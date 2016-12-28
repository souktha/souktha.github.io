.. title: UBI block and read-only NAND FS
.. slug: squashfs-ubi
.. date: 2016-04-09 01:44:47 UTC
.. tags: misc
.. category: 
.. link: 
.. description: 
.. type: text

There are many NAND Flash file systems available in Linux distribution that are suitable for deployment
in various Linux embedded products. Every FS has their strengths and weeknesses and they are not 
perfect for every type of applications. The debate will be endless as to which is better than the others.

.. TEASER_END

Usually the low cost consumer device is developed with cost constraint in its BOM and when it comes
down to NAND storage it is usually the cheapest part available which is usually in the 64MB-128MB range.
It is hard nowaday to find 64MB NAND, but the 128MB part is still in their commercial life cycle. 
Picking the righ FS to use is also important. One of the FS I have encountered with is the SquashFS [1]_. 
SquashFS is a read-only compressed FS that is available among others FS in Linux. It is 
being used in various consumer electronic devices. Because of its high compression ratio, it can fit nicely into
the smaller capacity NAND storage device; however this FS has one notable weakness, it cannot handle bad block on
its own. To overcome this limitation, UBI block volume comes into play. Wrap the SquashFS on UBI block. Let
the UBI block manages the faults and just let it be FS that it is meant to be.

Why read-only FS ?
==================

Some people would say why bother with it, just mount the R/W FS as RO and be done with it ! Having RO rootfs
is not the same as having RW FS with RO option because it enable user to remount as RW and alter
its contents in some way. Even small thing that is altered, the device may or may not function
as originally designed. The root FS is no longer a RO.  It is RO only at the will of the user.
This is not what I want. I want to use RO file system that fit its original objective,

- To prevent the alteration of its original contents by the average user whether it is intentional or accidental.
 
I want the users to use what I give them. Root FS contains specific revision of S/W apps, kernel, FPGA bitstream etc.
that run on specific revision of h/w and it is the version that, together passed the acceptance tests which could be 
safety tests (imagine medical devices), EMI/EMC tests, certification tests of some government agencies etc.. 
If some user choose to hack it, he/she needs to make some effort on his/her own.

So what happens if it is RO file system, how can I save something in it ? Generally the R/W FS will
be given in some partition to be mounted for general storage such as configuration data or user's files.


NANDSIM
========

*nandsim* is an excellent simulated NAND device which I find it to be amazing good for my own application. It is 
also available as part of Linux kernel that I can just build along with the kernel then load it and use it. I will
use *nandsim* device driver to simulate the actual file system before I transfer my final FS creation into the
mountable root FS.

Kernel configuration and s/w utilities
---------------------------------------

For kernel, I need to make sure I build MTD driver with NAND support, so I configure my kernel with the needed options,
        
.. code-block::

        Device Drivers -> 
           Memory Technology Device (MTD) support ->
              NAND Device Support -> Support for NAND Flash Simulator

As part of MTD Support, I also configure the kernel to enabled UBI - Unsorted block images

.. code-block::

        Device Drivers ->
           Memory Technology Device (MTD) Support ->
              Enable UBI - Unsorted block images ->
                 Read-only block devices on top of UBI volumes

I am done as far as kernel configuration is concerned. Just build it and have it ready to use. In addition to having the
needed support in the Linux kernel, I also need some external applications/utilities.

- MTD utilities (run on my host PC)
- SquashFS utilities (run on my host PC)

For test bed, I can use either my PC or the OMAP BeagleBone Black (BBLK). I will use both for this exercise.
The configuration I made above is for the target device where I intend to put the SquashFS/UBI on it.

Creating SquashFS
------------------

Using *mksquashfs* from SquashFS utilities on my PC, I create a SquashFS [4]_ rootfs as a test rootfs with xz compression,

.. code-block::

       mksquashfs rootfs rootfs.squashfs -nopad -noappend -root-owned -b 256k -comp xz -processors 2

       Parallel mksquashfs: Using 2 processors
        Creating 4.0 filesystem on rootfs.squashfs, block size 262144.
        [==============================================================================================-] 1249/1249 100%
        Exportable Squashfs 4.0 filesystem, xz compressed, data block size 262144
                compressed data, compressed metadata, compressed fragments, compressed xattrs
                duplicates are removed
        Filesystem size 12103.20 Kbytes (11.82 Mbytes)
                26.72% of uncompressed filesystem size (45288.55 Kbytes)
        Inode table size 14744 bytes (14.40 Kbytes)
                23.13% of uncompressed inode table size (63749 bytes)
        Directory table size 17646 bytes (17.23 Kbytes)
                46.33% of uncompressed directory table size (38087 bytes)
        Number of duplicate files found 8
        Number of inodes 1901
        Number of files 1192
        Number of fragments 120
        Number of symbolic links  393
        Number of device nodes 0
        Number of fifo nodes 0
        Number of socket nodes 0
        Number of directories 316
        Number of ids (unique uids + gids) 1
        Number of uids 1
        root (0)
        Number of gids 1
        root (0) 

