# ansible

- kernel_upgrade_playbook -- intended to handle kernel upgrades on a hypervisor with running VMs. Handles VM shutdown/startup, reboots, upgrades, and slack notifications.

- vm_storage_role -- ansible role that can configure a VM storage pool using available disks. It will create a raid, create the filesystem and mountpoint, create the storage pool, and also assign pool shares to a target VM