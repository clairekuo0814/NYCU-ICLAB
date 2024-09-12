module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================

/*
typedef enum logic [2:0]{
    IDLE,
    READ_ADDR,
    READ_DATA,
    READ_COMPLETE,
    WRITE_ADDR,
    WRITE_DATA,
    WRITE_RESP,
    WRITE_COMPLETE
} State;
*/


// REGISTERS
//State state, nstate;

logic [16:0] addr_save;
logic [63:0] data_save;

logic [16:0] addr_save_tmp;


//================================================================
// state 
//================================================================
/*
// STATE MACHINE
always_ff @( posedge clk or negedge inf.rst_n) begin : BRIDGE_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else state <= nstate;
end

always_comb begin : BRIDGE_FSM_COMB
    case(state)
        IDLE: begin
            if (inf.C_in_valid)
            begin
                if(inf.C_r_wb)
                    nstate = READ_ADDR;
                else
                    nstate = WRITE_ADDR;
            end
            else
            begin
                nstate = IDLE;
            end
        end
        READ_ADDR : begin
            if(inf.AR_READY && inf.AR_VALID)
                nstate = READ_DATA;
            else
                nstate = state;
        end
        READ_DATA : begin
            if(inf.R_READY && inf.R_VALID)
                nstate = READ_COMPLETE;
            else
                nstate = state;
        end 
        READ_COMPLETE : 
            nstate = IDLE;
        WRITE_ADDR : begin
            if(inf.AW_READY && inf.AW_VALID)
                nstate = WRITE_DATA;
            else
                nstate = state;
        end
        WRITE_DATA : begin
            if(inf.W_READY && inf.W_VALID)
                nstate = WRITE_RESP;
            else
                nstate = state;
        end
        WRITE_RESP : begin
            if(inf.B_READY && inf.B_VALID)
                nstate = WRITE_COMPLETE;
            else
                nstate = state;
        end
        WRITE_COMPLETE : 
            nstate = IDLE;
        default: nstate = IDLE;
    endcase
end

*/
//save input
always_comb
    addr_save_tmp = {1'd1, 5'd0, inf.C_addr, 3'd0};
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) addr_save <= 'd0;
    else addr_save <= (inf.C_in_valid) ? addr_save_tmp : addr_save;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) data_save <= 'd0;
    else data_save <= (inf.C_in_valid && !inf.C_r_wb) ? inf.C_data_w : (inf.R_VALID && inf.R_READY) ? inf.R_DATA : data_save;
end


// ------------------------ output -----------------------//
//read signal

always_ff @( posedge clk or negedge inf.rst_n) begin    //READ_ADDR
    if (!inf.rst_n) inf.AR_VALID <= 'd0;
    else inf.AR_VALID <= (inf.AR_READY && inf.AR_VALID) ? 'd0 : (inf.C_in_valid && inf.C_r_wb) ? 'd1 : inf.AR_VALID;
end
always_ff @( posedge clk or negedge inf.rst_n) begin    //READ_DATA
    if (!inf.rst_n) inf.R_READY <= 'd0;
    else inf.R_READY <= (inf.R_READY && inf.R_VALID) ? 'd0 : (inf.AR_READY && inf.AR_VALID) ? 'd1 : inf.R_READY;
end

//write signal
always_ff @( posedge clk or negedge inf.rst_n) begin    //WRITE_ADDR
    if (!inf.rst_n) inf.AW_VALID <= 'd0;
    else inf.AW_VALID <= (inf.AW_READY && inf.AW_VALID) ? 'd0 : (inf.C_in_valid && !inf.C_r_wb) ? 'd1 : inf.AW_VALID;
end
always_ff @( posedge clk or negedge inf.rst_n) begin    //WRITE_DATA
    if (!inf.rst_n) inf.W_VALID <= 'd0;
    else inf.W_VALID <= (inf.W_READY && inf.W_VALID) ? 'd0 : (inf.AW_READY && inf.AW_VALID) ? 'd1 : inf.W_VALID;
end
always_ff @( posedge clk or negedge inf.rst_n) begin    //WRITE_RESP
    if (!inf.rst_n) inf.B_READY <= 'd0;
    else inf.B_READY <= (inf.B_READY && inf.B_VALID) ? 'd0 : (inf.AW_READY && inf.AW_VALID) ? 'd1 : inf.B_READY;
end


always_ff @( posedge clk or negedge inf.rst_n) begin    //WRITE_RESP
    if (!inf.rst_n) inf.C_out_valid <= 'd0;
    else inf.C_out_valid <= (inf.B_READY && inf.B_VALID) || (inf.R_READY && inf.R_VALID);
end

always_comb begin
    //READ_ADDR
    //inf.AR_VALID = state == READ_ADDR;
    inf.AR_ADDR = addr_save;
    //READ_DATA
    //inf.R_READY = state == READ_DATA;
end

//write signal
always_comb begin
    //WRITE_ADDR
    //inf.AW_VALID = state == WRITE_ADDR;
    inf.AW_ADDR = addr_save;
    //WRITE_DATA
    //inf.W_VALID = state == WRITE_DATA;
    inf.W_DATA = data_save;
    //WRITE_RESP
    //inf.B_READY = state == WRITE_DATA || state == WRITE_RESP;
end


always_comb begin
    //inf.C_out_valid = (state == WRITE_COMPLETE) || (state == READ_COMPLETE);
    inf.C_data_r = data_save;
end




endmodule