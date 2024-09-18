module count_1 (
    input  logic [3:0] a,
    output logic [2:0] out
);
    integer i = 0;
    always_comb begin
        out = 3'b0;
        for (i = 0; i < 4; i = i+1'b1) begin
            if (a[i]) out = out + 1'b1;
        end
    end

endmodule
