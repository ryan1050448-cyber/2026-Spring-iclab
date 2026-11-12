`include "../00_TESTBED/DRAM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_inst1.v"
`include "../00_TESTBED/pseudo_DRAM_inst2.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"

`ifdef RTL
    `define CYCLE_TIME 5.0 
`elsif GATE
    `define CYCLE_TIME 5.0
`elsif CHIP
    `define CYCLE_TIME 20.0
`elsif POST
    `define CYCLE_TIME 20.0
`endif

`ifdef FUNC
`define PAT_NUM 952
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 952
`define MAX_WAIT_READY_CYCLE 100000
`endif

module PATTERN(
    //Output Port
    output reg clk,
    output reg rst_n,

    //===== AXI-4 Instruction1 DRAM (Slave to Master) =====
    output awready_s_inf_inst_1,
    output wready_s_inf_inst_1,
    output [3:0] bid_s_inf_inst_1,
    output [1:0] bresp_s_inf_inst_1,
    output bvalid_s_inf_inst_1,
    output arready_s_inf_inst_1,
    output [3:0] rid_s_inf_inst_1,
    output [15:0] rdata_s_inf_inst_1,
    output [1:0] rresp_s_inf_inst_1,
    output rlast_s_inf_inst_1,
    output rvalid_s_inf_inst_1,

    //===== AXI-4 Instruction2 DRAM (Slave to Master) =====
    output awready_s_inf_inst_2,
    output wready_s_inf_inst_2,
    output [3:0] bid_s_inf_inst_2,
    output [1:0] bresp_s_inf_inst_2,
    output bvalid_s_inf_inst_2,
    output arready_s_inf_inst_2,
    output [3:0] rid_s_inf_inst_2,
    output [15:0] rdata_s_inf_inst_2,
    output [1:0] rresp_s_inf_inst_2,
    output rlast_s_inf_inst_2,
    output rvalid_s_inf_inst_2,

    //===== AXI-4 Data DRAM (Slave to Master) =====
    output awready_s_inf_data,
    output wready_s_inf_data,
    output [3:0] bid_s_inf_data,
    output [1:0] bresp_s_inf_data,
    output bvalid_s_inf_data,
    output arready_s_inf_data,
    output [3:0] rid_s_inf_data,
    output [15:0] rdata_s_inf_data,
    output [1:0] rresp_s_inf_data,
    output rlast_s_inf_data,
    output rvalid_s_inf_data,

    //Input Port
    input stall_1,
    input stall_2,

    //===== AXI-4 Instruction1 DRAM (Master to Slave) =====
    input [3:0] awid_s_inf_inst_1,
    input [31:0] awaddr_s_inf_inst_1,
    input [6:0] awlen_s_inf_inst_1,
    input [2:0] awsize_s_inf_inst_1,
    input [1:0] awburst_s_inf_inst_1,
    input awvalid_s_inf_inst_1,
    input [15:0] wdata_s_inf_inst_1,
    input wlast_s_inf_inst_1,
    input wvalid_s_inf_inst_1,
    input bready_s_inf_inst_1,
    input [3:0] arid_s_inf_inst_1,
    input [31:0] araddr_s_inf_inst_1,
    input [6:0] arlen_s_inf_inst_1,
    input [2:0] arsize_s_inf_inst_1,
    input [1:0] arburst_s_inf_inst_1,
    input arvalid_s_inf_inst_1,
    input rready_s_inf_inst_1,

    //===== AXI-4 Instruction2 DRAM (Master to Slave) =====
    input [3:0] awid_s_inf_inst_2,
    input [31:0] awaddr_s_inf_inst_2,
    input [6:0] awlen_s_inf_inst_2,
    input [2:0] awsize_s_inf_inst_2,
    input [1:0] awburst_s_inf_inst_2,
    input awvalid_s_inf_inst_2,
    input [15:0] wdata_s_inf_inst_2,
    input wlast_s_inf_inst_2,
    input wvalid_s_inf_inst_2,
    input bready_s_inf_inst_2,
    input [3:0] arid_s_inf_inst_2,
    input [31:0] araddr_s_inf_inst_2,
    input [6:0] arlen_s_inf_inst_2,
    input [2:0] arsize_s_inf_inst_2,
    input [1:0] arburst_s_inf_inst_2,
    input arvalid_s_inf_inst_2,
    input rready_s_inf_inst_2,

    //===== AXI-4 Data DRAM (Master to Slave) =====
    input [3:0] awid_s_inf_data,
    input [31:0] awaddr_s_inf_data,
    input [6:0] awlen_s_inf_data,
    input [2:0] awsize_s_inf_data,
    input [1:0] awburst_s_inf_data,
    input awvalid_s_inf_data,
    input [15:0] wdata_s_inf_data,
    input wlast_s_inf_data,
    input wvalid_s_inf_data,
    input bready_s_inf_data,
    input [3:0] arid_s_inf_data,
    input [31:0] araddr_s_inf_data,
    input [6:0] arlen_s_inf_data,
    input [2:0] arsize_s_inf_data,
    input [1:0] arburst_s_inf_data,
    input arvalid_s_inf_data,
    input rready_s_inf_data
);

// ===============================================================
//  					Parameter & String Declaration 
// ===============================================================
parameter CYCLE = `CYCLE_TIME;
string reset_color          = "\033[1;0m";
string txt_black_prefix     = "\033[1;30m";
string txt_red_prefix       = "\033[1;31m";
string txt_green_prefix     = "\033[1;32m";
string txt_yellow_prefix    = "\033[1;33m";
string txt_blue_prefix      = "\033[1;34m";
string txt_magenta_prefix   = "\033[1;35m";
string txt_cyan_prefix      = "\033[1;36m";

