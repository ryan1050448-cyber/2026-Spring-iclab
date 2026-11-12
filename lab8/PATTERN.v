`define CYCLE_TIME 15.0
`define SEED_NUMBER     69
`define PATTERN_NUMBER  100

module PATTERN(
    // Output Port
    clk,
    rst_n,
    in_valid,
    in_data,

    // Input Port
    out_valid,
    out_data
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output  logic        clk, rst_n, in_valid;
output  logic[7:0]  in_data;

input           out_valid;
input   [11:0]   out_data;

//---------------------------------------------------------------------
//   PARAMETERS & VARIABLES
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
real seed = `SEED_NUMBER;

parameter PAT_NUM = `PATTERN_NUMBER;

integer f_in, f_out;
integer i, j, pat_idx;
integer in_val, golden_val;
integer latency, total_latency;
integer seed = `SEED_NUMBER;
integer read_count;

//---------------------------------------------------------------------
//   CLOCK
//---------------------------------------------------------------------
always #(CYCLE / 2.0) clk = ~clk;

//---------------------------------------------------------------------
//   INITIAL & MAIN BLOCK
//---------------------------------------------------------------------
initial begin
    f_in  = $fopen("../00_TESTBED/input.txt", "r");
    f_out = $fopen("../00_TESTBED/output.txt", "r");
    
    if (f_in == 0 || f_out == 0) begin
        $display("Can't open input.txt or output.txt");
        $finish;
    end

    reset_task;

    for (pat_idx = 0; pat_idx < PAT_NUM; pat_idx = pat_idx + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;

        $display("\033[0;32mPASS PATTERN NO.%4d, latency: %4d cycles\033[m", pat_idx, latency);
        total_latency = total_latency + latency;
    end

    $fclose(f_in);
    $fclose(f_out);

    YOU_PASS_task;
end

//---------------------------------------------------------------------
//   TASKS
//---------------------------------------------------------------------
task reset_task; begin
    rst_n = 1;
    in_valid = 0;
    in_data = 'bx;
    cg_en = 0;
    total_latency = 0;

    force clk = 0;
    #(CYCLE / 2.0); rst_n = 0;
    #(2.0 * CYCLE); rst_n = 1;

    if(out_valid !== 0 || out_data !== 0) begin
        $display("=========================================================");
        $display("  WRONG: All output signals should be reset to 0!       ");
        $display("=========================================================");
        $finish;
    end

    #CYCLE; release clk;

end endtask

task input_task; begin

    repeat($urandom_range(1,3)) @(negedge clk);
    in_valid = 1;

    // Read 97 consecutive cycles
    for (i = 0; i < 97; i = i + 1) begin
        read_count = $fscanf(f_in, "%d", in_val);
        in_data = in_val;
        @(negedge clk);
    end
    
    in_valid = 0;
    in_data  = 'bx;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while (out_valid === 1'b0) begin
        if (latency >= 200) begin
            $display("=========================================================");
            $display("  WRONG: Execution latency is over 200 cycles!           ");
            $display("=========================================================");
            $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    // Check 32 consecutive cycles of output
    for (j = 0; j < 32; j = j + 1) begin
        if (out_valid !== 1'b1) begin
            $display("=========================================================");
            $display("  WRONG: out_valid should remain high for 32 cycles!     ");
            $display("=========================================================");
            $finish;
        end

        read_count = $fscanf(f_out, "%d", golden_val);
        
        if (out_data !== golden_val) begin
            $display("=========================================================");
            $display("  WRONG at Pattern %d, Output Cycle %d                   ", pat_idx, j+1);
            $display("  Expected: %d, Got: %d                                  ", golden_val, out_data);
            $display("=========================================================");
            $finish;
        end
        @(negedge clk);
    end
    
    // Check if out_valid is properly pulled down after 32 cycles
    if (out_valid !== 1'b0) begin
        $display("=========================================================");
        $display("  WRONG: out_valid should be low after 32 cycles!        ");
        $display("=========================================================");
        $finish;
    end
end endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

endmodule