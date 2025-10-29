module processor#(
    parameter TESTING = 0
)(
	input wire mode,
	input wire clk,
//    input wire [31:0] instrA,
//    input wire [31:0] instrB,
    output [63:0] result
);

    // ----------------------------------------------------------------
    // Program Counter
    // ----------------------------------------------------------------
        wire choose;
        pcfsm pcfsmInst(
            .clk(clk),
            .choose(choose)
        );
        reg [63:0] pc;
        reg [63:0] next_pc;
        wire BranchTakenA;
        wire BranchTakenB;
        wire [63:0] immA; wire [63:0] immB;
        initial begin
            pc = 64'b0;
            next_pc = 64'b0;   
        end

        always @(posedge clk) begin
            if (mode) begin
                // 64-bit mode
                if (BranchTakenA)
                    next_pc <= pc + ($signed(immA) >> 2);        // jump to immediate target
                else
                    next_pc <= pc + 64'd1;  // normal increment
            end
            else begin
                // 32-bit mode
                if (BranchTakenA)
                    next_pc[31:0] <= pc[31:0] + ($signed(immA[31:0]) >> 2);
                else
                    next_pc[31:0] <= pc[31:0] + 32'd1;
            end
            pc <= (choose) ? pc : next_pc;
        end
    

    // ----------------------------------------------------------------
    // Instruction Memory
    // ----------------------------------------------------------------        
    wire hi; assign hi = 1'b1;
    wire [31:0] addrb = pc[63:32] + 32'd512;;  
    wire [31:0] instrA; wire [31:0] instrB;      
    blk_mem_gen_0 instMem(
        .clka(clk),
        .addra(pc[31:0]),
        .douta(instrA),
        .clkb(clk),
        .enb(hi),
        .addrb(addrb),
        .doutb(instrB)
  );

    // ----------------------------------------------------------------
    // Register File
    // ----------------------------------------------------------------
    wire [4:0] rs1A; assign rs1A = instrA[19:15];
    wire [4:0] rs2A; assign rs2A = instrA[24:20];
    wire [4:0]  rdA; assign  rdA = instrA[11:7];

    wire [4:0] rs1B; assign rs1B = instrB[19:15];
    wire [4:0] rs2B; assign rs2B = instrB[24:20];
    wire [4:0]  rdB; assign  rdB = instrB[11:7];
    
    wire [63:0] read_dataA1; wire [63:0] read_dataA2;
    wire [63:0] read_dataB1; wire [63:0] read_dataB2;
    wire [63:0] finalResult;
    wire MemWriteA; wire MemWriteB;

    register_file regfileInst(
        .clk(clk),
        .mode(mode),
        .write_enA(MemWriteA),   // figure this out, will change later
        .write_enB(MemWriteB),   // figure this out, will change later
        .rdA(rdA),
        .rdB(rdB),
        .write_data(finalResult),
        .rs1A(rs1A),
        .rs2A(rs2A),
        .rs1B(rs1B),
        .rs2B(rs2B),
        .read_dataA1(read_dataA1),
        .read_dataA2(read_dataA2),
        .read_dataB1(read_dataB1),
        .read_dataB2(read_dataB2)
    );

    // ----------------------------------------------------------------
    // Control Unit
    // ----------------------------------------------------------------

    wire [2:0] ALUOpA; wire [2:0] ALUOpB;
    wire [5:0] ALUCtrl; 
    wire ALUSrcA; wire ALUSrcB;
    wire BranchA, BranchB;
    wire [2:0] BranchTypeA; wire [2:0] BranchTypeB;
    control_unit ctrlUnitInst(
        .opcodeA(instrA[6:0]),
        .opcodeB(instrB[6:0]),
        .funct3A(instrA[14:12]),
        .funct3B(instrB[14:12]),
        .funct7A(instrA[31:25]),
        .funct7B(instrB[31:25]),
        .mode(mode),
        .ALUOpA(ALUOpA),
        .ALUOpB(ALUOpB),
        .ALUCtrl(ALUCtrl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .MemWriteA(MemWriteA),
        .MemWriteB(MemWriteB),
        .BranchA(BranchA),
        .BranchB(BranchB),
        .BranchTypeA(BranchTypeA),
        .BranchTypeB(BranchTypeB)
    );
     
    // ----------------------------------------------------------------
    // Immediate Generation
    // ----------------------------------------------------------------

    immediate_gen immInst(
        .instrA(instrA),
        .instrB(instrB),
        .immA(immA),
        .immB(immB)
    );

    // Choosing ALU Operand using ALUSrc
    wire [63:0] ALUOperandA; wire [63:0] ALUOperandB;
    assign ALUOperandA = (ALUSrcA) ? immA : read_dataA2;
    assign ALUOperandB = (ALUSrcB) ? immB : read_dataB2;

    // ----------------------------------------------------------------
    // Prepare ALU Inputs
    // ----------------------------------------------------------------
    wire [63:0] ALUInputA; wire [63:0] ALUInputB;
    PrepareALUInputs prepareInst(
        .rs1A(read_dataA1),
        .rs2A(ALUOperandA),
        .rs1B(read_dataB1),
        .rs2B(ALUOperandB),
        .ALUSrcB(ALUSrcB),    // new addition
        .mode(mode),
        .outputA(ALUInputA),
        .outputB(ALUInputB)
    );

    // ----------------------------------------------------------------
    // ALU
    // ----------------------------------------------------------------
    wire eqA, sltA, ultA, eqB, sltB, ultB;
    ALU aluInst(
        .a(ALUInputA),
        .b(ALUInputB),
        .mode(mode),
        .ALUOpA(ALUOpA),
        .ALUOpB(ALUOpB),
        .ALUCtrl(ALUCtrl),
        .result(finalResult),
        .eqA(eqA),
        .sltA(sltA),
        .ultA(ultA),
        .eqB(eqB),
        .sltB(sltB),
        .ultB(ultB) 
    );

    assign result = finalResult;
 
    // ----------------------------------------------------------------
    // Branch Decision
    // ----------------------------------------------------------------    
    branch_decider branchInst(
    .mode(mode),           // 1 = unified, 0 = split
    .branch_typeA(BranchTypeA),
    .branch_typeB(BranchTypeB),
    .eqA(eqA),
    .sltA(sltA),
    .ultA(ultA),
    .eqB(eqB),
    .sltB(sltB),
    .ultB(ultB),
    .branch_takenA(BranchTakenA),
    .branch_takenB(BranchTakenB)
    );
    

endmodule
