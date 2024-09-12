//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
//---------------------------- huffman ----------------------------//
integer i;
reg [2:0] mask      [4:0];
reg [4:0] weight    [13:0];
reg [6:0] code      [4:0];
reg [4:0] treeNode  [5:0];
reg       out_mode_save;
reg [2:0] cnt_round;
reg [2:0] cnt_input;
reg [31:0] IN_char_update;


reg  [2:0] mask_tmp      [4:0];
reg  [2:0] mask_tmp2      [4:0];
reg  [4:0] weight_tmp    [13:0];
reg  [6:0] code_tmp      [4:0];
reg  [6:0] code_tmp2      [4:0];
reg  [4:0] treeNode_tmp  [5:0];
wire       out_mode_save_tmp;
wire [2:0] cnt_input_tmp;
wire [2:0] cnt_round_tmp;
reg  [31:0] IN_char_update_tmp;
reg  [39:0] IN_weight_update;
wire [3:0] new_char;
wire [3:0] new_char2;
wire [2:0] char_pos [13:6];
wire [31:0] OUT_character;
reg[1:0] cmp_case;
wire [4:0] treeNode_or1, treeNode_or2;
reg [4:0] treeNode_or3, treeNode_or4;

//---------------------------- output ----------------------------//
reg [2:0] out_bitcnt;
reg [2:0] out_cnt;
wire [2:0] out_bitcnt_tmp;
wire [2:0] out_cnt_tmp;
wire out_valid_tmp;
wire out_code_tmp;


// ===============================================================
// Design
// ===============================================================

//---------------------------- huffman ----------------------------//
assign char_pos[13] = (out_mode_save) ? 'd3 : 'd7;
assign char_pos[12] = (out_mode_save) ? 'd4 : 'd7;
assign char_pos[11] = (out_mode_save) ? 'd1 : 'd7;
assign char_pos[10] = (out_mode_save) ? 'd7 : 'd4;
assign char_pos[ 9] = 'd0;
assign char_pos[ 8] = (out_mode_save) ? 'd2 : 'd1;
assign char_pos[ 7] = (out_mode_save) ? 'd7 : 'd2;
assign char_pos[ 6] = (out_mode_save) ? 'd7 : 'd3;


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i = 0; i < 5; i = i+1)
            mask[i] <= 'd0;
        for(i = 0; i < 14; i = i+1)
            weight[i] <= 'd0;
        for(i = 0; i < 5; i = i+1)
            code[i] <= 'd0;
        for(i = 0; i < 6; i = i+1)
            treeNode[i] <= 'd0;
        out_mode_save <= 'd0;
        cnt_round <= 'd0;
        cnt_input <= 'd0;
        IN_char_update <= 'd0;
    end
    else begin
        for(i = 0; i < 5; i = i+1)
            mask[i] <= mask_tmp[i];
        for(i = 0; i < 14; i = i+1)
            weight[i] <= weight_tmp[i];
        for(i = 0; i < 5; i = i+1)
            code[i] <= code_tmp[i];
        for(i = 0; i < 6; i = i+1)
            treeNode[i] <= treeNode_tmp[i];
        out_mode_save <= out_mode_save_tmp;
        cnt_round <= cnt_round_tmp;
        cnt_input <= cnt_input_tmp;
        IN_char_update <= IN_char_update_tmp;
    end
