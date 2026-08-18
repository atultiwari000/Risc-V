`default_nettype none

module pc_tb;

    reg clk = 0;
    reg rst_n = 0;
    reg en;
    reg [31:0] next_pc;
    wire [31:0] pcq;

    pc dut_pc (.clk(clk), .rst_n(rst_n), .en(en), .next_pc(next_pc), .q(pcq));

    always #5 clk = ~clk;

    integer errors = 0;

    task checkpc;
        input [31:0] exp;
        begin
            if (pcq !== exp) begin
                $display("FAIL: pc got=%h exp=%h", pcq, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        en = 0; next_pc = 32'h0;
        rst_n = 0;                    // real reset pulse (transition), not init-only
        @(posedge clk); #1;
        checkpc(32'h00000000);
        rst_n = 1; en = 1;
        next_pc = 32'h00000004;
        @(posedge clk); #1;
        checkpc(32'h00000004);
        next_pc = 32'h00000008;
        @(posedge clk); #1;
        checkpc(32'h00000008);

        // en=0: freeze
        next_pc = 32'hDEADBEEF; en = 0;
        @(posedge clk); #1;
        checkpc(32'h00000008);

        // en=1: resumes
        en = 1; next_pc = 32'h0000000C;
        @(posedge clk); #1;
        checkpc(32'h0000000C);

        // async reset
        rst_n = 0;
        #1;
        checkpc(32'h0);

        if (errors == 0) $display("PASS: pc all OK");
        else             $display("FAIL: pc %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
