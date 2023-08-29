#!/usr/bin/ksh
echo "Attention: Due to timing system issues, please run the program before 9pm"
echo "Timeout setting: 10800s CPU sleep setting: 50% Usage"
# Defining the scan path  
scanpath=/

# Defining the network drive  
networkdrive=/tmp/

# Getting the hostname 
hostname=$(hostname) 

# If networkdrive does not end with /, add it  
if [[ $networkdrive != */ ]]
then
  networkdrive=$networkdrive/
fi

# Creating the log and hit file paths
logpath=$networkdrive$hostname/log.txt
hitpath=$networkdrive$hostname/hit.txt
errorpath=$networkdrive$hostname/error.txt
greppath=$networkdrive$hostname/grep.txt

# Creating the networkdrive/hostname directory if it does not exist (tested, OK) 
if [ ! -d $networkdrive$hostname ]
then
  mkdir -p $networkdrive$hostname
fi


# Preventing CPU working overload
function cpu_limit {
 CPU_USAGE=`sar -u 1 1 | tail -1 | awk '{print $NF}'`
 if [[ $CPU_USAGE -gt 50 ]]; then 
  echo "High CPU usage detected. Sleeping for 10s" >> "$logpath"
  echo "High CPU usage detected. Sleeping for 10s" >> "$hitpath"
  # echo "High CPU usage detected. Sleeping for 10s"
  printf "\r High CPU usage detected. Sleeping for 10s\033[0K\r"
  sleep 10 
 fi 
}

# Design a function for progress bar
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

function show_progress {
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=`echo "scale=$bar_percentage_scale; 100 * $current / $total" |bc`

    # The number of done and todo characters
    done=`echo "scale=0; $bar_size * $percent / 100" |bc`
    todo=`echo "scale=0; $bar_size - $done" |bc`

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    printf "\r Progress : [${done_sub_bar}${todo_sub_bar}] ${percent}%\033[0K\r" #overwrite

    if [ $total -eq $current ]; then
        #adding a scan ended message to the log
        printf "\r Done \033[0K\r" #overwrite
        echo "Progress: Done!"
        echo "====================Scan ended at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath
        echo "======Scan ended at $(date +'%d-%b-%Y %H:%M:%S')======"
    fi
}

# Collect all the file path
echo "====================Scan started at $(date +'%d-%b-%Y %H:%M:%S')====================" >> $logpath
echo "====Path Scan started at $(date +'%d-%b-%Y %H:%M:%S')===="

# Find files and format output
time (find "$scanpath" -type f | sed 's/"/_/g')>> "$logpath" 2>> "$errorpath"

echo "====================Scan ended at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath
echo "====Path scan ended at $(date +'%d-%b-%Y %H:%M:%S')===="

# Start to detect the high-risk file
echo "======Start detecting high-risk files now======"

# Define timeout
timeout=10800
tasks_in_total=$(wc -l $logpath | sed 's/^[ \t]*//g' | cut -d ' ' -f1) # acquire the num of lines in log file
# tasks_in_total=100 # for testing
current_task=0
start_hours=`date +'%H'`
start_minute=`date +'%M'`
start_second=`date +'%S'`

