module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [WIDTH-1:0] data, next_data;
reg next_sreq;
reg next_dack;
reg [WIDTH-1:0] next_dout;
reg next_dvalid, dvalid_temp, next_dvalid_temp;

//==============================================//
// sclk domain 
// sreq
always @(*)
begin
    next_sreq = sreq;
    if(sack) // destination has acknowledged the request
        next_sreq = 0;
    else if(sready) // source has a new request
        next_sreq = 1;
end

always @(posedge sclk or negedge rst_n) 
begin
    if(!rst_n) 
        sreq <= 0;
    else
        sreq <= next_sreq;
end

//dreq
NDFF_syn NDFF_SYN_DREQ (
    .D(sreq),
    .Q(dreq),
    .clk(dclk),
    .rst_n(rst_n)
);

// data
always @(*)
begin
    next_data = data;
    if(sready && sidle)
        next_data = din;
end

always @(posedge sclk or negedge rst_n)
begin
    if(!rst_n)
        data <= 0;
    else
        data <= next_data;
end

//==============================================//
// dclk domain
// dack
always @(*)
begin
    next_dack = dack;

    if(dack == 0)
    begin
        if(dreq && ~dbusy) // destination can accept the request
            next_dack = 1;
    end
    else // dack == 1
    begin
        if(~dreq)
            next_dack = 0;
    end
    
end

always @(posedge dclk or negedge rst_n)
begin
    if(!rst_n)
        dack <= 0;
    else
        dack <= next_dack;
end

// sack
NDFF_syn NDFF_SYN_SACK (
    .D(dack),
    .Q(sack),
    .clk(sclk),
    .rst_n(rst_n)
);

always @(*)
begin
    flag_handshake_to_clk1 = sack;
    
end

// sidle
assign sidle = (~sreq) && (~sack);

// dvalid
always @(*)
begin
    next_dvalid_temp = dvalid_temp;
    next_dvalid = dvalid;

    if(dreq && ~dbusy) // destination can accept the request
        next_dvalid_temp = 1;
    else
        next_dvalid_temp = 0;

    if(dvalid_temp == 0 && next_dvalid_temp == 1) // rising edge of dvalid_temp
        next_dvalid = 1;
    else
        next_dvalid = 0;
end

always @(posedge dclk or negedge rst_n)
begin
    if(!rst_n)
    begin
        dvalid_temp <= 0;
        dvalid <= 0;
    end
    else
    begin
        dvalid_temp <= next_dvalid_temp;
        dvalid <= next_dvalid;
    end
        
end

// dout
always @(*)
begin
    next_dout = dout;

    if(next_dvalid) // when dvalid goes high, update dout with data
        next_dout = data;
    else
        next_dout = 0;
end

always @(posedge dclk or negedge rst_n)
begin
    if(!rst_n)
        dout <= 0;
    else
        dout <= next_dout;
end

endmodule