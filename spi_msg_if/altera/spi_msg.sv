// SPI Message Interface, top level module
// Platform: Altera Cyclone IV using Quartus 21.1 (>=16.1)
// Documentation: https://coertvonk.com/hw/math-talk/messages-exchange-with-fpga-as-slave-30825
//
// Implements SPII messaging protocol with Arduino (https://coertvonk.com/hw/math-talk/message-exchange-protocol-30820)
//   - Implements the commands STATUS, RDREG, WRREG
//   - Implements 4 read/write and 12 read-only registers, numbered 0 .. 16
//   - When the read/write registers[0] receives 0x76543210 it turns LED[0] on.
//   - When the read/write registers[1] receives 0x01234567 it turns LED[1] on.
//   - For read-only register[4] it always returns the value 0xDEADBEEF.
//   - The other read-only register register[4] .. [15], it always returns 0x00000000.
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015-2022, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

`timescale 1ns / 1ps
`default_nettype none

// for SPI MODE 3
module spi_msg #( parameter NR_RWREGS = 4,   // number of read/write registers
	               parameter NR_ROREGS = 12 ) // number of read-only registers
                ( input wire clk50MHz,       // external FPGA system clock (must be several times faster as SCLK, e.g. 50MHz)
                  input wire SCLK,           // SPI clock (e.g. 4 MHz)
					   input wire MOSI,           // SPI master out, slave in
						output wire MISO,          // SPI slave in, master out
						input wire SS,             // SPI slave select
						output wire [1:0] LED,
						output wire clkLocked );
						
	// derive 200 MHz clock from 50 MHz external clock
	wire clk200MHz;
	pll pll( clk50MHz, clk200MHz, clkLocked );
	
	wire rxValid;
	wire [7:0] rx, tx;
	wire [NR_RWREGS+NR_ROREGS-1:0] [31:0] registers; // registers are defined in spi_msg_if, 'cause output of that module can only connect to a net, not a register
	wire [NR_RWREGS-1:0] wrRegs;

	// bits <> bytes
	spi_byte_if byte_if( .sysClk  (clk200MHz),
								.SCLK    (SCLK),
								.MOSI    (MOSI),
								.MISO    (MISO),
								.SS      (SS),
								.tx      (tx),
								.rx      (rx),
								.rxValid (rxValid) );

   // bytes <> messages
	spi_msg_if #( NR_RWREGS, NR_ROREGS ) msg_if( .sysClk  (clk200MHz),
																.tx      (tx),
																.rx      (rx),
																.rxValid (rxValid),
																.rwRegs  (registers[NR_RWREGS -1:0]),
																.roRegs  (registers[NR_RWREGS + NR_ROREGS -1:NR_RWREGS]),
																.wrRegs  (wrRegs)	);

   // connect remaining read-only registers
	assign registers[NR_RWREGS+0] = 32'hDEADBEEF;
	genvar nn;
	generate
		for (nn = 1; nn < NR_ROREGS; nn = nn + 1 )
			begin :nnRegs
				assign registers[NR_RWREGS+nn] = 32'h00000000;
			end
   endgenerate
	
	// turn LEDs on when expected value has been written to register
	assign LED[0] = (registers[0] == 32'h76543210 );
	assign LED[1] = (registers[1] == 32'h01234567 );
endmodule
