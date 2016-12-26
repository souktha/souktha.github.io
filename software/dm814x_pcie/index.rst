.. title: Adding PCIe support and bring up the boot splash screen to DM814x U-Boot 
.. slug: dm814x_pcie
.. date: 2016-06-11 22:18:26 UTC
.. tags: software
.. category: U-Boot
.. link: 
.. description: PCIe support and splash screen for DM814x U-Boot
.. type: text

It is desirable to have some visual feedback to user during system boot up process especially if the system takes more
than few seconds to boot. For the Linux based set-top box that boot to the main GUI menu may take considerable 
amount of time depending on the number of processes it needs to start. Some system may need to program the FPGA bitmask, 
bring up the networking processes or bring up some externally connected devices. These steps add up to the total system boot up 
time. For system with video support, it is a good practice to have video up as soon as possible so that the user 
would know that the system is working and it is in the process of booting up the system. This is commonly known as 
putting the boot splash screen during boot process.

.. TEASER_END

The TI8148 has the integrated PCIe support in it. The TI OMAP DM814x/AM287x evaluation platform (TI8148 EVM) also comes 
with one PCIe connnector where the HBA can be attached; however, the TI's official released *u-boot-2010.06-psp04.00.01* 
does not have PCIe support enable. The board that I am using for this demonstration is the derivation of TI EVM board 
having a proprietary PCIe based video processor chips built in to the system. The video processor chip is capable of 
processing 4K-3D video. It has two HDMI ports and it has the built-in video/audio processing unit. This post is not
about the integrated HDVPSS.

In order to put the splash screen at u-boot level, I have to do these things,

* Initialize PCIe PLL clocks subsytem.
* Initialize PCIe RC (Root Complex).
* Initialize the video processor HDMI subsystem.
* Put up the splash screen with logo and status bar.


Initialize the PCIe PLL
-----------------------

In reference to  *u-boot-2010.06-psp04.04.00.01* of EZSDK, the file *board/ti/ti8148/evm.c* has function *pcie_pll_config()* disable (commented out). It is understandable that the original author exercised the practice of not leaving free-running clock enable if no device
was using it. Since I will be using it, this function need to be enable to configure PCIE's PLL clock in the control module 
(section 3 and 19.2.1 of [1_]). The registers to be configured are PLLCFG0 to PLLCFG4 of the PCIe control 
module (base offset is 4814_0000). I made some minor change for the board I am using, enabling MEAS
and enabling latch (50%).

.. code-block:: c

        static void pcie_pll_config()
        {
                ..
	        __raw_writel(0x70007017, PCIE_PLLCFG0); //per 19.3.1.1.1 sprugz8b.pdf manual.
        	/*wait for ADPLL lock*/
	        ..
        }

at the end of *pcie_pll_config()*, wait for PLL to phase-lock by polling PLLSTATUS bit 1. Also a call to the function should
be made in *prcm_init()*. This portion of code is only to 
configure PLL, feeding clock to the PCIe subsytem. It is the first step to be done before configuring/enumeratating 
the PCIe device. This PCIe PLL configuration must be done before the complete powerup sequence before the clock module 
is locked out so it is made as part of SBL ie.. (min_config).

Initialize PCIe Root Complex
----------------------------

The PCIe configuration registers of this OMAP SoC start at 5100_0000. The PCIe module is based on Synopsis Designware 
Core (DWC) and TI SERDES PHY. It can 
operate in either endpoint (EP) or root complex (RC). The mode to be initialized for this purpose is RC mode. To do this
is to set RC mode(2) for PCIE_CFG(480h) of the control module, bring PCIe out of reset sequence and enable PCIe clock (
*CM_DEFAULT_PCI_CLKCTRL*, section 2.10.7 of [1_]). Once the PCIe is out of stand-by mode, the PCIe link can be trained or
set-up. Because the PCIe module of this SoC is single lane (x1), the PCIe is configured for x1 before link training
is initiated. When link training is completed, the PCIe is configured as bridge device with outbound transaction
set for base address 2000_0000 (refers to 2.12.1 of [4_]). Some part of the code,

