module CAD(
    //Input Port
    clk,
    rst_n,
    in_valid,
    in_valid2,
    matrix_size,
    matrix,
	matrix_idx,
    mode,

    //Output Port
    out_valid,
    out_value
);


//---------------------------------------------------------------------
//                          Port Declaration
//---------------------------------------------------------------------

input          clk, rst_n, in_valid, in_valid2;
input [1:0]  matrix_size;
input [7:0]  matrix;
input [3:0]  matrix_idx;
input        mode;
output reg          out_valid;
output reg          out_value;

//---------------------------------------------------------------------
//                  Register & Wire Declaration
//---------------------------------------------------------------------
parameter SIZE8x8 = 'b00, SIZE16x16 = 'b01, SIZE32x32 = 'b10;


//FF
reg [1:0] matrix_size_reg;
reg [7:0] matrix_reg;
reg [3:0] img_idx_reg;
reg [3:0] kernel_idx_reg;
reg mode_reg;


wire out_valid_tmp;
wire out_value_tmp;
wire CS = 'b1;
wire OE = 'b1;
wire WEBN = 'b1;
wire signed [7:0] img_DOA, img_DOB;
wire signed [7:0] kernel_DOA, kernel_DOB;
wire signed [19:0] output_DOA, output_DOB;
reg img_WEAN, kernel_WEAN;
wire output_WEAN;
reg convolu_output_WEAN;
wire [13:0] img_A;
wire signed [7:0] img_DIA;
wire [8:0] kernel_A;
wire signed [7:0] kernel_DIA;
wire [10:0] output_A;
reg [10:0] convolu_output_A;
wire [10:0] output_B;
reg [10:0] convolu_output_B;
wire signed [19:0] output_DIA;
reg [19:0] convolu_output_DIA;
wire [8:0] de_kernel_A;
wire [13:0] de_img_A;
wire kernel_WEAN_tmp, img_WEAN_tmp;
/************************************* image & kernel save *************************************/
wire [1:0] matrix_size_reg_tmp;
wire [7:0] matrix_reg_tmp;
wire [3:0] img_idx_reg_tmp;
wire [3:0] kernel_idx_reg_tmp;
wire mode_reg_tmp;
integer i;
reg mode_update;
wire mode_update_tmp;

reg [3:0] matrix_cnt;
reg [3:0] matrix_cnt_d1;
reg isKernel;
wire isKernel_tmp;
reg [9:0] matrix_node_cnt;
reg [9:0] matrix_node_cnt_d1;
reg [3:0] matrix_cnt_tmp;
reg [9:0] matrix_node_cnt_tmp;
reg [9:0] end_size;

reg [13:0] img_A_convolu;
wire [8:0] kernel_A_convolu;
reg convolu_work, in_valid2_d1;
reg de_convolu_work;

/************************************* convolution *************************************/
reg convolution_work_d1;
wire convolu_work_tmp;
reg [3:0] img_shift_size;
reg [4:0] img_size;
reg [4:0] work_x, work_y;
reg [3:0] round;
reg signed [19:0] compute_reg [27:0];
reg signed [19:0] compute_reg_tmp [27:0];
reg signed [19:0] compute_reg_update [27:0];
reg signed [19:0] compute_reg_update_tmp [27:0];
reg [2:0] start_cnt_x, start_cnt_y;
reg [2:0] start_cnt_x_tmp, start_cnt_y_tmp;
wire [4:0] start_cnt_tmp;
reg [7:0] kernel_reg[24:0];
reg [7:0] kernel_reg_tmp[24:0];
reg signed[19:0] de_compute_reg_tmp[27:0];
reg signed[19:0] compute_reg_choose[27:0];
reg start_end;

wire img_WEBN, img_CS;
wire convolu_img_CS;
wire [13:0] img_B;
reg [13:0] convolu_img_B;

reg [4:0] work_x_d1, work_y_d1;
reg [3:0] round_d1;
wire [4:0] work_x_tmp, work_y_tmp;
reg convolu_comp;
wire convolu_comp_tmp;
wire [3:0] round_tmp;
reg signed [19:0] convolu_sum;
wire signed [19:0] convolu_sum_tmp;
wire signed [19:0] mult_add;
reg signed [7:0] mult[4:0];
reg signed [7:0] kernel[4:0];

/************************************* Maxpool *************************************/
wire [4:0] maxpool_x, maxpool_y;
wire [4:0] maxpool_x_d1, maxpool_y_d1;
wire [7:0] maxpool_addr, maxpool_addr_d1, maxpool_addr_next;
wire [9:0] convolu_addr;
wire [4:0] convolu_size, maxpool_size;
reg signed [19:0] new_max_sum;
reg signed [19:0] maxpool_cmp;
reg signed [19:0] maxpool_cmp_tmp;
wire output_CSB;
reg convolu_output_CSB;
wire CSB_0 = 'b0;
wire output_CSA = 'b1;


reg [7:0] output_addr;
reg [10:0] de_output_B;
reg de_output_CSB;
reg [10:0] de_output_A;
wire de_output_WEAN;
reg [19:0] de_output_DIA;
reg [18:0] maxpool_out_save;
reg maxpool_out_value;
reg [4:0] out_bit_cnt;
wire maxpool_out_valid;

/************************************* Deconvolution *************************************/
reg signed[7:0] de_kernel_reg[24:0];
reg signed[19:0] de_compute_reg_update[27:0];
reg signed[7:0] de_kernel_reg_tmp[24:0];
reg [2:0] de_start_cnt_x;
reg [2:0] de_start_cnt_y;
wire [2:0] de_start_cnt_x_tmp;
wire [2:0] de_start_cnt_y_tmp;
reg de_start_end;
reg [4:0] de_work_x;
reg [5:0] de_work_y;

reg de_convolution_work_d1;
wire de_convolu_work_tmp;
reg [2:0] de_round;
wire [5:0] deconvolu_size;
reg signed [19:0] de_mult[4:0];
reg signed [19:0] de_add[4:0];
reg signed [19:0] de_mult_add[4:0];
reg signed [7:0] de_img_save;
wire signed [7:0] de_img_save_tmp;
wire de_start_end_tmp;


