//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2026/5
//		Version		: v1.0
//   	File Name   : DSS.sv
//   	Module Name : DSS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module DSS(input clk, INF.DSS_inf inf);
import usertype::*;
//================================================================
// State Machine
//================================================================
typedef enum logic [4:0] {
    IDLE, GET_IN, AR0, R0, AR1, R1,
    CALC,
    AW0, W0, B0, AW1, W1, B1
} State;

State state, next_state;
//================================================================
// Declarations
//================================================================
Action act, next_act;
Dessert_Type dessert_type, next_dessert_type;
Order_Mode mode, next_mode;
Date date, next_date;
Data_No data_no, next_data_no;
Staff_t in_staff, next_in_staff, real_staff, next_real_staff;
Stock in_res [0:4], next_in_res [0:4];
logic [2:0] res_ct, next_res_ct;
// DRAM Data Storage
logic [63:0] w0, next_w0, w1, next_w1;
// Pipelined Calculation Registers
logic [7:0] l_div10, next_l_div10, l_add10, next_l_add10;
logic [13:0] l_sq, next_l_sq;
logic [15:0] cf_m, next_cf_m, cb_m, next_cb_m, cm_m, next_cm_m, cs_m, next_cs_m, cfr_m, next_cfr_m;
logic [11:0] cf_d, next_cf_d, cb_d, next_cb_d, cm_d, next_cm_d, cs_d, next_cs_d, cfr_d, next_cfr_d;
logic [23:0] cost_f, next_cost_f, cost_b, next_cost_b, cost_m, next_cost_m, cost_s, next_cost_s, cost_fr, next_cost_fr;
logic [3:0] calc_ct, next_calc_ct, pipe_ct, next_pipe_ct;
logic calc_end_valid, write_dram_valid;
logic [15:0] temp1, next_temp1, temp2, next_temp2;
logic [12:0] price_temp, next_price_temp, temp1_div, next_temp1_div, temp2_div, next_temp2_div;
logic [15:0] unit_cost, next_unit_cost;
logic [27:0] req_cost, next_req_cost, total_rev, next_total_rev, real_cost, next_real_cost;
logic [13:0] dessert_price, next_dessert_price;
logic [11:0] real_res_f, next_real_res_f, real_res_b, next_real_res_b, real_res_m, next_real_res_m, real_res_s, next_real_res_s, real_res_fr, next_real_res_fr;
// base
logic [11:0] base_f, base_b, base_m, base_s, base_fr;
logic [15:0] base_price;
logic [3:0] scale;
logic [11:0] req_f, req_b, req_m, req_s, req_fr;
//warn
logic date_older, no_staff, stock_warn;
logic [11:0] max_sales;
//output
logic out_valid, next_out_valid;
logic [2:0] warn_msg, next_warn_msg;
logic complete, next_complete;

//share div/mult
logic [19:0] shared_div_a, shared_div_out;
logic [15:0] shared_mult_a, next_shared_mult_a;
logic [11:0] shared_mult_b, next_shared_mult_b;
logic [27:0] shared_mult_out;

//axi
logic ar_valid, next_ar_valid, aw_valid, next_aw_valid, w_valid, next_w_valid, b_ready, next_b_ready, r_ready, next_r_ready;
logic [16:0] ar_addr, next_ar_addr, aw_addr, next_aw_addr;
logic [63:0] w_data, next_w_data;

