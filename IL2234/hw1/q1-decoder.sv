module decoder (
    input  logic [ 3:0] binary,
    output logic [15:0] one_hot
);
    always_comb begin
        one_hot = 16'b0000_0000_0000_0000;
        case (binary)
            4'b0000: one_hot[0] = 1'b1;
            4'b0001: one_hot[1] = 1'b1;
            4'b0010: one_hot[2] = 1'b1;
            4'b0011: one_hot[3] = 1'b1;
            4'b0100: one_hot[4] = 1'b1;
            4'b0101: one_hot[5] = 1'b1;
            4'b0110: one_hot[6] = 1'b1;
            4'b0111: one_hot[7] = 1'b1;
            4'b1000: one_hot[8] = 1'b1;
            4'b1001: one_hot[9] = 1'b1;
            4'b1010: one_hot[10] = 1'b1;
            4'b1011: one_hot[11] = 1'b1;
            4'b1100: one_hot[12] = 1'b1;
            4'b1101: one_hot[13] = 1'b1;
            4'b1110: one_hot[14] = 1'b1;
            4'b1111: one_hot[15] = 1'b1;
        endcase
    end
endmodule