reg [4:0] de_work_x_d1;
reg [5:0] de_work_y_d1;
wire [4:0] de_work_x_next;
wire [5:0] de_work_y_next;
reg [2:0] de_last_save_cnt;
reg de_start_end_d1;
wire [4:0] de_work_x_tmp;
wire [5:0] de_work_y_tmp;
reg de_convolu_comp;
wire de_convolu_comp_tmp;
reg [2:0] de_round_d1;
wire [2:0] de_round_tmp;
reg [10:0] de_output_addr_cnt;
reg [4:0] de_output_bit_cnt;
wire deconvolu_out_valid;
reg [18:0] deconvolu_out_save;
reg deconvolu_out_value;

/************************************* Output *************************************/
wire [18:0] out_save_tmp;
reg [18:0] out_save;
//---------------------------------------------------------------------
//                             Design start
//---------------------------------------------------------------------

/************************************* image & kernel save *************************************/

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        matrix_size_reg <= 'd0;
        matrix_reg <= 'd0;
        img_idx_reg <= 'd0;
        kernel_idx_reg <= 'd0;
        mode_reg <= 'd0;
        mode_update <= 'd0;
    end
    else begin
        matrix_size_reg <= matrix_size_reg_tmp;
        matrix_reg <= matrix_reg_tmp;
        img_idx_reg <= img_idx_reg_tmp;
        kernel_idx_reg <= kernel_idx_reg_tmp;
        mode_reg <= mode_reg_tmp;
        mode_update <= mode_update_tmp;
    end
end

assign matrix_reg_tmp = (in_valid) ? matrix : matrix_reg;
assign {img_idx_reg_tmp, kernel_idx_reg_tmp} = (in_valid2) ?  {kernel_idx_reg, matrix_idx} : {img_idx_reg, kernel_idx_reg};
assign mode_update_tmp = (out_valid) ? 'd0 : (in_valid2) ? 'd1 : mode_update;
assign mode_reg_tmp = (in_valid2 && !mode_update) ? mode : mode_reg;
assign matrix_size_reg_tmp = (in_valid && ~|matrix_cnt && ~|matrix_node_cnt && !isKernel) ? matrix_size : matrix_size_reg;



always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        matrix_cnt <= 'd0;
        matrix_cnt_d1 <= 'd0;
        matrix_node_cnt <= 'd0;
        matrix_node_cnt_d1 <= 'd0;
        isKernel <= 'd0;
        img_WEAN <= 'd1;
        kernel_WEAN <= 'd1;
    end
    else begin
        matrix_cnt <= matrix_cnt_tmp;
        matrix_cnt_d1 <= matrix_cnt;
        matrix_node_cnt <= matrix_node_cnt_tmp;
        matrix_node_cnt_d1 <= matrix_node_cnt;
        isKernel <= isKernel_tmp;
        img_WEAN <= img_WEAN_tmp;
        kernel_WEAN <= kernel_WEAN_tmp;
    end
end
always@(*)begin
    case(matrix_size_reg)
        SIZE8x8   : end_size = 'd63;
        SIZE16x16 : end_size = 'd255;
        SIZE32x32 : end_size = 'd1023;
        default   : end_size = 'd0;
    endcase
end

