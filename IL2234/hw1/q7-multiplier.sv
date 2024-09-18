module half_adder (
    input  a,
    input  b,
    output c_out,
    output s
);
    assign s = a ^ b;
    assign c_out = a & b;
endmodule

module full_adder (
    input  a,
    input  b,
    input  c_in,
    output c_out,
    output s
);
    logic s1, c1, c2;
    half_adder ha1 (
        a,
        b,
        s1,
        c1
    );
    half_adder ha2 (
        s1,
        c_in,
        c2,
        s
    );
    assign c_out = c1 | c2;
    assign c_out = c1 | c2;
endmodule

module multiplier #(
    parameter N = 1
) (
    input  [  N-1:0] a,
    input  [  N-1:0] b,
    output [2*N-1:0] product
);

    logic [2*N-1:0] tmpproduct[N-1:0];
    integer i, j;

    always_comb begin
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                tmpproduct[i][i+j] = a[i] & b[j];
            end
            //signed extend the result
            for (j = N + i; j < 2 * N; j++) begin
                tmpproduct[i][j] = tmpproduct[i][N-1+i];
            end
        end
    end

    wire [2*N-1:0] sum[N-1:0];
    wire [N-1:0] carry;

    assign sum[0] = tmpproduct[0];

    generate
        // sump up all tmpproduct
        for (genvar i = 1; i <= N - 1; i++) begin
            for (genvar j = 0; j < 2 * N; j++) begin
                if (j == 0) begin
                    // the least significant bit doesn't has a carry-in
                    // so we use half adder here
                    half_adder ha (
                        .a(sum[i-1][j]),
                        .b(tmpproduct[i][j]),
                        .c_out(carry[i][j]),
                        .s(sum[i][j])
                    );
                end
                full_adder fa (
                    .a(sum[i-1][j]),
                    .b(tmpproduct[i][j]),
                    .c_in(carry[i-1][j-1]),
                    .c_out(carry[i][j]),
                    .s(sum[i][j])
                );
            end
        end
    endgenerate

    assign product = sum[N-1];

endmodule
