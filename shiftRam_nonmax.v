module Shift_RAM_3X3_NO_MAX#(
  	parameter WIDTH = 512,
	parameter DEPTH = 636,
    parameter FIFO_SUM = 2,
    parameter KERNEL_SIZE = 3,
	parameter DATA_WIDTH = 26
)
(
	//global signals
	input 					clk,						
	input 					rst_n,							
	//Image data prepred to be processd
	input 					start,
	input 					data_en,//Prepared Image data output/capture enable clock
	input 			[DATA_WIDTH - 1:0]	per_img_Y,//Prepared Image brightness input
	//Image data has been processd
	output					matrix_clken,	//Prepared Image data output/capture enable clock
	output					data_valid,		//output data_valid
	output 					ready_en,		//sign of output
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


//counts  input  pixel
reg [19:0] count;
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 20'b0;
	  end
	else begin 
		if(count == (WIDTH* DEPTH + 2 )) begin
			count <= 20'b0;
		end	
		else if(data_en)begin 
			count <= count + 1;
    	end
		else	
		count <= count;
	end
end


//----------------------------------------------
//consume 1clk
wire 	[DATA_WIDTH - 1:0] 	row1_data;//frame data of the 1th row
wire 	[DATA_WIDTH - 1:0]	row2_data;//frame data of the 2th row
reg 	[DATA_WIDTH - 1:0] 	row3_data;//frame data of the 3th row

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		row3_data <= 26'b0;
	else begin
		if(start)
			row3_data <= per_img_Y;
		else
			row3_data <= row3_data;
		end
end
	

//debug for data
wire [1:0] direct1,direct2,direct3,direct4,direct5,direct6,direct7,direct8,direct9;
wire [23:0] grad1,grad2,grad3,grad4,grad5,grad6,grad7,grad8,grad9;
assign direct1 = {matrix_p11[25],matrix_p11[24]};
assign direct2 = {matrix_p12[25],matrix_p12[24]};
assign direct3 = {matrix_p13[25],matrix_p13[24]};
assign direct4 = {matrix_p21[25],matrix_p21[24]};
assign direct5 = {matrix_p22[25],matrix_p22[24]};
assign direct6 = {matrix_p23[25],matrix_p23[24]};
assign direct7 = {matrix_p31[25],matrix_p31[24]};
assign direct8 = {matrix_p32[25],matrix_p32[24]};
assign direct9 = {matrix_p33[25],matrix_p33[24]};
assign grad1 = {matrix_p11[23:0]};
assign grad2 = {matrix_p12[23:0]};
assign grad3 = {matrix_p13[23:0]};
assign grad4 = {matrix_p21[23:0]};
assign grad5 = {matrix_p22[23:0]};
assign grad6 = {matrix_p23[23:0]};
assign grad7 = {matrix_p31[23:0]};
assign grad8 = {matrix_p32[23:0]};
assign grad9 = {matrix_p33[23:0]};

//----------------------------------------------------------
//module of shift ram for row data
wire	shift_clk_en = start;

//Shift_RAM_3X3_16bit1
// IP core : shift ram
// width :26bits  depth: 512
// initial value = 26'b0
// synchronous setting : clear data
shift_ram_508 u1_Shift_RAM_3X3_26bit (
   .D(row3_data),        // input wire [25 : 0] D
  .CLK(clk&shift_clk_en),    // input wire  
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row2_data)        // output wire [25 : 0] Q
);

//Shift_RAM_3X3_16bit2
shift_ram_508 u2_Shift_RAM_3X3_26bit (
  .D(row2_data),        // input wire [25 : 0] D
  .CLK(clk&shift_clk_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row1_data)        // output wire [25 : 0] Q
);
//-------------------------------------------
// //per_clken delay 3clk	
// reg 	[1:0]	per_clken_r;
// always @(posedge clk or negedge rst_n)begin
// 	if(!rst_n)
// 		per_clken_r <= 2'b0;
// 	else 
// 		per_clken_r <= {per_clken_r[0], per_clken};	 
// end

//delay matrix shift sign 
reg per_clken_r;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		per_clken_r <= 1'b0;
	else 
		per_clken_r <=  start;	 
end
 
wire 	read_clken;
assign read_clken  = per_clken_r;

//count matrix_pixel output valid
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
	else	
		row <= row;
end


assign 	matrix_clken = (count>(WIDTH-4)*FIFO_SUM+KERNEL_SIZE )?1:0;
assign  data_valid = (row > 505 )?1:0;

reg [1:0] delay_start;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		delay_start <= 2'b0;
	else 
		delay_start <= {delay_start[0], start};	 
end
assign ready_en = delay_start[1];

//---------------------------------------------------------------------
/****************************************
(1)read data from shift_RAM
(2)caulate the sobel
(3)steady data after sobel generate
******************************************/
//wire 	[25:0] 	matrix_row1 = {matrix_p11, matrix_p12,matrix_p13};//just for test
//wire 	[25:0]	matrix_row2 = {matrix_p21, matrix_p22,matrix_p23};
//wire 	[25:0]	matrix_row3 = {matrix_p31, matrix_p32,matrix_p33};
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		{matrix_p11, matrix_p12, matrix_p13} <= 78'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 78'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 78'h0;
	end
//	else if(read_frame_href)begin
	else if(read_clken )begin//shift_RAM data read clock enbale 
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
		{matrix_p11, matrix_p12, matrix_p13} <= 111'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 111'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 111'h0;
		end */
end	
endmodule
