// 32-bit structural barrel shifter (5-stage) - corrected and robust
module shift32 (
    input  wire [31:0] in,
    input  wire [4:0]  shamt,   // 0..31
    input  wire        dir,     // 0 = left, 1 = right
    input  wire        arith,   // valid only when dir==1
    output wire [31:0] out
);
    // 5 staged shifts: 1,2,4,8,16
    wire [31:0] stage [5:0];
    assign stage[0] = in;

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : gen_stage
            localparam integer SHIFT = (1 << i);
            wire [31:0] left_shift;
            wire [31:0] right_log;
            wire [31:0] right_arith;
            wire [31:0] stage_out;

            // left shift by constant SHIFT
            assign left_shift = stage[i] << SHIFT;

            // logical right by constant SHIFT
            assign right_log = stage[i] >> SHIFT;

            // arithmetic right by constant SHIFT (use signed arithmetic shift)
            // cast to signed, shift, then cast back (result is 32 bits)
            assign right_arith = $signed(stage[i]) >>> SHIFT;

            // choose direction/arithmetic
            assign stage_out = (dir == 1'b0) ? left_shift : (arith ? right_arith : right_log);

            // select whether to apply this stage (shamt[i] is 1 => apply)
            assign stage[i+1] = shamt[i] ? stage_out : stage[i];
        end
    endgenerate

    assign out = stage[5];
endmodule


// Top-level: two 32-bit blocks usable independently or combined as 64-bit unified
module shift64 (
    input  wire         mode_unified, // 1 = unified (64-bit), 0 = split (two independent 32-bit)
    // unified controls
    input  wire        uni_dir,      // 0 = left, 1 = right
    input  wire        uni_arith,    // only relevant when uni_dir==1
    input  wire [11:0] shift_amt,    // 0..63

    // split controls (per-half)
    input  wire         hi_dir,
    input  wire         hi_arith,
    input  wire         lo_dir,
    input  wire         lo_arith,

    input  wire [63:0]  in_bus,
    output wire [63:0]  out_bus
);
    // split inputs (correct widths)
    wire [4:0] lo_amt  = shift_amt[4:0];
    wire [4:0] hi_amt  = shift_amt[10:6];
    wire [5:0] uni_amt = shift_amt[5:0]; // 6 bits: [5] indicates >=32, [4:0] is k

    wire [31:0] in_hi = in_bus[63:32];
    wire [31:0] in_lo = in_bus[31:0];

    // unified helpers
    wire [4:0] uni_shift = uni_amt[4:0]; // k = 0..31 (or r = K-32 when uni_ge_32)
    wire       uni_ge_32 = uni_amt[5];  // 1 if K >= 32

    // choose shamt/controls depending on mode
    wire [4:0] shamt_lo = mode_unified ? uni_shift : lo_amt;
    wire [4:0] shamt_hi = mode_unified ? uni_shift : hi_amt;

    wire dir_lo = mode_unified ? uni_dir : lo_dir;
    wire dir_hi = mode_unified ? uni_dir : hi_dir;

    wire arith_lo = mode_unified ? uni_arith : lo_arith;
    wire arith_hi = mode_unified ? uni_arith : hi_arith;

    // instantiate lower 32-bit block
    wire [31:0] lo_shifter_out;
    wire [31:0] hi_shifter_out;

    shift32 u_lo32 (
        .in(in_lo),
        .shamt(shamt_lo),
        .dir(dir_lo),
        .arith(arith_lo),
        .out(lo_shifter_out)
    );

    shift32 u_hi32 (
        .in(in_hi),
        .shamt(shamt_hi),
        .dir(dir_hi),
        .arith(arith_hi),
        .out(hi_shifter_out)
    );

    // ----------------------------
    // Combine results for unified mode
    // ----------------------------
    // K = uni_amt (6 bits). If uni_ge_32==0 then K<32 and uni_shift==K (0..31).
    // If uni_ge_32==1 then K>=32 and r = K - 32 == uni_shift (0..31 for K=32..63).

    wire k_is_zero = (uni_shift == 5'd0) && ~uni_ge_32; // only true when unified K==0

    // ---- K < 32 case ----
    // Cross bits from low -> high (top k bits of in_lo), guarded to avoid shifting by 32.
    wire [31:0] lo_to_hi = (k_is_zero) ? 32'b0
                          : (uni_shift == 5'd0) ? 32'b0
                          : (in_lo >> (32 - uni_shift)); // evaluated only when uni_shift != 0

    // Bits from high -> low (when shifting right), guarded
   wire [31:0] hi_to_lo = (k_is_zero) ? 32'b0
                          : (uni_shift == 5'd0) ? 32'b0
                          : (in_hi << (32 - uni_shift));

    // left direction K<32:
    wire [31:0] left_lo_klt  = lo_shifter_out;                 // in_lo << k
    wire [31:0] left_hi_klt  = hi_shifter_out | lo_to_hi;     // (in_hi << k) | (in_lo >> (32-k))

    // right direction K<32:
    wire [31:0] right_lo_klt       = (k_is_zero) ? in_lo : ((in_lo >> uni_shift) | hi_to_lo);
    wire [31:0] right_hi_log_klt   = (k_is_zero) ? in_hi : (in_hi >> uni_shift);
    wire [31:0] right_hi_arith_klt = (k_is_zero) ? in_hi : ($signed(in_hi) >>> uni_shift);

    wire [31:0] uni_lo_klt32  = (uni_dir == 1'b0) ? left_lo_klt  : right_lo_klt;
    wire [31:0] uni_hi_klt32  = (uni_dir == 1'b0) ? left_hi_klt  : (uni_arith ? right_hi_arith_klt : right_hi_log_klt);

    // ---- K >= 32 case ----
    // r = K - 32 ; stored in uni_shift (0..31)
    wire [4:0] r = uni_shift;

    // LEFT, K>=32:
    // lower_out = 0
    // upper_out = in_lo << r   ; when r==0 (K==32) this becomes in_lo (correct)
    wire [31:0] left_lo_kge = 32'b0;
    wire [31:0] left_hi_kge = (r == 5'd0) ? in_lo : (in_lo << r);

    // LOGICAL RIGHT, K>=32:
    // lower_out = in_hi >> r   ; when r==0 (K==32) this becomes in_hi (correct)
    // upper_out = 0
    wire [31:0] right_lo_kge_log = (r == 5'd0) ? in_hi : (in_hi >> r);
    wire [31:0] right_hi_kge_log = 32'b0;

    // ARITH RIGHT, K>=32: (kept for non-arith-unified fallback)
    // lower_out = arithmetic_right(in_hi, r)
    // upper_out = sign replicate (all bits = MSB of 64-bit input)
    wire [31:0] right_lo_kge_arith = (r == 5'd0) ? in_hi : ($signed(in_hi) >>> r);
    wire [31:0] right_hi_kge_arith = {32{in_bus[63]}}; // sign replicate top bit of 64-bit input

    wire [31:0] uni_lo_kge32 = (uni_dir == 1'b0) ? left_lo_kge : (uni_arith ? right_lo_kge_arith : right_lo_kge_log);
    wire [31:0] uni_hi_kge32 = (uni_dir == 1'b0) ? left_hi_kge : (uni_arith ? right_hi_kge_arith : right_hi_kge_log);

    // Non-arithmetic unified results (existing logic covers both K<32 and K>=32)
    wire [31:0] unified_lo_nonarith = uni_ge_32 ? uni_lo_kge32 : uni_lo_klt32;
    wire [31:0] unified_hi_nonarith = uni_ge_32 ? uni_hi_kge32 : uni_hi_klt32;

    // ----------------------------
    // TRUE 64-bit arithmetic right (when unified & right & arithmetic)
    // ----------------------------
    // Compute a true signed 64-bit arithmetic shift and split it.
    // This guarantees correct behavior for all K (0..63), including K==63 -> all sign bits.
    wire signed [63:0] signed_in64 = $signed(in_bus);
    wire signed [63:0] shifted64_arith = signed_in64 >>> uni_amt; // uni_amt is 6 bits (0..63)

    // Final unified selection:
    // - If in unified mode AND performing a 64-bit arithmetic right shift, use the true 64-bit result.
    // - Otherwise use the (previous) non-arithmetic / split-combined logic.
    wire [31:0] unified_lo = (mode_unified && uni_dir && uni_arith) ? shifted64_arith[31:0] : unified_lo_nonarith;
    wire [31:0] unified_hi = (mode_unified && uni_dir && uni_arith) ? shifted64_arith[63:32] : unified_hi_nonarith;

    // Final out: either unified combined outputs or split-mode outputs
    assign out_bus = mode_unified ? {unified_hi, unified_lo} : {hi_shifter_out, lo_shifter_out};

endmodule
