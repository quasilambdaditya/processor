// =============================================
// 64-bit ALU
// Supports and or, xor, add, sub, sll, srl, sra 
// Inputs:
//     a, b  : Outputs of PrepareALUInputs
//     ALUOp : Output of ALUControl
//     mode  : From CSR
// =============================================

module ALU (
	input wire  [63:0] a,
	input wire  [63:0] b,
	input wire         mode,
	input wire  [2:0]  ALUOpA, 
	input wire  [2:0]  ALUOpB, 
	input wire  [5:0]  ALUCtrl,    // To specify shift direction, add/sub etc
	output wire [63:0] result,
    output wire eqA,
    output wire sltA,
    output wire ultA,
    output wire eqB,
    output wire sltB,
    output wire ultB
);
	wire [63:0] addRes;
	wire [63:0] andRes;
	wire [63:0] orRes;
	wire [63:0] xorRes;
	wire [63:0] shiftRes;
	wire [11:0] shiftAmt;
	assign shiftAmt = {b[37:32], b[5:0]};
	adder64 adderInst(
		.a       (a),
		.b       (b),
		.mode    (mode),
		.sub_uni (ALUCtrl[4]),
		.sub_hi  (ALUCtrl[2]),
		.sub_lo  (ALUCtrl[0]),
		.sum 	 (addRes)
	);

	andUnit andInst(
		.a      (a),
		.b      (b),
		.result (andRes)
	);

	orUnit orInst(
		.a      (a),
		.b      (b),
		.result (orRes)
	);

	xorUnit xorInst(
		.a      (a),
		.b      (b),
		.result (xorRes)
	);

	shift64 shift64Inst(
		.in_bus       (a),
		.shift_amt    (shiftAmt),
		.mode_unified (mode),
		.uni_dir      (ALUCtrl[5]),
		.uni_arith    (ALUCtrl[4]),
		.hi_dir       (ALUCtrl[3]),
		.hi_arith     (ALUCtrl[2]),
		.lo_dir       (ALUCtrl[1]),
		.lo_arith     (ALUCtrl[0]),
		.out_bus      (shiftRes)
	);

    
    comparator64 comparator64Inst(
    .a     (a),
    .b     (b),
    .mode  (mode),
    .eqA   (eqA),
    .sltA  (sltA),
    .ultA  (ultA),
    .eqB   (eqB),
    .sltB  (sltB),
    .ultB  (ultB) 
);   
    wire [63:0] alu_out_A;
    wire [63:0] alu_out_B;

    // unified operation (mode == 1): select entire 64-bit result by ALUOpA
    assign alu_out_A = (ALUOpA == 3'b000) ? addRes :
                       (ALUOpA == 3'b001) ? andRes :
                       (ALUOpA == 3'b010) ? orRes  :
                       (ALUOpA == 3'b011) ? xorRes :
                       (ALUOpA == 3'b100) ? shiftRes : 64'b0;

    // split operation upper half (only used when mode == 0)
    assign alu_out_B = (ALUOpB == 3'b000) ? addRes :
                       (ALUOpB == 3'b001) ? andRes :
                       (ALUOpB == 3'b010) ? orRes  :
                       (ALUOpB == 3'b011) ? xorRes :
                       (ALUOpB == 3'b100) ? shiftRes : 64'b0;

    // final result selection
    assign result = (mode) ? alu_out_A :
                    { alu_out_B[63:32], alu_out_A[31:0] };
endmodule
