.. title: Custom FreeRTOS port for QEMU RTX
.. slug: freertos-port
.. date: 2021-11-21 13:20:03 UTC
.. tags: software
.. category: FreeRTOS
.. link: 
.. description: 
.. type: text

This is the second part that follows the porting QEMU for the Real-Time Experiment (RTX) ARM R5F core. This part addresses
the porting of FreeRTOS to run on the ported QEMU that I blogged earlier. For porting, I picked the latest
*FreeRTOS 10.4.1* at that time. It appears that the versioning of this RTOS has since changed since the later
part of 2020; however this released version is still available for downloading from its hosting site.

.. TEASER_END

Regardless of version of FreeRTOS used in the porting, you might still find some information to be useful to carry on
with your port into the latest version. The porting that I did was heavily inspired by the knowledge I learned while
using Xilinx ZynqMP and informations that I gathered from its Wiki pages. While Xilinx work was far more in complexity 
because of their hardware, mine was to make it simple for simple hardware, a stand-alone ARM R5F single core. 

After I finished my porting of QEMU then I realized, now what ? Nothing to run and nothing to prove whether or not my
porting of QEMU is working or not ! I just opened a can of worm that I needed to find the way to close it. This led me 
to finding the simplest, smallest RTOS to port. FreeRTOS appears to be very popular for being free and open source 
and several chip vendors are supporting this RTOS thus it became my primary candidate for porting so I downloaded 
and went through its code and see what I needed to do to get it going.

The essential FreeRTOS files 
============================

If you look at FreeRTOS code you will find a lot of things all over the place to the point of not knowing of what
to do with it. It happened to me. First I began examining its example of port for some platforms here and there to
get some picture primarily the ports of the ARM based platforms. I builded some *Demo* examples on how they are
built and what components they used for those ports. Since I used *GCC* toolchain that I already have installed from
Xilinx SDK, I focused on the demo that used this toolchain. 

Populating FreeRTOS files
-------------------------

I started by creating an empty directory *freertos-rtx* and populated this directory with a set of header files, and
from the demo examples, it appeared that all of the header files in the *Source/include* directory are needed. I 
populated my *freertos-rtx/include/freertos* by copying them over before making any modification. It looked like this,

.. code-block:: 

        freertos-rtx/
        ├── include
        │   ├── freertos
        │   │   ├── FreeRTOS.h
        │   │   ├── FreeRTOSConfig.h
        │   │   ├── StackMacros.h
        │   │   ├── atomic.h
        │   │   ├── croutine.h
        │   │   ├── deprecated_definitions.h
        │   │   ├── event_groups.h
        │   │   ├── list.h
        │   │   ├── message_buffer.h
        │   │   ├── mpu_prototypes.h
        │   │   ├── mpu_wrappers.h
        │   │   ├── portable.h
        │   │   ├── portmacro.h
        │   │   ├── projdefs.h
        │   │   ├── queue.h
        │   │   ├── semphr.h
        │   │   ├── stack_macros.h
        │   │   ├── stdint.readme
        │   │   ├── stream_buffer.h
        │   │   ├── task.h
        │   │   └── timers.h


The only file that I modified to suit my virtual hardware is *FreeRTOSConfig.h*. This modification was commonly 
done to all of the OS port. It is the FreeRTOS configuration file where you could add, subtract, modify specific
features that suit your hardware, for example, CPU clock frequency, tick rate, heap size, task features etc..  

So at this point, any headers that are FreeRTOS's are in *freertos-rtx/include/freertos* where I eventually 
populated with more header files specific to my device drivers or task applications. All of the header files
to be added can be at the top *include* directory so they wouldn't mix up with FreeRTOS's native files. This 
would help future porting to the later version easier by knowing where all the files came from.

Next was to bring in C source files of FreeRTOS into my *freertos-rtx*. I created *src* directory and copied all
of C files from *FreeRTOSv10.4.1/FreeRTOS/Source* into this directory. These are *timers.c, tasks.c etc..* which 
are common files to most of the ported platforms in the demo. There are three essential files to bring over as
well. These are *port.c, portASM.S, and portmacro.h*. This set of files is in its *Source/portable* and
I picked to best fit my need. For this port I picked the set in *portable/GCC/ARM_CA9*. Being portable implies
that they may be modified as suitable for my need, but I did not modify them at all ! I put *portmacro.h* 
into my *freertos-rtx/include/freertos* header files directory as you may have noticed.

