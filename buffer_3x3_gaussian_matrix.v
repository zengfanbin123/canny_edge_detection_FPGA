//use the 2 fifo for 3*3 gaussian_matrix
module moduleName  (
    input       clk_50MHz;
    input       rst_n;     
    input       start_flag;
	input [15:0] in_data,   //data input 
	
    //output 3*3 Matrix
    output [15:0] out0,
	output [15:0] out1,
	output [15:0] out2,
	output [15:0] out3,
	output [15:0] out4,
	output [15:0] out5,
	output [15:0] out6,
	output [15:0] out7,
	output [15:0] out8,

    //When the third element of the third line is inputted,the signal ready is OK
    output reg    ready
	);
	
	Shift_RAM_3X3 buffer_matrix(
		clk_50MHz,
		rst_n,
		start_flag,
		in_data,
		ready,
		out0,
		out1,
		out2,
		out3,
		out4,
		out5,
		out6,
		out7,
		out8
	);
	


endmodule 