module ISP(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in,
    param_valid,
    param_gain,

    //Output Port
    out_valid,
    r_out,
    g_out,
    b_out
    );

//==============================
//   INPUT/OUTPUT DECLARATION
//==============================
input clk;
input rst_n;
input in_valid;
input [11:0] in;
input param_valid;
input [11:0] param_gain;

output reg out_valid;
output reg [11:0] r_out;
output reg [11:0] g_out;
output reg [11:0] b_out;


//==============================
//   Declaration 
//==============================
reg [11:0] rp_array [0:5][0:5];
reg [11:0] next_rp_array [0:5][0:5];
reg [11:0] grp_array [0:5][0:5];
reg [11:0] next_grp_array [0:5][0:5];
reg [11:0] gbp_array [0:5][0:5];
reg [11:0] next_gbp_array [0:5][0:5];
reg [11:0] bp_array [0:5][0:5];
reg [11:0] next_bp_array [0:5][0:5];
reg [7:0] count, next_count;
reg [3:0] ctxi, next_ctxi, ctyi, next_ctyi;
reg [3:0] x2, y2, x3, y3, meshx, meshy;
reg [11:0] img_array [0:15][0:15];
reg [11:0] next_img_array [0:15][0:15];
reg start_valid, next_start_valid, start_valid1, next_start_valid1, start_valid2, next_start_valid2, start_valid3, next_start_valid3, start_valid4, next_start_valid4;
reg invalid_buf, next_invalid_buf;
reg [11:0] p2, g00, g01, g10, g11, big_g, in_data, next_in_data;
reg [6:0] b_value;
reg [1:0] rx, ry;
reg [13:0] multa, next_multa, multb, next_multb, r, next_r, g, next_g, b, next_b, tmp_r, tmp_g, tmp_b;
reg [11:0] iarry [0:4][0:4];
reg [11:0] darray [0:2][0:2];
reg [12:0] score_tmp1, score_tmp2, median_tmp1, median_tmp2, median;
reg [1:0] color;
reg next_out_valid;
reg [11:0] next_r_out, next_g_out, next_b_out, temp_r, temp_g, temp_b;
reg [8:0] ct1, next_ct1, ct2, next_ct2, ct3, next_ct3, ct4, next_ct4;
reg [11:0] tmp_queue [0:47];
reg [11:0] next_tmp_queue [0:47];

wire [12:0] median_h, median_v, median_d1, median_d2, score_h, score_v, score_d1, score_d2;
integer i,j;
//==============================
//   Design
//==============================
// param input
always @(*)
begin
    for (i = 0; i < 6; i = i + 1) begin
        for (j = 0; j < 6; j = j + 1) begin
            next_rp_array[i][j] = rp_array[i][j];
            next_grp_array[i][j] = grp_array[i][j];
            next_gbp_array[i][j] = gbp_array[i][j];
            next_bp_array[i][j] = bp_array[i][j];
        end
    end

    if(param_valid)
    begin
        if(count < 36) //R 0-35
        begin
            for (i = 0; i < 5; i = i + 1) begin
                next_rp_array[i][0:4] = rp_array[i][1:5];
                next_rp_array[i][5] = rp_array[i+1][0];
            end
            next_rp_array[5][0:4] = rp_array[5][1:5];
            next_rp_array[5][5] = param_gain;
        end
        if((count >= 36) && (count < 72)) //Gr 36-71
        begin
            for (i = 0; i < 5; i = i + 1) begin
                next_grp_array[i][0:4] = grp_array[i][1:5];
                next_grp_array[i][5] = grp_array[i+1][0];
            end
            next_grp_array[5][0:4] = grp_array[5][1:5];
            next_grp_array[5][5] = param_gain;
        end
        if((count >= 72) && (count < 108)) //Gb 72-107
        begin
            for (i = 0; i < 5; i = i + 1) begin
                next_gbp_array[i][0:4] = gbp_array[i][1:5];
                next_gbp_array[i][5] = gbp_array[i+1][0];
            end
            next_gbp_array[5][0:4] = gbp_array[5][1:5];
            next_gbp_array[5][5] = param_gain;
        end
        if((count >= 108) && (count < 144)) //B 108-143
        begin
            for (i = 0; i < 5; i = i + 1) begin
                next_bp_array[i][0:4] = bp_array[i][1:5];
                next_bp_array[i][5] = bp_array[i+1][0];
            end
            next_bp_array[5][0:4] = bp_array[5][1:5];
            next_bp_array[5][5] = param_gain;
        end
    end
