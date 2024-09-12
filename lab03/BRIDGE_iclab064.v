//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 'd0, COMMAND = 'd1, DIR0_READY = 'd2, TRANSFER_DATA = 'd3, DIR1_READY = 'd4, RECEIVE_DATA = 'd5, OUTPUT = 'd6;


//==============================================//
//           reg & wire declaration             //
//==============================================//
/*Flip-Flop*/
//FSM
reg [2:0] cs;

//input save
reg dir_save;
reg [12:0] addr_dram_save;
reg [15:0] addr_sd_save;
/********************* SD *********************/
//command
reg [47:0] command_line;

//command response check
reg [2:0] resp_cnt, wait_cycle;
reg [4:0] wait_unit;

//transfer data for SD
reg [88:0] data_line;

//receive data from SD
reg [64:0] SD_data;
reg [15:0] CRC16_check;

/********************* DRAM *********************/
//receive data from DRAM
reg [63:0] DRAM_data;

/********************* output *********************/
reg [2:0] out_cnt;


/*Combinational*/
//FSM
reg [2:0] ns;

//input save
wire dir_save_tmp;
wire [12:0] addr_dram_save_tmp;
wire [15:0] addr_sd_save_tmp;

//write address
reg AW_VALID_done;

//write response check
reg [7:0] write_response;
/********************* SD *********************/
//command
reg [5:0] command;
reg [39:0] command_40;
reg [47:0] command_line_tmp;

//output for SD
reg MOSI_tmp;

//command response check
wire [2:0] resp_cnt_tmp, wait_cycle_tmp;
wire [4:0] wait_unit_tmp;

//transfer data for SD
reg [88:0] data_line_tmp;

//write address
wire [12:0] AW_ADDR_tmp;
wire AW_VALID_tmp;
wire AW_VALID_done_tmp;

//write response check
wire [7:0] write_response_tmp;

//receive data from SD
wire [64:0] SD_data_tmp;
wire [15:0] CRC16_check_tmp;

/********************* DRAM *********************/
//DRAM ctrl
//read address
wire [12:0] AR_ADDR_tmp;
wire AR_VALID_tmp;
//read response
wire R_READY_tmp;

//receive data from DRAM
wire [63:0] DRAM_data_tmp;

//write SD_data
wire [63:0] W_DATA_tmp;
wire W_VALID_tmp;

//write response
wire B_READY_tmp;

/********************* output *********************/
reg out_valid_tmp;
reg [7:0] out_data_tmp;
wire [2:0] out_cnt_tmp;


//==============================================//
//                  design                      //
//==============================================//

//FSM
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cs <= IDLE;
    end else begin
        cs <= ns;
    end
end


