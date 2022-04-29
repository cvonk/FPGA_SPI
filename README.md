# FPGA to microcontroller interface using SPI

This implements registers on the FPGA that can be read or written from any microcontroller that supports the Serial Peripheral Interface (SPI). The article [Math Talk](http://coertvonk.com/category/hw/math-talk) describes the protocol and its implementation 

Serial Peripheral Interface (SPI) is a synchronous full-duplex serial interface commonly used to communicate with on-board peripherals such as FLASH memory, A/D converters, temperature sensors, or in our case a Field Programmable Gate Array (FPGA).
