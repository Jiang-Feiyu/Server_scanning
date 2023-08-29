# Server Scanning
**Bob Jiang**
## Overall
The program is capable of automatically traversing all files within the server, storing and printing their file names, performing regular expression searches based on sensitive content, screening for high-risk file paths and error messages, and storing them at the designated path after the scan is complete. Additionally, the program sets a scan time limit and CPU usage rate threshold to avoid affecting the normal operation of the server.

This is a note of server scanning based on **regex**. The purpose of scanning is managing to detect possible high-risk files and save the path of the file for manual checking. The programme uses `KSH` (Korn Shell Script) and developed different versions for `Solaris` and `RHEL8` systems.

## Flow of the program
1. define the variables for scan path, network drive and obtain the hostname.
2. create the log file, hit file and error file.
3. obtain the information of all files under the path and add to the log file.
4. enters a loop, iterating and checking through the files in the scan path before timeout, sleep for a period if the CPU usage is too high.
5. split the files into multiple files of maximum 10000 lines.

## Solaris-10 system
<p align=center><img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/27df038788624cbaab7536867fc18af1~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=216&h=82&e=png&b=35566b" alt="屏幕截图 2023-08-29 164839.png" width="50%" /></p>

### Running on different system
Relationship map between different linux operation system:
<p align=center><img src="https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/569d226bd8d54e028cf2eb41ec39b3f0~tplv-k3u1fbpfcp-watermark.image?" alt="image.png" width="70%" /></p>

### **What is Solaris system**
Solaris is considered one of the derivatives of the UNIX operating system. Solaris is hybrid open source software.
</br> Noramlly there are two versions of Solaris DVD image, `SPARC` and `x86`. Please download it depends on your PC. You may check your device in System -> About -> System type.
</br> Download link: [13]
</br> You need to register a Oracle link before download the disc.
### VMware download
1. Download from this website[9]
2. Permanent key for VMware Pro:[4]
</br> key: `JU090-6039P-08409-8J0QH-2YR7F `
### Setup through VMware
Here is a detailed **tutorial** about how to setup: [14] 
</br> Some critical steps:
```
Network Connectivity -> Yes
DHCP for e1000g0 -> No
IP address for e1000g0 -> turn on your cmd and type `ipconfig` and should be your IPv4 Address.
Host Name -> turn on your cmd and type `hostname`
Netmask for e1000g0 -> 255.255.255.0
IPv6 -> No
Default Route for e1000g0 -> Detect one upon reboot
Configure Security Policy -> No
Name Service -> None
NFSv4 -> Use the NFSv4 domain derived by the system
File Style type -> ZFS
Software -> Entire Distribution
* Notice, the login name should be `root`
```
### How to set a share holder on both host and virtual machine
- Install VM tools on your virtual machine, for more info, please click the reference link[10] if you need to download it manually.
- Turn off your virtual machine, and enable `share folder` in `VM`-> `Settings`-> `options` -> `Share folder`, create a new folder on your physical machine and paste the path as instructed.[11]
- Turn on the Virtual machine again and `cd /mnt/hgfs`, you will see your folder there.[12]
<p align=center><img src="https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/58bd44de9ddb44f3bed89a3cd23f8d4f~tplv-k3u1fbpfcp-watermark.image?" alt="image.png" width="70%" /></p>

### How to check which shell the system is using?
`echo $SHELL`: This command is used to output the path of the current user's default shell. `$SHELL` is a special environment variable that holds the path to the current user's default shell. 
</br> `ps -p $$`: This command is used to view the information of the specified process ID (PID), where `$$` represents the PID of the current Shell process. Executing `ps -p $$` will display detailed information about the current shell process, such as process ID, parent process ID, process status, etc.

However, the fact is that our simulated environment may not be exactly the same as the real operating environment. Some servers that need to be tested may not give us testing permissions due to security considerations, so we need to choose the built-in shell of the system and build an environment through scripts.

Since our code is designed initially for `ksh`， let's try to use `ksh` interpreter first.
1. Check whether there are `ksh` interpreter on your server:
    </br> `which ksh`
2. Define the path of your `ksh` .
    </br> e.g.: `#!#!/usr/bin/ksh`
3. Use debug command to see if your script is running in `ksh` or native `sh`.
```
#!/usr/bin/ksh
if [[ "$0" = *ksh ]]; then
  echo "The script is running under KSH."
else
  echo "The script is running under a different interpreter."
fi
```
You shall see`The script is running under KSH` if everthing alright.

