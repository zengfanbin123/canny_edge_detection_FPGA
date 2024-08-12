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

reg en_max_value;
reg [23:0] Maxvalue;
wire[1:0] direct ;
assign direct = (start && matrix_clken && (~data_valid)) ?{grad_p22[25],grad_p22[24]}:2'b0;


//-----------------------------------------
//pipeline of  non maximum suppression
always @(posedge clk  or negedge rst_n) begin
    if(!rst_n) begin
        Maxvalue <= 24'b0;
        en_max_value <= 1'b0;
    end
    else if(start == 1 ) begin
            if(matrix_clken && (~data_valid)) begin
                en_max_value <= 1'b1;
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
                en_max_value <= 1'b0;
                Maxvalue <= 24'b0;
            end 
    end
    else begin
        en_max_value <= 1'b0;
        Maxvalue <= 24'b0;  
    end  
end


//delay the matrix_clk_en
reg [14:0] delay_matrix;
always @(posedge clk or negedge rst_n) begin
    if(! rst_n ) begin
        delay_matrix <= 15'b0;
    end
    else 
        delay_matrix <= {delay_matrix[13:0],matrix_clken}; 
end
wire delayed_matrix;
assign delayed_matrix = delay_matrix[14];


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
  .s_axis_cartesian_tvalid(en_max_value),  // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(Maxvalue),    // input wire [23 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(sqrt_finish),            // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(data)              // output wire [15 : 0] m_axis_dout_tdata
);

//delay data_valid 14 per clock
reg [13:0] delay_data_valid;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        delay_data_valid <= 14'b0;        
    else 
        delay_data_valid <= {delay_data_valid[12:0],en_max_value};
end


//debug use 
//reg [9:0] cnt_row;      //row from 0 to 509  
// reg [9:0] cnt_col;      //col from 0 to 639
// always @(posedge clk or negedge rst_n ) begin
//     if(rst_n == 0) begin
//         cnt_col <= 10'b0;   
//     end 
// 	if(start ) begin
// 	    if(cnt_col == 720 - 1) begin 
// 			cnt_col <= 10'b0;
// 		end
// 		else if(matrix_clken||delayed_matrix) begin
// 			cnt_col <= cnt_col + 1;        
// 		end
// 		else 
// 			cnt_col <= 10'b0;
// 	end    
// 	else 
// 		cnt_col <= 10'b0;
// end
// always @(posedge clk or negedge rst_n ) begin
//     if(rst_n == 0) begin
//         cnt_row <= 10'b0;   
//     end
// 	else if(start ) begin
// 		if(cnt_col == WIDTH - 1)  
// 			cnt_row <=  cnt_row + 1;
		
// 		else if((cnt_row == DEPTH) && (cnt_col == WIDTH - 1) )  
// 			cnt_row <= 10'b0 ;        
		
// 		else 
// 			cnt_row <= cnt_row;
// 	end  
// 	else 
// 		cnt_row <= 10'b0;   
// end


//consume the 15 clock to non maximum suppression 
//so delay the start 15 clock
reg [14:0] delay_start;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        delay_start <= 15'b0;        
    else 
        delay_start <= {delay_start[14:0],start};
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
    .data_en(sqrt_finish),
    .matrix_clken(delayed_matrix),
    .fmap_raw(data),
    .fmap_pad(padding_data),
    .start_sync(pad_start_sync),	
    .data_en_sync(pad_data_sync)
    
);

assign start_sync = pad_start_sync;
assign out_data = padding_data;
assign data_en = pad_data_sync;
endmodule