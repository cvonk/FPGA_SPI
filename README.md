# fpga-arduino-spi
## Math Talk

![Image](media/spi-logo-mathtalk-small.jpg)

The inquiry [Building Math Hardware](http://www.coertvonk.com/technology/logic/fpga-math-verilog-12758) implemented a math compute device on a Field Programmable Gate Array (FPGA).  This sequel describes a protocol and implementation by which the FPGA can communicate with a microcontroller.  The vision is to generate operands on an microcontroller; the Math Hardware then performs the operations and returns the results.  The communication between the devices is the focus of this article.

The protocol that we will use is called Serial Peripheral Interface (SPI).  It is a synchronous full-duplex serial interface [[1]](http://www-ee.eng.hawaii.edu/~tep/EE491E/Notes/HC11A8/HC11A8_SPI.pdf), and is commonly used to communicate with on-board peripherals such as EEPROM, FLASH memory, A/D converters, temperature sensors, or in our case a Field Programmable Gate Array (FPGA).

We assume a working knowledge of the Verilog hardware description language.  To learn more about Verilog refer a book such as “FPGA Prototyping with Verilog Examples” by Chu, do the free online class at [verilog.com](http://vol.verilog.com/), or read through the slides [Intro to Verilog](http://web.mit.edu/6.111/www/f2015/index.html) from MIT.  My short introduction to the Verilog IDE can be found at [Getting Started with FPGA programming on Altera](http://www.coertvonk.com/technology/logic/quartus-cycloneiv-ne0nano-15932) or [on Xilinx](http://www.coertvonk.com/technology/logic/ise-spartan6-lx9-12604).

Contents

After describing the physical connections, we look into exchanging bytes between a microcontroller and an FPGA.  The last part implements an layer that allows message passing.

1. [Hardware](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/2)
2. Bytes
  * [Protocol](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/3)
  * [Arduino as Master](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/4)
  * [FPGA as Slave](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/5)
3. Messages
  * [Protocol](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/6)
  * [Arduino as Master](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/7)
  * [FPGA as Slave](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/8)
4. [What’s next](http://www.coertvonk.com/wp-admin/connecting-fpga-and-arduino-using-spi-13067/9)
