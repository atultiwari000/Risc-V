`default_nettype none

// ALU control: translates ALUOp (from main control) + funct (R-type) to ALUSel.
// ALUOp[1:0]
//   00 : lw/sw      -> add
//   01 : beq/bne    -> sub
//   10 : R-type     -> decode funct
//   11 : addi       -> add
module alu_control (
    input  wire [1:0] aluop,
    input  wire [5:0] funct,
    output reg  [3:0] alusel
);

    localparam ADD = 4'b0010, SUB = 4'b0110, AND = 4'b0000, OR = 4'b0001, SLT = 4'b0111;

    always @* begin
        case (aluop)
            2'b00:   alusel = ADD;
            2'b01:   alusel = SUB;
            2'b11:   alusel = ADD;
            2'b10:   case (funct)
                        6'b100000: alusel = ADD; // add
                        6'b100010: alusel = SUB; // sub
                        6'b100100: alusel = AND; // and
                        6'b100101: alusel = OR;  // or
                        6'b101010: alusel = SLT; // slt
                        default:   alusel = ADD;
                     endcase
            default: alusel = ADD;
        endcase
    end

endmodule

`default_nettype wire
