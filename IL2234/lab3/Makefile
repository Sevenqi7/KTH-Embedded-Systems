VSRCS = $(shell find ./ -name '*.v' -o -name '*.sv')
TOP ?= 

# simulate with verilator
verilator: $(VSRCS)
ifeq ($(TOP),)
	@echo "Usage: make TOP=\\TOP_MODEL\\ verilator"
else
	verilator --cc --exe -DTOPMODULE=$(TOP) -j 8 --timing --build -Wall -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC $(VSRCS) sim_main.cpp --trace --top-module $(TOP) 
	./obj_dir/V$(TOP) +trace
	gtkwave ./trace.vcd
endif

# simulate with questasim
# TODO