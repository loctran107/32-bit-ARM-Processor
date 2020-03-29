/* ALU function
	
	Input:
		ALUop		: 4-bit ALU opcode
		oprd1		: operand #1
		oprd2		: operand #2
	
	Output:
		result	: result of the calculation
		negative	: 1 if the result is negative, 0 if positive
		zero		: 1 if the result is 0, 0 otherwise
		overflow	: 1 if the calculation overflew, 0 otherwise
*/
module ALU #(parameter width = 32)(

	input [3:0] ALUop, //4 bit opcode
	input [width-1:0] oprd1,
	input [width-1:0] oprd2,
	output reg [width-1:0] result,

	//status flags
	output reg negative,
	output reg zero,
	output reg carry_bit,
	output reg overflow
	);


	reg [width:0] temp_result; //take into account of the sign bit

	always @(*) begin
		carry_bit = 1'b0;
		overflow = 1'b0;
		negative = 1'b0;
		zero = 1'b0;
		temp_result = 33'b0;
		result = 32'b0;

		case(ALUop)
			4'b0100: begin //ADD
							temp_result = oprd1 + oprd2;
							result = temp_result[width-1:0];

							carry_bit = temp_result[width];
							
							//signed arithmetic
							if((~oprd1[width-1] && ~oprd2[width-1] && temp_result[width-1]) || (oprd1[width-1] && oprd2[width-1] && ~temp_result[width-1]))
								overflow = 1'b1;
							if(temp_result[width-1]) negative = 1'b1;
						end
	
			4'b0010: begin  //SUB
							temp_result = oprd1 - oprd2;
							result = temp_result[width-1:0];

							carry_bit = temp_result[width];
							
							//signed arithmetic
							if((~oprd1[width-1] && oprd2[width-1] && temp_result[width-1]) || (oprd1[width-1] && ~oprd2[width-1] && temp_result[width-1]) 
							|| (~oprd1[width-1] && oprd2[width-1] && ~temp_result[width-1]) || (oprd1[width-1] && ~oprd2[width-1] && ~temp_result[width-1]))
								overflow = 1'b1;
							if(temp_result[width-1]) negative = 1'b1;
						end
			4'b1010: begin //CMP
							result = oprd1 - oprd2;  //results is discarded later
							if (result[width - 1]) negative = 1'b1; //negative
						end

			4'b1000: begin //TST
							result = oprd1 & oprd2; //result is discarded later
							if (result[width - 1]) negative = 1'b1;
						end

			4'b1001: begin //TEQ
							result = oprd1 ^ oprd2;  //result is discarded later
							if (result[width - 1]) negative = 1'b1;
						end

			4'b1110: begin  //BIC (bit clear)
							result = oprd1 & ~oprd2;
							if (result[width - 1]) negative = 1'b1;
						end

			4'b1100: begin //ORR
							result = oprd1 | oprd2;
							if (result[width - 1]) negative = 1'b1;
						end

			4'b0001: begin //EOR
							result = oprd1 ^ oprd2; //different from TEQ
							if (result[width - 1]) negative = 1'b1;
						end

			4'b1101: begin //MOV
							result = oprd2;
							if (result[width - 1]) negative = 1'b1;
						end

			4'b1111: begin //MVN
							result = ~oprd2;
							if (result[width - 1]) negative = 1'b1;
						end
			default: begin end
		endcase
		if (result == 1'b0)
		zero = 1'b1;
	end


endmodule
