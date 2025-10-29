`timescale 1ns/1ps

module tb_branch_decider;

    // DUT inputs
    reg        mode;
    reg  [2:0] branch_typeA, branch_typeB;
    reg        eqA, sltA, ultA;
    reg        eqB, sltB, ultB;

    // DUT outputs
    wire branch_takenA;
    wire branch_takenB;

    // Instantiate DUT
    branch_decider dut (
        .mode(mode),
        .branch_typeA(branch_typeA),
        .branch_typeB(branch_typeB),
        .eqA(eqA), .sltA(sltA), .ultA(ultA),
        .eqB(eqB), .sltB(sltB), .ultB(ultB),
        .branch_takenA(branch_takenA),
        .branch_takenB(branch_takenB)
    );

    // Branch types
    localparam BEQ  = 3'b000;
    localparam BNE  = 3'b001;
    localparam BLT  = 3'b010;
    localparam BGE  = 3'b011;
    localparam BLTU = 3'b100;
    localparam BGEU = 3'b101;

    integer pass_count = 0;
    integer fail_count = 0;

    // Helper task for checking
    task check_result;
        input [1023:0] testname; // allow long names
        input condition;
        reg [1023:0] t;          // local copy for safety
        begin
            t = testname;
            if (condition) begin
                $display(" PASS: %0s", t);
                pass_count = pass_count + 1;
            end else begin
                $display(" FAIL: %0s", t);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("\n=========================================================");
        $display("                BRANCH DECIDER TESTBENCH START");
        $display("=========================================================");

        // =====================================================
        // Unified mode (mode = 1)
        // =====================================================
        mode = 1'b1;

        // -- BEQ --
        branch_typeA = BEQ; eqA = 1; sltA = 0; ultA = 0;
        #1 check_result("Unified BEQ taken (A)", branch_takenA == 1 && branch_takenB == 0);
        eqA = 0; #1 check_result("Unified BEQ not taken (A)", branch_takenA == 0);

        // -- BNE --
        branch_typeA = BNE; eqA = 0;
        #1 check_result("Unified BNE taken (A)", branch_takenA == 1);
        eqA = 1; #1 check_result("Unified BNE not taken (A)", branch_takenA == 0);

        // -- BLT --
        branch_typeA = BLT; sltA = 1;
        #1 check_result("Unified BLT taken (A)", branch_takenA == 1);
        sltA = 0; #1 check_result("Unified BLT not taken (A)", branch_takenA == 0);

        // -- BGE --
        branch_typeA = BGE; sltA = 0;
        #1 check_result("Unified BGE taken (A)", branch_takenA == 1);
        sltA = 1; #1 check_result("Unified BGE not taken (A)", branch_takenA == 0);

        // -- BLTU --
        branch_typeA = BLTU; ultA = 1;
        #1 check_result("Unified BLTU taken (A)", branch_takenA == 1);
        ultA = 0; #1 check_result("Unified BLTU not taken (A)", branch_takenA == 0);

        // -- BGEU --
        branch_typeA = BGEU; ultA = 0;
        #1 check_result("Unified BGEU taken (A)", branch_takenA == 1);
        ultA = 1; #1 check_result("Unified BGEU not taken (A)", branch_takenA == 0);

        // =====================================================
        // Split mode (mode = 0)
        // =====================================================
        mode = 1'b0;

        // A-side: BEQ, B-side: BLT
        branch_typeA = BEQ; eqA = 1;
        branch_typeB = BLT; sltB = 1;
        #1 check_result("Split mode BEQ (A) + BLT (B)", branch_takenA == 1 && branch_takenB == 1);

        // A-side: BNE (not equal), B-side: BGEU
        branch_typeA = BNE; eqA = 1;   // not taken
        branch_typeB = BGEU; ultB = 1; // not taken
        #1 check_result("Split mode BNE (A) + BGEU (B)", branch_takenA == 0 && branch_takenB == 0);

        // A-side: BLTU, B-side: BGE
        branch_typeA = BLTU; ultA = 0; // not taken
        branch_typeB = BGE; sltB = 0;  // taken
        #1 check_result("Split mode BLTU (A) + BGE (B)", branch_takenA == 0 && branch_takenB == 1);

        // =====================================================
        // Summary
        // =====================================================
        $display("\n========================================================");
        $display("                     TEST SUMMARY");
        $display("=========================================================");
        $display("     Passed : %0d", pass_count);
        $display("     Failed : %0d", fail_count);
        $display("=========================================================");
        if (fail_count == 0)
            $display(" ALL TESTS PASSED SUCCESSFULLY!");
        else
            $display("  SOME TESTS FAILED. CHECK LOG ABOVE.");
        $display("=========================================================\n");

        $finish;
    end

endmodule
