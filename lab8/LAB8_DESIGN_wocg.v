
module LAB8_DESIGN(
    // input signals
    clk,
    rst_n,
	
    in_valid,
	in_data,
	  
    // output signals
	out_valid,	
	out_data
);

input              clk;
input              rst_n;

input              in_valid;
input       [7:0]  in_data;

output reg         out_valid;
output reg  [11:0]  out_data;

//==================================================================
// parameter & integer
//==================================================================

//==================================================================
// reg & wire
//==================================================================
reg next_out_valid;
reg [11:0] next_out_data;
reg mode, next_mode;
reg [7:0] ma [0:15], next_ma [0:15];
reg [7:0] mb [0:15], next_mb [0:15];
reg [3:0] mh1 [0:15], next_mh1 [0:15], mh2 [0:15], next_mh2 [0:15];
reg [3:0] mf1 [0:15], next_mf1 [0:15], mf2 [0:15], next_mf2 [0:15];
reg [7:0] count, next_count;
reg [11:0] midb [0:15], next_midb [0:15];
reg [7:0] mida [0:15], next_mida [0:15];
reg [3:0] xa1, xa2, xa3, xa4, ya1, ya2, ya3, ya4;
reg [11:0] xb1, xb2, xb3, xb4, yb1, yb2, yb3, yb4;
reg [3:0] x_temp, next_x_temp;
reg [7:0] y_temp, next_y_temp;
reg [7:0] ax2, bx1;

wire [3:0] x_result;
wire [7:0] y_result;

integer j;
//==================================================================
// design
//==================================================================
// count =====================================
always @(*)
begin
    next_count = count;

    if(count == 0 && !in_valid)
        next_count = 0;
    else if(out_valid == 1 && next_out_valid == 0)
        next_count = 0;
    else
        next_count = count + 1;
end
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        count <= 0;
    else
        count <= next_count;
end
// mode ====================================
always @(*)
begin
    next_mode = mode;
    if(in_valid && count == 0)// 0
        next_mode = in_data[0];
end
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        mode <= 0;
    else
        mode <= next_mode;
end
//ma =======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_ma[j] = ma[j];
    end

    if(in_valid && count >= 1 && count <= 16)// 1-16
        next_ma[count-1] = in_data;
end

genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                ma[i] <= 0;
            else
                ma[i] <= next_ma[i];
        end
    end
endgenerate
//mb =======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_mb[j] = mb[j];
    end

    if(in_valid && count >= 17 && count <= 32)// 17-32
        next_mb[count-17] = in_data;
end

//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                mb[i] <= 0;
            else
                mb[i] <= next_mb[i];
        end
    end
endgenerate
//mf1 ======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_mf1[j] = mf1[j];
    end

    if(in_valid && count >= 33 && count <= 48)// 33-48
        next_mf1[count-33] = in_data[3:0];
end

//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                mf1[i] <= 0;
            else
                mf1[i] <= next_mf1[i];
        end
    end
endgenerate
//mh1 ======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_mh1[j] = mh1[j];
    end

    if(in_valid && count >= 49 && count <= 64)// 49-64
        next_mh1[count-49] = in_data[3:0];
end

//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                mh1[i] <= 0;
            else
                mh1[i] <= next_mh1[i];
        end
    end
endgenerate
//mf2 ======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_mf2[j] = mf2[j];
    end

    if(in_valid && count >= 65 && count <= 80)// 65-80
        next_mf2[count-65] = in_data[3:0];
end

//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                mf2[i] <= 0;
            else
                mf2[i] <= next_mf2[i];
        end
    end
endgenerate
//mh2 ======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_mh2[j] = mh2[j];
    end

    if(in_valid && count >= 81 && count <= 96)// 81-96
        next_mh2[count-81] = in_data[3:0];
end

//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                mh2[i] <= 0;
            else
                mh2[i] <= next_mh2[i];
        end
    end
endgenerate

MULT_X mult_x(
    .a1(xa1), .a2(xa2), .a3(xa3), .a4(xa4),
    .b1(xb1), .b2(xb2), .b3(xb3), .b4(xb4),
    .result(x_result)
);
MULT_Y mult_y(
    .a1(ya1), .a2(ya2), .a3(ya3), .a4(ya4),
    .b1(yb1), .b2(yb2), .b3(yb3), .b4(yb4),
    .result(y_result)
);

