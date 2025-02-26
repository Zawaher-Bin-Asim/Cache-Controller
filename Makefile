# Existing variables
SOURCES_SV := define/cache_defs.svh \
               src/dcache_datapath.sv \
               src/dcache_controller.sv \
               src/dcache.sv \
			   src/axi_lite.sv \
               test/cache_tb.sv

SOURCES_CPP := test/cache_tb.cpp

COMP_OPT_SV := \
    --incr \
    --relax

DEFINE_VIVADO := -d Vivado
DEFINE_VERILATOR := -DVerilator

TB_TOP := cache_tb
MODULE := cache_tb

.PHONY: simulate elaborate compile

# Simulation using Vivado
simulate: $(TB_TOP)_snapshot.wdb

elaborate: .elab.timestamp

compile: .comp.timestamp

viv_waves: $(TB_TOP)_snapshot.wdb
	@echo
	@echo "### OPENING WAVEFORMS ###"
	xsim --gui $(TB_TOP)_snapshot.wdb

$(TB_TOP)_snapshot.wdb: .elab.timestamp
	@echo
	@echo "### SIMULATING ###"
	xsim $(TB_TOP)_snapshot --tclbatch xsim_cfg.tcl

.elab.timestamp: .compile.timestamp
	@echo
	@echo "### ELABORATING ###"
	xelab -debug all -top $(TB_TOP) -snapshot $(TB_TOP)_snapshot
	touch .elab.timestamp

.compile.timestamp: $(SOURCES_SV)
	@echo
	@echo "### COMPILING SYSTEM VERILOG ###"
	xvlog --sv $(COMP_OPT_SV) $(SOURCES_SV) $(DEFINE_VIVADO)
	@echo "log_wave -recursive *" >> xsim_cfg.tcl
	@echo "run all" >> xsim_cfg.tcl
	@echo "exit" >> xsim_cfg.tcl
	touch .compile.timestamp

#================================================================#
#                                                                #
#                VERILATOR MAKEFILE                              #
#                                                                #
#================================================================#

INCLUDE_DIR := define

VERILATOR_FLAGS := \
    --top-module $(MODULE) \
    -Wno-DECLFILENAME \
    -Wno-WIDTH \
    -Wno-REDEFMACRO \
    -Wno-INITIALDLY \
    -Wno-lint \
    -Wno-ASSIGNIN \
    -Wno-MULTIDRIVEN \
    -Wno-UNOPTFLAT  \
    -I$(INCLUDE_DIR)

.PHONY: ver_sim verilate build

ver_sim: ver_waves

verilate: .stamp.verilate

build: ./obj_dir/V$(MODULE)

ver_waves:
	@echo
	@echo "### VERILATOR WAVES ###"
	gtkwave waveform.vcd

verilator: ./obj_dir/V$(MODULE)
	@echo
	@echo "### SIMULATING ###"
	@ ./obj_dir/V$(MODULE)

./obj_dir/V$(MODULE): .stamp.verilate
	@echo
	@echo "### BUILDING SIMULATION ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

.stamp.verilate: $(SOURCES_SV) $(SOURCES_CPP)
	@echo
	@echo "### VERILATING ###"
	verilator --trace $(VERILATOR_FLAGS) -cc $(SOURCES_SV) $(DEFINE_VERILATOR) --exe $(SOURCES_CPP) --timing
	@touch .stamp.verilate

.PHONY: lint

lint: $(SOURCES_SV)
	verilator --lint-only $(SOURCES_SV)


#================================================================#
#                                                                #
#                VSIM MAKEFILE                                   #
#                                                                #
#================================================================#

WORK_DIR = work

# Create a working library and compile source files
vsim_compile:
	@mkdir -p log
	@echo "Creating work library..."
	vlib $(WORK_DIR)
	@echo "Compiling source files..."
	vlog -work $(WORK_DIR) $(SOURCES_SV)

# Run the simulation and generate WLF file
vsim_simulate: vsim_compile
	@echo "Running simulation and generating WLF file..."
	vsim -L $(WORK_DIR) $(TB_TOP) -do "add wave -radix Decimal sim:/$(TB_TOP)/*; run -all"

# Show the simulation output (command-line mode)
vsim: vsim_compile
	@echo "Running simulation"
	vsim -c -L $(WORK_DIR) $(TB_TOP) -do "run -all; quit;"

#================================================================#
#                                                                #
#                COCOTB TEST_BENCH                               #
#                                                                #
#================================================================#

cocotb:
	make -C test/


.PHONY : clean
clean:
	rm -rf *.jou *.log *.pb *.wdb xsim.dir *.str *.tcl
	rm -rf .*.timestamp
	rm -rf .stamp.*
	rm -rf ./obj_dir
	rm -rf waveform.vcd *.vvp
	rm -rf test/__pycache__
	rm -rf test/sim_build
	rm -rf test/*.xml
	rm -rf work 1 2 
	rm -rf *.wlf
	rm -rf transcript
	rm -rf .Xil log 