logic [2:0] warn_mg, next_warn_mg;
logic complete_mg, next_complete_mg;
//integer i;
//================================================================
// Design
//================================================================
// state
always_comb 
begin 
    next_state = state;

    case(state)
        IDLE: begin
            next_state = (inf.sel_action_valid) ? GET_IN : IDLE;
        end
        GET_IN: begin
            if(act == Restock)
            begin
                if(inf.restock_valid && res_ct == 4)
                    next_state = AR0;
                else
                    next_state = GET_IN;
            end
            else
            begin
                if(inf.data_no_valid)
                    next_state = AR0;
                else
                    next_state = GET_IN;
            end
        end
        AR0: begin
            next_state = (inf.AR_VALID && inf.AR_READY) ? R0 : AR0;
        end
        R0: begin
            next_state = (inf.R_VALID && inf.R_READY) ? AR1 : R0;
        end
        AR1: begin
            next_state = (inf.AR_VALID && inf.AR_READY) ? R1 : AR1;
        end
        R1: begin
            next_state = (inf.R_VALID && inf.R_READY) ? CALC : R1;
        end
        CALC: begin
            if(write_dram_valid)
                next_state = AW0;
            else if(calc_end_valid)
                next_state = IDLE;
            else
                next_state = CALC;
        end
        AW0: begin
            next_state = (inf.AW_VALID && inf.AW_READY) ? W0 : AW0;
        end
        W0: begin
            next_state = (inf.W_VALID && inf.W_READY) ? B0 : W0;
        end
        B0: begin
            next_state = (inf.B_VALID && inf.B_READY) ? AW1 : B0;
        end
        AW1: begin
            next_state = (inf.AW_VALID && inf.AW_READY) ? W1 : AW1;
        end
        W1: begin
            next_state = (inf.W_VALID && inf.W_READY) ? B1 : W1;
        end
        B1: begin
            next_state = (inf.B_VALID && inf.B_READY) ? IDLE : B1;
        end
    endcase
end
//input
always_comb 
begin
    next_act = act;
    next_dessert_type = dessert_type;
    next_mode = mode;
    next_date = date;
    next_data_no = data_no;
    next_in_staff = in_staff;
    next_res_ct = res_ct;
    for (int i = 0; i < 5; i = i + 1) 
    begin
        next_in_res[i] = in_res[i];
    end
    
    if(inf.sel_action_valid)
        next_act = inf.D.d_act[0];
    if(inf.type_valid)
        next_dessert_type = inf.D.d_type[0];
    if(inf.mode_valid)
        next_mode = inf.D.d_mode[0];
    if(inf.date_valid)
        next_date = inf.D.d_date[0];
    if(inf.data_no_valid)
        next_data_no = inf.D.d_data_no[0];
    if(inf.staff_valid)
        next_in_staff = inf.D.d_staff[0];
    if(inf.restock_valid)
    begin
        next_in_res[res_ct] = inf.D.d_stock[0];
        next_res_ct = res_ct + 1;
    end
    else if(state == IDLE)
        next_res_ct = 0;

end
// dessert type
always_comb 
begin
    base_f = 0; base_b = 0; base_m = 0; base_s = 0; base_fr = 0; 
    base_price = 0; 

    case(dessert_type)
        Cookie: begin
            base_f = 100; base_b = 50; base_m = 0; base_s = 30; base_fr = 0; base_price = 120;
        end
        Bread: begin
            base_f = 200; base_b = 20; base_m = 50; base_s = 10; base_fr = 0; base_price = 100;
        end
        Fruit_Cake: begin
            base_f = 150; base_b = 80; base_m = 40; base_s = 60; base_fr = 100; base_price = 400;
        end
        Pudding: begin
            base_f = 0; base_b = 0; base_m = 150; base_s = 50; base_fr = 20; base_price = 180;
        end
        Macaron: begin
            base_f = 40; base_b = 30; base_m = 0; base_s = 120; base_fr = 0; base_price = 250;
        end
        Pancake: begin
            base_f = 120; base_b = 30; base_m = 80; base_s = 20; base_fr = 40; base_price = 200;
        end
        Brownie: begin
            base_f = 80; base_b = 100; base_m = 0; base_s = 100; base_fr = 0; base_price = 280;
        end
        Scone: begin
            base_f = 150; base_b = 60; base_m = 30; base_s = 20; base_fr = 10; base_price = 160;
        end
    endcase
end
//scale and required resources
always_comb 
begin
    scale = 0;
    req_f = 0; req_b = 0; req_m = 0; req_s = 0; req_fr = 0;

    case(mode)
        Single: begin
            scale = 1;
            req_f = base_f; req_b = base_b; req_m = base_m; 
            req_s = base_s; req_fr = base_fr;
        end
        Family_Set: begin
            scale = 4;
            req_f = base_f << 2; req_b = base_b << 2; req_m = base_m << 2;
            req_s = base_s << 2; req_fr = base_fr << 2;
        end
        Party_Pack: begin
            scale = 8;
            req_f = base_f << 3; req_b = base_b << 3; req_m = base_m << 3;
            req_s = base_s << 3; req_fr = base_fr << 3;
        end
    endcase