.. code-block:: c
 :linenos:

        /*Various regions in PCIESS address space, sprugz8d document section 19.2.4.1, fig 19.2*/
        ..
        #define SPACE0_LOCAL_CFG_OFFSET		0x1000	/*local config space*/
        #define SPACE0_REMOTE_CFG_OFFSET	0x2000  /*remote config space*/
        #define SPACE0_IO_OFFSET		0x3000	/*remote device IO space*/
        #define PCIE_CONFIG_BASE		0x51000000
        ..
        ..
        static void set_outbound_trans(u32 start, u32 end)
        {
	int i, tr_size;

	/*Set outbound translation size per window division*/
	__raw_writel(CFG_PCIM_WIN_SZ_IDX & 0x7, reg_virt + OB_SIZE);

	tr_size = (1 << (CFG_PCIM_WIN_SZ_IDX & 0x7)) * SZ_1M;

	/*Direct 1:1 mapping of RC <-> PCI memory space*/
	for (i = 0; (i < CFG_PCIM_WIN_CNT) && (start < end); i++) {
		__raw_writel(start | 1, reg_virt + OB_OFFSET_INDEX(i));
		__raw_writel(0,	reg_virt + OB_OFFSET_HI(i));
		start += tr_size;
	}

	/*Enable OB translation*/
	 __raw_writel(OB_XLAT_EN_VAL | __raw_readl(reg_virt + CMD_STATUS),
			 reg_virt + CMD_STATUS);
        }

        ..

        static void set_inbound_trans(void)
        {
	/*Configure and set up BAR0*/
	set_dbi_mode();

	/*Enable BAR0*/
	__raw_writel(1, reg_virt + SPACE0_LOCAL_CFG_OFFSET +
			PCI_BASE_ADDRESS_0);

	__raw_writel(SZ_4K - 1, reg_virt +
			SPACE0_LOCAL_CFG_OFFSET + PCI_BASE_ADDRESS_0);

	clear_dbi_mode();

	__raw_writel(reg_phys, reg_virt + SPACE0_LOCAL_CFG_OFFSET
				+ PCI_BASE_ADDRESS_0);

	/*Configure BAR1 only if inbound window is specified*/
	if (ram_base != ram_end) {
		__raw_writel(ram_base, reg_virt + IB_START0_LO);
		__raw_writel(0, reg_virt + IB_START0_HI);
		__raw_writel(1, reg_virt + IB_BAR0);
		__raw_writel(ram_base, reg_virt + IB_OFFSET0);

		set_dbi_mode();

		__raw_writel(1, reg_virt + SPACE0_LOCAL_CFG_OFFSET +
				PCI_BASE_ADDRESS_1);

		__raw_writel(ram_end - ram_base, reg_virt +
			SPACE0_LOCAL_CFG_OFFSET + PCI_BASE_ADDRESS_1);

		clear_dbi_mode();

		/*Set BAR1 attributes and value in config space*/
		__raw_writel(ram_base | PCI_BASE_ADDRESS_MEM_PREFETCH,
				reg_virt + SPACE0_LOCAL_CFG_OFFSET
				+ PCI_BASE_ADDRESS_1);

		__raw_writel(IB_XLAT_EN_VAL | __raw_readl(reg_virt +
					CMD_STATUS), reg_virt + CMD_STATUS);
	        }
        }


        static void omap_pcie_setup(void)
        {

          u32 val;

	__raw_writel(2, CTRL_BASE + 0x480); /*RC mode*/
	/*bring PCIE out of reset sequence (PRM_DEFAULT)*/
	__raw_writel( __raw_readl(PRCM_BASE+0xb10) | 0x80,PRCM_BASE+0xb10);
	udelay(10);
	__raw_writel( __raw_readl(PRCM_BASE+0xb10) & ~0x80,PRCM_BASE+0xb10);
	delay(3);
	__raw_writel(__raw_readl(PRCM_BASE+0xb14) & 0x80,PRCM_BASE+0xb14); //clear this bit
	delay(3);
	/*enable PCIE clock (CM_DEFAULT)*/
	__raw_writel(0,PRCM_BASE+0x578);
	udelay(10);

	__raw_writel(2,PRCM_BASE+0x510);
	__raw_writel(2,PRCM_BASE+0x578);
	while ( __raw_readl(PRCM_BASE+0x578) & 0x70000 )delay(3);
	__raw_writel(DIR_SPD | __raw_readl(
				reg_virt + SPACE0_LOCAL_CFG_OFFSET + PL_GEN2),
			reg_virt + SPACE0_LOCAL_CFG_OFFSET + PL_GEN2);

        /*set x1*/
	val = __raw_readl(reg_virt + SPACE0_LOCAL_CFG_OFFSET +
			LINK_CAP); 
	val = (val & ~(0x3f << 4)) | (1 << 4);
	__raw_writel(val, reg_virt + SPACE0_LOCAL_CFG_OFFSET +
			LINK_CAP); /*not to confuse, this is PCIESS local config reg, not PCIe config reg which is RO*/

	val = __raw_readl(reg_virt + SPACE0_LOCAL_CFG_OFFSET + PL_GEN2);
	val = (val & ~(0xff << 8)) | (1 << 8);
	__raw_writel(val, reg_virt + SPACE0_LOCAL_CFG_OFFSET + PL_GEN2);

	val = __raw_readl(reg_virt + SPACE0_LOCAL_CFG_OFFSET +
			PL_LINK_CTRL);
	val = (val & ~(0x3F << 16)) | (1 << 16);
	__raw_writel(val, reg_virt + SPACE0_LOCAL_CFG_OFFSET +
				PL_LINK_CTRL);

	/*Initiate Link Trainin*/
	 __raw_writel(LTSSM_EN_VAL | __raw_readl(reg_virt + CMD_STATUS),
			 reg_virt + CMD_STATUS);

	udelay(100000);
	/*set up as bridge*/

	__raw_writew(PCI_CLASS_BRIDGE_PCI,
			reg_virt + SPACE0_LOCAL_CFG_OFFSET + PCI_CLASS_DEVICE);

	disable_bars(); //for now

	set_outbound_trans(0x20000000, 0x30000000-1); //non-prefetch mem area

	/*Enable 32-bit IO addressing support*/
	__raw_writew(PCI_IO_RANGE_TYPE_32 | (PCI_IO_RANGE_TYPE_32 << 8),
			reg_virt + SPACE0_LOCAL_CFG_OFFSET + PCI_IO_BASE);

	/*not plan to use interrupt*/
	__raw_writel(0xf, reg_virt + IRQ_ENABLE_CLR); //not enable irq

	/*skip MSI interrupt chain setup*/

	get_and_clear_err();
        }
        ..

        
