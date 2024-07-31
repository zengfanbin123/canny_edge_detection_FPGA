//使用移位寄存器完成3*3 矩阵模块

// define  row num = WIDTH   col num  = DEPTH
module Shift_RAM_3X3_gaussian#(
    parameter WIDTH  = 512,     // col lenth of the image
	parameter DEPTH = 640,		// row lenth
    parameter FIFO_SUM  = 2,        // FIFO nums    
    parameter KERNEL_SIZE = 3,
	parameter DATA_WIDTH = 16
)(
	//global signals
	input 					clk,						
	input 					rst_n,
	//Image data prepred to be processd
	input 					start,
	//input 					data_sync,		//data synchronous signal
	input 					data_en,		//Prepared Image data output/capture enable clock
	input 			[DATA_WIDTH - 1:0]	per_img_Y,	//Prepared Image brightness input
	
	//Image data has been processd
	output					matrix_clken,	//Prepared Image data output/capture enable clock	
	output					data_valid,		//shift_data move to the WIDTH - 1 ,and there are two clock peroid data is invalid
	output					ready_en,	    //data synchronous signal			
	output 	reg 	[DATA_WIDTH - 1:0]	matrix_p11,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p12,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p13,	//3X3 Matrix output
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p21,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p22,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p23,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p31,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p32,						
	output 	reg		[DATA_WIDTH - 1:0]	matrix_p33					
    );
	
//----------------------------------------------

wire 	[DATA_WIDTH - 1:0] 	row1_data;//frame data of the 1th row
wire 	[DATA_WIDTH - 1:0]	row2_data;//frame data of the 2th row
reg 	[DATA_WIDTH - 1:0] 	row3_data;//frame data of the 3th row


always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		row3_data <= 16'b0;
	else begin
		if(start)
			row3_data <= per_img_Y;
		else
			row3_data <= row3_data;
		end
end

//----------------------------------------------------------
//module of shift ram for row data
wire	shift_clk_en = data_en;
//Shift_RAM_3X3_16bit1
// IP core : shift ram
// width :16bits  depth: 512
// initial value = 16'h0000
// synchronous setting : clear data
c_shift_ram_1 u1_Shift_RAM_3X3_16bit (
   .D(row3_data),        // input wire [DATA_WIDTH - 1 : 0] D
  .CLK(clk&shift_clk_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row2_data)        // output wire [DATA_WIDTH - 1 : 0] Q
);

//Shift_RAM_3X3_16bit2
c_shift_ram_1 u2_Shift_RAM_3X3_16bit (
  .D(row2_data),        // input wire [DATA_WIDTH - 1 : 0] D
  .CLK(clk&shift_clk_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row1_data)        // output wire [DATA_WIDTH - 1 : 0] Q
);
//-------------------------------------------
//per_clken delay clk	
reg [1:0]	per_clken_r;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		per_clken_r <= 2'b0;
	else 
		per_clken_r <= {per_clken_r[0], data_en};	 
end
wire read_clken ;
assign read_clken = per_clken_r[1];

//counts  matrix output pixel
reg [19:0] count;
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 20'b0;
	  end
	else if((count == WIDTH * DEPTH + 3 ))
		count <= 20'b0;	
	else if(data_en )begin 
		count <= count + 1;
		//matrix_clken <= 1'b0;	 
    end
end

reg [9:0]  row;
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		row <= 10'b0;
	  end
	else if((row == 10'd511))
		row <= 10'b0;	
	else if(matrix_clken)begin 
		row <= row + 1;
		//matrix_clken <= 1'b0;	 
    end
end



// when the pixel counter is bigger then  the (delay + pixel nums),then output valid 
assign 	matrix_clken = (count > (WIDTH*FIFO_SUM+KERNEL_SIZE - 1) + 2)?1:0;
assign 	data_valid = (row > 509)?1:0;

reg [2:0] delay_start;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		delay_start <= 2'b0;
	else 
		delay_start <= {delay_start[1:0], data_en};	 
end
assign ready_en = delay_start[2];


//---------------------------------------------------------------------
/****************************************
(1)read data from shift_RAM
(2)calculate the gaussian
(3)steady data after sobel generate
******************************************/
//wire 	[23:0] 	matrix_row1 = {matrix_p11, matrix_p12,matrix_p13};//just for test
//wire 	[23:0]	matrix_row2 = {matrix_p21, matrix_p22,matrix_p23};
//wire 	[23:0]	matrix_row3 = {matrix_p31, matrix_p32,matrix_p33};
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		{matrix_p11, matrix_p12, matrix_p13} <= 48'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 48'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 48'h0;
	end
//	else if(read_frame_href)begin
	else if(read_clken)begin//shift_RAM data read clock enbale 
			{matrix_p11, matrix_p12, matrix_p13} <= {matrix_p12, matrix_p13, row1_data};//1th shift input
			{matrix_p21, matrix_p22, matrix_p23} <= {matrix_p22, matrix_p23, row2_data};//2th shift input 
			{matrix_p31, matrix_p32, matrix_p33} <= {matrix_p32, matrix_p33, row3_data};//3th shift input 
		end
	else begin
		{matrix_p11, matrix_p12, matrix_p13} <= {matrix_p11, matrix_p12, matrix_p13};
		{matrix_p21, matrix_p22, matrix_p23} <= {matrix_p21, matrix_p22, matrix_p23};
		{matrix_p31, matrix_p32, matrix_p33} <= {matrix_p31, matrix_p32, matrix_p33};
		end
//	end
/* 	else begin
		{matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
		end */
end	
	
endmodule