end
//warn
always_comb 
begin
    if((date.M < w0[39:32]) || (date.M == w0[39:32] && date.D < w0[7:0])) 
        date_older = 1;
    else
        date_older = 0;

    if(w1[39:32] == 0)
        no_staff = 1;
    else
        no_staff = 0;

    if(w0[63:52] < req_f || w0[51:40] < req_b || w0[31:20] < req_m || w0[19:8] < req_s || w1[63:52] < req_fr)
        stock_warn = 1;
    else
        stock_warn = 0;
    
    if(w1[7:0] >= 10)// level >= 10
        max_sales = l_div10 * 10;
    else
        max_sales = 10;
end
//ct
always_comb 
begin
    next_calc_ct = calc_ct;
    next_pipe_ct = pipe_ct;

    if(state == CALC)
        next_calc_ct = calc_ct + 1;
    else
        next_calc_ct = 0;
    
    if(calc_ct == 4 && act == Restock)
    begin
        next_pipe_ct = pipe_ct + 1;
        next_calc_ct = calc_ct;
        if(pipe_ct == 1)
        begin
            next_pipe_ct = 0;
            next_calc_ct = calc_ct + 1;
        end
    end
    else if(calc_ct == 5 && act == Restock)
    begin
        next_pipe_ct = pipe_ct + 1;
        next_calc_ct = calc_ct;
        if(pipe_ct == 4)
        begin
            next_pipe_ct = 0;
            next_calc_ct = calc_ct + 1;
        end
    end
    else if(calc_ct == 8 && act == Restock)
    begin
        next_pipe_ct = pipe_ct + 1;
        next_calc_ct = calc_ct;
        if(pipe_ct == 4)
        begin
            next_pipe_ct = 0;
            next_calc_ct = calc_ct + 1;
        end
    end
end

