RTL   := $(wildcard rtl/*.v)
TB    := alu_tb alu_control_tb control_tb regfile_tb utils_tb bram_tb pc_tb pipe_reg_tb
IV    := iverilog -g2012
VVP   := vvp
BUILD := build
SIMDIR := sim

.PHONY: all unit lint clean

all: unit

$(BUILD):
	mkdir -p $(BUILD)

# ---------- unit tests ----------
$(BUILD)/%.vvp: $(RTL) $(SIMDIR)/%.v | $(BUILD)
	$(IV) -o $@ -s $* $(RTL) $(SIMDIR)/$*.v

unit: $(addprefix $(BUILD)/,$(addsuffix .vvp,$(TB)))
	@for t in $(TB); do \
		(cd $(SIMDIR) && ../$(BUILD)/$$t.vvp) || exit 1; \
	done
	@echo "ALL UNIT TESTS PASS"

# ---------- lint ----------
lint:
	verilator --lint-only -Wall -Wno-fatal -Wno-WIDTH -Wno-UNUSEDSIGNAL -Wno-PINCONNECTEMPTY $(RTL)

# ---------- clean ----------
clean:
	rm -rf $(BUILD)
	rm -f $(SIMDIR)/*.vcd