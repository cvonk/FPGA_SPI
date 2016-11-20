// SPI Message Interface, test bench
// Platform: Altera Cyclone IV using Quartus 16.1
// Documentation: http://www.coertvonk.com/technology/logic/connecting-fpga-and-arduino-using-spi-13067
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015-2016, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

`timescale 1ns / 1ps
`default_nettype none

module spi_msg_tb;  // MODE_3

	localparam T = 250;   // SPI clock period
	localparam Tsys = 20; // period to generate a 50 MHz system clock

	// UUT input and output
	reg clk50MHz = 1'b0;  // initialize inputs
	reg SCLK = 1'b1;
	reg MOSI = 1'bz;
	reg SS = 1'b1;
	wire MISO;
	wire [1:0] LED;
	reg [7:0] dummy = 8'hxx;
	wire clkLocked;

   // instantiate Unit Under Test
	spi_msg uut ( .clk50MHz  ( clk50MHz ),
					  .SCLK      ( SCLK  ), 
					  .MOSI      ( MOSI ), 
					  .MISO      ( MISO ), 
					  .SS        ( SS   ), 
					  .LED       ( LED ),
					  .clkLocked ( clkLocked ) );
								
   // simulate system clock 
   always 
	   forever 
		   #(Tsys/2) clk50MHz = ~clk50MHz;

	reg [7:0] status;

	// test script				 
	initial
		begin
		   @(posedge clkLocked)  // wait for PLL lock
				;
				
			#10 SS = 1'b0;  // activate slave-select

			read_status( status ); $display( "status %h", status );

			write_verify_register( 0, 32'h76543210 );  $display( "LED[0]=%b", LED[0] );
			write_verify_register( 1, 32'h01234567 );  $display( "LED[1]=%b", LED[1] );

			read_verify_register( 4, 32'hDEADBEEF );

			#100
			read_verify_register( 5, 32'h00000000 );
			read_verify_register( 6, 32'h00000000 );

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

   task read_status( output [7:0] value );
	   begin
			exchange_byte( 8'h00, dummy );
			exchange_byte( dummy, value );
			if ( value != 8'h5A ) $display ( "read status %h, but expected 5a", value );
		end
	endtask

   task write_register( input [3:0] regNr, input [31:0] value );
	   begin
			exchange_byte( 8'hC0 | regNr, dummy );
			exchange_byte( value[31:24], dummy );
			exchange_byte( value[23:16], dummy );
			exchange_byte( value[15:8], dummy );
			exchange_byte( value[7:0], dummy );
		end
	endtask

   task read_register( input [3:0] regNr, output [31:0] value );
	   begin
			exchange_byte( 8'h80 | regNr, dummy );
			exchange_byte( dummy, value[31:24] );
			exchange_byte( dummy, value[23:16] );
			exchange_byte( dummy, value[15:8] );
			exchange_byte( dummy, value[7:0] );
		end
	endtask
	
	task write_verify_register( input [3:0] regNr, input [31:0] value );
		begin :write_verify
			reg [31:0] valRead;
			write_register( regNr, value);
			read_register(regNr, valRead );
			if ( valRead != value ) $display( "registers[%d] wrote %h, but read %h", regNr, value, valRead );
		end
	endtask
	
	task read_verify_register( input [3:0] regNr, input [31:0] expected );
		begin :read_verify
			reg [31:0] valRead;
			read_register(regNr, valRead );
			if ( valRead != expected ) $display( "registers[%d] expected %h, but read %h", regNr, expected, valRead );
		end
	endtask

endmodule
