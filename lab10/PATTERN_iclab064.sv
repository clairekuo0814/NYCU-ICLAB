/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
`define PAT_NUM 10000
`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

typedef logic[2:0] Ratio;
typedef logic[9:0] Bev_size;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
integer i_pat = 0, t, i;
integer total_latency, latency;



//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  
Action act_save;
//Order_Info order_save;
Bev_Type type_save;
Bev_Size size_save;
Date date_save;
Barrel_No box_no_save;
ING black_tea_supply_save;
ING green_tea_supply_save;
ING milk_supply_save;
ING pineapple_supply_save;

//answer check
Error_Msg golden_err_msg;
logic golden_complete;
Bev_Bal dram;

ING black_tea_need;
ING green_tea_need;
ING milk_need;
ING pineapple_need;
ING black_tea_update;
ING green_tea_update;
ING milk_update;
ING pineapple_update;

Bev_size bev_size;
Ratio ratio_all;
Ratio ratio_black_tea;
Ratio ratio_green_tea;
Ratio ratio_milk;
Ratio ratio_pineapple;



//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

/*
class random_type;
    randc Bev_Type [2:0] bev_type;
    constraint range{
        bev_type inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
    }
endclass

class random_size;
    randc Bev_Size [2:0] bev_size;
    constraint range{
        bev_size inside{L, M, S};
    }
endclass
*/

class random_order;
    randc Order_Info bev_order;
    constraint range{
        bev_order.Bev_Type_O inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
        bev_order.Bev_Size_O inside{L, M, S};
    }
endclass

class random_date;
    randc Date date;
    constraint range{
        date.M inside{[1:12]};
        if(date.M == 2)
            date.D inside{[1:28]};
        else if(date.M <= 7)
            if(date.M % 2 == 1)
                date.D inside{[1:31]};
            else   
                date.D inside{[1:30]};
        else
            if(date.M % 2 == 1)
                date.D inside{[1:30]};
            else   
                date.D inside{[1:31]};
    }
endclass

class random_supply;
    randc ING supply;
    constraint range{
        supply inside{[0:4095]};
    }
endclass

/**
 * Class representing a random box from 0 to 31.
 */
class random_box;
    randc logic [7:0] box_id;
    constraint range{
        box_id inside{[0:255]};
    }
endclass


class random_gap;
    randc logic [1:0] gap;
    constraint range{
        gap inside{[0:3]};
    }
endclass


//================================================================
// initial
//================================================================

initial $readmemh(DRAM_p_r, golden_DRAM);


random_act act_rand = new();
//random_type type_rand = new();
//random_size size_rand = new();
random_date date_rand = new();
random_order order_rand = new();
random_box box_rand = new();
random_supply supply_rand = new();
random_gap gap_rand = new();


/*out_data_reset_check_*/
/*
always_comb begin
    if((inf.out_valid === 'b0) && ((inf.err_msg !== 'd0) ||(inf.complete !== 'd0)))begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                   out_data should be reset when out_valid low                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(9)@(negedge clk);
        $finish;
    end
end

always_comb begin
	if(inf.out_valid === 'd1 && (inf.sel_action_valid === 'd1 || inf.type_valid === 'd1 || inf.size_valid === 'd1 || inf.date_valid === 'd1 || inf.box_no_valid === 'd1 || inf.box_sup_valid === 'd1))begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                   The out_valid cannot overlap with in_valid                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		repeat(9)@(negedge clk);
		$finish;			
	end	
end
*/

