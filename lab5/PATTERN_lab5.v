`define CYCLE_TIME      8.0  // Note: Adjust to your max clock period

module PATTERN(
    // Output Port (To DUT)
    clk,
    rst_n,
    i_valid,
    i_iter,
    i_mode,
    i_weight,
    i_data,
    
    // Input Port (From DUT)
    o_valid,
    o_data
);

// Output Port (To DUT)
output reg clk;
output reg rst_n;
output reg i_valid;
output reg [2:0] i_iter;
output reg [1:0] i_mode;
output reg [3:0] i_weight;
output reg [7:0] i_data;
    
// Input Port (From DUT)
input        o_valid;
input  [7:0] o_data;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
parameter PATNUM = 21; 

integer i_pat, i;
integer latency, total_latency;
integer count_out_valid;
integer iter_num;

integer fd_in, fd_out;
integer char_count;

// String buffers
reg [8*10:1] str_buf; 
reg [31:0] temp_val;

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
    
    // Wait random cycles and inject weight
    repeat($urandom_range(2,5)) @(negedge clk);
    load_weights_task;
    
    // Iteratively run patterns
    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_task;
        check_answer_task;
        $display("\033[0;32mPASS PATTERN NO.%4d, average latency: %d, iter_num: %d\033[m", i_pat, latency / iter_num, iter_num);
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
    i_valid = 1'b0;
    i_iter = 3'bx;
    i_mode = 2'bx;
    i_weight = 4'bx;
    i_data = 8'bx;

    total_latency = 0;

    force clk = 1'b0;
    #(CYCLE/2.0) rst_n = 1'b0;
    #(CYCLE*2.0) rst_n = 1'b1;
    
    if(o_valid !== 1'b0 || o_data !== 8'd0) begin
        $display("*************************************************************************");
        $display("             ALL output signals should be reset to 0                     ");
        $display("*************************************************************************");
        $finish;
    end

    #CYCLE; release clk;
end endtask

task load_weights_task; begin
    i_valid = 1'b1;
    for (i = 0; i < 1312; i = i + 1) begin
        char_count = $fscanf(fd_in, "%h", temp_val);
        i_weight = temp_val[3:0];
        @(negedge clk);
    end
    i_valid = 1'b0;
    i_weight = 4'bx;
end endtask

task input_task; begin
    // Skip the "PATTERN X" string
    char_count = $fscanf(fd_in, "%s %s", str_buf, str_buf);
    
    repeat($urandom_range(1,3)) @(negedge clk);
    i_valid = 1'b1;
    
    // First cycle sends parameters and first pixel
    char_count = $fscanf(fd_in, "%h", temp_val);
    i_iter = temp_val[2:0];
    iter_num = temp_val[2:0];
    char_count = $fscanf(fd_in, "%h", temp_val);
    i_mode = temp_val[1:0];
    
    char_count = $fscanf(fd_in, "%h", temp_val);
    i_data = temp_val[7:0];
    @(negedge clk);
    
    // Turn off iter/mode parameters after cycle 0
    i_iter = 3'bx;
    i_mode = 2'bx;
    
    // Stream remaining 4095 pixels (64x64 total)
    for (i = 1; i < 4096; i = i + 1) begin
        char_count = $fscanf(fd_in, "%h", temp_val);
        i_data = temp_val[7:0];
        @(negedge clk);
    end
    
    i_valid = 1'b0;
    i_data = 8'bx;
end endtask

task wait_out_task; begin
    latency = 0;
    while(o_valid !== 1'b1) begin
        latency = latency + 1;
        if(latency > 150000 * iter_num) begin
            $display("*************************************************************************");
            $display("               Execution latency is over 150000 cycles                   ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_answer_task; 
    reg [7:0] golden_data;
begin
    count_out_valid = 0;
    char_count = $fscanf(fd_out, "%s %s", str_buf, str_buf); // Skip PATTERN X
    
    for (i = 0; i < 4096; i = i + 1) begin
        if (o_valid !== 1'b1) begin
            $display("*************************************************************************");
            $display("             o_valid should be high for 4096 cycles                      ");
            $display("*************************************************************************");
            $finish;
        end

        char_count = $fscanf(fd_out, "%h", golden_data);
        
        if (o_data !== golden_data) begin
            $display("*************************************************************************");
            $display(" Error !");
            $display(" Index: %5d | Golden: %h | Yours: %h", i, golden_data, o_data);
            $display("*************************************************************************");
            $finish;
        end

        count_out_valid = count_out_valid + 1;
        @(negedge clk);
    end

    if(o_valid !== 1'b0 || o_data !== 8'd0) begin
        $display("*************************************************************************");
        $display("   o_valid should be low and o_data should be 0 after 4096 cycles        ");
        $display("*************************************************************************");
        $finish;
    end
end endtask

//---------------------------------------------------------------------
//  PARALLEL CHECKS
//---------------------------------------------------------------------
always @(negedge clk) begin
    if (o_valid && i_valid) begin
        $display("*************************************************************************");
        $display("          o_valid cannot overlap with any i_valid signals                ");
        $display("*************************************************************************");
        $finish;
    end
    
    if (o_valid === 1'b0 && o_data !== 8'd0) begin
        $display("*************************************************************************");
        $display("              o_data should be zero when o_valid is low                  ");
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