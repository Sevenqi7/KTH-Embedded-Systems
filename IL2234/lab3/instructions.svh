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
`ifndef INSTR_DEFINE
`define INSTR_DEFINE
parameter ADD     = 4'b0000;
parameter SUB     = 4'b0001;
parameter AND     = 4'b0010;
parameter OR      = 4'b0011;
parameter XOR     = 4'b0100;
parameter NOT     = 4'b0101;
parameter MOV     = 4'b0110;
parameter NOP     = 4'b0111;
parameter LOAD    = 4'b1000;
parameter STORE   = 4'b1001;
parameter LOAD_IM = 4'b1010;
parameter BRN_Z   = 4'b1011;
parameter BRN_N   = 4'b1100;
parameter BRN_O   = 4'b1101;
parameter BRN     = 4'b1110;
`endif