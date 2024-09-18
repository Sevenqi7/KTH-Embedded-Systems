module adder_4 (
    input logic [3:0] A,
    input logic [3:0] B,
    input logic cin,
    output logic [3:0] sum,
    output logic carry
);
    assign {carry, sum} = A + B;
endmodule

module CSA_8 (
    input logic [7:0] A,
    input logic [7:0] B,
    output logic [7:0] sum,
    output logic carry
);

    // A[3:0] + B[3:0]
    wire [3:0] sum_low, sum_high;
    wire c3;
    adder_4 add_u0 (
        .A(A[3:0]),
        .B(B[3:0]),
        .cin(0),
        .sum(sum_low),
        .carry(c3)
    );


    // result when ci4 = 0
    wire [3:0] sum_high_0;
    wire c7_0;

    adder_4 addu_1 (
        .A(A[7:4]),
        .B(B[7:4]),
        .cin(1'b0),
        .sum(sum_high_0),
        .carry(c7_0)
    );

    // result when ci4 = 1
    wire [3:0] sum_high_1;
    wire c7_1;
    adder_4 addu_2 (
        .A(A[7:4]),
        .B(B[7:4]),
        .cin(1'b1),
        .sum(sum_high_1),
        .carry(c7_1)
    );

    assign sum_high = c3 ? sum_high_1 : sum_high_0;
    assign sum = {sum_high, sum_low};
    assign carry = c3 ? c7_1 : c7_0;
endmodule

