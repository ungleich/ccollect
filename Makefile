#
# ccollect
# Nico Schottelius, Fri Jan 13 12:13:08 CET 2006
#

INSTALL=install
CCOLLECT=ccollect.sh
LN=ln -sf

prefix=/usr/packages/ccollect-0.2
bindir=$(prefix)/bin
destination=$(bindir)/$(CCOLLECT)

path_dir=/usr/local/bin
path_destination=$(path_dir)/$(CCOLLECT)

# where to publish
host=creme.schottelius.org
dir=www/org/schottelius/linux/ccollect
docdir=$(dir)/doc

all:
	@echo "Nothing to make, make install."

documentation:
	@echo "Generating HTML-documentation"
	@asciidoc -n -o doc/ccollect.html  doc/ccollect.text

publish-doc: documentation
	@chmod a+r doc/ccollect.html
	@scp doc/ccollect.html doc/ccollect.text $(host):$(docdir)

install:
	$(INSTALL) -D -m 0755 -s $(CCOLLECT) $(destination)
	$(LN) $(destination) $(path_destination)
