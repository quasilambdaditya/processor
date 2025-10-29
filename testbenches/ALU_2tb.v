`timescale 1ns / 1ps

module tb_ALU;

    // DUT inputs
    reg  [63:0] a, b;
    reg         mode;
    reg  [2:0]  ALUOpA, ALUOpB;
    reg  [5:0]  ALUCtrl;

    // DUT outputs
    wire [63:0] result;
    wire eqA, sltA, ultA, eqB, sltB, ultB;

    // Instantiate DUT
    ALU dut (
        .a(a),
        .b(b),
        .mode(mode),
        .ALUOpA(ALUOpA),
        .ALUOpB(ALUOpB),
        .ALUCtrl(ALUCtrl),
        .result(result),
        .eqA(eqA),
        .sltA(sltA),
        .ultA(ultA),
        .eqB(eqB),
        .sltB(sltB),
        .ultB(ultB)
    );

    // Pass/Fail reporting
    task check_result;
        input [63:0] expected;
        input [255:0] testname;
        begin
            if (result === expected)
                $display(" [PASS] %s | Result = %h", testname, result);
            else
                $display(" [FAIL] %s | Got = %h | Expected = %h", testname, result, expected);
        end
    endtask

    initial begin
        $display("=====================================================");
        $display("               ALU TESTBENCH STARTED                 ");
        $display("=====================================================");

        // ============================================================
        // Unified Mode (mode = 1)
        // ============================================================
        mode = 1;
        ALUCtrl = 6'b000000;

        // -------------------------
        // ADD
        // -------------------------
        a = 64'h0000_0000_0000_000A;
        b = 64'h0000_0000_0000_0005;
        ALUOpA = 3'b000;
        #5; check_result(64'hF, "Unified ADD");

        // SUB
        b = 64'h0000_0000_0000_0003;
        ALUOpA = 3'b000;
        ALUCtrl = 6'b010000; // maybe indicates subtraction
        #5; check_result(64'h7, "Unified SUB");

        // AND
        a = 64'hFFFF_0000_FFFF_0000;
        b = 64'h0F0F_F0F0_0F0F_F0F0;
        ALUOpA = 3'b001;
        #5; check_result(64'h0F0F_0000_0F0F_0000, "Unified AND");

        // OR
        ALUOpA = 3'b010;
        #5; check_result(64'hFFFF_F0F0_FFFF_F0F0, "Unified OR");

        // XOR
        ALUOpA = 3'b011;
        #5; check_result(64'hF0F0_F0F0_F0F0_F0F0, "Unified XOR");

        // SHIFT LEFT (SLL)
        a = 64'h0000_0000_0000_0001;
        b = 64'h0000_0000_0000_0003;
        ALUOpA = 3'b100;
        ALUCtrl = 6'b000000;
        #5; check_result(64'h8, "Unified SLL (<<3)");

        // SHIFT RIGHT LOGICAL (SRL)
        a = 64'h0000_0000_0000_00F0;
        b = 64'h0000_0000_0000_0004;
        ALUCtrl = 6'b100000;
        #5; check_result(64'hF, "Unified SRL (>>4)");

        // SHIFT RIGHT ARITHMETIC (SRA)
        a = 64'hFFFF_FFFF_FFFF_FF00; // negative number
        b = 64'h0000_0000_0000_0008;
        ALUCtrl = 6'b110000;
        #5; check_result(64'hFFFF_FFFF_FFFF_FFFF, "Unified SRA (>>8 arithmetic)");

        // Comparator tests
        a = 64'h0000_0000_0000_000A;
        b = 64'h0000_0000_0000_000A;
        #5;
        if (eqA) $display(" [PASS] EQ Comparator");
        else     $display(" [FAIL] EQ Comparator");

        a = 64'h0000_0000_0000_0004;
        b = 64'h0000_0000_0000_0008;
        #5;
        if (sltA && ultA) $display(" [PASS] LT Comparator");
        else               $display(" [FAIL] LT Comparator");

        // ============================================================
        // Split Mode (mode = 0)
        // ============================================================
        $display("-----------------------------------------------------");
        $display("                Split Mode Tests                     ");
        $display("-----------------------------------------------------");

        mode = 0;
        a = 64'hAAAA_BBBB_CCCC_DDDD;
        b = 64'h1111_2222_3333_4444;

        // ADD (low) / XOR (high)
        ALUOpA = 3'b000; // ADD low
        ALUOpB = 3'b011; // XOR high
        ALUCtrl = 6'b000000;
        #5; check_result({(a[63:32]^b[63:32]), (a[31:0]+b[31:0])}, "Split XOR(H)/ADD(L)");

        // SUB (low) / OR (high)
        ALUOpA = 3'b000; // SUB low
        ALUOpB = 3'b010; // OR high
        ALUCtrl = 6'b000001;
        #5; check_result({(a[63:32]|b[63:32]), (a[31:0]-b[31:0])}, "Split OR(H)/SUB(L)");

        // AND (low) / XOR (high)
        ALUOpA = 3'b001;
        ALUOpB = 3'b011;
        #5; check_result({(a[63:32]^b[63:32]), (a[31:0]&b[31:0])}, "Split XOR(H)/AND(L)");

        // SRL both halves
        ALUOpA = 3'b100;
        ALUOpB = 3'b100;
        ALUCtrl = 6'b001010;
        b = 64'h0000_0001_0000_0001; // shift by 1 each
        #5; check_result({(a[63:32]>>1),(a[31:0]>>1)}, "Split SRL");

        // SLL both halves
        ALUCtrl = 6'b000000;
        #5; check_result({(a[63:32]<<1),(a[31:0]<<1)}, "Split SLL");

        // SRA both halves
        a = 64'hFFFF_8000_FFFF_8000;
        ALUCtrl = 6'b001111;
        #5; check_result({($signed(a[63:32])>>>1),($signed(a[31:0])>>>1)}, "Split SRA");

        // Comparator split
        a = 64'h0000_0005_0000_000A;
        b = 64'h0000_0005_0000_000B;
        mode = 0;
        #5;
        if (~eqA && eqB && sltA && ultA)
            $display(" [PASS] Split Comparator EQ/LT mix");
        else
            $display(" [FAIL] Split Comparator EQ/LT mix");

        $display("=====================================================");
        $display("              ALU TESTBENCH FINISHED                 ");
        $display("=====================================================");
        $finish;
    end
endmodule
