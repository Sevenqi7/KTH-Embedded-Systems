// 4-bit multiplier module
module mul_4bits (
    input  logic [3:0] A,   
    input  logic [3:0] B,   
    output logic [7:0] P    
);
    assign P = A * B;
endmodule

// 8-bits multiplier, implemented by several 4-bit multiplier
module mul_8bits (
    input  logic [7:0] A,   // 16-bit unsigned input A
    input  logic [7:0] B,   // 16-bit unsigned input B
    output logic [15:0] P    // 32-bit output product
);

    logic [7:0] partial_product[3:0];

    // 4-bit multipliers
    mul_4bits mult0(.A(A[3:0]),   .B(B[3:0]),   .P(partial_product[0])); 
    mul_4bits mult1(.A(A[7:4]),   .B(B[3:0]),   .P(partial_product[1])); 
    mul_4bits mult2(.A(A[3:0]),   .B(B[7:4]),   .P(partial_product[2])); 
    mul_4bits mult3(.A(A[7:4]),   .B(B[7:4]),   .P(partial_product[3])); 

    assign P = partial_product[0] + {partial_product[1], 4'b0} + {partial_product[2], 4'b0} + {partial_product[3], 4'b0};

endmodule

// 8-bits multiplier, implemented by several 4-bit multiplier
module mul_16bits (
    input  logic [15:0] A,   // 16-bit unsigned input A
    input  logic [15:0] B,   // 16-bit unsigned input B
    output logic [31:0] P    // 32-bit output product
);

    logic [15:0] partial_product [3:0];
    logic [39:0] imm0, imm1;

    // 4-bit multipliers
    mul_8bits mult0(.A(A[7:0]),   .B(B[7:0]),   .P(partial_product[0])); 
    mul_8bits mult1(.A(A[15:8]),  .B(B[7:0]),   .P(partial_product[1])); 
    mul_8bits mult2(.A(A[7:0]),   .B(B[15:8]),  .P(partial_product[2])); 
    mul_8bits mult3(.A(A[15:8]),  .B(B[15:8]),  .P(partial_product[3])); 
    // Assign final product
    assign P = partial_product[0] + {partial_product[1], 8'b0} + {partial_product[2], 8'b0} + {partial_product[3], 16'b0};

endmodule 
