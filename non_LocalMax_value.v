module non_LocalMax_value #(
  	parameter WIDTH = 634,
	parameter DEPTH = 506,
    parameter FIFO_SUM = 2,
    parameter KERNEL_SIZE = 3,
    parameter DATA_WIDTH = 26
) (
    input       clk,
    input       rst_n,
    input       start,          // function start  
    input       data_valid,     //the signal of the valid data  1 represent the invalid
    input       matrix_clken,   //the signal of the matrix 
    input [DATA_WIDTH - 1:0] grad_p11,
    input [DATA_WIDTH - 1:0] grad_p12,
    input [DATA_WIDTH - 1:0] grad_p13,
    input [DATA_WIDTH - 1:0] grad_p21,
    input [DATA_WIDTH - 1:0] grad_p22,
    input [DATA_WIDTH - 1:0] grad_p23,
    input [DATA_WIDTH - 1:0] grad_p31,
    input [DATA_WIDTH - 1:0] grad_p32,
    input [DATA_WIDTH - 1:0] grad_p33,

    output          start_sync, //start synchronous 
    output          data_en,   // the signal of the data      
    output [15:0]   out_data
);

localparam N = 2'b00;          
localparam E = 2'b01;        
localparam NW = 2'b10;
localparam NE = 2'b11;

reg finish;
reg [23:0] Maxvalue;
wire[1:0] direct ;
assign direct = (start && matrix_clken && (~data_valid)) ?{grad_p22[25],grad_p22[24]}:2'b0;


// Non maximum suppression
always @(posedge clk  or negedge rst_n) begin
    if(!rst_n) begin
        Maxvalue <= 24'b0;
        finish <= 1'b0;
    end
    else if(start == 1 ) begin
            if(matrix_clken && (~data_valid)) begin
                finish <= 1'b1;
                case(direct)
                N: begin
                    if((grad_p22[23:0] >= grad_p12[23:0])&&(grad_p22[23:0] >= grad_p32[23:0])) 
                        Maxvalue <= grad_p22[23:0];
                    else begin
                        Maxvalue  <= 24'b0;
                    end
                end
                E:  begin
                    if((grad_p22[23:0] >= grad_p21[23:0])&&(grad_p22[23:0] >= grad_p23[23:0])) 
                        Maxvalue <= grad_p22[23:0];
                    else begin
                        Maxvalue  <= 24'b0;
                    end 
                        
                end
                NW: begin
                    if((grad_p22[23:0] >= grad_p11[23:0])&&(grad_p22[23:0] >= grad_p33[23:0]))
                        Maxvalue <= grad_p22[23:0];
                    else begin
                        Maxvalue  <= 24'b0;
                    end
                end
                NE: begin
                    if((grad_p22[23:0] >= grad_p13[23:0])&&(grad_p22[23:0] >= grad_p31[23:0])) 
                        Maxvalue <= grad_p22[23:0];
                    else begin
                        Maxvalue  <= 24'b0;
                    end
                end
                endcase   
            end
            else  begin 
                finish <= 1'b0;
                Maxvalue <= 24'b0;
            end 
    end
    else begin
        finish <= 1'b0;
        Maxvalue <= 24'b0;  
    end  
end


//end flag of the gradient square root 
wire sqrt_finish;
//data of the gradient square root
wire [15:0] data; 
//latency = 14 clock period
//input  24bits  unfractionInterger
//output [15:0] while valid data bits is [12:0]
//Round mode is round of pos inf 
cordic_sqrt grad_sqrt (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(finish),  // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(Maxvalue),    // input wire [23 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(sqrt_finish),            // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(data)              // output wire [15 : 0] m_axis_dout_tdata
);



//delay finish 14 per clock
reg [13:0] delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        delay <= 14'b0;        
    else 
        delay <= {delay[12:0],finish};
end

//calculate the row and col data 
// start counting from 0
// when the row is bigger than 511, then there are two clock period data is unvalid 
reg [9:0] cnt_row;      //row  from  1 to 510 is valid
reg [9:0] cnt_col;      //col from 1 to 638 is valid
always @(posedge clk or negedge rst_n ) begin
    if(rst_n == 0) begin
        cnt_col <= 10'b0;     
    end  
    else if (start_sync) begin 
        if(cnt_col == WIDTH - 1 ) begin 
            cnt_col <= 10'b0;
        end
        else if( data_en ) begin
            cnt_col <= cnt_col + 1;        
        end
        else 
            cnt_col <= cnt_col;
    end   
    else 
        cnt_col <= 10'b0;
end

always @(posedge clk or negedge rst_n ) begin
    if(rst_n == 0) begin
        cnt_row <= 10'b0;   
    end     
    else if((cnt_col == WIDTH -1) && data_en ) begin 
        cnt_row <=  cnt_row + 1;
    end
    else if((cnt_row == DEPTH) && (cnt_col == WIDTH ) )  begin
        cnt_row <= 10'b0 ;        
    end
    else 
        cnt_row <= cnt_row;
end

reg [14:0] delay_start;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        delay_start <= 15'b0;        
    else if(matrix_clken)
        delay_start <= {delay_start[14:0],start};
    else 
        delay_start <= 15'b0;
end

wire    [15:0] padding_data;
wire    pad_data_sync, pad_start_sync;
Padding_Col #(
    .DATA_WIDTH(16),
    .WIDTH(634),
    .N(3)
) non_padding(
    .clk(clk),
    .rst_n(rst_n),
    .start(delay_start[14]),		
    .data_en(delay[13]),
    .fmap_raw(data),
    .fmap_pad(padding_data),
    .start_sync(pad_start_sync),	
    .data_en_sync(pad_data_sync)
    
);

assign start_sync = pad_start_sync;
assign out_data = padding_data;
assign data_en = pad_data_sync;
endmodule