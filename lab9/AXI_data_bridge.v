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
                    next_state = AR;
            end
            else
                next_state = IDLE;
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

    if(state == IDLE && cpu_req_valid && !cpu_req_write)// go to read addr state
    begin
        next_arid = (core_id) ? 4'b0010 : 4'b0001;
        next_arvalid = 1;
        next_araddr = cpu_req_addr;
        next_arsize = 3'b001; // 16-bit(2 bytes)
        next_arburst = 2'b01; // increment
        next_arlen = 0; // single transfer
    end
    else if(state == AR && arvalid && arready)// go to read state
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
//axi out
always @(*)
begin
    axi_done = 0;
    axi_rdata = 0;
    axi_id = 0;

    if(state == R && rvalid && rready)
    begin
        axi_done = 1;
        axi_rdata = rdata;
        axi_id = rid; // 0001: core 1, 0010: core 2
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
    end
end