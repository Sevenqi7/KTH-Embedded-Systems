#include "VFSM_tb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv) {
  VerilatedVcdC *tracep = new VerilatedVcdC;
  VerilatedContext *contextp = new VerilatedContext;
  contextp->traceEverOn(true);
  contextp->randReset(5);
  contextp->commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  VFSM_tb *rf_tb = new VFSM_tb{contextp};
  rf_tb->trace(tracep, 3);
  tracep->open("./trace.vcd");
  // contextp->dump
  while (!contextp->gotFinish()) {
    rf_tb->eval();
    tracep->dump(contextp->time());
    contextp->timeInc(1);
    // printf("contextime:%d\n",contextp->time());
  }
  tracep->close();
  rf_tb->final();
  
  return 0;
}