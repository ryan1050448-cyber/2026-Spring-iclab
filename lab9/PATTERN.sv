`include "Usertype.sv"
`define CYCLE_TIME 4.5
`define SEED 696967777

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;
parameter simulation_cycle = `CYCLE_TIME;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)]; // 0x10000 to 0x107FF
integer PATNUM = 1000;
integer i_pat, latency, total_latency;
integer debug_fd;

Warn_Msg gold_warn_msg;
logic    gold_complete;

// Extracted Word Data
logic [63:0] dram_w0, dram_w1;
logic [63:0] init_dram_w0, init_dram_w1;  
logic [63:0] final_dram_w0, final_dram_w1;
logic [11:0] w0_flour, w0_butter, w0_milk, w0_sugar;
logic [7:0]  w0_month, w0_day;
logic [11:0] w1_fruit, w1_sales;
logic [7:0]  w1_staff, w1_level;
logic [23:0] w1_balance;
logic [16:0] tmp_addr;
logic [63:0] tmp_data;
logic [1:0]  tmp_resp;
logic wait_r, wait_w;

// Temporary Calculation Variables
integer total_flour_req, total_butter_req, total_milk_req, total_sugar_req, total_fruit_req;
integer scale_factor, dessert_base_price, dessert_price, total_revenue;
integer flour_cost, butter_cost, milk_cost, sugar_cost, fruit_cost;
integer total_restock_cost, hire_cost, total_salary;
integer tmp_flour, tmp_butter, tmp_milk, tmp_sugar, tmp_fruit, tmp_staff;
integer L, max_sales, dump;
integer cnt, count_r_valid, count_w_ready;
integer pending_ar = 0, pending_aw = 0;

//================================================================
// class random 
//================================================================
class RandomInput;
    rand Action       action;
    rand Dessert_Type dessert_type;
    rand Order_Mode   mode;
    rand Month        month;
    rand Day          day;
    rand Data_No      shop_no;
    rand Staff_t      staff;
    rand Stock        restock[5];

    constraint limit_action { 
        action inside {Make_and_Sell, Restock, Hire_Staff, Pay_Day, Check_Valid_Date}; 
    } 
    constraint limit_type { 
        dessert_type inside {Cookie, Bread, Fruit_Cake, Pudding, Macaron, Pancake, Brownie, Scone}; 
    }
    constraint limit_mode { 
        mode inside {Single, Family_Set, Party_Pack}; 
    } 
    constraint limit_month { 
        month inside {[1:12]}; 
    }
    constraint limit_day {
        if (month inside {1,3,5,7,8,10,12}) day inside {[1:31]};
        else if (month inside {4,6,9,11}) day inside {[1:30]};
        else day inside {[1:28]}; // February only has 28 days
    }
    constraint limit_shop { 
        shop_no inside {[0:127]}; 
    }
    constraint limit_staff { 
        staff inside {[1:30]}; 
    }
    constraint limit_restock{ 
        restock[0] inside {[0:2047]};
        restock[1] inside {[0:2047]};
        restock[2] inside {[0:2047]};
        restock[3] inside {[0:2047]};
        restock[4] inside {[0:2047]};
    }
endclass

RandomInput rand_in;

//================================================================
// initial
//================================================================
initial begin
    debug_fd = $fopen("../00_TESTBED/debug.txt", "w");
    dump = $urandom(`SEED);
    rand_in = new();
    rand_in.srandom(`SEED);
    generate_and_load_dram();
    $readmemh(DRAM_p_r, golden_DRAM);
    //initial again
    $readmemh(DRAM_p_r, dram_r.DRAM);
    reset_task();

    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        if (!rand_in.randomize()) begin
            $display("[ERROR] Randomization Failed");
            $finish;
        end

        input_task();

        read_dram(rand_in.shop_no);
        init_dram_w0 = dram_w0;
        init_dram_w1 = dram_w1;

        calculate_golden();

        read_dram(rand_in.shop_no);
        final_dram_w0 = dram_w0;
        final_dram_w1 = dram_w1;

        dump_debug_task();
        wait_out_task();
        check_ans_task();
        
        total_latency = total_latency + latency;
        $display("\033[0;32mPASS PATTERN NO.%4d, Latency = %0d\033[m", i_pat, latency);
    end

    $fclose(debug_fd);
    YOU_PASS_task();
