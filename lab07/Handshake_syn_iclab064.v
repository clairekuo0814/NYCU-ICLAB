module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;


//source
//reg handshake;
reg [WIDTH-1:0]data;
reg [WIDTH-1:0] r_data;

reg sreq_d1, sreq_d2;
wire sreq_tmp;
always@(posedge sclk or negedge rst_n)begin
    if(!rst_n)begin
        sreq <= 'd0;
        sreq_d1 <= 'd0;
        sreq_d2 <= 'd0;
    end
    else begin
        sreq <= sreq_tmp;
        sreq_d1<= sreq;
        sreq_d2<= sreq_d1;
    end
end
assign sreq_tmp = sready;

always@(posedge sclk or negedge rst_n)begin
    if(!rst_n)begin
        data <= 'd0;
    end
    else  if(sreq) begin
        data <= din;
    end
end
/*
always@(posedge sclk or negedge rst_n)begin
    if(!rst_n)begin
        handshake <= 'd0;
    end
    else begin
        handshake <= sready == sidle;
    end
end*/
/*
always@(*)begin
    handshake =  sidle;
end*/
//assign handshake = sready & sidle;
assign sidle = sreq & sack;

reg dreq_d1, dreq_d2, dreq_d3;
always@(posedge dclk or negedge rst_n)begin
    if(!rst_n)begin
        dreq_d1 <= 'd0;
        dreq_d2 <= 'd0;
        dreq_d3 <= 'd0;

    end
    else begin
        dreq_d1 <= dreq;
        dreq_d2 <= dreq_d1;
        dreq_d3 <= dreq_d2;
    end
end



//destination
wire stall;
wire wait_req;
reg dack_d1, dack_d2, dack_d3;
reg dbusy_d1, dbusy_d2;
//reg dbusy_d1, dbusy_d2,dbusy_d3, dbusy_d4, dbusy_d5, dbusy_d6;
always@(posedge dclk or negedge rst_n)begin
    if(!rst_n)begin
        dack <= 'd0;
        dack_d1 <= 'd0;
        dack_d2 <= 'd0;
        dack_d3 <= 'd0;
    end
    else begin
        dack <= (dbusy || dack & (!dack_d1 || !dack_d2)) ? 'd1 : (!dreq) ? 'd0 : dack;
        dack_d1 <= dack;
        dack_d2 <= dack_d1;
        dack_d3 <= dack_d2;
    end
end

always@(posedge dclk or negedge rst_n)begin
    if(!rst_n)begin
        dvalid <= 'd0;
        dout<= 0;
    end
    else begin
        dvalid <= (dbusy || dack) ? 'd0 : (dreq_d3) ? 'd1 : dvalid;
        dout <= (dreq_d3) ? r_data : dout;
    end
end


//assign stall = dvalid & dbusy;
//assign wait_req = (dreq & !dbusy & !dack);

NDFF_syn S2D_req(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn D2S_ack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));
NDFF_BUS_syn #(WIDTH) NDFF_bus(.D(data), .Q(r_data), .clk(dclk), .rst_n(rst_n));


endmodule