//x,y mult
always @(*)
begin
    xa1 = 0; xa2 = 0; xa3 = 0; xa4 = 0;
    ya1 = 0; ya2 = 0; ya3 = 0; ya4 = 0;
    xb1 = 0; xb2 = 0; xb3 = 0; xb4 = 0;
    yb1 = 0; yb2 = 0; yb3 = 0; yb4 = 0;

    if(mode == 0 && count >= 65 && count <= 80)// 65-80
    begin
        case((count-65) >> 2)
            0: begin
                xa1 = mf1[0]; xa2 = mf1[1]; xa3 = mf1[2]; xa4 = mf1[3];
                ya1 = mh1[0]; ya2 = mh1[1]; ya3 = mh1[2]; ya4 = mh1[3];
            end
            1: begin
                xa1 = mf1[4]; xa2 = mf1[5]; xa3 = mf1[6]; xa4 = mf1[7];
                ya1 = mh1[4]; ya2 = mh1[5]; ya3 = mh1[6]; ya4 = mh1[7];
            end
            2: begin
                xa1 = mf1[8]; xa2 = mf1[9]; xa3 = mf1[10]; xa4 = mf1[11];
                ya1 = mh1[8]; ya2 = mh1[9]; ya3 = mh1[10]; ya4 = mh1[11];
            end
            3: begin
                xa1 = mf1[12]; xa2 = mf1[13]; xa3 = mf1[14]; xa4 = mf1[15];
                ya1 = mh1[12]; ya2 = mh1[13]; ya3 = mh1[14]; ya4 = mh1[15];
            end
        endcase

        case((count-65) % 4)
            0: begin
                xb1 = ma[0]; xb2 = ma[4]; xb3 = ma[8]; xb4 = ma[12];
                yb1 = ma[0]; yb2 = ma[4]; yb3 = ma[8]; yb4 = ma[12];
            end
            1: begin
                xb1 = ma[1]; xb2 = ma[5]; xb3 = ma[9]; xb4 = ma[13];
                yb1 = ma[1]; yb2 = ma[5]; yb3 = ma[9]; yb4 = ma[13];
            end
            2: begin
                xb1 = ma[2]; xb2 = ma[6]; xb3 = ma[10]; xb4 = ma[14];
                yb1 = ma[2]; yb2 = ma[6]; yb3 = ma[10]; yb4 = ma[14];
            end
            3: begin
                xb1 = ma[3]; xb2 = ma[7]; xb3 = ma[11]; xb4 = ma[15];
                yb1 = ma[3]; yb2 = ma[7]; yb3 = ma[11]; yb4 = ma[15];
            end
        endcase
    end
    else if(mode == 0 && count >= 96 && count <= 111)// 96-111
    begin
        case((count-96) >> 2)
            0: begin
                xa1 = mf2[0]; xa2 = mf2[1]; xa3 = mf2[2]; xa4 = mf2[3];
                ya1 = mh2[0]; ya2 = mh2[1]; ya3 = mh2[2]; ya4 = mh2[3];
            end
            1: begin
                xa1 = mf2[4]; xa2 = mf2[5]; xa3 = mf2[6]; xa4 = mf2[7];
                ya1 = mh2[4]; ya2 = mh2[5]; ya3 = mh2[6]; ya4 = mh2[7];
            end
            2: begin
                xa1 = mf2[8]; xa2 = mf2[9]; xa3 = mf2[10]; xa4 = mf2[11];
                ya1 = mh2[8]; ya2 = mh2[9]; ya3 = mh2[10]; ya4 = mh2[11];
            end
            3: begin
                xa1 = mf2[12]; xa2 = mf2[13]; xa3 = mf2[14]; xa4 = mf2[15];
                ya1 = mh2[12]; ya2 = mh2[13]; ya3 = mh2[14]; ya4 = mh2[15];
            end
        endcase

        case((count-96) % 4)
            0: begin
                xb1 = midb[0]; xb2 = midb[4]; xb3 = midb[8]; xb4 = midb[12];
                yb1 = midb[0]; yb2 = midb[4]; yb3 = midb[8]; yb4 = midb[12];
            end
            1: begin
                xb1 = midb[1]; xb2 = midb[5]; xb3 = midb[9]; xb4 = midb[13];
                yb1 = midb[1]; yb2 = midb[5]; yb3 = midb[9]; yb4 = midb[13];
            end
            2: begin
                xb1 = midb[2]; xb2 = midb[6]; xb3 = midb[10]; xb4 = midb[14];
                yb1 = midb[2]; yb2 = midb[6]; yb3 = midb[10]; yb4 = midb[14];
            end
            3: begin
                xb1 = midb[3]; xb2 = midb[7]; xb3 = midb[11]; xb4 = midb[15];
                yb1 = midb[3]; yb2 = midb[7]; yb3 = midb[11]; yb4 = midb[15];
            end
        endcase
    end
    else if(mode == 1 && count >= 96 && count <= 111)// 96-111
    begin
        case((count-96) >> 2)
            0: begin
                xa1 = mf2[0]; xa2 = mf2[1]; xa3 = mf2[2]; xa4 = mf2[3];
                ya1 = mh2[0]; ya2 = mh2[1]; ya3 = mh2[2]; ya4 = mh2[3];
            end
            1: begin
                xa1 = mf2[4]; xa2 = mf2[5]; xa3 = mf2[6]; xa4 = mf2[7];
                ya1 = mh2[4]; ya2 = mh2[5]; ya3 = mh2[6]; ya4 = mh2[7];
            end
            2: begin
                xa1 = mf2[8]; xa2 = mf2[9]; xa3 = mf2[10]; xa4 = mf2[11];
                ya1 = mh2[8]; ya2 = mh2[9]; ya3 = mh2[10]; ya4 = mh2[11];
            end
            3: begin
                xa1 = mf2[12]; xa2 = mf2[13]; xa3 = mf2[14]; xa4 = mf2[15];
                ya1 = mh2[12]; ya2 = mh2[13]; ya3 = mh2[14]; ya4 = mh2[15];
            end
        endcase

        case((count-96) % 4)
            0: begin
                xb1 = mb[0]; xb2 = mb[4]; xb3 = mb[8]; xb4 = mb[12];
                yb1 = mb[0]; yb2 = mb[4]; yb3 = mb[8]; yb4 = mb[12];
            end
            1: begin
                xb1 = mb[1]; xb2 = mb[5]; xb3 = mb[9]; xb4 = mb[13];
                yb1 = mb[1]; yb2 = mb[5]; yb3 = mb[9]; yb4 = mb[13];
            end
            2: begin
                xb1 = mb[2]; xb2 = mb[6]; xb3 = mb[10]; xb4 = mb[14];
                yb1 = mb[2]; yb2 = mb[6]; yb3 = mb[10]; yb4 = mb[14];
            end
            3: begin
                xb1 = mb[3]; xb2 = mb[7]; xb3 = mb[11]; xb4 = mb[15];
                yb1 = mb[3]; yb2 = mb[7]; yb3 = mb[11]; yb4 = mb[15];
            end
        endcase
    end
    else if(mode == 1 && count >= 112 && count <= 127)// 112-127
    begin
        case((count-112) >> 2)
            0: begin
                xa1 = mf1[0]; xa2 = mf1[1]; xa3 = mf1[2]; xa4 = mf1[3];
                ya1 = mh1[0]; ya2 = mh1[1]; ya3 = mh1[2]; ya4 = mh1[3];
            end
            1: begin
                xa1 = mf1[4]; xa2 = mf1[5]; xa3 = mf1[6]; xa4 = mf1[7];
                ya1 = mh1[4]; ya2 = mh1[5]; ya3 = mh1[6]; ya4 = mh1[7];
            end
            2: begin
                xa1 = mf1[8]; xa2 = mf1[9]; xa3 = mf1[10]; xa4 = mf1[11];
                ya1 = mh1[8]; ya2 = mh1[9]; ya3 = mh1[10]; ya4 = mh1[11];
            end
            3: begin
                xa1 = mf1[12]; xa2 = mf1[13]; xa3 = mf1[14]; xa4 = mf1[15];
                ya1 = mh1[12]; ya2 = mh1[13]; ya3 = mh1[14]; ya4 = mh1[15];
            end
        endcase

        case((count-112) % 4)
            0: begin
                xb1 = mida[0]; xb2 = mida[4]; xb3 = mida[8]; xb4 = mida[12];
                yb1 = mida[0]; yb2 = mida[4]; yb3 = mida[8]; yb4 = mida[12];
            end
            1: begin
                xb1 = mida[1]; xb2 = mida[5]; xb3 = mida[9]; xb4 = mida[13];
                yb1 = mida[1]; yb2 = mida[5]; yb3 = mida[9]; yb4 = mida[13];
            end
            2: begin
                xb1 = mida[2]; xb2 = mida[6]; xb3 = mida[10]; xb4 = mida[14];
                yb1 = mida[2]; yb2 = mida[6]; yb3 = mida[10]; yb4 = mida[14];
            end
            3: begin
                xb1 = mida[3]; xb2 = mida[7]; xb3 = mida[11]; xb4 = mida[15];
                yb1 = mida[3]; yb2 = mida[7]; yb3 = mida[11]; yb4 = mida[15];
            end
        endcase
    end