end
//count
always @(*)
begin
    next_count = count;
    if(param_valid)
    begin
        if(count == 143)
            next_count = 0;
        else
            next_count = count + 1;
    end
end
//ctxi, ctyi
always @(*)
begin
    next_ctxi = ctxi;
    next_ctyi = ctyi;

    if(invalid_buf)
    begin
        if(ctxi == 15)
        begin
            next_ctxi = 0;
            next_ctyi = ctyi + 1;
        end
        else
        begin
            next_ctxi = ctxi + 1;
        end
    end
    else
    begin
        next_ctxi = 0;
        next_ctyi = 0;
    end
end
//input and img_array
always @(*)
begin
    next_in_data = 0;
    next_invalid_buf = 0;
    next_start_valid = 0;

    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            next_img_array[i][j] = img_array[i][j];
        end
    end

    if(in_valid)
    begin
        next_in_data = in;
        next_invalid_buf = 1;
        next_start_valid = 1;
    end

    if(start_valid1) //p*g
    begin
        next_img_array[ct1 >> 4][ct1 % 16] = p2;   
    end
    
    if(start_valid2 && ct2 >= 48) //median filter
    begin
        next_img_array[(ct2 - 48) >> 4][(ct2 - 48) % 16] = tmp_queue[0];
    end
