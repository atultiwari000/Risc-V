`default_nettype none
// 2:1 multiplexer, parameterized width
module mux2 #(
    parameter W = 32
) (
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire         s,
    output wire [W-1:0] y
);
    assign y = s ? d1 : d0;
endmodule
`default_nettype wire
