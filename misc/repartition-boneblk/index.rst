.. title: Repartitioning 4GB Beaglebone Black eMMC flash
.. slug: repartition-boneblk
.. date: 2016-03-20 01:26:53 UTC
.. tags: misc
.. category: 
.. link: 
.. description: Document about repartitioning my beaglebone black
.. type: text

.. $LastChangeDate$
.. $Rev$
.. $Author$

I bought the Beaglebone Black Rev C nearly two years ago. When I received it, I powered it up and
saw that everything appeared to be functional, put it back in the box and never had the chance
to work with it again until now. It looks like it was preloaded with Debian (I am not sure). There
must have been a lot of updates ever since.

.. TEASER_END

This is what shows up on serial port console on boot up,

.. code-block:: console

        U-Boot 2014.04-00015-gb4422bd (Apr 22 2014 - 13:24:29)

        I2C:   ready
        DRAM:  512 MiB
        NAND:  0 MiB
        MMC:   OMAP SD/MMC: 0, OMAP SD/MMC: 1

I examine its on-board MMC1 (4GB) for the partition information and find two factory created partitions,

.. code-block:: console

        => mmc dev 1
        switch to partitions #0, OK
        mmc1(part 0) is current device
        => mmc part 

        Partition Map for MMC device 1  --   Partition Type: DOS

        Part	Start Sector	Num Sectors	UUID		Type
          1	2048      	196608    	00000000-01	0e Boot
          2	198656    	7354368   	00000000-02	83


It is obvious that I cannot repartition this MMC1 if I boot from the on-board eMMC flash because it becomes 
a root partition itself. Maybe I could by pivoting root, but I am not sure I want to mount and edit the script of ramdisk
image to do that. I might as well end up spending the same amount of time doing what I plan to do. My plan is to rebuild
from ground up so I need to boot from SD first. For that I need to prepare a bootable SD card, 
which according to the BBLK document, it is regarded to be MMC0 device with respect to u-boot.
I begin to search for the cross toolchains. While there are readily available from TI website as well as
some others, they tend to come in large package, toolchain and rootfs. I decide to build it on my own using
buildroot[1_]. I also notice that the preloaded kernel is also quite old,

.. code-block:: console

        root@beaglebone:~# uname -ra
        Linux beaglebone 3.8.13-bone47 #1 SMP Fri Apr 11 01:36:09 UTC 2014 armv7l GNU/Linux

This gives me more excuse to totally upgrade it.
Once my cross toolchain and basic rootfs built is completed, I am ready to repartition MMC1. First I boot from
SD card. My SD card has the necessary tools, fdisk, mkfs installed so I am ready to repartition.

'fdisk /dev/mmcblk1' and then 'p' command to print partition. This is what is on my board,


.. code-block:: console

        Disk /dev/mmcblk1: 3867 MB, 3867148288 bytes
        4 heads, 16 sectors/track, 118016 cylinders
        Units = cylinders of 64 * 512 = 32768 bytes

        Device Boot      Start         End      Blocks  Id System
        /dev/mmcblk1p1   *          33        3104       98304   e Win95 FAT16 (LBA)
        /dev/mmcblk1p2            3105      118016     3677184  83 Linux

Firt thing to do is to delete these two partitions and recreate three new partitions. One for FAT to please AM335X ROM boot, and
two rootfs partitions. One rootfs partition is for the rootfs I built on my own, the second one I plan to use TI rootfs to see
what they have. For u-boot, I built after I clone from the git repos, and for the kernel I used TI' source of Linux 4.1.3 git. These
two items are on my SD card that I boot while the rootfs is from buildroot. Put it simply, they are all new.

.. code-block:: console

        U-Boot 2016.03 (Mar 17 2016 - 07:36:31 -0700)

       Watchdog enabled
        I2C:   ready
        DRAM:  512 MiB
        MMC:   OMAP SD/MMC: 0, OMAP SD/MMC: 1
        ....
        Linux version 4.1.13-g8dc6617 (xxxx@xxxx) (gcc version 5.3.0 (Buildroot 2016.02) ) #2 PREEMPT Tue Mar 15 13:35:14 PDT 2016
        
        ...
        
        Welcome to Buildroot
        beaglebone login: root
        # 

Continue with fdisk, I delete both partition with 'd' command. After that I use 'x' command to get to expert mode. In this page of 
command menu, I change heads and sectors to 255 and 63 respectively. Commit the change, exit fdisk to reenter again so I can
verify what I did earlier is still good just to be sure.