//w0, w1
always_comb 
begin 
    next_w0 = w0; next_w1 = w1;
    next_warn_mg = warn_mg; 
    next_complete_mg = complete_mg;
    calc_end_valid = 0; write_dram_valid = 0;
    next_l_div10 = l_div10; next_l_add10 = l_add10; next_l_sq = l_sq;
    next_temp1 = temp1; next_temp2 = temp2; next_price_temp = price_temp;
    next_cf_m = cf_m; next_cb_m = cb_m; next_cm_m = cm_m; next_cs_m = cs_m; next_cfr_m = cfr_m;
    next_unit_cost = unit_cost;
    next_temp1_div = temp1_div; next_temp2_div = temp2_div;
    next_cf_d = cf_d; next_cb_d = cb_d; next_cm_d = cm_d; next_cs_d = cs_d; next_cfr_d = cfr_d;
    next_req_cost = req_cost;
    next_dessert_price = dessert_price;
    next_cost_f = cost_f; next_cost_b = cost_b; next_cost_m = cost_m; next_cost_s = cost_s; next_cost_fr = cost_fr;
    next_real_staff = real_staff;
    next_total_rev = total_rev; next_real_cost = real_cost;
    next_real_res_f = real_res_f; next_real_res_b = real_res_b; next_real_res_m = real_res_m; next_real_res_s = real_res_s; next_real_res_fr = real_res_fr;


    if(state == R0 && inf.R_VALID && inf.R_READY)
        next_w0 = inf.R_DATA;
    if(state == R1 && inf.R_VALID && inf.R_READY)
        next_w1 = inf.R_DATA;

    case(calc_ct)
        0: begin // basic check
            if(state == CALC)
            begin
                if(date_older)
                begin
                    next_warn_mg = Date_Warn;
                    next_complete_mg = 0;
                    if(act == Check_Valid_Date)
                    begin
                        next_w0[39:32] = date.M;
                        next_w0[7:0] = date.D;
                        write_dram_valid = 1;
                    end
                    else
                        calc_end_valid = 1;
                end
                else
                begin
                    next_w0[39:32] = date.M;
                    next_w0[7:0] = date.D;
                    if(act == Check_Valid_Date)
                    begin
                        next_warn_mg = No_Warn;
                        next_complete_mg = 1;
                        write_dram_valid = 1;
                    end
                    if((act == Make_and_Sell || act == Pay_Day) && no_staff)
                    begin
                        next_warn_mg = No_Staff_Warn;
                        next_complete_mg = 0;
                        write_dram_valid = 1;
                    end
                end
            end
        end
        1: begin
            next_l_div10 = shared_div_out;
            next_l_sq = shared_mult_out[13:0];
        end
        2: begin // pre addtion
            next_l_add10 = 10 + l_div10;
            if(act == Make_and_Sell)
            begin
                if(stock_warn)
                begin
                    next_warn_mg = Stock_Warn;
                    next_complete_mg = 0;
                    write_dram_valid = 1;
                end
                else
                begin
                    next_w0[63:52] = w0[63:52] - req_f;
                    next_w0[51:40] = w0[51:40] - req_b;
                    next_w0[31:20] = w0[31:20] - req_m;
                    next_w0[19:8] = w0[19:8] - req_s;
                    next_w1[63:52] = w1[63:52] - req_fr;
                end
            end
            else if(act == Hire_Staff)
            begin
                next_temp1 = w1[7:0] * 100; //level * 100
                next_temp2 = l_div10 * 200; // (level/10)*200
            end
            else if(act == Pay_Day)
            begin
                next_temp1 = w1[7:0] * 200; //level * 200
                next_temp2 = l_div10 * 1000; // (level/10)*1000
            end
        end
        3: begin
            if(act == Make_and_Sell)
            begin
                next_price_temp = shared_mult_out[12:0];
            end
            else if(act == Restock)
            begin
                next_cf_m = 15 * l_add10; // 15 * (10 + level/10)
                next_cb_m = 6 * l_add10; // 6 * (10 + level/10)
                next_cm_m = 25 * l_add10; // 25 * (10 + level/10)
                next_cs_m = l_add10; // (10 + level/10)
                next_cfr_m = 8 * l_add10; // 8 * (10 + level/10)
            end
            else if(act == Hire_Staff)
            begin
                next_unit_cost = 2000 + temp1 + temp2; // 2000 + level*100 + (level/10)*200
            end
            else // Pay_Day
            begin
                next_unit_cost = 20000 + temp1 + temp2; // 20000 + level*200 + (level/10)*1000
            end
        end
        4: begin
            if(pipe_ct == 0)
            begin
                if(act == Make_and_Sell)
                begin
                    next_temp1_div = shared_div_out; // (price*(10+level/10))/10
                    next_temp2_div = l_sq / 200; // (level^2)/200
                end
                else if(act == Restock)
                    next_cf_d = shared_div_out; // flour unit cost
                else 
                    next_req_cost = shared_mult_out; // unit_cost * staff_num or unit_cost * in_staff
            end
            else if(pipe_ct == 1)
            begin
                next_cb_d = cb_m; // butter unit cost
                next_cm_d = shared_div_out; // milk unit cost
                next_cs_d = cs_m; // sugar unit cost
                next_cfr_d = cfr_m; // fruit unit cost
            end
        end
        5: begin
            if(pipe_ct == 0)
            begin
                if(act == Make_and_Sell)
                    next_dessert_price = temp1_div + temp2_div; // price*(10+level/10)/10 + (level^2)/200
                else if(act == Restock)
                    next_cost_f = shared_mult_out; // flour restock cost
                else if(act == Hire_Staff)
                begin
                    next_real_staff = (w1[39:32] + in_staff > 100) ? (100 - w1[39:32]) : in_staff; // real staff number added
                end
                else if(act == Pay_Day)
                begin
                    if(w1[31:8] < req_cost) // not enough balance to pay
                    begin
                        next_warn_mg = Balance_Warn;
                        next_complete_mg = 0;
                        next_w1[7:0] = (w1[7:0] < 10) ? 0 : (w1[7:0] - 10); // level down by 1 
                        next_w1[39:32] = (w1[39:32] < 2) ? 1 : (w1[39:32] >> 1); // staff number halfed
                        next_w1[51:40] = 0; // sales reset to 0
                    end
                    else
                    begin
                        next_warn_mg = No_Warn;
                        next_complete_mg = 1;
                        next_w1[31:8] = w1[31:8] - req_cost; // balance reduced by required cost
                    end
                    write_dram_valid = 1;
                end
            end
            else if(pipe_ct == 1)
                next_cost_b = shared_mult_out; // butter restock cost
            else if(pipe_ct == 2)
                next_cost_m = shared_mult_out; // milk restock cost
            else if(pipe_ct == 3)
                next_cost_s = shared_mult_out; // sugar restock cost
            else if(pipe_ct == 4)
                next_cost_fr = shared_mult_out; // fruit restock cost
        end
        6: begin
            if(act == Make_and_Sell)
                next_total_rev = shared_mult_out; // dessert_price * scale
            else if(act == Restock)
                next_req_cost = cost_f + cost_b + cost_m + cost_s + cost_fr; 
            else if(act == Hire_Staff)
                next_real_cost = shared_mult_out; // unit_cost * real_staff
        end
        7: begin
            if(act == Make_and_Sell)
            begin
                if(w1[31:8] + total_rev > 16777215)
                    next_w1[31:8] = 16777215; // balance cap
                else
                    next_w1[31:8] = w1[31:8] + total_rev; // balance increased by total revenue

                if(w1[51:40] + scale > 4095)
                    next_w1[51:40] = 4095; // sales cap
                else
                    next_w1[51:40] = w1[51:40] + scale; // sales increased by scale
            end
            else if(act == Restock)
            begin
                next_real_res_f = (w0[63:52] + in_res[0] > 4095) ? (4095 - w0[63:52]) : in_res[0];
                next_real_res_b = (w0[51:40] + in_res[1] > 4095) ? (4095 - w0[51:40]) : in_res[1];
                next_real_res_m = (w0[31:20] + in_res[2] > 4095) ? (4095 - w0[31:20]) : in_res[2];
                next_real_res_s = (w0[19:8] + in_res[3] > 4095) ? (4095 - w0[19:8]) : in_res[3];
                next_real_res_fr = (w1[63:52] + in_res[4] > 4095) ? (4095 - w1[63:52]) : in_res[4];
            end
            else if(act == Hire_Staff)
            begin
                if(w1[31:8] < real_cost) // not enough balance to hire
                begin
                    next_warn_mg = Balance_Warn;
                    next_complete_mg = 0;
                end
                else
                begin
                    if(real_staff != in_staff) //staff exceeds max limit
                    begin
                        next_warn_mg = Staff_Warn;
                        next_complete_mg = 0;
                    end
                    else
                    begin
                        next_warn_mg = No_Warn;
                        next_complete_mg = 1;
                    end
                    next_w1[31:8] = w1[31:8] - real_cost; // balance reduced by required cost
                    next_w1[39:32] = w1[39:32] + real_staff; // staff number increased by real staff added
                end
                write_dram_valid = 1;
            end
        end
        8: begin // real restock cost
            if(act == Restock && pipe_ct == 0)
                next_cost_f = shared_mult_out; 
            else if(act == Restock && pipe_ct == 1)
                next_cost_b = shared_mult_out; 
            else if(act == Restock && pipe_ct == 2)
                next_cost_m = shared_mult_out; 
            else if(act == Restock && pipe_ct == 3)
                next_cost_s = shared_mult_out; 
            else if(act == Restock && pipe_ct == 4)
                next_cost_fr = shared_mult_out; 
        end
        9: begin
            if(act == Restock)
                next_real_cost = cost_f + cost_b + cost_m + cost_s + cost_fr;
        end
        10: begin
            if(act == Make_and_Sell)
            begin
                if(w1[7:0] < 100 && w1[51:40] >= max_sales)// upgrade level
                begin
                    next_w1[7:0] = w1[7:0] + 1;
                    next_w1[51:40] = w1[51:40] - max_sales; // sales reset by max_sales
                end
                next_warn_mg = No_Warn;
                next_complete_mg = 1;
            end
            else if(act == Restock)
            begin
                if(w1[31:8] < real_cost) // not enough balance to restock
                begin
                    next_warn_mg = Balance_Warn;
                    next_complete_mg = 0;
                end
                else
                begin
                    if(real_res_f != in_res[0] || real_res_b != in_res[1] || real_res_m != in_res[2] 
                        || real_res_s != in_res[3] || real_res_fr != in_res[4]) // restock amount exceeds max limit
                    begin
                        next_warn_mg = Restock_Warn;
                        next_complete_mg = 0;
                    end
                    else
                    begin
                        next_warn_mg = No_Warn;
                        next_complete_mg = 1;
                    end
                    next_w1[31:8] = w1[31:8] - real_cost; // balance - required cost
                    next_w0[63:52] = w0[63:52] + real_res_f; // flour stock + real restock amount
                    next_w0[51:40] = w0[51:40] + real_res_b; // butter stock + real restock amount
                    next_w0[31:20] = w0[31:20] + real_res_m; // milk stock + real restock amount
                    next_w0[19:8] = w0[19:8] + real_res_s; // sugar stock + real restock amount
                    next_w1[63:52] = w1[63:52] + real_res_fr; // fruit stock + real restock amount
                end
            end
            write_dram_valid = 1;
        end
    endcase
