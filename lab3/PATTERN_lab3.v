`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

module PATTERN(
    output reg      clk,
    output reg      rst_n,
    // AXI4-Lite Master
    input [31:0]    aw_addr,
    input           aw_valid,
    input           aw_ready,
    input [63:0]    w_data,
    input           w_valid,
    input           w_ready,
    input [1:0]     b_resp,
    input           b_valid,
    input           b_ready,
    
    input [31:0]    ar_addr,
    input           ar_valid,
    input           ar_ready,
    input [63:0]    r_data,
    input [1:0]     r_resp,
    input           r_valid,
    input           r_ready,

    output reg       in_mode_valid,
    output reg [1:0] in_mode,
    output reg       in_valid,
    output reg [1:0] in_bank,
    output reg [5:0] in_src_row,
    output reg [5:0] in_dst_row,
    output reg [63:0]in_data,
    
    input             out_valid,
    input [63:0]      out_data
);


// Golden Memory for Verification
reg [63:0] golden_DRAM [0:65535];
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
initial $readmemh(DRAM_p_r, golden_DRAM);
//you can access psuedo_DRAM memory by u_DRAM.DRAM
//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency;
real CYCLE = `CYCLE_TIME;
parameter PATNUM = 100;
integer i_pat;
integer aw_tracking;
integer count1, count2, count3, count4, count5, count6, count7, count8;
integer ct_aw_w, ct_w_b, ct_ar_r;
integer i, j;
integer latency;
integer count_out_valid;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [31:0] aw_addr_temp, ar_addr_temp;
reg        aw_valid_temp, ar_valid_temp, w_valid_temp, r_valid_temp, b_valid_temp;
reg [63:0] w_data_temp, r_data_temp;
reg [1:0] b_resp_temp, r_resp_temp;
reg wait_w, wait_b, wait_r;
reg [1:0] mode_reg, bank_reg;
reg [63:0] datas [0:1023];
reg [63:0] addrs [0:1023];
reg [63:0] data_temp, addr_temp;
reg signed [30:0] si, sj;
reg [5:0] src_row_reg, dst_row_reg;
reg [63:0] in_data_reg [0:255];

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial begin
    reset_signal_task;//spec main-1
    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_task;
        check_answer_task;
        $display("\033[0;32mPASS PATTERN NO.%4d\033[m", i_pat);
    end

    YOU_PASS_task;
end


task reset_signal_task; begin
    rst_n = 1'b1;
    in_valid = 1'b0;
    in_mode_valid = 1'bx;
    in_mode = 2'bx;
    in_bank = 2'bx;
    in_src_row = 6'bx;
    in_dst_row = 6'bx;
    in_data = 64'bx;

    total_latency = 0;

    force clk = 1'b0;
    #(CYCLE/2.0) rst_n = 1'b0;
    #(CYCLE*2.0) rst_n = 1'b1;

    if(aw_valid !== 1'b0 || aw_ready !== 1'b0 || aw_addr !== 33'd0 || w_valid !== 1'b0 || w_ready !== 1'b0 || w_data !== 64'd0 || b_resp !== 2'b00 || b_valid !== 1'b0 || b_ready !== 1'b0 ||
       ar_valid !== 1'b0 || ar_ready !== 1'b0 || ar_addr !== 33'd0 || r_data !== 64'h0000000000000000 || r_resp !== 2'b00 || r_valid !== 1'b0 || r_ready !== 1'b0 ||
       out_valid !== 1'b0 || out_data !== 64'h0000000000000000) 
    begin
        $display("SPEC MAIN-1 FAIL");
        $display("*************************************************************************");
        $display("             ALL signals should be reset to 0 after reset                ");
        $display("*************************************************************************");
        $finish;
    end

    #CYCLE; release clk;
end endtask

