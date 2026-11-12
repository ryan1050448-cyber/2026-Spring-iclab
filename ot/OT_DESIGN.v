

module OT_DESIGN(
    // input signals
    clk,
    rst_n,
	
    in_valid_data,
	in_data,
	
    in_valid_cmd,
	in_cmd,    
	
    // output signals
	out_valid,	
	out_data
);

input              clk;
input              rst_n;

input              in_valid_data;
input       [7:0]  in_data;

input              in_valid_cmd;
input      [9:0]  in_cmd;

output reg         out_valid;
output reg  [7:0]  out_data;

//==================================================================
// parameter & integer
//==================================================================
parameter IMG = 0;
parameter INST = 1;
parameter MOV = 2;
parameter OUT = 3;

//==================================================================
// reg & wire
//==================================================================

// -----------------------------------------------------
// MEM
// -----------------------------------------------------

// MEM_0: 8-bit width, 4096 depth
wire        mem0_web, mem0_oe, mem0_cs;
wire [11:0] mem0_addr;
wire  [7:0] mem0_din;
wire  [7:0] mem0_dout;

reg web, next_web;
reg [11:0] addr, next_addr;
reg [7:0] din, next_din;
reg [7:0] dout, next_dout;
reg [12:0] img_ct, next_img_ct, mov_ct, next_mov_ct, t1_ct, next_t1_ct, t2_ct, next_t2_ct;
reg [3:0] state, next_state;
reg [9:0] instruction, next_instruction;
reg [1:0] op, next_op;
reg [3:0] target1, next_target1, target2, next_target2;
reg next_out_valid;
reg [7:0] next_out_data, t1_pix, next_t1_pix, t2_pix, next_t2_pix;
reg [7:0] out_vec [0:255], next_out_vec [0:255];
reg [8:0] vec_ct, next_vec_ct;
reg [15:0] t1_sum, next_t1_sum, t2_sum, next_t2_sum;
reg [7:0] max_pix, next_max_pix;
reg [7:0] iter, next_iter;
reg [8:0] out_ct, next_out_ct;