.. code-block:: console

        Disk /dev/mmcblk1: 3867 MB, 3867148288 bytes
        255 heads, 63 sectors/track, 118016 cylinders
        Units = cylinders of 16065 * 512 = 8225280 bytes

        Device Boot      Start         End      Blocks  Id System

        Command (m for help): n
        Command action
           e   extended
           p   primary partition (1-4)

so far so good. The heads and sectors are what I set so I proceed to to the rest of the steps on creating new partitions. These 
are my new partitions after I recreated.

.. code-block:: console

        Disk /dev/mmcblk0: 3867 MB, 3867148288 bytes
        255 heads, 63 sectors/track, 470 cylinders
        Units = cylinders of 16065 * 512 = 8225280 bytes

        Device Boot      Start         End      Blocks  Id System
        /dev/mmcblk0p1   *           1          13      104391   e Win95 FAT16 (LBA)
        /dev/mmcblk0p2              14         196     1469947+ 83 Linux
        /dev/mmcblk0p3             197         470     2200905  83 Linux

I will have two sets of rootfs partition, p2 and p3 of roughly equal size with the variety of zImage will be in p1 partition (FAT). The next
step is to populate the rootfs and the FAT partition. For root partition, I could do it live after mounting /dev/mmcblk0p2 to /mnt, for example,

.. code-block:: console

        wget ftp://myhost/rootfs.tar.gz -O - | tar xz -C /mnt

There is nothing magical about it. Of course, the filesystem must first be created on all partitions ie..mkfs them first.
Once this is done, FAT partition can be mounted and copy the u-boot and the zImage and the boot script.
Before my OS boot, I stop at u-boot prompt to confirm my new partitions as I would expect them to be,

.. code-block:: console

        mmc dev 1
        switch to partitions #0, OK
        mmc1(part 0) is current device
        => mmc part 

        Partition Map for MMC device 1  --   Partition Type: DOS

        Part	Start Sector	Num Sectors	UUID		Type
          1	63        	208782    	00000000-01	0e Boot
          2	208845    	2939895   	00000000-02	83
          3	3148740   	4401810   	00000000-03	83


So far so good.

Create zImage with FDT
======================

I do not like the complicated uEnv.txt that came with the board and its elaborated boot script. I think it was made to provide the maximum
accommodation to the variants of Am335x based platforms. Since I know for sure that my board is BBLK, so I will keep it as simple as possible by
putting the FDT onto zImage. The how-to is well documented in u-bood/doc/uImage.FIT [2_]. This is the RTFM part of the process.

Creating kernel.its file
------------------------

Just use the sample 'kernel_fdt.its', edit and use it. Here is my 'kernel.its' file ,

.. code-block::

        /dts-v1/;

        / {
        	description = "ARM BBLK FIT (Flattened Image Tree)";
        	#address-cells = <1>;

        	images {
        		kernel@1 {
        			description = "ARM BeagleboneBlack Linux-4.1.13";
        			data = /incbin/("zImage");
        			type = "kernel";
        			arch = "arm";
        			os = "linux";
        			compression = "none";
        			load = <0x80008000>;
        			entry = <0x80008000>;   
        			hash@1 {
				algo = "crc32";
        			};
        			hash@2 {
        				algo = "sha1";
        			};
        		};
        
        		fdt@1 {
        			description = "ARM Boneblack device tree blob";
        			data = /incbin/("am335x-boneblack.dtb");
        			type = "flat_dt";
        			arch = "arm";
        			compression = "none";
			
        			hash@1 {
        				algo = "crc32";
        			};
        			hash@2 {
        				algo = "sha1";
        			};
        		};

        	};

	        configurations {
        		default = "config@1";

        		config@1 {
        			description = "BeagleboneBlack";
        			kernel = "kernel@1";
        			fdt = "fdt@1";
        		};

        	};
        };

Pay attention to 'data' field. If your data file is not in the current directory where the kernel.its file resides you need to adjust their paths
accordingly. This is suppposedly the simplest form of 'its' file I need to create FDT image. Next I do,

.. code-block:: console
        
        $mkimage -f kernel.its zImage.itb


The output zImage.itb (I can name it anything) is my FIT file ready to be loaded. I need to do one more thing to complete this process.

Create boot.scr
----------------

I notice that every time I boot, I see this message on the console port,

.. code-block:: console

        SD/MMC found on device 1
        reading boot.scr
        ** Unable to read file boot.scr **
        reading uEnv.txt

