module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

output fifo_clk3_flag1;
output fifo_clk3_flag2;
input fifo_clk3_flag3;
input fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

// rdata
//  Add one more register stage to rdata

/*
always @(posedge rclk) begin
    if (rinc)
        rdata <= rdata_q;
end*/
always@(posedge rclk or negedge rst_n)begin
    if(!rst_n)begin
        rdata <= 'd0;
    end
    else begin
        rdata <= rdata_q;
    end
end


//gray code
function [$clog2(WORDS):0] addr_to_gray;
    input [$clog2(WORDS):0] addr;
    addr_to_gray = addr ^ {1'b0, addr[6:1]};
endfunction

//gray code judge
function [$clog2(WORDS):0] gray_to_judge;
    input [$clog2(WORDS):0] gray;
    gray_to_judge = {gray[6], gray[6] ^ gray[5], gray[4:0]};
endfunction


wire [$clog2(WORDS):0] r_wptr;
wire [$clog2(WORDS):0] r_rptr;
NDFF_BUS_syn #(.WIDTH(7))  NDFF_wptr(
    .D(wptr), .Q(r_wptr), .clk(rclk), .rst_n(rst_n)
);

NDFF_BUS_syn #(.WIDTH(7))  NDFF_rptr(
    .D(rptr), .Q(r_rptr), .clk(wclk), .rst_n(rst_n)
);

//write ctrl
reg [6:0] write_addr;
wire [6:0] write_addr_tmp;
wire WEAN;
always@(posedge wclk or negedge rst_n)begin
    if(!rst_n)begin
        write_addr <= 'd0;
    end
    else begin
        write_addr <= write_addr_tmp;
        
    end
end
assign write_addr_tmp = (!WEAN) ? write_addr + 'd1 : write_addr;
assign WEAN = ~(winc && !wfull);

wire [$clog2(WORDS):0] wptr_judge, r_rptr_judge;
wire [$clog2(WORDS):0] wptr_cur;
always@(posedge wclk or negedge rst_n)begin
    if(!rst_n)begin
        wptr <= 'd0;
    end
    else begin
        wptr <= wptr_cur;
    end
end
assign wptr_cur = addr_to_gray(write_addr);
assign wptr_judge = gray_to_judge(wptr_cur);
assign r_rptr_judge = gray_to_judge(r_rptr);

always@(*)begin
    if(wptr_judge[5:0] == r_rptr_judge[5:0] && wptr_judge[6] != r_rptr_judge[6])
        wfull = 'd1;
    else
        wfull = 'd0;
end


//read ctrl
reg [6:0] read_addr;
wire [6:0] read_addr_tmp;
always@(posedge rclk or negedge rst_n)begin
    if(!rst_n)begin
        read_addr <= 'd0;
    end
    else begin
        read_addr <= read_addr_tmp;
    end
end
assign read_addr_tmp = (!rempty) ? read_addr + 'd1 : read_addr;

wire [$clog2(WORDS):0] rptr_cur;
always@(posedge rclk or negedge rst_n)begin
    if(!rst_n)begin
        rptr <= 'd0;
    end
    else begin
        rptr <= rptr_cur;
    end
end
wire [$clog2(WORDS):0] r_wptr_judge, rptr_judge;
assign rptr_cur = addr_to_gray(read_addr);
assign r_wptr_judge = gray_to_judge(r_wptr);
assign rptr_judge = gray_to_judge(rptr_cur);

always@(*)begin
    if(r_wptr_judge == rptr_judge)
        rempty = 'd1;
    else
        rempty = 'd0;
end



wire WEBN = 1'b1;
wire CSA = ~WEAN;
wire CSB = ~rempty;
wire OEA = 1'b1;
wire OEB = 1'b1;
wire [WIDTH-1:0] w_DIA;
assign w_DIA = (!WEAN) ? wdata : 'd0;

DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(WEAN),
    .WEBN(WEBN),
    .CSA(CSA),
    .CSB(CSB),
    .OEA(OEA),
    .OEB(OEB),
    .A0(write_addr[0]),
    .A1(write_addr[1]),
    .A2(write_addr[2]),
    .A3(write_addr[3]),
    .A4(write_addr[4]),
    .A5(write_addr[5]),
    .B0(read_addr[0]),
    .B1(read_addr[1]),
    .B2(read_addr[2]),
    .B3(read_addr[3]),
    .B4(read_addr[4]),
    .B5(read_addr[5]),
    .DIA0(w_DIA[0]),
    .DIA1(w_DIA[1]),
    .DIA2(w_DIA[2]),
    .DIA3(w_DIA[3]),
    .DIA4(w_DIA[4]),
    .DIA5(w_DIA[5]),
    .DIA6(w_DIA[6]),
    .DIA7(w_DIA[7]),
    .DIA8(w_DIA[8]),
    .DIA9(w_DIA[9]),
    .DIA10(w_DIA[10]),
    .DIA11(w_DIA[11]),
    .DIA12(w_DIA[12]),
    .DIA13(w_DIA[13]),
    .DIA14(w_DIA[14]),
    .DIA15(w_DIA[15]),
    .DIA16(w_DIA[16]),
    .DIA17(w_DIA[17]),
    .DIA18(w_DIA[18]),
    .DIA19(w_DIA[19]),
    .DIA20(w_DIA[20]),
    .DIA21(w_DIA[21]),
    .DIA22(w_DIA[22]),
    .DIA23(w_DIA[23]),
    .DIA24(w_DIA[24]),
    .DIA25(w_DIA[25]),
    .DIA26(w_DIA[26]),
    .DIA27(w_DIA[27]),
    .DIA28(w_DIA[28]),
    .DIA29(w_DIA[29]),
    .DIA30(w_DIA[30]),
    .DIA31(w_DIA[31]),
    /*.DIB0(),
    .DIB1(),
    .DIB2(),
    .DIB3(),
    .DIB4(),
    .DIB5(),
    .DIB6(),
    .DIB7(),
    .DIB8(),
    .DIB9(),
    .DIB10(),
    .DIB11(),
    .DIB12(),
    .DIB13(),
    .DIB14(),
    .DIB15(),
    .DIB16(),
    .DIB17(),
    .DIB18(),
    .DIB19(),
    .DIB20(),
    .DIB21(),
    .DIB22(),
    .DIB23(),
    .DIB24(),
    .DIB25(),
    .DIB26(),
    .DIB27(),
    .DIB28(),
    .DIB29(),
    .DIB30(),
    .DIB31(),*/
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);


endmodule
