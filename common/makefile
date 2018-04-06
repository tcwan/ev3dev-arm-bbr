# ARM-BBR Common Library

# -- library name
TARGET = ev3dev-arm-bbr

# -- platform
ifeq ($(OS),Windows_NT)
# WIN32
PLATFORM = __MINGW__
else
# UNIX
PLATFORM = __UNIX__
endif

TOP = ..

# -- compiler
ifeq ($(PLATFORM),__UNIX__)
CC = arm-linux-gnueabi-gcc
CXX = arm-linux-gnueabi-g++
LINK = arm-linux-gnueabi-ar
else
CC = gcc
CXX = g++
LINK = ar
endif

# -- build on EV3 BRICK
ifeq ($(PLATFORM),__UNIX__)
EV3 = $(if $(shell $(CC) -dM -E - < /dev/null | grep __ARM_ARCH_4T__),1,0)
else
EV3 = 0
endif


# -- command to create directories
MKDIR = mkdir -p

# -- output subdirectory
ifeq ($(PLATFORM),__MINGW__)
D_PLATFORM = mingw
else
D_PLATFORM = .
endif

# -- installation directory
ifeq ($(PLATFORM),__MINGW__)
D_INSTALL = $(MINGW_HOME)
else
D_INSTALL = /usr/local
endif

D_INSTALL_H_FROM = include

# -- source directories
D_C = src

D_CXX = $(D_C)
D_ASM = $(D_C)

# -- include directories
D_H = $(TOP)/common/include $(TOP)/include

# -- library directory
D_BIN = $(TOP)/common/lib
D_BIN := $(if $(D_PLATFORM), $(D_BIN)/$(D_PLATFORM), $(D_BIN))

# -- object directory
D_OBJ = $(TOP)/common/object
D_OBJ := $(if $(D_PLATFORM), $(D_OBJ)/$(D_PLATFORM), $(D_OBJ))


E_H = .h
E_C = .c
E_CXX = .cpp
E_ASM = .S

# -- object suffix
E_OBJ = .o

# -- static library suffix
ifeq ($(OS),Windows_NT)
E_BIN = .a
else
E_BIN = .a
endif

# -- shared library suffix
ifeq ($(OS),Windows_NT)
E_BIN_SHARED = .dll
else
E_BIN_SHARED = .so
endif

# -- full name of static library
F_BIN = $(D_BIN)/lib$(TARGET)$(E_BIN)

# -- full name of shared library
F_BIN_SHARED = $(D_BIN)/lib$(TARGET)$(E_BIN_SHARED)

# -- static library link options
LFLAGS = rcs

# -- shared library link options
LFLAGS_SHARED = -shared

ifeq ($(PLATFORM),__UNIX__)
LFLAGS_SHARED := $(LFLAGS_SHARED) -fPIC
else
LFLAGS_SHARED := $(LFLAGS_SHARED) -Wl,--out-implib,$(strip $(F_BIN_SHARED)).a -lws2_32
endif

# Enable Debug Symbols by default
# -- compiler flags
CFLAGS = $(addprefix -I, $(D_H)) -O2 -std=gnu99 -W -Wall -Wno-comment -g

ifeq ($(PLATFORM),__UNIX__)
CFLAGS := $(CFLAGS) -fPIC
endif

CXXFLAGS = $(addprefix -I, $(D_H)) -O2 -ffast-math -funroll-loops -fno-exceptions -fomit-frame-pointer -g -W -Wall -Wno-comment -g

ifeq ($(PLATFORM),__UNIX__)
CXXFLAGS := $(CXXFLAGS) -fPIC
endif

ASMFLAGS = -Wall -g