The mapped BAR, 2000_0000 is the 256MB address space set aside for PCIe device's use [4_]. 
This is corresponded to the  address of the downstream PCIe video chip. Accessing this address space after the mapping is to access the video processor chip (below snippet). For system with more than one PCIe devices, extra code for buses enumeration is needed. Shown here is for the simplest case, single PCIe device [6_].

The next step is to set up the PCI header structure of u-boot so that it can be accessible by its drivers and utility. This 
includes registering PCI device, its respective read/write configuration space handlers etc..
Post enumeration is to set up the inbound transaction address space which is the local system memory space of the system.

.. code-block:: c
 :linenos:

        static struct pci_config_table pci_redray_config_table[] = {
        /*104c,8888 - TI host bridge*/
        	{0x104c, 0x8888, PCI_CLASS_BRIDGE_HOST,
        	 PCI_ANY_ID, PCI_ANY_ID, PCI_ANY_ID, pci_setup_ti_bridge},
	        {0x..., 0x..., 0x11, /*note: omit proprieatary info here*/
        	 PCI_ANY_ID, PCI_ANY_ID, PCI_ANY_ID, pci_setup_vp}, /*pci_setup_vp is to set up this proprietary video processor chip*/

	{ }
        };
        ..

        struct pci_controller hose = {
	        config_table: pci_vp_config_table,
        };

        ..

        void omap_pci_init(struct pci_controller* hose)
        {
	unsigned int val,offset;
	pci_dev_t dev;	

	omap_pcie_setup();//as shown above
        
	hose->first_busno = 0;
	hose->last_busno = 0x1f;

	/*memory space*/
	pci_set_region (&hose->regions[0],
			0x20000000,
			0, 0x1900000, PCI_REGION_MEM);
	hose->pci_mem = &hose->regions[0];

	/*PCI memory space*/
	pci_set_region (&hose->regions[1],
			0x20b00000,
			0, 0x100000, PCI_REGION_PREFETCH);
	hose->pci_prefetch = &hose->regions[1];
	hose->pci_io = NULL;

	/*PCI I/O space*/

	hose->region_count = 2;

	pci_register_hose (hose);
	pci_set_ops(hose,
		    pci_hose_read_config_byte_via_dword,
		    pci_hose_read_config_word_via_dword,
		    ti81xx_pci_read_config,
		    pci_hose_write_config_byte_via_dword,
		    pci_hose_write_config_word_via_dword,
		    ti81xx_pci_write_config ); 

	pciauto_config_init(hose);
	hose->current_busno = hose->first_busno+1;
	dev = PCI_BDF(hose->first_busno,0,0);
	pciauto_prescan_setup_bridge(hose,dev,hose->current_busno);
	pciauto_setup_device(hose,dev,0,hose->pci_mem,hose->pci_prefetch,hose->pci_io);
	hose->last_busno = pci_hose_scan(hose);
	hose->last_busno = hose->current_busno;

	/*fix up*/
	__raw_writel(0x20800000,reg_virt + SPACE0_REMOTE_CFG_OFFSET + PCI_BASE_ADDRESS_0);
	__raw_writel(0x20000000,reg_virt + SPACE0_REMOTE_CFG_OFFSET + PCI_BASE_ADDRESS_1);
	__raw_writel(0x010130,  reg_virt + SPACE0_REMOTE_CFG_OFFSET + PCI_INTERRUPT_LINE);
	__raw_writel(0x100546,  reg_virt + SPACE0_REMOTE_CFG_OFFSET + PCI_COMMAND);

	/*fix up max read request*/
	offset =  __raw_readl(reg_virt + SPACE0_REMOTE_CFG_OFFSET + PCI_CAPABILITY_LIST);
	val =  __raw_readl(reg_virt + SPACE0_REMOTE_CFG_OFFSET + offset + 8);
	val = (val & ~(3 << 12)) | (1 << 12); /*max read requst mask is 256bytes/read*/
	__raw_writel(val,  reg_virt + SPACE0_REMOTE_CFG_OFFSET + offset + 8 );

	__raw_writel(0x100147,  reg_virt + SPACE0_REMOTE_CFG_OFFSET + PCI_COMMAND);
	__raw_writel(0x100147,  reg_virt + SPACE0_LOCAL_CFG_OFFSET + PCI_COMMAND);

	ram_base = 0x80000000;
	ram_end = ram_base + 0x7fffffff;
	/*Post enumeration fixups*/
	set_inbound_trans();
	__raw_writew(__raw_readw(reg_virt + SPACE0_LOCAL_CFG_OFFSET +
				PCI_IO_BASE) | PCI_IO_RANGE_TYPE_32 |
				(PCI_IO_RANGE_TYPE_32 << 8),
				reg_virt + SPACE0_LOCAL_CFG_OFFSET +
				PCI_IO_BASE);

        }