// ===============================================================
//  					Variables Declaration 
// ===============================================================
integer ic_core1, ic_core2;
integer total_latency, latency_core1, latency_core2;
integer stall_1_cnt, stall_2_cnt;
integer fd_debug;
integer i;

// Golden DRAM array (8-bit array for Little Endian)
reg [7:0] golden_inst_1 [0:65535];
reg [7:0] golden_inst_2 [0:65535];
reg [7:0] golden_data   [0:65535];

// Core reg 
reg signed [15:0] golden_reg_1 [0:7];
reg signed [15:0] golden_reg_2 [0:7];
reg [15:0] pc_1, pc_2;

reg [15:0] curr_inst;
reg [2:0]  opcode, rs, rt, rd, func, rl;
reg [6:0]  imm;
reg [12:0] jump_addr;
reg signed [15:0] s_rd_val;

//---------------------------------------------------------------------
//   CLOCK
//---------------------------------------------------------------------
initial clk = 0;
always #(CYCLE / 2.0) clk = ~clk;

//---------------------------------------------------------------------
//   INSTANCE pseudo_DRAM 
//---------------------------------------------------------------------
pseudo_DRAM_inst1 u_DRAM_inst1 (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf(awid_s_inf_inst_1), .awaddr_s_inf(awaddr_s_inf_inst_1), .awlen_s_inf(awlen_s_inf_inst_1), .awsize_s_inf(awsize_s_inf_inst_1), .awburst_s_inf(awburst_s_inf_inst_1), .awvalid_s_inf(awvalid_s_inf_inst_1), .awready_s_inf(awready_s_inf_inst_1), 
    .wdata_s_inf(wdata_s_inf_inst_1), .wlast_s_inf(wlast_s_inf_inst_1), .wvalid_s_inf(wvalid_s_inf_inst_1), .wready_s_inf(wready_s_inf_inst_1),
    .bid_s_inf(bid_s_inf_inst_1), .bresp_s_inf(bresp_s_inf_inst_1), .bvalid_s_inf(bvalid_s_inf_inst_1), .bready_s_inf(bready_s_inf_inst_1),
    .arid_s_inf(arid_s_inf_inst_1), .araddr_s_inf(araddr_s_inf_inst_1), .arlen_s_inf(arlen_s_inf_inst_1), .arsize_s_inf(arsize_s_inf_inst_1), .arburst_s_inf(arburst_s_inf_inst_1), .arvalid_s_inf(arvalid_s_inf_inst_1), .arready_s_inf(arready_s_inf_inst_1),
    .rid_s_inf(rid_s_inf_inst_1), .rdata_s_inf(rdata_s_inf_inst_1), .rresp_s_inf(rresp_s_inf_inst_1), .rlast_s_inf(rlast_s_inf_inst_1), .rvalid_s_inf(rvalid_s_inf_inst_1), .rready_s_inf(rready_s_inf_inst_1)
);

