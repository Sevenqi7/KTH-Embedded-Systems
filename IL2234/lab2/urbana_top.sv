module urbana_top (
    input logic CLK_100MHZ,
    input logic [15:0] SW,
    input logic [3:0] BTN,
    // output logic [15:0] LED,
    output logic [3:0] D0_AN,
    output logic [7:0] D0_SEG
    // output logic [3:0] D1_AN,
    // output logic [7:0] D1_SEG
);

    // 1. Divide the clock to 1 kHz
    logic CLK_1KHZ;
    clock_divider #(
        .DIVISOR(10000)
    ) clk_dv (
        .rst_n  (1'b1),
        .clk_in (CLK_100MHZ),
        .clk_out(CLK_1KHZ)
    );

    // 1. Instantiate the ALU module
    wire [3:0] result, result_abs;
    wire [2:0] ONZ;

    ALU #(
        .width(4)
    ) urbana_alu (
        .clk(CLK_1KHZ),
        .rst_neg(1'b1),
        .rst_pos(BTN[0]),
        .A(SW[3:0]),
        .B(SW[7:4]),
        .op(SW[10:8]),
        .Y(result),
        .ONZ_en(SW[11]),
        .ONZ(ONZ)
    );

    assign result_abs = ONZ[1] ? (~result + 1'b1) : result;

    // 2. Instantiate bcd to 7 segments
    wire [6:0] digit[1:0];

    bcd27s b27 (
        .bcd(result_abs),
        .seg(digit[0])
    );

    // display minus if N flag is set
    assign digit[1] = ONZ[1] ? 7'h3f : 7'h7f;

    // 3. sequentially display every digit
    reg flag = 1'b0;
    always @(posedge CLK_1KHZ) begin
        flag <= ~flag;
        if (flag) begin
            D0_AN  = 4'b1011;
            D0_SEG = {1'b1, digit[1]};
        end else begin
            D0_AN  = 4'b0111;
            D0_SEG = {1'b1, digit[0]};
        end
    end

endmodule
