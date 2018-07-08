CONFIG -= qt

SOURCES += elsamuko-saturation.c

CONFIG += link_pkgconfig
PKGCONFIG += gimp-2.0 gimpui-2.0 gtk+-2.0

QMAKE_POST_LINK += gimptool-2.0 --install-bin elsamuko-saturation;
