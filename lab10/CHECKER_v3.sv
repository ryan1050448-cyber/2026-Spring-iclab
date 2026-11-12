/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2026 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2026)
Author : Chia-Hsin Lee
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module CHECKER(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Type_and_mode;
    Dessert_Type f_type;
    Order_Mode f_mode;
endclass
Type_and_mode fm_info = new();

//==============================================//
//                  Declaration                 //
//==============================================//
Action in_act, next_in_act;
Date in_date, next_in_date;
Data_No in_data_no, next_in_data_no;
Staff_t in_staff, next_in_staff;
Stock in_res [0:4], next_in_res [0:4], restock, next_restock;
Dessert_Type ff_type, next_ff_type;
Order_Mode ff_mode, next_ff_mode;
logic [2:0] res_ct, next_res_ct;
logic check_rst;
logic act_done_make, act_done_restock, act_done_hire, act_done_pay, act_done_date;
logic [2:0] valid_count;
logic date_f;

always_comb 
begin
    next_res_ct = res_ct;
    next_in_act = in_act;
    next_in_date = in_date;
    next_in_data_no = in_data_no;
    next_in_staff = in_staff;
    next_ff_type = ff_type;
    next_ff_mode = ff_mode;
    next_restock = restock;
    next_in_res[0] = in_res[0]; next_in_res[1] = in_res[1]; next_in_res[2] = in_res[2]; next_in_res[3] = in_res[3]; next_in_res[4] = in_res[4];

    fm_info.f_type = ff_type;
    fm_info.f_mode = ff_mode;

    if(inf.sel_action_valid)
        next_in_act = inf.D.d_act[0];
    if(inf.type_valid)
        next_ff_type = inf.D.d_type[0];
    if(inf.mode_valid)
        next_ff_mode = inf.D.d_mode[0];
    if(inf.date_valid)
        next_in_date = inf.D.d_date[0];
    if(inf.data_no_valid)
        next_in_data_no = inf.D.d_data_no[0];
    if(inf.staff_valid)
        next_in_staff = inf.D.d_staff[0];
    if(inf.restock_valid && res_ct < 5)
    begin
        next_in_res[res_ct] = inf.D.d_stock[0];
        next_restock = inf.D.d_stock[0];
        next_res_ct = res_ct + 1;
    end

    if(res_ct == 5) next_res_ct = 0;
end
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n) 
    begin
        res_ct <= 0;
        in_act <= Make_and_Sell;
        in_date <= 0;
        in_data_no <= 0;
        in_staff <= 0;
        in_res[0] <= 0; in_res[1] <= 0; in_res[2] <= 0; in_res[3] <= 0; in_res[4] <= 0;
        ff_type <= Cookie;
        ff_mode <= Single;
    end
    else 
    begin   
        res_ct <= next_res_ct;
        in_act <= next_in_act;
        in_date <= next_in_date;
        in_data_no <= next_in_data_no;
        in_staff <= next_in_staff;  
        in_res[0] <= next_in_res[0]; in_res[1] <= next_in_res[1]; in_res[2] <= next_in_res[2]; in_res[3] <= next_in_res[3]; in_res[4] <= next_in_res[4];
        ff_type <= next_ff_type;
        ff_mode <= next_ff_mode;
    end
        
end

//==============================================//
//                   COVERAGE                   //
//==============================================//

//1. Each case of Dessert_Type should be select at least 100 times.
covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least = 100;
    coverpoint fm_info.f_type {
        bins b_type [] = {Cookie, Bread, Fruit_Cake, Pudding, Macaron, Pancake, Brownie, Scone};
    }
endgroup
Spec1 cov_inst_1 = new();

//2. Each case of Order_mode should be select at least 100 times. 
covergroup Spec2 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 100;
    coverpoint fm_info.f_mode {
        bins b_mode [] = {Single, Family_Set, Party_Pack};
    }
endgroup
Spec2 cov_inst_2 = new();

//3. Each (spec1, spec2) combination should be selected at least 100 times. 
covergroup Spec3 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 100;
    cross fm_info.f_type, fm_info.f_mode;
endgroup
Spec3 cov_inst_3 = new();