end

//================================================================
// AXI Protocol Monitors 
//================================================================
// 1. AR Channel Monitor
initial begin
    forever begin
        @(negedge clk);

        if(inf.AR_VALID === 1 && (inf.AR_ADDR > 'h107FF || inf.AR_ADDR < 'h10000)) begin
            $display("***********************************************************************************");
            $display("[AXI ERROR] AR_ADDR is out of range. Address should be between 0x10000 and 0x107FF."); 
            $display("***********************************************************************************");
            $finish; 
        end
        if(inf.AR_VALID === 1 && ^inf.AR_ADDR === 1'bx) begin
            $display("******************************************************");
            $display("[AXI ERROR] AR_ADDR has X value when AR_VALID is high."); 
            $display("******************************************************");
            $finish; 
        end

        if (inf.AR_VALID && !inf.AR_READY) begin
            tmp_addr = inf.AR_ADDR;
            cnt = 0;
            while (inf.AR_READY !== 1) begin
                cnt = cnt + 1;
                if (cnt > 500) begin 
                    $display("********************************************************");
                    $display("[AXI ERROR] AR_READY is not pull high within 500 cycles."); 
                    $display("********************************************************");
                    $finish; 
                end
                if (inf.AR_ADDR !== tmp_addr) begin 
                    $display("**************************************************************");
                    $display("[AXI ERROR] AR_ADDR should be stable until AR_READY goes high."); 
                    $display("**************************************************************");
                    $finish; 
                end
                if (!inf.AR_VALID) begin 
                    $display("**************************************************************");
                    $display("[AXI ERROR] AR_VALID should be stable until AR_READY goes high."); 
                    $display("**************************************************************");
                    $finish; 
                end
                @(negedge clk);
            end
        end
    end
end
// 2. R Channel Monitor
initial begin
    forever begin
        @(negedge clk);
        if(inf.R_VALID === 1 && ^inf.R_DATA === 1'bx) begin
            $display("******************************************************");
            $display("[AXI ERROR] R_DATA has X value when R_VALID is high."); 
            $display("******************************************************");
            $finish; 
        end
        if (inf.R_VALID && !inf.R_READY) begin
            tmp_resp = inf.R_RESP;
            cnt = 0;
            while (inf.R_READY !== 1) begin
                cnt = cnt + 1;
                if (cnt > 500) begin 
                    $display("******************************************************");
                    $display("[AXI ERROR] R_READY is not pull high within 500 cycles."); 
                    $display("******************************************************");
                    $finish; 
                end
                @(negedge clk);
            end
        end
    end
end
// 3. AW Channel Monitor
initial begin
    forever begin
        @(negedge clk);

        if(inf.AW_VALID === 1 && (inf.AW_ADDR > 'h107FF || inf.AW_ADDR < 'h10000)) begin
            $display("***********************************************************************************");
            $display("[AXI ERROR] AW_ADDR is out of range. Address should be between 0x10000 and 0x107FF."); 
            $display("***********************************************************************************");
            $finish; 
        end
        if(inf.AW_VALID === 1 && ^inf.AW_ADDR === 1'bx) begin
            $display("******************************************************");
            $display("[AXI ERROR] AW_ADDR has X value when AW_VALID is high."); 
            $display("******************************************************");
            $finish; 
        end

        if (inf.AW_VALID && !inf.AW_READY) begin
            tmp_addr = inf.AW_ADDR;
            cnt = 0;
            while (inf.AW_READY !== 1) begin
                cnt = cnt + 1;
                if (cnt > 500) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] AW_READY is not pulled high within 500 cycles."); 
                    $display("***********************************************************");
                    $finish; 
                end
                if (inf.AW_ADDR !== tmp_addr) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] AW_ADDR should be stable until AW_READY goes high."); 
                    $display("***********************************************************");
                    $finish; 
                end
                if (!inf.AW_VALID) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] AW_VALID should be stable until AW_READY goes high."); 
                    $display("***********************************************************");
                    $finish; 
                end
                @(negedge clk);
            end
        end
    end
