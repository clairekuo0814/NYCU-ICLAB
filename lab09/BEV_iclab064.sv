module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
typedef enum logic [1:0]{
    IDLE,
    MAKE_DRINK,
    SUPPLY,
    CHECK_DATE
} state_t;

//make drink fsm
typedef enum logic [1:0]{
    IDLE_M,
    WORK_M,
    WRITE_BACK_M
} state_m;

//supply fsm
typedef enum logic [1:0]{
    IDLE_S,
    WORK_S,
    WRITE_BACK_S
} state_s;

//check date fsm
typedef enum logic{
    IDLE_C,
    WORK_C
} state_c;



typedef enum logic [3:0]{
    EMPTY = 4'b0000,
    FIRST = 4'b0001,
    SECOND = 4'b0010,
    THIRD = 4'b0100,
    FOURTH = 4'b1000
} Sup_4;

Bev_Type type_save;
Bev_Size size_save;
Month month_save;
Day day_save;
Barrel_No box_no_save;

Sup_4 sup_4comp;
Sup_4 sup_4comp_nxt;
logic size_comp;


ING black_tea_need;
ING green_tea_need;
ING milk_need;
ING pineapple_need;

ING black_tea_reg;
ING green_tea_reg;
ING milk_reg;
ING pineapple_reg;

//supply
logic dram_complete;


ING black_tea_supply;
ING green_tea_supply;
ING milk_supply;
ING pineapple_supply;

logic black_tea_supply_of;
logic green_tea_supply_of;
logic milk_supply_of;
logic pineapple_supply_of;


ING dram_black_tea_save;
ING dram_green_tea_save;
ING dram_milk_save;
ING dram_pineapple_save;
Month dram_month_save;
Day dram_day_save;


Bev_Bal dram_material;


Month month_update;
Day day_update;

ING black_tea_make;
ING green_tea_make;
ING milk_make;
ING pineapple_make;
logic black_tea_make_of;
logic green_tea_make_of;
logic milk_make_of;
logic pineapple_make_of;

Error_Msg err_msg_save;
logic complete_save;
Error_Msg err_msg_make;
logic complete_make;
Error_Msg err_msg_supply;
logic complete_supply;
Error_Msg err_msg_check;
logic complete_check;

// REGISTERS
state_t state, nstate;
state_m make_state, make_nstate;
state_s supply_state, supply_nstate;
state_c check_state, check_nstate;

logic out_ready;

