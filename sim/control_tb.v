`default_nettype none

module control_tb;

    reg [5:0] opcode;
    wire regdst, alusrc, memtoreg, regwrite, memread, memwrite, branch, bne, jump;
    wire [1:0] aluop;

    control dut (
        .opcode(opcode), .regdst(regdst), .alusrc(alusrc), .memtoreg(memtoreg),
        .regwrite(regwrite), .memread(memread), .memwrite(memwrite),
        .branch(branch), .bne(bne), .jump(jump), .aluop(aluop)
    );

    integer errors = 0;

    task check;
        input [10:0] exp; // {jump,bne,branch,memwrite,memread,regwrite,memtoreg,alusrc,regdst,aluop[1:0]}
        begin
            #1;
            if ({jump,bne,branch,memwrite,memread,regwrite,memtoreg,alusrc,regdst,aluop} !== exp) begin
                $display("FAIL: opcode=%b got={%b} exp=%b", opcode,
                         {jump,bne,branch,memwrite,memread,regwrite,memtoreg,alusrc,regdst,aluop}, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // R-type: regdst=1, regwrite=1, aluop=10
        opcode = 6'b000000; check(11'b0_0_0_0_0_1_0_0_1_10);
        // lw: alusrc=1, memtoreg=1, regwrite=1, memread=1, aluop=00
        opcode = 6'b100011; check(11'b0_0_0_0_1_1_1_1_0_00);
        // sw: alusrc=1, memwrite=1, aluop=00
        opcode = 6'b101011; check(11'b0_0_0_1_0_0_0_1_0_00);
        // beq: branch=1, aluop=01
        opcode = 6'b000100; check(11'b0_0_1_0_0_0_0_0_0_01);
        // bne: bne=1, aluop=01
        opcode = 6'b000101; check(11'b0_1_0_0_0_0_0_0_0_01);
        // addi: alusrc=1, regwrite=1, aluop=11
        opcode = 6'b001000; check(11'b0_0_0_0_0_1_0_1_0_11);
        // j: jump=1
        opcode = 6'b000010; check(11'b1_0_0_0_0_0_0_0_0_00);

        if (errors == 0) $display("PASS: control all OK");
        else             $display("FAIL: control %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