end

// output
assign inf.out_valid = out_valid;
assign inf.warn_msg = warn_msg;
assign inf.complete = complete;

always_comb
begin
    next_out_valid = 0;
    next_warn_msg = 0;
    next_complete = 0;

    if(state == B1 && inf.B_VALID && inf.B_READY)
    begin
        next_out_valid = 1;
        next_warn_msg = warn_mg;
        next_complete = complete_mg;
    end
    else if(state == CALC && calc_end_valid)
    begin
        next_out_valid = 1;
        next_warn_msg = next_warn_mg;
        next_complete = next_complete_mg;
    end
end


always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        for (int i = 0; i < 5; i = i + 1)
        begin
            in_res[i] <= 0;
        end
        state <= IDLE;
        act <= Make_and_Sell;
        dessert_type <= Cookie;
        mode <= Single;
        date <= 0;
        data_no <= 0;
        in_staff <= 0;
        res_ct <= 0;
        w0 <= 0; w1 <= 0;
        calc_ct <= 0; pipe_ct <= 0;
        warn_mg <= 0;
        complete_mg <= 0;
        l_div10 <= 0; l_add10 <= 0; l_sq <= 0;
        temp1 <= 0; temp2 <= 0; price_temp <= 0;
        cf_m <= 0; cb_m <= 0; cm_m <= 0; cs_m <= 0; cfr_m <= 0;
        unit_cost <= 0;
        temp1_div <= 0; temp2_div <= 0;
        cf_d <= 0; cb_d <= 0; cm_d <= 0; cs_d <= 0; cfr_d <= 0;
        dessert_price <= 0;
        cost_f <= 0; cost_b <= 0; cost_m <= 0; cost_s <= 0; cost_fr <= 0;
        real_staff <= 0;
        total_rev <= 0; real_cost <= 0;
        real_res_f <= 0; real_res_b <= 0; real_res_m <= 0; real_res_s <= 0; real_res_fr <= 0;
        out_valid <= 0;
        warn_msg <= 0;
        complete <= 0;
        req_cost <= 0;
    end
    else
    begin
        for (int i = 0; i < 5; i = i + 1)
        begin
            in_res[i] <= next_in_res[i];
        end
        state <= next_state;
        act <= next_act;
        dessert_type <= next_dessert_type;
        mode <= next_mode;
        date <= next_date;
        data_no <= next_data_no;
        in_staff <= next_in_staff;
        res_ct <= next_res_ct;
        w0 <= next_w0; w1 <= next_w1;
        calc_ct <= next_calc_ct; pipe_ct <= next_pipe_ct;
        warn_mg <= next_warn_mg;
        complete_mg <= next_complete_mg;
        l_div10 <= next_l_div10; l_add10 <= next_l_add10; l_sq <= next_l_sq;
        temp1 <= next_temp1; temp2 <= next_temp2; price_temp <= next_price_temp;
        cf_m <= next_cf_m; cb_m <= next_cb_m; cm_m <= next_cm_m; cs_m <= next_cs_m; cfr_m <= next_cfr_m;
        unit_cost <= next_unit_cost;
        temp1_div <= next_temp1_div; temp2_div <= next_temp2_div;
        cf_d <= next_cf_d; cb_d <= next_cb_d; cm_d <= next_cm_d; cs_d <= next_cs_d; cfr_d <= next_cfr_d;
        dessert_price <= next_dessert_price;
        cost_f <= next_cost_f; cost_b <= next_cost_b; cost_m <= next_cost_m; cost_s <= next_cost_s; cost_fr <= next_cost_fr;
        real_staff <= next_real_staff;
        total_rev <= next_total_rev; real_cost <= next_real_cost;
        real_res_f <= next_real_res_f; real_res_b <= next_real_res_b; real_res_m <= next_real_res_m; real_res_s <= next_real_res_s; real_res_fr <= next_real_res_fr;
        out_valid <= next_out_valid;
        warn_msg <= next_warn_msg;
        complete <= next_complete;
        req_cost <= next_req_cost;
    end
