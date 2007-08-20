#
# ccollect
# Nico Schottelius, Fri Jan 13 12:13:08 CET 2006
#

INSTALL=install
CCOLLECT_SOURCE=ccollect.sh
CCOLLECT_DEST=ccollect.sh
LN=ln -sf
ASCIIDOC=asciidoc
DOCBOOKTOTEXI=docbook2x-texi
DOCBOOKTOMAN=docbook2x-man
XSLTPROC=xsltproc
XSL=/usr/share/xml/docbook/stylesheet/nwalsh/html/docbook.xsl
A2X=a2x

prefix=/usr/packages/ccollect-git
bindir=${prefix}/bin
destination=${bindir}/${CCOLLECT_DEST}

mandest=${prefix}/man/man1
manlink=/usr/local/man/man1

path_dir=/usr/local/bin
path_destination=${path_dir}/${CCOLLECT_DEST}

# where to publish
host=home.schottelius.org
dir=www/org/schottelius/unix/www/ccollect/
docdir=${dir}/doc

#
# Asciidoc will be used to generate other formats later
#
MANDOCS  = doc/man/ccollect.text 			\
	doc/man/add_ccollect_source.text 		\
	doc/man/delete_ccollect_source.text		\
	doc/man/ccollect-logwrapper.text			\
	doc/man/list_ccollect_intervals.text

DOCS     = ${MANDOCS} doc/ccollect.text doc/ccollect-DE.text

#
# Doku
#
HTMLDOCS = ${DOCS:.text=.html}
DBHTMLDOCS = ${DOCS:.text=.htm}

# texi is broken currently, don't know why xslt things complain yet
TEXIDOCS = ${DOCS:.text=.texi}
TEXIDOCS = 

# fop fails here, so disable it for now
PDFDOCS  =  ${DOCS:.text=.pdf}
PDFDOCS  = 

MANPDOCS = ${MANDOCS:.text=.1}

DOCBDOCS = ${DOCS:.text=.docbook}

DOC_ALL  = ${HTMLDOCS} ${DBHTMLDOCS} ${TEXIDOCS} ${MANPDOCS} ${PDFDOCS}

html: ${HTMLDOCS}
htm: ${DBHTMLDOCS}
info: ${TEXIDOCS}
man: ${MANPDOCS} 
pdf: ${PDFDOCS} 
documentation: ${DOC_ALL}

#
# End user targets
#
all:
	@echo "----------- ccollect make targets --------------"
	@echo "documentation:    generate HTMl, Texinfo and manpage"
	@echo "html:             only generate HTML"
	@echo "info:             only generate Texinfo"
	@echo "man:              only generate manpage{s}"
	@echo "install:          install ccollect to ${prefix}"

install: install-link install-manlink

install-link: install-script
	${LN} ${destination} ${path_destination}

install-script:
	${INSTALL} -D -m 0755 ${CCOLLECT_SOURCE} ${destination}

install-man: man
	${INSTALL} -d -m 0755 ${mandest}
	${INSTALL} -D -m 0644 doc/man/*.1 ${mandest}

install-manlink: install-man
	${INSTALL} -d -m 0755 ${manlink}
	for man in ${mandest}/*; do ${LN} $$man ${manlink}; done


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

#%.mandocbook: %.text
#	${ASCIIDOC} -b docbook -d manpage -o $@ $<

#%.man: %.mandocbook
#	${DOCBOOKTOMAN} --to-stdout $< > $@

#%.man: %.text
%.1: %.text
	${A2X} -f manpage $<

%.pdf: %.text
	${A2X} -f pdf $<


#
# Developer targets
#
update:
	@git push

publish-doc: documentation
	@echo "Transferring files to ${host}"
	@chmod a+r ${DOCS} ${DOC_ALL}
	@tar c ${DOCS} ${DOC_ALL} | ssh ${host} "cd ${dir}; tar xv"

#
# Distribution
#
clean:
	rm -f ${DOC_ALL}
	rm -f doc/man/*.[0-9] doc/man/*.xml doc/*.fo doc/man/*.fo

distclean: clean
	rm -f ${DOCBDOCS}

#
# Be nice with the users and generate documentation for them
#
dist: distclean documentation

test: ccollect.sh documentation
	CCOLLECT_CONF=./conf ./ccollect.sh daily "source with spaces"
