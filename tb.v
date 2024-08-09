`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/10 15:40:23
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: S
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_sobel();


//reg define
reg clk ;
reg rst_n ;
reg frame;
reg row_valid;
//reg rx ;
reg [15:0] data_mem [640*512-1:0] ; //data_mem是一个存储器，相当于一个ram
reg [15:0] data;

reg [15:0] padding_data;
//读取sim文件夹下面的data.txt文件，并把读出的数据定义为data_mem
initial
$readmemh("E:/20231213_120326Raw.txt",data_mem);

//时钟、复位信号
initial begin
    clk = 1'b1 ;
    rst_n = 1'b0 ;
    frame = 1'b0;
    row_valid = 1'b0;
    data = 16'b0;
    padding_data = 16'b0;
    #10
    rst_n = 1'b1;
    #10
    frame = 1'b1;
    
end

always #10 begin
    clk = ~clk;
    //flag = ~flag;
end
reg delay_row;

always @ (posedge clk or negedge rst_n) begin 
    if(!rst_n) 
        delay_row <= 1'b0;
    else 
        delay_row <= row_valid;
end

initial begin 
    integer row;
    integer col;
    integer in_val; //invalid data

    for(row = 0; row < 512; row = row + 1)begin 
        row_valid <= 1'b1;   
        for(col = 0; col < 640; col = col + 1) begin 
            #20 data <= data_mem[row*640 + col] ;
        end
        row_valid <= 1'b0;
        for(in_val = 0; in_val  < 80; in_val  = in_val + 1) begin
            #20  data <= 16'b0;
        end 
    end
    frame <= 1'b0;
end


//initial begin
//    integer row;
//    integer col;
//    integer in_val; //invalid data
    
//    for(row = 0; row < 504; row = row + 1)begin 
          
//        for(col = 0; col < 640; col = col + 1) begin 
//            #50 padding_data <= row + col ;
//        end
        
//        for(in_val = 0; in_val  < 80; in_val  = in_val + 1) begin
//            #50  padding_data <= 16'b0;
//        end 
//    end
    
//end


//wire [15 : 0] row_padding;
//wire row_pad_start_sync,row_pad_data_sync;
//Padding_Row #(
//    .DATA_WIDTH(16),
//    .WIDTH(640),
//    .DEPTH(504),
//    .N(4)
//) thresh_padding_row(
//    .clk(clk),
//    .rst_n(rst_n),
//    .start(frame),		
//    .data_en(delay_row),
//    .fmap_raw(padding_data),
//    .fmap_pad(row_padding),
//    .start_sync(row_pad_start_sync),	
//    .data_en_sync(row_pad_data_sync)
//);




//-------------sobel_inst-------------
wire ready;
wire [15:0] out_data;
wire b_fval_sync,b_lval_sync;
canny_edge_detection test(
    .clk(clk),      //input clk 20MHz  
    .rst_n(rst_n),  //input reset signal  0-invalid   1 -valid     
    .b_fval(frame),  // input frame valid data
    .b_lval(delay_row),      // input row valid data
    .in_data(data),  // input [15:0] data
    
    .b_fval_sync(b_fval_sync),
    .b_lval_sync(b_lval_sync),
    .out_data(out_data) // output wire [15:0] data

);

endmodule
