module register_file (
    input logic clk,
    input logic rst_n,
    input logic [7:0] data,
    input logic write_en,
    input logic [3:0] r_address1,
    input logic [3:0] r_address2,
    input logic [3:0] w_address,
    output logic [7:0] out1,
    output logic [7:0] out2
);

    // register file
    reg [7:0] rf[15:0];
    always @(posedge clk) begin
        // I use synchronous reset since it's not specified in requirement
        integer i;
        if (!rst_n) begin
            for (i = 0; i < 16; i++) rf[i] <= 8'b0;
        end else if (writen_en) begin
            rf[w_address] <= data;
        end
    end

    assign out1 = rf[r_address1];
    assign out2 = rf[r_address2];

endmodule
