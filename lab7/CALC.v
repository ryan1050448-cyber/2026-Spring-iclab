always @(*)
begin
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

