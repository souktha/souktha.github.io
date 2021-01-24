.. title: Adding a custom ARM platform to QEMU 5.2.0
.. slug: qemu-port
.. date: 2021-01-02 17:19:03 UTC
.. tags: software
.. category: Linux
.. link: 
.. description: 
.. type: text

The SoC is being developed by the ASIC team, but the software team wants to develop the software concurrently
for the hardware that is not yet available, at least not for another 3 months or longer. In this situation what do
you do ? 

.. TEASER_END

In the early phase of SoC development you don't usually have hardware available, but you want to develop the software
concurrently with the ASIC development. One option is to find the platform with the closest architecture and develop
the software based on that platform, but it not always that easy to find. If you could, why would you want to continue 
with your SoC development ? You are already steps behind your competitors. This option will also come with a lot of clean-up
work later on. The other option is to software emulated your platform such that we can develop and test your software
implementation to its nearest target platform. This is what QEMU comes in to play. This blog is one of two parts series.
One is to add new ARM platform into QEMU to emulate the hardware while the other part is to port *FreeRTOS* to support
the new platform.

An open source, QEMU from *qemu.org* is a generic machine emulator and virtualizer that supports various CPU architectures and platforms.
QEMU runs on most mainstream OS, Linux, Windows, and MacOS. Since it is an open source, you can customize by adding the
new platform into this package, build, install and use it. This blogs documents about how I add a custom ARM Cortex R-5 
platform in to the existing package. I call it *real-time experimental SoC, rtx-soc* platform. This platform will be added
to the supported ARM CPU architectur the *QEMU*. 

Components
===========

Two main components needed: *QEMU* package (and other s/w dependencies required by this package) and the host PC (Linux). 
The software packages required by QEMU are listed in its respective QEMU site for building the QEMU. It is most likely
that the needed dependencies are met if you fully installed the Linux distribution. If not, only minimal effort is needed.
I choose the latest release version *qemu-5.2.0* of early 2021 since I find it to be
easier than the earlier version for adding new target. I have actually done this with version *qemu-5.1.0* and found that
the latest version is easier to port. 

The host PC is for building and running the QEMU to virtualize the h/w platform. For my case I use Linux x64 Slackware with kernel built 
to support virtualization. The PC BIOS should have virtualization enable as well. 

QEMU
-----
* QEMU

  * version: qemu-5.2.0, which is the latest as of Jan 2021.
         
  * Emulation: ARM and AARCH64 on Linux x64 host.

* SoC target plaform to be added:

  * ARM Cortex-R5 with 4MB on-chip RAM (OCR).
  * APB peripherals: UART, Timer, I2C
  * GICv2 Interrupt controller
  * Flash and others
       
Before you begin the work, you might as well test build the stock release as-is for the ARM emulation. If all the dependencies 
are met the package should build successfully. To build as-is for ARM, extract the package then *cd qemu-5.2.0* to configure
and build,

.. code-block:: 

        ./configure --target-list=arm-softmmu,arm-linux-user,aarch64-softmmu,aarch64-linux-user --prefix=/opt/qemu-5.2.0/
        
