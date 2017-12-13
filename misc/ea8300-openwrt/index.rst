.. title: OpenWRT (Chaos Calmer) on Linksys EA8300
.. slug: ea8300-openwrt
.. date: 2017-11-17 22:15:05 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text


This blog is about installing the OpenWRT firmware into Linksys EA8300 Max-Stream AC200 Tri-Band Wi-Fi router. The firmware is 
a customized version of OpenWRT Chaos Calmer for this platform. It serves as an alternative to the proprietary
firmware where one can further customizes it as needed.

.. TEASER_END

Linksys EA8300 Max-Stream AC200 Tri-Band Wi-Fi router
========================================================

Linksys EA8300 main features summary:

* Qualcomm Atheros IPQ4019 Quad-Core ARM based SoC.
  
* 256MB NAND storage, 256MB DRAM

* Concurrent tri-band 2.4Ghz MIMO 2x2 (802.11ng), 2-5Ghz MIMO 2x2 (802.11ac) 

* 4x1Gb LAN ports, 1 Gb WAN port, 1 USB2 port.

Software
----------

There are two sets of factory installed kernel+rootfs on EA8300.
These two sets of kernel+rootfs enable it to recover in case something goes wrong during the 
firmware upgrade or even during the normal operation.

The OpenWRT firmware is to be installed (replaced) one of these sets. Once the installation is completed (takes < 30s)
the router will reboot to the newly installed OpenWRT firmware. How does anybody know which set of firmware
the router is running ? You don't and neither do I ! Linksys router's WebUI f/w update process will
pick the set of partitions on which the new firmware is to be installed for you.

What you don't need
--------------------

You don't need to physically hack the router box by putting the serial console port into it. The OpenWRT installation
will be done through Linksys's firmware update procedure via its Web UI, no special tool is required.


what you need
-------------

* Download the customized version of OpenWRT firmware from my git hub repository `link here`_. This is an OpenWRT Chaos Calmer for EA8300.

.. _link here: http://github.com/souktha/OpenWRT_EA8300

OpenWRT installation        
====================

Of course, the liability clause,

**Everything that you do from this point on is at your own risk whether you brick it or void its
warranty ! If you are not willing to take some risk to experiment or if you are not sure then stop.**

Base on the assumption that the EA8300 is running the manufacturer's firmware (Linksys). It does not 
matter what version of Linksys firmware it is running. To install,

- Login to the router that is currently running Linksys firmware via its Web UI with the web browser (Chrome/firefox etc).

- Click on *connectivity* on the left panel below *Router Settings*. The *connectivity* will show up. On the right pane, there is 
  *Router Firmware Update*. Under it, there is *Manual* box. Select *Choose File* where you can pick the file you downloaded
  from my git repository. This is the file to flash into the router.

- After choosing file (LINKSYS_EA8300-openwrt.img), choose *start* to program the flash. Flashing will be on the partitions
  that is not the current set of root file system (Linksys). It will be automatically chosen for you. The OpenWRT image
  contains both kernel and rootfs so everything is OpenWRT.

- Click *yes* to continue on *Important* pop-up warning message.

- Firmware updating process will take place and the EA8300 router will reboot. This process should take less than 30s.
  Click *ok* when pop-up message tells you that it is rebooting (to new OpenWRT firmware).


Configuring the OpenWRT
=======================

Linksys firmware will switch to the new set of partition upon completion of f/w update process. The router is now running the 
OpenWRT once rebooted. At this stage, there are two sets of firmware in the router. One is OpenWRT (currently running) while the other is
Linksys f/w. To switch back and forth between these two sets is by changing its boot environment variables. I will cover it
later, but first thing first,

How to configure OpenWRT
------------------------

This image of OpenWRT is pre-configured with WiFi's SSIDs as 'OpenWrt_EA8300' for 11ng and 
'OpenWrt_EA8300_5g' for 11ac and they should be up. Its encryption is set to *none*, meaning it is open-access. 
Also it has no root password. To connect to OpenWRT WiFi AP,

