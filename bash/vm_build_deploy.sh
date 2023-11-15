#!/bin/bash
# VM Deployment Script
# Intended to build a CentOS 7.9 VM. Build and install functions are separated to allow
# a user to deploy a 7.9 VM on a hypervisor incapable of satisfying the pre-reqs required
# for building.

# Finished VM will have a bonded interface for public facing network and an internal-facing interface (eth0)
# User will need to provide a source containing an index for 7.9 base images since libguestfs does not provide them.
# Otherwise, change the virt-builder image designation to something in https://builder.libguestfs.org/index.asc

# Written by Matthew Amalino

#Store initial variables
mode=$1

#Check if we're running as root, and exit if not.
if [ "$EUID" -ne 0 ] 
then 
  echo "#####################################"
  echo "Please run as root"
  echo "#####################################"
  exit
fi

#Catch if mode unexpected
if ! [[ "$mode" =~ ^(build|install)$ ]]
then
    echo $'\n'
    echo "#####################################"
    echo "Instructions for use:"
    echo "Build VM image only: ./vm_build_deploy.sh build"
    echo "Install VM:          ./vm_build_deploy.sh install"
    echo "#####################################"
    echo $'\n'
    exit
fi

if [ "$mode" == "build" ]
then
    #Check if we're running from a suitable build server. Required CentOS 7.6 or greater.
    echo "Checking pre-reqs..."
    centos_release=$(awk '{print $4}' /etc/centos-release | awk -F'.' '{print $2}')
    prereq_libguestfs=$(rpm -q libguestfs)
    prereq_supermin5=$(rpm -q supermin5)
    prereq_libguestfs_tools=$(rpm -q libguestfs-tools)
    prereq_libguestfs_xfs=$(rpm -q libguestfs-xfs)
    prereq_qemu_img_cv=$(rpm -q qemu-img-cv)
    if [[ ${centos_release} -le 5 ]]
    then
        echo -e "CentOS is not 7.6 or greater. Choose a different build server. \nExiting."
        exit
    elif [[ -z $prereq_libguestfs ]] || [[ -z $prereq_supermin5 ]] || [[ -z $prereq_libguestfs_tools ]] || [[ -z $prereq_libguestfs_xfs ]] || [[ -z $prereq_qemu_img_cv ]]
    then
        echo -e "Missing one or more pre-requisite packages. \
        \n Confirm the following are installed: \
        \n - libguestfs \
        \n - libguestfs-tools \
        \n - libguestfs-xfs \
        \n - supermin5 \
        \n - qemu-img-cv"
        exit
    fi

    # Hostname and network prompts
    echo "Enter hostname"
    read -r hostname
    echo "Enter domain"
    read -r domain
    echo "Enter bond0 public IPv4 IP"
    read -r bond0_interface_v4_ip
    echo "Enter bond0 public IPv4 gateway"
    read -r bond0_interface_v4_gateway
    echo "Enter bond0 public IPv4 netmask"
    read -r bond0_interface_v4_netmask
    echo "Enter bond0 public IPv6 IP"
    read -r bond0_interface_v6_ip
    echo "Enter bond0 public IPv6 gateway"
    read -r bond0_interface_v6_gateway
    echo "Enter eth0 interface IP"
    read -r eth0_interface_ip
    echo "Enter eth0 interface netmask"
    read -r eth0_interface_netmask

    mkdir -p vm-files
    mkdir -p vm-images
    vm_files_dir_path="./vm-files"
    image_storage_path="./vm-images"

    # Generate mac addresses
    vf_mac=$(echo "$hostname"$RANDOM|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
    eth0_mac=$(echo "$hostname"$RANDOM|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')

    # Build the first-boot.sh to run after the first boot
    cat <<EOF >"${vm_files_dir_path}/first-boot.sh"
    #!/bin/bash
    set -xe

    echo "$bond0_interface_v4_ip $hostname" >> /etc/hosts

    for nic in /sys/class/net/e*; do ip link set "\$(basename \${nic})" down || true ; done
    rm -f /etc/sysconfig/network-scripts/ifcfg-en[ps]* || true
    systemctl enable network
    systemctl restart network
    sleep 30
    ip link set eth0 up || true
    ip link set eth1 up || true
    ip link set eth2 up || true

    yum clean all 

    /usr/sbin/ntpdate -u 0.us.pool.ntp.org || true
    /sbin/hwclock -w

    growpart /dev/vda 4
    resize2fs /dev/vda4

    touch /root/first-boot-done

    shutdown -P now
EOF

cat <<EOF >"${vm_files_dir_path}/resolv.conf"
search $domain
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:1
EOF

    cat <<EOF >"${vm_files_dir_path}/ifcfg-eth0"
DEVICE=eth0
HWADDR=$eth0_mac
TYPE=Ethernet
ONBOOT=yes
IPADDR=$eth0_interface_ip
NETMASK=$eth0_interface_netmask
EOF

    cat <<EOF >"${vm_files_dir_path}/ifcfg-eth1"
DEVICE=eth1
HWADDR=$vf_mac
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond0
AFFINITY_USE_KERNEL_ISOLATED_PROCESSORS=true
AFFINITY_USE_KERNEL_UNISOLATED_PROCESSORS=false
EOF

    cat <<EOF >"${vm_files_dir_path}/ifcfg-eth2"
DEVICE=eth2
HWADDR=$vf_mac
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond0
AFFINITY_USE_KERNEL_ISOLATED_PROCESSORS=true
AFFINITY_USE_KERNEL_UNISOLATED_PROCESSORS=false
EOF

    cat <<EOF >"${vm_files_dir_path}/ifcfg-bond0"
DEVICE=bond0
TYPE=Bond
ONBOOT=yes
BOOTPROTO=none
IPADDR=$bond0_interface_v4_ip
NETMASK=$bond0_interface_v4_netmask
GATEWAY=$bond0_interface_v4_gateway
BONDING_MASTER=yes
BONDING_OPTS="mode=2 xmit_hash_policy=1"
IPV6INIT=yes
IPV6ADDR=$bond0_interface_v6_ip/64
IPV6_DEFAULTGW=$bond0_interface_v6_gateway
EOF

    cat <<EOF >"${vm_files_dir_path}/network"
HOSTNAME=$hostname
NETWORKING_IPV6=yes
IPV6_AUTOCONF=no
NOZEROCONF=yes
EOF

    cat <<EOF >"${vm_files_dir_path}/grub"
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL="serial console"
GRUB_SERIAL_COMMAND="serial --speed=115200"
GRUB_CMDLINE_LINUX="panic=20 crashkernel=512M consoleblank=0 selinux=0 biosdevname=0 net.ifnames=0 console=ttyS0,115200n8 rd_NO_PLYMOUTH LANG=en_US.UTF-8"
GRUB_DISABLE_RECOVERY="true"
EOF

    #Delete the virt-builder cache before we start
    virt-builder --delete-cache

    virt-builder \
    centos-79 \
    -o "${image_storage_path}/${hostname}.qcow2" \
    --format qcow2 \
    --no-check-signature \
    --source {INPUT SOURCE HERE} \
    --hostname "$hostname" \
    --firstboot ./vm-files/first-boot.sh \
    --root-password 'password:{ROOT PASSWORD HERE}' \
    --timezone GMT \
    --upload "./vm-files/network:/etc/sysconfig" \
    --upload "./vm-files/resolv.conf:/etc" \
    --upload "./vm-files/ifcfg-eth1:/etc/sysconfig/network-scripts" \
    --upload "./vm-files/ifcfg-eth2:/etc/sysconfig/network-scripts" \
    --upload "./vm-files/ifcfg-bond0:/etc/sysconfig/network-scripts" \
    --upload "./vm-files/ifcfg-eth0:/etc/sysconfig/network-scripts" \
    --upload "./vm-files/grub:/etc/default" \
    --run-command "grub2-mkconfig -o /boot/grub2/grub.cfg"

    #Installing additional packages into image.
    virt-customize --install cloud-utils-growpart,gdisk, -a "${image_storage_path}/${hostname}.qcow2"

    echo $'\n'
    echo "##############################"
    echo "Image creation complete. Image can be found at ${image_storage_path}/${hostname}.qcow2."
    echo "SCP to your desired vmhost server and re-run this script with the 'install' option."
    echo "Provide the following MAC addresses to the install script when prompted:"
    echo "eth0 MAC address: $eth0_mac"
    echo "VF MAC address: $vf_mac"
    echo "##############################"
fi

if [ "$mode" == "install" ]
then
    echo "Enter hostname"
    read -r hostname
    echo "Enter bonded interface name #1 -- eg: eth1, eth2, etc"
    read -r team_member1
    echo "Enter bonded interface name #2 -- eg: eth2, eth3, etc"
    read -r team_member2
    echo "Enter eth0 MAC address provided during the build phase"
    read -r eth0_mac
    echo "Enter the VF MAC address provided during the build phase"
    read -r vf_mac
    echo "Enter path to VM disk image -- eg: /vm_images1/{hostname}.qcow2"
    read -r disk_image_path

    mkdir -p vm-files
    vm_files_dir_path="./vm-files"

    #Check for SRIOV_NUMVFS.
    iommu_setting=$(grep "iommu" /etc/default/grub)
    if [[ -z "$iommu_setting" ]]
        then
            #Check grub settings for sriov
            #echo "iommu=pt intel_iommu=on pci=realloc" >> /etc/default/grub
            #grub2-mkconfig -o /boot/grub2/grub.cfg
            echo -e "Grub is not configured for SRIOV interfaces. \
            \nIf desired, add "iommu=pt intel_iommu=on pci=realloc" to /etc/default/grub, then reboot. \
            \nSetup vfs interfaces in /sys/class/net/[interface]/device/sriov_numvfs after rebooting to get the vfs interfaces created, then re-run this script."
            exit
    fi
    
    sriov_numvfs_[$team_member1]=$(cat "/sys/class/net/${team_member1}/device/sriov_numvfs")
    sriov_numvfs_[$team_member2]=$(cat "/sys/class/net/${team_member2}/device/sriov_numvfs")
    if [[ "${sriov_numvfs_[$team_member1]}" == 0 ]]
        then
            #Check for sriov_numvfs
            #echo 4 > "/sys/class/net/${team_member1}/device/sriov_numvfs"
            echo "SRIOV_numvfs is not configured for ${team_member1}"
            exit
    fi

    if [[ "${sriov_numvfs_[$team_member2]}" == 0 ]]
        then
            #Check for sriov_numvfs
            #echo 4 > "/sys/class/net/${team_member2}/device/sriov_numvfs"
            echo "SRIOV_numvfs is not configured for ${team_member2}"
            exit
    fi

    #Create SRIOV VF interfaces if not existing
    virsh_netlist=$(virsh net-list --name --all| grep -v default)
    if [[ "$virsh_netlist" != *"$team_member1"* || "$virsh_netlist" != *"$team_member2"* ]]
        then
            #VFS interfaces do not exist
            cat <<EOF >"${vm_files_dir_path}/${team_member1}_vfs.xml"
            <network>
              <name>${team_member1}_vfs</name>
              <forward mode='hostdev' managed='yes'>
                <pf dev=${team_member1}/>
              </forward>
            </network>
EOF
            cat <<EOF >"${vm_files_dir_path}/${team_member2}_vfs.xml"
            <network>
              <name>${team_member2}_vfs</name>
              <forward mode='hostdev' managed='yes'>
                <pf dev=${team_member2}/>
              </forward>
            </network>
EOF
            virsh net-define "${vm_files_dir_path}/${team_member1}_vfs.xml"
            virsh net-define "${vm_files_dir_path}/${team_member2}_vfs.xml"
    fi
    team_member1_vf=$(virsh net-list --name --all| grep "$team_member1")# By Matthew Amalino
    team_member2_vf=$(virsh net-list --name --all| grep "$team_member2")

    #Resize VM disk and convert to raw format. Thick provisioning.
    image_storage_path=$(dirname "$disk_image_path")
    qemu-img resize "$disk_image_path" 512G
    qemu-img convert "$disk_image_path" "${image_storage_path}/${hostname}.raw"
    rm -f "$disk_image_path"

    virt-install \
    --import \
    --name "$hostname" \
    --memory 32768 \
    --vcpus 8 \
    --os-variant=centos7.0 \
    --disk path="${image_storage_path}/${hostname}.raw" \
    --nographics \
    --noautoconsole \
    --autostart \
    --noreboot

    virsh detach-interface "$hostname" --type bridge --config
    virsh attach-interface "$hostname" --type bridge --source mgmt --mac "$eth0_mac" --model virtio --config --persistent
    virsh attach-interface "$hostname" --type network --source "$team_member1_vf" --target eth1 --mac "$vf_mac" --config --persistent
    virsh attach-interface "$hostname" --type network --source "$team_member2_vf" --target eth2 --mac "$vf_mac" --config --persistent

fi