end
// 4. W Channel Monitor
initial begin
    forever begin
        @(negedge clk);
        if(inf.W_VALID === 1 && ^inf.W_DATA === 1'bx) begin
            $display("******************************************************");
            $display("[AXI ERROR] W_DATA has X value when W_VALID is high."); 
            $display("******************************************************");
            $finish; 
        end
        if (inf.W_VALID && !inf.W_READY) begin
            tmp_data = inf.W_DATA;
            cnt = 0;
            while (inf.W_READY !== 1) begin
                cnt = cnt + 1;
                if (cnt > 500) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] W_READY is not pulled high within 500 cycles."); 
                    $display("***********************************************************");
                    $finish; 
                end
                if (inf.W_DATA !== tmp_data) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] W_DATA should be stable until W_READY goes high."); 
                    $display("***********************************************************");
                    $finish; 
                end
                if (!inf.W_VALID) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] W_VALID should be stable until W_READY goes high."); 
                    $display("***********************************************************");
                    $finish; 
                end
                @(negedge clk);
            end
        end
    end
end
// 5. B Channel Monitor
initial begin
    forever begin
        @(negedge clk);
        if (inf.B_VALID && !inf.B_READY) begin
            tmp_resp = inf.B_RESP;
            cnt = 0;
            while (inf.B_READY !== 1) begin
                cnt = cnt + 1;
                if (cnt > 500) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] B_READY is not pulled high within 500 cycles."); 
                    $display("***********************************************************");
                    $finish; 
                end
                if (!inf.B_VALID) begin 
                    $display("***********************************************************");
                    $display("[AXI ERROR] B_VALID should be stable until B_READY goes high."); 
                    $display("***********************************************************");
                    $finish; 
                end
                @(negedge clk);
            end
        end
    end
end
// outstading
//ar
initial begin
    forever begin
        @(negedge clk);
        if(inf.AR_VALID && inf.AR_READY) begin
            if(!(inf.R_VALID && inf.R_READY)) begin
                pending_ar = pending_ar + 1;
            end
        end
        else if(inf.R_VALID && inf.R_READY) begin
            if(pending_ar > 0) begin
                pending_ar = pending_ar - 1;
            end
            else begin
                $display("*************************************************************************");
                $display("[SPEC AXI] FATAL: R_VALID handshake occurred without any pending AR request.");
                $display("*************************************************************************");
                $finish;
            end
        end
        if(pending_ar > 0)
            wait_r = 1;
        else
            wait_r = 0;
    end
