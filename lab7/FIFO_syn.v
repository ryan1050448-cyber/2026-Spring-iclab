module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,//clk2
    rclk,//clk1
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clkw,
    flag_clkw_to_fifo,

    flag_fifo_to_clkr,
	flag_clkr_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clkw;
input flag_clkw_to_fifo;

output flag_fifo_to_clkr;
input flag_clkr_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg [$clog2(WORDS):0] next_wptr, wptr_r;
reg [$clog2(WORDS):0] next_rptr, rptr_w;
reg [6:0] waddr, next_waddr, raddr, next_raddr;
reg next_wfull, next_rempty;
reg wean;
reg ren, next_ren, rvalid, next_rvalid;
//reg [6:0] waddr_p1, waddr_p2, wptr_p1, wptr_p2;
reg [6:0] raddr_w_bin, w_level;
reg wafull, next_wafull;
//reg real_full, next_real_full;

/*always @(*)
begin
    next_real_full = real_full;
    if({~next_wptr[$clog2(WORDS):$clog2(WORDS)-1], next_wptr[$clog2(WORDS)-2:0]} == rptr_w)
        next_real_full = 1;
    else
        next_real_full = 0;
end

always @(posedge wclk or negedge rst_n)
begin
    if(!rst_n)
        real_full <= 0;
    else
        real_full <= next_real_full;
end*/

//==============================================//
// wclk domain
// waddr
always @(*)
begin
    next_waddr = waddr;
    if(winc && ~wfull)
        next_waddr = waddr + 1;
end

always @(posedge wclk or negedge rst_n)
begin
    if(!rst_n)
        waddr <= 0;
    else
        waddr <= next_waddr;
end

// wptr
always @(*)
begin
    next_wptr = wptr;
    
    next_wptr = (next_waddr >> 1) ^ next_waddr; // gray code
end

always @(posedge wclk or negedge rst_n)
begin
    if(!rst_n)
        wptr <= 0;
    else
        wptr <= next_wptr;
end

// rptr in wclk domain
NDFF_BUS_syn #(.WIDTH(7)) NDFF_BUS_SYN_R2W(
    .D(rptr),
    .Q(rptr_w),
    .clk(wclk),
    .rst_n(rst_n)
);
// transfer gray code to binary code
always @(*)
begin
    /*waddr_p1 = waddr + 1;
    waddr_p2 = waddr + 2;

    wptr_p1 = (waddr_p1 >> 1) ^ waddr_p1;
    wptr_p2 = (waddr_p2 >> 1) ^ waddr_p2;

    if({~next_wptr[$clog2(WORDS):$clog2(WORDS)-1],next_wptr[$clog2(WORDS)-2:0]} == rptr_w) //64
        next_wafull = 1;
    else if({~wptr_p1[$clog2(WORDS):$clog2(WORDS)-1],wptr_p1[$clog2(WORDS)-2:0]} == rptr_w) //63
        next_wafull = 1;
    else if({~wptr_p2[$clog2(WORDS):$clog2(WORDS)-1],wptr_p2[$clog2(WORDS)-2:0]} == rptr_w) //62
        next_wafull = 1;
    else
        next_wafull = 0;*/

    raddr_w_bin[6] = rptr_w[6];
    raddr_w_bin[5] = rptr_w[5] ^ raddr_w_bin[6];
    raddr_w_bin[4] = rptr_w[4] ^ raddr_w_bin[5];
    raddr_w_bin[3] = rptr_w[3] ^ raddr_w_bin[4];
    raddr_w_bin[2] = rptr_w[2] ^ raddr_w_bin[3];
    raddr_w_bin[1] = rptr_w[1] ^ raddr_w_bin[2];
    raddr_w_bin[0] = rptr_w[0] ^ raddr_w_bin[1];

    w_level = next_waddr - raddr_w_bin;

    if(w_level >= WORDS - 2) //62, 63, 64
        next_wafull = 1;
    else
        next_wafull = 0;

end

always @(posedge wclk or negedge rst_n)
begin
    if(!rst_n)
        wafull <= 0;
    else
        wafull <= next_wafull;
