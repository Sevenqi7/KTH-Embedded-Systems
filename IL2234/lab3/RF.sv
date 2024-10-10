module RF #(
    parameter N = 8,
    parameter addressBits = 2
) (
    /* --------------------------------- Inputs --------------------------------- */
    input logic clk,
    input logic rst_n,
    input logic selectDestinationA,
    input logic selectDestinationB,

    input logic [1:0] selectSource,
    input logic [addressBits-1:0] writeAddress,
    input logic write_en,
    input logic [addressBits-1:0] readAddressA,
    input logic [addressBits-1:0] readAddressB,

    input  logic [N-1:0] A,
    input  logic [N-1:0] B,
    input  logic [N-1:0] C,
    /* --------------------------------- Outputs -------------------------------- */
    output logic [N-1:0] destination1A,
    output logic [N-1:0] destination2A,
    output logic [N-1:0] destination1B,
    output logic [N-1:0] destination2B
);

    // Source selection
    logic [N-1:0] write_data;
    always_comb begin
        case (selectSource)
            2'b01:   write_data = A;
            2'b10:   write_data = B;
            2'b11:   write_data = C;
            default: write_data = 0;
        endcase
    end

    // Register files definition
    reg [N-1:0] GPR[2**addressBits-1:0];

    always @(posedge clk or negedge rst_n) begin
        // reset logic
        if (!rst_n) begin
            GPR[0] <= 0;
            GPR[1] <= $signed(1);
            for (int i = 2; i < 2**addressBits; i++) begin
                GPR[i] <= 0;
            end
        end else if (write_en) begin
            GPR[writeAddress] <= write_data;
        end
    end

    // Destination and Read-port
    assign destination1A = !selectDestinationA ? GPR[readAddressA] : 0;
    assign destination2A = selectDestinationA ? GPR[readAddressA] : 0;
    assign destination1B = !selectDestinationB ? GPR[readAddressB] : 0;
    assign destination2B = selectDestinationB ? GPR[readAddressB] : 0;
endmodule
