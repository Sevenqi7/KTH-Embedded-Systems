module LFSR #(
    parameter N = 4
) (
    input logic clk,
    input logic rstn,
    input logic serial_parallel,
    input logic load_enable,
    input logic [N-1:0] parallel_in,
    input logic serial_in,
    output logic [N-1:0] parallel_out,
    output logic serail_out
);

    reg [N-1:0] shift_reg;
    always @(posedge clk) begin
        if (!rstn) begin
            shift_reg <= {N{1'b0}};
        end else if (load_enable) begin
            if (serial_parallel) begin
                shift_reg <= parallel_in;
            end else begin
                shift_reg <= {shift_reg[N-2:0], serial_in};
            end
        end
    end

    assign parallel_out = shift_reg;
    assign serial_out   = shift_reg[N-1];

endmodule
