#############################
# User variables
#############################
TB        ?= tb
SEED      ?= 1
SIMDIR    ?= .
LIBDIR    ?= .
TESTNAME  ?= ppa_basic_test

# Lab1 源文件 - 后续根据实际实现添加
DFILES    = $(SIMDIR)/apb_slave_if.sv \
            $(SIMDIR)/packet_sram.sv

VFILES    = $(SIMDIR)/$(TB).sv


#############################
# Environment variables
#############################
VCOMP     = vlog -work $(LIBDIR)/work -cover bst -sv -timescale=1ns/1ps -l comp.log
RUN       = vsim -work $(LIBDIR)/work -voptargs=+acc -classdebug -solvefaildebug -msgmode both -uvmcontrol=all -assertdebug -assertcounts $(TB) -l run.log -cover -cvgperinstance -cvgmergeinstances +sv_seed=$(SEED) +UVM_TESTNAME=$(TESTNAME)

comp:
	$(VCOMP) $(DFILES) $(VFILES)

run:
	$(RUN) +CMD_LINE -c -do "run -all; quit -f" 

rung:
	$(RUN) -i

smoke:
	$(VCOMP) $(DFILES) $(VFILES)
	$(RUN) -c -do "run -all; quit -f"

regress:
	$(VCOMP) $(DFILES) $(VFILES)
	$(RUN) -c -do "run -all; quit -f"

cov:
	$(VCOMP) $(DFILES) $(VFILES)
	$(RUN) -c -do "run -all; coverage save -onexit coverage.ucdb; quit -f"

clean:
	rm -rf VRMDATA vrmhtmlreport
	rm -rf *.log* work *.wlf coverage.ucdb