end
initial begin
    forever begin
        @(negedge clk);
        count_r_valid = 0;
        while(wait_r) begin
            if(inf.R_VALID !== 1)
                count_r_valid = count_r_valid + 1;
            else
                count_r_valid = 0;

            if(count_r_valid > 500) begin
                $display("*************************************************************************");
                $display("[AXI ERROR] R_VALID is not asserted within 500 cycles after AR handshake.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end
//aw
initial begin
    forever begin
        @(negedge clk);
        if(inf.AW_VALID && inf.AW_READY) begin
            if(!(inf.W_VALID && inf.W_READY)) begin
                pending_aw = pending_aw + 1;
            end
        end
        else if(inf.W_VALID && inf.W_READY) begin
            if(pending_aw > 0) begin
                pending_aw = pending_aw - 1;
            end
            else begin
                $display("*************************************************************************");
                $display("[SPEC AXI] FATAL: W_VALID handshake occurred without any pending AW request.");
                $display("*************************************************************************");
                $finish;
            end
        end
        if(pending_aw > 0)
            wait_w = 1;
        else
            wait_w = 0;
    end
end
initial begin
    forever begin
        @(negedge clk);
        count_w_ready = 0;
        while(wait_w) begin
            if(inf.W_READY !== 1)
                count_w_ready = count_w_ready + 1;
            else
                count_w_ready = 0;

            if(count_w_ready > 500) begin
                $display("*************************************************************************");
                $display("[AXI ERROR] W_READY is not asserted within 500 cycles after AW handshake.");
                $display("*************************************************************************");
                $finish;
            end
            @(negedge clk);
        end
    end
end

//================================================================
// Tasks
//================================================================
task generate_and_load_dram;
    integer fd, i, addr;
    logic [63:0] w0, w1;
    logic [31:0] w0_0, w0_1, w1_0, w1_1;
    begin
        fd = $fopen(DRAM_p_r, "w");
        for (i = 0; i < 128; i = i + 1) begin
            w0_flour = $urandom_range(100, 4000); w0_butter = $urandom_range(100, 4000); w0_month = $urandom_range(1, 12); 
            w0_milk = $urandom_range(100, 4000); w0_sugar = $urandom_range(100, 4000); w0_day = $urandom_range(1, 28); 
            w1_fruit = $urandom_range(100, 4000); w1_sales = $urandom_range(0, 100); w1_staff = $urandom_range(1, 50); 
            w1_level = $urandom_range(0, 100); w1_balance = $urandom_range(100000, 500000);

            w0 = {w0_flour, w0_butter, w0_month, w0_milk, w0_sugar, w0_day};
            w1 = {w1_fruit, w1_sales, w1_staff, w1_balance, w1_level};

            addr = 65536 + i * 16;
            {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
             golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]} = w0;
             
            addr = addr + 8;
            {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
             golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]} = w1;

            w0_0 = w0[31:0];
            w0_1 = w0[63:32];
            w1_0 = w1[31:0];
            w1_1 = w1[63:32];

            $fdisplay(fd, "@%05X", 32'h10000 + i*16);
            $fdisplay(fd, "%02X %02X %02X %02X", w0_0[7:0], w0_0[15:8], w0_0[23:16], w0_0[31:24]);
            
            $fdisplay(fd, "@%05X", 32'h10004 + i*16);
            $fdisplay(fd, "%02X %02X %02X %02X", w0_1[7:0], w0_1[15:8], w0_1[23:16], w0_1[31:24]);
            
            $fdisplay(fd, "@%05X", 32'h10008 + i*16);
            $fdisplay(fd, "%02X %02X %02X %02X", w1_0[7:0], w1_0[15:8], w1_0[23:16], w1_0[31:24]);
            
            $fdisplay(fd, "@%05X", 32'h1000C + i*16);
            $fdisplay(fd, "%02X %02X %02X %02X", w1_1[7:0], w1_1[15:8], w1_1[23:16], w1_1[31:24]);
        end
        $fclose(fd);
    end
endtask

task read_dram(input integer id);
    integer addr;
    begin
        addr = 65536 + id * 16;
        dram_w0 = {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
                   golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]};
        addr = addr + 8;
        dram_w1 = {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
                   golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]};
        {w0_flour, w0_butter, w0_month, w0_milk, w0_sugar, w0_day} = dram_w0;
        {w1_fruit, w1_sales, w1_staff, w1_balance, w1_level} = dram_w1;
    end
endtask

task write_dram(input integer id);
    integer addr;
    begin
        dram_w0 = {w0_flour, w0_butter, w0_month, w0_milk, w0_sugar, w0_day};
        dram_w1 = {w1_fruit, w1_sales, w1_staff, w1_balance, w1_level};
        
        addr = 65536 + id * 16;
        {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
         golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]} = dram_w0;
         
        addr = addr + 8;
        {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
         golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]} = dram_w1;
    end
endtask

task reset_task; begin
    inf.rst_n = 1;
    inf.sel_action_valid = 0; inf.type_valid = 0; inf.mode_valid = 0;
    inf.date_valid = 0; inf.data_no_valid = 0; inf.staff_valid = 0; inf.restock_valid = 0;
    inf.D = '0;
    total_latency = 0;

    #(simulation_cycle/2.0) inf.rst_n = 0;
    #(simulation_cycle*2.0) inf.rst_n = 1;

    if(inf.out_valid !== 0 || inf.warn_msg !== No_Warn || inf.complete !== 0) begin
        $display("*************************************************************");
        $display("[ERROR] Output signals should be low after reset deassertion."); 
        $display("*************************************************************");
        $finish; 
    end
    if(inf.AR_VALID !== 0 || inf.AR_ADDR !== 0 || inf.R_READY !== 0 || inf.AW_VALID !== 0 || inf.AW_ADDR !== 0
        || inf.W_VALID !== 0 || inf.W_DATA !== 0 || inf.B_READY !== 0) begin
        $display("*****************************************************************");
        $display("[ERROR] AXI master signals should be low after reset deassertion."); 
        $display("*****************************************************************");
        $finish; 
    end
