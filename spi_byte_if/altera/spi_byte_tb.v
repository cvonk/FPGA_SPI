`timescale 1ns / 100ps
`default_nettype none
// (c) 2015-2016, by Coert Vonk
// http://www.coertvonk.com/technology/logic/fpga-spi-slave-in-verilog-13067/5

module spi_byte_tb;  // MODE_3

	localparam T = 250;   // SPI clock period
	localparam Tsys = 20; // period to generate a 50 MHz system clock

	// UUT input and output
	reg sysClk = 1'b0;
	reg usrResetNot = 1'b1;
	reg SCLK = 1'b1;
	reg MOSI = 1'bz;
	reg SS = 1'b1;
	wire MISO;
	wire LED;

   reg [7:0] misoData;

   // instantiate Unit Under Test
	spi_byte uut ( .sysClk   ( sysClk ),
						.KEY      ( usrResetNot ),
						.SCLK     ( SCLK ), 
						.MOSI     ( MOSI ), 
						.MISO     ( MISO ), 
						.SS       ( SS ), 
						.LED      ( LED ) );

   // simulate system clock 
   always 
	   forever 
		   #(Tsys/2) sysClk = ~sysClk;

	// test script				 
	initial
		begin

			#100;  // wait 100 ns for global reset to finish
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
