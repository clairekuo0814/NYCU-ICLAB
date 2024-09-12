module CC(
    //Input Port
    clk,
    rst_n,
	in_valid,
	mode,
    xi,
    yi,

    //Output Port
    out_valid,
	xo,
	yo
    );

input               clk, rst_n, in_valid;
input       [1:0]   mode;
input       [7:0]   xi, yi;  

output reg          out_valid;
output reg  [7:0]   xo, yo;
//==============================================//
//             Parameter and Integer            //
//==============================================//



//==============================================//
//            FSM State Declaration             //
//==============================================//

parameter IDLE = 3'd0, START = 3'd1, CL_AC_PRE = 3'd2, TR_PRE = 3'd3, WORK = 3'd4, TR_R = 3'd5, TR_L = 3'd6, TR_STOP = 3'd7;
parameter O_IDLE = 1'd0, OUT = 1'd1;
parameter MODE_TR = 2'b00, MODE_CL = 2'b01, MODE_AC = 2'b10;

//==============================================//
//                 reg declaration              //
//==============================================//
//FSM FF
reg [2:0] comp_cs;
reg       out_cs;
//input FF
reg cnt;
reg [31:0] x_in;
reg [31:0] y_in;
reg [1:0] mode_save;
//FF
//Cal block1
reg signed [8:0] delta_x_l;
reg signed [8:0] delta_x_r;
reg signed [8:0] delta_y;
reg signed [7:0] start_p;
reg signed [7:0] end_p;
reg        [7:0] layer_cnt;
reg signed [7:0] y_p;
reg signed [7:0] xo_end;
//Cal block2
reg signed [6:0] equation_a, equation_b;
reg signed [11:0] constant;


//comb
//FSM
reg [2:0] comp_ns;
reg       out_ns;
//input
wire        cnt_temp;
wire [31:0] x_in_temp;
wire [31:0] y_in_temp;
wire        y_in_valid;
wire [1:0] mode_save_temp;

//input naming
wire signed [7:0] xul, xur, yu, xdl, xdr, yd;

//Cal block1
reg signed[7:0] minus1_a, minus1_b;
wire signed[8:0] minus1;
wire signed [8:0] delta_x_l_in, delta_x_r_in, delta_y_in;
wire signed [8:0] delta_x_l_temp;
wire signed [8:0] delta_x_r_temp;
wire signed [8:0] delta_y_temp;
wire signed [7:0] start_p_temp;
wire signed [7:0] end_p_temp;
wire signed [7:0] layer_cnt_temp;
wire m_l, m_r;
reg signed [7:0] y_p_temp;
wire signed [7:0] xo_end_temp;
wire signed [8:0] layer_comp;
wire signed [8:0] delta_x;
wire signed [16:0] mult;
wire signed [8:0] plus;
wire cut;
wire signed [7:0] x_point;
wire signed [7:0] find_p_plus;
wire signed [7:0] find_p;
wire m_judge;

//Cal block2
wire signed [5:0] a1, a2, b1, b2, c1, c2, d1, d2;
wire signed [6:0] line_delta_x, line_delta_y;
wire signed [6:0] equation_a_temp, equation_b_temp;
wire signed [11:0] const_temp;
wire signed [11:0] const_pos;
wire [12:0] circle_r_sqr;
wire signed [6:0] c1_d1, c2_d2;
wire [12:0] ab_sqr;
wire signed [27:0] equation_point_sqr;
wire signed [27:0] judge_d;
wire [1:0] judge;

//Cal block3
wire signed [7:0] x0, y0, x1, y1, x2, y2, x3, y3;
wire signed [16:0] area_temp;
wire [15:0] area;


//ctrl
wire      compute;
wire      comp;

//output
reg [7:0] xo_temp;
reg  [7:0] yo_temp;
wire       out_valid_temp;

//==============================================//
//             Current State Block              //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        comp_cs <= 3'd0;
        out_cs <= 1'd0;
    end
    else begin
        comp_cs <= comp_ns;
        out_cs <= out_ns;
    end
end

//==============================================//
//              Next State Block                //
//==============================================//

