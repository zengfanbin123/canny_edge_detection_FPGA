`timescale 1ns / 1ns
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
reg flag;
//reg rx ;
//reg [15:0] data_mem [640*512-1:0] ; //data_mem是一个存储器，相当于一个ram
reg [15:0] data;
reg [25:0] grad;
wire outflag;
wire [15:0] filter_Data;
//3X3 Matrix output
wire 	[15:0]	matrix_p11;					
wire	[15:0]	matrix_p12;						
wire	[15:0]	matrix_p13;	
wire    [15:0]	matrix_p21;						
wire 	[15:0]	matrix_p22;						
wire	[15:0]	matrix_p23;						
wire	[15:0]	matrix_p31;						
wire	[15:0]	matrix_p32;						
wire    [15:0]	matrix_p33;

//读取sim文件夹下面的data.txt文件，并把读出的数据定义为data_mem
// initial
// $readmemh("E:/test.txt",data_mem);

//时钟、复位信号
initial begin
    clk = 1'b0 ;
    rst_n = 1'b0 ;
    flag = 1'b0;
   
    #200
    rst_n = 1'b1 ;
end

always #10 begin
    clk = ~clk;
    flag = ~flag;
end

initial begin 
    integer i;
    for(i = 0;i<640*512;i =i+1)begin 
        #20
        data <= {18'b0, {$random()} % (256)} ;
    end
end

//-------------sobel_inst-------------

Shift_RAM_3X3_grad #(
    .WIDTH(510),     // line lenth of the image
    .FIFO_SUM(2),        // FIFO nums    
    .KERNEL_SIZE(3) 
)test (
    clk,rst_n,
    flag,
    data,
    outflag,
    matrix_p11,
    matrix_p12,
    matrix_p13,
    matrix_p21,
    matrix_p22,
    matrix_p23,
    matrix_p31,
    matrix_p32,
    matrix_p33
);

wire[1:0] direct;
wire  grad_ready;
Gradientfilter test_grad(
    clk,rst_n,outflag,
    matrix_p11,
    matrix_p12,
    matrix_p13,
    matrix_p21,
    matrix_p22,
    matrix_p23,
    matrix_p31,
    matrix_p32,
    matrix_p33,
    grad_ready,
    grad
);

wire matrix_ready;
wire [25:0] grad_p11;
wire [25:0] grad_p12;
wire [25:0] grad_p13;
wire [25:0] grad_p21;
wire [25:0] grad_p22;
wire [25:0] grad_p23;
wire [25:0] grad_p31;
wire [25:0] grad_p32;
wire [25:0] grad_p33;
Shift_RAM_3X3_NO_MAX grad_data(
    clk,rst_n,
    grad_ready,grad,
    matrix_ready,
    grad_p11,
    grad_p12,
    grad_p13,
    grad_p21,
    grad_p22,
    grad_p23,
    grad_p31,
    grad_p32,
    grad_p33
);
wire ready;
none_LocalMax_value test_none(
    clk,rst_n,
    matrix_ready,
    grad_p11,
    grad_p12,
    grad_p13,
    grad_p21,
    grad_p22,
    grad_p23,
    grad_p31,
    grad_p32,
    grad_p33,
    ready,
    filter_Data
);
endmodule
