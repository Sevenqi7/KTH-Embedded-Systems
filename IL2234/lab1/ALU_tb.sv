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

    integer i = 0, j = 0;
    initial begin
        op = 3'b0;
        for(i=0;i<32'd256;i=i+1'b1) begin
            for(j=0;j<32'd2;j=j+1'b1) begin
                A = $random();
                B = $random();
                #5;
                // check N flag
                if(Y[width-1] != ONZ[1]) begin
                    $display("Wrong N flag %d detected when op=%d A=%d B=%d\n", ONZ[1], op, A, B);
                    $finish;
                end
                // check Z flag
                if((Y == 0 && !ONZ[0]) || (Y != 0 && ONZ[0])) begin
                    $display("Wrong Z flag %d detected when op=%d A=%d B=%d\n", ONZ[0], op, A, B);
                    $finish;
                end
                // check ADD overflow
                if(op == 3'b0) begin
                    if((A[width - 1] == B[width - 1]) && (A[width - 1] != Y[width - 1] && !ONZ[2])) begin
                        $display("Wrong O flag %d detected when op=%d A=%d B=%d\n", ONZ[0], op, A, B);
                        $finish;
                    end
                end             
                if(op == 3'b1) begin
                    if((A[width - 1] != B[width - 1]) && (A[width - 1] != Y[width - 1] && !ONZ[2])) begin
                        $display("Wrong O flag %d detected when op=%d A=%d B=%d\n", ONZ[0], op, A, B);
                        $finish;
                    end
                end   

                op = op + 1'b1;
            end
        end
        $display("Simulation end\n");
        $finish;
    end
endmodule
;
