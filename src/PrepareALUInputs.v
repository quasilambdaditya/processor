//module PrepareALUInputs (
//	input wire [63:0] rs1A,
//	input wire [63:0] rs2A, 
//	input wire [63:0] rs1B,
//	input wire [63:0] rs2B,
//	input wire mode,

//	output wire [63:0] outputA,
//	output wire [63:0] outputB
//);

//    assign outputA = (mode == 1) ? rs1A : {rs1B[63:32], rs1A[31:0]};
//    assign outputB = (mode == 1) ? rs2A : {rs2B[63:32], rs2A[31:0]};

//endmodule

module PrepareALUInputs (
    input  wire [63:0] rs1A,
    input  wire [63:0] rs2A,
    input  wire [63:0] rs1B,
    input  wire [63:0] rs2B,
    input  wire        mode,
    input  wire        ALUSrcB,            // NEW

    output wire [63:0] outputA,
    output wire [63:0] outputB
);

    // A: lower 32 from rs1A, upper 32 from rs1B (register always lives in [63:32])
    assign outputA = (mode == 1) ? rs1A : { rs1B[63:32], rs1A[31:0] };

    // B: choose the correct 32-bit field for the upper word:
    //   - if ALUSrcB == 1 (immediate), the immediate is in rs2B[31:0]
    //   - else (register) the desired 32-bit reg half is rs2B[63:32]
    wire [31:0] b_upper = (ALUSrcB) ? rs2B[31:0] : rs2B[63:32];

    assign outputB = (mode == 1) ? rs2A : { b_upper, rs2A[31:0] };

endmodule
