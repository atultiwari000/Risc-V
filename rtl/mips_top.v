`default_nettype none

// 5-stage pipelined MIPS datapath (IF / ID / EX / MEM / WB).
// This is an intentionally incomplete teaching version. Basic sequential
// arithmetic is wired through the pipeline, while forwarding, memory side
// effects, and control-flow recovery are reserved for later work.
module mips_top #(
    parameter IMEM_DEPTH = 256,
    parameter IMEM_AW    = 8,
    parameter DMEM_DEPTH = 256,
    parameter DMEM_AW    = 8,
    parameter string IMEM_FILE = "program.hex",
    parameter string DMEM_FILE = ""
) (
    input  wire clk,
    input  wire rst_n,
    output wire [31:0] dbg_pc
);

    // ============================== interconnect ==============================
    wire [31:0] pc_q;
    wire [31:0] pc_plus4 = pc_q + 32'd4;
    wire [31:0] instr;             // instruction memory output
    wire [31:0] mem_q;             // data memory output
    wire [31:0] npc;
    wire [31:0] branch_target;
    wire [31:0] jump_target;

    // ============================== hazard unit ===============================
    // The hazard interface is present, but its behavior is not connected yet.
    wire        stall      = 1'b0;
    wire        flush_ifid = 1'b0;
    wire        flush_ide  = 1'b0;

    // ============================== pipeline enable ===========================
    wire pip_en = ~stall;

    // ============================== program counter ===========================
    reg  [31:0] pc_d1;             // PC one step in the past -> pc+4 of fetched instr

    pc u_pc (
        .clk(clk), .rst_n(rst_n), .en(pip_en), .next_pc(npc), .q(pc_q)
    );
    assign dbg_pc = pc_q;

    // ============================== instruction memory ========================
    bram #(.DEPTH(IMEM_DEPTH), .AW(IMEM_AW), .INIT(IMEM_FILE)) u_imem (
        .clk(clk), .we(1'b0), .addr(pc_q[IMEM_AW+1:2]), .wdata(32'b0), .q(instr)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_d1 <= 32'h0;
        else        pc_d1 <= pc_q;
    end

    // ============================== IF/ID =====================================
    reg [31:0] instr_ifid;
    reg [31:0] pc4_ifid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_ifid <= 32'h0;
            pc4_ifid   <= 32'h0;
        end else if (flush_ifid) begin
            instr_ifid <= 32'h0;
            pc4_ifid   <= 32'h0;
        end else if (pip_en) begin
            instr_ifid <= instr;
            pc4_ifid   <= pc_d1;
        end
    end

    // ============================== ID ========================================
    wire [5:0]  op   = instr_ifid[31:26];
    wire [4:0]  rs   = instr_ifid[25:21];
    wire [4:0]  rt   = instr_ifid[20:16];
    wire [4:0]  rd   = instr_ifid[15:11];

    wire        c_regdst, c_alusrc, c_memtoreg, c_regwrite, c_memread, c_memwrite;
    wire        c_branch, c_bne, c_jump;
    wire [1:0]  c_aluop;

    control u_ctrl (
        .opcode(op), .regdst(c_regdst), .alusrc(c_alusrc), .memtoreg(c_memtoreg),
        .regwrite(c_regwrite), .memread(c_memread), .memwrite(c_memwrite),
        .branch(c_branch), .bne(c_bne), .jump(c_jump), .aluop(c_aluop)
    );

    wire [31:0] rd1, rd2;
    reg        wb_regwrite;
    reg        wb_memtoreg;
    reg [31:0] wb_data;
    reg [4:0]  wb_rd;

    regfile u_rf (
        .clk(clk), .regwrite(wb_regwrite), .raddr1(rs), .raddr2(rt),
        .waddr(wb_rd), .wdata(wb_data), .rdata1(rd1), .rdata2(rd2)
    );

    wire [31:0] imm_sext;
    sign_extend u_sext (.in(instr_ifid[15:0]), .out(imm_sext));

    wire [31:0] pc4_ide_w  = pc4_ifid;
    wire [31:0] rd1_ide_w  = rd1;
    wire [31:0] rd2_ide_w  = rd2;
    wire [31:0] imm_ide_w  = imm_sext;
    wire [4:0]  rs_ide_w   = rs;
    wire [4:0]  rt_ide_w   = rt;
    wire [4:0]  rd_ide_w   = rd;
    wire [25:0] jpre_ide_w = instr_ifid[25:0];
    wire [10:0] ctrl_ide_w = {c_regdst, c_alusrc, c_memtoreg, c_regwrite,
                              c_memread, c_memwrite, c_branch, c_bne,
                              c_jump, c_aluop};

    // ============================== ID/EX =====================================
    reg [10:0]  ctrl_ide;
    reg [31:0]  pc4_ide;
    reg [31:0]  rd1_ide;
    reg [31:0]  rd2_ide;
    reg [31:0]  imm_ide;
    reg [4:0]   rs_ide;
    reg [4:0]   rt_ide;
    reg [4:0]   rd_ide;
    reg [25:0]  jpre_ide;
    reg [5:0]   funct_ide;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_ide <= 11'b0; pc4_ide <= 32'h0; rd1_ide <= 32'h0; rd2_ide <= 32'h0;
            imm_ide  <= 32'h0; rs_ide <= 5'h0;   rt_ide  <= 5'h0;  rd_ide <= 5'h0;
            jpre_ide <= 26'h0; funct_ide <= 6'h0;
        end else if (flush_ide) begin
            ctrl_ide <= 11'b0; pc4_ide <= 32'h0; rd1_ide <= 32'h0; rd2_ide <= 32'h0;
            imm_ide  <= 32'h0; rs_ide <= 5'h0;   rt_ide  <= 5'h0;  rd_ide <= 5'h0;
            jpre_ide <= 26'h0; funct_ide <= 6'h0;
        end else if (pip_en) begin
            ctrl_ide <= ctrl_ide_w;
            pc4_ide  <= pc4_ide_w;
            rd1_ide  <= rd1_ide_w;
            rd2_ide  <= rd2_ide_w;
            imm_ide  <= imm_ide_w;
            rs_ide   <= rs_ide_w;
            rt_ide   <= rt_ide_w;
            rd_ide   <= rd_ide_w;
            jpre_ide <= jpre_ide_w;
            funct_ide <= instr_ifid[5:0];
        end
    end

    // ============================== EX ========================================
    // taken-branch/jump propagation: only the EX stage computes targets
    // (branch through the ALU, jump from the ID/EX jump immediate)
    assign branch_target = pc4_ide + {imm_ide[29:0], 2'b00};
    assign jump_target   = {pc4_ide[31:28], jpre_ide, 2'b00};

    // TODO: add EX/MEM, MEM/WB, and load-result forwarding.
    // Without it, dependent instructions intentionally observe stale operands.
    wire [31:0] alu_a = rd1_ide;
    wire [31:0] alu_b_raw = rd2_ide;

    wire [31:0] alu_b = ctrl_ide[9] ? imm_ide : alu_b_raw;
    wire [3:0]  alusel;
    alu_control u_ac (.aluop(ctrl_ide[1:0]), .funct(funct_ide), .alusel(alusel));

    wire [31:0] alu_out;
    wire        alu_zero;
    alu #(.W(32)) u_alu (.a(alu_a), .b(alu_b), .alusel(alusel), .result(alu_out), .zero(alu_zero));

    wire [4:0]  wa = ctrl_ide[10] ? rd_ide : rt_ide;   // RegDst

    // Branch and jump recovery is intentionally disconnected for now.
    wire taken = 1'b0;
    assign npc = pc_plus4;

    // ============================== EX/MEM ====================================
    reg         exm_memread, exm_memwrite, exm_regwrite, exm_memtoreg;
    reg  [31:0] exm_aluout;
    reg  [31:0] exm_rd2;
    reg  [4:0]  exm_rd;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exm_memread <= 1'b0; exm_memwrite <= 1'b0; exm_regwrite <= 1'b0;
            exm_memtoreg <= 1'b0; exm_aluout <= 32'h0; exm_rd2 <= 32'h0; exm_rd <= 5'h0;
        end else if (pip_en) begin
            // Memory controls are held low until the BRAM timing is finished.
            exm_memread  <= 1'b0;
            exm_memwrite <= 1'b0;
            exm_regwrite <= ctrl_ide[7];
            exm_memtoreg <= ctrl_ide[8];
            exm_aluout   <= alu_out;
            exm_rd2      <= alu_b_raw;        // store data = forwarded/second operand
            exm_rd       <= wa;
        end
    end

    // ============================== MEM =======================================
    bram #(.DEPTH(DMEM_DEPTH), .AW(DMEM_AW), .INIT(DMEM_FILE)) u_dmem (
        .clk(clk), .we(exm_memwrite),
        .addr(exm_aluout[DMEM_AW+1:2]), .wdata(exm_rd2), .q(mem_q)
    );

    // ============================== MEM/WB ====================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_regwrite <= 1'b0; wb_memtoreg <= 1'b0; wb_data <= 32'h0; wb_rd <= 5'h0;
        end else if (pip_en) begin
            wb_regwrite <= exm_regwrite;
            wb_memtoreg <= 1'b0;
            wb_data     <= exm_aluout;
            wb_rd       <= exm_rd;
        end
    end

    // ============================== hazard ====================================
    // Placeholder signals keep future interfaces visible without pretending
    // that the difficult behavior is implemented.
    wire [7:0] future_work = 8'hA5;
    wire       unused_probe = future_work[0] & 1'b0;

endmodule

`default_nettype wire
