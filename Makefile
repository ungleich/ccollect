#
# ccollect
# Nico Schottelius, Fri Jan 13 12:13:08 CET 2006
#

INSTALL=install
CCOLLECT=ccollect.sh
LN=ln -sf

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
# End user targets
#
all:
	@echo "Nothing to make, make install."

install: install-script install-link

install-link: install-script
	$(LN) $(destination) $(path_destination)

install-script:
	$(INSTALL) -D -m 0755 -s $(CCOLLECT) $(destination)

documentation:
	@echo "Generating HTML-documentation (de en) ..."
	@asciidoc -n -o doc/ccollect.html  doc/ccollect.text
	@asciidoc -n -o doc/ccollect-DE.html  doc/ccollect-DE.text

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
	@scp doc/*.text doc/*.html $(host):$(docdir)
