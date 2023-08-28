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
  echo "High CPU usage detected. Sleeping for 10s"
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
        echo "====================Scan ended at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath
        echo "====Scan ended at $(date +'%d-%b-%Y %H:%M:%S')===="
    fi
}

# Define timeout
timeout=10800

# Collect all the file path
echo "====================Scan started at $(date +'%d-%b-%Y %H:%M:%S')====================" >> $logpath
echo "====Path Scan started at $(date +'%d-%b-%Y %H:%M:%S')===="

# Find files and format output
time (find "$scanpath" -type f | sed 's/"/_/g')>> "$logpath" 2>> "$errorpath"

echo "====================Scan ended at $(date +'%d-%b-%Y %H:%M:%S')=====================" >> $logpath
echo "====Path scan ended at $(date +'%d-%b-%Y %H:%M:%S')===="

# Start to detect the high-risk file
echo "====Start detecting high-risk files now===="

tasks_in_total=$(wc -l $logpath | sed 's/^[ \t]*//g' | cut -d ' ' -f1) # acquire the num of lines in log file

current_task=0

while [ $current_task -lt $tasks_in_total ]
do
  # cpu_limit # This will be turn off druing server simulation
  show_progress $current_task $tasks_in_total 
  current_task=`expr $current_task + 1`
done

