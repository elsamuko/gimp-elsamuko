CONFIG -= qt
SOURCES += elsamuko-get-curves.c

CONFIG += link_pkgconfig
PKGCONFIG += gimp-2.0 gtk+-2.0

QMAKE_POST_LINK += gimptool-2.0 --install-bin elsamuko-get-curves;
