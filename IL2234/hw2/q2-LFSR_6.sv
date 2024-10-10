module LFSR_6 (
    input logic clk,
    input logic rst_n,
    input logic sel,
    input logic [5:0] p,
    output logic [5:0] out
);
    reg [5:0] shift_reg;

    wire shift_in = shift_reg[5] + shift_reg[2] + shift_reg[0] + 1'b1;

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 6'b0;
        end else begin
            shift_reg <= sel ? {shift_reg[4:0], shift_in} : p;
        end
    end

endmodule
