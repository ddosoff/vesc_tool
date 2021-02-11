VT_VERSION = 2.07
VT_IS_TEST_VERSION = 1
DEFINES += VT_VERSION=$$VT_VERSION

CONFIG += c++11

QT += core
QT += gui
QT += widgets
QT += serialport
QT += network
QT += printsupport

TARGET = application
TEMPLATE = app

# Serial port available
DEFINES += HAS_SERIALPORT

# Bluetooth available
DEFINES += HAS_BLUETOOTH

!vt_test_version: {
    DEFINES += VT_IS_TEST_VERSION=$$VT_IS_TEST_VERSION
}
vt_test_version: {
    DEFINES += VT_IS_TEST_VERSION=1
}

contains(DEFINES, HAS_SERIALPORT) {
    QT += serialport
}

contains(DEFINES, HAS_BLUETOOTH) {
    QT += bluetooth
}

INCLUDEPATH += ../../

SOURCES += main.cpp\
    mainwindow.cpp

HEADERS  += mainwindow.h \
    commands.h \
    configparam.h \
    configparams.h \
    datatypes.h \
    packet.h \
    vescinterface.h \
    vbytearray.h \
    utility.h \
    tcpserversimple.h \
    udpserversimple.h

FORMS += mainwindow.ui
    
contains(DEFINES, HAS_BLUETOOTH) {
    SOURCES += ../../bleuart.cpp
    HEADERS += ../../bleuart.h
}

include(../../application.pri)
include(../../widgets/widgets.pri)
include(../../lzokay/lzokay.pri)

RESOURCES += \
    ../../res_config.qrc

