module Shift_RAM_3X3_thresh#(
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
	input 			[15:0]	per_img_Y,//Prepared Image brightness input
	//Image data has been processd
	output					matrix_clken,	//Prepared Image data output/capture enable clock	
	output 	reg 	[15:0]	matrix_p11,						
	output 	reg		[15:0]	matrix_p12,						
	output 	reg		[15:0]	matrix_p13,	//3X3 Matrix output
	output 	reg		[15:0]	matrix_p21,						
	output 	reg		[15:0]	matrix_p22,						
	output 	reg		[15:0]	matrix_p23,						
	output 	reg		[15:0]	matrix_p31,						
	output 	reg		[15:0]	matrix_p32,						
	output 	reg		[15:0]	matrix_p33					
    );
	
//----------------------------------------------
//consume 1clk
wire 	[15:0] 	row1_data;//frame data of the 1th row
wire 	[15:0]	row2_data;//frame data of the 2th row
reg 	[15:0] 	row3_data;//frame data of the 3th row
 
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		row3_data <= 16'b0;
	else begin
		if(per_clken)
			row3_data <= per_img_Y;
		else
			row3_data <= row3_data;
		end
end
//----------------------------------------------------------
//module of shift ram for row data
wire	shift_clk_en = per_clken;
//Shift_RAM_3X3_16bit1
// IP core : shift ram
// width :16bits  depth: 510
// initial value = 16'h0000
// synchronous setting : clear data
shift_ram_510 u3_Shift_RAM_3X3_16bit (
   .D(row3_data),        // input wire [15 : 0] D
  .CLK(shift_clk_en&clk),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row2_data)        // output wire [15 : 0] Q
);

//Shift_RAM_3X3_16bit2
shift_ram_510 u4_Shift_RAM_3X3_16bit (
  .D(row2_data),        // input wire [15 : 0] D
  .CLK(shift_clk_en&clk),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row1_data)        // output wire [15 : 0] Q
);
//-------------------------------------------
//per_clken delay 3clk	
// reg 	[1:0]	per_clken_r;
// always @(posedge clk or negedge rst_n)begin
// 	if(!rst_n)
// 		per_clken_r <= 2'b0;
// 	else 
// 		per_clken_r <= {per_clken_r[0], per_clken};	 
// end
 
wire 	read_clken;
assign read_clken  = per_clken?1:0;

//counts pixel
reg [19:0] count;
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 20'b0;
	  end
	//Two adjacent input data are not zero
	else if((count == (WIDTH-4) * DEPTH ))
		count <= 20'b0;	
	else if(per_clken == 1  )begin 
		count <= count + 1;
		//matrix_clken <= 1'b0;	 
    end
end
assign 	matrix_clken = (count>(WIDTH-4)*FIFO_SUM+KERNEL_SIZE )?1:0;
//calculate the row and col data 
// start counting from 0
// when the row is bigger than 511, then there are two clock period data is unvalid 
reg [9:0] cnt_row;      //row  from  1 to 510 is valid
reg [9:0] cnt_col;      //col from 1 to 638 is valid
always @(posedge clk or negedge rst_n ) begin
    if(rst_n == 0) begin
        cnt_row <= 10'b0;   
        
    end     
    else if(cnt_row == WIDTH -2 ) begin 
        cnt_row <= 10'b0;
    end
    else if(matrix_clken == 1 ) begin
        cnt_row <= cnt_row + 1;        
    end
end

always @(posedge clk or negedge rst_n ) begin
    if(rst_n == 0) begin
        cnt_col <= 10'b0;   
        
    end     
    else if(cnt_row == WIDTH - 2) begin 
        cnt_col <=  cnt_col + 1;
    end
    else if((cnt_col == DEPTH) && (cnt_row == WIDTH -2) )  begin
        cnt_col <= 10'b0 ;        
    end
    else 
        cnt_col <= cnt_col;
end

//ssign data_valid = ((cnt_row > WIDTH - KERNEL_SIZE)&&(matrix_clken==1)) ?0:1;		 
//---------------------------------------------------------------------
/****************************************
(1)read data from shift_RAM
(2)caulate the sobel
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
