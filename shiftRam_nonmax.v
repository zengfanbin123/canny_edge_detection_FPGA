module Shift_RAM_3X3_NO_MAX#(
  	parameter WIDTH = 512,
	parameter DEPTH = 636,
    parameter FIFO_SUM = 2,
    parameter KERNEL_SIZE = 3
)
(
	//global signals
	input 					clk,						
	input 					rst_n,							
	//Image data prepred to be processd
	input 					per_clken,//Prepared Image data output/capture enable clock
	input 			[25:0]	per_img_Y,//Prepared Image brightness input
	//Image data has been processd
	output					matrix_clken,	//Prepared Image data output/capture enable clock	
	//output					data_valid,
	output 	reg 	[25:0]	matrix_p11,						
	output 	reg		[25:0]	matrix_p12,						
	output 	reg		[25:0]	matrix_p13,	//3X3 Matrix output
	output 	reg		[25:0]	matrix_p21,						
	output 	reg		[25:0]	matrix_p22,						
	output 	reg		[25:0]	matrix_p23,						
	output 	reg		[25:0]	matrix_p31,						
	output 	reg		[25:0]	matrix_p32,						
	output 	reg		[25:0]	matrix_p33					
    );


//----------------------------------------------
//consume 1clk
wire 	[25:0] 	row1_data;//frame data of the 1th row
wire 	[25:0]	row2_data;//frame data of the 2th row
reg 	[25:0] 	row3_data;//frame data of the 3th row

wire readFIFO_en;
wire [25:0] fifo_out_data;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		row3_data <= 26'b0;
	else begin
		if(readFIFO_en)
			row3_data <= fifo_out_data;
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
wire	shift_clk_en = per_clken;

//Shift_RAM_3X3_16bit1
// IP core : shift ram
// width :26bits  depth: 508
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
 
wire 	read_clken;
assign read_clken  = per_clken?1:0;

//counts input fifo pixel
reg [9:0] fifo_pixel;
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fifo_pixel <= 20'b0;
	  end
	//Two adjacent input data are not zero
	else if(fifo_pixel > 10'd510 )
		fifo_pixel <= 10'd511;	
	else if(per_clken   )begin 
		fifo_pixel <= fifo_pixel + 1;
		//matrix_clken <= 1'b0;	 
    end
end 
assign readFIFO_en = fifo_pixel > 510 ?1:0;

//count mnatrix out pixel
reg [19:0] count;

always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 20'b0;
	  end
	//Two adjacent input data are not zero
	else if((count == (WIDTH-4) * DEPTH ))
		count <= 20'b0;	
	else if(per_clken == 1 && readFIFO_en)begin 
		count <= count + 1;
		//matrix_clken <= 1'b0;	 
    end
end


assign 	matrix_clken = (count>(WIDTH-4)*FIFO_SUM+KERNEL_SIZE )?1:0;

wire empty,full;


//fifo depth : 1024
bufffer_fifo non_max_fifo (
  .clk(clk),      // input wire clk
  .srst(~rst_n),    // input wire srst
  .din(per_img_Y),      // input wire [25 : 0] din
  .wr_en(per_clken),  // input wire wr_en
  .rd_en(readFIFO_en),  // input wire rd_en
  .dout(fifo_out_data),    // output wire [25 : 0] dout
  .full(full),    // output wire full
  .empty(empty)  // output wire empty
);

	 

//assign data_valid = ((cnt_row > WIDTH - KERNEL_SIZE)&&(matrix_clken==1)) ?0:1;	 


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
	else if(read_clken && per_clken)begin//shift_RAM data read clock enbale 
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
