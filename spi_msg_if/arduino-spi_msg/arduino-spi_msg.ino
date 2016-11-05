/**
 * @brief SPI master for msg example, communicates with FPGA over SPI interface
 * @file  arduino-spi_msg.ino
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

#include <Arduino.h>
#include <SPI.h>

typedef enum {
    IO_SSFPGA = 10
};

uint8_t exchange_byte( uint8_t const value )
{
    return SPI.transfer( value );
}

enum commands_t {
    CMD_STATUS = 0x00,
    CMD_RDREG = 0x80,
    CMD_WRREG = 0xC0
};

uint8_t DUMMY = 0xFF;

uint8_t read_status( void )
{
    (void)exchange_byte( CMD_STATUS );
    return exchange_byte( DUMMY );
}

void write_register( uint8_t const regNr, uint32_t const value )
{
    (void)exchange_byte( CMD_WRREG | (regNr & 0xFF) );
    (void)exchange_byte( (value >> 24) & 0xFF );
    (void)exchange_byte( (value >> 16) & 0xFF );
    (void)exchange_byte( (value >>  8) & 0xFF );
    (void)exchange_byte( (value >>  0) & 0xFF );
}

uint32_t read_register( uint8_t const regNr )
{
    (void)exchange_byte( CMD_RDREG | (regNr & 0xFF) );
    uint32_t const b1 = exchange_byte( DUMMY );
    uint32_t const b2 = exchange_byte( DUMMY );
    uint32_t const b3 = exchange_byte( DUMMY );
    uint32_t const b4 = exchange_byte( DUMMY );
    return (b1 << 24) | (b2 << 16) | (b3 << 8) | (b4 << 0);
}

void print_status_error( uint8_t const val1,
                         uint8_t const val2 )
{
    Serial.print( "STATUS error: " );
    Serial.print( val1, HEX ); Serial.print( " != " ); Serial.println( val2, HEX );
}

void print_reg_error( char const * const str,
                      uint8_t const regNr,
                      uint32_t const val1,
                      uint32_t const val2 )
{
    Serial.print( str ); Serial.print( "(" );
    Serial.print( regNr, HEX ); Serial.print( ") error: " );
    Serial.print( val1, HEX ); Serial.print( " != " ); Serial.println( val2, HEX );
}

void read_verify_status( uint8_t const expected )
{
    uint8_t const status = read_status();
    if ( status != expected ) {
        print_status_error( status, expected );
    }
}

void write_verify_register( uint8_t const regNr, uint32_t const value )
{
    write_register( regNr, value );
    uint32_t const valRead = read_register( regNr );
    if ( valRead != value ) {
        print_reg_error( "WRREG ", regNr, valRead, value );
    }
}

uint32_t read_verify_register( uint8_t const regNr, uint32_t const expected )
{
    uint32_t const valRead = read_register( regNr );
    if ( valRead != expected ) {
        print_reg_error( "RDREG ", regNr, valRead, expected );
    }
    return valRead;
}

void setup()
{
    Serial.begin( 115200 );
	while (!Serial) {
		; // wait
	}
	Serial.println("spi_msg");
	SPI.begin();
    pinMode( IO_SSFPGA, OUTPUT );
}

void loop()
{
	digitalWrite(IO_SSFPGA, 0);
	SPI.beginTransaction(SPISettings(4000000, MSBFIRST, SPI_MODE3));
	{
		read_verify_status(0x5A);

		uint32_t const reg0 = 0x76543210;
		uint32_t const reg1 = 0x01234567;
		write_verify_register(0, reg0);
		write_verify_register(1, reg1);

		read_verify_register(4, 0xDEADBEEF);
	}
	SPI.endTransaction();
	digitalWrite(IO_SSFPGA, 1);

	static int ii = 0;
	if (++ii % 1024 == 0) {
		Serial.print(".");  // show a sign of life
	}
}
