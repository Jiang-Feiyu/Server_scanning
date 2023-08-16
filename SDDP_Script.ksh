#!/usr/bin/ksh

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

# Creating the networkdrive/hostname directory if it does not exist  
if [ ! -d $networkdrive$hostname ]
then
  mkdir -p $networkdrive$hostname
fi

# Preventing CPU working overload
function cpu_limit {
 CPU_USAGE=$(sar -u 1 1 | tail -n 1 | awk '{print $NF}')
 if [[ $CPU_USAGE -gt 50 ]]; then 
  echo "High CPU usage detected. Sleeping for 10s" >> "$logpath"
  echo "High CPU usage detected. Sleeping for 10s" >> "$hitpath"
  echo "High CPU usage detected. Sleeping for 10s"
  sleep 10 
 fi 
}

# Define timeout
timeout=10800

# Record the start time
start_time=$(perl -e 'print time')

# Initialize elapsed time
elapsed_time=0

#adding a scan started message to the log
echo "====================Scan started at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath

# getting file info and adding to log
# find "$scanpath" -type f
{ time find "$scanpath" -type f ! -path "/proc/*" -exec stat -c '%y?%Y?%z?%Z?%x?%X?%w?%W?%U?%G?%s?%n?%p' {} + | awk -v hostname="$hostname" -v hitpath="$hitpath" 'BEGIN { FS="?" } { for (i=1; i<=NF-1; i++) gsub(/[-:]/,"_",$i); print $0, hostname }' | sed 's/"/_/g'; } >> "$logpath" 2>> "$errorpath"

find_name_end=$(perl -e 'print time')
runtime=$((find_name_end - start_time))
echo "It takes $runtime seconds to complete the path seach and PID storage"     
echo "Now start iterating through files and checking rules"

current_time=$(perl -e 'print time')
elapsed_time=$((current_time - start_time))
reserved_time=$((timeout-elapsed_time))

