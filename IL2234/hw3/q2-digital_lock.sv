module q2_top (
    input logic clk,
    input logic rst_n,
    input logic valid_key,
    input logic [3:0] key,
    output logic state
);

    // Insert your code here

    // set new password
    logic [3:0] password[3:0];
    logic [2:0] pwd_cnt;
    logic has_passwd_reset;

    enum logic [1:0] {
        idle,
        under_rst
    } pwd_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwd_state <= idle;
            pwd_cnt <= 0;
            password <= {4'hf, 4'hf, 4'hf, 4'hf};
            has_passwd_reset <= 1'b0;
        end else begin
            if (valid_key) begin
                case (pwd_state)
                    idle: begin
                        pwd_state <= (key == 4'hE) ? under_rst : idle;
                    end
                    under_rst: begin
                        pwd_cnt <= pwd_cnt + 1'b1;
                        pwd_state <= (pwd_cnt == 3'd3) ? idle : under_rst;
                        password[3-pwd_cnt[1:0]] <= key;
                        has_passwd_reset <= (pwd_cnt == 3'd3);
                    end
                    default: ;
                endcase
            end else begin
                password  <= password;
                pwd_state <= pwd_state;
                pwd_cnt   <= pwd_cnt;
            end
        end
    end

    logic [3:0] key_buffer[3:0];
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) begin
                key_buffer[i] <= 4'hf;
            end
        end

        if (valid_key) begin
            for (int i = 0; i < 4; i++) begin
                if (i == 0) key_buffer[i] <= key;
                else key_buffer[i] <= key_buffer[i-1];
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 1'b0;  // reset to unlocked
        end else begin
            if (valid_key) begin
                case (state)
                    1'b0: begin
                        if (key == 4'hB && has_passwd_reset) begin
                            state <= 1'h1;
                        end
                    end
                    1'b1: begin
                        if (key == 4'hC) begin
                            state <= (key_buffer == password) ? 1'b0 : 1'b1;
                        end
                    end
                endcase
            end else begin
                state <= state;
            end
        end
    end

endmodule
