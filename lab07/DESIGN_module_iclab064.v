module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;


wire [31:0] seed_out_nxt;
wire out_valid_nxt;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        seed_out <= 'd0;
        out_valid <= 'd0;
    end
    else begin
        seed_out <= seed_out_nxt;
        out_valid <= out_valid_nxt;
    end
end
assign seed_out_nxt = (in_valid) ? seed_in : seed_out;
assign out_valid_nxt = (in_valid);


endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output reg [31:0] rand_num;
output busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

parameter RANDOM_A = 'd13, RANDOM_B = 'd17, RANDOM_C = 'd5;
reg [31:0] rand_num_compute;
//reg [1:0]clk2_cs;
reg clk2_cs;
reg WORK_d1;
parameter IDLE = 2'd0, WORK = 2'd1, OUTPUT = 2'd2, WAIT = 2'd3;
//handshake
reg in_valid_d1;
reg in_valid_d2, in_valid_d3, in_valid_d4;
wire [31:0] rand_num_tmp;
wire [31:0] seed_syn;
NDFF_BUS_syn #(32) NDFF_bus_syn (.D(seed),.Q(seed_syn),.clk(clk),.rst_n(rst_n));
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_valid_d1 <= 'd0;
        in_valid_d2 <= 'd0;
        in_valid_d3 <= 'd0;
        //in_valid_d4 <= 'd0;
        rand_num <= 'd0;
    end
    else begin
        in_valid_d1 <= in_valid;
        in_valid_d2 <= in_valid_d1;
        in_valid_d3 <= in_valid_d2;
        //in_valid_d4 <= in_valid_d3;
        rand_num <= rand_num_tmp;
    end
end
//reg busy_d1, busy_d2, busy_d3;
assign busy = in_valid_d1 && !in_valid_d2 ;
/*
always@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        busy_d1 <= 'd0;
        busy_d2 <= 'd0;
        busy_d3 <= 'd0;
    end
    else begin
        busy_d1 <= |clk2_cs;
        busy_d2 <= busy_d1;
        busy_d3 <= busy_d2;
    end*/

/*
reg busy_judge;
assign busy = busy_judge;
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        busy_judge <= 'd0;
    else
        busy_judge <= in_valid;*/
assign rand_num_tmp = (in_valid_d2) ? seed_syn : (clk2_cs) ?  (fifo_full) ? rand_num : rand_num_compute : rand_num;

//compute
//reg [1:0] clk2_ns;
reg clk2_ns;
reg [7:0] turn_cnt;
wire [7:0] turn_cnt_tmp;

/*
wire ctrl;
assign ctrl = valid || !fifo_full;
NDFF_syn fsm_ctrl(.D(ctrl), .Q(ctrl), .clk(clk), .rst_n(rst_n));*/

//reg busy_d1;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        clk2_cs <= IDLE;
    end
    else begin
        clk2_cs <= clk2_ns;
    end
end

always@(*)begin
    case(clk2_cs)
        IDLE : clk2_ns = (in_valid_d3) ? WORK : clk2_cs;
        WORK : clk2_ns = (!fifo_full && &turn_cnt) ? IDLE : clk2_cs;
        //OUTPUT : clk2_ns = (&turn_cnt) ? IDLE : WORK;
        default : clk2_ns = IDLE;
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        WORK_d1 <= 'd0;
    end
    else begin
        WORK_d1 <= clk2_cs == WORK;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        turn_cnt <= 'd0;
        
    end
    else begin
        turn_cnt <= turn_cnt_tmp;
    end
end

reg out_start;
assign turn_cnt_tmp = (out_start && clk2_cs && !fifo_full) ? turn_cnt + 'd1 : turn_cnt;

reg [31:0] rand_num_compute1, rand_num_compute2;
always@(*)begin
    rand_num_compute1 = rand_num ^ (rand_num << 13);
    rand_num_compute2 = rand_num_compute1 ^ (rand_num_compute1 >> 17);
    rand_num_compute = rand_num_compute2 ^ (rand_num_compute2 << 5);
end

//fifo
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_start <= 'd0;
        
    end
    else begin
        out_start <= clk2_cs;
    end
end
assign out_valid = (out_start && clk2_cs) && !fifo_full;

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output reg fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;


// ===============================================================
// Reg & Wire Declaration
// ===============================================================
wire out_valid_tmp;
wire [31:0] rand_num_tmp;
reg [3:0] test;

//fifo
/*
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_rinc <= 'd0;
    end
    else begin
        fifo_rinc <= ~(fifo_empty);
    end
end*/
always@(*)
    fifo_rinc = ~(fifo_empty);


// ------------------------------ output ------------------------------
reg fifo_rinc_d1, fifo_rinc_d2;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_rinc_d1 <= 'd0;
        fifo_rinc_d2 <= 'd0;
    end
    else begin
        fifo_rinc_d1 <= fifo_rinc;
        fifo_rinc_d2 <= fifo_rinc_d1;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 'd0;
        rand_num <= 'd0;
    end
    else begin
        out_valid <= out_valid_tmp;
        rand_num <= rand_num_tmp;
    end
end
assign out_valid_tmp = fifo_rinc_d2;
assign rand_num_tmp = (fifo_rinc_d2) ? fifo_rdata : 'd0;



endmodule