pseudo_DRAM_inst2 u_DRAM_inst2 (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf(awid_s_inf_inst_2), .awaddr_s_inf(awaddr_s_inf_inst_2), .awlen_s_inf(awlen_s_inf_inst_2), .awsize_s_inf(awsize_s_inf_inst_2), .awburst_s_inf(awburst_s_inf_inst_2), .awvalid_s_inf(awvalid_s_inf_inst_2), .awready_s_inf(awready_s_inf_inst_2),
    .wdata_s_inf(wdata_s_inf_inst_2), .wlast_s_inf(wlast_s_inf_inst_2), .wvalid_s_inf(wvalid_s_inf_inst_2), .wready_s_inf(wready_s_inf_inst_2),
    .bid_s_inf(bid_s_inf_inst_2), .bresp_s_inf(bresp_s_inf_inst_2), .bvalid_s_inf(bvalid_s_inf_inst_2), .bready_s_inf(bready_s_inf_inst_2),
    .arid_s_inf(arid_s_inf_inst_2), .araddr_s_inf(araddr_s_inf_inst_2), .arlen_s_inf(arlen_s_inf_inst_2), .arsize_s_inf(arsize_s_inf_inst_2), .arburst_s_inf(arburst_s_inf_inst_2), .arvalid_s_inf(arvalid_s_inf_inst_2), .arready_s_inf(arready_s_inf_inst_2),
    .rid_s_inf(rid_s_inf_inst_2), .rdata_s_inf(rdata_s_inf_inst_2), .rresp_s_inf(rresp_s_inf_inst_2), .rlast_s_inf(rlast_s_inf_inst_2), .rvalid_s_inf(rvalid_s_inf_inst_2), .rready_s_inf(rready_s_inf_inst_2)
);

pseudo_DRAM_data u_DRAM_data (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf(awid_s_inf_data), .awaddr_s_inf(awaddr_s_inf_data), .awlen_s_inf(awlen_s_inf_data), .awsize_s_inf(awsize_s_inf_data), .awburst_s_inf(awburst_s_inf_data), .awvalid_s_inf(awvalid_s_inf_data), .awready_s_inf(awready_s_inf_data),
    .wdata_s_inf(wdata_s_inf_data), .wlast_s_inf(wlast_s_inf_data), .wvalid_s_inf(wvalid_s_inf_data), .wready_s_inf(wready_s_inf_data),
    .bid_s_inf(bid_s_inf_data), .bresp_s_inf(bresp_s_inf_data), .bvalid_s_inf(bvalid_s_inf_data), .bready_s_inf(bready_s_inf_data),
    .arid_s_inf(arid_s_inf_data), .araddr_s_inf(araddr_s_inf_data), .arlen_s_inf(arlen_s_inf_data), .arsize_s_inf(arsize_s_inf_data), .arburst_s_inf(arburst_s_inf_data), .arvalid_s_inf(arvalid_s_inf_data), .arready_s_inf(arready_s_inf_data),
    .rid_s_inf(rid_s_inf_data), .rdata_s_inf(rdata_s_inf_data), .rresp_s_inf(rresp_s_inf_data), .rlast_s_inf(rlast_s_inf_data), .rvalid_s_inf(rvalid_s_inf_data), .rready_s_inf(rready_s_inf_data)
);

//================================================================
//                          MAIN
//================================================================
initial begin
    generate_testcases_task; // Generate `.dat` files dynamically
    fd_debug = $fopen("../00_TESTBED/debug.txt", "w"); // Open debug log
    reset_task;
    set_env_task; 

    while (ic_core1 < `PAT_NUM || ic_core2 < `PAT_NUM) begin
        wait_stall_and_execute_task;
    end

    $fclose(fd_debug);
    you_pass_task;
end

//---------------------------------------------------------------------
//   TASKS
//---------------------------------------------------------------------
task generate_testcases_task;
    integer fd_i1, fd_i2, fd_d;
    integer i, c, pc_idx;
    integer target_pc; 
    integer s_imm_int;
    
    integer safe_base;
    integer small_data;
    integer base_choice;
    integer init_choice;
    integer seed;
    integer dummy;
    
    reg [15:0] inst;
    reg [2:0] g_op, g_rs, g_rt, g_rd, g_func, g_rl;
    reg [6:0] g_imm;
    reg [12:0] g_j_addr;
