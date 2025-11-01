// =====================================================
// Pure Combinational Branch Decider
// =====================================================

module branch_decider(
    input  wire       mode,           // 1 = unified, 0 = split
    input  wire [2:0] branch_typeA,
    input  wire [2:0] branch_typeB,
    input  wire eqA, sltA, ultA,
    input  wire eqB, sltB, ultB,
    output wire branch_takenA,
    output wire branch_takenB
);

    // --------------------------------------------------
    // A-side Branch Decision
    // --------------------------------------------------
    wire branchA_decision =
        (branch_typeA == 3'b000) ?  eqA  : // BEQ
        (branch_typeA == 3'b001) ? ~eqA  : // BNE
        (branch_typeA == 3'b010) ?  sltA : // BLT
        (branch_typeA == 3'b011) ? ~sltA : // BGE
        (branch_typeA == 3'b100) ?  ultA : // BLTU
        (branch_typeA == 3'b101) ? ~ultA : // BGEU
                                   1'b0;  // default

    // --------------------------------------------------
    // B-side Branch Decision
    // --------------------------------------------------
    wire branchB_decision =
        (branch_typeB == 3'b000) ?  eqB  : // BEQ
        (branch_typeB == 3'b001) ? ~eqB  : // BNE
        (branch_typeB == 3'b010) ?  sltB : // BLT
        (branch_typeB == 3'b011) ? ~sltB : // BGE
        (branch_typeB == 3'b100) ?  ultB : // BLTU
        (branch_typeB == 3'b101) ? ~ultB : // BGEU
                                   1'b0;  // default

    // --------------------------------------------------
    // Final Outputs
    // --------------------------------------------------
    assign branch_takenA = branchA_decision;
    assign branch_takenB = (mode == 1'b1) ? 1'b0 : branchB_decision;

endmodule