end endtask

task input_task; 
integer i;
begin
    repeat($urandom_range(1, 4)) @(negedge clk);
    
    inf.sel_action_valid = 1; inf.D = '0; inf.D.d_act[0] = rand_in.action;
    @(negedge clk); inf.sel_action_valid = 0; inf.D = '0;
    repeat($urandom_range(1, 4)) @(negedge clk);

    if (rand_in.action == Make_and_Sell) begin
        inf.type_valid = 1; inf.D = '0; inf.D.d_type[0] = rand_in.dessert_type;
        @(negedge clk); inf.type_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.mode_valid = 1; inf.D = '0; inf.D.d_mode[0] = rand_in.mode;
        @(negedge clk); inf.mode_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0;

    end 
    else if (rand_in.action == Restock) begin
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);

        for (i=0; i<5; i=i+1) begin 
            inf.restock_valid = 1; inf.D = '0; inf.D.d_stock[0] = rand_in.restock[i];
            @(negedge clk); inf.restock_valid = 0; inf.D = '0; 
            if (i < 4) 
                repeat($urandom_range(0, 3)) @(negedge clk);
        end

    end 
    else if (rand_in.action == Hire_Staff) begin
        inf.staff_valid = 1; inf.D = '0; inf.D.d_staff[0] = rand_in.staff;
        @(negedge clk); inf.staff_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0;

    end 
    else begin // Pay Day & Check Valid Date
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0;
    end
end endtask

