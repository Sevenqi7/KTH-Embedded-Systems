module q1_top (
    input  logic clk,
    input  logic rst_n,
    input  logic inp,
    output logic detected
);

    // Insert your code here

    logic [2:0] cnt;
    enum logic {
        seq_invalid,
        seq_detected
    }
        state, next;

    always_comb begin
        case (state)
            seq_invalid: begin
                if ((cnt == 4) && inp) next = seq_detected;
                else next = seq_invalid;
            end
            seq_detected: begin
                if (inp) next = seq_detected;
                else next = seq_invalid;
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt   <= 0;
            state <= seq_invalid;
        end else begin
            case (state)
                seq_invalid: begin
                    if (inp) begin
                        cnt <= cnt + 1'b1;
                    end else begin
                        cnt <= 0;
                    end
                    state <= next;
                end
                seq_detected: begin
                    state <= next;
                    cnt   <= 0;
                end
            endcase
        end
    end

    assign detected = (next == seq_detected);

endmodule
