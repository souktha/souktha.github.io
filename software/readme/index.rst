.. title: Carrier Card Source repository
.. date: 2021--2-25 11:52:00
.. tags: software
.. category: VxWorks
.. link:
.. description: README file 
.. type: text

This is *VxWorks* source code for carrier card software, an initial archive to the repository for
on-going work on R-EGI project. This source code is targeted Xilinx ZCU102 ZynqMP Ultrascale+ 
design reference platform. 

The software produces VxWorks (ELF) and uVxWorks (U-Bootable) as well as its binary to run on
ZCU102 board.

Host build requirements
========================

* WIN10 PC

  Optional: VMWare for WIN10 running Linux guest OS to run QEMU. This is helpful if you don't have ZCU102 board.

* VxWorks 7 OS and toolchain, *vx_sr540* for WIN10. Typically this is installed in *c:\RTN\windriver* directory.

* VxWorks board support package (BSP), *xlnx_zynqmp_1_0_4_0*. This is included in the installation package that
  support ZCU102 board.

Build environments
-------------------

You need to have the following environment variables defined for VxWorks toolchain,

* WIND_HOME
  WIND_BASE
  WIND_WRTOOL_WORKSPACE
  WIND_LAYER_PATHS
  WIND_LICENS_FILE

When those variables are defined, you can build. These variable in be put into a batch file. An
example, *myenv.bat* is provided as an example. Edit it to match your settings then excute it so
you can run VxWorks's *wrtool* or the GUI *workbench*. I use the command line *wrtool*. 

Contents
===========

Three main directories are:

1.      *regi*, this is VxWorks Source Build directory (VSB).

2.      *kernel*, this is VxWorks Image Project directory (VIP).

3.      *ntsf*, this is RTX directory containing NTSF messaging code ported from Green Hills's OMEGA project. 
        This directory is called outer layer of VxWorks. *WIND_LAYER_PATHS* point to this directory. If you don'tdefine this path, the build will fail.

What changes
==============

Currenly the code is bare bone. IS177 messages in *ntsf/msg* compiled to object codes. No task is written to
use it yet. So everything outside of *ntsf* directory is pretty much VxWorks code.

kernel/usrAppInit.c
----------------------

A call to ntsfInitialize() is added to its initialization to start up two sample tasks using message queue. This
function is in *ntsf/src* directory.

Enable UART1 of ZCU102 board
-----------------------------

In the VIP workspace,the ZCU102 device tree source file, *xlnx_zynqmp_1_0_4_0/xlnx-zcu102.dts* is edited to
enable UART1 port (alias serial1). This will show up on VxWorks as */tyC0/1* device. It is intended that
this port is to be used for connecting to host for GPS messages processing. UART0 is used for VxWorks shell
console.

Building source code for output images
========================================

You can use either GUI workbench or its command line, *wrtool* to build the project. Please refer to VxWorks 
documents on how to its IDE tool. For command line, *wrtool*, the step I used,

*  Open command prompt shell on WIN10.

*  In DOS command line prompt, cd to *c:\RTN\windriver\vx7_sr40* then run *myenv.bat*, the batch file that set my environment variables.

* run *wrtool*

* In *wrtool* shell, cd to my workspace, for example, *cd c:/\users/\1234567/\workspace/\carrier-card-source*,
  which is the base of the source code.

* cd to *regi*

* *prj build* the VSB (regi). 

* cd to *../kernel*, then *prj build* to build bootable image.


Loading and running VxWorks on ZCU102 board
============================================

Image file *vxWorks* (ELF) or *uVxWorks* built from this source can be copied to SD card of ZCU102. Using *uVxWorks* for
u-boot is recommened so copy it to SD card along with *xlnx-zcu102.dtb* file. Do not use U-Boot or Linux DTB file for
VxWorks. They don't work. Edit U-Boot boot script to automatically load and boot the VxWorks. This is U-Boot instructions 
and its related Xilinx instruction for ZCU102. I won't cover here.

Booting on real h/w ZCU102 board
---------------------------------

Set the boot switch options on ZCU102 board for SD card accordingly (see Xilinx doc). Alhough ZCU102 can boot from various devices,
JTAG, SD card, Flash, ony SD card is mentioned here and it is considered standard default booting. Xilinx shipped their
reference design board with this option.

It is easiest to edit the u-boot script to make it boot automaticall (see u-boot doc) on ZCU102, but if you do not want to you
can always boot it manually.

Manually boot from SD card
---------------------------

* Stop at u-boot prompt and use u-boot MMC utilities to load uVxWorks and its dtb file, for example (assuming the VxWorks files needed are in SD card),

  .. code-block::

        fatload mmc 0 2000000 uVxWorks
        fatload mmc 0 1000000 xlnx-zcu102.dtb
        bootm 2000000 - 1000000

This should boot VxWorks. An automate boot script can be created and automatically performs the boot operation. 

Loading and running VxWorks on QEMU
-------------------------------------

What happen if you don't have ZCU102 board ? QEMU is the solution. You need to build QEMU package on a Linux PC though.
You can install VMWare and Linux guest OS on it for your own convenience. The instruction below apply to Linux host.

*    Requirements: git clone QEMU from Xilinx's repository and follow its instruction on configuration options, for example,

  .. code-block::
        
        ./configure --target-list=aarch64-softmmu,aarch64-linux-user,arm-softmmu,arm-linux-user,microblazeel --prefix=/opt/qemu-xlnx
        make && make install

note: QEMU from upstream will not work, use Xilinx's QEMU instead. If using Xilinx's  petalinux, it will be build along the image, but 
this package is too big and it is not necessary for VxWorks.

* *uVxWorks* uses its own *xlnx-zcu102.dtb* file. Do not use Linux's or U-Boot DTB file. 

