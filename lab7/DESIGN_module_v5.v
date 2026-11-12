module CLK_1_MODULE (
	input               clk, 
    input               rst_n,
    input               in_mode_valid,
    input       	    in_mode,
	
    input               in_valid,
    input       [1:0]   in_bank,
    input       [5:0]   in_src_row,

    output reg          out_valid,
    output reg  [63:0]  out_data,

	input out_idle,
	output reg handshake_sready,
	output reg [8:0] handshake_din,
	// You can use the the custom flag ports for your design
	input  flag_handshake_to_clk1,
	output flag_clk1_to_handshake,

	input fifo_empty,
	input [31:0] fifo_rdata,
	output fifo_rinc,
	// You can use the the custom flag ports for your design
	output flag_clk1_to_fifo,
	input flag_fifo_to_clk1

);

// ==========================================
// Declare
// ==========================================
parameter IDLE = 0;
parameter TX = 1;

reg mode, next_mode;
reg [1:0] bank [0:3], next_bank [0:3];
reg [5:0] src_row [0:3], next_src_row [0:3];
reg next_handshake_sready;
reg [8:0] next_handshake_din;
reg [2:0] h_ct, next_h_ct, in_ct, next_in_ct;
reg [1:0] state, next_state;

reg next_out_valid;
reg [63:0] next_out_data;
reg out_half, next_out_half;
reg [31:0] out_lower, next_out_lower;

reg fifo_read_valid;

integer i;
// ==========================================
// Design
// ==========================================
assign flag_clk1_to_handshake = 0;
assign flag_clk1_to_fifo = 0;
// state
always @(*)
begin
    next_state = state;

    case(state)
        IDLE: begin
            next_state = (in_ct == 4) ? TX : IDLE;
        end
        TX: begin
            next_state = (h_ct == 4) ? IDLE : TX;
        end
    endcase
end
// input
always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        next_bank[i] = bank[i];
        next_src_row[i] = src_row[i];
    end
    next_mode = mode;
    next_in_ct = in_ct;
    
    if(in_mode_valid)
        next_mode = in_mode;
    else if(in_valid)
    begin
        next_bank[3] = in_bank;
        next_bank[0:2] = bank[1:3];
        next_src_row[3] = in_src_row;
        next_src_row[0:2] = src_row[1:3];

        next_in_ct = in_ct + 1;
    end

    if(in_ct == 4)
    begin
        next_in_ct = 0;
    end
end
// handshake syn
always @(*)
begin
    next_handshake_sready = 0;
    next_handshake_din = 0;
    next_h_ct = h_ct;

    if(state == TX)
    begin
        if(h_ct < 4)
        begin
            next_handshake_sready = 1;
            if(handshake_sready && out_idle)
            begin
                next_handshake_din = {mode, bank[h_ct], src_row[h_ct]};
                next_h_ct = h_ct + 1;
            end
            else
                next_handshake_din = handshake_din;
            
        end
    end
    else if(state == IDLE)
    begin
        next_handshake_sready = 0;
        next_handshake_din = 0;
        next_h_ct = 0;
    end
end
assign fifo_rinc = fifo_read_valid;
// output
always @(*)
begin
    next_out_valid = 0;
    next_out_data = 0;
    next_out_half = out_half;
    next_out_lower = out_lower;
    fifo_read_valid = !fifo_empty && !flag_fifo_to_clk1;

    if(flag_fifo_to_clk1)
    begin
        if(out_half == 0) //lower half
        begin
            next_out_half = 1;
            next_out_lower = fifo_rdata;
        end
        else // upper half
        begin
            next_out_half = 0;
            next_out_valid = 1;
            next_out_data = {fifo_rdata, out_lower};
        end
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n) 
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            bank[i] <= 0;
            src_row[i] <= 0;
        end
        mode <= 0;
        handshake_sready <= 0;
        handshake_din <= 0;
        h_ct <= 0;
        in_ct <= 0;
        state <= 0;
        out_valid <= 0;
        out_data <= 0;
        out_half <= 0;
        out_lower <= 0;
    end
    else
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            bank[i] <= next_bank[i];
            src_row[i] <= next_src_row[i];
        end
        mode <= next_mode;
        handshake_sready <= next_handshake_sready;
        handshake_din <= next_handshake_din;
        h_ct <= next_h_ct;
        in_ct <= next_in_ct;
        state <= next_state;
        out_valid <= next_out_valid;
        out_data <= next_out_data;
        out_half <= next_out_half;
        out_lower <= next_out_lower;
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    
	//INPUT
	busy,
    in_valid,
    in_data,
	flag_handshake_to_clk2,
    flag_clk2_to_handshake,

	//OUTPUT
    out_fifo_full,
    out_valid,
    out_data,
    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

	//AR
    ar_fifo_full,
    ar_out_valid,
    ar_out_data,
    ar_flag_fifo_to_wclk,
    ar_flag_wclk_to_fifo,

    //R
	r_fifo_empty,
    r_fifo_rdata,
    r_fifo_rinc,
    r_flag_fifo_to_rclk,
    r_flag_rclk_to_fifo,

	ar_addr, 
    ar_valid, 
    ar_ready,
    r_data,  
    // r_resp, 
    r_valid, 
    r_ready
);
input clk;
input rst_n;

output  busy;
input in_valid;
input [8:0] in_data;
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input out_fifo_full;
output reg out_valid;
output reg [31:0] out_data;
input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

//AR
input    	ar_fifo_full;
output reg  ar_out_valid;
output reg [31:0]    ar_out_data;
input    	ar_flag_fifo_to_wclk;
output    	ar_flag_wclk_to_fifo;

//R
input	r_fifo_empty;
input [31:0]   r_fifo_rdata;
output    r_fifo_rinc;
input    r_flag_fifo_to_rclk;
output    r_flag_rclk_to_fifo;

output   [31:0]  ar_addr;
output           ar_valid; 
output           ar_ready;
output reg  [63:0]  r_data;  
// input       [1:0]   r_resp; 
output reg       r_valid; 
output           r_ready;

