`default_nettype none

// Main control: decodes opcode [31:26] into control signals.
// Don't-care outputs are tied to 0 for clean waveforms.
module control (
    input  wire [5:0] opcode,
    output reg         regdst,
    output reg         alusrc,
    output reg         memtoreg,
    output reg         regwrite,
    output reg         memread,
    output reg         memwrite,
    output reg         branch,
    output reg         bne,
    output reg         jump,
    output reg  [1:0]  aluop
);

    always @* begin
        regdst   = 1'b0;
        alusrc   = 1'b0;
        memtoreg = 1'b0;
        regwrite = 1'b0;
        memread  = 1'b0;
        memwrite = 1'b0;
        branch   = 1'b0;
        bne      = 1'b0;
        jump     = 1'b0;
        aluop    = 2'b00;
        casez (opcode)
            6'b000000: begin // R-type
                regdst   = 1'b1;
                regwrite = 1'b1;
                aluop    = 2'b10;
            end
            6'b100011: begin // lw
                alusrc   = 1'b1;
                memtoreg = 1'b1;
                regwrite = 1'b1;
                memread  = 1'b1;
            end
            6'b101011: begin // sw
                alusrc   = 1'b1;
                memwrite = 1'b1;
            end
            6'b000100: begin // beq
                branch = 1'b1;
                aluop  = 2'b01;
            end
            6'b000101: begin // bne
                bne    = 1'b1;
                aluop  = 2'b01;
            end
            6'b001000: begin // addi
                alusrc   = 1'b1;
                regwrite = 1'b1;
                aluop    = 2'b11;
            end
            6'b000010: begin // j
                jump = 1'b1;
            end
            default: ; // all zeros
        endcase
    end

endmodule

`default_nettype wire
