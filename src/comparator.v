// =============================================================
// Dual-Mode Comparator (Shared Hardware)
// mode = 1 : Single 64-bit compare
// mode = 0 : Two independent 32-bit compares
//
// Outputs per mode:
//  mode=1 -> eqA, sltA, ultA correspond to full 64-bit result
//  mode=0 -> eqA/sltA/ultA = lower 32-bit comparison
//             eqB/sltB/ultB = upper 32-bit comparison
// =============================================================

module comparator64 (
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire        mode,     // 1 = unified, 0 = split

    output wire eqA,             // lower or full
    output wire sltA,            // signed less than (lower or full)
    output wire ultA,            // unsigned less than (lower or full)

    output wire eqB,             // upper
    output wire sltB,
    output wire ultB 
);

    // Split inputs into 32-bit halves
    wire [31:0] a_low  = a[31:0];
    wire [31:0] b_low  = b[31:0];
    wire [31:0] a_high = a[63:32];
    wire [31:0] b_high = b[63:32];

    // Reinterpret as signed inputs
    wire signed [63:0]  a_signed64  = a;
    wire signed [63:0]  b_signed64  = b;
    wire signed [31:0]  a_signed_lo = a_low;
    wire signed [31:0]  b_signed_lo = b_low;
    wire signed [31:0]  a_signed_hi = a_high;
    wire signed [31:0]  b_signed_hi = b_high;

    // -------------------------------------------------------------
    // Full 64-bit results
    // -------------------------------------------------------------
    wire eq64  = (a == b);
    wire slt64 = (a_signed64 < b_signed64);
    wire ult64 = (a < b);

    // -------------------------------------------------------------
    // Lower 32-bit results
    // -------------------------------------------------------------
    wire eq_lo  = (a_low  == b_low);
    wire slt_lo = (a_signed_lo < b_signed_lo);
    wire ult_lo = (a_low  <  b_low);

    // -------------------------------------------------------------
    // Upper 32-bit results
    // -------------------------------------------------------------
    wire eq_hi  = (a_high  == b_high);
    wire slt_hi = (a_signed_hi < b_signed_hi);
    wire ult_hi = (a_high  <  b_high);

    // -------------------------------------------------------------
    // Mode-based output selection
    // -------------------------------------------------------------
    assign eqA  = mode ? eq64  : eq_lo;
    assign sltA = mode ? slt64 : slt_lo;
    assign ultA = mode ? ult64 : ult_lo;

    assign eqB  = mode ? 1'b0 : eq_hi;
    assign sltB = mode ? 1'b0 : slt_hi;
    assign ultB = mode ? 1'b0 : ult_hi;

endmodule

