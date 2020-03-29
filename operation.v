/* Control overall operation with pipelines
	
	Input:
		clk							: clock signal
		inst0							: 32-bit current instruction
		pc								: 32-bit program counter		
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
		
		hf, hf2, hf3				: flags to stall for 3 cycles to resolve hazards
*/

module operation(
	input wire clk,
	input wire [31:0] inst0,
	input wire [31:0] pc,
	input wire [31:0] regdata1, regdata2, memdata,	
	
	output wire [3:0] regaddrIn, 
	output wire [3:0] regaddrOut1, regaddrOut2, 
	output wire [31:0] regdataIn,
	output wire regwr, regrd1, regrd2,
	output wire [31:0] memaddrIn, memaddrOut, memdataIn,
	output wire memwr, memrd,
	output wire hf, hf2, hf3, bf
	);
	
	reg [31:0] inst1, inst2, inst3, inst4;
	
	wire [31:0] result, result2;
	
	reg [31:0] result3, result4, tmemdataIn;
	wire s, h_flag, h_flag_1, h_flag_2;
	reg h_flag2, h_flag3;
	wire [3:0] newcond;
	reg [31:0] pc1, pc2, pc3;
	reg [31:0] regdata1_3, regdata2_3;	

	reg [31:0] cpsr, cpsr3, cpsr4;
	
	always @(posedge clk) begin
		if ((!h_flag) && (!h_flag2) && (!h_flag3)) begin
			inst1 <= inst0;
			inst2 <= inst1;
			pc1 <= pc;
			pc2 <= pc1;
		end
		else	inst2 <= 32'b0;
		inst3 <= inst2;
		inst4 <= inst3;
		result3 <= result;
		result4 <= result3;
		h_flag2 <= h_flag;
		h_flag3 <= h_flag2;
		regdata1_3 <= regdata1;
		regdata2_3 <= regdata2;
		tmemdataIn <= result2;
		cpsr3 <= cpsr;
		cpsr4 <= cpsr3;
		//regdata1_3 <= regdata1_2;
		//regdata2_3 <= regdata2_2;
	end
	
	// Altering CPSR
	initial cpsr = 0;
	always @(*) begin
		if (s) cpsr = {newcond,cpsr[27:0]};
	end
	
	assign hf = h_flag;
	assign hf2 = h_flag2;
	assign hf3 = h_flag3;
//	assign bf = b_flag;
	assign memdataIn = tmemdataIn;
	
	// Hazard detection
	hazard haz(inst1, inst2, h_flag_1);
	hazard haz2(inst0, inst2, h_flag_2);
	
	assign h_flag = (h_flag_1 || h_flag_2);
	
	stage0 zero(clk, inst0, cpsr, bf);
	
	stage1 one(clk, inst1, cpsr, regrd1, regrd2, regaddrOut1, regaddrOut2);
	
	stage2 two(clk, pc2, inst2, cpsr, regdata1, regdata2, result2, result, s, newcond);
	
	stage3 three(clk, inst3, cpsr3, regdata1_3, regdata2_3, memwr, memrd, memaddrIn, memaddrOut);//, memdataIn);
	
	stage4 four(clk, inst4, cpsr4, result4, memdata, regwr, regaddrIn, regdataIn);
endmodule
		