// ==========================================
// Declare
// ==========================================
parameter IDLE = 0;
parameter CALC = 1;
parameter G_PASS1 = 2;
parameter G_CALC = 3;
parameter G_PASS2 = 4;
parameter OUT = 5;

reg [2:0] state, next_state;
reg mode, next_mode;
reg [1:0] bank [0:3], next_bank [0:3];
reg [5:0] src_row [0:3], next_src_row [0:3];
reg [63:0] ans, next_ans;
reg [2:0] rcv_ct, next_rcv_ct;
reg next_ar_out_valid;
reg [31:0] next_ar_out_data;
reg r_rinc, next_r_rinc;
reg left_valid, next_left_valid, right_valid, next_right_valid, start_tree_valid, next_start_tree_valid;
reg [65:0] stack [0:15];
reg [65:0] next_stack [0:15];
reg signed [63:0] num1, num2, result;
reg [63:0] calc_result [0:3];
reg [63:0] next_calc_result [0:3];
reg [2:0] calc_ct, next_calc_ct, out_ct, next_out_ct;
reg [3:0] stack_ct, next_stack_ct;
reg stack_update;
reg [1:0] wait_data_ct, next_wait_data_ct;
reg next_out_valid;
reg [31:0] next_out_data;
reg [11:0] ar_ct, next_ar_ct, r_ct, next_r_ct, n_ct, next_n_ct, req_ct, next_req_ct;
reg [41:0] sum, next_sum;
reg [73:0] sq_sum, next_sq_sum;
reg [85:0] threshold, next_threshold;
reg [42:0] guass_a, guass_b, guass_abs_diff, next_guass_abs_diff;
reg [85:0] guass_diff_sq;
reg pipe_valid, next_pipe_valid, pipe_last, next_pipe_last;
reg [63:0] rdata_temp, next_rdata_temp;
reg read_half, next_read_half;
reg [31:0] rdata_lower, next_rdata_lower;
reg [63:0] full_rdata;
reg write_half, next_write_half, pedding_upper, next_pedding_upper;
reg [31:0] upper_data, next_upper_data;
reg [85:0] term1, term2, next_term1, next_term2;

integer i;
// ==========================================
// Design
// ==========================================
assign busy = (state != IDLE);
assign flag_clk2_to_handshake = 0;
assign flag_clk2_to_fifo = 0;
assign ar_flag_wclk_to_fifo = 0;
assign r_flag_wclk_to_fifo = 0;

// input
always @(*)
begin
    next_mode = mode;
    for (i = 0; i < 4; i = i + 1)
    begin
        next_bank[i] = bank[i];
        next_src_row[i] = src_row[i];
    end
    next_rcv_ct = rcv_ct;

    if(state == IDLE && in_valid)
    begin
        next_mode = in_data[8];
        next_bank[rcv_ct] = in_data[7:6];
        next_src_row[rcv_ct] = in_data[5:0];

        if(rcv_ct == 3)
            next_rcv_ct = 0;
        else
            next_rcv_ct = rcv_ct + 1;
    end

end
// state
always @(*)
begin
    next_state = state;

    case(state)
        IDLE: begin
            if(in_valid && rcv_ct == 3)
            begin
                if(mode == 0)
                    next_state = CALC;
                else
                    next_state = G_PASS1;
            end
            else
                next_state = IDLE;
        end
        CALC: begin
            if(next_calc_ct == 4)
                next_state = OUT;
            else
                next_state = CALC;
        end
        G_PASS1: begin
            if(r_ct == 1024)
                next_state = G_CALC;
            else
                next_state = G_PASS1;
        end
        G_CALC: begin
            if(r_ct == 1025) 
                next_state = G_PASS2;
            else
                next_state = G_CALC;
        end
        G_PASS2: begin
            if(r_ct == 1024)
                next_state = IDLE;
            else
                next_state = G_PASS2;
        end
        OUT: begin
            if(out_ct == 4)
                next_state = IDLE;
            else
                next_state = OUT;
        end
    endcase