I also picked one file *heap_3.c* from its *Source/portable/MemMang*. You might as well pick any *heap_x.c* file
that would fit well to your model regarding memory heap management. Since my model is a simple model so it 
could just use a simple heap management code.

In summary, so far I had

-  Basic C header files (\*.h) from *Source/include*
-  Basic C source files (\*.c) from *Source*
-  Basic C source files from *Source/portable*
       
My *freertos-rtx/src* source directory looked like this,

.. code-block::

        freertos-rtx/
        ├── src
        │   ├── ParTest.c
        │   ├── croutine.c
        │   ├── event_groups.c
        │   ├── heap_3.c
        │   ├── list.c
        │   ├── port.c
        │   ├── portASM.S
        │   ├── queue.c
        │   ├── stream_buffer.c
        │   ├── tasks.c
        │   └── timers.c

Populating platform files
-------------------------

From this point on it was getting more specific to platform so I created *freertos-rtx/platform* directory
to house the specific components. When a processor goes to reset or power-on, it has to fetch and execute
code from its boot vector table. A boot vector code from Xilinx Demo of its R5 core (RTOSDemo_R5) is the 
perfect code to use so I copied its *FreeRTOS_asm_vectors.S* to my *freertos-rtx/platform* directory where
I modified the interrupt handlers for debugging. You could pretty much use this file as-is. This is the only
file I made use from Xilinx R5 demo since my hardware model is different. The only similarity is the R5 core
so its CPU boot vectors are identical. This should be true for most implementation of R5 core. 

.. code-block:: c
   :linenos:

        ...
        .section .freertos_vectors
        _freertos_vector_table:
        	B	  _boot
        	B	  FreeRTOS_Undefined    
        	ldr   pc, _swi
        	B	  FreeRTOS_PrefetchAbortHandler
        	B	  FreeRTOS_DataAbortHandler
        	NOP	  /* Placeholder for address exception vector*/
        	LDR   PC, _irq
        	B	  FreeRTOS_FIQHandler

        _irq:   .word FreeRTOS_IRQ_Handler
        _swi:   .word FreeRTOS_SWI_Handler

        .align 4
        FreeRTOS_FIQHandler:
        ...


Since boot vector jump to *_boot* at reset/power-cycle, I need to have this function some where in the code so I cloned
one of Xilinx R5 demo *boot.S* and simplified it to my simpler model to become my *Init.qemu.S*. The *_boot* (line 4 below)
in this file was to set up stacks, initialized CPU mode, interrupt masks, invalidate caches, enable instruction cache,
enable FPU (if present). Mostly it is done by call to *arm_cpu_lowlevel_init* (line 10) followed by enabling cycle
counter, setting up data MMU and data cache, initializing GIC done by calling *_sysinit* (line 30) and finally jump to
to start of c-runtime, *_os_start* (line 32) that eventuall jum to main task. A snippet of this file, 

.. code-block:: c
        :linenos:

        ... 
        .globl _boot
        Reset_Handler :
        _boot:
        #------------------------------------------------------------------
        #@ 1 Initialize Registers & Vector Pointer
        #------------------------------------------------------------------
               	cpsid	aif
        	ldr	sp, .Lstack
        	bl	arm_cpu_lowlevel_init

        #------------------------------------------------------------------
        #@ 2 Initialize Stack Pointers
        #------------------------------------------------------------------

            #@  2.1 Initialize stack pointer registers
            # no stack for MODE_USR, MODE_MNT, MODE_HYP, MODE_SYS ?
            cps     MODE_FIQ                 @ change program state mode
            ldr     sp,  =__fiq_stack        @ set the stack pointer for this mode
            mov     lr,  #0                  @ clear the link register for this mode
            ...

        /* Reset and start Cycle Counter */
        	mov	r2, #0x80000000		/* clear overflow */
        	mcr	p15, 0, r2, c9, c12, 3
        	mov	r2, #0xd		/* D, C, E */
        	mcr	p15, 0, r2, c9, c12, 0
        	mov	r2, #0x80000000		/* enable cycle counter */
        	mcr	p15, 0, r2, c9, c12, 1
        	bl	_sysinit
            cpsie  aif    @ Enable asynchronous aborts, interrupts, and fast interrupts.
        	b	_os_start				/* jump to C startup code */
        	and	r0, r0, r0			/* no op */

