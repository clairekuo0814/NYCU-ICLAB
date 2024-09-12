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

Action act;
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(inf.sel_action_valid) 
    begin
		act = inf.D.d_act[0];
    end
end

logic [1:0] cnt_4;
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        cnt_4 <= 0;
    end

    else if(inf.box_sup_valid)
    begin
        cnt_4 <= cnt_4 + 1;
    end
end


/*
1. Each case of Beverage_Type should be select at least 100 times.
*/

covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup

/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/

covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
    bsize:coverpoint bev_info.bev_size{
        bins b_bev_size [] = {S,M,L};
    }
endgroup

/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/

covergroup Spec3 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
    coverpoint bev_info.bev_type;
    coverpoint bev_info.bev_size;
    cross bev_info.bev_type, bev_info.bev_size;
endgroup

/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 20;
    berrmsg:coverpoint inf.err_msg{
        bins b_err_msg [] = {[No_Err:Ing_OF]};
    }
endgroup

/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/

covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least = 200;
    bselact:coverpoint inf.D.d_act[0]{
        bins b_sel_act [] = ([Make_drink:Check_Valid_Date] => [Make_drink:Check_Valid_Date]);
    }
endgroup

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/

covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1;
    option.at_least = 1;
    bskeufhui:coverpoint inf.D.d_ing[0]{
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

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/

wire #(0.5) rst_reg = inf.rst_n;
assert_reset : assert property ( @(negedge rst_reg) (inf.out_valid==='d0 && inf.complete==='d0 && inf.err_msg==='d0 && 
														inf.C_addr==='d0 && inf.C_data_w==='d0 && inf.C_in_valid==='d0 && inf.C_r_wb==='d0 &&
														inf.C_out_valid==='d0 && inf.C_data_r==='d0 && inf.AR_VALID==='d0 && inf.AR_ADDR==='d0 && 
														inf.R_READY==='d0 && inf.AW_VALID==='d0 && inf.AW_ADDR==='d0 && inf.W_VALID==='d0 &&inf.W_DATA==='d0 && inf.B_READY==='d0))
else begin
        $display("************************************************************");  
        $display("                Assertion 1 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/

assert_latency : assert property(op_latency)
else
begin
        $display("************************************************************");  
        $display("                Assertion 2 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

property op_latency;
	@(posedge clk) (make_n_check_valid_latency or supply_latency);
endproperty

property make_n_check_valid_latency;
	@(posedge clk)	(inf.box_no_valid && (act === Make_drink || act === Check_Valid_Date )) |-> (##[1:1000] inf.out_valid);
endproperty:make_n_check_valid_latency

property supply_latency;
    @(posedge clk) (inf.box_sup_valid && cnt_4==3 && act === Supply) |-> (##[1:1000] inf.out_valid);
endproperty
/*
    3. If action is completed (complete=1), err_msg should be 2’b0 (no_err)
*/
assert_complete_errmsg : assert property( @(negedge clk)( inf.out_valid == 1 &&inf.complete == 1) |-> inf.err_msg == 2'd0)
else
begin
        $display("************************************************************");  
        $display("                Assertion 3 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end


/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/
assert_selact_type : assert property (@(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Make_drink) |-> ##[1:4](inf.type_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_type_size : assert property (@(posedge clk) (inf.type_valid && act === Make_drink) |-> ##[1:4](inf.size_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_size_date : assert property (@(posedge clk) (inf.size_valid && act === Make_drink) |-> ##[1:4](inf.date_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_date_no : assert property (@(posedge clk) (inf.date_valid && act === Make_drink) |-> ##[1:4](inf.box_no_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_supply_selact_date : assert property (@(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Supply) |-> ##[1:4](inf.date_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_supply_date_no : assert property (@(posedge clk) (inf.date_valid && act === Supply) |-> ##[1:4](inf.box_no_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_supply_no_sup : assert property (@(posedge clk) (inf.box_no_valid && act === Supply) |-> ##[1:4](inf.box_sup_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_supply_sup_sup : assert property (@(posedge clk) (inf.box_sup_valid && act === Supply && cnt_4 < 3) |-> ##[1:4](inf.box_sup_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_check_selact_date : assert property (@(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Check_Valid_Date) |-> ##[1:4](inf.date_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

assert_check_date_no : assert property (@(posedge clk) (inf.date_valid && act === Check_Valid_Date) |-> ##[1:4](inf.box_no_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 4 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

/*
    5. All input valid signals won't overlap with each other. 
*/
logic [2:0] overlap;
assign overlap = inf.sel_action_valid + inf.type_valid + inf.size_valid + inf.date_valid + inf.box_no_valid + inf.box_sup_valid;
assert_check_overlap : assert property (@(posedge clk) (overlap<= 1))
else
begin
        $display("************************************************************");  
        $display("                Assertion 5 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

/*
    6. Out_valid can only be high for exactly one cycle.
*/
assert_outvalid_one : assert property ( @(posedge clk)  (inf.out_valid===1) |-> ##1 (inf.out_valid===0) )
else
begin
        $display("************************************************************");  
        $display("                Assertion 6 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end
/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/

assert_out_in : assert property (@(posedge clk) (inf.out_valid ) |-> ##[1:4](inf.sel_action_valid))
else
begin
        $display("************************************************************");  
        $display("                Assertion 7 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/

assert_check_date : assert property ((check_date))
else
begin
        $display("************************************************************");  
        $display("                Assertion 8 is violated                     ");    
        $display("************************************************************");
        // $display(inf.D.d_date[0].M);
        // $display(inf.D.d_date[0].D);
	    $fatal; 
end

property check_date;
    @(negedge clk)  (Jan or Feb or Mar or Apr or May or Jun or July or Aug or Sep or Oct or Nov or Dec);
endproperty

property Jan;
    @(negedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M == 1 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty

property Feb;
    @(negedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M == 2 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 28));
endproperty

property Mar;
    @(negedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M == 3 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty

property Apr;
    @(negedge clk) (inf.date_valid) |->(inf.D.d_date[0].M == 4 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 30));
endproperty

property May;
    @(negedge clk) (inf.date_valid) |->(inf.D.d_date[0].M == 5 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty

property Jun;
    @(negedge clk) (inf.date_valid) |->(inf.D.d_date[0].M == 6 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 30));
endproperty

property July;
    @(negedge clk) (inf.date_valid) |->(inf.D.d_date[0].M == 7 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty

property Aug;
    @(negedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M == 8 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty

property Sep;
    @(negedge clk) (inf.date_valid) |->(inf.D.d_date[0].M == 9 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 30));
endproperty

property Oct;
    @(negedge clk) (inf.date_valid) |->(inf.D.d_date[0].M == 10 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty

property Nov;
    @(negedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M == 11 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 30));
endproperty

property Dec;
    @(negedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M == 12 and (inf.D.d_date[0].D >= 1 and inf.D.d_date[0].D <= 31));
endproperty
/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/

assert_C_in_valid_one : assert property ( @(negedge clk)  (inf.C_in_valid===1) |-> ##1 (inf.C_in_valid===0) )
else
begin
        $display("************************************************************");  
        $display("                Assertion 9 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

logic no_pull_up;
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) no_pull_up <= 0;
    else if (inf.C_out_valid) no_pull_up <= 0;
    else if (inf.C_in_valid) no_pull_up <= 1;
end

assert_check_in_out_valid : assert property (check_in_out_valid_rise)
else
begin
        $display("************************************************************");  
        $display("                Assertion 9 is violated                     ");    
        $display("************************************************************");
	    $fatal; 
end

property check_in_out_valid_rise;
    @(negedge clk) (no_pull_up) |-> (inf.C_in_valid === 0);
endproperty


endmodule
