`define CYCLE_TIME      50.0

module PATTERN(
    // Output Port (To DUT)
    clk,
    rst_n,
    instruction_in_valid,
    image_in_valid,
    weight_in_valid,
    in_data,
    
    // Input Port (From DUT)
    out_valid,
    out_data
);

// Output Port (To DUT)
output reg clk;
output reg rst_n;
output reg instruction_in_valid;
output reg image_in_valid;
output reg weight_in_valid;
output reg [31:0] in_data;
    
// Input Port (From DUT)
input    out_valid;
input  [31:0]  out_data;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
parameter PATNUM = 100; 

integer i_pat, i;
integer latency, total_latency;
integer count_out_valid;

integer fd_in, fd_out;
integer char_count;

// 用來吃掉 "PATTERN_X" 字串的垃圾桶，長度抓 20 個字元
reg [20*20:1] str_buf;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial begin
    fd_in  = $fopen("../00_TESTBED/input.txt", "r");
    fd_out = $fopen("../00_TESTBED/output.txt", "r");
    
    if (fd_in == 0 || fd_out == 0) begin
        $display("Failed to open input.txt or output.txt");
        $finish;
    end

    reset_signal_task;
    
    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_task;
        check_answer_task;
        $display("\033[0;32mPASS PATTERN NO.%4d\033[m", i_pat);
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
    instruction_in_valid = 1'b0;
    weight_in_valid = 1'b0;
    image_in_valid = 1'b0;
    in_data = 32'bx;

    total_latency = 0;

    force clk = 1'b0;
    #(CYCLE/2.0) rst_n = 1'b0;
    #(CYCLE*2.0) rst_n = 1'b1;
    
    if(out_valid !== 1'b0 || out_data !== 32'd0) begin
        $display("*************************************************************************");
        $display("             ALL output signals should be reset to 0                     ");
        $display("*************************************************************************");
        $finish;
    end

    #CYCLE; release clk;
end endtask

task input_task; begin
    // 每次開始一筆新的 Pattern 前，先把 input.txt 裡的 "PATTERN_X" 標籤讀掉
    char_count = $fscanf(fd_in, "%s %s %s", str_buf, str_buf, str_buf);
    
    // 1. 讀取並送出 Instruction (1 cycle)
    repeat($urandom_range(2,5)) @(negedge clk);
    instruction_in_valid = 1'b1;
    char_count = $fscanf(fd_in, "%h ", in_data); // 直接從檔案讀 1 行十六進位到 in_data
    @(negedge clk);
    instruction_in_valid = 1'b0;
    in_data = 32'bx;

    // 2. 讀取並送出 Weights (144 cycles)
    repeat($urandom_range(2,5)) @(negedge clk);
    weight_in_valid = 1'b1;
    for (i = 0; i < 144; i = i + 1) begin
        char_count = $fscanf(fd_in, "%h ", in_data); // 逐行讀取送入
        @(negedge clk);
    end
    weight_in_valid = 1'b0;
    in_data = 32'bx;

    // 3. 讀取並送出 Image (128 cycles)
    repeat($urandom_range(2,5)) @(negedge clk);
    image_in_valid = 1'b1;
    for (i = 0; i < 128; i = i + 1) begin
        char_count = $fscanf(fd_in, "%h ", in_data); // 逐行讀取送入
        @(negedge clk);
    end
    image_in_valid = 1'b0;
    in_data = 32'bx;
end endtask

task wait_out_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
        latency = latency + 1;
        if(latency > 1200) begin
            $display("*************************************************************************");
            $display("               Execution latency is over 1200 cycles                     ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

function real bits2real;
    input [31:0] bits;
    reg sign;
    reg [7:0] exp;
    reg [23:0] frac;
    begin
        sign = bits[31];
        exp = bits[30:23];
        frac = {1'b1, bits[22:0]};
        if (exp == 0) 
            bits2real = 0.0;
        else 
            bits2real = (sign ? -1.0 : 1.0) * (frac / (2.0**23)) * (2.0**(exp - 127.0));
    end
endfunction

task check_answer_task; 
    reg [31:0] golden_data;
    real real_golden, real_ans, err;
begin
    count_out_valid = 0;

    // 開始對這 128 個答案前，先把 output.txt 裡的 "PATTERN_X" 標籤讀掉
    char_count = $fscanf(fd_out, "%s %s %s", str_buf, str_buf, str_buf);

    for (i = 0; i < 128; i = i + 1) begin
        if (out_valid !== 1'b1) begin
            $display("*************************************************************************");
            $display("             out_valid should be high for 128 cycles                     ");
            $display("*************************************************************************");
            $finish;
        end

        // 動態從 output.txt 讀一行出來對答案
        char_count = $fscanf(fd_out, "%h ", golden_data);
        
        real_golden = bits2real(golden_data);
        real_ans = bits2real(out_data);
        
        if (real_golden == 0.0) begin
            err = (real_ans == 0.0) ? 0.0 : 1.0; 
        end else begin
            err = (real_golden - real_ans) / real_golden;
        end
        
        if (err < 0) err = -err; 

        if (err > 0.002) begin
            $display("*************************************************************************");
            $display(" Error > 0.002 !");
            $display(" Index: %3d | Golden: %h (%f) | Yours: %h (%f) | Error: %f", 
                      i, golden_data, real_golden, out_data, real_ans, err);
            $display("*************************************************************************");
            $finish;
        end

        count_out_valid = count_out_valid + 1;
        @(negedge clk);
    end

    if(out_valid !== 1'b0 || out_data !== 32'd0) begin
        $display("*************************************************************************");
        $display("   out_valid should be low and out_data should be 0 after 128 cycles     ");
        $display("*************************************************************************");
        $finish;
    end
end endtask

//---------------------------------------------------------------------
//  PARALLEL CHECKS
//---------------------------------------------------------------------
always @(negedge clk) begin
    if (out_valid && (instruction_in_valid || weight_in_valid || image_in_valid)) begin
        $display("*************************************************************************");
        $display("          out_valid cannot overlap with any in_valid signals             ");
        $display("*************************************************************************");
        $finish;
    end
    
    if (out_valid === 1'b0 && out_data !== 32'd0) begin
        $display("*************************************************************************");
        $display("              out_data should be zero when out_valid is low              ");
        $display("*************************************************************************");
        $finish;
    end
end

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("* Congratulations!                              *");
    $display("* Your execution cycles = %5d cycles          *", total_latency);
    $display("* Your clock period = %.1f ns          *", CYCLE);
    $display("* Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask



endmodule