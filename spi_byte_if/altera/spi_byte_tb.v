// SPI Byte Interface, test bench
// Platform: Altera Cyclone IV using Quartus 16.1
// Documentation: http://www.coertvonk.com/technology/logic/connecting-fpga-and-arduino-using-spi-13067
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015-2016, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

`timescale 1ns / 1ps
`default_nettype none

module spi_byte_tb;  // MODE_3

	localparam T = 250;   // SPI clock period (4 MHz)
	localparam Tsys = 20; // external FPGA clock period (50 MHz)

	// UUT input and output
	reg clk50Mhz = 1'b0;
	reg SCLK = 1'b1;
	reg MOSI = 1'bz;
	reg SS = 1'b1;
	wire MISO;
	wire LED;
  reg [7:0] misoData;
	wire clkLocked;
	
   // instantiate Unit Under Test
	spi_byte uut ( .clk50Mhz  ( clk50Mhz ),
								 .SCLK      ( SCLK ), 
								 .MOSI      ( MOSI ), 
								 .MISO      ( MISO ), 
								 .SS        ( SS ), 
								 .LED       ( LED ),
								 .clkLocked ( clkLocked ) );

   // simulate external clock 
   always 
	   forever 
		   #(Tsys/2) clk50Mhz = ~clk50Mhz;

	// test script				 
	initial
		begin

			@(posedge clkLocked)
				;
			
			#100 SS = 1'b0;  // activate slave-select

			exchange_byte( 8'hAA, misoData );
			#100 if ( misoData != 8'h55 ) $display ( "misoData %h != 55", misoData );
			if ( LED != 1'b1 ) $display ( "LED %h != 1", misoData );
			$display( "LED=%b misoData %h", LED, misoData );

			#10 SS = 1'b1;   // de-activate slave-select
			MOSI = 1'bz;	

      $display("EOT");			
		  $stop;
		end

  task exchange_byte ( input [7:0] mosiData,
								output [7:0] misoData );
		integer jj;
		begin
			for (jj = 0; jj < 8; jj = jj + 1 )
				begin
					#(T/2) SCLK = 1'b0; MOSI = mosiData[7 - jj];  // drive on falling edge
					#(T/2) SCLK = 1'b1; misoData = { misoData[6:0], MISO };  // sample in rising
				end
		end
	endtask

endmodule
