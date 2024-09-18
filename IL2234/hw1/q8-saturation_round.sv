module saturation_round #(
    parameter I = 4,
    parameter Fin = 12,
    parameter Fout = 4
) (
    input logic [15:0] in,
    input logic up_down,
    output logic [8:0] out
);

    logic carry;
    logic [I-1:0] Integer_in = in[15:Fin];
    logic [Fin-1:0] Fraction_in = in[Fin-1:0];

    logic [I:0] Integer_out;
    logic [Fout-1:0] Fraction_out;

    always_comb begin
        if (up_down) begin : round_up
            if (Fraction_in[Fout-1]) begin
                Fraction_out = Fraction_in[Fin-Fout-1:Fout] + 1'b1;
            end else begin
                Fraction_out = Fraction_in[Fin-Fout-1:Fout];
            end
        end else begin
            Fraction_out = Fraction_in[Fin-Fout-1:Fout];
        end
    end

    assign carry = Fraction_in[Fout-1] && Fraction_in[Fin-1];
    assign Integer_out = Integer_in + carry;
    assign out = {Integer_out, Fraction_out};

endmodule
