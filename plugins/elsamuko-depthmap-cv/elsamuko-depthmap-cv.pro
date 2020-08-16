CONFIG -= qt
SOURCES += elsamuko-depthmap-cv.cpp

CONFIG += link_pkgconfig

# sudo apt install libgimp2.0-dev libopencv-dev
PKGCONFIG += gimp-2.0 gimpui-2.0 gtk+-2.0 opencv4

QMAKE_POST_LINK += gimptool-2.0 --install-bin elsamuko-depthmap-cv
