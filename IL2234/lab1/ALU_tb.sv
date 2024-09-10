module ALU_tb;
    parameter width = 8;
    logic [width-1:0] A, B, Y;
    logic [2:0] op, ONZ;

    ALU #(
        .width(width)
    ) alu (
        .A  (A),
        .B  (B),
        .op (op),
        .Y  (Y),
        .ONZ(ONZ)
    );

    initial begin
        for (op = 0; op < 3'b111; op = op + 1'b1) begin
            A = $random();
            B = $random();
            #5;
            A = $random();
            B = $random();
            #5;
        end
        $display("Simulation end\n");
        $finish;
    end
endmodule
;