## Explanation of the technical principles of the procedure
### Find files and format output
</br> Command: `find "$scanpath"`

| `-printf` | meaning |
| --- | ---|
| `%CY-%Cm-%Cd` | File modification date and time (year-month-day hours:minutes:seconds) |
| `%TY-%Tm-%Td` | File access date and time (year-month-day hours:minutes:seconds) |
| `%AY-%Am-%Ad %ATu` | Date and time the file was created (year-month-day hours:minutes:seconds) |
| `%u` | The username of the file owner |
| `%M` | Permissions of the file |

### Specifies the path to the output file
```
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
```
### Preventing CPU working overload
Here `sar -u 1 1` will output a list, we only need to extract the last line of the last column.
```
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
```
### Design a function for progress bar
Draw a progress bar by calculating the proportion of completed tasks to the total tasks. It should be noted that the old progress bar needs to be overwritten with the new progress bar to achieve dynamic effects. The way to achieve it is to put the cursor position at the front of the line every time it is output.
```
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
        
    fi
}
```
Call the function by passing parameters through the while loop

```
while [ $current_task -le $tasks_in_total ]
do
  show_progress $current_task $tasks_in_total 
  current_task=`expr $current_task + 1`
done
```
Among them, we obtain the total task amount by obtaining the total number of rows of the log.
```
tasks_in_total=$(wc -l $logpath | sed 's/^[ \t]*//g' | cut -d ' ' -f1)
```
### Calculate running time
Solaris makes simple basic calculations very complicated, so I calculated the total number of seconds by taking the hours, minutes and seconds respectively and multiplying by 3600, 60, 1 accordingly. The total number of seconds to end minus the total number of seconds to start is the total running time of the program. It should be noted that the program cannot run across days.
```
  end_hours=`date +'%H'`
  hours_elpased=`expr $end_hours - $start_hours`
  EXPHOURINSEC=`expr $hours_elpased \* 3600`
  end_minute=`date +'%M'`
  min_elpased=`expr $start_minute - $end_minute`
  EXPMININSEC=`expr $min_elpased \* 60`
  end_second=`date +'%S'`
  EXPSECINSEC=`expr $end_second - $start_second`
  Total_time=`expr $EXPHOURINSEC + $EXPMININSEC + $EXPSECINSEC`
```
When the program times out, stop the loop.
```
if [ $Total_time -ge $timeout ]; then
    # adding a timeout message to the log
    break
  fi
```
### Judge high-risk files through regular expressions
One thing to note is that `=~` and `grep -E` cannot be used in Solaris, so I used `egrep` to match. The specific inspection items are placed in another document for reference.
### Other issues
#### Zombie process
- **The situation we met**:
</br>When I tried to record all the paths of files through `find`, I surprisingly found that the program is still running even when I kill the program in the terminal. The size of file is growing and CPU in a high usage, I realize there must be a zombie process.
- **What is Zombie process and how to prevent them?** 
    - A zombie process or defunct process is a process  that has completed execution but still has an entry in the process table: it is a process in the *Terminated state*.
    - Zombie processes are already dead processes but the parent process is unable to read its status and cannot be released from memory. So, the dead process cannot be killed.
- **How to detect and kill ps the Zombie process:**
    - `linux@linux-VirtualBox:~$ ps aux | egrep "Z|defunct"`
</br> In this command line, “ps” stands for the process state it is used to view the state of the process that is running in the system. This command is used to print all of the running processes that are stored in the memory. The second option passed “egrep” is a processing tool that is used to fetch the expressions or patterns in a specified location.When we execute the command, we will get the following output, which shows the zombie process in the system along with its “PID”. [1]
    - `linux@linux-VirtualBox:~$ ps –o ppid= -p 33819`
</br> In the above command, we tried to get the parent id of the zombie process.
    - `linux@linux-VirtualBox:~$ kill –s SIGCHLD  Parent_PID` or `kill -9 Parent_PID`[2]
</br> In the command above, we pass the signal to the parent id to kill the zombie process of the parent id passed to it.
<p align=center><img src="https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f0385fd5d7af4c1d8ce02551835e2730~tplv-k3u1fbpfcp-watermark.image?" alt="image.png"  width="70%"/></p>

- Specifies the path and format of the output file

