module DRAM_CTRL (
    input               clk,
    input               rst_n,
    
    // AXI4-Lite slave interface
    input [31:0]        aw_addr,
    input               aw_valid,
    output reg          aw_ready,
    input [63:0]        w_data,
    input               w_valid,
    output reg          w_ready,
    output reg [1:0]   b_resp,
    output reg         b_valid,
    input               b_ready,
    
    input [31:0]        ar_addr,
    input               ar_valid,
    output reg          ar_ready,
    output reg [63:0]   r_data,
    output reg [1:0]   r_resp,
    output reg         r_valid,
    input               r_ready,

    // DRAM master interface
    output reg  [3:0]   dram_cmd,  // {CS_n, RAS_n, CAS_n, WE_n}
    output reg  [1:0]   dram_ba,
    output reg  [10:0]  dram_addr,
    output reg  [63:0]  dram_wdata,
    input [63:0]        dram_rdata,
    input               dram_valid
);

parameter P3 = 0;
parameter A0 = 1;
parameter A1 = 2;
parameter A2 = 3;
parameter A3 = 4;
parameter A4 = 5;
parameter A5 = 6;
parameter P0 = 7;
parameter P1 = 8;
parameter P2 = 9;



reg [3:0] state_b0, next_state_b0, state_b1, next_state_b1, state_b2, next_state_b2, state_b3, next_state_b3;
reg next_aw_ready, next_w_ready, next_ar_ready, next_r_valid, next_b_valid;
reg [63:0] next_r_data, next_dram_wdata;
reg [1:0] next_b_resp, next_r_resp;
reg [3:0] next_dram_cmd;
reg [1:0] next_dram_ba;
reg [10:0] next_dram_addr;
reg [16:0] queue_addr [0:7];
reg [16:0] next_queue_addr [0:7];
reg [63:0] queue_wdata [0:7];
reg [63:0] next_queue_wdata [0:7];
reg [3:0] queue_ct, next_queue_ct, queue_wdata_ct, next_queue_wdata_ct;
reg [63:0] queue_rdata [0:4];
reg [63:0] next_queue_rdata [0:4];
reg dram_valid_buf, next_dram_valid_buf;
reg [2:0] queue_rdata_ct, next_queue_rdata_ct;
reg [5:0] b0_row, next_b0_row, b1_row, next_b1_row, b2_row, next_b2_row, b3_row, next_b3_row;
reg rdata_not_empty, next_rdata_not_empty;

integer i;

//state 
always @(*)
begin
    next_state_b0 = state_b0;
    next_state_b1 = state_b1;
    next_state_b2 = state_b2;
    next_state_b3 = state_b3;

    case(state_b0)
        P3:
        begin
            next_state_b0 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b00) ? A0 : P3;
        end
        A0: next_state_b0 = A1;
        A1: next_state_b0 = A2;
        A2: next_state_b0 = A3;
        A3: next_state_b0 = A4;
        A4: next_state_b0 = A5;
        A5: 
        begin
            next_state_b0 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b00) ? P0 : A5;
        end
        P0: next_state_b0 = P1;
        P1: next_state_b0 = P2;
        P2: next_state_b0 = P3;
        default: next_state_b0 = P3;
    endcase

    case(state_b1)
        P3:
        begin
            next_state_b1 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b01) ? A0 : P3;
        end
        A0: next_state_b1 = A1;
        A1: next_state_b1 = A2;
        A2: next_state_b1 = A3;
        A3: next_state_b1 = A4;
        A4: next_state_b1 = A5;
        A5: 
        begin
            next_state_b1 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b01) ? P0 : A5;
        end
        P0: next_state_b1 = P1;
        P1: next_state_b1 = P2;
        P2: next_state_b1 = P3;
        default: next_state_b1 = P3;
    endcase

    case(state_b2)
        P3:
        begin
            next_state_b2 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b10) ? A0 : P3;
        end
        A0: next_state_b2 = A1;
        A1: next_state_b2 = A2;
        A2: next_state_b2 = A3;
        A3: next_state_b2 = A4;
        A4: next_state_b2 = A5;
        A5: 
        begin
            next_state_b2 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b10) ? P0 : A5;
        end
        P0: next_state_b2 = P1;
        P1: next_state_b2 = P2;
        P2: next_state_b2 = P3;
        default: next_state_b2 = P3;
    endcase

    case(state_b3)
        P3:
        begin
            next_state_b3 = (next_dram_cmd == 4'b0011 && queue_addr[0][15:14] == 2'b11) ? A0 : P3;
        end
        A0: next_state_b3 = A1;
        A1: next_state_b3 = A2;
        A2: next_state_b3 = A3;
        A3: next_state_b3 = A4;
        A4: next_state_b3 = A5;
        A5: 
        begin
            next_state_b3 = (next_dram_cmd == 4'b0010 && queue_addr[0][15:14] == 2'b11) ? P0 : A5;
        end
        P0: next_state_b3 = P1;
        P1: next_state_b3 = P2;
        P2: next_state_b3 = P3;
        default: next_state_b3 = P3;
    endcase

