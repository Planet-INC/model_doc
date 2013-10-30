texfigsources := $(shell find ./rawfigs/src/ -maxdepth 1 -name '*.tex')
vectorsources := $(shell find ./rawfigs/ -name '*.dia' -o -name '*.eps' -o -name '*.ps' -o -name '*.svg')
rastersources := $(shell find ./rawfigs/ -name '*.jpg' -o -name '*.gif')
readysources := $(shell find ./rawfigs/ -name '*.png' -o -name '*.pdf')
texsource := $(wildcard main.tex)

texfigs := $(shell echo ' ' $(texfigsources) ' ' | sed -e 's> \(./\)*raw> >g' -e 's/src\///g' -e 's/\.[^. ]* /.pdf /g')
vectorfigs := $(shell echo ' ' $(vectorsources) ' ' | sed -e 's> \(./\)*raw> >g' -e 's/\.[^. ]* /.pdf /g')
rasterfigs := $(shell echo ' ' $(rastersources) ' ' | sed -e 's> \(./\)*raw> >g' -e 's/\.[^. ]* /.png /g')
readyfigs := $(shell echo ' ' $(readysources) ' ' | sed -e 's> \(./\)*raw> >g')
figures := $(vectorfigs) $(rasterfigs) $(readyfigs) $(texfigs)
texroot := $(patsubst %.tex, %, $(texsource))

bibfiles := $(wildcard *.bib)
styfiles := $(wildcard ./*.sty)
clsfiles := $(wildcard ./*.cls)

BIBTEX     ?= bibtex
PDFLATEX   ?= pdflatex -halt-on-error -jobname $(texfinal)
LATEX      ?= latex -halt-on-error -jobname $(texfinal)
texfinal   ?= Planet

all: $(texfinal)

texfigs: $(texfigs) cleantexfigs

cleantexfigs:
	@rm -f ./figs/*.{aux,bbl,blg,log,dvi,nav,out,snm,toc,vrb,lof,lot,gnuplot,table}

figures: $(figures) 

$(texfinal): *.tex $(bibfiles) $(figures) $(clsfiles) $(styfiles)
	if cat $(texroot).tex | grep \bibliography 2>&1; then $(PDFLATEX) $(call texroot,$@); fi
	if (cat $(texroot).tex | grep \bibliography 2>&1 && ls $(call texfinal,$@).aux 2>&1); then $(BIBTEX) $(call texfinal,$@); fi
	$(PDFLATEX) $(call texroot,$@) && $(PDFLATEX) $(call texroot,$@) && $(PDFLATEX) $(call texroot,$@)

clean: cleanlatex cleanfigs

cleanlatex:
	rm -f $(patsubst %.tex, %.aux, $(wildcard *.tex)) 
	rm -f $(shell find ./ -name '*.aux' -o -name '*.log' -o -name '*.bbl' -o -name '*.blg' -o -name '*.dvi' -o -name '*.nav' -o -name '*.out' -o -type f -name '*.pdf' -o -name '*.snm' -o -name '*.toc' -o -name '*.vrb' -o -name '*.lof' -o -name '*.lot')

cleanfigs:
	rm -f $(figures)

figs/%.pdf: rawfigs/%.dia
	@mkdir -p $(dir $@)
	dia -t eps-builtin -e $?_roytemp.eps $? && epstopdf $?_roytemp.eps -o=$@
	@rm -f $?_roytemp.eps

figs/%.pdf: rawfigs/%.eps
	@mkdir -p $(dir $@)
	epstopdf $? -o=$@

figs/%.pdf: rawfigs/src/%.tex
	@mkdir -p $(dir $@)
	pdflatex -output-directory $(dir $@) -halt-on-error -shell-escape $? && pdflatex -output-directory $(dir $@) -halt-on-error -shell-escape $?
	@rm -f $(shell find $(dir $@) -name '*.aux' -o -name '*.log')

figs/%.pdf: rawfigs/%.pdf
	@mkdir -p $(dir $@)
	@reldir=`echo $(dir $@) | sed -e 's>[^/]*/*>../>g'`; ln -sf $${reldir}$? $@

figs/%.pdf: rawfigs/%.ps
	@mkdir -p $(dir $@)
	ps2pdf $? $@

figs/%.pdf: rawfigs/%.svg
	@mkdir -p $(dir $@)
	inkscape $? -z --export-pdf=$@

figs/%.png: rawfigs/%.jpg
	@mkdir -p $(dir $@)
	convert $? $@

figs/%.png: ./rawfigs/%.png
	@mkdir -p $(dir $@)
	@reldir=`echo $(dir $@) | sed -e 's>[^/]*/*>../>g'`; ln -sf $${reldir}$? $@