always@(*)begin
    if(in_valid) begin
        if(!isKernel)begin
            matrix_node_cnt_tmp =  (matrix_node_cnt == end_size) ? 'd0 : matrix_node_cnt+1;
            matrix_cnt_tmp      =  (matrix_node_cnt == end_size) ? matrix_cnt+1 : matrix_cnt;
        end else begin
            matrix_node_cnt_tmp =  (matrix_node_cnt == 'd24) ? 'd0 : matrix_node_cnt+1;
            matrix_cnt_tmp      =  (matrix_node_cnt == 'd24) ? matrix_cnt+1 : matrix_cnt;
        end
    end else begin
        matrix_node_cnt_tmp =  'd0;
        matrix_cnt_tmp      =  'd0;
    end
end


assign isKernel_tmp = (matrix_cnt == 'd15 && matrix_node_cnt == end_size) ? 'd1 : (out_valid) ? 'd0 : isKernel;



assign img_A = (!img_WEAN) ? (matrix_cnt_d1 << 10) + matrix_node_cnt_d1 : (convolu_work) ? img_A_convolu : (de_convolu_work) ? de_img_A :'d0;
assign img_DIA = (!img_WEAN) ? matrix_reg : 'd0;
assign img_WEAN_tmp = (!isKernel && in_valid) ? 'd0 : 'd1;

assign kernel_A = (!kernel_WEAN) ? matrix_cnt_d1 * 'd25 + matrix_node_cnt_d1 : (convolu_work) ? kernel_A_convolu : (de_convolu_work) ? de_kernel_A : 'd0;
assign kernel_DIA = (!kernel_WEAN) ? matrix_reg : 'd0;
assign kernel_WEAN_tmp = (in_valid) ? !isKernel : 'd1;


/************************************* convolution *************************************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        convolu_work <= 'd0;
        in_valid2_d1 <= 'd0;
    end else begin
        convolu_work <= convolu_work_tmp;
        convolution_work_d1 <= convolu_work;
        in_valid2_d1 <= in_valid2;
    end
end
//shift how many bits
always@(*)begin
    case(matrix_size_reg)
        SIZE8x8   : img_shift_size = 'd3;
        SIZE16x16 : img_shift_size = 'd4;
        SIZE32x32 : img_shift_size = 'd5;
        default   : img_shift_size = 'd0;
    endcase
end

always@(*)begin
    case(matrix_size_reg)
        SIZE8x8   : img_size = 'd7;
        SIZE16x16 : img_size = 'd15;
        SIZE32x32 : img_size = 'd31;
        default   : img_size = 'd0;
    endcase
end

assign convolu_work_tmp = (in_valid2_d1 && !mode_reg) ? 'd1 : (work_x == img_size - 'd4 && work_y == img_size - 'd4 && round == 'd5) ? 'd0 : convolu_work; 

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i = 0; i < 28; i = i+1)
            compute_reg[i] <= 'd0;
        for(i = 0; i < 25; i = i+1)
            kernel_reg[i] <= 'd0;
        start_cnt_x <= 'd0;
        start_cnt_y <= 'd0;
        start_end <= 'd0;
    end else begin
        for(i = 0; i < 28; i = i+1)
            compute_reg[i] <= compute_reg_choose[i];
        for(i = 0; i < 25; i = i+1)
            kernel_reg[i] <= kernel_reg_tmp[i];
        start_cnt_x <= start_cnt_x_tmp;
        start_cnt_y <= start_cnt_y_tmp;
        start_end <= (start_cnt_y == 'd5);
    end
end
always@(*)begin
    for(i = 0; i < 28; i = i+1)
        compute_reg_choose[i] =  (mode_reg) ? de_compute_reg_tmp[i] : compute_reg_tmp[i];
end
assign img_CS = convolu_img_CS;

assign start_cnt_x_tmp = (in_valid2 || !convolu_work) ? 'd0 : (start_cnt_x < 'd4 && start_cnt_y != 'd5) ? start_cnt_x + 1 : (start_cnt_x == 'd4) ? 'd0 : start_cnt_x; 
assign start_cnt_y_tmp = (in_valid2) ? 'd0 : (!mode_reg) ? (start_cnt_x == 'd4 && start_cnt_y < 'd5) ? start_cnt_y + 1 : start_cnt_y : 'd0;
assign kernel_A_convolu = (start_cnt_y != 'd5) ? kernel_idx_reg * 'd25 + start_cnt_y * 5 + start_cnt_x : 'd0;
assign convolu_img_CS = (convolu_work && (start_cnt_y * 5 + start_cnt_x) >= 'd22);
assign img_WEBN = 'b1;

always@(*) begin
    if(start_cnt_y != 'd5)begin
        img_A_convolu = (img_idx_reg << 10) + (start_cnt_y << img_shift_size) + start_cnt_x + (img_size - 'd4);
    end
    else
        if((!work_y[0] && ~|work_x) || (work_y[0] && (work_x == img_size - 'd4)))begin
            img_A_convolu = (img_idx_reg << 10) + ((work_y + 'd5) << img_shift_size) + work_x + round - 1;
        end
        else if(work_y[0]) begin
            img_A_convolu = (img_idx_reg << 10) + ((work_y + round - 1) << img_shift_size) + work_x + 'd5;
        end
        else begin
            img_A_convolu = (img_idx_reg << 10) + ((work_y + round - 1) << img_shift_size) + work_x - 'd1;
        end
end

always@(*)begin
    for(i = 0; i < 25; i = i+1)
        kernel_reg_tmp[i] = kernel_reg[i];
    if(!start_end && convolution_work_d1)begin
        kernel_reg_tmp[start_cnt_y * 5 + start_cnt_x - 1] = kernel_DOA;
    end
end

always@(*)begin
    for(i = 0; i < 28; i = i+1)
        compute_reg_tmp[i] = compute_reg[i];
    if((convolu_work || out_valid))begin
        if(convolution_work_d1)begin
            if(!start_end)
                compute_reg_tmp['d28 - (start_cnt_y * 5 + start_cnt_x)] = img_DOA;
            else
                for(i = 0; i < 28; i = i+1)
                    compute_reg_tmp[i] = compute_reg_update[i];
        end
        else
            for(i = 0; i < 28; i = i+1)
                compute_reg_tmp[i] = compute_reg[i];
        end
    else begin
        for(i = 0; i < 28; i = i+1)
            compute_reg_tmp[i] = 'd0;
    end

end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        work_x <= 'd0;
        work_y <= 'd0;
        work_x_d1 <= 'd0;
        work_y_d1 <= 'd0;
        convolu_comp <= 'd0;
        round <= 'd0;
        round_d1 <= 'd0;
    end else begin
        work_x <= work_x_tmp;
        work_y <= work_y_tmp;
        work_x_d1 <= work_x;
        work_y_d1 <= work_y;
        convolu_comp <= convolu_comp_tmp;
        round <= round_tmp;
        round_d1 <= round;
    end
end

assign work_x_tmp = (in_valid2) ? 'd0 :  (convolu_work) ? ( start_cnt_y =='d5) ? ( round == 'd5) ? (work_y[0]) ? (work_x == img_size - 'd4) ? work_x : work_x + 'd1 : (~|work_x) ? work_x : work_x - 'd1 : work_x : img_size - 'd4 : work_x;
assign work_y_tmp = (in_valid2) ? 'd0 :  (convolu_work) ? ( start_cnt_y =='d5 ) ? ( round == 'd5) ? (!work_y[0]) ? (~|work_x) ? work_y + 1 : work_y : (work_x == img_size - 'd4) ? work_y + 1 : work_y  : work_y : 'd0 : work_y;
assign convolu_comp_tmp = (in_valid2) ? 'd0 : ((work_x == img_size - 'd4) && (work_y == img_size - 'd4) && round == 'd5) ? 'd1 : convolu_comp;
assign round_tmp = (in_valid2) ? 'd0 : (round == 'd5) ? 'd1 : (convolu_work && ((start_cnt_y =='d4 && start_cnt_x =='d4) || start_cnt_y =='d5)) ? round + 'd1 : (out_valid) ? round + 'd1 : 'd0;

always@(*)begin
    for(i = 0; i <= 27; i = i+1)
        compute_reg_update_tmp[i] = compute_reg[i];
    if(round == 'd5) begin
        if((~work_y_d1[0] && ~|work_x_d1) || (work_y_d1[0] && |work_y_d1 && (work_x_d1 == img_size - 'd4)))begin
            for(i = 5; i <= 27; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i-5];
            compute_reg_update_tmp[4] = img_DOA;
            compute_reg_update_tmp[3] = 'd0;
        end
        else if(work_y_d1[0]) begin
            for(i = 24; i <= 27; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i-1];
            for(i = 19; i <= 22; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i-1];
            for(i = 14; i <= 17; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i-1];
            for(i = 9; i <= 12; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i-1];
            for(i = 4; i <= 7; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i-1];
            compute_reg_update_tmp[3] = 'd0;
            compute_reg_update_tmp[8] = img_DOA;
            compute_reg_update_tmp[13] = compute_reg[0];
            compute_reg_update_tmp[18] = compute_reg[1];
            compute_reg_update_tmp[23] = compute_reg[2];
        end else begin
            for(i = 23; i <= 26; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i+1];
            for(i = 18; i <= 21; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i+1];
            for(i = 13; i <= 16; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i+1];
            for(i = 8; i <= 11; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i+1];
            for(i = 3; i <= 6; i = i+1)
                compute_reg_update_tmp[i] = compute_reg[i+1];
            compute_reg_update_tmp[7] = 'd0;
            compute_reg_update_tmp[12] = img_DOA;
            compute_reg_update_tmp[17] = compute_reg[0];
            compute_reg_update_tmp[22] = compute_reg[1];
            compute_reg_update_tmp[27] = compute_reg[2];
        end
    end
    else if(round == 'd1) begin
        if((~work_y_d1[0] && ~|work_x_d1) || (work_y_d1[0] && ~|work_y_d1 && (work_x_d1 == img_size - 'd4)))begin
            compute_reg_update_tmp[3] = img_DOA;
        end
        else if(work_y_d1[0])
            compute_reg_update_tmp[3] = img_DOA;
        else
            compute_reg_update_tmp[7] = img_DOA;
    end

end

always@(*) begin
    for(i = 3; i <= 27; i = i+1)
        compute_reg_update[i] = compute_reg_update_tmp[i];
    for(i = 1; i <= 2; i = i+1)
        compute_reg_update[i] = (round != 5) ? compute_reg[i-1] : compute_reg[i];
    compute_reg_update[0] = img_DOA;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        convolu_sum <= -524288;
    
    end else begin
        convolu_sum <= convolu_sum_tmp;
    end
end


assign convolu_sum_tmp = (convolu_work) ? (round == 'd1) ? mult_add : mult_add + convolu_sum : -524288;


always@(*)
    case(round)
        'd1 : begin
            for(i = 0; i < 5; i = i+1)begin
                mult[i] = {12'b0, compute_reg[27-i]};
                kernel[i] = kernel_reg[i];
            end
        end
        'd2 : begin
            for(i = 0; i < 5; i = i+1)begin
                mult[i] = {12'b0, compute_reg[22-i]};
                kernel[i] = kernel_reg[5+i];
            end
        end
        'd3 : begin
            for(i = 0; i < 5; i = i+1)begin
                mult[i] = {12'b0, compute_reg[17-i]};
                kernel[i] = kernel_reg[10+i];
            end
        end
        'd4 : begin
            for(i = 0; i < 5; i = i+1)begin
                mult[i] = {12'b0, compute_reg[12-i]};
                kernel[i] = kernel_reg[15+i];
            end
        end
        'd5 : begin
            for(i = 0; i < 5; i = i+1)begin
                mult[i] = {12'b0, compute_reg[7-i]};
                kernel[i] = kernel_reg[20+i];
            end
        end
        default : begin
            for(i = 0; i < 5; i = i+1)begin
                mult[i] = 'd0;
                kernel[i] = 'd0;
            end
        end
    endcase


assign mult_add = mult[0] * kernel[0] + mult[1] * kernel[1] + mult[2] * kernel[2] + mult[3] * kernel[3] + mult[4] * kernel[4];

/************************************* Maxpool *************************************/

assign convolu_size = (img_size - 'd3);
assign maxpool_size = convolu_size >> 1;
assign maxpool_x = work_x >> 1;
assign maxpool_y = work_y >> 1;
assign maxpool_addr = maxpool_y * maxpool_size + maxpool_x;
assign maxpool_x_d1 = work_x_d1 >> 1;
assign maxpool_y_d1 = work_y_d1 >> 1;
assign maxpool_addr_d1 = maxpool_y_d1 * maxpool_size + maxpool_x_d1;
assign maxpool_addr_next = (work_y[0]) ? maxpool_addr + 'd1 : maxpool_addr - 'd1;
assign convolu_addr = work_y * convolu_size + work_x;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        maxpool_cmp <= -524288;
    
    end else begin
        maxpool_cmp <= (convolu_work || out_valid) ? maxpool_cmp_tmp : -524288;
    end
end

always@(*)begin
    if(round == 'd1)begin
        maxpool_cmp_tmp = new_max_sum;
    end
    else
        maxpool_cmp_tmp = maxpool_cmp;
end

always@(*)begin
    if(!work_y[0] && work_x[0])
        if(work_x == convolu_size - 'd1 && work_y == convolu_size)
            new_max_sum = (convolu_sum > maxpool_cmp) ? convolu_sum : maxpool_cmp;
        else
            new_max_sum = -524288;
    else if((work_y_d1[0] && work_x_d1[0] && (work_x_d1 != convolu_size - 1)))
        new_max_sum = output_DOB;
    else
        new_max_sum = (convolu_sum > maxpool_cmp) ? convolu_sum : maxpool_cmp;
end

assign output_CSB = (mode_reg) ? de_output_CSB : convolu_output_CSB;
assign output_B = (mode_reg) ? de_output_B : convolu_output_B;

always@(*)begin
    if((!work_y[0] && !work_x[0] && |work_x) || (work_y[0] && work_x[0]) && round == 'd5)begin
        convolu_output_B = maxpool_addr_next;
        convolu_output_CSB = 'b1;
    end
    else if(round == 'd2 && convolu_addr >= convolu_size + 'd2)begin
        convolu_output_B = output_addr;
        convolu_output_CSB = 'b1;
    end
    else begin
        convolu_output_B = 'd0;
        convolu_output_CSB = 'b0;
    end
end

assign output_A = (mode_reg) ? de_output_A : convolu_output_A;
assign output_WEAN = (mode_reg) ? de_output_WEAN : convolu_output_WEAN;
assign output_DIA = (mode_reg) ? de_output_DIA : convolu_output_DIA;

always@(*)begin
    convolu_output_A = 'd0;
    convolu_output_DIA = 'd0;
    convolu_output_WEAN = 'b1;
    if(round == 'd1)
        if(((!work_y_d1[0]) && (!work_x_d1[0]) && (|work_x_d1)) || (work_y_d1[0] && work_x_d1[0]))begin
            convolu_output_A = maxpool_addr_d1;
            convolu_output_DIA = (convolu_sum > maxpool_cmp) ? convolu_sum : maxpool_cmp;
            convolu_output_WEAN = 'b0;
        end
end
//output

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        output_addr <= 'd0;
        out_bit_cnt <= 'd0;
    end
    else begin
        if(round == 'd3 && convolu_addr == convolu_size + 'd2)begin
            output_addr <= 'd1;
            out_bit_cnt <= 'd0;
        end
        else if(out_valid) begin
            output_addr <= (out_bit_cnt == 'd19) ? output_addr + 'd1 : output_addr;
            out_bit_cnt <= (out_bit_cnt == 'd19) ? 'd0 : out_bit_cnt + 'd1;
        end
        else begin
        output_addr <= 'd0;
        out_bit_cnt <= 'd0;
        end 
    end
end

assign maxpool_out_valid = (round == 'd3 && convolu_addr == convolu_size + 'd2) ? 'd1 : 
                           (output_addr == maxpool_size * maxpool_size && out_bit_cnt == 'd19) ? 'd0 : out_valid;


always@(*)begin
    if(output_addr == maxpool_size * maxpool_size && out_bit_cnt == 'd19)begin
            maxpool_out_save = 'd0;
            maxpool_out_value = 'd0;
    end
    else if(out_bit_cnt == 'd19 || (round == 'd3 && convolu_addr == convolu_size + 'd2))begin
        if(output_addr == maxpool_size * maxpool_size - 1)begin
            maxpool_out_save = maxpool_cmp[19:1];
            maxpool_out_value = maxpool_cmp[0];
        end
        else begin
            maxpool_out_save = output_DOB[19:1];
            maxpool_out_value = output_DOB[0];
        end
    end
    else begin
        maxpool_out_save = out_save >> 1;
        maxpool_out_value = out_save[0];
    end
end

/************************************* Deconvolution *************************************/

assign deconvolu_size = (img_size + 'd5);
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        de_convolu_work <= 'd0;
        de_convolution_work_d1 <= 'd0;
    end else begin
        de_convolu_work <= de_convolu_work_tmp;
        de_convolution_work_d1 <= de_convolu_work;
    end
end
assign de_convolu_work_tmp = (in_valid2_d1 && mode_reg) ? 'd1 : (de_work_x == 'd0 && de_work_y == img_size && de_round == 'd5) ? 'd0 : de_convolu_work; 

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i = 0; i < 25; i = i+1)
            de_kernel_reg[i] <= 'd0;
        de_start_cnt_x <= 'd0;
        de_start_end <= 'd0;
        de_img_save <= 'd0;
    end else begin
        for(i = 0; i < 25; i = i+1)
            de_kernel_reg[i] <= de_kernel_reg_tmp[i];
        de_start_cnt_x <= de_start_cnt_x_tmp;
        de_start_cnt_y <= de_start_cnt_y_tmp;
        de_start_end <= de_start_end_tmp;
        de_img_save <= de_img_save_tmp;
    end
end

assign de_img_save_tmp = (de_start_cnt_y * 5 + de_start_cnt_x == 'd19) ? img_DOA : (de_round == 'd5) ? img_DOA : de_img_save;
assign de_start_end_tmp = (in_valid2) ? 'd0 : (de_start_cnt_y == 'd4 && de_start_cnt_x == 'd4) ? 'd1 : de_start_end;


assign de_start_cnt_x_tmp = (in_valid2 || !de_convolu_work) ? 'd0 : (de_start_cnt_x < 'd4 && de_start_cnt_y != 'd5) ? de_start_cnt_x + 1 : (de_start_cnt_x == 'd4) ? 'd0 : de_start_cnt_x; 
assign de_start_cnt_y_tmp = (in_valid2) ? 'd0 : (mode_reg) ? (de_start_cnt_x == 'd4 && de_start_cnt_y < 'd5) ? de_start_cnt_y + 1 : de_start_cnt_y : 'd0;
assign de_kernel_A = (de_start_cnt_y != 'd5) ? kernel_idx_reg * 'd25 + de_start_cnt_y * 5 + de_start_cnt_x : 'd0;
//assign de_img_CS = (de_convolu_work && (de_start_cnt_y * 5 + de_start_cnt_x) >= 'd18);

assign de_work_x_next = (!de_work_y[0]) ? (de_work_x == img_size) ? de_work_x : de_work_x + 'd1 : (de_work_x == 'd0) ? de_work_x : de_work_x - 'd1;
assign de_work_y_next = (!de_work_y[0]) ? (de_work_x == img_size) ? de_work_y + 'd1 : de_work_y : (de_work_x == 'd0) ? de_work_y + 'd1 : de_work_y;

assign de_img_A = (de_start_end || (de_start_cnt_x == 'd3 && de_start_cnt_y == 'd4)) ? (img_idx_reg << 10) + (de_work_y_next << img_shift_size) + de_work_x_next 
                                  : (img_idx_reg << 10);



always@(posedge clk or negedge rst_n)begin
    if(!rst_n) 
        de_last_save_cnt <= 'd0;
    else
        de_last_save_cnt <= (in_valid2) ? 'd0 : (de_work_x == 'd0 && de_work_y == deconvolu_size && round == 'd5) ? 'd1 : (round == 'd5 && de_last_save_cnt <= 'd5) ? de_last_save_cnt + 'd1 : de_last_save_cnt;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        de_start_end_d1 <= 'd0;
    else
        de_start_end_d1 <= de_start_end;
end

always@(*)begin
    for(i = 0; i < 25; i = i+1)
        de_kernel_reg_tmp[i] = de_kernel_reg[i];
    if(!de_start_end_d1 && de_convolution_work_d1)begin
        de_kernel_reg_tmp[de_start_cnt_y * 5 + de_start_cnt_x - 1] = kernel_DOA;
    end
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        de_work_x <= 'd0;
        de_work_y <= 'd0;
        de_work_x_d1 <= 'd0;
        de_work_y_d1 <= 'd0;
        de_convolu_comp <= 'd0;
        de_round <= 'd0;
        de_round_d1 <= 'd0;
    end else begin
        de_work_x <= de_work_x_tmp;
        de_work_y <= de_work_y_tmp;
        de_work_x_d1 <= de_work_x;
        de_work_y_d1 <= de_work_y;
        de_convolu_comp <= de_convolu_comp_tmp;
        de_round <= de_round_tmp;
        de_round_d1 <= de_round;
    end
end

assign de_work_x_tmp = (in_valid2) ? 'd0 : (de_work_y > img_size) ? 'd0 :(de_convolu_work) ?  ( de_round == 'd5) ? de_work_x_next : de_work_x : 'd0 ;
assign de_work_y_tmp = (in_valid2) ? 'd0 : (de_work_y > img_size && de_work_y <= deconvolu_size) ? (de_round == 'd5 && de_work_y != deconvolu_size) ? de_work_y + 1 : de_work_y :(de_convolu_work) ?  ( de_round == 'd5) ? de_work_y_next : de_work_y : 'd0 ;
assign de_convolu_comp_tmp = (in_valid2) ? 'd0 : ((de_work_x == 'd0) && (de_work_y == img_size) && de_round == 'd5) ? 'd1 : de_convolu_comp;
assign de_round_tmp = (in_valid2) ? 'd0 : (de_round == 'd5) ? 'd1 : (de_convolu_work && (de_start_cnt_y * 5 + de_start_cnt_x) >= 'd21) ? de_round + 'd1 : (out_valid) ? de_round + 'd1 : 'd0;


//de_compute_reg
always@(*)begin
    if(de_convolu_work || out_valid) begin
    if(de_work_y > img_size)begin
        if(de_round == 'd5)begin
            for(i = 8; i < 28; i = i+1)
                de_compute_reg_tmp[i] = compute_reg[i - 5];
            for(i = 0; i < 8; i = i+1)
                de_compute_reg_tmp[i] = 'd0;
        end else begin
            for(i = 0; i < 28; i = i+1)
                de_compute_reg_tmp[i] = compute_reg[i];
        end

    end
    else begin
        case(de_round)
            'd1 : begin
                for(i = 0; i < 23; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 23; i < 28; i = i+1)
                    de_compute_reg_tmp[i] = de_mult_add['d27 - i];
            end
            'd2 : begin
                for(i = 0; i < 18; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 23; i < 28; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 18; i < 23; i = i+1)
                    de_compute_reg_tmp[i] = de_mult_add['d22 - i];
                de_compute_reg_tmp[0] = compute_reg[0];
                de_compute_reg_tmp[1] = compute_reg[1];
                de_compute_reg_tmp[2] = (de_start_end && (|de_work_y)) ? output_DOB : 'd0;
            end
            'd3 : begin
                for(i = 3; i < 13; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 18; i < 28; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 13; i < 18; i = i+1)
                    de_compute_reg_tmp[i] = de_mult_add['d17 - i];
                de_compute_reg_tmp[0] = compute_reg[0];
                de_compute_reg_tmp[1] = (de_start_end && (|de_work_y)) ? output_DOB : 'd0;
                de_compute_reg_tmp[2] = compute_reg[2];
            end
            'd4 : begin
                for(i = 3; i < 8; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 13; i < 28; i = i+1)
                    de_compute_reg_tmp[i] = compute_reg[i];
                for(i = 8; i < 13; i = i+1)
                    de_compute_reg_tmp[i] = de_mult_add['d12 - i];
                de_compute_reg_tmp[0] = (de_start_end && (|de_work_y)) ? output_DOB : 'd0;
                de_compute_reg_tmp[1] = compute_reg[1];
                de_compute_reg_tmp[2] = compute_reg[2];
            end
            'd5 : begin
                for(i = 0; i < 28; i = i+1)
                    de_compute_reg_tmp[i] = de_compute_reg_update[i];
            end
            default : begin
                for(i = 0; i < 28; i = i+1)
                    de_compute_reg_tmp[i] = 'd0;
            end
        endcase
    end
    end
    else begin
        for(i = 0; i < 28; i = i+1)
            de_compute_reg_tmp[i] = 'd0;
    end
end



always@(*)begin
    for(i = 0; i < 3; i = i+1)begin
        de_compute_reg_update[i] = 'd0;
    end
    if((!de_work_y[0] && de_work_x == img_size) || (de_work_y[0] && de_work_x == 'd0))begin
        for(i = 13; i < 28; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i-5];
        end
        for(i = 8; i < 13; i = i+1)begin
            de_compute_reg_update[i] = de_mult_add['d12 - i];
        end
        for(i = 3; i < 8; i = i+1)begin
            de_compute_reg_update[i] = 'd0;
        end
    end else if(!de_work_y[0]) begin
        for(i = 24; i < 28; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i-1];
        end
        de_compute_reg_update[23] = compute_reg[2];
        for(i = 19; i < 23; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i-1];
        end
        de_compute_reg_update[18] = compute_reg[1];
        for(i = 14; i < 18; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i-1];
        end
        de_compute_reg_update[13] = compute_reg[0];
        for(i = 9; i < 13; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i-1];
        end
        de_compute_reg_update[8] = (de_start_end && (|de_work_y)) ? output_DOB : 'd0;
        for(i = 4; i < 8; i = i+1)begin
            de_compute_reg_update[i] = de_mult_add['d8 - i];
        end
        de_compute_reg_update[3] = 'd0;
    end else begin
        de_compute_reg_update[27] = compute_reg[2];
        for(i = 23; i < 27; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i+1];
        end
        de_compute_reg_update[22] = compute_reg[1];
        for(i = 18; i < 22; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i+1];
        end
        de_compute_reg_update[17] = compute_reg[0];
        for(i = 13; i < 17; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i+1];
        end
        de_compute_reg_update[12] = output_DOB;
        for(i = 8; i < 12; i = i+1)begin
            de_compute_reg_update[i] = compute_reg[i+1];
        end
        de_compute_reg_update[7] = 'd0;
        for(i = 3; i < 7; i = i+1)begin
            de_compute_reg_update[i] = de_mult_add['d6 - i];
        end
    end
end

always@(*)begin
    case(de_round)
        'd1 : begin
            for(i = 0; i < 5; i = i+1)begin
                de_mult[i] = de_kernel_reg[i];
                de_add[i] = compute_reg['d27 - i];
            end
        end
        'd2 : begin
            for(i = 0; i < 5; i = i+1)begin
                de_mult[i] = de_kernel_reg[i + 5];
                de_add[i] = compute_reg['d22 - i];
            end
        end
        'd3 : begin
            for(i = 0; i < 5; i = i+1)begin
                de_mult[i] = de_kernel_reg[i + 10];
                de_add[i] = compute_reg['d17 - i];
            end
        end
        'd4 : begin
            for(i = 0; i < 5; i = i+1)begin
                de_mult[i] = de_kernel_reg[i + 15];
                de_add[i] = compute_reg['d12 - i];
            end
        end
        'd5 : begin
            for(i = 0; i < 5; i = i+1)begin
                de_mult[i] = de_kernel_reg[i + 20];
                de_add[i] = compute_reg['d7 - i];
            end
        end
        default : begin
            for(i = 0; i < 5; i = i+1)begin
                de_mult[i] = 'd0;
                de_add[i] = 'd0;
            end
        end
    endcase
end

always@(*)begin
    for(i = 0; i < 5; i = i+1)
        de_mult_add[i] = de_mult[i] * de_img_save + de_add[i];
end


always@(*)begin
    if((de_round < 'd5 && de_round > 'd0) && de_start_end && de_work_y <= img_size)begin
        if((!de_work_y[0] && de_work_x == img_size) || (de_work_y[0] && de_work_x == 'd0))begin
            de_output_B = 'd0;
            de_output_CSB = 'd0;
        end else if(!de_work_y[0])begin
            de_output_B = (de_work_y + de_round - 1)  * deconvolu_size + de_work_x + 'd5;
            de_output_CSB = 'd1;
        end else begin
            de_output_B = (de_work_y + de_round - 1)  * deconvolu_size + de_work_x -'d1;
            de_output_CSB = 'd1;
        end
    end
    else if(de_round == 'd5 && de_output_addr_cnt < deconvolu_size * deconvolu_size)begin
        de_output_B = de_output_addr_cnt;
        de_output_CSB = 'd1;
    end
    else begin
        de_output_B = 'd0;
        de_output_CSB = 'd0;
    end
end

assign de_output_WEAN = (de_round > 'd0 && de_convolu_work ) ? 'd0 : (de_work_y > img_size && de_work_y < deconvolu_size) ? 'd0 : 'd1;
always@(*)begin
    if(de_work_y > img_size && de_work_y <= deconvolu_size) begin
        if(de_work_y == deconvolu_size)begin
            de_output_A = 'd0;
            de_output_DIA = 'd0;
        end
        else begin
            de_output_A = de_work_y * deconvolu_size + de_work_x + de_round - 1;
            de_output_DIA = compute_reg['d28 - de_round];
        end
    end
    else begin   
        if(de_round > 'd0)begin
            if((!de_work_y[0] && de_work_x == img_size) || (de_work_y[0] && de_work_x == 'd0))begin
                de_output_A = de_work_y * deconvolu_size + de_work_x + de_round - 1;
                if(de_round == 'd1)
                    de_output_DIA = de_mult_add[0];
                else
                    de_output_DIA = compute_reg['d28 - de_round];
            end else if(!de_work_y[0])begin
                de_output_A = (de_work_y + de_round - 1)  * deconvolu_size + de_work_x;
                de_output_DIA = de_mult_add[0];
            end else begin
                de_output_A = (de_work_y + de_round - 1)  * deconvolu_size + de_work_x + 'd4;
                de_output_DIA = de_mult_add[4];
            end
        end else begin
            de_output_A = 'd0;
            de_output_DIA = 'd0;
        end
    end
end
//output
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        de_output_addr_cnt <= 'd0;
        de_output_bit_cnt <= 'd0;
    end
    else begin
        if(de_work_y == 'd0 && de_work_x == 'd2 && de_round  == 'd1)begin
            de_output_addr_cnt <= 'd1;
            de_output_bit_cnt <= 'd0;
        end
        else if(out_valid)begin
            de_output_addr_cnt <= (de_output_bit_cnt == 'd19 && de_output_addr_cnt < deconvolu_size * deconvolu_size) ? de_output_addr_cnt + 'd1 : de_output_addr_cnt;
            de_output_bit_cnt <= (de_output_bit_cnt == 'd19) ? 'd0 : de_output_bit_cnt + 'd1;
        end
        else begin
            de_output_addr_cnt <= 'd0;
            de_output_bit_cnt <= 'd0;
        end
    end
end


assign deconvolu_out_valid = (de_work_y == 'd0 && de_work_x == 'd2 && de_round  == 'd1) ? 'd1 : 
                             (de_output_addr_cnt == deconvolu_size * deconvolu_size && out_bit_cnt == 'd19) ? 'd0 : out_valid;


always@(*)begin
    if(de_output_addr_cnt == deconvolu_size * deconvolu_size && out_bit_cnt == 'd19)begin
            deconvolu_out_save = 'd0;
            deconvolu_out_value = 'd0;
    end 
    else if(de_output_bit_cnt == 'd19 || (de_work_y == 'd0 && de_work_x == 'd2 && de_round  == 'd1))begin
            deconvolu_out_save = output_DOB[19:1];
            deconvolu_out_value = output_DOB[0];
    end
    else begin
        deconvolu_out_save = out_save >> 1;
        deconvolu_out_value = out_save[0];
    end
end



        
/************************************* Output *************************************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_save <= 'd0;
    end
    else begin
        out_save <= out_save_tmp;
    end
end
assign out_save_tmp = (mode_reg) ? deconvolu_out_save : maxpool_out_save;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 'd0;
        out_value <= 'd0;
    end else begin
        out_valid <= out_valid_tmp;
        out_value <= out_value_tmp;
    end
end

assign out_valid_tmp = (mode_reg) ? deconvolu_out_valid : maxpool_out_valid;
assign out_value_tmp = (mode_reg) ? deconvolu_out_value : maxpool_out_value;

/************************************* Memory *************************************/
//save 16 * 32 * 32 img matrix
MEM32x32 MEM32x32_U1(  .A0(img_A[0]),      .A1(img_A[1]),      .A2(img_A[2]),      .A3(img_A[3]),      .A4(img_A[4]),      .A5(img_A[5]),      .A6(img_A[6]),        .A7(img_A[7]),
                        .A8(img_A[8]),      .A9(img_A[9]),      .A10(img_A[10]),    .A11(img_A[11]),    .A12(img_A[12]),    .A13(img_A[13]),
                        .DO0(img_DOA[0]),   .DO1(img_DOA[1]),   .DO2(img_DOA[2]),   .DO3(img_DOA[3]),   .DO4(img_DOA[4]),   .DO5(img_DOA[5]),   .DO6(img_DOA[6]),   .DO7(img_DOA[7]),
                        .DI0(img_DIA[0]),   .DI1(img_DIA[1]),   .DI2(img_DIA[2]),   .DI3(img_DIA[3]),   .DI4(img_DIA[4]),   .DI5(img_DIA[5]),   .DI6(img_DIA[6]),   .DI7(img_DIA[7]),
                        .CK(clk),           .WEB(img_WEAN),     .OE(OE),            .CS(CS));



//save 16 * 5 * 5 kernel matrix
MEM5x5 MEM5x5_U2(       .A0(kernel_A[0]),       .A1(kernel_A[1]),       .A2(kernel_A[2]),       .A3(kernel_A[3]),       .A4(kernel_A[4]),       .A5(kernel_A[5]),       .A6(kernel_A[6]),       .A7(kernel_A[7]),       .A8(kernel_A[8]),
                        .DO0(kernel_DOA[0]),    .DO1(kernel_DOA[1]),    .DO2(kernel_DOA[2]),    .DO3(kernel_DOA[3]),    .DO4(kernel_DOA[4]),    .DO5(kernel_DOA[5]),    .DO6(kernel_DOA[6]),    .DO7(kernel_DOA[7]),
                        .DI0(kernel_DIA[0]),    .DI1(kernel_DIA[1]),    .DI2(kernel_DIA[2]),    .DI3(kernel_DIA[3]),    .DI4(kernel_DIA[4]),    .DI5(kernel_DIA[5]),    .DI6(kernel_DIA[6]),    .DI7(kernel_DIA[7]),
                        .CK(clk),               .WEB(kernel_WEAN),      .OE(OE),                .CS(CS));

//save 36 * 36 deconvolution output

MEM36x36 MEM36x36_U3(   .A0(output_A[0]),       .A1(output_A[1]),       .A2(output_A[2]),       .A3(output_A[3]),       .A4(output_A[4]),
                        .A5(output_A[5]),       .A6(output_A[6]),       .A7(output_A[7]),       .A8(output_A[8]),       .A9(output_A[9]),   .A10(output_A[10]),
                        .B0(output_B[0]),       .B1(output_B[1]),       .B2(output_B[2]),       .B3(output_B[3]),       .B4(output_B[4]),               
                        .B5(output_B[5]),       .B6(output_B[6]),       .B7(output_B[7]),       .B8(output_B[8]),       .B9(output_B[9]),   .B10(output_B[10]),
                        .DOA0(output_DOA[0]),   .DOA1(output_DOA[1]),   .DOA2(output_DOA[2]),   .DOA3(output_DOA[3]),   .DOA4(output_DOA[4]),
                        .DOA5(output_DOA[5]),   .DOA6(output_DOA[6]),   .DOA7(output_DOA[7]),   .DOA8(output_DOA[8]),   .DOA9(output_DOA[9]),
                        .DOA10(output_DOA[10]), .DOA11(output_DOA[11]), .DOA12(output_DOA[12]), .DOA13(output_DOA[13]), .DOA14(output_DOA[14]),
                        .DOA15(output_DOA[15]), .DOA16(output_DOA[16]), .DOA17(output_DOA[17]), .DOA18(output_DOA[18]), .DOA19(output_DOA[19]),
                        .DOB0(output_DOB[0]),   .DOB1(output_DOB[1]),   .DOB2(output_DOB[2]),   .DOB3(output_DOB[3]),   .DOB4(output_DOB[4]),
                        .DOB5(output_DOB[5]),   .DOB6(output_DOB[6]),   .DOB7(output_DOB[7]),   .DOB8(output_DOB[8]),   .DOB9(output_DOB[9]),
                        .DOB10(output_DOB[10]), .DOB11(output_DOB[11]), .DOB12(output_DOB[12]), .DOB13(output_DOB[13]), .DOB14(output_DOB[14]),
                        .DOB15(output_DOB[15]), .DOB16(output_DOB[16]), .DOB17(output_DOB[17]), .DOB18(output_DOB[18]), .DOB19(output_DOB[19]),
                        .DIA0(output_DIA[0]),   .DIA1(output_DIA[1]),   .DIA2(output_DIA[2]),   .DIA3(output_DIA[3]),   .DIA4(output_DIA[4]),
                        .DIA5(output_DIA[5]),   .DIA6(output_DIA[6]),   .DIA7(output_DIA[7]),   .DIA8(output_DIA[8]),   .DIA9(output_DIA[9]),
                        .DIA10(output_DIA[10]), .DIA11(output_DIA[11]), .DIA12(output_DIA[12]), .DIA13(output_DIA[13]), .DIA14(output_DIA[14]),
                        .DIA15(output_DIA[15]), .DIA16(output_DIA[16]), .DIA17(output_DIA[17]), .DIA18(output_DIA[18]), .DIA19(output_DIA[19]),
                        //.DIB0('b0),             .DIB1('b0),             .DIB2('b0),             .DIB3('b0),             .DIB4('b0),
                        //.DIB5('b0),             .DIB6('b0),             .DIB7('b0),             .DIB8('b0),             .DIB9('b0),
                        //.DIB10('b0),            .DIB11('b0),            .DIB12('b0),            .DIB13('b0),            .DIB14('b0),
                        //.DIB15('b0),            .DIB16('b0),            .DIB17('b0),            .DIB18('b0),            .DIB19('b0),
                        .WEAN(output_WEAN),     .WEBN(WEBN),             .CKA(clk),              .CKB(clk),              .CSA(output_CSA),               .CSB(output_CSB),      .OEA(OE),       .OEB(OE));

endmodule


