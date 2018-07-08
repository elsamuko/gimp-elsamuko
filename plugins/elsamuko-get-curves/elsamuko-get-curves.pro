CONFIG -= qt
SOURCES += elsamuko-get-curves.c
unix: !macx: CONFIG += linux

linux {
    CONFIG += link_pkgconfig
    PKGCONFIG += gimp-2.0 gtk+-2.0

    QMAKE_POST_LINK += gimptool-2.0 --install-bin elsamuko-get-curves;
}

win32 {
    MSYSHOME  = C:\msys64\home\samuel\projects
    MINGWHOME = C:\msys64\mingw64

    INCLUDEPATH +=  $${MSYSHOME}\gegl\gegl \
                    $${MSYSHOME}\gegl\gegl\buffer \
                    $${MSYSHOME}\gegl\gegl\graph \
                    $${MSYSHOME}\gegl\gegl\property-types \
                    $${MSYSHOME}\gegl\gegl\process \
                    $${MSYSHOME}\babl \
                    $${MSYSHOME}\gimp \
                    \
                    $${MINGWHOME}\include\cairo \
                    $${MINGWHOME}\include\glib-2.0 \
                    $${MINGWHOME}\lib\glib-2.0\include \
                    $${MINGWHOME}\include\gdk-pixbuf-2.0 \
                    $${MINGWHOME}\include\gtk-3.0 \
                    $${MINGWHOME}\lib\gtk-3.0\include \
                    $${MINGWHOME}\include\pango-1.0 \
                    $${MINGWHOME}\include\atk-1.0

    LIBS +=         -L'C:\Program Files\GIMP 2\bin' \
                    -llibgimpui-2.0-0 \
                    -llibgimpwidgets-2.0-0 \
                    -llibgimpmodule-2.0-0 \
                    -llibgimp-2.0-0 \
                    -llibgimpmath-2.0-0 \
                    -llibgimpconfig-2.0-0 \
                    -llibgimpcolor-2.0-0 \
                    -llibgimpbase-2.0-0 \
                    -llibgegl-0.4-0 \
                    -llibgegl-npd-0.4 \
                    -lm \
                    -lgmodule-2.0 \
                    -pthread \
                    -ljson-glib-1.0 \
                    -lgio-2.0 \
                    -llibbabl-0.1-0 \
                    -llibgtk-win32-2.0-0 \
                    -llibgdk-win32-2.0-0 \
                    -lpangocairo-1.0 \
                    -latk-1.0 \
                    -lcairo \
                    -lgdk_pixbuf-2.0 \
                    -lgio-2.0 \
                    -lpangoft2-1.0 \
                    -lpango-1.0 \
                    -lgobject-2.0 \
                    -lglib-2.0 \
                    -lfontconfig \
                    -lfreetype
}
