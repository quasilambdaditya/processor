//`timescale 1ns/1ps

//module processor_tb;

//    reg clk;
//    reg mode;
//    reg [31:0] instrA;
//    reg [31:0] instrB;
//    wire [63:0] result;

//    // Instantiate the DUT
//    processor #(.TESTING(0)) dut (
//        .clk(clk),
//        .mode(mode),
//        .instrA(instrA),
//        .instrB(instrB),
//        .result(result)
//    );

//    // Clock generation
//    initial begin
//        clk = 0;
//        forever #10 clk = ~clk;  // 50 MHz
//    end

//    // Task to apply a pair of instructions
//    task apply_pair;
//        input [31:0] insA;
//        input [31:0] insB;
//        begin
//            instrA = insA;
//            instrB = insB;
//            $display("[%0t] mode=%0b instrA=%h instrB=%h result=%h", 
//                      $time, mode, instrA, instrB, result);
//            //@(posedge clk);
//           //  #21;  // small delay for stability
//            repeat(2) @(posedge clk);
//        end
//    endtask

//    initial begin
//        $dumpfile("processor_tb.vcd");
//        $dumpvars(0, processor_tb);

//        // ----------------------------------------------
//        // UNIFIED MODE TESTS (mode = 1)
//        // ----------------------------------------------
//        mode = 1;
//        $display("\n=== UNIFIED MODE TEST 1 ===");

//        // Perform arithmetic/logic operations sequentially

//        // Program A
//        // addi x1, x0, 324
//        // addi x2, x0, -32
//        // addi x3, x0, 24
//        // sll x4, x1, x3
//        // sra x5, x2, x3
//        // sub x6, x4, x5
//        // xor x5, x2, x4 
//        // lw x2, 4(x1)

//        apply_pair(32'h14400093, 32'h0);
//        apply_pair(32'hfe000113, 32'h0);
//        apply_pair(32'h01800193, 32'h0);
//        apply_pair(32'h00309233, 32'h0);
//        apply_pair(32'h403152b3, 32'h0);
//        apply_pair(32'h40520333, 32'h0);
//        apply_pair(32'h004142b3, 32'h0);
//        apply_pair(32'h0040a103, 32'h0);

//        $display("\n=== UNIFIED MODE TEST 2 ===");

//        // Program B
//        // addi x2, x0, 423
//        // addi x7, x2, 834
//        // sub x6, x2, x7
//        // srli x4, x2, 8
//        // sra x5, x6, x4
//        // add x8, x5, x5
//        // srli x6, x4, 4

//        apply_pair(32'h1a700113, 32'h0);
//        apply_pair(32'h34210393, 32'h0);
//        apply_pair(32'h40710333, 32'h0);
//        apply_pair(32'h00815213, 32'h0);
//        apply_pair(32'h404352b3, 32'h0);
//        apply_pair(32'h00528433, 32'h0);
//        apply_pair(32'h00425313, 32'h0);


//        // ----------------------------------------------
//        // SPLIT MODE TESTS (mode = 0)
//        // ----------------------------------------------
//        mode = 0;
//        $display("\n=== SPLIT MODE TESTS ===");
//        //
        
//        // Give two instructions simultaneously
//        apply_pair(32'h14400093, 32'h1a700113);
//        apply_pair(32'hfe000113, 32'h34210393);
//        apply_pair(32'h01800193, 32'h40710333);
//        apply_pair(32'h00309233, 32'h00815213);
//        apply_pair(32'h403152b3, 32'h404352b3);
//        apply_pair(32'h40520333, 32'h00528433);
//        apply_pair(32'h004142b3, 32'h0041d313);
//        apply_pair(32'h0040a103, 32'h0);
//        //apply_pair(, ADD_X3_X1_X2);
//        //apply_pair(,  AND_X5_X3_X4);
//        //apply_pair(, XOR_X7_X3_X4);

//        $display("\n=== TEST COMPLETE ===");
//        #50;
//        $finish;
//    end

//endmodule
