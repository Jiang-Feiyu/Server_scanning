# Server Scanning

## Overall
The program is capable of automatically traversing all files within the server, storing and printing their file names, performing regular expression searches based on sensitive content, screening for high-risk file paths and error messages, and storing them at the designated path after the scan is complete. Additionally, the program sets a scan time limit and CPU usage rate threshold to avoid affecting the normal operation of the server.
<p align=center><img src="https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/61f3b36a9a1f4edaa835c5a638ac6439~tplv-k3u1fbpfcp-watermark.image?" alt="image.png"  width="100%"/></p>

### server-scan function
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
- I tried several methods, mainly trying to find the specific pid, collecting them into a variable and killing them respectively, but the result shows not working well. The way I solve it is quite simple, 

## Expected results and possible errors

## Running on different system

## Code for reference
- `RHL8` version
</br>Please refer to `script_RHL8.ksh`

## Reference
 [1]: https://linuxhint.com/find-kill-zombie-process-linux/ 
 [2]: https://phoenixnap.com/kb/how-to-kill-a-process-in-linux#ftoc-heading-12
