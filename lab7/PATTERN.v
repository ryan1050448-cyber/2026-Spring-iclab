`ifdef RTL
    `define CYCLE_TIME_clk1 20.1
    `define CYCLE_TIME_clk2 11.3
    `define CYCLE_TIME_clk3 34.7
`endif
`ifdef Period_1
    `define CYCLE_TIME_clk1 34.7
    `define CYCLE_TIME_clk2 20.1
    `define CYCLE_TIME_clk3 11.3
`endif
`ifdef Period_2
    `define CYCLE_TIME_clk1 11.3
    `define CYCLE_TIME_clk2 20.1
    `define CYCLE_TIME_clk3 34.7
`endif
`ifdef Period_3
    `define CYCLE_TIME_clk1 20.1
    `define CYCLE_TIME_clk2 11.3
    `define CYCLE_TIME_clk3 34.7
`endif


`ifdef GATE
    `define CYCLE_TIME_clk1 20.1
    `define CYCLE_TIME_clk2 11.3
    `define CYCLE_TIME_clk3 34.7
`endif

module PATTERN(
    output reg      clk1,
    output reg      clk2,
    output reg      clk3,

    output reg      rst_n,
    // AXI4-Lite Master (Monitor Only, Relaxed)
    input      [31:0]  ar_addr_clk2, 
    input              ar_valid_clk2, 
    input              ar_ready_clk2,
    input       [63:0] r_data_clk2,  
    input              r_valid_clk2, 
    input              r_ready_clk2,

    input      [31:0]  ar_addr_clk3, 
    input              ar_valid_clk3, 
    input              ar_ready_clk3,
    input       [63:0] r_data_clk3,  
    input              r_valid_clk3, 
    input              r_ready_clk3,

    output reg       in_mode_valid,
    output reg       in_mode,
    output reg       in_valid,
    output reg [1:0] in_bank,
    output reg [5:0] in_src_row,
    
    input             out_valid,
    input [63:0]      out_data
);

real CYCLE_clk1 = `CYCLE_TIME_clk1;
real CYCLE_clk2 = `CYCLE_TIME_clk2;
real CYCLE_clk3 = `CYCLE_TIME_clk3;

parameter PATNUM = 100;
integer i_pat, q_idx;
integer total_latency;
integer latency;
integer fd_in, fd_out;
integer count_ar_ready_clk2;
integer count_r_ready_clk2;
integer count_r_valid_clk2;
integer pending_ar_clk2;
integer count_ar_ready_clk3;
integer count_r_ready_clk3;
integer count_r_valid_clk3;
integer pending_ar_clk3;
integer read_count;
integer temp_mode;

reg [31:0] temp_bank [0:3];
reg [31:0] temp_row  [0:3];
reg [63:0] golden_out_val;

reg        ar_valid_temp_clk2;
reg [31:0] ar_addr_temp_clk2;
reg        r_valid_temp_clk2;
reg [63:0] r_data_temp_clk2;
reg        wait_r_clk2;
reg        ar_valid_temp_clk3;
reg [31:0] ar_addr_temp_clk3;
reg        r_valid_temp_clk3;
reg [63:0] r_data_temp_clk3;
reg        wait_r_clk3;

// 宣告檢查用的暫存值
reg [31:0] temp_ar_addr_clk2, temp_ar_addr_clk3;
reg [63:0] temp_r_data_clk2,  temp_r_data_clk3;

// DRAM 模擬 (65536 個 64-bit 字組)
reg [63:0] DRAM_memory [0:65535];
reg [63:0] expected_result;
reg [30:0] gauss_raw_data [0:1023];
reg [63:0] golden_queue   [0:1025];
integer    golden_count;

integer i;
//---------------------------------------------------------------------
//  CLOCK GENERATION
//---------------------------------------------------------------------
initial clk1 = 0;
always #(CYCLE_clk1/2.0) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE_clk2/2.0) clk2 = ~clk2;

initial clk3 = 0;
always #(CYCLE_clk3/2.0) clk3 = ~clk3;

//---------------------------------------------------------------------
//  SIMULATION FLOW
//---------------------------------------------------------------------
initial begin
    $readmemh("../00_TESTBED/DRAM_init.dat", DRAM_memory);

    reset_signal_task;
    pending_ar_clk2 = 0;
    pending_ar_clk3 = 0;

    // Iteratively run patterns
    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        // Random delay between patterns (like in lab5)
        repeat($urandom_range(2, 5)) @(negedge clk1);

        input_task;
        //wait_out_task;
        check_answer_task;

        $display("\033[0;32mPASS PATTERN NO.%4d, latency: %4d cycles\033[m", i_pat, latency);
        total_latency = total_latency + latency;
    end

    $fclose(fd_in);
    $fclose(fd_out);
    
    YOU_PASS_task;
