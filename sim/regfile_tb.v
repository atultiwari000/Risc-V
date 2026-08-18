`default_nettype none

module regfile_tb;

    reg clk = 0;
    reg regwrite;
    reg [4:0] raddr1, raddr2, waddr;
    reg [31:0] wdata;
    wire [31:0] rdata1, rdata2;

    regfile dut (.clk(clk), .regwrite(regwrite), .raddr1(raddr1), .raddr2(raddr2),
                 .waddr(waddr), .wdata(wdata), .rdata1(rdata1), .rdata2(rdata2));

    always #5 clk = ~clk;

    integer errors = 0;

    task check;
        input [31:0] got;
        input [31:0] exp;
        input [7:0]  msg;
        begin
            if (got !== exp) begin
                $display("FAIL: %s got=%h exp=%h", msg, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        regwrite = 0; raddr1 = 0; raddr2 = 0; waddr = 0; wdata = 0;
        #1;

        // reads of uninitialized regs = 0
        raddr1 = 5'd1; raddr2 = 5'd2;
        #1;
        check(rdata1, 32'h0, "r1 init");
        check(rdata2, 32'h0, "r2 init");

        // r0 always 0 even if written
        waddr = 5'd0; wdata = 32'hDEADBEEF; regwrite = 1;
        @(negedge clk); raddr1 = 5'd0; raddr2 = 5'd1;
        #1;
        check(rdata1, 32'h0, "r0 stays 0");

        // write to r3
        waddr = 5'd3; wdata = 32'hCAFEBABE; regwrite = 1;
        @(negedge clk);
        raddr1 = 5'd3;
        #1;
        check(rdata1, 32'hCAFEBABE, "r3 written");

        // write r7, read both ports simultaneously
        waddr = 5'd7; wdata = 32'h00000042; regwrite = 1;
        @(negedge clk);
        raddr1 = 5'd3; raddr2 = 5'd7;
        #1;
        check(rdata1, 32'hCAFEBABE, "r3 after r7 write");
        check(rdata2, 32'h00000042, "r7 written");

        // no write when regwrite=0
        waddr = 5'd8; wdata = 32'h11111111; regwrite = 0;
        @(negedge clk);
        raddr2 = 5'd8;
        #1;
        check(rdata2, 32'h0, "no write when regwrite=0");

        if (errors == 0) $display("PASS: regfile all OK");
        else             $display("FAIL: regfile %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
