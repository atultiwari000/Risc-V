`default_nettype none

// Parameterized synchronous RAM with 2-clock-cycle read latency,
// modeled after FPGA BRAM (address register + output register).
//
// Read: address stable at input on edge N -> data valid at output from edge N+2.
// Write: synchronous, single-cycle (data captured on edge with we high).
module bram #(
    parameter DEPTH = 1024,  // number of 32-bit words
    parameter AW    = 10,    // log2(DEPTH)
    parameter INIT  = ""     // optional $readmemh file
) (
    input  wire        clk,
    input  wire        we,
    input  wire [AW-1:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] q
);

    reg [31:0] mem [0:DEPTH-1];
    reg [AW-1:0] addr_r;

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'h0;
        if (INIT != "") $readmemh(INIT, mem);
        addr_r = {AW{1'b0}};
        q = 32'h0;
    end

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        addr_r <= addr;
        q      <= mem[addr_r];
    end

endmodule

`default_nettype wire
