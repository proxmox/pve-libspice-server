RELEASE=3.0

PACKAGE=pve-libspice-server1
PKGVERSION=0.12.4
PKGRELEASE=1

PKGDIR=spice-${PKGVERSION}
PKGSRC=${PKGDIR}.tar.bz2

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

DEBS=pve-libspice-server1_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb  \
pve-libspice-server-dev_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb		

CELTDIR=celt-0.5.1.3
CELTSRC=${CELTDIR}.tar.gz

all: ${DEBS}
	echo ${DEBS}

${DEBS}: ${PKGSRC}
	echo ${DEBS}
	rm -rf ${PKGDIR}
	tar xf ${PKGSRC}
	# compile CELT first
	tar xf ${CELTSRC} -C ${PKGDIR}
	cd ${PKGDIR}; ln -s ${CELTDIR}/libcelt celt051
	cd ${PKGDIR}/${CELTDIR}; ./configure --prefix=/usr; make
	# now compile spice server
	cp -a debian ${PKGDIR}/debian
	cd ${PKGDIR}; dpkg-buildpackage -rfakeroot -b -us -uc


.PHONY: download
download:
	rm -f ${PKGSRC} 
	wget http://spice-space.org/download/releases/spice-${PKGVERSION}.tar.bz2

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/Packages*
	rm -f /pve/${RELEASE}/extra/pve-libspice-server1_*.deb
	rm -f /pve/${RELEASE}/extra/pve-libspice-server-dev_*.deb
	rm -f /pve/${RELEASE}/extra/pve-libspice-server1_*.deb
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *_${ARCH}.deb *.changes *.dsc ${PKGDIR}

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
