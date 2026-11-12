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
reg conv_valid01, next_conv_valid01, conv_valid02, next_conv_valid02, conv_valid11, next_conv_valid11, conv_valid12, next_conv_valid12;
reg deconv_valid01, next_deconv_valid01, deconv_valid02, next_deconv_valid02, deconv_valid11, next_deconv_valid11, deconv_valid12, next_deconv_valid12;
//reg conv_out_valid1, next_conv_out_valid1, conv_out_valid2, next_conv_out_valid2;
reg [1:0] index81 [0:15], next_index81 [0:15], index82 [0:15], next_index82 [0:15], index41 [0:3], next_index41 [0:3], index42 [0:3], next_index42 [0:3];
reg [31:0] conv01_array [0:15], next_conv01_array [0:15], conv02_array [0:15], next_conv02_array [0:15], conv11_array [0:3], next_conv11_array [0:3], conv12_array [0:3], next_conv12_array [0:3];
reg [31:0] deconv01_array [0:15], next_deconv01_array [0:15], deconv02_array [0:15], next_deconv02_array [0:15], deconv11_array [0:63], next_deconv11_array [0:63], deconv12_array [0:63], next_deconv12_array [0:63];
reg [7:0] out_ct, next_out_ct;
reg start_out, next_start_out;

wire conv_out_valid01, conv_out_valid02, conv_out_valid11, conv_out_valid12;
wire [31:0] conv_out_data01 [0:15], conv_out_data02 [0:15], conv_out_data11 [0:3], conv_out_data12 [0:3];
wire [31:0] deconv_out_data01 [0:15], deconv_out_data02 [0:15], deconv_out_data11 [0:63], deconv_out_data12 [0:63];
wire [1:0] index8_list1 [0:15], index4_list1 [0:3], index8_list2 [0:15], index4_list2 [0:3];
wire [31:0] unpool_out1 [0:15], unpool_out2 [0:15], unpool_out3 [0:63], unpool_out4 [0:63];
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
        if(in_ct >= 66 && in_ct <= 73) //66-73
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
        else if(in_ct >= 130 && in_ct <= 137) //130-137
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
    else if(image_in_valid || in_ct == 128 || in_ct == 129)
    begin
        next_in_ct = in_ct + 1;
    end
    else if(mm_valid)
        next_in_ct = in_ct + 1;
    else
        next_in_ct = 0;

    if(in_ct == 137)
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
DW_fp_div #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_faithful_round) u_div1(.a(32'h3f800000), .b(mm_sub1), .rnd(3'd0), .z(div_out1), .status(sts3));
DW_fp_div #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_faithful_round) u_div2(.a(32'h3f800000), .b(mm_sub2), .rnd(3'd0), .z(div_out2), .status(sts4));

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
        next_reciprocal1 = div_out1;
    end

    if(in_ct == 129)
    begin
        next_reciprocal2 = div_out2;
    end

    if(image_in_valid_buf && in_ct == 65)//66-73
        next_mm_valid = 1;
    else if(image_in_valid_buf && in_ct == 73)
        next_mm_valid = 0;
    else if(image_in_valid_buf && in_ct == 129)//130-137
        next_mm_valid = 1;
    else if(image_in_valid_buf && in_ct == 137)
        next_mm_valid = 0;

    if(mm_valid)
    begin
        if(in_ct >= 66 && in_ct <= 73)//66-73
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
        else if(in_ct >= 130 && in_ct <= 137)//130-137
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
// array to vector
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            img1_vec[i*8+j] = img1[i][j];
            img2_vec[i*8+j] = img2[i][j];
        end
    end
end
// clock, reset_n, conv_valid, instruction, img1_vec, img2_vec, kernel_vec, kernel2_vec, conv_out_valid, out_index, conv_out_data
CONV8X8 u_conv0(.clock(clk), .reset_n(rst_n), .conv_valid(conv_valid01), .instruction(instruction), .img_vec(img1_vec), .img2_vec(img2_vec), 
    .kernel_vec(wt1), .kernel2_vec(wt2), .conv_out_valid(conv_out_valid01), .out_index(index8_list1), .conv_out(conv_out_data01));
CONV8X8 u_conv1(.clock(clk), .reset_n(rst_n), .conv_valid(conv_valid02), .instruction(instruction), .img_vec(img1_vec), .img2_vec(img2_vec),
    .kernel_vec(wt3), .kernel2_vec(wt4), .conv_out_valid(conv_out_valid02), .out_index(index8_list2), .conv_out(conv_out_data02));

CONV4X4 u_conv2(.clock(clk), .reset_n(rst_n), .conv_valid(conv_valid11), .instruction(instruction), .img_vec(conv01_array), .img2_vec(conv02_array),
    .kernel_vec(wt5), .kernel2_vec(wt6), .conv_out_valid(conv_out_valid11), .out_index(index4_list1), .conv_out(conv_out_data11));
CONV4X4 u_conv3(.clock(clk), .reset_n(rst_n), .conv_valid(conv_valid12), .instruction(instruction), .img_vec(conv01_array), .img2_vec(conv02_array),
    .kernel_vec(wt7), .kernel2_vec(wt8), .conv_out_valid(conv_out_valid12), .out_index(index4_list2), .conv_out(conv_out_data12));

UNPOOL2X2 u_unpool0(.pool_in(conv11_array), .index(index41), .unpool_out(unpool_out1));
UNPOOL2X2 u_unpool1(.pool_in(conv12_array), .index(index42), .unpool_out(unpool_out2));

DECONV4X4 u_deconv0(.clock(clk), .reset_n(rst_n), .deconv_valid(deconv_valid01), .instruction(instruction), .img_vec(unpool_out1), .img2_vec(unpool_out2),
    .kernel_vec(wt9), .kernel2_vec(wt10), .deconv_out_valid(deconv_out_valid01), .deconv_out(deconv_out_data01));
DECONV4X4 u_deconv1(.clock(clk), .reset_n(rst_n), .deconv_valid(deconv_valid02), .instruction(instruction), .img_vec(unpool_out1), .img2_vec(unpool_out2),
    .kernel_vec(wt11), .kernel2_vec(wt12), .deconv_out_valid(deconv_out_valid02), .deconv_out(deconv_out_data02));

UNPOOL4X4 u_unpool2(.pool_in(deconv01_array), .index(index81), .unpool_out(unpool_out3));
UNPOOL4X4 u_unpool3(.pool_in(deconv02_array), .index(index82), .unpool_out(unpool_out4));

DECONV8X8 u_deconv2(.clock(clk), .reset_n(rst_n), .deconv_valid(deconv_valid11), .instruction(instruction), .img_vec(unpool_out3), .img2_vec(unpool_out4),
    .kernel_vec(wt13), .kernel2_vec(wt14), .deconv_out_valid(deconv_out_valid11), .deconv_out(deconv_out_data11));
DECONV8X8 u_deconv3(.clock(clk), .reset_n(rst_n), .deconv_valid(deconv_valid12), .instruction(instruction), .img_vec(unpool_out3), .img2_vec(unpool_out4),
    .kernel_vec(wt15), .kernel2_vec(wt16), .deconv_out_valid(deconv_out_valid12), .deconv_out(deconv_out_data12));

