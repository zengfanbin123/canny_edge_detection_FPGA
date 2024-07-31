module top (
    input clk,
    input rst_n,
    input [15:0]  in_data,
    input enable,
    output ready,
    output [15:0] out_data
    
);
//gaussian filter data
wire [15:0] mat1,mat2,mat3,mat4,mat5,mat6,mat7,mat8,mat9;
wire gauss_matrix_ready;
wire gauss_filter_ready;

wire [15:0] gaussianfilter_data;


//1bit sign  + 16 bits data
wire [15:0] grad_mat1,grad_mat2,grad_mat3,grad_mat4,grad_mat5,grad_mat6,grad_mat7,grad_mat8,grad_mat9;
wire grad_matrix_ready;
wire grad_filter_ready;
wire data_valid;
wire start_sync;
//wire [15:0] filter_data;
//wire [25:0] grad;
//input image size = 512*640
Shift_RAM_3X3_gaussian ram (
    //input 
    .clk(clk),  						
    .rst_n(rst_n),
    .start(enable),   
    .data_en(enable),		
    .per_img_Y(in_data),	
    .matrix_clken(gauss_matrix_ready),
     
    .data_valid(data_valid),	
    .ready_en(start_sync),	  
    .matrix_p11(mat1),	
    .matrix_p12(mat2),	
    .matrix_p13(mat3),	
    .matrix_p21(mat4),	
    .matrix_p22(mat5),		
    .matrix_p23(mat6),	
    .matrix_p31(mat7),	
    .matrix_p32(mat8),	
    .matrix_p33(mat9)		
);

wire guassianfilter_sync;
//latency  = 2 clock period 
Gaussianfilter fitler(
    .clk(clk),       //
    .rst_n(rst_n),       
    .start(start_sync),       
    .data_valid(data_valid),	
    .matrix_clken(gauss_matrix_ready),
    .matrix_p11(mat1),
    .matrix_p12(mat2),
    .matrix_p13(mat3),
    .matrix_p21(mat4),
    .matrix_p22(mat5),
    .matrix_p23(mat6),
    .matrix_p31(mat7),
    .matrix_p32(mat8),
    .matrix_p33(mat9),
    .ready(gauss_filter_ready),   // the signal of the 
    .start_sync(guassianfilter_sync),    
    .filter_Data(gaussianfilter_data)
   
);

wire grad_valid;
wire grad_ram_matrix_ready;
wire grad_ram_ready_sync;
//input image size  = 510*638
Shift_RAM_3X3_grad ram2(
    .clk(clk),					
    .rst_n(rst_n),			
    .start(guassianfilter_sync),	
    .data_en(gauss_filter_ready),
    .per_img_Y(gaussianfilter_data),
    .matrix_clken(grad_ram_matrix_ready),
    .data_valid(grad_valid),
    .ready_en(grad_ram_ready_sync),
    .matrix_p11(grad_mat1),
    .matrix_p12(grad_mat2),
    .matrix_p13(grad_mat3),
    .matrix_p21(grad_mat4),
    .matrix_p22(grad_mat5),
    .matrix_p23(grad_mat6),
    .matrix_p31(grad_mat7),
    .matrix_p32(grad_mat8),
    .matrix_p33(grad_mat9)
    
);

wire [25:0]grad_data;
Gradientfilter grad (
    clk,rst_n,
    grad_matrix_ready,
    grad_valid,
    grad_mat1,grad_mat2,grad_mat3,grad_mat4,grad_mat5,grad_mat6,grad_mat7,grad_mat8,grad_mat9,
    grad_filter_ready,
    grad_data
   
);

wire[25:0] wire1,wire2,wire3,wire4,wire5,wire6,wire7,wire8,wire9;
wire ram3_ready;
wire nomax_valid;
Shift_RAM_3X3_NO_MAX ram3(
    clk,rst_n,
    grad_filter_ready,grad_data,
    ram3_ready,
    //nomax_valid,
    wire1,wire2,wire3,wire4,wire5,wire6,wire7,wire8,wire9
);

wire [15:0]  none_max_data;
wire non_max_ready;
none_LocalMax_value max(
    clk,rst_n,
    ram3_ready,
    //nomax_valid,
    wire1,wire2,wire3,wire4,wire5,wire6,wire7,wire8,wire9,
    non_max_ready,
    none_max_data
);

wire max_ready;
wire ram4_ready;
wire [15:0] thresh_mat1,thresh_mat2,thresh_mat3,thresh_mat4,thresh_mat5,thresh_mat6,thresh_mat7,thresh_mat8,thresh_mat9;
Shift_RAM_3X3_thresh ram4(
    clk,rst_n,
    non_max_ready,none_max_data,
    ram4_ready,
    //max_ready,
    thresh_mat1,thresh_mat2,thresh_mat3,thresh_mat4,thresh_mat5,thresh_mat6,thresh_mat7,thresh_mat8,thresh_mat9
);
doublethresh thresh(
    clk,rst_n,
    ram4_ready,
   // max_ready,
    thresh_mat1,thresh_mat2,thresh_mat3,thresh_mat4,thresh_mat5,thresh_mat6,thresh_mat7,thresh_mat8,thresh_mat9,
    out_data,
    ready
); 
endmodule