```
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

```
- **Zombie process casused by `find`**
    - Since`find` is a recursive command, it will create loads of child processes to search into different directories. When the parent process is killed, there would be no *stop* command from the parent process so the child process will run until all files are traversed.
    - I tried several methods, mainly trying to find the specific pid, collecting them into a variable and killing them respectively, but the result shows not working well. It won't be easy to kill the specific pid since the process is dynamic.
    - Timeout function is a good command for dealing with this issue. The basic grammar is like: `timeout [OPTIONS] DURATION COMMAND [ARG]…`

#### Errors in setting up a virtual machine
- **VMWare 'Taking ownership of this virtual machine failed' Error**[3]
    - launch Task Manager by pressing `CTRL+ALT+DEL` on the keyboard and end the process of vmware.exe
    - Go to the folder containing the problematic virtual machine. Next, look for any " **.lck**" or " **.lock**" files AND folders. Cut these files into a `Temp` file folder, which is newly created.
    - Start VMWare Workstation again.
- **Keyboard and Mouse cannot connect to VMware**
     - Disconnection of keyboard and mouse between VMware and your PC is quite common. Here are some reference links: <vmware虛擬機不能使用鍵盤該怎麼辦？>[5], <安装虚拟机后键盘失灵>[6], <輸入問題故障排除>[7]




## Expected results
Here only provide results running on a solaris-10 system.
- This is the interface when the program runs successfully and ends within the specified time
<p align=center><img src="https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/edfab56b9fc041338bd3102960b6f624~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=623&h=198&e=png&b=fefefe" alt="屏幕截图 2023-08-29 163153.png" width="70%" /></p>

- This is the interface when the program is running normally
<p align=center><img src="https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d1c2e78d467c4741a384c609b52bde7c~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=641&h=165&e=png&b=fefefe" alt="屏幕截图 2023-08-29 163041.png" width="70%" /></p>

- This is the interface that stops running when the program occupies too much CPU.
<p align=center><img src="https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/fb805a29c90a464aa65b332c2a2f08a2~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=608&h=169&e=png&b=fefefe" alt="屏幕截图 2023-08-29 163716.png" width="70%" /></p>

- This is the interface when the program timeout, at this time the program automatically stops.
<p align=center><img src="https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/13a4187889354232b8ca0d181a527b12~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=617&h=198&e=png&b=fefefe" alt="屏幕截图 2023-08-29 162748.png" width="70%" /></p>

- This is a file generated under the specified path, and files that are too large will be automatically split.
<p align=center><img src="https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/586045648806480ea59ec1a7b6306ea9~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=680&h=141&e=png&b=fefefe" alt="屏幕截图 2023-08-29 162833.png" width="70%" /></p>

- This is the path output format of high-risk files, and OK means there is no problem.
<p align=center><img src="https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/fec660fdc76e43558c969c6a295ab112~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=409&h=187&e=png&b=fefefe" alt="屏幕截图 2023-08-29 162856.png" width="50%" /></p>


## Reference
 [1]: https://linuxhint.com/find-kill-zombie-process-linux/ 
 [2]: https://phoenixnap.com/kb/how-to-kill-a-process-in-linux#ftoc-heading-12
 [3]: https://www.infopackets.com/news/10475/how-fix-vmware-taking-ownership-virtual-machine-failed-error
 [4]: https://www.isharepc.com/36181.html 
 [5]: https://twcomputer.wsxdn.com/based/basiccomputerknowl/201510/27733.html
 [6]: https://juejin.cn/s/%E5%AE%89%E8%A3%85%E8%99%9A%E6%8B%9F%E6%9C%BA%E5%90%8E%E9%94%AE%E7%9B%98%E5%A4%B1%E7%81%B5
 [7]: https://docs.vmware.com/tw/VMware-Workstation-Pro/17/com.vmware.ws.using.doc/GUID-D677B10A-3590-460A-8141-709B4F8E4685.html
 [9]: https://www.vmware.com/products/workstation-pro/workstation-pro-evaluation.html 
 [10]: https://docs.vmware.com/en/VMware-Tools/12.2.0/com.vmware.vsphere.vmwaretools.doc/GUID-F223AEF5-AF32-4646-8177-FC1625B54366.html
 [11]: https://zhuanlan.zhihu.com/p/43920548
 [12]: https://blog.csdn.net/lq1759336950/article/details/104866536
 [13]: https://www.oracle.com/solaris/solaris10/downloads/solaris10-get-jsp-downloads.html
 [14]: https://www.linuxprobe.com/vmware-install-solaris10.html
Code for reference
- `RHL8` version
</br>Please refer to `script_RHL8.ksh`
- `Solaris` version
</br>Please refer to `Solaris.ksh`
- Regex rules
</br>Please refer to `regex.scv`