1. Use your host PC to connect to one of its SSID. Suppose that your host is Linux PC, you can use *wpa_supplicant*
to connect to it. This *wpa_supplicant.conf* would be sufficient for you (refer to *wpa_supplicant*),

.. code-block::

        ctrl_interface=/var/run/wpa_supplicant
        ctrl_interface_group=root
        network={
        ssid="OpenWrt_EA8300"
        scan_ssid=1
        key_mgmt=NONE
        }

      
2. Connect your host to it via WiFi access and use this access to configure the EA8300 openwrt (telnet/webUI). You may
connect to the router via *dhcp* or by static IP. Since the default LAN IP address is *192.168.2.1* for this
firmware, you can just *ifconfig wlan0 192.168.2.3 up* to bring up your host Wi-Fi interface then *telnet 192.168.2.1* to
the router. It should get you the OpenWrt prompt. You cannot *ssh* just yet, not until you configure root password.
You can also access its WebUI by *http://192.168.2.1* if you prefer.

Minimum configuration
---------------------

After you connect to *OpenWrt_EA8300xx* AP by telnet to it.  As mentioned, its initial AP's address is set to *192.168.2.1*.
From here on you can configure the AP via command line (telnet or webUI), but first thing first,

#.      You need to edit */etc/config/wireless* to set the SSID you need, its encryption and pass phrase. You also need to change *macaddr* to
        fit your Linksys's assigned MAC addresses. The MAC address for your router is printed on the same side of box where UPC code is located. It
        probably be some thing like *1491xxx*. Assign this MAC address to LAN, increment by one for each Wi-Fi MAC addresses. 
        For LAN/Bridge configuration, you need to edit */etc/config/network* to set your local
        network IP address if you need to. You can also close the WAN port that I opened in */etc/config/firewall*. These are the 
        minimum configurations that you need to do because what's in this image is generic and without security. Refer to OpenWRT on
        configuring the network and its security. MAC addresses must be unique for your router so you **must** change them.

#.      Check to make sure that */etc/fw_env.config* has the correct configuration for this platform. It should have only one line in it.

.. code-block::

        /dev/mtd7 0 0x40000 0x20000

That is to say that mtd7 is the u-boot environment block. This is where you need to access in order to switch booting between the 
Linksys firmware and the OpenWRT firmware. This will be useful later. The command *fw_printenv* will list the u-boot settings 
correctly if its *fw_env.config* file is correct.

#.      You need to use Linksys EA8300's factory radio calibration data that fits your regulatory domain. To do that you
        need to figure out what partition the OpenWRT firmware was flashed into. For this step, *fw_printenv*  will show you what
        variable *bootpart* and *boot_part_ready* is set to. *boot_part* indicates currently boot partition set (kernel+rootfs),
        for example, if *bootpart=1*, then the Linksys F/W rootfs must be on *mtd13*. If *bootpart=2*, then it is on *mtd11*. I will
        use *mtd11* as an example to get the Linksys factory radio calibration data for the EA8300.

#.      Mount Linksys rootfs to access radio data (change mtd number to fit your current boot partition set). The 
        example below shows how to attach MTD partition where Linksys rootfs is located, create temporary mount point
        and mount its UBIFS.

.. code-block::
                
        ubiattach -m11
        mkdir /mnt/ubi
        mount -t ubifs /dev/ubi1_0 /mnt/ubi


#.      Copy factory's RF calibration data and regulatory domain data to OpenWRT. This will enable your router to
        operate optimally.

.. code-block::

       cp /mnt/ubi/lib/firmware/IPQ4019/FCC/* /lib/firmware/IPQ4019/hw.1/
       cp /mnt/ubi/lib/firmware/QCA9888/FCC/* /lib/firmware/QCA9888/hw.2/

*FCC* is for U.S region. Replace it with your region, for example, EU for Europe, AU for Australia etc.

Do not forget to set the root password. It will run ssh service once root password is set (after service restarted).
Reboot the box is recommended; however, */etc/init.d/network reload* might as well works.

