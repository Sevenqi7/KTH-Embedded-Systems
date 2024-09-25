module d_flop #(
    parameter logic reset_val = 1'b0
) (
    input  logic clk,
    rst_n,
    d,
    output logic q
);
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            q <= reset_val;
        end else begin
            q <= d;
        end
    end
endmodule

module fb_LFSR #(
    parameter N = 4,
    parameter logic [N-2:0] feedback_poly = 3'b010,
    parameter logic [N-1:0] reset_val = 4'b0000
) (
    input logic clk,
    input logic rstn,
    output logic [N-1:0] out
);

    logic [N-1:0] d_in;
    always_comb begin
        d_in[0] = out[N-1];
        for (int i = 1; i < N; i++) begin
            if (feedback_poly[i-1]) d_in[i] = out[i-1] ^ out[N-1];
            else d_in[i] = out[i-1];
        end
    end

    generate
        genvar i;
        for (i = 0; i < N; i++) begin
            d_flop #(
                .reset_val(reset_val[i])
            ) dff (
                .clk(clk),
                .rst_n(rstn),
                .d(d_in[i]),
                .q(out[i])
            );
        end
    endgenerate

endmodule
