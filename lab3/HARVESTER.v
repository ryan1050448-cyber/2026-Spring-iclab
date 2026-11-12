module HARVESTER(
    input               clk, 
    input               rst_n,
    input               in_mode_valid,
    input               in_valid,
    input       [1:0]   in_mode,
    input       [1:0]   in_bank,
    input       [5:0]   in_src_row,
    input       [5:0]   in_dst_row,
    input       [63:0]  in_data,
    output reg          out_valid,
    output reg  [63:0]  out_data,
    
    output reg  [31:0]  aw_addr, 
    output reg          aw_valid, 
    input               aw_ready,
    output reg  [63:0]  w_data,  
    output reg          w_valid,  
    input               w_ready,
    input       [1:0]   b_resp,  
    input               b_valid,  
    output reg          b_ready,
    output reg  [31:0]  ar_addr, 
    output reg          ar_valid, 
    input               ar_ready,
    input       [63:0]  r_data,  
    input       [1:0]   r_resp, 
    input wire          r_valid, 
    output reg          r_ready
);

parameter IDLE = 0;
parameter READ = 1;
parameter WRITE = 2;
parameter CALC = 3;
parameter SORT0 = 4;
parameter SORT1 = 5;
parameter SORT2 = 6;
parameter SORT3 = 7;
parameter SORT = 8;
parameter OUT = 9;

reg next_out_valid, next_aw_valid, next_ar_valid, next_w_valid, next_b_ready, next_r_ready;
reg [63:0] next_out_data, next_w_data;
reg [31:0] next_aw_addr, next_ar_addr;
reg [1:0] mode, next_mode, bank, next_bank;
reg [63:0] data [0:255];
reg [63:0] next_data [0:255];
reg [5:0] src_row, next_src_row, dst_row, next_dst_row;
reg [3:0] state, next_state;
reg [7:0] addr_ct, next_addr_ct, r_ct, next_r_ct;
reg [7:0] out_ct, next_out_ct, count, next_count;
reg [7:0] in_data_ct, next_in_data_ct;
reg [10:0] bresp_ct, next_bresp_ct;
reg left_valid, next_left_valid, right_valid, next_right_valid, start_tree_valid, next_start_tree_valid;
reg [65:0] stack [0:15];
reg [65:0] next_stack [0:15];
reg signed [63:0] num1, num2, result;
reg [63:0] calc_result [0:3];
reg [63:0] next_calc_result [0:3];
reg [2:0] calc_ct, next_calc_ct;
reg [2:0] sort_ct, next_sort_ct;
reg sort_rvalid, next_sort_rvalid, oesort_valid, next_oesort_valid, wback_valid, next_wback_valid;
reg [3:0] q0_ct, next_q0_ct, q1_ct, next_q1_ct, q2_ct, next_q2_ct, q3_ct, next_q3_ct;
reg [3:0] q0_ar_ct, next_q0_ar_ct, q1_ar_ct, next_q1_ar_ct, q2_ar_ct, next_q2_ar_ct, q3_ar_ct, next_q3_ar_ct;
reg [7:0] b0_ct, next_b0_ct, b1_ct, next_b1_ct, b2_ct, next_b2_ct, b3_ct, next_b3_ct;
reg [7:0] b0_2ct, next_b0_2ct, b1_2ct, next_b1_2ct, b2_2ct, next_b2_2ct, b3_2ct, next_b3_2ct;
reg [63:0] q0 [0:7];
reg [63:0] next_q0 [0:7];
reg [63:0] q1 [0:7];
reg [63:0] next_q1 [0:7];
reg [63:0] q2 [0:7];
reg [63:0] next_q2 [0:7];
reg [63:0] q3 [0:7];
reg [63:0] next_q3 [0:7];
reg [10:0] wback_ct, next_wback_ct;
reg [2:0] fill_queue [0:31];
reg [2:0] next_fill_queue [0:31];
reg [5:0] fq_ct, next_fq_ct;
reg [2:0] fill_queue_ad [0:31];
reg [2:0] next_fill_queue_ad [0:31];
reg [5:0] fqad_ct, next_fqad_ct;
reg in_mode_buf, next_in_mode_buf;
reg [3:0] stack_ct, next_stack_ct;
reg stack_update;
reg [10:0] sort_addr_ct, next_sort_addr_ct, sort_r_ct, next_sort_r_ct;
reg [2:0] addr_list [0:31];
reg [2:0] next_addr_list [0:31];
reg [6:0] list_ct, next_list_ct;

integer i, j;

//input
always @(*)
begin
    next_mode = mode;
    next_in_mode_buf = 0;

    if(in_mode_valid)
    begin
        next_mode = in_mode;
        next_in_mode_buf = in_mode;
    end

    next_bank = bank;
    next_src_row = src_row;
    next_dst_row = dst_row;

    if(in_valid)
    begin
        if(mode == 0) //read
        begin
            next_bank = in_bank;
            next_src_row = in_src_row;
        end
        else if(mode == 1 && in_mode_buf) //write
        begin
            next_bank = in_bank;
            next_dst_row = in_dst_row;
        end
        else if(mode == 2) //calc
        begin
            next_src_row = in_src_row;
        end
        else if(mode == 3)//sort
        begin
            next_src_row = in_src_row;
            next_dst_row = in_dst_row;
        end
    end
end
//axi state
always @(*)
begin
    next_state = state;
    case(state)
        IDLE:
        begin
            if(next_mode == 0 && in_mode_valid)//read
            begin
                next_state = READ;
            end
            else if(next_mode == 1 && in_mode_valid)//write
            begin
                next_state = WRITE;
            end
            else if(next_mode == 2 && in_mode_valid)//calc
            begin
                next_state = CALC;
            end
            else if(next_mode == 3 && in_mode_valid)//sort
            begin
                next_state = SORT0;
            end
            else
            begin
                next_state = IDLE;
            end
        end
        READ:
        begin
            if(r_ct == 255)
            begin
                next_state = OUT;
            end
            else
            begin
                next_state = READ;
            end
        end
        WRITE:
        begin
            if(bresp_ct == 256)
            begin
                next_state = OUT;
            end
            else
            begin
                next_state = WRITE;
            end
        end
        CALC:
        begin
            if(next_calc_ct == 4)
            begin
                next_state = OUT;
            end
            else
            begin
                next_state = CALC;
            end
        end
        SORT0:
        begin
            if(wback_ct == 255)
            begin
                next_state = SORT1;
            end
            else
            begin
                next_state = SORT0;
            end
        end
        SORT1:
        begin
            if(wback_ct == 255)
            begin
                next_state = SORT2;
            end
            else
            begin
                next_state = SORT1;
            end
        end
        SORT2:
        begin
            if(wback_ct == 255)
            begin
                next_state = SORT3;
            end
            else
            begin
                next_state = SORT2;
            end
        end
        SORT3:
        begin
            if(wback_ct == 255)
            begin
                next_state = SORT;
            end
            else
            begin
                next_state = SORT3;
            end
        end
        SORT:
        begin
            if(bresp_ct == 1024 && q0_ct == 0 && q1_ct == 0 && q2_ct == 0 && q3_ct == 0)
            begin
                next_state = OUT;
            end
            else
            begin
                next_state = SORT;
            end
        end
        OUT:
        begin
            if(mode == 0 && out_ct == 255)//read out
            begin
                next_state = IDLE;
            end
            else if(mode == 1 && out_ct == 0)//write out
            begin
                next_state = IDLE;
            end
            else if(mode == 2 && out_ct == 3)//calc out
            begin
                next_state = IDLE;
            end
            else if(mode == 3)
            begin
                next_state = IDLE;
            end
            else
             next_state = OUT;
        end
        default: next_state = IDLE;
    endcase
