VT_VERSION = 0.95
DEFINES += VT_VERSION=$$VT_VERSION

#VT_ANDROID_VERSION_ARMV7 = 56
VT_ANDROID_VERSION_ARM64 = 57
#VT_ANDROID_VERSION_X86 = 58

#VT_ANDROID_VERSION = $$VT_ANDROID_VERSION_X86

# Ubuntu 18.04 (should work on raspbian buster too)
# sudo apt install qml-module-qt-labs-folderlistmodel qml-module-qtquick-extras qml-module-qtquick-controls2 qt5-default libqt5quickcontrols2-5 qtquickcontrols2-5-dev qtcreator qtcreator-doc libqt5serialport5-dev build-essential qml-module-qt3d qt3d5-dev qtdeclarative5-dev qtconnectivity5-dev qtmultimedia5-dev

DEFINES += VT_VERSION=$$VT_VERSION

CONFIG += build_mobile
CONFIG += c++11
QT += core
QT += gui
QT += widgets
QT += serialport
QT += network
QT += printsupport
QT += quick
QT += multimedia

TARGET = application
TEMPLATE = app

# Serial port available
DEFINES += HAS_SERIALPORT

# Bluetooth available
DEFINES += HAS_BLUETOOTH

contains(DEFINES, HAS_SERIALPORT) {
    QT += serialport
}

contains(DEFINES, HAS_BLUETOOTH) {
    QT += bluetooth
}

android: QT += androidextras

INCLUDEPATH += ../..

SOURCES += main.cpp \
    skypuff.cpp \
    qmlable_skypuff_types.cpp

HEADERS += \ 
    skypuff.h \
    app_skypuff.h \
    qmlable_skypuff_types.h
    
contains(DEFINES, HAS_BLUETOOTH) {
    SOURCES += ../../bleuart.cpp
    HEADERS += ../../bleuart.h
}

include(../../application.pri)
include(../../widgets/widgets.pri)
include(../../lzokay/lzokay.pri)

RESOURCES += \
    qml.qrc \
    ../../res_config.qrc \

