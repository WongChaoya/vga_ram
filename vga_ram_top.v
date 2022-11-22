////////////////////////////////////////////////////
//
// Project: vga_ram_top
// Author : CharlesWong
// Date	 : 2020/04/28
// Module : vga_ram_top
// Version: 1.0
//
///////////////////////////////////////////////////
`include "vga_para.v"
module vga_ram_top(
input clk,
input rst_n,


output hsync,
output vsync,
output [23:0]rgb,
output pixel_clk
);


reg [10:0]v_cnt_r;
reg [11:0]h_cnt_r;
wire pixel_clk_w;
reg vsync_r;
reg hsync_r;
reg [27:0]mov_cnt_r;
reg mov_flag_r;
reg h_direct_r;//为0右移，为1左移
reg [15:0]add_rom_r;
//reg [23:0]data_rom_r;
reg rden_r;
wire [15:0]add_rom_w;
wire [23:0]data_rom_w;
wire rden_w;
reg [10:0]h_mov_cnt_r;
reg[23:0]rgb_r;
reg v_direct_r;//为0下移，为1上移
reg [9:0]v_mov_cnt_r;
pll_pixel u_pll_pixel(
		.refclk   (clk),   //  refclk.clk
		.rst      (!rst_n),      //   reset.reset
		.outclk_0 (pixel_clk_w) // outclk0.clk
);
//行计数

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		h_cnt_r <= 0;
	end
	else if(h_cnt_r ==  `H_WHOLE -1) begin
		h_cnt_r <= 0;
	end
	else begin
		h_cnt_r <= h_cnt_r + 1'b1;
	end
end
//场计数

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		v_cnt_r <= 0;
	end
	else if(v_cnt_r ==  `V_WHOLE -1) begin
		v_cnt_r <= 0;
	end 
	else if (h_cnt_r ==  `H_WHOLE -1) begin
		v_cnt_r <= v_cnt_r + 1'b1;
	end
	else begin
		v_cnt_r <= v_cnt_r;
	end
end
//行同步

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		hsync_r <= 0;
	end
	else if((h_cnt_r >=0) && (h_cnt_r <= (`H_SYNC -1))) begin
		hsync_r <= 1;
	end
	else begin
		hsync_r <= 0;
	end
end
//场同步

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		vsync_r <= 0;
	end
	else if((v_cnt_r >= 0) && (v_cnt_r <=(`V_SYNC -1))) begin
		vsync_r <= 1;
	end
	else begin
		vsync_r <= 0;
	end
end
assign hsync=hsync_r;
assign vsync=vsync_r;

