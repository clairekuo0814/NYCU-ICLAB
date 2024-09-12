//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ---------------------------------------------------------------
//  					Parameter Declaration 
// ---------------------------------------------------------------
parameter ID_WIDTH = 4;
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;
parameter IDLE = 'd0, READ_MAP = 'd1, FILL_START = 'd2, FILL = 'd3, RETRACE = 'd4, WRITE_BACK = 'd5;//global FSM
parameter DOWN = 'd0, UP = 'd1, RIGHT = 'd2, LEFT = 'd3; 


// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output reg                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output reg                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// ---------------------------------------------------------------
//  						Register & Wire 
// ---------------------------------------------------------------
//FF
reg [2:0] global_cs;
//wire
integer i, j;
reg [2:0] global_ns;
//map FF
reg [1:0] map[63:0][63:0];
reg [1:0] map_tmp[63:0][63:0];
reg [1:0] map_fill[63:0][63:0];
reg label, label_d1;
//ctrl
wire read_map, read_weight;
reg read_map_done, read_map_done_d1, read_weight_done;
wire read_map_done_tmp, read_weight_done_tmp;
wire retrace_done;
wire fill_done;
reg fill_done_reg;
wire net_done;
reg [1:0] fill_start_cnt;
reg [5:0] map_share_x, map_share_y;

//retrace
reg [5:0] retrace_x, retrace_y;
reg [5:0] retrace_x_tmp, retrace_y_tmp;
reg retrace_read_ctrl;
reg [1:0] direct;
wire [1:0] label_retrace;
wire [5:0] retrace_x_p1, retrace_x_m1, retrace_y_p1, retrace_y_m1;
reg [127:0] retrace_write;
reg [5:0] retrace_x_d1;
reg [5:0] retrace_y_d1;




//------------------------------- Memory -------------------------------
//FF
reg [6:0] sram_addr_cnt;
//wire
reg [6:0] map_addr_sram;
wire [127:0] map_DO;
reg [127:0] map_DI;
reg map_WEB;
reg [6:0] weight_addr_sram;
wire [127:0] weight_DO;
reg [127:0] weight_DI;
reg weight_WEB;
reg [6:0] sram_addr_cnt_tmp;


// ---------------------------------------------------------------
//  							Design 
// ---------------------------------------------------------------

//------------------------------- input -------------------------------
//FF
reg in_valid_d1;
reg [4:0] frame_id_reg;
reg [3:0] net_id_reg[14:0];
reg [5:0] source_x_reg[14:0];
reg [5:0] source_y_reg[14:0];
reg [5:0] sink_x_reg[14:0];
reg [5:0] sink_y_reg[14:0];
reg [4:0] input_cnt;
//wire
reg [3:0] net_id_reg_tmp[14:0];
reg [5:0] source_x_reg_tmp[14:0];
reg [5:0] source_y_reg_tmp[14:0];
reg [5:0] sink_x_reg_tmp[14:0];
reg [5:0] sink_y_reg_tmp[14:0];
wire [4:0] input_cnt_tmp;
wire [3:0] input_pos;
assign input_pos = input_cnt >> 1;


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		in_valid_d1 <= 'd0;
		frame_id_reg <= 'd0;
		for( i=0; i < 15; i = i+1)begin
			net_id_reg[i] <= 'd0;
			source_x_reg[i] <= 'd0;
			source_y_reg[i] <= 'd0;
			sink_x_reg[i] <= 'd0;
			sink_y_reg[i] <= 'd0;
		end

	end
	else begin
		in_valid_d1 <= in_valid;
		frame_id_reg <= (in_valid && !in_valid_d1) ? frame_id : frame_id_reg;
		for( i=0; i < 15; i = i+1)begin
			net_id_reg[i] <= net_id_reg_tmp[i];
			source_x_reg[i] <= source_x_reg_tmp[i];
			source_y_reg[i] <= source_y_reg_tmp[i];
			sink_x_reg[i] <= sink_x_reg_tmp[i];
			sink_y_reg[i] <= sink_y_reg_tmp[i];
		end
	end
end

always@(*)begin
	if(retrace_done)begin
		for( i=0; i < 14; i = i+1)begin
			net_id_reg_tmp[i] = net_id_reg[i + 1];
			source_x_reg_tmp[i] = source_x_reg[i + 1];
			source_y_reg_tmp[i] = source_y_reg[i + 1];
			sink_x_reg_tmp[i] = sink_x_reg[i + 1];
			sink_y_reg_tmp[i] = sink_y_reg[i + 1];
		end
		net_id_reg_tmp[14] = 'd0;
		source_x_reg_tmp[14] = 'd0;
		source_y_reg_tmp[14] = 'd0; 
		sink_x_reg_tmp[14] = 'd0;
		sink_y_reg_tmp[14] = 'd0;
	end
	else begin
		for( i=0; i < 15; i = i+1)begin
			net_id_reg_tmp[i] = net_id_reg[i];
			source_x_reg_tmp[i] = source_x_reg[i];
			source_y_reg_tmp[i] = source_y_reg[i];
			sink_x_reg_tmp[i] = sink_x_reg[i];
			sink_y_reg_tmp[i] = sink_y_reg[i];
		end
		net_id_reg_tmp[input_pos] = (!input_cnt[0] && in_valid) ? net_id : net_id_reg[input_pos];
		source_x_reg_tmp[input_pos] = (!input_cnt[0] && in_valid) ? loc_x : source_x_reg[input_pos];
		source_y_reg_tmp[input_pos] = (!input_cnt[0] && in_valid) ? loc_y : source_y_reg[input_pos];
		sink_x_reg_tmp[input_pos] = (input_cnt[0] && in_valid) ? loc_x : sink_x_reg[input_pos];
		sink_y_reg_tmp[input_pos] = (input_cnt[0] && in_valid) ? loc_y : sink_y_reg[input_pos];
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		input_cnt <= 'd0;
	end
	else begin
		input_cnt <= input_cnt_tmp;
	end
