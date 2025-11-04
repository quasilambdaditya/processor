// ==============================================================
// Stalling FSM
// --------------------------------------------------------------
// To stall the fetching of instructions
// and writing to registers, due to BRAM 2 cycle
// read delay
// ===============================================================

module pcfsm(
    input wire clk,
//    input wire reset,
    output reg pc_choose,        // to choose between next pc or orig pc
    output reg reg_write_choose, // to stall register writes
    output reg mem_stall
);

    // pc_choose seq        : o -> 1 -> 1 -> 0 -> 1 -> 1 -> 0 -> 1 ...
    // reg_write_choose seq : 1 -> 1 -> 0 -> 1 -> 1 -> 0 -> 1 -> 1 ...

    reg [5:0] states;
    initial begin
            states[0] = 1'b1;
            states[1] = 1'b0;
            states[2] = 1'b0;
            states[3] = 1'b0;
            states[4] = 1'b0;
            states[5] = 1'b0;                                
    end
    always @(posedge clk) begin
//        if (reset) begin
//            states[0] <= 1'b1;
//            states[1] <= 1'b0;
//            states[2] <= 1'b0;
//        end else begin
            states[0] <= states[5];
            states[1] <= states[0];
            states[2] <= states[1];
            states[3] <= states[2];
            states[4] <= states[3];
            states[5] <= states[4];                                    
//        end
        pc_choose = ~states[0];
        reg_write_choose = ~states[5];
        mem_stall = ~(states[3] | states[4]);
        
    end
   
endmodule