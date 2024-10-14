module q4_top #(
    parameter unsigned A = 3,
    parameter unsigned B = 4,
    parameter unsigned C = 3,
    parameter unsigned D = 2,
    parameter unsigned E = 1,
    parameter unsigned addr_width = 4
) (

    input logic clk,
    input logic rst_n,
    input logic start,
    output logic idle,
    output logic [addr_width-1 : 0] address,
    output logic overflow
);

    enum logic [1:0] {
        idle_state,
        fst_itr,
        sec_itr
    } state;

    integer i, j;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= idle_state;
            i <= 0;
            j <= 0;
        end else begin
            case (state)
                idle_state: begin
                    if (start) begin
                        state <= sec_itr;
                    end else begin
                        i <= 0;
                        j <= 0;
                        state <= idle_state;
                    end
                end
                fst_itr: begin
                    if (i < (C - 1)) begin
                        i <= i + 1;
                        j <= 0;
                        state <= sec_itr;
                    end else begin
                        state <= idle_state;
                    end
                end
                sec_itr: begin
                    if (j < (B - 1)) begin
                        j <= j + 1;
                        if (j == (B - 2)) begin
                            state <= fst_itr;
                        end
                    end else begin
                        state <= sec_itr;
                    end
                end
            endcase
        end
    end

    assign idle = (state == idle_state);
    assign {overflow, address} = idle ? 0 : A + D * j + E * i;

endmodule
