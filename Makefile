COQC=coqc
USE_NIX ?= false

ifeq ($(USE_NIX), false)
	COQ_FLAGS=-R theories SepDiagram -Q vendor/cfml/lib/coq CFML -Q vendor/tlc/src TLC
else
	COQ_FLAGS=-R theories SepDiagram
endif

COQ_MF_FLAGS := $(COQ_FLAGS) -arg "-w -implicit-core-hint-db,-ambiguous-paths,-notation-incompatible-prefix,-automatic-prop-lowering"


# libraries

tlc:
	$(MAKE) -C vendor/tlc -j4
.PHONY: tlc

cfml: tlc
	$(MAKE) -C vendor/cfml .depend_lib
	$(MAKE) COQEXTRAFLAGS="-Q ../tlc/src TLC" -C vendor/cfml libcoq
.PHONY: cfml


# theories

VFILES = WPUntyped.v SepvizNotations.v ListNull.v LiterateQueue.v LiterateTree.v
ALLVFILES = $(patsubst %,theories/%,$(VFILES))
ALLVOFILES := $(patsubst %.v,%.vo,$(ALLVFILES))

build: Makefile.coq
	$(MAKE) -f Makefile.coq
	$(MAKE) sepviz
.PHONY: build

clean::
	if [ -e Makefile.coq ]; then $(MAKE) -f Makefile.coq cleanall; fi
	$(RM) $(wildcard Makefile.coq Makefile.coq.conf)
	$(MAKE) clean-sepviz
.PHONY: clean

Makefile.coq:
	coq_makefile $(COQ_MF_FLAGS) -o Makefile.coq $(ALLVFILES)

-include Makefile.coq


# sep-viz

.PHONY: sepviz clean-sepviz

ALECTRYON_FLAGS := \
  $(COQ_FLAGS) \
  --webpage-style windowed \
  --long-line-threshold 0

SEPVIZ_OUTDIR ?= _sepviz_build
SEPVIZ_MODULES = LiterateQueue LiterateTree
SEPVIZ_HTMLS := $(patsubst %,$(SEPVIZ_OUTDIR)/CFML-%.html, $(SEPVIZ_MODULES))

sepviz: $(SEPVIZ_HTMLS)
.PHONY: sepviz

$(SEPVIZ_OUTDIR):
	mkdir -p $@

$(SEPVIZ_OUTDIR)/CFML-%.html: theories/%.v | $(ALLVOFILES)
	alectryon $(ALECTRYON_FLAGS) --output $@ $<

clean-sepviz:
	rm -rf $(SEPVIZ_OUTDIR)
.PHONY: clean-sepviz