end
// axi
always @(*)
begin
    next_aw_ready = aw_ready;
    next_w_ready = w_ready;
    next_ar_ready = ar_ready;
    r_valid = rdata_not_empty;
    next_b_valid = 0;
    r_data = queue_rdata[0];
    next_b_resp = 0;
    next_r_resp = 0;
    next_rdata_not_empty = rdata_not_empty;

    if(queue_ct < 7)
    begin
        next_ar_ready = ar_valid ? 1 : 0;
        next_aw_ready = ~ (next_ar_ready);
        next_w_ready = ~ (next_ar_ready);
    end
    else //queue is full, stop accepting new request
    begin
        next_ar_ready = 0;
        next_aw_ready = 0;
        next_w_ready = 0;
    end

    if(dram_cmd == 4'b0100)
    begin
        next_b_valid = 1;
        next_b_resp = 2'b00; //OKAY
    end
    //next_b_valid = 1;

    if(next_queue_rdata_ct != 0)
        next_rdata_not_empty = 1;
    else
        next_rdata_not_empty = 0;
    
    
    if(queue_rdata_ct != 0)
    begin
        next_r_resp = 2'b00; //OKAY
    end
    
    
end
//dram valid buffer
always @(*)
begin
    next_dram_valid_buf = dram_valid_buf;

    next_dram_valid_buf = dram_valid;
end
//queue
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        next_queue_addr[i] = queue_addr[i];
        next_queue_wdata[i] = queue_wdata[i];
        next_queue_rdata[i] = queue_rdata[i];
    end
    next_queue_ct = queue_ct;
    next_queue_wdata_ct = queue_wdata_ct;
    next_queue_rdata_ct = queue_rdata_ct;

    if(ar_valid && ar_ready && queue_ct < 8)//read add to queue
    begin
        next_queue_addr[queue_ct] = {1'b0, ar_addr[15:0]};
        next_queue_ct = queue_ct + 1;
    end
    else if(aw_valid && aw_ready && queue_ct < 8)//write add to queue
    begin
        next_queue_addr[queue_ct] = {1'b1, aw_addr[15:0]};
        next_queue_ct = queue_ct + 1;
    end

    if(aw_valid && aw_ready && queue_wdata_ct < 8) //write data ready, update wdata in queue
    begin
        next_queue_wdata[queue_wdata_ct] = w_data;
        next_queue_wdata_ct = queue_wdata_ct + 1;
    end
    if(next_dram_cmd == 4'b0100 && queue_wdata_ct != 0) //write command issue, remove wdata in queue
    begin
        next_queue_wdata[0:6] = queue_wdata[1:7];
        next_queue_wdata[7] = 0;
        next_queue_wdata_ct = queue_wdata_ct - 1;
    end
    

    if(next_dram_cmd == 4'b0101 || next_dram_cmd == 4'b0100) //read or write, remove from queue
    begin
        next_queue_addr[0:6] = queue_addr[1:7];
        next_queue_addr[7] = 0;
        next_queue_ct = queue_ct - 1;
    end

    if((ar_valid && ar_ready) && (next_dram_cmd == 4'b0101 || next_dram_cmd == 4'b0100)) //pop and push at the same time
    begin
        next_queue_addr[0:6] = queue_addr[1:7];
        next_queue_addr[7] = 0;
        next_queue_addr[queue_ct - 1] = {1'b0, ar_addr[15:0]};
        next_queue_ct = queue_ct;
    end
    else if((aw_valid && aw_ready) && (next_dram_cmd == 4'b0100 || next_dram_cmd == 4'b0101)) //pop and push at the same time
    begin
        next_queue_addr[0:6] = queue_addr[1:7];
        next_queue_addr[7] = 0;
        next_queue_addr[queue_ct - 1] = {1'b1, aw_addr[15:0]};
        next_queue_ct = queue_ct;
    end

    if(aw_valid && aw_ready && next_dram_cmd == 4'b0100) //write command issue, but new write addr come, update wdata in queue
    begin
        next_queue_wdata[0:6] = queue_wdata[1:7];
        next_queue_wdata[7] = 0;
        next_queue_wdata[queue_wdata_ct - 1] = w_data;
        next_queue_wdata_ct = queue_wdata_ct;
    end


    if(dram_valid)
    begin
        next_queue_rdata[queue_rdata_ct] = dram_rdata;
        next_queue_rdata_ct = queue_rdata_ct + 1;
    end

    if(r_ready && r_valid)
    begin
        next_queue_rdata[0:3] = queue_rdata[1:4];
        next_queue_rdata[4] = 0;
        next_queue_rdata_ct = queue_rdata_ct - 1;
    end

    if(dram_valid && r_ready && r_valid) //push and pop at the same time
    begin
        next_queue_rdata[0:3] = queue_rdata[1:4];
        next_queue_rdata[4] = 0;
        next_queue_rdata[queue_rdata_ct - 1] = dram_rdata;
        next_queue_rdata_ct = queue_rdata_ct;
    end
    
end
//dram 
always @(*)
begin
    next_dram_cmd = 4'b0111; //default NOP
    next_dram_ba = dram_ba;
    next_dram_addr = dram_addr;
    next_dram_wdata = dram_wdata;

    if((state_b0 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b00) ||
       (state_b1 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b01) ||
       (state_b2 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b10) ||
       (state_b3 == P3 && queue_ct != 0 && queue_addr[0][15:14] == 2'b11)
    ) //issue ACT
    begin
        next_dram_cmd = 4'b0011;
        next_dram_ba = queue_addr[0][15:14];
        next_dram_addr = {5'b00000, queue_addr[0][13:8]};
        next_dram_wdata = 0;
    end

    if(((state_b0 == A2 || state_b0 == A3 || state_b0 == A4 || state_b0 == A5) && queue_addr[0][15:14] == 2'b00) ||
        ((state_b1 == A2 || state_b1 == A3 || state_b1 == A4 || state_b1 == A5) && queue_addr[0][15:14] == 2'b01) ||
        ((state_b2 == A2 || state_b2 == A3 || state_b2 == A4 || state_b2 == A5) && queue_addr[0][15:14] == 2'b10) ||
        ((state_b3 == A2 || state_b3 == A3 || state_b3 == A4 || state_b3 == A5) && queue_addr[0][15:14] == 2'b11) 
    ) //issue READ or WRITE
    begin
        if(queue_ct != 0)
        begin
            if(queue_addr[0][16] == 1'b0) //read
            begin
                next_dram_cmd = 4'b0101;
                next_dram_ba = queue_addr[0][15:14];
                next_dram_addr = {3'b000, queue_addr[0][7:0]};
                next_dram_wdata = 0;
            end
            else //write
            begin
                next_dram_cmd = 4'b0100;
                next_dram_ba = queue_addr[0][15:14];
                next_dram_addr = {3'b000, queue_addr[0][7:0]};
                next_dram_wdata = queue_wdata[0];
            end
        end
    end

    if(((state_b0 == A3 || state_b0 == A4) && queue_addr[0][15:14] == 2'b00 && queue_addr[0][13:8] != b0_row) ||
       ((state_b1 == A3 || state_b1 == A4) && queue_addr[0][15:14] == 2'b01 && queue_addr[0][13:8] != b1_row) ||
       ((state_b2 == A3 || state_b2 == A4) && queue_addr[0][15:14] == 2'b10 && queue_addr[0][13:8] != b2_row) ||
       ((state_b3 == A3 || state_b3 == A4) && queue_addr[0][15:14] == 2'b11 && queue_addr[0][13:8] != b3_row)
    ) //issue precharge
    begin
        next_dram_cmd = 4'b0111; //NOP for one cycle
        next_dram_ba = 0;
        next_dram_addr = 0;
        next_dram_wdata = 0;
    end

    if(((state_b0 == A5) && queue_addr[0][15:14] == 2'b00 && queue_addr[0][13:8] != b0_row) ||
       ((state_b1 == A5) && queue_addr[0][15:14] == 2'b01 && queue_addr[0][13:8] != b1_row) ||
       ((state_b2 == A5) && queue_addr[0][15:14] == 2'b10 && queue_addr[0][13:8] != b2_row) ||
       ((state_b3 == A5) && queue_addr[0][15:14] == 2'b11 && queue_addr[0][13:8] != b3_row)
    ) //issue precharge
    begin
        next_dram_cmd = 4'b0010;
        next_dram_ba = queue_addr[0][15:14];
        next_dram_addr = 0;
        next_dram_wdata = 0;
    end

end

always @(*)
begin
    next_b0_row = b0_row;
    next_b1_row = b1_row;
    next_b2_row = b2_row;
    next_b3_row = b3_row;

    if(state_b0 == A0)
        next_b0_row = queue_addr[0][13:8];
    if(state_b1 == A0)
        next_b1_row = queue_addr[0][13:8];
    if(state_b2 == A0)
        next_b2_row = queue_addr[0][13:8];
    if(state_b3 == A0)
        next_b3_row = queue_addr[0][13:8];
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        for(i = 0; i < 8; i = i + 1)
        begin
            queue_addr[i] <= 0;
            queue_wdata[i] <= 0;
        end
        for (i = 0; i < 5; i = i + 1)
        begin
            queue_rdata[i] <= 0;
        end
        aw_ready <= 0;
        w_ready <= 0;
        ar_ready <= 0;
        b_valid <= 0;
        b_resp <= 0;
        r_resp <= 0;
        dram_cmd <= 0;
        dram_ba <= 0;
        dram_addr <= 0;
        dram_wdata <= 0;
        state_b0 <= 0;
        state_b1 <= 0;
        state_b2 <= 0;
        state_b3 <= 0;
        queue_ct <= 0;
        queue_wdata_ct <= 0;
        dram_valid_buf <= 0;
        queue_rdata_ct <= 0;
        b0_row <= 0;
        b1_row <= 0;
        b2_row <= 0;
        b3_row <= 0;
        rdata_not_empty <= 0;
    end 
    else 
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            queue_addr[i] <= next_queue_addr[i];
            queue_wdata[i] <= next_queue_wdata[i];
        end
        for (i = 0; i < 5; i = i + 1)
        begin
            queue_rdata[i] <= next_queue_rdata[i];
        end
        aw_ready <= next_aw_ready;
        w_ready <= next_w_ready;
        ar_ready <= next_ar_ready;
        b_valid <= next_b_valid;
        b_resp <= next_b_resp;
        r_resp <= next_r_resp;
        dram_cmd <= next_dram_cmd;
        dram_ba <= next_dram_ba;
        dram_addr <= next_dram_addr;
        dram_wdata <= next_dram_wdata;
        state_b0 <= next_state_b0;
        state_b1 <= next_state_b1;
        state_b2 <= next_state_b2;
        state_b3 <= next_state_b3;
        queue_ct <= next_queue_ct;
        queue_wdata_ct <= next_queue_wdata_ct;
        dram_valid_buf <= next_dram_valid_buf;
        queue_rdata_ct <= next_queue_rdata_ct;
        b0_row <= next_b0_row;
        b1_row <= next_b1_row;
        b2_row <= next_b2_row;
        b3_row <= next_b3_row;
        rdata_not_empty <= next_rdata_not_empty;
    end
end

    
endmodule