VT_VERSION = 0.95
DEFINES += VT_VERSION=$$VT_VERSION

VT_IS_TEST_VERSION = 1
#VT_ANDROID_VERSION_ARMV7 = 1
VT_ANDROID_VERSION_ARM64 = 26
#VT_ANDROID_VERSION_X86 = 3

VT_ANDROID_VERSION = $$VT_ANDROID_VERSION_ARM64

# Ubuntu 18.04 (should work on raspbian buster too)
# sudo apt install qml-module-qt-labs-folderlistmodel qml-module-qtquick-extras qml-module-qtquick-controls2 qt5-default libqt5quickcontrols2-5 qtquickcontrols2-5-dev qtcreator qtcreator-doc libqt5serialport5-dev build-essential qml-module-qt3d qt3d5-dev qtdeclarative5-dev qtconnectivity5-dev qtmultimedia5-dev

DEFINES += VT_VERSION=$$VT_VERSION

!vt_test_version: {
    DEFINES += VT_IS_TEST_VERSION=$$VT_IS_TEST_VERSION
}
vt_test_version: {
    DEFINES += VT_IS_TEST_VERSION=1
}


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
QT += svg

TARGET = skypuff
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

android: {
    QT += androidextras
    manifest.input = $$PWD/android/AndroidManifest.xml.in
    manifest.output = $$PWD/android/AndroidManifest.xml
    QMAKE_SUBSTITUTES += manifest
}


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
include(../../QCodeEditor/qcodeeditor.pri)

RESOURCES += \
    qml.qrc \
    ../../res_config.qrc \

DISTFILES += \
    android/AndroidManifest.xml \
    android/AndroidManifest.xml.in \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/src/com/vedder/vesc/VForegroundService.java \
    android/src/com/vedder/vesc/Utils.java

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