task calculate_golden; 
begin
    read_dram(rand_in.shop_no);
    // default
    gold_warn_msg = No_Warn;
    gold_complete = 1;

    // Priority 1: Date Warn
    if ((rand_in.month < w0_month) || (rand_in.month == w0_month && rand_in.day < w0_day)) begin
        gold_warn_msg = Date_Warn; 
        gold_complete = 0;

        if (rand_in.action == Check_Valid_Date) begin
            w0_month = rand_in.month;  
            w0_day   = rand_in.day;
            write_dram(rand_in.shop_no); 
        end
        return;
    end
    // no date warn
    w0_month = rand_in.month;
    w0_day   = rand_in.day;

    if (rand_in.action == Make_and_Sell) begin
        // Priority 2: No Staff Warn
        if (w1_staff == 0) begin
            gold_warn_msg = No_Staff_Warn; gold_complete = 0; 
            write_dram(rand_in.shop_no); 
            return;
        end
        
        // Priority 3: Calculate Requirements
        if(rand_in.mode == Single) 
            scale_factor = 1;
        else if(rand_in.mode == Family_Set) 
            scale_factor = 4;
        else if(rand_in.mode == Party_Pack) 
            scale_factor = 8;

        case (rand_in.dessert_type)
            Cookie: begin 
                total_flour_req = 100; total_butter_req = 50; total_milk_req = 0; total_sugar_req = 30; total_fruit_req = 0; dessert_base_price = 120; 
            end
            Bread: begin 
                total_flour_req = 200; total_butter_req = 20; total_milk_req = 50; total_sugar_req = 10; total_fruit_req = 0; dessert_base_price = 100; 
            end
            Fruit_Cake: begin 
                total_flour_req = 150; total_butter_req = 80; total_milk_req = 40; total_sugar_req = 60; total_fruit_req = 100; dessert_base_price = 400; 
            end
            Pudding: begin 
                total_flour_req = 0; total_butter_req = 0; total_milk_req = 150; total_sugar_req = 50; total_fruit_req = 20; dessert_base_price = 180; 
            end
            Macaron: begin 
                total_flour_req = 40; total_butter_req = 30; total_milk_req = 0; total_sugar_req = 120; total_fruit_req = 0; dessert_base_price = 250; 
            end
            Pancake: begin 
                total_flour_req = 120; total_butter_req = 30; total_milk_req = 80; total_sugar_req = 20; total_fruit_req = 40; dessert_base_price = 200; 
            end
            Brownie:begin 
                total_flour_req = 80; total_butter_req = 100; total_milk_req = 0; total_sugar_req = 100; total_fruit_req = 0; dessert_base_price = 280; 
            end
            Scone:begin 
                total_flour_req = 150; total_butter_req = 60; total_milk_req = 30; total_sugar_req = 20; total_fruit_req = 10; dessert_base_price = 160; 
            end
        endcase
        
        total_flour_req = total_flour_req * scale_factor; 
        total_butter_req = total_butter_req * scale_factor;
        total_milk_req = total_milk_req * scale_factor; 
        total_sugar_req = total_sugar_req * scale_factor; 
        total_fruit_req = total_fruit_req * scale_factor;
        
        if (w0_flour < total_flour_req || w0_butter < total_butter_req || w0_milk < total_milk_req || 
            w0_sugar < total_sugar_req || w1_fruit < total_fruit_req) begin
            gold_warn_msg = Stock_Warn; gold_complete = 0; 
            write_dram(rand_in.shop_no); 
            return;
        end
        
        w0_flour = w0_flour - total_flour_req; 
        w0_butter = w0_butter - total_butter_req;
        w0_milk = w0_milk - total_milk_req; 
        w0_sugar = w0_sugar - total_sugar_req; 
        w1_fruit = w1_fruit - total_fruit_req;

        L = w1_level;
        dessert_price = ((dessert_base_price * (10 + (L / 10))) / 10) + ((L * L) / 200);
        total_revenue = dessert_price * scale_factor;

        w1_balance = (w1_balance + total_revenue > 16777215) ? 16777215 : (w1_balance + total_revenue);
        w1_sales = w1_sales + scale_factor; // accumulate sales

        if (L == 100) begin
            if (w1_sales > 4095) w1_sales = 4095;
        end 
        else begin
            max_sales = (10 > (10 * (L / 10))) ? 10 : (10 * (L / 10));
            if (w1_sales >= max_sales) begin
                w1_level = L + 1;                
                w1_sales = w1_sales - max_sales; 
            end
        end

    end 
    else if (rand_in.action == Restock) begin 
        L = w1_level;
        flour_cost = (15 * (10 + L / 10)) / 10; 
        butter_cost = (60 * (10 + L / 10)) / 10;
        milk_cost = (25 * (10 + L / 10)) / 10; 
        sugar_cost = (10 * (10 + L / 10)) / 10; 
        fruit_cost = (80 * (10 + L / 10)) / 10;

        tmp_flour = w0_flour + rand_in.restock[0]; 
        tmp_butter = w0_butter + rand_in.restock[1];
        tmp_milk = w0_milk + rand_in.restock[2]; 
        tmp_sugar = w0_sugar + rand_in.restock[3]; 
        tmp_fruit = w1_fruit + rand_in.restock[4];

        // 1. Calculate the actual total restock cost based on clamped values
        total_restock_cost = 0;
        total_restock_cost += (tmp_flour > 4095) ? (4095 - w0_flour) * flour_cost : rand_in.restock[0] * flour_cost;
        total_restock_cost += (tmp_butter > 4095) ? (4095 - w0_butter) * butter_cost : rand_in.restock[1] * butter_cost;
        total_restock_cost += (tmp_milk > 4095) ? (4095 - w0_milk) * milk_cost : rand_in.restock[2] * milk_cost;
        total_restock_cost += (tmp_sugar > 4095) ? (4095 - w0_sugar) * sugar_cost : rand_in.restock[3] * sugar_cost;
        total_restock_cost += (tmp_fruit > 4095) ? (4095 - w1_fruit) * fruit_cost : rand_in.restock[4] * fruit_cost;

        // Priority 2: Balance Warn (Using actual cost)
        if (w1_balance < total_restock_cost) begin
            gold_warn_msg = Balance_Warn;
            gold_complete = 0; 
            write_dram(rand_in.shop_no); 
            return;
        end

        // Priority 3: Restock Warn
        if (tmp_flour > 4095 || tmp_butter > 4095 || tmp_milk > 4095 || tmp_sugar > 4095 || tmp_fruit > 4095) begin
            gold_warn_msg = Restock_Warn; gold_complete = 0; 
            //write_dram(rand_in.shop_no);
            //return;
        end

        // Update quantities with actual amounts
        w0_flour = (tmp_flour > 4095) ? 4095 : tmp_flour;
        w0_butter = (tmp_butter > 4095) ? 4095 : tmp_butter;
        w0_milk = (tmp_milk > 4095) ? 4095 : tmp_milk;
        w0_sugar = (tmp_sugar > 4095) ? 4095 : tmp_sugar;
        w1_fruit = (tmp_fruit > 4095) ? 4095 : tmp_fruit;

        w1_balance = w1_balance - total_restock_cost;

    end 
    else if (rand_in.action == Hire_Staff) begin
        L = w1_level;
        //hire_cost = (2000 + L * 100 + (L / 10) * 200) * rand_in.staff;
        tmp_staff = w1_staff + rand_in.staff;

        // 1. Calculate actual hire cost based on clamped staff limit
        if (tmp_staff > 100) begin
            hire_cost = (2000 + L * 100 + (L / 10) * 200) * (100 - w1_staff);
        end else begin
            hire_cost = (2000 + L * 100 + (L / 10) * 200) * rand_in.staff;
        end

        // Priority 2: Balance Warn (Using actual cost)
        if (w1_balance < hire_cost) begin
            gold_warn_msg = Balance_Warn;
            gold_complete = 0; 
            write_dram(rand_in.shop_no); 
            return;
        end
        
        // Priority 3: Staff Warn
        if (tmp_staff > 100) begin 
            gold_warn_msg = Staff_Warn;
            gold_complete = 0; 
            w1_staff = 100;
        end 
        else begin
            w1_staff = tmp_staff;
        end

        w1_balance = w1_balance - hire_cost;

    end 
    else if (rand_in.action == Pay_Day) begin 
        // Priority 2: No Staff Warn
        if (w1_staff == 0) begin
            gold_warn_msg = No_Staff_Warn; gold_complete = 0; 
            write_dram(rand_in.shop_no); 
            return;
        end

        L = w1_level;
        total_salary = (20000 + L * 200 + (L / 10) * 1000) * w1_staff;
        // Priority 3: Balance Warn
        if (w1_balance < total_salary) begin
            gold_warn_msg = Balance_Warn; gold_complete = 0; 
            w1_level = (w1_level < 10) ? 0 : w1_level - 10;
            w1_staff = (w1_staff / 2 == 0) ? 1 : (w1_staff / 2);
            w1_sales = 0;
        end 
        else begin
            w1_balance = w1_balance - total_salary;
        end
    end

    // Write Final Computed State back to Memory
    write_dram(rand_in.shop_no);
