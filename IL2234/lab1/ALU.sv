module ALU #(
    parameter width = 3
) (
    input  logic [width - 1 : 0] A,
    input  logic [width - 1 : 0] B,
    input  logic [        2 : 0] op,
    output logic [width - 1 : 0] Y,
    output logic [        2 : 0] ONZ
);

    logic op_add = (op == 3'b000);
    logic op_sub = (op == 3'b001);
    logic op_and = (op == 3'b010);
    logic op_or = (op == 3'b011);
    logic op_xor = (op == 3'b100);
    logic op_inc = (op == 3'b101);
    logic op_mova = (op == 3'b110);
    logic op_movb = (op == 3'b111);

    assign Y =  op_add  ? A + B :
                op_sub  ? A - B :
                op_and  ? A & B :
                op_or   ? A | B :
                op_xor  ? A ^ B :
                op_inc  ? A + 1 :
                op_mova ? A :
                op_movb ? B :
                0;    //never reach here

    logic A_sign = A[width-1];
    logic B_sign = B[width-1];
    logic Y_sign = Y[width-1];

    logic add_of = op_add && ((A_sign == B_sign) && (A_sign != Y_sign));
    logic sub_of = op_sub && ((A_sign != B_sign) && (A_sign != Y_sign));

    logic o_flag = add_of | sub_of;
    logic n_flag = Y[width-1];
    logic z_flag = !|Y;

    assign ONZ = {o_flag, n_flag, z_flag};

endmodule
;