end
//pipeline 0
always @(*)
begin
    next_start_valid1 = start_valid1;
    next_multa = multa;
    next_multb = multb;

    if((ctyi % 2 == 0) && (ctxi % 2 == 0))//R
        b_value = 64;
    else if((ctyi % 2 == 0) && (ctxi % 2 == 1))//Gr
        b_value = 48;
    else if((ctyi % 2 == 1) && (ctxi % 2 == 0))//Gb
        b_value = 52;
    else//B
        b_value = 72;
 
        
    case(ctxi)
        0,1,2: meshx = 0;
        3,4,5: meshx = 1;
        6,7,8: meshx = 2;
        9,10,11: meshx = 3;
        12,13,14,15: meshx = 4;
        default: meshx = 0;
    endcase

    case(ctyi)
        0,1,2: meshy = 0;
        3,4,5: meshy = 1;
        6,7,8: meshy = 2;
        9,10,11: meshy = 3;
        12,13,14,15: meshy = 4;
        default: meshy = 0;
    endcase

    if((ctyi % 2 == 0) && (ctxi % 2 == 0))//R
    begin
        g00 = rp_array[meshy][meshx];
        g01 = rp_array[meshy][meshx + 1];
        g10 = rp_array[meshy + 1][meshx];
        g11 = rp_array[meshy + 1][meshx + 1];
    end
    else if((ctyi % 2 == 0) && (ctxi % 2 == 1))//Gr
    begin
        g00 = grp_array[meshy][meshx];
        g01 = grp_array[meshy][meshx + 1];
        g10 = grp_array[meshy + 1][meshx];
        g11 = grp_array[meshy + 1][meshx + 1];
    end
    else if((ctyi % 2 == 1) && (ctxi % 2 == 0))//Gb
    begin
        g00 = gbp_array[meshy][meshx];
        g01 = gbp_array[meshy][meshx + 1];
        g10 = gbp_array[meshy + 1][meshx];
        g11 = gbp_array[meshy + 1][meshx + 1];
    end
    else//B
    begin
        g00 = bp_array[meshy][meshx];
        g01 = bp_array[meshy][meshx + 1];
        g10 = bp_array[meshy + 1][meshx];
        g11 = bp_array[meshy + 1][meshx + 1];
    end

    rx = ((ctxi - 3 * meshx)) < 2 ? ctxi - 3 * meshx : 2;
    ry = ((ctyi - 3 * meshy)) < 2 ? ctyi - 3 * meshy : 2;

    if(rx == 0 && ry == 0)
        big_g = (256 * 256 * g00 + 32768) >> 16;
    else if(rx == 0 && ry == 1)
        big_g = (256 * 171 * g00 + 256 * 85 * g10 + 32768) >> 16;
    else if(rx == 0 && ry == 2)
        big_g = (256 * 85 * g00 + 256 * 171 * g10 + 32768) >> 16;
    else if(rx == 1 && ry == 0)
        big_g = (171 * 256 * g00 + 85 * 256 * g01 + 32768) >> 16;
    else if(rx == 1 && ry == 1)
        big_g = (171 * 171 * g00 + 171 * 85 * g10 + 85 * 171 * g01 + 85 * 85 * g11 + 32768) >> 16;
    else if(rx == 1 && ry == 2)
        big_g = (171 * 85 * g00 + 171 * 171 * g10 + 85 * 85 * g01 + 85 * 171 * g11 + 32768) >> 16;
    else if(rx == 2 && ry == 0)
        big_g = (85 * 256 * g00 + 171 * 256 * g01 + 32768) >> 16;
    else if(rx == 2 && ry == 1)
        big_g = (85 * 171 * g00 + 85 * 85 * g10 + 171 * 171 * g01 + 171 * 85 * g11 + 32768) >> 16;
    else if(rx == 2 && ry == 2)
        big_g = (85 * 85 * g00 + 85 * 171 * g10 + 171 * 85 * g01 + 171 * 171 * g11 + 32768) >> 16;
    else
        big_g = 0;

    if(start_valid)
    begin
        next_start_valid1 = 1;
        next_multa = big_g;
        //next_multb = ((in_data - b_value) > 0) ? (in_data - b_value) : 0;
        if(in_data > b_value)
        begin
            next_multb = in_data - b_value;
        end
        else
        begin
            next_multb = 0;
        end
    end

    //close start_valid1
    if(ct1 == 255)
        next_start_valid1 = 0;


end
//pipeline 1
always @(*)
begin
    next_start_valid2 = start_valid2;
    next_ct1 = 0;

    if(start_valid1)
        next_ct1 = ct1 + 1;

    if(((multa * multb + 512) >> 10) < 4095)
        p2 = (multa * multb + 512) >> 10;
    else
        p2 = 4095;

    if(start_valid1 && (ct1 >= 48))
    begin
        next_start_valid2 = 1;
    
    end

    //close start_valid2
    if(ct2 == 303)
        next_start_valid2 = 0;
end
//call score submodule
SCORE s1 (.a0(iarry[2][0]), .a1(iarry[2][1]), .a2(iarry[2][3]), .a3(iarry[2][4]), .score(score_h), .median(median_h));
SCORE s2 (.a0(iarry[0][2]), .a1(iarry[1][2]), .a2(iarry[3][2]), .a3(iarry[4][2]), .score(score_v), .median(median_v));
SCORE s3 (.a0(iarry[0][0]), .a1(iarry[1][1]), .a2(iarry[3][3]), .a3(iarry[4][4]), .score(score_d1), .median(median_d1));
SCORE s4 (.a0(iarry[0][4]), .a1(iarry[1][3]), .a2(iarry[3][1]), .a3(iarry[4][0]), .score(score_d2), .median(median_d2));

