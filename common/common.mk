 #---------------------------------------------------------------------------------
# common.mk -- shared build rules for the Swift NDS examples.
#
# An example Makefile sets TARGET (and optionally NDS_TITLE / NDS_SUBTITLE) and
# then `include ../common/common.mk`. Each example has a single source/main.swift;
# the shared C support in common/ is compiled alongside it.
#---------------------------------------------------------------------------------
.SUFFIXES:

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitpro")
endif
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=$$DEVKITPRO/devkitARM")
endif

# Embedded Swift compiler. Override on the command line: make SWIFTC=/path/to/swiftc
SWIFTC		?=	swiftc

# Directory holding this makefile (and the shared shim / module map).
COMMON		:=	$(dir $(lastword $(MAKEFILE_LIST)))

TARGET		?=	$(notdir $(CURDIR))
NDS_TITLE	?=	$(TARGET)
NDS_SUBTITLE	?=	swift-nds
BUILD		:=	build

LIBNDS		:=	$(DEVKITPRO)/libnds
CALICO		:=	$(DEVKITPRO)/calico

PREFIX		:=	$(DEVKITARM)/bin/arm-none-eabi-
CC		:=	$(PREFIX)gcc
LD		:=	$(PREFIX)gcc

#---------------------------------------------------------------------------------
# code generation -- ARM946E-S / armv5te, soft float, no FPU.
#---------------------------------------------------------------------------------
ARCH		:=	-march=armv5te -mtune=arm946e-s -mthumb

# Modern libnds sits on calico: nds.h requires __NDS__ and pulls in <calico.h>.
NDSDEFS		:=	-DARM9 -D__NDS__ -I$(COMMON) \
			-I$(LIBNDS)/include -I$(CALICO)/include

CFLAGS		:=	-g -Wall -O2 -ffunction-sections -fdata-sections $(ARCH) \
			$(NDSDEFS)

# calico ships the linker specs and a calico_ds9 runtime that nds9 links against.
LDFLAGS		:=	-specs=$(CALICO)/share/ds9.specs -g $(ARCH) \
			-Wl,-Map,$(TARGET).map -Wl,--gc-sections \
			-L$(LIBNDS)/lib -L$(CALICO)/lib

LIBS		?=	-lnds9 -lcalico_ds9

#---------------------------------------------------------------------------------
# Embedded Swift flags.
#
# The prebuilt Embedded stdlib ships an armv4t slice but no armv5te slice;
# armv4t code runs on the NDS's ARM946E-S (armv5te is backwards compatible).
# Embedded clang is pointed at newlib + libnds + calico + our module map.
#---------------------------------------------------------------------------------
SWIFTFLAGS	:=	-target armv4t-none-none-eabi \
			-enable-experimental-feature Embedded \
			-wmo -Osize \
			-Xcc -DARM9 -Xcc -D__NDS__ \
			-Xcc -march=armv5te -Xcc -mfloat-abi=soft \
			-Xcc -isystem -Xcc $(DEVKITARM)/arm-none-eabi/include \
			-Xcc -I$(COMMON) \
			-Xcc -I$(LIBNDS)/include \
			-Xcc -I$(CALICO)/include \
			-Xcc -fmodule-map-file=$(COMMON)module.modulemap

OFILES		:=	$(BUILD)/main.swift.o $(BUILD)/shim.o

#---------------------------------------------------------------------------------
.PHONY: all clean

all: $(TARGET).nds

$(BUILD):
	@mkdir -p $@

# Swift -> object
$(BUILD)/main.swift.o: source/main.swift $(COMMON)module.modulemap $(COMMON)nds_umbrella.h $(COMMON)shim.h | $(BUILD)
	@echo compiling $(notdir $<)
	$(SWIFTC) $(SWIFTFLAGS) -c $< -o $@

# Shared C shim -> object (devkitARM)
$(BUILD)/shim.o: $(COMMON)shim.c $(COMMON)shim.h | $(BUILD)
	@echo $(notdir $<)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).elf: $(OFILES)
	@echo linking $(notdir $@)
	$(LD) $(LDFLAGS) $(OFILES) $(LIBS) -o $@

$(TARGET).nds: $(TARGET).elf
	@echo packaging $(notdir $@)
	ndstool -c $@ -9 $< -7 $(CALICO)/bin/ds7_maine.elf \
		-b $(CALICO)/share/nds-icon.bmp "$(NDS_TITLE);$(NDS_SUBTITLE);swift-nds"

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).elf $(TARGET).nds $(TARGET).map