while [ $current_task -le $tasks_in_total ]
do
  cpu_limit # This will be turn off druing server simulation
  show_progress $current_task $tasks_in_total 
  current_task=`expr $current_task + 1`

  # calculate the time elpased and kill the process if timeout
  end_hours=`date +'%H'`
  hours_elpased=`expr $end_hours - $start_hours`
  EXPHOURINSEC=`expr $hours_elpased \* 3600`
  end_minute=`date +'%M'`
  min_elpased=`expr $start_minute - $end_minute`
  EXPMININSEC=`expr $min_elpased \* 60`
  end_second=`date +'%S'`
  EXPSECINSEC=`expr $end_second - $start_second`
  Total_time=`expr $EXPHOURINSEC + $EXPMININSEC + $EXPSECINSEC`

  if [ $Total_time -ge $timeout ]; then
    # adding a timeout message to the log
    printf "\r Done \033[0K\r" #overwrite
    echo "Timeout reached at $(date +'%d-%b-%Y %H:%M:%S')" >> $logpath
    echo "======Tiemout: the program is saving...======"
    echo "===========Please don't shut down==========="
    current_task=`expr $tasks_in_total + 1`
    echo "Exceed timeout, terminating the scan." >> $logpath
	echo "======================Scan ended at $(date + '%d-%b-%Y %H:%M:%S')======================" >> $logpath
    break
  fi

  current_line=`expr $current_task + 1`
  # Detect the high-risk file
  line=`sed -n "${current_line}p" "$logpath"`

  # Using regex to analysis the risk
  #extension check 
  if egrep -c '.*\.(vmdk|dayone|gnucash|pcap|bek|tpm|fve|asc|key|keypair|jks|pem|der|pfx|pk12|p12|pkcs12|mdf|sdf|sqldump|bak|wim|ova|ovf|cscfg|tfvars|dmp|pcap|cap|pcapng|cred|pass|kdbx|kdb|psafe3|kwallet|keychain|agilekeychain|cred|rdg|rtsz|rtsx|ovpn|tvopt|tblk|rdp|ppk|private_key|plist)' < "$line" >> "$greppath"; then
    : # do nothing
    echo "$line?extension" >> "$hitpath"

  #file name check
  elif egrep -c '.*(aws|ssh|winscp|logon\.sh|logon\.bat|logon\.vbs|logon\.vbe|logon\.wsf|logon\.wsc|login\.sh|login\.bat|login\.vbs|login\.vbe|login\.wsf|login\.wsc|signin\.sh|signin\.bat|signin\.vbs|signin\.cve|signin\.wsf|signin\.wsc|signon\.sh|signon\.bat|signon\.vbs|signon\.vbe|signon\.wsf|signon\.wsc|connect\.sh|connect\.bat|connect\.vbs|connect\.vbe|connect\.wsf|connect\.wsc|creds|sensitive|pamadmin|admin|login|journal.txt|gitconfig|config.inc|config.php|trc|s3cfg|muttrc|configuration\.user\.xpl|recon-ng|_rsa\.pub|_dsa\.pub|_ed25519\.pub|ecdsa\.pub|proxy|config|keystore|keyring|key3|key4|gitconfig|dockercfg|Login|passw|secret|credential|thycotic|cyberark|\.htpasswd|LocalSettings\.php|ConsoleHost_history|database|secret_token|knife|carrierwave|omniauth|jenkins|\.publish_over_ssh|\.BapSshPublisherPlugin|credentials|SensorConfiguration|unattend|Autounattend|profypdpasswd|filezilla|MEMORY\.DMP|hiberfil|\.sys|lsass|running-config|startup-config|running-config|startup-config|shadow|pwd|passwd|Psmapp|psmgw|backup|MasterReplicationUser|RecPrv|ReplicationUser|Server.key|VaultEmergency|VaultUser|Vault|PADR|PARAgent|CACPMScanner|PVConfiguration|logins|NTDS\.DIT|SYSTEM|SAM|SECURITY|tugboat|logins|SqlStudio|\.mysql_history|\.psql_history|\.pgpass|\.dbeaver-data-sources|credentials-config|dbvis|robomongo|\.git-credentials|\.bash_history|\.zsh_history|\.sh_history|zhistory|\.irb_history|ConsoleHost_History|_netrc|\.exports|\.functions|\.extra|\.npmrc|\.env|\.bashrc|\.profile|\.zshrc|cshrc|password|pass|accounts|passwords|pass|accounts|secrets|recentservers|sftp-config|mobaxterm|confCons|id_rsa|id_dsa|id_ecdsa|id_ed25519|_rsa|_dsa|_ed25519|_ecdsa|customsettings\.ini|Variables\.dat|Policy\.xml|config\.yaml|\.ssh).*' < "$line" >> "$greppath"; then    : # do nothing
    : # do nothing
    echo "$line?filename" >> "$hitpath"

  #filepath check
  elif egrep -c '.*(irssi\\config|xchat2\\servlist_\\conf|aws\\credentials|\.purple\\accounts\.xml|\.gem\\credentials|config\\hub|REMINST\\SMSTemp|SMS\\data\\Variables.dat|SMS\\data\\Policy.xml|\.aws|doctl\\config.yaml|\.ssh\\|winscp).*' < "$line" >> "$greppath"; then    : # do nothing
    : # do nothing
    echo "$line?filepath" >> "$hitpath"
  
  else
    echo "OK" >> "$hitpath"
  fi
done

#adding a scan ended message to the log
echo "====================Scan ended at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath

split -l 100000 $logpath $networkdrive$hostname/log_split
split -l 100000 $hitpath $networkdrive$hostname/hit_split
split -l 100000 $errorpath $networkdrive$hostname/error_split

echo "The whole program runs $Total_time second"