always@(*)begin
    case(cs)
        IDLE    : ns = (in_valid) ? COMMAND : IDLE;
        COMMAND : ns = (command_line[47] && (~|command_line[46:0])) ? (dir_save) ? DIR1_READY : DIR0_READY : COMMAND;
        DIR0_READY : ns = (wait_cycle == 'd7 && data_line[87]) ? TRANSFER_DATA : DIR0_READY;
        TRANSFER_DATA : ns = (write_response == 8'b00000101 && MISO) ? OUTPUT : TRANSFER_DATA;
        DIR1_READY : ns = (&resp_cnt) ? RECEIVE_DATA : DIR1_READY;
        RECEIVE_DATA : ns = (B_VALID && B_RESP == 'd0 && B_READY && !SD_data[64]) ? OUTPUT : RECEIVE_DATA;
        OUTPUT : ns = (&out_cnt) ? IDLE : OUTPUT;
        default : ns = IDLE;
    endcase
end


//input save
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        dir_save <= 0;
        addr_dram_save <= 0;
        addr_sd_save <= 0;
    end else begin
        dir_save <= dir_save_tmp;
        addr_dram_save <= addr_dram_save_tmp;
        addr_sd_save <= addr_sd_save_tmp;
    end
end

assign dir_save_tmp = (in_valid) ? direction : dir_save;
assign addr_dram_save_tmp = (in_valid) ? addr_dram : addr_dram_save;
assign addr_sd_save_tmp = (in_valid) ? addr_sd : addr_sd_save;

/********************* SD *********************/
//command
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        command_line <= {48{1'b1}};
    end else begin
        command_line <= command_line_tmp;
    end
end

always @(*)begin
    command = (dir_save) ? 'd17 : 'd24;
    command_40 = {2'b01, command, {16'd0, addr_sd_save}};
    if(cs == COMMAND)
        if(&command_line) begin
            command_line_tmp = {command_40, CRC7(command_40), 1'b1};
        end else begin
            command_line_tmp = command_line << 1;
        end
    else begin
        command_line_tmp = {48{1'b1}};
    end
end

//output for SD
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        MOSI <= 'd1;
    end else begin
        MOSI <= MOSI_tmp;
    end
end

always@(*)begin
    case(cs)
        COMMAND : MOSI_tmp = (&command_line) ? 'd1 : command_line[47];
        TRANSFER_DATA : MOSI_tmp = (~|data_line) ? 'd1 : data_line[88];
        default : MOSI_tmp = 'd1;
    endcase
end

//command response check

always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        resp_cnt <= 'd0;
        wait_cycle <= 'd0;
        wait_unit <= 'd0;
    end
    else begin
        resp_cnt <= resp_cnt_tmp;
        wait_cycle <= wait_cycle_tmp;
        wait_unit <= wait_unit_tmp;
    end
end

assign resp_cnt_tmp = (cs == DIR0_READY || cs == DIR1_READY) ? (&resp_cnt) ? resp_cnt : (!MISO) ? resp_cnt + 1 : 'd0 : 'd0;
assign wait_cycle_tmp = (&resp_cnt) ? wait_cycle + 1 : 'd0;
assign wait_unit_tmp = (cs == DIR0_READY) ? (wait_cycle == 'd7) ? wait_unit + 1 : wait_unit : 'd0;

//transfer data for SD

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_line <= 1'b0;
    else
        data_line <= data_line_tmp;
end
always@(*)begin
    case(cs)
        DIR0_READY : data_line_tmp = (|DRAM_data) ? {8'hFE, DRAM_data, CRC16_CCITT(DRAM_data), 1'b1} : 'd0;
        TRANSFER_DATA : data_line_tmp = data_line << 1;
        default : data_line_tmp = 'd0;
    endcase
end



//write response check
always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        write_response <= {8{1'b1}};
    end
    else begin
        write_response <= write_response_tmp;
    end
end

assign write_response_tmp = (cs == TRANSFER_DATA) ? (write_response == 8'b00000101) ? write_response : {write_response[6:0], MISO} : {8{1'b1}};

//receive data from SD

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        SD_data <= {65{1'b1}};
        CRC16_check <= {16{1'b1}};
    end
    else begin
        SD_data <= SD_data_tmp;
        CRC16_check <= CRC16_check_tmp;
    end
end

assign SD_data_tmp = ((B_VALID && B_RESP == 'd0 && B_READY && !SD_data[64]) || cs == OUTPUT) ? SD_data << 8 : (cs == RECEIVE_DATA) ?  {!SD_data[64]} ? SD_data : {SD_data[63:0], CRC16_check[15]} : {65{1'b1}};
assign CRC16_check_tmp = (cs == RECEIVE_DATA) ?  {!SD_data[64]} ? CRC16_check : {CRC16_check[14:0], MISO} : {16{1'b1}};
/********************* DRAM *********************/
//DRAM ctrl
//read address

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        AR_ADDR <= 'd0;
        AR_VALID <= 'd0;
    end
    else begin
        AR_ADDR <= AR_ADDR_tmp;
        AR_VALID <= AR_VALID_tmp;
    end
end


assign AR_ADDR_tmp = (in_valid && !direction) ? addr_dram : (AR_READY && AR_VALID) ? 'd0 : AR_ADDR;
assign AR_VALID_tmp = (in_valid && !direction) ? 'd1 : (AR_READY && AR_VALID) ? 'd0 : AR_VALID;
//read response
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        R_READY <= 'd0;
    end
    else begin
        R_READY <= R_READY_tmp;
    end
end
assign R_READY_tmp = (AR_READY && AR_VALID) ? 'd1 : (R_READY && R_VALID && R_RESP == 'd0) ? 'd0 : R_READY;

//receive data from DRAM
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        DRAM_data <= 'd0;
    else
        DRAM_data <= DRAM_data_tmp;
end

assign DRAM_data_tmp =  (|cs) ? (R_VALID && R_RESP == 'd0 && R_READY) ? R_DATA : ((write_response == 8'b00000101 && MISO) || cs == OUTPUT) ? DRAM_data << 8 : DRAM_data : 'd0;


//write address
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        AW_ADDR <= 'd0;
        AW_VALID <= 'd0;
    end
    else begin
        AW_ADDR <= AW_ADDR_tmp;
        AW_VALID <= AW_VALID_tmp;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        AW_VALID_done <= 'd0;
    end
    else begin
        AW_VALID_done <= AW_VALID_done_tmp;
    end
end

assign AW_VALID_done_tmp = (cs == IDLE) ? 'd0 : (AW_VALID) ? 'd1 : AW_VALID_done;
assign AW_ADDR_tmp = (!SD_data[64] && !AW_VALID_done) ? addr_dram_save : (AW_READY && AW_VALID) ? 'd0 : AW_ADDR;
assign AW_VALID_tmp = (!SD_data[64] && !AW_VALID_done) ? 'd1 : (AW_READY && AW_VALID) ? 'd0 : AW_VALID;

//write SD_data
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        W_DATA <= 'd0;
        W_VALID <= 'd0;
    end
    else begin
        W_DATA <= W_DATA_tmp;
        W_VALID <= W_VALID_tmp;
    end
end


assign W_DATA_tmp = (AW_READY && AW_VALID) ? SD_data[63:0] : (W_VALID && W_READY) ? 'd0 : W_DATA ;
assign W_VALID_tmp = (AW_READY && AW_VALID) ? 'd1 :  (W_VALID && W_READY) ? 'd0 : W_VALID;

//write response
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        B_READY <= 'd0;
    end
    else begin
        B_READY <= B_READY_tmp;
    end
end
assign B_READY_tmp = (AW_VALID && AW_READY) ? 'd1 : (B_VALID && B_READY) ? 'd0 : B_READY;




/********************* output *********************/
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 'd0;
        out_data <= 'd0;
    end
    else begin
        out_valid <= out_valid_tmp;
        out_data <= out_data_tmp;
    end
end


always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_cnt <= 'd0;
    end
    else begin
        out_cnt <= out_cnt_tmp;
    end
end

assign out_cnt_tmp = (cs == OUTPUT) ? out_cnt + 'd1 : 'd0;

always@(*)begin
    case(cs)
        TRANSFER_DATA : out_data_tmp = (write_response == 8'b00000101 && MISO) ? DRAM_data[63:56] :'d0;
        RECEIVE_DATA : out_data_tmp = (B_VALID && B_RESP == 'd0 && B_READY && !SD_data[64]) ? SD_data[63:56] : 'd0;
        OUTPUT : out_data_tmp = (&out_cnt) ? 'd0 : (dir_save) ? SD_data[63:56] : DRAM_data[63:56];
        default : out_data_tmp = 'd0;
    endcase
end

always@(*)begin
    case(cs)
        TRANSFER_DATA : out_valid_tmp = (write_response == 8'b00000101 && MISO) ? 'd1 :'d0;
        RECEIVE_DATA : out_valid_tmp = (B_VALID && B_RESP == 'd0 && B_READY && !SD_data[64]) ? 'd1 : 'd0;
        OUTPUT : out_valid_tmp = (&out_cnt) ? 'd0 : 'd1;
        default : out_valid_tmp = 'd0;
    endcase
end

/*CRC function*/
function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (integer i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction


function automatic [15:0] CRC16_CCITT;
    // Try to implement CRC-16-CCITT function by yourself.
    input [63:0] data;  // 40-bit data input
    reg [15:0] crc;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^16 + x^12 + x^5 + 1

    begin
        crc = 16'd0;
        for (integer i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction



endmodule

