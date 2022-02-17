// SPI Message Interface, message interface module
// Platform: Altera Cyclone IV using Quartus 16.1
// Documentation: http://www.coertvonk.com/technology/logic/connecting-fpga-and-arduino-using-spi-13067
//
// GNU GENERAL PUBLIC LICENSE Version 3, check the file LICENSE for more information
// (c) Copyright 2015-2016, Coert Vonk
// All rights reserved.  Use of copyright notice does not imply publication.
// All text above must be included in any redistribution

`timescale 1ns / 1ps
`default_nettype none

typedef logic [31:0] register_t;

module spi_msg_if #( parameter NR_RWREGS = 4,   // number of read/write registers
	                  parameter NR_ROREGS = 12 ) // number of read-only registers
                   ( input wire sysClk,
						   output reg [7:0] tx,       // BYTE data to transmit
						   input wire [7:0] rx,       // BYTE data received
						   input wire rxValid,        // BYTE data is valid
						   output [NR_RWREGS-1:0] [31:0] rwRegs,   // MESSAGE read/write registers
						   input [NR_ROREGS-1:0] [31:0] roRegs,    // MESSAGE read only registers
						   output reg [NR_RWREGS-1:0] wrRegs = {NR_RWREGS{1'b0}} );  // MESSAGE register has been writen (posedge)
							
	// store the registers here
	// can't store them in top module, because this module's output can ony connect to a net in the top module, not a reg
	// output rwRegs are connects directly to registers[]
	// value from input roRegs is used to transmit in response to CMD_RDREG
	reg [NR_RWREGS + NR_ROREGS - 1:0] [31:0] registers;  // 16 registers of 32-bit each
	assign rwRegs = registers[NR_RWREGS-1:0];  // these outputs are directly connected to 
				
	localparam [7:0] CMD_STATUS  = 8'b00000000,
						  CMD_RDREG   = 8'b1000xxxx,
						  CMD_WRREG   = 8'b1100xxxx,
						  CMD_ANY     = 8'bxxxxxxxx;
			
    localparam [3:0] STATE_IDLE     = 4'd0,
						   STATE_TXSTATUS = 4'd1,
						   STATE_TXREGVAL = 4'd2,
					 	   STATE_RXREGVAL = 4'd3;

	reg [3:0] state = STATE_IDLE, nState; // current and next state
	reg [3:0] regId = 4'bxxxx, nRegId;    // current and next register index
	reg [1:0] byteId = 2'bxx, nByteId;    // current and next byte id within the 32-bit register word

	reg [7:0] nRx;  // byte received (to be stored in register)
	reg [7:0] nTx;  // next byte to transmit
	//reg [NR_RWREGS-1:0] rxValid = NR_RWREGS{1'b0};
	reg [NR_RWREGS-1:0] nWrRegs;  // next register received

	integer ii;

   // FSM next state logic

	always @(*)
		casex ( {state, rx} )
			{STATE_IDLE, CMD_STATUS}:  // read status command
				begin 
					nState = STATE_TXSTATUS;    
					nRegId = 4'bxxxx;
					nByteId = 2'dx;
					nTx = 8'h5A;  // pseudo status
					nRx = 8'hxx;
					nWrRegs = {NR_RWREGS{1'b0}};
				end
			{STATE_TXSTATUS, CMD_ANY}:  // transmit status
				begin 
					nState = STATE_IDLE; 
					nRegId = 4'bxxxx;
					nByteId = 2'dx;
					nTx = 8'hxx;
					nRx = 8'hxx;
					nWrRegs = {NR_RWREGS{1'b0}};
				end

			{STATE_IDLE, CMD_RDREG}:  // read register command
				begin 
					nState = STATE_TXREGVAL;    
					nRegId = rx[3:0];
					nByteId = 2'd0;
					nTx = registers[nRegId][31:24];
					nRx = 8'hxx;
					nWrRegs = {NR_RWREGS{1'b0}};
				end
			{STATE_TXREGVAL, CMD_ANY}:  // transmit register value cont'd
				begin
					nState = ( byteId == 2'd3 ) ? STATE_IDLE : state;    
					nRegId = regId;
					nByteId= byteId + 1'd1; // 2BD carry-out bit? { dontcare, nByteId } = ...
					case (byteId) 
						2'd0: nTx = registers[regId][23:16];
						2'd1: nTx = registers[regId][15:8];
						2'd2: nTx = registers[regId][7:0];
						2'd3: nTx = 8'hxx;
					endcase
					nRx = 8'hxx;
					nWrRegs = {NR_RWREGS{1'b0}};
				end

			{STATE_IDLE, CMD_WRREG}:  // write register command
				begin 
					nState = STATE_RXREGVAL;    
					nRegId = rx[3:0];
					nByteId = 2'd0;
					nTx = 8'hxx;
					nRx = rx;
					nWrRegs = {NR_RWREGS{1'b0}};
				end
			{STATE_RXREGVAL, CMD_ANY}:  // receive register value
				begin
					nState = (byteId == 2'd3 ) ? STATE_IDLE : state;    
					nRegId = regId;
					nByteId = byteId + 1'd1;  // 2BD carry-out bit? { dontcare, nByteId } = ...
					nTx = 8'hxx;
					nRx = rx;
					nWrRegs = {NR_RWREGS{1'b0}};
					nWrRegs[regId] = (byteId == 2'd3 );
				end

			default: 
				begin
					nState = STATE_IDLE;
					nRegId = 4'bxxxx;
					nByteId = 2'dx;
					nTx = 8'hxx;
					nRx = 8'hxx;
					nWrRegs = {NR_RWREGS{1'b0}};
				end
		endcase

	// FSM current state logic

	always @(posedge sysClk)
		if ( rxValid )
			begin
				state <= nState;
				regId <= nRegId;
				byteId <= nByteId;
			end

  // Data path: for next, current state and output logic

	always @(posedge sysClk)
		if ( rxValid )
			begin
				tx <= nTx;  // always output, shortens the combinatorial path

				case (state) 
					STATE_IDLE: // tx register value for CMD_WRREG
						begin
							for ( ii = 0; ii < NR_ROREGS; ii = ii + 1 )
							registers[ii+NR_RWREGS] <= roRegs[ii];
						end
					STATE_TXSTATUS,
					STATE_TXREGVAL:
					;
					STATE_RXREGVAL:
						begin
							case (byteId)
								0: registers[regId][31:24] <= nRx;
								1: registers[regId][23:16] <= nRx;
								2: registers[regId][15: 8] <= nRx;
								3: registers[regId][ 7: 0] <= nRx;
							endcase
							wrRegs <= nWrRegs;
						end
				endcase
			end
		
endmodule
