`timescale 1ns/1ps

module ALU_tb;

    reg  [63:0] a, b;
    reg         mode;
    reg  [2:0]  ALUOpA, ALUOpB;
    reg  [5:0]  ALUCtrl;
    wire [63:0] result;

    // Instantiate DUT
    ALU dut (
        .a(a),
        .b(b),
        .mode(mode),
        .ALUOpA(ALUOpA),
        .ALUOpB(ALUOpB),
        .ALUCtrl(ALUCtrl),
        .result(result)
    );

    // Task for formatted display
    task show_result;
        input [1023:0] name; // Allow full test name
        begin
            #1;
            $display("\n[%0t ns] TEST: %0s", $time, name);
            $display("  Mode    : %b", mode);
            $display("  ALUOpA  : %b", ALUOpA);
            $display("  ALUOpB  : %b", ALUOpB);
            $display("  ALUCtrl : %b", ALUCtrl);
            $display("  A       : 0x%016h", a);
            $display("  B       : 0x%016h", b);
            $display("  Result  : 0x%016h", result);
            $display("------------------------------------------------------------");
        end
    endtask    initial begin

        $dumpfile("alu_tb.vcd");
        $dumpvars(0, ALU_tb);
        $display("===== STARTING SEQUENTIAL ALU TESTS =====");

        // ========================================
        // UNIFIED MODE TESTS (mode = 1)
        // ========================================
        mode = 1'b1;

        // ADD
        a = 64'h0000_0000_0000_0003;
        b = 64'h0000_0000_0000_0004;
        ALUOpA = 3'b000; ALUOpB = 3'b000; ALUCtrl = 6'b000000;
        #10; show_result("UNIFIED ADD (a+b)");

        // SUB (set sub_uni = ALUCtrl[4])
        a = 64'h0000_0000_0000_0009;
        b = 64'h0000_0000_0000_0005;
        ALUOpA = 3'b000; ALUCtrl = 6'b010000;
        #10; show_result("UNIFIED SUB (a-b)");

        // AND
        a = 64'hFFFF_0000_FFFF_0000;
        b = 64'h0F0F_F0F0_0F0F_F0F0;
        ALUOpA = 3'b001; ALUCtrl = 6'b000000;
        #10; show_result("UNIFIED AND");

        // OR
        a = 64'h1234_5678_0000_FFFF;
        b = 64'hFFFF_0000_1111_2222;
        ALUOpA = 3'b010;
        #10; show_result("UNIFIED OR");

        // XOR
        a = 64'hAAAA_BBBB_CCCC_DDDD;
        b = 64'hFFFF_0000_0000_FFFF;
        ALUOpA = 3'b011;
        #10; show_result("UNIFIED XOR");

        // Shift Left Logical
        a = 64'h0000_0000_0000_00FF;
        b = 64'h0000_0000_0000_0004;
        ALUOpA = 3'b100; ALUCtrl = 6'b000000;
        #10; show_result("UNIFIED SHIFT LEFT LOGICAL");

        // Shift Right Logical
        a = 64'h8000_0000_0000_0000;
        b = 64'h0000_0000_0000_0004;
        ALUOpA = 3'b100; ALUCtrl = 6'b100000;
        #10; show_result("UNIFIED SHIFT RIGHT LOGICAL");

        // Shift Right Arithmetic
        a = 64'h8000_0000_0000_0000;
        b = 64'h0000_0000_0000_0004;
        ALUOpA = 3'b100; ALUCtrl = 6'b110000;
        #10; show_result("UNIFIED SHIFT RIGHT ARITHMETIC");

        // ========================================
        // SPLIT MODE TESTS (mode = 0)
        // ========================================
        mode = 1'b0;
        a = 64'hFFFF_0000_DEAD_BEEF;
        b = 64'h0000_0004_0000_0001;

        // Lower half ADD, Upper half AND
        ALUOpA = 3'b000; ALUOpB = 3'b001; ALUCtrl = 6'b000000;
        #10; show_result("SPLIT: lower=ADD, upper=AND");

        // Lower half OR, Upper half XOR
        ALUOpA = 3'b010; ALUOpB = 3'b011;
        #10; show_result("SPLIT: lower=OR, upper=XOR");

        // Lower half Shift Left, Upper half Shift Right Arithmetic
        // hi_dir=1, hi_arith=1, lo_dir=0, lo_arith=0 → 6’b001100
        ALUOpA = 3'b100; ALUOpB = 3'b100; ALUCtrl = 6'b001100;
        #10; show_result("SPLIT: lower=SHIFT LEFT, upper=SHIFT RIGHT ARITH");

        // Lower half ADD, Upper half SUB (sub_hi bit = ALUCtrl[2])
        ALUOpA = 3'b000; ALUOpB = 3'b000; ALUCtrl = 6'b000100;
        #10; show_result("SPLIT: lower=ADD, upper=SUB");

        // Edge Case: All 1s + 1
        a = 64'hFFFF_FFFF_FFFF_FFFF;
        b = 64'h0000_0000_0000_0001;
        ALUOpA = 3'b000; ALUOpB = 3'b000; ALUCtrl = 6'b000000;
        #10; show_result("EDGE CASE: overflow wrap-around");

        $display("===== ALL TESTS COMPLETE =====");
        $finish;
    end

endmodule
