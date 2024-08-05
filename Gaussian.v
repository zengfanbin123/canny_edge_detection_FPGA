//input image size :512*640
//
//output image size : 510*638
//the filter on the below 
/* [1 2 1    
    2 4 2
    1 2 1]*/
// and the final, right shift for 4 

//latency  = 2*clock period

module Gaussianfilter#(
    parameter WIDTH  = 640,     // col lenth of the image
	parameter DEPTH = 512,		// row lenth
    parameter FIFO_SUM  = 2,        // FIFO nums    
    parameter KERNEL_SIZE = 3,
	parameter DATA_WIDTH = 16
)
(
    input       clk,       //50MHz clock
    input       rst_n,          
    input       start,          //the signal of the matrix 
    input       data_valid,		    
    input       matrix_clken,	   

    //input data
    //input       data_valid,
    input  	[DATA_WIDTH - 1:0]	matrix_p11,         
    input 	[DATA_WIDTH - 1:0]	matrix_p12,
    input 	[DATA_WIDTH - 1:0]	matrix_p13,
    input 	[DATA_WIDTH - 1:0]	matrix_p21,
    input 	[DATA_WIDTH - 1:0]	matrix_p22,
    input 	[DATA_WIDTH - 1:0]	matrix_p23,
    input 	[DATA_WIDTH - 1:0]	matrix_p31,
    input 	[DATA_WIDTH - 1:0]	matrix_p32,
    input 	[DATA_WIDTH - 1:0]	matrix_p33,
    output      ready,   // the signal of the calculation  
    output      start_sync,    
    //output      data_valid,
    output  reg [DATA_WIDTH - 1:0] filter_Data      //the filter data
);

reg  [19:0]  temp;
reg cal_finish;
//delay one clock period
// the final calculation of filter
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        temp <= 20'b0;
        cal_finish <= 1'b0;
    end
    else if (start == 1 ) begin
        if( matrix_clken&&(~data_valid) )begin 
                temp <= matrix_p11 + matrix_p12*2 + matrix_p13 +matrix_p21*2 + matrix_p22*4 + matrix_p23*2 + matrix_p31 + matrix_p32*2 + matrix_p33;
                cal_finish <= 1'b1;
        end
        else begin
            cal_finish <= 1'b0;
            temp <= 20'b0;
        end
    end
    else begin
            cal_finish <= 1'b0;
            temp <= 20'b0;
        end
end

//delay one clock period
//filter_Data = matrix_out[19:4]; 
reg en_ready;
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n ) begin
        filter_Data <= 16'b0;
        en_ready <= 1'b0;
    end
    else if (start && cal_finish)begin
        filter_Data <= temp[19:4];
        en_ready <= 1'b1;
    end
    else begin 
        en_ready <= 1'b0;
        filter_Data <= 16'b0;
    end
end



reg [1:0] delay_start;
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n ) begin 
        delay_start <= 2'b0;
    end        
    else begin 
        delay_start <= {delay_start[0],start}; 
    end
  
end

assign start_sync = delay_start[1];
assign ready = en_ready == 1? 1:0;


endmodule
