module cpu(
	input wire clk,
	input wire nreset,
	output wire led,
	output wire [23:0] debug_port1,
	output wire [23:0] debug_port2,
	output wire [23:0] debug_port3,
	output wire [23:0] debug_port4,
	output wire [23:0] debug_port5,
	output wire [23:0] debug_port6,
	output wire [23:0] debug_port7
	);

	wire reset;
	wire [31:0] regdata1, regdata2, memdata;
	wire [31:0] inst, inst0;
	reg [31:0] inst_full [100:0];
	reg [31:0] pc;
	reg [1:0] state;
	
	// Reg files and memory controller
	wire [3:0] regaddrIn, regaddrOut1, regaddrOut2;
	wire regwr, regrd1, regrd2, memwr, memrd;
	wire [31:0] regdataIn, memaddrIn, memaddrOut, memdataIn; 
	wire bf, h_flag;
	reg h_flag2, h_flag3;
	wire [31:0] branchimm;
	wire [3:0] cond, op, rn, rd, rm; 
	wire [11:0] operand;
	wire b, l, t, s, ss, ldr, str, p, u, bit, w;
	wire [23:0] offset;
	
	// Controls the LED on the board.
	assign led = 1'b1;
	assign reset = ~nreset;
	
	// Read in the instruction file
	initial begin
		$readmemb("inst.txt", inst_full);
	end
	
	assign inst0 = inst_full[pc];
	
	decode decoder(inst0, b, l, t, ss, ldr, str, p, u, bit, w, offset, cond, op, rn, rd, rm, operand, branchimm);
//
//	cycles operation(clk, pc, state, op, b, l, t, s, ldr, str, p, u, bit, w, offset, cond, rn, rd, rm, operand, regdata1, regdata2, memdata,
//						 regaddrIn, regaddrOut1, regaddrOut2, regdataIn, regwr, regrd1, regrd2, 
//						 memaddrIn, memaddrOut, memdataIn, memwr, memrd, bf)

/*
	operation run(clk, inst, pc, regdata1, regdata2, memdata,
						 regaddrIn, regaddrOut1, regaddrOut2, regdataIn, regwr, regrd1, regrd2, 
						 memaddrIn, memaddrOut, memdataIn, memwr, memrd, h_flag, h_flag2, h_flag3, bf);
*/	

	registers RAM(clk, regaddrIn, regaddrOut1, regaddrOut2, regdataIn, regwr, regrd1, regrd2, regdata1, regdata2);
	
	memory MEM(clk, memaddrIn, memaddrOut, memdataIn, memwr, memrd, memdata);

//	interpreter inter(b, l, t, offset, op, rn, rd, rm, operand, out1, out2, out3, out4, out5);

//----------------------------------------------operation module----------------------------------------------
	reg [31:0] inst1, inst2, inst3, inst4;

	wire [31:0] result, result2;

	reg [31:0] result3, result4, tmemdataIn;
	wire h_flag_1, h_flag_2;
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

//	assign hf = h_flag;
//	assign hf2 = h_flag2;
//	assign hf3 = h_flag3;
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

//--------------------------------------------------------------------------------------------------------------------
	
	always @(posedge clk) begin
		if (reset) begin
			pc <= 32'b0;
		end
		else begin
			if ((!h_flag) && (!h_flag2) && (!h_flag3)) begin
				if (!bf) pc <= pc + 1;
				else pc <= pc + ((branchimm + 4'b1000) >> 2);
			end				
		end
	end
	
	
	// These are how you communicate back to the serial port debugger.
	assign debug_port1 = pc << 2;
	
/*	assign debug_port1 = 0;
	assign debug_port2 = 1;
	assign debug_port3 = 2;
	assign debug_port4 = 3;
	assign debug_port5 = 4;
	assign debug_port6 = 5;
	assign debug_port7 = 6;
*/	

	// Logic for register fields
	assign debug_port2 = regdataIn;
	assign debug_port3 = regdata1;
	assign debug_port4 = regdata2;
	assign debug_port5 = memaddrIn;
	assign debug_port6 = memdataIn;	
	assign debug_port7 = memdata;
	
endmodule

module cpu_testbench();
	reg clk, nreset;
	wire led;
	wire [7:0] debug_port1,debug_port2, debug_port3, debug_port4, 
				  debug_port5, debug_port6, debug_port7;

	cpu dut(clk, nreset, led, debug_port1, debug_port2, debug_port3, 
					 debug_port4, debug_port5, debug_port6, debug_port7);

	// Set up the clock.
	always begin
		clk = 1; #5; clk = 0; #5;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	integer i;
	initial begin
						#10;
		nreset <= 0;	#10;
		nreset <= 1; #700;
  end
endmodule