The *_sys_init* set up two memory banks according to my h/w model starting at physical offset
zero(0). Each bank is 2MB of on-chip embedded memory eDRAM/eSRAM type for cachable data memory.
It also initialized timer *(sysctl_init)* needed for clock tick to support FreeRTOS and initialed (routed)
the interrupt to the GIC *(gic_init)*. Routing the timer tick to GIC is important because it 
is used by task switching of FreeRTOS. For my h/w platform model, I have the integrated timer 
and UART (PL010) so I need the interrupts for both of these devices. FreeRTOS is counting on
having proper timer tick interrupt for task switching among other things so it is essential
that the timer works correctly. A snippet of code,

.. code-block:: c
        :linenos:

         int _sysinit(void)
        {
        	unsigned long uval;
        
        	setup_mem_banks(); //setup the two mem banks
        	__mmu_init(get_cr() & CR_M); //set up MMU
        	uval = get_cpacr();
        	if ( uval & (1 << 31) ) {
        		set_cpacr(uval | (3 << 20) | (3 << 22));
        	}
            	//memtests(); //optional test after mmu enable to verify
        	sysctl_init(); //setup timer
        	 gic_init(0,
        		29,
        		IOMEM(0x58201000), //IOMEM(get_gicd_base_address()),
        		IOMEM(0x58202000) //either 2000 or 100 IOMEM(get_gicc_base_address())
        		 );
            	return 0;
        }

I put the set of files that are specific to my platform in *freertos-rtx/platform*. Their are
for initialization of the h/w platform components such as timer, MMU, GIC etc.. Here is what 
this tree looks like,

.. code-block::

        freertos-rtx/platform/
        ├── FreeRTOS_asm_vectors.S
        ├── FreeRTOS_tick_config.c
        ├── Init.qemu.S
        ├── cache-armv7.S
        ├── cache.c
        ├── gic.c
        ├── lowlevel.S
        ├── mmu.c
        ├── reent_init.c
        ├── sysinit.c
        └── vectors.c

The *_os_start* was to set up C-runtime code/data sections,stacks and heaps. It also initialized memory
array for the data variables of the program, for example, "int one23 = 123;" in your c-code ? It set up
this initialized memory location before it jump to *main()* so when your program read variable *one23*
it actually is 123. Again, you can find and reuse the CRT code in the demo example and make the
adjustment as needed to match the code and data sections of your port. Typically you would define them
in your linker script. I will leave the linker script later. A snippet of CRT code,

.. code-block:: c
        :linenos:

        .Lsbss_start:
        	.long	__sbss_start
                ...

        .Lstack:
        	.long	__stack
                ...
        
        	.weak	_os_start
        _os_start:

        /* Clear cp15 regs with unknown reset values */
        	mov	r0, #0x0
        	mcr	p15, 0, r0, c5, c0, 0	/* DFSR */
        	mcr	p15, 0, r0, c5, c0, 1	/* IFSR */
        	mcr	p15, 0, r0, c6, c0, 0	/* DFAR */
        	mcr	p15, 0, r0, c6, c0, 2	/* IFAR */

                ...

        .Lloop_bss:
        	cmp	r1,r2
        	bge	.Lenclbss		/* If no BSS, no clearing required */
        	str	r0, [r1], #4
        	b	.Lloop_bss
                ....
                
        .Lenclbss:

        	/* set stack pointer */
        	ldr	r13,.Lstack		/* stack address */
            /* Reset and start Global Timer */
        	mov	r0, #0x0
        	mov	r1, #0x0
                bl __libc_init_array

        	/* make sure argc and argv are valid */
        	mov	r0, #0
        	mov	r1, #0

        	/* Let her rip */
        	bl	main //off we go

At the bottom (line 42), it is where it branches to FreeRTOS's main task where it spawns more tasks. From this
point forward anything you want to do can be done in FreeRTOS.

