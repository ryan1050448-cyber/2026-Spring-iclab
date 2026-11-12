module CDNA(
    // Input Port
    clk,
    rst_n,
    instruction_in_valid,
    image_in_valid,
    weight_in_valid,
    in_data,
    
    // Output Port
    out_valid,
    out_data
);

input         clk;
input         rst_n;
input         instruction_in_valid;
input         image_in_valid;
input         weight_in_valid;
input  [31:0] in_data;

output reg        out_valid;
output reg [31:0] out_data;

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

//Example DW code
//DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type, inst_arch, inst_faithful_round) u_add(.a(add_in_a), .b(add_in_b), .z(add_out), .status(add_status), .rnd(rnd));
//Example DW code

reg next_out_valid, image_in_valid_buf, next_image_in_valid_buf, mm_valid, next_mm_valid;
reg [31:0] next_out_data;
reg [2:0] instruction, next_instruction;
reg [31:0] wt1 [0:8], next_wt1 [0:8], wt2 [0:8], next_wt2 [0:8], wt3 [0:8], next_wt3 [0:8], wt4 [0:8], next_wt4 [0:8];
reg [31:0] wt5 [0:8], next_wt5 [0:8], wt6 [0:8], next_wt6 [0:8], wt7 [0:8], next_wt7 [0:8], wt8 [0:8], next_wt8 [0:8];
reg [31:0] wt9 [0:8], next_wt9 [0:8], wt10 [0:8], next_wt10 [0:8], wt11 [0:8], next_wt11 [0:8], wt12 [0:8], next_wt12 [0:8];
reg [31:0] wt13 [0:8], next_wt13 [0:8], wt14 [0:8], next_wt14 [0:8], wt15 [0:8], next_wt15 [0:8], wt16 [0:8], next_wt16 [0:8];
reg [31:0] img1 [0:7][0:7], next_img1 [0:7][0:7], img2 [0:7][0:7], next_img2 [0:7][0:7];
reg [31:0] maxc1, next_maxc1, minc1, next_minc1, maxc2, next_maxc2, minc2, next_minc2;
reg [8:0] in_ct, next_in_ct, count, next_count;
reg [3:0] scale_ct, next_scale_ct;
reg [31:0] img1_vec[0:63], img2_vec[0:63];
reg [31:0] reciprocal1, next_reciprocal1, reciprocal2, next_reciprocal2, reciprocal, minc;
//reg conv_out_valid1, next_conv_out_valid1, conv_out_valid2, next_conv_out_valid2;
reg [1:0] index81 [0:15], next_index81 [0:15], index82 [0:15], next_index82 [0:15], index41 [0:3], next_index41 [0:3], index42 [0:3], next_index42 [0:3];
reg [31:0] conv01_array [0:63], next_conv01_array [0:63], conv02_array [0:63], next_conv02_array [0:63];
//reg [31:0] deconv11_array [0:63], next_deconv11_array [0:63], deconv12_array [0:63], next_deconv12_array [0:63];
//reg [31:0] deconv01_array [0:15], next_deconv01_array [0:15], deconv02_array [0:15], next_deconv02_array [0:15];
reg [31:0] conv11_array [0:15], next_conv11_array [0:15], conv12_array [0:15], next_conv12_array [0:15];
reg [7:0] out_ct, next_out_ct;
reg start_out, next_start_out;
//selection
reg [31:0] conv01_img1_sel [0:8], conv01_img2_sel [0:8];
reg [31:0] conv01_k1_sel [0:8], conv01_k2_sel [0:8];
reg conv01_valid, conv02_valid;
reg [31:0] cpa1, cpb1, cpa2, cpb2, cpa3, cpb3, cpa4, cpb4;
reg [31:0] mp01_array [0:3][0:3], next_mp01_array [0:3][0:3], mp02_array [0:3][0:3], next_mp02_array [0:3][0:3];
reg [31:0] mp11_array [0:1][0:1], next_mp11_array [0:1][0:1], mp12_array [0:1][0:1], next_mp12_array [0:1][0:1];
reg act_valid1, next_act_valid1;
reg [31:0] data_in1, data_in2;
reg [6:0] cct, next_cct, cct2, next_cct2;
reg [31:0] c01_vec[0:15], next_c01_vec[0:15], c02_vec[0:15], next_c02_vec[0:15];
reg [31:0] c11_vec[0:3], next_c11_vec[0:3], c12_vec[0:3], next_c12_vec[0:3];
//reg [31:0] c01_array [0:3][0:3], next_c01_array [0:3][0:3], c02_array [0:3][0:3], next_c02_array [0:3][0:3];
//reg [31:0] dc01_vec[0:15], next_dc01_vec[0:15], dc02_vec[0:15], next_dc02_vec[0:15];
reg [31:0] dc11_vec[0:63], next_dc11_vec[0:63], dc12_vec[0:63], next_dc12_vec[0:63];
reg [31:0] mms_sub1, next_mms_sub1, mms_sub2, next_mms_sub2;
reg [31:0] upl_out1 [0:15], next_upl_out1 [0:15], upl_out2 [0:15], next_upl_out2 [0:15], upl_out3 [0:63], next_upl_out3 [0:63], upl_out4 [0:63], next_upl_out4 [0:63];
reg [31:0] img1_pad10 [0:9][0:9], img2_pad10 [0:9][0:9], img1_pad6 [0:5][0:5], img2_pad6 [0:5][0:5];
reg [3:0] ki, next_ki, kj, next_kj;
reg [6:0] ar_ct, next_ar_ct;

wire conv_out_valid01, conv_out_valid02, conv_out_valid11, conv_out_valid12;
wire deconv_out_valid01, deconv_out_valid02, deconv_out_valid11, deconv_out_valid12;
wire [31:0] conv_out_data01;
wire [31:0] deconv_out_data01 [0:15], deconv_out_data02 [0:15], deconv_out_data11 [0:63], deconv_out_data12 [0:63];
wire [1:0] index8_list1 [0:15], index4_list1 [0:3], index8_list2 [0:15], index4_list2 [0:3];
wire [31:0] unpool_out1 [0:15], unpool_out2 [0:15], unpool_out3 [0:63], unpool_out4 [0:63];
wire [1:0] idx1, idx2;
wire act_out_valid1, act_out_valid2;
wire [31:0] data_out1, data_out2;
wire [31:0] cp3, cp4;
//fp comparator
wire altb0, agtb0, aeqb0, unordered0, altb1, agtb1, aeqb1, unordered1;
wire [7:0] status00, status10, status01, status11;
wire [31:0] z0_inst0, z1_inst0, z0_inst1, z1_inst1;
reg [31:0] a_inst0, a_inst1, b_inst0, b_inst1;
//fp subtractor
reg [31:0] p1, p2, p3, p4, p5, p6, p7, p8;
wire [31:0] sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8;
wire [31:0] mm_sub1, mm_sub2;
//fp divider
wire [31:0] div_out1, div_out2;

wire [7:0] sts1, sts2, sts3, sts4;

integer i, j;

//input
always @(*)
begin
    for (i = 0; i < 9; i = i + 1)
    begin
        next_wt1[i] = wt1[i];
        next_wt2[i] = wt2[i];
        next_wt3[i] = wt3[i];
        next_wt4[i] = wt4[i];
        next_wt5[i] = wt5[i];
        next_wt6[i] = wt6[i];
        next_wt7[i] = wt7[i];
        next_wt8[i] = wt8[i];
        next_wt9[i] = wt9[i];
        next_wt10[i] = wt10[i];
        next_wt11[i] = wt11[i];
        next_wt12[i] = wt12[i];
        next_wt13[i] = wt13[i];
        next_wt14[i] = wt14[i];
        next_wt15[i] = wt15[i];
        next_wt16[i] = wt16[i];
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            next_img1[i][j] = img1[i][j];
            next_img2[i][j] = img2[i][j];
        end
    end
    next_instruction = instruction;
    next_image_in_valid_buf = image_in_valid_buf;

    if(image_in_valid)
        next_image_in_valid_buf = 1;
    else if(in_ct == 137)
        next_image_in_valid_buf = 0;
    
    if(instruction_in_valid)
    begin
        next_instruction = in_data[2:0];
    end
    else if(weight_in_valid)
    begin
        if(in_ct < 9) //0-8
        begin
            next_wt1[8] = in_data;
            next_wt1[0:7] = wt1[1:8];
        end
        else if(in_ct < 18) //9-17
        begin
            next_wt2[8] = in_data;
            next_wt2[0:7] = wt2[1:8];
        end
        else if(in_ct < 27) //18-26
        begin
            next_wt3[8] = in_data;
            next_wt3[0:7] = wt3[1:8];
        end
        else if(in_ct < 36) //27-35
        begin
            next_wt4[8] = in_data;
            next_wt4[0:7] = wt4[1:8];
        end
        else if(in_ct < 45) //36-44
        begin
            next_wt5[8] = in_data;
            next_wt5[0:7] = wt5[1:8];
        end
        else if(in_ct < 54) //45-53
        begin
            next_wt6[8] = in_data;
            next_wt6[0:7] = wt6[1:8];
        end
        else if(in_ct < 63) //54-62
        begin
            next_wt7[8] = in_data;
            next_wt7[0:7] = wt7[1:8];
        end
        else if(in_ct < 72) //63-71
        begin
            next_wt8[8] = in_data;
            next_wt8[0:7] = wt8[1:8];
        end
        else if(in_ct < 81) //72-80
        begin
            next_wt9[8] = in_data;
            next_wt9[0:7] = wt9[1:8];
        end
        else if(in_ct < 90) //81-89
        begin
            next_wt10[8] = in_data;
            next_wt10[0:7] = wt10[1:8];
        end
        else if(in_ct < 99) //90-98
        begin
            next_wt11[8] = in_data;
            next_wt11[0:7] = wt11[1:8];
        end
        else if(in_ct < 108) //99-107
        begin
            next_wt12[8] = in_data;
            next_wt12[0:7] = wt12[1:8];
        end
        else if(in_ct < 117) //108-116
        begin
            next_wt13[8] = in_data;
            next_wt13[0:7] = wt13[1:8];
        end
        else if(in_ct < 126) //117-125
        begin
            next_wt14[8] = in_data;
            next_wt14[0:7] = wt14[1:8];
        end
        else if(in_ct < 135) //126-134
        begin
            next_wt15[8] = in_data;
            next_wt15[0:7] = wt15[1:8];
        end
        else if(in_ct < 144) //135-143
        begin
            next_wt16[8] = in_data;
            next_wt16[0:7] = wt16[1:8];
        end
    end
    else if(image_in_valid)
    begin
        if(in_ct < 64) //0-63
        begin
            for (i = 0; i < 7; i = i + 1)
            begin
                next_img1[i][0:6] = img1[i][1:7];
                next_img1[i][7] = img1[i+1][0];
            end
            next_img1[7][0:6] = img1[7][1:7];
            next_img1[7][7] = in_data;
        end
        else if(in_ct < 128) //64-127
        begin
            for (i = 0; i < 7; i = i + 1)
            begin
                next_img2[i][0:6] = img2[i][1:7];
                next_img2[i][7] = img2[i+1][0];
            end
            next_img2[7][0:6] = img2[7][1:7];
            next_img2[7][7] = in_data;
        end
    end

    if(mm_valid)
    begin
        if(in_ct >= 67 && in_ct <= 74) //67-74
        begin
            next_img1[scale_ct][0] = sp1;
            next_img1[scale_ct][1] = sp2;
            next_img1[scale_ct][2] = sp3;
            next_img1[scale_ct][3] = sp4;
            next_img1[scale_ct][4] = sp5;
            next_img1[scale_ct][5] = sp6;
            next_img1[scale_ct][6] = sp7;
            next_img1[scale_ct][7] = sp8;
        end
        else if(in_ct >= 131 && in_ct <= 138) //131-138
        begin
            next_img2[scale_ct][0] = sp1;
            next_img2[scale_ct][1] = sp2;
            next_img2[scale_ct][2] = sp3;
            next_img2[scale_ct][3] = sp4;
            next_img2[scale_ct][4] = sp5;
            next_img2[scale_ct][5] = sp6;
            next_img2[scale_ct][6] = sp7;
            next_img2[scale_ct][7] = sp8;
        end
    end
