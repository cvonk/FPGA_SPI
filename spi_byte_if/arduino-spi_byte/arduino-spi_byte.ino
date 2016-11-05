/**
 * @brief SPI master for byte example, communicates with FPGA over SPI interface
 * @file  arduino-spi_byte.ino
 * Platform: Arduino 101 or 3.3 Volt Arduino UNO R3 using Arduino IDE
 * Documentation: http://www.coertvonk.com/technology/logic/connecting-fpga-and-arduino-using-spi-13067
 *
 * GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
 * (c) Copyright 2015-2016, Coert Vonk
 * All rights reserved.  Use of copyright notice does not imply publication.
 * All text above must be included in any redistribution
 * 
 *           Arduino   Xilinx    Altera
 *                     FPGA J#4  GPIO_0
 * ssFPGA    10        J4#1      JP1#4
 * MOSI      11        J4#2      JP1#6
 * MISO      12        J4#3      JP1#8
 * SCK       13        J4#4      JP1#10
 * GND       GND       J4#5      JP1#12
 **/

#include <SPI.h>

uint8_t const ssFPGA = 10;

void setup()
{
    Serial.begin(115200);
	while (!Serial) {
		; // wait
	}
	Serial.println("spi_byte");
    SPI.begin();
    pinMode( ssFPGA, OUTPUT );
}

void loop() 
{
    digitalWrite( ssFPGA, 0 );
    for ( uint8_t ii = 0; ii < 10; ii++) {
        delay( 10 );
        SPI.beginTransaction( SPISettings( 4000000, MSBFIRST, SPI_MODE3 ) );
        {
            uint8_t const miso = SPI.transfer(ii == 0 ? 0xAA : 0x55 );
            Serial.println( miso, HEX );
        }
        SPI.endTransaction();
    }
    digitalWrite( ssFPGA, 1 );

	static int ii = 0;
	if (++ii % 1024 == 0) {
		Serial.print(".");  // show a sign of life
	}
}