//pipeline 2
always @(*)
begin
    next_start_valid3 = start_valid3;
    next_ct2 = 0;

    for (i = 0; i < 48; i = i + 1)
    begin
        next_tmp_queue[i] = tmp_queue[i];
    end

    if(start_valid2)
        next_ct2 = ct2 + 1;

    x2 = ct2 % 16;
    y2 = ct2 >> 4;

    //generate 5x5 iarry
    iarry[0][0] = (x2 < 2) ? ((y2 < 2) ? img_array[2 - y2][2 - x2] : img_array[y2 - 2][2 - x2]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 - 2] : img_array[y2 - 2][x2 - 2]);
    iarry[0][1] = (x2 < 1) ? ((y2 < 2) ? img_array[2 - y2][1 - x2] : img_array[y2 - 2][1 - x2]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 - 1] : img_array[y2 - 2][x2 - 1]);
    iarry[0][2] = (y2 < 2) ? img_array[2 - y2][x2] : img_array[y2 - 2][x2];
    iarry[0][3] = (x2 > 14) ? ((y2 < 2) ? img_array[2 - y2][30 - x2 - 1] : img_array[y2 - 2][30 - x2 - 1]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 + 1] : img_array[y2 - 2][x2 + 1]);
    iarry[0][4] = (x2 > 13) ? ((y2 < 2) ? img_array[2 - y2][30 - x2 - 2] : img_array[y2 - 2][30 - x2 - 2]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 + 2] : img_array[y2 - 2][x2 + 2]);
    iarry[1][0] = (x2 < 2) ? ((y2 < 1) ? img_array[1 - y2][2 - x2] : img_array[y2 - 1][2 - x2]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 - 2] : img_array[y2 - 1][x2 - 2]);
    iarry[1][1] = (x2 < 1) ? ((y2 < 1) ? img_array[1 - y2][1 - x2] : img_array[y2 - 1][1 - x2]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 - 1] : img_array[y2 - 1][x2 - 1]);
    iarry[1][2] = (y2 < 1) ? img_array[1 - y2][x2] : img_array[y2 - 1][x2];
    iarry[1][3] = (x2 > 14) ? ((y2 < 1) ? img_array[1 - y2][30 - x2 - 1] : img_array[y2 - 1][30 - x2 - 1]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 + 1] : img_array[y2 - 1][x2 + 1]);
    iarry[1][4] = (x2 > 13) ? ((y2 < 1) ? img_array[1 - y2][30 - x2 - 2] : img_array[y2 - 1][30 - x2 - 2]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 + 2] : img_array[y2 - 1][x2 + 2]);
    iarry[2][0] = (x2 < 2) ? img_array[y2][2 - x2] : img_array[y2][x2 - 2];
    iarry[2][1] = (x2 < 1) ? img_array[y2][1 - x2] : img_array[y2][x2 - 1];
    iarry[2][2] = img_array[y2][x2];
    iarry[2][3] = (x2 > 14) ? img_array[y2][30 - x2 - 1] : img_array[y2][x2 + 1];
    iarry[2][4] = (x2 > 13) ? img_array[y2][30 - x2 - 2] : img_array[y2][x2 + 2];
    iarry[3][0] = (x2 < 2) ? ((y2 > 14) ? img_array[30 - y2 - 1][2 - x2] : img_array[y2 + 1][2 - x2]) :
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 - 2] : img_array[y2 + 1][x2 - 2]);
    iarry[3][1] = (x2 < 1) ? ((y2 > 14) ? img_array[30 - y2 - 1][1 - x2] : img_array[y2 + 1][1 - x2]) : 
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 - 1] : img_array[y2 + 1][x2 - 1]);
    iarry[3][2] = (y2 > 14) ? img_array[30 - y2 - 1][x2] : img_array[y2 + 1][x2];
    iarry[3][3] = (x2 > 14) ? ((y2 > 14) ? img_array[30 - y2 - 1][30 - x2 - 1] : img_array[y2 + 1][30 - x2 - 1]) : 
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 + 1] : img_array[y2 + 1][x2 + 1]);
    iarry[3][4] = (x2 > 13) ? ((y2 > 14) ? img_array[30 - y2 - 1][30 - x2 - 2] : img_array[y2 + 1][30 - x2 - 2]) : 
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 + 2] : img_array[y2 + 1][x2 + 2]);
    iarry[4][0] = (x2 < 2) ? ((y2 > 13) ? img_array[30 - y2 - 2][2 - x2] : img_array[y2 + 2][2 - x2]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 - 2] : img_array[y2 + 2][x2 - 2]);
    iarry[4][1] = (x2 < 1) ? ((y2 > 13) ? img_array[30 - y2 - 2][1 - x2] : img_array[y2 + 2][1 - x2]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 - 1] : img_array[y2 + 2][x2 - 1]);
    iarry[4][2] = (y2 > 13) ? img_array[30 - y2 - 2][x2] : img_array[y2 + 2][x2];
    iarry[4][3] = (x2 > 14) ? ((y2 > 13) ? img_array[30 - y2 - 2][30 - x2 - 1] : img_array[y2 + 2][30 - x2 - 1]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 + 1] : img_array[y2 + 2][x2 + 1]);
    iarry[4][4] = (x2 > 13) ? ((y2 > 13) ? img_array[30 - y2 - 2][30 - x2 - 2] : img_array[y2 + 2][30 - x2 - 2]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 + 2] : img_array[y2 + 2][x2 + 2]);

    if(score_h > score_v)
    begin
        score_tmp1 = score_v;
        median_tmp1 = median_v;
    end
    else
    begin
        score_tmp1 = score_h;
        median_tmp1 = median_h;
    end

    if(score_d1 > score_d2)
    begin
        score_tmp2 = score_d2;
        median_tmp2 = median_d2;
    end
    else
    begin
        score_tmp2 = score_d1;
        median_tmp2 = median_d1;
    end

    if(score_tmp1 > score_tmp2)
        median = median_tmp2;
    else
        median = median_tmp1;
    

    if(start_valid2 && ct2 < 256)
    begin
        if(iarry[2][2] > median)
        begin
            if(iarry[2][2] - median > 320)
                next_tmp_queue[47] = median;
            else
                next_tmp_queue[47] = iarry[2][2];
        end
        else
        begin
            if(median - iarry[2][2] > 320)
                next_tmp_queue[47] = median;
            else
                next_tmp_queue[47] = iarry[2][2];
        end
    end
    else
    begin
        next_tmp_queue[47] = 0;
    end
    next_tmp_queue[0:46] = tmp_queue[1:47];

    if(ctxi == 12 && ctyi == 15)
    begin
        next_start_valid3 = 1;
    end

    if(ct3 == 255)
        next_start_valid3 = 0;
    