task input_task; begin
    repeat($urandom_range(3,5)) @(negedge clk);
    in_mode_valid = 1'b1;
    in_mode = $urandom % 4;
    in_valid = 1'b0;
    in_bank = 2'bx;
    in_src_row = 6'bx;
    in_dst_row = 6'bx;
    in_data = 64'bx;
    mode_reg = in_mode;

    @(negedge clk);
    in_mode_valid = 1'b0;
    in_mode = 2'bx;
    if(mode_reg == 2'b00) //read
    begin
        in_valid = 1'b1;
        in_bank = $urandom % 4;
        in_src_row = $urandom % 63;
        bank_reg = in_bank;
        src_row_reg = in_src_row;

        @(negedge clk);
        in_valid = 1'b0;
        in_bank = 2'bx;
        in_src_row = 6'bx;
    end
    else if(mode_reg == 2'b01) //write
    begin
        in_valid = 1'b1;
        in_bank = $urandom % 4;
        in_dst_row = ($urandom % 31) + 32; //32-62
        in_data = {$urandom, $urandom}; //64 bits
        bank_reg = in_bank;
        dst_row_reg = in_dst_row;
        in_data_reg[0] = in_data;

        @(negedge clk);
        in_bank = 2'bx;
        in_dst_row = 6'bx;
        for (j = 1; j < 256; j = j + 1) begin
            in_valid = 1'b1;
            in_data = {$urandom, $urandom};
            in_data_reg[j] = in_data;
            @(negedge clk);
        end

        in_valid = 1'b0;
        in_data = 64'bx;
    end
    else if(mode_reg == 2'b10) //CALC
    begin
        in_valid = 1'b1;
        in_src_row = $urandom % 32;
        src_row_reg = in_src_row;

        @(negedge clk);
        in_valid = 1'b0;
        in_src_row = 6'bx;
    end
    else //sort
    begin
        in_valid = 1'b1;
        in_src_row = $urandom % 63;
        in_dst_row = ($urandom % 31) + 32; //32-62
        src_row_reg = in_src_row;
        dst_row_reg = in_dst_row;

        @(negedge clk);
        in_valid = 1'b0;
        in_src_row = 6'bx;
        in_dst_row = 6'bx;
    end
end endtask

task wait_out_task; begin
    latency = 0;
    while(out_valid !== 1'b1)
    begin
        latency = latency + 1;
        if(latency > 10000)
        begin
            $display("SPEC MAIN-2 FAIL");
            $display("*************************************************************************");
            $display("                     latency is over 10000 cycles                        ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

function automatic reg signed [63:0] calc_tree(input reg [15:0] ptr);
    reg [63:0] node;
    reg signed [63:0] left_val;
    reg signed [63:0] right_val;
    begin
        node = golden_DRAM[ptr]; 

        if (node[63] == 1'b0) //number
        begin
            calc_tree = {{33{node[62]}}, node[62:32]}; //sign-extend
            //calc_tree = $signed(node[62:32]);
        end 
        else //operator
        begin
            left_val  = calc_tree(node[31:16]);
            right_val = calc_tree(node[15:0]);

            case (node[33:32])
                2'b00: calc_tree = left_val + right_val;
                2'b01: calc_tree = left_val - right_val;
                2'b10: calc_tree = left_val * right_val;
                2'b11: calc_tree = left_val >>> right_val[5:0]; 
            endcase
        end

        //$display("calc_tree: ptr = %d, node = %h, left_val = %d, right_val = %d, return %d", ptr, node, left_val, right_val, calc_tree);
    end
endfunction

task golden_sort;
    integer index;
    begin
        index = 0;
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 256; j = j + 1)
            begin
                addrs[index] = {i[1:0], src_row_reg[5:0], j[7:0]};
                datas[index] = golden_DRAM[addrs[index]];
                index = index + 1;
            end
        end

        for (i = 0; i < 1023; i = i + 1)
        begin
            for (j = i + 1; j < 1024; j = j + 1)
            begin
                if ((datas[i][62:32] > datas[j][62:32]) || (datas[i][62:32] == datas[j][62:32] && addrs[i] > addrs[j]))
                begin
                    data_temp = datas[i];
                    datas[i] = datas[j];
                    datas[j] = data_temp;

                    addr_temp = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = addr_temp;
                end
            end
        end

        index = 0;
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 256; j = j + 1)
            begin
                golden_DRAM[{i[1:0], dst_row_reg[5:0], j[7:0]}] = datas[index];
                index = index + 1;  
            end
        end
    end
endtask

task check_answer_task; 
begin
    reg [15:0] root_ptr;
    reg signed [63:0] golden_ans;

    if(out_valid === 1'b1)
    begin
        count_out_valid = 0;
        
        if (mode_reg == 2'd0) //read 
        begin
            for (i = 0; i < 256; i = i + 1) 
            begin
                if (out_data === 'bx || out_valid === 1'b0) 
                begin
                    $display("SPEC MAIN-3 FAIL"); 
                    $finish;
                end
                
                if (out_data !== golden_DRAM[{bank_reg, src_row_reg, i[7:0]}]) 
                begin
                    $display("SPEC MAIN-4 FAIL"); 
                    $display("*************************************************************************");
                    $display("                     output data should be %h at index %d                ", golden_DRAM[{bank_reg, src_row_reg, i[7:0]}], i);
                    $display("*************************************************************************");
                    $finish;
                end
                count_out_valid = count_out_valid + 1;
                @(negedge clk);
            end
            if(out_valid !== 0 || count_out_valid !== 256)
            begin
                $display("SPEC MAIN-3 FAIL");
                $display("*************************************************************************");
                $display("                     output latency is not 256 cycles                    ");
                $display("*************************************************************************");
                $finish;
            end
        end 
        else if (mode_reg == 2'd1) //write
        begin
            if (out_data === 'bx || out_valid === 1'b0) 
            begin
                $display("SPEC MAIN-3 FAIL"); 
                $finish;
            end

            for (i = 0; i < 256; i = i + 1)
            begin
                golden_DRAM[{bank_reg, dst_row_reg, i[7:0]}] = in_data_reg[i];
            end
            
            count_out_valid = count_out_valid + 1;
            

            for (i = 0; i < 256; i = i + 1) 
            begin
                if (u_DRAM.DRAM[{bank_reg, dst_row_reg, i[7:0]}] !== golden_DRAM[{bank_reg, dst_row_reg, i[7:0]}]) 
                begin
                    $display("SPEC MAIN-5 FAIL"); 
                    $display("*************************************************************************");
                    $display("                     DRAM data is wrong at address %h                    ", {bank_reg, dst_row_reg, i[7:0]});
                    $display("*************************************************************************");
                    $finish;
                end
            end

            @(negedge clk);
            if(out_valid !== 0 || count_out_valid !== 1)
            begin
                $display("SPEC MAIN-3 FAIL");
                $display("*************************************************************************");
                $display("                     output latency is not 1 cycle                       ");
                $display("*************************************************************************");
                $finish;
            end
        end 
        else if (mode_reg == 2'd2) //calc
        begin
            for (i = 0; i < 4; i = i + 1) 
            begin
                if (out_data === 'bx || out_valid === 1'b0) begin
                    $display("SPEC MAIN-3 FAIL"); 
                    $finish;
                end
                
                root_ptr = {i[1:0], src_row_reg, 8'd0};
                golden_ans = calc_tree(root_ptr);
                
                if (out_data !== golden_ans) begin
                    $display("SPEC MAIN-4 FAIL"); 
                    $display("*************************************************************************");
                    $display("                     output data should be %h at index %d                ", golden_ans, i);
                    $display("*************************************************************************");
                    $finish;
                end
                count_out_valid = count_out_valid + 1;
                @(negedge clk);
            end
            if(out_valid !== 0 || count_out_valid !== 4)
            begin
                $display("SPEC MAIN-3 FAIL");
                $display("*************************************************************************");
                $display("                     output latency is not 4 cycles                      ");
                $display("*************************************************************************");
                $finish;
            end
        end 
        else if (mode_reg == 2'd3) //sort
        begin
            if (out_data === 'bx || out_valid === 1'b0) begin
                $display("SPEC MAIN-3 FAIL"); 
                $finish;
            end
            
            golden_sort;
            count_out_valid = count_out_valid + 1;
            
            for (i = 0; i < 4; i = i + 1) 
            begin
                for (j = 0; j < 256; j = j + 1) 
                begin
                    if (u_DRAM.DRAM[{i[1:0], dst_row_reg, j[7:0]}] !== golden_DRAM[{i[1:0], dst_row_reg, j[7:0]}]) 
                    begin
                        $display("SPEC MAIN-5 FAIL"); 
                        $display("*************************************************************************");
                        $display("                     DRAM data is wrong at address %h                    ", {i[1:0], dst_row_reg, j[7:0]});
                        $display("*************************************************************************");
                        $finish;
                    end
                end
            end
            @(negedge clk);
            if(out_valid !== 0 || count_out_valid !== 1)
            begin
                $display("SPEC MAIN-3 FAIL");
                $display("*************************************************************************");
                $display("                     output latency is not 1 cycle                       ");
                $display("*************************************************************************");
                $finish;
            end
        end
    end
    
end endtask

//aw_tracking
always @(*)
begin
    @(negedge clk);
    if(aw_valid === 1'b1)
        aw_tracking = 1;

    if(w_valid === 1'b1 && w_ready === 1'b1)
        aw_tracking = 0;
end

// *****************************************************************
// spec axi-1
always @(*) 
begin
    @(negedge clk);
    if(ar_valid === 1'b0 && ar_addr !== 'b0)
    begin
        $display("SPEC AXI-1 FAIL");
        $display("*************************************************************************");
        $display("             ar_addr should be reset when ar_valid is 0                  ");
        $display("*************************************************************************");
        $finish;
    end
    if(aw_valid === 1'b0 && aw_addr !== 'b0)
    begin
        $display("SPEC AXI-1 FAIL");
        $display("*************************************************************************");
        $display("             aw_addr should be reset when aw_valid is 0                  ");
        $display("*************************************************************************");
        $finish;
    end
    if(w_valid === 1'b0 && w_data !== 'b0)
    begin
        $display("SPEC AXI-1 FAIL");
        $display("*************************************************************************");
        $display("             w_data should be reset when w_valid is 0                  ");
        $display("*************************************************************************");
        $finish;
    end
    if(r_valid === 1'b0 && (r_data !== 'b0 || r_resp !== 'b0))
    begin
        $display("SPEC AXI-1 FAIL");
        $display("*************************************************************************");
        $display("         r_data and r_resp should be reset when r_valid is 0             ");
        $display("*************************************************************************");
        $finish;
    end
    if(b_valid === 1'b0 && b_resp !== 'b0)
    begin
        $display("SPEC AXI-1 FAIL");
        $display("*************************************************************************");
        $display("             b_resp should be reset when b_valid is 0                  ");
        $display("*************************************************************************");
        $finish;
    end
end 
// *****************************************************************
//spec axi-2 aw
always @(*)
begin
    @(negedge clk);
    if(aw_valid === 1'b1 && aw_ready !== 1'b1)
    begin
        aw_valid_temp = aw_valid;
        aw_addr_temp = aw_addr;
        @(negedge clk);
        while(aw_ready !== 1'b1)
        begin
            if(aw_valid_temp !== aw_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            aw_valid should be stable before aw_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            if(aw_addr_temp !== aw_addr)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             aw_addr should be stable before aw_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        if(aw_ready === 1'b1)//before handshake
        begin
            if(aw_valid_temp !== aw_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            aw_valid should be stable before aw_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            if(aw_addr_temp !== aw_addr)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             aw_addr should be stable before aw_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end
//spec axi-2 ar
always @(*)
begin
    @(negedge clk);
    if(ar_valid === 1'b1 && ar_ready !== 1'b1)
    begin
        ar_valid_temp = ar_valid;
        ar_addr_temp = ar_addr;
        @(negedge clk);
        while(ar_ready !== 1'b1)
        begin
            if(ar_valid_temp !== ar_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            ar_valid should be stable before ar_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            if(ar_addr_temp !== ar_addr)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             ar_addr should be stable before ar_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        if(ar_ready === 1'b1)//before handshake
        begin
            if(ar_valid_temp !== ar_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            ar_valid should be stable before ar_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            if(ar_addr_temp !== ar_addr)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             ar_addr should be stable before ar_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end
//spec axi-2 w
always @(*)
begin
    @(negedge clk);
    if(w_valid === 1'b1 && w_ready !== 1'b1)
    begin
        w_valid_temp = w_valid;
        w_data_temp = w_data;
        @(negedge clk);
        while(w_ready !== 1'b1)
        begin
            if(w_valid_temp !== w_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            w_valid should be stable before w_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            if(w_data_temp !== w_data)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             w_data should be stable before w_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        if(w_ready === 1'b1)//before handshake
        begin
            if(w_valid_temp !== w_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            w_valid should be stable before w_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            if(w_data_temp !== w_data)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             w_data should be stable before w_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end
//spec axi-2 r
always @(*)
begin
    @(negedge clk);
    if(r_valid === 1'b1 && r_ready !== 1'b1)
    begin
        r_valid_temp = r_valid;
        r_data_temp = r_data;
        r_resp_temp = r_resp;
        @(negedge clk);
        while(r_ready !== 1'b1)
        begin
            if(r_valid_temp !== r_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            r_valid should be stable before r_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            if(r_data_temp !== r_data)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             r_data should be stable before r_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            if(r_resp_temp !== r_resp)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             r_resp should be stable before r_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        if(r_ready === 1'b1)//before handshake
        begin
            if(r_valid_temp !== r_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            r_valid should be stable before r_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            if(r_data_temp !== r_data)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             r_data should be stable before r_ready is 1               ");
                $display("*************************************************************************");
                $finish;
            end
            if(r_resp_temp !== r_resp)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             r_resp should be stable before r_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end
//spec axi-2 b
always @(*)
begin
    @(negedge clk);
    if(b_valid === 1'b1 && b_ready !== 1'b1)
    begin
        b_valid_temp = b_valid;
        b_resp_temp = b_resp;
        @(negedge clk);
        while(b_ready !== 1'b1)
        begin
            if(b_valid_temp !== b_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            b_valid should be stable before b_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            if(b_resp_temp !== b_resp)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             b_resp should be stable before b_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        if(b_ready === 1'b1)//before handshake
        begin
            if(b_valid_temp !== b_valid)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("            b_valid should be stable before b_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            if(b_resp_temp !== b_resp)
            begin
                $display("SPEC AXI-2 FAIL");
                $display("*************************************************************************");
                $display("             b_resp should be stable before b_ready is 1                 ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end
// *****************************************************************
//spec axi-3
always @(*)
begin
    @(negedge clk);

    if(w_valid === 1'b1 && aw_tracking !== 1'b1 && aw_valid !== 1'b1)
    begin
        $display("SPEC AXI-3 FAIL");
        $display("*************************************************************************");
        $display("             w_valid can't be high before aw_valid is 1                  ");
        $display("*************************************************************************");
        $finish;
    end
end
// *****************************************************************
//spec axi-4    
always @(*)
begin
    @(negedge clk);
    if(aw_addr < 0 || aw_addr > 65535 || ar_addr < 0 || ar_addr > 65535)
    begin
        $display("SPEC AXI-4 FAIL");
        $display("*************************************************************************");
        $display("                     Address is out of bounds                            ");
        $display("*************************************************************************");
        $finish;
    end
end
// *****************************************************************
//spec axi-5 aw
always @(*)
begin
    @(negedge clk);
    count1 = 0;
    while(aw_valid === 1'b1)    
    begin
        while(aw_ready !== 1'b1)
        begin
            count1 = count1 + 1;
            if(count1 > 50)
            begin
                $display("SPEC AXI-5 FAIL");
                $display("*************************************************************************");
                $display("   AWREADY is not asserted within 50 cycles after AWVALID is asserted    ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        while(aw_ready === 1'b1)
        begin
            count1 = 0;
            @(negedge clk);
        end
    end
end
//spec axi-5 w
always @(*)
begin
    @(negedge clk);
    count2 = 0;
    while(w_valid === 1'b1)
    begin
        while(w_ready !== 1'b1)
        begin
            count2 = count2 + 1;
            if(count2 > 100)
            begin
                $display("SPEC AXI-5 FAIL");
                $display("*************************************************************************");
                $display("   WREADY is not asserted within 100 cycles after WVALID is asserted     ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        while(w_ready === 1'b1)
        begin
            count2 = 0;
            @(negedge clk);
        end
    end
end
//spec axi-5 b
always @(*)
begin
    @(negedge clk);
    count3 = 0;
    while(b_valid === 1'b1)
    begin
        while(b_ready !== 1'b1)
        begin
            count3 = count3 + 1;
            if(count3 > 100)
            begin
                $display("SPEC AXI-5 FAIL");
                $display("*************************************************************************");
                $display("   BREADY is not asserted within 100 cycles after BVALID is asserted     ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        while(b_ready === 1'b1)
        begin
            count3 = 0;
            @(negedge clk);
        end
    end
end
//spec axi-5 ar
always @(*)
begin
    @(negedge clk);
    count4 = 0;
    while(ar_valid === 1'b1)
    begin
        while(ar_ready !== 1'b1)
        begin
            count4 = count4 + 1;
            if(count4 > 50)
            begin
                $display("SPEC AXI-5 FAIL");
                $display("*************************************************************************");
                $display("   ARREADY is not asserted within 50 cycles after ARVALID is asserted    ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        while(ar_ready === 1'b1)
        begin
            count4 = 0;
            @(negedge clk);
        end
    end
end
//spec axi-5 r
always @(*)
begin
    @(negedge clk);
    count5 = 0;
    while(r_valid === 1'b1)
    begin
        while(r_ready !== 1'b1)
        begin
            count5 = count5 + 1;
            if(count5 > 100)
            begin
                $display("SPEC AXI-5 FAIL");
                $display("*************************************************************************");
                $display("   RREADY is not asserted within 100 cycles after RVALID is asserted     ");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
        while(r_ready === 1'b1)
        begin
            count5 = 0;
            @(negedge clk);
        end
    end
end
//*********************************************************************
always @(*)
begin
    @(negedge clk);

    if(aw_valid === 1'b1 && aw_ready === 1'b1)
    begin
        wait_w = 1'b1;
        ct_aw_w = 0;
    end
    if(w_valid === 1'b1 && w_ready === 1'b1)
    begin
        wait_w = 1'b0;
        ct_aw_w = 0;
    end

    if(w_valid === 1'b1 && w_ready === 1'b1)
    begin
        wait_b = 1'b1;
        ct_w_b = 0;
    end
    if(b_valid === 1'b1 && b_ready === 1'b1)
    begin
        wait_b = 1'b0;
        ct_w_b = 0;
    end

    if(ar_valid === 1'b1 && ar_ready === 1'b1)
    begin
        wait_r = 1'b1;
        ct_ar_r = 0;
    end
    if(r_valid === 1'b1 && r_ready === 1'b1)
    begin
        wait_r = 1'b0;
        ct_ar_r = 0;
    end
end
//spec axi-6 wait w
always @(*)
begin
    @(negedge clk);
    ct_aw_w = 0;
    while(wait_w === 1'b1)
    begin
        ct_aw_w = ct_aw_w + 1;
        if(ct_aw_w > 150)
        begin
            $display("SPEC AXI-6 FAIL");
            $display("*************************************************************************");
            $display("    wait w_valid for more than 150 cycles after aw handshake is done     ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
end
//spec axi-6 wait b
always @(*)
begin
    @(negedge clk);
    ct_w_b = 0;
    while(wait_b === 1'b1)
    begin
        ct_w_b = ct_w_b + 1;
        if(ct_w_b > 150)
        begin
            $display("SPEC AXI-6 FAIL");
            $display("*************************************************************************");
            $display("    wait b_valid for more than 150 cycles after w handshake is done      ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
end
//spec axi-6 wait r
always @(*)
begin
    @(negedge clk);
    ct_ar_r = 0;
    while(wait_r === 1'b1)
    begin
        ct_ar_r = ct_ar_r + 1;
        if(ct_ar_r > 150)
        begin
            $display("SPEC AXI-6 FAIL");
            $display("*************************************************************************");
            $display("    wait r_valid for more than 150 cycles after ar handshake is done     ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
end

// =======================================
// helper
// =======================================
task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask
task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

endmodule

// $display("*************************************************************************");
// $display("*                           SPEC MAIN-1 FAIL                            *");
// $display("*                           SPEC MAIN-2 FAIL                            *");
// $display("*                           SPEC MAIN-3 FAIL                            *");
// $display("*                           SPEC MAIN-4 FAIL                            *");
// $display("*                           SPEC MAIN-5 FAIL                            *");
// $display("*************************************************************************");

// $display("*************************************************************************");
// $display("*                          SPEC AXI-1 FAIL                              *");
// $display("*                          SPEC AXI-2 FAIL                              *");
// $display("*                          SPEC AXI-3 FAIL                              *");
// $display("*                          SPEC AXI-4 FAIL                              *");
// $display("*                          SPEC AXI-5 FAIL                              *");
// $display("*                          SPEC AXI-6 FAIL                              *");
// $display("*************************************************************************");