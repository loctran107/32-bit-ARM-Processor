/* Break instructions to parts

	Input:
		inst: 32-bit instruction
	
	Output:
		bout, lout	: B and BL indicator
		otout			: operand type. 1 if number and 0 otherwise
		offset		: offset for branch
		cond			: condition code
		op				: opcode
		rn, rd, rm	: rn, rd and rm from instruction
		operand		: full operand code
*/
module decode(
	input wire [31:0] inst,
	output wire bout,lout, otout, sout, ldr, str, p, u, bit, w,
	output wire [23:0] offset,
	output wire [3:0] cond, op, rn, rd, rm,
	output wire [11:0] operand,
	output wire [31:0] branchimm
	);
	
	reg [3:0] r1_temp, r2_temp;
	reg [2:0] type;
	reg optype;
	reg b, l;
	reg ldr_temp, str_temp;

	assign branchimm[31:26] = {6{inst[23]}};
   assign branchimm[25:2] = inst[23:0];
   assign branchimm[1:0] = 2'b00;
	assign cond = inst[31:28];
	assign op = inst[24:21];
	assign operand = inst[11:0];
	assign otout  = inst[25];
	assign sout = inst[20];
	assign offset = inst[23:0];
	
	// STR LDR exclusive
	assign p = inst[24];
	assign u = inst[23];
	assign bit = inst[22];
	assign w = inst[21];
  
	assign rn = inst[19:16];
	assign rd = inst[15:12];
	assign rm = inst[3:0];
	assign bout = b;
	assign lout = l;
	assign ldr = ldr_temp;
	assign str = str_temp;
	
	always @ ( * ) begin
		
		type = inst[27:26];
		b = 1'b0; l = 1'b0; ldr_temp = 1'b0; str_temp = 1'b0;
		
		case (type)
			2'b00: begin
					end	
			2'b01: begin
						ldr_temp = inst[20];
						str_temp = ~inst[20];
						
					end
			default: begin
							b = 1'b1;
							if (inst[24]) l = 1'b1;
							else l = 1'b0;
						end
		endcase
	end
endmodule


//   case(condcode)
    // 4'b0000: cond = 0; // EQ
    // 4'b0001: cond = 1; // NE
    // 4'b0010: cond = 2; // CS/HS
    // 4'b0011: cond = 3; // CC/LO
    // 4'b0100: cond = 4; // MI
    // 4'b0101: cond = 5; // PL
    // 4'b0110: cond = 6; // VS
    // 4'b0111: cond = 7; // VC
    // 4'b1000: cond = 8; // HI
    // 4'b1001: cond = 9; // LS
    // 4'b1010: cond = 10; // GE
    // 4'b1011: cond = 11; // LT
    // 4'b1100: cond = 12; // GT
    // 4'b1101: cond = 13; // LE
    // 4'b1110: cond = 14; // AL
    // 4'b1111: cond = 15; // --
  // endcase
  //

  // assign condition = ["EQ","NE","CS/HS","CC/LO","MI","PL","VS","VC","HI","LS","GE","LT","GT","LE","AL","-"];
  // assign operation = ["AND","EOR","SUB","RSB","ADD","ADC","SBC","RSC","TST","TEQ","CMP","CMN","ORR","MOV","BIC","MVN"];

module decode_testbench();
	reg clk;	
	reg [31:0] inst;
	wire bout,lout, otout, sout, ldr, str, p, u, bit, w;
	wire [31:0] offset;
	wire [3:0] cond, op, rn, rd, rm;
	wire [11:0] operand;
	wire [31:0] branchimm;

	decode dut(inst, bout, lout, otout, sout, ldr, str, p, u, bit, w, offset, cond, op, rn, rd, rm, operand, branchimm);

	// Set up the clock.
	always begin
		clk = 1; #5; clk = 0; #5;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	integer i;
	initial begin
																		#10;
		inst <= 32'b11100011101000000111000000000000;	#10;
																		#10;
  end
endmodule
