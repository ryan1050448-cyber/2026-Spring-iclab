module ISP(
    //Input Port
    clk,
    rst_n,

    in_data_valid,
    in_data,
    cmd_valid,
    cmd,

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
input in_data_valid;
input [11:0] in_data;
input cmd_valid;
input [5:0] cmd;

output reg out_valid;
output reg [7:0] r_out;
output reg [7:0] g_out;
output reg [7:0] b_out;
//==================================================================
// SRAM
//==================================================================
wire SRAM_mem0_4096_12_CLK, SRAM_mem1_4096_12_CLK, SRAM_mem2_4096_12_CLK, SRAM_mem3_4096_12_CLK;
wire SRAM_mem0_4096_12_CS, SRAM_mem1_4096_12_CS, SRAM_mem2_4096_12_CS, SRAM_mem3_4096_12_CS;
wire SRAM_mem0_4096_12_OE, SRAM_mem1_4096_12_OE, SRAM_mem2_4096_12_OE, SRAM_mem3_4096_12_OE;
wire SRAM_mem0_4096_12_WE, SRAM_mem1_4096_12_WE, SRAM_mem2_4096_12_WE, SRAM_mem3_4096_12_WE;
wire [11:0] SRAM_mem0_4096_12_A, SRAM_mem1_4096_12_A, SRAM_mem2_4096_12_A, SRAM_mem3_4096_12_A;
wire [11:0] SRAM_mem0_4096_12_DI, SRAM_mem1_4096_12_DI, SRAM_mem2_4096_12_DI, SRAM_mem3_4096_12_DI;
wire [11:0] SRAM_mem0_4096_12_DO, SRAM_mem1_4096_12_DO, SRAM_mem2_4096_12_DO, SRAM_mem3_4096_12_DO;

SRAM_mem0_4096_12  SRAM_4096_12_0  (
    .CLK    (SRAM_mem0_4096_12_CLK ),
    .CS     (SRAM_mem0_4096_12_CS  ),
    .OE     (SRAM_mem0_4096_12_OE  ),
    .WEB    (!SRAM_mem0_4096_12_WE ),
    .A      (SRAM_mem0_4096_12_A   ),
    .DI     (SRAM_mem0_4096_12_DI  ),
    .DO     (SRAM_mem0_4096_12_DO  )
);
SRAM_mem1_4096_12  SRAM_4096_12_1  (
    .CLK    (SRAM_mem1_4096_12_CLK ),
    .CS     (SRAM_mem1_4096_12_CS  ),
    .OE     (SRAM_mem1_4096_12_OE  ),
    .WEB    (!SRAM_mem1_4096_12_WE ),
    .A      (SRAM_mem1_4096_12_A   ),
    .DI     (SRAM_mem1_4096_12_DI  ),
    .DO     (SRAM_mem1_4096_12_DO  )
);
SRAM_mem2_4096_12  SRAM_4096_12_2  (
    .CLK    (SRAM_mem2_4096_12_CLK ),
    .CS     (SRAM_mem2_4096_12_CS  ),
    .OE     (SRAM_mem2_4096_12_OE  ),
    .WEB    (!SRAM_mem2_4096_12_WE ),
    .A      (SRAM_mem2_4096_12_A   ),
    .DI     (SRAM_mem2_4096_12_DI  ),
    .DO     (SRAM_mem2_4096_12_DO  )
);
SRAM_mem3_4096_12  SRAM_4096_12_3  (
    .CLK    (SRAM_mem3_4096_12_CLK ),
    .CS     (SRAM_mem3_4096_12_CS  ),
    .OE     (SRAM_mem3_4096_12_OE  ),
    .WEB    (!SRAM_mem3_4096_12_WE ),
    .A      (SRAM_mem3_4096_12_A   ),
    .DI     (SRAM_mem3_4096_12_DI  ),
    .DO     (SRAM_mem3_4096_12_DO  )
);
//==============================
//   Declaration 
//==============================
reg we_mem0, next_we_mem0, we_mem1, next_we_mem1, we_mem2, next_we_mem2, we_mem3, next_we_mem3;
reg [11:0] addr_mem0, next_addr_mem0, addr_mem1, next_addr_mem1, addr_mem2, next_addr_mem2, addr_mem3, next_addr_mem3;
reg [11:0] di_mem0, next_di_mem0, di_mem1, next_di_mem1, di_mem2, next_di_mem2, di_mem3, next_di_mem3;
reg [11:0] do_mem0, next_do_mem0, do_mem1, next_do_mem1, do_mem2, next_do_mem2, do_mem3, next_do_mem3;
/*reg [11:0] rp_array [0:5][0:5];
reg [11:0] next_rp_array [0:5][0:5];
reg [11:0] grp_array [0:5][0:5];
reg [11:0] next_grp_array [0:5][0:5];
reg [11:0] gbp_array [0:5][0:5];
reg [11:0] next_gbp_array [0:5][0:5];
reg [11:0] bp_array [0:5][0:5];
reg [11:0] next_bp_array [0:5][0:5];*/
reg [3:0] ctxi, next_ctxi, ctyi, next_ctyi;
reg [3:0] x2, y2, x3, y3;
reg [11:0] img_array [0:15][0:15];
reg [11:0] next_img_array [0:15][0:15];
reg start_valid, next_start_valid, start_valid1, next_start_valid1, start_valid2, next_start_valid2, start_valid3, next_start_valid3, start_valid4, next_start_valid4;
reg invalid_buf, next_invalid_buf;
reg [11:0] p2, big_g, pixel_data;
reg [6:0] b_value;
reg [13:0] multa, next_multa, multb, next_multb, r, next_r, g, next_g, b, next_b, tmp_r, tmp_g, tmp_b;
reg [11:0] iarray [0:4][0:4];
reg [11:0] next_iarray [0:4][0:4];
reg [11:0] darray [0:2][0:2];
reg [12:0] score_tmp1, score_tmp2, median_tmp1, median_tmp2, median;
reg [1:0] color;
reg next_out_valid;
reg [11:0] next_r_out, next_g_out, next_b_out, temp_r, temp_g, temp_b;
reg [8:0] ct1, next_ct1, ct2, next_ct2, ct3, next_ct3, ct4, next_ct4;
reg [11:0] tmp_queue [0:47];
reg [11:0] next_tmp_queue [0:47];
reg [11:0] iarray_c, next_iarray_c;

wire [12:0] median_h, median_v, median_d1, median_d2, score_h, score_v, score_d1, score_d2;
integer i,j;

reg [14:0] in_ct, next_in_ct; 
reg [5:0] in_cmd, next_in_cmd;
reg in_cmd_buf, next_in_cmd_buf;
reg [8:0] pixel_ct, next_pixel_ct;
reg read_busy, next_read_busy, read_busy1, read_busy2, read_busy3;
//==================================================================
// SRAM control signal
//==================================================================
assign SRAM_mem0_4096_12_CLK   = clk;
assign SRAM_mem0_4096_12_CS    = 1'b1;
assign SRAM_mem0_4096_12_OE    = 1'b1;
assign SRAM_mem0_4096_12_WE    = we_mem0;
assign SRAM_mem0_4096_12_A     = addr_mem0;
assign SRAM_mem0_4096_12_DI    = di_mem0;

assign SRAM_mem1_4096_12_CLK   = clk;
assign SRAM_mem1_4096_12_CS    = 1'b1;
assign SRAM_mem1_4096_12_OE    = 1'b1;
assign SRAM_mem1_4096_12_WE    = we_mem1;
assign SRAM_mem1_4096_12_A     = addr_mem1;
assign SRAM_mem1_4096_12_DI    = di_mem1;

assign SRAM_mem2_4096_12_CLK   = clk;
assign SRAM_mem2_4096_12_CS    = 1'b1;
assign SRAM_mem2_4096_12_OE    = 1'b1;
assign SRAM_mem2_4096_12_WE    = we_mem2;
assign SRAM_mem2_4096_12_A     = addr_mem2;
assign SRAM_mem2_4096_12_DI    = di_mem2;

assign SRAM_mem3_4096_12_CLK   = clk;
assign SRAM_mem3_4096_12_CS    = 1'b1;
assign SRAM_mem3_4096_12_OE    = 1'b1;
assign SRAM_mem3_4096_12_WE    = we_mem3;
assign SRAM_mem3_4096_12_A     = addr_mem3;
assign SRAM_mem3_4096_12_DI    = di_mem3;

//==============================
//  Your Design 
//==============================
//input image
always @(*)
begin
    next_we_mem0 = 0; next_we_mem1 = 0; next_we_mem2 = 0; next_we_mem3 = 0;
    next_addr_mem0 = 0; next_addr_mem1 = 0; next_addr_mem2 = 0; next_addr_mem3 = 0;
    next_di_mem0 = 0; next_di_mem1 = 0; next_di_mem2 = 0; next_di_mem3 = 0;
    next_in_ct = in_ct; next_pixel_ct = pixel_ct;

    if(in_data_valid)
    begin
        if(in_ct < 4096)//0-4095
        begin
            next_we_mem0 = 1;
            next_addr_mem0 = in_ct;
            next_di_mem0 = in_data;
        end
        else if(in_ct < 8192)//4096-8191
        begin
            next_we_mem1 = 1;
            next_addr_mem1 = in_ct - 4096;
            next_di_mem1 = in_data;
        end
        else if(in_ct < 12288)//8192-12287
        begin
            next_we_mem2 = 1;
            next_addr_mem2 = in_ct - 8192;
            next_di_mem2 = in_data;
        end
        else if(in_ct < 16384)//12288-16383
        begin
            next_we_mem3 = 1;
            next_addr_mem3 = in_ct - 12288;
            next_di_mem3 = in_data;
        end

        next_in_ct = in_ct + 1;
        if(in_ct == 16383)
            next_in_ct = 0;
    end

    if(read_busy)
    begin
        case(in_cmd[5:4])
            0: begin
                next_we_mem0 = 0;
                next_addr_mem0 = {in_cmd[3:0], pixel_ct[7:0]};
            end
            1: begin
                next_we_mem1 = 0;
                next_addr_mem1 = {in_cmd[3:0], pixel_ct[7:0]};
            end
            2: begin
                next_we_mem2 = 0;
                next_addr_mem2 = {in_cmd[3:0], pixel_ct[7:0]};
            end
            3: begin
                next_we_mem3 = 0;
                next_addr_mem3 = {in_cmd[3:0], pixel_ct[7:0]};
            end
        endcase

    end

    if(cmd_valid)
        next_pixel_ct = 0;
    else
        next_pixel_ct = pixel_ct + 1;

end
// do
always @(*)
begin
    next_do_mem0 = SRAM_mem0_4096_12_DO; 
    next_do_mem1 = SRAM_mem1_4096_12_DO; 
    next_do_mem2 = SRAM_mem2_4096_12_DO; 
    next_do_mem3 = SRAM_mem3_4096_12_DO;
end
//cmd
always @(*)
begin
    next_in_cmd = in_cmd;
    next_in_cmd_buf = 0;
    next_read_busy = read_busy;

    if(cmd_valid)
    begin
        next_in_cmd = cmd;
        next_in_cmd_buf = 1;
    end

    if(cmd_valid)
        next_read_busy = 1;
    else if(pixel_ct == 255)
        next_read_busy = 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        we_mem0 <= 0; we_mem1 <= 0; we_mem2 <= 0; we_mem3 <= 0;
        addr_mem0 <= 0; addr_mem1 <= 0; addr_mem2 <= 0; addr_mem3 <= 0;
        di_mem0 <= 0; di_mem1 <= 0; di_mem2 <= 0; di_mem3 <= 0;
        do_mem0 <= 0; do_mem1 <= 0; do_mem2 <= 0; do_mem3 <= 0;
        in_ct <= 0;
        in_cmd <= 0; in_cmd_buf <= 0;
        pixel_ct <= 0;
        read_busy <= 0; read_busy1 <= 0; read_busy2 <= 0; read_busy3 <= 0;
    end
    else
    begin
        we_mem0 <= next_we_mem0; we_mem1 <= next_we_mem1; we_mem2 <= next_we_mem2; we_mem3 <= next_we_mem3;
        addr_mem0 <= next_addr_mem0; addr_mem1 <= next_addr_mem1; addr_mem2 <= next_addr_mem2; addr_mem3 <= next_addr_mem3;
        di_mem0 <= next_di_mem0; di_mem1 <= next_di_mem1; di_mem2 <= next_di_mem2; di_mem3 <= next_di_mem3;
        do_mem0 <= next_do_mem0; do_mem1 <= next_do_mem1; do_mem2 <= next_do_mem2; do_mem3 <= next_do_mem3;
        in_ct <= next_in_ct;
        in_cmd <= next_in_cmd; in_cmd_buf <= next_in_cmd_buf;
        pixel_ct <= next_pixel_ct;
        read_busy <= next_read_busy; read_busy1 <= read_busy; read_busy2 <= read_busy1; read_busy3 <= read_busy2;
    end
end
// param input
/*always @(*)
begin
    for (i = 0; i < 6; i = i + 1) begin
        for (j = 0; j < 6; j = j + 1) begin
            next_rp_array[i][j] = rp_array[i][j];
            next_grp_array[i][j] = grp_array[i][j];
            next_gbp_array[i][j] = gbp_array[i][j];
            next_bp_array[i][j] = bp_array[i][j];
        end
    end
    // --- R Channel ---
    next_rp_array[0][0] = 12'h640; next_rp_array[0][1] = 12'h5dc; next_rp_array[0][2] = 12'h5aa; next_rp_array[0][3] = 12'h5aa; next_rp_array[0][4] = 12'h5dc; next_rp_array[0][5] = 12'h640;
    next_rp_array[1][0] = 12'h5dc; next_rp_array[1][1] = 12'h546; next_rp_array[1][2] = 12'h4e2; next_rp_array[1][3] = 12'h4e2; next_rp_array[1][4] = 12'h546; next_rp_array[1][5] = 12'h5dc;
    next_rp_array[2][0] = 12'h5aa; next_rp_array[2][1] = 12'h4e2; next_rp_array[2][2] = 12'h44c; next_rp_array[2][3] = 12'h44c; next_rp_array[2][4] = 12'h4e2; next_rp_array[2][5] = 12'h5aa;
    next_rp_array[3][0] = 12'h5aa; next_rp_array[3][1] = 12'h4e2; next_rp_array[3][2] = 12'h44c; next_rp_array[3][3] = 12'h44c; next_rp_array[3][4] = 12'h4e2; next_rp_array[3][5] = 12'h5aa;
    next_rp_array[4][0] = 12'h5dc; next_rp_array[4][1] = 12'h546; next_rp_array[4][2] = 12'h4e2; next_rp_array[4][3] = 12'h4e2; next_rp_array[4][4] = 12'h546; next_rp_array[4][5] = 12'h5dc;
    next_rp_array[5][0] = 12'h640; next_rp_array[5][1] = 12'h5dc; next_rp_array[5][2] = 12'h5aa; next_rp_array[5][3] = 12'h5aa; next_rp_array[5][4] = 12'h5dc; next_rp_array[5][5] = 12'h640;
    // --- Gr Channel ---
    next_grp_array[0][0] = 12'h5dc; next_grp_array[0][1] = 12'h58c; next_grp_array[0][2] = 12'h550; next_grp_array[0][3] = 12'h550; next_grp_array[0][4] = 12'h58c; next_grp_array[0][5] = 12'h5dc;
    next_grp_array[1][0] = 12'h58c; next_grp_array[1][1] = 12'h500; next_grp_array[1][2] = 12'h4b0; next_grp_array[1][3] = 12'h4b0; next_grp_array[1][4] = 12'h500; next_grp_array[1][5] = 12'h58c;
    next_grp_array[2][0] = 12'h550; next_grp_array[2][1] = 12'h4b0; next_grp_array[2][2] = 12'h438; next_grp_array[2][3] = 12'h438; next_grp_array[2][4] = 12'h4b0; next_grp_array[2][5] = 12'h550;
    next_grp_array[3][0] = 12'h550; next_grp_array[3][1] = 12'h4b0; next_grp_array[3][2] = 12'h438; next_grp_array[3][3] = 12'h438; next_grp_array[3][4] = 12'h4b0; next_grp_array[3][5] = 12'h550;
    next_grp_array[4][0] = 12'h58c; next_grp_array[4][1] = 12'h500; next_grp_array[4][2] = 12'h4b0; next_grp_array[4][3] = 12'h4b0; next_grp_array[4][4] = 12'h500; next_grp_array[4][5] = 12'h58c;
    next_grp_array[5][0] = 12'h5dc; next_grp_array[5][1] = 12'h58c; next_grp_array[5][2] = 12'h550; next_grp_array[5][3] = 12'h550; next_grp_array[5][4] = 12'h58c; next_grp_array[5][5] = 12'h5dc;
    // --- Gb Channel ---
    next_gbp_array[0][0] = 12'h5dc; next_gbp_array[0][1] = 12'h58c; next_gbp_array[0][2] = 12'h550; next_gbp_array[0][3] = 12'h550; next_gbp_array[0][4] = 12'h58c; next_gbp_array[0][5] = 12'h5dc;
    next_gbp_array[1][0] = 12'h58c; next_gbp_array[1][1] = 12'h500; next_gbp_array[1][2] = 12'h4b0; next_gbp_array[1][3] = 12'h4b0; next_gbp_array[1][4] = 12'h500; next_gbp_array[1][5] = 12'h58c;
    next_gbp_array[2][0] = 12'h550; next_gbp_array[2][1] = 12'h4b0; next_gbp_array[2][2] = 12'h438; next_gbp_array[2][3] = 12'h438; next_gbp_array[2][4] = 12'h4b0; next_gbp_array[2][5] = 12'h550;
    next_gbp_array[3][0] = 12'h550; next_gbp_array[3][1] = 12'h4b0; next_gbp_array[3][2] = 12'h438; next_gbp_array[3][3] = 12'h438; next_gbp_array[3][4] = 12'h4b0; next_gbp_array[3][5] = 12'h550;
    next_gbp_array[4][0] = 12'h58c; next_gbp_array[4][1] = 12'h500; next_gbp_array[4][2] = 12'h4b0; next_gbp_array[4][3] = 12'h4b0; next_gbp_array[4][4] = 12'h500; next_gbp_array[4][5] = 12'h58c;
    next_gbp_array[5][0] = 12'h5dc; next_gbp_array[5][1] = 12'h58c; next_gbp_array[5][2] = 12'h550; next_gbp_array[5][3] = 12'h550; next_gbp_array[5][4] = 12'h58c; next_gbp_array[5][5] = 12'h5dc;
    // --- B Channel ---
    next_bp_array[0][0] = 12'h6a4; next_bp_array[0][1] = 12'h62c; next_bp_array[0][2] = 12'h5dc; next_bp_array[0][3] = 12'h5dc; next_bp_array[0][4] = 12'h62c; next_bp_array[0][5] = 12'h6a4;
    next_bp_array[1][0] = 12'h62c; next_bp_array[1][1] = 12'h58c; next_bp_array[1][2] = 12'h528; next_bp_array[1][3] = 12'h528; next_bp_array[1][4] = 12'h58c; next_bp_array[1][5] = 12'h62c;
    next_bp_array[2][0] = 12'h5dc; next_bp_array[2][1] = 12'h528; next_bp_array[2][2] = 12'h47e; next_bp_array[2][3] = 12'h47e; next_bp_array[2][4] = 12'h528; next_bp_array[2][5] = 12'h5dc;
    next_bp_array[3][0] = 12'h5dc; next_bp_array[3][1] = 12'h528; next_bp_array[3][2] = 12'h47e; next_bp_array[3][3] = 12'h47e; next_bp_array[3][4] = 12'h528; next_bp_array[3][5] = 12'h5dc;
    next_bp_array[4][0] = 12'h62c; next_bp_array[4][1] = 12'h58c; next_bp_array[4][2] = 12'h528; next_bp_array[4][3] = 12'h528; next_bp_array[4][4] = 12'h58c; next_bp_array[4][5] = 12'h62c;
    next_bp_array[5][0] = 12'h6a4; next_bp_array[5][1] = 12'h62c; next_bp_array[5][2] = 12'h5dc; next_bp_array[5][3] = 12'h5dc; next_bp_array[5][4] = 12'h62c; next_bp_array[5][5] = 12'h6a4;
end*/
//ctxi, ctyi
always @(*)
begin
    next_ctxi = ctxi;
    next_ctyi = ctyi;

    if(read_busy3 && pixel_ct >= 3 && pixel_ct < 259) //3-258
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
    pixel_data = 0;
    next_invalid_buf = 0;
    next_start_valid = 0;

    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            next_img_array[i][j] = img_array[i][j];
        end
    end

    if(read_busy2)
    begin
        next_start_valid = 1;
    end
    if(read_busy3)
    begin
        case(in_cmd[5:4])
            0: pixel_data = do_mem0;
            1: pixel_data = do_mem1;
            2: pixel_data = do_mem2;
            3: pixel_data = do_mem3;
            default: pixel_data = 0;
        endcase
    end

    if(start_valid1) //p*g
    begin
        next_img_array[ct1 >> 4][ct1 % 16] = p2;   
    end
    
    if(start_valid2 && ct2 >= 50) //median filter
    begin
        next_img_array[(ct2 - 50) >> 4][(ct2 - 50) % 16] = tmp_queue[0];
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

    case (ctyi)
        4'd0: begin
            case (ctxi)
                4'h0: big_g = 12'h640; 4'h1: big_g = 12'h5c1; 4'h2: big_g = 12'h5fd; 4'h3: big_g = 12'h58c;
                4'h4: big_g = 12'h5cb; 4'h5: big_g = 12'h564; 4'h6: big_g = 12'h5aa; 4'h7: big_g = 12'h550;
                4'h8: big_g = 12'h5aa; 4'h9: big_g = 12'h550; 4'ha: big_g = 12'h5bb; 4'hb: big_g = 12'h578;
                4'hc: big_g = 12'h5dc; 4'hd: big_g = 12'h5a7; 4'he: big_g = 12'h61f; 4'hf: big_g = 12'h5c1;
            endcase
        end
        4'd1, 4'd15: begin
            case (ctxi)
                4'h0: big_g = 12'h5c1; 4'h1: big_g = 12'h650; 4'h2: big_g = 12'h57f; 4'h3: big_g = 12'h5f7;
                4'h4: big_g = 12'h547; 4'h5: big_g = 12'h5bd; 4'h6: big_g = 12'h51b; 4'h7: big_g = 12'h5a0;
                4'h8: big_g = 12'h51b; 4'h9: big_g = 12'h5a0; 4'ha: big_g = 12'h531; 4'hb: big_g = 12'h5da;
                4'hc: big_g = 12'h55e; 4'hd: big_g = 12'h623; 4'he: big_g = 12'h5a0; 4'hf: big_g = 12'h650;
            endcase
        end
        4'd2: begin
            case (ctxi)
                4'h0: big_g = 12'h5fd; 4'h1: big_g = 12'h57f; 4'h2: big_g = 12'h5a4; 4'h3: big_g = 12'h52e;
                4'h4: big_g = 12'h55c; 4'h5: big_g = 12'h4fd; 4'h6: big_g = 12'h524; 4'h7: big_g = 12'h4e5;
                4'h8: big_g = 12'h524; 4'h9: big_g = 12'h4e5; 4'ha: big_g = 12'h540; 4'hb: big_g = 12'h516;
                4'hc: big_g = 12'h578; 4'hd: big_g = 12'h556; 4'he: big_g = 12'h5d1; 4'hf: big_g = 12'h57f;
            endcase
        end
        4'd3: begin
            case (ctxi)
                4'h0: big_g = 12'h58c; 4'h1: big_g = 12'h5f7; 4'h2: big_g = 12'h52e; 4'h3: big_g = 12'h58c;
                4'h4: big_g = 12'h4e5; 4'h5: big_g = 12'h549; 4'h6: big_g = 12'h4b0; 4'h7: big_g = 12'h528;
                4'h8: big_g = 12'h4b0; 4'h9: big_g = 12'h528; 4'ha: big_g = 12'h4cb; 4'hb: big_g = 12'h56b;
                4'hc: big_g = 12'h500; 4'hd: big_g = 12'h5c1; 4'he: big_g = 12'h55e; 4'hf: big_g = 12'h5f7;
            endcase
        end
        4'd4: begin
            case (ctxi)
                4'h0: big_g = 12'h5cb; 4'h1: big_g = 12'h547; 4'h2: big_g = 12'h55c; 4'h3: big_g = 12'h4e5;
                4'h4: big_g = 12'h4fe; 4'h5: big_g = 12'h4a7; 4'h6: big_g = 12'h4b0; 4'h7: big_g = 12'h488;
                4'h8: big_g = 12'h4b0; 4'h9: big_g = 12'h488; 4'ha: big_g = 12'h4d7; 4'hb: big_g = 12'h4c6;
                4'hc: big_g = 12'h525; 4'hd: big_g = 12'h516; 4'he: big_g = 12'h594; 4'hf: big_g = 12'h547;
            endcase
        end
        4'd5: begin
            case (ctxi)
                4'h0: big_g = 12'h564; 4'h1: big_g = 12'h5bd; 4'h2: big_g = 12'h4fd; 4'h3: big_g = 12'h549;
                4'h4: big_g = 12'h4a7; 4'h5: big_g = 12'h4e7; 4'h6: big_g = 12'h460; 4'h7: big_g = 12'h4b6;
                4'h8: big_g = 12'h460; 4'h9: big_g = 12'h4b6; 4'ha: big_g = 12'h483; 4'hb: big_g = 12'h518;
                4'hc: big_g = 12'h4cb; 4'hd: big_g = 12'h583; 4'he: big_g = 12'h531; 4'hf: big_g = 12'h5bd;
            endcase
        end
        4'd6, 4'd8: begin
            case (ctxi)
                4'h0: big_g = 12'h5aa; 4'h1: big_g = 12'h51b; 4'h2: big_g = 12'h524; 4'h3: big_g = 12'h4b0;
                4'h4: big_g = 12'h4b0; 4'h5: big_g = 12'h460; 4'h6: big_g = 12'h44c; 4'h7: big_g = 12'h438;
                4'h8: big_g = 12'h44c; 4'h9: big_g = 12'h438; 4'ha: big_g = 12'h47e; 4'hb: big_g = 12'h488;
                4'hc: big_g = 12'h4e2; 4'hd: big_g = 12'h4e5; 4'he: big_g = 12'h568; 4'hf: big_g = 12'h51b;
            endcase
        end
        4'd7, 4'd9: begin
            case (ctxi)
                4'h0: big_g = 12'h550; 4'h1: big_g = 12'h5a0; 4'h2: big_g = 12'h4e5; 4'h3: big_g = 12'h528;
                4'h4: big_g = 12'h488; 4'h5: big_g = 12'h4b6; 4'h6: big_g = 12'h438; 4'h7: big_g = 12'h47e;
                4'h8: big_g = 12'h438; 4'h9: big_g = 12'h47e; 4'ha: big_g = 12'h460; 4'hb: big_g = 12'h4f0;
                4'hc: big_g = 12'h4b0; 4'hd: big_g = 12'h564; 4'he: big_g = 12'h51b; 4'hf: big_g = 12'h5a0;
            endcase
        end
        4'd10: begin
            case (ctxi)
                4'h0: big_g = 12'h5bb; 4'h1: big_g = 12'h531; 4'h2: big_g = 12'h540; 4'h3: big_g = 12'h4cb;
                4'h4: big_g = 12'h4d7; 4'h5: big_g = 12'h483; 4'h6: big_g = 12'h47e; 4'h7: big_g = 12'h460;
                4'h8: big_g = 12'h47e; 4'h9: big_g = 12'h460; 4'ha: big_g = 12'h4aa; 4'hb: big_g = 12'h4a7;
                4'hc: big_g = 12'h503; 4'hd: big_g = 12'h4fd; 4'he: big_g = 12'h57e; 4'hf: big_g = 12'h531;
            endcase
        end
        4'd11: begin
            case (ctxi)
                4'h0: big_g = 12'h578; 4'h1: big_g = 12'h5da; 4'h2: big_g = 12'h516; 4'h3: big_g = 12'h56b;
                4'h4: big_g = 12'h4c6; 4'h5: big_g = 12'h518; 4'h6: big_g = 12'h488; 4'h7: big_g = 12'h4f0;
                4'h8: big_g = 12'h488; 4'h9: big_g = 12'h4f0; 4'ha: big_g = 12'h4a7; 4'hb: big_g = 12'h542;
                4'hc: big_g = 12'h4e5; 4'hd: big_g = 12'h5a2; 4'he: big_g = 12'h547; 4'hf: big_g = 12'h5da;
            endcase
        end
        4'd12: begin
            case (ctxi)
                4'h0: big_g = 12'h5dc; 4'h1: big_g = 12'h55e; 4'h2: big_g = 12'h578; 4'h3: big_g = 12'h500;
                4'h4: big_g = 12'h525; 4'h5: big_g = 12'h4cb; 4'h6: big_g = 12'h4e2; 4'h7: big_g = 12'h4b0;
                4'h8: big_g = 12'h4e2; 4'h9: big_g = 12'h4b0; 4'ha: big_g = 12'h503; 4'hb: big_g = 12'h4e5;
                4'hc: big_g = 12'h546; 4'hd: big_g = 12'h52e; 4'he: big_g = 12'h5aa; 4'hf: big_g = 12'h55e;
            endcase
        end
        4'd13: begin
            case (ctxi)
                4'h0: big_g = 12'h5a7; 4'h1: big_g = 12'h623; 4'h2: big_g = 12'h556; 4'h3: big_g = 12'h5c1;
                4'h4: big_g = 12'h516; 4'h5: big_g = 12'h583; 4'h6: big_g = 12'h4e5; 4'h7: big_g = 12'h564;
                4'h8: big_g = 12'h4e5; 4'h9: big_g = 12'h564; 4'ha: big_g = 12'h4fd; 4'hb: big_g = 12'h5a2;
                4'hc: big_g = 12'h52e; 4'hd: big_g = 12'h5f2; 4'he: big_g = 12'h57f; 4'hf: big_g = 12'h623;
            endcase
        end
        4'd14: begin
            case (ctxi)
                4'h0: big_g = 12'h61f; 4'h1: big_g = 12'h5a0; 4'h2: big_g = 12'h5d1; 4'h3: big_g = 12'h55e;
                4'h4: big_g = 12'h594; 4'h5: big_g = 12'h531; 4'h6: big_g = 12'h568; 4'h7: big_g = 12'h51b;
                4'h8: big_g = 12'h568; 4'h9: big_g = 12'h51b; 4'ha: big_g = 12'h57e; 4'hb: big_g = 12'h547;
                4'hc: big_g = 12'h5aa; 4'hd: big_g = 12'h57f; 4'he: big_g = 12'h5f8; 4'hf: big_g = 12'h5a0;
            endcase
        end
        default: big_g = 12'h400; 
    endcase

    if(start_valid)
    begin
        next_start_valid1 = 1;
        next_multa = big_g;
        //next_multb = ((pixel_data - b_value) > 0) ? (pixel_data - b_value) : 0;
        if(pixel_data > b_value)
        begin
            next_multb = pixel_data - b_value;
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

    if(start_valid1 && (ct1 >= 35))
    begin
        next_start_valid2 = 1;
    
    end

    //close start_valid2
    if(ct2 == 305)
        next_start_valid2 = 0;
end
//call score submodule
SCORE s1 (.clock(clk), .reset_n(rst_n), .a0(iarray[2][0]), .a1(iarray[2][1]), .a2(iarray[2][3]), .a3(iarray[2][4]), .score(score_h), .median(median_h));
SCORE s2 (.clock(clk), .reset_n(rst_n), .a0(iarray[0][2]), .a1(iarray[1][2]), .a2(iarray[3][2]), .a3(iarray[4][2]), .score(score_v), .median(median_v));
SCORE s3 (.clock(clk), .reset_n(rst_n), .a0(iarray[0][0]), .a1(iarray[1][1]), .a2(iarray[3][3]), .a3(iarray[4][4]), .score(score_d1), .median(median_d1));
SCORE s4 (.clock(clk), .reset_n(rst_n), .a0(iarray[0][4]), .a1(iarray[1][3]), .a2(iarray[3][1]), .a3(iarray[4][0]), .score(score_d2), .median(median_d2));
//1 to 2 temp1
always @(*)
begin
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 0; j < 5; j = j + 1) begin
            next_iarray[i][j] = 0;
        end
    end

    x2 = ct2 % 16;
    y2 = ct2 >> 4;

    //generate 5x5 iarray
    next_iarray[0][0] = (x2 < 2) ? ((y2 < 2) ? img_array[2 - y2][2 - x2] : img_array[y2 - 2][2 - x2]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 - 2] : img_array[y2 - 2][x2 - 2]);
    next_iarray[0][1] = (x2 < 1) ? ((y2 < 2) ? img_array[2 - y2][1 - x2] : img_array[y2 - 2][1 - x2]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 - 1] : img_array[y2 - 2][x2 - 1]);
    next_iarray[0][2] = (y2 < 2) ? img_array[2 - y2][x2] : img_array[y2 - 2][x2];
    next_iarray[0][3] = (x2 > 14) ? ((y2 < 2) ? img_array[2 - y2][30 - x2 - 1] : img_array[y2 - 2][30 - x2 - 1]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 + 1] : img_array[y2 - 2][x2 + 1]);
    next_iarray[0][4] = (x2 > 13) ? ((y2 < 2) ? img_array[2 - y2][30 - x2 - 2] : img_array[y2 - 2][30 - x2 - 2]) : 
                    ((y2 < 2) ? img_array[2 - y2][x2 + 2] : img_array[y2 - 2][x2 + 2]);
    next_iarray[1][0] = (x2 < 2) ? ((y2 < 1) ? img_array[1 - y2][2 - x2] : img_array[y2 - 1][2 - x2]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 - 2] : img_array[y2 - 1][x2 - 2]);
    next_iarray[1][1] = (x2 < 1) ? ((y2 < 1) ? img_array[1 - y2][1 - x2] : img_array[y2 - 1][1 - x2]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 - 1] : img_array[y2 - 1][x2 - 1]);
    next_iarray[1][2] = (y2 < 1) ? img_array[1 - y2][x2] : img_array[y2 - 1][x2];
    next_iarray[1][3] = (x2 > 14) ? ((y2 < 1) ? img_array[1 - y2][30 - x2 - 1] : img_array[y2 - 1][30 - x2 - 1]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 + 1] : img_array[y2 - 1][x2 + 1]);
    next_iarray[1][4] = (x2 > 13) ? ((y2 < 1) ? img_array[1 - y2][30 - x2 - 2] : img_array[y2 - 1][30 - x2 - 2]) : 
                    ((y2 < 1) ? img_array[1 - y2][x2 + 2] : img_array[y2 - 1][x2 + 2]);
    next_iarray[2][0] = (x2 < 2) ? img_array[y2][2 - x2] : img_array[y2][x2 - 2];
    next_iarray[2][1] = (x2 < 1) ? img_array[y2][1 - x2] : img_array[y2][x2 - 1];
    next_iarray[2][2] = img_array[y2][x2];
    next_iarray[2][3] = (x2 > 14) ? img_array[y2][30 - x2 - 1] : img_array[y2][x2 + 1];
    next_iarray[2][4] = (x2 > 13) ? img_array[y2][30 - x2 - 2] : img_array[y2][x2 + 2];
    next_iarray[3][0] = (x2 < 2) ? ((y2 > 14) ? img_array[30 - y2 - 1][2 - x2] : img_array[y2 + 1][2 - x2]) :
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 - 2] : img_array[y2 + 1][x2 - 2]);
    next_iarray[3][1] = (x2 < 1) ? ((y2 > 14) ? img_array[30 - y2 - 1][1 - x2] : img_array[y2 + 1][1 - x2]) : 
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 - 1] : img_array[y2 + 1][x2 - 1]);
    next_iarray[3][2] = (y2 > 14) ? img_array[30 - y2 - 1][x2] : img_array[y2 + 1][x2];
    next_iarray[3][3] = (x2 > 14) ? ((y2 > 14) ? img_array[30 - y2 - 1][30 - x2 - 1] : img_array[y2 + 1][30 - x2 - 1]) : 
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 + 1] : img_array[y2 + 1][x2 + 1]);
    next_iarray[3][4] = (x2 > 13) ? ((y2 > 14) ? img_array[30 - y2 - 1][30 - x2 - 2] : img_array[y2 + 1][30 - x2 - 2]) : 
                    ((y2 > 14) ? img_array[30 - y2 - 1][x2 + 2] : img_array[y2 + 1][x2 + 2]);
    next_iarray[4][0] = (x2 < 2) ? ((y2 > 13) ? img_array[30 - y2 - 2][2 - x2] : img_array[y2 + 2][2 - x2]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 - 2] : img_array[y2 + 2][x2 - 2]);
    next_iarray[4][1] = (x2 < 1) ? ((y2 > 13) ? img_array[30 - y2 - 2][1 - x2] : img_array[y2 + 2][1 - x2]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 - 1] : img_array[y2 + 2][x2 - 1]);
    next_iarray[4][2] = (y2 > 13) ? img_array[30 - y2 - 2][x2] : img_array[y2 + 2][x2];
    next_iarray[4][3] = (x2 > 14) ? ((y2 > 13) ? img_array[30 - y2 - 2][30 - x2 - 1] : img_array[y2 + 2][30 - x2 - 1]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 + 1] : img_array[y2 + 2][x2 + 1]);
    next_iarray[4][4] = (x2 > 13) ? ((y2 > 13) ? img_array[30 - y2 - 2][30 - x2 - 2] : img_array[y2 + 2][30 - x2 - 2]) : 
                    ((y2 > 13) ? img_array[30 - y2 - 2][x2 + 2] : img_array[y2 + 2][x2 + 2]);
