`timescale 1ns/1ps

module shift64_tb;
    // DUT Inputs
    reg         mode_unified;
    reg         uni_dir;
    reg         uni_arith;
    reg  [11:0]  shift_amt;

    reg         hi_dir;
    reg         hi_arith;
    reg         lo_dir;
    reg         lo_arith;

    reg  [63:0] in_bus;
    wire [63:0] out_bus;

    // DUT Instantiation
    shift64 dut (
        .mode_unified(mode_unified),
        .uni_dir(uni_dir),
        .uni_arith(uni_arith),
        .shift_amt(shift_amt),
        .hi_dir(hi_dir),
        .hi_arith(hi_arith),
        .lo_dir(lo_dir),
        .lo_arith(lo_arith),
        .in_bus(in_bus),
        .out_bus(out_bus)
    );

    // Simple task for displaying
    task show_result;
        input [127:0] label;
        begin
            $display("\n----------------------------------------------------\n");
            $display("\n%s\n", label);
            $display("\nmode_unified = %0d | uni_dir = %0d | uni_arith = %0d | shift_amt = %0d\n",
                     mode_unified, uni_dir, uni_arith, shift_amt);
            $display("\nhi_dir = %0d | lo_dir = %0d | hi_arith = %0d | lo_arith = %0d\n",
                     hi_dir, lo_dir, hi_arith, lo_arith);
            $display("\nInput  = %h\n", in_bus);
            $display("\nOutput = %h\n", out_bus);
            $display("----------------------------------------------------\n");
        end
    endtask

    initial begin
        $dumpfile("shift64.vvp");
        $dumpvars(0, shift64_tb);

        // ===============================
        // Test 1: Split mode, independent 32-bit shifts
        // ===============================
        mode_unified = 0;
        in_bus = 64'hFEDCBA9876543210;

        // lower: left shift by 3, higher: right arithmetic by 2
        lo_dir = 0; lo_arith = 0;
        hi_dir = 1; hi_arith = 1;
        shift_amt = {6'd2, 6'd3};
        #5 show_result("\nSPLIT MODE | hi: right arith(2), lo: left(3)\n");

        // lower: right logical by 4, higher: left by 1
        lo_dir = 1; lo_arith = 0;
        hi_dir = 0; hi_arith = 0;
        shift_amt = {6'd1, 6'd4};
        #5 show_result("\nSPLIT MODE | hi: left(1), lo: right(4)\n");
        
        // (Noisy Control) lower: right logical by 4, higher: left by 1
        uni_dir = 1; uni_arith = 0; shift_amt = 12'd5;
        lo_dir = 1; lo_arith = 0;
        hi_dir = 0; hi_arith = 0;
        shift_amt = {6'd1, 6'd4};
        #5 show_result("\nNOISY CONTROL SPLIT MODE | hi: left(1), lo: right(4)\n");


        // ===============================
        // Test 2: Unified mode (64-bit)
        // ===============================
        mode_unified = 1;
        in_bus = 64'hFEDCBA9876543210;

        // 64-bit left shift by 0
        uni_dir = 0; uni_arith = 0; shift_amt = 12'd0;
        #5 show_result("\nUNIFIED MODE | Left shift 0\n");

        // 64-bit left shift by 4
        uni_dir = 0; uni_arith = 0; shift_amt = 12'd4;
        #5 show_result("\nUNIFIED MODE | Left shift 4\n");

        // 64-bit left shift by 40 (crosses 32-bit boundary)
        uni_dir = 0; uni_arith = 0; shift_amt = 12'd40;
        #5 show_result("\nUNIFIED MODE | Left shift 40\n");

        // 64-bit right logical by 5
        uni_dir = 1; uni_arith = 0; shift_amt = 12'd5;
        #5 show_result("\nUNIFIED MODE | Right logical shift 5\n");

        // 64-bit right logical by 35 (cross 32-bit boundary)
        uni_dir = 1; uni_arith = 0; shift_amt = 12'd35;
        #5 show_result("\nUNIFIED MODE | Right logical shift 35\n");

        // 64-bit right arithmetic by 10 (sign bit propagation)
        in_bus = 64'hF0000000A0000000; // sign bit = 1
        uni_dir = 1; uni_arith = 1; shift_amt = 12'd10;
        #5 show_result("\nUNIFIED MODE | Right arithmetic shift 10 (sign extend)\n");

        // 64-bit right arithmetic by 40 (cross boundary + sign extend)
        uni_dir = 1; uni_arith = 1; shift_amt = 12'd40;
        #5 show_result("\nUNIFIED MODE | Right arithmetic shift 40\n");

        // 64-bit right arithmetic by 63 (extreme)
        uni_dir = 1; uni_arith = 1; shift_amt = 12'd63;
        #5 show_result("\nUNIFIED MODE | Right arithmetic shift 63\n");

        // 64-bit right arithmetic by 63 (extreme)
        uni_dir = 1; uni_arith = 1; shift_amt = 12'd63;
        lo_dir = 1; lo_arith = 0;
        hi_dir = 0; hi_arith = 0;

        #5 show_result("\nUNIFIED MODE with noisy control | Right arithmetic shift 63\n");


        // ===============================
        // Done
        // ===============================
        $display("All test cases executed.");
        $finish;
    end

endmodule
