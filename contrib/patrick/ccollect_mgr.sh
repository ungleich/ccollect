#!/bin/sh
#
# ----------------------------------------------------------------------------
# Last update: 2009-10-29
# By         : pdrolet (ccollect_mgr@drolet.name)
# ----------------------------------------------------------------------------
# Job manager to the ccollect utilities 
# (ccollect written by Nico Schottelius)
#
# Provides the following features
#    1) Determine the interval (daily/weekly/monthly)
#    2) Perform the backups using ccollect
#    4) Copy the ccollect log to the first backup of the set
#    5) Build a periodic report and include the real amount of disk used
#    6) Send an email if there has been errors or warnings
#    7) Send a periodic email to show transfer size, real backup size, etc
# ----------------------------------------------------------------------------
#
# This script was written primarily to gain better visibility of backups in
# an environment where data transfer is limited and so is bandwidth 
# (eg: going through an ISP).  The primary target of this script were a
# DNS323 and a QNAP T209 (eg: Busybox devices and not standard Linux devices)
# but it should run on any POSIX compliant device.
#
# Note: This is one of my first script in over a decade... don't use this as a 
# reference (but take a look at ccollect.sh... very well written!)
# ----------------------------------------------------------------------------
#
# -------------------------------------------
# TO MAKE THIS SCRIPT RUN ON A BUSYBOX DEVICE
# -------------------------------------------
# - You may need to install Optware and the following packages:
#   - findutils (to get a find utility which supports printf)
#   - procps (to get a ps utility that is standard) 
#   - mini-sendmail (this is what I used to send emails... you could easily 
#     modify this to use sendmail, mutt, putmail, etc...).
#   - On DNS323 only: Your Busybox is very limited. For details, see
#     http://wiki.dns323.info/howto:ffp#shells.  You need to redirect /bin/sh
#     to the Busybox provided with ffp (Fun Plug).  To do this, type:
#             ln -fs /ffp/bin/sh /bin/sh
#
# --------------------------------------------------
# TO MAKE THIS SCRIPT RUN ON A STANDARD LINUX DEVICE
# --------------------------------------------------
# - You will need install mini_sendmail or rewrite the send_email routine. 
#
# ----------------------------------------------------------------------------

# Send warning if the worst case data transfer will be larger than (in MB)...
warning_transfer_size=1024

# Define paths and default file names
ADD_TO_PATH=/opt/bin:/opt/sbin:/usr/local/bin:/usr/local/sbin
CCOLLECT=ccollect.sh
CCOLLECT_CONF=/usr/local/etc/ccollect

per_report=${CCOLLECT_CONF}/periodic_report.log
tmp_report=/tmp/ccollect.$$
tmp_email=/tmp/email.$$

# Sub routines...

find_interval()
{
    # ---------------------------------------------------- 
    # Find interval for ccollect backup. 
    # optional parameters: 
    #    - Day of the week to do weekly backups
    #    - Do monthly instead of weekly on the Nth week
    # ---------------------------------------------------- 

    weekly_backup=$1
    monthly_backup=$2
    
    weekday=`date "+%w"`
    if [ ${weekday} -eq ${weekly_backup} ]; then
        dom=`date "+%d"`
        weeknum=$(( ( ${dom} / 7 ) + 1 ))
        if [ ${weeknum} -eq ${monthly_backup} ]; then
            interval=monthly
        else
            interval=weekly
        fi 
    else
        interval=daily
    fi
}

move_log()
{
   for backup in $@ ; do 
       ddir="$(cat "${CCOLLECT_CONF}"/sources/"${backup}"/destination)"; ret="$?"
       if [ "${ret}" -ne 0 ]; then
           echo "Destination ${CCOLLECT_CONF}/sources/${backup}/destination is not readable... Skipping."
           backup_dir=""
       else
           backup_dir=`cat ${TEMP_LOG} | grep "\[${backup}\] .*: Creating ${ddir}" | awk '{ print $4 }'` 
       fi
       if [ "${backup_dir}" != "" ]; then
           new_log=${backup_dir}/ccollect.log
           mv ${TEMP_LOG} ${new_log}
           echo New Log Location: ${new_log}
           return 0
       fi
   done
   echo "WARNING: none of the backup set have been created"
   new_log=${TEMP_LOG} 
}