Xilinx QEMU boot ZCU102 in multiple stages, one is to boot ARM ATF and its microblaze with PMU f/w. This is the 1st boot. It then wait to connect
to 2nd boot with FSBL and U-Boot before let go of control.

Miscellaneous
--------------

Some helper scripts are provided in *misc* directory for buiding VxWorks and for running QEMU h/w emulation. These are,

* *myenv.bat* - VxWorks build environment variables setting. Edit it to fit your host installation.

* *vx.sh* bash shell script (QEMU booting scripts), *ublazepeta.sh* its MicroBlaze companion invoked by *vx.sh*. 

* *vxboot.scr* (u-boot script) that *vx.sh* loads. *vxargs.txt* is text file that create *vxboot.scr* using u-boot's *mkimage*.

* Companions firmware files that can be used on both QEMU or real ZCU102 board. The provided boot scripts need these firmwware
  files to bring up the virtual core on QEMU. The ELF firmware files are identically used for
  real h/w except the DTBs where they are specific for QEMU. You cannot use QEMU DTBs on real h/w.

Console capture of QEMU boot
-----------------------------

.. code-block::
     
        PMU Firmware 2020.2     Feb 10 2021   15:27:10
        PMU_ROM Version: xpbr-v8.1.0-0
        NOTICE:  ATF running on XCZUUNKN/QEMU v4/RTL0.0 at 0xfffea000
        NOTICE:  BL31: v2.2(release):xilinx_rebase_v2.2_2020.2
        NOTICE:  BL31: Built : 15:26:48, Feb 10 2021


        U-Boot 2020.01 (Feb 10 2021 - 15:38:17 +0000)

        Model: ZynqMP ZCU102 Rev1.0
        Board: Xilinx ZynqMP
        DRAM:  4 GiB
        PMUFW:  v1.1
        EL Level:       EL2
        Chip ID:        unknown
        NAND:  0 MiB
        MMC:   mmc@ff170000: 0
        In:    serial@ff000000
        Out:   serial@ff000000
        Err:   serial@ff000000
        Bootmode: SD_MODE1
        Reset reason:
        Net:   
        ZYNQ GEM: ff0e0000, mdio bus ff0e0000, phyaddr 12, interface rgmii-id

        Warning: ethernet@ff0e0000 using MAC address from DT
        eth0: ethernet@ff0e0000
        Hit any key to stop autoboot:  0 
        MMC: no card present
        JTAG: Trying to boot script at 0x20000000
        ## Executing script at 20000000
        ## Booting kernel from Legacy Image at 02000000 ...
           Image Name:   vxWorks
           Image Type:   AArch64 VxWorks Kernel Image (uncompressed)
           Data Size:    1386912 Bytes = 1.3 MiB
           Load Address: 00100000
           Entry Point:  00100000
           Verifying Checksum ... OK
        ## Flattened Device Tree blob at 01000000
           Booting using the fdt blob at 0x1000000
           Loading Kernel Image
           !!! WARNING !!! Using legacy DTB
           Loading Device Tree to 000000000fff8000, end 000000000ffff802 ... OK
        ## Starting vxWorks at 0x00100000, device tree at 0x0fff8000 ...
 
         _________            _________
         \77777777\          /77777777/
          \77777777\        /77777777/
           \77777777\      /77777777/
            \77777777\    /77777777/
             \77777777\   \7777777/
              \77777777\   \77777/              VxWorks 7 SMP 64-bit
               \77777777\   \777/
                \77777777\   \7/     Core Kernel version: 1.2.7.0
                 \77777777\   -      Build date: Feb 25 2021 10:38:40
                  \77777777\
                   \7777777/         Copyright Wind River Systems, Inc.
                    \77777/   -                 1984-2021
                     \777/   /7\
                      \7/   /777\
                       -   -------

                   Board: Xilinx ZCU102
               CPU Count: 4
          OS Memory Size: 4095MB
        ED&R Policy Mode: Permanently Deployed


         Adding 4412 symbols for standalone.
        ntsfInitialize
         entering
        _ntsfTask entering
        _IOTask entering, tps 60 
        code 1
        .ntsfInitialize exiting, status 
        -> ....code 1
        ..d.ev.s
        drv name                
          0 /null               
          1 /tyCo/0             
          1 /tyCo/1             
        value = 25 = 0x19
        -> .code 1
        .....code 1
        .....code 1
        ...w
          NAME             TID          STATUS     DELAY    OBJ_TYPE        OBJ_ID      
        ---------- ------------------ ---------- --------- ---------- ------------------
        tJobTask   0xffff800000044b80 PEND               0 SEM_B      0xffffffff8021cdd0
        tExcTask   0xffffffff802665b0 PEND               0 SEM_B      0xffffffff8021cb80
        tLogTask   0xffff80000004a670 PEND               0 MSG_Q(R)   0xffff800000049260
        tShell0    0xffff80000005d490 READY              0                           0x0
        tVxdbgTask 0xffff8000000514d0 PEND               0 SEM_B      0xffffffff8021a1d0
        ntsfTask   0xffffffff80265a50 PEND               0 MSG_Q(R)   0xffffffff80264f00
        IOTask     0xffffffff80260a20 DELAY             15                           0x0
        miiBusMoni 0xffff800000070a00 DELAY             77                           0x0
        tIdleTask0 0xffffffff8026f290 READY              0                           0x0
        tIdleTask1 0xffffffff80274760 READY              0                           0x0
        tIdleTask2 0xffffffff80279c30 READY              0                           0x0
        tIdleTask3 0xffffffff8027f100 READY              0                           0x0
        value = 0 = 0x0
        -> ..code 1

