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

all:
	@echo "Nothing to make, make install."

documentation:
	@asciidoc -n -o doc/ccollect.html  doc/ccollect.text

install:
	$(INSTALL) -D -m 0755 -s $(CCOLLECT) $(destination)
	$(LN) $(destination) $(path_destination)
