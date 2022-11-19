#/bin/sh -e

. common.shin

RPI="garagepi"

zfs_clone

## Customizations
echo "Installing pkgs.."
pkg -r ${DESTDIR} -R ${DESTDIR}/etc/pkg -o ABI_FILE=${DESTDIR}/usr/lib/crt1.o install -y \
	net/py-paho-mqtt

# Remount
zfs_remount

echo "Done, reboot GaragePi RPi"
