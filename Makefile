SOURCE=spice
PACKAGE=libspice-server1

PKGVERSION=0.14.2
DEBVERSION=0.14.2-4
PVERELEASE=pve6

VERSION := $(DEBVERSION)~$(PVERELEASE)

PKGDIR=spice-${PKGVERSION}
PKGSRC=${PKGDIR}.tar.bz2

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=$(PACKAGE)_${VERSION}_${ARCH}.deb
DEB_DBG=$(PACKAGE)-dbgsym_${VERSION}_${ARCH}.deb
DEBS=$(DEB) $(DEB_DBG)

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb: $(DEB)
$(DEB_DBG): $(DEB)
$(DEB): $(SOURCE)_$(PKGVERSION).orig.tar.bz2 $(SOURCE)_$(DEBVERSION).debian.tar.xz
	rm -rf ${PKGDIR}
	tar xf $(SOURCE)_$(PKGVERSION).orig.tar.bz2
	tar xf $(SOURCE)_$(DEBVERSION).debian.tar.xz -C $(SOURCE)-$(PKGVERSION)
	cat changelog.Debian $(PKGDIR)/debian/changelog > $(PKGDIR)/debian/changelog.tmp
	mv $(PKGDIR)/debian/changelog.tmp $(PKGDIR)/debian/changelog
	cd $(PKGDIR); for patch in ../patches/*.patch; do echo "applying patch '$$patch'" && patch -p1 < "$${patch}"; done
	cd ${PKGDIR}; dpkg-buildpackage -b -us -uc
	lintian ${DEBS}


.PHONY: download
download: $(SOURCE)_$(PKGVERSION).orig.tar.bz2 $(SOURCE)_$(DEBVERSION).debian.tar.xz
$(SOURCE)_$(PKGVERSION).orig.tar.bz2: $(SOURCE)_$(DEBVERSION).debian.tar.xz
$(SOURCE)_$(DEBVERSION).debian.tar.xz:
	dget http://deb.debian.org/debian/pool/main/s/spice/spice_0.14.2-4.dsc

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

distclean: clean
	rm -f *.tar.*

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *.deb *.changes *.dsc *.buildinfo ${PKGDIR}

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
