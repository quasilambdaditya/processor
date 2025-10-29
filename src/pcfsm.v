module pcfsm(
    input  wire clk,
    output reg  choose   // to choose between next pc or orig pc
);

    // state encoding  0 = next pc, 1 = same pc
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge clk) begin
        next_state = state;
        case (state)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S0;
            default: next_state = S0;
        endcase
    end

    always @(posedge clk) begin
        state <= next_state;
    end

    always @(*) begin
        case (state)
            S0: choose = 1'b0;
            S1: choose = 1'b1;
            S2: choose = 1'b1;
            default: choose = 1'b0;
        endcase
    end

endmodule