begin
    // =========================================================================
    // 0. Set Random Seed 
    // =========================================================================
    seed = 12345;                
    dummy = $urandom(seed);

    //$display(">>> Generating safe and random DRAM testcases...");
    fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    fd_d  = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");

    // =========================================================================
    // 1. Generate Data DRAM 
    // =========================================================================
    for (i = 0; i < 4096; i = i + 1) // 1000-2fff, total 8192 bytes -> 4096 lines
    begin 
        if (i == 0) begin
            // [Index 0] r5 Mask value: 0x000F (15) 
            $fdisplay(fd_d, "@%05X", 32'h1000 + i * 2);
            $fdisplay(fd_d, "0F 00"); 
        end 
        else if (i < 16) begin
            // [Index 1~15] r6, r7 Safe Base Addresses (16 ~ 2000)
            safe_base = $urandom_range(16, 2000);
            $fdisplay(fd_d, "@%05X", 32'h1000 + i * 2);
            $fdisplay(fd_d, "%02X %02X", safe_base[7:0], safe_base[15:8]);
        end 
        else begin
            // [Index 16~2047] random (-31 ~ +31)
            small_data = $urandom_range(0, 31);
            if ($urandom_range(0, 1)) 
                small_data = -small_data;
            $fdisplay(fd_d, "@%05X", 32'h1000 + i * 2);
            $fdisplay(fd_d, "%02X %02X", small_data[7:0], small_data[15:8]);
        end
    end

    // =========================================================================
    // 2. Generate Instructions
    // =========================================================================
    for (c = 1; c <= 2; c = c + 1) begin
        for (pc_idx = 0; pc_idx < 4096; pc_idx = pc_idx + 1) begin
            g_op = $urandom_range(0, 7);
            // r1-r4 operate
            g_rs = $urandom_range(1, 4); 
            g_rt = $urandom_range(1, 4);
            g_rd = $urandom_range(1, 4); 
            g_func = $urandom_range(0, 7);
            g_imm = $urandom_range(0, 15); 

            if (pc_idx == 0) begin
                g_op = 3'b100; // LOAD
                g_rs = 0;      // r0
                g_rt = 5;      // r5
                g_imm = 0;     
            end
            else if (pc_idx % 3 == 0) begin
                g_op = 3'b000;       // R-Type
                g_func = 3'b010;     // AND
                g_rs = 5;            // r5 (Mask = 15)
                
                // r1, r2, r3, r4 
                if (pc_idx % 12 == 0) g_rt = 1;
                else if (pc_idx % 12 == 3) g_rt = 2;
                else if (pc_idx % 12 == 6) g_rt = 3;
                else g_rt = 4;
                
                g_rd = g_rt; // AND r1 r1 r5...
            end
            
            // mult
            if (g_op == 3'b001) begin
                g_rl = $urandom_range(1, 4);
                if (g_rl == g_rd) 
                begin
                    if(g_rd == 4) 
                        g_rl = 1; 
                    else 
                        g_rl = g_rl + 1;
                end
            end

            // Constraint: LOAD / STORE 
            if (g_op == 3'b100 || g_op == 3'b101) begin
                // r0, r6, r7
                base_choice = $urandom_range(0, 2);
                if (base_choice == 0) 
                    g_rs = 0;
                else if (base_choice == 1) 
                    g_rs = 6;
                else 
                    g_rs = 7;
                
                g_imm = $urandom_range(16, 63); 

                if (g_op == 3'b100) begin 
                    init_choice = $urandom_range(0, 9);
                    if (init_choice == 0) begin
                        g_rs = 0; g_rt = 5; g_imm = 0; // load mask to r5
                    end 
                    else if (init_choice == 1) begin
                        g_rs = 0; g_rt = 6; g_imm = $urandom_range(1, 15); // load Base to r6
                    end 
                    else if (init_choice == 2) begin
                        g_rs = 0; g_rt = 7; g_imm = $urandom_range(1, 15); // load Base to r7
                    end
                end
            end

            // Constraint: Parity Store Access Check 
            if (g_op == 3'b101) begin // Store
                if (c == 1 && (pc_idx % 2 != 1)) // Core 1 Store in odd
                    g_op = 3'b100; 
                if (c == 2 && (pc_idx % 2 != 0)) // Core 2 Store in even
                    g_op = 3'b100; 
                
                if (g_op == 3'b100 && g_rt > 4) 
                    g_rt = $urandom_range(1, 4);
            end

            // Constraint: Jump & Branch (delta must be odd)
            if (g_op == 3'b110) begin // BEQ
                s_imm_int = ($urandom_range(0, 31) * 2) - 32; // -32 to 30, imm must be even
                if ($signed(pc_idx + 1) + s_imm_int < 0) 
                begin
                    s_imm_int = s_imm_int + 32;
                end
                if ($signed(pc_idx + 1) + s_imm_int > 4095) 
                begin
                    s_imm_int = s_imm_int - 32;
                end
                g_imm = s_imm_int[6:0]; 
            end 
            else if (g_op == 3'b111) begin // Jump
                target_pc = pc_idx + ($urandom_range(0, 31) - 16) * 2 + 1; // -31 to 31, must be odd
                if (target_pc < 0) 
                begin
                    target_pc = target_pc + 32;
                end
                if (target_pc > 4095) 
                begin
                    target_pc = target_pc - 32;
                end
                g_j_addr = target_pc * 2; 
            end

            // =========================================================================
            // 3. Assemble Instruction & Output
            // =========================================================================
            if (g_op != 3'b111) begin
                if (g_op == 3'b000) begin
                    inst = {g_op, g_rs, g_rt, g_rd, g_func, 1'b0};
                end 
                else if (g_op == 3'b001) begin
                    inst = {g_op, g_rs, g_rt, g_rd, g_rl, 1'b0}; 
                end
                else begin
                    inst = {g_op, g_rs, g_rt, g_imm};
                end
            end 
            else begin
                inst = {g_op, g_j_addr};
            end

            if (c == 1) begin
                $fdisplay(fd_i1, "@%05X", pc_idx * 2);
                $fdisplay(fd_i1, "%02X %02X", inst[7:0], inst[15:8]);
            end else begin
                $fdisplay(fd_i2, "@%05X", pc_idx * 2);
                $fdisplay(fd_i2, "%02X %02X", inst[7:0], inst[15:8]);
            end
        end
    end

    $fclose(fd_i1);
    $fclose(fd_i2);
    $fclose(fd_d);
    
    $readmemh("../00_TESTBED/DRAM/inst_1_dram_file.dat", u_DRAM_inst1.DRAM_r);
    $readmemh("../00_TESTBED/DRAM/inst_2_dram_file.dat", u_DRAM_inst2.DRAM_r);
    $readmemh("../00_TESTBED/DRAM/data_dram_file.dat", u_DRAM_data.DRAM_r);
end endtask

task reset_task; begin
    rst_n = 1'b1;
    ic_core1 = 0;
    ic_core2 = 0;
    pc_1 = 0; pc_2 = 0;
    stall_1_cnt = 0; stall_2_cnt = 0; total_latency = 0;
    latency_core1 = 0; latency_core2 = 0;

    for (i = 0; i < 8; i = i + 1) 
    begin
        golden_reg_1[i] = 16'd0;
        golden_reg_2[i] = 16'd0;
    end

    force clk = 0;
    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE*2.0) rst_n = 1;
    
    if (stall_1 !== 1'b1 || stall_2 !== 1'b1) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                stall signals must be high after initial reset      ");
        $display ("====================================================================");  
        $finish;
    end

    if (
        // ===== AXI-4 Instruction 1 DRAM =====
        awid_s_inf_inst_1 !== 0 || awaddr_s_inf_inst_1 !== 0 || awlen_s_inf_inst_1 !== 0 || awsize_s_inf_inst_1 !== 0 || awburst_s_inf_inst_1 !== 0 || awvalid_s_inf_inst_1 !== 0 ||
        wdata_s_inf_inst_1 !== 0 || wlast_s_inf_inst_1 !== 0 || wvalid_s_inf_inst_1 !== 0 || 
        bready_s_inf_inst_1 !== 0 || 
        arid_s_inf_inst_1 !== 0 || araddr_s_inf_inst_1 !== 0 || arlen_s_inf_inst_1 !== 0 || arsize_s_inf_inst_1 !== 0 || arburst_s_inf_inst_1 !== 0 || arvalid_s_inf_inst_1 !== 0 || 
        rready_s_inf_inst_1 !== 0 ||
        
        // ===== AXI-4 Instruction 2 DRAM =====
        awid_s_inf_inst_2 !== 0 || awaddr_s_inf_inst_2 !== 0 || awlen_s_inf_inst_2 !== 0 || awsize_s_inf_inst_2 !== 0 || awburst_s_inf_inst_2 !== 0 || awvalid_s_inf_inst_2 !== 0 ||
        wdata_s_inf_inst_2 !== 0 || wlast_s_inf_inst_2 !== 0 || wvalid_s_inf_inst_2 !== 0 || 
        bready_s_inf_inst_2 !== 0 || 
        arid_s_inf_inst_2 !== 0 || araddr_s_inf_inst_2 !== 0 || arlen_s_inf_inst_2 !== 0 || arsize_s_inf_inst_2 !== 0 || arburst_s_inf_inst_2 !== 0 || arvalid_s_inf_inst_2 !== 0 || 
        rready_s_inf_inst_2 !== 0 ||
        
        // ===== AXI-4 Data DRAM =====
        awid_s_inf_data !== 0 || awaddr_s_inf_data !== 0 || awlen_s_inf_data !== 0 || awsize_s_inf_data !== 0 || awburst_s_inf_data !== 0 || awvalid_s_inf_data !== 0 ||
        wdata_s_inf_data !== 0 || wlast_s_inf_data !== 0 || wvalid_s_inf_data !== 0 || 
        bready_s_inf_data !== 0 || 
        arid_s_inf_data !== 0 || araddr_s_inf_data !== 0 || arlen_s_inf_data !== 0 || arsize_s_inf_data !== 0 || arburst_s_inf_data !== 0 || arvalid_s_inf_data !== 0 || 
        rready_s_inf_data !== 0
    ) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                AXI signals must be low after initial reset         ");
        $display ("====================================================================");  
        $finish;
    end

    #(CYCLE); release clk;
end endtask

task set_env_task;
begin
    // copy DRAM content to golden DRAM array
    for (i = 0; i < 16'h2000; i = i + 1) begin
        golden_inst_1[i] = u_DRAM_inst1.DRAM_r[i];
        golden_inst_2[i] = u_DRAM_inst2.DRAM_r[i];
    end
    for (i = 16'h1000; i < 16'h3000; i = i + 1) begin
        golden_data[i] = u_DRAM_data.DRAM_r[i];
    end
end endtask

task wait_stall_and_execute_task; begin
    @(negedge clk);
    total_latency = total_latency + 1;
    if (ic_core1 < `PAT_NUM) latency_core1 = latency_core1 + 1;
    if (ic_core2 < `PAT_NUM) latency_core2 = latency_core2 + 1;
    
    stall_1_cnt = (stall_1 === 1'b1) ? stall_1_cnt + 1 : 0;
    stall_2_cnt = (stall_2 === 1'b1) ? stall_2_cnt + 1 : 0;
    
    if (stall_1_cnt > `MAX_WAIT_READY_CYCLE || stall_2_cnt > `MAX_WAIT_READY_CYCLE) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("        Stall is continuously high for more than %d cycles!         ", `MAX_WAIT_READY_CYCLE);
        $display ("====================================================================");
        $finish;
    end

    if (stall_1 === 1'b0 && ic_core1 < `PAT_NUM && stall_2 === 1'b0 && ic_core2 < `PAT_NUM) begin
        if (ic_core1 < ic_core2) begin
            check_core1_task;
            check_core2_task;
        end 
        else if (ic_core2 < ic_core1) begin
            check_core2_task;
            check_core1_task;
        end 
        else begin
            if (golden_inst_2[pc_2 * 2 + 1][7:5] === 3'b101) begin
                check_core2_task;
                check_core1_task;
            end 
            else if (golden_inst_1[pc_1 * 2 + 1][7:5] === 3'b101) begin
                check_core1_task;
                check_core2_task;
            end 
            else begin
                check_core1_task;
                check_core2_task;
            end
        end
    end 
    else if (stall_1 === 1'b0 && ic_core1 < `PAT_NUM) begin
        check_core1_task;
    end 
    else if (stall_2 === 1'b0 && ic_core2 < `PAT_NUM) begin
        check_core2_task;
    end
end endtask

task check_core1_task; begin
    generate_golden_ans_task(1); 
    
    if (u_DCCPU.core_1_r0 !== golden_reg_1[0]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r0 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[0], u_DCCPU.core_1_r0);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r1 !== golden_reg_1[1]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r1 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[1], u_DCCPU.core_1_r1);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r2 !== golden_reg_1[2]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r2 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[2], u_DCCPU.core_1_r2);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r3 !== golden_reg_1[3]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r3 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[3], u_DCCPU.core_1_r3);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r4 !== golden_reg_1[4]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r4 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[4], u_DCCPU.core_1_r4);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r5 !== golden_reg_1[5]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r5 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[5], u_DCCPU.core_1_r5);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r6 !== golden_reg_1[6]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r6 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[6], u_DCCPU.core_1_r6);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_1_r7 !== golden_reg_1[7]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 1 r7 mismatch at IC %d                  ", ic_core1);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_1[7], u_DCCPU.core_1_r7);
        $display ("=========================================================================");
        $finish;
    end

    if ((ic_core1 % 50 == 49) && (ic_core2 > ic_core1)) check_data_dram_task();
    $display("%0s Core 1 Instruction NO. %4d executed %0s", txt_blue_prefix, ic_core1, reset_color);
    ic_core1 = ic_core1 + 1;
end endtask

task check_core2_task; begin
    generate_golden_ans_task(2); 
    
    if (u_DCCPU.core_2_r0 !== golden_reg_2[0]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r0 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[0], u_DCCPU.core_2_r0);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r1 !== golden_reg_2[1]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r1 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[1], u_DCCPU.core_2_r1);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r2 !== golden_reg_2[2]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r2 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[2], u_DCCPU.core_2_r2);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r3 !== golden_reg_2[3]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r3 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[3], u_DCCPU.core_2_r3);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r4 !== golden_reg_2[4]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r4 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[4], u_DCCPU.core_2_r4);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r5 !== golden_reg_2[5]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r5 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[5], u_DCCPU.core_2_r5);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r6 !== golden_reg_2[6]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r6 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[6], u_DCCPU.core_2_r6);
        $display ("=========================================================================");
        $finish;
    end
    if (u_DCCPU.core_2_r7 !== golden_reg_2[7]) begin
        $display ("=========================================================================");
        $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
        $display ("                       Core 2 r7 mismatch at IC %d                  ", ic_core2);
        $display ("                       Expected: %04x, Actual: %04x                 ", golden_reg_2[7], u_DCCPU.core_2_r7);
        $display ("=========================================================================");
        $finish;
    end

    if ((ic_core2 % 50 == 49) && (ic_core1 > ic_core2)) check_data_dram_task();
    $display("%0s Core 2 Instruction NO. %4d executed %0s", txt_green_prefix, ic_core2, reset_color);
    ic_core2 = ic_core2 + 1;
end endtask

task generate_golden_ans_task;
    input integer core_id;
    reg signed [15:0] s_rs, s_rt, s_imm;
    reg signed [31:0] mul_temp;
    integer data_addr;
    integer inst_addr;
    string inst_str;
begin
    if (core_id == 1) begin
        inst_addr = pc_1 * 2;
        curr_inst = {golden_inst_1[inst_addr + 1], golden_inst_1[inst_addr]};
    end 
    else begin
        inst_addr = pc_2 * 2;
        curr_inst = {golden_inst_2[inst_addr + 1], golden_inst_2[inst_addr]};
    end
        
    opcode = curr_inst[15:13];
    rs = curr_inst[12:10]; 
    rt = curr_inst[9:7];
    rd = curr_inst[6:4];       
    rl = curr_inst[3:1];   
    func = curr_inst[3:1];
    imm = curr_inst[6:0];
    jump_addr = curr_inst[12:0];

    s_rs  = (core_id == 1) ? golden_reg_1[rs] : golden_reg_2[rs];
    s_rt  = (core_id == 1) ? golden_reg_1[rt] : golden_reg_2[rt];
    s_imm = {{9{imm[6]}}, imm}; 

    case (opcode)
        3'b000: begin // R-type
            case (func)
                3'b000: s_rd_val = s_rs + s_rt;
                3'b001: s_rd_val = s_rs - s_rt;
                3'b010: s_rd_val = s_rs & s_rt;
                3'b011: s_rd_val = s_rs | s_rt;
                3'b100: s_rd_val = ~(s_rs & s_rt);
                3'b101: s_rd_val = ~(s_rs | s_rt);
                3'b110: s_rd_val = s_rs ^ s_rt;
                3'b111: s_rd_val = (s_rs < s_rt) ? 16'd1 : 16'd0;
            endcase
            if (core_id == 1) begin 
                golden_reg_1[rd] = s_rd_val; 
                pc_1 = pc_1 + 1; 
            end 
            else begin 
                golden_reg_2[rd] = s_rd_val; 
                pc_2 = pc_2 + 1; 
            end
        end
        3'b001: begin // Mult-type
            mul_temp = s_rs * s_rt;
            if (core_id == 1) begin 
                golden_reg_1[rd] = mul_temp[31:16]; 
                golden_reg_1[rl] = mul_temp[15:0]; 
                pc_1 = pc_1 + 1; 
            end 
            else begin 
                golden_reg_2[rd] = mul_temp[31:16]; 
                golden_reg_2[rl] = mul_temp[15:0]; 
                pc_2 = pc_2 + 1; 
            end
        end
        3'b010: begin // ADDI
            if (core_id == 1) begin 
                golden_reg_1[rt] = s_rs + s_imm; 
                pc_1 = pc_1 + 1; 
            end 
            else begin 
                golden_reg_2[rt] = s_rs + s_imm; 
                pc_2 = pc_2 + 1; 
            end
        end
        3'b011: begin // SUBI
            if (core_id == 1) begin 
                golden_reg_1[rt] = s_rs - s_imm; 
                pc_1 = pc_1 + 1; 
            end 
            else begin 
                golden_reg_2[rt] = s_rs - s_imm; 
                pc_2 = pc_2 + 1; 
            end
        end
        3'b100: begin // Load 
            data_addr = (s_rs + s_imm) * 2 + 32'h1000;
            if (core_id == 1) begin 
                golden_reg_1[rt] = {golden_data[data_addr + 1], golden_data[data_addr]}; 
                pc_1 = pc_1 + 1; 
            end 
            else begin 
                golden_reg_2[rt] = {golden_data[data_addr + 1], golden_data[data_addr]}; 
                pc_2 = pc_2 + 1; 
            end
        end
        3'b101: begin // Store
            data_addr = (s_rs + s_imm) * 2 + 32'h1000;
            golden_data[data_addr]     = s_rt[7:0];
            golden_data[data_addr + 1] = s_rt[15:8];  
            if (core_id == 1) begin
                pc_1 = pc_1 + 1;
            end else begin
                pc_2 = pc_2 + 1;
            end
        end
        3'b110: begin // BEQ
            if (s_rs == s_rt) begin
                if (core_id == 1) 
                    pc_1 = pc_1 + 1 + s_imm; 
                else 
                    pc_2 = pc_2 + 1 + s_imm;
            end 
            else begin
                if (core_id == 1) 
                    pc_1 = pc_1 + 1; 
                else 
                    pc_2 = pc_2 + 1;
            end
        end
        3'b111: begin // Jump
            if (core_id == 1) 
                pc_1 = jump_addr >> 1; 
            else 
                pc_2 = jump_addr >> 1;
        end
    endcase

    case (opcode)
        3'b000: begin 
            case (func)
                3'b000: inst_str = $sformatf("ADD   r%0d, r%0d, r%0d", rd, rs, rt);
                3'b001: inst_str = $sformatf("SUB   r%0d, r%0d, r%0d", rd, rs, rt);
                3'b010: inst_str = $sformatf("AND   r%0d, r%0d, r%0d", rd, rs, rt);
                3'b011: inst_str = $sformatf("OR    r%0d, r%0d, r%0d", rd, rs, rt);
                3'b100: inst_str = $sformatf("NAND  r%0d, r%0d, r%0d", rd, rs, rt);
                3'b101: inst_str = $sformatf("NOR   r%0d, r%0d, r%0d", rd, rs, rt);
                3'b110: inst_str = $sformatf("XOR   r%0d, r%0d, r%0d", rd, rs, rt);
                3'b111: inst_str = $sformatf("SLT   r%0d, r%0d, r%0d", rd, rs, rt);
            endcase
        end
        3'b001: inst_str = $sformatf("MULT  r%0d, r%0d, r%0d, r%0d", rd, rl, rs, rt);
        3'b010: inst_str = $sformatf("ADDI  r%0d, r%0d, %0d", rt, rs, s_imm);
        3'b011: inst_str = $sformatf("SUBI  r%0d, r%0d, %0d", rt, rs, s_imm);
        3'b100: inst_str = $sformatf("LOAD  r%0d, r%0d, %0d", rt, rs, s_imm);
        3'b101: inst_str = $sformatf("STORE r%0d, r%0d, %0d", rt, rs, s_imm);
        3'b110: inst_str = $sformatf("BEQ   r%0d, r%0d, %0d", rs, rt, s_imm);
        3'b111: inst_str = $sformatf("JUMP  0x%04X", jump_addr);
    endcase

    // Write to Debug log
    $fdisplay(fd_debug, "--------------------------------------------------------");
    $fdisplay(fd_debug, "Core: %0d | IC: %04d | PC_idx: %04d | Inst: %04X | Opcode: %03b | %-20s"
                , core_id, (core_id==1) ? ic_core1 : ic_core2, inst_addr/2, curr_inst, opcode, inst_str);
    if (core_id == 1) begin
        $fdisplay(fd_debug, "R0:%04X  R1:%04X  R2:%04X  R3:%04X", golden_reg_1[0], golden_reg_1[1], golden_reg_1[2], golden_reg_1[3]);
        $fdisplay(fd_debug, "R4:%04X  R5:%04X  R6:%04X  R7:%04X", golden_reg_1[4], golden_reg_1[5], golden_reg_1[6], golden_reg_1[7]);
    end 
    else begin
        $fdisplay(fd_debug, "R0:%04X  R1:%04X  R2:%04X  R3:%04X", golden_reg_2[0], golden_reg_2[1], golden_reg_2[2], golden_reg_2[3]);
        $fdisplay(fd_debug, "R4:%04X  R5:%04X  R6:%04X  R7:%04X", golden_reg_2[4], golden_reg_2[5], golden_reg_2[6], golden_reg_2[7]);
    end
end endtask

task check_data_dram_task; begin
    reg print_fail_flag = 1;
    for (int k = 16'h1000; k < 16'h3000; k = k + 1) begin
        if (golden_data[k] !== u_DRAM_data.DRAM_r[k]) begin
            if(print_fail_flag) begin
                $display ("=========================================================================");
                $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
                $display ("                           Instruction NO. %04d (C1), %04d (C2)    ", ic_core1, ic_core2);
                $display ("                        DRAM status is incorrect                           ");
                print_fail_flag = 0;
            end
            $display ("          0x%04H      |         0x%02x            0x%02x        ", k, u_DRAM_data.DRAM_r[k], golden_data[k]);
        end
    end
    if(print_fail_flag == 0) $finish;
end endtask

task you_pass_task; begin
    $display("%0s======================================================================================================", txt_magenta_prefix);
	$display("                                     Congratulations!!");
    $display("                                    All Instructions Executed    ");
    $display("                                      Cycle time = %-2f ns", CYCLE);
    $display("                           Total execution cycles = %-4d cycles", total_latency);
    $display("========================================================================================================= %0s", reset_color);
	$finish;
end endtask

endmodule