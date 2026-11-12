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

`define PATNUM 100
`define MAX_WRONG_ANSWER_DISPLAY 30
`define PRINT_PATTERN 1
`define PRINT_ACT 1

module PATTERN(
    output reg      clk1,
    output reg      clk2,
    output reg      clk3,

    output reg      rst_n,
    // AXI4-Lite Master
    input      [31:0]  ar_addr_clk2, 
    input              ar_valid_clk2, 
    input              ar_ready_clk2,
    input       [63:0] r_data_clk2,  
    // input       [1:0]  r_resp_clk2, 
    input              r_valid_clk2, 
    input              r_ready_clk2,

    input      [31:0]  ar_addr_clk3, 
    input              ar_valid_clk3, 
    input              ar_ready_clk3,
    input       [63:0] r_data_clk3,  
    // input       [1:0]  r_resp_clk3, 
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
real	CYCLE_clk1 = `CYCLE_TIME_clk1;
real	CYCLE_clk2 = `CYCLE_TIME_clk2;
real	CYCLE_clk3 = `CYCLE_TIME_clk3;

//---------------------------------------------------------------------
//   Integer & DRAM
//---------------------------------------------------------------------
reg [63:0] golden_DRAM [0:65535];
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
initial $readmemh(DRAM_p_r, golden_DRAM);

integer patnum;
integer latency;
integer m0_total_latency, m1_total_latency;
integer m0_patnum, m1_patnum;
integer average_latency;

integer i, j;

reg [127:0] sum, square_sum, count, val;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
initial	clk1 = 0;
always #(CYCLE_clk1/2.0) clk1 = ~clk1;

initial	clk2 = 0;
always #(CYCLE_clk2/2.0) clk2 = ~clk2;

initial	clk3 = 0;
always #(CYCLE_clk3/2.0) clk3 = ~clk3;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------

// Main
reg mode;
reg [7:0] bank_row [3:0];

reg [10:0] golden_data_count;
reg [63:0] golden_data [1023:0];

reg [10:0] recieved_data_count;
reg [63:0] recieved_data [1023:0];

integer f_flag;

// AXI
reg axi_fail_valid;

reg [31:0] golden_ar [127:0];

reg [6:0] clk2_ar_pointer;
reg [6:0] clk3_ar_pointer;
reg [6:0] dram_ar_pointer;
reg [6:0] clk3_r_pointer;
reg [6:0] clk2_r_pointer;

// Support
integer ACT_count;


//---------------------------------------------------------------------
//   AXI protocol & DRAM CTRL protocol match
//---------------------------------------------------------------------

wire clk2_ar_handshake = (ar_valid_clk2 && ar_ready_clk2);
wire clk2_r_handshake  = ( r_valid_clk2 &&  r_ready_clk2);

wire clk2_ar_invalid = (ar_addr_clk2 > 65535);
wire clk2_r_invalid  = (golden_DRAM[golden_ar[clk2_r_pointer]] !== r_data_clk2);

AXI_Verifier #(.NAME("clk2 AR channel"), .CARRY_WIDTH(32), .PRIOR_ACTIVE(0)) CLK2_AR_CHANNEL_VERIFIER(
    .clk             (clk2            ),
    .rst_n           (rst_n           ),
    .enable          (axi_fail_valid  ),
    .prior_handshake (1'b0            ),
    .valid           (ar_valid_clk2   ),
    .carry           (ar_addr_clk2    ),
    .ready           (ar_ready_clk2   ),
    .carry_invalid   (clk2_ar_invalid )
);

AXI_Verifier #(.NAME("clk2 R channel"), .CARRY_WIDTH(64), .PRIOR_ACTIVE(1)) CLK2_R_CHANNEL_VERIFIER(
    .clk             (clk2              ),
    .rst_n           (rst_n             ),
    .enable          (axi_fail_valid    ),
    .prior_handshake (clk2_ar_handshake ),
    .valid           (r_valid_clk2      ),
    .carry           (r_data_clk2       ),
    .ready           (r_ready_clk2      ),
    .carry_invalid   (clk2_r_invalid    )
);

wire clk3_ar_handshake = (ar_valid_clk3 && ar_ready_clk3);
wire clk3_r_handshake  = ( r_valid_clk3 &&  r_ready_clk3);

wire dram_ar_cmd = (u_DRAM.dram_cmd === 4'b0101);

wire clk3_ar_invalid = (golden_ar[clk3_ar_pointer] !== ar_addr_clk3);
wire clk3_r_invalid  = (golden_DRAM[golden_ar[clk3_r_pointer]] !== r_data_clk3);

AXI_Verifier #(.NAME("clk3 AR channel"), .CARRY_WIDTH(32), .PRIOR_ACTIVE(0)) CLK3_AR_CHANNEL_VERIFIER(
    .clk             (clk3            ),
    .rst_n           (rst_n           ),
    .enable          (axi_fail_valid  ),
    .prior_handshake (1'b0            ),
    .valid           (ar_valid_clk3   ),
    .carry           (ar_addr_clk3    ),
    .ready           (ar_ready_clk3   ),
    .carry_invalid   (clk3_ar_invalid )
);

AXI_Verifier #(.NAME("clk3 R channel"), .CARRY_WIDTH(64), .PRIOR_ACTIVE(1)) CLK3_R_CHANNEL_VERIFIER(
    .clk             (clk3              ),
    .rst_n           (rst_n             ),
    .enable          (axi_fail_valid    ),
    .prior_handshake (clk3_ar_handshake ),
    .valid           (r_valid_clk3      ),
    .carry           (r_data_clk3       ),
    .ready           (r_ready_clk3      ),
    .carry_invalid   (clk3_r_invalid    )
);

always @(negedge clk2, negedge rst_n) begin
    if (!rst_n) begin
        clk2_ar_pointer <= 0;
        clk2_r_pointer  <= 0;
    end
    else begin
        if (clk2_ar_handshake) begin
            golden_ar[clk2_ar_pointer] <= ar_addr_clk2;
            clk2_ar_pointer <= clk2_ar_pointer + 1;
        end
        if (clk2_r_handshake) begin
            golden_ar[clk2_r_pointer] <= 'bx;
            clk2_r_pointer <= clk2_r_pointer + 1;
        end
    end
end

always @(negedge clk3, negedge rst_n) begin
    if (!rst_n) begin
        clk3_ar_pointer <= 0;
        dram_ar_pointer <= 0;
        clk3_r_pointer  <= 0;
    end
    else begin
        if (clk3_ar_handshake) begin
            clk3_ar_pointer <= clk3_ar_pointer + 1;
        end
        if (dram_ar_cmd) begin
            if (golden_ar[dram_ar_pointer] !== {u_DRAM.dram_ba, u_DRAM.active_row[u_DRAM.dram_ba][5:0], u_DRAM.dram_addr[7:0]}) begin
                $display();
                $display("\033[31m*******************************************************************************\033[0m");
                $display("\033[31m*            DRAM Read address (%4h) mismatch AXI ar channel                *\033[0m", {u_DRAM.dram_ba, u_DRAM.active_row[u_DRAM.dram_ba][5:0], u_DRAM.dram_addr[7:0]});
                $display("\033[31m*                   (Correspong AXI ar addr = %4h)                          *\033[0m", golden_ar[dram_ar_pointer]);
                $display("\033[31m*******************************************************************************\033[0m");
                $finish();
            end
            dram_ar_pointer <= dram_ar_pointer + 1;
        end
        if (clk3_r_handshake) begin
            clk3_r_pointer <= clk3_r_pointer + 1;
        end
    end
end
//---------------------------------------------------------------------
//   Support
//---------------------------------------------------------------------

always @(negedge clk3) begin
    if (u_DRAM.dram_cmd === 4'b0011) begin
	    ACT_count += 1;
	end
end

//---------------------------------------------------------------------
//   Main verification
//---------------------------------------------------------------------

initial begin
    async_reset_task;
    
    axi_fail_valid = 1;

    m0_patnum = 0;
    m1_patnum = 0;
    m0_total_latency = 0;
    m1_total_latency = 0;

    for (patnum = 0; patnum < `PATNUM; patnum += 1) begin
        repeat($urandom_range(4, 2)) @(negedge clk1);

        ACT_count = 0;

        generate_pattern_task;
        calculate_golden;
	    await_and_verify_output;

        if (`PRINT_ACT) begin
            $display("\033[32m--- PASS PATTERN %d, latency = %d, ACT = %d ---\033[0m", patnum, latency, ACT_count);
        end
        else begin
            $display("\033[32m--- PASS PATTERN %d, latency = %d ---\033[0m", patnum, latency);
        end

        if (mode == 0) begin
            m0_patnum += 1;
            m0_total_latency += latency;
        end
        else begin
            m1_patnum += 1;
            m1_total_latency += latency;
        end
    end

    YOU_PASS_task;
end

task async_reset_task; begin
    in_mode_valid = 0;
    in_valid      = 0;

    rst_n = 1;
    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;

    #(CYCLE_clk1 * 3.0); rst_n = 0;
    #(100.0); rst_n = 1;
    if (//ar_addr_clk2  !== 0 || 
        //ar_valid_clk2 !== 0 || 
        //ar_ready_clk2 !== 0 || 
//
        //r_data_clk2   !== 0 || 
        //r_valid_clk2  !== 0 ||
        //r_ready_clk2  !== 0 ||
        //
        //ar_addr_clk3  !== 0 || 
        //ar_valid_clk3 !== 0 || 
        //ar_ready_clk3 !== 0 || 
//
        //r_data_clk3   !== 0 || 
        //r_valid_clk3  !== 0 || 
        //r_ready_clk3  !== 0 || 
        
        out_valid     !== 0 || 
        out_data      !== 0) begin
        
        $display("\033[31m*******************************************************************************\033[0m");
        $display("\033[31m*                      Signals should be zero after reset                     *\033[0m");
        $display("\033[31m*******************************************************************************\033[0m");
        $finish();
    end
        

    #(CYCLE_clk1 * 3.0); 
    release clk1;
    release clk2;
    release clk3;
end endtask

task generate_pattern_task; begin
    mode = $urandom_range(1, 0);
    for (i = 0; i < 4; i = i + 1) bank_row[i] = $urandom_range(255, 0);

    if (`PRINT_PATTERN) begin
        $write("Mode %d, {bank, row} = {%d, %d}, {%d, %d}, {%d, %d}, {%d, %d}  | ",
                mode, 
                bank_row[0][7:6], bank_row[0][5:0],
                bank_row[1][7:6], bank_row[1][5:0],
                bank_row[2][7:6], bank_row[2][5:0],
                bank_row[3][7:6], bank_row[3][5:0]);
    end

    in_mode_valid = 1'b1;
    in_mode       = mode;

    @(negedge clk1);
    in_mode_valid = 1'b0;
    in_mode       = 'bx;

    in_valid = 1'b1;
    for (i = 0; i < 4; i = i + 1) begin
        in_bank    = bank_row[i][7:6];
        in_src_row = bank_row[i][5:0];
        @(negedge clk1);
    end

    in_valid   = 1'b0;
    in_bank    = 'bx;
    in_src_row = 'bx;