end

//x,y temp ==============================
always @(*)
begin
    next_x_temp = x_temp;
    next_y_temp = y_temp;

    if(mode == 0 && ((count >= 65 && count <= 80) || (count >= 96 && count <= 111)))// 65-80, 96-111
    begin
        next_x_temp = x_result;
        next_y_temp = y_result;
    end
    else if(mode == 1 && ((count >= 96 && count <= 111) || (count >= 112 && count <= 127)))// 96-111, 112-127
    begin
        next_x_temp = x_result;
        next_y_temp = y_result;
    end
end
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        x_temp <= 0;
    else
        x_temp <= next_x_temp;
end
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        y_temp <= 0;
    else
        y_temp <= next_y_temp;
end
//midb =======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_midb[j] = midb[j];
    end

    if(mode == 0 && count >= 66 && count <= 81)// 66-81
    begin
        next_midb[count-66] = (x_temp * mb[count-66]) ^ y_temp;
    end

end
//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                midb[i] <= 0;
            else
                midb[i] <= next_midb[i];
        end
    end
endgenerate
//mida =======================================
always @(*)
begin
    for (j = 0; j < 16; j = j + 1) begin
        next_mida[j] = mida[j];
    end
    ax2 = 0;

    if(mode == 1 && count >= 97 && count <= 112)// 97-112
    begin
        ax2 = ma[count-97] ^ y_temp;
        next_mida[count-97] = ax2 / x_temp;
    end

