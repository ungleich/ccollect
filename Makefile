#
# ccollect
# Nico Schottelius, Fri Jan 13 12:13:08 CET 2006
#

INSTALL=install
CCOLLECT=ccollect.sh
LN=ln -sf
ASCIIDOC=asciidoc
DOCBOOKTOTEXI=docbook2x-texi
DOCBOOKTOMAN=docbook2x-man
XSLTPROC=xsltproc
XSL=/usr/share/xml/docbook/stylesheet/nwalsh/html/docbook.xsl

prefix=/usr/packages/ccollect-git
bindir=$(prefix)/bin
destination=$(bindir)/$(CCOLLECT)

path_dir=/usr/local/bin
path_destination=$(path_dir)/$(CCOLLECT)

# where to publish
host=home.schottelius.org
dir=www/org/schottelius/unix/www/ccollect/
docdir=$(dir)/doc

#
# Asciidoc will be used to generate other formats later
#
MANDOCS  = doc/man/ccollect.text
DOCS     = $(MANDOCS) doc/ccollect.text doc/ccollect-DE.text

#
# Doku
#
HTMLDOCS = $(DOCS:.text=.html)
DBHTMLDOCS = $(DOCS:.text=.htm)

TEXIDOCS = $(DOCS:.text=.texi)

MANPDOCS = $(MANDOCS:.text=.man)

DOCBDOCS = $(DOCS:.text=.docbook)

DOC_ALL  = $(HTMLDOCS) $(DBHTMLDOCS) $(TEXIDOCS) $(MANPDOCS)

html: $(HTMLDOCS)
htm: $(DBHTMLDOCS)
info: $(TEXIDOCS)
man: $(MANPDOCS) 
documentation: $(DOC_ALL)

#
# End user targets
#
all:
	@echo "----------- ccollect make targets --------------"
	@echo "documentation:    generate HTMl, Texinfo and manpage"
	@echo "html:             only generate HTML"
	@echo "info:             only generate Texinfo"
	@echo "man:              only generate manpage(s)"
	@echo "install:          install ccollect to $(prefix)"

install: install-script install-link

install-link: install-script
	$(LN) $(destination) $(path_destination)

install-script:
	$(INSTALL) -D -m 0755 $(CCOLLECT) $(destination)


# docbook gets .htm, asciidoc directly .html
%.htm: %.docbook
	${XSLTPROC} -o $@ ${XSL} $<

%.html: %.text %.docbook
	${ASCIIDOC} -n -o $@ $<

%.html: %.text
	${ASCIIDOC} -n -o $@ $<

%.docbook: %.text
	${ASCIIDOC} -n -b docbook -o $@ $<

%.texi: %.docbook
	${DOCBOOKTOTEXI} --to-stdout $< > $@

%.mandocbook: %.text
	${ASCIIDOC} -b docbook -d manpage -o $@ $<

%.man: %.mandocbook
	${DOCBOOKTOMAN} --to-stdout $< > $@

#
# Developer targets
#
update:
	@cg-update home

push-work:
	@cg-push home
	@cg-push sygroup

publish-doc: documentation
	@echo "Transferring files to $(host)"
	@chmod a+r $(DOCS) $(DOC_ALL)
	@tar c $(DOCS) $(DOC_ALL) | ssh $(host) "cd $(dir); tar xv"

#
# Distribution
#
allclean:
	rm -f $(DOC_ALL)

distclean: allclean
	rm -f $(DOCBDOCS)

#
# Be nice with the users and generate documentation for them
#
dist: distclean documentation
