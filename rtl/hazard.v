`default_nettype none

// Hazard unit.
//
// Loads: the data BRAM has 2-cycle read latency (addr_r, q registers), so a
// load must stay 2 full windows in EX/MEM before its data lands in MEM/WB.
// The counter is armed from ID/EX.memread at the edge the load is transferred
// to EX/MEM and runs independently of the stall, so it terminates after 2
// windows even though the load itself is frozen in EX/MEM during the stall.
// A consumer immediately behind the load is served by the data-memory bypass
// (mem_q), so no separate load-use detector is needed.
//
// Stores: the write completes at the first window in EX/MEM, no stall needed.
//
// Branches/jumps: taken in EX redirects the PC and must flush the stale
// fetches still in the BRAM pipe (PC -> addr_r -> q -> IF/ID).  With a taken
// branch resolved in window W_R, the stale instructions are:
//   I(B+4)  waiting in IF/ID            -> killed when EX/MEM captures (edge R+1)
//   I(B+8)  on the imem output          -> would enter IF/ID at edge R+1
//   I(B+12) already addressed in BRAM   -> would enter IF/ID at edge R+2
//   I(B+16) being addressed in BRAM     -> would enter IF/ID at edge R+3
// The first is stopped by a combinational flush during W_R; the next three by
// the registered delay chain (fl_armed, fl_dly).  The first valid target fetch
// I(T) arrives at edge R+4, which the 2-deep chain leaves untouched.
module hazard (
    input  wire clk,
    input  wire rst_n,
    input  wire ide_memread,   // ID/EX stage: is a load
    input  wire taken,         // branch/jump taken (EX)
    output reg  stall,
    output reg  flush_ifid,
    output reg  flush_ide
);

    reg [1:0] sc;        // load-stall countdown (free-running)
    reg       fl_armed;  // qualified-armed taken (one window)
    reg       fl_dly;    // branch flush delay stage

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sc <= 2'b00;
        else if (ide_memread && (sc == 2'b00))
            sc <= 2'd2;          // load enters EX/MEM at this edge -> 2 stalls
        else if (sc != 2'b00)
            sc <= sc - 2'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fl_armed <= 1'b0;
        else
            fl_armed <= taken & ~stall;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fl_dly <= 1'b0;
        else
            fl_dly <= fl_armed;
    end

    assign stall = (sc != 2'b00);

    // combinational part kills I(B+4) while it is still in IF/ID and would
    // otherwise be captured into ID/EX and EX/MEM at edge R+1
    assign flush_ifid = (taken & ~stall) | fl_armed | fl_dly;
    assign flush_ide  = (taken & ~stall) | fl_armed;

endmodule

`default_nettype wire