//4.Output signal inf.warn_msg should be each at least 40 times.
covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 40;
    coverpoint inf.warn_msg {
        bins b_warn_msg [] = {No_Warn, Date_Warn, No_Staff_Warn, Stock_Warn, Balance_Warn, Restock_Warn, Staff_Warn};
    }
endgroup
Spec4 cov_inst_4 = new();

//5. Each action transition should be hit at least 200 times. 
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least = 200;
    coverpoint inf.D.d_act[0] {
        bins act_t [] = ([Make_and_Sell:Check_Valid_Date] => [Make_and_Sell:Check_Valid_Date]);
    }
endgroup
Spec5 cov_inst_5 = new();

//6.Create a covergroup for material of restock action , and each bin have to hit at least 5 time.
covergroup Spec6 @(posedge clk iff(inf.restock_valid));
    option.per_instance = 1;
    option.at_least = 5;
    coverpoint inf.D.d_stock[0] {
        option.auto_bin_max = 128;
        bins b_restock [128] = {[0:2047]};
        ignore_bins others = {[2048:4095]};
    }
endgroup
Spec6 cov_inst_6 = new();

//7.Action should be complete at least 1500 times.
covergroup Spec7 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 1500;
    coverpoint inf.complete {
         bins b_complete = {1'b1};
    }
endgroup
Spec7 cov_inst_7 = new();

//==============================================//
//                  ASSERTION                   //
//==============================================//

//1.All outputs signals should be zero after reset.
always_comb 
begin
    check_rst = 0;
    if(inf.out_valid === 1'b0 && inf.warn_msg === No_Warn && inf.complete === 1'b0 &&
        inf.AR_VALID === 1'b0 && inf.AR_ADDR === 1'b0 &&
        inf.R_READY === 1'b0 &&
        inf.AW_VALID === 1'b0 && inf.AW_ADDR === 1'b0 &&
        inf.W_VALID === 1'b0 && inf.W_DATA === 1'b0 &&
        inf.B_READY === 1'b0)
    begin
        check_rst = 1;
    end
end
always @(negedge inf.rst_n)
begin
    @(posedge inf.rst_n)
    CHECK_RST: assert(check_rst) 
    else $fatal(0, "Assertion 1 is violated");
end

//2.Latency should be less than 1000 cycles for each operation
always_comb 
begin
    act_done_make = 0; act_done_restock = 0; act_done_hire = 0; act_done_pay = 0; act_done_date = 0;
    if(inf.data_no_valid && in_act == Make_and_Sell) act_done_make = 1;
    if(inf.restock_valid && in_act == Restock && res_ct == 5) act_done_restock = 1;
    if(inf.data_no_valid && in_act == Hire_Staff) act_done_hire = 1;
    if(inf.data_no_valid && in_act == Pay_Day) act_done_pay = 1;
    if(inf.data_no_valid && in_act == Check_Valid_Date) act_done_date = 1;
end

assert_2_1: assert property(check_make)
else $fatal(0, "Assertion 2 is violated");

property check_make;
    @(negedge clk) act_done_make |-> ##[1:1000] inf.out_valid;
endproperty: check_make

assert_2_2: assert property(check_restock)
else $fatal(0, "Assertion 2 is violated");

property check_restock;
    @(negedge clk) act_done_restock |-> ##[1:1000] inf.out_valid;
endproperty: check_restock

assert_2_3: assert property(check_hire)
else $fatal(0, "Assertion 2 is violated");

property check_hire;
    @(negedge clk) act_done_hire |-> ##[1:1000] inf.out_valid;
endproperty: check_hire

assert_2_4: assert property(check_pay)
else $fatal(0, "Assertion 2 is violated");

property check_pay;
    @(negedge clk) act_done_pay |-> ##[1:1000] inf.out_valid;
endproperty: check_pay

assert_2_5: assert property(check_date)
else $fatal(0, "Assertion 2 is violated");

property check_date;
    @(negedge clk) act_done_date |-> ##[1:1000] inf.out_valid;
endproperty: check_date

//3.If action is completed (complete=1), warn_msg should be 3’b000 (No_Warn). 
assert_3: assert property(check_complete)
else $fatal(0, "Assertion 3 is violated");

property check_complete;
    @(negedge clk) (inf.out_valid && inf.complete) |-> (inf.warn_msg === No_Warn);
endproperty: check_complete

//4. Next input valid will be valid 1-4 cycles after previous input valid fall.
sequence s_make_sell;
    inf.type_valid ##[1:4] inf.mode_valid ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid;
endsequence

sequence s_restock;
    inf.date_valid ##[1:4] inf.data_no_valid ##[1:4] 
    inf.restock_valid ##[1:4] inf.restock_valid ##[1:4] inf.restock_valid ##[1:4] inf.restock_valid ##[1:4] inf.restock_valid;
endsequence

sequence s_hire;
    inf.staff_valid ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid;
endsequence

sequence s_pay;
    inf.date_valid ##[1:4] inf.data_no_valid;
endsequence

sequence s_date;
    inf.date_valid ##[1:4] inf.data_no_valid;
endsequence

assert_4_1: assert property(p_make_sell)
else $fatal(0, "Assertion 4 is violated");
property p_make_sell;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Make_and_Sell) |-> ##[1:4] s_make_sell;
endproperty : p_make_sell

assert_4_2: assert property(p_restock)
else $fatal(0, "Assertion 4 is violated");
property p_restock;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Restock) |-> ##[1:4] s_restock;
endproperty : p_restock

