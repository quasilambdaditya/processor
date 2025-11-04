// =====================================================
// RISC-V Control Unit
// =====================================================

module control_unit (
    input  wire [6:0] opcodeA,
    input  wire [6:0] opcodeB,
    input  wire [2:0] funct3A,
    input  wire [2:0] funct3B,
    input  wire [6:0] funct7A,
    input  wire [6:0] funct7B,
    
    input  wire       mode,       // 1 = unified, 0 = split 

    output wire [2:0] ALUOpA,
    output wire [2:0] ALUOpB,
    
    output wire [5:0] ALUCtrl,
    
    output wire       ALUSrcA,
    output wire       ALUSrcB,
    
    output wire       RegWriteA,
    output wire       RegWriteB,
    
    output wire       MemWriteA,
    output wire       MemWriteB,
    
    output wire       MemToRegA,
    output wire       MemToRegB,
    
    output wire [1:0] read_write_amtA,
    output wire [1:0] read_write_amtB,
    
    output wire       unsigned_readA,
    output wire       unsigned_readB,
    
    output wire       DMEMEnableA,
    output wire       DMEMEnableB,
        
    output wire       BranchA,
    output wire       BranchB,
    output wire [2:0] BranchTypeA,
    output wire [2:0] BranchTypeB
);

    // --------------------------------------------------
    // RISC-V Opcodes
    // --------------------------------------------------
    localparam OPC_RTYPE  = 7'b0110011;
    localparam OPC_ITYPE  = 7'b0010011;
    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_JALR   = 7'b1100111;
    localparam OPC_BRANCH = 7'b1100011;

    // --------------------------------------------------
    // funct3 / funct7 encodings
    // --------------------------------------------------
    localparam F3_ADD_SUB = 3'b000;
    localparam F3_SLL     = 3'b001;
    localparam F3_SRL     = 3'b101;
    localparam F3_SRA     = 3'b101;
    localparam F3_AND     = 3'b111;
    localparam F3_OR      = 3'b110;
    localparam F3_XOR     = 3'b100;
    localparam F3_LBU     = 3'b100;
    localparam F3_LHU     = 3'b101;
    localparam F3_LWU     = 3'b110;

    localparam F3_BEQ     = 3'b000;
    localparam F3_BNE     = 3'b001;
    localparam F3_BLT     = 3'b100;
    localparam F3_BGE     = 3'b101;
    localparam F3_BLTU    = 3'b110;
    localparam F3_BGEU    = 3'b111;

    localparam F7_ADD     = 7'b0000000;
    localparam F7_SUB     = 7'b0100000;
    localparam F7_SRL     = 7'b0000000;
    localparam F7_SRA     = 7'b0100000;

    // ==================================================
    // ALUSrc (1 = immediate)
    // ==================================================
    assign ALUSrcA = (opcodeA == OPC_ITYPE || opcodeA == OPC_LOAD || opcodeA == OPC_STORE || opcodeA == OPC_JALR);
    assign ALUSrcB = (opcodeB == OPC_ITYPE || opcodeB == OPC_LOAD || opcodeB == OPC_STORE || opcodeB == OPC_JALR);

    // ==================================================
    // ALUOp (3-bit)
    // ==================================================
    assign ALUOpA =
        (opcodeA == OPC_LOAD || opcodeA == OPC_STORE || opcodeA == OPC_JALR) ? 3'b000 :
        ((opcodeA == OPC_RTYPE || opcodeA == OPC_ITYPE) && funct3A == F3_ADD_SUB) ? 3'b000 :
        (funct3A == F3_AND) ? 3'b001 :
        (funct3A == F3_OR)  ? 3'b010 :
        (funct3A == F3_XOR) ? 3'b011 :
        ((funct3A == F3_SLL) || (funct3A == F3_SRL)) ? 3'b100 :
        3'b000;

    assign ALUOpB =
        (opcodeB == OPC_LOAD || opcodeB == OPC_STORE || opcodeB == OPC_JALR) ? 3'b000 :
        ((opcodeB == OPC_RTYPE || opcodeB == OPC_ITYPE) && funct3B == F3_ADD_SUB) ? 3'b000 :
        (funct3B == F3_AND) ? 3'b001 :
        (funct3B == F3_OR)  ? 3'b010 :
        (funct3B == F3_XOR) ? 3'b011 :
        ((funct3B == F3_SLL) || (funct3B == F3_SRL)) ? 3'b100 :
        3'b000;

    // ==================================================
    // ALUCtrl (6-bit)
    // ==================================================
    wire [5:0] alu_ctrl_unified;
    wire [5:0] alu_ctrl_split;

    // Unified Mode
    assign alu_ctrl_unified[4] =
        ((opcodeA == OPC_RTYPE) && (funct3A == F3_ADD_SUB) && (funct7A == F7_SUB)) ? 1'b1 : 1'b0;

    assign alu_ctrl_unified[1] =
        ((opcodeB == OPC_RTYPE) && (funct3B == F3_ADD_SUB) && (funct7B == F7_SUB)) ? 1'b1 : 1'b0;

    assign alu_ctrl_unified[5] = (funct3A == F3_SRL && funct7A == F7_SRL);
    assign alu_ctrl_unified[3] = (funct3A == F3_SRA && funct7A == F7_SRA);
    assign alu_ctrl_unified[0] = (funct3A == F3_SLL);

    // Split Mode
    wire [1:0] ctrlA_split =
        (funct3A == F3_SLL) ? 2'b00 :
        ((funct3A == F3_SRL) && (funct7A == F7_SRL)) ? 2'b10 :
        ((funct3A == F3_SRA) && (funct7A == F7_SRA)) ? 2'b11 :
        ((funct3A == F3_ADD_SUB) && (funct7A == F7_SUB)) ? 2'b01 :
        2'b00;

    wire [1:0] ctrlB_split =
        (funct3B == F3_SLL) ? 2'b00 :
        ((funct3B == F3_SRL) && (funct7B == F7_SRL)) ? 2'b10 :
        ((funct3B == F3_SRA) && (funct7B == F7_SRA)) ? 2'b11 :
        ((funct3B == F3_ADD_SUB) && (funct7B == F7_SUB)) ? 2'b01 :
        2'b00;

    assign alu_ctrl_split = {2'b00, ctrlB_split, ctrlA_split};

    assign ALUCtrl = (mode == 1'b1) ? alu_ctrl_unified : alu_ctrl_split;

    // ==================================================
    // RegWrite
    // ==================================================
    assign RegWriteA = (opcodeA == OPC_RTYPE || opcodeA == OPC_ITYPE || opcodeA == OPC_LOAD);
    assign RegWriteB = (opcodeB == OPC_RTYPE || opcodeB == OPC_ITYPE || opcodeB == OPC_LOAD);
    
    // ==================================================
    // MemWrite
    // ==================================================  
    assign MemWriteA = (opcodeA == OPC_STORE);
    assign MemWriteB = (opcodeB == OPC_STORE);  
    
    // ==================================================
    // DMEMEnable
    // ==================================================  
    assign DMEMEnableA = (opcodeA == OPC_LOAD || opcodeA == OPC_STORE);
    assign DMEMEnableB = (opcodeB == OPC_LOAD || opcodeB == OPC_STORE);  
    
    // ==================================================
    // MemToReg
    // ==================================================  
    assign MemToRegA = (opcodeA == OPC_LOAD);
    assign MemToRegB = (opcodeB == OPC_LOAD);  

    // ==================================================
    // Unsigned Read
    // ==================================================    
    assign unsigned_readA = (opcodeA == OPC_LOAD && 
            (funct3A == 3'd4 || funct3A == 3'd5 || funct3A == 3'd6));
    assign unsigned_readB = (opcodeB == OPC_LOAD && 
            (funct3B == 3'd4 || funct3B == 3'd5 || funct3B == 3'd6));
  
    // ==================================================
    // Read/Write Amount
    // ==================================================                
    // For A: handle loads and stores
    assign read_write_amtA =
        ( (opcodeA == OPC_LOAD && (funct3A == 3'd0 || funct3A == 3'd4)) ||
          (opcodeA == OPC_STORE &&  (funct3A == 3'd0)) ) ? 2'd0 : // byte (SB / LB / LBU)
        ( (opcodeA == OPC_LOAD && (funct3A == 3'd1 || funct3A == 3'd5)) ||
          (opcodeA == OPC_STORE &&  (funct3A == 3'd1)) ) ? 2'd1 : // half (SH / LH / LHU)
        ( (opcodeA == OPC_LOAD && (funct3A == 3'd2 || funct3A == 3'd6)) ||
          (opcodeA == OPC_STORE &&  (funct3A == 3'd2)) ) ? 2'd2 : // word (SW / LW / LWU)
        ( (opcodeA == OPC_LOAD && (funct3A == 3'd3)) ||
          (opcodeA == OPC_STORE &&  (funct3A == 3'd3)) ) ? 2'd3 : // dword (SD)
        2'd0;
    
    // For B:
    assign read_write_amtB =
        ( (opcodeB == OPC_LOAD && (funct3B == 3'd0 || funct3B == 3'd4)) ||
          (opcodeB == OPC_STORE &&  (funct3B == 3'd0)) ) ? 2'd0 :
        ( (opcodeB == OPC_LOAD && (funct3B == 3'd1 || funct3B == 3'd5)) ||
          (opcodeB == OPC_STORE &&  (funct3B == 3'd1)) ) ? 2'd1 :
        ( (opcodeB == OPC_LOAD && (funct3B == 3'd2 || funct3B == 3'd6)) ||
          (opcodeB == OPC_STORE &&  (funct3B == 3'd2)) ) ? 2'd2 :
        ( (opcodeB == OPC_LOAD && (funct3B == 3'd3)) ||
          (opcodeB == OPC_STORE &&  (funct3B == 3'd3)) ) ? 2'd3 :
        2'd0;
    
     
    // ==================================================
    // Branch Detection Logic
    // ==================================================
    assign BranchA = (opcodeA == OPC_BRANCH);
    assign BranchB = (opcodeB == OPC_BRANCH);

    assign BranchTypeA =
        (funct3A == F3_BEQ)  ? 3'b000 :
        (funct3A == F3_BNE)  ? 3'b001 :
        (funct3A == F3_BLT)  ? 3'b010 :
        (funct3A == F3_BGE)  ? 3'b011 :
        (funct3A == F3_BLTU) ? 3'b100 :
        (funct3A == F3_BGEU) ? 3'b101 :
        3'b000;

    assign BranchTypeB =
        (funct3B == F3_BEQ)  ? 3'b000 :
        (funct3B == F3_BNE)  ? 3'b001 :
        (funct3B == F3_BLT)  ? 3'b010 :
        (funct3B == F3_BGE)  ? 3'b011 :
        (funct3B == F3_BLTU) ? 3'b100 :
        (funct3B == F3_BGEU) ? 3'b101 :
        3'b000;

endmodule