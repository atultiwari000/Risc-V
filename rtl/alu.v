`default_nettype none

// ALU: 32-bit arithmetic/logic unit.
// ALUSel: 4'b0000 = AND
//         4'b0001 = OR
//         4'b0010 = ADD
//         4'b0110 = SUB
//         4'b0111 = SLT (signed less-than -> 0 or 1)
module alu #(
    parameter W = 32
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    input  wire [3:0]   alusel,
    output reg  [W-1:0] result,
    output wire         zero
);

    always @* begin
        case (alusel)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b0111: result = {{(W-1){1'b0}}, ($signed(a) < $signed(b))};
            default: result = {W{1'bx}};
        endcase
    end

    assign zero = (result == {W{1'b0}});

endmodule

`default_nettype wire
