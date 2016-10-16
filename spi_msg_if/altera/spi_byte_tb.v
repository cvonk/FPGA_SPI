`timescale 1ns / 100ps
`default_nettype none
// (c) 2015, by Coert Vonk
// http://www.coertvonk.com/technology/logic/fpga-spi-slave-in-verilog-13067/8 

module spi_slave_tb;  // MODE_3

	localparam T = 250;   // SPI clock period
	localparam Tsys = 16; // period to generate a 62.5 MHz system clock

	// UUT input and output
	reg sysClk = 1'b0;
	reg usrReset;
	reg SCLK;
	reg MOSI;
	reg SS;
	wire MISO;
	wire [1:0] LED;

   reg [7:0] misoData, mosiData;
	reg [7:0] dummy = 8'hxx;

   // instantiate Unit Under Test
	spi_msg uut ( .sysClk   ( sysClk ),
					  .usrReset ( usrReset ),
					  .SCLK     ( SCLK  ), 
					  .MOSI     ( MOSI ), 
					  .MISO     ( MISO ), 
					  .SS       ( SS   ), 
					  .LED      ( LED ));

   // simulate system clock 
   always 
	   forever 
		   #(Tsys/2) sysClk = ~sysClk;

	reg [7:0] status;
	reg [31:0] valueWritten, valueRead;

	// test script				 
	initial
		begin
			sysClk = 1'b0;  // initialize inputs
			usrReset = 1'b0;
			SCLK = 1'b1;
			MOSI = 1'bz;
			SS = 1'b1;

			#100;  // wait 100 ns for global reset to finish
			#10 SS = 1'b0;  // activate slave-select

			read_status( status ); $display( "status %h", status );

			write_verify_register( 0, 32'h76543210 );  $display( "LED[0]=%b", LED[0] );
			write_verify_register( 1, 32'h01234567 );  $display( "LED[1]=%b", LED[1] );

			read_verify_register( 4, 32'hDEADBEEF );

			#100
			read_verify_register( 5, 32'h76543210 + 32'h01234567 );
			read_verify_register( 6, 32'h76543210 - 32'h01234567 );

			#10 SS = 1'b1;   // de-activate slave-select
			MOSI = 1'bz;
			
			$display("EOT");
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