always @(*)
begin
    next_conv_valid01 = conv_valid01;
    next_conv_valid02 = conv_valid02;
    next_conv_valid11 = conv_valid11;
    next_conv_valid12 = conv_valid12;
    next_deconv_valid01 = deconv_valid01;
    next_deconv_valid02 = deconv_valid02;
    next_deconv_valid11 = deconv_valid11;
    next_deconv_valid12 = deconv_valid12;
    for (i = 0; i < 16; i = i + 1)
    begin
        next_index81[i] = index81[i];
        next_index82[i] = index82[i];
        next_conv01_array[i] = conv01_array[i];
        next_conv02_array[i] = conv02_array[i];
        next_deconv01_array[i] = deconv01_array[i];
        next_deconv02_array[i] = deconv02_array[i];
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        next_index41[i] = index41[i];
        next_index42[i] = index42[i];
        next_conv11_array[i] = conv11_array[i];
        next_conv12_array[i] = conv12_array[i];
    end
    for (i = 0; i < 64; i = i + 1)
    begin
        next_deconv11_array[i] = deconv11_array[i];
        next_deconv12_array[i] = deconv12_array[i];
    end

    if(in_ct == 137 && !weight_in_valid)
    begin
        next_conv_valid01 = 1;
        next_conv_valid02 = 1;
    end
    if(conv_out_valid01 || conv_out_valid02)
    begin
        next_conv_valid01 = 0;
        next_conv_valid02 = 0;
    end

    if(conv_out_valid01 && conv_out_valid02)
    begin
        next_conv_valid11 = 1;
        next_conv_valid12 = 1;
    end
    if(conv_out_valid11 || conv_out_valid12)
    begin
        next_conv_valid11 = 0;
        next_conv_valid12 = 0;
    end

    if(conv_out_valid11 && conv_out_valid12)
    begin
        next_deconv_valid01 = 1;
        next_deconv_valid02 = 1;
    end
    if(deconv_out_valid01 || deconv_out_valid02)
    begin
        next_deconv_valid01 = 0;
        next_deconv_valid02 = 0;
    end

    if(deconv_out_valid01 && deconv_out_valid02)
    begin
        next_deconv_valid11 = 1;
        next_deconv_valid12 = 1;
    end
    if(deconv_out_valid11 || deconv_out_valid12)
    begin
        next_deconv_valid11 = 0;
        next_deconv_valid12 = 0;
    end

    if(conv_out_valid01)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_index81[i] = index8_list1[i];
            next_conv01_array[i] = conv_out_data01[i];
        end
    end
    if(conv_out_valid02)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_index82[i] = index8_list2[i];
            next_conv02_array[i] = conv_out_data02[i];
        end
    end

    if(conv_out_valid11)
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            next_index41[i] = index4_list1[i];
            next_conv11_array[i] = conv_out_data11[i];
        end
    end
    if(conv_out_valid12)
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            next_index42[i] = index4_list2[i];
            next_conv12_array[i] = conv_out_data12[i];
        end
    end

    if(deconv_out_valid01)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_deconv01_array[i] = deconv_out_data01[i];
        end
    end
    if(deconv_out_valid02)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            next_deconv02_array[i] = deconv_out_data02[i];
        end
    end

    if(deconv_out_valid11)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            next_deconv11_array[i] = deconv_out_data11[i];
        end
    end
    if(deconv_out_valid12)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            next_deconv12_array[i] = deconv_out_data12[i];
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

    if(deconv_out_valid11 && deconv_out_valid12)
    begin
        next_start_out = 1;
    end

    if(start_out)
    begin
        next_out_valid = 1;
        if(out_ct < 64)//0-63
        begin
            next_out_data = deconv11_array[out_ct];
        end
        else if(out_ct < 128)//64-127
        begin
            next_out_data = deconv12_array[out_ct-64];
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
            conv01_array[i] <= 0;
            conv02_array[i] <= 0;
            deconv01_array[i] <= 0;
            deconv02_array[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            index41[i] <= 0;
            index42[i] <= 0;
            conv11_array[i] <= 0;
            conv12_array[i] <= 0;
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            deconv11_array[i] <= 0;
            deconv12_array[i] <= 0;
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
        conv_valid01 <= 0;
        conv_valid02 <= 0;
        conv_valid11 <= 0;
        conv_valid12 <= 0;
        deconv_valid01 <= 0;
        deconv_valid02 <= 0;
        deconv_valid11 <= 0;
        deconv_valid12 <= 0;
        out_ct <= 0;
        start_out <= 0;
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
            conv01_array[i] <= next_conv01_array[i];
            conv02_array[i] <= next_conv02_array[i];
            deconv01_array[i] <= next_deconv01_array[i];
            deconv02_array[i] <= next_deconv02_array[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            index41[i] <= next_index41[i];
            index42[i] <= next_index42[i];
            conv11_array[i] <= next_conv11_array[i];
            conv12_array[i] <= next_conv12_array[i];
        end
        for (i = 0; i < 64; i = i + 1)
        begin
            deconv11_array[i] <= next_deconv11_array[i];
            deconv12_array[i] <= next_deconv12_array[i];
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
        conv_valid01 <= next_conv_valid01;
        conv_valid02 <= next_conv_valid02;
        conv_valid11 <= next_conv_valid11;
        conv_valid12 <= next_conv_valid12;
        deconv_valid01 <= next_deconv_valid01;
        deconv_valid02 <= next_deconv_valid02;
        deconv_valid11 <= next_deconv_valid11;
        deconv_valid12 <= next_deconv_valid12;
        out_ct <= next_out_ct;
        start_out <= next_start_out;
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

wire [31:0] mult2_1, exp3, add4, add5, div6, mult7;
wire agtb1, agtb2, aeq1, aeq2, altb1, altb2, un1, un2;
wire [7:0] sts1, sts2, sts3, sts4, sts5, sts6, sts7, sts8, sts9, sts10;
wire [31:0] cz01, cz11, cz02, cz12; 

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(x_2), .b(a), .rnd(3'd0), .z(mult2_1), .status(sts1));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U3 ( .a(x_3), .z(exp3), .status(sts2));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U4 ( .a(x_4), .b(32'h3f800000), .rnd(3'd0), .z(add4), .status(sts3));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U5 ( .a(exp5), .b(32'hbf800000), .rnd(3'd0), .z(add5), .status(sts4));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U6 ( .a(temp), .b(x_6), .rnd(3'd0), .z(div6), .status(sts5));

//1
always @(*)
begin
    x_1 = 0;
    mode_1 = 0;
    v1 = 0;
    if(act_valid)
    begin
        v1 = 1;
        x_1 = data_in;
        mode_1 = instruction[1:0];
    end
    next_a = a;

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
    end
    else
    begin
        v2 <= v1;
        x_2 <= x_1;
        mode_2 <= mode_1;
        a <= next_a;
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
    end
    else
    begin
        v3 <= v2;
        x_3 <= x_comb2;
        mode_3 <= mode_2;
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
    end
    else
    begin
        v4 <= v3;
        x_4 <= x_comb3;
        mode_4 <= mode_3;
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
    end
    else
    begin
        exp5 <= exp4;
        v5 <= v4;
        x_5 <= x_comb4;
        mode_5 <= mode_4;
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
    end
    else
    begin
        v6 <= v5;
        x_6 <= x_comb5;
        mode_6 <= mode_5;
        temp <= temp_comb;
    end
end

DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp(.a(cpa1), .b(32'h00000000), .zctr(1'b0), .aeqb(aeq1), .altb(altb1), .agtb(agtb1), .unordered(un1), .z0(cz01), .z1(cz11), .status0(sts6), .status1(sts7));
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
    u_cmp2(.a(cpa2), .b(32'h82000000), .zctr(1'b0), .aeqb(aeq2), .altb(altb2), .agtb(agtb2), .unordered(un2), .z0(cz02), .z1(cz12), .status0(sts8), .status1(sts9));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U7 ( .a(data_in), .b(32'h3e000000), .rnd(3'd0), .z(mult7), .status(sts10));

//6
always @(*)
begin
    next_act_out_valid = 0;
    next_data_out = 0;
    cpa1 = 0;
    cpa2 = 0;

    if(mode_1 == 2'b00 || mode_1 == 2'b01)
    begin
        next_act_out_valid = v6;
        next_data_out = div6;
    end

    if(mode_1 == 2'b10)//relu
    begin
        next_act_out_valid = act_valid;
        cpa1 = data_in;
        if(agtb1)
            next_data_out = data_in;
        else
            next_data_out = 0;
    end
    else if(mode_1 == 2'b11)//leaky relu
    begin
        next_act_out_valid = act_valid;
        cpa1 = data_in;
        cpa2 = data_in;
        if(agtb1) //x > 0
            next_data_out = data_in;
        else
        begin
            if(agtb2) // -2^-123 < x <= 0
                next_data_out = 0; 
            else
                next_data_out = mult7;
        end
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
wire st1, st2, st3, sts4, sts5, sts6, un1, un2, un3;
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

module CONV8X8 (
    input clock,
    input reset_n,
    input conv_valid,
    input [2:0] instruction,
    input [31:0] img_vec [0:63],
    input [31:0] img2_vec [0:63],
    input [31:0] kernel_vec [0:8],
    input [31:0] kernel2_vec [0:8],
    output reg conv_out_valid,
    output reg [1:0] out_index [0:15],
    output reg [31:0] conv_out [0:15]
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
integer i, j;
reg [31:0] next_conv_out [0:15];
reg [1:0] next_out_index [0:15], index_list [0:15], next_index_list [0:15];
reg [31:0] conv_array [0:7][0:7], next_conv_array [0:7][0:7];
reg [31:0] img_array [0:7][0:7], img2_array [0:7][0:7];
reg [31:0] kernel_array [0:2][0:2], kernel2_array [0:2][0:2];
reg [31:0] image [0:9][0:9], image2 [0:9][0:9];
reg [2:0] ki, next_ki, kj, next_kj;
reg [31:0] a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18;
reg [31:0] b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18;
reg [31:0] mult_list [0:5], next_mult_list [0:5];
reg [6:0] conv_ct, next_conv_ct;
reg next_conv_out_valid, act_valid, next_act_valid;
reg [31:0] mp_array [0:3][0:3], next_mp_array [0:3][0:3];
reg [31:0] cpa1, cpa2, cpb1, cpb2;
reg [31:0] data_in;
reg [4:0] out_ct, next_out_ct;

//wire [31:0] p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18;
wire [7:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27;
wire [31:0] sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9;
wire [31:0] cp1, cp2, cp3, cp4;
wire [31:0] data_out;
wire [1:0] idx;
wire act_out_valid;

//vector to array
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            img_array[i][j] = img_vec[i*8+j];
            img2_array[i][j] = img2_vec[i*8+j];
        end
    end
    for (i = 0; i < 3; i = i + 1)
    begin
        for (j = 0; j < 3; j = j + 1)
        begin
            kernel_array[i][j] = kernel_vec[i*3+j];
            kernel2_array[i][j] = kernel2_vec[i*3+j];
        end
    end
end
//padding
always @(*)
begin
    for (i = 0; i < 10; i = i + 1)
    begin
        for (j = 0; j < 10; j = j + 1)
        begin
            if(i >= 1 && i <= 8 && j >= 1 && j <= 8)
            begin
                image[i][j] = img_array[i-1][j-1];
                image2[i][j] = img2_array[i-1][j-1];
            end
            else
            begin
                if(instruction[2] == 0)//zero padding
                begin
                    image[i][j] = 0;
                    image2[i][j] = 0;
                end
            end
        end
    end
    if(instruction[2] == 1)//reflication padding
    begin
        image[0][0] = img_array[0][0];
        image[0][1:8] = img_array[0][0:7];
        image[0][9] = img_array[0][7];
        image[9][0] = img_array[7][0];
        image[9][1:8] = img_array[7][0:7];
        image[9][9] = img_array[7][7];
        for(i = 1; i < 9; i = i + 1)
        begin
            image[i][0] = img_array[i-1][0];
            image[i][9] = img_array[i-1][7];
        end
        image2[0][0] = img2_array[0][0];
        image2[0][1:8] = img2_array[0][0:7];
        image2[0][9] = img2_array[0][7];
        image2[9][0] = img2_array[7][0];
        image2[9][1:8] = img2_array[7][0:7];
        image2[9][9] = img2_array[7][7];
        for(i = 1; i < 9; i = i + 1)
        begin
            image2[i][0] = img2_array[i-1][0];
            image2[i][9] = img2_array[i-1][7];
        end
    end
end

DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp3(.a(a1), .b(b1), .c(a2), .d(b2), .e(a3), .f(b3), .rnd(3'd0), .z(sp1), .status(s1));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp4(.a(a4), .b(b4), .c(a5), .d(b5), .e(a6), .f(b6), .rnd(3'd0), .z(sp2), .status(s2));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp5(.a(a7), .b(b7), .c(a8), .d(b8), .e(a9), .f(b9), .rnd(3'd0), .z(sp3), .status(s3));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type)
    u_dp6(.a(a10), .b(b10), .c(a11), .d(b11), .e(a12), .f(b12), .rnd(3'd0), .z(sp4), .status(s4));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp7(.a(a13), .b(b13), .c(a14), .d(b14), .e(a15), .f(b15), .rnd(3'd0), .z(sp5), .status(s5));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp8(.a(a16), .b(b16), .c(a17), .d(b17), .e(a18), .f(b18), .rnd(3'd0), .z(sp6), .status(s6));

DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_7(.a(mult_list[0]), .b(mult_list[1]), .c(mult_list[2]), .rnd(3'd0), .z(sp7), .status(s7));
DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_8(.a(mult_list[3]), .b(mult_list[4]), .c(mult_list[5]), .rnd(3'd0), .z(sp8), .status(s8));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add(.a(sp7), .b(sp8), .rnd(3'd0), .z(sp9), .status(s9));

//conv
always @(*)
begin
    next_ki = ki;
    next_kj = kj;
    for (i = 0; i < 6; i = i + 1)
    begin
        next_mult_list[i] = mult_list[i];
    end

    next_mult_list[0] = sp1;
    next_mult_list[1] = sp2;
    next_mult_list[2] = sp3;
    next_mult_list[3] = sp4;
    next_mult_list[4] = sp5;
    next_mult_list[5] = sp6;
    next_conv_ct = conv_ct;

    if(conv_valid)
    begin
        next_conv_ct = conv_ct + 1;
        next_kj = kj + 1;
        if(kj == 7)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 7)
            begin
                next_ki = 0;
            end
        end
        //image1
        a1 = image[ki][kj]; b1 = kernel_array[0][0];
        a2 = image[ki][kj+1]; b2 = kernel_array[0][1];
        a3 = image[ki][kj+2]; b3 = kernel_array[0][2];
        a4 = image[ki+1][kj]; b4 = kernel_array[1][0];
        a5 = image[ki+1][kj+1]; b5 = kernel_array[1][1];
        a6 = image[ki+1][kj+2]; b6 = kernel_array[1][2];
        a7 = image[ki+2][kj]; b7 = kernel_array[2][0];
        a8 = image[ki+2][kj+1]; b8 = kernel_array[2][1];
        a9 = image[ki+2][kj+2]; b9 = kernel_array[2][2];
        //image2
        a10 = image2[ki][kj]; b10 = kernel2_array[0][0];
        a11 = image2[ki][kj+1]; b11 = kernel2_array[0][1];
        a12 = image2[ki][kj+2]; b12 = kernel2_array[0][2];
        a13 = image2[ki+1][kj]; b13 = kernel2_array[1][0];
        a14 = image2[ki+1][kj+1]; b14 = kernel2_array[1][1];
        a15 = image2[ki+1][kj+2]; b15 = kernel2_array[1][2];
        a16 = image2[ki+2][kj]; b16 = kernel2_array[2][0];
        a17 = image2[ki+2][kj+1]; b17 = kernel2_array[2][1];
        a18 = image2[ki+2][kj+2]; b18 = kernel2_array[2][2];
    end
    else
    begin
        a1 = 0; b1 = 0; a2 = 0; b2 = 0; a3 = 0; b3 = 0; a4 = 0; b4 = 0;
        a5 = 0; b5 = 0; a6 = 0; b6 = 0; a7 = 0; b7 = 0; a8 = 0; b8 = 0;
        a9 = 0; b9 = 0; a10 = 0; b10 = 0; a11 = 0; b11 = 0; a12 = 0; b12 = 0;
        a13 = 0; b13 = 0; a14 = 0; b14 = 0; a15 = 0; b15 = 0; a16 = 0; b16 = 0;
        a17 = 0; b17 = 0; a18 = 0; b18 = 0;

        next_conv_ct = 0;
        next_ki = 0;
        next_kj = 0;
        for (i = 0; i < 6; i = i + 1)
        begin
            next_mult_list[i] = 0;
        end
    end

    
end
//conv_array
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            next_conv_array[i][j] = conv_array[i][j];
        end
    end
    for (i = 1; i < 65; i = i + 1)//1-64
    begin
        if(conv_ct == i)
        begin
            next_conv_array[(i-1)/8][(i-1)%8] = sp9;
        end
    end
end

MAXPOOL m0(.mp1(cpa1), .mp2(cpb1), .mp3(cpa2), .mp4(cpb2), .index(idx), .pool_out(cp3));

//mp_array
always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            next_mp_array[i][j] = mp_array[i][j];
        end
    end
    for (i = 0; i < 16; i = i + 1)
    begin
        next_index_list[i] = index_list[i];
    end
    cpa1 = 0; cpb1 = 0; cpa2 = 0; cpb2 = 0;

    case(conv_ct)
        51: begin
            cpa1 = conv_array[0][0]; cpb1 = conv_array[0][1]; cpa2 = conv_array[1][0]; cpb2 = conv_array[1][1]; next_mp_array[0][0] = cp3; next_index_list[0] = idx;
        end
        52: begin
            cpa1 = conv_array[0][2]; cpb1 = conv_array[0][3]; cpa2 = conv_array[1][2]; cpb2 = conv_array[1][3]; next_mp_array[0][1] = cp3; next_index_list[1] = idx;
        end
        53: begin
            cpa1 = conv_array[0][4]; cpb1 = conv_array[0][5]; cpa2 = conv_array[1][4]; cpb2 = conv_array[1][5]; next_mp_array[0][2] = cp3; next_index_list[2] = idx;
        end
        54: begin
            cpa1 = conv_array[0][6]; cpb1 = conv_array[0][7]; cpa2 = conv_array[1][6]; cpb2 = conv_array[1][7]; next_mp_array[0][3] = cp3; next_index_list[3] = idx;
        end
        55: begin
            cpa1 = conv_array[2][0]; cpb1 = conv_array[2][1]; cpa2 = conv_array[3][0]; cpb2 = conv_array[3][1]; next_mp_array[1][0] = cp3; next_index_list[4] = idx;
        end
        56: begin
            cpa1 = conv_array[2][2]; cpb1 = conv_array[2][3]; cpa2 = conv_array[3][2]; cpb2 = conv_array[3][3]; next_mp_array[1][1] = cp3; next_index_list[5] = idx;
        end
        57: begin
            cpa1 = conv_array[2][4]; cpb1 = conv_array[2][5]; cpa2 = conv_array[3][4]; cpb2 = conv_array[3][5]; next_mp_array[1][2] = cp3; next_index_list[6] = idx;
        end
        58: begin
            cpa1 = conv_array[2][6]; cpb1 = conv_array[2][7]; cpa2 = conv_array[3][6]; cpb2 = conv_array[3][7]; next_mp_array[1][3] = cp3; next_index_list[7] = idx;
        end
        59: begin
            cpa1 = conv_array[4][0]; cpb1 = conv_array[4][1]; cpa2 = conv_array[5][0]; cpb2 = conv_array[5][1]; next_mp_array[2][0] = cp3; next_index_list[8] = idx;
        end
        60: begin
            cpa1 = conv_array[4][2]; cpb1 = conv_array[4][3]; cpa2 = conv_array[5][2]; cpb2 = conv_array[5][3]; next_mp_array[2][1] = cp3; next_index_list[9] = idx;
        end
        61: begin
            cpa1 = conv_array[4][4]; cpb1 = conv_array[4][5]; cpa2 = conv_array[5][4]; cpb2 = conv_array[5][5]; next_mp_array[2][2] = cp3; next_index_list[10] = idx;
        end
        62: begin
            cpa1 = conv_array[4][6]; cpb1 = conv_array[4][7]; cpa2 = conv_array[5][6]; cpb2 = conv_array[5][7]; next_mp_array[2][3] = cp3; next_index_list[11] = idx;
        end
        63: begin
            cpa1 = conv_array[6][0]; cpb1 = conv_array[6][1]; cpa2 = conv_array[7][0]; cpb2 = conv_array[7][1]; next_mp_array[3][0] = cp3; next_index_list[12] = idx;
        end
        64: begin
            cpa1 = conv_array[6][2]; cpb1 = conv_array[6][3]; cpa2 = conv_array[7][2]; cpb2 = conv_array[7][3]; next_mp_array[3][1] = cp3; next_index_list[13] = idx;
        end
        65: begin
            cpa1 = conv_array[6][4]; cpb1 = conv_array[6][5]; cpa2 = conv_array[7][4]; cpb2 = conv_array[7][5]; next_mp_array[3][2] = cp3; next_index_list[14] = idx;
        end
        66: begin
            cpa1 = conv_array[6][6]; cpb1 = conv_array[6][7]; cpa2 = conv_array[7][6]; cpb2 = conv_array[7][7]; next_mp_array[3][3] = cp3; next_index_list[15] = idx;
        end
    endcase
end

ACTFCT u_actfct(.clock(clock), .reset_n(reset_n), .act_valid(act_valid), .instruction(instruction), .data_in(data_in), .act_out_valid(act_out_valid), .data_out(data_out));

//act_valid
always @(*)
begin
    next_act_valid = act_valid;
    data_in = 0;

    if(conv_ct == 51)
    begin
        next_act_valid = 1;
    end
    if(conv_out_valid)
    begin
        next_act_valid = 0;
    end

    case(conv_ct)
        52: data_in = mp_array[0][0];
        53: data_in = mp_array[0][1];
        54: data_in = mp_array[0][2];
        55: data_in = mp_array[0][3];
        56: data_in = mp_array[1][0];
        57: data_in = mp_array[1][1];
        58: data_in = mp_array[1][2];
        59: data_in = mp_array[1][3];
        60: data_in = mp_array[2][0];
        61: data_in = mp_array[2][1];
        62: data_in = mp_array[2][2];
        63: data_in = mp_array[2][3];
        64: data_in = mp_array[3][0];
        65: data_in = mp_array[3][1];
        66: data_in = mp_array[3][2];
        67: data_in = mp_array[3][3];
    endcase
end
//conv out
always @(*)
begin
    next_out_ct = out_ct;
    next_conv_out_valid = 0;
    for (i = 0; i < 16; i = i + 1)
    begin
        next_conv_out[i] = conv_out[i];
        next_out_index[i] = out_index[i];
    end

    if(act_out_valid && out_ct < 16 && next_conv_ct != 0)
    begin
        next_conv_out[out_ct] = data_out;
        next_out_index[out_ct] = index_list[out_ct];
        next_out_ct = out_ct + 1;
    end
    if(out_ct == 15)
    begin
        next_conv_out_valid = 1;
    end
    if(out_ct == 16)
    begin
        next_conv_out_valid = 0;
        next_out_ct = 0;
        for (i = 0; i < 16; i = i + 1)
        begin
            next_conv_out[i] = 0;
            next_out_index[i] = 0;
        end
    end
end

always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            conv_out[i] <= 0;
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            out_index[i] <= 0;
            index_list[i] <= 0;
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                conv_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                mp_array[i][j] <= 0;
            end
        end
        ki <= 0;
        kj <= 0;
        conv_ct <= 0;
        conv_out_valid <= 0;
        act_valid <= 0;
        out_ct <= 0;
    end
    else
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            conv_out[i] <= next_conv_out[i];
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            out_index[i] <= next_out_index[i];
            index_list[i] <= next_index_list[i];
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= next_mult_list[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                conv_array[i][j] <= next_conv_array[i][j];
            end
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                mp_array[i][j] <= next_mp_array[i][j];
            end
        end
        ki <= next_ki;
        kj <= next_kj;
        conv_ct <= next_conv_ct;
        conv_out_valid <= next_conv_out_valid;
        act_valid <= next_act_valid;
        out_ct <= next_out_ct;
    end
end
endmodule

module CONV4X4 (
    input clock,
    input reset_n,
    input conv_valid,
    input [2:0] instruction,
    input [31:0] img_vec [0:15],
    input [31:0] img2_vec [0:15],
    input [31:0] kernel_vec [0:8],
    input [31:0] kernel2_vec [0:8],
    output reg conv_out_valid,
    output reg [1:0] out_index [0:3],
    output reg [31:0] conv_out [0:3]
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
integer i, j;
reg [31:0] next_conv_out [0:3];
reg [1:0] next_out_index [0:3], index_list [0:3], next_index_list [0:3];
reg [31:0] conv_array [0:3][0:3], next_conv_array [0:3][0:3];
reg [31:0] img_array [0:3][0:3], img2_array [0:3][0:3];
reg [31:0] kernel_array [0:2][0:2], kernel2_array [0:2][0:2];
reg [31:0] image [0:5][0:5], image2 [0:5][0:5];
reg [2:0] ki, next_ki, kj, next_kj;
reg [31:0] a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18;
reg [31:0] b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18;
reg [31:0] mult_list [0:5], next_mult_list [0:5];
reg [6:0] conv_ct, next_conv_ct;
reg next_conv_out_valid, act_valid, next_act_valid;
reg [31:0] mp_array [0:1][0:1], next_mp_array [0:1][0:1];
reg [31:0] cpa1, cpa2, cpb1, cpb2;
reg [31:0] data_in;
reg [3:0] out_ct, next_out_ct;

wire [31:0] sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9;
wire [7:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;
wire [31:0] cp1, cp2, cp3, cp4, data_out;
wire [1:0] idx;
wire act_out_valid;

//vector to array
always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            img_array[i][j] = img_vec[i*4+j];
            img2_array[i][j] = img2_vec[i*4+j];
        end
    end
    for (i = 0; i < 3; i = i + 1)
    begin
        for (j = 0; j < 3; j = j + 1)
        begin
            kernel_array[i][j] = kernel_vec[i*3+j];
            kernel2_array[i][j] = kernel2_vec[i*3+j];
        end
    end
end
//padding
always @(*)
begin
    for (i = 0; i < 6; i = i + 1)
    begin
        for (j = 0; j < 6; j = j + 1)
        begin
            if(i >= 1 && i <= 4 && j >= 1 && j <= 4)
            begin
                image[i][j] = img_array[i-1][j-1];
                image2[i][j] = img2_array[i-1][j-1];
            end
            else
            begin
                if(instruction[2] == 0)//zero padding
                begin
                    image[i][j] = 0;
                    image2[i][j] = 0;
                end
            end
        end
    end
    if(instruction[2] == 1)//reflication padding
    begin
        image[0][0] = img_array[0][0];
        image[0][1:4] = img_array[0][0:3];
        image[0][5] = img_array[0][3];
        image[5][0] = img_array[3][0];
        image[5][1:4] = img_array[3][0:3];
        image[5][5] = img_array[3][3];
        for(i = 1; i < 5; i = i + 1)
        begin
            image[i][0] = img_array[i-1][0];
            image[i][5] = img_array[i-1][3];
        end
        image2[0][0] = img2_array[0][0];
        image2[0][1:4] = img2_array[0][0:3];
        image2[0][5] = img2_array[0][3];
        image2[5][0] = img2_array[3][0];
        image2[5][1:4] = img2_array[3][0:3];
        image2[5][5] = img2_array[3][3];
        for(i = 1; i < 5; i = i + 1)
        begin
            image2[i][0] = img2_array[i-1][0];
            image2[i][5] = img2_array[i-1][3];
        end
    end
end

DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp3(.a(a1), .b(b1), .c(a2), .d(b2), .e(a3), .f(b3), .rnd(3'd0), .z(sp1), .status(s1));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp4(.a(a4), .b(b4), .c(a5), .d(b5), .e(a6), .f(b6), .rnd(3'd0), .z(sp2), .status(s2));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp5(.a(a7), .b(b7), .c(a8), .d(b8), .e(a9), .f(b9), .rnd(3'd0), .z(sp3), .status(s3));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type)
    u_dp6(.a(a10), .b(b10), .c(a11), .d(b11), .e(a12), .f(b12), .rnd(3'd0), .z(sp4), .status(s4));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp7(.a(a13), .b(b13), .c(a14), .d(b14), .e(a15), .f(b15), .rnd(3'd0), .z(sp5), .status(s5));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp8(.a(a16), .b(b16), .c(a17), .d(b17), .e(a18), .f(b18), .rnd(3'd0), .z(sp6), .status(s6));

DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_7(.a(mult_list[0]), .b(mult_list[1]), .c(mult_list[2]), .rnd(3'd0), .z(sp7), .status(s7));
DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_8(.a(mult_list[3]), .b(mult_list[4]), .c(mult_list[5]), .rnd(3'd0), .z(sp8), .status(s8));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add(.a(sp7), .b(sp8), .rnd(3'd0), .z(sp9), .status(s9));

//conv
always @(*)
begin
    next_ki = ki;
    next_kj = kj;
    for (i = 0; i < 6; i = i + 1)
    begin
        next_mult_list[i] = mult_list[i];
    end

    next_mult_list[0] = sp1;
    next_mult_list[1] = sp2;
    next_mult_list[2] = sp3;
    next_mult_list[3] = sp4;
    next_mult_list[4] = sp5;
    next_mult_list[5] = sp6;
    next_conv_ct = conv_ct;

    if(conv_valid)
    begin
        next_conv_ct = conv_ct + 1;
        next_kj = kj + 1;
        if(kj == 3)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 3)
            begin
                next_ki = 0;
            end
        end
        //image1
        a1 = image[ki][kj]; b1 = kernel_array[0][0];
        a2 = image[ki][kj+1]; b2 = kernel_array[0][1];
        a3 = image[ki][kj+2]; b3 = kernel_array[0][2];
        a4 = image[ki+1][kj]; b4 = kernel_array[1][0];
        a5 = image[ki+1][kj+1]; b5 = kernel_array[1][1];
        a6 = image[ki+1][kj+2]; b6 = kernel_array[1][2];
        a7 = image[ki+2][kj]; b7 = kernel_array[2][0];
        a8 = image[ki+2][kj+1]; b8 = kernel_array[2][1];
        a9 = image[ki+2][kj+2]; b9 = kernel_array[2][2];
        //image2
        a10 = image2[ki][kj]; b10 = kernel2_array[0][0];
        a11 = image2[ki][kj+1]; b11 = kernel2_array[0][1];
        a12 = image2[ki][kj+2]; b12 = kernel2_array[0][2];
        a13 = image2[ki+1][kj]; b13 = kernel2_array[1][0];
        a14 = image2[ki+1][kj+1]; b14 = kernel2_array[1][1];
        a15 = image2[ki+1][kj+2]; b15 = kernel2_array[1][2];
        a16 = image2[ki+2][kj]; b16 = kernel2_array[2][0];
        a17 = image2[ki+2][kj+1]; b17 = kernel2_array[2][1];
        a18 = image2[ki+2][kj+2]; b18 = kernel2_array[2][2];
    end
    else
    begin
        a1 = 0; b1 = 0; a2 = 0; b2 = 0; a3 = 0; b3 = 0; a4 = 0; b4 = 0;
        a5 = 0; b5 = 0; a6 = 0; b6 = 0; a7 = 0; b7 = 0; a8 = 0; b8 = 0;
        a9 = 0; b9 = 0; a10 = 0; b10 = 0; a11 = 0; b11 = 0; a12 = 0; b12 = 0;
        a13 = 0; b13 = 0; a14 = 0; b14 = 0; a15 = 0; b15 = 0; a16 = 0; b16 = 0;
        a17 = 0; b17 = 0; a18 = 0; b18 = 0;

        next_conv_ct = 0;
        next_ki = 0;
        next_kj = 0;
        for (i = 0; i < 6; i = i + 1)
        begin
            next_mult_list[i] = 0;
        end
    end
end

//conv_array
always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            next_conv_array[i][j] = conv_array[i][j];
        end
    end
    for (i = 1; i < 17; i = i + 1)//1-16
    begin
        if(conv_ct == i)
        begin
            next_conv_array[(i-1)/4][(i-1)%4] = sp9;
        end
    end
end

MAXPOOL m0(.mp1(cpa1), .mp2(cpb1), .mp3(cpa2), .mp4(cpb2), .index(idx), .pool_out(cp3));
//mp_array
always @(*)
begin
    for (i = 0; i < 2; i = i + 1)
    begin
        for (j = 0; j < 2; j = j + 1)
        begin
            next_mp_array[i][j] = mp_array[i][j];
        end
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        next_index_list[i] = index_list[i];
    end
    cpa1 = 0; cpb1 = 0; cpa2 = 0; cpb2 = 0;

    case(conv_ct)
        15: begin
            cpa1 = conv_array[0][0]; cpb1 = conv_array[0][1]; cpa2 = conv_array[1][0]; cpb2 = conv_array[1][1]; next_mp_array[0][0] = cp3; next_index_list[0] = idx;
        end
        16: begin
            cpa1 = conv_array[0][2]; cpb1 = conv_array[0][3]; cpa2 = conv_array[1][2]; cpb2 = conv_array[1][3]; next_mp_array[0][1] = cp3; next_index_list[1] = idx;
        end
        17: begin
            cpa1 = conv_array[2][0]; cpb1 = conv_array[2][1]; cpa2 = conv_array[3][0]; cpb2 = conv_array[3][1]; next_mp_array[1][0] = cp3; next_index_list[2] = idx;
        end
        18: begin
            cpa1 = conv_array[2][2]; cpb1 = conv_array[2][3]; cpa2 = conv_array[3][2]; cpb2 = conv_array[3][3]; next_mp_array[1][1] = cp3; next_index_list[3] = idx;
        end
    endcase
end

ACTFCT u_actfct(.clock(clock), .reset_n(reset_n), .act_valid(act_valid), .instruction(instruction), .data_in(data_in), .act_out_valid(act_out_valid), .data_out(data_out));
//act_valid
always @(*)
begin
    next_act_valid = act_valid;
    data_in = 0;

    if(conv_ct == 15)
    begin
        next_act_valid = 1;
    end

    if(conv_out_valid)
    begin
        next_act_valid = 0;
    end

    case(conv_ct)
        16: data_in = mp_array[0][0];
        17: data_in = mp_array[0][1];
        18: data_in = mp_array[1][0];
        19: data_in = mp_array[1][1];
    endcase
end
//conv out
always @(*)
begin
    next_out_ct = out_ct;
    next_conv_out_valid = 0;
    for (i = 0; i < 4; i = i + 1)
    begin
        next_conv_out[i] = conv_out[i];
        next_out_index[i] = out_index[i];
    end

    if(act_out_valid && out_ct < 4 && next_conv_ct != 0)
    begin
        next_conv_out[out_ct] = data_out;
        next_out_index[out_ct] = index_list[out_ct];
        next_out_ct = out_ct + 1;
    end
    if(out_ct == 3)
    begin
        next_conv_out_valid = 1;
    end
    if(out_ct == 4)
    begin
        next_conv_out_valid = 0;
        next_out_ct = 0;
        for (i = 0; i < 4; i = i + 1)
        begin
            next_conv_out[i] = 0;
            next_out_index[i] = 0;
        end
    end
end

always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            conv_out[i] <= 0;
            out_index[i] <= 0;
            index_list[i] <= 0;
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                conv_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 2; i = i + 1)
        begin
            for (j = 0; j < 2; j = j + 1)
            begin
                mp_array[i][j] <= 0;
            end
        end
        ki <= 0;
        kj <= 0;
        conv_ct <= 0;
        conv_out_valid <= 0;
        act_valid <= 0;
        out_ct <= 0;
    end
    else
    begin
        for (i = 0; i < 4; i = i + 1)
        begin
            conv_out[i] <= next_conv_out[i];
            out_index[i] <= next_out_index[i];
            index_list[i] <= next_index_list[i];
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= next_mult_list[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                conv_array[i][j] <= next_conv_array[i][j];
            end
        end
        for (i = 0; i < 2; i = i + 1)
        begin
            for (j = 0; j < 2; j = j + 1)
            begin
                mp_array[i][j] <= next_mp_array[i][j];
            end
        end
        ki <= next_ki;
        kj <= next_kj;
        conv_ct <= next_conv_ct;
        conv_out_valid <= next_conv_out_valid;
        act_valid <= next_act_valid;
        out_ct <= next_out_ct;
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

module DECONV4X4 (
    input clock,
    input reset_n,
    input deconv_valid,
    input [2:0] instruction,
    input [31:0] img_vec [0:15],
    input [31:0] img2_vec [0:15],
    input [31:0] kernel_vec [0:8],
    input [31:0] kernel2_vec [0:8],
    output reg deconv_out_valid,
    output reg [31:0] deconv_out [0:15]
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
integer i, j;
reg [31:0] next_deconv_out [0:15];
reg [31:0] conv_array [0:3][0:3], next_conv_array [0:3][0:3];
reg [31:0] img_array [0:3][0:3], img2_array [0:3][0:3];
reg [31:0] kernel_array [0:2][0:2], kernel2_array [0:2][0:2];
reg [31:0] image [0:5][0:5], image2 [0:5][0:5];
reg [2:0] ki, next_ki, kj, next_kj;
reg [31:0] a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18;
reg [31:0] b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18;
reg [31:0] mult_list [0:5], next_mult_list [0:5];
reg [6:0] conv_ct, next_conv_ct;
reg next_deconv_out_valid, act_valid, next_act_valid;
reg [31:0] cpa1, cpa2, cpb1, cpb2;
reg [31:0] data_in;
reg [4:0] out_ct, next_out_ct;

wire [31:0] sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9;
wire [7:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;
wire [31:0] cp3, data_out;
wire act_out_valid;

//vector to array
always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            img_array[i][j] = img_vec[i*4+j];
            img2_array[i][j] = img2_vec[i*4+j];
        end
    end
    for (i = 0; i < 3; i = i + 1)
    begin
        for (j = 0; j < 3; j = j + 1)
        begin
            kernel_array[i][j] = kernel_vec[i*3+j];
            kernel2_array[i][j] = kernel2_vec[i*3+j];
        end
    end
end
//padding
always @(*)
begin
    for (i = 0; i < 6; i = i + 1)
    begin
        for (j = 0; j < 6; j = j + 1)
        begin
            if(i >= 1 && i <= 4 && j >= 1 && j <= 4)
            begin
                image[i][j] = img_array[i-1][j-1];
                image2[i][j] = img2_array[i-1][j-1];
            end
            else
            begin
                if(instruction[2] == 0)//zero padding
                begin
                    image[i][j] = 0;
                    image2[i][j] = 0;
                end
            end
        end
    end
    if(instruction[2] == 1)//reflication padding
    begin
        image[0][0] = img_array[0][0];
        image[0][1:4] = img_array[0][0:3];
        image[0][5] = img_array[0][3];
        image[5][0] = img_array[3][0];
        image[5][1:4] = img_array[3][0:3];
        image[5][5] = img_array[3][3];
        for(i = 1; i < 5; i = i + 1)
        begin
            image[i][0] = img_array[i-1][0];
            image[i][5] = img_array[i-1][3];
        end
        image2[0][0] = img2_array[0][0];
        image2[0][1:4] = img2_array[0][0:3];
        image2[0][5] = img2_array[0][3];
        image2[5][0] = img2_array[3][0];
        image2[5][1:4] = img2_array[3][0:3];
        image2[5][5] = img2_array[3][3];
        for(i = 1; i < 5; i = i + 1)
        begin
            image2[i][0] = img2_array[i-1][0];
            image2[i][5] = img2_array[i-1][3];
        end
    end
end

DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp3(.a(a1), .b(b1), .c(a2), .d(b2), .e(a3), .f(b3), .rnd(3'd0), .z(sp1), .status(s1));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp4(.a(a4), .b(b4), .c(a5), .d(b5), .e(a6), .f(b6), .rnd(3'd0), .z(sp2), .status(s2));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp5(.a(a7), .b(b7), .c(a8), .d(b8), .e(a9), .f(b9), .rnd(3'd0), .z(sp3), .status(s3));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type)
    u_dp6(.a(a10), .b(b10), .c(a11), .d(b11), .e(a12), .f(b12), .rnd(3'd0), .z(sp4), .status(s4));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp7(.a(a13), .b(b13), .c(a14), .d(b14), .e(a15), .f(b15), .rnd(3'd0), .z(sp5), .status(s5));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp8(.a(a16), .b(b16), .c(a17), .d(b17), .e(a18), .f(b18), .rnd(3'd0), .z(sp6), .status(s6));

DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_7(.a(mult_list[0]), .b(mult_list[1]), .c(mult_list[2]), .rnd(3'd0), .z(sp7), .status(s7));
DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_8(.a(mult_list[3]), .b(mult_list[4]), .c(mult_list[5]), .rnd(3'd0), .z(sp8), .status(s8));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add(.a(sp7), .b(sp8), .rnd(3'd0), .z(sp9), .status(s9));

//conv
always @(*)
begin
    next_ki = ki;
    next_kj = kj;
    for (i = 0; i < 6; i = i + 1)
    begin
        next_mult_list[i] = mult_list[i];
    end

    next_mult_list[0] = sp1;
    next_mult_list[1] = sp2;
    next_mult_list[2] = sp3;
    next_mult_list[3] = sp4;
    next_mult_list[4] = sp5;
    next_mult_list[5] = sp6;
    next_conv_ct = conv_ct;

    if(deconv_valid)
    begin
        next_conv_ct = conv_ct + 1;
        next_kj = kj + 1;
        if(kj == 3)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 3)
            begin
                next_ki = 0;
            end
        end
        //image1
        a1 = image[ki][kj]; b1 = kernel_array[0][0];
        a2 = image[ki][kj+1]; b2 = kernel_array[0][1];
        a3 = image[ki][kj+2]; b3 = kernel_array[0][2];
        a4 = image[ki+1][kj]; b4 = kernel_array[1][0];
        a5 = image[ki+1][kj+1]; b5 = kernel_array[1][1];
        a6 = image[ki+1][kj+2]; b6 = kernel_array[1][2];
        a7 = image[ki+2][kj]; b7 = kernel_array[2][0];
        a8 = image[ki+2][kj+1]; b8 = kernel_array[2][1];
        a9 = image[ki+2][kj+2]; b9 = kernel_array[2][2];
        //image2
        a10 = image2[ki][kj]; b10 = kernel2_array[0][0];
        a11 = image2[ki][kj+1]; b11 = kernel2_array[0][1];
        a12 = image2[ki][kj+2]; b12 = kernel2_array[0][2];
        a13 = image2[ki+1][kj]; b13 = kernel2_array[1][0];
        a14 = image2[ki+1][kj+1]; b14 = kernel2_array[1][1];
        a15 = image2[ki+1][kj+2]; b15 = kernel2_array[1][2];
        a16 = image2[ki+2][kj]; b16 = kernel2_array[2][0];
        a17 = image2[ki+2][kj+1]; b17 = kernel2_array[2][1];
        a18 = image2[ki+2][kj+2]; b18 = kernel2_array[2][2];
    end
    else
    begin
        a1 = 0; b1 = 0; a2 = 0; b2 = 0; a3 = 0; b3 = 0; a4 = 0; b4 = 0;
        a5 = 0; b5 = 0; a6 = 0; b6 = 0; a7 = 0; b7 = 0; a8 = 0; b8 = 0;
        a9 = 0; b9 = 0; a10 = 0; b10 = 0; a11 = 0; b11 = 0; a12 = 0; b12 = 0;
        a13 = 0; b13 = 0; a14 = 0; b14 = 0; a15 = 0; b15 = 0; a16 = 0; b16 = 0;
        a17 = 0; b17 = 0; a18 = 0; b18 = 0;

        next_conv_ct = 0;
        next_ki = 0;
        next_kj = 0;
        for (i = 0; i < 6; i = i + 1)
        begin
            next_mult_list[i] = 0;
        end
    end
end
//conv_array
always @(*)
begin
    for (i = 0; i < 4; i = i + 1)
    begin
        for (j = 0; j < 4; j = j + 1)
        begin
            next_conv_array[i][j] = conv_array[i][j];
        end
    end
    for (i = 1; i < 17; i = i + 1)
    begin
        if(conv_ct == i)
        begin
            next_conv_array[(i-1)/4][(i-1)%4] = sp9;
        end
    end
end
ACTFCT u_actfct(.clock(clock), .reset_n(reset_n), .act_valid(act_valid), .instruction(instruction), .data_in(data_in), .act_out_valid(act_out_valid), .data_out(data_out));
//act_valid
always @(*)
begin
    next_act_valid = act_valid;
    data_in = 0;

    if(conv_ct == 15)
    begin
        next_act_valid = 1;
    end

    if(deconv_out_valid)
    begin
        next_act_valid = 0;
    end

    case(conv_ct)
        16: data_in = conv_array[0][0];
        17: data_in = conv_array[0][1];
        18: data_in = conv_array[0][2];
        19: data_in = conv_array[0][3];
        20: data_in = conv_array[1][0];
        21: data_in = conv_array[1][1];
        22: data_in = conv_array[1][2];
        23: data_in = conv_array[1][3];
        24: data_in = conv_array[2][0];
        25: data_in = conv_array[2][1];
        26: data_in = conv_array[2][2];
        27: data_in = conv_array[2][3];
        28: data_in = conv_array[3][0];
        29: data_in = conv_array[3][1];
        30: data_in = conv_array[3][2];
        31: data_in = conv_array[3][3];
    endcase
end
//conv out
always @(*)
begin
    next_out_ct = out_ct;
    next_deconv_out_valid = 0;
    for (i = 0; i < 16; i = i + 1)
    begin
        next_deconv_out[i] = deconv_out[i];
    end

    if(act_out_valid && out_ct < 16 && next_conv_ct != 0)
    begin
        next_deconv_out[out_ct] = data_out;
        next_out_ct = out_ct + 1;
    end
    if(out_ct == 15)
    begin
        next_deconv_out_valid = 1;
    end
    if(out_ct == 16)
    begin
        next_deconv_out_valid = 0;
        next_out_ct = 0;
        for (i = 0; i < 16; i = i + 1)
        begin
            next_deconv_out[i] = 0;
        end
    end
end

always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            deconv_out[i] <= 0;
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= 0;
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                conv_array[i][j] <= 0;
            end
        end
        ki <= 0;
        kj <= 0;
        conv_ct <= 0;
        deconv_out_valid <= 0;
        act_valid <= 0;
        out_ct <= 0;
    end
    else
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            deconv_out[i] <= next_deconv_out[i];
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= next_mult_list[i];
        end
        for (i = 0; i < 4; i = i + 1)
        begin
            for (j = 0; j < 4; j = j + 1)
            begin
                conv_array[i][j] <= next_conv_array[i][j];
            end
        end
        ki <= next_ki;
        kj <= next_kj;
        conv_ct <= next_conv_ct;
        deconv_out_valid <= next_deconv_out_valid;
        act_valid <= next_act_valid;
        out_ct <= next_out_ct;
    end
end

endmodule

module DECONV8X8 (
    input clock,
    input reset_n,
    input deconv_valid,
    input [2:0] instruction,
    input [31:0] img_vec [0:63],
    input [31:0] img2_vec [0:63],
    input [31:0] kernel_vec [0:8],
    input [31:0] kernel2_vec [0:8],
    output reg deconv_out_valid,
    output reg [31:0] deconv_out [0:63]
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
integer i, j;
reg [31:0] next_deconv_out [0:63];
reg [31:0] conv_array [0:7][0:7], next_conv_array [0:7][0:7];
reg [31:0] img_array [0:7][0:7], img2_array [0:7][0:7];
reg [31:0] kernel_array [0:2][0:2], kernel2_array [0:2][0:2];
reg [31:0] image [0:9][0:9], image2 [0:9][0:9];
reg [2:0] ki, next_ki, kj, next_kj;
reg [31:0] a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18;
reg [31:0] b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18;
reg [31:0] mult_list [0:5], next_mult_list [0:5];
reg [6:0] conv_ct, next_conv_ct;
reg next_deconv_out_valid, act_valid, next_act_valid;
reg [31:0] cpa1, cpa2, cpb1, cpb2;
reg [31:0] data_in;
reg [6:0] out_ct, next_out_ct;

wire [7:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27;
wire [31:0] sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9;
wire [31:0] cp1, cp2, cp3, cp4;
wire [31:0] data_out;
wire act_out_valid;

//vector to array
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            img_array[i][j] = img_vec[i*8+j];
            img2_array[i][j] = img2_vec[i*8+j];
        end
    end
    for (i = 0; i < 3; i = i + 1)
    begin
        for (j = 0; j < 3; j = j + 1)
        begin
            kernel_array[i][j] = kernel_vec[i*3+j];
            kernel2_array[i][j] = kernel2_vec[i*3+j];
        end
    end
end
//padding
always @(*)
begin
    for (i = 0; i < 10; i = i + 1)
    begin
        for (j = 0; j < 10; j = j + 1)
        begin
            if(i >= 1 && i <= 8 && j >= 1 && j <= 8)
            begin
                image[i][j] = img_array[i-1][j-1];
                image2[i][j] = img2_array[i-1][j-1];
            end
            else
            begin
                if(instruction[2] == 0)//zero padding
                begin
                    image[i][j] = 0;
                    image2[i][j] = 0;
                end
            end
        end
    end
    if(instruction[2] == 1)//reflication padding
    begin
        image[0][0] = img_array[0][0];
        image[0][1:8] = img_array[0][0:7];
        image[0][9] = img_array[0][7];
        image[9][0] = img_array[7][0];
        image[9][1:8] = img_array[7][0:7];
        image[9][9] = img_array[7][7];
        for(i = 1; i < 9; i = i + 1)
        begin
            image[i][0] = img_array[i-1][0];
            image[i][9] = img_array[i-1][7];
        end
        image2[0][0] = img2_array[0][0];
        image2[0][1:8] = img2_array[0][0:7];
        image2[0][9] = img2_array[0][7];
        image2[9][0] = img2_array[7][0];
        image2[9][1:8] = img2_array[7][0:7];
        image2[9][9] = img2_array[7][7];
        for(i = 1; i < 9; i = i + 1)
        begin
            image2[i][0] = img2_array[i-1][0];
            image2[i][9] = img2_array[i-1][7];
        end
    end
end

DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp3(.a(a1), .b(b1), .c(a2), .d(b2), .e(a3), .f(b3), .rnd(3'd0), .z(sp1), .status(s1));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp4(.a(a4), .b(b4), .c(a5), .d(b5), .e(a6), .f(b6), .rnd(3'd0), .z(sp2), .status(s2));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp5(.a(a7), .b(b7), .c(a8), .d(b8), .e(a9), .f(b9), .rnd(3'd0), .z(sp3), .status(s3));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type)
    u_dp6(.a(a10), .b(b10), .c(a11), .d(b11), .e(a12), .f(b12), .rnd(3'd0), .z(sp4), .status(s4));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp7(.a(a13), .b(b13), .c(a14), .d(b14), .e(a15), .f(b15), .rnd(3'd0), .z(sp5), .status(s5));
DW_fp_dp3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_dp8(.a(a16), .b(b16), .c(a17), .d(b17), .e(a18), .f(b18), .rnd(3'd0), .z(sp6), .status(s6));

DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_7(.a(mult_list[0]), .b(mult_list[1]), .c(mult_list[2]), .rnd(3'd0), .z(sp7), .status(s7));
DW_fp_sum3 #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type) 
    u_sum3_8(.a(mult_list[3]), .b(mult_list[4]), .c(mult_list[5]), .rnd(3'd0), .z(sp8), .status(s8));
DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) u_add(.a(sp7), .b(sp8), .rnd(3'd0), .z(sp9), .status(s9));

//conv
always @(*)
begin
    next_ki = ki;
    next_kj = kj;
    for (i = 0; i < 6; i = i + 1)
    begin
        next_mult_list[i] = mult_list[i];
    end

    next_mult_list[0] = sp1;
    next_mult_list[1] = sp2;
    next_mult_list[2] = sp3;
    next_mult_list[3] = sp4;
    next_mult_list[4] = sp5;
    next_mult_list[5] = sp6;
    next_conv_ct = conv_ct;

    if(deconv_valid)
    begin
        next_conv_ct = conv_ct + 1;
        next_kj = kj + 1;
        if(kj == 7)
        begin
            next_kj = 0;
            next_ki = ki + 1;
            if(ki == 7)
            begin
                next_ki = 0;
            end
        end
        //image1
        a1 = image[ki][kj]; b1 = kernel_array[0][0];
        a2 = image[ki][kj+1]; b2 = kernel_array[0][1];
        a3 = image[ki][kj+2]; b3 = kernel_array[0][2];
        a4 = image[ki+1][kj]; b4 = kernel_array[1][0];
        a5 = image[ki+1][kj+1]; b5 = kernel_array[1][1];
        a6 = image[ki+1][kj+2]; b6 = kernel_array[1][2];
        a7 = image[ki+2][kj]; b7 = kernel_array[2][0];
        a8 = image[ki+2][kj+1]; b8 = kernel_array[2][1];
        a9 = image[ki+2][kj+2]; b9 = kernel_array[2][2];
        //image2
        a10 = image2[ki][kj]; b10 = kernel2_array[0][0];
        a11 = image2[ki][kj+1]; b11 = kernel2_array[0][1];
        a12 = image2[ki][kj+2]; b12 = kernel2_array[0][2];
        a13 = image2[ki+1][kj]; b13 = kernel2_array[1][0];
        a14 = image2[ki+1][kj+1]; b14 = kernel2_array[1][1];
        a15 = image2[ki+1][kj+2]; b15 = kernel2_array[1][2];
        a16 = image2[ki+2][kj]; b16 = kernel2_array[2][0];
        a17 = image2[ki+2][kj+1]; b17 = kernel2_array[2][1];
        a18 = image2[ki+2][kj+2]; b18 = kernel2_array[2][2];
    end
    else
    begin
        a1 = 0; b1 = 0; a2 = 0; b2 = 0; a3 = 0; b3 = 0; a4 = 0; b4 = 0;
        a5 = 0; b5 = 0; a6 = 0; b6 = 0; a7 = 0; b7 = 0; a8 = 0; b8 = 0;
        a9 = 0; b9 = 0; a10 = 0; b10 = 0; a11 = 0; b11 = 0; a12 = 0; b12 = 0;
        a13 = 0; b13 = 0; a14 = 0; b14 = 0; a15 = 0; b15 = 0; a16 = 0; b16 = 0;
        a17 = 0; b17 = 0; a18 = 0; b18 = 0;

        next_conv_ct = 0;
        next_ki = 0;
        next_kj = 0;
        for (i = 0; i < 6; i = i + 1)
        begin
            next_mult_list[i] = 0;
        end
    end
end
//conv_array
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            next_conv_array[i][j] = conv_array[i][j];
        end
    end
    for (i = 1; i < 65; i = i + 1)//1-64
    begin
        if(conv_ct == i)
        begin
            next_conv_array[(i-1)/8][(i-1)%8] = sp9;
        end
    end
end

ACTFCT u_actfct(.clock(clock), .reset_n(reset_n), .act_valid(act_valid), .instruction(instruction), .data_in(data_in), .act_out_valid(act_out_valid), .data_out(data_out));

//act_valid
always @(*)
begin
    next_act_valid = act_valid;
    data_in = 0;

    if(conv_ct == 51)
    begin
        next_act_valid = 1;
    end
    if(deconv_out_valid)
    begin
        next_act_valid = 0;
    end

    /*case(conv_ct)
        51: data_in = conv_array[0][0];
        52: data_in = conv_array[0][1];
        53: data_in = conv_array[0][2];
        54: data_in = conv_array[0][3];
        55: data_in = conv_array[0][4];
        56: data_in = conv_array[0][5];
        57: data_in = conv_array[0][6];
        58: data_in = conv_array[0][7];
        59: data_in = conv_array[1][0];
        60: data_in = conv_array[1][1];
        61: data_in = conv_array[1][2];
        62: data_in = conv_array[1][3];
        63: data_in = conv_array[2][0];
        64: data_in = conv_array[2][1];
        65: data_in = conv_array[3][2];
        66: data_in = conv_array[3][3];
    endcase*/

    for (i = 0; i < 8; i = i + 1)
    begin
        for (j = 0; j < 8; j = j + 1)
        begin
            if(conv_ct == (i*8 + j + 52))//52-115
            begin
                data_in = conv_array[i][j];
            end
        end
    end
end
//conv out
always @(*)
begin
    next_out_ct = out_ct;
    next_deconv_out_valid = 0;
    for (i = 0; i < 64; i = i + 1)
    begin
        next_deconv_out[i] = deconv_out[i];
    end

    if(act_out_valid && out_ct < 64 && next_conv_ct != 0)
    begin
        next_deconv_out[out_ct] = data_out;
        next_out_ct = out_ct + 1;
    end
    if(out_ct == 63)
    begin
        next_deconv_out_valid = 1;
    end
    if(out_ct == 64)
    begin
        next_deconv_out_valid = 0;
        next_out_ct = 0;
        for (i = 0; i < 64; i = i + 1)
        begin
            next_deconv_out[i] = 0;
        end
    end
end

always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            deconv_out[i] <= 0;
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                conv_array[i][j] <= 0;
            end
        end
        ki <= 0;
        kj <= 0;
        conv_ct <= 0;
        deconv_out_valid <= 0;
        act_valid <= 0;
        out_ct <= 0;
        
    end
    else
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            deconv_out[i] <= next_deconv_out[i];
        end
        for (i = 0; i < 6; i = i + 1)
        begin
            mult_list[i] <= next_mult_list[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            for (j = 0; j < 8; j = j + 1)
            begin
                conv_array[i][j] <= next_conv_array[i][j];
            end
        end
        ki <= next_ki;
        kj <= next_kj;
        conv_ct <= next_conv_ct;
        deconv_out_valid <= next_deconv_out_valid;
        act_valid <= next_act_valid;
        out_ct <= next_out_ct;
    end
end


endmodule

