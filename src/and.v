// ===========
// 64-bit AND
// ===========
module andUnit(
	input wire  [63:0] a,
	input wire  [63:0] b,

	output wire [63:0] result
);
	assign result = a & b;
endmodule
