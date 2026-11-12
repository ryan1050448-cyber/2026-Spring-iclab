module DRCA (
    input [3:0]  drc_sel,
    input [18:0] shape0 ,
    input [18:0] shape1 ,
    input [18:0] shape2 ,
    input [18:0] shape3 ,
    input [18:0] shape4 ,
    input [18:0] shape5 ,
    input [18:0] shape6 ,
    input [18:0] shape7 ,
    input [18:0] shape8 ,
    input [18:0] shape9 ,
    input [18:0] shape10 ,
    input [18:0] shape11 ,
    input [18:0] shape12 ,
    input [18:0] shape13 ,
    input [18:0] shape14 ,
    input [18:0] shape15 ,
    output reg [4:0] drc_out
);


//**************************************************
// Parameter 
//**************************************************


//**************************************************
// Reg & Wire 
//**************************************************
wire [224:0] v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15;
wire [4:0] vio_count;

integer i, j;

reg [3:0] sel;
reg [18:0] data0, data1, data2, data3, data4, data5, data6, data7, data8, data9, data10, data11, data12, data13, data14, data15;
reg [14:0] drc_array [14:0];
reg [16:0] drc_array_17 [16:0];
reg [224:0] drc_vector, v_total;
reg [288:0] drc_vector_17, drc_vector_17_t;
reg [2:0] sel_type;


//**************************************************
// Design 
//**************************************************
BARRAY u0 (.data(data0), .dc_sel(sel), .v(v0));
BARRAY u1 (.data(data1), .dc_sel(sel), .v(v1));
BARRAY u2 (.data(data2), .dc_sel(sel), .v(v2));
BARRAY u3 (.data(data3), .dc_sel(sel), .v(v3));
BARRAY u4 (.data(data4), .dc_sel(sel), .v(v4));
BARRAY u5 (.data(data5), .dc_sel(sel), .v(v5));
BARRAY u6 (.data(data6), .dc_sel(sel), .v(v6));
BARRAY u7 (.data(data7), .dc_sel(sel), .v(v7));
BARRAY u8 (.data(data8), .dc_sel(sel), .v(v8));
BARRAY u9 (.data(data9), .dc_sel(sel), .v(v9));
BARRAY u10 (.data(data10), .dc_sel(sel), .v(v10));
BARRAY u11 (.data(data11), .dc_sel(sel), .v(v11));
BARRAY u12 (.data(data12), .dc_sel(sel), .v(v12));
BARRAY u13 (.data(data13), .dc_sel(sel), .v(v13));
BARRAY u14 (.data(data14), .dc_sel(sel), .v(v14));
BARRAY u15 (.data(data15), .dc_sel(sel), .v(v15));

//input data and select signal to BARRAY
always @(*)
begin
    sel = drc_sel;
    data0 = shape0;
    data1 = shape1;
    data2 = shape2;
    data3 = shape3;
    data4 = shape4;
    data5 = shape5;
    data6 = shape6;
    data7 = shape7;
    data8 = shape8;
    data9 = shape9;
    data10 = shape10;
    data11 = shape11;
    data12 = shape12;
    data13 = shape13;
    data14 = shape14;
    data15 = shape15;
