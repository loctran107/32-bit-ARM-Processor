/*	Control the input and utilization of memory and register file
	Input:
		clk							: clock signal
		pc								: 32-bit program counter
		state							: 2-bit value corresponding to 4 phases
		op								: 4-bit opcode of operations
		b								: branch signal
		l								: branch link signakl
		t								: type of operand, 1 if value and 0 if register
		s								: condition modifying signal
		ldr/str						:	load/store signal
		p								: pre/post indexing style
		u								: offset increment/decrement, 1 if increment, 0 otherwise
		bit							: 1 if load/store is bit, 0 if word
		w								: 1 if ldr/str write back to register, 0 otherwise
		offset						: 24-bit offset for branch
		cond, rn, rd, rm			: 4-bit condition code - rn - rd - rm
		operand						: 12-bit operand
		regdata1, regdata2		: 32-bit output data from reg file
		memdata						: 32-bit output data from memory
		
	Output:
		regaddrIn					: 4-bit input address for reg file
		regaddrOut1, regaddrOut2: 32-bit output addresses for reg file
		regdataIn					: 32-bit input data for reg file
		regwr							: write signal for reg file
		regrd1, regrd2				: read signals for reg file
		
		memaddrIn					: 32-bit input address for memory
		memaddrOut					: 32-bit output address for memory
		memdataIn					: 32-bit input data for memory
		memwr							: write signal for mem file
		memrd							: read signals for memory
		
		bf								: branch flag, 1 if branch, 0 otherwise
		
*/
module cycles(
	input wire clk,
	input wire [31:0] pc,
	input wire [1:0] state,
	input wire [3:0] op,
	input wire b, l, t, s, ldr, str, p, u, bit, w,
	input wire [23:0] offset,
	input wire [3:0] cond, rn, rd, rm,
	input wire [11:0] operand,
	input wire [31:0] regdata1, regdata2, memdata,
	
	
	output wire [3:0] regaddrIn, 
	output wire [3:0] regaddrOut1, regaddrOut2, 
	output wire [31:0] regdataIn,
	output wire regwr, regrd1, regrd2,
	output wire [31:0] memaddrIn, memaddrOut, memdataIn,
	output wire memwr, memrd,
	output wire bf
	);
	
	// t = 0 => operand is register
	// t = 1 => operand is number
	// call ALU(op, value1, value2, results, cpsr)
	// not use ALU => op = 4'b0
	
	reg [31:0]  alu1, alu2,cpsr;
	wire [31:0] ALUresult, out_shift, out_rotate;
	reg [3:0] opcode;
	wire [3:0] newcond;
	reg [3:0]temp;
	reg condition, tbf;
	wire c_flag, c_flag2;
	
	// Temporary variables
	reg [3:0] tregaddrIn; 
	reg [3:0] tregaddrOut1, tregaddrOut2;
	reg [31:0] tregdataIn;
	reg tregwr, tregrd1, tregrd2;
	reg [31:0] tmemaddrIn, tmemaddrOut, tmemdataIn;
	reg tmemwr, tmemrd;
	
	assign regaddrIn 		= tregaddrIn;
	assign regaddrOut1 	= tregaddrOut1;
	assign regaddrOut2 	= tregaddrOut2;
	assign regdataIn 		= tregdataIn;
	assign regwr 			= tregwr;
	assign regrd1 			= tregrd1;
	assign regrd2 			= tregrd2;
	assign memaddrIn 		= tmemaddrIn;
	assign memaddrOut 	= tmemaddrOut;
	assign memdataIn 		= tmemdataIn;
	assign memwr 			= tmemwr;
	assign memrd 			= tmemrd;
	assign bf 				= tbf;

	//conditions
	localparam EQcc = 4'b0000;
	localparam NEcc = 4'b0001;
	localparam CScc = 4'b0010;
	localparam CCcc = 4'b0011;
	localparam MIcc = 4'b0100;
	localparam PLcc = 4'b0101;
	localparam VScc = 4'b0110;
	localparam VCcc = 4'b0111;
	localparam HIcc = 4'b1000;
	localparam LScc = 4'b1001;
	localparam GEcc = 4'b1010;
	localparam LTcc = 4'b1011;
	localparam GTcc = 4'b1100;
	localparam LEcc = 4'b1101;
	localparam ALcc = 4'b1110;

	// Set condition based on previous ALU result to determine whether to proceed with execution in the next step.
	always @(*) begin
		case (cond)
			EQcc: condition = cpsr[30];
			NEcc: condition = ~cpsr[30];
			CScc: condition = cpsr[29];
			CCcc: condition = ~cpsr[29];
			MIcc: condition = cpsr[31];
			PLcc: condition = ~cpsr[31];
			VScc: condition = cpsr[28];
			VCcc: condition = ~cpsr[28];
			HIcc: condition = cpsr[28] && ~cpsr[30];
			LScc: condition = ~cpsr[28] && cpsr[30];
			GEcc: condition = cpsr[31] == cpsr[28];
			LTcc: condition = cpsr[31] != cpsr[28];
			GTcc: condition = ~cpsr[30] && (cpsr[31] == cpsr[28]);
			LEcc: condition = cpsr[30] && (cpsr[31] != cpsr[28]);
			ALcc: condition = 1'b1;
			default: condition = 1'b1;
		endcase
	end
	
	// Shifter calls	
	shifter shifting (operand[11:4], regdata2, out_shift, c_flag); //carry bit of cpsr		
	rotate rotating(operand[11:8], operand[7:0], out_rotate, c_flag2); //carry bit of cpsr
	
	// ALU calls
	ALU calculation(opcode, alu1, alu2, ALUresult, newcond[3], newcond[2], newcond[1], newcond[0]);
	
	// Altering CPSR
	initial cpsr = 0;
	always @(*) begin
		if (s) cpsr = {newcond,cpsr[27:0]};
	end
	
	// Cycling through the states of the operations
	always @(*) begin
		tregaddrIn = 0; tregaddrOut1 = 0; tregaddrOut2 = 0; tregdataIn = 0;
		tregwr = 0; tregrd1 = 0; tregrd2 = 0; 
		tmemaddrIn = 0; tmemaddrOut = 0; tmemdataIn = 0; 
		tmemwr = 0; tmemrd = 0; 
		opcode = 0; alu1 = 0; alu2 = 0;
		tbf = 0;
		if (ldr || str) begin
			if (condition) begin
				case (state)
				2'b00: begin
				  //  fetch in main
						end
				2'b01: begin
				  // read register file
							if (ldr) begin
								tregaddrOut1 = rn;
								tregrd1 = 1'b1;
							end
							else begin
								tregaddrOut1 = rd;
								tregrd1 = 1'b1;
							end
							
						end
				2'b10: begin
							if (ldr) begin
								if (p) tmemaddrOut = regdata1 + operand;
								else tmemaddrOut = regdata1;
								tmemrd = 1'b1;
							end
							else begin
								tregaddrOut2 = rn;
								tregrd2 = 1'b1;
							end
						end
				2'b11: begin
				  // push and output
							if (ldr) begin
								tregaddrIn = rd; //stage 4
								tregwr = 1'b1;
								if (bit) tregdataIn = {24'b0, memdata[7:0]};
								else tregdataIn = memdata;
							end
							else begin
								if (p) tmemaddrIn = regdata2 + operand;
								else tmemaddrIn = regdata2;
								tmemwr = 1'b1;
								
								if (bit) tmemdataIn = {4{regdata1[7:0]}};
								else tmemdataIn = regdata1;
								
								if (w) begin
									tregaddrIn = rn;
									if (u)										
										tregdataIn = regdata2 + operand;
									else tregdataIn = regdata2 - operand;
								end
							end
						end
				endcase
			end
		end
		else begin
			if (b) begin
				if (condition) begin
					tbf = 1'b1;
					if (l) begin
						//register file connection
						tregaddrIn = 4'b1110; //if there is BL, store to register 14
						tregdataIn = pc; //connect to pc
						tregwr = 1'b1;
					end
				end
			end
			else
				case (op)
				4'b0000: begin // AND
								case (state)
								2'b00: begin
								  //  fetch in main
										end
								2'b01: begin
								  // read register file
										end
								2'b10: begin
								  // shift
										end
								2'b11: begin
								  // push and output
										end
								endcase
							end
				4'b0001: begin // EOR *
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin
											opcode = 4'b0001;
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate; // send to ALU
											else alu2 = out_shift; // send to 
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
											
										end
								endcase
							end
				4'b0010: begin // SUB *
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin
											opcode = 4'b0010;
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate; // send to ALU
											else alu2 = out_shift; // send to ALU
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
										end
								endcase
							end
				4'b0011: begin // RSB *
								case (state)
								2'b00: begin
										end
								2'b01: begin
										end
								2'b10: begin
										end
								2'b11: begin
										end
								endcase
							end
				4'b0100: begin // ADD *
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin	
											opcode = 4'b0100;
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate; // send to ALU
											else alu2 = out_shift; // send to ALU
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
										end
								endcase
							end
				4'b0101: begin // ADC *
								case (state)
								2'b00: begin
										end
								2'b01: begin
										end
								2'b10: begin
										end
								2'b11: begin
										end
								endcase
							end
				4'b0110: begin // SBC *
								case (state)
								2'b00: begin
										end
								2'b01: begin
										end
								2'b10: begin
										end
								2'b11: begin
										end
								endcase
							end
				4'b0111: begin // RSC *
								case (state)
								2'b00: begin
										end
								2'b01: begin
										end
								2'b10: begin
										end
								2'b11: begin
										end
								endcase
							end
				4'b1000: begin // TST
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin
											opcode = 4'b1000;											
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate; // send to ALU
											else alu2 = out_shift; // send to ALU
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
										end
								endcase
							end
				4'b1001: begin// TEQ
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin
											opcode = 4'b1001;
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate; // send to ALU
											else alu2 = out_shift; // send to ALU
										end
								2'b11: begin
										end
								endcase
							end
				4'b1010: begin// CMP
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin
											opcode = 4'b1010;
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate;
											else alu2 = out_shift; // send to ALU
										end
								2'b11: begin
										end
								endcase
							end
				4'b1011: begin// CMN
								case (state)
								2'b00: begin
										end
								2'b01: begin
										end
								2'b10: begin
										end
								2'b11: begin
										end
								endcase
							end
				4'b1100: begin // ORR *
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rn; tregrd1 = 1;
											if (!t) begin
												tregaddrOut2 = rm; tregrd2 = 1;
											end
										end
								2'b10: begin
											opcode = 4'b1100;
											alu1 = regdata1; // send to ALU
											if (t) alu2 = out_rotate; // send to ALU
											else alu2 = out_shift; // send to ALU
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
										end
								endcase
							end
				4'b1101: begin// MOV
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rm; tregrd1 = 1;	
										end
								2'b10: begin
											//enable the ALU for the work
											opcode = 4'b1101;
											alu1 = rd; //MOV to the destination register
											alu2 = regdata1; //operand 2	
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin 
										end
								endcase
							end
				4'b1110: begin // BIC *
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rm; tregrd1 = 1;
											tregaddrOut2 = rn; tregrd2 = 1;
										end
								2'b10: begin
											opcode = 4'b1110;
											alu1 = regdata1;
											alu2 = regdata2;											
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
										end
								endcase
							end
				4'b1111: begin // MVN
								case (state)
								2'b00: begin
										end
								2'b01: begin
											tregaddrOut1 = rm; tregrd1 = 1;				
										end
								2'b10: begin
											//enable the ALU for the work
											opcode = 4'b1111;
											alu1 = rd; //MVN to the destination register
											alu2 = regdata1; //operand 2	
											
											tregaddrIn = rd; tregwr = 1;
											tregdataIn = ALUresult;
										end
								2'b11: begin
										end
								endcase
							end
				endcase
		end
	end
endmodule


module cycle_testbench();
	reg clk;
	reg [31:0] pc;
	reg [1:0] state;
	reg [3:0] op;
	reg b, l, t, s, ldr, str, p, u, bit, w;
	reg [23:0] offset;
	reg [3:0] cond, rn, rd, rm;
	reg [11:0] operand;
	reg [31:0] regdata1, regdata2, memdata;
	
	
	wire [3:0] regaddrIn; 
	wire [31:0] regaddrOut1, regaddrOut2, regdataIn;
	wire regwr, regrd1, regrd2;
	wire [31:0] memaddrIn, memaddrOut, memdataIn;
	wire memwr, memrd;
	wire bf;
	
	cycles dut(clk, pc, state, op, b, l, t, s, ldr, str, p, u, bit, w, offset, cond, rn, rd, rm, operand, regdata1, regdata2, memdata,
						 regaddrIn, regaddrOut1, regaddrOut2, regdataIn, regwr, regrd1, regrd2, 
						 memaddrIn, memaddrOut, memdataIn, memwr, memrd, bf); 
	
	// Set up the inputs to the design. Each line is a clock cycle.
	integer i;
	initial begin
		
		//ADD instruction test
		pc <= 32'h0; cond <= 4'b1110; rn <= 4'b0100; rd <= 4'b0100; rm <= 4'b0001; operand <= 11'b1; 
		op <= 4'b0100; b <= 0; l <= 0; t <= 1; s <= 1; state <= 2'b00;  #10;
																									state <= 2'b01;  #10;
																									state <= 2'b10;  #10;
																									state <= 2'b11;  #10;
									
		//SUB instruction test
		pc <= 32'h4; cond <= 4'b1110; rn <= 4'b1011; rd <= 4'b1101; rm <= 4'b0000; operand <= 11'b10000; op <= 4'b0010; b <= 0; l <= 0; t <= 1; s <= 0; offset <= 24'b010010111101000000010000; state <= 2'b00;  #10;
																																																		 state <= 2'b01;  #10;
																																																		 state <= 2'b10;  #10;
																																																		 state <= 2'b11;  #10;
		
		//B instruction test
		pc <= 32'h8; cond <= 4'b1110; rn <= 4'b0; rd <= 4'b0; rm <= 4'b0; operand <= 12'b100010101110; op <= 4'b0; b <= 1; l <= 0; t <= 1; s <= 0; offset <= 24'b100010101110; state <= 2'b00;  #10;
																																																		 state <= 2'b01;  #10;
																																																		 state <= 2'b10;  #10;
																																																		 state <= 2'b11;  #10;
		
		//BL instruction test
		pc <= 32'hC; cond <= 4'b1110; rn <= 4'b0; rd <= 4'b0; rm <= 4'b0; operand <= 12'b100000101100 ; op <= 4'b0; b <= 1; l <= 1; t <= 1; s <= 0; offset <= 24'b100010101110; state <= 2'b00;  #10;
																																																		 state <= 2'b01;  #10;
																																																		 state <= 2'b10;  #10;
																																																		 state <= 2'b11;  #10;
  end
endmodule

/*
1110_00_1_0100_0_0100_0100_00000000_0001 (E2844001)
add r4, r4, #1, 0
11100010010010111101000000010000 (E24BD010)
sub sp(r13), fp(r11), #16, 0
11101010000000000000100010101110 (EA0008AE)
B 0x0008ae
11101011000000000011100000101100 (EB00382C)
BL 0x00382c
*/