end

always @(*)
begin
    next_iarray_c = iarray_c;

    next_iarray_c = iarray[2][2];
end
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
    
    if(start_valid2 && (ct2 > 1 && ct2 <= 257)) // 2-257
    begin
        if(iarray_c > median)
        begin
            if(iarray_c - median > 320)
                next_tmp_queue[47] = median;
            else
                next_tmp_queue[47] = iarray_c;
        end
        else
        begin
            if(median - iarray_c > 320)
                next_tmp_queue[47] = median;
            else
                next_tmp_queue[47] = iarray_c;
        end
    end
    else
    begin
        next_tmp_queue[47] = 0;
    end
    next_tmp_queue[0:46] = tmp_queue[1:47];

    if(ctxi == 10 && ctyi == 6)
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
        next_r_out = temp_r[11:4];
        next_g_out = temp_g[11:4];
        next_b_out = temp_b[11:4];
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
        /*for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                rp_array[i][j] <= 0;
                grp_array[i][j] <= 0;
                gbp_array[i][j] <= 0;
                bp_array[i][j] <= 0;
            end
        end*/
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                img_array[i][j] <= 0;
            end
        end
        for (i = 0; i < 48; i = i + 1) begin
            tmp_queue[i] <= 0;
        end
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                iarray[i][j] <= 0;
            end
        end
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
        iarray_c <= 0;
    end
    else
    begin
        /*for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                rp_array[i][j] <= next_rp_array[i][j];
                grp_array[i][j] <= next_grp_array[i][j];
                gbp_array[i][j] <= next_gbp_array[i][j];
                bp_array[i][j] <= next_bp_array[i][j];
            end
        end*/
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                img_array[i][j] <= next_img_array[i][j];
            end
        end
        for (i = 0; i < 48; i = i + 1) begin
            tmp_queue[i] <= next_tmp_queue[i];
        end
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                iarray[i][j] <= next_iarray[i][j];
            end
        end
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
        iarray_c <= next_iarray_c;
    end
