#!/bin/bash
mkdir -p /root/scripts/logs/
stty echo
{
#set -e
# bash <( curl -k https://raw.githubusercontent.com/rocxcoder/ols-autoinstall-almalinux/root/install.sh )
#############################################################################################
#                  OpenLiteSpeed Web Server Auto Installer for AlmaLinux 8                  #
#                                                                                           #
#                                     Author : OKFSoft                                      #
#                             Website: https://www.okflash.net                              #
#                           GitHub : https://github.com/okfsoft                             #
#             OpenLiteSpeed-Auto-Install-AlmaLinux-8, Copyright ©2021 OKFSoft               #
#                                Licensed under MIT License                                 #
#                                                                                           #
#                          Please do not remove copyright. Thank!                           #
#############################################################################################
#                                                                                           #
# MIT License                                                                               #
# -----------                                                                               #
#                                                                                           #
# Copyright (c) 2021 OKFSoft (https://www.okflash.net)                                      #
#                                                                                           #
# Permission is hereby granted, free of charge, to any person                               #
# obtaining a copy of this software and associated documentation                            #
# files (the "Software"), to deal in the Software without                                   #
# restriction, including without limitation the rights to use,                              #
# copy, modify, merge, publish, distribute, sublicense, and/or sell                         #
# copies of the Software, and to permit persons to whom the                                 #
# Software is furnished to do so, subject to the following                                  #
# conditions:                                                                               #
#                                                                                           #
# The above copyright notice and this permission notice shall be                            #
# included in all copies or substantial portions of the Software.                           #
#                                                                                           #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,                           #
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES                           #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                                  #
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT                               #
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,                              #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING                              #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR                             #
# OTHER DEALINGS IN THE SOFTWARE.                                                           #
#############################################################################################

#CONFIGURATION
############################################################################################
NC='\e[0m'
CL_GREEN='\033[1;92m'
CL_RED='\033[1;91m'
CL_ELLOW='\033[1;93m'
CL_BLUE='\033[1;94m'
CL_BLACK='\033[0;30m'
BG_RED='\e[0;41m'
BG_YELLOW='\e[0;43m'
BG_GREEEN='\e[0;42m'
TICK="[${CL_GREEN}✅${NC}]"
CROSS="[${CL_RED}❎${NC}]"
WARNING="[${CL_ELLOW}🔺${NC}]"
INFO=" [${CL_GREEN}➕${NC}]"
DONE="[${CL_GREEN}🔵${NC}]"
CHECK="${CL_GREEN}\u2714 ${NC}"
LINE="[✳ ]"
SET=" [${CL_GREEN}➕${NC}] $(date +%d-%m-%Y) $(date +%T) : "
SOK=" [${CL_GREEN}\u2714 ${NC}] $(date +%d-%m-%Y) $(date +%T) : "

#CONFIGURATION
############################################################################################
cRaw_Gith=https://raw.githubusercontent.com/rocxcoder/ols-autoinstall-almalinux/root
cConf_Path=/var/okfsoft-cfg
cOls_Root=/usr/local/lsws
cWeb_Root=/home
cVers_OLS="1.7.14"
cVPMA="5.1.1"
cHost_DB="localhost"
cPort_DB="3306"

#VARIABLES
############################################################################################
vHost_Name=$(hostname)
vLocal_IP=$(hostname -I | cut -d' ' -f1)
vPublic_IP=$(hostname -I | cut -d' ' -f1)
vDate_Now=$(date +%d-%m-%Y)-$(date +%H-%M-%S)
vSucc_Dom=0
vSucc_MDB=0
vSucc_PassOLS=0
vSts_Initialize=0

vOnlyOS="almalinux"
vPhpTime_Zone=";date.timezone ="

#GLOBAL FUNCTIONS
############################################################################################

# Checking the user has root access
function GF_Access_Root() {
  if [ "$EUID" -ne 0 ]; then
    return 1
  fi
}

# Take data in json file
function GF_Get_JsonDT() {
  #Checking the user has root access
  if GF_Files_Check /var/okfsoft-cfg/sys-info.json; then
    local a
    local b
    # shellcheck disable=SC2002
    a=$(cat /var/okfsoft-cfg/sys-info.json | jq '.'"$1")
    # shellcheck disable=SC2001
    b=$(echo "$a" | sed 's/"//g')
    [[ -z "$b" ]] && echo "null" || echo "$b"
  else
    echo "null"
  fi
}

# Checking directory status
function GF_Directory_Check() {
  if ! [ -d "$1" ]; then
    return 1
  else
    return 0
  fi
}

#Checking file status
function GF_Files_Check() {
  if ! [ -f "$1" ]; then
    return 1
  else
    return 0
  fi
}

# Checking service availability on the system
function GF_Service_Check() {
  # shellcheck disable=SC2126
  # shellcheck disable=SC2009
  if ! (($(ps -ef | grep -v grep | grep "$1" | wc -l) > 0)); then
    return 1
  else
    return 0
  fi
}

# Checking RPM packages on the system
function GF_Rpm_Chek() {
  # shellcheck disable=SC2046
  if [ $(rpm -qa|grep -c "$1") -gt 0 ]; then
    return 0
  else
    return 1
  fi
}

# Checking program availability and installation
function GF_App_Ins(){
  if ! hash "$1" 2>/dev/null; then
    echo -e "${SET} Get started Install $1"
    dnf install -y "$1"
  fi
}

# Checking installed programs on the system
function GF_Program_Check() {
    if hash "$1" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Generate Advanced Password
function GF_Pass_Random(){
    dd if=/dev/urandom bs=8 count=1 of=$cConf_Path/gen_password >/dev/null 2>&1
    # shellcheck disable=SC2155
    local RESULTS=$(cat $cConf_Path/gen_password) && rm -f $cConf_Path/gen_password
    # shellcheck disable=SC2155
    local DATE=$(date)
    echo "$RESULTS$DATE" |  md5sum | base64 | head -c 32
}

# Generate Simple Password
function GF_Pass_Generator() {
  # shellcheck disable=SC2155
  local out=$(date +%s | sha256sum | base64 | head -c "$1")
  echo "$2"-"$out"
}

# Check and generate ip information on system
function GF_Server_Info() {
  # Checking and creating this program directory
  if ! GF_Directory_Check $cConf_Path; then
    mkdir -p $cConf_Path
  fi
  # Checking the availability of the sys-info.json settings file
  if ! GF_Files_Check $cConf_Path/sys-info.json; then
    # Checking internet availability on the system
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
      # Get the public ip used on the system
      vPublic_IP=$(curl -s https://api.ipify.org)
	    # Get complete IP public information
      curl http://ip-api.com/json/"$vPublic_IP" --output $cConf_Path/sys-info.json
	    # Retrieve public ip on file sys-info.json
      vPublic_IP=$(GF_Get_JsonDT query)
	    # Retrieving Timezone on file sys-info.json
      vPhpTime_Zone="date.timezone = $(GF_Get_JsonDT timezone)"
    fi
  else
    vPublic_IP=$(GF_Get_JsonDT query)
    vPhpTime_Zone="date.timezone = $(GF_Get_JsonDT timezone)"
  fi
}

# Stop the process script
# shellcheck disable=SC2120
function GF_Exit_Process() {
  if [ "x$1" == "x" ]; then
    local msg="no process executed."
  else
    local msg="$1"
  fi
  clear
  stty echo
  echo
  echo -e " ${CROSS} ${CL_RED}Action aborted, $msg${NC}"
  echo
  exit 1
}

#-------------------------------------------------------------------------------------------
# Checks the required programs and installs them
GF_App_Ins "wget"
GF_App_Ins "zip"
GF_App_Ins "tar"
GF_App_Ins "jq"
GF_App_Ins "firewalld"
GF_App_Ins "openssl"
GF_App_Ins "sed"

# Checking the availability of the sys-info.json file
GF_Server_Info

# Checking the operating system type
function OS_Check(){
# shellcheck disable=SC2002
if [ "$(cat /etc/redhat-release | grep -i $vOnlyOS)x" != "x" ]; then
	DistroNam=$(cat /etc/redhat-release | cut -d ' ' -f1)
	DistroVer=$(cat /etc/redhat-release | awk '{print substr($3,1,1)}')
  echo
  echo -e " [info] This installation will use hostname(${CL_GREEN}$vHost_Name${NC}), please don't change the hostname after installation,"
  echo -e " [info] if you don't know what you are doing. If you want to change it do it first and rerun the installation script."
  echo
	echo -e " ${TICK} ${CL_GREEN}Operating system : ${DistroNam} $(cat /etc/redhat-release | cut -d ' ' -f3) ${NC}"
else
	echo -e " ${CROSS} ${CL_RED}Sorry, currently the installation only supports ${vOnlyOS} 8 or later.${NC}"
	echo
	exit 1
fi
}

# Check selinux status on system
function Selinux_Status() {
  local config_selinux
  local current_selinux
  if [[ -f /etc/selinux/config ]] && command -v getenforce &> /dev/null; then
  config_selinux=$(awk -F= '/^SELINUX=/ {print $2}' /etc/selinux/config)
  current_selinux=$(getenforce)
  if [ "x${current_selinux,,}" == "xenforcing" ]; then
		echo -e " ${CROSS} ${CL_RED}SELinux status on your system is ( ${current_selinux,,} ), the process cannot be continued,${NC}"
		echo -e " ${CROSS} ${CL_RED}Script doesn't support SELinux in enabled state, Please disable SELinux on the system to continue the installation.${NC}"
		echo
		read -e -p " ${LINE} Set SELinux to Disable [y/N] : " rDisableSelinux
		if [[ $rDisableSelinux =~ [yY](es)* ]]; then
			sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
			sudo sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
			echo -e " ${TICK} ${CL_GREEN} Please wait for the system to reboot in 2 seconds${NC}";
			echo
			sleep 2
			sudo shutdown -r now
		else
		  GF_Exit_Process
		fi
	else
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    sudo sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
	  echo -e " ${TICK} ${CL_GREEN}Status SELinux   : ${current_selinux}${NC}";
	fi
  else
    echo -e " ${CHECK} ${CL_GREEN}SELinux not detected${NC}"
  fi
}

# Initialize the system
function Initialize() {
  if ! GF_Access_Root; then
    GF_Exit_Process "you must run it with root privileges."
  fi
  OS_Check
  Selinux_Status
  echo -e " ${TICK} ${CL_GREEN}Hostname         : ${vHost_Name}${NC}";
  echo -e " ${TICK} ${CL_GREEN}Hostname IP      : ${vLocal_IP}${NC}";
  echo -e " ${TICK} ${CL_GREEN}Public IP        : ${vPublic_IP}${NC}";
  echo -e " ${TICK} ${CL_GREEN}Time/Zone        : $(GF_Get_JsonDT timezone)${NC}";
  echo
  read -e -p " ${LINE} Would you like to continue [y/Y] : " rInitialize
  if [[ $rInitialize =~ [yY](es)* ]]; then
    sed -i "/$vLocal_IP  $vHost_Name/d" /etc/hosts
    echo "$vLocal_IP  $vHost_Name" >> /etc/hosts
    vSts_Initialize=1
  else
    GF_Exit_Process "You choose to disagree"
  fi
}

# Please do not remove copyright. Thank!
function start_ascii_okf() {
stty echo
clear
echo -e "${CL_GREEN}
 OOOOOOOOOOO   KKK   KKK  FFFFFFFF  LLL             AAAAA        SSSSSSSSSSS  HHH     HHH
OOO       OOO  KKK  KKK   FFFFFFFF  LLL            AAA AAA       SSSSSSSSSSS  HHH     HHH
OOO       OOO  KKK KKK    FFF       LLL           AAA   AAA      SSS          HHH     HHH
OOO       OOO  KKKKK      FFFFFFFF  LLL          AAA     AAA     SSSSSSSSSSS  HHHHHHHHHHH${CL_RED}
OOO       OOO  KKKKK      FFFFFFFF  LLL         AAAAAAAAAAAAA    SSSSSSSSSSS  HHHHHHHHHHH
OOO       OOO  KKK KKK    FFF       LLL        AAAAAAAAAAAAAAA           SSS  HHH     HHH
OOO       OOO  KKK  KKK   FFF       LLLLLLLL  AAA           AAA  SSSSSSSSSSS  HHH     HHH
 OOOOOOOOOOO   KKK   KKK  FFF       LLLLLLLL AAA             AAA SSSSSSSSSSS  HHH     HHH${NC}"
echo
echo -e " ::: ================================================================================ :::${CL_GREEN}"
echo -e " :::        OpenLiteSpeed Web Server Auto Installer - https://www.okflash.net         :::${NC}"
echo -e " :::                                 Version : 1.0.0                                  :::"
echo -e " :::                          Copyright (c) 2021 - OKFSoft                            :::"
echo -e " :::                           Licensed under MIT License                             :::"
echo -e " ::: ================================================================================ :::"
echo -e " ::: Let's start installing the OpenLiteSpeed Web server and its dependencies         :::"
echo -e " ::: ================================================================================ :::"
echo
echo -e " ::: ================================================================================ :::"
echo
# Lewati inisialisasi sistem, jika memenuhi syarat
if [[ "${vSts_Initialize}" -eq 0 ]]; then
	Initialize
fi
echo
}

# User Information and Consent
function start_information_approval() {
echo -e " ::: ${BG_GREEEN}Packages to be installed on the system :${NC}"
echo -e " ::: ${CHECK} epel-release, tar, misc, zip, wget, certbot and openssl"
echo -e " ::: ${CHECK} OpenLiteSpeed"
echo -e " ::: ${CHECK} Database MariDB"
echo -e " ::: ${CHECK} ProFtpd"
echo
echo -e " ::: ${BG_GREEEN}Services to be implemented on the host :${NC}"
echo -e " ::: ${CHECK} phpMyAdmin v5.1.1"
echo -e " ::: ${CHECK} Web FTP Client"
echo
echo -e " ${WARNING}${CL_ELLOW} Script usage approval"
echo -e "      You are using a script (Auto Install OpenLiteSpeed Web Server), we have tested this script and it runs fine and"
echo -e "      We are not responsible for any damage to your system caused by using this script, please test it first before you use the main system.${NC}"
echo
echo -e " ::: ================================================================================ :::"
echo
read -e -p " ${LINE} Do you agree to continue?, to cancel press [any key], to continue press [y/Y] : " rApproval
if ! [[ $rApproval =~ [yY](es)* ]]; then
  GF_Exit_Process "You choose to disagree"
fi
}

# Setting OpenLiteSpeed Username and Password
function OLS_Config() {
  start_ascii_okf
    cUser_OLS="admin"
    cPass_OLS="admin123"
    read -e -p " ${LINE} Set OpenLiteSpeed Admin Username, press enter to use default [admin] : " rUser_OLS
    if ! [ "x${rUser_OLS,,}" == "x" ]; then
      cUser_OLS="${rUser_OLS,,}"
    fi
    while [ $vSucc_PassOLS -eq "0" ];  do
      stty -echo
      read -e -p "      ${LINE} Set OpenLiteSpeed Admin Password, press enter to use default [admin123] : " rPass_OLS
      if ! [ "x${rPass_OLS,,}" == "x" ]; then
        # shellcheck disable=SC2046
        if [ $(expr "$rPass_OLS" : '.*') -ge 6 ]; then
          echo
          stty -echo
          read -e -p "      ${LINE} Retype Admin Password OpenLiteSpeed : " rPassOLS_Retype
          stty echo
          if [ "x$rPass_OLS" = "x$rPassOLS_Retype" ]; then
            echo
            vSucc_PassOLS=1
            cPass_OLS=$rPassOLS_Retype
          else
            echo
            echo -e "      ${CROSS}${CL_RED} Error Sorry, passwords does not match. Try again!${NC}"
            stty echo
          fi
        else
          echo
          echo -e "      ${CROSS}${CL_RED} Error Sorry, password must be at least 6 charactors!${NC}"
          stty echo
        fi
      else
        echo
        stty echo
        vSucc_PassOLS=1
      fi
    done
}

# Setting up the MariaDB database
function MriaDB_Config() {
  start_ascii_okf
  cUser_DB="root"
  cPass_DB=$(GF_Pass_Generator 6 "$cUser_DB")
  echo -e " MariaDB Version List"
  echo
  echo -e " 1. MariaDB 10.1"
  echo -e " 2. MariaDB 10.2"
  echo -e " 3. MariaDB 10.3 (default)"
  echo -e " 4. MariaDB 10.4"
  echo -e " 5. MariaDB 10.5"
  echo -e " 6. MariaDB 10.6"
  echo -e " 7. MariaDB 10.7"
  echo
  # Selecting mariaDB database version
  while :; do
    read -e -p " ${LINE} Type the version number of mariaDB in the list above which will be installed on the server, [ example : 1] : " rSet_vMariaDB
    if [ "x${rSet_vMariaDB,,}" = "x" ]; then
      rSet_vMariaDB=3
    fi
    [[ $rSet_vMariaDB =~ ^[0-9]+$ ]] || { echo -e " ${CROSS} ${CL_RED}Enter valid number option${NC}"; continue; }
    # shellcheck disable=SC2004
    if [ "$rSet_vMariaDB" -ge 1 ] && [ "$rSet_vMariaDB" -le 7 ]; then
      cVer_MariaDB="10.$rSet_vMariaDB"
      break
    else
      echo -e " ${CROSS} ${CL_RED}Number option you entered is invalid, please try again.${NC}"
    fi
  done
  # Setting the MariaDB Database root password
  while [ $vSucc_MDB -eq "0" ];  do
    stty -echo
    read -e -p "      ${LINE} Set root password database, press enter to use default [$cPass_DB] : " rPass_DB
    if ! [ "x$rPass_DB" = "x" ]; then
    stty echo
    echo
      # shellcheck disable=SC2046
      if [ $(expr "$rPass_DB" : '.*') -ge 6 ]; then
        stty -echo
        read -e -p "      ${LINE} Retype root password database : " rPassDB_Retype
        stty echo
        echo
        if [ "x$rPass_DB" = "x$rPassDB_Retype" ]; then
          echo
          vSucc_MDB=1
          cPass_DB=$rPassDB_Retype
        else
          echo
          echo -e "      ${CROSS}${CL_RED} Error Sorry, passwords does not match. Try again!${NC}"
          stty echo
        fi
      else
        echo
        echo -e "      ${CROSS}${CL_RED} Error Sorry, password must be at least 6 charactors!${NC}"
        stty echo
      fi
    else
      echo
      stty echo
      vSucc_MDB=1
    fi
  done
}

# Setting up a phpMyAdmin connection if the database server is separate from the system
function PMA_Config() {
    # Specifying the phpMyAdmin database host
    start_ascii_okf
    vSet_HostDB=0
    echo -e " [info] You didn't install the database engine on the system, but you chose to implement phpMyAdmin,"
    echo -e " [info] Do you have a separate database engine?,"
    echo -e " [info] If so, you will specify the phpMyAdmin connection host settings to make it work."
    echo
    read -e -p " ${LINE} Are you using a separate database engine? [y/N] : " rSet_HostDB
    # Process of setting database host and port on phpMyAdmin
    if [[ $rSet_HostDB =~ [yY](es)* ]]; then
      while [ $vSet_HostDB -eq "0" ];  do
        read -e -p "      ${LINE} IP address or Database Host in use, [example: db.example.com or 10.10.10.1] : " rHost_DB
        if ! [ "x$rHost_DB" = "x" ]; then
          read -e -p "      ${LINE} Database port you are using, default [3306] : " rPort_DB
          # Uses default port 3306 if not specified
          if [ "x${rPort_DB,,}" != "x" ]; then
            cPort_DB=${rPort_DB,,}
          fi
          # Checking host connection status and database port
          echo -e "      [..] Checking host connection.."
          if ! timeout 1 bash -c "echo > /dev/tcp/$rHost_DB/$cPort_DB"; then
            echo -e "      ${CROSS} Connection to host $rHost_DB on port $cPort_DB has failed"
            echo
          else
            echo -e "      ${TICK} Connection to host $rHost_DB on port $cPort_DB has been successful"
            cHost_DB="$rHost_DB:$cPort_DB"
            vSet_HostDB=1
            echo
          fi 2>/dev/null
        else
          # Displays an error message if the host is not set up correctly or is unable to connect
          echo
          echo -e "      ${CROSS}${CL_RED} Error Sorry, You did not specify anything for the phpMyAdmin connection.${NC}"
        fi
      done
    else
      # exited and displayed error message chose to apply phpMyAdmin but set nothing
      GF_Exit_Process "You chose to implement phpMyAdmin, but you didn't specify a connection"
    fi
}


# Start
start_ascii_okf
start_information_approval

if [[ $rApproval =~ [yY](es)* ]]; then
  start_ascii_okf
  # Select (Y) to install OpenLiteSpeed
  read -e -p " ${LINE} Install OpenLiteSpeed   [y/Y] : " rInstall_OLS
  # Selecting (Y) to install MariaDB
  read -e -p " ${LINE} Install Database MariDB [y/Y] : " rInstall_MariDB
  # Selecting (Y) to install ProFTPD
  read -e -p " ${LINE} Install FTP ProFtpd     [y/Y] : " rInstall_ProFtpd

  # Optional installation of phpMyAdmin and Web FTP Client will be displayed if OpenLiteSpeed is installed
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then
    # Choose (Y) to install phpMyAdmin
    read -e -p " ${LINE} Implemented phpMyAdmin  [y/Y] : " rInstall_PMA
    if [[ $rInstall_ProFtpd =~ [yY](es)* ]]; then
	    # Select (Y) to install Web FTP
      read -e -p " ${LINE} Implemented Web FTP     [y/Y] : " rInstall_WebFTP
    fi
  fi

  # Check Validation of selected base program
  AppVal=0
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then AppVal="$((AppVal+1))"; fi
  if [[ $rInstall_MariDB =~ [yY](es)* ]]; then AppVal="$((AppVal+1))"; fi
  if [[ $rInstall_ProFtpd =~ [yY](es)* ]]; then AppVal="$((AppVal+1))"; fi
  if [ $AppVal -eq 0 ]; then
	# Exits and displays a message that none of the basic programs have been selected
    GF_Exit_Process "You don't choose anything, the process is stopped."
  fi

  # If you install OpenLiteSpeed
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then
    # Making settings
    if GF_Service_Check "lshttpd"; then
      GF_Exit_Process "Process terminated, Script detect system installed OpenLiteSpeed"
    fi
    OLS_Config
  fi

  # If you install OpenLiteSpeed
  if [[ $rInstall_ProFtpd =~ [yY](es)* ]]; then
    # Making settings
    if GF_Service_Check "proftpd"; then
      GF_Exit_Process "Process terminated, Script detect system installed ProFTPD"
    fi
  fi

  # If installing MariaDB Database
  if [[ $rInstall_MariDB =~ [yY](es)* ]]; then
	  # Making settings
    if GF_Service_Check "mysql"; then
      GF_Exit_Process "Process terminated, Script detect system installed MariaDB"
    fi
    MriaDB_Config
  else
    # Configuring PMA, because choosing to implement phpMyAdmin but not installing the database engine on the local system
    if [[ $rInstall_PMA =~ [yY](es)* ]]; then
	    # Making settings
      PMA_Config
    fi
  fi

  # Displaying the installation information before doing the core process
  start_ascii_okf
  echo -e " [info] Below is a snippet of the settings and options that will be implemented, please review,"
  echo -e " [info] if something is missed and run the script again, or continue the installation process. ."
  echo
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then echo -e " ${TICK} ${CL_GREEN}OpenLiteSpeed${NC}"; else  echo -e " ${CROSS} ${CL_RED}OpenLiteSpeed${NC}"; fi
  if [[ $rInstall_MariDB =~ [yY](es)* ]]; then echo -e " ${TICK} ${CL_GREEN}Database MariDB $cVer_MariaDB${NC}"; else echo -e " ${CROSS} ${CL_RED}Database MariDB${NC}"; fi
  if [[ $rInstall_ProFtpd =~ [yY](es)* ]]; then echo -e " ${TICK} ${CL_GREEN}FTP ProFtpd${NC}"; else echo -e " ${CROSS} ${CL_RED}FTP ProFtpd${NC}"; fi
  if [[ $rInstall_PMA =~ [yY](es)* ]]; then echo -e " ${TICK} ${CL_GREEN}phpMyAdmin v5.1.1${NC}"; else echo -e " ${CROSS} ${CL_RED}phpMyAdmin v5.1.1${NC}"; fi
  if [[ $rInstall_WebFTP =~ [yY](es)* ]]; then echo -e " ${TICK} ${CL_GREEN}Web FTP${NC}"; else echo -e " ${CROSS} ${CL_RED}Web FTP${NC}"; fi
  echo
  # Displaying OpenLiteSpeed installation information
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then
    echo -e " [info] ${BG_GREEEN} OpenLiteSpeed Configuration ${NC}"
    echo -e " [info] ${BG_GREEEN} Script installs and configures OpenLiteSpeed version $cVers_OLS, then checks for and installs the latest version if found. ${NC}"
    echo -e " ${DONE} OpenLiteSpeed Version      : $cVers_OLS"
    echo -e " ${DONE} OpenLiteSpeed Username     : $cUser_OLS"
    echo -e " ${DONE} OpenLiteSpeed Password     : $cPass_OLS"
  fi
  echo
  # Displaying MariaDB installation information
  if [[ $rInstall_MariDB =~ [yY](es)* ]]; then
    echo -e " [info] ${BG_GREEEN} MariaDB Configuration ${NC}"
    echo -e " ${DONE} MariaDB version            : $cVer_MariaDB"
    echo -e " ${DONE} MariaDB Username           : $cUser_DB"
    echo -e " ${DONE} MariaDB Password           : $cPass_DB"
  fi
  echo
  # Displaying ProFtpd instalasi installation Information
  if [[ $rInstall_ProFtpd =~ [yY](es)* ]]; then
    echo -e " [info] ${BG_GREEEN} ProFtpd Configuration ${NC}"
    echo -e " ${DONE} ProFtpd Host               : $vLocal_IP"
    echo -e " ${DONE} ProFtpd Port               : 21"
  fi
  echo
  # Displaying phpMyAdmin installation information
  if [[ $rInstall_PMA =~ [yY](es)* ]]; then
    echo -e " [info] ${BG_GREEEN} phpMyAdmin Configuration ${NC}"
    if [[ $rSet_HostDB =~ [yY](es)* ]]; then echo -e " ${DONE} Separate database server   : Yes"; else echo -e " ${DONE} Separate database server   : No"; fi
    echo -e " ${DONE} Host connection phpMyAdmin : $cHost_DB"
    echo -e " ${DONE} Port connection phpMyAdmin : $cPort_DB"
  fi
  echo
  # Approve the installation process
  read -e -p " ${LINE} If you are sure to continue with the installation type [y/N] : " rStart_Install
  # Installation aborted
  if ! [[ $rStart_Install =~ [yY](es)* ]]; then
    GF_Exit_Process
  fi
fi

# System Preparation
function Prepare_System() {
  echo -e "${SET} Clean system system"
  dnf clean all

  # Added OpenLiteSpeed Repository
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then
	# Checked the OpenLiteSpeed repository and installed it
    if GF_Rpm_Chek "litespeed"; then
      # Removed litespeedtech repository if found and added
      echo -e "${SET} Removed the litespeedtech repo and dependencies"
      dnf -y remove 'litespeed*'
      dnf autoremove
      rm -f /etc/yum.repos.d/{litespeed.repo.bak,litespeed.repo.rpmsave}
      # Fix Error Invalid failovermethod OpenLiteSpeed in AlmaLinux 5.8
      rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el8.noarch.rpm
      sudo sed -i".bak" '/^failovermethod=/d' /etc/yum.repos.d/litespeed.repo
      sudo sed -i '/^failovermethod=/d' /etc/yum.repos.d/litespeed.repo
    else
      echo -e "${SET} Add repository OpenLiteSpeed"
      # Fix Error Invalid failovermethod OpenLiteSpeed in AlmaLinux 5.8
      rpm -Uvh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el8.noarch.rpm
      sudo sed -i".bak" '/^failovermethod=/d' /etc/yum.repos.d/litespeed.repo
      sudo sed -i '/^failovermethod=/d' /etc/yum.repos.d/litespeed.repo
    fi
  fi

  # Adding MariaDB Repository
  if [[ $rInstall_MariDB =~ [yY](es)* ]]; then
    echo -e "${SET} Add repository MariaDB $cVer_MariaDB"
    wget -O /etc/yum.repos.d/mariadb.repo $cRaw_Gith/repository/MariaDB.repo
    sed -i "s/##VERMARIADB##/$cVer_MariaDB/g" /etc/yum.repos.d/mariadb.repo
    rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
  fi

  # Check availability of Packages and install them
  if ! GF_Rpm_Chek "epel-release"; then
    echo -e "${SET} Get started epel-release and dependencies"
    dnf -y install epel-release
  fi

  # shellcheck disable=SC2002
  echo -e "${SET} Get started update System ${DistroNam} $(cat /etc/redhat-release | cut -d ' ' -f3)"
  # Clean and update the system
  dnf clean all
  dnf -y update
}

# The installation process is carried out
if [[ $rStart_Install =~ [yY](es)* ]]; then
  start_ascii_okf
  Prepare_System
  vStatus_DB=0
  vStatus_OLS=0
  vStatus_FTP=0

  # Start installing OpenLiteSpeed and php Packages
  if [[ $rInstall_OLS =~ [yY](es)* ]]; then
	echo -e "${SET} Get started Install certbot"
	dnf -y install certbot
    echo -e "${SET} Get started psmisc and dependencies"
    dnf -y install psmisc
    dnf -y install rcs
    echo -e "${SET} Get started OpenLiteSpeed and dependencies"
    dnf install -y openlitespeed-$cVers_OLS
    echo -e "${SET} Get started php v7.3 OpenLiteSpeed and dependencies"
    dnf -y install lsphp73 lsphp73-bcmath lsphp73-gmp lsphp73-intl lsphp73-json lsphp73-ldap lsphp73-xmlrpc lsphp73-zip lsphp73-ioncube lsphp73-pspell lsphp73-soap
    echo -e "${SET} Get started php v7.2 OpenLiteSpeed and dependencies"
    dnf -y install lsphp72 lsphp72-common lsphp72-gd lsphp72-imap lsphp72-mbstring lsphp72-mysqlnd lsphp72-opcache lsphp72-pdo lsphp72-pecl-mcrypt lsphp72-process lsphp72-xml lsphp72-bcmath lsphp72-gmp lsphp72-intl lsphp72-json lsphp72-ldap lsphp72-xmlrpc lsphp72-zip lsphp72-ioncube lsphp72-pspell lsphp72-soap
    echo -e "${SET} Get started php v7.4 OpenLiteSpeed and dependencies"
    dnf -y install lsphp74 lsphp74-common lsphp74-gd lsphp74-imap lsphp74-mbstring lsphp74-mysqlnd lsphp74-opcache lsphp74-pdo lsphp74-pecl-mcrypt lsphp74-process lsphp74-xml lsphp74-bcmath lsphp74-gmp lsphp74-intl lsphp74-json lsphp74-ldap lsphp74-xmlrpc lsphp74-zip lsphp74-ioncube lsphp74-pspell lsphp74-soap
    echo -e "${SET} Get started php v8.0 OpenLiteSpeed and dependencies"
    dnf -y install lsphp80 lsphp80-common lsphp80-gd lsphp80-imap lsphp80-mbstring lsphp80-mysqlnd lsphp80-opcache lsphp80-pdo lsphp80-process lsphp80-xml lsphp80-bcmath lsphp80-gmp lsphp80-intl lsphp80-json lsphp80-ldap lsphp80-zip lsphp80-pspell lsphp80-soap
    vStatus_OLS=1
  fi

  # Start installing MariaDB
  if [[ $rInstall_MariDB =~ [yY](es)* ]]; then
    echo -e "${SET} Get started MariaDB $cVer_MariaDB and dependencies"
    dnf -y install mariadb mariadb-server
    vStatus_DB=1
  fi

  # Start installing ProFtpd
  if [[ $rInstall_ProFtpd =~ [yY](es)* ]]; then
    GF_App_Ins "proftpd"
    vStatus_FTP=1
  fi

fi

# Configure ProFTPD if installed
if [ $vStatus_FTP -eq "1" ]; then
 sed -i "s/ProFTPD server/$vHost_Name/g" /etc/proftpd.conf
 systemctl start proftpd && systemctl enable proftpd
	if [[ $(firewall-cmd --list-services) != *"ftp"* ]]; then
	  sudo firewall-cmd --zone=public --permanent --add-service=ftp
	fi
  info_ins_ftp=" ${CHECK} Install ProFtpd Successfully"
fi


# Configure OpenLiteSpeed Web Server if installed
if [ $vStatus_OLS -eq "1" ]; then
  echo -e "${SET} Getting started with basic OpenLiteSpeed Web Server setup"
  echo -e "${SET} Update OpenLiteSpeed password"
	Gencrypt=$($cOls_Root/admin/fcgi-bin/admin_php -q $cOls_Root/admin/misc/htpasswd.php "$cPass_OLS")
	echo "$cUser_OLS:$Gencrypt" > $cOls_Root/admin/conf/htpasswd
	# shellcheck disable=SC2181
	if [ $? -eq 0 ]; then
		echo -e " ${TICK} OpenLiteSpeed Administrator's username/password is updated successfully!${NC}"
	fi

	# Variables konfigurasi lsphp
	lsphp72=$cOls_Root/lsphp72/etc/php.ini
	lsphp73=$cOls_Root/lsphp73/etc/php.ini
	lsphp74=$cOls_Root/lsphp74/etc/php.ini
	lsphp80=$cOls_Root/lsphp80/etc/php.ini
	lsphpConfig="s|/var/lib/php/session|/var/lib/lsphp/session|;s|upload_max_filesize = 2M|upload_max_filesize = 50M|;s|post_max_size = 8M|post_max_size = 50M|;s|; max_input_vars = 1000|max_input_vars = 2000|;s|memory_limit = 128M|memory_limit = 256M|;s|;date.timezone =|$vPhpTime_Zone|;s|;date.timezone =|$vPhpTime_Zone|;"

	# Backup the php.ini file to lsphp
	echo -e "${SET} Backup file php[72,73,74,80].ini"
	cp $cOls_Root/lsphp72/etc/php.ini $cOls_Root/lsphp72/etc/"$vDate_Now"-php.ini.bak
	cp $cOls_Root/lsphp73/etc/php.ini $cOls_Root/lsphp73/etc/"$vDate_Now"-php.ini.bak
	cp $cOls_Root/lsphp74/etc/php.ini $cOls_Root/lsphp74/etc/"$vDate_Now"-php.ini.bak
	cp $cOls_Root/lsphp80/etc/php.ini $cOls_Root/lsphp80/etc/"$vDate_Now"-php.ini.bak

	# Perform default settings on php.ini
	echo -e "${SET} Merubah pengaturan default file php.ini"
	sed -i "$lsphpConfig" $lsphp72
	sed -i "$lsphpConfig" $lsphp73
	sed -i "$lsphpConfig" $lsphp74
	sed -i "$lsphpConfig" $lsphp80

	# Checking the lsphp session folder and creating it
  if ! GF_Directory_Check "/var/lib/lsphp/"; then
    echo -e "${SET} Create lsphp session folder, and set permissions"
    mkdir -p /var/lib/lsphp/{session,wsdlcache}
  else
    echo -e "${SET} Recreate lsphp session folder, and set the permissions"
    rm -rf /var/lib/lsphp/
    mkdir -p /var/lib/lsphp/{session,wsdlcache}
  fi

	# Checked lsphp log folder and created it
  if ! GF_Directory_Check "/var/log/lsphp/"; then
    echo -e "${SET} Create lsphp log folder"
		mkdir -p /var/log/lsphp
	else
	  echo -e "${SET} Recreate lsphp log folder"
		rm -rf /var/log/lsphp/
		mkdir -p /var/log/lsphp
  fi

  # Check and create lshttpd service on system
  if GF_Files_Check "/usr/lib/systemd/system/lshttpd.service"; then
    echo -e "${SET} Create OpenLiteSpeed service"
		sudo /usr/local/lsws/bin/lswsctrl stop
		sudo cp /usr/local/lsws/admin/misc/lshttpd.service /usr/lib/systemd/system/lshttpd.service
		sudo systemctl daemon-reload
  fi

  # OpenLiteSpeed file and folder creation
  echo -e "${SET} Create OpenLiteSpeed host default files and folders"
  VH_ROOT="usr\/local\/lsws\/www\/$vHost_Name"
  vDefault_Root="$cOls_Root/www/$vHost_Name"
  mkdir -p $cOls_Root/www/backup
  mkdir -p "$vDefault_Root"/{public_html,logs}
	mkdir -p $cOls_Root/conf/cert/www-ssl
	mkdir -p $cOls_Root/conf/cert/"$vHost_Name"
	touch "$vDefault_Root"/logs/{error.log,access.log}

	# Apply templates and backup templates Example
  echo -e "${SET} Apply new templates and backup default templates"
	cd $cOls_Root/
	zip -r -qq $cOls_Root/www/backup/backup-example.zip Example
	rm -rf $cOls_Root/Example
	cd "$vDefault_Root"/public_html/
	wget $cRaw_Gith/templates/www-default.tar.gz
	tar -xzf www-default.tar.gz
	rm -f www-default.tar.gz
	cd /
	sed -i "s/##DOMAIN##/$vHost_Name/g;s/##LINK##/$vLocal_IP:821/g" "$vDefault_Root"/public_html/index.php

	# Fetching vHost setup template on git
	echo -e "${SET} Creating virtual host templates"
	wget -O $cOls_Root/conf/templates/httpd_inc.conf $cRaw_Gith/config/ols/templates/httpd_inc.conf
  wget -O $cOls_Root/conf/templates/vhcon_inc.conf $cRaw_Gith/config/ols/templates/vhcon_inc.conf

	# Making vhosts Example configuration changes for hostname
	echo -e "${SET} Change Example templates"
	mv -f $cOls_Root/conf/vhosts/Example/ $cOls_Root/conf/vhosts/"$vHost_Name"/
	rm -f $cOls_Root/conf/vhosts/"$vHost_Name"/vhconf.conf
	wget -O $cOls_Root/conf/vhosts/"$vHost_Name"/vhconf.conf $cRaw_Gith/config/ols/vhconf.conf
	sed -i "s/##HOSTNAME##/$vHost_Name/g" $cOls_Root/conf/vhosts/"$vHost_Name"/vhconf.conf
	sed -i "s/##VHROOT##/$VH_ROOT/g" $cOls_Root/conf/vhosts/"$vHost_Name"/vhconf.conf

	# Take the httpd_config configuration template and apply it
	echo -e "${SET} OpenLiteSpeed httpd configuration"
	cp $cOls_Root/conf/httpd_config.conf $cOls_Root/conf/"$vDate_Now"-httpd_config.conf.bak
	rm -f $cOls_Root/conf/httpd_config.conf
	wget -O $cOls_Root/conf/httpd_config.conf $cRaw_Gith/config/ols/httpd_config.conf
	sed -i "s/##HOSTNAME##/$vHost_Name/g" $cOls_Root/conf/httpd_config.conf
	sed -i "s/##IPHOSTNAME##/$vLocal_IP/g" $cOls_Root/conf/httpd_config.conf

  # Fetch script to create new virtual host
  mkdir -p /root/scripts/template
  wget -O /root/scripts/template/www-vh-template.tar.gz $cRaw_Gith/templates/www-vh-template.tar.gz
  wget -O /root/scripts/host_create $cRaw_Gith/scripts/host_create
  wget -O /root/scripts/host_delete $cRaw_Gith/scripts/host_delete
  chmod +x /root/scripts/{host_create,host_delete}

	# SSL configuration variables
	echo -e "${SET} Config SSL Certificates"
	Subject_SSL="/CN=$vHost_Name/DC=$vLocal_IP/C=$(GF_Get_JsonDT countryCode)/ST=$(GF_Get_JsonDT country)/L=$(GF_Get_JsonDT regionName)/O=$vHost_Name Cloud/OU=$vHost_Name Cloud/emailAddress=mail@$vHost_Name"
	Admin_SSL=$cOls_Root/admin/conf
	Default_SSL=$cOls_Root/conf/cert/www-ssl/www-ssl
  Host_SSL=$cOls_Root/conf/cert/$vHost_Name/$vHost_Name

  # Generate SSL Certificates for default host
  echo -e "${SET} Generate default SSL Certificates"
  openssl genrsa -out $Default_SSL.key 2048
  openssl rsa -in $Default_SSL.key -out $Default_SSL.key
  openssl req -sha256 -new -key $Default_SSL.key -out $Default_SSL.csr -subj "$Subject_SSL" -config /etc/pki/tls/openssl.cnf -extensions v3_req
  openssl x509 -req -sha256 -days 3650 -in $Default_SSL.csr -signkey $Default_SSL.key -out $Default_SSL.crt -extfile /etc/pki/tls/openssl.cnf  -extensions v3_req && rm -f $Default_SSL.csr

  # Generate SSL Certificates for admin web server
	echo -e "${SET} Generate SSL Certificates for admin web server"
	cd $cOls_Root/admin/conf/
	tar -czvf "$vDate_Now"-ssl_backup.tar.gz webadmin.crt webadmin.key admin_config.conf
	rm -f $Admin_SSL/{webadmin.crt,webadmin.key,admin_config.conf}
	wget -O $Admin_SSL/admin_config.conf $cRaw_Gith/config/ols/admin_config.conf
	openssl genrsa -out $cOls_Root/admin/conf/webadmin.key 2048
	openssl rsa -in $Admin_SSL/webadmin.key -out $Admin_SSL/webadmin.key
	openssl req -sha256 -new -key $Admin_SSL/webadmin.key -out $Admin_SSL/webadmin.csr -subj "$Subject_SSL" -config /etc/pki/tls/openssl.cnf -extensions v3_req
	openssl x509 -req -sha256 -days 3650 -in $Admin_SSL/webadmin.csr -signkey $Admin_SSL/webadmin.key -out $Admin_SSL/webadmin.crt -extfile /etc/pki/tls/openssl.cnf -extensions v3_req && rm -f $Admin_SSL/webadmin.csr

	# Generate SSL Certificates for vHost Default
	echo -e "${SET} Generate SSL Certificates for default host"
	openssl genrsa -out "$Host_SSL".key 2048
	openssl rsa -in "$Host_SSL".key -out "$Host_SSL".key
	openssl req -sha256 -new -key "$Host_SSL".key -out "$Host_SSL".csr -subj "$Subject_SSL" -config /etc/pki/tls/openssl.cnf -extensions v3_req
	openssl x509 -req -sha256 -days 3650 -in "$Host_SSL".csr -signkey "$Host_SSL".key -out "$Host_SSL".crt -extfile /etc/pki/tls/openssl.cnf  -extensions v3_req && rm -f "$Host_SSL".csr

	# Fix permissions folder and files
	echo -e "${SET} Fix permissions folder and files"
	chown -R nobody:nobody /var/lib/lsphp/ && chmod -R 777 /var/lib/lsphp/{session,wsdlcache}
	chown root:nobody /var/log/lsphp/ && chmod -R 750 /var/log/lsphp/
  chown lsadm:nobody $cOls_Root/conf/templates/{httpd_inc.conf,vhcon_inc.conf} && chmod 750 $cOls_Root/conf/templates/{httpd_inc.conf,vhcon_inc.conf}
	chown lsadm:nobody $cOls_Root/conf/vhosts/"$vHost_Name"/vhconf.conf && chmod 750 $cOls_Root/conf/vhosts/"$vHost_Name"/vhconf.conf
	chown lsadm:nobody $cOls_Root/conf/httpd_config.conf && chmod 750 $cOls_Root/conf/httpd_config.conf
  chown nobody:nobody "$vDefault_Root"/logs/{error.log,access.log}
	chown lsadm:nobody $Admin_SSL/admin_config.conf && chmod 644 $Admin_SSL/admin_config.conf
	chown lsadm:lsadm $Admin_SSL/{webadmin.crt,webadmin.key} && chmod 400 $Admin_SSL/{webadmin.crt,webadmin.key}

  # Added OpenLiteSpeed port access and services on firewallD
  if [[ $(firewall-cmd --list-services) != *"http"* ]]; then
    sudo firewall-cmd --zone=public --permanent --add-service=http
  fi
  if [[ $(firewall-cmd --list-services) != *"https"* ]]; then
    sudo firewall-cmd --zone=public --permanent --add-service=https
  fi
  if [[ $(firewall-cmd --list-ports) != *"7080/tcp"* ]]; then
    sudo firewall-cmd --zone=public --permanent --add-port=7080/tcp
  fi
  if [[ $(firewall-cmd --list-ports) != *"821/tcp"* ]]; then
    sudo firewall-cmd --zone=public --permanent --add-port=821/tcp
  fi
  # Restarting OpenLiteSpeopenlitespeeded
  systemctl restart lshttpd
  sudo killall -9 lsphp
  # Update openlitespeed if the latest version is found, because all installations and configurations start with openlitespeed version 1.7.14
  dnf -y update openlitespeed
	# Checking the installed version of OpenLiteSpeed
  if GF_Service_Check "lshttpd"; then
    echo -e "${SET} Checking OpenLiteSpeed version"
    # shellcheck disable=SC2046
    # shellcheck disable=SC2005
    # shellcheck disable=SC2006
    # shellcheck disable=SC2006
    cVers_OLS=$(echo `/usr/local/lsws/bin/lshttpd -v` | grep -oP '(?<=LiteSpeed/)[a-zA-Z0-9\.-]*(?=\ Open)')
  fi
  info_ins_ols=" ${CHECK} Installation OpenLiteSpeed Successfully"
fi


# Starting the mariaDB database setup if installing it
if [ $vStatus_DB -eq "1" ]; then
	systemctl start mariadb
    if [ "$rSet_vMariaDB" -ge 1 ] && [ "$rSet_vMariaDB" -le 3 ]; then
      mysql -uroot -v -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
      mysql -uroot -v -e "DROP DATABASE test;"
      mysql -uroot -v -e "DELETE FROM mysql.user WHERE User='';"
      mysql -uroot -v -e "use mysql;update user set Password=PASSWORD('$cPass_DB') where user='$cUser_DB'; flush privileges;"
    fi
    if [ "$rSet_vMariaDB" -ge 4 ] && [ "$rSet_vMariaDB" -le 7 ]; then
      mysql -uroot -v -e "use mysql;DELETE FROM mysql.db WHERE User='' AND Host='%';"
      mysql -uroot -v -e "DROP DATABASE test;"
      mysql -uroot -v -e "use mysql;SET PASSWORD FOR '$cUser_DB'@'localhost' = PASSWORD('$cPass_DB'); flush privileges;"
    fi
	if [[ $(firewall-cmd --list-services) != *"mysql"* ]]; then
	  sudo firewall-cmd --zone=public --permanent --add-service=mysql
	fi
	systemctl enable mariadb
	systemctl restart mariadb
    info_ins_db=" ${CHECK} Installation MariaDB Successfully"
#Save Password Database
cat << EOT > /root/scripts/.MariaDB
$cPass_DB
EOT
fi

# install a net2ftp web ftp client if you so choose
if [[ $rInstall_WebFTP =~ [yY](es)* ]]; then
  echo -e "${SET} Implemented WEB FTP"
  rm -rf "$vDefault_Root/public_html/filemanager"
  mkdir -p "$vDefault_Root/public_html/filemanager"
  mkdir -p "$vDefault_Root/public_html/tmp"
  cd "$vDefault_Root/public_html/tmp/"
  wget --no-check-certificate -O "$vDefault_Root/public_html/tmp/net2ftp.zip" https://www.net2ftp.com/download/net2ftp_v1.3.zip
  unzip -qq net2ftp.zip
  mv "$vDefault_Root"/public_html/tmp/net2ftp_v1.3/files_to_upload/* "$vDefault_Root/public_html/filemanager/"
  rm -rf net2ftp_v1.3
  rm -rf net2ftp.zip
  rm -rf "$vDefault_Root/public_html/tmp"
  cd /
  chown -R nobody:nobody "$vDefault_Root"/public_html/filemanager/modules/upload
  chown -R nobody:nobody "$vDefault_Root"/public_html/filemanager/temp
  chmod -R 777 "$vDefault_Root"/public_html/filemanager/temp
  info_ins_webftp=" ${CHECK} Implemented WEB FTP Successfully"
fi

# Install phpmyadmin if you choose
if [[ $rInstall_PMA =~ [yY](es)* ]]; then
  echo -e "${SET} Implemented phpMyAdmin"
  mkdir -p "$vDefault_Root/public_html/tmp"
  cd "$vDefault_Root/public_html/tmp/"
  wget --no-check-certificate -O "$vDefault_Root/public_html/tmp/phpmyadmin.tar.gz" https://files.phpmyadmin.net/phpMyAdmin/"$cVPMA"/phpMyAdmin-"$cVPMA"-all-languages.tar.gz
  tar -xzf phpmyadmin.tar.gz
  rm -rf "$vDefault_Root/public_html/phpmyadmin"
  mkdir -p "$vDefault_Root/public_html/phpmyadmin/tmp/twig"
  mv phpMyAdmin-"$cVPMA"-all-languages/* "$vDefault_Root/public_html/phpmyadmin/"
  rm -rf phpMyAdmin-"$cVPMA"-all-languages
  rm -rf phpmyadmin.tar.gz
  wget -O "$vDefault_Root/public_html/phpmyadmin/"config.inc.php $cRaw_Gith/config/pma/pma.inc.conf
  sed -i "s/##BLOWFISH##/$(GF_Pass_Random)/g;s/localhost/$cHost_DB/g;" "$vDefault_Root/public_html/phpmyadmin/"config.inc.php
  if [ $cVPMA == "5.1.1" ]; then
   wget --no-check-certificate -O "$cOls_Root/www/$vHost_Name/public_html/phpmyadmin/themes/themes.zip" https://files.phpmyadmin.net/themes/darkwolf/5.1/darkwolf-5.1.zip
   cd "$vDefault_Root/public_html/phpmyadmin/themes/"
   unzip -qq themes.zip
   rm -rf themes.zip
   sed -i "s/pmahomme/darkwolf/g;" "$vDefault_Root/public_html/phpmyadmin/"config.inc.php
  fi
  rm -rf "$vDefault_Root/public_html/tmp"
  cd /
  info_ins_pma=" ${CHECK} Implemented phpMyAdmin Successfully"
fi

echo
echo
firewall-cmd --reload
echo
if [ $vStatus_OLS -eq "1" ]; then
  echo -e "${CL_GREEN} ::: ================================================================================ :::${NC}"
  echo -e " ${TICK}${BG_GREEEN} Detail Installation OpenLiteSpeed : ${NC}"
  echo -e "      $info_ins_ols"
  echo -e "      ${DONE} OpenLiteSpeed Version installed: $cVers_OLS"
  echo -e "      ${DONE} OpenLiteSpeed Username         : $cUser_OLS"
  echo -e "      ${DONE} OpenLiteSpeed Password         : $cPass_OLS"
  echo -e "      ${DONE} Admin dashboard with Public IP : https://${vPublic_IP}:7080/"
  echo -e "      ${DONE} Admin dashboard with Local IP  : https://${vLocal_IP}:7080/"
  echo -e "      ${DONE} OpenLiteSpeed Default Page     : https://${vLocal_IP}:821/"
  echo
fi
if [ $vStatus_DB -eq "1" ]; then
  echo -e "${CL_GREEN} ::: ================================================================================ :::${NC}"
  echo -e " ${TICK}${BG_GREEEN} Detail Installation OpenLiteSpeed : ${NC}"
  echo -e "      $info_ins_db"
  echo -e "      ${DONE} MariaDB Version installed      : $cVer_MariaDB"
  echo -e "      ${DONE} MariaDB Username               : $cUser_DB"
  echo -e "      ${DONE} MariaDB Password               : $cPass_DB"
  echo -e "      ${DONE} MariaDB Host                   : $cHost_DB or $vHost_Name"
  echo -e "      ${DONE} MariaDB Port                   : $cPort_DB"
  echo
fi
if [ $vStatus_FTP -eq "1" ]; then
  echo -e "${CL_GREEN} ::: ================================================================================ :::${NC}"
  echo -e " ${TICK}${BG_GREEEN} Detail Installation OpenLiteSpeed : ${NC}"
  echo -e "      $info_ins_ftp"
  echo -e "      ${DONE} ProFtpd Host                   : $vLocal_IP or $vHost_Name"
  echo -e "      ${DONE} ProFtpd Port                   : 21"
  echo
fi
if [[ $rInstall_PMA =~ [yY](es)* ]]; then
  echo -e "${CL_GREEN} ::: ================================================================================ :::${NC}"
  echo -e " ${TICK}${BG_GREEEN} Detail Installation OpenLiteSpeed : ${NC}"
  echo -e "      $info_ins_pma"
  echo -e "      ${DONE} phpMyAdmin Version             : $cVPMA"
  echo -e "      ${DONE} phpMyAdmin Host Connection     : $cHost_DB"
  echo -e "      ${DONE} phpMyAdmin Port Connection     : $cPort_DB"
  echo -e "      ${DONE} phpMyAdmin Web Manager         : https://${vLocal_IP}:821/phpmyadmin/"
  echo
fi
if [[ $rInstall_WebFTP =~ [yY](es)* ]]; then
  echo -e "${CL_GREEN} ::: ================================================================================ :::${NC}"
  echo -e " ${TICK}${BG_GREEEN} Detail Installation OpenLiteSpeed : ${NC}"
  echo -e "      $info_ins_webftp"
  echo -e "      ${DONE} WEB FTP Version                : 1.3"
  echo -e "      ${DONE} WEB FTP Manager                : https://${vLocal_IP}:821/filemanager/"
  echo
fi
echo
echo -e "${TICK} Details of the installation information above can be seen at ( /root/scripts/detail-installation.txt )"
echo

# Save installation details to file
cat << EOT > /root/scripts/detail-installation.txt
================================================================================
Detail Installation OpenLiteSpeed :
$info_ins_ols
OpenLiteSpeed Version installed: $cVers_OLS
OpenLiteSpeed Username         : $cUser_OLS
OpenLiteSpeed Password         : $cPass_OLS
Admin dashboard with Public IP : https://${vPublic_IP}:7080/
Admin dashboard with Local IP  : https://${vLocal_IP}:7080/
OpenLiteSpeed Default Page     : https://${vLocal_IP}:821/
================================================================================
Detail Installation MariaDB :
$info_ins_db
MariaDB Version installed      : $cVer_MariaDB
MariaDB Username               : $cUser_DB
MariaDB Password               : $cPass_DB
MariaDB Host                   : $cHost_DB or $vHost_Name
MariaDB Port                   : $cPort_DB
================================================================================
Detail Installation ProFTPD :
$info_ins_ftp
ProFtpd Host                   : $vLocal_IP or $vHost_Name
ProFtpd Port                   : 21
================================================================================
Detail Installation phpmyadmin :
$info_ins_pma
phpMyAdmin Version             : $cVPMA
phpMyAdmin Host Connection     : $cHost_DB
phpMyAdmin Port Connection     : $cPort_DB
phpMyAdmin Web Manager         : https://${vLocal_IP}:821/phpmyadmin

================================================================================
Detail Installation WEB FTP :
$info_ins_webftp
WEB FTP Version                : 1.3
WEB FTP Manager                : https://${vLocal_IP}:821/filemanager
EOT


} 2>&1 | tee /root/scripts/logs/$(date +%d-%m-%Y)-$(date +%H-%M-%S)-openlitespeed-auto-install-almalinux-8.log