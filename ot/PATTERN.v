//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2026 Spring
//   OT Exercise		
//   Author     		: Cho-Hsun Lee 
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`define CYCLE_TIME      20.0
`define SEED_NUMBER     69
`define PATTERN_NUMBER  100

module PATTERN(
    // Output Port
    clk,
    rst_n,
    in_valid_data,
    in_data,
    in_valid_cmd,
    in_cmd,
    
    // Input Port
    out_valid,
    out_data
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output  logic        clk, rst_n, in_valid_data, in_valid_cmd;
output  logic[7:0]  in_data;
output  logic[9:0]  in_cmd;

input           out_valid;
input   [7:0]   out_data;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
real seed = `SEED_NUMBER;


integer i,j,k;
integer latency, total_latency;
integer pat_num, PAT_NUM;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
logic[7:0]  golden_out[0:15][0:15];

logic[7:0]  golden_Image1[0:15][0:15], golden_Image2[0:15][0:15], golden_Image3[0:15][0:15], golden_Image4[0:15][0:15], golden_Image5[0:15][0:15], golden_Image6[0:15][0:15], golden_Image7[0:15][0:15], golden_Image8[0:15][0:15], golden_Image9[0:15][0:15], golden_Image10[0:15][0:15], golden_Image11[0:15][0:15], golden_Image12[0:15][0:15], golden_Image13[0:15][0:15], golden_Image14[0:15][0:15], golden_Image15[0:15][0:15], golden_Image16[0:15][0:15];

logic[9:0] golden_task_number;

logic[7:0]  golden_ImageA[0:15][0:15], golden_ImageB[0:15][0:15];

logic[50:0] golden_ans1;
logic[50:0] golden_ans2;

logic [10:0] ccntt;

logic [7:0]  temp;

//================================================================
// clock
//================================================================

always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//---------------------------------------------------------------------
//   Pattern_Design
//---------------------------------------------------------------------

