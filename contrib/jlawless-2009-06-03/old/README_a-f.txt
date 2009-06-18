Dear Nico Schottelius,

   I have started using ccollect and I very much like its design:
it is elegant and effective.

   In the process of getting ccollect setup and running, I made
five changes, including one major new feature, that I hope you will
find useful.

   First, I added the following before any old backup gets deleted:

>    # Verify source is up and accepting connections before deleting any old backups
>    rsync "$source" >/dev/null || _exit_err "Source ${source} is not readable. Skipping."

I think that this quick test is a much better than, say, pinging
the source in a pre-exec script: this tests not only that the
source is up and connected to the net, it also verifies (1) that
ssh is up and accepting our key (if we are using ssh), and (2) that
the source directory is mounted (if it needs to be mounted) and
readable.

   Second, I found ccollect's use of ctime problematic.  After
copying an old backup over to my ccollect destination, I adjusted
mtime and atime where needed using touch, e.g.:

touch -d"28 Apr 2009 3:00" destination/daily.01

However, as far as I know, there is no way to correct a bad ctime.
I ran into this issue repeatedly while adjusting my backup
configuration.  (For example, "cp -a" preserves mtime but not
ctime.  Even worse, "cp -al old new" also changes ctime on old.)

   Another potential problem with ctime is that it is file-system
dependent: I have read that Windows sets ctime to create-time not
last change-time.

   However, It is simple to give a new backup the correct mtime.
After the rsync step, I added the command:

553a616,617
>    # Correct the modification time:
>    pcmd touch "${destination_dir}"

Even if ccollect continues to use ctime for sorting, I see no
reason not to have the backup directory have the correct mtime.

   To allow the rest of the code to use either ctime or mtime, I
added definitions:

44a45,47
> #TSORT="tc" ; NEWER="cnewer"
> TSORT="t" ; NEWER="newer"

(It would be better if this choice was user-configurable because
those with existing backup directories should continue to use ctime
until the mtimes of their directories are correct.  The correction
would happen passively over time as new backups created using the
above touch command and the old ones are deleted.)

With these definitions, the proper link-dest directory can then be
found using this minor change (and comment update):

516,519c579,582
<    # Use ls -1c instead of -1t, because last modification maybe the same on all
<    # and metadate update (-c) is updated by rsync locally.
<    #
<    last_dir="$(pcmd ls -tcp1 "${ddir}" | grep '/$' | head -n 1)" || \
---
>    # Depending on your file system, you may want to sort on: 
>    #   1. mtime (modification time) with TSORT=t, or
>    #   2. ctime (last change time, usually) with TSORT=tc
>    last_dir="$(pcmd ls -${TSORT}p1 "${ddir}" | grep '/$' | head -n 1)" || \

   Thirdly, after I copied my old backups over to my ccollect
destination directory, I found that ccollect would delete a
recent backup not an old backup!  My problem was that, unknown to
me, the algorithm to find the oldest backup (for deletion) was
inconsistent with that used to find the newest (for link-dest).  I
suggest that these two should be consistent.  Because time-sorting
seemed more consistent with the ccollect documentation, I suggest:

492,493c555,556
<       pcmd ls -p1 "$ddir" | grep "^${INTERVAL}\..*/\$" | \
<         sort -n | head -n "${remove}" > "${TMP}"      || \
---
>       pcmd ls -${TSORT}p1r "$ddir" | grep "^${INTERVAL}\..*/\$" | \
>         head -n "${remove}" > "${TMP}"      || \

   Fourthly, in my experience, rsync error code 12 means complete
failure, usually because the source refuses the ssh connection.
So, I left the marker in that case:

558,559c622,625
<    pcmd rm "${destination_dir}.${c_marker}" || \
<       _exit_err "Removing ${destination_dir}/${c_marker} failed."
---
>    if [ "$ret" -ne 12 ] ; then
>       pcmd rm "${destination_dir}.${c_marker}" || \
>          _exit_err "Removing ${destination_dir}/${c_marker} failed."
>    fi

(A better solution might allow a user-configurable list of error
codes that are treated the same as a fail.)

   Fifth, because I was frustrated by the problems of having a
cron-job decide which interval to backup, I added a major new
feature: the modified ccollect can now automatically select an
interval to use for backup.

   Cron-job controlled backup works well if all machines are up and
running all the time and nothing ever goes wrong.  I have, however,
some machines that are occasionally turned off, or that are mobile
and only sometimes connected to local net.  For these machines, the
use of cron-jobs to select intervals can be a disaster.

   There are several ways one could automatically choose an
appropriate interval. The method I show below has the advantage
that it works with existing ccollect configuration files.  The only
requirement is that interval names be chosen to sort nicely (under
ls).  For example, I currently use:

