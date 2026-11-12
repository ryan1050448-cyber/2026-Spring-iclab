
`include "SORT_IP.v"


module HT(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
parameter IDLE = 0;
parameter BULID = 1;
parameter OUT_I = 2;
parameter OUT_L = 3;
parameter OUT_O = 4;
parameter OUT_V = 5;
parameter OUT_E = 6;
parameter OUT_C = 7;
parameter OUT_A = 8;
parameter OUT_B = 9;

reg next_out_valid, next_out_code;
reg [3:0] weight_array [0:7], next_weight_array [0:7];
reg [3:0] state, next_state;
reg [3:0] in_ct, next_in_ct;
reg [31:0] char_select;
reg [39:0] wt_select;
reg [7:0] char [0:7], next_char [0:7];
reg mode, next_mode;
//8
reg [7:0] char8;
reg [7:0] char8_array [0:6], next_char8_array [0:6];
reg [3:0] weight8;
reg [3:0] weight8_array [0:6], next_weight8_array [0:6];
reg [6:0] code8_array [0:7], next_code8_array [0:7];
reg [2:0] code_len8_array [0:7], next_code_len8_array [0:7];
reg cp8 [0:5];
//7
reg [7:0] char7;
reg [7:0] char7_array [0:5];
reg [3:0] weight7;
reg [3:0] weight7_array [0:5];
reg [6:0] code7_array [0:7];
reg [2:0] code_len7_array [0:7];
reg cp7 [0:4];
//6
reg [7:0] char6;
reg [7:0] char6_array [0:4];
reg [3:0] weight6;
reg [3:0] weight6_array [0:4];
reg [6:0] code6_array [0:7];
reg [2:0] code_len6_array [0:7];
reg cp6 [0:3];
//5
reg [7:0] char5;
reg [7:0] char5_array [0:3];
reg [3:0] weight5;
reg [3:0] weight5_array [0:3];
reg [6:0] code5_array [0:7];
reg [2:0] code_len5_array [0:7];
reg cp5 [0:2];
//4
reg [7:0] char4;
reg [7:0] char4_array [0:2];
reg [4:0] weight4;
reg [4:0] weight4_array [0:2];
reg [6:0] code4_array [0:7];
reg [2:0] code_len4_array [0:7];
reg cp4 [0:1];
//3
reg [7:0] char3;
reg [7:0] char3_array [0:1];
reg [4:0] weight3;
reg [4:0] weight3_array [0:1];
reg [6:0] code3_array [0:7];
reg [2:0] code_len3_array [0:7];
//2
reg [6:0] code2_array [0:7], next_code2_array [0:7];
reg [2:0] code_len2_array [0:7], next_code_len2_array [0:7];

reg [2:0] out_ct, next_out_ct;

wire [31:0] sc;

integer i;
// ===============================================================
// Design
// ===============================================================
SORT_IP #(.IP_WIDTH(8)) u_sort (
    .IN_character(char_select),
    .IN_weight(wt_select),
    .OUT_character(sc)
);
//mode
always @(*)
begin
    next_mode = mode;
    if(in_valid && in_ct == 0)
    begin
        next_mode = out_mode;
    end
end
//weight array
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        next_weight_array[i] = weight_array[i];
    end

    if(in_valid)
    begin
        next_weight_array[0] = in_weight;
        next_weight_array[1:7] = weight_array[0:6];
    end
    if(state == IDLE && in_ct == 8)
    begin
        next_weight_array[0] = weight_array[sc[30:28]];
        next_weight_array[1] = weight_array[sc[26:24]];
        next_weight_array[2] = weight_array[sc[22:20]];
        next_weight_array[3] = weight_array[sc[18:16]];
        next_weight_array[4] = weight_array[sc[14:12]];
        next_weight_array[5] = weight_array[sc[10:8]];
        next_weight_array[6] = weight_array[sc[6:4]];
        next_weight_array[7] = weight_array[sc[2:0]];
    end

end
//select
always @(*)
begin
    char_select = 0;
    wt_select = 0;

    if(state == IDLE && in_ct == 8)
    begin
        char_select = {4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0};
        wt_select = {{1'b0, weight_array[7]}, {1'b0, weight_array[6]}, {1'b0, weight_array[5]}, {1'b0, weight_array[4]}, {1'b0, weight_array[3]}, {1'b0, weight_array[2]}, {1'b0, weight_array[1]}, {1'b0, weight_array[0]}};
    end

end
//present char
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        next_char[i] = char[i];
    end

    if(state == IDLE && in_ct == 8)//first char
    begin
        next_char[0][sc[30:28]] = 1; 
        next_char[1][sc[26:24]] = 1;
        next_char[2][sc[22:20]] = 1; 
        next_char[3][sc[18:16]] = 1;
        next_char[4][sc[14:12]] = 1; 
        next_char[5][sc[10:8]] = 1;
        next_char[6][sc[6:4]] = 1; 
        next_char[7][sc[2:0]] = 1;
    end
    if(state == OUT_I)
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            next_char[i] = 0;
        end
    end
end
//8
always @(*)
begin
    char8 = 0; weight8 = 0;
    for (i = 0; i < 7; i = i + 1)
    begin
        next_char8_array[i] = char8_array[i];
        next_weight8_array[i] = weight8_array[i];
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        next_code8_array[i] = code8_array[i];
        next_code_len8_array[i] = code_len8_array[i];
    end
    for (i = 0; i < 6; i = i + 1)
    begin
        cp8[i] = 0;
    end

    if(state == IDLE && in_ct == 8)
    begin
        char8 = next_char[6] | next_char[7];
        weight8 = next_weight_array[6] + next_weight_array[7];
    end
    //cp8
    for (i = 0; i < 6; i = i + 1)
    begin
        cp8[i] = (weight8 > next_weight_array[i]) ? 1 : 0;
    end

    if(cp8[0] == 1)//0
    begin
        next_char8_array[0] = char8;
        next_weight8_array[0] = weight8;
    end
    else
    begin
        next_char8_array[0] = next_char[0];
        next_weight8_array[0] = next_weight_array[0];
    end
    for (i = 1; i < 6; i = i + 1)//1-5
    begin
        case({cp8[i-1], cp8[i]})
            2'b00: begin
                next_char8_array[i] = next_char[i];
                next_weight8_array[i] = next_weight_array[i];
            end
            2'b01: begin
                next_char8_array[i] = char8;
                next_weight8_array[i] = weight8;
            end
            2'b11: begin
                next_char8_array[i] = next_char[i-1];
                next_weight8_array[i] = next_weight_array[i-1];
            end
        endcase
    end
    if(cp8[5] == 1)//6
    begin
        next_char8_array[6] = next_char[5];
        next_weight8_array[6] = next_weight_array[5];
    end
    else
    begin
        next_char8_array[6] = char8;
        next_weight8_array[6] = weight8;
    end

    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    for (i = 0; i < 8; i = i + 1)
    begin
        if(next_char[7][7-i] == 1)
        begin
            next_code8_array[i][6] = 1'd1;
            next_code8_array[i][5:0] = 6'd0;
        end
        else if(next_char[6][7-i] == 1)
        begin
            next_code8_array[i][6] = 1'd0;
            next_code8_array[i][5:0] = 6'd0;
        end
        else
            next_code8_array[i] = {1'd0, 6'd0};
    end

    //code len array
    for (i = 0; i < 8; i = i + 1)
    begin
        next_code_len8_array[i] = (next_char[6][7-i] || next_char[7][7-i]) ? 1 : 0;
    end

end
//7 ,state = BULID
always @(*)
begin
    char7 = 0; weight7 = 0;
    for (i = 0; i < 6; i = i + 1)
    begin
        char7_array[i] = 0;
        weight7_array[i] = 0;
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        code7_array[i] = 0;
        code_len7_array[i] = 0;
    end
    for (i = 0; i < 5; i = i + 1)
    begin
        cp7[i] = 0;
    end

    char7 = char8_array[5] | char8_array[6];
    weight7 = weight8_array[5] + weight8_array[6];

    //cp7
    for (i = 0; i < 5; i = i + 1)
    begin
        cp7[i] = (weight7 > weight8_array[i]) ? 1 : 0;
    end

    if(cp7[0] == 1)//0
    begin
        char7_array[0] = char7;
        weight7_array[0] = weight7;
    end
    else
    begin
        char7_array[0] = char8_array[0];
        weight7_array[0] = weight8_array[0];
    end
    for (i = 1; i < 5; i = i + 1)//1-4
    begin
        case({cp7[i-1], cp7[i]})
            2'b00: begin
                char7_array[i] = char8_array[i];
                weight7_array[i] = weight8_array[i];
            end
            2'b01: begin
                char7_array[i] = char7;
                weight7_array[i] = weight7;
            end
            2'b11: begin
                char7_array[i] = char8_array[i-1];
                weight7_array[i] = weight8_array[i-1];
            end
        endcase
    end
    if(cp7[4] == 1)//5
    begin
        char7_array[5] = char8_array[4];
        weight7_array[5] = weight8_array[4];
    end
    else
    begin
        char7_array[5] = char7;
        weight7_array[5] = weight7;
    end

    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char8_array[5][7-i] == 1)//push 0
        begin
            code7_array[i][6] = 1'd0;
            code7_array[i][5:0] = code8_array[i][6:1];
        end
        else if(char8_array[6][7-i] == 1)//push 1
        begin
            code7_array[i][6] = 1'd1;
            code7_array[i][5:0] = code8_array[i][6:1];
        end
        else
            code7_array[i] = code8_array[i];
    end
    //code len array
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char8_array[5][7-i] == 1 || char8_array[6][7-i] == 1)
            code_len7_array[i] = code_len8_array[i] + 1;
        else
            code_len7_array[i] = code_len8_array[i];
    end
end
//6
always @(*)
begin
    char6 = 0; weight6 = 0;
    for (i = 0; i < 5; i = i + 1)
    begin
        char6_array[i] = 0;
        weight6_array[i] = 0;
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        code6_array[i] = 0;
        code_len6_array[i] = 0;
    end
    for (i = 0; i < 4; i = i + 1)
    begin
        cp6[i] = 0;
    end

    char6 = char7_array[4] | char7_array[5];
    weight6 = weight7_array[4] + weight7_array[5];

    //cp6
    for (i = 0; i < 4; i = i + 1)
    begin
        cp6[i] = (weight6 > weight7_array[i]) ? 1 : 0;
    end

    if(cp6[0] == 1)//0
    begin
        char6_array[0] = char6;
        weight6_array[0] = weight6;
    end
    else
    begin
        char6_array[0] = char7_array[0];
        weight6_array[0] = weight7_array[0];
    end
    for (i = 1; i < 4; i = i + 1)//1-3
    begin
        case({cp6[i-1], cp6[i]})
            2'b00: begin
                char6_array[i] = char7_array[i];
                weight6_array[i] = weight7_array[i];
            end
            2'b01: begin
                char6_array[i] = char6;
                weight6_array[i] = weight6;
            end
            2'b11: begin
                char6_array[i] = char7_array[i-1];
                weight6_array[i] = weight7_array[i-1];
            end
        endcase
    end
    if(cp6[3] == 1)//4
    begin
        char6_array[4] = char7_array[3];
        weight6_array[4] = weight7_array[3];
    end
    else
    begin
        char6_array[4] = char6;
        weight6_array[4] = weight6;
    end

    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char7_array[4][7-i] == 1)//push 0
        begin
            code6_array[i][6] = 1'd0;
            code6_array[i][5:0] = code7_array[i][6:1];
        end
        else if(char7_array[5][7-i] == 1)//push 1
        begin
            code6_array[i][6] = 1'd1;
            code6_array[i][5:0] = code7_array[i][6:1];
        end
        else
            code6_array[i] = code7_array[i];
    end
    //code len array
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char7_array[4][7-i] == 1 || char7_array[5][7-i] == 1)
            code_len6_array[i] = code_len7_array[i] + 1;
        else
            code_len6_array[i] = code_len7_array[i];
    end

end
//5
always @(*)
begin
    char5 = 0; weight5 = 0;
    for (i = 0; i < 4; i = i + 1)
    begin
        char5_array[i] = 0;
        weight5_array[i] = 0;
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        code5_array[i] = 0;
        code_len5_array[i] = 0;
    end
    for (i = 0; i < 3; i = i + 1)
    begin
        cp5[i] = 0;
    end

    char5 = char6_array[3] | char6_array[4];
    weight5 = weight6_array[3] + weight6_array[4];

    //cp5
    for (i = 0; i < 3; i = i + 1)
    begin
        cp5[i] = (weight5 > weight6_array[i]) ? 1 : 0;
    end

    if(cp5[0] == 1)//0
    begin
        char5_array[0] = char5;
        weight5_array[0] = weight5;
    end
    else
    begin
        char5_array[0] = char6_array[0];
        weight5_array[0] = weight6_array[0];
    end
    for (i = 1; i < 3; i = i + 1)//1-2
    begin
        case({cp5[i-1], cp5[i]})
            2'b00: begin
                char5_array[i] = char6_array[i];
                weight5_array[i] = weight6_array[i];
            end
            2'b01: begin
                char5_array[i] = char5;
                weight5_array[i] = weight5;
            end
            2'b11: begin
                char5_array[i] = char6_array[i-1];
                weight5_array[i] = weight6_array[i-1];
            end
        endcase
    end
    if(cp5[2] == 1)//3
    begin
        char5_array[3] = char6_array[2];
        weight5_array[3] = weight6_array[2];
    end
    else
    begin
        char5_array[3] = char5;
        weight5_array[3] = weight5;
    end

    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char6_array[3][7-i] == 1)//push 0
        begin
            code5_array[i][6] = 1'd0;
            code5_array[i][5:0] = code6_array[i][6:1];
        end
        else if(char6_array[4][7-i] == 1)//push 1
        begin
            code5_array[i][6] = 1'd1;
            code5_array[i][5:0] = code6_array[i][6:1];
        end
        else
            code5_array[i] = code6_array[i];
    end
    //code len array
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char6_array[3][7-i] == 1 || char6_array[4][7-i] == 1)
            code_len5_array[i] = code_len6_array[i] + 1;
        else
            code_len5_array[i] = code_len6_array[i];
    end
end
//4
always @(*)
begin
    char4 = 0; weight4 = 0;
    for (i = 0; i < 3; i = i + 1)
    begin
        char4_array[i] = 0;
        weight4_array[i] = 0;
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        code4_array[i] = 0;
        code_len4_array[i] = 0;
    end
    for (i = 0; i < 2; i = i + 1)
    begin
        cp4[i] = 0;
    end

    char4 = char5_array[2] | char5_array[3];
    weight4 = weight5_array[2] + weight5_array[3];

    //cp4
    for (i = 0; i < 2; i = i + 1)
    begin
        cp4[i] = (weight4 > weight5_array[i]) ? 1 : 0;
    end

    if(cp4[0] == 1)//0
    begin
        char4_array[0] = char4;
        weight4_array[0] = weight4;
    end
    else
    begin
        char4_array[0] = char5_array[0];
        weight4_array[0] = weight5_array[0];
    end
    case({cp4[0], cp4[1]})
        2'b00: begin
            char4_array[1] = char5_array[1];
            weight4_array[1] = weight5_array[1];
            char4_array[2] = char4;
            weight4_array[2] = weight4;
        end
        2'b01: begin
            char4_array[1] = char4;
            weight4_array[1] = weight4;
            char4_array[2] = char5_array[1];
            weight4_array[2] = weight5_array[1];
        end
        2'b11: begin
            char4_array[1] = char5_array[0];
            weight4_array[1] = weight5_array[0];
            char4_array[2] = char5_array[1];
            weight4_array[2] = weight5_array[1];
        end
    endcase
    
    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char5_array[2][7-i] == 1)//push 0
        begin
            code4_array[i][6] = 1'd0;
            code4_array[i][5:0] = code5_array[i][6:1];
        end
        else if(char5_array[3][7-i] == 1)//push 1
        begin
            code4_array[i][6] = 1'd1;
            code4_array[i][5:0] = code5_array[i][6:1];
        end
        else
            code4_array[i] = code5_array[i];
    end
    //code len array
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char5_array[2][7-i] == 1 || char5_array[3][7-i] == 1)
            code_len4_array[i] = code_len5_array[i] + 1;
        else
            code_len4_array[i] = code_len5_array[i];
    end

end
//3
always @(*)
begin
    char3 = 0; weight3 = 0;
    for (i = 0; i < 2; i = i + 1)
    begin
        char3_array[i] = 0;
        weight3_array[i] = 0;
    end
    for (i = 0; i < 8; i = i + 1)
    begin
        code3_array[i] = 0;
        code_len3_array[i] = 0;
    end

    char3 = char4_array[1] | char4_array[2];
    weight3 = weight4_array[1] + weight4_array[2];

    if(weight3 > weight4_array[0])//0
    begin
        char3_array[0] = char3;
        weight3_array[0] = weight3;
        char3_array[1] = char4_array[0];
        weight3_array[1] = weight4_array[0];
    end
    else//1
    begin
        char3_array[0] = char4_array[0];
        weight3_array[0] = weight4_array[0];
        char3_array[1] = char3;
        weight3_array[1] = weight3;
    end
    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char4_array[1][7-i] == 1)//push 0
        begin
            code3_array[i][6] = 1'd0;
            code3_array[i][5:0] = code4_array[i][6:1];
        end
        else if(char4_array[2][7-i] == 1)//push 1
        begin
            code3_array[i][6] = 1'd1;
            code3_array[i][5:0] = code4_array[i][6:1];
        end
        else
            code3_array[i] = code4_array[i];
    end
    //code len array
    for (i = 0; i < 8; i = i + 1)
    begin
        if(char4_array[1][7-i] == 1 || char4_array[2][7-i] == 1)
            code_len3_array[i] = code_len4_array[i] + 1;
        else
            code_len3_array[i] = code_len4_array[i];
    end
end
//2
always @(*)
begin
    for (i = 0; i < 8; i = i + 1)
    begin
        next_code2_array[i] = code2_array[i];
        next_code_len2_array[i] = code_len2_array[i];
    end

    //code len array
    if(state == BULID)
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            next_code_len2_array[i] = code_len3_array[i] + 1;
        end
    end
    //code array
    //A:0, B:1, C:2, E:3, I:4, L:5, O:6, V:7
    if(state == BULID)
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            if(char3_array[0][7-i] == 1)//push 0
            begin
                next_code2_array[i][6] = 1'd0;
                next_code2_array[i][5:0] = code3_array[i][6:1];
            end
            else if(char3_array[1][7-i] == 1)//push 1
            begin
                next_code2_array[i][6] = 1'd1;
                next_code2_array[i][5:0] = code3_array[i][6:1];
            end
            else
                next_code2_array[i] = code3_array[i];
        end
    end

    case(state)
        OUT_A: next_code2_array[0] = code2_array[0] << 1;
        OUT_B: next_code2_array[1] = code2_array[1] << 1;
        OUT_C: next_code2_array[2] = code2_array[2] << 1;
        OUT_E: next_code2_array[3] = code2_array[3] << 1;
        OUT_I: next_code2_array[4] = code2_array[4] << 1;
        OUT_L: next_code2_array[5] = code2_array[5] << 1;
        OUT_O: next_code2_array[6] = code2_array[6] << 1;
        OUT_V: next_code2_array[7] = code2_array[7] << 1;
    endcase

end

//state
always @(*)
begin
    next_state = state;
    case(state)
        IDLE: begin
            next_state = (in_ct == 8) ? BULID : IDLE;
        end
        BULID: begin
            next_state = OUT_I;
        end
        OUT_I: begin
            if(out_ct == code_len2_array[4])
                next_state = (mode == 0) ? OUT_L : OUT_C;
            else
                next_state = OUT_I;
        end
        OUT_L: begin
            if(out_ct == code_len2_array[5])
                next_state = (mode == 0) ? OUT_O : OUT_A;
            else
                next_state = OUT_L;
        end
        OUT_O: begin
            if(out_ct == code_len2_array[6])
                next_state = OUT_V;
            else
                next_state = OUT_O;
        end
        OUT_V: begin
            if(out_ct == code_len2_array[7])
                next_state = OUT_E;
            else
                next_state = OUT_V;
        end
        OUT_E: begin
            if(out_ct == code_len2_array[3])
                next_state = IDLE;
            else
                next_state = OUT_E;
        end
        OUT_C: begin
            if(out_ct == code_len2_array[2])
                next_state = OUT_L;
            else
                next_state = OUT_C;
        end
        OUT_A: begin
            if(out_ct == code_len2_array[0])
                next_state = OUT_B;
            else
                next_state = OUT_A;
        end
        OUT_B: begin
            if(out_ct == code_len2_array[1])
                next_state = IDLE;
            else
                next_state = OUT_B;
        end
    endcase

end
//ct
always @(*)
begin
    next_in_ct = in_ct;
    if(in_valid)
    begin
        next_in_ct = in_ct + 1;
    end
    if(state != next_state)
    begin
        next_in_ct = 0;
    end
end
//output
always @(*)
begin
    next_out_valid = 0;
    next_out_code = 0;
    next_out_ct = 0;

    if(state == BULID)
    begin
        next_out_valid = 1;
        next_out_code = next_code2_array[4][6];//I
        next_out_ct = out_ct + 1;
    end
    if(state == OUT_I)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[4][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[4])
        begin
            if(mode == 0)//change to L
            begin
                next_out_code = code2_array[5][6];
                next_out_ct = 1;
            end
            else//change to C
            begin
                next_out_code = code2_array[2][6];
                next_out_ct = 1;
            end
        end
    end
    else if(state == OUT_L)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[5][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[5])
        begin
            if(mode == 0)//change to O
            begin
                next_out_code = code2_array[6][6];
                next_out_ct = 1;
            end
            else//change to A
            begin
                next_out_code = code2_array[0][6];
                next_out_ct = 1;
            end
        end
    end
    else if(state == OUT_O)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[6][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[6])//change to V
        begin
            next_out_code = code2_array[7][6];
            next_out_ct = 1;
        end
    end
    else if(state == OUT_V)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[7][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[7])//change to E
        begin
            next_out_code = code2_array[3][6];
            next_out_ct = 1;
        end
    end
    else if(state == OUT_E)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[3][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[3])//output mode0 done
        begin
            next_out_valid = 0;
            next_out_code = 0;
            next_out_ct = 0;
        end
    end
    else if(state == OUT_C)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[2][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[2])//change to L
        begin
            next_out_code = code2_array[5][6];
            next_out_ct = 1;
        end
    end
    else if(state == OUT_A)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[0][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[0])//change to B
        begin
            next_out_code = code2_array[1][6];
            next_out_ct = 1;
        end
    end
    else if(state == OUT_B)
    begin
        next_out_valid = 1;
        next_out_code = code2_array[1][5];
        next_out_ct = out_ct + 1;
        if(out_ct == code_len2_array[1])//output mode1 done
        begin
            next_out_valid = 0;
            next_out_code = 0;
            next_out_ct = 0;
        end
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            weight_array[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            char[i] <= 0;
        end
        for (i = 0; i < 7; i = i + 1)
        begin
            char8_array[i] <= 0;
            weight8_array[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            code8_array[i] <= 0;
            code_len8_array[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            code_len2_array[i] <= 0;
            code2_array[i] <= 0;
        end
        out_valid <= 0;
        out_code <= 0;
        state <= 0;
        in_ct <= 0;
        out_ct <= 0;
        mode <= 0;
    end
    else
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            weight_array[i] <= next_weight_array[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            char[i] <= next_char[i];
        end
        for (i = 0; i < 7; i = i + 1)
        begin
            char8_array[i] <= next_char8_array[i];
            weight8_array[i] <= next_weight8_array[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            code8_array[i] <= next_code8_array[i];
            code_len8_array[i] <= next_code_len8_array[i];
        end
        for (i = 0; i < 8; i = i + 1)
        begin
            code_len2_array[i] <= next_code_len2_array[i];
            code2_array[i] <= next_code2_array[i];
        end
        out_valid <= next_out_valid;
        out_code <= next_out_code;
        state <= next_state;
        in_ct <= next_in_ct;
        out_ct <= next_out_ct;
        mode <= next_mode;
    end
end


endmodule