For my port, I created *freertos-rtx/lib* and put the CRT code here along with C-runtime support functions such
as *read.c, write.c, exit.c, errno.c, open.c, sbrk.c, isatty.c etc..*. They are typical set of files needed
in most OS port. My *lib* files looks like this,

.. code-block::

        freertos-rtx/lib/
        ├── CMakeLists.txt
        ├── _exit.c
        ├── _sbrk.c
        ├── close.c
        ├── crt0.S
        ├── errno.c
        ├── fstat.c
        ├── isatty.c
        ├── lseek.c
        ├── open.c
        ├── read.c
        ├── usleep.c
        ├── util.c
        └── write.c

These files are mostly 10-20 lines of code, for example, *isatty(..)* is simply returned true since the UART
port is a TTY device and the *open(..)* is simply returned EOI since I do not have FS support. They are
functions to make the linking process happy. They are just the filler set of files and most of the 
functions are defined with *weak* attribute in such as a way that they can be overrided.

The application tasks
----------------------

At this point it is almost done. The remaining would be application specific so I added *app* and *driver*
as directories to house files for RTOS main task and UART device driver. UART device driver is the
only device driver I have for this port. I needed it to support TTY console so I can used for debugging
and command line interfacing with the RTOS. The *main()* is copied from demo example and modified for 
this port.

.. code-block:: c
        :linenos:

        void main( void )
        {
        	char buf[20];
        	int n;
        	/* Create the queue. */
        	xQueue = xQueueCreate( mainQUEUE_LENGTH, sizeof( uint32_t ) );
        	xQueue_mon = xQueueCreate( mainQUEUE_LENGTH, sizeof( uint32_t ) );
        	xUARTQueue = xQueueCreate( 1, sizeof(unsigned int) );
        	serial_port_driver_install((void *)0x58000000); //V2M_UART0);

        	vPortInstallFreeRTOSVectorTable();

        	vfs_dev_uart_register();

        	timer_handle = xTimerCreateStatic("timer",
        			300UL/portTICK_PERIOD_MS,
        			pdTRUE,
        			(void *)0,
        			prvTimerCallback,
        			&xTimerBuffer
        		    );
        	if ( timer_handle )
        		xTimerStart(timer_handle,0); //don't block
                if ( init_console() < 0  ) {
        	     printf("%s, aborted!\n",__FUNCTION__);
        	     return;
                }
        	if( xQueue != NULL )
        	{
        		xTaskCreate( prvQueueReceiveTask,	/* The function that implements the task. */
        					"Rx", 		/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        					configMINIMAL_STACK_SIZE, 	/* The size of the stack to allocate to the task. */
        					NULL, 				/* The parameter passed to the task - not used in this case. */
        					mainQUEUE_RECEIVE_TASK_PRIORITY, 	/* The priority assigned to the task. */
        					NULL );					/* The task handle is not required, so NULL is passed. */

        		xTaskCreate( prvQueueSendTask, "TX", configMINIMAL_STACK_SIZE, NULL, mainQUEUE_SEND_TASK_PRIORITY, NULL );

	                xTaskCreate( app_main, "app_main", configMINIMAL_STACK_SIZE, NULL, appmainTASK_PRIORITY, NULL );

        	        if ( xUARTQueue != NULL ) {
        	                xTaskCreate( prvUARTPollTask, "uart_rx_poll", configMINIMAL_STACK_SIZE, NULL, UART_RXQUEUE_TASK_PRIORITY, NULL );
        	        }
        	        if ( xQueue_mon != NULL ) {
        		        xTaskCreate( state_mon_task, "regi_state_mon", configMINIMAL_STACK_SIZE, NULL, mainQUEUE_SEND_TASK_PRIORITY, NULL );
        	        }

        		/* Start the tasks and timer running.*/
        		vTaskStartScheduler();
        	}

        	for( ;; );
        }


The main function is to install and set up UART driver, start RTOS timer, TX/RX UART tasks and console task and run RTOS scheduler. *app_main* is a 
TTY console task for command line interface as shown here, for example, when I typed *help* I would get the list of commands supported.
If I typed *tasks* I would get the information about tasks registered.

