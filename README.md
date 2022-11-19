# rpi-pxeboot-scripts
Scripts I use to build RPi PXE diskless setup

I have a handful of RPis scattered around my house and I wanted to avoid
having to deal with pulling SD cards and updating them one at a time.

So I put together a handful of scripts to help PXE Boot them from one
place, so that I could upgrade a test RPi and then if that seemed good I
could update the rest by cloning that image over.

These goals are accomplished by leveraging:

- PXE
- ZFS (with clones)
- NFS
