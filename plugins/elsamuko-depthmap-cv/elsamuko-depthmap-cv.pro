CONFIG -= qt
SOURCES += elsamuko-depthmap-cv.cpp

CONFIG += link_pkgconfig
PKGCONFIG += gimp-2.0 gimpui-2.0 gtk+-2.0 opencv

QMAKE_POST_LINK += gimptool-2.0 --install-bin elsamuko-depthmap-cv