assert_4_3: assert property(p_hire)
else $fatal(0, "Assertion 4 is violated");
property p_hire;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Hire_Staff) |-> ##[1:4] s_hire;
endproperty : p_hire

assert_4_4: assert property(p_pay)
else $fatal(0, "Assertion 4 is violated");
property p_pay;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Pay_Day) |-> ##[1:4] s_pay;
endproperty : p_pay

assert_4_5: assert property(p_date)
else $fatal(0, "Assertion 4 is violated");
property p_date;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Check_Valid_Date) |-> ##[1:4] s_date;
endproperty : p_date

//5. All input valid signals won't overlap with each other.
assign valid_count = inf.sel_action_valid + inf.type_valid + inf.mode_valid + inf.date_valid + inf.data_no_valid + inf.staff_valid + inf.restock_valid;
always @(posedge clk) begin
    assert_5: assert(valid_count <= 1) 
    else $fatal(0, "Assertion 5 is violated");
end

//6. Out_valid can only be high for exactly one cycle.
assert_6: assert property( @(negedge clk) inf.out_valid |=> !inf.out_valid ) 
else $fatal(0, "Assertion 6 is violated");

//7. Next operation will be valid 1-4 cycles after out_valid fall.
assert_7: assert property(p_out_to_in)
else $fatal(0, "Assertion 7 is violated");
property p_out_to_in;
    @(posedge clk) (inf.out_valid) |-> ##[1:4] inf.sel_action_valid;
endproperty : p_out_to_in

//8. The input date from pattern should adhere to the real calendar.
always_comb 
begin
    if(inf.date_valid) 
    begin
        case(inf.D.d_date[0].M)
            1, 3, 5, 7, 8, 10, 12: date_f = (inf.D.d_date[0].D > 31 || inf.D.d_date[0].D < 1);
            2: date_f = (inf.D.d_date[0].D > 28 || inf.D.d_date[0].D < 1); // 2/29 is illegal cases
            4, 6, 9, 11: date_f = (inf.D.d_date[0].D > 30 || inf.D.d_date[0].D < 1);
            default: date_f = 1;
        endcase
    end 
    else
        date_f = 0;
end

assert_8: assert property( @(posedge clk) inf.date_valid |-> !date_f ) 
else $fatal(0, "Assertion 8 is violated");

//9. The AR_VALID signal should not overlap with the AW_VALID signal.  
assert_9_1: assert property( @(negedge clk) inf.AR_VALID |-> !inf.AW_VALID ) 
else $fatal(0, "Assertion 9 is violated");

assert_9_2: assert property( @(negedge clk) inf.AW_VALID |-> !inf.AR_VALID ) 
else $fatal(0, "Assertion 9 is violated");

//10. raise out_valid only when all input_valid signals are transmitted and your design has done current input operation
sequence seq_input_phase_make;
    inf.sel_action_valid && (inf.D.d_act[0] === Make_and_Sell) ##[1:4] s_make_sell;
endsequence

sequence seq_input_phase_restock;
    inf.sel_action_valid && (inf.D.d_act[0] === Restock) ##[1:4] s_restock;
endsequence

sequence seq_input_phase_hire;
    inf.sel_action_valid && (inf.D.d_act[0] === Hire_Staff) ##[1:4] s_hire;
