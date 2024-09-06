SRCS ?= Main.adb
BUILD_DIR = $(abspath ./build)
BIN = $(BUILD_DIR)/Main

all: 
	@mkdir -p $(BUILD_DIR)
	gnatmake $(SRCS) -o $(BIN)
	rm *.ali *.o

quiet-all:
	@make all > /dev/null 2>&1

run: quiet-all
	@$(BIN)

	