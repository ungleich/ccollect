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

prefix=/usr/packages/ccollect-git
bindir=$(prefix)/bin
destination=$(bindir)/$(CCOLLECT)

path_dir=/usr/local/bin
path_destination=$(path_dir)/$(CCOLLECT)

# where to publish
host=creme.schottelius.org
dir=www/org/schottelius/linux/ccollect
docdir=$(dir)/doc

#
# Asciidoc will be used to generate other formats later
#
MANDOCS  = doc/man/ccollect.text
DOCS     = $(MANDOCS) doc/ccollect.text doc/ccollect-DE.text

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
	@cg-update creme

push-work:
	@cg-push creme
	@cg-push sygroup

publish-doc: documentation
	@echo "Transferring files to $(host)"
	@chmod a+r doc/*.html doc/*.text
	@scp doc/*.text doc/*.html doc/*.texi doc/man/*.man $(host):$(docdir)
	@ssh $(host) "cd $(docdir); chmod a+r *"

#
# Doku
#
HTMLDOCS = $(DOCS:.text=.html)

TEXIDOCS = $(DOCS:.text=.texi)

MANPDOCS = $(MANDOCS:.text=.man)

DOCBDOCS = $(DOCS:.text=.docbook)


html: $(HTMLDOCS)

info: $(TEXIDOCS)

man: $(MANPDOCS) 

documentation: html info man

#
# Distribution
#
allclean:
	rm -f $(TEXIDOCS) $(HTMLDOCS) $(MANPDOCS) $(DOCBDOCS)

distclean:
	rm -f $(DOCBDOCS)

#
# Be nice with the users and generate documentation for them
#
dist: distclean documentation
