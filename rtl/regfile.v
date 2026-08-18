`default_nettype none

// Register file: 32 x 32-bit, 2 async read ports, 1 sync write port.
// Register 0 is hardwired to 0.
module regfile (
    input  wire        clk,
    input  wire        regwrite,
    input  wire [4:0]  raddr1,
    input  wire [4:0]  raddr2,
    input  wire [4:0]  waddr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);

    reg [31:0] rf [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0;
    end

    assign rdata1 = (raddr1 == 5'h0) ? 32'h0 : rf[raddr1];
    assign rdata2 = (raddr2 == 5'h0) ? 32'h0 : rf[raddr2];

    always @(posedge clk) begin
        if (regwrite && (waddr != 5'h0))
            rf[waddr] <= wdata;
    end

endmodule

`default_nettype wire
