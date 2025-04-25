# Directories
RTL_DIR       := rtl
TB_DIR        := testbench
BUILD_DIR     := build

# Files
DESIGN_FILES  := $(wildcard $(RTL_DIR)/*.sv)
TB_FILES      := $(wildcard $(TB_DIR)/*.sv)
VCD_FILE      := $(BUILD_DIR)/wave.vcd

# Tools
VLOG          := vlog
VSIM          := vsim
GTKWAVE       := gtkwave

# Top module
TOP_MODULE    := spi_tb

# Simulation flags
VSIM_FLAGS    := -c -do "run -all; quit" +vcdfile=$(VCD_FILE) +vcdon

# Default target
all: run

# Full design flow
compile:
	@if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR); fi
	$(VLOG) -work $(BUILD_DIR) $(DESIGN_FILES) $(TB_FILES)

sim: compile
	$(VSIM) -work $(BUILD_DIR) $(VSIM_FLAGS) $(TOP_MODULE)

wave:
	$(GTKWAVE) $(VCD_FILE)

run: sim wave

clean:
	@if [ -d $(BUILD_DIR) ]; then rm -rf $(BUILD_DIR); fi
	@if [ -f transcript ]; then rm -f transcript; fi
	clear
