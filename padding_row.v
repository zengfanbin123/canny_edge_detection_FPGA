module Padding_Row
#(
	parameter DATA_WIDTH = 16,
	parameter WIDTH = 640,
	parameter DEPTH = 504,
	parameter N = 4
)
(
	input 		clk,
	input 		rst_n,
	input 		start,		//start
	input 		data_en,	
    input       delay_start,	
	input  		[DATA_WIDTH-1:0]		fmap_raw,
	output 		[DATA_WIDTH-1:0]		fmap_pad,
	output 		start_sync,
	output 		data_en_sync
	
);



//delay data for 640*4 perclock
localparam pad_len = N;
wire    [DATA_WIDTH - 1:0]  delay_data;
wire    [DATA_WIDTH - 1:0]  row0_data;  //frame data of the 0  row
wire 	[DATA_WIDTH - 1:0] 	row1_data;  //frame data of the 1th row
wire 	[DATA_WIDTH - 1:0]	row2_data;  //frame data of the 2th row
reg 	[DATA_WIDTH - 1:0] 	row3_data;  //frame data of the 3th row

reg     [DATA_WIDTH - 1:0]  row2_temp;
reg     [DATA_WIDTH - 1:0]  row1_temp;
reg     [DATA_WIDTH - 1:0]  row0_temp;
reg     [9 : 0] cnt_row;
reg     [9 : 0] cnt_col;    
reg     [19 : 0]    cnt_all;
//delay start sign
reg delay_en;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		delay_en <= 1'b0;
	else 
		delay_en <= delay_start;
end

//delay data_en sign for padding line clock
reg[(WIDTH+80)*pad_len - 1 : 0] data_en_delay;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		data_en_delay <= 1'b0;
	else 
		data_en_delay <= {data_en_delay[(WIDTH + 80)*pad_len - 2:0],data_en};
end
wire data_en_shift = data_en_delay[(WIDTH+80)*pad_len - 1];


//delay row data 1 clock
reg row_en;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		row_en <= 1'b0;
	else 
		row_en <= data_en;
end
wire    shift_en = row_en;
wire    D_trig_en =  row_en || data_en_shift;


//shift row data
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)  begin
        row3_data <= 16'b0;
        row2_temp <= 16'b0;
        row1_temp <= 16'b0; 
        row0_temp <= 16'b0;       
	end
	else if(start || delay_en)begin
		if(D_trig_en) begin
			row3_data <= fmap_raw;
			row2_temp <= row2_data;
            row1_temp <= row1_data;
            row0_temp <= row0_data;
		end
		else begin
			row3_data <= row3_data;
			row2_temp <= row2_temp;
            row1_temp <= row1_temp;
            row0_temp <= row0_temp;
		end
	end
	else begin
		row3_data <= 16'b0;
		row2_temp <= 16'b0;
        row1_temp <= 16'b0;
        row0_temp <= 16'b0;
	end
end


//use the shiftram  delay 4 row data 
c_shift_ram_1 delay_1st_row (
   .D(row3_data),        // input wire [DATA_WIDTH - 1 : 0] D
  .CLK(clk & D_trig_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row2_data)        // output wire [DATA_WIDTH - 1 : 0] Q
);
c_shift_ram_1 delay_2nd_row (
   .D(row2_temp),        // input wire [DATA_WIDTH - 1 : 0] D
  .CLK(clk & D_trig_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row1_data)        // output wire [DATA_WIDTH - 1 : 0] Q
);
c_shift_ram_1 delay_3rd_row (
   .D(row1_temp),        // input wire [DATA_WIDTH - 1 : 0] D
  .CLK(clk & D_trig_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(row0_data)        // output wire [DATA_WIDTH - 1 : 0] Q
);
c_shift_ram_1 delay_4th_row (
   .D(row0_temp),        // input wire [DATA_WIDTH - 1 : 0] D
  .CLK(clk & D_trig_en),    // input wire CLK
  .SCLR(~rst_n),  // input wire SCLR
  .Q(delay_data)        // output wire [DATA_WIDTH - 1 : 0] Q
);

// sign of start_sync
wire start_en = start || (delay_en && cnt_row < DEPTH + N * 2);
//count all input  
// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		cnt_all <= 20'b0;
// 	end
//     else if (start_en) begin 
//         if(cnt_all == (WIDTH+80) * (DEPTH + pad_len*2) -1)
//             cnt_all <= 20'b0;
//         else 
//             cnt_all <= cnt_all + 1;
//     end
//     else 
//         cnt_all <= 20'b0;
// end
// reg sign;
// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		sign <= 1'b1;
// 	end
//     else if (start_en) begin 
//         if(cnt_col == WIDTH + 80 - 1 ) begin 
//             cnt_col <= 10'b0;
//         end
//         else if( delay_en) begin
//             cnt_col <= cnt_col + 1;        
//         end
//         else 
//             cnt_col <= cnt_col;
//     end   
//     else 
//         cnt_col <= 1'b1;
// end


//count input col  
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_col <= 0;
	end
    else if (start_en) begin 
        if(cnt_col == WIDTH + 80 - 1 ) begin 
            cnt_col <= 10'b0;
        end
        else if( delay_en) begin
            cnt_col <= cnt_col + 1;        
        end
        else 
            cnt_col <= cnt_col;
    end   
    else 
        cnt_col <= 10'b0;
end

//count input row  
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_row <= 0;
	end
	else if(start_en) begin
        if((cnt_row == DEPTH + N * 2) && (cnt_col == WIDTH + 80 - 1 ))  
            cnt_row <= 10'b0 ;
        else if(cnt_col == WIDTH + 80 - 1)  
            cnt_row <=  cnt_row + 1;       
        else
            cnt_row <= cnt_row;
    end
    else 
        cnt_col <= 10'b0;

end


assign start_sync = start_en;
assign data_en_sync = cnt_col < (WIDTH) && start_sync ?1:0;
assign fmap_pad = (cnt_row < pad_len && start_sync ? 16'b0 : cnt_row > DEPTH + pad_len - 1 ? 16'b0: delay_data);
endmodule