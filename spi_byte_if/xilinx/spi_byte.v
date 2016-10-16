`timescale 1ns / 100ps
`default_nettype none
// (c) 2015, by Coert Vonk
// http://www.coertvonk.com/technology/logic/fpga-spi-slave-in-verilog-13067

// for SPI MODE 3
module spi_byte( input wire sysClk,    // FPGA system clock (must be several times faster as SCLK, e.g. 66MHz)
                 input wire usrReset,  // FPGA user reset button
					  input wire SCLK,      // SPI clock (e.g. 4 MHz)
					  input wire MOSI,      // SPI master out, slave in
					  output wire MISO,     // SPI slave in, master out
					  input wire SS,        // SPI slave select
					  output reg LED1 );    // output bit
						
   wire rxValid;
	wire [7:0] rx, tx;

	 // bits <> bytes
   spi_byte_if byte_if( .sysClk  (sysClk),
								.usrReset(usrReset),
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
		   LED1 <= ( rx == 8'hAA );

endmodule
