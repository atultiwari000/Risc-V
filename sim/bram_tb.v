`default_nettype none

module bram_tb;

    reg clk = 0;
    reg we;
    reg [3:0] addr;
    reg [31:0] wdata;
    wire [31:0] q;

    bram #(.DEPTH(16), .AW(4)) dut (
        .clk(clk), .we(we), .addr(addr), .wdata(wdata), .q(q)
    );

    always #5 clk = ~clk;

    integer errors = 0;

    // Set stimulus, then wait one full cycle (advance past the edge we already
    // consumed, so inputs are stable well before the next posedge).
    task drive;
        input [3:0]  a;
        input        w;
        input [31:0] d;
        begin
            addr = a; we = w; wdata = d;
            #1;
        end
    endtask

    initial begin
        drive(4'h0, 1'b0, 32'h0);
        #1;

        // Write 0xA to word 1
        drive(4'h1, 1'b1, 32'h0000000A);
        @(posedge clk);
        #1;

        // Immediately after write, read address 1: NOT valid yet (latency 2).
        drive(4'h1, 1'b0, 32'h0);
        #1; // cycle A: addr latched into addr_r at next edge
        if (q !== 32'h00000000) begin
            $display("FAIL: data visible too early q=%h", q);
            errors = errors + 1;
        end
        @(posedge clk); // addr_r <= 1
        #1;
        @(posedge clk); // q <= mem[1] = 0xA
        #1;
        if (q !== 32'h0000000A) begin
            $display("FAIL: latency-2 read got=%h exp=%h", q, 32'h0000000A);
            errors = errors + 1;
        end

        // Read should persist while address is unchanged.
        #10;
        if (q !== 32'h0000000A) begin
            $display("FAIL: q did not hold value q=%h", q);
            errors = errors + 1;
        end

        // Read back a just-written word: write C to 3, then read 3.
        drive(4'h3, 1'b1, 32'hCAFEBABE);
        @(posedge clk); #1;
        drive(4'h3, 1'b0, 32'h0);
        @(posedge clk); #1; // addr_r <= 3
        @(posedge clk); #1; // q <= mem[3]
        if (q !== 32'hCAFEBABE) begin
            $display("FAIL: read-after-write got=%h exp=%h", q, 32'hCAFEBABE);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: bram all OK");
        else             $display("FAIL: bram %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
