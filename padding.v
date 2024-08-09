/* PADDING.v */
module Padding_Col
#(
	parameter DATA_WIDTH = 16,
	parameter WIDTH = 634,
	//parameter DEPTH = 506,
	parameter N = 3
)
(
	input 		clk,
	input 		rst_n,
	input 		start,		//start
	input 		data_en,		//~start
	input  		[DATA_WIDTH-1:0]		fmap_raw,
	output 		[DATA_WIDTH-1:0]		fmap_pad,
	output 		start_sync,
	output 		data_en_sync
	
);
localparam pad_len = N;
//delay input padding lenth period
reg [DATA_WIDTH * pad_len - 1:0] delay_data;
reg [N : 0] start_delay; 
//reg [9:0] cnt;
reg [9:0] cnt_col;
//reg [LINE_CNT_ROW_BIT_NUM-1:0]cnt_row;


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		delay_data <= 16'b0;
	end
	else if(pad_len > 1) begin
		if(start && cnt_col < WIDTH + pad_len - 1) begin 
			delay_data <= {delay_data[DATA_WIDTH * (pad_len - 1):0],fmap_raw};
		end
		else 
			delay_data <= 16'h0;
	end
	else begin
		if(start && cnt_col < WIDTH + pad_len - 1) begin 
			delay_data <=  fmap_raw ;
		end
		else 
			delay_data <= 16'h0;
	end
	 
end 

//delay start  
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		start_delay <= 1'b0;
	end
	else 
		start_delay <= {start_delay[N-1:0],start};
end 
wire start_delay_en ;
assign start_delay_en =  N > 1 ? start_delay[N]: start_delay;


//count all data 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_col <= 0;
	end
	else if(start||start_delay) begin
		if(cnt_col  == WIDTH + 2 * pad_len - 1 + 80)
			cnt_col <= 10'b0;
		else 
			cnt_col <= cnt_col + 1;
	end
	else
		cnt_col <= 10'b0;
end

// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		cnt <= 0;
// 	end
// 	else if(start) begin
// 		if(cnt  == WIDTH + 2 * pad_len - 1 + 80)
// 			cnt <= 10'b0;
// 		else 
// 			cnt <= cnt + 1;
// 	end
// 	else
// 		cnt_col <= 10'b0;
// end

	

assign  fmap_pad = (cnt_col < pad_len && start_sync? 16'b0 : cnt_col > WIDTH + pad_len - 1 ? 16'b0 : delay_data [DATA_WIDTH * pad_len - 1: DATA_WIDTH * (pad_len -1)]);
assign 	start_sync = start||start_delay_en;
assign  data_en_sync = cnt_col < ( WIDTH + 2 * pad_len ) && start_sync ?1:0;
endmodule
