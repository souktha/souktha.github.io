.. title: Decoupling Xilinx Zynq PS and PL on Linux for Digilent Zybo
.. slug: zybo-quickstart
.. date: 2016-04-23 19:08:20 UTC
.. tags: software, hardware
.. category: 
.. link: 
.. description: 
.. type: text

Digilent Zybo board is built around Xilinx Zynq-7000 family [1_]. This Zynq-7000 is integrated with a dual-core
ARM Cortex-A9 processor that has Linux support for it. In addition to this PS unit, the Xilinx 7-series
FPGA is also integrated as the PL component of this SoC [2_]. This demonstation will show how easy it is
to decouple PS and PL components. 

.. TEASER_END

Xilinx provides tools and utilities to get the Linux up and running on this board. One can use the
GNU tools in their SDK to build Linux kernel and u-boot, but those tools are based on standard
*glibc* which is too big for my use so I chose to build the smaller toolchain and root FS with
*buildroot* based on uClibc. For my use,

.. code-block::
        
        buildroot-2016.02$make zedboard_defconfig
        buildroot-2016.02$make

The default configuration builds the basic cross toolchain and minimum rootfs with majority of the utilities
provided by *busybox*. 
For this demo, it is not relevant what toolchain to use. Use what suits you. It is fine to stick 
with Xilinx GNU toolchain. It will work as well.

Essential software components
=============================

. uboot-xlnx, Xilinx version. Built with *zynq_zybo_defconfig*.

. linux-xlnx, Xilinx version. Built with *xilinx_zynq_defconfig*.

. root FS.

Once the u-boot and kernel built is done, prepare the SD card to put boot code, kernel and rootfs.
For the boot code, I need two files, *boot.bin* (in u-boot-xlnx/spl directory) and *u-boot.img*.
Copy them to SD boot partition. After that I populate the SD root partition with my choice of
rootfs.
For my development, I combine zImage with dtb so I do not have to have it load separately during
kernel boot up. I use the script below for my source,

.. code-block::

        /dts-v1/;

        / {
	description = "ARM Zynq Zybo FIT (Flattened Image Tree)";
	#address-cells = <1>;

	images {
		kernel@1 {
			description = "ARM Xilinx Zynq Linux-4.x";
			data = /incbin/("zImage");
			type = "kernel";
			arch = "arm";
			os = "linux";
			compression = "none";
			load = <0x800000>;
			entry = <0x800000>;
			hash@1 {
				algo = "crc32";
			};
			hash@2 {
				algo = "sha1";
			};
		};

		fdt@1 {
			description = "ARM Zynq Zybo device tree blob";
			data = /incbin/("dts/zynq-zybo.dtb");
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
			description = "Zynq Zybo";
			kernel = "kernel@1";
			fdt = "fdt@1";
		};

	};
        };

I place this script, *kernel.its*, in *linux-xlnx/arch/arm/boot* where I create the kernel image
with device tree blob

.. code-block::

        $mkimage -f kernel.its zImage.itb

The *zImage.itb* will be copied to SD boot partition later, but I need to test it first.
I stop at u-boot prompt at boot up to tftp zImage.itb,

