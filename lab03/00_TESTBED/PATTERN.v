`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
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

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

real CYCLE = `CYCLE_TIME;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;

reg dir_in;
reg [15:0] addr_check;
reg [12:0] addr_in1;
reg [15:0] addr_in2;
reg [63:0] golden;
reg [7:0] ans;
integer out_num;
integer i_addr, t, a;

//check DRAM, SD
parameter SD_p_r = "../00_TESTBED/SD_init.dat";
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
reg [63:0] DRAM_golden[0:65535];
reg [63:0] SD_golden [0:65535];

//parameter SD_final = "../00_TESTBED/SD_final_golden.dat";
//parameter DRAM_final = "../00_TESTBED/DRAM_final_golden.dat";
reg [63:0] DRAM_final_golden[0:65535];
reg [63:0] SD_final_golden [0:65535];
//SD_DRAM_check
initial $readmemh(SD_p_r, SD_golden);
initial $readmemh(DRAM_p_r, DRAM_golden);


initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");
    reset_signal_task;
    
    i_pat = 0;
    total_latency = 0;
    a = $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    final_check_task;
    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM);
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own code here
//////////////////////////////////////////////////////////////////////

/* define clock cycle */
always #(CYCLE/2.0) clk = ~clk;

/*out_data_reset_check_*/
always @ (negedge clk) begin
    if((out_valid === 'b0) && (out_data !== 8'd0))begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC MAIN-2 FAIL                                                         ");
        $display ("                                                   out_data should be reset when out_valid low                                            ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
        YOU_FAIL_task;
        $finish;
    end
end


//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
    direction = 'bx;
    addr_dram = 'dx;
    addr_sd = 'dx;

    force clk = 0;
    #CYCLE rst_n = 'b0;
    #CYCLE rst_n = 'b1;
    
    if(out_valid !== 'd0 || out_data !== 'd0 || AW_ADDR !== 'd0
    || AW_VALID  !== 'd0 || W_VALID  !== 'd0 || W_DATA  !== 'd0
    || B_READY   !== 'd0 || AR_ADDR  !== 'd0 || AR_VALID!== 'd0
    || R_READY   !== 'd0 || MOSI     !== 'd1) begin //out!==0
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC MAIN-1 FAIL                                                         ");
        $display ("                                        Output signal should be 0 after initial RESET  at %8t                                             ",$time);
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
        YOU_FAIL_task;
        $finish;
    end
	#CYCLE; release clk;

end endtask


task input_task; begin
    a = $fscanf(pat_read, "%d ", dir_in);
	a = $fscanf(pat_read, "%d ", addr_in1);
	a = $fscanf(pat_read, "%d ", addr_in2);

    t = $urandom_range(2, 4);
	repeat(t) @(negedge clk);
	in_valid = 1'b1;
	direction = dir_in;	
	addr_dram = addr_in1;
	addr_sd = addr_in2;
    if(direction === 'b0) begin
        SD_golden[addr_sd] = DRAM_golden[addr_dram];
        addr_check = addr_sd;
    end
    else begin
        DRAM_golden[addr_dram] = SD_golden[addr_sd];
        addr_check = {3'd0, addr_dram};
    end
    @(negedge clk);		
    in_valid = 1'b0;	
	direction = 'bx;	
	addr_dram = 'bx;
    addr_sd = 'bx;

    if(dir_in === 1'b0)
		golden = u_DRAM.DRAM[addr_in1];
    else
        golden = u_SD.SD[addr_in2];

end endtask 

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
    @(negedge clk);
	latency = latency + 1;
        if( latency == 10000) begin
            $display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
            $display ("                                                                 SPEC MAIN-3 FAIL                                                         ");
            $display ("                                                  The execution latency are over 10000 cycles  at %8t                                     ",$time);//over max
            $display ("------------------------------------------------------------------------------------------------------------------------------------------");
            YOU_FAIL_task;
	    $finish;
      end
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    if(out_valid === 'b1 )begin
		for(i_addr = 0; i_addr < 65536; i_addr = i_addr + 1)begin
            if(u_DRAM.DRAM[i_addr] !== DRAM_golden[i_addr] || u_SD.SD[i_addr] !== SD_golden[i_addr])begin
                $display ("------------------------------------------------------------------------------------------------------------------------------------------");
			    $display ("                                                                      FAIL!                                                               ");
                $display ("                                                                 SPEC MAIN-6 FAIL                                                         ");
			    $display ("                                                                 Address :    %d                                                   ",i_addr);
                $display ("                                                                 Golden ans :    %h    %h                                          ",DRAM_golden[i_addr], SD_golden[i_addr]); 
			    $display ("                                                                 Your ans :      %h    %h                                          ",u_DRAM.DRAM[i_addr], u_SD.SD[i_addr]);
			    $display ("------------------------------------------------------------------------------------------------------------------------------------------");
                YOU_FAIL_task;
			    $finish;		
            end
        end
    end
	out_num = 0;
	while(out_valid === 1)begin
        ans = golden[63-out_num * 8 -: 8];	
		out_num = out_num + 1;
        if(out_num > 8)
            break;
		if(out_data !== ans)begin
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
            $display ("                                                                 SPEC MAIN-5 FAIL                                                         ");
			$display ("                                                                 Golden ans :    %d                                              ",ans); 
			$display ("                                                                 Your ans :      %d                                              ",out_data);
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
            YOU_FAIL_task;
			$finish;		
		end
	    @(negedge clk);
	end
	if(out_num !== 8)begin
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                      FAIL!                                                               ");
            $display ("                                                                 SPEC MAIN-4 FAIL                                                         ");
			$display ("                                                                 Your ans amounts :     %d                                         ",out_num);
			$display ("------------------------------------------------------------------------------------------------------------------------------------------");
            YOU_FAIL_task;
			$finish;			
	end
	
end endtask


task final_check_task; begin
    //$readmemh(SD_final, SD_final_golden);
    //$readmemh(DRAM_final, DRAM_final_golden);
    for(i_addr = 0; i_addr < 65536; i_addr = i_addr + 1)begin
            if(u_DRAM.DRAM[i_addr] !== DRAM_golden[i_addr] || u_SD.SD[i_addr] !== SD_golden[i_addr])begin
                $display ("------------------------------------------------------------------------------------------------------------------------------------------");
			    $display ("                                                                      FAIL!                                                               ");
                $display ("                                                       final states of DRAM and SD card wrong                                             ");
                $display ("                                                                 Address :    %d                                                   ",i_addr);
			    $display ("                                                                 Golden ans :    %d    %d                                          ",DRAM_golden[i_addr], SD_golden[i_addr]); 
			    $display ("                                                                 Your ans :      %d    %d                                          ",u_DRAM.DRAM[i_addr], u_SD.SD[i_addr]);
			    $display ("------------------------------------------------------------------------------------------------------------------------------------------");
                YOU_FAIL_task;
			    repeat(9) @(negedge clk);
			    $finish;		
            end
        end
end endtask


//////////////////////////////////////////////////////////////////////

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles                  *", total_latency);
    $display("*                Your clock period = %.1f ns                            *", CYCLE);
    $display("*                Total Latency = %.1f ns                          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule