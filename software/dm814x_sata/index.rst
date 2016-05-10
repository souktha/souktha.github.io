.. title: Adding SATA HD boot support to DM814x U-Boot
.. slug: dm814x_sata
.. date: 2016-05-09 20:13:36 UTC
.. tags: software
.. category: 
.. link: 
.. description: SATA support for DM814x U-Boot
.. type: text

TI DM814x/AM287x evaluation platform (TI8148 EVM) can boot from various connected devices depending on the setting
of the BTMode[4-0] pins as described in chapter 4.5.2.1 of its respective technical reference manual [1_]. Typically
the EVM boot its first stage of u-boot as the minimum boot loaders. TI calls it *min-nand* boot loader 
configuration. This minimum boot then bootstraps a secondary boot phase which is a
a full featured u-boot for this platform. 
The EV platform has SATA H/W support where I will bring up the SATA HDD in the second phase of booting so that I can load the
Linux kernel image from HDD instead of loading it from NAND device.

.. TEASER_END

Objective
============

While booting from NAND is working perfectly fine, having the option to boot from SATA HDD brings greater flexibility
to the platform. I can have many versions of uImage in the disk partition where I can selectively use for booting.
I may have five or ten versions of it. It won't matter because I have plenty of disk space to store it, load it and 
run it instead of limiting myself to the space available in NAND device.

SATA feature implementation
===========================

For this development, I use TI's latest SDK [3_] and its associated cross toolchain [2_]. The EZSDK u-boot
source code resides in *board-support/u-boot-2010.06-psp04.04.00.01* directory after the EZSDK installation. This 
would be the version that I modify to add SATA support.
The integrated SATA controller of DM814x is capable of supporting up to 3Gbps per HBA port operating in AHCI mode. I 
will make use of AHCI driver that is already in place with some modifcation needed to get it to work properly.

What is/are needed to get SATA interface working
------------------------------------------------

1) Program the PLL for the correct values. I modify *sata_pll_config()* of *board/ti/ti8148/evm.c* for the correct 
values that use to configure *SATA_PLLCFGx* as shown in TI document, section 21.3.1, base on the 100MHZ low-jitter clock. 

.. code-block::

	/*use 100MHZ low jitter clock feed*/
	__raw_writel(0x00000004, SATA_PLLCFG0);
	for(i=0; i < 4; i++)delay(0xFFFF);

	__raw_writel(0x812C003C, SATA_PLLCFG1);
	for(i=0; i < 10; i++)delay(0xFFFF);
        ....
        ....
        sata_phy_config();


2) Add small piece of code to program SATA PHY (SERDES) namely the RX and TX configuration registers.

.. code-block::

        static void sata_phy_config(void)
        {
	__raw_writel(TI814X_SATA_PHY_CFGRX0_VAL, SATA_PHY_CFGRX0);
	__raw_writel(TI814X_SATA_PHY_CFGRX1_VAL, SATA_PHY_CFGRX1);
	__raw_writel(TI814X_SATA_PHY_CFGRX2_VAL, SATA_PHY_CFGRX2);
	__raw_writel(TI814X_SATA_PHY_CFGRX3_VAL, SATA_PHY_CFGRX3);

	__raw_writel(TI814X_SATA_PHY_CFGTX0_VAL, SATA_PHY_CFGTX0);
	__raw_writel(TI814X_SATA_PHY_CFGTX1_VAL, SATA_PHY_CFGTX1);
	__raw_writel(TI814X_SATA_PHY_CFGTX2_VAL, SATA_PHY_CFGTX2);
	__raw_writel(TI814X_SATA_PHY_CFGTX3_VAL, SATA_PHY_CFGTX3);
        }


3) Modify *drivers/block/ahci.c* slighty. The AHCI driver code assumes that the controller is connected via
PCI bus which is not true for this EVM platform. Since the integrated SATA controller is memory mapped to the SoC
physical address space, the modification is needed. I define *CONFIG_SCSI_AHCI_PLAT* to disable blocks of code
that are PCI related, for example,

.. code-block::

        #ifndef CONFIG_SCSI_AHCI_PLAT
	pci_read_config_word(pdev, PCI_VENDOR_ID, &vendor);
        ...
        #endif

and replace those blocks where memory mapped access is applicable. I also raise command timeout a little
bit to ensure that it works for slower HDD.

4) Add *CONFIG_SCSI_AHCI_PLAT* for AHCI driver and enable SCSI (AHCI) support in u-boot configuration file,
*include/configs/ti8148_evm.h* for one SCSI HDD, one SCSI LUN.

