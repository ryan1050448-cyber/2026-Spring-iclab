//###############################################################################################
//***********************************************************************************************
//    File Name   : SORT_IP.v
//    Module Name : SORT_TP
//***********************************************************************************************
//###############################################################################################

module SORT_IP #(parameter IP_WIDTH = 3)(
	//Input signals
	IN_character, IN_weight,
	//Output signalsll
	OUT_character
);

// ======================================================
// Input & Output Declaration
// ======================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ======================================================
// Declaration
// ======================================================
reg [4:0] wt_array [0:IP_WIDTH][0:IP_WIDTH-1];
reg [3:0] ch_array [0:IP_WIDTH][0:IP_WIDTH-1];

genvar gi, gj;

// ======================================================
// Design start
// ======================================================
generate
	//initial
	for (gi = 0; gi < IP_WIDTH; gi = gi + 1) 
	begin : first_assign
		always @(*) 
		begin
			ch_array[0][gi] = IN_character[(IP_WIDTH-gi)*4-1 -: 4];
			wt_array[0][gi] = IN_weight[(IP_WIDTH-gi)*5-1 -: 5];
		end
	end
	//odd even sort, large to small
	for (gi = 0; gi < IP_WIDTH; gi = gi + 1)
	begin : round
		always @(*) 
		begin
			integer j; 
			//default
			for (j = 0; j < IP_WIDTH; j = j + 1) 
			begin
				ch_array[gi+1][j] = ch_array[gi][j];
				wt_array[gi+1][j] = wt_array[gi][j];
			end
			
			for (j = (gi % 2); j < IP_WIDTH - 1; j = j + 2) 
			begin
				if ((wt_array[gi][j] < wt_array[gi][j+1]) || (wt_array[gi][j] == wt_array[gi][j+1] && ch_array[gi][j] < ch_array[gi][j+1])) 
				begin // Right is bigger (Swap)
					ch_array[gi+1][j]   = ch_array[gi][j+1];
					wt_array[gi+1][j]   = wt_array[gi][j+1];
					ch_array[gi+1][j+1] = ch_array[gi][j];
					wt_array[gi+1][j+1] = wt_array[gi][j];
				end
			end
		end
	end
	
	//output
	for (gi = 0; gi < IP_WIDTH; gi = gi + 1)
	begin : output_assign
		assign OUT_character[(IP_WIDTH-gi)*4-1 -: 4] = ch_array[IP_WIDTH][gi];
		
	end
endgenerate


endmodule