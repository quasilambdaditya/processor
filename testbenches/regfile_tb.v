`timescale 1ns/1ps

module register_file_tb;
    reg clk, mode;
    reg write_enA, write_enB;
    reg [4:0] rdA, rdB, rs1A, rs2A, rs1B, rs2B;
    reg [63:0] write_data;
    wire [63:0] read_dataA1, read_dataA2, read_dataB1, read_dataB2;

    // DUT
    register_file dut (
        .clk(clk), .mode(mode),
        .write_enA(write_enA), .write_enB(write_enB),
        .rdA(rdA), .rdB(rdB),
        .write_data(write_data),
        .rs1A(rs1A), .rs2A(rs2A),
        .rs1B(rs1B), .rs2B(rs2B),
        .read_dataA1(read_dataA1), .read_dataA2(read_dataA2),
        .read_dataB1(read_dataB1), .read_dataB2(read_dataB2)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Helper task to print registers
    task dump_regs;
        integer i;
        begin
            $display("\n---- REGISTER FILE STATE ----");
            for (i = 0; i < 32; i = i + 1)
                $display("x%-2d = %016h", i, dut.regfile[i]);
        end
    endtask

    // -------------------------------
    // TEST SEQUENCE
    // -------------------------------
    initial begin
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, register_file_tb);
        clk = 0; mode = 0;
        write_enA = 0; write_enB = 0;
        rdA = 0; rdB = 0; write_data = 0;
        rs1A = 0; rs2A = 0; rs1B = 0; rs2B = 0;
        #10;

        $display("\n====================================");
        $display(" REGISTER FILE EXTENSIVE TESTBENCH ");
        $display("====================================");
	// ---- TEST 1: SPLIT MODE BASIC ----
	mode = 0;

	// Write to Reg1 (low=A000, high=B000)
	write_enA = 1; write_enB = 1;
	rdA = 5'd1; rdB = 5'd1;
	write_data = 64'hFACE_B000_BEEF_A000;
	#10;
	write_enA = 0; write_enB = 0;

	// Write to Reg2 (low=0001, high=0002)
	write_enA = 1; write_enB = 1;
	rdA = 5'd2; rdB = 5'd2;
	write_data = 64'hDEAD_0002_CAFE_0001;
	#10;
	write_enA = 0; write_enB = 0;
        dump_regs();

        if (dut.regfile[1] !== 64'hFACE_B000_BEEF_A000 ||
            dut.regfile[2] !== 64'hDEAD_0002_CAFE_0001)
            $display("FAIL: Split mode mismatch");
        else
            $display("PASS: Split mode basic OK");

        // ---- TEST 2: WRITE TO x0 ----
        mode = 0;
        write_enA = 1; rdA = 5'd0; write_data = 64'hFFFF_FFFF_FFFF_FFFF;
        #10; write_enA = 0;
        if (dut.regfile[0] !== 64'd0)
            $display("FAIL: x0 modified!");
        else
            $display("PASS: x0 remained zero.");

        // ---- TEST 3: SUCCESSIVE WRITES ----
        mode = 0;
        rdA = 5'd4; rdB = 5'd4;
        write_enA = 1; write_enB = 1;
        write_data = 64'hBBBB_2222_AAAA_1111;
        #10;
        write_data = 64'hBBBB_2222_CCCC_3333;
        #10;
        write_enA = 0; write_enB = 0;
        if (dut.regfile[4][31:0] !== 32'hCCCC_3333)
            $display("FAIL: Successive write mismatch");
        else
            $display("PASS: Successive write OK");

        // ---- TEST 4: UNIFIED MODE ----
        mode = 1;
        write_enA = 1; rdA = 5'd5;
        write_data = 64'hABCD_1234_5678_9ABC;
        #10; write_enA = 0;
        if (dut.regfile[5] !== 64'hABCD_1234_5678_9ABC)
            $display("FAIL: Unified write mismatch");
        else
            $display("PASS: Unified mode write OK");

        // ---- TEST 5: MODE SWITCH ----
        mode = 0;
        write_enA = 1; write_enB = 1;
        rdA = 5'd6; rdB = 5'd6;
        write_data = 64'h5555_6666_3333_4444;
        #10; write_enA = 0; write_enB = 0;
        if (dut.regfile[6][31:0] !== 32'h3333_4444 ||
            dut.regfile[6][63:32] !== 32'h5555_6666)
            $display("FAIL: Mode switch partial write mismatch");
        else
            $display("PASS: Mode switch partial write OK");

        // ---- TEST 6: READ-AFTER-WRITE ----
        mode = 1;
        write_enA = 1; rdA = 5'd7;
        write_data = 64'hFACE_1234_BEEF_5678;
        rs1A = 5'd7;
        @(posedge clk);
	#1;
	if (read_dataA1 !== 64'hFACE_1234_BEEF_5678)
	    $display("FAIL: Read-after-write mismatch");
	else
	    $display("PASS: Read-after-write OK");
	write_enA = 0;
	// ---- TEST 7: RANDOM STRESS ---
        mode = 0;
        repeat (8) begin
            write_enA = 1; write_enB = 1;
            rdA = $urandom_range(1,7);
            rdB = $urandom_range(1,7);
            write_data = {$urandom, $urandom};
            #10;
        end
        write_enA = 0; write_enB = 0;
        dump_regs();
        $display("Randomized writes done.");

        $display("\nALL TESTS COMPLETED.\n");
        $finish;
    end
endmodule
