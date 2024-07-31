/*
    use the matrix_x to get the gradient of x direction 
    use the matrix_y to get the gradient of y direction

    matrix_x             
    [ -1  0  1          
      -2  0  2              
      -1  0  1 ]         
    matrix_y
    [  1  2  1
       0  0  0
      -1 -2 -1]

    matrix M [
    p11 p12 p13
    p21 p22 p23
    p31 p32 p33
    ]

data  D [
    a11 a21 a31
    a12 a22 a32
    a13 a23 a33
    ] 

M = transpose(D) 
and the M is the input  really
*/
module Gradientfilter
#(
    parameter WIDTH = 510,
	parameter DEPTH = 636,
    parameter FIFO_SUM = 2,
    parameter KERNEL_SIZE = 3,
	parameter DATA_WIDTH = 16
) (
    input       clk,       //50MHz clock
    input       rst_n,          
    input       start,          //the signal of the matrix 
    input       data_valid,
    input       matrix_clken,
    input  	[15:0]	matrix_p11,         
    input 	[15:0]	matrix_p12,
    input 	[15:0]	matrix_p13,
    input 	[15:0]	matrix_p21,
    input 	[15:0]	matrix_p22,
    input 	[15:0]	matrix_p23,
    input 	[15:0]	matrix_p31,
    input 	[15:0]	matrix_p32,
    input 	[15:0]	matrix_p33,
    output          ready,   // the signal of the calculation      
    //output reg [1:0] direct,      //  the angle of the gradient
    output  [25:0]  grad_square        //  [25:24]represens direction [23:0]represnts gradient size  (x^2 + y^2) 
);


//calculate the row and col data 
// start counting from 0
// when the row is bigger than 511, then there are two clock period data is unvalid 
reg [9:0] cnt_row;      //row  from  1 to 510 is valid
reg [9:0] cnt_col;      //col from 1 to 638 is valid
reg  sign_row;          //if row == 510 sign_row = 1

always @(posedge clk or negedge rst_n ) begin
    if(rst_n == 0) begin
        cnt_row <= 10'b0;           
    end     
    else if(cnt_row == WIDTH ) begin 
        cnt_row <= 10'b0;
    end
    else if(start == 1 ) begin
        cnt_row <= cnt_row + 1;        
    end
end

always @(posedge clk or negedge rst_n ) begin
    if(rst_n == 0) begin
        cnt_col <= 10'b0;   
        
    end     
    else if(cnt_row == WIDTH - 1) begin 
        cnt_col <=  cnt_col + 1;
    end
    else if((cnt_col == DEPTH) && (cnt_row == WIDTH ) )  begin
        cnt_col <= 10'b0 ;        
    end
    else 
        cnt_col <= cnt_col;
end
//wire data_valid;
//assign data_valid = ((cnt_row > WIDTH - KERNEL_SIZE)&&(ready==1)) ?0:1;	


//signal of the gradient calculate finish
//gradient of x  and y irection belongs to  [-1000,1000]
reg x_ready,y_ready;
reg signed [15:0] y_grad;      //gradient of x direction  1bit of sign and  17bits of data 
reg signed [15:0] x_grad;      //gradient of y direction 
//wire [1:0] sign_x_y;        //low bit represent the x_gradident sign ,high bit represent the y_gradient sign
//calculate the gradient of x

