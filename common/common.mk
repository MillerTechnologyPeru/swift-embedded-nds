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

LIBS		?=	-lnds9 -lcalico_ds9 -lm

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
# Optional asset pipelines.
#
#   GRAPHICS -- directory of <name>.png/.bmp + <name>.grit pairs, converted with
#               grit into tile/palette data.
#   DATA     -- directory of <name>.bin blobs, embedded with bin2s (display
#               lists, textures, raw bitmaps, ...).
#
# Each tool emits an assembly data file (compiled and linked in) plus a header
# of extern declarations. All generated headers are gathered into
# $(BUILD)/assets.h, handed to Swift as a bridging header so the symbols are
# visible alongside `import CNDS`. Because a C global array imports into Swift as
# a tuple (a *copy*), assets.h also emits an nds_asset_<symbol>() accessor that
# returns the address of the real linked symbol -- use that whenever a pointer is
# handed back to libnds (consoleSetFont, glCallList, glTexImage2D, ...).
#---------------------------------------------------------------------------------
GRAPHICS	?=
DATA		?=
ASSET_H		:=
ASSET_O		:=

ifneq ($(strip $(GRAPHICS)),)
vpath %.png  $(GRAPHICS)
vpath %.bmp  $(GRAPHICS)
vpath %.tga  $(GRAPHICS)
vpath %.grit $(GRAPHICS)
PNGFILES	:=	$(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.png)))
BMPFILES	:=	$(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.bmp)))
TGAFILES	:=	$(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.tga)))
GFXBASES	:=	$(PNGFILES:.png=) $(BMPFILES:.bmp=) $(TGAFILES:.tga=)
ASSET_H		+=	$(addprefix $(BUILD)/,$(addsuffix .h,$(GFXBASES)))
ASSET_O		+=	$(addprefix $(BUILD)/,$(addsuffix .o,$(GFXBASES)))
endif

ifneq ($(strip $(DATA)),)
vpath %.bin  $(DATA)
vpath %.pcx  $(DATA)
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.bin)))
PCXFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.pcx)))
ASSET_H		+=	$(addprefix $(BUILD)/,$(BINFILES:.bin=_bin.h)) $(addprefix $(BUILD)/,$(PCXFILES:.pcx=_pcx.h))
ASSET_O		+=	$(addprefix $(BUILD)/,$(BINFILES:.bin=_bin.o)) $(addprefix $(BUILD)/,$(PCXFILES:.pcx=_pcx.o))
endif

# Pre-assembled data: a directory of ready-made grit/Cearn `.s` files shipped
# with the example (paired with hand-written headers listed in EXTRA_HEADERS).
ASM_ASSETS	?=
ifneq ($(strip $(ASM_ASSETS)),)
vpath %.s  $(ASM_ASSETS)
ASMDATAFILES	:=	$(foreach dir,$(ASM_ASSETS),$(notdir $(wildcard $(dir)/*.s)))
ASSET_O		+=	$(addprefix $(BUILD)/,$(ASMDATAFILES:.s=.o))
endif

# Hand-written headers (e.g. texture-packer uvcoord tables) to expose to Swift.
EXTRA_HEADERS	?=

ifneq ($(strip $(ASSET_H))$(strip $(EXTRA_HEADERS)),)
ASSETS_H	:=	$(BUILD)/assets.h
OFILES		+=	$(ASSET_O)
SWIFTFLAGS	+=	-Xcc -I$(BUILD) -import-objc-header $(ASSETS_H)
SWIFTDEPS	:=	$(ASSETS_H) $(ASSET_H) $(EXTRA_HEADERS)
endif

#---------------------------------------------------------------------------------
.PHONY: all clean

all: $(TARGET).nds

$(BUILD):
	@mkdir -p $@

# grit: image (+ .grit options) -> assembly data + extern header
$(BUILD)/%.s $(BUILD)/%.h: %.png %.grit | $(BUILD)
	@echo grit $(notdir $<)
	grit $< -fts -o$(BUILD)/$*

$(BUILD)/%.s $(BUILD)/%.h: %.bmp %.grit | $(BUILD)
	@echo grit $(notdir $<)
	grit $< -fts -o$(BUILD)/$*

$(BUILD)/%.s $(BUILD)/%.h: %.tga %.grit | $(BUILD)
	@echo grit $(notdir $<)
	grit $< -fts -o$(BUILD)/$*

# bin2s: raw blob -> assembly data + extern header (<name>_<ext> / <name>_<ext>.h)
$(BUILD)/%_bin.s $(BUILD)/%_bin.h: %.bin | $(BUILD)
	@echo bin2s $(notdir $<)
	bin2s -a 4 -H $(BUILD)/$*_bin.h $< > $(BUILD)/$*_bin.s

$(BUILD)/%_pcx.s $(BUILD)/%_pcx.h: %.pcx | $(BUILD)
	@echo bin2s $(notdir $<)
	bin2s -a 4 -H $(BUILD)/$*_pcx.h $< > $(BUILD)/$*_pcx.s

# generated data -> object (devkitARM)
$(BUILD)/%.o: $(BUILD)/%.s
	@echo $(notdir $<)
	$(CC) $(CFLAGS) -c $< -o $@

# pre-assembled ASM_ASSETS data (found via vpath) -> object (devkitARM)
$(BUILD)/%.o: %.s | $(BUILD)
	@echo assembling $(notdir $<)
	$(CC) $(CFLAGS) -c $< -o $@

# Gather generated headers into one bridging header for Swift, and emit a
# stable-pointer accessor for each grit symbol. A C global array imports into
# Swift as a tuple (a *copy*), so `withUnsafeBytes(of:)` only yields a temporary;
# `nds_asset_<name>()` returns the address of the real linked symbol, which is
# valid for the lifetime of the program (needed when a pointer is handed to
# libnds, e.g. consoleSetFont).
$(ASSETS_H): $(ASSET_H) $(EXTRA_HEADERS) | $(BUILD)
	@printf '#ifndef SWIFT_NDS_ASSETS_H\n#define SWIFT_NDS_ASSETS_H\n' > $@
	@for h in $(notdir $(ASSET_H)); do printf '#include "%s"\n' "$$h" >> $@; done
	@for h in $(EXTRA_HEADERS); do printf '#include "%s"\n' "$(CURDIR)/$$h" >> $@; done
	@for h in $(ASSET_H) $(EXTRA_HEADERS); do \
	  grep -E '^(extern )?const .*\[[0-9]*\]' $$h | \
	  sed -E 's/^.*[^A-Za-z0-9_]([A-Za-z_][A-Za-z0-9_]*)\[[0-9]*\].*$$/static inline const void *nds_asset_\1(void) { return \1; }/' >> $@; \
	done
	@printf '#endif\n' >> $@

# Swift -> object
$(BUILD)/main.swift.o: source/main.swift $(COMMON)module.modulemap $(COMMON)nds_umbrella.h $(COMMON)shim.h $(SWIFTDEPS) | $(BUILD)
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
