/* Condition decoded instructions for output ports
	
	Input:
		b,l	 : B, BL indcator
		t		 : type of operand, 1 if number and register otherwise
		offset : offset for branch
		op		 : opcode
		rn, rd : rn, rd from instructions
		rm		 : operand register
		operand: full operand code
	
	Output:
		out1-5 : output data for debug port 3-7
*/		
module interpreter(
	input wire b, l, t, 
	input wire [23:0] offset,
	input wire [3:0] op, rn, rd, rm,
	input wire [11:0] operand,
	output wire [23:0] out1, out2, out3, out4, out5
	);
	
	reg [7:0] t1, t2, t3, t4; // temp vars
	
	assign out1 = t1;
	assign out2 = t2;
	assign out3 = t3;
	assign out4 = t4;
	assign out5 = t;
	
	always @(*) begin
		t3 = 1'b0; t4 = 1'b0;
		if (b) begin
			if (l)
				t1 = 5'b10000;
			else
				t1 = 5'b10001;
			t2 = offset[23:16];
			t3 = offset[15:8];
			t4 = offset[7:0];
		end
		else begin
			t1 = op;
			case (op)	
				4'b0000: begin // AND
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0001: begin // EOR *
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0010: begin // SUB *
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0011: begin // RSB *
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0100: begin // ADD *	
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0101: begin // ADC *	
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0110: begin // SBC *
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b0111: begin // RSC *
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b1000: begin // TST
								t2 = rd;
								if (t) 
									t3 = operand[7:0];
								else
									t3 = rm;
							end
				4'b1001: begin// TEQ
								t2 = rd;
								if (t) 
									t3 = operand[7:0];
								else
									t3 = rm;
							end
				4'b1010: begin// CMP
								t2 = rd;
								if (t) 
									t3 = operand[7:0];
								else
									t3 = rm;
							end
				4'b1011: begin// CMN
								t2 = rd;
								if (t) 
									t3 = operand[7:0];
								else
									t3 = rm;
							end
				4'b1100: begin // ORR *
								t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b1101: begin// MOV
								t2 = rd;
								if (t) 
									t3 = operand[7:0];
								else
									t3 = rm;
							end
				4'b1110: begin // BIC *
							t2 = rd;
								t3 = rn;
								if (t) 
									t4 = operand[7:0];
								else
									t4 = rm;
							end
				4'b1111: begin // MVN
								t2 = rd;
								if (t) 
									t3 = operand[7:0];
								else
									t3 = rm;
							end
			endcase
		end
	end
endmodule

module interpreter_testbench();
	reg clk,b, l, t; 
	reg [23:0] offset;
	reg [3:0] op, rn, rd, rm;
	reg [11:0] operand;
	wire [23:0] out1, out2, out3, out4, out5;
	
	interpreter dut(b, l , t, offset, op, rn, rd, rm, operand, 
												out1, out2, out3, out4, out5);

	// Set up the clock.
	always begin
		clk = 1; #5; clk = 0; #5;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	integer i;
	initial begin
																	#10;
		b <= 0; l <= 0; t <= 1; op <= 4'b1101;
		rn <= 0; rd <= 4'b0111; rm <= 0; operand <= 0;	#200;
  end
endmodule