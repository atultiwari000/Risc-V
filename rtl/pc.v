`default_nettype none

// Program counter: holds the address of the instruction to fetch.
// en=0 freezes the PC (stalls); async active-low reset to 0.
module pc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] next_pc,
    output reg  [31:0] q
);
    initial q = 32'h0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 32'h0;
        else if (en)
            q <= next_pc;
    end
endmodule

// Generic pipeline register with enable and synchronous clear.
module pipe_reg #(
    parameter W = 32
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        clr,
    input  wire [W-1:0] d,
    output reg  [W-1:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= {W{1'b0}};
        else if (clr)
            q <= {W{1'b0}};
        else if (en)
            q <= d;
    end
endmodule

`default_nettype wire