end

assign input_cnt_tmp = (global_cs == WRITE_BACK) ? 'd0 : (in_valid) ? input_cnt + 'd1 : input_cnt;

//------------------------------- global FSM -------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		global_cs <= IDLE;
	end
	else begin
		global_cs <= global_ns;
	end
end

always@(*)begin
	case(global_cs)
		IDLE : global_ns = (in_valid) ? READ_MAP : global_cs;
		READ_MAP : global_ns = (rlast_m_inf) ? FILL_START : global_cs;
		FILL_START : global_ns = (fill_start_cnt[1]) ? FILL : global_cs;
		FILL : global_ns = (fill_done_reg && read_weight_done) ? RETRACE : global_cs;
		RETRACE : global_ns = (retrace_done) ? (net_done) ? WRITE_BACK : FILL_START : global_cs;
		WRITE_BACK : global_ns = (bvalid_m_inf && bready_m_inf) ? IDLE : global_cs;
		default : global_ns = IDLE;
	endcase
end


//------------------------------- ctrl -------------------------------


assign read_map = in_valid && !in_valid_d1;
assign read_weight = (read_map_done && !read_map_done_d1);

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		read_map_done <= 'd0;
		read_map_done_d1 <= 'd0;
		read_weight_done <= 'd0;
	end
	else begin
		read_map_done <= read_map_done_tmp;
		read_map_done_d1 <= read_map_done;
		read_weight_done <= read_weight_done_tmp;
	end
end
assign read_map_done_tmp = (global_cs == IDLE) ? 'd0 : (rlast_m_inf) ? 'd1 : read_map_done;
assign read_weight_done_tmp = (global_cs == IDLE) ? 'd0 : (rlast_m_inf && global_cs != READ_MAP) ? 'd1 : read_weight_done;

assign fill_done = map[map_share_y][map_share_x][1] && global_cs == FILL;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		fill_done_reg <= 'd0;
	end
	else begin
		fill_done_reg <= (global_ns == RETRACE) ? 'd0 : (fill_done) ? 'd1 : fill_done_reg;
	end
end
assign retrace_done = retrace_x_d1 == source_x_reg[0] && retrace_y_d1 == source_y_reg[0] && global_cs == RETRACE;
assign net_done = (~|net_id_reg[1]);

reg wdata_start;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		wdata_start <= 'd0;
	end
	else begin
		wdata_start <= awvalid_m_inf && awready_m_inf;
	end
end

reg write_back_done;
wire write_back_done_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		write_back_done <= 'd0;
	end
	else begin
		write_back_done <= write_back_done_tmp;
	end
end
assign write_back_done_tmp = (global_cs == IDLE) ? 'd0 : (global_cs == WRITE_BACK && &sram_addr_cnt && wvalid_m_inf && wready_m_inf) ? 1'b1 : write_back_done;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		fill_start_cnt <= 'd0;
	end
	else begin
		fill_start_cnt <= {fill_start_cnt[0], (global_cs == FILL_START)};
	end
end
//------------------------------- HW sharing -------------------------------
reg [DATA_WIDTH-1 : 0] share_data_reg;
reg [DATA_WIDTH-1 : 0] share_data_reg_tmp;
reg [DATA_WIDTH-1 : 0] retrace_write_reg;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		share_data_reg <= 'd0;
	end
	else begin
		share_data_reg <= share_data_reg_tmp;
	end
end
always@(*)begin
	if(wdata_start || (wready_m_inf && wvalid_m_inf))
		share_data_reg_tmp = map_DO;
	else if(global_cs == RETRACE && !retrace_read_ctrl)
		share_data_reg_tmp = weight_DO[retrace_x_d1[4:0]*4 +: 4];
	else if(global_cs == WRITE_BACK)
		share_data_reg_tmp = share_data_reg;
	else
		share_data_reg_tmp = 'd0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		retrace_write_reg <= 'd0;
	end
	else begin
		retrace_write_reg <= (global_cs == RETRACE && !retrace_read_ctrl) ? retrace_write : 'd0;
	end
end
always@(*)begin
	if(!fill_done_reg && global_cs == FILL)begin
		map_share_x = sink_x_reg[0];
		map_share_y = sink_y_reg[0];
	end
	else begin
		map_share_x = retrace_x;
		map_share_y = retrace_y_p1;
	end
end




//------------------------------- map update -------------------------------
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i = 0; i < 64; i = i+1)
			for(j = 0; j < 64; j = j+1)
				map[i][j] <= 'd0;
	end
	else begin
	for(i = 0; i < 64; i = i+1)
		for(j = 0; j < 64; j = j+1)
			map[i][j] <= map_tmp[i][j];
	end
end*/
always@(posedge clk)begin
	/*
	if(!rst_n)begin
		for(i = 0; i < 64; i = i+1)
			for(j = 0; j < 64; j = j+1)
				map[i][j] <= 'd0;
	end
	else begin*/
	for(i = 0; i < 64; i = i+1)
		for(j = 0; j < 64; j = j+1)
			map[i][j] <= map_tmp[i][j];
	//end
end
reg [5:0] map_change_x, map_change_y;



