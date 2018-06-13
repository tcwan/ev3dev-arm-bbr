#Top level makefile

DIRS=source/*/ 

EVDEVC = ./ev3dev-c
ARMBBR = ./common
EVDEVCLIBS = $(EVDEVC)/lib/libev3dev-c.a $(EVDEVC)/lib/libev3dev-c.so
ARMBBRLIBS = $(ARMBBR)/lib/libev3dev-arm-bbr.a $(ARMBBR)/lib/libev3dev-arm-bbr.so
ASM_HEADERS = $(EVDEVC)/asm/*.h

# Actual builds

$(EVDEVC)/lib/libev3dev-c.a:
	make -C ev3dev-c/source/ev3 SKIP_PP=0	

$(EVDEVC)/lib/libev3dev-c.so:
	make -C ev3dev-c/source/ev3 SKIP_PP=0 shared

$(ARMBBR)/lib/libev3dev-arm-bbr.a:
	make -C common

$(ARMBBR)/lib/libev3dev-arm-bbr.so:
	make -C common shared


# meta builds
clean::
	@echo "Cleaning ..." ${DIRS}
	@for i in ${DIRS}; \
	do \
	make -f Makefile.proj -C $${i} clean; \
	done

clean-ev3dev-c-libs::
	make -C ev3dev-c/source/ev3 clean

clean-arm-bbr-libs::
	make -C common clean

clean-libs:: clean-ev3dev-c-libs clean-arm-bbr-libs

clean-headers::
	make -C ev3dev-c/asm clean

ev3dev-c-libs:: $(EVDEVC)/lib/libev3dev-c.a

ev3dev-c-shared-libs:: $(EVDEVC)/lib/libev3dev-c.so

arm-bbr-libs:: $(ARMBBR)/lib/libev3dev-arm-bbr.a

arm-bbr-shared-libs:: $(ARMBBR)/lib/libev3dev-arm-bbr.so

asm-headers::
	make -C ev3dev-c/asm

libs:: ev3dev-c-libs arm-bbr-libs

shared-libs:: ev3dev-c-shared-libs arm-bbr-shared-libs

all:: $(EVDEVCLIBS) $(ARMBBRLIBS) $(ASM_HEADERS)
	@echo "Making ..." ${DIRS}
	@for i in ${DIRS}; \
	do \
	make -f Makefile.proj -C $${i}; \
	done

source/*::
	make -f Makefile.proj -C $@;
	
source/*/*::
	make -f Makefile.subproject -C $@;

docs::
	cd doc; doxygen
