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
//   File Name   : DCCPU.v
//   Module Name : DCCPU.v
//   Release version : V1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module DCCPU(
// Input
    clk,
    rst_n,
// Output
    stall_1,
    stall_2,
//===== AXI-4 Instruction1 DRAM =====
    arid_m_inf_inst_1,
    araddr_m_inf_inst_1,
    arlen_m_inf_inst_1,
    arsize_m_inf_inst_1,
    arburst_m_inf_inst_1,
    arvalid_m_inf_inst_1,
    arready_m_inf_inst_1,

    rid_m_inf_inst_1,
    rdata_m_inf_inst_1,
    rresp_m_inf_inst_1,
    rlast_m_inf_inst_1,
    rvalid_m_inf_inst_1,
    rready_m_inf_inst_1,

    //awid_m_inf_inst_1,
    //awaddr_m_inf_inst_1,
    //awsize_m_inf_inst_1,
    //awburst_m_inf_inst_1,
    //awlen_m_inf_inst_1,
    //awvalid_m_inf_inst_1,
    //awready_m_inf_inst_1,
    //            
    //wdata_m_inf_inst_1,
    //wlast_m_inf_inst_1,
    //wvalid_m_inf_inst_1,
    //wready_m_inf_inst_1,

    //bid_m_inf_inst_1,
    //bresp_m_inf_inst_1,
    //bvalid_m_inf_inst_1,
    //bready_m_inf_inst_1,
//===== AXI-4 Instruction2 DRAM =====
    arid_m_inf_inst_2,
    araddr_m_inf_inst_2,
    arlen_m_inf_inst_2,
    arsize_m_inf_inst_2,
    arburst_m_inf_inst_2,
    arvalid_m_inf_inst_2,
    arready_m_inf_inst_2,

    rid_m_inf_inst_2,
    rdata_m_inf_inst_2,
    rresp_m_inf_inst_2,
    rlast_m_inf_inst_2,
    rvalid_m_inf_inst_2,
    rready_m_inf_inst_2,

    //awid_m_inf_inst_2,
    //awaddr_m_inf_inst_2,
    //awsize_m_inf_inst_2,
    //awburst_m_inf_inst_2,
    //awlen_m_inf_inst_2,
    //awvalid_m_inf_inst_2,
    //awready_m_inf_inst_2,
    //            
    //wdata_m_inf_inst_2,
    //wlast_m_inf_inst_2,
    //wvalid_m_inf_inst_2,
    //wready_m_inf_inst_2,

    //bid_m_inf_inst_2,
    //bresp_m_inf_inst_2,
    //bvalid_m_inf_inst_2,
    //bready_m_inf_inst_2,  
//===== AXI-4 Data DRAM =====
    arid_m_inf_data,
    araddr_m_inf_data,
    arlen_m_inf_data,
    arsize_m_inf_data,
    arburst_m_inf_data,
    arvalid_m_inf_data,
    arready_m_inf_data,

    rid_m_inf_data,
    rdata_m_inf_data,
    rresp_m_inf_data,
    rlast_m_inf_data,
    rvalid_m_inf_data,
    rready_m_inf_data,

    awid_m_inf_data,
    awaddr_m_inf_data,
    awsize_m_inf_data,
    awburst_m_inf_data,
    awlen_m_inf_data,
    awvalid_m_inf_data,
    awready_m_inf_data,
                
    wdata_m_inf_data,
    wlast_m_inf_data,
    wvalid_m_inf_data,
    wready_m_inf_data,

    bid_m_inf_data,
    bresp_m_inf_data,
    bvalid_m_inf_data,
    bready_m_inf_data
);
// Input port
input wire clk, rst_n;
// Output port
output reg  stall_1, stall_2;

parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=16, BURST_LEN=7;

// AXI Interface wire connecttion for pseudo-DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

//########################################### Instruction1 DRAM
// axi write addr channel 
// src master
//output wire [ID_WIDTH-1:0]   awid_m_inf_inst_1; 
//output wire [ADDR_WIDTH-1:0] awaddr_m_inf_inst_1;
//output wire [2:0]            awsize_m_inf_inst_1; 
//output wire [1:0]            awburst_m_inf_inst_1; 
//output wire [BURST_LEN-1:0]  awlen_m_inf_inst_1;
//output wire                  awvalid_m_inf_inst_1;
//// src slave
//input wire                   awready_m_inf_inst_1;
//// -------------------------
//
//// axi write data channel 
//// src master
//output wire [DATA_WIDTH-1:0] wdata_m_inf_inst_1;
//output wire                  wlast_m_inf_inst_1;
//output wire                  wvalid_m_inf_inst_1;
//// src slave
//input wire                   wready_m_inf_inst_1;
//
//// axi write resp channel 
//// src slave
//input wire  [ID_WIDTH-1:0] bid_m_inf_inst_1; 
//input wire  [1:0]          bresp_m_inf_inst_1; 
//input wire                 bvalid_m_inf_inst_1;
//// src master 
//output wire                bready_m_inf_inst_1;
//// ------------------------

// axi read addr channel 
// src master
output wire [ID_WIDTH-1:0]   arid_m_inf_inst_1; 
output wire [ADDR_WIDTH-1:0] araddr_m_inf_inst_1;
output wire [BURST_LEN-1:0]  arlen_m_inf_inst_1;
output wire [2:0]            arsize_m_inf_inst_1; 
output wire [1:0]            arburst_m_inf_inst_1; 
output wire                  arvalid_m_inf_inst_1;
// src slave
input wire                   arready_m_inf_inst_1;
// ------------------------

// axi read data channel 
// slave
input wire [ID_WIDTH-1:0]   rid_m_inf_inst_1; 
input wire [DATA_WIDTH-1:0] rdata_m_inf_inst_1;
input wire [1:0]            rresp_m_inf_inst_1; 
input wire                  rlast_m_inf_inst_1;
input wire                  rvalid_m_inf_inst_1;
// master
output wire                 rready_m_inf_inst_1;
// -----------------------------

//########################################### Instruction2 DRAM
//// axi write addr channel 
//// src master
//output wire [ID_WIDTH-1:0]   awid_m_inf_inst_2; 
//output wire [ADDR_WIDTH-1:0] awaddr_m_inf_inst_2;
//output wire [2:0]            awsize_m_inf_inst_2; 
//output wire [1:0]            awburst_m_inf_inst_2; 
//output wire [BURST_LEN-1:0]  awlen_m_inf_inst_2;
//output wire                  awvalid_m_inf_inst_2;
//// src slave
//input wire                   awready_m_inf_inst_2;
//// -------------------------
//
//// axi write data channel 
//// src master
//output wire [DATA_WIDTH-1:0] wdata_m_inf_inst_2;
//output wire                  wlast_m_inf_inst_2;
//output wire                  wvalid_m_inf_inst_2;
//// src slave
//input wire                   wready_m_inf_inst_2;
//
//// axi write resp channel 
//// src slave
//input wire  [ID_WIDTH-1:0] bid_m_inf_inst_2; 
//input wire  [1:0]          bresp_m_inf_inst_2; 
//input wire                 bvalid_m_inf_inst_2;
//// src master 
//output wire                bready_m_inf_inst_2;
//// ------------------------

// axi read addr channel 
// src master
output wire [ID_WIDTH-1:0]   arid_m_inf_inst_2; 
output wire [ADDR_WIDTH-1:0] araddr_m_inf_inst_2;
output wire [BURST_LEN-1:0]  arlen_m_inf_inst_2;
output wire [2:0]            arsize_m_inf_inst_2; 
output wire [1:0]            arburst_m_inf_inst_2; 
output wire                  arvalid_m_inf_inst_2;
// src slave
input wire                   arready_m_inf_inst_2;
// ------------------------

