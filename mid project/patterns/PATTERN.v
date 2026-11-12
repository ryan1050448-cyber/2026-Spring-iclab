//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2026 Spring Midterm Project: Dual-Core CPU 
//   Author                           : Ying-Yu Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN.v
//   Release version : V1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

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
`define PAT_NUM 9520
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 9520
`define MAX_WAIT_READY_CYCLE 100000
`endif

module PATTERN(
    //Output Port
    clk,
    rst_n,
    //Input Port
    stall_1,
    stall_2,
//===== AXI-4 Instruction1 DRAM =====
    arid_s_inf_inst_1,
    araddr_s_inf_inst_1,
    arlen_s_inf_inst_1,
    arsize_s_inf_inst_1,
    arburst_s_inf_inst_1,
    arvalid_s_inf_inst_1,
    arready_s_inf_inst_1,

    rid_s_inf_inst_1,
    rdata_s_inf_inst_1,
    rresp_s_inf_inst_1,
    rlast_s_inf_inst_1,
    rvalid_s_inf_inst_1,
    rready_s_inf_inst_1,

    awid_s_inf_inst_1,
    awaddr_s_inf_inst_1,
    awsize_s_inf_inst_1,
    awburst_s_inf_inst_1,
    awlen_s_inf_inst_1,
    awvalid_s_inf_inst_1,
    awready_s_inf_inst_1,
                
    wdata_s_inf_inst_1,
    wlast_s_inf_inst_1,
    wvalid_s_inf_inst_1,
    wready_s_inf_inst_1,

    bid_s_inf_inst_1,
    bresp_s_inf_inst_1,
    bvalid_s_inf_inst_1,
    bready_s_inf_inst_1,
//===== AXI-4 Instruction2 DRAM =====
    arid_s_inf_inst_2,
    araddr_s_inf_inst_2,
    arlen_s_inf_inst_2,
    arsize_s_inf_inst_2,
    arburst_s_inf_inst_2,
    arvalid_s_inf_inst_2,
    arready_s_inf_inst_2,

    rid_s_inf_inst_2,
    rdata_s_inf_inst_2,
    rresp_s_inf_inst_2,
    rlast_s_inf_inst_2,
    rvalid_s_inf_inst_2,
    rready_s_inf_inst_2,

    awid_s_inf_inst_2,
    awaddr_s_inf_inst_2,
    awsize_s_inf_inst_2,
    awburst_s_inf_inst_2,
    awlen_s_inf_inst_2,
    awvalid_s_inf_inst_2,
    awready_s_inf_inst_2,
                
    wdata_s_inf_inst_2,
    wlast_s_inf_inst_2,
    wvalid_s_inf_inst_2,
    wready_s_inf_inst_2,

    bid_s_inf_inst_2,
    bresp_s_inf_inst_2,
    bvalid_s_inf_inst_2,
    bready_s_inf_inst_2,  
//===== AXI-4 Data DRAM =====
    arid_s_inf_data,
    araddr_s_inf_data,
    arlen_s_inf_data,
    arsize_s_inf_data,
    arburst_s_inf_data,
    arvalid_s_inf_data,
    arready_s_inf_data,

    rid_s_inf_data,
    rdata_s_inf_data,
    rresp_s_inf_data,
    rlast_s_inf_data,
    rvalid_s_inf_data,
    rready_s_inf_data,

    awid_s_inf_data,
    awaddr_s_inf_data,
    awsize_s_inf_data,
    awburst_s_inf_data,
    awlen_s_inf_data,
    awvalid_s_inf_data,
    awready_s_inf_data,
                
    wdata_s_inf_data,
    wlast_s_inf_data,
    wvalid_s_inf_data,
    wready_s_inf_data,

    bid_s_inf_data,
    bresp_s_inf_data,
    bvalid_s_inf_data,
    bready_s_inf_data
);

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=16, BURST_LEN=7;
integer i, j;

integer latency_1, latency_2;
integer total_latency;

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
// output port
output reg clk, rst_n;
// input port
input wire  stall_1, stall_2;

//########################################### Instruction1 DRAM
// axi write addr channel 
// src master
input wire [ID_WIDTH-1:0]   awid_s_inf_inst_1; 
input wire [ADDR_WIDTH-1:0] awaddr_s_inf_inst_1;
input wire [2:0]            awsize_s_inf_inst_1; 
input wire [1:0]            awburst_s_inf_inst_1; 
input wire [BURST_LEN-1:0]  awlen_s_inf_inst_1;
input wire                  awvalid_s_inf_inst_1;
// src slave
output wire                   awready_s_inf_inst_1;
// -------------------------

// axi write data channel 
// src master
input wire [DATA_WIDTH-1:0] wdata_s_inf_inst_1;
input wire                  wlast_s_inf_inst_1;
input wire                  wvalid_s_inf_inst_1;
// src slave
output wire                   wready_s_inf_inst_1;

// axi write resp channel 
// src slave
output wire  [ID_WIDTH-1:0] bid_s_inf_inst_1; 
output wire  [1:0]          bresp_s_inf_inst_1; 
output wire                 bvalid_s_inf_inst_1;
// src master 
input wire                bready_s_inf_inst_1;
// ------------------------

// axi read addr channel 
// src master
input wire [ID_WIDTH-1:0]   arid_s_inf_inst_1; 
input wire [ADDR_WIDTH-1:0] araddr_s_inf_inst_1;
input wire [BURST_LEN-1:0]  arlen_s_inf_inst_1;
input wire [2:0]            arsize_s_inf_inst_1; 
input wire [1:0]            arburst_s_inf_inst_1; 
input wire                  arvalid_s_inf_inst_1;
// src slave
output wire                   arready_s_inf_inst_1;
// ------------------------

// axi read data channel 
// slave
output wire [ID_WIDTH-1:0]   rid_s_inf_inst_1; 
output wire [DATA_WIDTH-1:0] rdata_s_inf_inst_1;
output wire [1:0]            rresp_s_inf_inst_1; 
output wire                  rlast_s_inf_inst_1;
output wire                  rvalid_s_inf_inst_1;
// master
input wire                 rready_s_inf_inst_1;
// -----------------------------

//########################################### Instruction2 DRAM
// axi write addr channel 
// src master
input wire [ID_WIDTH-1:0]   awid_s_inf_inst_2; 
input wire [ADDR_WIDTH-1:0] awaddr_s_inf_inst_2;
input wire [2:0]            awsize_s_inf_inst_2; 
input wire [1:0]            awburst_s_inf_inst_2; 
input wire [BURST_LEN-1:0]  awlen_s_inf_inst_2;
input wire                  awvalid_s_inf_inst_2;
// src slave
output wire                   awready_s_inf_inst_2;
// -------------------------

// axi write data channel 
// src master
input wire [DATA_WIDTH-1:0] wdata_s_inf_inst_2;
input wire                  wlast_s_inf_inst_2;
input wire                  wvalid_s_inf_inst_2;
// src slave
output wire                   wready_s_inf_inst_2;

// axi write resp channel 
// src slave
output wire  [ID_WIDTH-1:0] bid_s_inf_inst_2; 
output wire  [1:0]          bresp_s_inf_inst_2; 
output wire                 bvalid_s_inf_inst_2;
// src master 
input wire                bready_s_inf_inst_2;
// ------------------------

// axi read addr channel 
// src master
input wire [ID_WIDTH-1:0]   arid_s_inf_inst_2; 
input wire [ADDR_WIDTH-1:0] araddr_s_inf_inst_2;
input wire [BURST_LEN-1:0]  arlen_s_inf_inst_2;
input wire [2:0]            arsize_s_inf_inst_2; 
input wire [1:0]            arburst_s_inf_inst_2; 
input wire                  arvalid_s_inf_inst_2;
// src slave
output wire                   arready_s_inf_inst_2;
// ------------------------

// axi read data channel 
// slave
output wire [ID_WIDTH-1:0]   rid_s_inf_inst_2; 
output wire [DATA_WIDTH-1:0] rdata_s_inf_inst_2;
output wire [1:0]            rresp_s_inf_inst_2; 
output wire                  rlast_s_inf_inst_2;
output wire                  rvalid_s_inf_inst_2;
// master
input wire                 rready_s_inf_inst_2;
// -----------------------------

//########################################### Data DRAM 
// axi write addr channel 
// src master
input wire [ID_WIDTH-1:0]   awid_s_inf_data; 
input wire [ADDR_WIDTH-1:0] awaddr_s_inf_data;
input wire [2:0]            awsize_s_inf_data; 
input wire [1:0]            awburst_s_inf_data; 
input wire [BURST_LEN-1:0]  awlen_s_inf_data;
input wire                  awvalid_s_inf_data;
// src slave
output wire                   awready_s_inf_data;
// -------------------------

// axi write data channel 
// src master
input wire [DATA_WIDTH-1:0] wdata_s_inf_data;
input wire                  wlast_s_inf_data;
input wire                  wvalid_s_inf_data;
// src slave
output wire                   wready_s_inf_data;

// axi write resp channel 
// src slave
output wire  [ID_WIDTH-1:0] bid_s_inf_data; 
output wire  [1:0]          bresp_s_inf_data; 
output wire                 bvalid_s_inf_data;
// src master 
input wire                bready_s_inf_data;
// ------------------------

// axi read addr channel 
// src master
input wire [ID_WIDTH-1:0]   arid_s_inf_data; 
input wire [ADDR_WIDTH-1:0] araddr_s_inf_data;
input wire [BURST_LEN-1:0]  arlen_s_inf_data;
input wire [2:0]            arsize_s_inf_data; 
input wire [1:0]            arburst_s_inf_data; 
input wire                  arvalid_s_inf_data;
// src slave
output wire                   arready_s_inf_data;
// ------------------------

// axi read data channel 
// slave
output wire [ID_WIDTH-1:0]   rid_s_inf_data; 
output wire [DATA_WIDTH-1:0] rdata_s_inf_data;
output wire [1:0]            rresp_s_inf_data; 
output wire                  rlast_s_inf_data;
output wire                  rvalid_s_inf_data;
// master
input wire                 rready_s_inf_data;
// -----------------------------

//---------------------------------------------------------------------
//  DRAM DECLARATION
//---------------------------------------------------------------------
pseudo_DRAM_inst1 u_pseudo_DRAM_inst1(
    .clk           (clk                  ),
    .rst_n         (rst_n                ),
    .awid_s_inf    (awid_s_inf_inst_1    ),
    .awaddr_s_inf  (awaddr_s_inf_inst_1  ),
    .awsize_s_inf  (awsize_s_inf_inst_1  ),
    .awburst_s_inf (awburst_s_inf_inst_1 ),
    .awlen_s_inf   (awlen_s_inf_inst_1   ),
    .awvalid_s_inf (awvalid_s_inf_inst_1 ),
    .awready_s_inf (awready_s_inf_inst_1 ),
    .wdata_s_inf   (wdata_s_inf_inst_1   ),
    .wlast_s_inf   (wlast_s_inf_inst_1   ),
    .wvalid_s_inf  (wvalid_s_inf_inst_1  ),
    .wready_s_inf  (wready_s_inf_inst_1  ),
    .bid_s_inf     (bid_s_inf_inst_1     ),
    .bresp_s_inf   (bresp_s_inf_inst_1   ),
    .bvalid_s_inf  (bvalid_s_inf_inst_1  ),
    .bready_s_inf  (bready_s_inf_inst_1  ),
    .arid_s_inf    (arid_s_inf_inst_1    ),
    .araddr_s_inf  (araddr_s_inf_inst_1  ),
    .arlen_s_inf   (arlen_s_inf_inst_1   ),
    .arsize_s_inf  (arsize_s_inf_inst_1  ),
    .arburst_s_inf (arburst_s_inf_inst_1 ),
    .arvalid_s_inf (arvalid_s_inf_inst_1 ),
    .arready_s_inf (arready_s_inf_inst_1 ),
    .rid_s_inf     (rid_s_inf_inst_1     ),
    .rdata_s_inf   (rdata_s_inf_inst_1   ),
    .rresp_s_inf   (rresp_s_inf_inst_1   ),
    .rlast_s_inf   (rlast_s_inf_inst_1   ),
    .rvalid_s_inf  (rvalid_s_inf_inst_1  ),
    .rready_s_inf  (rready_s_inf_inst_1  )
);

pseudo_DRAM_inst2 u_pseudo_DRAM_inst2(
    .clk           (clk                  ),
    .rst_n         (rst_n                ),
    .awid_s_inf    (awid_s_inf_inst_2    ),
    .awaddr_s_inf  (awaddr_s_inf_inst_2  ),
    .awsize_s_inf  (awsize_s_inf_inst_2  ),
    .awburst_s_inf (awburst_s_inf_inst_2 ),
    .awlen_s_inf   (awlen_s_inf_inst_2   ),
    .awvalid_s_inf (awvalid_s_inf_inst_2 ),
    .awready_s_inf (awready_s_inf_inst_2 ),
    .wdata_s_inf   (wdata_s_inf_inst_2   ),
    .wlast_s_inf   (wlast_s_inf_inst_2   ),
    .wvalid_s_inf  (wvalid_s_inf_inst_2  ),
    .wready_s_inf  (wready_s_inf_inst_2  ),
    .bid_s_inf     (bid_s_inf_inst_2     ),
    .bresp_s_inf   (bresp_s_inf_inst_2   ),
    .bvalid_s_inf  (bvalid_s_inf_inst_2  ),
    .bready_s_inf  (bready_s_inf_inst_2  ),
    .arid_s_inf    (arid_s_inf_inst_2    ),
    .araddr_s_inf  (araddr_s_inf_inst_2  ),
    .arlen_s_inf   (arlen_s_inf_inst_2   ),
    .arsize_s_inf  (arsize_s_inf_inst_2  ),
    .arburst_s_inf (arburst_s_inf_inst_2 ),
    .arvalid_s_inf (arvalid_s_inf_inst_2 ),
    .arready_s_inf (arready_s_inf_inst_2 ),
    .rid_s_inf     (rid_s_inf_inst_2     ),
    .rdata_s_inf   (rdata_s_inf_inst_2   ),
    .rresp_s_inf   (rresp_s_inf_inst_2   ),
    .rlast_s_inf   (rlast_s_inf_inst_2   ),
    .rvalid_s_inf  (rvalid_s_inf_inst_2  ),
    .rready_s_inf  (rready_s_inf_inst_2  )
);

pseudo_DRAM_data u_pseudo_DRAM_data(
    .clk           (clk                ),
    .rst_n         (rst_n              ),
    .awid_s_inf    (awid_s_inf_data    ),
    .awaddr_s_inf  (awaddr_s_inf_data  ),
    .awsize_s_inf  (awsize_s_inf_data  ),
    .awburst_s_inf (awburst_s_inf_data ),
    .awlen_s_inf   (awlen_s_inf_data   ),
    .awvalid_s_inf (awvalid_s_inf_data ),
    .awready_s_inf (awready_s_inf_data ),
    .wdata_s_inf   (wdata_s_inf_data   ),
    .wlast_s_inf   (wlast_s_inf_data   ),
    .wvalid_s_inf  (wvalid_s_inf_data  ),
    .wready_s_inf  (wready_s_inf_data  ),
    .bid_s_inf     (bid_s_inf_data     ),
    .bresp_s_inf   (bresp_s_inf_data   ),
    .bvalid_s_inf  (bvalid_s_inf_data  ),
    .bready_s_inf  (bready_s_inf_data  ),
    .arid_s_inf    (arid_s_inf_data    ),
    .araddr_s_inf  (araddr_s_inf_data  ),
    .arlen_s_inf   (arlen_s_inf_data   ),
    .arsize_s_inf  (arsize_s_inf_data  ),
    .arburst_s_inf (arburst_s_inf_data ),
    .arvalid_s_inf (arvalid_s_inf_data ),
    .arready_s_inf (arready_s_inf_data ),
    .rid_s_inf     (rid_s_inf_data     ),
    .rdata_s_inf   (rdata_s_inf_data   ),
    .rresp_s_inf   (rresp_s_inf_data   ),
    .rlast_s_inf   (rlast_s_inf_data   ),
    .rvalid_s_inf  (rvalid_s_inf_data  ),
    .rready_s_inf  (rready_s_inf_data  )
);

//---------------------------------------------------------------------
//   WIRE & REGISTER DECLARATION
//---------------------------------------------------------------------
reg signed [15:0] golden_regs [15:0];
reg signed [15:0] golden_data_dram [4095:0];

reg [15:0] inst1 [4095:0];
reg [15:0] inst2 [4095:0];

integer pc1, pc2; // program counter
integer ic1, ic2; // instruction counter


parameter CYCLE   = `CYCLE_TIME;
parameter PAT_NUM = `PAT_NUM;

//---------------------------------------------------------------------
//  INSTRUCTION PARSE & WRITE
//---------------------------------------------------------------------

parameter I_ADD   = 4'd0;
parameter I_SUB   = 4'd1;
parameter I_AND   = 4'd2;
parameter I_OR    = 4'd3;
parameter I_NAND  = 4'd4;
parameter I_NOR   = 4'd5;
parameter I_XOR   = 4'd6;
parameter I_STL   = 4'd7;
parameter I_MULT  = 4'd8;
parameter I_ADDI  = 4'd9;
parameter I_SUBI  = 4'd10;  
parameter I_LOAD  = 4'd11;
parameter I_STORE = 4'd12;
parameter I_BEQ   = 4'd13;
parameter I_JUMP  = 4'd14;

reg        [15:0] inst;
reg         [3:0] inst_type;
reg         [2:0] op_code;
reg         [2:0] rs, rt, rd, rl, func;
reg signed  [6:0] imm;
reg        [12:0] addr;

task parse_inst(); begin
    if (^inst === 1'bx) $display("[WARNING] x in read instruction, inst = %b", inst);

    op_code = inst[15:13];
    rs      = inst[12:10];
    rt      = inst[ 9: 7];
    rd      = inst[ 6: 4];
    rl      = inst[ 3: 1];
    func    = inst[ 3: 1];
    imm     = inst[ 6: 0];
    addr    = inst[12: 0];

    inst = 'bx;

    case (op_code)
        3'b000: begin
            case (func)
                3'b000: inst_type = I_ADD ;
                3'b001: inst_type = I_SUB ;
                3'b010: inst_type = I_AND ;
                3'b011: inst_type = I_OR  ;
                3'b100: inst_type = I_NAND;
                3'b101: inst_type = I_NOR ;
                3'b110: inst_type = I_XOR ;
                3'b111: inst_type = I_STL ;
            endcase
        end
        3'b001: inst_type = I_MULT ;
        3'b010: inst_type = I_ADDI ;
        3'b011: inst_type = I_SUBI ;
        3'b100: inst_type = I_LOAD ;
        3'b101: inst_type = I_STORE;
        3'b110: inst_type = I_BEQ  ;
        3'b111: inst_type = I_JUMP ;
    endcase
end endtask

function integer write_inst(reg core, integer pc); begin
    inst = 'bx;
    case (inst_type)
        I_ADD  : inst = {3'b000, rs, rt, rd, 3'b000, 1'b0};
        I_SUB  : inst = {3'b000, rs, rt, rd, 3'b001, 1'b0};
        I_AND  : inst = {3'b000, rs, rt, rd, 3'b010, 1'b0};
        I_OR   : inst = {3'b000, rs, rt, rd, 3'b011, 1'b0};
        I_NAND : inst = {3'b000, rs, rt, rd, 3'b100, 1'b0};
        I_NOR  : inst = {3'b000, rs, rt, rd, 3'b101, 1'b0};
        I_XOR  : inst = {3'b000, rs, rt, rd, 3'b110, 1'b0};
        I_STL  : inst = {3'b000, rs, rt, rd, 3'b111, 1'b0};
        I_MULT : inst = {3'b001, rs, rt, rd, rl, 1'b0};
        I_ADDI : inst = {3'b010, rs, rt, imm};
        I_SUBI : inst = {3'b011, rs, rt, imm};
        I_LOAD : inst = {3'b100, rs, rt, imm};
        I_STORE: inst = {3'b101, rs, rt, imm};
        I_BEQ  : inst = {3'b110, rs, rt, imm};
        I_JUMP : inst = {3'b111, addr};
    endcase
    if (^inst === 1'bx) $display("[WARNING] x in written instruction, inst_type = %d, inst = %b", inst_type, inst);

    if ((inst_type == I_BEQ && imm % 2 != 0) || (inst_type == I_JUMP && (addr / 2 - pc) % 2 == 0)) begin
        $display("[WARNING] even delta PC detected: inst_type = %d, inst = %b", inst_type, inst);
    end

    if (inst_type == I_STORE && pc % 2 == core) pc = pc + 1;

    if (!core) inst1[pc] = inst;
    else       inst2[pc] = inst;

    {inst_type, rs, rt, rd, rl, imm, addr} = 'bx;

    write_inst = pc + 1;
end endfunction

task print_inst(); 
    string s;
    begin
        case (inst_type)
            I_ADD  : begin
                if (rs == 0 && rt == 0 && rd == 0) s = "NOP";
                else s = $sformatf("ADD   r%d = r%d + r%d",        rd, rs, rt);
            end
            I_SUB  : s = $sformatf("SUB   r%d = r%d - r%d",        rd, rs, rt);
            I_AND  : s = $sformatf("AND   r%d = r%d & r%d",        rd, rs, rt);
            I_OR   : s = $sformatf("OR    r%d = r%d | r%d",        rd, rs, rt);
            I_NAND : s = $sformatf("NAND  r%d = ~(r%d & r%d)",     rd, rs, rt);
            I_NOR  : s = $sformatf("NOR   r%d = ~(r%d | r%d)",     rd, rs, rt);
            I_XOR  : s = $sformatf("XOR   r%d = r%d ^ r%d",        rd, rs, rt);
            I_STL  : s = $sformatf("STL   r%d = r%d < r%d",        rd, rs, rt);
            I_MULT : s = $sformatf("MULT  {r%d, r%d} = r%d * r%d", rd, rl, rs, rt);
            I_ADDI : s = $sformatf("ADDI  r%d = r%d + (%0d)",       rt, rs, imm);
            I_SUBI : s = $sformatf("SUBI  r%d = r%d - (%0d)",       rt, rs, imm);
            I_LOAD : s = $sformatf("LOAD  r%d <- D[(r%d + (%0d)) * 2 + 'h1000]", rt, rs, imm);
            I_STORE: s = $sformatf("STORE r%d -> D[(r%d + (%0d)) * 2 + 'h1000]", rt, rs, imm);
            I_BEQ  : s = $sformatf("BEQ   if (r%d == r%d), pc += %0d", rs, rt, 1 + imm);
            I_JUMP : s = $sformatf("JUMP  pc = %0d / 2", addr);
        endcase
        $write("| %-40s |", s);
    end 
endtask

function integer truncate(reg core, integer pc, reg [2:0] _rs, reg [2:0] r_temp); 
    integer j_pc;
    begin
        // slt temp rs r0
        // beq temp r0 +2
        // (rs >= 0) and  rs rs r7
        //           jump (+3)
        // nor  rs rs r0
        // nand rs rs r7

        {inst_type, rd, rs, rt} = {I_STL, r_temp, _rs, 3'd0};
        pc = write_inst(core, pc);

        {inst_type, rt, rs, imm} = {I_BEQ, r_temp, 3'd0, 7'd2};
        pc = write_inst(core, pc);
        
        {inst_type, rd, rs, rt} = {I_AND, _rs, _rs, 3'd7};
        pc = write_inst(core, pc);
        
        j_pc = pc + 3;
        {inst_type, addr} = {I_JUMP, j_pc[11:0], 1'b0};
        pc = write_inst(core, pc);
        
        {inst_type, rd, rs, rt} = {I_NOR, _rs, _rs, 3'd0};
        pc = write_inst(core, pc);
        
        {inst_type, rd, rs, rt} = {I_NAND, _rs, _rs, 3'd7};
        pc = write_inst(core, pc);

        truncate = pc;
    end 
endfunction


//---------------------------------------------------------------------
//   CLOCK
//---------------------------------------------------------------------
initial	clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//   TEST PATTERN                                         
//---------------------------------------------------------------------

initial begin
    generate_pattern(); 
    write_memory();
    async_reset_task();

    ic1 = 0;
    ic2 = 0;
    pc1 = 0;
    pc2 = 0;
    for (i = 0; i < 16; i = i + 1) begin
        golden_regs[i] = 0;
    end
    latency_1 = 0;
    latency_2 = 0;
    total_latency = 0;
    while (ic1 < PAT_NUM && ic2 < PAT_NUM) begin
        @(negedge clk);

        if (ic1 == ic2) begin
            if (inst1[pc1][15:13] == 3'b101 && inst2[pc2][15:13] == 3'b101) begin
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
                $display("\033[31m                                            \033[0m");
                $display("\033[31m >> Simultaneous store at IC = %d           \033[0m", ic1);
                $display("\033[31m                                            \033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $finish();
            end
            else if ((inst1[pc1][15:13] == 3'b101 && inst2[pc2][15:13] == 3'b100 &&  stall_1 && !stall_2) ||
                     (inst1[pc1][15:13] == 3'b100 && inst2[pc2][15:13] == 3'b101 && !stall_1 &&  stall_2)) begin
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
                $display("\033[31m                                            \033[0m");
                $display("\033[31m >> Load executed before store at IC = %d   \033[0m", ic1);
                $display("\033[31m                                            \033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $finish();
            end
        end
        
        if (ic1 == ic2 && !stall_1 && !stall_2 && inst2[pc2][15:13] == 3'b101) begin // If core 2 is store -> execute first
            $write("%-67s", " --- Core 2 execute first --- ");
            execute_inst(1'b1);
            $display();
            execute_inst(1'b0);
            $write("%67s", "");
        end
        else if (!stall_1 || !stall_2) begin
            if (!stall_1) execute_inst(1'b0);
            else          $write("%67s", "");
            if (!stall_2) execute_inst(1'b1);
            else          $write("%67s", "");
        end
        
        if (!stall_1 || !stall_2) begin
            verify_registers();
            $display("\033[32m == Pass == \033[0m");
        end

        if ((!stall_1 && ic1 < ic2 && ic1 % 50 == 0) || (!stall_2 && ic2 <= ic1 && ic2 % 50 == 0)) begin
            verify_data_dram();
            $display("\033[32m=============================== PASS DRAM CHECK of IC = %5d ===============================\033[0m", 
                    (ic1 < ic2)? ic1 : ic2);
        end
        
        latency_1 += 1;
        latency_2 += 1;
        total_latency += 1;

        if (!stall_1) latency_1 = 0;
        if (!stall_2) latency_2 = 0;

        if (latency_1 >= `MAX_WAIT_READY_CYCLE) begin
            $display("\033[31m--------------------------------------------\033[0m");
            $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
            $display("\033[31m                                            \033[0m");
            $display("\033[31m >> Core 1 latency exceed %d cycles         \033[0m", latency_1);
                $display("Current core 1 instruction: ");
                inst = inst1[pc1];
                parse_inst();
                print_inst();
                $display();

                $display("Current core 2 instruction: ");
                inst = inst2[pc2];
                parse_inst();
                print_inst();
                $display();
            $display("\033[31m                                            \033[0m");
            $display("\033[31m--------------------------------------------\033[0m");
            $display("\033[31m--------------------------------------------\033[0m");
            $finish();
        end
        if (latency_2 >= `MAX_WAIT_READY_CYCLE) begin
            $display("\033[31m--------------------------------------------\033[0m");
            $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
            $display("\033[31m                                            \033[0m");
            $display("\033[31m >> Core 2 latency exceed %d cycles         \033[0m", latency_2);
                $display("Current core 1 instruction: ");
                inst = inst1[pc1];
                parse_inst();
                print_inst();
                $display();

                $display("Current core 2 instruction: ");
                inst = inst2[pc2];
                parse_inst();
                print_inst();
                $display();
            $display("\033[31m                                            \033[0m");
            $display("\033[31m--------------------------------------------\033[0m");
            $display("\033[31m--------------------------------------------\033[0m");
            $finish();
        end
    end

    $display("\033[32m--------------------------------------------\033[0m");
    $display("\033[32m-------------- Congratulations --------------\033[0m");
    $display("\033[32m                                            \033[0m");
    $display("\033[32m >> Latency = %d cycles                     \033[0m", total_latency);
    $display("\033[32m                                            \033[0m");
    $display("\033[32m--------------------------------------------\033[0m");
    $display("\033[32m--------------------------------------------\033[0m");
    $finish();

end

task generate_pattern(); 
    reg core;
    integer pc;
    begin
        // random DRAM data
        for (i = 'h0000; i < 'h1000; i = i + 1) golden_data_dram[i] = $urandom_range(4095, 0) - 2048;
        for (i = 'h0000; i < 'h1000; i = i + 1) inst1[i] = 0;
        for (i = 'h0000; i < 'h1000; i = i + 1) inst2[i] = 0;

        core = 0;
        pc = 0;

        pc = set_reg_value(core, pc, 3'd7, 4095);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);

        {inst_type, addr} = {I_JUMP, 13'd0};
        write_inst(core, 4095);
        
        //$display("Instruction 1");
        //for (i = 0; i < pc; i = i + 1) begin
        //    inst = inst1[i];
        //    $write("%d, %b   ", i, inst);
        //    parse_inst();
        //    print_inst();
        //    $display();
        //end
        
        core = 1;
        pc = 0;

        pc = set_reg_value(core, pc, 3'd7, 4095);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);
        pc = generate_vector_operation(core, pc, 1000);
        pc = generate_vector_operation(core, pc, 2000);
        
        {inst_type, addr} = {I_JUMP, 13'd0};
        write_inst(core, 4095);
        
        //$display("Instruction 2");
        //for (i = 0; i < pc; i = i + 1) begin
        //    inst = inst2[i];
        //    $write("%d, %b   ", i, inst);
        //    parse_inst();
        //    print_inst();
        //    $display();
        //end
    end 
endtask

function integer set_reg_value(reg core, integer pc, reg [2:0] _r, reg signed [12:0] value);
    reg signed [6:0] val;
    integer diff, tmp;

    begin
        diff = 10000;
        for (i = 0; i < 65; i = i + 1) begin
            tmp = ((value > 0)? value : -value) - i * i;
            if (tmp < 0) tmp = -tmp;
            if (tmp < diff) begin
                val  = -i;
                diff = tmp;
            end
        end

        // x = val * val + delta
        diff = ((value > 0)? value : -value) - val * val;

        {inst_type, rt, rs, imm} = {I_ADDI, _r, 3'd0, val};
        pc = write_inst(core, pc);

        {inst_type, rd, rl, rs, rt} = {I_MULT, 3'd0, _r, _r, _r};
        pc = write_inst(core, pc);

        {inst_type, rt, rs, imm} = {I_ADDI, _r, _r, diff[6:0]};
        pc = write_inst(core, pc);

        // Neg
        if (value < 0) begin
            {inst_type, rd, rs, rt} = {I_NOR, _r, _r, 3'd0};
            pc = write_inst(core, pc);

            {inst_type, rt, rs, imm} = {I_ADDI, _r, 3'd0, 7'd1};
            pc = write_inst(core, pc);
        end

        set_reg_value = pc;
    end
endfunction

function integer generate_vector_operation(reg core, integer pc, integer ic_budget);
    integer loop_i;
    integer expr_i;
    integer n_pc;

    reg        [2:0] r_rand;
    reg signed [6:0] imm_rand;
    begin
        // (4 + 4 + 6 + 4(x + 4)) * abs(loop_i) = ic_budget
        loop_i = $urandom_range(15, 1);
        expr_i = (ic_budget - 30 * loop_i) / loop_i / 4;

        if (expr_i < 0)         expr_i = 1;
        if ($random() % 2 == 0) loop_i = -loop_i;

        // r7 <- r0 + 15
        {inst_type, rt, rs} = {I_ADDI, 3'd6, 3'd0};
        imm = loop_i;
        pc = write_inst(core, pc); 

        pc = set_reg_value(core, pc, 3'd1, $urandom_range(4000, 0));
        pc = set_reg_value(core, pc, 3'd2, $urandom_range(4000, 0));
        
        // nop
        n_pc = pc + 1;

        // Load vectors
        //
        // load r3 r1 +0
        // load r4 r1 +32
        // addi r1 r1 +1

        {inst_type, rt, rs, imm} = {I_LOAD, 3'd3, 3'd1, 7'd0};
        n_pc = write_inst(core, n_pc);
        {inst_type, rt, rs, imm} = {I_LOAD, 3'd4, 3'd1, 7'd32};
        n_pc = write_inst(core, n_pc);
        {inst_type, rt, rs, imm} = {I_ADDI, 3'd1, 3'd1, 7'd1};
        n_pc = write_inst(core, n_pc);

        // random on r5
        n_pc = set_reg_value(core, n_pc, 3'd5, ($urandom_range(8191, 0) - 4096));

        // Generate Expressions
        for (i = 0; i < expr_i; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                r_rand   = $urandom_range(5, 3);
                imm_rand = $urandom_range(255, 0) - 128;
                // ?op r(j+3) r(j+3) r_rand imm_rand
                inst_type = $urandom_range(10, 0);
                if (inst_type == I_MULT) begin
                    rs = (j + 3);
                    rt = r_rand;
                    rd = (j + 1) % 3 + 3;
                    rl = (j + 2) % 3 + 3;
                    n_pc = write_inst(core, n_pc);
                    
                    rs = (j + 3);
                    rl = (j + 2) % 3 + 3;
                    n_pc = truncate(core, n_pc, rl, rs);
                end
                else if (inst_type <= 7) begin
                    rd = (j + 3);
                    rs = (j + 3);
                    rt = r_rand;
                    n_pc = write_inst(core, n_pc);
                end
                else begin
                    rt = (j + 3);
                    {rs, imm} = {r_rand, imm_rand};
                    n_pc = write_inst(core, n_pc);
                end
            end
        end
//$display("%d", n_pc);
        // Saturate / Truncate   
        n_pc = truncate(core, n_pc, 3'd3, 3'd5);
        n_pc = truncate(core, n_pc, 3'd4, 3'd5);

        // Store vectors
        //
        // st   r3 r2 +0
        // addi r2 r2 +1
        // st   r4 r2 +31

//$display("%d", n_pc);
        {inst_type, rt, rs, imm} = {I_STORE, 3'd3, 3'd2, 7'd0};
        n_pc = write_inst(core, n_pc);
        
        {inst_type, rt, rs, imm} = {I_ADDI, 3'd2, 3'd2, 7'd1};
        n_pc = write_inst(core, n_pc);

        {inst_type, rt, rs, imm} = {I_STORE, 3'd4, 3'd2, 7'd31};
        n_pc = write_inst(core, n_pc);

        // slt  r5 r6 r0
        // beq  r5 r0 +4
        // add  r5 r5 r5
        // subi r5 r5 +1
        // add  r6 r6 r5
        // jump (pc or pc + 1)

        {inst_type, rd, rs, rt} = {I_STL, 3'd5, 3'd6, 3'd0};
        n_pc = write_inst(core, n_pc);

        {inst_type, rt, rs, imm} = {I_BEQ, 3'd5, 3'd0, 7'd4};
        n_pc = write_inst(core, n_pc);

        {inst_type, rd, rs, rt} = {I_ADD, 3'd5, 3'd5, 3'd5};
        n_pc = write_inst(core, n_pc);

        {inst_type, rt, rs, imm} = {I_SUBI, 3'd5, 3'd5, 7'd1};
        n_pc = write_inst(core, n_pc);

        {inst_type, rd, rs, rt} = {I_ADD, 3'd6, 3'd6, 3'd5};
        n_pc = write_inst(core, n_pc);



        pc = pc + (pc % 2 == n_pc % 2);
        {inst_type, addr} = {I_JUMP, pc[11:0], 1'b0};
        n_pc = write_inst(core, n_pc);

//$display("%d", n_pc);
        generate_vector_operation = n_pc;
    end 
endfunction



task async_reset_task; begin
    rst_n = 1;
    force clk = 0;

    #(CYCLE * 2.0); rst_n = 0;
    #(20.0); rst_n = 1;
    if (stall_1 !== 1 || stall_2  !== 1) begin        
        $display("*************************************************************************");
        $display("                      Stalls should be 1 after reset                     ");
        $display("*************************************************************************");
        $finish;
    end

    #(CYCLE * 2.0); release clk;
end endtask

task write_memory(); 
    integer f;
    begin
        // $display("CMP 1");
        // verify_data_dram();

        for (i = 'h0000; i < 'h1000; i = i + 1) 
            {u_pseudo_DRAM_inst1.DRAM_r[2 * i + 1], u_pseudo_DRAM_inst1.DRAM_r[2 * i]} = inst1[i];
        for (i = 'h0000; i < 'h1000; i = i + 1) 
            {u_pseudo_DRAM_inst2.DRAM_r[2 * i + 1], u_pseudo_DRAM_inst2.DRAM_r[2 * i]} = inst2[i];
        for (i = 'h0000; i < 'h1000; i = i + 1) 
            {u_pseudo_DRAM_data.DRAM_r[2 * i + 'h1001], u_pseudo_DRAM_data.DRAM_r[2 * i + 'h1000]} = golden_data_dram[i];

        // Inst 1
        f = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
        for (i = 0; i < 4096; i = i + 1) begin
            $fdisplay(f, "@%4h", i * 2);
            $fdisplay(f, "%2h %2h", inst1[i][7:0], inst1[i][15:8]);
        end
        $fclose(f);
        
        // Inst 2
        f = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
        for (i = 0; i < 4096; i = i + 1) begin
            $fdisplay(f, "@%4h", i * 2);
            $fdisplay(f, "%2h %2h", inst2[i][7:0], inst2[i][15:8]);
        end
        $fclose(f);

        // Data
        f = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
        for (i = 0; i < 4096; i = i + 1) begin
            $fdisplay(f, "@%8h", i * 2 + 'h1000);
            $fdisplay(f, "%2h %2h", golden_data_dram[i][7:0], golden_data_dram[i][15:8]);
        end
        $fclose(f);
    end 
endtask

task execute_inst (reg core);  
    integer temp;
    integer pc_next;

    reg [3:0] c_rs, c_rt, c_rd, c_rl;
    begin
        if (!core) inst = inst1[pc1];
        else       inst = inst2[pc2];
        parse_inst();

        if (1) begin
            if (!core) $write("IC = %5d; PC = %4d  ", ic1, pc1);
            else       $write("IC = %5d; PC = %4d  ", ic2, pc2);

            print_inst();
        end

        if (inst_type == I_STORE || inst_type == I_LOAD) begin
            if ((!core && ic1 > ic2) || (core && ic2 > ic1)) begin
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
                $display("\033[31m                                            \033[0m");
                $display("\033[31m >> Leading process execute DRAM action     \033[0m");
                $display("\033[31m                                            \033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $finish();
            end
        end

        c_rs = rs + core * 8;
        c_rt = rt + core * 8;
        c_rd = rd + core * 8;
        c_rl = rl + core * 8;

        if (!core) pc_next = pc1 + 1;
        else       pc_next = pc2 + 1;

        case (inst_type)
            I_ADD  : golden_regs[c_rd] =   golden_regs[c_rs] + golden_regs[c_rt] ;
            I_SUB  : golden_regs[c_rd] =   golden_regs[c_rs] - golden_regs[c_rt] ;
            I_AND  : golden_regs[c_rd] =   golden_regs[c_rs] & golden_regs[c_rt] ;
            I_OR   : golden_regs[c_rd] =   golden_regs[c_rs] | golden_regs[c_rt] ;
            I_NAND : golden_regs[c_rd] = ~(golden_regs[c_rs] & golden_regs[c_rt]);
            I_NOR  : golden_regs[c_rd] = ~(golden_regs[c_rs] | golden_regs[c_rt]);
            I_XOR  : golden_regs[c_rd] =   golden_regs[c_rs] ^ golden_regs[c_rt] ;
            I_STL  : golden_regs[c_rd] =  (golden_regs[c_rs] < golden_regs[c_rt]);
            I_MULT : begin
                temp = golden_regs[c_rs] * golden_regs[c_rt];
                {golden_regs[c_rd], golden_regs[c_rl]} = temp;
            end
            I_ADDI : golden_regs[c_rt] = golden_regs[c_rs] + imm;
            I_SUBI : golden_regs[c_rt] = golden_regs[c_rs] - imm;
            I_LOAD : golden_regs[c_rt] = golden_data_dram[golden_regs[c_rs] + imm];
            I_STORE: golden_data_dram[golden_regs[c_rs] + imm] = golden_regs[c_rt];
            I_BEQ  : begin
                if (golden_regs[c_rs] == golden_regs[c_rt]) 
                    pc_next = pc_next + imm;
            end
            I_JUMP : pc_next = addr / 2;
        endcase

        if (!core) begin
            pc1 = pc_next;
            ic1 = ic1 + 1;
        end
        else begin
            pc2 = pc_next;
            ic2 = ic2 + 1;
        end
    end 
endtask

task verify_registers(); 
    reg signed [15:0] DCCPU_regs [15:0];
    begin
        // Core 1 regs
        DCCPU_regs[ 0] = u_DCCPU.core_1_r0;
        DCCPU_regs[ 1] = u_DCCPU.core_1_r1;
        DCCPU_regs[ 2] = u_DCCPU.core_1_r2;
        DCCPU_regs[ 3] = u_DCCPU.core_1_r3;
        DCCPU_regs[ 4] = u_DCCPU.core_1_r4;
        DCCPU_regs[ 5] = u_DCCPU.core_1_r5;
        DCCPU_regs[ 6] = u_DCCPU.core_1_r6;
        DCCPU_regs[ 7] = u_DCCPU.core_1_r7;
        // Core 2 regs
        DCCPU_regs[ 8] = u_DCCPU.core_2_r0;
        DCCPU_regs[ 9] = u_DCCPU.core_2_r1;
        DCCPU_regs[10] = u_DCCPU.core_2_r2;
        DCCPU_regs[11] = u_DCCPU.core_2_r3;
        DCCPU_regs[12] = u_DCCPU.core_2_r4;
        DCCPU_regs[13] = u_DCCPU.core_2_r5;
        DCCPU_regs[14] = u_DCCPU.core_2_r6;
        DCCPU_regs[15] = u_DCCPU.core_2_r7;
        
        for (i = 0; i < 16; i = i + 1) begin
            if (golden_regs[i] !== DCCPU_regs[i]) begin
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
                $display("\033[31m                                            \033[0m");
                $display("\033[31m >> Wrong register value                    \033[0m");
                
                $display("Core 1:");
                $write("Golden: ");
                for (j = 7; j >= 0; j = j - 1) $write("%5d ", golden_regs[j]);
                $display();
                $write("DCCPU:  ");
                for (j = 7; j >= 0; j = j - 1) $write("%5d ", DCCPU_regs[j]);
                $display();

                $display("Core 2:");
                $write("Golden: ");
                for (j = 15; j >= 8; j = j - 1) $write("%5d ", golden_regs[j]);
                $display();
                $write("DCCPU:  ");
                for (j = 15; j >= 8; j = j - 1) $write("%5d ", DCCPU_regs[j]);
                $display();

                $display("Current core 1 instruction: ");
                inst = inst1[pc1];
                parse_inst();
                print_inst();
                $display();

                $display("Current core 2 instruction: ");
                inst = inst2[pc2];
                parse_inst();
                print_inst();
                $display();

                $display("\033[31m                                            \033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $display("\033[31m--------------------------------------------\033[0m");
                $finish;
            end
        end
    end 
endtask

task verify_data_dram(); begin
    for (i = 0; i < 4096; i = i + 1) begin
        if ({u_pseudo_DRAM_data.DRAM_r[2 * i + 'h1001], u_pseudo_DRAM_data.DRAM_r[2 * i + 'h1000]} 
                !== golden_data_dram[i]) begin
            
            $display();
            $display("\033[31m--------------------------------------------\033[0m");
            $display("\033[31m--------------- PATTERN FAIL ---------------\033[0m");
            $display("\033[31m                                            \033[0m");
            $display("\033[31m >> Wrong data dram value                   \033[0m");
            
            for (j = 0; j < 4096; j = j + 1)
                if ({u_pseudo_DRAM_data.DRAM_r[2 * j + 'h1001], u_pseudo_DRAM_data.DRAM_r[2 * j + 'h1000]} 
                        !== golden_data_dram[j]) begin
                    
                    $display("At {0x%4h, 0x%4h}: Golden = %5d (0x%4h), DCCPU = %5d (0x%4h)", 
                            (2 * j + 'h1001), (2 * j + 'h1000), 
                            golden_data_dram[j], golden_data_dram[j], 
                            $signed({u_pseudo_DRAM_data.DRAM_r[2 * j + 'h1001], u_pseudo_DRAM_data.DRAM_r[2 * j + 'h1000]}),
                            {u_pseudo_DRAM_data.DRAM_r[2 * j + 'h1001], u_pseudo_DRAM_data.DRAM_r[2 * j + 'h1000]});
                end

            $display("\033[31m                                            \033[0m");
            $display("\033[31m--------------------------------------------\033[0m");
            $display("\033[31m--------------------------------------------\033[0m");
            $finish;
        end
    end
end endtask

endmodule