end
assign out_mode_save_tmp = (out_valid) ? 'd0 : (~|cnt_input && in_valid) ? out_mode : out_mode_save;
assign cnt_round_tmp = (cnt_input == 'd7) ? cnt_round + 'd1 : 'd0;
assign cnt_input_tmp = (cnt_round == 'd4) ? 'd0 : (in_valid && ~&cnt_input) ? cnt_input + 'd1 : cnt_input;
assign new_char = ('d7-cnt_round*2);
assign new_char2 = ('d6-cnt_round*2);

always@(*)begin
    if(cnt_round > 'd0 && cnt_round < 'd4)begin
        if(weight[OUT_character[7:4]] + weight[OUT_character[3:0]] <= weight[OUT_character[11:8]])
            cmp_case = 'd0;
        else if(weight[OUT_character[7:4]] + weight[OUT_character[3:0]] <= weight[OUT_character[15:12]])
            cmp_case = 'd1;
        else
            cmp_case = 'd2;
    end
    else
        cmp_case = 'd0;
end



always@(*)begin
    if(cnt_round < 'd1)
        IN_char_update_tmp = {4'd13, 4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6};
    else begin
        case(cmp_case[1])
            'd0 : IN_char_update_tmp = {OUT_character[31:12], new_char2, 4'd15, 4'd15};
            'd1 : IN_char_update_tmp = {OUT_character[31:16], new_char, new_char2, 4'd15, 4'd15};
        endcase
    end        
end

always@(*)begin
    if(cnt_round < 'd1 && in_valid)begin
        for(i = 7; i < 14; i = i+1)begin
            weight_tmp[i] = weight[i-1];
        end
        weight_tmp[6] = in_weight;
        for(i = 0; i < 6; i = i+1)begin
            weight_tmp[i] = 'd0;
        end
    end
    else if(cnt_round < 'd4 && cnt_round > 'd0) begin
        for(i = 0; i < 14; i = i+1)begin
            weight_tmp[i] = weight[i];
        end
        weight_tmp[new_char] = weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
        case(cmp_case[1])
            'd0 : weight_tmp[new_char2] = weight[OUT_character[7:4]] + weight[OUT_character[3:0]] + weight[OUT_character[11:8]];
            'd1 : weight_tmp[new_char2] = weight[OUT_character[15:12]] + weight[OUT_character[11:8]];
        endcase
    end
    else 
        for(i = 0; i < 14; i = i+1)begin
            weight_tmp[i] = weight[i];
        end
end

always@(*)begin
    for(i = 0; i < 8; i = i+1)begin
        if(IN_char_update[31 - i*4 -: 4] == 'd15)
            IN_weight_update[39 - i*5 -: 5] = 'd31;
        else
            IN_weight_update[39 - i*5 -: 5] = weight[IN_char_update[31 - i*4 -: 4]];
    end
end


SORT_IP sort_U1 (
    // Input signals
    .IN_character(IN_char_update), .IN_weight(IN_weight_update),
    // Output signals
    .OUT_character(OUT_character)
);

assign treeNode_or1 = (OUT_character[7:4] > 'd5) ? (&char_pos[OUT_character[7:4]]) ? 'd0 : 1 << char_pos[OUT_character[7:4]] : treeNode[OUT_character[7:4]];
assign treeNode_or2 = (OUT_character[3:0] > 'd5) ? (&char_pos[OUT_character[3:0]]) ? 'd0 : 1 << char_pos[OUT_character[3:0]] : treeNode[OUT_character[3:0]];
always@(*)begin
    case(cmp_case)
        'd0 : begin
            treeNode_or3 = (OUT_character[11:8] > 'd5) ? (&char_pos[OUT_character[11:8]]) ? 'd0 : 1 << char_pos[OUT_character[11:8]] : treeNode[OUT_character[11:8]];
            treeNode_or4 = treeNode_or1 | treeNode_or2;
        end
        'd1 : begin
            treeNode_or3 = treeNode_or1 | treeNode_or2;
            treeNode_or4 = (OUT_character[11:8] > 'd5) ? (&char_pos[OUT_character[11:8]]) ? 'd0 : 1 << char_pos[OUT_character[11:8]] : treeNode[OUT_character[11:8]];
        end
        default : begin
            treeNode_or3 = (OUT_character[15:12] > 'd5) ? (&char_pos[OUT_character[15:12]]) ? 'd0 : 1 << char_pos[OUT_character[15:12]] : treeNode[OUT_character[15:12]];
            treeNode_or4 = (OUT_character[11:8] > 'd5) ? (&char_pos[OUT_character[11:8]]) ? 'd0 : 1 << char_pos[OUT_character[11:8]] : treeNode[OUT_character[11:8]];
        end
    endcase
end

always@(*)begin
    for(i = 0; i < 6; i = i+1)
        treeNode_tmp[i] = treeNode[i];
    if(cnt_round > 'd0 && cnt_round < 'd4)begin
        treeNode_tmp[new_char] = treeNode_or1 | treeNode_or2;
        treeNode_tmp[new_char2] = treeNode_or3 | treeNode_or4;
    end
end

always@(*)begin
    if(cnt_round == 'd4)begin
        for(i=0; i < 5; i = i+1)
            if(treeNode_or1[i])begin
                code_tmp[i] = {code[i][6:0], 1'b0};
                mask_tmp[i] = mask[i] + 'd1;
            end
            else if(treeNode_or2[i])begin
                code_tmp[i] = {code[i][6:0], 1'b1};
                mask_tmp[i] = mask[i] + 'd1;
            end
            else begin
                code_tmp[i] = code[i];
                mask_tmp[i] = mask[i];
            end
    end
    
    else if(cnt_round > 'd0 && cnt_round < 'd4)begin
        for(i=0; i < 5; i = i+1)
            if(treeNode_or1[i])begin
                code_tmp2[i] = {code[i][6:0], 1'b0};
                mask_tmp2[i] = mask[i] + 'd1;
            end
            else if(treeNode_or2[i])begin
                code_tmp2[i] = {code[i][6:0], 1'b1};
                mask_tmp2[i] = mask[i] + 'd1;
            end
            else begin
                code_tmp2[i] = code[i];
                mask_tmp2[i] = mask[i];
            end
        for(i=0; i < 5; i = i+1)
            if(treeNode_or3[i])begin
                code_tmp[i] = {code_tmp2[i][6:0], 1'b0};
                mask_tmp[i] = mask_tmp2[i] + 'd1;
            end
            else if(treeNode_or4[i])begin
                code_tmp[i] = {code_tmp2[i][6:0], 1'b1};
                mask_tmp[i] = mask_tmp2[i] + 'd1;
            end
            else begin
                code_tmp[i] = code_tmp2[i];
                mask_tmp[i] = mask_tmp2[i];
            end
    end
    else if(in_valid)
        for(i=0; i < 5; i = i+1)begin
            code_tmp[i] = 'd0;
            mask_tmp[i] = 'd0;
        end
    else 
        for(i=0; i < 5; i = i+1)begin
            code_tmp[i] = code[i];
            mask_tmp[i] = mask[i];
        end
end


//---------------------------- output ----------------------------//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 'd0;
        out_code <= 'd0;
        out_bitcnt <= 'd0;
        out_cnt <= 'd0;
    end
    else begin
        out_valid <= out_valid_tmp;
        out_code <= out_code_tmp;
        out_bitcnt <= out_bitcnt_tmp;
        out_cnt <= out_cnt_tmp;
    end
end

assign out_valid_tmp = (out_cnt == 'd4 && out_bitcnt == mask[4] - 'd1) ? 'd0 : (cnt_round == 'd4) ? 'd1 : out_valid;
assign out_code_tmp = (out_cnt == 'd4 && out_bitcnt == mask[4] - 'd1) ? 'd0 : (cnt_round == 'd4) ? treeNode_or2[0] : (out_valid) ? code[out_cnt_tmp][out_bitcnt_tmp] : 'd0;
assign out_cnt_tmp = (out_cnt == 'd4 && out_bitcnt == mask[4] - 'd1) ? 'd0 : (out_bitcnt == mask[out_cnt] - 'd1 && out_valid) ? out_cnt + 'd1 : out_cnt;
assign out_bitcnt_tmp = (out_cnt == 'd4 && out_bitcnt == mask[4] - 'd1) ? 'd0 : (out_bitcnt == mask[out_cnt] - 'd1) ? 'd0 : (out_valid) ? out_bitcnt + 'd1 : 'd0;


endmodule