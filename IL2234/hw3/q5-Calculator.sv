module q5_top (
    input logic clk,
    input logic rstn,
    input logic valid_key,
    input logic [3:0] key,
    output logic [7:0] result,
    output logic valid
);

    enum logic [1:0] {
        wait_op1_1st,
        wait_op1,
        wait_optype,
        wait_op2
    } state;

    logic [3:0] op1, op2;
    logic [1:0] optype;  // 0: add 1: sub 2: mul

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= wait_op1_1st;
            op1 <= 0;
            op2 <= 0;
            optype <= 0;
        end else begin
            if (valid_key) begin
                case (state)
                    wait_op1_1st: begin
                        op1   <= key;
                        state <= wait_optype;
                    end
                    wait_op1: begin
                        op1   <= key;
                        state <= wait_optype;
                    end
                    wait_optype: begin
                        optype <= key[1:0];
                        state  <= wait_op2;
                    end
                    wait_op2: begin
                        op2   <= key;
                        state <= wait_op1;
                    end
                endcase
            end
        end
    end


    logic [7:0] sext_op1, sext_op2;
    always_comb begin
        sext_op1 = {{4{op1[3]}}, op1};
        sext_op2 = {{4{op2[3]}}, op2};
        result   = 0;
        if (valid) begin
            case (optype)
                2'b00:   result = sext_op1 + sext_op2;
                2'b01:   result = sext_op1 - sext_op2;
                2'b10:   result = op1 * op2;
                default: result = 0;
            endcase
        end
    end

    always_comb begin
        valid = 1'b0;
        if (state == wait_op1) valid = 1'b1;
    end
    // assign valid = (state == wait_op1);


endmodule
