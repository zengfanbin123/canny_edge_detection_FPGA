module doublethresh #(
    parameter TH = 500,     //high threshold
    parameter TL = 400,       //low threshold
    parameter DATA_WIDTH  = 16,
    parameter WIDTH = 640,
    parameter DEPTH = 504
) (
    input       clk,
    input       rst_n,
    input       start,          // function start  
    input       data_valid,     //the signal of the valid data  1 represent the invalid
    input       matrix_clken,   //the signal of the matrix 
    input  	[DATA_WIDTH - 1:0]	matrix_p11,         
    input 	[DATA_WIDTH - 1:0]	matrix_p12,
    input 	[DATA_WIDTH - 1:0]	matrix_p13,
    input 	[DATA_WIDTH - 1:0]	matrix_p21,
    input 	[DATA_WIDTH - 1:0]	matrix_p22,
    input 	[DATA_WIDTH - 1:0]	matrix_p23,
    input 	[DATA_WIDTH - 1:0]	matrix_p31,
    input 	[DATA_WIDTH - 1:0]	matrix_p32,
    input 	[DATA_WIDTH - 1:0]	matrix_p33, 
    output  [DATA_WIDTH - 1:0]  data,
    output      start_sync,
    output      data_en_sync
);

wire line1,line2,line3;
assign line1 = (start && matrix_clken && (~data_valid)) ? (matrix_p11 > TH)||(matrix_p12 > TH)||(matrix_p13 > TH) : 0;
assign line2 = (start && matrix_clken && (~data_valid)) ? (matrix_p21 > TH)||(matrix_p23 > TH) : 0;
assign line3 = (start && matrix_clken && (~data_valid)) ? (matrix_p31 > TH)||(matrix_p32 > TH)||(matrix_p33 > TH) :0;


reg [DATA_WIDTH - 1:0] temp_data;
reg en_data;
always @(posedge clk ) begin
    if(!rst_n)  begin 
        temp_data <= 16'b0;
        en_data <= 1'b0;
    end
    else if(start == 1) begin
        if(matrix_clken && (~data_valid)) begin
            en_data <= 1'b1; 
            if(matrix_p22 < TL)
                temp_data <= 16'b0;
            else if (matrix_p22 > TH)  
                temp_data <= matrix_p22;
            else if(line1||line2||line3) 
                temp_data <= matrix_p22;  
            else
                temp_data <= 16'b0;   
        end
        else begin
            en_data <= 1'b0;
            temp_data <= 16'h0000;
        end
    end
    else begin 
        en_data <= 1'b0;
        temp_data <= 16'hffff;
        
    end
end

//delay start 1 clock period
reg delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        delay <= 1'b0;
    else 
        delay <= start;
end

// reg [9:0] cnt_row;      //row  from  1 to 510 is valid
// reg [9:0] cnt_col;      //col from 1 to 638 is valid
// always @(posedge clk or negedge rst_n ) begin
//     if(rst_n == 0) begin
//         cnt_col <= 10'b0;     
//     end  
//     else if (start_sync) begin 
//         if(cnt_col == WIDTH - 1 ) begin 
//             cnt_col <= 10'b0;
//         end
//         else if( data_en_sync ) begin
//             cnt_col <= cnt_col + 1;        
//         end
//         else 
//             cnt_col <= cnt_col;
//     end   
//     else 
//         cnt_col <= 10'b0;
// end

// always @(posedge clk or negedge rst_n ) begin
//     if(rst_n == 0) begin
//         cnt_row <= 10'b0;   
        
//     end     
//     else if((cnt_col == WIDTH -1) && data_en_sync ) begin 
//         cnt_row <=  cnt_row + 1;
//     end
//     else if((cnt_row == DEPTH) && (cnt_col == WIDTH ) )  begin
//         cnt_row <= 10'b0 ;        
//     end
//     else 
//         cnt_row <= cnt_row;
// end


wire pad_data_sync,pad_start_sync;
wire [DATA_WIDTH -1 :0] padding_data;
Padding_Col #(
    .DATA_WIDTH(16),
    .WIDTH(638),
    .N(1)
) thresh_padding_col(
    .clk(clk),
    .rst_n(rst_n),
    .start(delay),		
    .data_en(en_data),
    .matrix_clken(matrix_clken),
    .fmap_raw(temp_data),
    .fmap_pad(padding_data),
    .start_sync(pad_start_sync),	
    .data_en_sync(pad_data_sync)
);

wire [DATA_WIDTH - 1 : 0] row_padding;
wire row_pad_start_sync,row_pad_data_sync;
Padding_Row #(
    .DATA_WIDTH(16),
    .WIDTH(640),
    .DEPTH(504),
    .N(4)
) thresh_padding_row(
    .clk(clk),
    .rst_n(rst_n),
    .start(pad_start_sync),		
    .data_en(pad_data_sync),
    .matrix_clken(matrix_clken),
    .fmap_raw(padding_data),
    .fmap_pad(row_padding),
    .start_sync(row_pad_start_sync),	
    .data_en_sync(row_pad_data_sync)
);


assign data = row_padding;   
assign start_sync = row_pad_start_sync;
assign data_en_sync = row_pad_data_sync;
endmodule