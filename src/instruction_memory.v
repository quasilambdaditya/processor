module instruction_memory#(
    parameter ADDR_WIDTH = 10,      // 2^10 = 1024 words
    parameter DATA_WIDTH = 32,
    parameter OFFSET = 512,         // Offset for B region
    parameter TESTING = 0
)(
    input  wire         clk,
    input  wire         mode,   // 1 = unified, 0 = split
    input  wire         enA,
    input  wire         enB,
    input  wire [31:0]  pcA,    // separate PCs
    input  wire [31:0]  pcB,
    output reg  [31:0]  instrA,
    output reg  [31:0]  instrB
);

    // ----------------------------------------------------------------
    // Instruction Memory
    // ----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    generate
    if (TESTING) begin : MEM_INIT
        initial $readmemh("program.hex", ram);
    end
    endgenerate

    // ----------------------------------------------------------------
    // Dual-Port BRAM Read Logic
    // ----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] doutA;
    reg [DATA_WIDTH-1:0] doutB;

    always @(posedge clk) begin
        if (enA)
            doutA <= ram[pcA[ADDR_WIDTH+1:2]];

        if (enB) begin
            if (mode == 0)
                doutB <= ram[(pcB[ADDR_WIDTH+1:2]) + OFFSET];
        end
    end

    // ----------------------------------------------------------------
    // Registered Outputs
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        casez ({mode, enA, enB})
            3'b110: instrA <= doutA;     // Unified
            3'b010: instrA <= doutA;     // Split: A only
            3'b001: instrB <= doutB;     // Split: B only
            3'b011: begin                // Split: both active
                instrA <= doutA;
                instrB <= doutB;
            end
            default: begin
                instrA <= 32'b0;
                instrB <= 32'b0;
            end
        endcase
    end
endmodule
