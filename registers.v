/*
  Manipulate the registers

  Input:
    clk		: clock signal
    addrIn  : 4-bit input address
    addrOut1: 4-bit output address
	 addrOut2: 4-bit output address
    dataIn  : 32-bit input data
    wr      : write signal
    rd1, rd2: read signals

  Output:
    dataOut1: data at the requested address #1
	 dataOut2: data at the requested address #2
*/
module registers(
	input wire clk,
	input wire [3:0] addrIn,
	input wire [3:0] addrOut1, addrOut2,
	input wire [31:0] dataIn,
	input wire wr, rd1, rd2,
	output wire [31:0] dataOut1, dataOut2) ;
	
	reg [31:0] ram [0:15];
	reg [31:0] out1, out2;
	
	integer i;		

	assign dataOut1 = out1;
	assign dataOut2 = out2;
	
	// Initial Block
	initial begin
		for (i=0; i < 16; i = i + 1) 
			ram[i] = 32'b0;
	end
	
	always @(posedge clk) begin
		if (wr)
			ram[addrIn] <= dataIn;
		if (rd1)
			out1 <= ram[addrOut1];
		if (rd2)
			out2 <= ram[addrOut2];
	end
endmodule

module registers_testbench();
	reg clk, wr, rd1, rd2;
	reg [3:0] addrIn, addrOut1, addrOut2;
	reg [31:0] dataIn;
	wire[31:0] dataOut1, dataOut2;	

	registers dut(clk, addrIn, addrOut1, addrOut2, dataIn, wr, rd1, rd2, dataOut1, dataOut2);

	// Set up the clock.
	always begin
		clk = 1; #5; clk = 0; #5;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	integer i;
	initial begin
																					#10;
		addrIn <= 4; addrOut1 <= 4; addrOut2 <= 4; dataIn <= 20;
		wr <= 1; rd1 <= 1; rd2 <= 1;                        		#10;
																					#10;
						dataIn <= 30;                            		#10;
																					#10;
  end
endmodule
