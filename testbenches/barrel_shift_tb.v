`timescale 1ns / 1ps

module flexible_shifter_structural_tb;

    // DUT inputs
    reg         mode_unified;
    reg         uni_dir, uni_arith;
    reg  [5:0]  uni_amt;

    reg         hi_dir, hi_arith;
    reg  [4:0]  hi_amt;

    reg         lo_dir, lo_arith;
    reg  [4:0]  lo_amt;

    reg  [63:0] in_bus;

    // DUT output
    wire [63:0] out_bus;

    // Instantiate DUT
    flexible_shifter_structural dut (
        .mode_unified(mode_unified),
        .uni_dir(uni_dir),
        .uni_arith(uni_arith),
        .uni_amt(uni_amt),
        .hi_dir(hi_dir),
        .hi_arith(hi_arith),
        .hi_amt(hi_amt),
        .lo_dir(lo_dir),
        .lo_arith(lo_arith),
        .lo_amt(lo_amt),
        .in_bus(in_bus),
        .out_bus(out_bus)
    );

    // Task for unified tests
    task test_unified(
        input [63:0] val,
        input [5:0]  amt,
        input        dir,
        input        arith
    );
    begin
        in_bus       = val;
        uni_amt      = amt;
        uni_dir      = dir;
        uni_arith    = arith;
        mode_unified = 1;

        #5;
        $display("UNIFIED | dir=%0s | arith=%0s | amt=%0d | in=%h | out=%h",
                 (dir ? "RIGHT" : "LEFT"),
                 (arith ? "ARITH" : "LOGIC"),
                 amt, val, out_bus);
    end
    endtask

    // Task for split tests
    task test_split(
        input [63:0] val,
        input [4:0]  hi_amt_t,
        input [4:0]  lo_amt_t,
        input        hi_dir_t,
        input        lo_dir_t,
        input        hi_arith_t,
        input        lo_arith_t
    );
    begin
        in_bus       = val;
        hi_amt       = hi_amt_t;
        lo_amt       = lo_amt_t;
        hi_dir       = hi_dir_t;
        lo_dir       = lo_dir_t;
        hi_arith     = hi_arith_t;
        lo_arith     = lo_arith_t;
        mode_unified = 0;

        #5;
        $display("SPLIT | hi_dir=%0s lo_dir=%0s | hi_amt=%0d lo_amt=%0d | in=%h | out=%h",
                 (hi_dir_t ? "RIGHT" : "LEFT"),
                 (lo_dir_t ? "RIGHT" : "LEFT"),
                 hi_amt_t, lo_amt_t, val, out_bus);
    end
    endtask

    // Stimulus
    initial begin
        $display("============================================");
        $display(" FLEXIBLE SHIFTER STRUCTURAL TESTBENCH START ");
        $display("============================================\n");

        // Test unified 64-bit shifting
        test_unified(64'hFEDC_BA98_7654_3210, 6'd0, 0, 0);
        test_unified(64'hFEDC_BA98_7654_3210, 6'd4, 0, 0);
        test_unified(64'hFEDC_BA98_7654_3210, 6'd8, 1, 0);
        test_unified(64'hFEDC_BA98_7654_3210, 6'd8, 1, 1);
        test_unified(64'h8000_0000_0000_0000, 6'd4, 1, 1);

        $display("\n--------------------------------------------");
        $display(" Switching to split 32-bit mode ");
        $display("--------------------------------------------\n");

        // Test split 32-bit mode (hi/lo independent)
        test_split(64'hFEDC_BA98_7654_3210, 5'd4, 5'd4, 0, 0, 0, 0);
        test_split(64'hFEDC_BA98_7654_3210, 5'd8, 5'd4, 1, 0, 0, 0);
        test_split(64'hFEDC_BA98_7654_3210, 5'd8, 5'd8, 1, 1, 0, 1);
        test_split(64'h8000_0000_F000_0000, 5'd4, 5'd4, 1, 1, 1, 1);

        $display("\n============================================");
        $display(" FLEXIBLE SHIFTER STRUCTURAL TESTBENCH END ");
        $display("============================================");

        $finish;
    end

endmodule
