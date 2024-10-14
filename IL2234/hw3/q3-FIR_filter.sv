module q3_top #(
    parameter W = 8,
    parameter C = 5
) (
    input logic clk,
    input logic rst_n,
    input logic new_sample,
    input logic signed [W-1:0] sample,
    output logic signed [W+C+6:0] output_data,
    output logic done
);

    // Insert your code here
    enum logic [1:0] {
        IDLE,
        CALC,
        DONE
    } state;

    parameter signed [C-1:0] coefficients[6:0] = {1, 3, 7, 15, 7, 3, 1};

    logic signed [W-1:0] delay_line[6:0];
    logic signed [W-1:0] sample_r;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            for (int i = 0; i < 7; i++) begin
                delay_line[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    if (new_sample) begin
                        state <= CALC;
                        sample_r <= sample;
                    end else state <= IDLE;
                end
                CALC: begin
                    state <= DONE;
                    delay_line <= {delay_line[5:0], sample_r};
                end
                DONE: begin
                    state <= IDLE;
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        output_data = 0;
        done = (state == DONE);
        for (int i = 0; i < 7; i++) begin
            output_data = output_data + delay_line[i] * coefficients[i];
        end
    end
endmodule