initial begin
  reset_task;
    for (i_pat = 0; i_pat < `PAT_NUM; i_pat = i_pat+1)
  	  begin
  		input_task;
        take_dram_task;
        if(act_save == Make_drink)
            make_ans_cal;
        else if(act_save == Supply)
            supply_ans_cal;
        else
            check_ans_cal;
        wait_out_valid_task;
        check_ans_task;
        $display("%0sPASS PATTERN NO.%4d, %0sCycles: %3d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
      end
    YOU_PASS_task;
end

task reset_task; begin 
    inf.rst_n = 'b1;
    inf.sel_action_valid = 'b0;
    inf.type_valid = 'b0;
    inf.size_valid = 'b0;
    inf.date_valid = 'b0;
    inf.box_no_valid = 'b0;
    inf.box_sup_valid = 'b0;
    inf.D = 'b0;
    total_latency = 0;

    force clk = 0;

    #10.0; inf.rst_n = 0; 
    #10.0; inf.rst_n = 1;
    /*
    if(inf.out_valid !== 'b0 || inf.err_msg !== 'b0 || inf.complete !== 'b0) begin //out!==0
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                   FAIL!                                                            ");
        $display ("                                          Output signal should be 0 after initial RESET  at %8t                                     ",$time);
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
        repeat(2) #10.0;
        $finish;
    end*/
	#10.0;
	release clk;
	@(negedge clk);
end endtask

task input_task; begin
    gap_rand.randomize();
    t = gap_rand.gap;
	repeat(t) @(negedge clk);
    act_rand.randomize();
    inf.D.d_act[0] = act_rand.act_id;
    act_save = inf.D.d_act[0];
    inf.sel_action_valid = 'd1;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D.d_act[0] = 'dx;
    if(act_save == Make_drink)begin
        //type
        gap_rand.randomize();
        t = gap_rand.gap;
	    repeat(t) @(negedge clk);
        order_rand.randomize();
        //type_rand.randomize();
        inf.D.d_type[0] = order_rand.bev_order.Bev_Type_O;
        type_save = inf.D.d_type[0];
        inf.type_valid = 'd1;
        @(negedge clk);
        inf.type_valid = 1'b0;
        inf.D.d_type[0] = 'dx;
        //size
        gap_rand.randomize();
        t = gap_rand.gap;
	    repeat(t) @(negedge clk);
        //size_rand.randomize();
        inf.D.d_size[0] = order_rand.bev_order.Bev_Size_O;
        size_save = inf.D.d_size[0];
        inf.size_valid = 'd1;
        @(negedge clk);
        inf.size_valid = 1'b0;
        inf.D.d_size[0] = 'dx;

    end
    //date
    gap_rand.randomize();
    t = gap_rand.gap;
	repeat(t) @(negedge clk);
    date_rand.randomize();
    inf.D.d_date[0] = date_rand.date;
    date_save = inf.D.d_date[0];
    inf.date_valid = 'd1;
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D.d_date[0] = 'dx;
    //box_no
    gap_rand.randomize();
    t = gap_rand.gap;
	repeat(t) @(negedge clk);
    box_rand.randomize();
    inf.D.d_box_no[0] = box_rand.box_id;
    box_no_save = inf.D.d_box_no[0];
    inf.box_no_valid = 'd1;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D.d_box_no[0] = 'dx;
    if(act_save == Supply)begin
        //supply meterial
        //black tea
        gap_rand.randomize();
        t = gap_rand.gap;
	    repeat(t) @(negedge clk);
        supply_rand.randomize();
        inf.D.d_ing[0] = supply_rand.supply;
        black_tea_supply_save = inf.D.d_ing[0];
        inf.box_sup_valid = 'd1;
        @(negedge clk);
        inf.box_sup_valid = 1'b0;
        inf.D.d_ing[0] = 'dx;

        //green tea
        gap_rand.randomize();
        t = gap_rand.gap;
	    repeat(t) @(negedge clk);
        supply_rand.randomize();
        inf.D.d_ing[0] = supply_rand.supply;
        green_tea_supply_save = inf.D.d_ing[0];
        inf.box_sup_valid = 'd1;
        @(negedge clk);
        inf.box_sup_valid = 1'b0;
        inf.D.d_ing[0] = 'dx;

        //milk
        gap_rand.randomize();
        t = gap_rand.gap;
	    repeat(t) @(negedge clk);
        supply_rand.randomize();
        inf.D.d_ing[0] = supply_rand.supply;
        milk_supply_save = inf.D.d_ing[0];
        inf.box_sup_valid = 'd1;
        @(negedge clk);
        inf.box_sup_valid = 1'b0;
        inf.D.d_ing[0] = 'dx;

        //pineapple
        gap_rand.randomize();
        t = gap_rand.gap;
	    repeat(t) @(negedge clk);
        supply_rand.randomize();
        inf.D.d_ing[0] = supply_rand.supply;
        pineapple_supply_save = inf.D.d_ing[0];
        inf.box_sup_valid = 'd1;
        @(negedge clk);
        inf.box_sup_valid = 1'b0;
        inf.D.d_ing[0] = 'dx;
    end
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid !== 1'b1) begin
        /*
        if(((inf.err_msg !== 'd0) ||(inf.complete !== 'd0)))begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------------");
	    	$display ("                                                                      FAIL!                                                               ");
            $display ("                                                   out_data should be reset when out_valid low                                            ");
            $display ("------------------------------------------------------------------------------------------------------------------------------------------");
            repeat(9)@(negedge clk);
            $finish;
        end*/
	    latency = latency + 1;
        /*
        if( latency == 1000) begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
	        $display ("                                                                   FAIL!                                                            ");
            $display ("                                            The execution latency are over 1000 cycles  at %8t                                      ",$time);
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
	        repeat(2)@(negedge clk);
	        $finish;
        end*/
    @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask 

task take_dram_task; begin
    //take data from dram
    dram.M = {golden_DRAM[65536 + 8*box_no_save + 4][3:0]};
    dram.D = {golden_DRAM[65536 + 8*box_no_save][4:0]};
    dram.pineapple_juice = {golden_DRAM[65536 + 8*box_no_save + 2][3:0], golden_DRAM[65536 + 8*box_no_save + 1]};
    dram.milk = {golden_DRAM[65536 + 8*box_no_save + 3], golden_DRAM[65536 + 8*box_no_save + 2][7:4]};
    dram.green_tea = {golden_DRAM[65536 + 8*box_no_save + 6][3:0], golden_DRAM[65536 + 8*box_no_save + 5]};
    dram.black_tea = {golden_DRAM[65536 + 8*box_no_save + 7], golden_DRAM[65536 + 8*box_no_save + 6][7:4]};
end endtask

task make_ans_cal; begin

    //need meterial Cal
    case(size_save)
        L : bev_size = 960;
        M : bev_size = 720;
        S : bev_size = 480;
        default : bev_size = 0;
    endcase
    ratio_black_tea = 0;
    ratio_green_tea = 0;
    ratio_milk = 0;
    ratio_pineapple = 0;
    case(type_save)
        Black_Tea : begin
            ratio_black_tea = 1;
        end
        Milk_Tea : begin
            ratio_black_tea = 3;
            ratio_milk = 1;
        end
        Extra_Milk_Tea : begin
            ratio_black_tea = 1;
            ratio_milk = 1;
        end
        Green_Tea : begin
            ratio_green_tea = 1;
        end
        Green_Milk_Tea : begin
            ratio_green_tea = 1;
            ratio_milk = 1;
        end
        Pineapple_Juice : begin
            ratio_pineapple = 1;
        end
        Super_Pineapple_Tea : begin
            ratio_pineapple = 1;
            ratio_black_tea = 1;
        end
        Super_Pineapple_Milk_Tea : begin
            ratio_pineapple = 1;
            ratio_black_tea = 2;
            ratio_milk = 1;
        end
    endcase
    ratio_all = ratio_black_tea + ratio_green_tea + ratio_milk + ratio_pineapple;
    black_tea_need = bev_size * ratio_black_tea / ratio_all;
    green_tea_need = bev_size * ratio_green_tea / ratio_all;
    pineapple_need = bev_size * ratio_pineapple / ratio_all;
    milk_need = bev_size * ratio_milk / ratio_all;

    golden_err_msg = No_Err;
    if((date_save.M === dram.M && date_save.D > dram.D ) || date_save.M > dram.M)
        golden_err_msg = No_Exp;
    else if(black_tea_need > dram.black_tea || green_tea_need > dram.green_tea || pineapple_need > dram.pineapple_juice || milk_need > dram.milk)
        golden_err_msg = No_Ing;

    if(golden_err_msg == No_Err)begin
        golden_complete = 'd1;
        pineapple_update = dram.pineapple_juice - pineapple_need;
        milk_update = dram.milk - milk_need;
        green_tea_update = dram.green_tea - green_tea_need;
        black_tea_update = dram.black_tea - black_tea_need;
        {golden_DRAM[65536 + 8*box_no_save + 2][3:0], golden_DRAM[65536 + 8*box_no_save + 1]} = pineapple_update;
        {golden_DRAM[65536 + 8*box_no_save + 3], golden_DRAM[65536 + 8*box_no_save + 2][7:4]} = milk_update;
        {golden_DRAM[65536 + 8*box_no_save + 6][3:0], golden_DRAM[65536 + 8*box_no_save + 5]} = green_tea_update;
        {golden_DRAM[65536 + 8*box_no_save + 7], golden_DRAM[65536 + 8*box_no_save + 6][7:4]} = black_tea_update;
    end
    else
        golden_complete = 'd0;
    

end endtask

task supply_ans_cal; begin
    if(black_tea_supply_save + dram.black_tea > 4095 || green_tea_supply_save + dram.green_tea > 4095 || pineapple_supply_save + dram.pineapple_juice > 4095 || milk_supply_save + dram.milk > 4095)begin
        golden_err_msg = Ing_OF;
        golden_complete = 'd0;
    end
    else begin
        golden_err_msg = No_Err;
        golden_complete = 'd1;
    end

    pineapple_update = (pineapple_supply_save + dram.pineapple_juice > 4095) ? 4095 : dram.pineapple_juice + pineapple_supply_save;
    milk_update = (milk_supply_save + dram.milk > 4095) ? 4095 : dram.milk + milk_supply_save;
    green_tea_update = (green_tea_supply_save + dram.green_tea > 4095) ? 4095 : dram.green_tea + green_tea_supply_save;
    black_tea_update = (black_tea_supply_save + dram.black_tea > 4095) ? 4095 : dram.black_tea + black_tea_supply_save;
    {golden_DRAM[65536 + 8*box_no_save + 4][3:0]} = date_save.M;
    {golden_DRAM[65536 + 8*box_no_save][4:0]} = date_save.D;
    {golden_DRAM[65536 + 8*box_no_save + 2][3:0], golden_DRAM[65536 + 8*box_no_save + 1]} = pineapple_update;
    {golden_DRAM[65536 + 8*box_no_save + 3], golden_DRAM[65536 + 8*box_no_save + 2][7:4]} = milk_update;
    {golden_DRAM[65536 + 8*box_no_save + 6][3:0], golden_DRAM[65536 + 8*box_no_save + 5]} = green_tea_update;
    {golden_DRAM[65536 + 8*box_no_save + 7], golden_DRAM[65536 + 8*box_no_save + 6][7:4]} = black_tea_update;

end endtask

task check_ans_cal; begin
    if((date_save.M === dram.M && date_save.D > dram.D ) || date_save.M > dram.M)begin
        golden_err_msg = No_Exp;
        golden_complete = 'd0;
    end
    else begin
        golden_err_msg = No_Err;
        golden_complete = 'd1;
    end

end endtask


task check_ans_task; begin
    if(inf.err_msg !== golden_err_msg || inf.complete !== golden_complete)begin
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                               Wrong Answer!                                                               ");
	    $display ("                                                                   FAIL!                                                               ");
	    $display ("                                                              Golden ans :    %d  %d                                           ",golden_err_msg, golden_complete); 
	    $display ("                                                              Your ans :      %d  %d                                              ",inf.err_msg, inf.complete);
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
	    //repeat(9)@(negedge clk);
        $finish;		
	end
    @(negedge clk);
    /*
    if(inf.out_valid == 1)begin
        $display ("-----------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                  FAIL!                                                            ");
        $display ("                                             output signal must be delivered for only one cycle                                    ");
		$display ("-----------------------------------------------------------------------------------------------------------------------------------");
		//repeat(9)@(negedge clk);
        $finish;
    end
    */
end endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*************************************************************************");
    $finish;
end endtask


endprogram
