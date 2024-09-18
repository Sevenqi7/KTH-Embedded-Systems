module product_prod #(
    parameter N = 4
) (
    input [N-1:0] X[5:0],
    output [2*N + 2:0] result
);

    logic [2*N-1 : 0] product[4:0];
    always_comb begin
        for (integer i = 0; i < 5; i++) begin
            product[i] = X[i] * X[i+1];
        end
    end

    logic [2*N:0] tmp0, tmp1;
    assign tmp0 = product[0] + product[1];
    assign tmp1 = product[2] + product[3];

    logic [2*N+1:0] tmp2;
    assign tmp2 = tmp0 + tmp1;

    logic [2*N+2:0] tmp3;
    assign tmp3   = tmp2 + product[4];

    assign result = tmp3;
endmodule

