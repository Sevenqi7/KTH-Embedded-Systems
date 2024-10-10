//-------------- Copyright (c) notice -----------------------------------------
//
// The SV code, the logic and concepts described in this file constitute
// the intellectual property of the authors listed below, who are affiliated
// to KTH (Kungliga Tekniska Högskolan), School of EECS, Kista.
// Any unauthorised use, copy or distribution is strictly prohibited.
// Any authorised use, copy or distribution should carry this copyright notice
// unaltered.
//-----------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//                                                                         #
//This file is part of IL1332 and IL2234 course.                           #
//                                                                         #
//    The source code is distributed freely: you can                       #
//    redistribute it and/or modify it under the terms of the GNU          #
//    General Public License as published by the Free Software Foundation, #
//    either version 3 of the License, or (at your option) any             #
//    later version.                                                       #
//                                                                         #
//    It is distributed in the hope that it will be useful,                #
//    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
//    GNU General Public License for more details.                         #
//                                                                         #
//    See <https://www.gnu.org/licenses/>.                                 #
//                                                                         #
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

`include "instructions.svh"


module FSM #(
    parameter M = 4,  // size of register address
    parameter N = 4,  // size of register data
    parameter P = 6   // PC size and instruction memory address
) (
    input  logic             clk,
    input  logic             rst_n,
    output logic             overflow_warning,
    /* ---------------------- signals to/from register file --------------------- */
    output logic [      1:0] select_source,
    output logic [    M-1:0] waddr,
    output logic             write_en,
    output logic [    M-1:0] raddrA,
    output logic [    M-1:0] raddrB,
    output logic             sel_destA,
    output logic             sel_destB,
    output logic [    N-1:0] imm,
    /* --------------------------- signals to/from ALU -------------------------- */
    output logic [      2:0] OP,
    output logic             s_rst,
    input  logic [      2:0] ONZ,
    output logic             enable,
    /* --------------------------- signals from instruction memory -------------- */
    input  logic [4+2*M-1:0] instr_in,
    output logic             en_read_instr,
    output logic [    P-1:0] raddr_instr,
    /*---------------------------Signals to the data memory--------------*/
    output logic             SRAM_readEnable,
    output logic             SRAM_writeEnable
);

    enum logic [1:0] {
        idle = 2'b11,
        fetch = 2'b00,
        decode = 2'b01,
        execute = 2'b10
    }
        state, next;

    /* ----------------------------- PROGRAM COUNTER ---------------------------- */
    logic [    P-1:0] PC;
    logic [    P-1:0] PC_next;
    logic             ov;
    logic             ov_reg;
    logic [  2*M-1:0] offset;


    /*-----------------------------------------------------------------------------*/
    // Add signals and logic here

    // Decode
    logic [4+2*M-1:0] instr_in_r;
    logic [      3:0] instr_op;
    logic alu_valid, br_valid, ld_valid, ldimm_valid, st_valid;
    logic           br_taken;
    logic [2*M-1:0] br_offset;

    always_comb begin : decoder
        br_offset = instr_in_r[2*M-1:0];
        instr_op = instr_in_r[4+2*M-1:2*M];
        alu_valid = (instr_op <= 4'b0110);
        br_valid = (instr_op >= 4'b1011);
        ld_valid = 0;
        st_valid = 0;
        ldimm_valid = 0;
        case (instr_op)
            LOAD: ld_valid = 1'b1;
            STORE: st_valid = 1'b1;
            LOAD_IM: ldimm_valid = 1'b1;
            default: ;
        endcase
    end

    /*-----------------------------------------------------------------------------*/

    //State register
    always @(posedge clk, negedge rst_n) begin 
        if (!rst_n) begin
            state <= idle;
        end else begin
            state <= next;
        end
    end

    /*-----------------------------------------------------------------------------*/
    // Describe your next state and output logic here

    // Next state logic
    always_comb begin
        case (state)
            idle: begin
                next = ov_reg ? idle : fetch;
            end
            fetch: begin
                next = decode;
            end
            decode: begin
                next = execute;
            end
            execute: begin
                next = ov ? idle : fetch;
            end
            default: next = state;
        endcase
    end

    // Combinational output logic
    always_comb begin
        //1. initialisation
        select_source = 0;
        waddr = 0;
        write_en = 0;
        raddrA = 0;
        raddrB = 0;
        sel_destA = 0;
        sel_destB = 0;
        imm = 0;
        OP = 0;
        s_rst = 0;
        enable = 0;
        en_read_instr = 0;
        raddr_instr = 0;
        SRAM_readEnable = 0;
        SRAM_writeEnable = 0;
        PC_next = PC;
        ov = 0;
        case (state)
            fetch: begin
                en_read_instr = 1'b1;
                raddr_instr   = PC;
            end
            decode: begin
                OP = instr_op[2:0];
                enable = alu_valid;

                raddrA = instr_in_r[2*M-1:M];
                raddrB = instr_in_r[M-1:0];
                s_rst = br_valid;
                sel_destA = st_valid | ld_valid;
                sel_destB = st_valid | ld_valid;

                SRAM_readEnable = ld_valid;
                SRAM_writeEnable = st_valid;
            end
            execute: begin
                imm = ldimm_valid ? {{((N - M) > 0 ? (N-M+1) : 1) {instr_in_r[M-1]}}, instr_in_r[M-2:0]} : 0;
                write_en = alu_valid | ld_valid | ldimm_valid;
                waddr = instr_in_r[2*M-1:M];
                select_source = alu_valid ? 2'b01 : ld_valid ? 2'b10 : ldimm_valid ? 2'b11 : 2'b00;
                if (br_taken) begin
                    {ov, PC_next} = br_offset[2*M-1] ? PC - br_offset[2*M-2:0] : PC + br_offset[2*M-2:0];
                end else begin
                    {ov, PC_next} = PC + 1'b1;
                end
            end
            default: ;
        endcase
    end
    /*-----------------------------------------------------------------------------*/
    // Registered the output of the FSM when required
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            instr_in_r <= 0;
            br_taken <= 0;
        end else begin
            case (state)
                fetch: begin
                    instr_in_r <= instr_in;
                end
                decode: begin
                    case (instr_op)
                        BRN_Z: br_taken <= ONZ[0] & br_valid;
                        BRN_N: br_taken <= ONZ[1] & br_valid;
                        BRN_O: br_taken <= ONZ[2] & br_valid;
                        BRN: br_taken <= 1'b1;
                        default: ;
                    endcase
                end
                execute: begin
                    br_taken <= 1'b0;
                end
                default: ;
            endcase
        end
        // fill in here

    end

    // PC and overflow
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            PC     <= 0;
            ov_reg <= 0;
        end else begin
            PC     <= PC_next;
            ov_reg <= !ov_reg ? ov : ov_reg;
        end
    end

    assign overflow_warning = ov_reg;

endmodule