// axi read data channel 
// slave
input wire [ID_WIDTH-1:0]   rid_m_inf_inst_2; 
input wire [DATA_WIDTH-1:0] rdata_m_inf_inst_2;
input wire [1:0]            rresp_m_inf_inst_2; 
input wire                  rlast_m_inf_inst_2;
input wire                  rvalid_m_inf_inst_2;
// master
output wire                 rready_m_inf_inst_2;
// -----------------------------

//########################################### Data DRAM 
// axi write addr channel 
// src master
output wire [ID_WIDTH-1:0]   awid_m_inf_data; 
output wire [ADDR_WIDTH-1:0] awaddr_m_inf_data;
output wire [2:0]            awsize_m_inf_data; 
output wire [1:0]            awburst_m_inf_data; 
output wire [BURST_LEN-1:0]  awlen_m_inf_data;
output wire                  awvalid_m_inf_data;
// src slave
input wire                   awready_m_inf_data;
// -------------------------

// axi write data channel 
// src master
output wire [DATA_WIDTH-1:0] wdata_m_inf_data;
output wire                  wlast_m_inf_data;
output wire                  wvalid_m_inf_data;
// src slave
input wire                   wready_m_inf_data;

// axi write resp channel 
// src slave
input wire  [ID_WIDTH-1:0] bid_m_inf_data; 
input wire  [1:0]          bresp_m_inf_data; 
input wire                 bvalid_m_inf_data;
// src master 
output wire                bready_m_inf_data;
// ------------------------

// axi read addr channel 
// src master
output wire [ID_WIDTH-1:0]   arid_m_inf_data; 
output wire [ADDR_WIDTH-1:0] araddr_m_inf_data;
output wire [BURST_LEN-1:0]  arlen_m_inf_data;
output wire [2:0]            arsize_m_inf_data; 
output wire [1:0]            arburst_m_inf_data; 
output wire                  arvalid_m_inf_data;
// src slave
input wire                   arready_m_inf_data;
// ------------------------

// axi read data channel 
// slave
input wire [ID_WIDTH-1:0]   rid_m_inf_data; 
input wire [DATA_WIDTH-1:0] rdata_m_inf_data;
input wire [1:0]            rresp_m_inf_data; 
input wire                  rlast_m_inf_data;
input wire                  rvalid_m_inf_data;
// master
output wire                 rready_m_inf_data;
// -----------------------------
//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/
reg [15:0] core_1_r0, core_1_r1, core_1_r2, core_1_r3;
reg [15:0] core_1_r4, core_1_r5, core_1_r6, core_1_r7;
reg [15:0] core_2_r0, core_2_r1, core_2_r2, core_2_r3;
reg [15:0] core_2_r4, core_2_r5, core_2_r6, core_2_r7;
// -----------------------------
parameter IDLE = 0;
parameter FB = 1;
parameter OPER = 2;

//==================================================================
// Declaration
//==================================================================
reg next_stall_1, next_stall_2;
reg first_burst1, first_burst2, fb1, next_fb1, fb2, next_fb2;
reg cpu_req_valid1, cpu_req_valid2;
reg [ADDR_WIDTH-1:0] cpu_req_addr1, cpu_req_addr2;
reg data_req_valid, data_req_write, data_core_id;
reg [ADDR_WIDTH-1:0] data_req_addr;
reg [DATA_WIDTH-1:0] data_req_wdata;
reg [15:0] next_core_1_r0, next_core_1_r1, next_core_1_r2, next_core_1_r3, next_core_1_r4, next_core_1_r5, next_core_1_r6, next_core_1_r7;
reg [15:0] next_core_2_r0, next_core_2_r1, next_core_2_r2, next_core_2_r3, next_core_2_r4, next_core_2_r5, next_core_2_r6, next_core_2_r7;
reg [2:0] state1, next_state1, state2, next_state2;
reg [15:0] inst1, next_inst1, inst2, next_inst2;
reg op_done1, op_done2, next_op_done1, next_op_done2;
reg store1_valid, next_store1_valid, store2_valid, next_store2_valid;
reg [12:0] pc1, next_pc1, pc2, next_pc2;
reg [6:0] ic1, next_ic1, ic2, next_ic2;
reg [2:0] mct1, next_mct1;
reg load_valid1, next_load_valid1, load_valid2, next_load_valid2;
reg [1:0] alu_core, next_alu_core;
reg signed [15:0] rs, rt, rd, rl, mrs, next_mrs, mrt, next_mrt, mrd, next_mrd, mrl, next_mrl;
reg signed [6:0] imm;
reg [15:0] alu_inst;
reg [15:0] local_addr;

wire axi_done1, axi_done2;
wire [DATA_WIDTH-1:0] axi_rdata1, axi_rdata2;
wire data_axi_done;
wire [ID_WIDTH-1:0] data_axi_id;
wire [DATA_WIDTH-1:0] data_axi_rdata;

//###########################################
//
// Wrtie down your design below
//
//##################################################
AXI_INST #(
    .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH), .BURST_LEN(BURST_LEN)
)u_inst1 (
    .clk(clk),
    .rst_n(rst_n),
    .first_burst(first_burst1),
    .cpu_req_valid(cpu_req_valid1),
    .cpu_req_addr(cpu_req_addr1),
    .axi_done(axi_done1),
    .axi_rdata(axi_rdata1),

    .arid(arid_m_inf_inst_1),
    .araddr(araddr_m_inf_inst_1),
    .arlen(arlen_m_inf_inst_1),
    .arsize(arsize_m_inf_inst_1),
    .arburst(arburst_m_inf_inst_1),
    .arvalid(arvalid_m_inf_inst_1),
    .arready(arready_m_inf_inst_1),

    .rid(rid_m_inf_inst_1),
    .rdata(rdata_m_inf_inst_1),
    .rresp(rresp_m_inf_inst_1),
    .rlast(rlast_m_inf_inst_1),
    .rvalid(rvalid_m_inf_inst_1),
    .rready(rready_m_inf_inst_1)
);
AXI_INST #(
    .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH), .BURST_LEN(BURST_LEN)
)u_inst2 (
    .clk(clk),
    .rst_n(rst_n),
    .first_burst(first_burst2),
    .cpu_req_valid(cpu_req_valid2),
    .cpu_req_addr(cpu_req_addr2),
    .axi_done(axi_done2),
    .axi_rdata(axi_rdata2),

    .arid(arid_m_inf_inst_2),
    .araddr(araddr_m_inf_inst_2),
    .arlen(arlen_m_inf_inst_2),
    .arsize(arsize_m_inf_inst_2),
    .arburst(arburst_m_inf_inst_2),
    .arvalid(arvalid_m_inf_inst_2),
    .arready(arready_m_inf_inst_2),

    .rid(rid_m_inf_inst_2),
    .rdata(rdata_m_inf_inst_2),
    .rresp(rresp_m_inf_inst_2),
    .rlast(rlast_m_inf_inst_2),
    .rvalid(rvalid_m_inf_inst_2),
    .rready(rready_m_inf_inst_2)
);
AXI_DATA #(
    .ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH), .BURST_LEN(BURST_LEN)
)u_data (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_req_valid(data_req_valid),
    .cpu_req_write(data_req_write),
    .core_id(data_core_id),
    .cpu_req_addr(data_req_addr),
    .cpu_req_wdata(data_req_wdata),
    .axi_done(data_axi_done),
    .axi_id(data_axi_id),
    .axi_rdata(data_axi_rdata),

    .awid(awid_m_inf_data),
    .awaddr(awaddr_m_inf_data),
    .awsize(awsize_m_inf_data),
    .awburst(awburst_m_inf_data),
    .awlen(awlen_m_inf_data),
    .awvalid(awvalid_m_inf_data),
    .awready(awready_m_inf_data),

    .wdata(wdata_m_inf_data),
    .wlast(wlast_m_inf_data),
    .wvalid(wvalid_m_inf_data),
    .wready(wready_m_inf_data),

    .bid(bid_m_inf_data),
    .bresp(bresp_m_inf_data),
    .bvalid(bvalid_m_inf_data),
    .bready(bready_m_inf_data),

    .arid(arid_m_inf_data),
    .araddr(araddr_m_inf_data),
    .arlen(arlen_m_inf_data),
    .arsize(arsize_m_inf_data),
    .arburst(arburst_m_inf_data),
    .arvalid(arvalid_m_inf_data),
    .arready(arready_m_inf_data),

    .rid(rid_m_inf_data),
    .rdata(rdata_m_inf_data),
    .rresp(rresp_m_inf_data),
    .rlast(rlast_m_inf_data),
    .rvalid(rvalid_m_inf_data),
    .rready(rready_m_inf_data)
);