end
// ar
always @(*)
begin
    next_ar_out_valid = 0;
    next_ar_out_data = 0;
    next_ar_ct = ar_ct;

    if(state == CALC && ar_out_valid) 
    begin
        next_ar_out_valid = 0;
        next_ar_out_data = 0;
    end

    // ensure !ar_fifo_full
    if(state == CALC && !ar_out_valid && !ar_flag_fifo_to_wclk)
    begin
        if(start_tree_valid) // calc first read
        begin
            next_ar_out_valid = 1;
            next_ar_out_data = {bank[calc_ct], src_row[calc_ct], 8'b0};
        end
        else if(next_left_valid && stack_update)
        begin
            next_ar_out_valid = 1;
            next_ar_out_data = next_stack[0][31:16];
        end
        else if(next_right_valid && stack_update)        
        begin
            next_ar_out_valid = 1;
            next_ar_out_data = next_stack[1][15:0];
        end
    end

    if((state == G_PASS1 || state == G_PASS2) && ar_ct < 1024)
    begin
        if(!ar_flag_fifo_to_wclk)
        begin
            next_ar_out_valid = 1;
            next_ar_out_data = {bank[ar_ct[9:8]], src_row[ar_ct[9:8]], ar_ct[7:0]};
            
            next_ar_ct = ar_ct + 1;
        end
    end
    if(state == IDLE || state == G_CALC)
    begin
        next_ar_out_valid = 0;
        next_ar_out_data = 0;
        next_ar_ct = 0;
    end
    

end
// pattern use
assign ar_valid = next_ar_out_valid;
assign ar_addr = next_ar_out_data;
assign ar_ready = (state == CALC || state == G_PASS1 || state == G_PASS2 || state == G_CALC) && !ar_fifo_full;

// r
always @(*)
begin
    next_r_rinc = 0;
    next_req_ct = req_ct;

    if(state == CALC && wait_data_ct > 0 && !r_fifo_empty)
    begin
        next_r_rinc = 1;
    end

    if(state == G_PASS1 && req_ct < 2048 && !r_fifo_empty)
    begin
        next_r_rinc = 1;
        next_req_ct = req_ct + 1;
    end
    else if(state == G_PASS2 && req_ct < 2048 && !r_fifo_empty && !out_fifo_full && !pipe_valid && !pedding_upper)
    begin
        next_r_rinc = 1;
        next_req_ct = req_ct + 1;
    end

    if(state != G_PASS1 && state != G_PASS2)
    begin
        next_req_ct = 0;
    end

end
// read half
always @(*)
begin
    next_read_half = read_half;
    next_rdata_lower = rdata_lower;
    full_rdata = 0;

    if((state == CALC || state == G_PASS1 || state == G_PASS2) && r_flag_fifo_to_rclk)
    begin
        if(read_half == 0)
        begin
            next_rdata_lower = r_fifo_rdata;
            next_read_half = 1;
        end
        else // read_half == 1
        begin
            next_read_half = 0;
            full_rdata = {r_fifo_rdata, rdata_lower};
        end
    end

end

assign r_fifo_rinc = next_r_rinc;

always @(*) 
begin
    r_valid = r_flag_fifo_to_rclk && read_half; // only assert r_valid when the second half of data is read and valid
    r_data  = (read_half) ? full_rdata : 0;
end
assign r_ready = (state == CALC) || (state == G_PASS1) || (state == G_PASS2);

// wait data
always @(*) 
begin
    next_wait_data_ct = wait_data_ct; 

    if (state == CALC && !ar_out_valid && !ar_fifo_full) 
    begin
        if (start_tree_valid || (next_left_valid && stack_update) || (next_right_valid && stack_update)) 
        begin
            next_wait_data_ct = 2; // Wait for 2 clock cycles
        end
    end

    if(state == CALC && wait_data_ct > 0 && !r_fifo_empty)
    begin
        next_wait_data_ct = wait_data_ct - 1;
    end
    
end

// calc
always @(*)
begin
    for (i = 0; i < 16; i = i + 1)
    begin
        next_stack[i] = stack[i];
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        next_calc_result[i] = calc_result[i];
    end
    num1 = 0;
    num2 = 0;
    result = 0;
    next_calc_ct = calc_ct;
    next_start_tree_valid = start_tree_valid;
    next_stack_ct = stack_ct;
    stack_update = 0;

    if(state == CALC && r_flag_fifo_to_rclk && read_half) //calc read data
    begin
        if(full_rdata[63] == 0) //number
            next_stack[0] = {1'b1, 1'b0, {33{full_rdata[62]}}, full_rdata[62:32]}; //{valid, type, data}
        else if(full_rdata[63] == 1) //operator
            next_stack[0] = {1'b1, 1'b1, full_rdata[63:0]};

        next_stack[1:15] = stack[0:14];
        next_stack_ct = stack_ct + 1;
        
        stack_update = 1;
    end

    if(state == CALC && ar_out_valid) //calc read addr handshake
    begin
        next_start_tree_valid = 0;
    end

    if(stack[0][64] == 0 && stack[1][64] == 0 && stack[2][64] == 1 && state == CALC) //both number, do operation
    begin
        next_stack[15] = 0;
        next_stack[14] = 0;
        next_stack[1:13] = stack[3:15];
        num1 = stack[1][63:0];
        num2 = stack[0][63:0];
        case(stack[2][33:32])
            0: result = num1 + num2;//add
            1: result = num1 - num2;//sub
            2: result = num1 * num2;//mul
            3: result = num1 >>> num2[5:0];//shift right
            default: result = 0;
        endcase
        next_stack[0] = {1'b1, 1'b0, result[63:0]};
        stack_update = 1;
    end

    if(stack[0][64] == 0 && state == CALC && stack[0][65] != 0) //calc done
    begin
        if((stack[1] | stack[2] | stack[3] | stack[4] | stack[5] | stack[6] | stack[7] | stack[8] 
            | stack[9] | stack[10] | stack[11] | stack[12] | stack[13] | stack[14] | stack[15]) == 0) //tree done
        begin
            next_calc_result[3] = stack[0][63:0];
            next_calc_result[0:2] = calc_result[1:3];
            next_calc_ct = calc_ct + 1;
            next_start_tree_valid = 1;
            next_stack[0] = 0;
            stack_update = 1;
        end
    end

    if(state == IDLE) //calc reset
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            next_calc_result[i] = 0;
        end
        next_calc_ct = 0;
        next_start_tree_valid = 0;
    end

    if(state == IDLE && next_state == CALC)
    begin
        next_start_tree_valid = 1;
    end

end
//left right valid
always @(*)
begin
    next_left_valid = 0;
    next_right_valid = 0;

    if(next_stack[0][64] == 1)//operator
    begin
        next_left_valid = 1;
    end
    else if(next_stack[0][64] == 0 && next_stack[0][65] != 0)//number
    begin
        next_right_valid = 1;
    end

    if(next_stack[0][64] == 0 && next_stack[1][64] == 0 && next_stack[2][64] == 1 && state == CALC)
    begin
        next_left_valid = 0;
        next_right_valid = 0;
    end

    if(next_stack[0][64] == 0 && state == CALC && next_stack[0][65] != 0) //calc done
    begin
        if((next_stack[1] | next_stack[2] | next_stack[3] | next_stack[4] | next_stack[5] | next_stack[6] | next_stack[7] | next_stack[8] 
            | next_stack[9] | next_stack[10] | next_stack[11] | next_stack[12] | next_stack[13] | next_stack[14] | next_stack[15]) == 0) //tree done
        begin
            next_left_valid = 0;
            next_right_valid = 0;
        end
    end
end
// guass
always @(*)
begin
    next_sum = sum;
    next_sq_sum = sq_sum;
    next_threshold = threshold;
    guass_a = 0; guass_b = 0; guass_diff_sq = 0;
    next_n_ct = n_ct;
    next_r_ct = r_ct;
    next_guass_abs_diff = 0;
    next_pipe_valid = pipe_valid;
    next_rdata_temp = rdata_temp;
    next_pipe_last = pipe_last;
    next_term1 = term1;
    next_term2 = term2;

    if(state == G_PASS1 && r_flag_fifo_to_rclk && read_half)
    begin
        next_r_ct = r_ct + 1;

        if(full_rdata[63] == 0) //number
        begin
            next_n_ct = n_ct + 1;
            next_sum = sum + full_rdata[62:32];
            next_sq_sum = sq_sum + (full_rdata[62:32] * full_rdata[62:32]);
        end
    end
    else if(state == G_CALC)
    begin
        if(r_ct == 1024)
        begin
            next_term1 = n_ct * sq_sum;
            next_term2 = sum * sum;
            next_r_ct = 1025;
        end
        else if(r_ct == 1025)
        begin
            next_threshold = term1 - term2;
            next_r_ct = 0;
        end
        //next_threshold = (n_ct * sq_sum) - (sum * sum);
    end
    else if(state == G_PASS2 && r_flag_fifo_to_rclk && read_half)
    begin
        next_r_ct = r_ct + 1;
        guass_a = n_ct * full_rdata[62:32];
        guass_b = sum;
        next_guass_abs_diff = (guass_a > guass_b) ? (guass_a - guass_b) : (guass_b - guass_a);
        next_pipe_valid = 1;
        next_rdata_temp = full_rdata;
        next_pipe_last = (r_ct == 1023) ? 1 : 0;
    end

    if(pipe_valid)
    begin
        guass_diff_sq = guass_abs_diff * guass_abs_diff;
    end
    if (state == G_PASS2 && pipe_valid && !out_fifo_full && !pedding_upper) 
    begin
        next_pipe_valid = 0; 
    end

    if(state == IDLE)
    begin
        next_sum = 0;
        next_sq_sum = 0;
        next_threshold = 0;
        next_n_ct = 0;
        next_r_ct = 0;
        next_guass_abs_diff = 0;
        next_rdata_temp = 0;
    end

end

// output
always @(*)
begin
    next_out_valid = 0;
    next_out_data = 0;
    next_out_ct = out_ct;
    next_write_half = write_half;
    next_pedding_upper = pedding_upper;
    next_upper_data = upper_data;

    if(state == OUT && out_ct < 4 && !flag_fifo_to_clk2)
    begin
        next_out_valid = 1;
        if(write_half == 0)
        begin
            next_out_data = calc_result[out_ct][31:0];
            next_write_half = 1;
        end
        else // write_half == 1
        begin
            next_out_data = calc_result[out_ct][63:32];
            next_write_half = 0;
            next_out_ct = out_ct + 1;
        end
    end
    else if(pedding_upper && !flag_fifo_to_clk2)// previous upper data pedding, output it first
    begin
        next_out_valid = 1;
        next_out_data = upper_data;
        next_pedding_upper = 0;
    end
    else if(state == G_PASS2)
    begin
        if(pipe_valid && !flag_fifo_to_clk2)
        begin
            if((rdata_temp[63] == 0 && guass_diff_sq <= threshold) || pipe_last) // ensure the last data can be output even if it is outlier
            begin
                next_out_valid = 1;
                next_out_data = rdata_temp[31:0];
                next_upper_data = rdata_temp[63:32];
                next_pedding_upper = 1;
            end
        end
    end

    if(out_ct == 4)
    begin
        next_out_ct = 0;
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            bank[i] <= 0;
            src_row[i] <= 0;
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            stack[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            calc_result[i] <= 0;
        end
        mode <= 0;
        rcv_ct <= 0;
        state <= 0;
        ar_out_valid <= 0;
        ar_out_data <= 0;
        ar_ct <= 0;
        r_ct <= 0;
        left_valid <= 0;
        right_valid <= 0;
        start_tree_valid <= 0;
        calc_ct <= 0;
        stack_ct <= 0;
        r_rinc <= 0;
        wait_data_ct <= 0;
        out_valid <= 0;
        out_data <= 0;
        out_ct <= 0;
        n_ct <= 0;
        sum <= 0;
        sq_sum <= 0;
        threshold <= 0;
        guass_abs_diff <= 0;
        pipe_valid <= 0;
        rdata_temp <= 0;
        req_ct <= 0;
        pipe_last <= 0;
        read_half <= 0;
        rdata_lower <= 0;
        write_half <= 0;
        pedding_upper <= 0;
        upper_data <= 0;
        term1 <= 0;
        term2 <= 0;
    end
    else
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            bank[i] <= next_bank[i];
            src_row[i] <= next_src_row[i];
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            stack[i] <= next_stack[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            calc_result[i] <= next_calc_result[i];
        end
        mode <= next_mode;
        rcv_ct <= next_rcv_ct;
        state <= next_state;
        ar_out_valid <= next_ar_out_valid;
        ar_out_data <= next_ar_out_data;
        ar_ct <= next_ar_ct;
        r_ct <= next_r_ct;
        left_valid <= next_left_valid;
        right_valid <= next_right_valid;
        start_tree_valid <= next_start_tree_valid;
        calc_ct <= next_calc_ct;
        stack_ct <= next_stack_ct;
        r_rinc <= next_r_rinc;
        wait_data_ct <= next_wait_data_ct;
        out_valid <= next_out_valid;
        out_data <= next_out_data;
        out_ct <= next_out_ct;
        n_ct <= next_n_ct;
        sum <= next_sum;
        sq_sum <= next_sq_sum;
        threshold <= next_threshold;
        guass_abs_diff <= next_guass_abs_diff;
        pipe_valid <= next_pipe_valid;
        rdata_temp <= next_rdata_temp;
        req_ct <= next_req_ct;
        pipe_last <= next_pipe_last;
        read_half <= next_read_half;
        rdata_lower <= next_rdata_lower;
        write_half <= next_write_half;
        pedding_upper <= next_pedding_upper;
        upper_data <= next_upper_data;
        term1 <= next_term1;
        term2 <= next_term2;
    end
end

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    
    r_fifo_full,
    r_out_valid,
    r_out_data,

	ar_fifo_empty,
    ar_fifo_rdata,
    ar_fifo_rinc,

    ar_flag_fifo_to_rclk,
    ar_flag_rclk_to_fifo,

	r_flag_fifo_to_wclk,
    r_flag_wclk_to_fifo,

	ar_addr, 
    ar_valid, 
    ar_ready,
    r_data,  
    // r_resp, 
    r_valid, 
    r_ready,

	dram_cmd,  // {CS_n, RAS_n, CAS_n, WE_n}
    dram_ba,
    dram_addr,
    dram_wdata,
    dram_rdata,
    dram_valid
);
input 			clk;
input 			rst_n;

input  		ar_fifo_empty;
output reg		ar_fifo_rinc;
input [31:0] 	ar_fifo_rdata;

input 			r_fifo_full;
output reg 		r_out_valid;
output reg [31:0] r_out_data;
// You can use the the custom flag ports for your design
input  			ar_flag_fifo_to_rclk,r_flag_fifo_to_wclk;
output 			ar_flag_rclk_to_fifo,r_flag_wclk_to_fifo;


output [31:0] ar_addr;
output reg    ar_valid;
output        ar_ready;
output [63:0] r_data;
output        r_valid;
output reg    r_ready;

output reg  [3:0]  dram_cmd;  // {CS_n, RAS_n, CAS_n, WE_n}
output reg  [1:0]  dram_ba;
output reg  [10:0] dram_addr;
output reg  [63:0] dram_wdata;
input [63:0] dram_rdata;
input        dram_valid;

// ==========================================
// Declare
// ==========================================
parameter P3 = 0;
parameter A0 = 1;
parameter A1 = 2;
parameter A2 = 3;
parameter A3 = 4;
parameter A4 = 5;
parameter A5 = 6;
parameter P0 = 7;
parameter P1 = 8;
parameter P2 = 9;

reg [3:0] state_b0, next_state_b0, state_b1, next_state_b1, state_b2, next_state_b2, state_b3, next_state_b3;

reg [3:0] next_dram_cmd;
reg [1:0] next_dram_ba;
reg [10:0] next_dram_addr;
reg [63:0] next_dram_wdata;
reg [16:0] queue_addr [0:7];
reg [16:0] next_queue_addr [0:7];

reg [3:0] queue_ct, next_queue_ct;
reg [63:0] queue_rdata [0:7];
reg [63:0] next_queue_rdata [0:7];
//reg dram_valid_buf, next_dram_valid_buf;
reg [3:0] queue_rdata_ct, next_queue_rdata_ct;
reg [5:0] b0_row, next_b0_row, b1_row, next_b1_row, b2_row, next_b2_row, b3_row, next_b3_row;
//reg rdata_not_empty, next_rdata_not_empty;
reg internal_ar_valid, internal_ar_ready;
reg [31:0] internal_ar_addr;
reg internal_r_valid, internal_r_ready;
reg [63:0] internal_r_data;
reg push_state, next_push_state;
reg [31:0] r_data_temp, next_r_data_temp;
reg ar_handshake, dram_read, r_handshake;
reg next_r_out_valid;
reg [31:0] next_r_out_data;
reg as_active, next_as_active;
reg stall_signal, next_stall_signal;
reg ar_rinc_d1, ar_rinc_d2;
reg [2:0] read_inflight_ct, next_read_inflight_ct;
reg c0_valid, c1_valid, c2_valid, next_c0_valid, next_c1_valid, next_c2_valid, c3_valid, next_c3_valid;
reg c0_ready, c1_ready, c2_ready, next_c0_ready, next_c1_ready, next_c2_ready, c3_ready, next_c3_ready;
reg [31:0] q0 [0:1], next_q0 [0:1], q1 [0:1], next_q1 [0:1], q2 [0:1], next_q2 [0:1], q3 [0:1], next_q3 [0:1];
reg [2:0] q0_ct, next_q0_ct, q1_ct, next_q1_ct, q2_ct, next_q2_ct, q3_ct, next_q3_ct;
reg ex_ar_valid;
reg [31:0] ex_ar_addr;

integer i;

// ==========================================
// Design
// ==========================================
assign ar_flag_rclk_to_fifo = 0;
assign r_flag_wclk_to_fifo = 0;
// active
always @(*)
begin
    next_as_active = as_active;

    next_as_active = 1;
end

always @(*)
begin
    for (i = 0; i < 2; i = i + 1)
    begin
        next_q0[i] = q0[i];
        next_q1[i] = q1[i];
        next_q2[i] = q2[i];
        next_q3[i] = q3[i];
    end
    next_q0_ct = q0_ct;
    next_q1_ct = q1_ct;
    next_q2_ct = q2_ct;
    next_q3_ct = q3_ct;
    next_c0_valid = c0_valid;
    next_c1_valid = c1_valid;
    next_c2_valid = c2_valid;
    next_c3_valid = c3_valid;
    next_c0_ready = c0_ready;
    next_c1_ready = c1_ready;
    next_c2_ready = c2_ready;
    next_c3_ready = c3_ready;

    // c0
    /*if(ex_ar_valid && c0_ready || ((!(c0_valid && c1_ready)) && c0_valid))
        next_c0_valid = 1;
    else
        next_c0_valid = 0;*/

    if(ex_ar_valid && c0_ready && !(c0_valid && c1_ready))
    begin
        next_q0[q0_ct] = ex_ar_addr;
        next_q0_ct = q0_ct + 1;
    end
    else if(!(ex_ar_valid && c0_ready) && c0_valid && c1_ready)
    begin
        next_q0[1] = 0;
        next_q0[0] = q0[1];
        next_q0_ct = q0_ct - 1;
    end
    else if(ex_ar_valid && c0_ready && c0_valid && c1_ready)
    begin
        next_q0[1] = 0;
        next_q0[0] = q0[1];
        next_q0[q0_ct - 1] = ex_ar_addr;
        next_q0_ct = q0_ct;
    end

    if(next_q0_ct != 0)
        next_c0_valid = 1;
    else
        next_c0_valid = 0;

    next_c0_ready = (next_q0_ct < 2);

    //c1
    /*if(c0_valid && c1_ready || ((!(c1_valid && c2_ready)) && c1_valid))
        next_c1_valid = 1;
    else
        next_c1_valid = 0;*/

    if(c0_valid && c1_ready && !(c1_valid && c2_ready))
    begin
        next_q1[q1_ct] = q0[0];
        next_q1_ct = q1_ct + 1;
    end
    else if(!(c0_valid && c1_ready) && c1_valid && c2_ready)
    begin
        next_q1[1] = 0;
        next_q1[0] = q1[1];
        next_q1_ct = q1_ct - 1;
    end
    else if(c0_valid && c1_ready && c1_valid && c2_ready)
    begin
        next_q1[1] = 0;
        next_q1[0] = q1[1];
        next_q1[q1_ct - 1] = q0[0];
        next_q1_ct = q1_ct;
    end

    if(next_q1_ct != 0)
        next_c1_valid = 1;
    else
        next_c1_valid = 0;

    next_c1_ready = (next_q1_ct < 2);

    //c2
    /*if(c1_valid && c2_ready || ((!(c2_valid && c3_ready)) && c2_valid))
        next_c2_valid = 1;
    else
        next_c2_valid = 0;*/

    if(c1_valid && c2_ready && !(c2_valid && c3_ready))
    begin
        next_q2[q2_ct] = q1[0];
        next_q2_ct = q2_ct + 1;
    end
    else if(!(c1_valid && c2_ready) && c2_valid && c3_ready)
    begin
        next_q2[1] = 0;
        next_q2[0] = q2[1];
        next_q2_ct = q2_ct - 1;
    end
    else if(c1_valid && c2_ready && c2_valid && c3_ready)
    begin
        next_q2[1] = 0;
        next_q2[0] = q2[1];
        next_q2[q2_ct - 1] = q1[0];
        next_q2_ct = q2_ct;
    end

    if(next_q2_ct != 0)
        next_c2_valid = 1;
    else
        next_c2_valid = 0;

    next_c2_ready = (next_q2_ct < 2);

    //c3
    /*if(c2_valid && c3_ready || ((!(c3_valid && internal_ar_ready)) && c3_valid))
        next_c3_valid = 1;
    else
        next_c3_valid = 0;*/

    if(c2_valid && c3_ready && !(c3_valid && internal_ar_ready))
    begin
        next_q3[q3_ct] = q2[0];
        next_q3_ct = q3_ct + 1;
    end
    else if(!(c2_valid && c3_ready) && c3_valid && internal_ar_ready)
    begin
        next_q3[1] = 0;
        next_q3[0] = q3[1];
        next_q3_ct = q3_ct - 1;
    end
    else if(c2_valid && c3_ready && c3_valid && internal_ar_ready)
    begin
        next_q3[1] = 0;
        next_q3[0] = q3[1];
        next_q3[q3_ct - 1] = q2[0];
        next_q3_ct = q3_ct;
    end

    if(next_q3_ct != 0)
        next_c3_valid = 1;
    else
        next_c3_valid = 0;
    next_c3_ready = (next_q3_ct < 2);

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 2; i = i + 1)
        begin
            q0[i] <= 0;
            q1[i] <= 0;
            q2[i] <= 0;
            q3[i] <= 0;
        end
        c0_valid <= 0;
        c1_valid <= 0;
        c2_valid <= 0;
        q0_ct <= 0;
        q1_ct <= 0;
        q2_ct <= 0;
        q3_ct <= 0;
        c0_ready <= 0;
        c1_ready <= 0;
        c2_ready <= 0;
        c3_valid <= 0;
        c3_ready <= 0;
    end
    else
    begin
        for (i = 0; i < 2; i = i + 1)
        begin
            q0[i] <= next_q0[i];
            q1[i] <= next_q1[i];
            q2[i] <= next_q2[i];
            q3[i] <= next_q3[i];
        end
        c0_valid <= next_c0_valid;
        c1_valid <= next_c1_valid;
        c2_valid <= next_c2_valid;
        c3_valid <= next_c3_valid;
        q0_ct <= next_q0_ct;
        q1_ct <= next_q1_ct;
        q2_ct <= next_q2_ct;
        q3_ct <= next_q3_ct;
        c0_ready <= next_c0_ready;
        c1_ready <= next_c1_ready;
        c2_ready <= next_c2_ready;
        c3_ready <= next_c3_ready;
    end
end
// internal
always @(*)
begin
    ex_ar_valid = ar_flag_fifo_to_rclk;
    ex_ar_addr = ar_fifo_rdata;
    //internal_ar_valid = ar_flag_fifo_to_rclk;
    //internal_ar_valid = ar_rinc_d2;
    //internal_ar_addr = ar_fifo_rdata;
    internal_ar_ready = (queue_ct < 8) && as_active;

    internal_r_valid = (queue_rdata_ct > 0);
    internal_r_ready = (push_state == 0) && !r_flag_fifo_to_wclk && as_active;
    internal_r_data = queue_rdata[0];

    internal_ar_valid = internal_ar_valid;
    internal_ar_addr = internal_ar_addr;
    if(c3_valid && internal_ar_ready)
    begin
        internal_ar_valid = 1;
        internal_ar_addr = q3[0];
    end
    else
    begin
        internal_ar_valid = 0;
        internal_ar_addr = 0;
    end

end
// pattern use
always @(*)
begin
    ar_valid = internal_ar_valid;
    //ar_fifo_rinc = !ar_fifo_empty && (queue_ct < 6) && as_active;
    ar_fifo_rinc = !ar_fifo_empty && c2_ready && as_active;
    r_ready = internal_r_ready;
end
assign ar_addr = internal_ar_valid ? internal_ar_addr : 0;
assign ar_ready = internal_ar_ready;
assign r_data = internal_r_valid ? internal_r_data : 0;
assign r_valid = internal_r_valid;

// state
always @(*)
begin
    next_state_b0 = state_b0;
    next_state_b1 = state_b1;
    next_state_b2 = state_b2;
    next_state_b3 = state_b3;

    case(state_b0)
        P3:
        begin
            next_state_b0 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b00) ? A0 : P3;
        end
        A0: next_state_b0 = A1;
        A1: next_state_b0 = A2;
        A2: next_state_b0 = A3;
        A3: next_state_b0 = A4;
        A4: next_state_b0 = A5;
        A5: 
        begin
            next_state_b0 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b00) ? P0 : A5;
        end
        P0: next_state_b0 = P1;
        P1: next_state_b0 = P2;
        P2: next_state_b0 = P3;
        default: next_state_b0 = P3;
    endcase

    case(state_b1)
        P3:
        begin
            next_state_b1 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b01) ? A0 : P3;
        end
        A0: next_state_b1 = A1;
        A1: next_state_b1 = A2;
        A2: next_state_b1 = A3;
        A3: next_state_b1 = A4;
        A4: next_state_b1 = A5;
        A5: 
        begin
            next_state_b1 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b01) ? P0 : A5;
        end
        P0: next_state_b1 = P1;
        P1: next_state_b1 = P2;
        P2: next_state_b1 = P3;
        default: next_state_b1 = P3;
    endcase

    case(state_b2)
        P3:
        begin
            next_state_b2 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b10) ? A0 : P3;
        end
        A0: next_state_b2 = A1;
        A1: next_state_b2 = A2;
        A2: next_state_b2 = A3;
        A3: next_state_b2 = A4;
        A4: next_state_b2 = A5;
        A5: 
        begin
            next_state_b2 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b10) ? P0 : A5;
        end
        P0: next_state_b2 = P1;
        P1: next_state_b2 = P2;
        P2: next_state_b2 = P3;
        default: next_state_b2 = P3;
    endcase

    case(state_b3)
        P3:
        begin
            next_state_b3 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b11) ? A0 : P3;
        end
        A0: next_state_b3 = A1;
        A1: next_state_b3 = A2;
        A2: next_state_b3 = A3;
        A3: next_state_b3 = A4;
        A4: next_state_b3 = A5;
        A5: 
        begin
            next_state_b3 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b11) ? P0 : A5;
        end
        P0: next_state_b3 = P1;
        P1: next_state_b3 = P2;
        P2: next_state_b3 = P3;
        default: next_state_b3 = P3;
    endcase
