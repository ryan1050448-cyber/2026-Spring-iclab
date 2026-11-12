always @(*) begin
    case (y)
        4'd0: begin
            case (x)
                4'h0: lsc_G = 12'h640; 4'h1: lsc_G = 12'h5c1; 4'h2: lsc_G = 12'h5fd; 4'h3: lsc_G = 12'h58c;
                4'h4: lsc_G = 12'h5cb; 4'h5: lsc_G = 12'h564; 4'h6: lsc_G = 12'h5aa; 4'h7: lsc_G = 12'h550;
                4'h8: lsc_G = 12'h5aa; 4'h9: lsc_G = 12'h550; 4'ha: lsc_G = 12'h5bb; 4'hb: lsc_G = 12'h578;
                4'hc: lsc_G = 12'h5dc; 4'hd: lsc_G = 12'h5a7; 4'he: lsc_G = 12'h61f; 4'hf: lsc_G = 12'h5c1;
            endcase
        end
        4'd1, 4'd15: begin
            case (x)
                4'h0: lsc_G = 12'h5c1; 4'h1: lsc_G = 12'h650; 4'h2: lsc_G = 12'h57f; 4'h3: lsc_G = 12'h5f7;
                4'h4: lsc_G = 12'h547; 4'h5: lsc_G = 12'h5bd; 4'h6: lsc_G = 12'h51b; 4'h7: lsc_G = 12'h5a0;
                4'h8: lsc_G = 12'h51b; 4'h9: lsc_G = 12'h5a0; 4'ha: lsc_G = 12'h531; 4'hb: lsc_G = 12'h5da;
                4'hc: lsc_G = 12'h55e; 4'hd: lsc_G = 12'h623; 4'he: lsc_G = 12'h5a0; 4'hf: lsc_G = 12'h650;
            endcase
        end
        4'd2: begin
            case (x)
                4'h0: lsc_G = 12'h5fd; 4'h1: lsc_G = 12'h57f; 4'h2: lsc_G = 12'h5a4; 4'h3: lsc_G = 12'h52e;
                4'h4: lsc_G = 12'h55c; 4'h5: lsc_G = 12'h4fd; 4'h6: lsc_G = 12'h524; 4'h7: lsc_G = 12'h4e5;
                4'h8: lsc_G = 12'h524; 4'h9: lsc_G = 12'h4e5; 4'ha: lsc_G = 12'h540; 4'hb: lsc_G = 12'h516;
                4'hc: lsc_G = 12'h578; 4'hd: lsc_G = 12'h556; 4'he: lsc_G = 12'h5d1; 4'hf: lsc_G = 12'h57f;
            endcase
        end
        4'd3: begin
            case (x)
                4'h0: lsc_G = 12'h58c; 4'h1: lsc_G = 12'h5f7; 4'h2: lsc_G = 12'h52e; 4'h3: lsc_G = 12'h58c;
                4'h4: lsc_G = 12'h4e5; 4'h5: lsc_G = 12'h549; 4'h6: lsc_G = 12'h4b0; 4'h7: lsc_G = 12'h528;
                4'h8: lsc_G = 12'h4b0; 4'h9: lsc_G = 12'h528; 4'ha: lsc_G = 12'h4cb; 4'hb: lsc_G = 12'h56b;
                4'hc: lsc_G = 12'h500; 4'hd: lsc_G = 12'h5c1; 4'he: lsc_G = 12'h55e; 4'hf: lsc_G = 12'h5f7;
            endcase
        end
        4'd4: begin
            case (x)
                4'h0: lsc_G = 12'h5cb; 4'h1: lsc_G = 12'h547; 4'h2: lsc_G = 12'h55c; 4'h3: lsc_G = 12'h4e5;
                4'h4: lsc_G = 12'h4fe; 4'h5: lsc_G = 12'h4a7; 4'h6: lsc_G = 12'h4b0; 4'h7: lsc_G = 12'h488;
                4'h8: lsc_G = 12'h4b0; 4'h9: lsc_G = 12'h488; 4'ha: lsc_G = 12'h4d7; 4'hb: lsc_G = 12'h4c6;
                4'hc: lsc_G = 12'h525; 4'hd: lsc_G = 12'h516; 4'he: lsc_G = 12'h594; 4'hf: lsc_G = 12'h547;
            endcase
        end
        4'd5: begin
            case (x)
                4'h0: lsc_G = 12'h564; 4'h1: lsc_G = 12'h5bd; 4'h2: lsc_G = 12'h4fd; 4'h3: lsc_G = 12'h549;
                4'h4: lsc_G = 12'h4a7; 4'h5: lsc_G = 12'h4e7; 4'h6: lsc_G = 12'h460; 4'h7: lsc_G = 12'h4b6;
                4'h8: lsc_G = 12'h460; 4'h9: lsc_G = 12'h4b6; 4'ha: lsc_G = 12'h483; 4'hb: lsc_G = 12'h518;
                4'hc: lsc_G = 12'h4cb; 4'hd: lsc_G = 12'h583; 4'he: lsc_G = 12'h531; 4'hf: lsc_G = 12'h5bd;
            endcase
        end
        4'd6, 4'd8: begin
            case (x)
                4'h0: lsc_G = 12'h5aa; 4'h1: lsc_G = 12'h51b; 4'h2: lsc_G = 12'h524; 4'h3: lsc_G = 12'h4b0;
                4'h4: lsc_G = 12'h4b0; 4'h5: lsc_G = 12'h460; 4'h6: lsc_G = 12'h44c; 4'h7: lsc_G = 12'h438;
                4'h8: lsc_G = 12'h44c; 4'h9: lsc_G = 12'h438; 4'ha: lsc_G = 12'h47e; 4'hb: lsc_G = 12'h488;
                4'hc: lsc_G = 12'h4e2; 4'hd: lsc_G = 12'h4e5; 4'he: lsc_G = 12'h568; 4'hf: lsc_G = 12'h51b;
            endcase
        end
        4'd7, 4'd9: begin
            case (x)
                4'h0: lsc_G = 12'h550; 4'h1: lsc_G = 12'h5a0; 4'h2: lsc_G = 12'h4e5; 4'h3: lsc_G = 12'h528;
                4'h4: lsc_G = 12'h488; 4'h5: lsc_G = 12'h4b6; 4'h6: lsc_G = 12'h438; 4'h7: lsc_G = 12'h47e;
                4'h8: lsc_G = 12'h438; 4'h9: lsc_G = 12'h47e; 4'ha: lsc_G = 12'h460; 4'hb: lsc_G = 12'h4f0;
                4'hc: lsc_G = 12'h4b0; 4'hd: lsc_G = 12'h564; 4'he: lsc_G = 12'h51b; 4'hf: lsc_G = 12'h5a0;
            endcase
        end
        4'd10: begin
            case (x)
                4'h0: lsc_G = 12'h5bb; 4'h1: lsc_G = 12'h531; 4'h2: lsc_G = 12'h540; 4'h3: lsc_G = 12'h4cb;
                4'h4: lsc_G = 12'h4d7; 4'h5: lsc_G = 12'h483; 4'h6: lsc_G = 12'h47e; 4'h7: lsc_G = 12'h460;
                4'h8: lsc_G = 12'h47e; 4'h9: lsc_G = 12'h460; 4'ha: lsc_G = 12'h4aa; 4'hb: lsc_G = 12'h4a7;
                4'hc: lsc_G = 12'h503; 4'hd: lsc_G = 12'h4fd; 4'he: lsc_G = 12'h57e; 4'hf: lsc_G = 12'h531;
            endcase
        end
        4'd11: begin
            case (x)
                4'h0: lsc_G = 12'h578; 4'h1: lsc_G = 12'h5da; 4'h2: lsc_G = 12'h516; 4'h3: lsc_G = 12'h56b;
                4'h4: lsc_G = 12'h4c6; 4'h5: lsc_G = 12'h518; 4'h6: lsc_G = 12'h488; 4'h7: lsc_G = 12'h4f0;
                4'h8: lsc_G = 12'h488; 4'h9: lsc_G = 12'h4f0; 4'ha: lsc_G = 12'h4a7; 4'hb: lsc_G = 12'h542;
                4'hc: lsc_G = 12'h4e5; 4'hd: lsc_G = 12'h5a2; 4'he: lsc_G = 12'h547; 4'hf: lsc_G = 12'h5da;
            endcase
        end
        4'd12: begin
            case (x)
                4'h0: lsc_G = 12'h5dc; 4'h1: lsc_G = 12'h55e; 4'h2: lsc_G = 12'h578; 4'h3: lsc_G = 12'h500;
                4'h4: lsc_G = 12'h525; 4'h5: lsc_G = 12'h4cb; 4'h6: lsc_G = 12'h4e2; 4'h7: lsc_G = 12'h4b0;
                4'h8: lsc_G = 12'h4e2; 4'h9: lsc_G = 12'h4b0; 4'ha: lsc_G = 12'h503; 4'hb: lsc_G = 12'h4e5;
                4'hc: lsc_G = 12'h546; 4'hd: lsc_G = 12'h52e; 4'he: lsc_G = 12'h5aa; 4'hf: lsc_G = 12'h55e;
            endcase
        end
        4'd13: begin
            case (x)
                4'h0: lsc_G = 12'h5a7; 4'h1: lsc_G = 12'h623; 4'h2: lsc_G = 12'h556; 4'h3: lsc_G = 12'h5c1;
                4'h4: lsc_G = 12'h516; 4'h5: lsc_G = 12'h583; 4'h6: lsc_G = 12'h4e5; 4'h7: lsc_G = 12'h564;
                4'h8: lsc_G = 12'h4e5; 4'h9: lsc_G = 12'h564; 4'ha: lsc_G = 12'h4fd; 4'hb: lsc_G = 12'h5a2;
                4'hc: lsc_G = 12'h52e; 4'hd: lsc_G = 12'h5f2; 4'he: lsc_G = 12'h57f; 4'hf: lsc_G = 12'h623;
            endcase
        end
        4'd14: begin
            case (x)
                4'h0: lsc_G = 12'h61f; 4'h1: lsc_G = 12'h5a0; 4'h2: lsc_G = 12'h5d1; 4'h3: lsc_G = 12'h55e;
                4'h4: lsc_G = 12'h594; 4'h5: lsc_G = 12'h531; 4'h6: lsc_G = 12'h568; 4'h7: lsc_G = 12'h51b;
                4'h8: lsc_G = 12'h568; 4'h9: lsc_G = 12'h51b; 4'ha: lsc_G = 12'h57e; 4'hb: lsc_G = 12'h547;
                4'hc: lsc_G = 12'h5aa; 4'hd: lsc_G = 12'h57f; 4'he: lsc_G = 12'h5f8; 4'hf: lsc_G = 12'h5a0;
            endcase
        end
        default: lsc_G = 12'h400; 
    endcase
end