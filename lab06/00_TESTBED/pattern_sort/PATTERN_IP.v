`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

`define PAT_NUM 1000

module PATTERN #(parameter IP_WIDTH = 8)(
    //Output Port
    IN_character,
	IN_weight,
    //Input Port
	OUT_character
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_character;
output reg [IP_WIDTH*5-1:0] IN_weight;

input [IP_WIDTH*4-1:0] OUT_character;

// ========================================
// Parameter
// ========================================
reg [IP_WIDTH*4-1:0] char;
reg [IP_WIDTH*5-1:0] weight;
reg [IP_WIDTH*4-1:0] golden_out;
integer pat_read, out_read;
integer i_pat, i, j, a, t;

`define CYCLE_TIME 20.0

//================================================================
// design
//================================================================
reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

initial begin
    pat_read = $fopen("../00_TESTBED/width_3/input_sort.txt", "r");
    out_read = $fopen("../00_TESTBED/width_3/output_sort.txt", "r");
    i_pat = 0;
    for (i_pat = 1; i_pat <= `PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        repeat(1) @(negedge clk);
        check_ans_task;
        $display("PASS PATTERN NO.%4d", i_pat);
		repeat($urandom_range(3, 5)) @(negedge clk);
    end
    $fclose(pat_read);
    $fclose(out_read);
    YOU_PASS_task;
end


task input_task; begin
    for(integer i=0; i < IP_WIDTH; i = i+1)begin
        a = $fscanf(pat_read, "%h",char[IP_WIDTH * 4 - i*4 - 1 -: 4]);
        a = $fscanf(pat_read, "%h",weight[IP_WIDTH * 5 - i*5 - 1 -: 5]);
    end
    IN_character = char;
    IN_weight = weight;
end endtask

task check_ans_task; begin
    for(i=0; i < IP_WIDTH; i++)begin
        a = $fscanf(out_read, "%h",golden_out[IP_WIDTH * 4 - i*4 - 1 -: 4]);
	end
    if(OUT_character !== golden_out)begin
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
	    $display ("                                                                   FAIL!                                                               ");
        $display ("                                                                 %d th output                                           ",i_pat);
	    $display ("                                                              Golden ans :    %h                                           ",golden_out); 
	    $display ("                                                              Your ans :      %h                                              ",OUT_character);
	    $display ("------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;	
    end
end endtask

task YOU_PASS_task; begin
    $display ("----------------------------------------------------------------------------------------------------------------------");
    $display ("                                                  Congratulations!                                                                       ");
    $display ("                                           You have passed all patterns!                                                                 ");
    $display ("----------------------------------------------------------------------------------------------------------------------");     
    $finish;
end endtask


endmodule