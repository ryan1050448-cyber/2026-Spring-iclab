`define CYCLE_TIME 20.0

module PATTERN(
    // Output signals (To DUT)
    clk,
    rst_n,
    in_valid,
    in_weight, 
    out_mode,
    // Input signals (From DUT)
    out_valid, 
    out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg clk, rst_n, in_valid;
output reg [2:0] in_weight;
output reg out_mode;
input out_valid, out_code;

// ===============================================================
// Parameters & Variables
// ===============================================================
real CYCLE = `CYCLE_TIME;
parameter PATNUM = 100;

integer i_pat, i;
integer latency, total_latency;
integer out_cnt;

integer fd_in, fd_out;
integer char_count;

// Data buffers for reading files
integer w [0:7];
integer mode;
integer exp_len;
integer golden_bit;

// ===============================================================
// Clock Generation
// ===============================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

// ===============================================================
// Main Simulation Block
// ===============================================================
initial begin
    fd_in  = $fopen("../00_TESTBED/input.txt", "r");
    fd_out = $fopen("../00_TESTBED/output.txt", "r");
    if (fd_in == 0 || fd_out == 0) begin
        $display("[ERROR] Could not find input.txt or output.txt. Please run Python script first!");
        $finish;
    end

    reset_signal_task;
    
    // Iteratively run patterns
    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        // Random delay between patterns (like in lab5)
        repeat($urandom_range(2, 5)) @(negedge clk);
        
        input_task;
        wait_out_task;
        check_answer_task;
        
        $display("\033[0;32mPASS PATTERN NO.%4d, latency: %4d cycles\033[m", i_pat, latency);
    end

    $fclose(fd_in);
    $fclose(fd_out);

    YOU_PASS_task;
end

// ===============================================================
// Tasks
// ===============================================================
task reset_signal_task; begin
    rst_n = 1'b1;
    in_valid = 1'b0;
    in_weight = 3'bx;
    out_mode = 1'bx;
    
    total_latency = 0;

    force clk = 0;
    #(CYCLE/2.0) rst_n = 1'b0;
    #(CYCLE*2.0) rst_n = 1'b1;
    
    // Check Reset of Outputs
    if (out_valid !== 1'b0 || out_code !== 1'b0) begin
        $display("*************************************************************************");
        $display("             ALL output signals should be reset to 0                     ");
        $display("*************************************************************************");
        $finish;
    end

    #CYCLE; release clk;
end endtask

task input_task; begin
    // Read 8 weights and 1 mode from input.txt
    char_count = $fscanf(fd_in, "%d %d %d %d %d %d %d %d %d", w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7], mode);
    repeat($urandom_range(1,3)) @(negedge clk);
    in_valid = 1'b1;
    
    // Drive inputs for 8 cycles
    for (i = 0; i < 8; i = i + 1) begin
        in_weight = w[i];
        
        // out_mode should typically be given at the first cycle of in_valid
        if (i == 0) out_mode = mode;
        else        out_mode = 1'bx;
        
        @(negedge clk);
    end
    
    // Pull down valid and X out inputs
    in_valid = 1'b0;
    in_weight = 3'bx;
    out_mode = 1'bx;
end endtask

task wait_out_task; begin
    latency = 0;
    while (out_valid !== 1'b1) begin
        latency = latency + 1;
        if (latency > 2000) begin
            $display("***********************************************************************");
            $display("               Execution latency is over 2000 cycles                   ");
            $display("***********************************************************************");
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_answer_task; begin
    out_cnt = 0;
    
    // Read the expected length for this pattern first
    char_count = $fscanf(fd_out, "%d", exp_len);
    
    // Check cycle-by-cycle while out_valid is high
    while (out_valid === 1'b1) begin
        if (out_cnt >= exp_len) begin
            $display("***********************************************************************");
            $display("               out_valid is High for too many cycles!                  ");
            $display("***********************************************************************");
            $finish;
        end
        
        // Read the exact golden bit for this specific cycle
        char_count = $fscanf(fd_out, "%d", golden_bit);
        
        if (out_code !== golden_bit[0]) begin
            $display("***********************************************************************");
            $display(" Error ! Pattern %d", i_pat);
            $display(" Output bit[%3d] mismatch. Expected: %b, Got: %b", out_cnt, golden_bit[0], out_code);
            $display("***********************************************************************");
            $finish;
        end
        
        out_cnt = out_cnt + 1;
        @(negedge clk);
    end
    
    // Check if it ended prematurely
    if (out_cnt !== exp_len) begin
        $display("**********************************************************************************");
        $display("   Pattern %d Error! out_valid ended too early. Output %d bits, Expected %d bits  ", i_pat, out_cnt, exp_len);
        $display("**********************************************************************************");
        $finish;
    end
end endtask

// ===============================================================
// Parallel Checks (Background Checkers)
// ===============================================================
always @(negedge clk) begin
    if (out_valid && in_valid) begin
        $display("*************************************************************************");
        $display("          out_valid cannot overlap with in_valid                         ");
        $display("*************************************************************************");
        $finish;
    end
    
    if (out_valid === 1'b0 && out_code !== 1'b0) begin
        $display("*************************************************************************");
        $display("              out_code should be zero when out_valid is low              ");
        $display("*************************************************************************");
        $finish;
    end
end

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("* Congratulations!                               *");
    $display("* You have passed all patterns!                         *");
    $display("* Total Latency: %8d cycles                       *", total_latency);
    $display("*************************************************************************");
    $finish;
end endtask

endmodule