end

endmodule

module SCORE(
    input clock,
    input reset_n,
    input [11:0] a0, 
    input [11:0] a1, 
    input [11:0] a2, 
    input [11:0] a3,
    output reg [12:0] score,
    output reg [12:0] median
);

reg [11:0] max1, max2, min1, min2, m1, m2, m3, m4, md1, md2, md3, md4;
reg [12:0] next_score, next_median;

always @(*)
begin
    next_score = score;
    next_median = median;

    max1 = (a0 > a1) ? a0 : a1;
    min1 = (a0 > a1) ? a1 : a0;
    max2 = (a2 > a3) ? a2 : a3;
    min2 = (a2 > a3) ? a3 : a2;

    m1 = (max1 > max2) ? max1 : max2;
    m2 = (max1 > max2) ? max2 : max1; 
    m3 = (min1 > min2) ? min1 : min2; 
    m4 = (min1 > min2) ? min2 : min1;

    next_median = (m2 + m3) >> 1;

    md1 = m1;
    md2 = (m2 > m3) ? m2 : m3;
    md3 = (m2 > m3) ? m3 : m2;
    md4 = m4;

    next_score = md1 + md2 - md3 - md4;
end

always @(posedge clock or negedge reset_n)
begin
    if(!reset_n)
    begin
        score <= 0;
        median <= 0;
    end
    else
    begin
        score <= next_score;
        median <= next_median;
    end
