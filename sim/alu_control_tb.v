`default_nettype none

module alu_control_tb;

    reg [1:0] aluop;
    reg [5:0] funct;
    wire [3:0] alusel;

    alu_control dut (.aluop(aluop), .funct(funct), .alusel(alusel));

    integer errors = 0;

    task check;
        input [3:0] exp;
        begin
            #1;
            if (alusel !== exp) begin
                $display("FAIL: aluop=%b funct=%b got=%b exp=%b", aluop, funct, alusel, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // lw/sw -> add
        aluop = 2'b00; funct = 6'bx;     check(4'b0010);
        // beq/bne -> sub
        aluop = 2'b01; funct = 6'bx;     check(4'b0110);
        // addi -> add
        aluop = 2'b11; funct = 6'bx;     check(4'b0010);
        // R-type
        aluop = 2'b10;
        funct = 6'b100000; check(4'b0010); // add
        funct = 6'b100010; check(4'b0110); // sub
        funct = 6'b100100; check(4'b0000); // and
        funct = 6'b100101; check(4'b0001); // or
        funct = 6'b101010; check(4'b0111); // slt

        if (errors == 0) $display("PASS: alu_control all OK");
        else             $display("FAIL: alu_control %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
