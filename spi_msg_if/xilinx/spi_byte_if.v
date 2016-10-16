`timescale 1ns / 100ps
`default_nettype none
// (c) 2015, by Coert Vonk
// http://www.coertvonk.com/technology/logic/fpga-spi-slave-in-verilog-13067/8
 
// for SPI MODE 3
module spi_byte_if( input wire sysClk,
                    input wire usrReset,
                    input wire SCLK,        // SPI clock
                    input wire MOSI,        // SPI master out, slave in
                    output wire MISO,       // SPI slave in, master out
                    input wire SS,          // SPI slave select
                    output wire rxValid,    // BYTE received is valid
                    output reg [7:0] rx,    // BYTE received
                    input wire [7:0] tx );  // BYTE to transmit
 
   // synchronize SCLK to FPGA domain clock using a two-stage shift-register
   // (bit [0] takes the hit of timing errors)
   reg [2:0] SCLKr;  always @(posedge sysClk) SCLKr <= { SCLKr[1:0], SCLK };
   reg [1:0] SSr;  always @(posedge sysClk) SSr <= { SSr[0], SS };
   reg [1:0] MOSIr;  always @(posedge sysClk) MOSIr <= { MOSIr[0], MOSI };
   wire SCLK_rising  = ( SCLKr[2:1] == 2'b01 );
   wire SCLK_falling = ( SCLKr[2:1] == 2'b10 );
   wire SS_active  = ~SSr[1];  // synchronous version of ~SS input
   wire MOSI_s = MOSIr[1];     // synchronous version of MOSI input
 
   // next state logic
 
   reg [2:0] state;  // state corresponds to bit count
   localparam [2:0] STATE_WAIT4BIT7 = 3'd0,
		              STATE_WAIT4BIT6 = 3'd1,
		              STATE_WAIT4BIT5 = 3'd2,
		              STATE_WAIT4BIT4 = 3'd3,
		              STATE_WAIT4BIT3 = 3'd4,
		              STATE_WAIT4BIT2 = 3'd5,
		              STATE_WAIT4BIT1 = 3'd6,
		              STATE_WAIT4BIT0 = 3'd7;
 
	reg [2:0] nState;
	
	// control path, next state logic
	
	always @(*)
		if (SS_active)
			if (SCLK_rising)
				nState = state + 3'd1;
			else
				nState = state;
		else
			nState = STATE_WAIT4BIT7;


   // control path, current state logic
 
   always @(posedge sysClk or posedge usrReset)
      if( usrReset )
         state <= STATE_WAIT4BIT7;
      else
         state <= nState;
          
   // data path

   reg [7:0] data = 8'hxx, nData;
   reg rxAvail = 1'b0, nRxAvail;
	reg [7:0] nRx;
   reg MISOr = 1'bx, nMISOr;
	
   // data path, next state logic

	wire [7:0] rx_next = {data[6:0], MOSI_s};	
   always @(*)
		begin
			nData = data;  // assume all stays the same unless noted
			nRx = rx;
			nRxAvail = rxAvail;
			nMISOr = MISOr;
		
			if ( SS_active )
				if ( SCLK_rising )  // input on rising PCI clock edge
					begin
						nData = rx_next;
						if ( state == STATE_WAIT4BIT0 ) 
							begin
								nRx = rx_next;  // grab data received
								nRxAvail = 1'b1;
							end
						else
							nRxAvail = 1'b0;
					end
				else if ( SCLK_falling)  // output on falling PCI clock edge
					begin
						if ( state == STATE_WAIT4BIT7 )
							begin
								nData = tx;  // get data to transmit
								nMISOr = tx[7];
							end
						else
							nMISOr = data[7];
					end
		end
				
   // data path, current state logic

   always @(posedge sysClk or posedge usrReset)
      if ( usrReset )
         begin
            rx <= 8'hxx;
            rxAvail <= 1'b0;
				data <= 8'hxx;
				MISOr <= 1'bx;
         end
      else
			begin
				rx <= nRx;
				rxAvail <= nRxAvail;
				data <= nData;
				MISOr <= nMISOr;
			end
 
   // data path, output logic

   assign MISO = SS_active ? MISOr : 1'bz;  // send MSB first
   reg rxAvailFall;  // make rxAvail change on the falling edge
   reg rxAvailFall_dly;  // make it 1 cycle wide
   always @(negedge sysClk) rxAvailFall <= rxAvail;
   always @(negedge sysClk) rxAvailFall_dly <= rxAvailFall;
   assign rxValid = rxAvailFall & ~rxAvailFall_dly;
 
endmodule
