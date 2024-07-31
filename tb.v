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
reg data_valid;
//reg rx ;
reg [320:0] str1 ; //错误类型的变量也可以为可支持的 string 类型
reg [15:0] data_mem [640*512-1:0] ; //data_mem是一个存储器，相当于一个ram
reg [15:0] data;


//读取sim文件夹下面的data.txt文件，并把读出的数据定义为data_mem
initial
$readmemh("E:/20231213_120326Raw.txt",data_mem);

//时钟、复位信号
initial begin
    clk = 1'b1 ;
    rst_n = 1'b0 ;
    flag = 1'b1;
    str1 = 321'b0;
    #80
    rst_n = 1'b1 ;
    data_valid = 1'b1;
end

always #10 begin
    clk = ~clk;
    flag = ~flag;
end


initial begin 
    integer i;
    #60 ;
    for(i = 0; i < 640*512; i = i+1)begin 
        #20
        data <= data_mem[i] ;
        
    end
end

//-------------sobel_inst-------------
wire ready;
wire [15:0] out_data;
top test(
    clk,rst_n,
    data,flag,data_valid,
    ready,
    out_data
);

//open/close file
   integer fd1;
   integer err1;
initial begin
  if(ready ==1 ) begin 
        integer k;
        fd1 = $fopen("E:/cannydata.txt", "w");   
        err1 = $ferror(fd1, str1);   
        for(k=0; k<504*632-1; k=k+1) begin 
            $fdisplay(fd1, "New data1: %d", out_data); 
            #20;     
        end 
        $fclose(fd1);
      end
end

endmodule