.. code-block::

        # define CONFIG_CMD_SCSI        1
        ...

	#ifdef CONFIG_CMD_SCSI
		#define CONFIG_SCSI_AHCI
		#define CONFIG_SCSI_AHCI_PLAT
		#define CONFIG_SYS_SCSI_MAX_DEVICE 1
		#define CONFIG_SYS_SCSI_MAX_SCSI_ID 1
		#define CONFIG_SYS_SCSI_MAX_LUN	 1
	#endif

The complete code change is available in my git repository in the form of patch file where it could be
patched to the TI's u-boot release directly (https://github.com/souktha/dm814x-u-boot-psp04.04.01).
The patch file will patch four files for this implementation,
*drivers/block/ahci.c, common/cmd_scsi.c, include/configs/ti8148_evm.h, board/ti/ti8148/evm.c*.


Building and testing
=====================

The code change is for the secondary stage of u-boot so *ti8148_evm_config_nand* is the configuration to
be used when building this platform's u-boot.

Building
--------

.. code-block::

        $make ARCH=arm ti8148_evm_config_nand
        $make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- 

are the command lines for configuring and building u-boot. After building is complete, *u-boot.bin* can be used for
testing.

Testing
-------

The new u-boot can be tested before flashing to NAND partition. To do this, stop the boot during its
first stage boot (TI-MIN), then load the code to test it (one HDD connected).

.. code-block::

        ...
        The 2nd stage U-Boot will now be auto-loaded
        Please do not interrupt the countdown till ...
        Hit any key to stop autoboot:  1 
        TI-MIN#


Use u-boot's *loady 0x80800000* to download code to memory via UART port using Y-modem protocol. Once downloading is 
completed, just *go <load address>*,

.. code-block::

        TI-MIN#loady 80800000 
        ## Ready for binary (ymodem) download to 0x80800000 at 115200 bps...
        Cm - CRC mode, 1700(SOH)/0(STX)/0(CAN) packets, 8 retries
        ## Total Size      = 0x000350dc = 217308 Bytes
        TI-MIN#go 80800000 
        ## Starting application at 0x80800000 ...


        U-Boot 2010.06 (May 09 2016 - 20:09:26)

        TI8148-GP rev 2.1

        ARM clk: 600MHz
        DDR clk: 400MHz

        I2C:   ready
        DRAM:  2 GiB
        NAND:  HW ECC BCH8 Selected
        256 MiB
        MMC:   OMAP SD/MMC: 0
        *** Warning - bad CRC or NAND, using default environment

                          .:;rrr;;.                   
                    ,5#@@@@#####@@@@@@#2,             
                 ,A@@@hi;;;r5;;;;r;rrSG@@@A,          
               r@@#i;:;s222hG;rrsrrrrrr;ri#@@r        
             :@@hr:r;SG3ssrr2r;rrsrsrsrsrr;rh@@:      
            B@H;;rr;3Hs;rrr;sr;;rrsrsrsrsrsr;;H@B     
           @@s:rrs;5#;;rrrr;r#@H:;;rrsrsrsrsrr:s@@    
          @@;;srs&X#9;r;r;;,2@@@rrr:;;rrsrsrsrr;;@@   
         @@;;rrsrrs@MB#@@@@@###@@@@@@#rsrsrsrsrr;;@@  
        G@r;rrsrsr;#X;SX25Ss#@@#M@#9H9rrsrsrsrsrs;r@G 
        @9:srsrsrs;2@;:;;:.X@@@@@H::;rrsrsrsrsrsrr:3@ 
       X@;rrsrsrsrr;XAi;;:&@@#@Bs:rrsrsrsrsrsrsrsrr;@X
       @#;rsrsrsrsrr;r2ir@@@###::rrsrsrsrsrsrsrsrsr:@@
       @A:rrsrsrsrr;:2@29@@M@@@;:;rrrrsrsrsrsrsrsrs;H@
       @&;rsrsrsrr;A@@@@@@###@@@s::;:;;rrsrsrsrsrsr;G@
       @#:rrsrsrsr;G@5Hr25@@@#@@@#9XG9s:rrrrsrsrsrs:#@
       M@;rsrsrsrs;r@&#;::S@@@@@@@M@@@@Grr:;rsrsrsr;@#
       :@s;rsrsrsrr:M#Msrr;;&#@@@@@@@@@@H@@5;rsrsr;s@,
        @@:rrsrsrsr;S@rrrsr;:;r3MH@@#@M5,S@@irrsrr:@@ 
         @A:rrsrsrsrrrrrsrsrrr;::;@##@r:;rH@h;srr:H@  
         ;@9:rrsrsrsrrrsrsrsrsr;,S@Hi@i:;s;MX;rr:h@;  
          r@B:rrrrsrsrsrsrsrr;;sA@#i,i@h;r;S5;r:H@r   
           ,@@r;rrrsrsrsrsrr;2BM3r:;r:G@:rrr;;r@@,    
             B@Mr;rrrrsrsrsr@@S;;;rrr:5M;rr;rM@H      
              .@@@i;;rrrrsrs2i;rrrrr;r@M:;i@@@.       
                .A@@#5r;;;r;;;rrr;r:r#AsM@@H.         
                   ;&@@@@MhXS5i5SX9B@@@@G;            
                       :ihM#@@@@@##hs,                

        AHCI 0001.0300 32 slots 1 ports 3 Gbps 0x1 impl SATA mode
        flags: ncq stag pm led clo only pmp pio slum part 
        Net:   <ethaddr> not set. Reading from E-fuse
        Detected MACID:0:18:32:39:b2:f2
        cpsw
        Hit any key to stop autoboot:  3
        TI8148_EVM#