compute_rdu()
{
   # WARNING: Don't pass a directory with a space as parameter (I'm too new at scripting!)
   
   kdivider=1
   find_options=""
   
   while [ "$#" -ge 1 ]; do
      case "$1" in
         -m)
            kdivider=1024
            ;;
         -g)
            kdivider=1048576
            ;;
         *)
            find_options="${find_options} $1"
            ;;
      esac
      shift
   done
   
   # ------------------------------------------------------------------------------------------------------
   # Compute the real disk usage (eg: hard links do files outside the backup set don't count)
   # ------------------------------------------------------------------------------------------------------
   # 1) Find selected files and list link count, inodes, file type and size
   # 2) Sort (sorts on inodes since link count is constant per inode)
   # 3) Merge duplicates using uniq
   #    (result is occurence count, link count, inode, file type and size)
   # 4) Use awk to sum up the file size of each inodes when the occurence count
   #    and link count are the same.  Use %k for size since awk's printf is 32 bits
   # 5) Present the result with additional dividers based on command line parameters
   #

   rdu=$(( ( `/opt/bin/find ${find_options} -printf '%n %i %y %k \n' \
           | sort -n \
           | uniq -c \
           | awk '{ if (( $1 == $2 ) || ($4 == "d")) { sum += $5; } } END { printf "%u\n",(sum); }'` \
           + ${kdivider} - 1 ) / ${kdivider} ))
   echo RDU for ${find_options} is ${rdu}
}

compute_total_rdu()
{
    real_usage=0
    
    # ------------------------------------------
    # Get the real disk usage for the backup set
    # ------------------------------------------
    for backup in $@ ; do
        ddir="$(cat "${CCOLLECT_CONF}"/sources/"${backup}"/destination)"; ret="$?"
        echo ${backup} - Adding ${ddir} to backup list
        backup_dir_list="${backup_dir_list} ${ddir}"
        if [ "${ret}" -ne 0 ]; then
            echo "Destination ${CCOLLECT_CONF}/sources/${backup}/destination is not readable... Skipping."
        else
            backup_dir=`find ${ddir}/${interval}.* -maxdepth 0 -type d -print | sort -r | head -n 1` 
            compute_rdu -m ${backup_dir}
            real_usage=$(( ${real_usage} + ${rdu} ))
        fi 
    done
    echo Backup list - ${backup_dir_list}
}

send_email()
{
    # Send a simple email using mini-sendmail.  
    
    msg_body_file=$1
    shift
	
    # ------------------------------
    # Quit if we can't send an email
    # ------------------------------
    if [ "${to}" == "" ] || [ "${mail_server}" == "" ]; then
        echo "Missing mail server or destination email. No email sent with subject: $@"
        exit 1
    fi

    echo from: ${from} > ${tmp_email}
    echo subject: $@ >> ${tmp_email}
    echo to: ${to} >> ${tmp_email}
    echo cc: >> ${tmp_email}
    echo bcc: >> ${tmp_email}
    echo "" >> ${tmp_email}
    echo "" >> ${tmp_email}
    cat ${msg_body_file} >> ${tmp_email}
    echo "" >> ${tmp_email}
        
    echo Sending email to ${to} to report the following error:
    echo -----------------------------------------------------
    cat ${tmp_email}
    cat ${tmp_email} | mini_sendmail -f${from} -s${mail_server} ${to}  
    rm ${tmp_email}
}

check_running_backups()
{
    # Check if a backup is already ongoing.  If so, skip and send email
    # Don't use the ccollect marker as this is no indication if it is still running
    
    for backup in ${ccollect_backups} ; do
        PID=$$
        /opt/bin/ps -e -o pid,ppid,args 2> /dev/null | grep -v -e grep -e "${PID}.*ccollect.*${backup}" | grep "ccollect.*${backup}" > /tmp/ccollect_mgr.$$ 2> /dev/null
        running_proc=`cat /tmp/ccollect_mgr.$$ | wc -l`
        if [ ${running_proc} -gt 0 ]; then
            running_backups="${running_backups}${backup} "
            echo "Process:"
            cat /tmp/ccollect.$$
        else
            backups_to_do="${backups_to_do}${backup} "
        fi
        rm /tmp/ccollect_mgr.$$
    done
    ccollect_backups=${backups_to_do}
    
    if [ "${running_backups}" != "" ]; then
        echo "skipping ccollect backups already running: ${running_backups}" | tee ${tmp_report}
        send_email ${tmp_report} "WARNING - skipping ccollect backups already running: ${running_backups}"
        rm ${tmp_report} 
    fi
}
        