This is because there was no boot.scr so u-boot falls back to reading uEnv.txt instead. 'boot.scr' is not text file, but an image file. This is the
source file for my boot.scr. Basically I can convert uEnv.txt to boot.scr, but I want a much simpler one. This is my 'boot.scr.src',

.. code-block:: console

        set loadaddr 82000000 
        set bootargs 'console=ttyS0,115200n8 rootfstype=ext4 root=/dev/mmcblk0p2 earlyprintk'
        fatload mmc 1:1 $loadaddr zImage.itb
        bootm $loadaddr

This is it for now. It is the minimalist approach. Next I create 'boot.scr',

.. code-block:: console

        $mkimage  -C none -A arm -T script -a 80000000 -e 80000000 -d boot.scr.src boot.scr

This is my default boot.scr that is copied to the boot partition (FAT) of the flash MMC1 where u-boot will read from at boot time.
Here is what happens after all these things,

.. code-block:: console

        Scanning mmc 1:1...
        Found U-Boot script /boot.scr
        reading /boot.scr
        234 bytes read in 3 ms (76.2 KiB/s)
        ## Executing script at 80000000
        reading zImage.itb
        3360080 bytes read in 187 ms (17.1 MiB/s)
        ## Loading kernel from FIT Image at 82000000 ...
           Using 'config@1' configuration
           Trying 'kernel@1' kernel subimage
             Description:  ARM BeagleboneBlack Linux-4.1.13
             Created:      2016-03-20  22:33:34 UTC
             Type:         Kernel Image
             Compression:  uncompressed
             Data Start:   0x820000e8
             Data Size:    3325704 Bytes = 3.2 MiB
             Architecture: ARM
             OS:           Linux
             Load Address: 0x80008000
             Entry Point:  0x80008000
             Hash algo:    crc32
             Hash value:   62b34510
             Hash algo:    sha1
             Hash value:   04be40f903db0deb1cd632416e82f09828f05545
           Verifying Hash Integrity ... crc32+ sha1+ OK
        ## Loading fdt from FIT Image at 82000000 ...
           Using 'config@1' configuration
           Trying 'fdt@1' fdt subimage
             Description:  ARM Boneblack device tree blob
             Created:      2016-03-20  22:33:34 UTC
             Type:         Flat Device Tree
             Compression:  uncompressed
             Data Start:   0x8232c11c
             Data Size:    33030 Bytes = 32.3 KiB
             Architecture: ARM
             Hash algo:    crc32
             Hash value:   a101a6b3
             Hash algo:    sha1
             Hash value:   711dfa46a5cb4c8286035d1577fb6cc6eff22370
           Verifying Hash Integrity ... crc32+ sha1+ OK
           Booting using the fdt blob at 0x8232c11c
           Loading Kernel Image ... OK
           Loading Device Tree to 8fff4000, end 8ffff105 ... OK

        Starting kernel ...

        [    0.000000] Booting Linux on physical CPU 0x0
        [    0.000000] Initializing cgroup subsys cpuset 
        [    0.000000] Initializing cgroup subsys cpu

As I can see, u-boot detects the presence of boot.scr, follows the instruction given such as set the bootargs and 'fatload' the zImage.itb then
boot Linux kernel. The part dealing with creating partitions and booting the image is done.

So far the method shown above is pretty much done at high level, booting up, deleting and recreating the partitions.
Specifically, it is done at the OS level (Linux) while another alternative of creating/recreating eMMC partitions
for this platform existed where it can be done at U-Boot level. The Boneblack can boot straight off the raw eMMC 
partition at fixed LBA offset if it is properly configured. To do this, I need to make sure the following flags,
*CONFIG_SYS_MMSD_RAW_MODE_xxx_SECTOR* are set when building its SPL (MLO). The *MLO* and *u-boot.img* can then be
copied to the eMMC raw partition at the fixed LBA offsets *0x100* and *0x300* respectively.

Boot from eMMC raw partition
----------------------------

. Follow *doc/README.gpt* on creating the GPT partition on the eMMC. This is what I have after
creating four GPT partitions. Hint: Use host's tool *uuidgen* to generate the UUID needed.

