#/bin/sh -e

RPI="homeassistant"
. common.shin

zfs_clone

# Configure homeassistant bits
echo "Adding homeassistant user.."
pw -R "${DESTDIR}" useradd homeassistant -w no -m -c "Home Assistant"
pw -R "${DESTDIR}" groupmod dialer -m homeassistant
HA_UID=$( pw -R "${DESTDIR}" showuser homeassistant | awk -F ':' '{print $3}' )

# Extra packages
echo "Installing pkgs.."
pkg -r "${DESTDIR}" -R "${DESTDIR}/usr/local/etc/pkg/repos" -o ABI_FILE="${DESTDIR}/usr/lib/crt1.o" install -y \
	multimedia/py-homeassistant \
	www/npm
echo

# Remount
echo "Remounting the ZFS dataset.."
zfs_remount
nfs_restart

echo "Done, reboot homeassistant RPi"
