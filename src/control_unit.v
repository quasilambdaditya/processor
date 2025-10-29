// =====================================================
// RISC-V Control Unit (Parameterised)
// Supports ALUOp, ALUSrc, and ALUCtrl logic
// Extended for ADD/ADDI/SUB
// =====================================================

module control_unit (
    input  wire [6:0] opcodeA,
    input  wire [6:0] opcodeB,
    input  wire [2:0] funct3A,
    input  wire [2:0] funct3B,
    input  wire [6:0] funct7A,
    input  wire [6:0] funct7B,
    input  wire       mode,       // 1 = unified, 0 = split 
    
    output reg  [2:0] ALUOpA,
    output reg  [2:0] ALUOpB,
    output reg  [5:0] ALUCtrl,
    output reg        ALUSrcA,
    output reg        ALUSrcB,
    output reg        MemWriteA,
    output reg        MemWriteB,
    output reg        BranchA,
    output reg        BranchB,
    output reg  [2:0] BranchTypeA,
    output reg  [2:0] BranchTypeB
);

    // --------------------------------------------------
    // RISC-V Opcodes
    // --------------------------------------------------
    localparam OPC_RTYPE = 7'b0110011;
    localparam OPC_ITYPE = 7'b0010011;
    localparam OPC_LOAD  = 7'b0000011;
    localparam OPC_STORE = 7'b0100011;
    localparam OPC_JALR  = 7'b1100111;
    localparam OPC_BRANCH = 7'b1100011;

    // --------------------------------------------------
    // funct3 / funct7 encodings
    // --------------------------------------------------
    localparam F3_ADD_SUB = 3'b000;
    localparam F3_SLL  = 3'b001;
    localparam F3_SRL  = 3'b101;
    localparam F3_SRA  = 3'b101;   // same funct3, different funct7
    
    localparam F3_BEQ  = 3'b000;
    localparam F3_BNE  = 3'b001;
    localparam F3_BLT  = 3'b100;
    localparam F3_BGE  = 3'b101;
    localparam F3_BLTU = 3'b110;
    localparam F3_BGEU = 3'b111;
    
    
    localparam F7_ADD  = 7'b0000000;
    localparam F7_SUB  = 7'b0100000;
    localparam F7_SRL  = 7'b0000000;
    localparam F7_SRA  = 7'b0100000;

    // ==================================================
    // ALUSrc (0 = reg, 1 = imm)
    // ==================================================
    always @(*) begin
        case (opcodeA)
            OPC_ITYPE, OPC_LOAD, OPC_STORE, OPC_JALR: ALUSrcA = 1'b1;
            default:                                 ALUSrcA = 1'b0;
        endcase

        case (opcodeB)
            OPC_ITYPE, OPC_LOAD, OPC_STORE, OPC_JALR: ALUSrcB = 1'b1;
            default:                                 ALUSrcB = 1'b0;
        endcase
    end

    // ==================================================
    // ALUOp (3-bit code for broad ALU category)
    // ==================================================
    always @(*) begin
        // A-side
        if (opcodeA == OPC_LOAD || opcodeA == OPC_STORE || opcodeA == OPC_JALR)
            ALUOpA = 3'b000; // address computation (add)
        else if ((opcodeA == OPC_RTYPE || opcodeA == OPC_ITYPE) && funct3A == F3_ADD_SUB)
            ALUOpA = 3'b000; // add/sub/addi
        else if (funct3A == 3'b111)
            ALUOpA = 3'b001; // and/andi
        else if (funct3A == 3'b110)
            ALUOpA = 3'b010; // or/ori
        else if (funct3A == 3'b100)
            ALUOpA = 3'b011; // xor/xori
        else if (funct3A == 3'b001 || funct3A == 3'b101)
            ALUOpA = 3'b100; // shift
        else
            ALUOpA = 3'b000; // don't care for B-Type

        // B-side
        if (opcodeB == OPC_LOAD || opcodeB == OPC_STORE || opcodeB == OPC_JALR)
            ALUOpB = 3'b000;
        else if ((opcodeB == OPC_RTYPE || opcodeB == OPC_ITYPE) && funct3B == F3_ADD_SUB)
            ALUOpB = 3'b000;
        else if (funct3B == 3'b111)
            ALUOpB = 3'b001;
        else if (funct3B == 3'b110)
            ALUOpB = 3'b010;
        else if (funct3B == 3'b100)
            ALUOpB = 3'b011;
        else if (funct3B == 3'b001 || funct3B == 3'b101)
            ALUOpB = 3'b100;
        else
            ALUOpB = 3'b000; // don't care for B-Type
    end

    // ==================================================================
    // ALUCtrl Encoding (Shift + Add/Sub operations)
    // ------------------------------------------------------------------
    // Output : 6-bit encoding
    // Encoding : uni_dir | uni_shift/sub_uni | hi_dir | hi_shift/sub_hi
    //           | lo_dir | lo_shift/sub_lo
    // ==================================================================
    always @(*) begin
        ALUCtrl = 6'b000000;

        if (mode == 1'b1) begin
            // ==================================================
            // Unified Mode
            // ==================================================
            if ((opcodeA == OPC_RTYPE || opcodeA == OPC_ITYPE)) begin
                // ---- Shift Operations ----
                if (funct3A == F3_SLL)
                    ALUCtrl = 6'b000000;   // SLL / SLLI
                else if (funct3A == F3_SRL && funct7A == F7_SRL)
                    ALUCtrl = 6'b100000;   // SRL / SRLI
                else if (funct3A == F3_SRA && funct7A == F7_SRA)
                    ALUCtrl = 6'b110000;   // SRA / SRAI

                // ---- ADD / ADDI / SUB ----
               else if (funct3A == F3_ADD_SUB) begin
                    if (funct7A == F7_SUB && opcodeA == OPC_RTYPE)
                        ALUCtrl[4] = 1'b1;     // sub
                    else
                        ALUCtrl[4] = 1'b0;     // add/addi/ld/st/jalr
                end
            end

            if ((opcodeB == OPC_RTYPE || opcodeB == OPC_ITYPE)) begin
                if (funct3B == F3_ADD_SUB && funct7B == F7_SUB && opcodeB == OPC_RTYPE)
                    ALUCtrl[1] = 1'b1;         // subB
                else
                    ALUCtrl[1] = 1'b0;
            end
        end
        else begin
            // ==================================================
            // Split Mode
            // ==================================================
            // --- A side bits [1:0] ---
            if ((opcodeA == OPC_RTYPE || opcodeA == OPC_ITYPE)) begin
                if (funct3A == F3_SLL)
                    ALUCtrl[1:0] = 2'b00;
                else if (funct3A == F3_SRL && funct7A == F7_SRL)
                    ALUCtrl[1:0] = 2'b10;
                else if (funct3A == F3_SRA && funct7A == F7_SRA)
                    ALUCtrl[1:0] = 2'b11;
                else if (funct3A == F3_ADD_SUB && funct7A == F7_SUB)
                    ALUCtrl[1:0] = 2'b01;  // subA
            end

            // --- B side bits [3:2] ---
            if ((opcodeB == OPC_RTYPE || opcodeB == OPC_ITYPE)) begin
                if (funct3B == F3_SLL)
                    ALUCtrl[3:2] = 2'b00;
                else if (funct3B == F3_SRL && funct7B == F7_SRL)
                    ALUCtrl[3:2] = 2'b10;
                else if (funct3B == F3_SRA && funct7B == F7_SRA)
                    ALUCtrl[3:2] = 2'b11;
                else if (funct3B == F3_ADD_SUB && funct7B == F7_SUB)
                    ALUCtrl[3:2] = 2'b01;  // subB
            end
        end
    end
    // ==================================================
    // Split Mode
    // ==================================================
    always @(*) begin
        MemWriteA = (opcodeA == OPC_RTYPE || opcodeA == OPC_ITYPE) ? 1'b1 : 1'b0;
        MemWriteB = (opcodeB == OPC_RTYPE || opcodeB == OPC_ITYPE) ? 1'b1 : 1'b0;
    end
    
    // ==================================================
    // Branch Detection Logic
    // ==================================================
    always @(*) begin
        BranchA = (opcodeA == OPC_BRANCH);
        BranchB = (opcodeB == OPC_BRANCH);

        BranchTypeA = 3'b000;
        BranchTypeB = 3'b000;

        if (BranchA) begin
            case (funct3A)
                F3_BEQ:  BranchTypeA = 3'b000;
                F3_BNE:  BranchTypeA = 3'b001;
                F3_BLT:  BranchTypeA = 3'b010;
                F3_BGE:  BranchTypeA = 3'b011;
                F3_BLTU: BranchTypeA = 3'b100;
                F3_BGEU: BranchTypeA = 3'b101;
                default: BranchTypeA = 3'b000;
            endcase
        end

        if (BranchB) begin
            case (funct3B)
                F3_BEQ:  BranchTypeB = 3'b000;
                F3_BNE:  BranchTypeB = 3'b001;
                F3_BLT:  BranchTypeB = 3'b010;
                F3_BGE:  BranchTypeB = 3'b011;
                F3_BLTU: BranchTypeB = 3'b100;
                F3_BGEU: BranchTypeB = 3'b101;
                default: BranchTypeB = 3'b000;
            endcase
        end
    end
    
endmodule
