RELEASE=4.0

PACKAGE=pve-libspice-server1
PKGVERSION=0.14.1
PKGRELEASE=3

PKGDIR=spice-${PKGVERSION}
PKGSRC=${PKGDIR}.tar.bz2

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=pve-libspice-server1_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb
DEB_DBG=pve-libspice-server-dev_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb
DEBS=$(DEB) $(DEB_DBG)

CELTDIR=celt-0.5.1.3
CELTSRC=${CELTDIR}.tar.gz

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb: $(DEB)
$(DEB_DBG): $(DEB)
$(DEB): ${PKGSRC}
	echo ${DEBS}
	rm -rf ${PKGDIR}
	tar xf ${PKGSRC}
	# compile CELT first
	tar xf ${CELTSRC} -C ${PKGDIR}
	cd ${PKGDIR}; ln -s ${CELTDIR}/libcelt celt051
	cd ${PKGDIR}/${CELTDIR}; ./configure --prefix=/usr; make
	# now compile spice server
	cp -a debian ${PKGDIR}/debian
	echo "git clone git://git.proxmox.com/git/pve-libspice-server.git\\ngit checkout ${GITVERSION}" > ${PKGDIR}/debian/SOURCE
	cd ${PKGDIR}; dpkg-buildpackage -b -us -uc


.PHONY: download
download:
	rm -f ${PKGSRC} 
	wget http://spice-space.org/download/releases/spice-server/spice-${PKGVERSION}.tar.bz2

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *_${ARCH}.deb *.changes *.dsc *.buildinfo ${PKGDIR}

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
