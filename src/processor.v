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
        reg [63:0] pc;     
        reg [63:0] next_pc;
        reg rst;
        wire BranchA, BranchB;
        wire [63:0] pc_update_amt = (mode) ? 64'd1 : {32'd1, 32'd1}; 
        
        wire [63:0] immA, immB;
        wire [63:0] pc_shift_amt = (mode) ? 64'd2 : {32'd2, 32'd2};
               
        wire [63:0] pc_plus1; wire cout;
        
        wire pc_choose, reg_write_choose;
        
        wire [63:0] pc_branch;
        
        initial begin
            pc = -64'd1;
        end
                
        adder64 pcAdder(
            .a(pc),
            .b(pc_update_amt),
            .mode(mode),
            .sub_uni(1'b0),
            .sub_hi(1'b0),
            .sub_lo(1'b0),
            .sum(pc_plus1),
            .cout(cout)
            );
            
        wire [63:0] pc_shift_input = (mode == 1) ? immA : {immB[31:0], immA[31:0]}; 
            
        shift64 pcShift(
            .mode_unified(mode),
            .uni_dir(1'b1),
            .uni_arith(1'b1),
            .hi_dir(1'b1),
            .hi_arith(1'b1),
            .lo_dir(1'b1),
            .lo_arith(1'b1),
            .shift_amt(pc_shift_amt),
            .in_bus(pc_shift_input),
            .out_bus(pc_branch)
        );
 

        pcfsm pcfsmInst(
            .clk(clk),
//            .reset(rst),
            .pc_choose(pc_choose),
            .reg_write_choose(reg_write_choose)
        );
        
         always @(*) begin
 //           next_pc = pc_plus1;
            if (mode) begin
                if (BranchTakenA && BranchA)
                    next_pc = pc + pc_branch;
                 else begin 
                    next_pc = pc_plus1;
                 end
            end else begin
                next_pc = pc_plus1;
                if (BranchTakenA && BranchA)
                    next_pc[31:0] = pc[31:0] + pc_branch[31:0];
                if (BranchTakenB && BranchB)
                    next_pc[63:32] = pc[63:32] + pc_branch[31:0];
            end
        end
        
        always @(posedge clk) begin
            if (~pc_choose) begin pc <= next_pc; end
        end
        
        

    // ----------------------------------------------------------------
    // Instruction Memory
    // ----------------------------------------------------------------        
    reg [31:0] addrb;
    always @(posedge clk) begin
       addrb = $signed(pc[63:32]) + 32'd512;
    end
      
    wire [31:0] instrA; wire [31:0] instrB;      
    blk_mem_gen_0 instMem(
        .clka(clk),
        .addra(pc[31:0]),
        .douta(instrA),
        .clkb(clk),
        .enb(1'b1),
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
        .write_enA(MemWriteA & ~reg_write_choose),   // figure this out, will change later
        .write_enB(MemWriteB & ~reg_write_choose),   // figure this out, will change later
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
