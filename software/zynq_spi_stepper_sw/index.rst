.. title: Zynq SPI slave stepper motor driver
.. slug: zynq_spi_stepper_sw
.. date: 2016-11-17 00:40:47 UTC
.. tags: software
.. category: Linux
.. link: 
.. description: Linux device driver for zynq SPI slave stepper motor
.. type: text

The Linux SPI slave device driver is to enable user access to SPI slave stepper motor FPGA design in my other post 
`<http://souktha.github.io/hardware/zybo-spi-stepper>`_ . This is the software part of that implementation on the Zybo Zynq7000.
I reuse the original SPI slave I wrote earlier and expand its functionality a little bit more so that I can send 
the step count to the stepper motor.

.. TEASER_END

SPI slave driver implementation
================================

I try to make it as simple as possible so that writing and reading the SPI interface does not require to have any
application be written for it. I choose to use the *proc* file system as the access mechanism since it will work
out well with just shell script.

All that is needed for this task is adding *proc* file system to the driver and provide the entry points where
the step count can be written and where the status can be read. My interface will have  */proc/stepper/steps* for
writing step counts and */proc/stepper/status* for reading the status of the motor.

In summary, for this design:

* Add *proc FS* for user acess to the driver to allow writing of step count and reading stepper status.

  - Add *proc* file write handler for writing stepper count.

  - Add *proc* file read handler for reading stepper status.

.. code-block:: C
        :linenos:

        ..

        //adding proc directory and proc entries 

	if (!(stepper_procdir_entry = proc_mkdir("stepper",NULL)))
		goto exit_free_data;
	
	spi5a->proc_entry = stepper_procdir_entry;
	if (!(entry = proc_create_data("steps",
				S_IFREG | S_IRUGO | S_IWUSR,
				spi5a->proc_entry,
				&proc_stepper_fops,
				NULL)) ) {

		goto exit_free_data;
	}
	if (!(entry = proc_create_data("status",
				S_IFREG | S_IRUGO | S_IWUSR,
				spi5a->proc_entry,
				&proc_stepper_status_fops,
				NULL)) ) {

		remove_proc_entry("steps",spi5a->proc_entry);
		goto exit_free_data;
	}

        ..

On handling the step count write operation, the proc write handler takes the step count input from user
and send it out to Zynq SPI master (PS) to the SPI slave stepper hardware (PL).

.. code-block:: C
   :linenos:

        ...
        ..
	if ( copy_from_user((void * )&sbuf,buf,cnt) ) {
		up(&priv->sem);
		return -EFAULT;
	}
	priv->spidev->bits_per_word = 8;
	priv->spidev->mode = SPI_MODE_0;
    	spi_setup(priv->spidev);

	byte  =  (char )simple_strtol(sbuf,NULL,0);
		sbuf[0] = STEPPER_WRITE_COUNT;
		sbuf[1] = byte;
		ret = spi_write(priv->spidev,sbuf,2); //send write command and data


	return cnt;
        }

I use Linux sequential file as an interface for reading the status of the stepper motor operation. This is to 
capitalize on the existing *proc* file interface.

.. code-block:: c
        :linenos:

        ...
        
        static int stepper_status_show(struct seq_file * seq_file, void * arg)
        {
        	u8 ret;
        	struct spi5a_dev \*priv  = (struct spi5a_dev * )seq_file->private;
        
        	priv->spidev->bits_per_word = 8;
        	priv->spidev->mode = SPI_MODE_0;
            	spi_setup(priv->spidev);

        	ret = spi_w8r8(priv->spidev, STEPPER_READ_STAT);
        	seq_printf(seq_file,"0x%x\n",ret); //read 
        	return 0;
        }
        ...


        struct file_operations proc_stepper_status_fops = {
	        .owner = THIS_MODULE,
        	.open = proc_stepper_status_open,
        	.read = seq_read,
        	.llseek = seq_lseek,
        	.release = single_release,
        };


Testing the design with the SPI slave driver
============================================

The SPI slave device has to brought in to existence first before loading the SPI slave driver. This is simply done using
*cat* the bitstream to Xilinx PL configuration device (line 1). Once the FPGA bitstrem is loaded to the Zynq, the 
SPI slave can be loaded (line 2). On loading of the SPI slave driver, the Zynq SPI master probes the SPI device 
attached to SPI0 using the *read id (0x1d)* command. My SPI slave FPGA responds to the read ID command with its ID,
*0xa5*. This is indicated that the device that SPI slave is written for existed. Once the SPI slave stepper motor 
driver is detected, the *proc/stepper* file is then created and become accessible to user. 
This is when the step count and status can be read. Positive step count is for stepping in forward direction while the negative 
count is for the opposite direction. The step count is 8bit signed integer. The motor status for *running* or *idle* is returned 
in the LSB of the *read status (0xea)* command.
        
    .. code-block:: 
        :linenos:

        # cat design_3_wrapper.bit >/dev/xdevcfg 
        # insmod spi5a.ko 
        spi max speed HZ: 1000000
        spi read ID for cs 0, mode 0, bpw 8
        Detected SPI Stepper ID 0x5a
        spi5a_probe read(ea) returns 0xc4
        # cat /proc/stepper/status 
        0xc4
        # echo '0x44'>/proc/stepper/steps && cat /proc/stepper/status 
        proc_stepcount_write: sbuf dd9b5e50, wrote step count 0x44, status 0 
        0xc5
        # 

Conclusion
============

This simple exercise instantiates the SPI slave device on the programmable logic side of the Zynq7000 having the Linux
SPI slave driver works in conjunction with that design. It is complete hardware and software interface for the simple
SPI slave stepper motor driver.
