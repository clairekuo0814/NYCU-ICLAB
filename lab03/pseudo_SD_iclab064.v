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
//   File Name   : pseudo_SD.v
//   Module Name : pseudo_SD
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_SD (
    clk,
    MOSI,
    MISO
);

input clk;
input MOSI;
output reg MISO;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";

reg [63:0] SD [0:65535];
initial $readmemh(SD_p_r, SD);


//////////////////////////////////////////////////////////////////////
// Write your Code here
//////////////////////////////////////////////////////////////////////
//command
reg com_start, transmission;
reg [5:0] command;
reg [31:0] addr;
reg [6:0] CRC7_addr;
reg end_bit;
reg [47:0] command_all;
//data
reg [7:0] data_start;
reg [63:0] data;
reg [15:0] CRC16_data;
reg [87:0] data_all;


integer i, t;



initial begin
    //output
    MISO = 1;
    //reg
    {com_start, transmission, command, addr, CRC7_addr, end_bit} = {48{1'b1}};
    {data_start, data, CRC16_data} = {88{1'b1}};
end

initial begin
    while(1) begin
        receive_command_task;
        command_format_check_task;
        address_check_task;
        CRC7_check_task;
        wait_0_8_task;
        response_task;
        if(command == 6'd24)begin
            transmission_time_check_task;
            receive_data_task;
            CRC16_check_task;
            write_response_task;
        end else begin
            wait_1_32_task;
            transfer_data_task;
        end
        clear_reg_task;
    end
end


//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

//common
task receive_command_task; begin
    while({com_start, transmission} !== 2'b01)begin
        @(posedge clk);
        command_all = {com_start, transmission, command, addr, CRC7_addr, end_bit};
        {com_start, transmission, command, addr, CRC7_addr, end_bit} = {command_all[46:0], MOSI};
    end
end endtask


task wait_0_8_task; begin
    t = $urandom_range(0, 8) * 8 ;
	repeat(t) @(posedge clk);
end endtask

task response_task; begin
    MISO = 1'b0;
	repeat(8) @(posedge clk);
    MISO = 1'b1;
end endtask


//SD write
task receive_data_task; begin
    data_all = {data_start, data, CRC16_data};
    {data_start, data, CRC16_data} = {data_all[86:0], MOSI};
    while(data_start !== 8'hFE)begin
        @(posedge clk);
        data_all = {data_start, data, CRC16_data};
        {data_start, data, CRC16_data} = {data_all[86:0], MOSI};
    end
end endtask

task write_response_task; begin
    //@(posedge clk);
    MISO = 1'b0;
    repeat(5) @(posedge clk);
    MISO = 1'b1;
    @(posedge clk);
    MISO = 1'b0;
    @(posedge clk);
    MISO = 1'b1;
    @(posedge clk);
    MISO = 1'b0;
    t = $urandom_range(0, 32) * 8;
	repeat(t) @(posedge clk);
    SD[addr] = data;
    MISO = 1'b1;
end endtask

//SD read
task wait_1_32_task; begin
    t = $urandom_range(1, 32) * 8;
	repeat(t) @(posedge clk);
end endtask

task transfer_data_task; begin
    
    {data_start, data, CRC16_data} = {8'hFE, SD[addr], CRC16_CCITT(SD[addr])};//{data_start, data, CRC16}
    data_all = {data_start, data, CRC16_data};
    MISO =  data_all[87];
    data_all = data_all << 1;
    for(i=0; i < 88; i = i + 1)begin
        @(posedge clk);
        MISO =  data_all[87];
        data_all = data_all << 1;
    end
end endtask

task clear_reg_task; begin
    MISO = 1;
    {com_start, transmission, command, addr, CRC7_addr, end_bit} = {48{1'b1}};
    {data_start, data, CRC16_data} = {88{1'b1}};
end endtask

//check
task command_format_check_task; begin
    if( {com_start, transmission} != 2'b01 ||
        (command != 6'd17 && command != 6'd24) ||
        end_bit != 1'b1) begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC SD-1 FAIL                                                         ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		YOU_FAIL_task;
        repeat(9) @(posedge clk);
	    $finish;	
    end
end endtask

task address_check_task; begin
    if( addr < 0 || addr > 32'd65536) begin
       $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC SD-2 FAIL                                                         ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		YOU_FAIL_task;
        repeat(9) @(posedge clk);
	    $finish;	
    end
end endtask

task CRC7_check_task; begin
    reg [6:0] crc7_correct;
    crc7_correct = CRC7({com_start, transmission, command, addr});
    if( CRC7_addr != crc7_correct)begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC SD-3 FAIL                                                         ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		YOU_FAIL_task;
        repeat(9) @(posedge clk);
	    $finish;	
    end
end endtask

task CRC16_check_task; begin
    reg [15:0] crc16_correct;
    crc16_correct = CRC16_CCITT(data);
    if( CRC16_data != crc16_correct)begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC SD-4 FAIL                                                         ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		YOU_FAIL_task;
        repeat(9) @(posedge clk);
	    $finish;	
    end
end endtask

integer unit_cnt = 0;
integer cycle_cnt = 0;
task transmission_time_check_task; begin
    unit_cnt = 0;
    cycle_cnt = 0;
    while(MOSI === 1'b1)begin
        @(posedge clk)
        cycle_cnt = cycle_cnt + 1;
        if(cycle_cnt === 8)begin
            cycle_cnt = 0;
            unit_cnt = unit_cnt + 1;
        end
        if(unit_cnt > 33)
            break;
    end
    if(cycle_cnt !== 0 || unit_cnt > 33 || unit_cnt < 2)begin
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                      FAIL!                                                               ");
        $display ("                                                                 SPEC SD-5 FAIL                                                         ");
        $display ("------------------------------------------------------------------------------------------------------------------------------------------");
		YOU_FAIL_task;
        repeat(9) @(posedge clk);
	    $finish;	
    end
end endtask

//////////////////////////////////////////////////////////////////////


task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
end endtask


function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
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
        for (i = 0; i < 64; i = i + 1) begin
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