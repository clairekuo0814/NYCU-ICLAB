`ifdef RTL
    `define CYCLE_TIME 4.5
`endif
`ifdef GATE
    `define CYCLE_TIME 4.5
`endif


module PATTERN(
           // Output signals
           clk,
           rst_n,
           in_valid,
           in_weight,
           out_mode,
           // Input signals
           out_valid,
           out_code
       );

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid, out_mode;
output reg [2:0] in_weight;

input out_valid, out_code;



real CYCLE = `CYCLE_TIME;
always #(CYCLE/2) clk = ~clk;


reg[2:0]input_data;
reg mod;
integer i,t,j,long;
integer pat_read,pat_out;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;
reg out_ans;

initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    pat_out  = $fopen("../00_TESTBED/Output.txt", "r");
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",i_pat ,latency);
        #(CYCLE);

    end
    $fclose(pat_read);
    $fclose(pat_out);
    YOU_PASS_task;
end


//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
task reset_signal_task;
    begin
        rst_n = 'b1;
        in_valid = 'b0;
        latency=0;
        i=0;
        force clk = 0;
        out_ans=0;
        #CYCLE;
        rst_n = 0;
        #CYCLE;
        rst_n = 1;

        if(out_valid !== 1'b0 ||out_code!==1'b0) begin //out!==0
            $display("************************************************************");
            $display("             you should reset output signal                 ");
            $display("************************************************************");
            repeat(2) #CYCLE;
            $finish;
        end
        #(CYCLE);
        release clk;
    end
endtask
always @(negedge clk) begin
    if(out_valid === 1'b0&&out_code !== 1'b0) begin
        $display("************************************************************");
        $display("     out_code should be zero when out_valid is zero         ");
        $display("************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end

task input_task;
    begin
        $fscanf(pat_read, "%d", mod);
        $fscanf(pat_read, "%d", input_data);
        t = $urandom_range(2, 4);
        repeat(t) @(negedge clk);
        in_valid=1;
        out_mode=mod;
        in_weight=input_data;
        @(negedge clk);
        out_mode='bx;
        for(i=0;i<7;i=i+1) begin
            $fscanf(pat_read, "%d", input_data);
            in_weight=input_data;
            @(negedge clk);
        end
        in_weight='bx;
        in_valid=0;
    end
endtask

task wait_out_valid_task;
    begin
        latency = 0;
        while(out_valid !== 1'b1) begin
            latency = latency + 1;
            if( latency == 1000) begin
                $display("********************************************************");
                $display("*  The execution latency are over 1000 cycles  at %8t  *",$time);//over max
                $display("********************************************************");

                $finish;
            end
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end
endtask

task check_ans_task;
    begin
        $fscanf(pat_out, "%d", long);
        for(j=0;j<long;j=j+1) begin
            $fscanf(pat_out, "%b", out_ans);
            if(out_code!==out_ans) begin
                you_fail_task;
            end
            @(negedge clk);
        end
    end
endtask




//////////////////////////////////////////////////////////////////////
task YOU_PASS_task;
    begin
        $display ("----------------------------------------------------------------------------------------------------------------------");
        $display ("                                                  Congratulations!                                                                       ");
        $display ("                                           You have passed all patterns!                                                                 ");
        $display ("                                           Your execution cycles = %5d cycles                                                            ", total_latency);
        $display ("                                           Your clock period = %.1f ns                                                               ", CYCLE);
        $display ("                                           Total Latency = %.1f ns                                                               ", total_latency*CYCLE);
        $display ("----------------------------------------------------------------------------------------------------------------------");
        repeat(2)@(negedge clk);
        $finish;
    end
endtask


task FAIL_MAIN4;
    begin
        $display("************************************************************");
        $display("                         SPEC MAIN-4 FAIL                   ");
        $display("************************************************************");

        $finish;
    end
endtask

task FAIL_MAIN5;
    begin
        repeat(3) #CYCLE;
        $display("************************************************************");
        $display("                         SPEC MAIN-5 FAIL                   ");
        $display("************************************************************");
        $finish;
    end
endtask

task you_fail_task;
    begin

        $display("************************************************************");
        $display("                         out is not correct                 ");
        $display("************************************************************");

        $finish;
    end
endtask

endmodule

