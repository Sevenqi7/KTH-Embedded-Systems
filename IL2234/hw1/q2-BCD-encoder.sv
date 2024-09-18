module bin2bcd (
    input logic [3:0] binary,
    output logic [3:0] bcd,
    output logic carry
);

    always @(*) begin
        case (binary)
            4'b0000: {carry, bcd} = {1'b0, 4'b0000};  // 0 
            4'b0001: {carry, bcd} = {1'b0, 4'b0001};  // 1 
            4'b0010: {carry, bcd} = {1'b0, 4'b0010};  // 2 
            4'b0011: {carry, bcd} = {1'b0, 4'b0011};  // 3 
            4'b0100: {carry, bcd} = {1'b0, 4'b0100};  // 4 
            4'b0101: {carry, bcd} = {1'b0, 4'b0101};  // 5 
            4'b0110: {carry, bcd} = {1'b0, 4'b0110};  // 6 
            4'b0111: {carry, bcd} = {1'b0, 4'b0111};  // 7 
            4'b1000: {carry, bcd} = {1'b0, 4'b1000};  // 8 
            4'b1001: {carry, bcd} = {1'b0, 4'b1001};  // 9 
            4'b1010: {carry, bcd} = {1'b1, 4'b0000};  // 10 
            4'b1011: {carry, bcd} = {1'b1, 4'b0001};  // 11 
            4'b1100: {carry, bcd} = {1'b1, 4'b0010};  // 12 
            4'b1101: {carry, bcd} = {1'b1, 4'b0011};  // 13 
            4'b1110: {carry, bcd} = {1'b1, 4'b0100};  // 14 
            4'b1111: {carry, bcd} = {1'b1, 4'b0101};  // 15 
            default: {carry, bcd} = {1'b1, 4'bXXXX};  // X 
        endcase
    end

endmodule
;
