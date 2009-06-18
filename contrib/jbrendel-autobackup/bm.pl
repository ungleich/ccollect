#!/usr/bin/perl

###############################
#
# Jens-Christoph Brendel, 2009
# licensed under GPL3 NO WARRANTY
#
###############################

use Date::Calc qw(:all);
use strict;
use warnings;

#
#!!!!!!!!!!!!!!!!! you need to customize these settings !!!!!!!!!!!!!!!!!!!! 
#
my $backupdir = "/media/backupdisk";
my $logwrapper = "/home/jcb/ccollect/tools/ccollect_logwrapper.sh";

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# +------------------------------------------------------------------------+
# |                                                                        |
# |                         V A R I A B L E S                              |
# |                                                                        |
# +------------------------------------------------------------------------+
#

# get the current date
#
my ($sek, $min, $hour, $day, $month, $year) = localtime();

my $curr_year = $year + 1900;
my $curr_month = $month +1;
my ($curr_week,$cur_year) = Week_of_Year($curr_year,$curr_month,$day);

# initialize some variables
#
my %most_recent_daily = (
   'age'  => 9999,
   'file' => ''
);

my %most_recent_weekly = (
   'age'  => 9999,
   'file' => ''
);

my %most_recent_monthly = (
   'age'  => 9999,
   'file' => ''
);

# prepare the output formatting
#
#---------------------------------------------------------------------------
my ($msg1, $msg2, $msg3, $msg4);

format =
  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
  $msg1
  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<       
  $msg2,                                      $msg3

  @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| 
  $msg4
.

my @months = (' ','January', 'February', 'March', 'April', 
                  'May', 'June', 'July', 'August', 
                  'September', 'October', 'November', 
                  'December');

# +------------------------------------------------------------------------+
# |                                                                        |
# |                           P r o c e d u r e s                          |
# |                                                                        |
# +------------------------------------------------------------------------+
#

# PURPOSE:            extract the date from the file name
# PARAMETER VALUE:    file name
# RETURN VALUE:       pointer of a hash containing year, month, day
#
sub decodeDate {
   my $file = shift;
   $file =~ /^(daily|weekly|monthly)\.(\d+)-.*/;
   my %date = (
      'y' => substr($2,0,4),
      'm' => substr($2,4,2),
      'd' => substr($2,6,2)
   );
   return \%date;
}

# PURPOSE:         calculate the file age in days
# PARAMETER VALUE: name of a ccollect backup file
# RETURN VALUE:    age in days
#
sub AgeInDays {
   my $file = shift;
   my $date=decodeDate($file);
   my $ageindays = Delta_Days($$date{'y'}, $$date{'m'}, $$date{'d'}, $curr_year, $curr_month, $day);
   return $ageindays;
}

# PURPOSE:         calculate the file age in number of weeks 
# PARAMETER VALUE: name of a ccollect backup file
# RETURN VALUE:    age in weeks 
#
sub AgeInWeeks {
   my($y,$m,$d);

   my $file = shift;
   my $date = decodeDate($file);
   my ($weeknr,$yr) = Week_of_Year($$date{'y'}, $$date{'m'}, $$date{'d'});
   my $ageinweeks  = $curr_week - $weeknr;
   return $ageinweeks;
}

# PURPOSE:         calculate the file age in number of months 
# PARAMETER VALUE: name of a ccollect backup file
# RETURN VALUE:    age in months 
#
sub AgeInMonths {
   my $ageinmonths;
   my $ageinmonths;
   my $file = shift;
   my $date = decodeDate($file);
   if ($curr_year == $$date{'y'}) {
        $ageinmonths = $curr_month - $$date{'m'};
   } else {
        $ageinmonths = $curr_month + (12-$$date{'m'}) + ($curr_year-$$date{'y'}-1)*12;
   }
   return $ageinmonths; 
}

#  +------------------------------------------------------------------------+
#  |                                                                        |
#  |                                M A I N                                 |
#  |                                                                        |
#  +------------------------------------------------------------------------+
#

#
# find the most recent daily, weekly and monthly backup file
#

opendir(DIRH, $backupdir) or die "Can't open $backupdir \n";

my @files = readdir(DIRH);

die "Zielverzeichnis leer \n" if ( $#files <= 1 ); 

foreach my $file (@files) {
    
    next if $file eq "." or $file eq "..";
     
    SWITCH: {
       if ($file =~ /^daily/) {
          my $curr_age=AgeInDays($file);
          if ($curr_age<$most_recent_daily{'age'}) {
                 $most_recent_daily{'age'} =$curr_age;
                 $most_recent_daily{'file'}= $file; 
          }
          last SWITCH;
       }

       if ($file =~ /^weekly/) {
          my $curr_week_age = AgeInWeeks($file);
          if ($curr_week_age<$most_recent_weekly{'age'}) {
                $most_recent_weekly{'age'} =$curr_week_age;
                $most_recent_weekly{'file'}=$file;
          }  
          last SWITCH;
       }

       if ($file =~ /^monthly/) {
          my $curr_month_age=AgeInMonths($file);
          if ($curr_month_age < $most_recent_monthly{'age'}) {
                $most_recent_monthly{'age'} =$curr_month_age;
                $most_recent_monthly{'file'}=$file;
          }
          last SWITCH; 
       }
       print "\n\n unknown file $file \n\n";
     }
}

printf("\nBackup Manager started: %02u.%02u. %u, week %02u\n\n", $day, $curr_month, $curr_year, $curr_week);

#
# compare the most recent daily, weekly and monthly backup file
# and decide if it's necessary to start a new backup process in
# each category
#

if ($most_recent_monthly{'age'} == 0) {
	$msg1="The most recent monthly backup";
        $msg2="$most_recent_monthly{'file'} from $months[$curr_month - $most_recent_monthly{'age'}]";
        $msg3="is still valid.";
        $msg4="";
        write;
} else {
	$msg1="The most recent monthly backup";
        $msg2="$most_recent_monthly{'file'} from $months[$curr_month - $most_recent_monthly{'age'}]";
        $msg3="is out-dated.";
        $msg4="Starting new monthly backup.";
        write; 
        exec "sudo $logwrapper monthly FULL";
	exit;
}

if ($most_recent_weekly{'age'} == 0) {
	$msg1="The most recent weekly backup";
        $msg2="$most_recent_weekly{'file'} from week nr: $curr_week-$most_recent_weekly{'age'}";
        $msg3="is still valid.";
        $msg4="";
        write;
} else {
	$msg1="The most recent weekly backup";
        $msg2="$most_recent_weekly{'file'} from week nr: $curr_week-$most_recent_weekly{'age'}";
        $msg3="is out-dated.";
        $msg4="Starting new weekly backup.";
        write;
        exec "sudo $logwrapper weekly FULL";
	exit;
}

if ($most_recent_daily{'age'} == 0 ) {
	$msg1=" The most recent daily backup";
        $msg2="$most_recent_daily{'file'}";
        $msg3="is still valid.";
        $msg4="";
        write;
} else {
	$msg1="The most recent daily backup";
        $msg2="$most_recent_daily{'file'}";
        $msg3="is out-dated.";
        $msg4="Starting new daily backup.";
        write;
        exec "sudo $logwrapper daily FULL";
