/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/


class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

BEV bev_info = new();

always_ff @(posedge clk) begin
    if (inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0];
    end
end

always_ff @(posedge clk) begin
    if (inf.size_valid) begin
        bev_info.bev_size = inf.D.d_size[0];
    end
end

/*
Error_Msg err_info;
always_ff @(posedge clk) begin
    if (inf.out_valid) begin
        err_info = inf.err_msg;
    end
end*/

Action sel_action;
always_ff @(posedge clk) begin
    if (inf.sel_action_valid) begin
        sel_action = inf.D.d_act[0];
    end
end

ING sup_ing;
always_ff @(posedge clk) begin
    if (inf.box_sup_valid) begin
        sup_ing = inf.D.d_ing[0];
    end
end


/*
1. Each case of Beverage_Type should be select at least 100 times.
*/


covergroup Spec1 @(negedge clk iff inf.type_valid);
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup


/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/

covergroup Spec2 @(negedge clk iff inf.size_valid);
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_size{
        bins b_bev_size [] = {[L:S]};
    }
endgroup

/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/

covergroup Spec3 @(negedge clk iff inf.size_valid);
    option.per_instance = 1;
    option.at_least = 100;
    cross bev_info.bev_type, bev_info.bev_size;
endgroup

/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(negedge clk iff inf.out_valid);/*No_Err wrong*/
    option.per_instance = 1;
    option.at_least = 20;
    btype:coverpoint inf.err_msg{
        bins b_err_info[] = {[No_Err:Ing_OF]};
    }
endgroup

/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/
covergroup Spec5 @(negedge clk iff inf.sel_action_valid);
    option.per_instance = 1;
    option.at_least = 200;
    btype:coverpoint sel_action{
        bins b_sel_action[] = ([Make_drink:Check_Valid_Date] => [Make_drink:Check_Valid_Date]);
    }
endgroup

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/
covergroup Spec6 @(negedge clk iff inf.box_sup_valid);
    option.per_instance = 1;
    option.at_least = 1;
    btype:coverpoint sup_ing{
        option.auto_bin_max = 32;
    }
endgroup


/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
// Spec1_2_3 cov_inst_1_2_3 = new();
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();
Spec6 cov_inst_6 = new();