The new u-boot detects the SATA controller as shown just below the text art. U-Boot's *SCSI* command and 
*FAT* command can be used for the rest of the tests relating to SATA HDD access.

.. code-block::

        TI8148_EVM#scsi scan 
        scanning bus for devices...
          Device 0: (0:0) Vendor: ATA Prod.: Hitachi HTS54505 Rev: GG2O
            Type: Hard Disk
            Capacity: 476940.0 MB = 465.7 GB (976773168 x 512)

        TI8148_EVM#scsi part 

        Partition Map for SCSI device 0  --   Partition Type: DOS

        Partition     Start Sector     Num Sectors     Type
            1		      2048	  20971520	 b
            2		  20973568	 955799600	83
        TI8148_EVM#

The *scan* data above is the result of the *INQUIRY* command while the data from *part* is the result from 
reading HDD partition information. *FAT* commands that list file on partition as well as loading file are:

.. code-block::

        TI8148_EVM#fatls scsi 0 
          3522384   uimage 
         95158272   rootfs.ubi.img 
         100925440   rootfs.ubi.img.624 

        3 file(s), 0 dir(s)

        TI8148_EVM#fatload scsi 0 80800000 uimage
        reading uimage

        3522384 bytes read
        TI8148_EVM#bootm 80800000 
        ## Booting kernel from Legacy Image at 80800000 ...
           Image Name:   Linux-2.6.37
           Image Type:   ARM Linux Kernel Image (uncompressed)
           Data Size:    3522320 Bytes = 3.4 MiB
           Load Address: 80008000
           Entry Point:  80008000
           Verifying Checksum ... OK
           Loading Kernel Image ... OK
        OK

        Starting kernel ...

        Uncompressing Linux... done, booting the kernel.

U-Boot's *bootcmd* can then be customize to *fatload* the kernel image from the harddisk instead of NAND
or SD card. To do this, set  *bootcmd='fatload scsi 0 $loadaddr uImage2 && bootm $loadaddr'*.

*u-boot.bin* that is tested above can be flashed to NAND partition. For my case, the partition offset
is at *0x20000*, and the size of this u-boot is less than 256KB. 

After I satisfy with the result, I download and flash to NAND using the commands below.

.. code-block::

        TI-MIN#nand erase 20000 40000
        TI-MIN#nandecc hw 2
        TI-MIN#nand write 80800000 20000 40000

Conclusion
==========

Having SATA support added to u-boot for this platform gives me the flexibilty to have multiple images in
the FAT partition of the HDD where I can selectively use.

Citations
=========

.. [1] TMS320DM814x Davinci Digital Video Processor Technical Reference Manual, SPRUGZ8D, Revised April 2013.

.. [2] arm-2009q1-203-arm-none-linux-gnueabi.bin, TI cross toolchain.

.. [3] LINUXEZSDK-DAVINCI: Linux EZ Software Development Kit (EZSDK) for DM814x and DM816x- ALPHA,ezsdk_dm814x-evm_5_05_01_04_setuplinux, www.ti.com/tool/linuxezsdk-davinci, v5.05.01.04-ALPHA, 10 OCt, 2012.