From the original 44MB or so, I have a compressed file of about 12MB, which is small enough for my NAND device.

I then follow the formula [2]_ of computing what amount of overhead in terms of reserved blocks that I need to allocate for 
the UBI block so that I will image it into a 32MB partition of the 128MB NAND. My ubinize configuration file, *ubinize.cfg*,
will have 28MB declared for *vol_size* base on my calculation, thus,

.. code-block::

        [squashfs]
         mode=ubi
         image=rootfs.squashfs
         vol_id=0
         vol_size=28MiB
         vol_type=dynamic
         vol_name=squashfs
         vol_flags=autoresize

is the actual content of my *ubinize.cfg* file. Then I proceed to create the UBI block on top of the *rootfs.squashfs* that 
I created in the previous step,

.. code-block::

        ubinize -o ubi-rootfs.squashfs -m 2048 -p 128KiB -s 512 -O 2048 ubinize.cfg

my output file from this command is *ubi-roots.squashfs* and ready to be used for testing. 

Next I am going to use *nandsim* on the host PC to test it. If this works, the real NAND will work too.
I will simulate the equivalent *Spansion* NAND, which is now a *Cypress SM34S01G1*, 128MB NAND [3]_. 
Its manufacturer's 4 bytes ID as read from *READ ID* command is *0x1,0xa1,0x0,0x15*. 

.. code-block::

        # modprobe nandsim first_id_byte=0x1 second_id_byte=0xa1 third_id_byte=0x0 fourth_id_byte=0x15 parts=24,256,296 badblocks=310,410

        [  793.127308] nand: device found, Manufacturer ID: 0x01, Chip ID: 0xa1
        [  793.134397] nand: AMD/Spansion NAND 128MiB 1,8V 8-bit
        [  793.139506] nand: 128 MiB, SLC, erase size: 128 KiB, page size: 2048, OOB size: 64
        [  793.147895] flash size: 128 MiB
        [  793.151069] page size: 2048 bytes
        [  793.155069] OOB area size: 64 bytes
        ....
          793.234215] Creating 4 MTD partitions on "NAND 128MiB 1,8V 8-bit":
        [  793.240475] 0x000000000000-0x000000300000 : "NAND simulator partition 0"
        [  793.250553] 0x000000300000-0x000002300000 : "NAND simulator partition 1"
        [  793.259978] 0x000002300000-0x000004800000 : "NAND simulator partition 2"
        [  793.270224] 0x000004800000-0x000008000000 : "NAND simulator partition 3"

It creates the specified three partitions of 24 blocks (x128KB), 256 blocks and 296 blocks. Partition 3 is
the remaining size. Here I have, 3MB, 32MB, 37MB, 56MB. I will use only partition 1,2 for this exercise.
Two bad blocks are also specified in the command above. These blocks fall into partition 2.

Testing
=========

First try the pure SquashFS on partition 1,2. For me to do that, first I need to erase these *simulated* NAND
before I flash them. Eventhough it is a simuted NAND resides in memory, it acts just like real NAND. Because 
of this I cannot use *dd* command to write, so

.. code-block::

        # flash_erase /dev/mtd1 0 0
        # flash_erase /dev/mtd2 0 0 

*flash_erase* is the MTD utility command for the job. Next I will flash the *rootfs.quashfs* with *nandwrite* which
is also a MTD NAND utility to *mtd1* and mount it.

.. code-block::

       # nandwrite -p -q /dev/mtd1 rootfs.squashfs
       # mount /dev/mtdblock1 /mnt
       # ls /mnt
       bin      etc      lib32    linuxrc  mnt      proc     run      sys      usr
       dev      lib      libexec  media    opt      root     sbin     tmp      var

*rootfs.squashfs* mount just fine on mtdblock1 since it has no bad block. Next I try it by imaging
the rootfs onto the *mtd2* having simulated bad blocks,

