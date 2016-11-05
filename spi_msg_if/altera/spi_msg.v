`timescale 1ns / 100ps
`default_nettype none
// SPI Message Interface, top level module
// Platform: Altera Cyclone IV using Quartus 16.0
// Documentation: http://www.coertvonk.com/technology/logic/connecting-fpga-and-arduino-using-spi-13067
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

// for SPI MODE 3
module spi_msg #( parameter nrRWregs = 4,
	               parameter nrROregs = 12 ) // nrRWregs + nrROregs should be <= 16
                ( input wire sysClk,        // FPGA system clock (must be several times faster as SCLK, e.g. 66MHz)
                  input wire [0:0] KEY,     // FPGA user reset button
					   input wire SCLK,          // SPI clock (e.g. 4 MHz)
					  	input wire MOSI,          // SPI master out, slave in
						output wire MISO,         // SPI slave in, master out
						input wire SS,            // SPI slave select
						output wire [1:0] LED );  // debug
						
   wire rxValid;
	wire [7:0] rx, tx;
	wire [nrRWregs*32-1:0] rwRegs1D;
	wire [nrROregs*32-1:0] roRegs1D;
	
	 // bits <> bytes
   spi_byte_if byte_if( .sysClk  (sysClk),
								.usrReset(~KEY[0]),
	                     .SCLK    (SCLK),
								.MOSI    (MOSI),
								.MISO    (MISO),
								.SS      (SS),
								.rxValid (rxValid),
								.rx      (rx),
								.tx      (tx) );

   // bytes <> messages
   spi_msg_if #( nrRWregs, nrROregs ) msg_if
					( .sysClk  (sysClk),
					  .usrReset(~KEY[0]),
					  .rxValid (rxValid),
	              .rx      (rx),
	              .tx      (tx),
                 .rwRegs1D(rwRegs1D),
					  .roRegs1D(roRegs1D) );

	// inflate the 1D arrays (rwRegs1D, roRegs1D)
	// into a 2D registers array (registers)
	wire [31:0] registers[0:nrRWregs+nrROregs-1];
	genvar nn;
	generate
		for ( nn = 0; nn < nrRWregs; nn = nn + 1 )
			begin :nnRW
				assign registers[nn] = rwRegs1D[32*nn+31:32*nn];
			end
		for ( nn = 0; nn < nrROregs; nn = nn + 1 )	
			begin :nnRO
				assign roRegs1D[32*nn+31:32*nn] = registers[nn+nrRWregs];
			end
		
		// connect the input and outputs
		assign registers[0+nrRWregs] = 32'hDEADBEEF;
		for (nn = 1; nn < nrROregs; nn = nn + 1 )
			begin :nnRegs
				assign registers[nn+nrRWregs] = 32'h00000000;
			end
   endgenerate
		
	// turn LEDs on when expected value has been written to register
	assign LED[0] = (registers[0] == 32'h76543210 );
	assign LED[1] = (registers[1] == 32'h01234567 );
endmodule
