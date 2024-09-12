//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Hsien-Chi Peng (jhpeng2012@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


/******************design start****************/
parameter inst_rnd = 3'b000;
wire zctr = 1'b1;
//FF
reg [31:0] kernel_save[26:0];
reg [31:0] weight_save[3:0];
reg [1:0]  opt_save;
reg [3:0] cell_cnt;
reg [2:0] img_cnt;
reg lower_cnt;
reg [4:0] delay_cnt;

//combinational
reg [31:0] kernel_save_tmp[26:0];
reg [31:0] weight_save_tmp[3:0];
wire [1:0]  opt_save_tmp;
wire [3:0] cell_cnt_tmp;
wire [2:0] img_cnt_tmp;
wire lower_cnt_tmp;
wire [4:0] delay_cnt_tmp;
integer i, j;



//---------------------- input save -----------------//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0; i<27; i = i+1)
            kernel_save[i] <= 'b0;
        for(i=0; i<4; i = i+1)
            weight_save[i] <= 'd0;
        opt_save    <= 'd0;
    end
    else begin
        for(i=0; i<27; i = i+1)
            kernel_save[i] <= kernel_save_tmp[i];
        for(i=0; i<4; i = i+1)
            weight_save[i] <= weight_save_tmp[i];
        opt_save    <= opt_save_tmp;
    end
end

genvar gen_i;
always@(*)begin
    for(i=0; i < 27; i = i+1)begin
        kernel_save_tmp[i] = kernel_save[i];
    end
    if({lower_cnt,img_cnt,cell_cnt} < 27 && in_valid)
        kernel_save_tmp[{img_cnt,cell_cnt}] = Kernel;
end

always@(*)begin
    for(i=0; i < 4; i = i+1)begin
        weight_save_tmp[i] = weight_save[i];
    end
    if({lower_cnt,img_cnt,cell_cnt} < 4 && in_valid)
        weight_save_tmp[cell_cnt] = Weight;
end

assign opt_save_tmp = (in_valid && {lower_cnt,img_cnt,cell_cnt} < 1 ) ? Opt : opt_save;


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cell_cnt <= 'd0;
        img_cnt <= 'd0;
        lower_cnt <= 'd0;
        delay_cnt <= 'd0;
    end
    else begin
        cell_cnt <= cell_cnt_tmp;
        img_cnt <= img_cnt_tmp;
        lower_cnt <= lower_cnt_tmp;
        delay_cnt <= delay_cnt_tmp;
    end
end

assign cell_cnt_tmp =  (out_valid) ? 'd0 : (lower_cnt && img_cnt == 'd2 && cell_cnt == 'd15) ? cell_cnt : (in_valid) ? cell_cnt + 1 : cell_cnt;
assign img_cnt_tmp =  (out_valid) ? 'd0 : (img_cnt == 'd2 && &cell_cnt) ? (lower_cnt) ? img_cnt : 'd0 : (cell_cnt == 15) ? img_cnt + 1 : img_cnt;
assign lower_cnt_tmp =  (out_valid) ? 'd0 : (img_cnt == 'd2 && &cell_cnt) ? 'd1 :lower_cnt;
assign delay_cnt_tmp =  (out_valid) ? 'd0 : (lower_cnt && img_cnt == 'd2 && cell_cnt == 'd15 && !in_valid) ? delay_cnt + 1 : delay_cnt;

//------------------ padding & convolution -------------//
reg [31:0] in_reg[13:0];
wire [31:0] in_reg_tmp[13:0];
reg [31:0] padding_reg[15:0];
wire [31:0] padding_reg_tmp[15:0];
reg [31:0] padding_compute[15:0];
wire [31:0] padding_new;
wire padding_start;

//convolution after 9 cycles, need 15FF(in_reg)
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0; i<14; i = i+1)
            in_reg[i] <= 'd0;
        for(i=0; i<16; i = i+1)
            padding_reg[i] <= 'd0;
    end
    else begin
        for(i=0; i<14; i = i+1)
            in_reg[i] <= in_reg_tmp[i];
        for(i=0; i<16; i = i+1)
            padding_reg[i] <= padding_reg_tmp[i];
    end
end

generate
    for(gen_i=1; gen_i < 14; gen_i = gen_i+1)begin
        assign in_reg_tmp[gen_i] = (in_valid) ? in_reg[gen_i-1] : in_reg[gen_i];
    end
    assign in_reg_tmp[0] = (in_valid) ? Img : in_reg[0];
endgenerate

//save data after padding & convolution
generate
    for(gen_i=0; gen_i < 16; gen_i = gen_i+1)begin
        assign padding_reg_tmp[gen_i] = (padding_start) ? padding_compute[gen_i] : padding_reg[gen_i];
    end
endgenerate

//choose mult a,b
wire [31:0] mult_a[8:0];
wire [31:0] mult_b[8:0];
wire [31:0] mult_ans[8:0];
wire [31:0] sum3_1[2:0];
wire [31:0] sum2_a, sum2_ans;
reg [31:0] sum2_b;

