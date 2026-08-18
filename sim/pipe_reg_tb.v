`default_nettype none

module pipe_reg_tb;

    reg clk = 0;
    reg rst_n = 0;
    reg en;
    reg clr;
    reg [7:0] d;
    wire [7:0] q;

    pipe_reg #(.W(8)) dut (.clk(clk), .rst_n(rst_n), .en(en), .clr(clr), .d(d), .q(q));

    always #5 clk = ~clk;

    integer errors = 0;

    initial begin
        en = 0; clr = 0; d = 8'h0;
        rst_n = 0;
        @(posedge clk); #1;
        if (q !== 8'h0) begin $display("FAIL reset"); errors = errors + 1; end

        rst_n = 1;
        en = 1; d = 8'hAA;
        @(posedge clk); #1;
        if (q !== 8'hAA) begin $display("FAIL load %h", q); errors = errors + 1; end

        // en=0 -> hold
        en = 0; d = 8'h55;
        @(posedge clk); #1;
        if (q !== 8'hAA) begin $display("FAIL hold"); errors = errors + 1; end

        // clr -> 0
        en = 1; clr = 1; d = 8'hFF;
        @(posedge clk); #1;
        if (q !== 8'h00) begin $display("FAIL clear %h", q); errors = errors + 1; end

        // reset low -> 0
        clr = 0;
        rst_n = 0;
        #1;
        if (q !== 8'h00) begin $display("FAIL rst"); errors = errors + 1; end

        if (errors == 0) $display("PASS: pipe_reg all OK");
        else             $display("FAIL: pipe_reg %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
