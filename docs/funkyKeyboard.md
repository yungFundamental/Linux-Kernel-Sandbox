# Funky Keyboard
## Introduction
This documents me playing around with the keyboard driver.

## Finding The Driver
After running `qemu`, in order to find the module of the driver module that was probed run:
```bash
dmesg | grep input
```

This should show the connected devices and their type. Look up the driver module for that type of device.

I found that my driver is in `drivers/input/keyboard/atkbd.c`

## Getting More Information
I like to play around to find more information. So I added the following line to the `atkbd.c` in the `atkbd_receive_byte` function:
```
dev_dbg(&serio->dev, "Keyboard on %s processing byte %02X.\n", serio->phys, data);
```
This was meant to print the data of each byte recieved before parsing.

For this to be printed, make sure to mount `debugfs` and add `atkbd.c` to [dynamic_debugging](https://www.kernel.org/doc/html/v4.11/admin-guide/dynamic-debug-howto.html).

### What I Learned
Once I got it to work, I learned some valuable information.
1. There already is a `dev_dbg` line that prints all the bytes sent by the keyboard.
    It happens in a function called `atkbd_pre_receive_byte`. The function logs the byte but also some flags. 
    The purpose of this pre-processing is to tell the kernel whether or not to ignore the byte.
1. I got information about each byte that each byte that each button represents.
    When pressing a key a byte is sent. Each key has a different byte to represent it. When that key is let go, the same byte is sent but with the MSB on.
    For example, when pressing the '1' key, the `02` byte is sent (this is true for the key above the 'q' key, not numpad). When letting go, the `82` byte is sent.
    This can be deduced also by the following line in `atkbd_receive_byte`:
    ```c
    atkbd->release = code >> 7;
    ```