endsequence

sequence seq_input_phase_pay;
    inf.sel_action_valid && (inf.D.d_act[0] === Pay_Day) ##[1:4] s_pay;
endsequence

sequence seq_input_phase_date;
    inf.sel_action_valid && (inf.D.d_act[0] === Check_Valid_Date) ##[1:4] s_date;
endsequence

assert_10_make: assert property ( @(negedge clk) (inf.sel_action_valid && (inf.D.d_act[0] === Make_and_Sell)) |-> (!inf.out_valid throughout seq_input_phase_make ) )
    else $fatal(0, "Assertion 10 violated: out_valid occurred during Make_and_Sell input phase");

assert_10_restock: assert property ( @(negedge clk) (inf.sel_action_valid && (inf.D.d_act[0] === Restock)) |-> (!inf.out_valid throughout seq_input_phase_restock ) )
    else $fatal(0, "Assertion 10 violated: out_valid occurred during Restock input phase");

assert_10_hire: assert property ( @(negedge clk) (inf.sel_action_valid && (inf.D.d_act[0] === Hire_Staff)) |-> (!inf.out_valid throughout seq_input_phase_hire ) )
    else $fatal(0, "Assertion 10 violated: out_valid occurred during Hire_Staff input phase");

assert_10_pay: assert property ( @(negedge clk) (inf.sel_action_valid && (inf.D.d_act[0] === Pay_Day)) |-> (!inf.out_valid throughout seq_input_phase_pay ) )
    else $fatal(0, "Assertion 10 violated: out_valid occurred during Pay_Day input phase");

assert_10_date: assert property ( @(negedge clk) (inf.sel_action_valid && (inf.D.d_act[0] === Check_Valid_Date)) |-> (!inf.out_valid throughout seq_input_phase_date ) )
    else $fatal(0, "Assertion 10 violated: out_valid occurred during Check_Valid_Date input phase");

//11. input not exceed maximum value
assert_11_month: assert property( @(posedge clk) inf.date_valid |-> (inf.D.d_date[0].M >= 1 && inf.D.d_date[0].M <= 12) ) 
else $fatal(0, "Assertion 11 is violated: Month value out of range");

assert_11_day: assert property( @(posedge clk) inf.date_valid |-> (inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ) 
else $fatal(0, "Assertion 11 is violated: Day value out of range");

assert_11_staff: assert property( @(posedge clk) inf.staff_valid |-> (inf.D.d_staff[0] >= 0 && inf.D.d_staff[0] <= 100) ) 
else $fatal(0, "Assertion 11 is violated: Staff value out of range");

assert_11_data_no: assert property( @(posedge clk) inf.data_no_valid |-> (inf.D.d_data_no[0] >= 0 && inf.D.d_data_no[0] <= 127) ) 
else $fatal(0, "Assertion 11 is violated: Data_No value out of range");

assert_11_mode: assert property( @(posedge clk) inf.mode_valid |-> (inf.D.d_mode[0] == 2'b00 || inf.D.d_mode[0] == 2'b10 || inf.D.d_mode[0] == 2'b11) ) 
else $fatal(0, "Assertion 11 is violated: Mode value out of range");

assert_11_act: assert property( @(posedge clk) inf.sel_action_valid |-> (inf.D.d_act[0] >= 0 && inf.D.d_act[0] <= 4) ) 
else $fatal(0, "Assertion 11 is violated: Action value out of range");

assert_11_warn_msg: assert property( @(negedge clk) inf.out_valid |-> (inf.warn_msg >= 0 && inf.warn_msg <= 6) ) 
else $fatal(0, "Assertion 11 is violated: Warn_Msg value out of range");

assert_11_restock_range: assert property ( @(posedge clk) inf.restock_valid |-> (inf.D.d_stock[0] >= 0 && inf.D.d_stock[0] <= 2047) )
else $fatal(0, "Assertion 11 is violated: Restock value out of range (0-2047)");

//================================================================
// AXI Protocol Monitors 
//================================================================
logic [16:0] tmp_addr;
logic [63:0] tmp_data;
logic [1:0]  tmp_resp;
integer cnt, count_r_valid, count_w_ready;
logic wait_r, wait_w;
integer pending_ar = 0, pending_aw = 0;
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

endmodule