// submodule signal
always @(*)
begin
    first_burst1 = 0; first_burst2 = 0;
    cpu_req_valid1 = 0; cpu_req_valid2 = 0;
    cpu_req_addr1 = 0; cpu_req_addr2 = 0;
    data_req_valid = 0; data_req_write = 0; data_core_id = 0; 
    data_req_addr = 0; data_req_wdata = 0;
    next_fb1 = fb1; next_fb2 = fb2;
    next_inst1 = inst1; next_inst2 = inst2;
    next_load_valid1 = load_valid1; next_load_valid2 = load_valid2;
    next_store1_valid = store1_valid; next_store2_valid = store2_valid;
    next_alu_core = alu_core;
    local_addr = 0;

    if(fb1 == 0)
    begin
        first_burst1 = 1;
        cpu_req_valid1 = 1;
        cpu_req_addr1 = 0;
        next_fb1 = 1;
    end
    if(fb2 == 0)
    begin
        first_burst2 = 1;
        cpu_req_valid2 = 1;
        cpu_req_addr2 = 0;
        next_fb2 = 1;
    end
    if(state1 == FB && axi_done1)
    begin
        next_inst1 = axi_rdata1;
    end
    if(state2 == FB && axi_done2)
    begin
        next_inst2 = axi_rdata2;
    end

    // alu core1 first, except core2 is store
    if(state1 == OPER)
    begin
        next_alu_core = 1;// core1 alu
        if(state2 == IDLE && op_done2 == 0)// wait core2 inst
            next_alu_core = 0;
        if(state2 == OPER && inst2[15:13] == 3'b101)// wait core2 store done
            next_alu_core = 2;// core2 alu
    end
    if(next_op_done1 == 1 && op_done2 == 0)// core1 alu done, core2 not done
        next_alu_core = 2;// core2 alu
    if(state2 == OPER && inst2[15:13] == 3'b101)// core2 store
        next_alu_core = 2;// core2 alu

    if(op_done1 == 1 && op_done2 == 1)// both cores done
        next_alu_core = 0;// no alu

    if(state1 == OPER && inst1[15:13] == 3'b101 && alu_core == 1)// core1 store
    begin
        next_store1_valid = 1;
    end
    if(state2 == OPER && inst2[15:13] == 3'b101 && alu_core == 2)// core2 store
    begin
        next_store2_valid = 1;
    end

    if(state1 == OPER && inst1[15:13] == 3'b100 && alu_core == 1)// core1 load
    begin
        next_load_valid1 = 1;
    end
    if(state2 == OPER && inst2[15:13] == 3'b100 && alu_core == 2)// core2 load
    begin
        next_load_valid2 = 1;
    end

    if(op_done1 == 1)
    begin
        next_load_valid1 = 0;
        next_store1_valid = 0;
    end
    if(op_done2 == 1)
    begin
        next_load_valid2 = 0;
        next_store2_valid = 0;
    end

    if(state1 == OPER && inst1[15:13] == 3'b100 && load_valid1 == 0 && next_load_valid1 == 1)// load core1(trigger once)
    begin
        data_req_valid = 1;
        data_req_write = 0;// read
        data_core_id = 0;// core 1
        local_addr = ((rs + {{9{imm[6]}}, imm}) << 1) + 16'h1000;
        data_req_addr = {16'h0, local_addr};
        data_req_wdata = 0;
    end
    if(state1 == OPER && inst1[15:13] == 3'b101 && store1_valid == 0 && next_store1_valid == 1)// store core1(trigger once)
    begin
        data_req_valid = 1;
        data_req_write = 1;// write
        data_core_id = 0;// core 1
        local_addr = ((rs + {{9{imm[6]}}, imm}) << 1) + 16'h1000;
        data_req_addr = {16'h0, local_addr};
        data_req_wdata = rt;
    end

    if(state2 == OPER && inst2[15:13] == 3'b100 && load_valid2 == 0 && next_load_valid2 == 1)// load core2(trigger once)
    begin
        data_req_valid = 1;
        data_req_write = 0;// read
        data_core_id = 1;// core 2
        local_addr = ((rs + {{9{imm[6]}}, imm}) << 1) + 16'h1000;
        data_req_addr = {16'h0, local_addr};
        data_req_wdata = 0;
    end
    if(state2 == OPER && inst2[15:13] == 3'b101 && store2_valid == 0 && next_store2_valid == 1)// store core2(trigger once)
    begin
        data_req_valid = 1;
        data_req_write = 1;// write
        data_core_id = 1;// core 2
        local_addr = ((rs + {{9{imm[6]}}, imm}) << 1) + 16'h1000;
        data_req_addr = {16'h0, local_addr};
        data_req_wdata = rt;
    end

    if(op_done1 && op_done2 && pc1 <= 4095 && pc2 <= 4095)// both cores are done, next instruction
    begin
        cpu_req_valid1 = 1;
        cpu_req_addr1 = pc1 << 1;
        cpu_req_valid2 = 1;
        cpu_req_addr2 = pc2 << 1;
    end
    if(state1 == IDLE && axi_done1)
    begin
        next_inst1 = axi_rdata1;
    end
    if(state2 == IDLE && axi_done2)
    begin
        next_inst2 = axi_rdata2;
    end

end

//core reg
always @(*)
begin
    next_core_1_r0 = core_1_r0; next_core_1_r1 = core_1_r1;
    next_core_1_r2 = core_1_r2; next_core_1_r3 = core_1_r3;
    next_core_1_r4 = core_1_r4; next_core_1_r5 = core_1_r5;
    next_core_1_r6 = core_1_r6; next_core_1_r7 = core_1_r7;
    next_core_2_r0 = core_2_r0; next_core_2_r1 = core_2_r1;
    next_core_2_r2 = core_2_r2; next_core_2_r3 = core_2_r3;
    next_core_2_r4 = core_2_r4; next_core_2_r5 = core_2_r5;
    next_core_2_r6 = core_2_r6; next_core_2_r7 = core_2_r7;
    rs = 0; rt = 0; rd = 0; rl = 0;
    next_mrs = mrs; next_mrt = mrt; next_mrd = mrd; next_mrl = mrl;
    next_op_done1 = op_done1; next_op_done2 = op_done2;
    imm = 0;
    next_pc1 = pc1; next_pc2 = pc2;
    next_ic1 = ic1; next_ic2 = ic2;
    next_mct1 = mct1; 
    alu_inst = 0;

    if(state1 == OPER && alu_core == 1)// core1 operating
    begin
        alu_inst = inst1;
    end
    if(state2 == OPER && alu_core == 2)// core2 operating
    begin
        alu_inst = inst2;
    end
    // alu
    if((state1 == OPER && alu_core == 1) || (state2 == OPER && alu_core == 2))
    begin
        case(alu_inst[12:10])//rs
                0: rs = (alu_core == 1) ? core_1_r0 : core_2_r0;
                1: rs = (alu_core == 1) ? core_1_r1 : core_2_r1;
                2: rs = (alu_core == 1) ? core_1_r2 : core_2_r2;
                3: rs = (alu_core == 1) ? core_1_r3 : core_2_r3;
                4: rs = (alu_core == 1) ? core_1_r4 : core_2_r4;
                5: rs = (alu_core == 1) ? core_1_r5 : core_2_r5;
                6: rs = (alu_core == 1) ? core_1_r6 : core_2_r6;
                7: rs = (alu_core == 1) ? core_1_r7 : core_2_r7;
            endcase
            case(alu_inst[9:7])//rt
                0: rt = (alu_core == 1) ? core_1_r0 : core_2_r0;
                1: rt = (alu_core == 1) ? core_1_r1 : core_2_r1;
                2: rt = (alu_core == 1) ? core_1_r2 : core_2_r2;
                3: rt = (alu_core == 1) ? core_1_r3 : core_2_r3;
                4: rt = (alu_core == 1) ? core_1_r4 : core_2_r4;
                5: rt = (alu_core == 1) ? core_1_r5 : core_2_r5;
                6: rt = (alu_core == 1) ? core_1_r6 : core_2_r6;
                7: rt = (alu_core == 1) ? core_1_r7 : core_2_r7;
            endcase
        imm = alu_inst[6:0];

        if(alu_inst[15:13] == 0)// r-type
        begin
            case(alu_inst[3:1])
                3'b000: rd = rs + rt; // add
                3'b001: rd = rs - rt; // sub
                3'b010: rd = rs & rt; // and
                3'b011: rd = rs | rt; // or
                3'b100: rd = ~(rs & rt); // nand
                3'b101: rd = ~(rs | rt); // nor
                3'b110: rd = rs ^ rt; // xor
                3'b111: rd = (rs < rt) ? 1 : 0; // slt
            endcase
            if(alu_core == 1)
            begin
                case (alu_inst[6:4])//rd
                    0: next_core_1_r0 = rd;
                    1: next_core_1_r1 = rd;
                    2: next_core_1_r2 = rd;
                    3: next_core_1_r3 = rd;
                    4: next_core_1_r4 = rd;
                    5: next_core_1_r5 = rd;
                    6: next_core_1_r6 = rd;
                    7: next_core_1_r7 = rd;
                endcase
                next_op_done1 = 1;
                next_pc1 = pc1 + 1;
                next_ic1 = ic1 + 1;
            end
            if(alu_core == 2)
            begin
                case (alu_inst[6:4])//rd
                    0: next_core_2_r0 = rd;
                    1: next_core_2_r1 = rd;
                    2: next_core_2_r2 = rd;
                    3: next_core_2_r3 = rd;
                    4: next_core_2_r4 = rd;
                    5: next_core_2_r5 = rd;
                    6: next_core_2_r6 = rd;
                    7: next_core_2_r7 = rd;
                endcase
                next_op_done2 = 1;
                next_pc2 = pc2 + 1;
                next_ic2 = ic2 + 1;
            end
        end
        else if(alu_inst[15:13] == 1)// mult
        begin
            next_mct1 = mct1 + 1;
            //0
            next_mrs = rs;
            next_mrt = rt;
            //1
            {next_mrd, next_mrl} = mrs * mrt;
            //2
            if(alu_core == 1)
            begin
                case (alu_inst[6:4])//rd
                    0: next_core_1_r0 = mrd;
                    1: next_core_1_r1 = mrd;
                    2: next_core_1_r2 = mrd;
                    3: next_core_1_r3 = mrd;
                    4: next_core_1_r4 = mrd;
                    5: next_core_1_r5 = mrd;
                    6: next_core_1_r6 = mrd;
                    7: next_core_1_r7 = mrd;
                endcase
                case (alu_inst[3:1])//rl
                    0: next_core_1_r0 = mrl;
                    1: next_core_1_r1 = mrl;
                    2: next_core_1_r2 = mrl;
                    3: next_core_1_r3 = mrl;
                    4: next_core_1_r4 = mrl;
                    5: next_core_1_r5 = mrl;
                    6: next_core_1_r6 = mrl;
                    7: next_core_1_r7 = mrl;
                endcase
            end
            if(alu_core == 2)
            begin
                case (alu_inst[6:4])//rd
                    0: next_core_2_r0 = mrd;
                    1: next_core_2_r1 = mrd;
                    2: next_core_2_r2 = mrd;
                    3: next_core_2_r3 = mrd;
                    4: next_core_2_r4 = mrd;
                    5: next_core_2_r5 = mrd;
                    6: next_core_2_r6 = mrd;
                    7: next_core_2_r7 = mrd;
                endcase
                case (alu_inst[3:1])//rl
                    0: next_core_2_r0 = mrl;
                    1: next_core_2_r1 = mrl;
                    2: next_core_2_r2 = mrl;
                    3: next_core_2_r3 = mrl;
                    4: next_core_2_r4 = mrl;
                    5: next_core_2_r5 = mrl;
                    6: next_core_2_r6 = mrl;
                    7: next_core_2_r7 = mrl;
                endcase
            end

            if(mct1 == 2)
            begin
                if(alu_core == 1)
                begin
                    next_op_done1 = 1;
                    next_pc1 = pc1 + 1;
                    next_ic1 = ic1 + 1;
                end
                if(alu_core == 2)
                begin
                    next_op_done2 = 1;
                    next_pc2 = pc2 + 1;
                    next_ic2 = ic2 + 1;
                end
                next_mct1 = 0;
            end
        end
        else if(alu_inst[15:13] == 3'b010 || alu_inst[15:13] == 3'b011)// addi, subi
        begin
            rt = (alu_inst[15:13] == 3'b010) ? (rs + imm) : (rs - imm);
            if(alu_core == 1)
            begin
                case (alu_inst[9:7])//rt
                    0: next_core_1_r0 = rt;
                    1: next_core_1_r1 = rt;
                    2: next_core_1_r2 = rt;
                    3: next_core_1_r3 = rt;
                    4: next_core_1_r4 = rt;
                    5: next_core_1_r5 = rt;
                    6: next_core_1_r6 = rt;
                    7: next_core_1_r7 = rt;
                endcase
                next_op_done1 = 1;
                next_pc1 = pc1 + 1;
                next_ic1 = ic1 + 1;
            end
            if(alu_core == 2)
            begin
                case (alu_inst[9:7])//rt
                    0: next_core_2_r0 = rt;
                    1: next_core_2_r1 = rt;
                    2: next_core_2_r2 = rt;
                    3: next_core_2_r3 = rt;
                    4: next_core_2_r4 = rt;
                    5: next_core_2_r5 = rt;
                    6: next_core_2_r6 = rt;
                    7: next_core_2_r7 = rt;
                endcase
                next_op_done2 = 1;
                next_pc2 = pc2 + 1;
                next_ic2 = ic2 + 1;
            end
            
        end
        else if(alu_inst[15:13] == 3'b100)// load
        begin
            if(data_axi_done && data_axi_id == 4'b0001 && alu_core == 1)
            begin
                rt = data_axi_rdata;
                case (alu_inst[9:7])//rt
                    0: next_core_1_r0 = rt;
                    1: next_core_1_r1 = rt;
                    2: next_core_1_r2 = rt;
                    3: next_core_1_r3 = rt;
                    4: next_core_1_r4 = rt;
                    5: next_core_1_r5 = rt;
                    6: next_core_1_r6 = rt;
                    7: next_core_1_r7 = rt;
                endcase
                next_op_done1 = 1;
                next_ic1 = ic1 + 1;
                next_pc1 = pc1 + 1;
            end
            if(data_axi_done && data_axi_id == 4'b0010 && alu_core == 2)
            begin
                rt = data_axi_rdata;
                case (alu_inst[9:7])//rt
                    0: next_core_2_r0 = rt;
                    1: next_core_2_r1 = rt;
                    2: next_core_2_r2 = rt;
                    3: next_core_2_r3 = rt;
                    4: next_core_2_r4 = rt;
                    5: next_core_2_r5 = rt;
                    6: next_core_2_r6 = rt;
                    7: next_core_2_r7 = rt;
                endcase
                next_op_done2 = 1;
                next_ic2 = ic2 + 1;
                next_pc2 = pc2 + 1;
            end
        end
        else if(alu_inst[15:13] == 3'b101)// store
        begin
            if(data_axi_done && data_axi_id == 4'b0001 && alu_core == 1)
            begin
                next_op_done1 = 1;
                next_pc1 = pc1 + 1;
                next_ic1 = ic1 + 1;
            end
            if(data_axi_done && data_axi_id == 4'b0010 && alu_core == 2)
            begin
                next_op_done2 = 1;
                next_pc2 = pc2 + 1;
                next_ic2 = ic2 + 1;
            end
        end
        else if(alu_inst[15:13] == 3'b110)// beq
        begin
            if(alu_core == 1)
            begin
                if(rs == rt)
                begin
                    next_pc1 = pc1 + 1 + {{7{imm[6]}}, imm};
                end
                else
                begin
                    next_pc1 = pc1 + 1;
                end
                next_ic1 = ic1 + 1;
                next_op_done1 = 1;
            end
            if(alu_core == 2)
            begin
                if(rs == rt)
                begin
                    next_pc2 = pc2 + 1 + {{7{imm[6]}}, imm};
                end
                else
                begin
                    next_pc2 = pc2 + 1;
                end
                next_ic2 = ic2 + 1;
                next_op_done2 = 1;
            end
            
        end
        else if(alu_inst[15:13] == 3'b111)// jump
        begin
            if(alu_core == 1)
            begin
                next_pc1 = alu_inst[12:0] >> 1;
                next_ic1 = ic1 + 1;
                next_op_done1 = 1;
            end
            if(alu_core == 2)
            begin
                next_pc2 = alu_inst[12:0] >> 1;
                next_ic2 = ic2 + 1;
                next_op_done2 = 1;
            end
        end
    end

    if(ic1 == 50)
        next_ic1 = 0;
    if(ic2 == 50)
        next_ic2 = 0;

    if(op_done1 && op_done2)
    begin
        next_op_done1 = 0;
        next_op_done2 = 0;
    end

end
//state
always @(*)
begin
    next_state1 = state1; 
    next_state2 = state2;

    case(state1)
        IDLE: begin
            if(fb1 == 0)
                next_state1 = FB;
            else if(axi_done1)
                next_state1 = OPER;
            else
                next_state1 = IDLE;
        end
        FB: begin
            if(axi_done1)
                next_state1 = OPER;
            else
                next_state1 = FB;
        end
        OPER: begin
            if(next_op_done1)
                next_state1 = IDLE;
            else
                next_state1 = OPER;
        end
    endcase

    case(state2)
        IDLE: begin
            if(fb2 == 0)
                next_state2 = FB;
            else if(axi_done2)
                next_state2 = OPER;
            else
                next_state2 = IDLE;
        end
        FB: begin
            if(axi_done2)
                next_state2 = OPER;
            else
                next_state2 = FB;
        end
        OPER: begin
            if(next_op_done2)
                next_state2 = IDLE;
            else
                next_state2 = OPER;
        end
    endcase

end
// stall
always @(*)
begin
    next_stall_1 = 1; next_stall_2 = 1;

    if(op_done1 && op_done2)
    begin
        next_stall_1 = 0;
        next_stall_2 = 0;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        core_1_r0 <= 0; core_1_r1 <= 0; 
        core_1_r2 <= 0; core_1_r3 <= 0;
        core_1_r4 <= 0; core_1_r5 <= 0; 
        core_1_r6 <= 0; core_1_r7 <= 0;
        core_2_r0 <= 0; core_2_r1 <= 0; 
        core_2_r2 <= 0; core_2_r3 <= 0;
        core_2_r4 <= 0; core_2_r5 <= 0; 
        core_2_r6 <= 0; core_2_r7 <= 0;
        stall_1 <= 1; stall_2 <= 1;
        fb1 <= 0; fb2 <= 0;
        state1 <= 0; state2 <= 0;
        inst1 <= 0; inst2 <= 0;
        pc1 <= 0; pc2 <= 0;
        ic1 <= 0; ic2 <= 0;
        mct1 <= 0; 
        op_done1 <= 0; op_done2 <= 0;
        load_valid1 <= 0; load_valid2 <= 0;
        store1_valid <= 0; store2_valid <= 0;
        alu_core <= 0;
        mrs <= 0; mrt <= 0; mrd <= 0; mrl <= 0;
    end
    else
    begin
        core_1_r0 <= next_core_1_r0; core_1_r1 <= next_core_1_r1;
        core_1_r2 <= next_core_1_r2; core_1_r3 <= next_core_1_r3;
        core_1_r4 <= next_core_1_r4; core_1_r5 <= next_core_1_r5;
        core_1_r6 <= next_core_1_r6; core_1_r7 <= next_core_1_r7;
        core_2_r0 <= next_core_2_r0; core_2_r1 <= next_core_2_r1;
        core_2_r2 <= next_core_2_r2; core_2_r3 <= next_core_2_r3;
        core_2_r4 <= next_core_2_r4; core_2_r5 <= next_core_2_r5;
        core_2_r6 <= next_core_2_r6; core_2_r7 <= next_core_2_r7;
        stall_1 <= next_stall_1; stall_2 <= next_stall_2;
        fb1 <= next_fb1; fb2 <= next_fb2;
        state1 <= next_state1; state2 <= next_state2;
        inst1 <= next_inst1; inst2 <= next_inst2;
        pc1 <= next_pc1; pc2 <= next_pc2;
        ic1 <= next_ic1; ic2 <= next_ic2;
        mct1 <= next_mct1;
        op_done1 <= next_op_done1; op_done2 <= next_op_done2;
        load_valid1 <= next_load_valid1; load_valid2 <= next_load_valid2;
        store1_valid <= next_store1_valid; store2_valid <= next_store2_valid;
        alu_core <= next_alu_core;
        mrs <= next_mrs; mrt <= next_mrt; mrd <= next_mrd; mrl <= next_mrl;
    end
end

endmodule

module AXI_INST #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 16,
    parameter BURST_LEN  = 7
)(
    input clk,
    input rst_n,
    input first_burst,
    input cpu_req_valid, // read request from CPU
    input [ADDR_WIDTH-1:0]  cpu_req_addr,  
    output reg                    axi_done, // AXI transaction done
    output reg  [DATA_WIDTH-1:0]  axi_rdata,     

    // ==========================================
    // AXI interface
    // ==========================================
    // AR Channel (Read Address)
    output reg  [ID_WIDTH-1:0]    arid,
    output reg  [ADDR_WIDTH-1:0]  araddr,
    output reg  [BURST_LEN-1:0]   arlen,
    output reg  [2:0]             arsize,
    output reg  [1:0]             arburst,
    output reg                    arvalid,
    input  wire                   arready,

    // R Channel (Read Data)
    input  wire [ID_WIDTH-1:0]    rid,
    input  wire [DATA_WIDTH-1:0]  rdata,
    input  wire [1:0]             rresp,
    input  wire                   rlast,
    input  wire                   rvalid,
    output reg                    rready
);

parameter IDLE = 0;
parameter SRAM = 1;
parameter AR = 2;
parameter R = 3;
parameter FB = 4;

//==================================================================
// SRAM
//==================================================================
wire SRAM_inst_128X22_CLK, SRAM_inst_128X22_CS, SRAM_inst_128X22_OE, SRAM_inst_128X22_WE;
wire [6:0]  SRAM_inst_128X22_A;
wire [21:0] SRAM_inst_128X22_DI;
wire [21:0] SRAM_inst_128X22_DO;

SRAM_inst_128_22  SRAM_128_22_inst  (
    .CLK    (SRAM_inst_128X22_CLK ),
    .CS     (SRAM_inst_128X22_CS  ),
    .OE     (SRAM_inst_128X22_OE  ),
    .WEB    (!SRAM_inst_128X22_WE ),
    .A      (SRAM_inst_128X22_A   ),
    .DI     (SRAM_inst_128X22_DI  ),
    .DO     (SRAM_inst_128X22_DO  )
);

reg next_arvalid, next_rready;
reg [ID_WIDTH-1:0] next_arid;
reg [ADDR_WIDTH-1:0] next_araddr;
reg [2:0] next_arsize;
reg [1:0] next_arburst;
reg [BURST_LEN-1:0] next_arlen;
reg [2:0] state, next_state;
reg [15:0] first_inst, next_first_inst;
reg [7:0] count, next_count;
reg [ADDR_WIDTH-1:0]  req_addr, next_req_addr, addr_temp;
reg cache_hit;

// sram reg
reg we_inst, next_we_inst;
reg [6:0]  addr_inst, next_addr_inst;
reg [21:0] di_inst, next_di_inst;
reg [21:0] do_inst, next_do_inst;

assign SRAM_inst_128X22_CLK   = clk;
assign SRAM_inst_128X22_CS    = 1'b1;
assign SRAM_inst_128X22_OE    = 1'b1;
assign SRAM_inst_128X22_WE    = we_inst;
assign SRAM_inst_128X22_A     = addr_inst;
assign SRAM_inst_128X22_DI    = di_inst;

//cache
always @(*)
begin
    next_req_addr = req_addr;
    cache_hit = 0;
    
    if(state == IDLE && cpu_req_valid)
    begin
        next_req_addr = cpu_req_addr;
    end

    if(state == SRAM && count == 2)
    begin
        if(do_inst[20:16] == req_addr[12:8])// tag match
            cache_hit = 1;
        else 
            cache_hit = 0;
    end

end
// sram
always @(*)
begin
    next_we_inst = 0;
    next_addr_inst = addr_inst;
    next_di_inst = 0;
    addr_temp = 0;
    // dout
    next_do_inst = SRAM_inst_128X22_DO;

    if(state == FB && rvalid && rready)// write burst data to sram(128 instructions)
    begin
        next_we_inst = 1;
        next_addr_inst = count;// 0,1,2...127
        next_di_inst = {1'b0, 5'd0, rdata};
        
    end
    if(state == IDLE && cpu_req_valid && !first_burst)// read cache
    begin
        next_we_inst = 0;
        next_addr_inst = cpu_req_addr[7:1];
    end
    if(state == R && rvalid && rready)// write burst data to sram(32 instructions)
    begin
        next_we_inst = 1;
        addr_temp = req_addr + (count << 1);// +2,+4,+6...+64
        next_addr_inst = addr_temp[7:1];// req_addr[7:1] + count
        next_di_inst = {1'b0, addr_temp[12:8], rdata};
    end

end
//state
always @(*)
begin
    next_state = state;

    case(state)
        IDLE: begin
            if(cpu_req_valid)
            begin
                if(first_burst)
                    next_state = FB;
                else
                    next_state = SRAM;
            end
            else
                next_state = IDLE;
        end
        SRAM: begin
            if(count == 2)
            begin
                if(cache_hit)
                    next_state = IDLE;
                else
                    next_state = AR;
            end
            else
                next_state = SRAM;
        end
        AR: begin
            if(arvalid && arready)
                next_state = R;
            else
                next_state = AR;
        end
        R:  begin
            if(rvalid && rready && rlast)
                next_state = IDLE;
            else
                next_state = R;
        end
        FB: begin
            if(rvalid && rready && rlast)
                next_state = IDLE;
            else
                next_state = FB;
        end
    endcase
end
// axi signal
always @(*)
begin
    next_arid = arid; next_araddr = araddr; next_arsize = arsize; next_arburst = arburst; next_arlen = arlen; next_arvalid = arvalid;
    next_rready = rready;
    

    if(state == IDLE && cpu_req_valid && first_burst)// go to first burst state
    begin
        next_arid = 1;
        next_arvalid = 1;
        next_araddr = 0;
        next_arsize = 3'b001; // 16-bit(2 bytes)
        next_arburst = 2'b01; // increment
        next_arlen = 127; // burst of 128 transfers
    end
    else if(state == FB && arvalid && arready)// go to read state
    begin
        next_rready = 1;

        next_arvalid = 0;
        next_arid = 0;
        next_araddr = 0;
        next_arsize = 0;
        next_arburst = 0;
        next_arlen = 0;
    end
    else if(state == FB && rvalid && rready && rlast)// go back to idle
    begin
        next_rready = 0;
    end
    // cache miss
    if(state == AR)
    begin
        next_arid = 1;
        next_arvalid = 1;
        next_araddr = req_addr;
        next_arsize = 3'b001; // 16-bit(2 bytes)
        next_arburst = 2'b01; // increment
        //next_arlen = 31; // burst 32
        if((4095 - (req_addr >> 1)) < 64)
            next_arlen = 4095 - (req_addr >> 1);// last burst, less than 32
        else
            next_arlen = 63;
    end
    if(state == AR && arvalid && arready)// go to read state
    begin
        next_rready = 1;

        next_arvalid = 0;
        next_arid = 0;
        next_araddr = 0;
        next_arsize = 0;
        next_arburst = 0;
        next_arlen = 0;
    end
    else if(state == R && rvalid && rready && rlast)// go back to idle
    begin
        next_rready = 0;
    end
    
end
//count
always @(*)
begin
    next_count = count;

    if(state == FB && rvalid && rready)
    begin
        next_count = count + 1;
    end
    else if(state == SRAM)
    begin
        next_count = count + 1;
    end
    else if(state == R && rvalid && rready)
    begin
        next_count = count + 1;
    end

    if(state != next_state)
        next_count = 0;
end
// first_inst
always @(*)
begin
    next_first_inst = first_inst;

    if(state == FB && rvalid && rready && count == 0)
    begin
        next_first_inst = rdata;
    end
    else if(state == R && rvalid && rready && count == 0)
    begin
        next_first_inst = rdata;
    end
     
end
//axi out
always @(*)
begin
    axi_done = 0;
    axi_rdata = 0;

    if(state == FB && rvalid && rready && rlast)
    begin
        axi_done = 1;
        axi_rdata = first_inst;
    end
    if(state == SRAM && count == 2 && cache_hit)
    begin
        axi_done = 1;
        axi_rdata = do_inst[15:0];
    end
    if(state == R && rvalid && rready && rlast)
    begin
        axi_done = 1;
        axi_rdata = first_inst;
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        arid <= 0; araddr <= 0; arsize <= 0; arburst <= 0; arlen <= 0; arvalid <= 0;
        rready <= 0;
        state <= 0;
        we_inst <= 0;
        addr_inst <= 0;
        di_inst <= 0;
        do_inst <= 0;
        first_inst <= 0;
        count <= 0;
        req_addr <= 0;
    end
    else
    begin
        arid <= next_arid; araddr <= next_araddr; arsize <= next_arsize; arburst <= next_arburst; arlen <= next_arlen; arvalid <= next_arvalid;
        rready <= next_rready;
        state <= next_state;
        we_inst <= next_we_inst;
        addr_inst <= next_addr_inst;
        di_inst <= next_di_inst;
        do_inst <= next_do_inst;
        first_inst <= next_first_inst;
        count <= next_count;
        req_addr <= next_req_addr;
    end
end

endmodule


module AXI_DATA #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 16,
    parameter BURST_LEN  = 7
)(
    input clk,
    input rst_n,
    input cpu_req_valid, // read/write request from CPU
    input cpu_req_write, // 0: read, 1: write
    input core_id, // 0: core 1, 1: core 2
    input [ADDR_WIDTH-1:0]  cpu_req_addr,  
    input [DATA_WIDTH-1:0]  cpu_req_wdata, 
    output reg                    axi_done, // AXI transaction done
    output reg  [ID_WIDTH-1:0]    axi_id, // 0: core 1, 1: core 2
    output reg  [DATA_WIDTH-1:0]  axi_rdata,     

    // ==========================================
    // AXI interface
    // ==========================================
    // AW Channel (Write Address)
    output reg  [ID_WIDTH-1:0]    awid,
    output reg  [ADDR_WIDTH-1:0]  awaddr,
    output reg  [2:0]             awsize,
    output reg  [1:0]             awburst,
    output reg  [BURST_LEN-1:0]   awlen,
    output reg                    awvalid,
    input  wire                   awready,

    // W Channel (Write Data)
    output reg  [DATA_WIDTH-1:0]  wdata,
    output reg                    wlast,
    output reg                    wvalid,
    input  wire                   wready,

    // B Channel (Write Response)
    input  wire [ID_WIDTH-1:0]    bid,
    input  wire [1:0]             bresp,
    input  wire                   bvalid,
    output reg                    bready,

    // AR Channel (Read Address)
    output reg  [ID_WIDTH-1:0]    arid,
    output reg  [ADDR_WIDTH-1:0]  araddr,
    output reg  [BURST_LEN-1:0]   arlen,
    output reg  [2:0]             arsize,
    output reg  [1:0]             arburst,
    output reg                    arvalid,
    input  wire                   arready,

    // R Channel (Read Data)
    input  wire [ID_WIDTH-1:0]    rid,
    input  wire [DATA_WIDTH-1:0]  rdata,
    input  wire [1:0]             rresp,
    input  wire                   rlast,
    input  wire                   rvalid,
    output reg                    rready
);

parameter IDLE = 0;
parameter AR = 1;
parameter R = 2;
parameter AW = 3;
parameter W = 4;
parameter B = 5;
parameter SRAM = 6;
parameter FB = 7;

//==================================================================
// SRAM
//==================================================================
wire SRAM_inst_128X22_CLK, SRAM_inst_128X22_CS, SRAM_inst_128X22_OE, SRAM_inst_128X22_WE;
wire [6:0]  SRAM_inst_128X22_A;
wire [21:0] SRAM_inst_128X22_DI;
wire [21:0] SRAM_inst_128X22_DO;

SRAM_inst_128_22  SRAM_128_22_inst  (
    .CLK    (SRAM_inst_128X22_CLK ),
    .CS     (SRAM_inst_128X22_CS  ),
    .OE     (SRAM_inst_128X22_OE  ),
    .WEB    (!SRAM_inst_128X22_WE ),
    .A      (SRAM_inst_128X22_A   ),
    .DI     (SRAM_inst_128X22_DI  ),
    .DO     (SRAM_inst_128X22_DO  )
);

reg next_awvalid, next_wvalid, next_arvalid;
reg next_wlast;
reg next_bready, next_rready;
reg [DATA_WIDTH-1:0] next_wdata, req_wdata, next_req_wdata;
reg [ID_WIDTH-1:0] next_awid, next_arid;
reg [ADDR_WIDTH-1:0] next_awaddr, next_araddr;
reg [2:0] next_awsize, next_arsize;
reg [1:0] next_awburst, next_arburst;
reg [BURST_LEN-1:0] next_awlen, next_arlen;
reg [2:0] state, next_state;
reg [15:0] first_inst, next_first_inst;
reg [7:0] count, next_count;
reg [ADDR_WIDTH-1:0]  req_addr, next_req_addr, addr_temp;
reg cache_hit;
reg one_rdata_valid, next_one_rdata_valid;
reg sram_core_id, next_sram_core_id;
reg [127:0] cache_valid, next_cache_valid;

// sram reg
reg we_inst, next_we_inst;
reg [6:0]  addr_inst, next_addr_inst;
reg [21:0] di_inst, next_di_inst;
reg [21:0] do_inst, next_do_inst;

assign SRAM_inst_128X22_CLK   = clk;
assign SRAM_inst_128X22_CS    = 1'b1;
assign SRAM_inst_128X22_OE    = 1'b1;
assign SRAM_inst_128X22_WE    = we_inst;
assign SRAM_inst_128X22_A     = addr_inst;
assign SRAM_inst_128X22_DI    = di_inst;

//cache
always @(*)
begin
    next_req_addr = req_addr;
    cache_hit = 0;
    next_sram_core_id = sram_core_id;
    
    if(state == IDLE && cpu_req_valid)
    begin
        next_req_addr = cpu_req_addr;
        next_sram_core_id = core_id;
    end

    if(state == SRAM && count == 2)
    begin
        if(do_inst[20:16] == req_addr[12:8] && cache_valid[req_addr[7:1]])// tag match
            cache_hit = 1;
        else 
            cache_hit = 0;
    end

end
// sram
always @(*)
begin
    next_we_inst = 0;
    next_addr_inst = addr_inst;
    next_di_inst = 0;
    addr_temp = 0;
    next_cache_valid = cache_valid;
    // dout
    next_do_inst = SRAM_inst_128X22_DO;

    if(state == IDLE && cpu_req_valid && !cpu_req_write)// read cache
    begin
        next_we_inst = 0;
        next_addr_inst = cpu_req_addr[7:1];
    end
    if(state == R && rvalid && rready)// write burst data to sram(32 instructions)
    begin
        next_we_inst = 1;
        addr_temp = req_addr + (count << 1);// +2,+4,+6...+64
        next_addr_inst = addr_temp[7:1];// req_addr[7:1] + count
        next_di_inst = {1'b0, addr_temp[12:8], rdata};
        next_cache_valid[addr_temp[7:1]] = 1;
    end
    if(state == W && wvalid && wready)
    begin
        next_we_inst = 1;
        next_addr_inst = req_addr[7:1];
        next_di_inst = {1'b0, req_addr[12:8], req_wdata};
        next_cache_valid[req_addr[7:1]] = 1;
    end

end
//state
always @(*)
begin
    next_state = state;

    case(state)
        IDLE: begin
            if(cpu_req_valid)
            begin
                if(cpu_req_write)
                    next_state = AW;
                else
                    next_state = SRAM;
            end
            else
                next_state = IDLE;
        end
        SRAM: begin
            if(count == 2)
            begin
                if(cache_hit)
                    next_state = IDLE;
                else
                    next_state = AR;
            end
            else
                next_state = SRAM;
        end
        AR: begin
            if(arvalid && arready)
                next_state = R;
            else
                next_state = AR;
        end
        R:  begin
            if(rvalid && rready && rlast)
                next_state = IDLE;
            else
                next_state = R;
        end
        AW: begin
            if(awvalid && awready)
                next_state = W;
            else
                next_state = AW;
        end
        W:  begin
            if(wvalid && wready)
                next_state = B;
            else            
                next_state = W;
        end
        B:  begin
            if(bvalid && bready)
                next_state = IDLE;
            else
                next_state = B;
        end
    endcase
end
// axi signal
always @(*)
begin
    next_awid = awid; next_awaddr = awaddr; next_awsize = awsize; next_awburst = awburst; next_awlen = awlen; next_awvalid = awvalid;
    next_wdata = wdata; next_wlast = wlast; next_wvalid = wvalid;
    next_arid = arid; next_araddr = araddr; next_arsize = arsize; next_arburst = arburst; next_arlen = arlen; next_arvalid = arvalid;
    next_bready = bready;
    next_rready = rready;
    next_req_wdata = req_wdata;
    next_one_rdata_valid = one_rdata_valid;

    if(state == AR)// cache miss, go to read state
    begin
        next_arid = (sram_core_id) ? 4'b0010 : 4'b0001;
        next_arvalid = 1;
        next_araddr = req_addr;
        next_arsize = 3'b001; // 16-bit(2 bytes)
        next_arburst = 2'b01; // increment
        next_arlen = 0; // single transfer
        if((6143 - (req_addr >> 1)) < 128)
            next_arlen = 6143 - (req_addr >> 1);// last burst, less than 32
        else
            next_arlen = 127;

        if((req_addr >> 1) == 6143)
            next_one_rdata_valid = 1;
        else
            next_one_rdata_valid = 0;

        if(axi_done)
            next_one_rdata_valid = 0;
    end
    if(state == AR && arvalid && arready)// go to read state
    begin
        next_rready = 1;

        next_arvalid = 0;
        next_arid = 0;
        next_araddr = 0;
        next_arsize = 0;
        next_arburst = 0;
        next_arlen = 0;
    end
    else if(state == R && rvalid && rready && rlast)// go back to idle
    begin
        next_rready = 0;
    end
    
    if(state == IDLE && cpu_req_valid && cpu_req_write)// go to write addr state
    begin
        next_awid = (core_id) ? 4'b0010 : 4'b0001;
        next_awvalid = 1;
        next_awaddr = cpu_req_addr;
        next_awsize = 3'b001; // 16-bit(2 bytes)
        next_awburst = 2'b01; // increment
        next_awlen = 0; // single transfer

        next_req_wdata = cpu_req_wdata;
    end
    else if(state == AW && awvalid && awready)// go to write data state
    begin
        next_wvalid = 1;
        next_wlast = 1;
        next_wdata = req_wdata;

        next_awvalid = 0;
        next_awid = 0;
        next_awaddr = 0;
        next_awsize = 0;
        next_awburst = 0;
        next_awlen = 0;
    end
    else if(state == W && wvalid && wready)// go to write response state
    begin
        next_bready = 1;

        next_wvalid = 0;
        next_wlast = 0;
        next_wdata = 0;
    end
    else if(state == B && bvalid && bready)// go back to idle
    begin
        next_bready = 0;
    end

end
//count
always @(*)
begin
    next_count = count;

    if(state == SRAM)
    begin
        next_count = count + 1;
    end
    else if(state == R && rvalid && rready)
    begin
        next_count = count + 1;
    end

    if(state != next_state)
        next_count = 0;
end
// first_inst
always @(*)
begin
    next_first_inst = first_inst;

    if(state == R && rvalid && rready && count == 0)
    begin
        next_first_inst = rdata;
    end
     
end
//axi out
always @(*)
begin
    axi_done = 0;
    axi_rdata = 0;
    axi_id = 0;

    if(state == SRAM && count == 2 && cache_hit)
    begin
        axi_done = 1;
        axi_rdata = do_inst[15:0];
        axi_id = (sram_core_id) ? 4'b0010 : 4'b0001;
    end
    if(state == R && rvalid && rready && rlast)
    begin
        axi_done = 1;
        axi_rdata = first_inst;
        axi_id = rid; // 0001: core 1, 0010: core 2
        if(one_rdata_valid)
            axi_rdata = next_first_inst;
    end
    else if(state == B && bvalid && bready)
    begin
        axi_done = 1;
        axi_id = bid; // 0001: core 1, 0010: core 2
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        awid <= 0; awaddr <= 0; awsize <= 0; awburst <= 0; awlen <= 0; awvalid <= 0;
        wdata <= 0; wlast <= 0; wvalid <= 0;
        arid <= 0; araddr <= 0; arsize <= 0; arburst <= 0; arlen <= 0; arvalid <= 0;
        bready <= 0;
        rready <= 0;
        state <= 0;
        req_wdata <= 0;
        first_inst <= 0;
        count <= 0;
        req_addr <= 0;
        we_inst <= 0;
        addr_inst <= 0;
        di_inst <= 0;
        do_inst <= 0;
        one_rdata_valid <= 0;
        sram_core_id <= 0;
        cache_valid <= 0;
    end
    else
    begin
        awid <= next_awid; awaddr <= next_awaddr; awsize <= next_awsize; awburst <= next_awburst; awlen <= next_awlen; awvalid <= next_awvalid;
        wdata <= next_wdata; wlast <= next_wlast; wvalid <= next_wvalid;
        arid <= next_arid; araddr <= next_araddr; arsize <= next_arsize; arburst <= next_arburst; arlen <= next_arlen; arvalid <= next_arvalid;
        bready <= next_bready;
        rready <= next_rready;
        state <= next_state;
        req_wdata <= next_req_wdata;
        first_inst <= next_first_inst;
        count <= next_count;
        req_addr <= next_req_addr;
        we_inst <= next_we_inst;
        addr_inst <= next_addr_inst;
        di_inst <= next_di_inst;
        do_inst <= next_do_inst;
        one_rdata_valid <= next_one_rdata_valid;
        sram_core_id <= next_sram_core_id;
        cache_valid <= next_cache_valid;
    end
end


endmodule

module SRAM_inst_128_22 (
    input CLK, CS, OE, WEB,
    input [6:0]  A,
    input [21:0] DI,
    output[21:0] DO
);
SRAM_128x22 SRAM_128x22_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]),
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

