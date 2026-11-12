`include "Usertype.sv"
`define CYCLE_TIME 4.0
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
integer PATNUM = 10000;
integer i_pat, latency, total_latency;

Warn_Msg gold_warn_msg;
logic    gold_complete;
Action   temp_act;
Stock    temp_restock[0:4];

// Extracted Word Data
logic [63:0] dram_w0, dram_w1;
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
integer current_m = 1, current_d = 1, days_in_month, pat_ct = 0;
integer count;
integer restock_idx = 0;

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

    integer force_m = 1, force_d = 1, force_date_warn = 0;

    constraint limit_action { 
        action dist {Make_and_Sell:=1, Restock:=5, Hire_Staff:=5, Pay_Day:=1, Check_Valid_Date:=1}; 
    } 
    constraint limit_type { 
        dessert_type inside {Cookie, Bread, Fruit_Cake, Pudding, Macaron, Pancake, Brownie, Scone}; 
    }
    constraint limit_mode { 
        mode inside {Single, Family_Set, Party_Pack}; 
    } 
    constraint limit_month { 
        if(force_date_warn) month inside {[1:2]}; 
        else month == force_m;
    }
    constraint limit_day {
        if(force_date_warn) day inside {[1:28]};
        else day == force_d;
    }
    constraint limit_shop { 
        shop_no inside {[0:127]}; 
    }
    constraint limit_staff { 
        if (action == Hire_Staff) 
            staff inside {[45:60]}; 
        else 
            staff inside {[1:60]};
        
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

class RandomDram;
    rand logic [11:0] flour, butter, milk, sugar, fruit;
    rand logic [7:0]  month, day;
    rand logic [11:0] sales;
    rand logic [7:0]  staff, level;
    rand logic [23:0] balance;

    constraint limit_ingredients {
        flour   dist {[10:100]:/1, [100:4000]:/2};
        butter  dist {[10:100]:/1, [100:4000]:/2};
        milk    dist {[10:100]:/1, [100:4000]:/2};
        sugar   dist {[10:100]:/1, [100:4000]:/2};
        fruit   dist {[10:100]:/1, [100:4000]:/2};
        staff   dist {0:/1, [1:50]:/2};
        level   inside {[0:100]};
        balance dist {[1000:1000000]:/1, [1000000:16777215]:/2};
    }

    constraint limit_month { 
        month inside {[1:12]}; 
    }
    constraint limit_day {
        if (month inside {1, 3, 5, 7, 8, 10, 12}) day inside {[1:31]};
        else if (month inside {4, 6, 9, 11}) day inside {[1:30]};
        else day inside {[1:28]}; // February only has 28 days
    }
    constraint limit_sales {
        if (level < 10) {
            sales inside {[0:9]};
        } 
        else {
            sales inside {[0 : (level/10)*10 - 1]};
        }
    }
endclass
RandomDram rand_dram;

//================================================================
// initial
//================================================================
initial begin
    //debug_fd = $fopen("../00_TESTBED/debug.txt", "w");
    dump = $urandom(`SEED);
    rand_in = new();
    rand_in.srandom(`SEED);
    rand_dram = new();
    rand_dram.srandom(`SEED + 1); // Use a different seed for DRAM randomization
    
    generate_and_load_dram();
    $readmemh(DRAM_p_r, golden_DRAM);
    check_dram_legal_task();
    //initial again
    $readmemh(DRAM_p_r, dram_r.DRAM);
    reset_task();

    for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        
        gem_date_warn_task();
        
        if (!rand_in.randomize()) begin
            $display("[ERROR] Randomization Failed");
            $finish;
        end
        if(i_pat == 8000)
            test_input_task();
        else
            input_task();
            
        read_dram(rand_in.shop_no);
        calculate_golden();
        read_dram(rand_in.shop_no);

        //dump_debug_task();
        wait_out_task();
        check_ans_task();
        
        total_latency = total_latency + latency;
        $display("\033[0;32mPASS PATTERN NO.%4d, Latency = %0d\033[m", i_pat, latency);
    end

    //fclose(debug_fd);
    YOU_PASS_task();
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

            if (!rand_dram.randomize()) begin
                $display("[ERROR] DRAM Randomization Failed at Shop %0d", i);
                $finish;
            end

            w0_flour  = rand_dram.flour;
            w0_butter = rand_dram.butter;
            w0_month  = rand_dram.month;
            w0_milk   = rand_dram.milk;
            w0_sugar  = rand_dram.sugar;
            w0_day    = rand_dram.day;
            
            w1_fruit  = rand_dram.fruit;
            w1_sales  = rand_dram.sales;
            w1_staff  = rand_dram.staff;
            w1_level  = rand_dram.level;
            w1_balance = rand_dram.balance;

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

task check_dram_legal_task;
    integer i;
    integer max_s;
begin
    for (i = 0; i < 128; i = i + 1) begin
        
        read_dram(i);

        if (w0_month < 1 || w0_month > 12) begin
            $display("[ERROR] Illegal DRAM Data: Shop %0d has invalid month %0d", i, w0_month);
            $finish;
        end
        if (w0_month == 2) begin
            if (w0_day < 1 || w0_day > 28) begin 
                $display("[ERROR] Illegal DRAM Data: Shop %0d has invalid day %0d for month 2", i, w0_day);
                $finish;
            end
        end else if (w0_month == 4 || w0_month == 6 || w0_month == 9 || w0_month == 11) begin
            if (w0_day < 1 || w0_day > 30) begin
                $display("[ERROR] Illegal DRAM Data: Shop %0d has invalid day %0d for month %0d", i, w0_day, w0_month);
                $finish;
            end
        end else begin
            if (w0_day < 1 || w0_day > 31) begin
                $display("[ERROR] Illegal DRAM Data: Shop %0d has invalid day %0d for month %0d", i, w0_day, w0_month);
                $finish;
            end
        end

        if (w1_level > 100) begin
            $display("[ERROR] Illegal DRAM Data: Shop %0d has level %0d > 100", i, w1_level);
            $finish;
        end
        if (w1_level < 100) begin
            max_s = (10 > (10 * (w1_level / 10))) ? 10 : (10 * (w1_level / 10));
            if (w1_sales >= max_s) begin
                $display("[ERROR] Illegal DRAM Data: Shop %0d has sales %0d >= max_sales %0d for level %0d", i, w1_sales, max_s, w1_level);
                $finish;
            end
        end

        if (w1_staff > 100) begin
            $display("[ERROR] Illegal DRAM Data: Shop %0d has staff %0d > 100", i, w1_staff);
            $finish;
        end

        if(w0_flour > 4095 || w0_butter > 4095 || w0_milk > 4095 || w0_sugar > 4095 || w1_fruit > 4095) begin
            $display("[ERROR] Illegal DRAM Data: Shop %0d has ingredient quantity greater than 4095", i);
            $finish;
        end

        if(w1_balance > 16777215) begin
            $display("[ERROR] Illegal DRAM Data: Shop %0d has balance greater than 16777215", i);
            $finish;
        end
    end
    
    $display("\033[0;34m[INFO] DRAM Data Legal Check Passed!\033[m");
end
endtask

task reset_task; begin
    inf.rst_n = 1;
    inf.sel_action_valid = 0; inf.type_valid = 0; inf.mode_valid = 0;
    inf.date_valid = 0; inf.data_no_valid = 0; inf.staff_valid = 0; inf.restock_valid = 0;
    inf.D = '0;
    total_latency = 0;
    count = 0;

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

task gem_date_warn_task;
begin
    pat_ct = pat_ct + 1;
    if(pat_ct == 25)
    begin
        pat_ct = 0;
        current_d = current_d + 1;

        if(current_m == 2)
            days_in_month = 28;
        else if(current_m == 4 || current_m == 6 || current_m == 9 || current_m == 11)
            days_in_month = 30;
        else
            days_in_month = 31;

        if(current_d > days_in_month)
        begin
            current_m = current_m + 1;
            current_d = 1;
            if(current_m > 12) current_m = 1;
        end

        rand_in.force_date_warn = (i_pat % 10 == 0) ? 1 : 0; // Force date warn every 10 patterns
        rand_in.force_m = current_m;
        rand_in.force_d = current_d;
    end

end endtask

task input_task; 
integer i;
begin
    repeat($urandom_range(0, 3)) @(negedge clk);
    
    inf.sel_action_valid = 1; inf.D = '0; 
    if(i_pat < 5000) //0-4999
    begin
        case (i_pat % 25)
            0:  temp_act = Make_and_Sell;     // 0
            1:  temp_act = Make_and_Sell;     // 0->0
            2:  temp_act = Restock;           // 0->1
            3:  temp_act = Make_and_Sell;     // 1->0
            4:  temp_act = Hire_Staff;        // 0->2
            5:  temp_act = Make_and_Sell;     // 2->0
            6:  temp_act = Pay_Day;           // 0->3
            7:  temp_act = Make_and_Sell;     // 3->0
            8:  temp_act = Check_Valid_Date;  // 0->4
            9:  temp_act = Restock;           // 4->1
            10: temp_act = Restock;           // 1->1
            11: temp_act = Hire_Staff;        // 1->2
            12: temp_act = Restock;           // 2->1
            13: temp_act = Pay_Day;           // 1->3
            14: temp_act = Restock;           // 3->1
            15: temp_act = Check_Valid_Date;  // 1->4
            16: temp_act = Hire_Staff;        // 4->2
            17: temp_act = Hire_Staff;        // 2->2
            18: temp_act = Pay_Day;           // 2->3
            19: temp_act = Hire_Staff;        // 3->2
            20: temp_act = Check_Valid_Date;  // 2->4
            21: temp_act = Pay_Day;           // 4->3
            22: temp_act = Pay_Day;           // 3->3
            23: temp_act = Check_Valid_Date;  // 3->4
            24: temp_act = Check_Valid_Date;  // 4->4 
        endcase
    end
    else if(i_pat < 6500)// 5000-6499
        temp_act = Make_and_Sell;
    else if(i_pat < 6800)// 6500-6799
        temp_act = Restock;
    else if(i_pat < 7000)// 6800-6999
        temp_act = Hire_Staff;
    else// 7000-9999
    begin
        temp_act = rand_in.action;
    end

    inf.D.d_act[0] = temp_act;
    rand_in.action = temp_act; // For golden model calculation
    
    @(negedge clk); inf.sel_action_valid = 0; inf.D = '0;
    repeat($urandom_range(0, 3)) @(negedge clk);

    if (temp_act == Make_and_Sell) begin
        inf.type_valid = 1; inf.D = '0; 
        case(count % 8)
            0: begin
                inf.D.d_type[0] = Cookie; rand_in.dessert_type = Cookie; 
            end
            1: begin
                inf.D.d_type[0] = Bread; rand_in.dessert_type = Bread; 
            end
            2: begin
                inf.D.d_type[0] = Fruit_Cake; rand_in.dessert_type = Fruit_Cake; 
            end
            3: begin
                inf.D.d_type[0] = Pudding; rand_in.dessert_type = Pudding; 
            end
            4: begin
                inf.D.d_type[0] = Macaron; rand_in.dessert_type = Macaron; 
            end
            5: begin
                inf.D.d_type[0] = Pancake; rand_in.dessert_type = Pancake; 
            end
            6: begin
                inf.D.d_type[0] = Brownie; rand_in.dessert_type = Brownie; 
            end
            7: begin
                inf.D.d_type[0] = Scone; rand_in.dessert_type = Scone; 
            end
        endcase
        
        @(negedge clk); inf.type_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.mode_valid = 1; inf.D = '0; 
        case(count % 3)
            0: begin
                inf.D.d_mode[0] = Single; rand_in.mode = Single;
            end
            1: begin
                inf.D.d_mode[0] = Family_Set; rand_in.mode = Family_Set;
            end
            2: begin
                inf.D.d_mode[0] = Party_Pack; rand_in.mode = Party_Pack;
            end
        endcase

        @(negedge clk); inf.mode_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0;

        count = count + 1;

    end 
    else if (temp_act == Restock) begin
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);

        for (i=0; i<5; i=i+1) begin
            temp_restock[i] = ( (restock_idx + i) * 16 + $urandom_range(0, 15)) % 2048; 
            rand_in.restock[i] = temp_restock[i]; // For golden model calculation
        end
        restock_idx = restock_idx + 1;

        for (i=0; i<5; i=i+1) begin 
            inf.restock_valid = 1; inf.D = '0; 
            inf.D.d_stock[0] = temp_restock[i];
            @(negedge clk); inf.restock_valid = 0; inf.D = '0; 
            if (i < 4) 
                repeat($urandom_range(0, 3)) @(negedge clk);
        end

    end 
    else if (temp_act == Hire_Staff) begin
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

task test_input_task;
integer i;
begin
    if(i_pat == 8000)
    begin
        inf.sel_action_valid = 1; inf.D = '0;
        temp_act = Make_and_Sell;
        inf.D.d_act[0] = temp_act;
        rand_in.action = temp_act;
        @(negedge clk); inf.sel_action_valid = 0; inf.D = '0;
        repeat($urandom_range(0, 3)) @(negedge clk);

        inf.type_valid = 1; inf.D = '0;
        inf.D.d_type[0] = Cookie;
        rand_in.dessert_type = Cookie;
        @(negedge clk); inf.type_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.mode_valid = 1; inf.D = '0; 
        inf.D.d_mode[0] = Single;
        rand_in.mode = Single;
        @(negedge clk); inf.mode_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; 
        repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0;
    end
    if(i_pat == 8001)
    begin
        inf.sel_action_valid = 1; inf.D = '0;
        temp_act = Restock;
        inf.D.d_act[0] = temp_act;
        rand_in.action = temp_act;
        @(negedge clk); inf.sel_action_valid = 0; inf.D = '0;
        repeat($urandom_range(0, 3)) @(negedge clk);

        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);

        for (i=0; i<5; i=i+1) begin
            temp_restock[i] = ( (restock_idx + i) * 16 + $urandom_range(0, 15)) % 2048; 
            rand_in.restock[i] = temp_restock[i]; // For golden model calculation
        end
        restock_idx = restock_idx + 1;

        for (i=0; i<5; i=i+1) begin 
            inf.restock_valid = 1; inf.D = '0; 
            inf.D.d_stock[0] = temp_restock[i];
            @(negedge clk); inf.restock_valid = 0; inf.D = '0; 
            if (i < 4) 
                repeat($urandom_range(0, 3)) @(negedge clk);
        end
    end
    if(i_pat == 8002)
    begin
        inf.sel_action_valid = 1; inf.D = '0;
        temp_act = Hire_Staff;
        inf.D.d_act[0] = temp_act;
        rand_in.action = temp_act;
        @(negedge clk); inf.sel_action_valid = 0; inf.D = '0;
        repeat($urandom_range(0, 3)) @(negedge clk);

        inf.staff_valid = 1; inf.D = '0; inf.D.d_staff[0] = rand_in.staff;
        @(negedge clk); inf.staff_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.date_valid = 1; inf.D = '0; inf.D.d_date[0].M = rand_in.month; inf.D.d_date[0].D = rand_in.day;
        @(negedge clk); inf.date_valid = 0; inf.D = '0; repeat($urandom_range(0, 3)) @(negedge clk);
        
        inf.data_no_valid = 1; inf.D = '0; inf.D.d_data_no[0] = rand_in.shop_no;
        @(negedge clk); inf.data_no_valid = 0; inf.D = '0;
    end
    if(i_pat == 8003)
    begin
        inf.sel_action_valid = 1; inf.D = '0;
        temp_act = Pay_Day;
        inf.D.d_act[0] = temp_act;
        rand_in.action = temp_act;
        @(negedge clk); inf.sel_action_valid = 0; inf.D = '0;
        repeat($urandom_range(0, 3)) @(negedge clk);

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
        //$fdisplay(debug_fd, "\n[!!! MISMATCH !!!]");
        //$fdisplay(debug_fd, "*************************************************************");
        //$fdisplay(debug_fd, "Expected: complete=%b, warn_msg=%s (%3b)", gold_complete, gold_warn_msg.name(), gold_warn_msg);
        //$fdisplay(debug_fd, "Received: complete=%b, warn_msg=%3b", inf.complete, inf.warn_msg);
        //$fdisplay(debug_fd, "*************************************************************");
        //$fclose(debug_fd); 

        // terimal
        $display("Wrong Answer");
        $display("*************************************************************");
        $display("[ERROR] Mismatch at PATTERN %0d", i_pat);
        $display("Expected: complete=%b, warn_msg=%s (%3b)", gold_complete, gold_warn_msg.name(), gold_warn_msg);
        $display("Received: complete=%b, warn_msg=%3b", inf.complete, inf.warn_msg);
        //$display(">> Please check debug.txt for current DRAM state and details.");
        $display("*************************************************************");
        $finish;
    end
    @(negedge clk);
end endtask

/*task dump_debug_task; begin
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
end endtask*/

task YOU_PASS_task; begin
    $display("Congratulations");
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", `CYCLE_TIME);
    $display("*************************************************************************");
    $finish;
end endtask

endprogram