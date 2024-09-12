`ifdef RTL
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
	`define CYCLE_TIME_clk3 20.7
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 3.9
	`define CYCLE_TIME_clk3 20.7
`endif

`define PAT_NUM 1000
module PATTERN(
	clk1,
	clk2,
	clk3,
	rst_n,
	in_valid,
	seed,
	out_valid,
	rand_num
);

output reg clk1, clk2, clk3;
output reg rst_n;
output reg in_valid;
output reg [31:0] seed;

input out_valid;
input [31:0] rand_num;


//================================================================
// parameters & integer
//================================================================
real	CYCLE_clk1 = `CYCLE_TIME_clk1;
real	CYCLE_clk2 = `CYCLE_TIME_clk2;
real	CYCLE_clk3 = `CYCLE_TIME_clk3;
integer total_latency;


integer latency;
integer i, i_pat, a, t;
real CYCLE1 = `CYCLE_TIME_clk1;
real CYCLE2 = `CYCLE_TIME_clk2;
real CYCLE3 = `CYCLE_TIME_clk3;
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
integer   SEED = 562;
integer out_num;
reg [31:0] golden;
//================================================================
// wire & registers 
//================================================================


//================================================================
// clock
//================================================================
/* define clock cycle */
always #(CYCLE1/2.0) clk1 = ~clk1;
always #(CYCLE2/2.0) clk2 = ~clk2;
always #(CYCLE3/2.0) clk3 = ~clk3;


//================================================================
// initial
//================================================================
/*out_data_reset_check_*/
always @ (negedge clk3) begin
    if((out_valid === 'b0) && (rand_num !== 'd0))begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                   out_data should be reset when out_valid low                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
        repeat(9)@(negedge clk3);
        $finish;
    end
end

always@(*)begin
	if(in_valid && out_valid)begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                   The out_valid cannot overlap with in_valid                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		repeat(9)@(negedge clk3);
		$finish;			
	end	
end


initial begin

  reset_task;
    for (i_pat = 0; i_pat < `PAT_NUM; i_pat = i_pat+1)
  	  begin
  		input_task;
        //wait_out_valid_task;
        check_ans_task;
        $display("%0sPASS PATTERN NO.%4d, %0sCycles: %3d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
		total_latency = total_latency + latency;
      end
    YOU_PASS_task;
end



//================================================================
// task
//================================================================

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    seed = 'bx;
    total_latency = 0;

    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;

    #CYCLE3; rst_n = 0; 
    #CYCLE3; rst_n = 1;
    
    if(out_valid !== 1'b0 || rand_num !== 'b0) begin //out!==0
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                   FAIL!                                                            ");
        $display ("                                          Output signal should be 0 after initial RESET  at %8t                                     ",$time);
        $display ("------------------------------------------------------------------------------------------------------------------------------------");
        repeat(2) #CYCLE3;
        $finish;
    end
	#CYCLE3;
	#CYCLE1;
	#CYCLE2;
	release clk1;
	release clk2;
	release clk3;
	@(negedge clk1);
end endtask


task input_task; begin
    t = $urandom_range(0, 2);
	repeat(t) @(negedge clk1);

    in_valid = 1'b1;
    seed = $urandom(SEED);
	//seed = 'h8081a201;
    golden = seed;
    @(negedge clk1);
    in_valid = 1'b0;	
	seed = 'bx;
end endtask 

task check_ans_task; begin
	out_num = 0;
    latency = 0;
	while(out_num < 256)begin
		@(negedge clk3)
		latency = latency + 1;
		if(out_valid === 1'b1)begin
			golden = golden ^ (golden << 13);
			golden = golden ^ (golden >> 17);
			golden = golden ^ (golden << 5);
    		if(rand_num !== golden)begin
			    $display ("------------------------------------------------------------------------------------------------------------------------------------");
			    $display ("                                                                   FAIL!                                                               ");
			    $display ("                                                                  %5d th random_num                                            ",out_num); 
			    $display ("                                                              Golden ans :    %8h                                           ",golden); 
			    $display ("                                                              Your ans :      %8h                                              ",rand_num);
			    $display ("------------------------------------------------------------------------------------------------------------------------------------");
			    repeat(9)@(negedge clk3);
    		    $finish;		
			end
			out_num = out_num + 1;
		end
        if( latency == 2000) begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
	        $display ("                                                                   FAIL!                                                            ");
            $display ("                                            The execution latency are over 2000 cycles  at %8t                                      ",$time);
            $display ("------------------------------------------------------------------------------------------------------------------------------------");
	        repeat(2)@(negedge clk3);
	        $finish;
        end
	end
	@(negedge clk3)
	if(out_valid === 1'b1)begin
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
	    $display ("                                                                   FAIL!                                                               ");
	    $display ("                                                       output should only 256 cycles                                            "); 
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
	    repeat(9)@(negedge clk3);
        $finish;		
	end
			
end endtask


task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE_clk3);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE_clk3);
    $display("*************************************************************************");
    $finish;
end endtask


endmodule
