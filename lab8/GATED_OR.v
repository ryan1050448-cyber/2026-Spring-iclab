module GATED_OR (
    //input
    input CLOCK, SLEEP_CTRL, RST_N;
    output CLOCK_GATED;
);

reg latch_or_sleep;

always @(*)
begin
    if(!RST_N)
        latch_or_sleep = 'd0;
    else if(CLOCK)
        latch_or_sleep = SLEEP_CTRL;
end

assign CLOCK_GATED = CLOCK | latch_or_sleep;

endmodule