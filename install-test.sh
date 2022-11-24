#/bin/sh -e

RPI=test
. common.shin

echo
zfs_create

echo 'Installing..'
eval make -s -C /usr/src TARGET=arm TARGET_ARCH=armv7 ${OPTIONS} DESTDIR="${DESTDIR}" installworld installkernel
eval make -s -C /usr/src TARGET=arm TARGET_ARCH=armv7 ${OPTIONS} DESTDIR="${DESTDIR}" distribution
eval make -s -C /usr/src TARGET=arm TARGET_ARCH=armv7 ${OPTIONS} DESTDIR="${DESTDIR}" BATCH_DELETE_OLD_FILES=y delete-old delete-old-libs
echo

# Configure console
echo 'console="comconsole"' >> "${DESTDIR}/boot/loader.conf"

# Add user
echo 'Adding users..'
pw -R "${DESTDIR}" useradd brd
mkdir -p "${DESTDIR}/home/brd/.ssh"
cp ~brd/.ssh/authorized_keys "${DESTDIR}/home/brd/.ssh/"
chown -R brd "${DESTDIR}/home/brd"
chmod -R 700 "${DESTDIR}/home/brd/.ssh"
chmod 600 "${DESTDIR}/home/brd/.ssh/authorized_keys"
pw -R "${DESTDIR}" groupmod wheel -m brd
cp /home/brd/.vimrc "${DESTDIR}/home/brd"
cp /home/brd/.zshrc "${DESTDIR}/home/brd"
echo

# Install pkgs
echo "Configuring pkg.."
mkdir -p "${DESTDIR}/usr/local/etc/pkg/repos"
echo 'od1000: {' > "${DESTDIR}/usr/local/etc/pkg/repos/od1000.conf"
echo '  url: "http://od1000/packages/131-default",' >> "${DESTDIR}/usr/local/etc/pkg/repos/od1000.conf"
echo '}' >> "${DESTDIR}/usr/local/etc/pkg/repos/od1000.conf"
echo "Installing pkgs.."
pkg -r "${DESTDIR}" -R "${DESTDIR}/usr/local/etc/pkg/repos" -o ABI_FILE="${DESTDIR}/usr/lib/crt1.o" install -y python lldpd vim tmux net/py-paho-mqtt icinga2 zsh
echo

# Make syslogd wait until lockd starts
echo 'Configuring rc.conf..'
sysrc -f "${DESTDIR}/etc/rc.conf" syslogd_enable="NO"
echo '/etc/rc.d/syslogd forcestart' >> "${DESTDIR}/etc/rc.local"

# Make devd wait until lockd starts
sysrc -f "${DESTDIR}/etc/rc.conf" devd_enable="NO"
echo '/etc/rc.d/devd forcestart' >> "${DESTDIR}/etc/rc.local"

# Make sshd wait until lockd starts
echo '/etc/rc.d/sshd forcestart' >> "${DESTDIR}/etc/rc.local"

# Enable NFS locking
sysrc -f "${DESTDIR}/etc/rc.conf" rpc_lockd_enable="YES"

# Disable background fsck
sysrc -f "${DESTDIR}/etc/rc.conf" background_fsck="NO"

# Enable LLDPd
echo '/usr/local/etc/rc.d/lldpd onestart' >> "${DESTDIR}/etc/rc.local"

# Enable NTP
sysrc -f "${DESTDIR}/etc/rc.conf" ntpd_enable="YES" ntpd_sync_on_start="YES"
sed -i'' -e 's/pool .*/#pool /' "${DESTDIR}/etc/ntp.conf"
echo 'server 192.168.1.31 iburst' > "${DESTDIR}/etc/ntp.conf"
echo

# Configure resolv.conf
echo 'Configuring resolv.conf..'
cp /etc/resolv.conf "${DESTDIR}/etc/"
echo

# Create a snapshot so it can be cloned out
echo 'Creating snapshot..'
zfs snapshot "${ZROOT}${DESTDIR}@clean"
echo

# Remount
echo 'Changing mountpoint..'
zfs set mountpoint=/usr/pxeroot/test "${ZROOT}${DESTDIR}"
nfs_restart
echo


echo 'Done, reboot test RPi'
echo ${DATE} > .latest_test_date
echo ${GITHASH} > .latest_test_githash
echo ${GITBRANCH} > .latest_test_gitbranch
