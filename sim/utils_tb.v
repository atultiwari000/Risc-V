`default_nettype none

module utils_tb;

    // --- sign_extend ---
    reg [15:0] simm;
    wire [31:0] sext;
    sign_extend u_sext (.in(simm), .out(sext));

    // --- mux2 (4-bit + 32-bit) ---
    reg [3:0]  m0, m1;
    reg        msel;
    wire [3:0] mouts;
    mux2 #(.W(4)) u_mux4 (.d0(m0), .d1(m1), .s(msel), .y(mouts));
    reg [31:0] a0, a1;
    reg        asel;
    wire [31:0] aout;
    mux2 #(.W(32)) u_mux32 (.d0(a0), .d1(a1), .s(asel), .y(aout));

    // --- adder ---
    reg [31:0] aa, ab;
    wire [31:0] asum;
    adder u_add (.a(aa), .b(ab), .y(asum));

    // --- shift_left2 ---
    reg [31:0] shin;
    wire [31:0] shout;
    shift_left2 u_shl (.in(shin), .out(shout));

    integer errors = 0;

    initial begin
        // sign_extend
        simm = 16'h7FFF; #1;
        if (sext !== 32'h00007FFF) begin $display("FAIL sext positive"); errors = errors + 1; end
        simm = 16'h8000; #1;
        if (sext !== 32'hFFFF8000) begin $display("FAIL sext negative"); errors = errors + 1; end
        simm = 16'hFFFF; #1;
        if (sext !== 32'hFFFFFFFF) begin $display("FAIL sext -1"); errors = errors + 1; end

        // mux 4-bit
        m0 = 4'h5; m1 = 4'hA; msel = 1'b0; #1;
        if (mouts !== 4'h5) begin $display("FAIL mux4 sel0"); errors = errors + 1; end
        msel = 1'b1; #1;
        if (mouts !== 4'hA) begin $display("FAIL mux4 sel1"); errors = errors + 1; end

        // mux 32-bit
        a0 = 32'h00000000; a1 = 32'hFFFFFFFF; asel = 1'b0; #1;
        if (aout !== 32'h0) begin $display("FAIL mux32 sel0"); errors = errors + 1; end
        asel = 1'b1; #1;
        if (aout !== 32'hFFFFFFFF) begin $display("FAIL mux32 sel1"); errors = errors + 1; end

        // adder
        aa = 32'h00000004; ab = 32'h00000004; #1;
        if (asum !== 32'h00000008) begin $display("FAIL add 4+4"); errors = errors + 1; end
        aa = 32'hFFFFFFFF; ab = 32'h00000001; #1;
        if (asum !== 32'h00000000) begin $display("FAIL add wrap"); errors = errors + 1; end

        // shift_left2
        shin = 32'h00000004; #1;
        if (shout !== 32'h00000010) begin $display("FAIL shl 4<<2"); errors = errors + 1; end
        shin = 32'h80000000; #1;
        if (shout !== 32'h00000000) begin $display("FAIL shl overflow"); errors = errors + 1; end

        if (errors == 0) $display("PASS: utils all OK");
        else             $display("FAIL: utils %0d errors", errors);
        $finish;
    end

endmodule

`default_nettype wire