This configure for ARMv7 and ARMv8 and install to */opt/qemu-5.2.0* when you do *make install*. The output of the built
QEMU is in its *build/* directory. You can as well run QEMU from this directory without having to install it to the
desired location.

Check the machines supported by this build,

.. code-block::

        qemu-system-aarch64 -M help

Will list the ARM platforms supported, for examples,

.. code-block::

        Supported machines are:
        akita                Sharp SL-C1000 (Akita) PDA (PXA270)
        ast2500-evb          Aspeed AST2500 EVB (ARM1176)
        ast2600-evb          Aspeed AST2600 EVB (Cortex A7)
        borzoi               Sharp SL-C3100 (Borzoi) PDA (PXA270)
        canon-a1100          Canon PowerShot A1100 IS
        cheetah              Palm Tungsten|E aka. Cheetah PDA (OMAP310)
        collie               Sharp SL-5500 (Collie) PDA (SA-1110)
        connex               Gumstix Connex (PXA255)
        ..

Adding platform to QEMU
=======================

In QEMU directories structure, I only need to work in two directories, *hw/arm/* and *default-configs/devices/* to add
the new target platform and to modified the existing configuration incorporating new platform. 

Adding *rtx-soc* to configuration
----------------------------------

1) Specify QEMU platform and what the platform needs for its basic peripherals. To do this, add *config RTX_SOC*
block which is a custom platform to *hw/arm/Kconfig* by editing this file (line 8-15),

.. code-block::
        :linenos:

        ..
        config NETDUINOPLUS2
            bool
            select STM32F405_SOC

        #add RTX_SOC block here

        config RTX_SOC
            bool
            select ARM_MPTIMER
            select ARM_TIMER # sp804
            select PL011 # UART
            select ARM_GIC
            select VIRTIO_MMIO
            select UNIMP
        #end  of block added
        config NSERIES
            bool
            ..

The components chosen by *select* are the peripherals that my platform needs to instantiate on board bring-up. They
are the QEMU objects to be invoked in the source code so they too need to be configured as default devices. More 
peripherals can be added in the future, but it is adequate for my need at the time being.

2) Adding to *CONFIG_RTX_SOC* to *default-configs/devices/arm-softmmu.mak* file for the above configuration.
QEMU will build RTX_SOC platform as a default supported platform among others (line 3).

.. code-block::
        :linenos:

        ..
        CONFIG_TOSA=y
        CONFIG_RTX_SOC=y  
        CONFIG_Z2=y
        ..

3) Add file name *rtx-soc.c* to be compiled to QEMU 5.2.0's *hw/arm/meson.build* script. This is the 
emulated Cortex-R5 RTX_SOC target platform (line 3).

.. code-block::
        :linenos:

        ..
        arm_ss.add(when: 'CONFIG_REALVIEW', if_true: files('realview.c'))
        arm_ss.add(when: 'CONFIG_RTX_SOC', if_true: files('rtx-soc.c'))
        arm_ss.add(when: 'CONFIG_SBSA_REF', if_true: files('sbsa-ref.c'))
        ..

The configuration part of this package is complete. Next is to add platform machine file.

Creating and adding platform file
----------------------------------

*rtx-soc.c* is source file to describe the ARM Cortex-R5 platform to be added to the supported platform as described in
the section above. The Cortex-R5 CPU support is in *target/arm* directory of the QEMU. There is no need
to do anything with respect to this directory or any subdirectory in *target/*. All other peripheral
components are in *hw/* subdirectories, for example, *hw/char/* (serial port), *hw/net/* (Ethernet network),
*/hw/block/* (flash) etc... You can explore the subdirectories of *hw/* to find out what you need 
to add them to your platform.

Simply create *rtx-soc.c* source file in QEMU's */hw/arm/* directory. The edited configuration already made
as described above will compile this source into QEMU to support this platform. 

Implementation of *rtx-soc.c* for Cortex-R5 platform
=====================================================

Instead of creating *rtx-soc.c* from scratch, it is best to clone it from the one of the existing file
in *hw/arm/* directory. Browsing through these files, I choose ARM Versatile Express emulation, *vexpress.c*,
as the base line and clone it to be *rtx-soc.c* because it has many similar peripherals that I need and 
having the content that is easier to understand. The *vexpress* is based on Cortex-A9 and Cortex-A15 multicore
h/w platform. I will replace these ARM cores in *rtx-soc.c* for Cortex-R5. The components that do not exist
in my platform will be removed and the components that I need will be added. 

Steps involved
---------------

*  Copy *vexpress.c* to *rtx-soc.c* - start of with this cloned file.
        
*  Edit the clone file, *rtx-soc.c* :

   *  Create the *hwaddr* structure that defines my platform need to be created to match the phyiscal addresses of the memory and peripheral devices. I can edit the existing structure to fit my need,

   .. code-block:: c
        :linenos:

        static hwaddr motherboard_rtx_r5_map[] = {
        /* clone from legacy map . For RTX R5, it has
         * no northbridge/southbridge interface complexity. */
            [VE_NORFLASHALIAS] = 0,
            [VE_UART0] = 0x58000000,
            [VE_UART1] = 0x58010000,
            [VE_UART2] = 0x58020000,
            [VE_UART3] = 0x58030000,
            [VE_TIMER01] = 0x580a0000,
            [VE_VIRTIO] = 0x10013000,
            [VE_RTC] = 0x10017000,
            /* CS0: 0x40000000 .. 0x44000000 */
            [VE_NORFLASH0] = 0x40000000,
            [VE_USB] = 0x58140000,
        };

   More elements can be added as needed.

   * Create/edit *VEDBoardInfo* structure for this platform and specify to use motherboard map as defined above,

   .. code-block:: c
    :linenos:

        static VEDBoardInfo r5_daughterboard = {
            .motherboard_map = motherboard_rtx_r5_map,
            .loader_start = 0x00000000, /* use same loader start address */
            .gic_cpu_if_addr = 0x58200000,
            .proc_id = 0x14000237,
            /* use same voltage and clocks as in A15's */
            .num_voltage_sensors = ARRAY_SIZE(a15_voltages),
            .voltages = a15_voltages,
            .num_clocks = ARRAY_SIZE(a15_clocks),
            .clocks = a15_clocks,
            .init = r5_daughterboard_init,
        };

  
   * Create/edit the rtx-soc machine classes and information structures for initialization. For machine state, use *VexpressMachineState* since it is not necessary to rename it. 

   .. code-block:: c
    :linenos:

        static void rtx_soc_class_init(ObjectClass *oc, void *data)
        {
            MachineClass *mc = MACHINE_CLASS(oc);

            mc->desc = "ARM Real Time Experiment (RTX)";
            mc->init = rtx_soc_common_init;
            mc->max_cpus = 1; // single core
            mc->ignore_memory_transaction_failures = true;
            mc->default_ram_id = "rtx_soc.highmem";
        }


        static void rtx_soc_instance_init(Object *obj)
        {
            VexpressMachineState *vms = RTX_MACHINE(obj);

            /* EL3 is enabled by default on rtx_soc */
            vms->secure = true;
            object_property_add_bool(obj, "secure", rtx_soc_get_secure,
                             rtx_soc_set_secure);
            object_property_set_description(obj, "secure",
                                    "Set on/off to enable/disable the ARM "
                                    "Security Extensions (TrustZone)");
        }

        static void rtx_soc_r5_instance_init(Object *obj)
        {
            VexpressMachineState *vms = RTX_MACHINE(obj);

            vms->virt = false;
            vms->secure = false;
        }

        static void rtx_soc_r5_class_init(ObjectClass *oc, void *data)
        {
            MachineClass *mc = MACHINE_CLASS(oc);
            VexpressMachineClass *vmc = RTX_MACHINE_CLASS(oc);

            mc->desc = "ARM Real Time Experiment (RTX) Cortex-r5f";
            mc->default_cpu_type = ARM_CPU_TYPE_NAME("cortex-r5f");

            vmc->daughterboard = &r5_daughterboard;
        }

        static const TypeInfo rtx_soc_info = {
            .name = TYPE_RTX_MACHINE,
            .parent = TYPE_MACHINE,
            .abstract = true,
            /* use the same Machine state clone from vexpress */
            .instance_size = sizeof(VexpressMachineState),
            .instance_init = rtx_soc_instance_init,
            .class_size = sizeof(VexpressMachineClass),
            .class_init = rtx_soc_class_init,
        };

        static const TypeInfo rtx_soc_r5_info = {
            .name = TYPE_RTX_R5_MACHINE,
            .parent = TYPE_RTX_MACHINE,
            .class_init = rtx_soc_r5_class_init,
            .instance_init = rtx_soc_r5_instance_init,
        };


   * Create/edit *type_init()* macro to invoke machine initialization for this platform.

   .. code-block:: c
     :linenos:

       static void rtx_soc_machine_init(void)
        {
            type_register_static(&rtx_soc_info);
            type_register_static(&rtx_soc_r5_info);
        }

      type_init(rtx_soc_machine_init);

   * Define the machine type and object macros used in the structures above,

   .. code-block:: c
        :linenos:

        #define TYPE_RTX_MACHINE   "rtx"
        #define TYPE_RTX_R5_MACHINE   MACHINE_TYPE_NAME("rtx-r5")
        #define RTX_MACHINE(obj) \
            OBJECT_CHECK(VexpressMachineState, (obj), TYPE_RTX_MACHINE)
        #define RTX_MACHINE_GET_CLASS(obj) \
            OBJECT_GET_CLASS(VexpressMachineClass, obj, TYPE_RTX_MACHINE)
        #define RTX_MACHINE_CLASS(klass) \
            OBJECT_CLASS_CHECK(VexpressMachineClass, klass, TYPE_RTX_MACHINE)

   * When machine class is initialized, *rtx_soc_common_init()* function is called so we need to implement this function. The *vexpress_common_init()* is renamed and edited to become this function. This function is for instantiating devices defined for the target platform. For RTX platform, the clocks and voltage sensors remain the same as the Vexpress's. MMC, Keyboard, VRAM devices are commented out. Only one UART0 is used so UART1-3 are not instantiated. 

 .. code-block:: c
        :linenos:

        static void rtx_soc_common_init(MachineState * machine) {
          VexpressMachineState * vms = RTX_MACHINE(machine);
          VexpressMachineClass * vmc = RTX_MACHINE_GET_CLASS(machine);
          VEDBoardInfo * daughterboard = vmc -> daughterboard;  
          DeviceState * dev, * sysctl, * pl041;
          qemu_irq pic[64];
          uint32_t sys_id;
          I2CBus * i2c;
          ram_addr_t sram_size;
          MemoryRegion * sysmem = get_system_memory();
          MemoryRegion * sram = g_new(MemoryRegion, 1);
          const hwaddr * map = daughterboard -> motherboard_map;
          int i;        

          daughterboard -> init(vms, machine -> ram_size, machine -> cpu_type, pic);

          /*
           * If a bios file was provided, attempt to map it into memory
           */
          if (bios_name) {
            char * fn;
            int image_size;

            if (drive_get(IF_PFLASH, 0, 0)) {
              error_report("The contents of the first flash device may be "
                "specified with -bios or with -drive if=pflash... "
                "but you cannot use both options at once");             
              exit(1);
            }
            fn = qemu_find_file(QEMU_FILE_TYPE_BIOS, bios_name);
            if (!fn) {
              error_report("Could not find ROM image '%s'", bios_name);
              exit(1);
            }
            image_size = load_image_targphys(fn, map[VE_NORFLASH0],
              RTX_FLASH_SIZE);
            g_free(fn);
            if (image_size < 0) {
              error_report("Could not load ROM image '%s'", bios_name);
              exit(1);
            }
          }

          /* Motherboard peripherals: the wiring is the same but the    
           * addresses vary between the legacy and A-Series memory maps.
           */

          sys_id = 0x1190f500;

          sysctl = qdev_new("realview_sysctl");
          qdev_prop_set_uint32(sysctl, "sys_id", sys_id);
          qdev_prop_set_uint32(sysctl, "proc_id", daughterboard -> proc_id);    
          qdev_prop_set_uint32(sysctl, "len-db-voltage",
          daughterboard -> num_voltage_sensors);
          for (i = 0; i < daughterboard -> num_voltage_sensors; i++) {
            char * propname = g_strdup_printf("db-voltage[%d]", i);
            qdev_prop_set_uint32(sysctl, propname, daughterboard -> voltages[i]);       
            g_free(propname);
          }
          qdev_prop_set_uint32(sysctl, "len-db-clock",
          daughterboard -> num_clocks);       
          for (i = 0; i < daughterboard -> num_clocks; i++) {
            char * propname = g_strdup_printf("db-clock[%d]", i);
            qdev_prop_set_uint32(sysctl, propname, daughterboard -> clocks[i]);
            g_free(propname);
          }
          sysbus_realize_and_unref(SYS_BUS_DEVICE(sysctl), & error_fatal);
          sysbus_mmio_map(SYS_BUS_DEVICE(sysctl), 0, map[VE_SYSREGS]);

          /* VE_SP810: not modelled */
          /* VE_SERIALPCI: not modelled */

          pl041 = qdev_new("pl041");
          qdev_prop_set_uint32(pl041, "nc_fifo_depth", 512);
          sysbus_realize_and_unref(SYS_BUS_DEVICE(pl041), & error_fatal);
          sysbus_mmio_map(SYS_BUS_DEVICE(pl041), 0, map[VE_PL041]);
          sysbus_connect_irq(SYS_BUS_DEVICE(pl041), 0, pic[11]);

          pl011_create(map[VE_UART0], pic[5], serial_hd(0));

          sysbus_create_simple("sp804", map[VE_TIMER01], pic[2]);
          sysbus_create_simple("sp804", map[VE_TIMER23], pic[3]);

          dev = sysbus_create_simple(TYPE_VERSATILE_I2C, map[VE_SERIALDVI], NULL);
          i2c = (I2CBus * ) qdev_get_child_bus(dev, "i2c");
          i2c_slave_create_simple(i2c, "sii9022", 0x39);

          sysbus_create_simple("pl031", map[VE_RTC], pic[4]); /* RTC */

          /* VE_COMPACTFLASH: not modelled */

          sram_size = 0x200000;

          memory_region_init_ram(sram, NULL, "rtx_soc.sram", sram_size, &
            error_fatal);
          memory_region_add_subregion(sysmem, map[VE_SRAM], sram);

          /* VE_USB: not modelled */

          /* VE_DAPROM: not modelled */

          /* Create mmio transports, so the user can create virtio backends
           * (which will be automatically plugged in to the transports). If
           * no backend is created the transport will just sit harmlessly idle.
           */
          for (i = 0; i < NUM_VIRTIO_TRANSPORTS; i++) {
            sysbus_create_simple("virtio-mmio", map[VE_VIRTIO] + 0x200 * i,
              pic[40 + i]);
          }
          daughterboard -> bootinfo.ram_size = machine -> ram_size;
          daughterboard -> bootinfo.nb_cpus = machine -> smp.cpus;
          daughterboard -> bootinfo.board_id = RTX_BOARD_ID;
          daughterboard -> bootinfo.loader_start = daughterboard -> loader_start;
          daughterboard -> bootinfo.smp_loader_start = map[VE_SRAM];
          daughterboard -> bootinfo.smp_bootreg_addr = map[VE_SYSREGS] + 0x30;
          daughterboard -> bootinfo.gic_cpu_if_addr = daughterboard -> gic_cpu_if_addr;
          daughterboard -> bootinfo.modify_dtb = rtx_soc_modify_dtb;
          /* When booting Linux we should be in secure state if the CPU has one. */
          daughterboard -> bootinfo.secure_boot = vms -> secure;
          arm_load_kernel(ARM_CPU(first_cpu), machine, & daughterboard -> bootinfo);
        }