end
//axi read
always @(*)
begin
    next_ar_valid = ar_valid;
    next_ar_addr = ar_addr;
    next_r_ready = r_ready;
    next_list_ct = list_ct;
    for (i = 0; i < 32; i = i + 1)
    begin
        next_addr_list[i] = addr_list[i];
    end

    if(ar_valid && ar_ready) //read addr handshake
    begin
        next_ar_valid = 0;
        next_ar_addr = 0;
    end

    if(r_valid && r_ready) //read data handshake
    begin
        next_r_ready = 0;
    end

    if(state == READ)//read
    begin
        next_ar_valid = 1;
        next_ar_addr = {next_bank, next_src_row, next_addr_ct};
    end

    if(addr_ct == 255)//read done
    begin
        next_ar_valid = 0;
        next_ar_addr = 0;
    end

    if(r_ct != 255) //sort read addr handshake
    begin
        next_r_ready = 1;
    end
    

    //CALC
    if(state == CALC)
    begin
        if(in_valid || start_tree_valid) //calc first read
        begin
            next_ar_valid = 1;
            next_ar_addr = {next_calc_ct[1:0], next_src_row, 8'b0};
            next_r_ready = 1;
        end
        else if(next_left_valid && stack_update)
        begin
            next_ar_valid = 1;
            next_ar_addr = next_stack[0][31:16];
            next_r_ready = 1;
        end
        else if(next_right_valid && stack_update)        
        begin
            next_ar_valid = 1;
            next_ar_addr = next_stack[1][15:0];
            next_r_ready = 1;
        end
        
    end

    if(state == CALC && (ar_valid && ar_ready)) //calc read addr handshake
    begin
        next_ar_valid = 0;
        next_ar_addr = 0;
    end
    if(state == CALC && (r_valid && r_ready)) //calc read handshake
    begin
        next_r_ready = 0;
    end

    if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && next_sort_rvalid) //sort read
    begin
        if(sort_ct == 0)
        begin
            next_ar_valid = 1;
            next_ar_addr = {2'b00, next_src_row, next_addr_ct};
            //next_r_ready = 1;
        end
        else if(sort_ct == 1)
        begin
            next_ar_valid = 1;
            next_ar_addr = {2'b01, next_src_row, next_addr_ct};
            //next_r_ready = 1;
        end
        else if(sort_ct == 2)
        begin
            next_ar_valid = 1;
            next_ar_addr = {2'b10, next_src_row, next_addr_ct};
            //next_r_ready = 1;
        end
        else if(sort_ct == 3)
        begin
            next_ar_valid = 1;
            next_ar_addr = {2'b11, next_src_row, next_addr_ct};
            //next_r_ready = 1;
        end
    end

    if(state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3)
    begin
        if(r_ct != 255)
        begin
            next_r_ready = 1;
        end
    end

    if(state == SORT && ar_valid && ar_ready)
    begin
        if((ar_addr >= 32'h0000bf00 && ar_addr <= 32'h0000bf7f) || (ar_addr >= 32'h00003f00 && ar_addr <= 32'h00003f7f))
        begin
            next_addr_list[list_ct] = 1;
            next_list_ct = list_ct + 1;
        end
        else if((ar_addr >= 32'h0000bf80 && ar_addr <= 32'h0000bfff) || (ar_addr >= 32'h00003f80 && ar_addr <= 32'h00003fff))
        begin
            next_addr_list[list_ct] = 2;
            next_list_ct = list_ct + 1;
        end
        else if((ar_addr >= 32'h0000ff00 && ar_addr <= 32'h0000ff7f) || (ar_addr >= 32'h00007f00 && ar_addr <= 32'h00007f7f))
        begin
            next_addr_list[list_ct] = 3;
            next_list_ct = list_ct + 1;
        end
        else if((ar_addr >= 32'h0000ff80 && ar_addr <= 32'h0000ffff) || (ar_addr >= 32'h00007f80 && ar_addr <= 32'h00007fff))
        begin
            next_addr_list[list_ct] = 4;
            next_list_ct = list_ct + 1;
        end
    end
    if(state == SORT && r_valid && r_ready)
    begin
        next_addr_list[0:30] = addr_list[1:31];
        next_addr_list[31] = 0;
        next_list_ct = list_ct - 1;
    end

    if(state == SORT && ar_valid && ar_ready && r_valid && r_ready)
    begin
        next_addr_list[0:30] = addr_list[1:31];
        next_addr_list[31] = 0;
    
        if((ar_addr >= 32'h0000bf00 && ar_addr <= 32'h0000bf7f) || (ar_addr >= 32'h00003f00 && ar_addr <= 32'h00003f7f))
        begin
            next_addr_list[list_ct - 1] = 1;
            next_list_ct = list_ct;
        end
        else if((ar_addr >= 32'h0000bf80 && ar_addr <= 32'h0000bfff) || (ar_addr >= 32'h00003f80 && ar_addr <= 32'h00003fff))
        begin
            next_addr_list[list_ct - 1] = 2;
            next_list_ct = list_ct;
        end
        else if((ar_addr >= 32'h0000ff00 && ar_addr <= 32'h0000ff7f) || (ar_addr >= 32'h00007f00 && ar_addr <= 32'h00007f7f))
        begin
            next_addr_list[list_ct - 1] = 3;
            next_list_ct = list_ct;
        end
        else if((ar_addr >= 32'h0000ff80 && ar_addr <= 32'h0000ffff) || (ar_addr >= 32'h00007f80 && ar_addr <= 32'h00007fff))
        begin
            next_addr_list[list_ct - 1] = 4;
            next_list_ct = list_ct;
        end
    end
    //if(next_q0_ar_ct < 8 && (next_fill_queue_ad[0] == 1 || sort_addr_ct < 32) && next_b0_ct != 128)
    
    if(state == SORT && (wback_valid == 0)) 
    begin
        if(next_q0_ar_ct < 8 && (next_fill_queue_ad[0] == 1 || sort_addr_ct < 32) && next_b0_ct != 128)//q0 from bank2
        begin
            next_ar_valid = 1;
            if(next_b2_ct < 128)//read data from bank2
            begin
                next_ar_addr = {2'b10, 6'b111111, next_b2_ct};
            end
            else if(next_b0_ct < 128)//read data from bank0
            begin
                next_ar_addr = {2'b00, 6'b111111, next_b0_ct};
            end
        end
        else if(next_q1_ar_ct < 8 && (next_fill_queue_ad[0] == 2 || sort_addr_ct < 32) && next_b0_2ct != 128)
        begin
            next_ar_valid = 1;
            if(next_b2_2ct < 128)//read data from bank2
            begin
                next_ar_addr = {2'b10, 6'b111111, next_b2_2ct} + 128;
            end
            else if(next_b0_2ct < 128)//read data from bank0
            begin
                next_ar_addr = {2'b00, 6'b111111, next_b0_2ct} + 128;
            end
        end
        else if(next_q2_ar_ct < 8 && (next_fill_queue_ad[0] == 3 || sort_addr_ct < 32) && next_b1_ct != 128)
        begin
            next_ar_valid = 1;
            if(next_b3_ct < 128)//read data from bank3
            begin
                next_ar_addr = {2'b11, 6'b111111, next_b3_ct};
            end
            else if(next_b1_ct < 128)//read data from bank1
            begin
                next_ar_addr = {2'b01, 6'b111111, next_b1_ct};
            end
            
        end
        else if(next_q3_ar_ct < 8 && (next_fill_queue_ad[0] == 4 || sort_addr_ct < 32) && next_b1_2ct != 128)
        begin
            next_ar_valid = 1;
            if(next_b3_2ct < 128)//read data from bank3
            begin
                next_ar_addr = {2'b11, 6'b111111, next_b3_2ct} + 128;
            end
            else if(next_b1_2ct < 128)//read data from bank1
            begin
                next_ar_addr = {2'b01, 6'b111111, next_b1_2ct} + 128;
            end
        end

        if(q0_ct == 8 && q1_ct == 8 && q2_ct == 8 && q3_ct == 8)
            next_r_ready = 0;
        else
            next_r_ready = 1;

        if(ar_valid == 1 && ar_ready == 0)
            next_ar_addr = ar_addr;
        
    end

end
//axi write
always @(*)
begin
    next_aw_valid = aw_valid;
    next_aw_addr = aw_addr;
    next_w_valid = w_valid;
    next_w_data = w_data;
    next_b_ready = 1;
    next_wback_valid = wback_valid;
    next_wback_ct = wback_ct;

    if(aw_valid && aw_ready) //write addr handshake
    begin
        next_aw_valid = 0;
        next_aw_addr = 0;
    end

    if(w_valid && w_ready) //write data handshake
    begin
        next_w_valid = 0;
        next_w_data = 0;
    end

    if(state == WRITE && in_data_ct == 255) //write data
        next_wback_valid = 1;
    if(wback_ct == 255)
        next_wback_valid = 0;

    if(state == WRITE && wback_valid) //write address
    begin
        next_aw_valid = 1;
        next_aw_addr = {bank, dst_row, next_addr_ct};
        next_w_valid = 1;
        next_w_data = next_data[0];
    end

    
    if(state == WRITE && w_valid && w_ready) //write data handshake
    begin
        next_wback_ct = wback_ct + 1;
        if(wback_ct == 255)
            next_wback_ct = 0;
    end
    
    
    if(addr_ct == 255) //write done
    begin
        next_aw_valid = 0;
        next_aw_addr = 0;
        next_w_valid = 0;
        next_w_data = 0;
    end

    //sort *****************************
    if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && w_valid && w_ready) 
    begin
        next_wback_ct = wback_ct + 1;
        if(wback_ct == 255)            
            next_wback_ct = wback_ct;
    end

    if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && wback_ct != 255 && count == 255) //sort write
    begin
        next_aw_valid = 1;
        next_w_valid = 1;
        next_w_data = next_data[0];
        if(state == SORT0)
        begin
            if(wback_ct <= 126) //next_wback_ct <= 127
                next_aw_addr = {2'b10, 6'b111111, next_wback_ct[7:0]}; //bank2
            else //next_wback_ct 128-255
                next_aw_addr = {2'b00, 6'b111111, next_wback_ct[7:0]} - 128; //bank0
        end
        else if(state == SORT1)
        begin
            if(wback_ct <= 126) //next_wback_ct <= 127
                next_aw_addr = {2'b10, 6'b111111, next_wback_ct[7:0]} + 128; //bank2
            else //next_wback_ct 128-255
                next_aw_addr = {2'b00, 6'b111111, next_wback_ct[7:0]}; //bank1
        end
        else if(state == SORT2)
        begin
            if(wback_ct <= 126) //next_wback_ct <= 127
                next_aw_addr = {2'b11, 6'b111111, next_wback_ct[7:0]}; //bank3
            else //next_wback_ct 128-255
                next_aw_addr = {2'b01, 6'b111111, next_wback_ct[7:0]} - 128; //bank0
        end
        else if(state == SORT3)
        begin
            if(wback_ct <= 126) //next_wback_ct <= 127
                next_aw_addr = {2'b11, 6'b111111, next_wback_ct[7:0]} + 128; //bank3
            else //next_wback_ct 128-255
                next_aw_addr = {2'b01, 6'b111111, next_wback_ct[7:0]}; //bank0
        end
    end
    
    if(wback_ct == 255 && (state != SORT)) //write done
        next_wback_valid = 0;
    
    if((state == SORT0 && next_state == SORT1) || (state == SORT1 && next_state == SORT2) 
        || (state == SORT2 && next_state == SORT3) || (state == SORT3 && next_state == SORT))
        next_wback_ct = 0;

    if(state == SORT && w_valid && w_ready)
        next_wback_ct = wback_ct + 1;

    if(state == OUT)
        next_wback_ct = 0;

    if(state == SORT)
    begin
        if((q0_ct == 8 || (b0_ct == 128)) && (q1_ct == 8 || (b0_2ct == 128)) 
            && (q2_ct == 8 || (b1_ct == 128)) && (q3_ct == 8 || (b1_2ct == 128)))
        begin
            next_wback_valid = 1;
        end

        if(q0_ar_ct <= 1 || q1_ar_ct <= 1 || q2_ar_ct <= 1 || q3_ar_ct <= 1)
        begin
            next_wback_valid = 0;
        end

        if(b0_ct == 128 && q0_ct == 0) // list1 empty
        begin
            if((q1_ct == 0 && b0_2ct != 128) || (q2_ct == 0 && b1_ct != 128) || (q3_ct == 0 && b1_2ct != 128))
                next_wback_valid = 0;
        end
        if(b0_2ct == 128 && q1_ct == 0) // list2 empty
        begin
            if((q0_ct == 0 && b0_ct != 128) || (q2_ct == 0 && b1_ct != 128) || (q3_ct == 0 && b1_2ct != 128))
                next_wback_valid = 0;
        end
        if(b1_ct == 128 && q2_ct == 0) //list3 empty
        begin
            if((q0_ct == 0 && b0_ct != 128) || (q1_ct == 0 && b0_2ct != 128) || (q3_ct == 0 && b1_2ct != 128))
                next_wback_valid = 0;
        end
        if(b1_2ct == 128 && q3_ct == 0) //list4 empty
        begin
            if((q0_ct == 0 && b0_ct != 128) || (q1_ct == 0 && b0_2ct != 128) || (q2_ct == 0 && b1_ct != 128))
                next_wback_valid = 0;
        end


        if((b0_ct == 128 && addr_list[0] == 1) || (b0_2ct == 128 && addr_list[0] == 2) || (b1_ct == 128 && addr_list[0] == 3) || (b1_2ct == 128 && addr_list[0] == 4))
            next_wback_valid = 0;

        if(q0_ct == 0 && q1_ct == 0 && q2_ct == 0 && q3_ct == 0)
            next_wback_valid = 0;

        if(b0_ct == 128 && b0_2ct == 128 && b1_ct == 128 && b1_2ct == 128)
        begin
            if(next_q0_ct == 0 && next_q1_ct == 0 && next_q2_ct == 0 && next_q3_ct == 0)
                next_wback_valid = 0;
        end
            
    end


    if(state == SORT && next_wback_valid)//priority: q0, q1, q2, q3
    begin
        if(next_q0[0][62:32] <= next_q1[0][62:32] && next_q0[0][62:32] <= next_q2[0][62:32] && next_q0[0][62:32] <= next_q3[0][62:32]) //q0 min
        begin
            next_aw_valid = 1;
            next_w_valid = 1;
            next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
            next_w_data = next_q0[0][63:0];
        end
        else if(next_q1[0][62:32] < next_q0[0][62:32] && next_q1[0][62:32] <= next_q2[0][62:32] && next_q1[0][62:32] <= next_q3[0][62:32]) //q1 min
        begin
            next_aw_valid = 1;
            next_w_valid = 1;
            next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
            next_w_data = next_q1[0][63:0];
        end
        else if(next_q2[0][62:32] < next_q0[0][62:32] && next_q2[0][62:32] < next_q1[0][62:32] && next_q2[0][62:32] <= next_q3[0][62:32]) //q2 min
        begin
            next_aw_valid = 1;
            next_w_valid = 1;
            next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
            next_w_data = next_q2[0][63:0];
        end
        else//q3 min
        begin
            next_aw_valid = 1;
            next_w_valid = 1;
            next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
            next_w_data = next_q3[0][63:0];
        end


        if(next_q0[0][62:32] == 31'h7fffffff && next_q1[0][62:32] == 31'h7fffffff && next_q2[0][62:32] == 31'h7fffffff && next_q3[0][62:32] == 31'h7fffffff)
        begin
            if(q0_ct != 0 && b0_ct == 128)
            begin
                next_aw_valid = 1;
                next_w_valid = 1;
                next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
                //next_w_data = q0[0][63:0];
                if(next_q0[0] == 64'h7fffffffffffffff)
                    next_w_data = 64'h7fffffffffffffff;

                if(next_q0[0] == 64'hffffffffffffffff)
                    next_w_data = 64'hffffffffffffffff; 
                
            end
            if(q1_ct != 0 && b0_2ct == 128)
            begin
                next_aw_valid = 1;
                next_w_valid = 1;
                next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
                //next_w_data = q1[0][63:0];
                if(next_q1[0] == 64'h7fffffffffffffff)
                    next_w_data = 64'h7fffffffffffffff;

                if(next_q1[0] == 64'hffffffffffffffff)
                    next_w_data = 64'hffffffffffffffff;
            end
            if(q2_ct != 0 && b1_ct == 128)
            begin
                next_aw_valid = 1;
                next_w_valid = 1;
                next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
                //next_w_data = q2[0][63:0];
                if(next_q2[0] == 64'h7fffffffffffffff)
                    next_w_data = 64'h7fffffffffffffff;

                if(next_q2[0] == 64'hffffffffffffffff)
                    next_w_data = 64'hffffffffffffffff;
            end
            if(q3_ct != 0 && b1_2ct == 128)            
            begin
                next_aw_valid = 1;
                next_w_valid = 1;
                next_aw_addr = {next_wback_ct[9:8], dst_row, next_wback_ct[7:0]};
                //next_w_data = q3[0][63:0];
                if(next_q3[0] == 64'h7fffffffffffffff)
                    next_w_data = 64'h7fffffffffffffff;

                if(next_q3[0] == 64'hffffffffffffffff)
                    next_w_data = 64'hffffffffffffffff;
            end
        end

        
    end
    
    

end
//address counter and read counter
always @(*)
begin
    next_addr_ct = addr_ct;
    next_r_ct = r_ct;
    next_in_data_ct = in_data_ct;
    next_bresp_ct = bresp_ct;
    next_out_ct = out_ct;
    next_count = count;
    next_sort_addr_ct = sort_addr_ct;
    next_sort_r_ct = sort_r_ct;

    if(state == READ && (ar_valid && ar_ready))
    begin
        next_addr_ct = addr_ct + 1;
        if(addr_ct == 255)
            next_addr_ct = addr_ct;
    end
    else if(state == WRITE && (aw_valid && aw_ready))
    begin
        next_addr_ct = addr_ct + 1;
    end
    else if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && (ar_valid && ar_ready))
    begin
        next_addr_ct = addr_ct + 1;
    end
    
    if(state == SORT && (ar_valid && ar_ready))
    begin
        next_sort_addr_ct = sort_addr_ct + 1;
    end
    if(state == SORT && r_valid && r_ready)
    begin
        next_sort_r_ct = sort_r_ct + 1;
    end
    if(state != SORT)
    begin
        next_sort_addr_ct = 0;
        next_sort_r_ct = 0;
    end
        

    if(addr_ct == 255 && out_valid) //read or write done
    begin
        next_addr_ct = 0;
    end

    if(r_valid && r_ready)
    begin
        next_r_ct = r_ct + 1;
    end
    if(r_ct == 255 || state == OUT)
    begin
        next_r_ct = 0;
    end

    if(in_valid && mode == 1) //write data count
    begin
        next_in_data_ct = in_data_ct + 1;
    end
    if(in_data_ct == 255)
    begin
        next_in_data_ct = 0;
    end

    if(b_valid && b_ready && state == WRITE) //write response count
    begin
        next_bresp_ct = bresp_ct + 1;
    end
    if(state == WRITE && bresp_ct == 256)
    begin
        next_bresp_ct = 256;
    end
    if(state != WRITE && state != SORT)
    begin
        next_bresp_ct = 0;
    end

    if(state == SORT && b_valid && b_ready && (sort_addr_ct >= 32)) //sort write response count
    begin
        next_bresp_ct = bresp_ct + 1;
    end

    if(out_valid)
    begin
        next_out_ct = out_ct + 1;
    end
    if(state != OUT)
    begin
        next_out_ct = 0;
    end

    if(oesort_valid) //sort count
    begin
        next_count = count + 1;
    end
    if(count == 255)
    begin
        if(wback_ct == 255)
            next_count = 0;
        else
            next_count = count;
    end
end
//q0, q1, q2, q3
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        next_q0[i] = q0[i];
        next_q1[i] = q1[i];
        next_q2[i] = q2[i];
        next_q3[i] = q3[i];
    end
    for (j = 0; j < 32; j = j + 1)
    begin
        next_fill_queue[j] = fill_queue[j];
        next_fill_queue_ad[j] = fill_queue_ad[j];
    end
    next_q0_ct = q0_ct;
    next_q1_ct = q1_ct;
    next_q2_ct = q2_ct;
    next_q3_ct = q3_ct;
    next_b0_ct = b0_ct;
    next_b1_ct = b1_ct;
    next_b2_ct = b2_ct;
    next_b3_ct = b3_ct;
    next_b0_2ct = b0_2ct;
    next_b1_2ct = b1_2ct;
    next_b2_2ct = b2_2ct;
    next_b3_2ct = b3_2ct;
    next_q0_ar_ct = q0_ar_ct;
    next_q1_ar_ct = q1_ar_ct;
    next_q2_ar_ct = q2_ar_ct;
    next_q3_ar_ct = q3_ar_ct;
    next_fq_ct = fq_ct;
    next_fqad_ct = fqad_ct;

    if(state == SORT && ar_valid && ar_ready) 
    begin
        if(q0_ct < 8 && q0_ar_ct < 8 && (fill_queue_ad[0] == 1 || sort_addr_ct < 32))
        begin
            next_q0_ar_ct = q0_ar_ct + 1;
        end
        else if(q1_ct < 8 && q1_ar_ct < 8 && (fill_queue_ad[0] == 2 || sort_addr_ct < 32))
        begin
            next_q1_ar_ct = q1_ar_ct + 1;
        end
        else if(q2_ct < 8 && q2_ar_ct < 8 && (fill_queue_ad[0] == 3 || sort_addr_ct < 32))
        begin
            next_q2_ar_ct = q2_ar_ct + 1;
        end
        else if(q3_ct < 8 && q3_ar_ct < 8 && (fill_queue_ad[0] == 4 || sort_addr_ct < 32))
        begin
            next_q3_ar_ct = q3_ar_ct + 1;
        end
    end

    if(state == SORT && ar_valid && ar_ready) //sort read addr handshake
    begin
        if(q0_ar_ct < 8 && (next_fill_queue_ad[0] == 1 || sort_addr_ct < 32)) 
        begin
            if(b2_ct != 128)//read data from bank2
            begin
                next_b2_ct = b2_ct + 1;
            end
            else//read data from bank0
            begin
                next_b0_ct = b0_ct + 1;
            end
        end
        else if(q1_ar_ct < 8 && (next_fill_queue_ad[0] == 2 || sort_addr_ct < 32))
        begin
            if(b2_2ct != 128)//read data from bank2
            begin
                next_b2_2ct = b2_2ct + 1;
            end
            else//read data from bank0_2
            begin
                next_b0_2ct = b0_2ct + 1;
            end
        end
        else if(q2_ar_ct < 8 && (next_fill_queue_ad[0] == 3 || sort_addr_ct < 32))
        begin
            if(b3_ct != 128)//read data from bank3
            begin
                next_b3_ct = b3_ct + 1;
            end
            else//read data from bank1
            begin
                next_b1_ct = b1_ct + 1;
            end
        end
        else if(q3_ar_ct < 8 && (next_fill_queue_ad[0] == 4 || sort_addr_ct < 32))
        begin
            if(b3_2ct != 128)//read data from bank3
            begin
                next_b3_2ct = b3_2ct + 1;
            end
            else//read data from bank1_2
            begin
                next_b1_2ct = b1_2ct + 1;
            end
        end
    end

    if(b0_ct == 128 && state == SORT)
        next_b0_ct = b0_ct;
    if(b0_2ct == 128 && state == SORT)
        next_b0_2ct = b0_2ct;
    if(b1_ct == 128 && state == SORT)
        next_b1_ct = b1_ct;
    if(b1_2ct == 128 && state == SORT)
        next_b1_2ct = b1_2ct;

    if(state != SORT)
    begin
        next_b0_ct = 0;
        next_b0_2ct = 0;
        next_b1_ct = 0;
        next_b1_2ct = 0;
        next_b2_ct = 0;
        next_b2_2ct = 0;
        next_b3_ct = 0;
        next_b3_2ct = 0;
        next_q0_ar_ct = 0;
        next_q1_ar_ct = 0;
        next_q2_ar_ct = 0;
        next_q3_ar_ct = 0;
        next_fq_ct = 0;
        next_fqad_ct = 0;
        next_q0_ct = 0;
        next_q1_ct = 0;
        next_q2_ct = 0;
        next_q3_ct = 0;
    end
    

    if(state == SORT && r_valid && r_ready) //sort read data into q0, q1, q2, q3
    begin
        if(q0_ct < 8 && (addr_list[0] == 1 || sort_r_ct < 32))//from bank2
        begin
            next_q0[q0_ct] = r_data;
            next_q0_ct = q0_ct + 1;
        end
        else if(q1_ct < 8 && (addr_list[0] == 2 || sort_r_ct < 32))//from bank2
        begin
            next_q1[q1_ct] = r_data;
            next_q1_ct = q1_ct + 1;
        end
        else if(q2_ct < 8 && (addr_list[0] == 3 || sort_r_ct < 32))//from bank3
        begin
            next_q2[q2_ct] = r_data;
            next_q2_ct = q2_ct + 1;
        end
        else if(q3_ct < 8 && (addr_list[0] == 4 || sort_r_ct < 32))//from bank3
        begin
            next_q3[q3_ct] = r_data;
            next_q3_ct = q3_ct + 1;
        end
    end



    if(state == SORT && r_ready && r_valid) //sort read data into q0, q1, q2, q3
    begin
        next_fill_queue[0:30] = fill_queue[1:31];
        next_fill_queue[31] = 0;
        next_fq_ct = (fq_ct > 0) ? fq_ct - 1 : 0;
    end

    if(state == SORT && ar_valid && ar_ready) //sort write data from q0, q1, q2, q3
    begin
        next_fill_queue_ad[0:30] = fill_queue_ad[1:31];
        next_fill_queue_ad[31] = 0;
        next_fqad_ct = (fqad_ct > 0) ? fqad_ct - 1 : 0;
    end


    if(state == SORT && (w_valid && w_ready))// pop and push at the same time
    begin
        if(next_q0[0][62:32] <= next_q1[0][62:32] && next_q0[0][62:32] <= next_q2[0][62:32] && next_q0[0][62:32] <= next_q3[0][62:32] && b0_ct != 128) //q0 min
        begin
            if(r_valid && r_ready)
            begin
                next_fill_queue[0:30] = fill_queue[1:31];
                next_fill_queue[31] = 0;
                next_fill_queue[fq_ct - 1] = 1;
                next_fq_ct = fq_ct;
            end
            else
            begin
                next_fill_queue[fq_ct] = 1;
                next_fq_ct = fq_ct + 1;
            end
                
        end
        else if(next_q1[0][62:32] < next_q0[0][62:32] && next_q1[0][62:32] <= next_q2[0][62:32] && next_q1[0][62:32] <= next_q3[0][62:32] && b0_2ct != 128) //q1 min
        begin
            if(r_valid && r_ready)
            begin
                next_fill_queue[0:30] = fill_queue[1:31];
                next_fill_queue[31] = 0;
                next_fill_queue[fq_ct - 1] = 2;
                next_fq_ct = fq_ct;
            end
            else
            begin
                next_fill_queue[fq_ct] = 2;
                next_fq_ct = fq_ct + 1;
            end
            
        end
        else if(next_q2[0][62:32] < next_q0[0][62:32] && next_q2[0][62:32] < next_q1[0][62:32] && next_q2[0][62:32] <= next_q3[0][62:32] && b1_ct != 128) //q2 min
        begin
            if(r_valid && r_ready)
            begin
                next_fill_queue[0:30] = fill_queue[1:31];
                next_fill_queue[31] = 0;
                next_fill_queue[fq_ct - 1] = 3;
                next_fq_ct = fq_ct;
            end
            else
            begin
                next_fill_queue[fq_ct] = 3;
                next_fq_ct = fq_ct + 1;
            end
        end
        else if(next_q3[0][62:32] < next_q0[0][62:32] && next_q3[0][62:32] < next_q1[0][62:32] && next_q3[0][62:32] < next_q2[0][62:32] && b1_2ct != 128) //q3 min
        begin
            if(r_valid && r_ready)
            begin
                next_fill_queue[0:30] = fill_queue[1:31];
                next_fill_queue[31] = 0;
                next_fill_queue[fq_ct - 1] = 4;
                next_fq_ct = fq_ct;
            end
            else
            begin
                next_fill_queue[fq_ct] = 4;
                next_fq_ct = fq_ct + 1;
            end
        end

    end


    if(state == SORT && w_valid && w_ready) //sort write data from q0, q1, q2, q3
    begin
        if(next_q0[0][62:32] <= next_q1[0][62:32] && next_q0[0][62:32] <= next_q2[0][62:32] && next_q0[0][62:32] <= next_q3[0][62:32]) //q0 min
        begin
            if(addr_list[0] == 1 && q0_ct < 8 && r_valid && r_ready)
            begin
                next_q0[0:6] = q0[1:7];
                next_q0[7] = 64'hffffffffffffffff;
                /*if(next_q0[0][62:32] == 31'h7fffffff)
                begin
                    next_q0[0] = q0[0];
                    next_q0[1:6] = q0[2:7];
                end*/
                
                next_q0_ct = q0_ct;
                next_q0[q0_ct - 1] = r_data;
            end
            else
            begin
                next_q0[0:6] = q0[1:7];
                next_q0[7] = 64'hffffffffffffffff;
                /*if(next_q0[0][62:32] == 31'h7fffffff)
                begin
                    next_q0[0] = q0[0];
                    next_q0[1:6] = q0[2:7];
                end*/
                next_q0_ct = (q0_ct > 0) ? q0_ct - 1 : 0;
                next_q0_ar_ct = (q0_ar_ct > 0) ? q0_ar_ct - 1 : 0;
            end

            if(b0_ct != 128)
            begin
                //next_fill_queue[fq_ct] = 1;
                //next_fq_ct = fq_ct + 1;
                next_fill_queue_ad[fqad_ct] = 1;
                next_fqad_ct = fqad_ct + 1;
            end
            
        end
        else if(next_q1[0][62:32] < next_q0[0][62:32] && next_q1[0][62:32] <= next_q2[0][62:32] && next_q1[0][62:32] <= next_q3[0][62:32]) //q1 min
        begin
            if(addr_list[0] == 2 && q1_ct < 8 && r_valid && r_ready)
            begin
                next_q1[0:6] = q1[1:7];
                next_q1[7] = 64'hffffffffffffffff;
                /*if(next_q1[0][62:32] == 31'h7fffffff)
                begin
                    next_q1[0] = q1[0];
                    next_q1[1:6] = q1[2:7];
                end*/
                next_q1_ct = q1_ct;
                next_q1[q1_ct - 1] = r_data;
            end
            else
            begin
                next_q1[0:6] = q1[1:7];
                next_q1[7] = 64'hffffffffffffffff;
                /*if(next_q1[0][62:32] == 31'h7fffffff)
                begin
                    next_q1[0] = q1[0];
                    next_q1[1:6] = q1[2:7];
                end*/
                next_q1_ct = (q1_ct > 0) ? q1_ct - 1 : 0;
                next_q1_ar_ct = (q1_ar_ct > 0) ? q1_ar_ct - 1 : 0;
            end

            if(b0_2ct != 128)
            begin
                //next_fill_queue[fq_ct] = 2;
                //next_fq_ct = fq_ct + 1;
                next_fill_queue_ad[fqad_ct] = 2;
                next_fqad_ct = fqad_ct + 1;
            end
        end
        else if(next_q2[0][62:32] < next_q0[0][62:32] && next_q2[0][62:32] < next_q1[0][62:32] && next_q2[0][62:32] <= next_q3[0][62:32]) //q2 min
        begin
            if(addr_list[0] == 3 && q2_ct < 8 && r_valid && r_ready)
            begin
                next_q2[0:6] = q2[1:7];
                next_q2[7] = 64'hffffffffffffffff;
                /*if(next_q2[0][62:32] == 31'h7fffffff)
                begin
                    next_q2[0] = q2[0];
                    next_q2[1:6] = q2[2:7];
                end*/
                next_q2_ct = q2_ct;
                next_q2[q2_ct - 1] = r_data;
            end
            else
            begin
                next_q2[0:6] = q2[1:7];
                next_q2[7] = 64'hffffffffffffffff;
                /*if(next_q2[0][62:32] == 31'h7fffffff)
                begin
                    next_q2[0] = q2[0];
                    next_q2[1:6] = q2[2:7];
                end*/
                next_q2_ct = (q2_ct > 0) ? q2_ct - 1 : 0;
                next_q2_ar_ct = (q2_ar_ct > 0) ? q2_ar_ct - 1 : 0;
            end

            if(b1_ct != 128)
            begin
                //next_fill_queue[fq_ct] = 3;
                //next_fq_ct = fq_ct + 1;
                next_fill_queue_ad[fqad_ct] = 3;
                next_fqad_ct = fqad_ct + 1;
            end
        end
        else//q3 min
        begin
            if(addr_list[0] == 4 && q3_ct < 8 && r_valid && r_ready)
            begin
                next_q3[0:6] = q3[1:7];
                next_q3[7] = 64'hffffffffffffffff;
                /*if(next_q3[0][62:32] == 31'h7fffffff)
                begin
                    next_q3[0] = q3[0];
                    next_q3[1:6] = q3[2:7];
                end*/
                next_q3_ct = q3_ct;
                next_q3[q3_ct - 1] = r_data;
            end
            else
            begin
                next_q3[0:6] = q3[1:7];
                next_q3[7] = 64'hffffffffffffffff;
                /*if(next_q3[0][62:32] == 31'h7fffffff)
                begin
                    next_q3[0] = q3[0];
                    next_q3[1:6] = q3[2:7];
                end*/
                next_q3_ct = (q3_ct > 0) ? q3_ct - 1 : 0;
                next_q3_ar_ct = (q3_ar_ct > 0) ? q3_ar_ct - 1 : 0;
            end

            if(b1_2ct != 128)
            begin
                //next_fill_queue[fq_ct] = 4;
                //next_fq_ct = fq_ct + 1;
                next_fill_queue_ad[fqad_ct] = 4;
                next_fqad_ct = fqad_ct + 1;
            end
        end

        if(next_q0[0][62:32] == 31'h7fffffff && next_q1[0][62:32] == 31'h7fffffff && next_q2[0][62:32] == 31'h7fffffff && next_q3[0][62:32] == 31'h7fffffff)
        begin
            if(q0_ct != 0 && b0_ct == 128)
            begin
                next_q0[0:6] = q0[1:7];
                next_q0[7] = 64'hffffffffffffffff;
                /*if(next_q0[0][62:32] == 31'h7fffffff)
                begin
                    next_q0[0] = q0[0];
                    next_q0[1:6] = q0[2:7];
                end*/
                next_q0_ct = (q0_ct > 0) ? q0_ct - 1 : 0;
            end
            else if(q1_ct != 0 && b0_2ct == 128)
            begin
                next_q1[0:6] = q1[1:7];
                next_q1[7] = 64'hffffffffffffffff;
                /*if(next_q1[0][62:32] == 31'h7fffffff)
                begin
                    next_q1[0] = q1[0];
                    next_q1[1:6] = q1[2:7];
                end*/
                next_q1_ct = (q1_ct > 0) ? q1_ct - 1 : 0;
            end
            else if(q2_ct != 0 && b1_ct == 128)
            begin
                next_q2[0:6] = q2[1:7];
                next_q2[7] = 64'hffffffffffffffff;
                /*if(next_q2[0][62:32] == 31'h7fffffff)
                begin
                    next_q2[0] = q2[0];
                    next_q2[1:6] = q2[2:7];
                end*/

                next_q2_ct = (q2_ct > 0) ? q2_ct - 1 : 0;
            end
            else if(q3_ct != 0 && b1_2ct == 128)
            begin
                next_q3[0:6] = q3[1:7];
                next_q3[7] = 64'hffffffffffffffff;
                /*if(next_q3[0][62:32] == 31'h7fffffff)
                begin
                    next_q3[0] = q3[0];
                    next_q3[1:6] = q3[2:7];
                end*/
                next_q3_ct = (q3_ct > 0) ? q3_ct - 1 : 0;
            end
        end
    end

    if(w_ready && w_valid && state == SORT && r_valid && r_ready) 
    begin
        if(addr_list[0] == 1 && q0[0] == w_data)
        begin
            next_q0_ar_ct = (q0_ar_ct > 0) ? q0_ar_ct - 1 : 0;
        end
        if(addr_list[0] == 2 && q1[0] == w_data)
        begin
            next_q1_ar_ct = (q1_ar_ct > 0) ? q1_ar_ct - 1 : 0;
        end
        if(addr_list[0] == 3 && q2[0] == w_data)
        begin
            next_q2_ar_ct = (q2_ar_ct > 0) ? q2_ar_ct - 1 : 0;
        end
        if(addr_list[0] == 4 && q3[0] == w_data)
        begin
            next_q3_ar_ct = (q3_ar_ct > 0) ? q3_ar_ct - 1 : 0;
        end

    end

    if(b0_ct == 128) //list 1 done
    begin
        if(fill_queue[0] == 1 && !(w_valid && w_ready))
        begin
            next_fill_queue[0:30] = fill_queue[1:31];
            next_fill_queue[31] = 0;
            next_fq_ct = (fq_ct > 0) ? fq_ct - 1 : 0;
            if(r_valid && r_ready && fill_queue[1] != 1)
            begin
                next_fill_queue[0:29] = fill_queue[2:31];
                next_fill_queue[30] = 0;
                next_fill_queue[31] = 0;
                next_fq_ct = (fq_ct > 1) ? fq_ct - 2 : 0; 
            end
        end
        if(fill_queue_ad[0] == 1)
        begin
            next_fill_queue_ad[0:30] = fill_queue_ad[1:31];
            next_fill_queue_ad[31] = 0;
            next_fqad_ct = (fqad_ct > 0) ? fqad_ct - 1 : 0;
        end
        next_q0_ar_ct = 8;
    end
    if(b0_2ct == 128) //list 2 done
    begin
        if(fill_queue[0] == 2 && !(w_valid && w_ready))
        begin
            next_fill_queue[0:30] = fill_queue[1:31];
            next_fill_queue[31] = 0;
            next_fq_ct = (fq_ct > 0) ? fq_ct - 1 : 0;
            if(r_valid && r_ready && fill_queue[1] != 2)
            begin
                next_fill_queue[0:29] = fill_queue[2:31];
                next_fill_queue[30] = 0;
                next_fill_queue[31] = 0;
                next_fq_ct = (fq_ct > 1) ? fq_ct - 2 : 0; 
            end
        end
        if(fill_queue_ad[0] == 2)
        begin
            next_fill_queue_ad[0:30] = fill_queue_ad[1:31];
            next_fill_queue_ad[31] = 0;
            next_fqad_ct = (fqad_ct > 0) ? fqad_ct - 1 : 0;
        end
        next_q1_ar_ct = 8;
    end
    if(b1_ct == 128) //list 3 done
    begin
        if(fill_queue[0] == 3 && !(w_valid && w_ready))
        begin
            next_fill_queue[0:30] = fill_queue[1:31];
            next_fill_queue[31] = 0;
            next_fq_ct = (fq_ct > 0) ? fq_ct - 1 : 0;
            if(r_valid && r_ready && fill_queue[1] != 3)
            begin
                next_fill_queue[0:29] = fill_queue[2:31];
                next_fill_queue[30] = 0;
                next_fill_queue[31] = 0;
                next_fq_ct = (fq_ct > 1) ? fq_ct - 2 : 0; 
            end
        end
        if(fill_queue_ad[0] == 3)
        begin
            next_fill_queue_ad[0:30] = fill_queue_ad[1:31];
            next_fill_queue_ad[31] = 0;
            next_fqad_ct = (fqad_ct > 0) ? fqad_ct - 1 : 0;
        end
        next_q2_ar_ct = 8;
    end
    
    if(b1_2ct == 128) //list 4 done
    begin
        if(fill_queue[0] == 4 && !(w_valid && w_ready))
        begin
            next_fill_queue[0:30] = fill_queue[1:31];
            next_fill_queue[31] = 0;
            next_fq_ct = (fq_ct > 0) ? fq_ct - 1 : 0;

            if(r_valid && r_ready && fill_queue[1] != 4)
            begin
                next_fill_queue[0:29] = fill_queue[2:31];
                next_fill_queue[30] = 0;
                next_fill_queue[31] = 0;
                next_fq_ct = (fq_ct > 1) ? fq_ct - 2 : 0; 
            end
        end
        if(fill_queue_ad[0] == 4)
        begin
            next_fill_queue_ad[0:30] = fill_queue_ad[1:31];
            next_fill_queue_ad[31] = 0;
            next_fqad_ct = (fqad_ct > 0) ? fqad_ct - 1 : 0;
        end
        next_q3_ar_ct = 8;
    end

end

//data
always @(*)
begin
    for (i = 0; i < 256; i = i + 1)
    begin
        next_data[i] = data[i];
    end

    if(in_valid && mode == 1) //write data
    begin
        next_data[255] = in_data;
        next_data[0:254] = data[1:255];
    end
    
    if((r_valid && r_ready) && mode == 0) //read data
    begin
        next_data[255] = r_data;
        next_data[0:254] = data[1:255];
    end

    if(state == WRITE && w_valid && w_ready) //write data
    begin
        next_data[0:254] = data[1:255];
        next_data[255] = 0;
    end

    if(state == OUT) //output data
    begin
        next_data[0:254] = data[1:255];
        next_data[255] = 0;
    end

    //sort************************************
    if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && r_valid && r_ready) //read data from bank 0-3 for sort
    begin
        next_data[255] = r_data;
        next_data[0:254] = data[1:255];
    end

    if(oesort_valid) // odd even sort
    begin
        if(count[0] == 0) //even cycle (0,1) ... (254,255)
        begin
            for (i = 0; i < 255; i = i + 2)
            begin
                if(data[i][62:32] > data[i+1][62:32])
                begin
                    next_data[i] = data[i+1];
                    next_data[i+1] = data[i];
                end
            end
        end
        else //odd cycle (1,2) ... (253,254)
        begin
            for (i = 1; i < 254; i = i + 2)
            begin
                if(data[i][62:32] > data[i+1][62:32])
                begin
                    next_data[i] = data[i+1];
                    next_data[i+1] = data[i];
                end
            end
        end
    end

    if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && w_valid && w_ready) //sort write data
    begin
        next_data[0:254] = data[1:255];
        next_data[255] = 0;
    end

    
end
//stack
always @(*)
begin
    for (i = 0; i < 16; i = i + 1)
    begin
        next_stack[i] = stack[i];
    end
    for (j = 0; j < 4; j = j + 1)
    begin
        next_calc_result[j] = calc_result[j];
    end
    num1 = 0;
    num2 = 0;
    result = 0;
    next_calc_ct = calc_ct;
    next_start_tree_valid = start_tree_valid;
    next_stack_ct = stack_ct;
    stack_update = 0;

    //CALC
    if(state == CALC && (r_valid && r_ready)) //calc read data
    begin
        if(r_data[63] == 0) //number
            next_stack[0] = {1'b1, 1'b0, {33{r_data[62]}}, r_data[62:32]}; //{valid, type, data}
        else if(r_data[63] == 1) //operator
            next_stack[0] = {1'b1, 1'b1, r_data[63:0]};

        next_stack[1:15] = stack[0:14];
        next_stack_ct = stack_ct + 1;
        
        stack_update = 1;
    end

    if(state == CALC && ar_valid && ar_ready) //calc read addr handshake
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

    if(state == OUT && mode == 2) //calc output
    begin
        next_calc_result[0:2] = calc_result[1:3];
        next_calc_result[3] = 0;
        next_calc_ct = 0;
        next_start_tree_valid = 0;
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
//sort
always @(*)
begin
    next_sort_ct = sort_ct;
    next_sort_rvalid = sort_rvalid;
    next_oesort_valid = oesort_valid;
    

    if(in_mode_valid && in_mode == 3) //sort first read
    begin
        next_sort_ct = 0;
        //next_sort_rvalid = 1;
    end

    if((next_state == SORT0 && state == IDLE) || (next_state == SORT1 && state == SORT0) || (next_state == SORT2 && state == SORT1) 
        || (next_state == SORT3 && state == SORT2)) //sort0 first read
    begin
        next_sort_rvalid = 1;
    end

    if(addr_ct == 255)
        next_sort_rvalid = 0;


    if((state == SORT0 || state == SORT1 || state == SORT2 || state == SORT3) && r_ct == 255) //sort read 256 done
    begin
        next_sort_ct = sort_ct + 1;
        //next_sort_rvalid = 0;
        next_oesort_valid = 1;
    end
    
    
    if(count == 255)
    begin
        next_oesort_valid = 0;
    end
end

//output
always @(*)
begin
    next_out_valid = out_valid;
    next_out_data = out_data;

    if(state == OUT)
    begin
        next_out_valid = 1;
        if(mode == 0)
        begin
            next_out_data = data[0];
            if(out_ct == 255)
            begin
                next_out_data = 0;
                next_out_valid = 0;
            end    
        end
        else if(mode == 1)
            next_out_data = 0;
        else if(mode == 2)
        begin
            next_out_data = calc_result[0];
            if(out_ct == 3)
            begin
                next_out_valid = 0;
                next_out_data = 0;
            end
        end
        else if(mode == 3)
            next_out_data = 0;
    end
    else
    begin
        next_out_valid = 0;
        next_out_data = 0;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        for (i = 0; i < 256; i = i + 1) 
        begin
            data[i] <= 0;
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            stack[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            calc_result[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            q0[i] <= 0;
            q1[i] <= 0;
            q2[i] <= 0;
            q3[i] <= 0;
        end
        for (i = 0; i < 32; i = i + 1)
        begin
            fill_queue[i] <= 0;
            fill_queue_ad[i] <= 0;
            addr_list[i] <= 0;
        end
        out_valid <= 0;
        out_data <= 0;
        aw_addr <= 0;
        aw_valid <= 0;
        w_data <= 0;
        w_valid <= 0;
        b_ready <= 0;
        ar_addr <= 0;
        ar_valid <= 0;
        r_ready <= 0;
        mode <= 0;
        bank <= 0;
        src_row <= 0;
        dst_row <= 0;
        state <= 0;
        addr_ct <= 0;
        r_ct <= 0;
        out_ct <= 0;
        in_data_ct <= 0;
        bresp_ct <= 0;
        left_valid <= 0;
        right_valid <= 0;
        calc_ct <= 0;
        start_tree_valid <= 0;
        sort_ct <= 0;
        sort_rvalid <= 0;
        oesort_valid <= 0;
        count <= 0;
        wback_ct <= 0;
        wback_valid <= 0;
        q0_ct <= 0;
        q1_ct <= 0;
        q2_ct <= 0;
        q3_ct <= 0;
        b0_ct <= 0;
        b1_ct <= 0;
        b2_ct <= 0;
        b3_ct <= 0;
        b0_2ct <= 0;
        b1_2ct <= 0;
        b2_2ct <= 0;
        b3_2ct <= 0;
        q0_ar_ct <= 0;
        q1_ar_ct <= 0;
        q2_ar_ct <= 0;
        q3_ar_ct <= 0;
        fq_ct <= 0;
        fqad_ct <= 0;
        in_mode_buf <= 0;
        stack_ct <= 0;
        sort_addr_ct <= 0;
        sort_r_ct <= 0;
        list_ct <= 0;
    end
    else 
    begin
        for (i = 0; i < 256; i = i + 1)
        begin
            data[i] <= next_data[i];
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            stack[i] <= next_stack[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            calc_result[i] <= next_calc_result[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            q0[i] <= next_q0[i];
            q1[i] <= next_q1[i];
            q2[i] <= next_q2[i];
            q3[i] <= next_q3[i];
        end
        for (i = 0; i < 32; i = i + 1)
        begin
            fill_queue[i] <= next_fill_queue[i];
            fill_queue_ad[i] <= next_fill_queue_ad[i];
            addr_list[i] <= next_addr_list[i];
        end
        out_valid <= next_out_valid;
        out_data <= next_out_data;
        aw_addr <= next_aw_addr;
        aw_valid <= next_aw_valid;
        w_data <= next_w_data;
        w_valid <= next_w_valid;
        b_ready <= next_b_ready;
        ar_addr <= next_ar_addr;
        ar_valid <= next_ar_valid;
        r_ready <= next_r_ready;
        mode <= next_mode;
        bank <= next_bank;
        src_row <= next_src_row;
        dst_row <= next_dst_row;
        state <= next_state;
        addr_ct <= next_addr_ct;
        r_ct <= next_r_ct;
        out_ct <= next_out_ct;
        in_data_ct <= next_in_data_ct;
        bresp_ct <= next_bresp_ct;
        left_valid <= next_left_valid;
        right_valid <= next_right_valid;
        calc_ct <= next_calc_ct;
        start_tree_valid <= next_start_tree_valid;
        sort_ct <= next_sort_ct;
        sort_rvalid <= next_sort_rvalid;
        oesort_valid <= next_oesort_valid;
        count <= next_count;
        wback_ct <= next_wback_ct;
        wback_valid <= next_wback_valid;
        q0_ct <= next_q0_ct;
        q1_ct <= next_q1_ct;
        q2_ct <= next_q2_ct;
        q3_ct <= next_q3_ct;
        b0_ct <= next_b0_ct;
        b1_ct <= next_b1_ct;
        b2_ct <= next_b2_ct;
        b3_ct <= next_b3_ct;
        b0_2ct <= next_b0_2ct;
        b1_2ct <= next_b1_2ct;
        b2_2ct <= next_b2_2ct;
        b3_2ct <= next_b3_2ct;
        q0_ar_ct <= next_q0_ar_ct;
        q1_ar_ct <= next_q1_ar_ct;
        q2_ar_ct <= next_q2_ar_ct;
        q3_ar_ct <= next_q3_ar_ct;
        fq_ct <= next_fq_ct;
        fqad_ct <= next_fqad_ct;
        in_mode_buf <= next_in_mode_buf;
        stack_ct <= next_stack_ct;
        sort_addr_ct <= next_sort_addr_ct;
        sort_r_ct <= next_sort_r_ct;
        list_ct <= next_list_ct;
    end
end


endmodule
