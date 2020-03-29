// detect if two instructions in 
// sequence would cause data hazard

module hazard(
	input wire [31:0] inst1, inst2, // inst2 should be the first inst read
	output wire haz				 	  // inst1 is the second 
	);
	
	wire b1, b2, l1, l2, t1, t2, s1, s2, ldr1, ldr2, str1, str2, p1, p2, u1, u2, bit1, bit2, w1, w2;
	wire [23:0] offset1, offset2;
	wire [3:0] cond1, cond2, op1, op2, rn1, rn2, rd1, rd2, rm1, rm2;
	wire [11:0] operand1, operand2;
	wire [31:0] branchimm1, branchimm2;
	// temp haz flag
	reg thaz;
	
	assign haz = thaz;
	
	decode decoder1(inst2, b1, l1, t1, s1, ldr1, str1, p1, u1, bit1, w1, offset1, cond1, op1, rn1, rd1, rm1, operand1, branchimm1);
	decode decoder2(inst1, b2, l2, t2, s2, ldr2, str2, p2, u2, bit2, w2, offset2, cond2, op2, rn2, rd2, rm2, operand2, branchimm2);
	
	
	always @(*) begin	
		
		// op1 is EOR, SUB, ADD, ORR, MOV, BIC, MVN
		if (ldr1 || op1 == 4'b0001 || op1 == 4'b0010 || op1 == 4'b0100 || op1 == 4'b1100 ||
						op1 == 4'b1101 || op1 == 4'b1110 ||op1 == 4'b1111) begin
			if (str2 && (rd1 == rd2)) // handle when str2 is true 
				thaz = 1'b1;
			else if (ldr2 || op2 == 4'b0001 || op2 == 4'b0010 || op2 == 4'b0100 || op2 == 4'b1100 || 
							op2 == 4'b1110 || op2 == 4'b1000 || op2 == 4'b1001 || op2 == 4'b1111 || 
							op2 == 4'b1101 ||op2 == 4'b1111) begin
				// set hazard to true
				if (rd1 == rn2 || ( (!t2) && rd1 == rm2)) 
					thaz = 1'b1; 
				else 
					thaz = 1'b0;
			end else 
				thaz = 1'b0;
		end else begin
			thaz = 1'b0;
		end
	end
endmodule 

module hazard_testbench();
	reg clk;
	reg [31:0] inst1, inst2;
	wire haz;
	
	hazard dut(inst1, inst2, haz);
	
	// Set up the clock.
	always begin
		clk = 1; #2; clk = 0; #2;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin
																																		#4;
		// add r0, r4, #0											// sub r2, r3, #7						flag = 0
		inst1 <= 32'b11100010100001000000000000000000;	inst2 <= 32'b11100010010000110010000000000111; 	#4;
		// add r0, r4, #1											// sub r4, r3, #7						flag = 1
		inst1 <= 32'b11100010100001000000000000000001;	inst2 <= 32'b11100010010000110100000000000111; 	#4;
		// add r0, r4, #9											// sub r2, r3, #7						flag = 0
		inst1 <= 32'b11100010100001000000000000001001;	inst2 <= 32'b11100010010000110010000000000111; 	#4;
		// sub r2, r3, r7											// add r7, r4, #1						flag = 1
		inst1 <= 32'b11100000010000110010000000000111;	inst2 <= 32'b11100010100001000111000000000001; 	#4;
		// add r0, r4, #9											// MOV r7, r3							flag = 0
		inst1 <= 32'b11100010100001000000000000001001;	inst2 <= 32'b11100001101000000111000000000011; 	#4;
		// sub r2, r3, r7											// MOV r7, r3							flag = 1
		inst1 <= 32'b11100000010000110010000000000111;	inst2 <= 32'b11100001101000000111000000000011; 	#4;
		// add r0, r4, #0											// sub r2, r3, #7						flag = 0
		inst1 <= 32'b11100010100001000000000000000000;	inst2 <= 32'b11100010010000110010000000000111; 	#4;
		// MOV r7, r3												// sub r3, r2, #7						flag = 1
		inst1 <= 32'b11100001101000000111000000000011;	inst2 <= 32'b11100010010000100011000000000111; 	#4;
		
		// MOV r7, r3												// LDR r5, [r2]						flag = 0
		inst1 <= 32'b11100001101000000111000000000011;	inst2 <= 32'b11100110001100100101000000000000; 	#4;
		// MOV r7, r5												// LDR r5, [r2]						flag = 1
		inst1 <= 32'b11100001101000000111000000000101;	inst2 <= 32'b11100110001100100101000000000000; 	#4;
		// add r5, r4, #0											// STR r5, [r2]						flag = 0
		inst1 <= 32'b11100010100001000101000000000000;	inst2 <= 32'b11100110001000100101000000000000; 	#4;
		// STR r5, [r2]											// add r5, r4, #0						flag = 1
		inst1 <= 32'b11100110001000100101000000000000;	inst2 <= 32'b11100010100001000101000000000000; 	#4;
												// 000000000000											// 000000000000
																					  //1110 00 1 0100 0 0100 0101 000000000000
	end
endmodule