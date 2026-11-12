module DM(
    clk,
    rst_n,
    i_valid,
    i_iter,
    i_mode,
    i_data,
    i_weight,
    o_valid,
    o_data
);

input       clk, rst_n, i_valid;
input       [7:0] i_data;
input       [2:0] i_iter;
input       [1:0] i_mode;
input       [3:0] i_weight;
output reg  o_valid;
output reg  [7:0] o_data;

//==================================================================
// SRAM
//==================================================================
wire SRAM_img_512X128_CLK, SRAM_512X128_CLK, SRAM_cal_512X128_CLK, SRAM_96X64_CLK; // SRAM Clock
wire SRAM_img_512X128_CS, SRAM_512X128_CS, SRAM_cal_512X128_CS, SRAM_96X64_CS;  // SRAM Chip Select
wire SRAM_img_512X128_OE, SRAM_512X128_OE, SRAM_cal_512X128_OE, SRAM_96X64_OE;  // SRAM Output Enable
wire SRAM_img_512X128_WE, SRAM_512X128_WE, SRAM_cal_512X128_WE, SRAM_96X64_WE;  // SRAM Write Enable
wire [8:0]  SRAM_512X128_A, SRAM_img_512X128_A, SRAM_cal_512X128_A;   // SRAM address
wire [6:0]  SRAM_96X64_A;   // SRAM address
wire [127:0]  SRAM_512X128_DI, SRAM_img_512X128_DI, SRAM_cal_512X128_DI;  // SRAM Data In
wire [127:0]  SRAM_512X128_DO, SRAM_img_512X128_DO, SRAM_cal_512X128_DO;  // SRAM Data Out
wire [63:0]  SRAM_96X64_DI, SRAM_96X64_DO;  // SRAM Data In and Out
/*
//debg
wire SRAM_debg_512X128_CLK, SRAM_debg_512X128_CS, SRAM_debg_512X128_OE, SRAM_debg_512X128_WE;
wire [8:0] SRAM_debg_512X128_A;
wire [127:0] SRAM_debg_512X128_DI, SRAM_debg_512X128_DO;*/
/*
SRAM_debg_512_128  SRAM_debg_512_128_inst  (
    .CLK    (SRAM_debg_512X128_CLK ),
    .CS     (SRAM_debg_512X128_CS  ),
    .OE     (SRAM_debg_512X128_OE  ),
    .WEB    (!SRAM_debg_512X128_WE ),
    .A      (SRAM_debg_512X128_A   ),
    .DI     (SRAM_debg_512X128_DI  ),
    .DO     (SRAM_debg_512X128_DO  )
);*/

SRAM_512_128  SRAM_512_128_inst  (
    .CLK    (SRAM_512X128_CLK ),
    .CS     (SRAM_512X128_CS  ),
    .OE     (SRAM_512X128_OE  ),
    .WEB    (!SRAM_512X128_WE ),
    .A      (SRAM_512X128_A   ),
    .DI     (SRAM_512X128_DI  ),
    .DO     (SRAM_512X128_DO  )
);
SRAM_cal_512_128  SRAM_cal_512_128_inst  (
    .CLK    (SRAM_cal_512X128_CLK ),
    .CS     (SRAM_cal_512X128_CS  ),
    .OE     (SRAM_cal_512X128_OE  ),
    .WEB    (!SRAM_cal_512X128_WE ),
    .A      (SRAM_cal_512X128_A   ),
    .DI     (SRAM_cal_512X128_DI  ),
    .DO     (SRAM_cal_512X128_DO  )
);
SRAM_img_512_128  SRAM_img_512_128_inst  (
    .CLK    (SRAM_img_512X128_CLK ),
    .CS     (SRAM_img_512X128_CS  ),
    .OE     (SRAM_img_512X128_OE  ),
    .WEB    (!SRAM_img_512X128_WE ),
    .A      (SRAM_img_512X128_A   ),
    .DI     (SRAM_img_512X128_DI  ),
    .DO     (SRAM_img_512X128_DO  )
);
SRAM_96_64  SRAM_96_64_inst  (
    .CLK    (SRAM_96X64_CLK ),
    .CS     (SRAM_96X64_CS  ),
    .OE     (SRAM_96X64_OE  ),
    .WEB    (!SRAM_96X64_WE ),
    .A      (SRAM_96X64_A   ),
    .DI     (SRAM_96X64_DI  ),
    .DO     (SRAM_96X64_DO  )
);

//==================================================================
// Declaration
//==================================================================
reg we_img, next_we_img, we_128, next_we_128, we_cal_128, next_we_cal_128, we64, next_we64;
reg [8:0] ad_128, next_ad_128, ad_cal_128, next_ad_cal_128, ad_img, next_ad_img;
reg [6:0] ad_64, next_ad_64;
reg [127:0] di128_sram, next_di128_sram, di_img_sram, next_di_img_sram, di_cal_128_sram, next_di_cal_128_sram;
reg [63:0] di64_sram, next_di64_sram;
reg [12:0] in_count, next_in_count;
reg [2:0] iter_count, next_iter_count, iter, next_iter;
reg [1:0] mode, next_mode;
reg [7:0] in_data, next_in_data;
reg wt_read, next_wt_read;
reg [7:0] rd_wt_ct, next_rd_wt_ct;
//reg [7:0] temp [0:15], next_temp [0:15];
reg [3:0] state, next_state;
reg [10:0] conv_ct, next_conv_ct;
reg [12:0] mm_ct, next_mm_ct;
reg [3:0] wt_temp [0:51], next_wt_temp [0:51];
reg [7:0] img_temp [0:15], next_img_temp [0:15];
reg [7:0] group_idx, offset;
reg mac_reset, sign_valid, t_valid;
reg [2:0] mm_mode;
reg [127:0] a_select, b_select;
reg [6:0] round, next_round;
reg [7:0] ffn_temp [0:35], next_ffn_temp [0:35];
reg [95:0] s96 [0:1], next_s96 [0:1];
reg [10:0] tmp_ad;
reg [9:0] r, c, ch;
reg [63:0] conv2k_tmp, next_conv2k_tmp;
reg [127:0] sram_128_do, next_sram_128_do, sram_cal_128_do, next_sram_cal_128_do, sram_img_128_do, next_sram_img_128_do;
reg [63:0] sram_64_do, next_sram_64_do;
reg [1:0] k_row;
reg [7:0] tmp8, next_tmp8;
reg [127:0] img_tmp128;
reg next_o_valid, i_valid_buf, next_i_valid_buf;
reg [7:0] next_o_data;
wire [127:0] out_data;

//debg
/*reg we_debg, next_we_debg;
reg [8:0] ad_debg, next_ad_debg;
reg [127:0] di_debg, next_di_debg;*/

parameter IDLE = 0;
parameter CONV1 = 1;
parameter QKV = 2;
parameter QKT = 3;
parameter V = 4;
parameter FFN = 5;
parameter CONV2 = 6;
parameter INPOL_D = 7;
parameter INPOL = 8;
parameter SUB = 9;
parameter WAIT = 10;
parameter OUT = 11;

integer i, j;
//==================================================================
// SRAM control signal
//==================================================================
assign SRAM_512X128_CLK   = clk;
assign SRAM_512X128_CS    = 1'b1;
assign SRAM_512X128_OE    = 1'b1;
assign SRAM_512X128_WE    = we_128;
assign SRAM_512X128_A     = ad_128;
assign SRAM_512X128_DI    = di128_sram;

assign SRAM_cal_512X128_CLK   = clk;
assign SRAM_cal_512X128_CS    = 1'b1;
assign SRAM_cal_512X128_OE    = 1'b1;
assign SRAM_cal_512X128_WE    = we_cal_128;
assign SRAM_cal_512X128_A     = ad_cal_128;
assign SRAM_cal_512X128_DI    = di_cal_128_sram;

assign SRAM_img_512X128_CLK   = clk;
assign SRAM_img_512X128_CS    = 1'b1;
assign SRAM_img_512X128_OE    = 1'b1;
assign SRAM_img_512X128_WE    = we_img;
assign SRAM_img_512X128_A     = ad_img;
assign SRAM_img_512X128_DI    = di_img_sram;

assign SRAM_96X64_CLK   = clk;
assign SRAM_96X64_CS    = 1'b1;
assign SRAM_96X64_OE    = 1'b1;
assign SRAM_96X64_WE    = we64;
assign SRAM_96X64_A     = ad_64;
assign SRAM_96X64_DI    = di64_sram;
/*
assign SRAM_debg_512X128_CLK   = clk;
assign SRAM_debg_512X128_CS    = 1'b1;
assign SRAM_debg_512X128_OE    = 1'b1;
assign SRAM_debg_512X128_WE    = we_debg;
assign SRAM_debg_512X128_A     = ad_debg;
assign SRAM_debg_512X128_DI    = di_debg;*/

