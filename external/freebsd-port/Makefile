# New ports collection makefile for:   oneko
# New ports collection makefile for: ccollect
# Date created:        2006-10-20
# Whom:                Nico Schottelius <nico-fbsd-ccollect@schottelius.org>
#
# $FreeBSD$
#

PORTNAME=      ccollect
PORTVERSION=   0.5.1
CATEGORIES=    sysutils archivers
MASTER_SITES=  http://unix.schottelius.org/ccollect/

MAINTAINER=    nico-fbsd-ccollect@schottelius.org
COMMENT=       (pseudo) incremental (parallel) backup

MAN1=          ccollect.sh.1
MANCOMPRESSED= no
USE_BZIP2=		yes

RUN_DEPENDS=	rsync:${PORTSDIR}/net/rsync

.include <bsd.port.mk>