end

//---------------------------------------------------------------------
//  TASKS
//---------------------------------------------------------------------
task reset_signal_task; begin
    rst_n = 1'b1;
    in_mode_valid = 1'b0;
    in_mode = 1'bx;
    in_valid = 1'b0;
    in_bank = 2'bx;
    in_src_row = 6'bx;
    total_latency = 0;

    force clk1 = 1'b0;
    force clk2 = 1'b0;
    force clk3 = 1'b0;
    #(CYCLE_clk1/2.0) rst_n = 1'b0;
    #(CYCLE_clk1*2.0) rst_n = 1'b1;

    if(ar_addr_clk2 !== 0 || ar_valid_clk2 !== 0 || ar_ready_clk2 !== 0 || r_data_clk2 !== 0 || r_valid_clk2 !== 0 || r_ready_clk2 !== 0) begin
        $display("*************************************************************************");
        $display("[ERROR] AXI signals in clk2 domain should be reset to 0 at the beginning.");
        $display("*************************************************************************");
        $finish;
    end

    if(ar_addr_clk3 !== 0 || ar_valid_clk3 !== 0 || ar_ready_clk3 !== 0 || r_data_clk3 !== 0 || r_valid_clk3 !== 0 || r_ready_clk3 !== 0) begin
        $display("*************************************************************************");
        $display("[ERROR] AXI signals in clk3 domain should be reset to 0 at the beginning.");
        $display("*************************************************************************");
        $finish;
    end
        

    if(out_valid !== 0 || out_data !== 0) begin
        $display("*************************************************************");
        $display("[ERROR] Output signals should be reset to 0 at the beginning.");
        $display("*************************************************************");
        $finish;
    end

    # CYCLE_clk1; // Ensure reset is released for at least one full cycle
    release clk1;
    release clk2;
    release clk3;
end endtask

task input_task; begin
    
    repeat($urandom_range(1, 3)) @(negedge clk1);
    in_mode_valid = 1'b1;
    in_mode = $urandom_range(0, 1); 
    temp_mode = in_mode;
    in_valid = 0;
    in_bank = 2'bx;
    in_src_row = 6'bx;

    @(negedge clk1);
    in_mode_valid = 1'b0;
    in_mode = 1'bx;
    
    in_valid = 1'b1;
    for (i = 0; i < 4; i = i + 1) begin
        in_bank = $urandom_range(0, 3);
        in_src_row = $urandom_range(0, 63);
        temp_bank[i] = in_bank;
        temp_row[i] = in_src_row;
        @(negedge clk1);
    end

    in_valid = 1'b0;
    in_bank = 2'bx;
    in_src_row = 6'bx;
end endtask