end

//================================================================
// Shared Divider (/10)
//================================================================
always_comb 
begin
    shared_div_a = 0; shared_div_out = 0;

    case(calc_ct)
        1: shared_div_a = w1[7:0]; // level
        4: begin
            if(pipe_ct == 0)
            begin
                shared_div_a = (act == Make_and_Sell) ? price_temp : cf_m; // price or flour unit cost
            end
            else if(pipe_ct == 1)
                shared_div_a = cm_m; // milk unit cost
        end
    endcase

    shared_div_out = shared_div_a / 10;
end

//================================================================
// Shared Multiplier
//================================================================
always_comb 
begin
    next_shared_mult_a = 0; next_shared_mult_b = 0; shared_mult_out = 0;

    case(calc_ct)
        0: begin
            next_shared_mult_a = w1[7:0]; // level
            next_shared_mult_b = w1[7:0]; // level
        end
        2: begin
            if(act == Make_and_Sell)
            begin
                next_shared_mult_a = base_price;// 16 bits
                next_shared_mult_b = next_l_add10;// 8 bits
            end
        end
        3: begin
            if(act == Hire_Staff)
            begin
                next_shared_mult_a = next_unit_cost;// 16 bits
                next_shared_mult_b = in_staff;// 8 bits
            end
            else if(act == Pay_Day)
            begin
                next_shared_mult_a = next_unit_cost;
                next_shared_mult_b = w1[39:32]; // current staff number
            end
        end
        4: begin
            if(act == Restock && pipe_ct == 1)
            begin
                next_shared_mult_a = in_res[0]; // flour restock amount
                next_shared_mult_b = cf_d; // flour unit cost
            end
        end
        5: begin
            if(pipe_ct == 0 && act == Restock)
            begin
                next_shared_mult_a = in_res[1]; // butter restock amount
                next_shared_mult_b = cb_d; // butter unit cost
            end
            else if(pipe_ct == 1 && act == Restock)
            begin
                next_shared_mult_a = in_res[2]; // milk restock amount
                next_shared_mult_b = cm_d; // milk unit cost
            end
            else if(pipe_ct == 2 && act == Restock)
            begin
                next_shared_mult_a = in_res[3]; // sugar restock amount
                next_shared_mult_b = cs_d; // sugar unit cost
            end
            else if(pipe_ct == 3 && act == Restock)
            begin
                next_shared_mult_a = in_res[4]; // fruit restock amount
                next_shared_mult_b = cfr_d; // fruit unit cost
            end

            if(act == Make_and_Sell)
            begin
                next_shared_mult_a = next_dessert_price;
                next_shared_mult_b = scale;
            end
            else if(act == Hire_Staff)
            begin
                next_shared_mult_a = unit_cost;
                next_shared_mult_b = next_real_staff;
            end
        end
        7: begin
            if(act == Restock)
            begin
                next_shared_mult_a = next_real_res_f;
                next_shared_mult_b = cf_d;
            end
        end
        8: begin
            if(pipe_ct == 0)//butter
            begin
                next_shared_mult_a = real_res_b;
                next_shared_mult_b = cb_d;
            end
            else if(pipe_ct == 1)//milk
            begin
                next_shared_mult_a = real_res_m;
                next_shared_mult_b = cm_d;
            end
            else if(pipe_ct == 2)//sugar
            begin
                next_shared_mult_a = real_res_s;
                next_shared_mult_b = cs_d;
            end
            else if(pipe_ct == 3)//fruit
            begin
                next_shared_mult_a = real_res_fr;
                next_shared_mult_b = cfr_d;
            end
        end
    endcase

    shared_mult_out = shared_mult_a * shared_mult_b;