end

// wfull
always @(*)
begin
    next_wfull = wfull;
    
    if({~next_wptr[$clog2(WORDS):$clog2(WORDS)-1],next_wptr[$clog2(WORDS)-2:0]} == rptr_w)
        next_wfull = 1;
    else
        next_wfull = 0;

    //next_wfull = next_wafull;
end

always @(posedge wclk or negedge rst_n)
begin
    if(!rst_n)
        wfull <= 0;
    else
        wfull <= next_wfull;
end

assign flag_fifo_to_clkw = wafull;

// wean
assign wean = ~(~wfull && winc);

//==============================================//
// rclk domain
// raddr
always @(*)
begin
    next_raddr = raddr;
    if(rinc && ~rempty)
        next_raddr = raddr + 1;
end

always @(posedge rclk or negedge rst_n)
begin
    if(!rst_n)
        raddr <= 0;
    else
        raddr <= next_raddr;
end

//rptr
always @(*)
begin
    next_rptr = rptr;
    
    next_rptr = (next_raddr >> 1) ^ next_raddr; // gray code
end

always @(posedge rclk or negedge rst_n)
begin
    if(!rst_n)
        rptr <= 0;
    else
        rptr <= next_rptr;
end

// wptr in rclk domain
NDFF_BUS_syn #(.WIDTH(7)) NDFF_BUS_SYN_W2R(
    .D(wptr),
    .Q(wptr_r),
    .clk(rclk),
    .rst_n(rst_n)
);

// rempty
always @(*)
begin
    next_rempty = rempty;
    
    if(next_rptr == wptr_r)
        next_rempty = 1;
    else
        next_rempty = 0;
end

always @(posedge rclk or negedge rst_n)
begin
    if(!rst_n)
        rempty <= 1;
    else
        rempty <= next_rempty;
end

// ren
always @(*)
begin
    next_ren = ren;
    //next_ren0 = ren0;
    
    if(rinc && ~rempty)
        next_ren = 1;
    else
        next_ren = 0;

end

always @(posedge rclk or negedge rst_n)
begin
    if(!rst_n)
    begin
        ren <= 0;
        //ren0 <= 0;
    end
    else
    begin
        ren <= next_ren;
        //ren0 <= next_ren0;
    end
        
end

// rvalid
always @(*)
begin
    next_rvalid = rvalid;
    
    next_rvalid = ren;
end

always @(posedge rclk or negedge rst_n)
begin
    if(!rst_n)
        rvalid <= 0;
    else
        rvalid <= next_rvalid;
end

assign flag_fifo_to_clkr = rvalid;

// rdata
//  Add one more register stage to rdata
always @(posedge rclk, negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else begin
		if (ren) begin
			rdata <= rdata_q;
		end
    end
end

DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(wean),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(~rempty),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr[0]),
    .A1(waddr[1]),
    .A2(waddr[2]),
    .A3(waddr[3]),
    .A4(waddr[4]),
    .A5(waddr[5]),
    .B0(raddr[0]),
    .B1(raddr[1]),
    .B2(raddr[2]),
    .B3(raddr[3]),
    .B4(raddr[4]),
    .B5(raddr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),

    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31]),

    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DIB8(1'b0),
    .DIB9(1'b0),
    .DIB10(1'b0),
    .DIB11(1'b0),
    .DIB12(1'b0),
    .DIB13(1'b0),
    .DIB14(1'b0),
    .DIB15(1'b0),
    .DIB16(1'b0),
    .DIB17(1'b0),
    .DIB18(1'b0),
    .DIB19(1'b0),
    .DIB20(1'b0),
    .DIB21(1'b0),
    .DIB22(1'b0),
    .DIB23(1'b0),
    .DIB24(1'b0),
    .DIB25(1'b0),
    .DIB26(1'b0),
    .DIB27(1'b0),
    .DIB28(1'b0),
    .DIB29(1'b0),
    .DIB30(1'b0),
    .DIB31(1'b0)
);

endmodule




