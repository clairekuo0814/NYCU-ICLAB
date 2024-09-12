//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
       bready_m_inf,
                    
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
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  reg [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  reg [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  reg [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  reg [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  reg [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  reg [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

parameter signed OFFSET = 16'h1000;
parameter T_IDLE = 3'd0, T_FETCH = 3'd1, T_DECODE = 3'd2, T_EXECUTE = 3'd3, T_MEM_LOAD = 3'd4, T_MEM_STORE = 3'd5, T_WRITE_BACK = 3'd6;//top FSM
parameter I_IDLE = 3'd0, I_HIT = 3'd1, I_WAIT = 3'd2, I_DRAM_ADDR = 3'd3, I_DRAM_DATA = 3'd4, I_COMP = 3'd5;//inst FSM
parameter L_IDLE = 3'd0, L_HIT = 3'd1, L_WAIT = 3'd2, L_DRAM_ADDR = 3'd3, L_DRAM_DATA = 3'd4, L_COMP = 3'd5, L_WRITE = 3'd6;//load FSM
parameter S_IDLE = 2'd0, S_DRAM_ADDR = 2'd1, S_DRAM_DATA = 2'd2, S_COMP = 2'd3;//store FSM

//####################################################
//               reg & wire
//####################################################
//top FSM
reg [2:0] top_cur_s;
reg [2:0] top_nxt_s;
//inst FSM
reg [2:0] inst_cur_s;
reg [2:0] inst_nxt_s;
reg inst_in_valid;

reg signed[15:0] cur_pc;
reg signed[15:0] nxt_pc;

reg load_comp;
reg store_comp;
reg fetch_comp;

wire [2:0] op;
wire [3:0] rs;
wire [3:0] rd;
wire [3:0] rt;
wire func;
wire signed[4:0] imme;
wire [12:0] addr;


reg [6:0] cur_inst_addr;
reg [3:0] inst_tag;
reg [DATA_WIDTH-1:0] inst;
wire [DATA_WIDTH-1:0] inst_sram_out;
reg [6:0] inst_sram_addr;
wire [6:0] inst_sram_addr_nxt;
wire inst_WEB;
reg [DATA_WIDTH-1:0] r_data_inst;
reg initial_inst_sram;
reg arready_m_inf_1_reg;
reg rvalid_m_inf_1_reg;
reg rlast_m_inf_1_reg;

//decode
reg signed [DATA_WIDTH-1:0] rd_data;
reg signed [DATA_WIDTH-1:0] rd_data_tmp;
reg signed [DATA_WIDTH-1:0] rs_data;
reg signed [DATA_WIDTH-1:0] rs_data_tmp;
reg signed [DATA_WIDTH-1:0] rt_data;
reg signed [DATA_WIDTH-1:0] rt_data_tmp;

//load
wire [ADDR_WIDTH-1:0] araddr_load;
reg signed [DATA_WIDTH-1:0] load_data;
reg load_in_valid;
reg [2:0] load_cur_s;
reg [2:0] load_nxt_s;
wire signed [DATA_WIDTH-1:0] data_addr;
reg signed [DATA_WIDTH-1:0] data_addr_reg;
reg initial_load_sram;
reg arvalid_load;
reg [3:0] load_tag;
wire [DATA_WIDTH-1:0] load_sram_out;
reg [6:0] load_sram_addr;
wire [6:0] load_sram_addr_nxt;
wire load_WEB;
wire [DATA_WIDTH-1:0] r_data_load;
reg [DATA_WIDTH-1:0] r_data_load_reg;
reg rlast_m_inf_0_reg;
reg arready_m_inf_0_reg;
reg rvalid_m_inf_0_reg;



//store
reg store_in_valid;
reg [1:0] store_cur_s;
reg [1:0] store_nxt_s;

//AXI4
reg arvalid_inst;
reg arvalid_data;
wire [ADDR_WIDTH-1:0] araddr_inst;
wire rready_inst;
wire rready_load;

//####################################################
//               design
//####################################################


//top FSM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        top_cur_s <= T_IDLE;
    end
    else begin
        top_cur_s <= top_nxt_s;
    end
end

always@(*)begin
    case(top_cur_s)
        T_IDLE : top_nxt_s = T_FETCH;
        T_FETCH : top_nxt_s = (fetch_comp) ? T_DECODE : top_cur_s;
        T_DECODE : top_nxt_s = T_EXECUTE;
        T_EXECUTE : begin
            if(op[2:1] == 2'b01)
                top_nxt_s = (op[0] == 0) ? T_MEM_LOAD : T_MEM_STORE;
            else if(op[2])
                top_nxt_s = T_FETCH;
            else
                top_nxt_s = T_WRITE_BACK;
        end
        T_MEM_LOAD : top_nxt_s = (load_comp) ? T_FETCH : top_cur_s;
        T_MEM_STORE : top_nxt_s = (store_comp) ? T_FETCH : top_cur_s;
        T_WRITE_BACK : top_nxt_s = T_FETCH;
        default : top_nxt_s = T_IDLE;
    endcase
end

//======================= fetch instruction =======================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cur_pc <= OFFSET;
    else
        cur_pc <= nxt_pc;
end

always@(*)begin
    if(top_cur_s == T_EXECUTE)
        if(op == 3'b100 && rs_data == rt_data)
            nxt_pc = cur_pc + 2 + (imme<<1);
        else if(op == 3'b101)
            nxt_pc = {3'b000, addr};
        else
            nxt_pc = cur_pc + 2;
    else
        nxt_pc = cur_pc;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        inst_in_valid <= 'd0;
    else
        inst_in_valid <= (top_nxt_s == T_FETCH && top_cur_s != T_FETCH);
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        inst_tag <= 'd0;
    else if(inst_cur_s == I_DRAM_ADDR)
        inst_tag <= cur_pc[11:8];
end

//inst FSM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        inst_cur_s <= I_IDLE;
    end
    else begin
        inst_cur_s <= inst_nxt_s;
    end
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        initial_inst_sram <= 'd0;
    end
    else begin
        initial_inst_sram <= (inst_cur_s == I_DRAM_DATA) ? 'd1 : initial_inst_sram;
    end
end

always@(*)
    case(inst_cur_s)
        I_IDLE : begin
            if(inst_in_valid)begin
                if(cur_pc[11:8] == inst_tag && initial_inst_sram)
                    inst_nxt_s = I_HIT;
                else
                    inst_nxt_s = I_DRAM_ADDR;
            end else
                inst_nxt_s = inst_cur_s;
        end
        I_HIT : inst_nxt_s = I_WAIT;
        I_WAIT : inst_nxt_s = I_COMP;
        I_DRAM_ADDR : inst_nxt_s = (arready_m_inf_1_reg) ? I_DRAM_DATA : inst_cur_s;
        I_DRAM_DATA : inst_nxt_s = (rlast_m_inf_1_reg) ? I_COMP : inst_cur_s;
        I_COMP : inst_nxt_s = I_IDLE;
        default : inst_nxt_s = I_IDLE;
    endcase

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        inst_sram_addr <= 'd0;
    end
    else
        inst_sram_addr <= inst_sram_addr_nxt;
end
assign inst_sram_addr_nxt = (inst_nxt_s == I_IDLE) ? 'd0 : (rvalid_m_inf_1_reg) ? inst_sram_addr + 'd1 : (inst_nxt_s == I_HIT) ? cur_pc[7:1] : inst_sram_addr;

assign inst_WEB = inst_cur_s != I_DRAM_DATA;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        arready_m_inf_1_reg <= 'd0;
        rvalid_m_inf_1_reg <= 'd0;
        r_data_inst <= 'd0;
        rlast_m_inf_1_reg <= 'd0;
    end
    else begin
        arready_m_inf_1_reg <= arready_m_inf[1];
        rvalid_m_inf_1_reg <= rvalid_m_inf[1];
        r_data_inst <= rdata_m_inf[DRAM_NUMBER * DATA_WIDTH-1:DATA_WIDTH];
        rlast_m_inf_1_reg <= rlast_m_inf[1];
    end
end
SRAM_128X16 r_inst_cache (  .A0(inst_sram_addr[0]), .A1(inst_sram_addr[1]), .A2(inst_sram_addr[2]),     .A3(inst_sram_addr[3]),     .A4(inst_sram_addr[4]),     .A5(inst_sram_addr[5]),     .A6(inst_sram_addr[6]),
                            .DO0(inst_sram_out[0]), .DO1(inst_sram_out[1]), .DO2(inst_sram_out[2]),     .DO3(inst_sram_out[3]),     .DO4(inst_sram_out[4]),     .DO5(inst_sram_out[5]),     .DO6(inst_sram_out[6]),     .DO7(inst_sram_out[7]), 
                            .DO8(inst_sram_out[8]), .DO9(inst_sram_out[9]), .DO10(inst_sram_out[10]),   .DO11(inst_sram_out[11]),   .DO12(inst_sram_out[12]),   .DO13(inst_sram_out[13]),   .DO14(inst_sram_out[14]),   .DO15(inst_sram_out[15]),
                            .DI0(r_data_inst[0]),   .DI1(r_data_inst[1]),   .DI2(r_data_inst[2]),       .DI3(r_data_inst[3]),       .DI4(r_data_inst[4]),       .DI5(r_data_inst[5]),       .DI6(r_data_inst[6]),       .DI7(r_data_inst[7]),
                            .DI8(r_data_inst[8]),   .DI9(r_data_inst[9]),   .DI10(r_data_inst[10]),     .DI11(r_data_inst[11]),     .DI12(r_data_inst[12]),     .DI13(r_data_inst[13]),     .DI14(r_data_inst[14]),     .DI15(r_data_inst[15]),
                            .CK(clk), .WEB(inst_WEB), .OE(1'b1), .CS(1'b1) 
                        );

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        inst <= 'd0;
    end
    else if(inst_cur_s == I_DRAM_DATA && inst_sram_addr == cur_pc[7:1] && rvalid_m_inf_1_reg)begin
        inst <= r_data_inst;
    end
    else if(inst_cur_s == I_WAIT)
        inst <= inst_sram_out;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fetch_comp <= 'd0;
    end
    else begin
        fetch_comp <= (inst_nxt_s == I_COMP);
    end
end

//AXI4
always@(*)begin
    if(inst_nxt_s == I_DRAM_ADDR && inst_cur_s != I_DRAM_ADDR)
        arvalid_inst <= 'd1;
    else
        arvalid_inst <= 'd0;
end
assign araddr_inst = {16'd0, 4'b0001, cur_pc[11:8], 8'd0};
assign rready_inst = inst_cur_s == I_DRAM_DATA;

//======================= instruction decode =======================
assign op = inst[15:13];
assign rs = inst[12:9];
assign rt = inst[8:5];
assign rd = inst[4:1];
assign func = inst[0];
assign imme = inst[4:0];
assign addr = inst[12:0];


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rs_data <= 'd0;
    end
    else if(top_nxt_s == T_DECODE)begin
        rs_data <= rs_data_tmp;
    end
end

always@(*)begin
    case(rs)
        'd0 : rs_data_tmp = core_r0;
        'd1 : rs_data_tmp = core_r1;
        'd2 : rs_data_tmp = core_r2;
        'd3 : rs_data_tmp = core_r3;
        'd4 : rs_data_tmp = core_r4;
        'd5 : rs_data_tmp = core_r5;
        'd6 : rs_data_tmp = core_r6;
        'd7 : rs_data_tmp = core_r7;
        'd8 : rs_data_tmp = core_r8;
        'd9 : rs_data_tmp = core_r9;
        'd10 : rs_data_tmp = core_r10;
        'd11 : rs_data_tmp = core_r11;
        'd12 : rs_data_tmp = core_r12;
        'd13 : rs_data_tmp = core_r13;
        'd14 : rs_data_tmp = core_r14;
        'd15 : rs_data_tmp = core_r15;
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rt_data <= 'd0;
    end
    else if(top_nxt_s == T_DECODE)begin
        rt_data <= rt_data_tmp;
    end
end

always@(*)begin
    case(rt)
        'd0 : rt_data_tmp = core_r0;
        'd1 : rt_data_tmp = core_r1;
        'd2 : rt_data_tmp = core_r2;
        'd3 : rt_data_tmp = core_r3;
        'd4 : rt_data_tmp = core_r4;
        'd5 : rt_data_tmp = core_r5;
        'd6 : rt_data_tmp = core_r6;
        'd7 : rt_data_tmp = core_r7;
        'd8 : rt_data_tmp = core_r8;
        'd9 : rt_data_tmp = core_r9;
        'd10 : rt_data_tmp = core_r10;
        'd11 : rt_data_tmp = core_r11;
        'd12 : rt_data_tmp = core_r12;
        'd13 : rt_data_tmp = core_r13;
        'd14 : rt_data_tmp = core_r14;
        'd15 : rt_data_tmp = core_r15;
    endcase
end
//======================= execute =======================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_data <= 'd0;
    end
    else if(top_nxt_s == T_EXECUTE)begin
        rd_data <= rd_data_tmp;
    end

end

always@(*)begin
    if((~|op))
        if(!func)
            rd_data_tmp = rs_data + rt_data;
        else
            rd_data_tmp = rs_data - rt_data;
    else if(op == 3'b001)
        if(!func)
            rd_data_tmp = (rs_data < rt_data) ? 'd1 : 'd0;
        else
            rd_data_tmp = rs_data * rt_data;
    else
        rd_data_tmp = 'd0;
end

//======================= LOAD =======================
assign data_addr = ((rs_data + imme) << 1) + OFFSET;
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        data_addr_reg <= 'd0;
    else
        data_addr_reg <= data_addr;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        load_in_valid <= 'd0;
    else
        load_in_valid <= (top_nxt_s == T_MEM_LOAD && top_cur_s != T_MEM_LOAD);
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        load_tag <= 'd0;
    else if(load_cur_s == L_DRAM_ADDR)
        load_tag <= data_addr_reg[11:8];
end

//load FSM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        load_cur_s <= L_IDLE;
    end
    else begin
        load_cur_s <= load_nxt_s;
    end
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        initial_load_sram <= 'd0;
    end
    else begin
        initial_load_sram <= (load_cur_s == L_DRAM_DATA) ? 'd1 : initial_load_sram;
    end
end

always@(*)
    case(load_cur_s)
        L_IDLE : begin
            if(store_in_valid && data_addr_reg[11:8] == load_tag)
                load_nxt_s = L_WRITE;
            else if(load_in_valid)begin
                if(data_addr_reg[11:8] == load_tag && initial_load_sram)
                    load_nxt_s = L_HIT;
                else
                    load_nxt_s = L_DRAM_ADDR;
            end 
            else
                load_nxt_s = load_cur_s;
        end
        L_HIT : load_nxt_s = L_WAIT;
        L_WAIT : load_nxt_s = L_COMP;
        L_DRAM_ADDR : load_nxt_s = (arready_m_inf_0_reg) ? L_DRAM_DATA : load_cur_s;
        L_DRAM_DATA : load_nxt_s = (rlast_m_inf_0_reg) ? L_COMP : load_cur_s;
        L_COMP : load_nxt_s = L_IDLE;
        L_WRITE : load_nxt_s = L_IDLE;
        default : load_nxt_s = L_IDLE;
    endcase

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        load_sram_addr <= 'd0;
    end
    else
        load_sram_addr <= load_sram_addr_nxt;
end
assign load_sram_addr_nxt = (load_nxt_s == L_IDLE) ? 'd0 : (rvalid_m_inf_0_reg) ? load_sram_addr + 'd1 : (load_nxt_s == L_HIT || load_nxt_s == L_WRITE) ? data_addr_reg[7:1] : load_sram_addr;

assign load_WEB = load_cur_s != L_DRAM_DATA && load_cur_s != L_WRITE;
assign r_data_load = (load_cur_s == L_WRITE) ? rt_data : r_data_load_reg;
SRAM_128X16 load_cache (  .A0(load_sram_addr[0]), .A1(load_sram_addr[1]), .A2(load_sram_addr[2]),     .A3(load_sram_addr[3]),     .A4(load_sram_addr[4]),     .A5(load_sram_addr[5]),     .A6(load_sram_addr[6]),
                            .DO0(load_sram_out[0]), .DO1(load_sram_out[1]), .DO2(load_sram_out[2]),     .DO3(load_sram_out[3]),     .DO4(load_sram_out[4]),     .DO5(load_sram_out[5]),     .DO6(load_sram_out[6]),     .DO7(load_sram_out[7]), 
                            .DO8(load_sram_out[8]), .DO9(load_sram_out[9]), .DO10(load_sram_out[10]),   .DO11(load_sram_out[11]),   .DO12(load_sram_out[12]),   .DO13(load_sram_out[13]),   .DO14(load_sram_out[14]),   .DO15(load_sram_out[15]),
                            .DI0(r_data_load[0]),   .DI1(r_data_load[1]),   .DI2(r_data_load[2]),       .DI3(r_data_load[3]),       .DI4(r_data_load[4]),       .DI5(r_data_load[5]),       .DI6(r_data_load[6]),       .DI7(r_data_load[7]),
                            .DI8(r_data_load[8]),   .DI9(r_data_load[9]),   .DI10(r_data_load[10]),     .DI11(r_data_load[11]),     .DI12(r_data_load[12]),     .DI13(r_data_load[13]),     .DI14(r_data_load[14]),     .DI15(r_data_load[15]),
                            .CK(clk), .WEB(load_WEB), .OE(1'b1), .CS(1'b1) 
                        );

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        load_data <= 'd0;
    end
    else if(load_cur_s == L_DRAM_DATA && load_sram_addr == data_addr_reg[7:1] && rvalid_m_inf_0_reg)begin
        load_data <= r_data_load;
    end
    else if(load_cur_s == L_WAIT)
        load_data <= load_sram_out;

end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        load_comp <= 'd0;
    end
    else begin
        load_comp <= (load_nxt_s == L_COMP);
    end
end

//AXI4

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rvalid_m_inf_0_reg <= 'd0;
        r_data_load_reg <= rdata_m_inf[DATA_WIDTH-1:0];
        arready_m_inf_0_reg <= 'd0;
        rlast_m_inf_0_reg <= 'd0;
    end
    else begin
        rvalid_m_inf_0_reg <= rvalid_m_inf[0];
        r_data_load_reg <= rdata_m_inf[DATA_WIDTH-1:0];
        arready_m_inf_0_reg <= arready_m_inf[0];
        rlast_m_inf_0_reg <= rlast_m_inf[0];
    end
end

always@(*)begin
    if(load_nxt_s == L_DRAM_ADDR && load_cur_s != L_DRAM_ADDR)
        arvalid_load <= 'd1;
    else
        arvalid_load <= 'd0;
end
assign araddr_load = {16'd0, 4'b0001, data_addr_reg[11:8], 8'd0};
assign rready_load = load_cur_s == L_DRAM_DATA;

//======================= STORE =======================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        store_in_valid <= 'd0;
    else
        store_in_valid <= (top_nxt_s == T_MEM_STORE && top_cur_s != T_MEM_STORE);
end

//store FSM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        store_cur_s <= S_IDLE;
    end
    else begin
        store_cur_s <= store_nxt_s;
    end
end

always@(*)begin
    case(store_cur_s)
        S_IDLE : store_nxt_s = (store_in_valid) ? S_DRAM_ADDR : store_cur_s;
        S_DRAM_ADDR : store_nxt_s = (awready_m_inf) ? S_DRAM_DATA : store_cur_s;
        S_DRAM_DATA : store_nxt_s = (wready_m_inf && wlast_m_inf) ? S_COMP : store_cur_s;
        S_COMP : store_nxt_s = (bvalid_m_inf) ? S_IDLE : store_cur_s;
        default : store_nxt_s = S_IDLE;
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        store_comp <= 'd0;
    end
    else begin
        store_comp <= (store_cur_s == S_COMP && bvalid_m_inf);
    end
end

//AXI4 signal
assign awaddr_m_inf = {16'd0, 4'b0001, data_addr_reg[11:1], 1'b0};

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        awvalid_m_inf <= 'd0;
    end
    else begin
        awvalid_m_inf <= (store_nxt_s == S_DRAM_ADDR);
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wdata_m_inf <= 'd0;
    end
    else begin
        wdata_m_inf <= (store_in_valid) ? rt_data : wdata_m_inf;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wvalid_m_inf <= 'd0;
        wlast_m_inf <= 'd0;
    end
    else begin
        wvalid_m_inf <= (store_nxt_s == S_DRAM_DATA);
        wlast_m_inf <= (store_nxt_s == S_DRAM_DATA);
    end
end

assign bready_m_inf = store_cur_s==S_COMP;

//======================= register write back =======================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        core_r0 <= 'd0;
        core_r1 <= 'd0;
        core_r2 <= 'd0;
        core_r3 <= 'd0;
        core_r4 <= 'd0;
        core_r5 <= 'd0;
        core_r6 <= 'd0;
        core_r7 <= 'd0;
        core_r8 <= 'd0;
        core_r9 <= 'd0;
        core_r10 <= 'd0;
        core_r11 <= 'd0;
        core_r12 <= 'd0;
        core_r13 <= 'd0;
        core_r14 <= 'd0;
        core_r15 <= 'd0;
    end
    else if(load_comp)begin
        case(rt)
            'd0 : core_r0 <= load_data;
            'd1 : core_r1 <= load_data;
            'd2 : core_r2 <= load_data;
            'd3 : core_r3 <= load_data;
            'd4 : core_r4 <= load_data;
            'd5 : core_r5 <= load_data;
            'd6 : core_r6 <= load_data;
            'd7 : core_r7 <= load_data;
            'd8 : core_r8 <= load_data;
            'd9 : core_r9 <= load_data;
            'd10 : core_r10 <= load_data;
            'd11 : core_r11 <= load_data;
            'd12 : core_r12 <= load_data;
            'd13 : core_r13 <= load_data;
            'd14 : core_r14 <= load_data;
            'd15 : core_r15 <= load_data;
        endcase
    end
    else if(top_nxt_s == T_WRITE_BACK)begin
        case(rd)
            'd0 : core_r0 <= rd_data;
            'd1 : core_r1 <= rd_data;
            'd2 : core_r2 <= rd_data;
            'd3 : core_r3 <= rd_data;
            'd4 : core_r4 <= rd_data;
            'd5 : core_r5 <= rd_data;
            'd6 : core_r6 <= rd_data;
            'd7 : core_r7 <= rd_data;
            'd8 : core_r8 <= rd_data;
            'd9 : core_r9 <= rd_data;
            'd10 : core_r10 <= rd_data;
            'd11 : core_r11 <= rd_data;
            'd12 : core_r12 <= rd_data;
            'd13 : core_r13 <= rd_data;
            'd14 : core_r14 <= rd_data;
            'd15 : core_r15 <= rd_data;
        endcase
    end
end

//======================= output =======================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        IO_stall <= 'd1;
    end
    else if(top_cur_s != T_FETCH && top_nxt_s == T_FETCH && top_cur_s != T_IDLE)begin
        IO_stall <= 'd0;
    end
    else
        IO_stall <= 'd1;
end

//======================= AXI4 =======================
//read
assign arid_m_inf = 'd0;
assign arlen_m_inf = {14{1'b1}};
assign arsize_m_inf = {3'b001, 3'b001};
assign arburst_m_inf = {2'b01, 2'b01} ;

//write
assign awid_m_inf = 'd0;
assign awlen_m_inf = 7'd0;
assign awsize_m_inf = 3'b001;
assign awburst_m_inf = 2'b01;

assign rready_m_inf = {rready_inst, rready_load};
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        arvalid_m_inf <= 'd0;
        araddr_m_inf <= 'd0;
    end
    else begin
        arvalid_m_inf <= {arvalid_inst, arvalid_load};
        araddr_m_inf <= {araddr_inst, araddr_load};
    end
end
endmodule

