`default_nettype none
// Parameterized adder
module adder #(
    parameter W = 32
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] y
);
    assign y = a + b;
endmodule
`default_nettype wire