//==================================================================
// Design
//==================================================================
//sram control signal
always @(*)
begin
    next_we_img = 0;
    next_we_128 = 0;
    next_we_cal_128 = 0;
    next_we64 = 0;
    next_ad_img = ad_img;
    next_ad_128 = ad_128;
    next_ad_cal_128 = ad_cal_128;
    next_ad_64 = ad_64;
    next_di_img_sram = 0;
    next_di128_sram = 0;
    next_di_cal_128_sram = 0;
    next_di64_sram = 0;
    group_idx = 0;
    offset = 0;
    tmp_ad = 0;
    r = 0;
    c = 0;
    ch = 0;

    if(i_valid && wt_read == 0 && in_count <= 144)//write down sampling weight
    begin
        case(in_count)
            30: begin //k11, k21, k31, k41
                next_we64 = 1;
                next_ad_64 = 0;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            33: begin //k12, k22, k32, k42
                next_we64 = 1;
                next_ad_64 = 1;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            36: begin //k13, k23, k33, k43
                next_we64 = 1;
                next_ad_64 = 2;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            66: begin //k51, k61, k71, k81
                next_we64 = 1;
                next_ad_64 = 3;
                //next_di64_sram = {{wt_temp[22:24]}, {4'd0}, {wt_temp[31:33]}, {4'd0}, {wt_temp[40:42]}, {4'd0}, {wt_temp[49:51]}, {4'd0}};
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            69: begin //k52, k62, k72, k82
                next_we64 = 1;
                next_ad_64 = 4;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            72: begin //k53, k63, k73, k83
                next_we64 = 1;
                next_ad_64 = 5; 
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            102: begin //k91, k101, k111, k121
                next_we64 = 1;
                next_ad_64 = 6;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            105: begin //k92, k102, k112, k122
                next_we64 = 1;
                next_ad_64 = 7;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            108: begin //k93, k103, k113, k123
                next_we64 = 1;
                next_ad_64 = 8;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            138: begin //k131, k141, k151, k161
                next_we64 = 1;
                next_ad_64 = 9;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            141: begin //k132, k142, k152, k162
                next_we64 = 1;
                next_ad_64 = 10;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
            144: begin //k133, k143, k153, k163
                next_we64 = 1;
                next_ad_64 = 11;
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
        endcase
    end
    if(i_valid && wt_read == 0 && (in_count >= 145 && in_count <= 1168) && (in_count % 4 == 0))//write q,k,v, ffn
    begin
        case(((in_count - 144) >> 2) % 16)
            13, 14, 15, 0: begin
                next_we64 = 1;
                next_ad_64 = ad_64 + 1;
                //next_di64_sram = {{wt_temp[0:3]}, {wt_temp[16:19]}, {wt_temp[32:35]}, {wt_temp[48:51]}};
                next_di64_sram = {wt_temp[0], wt_temp[1], wt_temp[2], wt_temp[3], wt_temp[16], wt_temp[17], wt_temp[18], wt_temp[19],
                                wt_temp[32], wt_temp[33], wt_temp[34], wt_temp[35], wt_temp[48], wt_temp[49], wt_temp[50], wt_temp[51]};
            end
        endcase
    end
    if(i_valid_buf && wt_read == 0 && (in_count >= 1168 && in_count <= 1312))//write up sampling weight
    begin
        case(in_count - 1168)
            30, 33, 36, 66, 69, 72, 102, 105, 108, 138, 141, 144: 
            begin //k11, k21, k31, k41
                next_we64 = 1;
                next_ad_64 = ad_64 + 1;
                //next_di64_sram = {{wt_temp[22:24]}, {4'd0}, {wt_temp[31:33]}, {4'd0}, {wt_temp[40:42]}, {4'd0}, {wt_temp[49:51]}, {4'd0}};
                next_di64_sram = {wt_temp[22], wt_temp[23], wt_temp[24], 4'd0, wt_temp[31], wt_temp[32], wt_temp[33], 4'd0, 
                                wt_temp[40], wt_temp[41], wt_temp[42], 4'd0, wt_temp[49], wt_temp[50], wt_temp[51], 4'd0};
            end
        endcase
    end

    if(i_valid_buf && wt_read == 1 && (in_count >= 16 && in_count <= 4096))//write image 16-4096
    begin
        if(in_count % 16 == 0 && (in_count >> 4) >= 1)//save 128 bit, start from 16
        begin
            next_we_img = 1;
            next_ad_img = (in_count >> 4) - 1;
            for (i = 0; i < 16; i = i + 1)
            begin
                //next_di_img_sram[(127-i*8) : (120-i*8)] = temp[i];
                next_di_img_sram[120-i*8 +: 8] = img_temp[i];
            end
        end
    end
    if(i_valid && wt_read == 1 && in_count < 3968 && ((in_count - 1) / 64) % 4 != 2)//write image preprocess
    begin
        if(in_count == 1)//I11, I21, I31, I41
        begin
            next_we_128 = 1;
            next_ad_128 = 0;
            next_di128_sram = 128'd0;
        end
        case(in_count)
            2, 3, 4: begin //I51, I61, I71, I81, I91, I101, I111, I121, I131, I141, I151, I161
                next_we_128 = 1;
                next_ad_128 = ad_128 + 1;
                next_di128_sram = 128'd0;
            end
        endcase
        case(in_count % 64)
            14: begin 
                next_we_128 = 1;
                next_ad_128 = ad_128 + 1;
                //next_di128_sram = {{8'd0}, {img_temp[1:2]}, {8'd0}, {img_temp[4:6]}, {8'd0}, {img_temp[8:10]}, {8'd0}, {img_temp[12:14]}, {8'd0}};
                next_di128_sram = {8'd0, img_temp[2], img_temp[3], 8'd0, img_temp[5], img_temp[6], img_temp[7], 8'd0, 
                                img_temp[9], img_temp[10], img_temp[11], 8'd0, img_temp[13], img_temp[14], img_temp[15], 8'd0};
            end
            30, 46, 62: begin 
                next_we_128 = 1;
                next_ad_128 = ad_128 + 1;
                //next_di128_sram = {{img_temp[0:2]}, {8'd0}, {img_temp[4:6]}, {8'd0}, {img_temp[8:10]}, {8'd0}, {img_temp[12:14]}, {8'd0}};
                next_di128_sram = {img_temp[1], img_temp[2], img_temp[3], 8'd0, img_temp[5], img_temp[6], img_temp[7], 8'd0, 
                                img_temp[9], img_temp[10], img_temp[11], 8'd0, img_temp[13], img_temp[14], img_temp[15], 8'd0};
            end
        endcase
    end
    //conv1
    if(state == CONV1 && conv_ct >= 0 && conv_ct <= 767)//read weight and image for conv
    begin
        //image process
        next_we_128 = 0;
        group_idx = conv_ct / 12;
        offset = (group_idx >> 2) * 12 + (group_idx % 4);
        next_ad_128 = ((conv_ct % 3) << 2) + offset;
        //kernel
        next_we64 = 0;
        next_ad_64 = conv_ct % 12;
    end
    if(state == CONV1 && conv_ct >= 9 && conv_ct % 3 == 0)//write conv result:9,12,15,18,...,771,774
    begin
        next_we_img = 1;
        next_ad_img = (conv_ct - 9) / 3 + 256;
        next_di_img_sram = out_data;
    end
    //QKV
    if(state == QKV && mm_ct < 3072)//read q,k,v weight and A
    begin
        //A
        next_we_img = 0;
        //next_ad_cal_128 = (mm_ct / 16) * 4 + (mm_ct % 4);
        //next_ad_img = {{1'd0}, {mm_ct[9:4]}, {mm_ct[1:0]}} + 256;
        next_ad_img = {1'b0, mm_ct[9:4], mm_ct[1:0]} + 256;
        //q
        if(mm_ct >= 0 && mm_ct < 1024)//0-1023
        begin
            next_we64 = 0;
            //0,4,8,12, 1,5,9,13, 2,6,10,14, 3,7,11,15, 0,4,8,12,...
            //next_ad_64 = {{5'd0}, {mm_ct[1:0]}, {mm_ct[3:2]}} + 12;
            next_ad_64 = {5'd0, mm_ct[1:0], mm_ct[3:2]} + 12;
        end
        //k
        else if(mm_ct >= 1024 && mm_ct < 2048)//1024-2047
        begin
            next_we64 = 0;
            //next_ad_64 = {{5'd0}, {mm_ct[1:0]}, {mm_ct[3:2]}} + 28;
            next_ad_64 = {5'd0, mm_ct[1:0], mm_ct[3:2]} + 28;
        end
        //v
        else if(mm_ct >= 2048 && mm_ct < 3072)//2048-3071
        begin
            next_we64 = 0;
            //next_ad_64 = {{5'd0}, {mm_ct[1:0]}, {mm_ct[3:2]}} + 44;
            next_ad_64 = {5'd0, mm_ct[1:0], mm_ct[3:2]} + 44;
        end
    end
    if(state == QKV && mm_ct >= 10 && mm_ct <= 3078)//write Q,K,V
    begin
        if(mm_ct >= 10 && mm_ct <= 1030 && (mm_ct - 10) % 4 == 0)//10-1030 Q
        begin
            next_we_cal_128 = 1;
            next_ad_cal_128 = (mm_ct - 10) >> 2;
            next_di_cal_128_sram = out_data;
        end
        else if(mm_ct >= 1034 && mm_ct <= 2054 && (mm_ct - 10) % 4 == 0)//1034-2054 K
        begin
            next_we_128 = 1;
            next_ad_128 = ((mm_ct - 1034) >> 2) + 256;
            next_di128_sram = out_data;
        end
        else if(mm_ct >= 2058 && mm_ct <= 3078 && (mm_ct - 10) % 4 == 0)//2058-3078 V
        begin
            next_we_cal_128 = 1;
            next_ad_cal_128 = ((mm_ct - 2058) >> 2) + 256;
            next_di_cal_128_sram = out_data;
        end
    end
    //qkt
    if(state == QKT && mm_ct < 256)//read Q,K
    begin
        //Q
        next_we_cal_128 = 0;
        next_ad_cal_128 = (mm_ct % 4) + (round << 2);
        //K
        next_we_128 = 0;
        next_ad_128 = mm_ct + 256;
    end
    if(state == QKT && mm_ct >= 10 && (mm_ct - 10) % 4 == 0)//write QK result 10-262
    begin
        next_we_img = 1;
        next_ad_img = ((mm_ct - 10) >> 2) + 256;
        next_di_img_sram = out_data;
    end
    //v
    if(state == V && mm_ct < 256)//read QKt, V
    begin
        //QKt
        next_we_img = 0;
        next_ad_img = mm_ct % 64 + 256;
        //V
        next_we_cal_128 = 0;
        next_ad_cal_128 = {1'd0, mm_ct[5:0], mm_ct[7:6]} + 256;
    end
    if(state == V)//write QKt*V result
    begin
        case(mm_ct)
            70: begin
                next_we_128 = 1;
                next_ad_128 = 0 + round * 4;
                next_di128_sram = out_data;
            end
            134, 198, 262: begin
                next_we_128 = 1;
                next_ad_128 = ad_128 + 1;
                next_di128_sram = out_data;
            end
        endcase
    end
    //FFN
    if(state == FFN && mm_ct < 1024)//read QKV result and FFN weight
    begin
        //QKV result
        next_we_128 = 0;
        next_ad_128 = mm_ct % 256;
        //FFN weight
        next_we64 = 0;
        next_ad_64 = ((mm_ct % 4) << 2) + (mm_ct / 256) + 60;
    end
    if(state == FFN && mm_ct >= 16 && mm_ct <= 1037 && (mm_ct % 4 == 0 || mm_ct % 4 == 1))//write T
    begin
        next_we_cal_128 = 1;
        tmp_ad = mm_ct - 16;
        next_ad_cal_128 = {tmp_ad[7:2], tmp_ad[9:8], tmp_ad[0]};//0-255
        next_di_cal_128_sram = s96[0];
    end
    //conv2
    if(state == CONV2 && mm_ct >= 0 && mm_ct <= 3071)//read T and image for conv
    begin
        //T
        r = (mm_ct % 3) - 1 + (mm_ct / 192);
        c = (mm_ct / 48) % 4;
        ch = (mm_ct / 3) % 16;
        if(mm_ct % 3 == 0 && mm_ct / 192 == 0)//r=-1 no read
        begin
            next_we_cal_128 = 0;
            next_ad_cal_128 = 0;
        end
        else if(r == 16)//r=16 no read
        begin
            next_we_cal_128 = 0;
            next_ad_cal_128 = 0;
        end
        else
        begin
            next_we_cal_128 = 0;
            next_ad_cal_128 = 32 * r + 8 * c + (ch/2);
        end
        //kernel
        next_we64 = 0;
        next_ad_64 = (mm_ct % 3) + 3 * (mm_ct / 12 % 4) + 76;
    end
    if(state == CONV2 && mm_ct >= 55 && mm_ct <= 3127 && (mm_ct - 55) % 48 == 0)//write conv2 result
    begin
        if((mm_ct - 55) % 192 == 144)
        begin
            next_we_img = 1;
            next_ad_img = ((mm_ct - 55) / 192) + 256;
            //next_di_img_sram = img_temp[0:15];
            for (i = 0; i < 16; i = i + 1)
            begin
                //next_di_img_sram[(127-i*8) : (120-i*8)] = img_temp[i];
                next_di_img_sram[120-i*8 +: 8] = img_temp[i];
            end
        end 
    end
    //INPOL_D
    if(state == INPOL_D && mm_ct < 32)//read conv2 result
    begin
        if(mode == 1)
        begin
            next_we_img = 0;
            next_ad_img = (mm_ct >> 1) + 256;
        end
        else if(mode == 2)
        begin
            if(mm_ct <= 29)//0-29
            begin
                next_we_img = 0;
                next_ad_img = (mm_ct / 2) + !(mm_ct % 2) + 256;
            end
            else if(mm_ct == 30 || mm_ct == 31)//30,31
            begin
                next_we_img = 0;
                next_ad_img = (mm_ct / 2) + !(mm_ct % 2) + 256 - 1;
            end
        end
        
    end
    if(state == INPOL_D && mm_ct >= 2 && mm_ct <= 38 && mm_ct % 2 == 0)//write inpol d result
    begin
        next_we_cal_128 = 1;
        next_ad_cal_128 = (mm_ct - 8) >> 1;
        next_di_cal_128_sram = out_data;
    end
    //INPOL
    if(state == INPOL && mm_ct < 512)//read conv2 result and inpol d result
    begin
        if(mm_ct % 2 == 0)//even
        begin
            next_we_img = 0;
            next_ad_img = (mm_ct / 32) + 256;
        end
        else//odd
        begin
            next_we_cal_128 = 0;
            next_ad_cal_128 = mm_ct / 32;
        end
    end
    if(state == INPOL && mm_ct >= 8 && mm_ct <= 520 && (mm_ct - 8) % 2 == 0)//write inpol result
    begin
        next_we_128 = 1;
        next_ad_128 = (mm_ct - 8) >> 1;
        next_di128_sram = out_data;
    end
    //SUB
    if(state == SUB && mm_ct < 512)//read image and inpol result
    begin
        if(mm_ct % 2 == 0)//even
        begin
            next_we_img = 0;
            next_ad_img = mm_ct / 2;
        end
        else
        begin
            next_we_128 = 0;
            next_ad_128 = mm_ct / 2;
        end
    end
    if(state == SUB && mm_ct >= 8 && mm_ct <= 518 && (mm_ct - 8) % 2 == 0)//write sub result
    begin
        next_we_cal_128 = 1;
        next_ad_cal_128 = (mm_ct - 8) >> 1;
        next_di_cal_128_sram = out_data;
    end
    //wait
    if(state == WAIT && mm_ct < 256)//read sub result
    begin
        next_we_cal_128 = 0;
        next_ad_cal_128 = mm_ct;
    end
    if(state == WAIT && mm_ct >= 3 && mm_ct <= 251 && ((mm_ct - 3) >> 2) % 4 != 2)//write output
    begin
        next_we_128 = 1;
        next_ad_128 = 12 * ((mm_ct + 1) / 16)  + (mm_ct + 1) % 16;

        next_di128_sram = img_tmp128;
    end
    if(state == WAIT && mm_ct >= 3 && mm_ct <= 258)//write image
    begin
        next_we_img = 1;
        next_ad_img = mm_ct - 3;
        next_di_img_sram = sram_cal_128_do;
    end

    if(state == WAIT && mm_ct >= 252 && mm_ct <= 255)//last 256,257,258,259 write output
    begin
        case(mm_ct)
            252: begin//I11, I21, I31, I41
                next_we_128 = 1;
                next_ad_128 = 0;
                next_di128_sram = 0;
            end
            253: begin//I51, I61, I71, I81
                next_we_128 = 1;
                next_ad_128 = 1;
                next_di128_sram = 0;
            end
            254: begin//I91, I101, I111, I121
                next_we_128 = 1;
                next_ad_128 = 2;
                next_di128_sram = 0;
            end
            255: begin//I131, I141, I151, I161
                next_we_128 = 1;
                next_ad_128 = 3;
                next_di128_sram = 0;
            end
        endcase
    end
    //out
    if(state == OUT && mm_ct < 4096)//read output
    begin
        next_we_cal_128 = 0;
        next_ad_cal_128 = mm_ct / 16;
    end

    /*next_we_debg = 0;
    next_ad_debg = ad_debg;
    next_di_debg = 0;
    //debg
    if(state == FFN && mm_ct >= 10 && mm_ct <= 1030 && (mm_ct - 10) % 4 == 0)//write T
    begin
        next_we_debg = 1;
        next_ad_debg = (((mm_ct - 10) / 4) * 4) % 255;
        if((mm_ct - 10) / 4 == 255)
            next_ad_debg = 255;
        next_di_debg = out_data;
    end*/

end
//input
always @(*)
begin
    next_in_count = in_count;
    next_iter_count = iter_count;
    next_mode = mode;
    next_in_data = in_data;
    next_wt_read = wt_read;
    next_iter = iter;
    next_i_valid_buf = 0;

    if(i_valid)
    begin
        next_i_valid_buf = 1;
    end
    

    if(i_valid && wt_read == 0)//read weight
        next_in_count = in_count + 1;
    if(in_count == 1312)//read weight done
    begin
        next_wt_read = 1;
        next_in_count = 0;
    end

    if(i_valid && wt_read == 1 && in_count == 0)//read iter and mode
    begin
        next_iter = i_iter;
        next_mode = i_mode;
    end
    if(i_valid && wt_read == 1)//read image
    begin
        next_in_count = in_count + 1;
    end
    if(in_count == 4096 && wt_read == 1)//read image done
    begin
        next_in_count = 0;
    end

    if(state == SUB && mm_ct == 520)//sub done
    begin
        next_iter_count = iter_count + 1;
    end
    if(state == OUT)
    begin
        next_iter_count = 0;
    end
         
end
//sram do
always @(*)
begin
    next_sram_128_do = SRAM_512X128_DO;
    next_sram_cal_128_do = SRAM_cal_512X128_DO;
    next_sram_img_128_do = SRAM_img_512X128_DO;
    next_sram_64_do = SRAM_96X64_DO;

end
//temp8
always @(*)
begin
    next_tmp8 = tmp8;
    img_tmp128 = 128'd0;

    if(state == WAIT && mm_ct >= 3)
    begin
        /*img_tmp128 = {{tmp8}, {sram_cal_128_do[127:112]}, {8'd0}, {sram_cal_128_do[103:80]}, {8'd0}, 
                    {sram_cal_128_do[71:48]}, {8'd0}, {sram_cal_128_do[39:16]}, {8'd0}};*/
        img_tmp128 = {tmp8, sram_cal_128_do[127:112], 8'd0, sram_cal_128_do[103:80], 8'd0, 
                        sram_cal_128_do[71:48], 8'd0, sram_cal_128_do[39:16], 8'd0};
        if((mm_ct - 3) % 4 == 0)
        begin
            /*img_tmp128 = {{4'd0}, {sram_cal_128_do[127:112]}, {8'd0}, {sram_cal_128_do[103:80]}, {8'd0}, 
                        {sram_cal_128_do[71:48]}, {8'd0}, {sram_cal_128_do[39:16]}, {8'd0}};*/
            img_tmp128 = {8'd0, sram_cal_128_do[127:112], 8'd0, sram_cal_128_do[103:80], 8'd0, 
                            sram_cal_128_do[71:48], 8'd0, sram_cal_128_do[39:16], 8'd0};
        end

        next_tmp8 = sram_cal_128_do[7:0];
    end

end

// wt_temp
always @(*)
begin
    for (i = 0; i < 52; i = i + 1)
    begin
        next_wt_temp[i] = wt_temp[i];
    end

    if(i_valid && wt_read == 0)//read weight
    begin
        next_wt_temp[51] = i_weight;
        next_wt_temp[0:50] = wt_temp[1:51];
    end
    if(wt_read == 0 && in_count == 1312)//read weight done
    begin
        for (i = 0; i < 52; i = i + 1)
        begin
            next_wt_temp[i] = 0;
        end
    end
end
//img_temp
always @(*)
begin
    for (i = 0; i < 16; i = i + 1)
    begin
        next_img_temp[i] = img_temp[i];
    end
    if(i_valid && wt_read == 1)//read image
    begin
        next_img_temp[15] = i_data;
        next_img_temp[0:14] = img_temp[1:15];
    end

    /*if(state == WAIT && mm_ct >= 3 && mm_ct <= 258)//read sub result
    begin
        next_img_temp[15] = sram_cal_128_do[7:0];
    end*/

    if(state == CONV2 && mm_ct >= 54 && mm_ct <= 3126)//read image for conv2
    begin
        if((mm_ct - 54) % 48 == 0)
        begin
            next_img_temp[15] = out_data[31:24];
            next_img_temp[14] = out_data[63:56];
            next_img_temp[13] = out_data[95:88];
            next_img_temp[12] = out_data[127:120];
            next_img_temp[0:11] = img_temp[4:15];
        end
    end
end

//state
always @(*)
begin
    next_state = state;
    case(state)
        IDLE: begin
            next_state = (in_count == 4095 && wt_read == 1 && iter > 0) ? CONV1 : IDLE;
        end
        CONV1: begin
            next_state = (conv_ct == 774) ? QKV : CONV1;
        end
        QKV: begin
            next_state = (mm_ct == 3078) ? QKT : QKV;
        end
        QKT: begin
            next_state = (mm_ct == 262) ? V : QKT;
        end
        V: begin
            if(mm_ct == 262 && round != 63)
                next_state = QKT;
            else if(mm_ct == 262 && round == 63)
                next_state = FFN;
            else
                next_state = V;
        end
        FFN: begin
            next_state = (mm_ct == 1037) ? CONV2 : FFN;
        end
        CONV2: begin
            if(mm_ct == 3126 && (mode != 0))
                next_state = INPOL_D;
            else if(mm_ct == 3126 && mode == 0)
                next_state = INPOL;
            else
                next_state = CONV2;
        end
        INPOL_D: begin
            next_state = (mm_ct == 38) ? INPOL : INPOL_D;
        end
        INPOL: begin
            next_state = (mm_ct == 520) ? SUB : INPOL;
        end
        SUB: begin
            if(mm_ct == 520 && iter_count < iter - 1)
                next_state = WAIT;
            else if(mm_ct == 520 && iter_count == iter - 1)
                next_state = OUT;
            else
                next_state = SUB;
        end
        WAIT: begin
            next_state = (mm_ct == 258) ? CONV1 : WAIT;
        end
        OUT: begin
            next_state = (mm_ct == 4098) ? IDLE : OUT;
        end
    endcase
end

MMULT mmult_inst(.clk(clk), .rst_n(rst_n), .mac_reset(mac_reset), .sign_valid(sign_valid), .t_valid(t_valid), .mode(mm_mode), 
    .a(a_select), .b(b_select), .out_data(out_data));
//matrix multiplication
always @(*)
begin
    a_select = 128'd0;
    b_select = 128'd0;
    mac_reset = 0;
    sign_valid = 0;
    t_valid = 0;
    mm_mode = 0;
    k_row = 0;

    if(state == CONV1 && conv_ct >= 3 && conv_ct <= 770)//3-770
    begin
        a_select = sram_128_do;
        /*b_select = {{4'd0}, {sram_64_do[63:60]}, {4'd0}, {sram_64_do[59:56]}, {4'd0}, {sram_64_do[55:52]}, {4'd0}, {sram_64_do[51:48]}, 
                    {4'd0}, {sram_64_do[47:44]}, {4'd0}, {sram_64_do[43:40]}, {4'd0}, {sram_64_do[39:36]}, {4'd0}, {sram_64_do[35:32]}, 
                    {4'd0}, {sram_64_do[31:28]}, {4'd0}, {sram_64_do[27:24]}, {4'd0}, {sram_64_do[23:20]}, {4'd0}, {sram_64_do[19:16]}, 
                    {4'd0}, {sram_64_do[15:12]}, {4'd0}, {sram_64_do[11:8]},  {4'd0}, {sram_64_do[7:4]},   {4'd0}, {sram_64_do[3:0]}};*/
        b_select = {{4{sram_64_do[63]}}, sram_64_do[63:60], {4{sram_64_do[59]}}, sram_64_do[59:56], {4{sram_64_do[55]}}, sram_64_do[55:52], {4{sram_64_do[51]}}, sram_64_do[51:48], 
                    {4{sram_64_do[47]}}, sram_64_do[47:44], {4{sram_64_do[43]}}, sram_64_do[43:40], {4{sram_64_do[39]}}, sram_64_do[39:36], {4{sram_64_do[35]}}, sram_64_do[35:32], 
                    {4{sram_64_do[31]}}, sram_64_do[31:28], {4{sram_64_do[27]}}, sram_64_do[27:24], {4{sram_64_do[23]}}, sram_64_do[23:20], {4{sram_64_do[19]}}, sram_64_do[19:16], 
                    {4{sram_64_do[15]}}, sram_64_do[15:12], {4{sram_64_do[11]}}, sram_64_do[11:8],  {4{sram_64_do[7]}}, sram_64_do[7:4],    {4{sram_64_do[3]}}, sram_64_do[3:0]};
        sign_valid = 0;
        t_valid = 1;
        mm_mode = 0;
    end
    if(state == CONV1 && conv_ct >= 8 && conv_ct <= 773 && (conv_ct - 8) % 3 == 0)//8,11,14,...,770,773
    begin
        mac_reset = 1;
    end
    if(state == QKV && mm_ct >= 3 && mm_ct <= 3074)//3-3074
    begin
        a_select = sram_img_128_do;
        b_select = {{4{sram_64_do[63]}}, sram_64_do[63:60], {4{sram_64_do[59]}}, sram_64_do[59:56], {4{sram_64_do[55]}}, sram_64_do[55:52], {4{sram_64_do[51]}}, sram_64_do[51:48], 
                    {4{sram_64_do[47]}}, sram_64_do[47:44], {4{sram_64_do[43]}}, sram_64_do[43:40], {4{sram_64_do[39]}}, sram_64_do[39:36], {4{sram_64_do[35]}}, sram_64_do[35:32], 
                    {4{sram_64_do[31]}}, sram_64_do[31:28], {4{sram_64_do[27]}}, sram_64_do[27:24], {4{sram_64_do[23]}}, sram_64_do[23:20], {4{sram_64_do[19]}}, sram_64_do[19:16], 
                    {4{sram_64_do[15]}}, sram_64_do[15:12], {4{sram_64_do[11]}}, sram_64_do[11:8],  {4{sram_64_do[7]}}, sram_64_do[7:4],    {4{sram_64_do[3]}}, sram_64_do[3:0]};
        sign_valid = 0;
        t_valid = 0;
        mm_mode = 1;
    end
    if(state == QKV && mm_ct >= 9 && mm_ct <= 3077 && (mm_ct - 9) % 4 == 0)//9,13,17,...,3073,3077
    begin
        mac_reset = 1;
    end
    if(state == QKT && mm_ct >= 3 && mm_ct <= 258)//3-258
    begin
        a_select = sram_cal_128_do;
        b_select = sram_128_do;
        sign_valid = 1;
        t_valid = 1;
        mm_mode = 2;
    end
    if(state == QKT && mm_ct >= 9 && mm_ct <= 261 && (mm_ct - 9) % 4 == 0)//9,13,17,...,257,261
    begin
        mac_reset = 1;
    end
    if(state == V && mm_ct >= 3 && mm_ct <= 258)//3-258
    begin
        a_select = sram_img_128_do;
        b_select = sram_cal_128_do;
        sign_valid = 0;
        t_valid = 0;
        mm_mode = 3;
    end
    if(state == V && mm_ct >= 69 && mm_ct <= 261 && (mm_ct - 69) % 64 == 0)//69,73,77,...,257,261
    begin
        mac_reset = 1;
    end
    if(state == FFN && mm_ct >= 3 && mm_ct <= 1026)//3-1026
    begin
        a_select = sram_128_do;
        //b_select = sram_64_do;
        b_select = {{4{sram_64_do[63]}}, sram_64_do[63:60], {4{sram_64_do[59]}}, sram_64_do[59:56], {4{sram_64_do[55]}}, sram_64_do[55:52], {4{sram_64_do[51]}}, sram_64_do[51:48], 
                    {4{sram_64_do[47]}}, sram_64_do[47:44], {4{sram_64_do[43]}}, sram_64_do[43:40], {4{sram_64_do[39]}}, sram_64_do[39:36], {4{sram_64_do[35]}}, sram_64_do[35:32], 
                    {4{sram_64_do[31]}}, sram_64_do[31:28], {4{sram_64_do[27]}}, sram_64_do[27:24], {4{sram_64_do[23]}}, sram_64_do[23:20], {4{sram_64_do[19]}}, sram_64_do[19:16], 
                    {4{sram_64_do[15]}}, sram_64_do[15:12], {4{sram_64_do[11]}}, sram_64_do[11:8],  {4{sram_64_do[7]}}, sram_64_do[7:4],    {4{sram_64_do[3]}}, sram_64_do[3:0]};
        sign_valid = 1;
        t_valid = 0;
        mm_mode = 7;
    end
    if(state == FFN && mm_ct >= 9 && mm_ct <= 1029 && (mm_ct - 9) % 4 == 0)//9,13,17,...,1025,1029
    begin
        mac_reset = 1;
    end
    if(state == CONV2 && mm_ct >= 3 && mm_ct <= 3074)//3-3074
    begin
        if(((mm_ct - 3) % 6) / 3 == 0)//ch is even
        begin
            //a_select = {{conv2m_tmp[95:72]}, {8'd0}, {conv2m_tmp[87:64]}, {8'd0}, {conv2m_tmp[79:56]}, {8'd0}, {conv2m_tmp[71:48]}, {8'd0}};
            //a_select = {{sram_cal_128_do[95:72]}, {8'd0}, {sram_cal_128_do[87:64]}, {8'd0}, {sram_cal_128_do[79:56]}, {8'd0}, {sram_cal_128_do[71:48]}, {8'd0}};
            a_select = {sram_cal_128_do[95:72], 8'd0, sram_cal_128_do[87:64], 8'd0, sram_cal_128_do[79:56], 8'd0, sram_cal_128_do[71:48], 8'd0};
        end
        else //ch is odd
        begin
            //a_select = {{sram_cal_128_do[47:24]}, {8'd0}, {sram_cal_128_do[39:16]}, {8'd0}, {sram_cal_128_do[31:8]}, {8'd0}, {sram_cal_128_do[23:0]}, {8'd0}};
            a_select = {sram_cal_128_do[47:24], 8'd0, sram_cal_128_do[39:16], 8'd0, sram_cal_128_do[31:8], 8'd0, sram_cal_128_do[23:0], 8'd0};
        end
        //padding 0
        if((mm_ct - 3) % 3 == 0 && (mm_ct - 3) / 192 == 0)//r=-1 no read
        begin
            a_select = 128'd0;
        end
        else if(((mm_ct - 3) % 3) - 1 + ((mm_ct - 3) / 192) == 16)//r=16 no read
        begin
            a_select = 128'd0;
        end
        if(((mm_ct - 3) % 12) / 3 == 0)//k 0
        begin
            b_select = {{4{sram_64_do[63]}}, sram_64_do[63:60], {4{sram_64_do[59]}}, sram_64_do[59:56], {4{sram_64_do[55]}}, sram_64_do[55:52], 8'd0, 96'd0};
        end
        else if(((mm_ct - 3) % 12) / 3 == 1)//k 1
        begin
            //b_select = {{4'd0}, {sram_64_do[47:44]}, {4'd0}, {sram_64_do[43:40]}, {4'd0}, {sram_64_do[39:36]}, {8'd0}, {112'd0}};
            b_select = {{4{sram_64_do[47]}}, sram_64_do[47:44], {4{sram_64_do[43]}}, sram_64_do[43:40], {4{sram_64_do[39]}}, sram_64_do[39:36], 8'd0, 96'd0};
        end
        else if(((mm_ct - 3) % 12) / 3 == 2)//k 2
        begin
            //b_select = {{4'd0}, {sram_64_do[31:28]}, {4'd0}, {sram_64_do[27:24]}, {4'd0}, {sram_64_do[23:20]}, {8'd0}, {112'd0}};
            b_select = {{4{sram_64_do[31]}}, sram_64_do[31:28], {4{sram_64_do[27]}}, sram_64_do[27:24], {4{sram_64_do[23]}}, sram_64_do[23:20], 8'd0, 96'd0};
        end
        else //k 3
        begin
            //b_select = {{4'd0}, {sram_64_do[15:12]}, {4'd0}, {sram_64_do[11:8]}, {4'd0}, {sram_64_do[7:4]}, {8'd0}, {112'd0}};
            b_select = {{4{sram_64_do[15]}}, sram_64_do[15:12], {4{sram_64_do[11]}}, sram_64_do[11:8], {4{sram_64_do[7]}}, sram_64_do[7:4], 8'd0, 96'd0};
        end
        sign_valid = 0;
        t_valid = 1;
        mm_mode = 0;
    end
    if(state == CONV2 && mm_ct >= 53 && mm_ct <= 3125 && (mm_ct - 53) % 48 == 0)//53,101,149,...,3061,3109
    begin
        mac_reset = 1;
    end
    if(state == INPOL_D && mm_ct >= 3 && mm_ct <= 34)//3-34
    begin
        if(mode == 1)
        begin
            if(mm_ct % 2 == 1)//even in read
            begin
                //a_select = {{sram_img_128_do[119:0]}, {sram_img_128_do[7:0]}};
                a_select = {sram_img_128_do[119:0], sram_img_128_do[7:0]};
                b_select = {8'd1, 8'd0, 8'd0, 8'd0, 
                            8'd0, 8'd1, 8'd0, 8'd0,  
                            8'd0, 8'd0, 8'd1, 8'd0, 
                            8'd0, 8'd0, 8'd0, 8'd1};
            end
            else//odd
            begin
                //a_select = {{sram_img_128_do[127:8]}, {sram_img_128_do[15:8]}};
                a_select = {sram_img_128_do[127:8], sram_img_128_do[15:8]};
                b_select = {-8'd1, 8'd0, 8'd0, 8'd0, 
                            8'd0, -8'd1, 8'd0, 8'd0,  
                            8'd0, 8'd0, -8'd1, 8'd0, 
                            8'd0, 8'd0, 8'd0, -8'd1};
            end
        end
        else if(mode == 2)
        begin
            if(mm_ct % 2 == 1)//even in read
            begin
                //a_select = {{sram_img_128_do[119:0]}, {sram_img_128_do[7:0]}};
                a_select = sram_img_128_do;
                b_select = {8'd1, 8'd0, 8'd0, 8'd0, 
                            8'd0, 8'd1, 8'd0, 8'd0,  
                            8'd0, 8'd0, 8'd1, 8'd0, 
                            8'd0, 8'd0, 8'd0, 8'd1};
            end
            else//odd
            begin
                //a_select = {{sram_img_128_do[127:8]}, {sram_img_128_do[15:8]}};
                a_select = sram_img_128_do;
                b_select = {-8'd1, 8'd0, 8'd0, 8'd0, 
                            8'd0, -8'd1, 8'd0, 8'd0,  
                            8'd0, 8'd0, -8'd1, 8'd0, 
                            8'd0, 8'd0, 8'd0, -8'd1};
            end
        end
        
        sign_valid = 0;
        t_valid = 0;
        mm_mode = 4;
    end
    if(state == INPOL_D && mm_ct >= 7 && mm_ct <= 37 && (mm_ct - 7) % 2 == 0)//7,9,11,...,35,37
    begin
        mac_reset = 1;
    end
    if(state == INPOL && mm_ct >= 3 && mm_ct <= 514)//3-514
    begin
        k_row = ((mm_ct - 3) / 8) % 4;

        if(mm_ct % 2 == 1)//even in read
        begin
            if(((mm_ct - 3) % 8) / 2 == 0)
            begin
                a_select = {{4{sram_img_128_do[127:120]}}, {4{sram_img_128_do[119:112]}}, {4{sram_img_128_do[111:104]}}, {4{sram_img_128_do[103:96]}}};
            end
            else if(((mm_ct - 3) % 8) / 2 == 1)
            begin
                a_select = {{4{sram_img_128_do[95:88]}}, {4{sram_img_128_do[87:80]}}, {4{sram_img_128_do[79:72]}}, {4{sram_img_128_do[71:64]}}};
            end
            else if(((mm_ct - 3) % 8) / 2 == 2)
            begin
                a_select = {{4{sram_img_128_do[63:56]}}, {4{sram_img_128_do[55:48]}}, {4{sram_img_128_do[47:40]}}, {4{sram_img_128_do[39:32]}}};
            end
            else    
            begin
                a_select = {{4{sram_img_128_do[31:24]}}, {4{sram_img_128_do[23:16]}}, {4{sram_img_128_do[15:8]}}, {4{sram_img_128_do[7:0]}}};
            end
            b_select = {8'd1, 8'd0, 8'd0, 8'd0, 
                        8'd0, 8'd1, 8'd0, 8'd0,  
                        8'd0, 8'd0, 8'd1, 8'd0, 
                        8'd0, 8'd0, 8'd0, 8'd1};

            sign_valid = 0;
        end
        else//odd
        begin
            if(((mm_ct - 3) % 8) / 2 == 0)
            begin
                //a_select = {{sram_cal_128_do[127:120]}, {32'd0}, {sram_cal_128_do[119:112]}, {32'd0}, {sram_cal_128_do[111:104]}, {32'd0}, {sram_cal_128_do[103:96]}};
                a_select = {sram_cal_128_do[127:120], 32'd0, sram_cal_128_do[119:112], 32'd0, sram_cal_128_do[111:104], 32'd0, sram_cal_128_do[103:96]};
            end
            else if(((mm_ct - 3) % 8) / 2 == 1)
            begin
                //a_select = {{sram_cal_128_do[95:88]}, {32'd0}, {sram_cal_128_do[87:80]}, {32'd0}, {sram_cal_128_do[79:72]}, {32'd0}, {sram_cal_128_do[71:64]}};
                a_select = {sram_cal_128_do[95:88], 32'd0, sram_cal_128_do[87:80], 32'd0, sram_cal_128_do[79:72], 32'd0, sram_cal_128_do[71:64]};
            end
            else if(((mm_ct - 3) % 8) / 2 == 2)
            begin
                //a_select = {{sram_cal_128_do[63:56]}, {32'd0}, {sram_cal_128_do[55:48]}, {32'd0}, {sram_cal_128_do[47:40]}, {32'd0}, {sram_cal_128_do[39:32]}};
                a_select = {sram_cal_128_do[63:56], 32'd0, sram_cal_128_do[55:48], 32'd0, sram_cal_128_do[47:40], 32'd0, sram_cal_128_do[39:32]};
            end
            else    
            begin
                //a_select = {{sram_cal_128_do[31:24]}, {32'd0}, {sram_cal_128_do[23:16]}, {32'd0}, {sram_cal_128_do[15:8]}, {32'd0}, {sram_cal_128_do[7:0]}};
                a_select = {sram_cal_128_do[31:24], 32'd0, sram_cal_128_do[23:16], 32'd0, sram_cal_128_do[15:8], 32'd0, sram_cal_128_do[7:0]};
            end
            if(mode == 0)
            begin
                a_select = 128'd0;
            end
            
            if(mode == 1)
            begin
                b_select = {8'd0, 8'd1, 8'd2, 8'd3, 
                            8'd0, 8'd1, 8'd2, 8'd3,  
                            8'd0, 8'd1, 8'd2, 8'd3, 
                            8'd0, 8'd1, 8'd2, 8'd3};
            end
            else if(mode == 2)
            begin
                //b_select = {{16{{6'd0}, {k_row}}}};
                b_select = {{16{6'd0, k_row}}};
            end
            else 
                b_select = 128'd0;

            sign_valid = 1;
        end
        //sign_valid = 0;
        t_valid = 0;
        mm_mode = 5;
    end
    if(state == INPOL && mm_ct >= 7 && mm_ct <= 519 && (mm_ct - 7) % 2 == 0)//7,9,11,...,519
    begin
        mac_reset = 1;
    end
    if(state == SUB && mm_ct >= 3 && mm_ct <= 514)//3-514
    begin
        if(mm_ct % 2 == 1)
        begin
            a_select = sram_img_128_do;
            b_select = {8'd1, 8'd0, 8'd0, 8'd0, 
                        8'd0, 8'd1, 8'd0, 8'd0,  
                        8'd0, 8'd0, 8'd1, 8'd0, 
                        8'd0, 8'd0, 8'd0, 8'd1};
        end
        else
        begin
            a_select = sram_128_do;
            b_select = {-8'd1, 8'd0, 8'd0, 8'd0, 
                        8'd0, -8'd1, 8'd0, 8'd0,  
                        8'd0, 8'd0, -8'd1, 8'd0, 
                        8'd0, 8'd0, 8'd0, -8'd1};
        end
        sign_valid = 0;
        t_valid = 0;
        mm_mode = 6;
    end
    if(state == SUB && mm_ct >= 7 && mm_ct <= 519 && (mm_ct - 7) % 2 == 0)//7,9,11,...,519
    begin
        mac_reset = 1;
    end

end
//conv
always @(*)
begin
    next_conv_ct = conv_ct;
    if(state == CONV1)
    begin
        next_conv_ct = conv_ct + 1;
    end

    if(next_state != state)
    begin
        next_conv_ct = 0;
    end
end
//mm
always @(*)
begin
    next_mm_ct = mm_ct;
    next_round = round;

    if(state == QKV || state == QKT || state == V || state == FFN || state == CONV2 || state == INPOL_D || state == INPOL || state == SUB || state == WAIT || state == OUT)
    begin
        next_mm_ct = mm_ct + 1;
    end
    if(state != next_state)
    begin
        next_mm_ct = 0;
    end

    if(state == V && mm_ct == 262)
    begin
        next_round = round + 1;
    end
    if(state == OUT || state == WAIT)
    begin
        next_round = 0;
    end

end
//ffn temp
always @(*)
begin
    for(i = 0; i < 2; i = i + 1)
    begin
        next_s96[i] = s96[i];
    end
    for (i = 0; i < 36; i = i + 1)
    begin
        next_ffn_temp[i] = ffn_temp[i];
    end
    next_s96[0] = s96[1];
    next_s96[1] = 0;

    if(state == FFN && mm_ct >= 10 && mm_ct <= 1030 && (mm_ct - 10) % 4 == 0)
    begin
        next_ffn_temp[0:3] = ffn_temp[16:19];
        next_ffn_temp[4:19] = ffn_temp[20:35];
        for (i = 0; i < 16; i = i + 1)//next_ffn_temp[20:35] = out_data[127:0];
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                next_ffn_temp[35-i][j] = out_data[8*i+j];
            end
        end
    end
    if(state == FFN && mm_ct == 1034)
    begin
        next_ffn_temp[0:3] = ffn_temp[16:19];
        next_ffn_temp[4:19] = ffn_temp[20:35];
        for (i = 0; i < 16; i = i + 1)//next_ffn_temp[20:35] = out_data[127:0];
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                next_ffn_temp[35-i][j] = 0;
            end
        end
    end

    if(state == FFN && mm_ct >= 15 && mm_ct <= 1035 && (mm_ct - 15) % 4 == 0)//15,19,23,27,...,1031,1035
    begin
        next_s96[0] = {{ffn_temp[0]}, {ffn_temp[4]}, {ffn_temp[8]}, {ffn_temp[12]}, {ffn_temp[16]}, {ffn_temp[20]}, {ffn_temp[1]}, {ffn_temp[5]}, {ffn_temp[9]}, {ffn_temp[13]}, {ffn_temp[17]}, {ffn_temp[21]}};
        next_s96[1] = {{ffn_temp[2]}, {ffn_temp[6]}, {ffn_temp[10]}, {ffn_temp[14]}, {ffn_temp[18]}, {ffn_temp[22]}, {ffn_temp[3]}, {ffn_temp[7]}, {ffn_temp[11]}, {ffn_temp[15]}, {ffn_temp[19]}, {ffn_temp[23]}};
        if(((mm_ct + 1) >> 2) % 4 == 0)//padding 0 in the beginning
        begin
            next_s96[0] = {{8'd0}, {ffn_temp[4]}, {ffn_temp[8]}, {ffn_temp[12]}, {ffn_temp[16]}, {ffn_temp[20]}, {8'd0}, {ffn_temp[5]}, {ffn_temp[9]}, {ffn_temp[13]}, {ffn_temp[17]}, {ffn_temp[21]}};
            next_s96[1] = {{8'd0}, {ffn_temp[6]}, {ffn_temp[10]}, {ffn_temp[14]}, {ffn_temp[18]}, {ffn_temp[22]}, {8'd0}, {ffn_temp[7]}, {ffn_temp[11]}, {ffn_temp[15]}, {ffn_temp[19]}, {ffn_temp[23]}};
        end
        else if(((mm_ct + 1) >> 2) % 4 == 3)//padding 0 in the end
        begin
            next_s96[0] = {{ffn_temp[0]}, {ffn_temp[4]}, {ffn_temp[8]}, {ffn_temp[12]}, {ffn_temp[16]}, {8'd0}, {ffn_temp[1]}, {ffn_temp[5]}, {ffn_temp[9]}, {ffn_temp[13]}, {ffn_temp[17]}, {8'd0}};
            next_s96[1] = {{ffn_temp[2]}, {ffn_temp[6]}, {ffn_temp[10]}, {ffn_temp[14]}, {ffn_temp[18]}, {8'd0}, {ffn_temp[3]}, {ffn_temp[7]}, {ffn_temp[11]}, {ffn_temp[15]}, {ffn_temp[19]}, {8'd0}};

        end
    end
    
end
//out
always @(*)
begin
    next_o_valid = 0;
    next_o_data = 0;

    if(state == OUT && mm_ct >= 3 && mm_ct <= 4098)//3-4098
    begin
        next_o_valid = 1;
        case ((mm_ct - 3) % 16)
            0: next_o_data = sram_cal_128_do[127:120];
            1: next_o_data = sram_cal_128_do[119:112];
            2: next_o_data = sram_cal_128_do[111:104];
            3: next_o_data = sram_cal_128_do[103:96];
            4: next_o_data = sram_cal_128_do[95:88];
            5: next_o_data = sram_cal_128_do[87:80];
            6: next_o_data = sram_cal_128_do[79:72];
            7: next_o_data = sram_cal_128_do[71:64];
            8: next_o_data = sram_cal_128_do[63:56];
            9: next_o_data = sram_cal_128_do[55:48];
            10: next_o_data = sram_cal_128_do[47:40];
            11: next_o_data = sram_cal_128_do[39:32];
            12: next_o_data = sram_cal_128_do[31:24];
            13: next_o_data = sram_cal_128_do[23:16];
            14: next_o_data = sram_cal_128_do[15:8];
            15: next_o_data = sram_cal_128_do[7:0];
        endcase
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 52; i = i + 1)
        begin
            wt_temp[i] <= 0;
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            img_temp[i] <= 0;
        end
        for (i = 0; i < 2; i = i + 1)
        begin
            s96[i] <= 0;
        end
        for (i = 0; i < 36; i = i + 1)
        begin
            ffn_temp[i] <= 0;
        end
        we_img <= 0;
        we_128 <= 0;
        we64 <= 0;
        we_cal_128 <= 0;
        ad_img <= 0;
        ad_128 <= 0;
        ad_64 <= 0;
        ad_cal_128 <= 0;
        di_img_sram <= 0;
        di128_sram <= 0;
        di64_sram <= 0;
        di_cal_128_sram <= 0;
        in_count <= 0;
        iter_count <= 0;
        iter <= 0;
        mode <= 0;
        in_data <= 0;
        wt_read <= 0;
        rd_wt_ct <= 0;
        state <= 0;
        conv_ct <= 0;
        mm_ct <= 0;
        round <= 0;
        sram_128_do <= 0;
        sram_64_do <= 0;
        sram_cal_128_do <= 0;
        sram_img_128_do <= 0;
        tmp8 <= 0;
        o_valid <= 0;
        o_data <= 0;
        i_valid_buf <= 0;
        
        /*we_debg <= 0;
        ad_debg <= 0;
        di_debg <= 0;*/
    end
    else
    begin
        for (i = 0; i < 52; i = i + 1)
        begin
            wt_temp[i] <= next_wt_temp[i];
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            img_temp[i] <= next_img_temp[i];
        end
        for (i = 0; i < 2; i = i + 1)
        begin
            s96[i] <= next_s96[i];
        end
        for (i = 0; i < 36; i = i + 1)
        begin
            ffn_temp[i] <= next_ffn_temp[i];
        end
        we_img <= next_we_img;
        we_128 <= next_we_128;
        we_cal_128 <= next_we_cal_128;
        we64 <= next_we64;
        ad_img <= next_ad_img;
        ad_128 <= next_ad_128;
        ad_cal_128 <= next_ad_cal_128;
        ad_64 <= next_ad_64;
        di_img_sram <= next_di_img_sram;
        di128_sram <= next_di128_sram;
        di_cal_128_sram <= next_di_cal_128_sram;
        di64_sram <= next_di64_sram;
        in_count <= next_in_count;
        iter_count <= next_iter_count;
        iter <= next_iter;
        mode <= next_mode;
        in_data <= next_in_data;
        wt_read <= next_wt_read;
        rd_wt_ct <= next_rd_wt_ct;
        state <= next_state;
        conv_ct <= next_conv_ct;
        mm_ct <= next_mm_ct;
        round <= next_round;
        sram_128_do <= next_sram_128_do;
        sram_64_do <= next_sram_64_do;
        sram_cal_128_do <= next_sram_cal_128_do;
        sram_img_128_do <= next_sram_img_128_do;
        tmp8 <= next_tmp8;
        o_valid <= next_o_valid;
        o_data <= next_o_data;
        i_valid_buf <= next_i_valid_buf;
        
        /*we_debg <= next_we_debg;
        ad_debg <= next_ad_debg;
        di_debg <= next_di_debg;*/
    end
end

endmodule

module MMULT(
    input clk,
    input rst_n,
    input mac_reset,
    input sign_valid,
    input t_valid,
    input [2:0] mode,
    input [127:0] a,//unsigned or signed
    input [127:0] b,//signed
    output reg [127:0] out_data
);

reg [127:0] next_out_data;
reg signed [8:0] a_list [0:15], next_a_list [0:15], b_list [0:15], next_b_list [0:15];
reg signed [18:0] c_list [0:15], next_c_list [0:15];
reg signed [24:0] mac_list [0:15], next_mac_list [0:15];
reg [2:0] mode1, mode2, mode3, mode4;
reg signed [15:0] shifted_value [0:15];
reg [7:0] c_value [0:15];
reg [7:0] clip_value [0:15];
reg signed [18:0] softmax_clip [0:15];

integer i, j, k;
//1
always @(*)
begin
    for (i = 0; i < 16; i = i + 1)
    begin
        next_a_list[i] = a_list[i];
        next_b_list[i] = b_list[i];
    end
    for (i = 0; i < 16; i = i + 1)
    begin
        //next_b_list[i] = {b[127-i*8], b[127-i*8 : 120-i*8]};
        next_b_list[i] = {b[127-i*8], b[120-i*8 +: 8]};
    end
    if(t_valid) //transpose
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                //next_b_list[i*4+j] = next_b_list[j*4+i];
                next_b_list[i*4+j] = {b[127-(j*4+i)*8], b[120-(j*4+i)*8 +: 8]};
            end 
        end
    end

    if(sign_valid)
    begin
        if(mode == 1)
        begin
            for (i = 0; i < 16; i = i + 1)
            begin
                //next_a_list[i] = {a[127-i*8], a[127-i*8 : 120-i*8]} - 9'd128;
                next_a_list[i] = {a[127-i*8], a[120-i*8 +: 8]} - 9'd128;
            end
        end
        else
        begin
            for (i = 0; i < 16; i = i + 1)
            begin
                //next_a_list[i] = {a[127-i*8], a[127-i*8 : 120-i*8]};
                next_a_list[i] = {a[127-i*8], a[120-i*8 +: 8]};
            end
        end
    end
    else
    begin
        // *** mode 1 to do
        if(mode == 1)
        begin
            for (i = 0; i < 16; i = i + 1)
            begin
                //next_a_list[i] = {a[127-i*8], a[127-i*8 : 120-i*8]} - 9'd128;
                next_a_list[i] = {1'b0, a[120-i*8 +: 8]} - 9'd128;
            end
        end
        else
        begin
            for (i = 0; i < 16; i = i + 1)
            begin
                //next_a_list[i] = {1'b0, a[127-i*8 : 120-i*8]};
                next_a_list[i] = {1'b0, a[120-i*8 +: 8]};
            end
        end
    end

    mode1 = mode;
end
//2
always @(*)
begin
    for (i = 0; i < 16; i = i + 1)
    begin
        next_c_list[i] = c_list[i];
    end

    //matrix multiplication
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            next_c_list[i*4+j] = 0;
            for (k = 0; k < 4; k = k + 1)
            begin
                next_c_list[i*4+j] = a_list[i*4+k] * b_list[k*4+j] + next_c_list[i*4+j];
            end
        end
    end
end
//3
always @(*)
begin
    for (i = 0; i < 16; i = i + 1)
    begin
        next_mac_list[i] = mac_list[i];
    end

    if(!mac_reset)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_mac_list[i] = mac_list[i] + c_list[i];
        end
    end
    else
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_mac_list[i] = c_list[i];
        end
    end
end
//4 normalization
always @(*)
begin
    next_out_data = 0;
    for (i = 0; i < 16; i = i + 1)
    begin
        shifted_value[i] = 0;
        clip_value[i] = 0;
        c_value[i] = 0;
        softmax_clip[i] = 0;
    end

    if(mode4 == 0)//conv
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            shifted_value[i] = (mac_list[i] >>> 6) + 128;
            if(shifted_value[i][15])//relu
                clip_value[i] = 0;
            else if(shifted_value[i] > 255)//clip
                clip_value[i] = 255;
            else
                clip_value[i] = shifted_value[i][7:0];
        end
    end
    else if(mode4 == 1)//qkv
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            if((mac_list[i] >>> 4) > 127)//clip
                clip_value[i] = 127;
            else if((mac_list[i] >>> 4) < -128)
                clip_value[i] = -128;
            else
                clip_value[i] = mac_list[i] >>> 4;
        end
    end
    else if(mode4 == 2)//qkt softmax
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            if((mac_list[i] >>> 2) > 2047)//clip
                softmax_clip[i] = 2047;
            else if((mac_list[i] >>> 2) < -2048)
                softmax_clip[i] = -2048;
            else
                softmax_clip[i] = mac_list[i] >>> 2;

            if((softmax_clip[i] >>> 4) + 128 > 255)
                clip_value[i] = 255;
            else if((softmax_clip[i] >>> 4) + 128 < 0)
                clip_value[i] = 0;
            else
                clip_value[i] = (softmax_clip[i] >>> 4) + 128;
        end
    end
    else if(mode4 == 3)//v
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            if((mac_list[i] >>> 16) > 127)//clip
                clip_value[i] = 127;
            else if((mac_list[i] >>> 16) < -128)
                clip_value[i] = -128;
            else
                clip_value[i] = mac_list[i] >>> 16;
        end
    end
    else if(mode4 == 4)//inpol d
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            clip_value[i] = mac_list[i] >>> 2;
        end
    end
    else if(mode4 == 5)//inpol
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            if(mac_list[i] > 255)//clip
                c_value[i] = 255;
            else if(mac_list[i] < 0)
                c_value[i] = 0;
            else
                c_value[i] = mac_list[i];

            clip_value[i] = c_value[i] >> 3;
        end
    end
    else if(mode4 == 6)//sub
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            if(mac_list[i] > 255)//clip
                clip_value[i] = 255;
            else if(mac_list[i] < 0)
                clip_value[i] = 0;
            else
                clip_value[i] = mac_list[i];
        end
    end
    else if(mode4 == 7)//ffn
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            shifted_value[i] = (mac_list[i] >>> 4) + 128;
            if(shifted_value[i][15])//relu
                clip_value[i] = 0;
            else if(shifted_value[i] > 255)//clip
                clip_value[i] = 255;
            else
                clip_value[i] = shifted_value[i][7:0];
        end
    end
    
    next_out_data = {clip_value[0], clip_value[1], clip_value[2], clip_value[3], clip_value[4], clip_value[5], clip_value[6], clip_value[7],
                    clip_value[8], clip_value[9], clip_value[10], clip_value[11], clip_value[12], clip_value[13], clip_value[14], clip_value[15]};
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            a_list[i] <= 0;
            b_list[i] <= 0;
            c_list[i] <= 0;
            mac_list[i] <= 0;
        end
        out_data <= 0;
        mode2 <= 0;
        mode3 <= 0;
        mode4 <= 0;
    end
    else
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            a_list[i] <= next_a_list[i];
            b_list[i] <= next_b_list[i];
            c_list[i] <= next_c_list[i];
            mac_list[i] <= next_mac_list[i];
        end
        out_data <= next_out_data;
        mode2 <= mode1;
        mode3 <= mode2;
        mode4 <= mode3;
    end
end

endmodule



module SRAM_512_128 (
    input CLK, CS, OE, WEB,
    input [8:0]  A,
    input [127:0] DI,
    output[127:0] DO
);
SRAM_512x128 SRAM_512x128_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),     .A8(A[8]), 
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  .DO22(DO[22]),  .DO23(DO[23]), 
    .DO24(DO[24]),  .DO25(DO[25]),  .DO26(DO[26]),  .DO27(DO[27]),  .DO28(DO[28]),  .DO29(DO[29]),  .DO30(DO[30]),  .DO31(DO[31]),
    .DO32(DO[32]),  .DO33(DO[33]),  .DO34(DO[34]),  .DO35(DO[35]),  .DO36(DO[36]),  .DO37(DO[37]),  .DO38(DO[38]),  .DO39(DO[39]),
    .DO40(DO[40]),  .DO41(DO[41]),  .DO42(DO[42]),  .DO43(DO[43]),  .DO44(DO[44]),  .DO45(DO[45]),  .DO46(DO[46]),  .DO47(DO[47]),
    .DO48(DO[48]),  .DO49(DO[49]),  .DO50(DO[50]),  .DO51(DO[51]),  .DO52(DO[52]),  .DO53(DO[53]),  .DO54(DO[54]),  .DO55(DO[55]),
    .DO56(DO[56]),  .DO57(DO[57]),  .DO58(DO[58]),  .DO59(DO[59]),  .DO60(DO[60]),  .DO61(DO[61]),  .DO62(DO[62]),  .DO63(DO[63]),
    .DO64(DO[64]),  .DO65(DO[65]),  .DO66(DO[66]),  .DO67(DO[67]),  .DO68(DO[68]),  .DO69(DO[69]),  .DO70(DO[70]),  .DO71(DO[71]),
    .DO72(DO[72]),  .DO73(DO[73]),  .DO74(DO[74]),  .DO75(DO[75]),  .DO76(DO[76]),  .DO77(DO[77]),  .DO78(DO[78]),  .DO79(DO[79]),
    .DO80(DO[80]),  .DO81(DO[81]),  .DO82(DO[82]),  .DO83(DO[83]),  .DO84(DO[84]),  .DO85(DO[85]),  .DO86(DO[86]),  .DO87(DO[87]),
    .DO88(DO[88]),  .DO89(DO[89]),  .DO90(DO[90]),  .DO91(DO[91]),  .DO92(DO[92]),  .DO93(DO[93]),  .DO94(DO[94]),  .DO95(DO[95]),
    .DO96(DO[96]),  .DO97(DO[97]),  .DO98(DO[98]),  .DO99(DO[99]),  .DO100(DO[100]),.DO101(DO[101]),.DO102(DO[102]),.DO103(DO[103]),
    .DO104(DO[104]),.DO105(DO[105]),.DO106(DO[106]),.DO107(DO[107]),.DO108(DO[108]),.DO109(DO[109]),.DO110(DO[110]),.DO111(DO[111]),
    .DO112(DO[112]),.DO113(DO[113]),.DO114(DO[114]),.DO115(DO[115]),.DO116(DO[116]),.DO117(DO[117]),.DO118(DO[118]),.DO119(DO[119]),
    .DO120(DO[120]),.DO121(DO[121]),.DO122(DO[122]),.DO123(DO[123]),.DO124(DO[124]),.DO125(DO[125]),.DO126(DO[126]),.DO127(DO[127]),
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]),
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  .DI22(DI[22]),  .DI23(DI[23]),
    .DI24(DI[24]),  .DI25(DI[25]),  .DI26(DI[26]),  .DI27(DI[27]),  .DI28(DI[28]),  .DI29(DI[29]),  .DI30(DI[30]),  .DI31(DI[31]),
    .DI32(DI[32]),  .DI33(DI[33]),  .DI34(DI[34]),  .DI35(DI[35]),  .DI36(DI[36]),  .DI37(DI[37]),  .DI38(DI[38]),  .DI39(DI[39]),
    .DI40(DI[40]),  .DI41(DI[41]),  .DI42(DI[42]),  .DI43(DI[43]),  .DI44(DI[44]),  .DI45(DI[45]),  .DI46(DI[46]),  .DI47(DI[47]),
    .DI48(DI[48]),  .DI49(DI[49]),  .DI50(DI[50]),  .DI51(DI[51]),  .DI52(DI[52]),  .DI53(DI[53]),  .DI54(DI[54]),  .DI55(DI[55]),
    .DI56(DI[56]),  .DI57(DI[57]),  .DI58(DI[58]),  .DI59(DI[59]),  .DI60(DI[60]),  .DI61(DI[61]),  .DI62(DI[62]),  .DI63(DI[63]),
    .DI64(DI[64]),  .DI65(DI[65]),  .DI66(DI[66]),  .DI67(DI[67]),  .DI68(DI[68]),  .DI69(DI[69]),  .DI70(DI[70]),  .DI71(DI[71]),
    .DI72(DI[72]),  .DI73(DI[73]),  .DI74(DI[74]),  .DI75(DI[75]),  .DI76(DI[76]),  .DI77(DI[77]),  .DI78(DI[78]),  .DI79(DI[79]),
    .DI80(DI[80]),  .DI81(DI[81]),  .DI82(DI[82]),  .DI83(DI[83]),  .DI84(DI[84]),  .DI85(DI[85]),  .DI86(DI[86]),  .DI87(DI[87]),
    .DI88(DI[88]),  .DI89(DI[89]),  .DI90(DI[90]),  .DI91(DI[91]),  .DI92(DI[92]),  .DI93(DI[93]),  .DI94(DI[94]),  .DI95(DI[95]),
    .DI96(DI[96]),  .DI97(DI[97]),  .DI98(DI[98]),  .DI99(DI[99]),  .DI100(DI[100]),.DI101(DI[101]),.DI102(DI[102]),.DI103(DI[103]),
    .DI104(DI[104]),.DI105(DI[105]),.DI106(DI[106]),.DI107(DI[107]),.DI108(DI[108]),.DI109(DI[109]),.DI110(DI[110]),.DI111(DI[111]),
    .DI112(DI[112]),.DI113(DI[113]),.DI114(DI[114]),.DI115(DI[115]),.DI116(DI[116]),.DI117(DI[117]),.DI118(DI[118]),.DI119(DI[119]),
    .DI120(DI[120]),.DI121(DI[121]),.DI122(DI[122]),.DI123(DI[123]),.DI124(DI[124]),.DI125(DI[125]),.DI126(DI[126]),.DI127(DI[127]),
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

module SRAM_cal_512_128 (
    input CLK, CS, OE, WEB,
    input [8:0]  A,
    input [127:0] DI,
    output[127:0] DO
);
SRAM_512x128 SRAM_512x128_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      .A8(A[8]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  .DO22(DO[22]),  .DO23(DO[23]), 
    .DO24(DO[24]),  .DO25(DO[25]),  .DO26(DO[26]),  .DO27(DO[27]),  .DO28(DO[28]),  .DO29(DO[29]),  .DO30(DO[30]),  .DO31(DO[31]),
    .DO32(DO[32]),  .DO33(DO[33]),  .DO34(DO[34]),  .DO35(DO[35]),  .DO36(DO[36]),  .DO37(DO[37]),  .DO38(DO[38]),  .DO39(DO[39]),
    .DO40(DO[40]),  .DO41(DO[41]),  .DO42(DO[42]),  .DO43(DO[43]),  .DO44(DO[44]),  .DO45(DO[45]),  .DO46(DO[46]),  .DO47(DO[47]),
    .DO48(DO[48]),  .DO49(DO[49]),  .DO50(DO[50]),  .DO51(DO[51]),  .DO52(DO[52]),  .DO53(DO[53]),  .DO54(DO[54]),  .DO55(DO[55]),
    .DO56(DO[56]),  .DO57(DO[57]),  .DO58(DO[58]),  .DO59(DO[59]),  .DO60(DO[60]),  .DO61(DO[61]),  .DO62(DO[62]),  .DO63(DO[63]),
    .DO64(DO[64]),  .DO65(DO[65]),  .DO66(DO[66]),  .DO67(DO[67]),  .DO68(DO[68]),  .DO69(DO[69]),  .DO70(DO[70]),  .DO71(DO[71]),
    .DO72(DO[72]),  .DO73(DO[73]),  .DO74(DO[74]),  .DO75(DO[75]),  .DO76(DO[76]),  .DO77(DO[77]),  .DO78(DO[78]),  .DO79(DO[79]),
    .DO80(DO[80]),  .DO81(DO[81]),  .DO82(DO[82]),  .DO83(DO[83]),  .DO84(DO[84]),  .DO85(DO[85]),  .DO86(DO[86]),  .DO87(DO[87]),
    .DO88(DO[88]),  .DO89(DO[89]),  .DO90(DO[90]),  .DO91(DO[91]),  .DO92(DO[92]),  .DO93(DO[93]),  .DO94(DO[94]),  .DO95(DO[95]),
    .DO96(DO[96]),  .DO97(DO[97]),  .DO98(DO[98]),  .DO99(DO[99]),  .DO100(DO[100]),.DO101(DO[101]),.DO102(DO[102]),.DO103(DO[103]),
    .DO104(DO[104]),.DO105(DO[105]),.DO106(DO[106]),.DO107(DO[107]),.DO108(DO[108]),.DO109(DO[109]),.DO110(DO[110]),.DO111(DO[111]),
    .DO112(DO[112]),.DO113(DO[113]),.DO114(DO[114]),.DO115(DO[115]),.DO116(DO[116]),.DO117(DO[117]),.DO118(DO[118]),.DO119(DO[119]),
    .DO120(DO[120]),.DO121(DO[121]),.DO122(DO[122]),.DO123(DO[123]),.DO124(DO[124]),.DO125(DO[125]),.DO126(DO[126]),.DO127(DO[127]),
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]),
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  .DI22(DI[22]),  .DI23(DI[23]),
    .DI24(DI[24]),  .DI25(DI[25]),  .DI26(DI[26]),  .DI27(DI[27]),  .DI28(DI[28]),  .DI29(DI[29]),  .DI30(DI[30]),  .DI31(DI[31]),
    .DI32(DI[32]),  .DI33(DI[33]),  .DI34(DI[34]),  .DI35(DI[35]),  .DI36(DI[36]),  .DI37(DI[37]),  .DI38(DI[38]),  .DI39(DI[39]),
    .DI40(DI[40]),  .DI41(DI[41]),  .DI42(DI[42]),  .DI43(DI[43]),  .DI44(DI[44]),  .DI45(DI[45]),  .DI46(DI[46]),  .DI47(DI[47]),
    .DI48(DI[48]),  .DI49(DI[49]),  .DI50(DI[50]),  .DI51(DI[51]),  .DI52(DI[52]),  .DI53(DI[53]),  .DI54(DI[54]),  .DI55(DI[55]),
    .DI56(DI[56]),  .DI57(DI[57]),  .DI58(DI[58]),  .DI59(DI[59]),  .DI60(DI[60]),  .DI61(DI[61]),  .DI62(DI[62]),  .DI63(DI[63]),
    .DI64(DI[64]),  .DI65(DI[65]),  .DI66(DI[66]),  .DI67(DI[67]),  .DI68(DI[68]),  .DI69(DI[69]),  .DI70(DI[70]),  .DI71(DI[71]),
    .DI72(DI[72]),  .DI73(DI[73]),  .DI74(DI[74]),  .DI75(DI[75]),  .DI76(DI[76]),  .DI77(DI[77]),  .DI78(DI[78]),  .DI79(DI[79]),
    .DI80(DI[80]),  .DI81(DI[81]),  .DI82(DI[82]),  .DI83(DI[83]),  .DI84(DI[84]),  .DI85(DI[85]),  .DI86(DI[86]),  .DI87(DI[87]),
    .DI88(DI[88]),  .DI89(DI[89]),  .DI90(DI[90]),  .DI91(DI[91]),  .DI92(DI[92]),  .DI93(DI[93]),  .DI94(DI[94]),  .DI95(DI[95]),
    .DI96(DI[96]),  .DI97(DI[97]),  .DI98(DI[98]),  .DI99(DI[99]),  .DI100(DI[100]),.DI101(DI[101]),.DI102(DI[102]),.DI103(DI[103]),
    .DI104(DI[104]),.DI105(DI[105]),.DI106(DI[106]),.DI107(DI[107]),.DI108(DI[108]),.DI109(DI[109]),.DI110(DI[110]),.DI111(DI[111]),
    .DI112(DI[112]),.DI113(DI[113]),.DI114(DI[114]),.DI115(DI[115]),.DI116(DI[116]),.DI117(DI[117]),.DI118(DI[118]),.DI119(DI[119]),
    .DI120(DI[120]),.DI121(DI[121]),.DI122(DI[122]),.DI123(DI[123]),.DI124(DI[124]),.DI125(DI[125]),.DI126(DI[126]),.DI127(DI[127]),
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

module SRAM_img_512_128 (
    input CLK, CS, OE, WEB,
    input [8:0]  A,
    input [127:0] DI,
    output[127:0] DO
);
SRAM_512x128 SRAM_512x128_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      .A8(A[8]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  .DO22(DO[22]),  .DO23(DO[23]), 
    .DO24(DO[24]),  .DO25(DO[25]),  .DO26(DO[26]),  .DO27(DO[27]),  .DO28(DO[28]),  .DO29(DO[29]),  .DO30(DO[30]),  .DO31(DO[31]),
    .DO32(DO[32]),  .DO33(DO[33]),  .DO34(DO[34]),  .DO35(DO[35]),  .DO36(DO[36]),  .DO37(DO[37]),  .DO38(DO[38]),  .DO39(DO[39]),
    .DO40(DO[40]),  .DO41(DO[41]),  .DO42(DO[42]),  .DO43(DO[43]),  .DO44(DO[44]),  .DO45(DO[45]),  .DO46(DO[46]),  .DO47(DO[47]),
    .DO48(DO[48]),  .DO49(DO[49]),  .DO50(DO[50]),  .DO51(DO[51]),  .DO52(DO[52]),  .DO53(DO[53]),  .DO54(DO[54]),  .DO55(DO[55]),
    .DO56(DO[56]),  .DO57(DO[57]),  .DO58(DO[58]),  .DO59(DO[59]),  .DO60(DO[60]),  .DO61(DO[61]),  .DO62(DO[62]),  .DO63(DO[63]),
    .DO64(DO[64]),  .DO65(DO[65]),  .DO66(DO[66]),  .DO67(DO[67]),  .DO68(DO[68]),  .DO69(DO[69]),  .DO70(DO[70]),  .DO71(DO[71]),
    .DO72(DO[72]),  .DO73(DO[73]),  .DO74(DO[74]),  .DO75(DO[75]),  .DO76(DO[76]),  .DO77(DO[77]),  .DO78(DO[78]),  .DO79(DO[79]),
    .DO80(DO[80]),  .DO81(DO[81]),  .DO82(DO[82]),  .DO83(DO[83]),  .DO84(DO[84]),  .DO85(DO[85]),  .DO86(DO[86]),  .DO87(DO[87]),
    .DO88(DO[88]),  .DO89(DO[89]),  .DO90(DO[90]),  .DO91(DO[91]),  .DO92(DO[92]),  .DO93(DO[93]),  .DO94(DO[94]),  .DO95(DO[95]),
    .DO96(DO[96]),  .DO97(DO[97]),  .DO98(DO[98]),  .DO99(DO[99]),  .DO100(DO[100]),.DO101(DO[101]),.DO102(DO[102]),.DO103(DO[103]),
    .DO104(DO[104]),.DO105(DO[105]),.DO106(DO[106]),.DO107(DO[107]),.DO108(DO[108]),.DO109(DO[109]),.DO110(DO[110]),.DO111(DO[111]),
    .DO112(DO[112]),.DO113(DO[113]),.DO114(DO[114]),.DO115(DO[115]),.DO116(DO[116]),.DO117(DO[117]),.DO118(DO[118]),.DO119(DO[119]),
    .DO120(DO[120]),.DO121(DO[121]),.DO122(DO[122]),.DO123(DO[123]),.DO124(DO[124]),.DO125(DO[125]),.DO126(DO[126]),.DO127(DO[127]),
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]),
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  .DI22(DI[22]),  .DI23(DI[23]),
    .DI24(DI[24]),  .DI25(DI[25]),  .DI26(DI[26]),  .DI27(DI[27]),  .DI28(DI[28]),  .DI29(DI[29]),  .DI30(DI[30]),  .DI31(DI[31]),
    .DI32(DI[32]),  .DI33(DI[33]),  .DI34(DI[34]),  .DI35(DI[35]),  .DI36(DI[36]),  .DI37(DI[37]),  .DI38(DI[38]),  .DI39(DI[39]),
    .DI40(DI[40]),  .DI41(DI[41]),  .DI42(DI[42]),  .DI43(DI[43]),  .DI44(DI[44]),  .DI45(DI[45]),  .DI46(DI[46]),  .DI47(DI[47]),
    .DI48(DI[48]),  .DI49(DI[49]),  .DI50(DI[50]),  .DI51(DI[51]),  .DI52(DI[52]),  .DI53(DI[53]),  .DI54(DI[54]),  .DI55(DI[55]),
    .DI56(DI[56]),  .DI57(DI[57]),  .DI58(DI[58]),  .DI59(DI[59]),  .DI60(DI[60]),  .DI61(DI[61]),  .DI62(DI[62]),  .DI63(DI[63]),
    .DI64(DI[64]),  .DI65(DI[65]),  .DI66(DI[66]),  .DI67(DI[67]),  .DI68(DI[68]),  .DI69(DI[69]),  .DI70(DI[70]),  .DI71(DI[71]),
    .DI72(DI[72]),  .DI73(DI[73]),  .DI74(DI[74]),  .DI75(DI[75]),  .DI76(DI[76]),  .DI77(DI[77]),  .DI78(DI[78]),  .DI79(DI[79]),
    .DI80(DI[80]),  .DI81(DI[81]),  .DI82(DI[82]),  .DI83(DI[83]),  .DI84(DI[84]),  .DI85(DI[85]),  .DI86(DI[86]),  .DI87(DI[87]),
    .DI88(DI[88]),  .DI89(DI[89]),  .DI90(DI[90]),  .DI91(DI[91]),  .DI92(DI[92]),  .DI93(DI[93]),  .DI94(DI[94]),  .DI95(DI[95]),
    .DI96(DI[96]),  .DI97(DI[97]),  .DI98(DI[98]),  .DI99(DI[99]),  .DI100(DI[100]),.DI101(DI[101]),.DI102(DI[102]),.DI103(DI[103]),
    .DI104(DI[104]),.DI105(DI[105]),.DI106(DI[106]),.DI107(DI[107]),.DI108(DI[108]),.DI109(DI[109]),.DI110(DI[110]),.DI111(DI[111]),
    .DI112(DI[112]),.DI113(DI[113]),.DI114(DI[114]),.DI115(DI[115]),.DI116(DI[116]),.DI117(DI[117]),.DI118(DI[118]),.DI119(DI[119]),
    .DI120(DI[120]),.DI121(DI[121]),.DI122(DI[122]),.DI123(DI[123]),.DI124(DI[124]),.DI125(DI[125]),.DI126(DI[126]),.DI127(DI[127]),
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

module SRAM_96_64 (
    input CLK, CS, OE, WEB,
    input [6:0]  A,
    input [63:0] DI,
    output[63:0] DO
);
SRAM_96x64 SRAM_96x64_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  .DO22(DO[22]),  .DO23(DO[23]), 
    .DO24(DO[24]),  .DO25(DO[25]),  .DO26(DO[26]),  .DO27(DO[27]),  .DO28(DO[28]),  .DO29(DO[29]),  .DO30(DO[30]),  .DO31(DO[31]),
    .DO32(DO[32]),  .DO33(DO[33]),  .DO34(DO[34]),  .DO35(DO[35]),  .DO36(DO[36]),  .DO37(DO[37]),  .DO38(DO[38]),  .DO39(DO[39]),
    .DO40(DO[40]),  .DO41(DO[41]),  .DO42(DO[42]),  .DO43(DO[43]),  .DO44(DO[44]),  .DO45(DO[45]),  .DO46(DO[46]),  .DO47(DO[47]),
    .DO48(DO[48]),  .DO49(DO[49]),  .DO50(DO[50]),  .DO51(DO[51]),  .DO52(DO[52]),  .DO53(DO[53]),  .DO54(DO[54]),  .DO55(DO[55]),
    .DO56(DO[56]),  .DO57(DO[57]),  .DO58(DO[58]),  .DO59(DO[59]),  .DO60(DO[60]),  .DO61(DO[61]),  .DO62(DO[62]),  .DO63(DO[63]),
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]),
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  .DI22(DI[22]),  .DI23(DI[23]),
    .DI24(DI[24]),  .DI25(DI[25]),  .DI26(DI[26]),  .DI27(DI[27]),  .DI28(DI[28]),  .DI29(DI[29]),  .DI30(DI[30]),  .DI31(DI[31]),
    .DI32(DI[32]),  .DI33(DI[33]),  .DI34(DI[34]),  .DI35(DI[35]),  .DI36(DI[36]),  .DI37(DI[37]),  .DI38(DI[38]),  .DI39(DI[39]),
    .DI40(DI[40]),  .DI41(DI[41]),  .DI42(DI[42]),  .DI43(DI[43]),  .DI44(DI[44]),  .DI45(DI[45]),  .DI46(DI[46]),  .DI47(DI[47]),
    .DI48(DI[48]),  .DI49(DI[49]),  .DI50(DI[50]),  .DI51(DI[51]),  .DI52(DI[52]),  .DI53(DI[53]),  .DI54(DI[54]),  .DI55(DI[55]),
    .DI56(DI[56]),  .DI57(DI[57]),  .DI58(DI[58]),  .DI59(DI[59]),  .DI60(DI[60]),  .DI61(DI[61]),  .DI62(DI[62]),  .DI63(DI[63]),
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule
/*
module SRAM_debg_512_128 (
    input CLK, CS, OE, WEB,
    input [8:0]  A,
    input [127:0] DI,
    output[127:0] DO
);
SRAM_512x128 SRAM_512x128_inst (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      .A8(A[8]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  .DO12(DO[12]),  .DO13(DO[13]),  .DO14(DO[14]),  .DO15(DO[15]), 
    .DO16(DO[16]),  .DO17(DO[17]),  .DO18(DO[18]),  .DO19(DO[19]),  .DO20(DO[20]),  .DO21(DO[21]),  .DO22(DO[22]),  .DO23(DO[23]), 
    .DO24(DO[24]),  .DO25(DO[25]),  .DO26(DO[26]),  .DO27(DO[27]),  .DO28(DO[28]),  .DO29(DO[29]),  .DO30(DO[30]),  .DO31(DO[31]),
    .DO32(DO[32]),  .DO33(DO[33]),  .DO34(DO[34]),  .DO35(DO[35]),  .DO36(DO[36]),  .DO37(DO[37]),  .DO38(DO[38]),  .DO39(DO[39]),
    .DO40(DO[40]),  .DO41(DO[41]),  .DO42(DO[42]),  .DO43(DO[43]),  .DO44(DO[44]),  .DO45(DO[45]),  .DO46(DO[46]),  .DO47(DO[47]),
    .DO48(DO[48]),  .DO49(DO[49]),  .DO50(DO[50]),  .DO51(DO[51]),  .DO52(DO[52]),  .DO53(DO[53]),  .DO54(DO[54]),  .DO55(DO[55]),
    .DO56(DO[56]),  .DO57(DO[57]),  .DO58(DO[58]),  .DO59(DO[59]),  .DO60(DO[60]),  .DO61(DO[61]),  .DO62(DO[62]),  .DO63(DO[63]),
    .DO64(DO[64]),  .DO65(DO[65]),  .DO66(DO[66]),  .DO67(DO[67]),  .DO68(DO[68]),  .DO69(DO[69]),  .DO70(DO[70]),  .DO71(DO[71]),
    .DO72(DO[72]),  .DO73(DO[73]),  .DO74(DO[74]),  .DO75(DO[75]),  .DO76(DO[76]),  .DO77(DO[77]),  .DO78(DO[78]),  .DO79(DO[79]),
    .DO80(DO[80]),  .DO81(DO[81]),  .DO82(DO[82]),  .DO83(DO[83]),  .DO84(DO[84]),  .DO85(DO[85]),  .DO86(DO[86]),  .DO87(DO[87]),
    .DO88(DO[88]),  .DO89(DO[89]),  .DO90(DO[90]),  .DO91(DO[91]),  .DO92(DO[92]),  .DO93(DO[93]),  .DO94(DO[94]),  .DO95(DO[95]),
    .DO96(DO[96]),  .DO97(DO[97]),  .DO98(DO[98]),  .DO99(DO[99]),  .DO100(DO[100]),.DO101(DO[101]),.DO102(DO[102]),.DO103(DO[103]),
    .DO104(DO[104]),.DO105(DO[105]),.DO106(DO[106]),.DO107(DO[107]),.DO108(DO[108]),.DO109(DO[109]),.DO110(DO[110]),.DO111(DO[111]),
    .DO112(DO[112]),.DO113(DO[113]),.DO114(DO[114]),.DO115(DO[115]),.DO116(DO[116]),.DO117(DO[117]),.DO118(DO[118]),.DO119(DO[119]),
    .DO120(DO[120]),.DO121(DO[121]),.DO122(DO[122]),.DO123(DO[123]),.DO124(DO[124]),.DO125(DO[125]),.DO126(DO[126]),.DO127(DO[127]),
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  .DI12(DI[12]),  .DI13(DI[13]),  .DI14(DI[14]),  .DI15(DI[15]),
    .DI16(DI[16]),  .DI17(DI[17]),  .DI18(DI[18]),  .DI19(DI[19]),  .DI20(DI[20]),  .DI21(DI[21]),  .DI22(DI[22]),  .DI23(DI[23]),
    .DI24(DI[24]),  .DI25(DI[25]),  .DI26(DI[26]),  .DI27(DI[27]),  .DI28(DI[28]),  .DI29(DI[29]),  .DI30(DI[30]),  .DI31(DI[31]),
    .DI32(DI[32]),  .DI33(DI[33]),  .DI34(DI[34]),  .DI35(DI[35]),  .DI36(DI[36]),  .DI37(DI[37]),  .DI38(DI[38]),  .DI39(DI[39]),
    .DI40(DI[40]),  .DI41(DI[41]),  .DI42(DI[42]),  .DI43(DI[43]),  .DI44(DI[44]),  .DI45(DI[45]),  .DI46(DI[46]),  .DI47(DI[47]),
    .DI48(DI[48]),  .DI49(DI[49]),  .DI50(DI[50]),  .DI51(DI[51]),  .DI52(DI[52]),  .DI53(DI[53]),  .DI54(DI[54]),  .DI55(DI[55]),
    .DI56(DI[56]),  .DI57(DI[57]),  .DI58(DI[58]),  .DI59(DI[59]),  .DI60(DI[60]),  .DI61(DI[61]),  .DI62(DI[62]),  .DI63(DI[63]),
    .DI64(DI[64]),  .DI65(DI[65]),  .DI66(DI[66]),  .DI67(DI[67]),  .DI68(DI[68]),  .DI69(DI[69]),  .DI70(DI[70]),  .DI71(DI[71]),
    .DI72(DI[72]),  .DI73(DI[73]),  .DI74(DI[74]),  .DI75(DI[75]),  .DI76(DI[76]),  .DI77(DI[77]),  .DI78(DI[78]),  .DI79(DI[79]),
    .DI80(DI[80]),  .DI81(DI[81]),  .DI82(DI[82]),  .DI83(DI[83]),  .DI84(DI[84]),  .DI85(DI[85]),  .DI86(DI[86]),  .DI87(DI[87]),
    .DI88(DI[88]),  .DI89(DI[89]),  .DI90(DI[90]),  .DI91(DI[91]),  .DI92(DI[92]),  .DI93(DI[93]),  .DI94(DI[94]),  .DI95(DI[95]),
    .DI96(DI[96]),  .DI97(DI[97]),  .DI98(DI[98]),  .DI99(DI[99]),  .DI100(DI[100]),.DI101(DI[101]),.DI102(DI[102]),.DI103(DI[103]),
    .DI104(DI[104]),.DI105(DI[105]),.DI106(DI[106]),.DI107(DI[107]),.DI108(DI[108]),.DI109(DI[109]),.DI110(DI[110]),.DI111(DI[111]),
    .DI112(DI[112]),.DI113(DI[113]),.DI114(DI[114]),.DI115(DI[115]),.DI116(DI[116]),.DI117(DI[117]),.DI118(DI[118]),.DI119(DI[119]),
    .DI120(DI[120]),.DI121(DI[121]),.DI122(DI[122]),.DI123(DI[123]),.DI124(DI[124]),.DI125(DI[125]),.DI126(DI[126]),.DI127(DI[127]),
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule*/