$ ls -1 intervals
a_daily
b_weekly
c_monthly
d_quarterly
e_yearly
$ cat intervals/*
6
3
2
3
30

A simpler example would be:

$ ls -1 intervals
int1
int2
int3
$ cat intervals/*
2
3
4

The algorithm works as follows:

   If no backup exists for the least frequent interval (int3 in the
   simpler example), then use that interval. Otherwise, use the
   most frequent interval (int1) unless there are "$(cat
   intervals/int1)" int1 backups more recent than any int2 or int3
   backup, in which case select int2 unless there are "$(cat
   intervals/int2)" int2 backups more recent than any int3 backups
   in which case choose int3.

This algorithm works well cycling through all the backups for my
always connected machines as well as for my usually connected
machines, and rarely connected machines.  (For a rarely connected
machine, interval names like "b_weekly" lose their English meaning
but it still does a reasonable job of rotating through the
intervals.)

   In addition to being more robust, the automatic interval
selection means that crontab is greatly simplified: only one line
is needed.  I use:

30 3 * * * ccollect.sh AUTO host1 host2 host3 | tee -a /var/log/ccollect-full.log | ccollect_analyse_logs.sh iwe

   Some users might prefer a calendar-driven algorithm such as: do
a yearly backup the first time a machine is connected during a new
year; do a monthly backup the first that a machine is connected
during a month; etc. This, however, would require a change to the
ccollect configuration files.  So, I didn't pursue the idea any
further.

   The code checks to see if the user specified the interval as
AUTO.  If so, the auto_interval function is called to select the
interval:

347a417,420
>    if [ ${INTERVAL} = "AUTO" ] ; then
>       auto_interval
>       _techo "Selected interval: '$INTERVAL'"
>    fi

The code for auto_interval is as follows (note that it allows 'more
recent' to be defined by either ctime or mtime as per the TSORT
variable):

125a129,182
> # Select interval if AUTO
> #
> # For this to work nicely, you have to choose interval names that sort nicely
> # such as int1, int2, int3 or a_daily, b_weekly, c_monthly, etc.
> #
> auto_interval()
> {
>    if [ -d "${backup}/intervals" -a -n "$(ls "${backup}/intervals" 2>/dev/null)" ] ; then
>       intervals_dir="${backup}/intervals"
>    elif [ -d "${CDEFAULTS}/intervals" -a -n "$(ls "${CDEFAULTS}/intervals" 2>/dev/null)" ] ; then
>       intervals_dir="${CDEFAULTS}/intervals"
>    else
>       _exit_err "No intervals are defined.  Skipping."
>    fi
>    echo intervals_dir=${intervals_dir}
> 
>    trial_interval="$(ls -1r "${intervals_dir}/" | head -n 1)" || \
>       _exit_err "Failed to list contents of ${intervals_dir}/."
>    _techo "Considering interval ${trial_interval}"
>    most_recent="$(pcmd ls -${TSORT}p1 "${ddir}" | grep "^${trial_interval}.*/$" | head -n 1)" || \
>       _exit_err "Failed to list contents of ${ddir}/."
>    _techo "   Most recent ${trial_interval}: '${most_recent}'"
>    if [ -n "${most_recent}" ]; then
>        no_intervals="$(ls -1 "${intervals_dir}/" | wc -l)"
>        n=1
>        while [ "${n}" -le "${no_intervals}" ]; do
>           trial_interval="$(ls -p1 "${intervals_dir}/" | tail -n+${n} | head -n 1)"
>           _techo "Considering interval '${trial_interval}'"
>           c_interval="$(cat "${intervals_dir}/${trial_interval}" 2>/dev/null)"
>           m=$((${n}+1))
>           set --  "${ddir}" -maxdepth 1
>           while [ "${m}" -le "${no_intervals}" ]; do
>              interval_m="$(ls -1 "${intervals_dir}/" | tail -n+${m} | head -n 1)"
>              most_recent="$(pcmd ls -${TSORT}p1 "${ddir}" | grep "^${interval_m}\..*/$" | head -n 1)"
>              _techo "   Most recent ${interval_m}: '${most_recent}'"
>              if [ -n "${most_recent}" ] ; then
>                 set -- "$@" -$NEWER "${ddir}/${most_recent}"
>              fi
>              m=$((${m}+1))
>           done
>           count=$(pcmd find "$@" -iname "${trial_interval}*" | wc -l)
>           _techo "   Found $count more recent backups of ${trial_interval} (limit: ${c_interval})"
>           if [ "$count" -lt "${c_interval}" ] ; then
>              break
>           fi
>           n=$((${n}+1))
>        done
>    fi
>    export INTERVAL="${trial_interval}"
>    D_FILE_INTERVAL="${intervals_dir}/${INTERVAL}"
>    D_INTERVAL=$(cat "${D_FILE_INTERVAL}" 2>/dev/null)
> }
> 
> #

While I consider the auto_interval code to be developmental, I have
been using it for my nightly backups and it works for me.

   One last change: For auto_interval to work, it needs "ddir" to
be defined first.  Consequently, I had to move the following code
so it gets run before auto_interval is called:

369,380c442,443
< 
<    #
<    # Destination is a path
<    #
<    if [ ! -f "${c_dest}" ]; then
<       _exit_err "Destination ${c_dest} is not a file. Skipping."
<    else
<       ddir=$(cat "${c_dest}"); ret="$?"
<       if [ "${ret}" -ne 0 ]; then
<          _exit_err "Destination ${c_dest} is not readable. Skipping."
<       fi
<    fi
345a403,414
>    # Destination is a path
>    #
>    if [ ! -f "${c_dest}" ]; then
>       _exit_err "Destination ${c_dest} is not a file. Skipping."
>    else
>       ddir=$(cat "${c_dest}"); ret="$?"
>       if [ "${ret}" -ne 0 ]; then
>          _exit_err "Destination ${c_dest} is not readable. Skipping."
>       fi
>    fi
> 
>    #

   I have some other ideas but this is all I have implemented at
the moment.  Files are attached.

   Thanks again for developing ccollect and let me know what you
think.

Regards,

John

-- 
 John L. Lawless, Ph.D.
 Redwood Scientific, Inc.
 1005 Terra Nova Blvd
 Pacifica, CA 94044-4300
 1-650-738-8083