function automatic reg signed [63:0] calc_tree(input [15:0] ptr);
    reg [63:0] node;
    reg signed [63:0] left_val;
    reg signed [63:0] right_val;
    begin
        node = DRAM_memory[ptr]; 

        if (node[63] == 1'b0) //number
        begin
            calc_tree = {{33{node[62]}}, node[62:32]}; //sign-extend
            //calc_tree = $signed(node[62:32]);
        end 
        else //operator
        begin
            left_val  = calc_tree(node[31:16]);
            right_val = calc_tree(node[15:0]);

            case (node[33:32])
                2'b00: calc_tree = left_val + right_val;
                2'b01: calc_tree = left_val - right_val;
                2'b10: calc_tree = left_val * right_val;
                2'b11: calc_tree = left_val >>> right_val[5:0]; 
            endcase
        end

        //$display("calc_tree: ptr = %d, node = %h, left_val = %d, right_val = %d, return %d", ptr, node, left_val, right_val, calc_tree);
    end
endfunction

task calculate_gauss_golden;
    integer i, j;
    reg [127:0] sum;              // S
    reg [127:0] sum_sq_elements;  //  \sum(x_i^2)
    reg [127:0] threshold;        //  N * \sum(x_i^2) - S^2
    reg [127:0] N_xi;             // N * x_i
    reg [127:0] diff_sq;          // (N*x_i - S)^2
    
    reg [63:0] cur;
    integer v_cnt; // N
    begin
        golden_count = 0; 
        v_cnt = 0; 
        sum = 0; 
        sum_sq_elements = 0;
        
        // ==========================================
        // 第一階段：讀取數據，計算總和(S)與平方總和(\sum x_i^2)
        // ==========================================
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                cur = DRAM_memory[{temp_bank[i][1:0], temp_row[i][5:0], 8'h0} + j];
                if (cur[63] == 0) begin
                    gauss_raw_data[v_cnt] = cur[62:32];
                    
                    // S
                    sum = sum + cur[62:32];
                    //  \sum(x_i^2)
                    sum_sq_elements = sum_sq_elements + (cur[62:32] * cur[62:32]);
                    
                    v_cnt = v_cnt + 1;
                end
            end
        end

        if (v_cnt > 0) begin
            // ==========================================
            // 第二階段：計算無誤差的 Threshold ( N * \sum(x_i^2) - S^2 )
            // ==========================================
            threshold = (v_cnt * sum_sq_elements) - (sum * sum);

            // ==========================================
            // 第三階段：完美判斷與 Last Position 處理
            // ==========================================
            
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    cur = DRAM_memory[{temp_bank[i][1:0], temp_row[i][5:0], 8'h0} + j];
                    
                    if (cur[63] == 0) begin
                        // 算出等式左邊: (N * x_i - S)^2
                        N_xi = v_cnt * cur[62:32];
                        
                        // 處理無號數減法的正負號問題再平方
                        diff_sq = (N_xi > sum) ? (N_xi - sum)**2 : (sum - N_xi)**2;

                        // 判斷式： (N * x_i - S)^2 <= threshold
                        if (diff_sq <= threshold) begin
                            golden_queue[golden_count] = cur;
                            golden_count = golden_count + 1;
                        end
                        
                    end
                    
                    // 條件 B: Requirement 1 - 該 Bank 的最後一個位置 (Column 255)
                    if (i == 3 && j == 255) begin
                        if (golden_count == 0 || golden_queue[golden_count-1] !== cur) begin
                            golden_queue[golden_count] = cur;
                            golden_count = golden_count + 1;
                        end
                    end
                end
            end
        end
    end
endtask

task check_answer_task; begin
    latency = 0;
    //total_latency = 0;
    if (temp_mode == 0) begin //CALC_LOGIC
        for (i = 0; i < 4; i = i + 1) begin
            expected_result = calc_tree({temp_bank[i][1:0], temp_row[i][5:0], 8'd0});
            wait_and_compare(expected_result);
        end
        
    end 
    else begin //GAUSS_LOGIC
        calculate_gauss_golden;
        for (q_idx = 0; q_idx < golden_count; q_idx = q_idx + 1) begin
            wait_and_compare(golden_queue[q_idx]);
        end
    end
end endtask

task wait_and_compare;
    input [63:0] golden_val;
    begin
        while (out_valid !== 1'b1) begin
            latency = latency + 1;
            if (latency > 40000) begin
                $display("*******************************");
                $display("[ERROR] Wait out_valid timeout!"); 
                $display("*******************************");
                $finish;
            end
            @(negedge clk1);
        end
        if (out_data !== golden_val) begin
            $display("***************************************************");
            $display("* [Error] Output mismatch at PATTERN %4d         *", i_pat);
            $display("* Golden : %16x                          *", golden_val);
            $display("* Yours  : %16x                          *", out_data);
            $display("***************************************************");
            $finish;
        end
        //total_latency = total_latency + latency;
        @(negedge clk1);
    end
endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE_clk1);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE_clk1);
    $display("*************************************************************************");
    $finish;
end endtask

//---------------------------------------------------------------------
//  SPEC AXI Check for CLK2 Domain
//---------------------------------------------------------------------
// *****************************************************************
// Rule 1: AR_READY Timeout (0~500 cycles)
// *****************************************************************
always @(*) 
begin
    @(negedge clk2);
    count_ar_ready_clk2 = 0;
    while (ar_valid_clk2 === 1'b1) begin
        while (ar_ready_clk2 !== 1'b1) begin
            count_ar_ready_clk2 = count_ar_ready_clk2 + 1;
            if (count_ar_ready_clk2 > 500) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk2] Rule 1 FAIL: AR_READY is not pulled high within 500 cycles.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk2);
        end
        while (ar_ready_clk2 === 1'b1) begin
            count_ar_ready_clk2 = 0;
            @(negedge clk2);
        end
    end
end
// *****************************************************************
// Rule 2: AR_VALID and AR_ADDR Stability Check
// *****************************************************************
always @(*) 
begin
    @(negedge clk2);
    if (ar_valid_clk2 === 1'b1 && ar_ready_clk2 !== 1'b1) begin
        ar_valid_temp_clk2 = ar_valid_clk2;
        ar_addr_temp_clk2  = ar_addr_clk2;
        @(negedge clk2);
        while (ar_ready_clk2 !== 1'b1) begin
            if (ar_valid_temp_clk2 !== ar_valid_clk2) begin
                $display("*************************************************************************************");
                $display("[SPEC AXI clk2] Rule 2 FAIL: AR_VALID must not be pulled low before AR_READY is high.");
                $display("*************************************************************************************");
                $finish;
            end
            if (ar_addr_temp_clk2 !== ar_addr_clk2) begin
                $display("*********************************************************************************");
                $display("[SPEC AXI clk2] Rule 2 FAIL: AR_ADDR must remain stable until AR_READY goes high.");
                $display("*********************************************************************************");
                $finish;
            end
            @(negedge clk2);
        end
    end
end
// *****************************************************************
// Rule 3, 4, 5, 8, 9: Range, Reset, and Undefined Check
// *****************************************************************
always @(*) 
begin
    @(negedge clk2);
    
    // Rule 3: AR_ADDR legal range (0~65535)
    if (ar_addr_clk2 < 0 || ar_addr_clk2 > 65535) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk2] Rule 3 FAIL: AR_ADDR %d is out of bounds (0~65535).", ar_addr_clk2);
        $display("*************************************************************************");
        $finish;
    end

    // Rule 4 & 8: Cannot be X or Z when Valid is high
    if (ar_valid_clk2 === 1'b1 && ^ar_addr_clk2 === 1'bx) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk2] Rule 4 FAIL: AR_ADDR contains X/Z when AR_VALID is high."); 
        $display("*************************************************************************");
        $finish;
    end
    if (r_valid_clk2 === 1'b1 && ^r_data_clk2 === 1'bx) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk2] Rule 8 FAIL: R_DATA contains X/Z when R_VALID is high."); 
        $display("*************************************************************************");
        $finish;
    end

    // Rule 5: AR_ADDR should be reset when AR_VALID is low
    if (ar_valid_clk2 === 1'b0 && ar_addr_clk2 !== 'b0) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk2] Rule 5 FAIL: AR_ADDR should be reset to 0 when AR_VALID is low.");
        $display("*************************************************************************");
        $finish;
    end

    // Rule 9: R_DATA should be reset when R_VALID is low
    if (r_valid_clk2 === 1'b0 && r_data_clk2 !== 'b0) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk2] Rule 9 FAIL: R_DATA should be reset to 0 when R_VALID is low.");
        $display("*************************************************************************");
        $finish;
    end
end
// *****************************************************************
// Outstanding Capability Tracker & Rule 6 (R_VALID Timeout)
// *****************************************************************
always @(negedge clk2) 
begin
    //@(negedge clk2);
    // Track Outstanding AR requests
    if (ar_valid_clk2 === 1'b1 && ar_ready_clk2 === 1'b1) begin
        if (!(r_valid_clk2 === 1'b1 && r_ready_clk2 === 1'b1)) begin
            pending_ar_clk2 = pending_ar_clk2 + 1;
        end
    end 
    else if (r_valid_clk2 === 1'b1 && r_ready_clk2 === 1'b1) begin
        if (pending_ar_clk2 > 0) begin
            pending_ar_clk2 = pending_ar_clk2 - 1;
        end 
        else begin
            $display("*************************************************************************");
            $display("[SPEC AXI clk2] FATAL: R_VALID handshake occurred without any pending AR request.");
            $display("*************************************************************************");
            $finish;
        end
    end

    // wait_r trigger for Rule 6
    if (pending_ar_clk2 > 0) begin
        wait_r_clk2 = 1'b1;
    end 
    else begin
        wait_r_clk2 = 1'b0;
    end
end

always @(*) 
begin
    @(negedge clk2);
    count_r_valid_clk2 = 0;
    while (wait_r_clk2 === 1'b1) begin
        // If R_VALID is not yet high, count up
        if (r_valid_clk2 !== 1'b1) begin
            count_r_valid_clk2 = count_r_valid_clk2 + 1;
        end 
        else begin
            count_r_valid_clk2 = 0; // Reset count when valid appears
        end

        if (count_r_valid_clk2 > 500) begin
            $display("*************************************************************************************************");
            $display("[SPEC AXI clk2] Rule 6 FAIL: R_VALID is not pulled high within 500 cycles after AR communication.");
            $display("*************************************************************************************************");
            $finish;
        end
        @(negedge clk2);
    end
end
// *****************************************************************
// Rule 7: R_READY Timeout (0~500 cycles)
// *****************************************************************
always @(*) 
begin
    @(negedge clk2);
    count_r_ready_clk2 = 0;
    while (r_valid_clk2 === 1'b1) begin
        while (r_ready_clk2 !== 1'b1) begin
            count_r_ready_clk2 = count_r_ready_clk2 + 1;
            if (count_r_ready_clk2 > 500) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk2] Rule 7 FAIL: R_READY is not pulled high within 500 cycles.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk2);
        end
        while (r_ready_clk2 === 1'b1) begin
            count_r_ready_clk2 = 0;
            @(negedge clk2);
        end
    end
end
// *****************************************************************
// Rule 10: R_VALID and R_DATA Stability Check
// *****************************************************************
always @(*) 
begin
    @(negedge clk2);
    if (r_valid_clk2 === 1'b1 && r_ready_clk2 !== 1'b1) begin
        r_valid_temp_clk2 = r_valid_clk2;
        r_data_temp_clk2  = r_data_clk2;
        @(negedge clk2);
        while (r_ready_clk2 !== 1'b1) begin
            if (r_valid_temp_clk2 !== r_valid_clk2) begin
                $display("************************************************************************************");
                $display("[SPEC AXI clk2] Rule 10 FAIL: R_VALID must not be pulled low before R_READY is high.");
                $display("************************************************************************************");
                $finish;
            end
            if (r_data_temp_clk2 !== r_data_clk2) begin
                $display("*********************************************************************************");
                $display("[SPEC AXI clk2] Rule 10 FAIL: R_DATA must remain stable until R_READY goes high.");
                $display("************************************************************************************");
                $finish;
            end
            @(negedge clk2);
        end
    end
end
//---------------------------------------------------------------------
//  SPEC AXI Check for CLK3 Domain
//---------------------------------------------------------------------
// *****************************************************************
// Rule 1: AR_READY Timeout (clk3)
// *****************************************************************
always @(*) 
begin
    @(negedge clk3);
    count_ar_ready_clk3 = 0;
    while (ar_valid_clk3 === 1'b1) begin
        while (ar_ready_clk3 !== 1'b1) begin
            count_ar_ready_clk3 = count_ar_ready_clk3 + 1;
            if (count_ar_ready_clk3 > 500) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk3] Rule 1 FAIL: AR_READY is not pulled high within 500 cycles.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk3);
        end
        while (ar_ready_clk3 === 1'b1) begin
            count_ar_ready_clk3 = 0;
            @(negedge clk3);
        end
    end
end
// *****************************************************************
// Rule 2: AR_VALID and AR_ADDR Stability Check (clk3)
// *****************************************************************
always @(*) 
begin
    @(negedge clk3);
    if (ar_valid_clk3 === 1'b1 && ar_ready_clk3 !== 1'b1) begin
        ar_valid_temp_clk3 = ar_valid_clk3;
        ar_addr_temp_clk3  = ar_addr_clk3;
        @(negedge clk3);
        while (ar_ready_clk3 !== 1'b1) begin
            if (ar_valid_temp_clk3 !== ar_valid_clk3) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk3] Rule 2 FAIL: AR_VALID must not be pulled low before AR_READY is high.");
                $display("*************************************************************************");
                $finish;
            end
            if (ar_addr_temp_clk3 !== ar_addr_clk3) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk3] Rule 2 FAIL: AR_ADDR must remain stable until AR_READY goes high.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk3);
        end
    end
end
// *****************************************************************
// Rule 3, 4, 5, 8, 9: Range, Reset, and Undefined Check (clk3)
// *****************************************************************
always @(*) 
begin
    @(negedge clk3);

    // Rule 3: AR_ADDR range check (0~65535)
    if (ar_addr_clk3 < 0 || ar_addr_clk3 > 65535) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk3] Rule 3 FAIL: AR_ADDR %d is out of bounds.", ar_addr_clk3);
        $display("*************************************************************************");
        $finish;
    end

    // Rule 4 & 8: X/Z check
    if (ar_valid_clk3 === 1'b1 && ^ar_addr_clk3 === 1'bx) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk3] Rule 4 FAIL: AR_ADDR contains X/Z when AR_VALID is high."); 
        $display("*************************************************************************");
        $finish;

    end
    if (r_valid_clk3 === 1'b1 && ^r_data_clk3 === 1'bx) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk3] Rule 8 FAIL: R_DATA contains X/Z when R_VALID is high."); 
        $display("*************************************************************************");
        $finish;
    end

    // Rule 5: AR_ADDR reset check
    if (ar_valid_clk3 === 1'b0 && ar_addr_clk3 !== 'b0) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk3] Rule 5 FAIL: AR_ADDR should be reset to 0 when AR_VALID is low.");
        $display("*************************************************************************");
        $finish;
    end
    
    // Rule 9: R_DATA reset check
    if (r_valid_clk3 === 1'b0 && r_data_clk3 !== 'b0) begin
        $display("*************************************************************************");
        $display("[SPEC AXI clk3] Rule 9 FAIL: R_DATA should be reset to 0 when R_VALID is low.");
        $display("*************************************************************************");
        $finish;
    end
end
// *****************************************************************
// Outstanding Tracker & Rule 6 (R_VALID Timeout) (clk3)
// *****************************************************************
always @(negedge clk3) 
begin
    //@(negedge clk3);
    if (ar_valid_clk3 === 1'b1 && ar_ready_clk3 === 1'b1) begin
        if (!(r_valid_clk3 === 1'b1 && r_ready_clk3 === 1'b1)) begin
            pending_ar_clk3 = pending_ar_clk3 + 1;
        end
    end 
    else if (r_valid_clk3 === 1'b1 && r_ready_clk3 === 1'b1) begin
        if (pending_ar_clk3 > 0) begin
            pending_ar_clk3 = pending_ar_clk3 - 1;
        end else begin
            $display("************************************************************");
            $display("[SPEC AXI clk3] FATAL: R_VALID handshake without pending AR.");
            $display("************************************************************");
            $finish;
        end
    end

    wait_r_clk3 = (pending_ar_clk3 > 0) ? 1'b1 : 1'b0;
end

always @(*) 
begin
    @(negedge clk3);
    count_r_valid_clk3 = 0;
    while (wait_r_clk3 === 1'b1) begin
        if (r_valid_clk3 !== 1'b1) begin
            count_r_valid_clk3 = count_r_valid_clk3 + 1;
        end 
        else begin
            count_r_valid_clk3 = 0;
        end

        if (count_r_valid_clk3 > 500) begin
            $display("*************************************************************************************************");
            $display("[SPEC AXI clk3] Rule 6 FAIL: R_VALID is not pulled high within 500 cycles after AR communication.");
            $display("**************************************************************************************************");
            $finish;
        end
        @(negedge clk3);
    end
end
// *****************************************************************
// Rule 7: R_READY Timeout (clk3)
// *****************************************************************
always @(*) 
begin
    @(negedge clk3);
    count_r_ready_clk3 = 0;
    while (r_valid_clk3 === 1'b1) begin
        while (r_ready_clk3 !== 1'b1) begin
            count_r_ready_clk3 = count_r_ready_clk3 + 1;
            if (count_r_ready_clk3 > 500) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk3] Rule 7 FAIL: R_READY is not pulled high within 500 cycles.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk3);
        end
        while (r_ready_clk3 === 1'b1) begin
            count_r_ready_clk3 = 0;
            @(negedge clk3);
        end
    end
end
// *****************************************************************
// Rule 10: R_VALID and R_DATA Stability Check (clk3)
// *****************************************************************
always @(*) 
begin
    @(negedge clk3);
    if (r_valid_clk3 === 1'b1 && r_ready_clk3 !== 1'b1) begin
        r_valid_temp_clk3 = r_valid_clk3;
        r_data_temp_clk3  = r_data_clk3;
        @(negedge clk3);
        while (r_ready_clk3 !== 1'b1) begin
            if (r_valid_temp_clk3 !== r_valid_clk3) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk3] Rule 10 FAIL: R_VALID must not be pulled low before R_READY is high.");
                $display("*************************************************************************");
                $finish;
            end
            if (r_data_temp_clk3 !== r_data_clk3) begin
                $display("*************************************************************************");
                $display("[SPEC AXI clk3] Rule 10 FAIL: R_DATA must remain stable until R_READY goes high.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk3);
        end
    end
end

endmodule