.. code-block:: console

        Partition Map for MMC device 1  --   Partition Type: EFI

        Part	Start LBA	End LBA		Name
	        Attributes
        	Type GUID
        	Partition GUID
          1	0x00000022	0x00001021	"u-boot"
        	attrs:	0x0000000000000000
        	type:	ebd0a0a2-b9e5-4433-87c0-68b6b72699c7
        	guid:	1377cef2-31f4-2341-bf92-706fe6b86817
          2	0x00001022	0x00002021	"env"
        	attrs:	0x0000000000000000
        	type:	ebd0a0a2-b9e5-4433-87c0-68b6b72699c7
        	guid:	e54754d6-363e-8249-b30d-1f705412c6ba
          3	0x00002022	0x00007021	"kernel"
        	attrs:	0x0000000000000000
        	type:	ebd0a0a2-b9e5-4433-87c0-68b6b72699c7
        	guid:	0d74cff8-8691-654a-b56c-468983a435b4
          4	0x00007022	0x00733fde	"rootfs"
        	attrs:	0x0000000000000000
        	type:	ebd0a0a2-b9e5-4433-87c0-68b6b72699c7
        	guid:	3c6a05e6-e730-6e45-9fa5-a6e37b9283b6
        U-Boot# 

. Download MLO and u-boot.img and write to the eMMC raw partition. The fixed locations *0x100* and *0x300* fall
into the u-boot partition (0x22..0x1021). Line 12,24 are *mmc write* to the fixed LBA offsets of the eMMC for
0x90 and 0x269 blocks where each block is 512 bytes. 

.. code-block:: console
        :linenos:

        U-Boot# tftpboot $loadaddr MLO
        link up on port 0, speed 100, full duplex
        Using cpsw device
        TFTP from server 192.168....
        Filename 'MLO'.
        Load address: 0x82000000
        Loading: *##############
	 850.6 KiB/s
        done
        Bytes transferred = 72332 (11a8c hex)

        U-Boot# mmc write $loadaddr 0x100 90

        U-Boot# tftpboot $loadaddr u-boot.img
        link up on port 0, speed 100, full duplex
        Using cpsw device
        TFTP from server 192.168....
        Filename 'u-boot.img'.
        Load address: 0x82000000
        Loading: *#############################################################
	 1.3 MiB/s
        done
        Bytes transferred = 309548 (4b92c hex)
        U-Boot# mmc write $loadaddr 0x300 269 

. Download kernel image and write to the *kernel* partition. Having the named partition for it is not necessary
, but it is easier to keep track of it later.

.. code-block:: console

        tftpboot $loadaddr zImage.itb 
        link up on port 0, speed 100, full duplex
        Using cpsw device
        TFTP from server 192.168.10.14; our IP address is 192.168.10.20
        Filename 'zImage.itb'.
        Load address: 0x82000000
        Loading: *################################################################
	         #################################################################
                 ..

        U-Boot# mmc write $loadaddr 2022 1b00 

. Download root FS and write it to *rootfs* partition and set the u-boot's *bootargs* to specify the rootfs.

.. code-block:: console

        U-Boot# tftpboot $loadaddr rootfs.ext4
        link up on port 0, speed 100, full duplex
        Using cpsw device
        TFTP from server 192.168.10.14; our IP address is 192.168.10.20
        Filename 'rootfs.ext4'.
        Load address: 0x82000000
        Loading: *################################################################
        	 #################################################################
                 ..
	done
        Bytes transferred = 130077696 (7c0d400 hex)
        U-Boot# mmc write $loadaddr 7022 3e070

. Set/verify *bootcmd* to read kernel image from the correct LBA offset of the *kernel* partition as well as 
set/verify the *bootargs* to have the correct partition for the rootFS. The LBA offset for kernel partition
above is at *0x2022*.

.. code-block:: console

        U-Boot# pr bootcmd
        bootcmd=mmc dev 1 && mmc read $loadaddr 2022 8200 && bootm $loadaddr
        U-Boot# pr bootargs
        bootargs=console=ttyS0,115200n8 root=/dev/mmcblk0p4 rw rootwait

The system should be able to boot and mount the rootfs correctly. The setting of *bootcmd* above is to
read the kernel from LBA *0x2022* for 8200 blocks and boot from it. The *bootargs* is set to make sure
that the rootfs is pointed to the 4th partition of the eMMC.

Of all the four GPT partitions created, the only partition that has FS is the *rootfs* while all others
are raw partitions. This is almost similar to booting from NAND device.


Citations
----------

.. [1] https://buildroot.org
.. [2] uImage.FIT directory of u-boot/doc
.. [3] BBB_SRM.pdf, user reference manual of beagle bone black.
