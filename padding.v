/* PADDING.v */
module PADDING
#(
	parameter DATA_WIDTH = 16,
	parameter FMAP_SIZE = 28,
	parameter N = 1
)
(
	input clk,
	input rst_n,
	input ena,
	input clear,
	input [DATA_WIDTH-1:0]fmap_raw,
	output [DATA_WIDTH-1:0]fmap_pad,
	output rd_en,
	output valid,
	output done
);

	function integer clogb2 (input integer bit_depth);
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
		bit_depth = bit_depth >> 1;
	end
	endfunction
	
	localparam CNT_BIT_NUM = clogb2((FMAP_SIZE+N*2)*(FMAP_SIZE+N*2));
	localparam LINE_CNT_BIT_NUM = clogb2(FMAP_SIZE+N*2);
	
	reg [CNT_BIT_NUM-1:0]cnt;
	reg [LINE_CNT_BIT_NUM-1:0]cnt_col;
	reg [LINE_CNT_BIT_NUM-1:0]cnt_row;
	
	assign valid = (ena) ? ((cnt < (FMAP_SIZE + N * 2) * (FMAP_SIZE + N * 2) - 1) ? 1 : 0) : 0;
	assign done = (ena) ? ((cnt == (FMAP_SIZE + N * 2) * (FMAP_SIZE + N * 2) - 1) ? 1 : 0) : 0;
	assign fmap_pad = (!ena || cnt_row < N  || cnt_row > FMAP_SIZE + N - 1) ? 0 : ((cnt_col < N || cnt_col > FMAP_SIZE + N - 1) ? 0 : fmap_raw);
	
	//conditional generate
	generate 
		if(N != 0) begin: no_padding
			assign rd_en = (!ena || cnt_row < N|| cnt_row > FMAP_SIZE + N - 1) ? 0 : ((cnt_col < N - 1 || cnt_col > FMAP_SIZE + N - 2) ? 0 : 1);
		end
		else begin: padding
			assign rd_en = (ena) ? 1 : 0;
		end
	endgenerate
	
	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			cnt <= 0;
		else if(clear)
			cnt <= 0;
		else if(ena) begin
			if(cnt == (FMAP_SIZE + N * 2) * (FMAP_SIZE + N * 2) - 1) 
				cnt <= 0;
			else
				cnt <= cnt + 1;
		end
		
	always @(posedge clk or negedge rst_n)
		if(!rst_n) begin
			cnt_col <= 0;
			cnt_row <= 0;
		end
		else if(clear) begin
			cnt_col <= 0;
			cnt_row <= 0;	
		end
		else if(ena) begin
			if (cnt_col >= FMAP_SIZE + N * 2 - 1) begin
				cnt_col <= 0;
				cnt_row <= cnt_row + 1;
			end
			else 
				cnt_col <= cnt_col + 1;
		end
				
endmodule
