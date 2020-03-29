/* Control stage 3 of pipeline (Write/read on memory)

	Input:
		clk							: clock signal
		inst							: 32-bit current instruction
		cpsr							: 32-bit condition controller		
		regdata1, regdata2		: 32-bit output data from reg file
		
	Output:
		memwr							: write signal for mem file
		memrd							: read signals for memory
		memaddrIn					: 32-bit input address for memory
		memaddrOut					: 32-bit output address for memory
*/		
module stage3(
	input wire clk, 
	input wire [31:0] inst,
	input wire [31:0] cpsr,
	input wire [31:0] regdata1, regdata2,
	
	output wire memwr, memrd,
	output wire [31:0] memaddrIn, memaddrOut
	);				

	wire [3:0] cond, op, rn, rd, rm; 
	wire [11:0] operand;
	wire [7:0] out1, out2, out3, out4, out5;
	wire b, l, t, s, ldr, str, p, u, bit, w, bf;
	wire [23:0] offset;
	wire [31:0] branchimm;		
	reg condition;
	
	// Temporary variables
	reg [31:0] tmemaddrIn, tmemaddrOut;
	reg tmemwr, tmemrd;
	
	
	assign memaddrIn 		= tmemaddrIn;
	assign memaddrOut 	= tmemaddrOut;
	assign memwr 			= tmemwr;
	assign memrd 			= tmemrd;

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
	
	always @(*) begin
		tmemaddrIn = 0; tmemaddrOut = 0; 
		tmemwr = 0; tmemrd = 0; 
		if (ldr || str) begin
			if (condition) begin
				if (ldr) begin
					if (p) tmemaddrOut = regdata1 + operand;
					else tmemaddrOut = regdata1;
					tmemrd = 1'b1;
				end
				else begin
					if (p) tmemaddrIn = regdata2 + operand;
					else tmemaddrIn = regdata2;
					tmemwr = 1'b1;					
					if (w) begin
					end
				end
			end
		end
		else begin
			if (b) begin
				if (condition) begin
					if (l) begin
					end
				end
			end
			else
				case (op)
				4'b0000: begin // AND
							end
				4'b0001: begin // EOR *
							end
				4'b0010: begin // SUB *
							end
				4'b0011: begin // RSB *
							end
				4'b0100: begin // ADD *
							end
				4'b0101: begin // ADC *
							end
				4'b0110: begin // SBC *
							end
				4'b0111: begin // RSC *
							end
				4'b1000: begin // TST
							end
				4'b1001: begin// TEQ
							end
				4'b1010: begin// CMP
							end
				4'b1011: begin// CMN
							end
				4'b1100: begin // ORR 
							end
				4'b1101: begin// MOV
							end
				4'b1110: begin // BIC
							end
				4'b1111: begin // MVN
							end
				endcase
		end
	end
endmodule 