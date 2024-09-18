module ArithmeticRightShifter #(
    parameter N = 5
) (
    input  logic [N-1:0] input_data,
    input  logic [  1:0] control,
    output logic [N-1:0] shifted_result
);

    always_comb begin
        case (control)
            2'b00: shifted_result = input_data;
            2'b01: shifted_result = {input_data[N-1], input_data[N-1 : 1]};
            2'b10: shifted_result = {input_data[N-1], input_data[N-1], input_data[N-1 : 2]};
            2'b11:
            shifted_result = {
                input_data[N-1], input_data[N-1], input_data[N-1], input_data[N-1 : 3]
            };
            default: shifted_result = input_data;
        endcase
    end

endmodule