How to switch to Linksys firmware from OpenWRT
-----------------------------------------------

There are two u-boot parameters use for switching the firmware boot between Linksys and OpenWRT. You can see them when login to the box
and issuing *fw_printenv*. The variables *boot_part* is either 1 or 2, for example, if *boot_part=1* while running OpenWRT
that's mean the Linksys f/w is on 2 so to switch it to 2,

.. code-block::

        fw_setenv boot_part 2
        fw_setenv boot_part_ready 2

After reboot, the EA8300 will boot up with Linksys f/w.

How to switch to OpenWRT from Linksys
-------------------------------------

When you flash the OpenWRT the first time, the Linksys f/w switch partition on the box for you. After running OpenWRT for
a while then decide to switch back to Linksys f/w, you can do so using the steps above. Now the box is running Linksys
f/w. How do you switch to OpenWRT again without flashing which will wipe out everything you configured ?

This is tricky part since Linksys f/w does not have option in its Web UI that you can switch the boot/root partition, also
you cannot SSH to it. Basically it is sealed.  You can give the capability by performing these steps while you are login to OpenWRT.

**Important:** Do this before you ever switch back to Linksys firmware or you will end up flashing the OpenWRT for the 
second time !

1) Mount the Linksys rootfs partition (as shown above) to copy OpenWRT's *dropbear* into it.

.. code-block::

        cp /usr/sbin/dropbear /mnt/ubi/usr/sbin

2) Create script to run *dropbear* on Linksys f/w when you switch later on.

.. code-block::

        echo "/usr/sbin/dropbear -d /etc/dropbear_dss_host_key -r /etc/dropbear_rsa_host_key">/mnt/ubi/etc/dropbear.sh 
        chmod +x /mnt/ubi/etc/dropbear.sh

You can edit this file the way you like as long as you can assure that SSH will be running after you make the switch. The
dropbear's keys existed in Linksys f/w. It just does not have the accompanied *dropbear* that uses it. Basically use
the existing Linksys's own keys and enable it.

3) Add to start-up list,

.. code-block::

        cd /mnt/ubi/etc/registration.d
        ln -s ../init.d/dropbear.sh 99_sshd

Next time you router run its factory f/w, it will have ssh capability where you can login. The factory ssh login
used to be *ssh root@<your box ip>*. Its password was *admin*. From this point onward you can safely
switch between Linksys and OpenWRT firmware using *boot_partxx* environments. If you forgot your Linksys password
you can always factory reset it !

Update Linksys firmware with OpenWRT
-------------------------------------

**Try to be extremely careful with *flash_erase* command where you could easily brick the box if you mistype MTD number !**

Remember that whenever you run Linksys f/w, the f/w upgrade will always be on the other set of kernel+rootfs
partitions. This means that it will overwrite the partitions where OpenWRT resides !

You can also update Linksys f/w while running OpenWRT without the need to switch to running Linksys
firmware. To do that,

* Download the Linksys firmware to your host PC for your local copy.

* Login to the your router (running OpenWRT) with ssh.

* *scp* Linksys firmware file to your box and use *flash_erase* and *nandwrite* to update the firmware. Of course,
  you should identify where the new firmware should be in particular partitions. For Linksys firmware, it 
  will be in either *mtd10* or *mtd13*, for example, if *boot_part=1*, you need to flash to 2nd set of partition
  that will overwrite the old Linksys f/w. To do this,

.. code-block::

        #scp file from your host into /tmp directory (it should fit).
        flash_erase /dev/mtd13 0 0  (if boot_part=1 )
        nandwrite -p -q /dev/mtd13 /tmp/<fw image> (assume it is in /tmp)


* Change the *boot_partxx* parameters with *fw_setenv* to switch the firmware.

This concluded the installation of OpenWRT into the Linksys EA8300 Wi-Fi router and hopefully you did not brick your
router !

.. Using the toolchain from my git repository where you downloaded the OpenWRT, you can build and install OpenWRT apps. 
