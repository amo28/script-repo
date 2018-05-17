# script-repo
Collection of scripts for different purposes. Each one has instructions and comments embedded.
Brief description of each below:

- CorruptImageScan.ps1 -- Powershell script to analyze JPEGs in a folder to determine if they are corrupt or valid. Uses ImageMagick 'identify' function, which returns a simple 0 or 1 errorlevel if the image can't be read.

- LogTimeCompare.sh -- Bash script that compares the last line in a log file with the current time. Uses logic to determine if the time difference is greater than a configurable time, and outputs a 0 or 1 to allow for alerting. Originally written for Zabbix usage.

- NAS_Samba_Access_Check.bat -- Batch script which uses putty/plink function. Designed to run as a scheduled task and check NAS shares for accessibility. It attempts to map a share as a local drive using two different user credentials. If one of them fails, it issues a restart to the Samba service on the NAS, then tries again. Written to workaround an ongoing issue with QNAP NAS's where permissions would lock out for an unknown reason.

- RaspberryPiIntegration.sh -- Bash script to simplify the integration process for a Raspberry Pi 3. Allows a user to easily change the hostname, set static IP or DHCP, update the date/time both manually and via HTPdate, rotate the display output for vertically mounted displays, and issue a reboot.

- XMLUpdate.ps1 -- Powershell script designed to update an individual value in an XML document, while preserving the rest of it. In my scenario, I needed to make a change a value from True to False on several hundred PCs, but the rest of the XML was customized to each PC so I couldn't just copy/paste.
