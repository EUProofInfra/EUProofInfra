###########################################################################
# Automating proposal management by make.
# The participants work on proposal.tex in "draft" mode, which gives a lot
# of information to the developers. Variants submit.tex and public.tex are
# used to prepare official versions (hiding development/private info). 
###########################################################################
# possibly customize the following variables to your setting
PROPOSAL = propB.tex 		# the proposal
PROP.dir = LaTeX-proposal#      # The LaTeX-proposal class directory
BIB = lib/kbibs/kwarc.bib
TSIMP = 	                # pdflatex Targets without bibTeX
###########################################################################
# the following are computed
TSIMP.pdf 	= $(TSIMP:%.tex=%.pdf)            # PDFs to be produced
TBIB = $(PROPOSAL) 		  	  	  # pdflatex Targets with bibTeX
TARGET = $(TSIMP) $(TBIB)                         # all pdflatex targets
TBIB.pdf 	= $(TBIB:%.tex=%.pdf)         	  # PDFs to be produced
TBIB.aux 	= $(TBIB:%.tex=%.aux)             # their aux files.
PDATA 		= $(PROPOSAL:%.tex=%.pdata)       # the proposal project data
SRC = $(filter-out $(TARGET),$(shell ls *.tex lib/WApersons.tex sites/*.tex workpackages/*.tex))   # included files
MODE = -interaction scrollmode
PDFLATEX = pdflatex $(MODE) -file-line-error
PROPCLS.dir = $(PROP.dir)/base
PROPETC.dir = $(PROP.dir)/etc
EUPROPCLS.dir = $(PROP.dir)/eu
TEXINPUTS := .//:$(PROPCLS.dir)//:$(EUPROPCLS.dir)//:$(PROPETC.dir)//:
BIBINPUTS := lib/kbibs:$(BIBINPUTS)
export TEXINPUTS
export BIBINPUTS
PROPCLS.clssty = proposal.cls pdata.sty
PROPETC.sty = workaddress.sty metakeys.sty sref.sty
EUPROPCLS.clssty = euproposal.cls
PROPCLS = $(PROPCLS.clssty:%=$(PROPCLS.dir)/%) $(EUPROPCLS.clssty:%=$(EUPROPCLS.dir)/%) $(PROPETC.sty:%=$(PROPETC.dir)/%)
#Orrm = || $(RM) $@
All: $(TBIB.pdf) $(TSIMP.pdf)

submit:
	$(MAKE) -$(MAKEFLAGS) -w PROPOSAL=submit.tex

SPLIT.at = $(shell cat SPLIT.at)
SPLIT = $$(($(SPLIT.at) + 1))
SSPLIT = $$(($(SPLIT.at) + 2))
split: submit
	qpdf --pages submit.pdf 1-$(SPLIT) -- submit.pdf submit-123.pdf
	qpdf --pages submit.pdf $(SSPLIT)-z -- submit.pdf submit-45.pdf

public:  $(SRC)
	$(MAKE) -$(MAKEFLAGS) -w PROPOSAL=public.tex all

grantagreement:
	$(MAKE) -$(MAKEFAGS) -w PROPOSAL=grantagreement.tex -W grantagreement.tex all
	pdftk grantagreement.pdf cat 1-35 61-end output grantagreement-striped.pdf
	mv grantagreement-striped.pdf grantagreement.pdf


install: submit
	cp submit.pdf proposal-www.pdf
	git commit -m "Updated pdf" proposal-www.pdf
	git push

$(TSIMP.pdf): %.pdf: %.tex $(PROPCLS) $(PDATA)
	$(PDFLATEX) $< $(ORRM)

$(PDATA): %.pdata: %.tex
	$(PDFLATEX) $< $(ORRM)

$(TBIB.aux): %.aux: %.tex
	$(PDFLATEX) $< $(ORRM)

$(TBIB.pdf): %.pdf: %.tex $(SRC) $(BIB) $(PROPCLS) 
	$(PDFLATEX) $<  $(ORRM)
	sort $(PROPOSAL:%.tex=%.delivs) > $(PROPOSAL:%.tex=%.deliverables)
	@if (test -e $(patsubst %.tex, %.idx,  $<));\
	    then makeindex $(patsubst %.tex, %.idx,  $<); fi
	biber $(basename $<)
	@if (grep "(re)run" $(patsubst %.tex, %.log,  $<)> /dev/null);\
	    then biber $(basename $<); fi
	$(PDFLATEX)  $< $(ORRM)
	@if (grep Rerun $(patsubst %.tex, %.log,  $<) > /dev/null);\
	   then $(PDFLATEX)  $<  $(ORRM); fi
	@if (grep Rerun $(patsubst %.tex, %.log,  $<) > /dev/null);\
	    then $(PDFLATEX)  $<  $(ORRM); fi

clean: 
	rm -f *~ *.log *.ilg *.out *.glo *.idx *.ilg *.blg *.run.xml *.synctex.gz *.cut *.toc

distclean: clean
	rm -f *.aux *.ind *.gls *.ps *.dvi *.thm *.out *.run.xml *.bbl *.toc *.deliv* *.pdata *-blx.bib
	rm -Rf auto
	rm -f proposal.fls

echo:
	@echo $(PROPCLS)
