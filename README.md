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
### Zombie process
1. **The situation we met**:
</br>When I tried to record all the paths of files through `find`, I surprisingly found that the program is still running even when I kill the program in the terminal. The size of file is growing and CPU in a high usage, I realize there must be a zombie process.
2. **What is Zombie process and how to prevent them?** 
- A zombie process or defunct process is a process  that has completed execution but still has an entry in the [process table](https://en.wikipedia.org/wiki/Process_table "Process table"): it is a process in the [Terminated state](https://en.wikipedia.org/wiki/Process_state#Terminated "Process state").
- Zombie processes are already dead processes but the parent process is unable to read its status and cannot be released from memory. So, the dead process cannot be killed.

3. **How to detect and kill ps the Zombie process:**
- `linux@linux-VirtualBox:~$ ps aux | egrep "Z|defunct"`
</br> In this command line, “ps” stands for the process state it is used to view the state of the process that is running in the system. This command is used to print all of the running processes that are stored in the memory. The second option passed “egrep” is a processing tool that is used to fetch the expressions or patterns in a specified location.When we execute the command, we will get the following output, which shows the zombie process in the system along with its “PID”. [1]
- `linux@linux-VirtualBox:~$ ps –o ppid= -p 33819`
</br> In the above command, we tried to get the parent id of the zombie process.
- `linux@linux-VirtualBox:~$ kill –s SIGCHLD  Parent_PID` or `kill -9 Parent_PID`[2]
</br> In the command above, we pass the signal to the parent id to kill the zombie process of the parent id passed to it.
<p align=center><img src="https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f0385fd5d7af4c1d8ce02551835e2730~tplv-k3u1fbpfcp-watermark.image?" alt="image.png"  width="70%"/></p>

4. **Zombie process casused by `find`**
- Since`find` is a recursive command, it will create loads of child processes to search into different directories. When the parent process is killed, there would be no *stop* command from the parent process so the child process will run until all files are traversed.
- I tried several methods, mainly trying to find the specific pid, collecting them into a variable and killing them respectively, but the result shows not working well. It won't be easy to kill the specific pid since the process is dynamic.
- Timeout function is a good command for dealing with this issue. The basic grammar is like: `timeout [OPTIONS] DURATION COMMAND [ARG]…`

### Errors in setting up a virtual machine
1. **VMWare 'Taking ownership of this virtual machine failed' Error**[3]
- launch Task Manager by pressing `CTRL+ALT+DEL` on the keyboard and end the process of vmware.exe
- Go to the folder containing the problematic virtual machine. Next, look for any " **.lck**" or " **.lock**" files AND folders. Cut these files into a `Temp` file folder, which is newly created.
- Start VMWare Workstation again.
2. **Keyboard and Mouse cannot connect to VMware**
- Disconnection of keyboard and mouse between VMware and your PC is quite common. Here are some reference links: <vmware虛擬機不能使用鍵盤該怎麼辦？>[5], <安装虚拟机后键盘失灵>[6], <輸入問題故障排除>[7]
3. **Windows host ssh connect to virtual machine**

- There is another way to use command line to control the virtual machine and login through `ssh`.
- How to start the Vmware through command line:
</br> I create a `.bat` file like this:
```
C:
cd "\Program Files (x86)\VMware\VMware Workstation"
vmrun -T ws start "C:\Users\<your username>\desktop\VMware-sol-10\Solaris-10-64-bit-kpmg.vmx" nogui
```
- First, you need to find the `ip` address of both your physical machine and virtual machine.[8]
- `ipconfig` in your `cmd` and record your `Wireless LAN adapter Wi-Fi`-`IPv4 Address` and `Subnet Mask`.
- Turn on your VMware and don't start any machine. Click `Edit` -> `Virtual Network Editor` -> (type - NAT) `Subnet Address`(you can also infer the subnet musk since the last digit is 0)
- Turn on your virtual machine and download some package: `sudo apt-get install openssh-server net-tools`, after downloading, you may use `ifconfig` to check your virtual machine's ip address.
- Modify your NAT setting, set the port number to `22` and input your virtual machine's `ip`. You may check the ssh config by `sudo vim /etc/ssh/ssh_config`, delete the `#` in front of `PasswordAuthentication yes` and `port 22`. Save the file by `esc` + `:wq`.
- You may test ssh connection by `ssh yourVMusername@yourVMip`

## Running on different system
During our engagement, code running on `RHEL8` is same as the code running on `kali-linux-2022.3-vmware-amd64`, so I will focus on the `Solaris`, `Unix` and `AIX` in the following page. Here is a brief history and relationship map between different linux operation system:
<p align=center><img src="https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/569d226bd8d54e028cf2eb41ec39b3f0~tplv-k3u1fbpfcp-watermark.image?" alt="image.png" width="70%" /></p>

### VMware download
1. Download from this website: https://www.vmware.com/products/workstation-pro/workstation-pro-evaluation.html 
2. Permanent key for VMware Pro:[4]
</br> key: `JU090-6039P-08409-8J0QH-2YR7F `

### Solaris-10 system
1. **What is Solaris system**
</br> Solaris is considered one of the derivatives of the UNIX operating system. Solaris is hybrid open source software.
2. **Different versions of Solaris**
</br> Noramlly there are two versions of Solaris DVD image, `SPARC` and `x86`. Please download it depends on your PC. You may check your device in System -> About -> System type.
</br> Download link: https://www.oracle.com/solaris/solaris10/downloads/solaris10-get-jsp-downloads.html
</br> You need to register a Oracle link before download the disc.
3. Setup through VMware
</br> Here is a detailed **tutorial** about how to setup:
https://www.linuxprobe.com/vmware-install-solaris10.html 
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

## Expected results and possible errors
  
## Reference
 [1]: https://linuxhint.com/find-kill-zombie-process-linux/ 
 [2]: https://phoenixnap.com/kb/how-to-kill-a-process-in-linux#ftoc-heading-12
 [3]: https://www.infopackets.com/news/10475/how-fix-vmware-taking-ownership-virtual-machine-failed-error
 [4]: https://www.isharepc.com/36181.html 
 [5]: https://twcomputer.wsxdn.com/based/basiccomputerknowl/201510/27733.html
 [6]: https://juejin.cn/s/%E5%AE%89%E8%A3%85%E8%99%9A%E6%8B%9F%E6%9C%BA%E5%90%8E%E9%94%AE%E7%9B%98%E5%A4%B1%E7%81%B5
 [7]: https://docs.vmware.com/tw/VMware-Workstation-Pro/17/com.vmware.ws.using.doc/GUID-D677B10A-3590-460A-8141-709B4F8E4685.html
 [8]: https://www.huoban.com/news/post/3040.html
Code for reference
- `RHL8` version
</br>Please refer to `script_RHL8.ksh`