.. code-block::
        
        zynq>tftpboot 100000 zImage.itb
        ethernet@e000b000 Waiting for PHY auto negotiation to complete...... done
        Using ethernet@e000b000 device
        TFTP from server 192.168.10.14; our IP address is 192.168.10.3
        Filename 'zImage.itb'.
        Load address: 0x100000
        Loading: ################################################################
	 #################################################################
         ..
	 ####################
	 3.4 MiB/s
        done
        Bytes transferred = 3760372 (3960f4 hex)
        Zynq> set bootargs 'root=dev/mmcblk0p2 rootfstype=ext4 rootwait rw' && bootm 100000 
        ## Loading kernel from FIT Image at 00100000 ...
           Using 'config@1' configuration
           Verifying Hash Integrity ... OK
           Trying 'kernel@1' kernel subimage
             Description:  ARM Xilinx Zynq Linux-4.x
             Type:         Kernel Image
             Compression:  uncompressed
             Data Start:   0x001000e8
             ..
          Verifying Hash Integrity ... crc32+ sha1+ OK
           Booting using the fdt blob at 0x493b6c
           Loading Kernel Image ... OK
           Loading Device Tree to 1f314000, end 1f31925e ... OK

        Starting kernel ...

        Booting Linux on physical CPU 0x0
        Linux version 4.4.0-xilinx-34568-g9c1d910-dirty (xxx@host3) (gcc version 4.9.3 (Buildroot 2016.02) ) #2 SMP PREEMPT Sat Apr 23 18:32:38 PDT 2016
        CPU: ARMv7 Processor [413fc090] revision 0 (ARMv7), cr=18c5387d
        CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
        Machine model: Zynq ZYBO Development Board
        ..

        EXT4-fs (mmcblk0p2): mounted filesystem with ordered data mode. Opts: (null)
        VFS: Mounted root (ext4 filesystem) on device 179:2.
        devtmpfs: mounted
        Freeing unused kernel memory: 252K (c06bb000 - c06fa000)
        EXT4-fs (mmcblk0p2): re-mounted. Opts: data=ordered
        ..
        done.
        Starting network...
        IPv6: ADDRCONF(NETDEV_UP): eth0: link is not ready
        Starting ntpd: OK

        Welcome to Buildroot
        buildroot login: 

Once I verified that *zImage.itb* is good and rootfs is sane. I can finalize the SD card and edit the necessary
boot scripts. The Linux booting process is done at this point and I can login to Zybo linux host.

Tool to validate the decoupling of PS and PL components
=======================================================

. Only Vivado h/w synthesis tool. No SDK needed.

The tool that can be used to program the bitstream to the PL components of the board is readily availble as a 
character device driver, *xilinx_devcfg*, which is a device configuration driver. This is the built-in component
of the kernel. I need not modify anything as it is working just fine, but I need to know how to use it.
If I load the bitstream that generated by Vivado, it will hang and I have to reset the board. This is because
it assumes that the binary I load is generated by SDK's *bitgen* so it tries to post initialize the FPGA after the loading. 
The bitstgream generated by Vivado synthesis tool is considered *partial bitstream* so
it needs to be loaded as partial bitstream. To do that, I need to tell it before I load the bitstream,

.. code-block::

       $echo 1 > /sys/devices/soc0/amba/f8007000.devcfg/is_partial_bitstream  

After this flag is set, FPGA post initialization will not be invoked. This enable me to load the bitstream
at will. Of course, this assumes that the system is running in non-secure mode and that no POR is required.

Using this simple switches to LEDs, synthesize and generate the bitstream (Vivado) and load it,

.. code-block::

        `timescale 1ns / 1ps
        module simpletest(
            input [3:0] sw,
            output [3:0] led,
            input clk
            );
    
            assign led = sw ;
    
        endmodule

Consider that to be *helloworld* for the PL component. Once synthesized, bring it over to the Zybo
and load it,

.. code-block::


        $cat simpletest.bit > /dev/xdevcfg

After the *is_partial_bitstream* is set, I can keep on loading the bitstream. Any new bitstream will
overwrite the old one that is currently active. If the bitstream is part of the kernel component such
that it instantiates I/O device within Linux, I will need to consider stopping the process that use
that I/O and unload its driver before loading the new bitstream. This is strictly implementation 
dependent based on the design.

Conclusion
============

The benefit that I get from this is:

. I do not need to use *bitgen* for a quick test run on the FPGA code that is not interdependent 
with kernel. I can avoid exporting the bitstream to Xilinx SDK for various cases.

. I do not need to restart to load the bitstream at bootup time ie.. u-boot's *fpga load ..* command.

. I can keep PS/PL decouple for the FPGA test code until I am ready to integrate the PS/PL for embedded
purpose.

Citations
==========

.. [1] Zybo(TM) FPGA Board Reference Manual, zybo_rm.pdf, Februrary 2013, Zybo rev B, Digilent.

.. [2] Zynq-7000 All Programmable SoC Techincal Reference Manual, ug585-Zynq-7000-TRM.pdf, Feb 2015, Xilinx.