//calculate x, y coordinate of convolution
reg [1:0] x, y;
wire [3:0] xy_tmp;
reg [1:0] xy_img;
wire [1:0] xy_img_tmp;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        {y,x} <= 'd0;
        xy_img <= 'd0;
    end
    else begin
        {y,x} <= xy_tmp;
        xy_img <= xy_img_tmp;
    end
end
assign xy_tmp = (out_valid) ? 'd0 : ({lower_cnt, img_cnt, cell_cnt} >= 'd9) ? {y,x} + 'd1 : 'd0;
assign xy_img_tmp = (out_valid) ? 'd0 : ({y,x} == 15) ? (xy_img == 2) ? 'd0 : xy_img + 1 : xy_img;

generate
    for(gen_i=0; gen_i < 9; gen_i = gen_i+1)begin
        assign mult_b[gen_i] = kernel_save[xy_img * 9 + gen_i];
    end
endgenerate

wire [3:0] num_3, num_4, num_5, num_7, num_8, num_9, num_11, num_12, num_13;
assign num_3 = (delay_cnt >= 9) ? 'd0 : ('d3 - delay_cnt);
assign num_4 = (delay_cnt >= 9) ? 'd0 : ('d4 - delay_cnt);
assign num_5 = (delay_cnt >= 9) ? 'd0 : ('d5 - delay_cnt);
assign num_7 = (delay_cnt >= 9) ? 'd0 : ('d7 - delay_cnt);
assign num_8 = (delay_cnt >= 9) ? 'd0 : ('d8 - delay_cnt);
assign num_9 = (delay_cnt >= 9) ? 'd0 : ('d9 - delay_cnt);
assign num_11 = (delay_cnt >= 9) ? 'd0 : ('d11 - delay_cnt);
assign num_12 = (delay_cnt >= 9) ? 'd0 : ('d12 - delay_cnt);
assign num_13 = (delay_cnt >= 9) ? 'd0 : ('d13 - delay_cnt);

assign mult_a[0] = (~|x) ? (opt_save[0]) ? 'd0 : mult_a[1] : (~|y) ? (opt_save[0]) ? 'd0 : mult_a[3] : in_reg[num_13];
assign mult_a[1] = (~|y) ? (opt_save[0]) ? 'd0 : in_reg[num_8] : in_reg[num_12];
assign mult_a[2] = (&x) ? (opt_save[0]) ? 'd0 : mult_a[1] : (~|y) ? (opt_save[0]) ? 'd0 : mult_a[5] : in_reg[num_11];
assign mult_a[3] = (~|x) ? (opt_save[0]) ? 'd0 : in_reg[num_8] : in_reg[num_9];
assign mult_a[4] = in_reg[num_8];
assign mult_a[5] = (&x) ? (opt_save[0]) ? 'd0 : in_reg[num_8] : in_reg[num_7];
assign mult_a[6] = (~|x) ? (opt_save[0]) ? 'd0 : mult_a[7] : (&y) ? (opt_save[0]) ? 'd0 : mult_a[3] : in_reg[num_5];
assign mult_a[7] = (&y) ? (opt_save[0]) ? 'd0 : in_reg[num_8] : in_reg[num_4];
assign mult_a[8] = (&x) ? (opt_save[0]) ? 'd0 : mult_a[7] : (&y) ? (opt_save[0]) ? 'd0 : mult_a[5] : in_reg[num_3];



generate
    for(gen_i=0; gen_i<9; gen_i = gen_i+1)begin
        DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        mult_inst ( .a(mult_a[gen_i]), .b(mult_b[gen_i]), .rnd(inst_rnd), .z(mult_ans[gen_i]));
    end
endgenerate
//add 3 row data after mult
generate
    for(gen_i=0; gen_i<3; gen_i = gen_i+1)begin
        DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
        sum3_inst (
        .a(mult_ans[gen_i*3]),
        .b(mult_ans[gen_i*3 + 1]),
        .c(mult_ans[gen_i*3 + 2]),
        .rnd(inst_rnd),
        .z(sum3_1[gen_i]));
    end
endgenerate
//save every row after sum them up
reg [31:0] sum3_1_save[2:0];
reg [31:0] sum3_1_save_tmp[2:0];
always@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        for(i=0; i<3; i = i+1)
            sum3_1_save[i] <= 'd0;
    end
    else begin
        for(i=0; i<3; i = i+1)
            sum3_1_save[i] <= sum3_1_save_tmp[i];
    end

always@(*)begin
    for(i=0; i<3; i = i+1)
        sum3_1_save_tmp[i] = (delay_cnt >= 9) ? 'd0 : ({lower_cnt,img_cnt,cell_cnt} > 8) ? sum3_1[i] : 'd0;
end
//add 3 row data
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
        sum3_U2 (
        .a(sum3_1_save[0]),
        .b(sum3_1_save[1]),
        .c(sum3_1_save[2]),
        .rnd(inst_rnd),
        .z(sum2_a));
reg [31:0] sum2_a_save;
always@(posedge clk or negedge rst_n)
    if(!rst_n)begin
            sum2_a_save <= 'd0;
    end
    else begin
            sum2_a_save <= sum2_a;
    end

