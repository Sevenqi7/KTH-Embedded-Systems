#include "VALU_tb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv) {
  VerilatedVcdC *tracep = new VerilatedVcdC;
  VerilatedContext *contextp = new VerilatedContext;
  contextp->traceEverOn(true);
  contextp->randReset(5);
  contextp->commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  VALU_tb *alu_tb = new VALU_tb{contextp};
  alu_tb->trace(tracep, 99);
  tracep->open("./trace.vcd");
  // contextp->dump
  while (!contextp->gotFinish()) {
    alu_tb->eval();
    tracep->dump(contextp->time());
    contextp->timeInc(1);
    // printf("contextime:%d\n",contextp->time());
  }
  tracep->close();
  alu_tb->final();

  return 0;
}