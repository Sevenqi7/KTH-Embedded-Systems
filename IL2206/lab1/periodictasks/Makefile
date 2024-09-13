SRCS ?= 
BUILD_DIR = $(abspath ./build)
BIN = $(BUILD_DIR)/output

all: 
ifndef SRCS
	@echo "SRCS is empty! Usage: make SRCS={ada sources}"	
else
	@mkdir -p $(BUILD_DIR)
	gnatmake $(SRCS) -o $(BIN)
	rm *.ali *.o
endif

quiet-all:
	@make all > /dev/null 2>&1

run: quiet-all
	@sudo taskset -c 0 $(BIN)

	