When all is done with PCIe device configuration, the device's PCIe memory mapped address space can be dumped with 
u-boot's *md* command. Sample below is the content of the video processor control registers area.

.. code-block:: console

        TI-MIN#md 20000000 
        20000000: 00000000 00000000 00000000 00000000    ................
        20000010: 00000000 00000000 00000000 00000000    ................
        20000020: 00000000 00000000 00000000 00000000    ................
        20000030: 00000000 00000000 00000000 00000035    ............5...
        20000040: 000003e7 0000000e 0000000f 00000000    ................
        20000050: 00000000 00000011 00000035 000003e7    ........5.......
        20000060: 0000000e 0000000f 00000000 00000000    ................

TI document section 19.3.1 [1_] describes all the necessary steps needed to set up the RC mode for this module. Initialization of PCIESS for 
the boot code or the high level kernel OS takes the exact same steps. In fact, I ported part of the code from the linux kernel originally
done by TI [3_] in *linux-2.6,37-psp04.04.00.01/mach-omap2/pcie-ti81xx.c*. 
        
Initialize the video processor's HDMI subsystem
-----------------------------------------------

From this point onward, the PCIe video processor is accessible by u-boot. The proprietary video processor used 
in this derived platform has external DDR3 video display memory that need to be configured. The first step in this
process is to set up its PLL clocks subsystem and set up its DDR3 memory controller (DDR training). Video PLL clock and audio
PLL clock are set up as part of this initialization. Following this step, the EDID is read from the connected
display device (monitor/tv) so that it can setup the HDMI interface correctly. My board's HDMI is connected to ASUS
LCD monitor.

