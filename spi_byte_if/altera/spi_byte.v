// SPI Byte Interface, top level module
// Platform: Altera Cyclone IV using Quartus 21.1 (>=16.1)
// Documentation: https://coertvonk.com/hw/math-talk/byte-exchange-with-a-fpga-as-slave-30818
//
// Demonstrates byte exchange with Arduino where FPGA is the SPI slave
//   - The Arduino sends an alternating pattern of 0xAA and 0x55 to the FPGA.
//   - On the FPGA, LED[0] will be on when it receives 0xAA.  Consequentially it will blink with 10% duty cycle.
//   - The FPGA always returns 0x55, what is displayed on the serial port.
//   
// The protocol is specified at https://coertvonk.com/hw/math-talk/bytes-exchange-protocol-30814
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015-2022, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

`timescale 1ns / 1ps
`default_nettype none

// for SPI MODE 3
module spi_byte( input wire clk50Mhz,     // external FPGA system clock (e.g. 50 MHz)
                 input wire SCLK,         // SPI clock (e.g. 4 MHz)
					  input wire MOSI,         // SPI master out, slave in
					  output wire MISO,        // SPI slave in, master out
					  input wire SS,           // SPI slave select
					  output reg [0:0] LED,    // output bit
                 output wire clkLocked ); // PLL clock locked
								 
  // generate a fast clock, that later will allow us to measure coarse propagation delay

	wire clk200MHz;
	spi_pll pll( clk50Mhz, clk200MHz, clkLocked);
						
	// bits <> bytes

	wire rxValid;
	wire [7:0] rx, tx;
 
	spi_byte_if byte_if( .sysClk  (clk200MHz),
								.SCLK    (SCLK),
								.MOSI    (MOSI),
								.MISO    (MISO),
								.SS      (SS),
								.tx      (8'h55),
								.rx      (rx),
								.rxValid (rxValid) );

   // byte received controls a LED (on when expected byte was received)

	always @(posedge clk200MHz)
	   if (rxValid )
		   LED[0] <= ( rx == 8'hAA );
			
endmodule
