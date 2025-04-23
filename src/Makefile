# Makefile for CONMOD

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

SRCDIR_MK = ../srcdir.mk
SRC_DIR = ../src
-include $(SRCDIR_MK)

AS = has060
ASFLAGS = -w2 -c3 -i./include
LD ?= hlk
LDFLAGS =
CV = cv
U8TOSJ = u8tosj

ifeq ($(findstring hlkx,$(LD)),hlkx)
USE_HLKX = true
endif

TARGET = conmod.r
ARCHIVE_ZIP = conmd.zip

SRCS = conmod.s
OBJS = $(SRCS:.s=.o)
DOCS = README.txt CHANGELOG.txt LICENSE


.PHONY: all archive clean
.PRECIOUS: %.o %.x

all: $(TARGET)

%.x: %.s
%.o: %.s
	$(AS) $(ASFLAGS) -o$@ $<

%.x: %.o
	$(LD) $(LDFLAGS) -o$@ $^

ifdef USE_HLKX
%.r: %.o
	$(LD) $(LDFLAGS) -r -o$@ $^
else
%.r: %.x
	$(CV) $< $@
endif


archive: $(ARCHIVE_ZIP)

$(ARCHIVE_ZIP): $(DOCS) $(TARGET)
	rm -f $@
	zip -9 $@ $^

%.txt: $(SRC_DIR)/../%.md
	rm -f $@
	$(U8TOSJ) < $^ > $@

LICENSE: $(SRC_DIR)/../LICENSE
	rm -f $@
	cp $< $@


clean:
	rm -f $(ARCHIVE_ZIP) $(DOCS) $(TARGET) $(OBJS)

# EOF