end
// dram cmd
always @(*)
begin
    next_dram_cmd = 4'b0111; //default NOP
    next_dram_ba = dram_ba;
    next_dram_addr = dram_addr;
    next_dram_wdata = dram_wdata;

    if((state_b0 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b00) ||
       (state_b1 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b01) ||
       (state_b2 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b10) ||
       (state_b3 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b11)
    ) //issue ACT
    begin
        next_dram_cmd = 4'b0011;
        next_dram_ba = queue_addr[0][15:14];
        next_dram_addr = {5'b00000, queue_addr[0][13:8]};
        next_dram_wdata = 0;
    end

    if(((state_b0 == A2 || state_b0 == A3 || state_b0 == A4 || state_b0 == A5) && queue_addr[0][15:14] == 2'b00) ||
        ((state_b1 == A2 || state_b1 == A3 || state_b1 == A4 || state_b1 == A5) && queue_addr[0][15:14] == 2'b01) ||
        ((state_b2 == A2 || state_b2 == A3 || state_b2 == A4 || state_b2 == A5) && queue_addr[0][15:14] == 2'b10) ||
        ((state_b3 == A2 || state_b3 == A3 || state_b3 == A4 || state_b3 == A5) && queue_addr[0][15:14] == 2'b11) 
    ) //issue READ or WRITE
    begin
        if(queue_ct != 0 && !stall_signal)
        begin
            if(queue_addr[0][16] == 1'b0) //read
            begin
                next_dram_cmd = 4'b0101;
                next_dram_ba = queue_addr[0][15:14];
                next_dram_addr = {3'b000, queue_addr[0][7:0]};
                next_dram_wdata = 0;
            end
        end
    end

    if(((state_b0 == A3 || state_b0 == A4) && queue_addr[0][15:14] == 2'b00 && queue_addr[0][13:8] != b0_row) ||
       ((state_b1 == A3 || state_b1 == A4) && queue_addr[0][15:14] == 2'b01 && queue_addr[0][13:8] != b1_row) ||
       ((state_b2 == A3 || state_b2 == A4) && queue_addr[0][15:14] == 2'b10 && queue_addr[0][13:8] != b2_row) ||
       ((state_b3 == A3 || state_b3 == A4) && queue_addr[0][15:14] == 2'b11 && queue_addr[0][13:8] != b3_row)
    ) //precharge nop
    begin
        next_dram_cmd = 4'b0111; //NOP for one cycle
        next_dram_ba = 0;
        next_dram_addr = 0;
        next_dram_wdata = 0;
    end

    if(((state_b0 == A5) && queue_addr[0][15:14] == 2'b00 && queue_addr[0][13:8] != b0_row) ||
       ((state_b1 == A5) && queue_addr[0][15:14] == 2'b01 && queue_addr[0][13:8] != b1_row) ||
       ((state_b2 == A5) && queue_addr[0][15:14] == 2'b10 && queue_addr[0][13:8] != b2_row) ||
       ((state_b3 == A5) && queue_addr[0][15:14] == 2'b11 && queue_addr[0][13:8] != b3_row)
    ) //issue precharge
    begin
        next_dram_cmd = 4'b0010;
        next_dram_ba = queue_addr[0][15:14];
        next_dram_addr = 0;
        next_dram_wdata = 0;
    end
end

always @(*)
begin
    next_b0_row = b0_row;
    next_b1_row = b1_row;
    next_b2_row = b2_row;
    next_b3_row = b3_row;

    if(state_b0 == A0)
        next_b0_row = queue_addr[0][13:8];
    if(state_b1 == A0)
        next_b1_row = queue_addr[0][13:8];
    if(state_b2 == A0)
        next_b2_row = queue_addr[0][13:8];
    if(state_b3 == A0)
        next_b3_row = queue_addr[0][13:8];
end
// ar
always @(*)
begin
    ar_handshake = internal_ar_valid && internal_ar_ready;
    dram_read = (next_dram_cmd == 4'b0101);
    for (i = 0; i < 8; i = i + 1)
    begin
        next_queue_addr[i] = queue_addr[i];
    end
    next_queue_ct = queue_ct;

    if(ar_handshake && !dram_read && queue_ct < 8)
    begin
        next_queue_addr[queue_ct] = internal_ar_addr[15:0];
        next_queue_ct = queue_ct + 1;
    end
    else if(!ar_handshake && dram_read)
    begin
        next_queue_addr[0:6] = queue_addr[1:7];
        next_queue_addr[7] = 0;
        next_queue_ct = queue_ct - 1;
    end
    else if(ar_handshake && dram_read)
    begin
        next_queue_addr[0:6] = queue_addr[1:7];
        next_queue_addr[7] = 0;
        next_queue_addr[queue_ct - 1] = internal_ar_addr[15:0];
        next_queue_ct = queue_ct; // remain the same, one in one out
    end

end
// r
always @(*)
begin
    r_handshake = internal_r_valid && internal_r_ready;
    for (i = 0; i < 8; i = i + 1)
    begin
        next_queue_rdata[i] = queue_rdata[i];
    end
    next_queue_rdata_ct = queue_rdata_ct;

    if(dram_valid && !r_handshake)
    begin
        next_queue_rdata[queue_rdata_ct] = dram_rdata;
        next_queue_rdata_ct = queue_rdata_ct + 1;
    end
    else if(!dram_valid && r_handshake)
    begin
        next_queue_rdata[0:6] = queue_rdata[1:7];
        next_queue_rdata[7] = 0;
        next_queue_rdata_ct = queue_rdata_ct - 1;
    end
    else if(dram_valid && r_handshake)
    begin
        next_queue_rdata[0:6] = queue_rdata[1:7];
        next_queue_rdata[7] = 0;
        next_queue_rdata[queue_rdata_ct - 1] = dram_rdata;
        next_queue_rdata_ct = queue_rdata_ct; // remain the same, one in one out
    end

end
// read_inflight count
always @(*)
begin
    next_read_inflight_ct = read_inflight_ct;

    if (dram_read && !dram_valid)
        next_read_inflight_ct = read_inflight_ct + 1;
    else if (!dram_read && dram_valid)
        next_read_inflight_ct = read_inflight_ct - 1;

end
// stall signal
always @(*)
begin
    next_stall_signal = stall_signal;

    //next_stall_signal = (queue_rdata_ct != 0) && (!r_handshake);
    next_stall_signal = (queue_rdata_ct >= 2);
    //stall_signal = (queue_rdata_ct + read_inflight_ct >= 6) >= 5;
end
// 64 to 32 output
always @(*)
begin
    next_push_state = push_state;
    next_r_out_valid = 0;
    next_r_out_data = 0;
    next_r_data_temp = r_data_temp;

    if(push_state == 0)//output lower 32 bits
    begin
        if(internal_r_valid && !r_flag_fifo_to_wclk)
        begin
            next_r_out_valid = 1;
            next_r_out_data = internal_r_data[31:0]; //output lower 32 bits first
            next_r_data_temp = internal_r_data[63:32]; //store upper 32 bits in temp reg
            next_push_state = 1;
        end
    end
    else
    begin
        if(!r_flag_fifo_to_wclk) //output upper 32 bits in the next cycle
        begin
            next_r_out_valid = 1;
            next_r_out_data = r_data_temp; //output upper 32 bits
            next_r_data_temp = 0;
            next_push_state = 0;
        end
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 8; i = i + 1)
        begin
            queue_addr[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            queue_rdata[i] <= 0;
        end
        dram_cmd <= 0;
        dram_ba <= 0;
        dram_addr <= 0;
        dram_wdata <= 0;
        state_b0 <= 0;
        state_b1 <= 0;
        state_b2 <= 0;
        state_b3 <= 0;
        queue_ct <= 0;
        queue_rdata_ct <= 0;
        b0_row <= 0;
        b1_row <= 0;
        b2_row <= 0;
        b3_row <= 0;
        push_state <= 0;
        r_out_valid <= 0;
        r_out_data <= 0;
        r_data_temp <= 0;
        as_active <= 0;
        ar_rinc_d1 <= 0;
        ar_rinc_d2 <= 0;
        read_inflight_ct <= 0;
        stall_signal <= 0;
    end
    else
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            queue_addr[i] <= next_queue_addr[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            queue_rdata[i] <= next_queue_rdata[i];
        end
        dram_cmd <= next_dram_cmd;
        dram_ba <= next_dram_ba;
        dram_addr <= next_dram_addr;
        dram_wdata <= next_dram_wdata;
        state_b0 <= next_state_b0;
        state_b1 <= next_state_b1;
        state_b2 <= next_state_b2;
        state_b3 <= next_state_b3;
        queue_ct <= next_queue_ct;
        queue_rdata_ct <= next_queue_rdata_ct;
        b0_row <= next_b0_row;
        b1_row <= next_b1_row;
        b2_row <= next_b2_row;
        b3_row <= next_b3_row;
        push_state <= next_push_state;
        r_out_valid <= next_r_out_valid;
        r_out_data <= next_r_out_data;
        r_data_temp <= next_r_data_temp;
        as_active <= next_as_active;
        ar_rinc_d1 <= ar_fifo_rinc;
        ar_rinc_d2 <= ar_rinc_d1;
        read_inflight_ct <= next_read_inflight_ct;
        stall_signal <= next_stall_signal;
    end
end


endmodule
