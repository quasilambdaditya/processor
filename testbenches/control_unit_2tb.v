`timescale 1ns/1ps

module tb_control_unit;

    // DUT inputs
    reg  [6:0] opcodeA, opcodeB;
    reg  [2:0] funct3A, funct3B;
    reg  [6:0] funct7A, funct7B;
    reg        mode;

    // DUT outputs
    wire [2:0] ALUOpA, ALUOpB;
    wire [5:0] ALUCtrl;
    wire       ALUSrcA, ALUSrcB;
    wire       MemWriteA, MemWriteB;
    wire       BranchA, BranchB;
    wire [2:0] BranchTypeA, BranchTypeB;

    // Instantiate DUT
    control_unit dut (
        .opcodeA(opcodeA), .opcodeB(opcodeB),
        .funct3A(funct3A), .funct3B(funct3B),
        .funct7A(funct7A), .funct7B(funct7B),
        .mode(mode),
        .ALUOpA(ALUOpA), .ALUOpB(ALUOpB),
        .ALUCtrl(ALUCtrl),
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB),
        .MemWriteA(MemWriteA), .MemWriteB(MemWriteB),
        .BranchA(BranchA), .BranchB(BranchB),
        .BranchTypeA(BranchTypeA), .BranchTypeB(BranchTypeB)
    );

    // --------------------------------------------------
    // Constants
    // --------------------------------------------------
    localparam OPC_RTYPE  = 7'b0110011;
    localparam OPC_ITYPE  = 7'b0010011;
    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_JALR   = 7'b1100111;
    localparam OPC_BRANCH = 7'b1100011;

    localparam F3_ADD_SUB = 3'b000;
    localparam F3_SLL     = 3'b001;
    localparam F3_SRL     = 3'b101;
    localparam F3_SRA     = 3'b101; // same funct3, diff funct7

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

    integer tests_passed = 0;
    integer tests_failed = 0;

    // --------------------------------------------------
    // PASS/FAIL helper
    // --------------------------------------------------
    task check_result;
        input [255:0] testname; // extended to avoid truncation
        input condition;
        begin
            if (condition) begin
                $display(" PASS: %-40s", testname);
                tests_passed = tests_passed + 1;
            end else begin
                $display(" FAIL: %-40s", testname);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // --------------------------------------------------
    // TEST PROCEDURE
    // --------------------------------------------------
    initial begin
        $display("\n==========================================================");
        $display("        RISC-V CONTROL UNIT TESTBENCH STARTED");
        $display("==========================================================\n");

        // =====================================================
        // Unified Mode Tests
        // =====================================================
        $display("------------ [Unified Mode Tests] ------------\n");
        mode = 1'b1;

        // --- ADD / ADDI ---
        opcodeA = OPC_RTYPE; funct3A = F3_ADD_SUB; funct7A = F7_ADD;
        opcodeB = OPC_ITYPE; funct3B = F3_ADD_SUB; funct7B = F7_ADD;
        #1;
        check_result("Unified ADD/ADDI ALUSrc", (ALUSrcA == 0 && ALUSrcB == 1));
        check_result("Unified ADD/ADDI ALUOp",  (ALUOpA == 3'b000 && ALUOpB == 3'b000));

        // --- SUB ---
        funct7A = F7_SUB;
        #1;
        check_result("Unified SUB ALUCtrl[4]", ALUCtrl[4] == 1'b1);

        // --- AND / OR / XOR ---
        funct3A = 3'b111; funct3B = 3'b110;
        #1;
        check_result("Unified AND/OR ALUOp", (ALUOpA == 3'b001 && ALUOpB == 3'b010));

        // --- Shift operations ---
        funct3A = F3_SLL;
        #1; check_result("Unified SLL ALUCtrl", ALUCtrl == 6'b000000);
        funct3A = F3_SRL; funct7A = F7_SRL;
        #1; check_result("Unified SRL ALUCtrl", ALUCtrl == 6'b100000);
        funct3A = F3_SRA; funct7A = F7_SRA;
        #1; check_result("Unified SRA ALUCtrl", ALUCtrl == 6'b110000);

       // --- Branch Tests ---
        opcodeA = OPC_BRANCH; funct3A = F3_BNE;
        #1;
        check_result("Unified Branch detect A", BranchA == 1'b1);
        check_result("Unified Branch type BNE", BranchTypeA == 3'b001);

        opcodeB = OPC_BRANCH; funct3B = F3_BGEU;
        #1;
        check_result("Unified Branch detect B", BranchB == 1'b1);
        check_result("Unified Branch type BGEU", BranchTypeB == 3'b101);

        // =====================================================
        // Split Mode Tests
        // =====================================================
        $display("\n------------ [Split Mode Tests] ------------\n");
        mode = 1'b0;

        // --- SRA / SLL / SUB (A side) ---
        opcodeA = OPC_RTYPE; funct3A = F3_SRA; funct7A = F7_SRA;
        opcodeB = OPC_RTYPE; funct3B = F3_SLL; funct7B = F7_ADD;
        #1;
        check_result("Split A SRA ALUCtrl[1:0]", ALUCtrl[1:0] == 2'b11);
        check_result("Split B SLL ALUCtrl[3:2]", ALUCtrl[3:2] == 2'b00);

        funct3A = F3_ADD_SUB; funct7A = F7_SUB;
        #1;
        check_result("Split A SUB ALUCtrl[1:0]", ALUCtrl[1:0] == 2'b01);

        // --- MemWrite flags ---
        opcodeA = OPC_RTYPE; opcodeB = OPC_ITYPE;
        #1;
        check_result("Split MemWriteA", MemWriteA == 1);
        check_result("Split MemWriteB", MemWriteB == 1);

        // --- Branch Tests ---
        opcodeA = OPC_BRANCH; funct3A = F3_BLT;
        opcodeB = OPC_BRANCH; funct3B = F3_BEQ;
        #1;
        check_result("Split BranchA active", BranchA == 1);
        check_result("Split BranchTypeA BLT", BranchTypeA == 3'b010);
        check_result("Split BranchTypeB BEQ", BranchTypeB == 3'b000);

        // =====================================================
        // Summary
        // =====================================================
        $display("\n==========================================================");
        $display("                     TEST SUMMARY");
        $display("==========================================================");
        $display("     Passed : %0d", tests_passed);
        $display("     Failed : %0d", tests_failed);
        $display("==========================================================");
        if (tests_failed == 0)
            $display(" ALL TESTS PASSED SUCCESSFULLY!");
        else
            $display("  SOME TESTS FAILED. CHECK LOG ABOVE.");
        $display("==========================================================\n");

        $finish;
    end

endmodule
