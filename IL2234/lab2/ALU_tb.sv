module ALU_tb;
    parameter width = 8;
    logic [width-1:0] A, B, Y;
    logic [2:0] op, ONZ;
    logic clk, rst_neg, rst_pos, ONZ_en;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    ALU #(
        .width(width)
    ) alu (
        .clk(clk),
        .rst_neg(rst_neg),
        .rst_pos(rst_pos),
        .A(A),
        .B(B),
        .op(op),
        .Y(Y),
        .ONZ_en(ONZ_en),
        .ONZ(ONZ)
    );

    integer i = 0, j = 0;
    initial begin
        op = 3'b0;
        rst_neg = 1'b1;
        rst_pos = 1'b0;
        ONZ_en = 1'b1;

        // 1. verify the correctness of calculation 
        for (i = 0; i < 32'd256; i = i + 1'b1) begin
            for (j = 0; j < 32'd2; j = j + 1'b1) begin
                A = $random();
                B = $random();
                @(negedge clk);
                @(negedge clk);
                // check N flag
                if (Y[width-1] != ONZ[1]) begin
                    $display("Wrong N flag %d detected when op=%d A=%d B=%d\n", ONZ[1], op, A, B);
                    $finish;
                end
                // check Z flag
                if ((Y == 0 && !ONZ[0]) || (Y != 0 && ONZ[0])) begin
                    $display("Wrong Z flag %d detected when op=%d A=%d B=%d\n", ONZ[0], op, A, B);
                    $finish;
                end
                // check ADD overflow
                if (op == 3'b0) begin
                    if ((A[width-1] == B[width-1]) && (A[width-1] != Y[width-1] && !ONZ[2])) begin
                        $display("Wrong O flag %d detected when op=%d A=%d B=%d\n", ONZ[0], op, A,
                                 B);
                        $finish;
                    end
                end
                if (op == 3'b1) begin
                    if ((A[width-1] != B[width-1]) && (A[width-1] != Y[width-1] && !ONZ[2])) begin
                        $display("Wrong O flag %d detected when op=%d A=%d B=%d\n", ONZ[0], op, A,
                                 B);
                        $finish;
                    end
                end

                op = op + 1'b1;
            end
        end

        //2. verify that ONZ_en and rst_pos work correctly
        rst_pos = 1'b1;
        @(posedge clk);
        if (ONZ != 3'b0) begin
            $display("Error: rst_pos doesn't reset the value of ONZ");
            $finish;
        end

        // Calculate MAX + 1, which should set O and N flag
        rst_pos = 1'b0;
        ONZ_en = 1'b1;
        A = {1'b0, {width - 1{1'b1}}};
        B = 1'b1;
        @(posedge clk);
        @(posedge clk);
        if (ONZ != 3'b0) begin
            $display("Error: ONZ flags are still updated when ONZ_en is 0");
            $finish;
        end

        $display("Simulation end\n");
        $finish;
    end
endmodule
