// ============================================================
// 64-bit Register File with Split/Unified Mode
// ------------------------------------------------------------
// mode = 0 → Split mode: two 32-bit halves act independently
// mode = 1 → Unified mode: full 64-bit register operations
// ------------------------------------------------------------
// Features:
// - x0 is hardwired to zero
// - Simultaneous writes allowed in split mode
// ============================================================

module register_file (
    input  wire        clk,
    input  wire        mode,        // 0 = split, 1 = unified
    input  wire        write_enA,
    input  wire        write_enB,
    input  wire [4:0]  rdA,
    input  wire [4:0]  rdB,
    input  wire [63:0] write_data,  // unified 64-bit data
    input  wire [4:0]  rs1A,
    input  wire [4:0]  rs2A,
    input  wire [4:0]  rs1B,
    input  wire [4:0]  rs2B,
    output wire [63:0] read_dataA1,
    output wire [63:0] read_dataA2,
    output wire [63:0] read_dataB1,
    output wire [63:0] read_dataB2
);

    reg [63:0] regfile [0:31];
    integer i;

    // Hardwire x0 to zero
    always @(posedge clk) begin
        regfile[0] <= 64'b0;

        if (!mode) begin
            // Split mode: A & B act independently on lower/upper halves
            if (write_enA && rdA != 5'd0)
                regfile[rdA][31:0] <= write_data[31:0];
            if (write_enB && rdB != 5'd0)
                regfile[rdB][63:32] <= write_data[63:32];
        end else begin
            // Unified 64-bit write
            if (write_enA && rdA != 5'd0)
                regfile[rdA] <= write_data;
        end
    end

    // Continuous reads
    assign read_dataA1 = regfile[rs1A];
    assign read_dataA2 = regfile[rs2A];
    assign read_dataB1 = regfile[rs1B];
    assign read_dataB2 = regfile[rs2B];

endmodule
