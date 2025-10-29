// =====================================================
// RISC-V Immediate Generator 
// Supports I, S, B, U, J type immediates for both A & B
// =====================================================

module immediate_gen #(
    // RISC-V opcode constants
    parameter [6:0] OPC_ITYPE = 7'b0010011,  // addi, andi, ori, etc.
    parameter [6:0] OPC_LOAD  = 7'b0000011,  // lb, lh, lw, lbu, lhu
    parameter [6:0] OPC_STORE = 7'b0100011,  // sb, sh, sw
    parameter [6:0] OPC_BRANCH= 7'b1100011,  // beq, bne, blt, etc.
    parameter [6:0] OPC_JAL   = 7'b1101111,  // jal
    parameter [6:0] OPC_JALR  = 7'b1100111,  // jalr
    parameter [6:0] OPC_LUI   = 7'b0110111   // lui
)(
    input  wire [31:0] instrA,
    input  wire [31:0] instrB,
    output wire [63:0] immA,
    output wire [63:0] immB
);

    // --------------------------------------------------
    // Extract opcodes
    // --------------------------------------------------
    wire [6:0] opcodeA = instrA[6:0];
    wire [6:0] opcodeB = instrB[6:0];

    // --------------------------------------------------
    // Immediate for instrA
    // --------------------------------------------------
    assign immA =
        // I-type, LOAD, JALR
        ((opcodeA == OPC_ITYPE) || (opcodeA == OPC_LOAD) || (opcodeA == OPC_JALR)) ?
            {{52{instrA[31]}}, instrA[31:20]} :
        // S-type
        (opcodeA == OPC_STORE) ?
            {{52{instrA[31]}}, instrA[31:25], instrA[11:7]} :
        // B-type
        (opcodeA == OPC_BRANCH) ?
            {{51{instrA[31]}}, instrA[31], instrA[7], instrA[30:25], instrA[11:8], 1'b0} :
        // J-type
        (opcodeA == OPC_JAL) ?
            {{43{instrA[31]}}, instrA[31], instrA[19:12], instrA[20], instrA[30:21], 1'b0} :
        // U-type
        (opcodeA == OPC_LUI) ?
            {32'b0, instrA[31:12], 12'b0} :
        // Default
            64'b0;

    // --------------------------------------------------
    // Immediate for instrB
    // --------------------------------------------------
    assign immB =
        // I-type, LOAD, JALR
        ((opcodeB == OPC_ITYPE) || (opcodeB == OPC_LOAD) || (opcodeB == OPC_JALR)) ?
            {{52{instrB[31]}}, instrB[31:20]} :
        // S-type
        (opcodeB == OPC_STORE) ?
            {{52{instrB[31]}}, instrB[31:25], instrB[11:7]} :
        // B-type
        (opcodeB == OPC_BRANCH) ?
            {{51{instrB[31]}}, instrB[31], instrB[7], instrB[30:25], instrB[11:8], 1'b0} :
        // J-type
        (opcodeB == OPC_JAL) ?
            {{43{instrB[31]}}, instrB[31], instrB[19:12], instrB[20], instrB[30:21], 1'b0} :
        // U-type
        (opcodeB == OPC_LUI) ?
            {32'b0, instrB[31:12], 12'b0} :
        // Default
            64'b0;

endmodule
