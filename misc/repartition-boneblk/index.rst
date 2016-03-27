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

.. code-block:: 

        U-Boot 2014.04-00015-gb4422bd (Apr 22 2014 - 13:24:29)

        I2C:   ready
        DRAM:  512 MiB
        NAND:  0 MiB
        MMC:   OMAP SD/MMC: 0, OMAP SD/MMC: 1

I examine its on-board MMC1 (4GB) for the partition information and find two factory created partitions,

.. code-block::

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

.. code-block::

        root@beaglebone:~# uname -ra
        Linux beaglebone 3.8.13-bone47 #1 SMP Fri Apr 11 01:36:09 UTC 2014 armv7l GNU/Linux

This gives me more excuse to totally upgrade it.
Once my cross toolchain and basic rootfs built is completed, I am ready to repartition MMC1. First I boot from
SD card. My SD card has the necessary tools, fdisk, mkfs installed so I am ready to repartition.

'fdisk /dev/mmcblk1' and then 'p' command to print partition. This is what is on my board,


.. code-block::

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

.. code-block::

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

.. code-block::

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

.. code-block::

        Disk /dev/mmcblk0: 3867 MB, 3867148288 bytes
        255 heads, 63 sectors/track, 470 cylinders
        Units = cylinders of 16065 * 512 = 8225280 bytes

        Device Boot      Start         End      Blocks  Id System
        /dev/mmcblk0p1   *           1          13      104391   e Win95 FAT16 (LBA)
        /dev/mmcblk0p2              14         196     1469947+ 83 Linux
        /dev/mmcblk0p3             197         470     2200905  83 Linux

I will have two sets of rootfs partition, p2 and p3 of roughly equal size with the variety of zImage will be in p1 partition (FAT). The next
step is to populate the rootfs and the FAT partition. For root partition, I could do it live after mounting /dev/mmcblk0p2 to /mnt, for example,

.. code-block::

        wget ftp://myhost/rootfs.tar.gz -O - | tar xz -C /mnt

There is nothing magical about it. Of course, the filesystem must first be created on all partitions ie..mkfs them first.
Once this is done, FAT partition can be mounted and copy the u-boot and the zImage and the boot script.
Before my OS boot, I stop at u-boot prompt to confirm my new partitions as I would expect them to be,

.. code-block::

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

Pay attention to 'data' field. If your data file is not in the current directory wkere the kernel.its file resides you need to adjust their paths
accordingly. This is suppposedly the simplest form of 'its' file I need to create FDT image. Next I do,

.. code-block::
        
        $mkimage -f kernel.its zImage.itb


The output zImage.itb (I can name it anything) is my FIT file ready to be loaded. I need to do one more thing to complete this process.

Create boot.scr
----------------

I notice that every time I boot, I see this message on the console port,

.. code-block::

        SD/MMC found on device 1
        reading boot.scr
        ** Unable to read file boot.scr **
        reading uEnv.txt

This is because there was no boot.scr so u-boot falls back to reading uEnv.txt instead. 'boot.scr' is not text file, but an image file. This is the
source file for my boot.scr. Basically I can convert uEnv.txt to boot.scr, but I want a much simpler one. This is my 'boot.scr.src',

.. code-block::

        set loadaddr 82000000 
        set bootargs 'console=ttyS0,115200n8 rootfstype=ext4 root=/dev/mmcblk0p2 earlyprintk'
        fatload mmc 1:1 $loadaddr zImage.itb
        bootm $loadaddr

This is it for now. It is the minimalist approach. Next I create 'boot.scr',

.. code-block::

        $mkimage  -C none -A arm -T script -a 80000000 -e 80000000 -d boot.scr.src boot.scr

This is my default boot.scr that is copied to the boot partition (FAT) of the flash MMC1 where u-boot will read from at boot time.
Here is what happens after all these things,

.. code-block::

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

Todo
+++++

I should update my boot.scr to be a little bit more accommodating to multiple root filesystems. 

Citations
----------

.. [1] https://buildroot.org
.. [2] uImage.FIT directory of u-boot/doc
.. [3] BBB_SRM.pdf, user reference manual of beagle bone black.