always @(*)begin
    case(comp_cs)
        IDLE        : comp_ns = (in_valid)        ? START : IDLE;
        START       : comp_ns = (cnt)             ? CL_AC_PRE  : START;
        CL_AC_PRE   : comp_ns = TR_PRE;
        TR_PRE      : comp_ns = (|mode)           ? WORK : TR_R;
        WORK        : comp_ns = IDLE;
        TR_R        : comp_ns = (comp)            ? IDLE  : (compute) ? TR_L : TR_STOP;
        TR_L        : comp_ns = TR_R;
        TR_STOP     : comp_ns = (comp)            ? IDLE  : (compute) ? TR_L : TR_STOP;
        default     : comp_ns = IDLE;
    endcase
end

always @(*)begin
    case(out_cs)
        O_IDLE : out_ns = (comp_cs == WORK || comp_cs == TR_R) ? OUT : O_IDLE;
        OUT   : out_ns = (comp) ? O_IDLE : OUT;
    endcase
end

//==============================================//
//                  Input Block                 //
//==============================================//
//in_done judge

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 1'd0;
    end
    else begin
        cnt <= cnt_temp;
    end
end
assign cnt_temp = (in_valid);

//input save
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        mode_save <= 2'd0;
        x_in <= 32'd0;
        y_in <= 32'd0;
    end
    else begin
        mode_save <= mode_save_temp;
        x_in <= x_in_temp;
        y_in <= y_in_temp;
    end
end

assign mode_save_temp = (in_valid) ? mode : mode_save;
assign x_in_temp = (in_valid) ? {x_in[23:0], xi} : x_in;
assign y_in_temp = (in_valid) ? {y_in[23:0], yi} : y_in;

//==============================================//
//              coordinate naming               //
//==============================================//

assign xul = (comp_cs == TR_PRE) ? x_in[23:16] : x_in[31:24];
assign xur = x_in[23:16];
assign yu  = (comp_cs == TR_PRE) ? y_in[23:16] : y_in[31:24];
assign xdl = (comp_cs == TR_PRE) ? x_in[7:0]   : x_in[15:8];
assign xdr = x_in[7:0];
assign yd  = (comp_cs == TR_PRE) ? y_in[7:0]   : y_in[15:8];
//==============================================//
//              Calculation Block1              //
//==============================================//

//share HW
always@(*)begin
    case(comp_cs)
        TR_PRE : begin
            minus1_a = xul;
            minus1_b = xdl;
        end
        CL_AC_PRE : begin
            minus1_a = {{2{a1[5]}}, a1};
            minus1_b= {{2{b1[5]}}, b1};
        end
        default : begin
            minus1_a = 0;
            minus1_b = 0;
        end
    endcase
end
assign minus1 = minus1_a - minus1_b;


//delta compute & save
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        delta_x_l <= 9'd0;
        delta_x_r <= 9'd0;
        delta_y <= 9'd1;
    end
    else begin
        delta_x_l <= delta_x_l_temp;
        delta_x_r <= delta_x_r_temp;
        delta_y <= delta_y_temp;
    end
end
assign delta_x_l_in = minus1;
assign delta_x_r_in = (xur - xdr);
assign delta_y_in = (yu - yd);
assign delta_x_l_temp = (comp_cs == TR_PRE) ? delta_x_l_in : delta_x_l;
assign delta_x_r_temp = (comp_cs == TR_R) ? delta_x_r_in : delta_x_r; 
assign delta_y_temp = (comp_cs == TR_PRE) ? delta_y_in : delta_y;



//start point & end point save

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        layer_cnt = 0;
    end else begin
        layer_cnt = layer_cnt_temp;
    end
end
assign layer_cnt_temp = (comp_cs == TR_R) ? layer_cnt + 1 : (|comp_cs)? layer_cnt : 0;

