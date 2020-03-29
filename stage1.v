/* Control stage 1 of the pipelines (Read from reg file)

	Input:
		clk							: clock signal
		inst							: 32-bit current instruction		
		cpsr							: 32-bit condition controller

	Output:
		regrd1, regrd2				: read signals for reg file
		regaddrOut1, regaddrOut2: 32-bit output addresses for reg file
*/

module stage1(
	input wire clk, 
	input wire [31:0] inst,
	input wire [31:0] cpsr,
	output wire regrd1, regrd2,
	output wire [3:0] regaddrOut1, regaddrOut2
	);

	wire [3:0] cond, op, rn, rd, rm; 
	wire [11:0] operand;
	wire [7:0] out1, out2, out3, out4, out5;
	wire b, l, t, s, ldr, str, p, u, bit, w;
	wire [23:0] offset;
	wire [31:0] branchimm;
	reg condition;
	
	// Temporary variables
	reg [3:0] tregaddrOut1, tregaddrOut2;
	reg tregrd1, tregrd2;
	
	assign regrd1 = tregrd1;
	assign regrd2 = tregrd2;
	assign regaddrOut1 = tregaddrOut1;
	assign regaddrOut2 = tregaddrOut2;
	
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
		tregaddrOut1 = 0; tregaddrOut2 = 0;
		tregrd1 = 0; tregrd2 = 0; 
		if (ldr || str) begin
			if (condition) begin
				// read register 
				if (ldr) begin
					tregaddrOut1 = rn;
					tregrd1 = 1'b1;
				end
				else begin
					tregaddrOut1 = rd;
					tregrd1 = 1'b1;
					tregaddrOut2 = rn;
					tregrd2 = 1'b1;
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
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b0010: begin // SUB *
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b0011: begin // RSB *
	
							end
							
				4'b0100: begin // ADD *
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b0101: begin // ADC *
							
							end
							
				4'b0110: begin // SBC *
					
							end
							
				4'b0111: begin // RSC *
							
							end
							
				4'b1000: begin // TST
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b1001: begin// TEQ
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b1010: begin// CMP
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b1011: begin// CMN

							end
							
				4'b1100: begin // ORR *
								tregaddrOut1 = rn; tregrd1 = 1;
								if (!t) begin
									tregaddrOut2 = rm; tregrd2 = 1;
								end
							end
							
				4'b1101: begin// MOV
								tregaddrOut1 = rm; tregrd1 = 1;	
							end
							
				4'b1110: begin // BIC *
								tregaddrOut1 = rm; tregrd1 = 1;
								tregaddrOut2 = rn; tregrd2 = 1;
							end
							
				4'b1111: begin // MVN
								tregaddrOut1 = rm; tregrd1 = 1;				
							end
				endcase
		end
	end
endmodule 