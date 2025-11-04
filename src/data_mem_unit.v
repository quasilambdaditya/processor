module data_mem_unit(
    input  wire        clk,
    input  wire        mode,

    input  wire [63:0] addr,
    input  wire [63:0] write_data,

    input  wire        ena,        // port A enable (load/store)
    input  wire        wea,        // port A write enable

    input  wire        enb,        // port B enable
    input  wire        web,        // port B write enable

    input  wire [1:0]  read_write_amtA,    // 00=1 byte, 01=2, 10=4, 11=8
    input  wire [1:0]  read_write_amtB,
    input  wire        unsigned_readA,
    input  wire        unsigned_readB,

    output wire [63:0] dout
);

    // ---- write-enable patterns (LSB = byte 0) ----
    reg [7:0] write_enable_patternA, write_enable_patternB;
    always @(*) begin
        case (read_write_amtA)
            2'b00: write_enable_patternA = 8'b00000001; // byte
            2'b01: write_enable_patternA = 8'b00000011; // half
            2'b10: write_enable_patternA = 8'b00001111; // word
            2'b11: write_enable_patternA = 8'b11111111; // dword
            default: write_enable_patternA = 8'b00000000;
        endcase
    end

    always @(*) begin
        case (read_write_amtB)
            2'b00: write_enable_patternB = 8'b00000001;
            2'b01: write_enable_patternB = 8'b00000011;
            2'b10: write_enable_patternB = 8'b00001111;
            default: write_enable_patternB = 8'b00000000;
        endcase
    end

    // ---- column and row extraction ----
    wire [2:0] col_numA = addr[2:0];
    wire [60:0] row_fullA = (mode) ? addr[63:3] : {32'b0, addr[31:3]};    // full row number for A
    wire [2:0] col_numB = (mode) ? 3'b0 : addr[34:32];                    // in mode==0, B's LSBs are addr[32..34]
    wire [60:0] row_fullB = (mode) ? addr[63:3] : addr[63:35];            // full row number for B (in mode==0 it's the upper 32-bit addr shifted >>3)

    // ---- 8-bit write-enable after rotation (circular left by col_num) ----
    wire [7:0] shifted_weA = (write_enable_patternA << col_numA) | (write_enable_patternA >> (8 - col_numA));
    wire [7:0] shifted_weB = (write_enable_patternB << col_numB) | (write_enable_patternB >> (8 - col_numB));

    // ---- shift amounts in bits (col * 8) ----
    wire [5:0] col_shiftA = {3'b000, col_numA} << 3; // col_numA * 8
    wire [5:0] col_shiftB = {3'b000, col_numB} << 3;
    wire [5:0] col_shiftA_rev = 6'd64 - col_shiftA;
    wire [5:0] col_shiftB_rev = 6'd64 - col_shiftB;

    // ---- prepare 64-bit write lanes (in mode==0, each core occupies its half) ----
    wire [63:0] din64A = (mode) ? write_data : {32'b0, write_data[31:0]};       // A writes into low half when dual-core
    wire [63:0] din64B = (mode) ? write_data : {write_data[63:32], 32'b0};      // B writes into high half when dual-core

    // ---- rotate (circular left) into 64-bit aligned lanes ----
    wire [63:0] din64A_rot = (din64A << col_shiftA) | (din64A >> col_shiftA_rev);
    wire [63:0] din64B_rot = (din64B << col_shiftB) | (din64B >> col_shiftB_rev);

    // ---- memory instance outputs (unrotated raw) ----
    wire [63:0] unshifted_output_dataA;
    wire [63:0] unshifted_output_dataB;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : dmem_cols
            // compute column-aware row addresses and carry for adders
            // For unified 64-bit (mode==1) we use the low 10 bits of row_fullX (row_fullX[9:0])
            // For dual-core (mode==0), map A to rows 0..511 and B to rows 512..1023
            wire [9:0] addra_base = (mode) ? row_fullA[9:0] : {1'b0, row_fullA[8:0]}; // 10-bit
            wire [9:0] addrb_base = (mode) ? row_fullB[9:0] : {1'b1, row_fullB[8:0]}; // 10-bit (upper half)

            wire [9:0] addra = addra_base + ((i < col_numA) ? 10'd1 : 10'd0);
            wire [9:0] addrb = addrb_base + ((i < col_numB) ? 10'd1 : 10'd0);

            // 8-bit slices from rotated 64-bit din lanes
            wire [7:0] dina_byte = din64A_rot[(i*8)+:8];
            wire [7:0] dinb_byte = din64B_rot[(i*8)+:8];

            // write enables per byte lane (wea/web signals combined with shifted pattern bits)
            wire wea_i = wea & shifted_weA[i];
            wire web_i = web & shifted_weB[i];

            blk_mem_gen_1 dmemColInst (
                .clka(clk),
                .clkb(clk),
                .ena(ena),
                .enb(enb),
                .wea(wea_i),
                .web(web_i),
                .addra(addra),
                .addrb(addrb),
                .dina(dina_byte),
                .dinb(dinb_byte),
                .douta(unshifted_output_dataA[(i*8)+:8]),
                .doutb(unshifted_output_dataB[(i*8)+:8])
            );
        end
    endgenerate


    wire [63:0] read_data_no_zA = unshifted_output_dataA | 64'b0;
    wire [63:0] read_data_no_zB = unshifted_output_dataB | 64'b0;

    // ---- rotate read data right by col_shift to recover logical word ----
    reg [63:0] true_read_dataA;
    reg [63:0] true_read_dataB;

    always @(*) begin
        true_read_dataA = (read_data_no_zA >> col_shiftA) | (read_data_no_zA << col_shiftA_rev);
        case (read_write_amtA)
            2'b00: true_read_dataA[63:8]  = unsigned_readA ? 56'b0 : {56{true_read_dataA[7]}};
            2'b01: true_read_dataA[63:16] = unsigned_readA ? 48'b0 : {48{true_read_dataA[15]}};
            2'b10: true_read_dataA[63:32] = unsigned_readA ? 32'b0 : {32{true_read_dataA[31]}};
        endcase
    end

    always @(*) begin
        true_read_dataB = (read_data_no_zB >> col_shiftB) | (read_data_no_zB << col_shiftB_rev);
        case (read_write_amtB)
            2'b00: true_read_dataB[63:8]  = unsigned_readB ? 56'b0 : {56{true_read_dataB[7]}};
            2'b01: true_read_dataB[63:16] = unsigned_readB ? 48'b0 : {48{true_read_dataB[15]}};
            2'b10: true_read_dataB[63:32] = unsigned_readB ? 32'b0 : {32{true_read_dataB[31]}};
        endcase
    end

    // ---- output composition: unified -> A's 64-bit result; dual-core -> {B[31:0], A[31:0]} ----
    assign dout = (mode) ? true_read_dataA : {true_read_dataB[31:0], true_read_dataA[31:0]};

endmodule