.. code-block:: console
 :linenos:

        U-Boot 2010.06 (Jul 02 2016 - 17:35:59)

        TI8148-GP rev 2.1

        ARM clk: 720MHz
        DDR clk: 533MHz

        I2C:   ready
        DRAM:  2 GiB
        NAND:  HW ECC BCH8 Selected
        256 MiB
        
        ..

        DDR trained (0x80000fff).

	Pixel clocks  :148500 KHZ
	Horizontal pix:1920
	Vertical   pix:1080
	Display size H:598 mm
	Display size V:592 mm
        Display Name     : VS278
        Display serial no: D1LMQS148212

        MMC:   OMAP SD/MMC: 0
        Net:   Detected MACID:2c:b6:9d:d0:d1:d2
        cpsw
        Hit any key to stop autoboot:  1

        
The information from EDID is used for configuring the HDMI [5_] to match the capability of the display unit (TV/monitor) so that 
the splash screen will be properly centered. The gamma LUT, chroma scaler, dithering frame dimension, info frame, color space
etc.. for the video pipe and the HDMI component of the video processor are then initialized accordingly.

Put up splash screen logo
--------------------------

The final step is to load the video pixels of the splash screen. One is static logo image and one is the progressive
status bar. The logo image that is compiled along u-boot code (~100k) is then DMAed by the video processor to its 
layered output display memory buffer, the main display buffer. The overlay progressive status bar is output in the
same way, but to its OSD display buffer and having its progress status update mechanism hooks up to the timer tick 
in order to update the progress bar. This part of putting the splash screen is the proprietary part that I cannot 
include any snippet due to NDA.

.. figure::        ../../images/misc/splash-screen.jpg
      
        Splash screen with a progressing status bar (company logo blocked out).

Conclusion
-----------

It takes a little bit of effort to get this done, coding and debugging, but some lessons are learned during the 
process.

Citations
=========

.. [1] TMS320DM814x Davinci Digital Video Processor Technical Reference Manual, SPRUGZ8D, Revised April 2013.

.. [2] arm-2009q1-203-arm-none-linux-gnueabi.bin, TI cross toolchain.

.. [3] LINUXEZSDK-DAVINCI: Linux EZ Software Development Kit (EZSDK) for DM814x and DM816x- ALPHA,ezsdk_dm814x-evm_5_05_01_04_setuplinux, www.ti.com/tool/linuxezsdk-davinci, v5.05.01.04-ALPHA, 10 OCt, 2012.

.. [4] TMS320DM8148, TMS320DM8148, TMS320DM8146, SPRS647D-MARCH 2011-REVISED SEPTEMBER 2012.

.. [5] High Definition Multimedia Interface, Specification Version 1.3a, November 10, 2006

.. [6] PCI Express System Architecture, MindShare Inc, Addison Wesley, ISBN: 0-321-15630-7, September 04, 2003.

