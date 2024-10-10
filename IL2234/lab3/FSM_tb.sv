`timescale 1ns / 1ps

`include "instructions.svh"
module FSM_tb;
    parameter M = 4;  // size of register address
    parameter N = 4;  // size of register data
    parameter P = 6;  // PC size and instruction memory address
    parameter MAX_PC = {P{1'b1}};

    class Random_Instr;
        rand bit [4+2*M-1:0] instr;

        constraint instr_constraint {instr[4+2*M-1:2*M] < 4'b1111;}

        function void random_alu();
            assert (randomize(instr) with {instr[4+2*M-1:2*M] inside {[4'b0000 : 4'b0110]};});
        endfunction

        function void random_branch(input integer PC);
            assert (randomize(
                instr
            ) with {
                // instr[2*M-2:0] <= PC[P-1:0];
                (!instr[2*M-1] && (instr[2*M-2:0] <= PC[P-1:0])) || 
                    (instr[2*M-1] && (instr[2*M-2:0] < PC[P-1:0]));
                instr[4+2*M-1:2*M] inside {[4'b1011 : 4'b1110]};
            });
        endfunction
    endclass

    // Clock & reset 
    logic clk, rst_n;
    Random_Instr rand_instr;
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 1. Instantiation of ALU
    logic ONZ_en, rst_pos;
    logic [M-1:0] op_A, op_B, result;
    logic [2:0] alu_op;
    logic [2:0] ONZ;

    ALU #(
        .width(N)
    ) alu_0 (
        .clk(clk),
        .rst_neg(rst_n),
        .rst_pos(rst_pos),
        .A(op_A),
        .B(op_B),
        .op(alu_op),
        .Y(result),
        .ONZ_en(ONZ_en),
        .ONZ(ONZ)
    );

    // 2. instantiation of Regfile
    logic sel_destA, sel_destB, write_en;
    logic [1:0] select_source;
    logic [M-1:0] waddr, raddrA, raddrB;
    logic [N-1:0] imm;
    // logic [N-1:0] dest1A, dest1B, dest2A, dest2B;


    RF #(
        .N(N),
        .addressBits(M)
    ) regfile_0 (
        .clk(clk),
        .rst_n(rst_n),
        .selectDestinationA(sel_destA),
        .selectDestinationB(sel_destB),
        .selectSource(select_source),
        .writeAddress(waddr),
        .write_en(write_en),
        .readAddressA(raddrA),
        .readAddressB(raddrB),
        .A(result),
        .B(4'hf),
        .C(imm),
        .destination1A(op_A),
        .destination1B(op_B),
        .destination2A(),
        .destination2B()
    );

    // 3. instantiation of FSM

    logic en_read_instr, ov_warn, sram_ren, sram_wen;
    logic [4+2*M-1:0] instr;

    FSM #(
        .M(M),
        .N(N),
        .P(P)
    ) fsm_0 (
        .clk(clk),
        .rst_n(rst_n),
        .overflow_warning(ov_warn),
        // to/from register file
        .select_source(select_source),
        .waddr(waddr),
        .write_en(write_en),
        .raddrA(raddrA),
        .raddrB(raddrB),
        .sel_destA(sel_destA),
        .sel_destB(sel_destB),
        .imm(imm),
        // to/from ALU
        .OP(alu_op),
        .s_rst(rst_pos),
        .ONZ(ONZ),
        .enable(ONZ_en),
        // from instr mem
        .instr_in(instr),
        .en_read_instr(en_read_instr),
        .raddr_instr(),
        // to data mem
        .SRAM_readEnable(sram_ren),
        .SRAM_writeEnable(sram_wen)
    );

    enum logic [2:0] {
        alu_test,
        br_test,
        ldimm_test,
        mem_test,
        ov_test
    } tb_state;

    /*
    RF.dest1A -> alu.op_A
    RF.dest1B -> alu.op_B
    RF.dest2A -> MEM.wdata
    RF.dest2B -> MEM.addr

    alu.result -> RF.A
    MEM.rdata -> RF.B
    IMM -> RF.C

    */
    wire [P-1:0] diff = MAX_PC - fsm_0.PC;

    initial begin
        rst_n = 1'b0;
        rand_instr = new();
        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;
        // Test ALU instrs and state machines
        tb_state = alu_test;
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);
            assert (fsm_0.state == fsm_0.fetch && en_read_instr);
            rand_instr.random_alu();
            instr = rand_instr.instr;
            @(posedge clk);
            assert (fsm_0.state == fsm_0.decode);
            assert (ONZ_en && (alu_op == instr[4+2*M-2:2*M]) && !sel_destA && !sel_destB);
            @(posedge clk);
            assert (fsm_0.state == fsm_0.execute);
            assert (!ONZ_en && (select_source == 2'b01) && write_en);
            assert (!ov_warn);
        end

        // Test load imm
        tb_state = ldimm_test;
        @(posedge clk);
        instr = {LOAD_IM, 8'h77};
        @(posedge clk);
        //decode
        @(posedge clk);
        assert ((select_source == 2'b11) && write_en);
        //execute

        // Test LD/ST instrs
        tb_state = mem_test;
        // LOAD
        @(posedge clk);
        instr = {LOAD, 8'h77};
        @(posedge clk);
        assert (sram_ren && sel_destB);
        @(posedge clk);
        assert (write_en && (select_source == 2'b10));

        //STORE
        @(posedge clk);
        instr = {STORE, 8'h77};
        @(posedge clk);
        assert (sram_wen && sel_destA && sel_destB);
        @(posedge clk);

        // Test Branch instrs
        tb_state = br_test;
        for (int i = 0; i < 5; i++) begin
            // generate ONZ flags by random ALU instruction
            @(posedge clk);
            assert (fsm_0.state == fsm_0.fetch && en_read_instr);
            rand_instr.random_alu();
            instr = rand_instr.instr;
            @(posedge clk);
            assert (fsm_0.state == fsm_0.decode);
            assert (ONZ_en && (alu_op == instr[4+2*M-2:2*M]));
            @(posedge clk);
            assert (fsm_0.state == fsm_0.execute);
            assert (!ONZ_en && (select_source == 2'b01) && write_en);
            assert (!ov_warn);

            // generate random branch instruction
            @(posedge clk);
            assert (fsm_0.state == fsm_0.fetch && en_read_instr);
            rand_instr.random_branch(fsm_0.PC);
            instr = rand_instr.instr;
            @(posedge clk);
            assert (fsm_0.state == fsm_0.decode);
            assert (!ONZ_en && rst_pos);
            @(posedge clk);
            assert (fsm_0.state == fsm_0.execute);
            assert (!write_en && !ov_warn);
        end

        // overflow detection
        tb_state = ov_test;
        @(posedge clk);
        instr = {4'b1110, 2'b10, fsm_0.PC[P-1:0] + 1'b1};  // make a delibrated jump to overflow PC
        @(posedge clk);  // decode
        @(posedge clk);  // execute
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);
            assert (ov_warn && (fsm_0.state == fsm_0.idle));
        end
        $display("Test Pass!");
        $finish();
    end

endmodule
