//module full_adder_1(
//	input wire a,
//	input wire b,
//	input wire cin,
	
//	output wire sum,
//	output wire cout
//);
//	assign sum = (a ^ b) ^ cin;
//	assign cout = (a & b) | (b & cin) | (a & cin);
//endmodule

//module adder32 (
//    input  wire [31:0] a,
//    input  wire [31:0] b,
//    input  wire cin,
//    input  wire sub,                // 0 = add, 1 = subtract
//    output wire [31:0] sum, 
//    output wire cout
//);
//    wire [31:0] b_xor;              // modified B input
//    assign b_xor = b ^ {32{sub}};   // invert B if subtracting

//    wire [32:0] carry;
//    assign carry[0] = cin;    // use sub as starting carry-in when subtracting

//    genvar i;
//    generate 
//        for (i = 0; i < 32; i = i + 1) begin : upper_loop
//            full_adder_1 inst (
//                .a(a[i]),
//                .b(b_xor[i]),
//                .cin(carry[i]),
//                .sum(sum[i]),
//                .cout(carry[i+1])
//            );
//        end
//    endgenerate

//    assign cout = carry[32];
//endmodule

//module adder64 (
//    input  wire [63:0] a,
//    input  wire [63:0] b,
//    input  wire mode,      // 1 = unified, 0 = split
//    input  wire sub_uni,
//    input  wire sub_lo,
//    input  wire sub_hi,
//    output wire [63:0] sum, 
//    output wire cout
//);
//    wire carry_link;
//    wire sub_sig_lo = (mode == 1'b1) ? sub_uni : sub_lo;
//    wire sub_sig_hi = (mode == 1'b1) ? sub_uni : sub_hi;

//    adder32 lo_add (
//        .a(a[31:0]),
//        .b(b[31:0]),
//        .cin(sub_sig_lo),            // initial carry = sub
//        .sub(sub_sig_lo),
//        .sum(sum[31:0]),
//        .cout(carry_link)
//    );

//    // If mode=1, propagate carry to upper 32 bits
//    assign mid_carry = (mode == 1'b1) ? carry_link : sub_sig_hi;
	
//    // Upper 32-bit section
//    adder32 hi_add (
//        .a(a[63:32]),
//        .b(b[63:32]),
//        .cin(mid_carry),
//        .sub(sub_sig_hi),
//        .sum(sum[63:32]),
//        .cout(cout)
//    );
//endmodule

// =======================
// 32-bit Adder/Subtractor
// =======================

module adder32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,      // external carry-in (or 'sub' for low half when subtracting)
    input  wire        sub,      // 0 = add, 1 = subtract
    output wire [31:0] sum,
    output wire        cout
);
    wire [32:0] result33;
    assign result33 = {1'b0, a} + ({1'b0, b} ^ {33{sub}}) + cin;

    assign sum  = result33[31:0];
    assign cout = result33[32];
endmodule



// ==========================
// 64-bit Split/Unified Adder 
// ==========================
module adder64(
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire        mode,      // 1 = unified, 0 = split
    input  wire        sub_uni,
    input  wire        sub_lo,
    input  wire        sub_hi,
    output wire [63:0] sum,
    output wire        cout
);
    wire cout_lo;
    wire cout_hi;

    // select which sub signals apply depending on mode
    wire sub_sig_lo = mode ? sub_uni : sub_lo;
    wire sub_sig_hi = mode ? sub_uni : sub_hi;

    // lower 32-bit adder
    (* use_dsp = "yes" *) adder32 lo_add (
        .a   (a[31:0]),
        .b   (b[31:0]),
        .cin (sub_sig_lo),  // +1 for subtraction
        .sub (sub_sig_lo),
        .sum (sum[31:0]),
        .cout(cout_lo)
    );

    wire mid_carry = mode 
                     ? (sub_uni ? ~cout_lo : cout_lo)  // invert carry for subtraction
                     : sub_sig_hi;

    (* use_dsp = "yes" *) adder32 hi_add (
        .a   (a[63:32]),
        .b   (b[63:32]),
        .cin (mid_carry),
        .sub (sub_sig_hi),
        .sum (sum[63:32]),
        .cout(cout_hi)
    );

    assign cout = mode ? (sub_uni ? ~cout_hi : cout_hi) : cout_hi;
endmodule