end
//pipeline 3
always @(*)
begin
    next_g = g;
    next_b = b;
    next_r = r;
    next_start_valid4 = start_valid4;
    next_ct3 = 0;

    if(start_valid3)
        next_ct3 = ct3 + 1;

    x3 = ct3 % 16;
    y3 = ct3 >> 4;

    darray[0][0] = (x3 < 1) ? ((y3 < 1) ? img_array[1 - y3][1 - x3] : img_array[y3 - 1][1 - x3]) : 
                    ((y3 < 1) ? img_array[1 - y3][x3 - 1] : img_array[y3 - 1][x3 - 1]);
    darray[0][1] = (y3 < 1) ? img_array[1 - y3][x3] : img_array[y3 - 1][x3];
    darray[0][2] = (x3 > 14) ? ((y3 < 1) ? img_array[1 - y3][30 - x3 - 1] : img_array[y3 - 1][30 - x3 - 1]) : 
                    ((y3 < 1) ? img_array[1 - y3][x3 + 1] : img_array[y3 - 1][x3 + 1]);
    darray[1][0] = (x3 < 1) ? img_array[y3][1 - x3] : img_array[y3][x3 - 1];
    darray[1][1] = img_array[y3][x3];
    darray[1][2] = (x3 > 14) ? img_array[y3][30 - x3 - 1] : img_array[y3][x3 + 1];
    darray[2][0] = (x3 < 1) ? ((y3 > 14) ? img_array[30 - y3 - 1][1 - x3] : img_array[y3 + 1][1 - x3]) : 
                    ((y3 > 14) ? img_array[30 - y3 - 1][x3 - 1] : img_array[y3 + 1][x3 - 1]);
    darray[2][1] = (y3 > 14) ? img_array[30 - y3 - 1][x3] : img_array[y3 + 1][x3];
    darray[2][2] = (x3 > 14) ? ((y3 > 14) ? img_array[30 - y3 - 1][30 - x3 - 1] : img_array[y3 + 1][30 - x3 - 1]) : 
                    ((y3 > 14) ? img_array[30 - y3 - 1][x3 + 1] : img_array[y3 + 1][x3 + 1]);

    if((y3 % 2 == 0) && (x3 % 2 == 0))//R
        color = 0;
    else if((y3 % 2 == 0) && (x3 % 2 == 1))//Gr
        color = 1;
    else if((y3 % 2 == 1) && (x3 % 2 == 0))//Gb
        color = 2;
    else//B
        color = 3;

    if(start_valid3)
    begin
        case (color)
            0: //r
            begin
                next_r = img_array[y3][x3];
                next_g = (darray[1][0] + darray[0][1] + darray[1][2] + darray[2][1]) >> 2;
                next_b = (darray[0][0] + darray[0][2] + darray[2][0] + darray[2][2]) >> 2;
            end
            1: //gr
            begin
                next_r = (darray[1][0] + darray[1][2]) >> 1;
                next_g = img_array[y3][x3];
                next_b = (darray[0][1] + darray[2][1]) >> 1;
            end
            2: //gb
            begin
                next_r = (darray[0][1] + darray[2][1]) >> 1;
                next_g = img_array[y3][x3];
                next_b = (darray[1][0] + darray[1][2]) >> 1;
            end
            3: //b
            begin
                next_r = (darray[0][0] + darray[0][2] + darray[2][0] + darray[2][2]) >> 2;
                next_g = (darray[1][0] + darray[0][1] + darray[1][2] + darray[2][1]) >> 2;
                next_b = img_array[y3][x3];
            end
        endcase

        next_start_valid4 = 1;
    end
    
    if(ct4 == 255)
        next_start_valid4 = 0;