.. code-block:: 

        xxx@xxx:~/freertos-rtx$ ./run.sh 
        machine cpu_type cortex-r5f-arm-cpu
        UART base 0x58000000 created for serial0.
        main: Entering main(265)
        init_console, line 222
        current state: standby, last_state initialize
        Entering app_main(89), 0.000000
        rtx> tasks
        Task Name	Status	Prio	HWM	Task Number
        app_main       	X	1	333	3
        IDLE           	R	0	478	6
        Tmr Svc        	B	4	451	7
        TX             	B	2	472	2
        uart_rx_poll   	B	1	471	4
        Rx             	B	1	468	1
        regi_state_mon 	B	2	339	5
        
        Timer ulCount	: 35
        rtx> help
        help 
          Print the list of registered commands
        
        tasks 
          Get information about running tasks
        
        state 
          Get the current monitored state
        
        free 
          Get the total size of heap memory available
        
        read 
          read memory address
        
        next 
          read next memory address
        
        reboot 
          System reboot
        
        QEMU: Terminated

What I had in *app* and *drivers* are specific to the platform and OS usage. You would have what you need
to get what you want it to do for your application. 


.. code-block::

        freertos-rtx/
        ├── app
        │   ├── app_main.c
        │   ├── command.c
        │   ├── main.c
        │   ├── partest.h
        │   └── regi-state.c
        ├── drivers
        │   ├── serial_pl010.c
        │   └── serial_pl010.h

Don't forget about one important file, the linker script. Make sure you have the correct 
definition of code and data sections in it. You could as well use the linker script
in some of the demo example and modify it to fit your port. Look for file ending with
*\*.ld* in the demo, for example, the Xilinx's demo example linker script. Modify it
as needed to fit the sections of your code. It is what I did. Instead of writing
*Makefile* to build, I used *cmake* so I wrote *CMakeLists.txt* from top directory
to all of subdirectories that need to be compiled or assembled to create the 
bootable code. Here is the sample of my *CMakeLists.txt* file,

.. code-block:: 
        :linenos:

        cmake_minimum_required(VERSION 3.1)
        project(freertos-rtx)
        enable_language(C ASM)
        set(CMAKE_CROSSCOMPILING TRUE)
        set(TARGET armr5-none-eabi)
        set(TOOLCHAIN armr5-none-eabi)
        set(CMAKE_SYSTEM_PROCESSOR arm)
        set(CMAKE_C_COMPILER armr5-none-eabi-gcc)
        set(CMAKE_C_FLAGS "-mcpu=cortex-r5 -mfloat-abi=hard -mfpu=vfpv3-d16 -DFPU_PRESENT -DCONFIG_GICV2 \
        -DUART_BASE=0x58000000 -g " CACHE STRING "" FORCE)
        set(NGA_BOARD rtx-r5 CACHE INTERNAL "")
        set(LINKER_SCRIPT "${CMAKE_SOURCE_DIR}/linker.ld")
        set(ASM_OPTIONS "-x assembler-with-cpp")
        set(CMAKE_ASM_COMPILER armr5-none-eabi-gcc)
        set(CMAKE_ASM_FLAGS "${CFLAGS} ${CMAKE_C_FLAGS} ${ASM_OPTIONS}" CACHE INTERNAL "ASM Options")
        #set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -e 0x0 -Wl,-Map=freertos-rtx.map -nostdlib -T ${LINKER_SCRIPT}")
        #set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -e 0x0 -Wl,-Map=freertos-rtx.map -Wl,-rpath=${CMAKE_CURRENT_SOURCE_DIR}/lib -lextra -T ${LINKER_SCRIPT}")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -e 0x0 -Wl,-Map=freertos-rtx.map -T ${LINKER_SCRIPT}")
        Set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)
        set_target_properties(${TARGET_NAME} PROPERTIES LINK_DEPENDS ${LINKER_SCRIPT})
        include_directories("include" "include/freertos/" "include/asm" 
         "console/argtable3" "console/linenoise" "console" "vfs/include")
        file(GLOB SOURCES  "app/*.c" )
        add_subdirectory(drivers)
        add_subdirectory(console)
        add_subdirectory(lib)
        add_subdirectory(src)
        add_subdirectory(platform)
        add_subdirectory(vfs)
        #add_executable(freertos-rtx "app/main.c" ${SOURCES} ${COMPONENT_LIB_SRCS} ${COMPONENT_SRCS}) 
        add_executable(freertos-rtx  ${SOURCES} ${PLATFORM_SRCS} ${RTOS_SRCS} ${COMPONENT_LIB_SRCS} ${CONSOLE_SRCS} ${DRIVER_SRCS} ${VFS_SRCS})
        target_link_libraries(freertos-rtx 
        	PRIVATE 
        	"-Wl,--whole-archive"
        	console
        	platform
        	rtos    
        	extra	
        	drivers
        	vfs
        	"-Wl,--no-whole-archive")

