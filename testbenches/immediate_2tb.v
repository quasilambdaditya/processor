`timescale 1ns/1ps

module tb_immediate_gen;

    // DUT Inputs
    reg  [31:0] instrA, instrB;
    // DUT Outputs
    wire [63:0] immA, immB;

    // Instantiate DUT
    immediate_gen dut (
        .instrA(instrA),
        .instrB(instrB),
        .immA(immA),
        .immB(immB)
    );

    // ----------------------------------------------------------
    // Test counters and task
    // ----------------------------------------------------------
    integer total_tests = 0;
    integer passed_tests = 0;

    task run_test(
        input [31:0] iA,
        input [31:0] iB,
        input [63:0] expA,
        input [63:0] expB,
        input string msg
    );
    begin
        instrA = iA;
        instrB = iB;
        #1;
        total_tests++;
        if (immA === expA && immB === expB) begin
            $display(" PASS: %s", msg);
            passed_tests++;
        end else begin
            $display(" FAIL: %s", msg);
            $display("     immA = %h (expected %h)", immA, expA);
            $display("     immB = %h (expected %h)", immB, expB);
        end
    end
    endtask

    // ----------------------------------------------------------
    // Main Test Sequence
    // ----------------------------------------------------------
    initial begin
        $display("======================================================");
        $display("     RISC-V Immediate Generator Testbench Start       ");
        $display("======================================================");

        // ----------------------------
        // I-TYPE: ADDI
        // ----------------------------
        // imm = 0xFFF (-1 signed) and 0x004 (+4)
        run_test(
            32'b111111111111_00010_000_00001_0010011, // ADDI x1,x2,-1
            32'b000000000100_00010_000_00001_0010011, // ADDI x1,x2,4
            {{52{1'b1}}, 12'hFFF},
            {{52{1'b0}}, 12'h004},
            "I-TYPE: ADDI with signed and unsigned immediates"
        );

        // ----------------------------
        // LOAD: LW
        // ----------------------------
        run_test(
            32'b000000000100_00010_010_00001_0000011, // LW imm=4
            32'b111111111100_00010_010_00001_0000011, // LW imm=-4
            {{52{1'b0}}, 12'h004},
            {{52{1'b1}}, 12'hFFC},
            "I-TYPE LOAD: LW with positive and negative immediates"
        );

        // ----------------------------
        // STORE: SW
        // ----------------------------
        // imm = {instr[31:25], instr[11:7]}
        run_test(
            32'b0000000_00001_00010_010_00100_0100011, // imm=0x004
            32'b1111111_00001_00010_010_00000_0100011, // imm=-128
            {{52{1'b0}}, {7'b0000000,5'b00100}},
            {{52{1'b1}}, {7'b1111111,5'b00000}},
            "S-TYPE: SW with positive and negative immediates"
        );

        // ----------------------------
        // BRANCH: BEQ
        // ----------------------------
        // imm = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
        // Example imm = 8 and -8
        run_test(
            32'b0000000_00010_00001_000_01000_1100011, // imm = 8
            32'hfe208ce3, // imm = -8 (fixed)
            {{51{1'b0}}, 13'd8},
            {{51{1'b1}}, -13'sd8},
            "B-TYPE: BEQ with positive and negative branch offsets"
        );

        // ----------------------------
        // U-TYPE: LUI
        // ----------------------------
        run_test(
            32'b00010010001101000101_00001_0110111, // imm=0x12345
            32'b11111111111111111111_00001_0110111, // imm=0xFFFFF
            {32'b0, 20'h12345, 12'b0},
            {32'b0, 20'hFFFFF, 12'b0},
            "U-TYPE: LUI immediate generation"
        );

        // ----------------------------
        // J-TYPE: JAL
        // ----------------------------
        // imm = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
        // J-TYPE: JAL imm=16, imm=-2
        run_test(
            32'b00000001000000000000_00001_1101111, // imm = 16 (fixed)
            32'b11111111111111111111_00001_1101111, // imm = -2
            {{43{1'b0}}, 21'd16},
            {{43{1'b1}}, -21'sd2},
            "J-TYPE: JAL positive and negative offsets"
        );
         // ----------------------------
        // I-TYPE: JALR
        // ----------------------------
        run_test(
            32'b000000000100_00010_000_00001_1100111, // imm=4
            32'b111111111100_00010_000_00001_1100111, // imm=-4
            {{52{1'b0}}, 12'h004},
            {{52{1'b1}}, 12'hFFC},
            "I-TYPE: JALR with positive and negative offsets"
        );

        // ------------------------------------------------------
        // Summary
        // ------------------------------------------------------
        $display("======================================================");
        $display("Test Summary: %0d / %0d PASSED", passed_tests, total_tests);
        if (passed_tests == total_tests)
            $display(" All tests passed!");
        else
            $display("  Some tests failed!");
        $display("======================================================");

        $finish;
    end

endmodule