end
//pipeline 4
always @(*)
begin
    next_out_valid = 0;
    next_r_out = 0;
    next_g_out = 0;
    next_b_out = 0;
    next_ct4 = ct4;

    tmp_r = ((1100 * r - 50 * g - 50 * b + 512) >> 10) > 4095 ? 4095 : ((1100 * r - 50 * g - 50 * b + 512) >> 10);
    tmp_g = ((-50 * r + 1100 * g - 50 * b + 512) >> 10) > 4095 ? 4095 : ((-50 * r + 1100 * g - 50 * b + 512) >> 10);
    tmp_b = ((-50 * r - 50 * g + 1100 * b + 512) >> 10) > 4095 ? 4095 : ((-50 * r - 50 * g + 1100 * b + 512) >> 10);

    tmp_r = (1100 * r - 50 * g - 50 * b + 512) >> 10;
    tmp_g = (-50 * r + 1100 * g - 50 * b + 512) >> 10;
    tmp_b = (-50 * r - 50 * g + 1100 * b + 512) >> 10;

    if(tmp_r[13] == 1)
        temp_r = 0;
    else
    begin
        if(tmp_r > 4095)
            temp_r = 4095;
        else
            temp_r = tmp_r;
    end

    if(tmp_g[13] == 1)
        temp_g = 0;
    else
    begin
        if(tmp_g > 4095)
            temp_g = 4095;
        else
            temp_g = tmp_g;
    end

    if(tmp_b[13] == 1)
        temp_b = 0;
    else
    begin
        if(tmp_b > 4095)
            temp_b = 4095;
        else
            temp_b = tmp_b;
    end
    

    if(start_valid4)
    begin
        next_out_valid = 1;
        next_r_out = temp_r;
        next_g_out = temp_g;
        next_b_out = temp_b;
    end

    if(start_valid4)
    begin
        if(ct4 == 255)
            next_ct4 = 0;
        else
            next_ct4 = ct4 + 1;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                rp_array[i][j] <= 0;
                grp_array[i][j] <= 0;
                gbp_array[i][j] <= 0;
                bp_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                img_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 48; i = i + 1) begin
            tmp_queue[i] <= 0;
        end
        count <= 0;
        ctxi <= 0;
        ctyi <= 0;
        start_valid <= 0;
        start_valid1 <= 0;
        start_valid2 <= 0;
        start_valid3 <= 0;
        start_valid4 <= 0;
        multa <= 0;
        multb <= 0;
        invalid_buf <= 0;
        in_data <= 0;
        r <= 0;
        g <= 0;
        b <= 0;
        out_valid <= 0;
        r_out <= 0;
        g_out <= 0;
        b_out <= 0;
        ct1 <= 0;
        ct2 <= 0;
        ct3 <= 0;
        ct4 <= 0;
    end
    else
    begin
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                rp_array[i][j] <= next_rp_array[i][j];
                grp_array[i][j] <= next_grp_array[i][j];
                gbp_array[i][j] <= next_gbp_array[i][j];
                bp_array[i][j] <= next_bp_array[i][j];
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                img_array[i][j] <= next_img_array[i][j];
            end
        end
        for (i = 0; i < 48; i = i + 1) begin
            tmp_queue[i] <= next_tmp_queue[i];
        end
        count <= next_count;
        ctxi <= next_ctxi;
        ctyi <= next_ctyi;
        start_valid <= next_start_valid;
        start_valid1 <= next_start_valid1;
        start_valid2 <= next_start_valid2;
        start_valid3 <= next_start_valid3;
        start_valid4 <= next_start_valid4;
        multa <= next_multa;
        multb <= next_multb;
        invalid_buf <= next_invalid_buf;
        in_data <= next_in_data;
        r <= next_r;
        g <= next_g;
        b <= next_b;
        out_valid <= next_out_valid;
        r_out <= next_r_out;
        g_out <= next_g_out;
        b_out <= next_b_out;
        ct1 <= next_ct1;
        ct2 <= next_ct2;
        ct3 <= next_ct3;
        ct4 <= next_ct4;
    end
end


endmodule

module SCORE(
    input [11:0] a0, 
    input [11:0] a1, 
    input [11:0] a2, 
    input [11:0] a3,
    output reg [12:0] score,
    output reg [12:0] median
);

reg [11:0] max1, max2, min1, min2, m1, m2, m3, m4, md1, md2, md3, md4;

always @(*)
begin
    max1 = (a0 > a1) ? a0 : a1;
    min1 = (a0 > a1) ? a1 : a0;
    max2 = (a2 > a3) ? a2 : a3;
    min2 = (a2 > a3) ? a3 : a2;

    m1 = (max1 > max2) ? max1 : max2;
    m2 = (max1 > max2) ? max2 : max1; 
    m3 = (min1 > min2) ? min1 : min2; 
    m4 = (min1 > min2) ? min2 : min1;

    median = (m2 + m3) >> 1;

    md1 = m1;
    md2 = (m2 > m3) ? m2 : m3;
    md3 = (m2 > m3) ? m3 : m2;
    md4 = m4;

    score = md1 + md2 - md3 - md4;
end

endmodule