.. code-block::

        # nandwrite -p -q /dev/mtd2 rootfs.squashfs 
        # mount /dev/mtdblock2 /mnt
        [ 2018.939315] squashfs: SQUASHFS error: unable to read id index table
        mount: wrong fs type, bad option, bad superblock on /dev/mtdblock2,
               missing codepage or helper program, or other error

               In some cases useful info is found in syslog - try
               dmesg | tail or so.

As I can see, SquashFS cannot handle the fact that it is residing in the partition with bad blocks and 
that some of its file data is/are relocated elsewhere by *nandwrite*. It fails when it try to mount it.

Now, I will use the *ubi-rootfs.squashfs* that I created earlier, the rootfs with UBI block volume in it 
so I erase *mtd2* and put this rootfs on it.

.. code-block::

        # flash_erase /dev/mtd2 0 0 
        Erasing 128 Kibyte @ 3a0000 --  9 % complete flash_erase: Skipping bad block at 003c0000
        Erasing 128 Kibyte @ 1020000 -- 43 % complete flash_erase: Skipping bad block at 01040000
        Erasing 128 Kibyte @ 24e0000 -- 100 % complete

        # nandwrite -p -q /dev/mtd2 ubi-rootfs.squashfs 

In order to use this rootfs, I need to load ubi block device driver that I built as module earlier,

.. code-block::

        # modprobe ubi mtd=2,2048 block=0,0
        [ 2454.912083] ubi0: attaching mtd2
        [ 2454.928459] ubi0: scanning is finished
        ..
         2455.011158] ubi0: background thread "ubi_bgt0d" started, PID 184
        [ 2455.020281] block ubiblock0_0: created from ubi0:0(squashfs)

when load, UBI block device will come to existence that I will later mount. The last line above
indicates that the UBI driver detect the *vol_name=squashfs* as defined in my *ubinize.cfg* file, which is
a good sign.


.. code-block::

        # ls /dev/ubi
        ubi0         ubi0_0       ubi_ctrl     ubiblock0_0

I verify that *ubiblock0_0* is available. Now I mount it,

.. code-block::

        # mount -t squashfs -r /dev/ubiblock0_0 /mnt
        # ls /mnt
        bin      etc      lib32    linuxrc  mnt      proc     run      sys      usr
        dev      lib      libexec  media    opt      root     sbin     tmp      var

It is successful. This confirms that having UBI volume on top of SquashFS solves the bad block handling issue.

Using *nandsim* gives me the confident that my root file system will work on the real NAND of exact same
partitioning scheme. I only need to flash *ubi-rootfs.squashfs* into the real NAND on the target,
add boot argument to the device tree and compile it to device tree blob for the next boot. It is 
important to erase the entire partition of the NAND before I flash *ubi-rootfs.squashfs* into it, for
example, using u-boot's *nand write* command, I need to *nand erase 300000 2000000* that corresponds
to *mtd1*, not just erasing only portion that fits the size of the file.

I also need to make sure that UBI block is compiled as built-in into the target kernel so that the
*ubi-roofs.squashfs* that I flash to the NAND will be mounted successfully as root device at boot time.

The Linux kernel boot argument that I need to add to device tree is, for example,  *ubi.mtd=x,2048 root=/dev/ubilock0_0 rootfstype=squashfs rootwait* where *x* is the MTD number. I will
not worry whether that partition has any bad block in it or not knowing that 
my UBI wrapped rootfs will work provided that the number of bad blocks is not excessively large such that it 
leaves no room for UBI to relocate/manage those bad blocks.

.. code-block::
        
        chosen {
         bootargs-append=" rootfstype=squashfs ubi.mtd=1,2048 root=/dev/ubiblock0_0 rootwait ro ";
         };

         /* partition can be defined in dts some where also*/
         ..
         partition@0 {
           label = "kernel";
           reg = <0 0x300000>;
           read-only;
         };
         partition@1 {
           label = "rootfs";
           reg = < 0x3000000 0x2000000>;
           red-only;
         };
         ...

If it is too much to deal with dts file, the boot argument can also be passed to Linux by the bootloader, u-boot.


Conclusion
===========

*nandsim* is an excellent tool to create the test bed for NAND file system much like every
simulation tool out there. In most cases, if I can create rootfs and mount it successfully, I
usually achieve similar result with physical NAND device.


Citations
==========

.. [1] https://en.wikipedia.org/wiki/SquashFS 
.. [2] www.linux-mtd.infradead.org/doc/ubi.html
.. [3] 002-00330_1-bit_ECC_x8_and_x16_I_O_1.8V_VCC_SLC_NAND_FLash_for_Embedded.pdf, Cypress.
.. [4] www.tldp.org/HOWTO/html_single/SquashFS-HOWTO
