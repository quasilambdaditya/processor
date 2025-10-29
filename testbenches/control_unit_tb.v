`timescale 1ns/1ps

module control_unit_tb;

    // DUT inputs
    reg  [6:0] opcodeA, opcodeB;
    reg  [2:0] funct3A, funct3B;
    reg  [6:0] funct7A, funct7B;
    reg        mode;

    // DUT outputs
    wire [2:0] ALUOpA, ALUOpB;
    wire [5:0] ALUCtrl;
    wire       ALUSrcA, ALUSrcB;

    // Instantiate DUT
    control_unit dut (
        .opcodeA(opcodeA),
        .opcodeB(opcodeB),
        .funct3A(funct3A),
        .funct3B(funct3B),
        .funct7A(funct7A),
        .funct7B(funct7B),
        .mode(mode),
        .ALUOpA(ALUOpA),
        .ALUOpB(ALUOpB),
        .ALUCtrl(ALUCtrl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB)
    );

    // Local RISC-V constants
    localparam OPC_RTYPE = 7'b0110011;
    localparam OPC_ITYPE = 7'b0010011;
    localparam OPC_LOAD  = 7'b0000011;
    localparam OPC_STORE = 7'b0100011;
    localparam OPC_JALR  = 7'b1100111;
    localparam OPC_NOP   = 7'b0000000;

    localparam F3_ADD_SUB = 3'b000;
    localparam F3_SLL     = 3'b001;
    localparam F3_SRL     = 3'b101;
    localparam F3_SRA     = 3'b101;
    localparam F7_ADD     = 7'b0000000;
    localparam F7_SUB     = 7'b0100000;
    localparam F7_SRL     = 7'b0000000;
    localparam F7_SRA     = 7'b0100000;

    integer i;

    // Display task
    task show;
        input [255:0] instr_name;
        begin
            #1;
            $display("-----------------------------------------------------------");
            $display("Mode=%b | %-12s", mode, instr_name);
            $display("OpcodeA=%b funct3A=%b funct7A=%b | OpcodeB=%b funct3B=%b funct7B=%b",
                     opcodeA, funct3A, funct7A, opcodeB, funct3B, funct7B);
            $display("ALUSrcA=%b ALUSrcB=%b | ALUOpA=%03b ALUOpB=%03b | ALUCtrl=%06b",
                     ALUSrcA, ALUSrcB, ALUOpA, ALUOpB, ALUCtrl);
        end
    endtask

    // Stimulus
    initial begin
        $display("=========== CONTROL UNIT TESTBENCH START ===========");

        // -------------------------------------
        // Unified mode (mode = 1)
        // -------------------------------------
        mode = 1'b1;

        // ADD (R-type)
        opcodeA = OPC_RTYPE; funct3A = F3_ADD_SUB; funct7A = F7_ADD;
        opcodeB = OPC_NOP;   funct3B = F3_ADD_SUB; funct7B = F7_ADD;
        show("ADD");

        // SUB (R-type)
        funct7A = F7_SUB; funct7B = F7_SUB;
        show("SUB");

        // ADDI (I-type)
        opcodeA = OPC_ITYPE; funct3A = F3_ADD_SUB; funct7A = F7_ADD;
        opcodeB = OPC_NOP  ; funct3B = F3_ADD_SUB; funct7B = F7_ADD;
        show("ADDI");

        // LOAD
        opcodeA = OPC_LOAD; funct3A = 3'b010; funct7A = F7_ADD;
        opcodeB = OPC_NOP;  funct3B = 3'b000; funct7B = F7_ADD;
        show("LOAD");

        // STORE
        opcodeA = OPC_STORE; funct3A = 3'b010; funct7A = F7_ADD;
        opcodeB = OPC_NOP  ; funct3B = 3'b000; funct7B = F7_ADD;
        show("STORE");

        // JALR
        opcodeA = OPC_JALR; funct3A = 3'b000; funct7A = F7_ADD;
        opcodeB = OPC_JALR; funct3B = 3'b000; funct7B = F7_ADD;
        show("JALR");

        // SLL
        opcodeA = OPC_RTYPE; funct3A = F3_SLL;     funct7A = F7_ADD;
        opcodeB = OPC_NOP  ; funct3B = F3_ADD_SUB; funct7B = F7_ADD;
        show("SLL/SLLI");

        // SRL
        funct3A = F3_SRL;     funct7A = F7_SRL;
        funct3B = F3_ADD_SUB; funct7B = F7_ADD;
        show("SRL/SRLI");

        // SRA
        funct3A = F3_SRA;     funct7A = F7_SRA;
        funct3B = F3_ADD_SUB; funct7B = F7_ADD;
        show("SRA/SRAI");

        // -------------------------------------
        // Split mode (mode = 0)
        // -------------------------------------
        mode = 1'b0;

        // ADD/SUB variations
        opcodeA = OPC_RTYPE; funct3A = F3_ADD_SUB; funct7A = F7_ADD;
        opcodeB = OPC_RTYPE; funct3B = F3_ADD_SUB; funct7B = F7_SUB;
        show("ADD/SUB Split");

        // SLL vs SRL
        funct3A = F3_SLL; funct7A = F7_ADD;
        funct3B = F3_SRL; funct7B = F7_SRL;
        show("SLL/SRL Split");

        // SRA vs ADDI
        funct3A = F3_SRA; funct7A = F7_SRA;
        opcodeB = OPC_ITYPE; funct3B = F3_ADD_SUB; funct7B = F7_ADD;
       show("SRA/ADDI Split");

        // Mixed LOAD and STORE
        opcodeA = OPC_LOAD; funct3A = 3'b010; funct7A = F7_ADD;
        opcodeB = OPC_STORE; funct3B = 3'b010; funct7B = F7_ADD;
        show("LOAD/STORE Split");

        $display("=========== CONTROL UNIT TESTBENCH END ===========");
        $finish;
    end

endmodule
