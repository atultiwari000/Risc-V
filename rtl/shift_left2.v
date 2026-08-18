`default_nettype none
// Left shift by 2 (for branch offsets and jump target)
module shift_left2 #(
    parameter W = 32
) (
    input  wire [W-1:0] in,
    output wire [W-1:0] out
);
    assign out = in << 2;
endmodule
`default_nettype wire