integer i;
//==================================================================
// design
//==================================================================
//sram
always @(*)
begin
    next_web = 0;
    next_addr = addr;
    next_din = 0;
    next_dout = dout;
    // sram dout
    next_dout = mem0_dout;
    next_t1_ct = t1_ct;
    next_t2_ct = t2_ct;
    //next_max_pix = max_pix;

    if(state == IMG)
    begin
        if(in_valid_data)// 0-4095
        begin
            next_din = in_data;
            next_addr = img_ct;
            next_web = 1;
        end
    end
    
    if(state == MOV)
    begin
        if(op == 2'b00 || op == 2'b01)// avg
        begin
            if(mov_ct % 2 == 0)// read target1
            begin
                next_addr = target1 * 256 + t1_ct;
                next_web = 0;
                next_t1_ct = t1_ct + 1;
            end
            else // read target2
            begin
                next_addr = target2 * 256 + t2_ct;
                next_web = 0;
                next_t2_ct = t2_ct + 1;
            end
        end
        else if(op == 2'b10)// swap
        begin
            if(mov_ct < 1536) // do swap
            begin
                if(mov_ct % 6 == 0)// read target1
                begin
                    next_addr = target1 * 256 + t1_ct;
                    next_web = 0;
                    next_t1_ct = t1_ct + 1;
                end
                else if(mov_ct % 6 == 1) // read target2
                begin
                    next_addr = target2 * 256 + t2_ct;
                    next_web = 0;
                    next_t2_ct = t2_ct + 1;
                end
                if(mov_ct % 6 == 4)// write 1
                begin
                    next_addr = target1 * 256 + t1_ct - 1;
                    next_web = 1;
                    next_din = next_t2_pix;
                end
                if(mov_ct % 6 == 5)// write 2
                begin
                    next_addr = target2 * 256 + t2_ct - 1;
                    next_web = 1;
                    next_din = t1_pix;
                end
            end
            if(mov_ct >= 1536)
            begin
                if(t1_sum > t2_sum)// read 2
                begin
                    next_addr = target2 * 256 + t2_ct;
                    next_web = 0;
                    next_t2_ct = t2_ct + 1;
                end
                else // read 1
                begin
                    next_addr = target1 * 256 + t1_ct;
                    next_web = 0;
                    next_t1_ct = t1_ct + 1;
                end
            end
            
        end
        else if(op == 2'b11)// max pooling
        begin
            if(mov_ct <= 255)
            begin
                next_addr = target1 * 256 + t1_ct;
                next_web = 0;
                next_t1_ct = t1_ct + 1;
            end
        end
        
    end

    if(state == MOV)
    begin
        if(mov_ct == 1535)
        begin
            next_t1_ct = 0;
            next_t2_ct = 0;
        end
    end

    if(state != next_state)
    begin
        next_t1_ct = 0;
        next_t2_ct = 0;
        //next_max_pix = 0;
    end
end
// count
always @(*)
begin
    next_img_ct = img_ct;
    next_mov_ct = mov_ct;

    if(in_valid_data)
    begin
        next_img_ct = img_ct + 1;
    end
    if(img_ct == 4095)
        next_img_ct = 0;

    if(state == MOV)
    begin
        next_mov_ct = mov_ct + 1;
    end
    if(state != next_state)
        next_mov_ct = 0;
end
//inst
always @(*)
begin
    next_instruction = instruction;
    next_op = op;
    next_target1 = target1;
    next_target2 = target2;

    if(state == INST)
    begin
        if(in_valid_cmd)
        begin
            next_instruction = in_cmd;
            next_op = in_cmd[9:8];
            next_target1 = in_cmd[7:4];
            next_target2 = in_cmd[3:0];
        end
    end

end

// state
always @(*)
begin
    next_state = state;
    next_iter = iter;

    case(state)
        IMG:
        begin
            if(img_ct == 4095)
                next_state = INST;
            else
                next_state = IMG;
        end
        INST:
        begin
            if(in_valid_cmd)
                next_state = MOV;
            else
                next_state = INST;
        end
        MOV:
        begin
            if(vec_ct == 256)
            begin
                next_state = OUT;
                
            end
            else
                next_state = MOV;
        end
        OUT:
        begin
            if(out_ct == 256)
            begin
                next_state = INST;
                next_iter = iter + 1;
            end
            else
            begin
                next_state = OUT;
            end
        end
    endcase

end

always @(*)
begin
    next_t1_sum = t1_sum;
    next_t2_sum = t2_sum;

    if(state == MOV && mov_ct <= 1536)
    begin
        if(mov_ct % 6 == 3)
        begin
            next_t1_sum = t1_sum + dout;
        end
        else if(mov_ct % 6 == 4)
        begin
            next_t2_sum = t2_sum + dout;
        end
    end

    if(state != next_state)
    begin
        next_t1_sum = 0;
        next_t2_sum = 0;
    end
end

//out
always @(*)
begin
    next_out_valid = 0;
    next_out_data = 0;
    next_t1_pix = t1_pix;
    next_t2_pix = t2_pix;
    next_vec_ct = vec_ct;
    next_max_pix = max_pix;
    next_out_ct = out_ct;
    for (i = 0; i < 256; i = i + 1)
    begin
        next_out_vec[i] = out_vec[i];
    end

    if(state == MOV && (op == 2'b00 || op == 2'b01))
    begin
        if(mov_ct >= 3 && mov_ct % 2 == 1)//t1
        begin
            next_t1_pix = dout;
        end
        else if(mov_ct >= 3 && mov_ct % 2 == 0)//t2
        begin
            next_t2_pix = dout;
        end
    end
    if(state == MOV && op == 2'b10)//swap
    begin
        if(mov_ct >= 3 && mov_ct % 6 == 3)
        begin
            next_t1_pix = dout;
        end
        else if(mov_ct >= 3 && mov_ct % 6 == 4)
        begin
            next_t2_pix = dout;
        end
    end

    if(state == MOV)
    begin
        if(op == 2'b00)
        begin
            if((mov_ct - 5) % 2 == 0 && mov_ct >= 5)// 5,7,9...
            begin
                next_out_vec[vec_ct] = (t1_pix + t2_pix) / 2;
                next_vec_ct = vec_ct + 1;
            end
        end
        else if(op == 2'b01)
        begin
            if((mov_ct - 5) % 2 == 0 && mov_ct >= 5)// 5,7,9...
            begin
                if(t1_pix > t2_pix)
                begin
                    next_out_vec[vec_ct] = t1_pix - t2_pix;
                end
                else
                begin
                    next_out_vec[vec_ct] = t2_pix - t1_pix;
                end

                next_vec_ct = vec_ct + 1;
            end
        end
        else if(op == 2'b10)
        begin
            if((mov_ct - 1536) >= 3 && (mov_ct - 1536) <= 258)
            begin
                next_out_vec[vec_ct] = dout;
                next_vec_ct = vec_ct + 1;
            end
        end
        else if(op == 2'b11)
        begin
            if(mov_ct >= 3 && mov_ct <= 258)
            begin
                if(dout > max_pix)
                begin
                    next_max_pix = dout;
                end
                if((mov_ct - 3) % 16 == 0)// row begin
                begin
                    next_max_pix = dout;
                end
                if((mov_ct - 3) % 16 == 15)// row end
                begin
                    next_out_vec[vec_ct] = next_max_pix;
                    next_out_vec[vec_ct + 1] = next_max_pix;
                    next_out_vec[vec_ct + 2] = next_max_pix;
                    next_out_vec[vec_ct + 3] = next_max_pix;
                    next_out_vec[vec_ct + 4] = next_max_pix;
                    next_out_vec[vec_ct + 5] = next_max_pix;
                    next_out_vec[vec_ct + 6] = next_max_pix;
                    next_out_vec[vec_ct + 7] = next_max_pix;
                    next_out_vec[vec_ct + 8] = next_max_pix;
                    next_out_vec[vec_ct + 9] = next_max_pix;
                    next_out_vec[vec_ct + 10] = next_max_pix;
                    next_out_vec[vec_ct + 11] = next_max_pix;
                    next_out_vec[vec_ct + 12] = next_max_pix;
                    next_out_vec[vec_ct + 13] = next_max_pix;
                    next_out_vec[vec_ct + 14] = next_max_pix;
                    next_out_vec[vec_ct + 15] = next_max_pix;

                    next_vec_ct = vec_ct + 16;
                end
                
            end
        end
    end

    if(state == OUT && out_ct <= 255)
    begin
        next_out_valid = 1;
        next_out_data = out_vec[out_ct];
        next_out_ct = out_ct + 1;
    end

    if(state != next_state)
    begin
        next_vec_ct = 0;
        next_max_pix = 0;
        next_out_ct = 0;
    end

end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for (i = 0; i < 256; i = i + 1)
        begin
            out_vec[i] <= 0;
        end
        web <= 0;
        addr <= 0;
        din <= 0;
        dout <= 0;
        img_ct <= 0;
        state <= 0;
        instruction <= 0;
        op <= 0;
        target1 <= 0;
        target2 <= 0;
        mov_ct <= 0;
        out_valid <= 0;
        out_data <= 0;
        t1_ct <= 0;
        t2_ct <= 0;
        t1_pix <= 0;
        t2_pix <= 0;
        vec_ct <= 0;
        t1_sum <= 0;
        t2_sum <= 0;
        max_pix <= 0;
        iter <= 0;
        out_ct <= 0;
    end
    else
    begin
        for (i = 0; i < 256; i = i + 1)
        begin
            out_vec[i] <= next_out_vec[i];
        end
        web <= next_web;
        addr <= next_addr;
        din <= next_din;
        dout <= next_dout;
        img_ct <= next_img_ct;
        state <= next_state;
        instruction <= next_instruction;
        op <= next_op;
        target1 <= next_target1;
        target2 <= next_target2;
        mov_ct <= next_mov_ct;
        out_valid <= next_out_valid;
        out_data <= next_out_data;
        t1_ct <= next_t1_ct;
        t2_ct <= next_t2_ct;
        t1_pix <= next_t1_pix;
        t2_pix <= next_t2_pix;
        vec_ct <= next_vec_ct;
        t1_sum <= next_t1_sum;
        t2_sum <= next_t2_sum;
        max_pix <= next_max_pix;
        iter <= next_iter;
        out_ct <= next_out_ct;
    end
end


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/* 
  There are eight SRAMs in your GTE. You should not change the name of those SRAMs.
  TA will check the value in each SRAMs when your GTE is not busy.
  If you change the name of SRAMs below, you must get the fail in this lab.
  
  You should finish SRAM-related signals assignments for each SRAM.
*/
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// SRAM-related signals assignments
assign mem0_addr = addr;
assign mem0_web  = !web;
assign mem0_din  = din;
assign mem0_oe   = 1;
assign mem0_cs   = 1;

// MEM_0, MEM_1, MEM_2, MEM_3, MEM_4, MEM_5, MEM_6, MEM_7 instantiation
SUMA180_4096X8X1BM4 MEM0(
    .A0(mem0_addr[0]), .A1(mem0_addr[1]), .A2(mem0_addr[2]), .A3(mem0_addr[3]), .A4(mem0_addr[4]), .A5(mem0_addr[5]), .A6(mem0_addr[6]), .A7(mem0_addr[7]), 
    .A8(mem0_addr[8]), .A9(mem0_addr[9]), .A10(mem0_addr[10]), .A11(mem0_addr[11]),
    .DO0(mem0_dout[0]), .DO1(mem0_dout[1]), .DO2(mem0_dout[2]), .DO3(mem0_dout[3]), .DO4(mem0_dout[4]), .DO5(mem0_dout[5]), .DO6(mem0_dout[6]), .DO7(mem0_dout[7]),
    .DI0(mem0_din[0]), .DI1(mem0_din[1]), .DI2(mem0_din[2]), .DI3(mem0_din[3]), .DI4(mem0_din[4]), .DI5(mem0_din[5]), .DI6(mem0_din[6]), .DI7(mem0_din[7]),
    .CK(clk), .WEB(mem0_web), .OE(mem0_oe), .CS(mem0_cs)
);

endmodule