// STATE MACHINE
always_ff @( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else state <= nstate;
end

always_comb begin : TOP_FSM_COMB
    case(state)
        IDLE: begin
            if (inf.sel_action_valid)
            begin
                case(inf.D.d_act[0])
                    Make_drink: nstate = MAKE_DRINK;
                    Supply: nstate = SUPPLY;
                    Check_Valid_Date: nstate = CHECK_DATE;
                    default: nstate = IDLE;
                endcase
            end
            else
            begin
                nstate = IDLE;
            end
        end
        MAKE_DRINK : 
            if((make_state == WRITE_BACK_M && inf.C_out_valid) || (make_state == WORK_M && !complete_make))
                nstate = IDLE;
            else
                nstate = state;
        SUPPLY : 
            if(supply_state == WRITE_BACK_S && inf.C_out_valid)
                nstate = IDLE;
            else
                nstate = state;
        CHECK_DATE : 
            if(check_state == WORK_C)
                nstate = IDLE;
            else
                nstate = state;
        default: nstate = IDLE;
    endcase
end

always_comb begin
    if(nstate == IDLE && state != IDLE)
        out_ready = 'd1;
    else
        out_ready = 'd0;
end

//-------------------- make drink -------------------//
//FSM
always_ff @( posedge clk or negedge inf.rst_n) begin : MAKE_DRINK_FSM_SEQ
    if (!inf.rst_n) make_state <= IDLE_M;
    else make_state <= make_nstate;
end

always_comb begin : MAKE_DRINK_FSM_COMB
    case(make_state)
        IDLE_M: begin
            if(state == MAKE_DRINK && inf.C_out_valid)
                make_nstate = WORK_M;
            else
                make_nstate = make_state;
        end
        WORK_M : begin
            if(complete_make) 
                make_nstate = WRITE_BACK_M;
            else
                make_nstate = IDLE_M;
        end
        WRITE_BACK_M : 
            if(inf.C_out_valid)
                make_nstate = IDLE_M;
            else
                make_nstate = make_state;
        default: make_nstate = IDLE_M;
    endcase
end
//Cal need material
always_comb begin
    black_tea_need = 'd0;
    green_tea_need = 'd0;
    milk_need = 'd0;
    pineapple_need = 'd0;
    case({size_save, type_save})
        {L, Black_Tea} : black_tea_need = 'd960;
        {M, Black_Tea} : black_tea_need = 'd720;
        {S, Black_Tea} : black_tea_need = 'd480;
        {L, Milk_Tea} : begin
            black_tea_need = 'd720;
            milk_need = 'd240;
        end
        {M, Milk_Tea} : begin
            black_tea_need = 'd540;
            milk_need = 'd180;
        end
        {S, Milk_Tea} : begin
            black_tea_need = 'd360;
            milk_need = 'd120;
        end
        {L, Extra_Milk_Tea} : begin
            black_tea_need = 'd480;
            milk_need = 'd480;
        end
        {M, Extra_Milk_Tea} : begin
            black_tea_need = 'd360;
            milk_need = 'd360;
        end
        {S, Extra_Milk_Tea} : begin
            black_tea_need = 'd240;
            milk_need = 'd240;
        end
        {L, Green_Tea} : begin
            green_tea_need = 'd960;
        end
        {M, Green_Tea} : begin
            green_tea_need = 'd720;
        end
        {S, Green_Tea} : begin
            green_tea_need = 'd480;
        end
        {L, Green_Milk_Tea} : begin
            green_tea_need = 'd480;
            milk_need = 'd480;
        end
        {M, Green_Milk_Tea} : begin
            green_tea_need = 'd360;
            milk_need = 'd360;
        end
        {S, Green_Milk_Tea} : begin
            green_tea_need = 'd240;
            milk_need = 'd240;
        end
        {L, Pineapple_Juice} : begin
            pineapple_need = 'd960;
        end
        {M, Pineapple_Juice} : begin
            pineapple_need = 'd720;
        end
        {S, Pineapple_Juice} : begin
            pineapple_need = 'd480;
        end
        {L, Super_Pineapple_Tea} : begin
            pineapple_need = 'd480;
            black_tea_need = 'd480;
        end
        {M, Super_Pineapple_Tea} : begin
            pineapple_need = 'd360;
            black_tea_need = 'd360;
        end
        {S, Super_Pineapple_Tea} : begin
            pineapple_need = 'd240;
            black_tea_need = 'd240;
        end
        {L, Super_Pineapple_Milk_Tea} : begin
            black_tea_need = 'd480;
            pineapple_need = 'd240;
            milk_need = 'd240;
        end
        {M, Super_Pineapple_Milk_Tea} : begin
            black_tea_need = 'd360;
            pineapple_need = 'd180;
            milk_need = 'd180;
        end
        {S, Super_Pineapple_Milk_Tea} : begin
            black_tea_need = 'd240;
            pineapple_need = 'd120;
            milk_need = 'd120;
        end
    endcase
end
//HW sharing (make drink need & supply Ing)
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        black_tea_reg <= 'd0;
        green_tea_reg <= 'd0;
        milk_reg <= 'd0;
        pineapple_reg <= 'd0;
    end
    else if(size_comp)begin
        black_tea_reg <= ~black_tea_need + 'd1;
        green_tea_reg <= ~green_tea_need + 'd1;
        milk_reg <= ~milk_need + 'd1;
        pineapple_reg <= ~pineapple_need + 'd1;
    end
    //update
    else if(make_state == WORK_M)begin
        black_tea_reg <= black_tea_supply;
        green_tea_reg <= green_tea_supply;
        milk_reg <= milk_supply;
        pineapple_reg <= pineapple_supply;
    end
    else if(inf.box_sup_valid)begin
        black_tea_reg  <= (sup_4comp == EMPTY)     ? inf.D.d_ing[0] : black_tea_reg;
        green_tea_reg  <= (sup_4comp == FIRST)     ? inf.D.d_ing[0] : green_tea_reg;
        milk_reg       <= (sup_4comp == SECOND)    ? inf.D.d_ing[0] : milk_reg;
        pineapple_reg  <= (sup_4comp == THIRD)     ? inf.D.d_ing[0] : pineapple_reg;
    end
    else if(supply_state == WORK_S)begin
        black_tea_reg <= (black_tea_supply_of) ? 'd4095 : black_tea_supply;
        green_tea_reg <= (green_tea_supply_of) ? 'd4095 : green_tea_supply;
        milk_reg <= (milk_supply_of) ? 'd4095 : milk_supply;
        pineapple_reg <= (pineapple_supply_of) ? 'd4095 : pineapple_supply;
    end


end


//save meterial from dram
always_comb
    dram_material = {inf.C_data_r[63:40], inf.C_data_r[31:8], inf.C_data_r[35:32], inf.C_data_r[4:0]};

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        dram_black_tea_save <= 'd0;
        dram_green_tea_save <= 'd0;
        dram_milk_save <= 'd0;
        dram_pineapple_save <= 'd0;
        dram_month_save <= 'd0;
        dram_day_save <= 'd0;
    end
    else begin
        dram_black_tea_save <= (inf.C_out_valid && (make_state == IDLE_M || supply_state == IDLE_S)) ? dram_material.black_tea : dram_black_tea_save;
        dram_green_tea_save <= (inf.C_out_valid && (make_state == IDLE_M || supply_state == IDLE_S)) ? dram_material.green_tea : dram_green_tea_save;
        dram_milk_save <= (inf.C_out_valid && (make_state == IDLE_M || supply_state == IDLE_S)) ? dram_material.milk : dram_milk_save;
        dram_pineapple_save <= (inf.C_out_valid && (make_state == IDLE_M || supply_state == IDLE_S)) ? dram_material.pineapple_juice : dram_pineapple_save;
        dram_month_save <= (inf.C_out_valid && (make_state == IDLE_M || supply_state == IDLE_S)) ? dram_material.M : dram_month_save;
        dram_day_save <= (inf.C_out_valid && (make_state == IDLE_M || supply_state == IDLE_S)) ? dram_material.D : dram_day_save;
    end
end

//WORK
always_comb begin
    if((month_save > dram_month_save) || (month_save == dram_month_save && day_save > dram_day_save))begin
        err_msg_make = No_Exp;
        complete_make = 'd0;
    end
    else if(black_tea_supply_of || green_tea_supply_of || milk_supply_of || pineapple_supply_of)begin
        err_msg_make = No_Ing;
        complete_make = 'd0;
    end
    else begin
        err_msg_make = No_Err;
        complete_make = 'd1;
    end
end

always_ff @( posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        err_msg_save <= No_Err;
        complete_save <= 'd0;
    end
    else if(make_state == WORK_M)begin
        err_msg_save <= err_msg_make;
        complete_save <= complete_make;
    end
    else if(supply_state == WORK_S)begin
        err_msg_save <= err_msg_supply;
        complete_save <= complete_supply;
    end
    else if(check_state == WORK_C)begin
        err_msg_save <= err_msg_check;
        complete_save <= complete_check;
    end
end

/*share with supply
always_comb begin
    {black_tea_make_of, black_tea_make} = dram_black_tea_save - black_tea_reg;
    {green_tea_make_of, green_tea_make} = dram_green_tea_save - green_tea_reg;
    {milk_make_of, milk_make} = dram_milk_save - milk_reg;
    {pineapple_make_of, pineapple_make} = dram_pineapple_save - pineapple_reg;
end
*/

always_ff @( posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) begin
        month_update <= 'd0;
        day_update <= 'd0;
    end
    else if(make_state == WORK_M && complete_make) begin
        month_update <= dram_month_save;
        day_update <= dram_day_save;
    end
    else if(supply_state == WORK_S) begin
        month_update <= month_save;
        day_update <= day_save;
    end
end

//-------------------- supply -------------------//
always_ff @( posedge clk or negedge inf.rst_n) begin : SUPPLY_FSM_SEQ
    if (!inf.rst_n) supply_state <= IDLE_S;
    else supply_state <= supply_nstate;
end

always_comb begin : SUPPLY_FSM_COMB
    case(supply_state)
        IDLE_S: begin
            if(state == SUPPLY && (inf.C_out_valid || dram_complete) && sup_4comp == FOURTH)
                supply_nstate = WORK_S;
            else
                supply_nstate = supply_state;
        end
        WORK_S : supply_nstate = WRITE_BACK_S;
        WRITE_BACK_S : 
            if(inf.C_out_valid)
                supply_nstate = IDLE_S;
            else
                supply_nstate = supply_state;
        default: supply_nstate = IDLE_S;
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) dram_complete <= 'd0;
    else dram_complete <= (state == IDLE) ? 'd0 : (inf.C_out_valid) ? 'd1 : dram_complete;
end

//WORK
always_comb begin
    if(black_tea_supply_of || green_tea_supply_of || milk_supply_of || pineapple_supply_of)begin
        err_msg_supply = Ing_OF;
        complete_supply = 'd0;
    end
    else begin
        err_msg_supply = No_Err;
        complete_supply = 'd1;
    end
end

logic signed [12:0] black_signed;
logic signed [12:0] green_signed;
logic signed [12:0] milk_signed;
logic signed [12:0] pineapple_signed;

logic signed [12:0] dram_black_signed;
logic signed [12:0] dram_green_signed;
logic signed [12:0] dram_milk_signed;
logic signed [12:0] dram_pineapple_signed;

logic signed [12:0] black_sum;
logic signed [12:0] green_sum;
logic signed [12:0] milk_sum;
logic signed [12:0] pineapple_sum;

always_comb begin
    black_signed = {state == MAKE_DRINK & |black_tea_reg, black_tea_reg};
    green_signed = {state == MAKE_DRINK & |green_tea_reg, green_tea_reg};
    milk_signed = {state == MAKE_DRINK & |milk_reg, milk_reg};
    pineapple_signed = {state == MAKE_DRINK & |pineapple_reg, pineapple_reg};
    dram_black_signed = {1'b0, dram_black_tea_save};
    dram_green_signed = {1'b0, dram_green_tea_save};
    dram_milk_signed = {1'b0, dram_milk_save};
    dram_pineapple_signed = {1'b0, dram_pineapple_save};
end

always_comb begin
    {black_tea_supply_of, black_tea_supply} = black_sum;
    {green_tea_supply_of, green_tea_supply} = green_sum;
    {milk_supply_of, milk_supply} = milk_sum;
    {pineapple_supply_of, pineapple_supply} = pineapple_sum;
end

always_comb begin
    black_sum = dram_black_signed + black_signed;
    green_sum = dram_green_signed + green_signed;
    milk_sum = dram_milk_signed + milk_signed;
    pineapple_sum = dram_pineapple_signed + pineapple_signed;
end



//-------------------- check date -------------------//
always_ff @( posedge clk or negedge inf.rst_n) begin : CHECK_FSM_SEQ
    if (!inf.rst_n) check_state <= IDLE_C;
    else check_state <= check_nstate;
end

always_comb begin : CHECK_FSM_COMB
    case(check_state)
        IDLE_C: begin
            if(state == CHECK_DATE && inf.C_out_valid)
                check_nstate = WORK_C;
            else
                check_nstate = check_state;
        end
        WORK_C : check_nstate = IDLE_C;
        default: check_nstate = IDLE_C;
    endcase
end


//WORK
always_comb begin
    if((month_save > dram_month_save) || (month_save == dram_month_save && day_save > dram_day_save))begin
        err_msg_check = No_Exp;
        complete_check = 'd0;
    end
    else begin
        err_msg_check = No_Err;
        complete_check = 'd1;
    end
end


//-------------------- input save -------------------//
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) type_save <= 'd0;
    else type_save <= (inf.type_valid) ? inf.D.d_type[0] : type_save;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) size_save <= 'd0;
    else size_save <= (inf.size_valid) ? inf.D.d_size[0] : size_save;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) size_comp <= 'd0;
    else size_comp <= inf.size_valid;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) month_save <= 'd0;
    else month_save <= (inf.date_valid) ? inf.D.d_date[0].M : month_save;
end
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) day_save <= 'd0;
    else day_save <= (inf.date_valid) ? inf.D.d_date[0].D : day_save;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) box_no_save <= 'd0;
    else box_no_save <= (inf.box_no_valid) ? inf.D.d_box_no[0] : box_no_save;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) sup_4comp <= EMPTY;
    else sup_4comp <= sup_4comp_nxt;
