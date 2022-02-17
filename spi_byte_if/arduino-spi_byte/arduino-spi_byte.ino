/**
 * @brief SPI master for byte example, communicates with FPGA over SPI interface
 * @file  arduino-spi_byte.ino
 * Platform: Arduino 101 or 3.3 Volt Arduino UNO R3 using Arduino IDE
 * Documentation: https://coertvonk.com/hw/math-talk/bytes-exchange-with-arduino-as-master-30816
 *
 * Demonstrates byte exchange with FPGA where Arduino is the SPI master
 *   - Waits for the serial port to be connected (115200 baud)
 *   - The Arduino sends an alternating pattern of 0xAA and 0x55 to the FPGA.
 *   - On the FPGA, LED[0] will be on when it receives 0xAA.  Consequentially it will blink with 10% duty cycle.
 *   - The FPGA always returns 0x55, what is displayed on the serial port.
 *   
 * The protocol is specified at https://coertvonk.com/hw/math-talk/bytes-exchange-protocol-30814
 * 
 *           Arduino   Xilinx    Altera
 *                     FPGA J#4  GPIO_0
 * ssFPGA    10        J4#1      JP1#4
 * MOSI      11        J4#2      JP1#6
 * MISO      12        J4#3      JP1#8
 * SCK       13        J4#4      JP1#10
 * GND       GND       J4#5      JP1#12
 *
 * Tested versions:
 *   - Arduino IDE 1.8.19
 *   - Intel Curie Boards support package 2.0.5
 *
 * GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
 * (c) Copyright 2015-2022, Coert Vonk
 * All rights reserved.  Use of copyright notice does not imply publication.
 * All text above must be included in any redistribution
 **/

#include <SPI.h>

uint8_t const ssFPGA = 10;

void setup()
{
    pinMode(ssFPGA, OUTPUT);
    digitalWrite(ssFPGA, 0);
    SPI.begin();
    
    Serial.begin(115200);
	  while (!Serial) {
		    ; // wait
	  }
  	Serial.println("spi_byte");
}

void loop() 
{
    digitalWrite(ssFPGA, 0);
    for ( uint8_t ii = 0; ii < 10; ii++) {
        //delay( 10 );
        SPI.beginTransaction( SPISettings( 4000000, MSBFIRST, SPI_MODE3 ) );
        {
            (void)SPI.transfer(ii == 0 ? 0xAA : 0x55 );
        }
        SPI.endTransaction();
    }
    digitalWrite(ssFPGA, 1);

  	static int ii = 0;
	  if (++ii % 1024 == 0) {
		    Serial.print(".");  // show a sign of life
	  }
}
