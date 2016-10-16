`timescale 1ns / 100ps
`default_nettype none
// SPI Byte Interface, top level module
// Platform: Altera Cyclone IV using Quartus 16.0
// Documentation: http://www.coertvonk.com/technology/logic/connecting-fpga-and-arduino-using-spi-13067
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

// for SPI MODE 3
module spi_byte( input wire sysClk,       // FPGA system clock (must be several times faster as SCLK, e.g. 50MHz)
                 input wire [0:0] KEY,    // FPGA user reset button
					  input wire SCLK,         // SPI clock (e.g. 4 MHz)
					  input wire MOSI,         // SPI master out, slave in
					  output wire MISO,        // SPI slave in, master out
					  input wire SS,           // SPI slave select
					  output reg [0:0] LED );  // output bit
						
   wire rxValid;
	wire [7:0] rx, tx;

	 // bits <> bytes
   spi_byte_if byte_if( .sysClk  (sysClk),
								.usrReset(~KEY[0]),
	                     .SCLK    (SCLK),
								.MOSI    (MOSI),
								.MISO    (MISO),
								.SS      (SS),
								.rxValid (rxValid),
								.rx      (rx),
								.tx      (8'h55) );

	// byte received controls an LED
	always @(posedge sysClk)
	   if (rxValid )
		   LED[0] <= ( rx == 8'hAA );

endmodule
