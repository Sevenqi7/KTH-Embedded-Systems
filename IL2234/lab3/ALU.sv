module ALU #(
    parameter width = 3
) (
    input  logic                 clk,
    input  logic                 rst_neg,
    input  logic                 rst_pos,
    input  logic [width - 1 : 0] A,
    input  logic [width - 1 : 0] B,
    input  logic [        2 : 0] op,
    output logic [width - 1 : 0] Y,
    input  logic                 ONZ_en,
    output logic [        2 : 0] ONZ
);

    wire op_add = (op == 3'b000);
    wire op_sub = (op == 3'b001);
    wire op_and = (op == 3'b010);
    wire op_or = (op == 3'b011);
    wire op_xor = (op == 3'b100);
    wire op_inc = (op == 3'b101);
    wire op_mova = (op == 3'b110);
    wire op_movb = (op == 3'b111);
    wire [width-1:0] result;

    assign result =  op_add  ? A + B :
                     op_sub  ? A - B :
                     op_and  ? A & B :
                     op_or   ? A | B :
                     op_xor  ? A ^ B :
                     op_inc  ? A + 1 :
                     op_mova ? A :
                     op_movb ? B :
                     0;    //never reach here

    always @(posedge clk or negedge rst_neg) begin
        if (!rst_neg) begin
            Y <= 0;
        end else begin
            Y <= result;
        end
    end

    wire A_sign = A[width-1];
    wire B_sign = B[width-1];
    wire Y_sign = Y[width-1];

    wire add_of = op_add && ((A_sign == B_sign) && (A_sign != Y_sign));
    wire sub_of = op_sub && ((A_sign != B_sign) && (A_sign != Y_sign));

    wire o_flag = add_of | sub_of;
    wire n_flag = Y_sign;
    wire z_flag = (Y == 0);

    always @(posedge clk or negedge rst_neg) begin
        if (!rst_neg | rst_pos) begin
            ONZ <= 3'b0;
        end else if (ONZ_en) begin
            ONZ <= {o_flag, n_flag, z_flag};
        end
    end

endmodule
