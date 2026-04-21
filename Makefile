COQC=coqc
USE_NIX ?= false
OUT_DIR ?= _sepviz_build

ifeq ($(USE_NIX), false)
	COQ_FLAGS=-R theories SepDiagram -Q vendor/cfml/lib/coq CFML -Q vendor/tlc/src TLC
else
	COQ_FLAGS=-R theories SepDiagram
endif

ALECTRYON_FLAGS := \
  $(COQ_FLAGS) \
  --webpage-style windowed \
  --coq-driver sertop \
  --long-line-threshold 0

LIB := theories/lib
EXM := theories/examples

VFILES_IN_LIB := SepViz_Notations.v WPUntyped.v ListNull.v
VFILES_IN_EXM := LiterateQueue.v LiterateTree.v LiterateTest.v

LIB_VFILES := $(addprefix $(LIB)/, $(VFILES_IN_LIB))
LIB_VO_FILES := $(addprefix $(LIB)/, $(VFILES_IN_LIB:.v=.vo))
EXM_VO_FILES := $(addprefix $(EXM)/, $(VFILES_IN_EXM:.v=.vo))
# HTML_FILES := $(addprefix $(OUT_DIR)/, $(VFILES_IN_EXM:.v=.html))
HTML_FILES := $(OUT_DIR)/CFML-Queue.html $(OUT_DIR)/CFML-Tree.html $(OUT_DIR)/CFML-Test.html

.PHONY: default sepviz tlc cfml clean-web clean-theories clean test

default: $(LIB_VO_FILES) $(EXM_VO_FILES) $(HTML_FILES)

sepviz: $(HTML_FILES)

tlc:
	$(MAKE) -C vendor/tlc -j4

cfml: tlc
	$(MAKE) -C vendor/cfml .depend_lib
	$(MAKE) COQEXTRAFLAGS="-Q ../tlc/src TLC" -C vendor/cfml libcoq

%.vo: %.v
	$(COQC) $(COQ_FLAGS) $<

$(LIB)/WPUntyped.vo: $(LIB)/SepViz_Notations.vo
$(LIB)/ListNull.vo: $(LIB)/WPUntyped.vo


$(OUT_DIR):
	mkdir -p $@

$(OUT_DIR)/CFML-Queue.html: $(EXM)/LiterateQueue.v $(LIB_VFILES:.v=.vo)
	alectryon $(ALECTRYON_FLAGS) --output $@ $<

$(OUT_DIR)/CFML-Tree.html: $(EXM)/LiterateTree.v $(LIB_VFILES:.v=.vo)
	alectryon $(ALECTRYON_FLAGS) --output $@ $<

$(OUT_DIR)/CFML-Test.html: $(EXM)/LiterateTest.v $(LIB_VFILES:.v=.vo)
	alectryon $(ALECTRYON_FLAGS) --output $@ $<

clean-web:
	rm -rf $(OUT_DIR)

clean-theories:
	find theories \( -name "*.vo" -o -name "*.vos" -o -name "*.vok" -o -name "*.glob" \) -delete

clean: clean-web clean-theories

test: default
	firefox $(OUT_DIR)/LiterateQueue.html
	firefox $(OUT_DIR)/LiterateTree.html
