# Server_scanning
This is a project for server scanning using bash script

# Mail Sending Script Documentation

18/7/2023

## Main Function Used

`curl`: The `curl` command is used with multiple parameters to send an email using SMTP protocol.

## What You Need to Prepare Before Running This Script

1. Change the `email address` and `password`. <br> You can search for the `FROM_EMAIL` and `EMAIL_PASSWORD` variables using `ctrl + F`.
2. Update your SMTP server address. <br> At the end of the script, replace your server address after the `curl --url` command in the format of `address:port`.
3. For *company side*, you need to update the recipient email address and the attachment file name. 
<br>If you want to zip or upload several files at the same time, you need to modify the `zip` function `zip $ZIP_FILENAME $ATTACHMENT_FILENAME` and the `upload file` function `--upload-file "$ZIP_FILENAME"`.

## How to Run the Script

1. Download the folder and save it locally.
2. Open the Linux terminal and navigate to the folder.<br>For example: `cd Desktop`
3. Input the following command: <br>`./demo-run.sh`<br> If the terminal shows `permission denied`, please try entering `chmod 777 demo-run.sh`.