end endtask

task calculate_golden; begin
    golden_data_count = 0;
    for (i = 0; i < 1024; i = i + 1) golden_data[i] = 'bx;

    if (mode == 0) begin
        golden_data_count = 4;
        golden_data[0] = eval_expression_tree({bank_row[0], 8'b0});
        golden_data[1] = eval_expression_tree({bank_row[1], 8'b0});
        golden_data[2] = eval_expression_tree({bank_row[2], 8'b0});
        golden_data[3] = eval_expression_tree({bank_row[3], 8'b0});
    end
    else begin
        count = 0;
        sum = 0;
        square_sum = 0;
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                if (golden_DRAM[{bank_row[i], j[7:0]}][63] == 0) begin
                    val = golden_DRAM[{bank_row[i], j[7:0]}][62:32];
                    count += 1;
                    sum += val;
                    square_sum += val * val;
                end
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                if (golden_DRAM[{bank_row[i], j[7:0]}][63] == 0) begin
                    val = golden_DRAM[{bank_row[i], j[7:0]}][62:32];

                    if ((count * val - sum) * (count * val - sum) <= (count * square_sum - sum * sum)) begin
                        golden_data[golden_data_count] = golden_DRAM[{bank_row[i], j[7:0]}];
                        golden_data_count += 1;
                    end
                end
            end
        end

        val = golden_DRAM[{bank_row[3], 8'd255}][62:32];

        if (golden_DRAM[{bank_row[3], 8'd255}][63] != 0 || 
            (count * val - sum) * (count * val - sum) > (count * square_sum - sum * sum)) begin
            
            golden_data[golden_data_count] = golden_DRAM[{bank_row[3], 8'd255}];
            golden_data_count += 1;
        end

        //$display("Count = %d, Sum = %d, Square_sum = %d, V = %d", count, sum, square_sum, (count * square_sum - sum * sum));
    end
end endtask

task await_and_verify_output; begin

    for (i = 0; i < 1024; i = i + 1) recieved_data[i] = 'bx;

    latency = 0;
    f_flag  = 0;
    recieved_data_count = 0;
    while (!f_flag && (recieved_data_count < golden_data_count)) begin
        if (out_valid === 1) begin
            recieved_data[recieved_data_count] = out_data;
            recieved_data_count += 1;
        end

        if (^out_valid === 1'bx) begin
            $display();
            $display("\033[31m*******************************************************************************\033[0m");
            $display("\033[31m*                             Out valid is unknown                            *\033[0m");
            $display("\033[31m*******************************************************************************\033[0m");
            f_flag = 1;
        end

        if (latency >= 40000) begin
            $display();
            $display("\033[31m*******************************************************************************\033[0m");
            $display("\033[31m*                         latency exceed 40000 cycles                         *\033[0m");
            $display("\033[31m*******************************************************************************\033[0m");
            f_flag = 1;
        end

        @(negedge clk1);
        latency += 1;
    end

    if (!f_flag) begin
        for (i = 0; i < golden_data_count; i = i + 1) begin
            if (golden_data[i] !== recieved_data[i]) begin
                f_flag = 1;
            end
        end
        if (f_flag) begin
            $display();
            $display("\033[31m*******************************************************************************\033[0m");
            $display("\033[31m*                                 Wrong Answer                                *\033[0m");
            $display("\033[31m*******************************************************************************\033[0m");
        end
    end

    if (f_flag) begin
        $display();
        j = 0;
        for (i = 0; i < golden_data_count; i = i + 1) begin
            if (golden_data[i] !== recieved_data[i]) begin
                if (j < `MAX_WRONG_ANSWER_DISPLAY) begin
                    $display("Output #%-4d: golden = %d (0x%16h), recieved = %d (0x%16h)", i, $signed(golden_data[i]), golden_data[i], $signed(recieved_data[i]), recieved_data[i]);
                end
                else if (j == `MAX_WRONG_ANSWER_DISPLAY) begin
                    $display("... and more");
                end
                j += 1;
            end
        end
        $display();
        $display("Recieved: %d / %d", recieved_data_count, golden_data_count);
        $display("Wrong answer count: %d", j);
        $display();
        $finish();
    end

end endtask

//---------------------------------------------------------------------
//  Solver
//---------------------------------------------------------------------

function automatic signed [63:0] eval_expression_tree(
    input [15:0] node_addr
);
    reg        [63:0] node_data;
    reg signed [63:0] left;
    reg signed [63:0] right;

    begin
        node_data = golden_DRAM[node_addr];
        
        if (!node_data[63])
            eval_expression_tree = {{33{node_data[62]}}, node_data[62:32]};
        else begin
            left  = eval_expression_tree(node_data[31:16]);
            right = eval_expression_tree(node_data[15: 0]);

            case (node_data[33:32])
                2'b00: eval_expression_tree = left + right;
                2'b01: eval_expression_tree = left - right;
                2'b10: eval_expression_tree = left * right;
                2'b11: eval_expression_tree = left >>> right[5:0];
            endcase
        end
    end
endfunction


task YOU_PASS_task; begin
    average_latency = ((m0_total_latency + (m0_patnum - 1)) / m0_patnum + (m1_total_latency + (m1_patnum - 1)) / m1_patnum + 1) / 2;

    $display("*************************************************************************");
    $display("*                         \033[32mCongratulations!\033[0m                              *");
    $display("*                                                                       *");
    $display("*          Mode 0 | Patnum = %4d | Total Latency = %10d          *", m0_patnum, m0_total_latency);
    $display("*          Mode 1 | Patnum = %4d | Total Latency = %10d          *", m1_patnum, m1_total_latency);
    $display("*          ---------------------------------------------------          *");
    $display("*                                 Average Latency = %10d          *", average_latency);

    if (average_latency <= 8000)
        $display("*                                        \033[32m(YOU PASS THE GOAL!!)\033[0m          *");

    $display("*                                                                       *");
    $display("*************************************************************************");
    $finish;
end endtask

endmodule

module AXI_Verifier #(parameter string NAME  = "Channel",
                      parameter CARRY_WIDTH  = 1,
                      parameter PRIOR_ACTIVE = 0) (
    input clk,
    input rst_n,
    input enable,

    input prior_handshake,

    input                   valid,
    input [CARRY_WIDTH-1:0] carry,
    
    input                   ready,

    input carry_invalid
);

// Parameters
parameter TIMEOUT1_CYCLE = 500;
parameter TIMEOUT2_CYCLE = 500;

// Monitoring variables
integer valid_standing;
integer prior_standing;

reg                   stable_valid;
reg [CARRY_WIDTH-1:0] prev_carry;

always @(negedge clk, negedge rst_n) begin
    if (!rst_n) begin
        valid_standing <= 0;
        prior_standing <= 0;

        stable_valid <= 0;
        prev_carry   <= 0;
    end
    else begin
        valid_standing <= (valid && !ready)? (valid_standing + 1) : 0;
        prior_standing <= ((valid && ready) || (prior_standing === 0 && !prior_handshake))? 0 : (prior_standing + 1);
    
        stable_valid <= !(valid && ready) && valid;
        prev_carry   <= carry;
    end
end

// Verification
always @(negedge clk) begin
    if (enable) begin
        if (^{valid, carry} === 1'bx) begin
            FAIL("Unknown detected");
        end
        if (valid === 0 && carry !== 0) begin
            FAIL("Carry should be reset when valid is low");
        end
        if (stable_valid === 1 && (valid === 0 || prev_carry !== carry)) begin
            FAIL("Valid and carry should be stable until handshake");
        end
        if (valid_standing >= TIMEOUT1_CYCLE) begin
            FAIL($sformatf("(Timeout 1) Ready should be high in %d cycles after valid pulled high", TIMEOUT1_CYCLE));
        end
        if (PRIOR_ACTIVE && (prior_standing >= TIMEOUT2_CYCLE)) begin
            FAIL($sformatf("(Timeout 2) Handshake should occur in %d cycles after prior channel handshake", TIMEOUT2_CYCLE));
        end
        if (valid && carry_invalid) begin
            FAIL($sformatf("Carry value (0x%16h) is invalid", carry));
        end
    end
end

task FAIL(string fail_msg); begin
    $display();
    $display("\033[31m*******************************************************************************\033[0m");
    $display("\033[31m* Channel: %-67s *\033[0m", NAME);
    $display("\033[31m* Message: %-67s *\033[0m", fail_msg);
    $display("\033[31m*******************************************************************************\033[0m");
    $finish();
end endtask

endmodule