//choose position to update, add original value and convolution value(3*img)
always@(*)begin
    case({y,x})
        'd0:sum2_b = padding_reg[14];
        'd1:sum2_b = padding_reg[15];
        'd2:sum2_b = padding_reg[0];
        'd3:sum2_b = padding_reg[1];
        'd4:sum2_b = padding_reg[2];
        'd5:sum2_b = padding_reg[3];
        'd6:sum2_b = padding_reg[4];
        'd7:sum2_b = padding_reg[5];
        'd8:sum2_b = padding_reg[6];
        'd9:sum2_b = padding_reg[7];
        'd10:sum2_b = padding_reg[8];
        'd11:sum2_b = padding_reg[9];
        'd12:sum2_b = padding_reg[10];
        'd13:sum2_b = padding_reg[11];
        'd14:sum2_b = padding_reg[12];
        'd15:sum2_b = padding_reg[13];
        default:sum2_b = 'd0;
    endcase
end

wire dis_start;
wire [31:0] add1_a, add1_b;
wire [31:0] add1_a_dis, add1_b_dis;
assign add1_a = (dis_start) ? add1_a_dis : sum2_a_save;
assign add1_b = (dis_start) ? add1_b_dis : sum2_b;

//update padding & convolution value
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_U1 ( .a(add1_a), .b(add1_b), .rnd(inst_rnd), .z(sum2_ans));

assign padding_new = (((~|xy_img) && ({y,x} >= 'd2)) || (xy_img[0] && ({y,x} <= 'd1)) ) ? sum2_a_save : sum2_ans;

always@(*)begin
    for(i=0; i<16; i = i+1)begin
        padding_compute[i] = padding_reg[i];
    end
    case({y,x})
        'd0 : padding_compute[14] = padding_new;
        'd1 : padding_compute[15] = padding_new;
        'd2 : padding_compute[0] = padding_new;
        'd3 : padding_compute[1] = padding_new;
        'd4 : padding_compute[2] = padding_new;
        'd5 : padding_compute[3] = padding_new;
        'd6 : padding_compute[4] = padding_new;
        'd7 : padding_compute[5] = padding_new;
        'd8 : padding_compute[6] = padding_new;
        'd9 : padding_compute[7] = padding_new;
        'd10 : padding_compute[8] = padding_new;
        'd11 : padding_compute[9] = padding_new;
        'd12 : padding_compute[10] = padding_new;
        'd13 : padding_compute[11] = padding_new;
        'd14 : padding_compute[12] = padding_new;
        'd15 : padding_compute[13] = padding_new;
    endcase

    /*if(|{y,x})
        padding_compute[{y,x}-1] = padding_new;
    else
        padding_compute[15] = padding_new;*/
end

assign padding_start = (delay_cnt >= 11) ? 'd0 : ({lower_cnt,img_cnt,cell_cnt} > 10) ? 'd1 : 'd0;

//------------------ equalization -------------//
reg equa_start, equa_start_d1, equa_start_d2;
wire equa_start_tmp;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        equa_start <= 'd0;
        equa_start_d1 <= 'd0;
        equa_start_d1 <= 'd0;
    end
    else begin
        equa_start <= equa_start_tmp;
        equa_start_d1 <= equa_start;
        equa_start_d2 <= equa_start_d1;
    end
end

