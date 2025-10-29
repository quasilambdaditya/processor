// =====================================================
// Branch Decider
// =====================================================

module branch_decider(
    input  wire       mode,           // 1 = unified, 0 = split
    input  wire [2:0] branch_typeA,
    input  wire [2:0] branch_typeB,
    input  wire eqA, sltA, ultA,
    input  wire eqB, sltB, ultB,

    output reg  branch_takenA,
    output reg  branch_takenB
);

    // --------------------------------------------------
    // Temporary signals for branch decisions
    // --------------------------------------------------
    reg branchA_decision;
    reg branchB_decision;

    // --------------------------------------------------
    // Branch Decision for A-side
    // --------------------------------------------------
    always @(*) begin
        case (branch_typeA)
            3'b000: branchA_decision = eqA;          // BEQ
            3'b001: branchA_decision = ~eqA;         // BNE
            3'b010: branchA_decision = sltA;         // BLT
            3'b011: branchA_decision = ~sltA;        // BGE
            3'b100: branchA_decision = ultA;         // BLTU
            3'b101: branchA_decision = ~ultA;        // BGEU
            default: branchA_decision = 1'b0;
        endcase
    end

    // --------------------------------------------------
    // Branch Decision for B-side
    // --------------------------------------------------
    always @(*) begin
        case (branch_typeB)
            3'b000: branchB_decision = eqB;          // BEQ
            3'b001: branchB_decision = ~eqB;         // BNE
            3'b010: branchB_decision = sltB;         // BLT
            3'b011: branchB_decision = ~sltB;        // BGE
            3'b100: branchB_decision = ultB;         // BLTU
            3'b101: branchB_decision = ~ultB;        // BGEU
            default: branchB_decision = 1'b0;
        endcase
    end

    // --------------------------------------------------
    // Final Outputs 
    // --------------------------------------------------
    always @(*) begin
        branch_takenA = branchA_decision;
        branch_takenB = (mode == 1'b1) ? 1'b0 : branchB_decision;
    end

endmodule