precheck_transfer_size()
{
    # Check the estimated (worst case) transfer size and send email if larger than certain size
    # 
    # Be nice and add error checking one day...
    
    for backup in ${ccollect_backups} ; do
        ddir="$(cat "${CCOLLECT_CONF}"/sources/"${backup}"/destination)"; ret="$?"
        last_dir="$(ls -tcp1 "${ddir}" | grep '/$' | head -n 1)"
        sdir="$(cat "${CCOLLECT_CONF}"/sources/"${backup}"/source)"; ret="$?"
        if [ -f "${CCOLLECT_CONF}"/sources/"${backup}"/exclude ]; then
            exclude="--exclude-from=${CCOLLECT_CONF}/sources/${backup}/exclude";
        else
            exclude=""
        fi
        if [ -f "${CCOLLECT_CONF}"/sources/"${backup}"/rsync_options ]; then
            while read line; do
                rsync_options="${rsync_options} ${line}"
            done < ${CCOLLECT_CONF}/sources/${backup}/rsync_options 
        fi
        rsync -n -a --delete --stats ${rsync_options} ${exclude} ${sdir} ${ddir}/${last_dir} > ${tmp_report}  
        tx_rx=`cat ${tmp_report} | grep "Total transferred file size" | \
               awk '{ { tx += $5 } } END { printf "%u",(((tx)+1024*1024-1)/1024/1024); }'`
        total_xfer=$(( ${total_xfer} + ${tx_rx} ))
    done
    echo Transfer estimation for ${ccollect_backups}: ${total_xfer} MB
    
    if [ ${total_xfer} -gt ${warning_transfer_size} ]; then
        # --------------------------------------------------
        # Send a warning if transfer is expected to be large
        # --------------------------------------------------
        # Useful to detect potential issues when there is transfer quota (ex: with ISP)

        echo Data transfer larger than ${warning_transfer_size} MB is expected for ${ccollect_backups} > ${tmp_report}
        
        send_email ${tmp_report} "WARNING ccollect for ${ccollect_backups} -- Estimated Tx+Rx: ${total_xfer} MB"
        rm ${tmp_report} 
    fi
}

send_report()
{
    log=$1
    
    # Analyze log for periodic report and for error status report
    cat ${log} | ccollect_analyse_logs.sh iwe > ${tmp_report}

    # -------------------------
    # Build the periodic report
    # -------------------------

    # Compute the total number of MB sent and received for all the backup sets
    tx_rx=`cat ${tmp_report} | \
           grep 'sent [[:digit:]]* bytes  received [0-9]* bytes' | \
           awk '{ { tx += $3 } { rx += $6} } END \
                { printf "%u",(((tx+rx)+1024*1024-1)/1024/1024); }'`
    current_date=`date +'20%y/%m/%d %Hh%M -- '`

    # ---------------------------------------------------------
    # Get the disk usage for all backups of each backup sets... 
    # ** be patient **
    # ---------------------------------------------------------
    compute_rdu -g ${backup_dir_list}
    
    echo ${current_date} Tx+Rx: ${tx_rx} MB -- \
         Disk Usage: ${real_usage} MB -- \
         Backup set \(${interval}\): ${ccollect_backups} -- \
         Historical backups usage: ${rdu} GB >> ${per_report}

    # ----------------------------------------
    # Send a status email if there is an error
    # ----------------------------------------
    ccollect_we=`cat ${log} | ccollect_analyse_logs.sh we | wc -l`
    if [ ${ccollect_we} -ge 1 ]; then
        send_email ${tmp_report} "ERROR ccollect for ${ccollect_backups} -- Tx+Rx: ${tx_rx} MB"
    fi
    
    # --------------------
    # Send periodic report
    # --------------------
    if [ ${report_interval} == ${interval} ] || [ ${interval} == "monthly" ]; then

        # Make reporting atomic to handle concurrent ccollect_mgr instances
        mv ${per_report} ${per_report}.$$
        cat ${per_report}.$$ >> ${per_report}.history

        # Calculate total amount of bytes sent and received
        tx_rx=`cat ${per_report}.$$ | \
               awk '{ { transfer += $5 } } END \
               { printf "%u",(transfer); }'`

        # Send email
        send_email ${per_report}.$$ "${report_interval} ccollect status for ${ccollect_backups} -- Tx+Rx: ${tx_rx} MB"
        rm ${per_report}.$$
    fi

    rm ${tmp_report}
}

