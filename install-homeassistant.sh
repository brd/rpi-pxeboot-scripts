#/bin/sh -e

. common.shin

RPI="homeassistant"

zfs_clone

# Configure homeassistant bits
pw -R ${DESTDIR} useradd homeassistant -w no -m -c "Home Assistant"
pw -R ${DESTDIR} groupmod dialer -m homeassistant
HA_UID=$( pw -R ${DESTDIR} showuser homeassistant | awk -F ':' {print $3} )

# Extra packages
echo "Installing pkgs.."
pkg -r ${DESTDIR} -R ${DESTDIR}/etc/pkg -o ABI_FILE=${DESTDIR}/usr/lib/crt1.o install -y \
	devel/py-pip \
	#www/py-pyjwt2 \
	multimedia/py-av \
	devel/py-atomicwrites \
	textproc/py-python-slugify \
	www/py-requests \
	devel/py-yaml \
	security/py-certifi \
	devel/py-awesomeversion \
	#voluptuous_serialize \
	devel/py-ciso8601 \
	devel/py-backports.zoneinfo \
	devel/py-Jinja2 \
	net/py-ifaddr \
	security/py-bcrypt \
	www/py-aiohttp \
	astro/py-astral \
	#async-timeout \
	devel/py-attrs \
	www/py-httpx \
	devel/py-voluptuous \
	www/py-yarl \
	#py-frozenlist \
	www/py-multidict \
	textproc/py-charset-normalizer \
	#py-aiosignal \
	py38-pytz \
	devel/py-typing-extensions \
	www/py-rfc3986 \
	devel/py-sniffio \
	www/py-httpcore \
	textproc/py-markupsafe \
	converters/py-text-unidecode \
	dns/py-idna \
	net/py-urllib3 \
	#anyio3 \
	net/py-h11 \
	security/py-cryptography
echo

# Remount
zfs_remount

echo "Done, reboot homeassistant RPi"