assign m_l = delta_x_l[8];
assign m_r = delta_x_r[8];
assign m_judge = (comp_cs == TR_R) ? m_r : m_l;
assign layer_comp = {1'd0,layer_cnt};
assign delta_x = (comp_cs == TR_R) ? delta_x_r : delta_x_l;
assign mult = delta_x * layer_comp;
assign plus = mult / delta_y;
assign cut = (mult == delta_y * plus);
assign x_point = (comp_cs == TR_R) ? xdr : xdl;
assign find_p_plus = x_point + plus;
assign find_p = (m_judge == 1 && cut == 0) ? find_p_plus - 1 : find_p_plus;

assign start_p_temp = (comp_cs == TR_PRE || comp_cs == TR_L) ? find_p : start_p;
assign end_p_temp = (comp_cs == TR_R) ? find_p : end_p;

//output
assign y_p_temp = (comp_cs == TR_L || comp_cs == TR_PRE) ? yd + layer_cnt : y_p;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        y_p <= 8'd0;
        start_p <= 8'd0;
        end_p <= 8'd0;
    end else begin
        y_p <= y_p_temp;
        start_p <= start_p_temp;
        end_p <= end_p_temp;
    end
end

assign xo_end_temp = (compute) ? (comp_cs == TR_R) ? end_p_temp : end_p : xo_end;
assign compute = (xo == xo_end && (comp_cs == TR_R || (&comp_cs))) || (comp_cs == TR_R && ~out_cs);
assign comp = (yo == yu) && compute;


//==============================================//
//              Calculation Block2              //
//==============================================//
///////////revise
//left
//CL_AC_PRE
assign a1 = x_in[13:8];
assign a2 = y_in[13:8];
assign b1 = x_in[5:0];
assign b2 = y_in[5:0];
//WORK
assign c1 = x_in[13:8];
assign c2 = y_in[13:8];
assign d1 = x_in[5:0];
assign d2 = y_in[5:0];

//找方程式
assign line_delta_x = minus1[6:0];
assign line_delta_y = (a2 - b2);

assign equation_a_temp = (comp_cs == CL_AC_PRE) ? line_delta_y : equation_a;
assign equation_b_temp = (comp_cs == CL_AC_PRE) ? (~line_delta_x + 1) : equation_b;

assign const_pos = (equation_a_temp * a1 + equation_b_temp * a2);
assign const_temp = (comp_cs == CL_AC_PRE) ? ~const_pos + 1 : constant;


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        equation_a <= 7'd0;
        equation_b <= 7'd0;
        constant <= 12'd0;
    end else begin
        equation_a <= equation_a_temp;
        equation_b <= equation_b_temp;
        constant <= const_temp;
    end
end


//圓半徑平方
assign c1_d1 = c1-d1;
assign c2_d2 = c2-d2;
assign circle_r_sqr = (c1_d1) * (c1_d1) + (c2_d2) * (c2_d2);

//a^2 + b^2
assign ab_sqr = equation_a * equation_a + equation_b * equation_b;

//( ax0 + by0 + c ) ^ 2
assign equation_point_sqr = (equation_a * c1 + equation_b * c2 + constant) * (equation_a * c1 + equation_b * c2 + constant);
assign judge_d = circle_r_sqr * ab_sqr - equation_point_sqr;
assign judge = (comp_cs != WORK || judge_d[27]) ? 0: (|judge_d) ? 1 : 2;




//==============================================//
//              Calculation Block3              //
//==============================================//
assign x0 = x_in[31:24];
assign x1 = x_in[23:16];
assign x2 = x_in[15:8];
assign x3 = x_in[7:0];
assign y0 = y_in[31:24];
assign y1 = y_in[23:16];
assign y2 = y_in[15:8];
assign y3 = y_in[7:0];

assign area_temp = ((x0*y1 - x1*y0) + (x1*y2 - x2*y1) + (x2*y3 - x3*y2) + (x3*y0 - x0*y3)) ;
assign area = (comp_cs == WORK) ? (area_temp[16]) ? (~area_temp + 1) >> 1 : area_temp >> 1 : 0;



//==============================================//
//                Output Block                  //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        xo <= 8'd0;
        yo <= 8'd0;
        out_valid <= 1'd0;
        xo_end <= 8'd0;
    end else begin
        xo <= xo_temp;
        yo <= yo_temp;
        out_valid <= out_valid_temp;
        xo_end <= xo_end_temp;
    end
end

assign out_valid_temp = (comp_cs[2] ^ comp);


always@(*)begin
    case(mode_save)
        MODE_TR : xo_temp = (compute) ? start_p : xo + 1;
        MODE_CL : xo_temp = 0;
        MODE_AC : xo_temp = area[15:8];
        default : xo_temp = 0;
    endcase
end

always@(*)begin
    case(mode_save)
        MODE_TR : yo_temp = (compute) ? y_p : yo;
        MODE_CL : yo_temp = {6'd0, judge};
        MODE_AC : yo_temp = area[7:0];
        default : yo_temp = 0;
    endcase
end


endmodule