always@(*)begin
	case(global_cs)
		READ_MAP : begin
			for(i = 0; i < 64; i = i+1)
				for(j = 0; j < 64; j = j+1) begin
					if(i == sram_addr_cnt >> 1 && j[5] == sram_addr_cnt[0])
						if(rdata_m_inf[{2'b0, j[4:0]} << 2 +: 4] != 'd0)
							map_tmp[i][j] = 2'b01;
						else
							map_tmp[i][j] = 2'b00;
					else
						map_tmp[i][j] = map[i][j];
				end
		end
		FILL_START : begin
			//change label to empty
			if(fill_start_cnt[1])
				for(i = 0; i < 64; i = i+1)begin
					for(j = 0; j < 64; j = j+1)begin
						if(i == source_y_reg[0] && j == source_x_reg[0])//source change to label 2
							map_tmp[i][j] = 2'b11;
						else
							map_tmp[i][j] = map[i][j];
					end
				end
			else if(fill_start_cnt[0])
				for(i = 0; i < 64; i = i+1)begin
					for(j = 0; j < 64; j = j+1)begin
						if(i == sink_y_reg[0] && j == sink_x_reg[0])//sink change to empty
							map_tmp[i][j] = 2'b00;
						else
							map_tmp[i][j] = map[i][j];
					end
				end
			else
				for(i = 0; i < 64; i = i+1)begin
					for(j = 0; j < 64; j = j+1)begin
						map_tmp[i][j] = {1'b0,(~map[i][j][1]) && map[i][j][0]};
					end
				end
		end
		FILL : begin
			for(i = 0; i < 64; i = i+1)begin
				for(j = 0; j < 64; j = j+1)begin
					map_tmp[i][j] = map_fill[i][j];
				end
			end
		end
		RETRACE : 
			for(i = 0; i < 64; i = i+1)begin
				for(j = 0; j < 64; j = j+1)begin
					if(i == retrace_y_d1 && j == retrace_x_d1)
						map_tmp[i][j] = 2'b01;
					else
						map_tmp[i][j] = map[i][j];
				end
			end
		default : 
			for(i = 0; i < 64; i = i+1)begin
				for(j = 0; j < 64; j = j+1)begin
					map_tmp[i][j] = 'd0;
				end
			end
	endcase
end
wire [1:0] label_fill;
assign label_fill = {1'b1, label};
always@(*)begin
	for(i = 0; i < 64; i = i+1)begin
		for(j = 0; j < 64; j = j+1)begin
			map_fill[i][j] = map[i][j];
		end
	end
	for(i = 1; i < 63; i = i+1)begin
		for(j = 1; j < 63; j = j+1)begin
			if(~|map[i][j] && (map[i-1][j][1] || map[i+1][j][1] || map[i][j-1][1] || map[i][j+1][1]))
				map_fill[i][j] = label_fill;
		end
	end
	for(i = 1; i < 63; i = i+1)begin
		if(~|map[i][0] && (map[i-1][0][1] || map[i+1][0][1] || map[i][1][1]))
			map_fill[i][0] = label_fill;
		if(~|map[i][63] && (map[i-1][63][1] || map[i+1][63][1] || map[i][62][1]))
			map_fill[i][63] = label_fill;
	end
	for(j = 1; j < 63; j = j+1)begin
		if(~|map[0][j] && (map[1][j][1] || map[0][j-1][1] || map[0][j+1][1]))
			map_fill[0][j] = label_fill;
		if(~|map[63][j] && (map[62][j][1] || map[63][j-1][1] || map[63][j+1][1]))
			map_fill[63][j] = label_fill;
	end
	if(~|map[0][0] && (map[0][1][1] || map[1][0][1]))
		map_fill[0][0] = label_fill;

	if(~|map[0][63] && (map[0][62][1] || map[1][63][1]))
		map_fill[0][63] = label_fill;

	if(~|map[63][0] && (map[63][1][1] || map[62][0][1]))
		map_fill[63][0] = label_fill;

	if(~|map[63][63] && (map[62][63][1] || map[63][62][1]))
		map_fill[63][63] = label_fill;
		
end
//------------------------------- fill & retrace label -------------------------------
reg label_nxt, label_d1_nxt;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		label <= 'd0;
		label_d1 <= 'd0;
	end
	else begin
		label <= label_nxt;
		label_d1 <= label_d1_nxt;
	end
end

always@(*)begin
	case(global_cs)
	/*
		FILL_START : begin
			label_nxt = 'd0;
			label_d1_nxt = 'd1;
		end*/
		FILL : begin
			//label_nxt = (fill_done_reg) ? (read_weight_done) ? label : label : ~label_d1;
			label_nxt = (fill_done_reg) ? label : ~label_d1;
			label_d1_nxt = (fill_done_reg) ? (read_weight_done) ? ~label_d1 : label_d1 : label;
		end
		RETRACE : begin
			label_nxt = (!retrace_read_ctrl) ? ~label_d1 : label;
			label_d1_nxt = (!retrace_read_ctrl) ? label : label_d1;
		end
		default : begin
			label_nxt = 'd0;
			label_d1_nxt = 'd1;
		end 
	endcase
end


//------------------------------- retrace -------------------------------
//retrace position
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		retrace_x <= 'd0;
		retrace_y <= 'd0;
		retrace_x_d1 <= 'd0;
		retrace_y_d1 <= 'd0;
	end
	else begin
		retrace_x <= retrace_x_tmp;
		retrace_y <= retrace_y_tmp;
		retrace_x_d1 <= (retrace_read_ctrl && global_cs == RETRACE) ? retrace_x_d1 : retrace_x;
		retrace_y_d1 <= (retrace_read_ctrl && global_cs == RETRACE) ? retrace_y_d1 : retrace_y;
	end
end
wire x_m1_en, x_p1_en, y_m1_en, y_p1_en;
assign x_m1_en = (|retrace_x);
assign x_p1_en = ~&retrace_x;
assign y_m1_en = (|retrace_y);
assign y_p1_en = ~&retrace_y;
assign retrace_x_p1 = retrace_x + 'd1;
assign retrace_x_m1 = retrace_x - 'd1;
assign retrace_y_p1 = retrace_y + 'd1;
assign retrace_y_m1 = retrace_y - 'd1;
assign label_retrace = (fill_done_reg) ? {1'b1,~label_d1} : {1'b1, label};


always@(*)begin
	if(y_p1_en && map[map_share_y][map_share_x] == label_retrace)
		direct = DOWN;
	else if(y_m1_en && map[retrace_y_m1][retrace_x] == label_retrace)
		direct = UP;
	else if(x_p1_en && map[retrace_y][retrace_x_p1] == label_retrace)
		direct = RIGHT;
	else
		direct = LEFT;
end
	
always@(*)begin
	if(global_cs == RETRACE || (fill_done_reg && read_weight_done))begin
		if(!retrace_read_ctrl || global_cs == FILL)
			case(direct)
				DOWN : begin
					retrace_x_tmp = retrace_x;
					retrace_y_tmp = retrace_y_p1;
				end
				UP : begin
					retrace_x_tmp = retrace_x;
					retrace_y_tmp = retrace_y_m1;
				end
				RIGHT : begin
					retrace_x_tmp = retrace_x_p1;
					retrace_y_tmp = retrace_y;
				end
				LEFT : begin
					retrace_x_tmp = retrace_x_m1;
					retrace_y_tmp = retrace_y;
				end
			endcase
		else begin
			retrace_x_tmp = retrace_x;
			retrace_y_tmp = retrace_y;
		end
	end
	else begin
		retrace_x_tmp = sink_x_reg[0];
		retrace_y_tmp = sink_y_reg[0];
	end
end

//for SRAM -> 1 cycle read, 1 cycle write
reg retrace_start;
wire retrace_read_ctrl_tmp;
reg retrace_read_ctrl_d1;
always@(posedge clk or negedge rst_n)
	if(!rst_n)begin
		retrace_start <= 'd0;
		retrace_read_ctrl <= 'd1;
		retrace_read_ctrl_d1 <= 'd1;
	end
	else begin
		retrace_start <= (global_cs == RETRACE) ? (!retrace_read_ctrl_d1) ? 'd1 : retrace_start : 'd0;
		retrace_read_ctrl <= retrace_read_ctrl_tmp;
		retrace_read_ctrl_d1 <= retrace_read_ctrl;
	end

assign same_retrace = retrace_y == retrace_y_d1 && retrace_x_d1[5] == retrace_x[5] && !retrace_read_ctrl;
assign retrace_read_ctrl_tmp = (global_cs == RETRACE) ? (!same_retrace) ? ~retrace_read_ctrl : retrace_read_ctrl : 'd1;


reg same_retrace_d1;
always@(posedge clk or negedge rst_n)
	if(!rst_n)
		same_retrace_d1 <= 'd0;
	else
		same_retrace_d1 <= same_retrace;

//write back to SRAM
always@(*)begin
	for(i = 0; i < 32; i = i+1)begin
		if(i == retrace_x_d1[4:0])
			retrace_write[(i<<2) +: 4] = net_id_reg[0];
		else
			retrace_write[(i<<2) +: 4] = (same_retrace_d1) ? retrace_write_reg[(i<<2) +: 4] : map_DO[(i<<2) +: 4];
	end
end


//------------------------------- output -------------------------------

wire busy_tmp;
wire [13:0] cost_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		busy <= 'd0;
		cost <= 'd0;
	end
	else begin
		busy <= busy_tmp;
		cost <= cost_tmp;
	end
end
assign busy_tmp = (bvalid_m_inf && bready_m_inf) ? 'd0 : (in_valid_d1 && !in_valid) ? 'd1 : busy;
//wire [3:0] weight_cost;
//assign weight_cost = weight_DO[retrace_x[4:0]*4 +: 4];
assign cost_tmp = (~|global_cs) ? 'd0 : (retrace_start && global_cs == RETRACE && !retrace_read_ctrl_d1) ? cost + share_data_reg : cost;


//------------------------------- output for dram -------------------------------
// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
assign arid_m_inf = 4'd0;
assign arsize_m_inf = 3'b100; //16 Byte in each transfer
assign arburst_m_inf = 2'b01; //INCR
assign arlen_m_inf = 8'd127;

wire arvalid_m_inf_tmp;
//wire [ADDR_WIDTH-1:0]  araddr_m_inf_tmp;




always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		arvalid_m_inf <= 'd0;
		//araddr_m_inf <= 'd0;
	end
	else begin
		arvalid_m_inf <= arvalid_m_inf_tmp;
		//araddr_m_inf <= araddr_m_inf_tmp;
	end
end
assign arvalid_m_inf_tmp = (arvalid_m_inf && arready_m_inf) ? 'd0 : (read_map || read_weight) ? 'd1 : arvalid_m_inf;
assign araddr_m_inf = (!arvalid_m_inf) ? 'd0 : (global_cs == READ_MAP) ? {16'd1, frame_id_reg, 11'd0} : {16'd2, frame_id_reg, 11'd0};


// (2)	axi read data channel 
wire rready_m_inf_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		rready_m_inf <= 'd0;
	end
	else begin
		rready_m_inf <= rready_m_inf_tmp;
	end
end
assign rready_m_inf_tmp = (rlast_m_inf) ? 'd0 : (arvalid_m_inf && arready_m_inf) ? 'd1 : rready_m_inf;

// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 

assign awid_m_inf = 4'd0;
assign awsize_m_inf = 3'b100; //16 Byte in each transfer
assign awburst_m_inf = 2'b01; //INCR
assign awlen_m_inf = 8'd127;

wire awvalid_m_inf_tmp;
wire [ADDR_WIDTH-1:0]awaddr_m_inf_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		awvalid_m_inf <= 'd0;
		awaddr_m_inf <= 'd0;
	end
	else begin
		awvalid_m_inf <= awvalid_m_inf_tmp;
		awaddr_m_inf <= awaddr_m_inf_tmp;
	end
end
assign awvalid_m_inf_tmp = (awvalid_m_inf && awready_m_inf) ? 'd0 : (retrace_done && net_done) ? 'd1 : awvalid_m_inf;
assign awaddr_m_inf_tmp = (awvalid_m_inf && awready_m_inf) ? 'd0 : (retrace_done && net_done) ? {16'd1, frame_id_reg, 11'd0} : awaddr_m_inf;

// (2)	axi write data channel 
wire wvalid_m_inf_tmp, wlast_m_inf_tmp;
//wire [DATA_WIDTH-1:0] wdata_m_inf_tmp;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		wvalid_m_inf <= 'd0;
		//wdata_m_inf <= 'd0;
		wlast_m_inf <= 'd0;
	end
	else begin
		wvalid_m_inf <= wvalid_m_inf_tmp;
		//wdata_m_inf <= wdata_m_inf_tmp;
		wlast_m_inf <= wlast_m_inf_tmp;
	end
end
assign wvalid_m_inf_tmp = (wlast_m_inf) ? 'd0 : (wdata_start) ? 'd1 : wvalid_m_inf;
assign wdata_m_inf = share_data_reg;
assign wlast_m_inf_tmp = (wlast_m_inf && wready_m_inf && wvalid_m_inf) ? 'd0 : (write_back_done && wvalid_m_inf) ? 'd1 : 'd0;

// (3)	axi write response channel 
wire bready_m_inf_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		bready_m_inf <= 'd0;
	end
	else begin
		bready_m_inf <= bready_m_inf_tmp;
	end
end
assign bready_m_inf_tmp = (awvalid_m_inf && awready_m_inf) ? 'd1 : (bvalid_m_inf && bready_m_inf) ? 'd0 : bready_m_inf;

// ---------------------------------------------------------------
//  							Memory 
// ---------------------------------------------------------------

//SRAM-MAP write
always@(*)
	case(global_cs)
		READ_MAP : begin
			map_WEB = !(rvalid_m_inf && rready_m_inf);
			map_addr_sram = sram_addr_cnt;
			map_DI = rdata_m_inf;
		end
		RETRACE : begin
			map_WEB = retrace_read_ctrl;
			map_addr_sram = {retrace_y_d1, retrace_x_d1[5]};
			map_DI = retrace_write;
		end
		WRITE_BACK : begin
			map_WEB = 'd1;
			map_addr_sram = (|sram_addr_cnt[6:1]) ? (wready_m_inf && wvalid_m_inf) ? sram_addr_cnt : sram_addr_cnt - 'd1 : sram_addr_cnt;
			map_DI = 'd0;
		end
		default : begin
			map_WEB = 'd1;
			map_addr_sram = 'd0;
			map_DI = 'd0;
		end
	endcase


//SRAM-WEIGHT write
always@(*)
	case(global_cs)
		FILL_START : begin
			weight_WEB = !((global_cs != READ_MAP) && rvalid_m_inf && rready_m_inf);
			weight_addr_sram = sram_addr_cnt;
			weight_DI = (weight_WEB) ? 'd0 : rdata_m_inf;
		end
		FILL : begin
			weight_WEB = !((global_cs != READ_MAP) && rvalid_m_inf && rready_m_inf);
			weight_addr_sram = sram_addr_cnt;
			weight_DI = (weight_WEB) ? 'd0 : rdata_m_inf;
		end
		RETRACE : begin
			weight_WEB = 'd1;
			weight_addr_sram = {retrace_y_d1, retrace_x_d1[5]};
			weight_DI = 'd0;
		end
		default : begin
			weight_WEB = 1'd1;
			weight_addr_sram = 'd0;
			weight_DI = 'd0;
		end
	endcase


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		sram_addr_cnt <= 'd0;
	end
	else begin
		sram_addr_cnt <= sram_addr_cnt_tmp;
	end
end
always@(*)begin
	case(global_cs)
		IDLE : 
			sram_addr_cnt_tmp = 'd0;
		WRITE_BACK : 
			sram_addr_cnt_tmp = ((awready_m_inf && awvalid_m_inf) || wdata_start) ? sram_addr_cnt + 'd1 : (wready_m_inf && wvalid_m_inf && ~&sram_addr_cnt) ? sram_addr_cnt + 'd1 : sram_addr_cnt;
		default : 
			sram_addr_cnt_tmp = (rlast_m_inf) ? 'd0 : (rvalid_m_inf && rready_m_inf) ? sram_addr_cnt + 'd1 : sram_addr_cnt;
	endcase
end

wire OE = 1'b1;
wire CS = 1'b1;


MEM128x128 MAP(	.A0  (map_addr_sram[0]),   .A1  (map_addr_sram[1]),   .A2  (map_addr_sram[2]),   .A3  (map_addr_sram[3]),   .A4  (map_addr_sram[4]),   .A5  (map_addr_sram[5]),   .A6  (map_addr_sram[6]),

				.DO0 (map_DO[0]),   .DO1 (map_DO[1]),   .DO2 (map_DO[2]),   .DO3 (map_DO[3]),   .DO4 (map_DO[4]),   .DO5 (map_DO[5]),   .DO6 (map_DO[6]),   .DO7 (map_DO[7]),
				.DO8 (map_DO[8]),   .DO9 (map_DO[9]),   .DO10(map_DO[10]),  .DO11(map_DO[11]),  .DO12(map_DO[12]),  .DO13(map_DO[13]),  .DO14(map_DO[14]),  .DO15(map_DO[15]),
				.DO16(map_DO[16]),  .DO17(map_DO[17]),  .DO18(map_DO[18]),  .DO19(map_DO[19]),  .DO20(map_DO[20]),  .DO21(map_DO[21]),  .DO22(map_DO[22]),  .DO23(map_DO[23]),
				.DO24(map_DO[24]),  .DO25(map_DO[25]),  .DO26(map_DO[26]),  .DO27(map_DO[27]),  .DO28(map_DO[28]),  .DO29(map_DO[29]),  .DO30(map_DO[30]),  .DO31(map_DO[31]),
				.DO32(map_DO[32]),  .DO33(map_DO[33]),  .DO34(map_DO[34]),  .DO35(map_DO[35]),  .DO36(map_DO[36]),  .DO37(map_DO[37]),  .DO38(map_DO[38]),  .DO39(map_DO[39]),
				.DO40(map_DO[40]),  .DO41(map_DO[41]),  .DO42(map_DO[42]),  .DO43(map_DO[43]),  .DO44(map_DO[44]),  .DO45(map_DO[45]),  .DO46(map_DO[46]),  .DO47(map_DO[47]),
				.DO48(map_DO[48]),  .DO49(map_DO[49]),  .DO50(map_DO[50]),  .DO51(map_DO[51]),  .DO52(map_DO[52]),  .DO53(map_DO[53]),  .DO54(map_DO[54]),  .DO55(map_DO[55]),
				.DO56(map_DO[56]),  .DO57(map_DO[57]),  .DO58(map_DO[58]),  .DO59(map_DO[59]),  .DO60(map_DO[60]),  .DO61(map_DO[61]),  .DO62(map_DO[62]),  .DO63(map_DO[63]),
				.DO64(map_DO[64]),  .DO65(map_DO[65]),  .DO66(map_DO[66]),  .DO67(map_DO[67]),  .DO68(map_DO[68]),  .DO69(map_DO[69]),  .DO70(map_DO[70]),  .DO71(map_DO[71]),
				.DO72(map_DO[72]),  .DO73(map_DO[73]),  .DO74(map_DO[74]),  .DO75(map_DO[75]),  .DO76(map_DO[76]),  .DO77(map_DO[77]),  .DO78(map_DO[78]),  .DO79(map_DO[79]),
				.DO80(map_DO[80]),  .DO81(map_DO[81]),  .DO82(map_DO[82]),  .DO83(map_DO[83]),  .DO84(map_DO[84]),  .DO85(map_DO[85]),  .DO86(map_DO[86]),  .DO87(map_DO[87]),
				.DO88(map_DO[88]),  .DO89(map_DO[89]),  .DO90(map_DO[90]),  .DO91(map_DO[91]),  .DO92(map_DO[92]),  .DO93(map_DO[93]),  .DO94(map_DO[94]),  .DO95(map_DO[95]),
				.DO96(map_DO[96]),  .DO97(map_DO[97]),  .DO98(map_DO[98]),  .DO99(map_DO[99]),  .DO100(map_DO[100]),.DO101(map_DO[101]),.DO102(map_DO[102]),.DO103(map_DO[103]),
				.DO104(map_DO[104]),.DO105(map_DO[105]),.DO106(map_DO[106]),.DO107(map_DO[107]),.DO108(map_DO[108]),.DO109(map_DO[109]),.DO110(map_DO[110]),.DO111(map_DO[111]),
				.DO112(map_DO[112]),.DO113(map_DO[113]),.DO114(map_DO[114]),.DO115(map_DO[115]),.DO116(map_DO[116]),.DO117(map_DO[117]),.DO118(map_DO[118]),.DO119(map_DO[119]),
				.DO120(map_DO[120]),.DO121(map_DO[121]),.DO122(map_DO[122]),.DO123(map_DO[123]),.DO124(map_DO[124]),.DO125(map_DO[125]),.DO126(map_DO[126]),.DO127(map_DO[127]),

				.DI0 (map_DI[0]),   .DI1 (map_DI[1]),   .DI2 (map_DI[2]),   .DI3 (map_DI[3]),   .DI4 (map_DI[4]),   .DI5 (map_DI[5]),   .DI6 (map_DI[6]),   .DI7 (map_DI[7]),
				.DI8 (map_DI[8]),   .DI9 (map_DI[9]),   .DI10(map_DI[10]),  .DI11(map_DI[11]),  .DI12(map_DI[12]),  .DI13(map_DI[13]),  .DI14(map_DI[14]),  .DI15(map_DI[15]),
				.DI16(map_DI[16]),  .DI17(map_DI[17]),  .DI18(map_DI[18]),  .DI19(map_DI[19]),  .DI20(map_DI[20]),  .DI21(map_DI[21]),  .DI22(map_DI[22]),  .DI23(map_DI[23]),
				.DI24(map_DI[24]),  .DI25(map_DI[25]),  .DI26(map_DI[26]),  .DI27(map_DI[27]),  .DI28(map_DI[28]),  .DI29(map_DI[29]),  .DI30(map_DI[30]),  .DI31(map_DI[31]),
				.DI32(map_DI[32]),  .DI33(map_DI[33]),  .DI34(map_DI[34]),  .DI35(map_DI[35]),  .DI36(map_DI[36]),  .DI37(map_DI[37]),  .DI38(map_DI[38]),  .DI39(map_DI[39]),
				.DI40(map_DI[40]),  .DI41(map_DI[41]),  .DI42(map_DI[42]),  .DI43(map_DI[43]),  .DI44(map_DI[44]),  .DI45(map_DI[45]),  .DI46(map_DI[46]),  .DI47(map_DI[47]),
				.DI48(map_DI[48]),  .DI49(map_DI[49]),  .DI50(map_DI[50]),  .DI51(map_DI[51]),  .DI52(map_DI[52]),  .DI53(map_DI[53]),  .DI54(map_DI[54]),  .DI55(map_DI[55]),
				.DI56(map_DI[56]),  .DI57(map_DI[57]),  .DI58(map_DI[58]),  .DI59(map_DI[59]),  .DI60(map_DI[60]),  .DI61(map_DI[61]),  .DI62(map_DI[62]),  .DI63(map_DI[63]),
				.DI64(map_DI[64]),  .DI65(map_DI[65]),  .DI66(map_DI[66]),  .DI67(map_DI[67]),  .DI68(map_DI[68]),  .DI69(map_DI[69]),  .DI70(map_DI[70]),  .DI71(map_DI[71]),
				.DI72(map_DI[72]),  .DI73(map_DI[73]),  .DI74(map_DI[74]),  .DI75(map_DI[75]),  .DI76(map_DI[76]),  .DI77(map_DI[77]),  .DI78(map_DI[78]),  .DI79(map_DI[79]),
				.DI80(map_DI[80]),  .DI81(map_DI[81]),  .DI82(map_DI[82]),  .DI83(map_DI[83]),  .DI84(map_DI[84]),  .DI85(map_DI[85]),  .DI86(map_DI[86]),  .DI87(map_DI[87]),
				.DI88(map_DI[88]),  .DI89(map_DI[89]),  .DI90(map_DI[90]),  .DI91(map_DI[91]),  .DI92(map_DI[92]),  .DI93(map_DI[93]),  .DI94(map_DI[94]),  .DI95(map_DI[95]),
				.DI96(map_DI[96]),  .DI97(map_DI[97]),  .DI98(map_DI[98]),  .DI99(map_DI[99]),  .DI100(map_DI[100]),.DI101(map_DI[101]),.DI102(map_DI[102]),.DI103(map_DI[103]),
				.DI104(map_DI[104]),.DI105(map_DI[105]),.DI106(map_DI[106]),.DI107(map_DI[107]),.DI108(map_DI[108]),.DI109(map_DI[109]),.DI110(map_DI[110]),.DI111(map_DI[111]),
				.DI112(map_DI[112]),.DI113(map_DI[113]),.DI114(map_DI[114]),.DI115(map_DI[115]),.DI116(map_DI[116]),.DI117(map_DI[117]),.DI118(map_DI[118]),.DI119(map_DI[119]),
				.DI120(map_DI[120]),.DI121(map_DI[121]),.DI122(map_DI[122]),.DI123(map_DI[123]),.DI124(map_DI[124]),.DI125(map_DI[125]),.DI126(map_DI[126]),.DI127(map_DI[127]),
				
				.CK(clk), .WEB(map_WEB), .OE(OE), .CS(CS));



MEM128x128 WEIGHT(	.A0  (weight_addr_sram[0]),   .A1  (weight_addr_sram[1]),   .A2  (weight_addr_sram[2]),   .A3  (weight_addr_sram[3]),   .A4  (weight_addr_sram[4]),   .A5  (weight_addr_sram[5]),   .A6  (weight_addr_sram[6]),

					.DO0 (weight_DO[0]),   .DO1 (weight_DO[1]),   .DO2 (weight_DO[2]),   .DO3 (weight_DO[3]),   .DO4 (weight_DO[4]),   .DO5 (weight_DO[5]),   .DO6 (weight_DO[6]),   .DO7 (weight_DO[7]),
					.DO8 (weight_DO[8]),   .DO9 (weight_DO[9]),   .DO10(weight_DO[10]),  .DO11(weight_DO[11]),  .DO12(weight_DO[12]),  .DO13(weight_DO[13]),  .DO14(weight_DO[14]),  .DO15(weight_DO[15]),
					.DO16(weight_DO[16]),  .DO17(weight_DO[17]),  .DO18(weight_DO[18]),  .DO19(weight_DO[19]),  .DO20(weight_DO[20]),  .DO21(weight_DO[21]),  .DO22(weight_DO[22]),  .DO23(weight_DO[23]),
					.DO24(weight_DO[24]),  .DO25(weight_DO[25]),  .DO26(weight_DO[26]),  .DO27(weight_DO[27]),  .DO28(weight_DO[28]),  .DO29(weight_DO[29]),  .DO30(weight_DO[30]),  .DO31(weight_DO[31]),
					.DO32(weight_DO[32]),  .DO33(weight_DO[33]),  .DO34(weight_DO[34]),  .DO35(weight_DO[35]),  .DO36(weight_DO[36]),  .DO37(weight_DO[37]),  .DO38(weight_DO[38]),  .DO39(weight_DO[39]),
					.DO40(weight_DO[40]),  .DO41(weight_DO[41]),  .DO42(weight_DO[42]),  .DO43(weight_DO[43]),  .DO44(weight_DO[44]),  .DO45(weight_DO[45]),  .DO46(weight_DO[46]),  .DO47(weight_DO[47]),
					.DO48(weight_DO[48]),  .DO49(weight_DO[49]),  .DO50(weight_DO[50]),  .DO51(weight_DO[51]),  .DO52(weight_DO[52]),  .DO53(weight_DO[53]),  .DO54(weight_DO[54]),  .DO55(weight_DO[55]),
					.DO56(weight_DO[56]),  .DO57(weight_DO[57]),  .DO58(weight_DO[58]),  .DO59(weight_DO[59]),  .DO60(weight_DO[60]),  .DO61(weight_DO[61]),  .DO62(weight_DO[62]),  .DO63(weight_DO[63]),
					.DO64(weight_DO[64]),  .DO65(weight_DO[65]),  .DO66(weight_DO[66]),  .DO67(weight_DO[67]),  .DO68(weight_DO[68]),  .DO69(weight_DO[69]),  .DO70(weight_DO[70]),  .DO71(weight_DO[71]),
					.DO72(weight_DO[72]),  .DO73(weight_DO[73]),  .DO74(weight_DO[74]),  .DO75(weight_DO[75]),  .DO76(weight_DO[76]),  .DO77(weight_DO[77]),  .DO78(weight_DO[78]),  .DO79(weight_DO[79]),
					.DO80(weight_DO[80]),  .DO81(weight_DO[81]),  .DO82(weight_DO[82]),  .DO83(weight_DO[83]),  .DO84(weight_DO[84]),  .DO85(weight_DO[85]),  .DO86(weight_DO[86]),  .DO87(weight_DO[87]),
					.DO88(weight_DO[88]),  .DO89(weight_DO[89]),  .DO90(weight_DO[90]),  .DO91(weight_DO[91]),  .DO92(weight_DO[92]),  .DO93(weight_DO[93]),  .DO94(weight_DO[94]),  .DO95(weight_DO[95]),
					.DO96(weight_DO[96]),  .DO97(weight_DO[97]),  .DO98(weight_DO[98]),  .DO99(weight_DO[99]),  .DO100(weight_DO[100]),.DO101(weight_DO[101]),.DO102(weight_DO[102]),.DO103(weight_DO[103]),
					.DO104(weight_DO[104]),.DO105(weight_DO[105]),.DO106(weight_DO[106]),.DO107(weight_DO[107]),.DO108(weight_DO[108]),.DO109(weight_DO[109]),.DO110(weight_DO[110]),.DO111(weight_DO[111]),
					.DO112(weight_DO[112]),.DO113(weight_DO[113]),.DO114(weight_DO[114]),.DO115(weight_DO[115]),.DO116(weight_DO[116]),.DO117(weight_DO[117]),.DO118(weight_DO[118]),.DO119(weight_DO[119]),
					.DO120(weight_DO[120]),.DO121(weight_DO[121]),.DO122(weight_DO[122]),.DO123(weight_DO[123]),.DO124(weight_DO[124]),.DO125(weight_DO[125]),.DO126(weight_DO[126]),.DO127(weight_DO[127]),

					.DI0 (weight_DI[0]),   .DI1 (weight_DI[1]),   .DI2 (weight_DI[2]),   .DI3 (weight_DI[3]),   .DI4 (weight_DI[4]),   .DI5 (weight_DI[5]),   .DI6 (weight_DI[6]),   .DI7 (weight_DI[7]),
					.DI8 (weight_DI[8]),   .DI9 (weight_DI[9]),   .DI10(weight_DI[10]),  .DI11(weight_DI[11]),  .DI12(weight_DI[12]),  .DI13(weight_DI[13]),  .DI14(weight_DI[14]),  .DI15(weight_DI[15]),
					.DI16(weight_DI[16]),  .DI17(weight_DI[17]),  .DI18(weight_DI[18]),  .DI19(weight_DI[19]),  .DI20(weight_DI[20]),  .DI21(weight_DI[21]),  .DI22(weight_DI[22]),  .DI23(weight_DI[23]),
					.DI24(weight_DI[24]),  .DI25(weight_DI[25]),  .DI26(weight_DI[26]),  .DI27(weight_DI[27]),  .DI28(weight_DI[28]),  .DI29(weight_DI[29]),  .DI30(weight_DI[30]),  .DI31(weight_DI[31]),
					.DI32(weight_DI[32]),  .DI33(weight_DI[33]),  .DI34(weight_DI[34]),  .DI35(weight_DI[35]),  .DI36(weight_DI[36]),  .DI37(weight_DI[37]),  .DI38(weight_DI[38]),  .DI39(weight_DI[39]),
					.DI40(weight_DI[40]),  .DI41(weight_DI[41]),  .DI42(weight_DI[42]),  .DI43(weight_DI[43]),  .DI44(weight_DI[44]),  .DI45(weight_DI[45]),  .DI46(weight_DI[46]),  .DI47(weight_DI[47]),
					.DI48(weight_DI[48]),  .DI49(weight_DI[49]),  .DI50(weight_DI[50]),  .DI51(weight_DI[51]),  .DI52(weight_DI[52]),  .DI53(weight_DI[53]),  .DI54(weight_DI[54]),  .DI55(weight_DI[55]),
					.DI56(weight_DI[56]),  .DI57(weight_DI[57]),  .DI58(weight_DI[58]),  .DI59(weight_DI[59]),  .DI60(weight_DI[60]),  .DI61(weight_DI[61]),  .DI62(weight_DI[62]),  .DI63(weight_DI[63]),
					.DI64(weight_DI[64]),  .DI65(weight_DI[65]),  .DI66(weight_DI[66]),  .DI67(weight_DI[67]),  .DI68(weight_DI[68]),  .DI69(weight_DI[69]),  .DI70(weight_DI[70]),  .DI71(weight_DI[71]),
					.DI72(weight_DI[72]),  .DI73(weight_DI[73]),  .DI74(weight_DI[74]),  .DI75(weight_DI[75]),  .DI76(weight_DI[76]),  .DI77(weight_DI[77]),  .DI78(weight_DI[78]),  .DI79(weight_DI[79]),
					.DI80(weight_DI[80]),  .DI81(weight_DI[81]),  .DI82(weight_DI[82]),  .DI83(weight_DI[83]),  .DI84(weight_DI[84]),  .DI85(weight_DI[85]),  .DI86(weight_DI[86]),  .DI87(weight_DI[87]),
					.DI88(weight_DI[88]),  .DI89(weight_DI[89]),  .DI90(weight_DI[90]),  .DI91(weight_DI[91]),  .DI92(weight_DI[92]),  .DI93(weight_DI[93]),  .DI94(weight_DI[94]),  .DI95(weight_DI[95]),
					.DI96(weight_DI[96]),  .DI97(weight_DI[97]),  .DI98(weight_DI[98]),  .DI99(weight_DI[99]),  .DI100(weight_DI[100]),.DI101(weight_DI[101]),.DI102(weight_DI[102]),.DI103(weight_DI[103]),
					.DI104(weight_DI[104]),.DI105(weight_DI[105]),.DI106(weight_DI[106]),.DI107(weight_DI[107]),.DI108(weight_DI[108]),.DI109(weight_DI[109]),.DI110(weight_DI[110]),.DI111(weight_DI[111]),
					.DI112(weight_DI[112]),.DI113(weight_DI[113]),.DI114(weight_DI[114]),.DI115(weight_DI[115]),.DI116(weight_DI[116]),.DI117(weight_DI[117]),.DI118(weight_DI[118]),.DI119(weight_DI[119]),
					.DI120(weight_DI[120]),.DI121(weight_DI[121]),.DI122(weight_DI[122]),.DI123(weight_DI[123]),.DI124(weight_DI[124]),.DI125(weight_DI[125]),.DI126(weight_DI[126]),.DI127(weight_DI[127]),

					.CK(clk), .WEB(weight_WEB), .OE(OE), .CS(CS));



endmodule