# ------------------------------------------------
# Add to PATH in case we're launching from crontab
# ------------------------------------------------

PATH=${ADD_TO_PATH}:${PATH} 

# --------------
# Default Values
# --------------

# Set on which interval status emails are sent (daily, weekly, monthly)
report_interval=weekly

# Set day of the week for weekly backups.  Default is Monday
# 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
weekly_backup=1

# Set the monthly backup interval.  Default is 4th Monday of every month
monthly_backup=4

show_help=0

# ---------------------------------
# Parse command line
# ---------------------------------

while [ "$#" -ge 1 ]; do
   case "$1" in
        -help)
           show_help=1
           ;;
        -from)
           from=$2
           shift
           ;;
        -to)
           to=$2
           shift
           ;;
        -server|mail_server)
           mail_server=$2
           shift
           ;;
        -weekly)
           weekly_backup=$2
           shift
           ;;
        -monthly)
           monthly_backup=$2
           shift
           ;;
        -warning_size)
           warning_transfer_size=$2
           shift
           ;;
        -report)
           report_interval=$2
           shift
           ;;
        -*)
           ccollect_options="${ccollect_options} $1"
           ;;
        daily|weekly|monthly)
           ;;
        *) 
           ccollect_backups="${ccollect_backups}$1 " 
           ;;
   esac
   shift
done

if [ "${ccollect_backups}" == "" ] || [ ${show_help} -eq 1 ]; then
   echo 
   echo "$0: Syntax"
   echo " -help               This help"
   echo " -from <email>       From email address (ex.: -from nas@home.com)"
   echo " -to <email>         Send email to this address (ex.: -to me@home.com)"
   echo " -server <smtp_addr> SMTP server used for sending emails"
   echo " -weekly <day#>      Define wich day of the week is the weekly backup"
   echo "                     Default is ${weekly_backup}.  Sunday = 0, Saturday = 6"
   echo " -monthly <week#>    Define on which week # is the monthly backup"
   echo "                     Default is ${monthly_backup}. Value = 1 to 5"
   echo " -report <interval>  Frequency of report email (daily, weekly or monthly)"
   echo "                     Default is ${report_interval}"
   echo " -warning_size <MB>  Send a warning email if the transfer size exceed this"
   echo "                     Default is ${warning_transfer_size}"
   echo ""
   echo " other parameters are transfered to ccollect"
   echo
   exit 0
fi

# ------------------------------------------------------------------
# Check if ccollect_mgr is already running for the given backup sets
# ------------------------------------------------------------------

check_running_backups

if [ "${ccollect_backups}" == "" ]; then
    echo "No backup sets are reachable"
    exit 1
fi

# ----------------------------------------------------------
# Set the interval type
#
# Here, weeklys are Mondays, and Monthlys are the 4th Monday
# ----------------------------------------------------------

find_interval ${weekly_backup} ${monthly_backup}
echo Interval: ${interval}

# --------------
# Do the backups
# --------------
TEMP_LOG=${CCOLLECT_CONF}/log.$$
echo Backup sets: ${ccollect_backups}

# Check the transfer size (to issue email warning)
precheck_transfer_size 

${CCOLLECT} ${ccollect_options} ${interval} ${ccollect_backups} | tee ${TEMP_LOG}

# ---------------------------------------
# Move log to the last backup of the set
# ---------------------------------------

move_log ${ccollect_backups} 

# -----------------------------------------
# Compute the physical amount of disk usage
# -----------------------------------------

compute_total_rdu ${ccollect_backups}

# -----------------
# Send status email
# -----------------

send_report ${new_log}
