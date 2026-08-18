`default_nettype none

module alu_tb;

    reg  [31:0] a, b;
    reg  [3:0]  alusel;
    wire [31:0] result;
    wire        zero;

    alu #(.W(32)) dut (
        .a(a), .b(b), .alusel(alusel), .result(result), .zero(zero)
    );

    integer errors = 0;
    integer i;

    task check_alu;
        input [3:0]  sel;
        input [31:0] exp;
        begin
            #1;
            if (result !== exp) begin
                $display("FAIL: a=%h b=%h sel=%b got=%h exp=%h", a, b, sel, result, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // AND
        a = 32'hFFFF0000; b = 32'h00FF00FF; alusel = 4'b0000; check_alu(4'b0000, 32'h00FF0000);
        // OR
        a = 32'hF0F00000; b = 32'h0F0F0000; alusel = 4'b0001; check_alu(4'b0001, 32'hFFFF0000);
        // ADD (carry out of top bit wraps in 32-bit)
        a = 32'hFFFFFFFF; b = 32'h00000001; alusel = 4'b0010; check_alu(4'b0010, 32'h00000000);
        a = 32'h00000005; b = 32'h00000007; alusel = 4'b0010; check_alu(4'b0010, 32'h0000000C);
        // SUB
        a = 32'h00000007; b = 32'h00000005; alusel = 4'b0110; check_alu(4'b0110, 32'h00000002);
        a = 32'h00000005; b = 32'h00000007; alusel = 4'b0110; check_alu(4'b0110, 32'hFFFFFFFE);
        // SLT signed
        a = 32'h00000005; b = 32'h00000007; alusel = 4'b0111; check_alu(4'b0111, 32'h00000001); // 5 < 7
        a = 32'hFFFFFFFF; b = 32'h00000000; alusel = 4'b0111; check_alu(4'b0111, 32'h00000001); // -1 < 0
        a = 32'h00000000; b = 32'h00000000; alusel = 4'b0111; check_alu(4'b0111, 32'h00000000); // 0 < 0 false

        // Zero flag checks
        a = 32'h00000005; b = 32'h00000007; alusel = 4'b0110;
        #1;
        if (zero !== 0) begin $display("FAIL: zero should be 0 for 5-7"); errors = errors + 1; end
        a = 32'h00000005; b = 32'h00000005; alusel = 4'b0110;
        #1;
        if (zero !== 1) begin $display("FAIL: zero should be 1 for 5-5"); errors = errors + 1; end

        if (errors == 0) $display("PASS: ALU %0d tests OK", i);
        else             $display("FAIL: ALU had %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
