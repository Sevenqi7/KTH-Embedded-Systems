VSRCS = $(shell find ./ -name '*.v' -o -name '*.sv')
TOP = ALU_tb

# simulate with verilator
verilator: $(VSRCS)
	verilator --cc --exe -j 8 --timing --build -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC $(VSRCS) sim_main.cpp --trace --top-module $(TOP) 
	./obj_dir/V$(TOP) +trace
	gtkwave ./trace.vcd

# simulate with questasim
# TODO