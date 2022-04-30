# FPGA to microcontroller interface using SPI

This implements registers on the FPGA that can be read or written from any microcontroller that supports the Serial Peripheral Interface (SPI). The article [Math Talk](http://coertvonk.com/category/hw/math-talk) describes the protocol, shows logic analyzer traces explains the Verilog implementation.

The FPGA implementation is for Altera, but should apply equally to Xilinx. Similarly, the microcontroller implementation is for Arduino but is trivial to write for other platforms.
