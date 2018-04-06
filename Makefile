#Top level makefile

DIRS=source/*/ 

EVDEVC = ./ev3dev-c
EVDEVCLIBS = $(EVDEVC)/lib/libev3dev-c.a $(EVDEVC)/lib/libev3dev-c.so
ASM_HEADERS = $(EVDEVC)/asm/*.h

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

ev3dev-c-libs::
	make -C ev3dev-c/source/ev3 SKIP_PP=0	

ev3dev-c-shared-libs::
	make -C ev3dev-c/source/ev3 SKIP_PP=0 shared

arm-bbr-libs::
	make -C common

arm-bbr-shared-libs::
	make -C common shared

asm-headers::
	make -C ev3dev-c/asm

libs:: ev3dev-c-libs arm-bbr-libs

shared-libs:: ev3dev-c-shared-libs arm-bbr-shared-libs

all:: $(EVDEVCLIBS) $(ASM_HEADERS)
	@echo "Making ..." ${DIRS}
	@for i in ${DIRS}; \
	do \
	make -f Makefile.proj -C $${i}; \
	done

source/*::
	make -f Makefile.proj -C $@;
	
source/*/*::
	make -f Makefile.subproject -C $@;