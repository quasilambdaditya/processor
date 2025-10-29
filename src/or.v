// ===========
// 64-bit OR
// ===========
module orUnit(
	input wire  [63:0] a,
	input wire  [63:0] b,

	output wire [63:0] result
);
	assign result = a | b;
endmodule
