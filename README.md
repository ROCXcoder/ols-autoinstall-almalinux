<p align="center">
  <a href="https://okflash.net/" rel="noopener" target="_blank"><img width="150" src="https://avatars.githubusercontent.com/u/73544074" alt="OKFSoft logo"></a>
</p>
<h3 align="center">
  <img src="https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white" />
  <p>Auto Install OpenLiteSpeed Web Server for AlmaLinux</p>
</h3>
<div align="center">

Build a web server quickly. this is a script library for performing simple and customizable OpenLiteSpeed installations for faster and easier web server building.

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/rocxcoder/ols-autoinstall-almalinux/blob/root/LICENSE)
</div>

## 1. Installation Usage
You can start the installation by copying the code below and pasting it in the command line or you can use SSH with root user rights. The process will display a few questions to start installing the required packages.

    bash <( curl -k https://raw.githubusercontent.com/rocxcoder/ols-autoinstall-almalinux/root/install.sh )

Or use

    curl -sO https://raw.githubusercontent.com/rocxcoder/ols-autoinstall-almalinux/root/install.sh && chmod +x install.sh && ./install.sh

<br>

## 2. Programs to be installed
After you run the script, the script will propose several options for the installation of the program you can choose to install or not according to your needs.

- **OpenLiteSpeed web server**
- **LSPHP 7.1 - 8.0**
- **MariaDB 10.1 - 10.7**
- **ProFTPD**
- **phpMyAdmin 5.1.1**
- **net2ftp 1.3**

### 2.1. Creating Simple Scripts
Script will create a simple function on ( /root/scripts/ ) a simple script is used to create a Virtual Host, Delete, etc.

- host_create _(To create a New Virtual Host)_
- host_delete _(To remove Virtual Host)_

### Usage
You are in the root directory, copy and paste the script in the command line. To create a new virtual host.

    /scripts/host_create

You are in the root directory, copy and paste the script in the command line. To delete virtual hosts.

    /scripts/host_delete

<br>

## Suggestions

- Lack of Experience and Capabilities, Script definitely has a lot of flaws. We look forward to receiving your comments to make the script more perfect.

- Suggestions and feedback can be made via the [Github issue tracker](https://github.com/rocxcoder/ols-autoinstall-almalinux/issues).

<br>

## Contributors
I am grateful that this project exists thanks to all the best people who contributed.

- WofiNR

<br>

## License

Copyright © 2021 [rocxcoder](https://github.com/rocxcoder).
<br>
This project is licensed under the terms of the [MIT](https://github.com/rocxcoder/ols-autoinstall-almalinux/blob/root/LICENSE) licensed.

---