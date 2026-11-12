module SORT_IP #(parameter IP_WIDTH = 8) (
    input      [IP_WIDTH*4-1:0] IN_character,
    input      [IP_WIDTH*5-1:0] IN_weight,
    output reg [IP_WIDTH*4-1:0] OUT_character  // 新增 reg 宣告以搭配 always block
);

    // ===============================================================
    // 1. 將陣列宣告為 reg，方便在 always @(*) 中賦值
    // ===============================================================
    reg [3:0] c_net [0:IP_WIDTH][0:IP_WIDTH-1];
    reg [4:0] w_net [0:IP_WIDTH][0:IP_WIDTH-1];

    genvar i, j;
    generate
        // ===============================================================
        // 2. Initial assignment (Stage 0): 將 1D Input 攤平到 2D Array
        // ===============================================================
        for (i = 0; i < IP_WIDTH; i = i + 1) begin : init_assign
            always @(*) begin
                c_net[0][i] = IN_character[ (IP_WIDTH-i)*4-1 -: 4 ];
                w_net[0][i] = IN_weight[ (IP_WIDTH-i)*5-1 -: 5 ];
            end
        end

        // ===============================================================
        // 3. Sorting Network (Odd-Even Sort Topology)
        // ===============================================================
        for (i = 0; i < IP_WIDTH; i = i + 1) begin : stage
            for (j = 0; j < IP_WIDTH; j = j + 1) begin : node
                
                always @(*) begin
                    if (i % 2 == 0) begin 
                        // ---------------------------------------------------
                        // 偶數階段 (Even Phase): 比較 (0,1), (2,3), (4,5)...
                        // ---------------------------------------------------
                        if (j % 2 == 0 && j < IP_WIDTH - 1) begin
                            // 身為左節點：負責與右邊 (j+1) 比較
                            // 比較條件：右邊權重大，或權重相同但右邊字元ID大 -> 發生 Swap
                            if ( (w_net[i][j] < w_net[i][j+1]) || 
                                 (w_net[i][j] == w_net[i][j+1] && c_net[i][j] < c_net[i][j+1]) ) begin
                                c_net[i+1][j] = c_net[i][j+1];
                                w_net[i+1][j] = w_net[i][j+1];
                            end else begin
                                c_net[i+1][j] = c_net[i][j];
                                w_net[i+1][j] = w_net[i][j];
                            end
                            
                        end else if (j % 2 == 1) begin
                            // 身為右節點：根據左邊 (j-1) 的比較結果決定自己的值
                            if ( (w_net[i][j-1] < w_net[i][j]) || 
                                 (w_net[i][j-1] == w_net[i][j] && c_net[i][j-1] < c_net[i][j]) ) begin
                                c_net[i+1][j] = c_net[i][j-1];
                                w_net[i+1][j] = w_net[i][j-1];
                            end else begin
                                c_net[i+1][j] = c_net[i][j];
                                w_net[i+1][j] = w_net[i][j];
                            end
                            
                        end else begin
                            // 邊界節點：直接 Pass through
                            c_net[i+1][j] = c_net[i][j];
                            w_net[i+1][j] = w_net[i][j];
                        end
                        
                    end else begin 
                        // ---------------------------------------------------
                        // 奇數階段 (Odd Phase): 比較 (1,2), (3,4), (5,6)...
                        // ---------------------------------------------------
                        if (j % 2 == 1 && j < IP_WIDTH - 1) begin
                            // 身為左節點：負責與右邊 (j+1) 比較
                            if ( (w_net[i][j] < w_net[i][j+1]) || 
                                 (w_net[i][j] == w_net[i][j+1] && c_net[i][j] < c_net[i][j+1]) ) begin
                                c_net[i+1][j] = c_net[i][j+1];
                                w_net[i+1][j] = w_net[i][j+1];
                            end else begin
                                c_net[i+1][j] = c_net[i][j];
                                w_net[i+1][j] = w_net[i][j];
                            end
                            
                        end else if (j % 2 == 0 && j > 0) begin
                            // 身為右節點：根據左邊 (j-1) 的比較結果決定自己的值
                            if ( (w_net[i][j-1] < w_net[i][j]) || 
                                 (w_net[i][j-1] == w_net[i][j] && c_net[i][j-1] < c_net[i][j]) ) begin
                                c_net[i+1][j] = c_net[i][j-1];
                                w_net[i+1][j] = w_net[i][j-1];
                            end else begin
                                c_net[i+1][j] = c_net[i][j];
                                w_net[i+1][j] = w_net[i][j];
                            end
                            
                        end else begin
                            // 邊界節點：直接 Pass through
                            c_net[i+1][j] = c_net[i][j];
                            w_net[i+1][j] = w_net[i][j];
                        end
                    end
                end // end always
                
            end
        end

        // ===============================================================
        // 4. Output assignment: 將排序好的最後一個 stage 塞進 OUT_character
        // ===============================================================
        for (i = 0; i < IP_WIDTH; i = i + 1) begin : out_assign
            always @(*) begin
                OUT_character[ (IP_WIDTH-i)*4-1 -: 4 ] = c_net[IP_WIDTH][i];
            end
        end
    endgenerate

endmodule