/* Control stage 4 of pipeline (Write to reg file)

	Input:
		clk							: clock signal
		inst							: 32-bit current instruction
		cpsr							: 32-bit condition controller				
		result						: 32-bit result of calculation
		memdata						: 32-bit output data from memory
		
	Output:
		regwr							: write signal for reg file
		regaddrIn					: 4-bit input address for reg file
		regdataIn					: 32-bit input data for reg file
*/		
module stage4(
	input wire clk, 
	input wire [31:0] inst,
	input wire [31:0] cpsr,
	input wire [31:0] result,
	input wire [31:0] memdata,
	
	output wire regwr,
	output wire [3:0] regaddrIn,
	output wire [31:0] regdataIn
	);

	wire [3:0] cond, op, rn, rd, rm; 
	wire [11:0] operand;
	wire [7:0] out1, out2, out3, out4, out5;
	wire b, l, t, s, ldr, str, p, u, bit, w;
	wire [23:0] offset;
	reg condition;
	wire [31:0] branchimm;
	
	
	// Temporary variables
	reg [3:0] tregaddrIn; 
	reg [31:0] tregdataIn;
	reg tregwr;
	
	assign regaddrIn 		= tregaddrIn;
	assign regwr 			= tregwr;
	assign regdataIn = tregdataIn;
	

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
			
	
	
	// Cycling through the states of the operations
	always @(*) begin		
		tregwr = 0; tregaddrIn = 0; tregdataIn = 0;		
		if (ldr || str) begin
			if (condition) begin
				if (ldr) begin
					tregaddrIn = rd;
					tregwr = 1'b1;
					if (bit) tregdataIn = {24'b0, memdata[7:0]};
					else tregdataIn = memdata;
				end
				else begin
					if (w) begin
						tregaddrIn = rn;
						if (u)										
							tregdataIn = result;
						else tregdataIn = result;
					end
				end
			end
		end
		else begin
			if (b) begin
				if (condition) begin
					
					if (l) begin
						//register file connection
						tregaddrIn = 4'b1110; //if there is BL, store to register 14
						tregdataIn = result; //connect to pc
						tregwr = 1'b1;
					end
				end
			end
			else begin
				tregdataIn = result;
				case (op)
				4'b0000: begin // AND
							end
							
				4'b0001: begin // EOR *
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b0010: begin // SUB *
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b0011: begin // RSB *
							end
				4'b0100: begin // ADD *
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b0101: begin // ADC *
							end
				4'b0110: begin // SBC *
							end
				4'b0111: begin // RSC *
							end
							
				4'b1000: begin // TST
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b1001: begin// TEQ
							end
							
				4'b1010: begin// CMP
							end
							
				4'b1011: begin// CMN
							end
							
				4'b1100: begin // ORR *
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b1101: begin// MOV
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b1110: begin // BIC *										
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
							
				4'b1111: begin // MVN
								tregaddrIn = rd; tregwr = 1;
								//tregdataIn = ALUresult;
							end
				endcase
			end
		end
	  end
endmodule 