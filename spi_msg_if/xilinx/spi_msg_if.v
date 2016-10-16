`timescale 1ns / 100p
`default_nettype none
// (c) 2015, by Coert Vonk
// http://www.coertvonk.com/technology/logic/fpga-spi-slave-in-verilog-13067/8

module spi_msg_if #( parameter nrRWregs = 4,
	                  parameter nrROregs = 12 )  // total should be <= 15
                   ( input wire sysClk,
						   input wire usrReset,
						   input wire rxValid,        // BYTE data is valid
					      input wire [7:0] rx,       // BYTE data received
						   output reg [7:0] tx,       // BYTE data to transmit
						   output wire [nrRWregs*32-1:0] rwRegs1D, // MESSAGE read/write registers (as 1D vector)
						   input wire [nrROregs*32-1:0] roRegs1D); // MESSAGE read only registers (as 1D vector)

   localparam [7:0] CMD_STATUS  = 8'b00000000,
                    CMD_RDREG   = 8'b1000xxxx,
						  CMD_WRREG   = 8'b1100xxxx,
						  CMD_ANY     = 8'bxxxxxxxx;
						
   localparam [3:0] STATE_IDLE     = 4'd0,
                    STATE_TXSTATUS = 4'd1,
 						  STATE_TXREGVAL = 4'd2,
						  STATE_RXREGVAL = 4'd3;

   reg [31:0] registers [0:15];    // 16 registers of 32-bits

   reg [3:0] state = STATE_IDLE, nState; // current and next state
   reg [3:0] regId = 4'bxxxx, nRegId;    // current and next register index
   reg [1:0] byteId = 2'bxx, nByteId;    // current and next byte id within the 32-bit register word
	
   reg [7:0] nRx;  // byte received (to be stored in register)
   reg [7:0] nTx;  // next byte to transmit

	integer ii;
   reg dontcare = 1'bx;

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
				end
	      {STATE_TXSTATUS, CMD_ANY}:  // transmit status
		      begin 
		         nState = STATE_IDLE; 
				   nRegId = 4'bxxxx;
				   nByteId = 2'dx;
					nTx = 8'hxx;
					nRx = 8'hxx;
				end

			{STATE_IDLE, CMD_RDREG}:  // read register command
		      begin 
				   nState = STATE_TXREGVAL;    
					nRegId = rx[3:0];
				   nByteId = 2'd0;
					nTx = registers[nRegId][31:24];
					nRx = 8'hxx;
				end
			{STATE_TXREGVAL, CMD_ANY}:  // transmit register value cont'd
		      begin
				   nState = ( byteId == 2'd3 ) ? STATE_IDLE : state;    
					nRegId = regId;
				   { dontcare, nByteId } = byteId + 1;
					case (byteId) 
						2'd0: nTx = registers[regId][23:16];
						2'd1: nTx = registers[regId][15:8];
						2'd2: nTx = registers[regId][7:0];
						2'd3: nTx = 8'hxx;
					endcase
					nRx = 8'hxx;
				end

			{STATE_IDLE, CMD_WRREG}:  // write register command
		      begin 
				   nState = STATE_RXREGVAL;    
					nRegId = rx[3:0];
				   nByteId = 2'd0;
					nTx = 8'hxx;
					nRx = rx;
				end
         {STATE_RXREGVAL, CMD_ANY}:  // receive register value
		      begin
				   nState = (byteId == 2'd3 ) ? STATE_IDLE : state;    
					nRegId = regId;
				   {dontcare, nByteId} = byteId + 1;
					nTx = 8'hxx;
					nRx = rx;
				end

			default: 
		      begin
					nState = STATE_IDLE;
					nRegId = 4'bxxxx;
				   nByteId = 2'dx;
					nTx = 8'hxx;
					nRx = 8'hxx;
				end
		endcase

   // FSM current state logic
   always @(posedge sysClk or posedge usrReset)
		if( usrReset )
			begin
				state <= STATE_IDLE;
				regId <= 4'bxxxx;
				byteId <= 2'dx;
			end  
		else
			if ( rxValid )
				begin
					state <= nState;
					regId <= nRegId;
					byteId <= nByteId;
				end

	// flatten the 2D registers array into two 1D arrays
	// (2D arrays need to be passed as 1D vector between modules)
	genvar nn;
	wire [31:0] roRegs2D[0:nrROregs-1];
	generate
		for ( nn = 0; nn < nrRWregs; nn = nn + 1)
			begin :nnRW
				assign rwRegs1D[32*nn+31:32*nn] = registers[nn];  // flatten
			end
		for ( nn = 0; nn < nrROregs; nn = nn + 1)
			begin :nnRO
				assign roRegs2D[nn] = roRegs1D[32*nn+31:32*nn];  // inflate
			end
	endgenerate
		
   // Data path: for next, current state and output logic
   always @(posedge sysClk or posedge usrReset)
		if( usrReset )
			begin
				for ( ii = 0; ii < 16; ii = ii + 1 )
					registers[ii] <= 32'b0;
				tx <= 8'hx;
			end  
		else
			if ( rxValid )
				case (state) 
					STATE_IDLE: // tx register value for CMD_WRREG
						begin
							for ( ii = 0; ii < nrROregs; ii = ii + 1 )
								registers[ii+nrRWregs] <= roRegs2D[ii];
							tx <= nTx;
						end
					STATE_TXSTATUS,
					STATE_TXREGVAL:
						tx <= nTx;
					STATE_RXREGVAL:
						begin
							case (byteId)
								0: registers[regId][31:24] <= nRx;
								1: registers[regId][23:16] <= nRx;
								2: registers[regId][15: 8] <= nRx;
								3: registers[regId][ 7: 0] <= nRx;
							endcase
						end
				endcase
	
endmodule