end

//supply meterial
always_comb begin
    if(state == IDLE)
        sup_4comp_nxt = EMPTY;
    else if(inf.box_sup_valid)
        case(sup_4comp)
            EMPTY : sup_4comp_nxt = FIRST;
            FIRST : sup_4comp_nxt = SECOND;
            SECOND : sup_4comp_nxt = THIRD;
            THIRD : sup_4comp_nxt = FOURTH;
            default : sup_4comp_nxt = EMPTY;
        endcase
    else
        sup_4comp_nxt = sup_4comp;
end




//-------------------- output -------------------//
always_ff@( posedge clk or negedge inf.rst_n) begin : OUT_VALID
    if (!inf.rst_n) inf.out_valid <= 'd0;
    else inf.out_valid <= (out_ready) ? 'd1 : 'd0;
end

always_ff@( posedge clk or negedge inf.rst_n) begin : ERROR_MSG
    if (!inf.rst_n) inf.err_msg <= 'd0;
    else inf.err_msg <= (out_ready) ? (make_state == WORK_M) ? err_msg_make : (check_state == WORK_C) ? err_msg_check : err_msg_save : 'd0;
end

always_ff@( posedge clk or negedge inf.rst_n) begin : COMPLETE
    if (!inf.rst_n) inf.complete <= 'd0;
    else inf.complete <= (out_ready) ? (make_state == WORK_M) ? complete_make : (check_state == WORK_C) ? complete_check : complete_save : 'd0;
end


always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) inf.C_in_valid <= 'd0;
    else inf.C_in_valid <= inf.box_no_valid || (make_state == WORK_M && complete_make) || supply_state == WORK_S;
end

always_comb begin
    inf.C_addr = box_no_save;
end

always_comb begin
    inf.C_r_wb = (make_state == WRITE_BACK_M || supply_state == WRITE_BACK_S || state == IDLE) ? 'd0 : 'd1;
end

always_comb begin
    inf.C_data_w = {black_tea_reg, green_tea_reg, {4'd0, month_update}, milk_reg, pineapple_reg, {3'd0, day_update}};
end

endmodule