There are other *CMakeLists.txt* files in nearly all of the subdirectories that contained C or S source files. *cmake* will create
*Makefile* to build the ARM executable code. 

.. code-block::

        mkdir build
        cd build
        cmake .. && make

is cmake building process. The binary executable, *freertos-rtx* and the compiled object files will
be in *freertos-rtx/build* directory that's built using *armr5-none-eabi* Xilinx toolchain. 

Debugging
----------

At the earliest stage of your port you are most likely need to debug some of your code so in terms
of debugging with QEMU, it was pretty much the way I blogged in my previous post on QEMU porting. 
You just start up QEMU in single step mode and single step it from reset vector all the
way to main function. Start QEMU in debugging mode in one shell. This will be *FreeRTOS* shell,

.. code-block::

        qemu-system-aarch64 -M rtx-r5  -m 2m -no-reboot -nographic -s  -S -kernel build/freertos-rtx

and open another shell to debug with *gdb* built for ARM version. I also used Xilinx's built
version of ARM R5 GDB.

.. code-block::

        xx@xx:~/freertos-rtx/build$ armr5-none-eabi-gdb freertos-rtx  
        GNU gdb (GDB) 8.3.1
        Copyright (C) 2019 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-oesdk-linux --target=arm-xilinx-eabi".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word"...
        Reading symbols from freertos-rtx...
        (gdb) target remote :1234
        Remote debugging using :1234
        _freertos_vector_table () at /home/ssop/freertos-rtx/platform/FreeRTOS_asm_vectors.S:82
        82              B         _boot
        (gdb) b _boot
        Breakpoint 1 at 0x2f848: file /home/ssop/freertos-rtx/platform/Init.qemu.S, line 75.
        (gdb) b _sysinit
        Breakpoint 2 at 0xecbc: file /home/ssop/freertos-rtx/platform/sysinit.c, line 311.
        (gdb) c
        Continuing.

        Breakpoint 1, _boot () at /home/ssop/freertos-rtx/platform/Init.qemu.S:75
        75              cpsid   aif
        (gdb) c
        Continuing.

        Breakpoint 2, _sysinit () at /home/ssop/freertos-rtx/platform/sysinit.c:311
        311             setup_mem_banks();
        (gdb) 

       
Here I set two break point, one at *_boot* reset vector and one at *_sysinit*. You can single
step your code this way during your debugging. There are many GUI GDB front end debuggers that
you could use as well if you prefer.

Conclusion
===========

Most work in this porting is primarily getting the code execution from reset vector 
to main program ie.. boot loader code. Little of it involved modifying FreeRTOS code
other than its configuration file(s) that is specifically platform dependent.
Find what you need in the demo examples and make use of it. The best place to look 
for the very low-level assembly code is to look in some boot code such as U-Boot
or Barebox among others. It will save you a lot of time by using the proven code, 
modify as needed. Try to understand what it does and why it does so you will know 
if you could make use of it for your port. The most time I spent on porting this
FreeRTOS is on debugging the interrupt routing to GIC because of what I thought 
I knew, but I didn't. If there is no timer tick, the tasks would never get scheduled 
and switched. It would stuck in main and going no where. I eventually got it
right. 

The majority of code I had for this port came from various sources
and I modified to fit my need. I do not like to reinvent the wheel and you
shouldn't too. Although I tested my port on QEMU, I have 99% confident that it
too would run on real h/w. QEMU is quite powerful and very useful for this
type of prototyping work. 