end

endmodule


module SRAM_mem0_4096_12 (
    input CLK, CS, OE, WEB,
    input [11:0]  A,
    input [11:0] DI,
    output[11:0] DO
);
SUMA180_4096X12 SRAM_4096X12_0 (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      
    .A8(A[8]),      .A9(A[9]),      .A10(A[10]),    .A11(A[11]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

module SRAM_mem1_4096_12 (
    input CLK, CS, OE, WEB,
    input [11:0]  A,
    input [11:0] DI,
    output[11:0] DO
);
SUMA180_4096X12 SRAM_4096X12_1 (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      
    .A8(A[8]),      .A9(A[9]),      .A10(A[10]),    .A11(A[11]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

module SRAM_mem2_4096_12 (
    input CLK, CS, OE, WEB,
    input [11:0]  A,
    input [11:0] DI,
    output[11:0] DO
);
SUMA180_4096X12 SRAM_4096X12_2 (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      
    .A8(A[8]),      .A9(A[9]),      .A10(A[10]),    .A11(A[11]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule

module SRAM_mem3_4096_12 (
    input CLK, CS, OE, WEB,
    input [11:0]  A,
    input [11:0] DI,
    output[11:0] DO
);
SUMA180_4096X12 SRAM_4096X12_3 (
    .A0(A[0]),      .A1(A[1]),      .A2(A[2]),      .A3(A[3]),      .A4(A[4]),      .A5(A[5]),      .A6(A[6]),      .A7(A[7]),      
    .A8(A[8]),      .A9(A[9]),      .A10(A[10]),    .A11(A[11]),
    .DO0(DO[0]),    .DO1(DO[1]),    .DO2(DO[2]),    .DO3(DO[3]),    .DO4(DO[4]),    .DO5(DO[5]),    .DO6(DO[6]),    .DO7(DO[7]), 
    .DO8(DO[8]),    .DO9(DO[9]),    .DO10(DO[10]),  .DO11(DO[11]),  
    .DI0(DI[0]),    .DI1(DI[1]),    .DI2(DI[2]),    .DI3(DI[3]),    .DI4(DI[4]),    .DI5(DI[5]),    .DI6(DI[6]),    .DI7(DI[7]), 
    .DI8(DI[8]),    .DI9(DI[9]),    .DI10(DI[10]),  .DI11(DI[11]),  
    .CK(CLK),                    
    .WEB(WEB),                   
    .OE(OE),                     
    .CS(CS)                      
);
endmodule