end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        shared_mult_a <= 0; 
        shared_mult_b <= 0;
    end
    else
    begin
        shared_mult_a <= next_shared_mult_a; 
        shared_mult_b <= next_shared_mult_b;
    end
end

//================================================================
// AXI signals
//================================================================
assign inf.AR_VALID = ar_valid;
assign inf.AR_ADDR = ar_addr;
assign inf.R_READY = r_ready;
assign inf.AW_VALID = aw_valid;
assign inf.AW_ADDR = aw_addr;
assign inf.W_VALID = w_valid;
assign inf.W_DATA = w_data;
assign inf.B_READY = b_ready;

always_comb 
begin
    next_ar_valid = ar_valid; next_ar_addr = ar_addr;
    next_r_ready = r_ready;
    next_aw_valid = aw_valid; next_aw_addr = aw_addr;
    next_w_valid = w_valid; next_w_data = w_data;
    next_b_ready = b_ready;

    //read
    if(state == GET_IN && next_state == AR0)// read first
    begin
        next_ar_valid = 1;
        next_ar_addr = 17'h10000 + (next_data_no << 4);
    end
    if(state == AR0 && inf.AR_VALID && inf.AR_READY)
    begin
        next_r_ready = 1;

        next_ar_valid = 0;
        next_ar_addr = 0;
    end
    if(state == R0 && inf.R_VALID && inf.R_READY)// read second
    begin
        next_ar_valid = 1;
        next_ar_addr = 17'h10000 + (data_no << 4) + 8;

        next_r_ready = 0;
    end
    if(state == AR1 && inf.AR_VALID && inf.AR_READY)
    begin
        next_r_ready = 1;

        next_ar_valid = 0;
        next_ar_addr = 0;
    end
    if(state == R1 && inf.R_VALID && inf.R_READY)
    begin
        next_r_ready = 0;
        // after this, go to CALC
    end

    //write
    if(state == CALC && next_state == AW0)// write first
    begin
        next_aw_valid = 1;
        next_aw_addr = 17'h10000 + (data_no << 4);
    end
    if(state == AW0 && inf.AW_VALID && inf.AW_READY)
    begin
        next_w_valid = 1;
        next_w_data = w0;

        next_aw_valid = 0;
        next_aw_addr = 0;
    end
    if(state == W0 && inf.W_VALID && inf.W_READY)
    begin
        next_b_ready = 1;

        next_w_valid = 0;
        next_w_data = 0;
    end
    if(state == B0 && inf.B_VALID && inf.B_READY)// write second
    begin
        next_aw_valid = 1;
        next_aw_addr = 17'h10000 + (data_no << 4) + 8;

        next_b_ready = 0;
    end
    if(state == AW1 && inf.AW_VALID && inf.AW_READY)
    begin
        next_w_valid = 1;
        next_w_data = w1;

        next_aw_valid = 0;
        next_aw_addr = 0;
    end
    if(state == W1 && inf.W_VALID && inf.W_READY)
    begin
        next_b_ready = 1;

        next_w_valid = 0;
        next_w_data = 0;
    end
    if(state == B1 && inf.B_VALID && inf.B_READY)
    begin
        next_b_ready = 0;
    end

end

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        ar_valid <= 0; ar_addr <= 0;
        r_ready <= 0;
        aw_valid <= 0; aw_addr <= 0;
        w_valid <= 0; w_data <= 0;
        b_ready <= 0;
    end
    else
    begin
        ar_valid <= next_ar_valid; ar_addr <= next_ar_addr;
        r_ready <= next_r_ready;
        aw_valid <= next_aw_valid; aw_addr <= next_aw_addr;
        w_valid <= next_w_valid; w_data <= next_w_data;
        b_ready <= next_b_ready;
    end
end




endmodule
