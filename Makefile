#Top level makefile

DIRS=source/*/ 
LIBS=ev3dev-c/lib/libev3dev-c.a ev3dev-c/lib/libev3dev-c.so
ASM_HEADERS=ev3dev-c/asm/*.h

clean::
	@for i in ${DIRS}; \
	do \
	make -C $${i} clean; \
	done

clean-libs::
	make -C ev3dev-c/source/ev3 clean
	
clean-headers::
	make -C ev3dev-c/asm clean

$(LIBS)::
	make -C ev3dev-c/source/ev3  SKIP_PP=0	
	make -C ev3dev-c/source/ev3 SKIP_PP=0 shared
	
$(ASM_HEADERS)::
	make -C ev3dev-c/asm

all:: $(LIBS) $(ASM_HEADERS)
	@for i in ${DIRS}; \
	do \
	make -C $${i}; \
	done
	