`timescale 1ns/1ps

module immediate_gen_tb;
    reg  [31:0] instrA;
    reg  [31:0] instrB;
    wire [63:0] immA;
    wire [63:0] immB;

    // DUT instance
    immediate_gen uut (
        .instrA(instrA),
        .instrB(instrB),
        .immA(immA),
        .immB(immB)
    );

    initial begin
        $display("===============================================");
        $display("     RISC-V Immediate Generation Testbench     ");
        $display("===============================================");

        // -------------------------
        // I-type tests
        // -------------------------
        instrA = 32'b000000000101_00010_000_00001_0010011; // addi x1,x2,5
        instrB = 32'b111111111011_00011_100_00001_0010011; // xori x1,x3,-5
        #1 $display("I-type  : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        // -------------------------
        // Load (I-type)
        // -------------------------
        instrA = 32'b000000000100_00010_010_00001_0000011; // lw x1,4(x2)
        instrB = 32'b111111111100_00011_000_00001_0000011; // lb x1,-4(x3)
        #1 $display("Load    : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        // -------------------------
        // Store (S-type)
        // -------------------------
        instrA = 32'b0000000_00101_00010_010_00100_0100011; // sw x5,4(x2)
        instrB = 32'b1111111_00101_00011_010_00100_0100011; // sw x5,-4(x3)
        #1 $display("Store   : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        // -------------------------
        // Branch (B-type)
        // -------------------------
        instrA = 32'b0_000000_00011_00010_000_00100_1100011; // beq x2,x3,4
        instrB = 32'b1_000000_00011_00010_000_00100_1100011; // beq x2,x3,-4
        #1 $display("Branch  : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        // -------------------------
        // LUI (U-type)
        // -------------------------
        instrA = 32'b00000000000000000001_00001_0110111; // lui x1,0x1
        instrB = 32'b11111111111111111111_00001_0110111; // lui x1,0xFFFFF
        #1 $display("LUI     : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        // -------------------------
        // JAL (J-type)
        // -------------------------
        instrA = 32'b00000000001000000001_000001101111; // jal x0, 4098
        instrB = 32'b00000001011000000000_000001101111; // jal x0, 22
        #1 $display("JAL     : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        // -------------------------
        // JALR (I-type)
        // -------------------------
        instrA = 32'b000000000100_00010_000_00001_1100111; // jalr x1,4(x2)
        instrB = 32'b111111111100_00010_000_00001_1100111; // jalr x1,-4(x2)
        #1 $display("JALR    : immA=%0d immB=%0d", $signed(immA), $signed(immB));

        $display("===============================================");
        $finish;
    end
endmodule