end
//ct
always @(*)
begin
    next_in_ct = in_ct;
    next_count = count;

    if(weight_in_valid)
        next_in_ct = in_ct + 1;
    else if(image_in_valid || in_ct == 128 || in_ct == 129 || in_ct == 130)
    begin
        next_in_ct = in_ct + 1;
    end
    else if(mm_valid)
        next_in_ct = in_ct + 1;
    else
        next_in_ct = 0;

    if(in_ct == 138 && !weight_in_valid)
        next_count = count + 1;
    if (count != 0)
        next_count = count + 1;
    if(out_valid)
        next_count = 0;
end

DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp0(.a(a_inst0), .b(b_inst0), .zctr(1'b0), .aeqb(aeqb0), .altb(altb0), .agtb(agtb0), .unordered(unordered0), .z0(z0_inst0), .z1(z1_inst0), .status0(status00), .status1(status10));
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp1(.a(a_inst1), .b(b_inst1), .zctr(1'b0), .aeqb(aeqb1), .altb(altb1), .agtb(agtb1), .unordered(unordered1), .z0(z0_inst1), .z1(z1_inst1), .status0(status01), .status1(status11));

DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_sub(.a(maxc1), .b(minc1), .rnd(3'd0), .z(mm_sub1), .status(sts1));
DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_sub2(.a(maxc2), .b(minc2), .rnd(3'd0), .z(mm_sub2), .status(sts2));
DW_fp_div #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_faithful_round) u_div1(.a(32'h3f800000), .b(mms_sub1), .rnd(3'd0), .z(div_out1), .status(sts3));
DW_fp_div #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_faithful_round) u_div2(.a(32'h3f800000), .b(mms_sub2), .rnd(3'd0), .z(div_out2), .status(sts4));

MM_SCALE u_mm_scale0(.pixel(p1), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp1));
MM_SCALE u_mm_scale1(.pixel(p2), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp2));
MM_SCALE u_mm_scale2(.pixel(p3), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp3));
MM_SCALE u_mm_scale3(.pixel(p4), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp4));
MM_SCALE u_mm_scale4(.pixel(p5), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp5));
MM_SCALE u_mm_scale5(.pixel(p6), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp6));
MM_SCALE u_mm_scale6(.pixel(p7), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp7));
MM_SCALE u_mm_scale7(.pixel(p8), .minc(minc), .reciprocal(reciprocal), .mm_valid(mm_valid), .scaled_pixel(sp8));

//maxc, minc
always @(*)
begin
    next_maxc1 = maxc1;
    next_minc1 = minc1;
    next_maxc2 = maxc2;
    next_minc2 = minc2;
    a_inst0 = 0;
    a_inst1 = 0;
    b_inst0 = 0;
    b_inst1 = 0;
    next_mm_valid = mm_valid;
    next_scale_ct = scale_ct;
    next_reciprocal1 = reciprocal1;
    next_reciprocal2 = reciprocal2;
    minc = 0;
    reciprocal = 0;
    p1 = 0;
    p2 = 0;
    p3 = 0;
    p4 = 0;
    p5 = 0;
    p6 = 0;
    p7 = 0;
    p8 = 0;
    next_mms_sub1 = mms_sub1;
    next_mms_sub2 = mms_sub2;

    if(instruction_in_valid)
    begin
        next_maxc1 = 32'h00000000;
        next_minc1 = 32'h7f7fffff;
        next_maxc2 = 32'h00000000;
        next_minc2 = 32'h7f7fffff;
    end

    if(image_in_valid_buf && (in_ct >= 1 && in_ct <= 64))
    begin
        a_inst0 = img1[7][7];
        b_inst0 = maxc1;
        next_maxc1 = z1_inst0;
        a_inst1 = img1[7][7];
        b_inst1 = minc1;
        next_minc1 = z0_inst1;
    end
    else if(image_in_valid_buf && (in_ct >= 65 && in_ct <= 128))
    begin
        a_inst0 = img2[7][7];
        b_inst0 = maxc2;
        next_maxc2 = z1_inst0;
        a_inst1 = img2[7][7];
        b_inst1 = minc2;
        next_minc2 = z0_inst1;
    end

    if(in_ct == 65)
    begin
        next_mms_sub1 = mm_sub1;
        next_mms_sub2 = mm_sub2;
    end
    if(in_ct == 66)
    begin
        next_reciprocal1 = div_out1;
    end

    if(in_ct == 129)
    begin
        next_mms_sub1 = mm_sub1;
        next_mms_sub2 = mm_sub2;
    end
    if(in_ct == 130)
    begin
        next_reciprocal2 = div_out2;
    end

    if(image_in_valid_buf && in_ct == 66)//67-74
        next_mm_valid = 1;
    else if(image_in_valid_buf && in_ct == 74)
        next_mm_valid = 0;
    else if(image_in_valid_buf && in_ct == 130)//131-138
        next_mm_valid = 1;
    else if(in_ct == 138)
        next_mm_valid = 0;

    if(mm_valid)
    begin
        if(in_ct >= 67 && in_ct <= 74)//67-74
        begin
            p1 = img1[scale_ct][0];
            p2 = img1[scale_ct][1];
            p3 = img1[scale_ct][2];
            p4 = img1[scale_ct][3];
            p5 = img1[scale_ct][4];
            p6 = img1[scale_ct][5];
            p7 = img1[scale_ct][6];
            p8 = img1[scale_ct][7];
            minc = minc1;
            reciprocal = reciprocal1;
            next_scale_ct = scale_ct + 1;
        end
        else if(in_ct >= 131 && in_ct <= 138)//131-138
        begin
            p1 = img2[scale_ct][0];
            p2 = img2[scale_ct][1];
            p3 = img2[scale_ct][2];
            p4 = img2[scale_ct][3];
            p5 = img2[scale_ct][4];
            p6 = img2[scale_ct][5];
            p7 = img2[scale_ct][6];
            p8 = img2[scale_ct][7];
            minc = minc2;
            reciprocal = reciprocal2;
            next_scale_ct = scale_ct + 1;
        end
    end
    else
    begin
        p1 = 0;
        p2 = 0;
        p3 = 0;
        p4 = 0;
        p5 = 0;
        p6 = 0;
        p7 = 0;
        p8 = 0;
    end

    if(scale_ct == 7)
        next_scale_ct = 0;
end
// image padding
always @(*)
begin
    for (i = 0; i < 10; i = i + 1)
    begin
        for (j = 0; j < 10; j = j + 1)
        begin
            img1_pad10[i][j] = 0;
            img2_pad10[i][j] = 0;
        end
    end
    for (i = 0; i < 6; i = i + 1)
    begin
        for (j = 0; j < 6; j = j + 1)
        begin
            img1_pad6[i][j] = 0;
            img2_pad6[i][j] = 0;
        end
    end

    if(count >= 1 && count <= 141)//1-70, 72-141
    begin
        for (i = 0; i < 10; i = i + 1)
        begin
            for (j = 0; j < 10; j = j + 1)
            begin
                if(i >= 1 && i <= 8 && j >= 1 && j <= 8)
                begin
                    img1_pad10[i][j] = img1[i-1][j-1];
                    img2_pad10[i][j] = img2[i-1][j-1];
                end
                else
                begin
                    if(instruction[2] == 0)//zero padding
                    begin
                        img1_pad10[i][j] = 0;
                        img2_pad10[i][j] = 0;
                    end
                end
            end
        end
        if(instruction[2] == 1)//reflication padding
        begin
            img1_pad10[0][0] = img1[0][0];
            img1_pad10[0][1:8] = img1[0][0:7];
            img1_pad10[0][9] = img1[0][7];
            img1_pad10[9][0] = img1[7][0];
            img1_pad10[9][1:8] = img1[7][0:7];
            img1_pad10[9][9] = img1[7][7];
            for(i = 1; i < 9; i = i + 1)
            begin
                img1_pad10[i][0] = img1[i-1][0];
                img1_pad10[i][9] = img1[i-1][7];
            end
            img2_pad10[0][0] = img2[0][0];
            img2_pad10[0][1:8] = img2[0][0:7];
            img2_pad10[0][9] = img2[0][7];
            img2_pad10[9][0] = img2[7][0];
            img2_pad10[9][1:8] = img2[7][0:7];
            img2_pad10[9][9] = img2[7][7];
            for(i = 1; i < 9; i = i + 1)
            begin
                img2_pad10[i][0] = img2[i-1][0];
                img2_pad10[i][9] = img2[i-1][7];
            end
        end
    end

    if(count >= 151 && count <= 195)//151-172, 174-195
    begin
        for (i = 0; i < 6; i = i + 1)
        begin
            for (j = 0; j < 6; j = j + 1)
            begin
                if(i >= 1 && i <= 4 && j >= 1 && j <= 4)
                begin
                    //img1_pad6[i][j] = c01_vec[i-1][j-1];
                    //img2_pad6[i][j] = c02_vec[i-1][j-1];
                    img1_pad6[i][j] = c01_vec[(i-1)*4+(j-1)];
                    img2_pad6[i][j] = c02_vec[(i-1)*4+(j-1)];
                end
                else
                begin
                    if(instruction[2] == 0)//zero padding
                    begin
                        img1_pad6[i][j] = 0;
                        img2_pad6[i][j] = 0;
                    end
                end
            end
        end
        if(instruction[2] == 1)//reflication padding
        begin
            /*img1_pad6[0][0] = c01_vec[0][0];
            img1_pad6[0][1:4] = c01_vec[0][0:3];
            img1_pad6[0][5] = c01_vec[0][3];
            img1_pad6[5][0] = c01_vec[3][0];
            img1_pad6[5][1:4] = c01_vec[3][0:3];
            img1_pad6[5][5] = c01_vec[3][3];*/
            img1_pad6[0][0] = c01_vec[0];
            img1_pad6[0][1:4] = c01_vec[0:3];
            img1_pad6[0][5] = c01_vec[3];
            img1_pad6[5][0] = c01_vec[12];
            img1_pad6[5][1:4] = c01_vec[12:15];
            img1_pad6[5][5] = c01_vec[15];
            for(i = 1; i < 5; i = i + 1)
            begin
                img1_pad6[i][0] = c01_vec[(i-1)*4];
                img1_pad6[i][5] = c01_vec[(i-1)*4 + 3];
            end
            /*img2_pad6[0][0] = c02_vec[0][0];
            img2_pad6[0][1:4] = c02_vec[0][0:3];
            img2_pad6[0][5] = c02_vec[0][3];
            img2_pad6[5][0] = c02_vec[3][0];
            img2_pad6[5][1:4] = c02_vec[3][0:3];
            img2_pad6[5][5] = c02_vec[3][3];*/
            img2_pad6[0][0] = c02_vec[0];
            img2_pad6[0][1:4] = c02_vec[0:3];
            img2_pad6[0][5] = c02_vec[3];
            img2_pad6[5][0] = c02_vec[12];
            img2_pad6[5][1:4] = c02_vec[12:15];
            img2_pad6[5][5] = c02_vec[15];
            for(i = 1; i < 5; i = i + 1)
            begin
                /*img2_pad6[i][0] = c02_vec[i-1][0];
                img2_pad6[i][5] = c02_vec[i-1][3];*/
                img2_pad6[i][0] = c02_vec[(i-1)*4];
                img2_pad6[i][5] = c02_vec[(i-1)*4 + 3];
            end
        end
    end
    if(count >= 205 && count <= 249)//205-226, 228-249
    begin
        for (i = 0; i < 6; i = i + 1)
        begin
            for (j = 0; j < 6; j = j + 1)
            begin
                if(i >= 1 && i <= 4 && j >= 1 && j <= 4)
                begin
                    //img1_pad6[i][j] = upl_out1[i-1][j-1];
                    //img2_pad6[i][j] = upl_out2[i-1][j-1];
                    img1_pad6[i][j] = upl_out1[(i-1)*4+(j-1)];
                    img2_pad6[i][j] = upl_out2[(i-1)*4+(j-1)];
                end
                else
                begin
                    if(instruction[2] == 0)//zero padding
                    begin
                        img1_pad6[i][j] = 0;
                        img2_pad6[i][j] = 0;
                    end
                end
            end
        end
        if(instruction[2] == 1)//reflication padding
        begin
            /*img1_pad6[0][0] = upl_out1[0][0];
            img1_pad6[0][1:4] = upl_out1[0][0:3];
            img1_pad6[0][5] = upl_out1[0][3];
            img1_pad6[5][0] = upl_out1[3][0];
            img1_pad6[5][1:4] = upl_out1[3][0:3];
            img1_pad6[5][5] = upl_out1[3][3];*/
            img1_pad6[0][0] = upl_out1[0];
            img1_pad6[0][1:4] = upl_out1[0:3];
            img1_pad6[0][5] = upl_out1[3];
            img1_pad6[5][0] = upl_out1[12];
            img1_pad6[5][1:4] = upl_out1[12:15];
            img1_pad6[5][5] = upl_out1[15];
            for(i = 1; i < 5; i = i + 1)
            begin
                //img1_pad6[i][0] = upl_out1[i-1][0];
                //img1_pad6[i][5] = upl_out1[i-1][3];
                img1_pad6[i][0] = upl_out1[(i-1)*4];
                img1_pad6[i][5] = upl_out1[(i-1)*4 + 3];
            end
            /*img2_pad6[0][0] = upl_out2[0][0];
            img2_pad6[0][1:4] = upl_out2[0][0:3];
            img2_pad6[0][5] = upl_out2[0][3];
            img2_pad6[5][0] = upl_out2[3][0];
            img2_pad6[5][1:4] = upl_out2[3][0:3];
            img2_pad6[5][5] = upl_out2[3][3];*/
            img2_pad6[0][0] = upl_out2[0];
            img2_pad6[0][1:4] = upl_out2[0:3];
            img2_pad6[0][5] = upl_out2[3];
            img2_pad6[5][0] = upl_out2[12];
            img2_pad6[5][1:4] = upl_out2[12:15];
            img2_pad6[5][5] = upl_out2[15];
            for(i = 1; i < 5; i = i + 1)
            begin
                //img2_pad6[i][0] = upl_out2[i-1][0];
                //img2_pad6[i][5] = upl_out2[i-1][3];
                img2_pad6[i][0] = upl_out2[(i-1)*4];
                img2_pad6[i][5] = upl_out2[(i-1)*4 + 3];
            end
        end
    end
    if((count >= 258 && count <= 327) || (count >= 329 && count <= 398))//258-327, 329-398
    begin
        for (i = 0; i < 10; i = i + 1)
        begin
            for (j = 0; j < 10; j = j + 1)
            begin
                if(i >= 1 && i <= 8 && j >= 1 && j <= 8)
                begin
                    //img1_pad10[i][j] = upl_out3[i-1][j-1];
                    //img2_pad10[i][j] = upl_out4[i-1][j-1];
                    img1_pad10[i][j] = upl_out3[(i-1)*8+(j-1)];
                    img2_pad10[i][j] = upl_out4[(i-1)*8+(j-1)];
                end
                else
                begin
                    if(instruction[2] == 0)//zero padding
                    begin
                        img1_pad10[i][j] = 0;
                        img2_pad10[i][j] = 0;
                    end
                end
            end
        end
        if(instruction[2] == 1)//reflication padding
        begin
            /*img1_pad10[0][0] = upl_out3[0][0];
            img1_pad10[0][1:8] = upl_out3[0][0:7];
            img1_pad10[0][9] = upl_out3[0][7];
            img1_pad10[9][0] = upl_out3[7][0];
            img1_pad10[9][1:8] = upl_out3[7][0:7];
            img1_pad10[9][9] = upl_out3[7][7];*/
            img1_pad10[0][0] = upl_out3[0];
            img1_pad10[0][1:8] = upl_out3[0:7];
            img1_pad10[0][9] = upl_out3[7];
            img1_pad10[9][0] = upl_out3[56];
            img1_pad10[9][1:8] = upl_out3[56:63];
            img1_pad10[9][9] = upl_out3[63];
            for(i = 1; i < 9; i = i + 1)
            begin
                //img1_pad10[i][0] = upl_out3[i-1][0];
                //img1_pad10[i][9] = upl_out3[i-1][7];
                img1_pad10[i][0] = upl_out3[(i-1)*8];
                img1_pad10[i][9] = upl_out3[(i-1)*8 + 7];
            end
            /*img2_pad10[0][0] = upl_out4[0][0];
            img2_pad10[0][1:8] = upl_out4[0][0:7];
            img2_pad10[0][9] = upl_out4[0][7];
            img2_pad10[9][0] = upl_out4[7][0];
            img2_pad10[9][1:8] = upl_out4[7][0:7];
            img2_pad10[9][9] = upl_out4[7][7];*/
            img2_pad10[0][0] = upl_out4[0];
            img2_pad10[0][1:8] = upl_out4[0:7];
            img2_pad10[0][9] = upl_out4[7];
            img2_pad10[9][0] = upl_out4[56];
            img2_pad10[9][1:8] = upl_out4[56:63];
            img2_pad10[9][9] = upl_out4[63];
            for(i = 1; i < 9; i = i + 1)
            begin
                //img2_pad10[i][0] = upl_out4[i-1][0];
                //img2_pad10[i][9] = upl_out4[i-1][7];
                img2_pad10[i][0] = upl_out4[(i-1)*8];
                img2_pad10[i][9] = upl_out4[(i-1)*8 + 7];
            end
        end
    end
    
end

CONV u_conv01(.clock(clk), .reset_n(rst_n), .conv_valid(conv01_valid), .img_vec(conv01_img1_sel), .img2_vec(conv01_img2_sel), 
    .kernel_vec(conv01_k1_sel), .kernel2_vec(conv01_k2_sel), .conv_out_valid(conv_out_valid01), .conv_out(conv_out_data01));

MAXPOOL m0(.mp1(cpa1), .mp2(cpb1), .mp3(cpa2), .mp4(cpb2), .index(idx1), .pool_out(cp3));
//MAXPOOL m1(.mp1(cpa3), .mp2(cpb3), .mp3(cpa4), .mp4(cpb4), .index(idx2), .pool_out(cp4));

ACTFCT u_actfct(.clock(clk), .reset_n(rst_n), .act_valid(act_valid1), .instruction(instruction), .data_in(data_in1), .act_out_valid(act_out_valid1), .data_out(data_out1));
//ACTFCT u_actfct1(.clock(clk), .reset_n(rst_n), .act_valid(act_valid2), .instruction(instruction), .data_in(data_in2), .act_out_valid(act_out_valid2), .data_out(data_out2));

UNPOOL2X2 u_unpool0(.pool_in(c11_vec), .index(index41), .unpool_out(unpool_out1));
UNPOOL2X2 u_unpool1(.pool_in(c12_vec), .index(index42), .unpool_out(unpool_out2));

UNPOOL4X4 u_unpool2(.pool_in(c01_vec), .index(index81), .unpool_out(unpool_out3));
UNPOOL4X4 u_unpool3(.pool_in(c02_vec), .index(index82), .unpool_out(unpool_out4));

//selection
always @(*)
begin
    for (i = 0; i < 9; i = i + 1)
    begin
        conv01_img1_sel[i] = 0; 
        conv01_img2_sel[i] = 0; 
        conv01_k1_sel[i] = 0; 
        conv01_k2_sel[i] = 0; 
    end
    for (i = 0; i < 16; i = i + 1)
    begin
        next_index81[i] = index81[i];
        next_index82[i] = index82[i];
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        next_index41[i] = index41[i];
        next_index42[i] = index42[i];
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            next_mp01_array[i][j] = mp01_array[i][j];
            next_mp02_array[i][j] = mp02_array[i][j];
        end
    end
    for (i = 0; i < 2; i = i + 1)
    begin
        for (j = 0; j < 2; j = j + 1)
        begin
            next_mp11_array[i][j] = mp11_array[i][j];
            next_mp12_array[i][j] = mp12_array[i][j];
        end
    end
    for (i = 0; i < 16; i = i + 1)
    begin
        next_upl_out1[i] = upl_out1[i];
        next_upl_out2[i] = upl_out2[i];
    end
    for (i = 0; i < 64; i = i + 1)
    begin
        next_upl_out3[i] = upl_out3[i];
        next_upl_out4[i] = upl_out4[i];
    end
    conv01_valid = 0; conv02_valid = 0; 
    cpa1 = 0; cpb1 = 0; cpa2 = 0; cpb2 = 0; cpa3 = 0; cpb3 = 0; cpa4 = 0; cpb4 = 0;
    data_in1 = 0; data_in2 = 0;
    next_act_valid1 = act_valid1; 
    next_ki = 0; next_kj = 0;

    if((count >= 1 && count <= 70) || (count >= 72 && count <= 141))//1-70, 72-141
    begin
        conv01_valid = 1;
    end
    else if((count >= 151 && count <= 172) || (count >= 174 && count <= 195))//151-172, 174-195
    begin
        conv01_valid = 1;
    end
    else if((count >= 205 && count <= 226) || (count >= 228 && count <= 249))//205-226, 228-249
    begin
        conv01_valid = 1;
    end
    else if((count >= 258 && count <= 327) || (count >= 329 && count <= 398))//258-327, 329-398
    begin
        conv01_valid = 1;
    end

    if((count >= 1 && count <= 64))//1-64
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 7)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 7)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad10[ki][kj]; conv01_img1_sel[1] = img1_pad10[ki][kj+1]; conv01_img1_sel[2] = img1_pad10[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad10[ki+1][kj]; conv01_img1_sel[4] = img1_pad10[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad10[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad10[ki+2][kj]; conv01_img1_sel[7] = img1_pad10[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad10[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad10[ki][kj]; conv01_img2_sel[1] = img2_pad10[ki][kj+1]; conv01_img2_sel[2] = img2_pad10[ki][kj+2];
        conv01_img2_sel[3] = img2_pad10[ki+1][kj]; conv01_img2_sel[4] = img2_pad10[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad10[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad10[ki+2][kj]; conv01_img2_sel[7] = img2_pad10[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad10[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt1[i];
            conv01_k2_sel[i] = wt2[i];
        end
    end
    else if(count >= 72 && count <= 135)//72-135
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 7)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 7)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad10[ki][kj]; conv01_img1_sel[1] = img1_pad10[ki][kj+1]; conv01_img1_sel[2] = img1_pad10[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad10[ki+1][kj]; conv01_img1_sel[4] = img1_pad10[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad10[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad10[ki+2][kj]; conv01_img1_sel[7] = img1_pad10[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad10[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad10[ki][kj]; conv01_img2_sel[1] = img2_pad10[ki][kj+1]; conv01_img2_sel[2] = img2_pad10[ki][kj+2];
        conv01_img2_sel[3] = img2_pad10[ki+1][kj]; conv01_img2_sel[4] = img2_pad10[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad10[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad10[ki+2][kj]; conv01_img2_sel[7] = img2_pad10[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad10[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt3[i];
            conv01_k2_sel[i] = wt4[i];
        end
    end
    else if(count >= 151 && count <= 166)//151-166
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 3)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 3)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad6[ki][kj]; conv01_img1_sel[1] = img1_pad6[ki][kj+1]; conv01_img1_sel[2] = img1_pad6[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad6[ki+1][kj]; conv01_img1_sel[4] = img1_pad6[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad6[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad6[ki+2][kj]; conv01_img1_sel[7] = img1_pad6[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad6[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad6[ki][kj]; conv01_img2_sel[1] = img2_pad6[ki][kj+1]; conv01_img2_sel[2] = img2_pad6[ki][kj+2];
        conv01_img2_sel[3] = img2_pad6[ki+1][kj]; conv01_img2_sel[4] = img2_pad6[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad6[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad6[ki+2][kj]; conv01_img2_sel[7] = img2_pad6[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad6[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt5[i];
            conv01_k2_sel[i] = wt6[i];
        end
    end
    else if(count >= 174 && count <= 189)//174-189
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 3)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 3)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad6[ki][kj]; conv01_img1_sel[1] = img1_pad6[ki][kj+1]; conv01_img1_sel[2] = img1_pad6[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad6[ki+1][kj]; conv01_img1_sel[4] = img1_pad6[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad6[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad6[ki+2][kj]; conv01_img1_sel[7] = img1_pad6[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad6[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad6[ki][kj]; conv01_img2_sel[1] = img2_pad6[ki][kj+1]; conv01_img2_sel[2] = img2_pad6[ki][kj+2];
        conv01_img2_sel[3] = img2_pad6[ki+1][kj]; conv01_img2_sel[4] = img2_pad6[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad6[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad6[ki+2][kj]; conv01_img2_sel[7] = img2_pad6[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad6[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt7[i];
            conv01_k2_sel[i] = wt8[i];
        end
    end
    else if(count >= 205 && count <= 220)//205-220
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 3)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 3)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad6[ki][kj]; conv01_img1_sel[1] = img1_pad6[ki][kj+1]; conv01_img1_sel[2] = img1_pad6[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad6[ki+1][kj]; conv01_img1_sel[4] = img1_pad6[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad6[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad6[ki+2][kj]; conv01_img1_sel[7] = img1_pad6[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad6[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad6[ki][kj]; conv01_img2_sel[1] = img2_pad6[ki][kj+1]; conv01_img2_sel[2] = img2_pad6[ki][kj+2];
        conv01_img2_sel[3] = img2_pad6[ki+1][kj]; conv01_img2_sel[4] = img2_pad6[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad6[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad6[ki+2][kj]; conv01_img2_sel[7] = img2_pad6[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad6[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt9[i];
            conv01_k2_sel[i] = wt10[i];
        end
    end
    else if(count >= 228 && count <= 243)//228-243
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 3)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 3)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad6[ki][kj]; conv01_img1_sel[1] = img1_pad6[ki][kj+1]; conv01_img1_sel[2] = img1_pad6[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad6[ki+1][kj]; conv01_img1_sel[4] = img1_pad6[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad6[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad6[ki+2][kj]; conv01_img1_sel[7] = img1_pad6[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad6[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad6[ki][kj]; conv01_img2_sel[1] = img2_pad6[ki][kj+1]; conv01_img2_sel[2] = img2_pad6[ki][kj+2];
        conv01_img2_sel[3] = img2_pad6[ki+1][kj]; conv01_img2_sel[4] = img2_pad6[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad6[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad6[ki+2][kj]; conv01_img2_sel[7] = img2_pad6[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad6[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt11[i];
            conv01_k2_sel[i] = wt12[i];
        end
    end
    else if(count >= 258 && count <= 321)//258-321
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 7)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 7)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad10[ki][kj]; conv01_img1_sel[1] = img1_pad10[ki][kj+1]; conv01_img1_sel[2] = img1_pad10[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad10[ki+1][kj]; conv01_img1_sel[4] = img1_pad10[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad10[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad10[ki+2][kj]; conv01_img1_sel[7] = img1_pad10[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad10[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad10[ki][kj]; conv01_img2_sel[1] = img2_pad10[ki][kj+1]; conv01_img2_sel[2] = img2_pad10[ki][kj+2];
        conv01_img2_sel[3] = img2_pad10[ki+1][kj]; conv01_img2_sel[4] = img2_pad10[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad10[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad10[ki+2][kj]; conv01_img2_sel[7] = img2_pad10[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad10[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt13[i];
            conv01_k2_sel[i] = wt14[i];
        end
    end
    else if(count >= 329 && count <= 392)//329-392
    begin
        next_kj = kj + 1;
        next_ki = ki;
        if(kj == 7)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 7)
            begin
                next_ki = 0;
            end
        end
        conv01_valid = 1;
        conv01_img1_sel[0] = img1_pad10[ki][kj]; conv01_img1_sel[1] = img1_pad10[ki][kj+1]; conv01_img1_sel[2] = img1_pad10[ki][kj+2]; 
        conv01_img1_sel[3] = img1_pad10[ki+1][kj]; conv01_img1_sel[4] = img1_pad10[ki+1][kj+1]; conv01_img1_sel[5] = img1_pad10[ki+1][kj+2]; 
        conv01_img1_sel[6] = img1_pad10[ki+2][kj]; conv01_img1_sel[7] = img1_pad10[ki+2][kj+1]; conv01_img1_sel[8] = img1_pad10[ki+2][kj+2];

        conv01_img2_sel[0] = img2_pad10[ki][kj]; conv01_img2_sel[1] = img2_pad10[ki][kj+1]; conv01_img2_sel[2] = img2_pad10[ki][kj+2];
        conv01_img2_sel[3] = img2_pad10[ki+1][kj]; conv01_img2_sel[4] = img2_pad10[ki+1][kj+1]; conv01_img2_sel[5] = img2_pad10[ki+1][kj+2];
        conv01_img2_sel[6] = img2_pad10[ki+2][kj]; conv01_img2_sel[7] = img2_pad10[ki+2][kj+1]; conv01_img2_sel[8] = img2_pad10[ki+2][kj+2];

        for (i = 0; i < 9; i = i + 1)
        begin
            conv01_k1_sel[i] = wt15[i];
            conv01_k2_sel[i] = wt16[i];
        end
    end

    
    if(count == 204)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_upl_out1[i] = unpool_out1[i];
            next_upl_out2[i] = unpool_out2[i];
        end
    end
    if(count == 257)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            next_upl_out3[i] = unpool_out3[i];
            next_upl_out4[i] = unpool_out4[i];
        end
    end


    case(count)
        59: begin
            cpa1 = conv01_array[0]; cpb1 = conv01_array[1]; cpa2 = conv01_array[8]; cpb2 = conv01_array[9]; next_mp01_array[0][0] = cp3; next_index81[0] = idx1;
            //cpa3 = conv02_array[0]; cpb3 = conv02_array[1]; cpa4 = conv02_array[8]; cpb4 = conv02_array[9]; next_mp02_array[0][0] = cp4; next_index82[0] = idx2;
        end
        60: begin
            cpa1 = conv01_array[2]; cpb1 = conv01_array[3]; cpa2 = conv01_array[10]; cpb2 = conv01_array[11]; next_mp01_array[0][1] = cp3; next_index81[1] = idx1;
        end
        61: begin
            cpa1 = conv01_array[4]; cpb1 = conv01_array[5]; cpa2 = conv01_array[12]; cpb2 = conv01_array[13]; next_mp01_array[0][2] = cp3; next_index81[2] = idx1;
        end
        62: begin
            cpa1 = conv01_array[6]; cpb1 = conv01_array[7]; cpa2 = conv01_array[14]; cpb2 = conv01_array[15]; next_mp01_array[0][3] = cp3; next_index81[3] = idx1;
        end
        63: begin
            cpa1 = conv01_array[16]; cpb1 = conv01_array[17]; cpa2 = conv01_array[24]; cpb2 = conv01_array[25]; next_mp01_array[1][0] = cp3; next_index81[4] = idx1;
        end
        64: begin
            cpa1 = conv01_array[18]; cpb1 = conv01_array[19]; cpa2 = conv01_array[26]; cpb2 = conv01_array[27]; next_mp01_array[1][1] = cp3; next_index81[5] = idx1;
        end
        65: begin
            cpa1 = conv01_array[20]; cpb1 = conv01_array[21]; cpa2 = conv01_array[28]; cpb2 = conv01_array[29]; next_mp01_array[1][2] = cp3; next_index81[6] = idx1;
        end
        66: begin
            cpa1 = conv01_array[22]; cpb1 = conv01_array[23]; cpa2 = conv01_array[30]; cpb2 = conv01_array[31]; next_mp01_array[1][3] = cp3; next_index81[7] = idx1;
        end
        67: begin
            cpa1 = conv01_array[32]; cpb1 = conv01_array[33]; cpa2 = conv01_array[40]; cpb2 = conv01_array[41]; next_mp01_array[2][0] = cp3; next_index81[8] = idx1;
        end
        68: begin
            cpa1 = conv01_array[34]; cpb1 = conv01_array[35]; cpa2 = conv01_array[42]; cpb2 = conv01_array[43]; next_mp01_array[2][1] = cp3; next_index81[9] = idx1;
        end
        69: begin
            cpa1 = conv01_array[36]; cpb1 = conv01_array[37]; cpa2 = conv01_array[44]; cpb2 = conv01_array[45]; next_mp01_array[2][2] = cp3; next_index81[10] = idx1;
        end
        70: begin
            cpa1 = conv01_array[38]; cpb1 = conv01_array[39]; cpa2 = conv01_array[46]; cpb2 = conv01_array[47]; next_mp01_array[2][3] = cp3; next_index81[11] = idx1;
        end
        71: begin
            cpa1 = conv01_array[48]; cpb1 = conv01_array[49]; cpa2 = conv01_array[56]; cpb2 = conv01_array[57]; next_mp01_array[3][0] = cp3; next_index81[12] = idx1;
        end
        72: begin
            cpa1 = conv01_array[50]; cpb1 = conv01_array[51]; cpa2 = conv01_array[58]; cpb2 = conv01_array[59]; next_mp01_array[3][1] = cp3; next_index81[13] = idx1;
        end
        73: begin
            cpa1 = conv01_array[52]; cpb1 = conv01_array[53]; cpa2 = conv01_array[60]; cpb2 = conv01_array[61]; next_mp01_array[3][2] = cp3; next_index81[14] = idx1;
        end
        74: begin
            cpa1 = conv01_array[54]; cpb1 = conv01_array[55]; cpa2 = conv01_array[62]; cpb2 = conv01_array[63]; next_mp01_array[3][3] = cp3; next_index81[15] = idx1;
        end
        //channel 2
        128: begin
            cpa1 = conv02_array[0]; cpb1 = conv02_array[1]; cpa2 = conv02_array[8]; cpb2 = conv02_array[9]; next_mp02_array[0][0] = cp3; next_index82[0] = idx1;
        end
        129: begin
            cpa1 = conv02_array[2]; cpb1 = conv02_array[3]; cpa2 = conv02_array[10]; cpb2 = conv02_array[11]; next_mp02_array[0][1] = cp3; next_index82[1] = idx1;
        end
        130: begin
            cpa1 = conv02_array[4]; cpb1 = conv02_array[5]; cpa2 = conv02_array[12]; cpb2 = conv02_array[13]; next_mp02_array[0][2] = cp3; next_index82[2] = idx1;
        end
        131: begin
            cpa1 = conv02_array[6]; cpb1 = conv02_array[7]; cpa2 = conv02_array[14]; cpb2 = conv02_array[15]; next_mp02_array[0][3] = cp3; next_index82[3] = idx1;
        end
        132: begin
            cpa1 = conv02_array[16]; cpb1 = conv02_array[17]; cpa2 = conv02_array[24]; cpb2 = conv02_array[25]; next_mp02_array[1][0] = cp3; next_index82[4] = idx1;
        end
        133: begin
            cpa1 = conv02_array[18]; cpb1 = conv02_array[19]; cpa2 = conv02_array[26]; cpb2 = conv02_array[27]; next_mp02_array[1][1] = cp3; next_index82[5] = idx1;
        end
        134: begin
            cpa1 = conv02_array[20]; cpb1 = conv02_array[21]; cpa2 = conv02_array[28]; cpb2 = conv02_array[29]; next_mp02_array[1][2] = cp3; next_index82[6] = idx1;
        end
        135: begin
            cpa1 = conv02_array[22]; cpb1 = conv02_array[23]; cpa2 = conv02_array[30]; cpb2 = conv02_array[31]; next_mp02_array[1][3] = cp3; next_index82[7] = idx1;
        end
        136: begin
            cpa1 = conv02_array[32]; cpb1 = conv02_array[33]; cpa2 = conv02_array[40]; cpb2 = conv02_array[41]; next_mp02_array[2][0] = cp3; next_index82[8] = idx1;
        end
        137: begin
            cpa1 = conv02_array[34]; cpb1 = conv02_array[35]; cpa2 = conv02_array[42]; cpb2 = conv02_array[43]; next_mp02_array[2][1] = cp3; next_index82[9] = idx1;
        end
        138: begin
            cpa1 = conv02_array[36]; cpb1 = conv02_array[37]; cpa2 = conv02_array[44]; cpb2 = conv02_array[45]; next_mp02_array[2][2] = cp3; next_index82[10] = idx1;
        end
        139: begin
            cpa1 = conv02_array[38]; cpb1 = conv02_array[39]; cpa2 = conv02_array[46]; cpb2 = conv02_array[47]; next_mp02_array[2][3] = cp3; next_index82[11] = idx1;
        end
        140: begin
            cpa1 = conv02_array[48]; cpb1 = conv02_array[49]; cpa2 = conv02_array[56]; cpb2 = conv02_array[57]; next_mp02_array[3][0] = cp3; next_index82[12] = idx1;
        end
        141: begin
            cpa1 = conv02_array[50]; cpb1 = conv02_array[51]; cpa2 = conv02_array[58]; cpb2 = conv02_array[59]; next_mp02_array[3][1] = cp3; next_index82[13] = idx1;
        end
        142: begin
            cpa1 = conv02_array[52]; cpb1 = conv02_array[53]; cpa2 = conv02_array[60]; cpb2 = conv02_array[61]; next_mp02_array[3][2] = cp3; next_index82[14] = idx1;
        end
        143: begin
            cpa1 = conv02_array[54]; cpb1 = conv02_array[55]; cpa2 = conv02_array[62]; cpb2 = conv02_array[63]; next_mp02_array[3][3] = cp3; next_index82[15] = idx1;
        end
    endcase

    if(count == 59 || count == 128)
    begin
        next_act_valid1 = 1;
        //next_act_valid2 = 1;
    end
    if(count == 75 || count == 144)
    begin
        next_act_valid1 = 0;
        //next_act_valid2 = 0;
    end

    if(count >= 60 && count <= 75)//60-75
    begin
        data_in1 = mp01_array[(count-60)/4][(count-60)%4];
    end
    else if(count >= 129 && count <= 144)//129-144
    begin
        data_in1 = mp02_array[(count-129)/4][(count-129)%4];
    end
    
    case(count)
        170: begin
            cpa1 = conv11_array[0]; cpb1 = conv11_array[1]; cpa2 = conv11_array[4]; cpb2 = conv11_array[5]; next_mp11_array[0][0] = cp3; next_index41[0] = idx1;
            //cpa3 = conv12_array[0]; cpb3 = conv12_array[1]; cpa4 = conv12_array[4]; cpb4 = conv12_array[5]; next_mp12_array[0][0] = cp4; next_index42[0] = idx2;
        end
        171: begin
            cpa1 = conv11_array[2]; cpb1 = conv11_array[3]; cpa2 = conv11_array[6]; cpb2 = conv11_array[7]; next_mp11_array[0][1] = cp3; next_index41[1] = idx1;
        end
        172: begin
            cpa1 = conv11_array[8]; cpb1 = conv11_array[9]; cpa2 = conv11_array[12]; cpb2 = conv11_array[13]; next_mp11_array[1][0] = cp3; next_index41[2] = idx1;
        end
        173: begin
            cpa1 = conv11_array[10]; cpb1 = conv11_array[11]; cpa2 = conv11_array[14]; cpb2 = conv11_array[15]; next_mp11_array[1][1] = cp3; next_index41[3] = idx1;
        end
        //channel 2
        193: begin
            cpa1 = conv12_array[0]; cpb1 = conv12_array[1]; cpa2 = conv12_array[4]; cpb2 = conv12_array[5]; next_mp12_array[0][0] = cp3; next_index42[0] = idx1;
        end
        194: begin
            cpa1 = conv12_array[2]; cpb1 = conv12_array[3]; cpa2 = conv12_array[6]; cpb2 = conv12_array[7]; next_mp12_array[0][1] = cp3; next_index42[1] = idx1;
        end
        195: begin
            cpa1 = conv12_array[8]; cpb1 = conv12_array[9]; cpa2 = conv12_array[12]; cpb2 = conv12_array[13]; next_mp12_array[1][0] = cp3; next_index42[2] = idx1;
        end
        196: begin
            cpa1 = conv12_array[10]; cpb1 = conv12_array[11]; cpa2 = conv12_array[14]; cpb2 = conv12_array[15]; next_mp12_array[1][1] = cp3; next_index42[3] = idx1;
        end
    endcase

    if(count == 170 || count == 193)
    begin
        next_act_valid1 = 1;
        //next_act_valid2 = 1;
    end
    if(count == 174 || count == 197)
    begin
        next_act_valid1 = 0;
        //next_act_valid2 = 0;
    end

    if(count >= 171 && count <= 174)//171-174
    begin
        data_in1 = mp11_array[(count-171)/2][(count-171)%2];
    end
    else if(count >= 194 && count <= 197)//194-197
    begin
        data_in1 = mp12_array[(count-194)/2][(count-194)%2];
    end

    //deconv act
    if(count == 211 || count == 234)
    begin
        next_act_valid1 = 1;
    end
    if(count == 227 || count == 250)
    begin
        next_act_valid1 = 0;
    end

    if(count >= 212 && count <= 227)//212-227
    begin
        data_in1 = conv11_array[count-212];
    end
    else if(count >= 235 && count <= 250)//235-250
    begin
        data_in1 = conv12_array[count-235];
    end

    if(count == 264 || count == 335)
    begin
        next_act_valid1 = 1;
    end
    if(count == 328 || count == 399)
    begin
        next_act_valid1 = 0;
    end

    if(count >= 265 && count <= 328)//265-328
    begin
        data_in1 = conv01_array[count-265];
    end
    else if(count >= 336 && count <= 399)//336-399
    begin
        data_in1 = conv02_array[count-336];
    end

end

always @(*)
begin
    next_cct = 0;
    next_cct2 = 0;
    for (i = 0; i < 16; i = i + 1)
    begin
        next_c01_vec[i] = c01_vec[i];
        next_c02_vec[i] = c02_vec[i];
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        next_c11_vec[i] = c11_vec[i];
        next_c12_vec[i] = c12_vec[i];
    end
    for (i = 0; i < 64; i = i + 1)
    begin
        next_dc11_vec[i] = dc11_vec[i];
        next_dc12_vec[i] = dc12_vec[i];
    end

    if(act_out_valid1 && (count >= 66 && count <= 81))//66-81
    begin
        next_cct = cct + 1;
        next_c01_vec[cct] = data_out1;
    end
    if(act_out_valid1 && (count >= 135 && count <= 150))//135-150
    begin
        next_cct2 = cct2 + 1;
        next_c02_vec[cct2] = data_out1;
    end
    if(act_out_valid1 && (count >= 177 && count <= 180))//177-180
    begin
        next_cct = cct + 1;
        next_c11_vec[cct] = data_out1;
    end
    if(act_out_valid1 && (count >= 200 && count <= 203))//200-203
    begin
        next_cct2 = cct2 + 1;
        next_c12_vec[cct2] = data_out1;
    end
    if(act_out_valid1 &&  (count >= 218 && count <= 233))//218-233
    begin
        next_cct = cct + 1;
        next_c01_vec[cct] = data_out1;
    end
    if(act_out_valid1 && (count >= 241 && count <= 256))//241-256
    begin
        next_cct2 = cct2 + 1;
        next_c02_vec[cct2] = data_out1;
    end
    if(act_out_valid1 && (count >= 271 && count <= 334))//271-334
    begin
        next_cct = cct + 1;
        next_dc11_vec[cct] = data_out1;
    end
    if(act_out_valid1 && (count >= 342 && count <= 405))//342-405
    begin
        next_cct2 = cct2 + 1;
        next_dc12_vec[cct2] = data_out1;
    end

end

always @(*)
begin
    next_ar_ct = 0;

    for (i = 0; i < 16; i = i + 1)
    begin
        next_conv11_array[i] = conv11_array[i];
        next_conv12_array[i] = conv12_array[i];
    end
    for (i = 0; i < 64; i = i + 1)
    begin
        next_conv01_array[i] = conv01_array[i];
        next_conv02_array[i] = conv02_array[i];
    end

    if(conv_out_valid01 && count >= 7 && count <= 70)//7-70
    begin
        next_ar_ct = ar_ct + 1;
        next_conv01_array[ar_ct] = conv_out_data01;
    end
    if(conv_out_valid01 && count >= 78 && count <= 141)//78-141
    begin
        next_ar_ct = ar_ct + 1;
        next_conv02_array[ar_ct] = conv_out_data01;
    end

    if(conv_out_valid01 && count >= 157 && count <= 172)//157-172
    begin
        next_ar_ct = ar_ct + 1;
        next_conv11_array[ar_ct] = conv_out_data01;
    end
    if(conv_out_valid01 && count >= 180 && count <= 195)//180-195
    begin
        next_ar_ct = ar_ct + 1;
        next_conv12_array[ar_ct] = conv_out_data01;
    end

    if(conv_out_valid01 && count >= 211 && count <= 226)//211-226
    begin
        next_ar_ct = ar_ct + 1;
        next_conv11_array[ar_ct] = conv_out_data01;
    end
    if(conv_out_valid01 && count >= 234 && count <= 249)//234-249
    begin
        next_ar_ct = ar_ct + 1;
        next_conv12_array[ar_ct] = conv_out_data01;
    end

    if(conv_out_valid01 && count >= 264 && count <= 327)//264-327
    begin
        next_ar_ct = ar_ct + 1;
        next_conv01_array[ar_ct] = conv_out_data01;
    end
    if(conv_out_valid01 && count >= 335 && count <= 398)//335-398
    begin
        next_ar_ct = ar_ct + 1;
        next_conv02_array[ar_ct] = conv_out_data01;
    end

    if(out_valid)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            next_conv01_array[i] = 0;
            next_conv02_array[i] = 0;
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            next_conv11_array[i] = 0;
            next_conv12_array[i] = 0;
        end
    end
end

//output 
always @(*)
begin
    next_out_valid = 0;
    next_out_data = 0;
    next_out_ct = out_ct;
    next_start_out = start_out;

    if(count == 405)
    begin
        next_start_out = 1;
    end

    if(start_out)
    begin
        next_out_valid = 1;
        if(out_ct < 64)//0-63
        begin
            next_out_data = dc11_vec[out_ct];
        end
        else if(out_ct < 128)//64-127
        begin
            next_out_data = dc12_vec[out_ct-64];
        end
        next_out_ct = out_ct + 1;
    end

    if(out_ct == 128)
    begin
        next_start_out = 0;
        next_out_ct = 0;
        next_out_valid = 0;
        next_out_data = 0;
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 9; i = i + 1)
        begin
            wt1[i] <= 0;
            wt2[i] <= 0;
            wt3[i] <= 0;
            wt4[i] <= 0;
            wt5[i] <= 0;
            wt6[i] <= 0;
            wt7[i] <= 0;
            wt8[i] <= 0;
            wt9[i] <= 0;
            wt10[i] <= 0;
            wt11[i] <= 0;
            wt12[i] <= 0;
            wt13[i] <= 0;
            wt14[i] <= 0;
            wt15[i] <= 0;
            wt16[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                img1[i][j] <= 0;
                img2[i][j] <= 0;
            end
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            index81[i] <= 0;
            index82[i] <= 0;
            conv11_array[i] <= 0;
            conv12_array[i] <= 0;
            //deconv01_array[i] <= 0;
            //deconv02_array[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            index41[i] <= 0;
            index42[i] <= 0;
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            conv01_array[i] <= 0;
            conv02_array[i] <= 0;
            //deconv11_array[i] <= 0;
            //deconv12_array[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                mp01_array[i][j] <= 0;
                mp02_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 2; i = i + 1)
        begin
            for (j = 0; j < 2; j = j + 1)
            begin
                mp11_array[i][j] <= 0;
                mp12_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            c01_vec[i] <= 0;
            c02_vec[i] <= 0;
            //dc01_vec[i] <= 0;
            //dc02_vec[i] <= 0;
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            dc11_vec[i] <= 0;
            dc12_vec[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            c11_vec[i] <= 0;
            c12_vec[i] <= 0;
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            upl_out1[i] <= 0;
            upl_out2[i] <= 0;
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            upl_out3[i] <= 0;
            upl_out4[i] <= 0;
        end
        out_valid <= 0;
        out_data <= 0;
        instruction <= 0;
        maxc1 <= 0;
        minc1 <= 0;
        maxc2 <= 0;
        minc2 <= 0;
        in_ct <= 0;
        image_in_valid_buf <= 0;
        mm_valid <= 0;
        scale_ct <= 0;
        count <= 0;
        reciprocal1 <= 0;
        reciprocal2 <= 0;
        out_ct <= 0;
        start_out <= 0;
        act_valid1 <= 0;
        //act_valid2 <= 0;
        cct <= 0;
        cct2 <= 0;
        mms_sub1 <= 0;
        mms_sub2 <= 0;
        ki <= 0;
        kj <= 0;
        ar_ct <= 0;
    end
    else
    begin
        for (i = 0; i < 9; i = i + 1)
        begin
            wt1[i] <= next_wt1[i];
            wt2[i] <= next_wt2[i];
            wt3[i] <= next_wt3[i];
            wt4[i] <= next_wt4[i];
            wt5[i] <= next_wt5[i];
            wt6[i] <= next_wt6[i];
            wt7[i] <= next_wt7[i];
            wt8[i] <= next_wt8[i];
            wt9[i] <= next_wt9[i];
            wt10[i] <= next_wt10[i];
            wt11[i] <= next_wt11[i];
            wt12[i] <= next_wt12[i];
            wt13[i] <= next_wt13[i];
            wt14[i] <= next_wt14[i];
            wt15[i] <= next_wt15[i];
            wt16[i] <= next_wt16[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                img1[i][j] <= next_img1[i][j];
                img2[i][j] <= next_img2[i][j];
            end
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            index81[i] <= next_index81[i];
            index82[i] <= next_index82[i];
            conv11_array[i] <= next_conv11_array[i];
            conv12_array[i] <= next_conv12_array[i];
            //deconv01_array[i] <= next_deconv01_array[i];
            //deconv02_array[i] <= next_deconv02_array[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            index41[i] <= next_index41[i];
            index42[i] <= next_index42[i];
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            //deconv11_array[i] <= next_deconv11_array[i];
            //deconv12_array[i] <= next_deconv12_array[i];
            conv01_array[i] <= next_conv01_array[i];
            conv02_array[i] <= next_conv02_array[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                mp01_array[i][j] <= next_mp01_array[i][j];
                mp02_array[i][j] <= next_mp02_array[i][j];
            end
        end
        for (i = 0; i < 2; i = i + 1)
        begin
            for (j = 0; j < 2; j = j + 1)
            begin
                mp11_array[i][j] <= next_mp11_array[i][j];
                mp12_array[i][j] <= next_mp12_array[i][j];
            end
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            c01_vec[i] <= next_c01_vec[i];
            c02_vec[i] <= next_c02_vec[i];
            //dc01_vec[i] <= next_dc01_vec[i];
            //dc02_vec[i] <= next_dc02_vec[i];
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            dc11_vec[i] <= next_dc11_vec[i];
            dc12_vec[i] <= next_dc12_vec[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            c11_vec[i] <= next_c11_vec[i];
            c12_vec[i] <= next_c12_vec[i];
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            upl_out1[i] <= next_upl_out1[i];
            upl_out2[i] <= next_upl_out2[i];
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            upl_out3[i] <= next_upl_out3[i];
            upl_out4[i] <= next_upl_out4[i];
        end
        out_valid <= next_out_valid;
        out_data <= next_out_data;
        instruction <= next_instruction;
        maxc1 <= next_maxc1;
        minc1 <= next_minc1;
        maxc2 <= next_maxc2;
        minc2 <= next_minc2;
        in_ct <= next_in_ct;
        image_in_valid_buf <= next_image_in_valid_buf;
        mm_valid <= next_mm_valid;
        scale_ct <= next_scale_ct;
        count <= next_count;
        reciprocal1 <= next_reciprocal1;
        reciprocal2 <= next_reciprocal2;
        out_ct <= next_out_ct;
        start_out <= next_start_out;
        act_valid1 <= next_act_valid1;
        //act_valid2 <= next_act_valid2;
        cct <= next_cct;
        cct2 <= next_cct2;
        mms_sub1 <= next_mms_sub1;
        mms_sub2 <= next_mms_sub2;
        ki <= next_ki;
        kj <= next_kj;
        ar_ct <= next_ar_ct;
    end
end


endmodule

module MM_SCALE (
    input [31:0] pixel,
    input [31:0] minc,
    input [31:0] reciprocal,
    input mm_valid,
    output reg [31:0] scaled_pixel
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

wire [31:0] sub_out, mult_out;
wire [7:0] sub_status, sub_status2, mult_status;

DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_sub2(.a(pixel), .b(minc), .rnd(3'd0), .z(sub_out), .status(sub_status2));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult(.a(sub_out), .b(reciprocal), .rnd(3'd0), .z(mult_out), .status(mult_status));

always @(*)
begin
    if(mm_valid)
    begin
        scaled_pixel = mult_out;
    end
    else
    begin
        scaled_pixel = 0;
    end
end

endmodule

module ACTFCT (
    input clock,
    input reset_n,
    input act_valid,
    input [2:0] instruction,
    input [31:0] data_in,
    output reg act_out_valid,
    output reg [31:0] data_out
);
parameter FP_ONE = 32'h3f800000;        // This is " 1.0 " in IEEE754 single precision
parameter FP_ZERO = 32'h00000000;       // This is " 0.0 " in IEEE754 single precision
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

reg [31:0] x_1, x_2, x_comb2, x_3, x_comb3, x_4, x_comb4, x_5, x_comb5, x_6, x_comb6, temp, temp_comb, exp4, exp5, a, next_a, x_7;
reg [1:0] mode_1, mode_2, mode_3, mode_4, mode_5, mode_6;
reg v1, v2, v3, v4, v5, v6, v7;
reg next_act_out_valid;
reg [31:0] next_data_out;
reg [31:0] cpa1, cpa2;
reg [31:0] d_1, d_2, d_3, d_4, d_5, d_6;

wire [31:0] mult2_1, exp3, add4, add5, div6, mult7;
wire agtb1, agtb2, aeq1, aeq2, altb1, altb2, un1, un2;
wire [7:0] sts1, sts2, sts3, sts4, sts5, sts6, sts7, sts8, sts9, sts10;
wire [31:0] cz01, cz11, cz02, cz12; 

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(x_2), .b(a), .rnd(3'd0), .z(mult2_1), .status(sts1));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U3 ( .a(x_3), .z(exp3), .status(sts2));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U4 ( .a(x_4), .b(32'h3f800000), .rnd(3'd0), .z(add4), .status(sts3));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U5 ( .a(exp5), .b(32'hbf800000), .rnd(3'd0), .z(add5), .status(sts4));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U6 ( .a(temp), .b(x_6), .rnd(3'd0), .z(div6), .status(sts5));

DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp(.a(cpa1), .b(32'h00000000), .zctr(1'b0), .aeqb(aeq1), .altb(altb1), .agtb(agtb1), .unordered(un1), .z0(cz01), .z1(cz11), .status0(sts6), .status1(sts7));
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp2(.a(cpa2), .b(32'h82000000), .zctr(1'b0), .aeqb(aeq2), .altb(altb2), .agtb(agtb2), .unordered(un2), .z0(cz02), .z1(cz12), .status0(sts8), .status1(sts9));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U7 ( .a(data_in), .b(32'h3e000000), .rnd(3'd0), .z(mult7), .status(sts10));

//1
always @(*)
begin
    x_1 = 0;
    mode_1 = 0;
    v1 = 0;
    d_1 = 0;
    cpa1 = 0;
    cpa2 = 0;
    if(act_valid)
    begin
        v1 = 1;
        x_1 = data_in;
        mode_1 = instruction[1:0];
    end
    next_a = a;
    /*if(mode_1 == 2'b10 || mode_1 == 2'b11)
        v1 = 0;*/
    if(mode_1 == 2'b10)//relu
    begin
        cpa1 = data_in;
        if(agtb1)
            d_1 = data_in;
        else
            d_1 = 0;
    end
    else if(mode_1 == 2'b11)//leaky relu
    begin
        cpa1 = data_in;
        cpa2 = data_in;
        if(agtb1) //x > 0
            d_1 = data_in;
        else
        begin
            if(agtb2) // -2^-123 < x <= 0
                d_1 = 0; 
            else
                d_1 = mult7;
        end
    end

    if(mode_1 == 2'b00)
        next_a = 32'hbf800000; //-1
    else if(mode_1 == 2'b01)
        next_a = 32'h40000000; //2
end
always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        v2 <= 0;
        x_2 <= 0;
        mode_2 <= 0;
        a <= 0;
        d_2 <= 0;
    end
    else
    begin
        v2 <= v1;
        x_2 <= x_1;
        mode_2 <= mode_1;
        a <= next_a;
        d_2 <= d_1;
    end
end
//2
always @(*)
begin
    x_comb2 = mult2_1; //-x or 2x
end
always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        v3 <= 0;
        x_3 <= 0;
        mode_3 <= 0;
        d_3 <= 0;
    end
    else
    begin
        v3 <= v2;
        x_3 <= x_comb2;
        mode_3 <= mode_2;
        d_3 <= d_2;
    end
end
//3
always @(*)
begin
    x_comb3 = exp3; //exp(-x) or exp(2x)
end
always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        v4 <= 0;
        x_4 <= 0;
        mode_4 <= 0;
        d_4 <= 0;
    end
    else
    begin
        v4 <= v3;
        x_4 <= x_comb3;
        mode_4 <= mode_3;
        d_4 <= d_3;
    end
        
end
//4
always @(*)
begin
    exp4 = x_4;
    x_comb4 = add4; //exp(-x)+1 or exp(2x)+1
end
always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        exp5 <= 0;
        v5 <= 0;
        x_5 <= 0;
        mode_5 <= 0;
        d_5 <= 0;
    end
    else
    begin
        exp5 <= exp4;
        v5 <= v4;
        x_5 <= x_comb4;
        mode_5 <= mode_4;
        d_5 <= d_4;
    end
end
//5
always @(*)
begin
    temp_comb = 0;
    x_comb5 = x_5;
    if(mode_5 == 2'b00)
        temp_comb = 32'h3f800000;
    else
    begin
        temp_comb = add5;
    end
end
always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        v6 <= 0;
        x_6 <= 0;
        mode_6 <= 0;
        temp <= 0;
        d_6 <= 0;
    end
    else
    begin
        v6 <= v5;
        x_6 <= x_comb5;
        mode_6 <= mode_5;
        temp <= temp_comb;
        d_6 <= d_5;
    end
end

//6
always @(*)
begin
    next_act_out_valid = 0;
    next_data_out = 0;
    //cpa1 = 0;
    //cpa2 = 0;

    if(mode_6 == 2'b00 || mode_6 == 2'b01)
    begin
        next_act_out_valid = v6;
        next_data_out = div6;
    end
    else if(mode_6 == 2'b10 || mode_6 == 2'b11)
    begin
        next_act_out_valid = v6;
        next_data_out = d_6;
    end

end
always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        act_out_valid <= 0;
        data_out <= 0;
    end
    else
    begin
        act_out_valid <= next_act_out_valid;
        data_out <= next_data_out;
    end
end
endmodule

module MAXPOOL(
    input [31:0] mp1,
    input [31:0] mp2,
    input [31:0] mp3,
    input [31:0] mp4,
    output reg [1:0] index,
    output reg [31:0] pool_out
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

wire agtb1, agtb2, agtb3, aeq1, aeq2, aeq3, altb1, altb2, altb3;
wire [31:0] cp1, cp2, cp3;
wire un1, un2, un3;
wire [7:0] sts1, sts2, sts3, sts4, sts5, sts6;
wire [31:0] cz01, cz02, cz03;

DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp(.a(mp1), .b(mp2), .zctr(1'b0), .aeqb(aeq1), .altb(altb1), .agtb(agtb1), .unordered(un1), .z0(cz01), .z1(cp1), .status0(sts1), .status1(sts2));
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp2(.a(mp3), .b(mp4), .zctr(1'b0), .aeqb(aeq2), .altb(altb2), .agtb(agtb2), .unordered(un2), .z0(cz02), .z1(cp2), .status0(sts3), .status1(sts4));
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp3(.a(cp1), .b(cp2), .zctr(1'b0), .aeqb(aeq3), .altb(altb3), .agtb(agtb3), .unordered(un3), .z0(cz03), .z1(cp3), .status0(sts5), .status1(sts6));

always @(*)
begin
    pool_out = cp3;

    if(agtb1 && agtb3)
        index = 0;
    else if(!agtb1 && agtb3)
        index = 1;
    else if(agtb2 && !agtb3)
        index = 2;
    else 
        index = 3;
end
endmodule


module CONV (
    input clock,
    input reset_n,
    input conv_valid,
    input [31:0] img_vec [0:8],
    input [31:0] img2_vec [0:8],
    input [31:0] kernel_vec [0:8],
    input [31:0] kernel2_vec [0:8],
    output reg conv_out_valid,
    output reg [31:0] conv_out
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
integer i, j;
reg [31:0] next_conv_out;
reg [31:0] a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18;
reg [31:0] b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18;
reg [6:0] conv_ct, next_conv_ct;
reg next_conv_out_valid;
reg [31:0] m18_list [0:17], next_m18_list [0:17];
reg [31:0] a19_list [0:18], next_a19_list [0:18];

wire [31:0] sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9;
wire [7:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30;
wire [7:0] s31, s32, s33, s34, s35;
wire [31:0] cp1, cp2, cp3, cp4, data_out;
//wire [1:0] idx;
//wire act_out_valid;
wire [31:0] m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18;
wire [31:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8, tmp9, tmp10, tmp11, tmp12, tmp13, tmp14, tmp15, tmp16, tmp17, tmp18;

DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult1(.a(a1), .b(b1), .rnd(3'd0), .z(m1), .status(s1));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult2(.a(a2), .b(b2), .rnd(3'd0), .z(m2), .status(s2));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult3(.a(a3), .b(b3), .rnd(3'd0), .z(m3), .status(s3));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult4(.a(a4), .b(b4), .rnd(3'd0), .z(m4), .status(s4));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult5(.a(a5), .b(b5), .rnd(3'd0), .z(m5), .status(s5));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult6(.a(a6), .b(b6), .rnd(3'd0), .z(m6), .status(s6));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult7(.a(a7), .b(b7), .rnd(3'd0), .z(m7), .status(s7));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult8(.a(a8), .b(b8), .rnd(3'd0), .z(m8), .status(s8));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult9(.a(a9), .b(b9), .rnd(3'd0), .z(m9), .status(s9));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult10(.a(a10), .b(b10), .rnd(3'd0), .z(m10), .status(s10));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult11(.a(a11), .b(b11), .rnd(3'd0), .z(m11), .status(s11));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult12(.a(a12), .b(b12), .rnd(3'd0), .z(m12), .status(s12));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult13(.a(a13), .b(b13), .rnd(3'd0), .z(m13), .status(s13));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult14(.a(a14), .b(b14), .rnd(3'd0), .z(m14), .status(s14));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult15(.a(a15), .b(b15), .rnd(3'd0), .z(m15), .status(s15));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult16(.a(a16), .b(b16), .rnd(3'd0), .z(m16), .status(s16));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult17(.a(a17), .b(b17), .rnd(3'd0), .z(m17), .status(s17));
DW_fp_mult #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_mult18(.a(a18), .b(b18), .rnd(3'd0), .z(m18), .status(s18));

DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add1(.a(m18_list[0]), .b(m18_list[1]), .rnd(3'd0), .z(tmp1), .status(s19));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add2(.a(m18_list[2]), .b(m18_list[3]), .rnd(3'd0), .z(tmp2), .status(s20));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add3(.a(m18_list[4]), .b(m18_list[5]), .rnd(3'd0), .z(tmp3), .status(s21));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add4(.a(m18_list[6]), .b(m18_list[7]), .rnd(3'd0), .z(tmp4), .status(s22));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add5(.a(m18_list[8]), .b(m18_list[9]), .rnd(3'd0), .z(tmp5), .status(s23));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add6(.a(m18_list[10]), .b(m18_list[11]), .rnd(3'd0), .z(tmp6), .status(s24));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add7(.a(m18_list[12]), .b(m18_list[13]), .rnd(3'd0), .z(tmp7), .status(s25));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add8(.a(m18_list[14]), .b(m18_list[15]), .rnd(3'd0), .z(tmp8), .status(s26));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add9(.a(m18_list[16]), .b(m18_list[17]), .rnd(3'd0), .z(tmp9), .status(s27));

DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add10(.a(a19_list[0]), .b(a19_list[1]), .rnd(3'd0), .z(tmp10), .status(s28));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add11(.a(a19_list[2]), .b(a19_list[3]), .rnd(3'd0), .z(tmp11), .status(s29));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add12(.a(a19_list[4]), .b(a19_list[5]), .rnd(3'd0), .z(tmp12), .status(s30));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add13(.a(a19_list[6]), .b(a19_list[7]), .rnd(3'd0), .z(tmp13), .status(s31));

DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add14(.a(a19_list[9]), .b(a19_list[10]), .rnd(3'd0), .z(tmp14), .status(s32));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add15(.a(a19_list[11]), .b(a19_list[12]), .rnd(3'd0), .z(tmp15), .status(s33));

DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add16(.a(a19_list[14]), .b(a19_list[15]), .rnd(3'd0), .z(tmp16), .status(s34));

DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add17(.a(a19_list[17]), .b(a19_list[18]), .rnd(3'd0), .z(sp9), .status(s35));


//conv
always @(*)
begin
    for (i = 0; i < 18; i = i + 1)
    begin
        next_m18_list[i] = m18_list[i];
    end
    for (i = 0; i < 19; i = i + 1)
    begin
        next_a19_list[i] = a19_list[i];
    end

    next_m18_list[0] = m1; next_m18_list[1] = m2; next_m18_list[2] = m3; next_m18_list[3] = m4; next_m18_list[4] = m5; next_m18_list[5] = m6;
    next_m18_list[6] = m7; next_m18_list[7] = m8; next_m18_list[8] = m9; next_m18_list[9] = m10; next_m18_list[10] = m11; next_m18_list[11] = m12;
    next_m18_list[12] = m13; next_m18_list[13] = m14; next_m18_list[14] = m15; next_m18_list[15] = m16; next_m18_list[16] = m17; next_m18_list[17] = m18;
    //pipe1
    next_a19_list[0] = tmp1; next_a19_list[1] = tmp2; next_a19_list[2] = tmp3; next_a19_list[3] = tmp4; next_a19_list[4] = tmp5; next_a19_list[5] = tmp6;
    next_a19_list[6] = tmp7; next_a19_list[7] = tmp8; next_a19_list[8] = tmp9; 
    //pipe2
    next_a19_list[9] = tmp10; next_a19_list[10] = tmp11; next_a19_list[11] = tmp12; next_a19_list[12] = tmp13; next_a19_list[13] = a19_list[8];
    //pipe3
    next_a19_list[14] = tmp14; next_a19_list[15] = tmp15; next_a19_list[16] = a19_list[13]; 
    //pipe4
    next_a19_list[17] = tmp16; next_a19_list[18] = a19_list[16];
    
    next_conv_ct = conv_ct;

    if(conv_valid)
    begin
        next_conv_ct = conv_ct + 1;
        //image1
        a1 = img_vec[0]; b1 = kernel_vec[0];
        a2 = img_vec[1]; b2 = kernel_vec[1];
        a3 = img_vec[2]; b3 = kernel_vec[2];
        a4 = img_vec[3]; b4 = kernel_vec[3];
        a5 = img_vec[4]; b5 = kernel_vec[4];
        a6 = img_vec[5]; b6 = kernel_vec[5];
        a7 = img_vec[6]; b7 = kernel_vec[6];
        a8 = img_vec[7]; b8 = kernel_vec[7];
        a9 = img_vec[8]; b9 = kernel_vec[8];
        //image2
        a10 = img2_vec[0]; b10 = kernel2_vec[0];
        a11 = img2_vec[1]; b11 = kernel2_vec[1];
        a12 = img2_vec[2]; b12 = kernel2_vec[2];
        a13 = img2_vec[3]; b13 = kernel2_vec[3];
        a14 = img2_vec[4]; b14 = kernel2_vec[4];
        a15 = img2_vec[5]; b15 = kernel2_vec[5];
        a16 = img2_vec[6]; b16 = kernel2_vec[6];
        a17 = img2_vec[7]; b17 = kernel2_vec[7];
        a18 = img2_vec[8]; b18 = kernel2_vec[8];
    end
    else
    begin
        a1 = 0; b1 = 0; a2 = 0; b2 = 0; a3 = 0; b3 = 0; a4 = 0; b4 = 0;
        a5 = 0; b5 = 0; a6 = 0; b6 = 0; a7 = 0; b7 = 0; a8 = 0; b8 = 0;
        a9 = 0; b9 = 0; a10 = 0; b10 = 0; a11 = 0; b11 = 0; a12 = 0; b12 = 0;
        a13 = 0; b13 = 0; a14 = 0; b14 = 0; a15 = 0; b15 = 0; a16 = 0; b16 = 0;
        a17 = 0; b17 = 0; a18 = 0; b18 = 0;

        next_conv_ct = 0;
        for (i = 0; i < 19; i = i + 1)
        begin
            next_a19_list[i] = 0;
        end
        for (i = 0; i < 18; i = i + 1)
        begin
            next_m18_list[i] = 0;
        end
    end
end

//conv out
always @(*)
begin
    next_conv_out_valid = 0;
    next_conv_out = 0;

    if(conv_ct >= 5)
    begin
        next_conv_out = sp9;
        next_conv_out_valid = 1;
    end
end

always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        conv_out <= 0;
        for (i = 0; i < 18; i = i + 1)
        begin
            m18_list[i] <= 0;
        end
        for (i = 0; i < 19; i = i + 1)
        begin
            a19_list[i] <= 0;
        end
        conv_ct <= 0;
        conv_out_valid <= 0;
    end
    else
    begin
        conv_out <= next_conv_out;
        for (i = 0; i < 18; i = i + 1)
        begin
            m18_list[i] <= next_m18_list[i];
        end
        for (i = 0; i < 19; i = i + 1)
        begin
            a19_list[i] <= next_a19_list[i];
        end
        conv_ct <= next_conv_ct;
        conv_out_valid <= next_conv_out_valid;
    end
end
endmodule

module UNPOOL2X2(
    input [31:0] pool_in [0:3],
    input [1:0] index [0:3],
    output reg [31:0] unpool_out [0:15]
);

integer i, j;

always @(*)
begin
    for (i = 0; i < 2; i = i + 1)
    begin
        for (j = 0; j < 2; j = j + 1) 
        begin
            unpool_out[i * 8 + j * 2 + 0] = (index[i * 2 + j] == 0)? pool_in[i * 2 + j] : 0;
            unpool_out[i * 8 + j * 2 + 1] = (index[i * 2 + j] == 1)? pool_in[i * 2 + j] : 0;
            unpool_out[i * 8 + j * 2 + 4] = (index[i * 2 + j] == 2)? pool_in[i * 2 + j] : 0;
            unpool_out[i * 8 + j * 2 + 5] = (index[i * 2 + j] == 3)? pool_in[i * 2 + j] : 0;
        end
    end
end
endmodule

module UNPOOL4X4(
    input [31:0] pool_in [0:15],
    input [1:0] index [0:15],
    output reg [31:0] unpool_out [0:63]
);

integer i, j;

always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            unpool_out[i * 16 + j * 2 + 0] = (index[i * 4 + j] == 0)? pool_in[i * 4 + j] : 0;
            unpool_out[i * 16 + j * 2 + 1] = (index[i * 4 + j] == 1)? pool_in[i * 4 + j] : 0;
            unpool_out[i * 16 + j * 2 + 8] = (index[i * 4 + j] == 2)? pool_in[i * 4 + j] : 0;
            unpool_out[i * 16 + j * 2 + 9] = (index[i * 4 + j] == 3)? pool_in[i * 4 + j] : 0;
        end
    end
end
endmodule