*  Configure and build QEMU at top directory to populate the build directory by *cmake*. 

  .. code-block:: console

        qemu-5.2.0/$./configure --target-list=arm-softmmu,arm-linux-user,aarch64-softmmu,aarch64-linux-user --prefix=/opt/qemu-5.2.0/
        qemu-5.2.0/$make && make install
        
More elements can be added as needed.*make install* to install the s/w binaries into the directory in */opt/qemu-5.2.0*. QEMU binary can also be run within *build/* directory. The successfully created platform would show up on the supported list of ARM machines (line 8),
	

  .. code-block:: console
        :linenos:

        qemu-5.2.0$ build/qemu-system-aarch64 -M help
        Supported machines are:
        akita                Sharp SL-C1000 (Akita) PDA (PXA270)
        ast2500-evb          Aspeed AST2500 EVB (ARM1176)
        ..
        realview-pbx-a9      ARM RealView Platform Baseboard Explore for Cortex-A9
        romulus-bmc          OpenPOWER Romulus BMC (ARM1176)
        rtx-r5               ARM Real Time Experiment (RTX) Cortex-r5f
        sabrelite            Freescale i.MX6 Quad SABRE Lite Board (Cortex A9)
        ..


Testing
=======

Once the built is complete and installed, I can use it to emulate the hardware platform to test my *FreeRTOS* port
for this RTX SoC. The *freertos-nga* is the ELF binary of the ported RTOS for this platform. Porting the *FreeRTOS* will be
in another post of this two parts series.

.. code-block:: console

        qemu-system-aarch64 -M rtx-r5 -m 2m -nographic -no-reboot -kernel build/freertos-nga 
        machine cpu_type cortex-r5f-arm-cpu
        UART base 0x58000000 created for serial0.
        main: Entering main(265)
        init_console, line 222
        current state: standby, last_state initialize
        Entering app_main(33686018), 3.141590
        nga> tasks
        Task Name       Status  Prio    HWM     Task Number
        app_main        X       1       323     3
        IDLE            R       0       478     6
        uart_rx_poll    B       1       471     4
        Tmr Svc         B       4       451     7       
        TX              B       2       472     2
        Rx              B       1       468     1
        regi_state_mon  B       2       335     5

        Timer ulCount   : 62
        nga>    

QEMU can be use along with GDB such as *arm-eabi-gdb* to debug the OS port. The *-s -S* options use for QEMU is to single step and connect 
to GDB, for example,

.. code-block:: console

        $ qemu-system-aarch64 -M rtx-r5 -m 2m -nographic -no-reboot -kernel build/freertos-nga -s -S 
        machine cpu_type cortex-r5f-arm-cpu
        UART base 0x58000000 created for serial0.

At this stage, QEMU is waiting for GDB connection. To connect, open another shell and start GDB,

.. code-block:: console

        $ arm-eabi-gdb build/freertos-nga 
        GNU gdb (GDB) 9.2
        Copyright (C) 2020 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-pc-linux-gnu --target=arm-eabi".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word"...
        Reading symbols from build/freertos-nga...
        (gdb) target remote :1234
        Remote debugging using :1234
        _freertos_vector_table () at /home/ssop/NGA/freertos-nga/platform/FreeRTOS_asm_vectors.S:82
        82              B         _boot
        (gdb) b main
        Breakpoint 1 at 0xd8c: file /home/ssop/NGA/freertos-nga/app/main.c, line 246.
        (gdb) c
        Continuing.

        Breakpoint 1, main () at /home/ssop/NGA/freertos-nga/app/main.c:246
        246             xQueue = xQueueCreate( mainQUEUE_LENGTH, sizeof( uint32_t ) );
        (gdb) 


Conclusion
==========

Without hardware available, I can use QEMU to emulate a virtual hardware with almost everything, CPU and peripherals that I need to get going for software development. For a faster Linux host, the clock cycles for slower ARM core frequency ~20MHZ -40MHZ is probably very close to the physical hardware although I did not take any measurement. QEMU is a powerful software tool and more than adequate for majority of software work such as board bring up and low-level firmware development. Its MMU support is very machine accurate. It can emulate PC to run the full blown OS such as Windows or Linux without problem. 

Citations
=========

.. [1] https://qemu.org QEMU portal 

.. [2] ARM Ltd, for all ARM Architecture.

