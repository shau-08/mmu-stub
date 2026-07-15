# Stub Makefile -- deliberately does NOT invoke Mill/Chisel. Only exists
# to prove the CI/CD trigger/dispatch chain works mechanically, isolated
# from real toolchain concerns.

-include cd.config
RTL_TARGET ?= rtl
TARGET ?= stub

.PHONY: test rtl lazyrtl rtl-dispatch

test:
	@echo "stub test target -- pretending to run ChiselTest successfully"

rtl:
	@mkdir -p generated_sv_dir
	@echo "// stub generated RTL for TARGET=$(TARGET)" > generated_sv_dir/stub.sv
	@echo "stub rtl target -- wrote generated_sv_dir/stub.sv"

lazyrtl: rtl

rtl-dispatch:
	@$(MAKE) $(RTL_TARGET) TARGET=$(TARGET)