# ---------------------------------
#   files lists
# ---------------------------------
G_H = $(wildcard $(addsuffix /*$(E_H), $(D_H)))

S_C = $(sort $(wildcard $(addsuffix /*$(E_C), $(D_C))) $(G_C))
S_CXX = $(sort $(wildcard $(addsuffix /*$(E_CXX), $(D_CXX))) $(G_CXX))
S_ASM = $(wildcard $(addsuffix /*$(E_ASM), $(D_ASM)))
S_INSTALL_H = $(wildcard $(addsuffix /*$(E_H), $(D_INSTALL_H_FROM)))

O_CXX = $(addprefix $(D_OBJ)/, $(addsuffix $(E_OBJ), $(basename $(notdir $(S_CXX)))))
O_C = $(addprefix $(D_OBJ)/, $(addsuffix $(E_OBJ), $(basename $(notdir $(S_C)))))
O_ASM = $(addprefix $(D_OBJ)/, $(addsuffix $(E_OBJ), $(basename $(notdir $(S_ASM)))))

O = $(O_CXX) $(O_C) $(O_ASM)

# ---------------------------------
#   commands
# ---------------------------------

_BASH = 1

ifeq ($(OS),Windows_NT)
ifdef ComSpec
_BASH = 0
endif
endif

ifeq ($(_BASH),0)
# -- cmd
RM = cmd /c del /f
else
# -- sh (MSYS)
RM = rm -rf
endif

# -- wrap compiler arguments
ifeq ($(OS),Windows_NT)
# -- too long command line workaround
define wrap
	echo $2 > args
	$1 @args
	-$(RM) args
endef
else
define wrap
	$1 $2
endef
endif

# -- optional final tools
define final
endef

# -- removal list
R_BIN = $(F_BIN) $(F_BIN_SHARED) $(O)
R = $(R_BIN)

ifeq ($(_BASH),0)
# -- cmd
CLEAN = cmd /c del /f $(subst /,\,$(R))
CLEAN_BIN = cmd /c del /f $(R_BIN)
else
# -- sh (MSYS)
CLEAN = rm -rf $(R)
CLEAN_BIN = rm -rf $(R_BIN)
endif

# -- install library
define install
	${MKDIR} $(D_INSTALL)/lib
	cp -f $1 $(D_INSTALL)/lib
	${MKDIR} $(D_INSTALL)/include
	cp -f $(S_INSTALL_H) $(D_INSTALL)/include
endef

# ---------------------------------
#   make rules
# ---------------------------------

vpath %$(E_CXX) $(D_CXX)
vpath %$(E_C) $(D_C)
vpath %$(E_ASM) $(D_ASM)

# ---- build library
.PHONY: default shared

# -- build static library
default: bindirs $(F_BIN)

# -- build shared library
shared: bindirs $(F_BIN_SHARED)

$(F_BIN): $(O)
	$(call wrap,$(LINK),$(LFLAGS) $@ $^)
	$(call final,$@)
	@echo "*** $(F_BIN) ***"

$(F_BIN_SHARED): $(O)
	$(call wrap,$(CC),$^ $(LFLAGS_SHARED) -o $@)
	$(call final,$@)
	@echo "*** $(F_BIN_SHARED) ***"

$(S_C) $(S_CXX) $(S_ASM): $(G_H)

$(O_C): $(D_OBJ)/%$(E_OBJ): %$(E_C)
	$(call wrap,$(CC),$(CFLAGS) -c $< -o $@)

$(O_CXX): $(D_OBJ)/%$(E_OBJ): %$(E_CXX)
	$(call wrap,$(CXX),$(CXXFLAGS) -c $< -o $@)

$(O_ASM): $(D_OBJ)/%$(E_OBJ): %$(E_ASM)
	$(call wrap,$(CC),$(ASMFLAGS) -c $< -o $@)

# -- create 'object' and 'bin' directories
bindirs: $(D_OBJ) $(D_BIN)

$(D_OBJ):
	${MKDIR} ${D_OBJ}

$(D_BIN):
	${MKDIR} ${D_BIN}

# ---- remove temporary files
.PHONY: clean

clean:
	$(CLEAN)

# ---- remove binary and object files
.PHONY: clean-binary

clean-binary:
	$(CLEAN_BIN)

# ---- install
.PHONY: install shared-install

install:
	$(call install,$(F_BIN))

shared-install:
	$(call install,$(F_BIN_SHARED))
	ldconfig

# -- EOF
