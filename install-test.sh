#/bin/sh -e

RPI="test"
. common.shin

echo
zfs_create

echo 'Installing..'
eval make -s -C /usr/src TARGET=arm TARGET_ARCH=armv7 ${OPTIONS} DESTDIR="${DESTDIR}" installworld installkernel
eval make -s -C /usr/src TARGET=arm TARGET_ARCH=armv7 ${OPTIONS} DESTDIR="${DESTDIR}" distribution
eval make -s -C /usr/src TARGET=arm TARGET_ARCH=armv7 ${OPTIONS} DESTDIR="${DESTDIR}" BATCH_DELETE_OLD_FILES=y delete-old delete-old-libs
echo ${DATE} > .latest_test_date
echo ${GITHASH} > .latest_test_githash
echo ${GITBRANCH} > .latest_test_gitbranch
echo

# Configure console
echo 'console="efi"' >> "${DESTDIR}/boot/loader.conf"

# Add user
echo 'Adding users..'
pw -R "${DESTDIR}" useradd brd
mkdir -p "${DESTDIR}/home/brd/.ssh"
cp ~brd/.ssh/authorized_keys "${DESTDIR}/home/brd/.ssh/"
chmod -R 700 "${DESTDIR}/home/brd/.ssh"
chmod 600 "${DESTDIR}/home/brd/.ssh/authorized_keys"
pw -R "${DESTDIR}" groupmod wheel -m brd
cp /home/brd/.vimrc "${DESTDIR}/home/brd"
cp /home/brd/.zshrc "${DESTDIR}/home/brd"
chown -R brd "${DESTDIR}/home/brd"
echo

# Install pkgs
echo "Configuring pkg.."
mkdir -p "${DESTDIR}/usr/local/etc/pkg/repos"
echo 'FreeBSD: {' > "${DESTDIR}/usr/local/etc/pkg/repos/FreeBSD.conf"
echo '  enabled: no,' >> "${DESTDIR}/usr/local/etc/pkg/repos/FreeBSD.conf"
echo '}' >> "${DESTDIR}/usr/local/etc/pkg/repos/FreeBSD.conf"
echo 'od1000: {' > "${DESTDIR}/usr/local/etc/pkg/repos/od1000.conf"
echo '  url: "http://od1000/packages/140-default",' >> "${DESTDIR}/usr/local/etc/pkg/repos/od1000.conf"
echo '}' >> "${DESTDIR}/usr/local/etc/pkg/repos/od1000.conf"
echo "Installing pkgs.."
# XXX this is broken
pkg -r "${DESTDIR}" -R "${DESTDIR}/usr/local/etc/pkg/repos" -o ABI_FILE="${DESTDIR}/usr/lib/crt1.o" install -y python lldpd vim tmux net/py-paho-mqtt icinga2 zsh
echo

# Make syslogd wait until lockd starts
echo 'Configuring rc.conf..'
sysrc -f "${DESTDIR}/etc/rc.conf" syslogd_enable="NO"
echo '/etc/rc.d/syslogd forcestart' >> "${DESTDIR}/etc/rc.local"

# Enable sshd
sysrc -f "${DESTDIR}/etc/rc.conf" sshd_enable="YES"

# Enable NFS locking
sysrc -f "${DESTDIR}/etc/rc.conf" rpc_lockd_enable="YES"
sysrc -f "${DESTDIR}/etc/rc.conf" rpc_statd_enable="YES"

# Disable background fsck
sysrc -f "${DESTDIR}/etc/rc.conf" background_fsck="NO"
touch "${DESTDIR}/etc/fstab"

# Enable LLDPd
sysrc -f "${DESTDIR}/etc/rc.conf" lldpd_enable="NO"

# Enable NTP
sysrc -f "${DESTDIR}/etc/rc.conf" ntpd_enable="YES" ntpd_sync_on_start="YES"
sed -i'' -e 's/pool .*/#pool /' "${DESTDIR}/etc/ntp.conf"
echo 'server 192.168.1.31 iburst' > "${DESTDIR}/etc/ntp.conf"
echo

# Disable periodic services
echo 'weekly_locate_enable="NO"' >> "${DESTDIR}/etc/perodic.conf"
echo 'security_status_neggrpperm_enable="NO"' >> "${DESTDIR}/etc/perodic.conf"
echo 'security_status_chksetuid_enable="NO"' >> "${DESTDIR}/etc/perodic.conf"
echo 'daily_output="/var/log/daily.log"' >> "${DESTDIR}/etc/perodic.conf"
echo 'weekly_output="/var/log/weekly.log"' >> "${DESTDIR}/etc/perodic.conf"
echo 'monthly_output="/var/log/monthly.log"' >> "${DESTDIR}/etc/perodic.conf"

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
zfs_remount
nfs_restart
echo


echo 'Done, reboot test RPi'
