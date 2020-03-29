/* Control stage 2 of pipeline (Execute calculation)

	Input:
		clk							: clock signal
		pc								: 32-bit program counter	
		inst							: 32-bit current instruction
		cpsr							: 32-bit condition controller		
		regdata1, regdata2		: 32-bit output data from reg file
		
	Output:
		memdataIn					: 32-bit input data for memory
		result						: 32-bit result of calculation
		memwr							: write signal for mem file
		memrd							: read signals for memory
		sOut							: flag to change condition controller
		newcondOut					: 4-bit updated condition		
*/		
module stage2(
	input wire clk, 
	input wire [31:0] pc,
	input wire [31:0] inst,
	input wire [31:0] cpsr,
	input wire [31:0] regdata1, regdata2,
	
	output wire [31:0] memdataIn, result,
	output wire sOut,
	output wire [3:0] newcondOut
	);

	
	wire [3:0] cond, op, rn, rd, rm; 
	wire [11:0] operand;
	wire [7:0] out1, out2, out3, out4, out5;
	wire b, l, t, s, ldr, str, p, u, bit, w;
	wire [23:0] offset;	
	wire [31:0] branchimm;
	
	reg [31:0]  alu1, alu2;
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
	reg [31:0] tcpsr;
	
	
	assign memdataIn 		= tmemdataIn;
	assign result = tregdataIn;

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
	
	decode decoder(inst, b, l, t, s, ldr, str, p, u, bit, w, offset, cond, op, rn, rd, rm, operand, branchimm);
	ALU calculation(opcode, alu1, alu2, ALUresult, newcond[3], newcond[2], newcond[1], newcond[0]);
	
	// Shifter calls	
	shifter shifting (operand[11:4], regdata2, out_shift, c_flag); //carry bit of cpsr		
	rotate rotating(operand[11:8], operand[7:0], out_rotate, c_flag2); //carry bit of cpsr
	
	assign newcondOut = newcond;
	assign sOut = s;
	
	reg [31:0] tresult1, tresult2;
	always @(*) begin
		tregdataIn = 0;
		tmemdataIn = 0; 
		opcode = 0;
		alu1 = 0; alu2 = 0;
		
		if (ldr || str) begin
			if (condition) begin
				if (ldr) begin
				end
				else begin
					if (bit) tmemdataIn = {4{regdata1[7:0]}};
					else tmemdataIn = regdata1;
					if (w) begin
						if (u)										
							tregdataIn = regdata2 + operand;
						else tregdataIn = regdata2 - operand;
					end
				end
			end
		end
		else begin
			if (b) begin
				if (condition) begin
					if (l) begin
						tregdataIn = pc;
					end
				end
			end
			else 
				case (op)
				4'b0000:	begin end
				
				//memory result1, reg file result2
				
				4'b0001: begin //EOR *
								opcode = 4'b0001;
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate; // send to ALU
								else alu2 = out_shift; // send to 
								
								tregdataIn = ALUresult;
							end
				
				4'b0010: begin // SUB *
								opcode = 4'b0010;
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate; // send to ALU
								else alu2 = out_shift; // send to ALU
								
								tregdataIn = ALUresult;
							end
							
				4'b0011: begin // RSB *
							end
									
				4'b0100: begin // ADD *
								opcode = 4'b0100;
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate; // send to ALU
								else alu2 = out_shift; // send to ALU
								
								tregdataIn = ALUresult;
							end
							
				4'b0101: begin // ADC *
							end
							
				4'b0110: begin // SBC *
							end
							
				4'b0111: begin // RSC *
							end
							
				4'b1000: begin // TST
								opcode = 4'b1000;											
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate; // send to ALU
								else alu2 = out_shift; // send to ALU
								
								tregdataIn = ALUresult;
							end
							
				4'b1001: begin// TEQ
								opcode = 4'b1001;
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate; // send to ALU
								else alu2 = out_shift; // send to ALU
							end
							
				4'b1010: begin// CMP
								opcode = 4'b1010;
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate;
								else alu2 = out_shift; // send to ALU
								
							end
							
				4'b1011: begin// CMN
							end
							
				4'b1100: begin // ORR *
								opcode = 4'b1100;
								alu1 = regdata1; // send to ALU
								if (t) alu2 = out_rotate; // send to ALU
								else alu2 = out_shift; // send to ALU
								
								tregdataIn = ALUresult;
							end
				4'b1101: begin// MOV
								//enable the ALU for the work
								opcode = 4'b1101;
								alu1 = rd; //MOV to the destination register
								alu2 = regdata1; //operand 2	
								
								tregdataIn = ALUresult;
							end
							
				4'b1110: begin // BIC *
								opcode = 4'b1110;
								alu1 = regdata1;
								alu2 = regdata2;	

								tregdataIn = ALUresult;
							end

				4'b1111: begin // MVN
								//enable the ALU for the work
								opcode = 4'b1111;
								alu1 = rd; //MVN to the destination register
								alu2 = regdata1; //operand 2	
								
								tregdataIn = ALUresult;
							end
				endcase
			end
		end
endmodule 