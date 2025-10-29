`timescale 1ns/1ps

module adder64_tb;

    // DUT inputs
    reg  [63:0] a, b;
    reg         mode;
    reg         sub_uni, sub_lo, sub_hi;
    wire [63:0] sum;
    wire        cout;

    // Instantiate DUT
    adder64 uut (
        .a(a),
        .b(b),
        .mode(mode),
        .sub_uni(sub_uni),
        .sub_lo(sub_lo),
        .sub_hi(sub_hi),
        .sum(sum),
        .cout(cout)
    );

    // Simple task to print output nicely
    task show_result;
        input [127:0] label;
        begin
            $display("%s | mode=%0d sub_uni=%0d sub_lo=%0d sub_hi=%0d", 
                     label, mode, sub_uni, sub_lo, sub_hi);
            $display("A      = %h", a);
            $display("B      = %h", b);
            $display("SUM    = %h", sum);
            $display("COUT   = %b", cout);
            $display("---------------------------------------------");
        end
    endtask

    initial begin
        $dumpfile("adder64_tb.vcd");
        $dumpvars(0, adder64_tb);

        // -----------------------------------------------------
        // Test 1: Split mode (independent add)
        // -----------------------------------------------------
        mode     = 0;
        sub_uni  = 0;
        sub_lo   = 0;
        sub_hi   = 0;
        a        = 64'h0ac415df_aa68322c;
        b        = 64'h9dae164_7f775046a;
        #5 show_result("TEST-CASE 1: Split Add (mode=0)");

        // -----------------------------------------------------
        // Test 2: Split mode (independent subtract)
        // -----------------------------------------------------
        mode     = 0;
        sub_uni  = 0;
        sub_lo   = 1;
        sub_hi   = 1;
        a        = 64'h414583bb_853a87c3;
        b        = 64'hd9b34082_ad5ccb09;
        #5 show_result("TEST-CASE 2: Split Subtract (mode=0)");

        // -----------------------------------------------------
        // Test 3: Unified mode (add)
        // -----------------------------------------------------
        mode     = 1;
        sub_uni  = 0;
        sub_lo   = 0;  // Ignored in mode=1
        sub_hi   = 0;  // Ignored in mode=1
        a        = 64'h47b04b8e_bf12b412;
        b        = 64'h21dd24a1_fc1209b4;
        #5 show_result("TEST-CASE 3: Unified Add (mode=1)");

        // -----------------------------------------------------
        // Test 4: Unified mode (subtract)
        // -----------------------------------------------------
        mode     = 1;
        sub_uni  = 1;
        sub_lo   = 0;
        sub_hi   = 0;
        a        = 64'h725de3d9_9b5c2ace;
        b        = 64'h9658b549_4f694fe0;
        #5 show_result("TEST-CASE 4: Unified Subtract (mode=1)");

        // -----------------------------------------------------
        // Test 5: Mixed Split - Add lower, Sub upper
        // -----------------------------------------------------
        mode     = 0;
        sub_uni  = 0;
        sub_lo   = 0;  // Add low
        sub_hi   = 1;  // Sub high
        a        = 64'h34fe9f98_f20fb46c;
        b        = 64'ha7ad6fbe_7540b53c;
        #5 show_result("TEST-CASE 5: Split Mixed (low add, high sub)");

	// -----------------------------------------------------
        // Test 5: Mixed Split - Add upper, Sub lower 
        // -----------------------------------------------------
        mode     = 0;
        sub_uni  = 0;
        sub_lo   = 1;  // Sub low
        sub_hi   = 0;  // Add high
        a        = 64'h76434e32_c113dcf4;
        b        = 64'h6b9bc2e0_da94169c;
        #5 show_result("TEST-CASE 5: Split Mixed (low sub, high add)");


        $finish;
    end
endmodule

