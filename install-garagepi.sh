#/bin/sh -e

. common.shin

RPI="garagepi"

zfs_clone

## Customizations
echo "Installing pkgs.."
# Already installed earlier
#pkg -r "${DESTDIR}" -R "${DESTDIR}/etc/pkg" -o ABI_FILE="${DESTDIR}/usr/lib/crt1.o" install -y \
#	net/py-paho-mqtt
git -C "${DESTDIR}/home/brd" clone https://github.com/brd/mqtt_garagedoor_temp.git

# Setup the relay as an output pin
echo '/usr/sbin/gpioctl -c 18 OUT' >> "${DESTDIR}/etc/rc.local"

# Setup tmux to start the python script
echo '@reboot tmux' >> "${DESTDIR}/var/cron/tabs/root"
echo 'set -g default-command zsh' >> "${DESTDIR}/root/.tmux.conf"
echo 'new-session -n pub "sleep 60; /home/brd/mqtt_garagedoor_temp/garagedoor_temp.py"' >> "${DESTDIR}/root/.tmux.conf"

# Remount
zfs_remount

echo "Done, reboot GaragePi RPi"
