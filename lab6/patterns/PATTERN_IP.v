`define CYCLE_TIME 20.0

module PATTERN #(parameter IP_WIDTH = 8)(
    //Output Port
    IN_character,
	IN_weight,
    //Input Port
	OUT_character
);

parameter PATNUM = 1000;

// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_character;
output reg [IP_WIDTH*5-1:0] IN_weight;

input [IP_WIDTH*4-1:0] OUT_character;

integer i, j;
integer patnum;

reg clk;

reg [3:0] characters   [IP_WIDTH-1:0];
reg [4:0] weights      [IP_WIDTH-1:0];
reg [4:0] sort_weights [IP_WIDTH-1:0];

reg [8:0] temp;

reg flag;

// ========================================
// Pattern Start
// ========================================
initial	clk = 0;
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    #10;
    release clk;

    repeat(2) @(negedge clk);

    for (patnum = 0; patnum < PATNUM; patnum += 1) begin
        // Generate pattern
        for (i = 0; i < IP_WIDTH; i = i + 1) begin
            characters[i] = i;
            weights[i]    = $urandom_range(31, 0);

            for (j = 0; j < 4; j = j + 1) IN_character[i * 4 + j] = characters[i][j];
            for (j = 0; j < 5; j = j + 1) IN_weight[i * 5 + j]    = weights[i][j];
        end

        @(negedge clk);

        // Verify answer
        sort_task();
        flag = 0;
        for (i = 0; i < IP_WIDTH; i = i + 1)
            for (j = 0; j < 4; j = j + 1) 
                flag |= (OUT_character[i * 4 + j] !== characters[i][j]);

        // Fail
        if (flag) begin
            $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
            $write("Input characters: ");
            for (i = IP_WIDTH - 1; i >= 0; i = i - 1)
                $write("%2d ", i);
            $display();
            $write("Input weight:     ");
            for (i = IP_WIDTH - 1; i >= 0; i = i - 1)
                $write("%2d ", weights[i]);
            
            $display("\n");

            $write("Golden:  ");
            for (i = IP_WIDTH - 1; i >= 0; i = i - 1)
                $write("%2d ", characters[i]);
            $display();

            $write("Receive: ");
            for (i = IP_WIDTH - 1; i >= 0; i = i - 1)
                $write("%2d ", OUT_character[i * 4 +: 4]);
            $display();

            $display("\033[31m--------------------------------------------\033[0m");
            $finish;
        end
        else begin
            $display("\033[32mPASS PATTERN %d\033[0m", patnum);
        end
    end

    YOU_PASS_task;
end

task sort_task(); begin
    for (i = 0; i < IP_WIDTH; i += 1)
        sort_weights[i] = weights[i];

    for (i = 0; i < IP_WIDTH - 1; i += 1)
        for (j = 0; j < IP_WIDTH - i - 1; j += 1)
            if (sort_weights[j + 1] < sort_weights[j]) begin
                temp = {characters[j], sort_weights[j]};
                {characters[j], sort_weights[j]} = {characters[j + 1], sort_weights[j + 1]};
                {characters[j + 1], sort_weights[j + 1]} = temp;
            end
end endtask

task YOU_PASS_task; begin
    $display("\n");
    $display("\n");
    $display("        ----------------------------               ");
    $display("        --                        --       |\__||  ");
    $display("        --  Congratulations !!    --      / O.O  | ");
    $display("        --                        --    /_____   | ");
    $display("        --  Simulation out!!     --   /^ ^ ^ \\  |");
    $display("        --                        --  |^ ^ ^ ^ |w| ");
    $display("        ----------------------------   \\m___m__|_|");
    $display("\n");
    $finish;
end endtask

endmodule