end
//genvar i;
generate
    for (i = 0; i < 16; i = i + 1)
    begin
        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                mida[i] <= 0;
            else
                mida[i] <= next_mida[i];
        end
    end
endgenerate


//out =======================================
always @(*)
begin
    next_out_valid = 0;
    next_out_data = 0;
    bx1 = 0;

    if(mode == 0)
    begin
        if(count >= 97 && count <= 112)// 97-112
        begin
            next_out_valid = 1;
            next_out_data = (x_temp * ma[count-97]) ^ y_temp;
        end
        else if(count >= 113 && count <= 128)// 113-128
        begin
            next_out_valid = 1;
            next_out_data = midb[count-113];
        end
    end
    
    if(mode == 1)
    begin
        if(count >= 97 && count <= 112)// 97-112
        begin
            next_out_valid = 1;
            next_out_data = next_mida[count-97];
        end
        else if(count >= 113 && count <= 128)// 113-128
        begin
            next_out_valid = 1;
            bx1 = mb[count-113] ^ y_temp;
            next_out_data = bx1 / x_temp;
        end
    end

end
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) 
    begin
        out_valid <= 0;
        out_data <= 0;
    end
    else
    begin
        out_valid <= next_out_valid;
        out_data <= next_out_data;
    end
end


endmodule

module MULT_X(
    input [3:0] a1,
    input [3:0] a2,
    input [3:0] a3,
    input [3:0] a4,
    input [11:0] b1,
    input [11:0] b2,
    input [11:0] b3,
    input [11:0] b4,
    output reg [3:0] result
);

//reg [15:0] temp1, temp2, temp3, temp4;
//reg [17:0] temp_result;
reg [7:0] temp1, temp2, temp3, temp4;
reg [9:0] temp_result;

always @(*)
begin
    /*temp1 = a1 * b1;
    temp2 = a2 * b2;
    temp3 = a3 * b3;
    temp4 = a4 * b4;*/
    temp1 = (a1 % 15) * (b1 % 15);
    temp2 = (a2 % 15) * (b2 % 15);
    temp3 = (a3 % 15) * (b3 % 15);
    temp4 = (a4 % 15) * (b4 % 15);
    temp_result = temp1 + temp2 + temp3 + temp4;
    
    result = (temp_result % 15) + 1; 
end

endmodule

module MULT_Y(
    input [3:0] a1,
    input [3:0] a2,
    input [3:0] a3,
    input [3:0] a4,
    input [11:0] b1,
    input [11:0] b2,
    input [11:0] b3,
    input [11:0] b4,
    output reg [7:0] result
);

//reg [15:0] temp1, temp2, temp3, temp4;
//reg [17:0] temp_result;
reg [7:0] temp1, temp2, temp3, temp4;
reg [9:0] temp_result;

always @(*)
begin
    /*temp1 = a1 * b1;
    temp2 = a2 * b2;
    temp3 = a3 * b3;
    temp4 = a4 * b4;*/
    temp1 = (a1 % 256) * (b1 % 256);
    temp2 = (a2 % 256) * (b2 % 256);
    temp3 = (a3 % 256) * (b3 % 256);
    temp4 = (a4 % 256) * (b4 % 256);
    temp_result = temp1 + temp2 + temp3 + temp4;
    
    result = temp_result % 256; 
end

endmodule