end
endtask

task wait_out_task; begin
    latency = 0;
    while (inf.out_valid !== 1) begin
        latency = latency + 1;
        if (latency > MAX_CYCLE) begin
            $display("***********************************");
            $display("[ERROR] Latency exceeded MAX_CYCLE.");
            $display("***********************************");
            $finish;
        end
        @(negedge clk);
    end
end endtask

task check_ans_task; begin
    if (inf.complete !== gold_complete || inf.warn_msg !== gold_warn_msg) begin
        $fdisplay(debug_fd, "\n[!!! MISMATCH !!!]");
        $fdisplay(debug_fd, "*************************************************************");
        $fdisplay(debug_fd, "Expected: complete=%b, warn_msg=%s (%3b)", gold_complete, gold_warn_msg.name(), gold_warn_msg);
        $fdisplay(debug_fd, "Received: complete=%b, warn_msg=%3b", inf.complete, inf.warn_msg);
        $fdisplay(debug_fd, "*************************************************************");
        $fclose(debug_fd); 

        // terimal
        $display("*************************************************************");
        $display("[ERROR] Mismatch at PATTERN %0d", i_pat);
        $display("Expected: complete=%b, warn_msg=%s (%3b)", gold_complete, gold_warn_msg.name(), gold_warn_msg);
        $display("Received: complete=%b, warn_msg=%3b", inf.complete, inf.warn_msg);
        $display(">> Please check debug.txt for current DRAM state and details.");
        $display("*************************************************************");
        $finish;
    end
    @(negedge clk);