assign equa_start_tmp = ({xy_img,y,x} == 6'b100111) ? 'd1 : ({xy_img,y,x} == 6'b000111) ? 'd0 : equa_start;

reg [31:0] padding_array[5:0][5:0];
always@(*)begin
    for(int i=1; i < 5; i = i+1)begin
        for(int j=1; j < 5; j = j+1)begin
        padding_array[i][j] = padding_reg[(i-1) * 4 + j -1];
        end
    end
    for(int j=1; j < 5; j = j+1)begin
        padding_array[0][j] = (opt_save[0]) ? 'd0 : padding_reg[j-1];
    end
    for(int j=1; j < 5; j = j+1)begin
        padding_array[5][j] = (opt_save[0]) ? 'd0 : padding_reg[11 + j];
    end
    for(int i=0; i < 6; i = i+1)begin
        padding_array[i][0] = (opt_save[0]) ? 'd0 : padding_array[i][1];
    end
    for(int i=0; i < 6; i = i+1)begin
        padding_array[i][5] = (opt_save[0]) ? 'd0 : padding_array[i][4];
    end
end
reg [31:0] equa_sum3_array[2:0][2:0];
always@(*)begin
    case({y,x})
        'd8 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i][j];
                end
            end
        end
        'd9 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i][j + 1];
                end
            end
        end
        'd10 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i][j + 2];
                end
            end
        end
        'd11 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i][j + 3];
                end
            end
        end
        'd12 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 1][j];
                end
            end
        end
        'd13 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 1][j + 1];
                end
            end
        end
        'd14 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 1][j + 2];
                end
            end
        end
        'd15 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 1][j + 3];
                end
            end
        end
        'd0 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 2][j];
                end
            end
        end
        'd1 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 2][j + 1];
                end
            end
        end
        'd2 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 2][j + 2];
                end
            end
        end
        'd3 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 2][j + 3];
                end
            end
        end
        'd4 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 3][j];
                end
            end
        end
        'd5 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 3][j + 1];
                end
            end
        end
        'd6 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 3][j + 2];
                end
            end
        end
        'd7 : begin
            for(int i=0; i < 3; i = i+1)begin
                for(int j=0; j < 3; j = j+1)begin
                    equa_sum3_array[i][j] = padding_array[i + 3][j + 3];
                end
            end
        end
    endcase
end

wire [31:0] equa_sum3_1[2:0];
//add 3 row data after mult
generate
    for(gen_i=0; gen_i<3; gen_i = gen_i+1)begin
        DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
        sum3_equa (
        .a(equa_sum3_array[gen_i][0]),
        .b(equa_sum3_array[gen_i][1]),
        .c(equa_sum3_array[gen_i][2]),
        .rnd(inst_rnd),
        .z(equa_sum3_1[gen_i]));
    end
endgenerate

reg [31:0] equal_sum3_1_reg[2:0];
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        for(int i=0; i < 3; i = i+1)
            equal_sum3_1_reg[i] <= 'd0;
    else
        for(int i=0; i < 3; i = i+1)
            equal_sum3_1_reg[i] <= (equa_start) ? equa_sum3_1[i] : equal_sum3_1_reg[i];
end

wire [31:0] equa_sum3_2;
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
sum3_equa (
.a(equal_sum3_1_reg[0]),
.b(equal_sum3_1_reg[1]),
.c(equal_sum3_1_reg[2]),
.rnd(inst_rnd),
.z(equa_sum3_2));

reg [31:0] equal_sum3_2_reg;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        equal_sum3_2_reg <= 'd0;
    else
        equal_sum3_2_reg <= (equa_start_d1) ? equa_sum3_2 : equal_sum3_2_reg;
end

reg [31:0] equa_reg[15:0];
reg [31:0] equa_reg_tmp[15:0];
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(int i=0; i < 16; i = i+1)
            equa_reg[i] <= 'd0;
    end
    else begin
        for(int i=0; i < 16; i = i+1)
            equa_reg[i] <= equa_reg_tmp[i];
    end
end
wire [31:0] div_result_1;

always@(*)begin
    for(i=0; i<16; i = i+1)begin
        equa_reg_tmp[i] = equa_reg[i];
    end
    if(equa_start_d2)begin
        case({y,x})
            'd0 : equa_reg_tmp[6] = div_result_1;
            'd1 : equa_reg_tmp[7] = div_result_1;
            'd2 : equa_reg_tmp[8] = div_result_1;
            'd3 : equa_reg_tmp[9] = div_result_1;
            'd4 : equa_reg_tmp[10] = div_result_1;
            'd5 : equa_reg_tmp[11] = div_result_1;
            'd6 : equa_reg_tmp[12] = div_result_1;
            'd7 : equa_reg_tmp[13] = div_result_1;
            'd8 : equa_reg_tmp[14] = div_result_1;
            'd9 : equa_reg_tmp[15] = div_result_1;
            'd10 : equa_reg_tmp[0] = div_result_1;
            'd11 : equa_reg_tmp[1] = div_result_1;
            'd12 : equa_reg_tmp[2] = div_result_1;
            'd13 : equa_reg_tmp[3] = div_result_1;
            'd14 : equa_reg_tmp[4] = div_result_1;
            'd15 : equa_reg_tmp[5] = div_result_1;
        endcase
    end
end


//------------------ max pooling -------------//
wire maxpool_start;
assign maxpool_start = ({xy_img,y,x} >= 6'b000111 && {xy_img,y,x} <= 6'b001010 && lower_cnt);

reg [31:0] maxpool [3:0];
reg [31:0] maxpool_tmp [3:0];
reg [31:0] cmp1_a_maxpool, cmp1_b_maxpool, cmp2_a_maxpool, cmp2_b_maxpool;
wire [31:0] cmp1_ans_a, cmp1_ans_b, cmp2_ans_a, cmp2_ans_b;
wire [31:0] cmp3_ans_a, cmp3_ans_b, cmp4_ans_a, cmp4_ans_b;
wire [31:0] cmp1_a, cmp1_b, cmp2_a, cmp2_b;
wire cmp1_big, cmp2_big, cmp3_big, cmp4_big;

//normal
reg [2:0] normal_start;
wire [2:0] normal_start_tmp;
wire [31:0] cmp1_a_normal, cmp1_b_normal, cmp2_a_normal, cmp2_b_normal;
reg [31:0] x_dis_save, x_diff1_save, x_diff2_save;
wire [31:0] x_dis_save_tmp, x_diff1_save_tmp, x_diff2_save_tmp;
wire [31:0] div_result_2;

//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0; i<4; i = i+1)
            maxpool[i] <= 'd0;
    end
    else begin
        for(i=0; i<4; i = i+1)
            maxpool[i] <= maxpool_tmp[i];
    end
end



always@(*)begin
    for(i=0; i<4; i = i+1)
        maxpool_tmp[i] = maxpool[i];
    if(maxpool_start)begin
        case(x)
            'd1 : maxpool_tmp[2] = cmp3_ans_a;
            'd2 : maxpool_tmp[3] = cmp3_ans_a;
            'd3 : maxpool_tmp[0] = cmp3_ans_a;
            'd0 : maxpool_tmp[1] = cmp3_ans_a;
        endcase
    end
end
//cut coordinate into 4 region, every cycle choose max in each region
always@(*)
    case(x)
        'd2 : begin
            cmp1_a_maxpool = equa_reg[10];
            cmp1_b_maxpool = equa_reg[11];
            cmp2_a_maxpool = equa_reg[14];
            cmp2_b_maxpool = equa_reg[15];
        end
        'd3 : begin
            cmp1_a_maxpool = equa_reg[0];
            cmp1_b_maxpool = equa_reg[1];
            cmp2_a_maxpool = equa_reg[4];
            cmp2_b_maxpool = equa_reg[5];
        end
        'd0 : begin
            cmp1_a_maxpool = equa_reg[2];
            cmp1_b_maxpool = equa_reg[3];
            cmp2_a_maxpool = equa_reg[6];
            cmp2_b_maxpool = equa_reg[7];
        end
        'd1 :begin
            cmp1_a_maxpool = equa_reg[8];
            cmp1_b_maxpool = equa_reg[9];
            cmp2_a_maxpool = equa_reg[12];
            cmp2_b_maxpool = equa_reg[13];
        end
    endcase

assign cmp1_a = (normal_start) ? cmp1_a_normal : cmp1_a_maxpool;
assign cmp1_b = (normal_start) ? cmp1_b_normal : cmp1_b_maxpool;
assign cmp2_a = (normal_start) ? cmp2_a_normal : cmp2_a_maxpool;
assign cmp2_b = (normal_start) ? cmp2_b_normal : cmp2_b_maxpool;

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
cmp_U1 ( .a(cmp1_a), .b(cmp1_b), .zctr(zctr), .z0(cmp1_ans_a), .z1(cmp1_ans_b), .agtb(cmp1_big));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
cmp_U2 ( .a(cmp2_a), .b(cmp2_b), .zctr(zctr), .z0(cmp2_ans_a), .z1(cmp2_ans_b), .agtb(cmp2_big));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
cmp_U3 ( .a(cmp1_ans_a), .b(cmp2_ans_a), .zctr(zctr), .z0(cmp3_ans_a), .z1(cmp3_ans_b), .agtb(cmp3_big));

//for normalize
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
cmp_U4 ( .a(cmp1_ans_b), .b(cmp2_ans_b), .zctr(zctr), .z0(cmp4_ans_a), .z1(cmp4_ans_b), .agtb(cmp4_big));

//------------------ fully connected -------------//
reg fullcon_start;
reg [31:0] fullcon[3:0];
reg [31:0] fullcon_tmp[3:0];
reg [31:0] fullcon_tmp_newfull[3:0];
wire [31:0] fullcon_tmp_normal[3:0];
reg [31:0] mult2_a, mult2_b, mult3_b, mult3_a;
wire [31:0] add2_a, add3_a, add2_b, add3_b;
reg [31:0] add2_a_fullcon, add3_a_fullcon;

wire [31:0] mult2_ans, mult3_ans, add2_ans, add3_ans;

//do ready position

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fullcon_start <= 'd0;
        for(i=0; i<4; i = i+1)
            fullcon[i] <= 'd0;
    end
    else begin
        fullcon_start <= maxpool_start;
        for(i=0; i<4; i = i+1)
            fullcon[i] <= fullcon_tmp[i];
    end
end

always@(*)begin
    for(i=0; i<4; i = i+1)
        fullcon_tmp_newfull[i] = fullcon[i];
    if(fullcon_start)begin
        case(x)
            'd2 : begin
                fullcon_tmp_newfull[2] = add2_ans;
                fullcon_tmp_newfull[3] = add3_ans;
            end
            'd3 : begin
                fullcon_tmp_newfull[2] = add2_ans;
                fullcon_tmp_newfull[3] = add3_ans;
            end
            'd0 : begin
                fullcon_tmp_newfull[0] = add2_ans;
                fullcon_tmp_newfull[1] = add3_ans;
            end
            'd1 : begin
                fullcon_tmp_newfull[0] = add2_ans;
                fullcon_tmp_newfull[1] = add3_ans;
            end
        endcase
    end else if(maxpool_start && !fullcon_start)
        for(i=0; i<4; i = i+1)
        fullcon_tmp_newfull[i] = 'd0;
end

reg [5:0] act_start;

always@(*)begin
    if((normal_start[1] || normal_start[2]))
        fullcon_tmp = fullcon_tmp_normal;
    else if((|act_start))
        fullcon_tmp = {fullcon[2], fullcon[1], fullcon[0],add2_ans};
    else
        fullcon_tmp = fullcon_tmp_newfull;
end
//assign fullcon_tmp = (normal_start[1] | normal_start[2]) ? fullcon_tmp_normal : (|act_start) ? {fullcon[2], fullcon[1], fullcon[0],add2_ans} : fullcon_tmp_newfull;

always@(*)
    case(x)
        'd2 : begin
            mult2_a = maxpool[2];
            mult3_a = maxpool[2];
            mult2_b = weight_save[0];
            mult3_b = weight_save[1];
            add2_a_fullcon = fullcon[2];
            add3_a_fullcon = fullcon[3];
        end
        'd3 : begin
            mult2_a = maxpool[3];
            mult3_a = maxpool[3];
            mult2_b = weight_save[2];
            mult3_b = weight_save[3];
            add2_a_fullcon = fullcon[2];
            add3_a_fullcon = fullcon[3];
        end
        'd0 : begin
            mult2_a = maxpool[0];
            mult3_a = maxpool[0];
            mult2_b = weight_save[0];
            mult3_b = weight_save[1];
            add2_a_fullcon = fullcon[0];
            add3_a_fullcon = fullcon[1];
        end
        'd1 :begin
            mult2_a = maxpool[1];
            mult3_a = maxpool[1];
            mult2_b = weight_save[2];
            mult3_b = weight_save[3];
            add2_a_fullcon = fullcon[0];
            add3_a_fullcon = fullcon[1];
        end
    endcase


DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mult_U2 ( .a(mult2_a), .b(mult2_b), .rnd(inst_rnd), .z(mult2_ans));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mult_U3 ( .a(mult3_a), .b(mult3_b), .rnd(inst_rnd), .z(mult3_ans));


//act
wire [31:0] add2_a_act, add2_b_act, add3_a_act, add3_b_act;
wire [31:0] add2_a_dis, add2_b_dis, add3_a_dis, add3_b_dis;
assign add2_a = (dis_start) ? add2_a_dis : (act_start) ? add2_a_act : add2_a_fullcon;
assign add2_b = (dis_start) ? add2_b_dis : (act_start) ? add2_b_act : mult2_ans;
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_U2 ( .a(add2_a), .b(add2_b), .rnd(inst_rnd), .z(add2_ans));

assign add3_a = (dis_start) ? add3_a_dis : add3_a_fullcon;
assign add3_b = (dis_start) ? add3_b_dis : mult3_ans;
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_U3 ( .a(add3_a), .b(add3_b), .rnd(inst_rnd), .z(add3_ans));


//------------------ normalize -------------//
//share max pooling comparator
wire [31:0] x_dis;
wire [31:0] x_diff1, x_diff2;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        normal_start <= 'd0;
        x_dis_save <= 'd0;
        x_diff1_save <= 'd0;
        x_diff2_save <= 'd0;
    end
    else begin
        normal_start <= normal_start_tmp;
        x_dis_save <= x_dis_save_tmp;
        x_diff1_save <= x_diff1_save_tmp;
        x_diff2_save <= x_diff2_save_tmp;

    end
end

assign normal_start_tmp = (!maxpool_start && fullcon_start) ? 'd1 : normal_start << 1;
assign x_dis_save_tmp = (normal_start[0] || dis_start) ? x_dis : x_dis_save;
assign x_diff1_save_tmp = (normal_start[0] || act_start[2] || act_start[4] || dis_start) ? x_diff1 : x_diff1_save;
assign x_diff2_save_tmp = (normal_start[0] || dis_start) ? x_diff2 : x_diff2_save;

assign cmp1_a_normal = fullcon[0];
assign cmp1_b_normal = fullcon[1];
assign cmp2_a_normal = fullcon[2];
assign cmp2_b_normal = fullcon[3];

reg cmp1_big_save, cmp2_big_save, cmp3_big_save, cmp4_big_save;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cmp1_big_save <= 'd0;
        cmp2_big_save <= 'd0;
        cmp3_big_save <= 'd0;
        cmp4_big_save <= 'd0;
    end
    else begin
        cmp1_big_save <= (normal_start[0]) ? cmp1_big : cmp1_big_save;
        cmp2_big_save <= (normal_start[0]) ? cmp2_big : cmp2_big_save;
        cmp3_big_save <= (normal_start[0]) ? cmp3_big : cmp3_big_save;
        cmp4_big_save <= (normal_start[0]) ? cmp4_big : cmp4_big_save;
    end
end


//xmax-xmin
wire [31:0] sub1_a, sub1_b;
wire [31:0] sub1_a_dis, sub1_b_dis, sub2_a_dis, sub2_b_dis, sub3_a_dis, sub3_b_dis;
assign sub1_a = (dis_start) ? sub1_a_dis : cmp3_ans_a;
assign sub1_b = (dis_start) ? sub1_b_dis : cmp4_ans_b;
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
sub_U1 ( .a(sub1_a), .b(sub1_b), .rnd(inst_rnd), .z(x_dis));

//x-xmin
wire [31:0] sub2_a, sub2_b, sub3_a, sub3_b;
//act
wire [31:0] sub2_a_act, sub2_b_act, sub3_a_act, sub3_b_act;
assign sub2_a = (dis_start) ? sub2_a_dis : (act_start) ? sub2_a_act : cmp3_ans_b;
assign sub2_b = (dis_start) ? sub2_b_dis : (act_start) ? sub2_b_act : cmp4_ans_b;
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
sub_U2 ( .a(sub2_a), .b(sub2_b), .rnd(inst_rnd), .z(x_diff1));

assign sub3_a = (dis_start) ? sub3_a_dis : (act_start) ? sub3_a_act : cmp4_ans_a;
assign sub3_b = (dis_start) ? sub3_b_dis : (act_start) ? sub3_b_act : cmp4_ans_b;
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
sub_U3 ( .a(sub3_a), .b(sub3_b), .rnd(inst_rnd), .z(x_diff2));


//(x-xmin)/(xmax-xmin)
wire [31:0] div1_a, div1_b, div2_a, div2_b;
wire [31:0] div1_a_normal, div1_b_normal;
//act
wire [31:0] div1_a_act, div1_b_act, div2_a_act, div2_b_act;
assign div1_a = (equa_start_d2) ? equal_sum3_2_reg : (act_start[3] || act_start[5]) ? div1_a_act : div1_a_normal;
assign div1_b = (equa_start_d2) ? 32'h41100000 : (act_start[3] || act_start[5]) ? div1_b_act : div1_b_normal;
assign div1_a_normal = (normal_start[1]) ? x_diff1_save : x_diff2_save;
assign div1_b_normal = x_dis_save;
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) 
div_U1 ( .a(div1_a), .b(div1_b), .rnd(inst_rnd), .z(div_result_1));

/*
assign div2_a = (act_start) ? div2_a_act : x_diff2_save;
assign div2_b = (act_start) ? div2_b_act : x_dis_save;
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) 
div_U2 ( .a(div2_a), .b(div2_b), .rnd(inst_rnd), .z(div_result_2));
*/
//save max, mid1, mid2, min order
reg [1:0] max, second, third, min;
wire [1:0] max_tmp, second_tmp, third_tmp, min_tmp;

//by comparator result, decide which is max, mid1, mid2, min
assign fullcon_tmp_normal[0] = (normal_start[1]) ? div_result_1 : fullcon[0];
assign fullcon_tmp_normal[1] = (normal_start[2]) ? div_result_1 : fullcon[1];
assign fullcon_tmp_normal[2] = fullcon[2];
assign fullcon_tmp_normal[3] = fullcon[3];


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        max <= 'd0;
        second <= 'd0;
        third <= 'd0;
        min <= 'd0;
    end
    else begin
        max <= max_tmp;
        second <= second_tmp;
        third <= third_tmp;
        min <= min_tmp;
    end
end

assign max_tmp = (normal_start[0]) ? (cmp3_big) ? (cmp1_big) ? 'd0 : 'd1 : (cmp2_big) ? 'd2 : 'd3 : max;
assign second_tmp = (normal_start[0]) ? (!cmp3_big) ? (cmp1_big) ? 'd0 : 'd1 : (cmp2_big) ? 'd2 : 'd3 : second;
assign third_tmp = (normal_start[0]) ? (cmp4_big) ? (!cmp1_big) ? 'd0 : 'd1 : (!cmp2_big) ? 'd2 : 'd3 : third;
assign min_tmp = (normal_start[0]) ? (!cmp4_big) ? (!cmp1_big) ? 'd0 : 'd1 : (!cmp2_big) ? 'd2 : 'd3 : min;


//------------------ activation -------------//
wire [5:0] act_start_tmp;
wire [31:0] exp_second, exp_second_inv, exp_third, exp_third_inv;
reg [31:0] exp_second_save, exp_second_inv_save, exp_third_save, exp_third_inv_save;
wire [31:0] exp_second_save_tmp, exp_second_inv_save_tmp, exp_third_save_tmp, exp_third_inv_save_tmp;
reg [31:0] act1[3:0], act2[3:0];
reg [31:0] act1_tmp[3:0], act2_tmp[3:0];

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        act_start <= 'd0;
        exp_second_save <= 'd0;
        exp_second_inv_save <= 'd0;
        exp_third_save <= 'd0;
        exp_third_inv_save <= 'd0;
        for( i=0; i<4; i= i+1)begin
            act1[i] <= 'd0;
            act2[i] <= 'd0;
        end
    end
    else begin
        act_start <= act_start_tmp;
        exp_second_save <= exp_second_save_tmp;
        exp_second_inv_save <= exp_second_inv_save_tmp;
        exp_third_save <= exp_third_save_tmp;
        exp_third_inv_save <= exp_third_inv_save_tmp;
        for( i=0; i<4; i= i+1)begin
            act1[i] <= act1_tmp[i];
            act2[i] <= act2_tmp[i];
        end
    end
end

//exponential
wire [31:0] exp_a, exp_a_inv, exp_ans, exp_ans_inv;

assign act_start_tmp = (normal_start[1]) ? 'd1 : act_start << 1;
assign exp_second_save_tmp = (act_start[0]) ? exp_ans : exp_second_save;
assign exp_second_inv_save_tmp = (act_start[1]) ? exp_ans : exp_second_inv_save;
assign exp_third_save_tmp = (act_start[2]) ? exp_ans : exp_third_save;
assign exp_third_inv_save_tmp = (act_start[3]) ? exp_ans : exp_third_inv_save;


assign exp_a = (act_start[0]) ? fullcon[0] : (act_start[1]) ? {!fullcon[0][31],fullcon[0][30:0]} :
               (act_start[2]) ? fullcon[2]  : {!fullcon[3][31],fullcon[3][30:0]} ;
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
exp_U1 (.a(exp_a),.z(exp_ans));

/*
assign exp_a_inv = (act_start[0]) ? {!fullcon[second][31],fullcon[second][30:0]} : {!fullcon[third][31],fullcon[third][30:0]};
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
DW_fp_exp_U2 (.a(exp_a_inv),.z(exp_ans_inv));
*/
/*
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
DW_fp_exp_U3 (.a(fullcon[third]),.z(exp_third));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
DW_fp_exp_U4 (.a({!fullcon[third][31],fullcon[third][30:0]}),.z(exp_third_inv));
*/

//Opt = 1, numerator sub
assign sub2_a_act = (act_start[2]) ? exp_second_save : exp_third_save;
assign sub2_b_act = (act_start[2]) ? exp_second_inv_save : exp_third_inv_save;
//assign sub3_a_act = exp_third_save;
//assign sub3_b_act = exp_third_inv_save;
//denominator add
assign add2_a_act = (opt_save[1]) ? (act_start[2]) ? exp_second_save : exp_third_save : 'h3f800000;
assign add2_b_act = (act_start[2]) ? exp_second_inv_save : exp_third_inv_save;
//assign add3_a_act = (opt_save[1]) ? exp_third_save : 'h3f800000; 
//assign add3_b_act = exp_third_inv_save;

//div
assign div1_a_act = (opt_save[1]) ? x_diff1_save : 'h3f800000;
assign div1_b_act = fullcon[0];
//assign div2_a_act = (opt_save[1]) ? x_diff2_save : 'h3f800000;
//assign div2_b_act = fullcon[0];

//if max(1) or min(0) can be const.
always@(*)begin
    for(i=0; i<4; i = i + 1)begin
        act1_tmp[i] = act1[i];
        act2_tmp[i] = act2[i];
    end
    if(act_start[3])begin
        if(lower_cnt && !img_cnt[1])begin
            act1_tmp[max] = (opt_save[1]) ? 'h3F42F7D5 : 'h3f3b26a8;
            act1_tmp[second] = div_result_1;
            act1_tmp[min] =  (opt_save[1]) ? 'h00000000 : 'h3f000000;
        end else begin
            act2_tmp[max] = (opt_save[1]) ? 'h3F42F7D5 : 'h3f3b26a8;
            act2_tmp[second] = div_result_1;
            act2_tmp[min] =  (opt_save[1]) ? 'h00000000 : 'h3f000000;
        end
    end else if(act_start[5])begin
        if(lower_cnt && !img_cnt[1])begin
            act1_tmp[third] = div_result_1;
        end else begin
            act2_tmp[third] = div_result_1;
        end
    end
end

//------------------ distance -------------//
wire [31:0] sub4_a, sub4_b, x_diff3;
reg [31:0] x_diff3_save;
assign dis_start = (delay_cnt == 'd29 || delay_cnt == 'd30);
//calaulate diff between upper and lower
assign sub1_a_dis = act1[0];
assign sub1_b_dis = act2[0];
assign sub2_a_dis = act1[1];
assign sub2_b_dis = act2[1];
assign sub3_a_dis = act1[2];
assign sub3_b_dis = act2[2];
assign sub4_a = act1[3];
assign sub4_b = act2[3];

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        x_diff3_save <= 'd0;
    else
        x_diff3_save <= (dis_start) ? x_diff3 : x_diff3_save;
end

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
sub_U4 ( .a(sub4_a), .b(sub4_b), .rnd(inst_rnd), .z(x_diff3));

//abs(sub result) and add two by two
assign add1_a_dis = (x_dis_save[31]) ? {!x_dis_save[31], x_dis_save[30:0]} : x_dis_save;
assign add1_b_dis = (x_diff1_save[31]) ? {!x_diff1_save[31], x_diff1_save[30:0]} : x_diff1_save;

assign add2_a_dis = (x_diff2_save[31]) ? {!x_diff2_save[31], x_diff2_save[30:0]} : x_diff2_save;
assign add2_b_dis = (x_diff3_save[31]) ? {!x_diff3_save[31], x_diff3_save[30:0]} : x_diff3_save;


//add two by two last
assign add3_a_dis = sum2_ans;
assign add3_b_dis = add2_ans;


//------------------ output -------------//
wire [31:0] out_tmp;
wire out_valid_tmp;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 'b0;
        out <= 'd0;
    end
    else begin
        out_valid <= out_valid_tmp;
        out <= out_tmp;
    end
end

assign out_valid_tmp = (delay_cnt == 'd30);
assign out_tmp = (delay_cnt == 'd30) ? add3_ans : 'd0;



endmodule
