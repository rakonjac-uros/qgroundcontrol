/****************************************************************************
 *
 * (c) 2009-2019 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 *   @brief Custom QGCCorePlugin Declaration
 *   @author Gus Grubba <gus@auterion.com>
 */

#pragma once

#include "QGCCorePlugin.h"
#include "QGCOptions.h"
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"

#include <QTranslator>

class CustomOptions;
class SYOSPlugin;
class CustomSettings;

Q_DECLARE_LOGGING_CATEGORY(CustomLog)

class SYOSPlugin : public QGCCorePlugin
{
    Q_OBJECT
public:
    SYOSPlugin(QGCApplication* app, QGCToolbox *toolbox);
    ~SYOSPlugin();
    QQmlApplicationEngine*  createQmlApplicationEngine      (QObject* parent) final;
};