end endtask

task dump_debug_task; begin
    read_dram(rand_in.shop_no);

    $fdisplay(debug_fd, "============================================================");
    $fdisplay(debug_fd, "PATTERN NO. %4d", i_pat);
    $fdisplay(debug_fd, "------------------------------------------------------------");
    $fdisplay(debug_fd, "[INPUT STIMULUS]");
    $fdisplay(debug_fd, "Action      : %s", rand_in.action.name());
    $fdisplay(debug_fd, "Shop ID     : %0d", rand_in.shop_no);
    $fdisplay(debug_fd, "Today's Date: %0d/%0d", rand_in.month, rand_in.day);
    
    if (rand_in.action == Make_and_Sell) begin
        $fdisplay(debug_fd, "Dessert     : %s", rand_in.dessert_type.name());
        $fdisplay(debug_fd, "Order Mode  : %s", rand_in.mode.name());
    end else if (rand_in.action == Restock) begin
        $fdisplay(debug_fd, "Restock     : F=%0d, B=%0d, M=%0d, S=%0d, Fr=%0d", 
                  rand_in.restock[0], rand_in.restock[1], rand_in.restock[2], 
                  rand_in.restock[3], rand_in.restock[4]);
    end else if (rand_in.action == Hire_Staff) begin
        $fdisplay(debug_fd, "Hire Staff  : %0d", rand_in.staff);
    end

    $fdisplay(debug_fd, "------------------------------------------------------------");
    $fdisplay(debug_fd, "[EXPECTED (GOLDEN) OUTPUT]");
    $fdisplay(debug_fd, "Complete    : %b", gold_complete);
    $fdisplay(debug_fd, "Warn Msg    : %s (%3b)", gold_warn_msg.name(), gold_warn_msg);
    
    $fdisplay(debug_fd, "------------------------------------------------------------");
    $fdisplay(debug_fd, "[GOLDEN DRAM STATE FOR SHOP %0d] (After Operation)", rand_in.shop_no);
    $fdisplay(debug_fd, "Action Date : %0d/%0d (Hex: %02x/%02x)", w0_month, w0_day, w0_month, w0_day);
    $fdisplay(debug_fd, "Ingredients : Flour=%4d (0x%03x), Butter=%4d (0x%03x), Milk=%4d (0x%03x), Sugar=%4d (0x%03x), Fruit=%4d (0x%03x)", 
              w0_flour, w0_flour, w0_butter, w0_butter, w0_milk, w0_milk, w0_sugar, w0_sugar, w1_fruit, w1_fruit);
    $fdisplay(debug_fd, "Sales       : %0d (0x%03x)", w1_sales, w1_sales);
    $fdisplay(debug_fd, "Staff       : %0d (0x%02x)", w1_staff, w1_staff);
    $fdisplay(debug_fd, "Level       : %0d (0x%02x)", w1_level, w1_level);
    $fdisplay(debug_fd, "Balance     : %0d (0x%06x)", w1_balance, w1_balance);
    
    $fdisplay(debug_fd, "------------------------------------------------------------");
    $fdisplay(debug_fd, "[64-bit HEX WORD COMPARISON]");
    $fdisplay(debug_fd, "Address     | Initial (Read from DRAM) | Expected (Write back to DRAM)");
    $fdisplay(debug_fd, "w0 (0x%05X) : %016x | %016x", 32'h10000 + rand_in.shop_no*16, init_dram_w0, final_dram_w0);
    $fdisplay(debug_fd, "w1 (0x%05X) : %016x | %016x", 32'h10000 + rand_in.shop_no*16 + 8, init_dram_w1, final_dram_w1);
    $fdisplay(debug_fd, "============================================================\n");
    
    $fflush(debug_fd); 
end endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", `CYCLE_TIME);
    $display("*************************************************************************");
    $finish;
end endtask

endprogram