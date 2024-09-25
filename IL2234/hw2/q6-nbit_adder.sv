module full_adder (
    input  a,
    b,
    c_in,
    output c_out,
    s
);
    logic s1, c1, c2;
    half_adder ha1 (
        .a(a),
        .b(b),
        .s(s1),
        .c_out(c1)
    );
    half_adder ha2 (
        s1,
        c_in,
        c2,
        s
    );
    assign c_out = c1 | c2;
endmodule
module half_adder (
    input  a,
    b,
    output c_out,
    s
);
    assign s = a ^ b;
    assign c_out = a & b;
endmodule

module nbit_adder #(
    parameter N = 6,
    parameter P = 2
) (
    input logic clk,
    input logic rstn,
    input logic [N-1:0] a,
    input logic [N-1:0] b,
    output logic [N-1:0] sum,
    output logic c_out
);

    // stage 1: Calculate A[P-1:0] + B[P-1:0]
    //  1 more bit for carry_in
    reg [P:0] lowsum_r;
    wire [P-1:0] lowsum, lowcout;

    half_adder ha (
        .a(a[0]),
        .b(b[0]),
        .c_out(lowcout[0]),
        .s(lowsum[0])
    );

    generate
        genvar i;
        for (i = 1; i < P; i++) begin
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .c_in(lowcout[i-1]),
                .s(lowsum[i]),
                .c_out(lowcout[i])
            );
        end
    endgenerate


    always @(posedge clk) begin
        if (!rstn) begin
            lowsum_r <= 0;
        end else begin
            lowsum_r <= {lowcout[P-1], lowsum};
        end
    end

    // stage 2 Calculate rest part

    wire [N-P-1:0] highsum, highcout;
    generate
        genvar k;
        for (k = P; k < N; k++) begin
            if (k == P) begin
                full_adder fa2 (
                    .a(a[P]),
                    .b(b[P]),
                    .c_in(lowsum_r[P]),
                    .s(highsum[0]),
                    .c_out(highcout[0])
                );
            end else begin
                full_adder fa2 (
                    .a(a[k]),
                    .b(b[k]),
                    .c_in(highcout[k-P-1]),
                    .s(highsum[k-P]),
                    .c_out(highcout[k-P])
                );
            end
        end
    endgenerate

    assign c_out = highcout[N-P-1];
    assign sum   = {highsum, lowsum_r[P-1:0]};

endmodule