//白色正方形移动计数器计数,间隔时间1s

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		mov_cnt_r <= 1;
	end
	else if(mov_cnt_r ==`MOV_PARA) begin 
		mov_cnt_r <= 0;
	end
	else if((h_cnt_r >=(`H_SYNC + `H_BACK) && h_cnt_r <= (`H_SYNC + `H_BACK + `H_VISIBLE)) && (v_cnt_r >= (`V_SYNC + `V_BACK) && v_cnt_r <= (`V_SYNC + `V_BACK + `V_VISIBLE))) begin//在VGA显示区域移动
		mov_cnt_r <= mov_cnt_r + 1'b1;
	end
	else begin
		mov_cnt_r <= mov_cnt_r;
	end
end
//白色正方形移动标志

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		mov_flag_r <= 0;
	end
	else if(mov_cnt_r == `MOV_PARA) begin//每隔MOV_PARA个时钟周期移动一次
		mov_flag_r <= 1;
	end
	else begin
		mov_flag_r <= 0;
	end
end
//正方形水平移动方向

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		h_direct_r <= 0;
	end
	else if(h_mov_cnt_r >= (`H_VISIBLE -200)) begin
		h_direct_r <= 1;
	end
	else if(h_mov_cnt_r <= 0) begin
		h_direct_r <= 0;
	end
	else begin
		h_direct_r <= h_direct_r;
	end
end
//正方形水平移动计数

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		h_mov_cnt_r <=0;
	end
	else if(h_direct_r && mov_flag_r) begin
		h_mov_cnt_r <= h_mov_cnt_r -1'b1;
	end
	else if((!h_direct_r) && mov_flag_r) begin
		h_mov_cnt_r <= h_mov_cnt_r +1'b1;
	end
	else begin
		h_mov_cnt_r <= h_mov_cnt_r;
	end
end
//正方形垂直移动方向

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		v_direct_r <= 0;
	end
	else if(v_mov_cnt_r >= (`V_VISIBLE -200)) begin
		v_direct_r <= 1;
	end
	else if(v_mov_cnt_r <=0) begin
		v_direct_r <= 0;
	end
	else begin
		v_direct_r <= v_direct_r;
	end
end
//正方形垂直方向移动计数

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		v_mov_cnt_r <=0;
	end
	else if(v_direct_r && mov_flag_r) begin
		v_mov_cnt_r <= v_mov_cnt_r -1'b1;
	end
	else if((!v_direct_r) && mov_flag_r) begin
		v_mov_cnt_r <= v_mov_cnt_r +1'b1;
	end
	else begin
		v_mov_cnt_r <= v_mov_cnt_r;
	end
end
//读取ROM中像素数据
rom_init u_rom_init(
.address(add_rom_w),
.clock(pixel_clk_w),
.rden(rden_w),
.q(data_rom_w)
);

always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		rden_r <= 0;
	end
	else begin
		rden_r <= 1;
	end
end
reg [3:0]status_r1;
reg [3:0]status_r2;
always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		status_r1 <= 0;
		status_r2 <= 0;
	end
	else begin
		status_r1[0] <= (h_cnt_r >= (`H_SYNC + `H_BACK +h_mov_cnt_r)) ? 1:0;
		status_r1[1] <= (h_cnt_r <= (`H_SYNC + `H_BACK +h_mov_cnt_r + 200)) ? 1:0;
		status_r1[2] <= (v_cnt_r >= (`V_SYNC + `V_BACK + v_mov_cnt_r)) ? 1:0;
		status_r1[3] <= (v_cnt_r <= (`V_SYNC + `V_BACK + v_mov_cnt_r + 200)) ? 1:0;
		status_r2 <= status_r1;
	end
end
	
reg disp_flag_r1,disp_flag_r2;
always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		disp_flag_r1 <= 0;
		disp_flag_r2 <= 0;
	end
	else begin
		disp_flag_r1 <= ((status_r2[0]) && (status_r2[1]) && (status_r2[2]) && (status_r2[3])) ? 1:0;
		disp_flag_r2 <= disp_flag_r1;
	end
end
always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		add_rom_r <= 0;
	end
//	else if(v_cnt_r >= `V_WHOLE) begin
//		add_rom_r <= 0;
//	end
	else if(rden_r) begin
		if (disp_flag_r2)begin
			add_rom_r <= add_rom_r + 1;
		end
	end
	else begin
		add_rom_r <= 0;
	end
end
assign add_rom_w = add_rom_r;
assign rden_w = rden_r;

//VGA显示
always@(posedge pixel_clk_w or negedge rst_n) begin
	if(!rst_n) begin
		rgb_r <= 0;
	end
	else if (disp_flag_r2) begin
		rgb_r <= data_rom_w;
	end
	else if(v_cnt_r <= 400 && v_cnt_r >= 0) begin
		rgb_r <= 24'hFF0000;
	end
	else if(v_cnt_r >400 && v_cnt_r <= 800) begin
		rgb_r <= 24'h00FF00;
	end
	else begin
		rgb_r <= 24'h0000FF;
	end
end
assign rgb = rgb_r;	
assign pixel_clk = pixel_clk_w;
endmodule 