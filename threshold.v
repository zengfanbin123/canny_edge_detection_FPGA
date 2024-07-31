module doublethresh #(
    parameter TH = 22943,     //high threshold
    parameter TL = 17208       //low threshold
) (
    input clk,
    input rst_n,
    input start,
    input  	[15:0]	matrix_p11,         
    input 	[15:0]	matrix_p12,
    input 	[15:0]	matrix_p13,
    input 	[15:0]	matrix_p21,
    input 	[15:0]	matrix_p22,
    input 	[15:0]	matrix_p23,
    input 	[15:0]	matrix_p31,
    input 	[15:0]	matrix_p32,
    input 	[15:0]	matrix_p33, 
    output  [15:0]  data,
    output          ready
);

wire line1,line2,line3;
assign line1 = (matrix_p11 > TH)||(matrix_p12 > TH)||(matrix_p13 > TH);
assign line2 = (matrix_p21 > TH)||(matrix_p23 > TH);
assign line3 = (matrix_p31 > TH)||(matrix_p32 > TH)||(matrix_p33 > TH);

reg [15:0] temp_data;
reg en_data;
always @(posedge clk ) begin
    if(!rst_n)  begin 
        temp_data <= 16'b0;
        en_data <= 1'b0;
    end
    else if(start == 1) begin

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
        temp_data <= 16'b0;
    end
end
//delay en_data 1 clock period
reg[1:0] delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        delay <= 2'b0;
    else 
        delay <= {delay[0],en_data};
end

assign data = temp_data;   
assign ready = delay[0] == 1?1:0;
endmodule