/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/
logic [2:0] sup_valid_flag;
always @(negedge clk)begin
    if(inf.sel_action_valid)
        sup_valid_flag = 'd0;
    else if(inf.box_sup_valid)
        sup_valid_flag = {sup_valid_flag[1:0], 1'b1};
end
/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/

always @(negedge inf.rst_n)begin
    #1;
    SPEC_1 : assert (inf.out_valid === 'b0 && inf.err_msg === 'b0 && inf.complete === 'b0 &&
                     inf.C_addr === 'b0 && inf.C_data_w === 'b0 && inf.C_in_valid === 'b0 && inf.C_r_wb === 'b0 && //BEV.sv
                     inf.C_out_valid === 'b0 && inf.C_data_r === 'b0 && inf.AR_VALID === 'b0 && inf.AR_ADDR === 'b0 && inf.R_READY === 'b0 &&
                     inf.AW_VALID === 'b0 && inf.AW_ADDR === 'b0 && inf.W_VALID === 'b0 && inf.W_DATA === 'b0 && inf.B_READY === 'b0 //bridge.sv
		            )
        else begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
		    $display ("                                                 Assertion 1 is violated                                                            ");
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
            $fatal;
    end
end

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/

SPEC_2 :assert property ( @(posedge clk) ( ((inf.box_no_valid && (sel_action == Make_drink || sel_action == Check_Valid_Date)) || (&sup_valid_flag && sel_action == Supply && inf.box_sup_valid)) |-> ( ##[1:999] inf.out_valid===1 ) ) )
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 2 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end


/*
    3. If out_valid does not pull up, complete should be 0.
*/

SPEC_3 :assert property ( @(negedge clk) ( (inf.complete === 1'b1) |-> ( inf.err_msg === No_Err ) ) )
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 3 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end

/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/
/*
property assert_4;
    @(posedge clk) 
        (   ( (inf.sel_action === 1'b1)     |-> (##[1:4] (inf.type_valid === 1'b1 || inf.date_valid === 1'b1    ) ) ) &&
            ( (inf.type_valid === 1'b1)     |-> (##[1:4] (inf.size_valid === 1'b1                               ) ) ) &&
            ( (inf.size_valid === 1'b1)     |-> (##[1:4] (inf.date_valid === 1'b1                               ) ) ) &&
            ( (inf.date_valid === 1'b1)     |-> (##[1:4] (inf.box_no_valid === 1'b1                             ) ) ) &&
            ( (inf.box_no_valid === 1'b1 && sel_action == Supply)   |-> (##[1:4] (inf.box_sup_valid === 1'b1    ) ) ) &&
            ( (inf.box_sup_valid === 1'b1 && &sup_valid_flag !==1)   |-> (##[1:4] (inf.box_sup_valid === 1'b1    ) ) ) );
endproperty : assert_4*/

SPEC_4_type :assert property (@(posedge clk) (( (inf.sel_action_valid === 1'b1 && inf.D.d_act[0] == Make_drink) |-> (##[1:4] (inf.type_valid === 1'b1) ) )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 4 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end
SPEC_4_size :assert property (@(posedge clk) (( (inf.type_valid === 1'b1) |-> (##[1:4] (inf.size_valid === 1'b1) ) )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 4 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end
SPEC_4_date :assert property (@(posedge clk) (( ((inf.size_valid === 1'b1) || (inf.sel_action_valid === 1'b1 && inf.D.d_act[0] !== Make_drink)) |-> (##[1:4] (inf.date_valid === 1'b1) ) )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 4 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end
SPEC_4_box_no :assert property (@(posedge clk) (( (inf.date_valid === 1'b1)  |-> (##[1:4] (inf.box_no_valid === 1'b1) ) )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 4 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end
    
SPEC_4_box_sup :assert property (@(posedge clk) (( ((inf.box_no_valid === 1'b1 && sel_action == Supply) || (inf.box_sup_valid === 1'b1 && (&sup_valid_flag === 'b0)))  |-> (##[1:4] (inf.box_sup_valid === 1'b1) ) )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 4 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end


/*
    5. All input valid signals won't overlap with each other. 
*/
logic no_in_valid;
always_comb
    no_in_valid = ~(inf.sel_action_valid || inf.type_valid || inf.size_valid || inf.date_valid || inf.box_no_valid || inf.box_sup_valid);

SPEC_5 :assert property ( @(posedge clk)  $onehot({ inf.sel_action_valid, inf.type_valid, inf.size_valid, inf.date_valid, inf.box_no_valid, inf.box_sup_valid , no_in_valid}) )  
    else begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$display ("                                                 Assertion 5 is violated                                                            ");
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$fatal; 
    end
/*
    6. Out_valid can only be high for exactly one cycle.
*/

SPEC_6 :assert property ( @(posedge clk)  (( (inf.out_valid === 1'b1)  |=> (inf.out_valid === 1'b0) )))  
    else begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$display ("                                                 Assertion 6 is violated                                                            ");
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$fatal; 
    end

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/
SPEC_7 :assert property (@(posedge clk) (( (inf.out_valid === 1'b1)  |-> (##[1:4] (inf.sel_action_valid === 1'b1) ) )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 7 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/
SPEC_8 :assert property (@(posedge clk) (( (inf.date_valid === 1'b1) |-> (
                                           (inf.D.d_date[0].M === 'd2 && inf.D.d_date[0].D <= 28 && inf.D.d_date[0].D > 0) ||   //2
                                           (inf.D.d_date[0].M > 'd0 && inf.D.d_date[0].M <= 'd7 && inf.D.d_date[0].M%2 === 1 && inf.D.d_date[0].D <= 31 && inf.D.d_date[0].D > 0) ||    //1,3,5,7
                                           (inf.D.d_date[0].M > 'd0 && inf.D.d_date[0].M <= 'd7 && inf.D.d_date[0].M !== 'd2 && inf.D.d_date[0].M%2 === 0 && inf.D.d_date[0].D <= 30 && inf.D.d_date[0].D > 0) ||    //4,6
                                           (inf.D.d_date[0].M > 'd7 && inf.D.d_date[0].M <= 'd12 && inf.D.d_date[0].M%2 === 1 && inf.D.d_date[0].D <= 30 && inf.D.d_date[0].D > 0) ||   //9,11
                                           (inf.D.d_date[0].M > 'd7 && inf.D.d_date[0].M <= 'd12 && inf.D.d_date[0].M%2 === 0 && inf.D.d_date[0].D <= 31 && inf.D.d_date[0].D > 0))     //8,10,12
                                        )))
    else begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$display ("                                                 Assertion 8 is violated                                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
     	$fatal; 
    end


/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/

logic still_work;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        still_work = 'd0;
    else if(inf.C_in_valid)
        still_work = 'd1;
    else if(inf.C_out_valid)
        still_work = 'd0;
end

SPEC_9_1 :assert property ( @(negedge clk)  (( (inf.C_in_valid === 1'b1)  |=> (inf.C_in_valid === 1'b0) ) ))  
    else begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$display ("                                                 Assertion 9 is violated                                                            ");
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$fatal; 
    end

SPEC_9_2 :assert property ( @(negedge clk)  (( (inf.C_in_valid === 1'b1)  |-> (still_work === 'd0) ) ))  
    else begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$display ("                                                 Assertion 9 is violated                                                            ");
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
         	$fatal; 
    end

endmodule
