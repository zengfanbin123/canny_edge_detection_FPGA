module doublethresh #(
    parameter TH = 400,     //high threshold
    parameter TL = 500       //low threshold
) (
    input       clk,
    input       rst_n,
    input       start,          // function start  
    input       data_valid,     //the signal of the valid data  1 represent the invalid
    input       matrix_clken,   //the signal of the matrix 
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
assign line1 = (start && matrix_clken && (~data_valid)) ?(matrix_p11 > TH)||(matrix_p21 > TH)||(matrix_p31 > TH) : 0;
assign line2 = (start && matrix_clken && (~data_valid)) ? (matrix_p12 > TH)||(matrix_p32 > TH) : 0;
assign line3 = (start && matrix_clken && (~data_valid)) ? (matrix_p13 > TH)||(matrix_p23 > TH)||(matrix_p33 > TH) :0;

reg [15:0] temp_data;
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
            temp_data <= 16'hffff;
        end
    end
    else begin 
        en_data <= 1'b0;
        temp_data <= 16'hffff;
    end
end

//delay en_data 1 clock period
reg delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        delay <= 1'b0;
    else 
        delay <= start;
end

assign data = temp_data;   
assign ready = start ;
endmodule