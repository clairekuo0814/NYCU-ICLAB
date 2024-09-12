//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================

wire [3:0] char[7:0];
wire [4:0] weight[7:0];

genvar gen_i;
generate 
    for(gen_i=0; gen_i < IP_WIDTH; gen_i = gen_i+1)begin
        assign char[gen_i] = IN_character[IP_WIDTH * 4 - gen_i * 4 -1 -: 4];
        assign weight[gen_i] = IN_weight[IP_WIDTH * 5 - gen_i * 5 -1 -: 5];
    end
    if(IP_WIDTH < 'd8)begin
        for(gen_i=IP_WIDTH; gen_i < 8; gen_i = gen_i+1)begin
            assign char[gen_i] = 'd0;
            assign weight[gen_i] = 'd0;
        end
    end
endgenerate

//cmp_L1
reg [3:0] char_L1[7:0];
reg [4:0] weight_L1[7:0];
generate
    for(gen_i=0; gen_i < 4; gen_i = gen_i+1)begin
        always@(*)
            if(weight[gen_i * 2] > weight[gen_i * 2 + 1] || ((weight[gen_i * 2] == weight[gen_i * 2 + 1] && char[gen_i * 2] > char[gen_i * 2 + 1])))begin
                char_L1[gen_i * 2] = char[gen_i * 2];
                char_L1[gen_i * 2 + 1] = char[gen_i * 2 + 1];
                weight_L1[gen_i * 2] = weight[gen_i * 2];
                weight_L1[gen_i * 2 + 1] = weight[gen_i * 2 + 1];
            end
            else begin
                char_L1[gen_i * 2] = char[gen_i * 2 + 1];
                char_L1[gen_i * 2 + 1] = char[gen_i * 2];
                weight_L1[gen_i * 2] = weight[gen_i * 2 + 1];
                weight_L1[gen_i * 2 + 1] = weight[gen_i * 2];
            end
    end
endgenerate

//cmp_L2
reg [3:0] char_L2[7:0];
reg [4:0] weight_L2[7:0];
generate
    for(gen_i=0; gen_i < 2; gen_i = gen_i+1)begin
        always@(*)
            if(weight_L1[gen_i * 4] > weight_L1[gen_i * 4 + 3] || ((weight_L1[gen_i * 4] == weight_L1[gen_i * 4 + 3] && char_L1[gen_i * 4] > char_L1[gen_i * 4 + 3])))begin
                char_L2[gen_i * 4] = char_L1[gen_i * 4];
                char_L2[gen_i * 4 + 3] = char_L1[gen_i * 4 + 3];
                weight_L2[gen_i * 4] = weight_L1[gen_i * 4];
                weight_L2[gen_i * 4 + 3] = weight_L1[gen_i * 4 + 3];
            end
            else begin
                char_L2[gen_i * 4] = char_L1[gen_i * 4 + 3];
                char_L2[gen_i * 4 + 3] = char_L1[gen_i * 4];
                weight_L2[gen_i * 4] = weight_L1[gen_i * 4 + 3];
                weight_L2[gen_i * 4 + 3] = weight_L1[gen_i * 4];
            end
    end
endgenerate
generate
    for(gen_i=0; gen_i < 2; gen_i = gen_i+1)begin
        always@(*)
            if(weight_L1[gen_i * 4 + 1] > weight_L1[gen_i * 4 + 2] || ((weight_L1[gen_i * 4 + 1] == weight_L1[gen_i * 4 + 2] && char_L1[gen_i * 4 + 1] > char_L1[gen_i * 4 + 2])))begin
                char_L2[gen_i * 4 + 1] = char_L1[gen_i * 4 + 1];
                char_L2[gen_i * 4 + 2] = char_L1[gen_i * 4 + 2];
                weight_L2[gen_i * 4 + 1] = weight_L1[gen_i * 4 + 1];
                weight_L2[gen_i * 4 + 2] = weight_L1[gen_i * 4 + 2];
            end
            else begin
                char_L2[gen_i * 4 + 1] = char_L1[gen_i * 4 + 2];
                char_L2[gen_i * 4 + 2] = char_L1[gen_i * 4 + 1];
                weight_L2[gen_i * 4 + 1] = weight_L1[gen_i * 4 + 2];
                weight_L2[gen_i * 4 + 2] = weight_L1[gen_i * 4 + 1];
            end
    end
endgenerate

//cmp_L3
reg [3:0] char_L3[7:0];
reg [4:0] weight_L3[7:0];
generate
    for(gen_i=0; gen_i < 4; gen_i = gen_i+1)begin
        always@(*)
            if(weight_L2[gen_i * 2] > weight_L2[gen_i * 2 + 1] || ((weight_L2[gen_i * 2] == weight_L2[gen_i * 2 + 1] && char_L2[gen_i * 2] > char_L2[gen_i * 2 + 1])))begin
                char_L3[gen_i * 2] = char_L2[gen_i * 2];
                char_L3[gen_i * 2 + 1] = char_L2[gen_i * 2 + 1];
                weight_L3[gen_i * 2] = weight_L2[gen_i * 2];
                weight_L3[gen_i * 2 + 1] = weight_L2[gen_i * 2 + 1];
            end
            else begin
                char_L3[gen_i * 2] = char_L2[gen_i * 2 + 1];
                char_L3[gen_i * 2 + 1] = char_L2[gen_i * 2];
                weight_L3[gen_i * 2] = weight_L2[gen_i * 2 + 1];
                weight_L3[gen_i * 2 + 1] = weight_L2[gen_i * 2];
            end
    end
endgenerate

//cmp_L4
reg [3:0] char_L4[7:0];
reg [4:0] weight_L4[7:0];
generate
    for(gen_i=0; gen_i < 4; gen_i = gen_i+1)begin
        always@(*)
            if(weight_L3[gen_i] > weight_L3[8 - gen_i - 1] || ((weight_L3[gen_i] == weight_L3[8 - gen_i - 1] && char_L3[gen_i] > char_L3[8 - gen_i - 1])))begin
                char_L4[gen_i] = char_L3[gen_i];
                char_L4[8 - gen_i - 1] = char_L3[8 - gen_i - 1];
                weight_L4[gen_i] = weight_L3[gen_i];
                weight_L4[8 - gen_i - 1] = weight_L3[8 - gen_i - 1];
            end
            else begin
                char_L4[gen_i] = char_L3[8 - gen_i - 1];
                char_L4[8 - gen_i - 1] = char_L3[gen_i];
                weight_L4[gen_i] = weight_L3[8 - gen_i - 1];
                weight_L4[8 - gen_i - 1] = weight_L3[gen_i];
            end
    end
endgenerate

//cmp_L5
reg [3:0] char_L5[7:0];
reg [4:0] weight_L5[7:0];

generate
    for(gen_i=0; gen_i < 2; gen_i = gen_i+1)begin
        always@(*)
            if(weight_L4[gen_i] > weight_L4[gen_i + 2] || ((weight_L4[gen_i] == weight_L4[gen_i + 2] && char_L4[gen_i] > char_L4[gen_i + 2])))begin
                char_L5[gen_i] = char_L4[gen_i];
                char_L5[gen_i + 2] = char_L4[gen_i + 2];
                weight_L5[gen_i] = weight_L4[gen_i];
                weight_L5[gen_i + 2] = weight_L4[gen_i + 2];
            end
            else begin
                char_L5[gen_i] = char_L4[gen_i + 2];
                char_L5[gen_i + 2] = char_L4[gen_i];
                weight_L5[gen_i] = weight_L4[gen_i + 2];
                weight_L5[gen_i + 2] = weight_L4[gen_i];
            end
    end
    for(gen_i=4; gen_i < 6; gen_i = gen_i+1)begin
        always@(*)
            if(weight_L4[gen_i] > weight_L4[gen_i + 2] || ((weight_L4[gen_i] == weight_L4[gen_i + 2] && char_L4[gen_i] > char_L4[gen_i + 2])))begin
                char_L5[gen_i] = char_L4[gen_i];
                char_L5[gen_i + 2] = char_L4[gen_i + 2];
                weight_L5[gen_i] = weight_L4[gen_i];
                weight_L5[gen_i + 2] = weight_L4[gen_i + 2];
            end
            else begin
                char_L5[gen_i] = char_L4[gen_i + 2];
                char_L5[gen_i + 2] = char_L4[gen_i];
                weight_L5[gen_i] = weight_L4[gen_i + 2];
                weight_L5[gen_i + 2] = weight_L4[gen_i];
            end
    end
endgenerate

//cmp_L6
reg [3:0] char_L6[7:0];
reg [4:0] weight_L6[7:0];

generate
    for(gen_i=0; gen_i < 8; gen_i = gen_i+2)begin
        always@(*)
            if(weight_L5[gen_i] > weight_L5[gen_i + 1] || ((weight_L5[gen_i] == weight_L5[gen_i + 1] && char_L5[gen_i] > char_L5[gen_i + 1])))begin
                char_L6[gen_i] = char_L5[gen_i];
                char_L6[gen_i + 1] = char_L5[gen_i + 1];
                weight_L6[gen_i] = weight_L5[gen_i];
                weight_L6[gen_i + 1] = weight_L5[gen_i + 1];
            end
            else begin
                char_L6[gen_i] = char_L5[gen_i + 1];
                char_L6[gen_i + 1] = char_L5[gen_i];
                weight_L6[gen_i] = weight_L5[gen_i + 1];
                weight_L6[gen_i + 1] = weight_L5[gen_i];
            end
    end
endgenerate




generate
    for(gen_i=0; gen_i < IP_WIDTH; gen_i = gen_i+1)begin
        assign OUT_character[IP_WIDTH * 4 - gen_i * 4 - 1 -: 4] = char_L6[gen_i];
    end
endgenerate


endmodule