//use one clock period to calculate
always@ ( posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        x_grad <= 15'b0;
        x_ready <= 1'b0;
     end
    else if(start == 1 && data_valid) begin
        x_grad <= matrix_p31 - matrix_p11 + (matrix_p32- matrix_p12)*2 + matrix_p33 - matrix_p13;
        x_ready <= 1'b1;
    end
    else begin 
        x_ready <= 1'b0;
        x_grad <= 15'b0;
    end 
end


//calculate the gradient of y
always@ ( posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y_grad <= 15'b0;
        y_ready <= 1'b0;
    end
    else if(start && data_valid) begin
        y_grad <= matrix_p11  + matrix_p31 + (matrix_p21 - matrix_p23)*2 - matrix_p13  - matrix_p33;
        y_ready <= 1'b1;
    end
    else begin 
        y_ready <= 1'b0;
        y_grad <= 15'b0;
    end 
end

//calculate the square of the gradient
wire [23:0] x_square,y_square;

assign x_square = x_grad[15] ? (-x_grad) * (-x_grad):x_grad * x_grad ; 
assign y_square = y_grad[15] ? (-y_grad) * (-y_grad):y_grad * y_grad ;


reg[23:0]grad_temp;
reg grad_finish;
always @(posedge clk or negedge rst_n) begin
    if(! rst_n ) begin
        grad_temp <= 24'b0;
        grad_finish <= 1'b0;
    end
    else if((x_ready )&&(y_ready ))begin
        grad_temp <= x_square + y_square;
        grad_finish <= 1'b1;
    end
    else begin
        grad_temp <= 24'b0;
        grad_finish <= 1'b0;
    end 
end


//delay grad_finish signal 
reg [21:0] delay_finish;
always @(posedge clk or negedge rst_n) begin
    if(! rst_n ) begin
        delay_finish <= 21'b0;
    end
    else 
        delay_finish <= {delay_finish[20:0],grad_finish}; 
end
wire delayed_grad;
assign delayed_grad = delay_finish[21];


// through the shiftRam to delay  grad_temp  21 clock period
wire[23:0] grad ;
c_shift_ram_2 delay_grad (
  .D(grad_temp),        // input wire [23 : 0] D
  .CLK(clk),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(grad)        // output wire [23 : 0] Q
);



//calculate the angle for gradient ,which will delay 22 clock period contrast to the  x_grad and y_grad 
wire radian_cal_begin;
assign radian_cal_begin = x_ready && y_ready;
wire  radian_cal_finish;
wire  [15:0]  radian_temp;


//latency = 22 clock period
// input require : two bits interge fiexed Fraction   
cordic_arctan arctan (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(radian_cal_begin),  // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata({y_grad,x_grad}),    // input wire [31 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(radian_cal_finish),            // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata({radian_temp})              // output wire [15 : 0] m_axis_dout_tdata
);



//direction of the gradient
//22.5*pai/180 transform into integer width 3  -> 16 000_00100000000
localparam N = 2'b00;          
localparam E = 2'b01;        
localparam NW = 2'b10;
localparam NE = 2'b11;

localparam ANGLE1 = 13'b1_1100_0000_0000;        //157.5/180*2^13 
localparam ANGLE2 = 13'b1_0100_0000_0000;        //112.5/180*2^13
localparam ANGLE3 = 13'b0_1100_0000_0000;        //67.5/180 *2^13
localparam ANGLE4 = 13'b0_0100_0000_0000;        //22.5/180 *2^13




//judge the direction of the gradient
//consume 2 clock period when the radian_temp input is valid
wire [12:0] angle;
assign angle = radian_temp[15]== 1 ? ~(radian_temp[12:0] -1):radian_temp[12:0] ;


reg [1:0] direct;       //direction of gradient
reg direct_en;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        direct <= 2'b0;
        direct_en <= 1'b0;
    end
    else if(radian_cal_finish == 1  )begin 
        direct_en <= 1'b1;
        //negative theta belongs to three or four quadrant
        if(radian_temp[15] == 1) begin  
            if(((13'b0 <= angle))&&((angle < ANGLE4))||(angle > ANGLE1))
                direct <= E;
            else if((ANGLE4 <= angle)&&(angle < ANGLE3))
                direct <= NW;
            else if((ANGLE3 <= angle)&&(angle < ANGLE2))
                direct <= N;
            else if((ANGLE2 <= angle)&&(angle < ANGLE1)) 
                direct <= NE;
        end
        //positive theta belongs to one or two quadrant
        else begin 
            if(((13'b0 <= angle)&&(angle < ANGLE4))||(angle > ANGLE1))
                direct <= E;
            else if((ANGLE4 <= angle)&&(angle < ANGLE3))
                direct <= NE;
            else if((ANGLE3 <= angle)&&(angle < ANGLE2))
                direct <= N;
            else if((ANGLE2 <= angle)&&(angle < ANGLE1)) 
                direct <= NW;
        end
    end
    else  begin
        direct <= 2'b0;    
        direct_en <= 1'b0;
    end
end

// //debug for the direction counts
// reg [9:0]   direc_count;
// always@ ( posedge clk or negedge rst_n) begin
//     if(!rst_n)begin
//         direc_count <= 10'b0;
//     end
//     //0~507   
//     else if (direc_count  == 10'd507) begin 
//         direc_count <= 10'b0;
//     end 
//     else if((start == 1)&&(count_en ==1)) begin
//         direc_count <= direc_count  +1;
//     end
   
// end





//  reg finish;
//  always @(posedge clk or negedge rst_n) begin
//      if(!rst_n) begin  
//          finish <= 1'b0;
//      end
//      else if( finish_en == 1)begin 
//          finish <= 1'b1;
//      end
//      else begin
         
//          finish <=1'b0;
//      end    
//  end
assign grad_square =  direct_en&&delayed_grad ? {direct,grad}: 26'b0 ;
assign ready = direct_en&&delayed_grad == 1 ? 1 : 0;
endmodule