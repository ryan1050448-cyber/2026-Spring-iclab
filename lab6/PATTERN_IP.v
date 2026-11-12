`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

module PATTERN #(parameter IP_WIDTH = 8)(
    //Output Port
    IN_character,
	IN_weight,
    //Input Port
	OUT_character
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_character;
output reg [IP_WIDTH*5-1:0] IN_weight;

input [IP_WIDTH*4-1:0] OUT_character;

// ========================================
// Parameters & Variables
// ========================================
parameter PATNUM = 1000;
integer f_in, f_out;
integer patcount;
integer i;
integer wrong_cnt;

reg [3:0] tmp_char;
reg [4:0] tmp_weight;
reg [3:0] exp_char_arr [0:15]; // Max support up to IP_WIDTH=16

// ========================================
// Pattern Start
// ========================================
initial begin
    f_in  = $fopen("input_ip.txt", "r");
    f_out = $fopen("output_ip.txt", "r");
    
    if (f_in == 0 || f_out == 0) begin
        $display("[MSG] Could not find input_ip.txt or output_ip.txt. Run Python script first!");
        $finish;
    end

    // Initialize inputs
    IN_character = 0;
    IN_weight = 0;
    wrong_cnt = 0;
    
    #(`CYCLE_TIME);

    for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
        
        // 1. Read Inputs (from MSB to LSB)
        for (i = IP_WIDTH - 1; i >= 0; i = i - 1) begin
            $fscanf(f_in, "%d %d", tmp_char, tmp_weight);
            IN_character[i*4 +: 4] = tmp_char;
            IN_weight[i*5 +: 5] = tmp_weight;
        end

        // 2. Read Expected Outputs
        for (i = IP_WIDTH - 1; i >= 0; i = i - 1) begin
            $fscanf(f_out, "%d", exp_char_arr[i]);
        end

        // 3. Wait for Combinational Logic to Settle
        // Since it's combo logic, half a cycle is enough to check
        #(`CYCLE_TIME / 2.0);

        // 4. Check Outputs
        for (i = IP_WIDTH - 1; i >= 0; i = i - 1) begin
            if (OUT_character[i*4 +: 4] !== exp_char_arr[i]) begin
                $display("[MSG] Pattern %d mismatched at Index %d!", patcount, i);
                $display("   Expected Char ID: %d", exp_char_arr[i]);
                $display("   Your IP Output  : %d", OUT_character[i*4 +: 4]);
                wrong_cnt = wrong_cnt + 1;
            end
        end
        
        if (wrong_cnt > 0) begin
            $display("[MSG] Simulation stopped due to mismatches.");
            $finish;
        end

        $display("\033[0;32mPASS PATTERN NO.%4d\033[m", patcount);

        // 5. Delay before next pattern
        #(`CYCLE_TIME / 2.0);
    end

    // If it reaches here, all patterns are correct
    $display("-------------------------------------------------------------------");
    $display("                        All tests clear!                           ");
    $display("                 Your SORT_IP is working perfectly!                ");
    $display("-------------------------------------------------------------------");
    $finish;
end


endmodule