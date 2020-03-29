/*
  Manipulate the registers

  Input:
    clk		: clock signal
    addrIn  : 32-bit input address
    addrOut : 32-bit output address
    dataIn  : 32-bit input data
    wr      : write signal
    rd1		: read signals

  Output:
    dataOut: data at the requested address
*/
module memory(
	input wire clk,
	input wire [31:0] addrIn,
	input wire [31:0] addrOut,
	input wire [31:0] dataIn,
	input wire wr, rd,
	output wire [31:0] dataOut) ;
	
	reg [7:0] mem [31:0];
	reg [31:0] out;
	
	reg [7:0] a,b,c,d;
	
	integer i;		

	assign dataOut = {a,b,c,d};
	
	// Initial Block
	initial begin
		for (i=0; i < 32; i = i + 1) 
			mem[i] = 8'b0;
	end
	
//	always @(posedge clk) begin
//		if (wr) begin
//			mem[addrIn] <= dataIn[7:0];
//			
//			if (addrIn < (~32'b0)) mem[addrIn + 32'b1] <= dataIn[15:8];
//			else mem[addrIn - (~32'b0) + 32'b1] <= dataIn[15:8];
//			
//			if (addrIn + 32'b1 < (~32'b0)) mem[addrIn + 32'b10] <= dataIn[23:16];
//			else mem[addrIn - (~32'b0) + 32'b10] <= dataIn[23:16]; 
//			
//			if (addrIn + 32'b10 < (~32'b0)) mem[addrIn + 32'b11] <= dataIn[31:24];
//			else mem[addrIn - (~32'b0) + 32'b11] <= dataIn[31:24];
//		end
//		if (rd) begin
//			out[7:0] <= mem[addrOut];
//			
//			if (addrOut < (~32'b0)) out[15:8] <= mem[addrOut + 32'b1];
//			else out[15:8] <= mem[addrOut - (~32'b0) + 32'b1];
//			
//			if (addrOut + 32'b1 < (~32'b0)) out[15:8] <= mem[addrOut + 32'b10];
//			else out[23:16] <= mem[addrOut - (~32'b0) + 32'b10];
//			
//			if (addrOut + 32'b10 < (~32'b0)) out[15:8] <= mem[addrOut + 32'b11];
//			else out[31:24] <= mem[addrOut - (~32'b0) + 32'b11];
//		end
//	end

	always @(posedge clk) begin
		if (wr) begin
			mem[addrIn] <= dataIn[7:0];
			
			if (addrIn < 31) mem[addrIn + 1] <= dataIn[15:8];
			else mem[addrIn - 31 + 1] <= dataIn[15:8];
			
			if (addrIn + 1 < 31) mem[addrIn + 2] <= dataIn[23:16];
			else mem[addrIn - 31 + 2] <= dataIn[23:16]; 
			
			if (addrIn + 2 < 31) mem[addrIn + 3] <= dataIn[31:24];
			else mem[addrIn - 31 + 3] <= dataIn[31:24];
		end
		if (rd) begin
			d <= mem[addrOut];
			
			if (addrOut < 31) c <= mem[addrOut + 1];
			else c <= mem[addrOut - 31 + 1];
			
			if (addrOut + 1 < 31) b <= mem[addrOut + 2];
			else b <= mem[addrOut - 31 + 2];
			
			if (addrOut + 2 < 31) a <= mem[addrOut + 3];
			else a <= mem[addrOut - 31 + 3];
		end
	end
endmodule

module memory_testbench();
	reg clk, wr, rd;
	reg [31:0] addrIn, addrOut;
	reg [31:0] dataIn;
	wire[31:0] dataOut;	

	memory dut(clk, addrIn, addrOut, dataIn, wr, rd, dataOut);

	// Set up the clock.
	always begin
		clk = 1; #5; clk = 0; #5;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	integer i;
	initial begin
																#10;
		addrIn <= 4; addrOut <= 4; dataIn <= 20;
		wr <= 1; rd <= 1;                        	#10;
																#10;
						dataIn <= 30;                 #10;
																#10;
  end
endmodule