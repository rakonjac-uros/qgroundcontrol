message("Adding Custom Plugin")

#-- Version control
#   Major and minor versions are defined here (manually)

CUSTOM_QGC_VER_MAJOR = 1
CUSTOM_QGC_VER_MINOR = 0
CUSTOM_QGC_VER_FIRST_BUILD = 0

# Build number is automatic
# Uses the current branch. This way it works on any branch including build-server's PR branches
CUSTOM_QGC_VER_BUILD = $$system(git --git-dir ../.git rev-list $$GIT_BRANCH --first-parent --count)
win32 {
    CUSTOM_QGC_VER_BUILD = $$system("set /a $$CUSTOM_QGC_VER_BUILD - $$CUSTOM_QGC_VER_FIRST_BUILD")
} else {
    CUSTOM_QGC_VER_BUILD = $$system("echo $(($$CUSTOM_QGC_VER_BUILD - $$CUSTOM_QGC_VER_FIRST_BUILD))")
}
CUSTOM_QGC_VERSION = $${CUSTOM_QGC_VER_MAJOR}.$${CUSTOM_QGC_VER_MINOR}.$${CUSTOM_QGC_VER_BUILD}

DEFINES -= APP_VERSION_STR=\"\\\"$$APP_VERSION_STR\\\"\"
DEFINES += APP_VERSION_STR=\"\\\"$$CUSTOM_QGC_VERSION\\\"\"

message(Custom QGC Version: $${CUSTOM_QGC_VERSION})

# Branding

DEFINES += CUSTOMHEADER=\"\\\"SYOSPlugin.h\\\"\"
DEFINES += CUSTOMCLASS=SYOSPlugin

TARGET   = SYOSQGroundControl
DEFINES += QGC_APPLICATION_NAME='"\\\"SYOS QGroundControl\\\""'

DEFINES += QGC_ORG_NAME=\"\\\"syos-aerospace.com\\\"\"
DEFINES += QGC_ORG_DOMAIN=\"\\\"com.syos-aerospace\\\"\"

QGC_APP_NAME        = "SYOS QGroundControl"
QGC_BINARY_NAME     = "SYOSQGroundControl"
QGC_ORG_NAME        = "SYOS Aerospace"
QGC_ORG_DOMAIN      = "com.syos-aerospace"
QGC_ANDROID_PACKAGE = "com.syos-aerospace.qgroundcontrol"
QGC_APP_DESCRIPTION = "SYOS QGroundControl"
QGC_APP_COPYRIGHT   = "Copyright (C) 2024 SYOS QGroundControl Development Team. All rights reserved."

# Our own, custom resources
RESOURCES += \
    $$PWD/custom.qrc

QML_IMPORT_PATH += \
   $$PWD/res

# Our own, custom sources
SOURCES += \
    $$PWD/src/SYOSPlugin.cc \

HEADERS += \
    $$PWD/src/SYOSPlugin.h \

INCLUDEPATH += \
    $$PWD/src \

