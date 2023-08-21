# Server Scanning
**Bob Jiang**
## Overall
The program is capable of automatically traversing all files within the server, storing and printing their file names, performing regular expression searches based on sensitive content, screening for high-risk file paths and error messages, and storing them at the designated path after the scan is complete. Additionally, the program sets a scan time limit and CPU usage rate threshold to avoid affecting the normal operation of the server.
<p align=center><img src="https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/61f3b36a9a1f4edaa835c5a638ac6439~tplv-k3u1fbpfcp-watermark.image?" alt="image.png"  width="100%"/></p>

This is a note of server scanning based on **regex**. The purpose of scanning is managing to detect possible high-risk files and save the path of the file for manual checking. The programme uses `KSH` (Korn Shell Script) and developed different versions for `AIX`, `Solaris` and `RHEL8` systems.
## Flow of the program
1. define the variables for scan path, network drive and obtain the hostname.
2. create the log file, hit file and error file.
3. obtain the information of all files under the path and add to the log file.
4. enters a loop, iterating and checking through the files in the scan path before timeout, sleep for a period if the CPU usage is too high.
5. split the files into multiple files of 10M size.
6. *The mail function has been finished seperately.*
## Technical issues
### Program introduction
#### Find files and format output
</br> Command: `find "$scanpath"`

| `-printf` | meaning |
| --- | ---|
| `%CY-%Cm-%Cd` | File modification date and time (year-month-day hours:minutes:seconds) |
| `%TY-%Tm-%Td` | File access date and time (year-month-day hours:minutes:seconds) |
| `%AY-%Am-%Ad %ATu` | Date and time the file was created (year-month-day hours:minutes:seconds) |
| `%u` | The username of the file owner |
| `%M` | Permissions of the file |

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

## Running on different system
During our engagement, code running on `RHEL8` is same as the code running on `kali-linux-2022.3-vmware-amd64`, so I will focus on the `Solaris`, `Unix` and `AIX` in the following page. Here is a brief history and relationship map between different linux operation system:
<p align=center><img src="https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/569d226bd8d54e028cf2eb41ec39b3f0~tplv-k3u1fbpfcp-watermark.image?" alt="image.png" width="70%" /></p>

### VMware download
1. Download from this website[9]
2. Permanent key for VMware Pro:[4]
</br> key: `JU090-6039P-08409-8J0QH-2YR7F `
### Solaris-10 system
#### **What is Solaris system**
Solaris is considered one of the derivatives of the UNIX operating system. Solaris is hybrid open source software.
</br> Noramlly there are two versions of Solaris DVD image, `SPARC` and `x86`. Please download it depends on your PC. You may check your device in System -> About -> System type.
</br> Download link: [13]
</br> You need to register a Oracle link before download the disc.
#### Setup through VMware
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
#### How to set a share holder on both host and virtual machine
- Install VM tools on your virtual machine, for more info, please click the reference link[10] if you need to download it manually.
- Turn off your virtual machine, and enable `share folder` in `VM`-> `Settings`-> `options` -> `Share folder`, create a new folder on your physical machine and paste the path as instructed.[11]
- Turn on the Virtual machine again and `cd /mnt/hgfs`, you will see your folder there.[12]
<p align=center><img src="https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/aae09e2f76c646218ca820acefdcfa43~tplv-k3u1fbpfcp-watermark.image?" alt="image.png" width="70%" /></p>

#### How to check which shell the system is using?
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
## Expected results and possible errors

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

正则匹配简介：https://www.softwaretestinghelp.com/unix-regular-expressions/
正则匹配和模式匹配
find: bad option -printf
报错：ls: illegal option --time-style=long-ios
