# Directories
RTL_DIR       := rtl
TB_DIR        := testbench
BUILD_DIR     := build

# Files
DESIGN_FILES  := $(wildcard $(RTL_DIR)/*.sv)
TB_FILES      := $(wildcard $(TB_DIR)/*.sv)
VCD_FILE      := $(BUILD_DIR)/wave.vcd

# Try-specific
TRY_DESIGN    := $(RTL_DIR)/try.sv
TRY_TB        := $(TB_DIR)/try_tb.sv
TRY_VCD       := $(BUILD_DIR)/try_wave.vcd

# Tools
VLOG          := vlog
VSIM          := vsim
GTKWAVE       := gtkwave

# Top module
TOP_MODULE    := spi_tb
TRY_TOP       := try_tb

# Simulation flags
VSIM_FLAGS    := -c -do "run -all; quit" +vcdfile=$(VCD_FILE) +vcdon
TRY_FLAGS     := -c -do "run -all; quit" +vcdfile=$(TRY_VCD) +vcdon

# Default target
all: run

# Full design flow
compile:
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	$(VLOG) -work $(BUILD_DIR) $(DESIGN_FILES) $(TB_FILES)

run: compile
	$(VSIM) -work $(BUILD_DIR) $(VSIM_FLAGS) $(TOP_MODULE)

wave:
	$(GTKWAVE) $(VCD_FILE)

# Try design flow
tcompile:
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	$(VLOG) -work $(BUILD_DIR) $(TRY_DESIGN) $(TRY_TB)

trun: tcompile
	$(VSIM) -work $(BUILD_DIR) $(TRY_FLAGS) $(TRY_TOP)

twave:
	$(GTKWAVE) $(TRY_VCD)

clean:
	@if exist build rmdir /s /q build
	@if exist '-p' rmdir /f /q '-p'
	@if exist transcript del /f /q transcript
