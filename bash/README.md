# bash scripts

- LogTimeCompare.sh -- Bash script that compares the last line in a log file with the current time. Uses logic to determine if the time difference is greater than a configurable time, and outputs a 0 or 1 to allow for alerting. Could be a telegraf or Zabbix alert script.

- RaspberryPiIntegration.sh -- Bash script to simplify the integration process for a Raspberry Pi 3. Allows a user to easily provision a fresh image.

- vm_build_deploy.sh -- Intended to build a CentOS 7.9 VM. Build and install functions are separated to allow a user to deploy a 7.9 VM on a hypervisor incapable of satisfying the pre-reqs required for building.