end
// generate drc_vector ,drc_array ,drc_vector_17 ,drc_vector_17_t
always @(*)
begin
    v_total = v0 | v1 | v2 | v3 | v4 | v5 | v6 | v7 | v8 | v9 | v10 | v11 | v12 | v13 | v14 | v15;

    if(sel[0] == 1'b0) // width
        drc_vector = v_total;
    else // spacing
        drc_vector = ~v_total;

    for (i = 0; i < 15; i = i + 1)
    begin
        for (j = 0; j < 15; j = j + 1)
        begin
            drc_array[i][j] = drc_vector[i*15+j];
        end
    end

    for (i = 0; i < 17; i = i + 1)
    begin
        for (j = 0; j < 17; j = j + 1)
        begin
            if((i == 0 || i == 16 || j == 0 || j == 16) && sel[0] == 1'b0) // width
                drc_array_17[i][j] = 1'b0;
            else if((i == 0 || i == 16 || j == 0 || j == 16) && sel[0] == 1'b1) // spacing
                drc_array_17[i][j] = 1'b1;
            else
                drc_array_17[i][j] = drc_array[i-1][j-1];

        end
    end

    for (i = 0; i < 17; i = i + 1)
    begin
        for (j = 0; j < 17; j = j + 1)
        begin
            drc_vector_17[i*17+j] = drc_array_17[i][j];
        end
    end

    for (i = 0; i < 17; i = i + 1)
    begin
        for (j = 0; j < 17; j = j + 1)
        begin
            drc_vector_17_t[i*17+j] = drc_vector_17[j*17+i];
        end
    end
end

always @(*)
begin
    case(sel)
        4'b0000, 4'b0001, 4'b0011, 4'b0100, 4'b0101, 4'b0111:
            sel_type = 3'd2;
        4'b0010, 4'b0110, 4'b1001 ,4'b1011:
            sel_type = 3'd3;
        4'b1000, 4'b1010, 4'b1101:
            sel_type = 3'd4;
        4'b1100:
            sel_type = 3'd5;
        default:
            sel_type = 3'd0;
    endcase
end

// call CALVIO
CALVIO c1 (.drc_vector_17(drc_vector_17), .drc_vector_17_t(drc_vector_17_t), .sel_type(sel_type), .vio_count(vio_count));
//output result
always @(*)
begin
    drc_out = 5'd0;
    drc_out = vio_count;
end

endmodule

module BARRAY (
    input [18:0] data,
    input [3:0] dc_sel,
    output reg [224:0] v
);

reg [2:0] layer;
reg [3:0] l, b, r, u;
integer i, j;
reg [14:0] mask_x, mask_y;

always @(*)
begin
    layer = data[18:16];
    l = data[15:12];
    b = data[11:8];
    r = data[7:4];
    u = data[3:0];

    for (j = 0; j < 15; j = j + 1)
        mask_x[j] = (l <= j && r > j);

    for (i = 0; i < 15; i = i + 1)
        mask_y[i] = (b <= i && u > i);

    if((dc_sel[3:1] + 1) == layer)
    begin
        for (i = 0; i < 15; i = i + 1) 
        begin
            for (j = 0; j < 15; j = j + 1) 
            begin
                v[i*15+j] = mask_x[j] & mask_y[i];
            end
        end
    end
    else
        v = 225'd0;

end
endmodule;

module FDVIO (
    input [16:0] findv,
    input [16:0] findv_cp,
    input [2:0] sel_type,
    output reg [4:0] vio_count
);

integer i;
reg [14:0] vio_bitstream_010, vio_bitstream_0110, vio_bitstream_01110, vio_bitstream_011110;
reg [14:0] final_bitstream;

always @(*)
begin
    vio_bitstream_010 = 15'd0;
    // find 010
    for (i = 0; i < 15; i = i + 1) 
    begin
        if (({findv[i+2], findv[i+1], findv[i]} == 3'b010) && ({findv_cp[i+2], findv_cp[i+1], findv_cp[i]} != 3'b010))
            vio_bitstream_010[i] = 1'b1;
        else
            vio_bitstream_010[i] = 1'b0;
    end

end

always @(*)
begin
    vio_bitstream_0110 = 15'd0;
    // find 0110
    for (i = 0; i < 14; i = i + 1) 
    begin
        if (({findv[i+3], findv[i+2], findv[i+1], findv[i]} == 4'b0110) && ({findv_cp[i+3], findv_cp[i+2], findv_cp[i+1], findv_cp[i]} != 4'b0110))
            vio_bitstream_0110[i] = 1'b1;
        else
            vio_bitstream_0110[i] = 1'b0;
    end
end

always @(*)
begin
    vio_bitstream_01110 = 15'd0;
    // find 01110
    for (i = 0; i < 13; i = i + 1) 
    begin
        if (({findv[i+4], findv[i+3], findv[i+2], findv[i+1], findv[i]} == 5'b01110) && ({findv_cp[i+4], findv_cp[i+3], findv_cp[i+2], findv_cp[i+1], findv_cp[i]} != 5'b01110))
            vio_bitstream_01110[i] = 1'b1;
        else
            vio_bitstream_01110[i] = 1'b0;
    end
end

always @(*)
begin
    vio_bitstream_011110 = 15'd0;
    // find 011110
    for (i = 0; i < 12; i = i + 1) 
    begin
        if (({findv[i+5], findv[i+4], findv[i+3], findv[i+2], findv[i+1], findv[i]} == 6'b011110) && ({findv_cp[i+5], findv_cp[i+4], findv_cp[i+3], findv_cp[i+2], findv_cp[i+1], findv_cp[i]} != 6'b011110))
            vio_bitstream_011110[i] = 1'b1;
        else
            vio_bitstream_011110[i] = 1'b0;
    end
end

always @(*) 
begin
    case(sel_type)
        3'd2:
            final_bitstream = vio_bitstream_010;
        3'd3:
            final_bitstream = vio_bitstream_0110 | vio_bitstream_010;
        3'd4:
            final_bitstream = vio_bitstream_01110 | vio_bitstream_0110 | vio_bitstream_010;
        3'd5:
            final_bitstream = vio_bitstream_011110 | vio_bitstream_01110 | vio_bitstream_0110 | vio_bitstream_010;
        default:
            final_bitstream = 15'd0;
    endcase
end

always @(*)
begin
    vio_count = 5'd0;

    for (i = 0; i < 15; i = i + 1)
        vio_count = vio_count + final_bitstream[i];

end
endmodule

module CALVIO (
    input [288:0] drc_vector_17,
    input [288:0] drc_vector_17_t,
    input [2:0] sel_type,
    output reg [4:0] vio_count
);

integer i, j;
wire [4:0] vio_bitstream_row [15:0];
wire [4:0] vio_bitstream_col [15:0];
reg [16:0] drc_array_17 [16:0];
reg [16:0] drc_array_17_t [16:0];

always @(*)
begin
    for (i = 0; i < 17; i = i + 1) 
    begin
        for (j = 0; j < 17; j = j + 1)
        begin
            drc_array_17[i][j] = drc_vector_17[i*17 + j];
            drc_array_17_t[i][j] = drc_vector_17_t[i*17 + j];
        end
    end
end

genvar gi, gj;
generate
    for (gi = 0; gi < 16; gi = gi + 1) 
    begin :FDMODULE
        FDVIO f1 (.findv(drc_array_17[gi]), .findv_cp(drc_array_17[gi+1]), .sel_type(sel_type), .vio_count(vio_bitstream_row[gi]));
    end

    for (gj = 0; gj < 16; gj = gj + 1) 
    begin :FDMODULET
        FDVIO f2 (.findv(drc_array_17_t[gj]), .findv_cp(drc_array_17_t[gj+1]), .sel_type(sel_type), .vio_count(vio_bitstream_col[gj]));
    end
endgenerate

always @(*)
begin
    vio_count = 5'd0;
    for (i = 0; i < 16; i = i + 1)
        vio_count = vio_count + vio_bitstream_row[i] + vio_bitstream_col[i];
end
endmodule