# Loop and write
for line in $(timeout $reserved_time find "$scanpath" -type f 2>/dev/null); do
  # update the time checking function
  current_time=$(perl -e 'print time')
  elapsed_time=$((current_time - start_time))

  # Check CPU usage before writing to log file
  cpu_limit

  # Write to log file every 5 seconds
  echo "checking" >> $logpath

  # Check if timeout has been reached
  if [ $elapsed_time -ge $timeout ]; then
    # adding a timeout message to the log
    echo "Timeout reached at $(date +'%d-%b-%Y %H:%M:%S')" >> $logpath
    break
  fi

  # checking rules
  fullpath=$(echo $line | awk '{print $NF}')
  filename=$(echo $fullpath | awk -F '/' '{print $NF}')

  #exclusion
  if [[echo "$line" | grep -qE '^(/bin|/sbin|/lib|/libx32|/lib64|/boot|/sys).*']]; then
	  continue

  elif [[echo "$line" | grep -qE '(.bmp|\.eps|\.gif|\.ico|\.jfi|\.jfif|\.jpe|\.jpeg|\.jpg|\.png|\.psd|\.svg|\.tif|\.tiff|\.webp|\.xcf|\.ttf|\.otf|\.lock|\.css|\.less|\.admx|\.adml|\.xsd|\.nse|\.xsl|\.exe|\.dll|\.mp4|\.sys|\.png|\.so|\.bin)$']]; then
    continue

 elif [[echo "$line" | grep -qE '(jmxremote\\\.password\\\.template|sceregvl\.inf|puppet\\share\\doc|\\lib\\ruby|\\lib\\site-packages|\\usr\\share\\doc|node_modules|vendor\\bundle|vendor\\cache|\\doc\\openssl|Anaconda3\\Lib\\test|WindowsPowerShell\\Modules|Python\\d*\\Lib|Reference Assemblies|dotnet\\sdk|dotnet\\shared|Modules\\Microsoft\\.PowerShell\\.Security|Windows\\assembly|\\print$|\\ipc$|winsxs|syswow64|system32|systemapps|windows\\servicing|\\servicing|\\Microsoft\\\.Net\\Framework|\\windows\\immersivecontrolpanel|windows\\diagnostics\\windows\\debug|\\locale|\\chocolatey\\helpers|sources\\sxs|localization|AppData\\Local\\Microsoft|\\AppData\\Roaming\\Microsoft\\Windows|\\AppData\\Roaming\\Microsoft\\Teams|\\wsuscontent|\\\Application Data\\Microsoft\\CLR Security Config|\\servicing\\LCU|Microsoft SDKs|\\dotnet\\packs\\)$']]; then
    continue

  #extension check 
  elif [[echo "$line" | grep -qE '.*\.(vmdk|dayone|gnucash|pcap|bek|tpm|fve|asc|key|keypair|jks|pem|der|pfx|pk12|p12|pkcs12|mdf|sdf|sqldump|bak|wim|ova|ovf|cscfg|tfvars|dmp|pcap|cap|pcapng|cred|pass|kdbx|kdb|psafe3|kwallet|keychain|agilekeychain|cred|rdg|rtsz|rtsx|ovpn|tvopt|tblk|rdp|ppk|private_key|plist)$']]; then
    echo "$line?extension" >> "$hitpath"

  #file name check
  elif echo "$line" | grep -qE '.*(aws|ssh|winscp|logon\.sh|logon\.bat|logon\.vbs|logon\.vbe|logon\.wsf|logon\.wsc|login\.sh|login\.bat|login\.vbs|login\.vbe|login\.wsf|login\.wsc|signin\.sh|signin\.bat|signin\.vbs|signin\.cve|signin\.wsf|signin\.wsc|signon\.sh|signon\.bat|signon\.vbs|signon\.vbe|signon\.wsf|signon\.wsc|connect\.sh|connect\.bat|connect\.vbs|connect\.vbe|connect\.wsf|connect\.wsc|creds|sensitive|pamadmin|admin|login|journal.txt|gitconfig|config.inc|config.php|trc|s3cfg|muttrc|configuration\.user\.xpl|recon-ng|_rsa\.pub|_dsa\.pub|_ed25519\.pub|ecdsa\.pub|proxy|config|keystore|keyring|key3|key4|gitconfig|dockercfg|Login|passw|secret|credential|thycotic|cyberark|\.htpasswd|LocalSettings\.php|ConsoleHost_history|database|secret_token|knife|carrierwave|omniauth|jenkins|\.publish_over_ssh|\.BapSshPublisherPlugin|credentials|SensorConfiguration|unattend|Autounattend|profypdpasswd|filezilla|MEMORY\.DMP|hiberfil|\.sys|lsass|running-config|startup-config|running-config|startup-config|shadow|pwd|passwd|Psmapp|psmgw|backup|MasterReplicationUser|RecPrv|ReplicationUser|Server.key|VaultEmergency|VaultUser|Vault|PADR|PARAgent|CACPMScanner|PVConfiguration|logins|NTDS\.DIT|SYSTEM|SAM|SECURITY|tugboat|logins|SqlStudio|\.mysql_history|\.psql_history|\.pgpass|\.dbeaver-data-sources|credentials-config|dbvis|robomongo|\.git-credentials|\.bash_history|\.zsh_history|\.sh_history|zhistory|\.irb_history|ConsoleHost_History|_netrc|\.exports|\.functions|\.extra|\.npmrc|\.env|\.bashrc|\.profile|\.zshrc|cshrc|password|pass|accounts|passwords|pass|accounts|secrets|recentservers|sftp-config|mobaxterm|confCons|id_rsa|id_dsa|id_ecdsa|id_ed25519|_rsa|_dsa|_ed25519|_ecdsa|customsettings\.ini|Variables\.dat|Policy\.xml|config\.yaml|\.ssh).*'; then
	  echo "$line?filename" >> "$hitpath"

  #filepath check
  elif echo "$line" | grep -qE '.*(irssi\\config|xchat2\\servlist_\\conf|aws\\credentials|\.purple\\accounts\.xml|\.gem\\credentials|config\\hub|REMINST\\SMSTemp|SMS\\data\\Variables.dat|SMS\\data\\Policy.xml|\.aws|doctl\\config.yaml|\.ssh\\|winscp).*'; then
	  echo "$line?filepath" >> "$hitpath"
  
  else
    continue
  fi

done

#adding a scan ended message to the log
echo "====================Scan ended at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath

split -b 10m -d --additional-suffix=".txt" $logpath $networkdrive$hostname/log_split
split -b 10m -d --additional-suffix=".txt" $hitpath $networkdrive$hostname/hit_split
split -b 10m -d --additional-suffix=".txt" $errorpath $networkdrive$hostname/error_split


if [ $? -eq 124 ]; then
	echo "Exceed timeout, terminating the scan." >> $logpath
	echo "======================Scan ended at $(date + '%d-%b-%Y %H:%M:%S')======================" >> $logpath
	split -b 10m -d --additional-suffix=".txt" $logpath $networkdrive$hostname/log_split
	split -b 10m -d --additional-suffix=".txt" $hitpath $networkdrive$hostname/hit_split
	split -b 10m -d --additional-suffix=".txt" $errorpath $networkdrive$hostname/error_split
fi

current_time=$(perl -e 'print time')
elapsed_time=$((current_time - start_time))
echo "The whole program runs $elapsed_time second"