initial begin
    force clk = 1'b0;

    reset_task;
    pat_num = 0;
    total_latency = 0;

    input_task1;
    repeat($urandom_range(2, 4)) @(negedge clk);

    for(pat_num=0; pat_num<`PATTERN_NUMBER; pat_num+=1) begin
        ccntt = 0;
        input_task2;

        calculate_task;

        wait_out_valid_task;
        check_ans_task;
        PASS_task;
        repeat($urandom_range(2, 4)) @(negedge clk);

    end

    YOU_PASS_task;

end


/* reset task*/
task reset_task; begin
    rst_n = 'b1;
    in_valid_data = 'b0;
    in_valid_cmd = 'b0;

    ccntt = 0;

    in_data = 'bx;
    in_cmd = 'bx;
    
    #CYCLE; rst_n = 'b0;
    #(3*CYCLE); rst_n = 'b1;
    
    if( (out_valid !== 0) || (out_data !== 0)) begin
        $display("***********************************************************************");
        $display("*                            SPEC FAIL                                  *");
        $display("************** Output signal should be 0 after initial RESET at %4t **************",$time);
        $display("***********************************************************************");
        #(50);
        $finish;
    end
    #CYCLE;
    release clk;
    repeat (5) @(negedge clk);
end endtask

task input_task1; begin                                 //golden_Images1~16 are treated as SRAM for storing 16 images

    for(i=0; i<4096; i=i+1) begin
        in_valid_data = 'b1;
        in_data = $random(seed) % 256;

        if(i<256) begin
            golden_Image1[i/16][i%16] = in_data;
        end
        else if(i >= 256 && i < 512) begin
            golden_Image2[(i-256)/16][(i-256)%16] = in_data;
        end
        else if(i >= 512 && i < 768) begin
            golden_Image3[(i-512)/16][(i-512)%16] = in_data;
        end
        else if(i >= 768 && i < 1024) begin
            golden_Image4[(i-768)/16][(i-768)%16] = in_data;
        end
        else if(i >= 1024 && i < 1280) begin
            golden_Image5[(i-1024)/16][(i-1024)%16] = in_data;
        end
        else if(i >= 1280 && i < 1536) begin
            golden_Image6[(i-1280)/16][(i-1280)%16] = in_data;
        end
        else if(i >= 1536 && i < 1792) begin
            golden_Image7[(i-1536)/16][(i-1536)%16] = in_data;
        end
        else if(i >= 1792 && i < 2048) begin
            golden_Image8[(i-1792)/16][(i-1792)%16] = in_data;
        end
        else if(i >= 2048 && i < 2304) begin
            golden_Image9[(i-2048)/16][(i-2048)%16] = in_data;
        end
        else if(i >= 2304 && i < 2560) begin
            golden_Image10[(i-2304)/16][(i-2304)%16] = in_data;
        end
        else if(i >= 2560 && i < 2816) begin
            golden_Image11[(i-2560)/16][(i-2560)%16] = in_data;
        end
        else if(i >= 2816 && i < 3072) begin
            golden_Image12[(i-2816)/16][(i-2816)%16] = in_data;
        end
        else if(i >= 3072 && i < 3328) begin
            golden_Image13[(i-3072)/16][(i-3072)%16] = in_data; 
        end
        else if(i >= 3328 && i < 3584) begin
            golden_Image14[(i-3328)/16][(i-3328)%16] = in_data;
        end
        else if(i >= 3584 && i < 3840) begin
            golden_Image15[(i-3584)/16][(i-3584)%16] = in_data;
        end
        else if(i >= 3840 && i < 4096) begin
            golden_Image16[(i-3840)/16][(i-3840)%16] = in_data;
        end

        @(negedge clk);
    end


    in_valid_data = 'b0;
    in_data = 'bx;

end endtask

task input_task2; begin                                 //golden_task_number is used for storing cmd
    in_valid_cmd = 'b1;
    in_cmd = $random(seed) % 1024;  // cmd0

    if(in_cmd[7:4] == in_cmd[3:0]) begin
        in_cmd[3:0] = in_cmd[7:4] + 6;
    end

    golden_task_number = in_cmd;

    @(negedge clk);
    in_valid_cmd = 'b0;
    in_cmd = 'bx;
end endtask 

task wait_out_valid_task; begin
  latency = 0;
  while(out_valid !== 1'b1) begin
    if(latency == 2000) begin
        $display("*************************************************************************");
        $display("*                          SPEC FAIL                                    *");
        $display("*                  Latency are over 2000 cycles                          *");
        $display("*************************************************************************");
        repeat(4) @(negedge clk);
        $finish;
    end

    if(out_data !== 0) begin
        $display("*************************************************************************");
        $display("*                          SPEC FAIL                                    *");
        $display("*          out signal should be zero when out_valid is low              *");
        $display("*************************************************************************");
        repeat(4) @(negedge clk);
        $finish;
    end

    latency = latency + 1;
    @(negedge clk);
  end
  total_latency+=latency;
end endtask

task calculate_task; 
reg [1:0] op;
reg [3:0] t1;
reg [3:0] t2;
reg [7:0] img1 [0:15][0:15];
reg [7:0] img2 [0:15][0:15];
reg [15:0] sum1, sum2;
reg [7:0] max;
//integer i, j;
begin                               //you should complete this part, calculate golden_out for checking design answer
    op = golden_task_number[9:8];
    t1 = golden_task_number[7:4];
    t2 = golden_task_number[3:0];
    sum1 = 0;
    sum2 = 0;
    max = 0;

    for (i = 0; i < 16; i = i + 1)
    begin
        for (j = 0; j < 16; j = j + 1)
        begin
            case (t1)
                0: img1[i][j] = golden_Image1[i][j];
                1: img1[i][j] = golden_Image2[i][j];
                2: img1[i][j] = golden_Image3[i][j];
                3: img1[i][j] = golden_Image4[i][j];
                4: img1[i][j] = golden_Image5[i][j];
                5: img1[i][j] = golden_Image6[i][j];
                6: img1[i][j] = golden_Image7[i][j];
                7: img1[i][j] = golden_Image8[i][j];
                8: img1[i][j] = golden_Image9[i][j];
                9: img1[i][j] = golden_Image10[i][j];
                10: img1[i][j] = golden_Image11[i][j];
                11: img1[i][j] = golden_Image12[i][j];
                12: img1[i][j] = golden_Image13[i][j];
                13: img1[i][j] = golden_Image14[i][j];
                14: img1[i][j] = golden_Image15[i][j];
                15: img1[i][j] = golden_Image16[i][j];
            endcase

            case (t2)
                0: img2[i][j] = golden_Image1[i][j];
                1: img2[i][j] = golden_Image2[i][j];
                2: img2[i][j] = golden_Image3[i][j];
                3: img2[i][j] = golden_Image4[i][j];
                4: img2[i][j] = golden_Image5[i][j];
                5: img2[i][j] = golden_Image6[i][j];
                6: img2[i][j] = golden_Image7[i][j];
                7: img2[i][j] = golden_Image8[i][j];
                8: img2[i][j] = golden_Image9[i][j];
                9: img2[i][j] = golden_Image10[i][j];
                10: img2[i][j] = golden_Image11[i][j];
                11: img2[i][j] = golden_Image12[i][j];
                12: img2[i][j] = golden_Image13[i][j];
                13: img2[i][j] = golden_Image14[i][j];
                14: img2[i][j] = golden_Image15[i][j];
                15: img2[i][j] = golden_Image16[i][j];
            endcase
        end
    end

    if(op == 2'b00)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            for (j = 0; j < 16; j = j + 1)
            begin
                golden_out[i][j] = (img1[i][j] + img2[i][j]) / 2;
            end
        end
    end
    else if(op == 2'b01)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            for (j = 0; j < 16; j = j + 1)
            begin
                if(img1[i][j] > img2[i][j])
                begin
                    golden_out[i][j] = img1[i][j] - img2[i][j];
                end
                else
                begin
                    golden_out[i][j] = img2[i][j] - img1[i][j];
                end
            end
        end
    end
    else if(op == 2'b10)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            for (j = 0; j < 16; j = j + 1)
            begin
                temp = img1[i][j];
                img1[i][j] = img2[i][j];
                img2[i][j] = temp;
            end
        end
        for (i = 0; i < 16; i = i + 1)
        begin
            for (j = 0; j < 16; j = j + 1)
            begin
                sum1 = sum1 + img1[i][j];
                sum2 = sum2 + img2[i][j];
            end
        end
        if(sum1 > sum2)
        begin
            for (i = 0; i < 16; i = i + 1)
            begin
                for (j = 0; j < 16; j = j + 1)
                begin
                    golden_out[i][j] = img1[i][j];
                end
            end
        end
        else
        begin
            for (i = 0; i < 16; i = i + 1)
            begin
                for (j = 0; j < 16; j = j + 1)
                begin
                    golden_out[i][j] = img2[i][j];
                end
            end
        end

        for (i = 0; i < 16; i = i + 1)
        begin
            for (j = 0; j < 16; j = j + 1)
            begin
                case (t1)
                    0: golden_Image1[i][j] = img1[i][j];
                    1: golden_Image2[i][j] = img1[i][j];
                    2: golden_Image3[i][j] = img1[i][j];
                    3: golden_Image4[i][j] = img1[i][j];
                    4: golden_Image5[i][j] = img1[i][j];
                    5: golden_Image6[i][j] = img1[i][j];
                    6: golden_Image7[i][j] = img1[i][j];
                    7: golden_Image8[i][j] = img1[i][j];
                    8: golden_Image9[i][j] = img1[i][j];
                    9: golden_Image10[i][j] = img1[i][j];
                    10: golden_Image11[i][j] = img1[i][j];
                    11: golden_Image12[i][j] = img1[i][j];
                    12: golden_Image13[i][j] = img1[i][j];
                    13: golden_Image14[i][j] = img1[i][j];
                    14: golden_Image15[i][j] = img1[i][j];
                    15: golden_Image16[i][j] = img1[i][j];
                endcase

                case (t2)
                    0: golden_Image1[i][j] = img2[i][j];
                    1: golden_Image2[i][j] = img2[i][j];
                    2: golden_Image3[i][j] = img2[i][j];
                    3: golden_Image4[i][j] = img2[i][j];
                    4: golden_Image5[i][j] = img2[i][j];
                    5: golden_Image6[i][j] = img2[i][j];
                    6: golden_Image7[i][j] = img2[i][j];
                    7: golden_Image8[i][j] = img2[i][j];
                    8: golden_Image9[i][j] = img2[i][j];
                    9: golden_Image10[i][j] = img2[i][j];
                    10: golden_Image11[i][j] = img2[i][j];
                    11: golden_Image12[i][j] = img2[i][j];
                    12: golden_Image13[i][j] = img2[i][j];
                    13: golden_Image14[i][j] = img2[i][j];
                    14: golden_Image15[i][j] = img2[i][j];
                    15: golden_Image16[i][j] = img2[i][j];
                endcase
            end
        end

    end
    else if(op == 2'b11)
    begin
        for (i = 0; i < 16; i = i + 1)
        begin
            max = 0;
            for (j = 0; j < 16; j = j + 1)
            begin
                if(img1[i][j] > max)
                begin
                    max = img1[i][j];
                end
            end
            for (j = 0; j < 16; j = j + 1)
                golden_out[i][j] = max;
        end

    end
    

end endtask


task check_ans_task; begin                              //you should complete this part, compare golden_out and out_data(design's output) and check out_valid be high for 256 consecutive cycles
    if(out_valid === 1'b1)
    begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                if(out_data !== golden_out[i][j])
                begin
                    $display("*************************************************************************");
                    $display("       output data should be %d at index (%d, %d), your data is %d       ", golden_out[i][j], i, j, out_data);
                    $display("*************************************************************************");
                    $finish;
                end

                @(negedge clk);
            end
        end
    end
    
    
end endtask


task PASS_task; 
  begin
    $display("\033[32m********************** pass pat_num%d | Your execution cycles = %d cycles **********************\033[0m", pat_num, latency);
  end
endtask

task YOU_PASS_task; begin
    $display("                                                   ....... ... ....... ..... ... ......                 ");
    $display("                                              ......:-+#&@@@&#+-:..-+#@@@@@&+:.....                 ");
    $display("                                        .......:+#@@@@@@&&&&&@@@@@@@@@@&&&&@@@@@*:....              ");
    $display("                                        ....:*@@@@&*=-:::..:*@@@@&+--:::::::::=#@@*....             ");
    $display("                                     .....-&@@@#-::::....-@@@@#-:::::::.........=@@:...             ");
    $display("                                  .  ...=@@@&=::::.....=&@@&=::::::...........:*@@*...              ");
    $display("                                  . ...*@@&-::::.....-&@@&-::::::..........:+&@@@+. ..              ");
    $display("                               .. ....&@@+:::::.....+@@&=::::::.........:*&@@@&-... ..              ");
    $display("                              .. ....&@@=::::.....:+@@&::::::.......:+@@@@@@+......                 ");
    $display("                     ........:-+#@@@@@@=:::...:@@@@@@@@&-::...:-+&@@@@@&*-.......                   ");
    $display("                     ....=*&@@@@@@#*+=:........---::---:......@@@@@@@&+-.........                   ");
    $display("                 ....:*@@@@@&+::..............................::-+#@@@@@@&#-.....                   ");
    $display("              ....:*@@@@&+......::-=+*+:...............................+&@@@@&-........             ");
    $display("             ...=&@@@&+:...:=#@@@@&&###-.................#@@@@&#+-:.......:+#@@@*:.....             ");
    $display("           ...=&@@@*-....-#@@#-:.........................:---=+&@@@&+:.......:=@@@#:......          ");
    $display("         ...:@@@@=.....:&@@+.....................................:#@@@*.........-&@@&:...           ");
    $display("        ...*@@@+......=@@#..........................................=&@@+.........=@@@+... .        ");
    $display("        .:#@@#:......+@@=.............................................=@@#:.........#@@#.....       ");
    $display("    .....&@@+.......-@@=...............................................:&@@:.........+@@&:...       ");
    $display("    ....&@@=........#@#:................................................-&@@:.........+@@#:.        ");
    $display("    ...*@@+........:@@+..................................................=@@#:.........+@@+..       ");
    $display("    ..-@@#:........:@@=...................................................#@@-..........#@@:.       ");
    $display("    .:*@@-..........-=.....................................................+=...........-@@#...     ");
    $display("    .=@@#........................+@@@@#-...................=&@@#:.......................:*@@-...    ");
    $display(" ....#@@-.....................:*@@=..:@@*................*@@*:=#@&:......................=@@#...    ");
    $display(" ...:@@&......................=@@&..-&@@&...............+@@#....#@@......................:&@&:.     ");
    $display(" ...=@@*......................=@@@@@@@@@*...............+@@@@&&@@@@:......................*@@=..    ");
    $display("  ..+@@+.......................*@@+=*@@#:...............:#@&=++#@@=.......................*@@+..    ");
    $display("  ..*@@=............::::::::::...=**+=:...................-#@@@@#-..:::::::::.............*@@+..    ");
    $display(" ...+@@+..........::+@#:::+:::+-...............:*-................::-=:::::::::...........*@@+..    ");
    $display(" ...-@@#.........::=@@-:-@#-:#@+:.........#@=..+@@-..==..........::=@#::&&-:&&-:.........:#@@=..    ");
    $display(" ....&@@..........:#@=::&@=:+@*::.........=@@@&@@@@=#@@-.........:-@#-:*@+:*@*::.........-&@&:..    ");
    $display(" ....+@@+.........::::::-:::::::...........:#@@@@@@@@+...........:=*=::**-:#*:::.........+@@*...    ");
    $display(" ....:&@@-..........:::::::::::.............*@&=&#:@@=............::::::::::::..........:&@@:...    ");
    $display("  ....=@@&:.................................*@&:=::@@=.................::...............#@@-....    ");
    $display("    ...+@@*:................................=@@=:::@@-................................:&@@+....     ");
    $display("    ....*@@&:................................#@&+-#@#:...............................-&@@*....      ");
    $display("     ....=@@@*................................=@@@@#:...............................*@@@=.....      ");
    $display("        ..-&@@@+..............................:...................................*@@@&.....        ");
    $display("         ...+@@@@+:..........................:@&+#&:...........................:+@@@@+......        ");
    $display("         .....+@@@@#=.........................:+*+-..........................=#@@@@+.........       ");
    $display("           .  ..-&@@@@@*:................................................:*&@@@@&-..........        ");
    $display("              .....=&@@@@@@#=-::..................................::-=#@@@@@@&=.....                ");
    $display("                 .....:+#@@@@@@@@&#+=-:::................:::-=+*&@@@@@@@@#+:.......                 ");
    $display("                 ..........:-=#@@@@@@@@@@@@@@&&&&&&&&@@@@@@@@@@@@@@#=-:........                     ");
    $display("                           .........:-=+*#&&&&@@@@@@&&&&#*+--:..... ..                              ");
    $display("                           ..          .. .. ...             .  .. ..                           ");
    $display("                                                     ");
    $display("                                                      ");
    $display("                          \033[0;32m \033[5m    //   ) )     // | |     //   ) )     //   ) )\033[m");
    $display("                          \033[0;32m \033[5m   //___/ /     //__| |    ((           ((\033[m");
    $display("                          \033[0;32m \033[5m  / ____ /     / ___  |      \\           \\\033[m");
    $display("                          \033[0;32m \033[5m //           //    | |        ) )          ) )\033[m");
    $display("                          \033[0;32m \033[5m//           //     | | ((___ / /    ((___ / /\033[m");
    $display("                                  ----------------------------               ");
    $display("                                  --                        --               ");
    $display("                                  --  Congratulations !!    --               ");
    $display("                                  --                        --               ");
    $display("                                  --  \033[0;32mSimulation PASS!!\033[m          ");
    $display("                                  --                        --               ");
    $display("                                  --                        --               ");
    $display("                                Total Latency = %d cycles                                    ", total_latency);
    $display("                                  ----------------------------               ");
    // $display("*                  Computation Time = %10d ns          *", total_latency * `CYCLE_TIME);
    // $display("************************************************************************");
    $finish;
end endtask



always @(*) begin
    if(out_valid === 1 && in_valid_data === 1) begin
        $display("*************************************************************************");
        $display("*                            SPEC FAIL                                  *");
        $display("*               out_valid cannot overlap with in_valid                  *");
        $display("*************************************************************************");
        repeat(4) @(negedge clk);
        $finish;
    end

    if(out_valid === 1 && in_valid_cmd === 1) begin
        $display("*************************************************************************");
        $display("*                            SPEC FAIL                                  *");
        $display("*               out_valid cannot overlap with in_valid                  *");
        $display("*************************************************************************");
        repeat(4) @(negedge clk);
        $finish;
    end
end


endmodule



