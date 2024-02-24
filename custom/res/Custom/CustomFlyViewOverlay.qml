/****************************************************************************
 *
 * (c) 2009-2019 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 * @file
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick          2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

import Custom.Widgets 1.0

Item {
    id: customFlyView
    property var parentToolInsets                       // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _totalToolInsets    // The insets updated for the custom overlay additions
    property var mapControl

    readonly property string noGPS:         qsTr("NO GPS")
    readonly property real   indicatorValueWidth:   ScreenTools.defaultFontPixelWidth * 7
    readonly property int actionStopEngine:         25
    readonly property int actionPayloadInit:        26
    readonly property int actionPayloadActivate:    27
    readonly property int actionStartEngine:        28
    readonly property int actionPayloadReset:       29

    property real   _defaultWidgetOpacity:  0.5
    property real   _defaultWidgetRadius:   8

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _indicatorDiameter:     ScreenTools.defaultFontPixelWidth * 18
    property real   _indicatorsHeight:      ScreenTools.defaultFontPixelHeight
    property var    _sepColor:              qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(0,0,0,0.5) : Qt.rgba(1,1,1,0.5)
    property color  _indicatorsColor:       qgcPal.text
    property bool   _isVehicleGps:          _activeVehicle ? _activeVehicle.gps.count.rawValue > 1 && _activeVehicle.gps.hdop.rawValue < 1.4 : false
    property string _altitude:              _activeVehicle ? (isNaN(_activeVehicle.altitudeRelative.value) ? "0.0" : _activeVehicle.altitudeRelative.value.toFixed(1)) + ' ' + _activeVehicle.altitudeRelative.units : "0.0"
    property string _distanceStr:           isNaN(_distance) ? "0" : _distance.toFixed(0) + ' ' + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property real   _distance:              _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property string _messageTitle:          ""
    property string _messageText:           ""
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75

    function secondsToHHMMSS(timeS) {
        var sec_num = parseInt(timeS, 10);
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
        var seconds = sec_num - (hours * 3600) - (minutes * 60);
        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        return hours+':'+minutes+':'+seconds;
    }

    property var    battery1:           _activeVehicle ? _activeVehicle.battery  : null
    property var    battery2:           _activeVehicle ? _activeVehicle.battery2 : null
    property bool   hasSecondBattery:   battery2 && battery2.voltage.value !== -1

    function getName(systemID){
        var vehicleName;
        switch (systemID) {
        case 1:
            vehicleName = "ALPHA"
            break
        case 2:
            vehicleName = "BRAVO"
            break
        case 3:
            vehicleName = "CHARLIE"
            break
        default:
            vehicleName = "UNKNOWN"
            break
        }
        return vehicleName
    }

    property var _actionData

    // Called when an action is about to be executed in order to confirm
    function confirmAction(actionCode, actionData) {
        var showImmediate = true
        //closeAll()
        confirmDialog.action = actionCode
        confirmDialog.actionData = actionData
        confirmDialog.hideTrigger = true
        //confirmDialog.mapIndicator = mapIndicator
        confirmDialog.optionText = ""
        _actionData = actionData
        switch (actionCode) {
        case actionStopEngine:
            confirmDialog.title = "STOP ENGINE"
            confirmDialog.message = "WARNING: THIS WILL STOP THE ENGINE!"
            //confirmDialog.hideTrigger = Qt.binding(function() { return !showEmergenyStop })
            break;
        case actionStartEngine:
            confirmDialog.title = "START ENGINE"
            confirmDialog.message = "INFO: Start the engine?"
            //confirmDialog.hideTrigger = Qt.binding(function() { return !showEmergenyStop })
            break;
        case actionPayloadInit:
            confirmDialog.title = "INIT PAYLOAD"
            confirmDialog.message = "WARNING: THIS WILL INIT THE PAYLOAD!"
            //confirmDialog.hideTrigger = Qt.binding(function() { return !showEmergenyStop })
            break;
        case actionPayloadActivate:
            confirmDialog.title = "ACTIVATE PAYLOAD"
            confirmDialog.message = "WARNING: THIS WILL ACTIVATE THE PAYLOAD!"
            //confirmDialog.hideTrigger = Qt.binding(function() { return !showEmergenyStop })
            break;
        case actionPayloadReset:
            confirmDialog.title = "RESET PAYLOAD"
            confirmDialog.message = "WARNING: THIS WILL RESET THE PAYLOAD!"
            //confirmDialog.hideTrigger = Qt.binding(function() { return !showEmergenyStop })
            break;
        default:
            console.warn("Unknown actionCode", actionCode)
            return
        }
        confirmDialog.show(showImmediate)
    }

    // Executes the specified action
    function executeAction(actionCode, actionData, optionChecked) {
        var i;
        var rgVehicle;
        switch (actionCode) {
        case actionStopEngine:
            // send mavlink command
            // MAV_CMD_DO_SET_SERVO (183)
            // param 1: instance
            // param 2: PWM
            _activeVehicle.sendCommand(0, 183, true, 13, 1900, 0, 0, 0, 0, 0)
            stopMotorTimer.running = true
            console.warn(qsTr("Sent stop engine command"), actionCode)
            break
        case actionStartEngine:
            // send mavlink command
            // MAV_CMD_DO_SET_SERVO (183)
            // param 1: instance
            // param 2: PWM
            _activeVehicle.sendCommand(0, 183, true, 14, 1900, 0, 0, 0, 0, 0)
            startMotorTimer.running = true
            console.warn(qsTr("Sent start engine command"), actionCode)
            break
        case actionPayloadInit:
            // send mavlink command
            // MAV_CMD_DO_SET_SERVO (183)
            // param 1: instance
            // param 2: PWM
            _activeVehicle.sendCommand(0, 183, true, 11, 1900, 0, 0, 0, 0, 0)
            console.warn(qsTr("Sent payload init command"), actionCode)
            break
        case actionPayloadActivate:
            // send mavlink command
            // MAV_CMD_DO_SET_SERVO (183)
            // param 1: instance
            // param 2: PWM
            _activeVehicle.sendCommand(0, 183, true, 12, 1900, 0, 0, 0, 0, 0)
            console.warn(qsTr("Sent payload activate command"), actionCode)
            break
        case actionPayloadReset:
            // send mavlink command
            // MAV_CMD_DO_SET_SERVO (183)
            // param 1: instance
            // param 2: PWM
            _activeVehicle.sendCommand(0, 183, true, 11, 1100, 0, 0, 0, 0, 0)
            _activeVehicle.sendCommand(0, 183, true, 12, 1100, 0, 0, 0, 0, 0)
            console.warn(qsTr("Sent payload reset command"), actionCode)
            break
        default:
            console.warn(qsTr("Internal error: unknown actionCode"), actionCode)
            break
        }
    }

    Timer {
        id:        startMotorTimer
        interval:  3000
        running:   false;
        repeat:    false;
        onTriggered: {
            // send set_servo cmd to servo 14 wil low value (1100)
            _activeVehicle.sendCommand(0, 183, true, 14, 1100, 0, 0, 0, 0, 0)
            startMotorTimer.running = false
        }
    }

    Timer {
        id:        stopMotorTimer
        interval:  3000
        running:   false;
        repeat:    false;
        onTriggered: {
            // send set_servo cmd to servo 13 wil low value (1100)
            _activeVehicle.sendCommand(0, 183, true, 13, 1100, 0, 0, 0, 0, 0)
            startMotorTimer.running = false
        }
    }

    CustomActionConfirm {
        id:                         confirmDialog
        anchors.margins:            _margins
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        customCommandController:    customFlyView
    }

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    exampleRectangle.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parent.width - compassBackground.x
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     compassArrowIndicator.y + compassArrowIndicator.height
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parent.height - attitudeIndicator.y
    }

    // This is an example of how you can use parent tool insets to position an element on the custom fly view layer
    // - we use parent topEdgeLeftInset to position the widget below the toolstrip
    // - we use parent bottomEdgeLeftInset to dodge the virtual joystick if enabled
    // - we use the parent leftEdgeTopInset to size our element to the same width as the ToolStripAction
    // - we export the width of this element as the leftEdgeCenterInset so that the map will recenter if the vehicle flys behind this element
    Rectangle {
        id: exampleRectangle
        visible: false // to see this example, set this to true. To view insets, enable the insets viewer FlyView.qml
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: parentToolInsets.topEdgeLeftInset + _toolsMargin
        anchors.bottomMargin: parentToolInsets.bottomEdgeLeftInset + _toolsMargin
        anchors.leftMargin: _toolsMargin
        width: parentToolInsets.leftEdgeTopInset - _toolsMargin
        color: 'red'

        property real leftEdgeCenterInset: visible ? x + width : 0
    }

    //-------------------------------------------------------------------------
    //-- Heading Indicator
    Rectangle {
        id:                         compassBar
        height:                     ScreenTools.defaultFontPixelHeight * 1.5
        width:                      ScreenTools.defaultFontPixelWidth  * 50
        color:                      "#DEDEDE"
        radius:                     2
        clip:                       true
        anchors.top:                headingIndicator.bottom
        anchors.topMargin:          -headingIndicator.height / 2
        anchors.horizontalCenter:   parent.horizontalCenter
        Repeater {
            model: 720
            QGCLabel {
                function _normalize(degrees) {
                    var a = degrees % 360
                    if (a < 0) a += 360
                    return a
                }
                property int _startAngle: modelData + 180 + _heading
                property int _angle: _normalize(_startAngle)
                anchors.verticalCenter: parent.verticalCenter
                x:              visible ? ((modelData * (compassBar.width / 360)) - (width * 0.5)) : 0
                visible:        _angle % 45 == 0
                color:          "#75505565"
                font.pointSize: ScreenTools.smallFontPointSize
                text: {
                    switch(_angle) {
                    case 0:     return "N"
                    case 45:    return "NE"
                    case 90:    return "E"
                    case 135:   return "SE"
                    case 180:   return "S"
                    case 225:   return "SW"
                    case 270:   return "W"
                    case 315:   return "NW"
                    }
                    return ""
                }
            }
        }
    }
    Rectangle {
        id:                         headingIndicator
        height:                     ScreenTools.defaultFontPixelHeight
        width:                      ScreenTools.defaultFontPixelWidth * 4
        color:                      qgcPal.windowShadeDark
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        anchors.horizontalCenter:   parent.horizontalCenter
        QGCLabel {
            text:                   _heading
            color:                  qgcPal.text
            font.pointSize:         ScreenTools.smallFontPointSize
            anchors.centerIn:       parent
        }
    }
    Image {
        id:                         compassArrowIndicator
        height:                     _indicatorsHeight
        width:                      height
        source:                     "/custom/img/compass_pointer.svg"
        fillMode:                   Image.PreserveAspectFit
        sourceSize.height:          height
        anchors.top:                compassBar.bottom
        anchors.topMargin:          -height / 2
        anchors.horizontalCenter:   parent.horizontalCenter
    }

    Rectangle {
        id:                     compassBackground
        anchors.bottom:         attitudeIndicator.bottom
        anchors.right:          attitudeIndicator.left
        anchors.rightMargin:    -attitudeIndicator.width / 2
        width:                  -anchors.rightMargin + compassBezel.width + (_toolsMargin * 2)
        height:                 attitudeIndicator.height * 0.75
        radius:                 2
        color:                  qgcPal.window

        Rectangle {
            id:                     compassBezel
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     _toolsMargin
            anchors.left:           parent.left
            width:                  height
            height:                 parent.height - (northLabelBackground.height / 2) - (headingLabelBackground.height / 2)
            radius:                 height / 2
            border.color:           qgcPal.text
            border.width:           1
            color:                  Qt.rgba(0,0,0,0)
        }

        Rectangle {
            id:                         northLabelBackground
            anchors.top:                compassBezel.top
            anchors.topMargin:          -height / 2
            anchors.horizontalCenter:   compassBezel.horizontalCenter
            width:                      northLabel.contentWidth * 1.5
            height:                     northLabel.contentHeight * 1.5
            radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
            color:                      qgcPal.windowShade

            QGCLabel {
                id:                 northLabel
                anchors.centerIn:   parent
                text:               "N"
                color:              qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }

        Image {
            id:                 headingNeedle
            anchors.centerIn:   compassBezel
            height:             compassBezel.height * 0.75
            width:              height
            source:             "/custom/img/compass_needle.svg"
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height
            transform: [
                Rotation {
                    origin.x:   headingNeedle.width  / 2
                    origin.y:   headingNeedle.height / 2
                    angle:      _heading
                }]
        }

        Rectangle {
            id:                         headingLabelBackground
            anchors.top:                compassBezel.bottom
            anchors.topMargin:          -height / 2
            anchors.horizontalCenter:   compassBezel.horizontalCenter
            width:                      headingLabel.contentWidth * 1.5
            height:                     headingLabel.contentHeight * 1.5
            radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
            color:                      qgcPal.windowShade

            QGCLabel {
                id:                 headingLabel
                anchors.centerIn:   parent
                text:               _heading
                color:              qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }

    Rectangle {
        id:                     attitudeIndicator
        anchors.bottomMargin:   _toolsMargin + parentToolInsets.bottomEdgeRightInset
        anchors.rightMargin:    _toolsMargin
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        height:                 ScreenTools.defaultFontPixelHeight * 6
        width:                  height
        radius:                 height * 0.5
        color:                  qgcPal.windowShade

        CustomAttitudeWidget {
            size:               parent.height * 0.95
            vehicle:            _activeVehicle
            showHeading:        false
            anchors.centerIn:   parent
        }
    }

    Rectangle {
        id:                     vehicleIndicator
        color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,_defaultWidgetOpacity)//0.3
        width:                  vehicleStatusGrid.width  + (ScreenTools.defaultFontPixelWidth  * 10)//5
        height:                 vehicleStatusGrid.height + (ScreenTools.defaultFontPixelHeight * 1.5)//2.5
        radius:                 8

        anchors.top:    battTimeLoader.top
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * (_airspaceIndicatorVisible  ? 3 : 1.3)//
        anchors.horizontalCenter: parent.horizontalCenter
        //anchors.right:  parent.right
        //anchors.rightMargin:   400//ScreenTools.defaultFontPixeWidth *2

        readonly property bool  _showGps: CustomQuickInterface.showAttitudeWidget

        //  Layout
        RowLayout {
            id:                     vehicleStatusGrid
            //columnSpacing:          ScreenTools.defaultFontPixelWidth  * 2
            //rowSpacing:             ScreenTools.defaultFontPixelHeight * 0.5
            //columns:                8
            //rows:                   2
            anchors.centerIn:       parent
            Layout.fillWidth:     true //false

            ColumnLayout { // USV name
                QGCLabel {
                    text:                   _activeVehicle ? getName(_activeVehicle.id) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    //Layout.fillWidth:       true
                    Layout.minimumWidth:    10
                    //Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                    rotation: 270
                }
            }

            ColumnLayout {
                QGCHoverButton {
                    id:             buttonStartMotor

                    //anchors.left:   toolStripColumn.left
                    //anchors.right:  toolStripColumn.right
                    //height:         _indicatorsHeight
                    //width:          height
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumHeight: _indicatorsHeight
                    Layout.minimumWidth: height
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.smallFontPointSize
                    autoExclusive:  true

                    enabled:        _activeVehicle ? true : false //modelData.buttonEnabled
                    visible:        true //modelData.buttonVisible
                    imageSource:    "/res/PowerButton"
                    text:           "START"
                    checked:        false //modelData.checked !== undefined ? modelData.checked : checked
                    borderColor:    "green"
                    borderWidth:    4
                    hoverColor:     "green"
                    // border.color:   "red"
                    // border.width:   4

                    //ButtonGroup.group: buttonGroup
                    // Only drop panel and toggleable are checkable
                    //checkable: modelData.dropPanelComponent !== undefined || (modelData.toggle !== undefined && modelData.toggle)

                    onPressed: {
                        console.warn("btn pressed, action: ", actionStartEngine)
                        confirmAction(actionStartEngine)
                        //executeAction(actionStopEngine)
                    }
                }
            }

            ColumnLayout {
                QGCHoverButton {
                    id:             buttonStopMotor

                    //anchors.left:   toolStripColumn.left
                    //anchors.right:  toolStripColumn.right
                    //height:         _indicatorsHeight
                    //width:          height
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumHeight: _indicatorsHeight
                    Layout.minimumWidth: height
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.smallFontPointSize
                    autoExclusive:  true

                    enabled:        _activeVehicle ? true : false //modelData.buttonEnabled
                    visible:        true //modelData.buttonVisible
                    imageSource:    "/res/XDelete.svg"
                    text:           "STOP ENGINE"
                    checked:        false //modelData.checked !== undefined ? modelData.checked : checked
                    borderColor:    "red"
                    borderWidth:    4
                    hoverColor:     "red"
                    // border.color:   "red"
                    // border.width:   4

                    //ButtonGroup.group: buttonGroup
                    // Only drop panel and toggleable are checkable
                    //checkable: modelData.dropPanelComponent !== undefined || (modelData.toggle !== undefined && modelData.toggle)

                    onPressed: {
                        console.warn("btn pressed, action: ", actionStopEngine)
                        confirmAction(actionStopEngine)
                        //executeAction(actionStopEngine)
                    }
                }
            }



            ColumnLayout { // RC Channel 3

                property int rcValue: 1500
                readonly property int _pwmMin:      800
                readonly property int _pwmMax:      2200
                readonly property int _pwmRange:    _pwmMax - _pwmMin
                property int ch3Value: 1500

                RCChannelMonitorController {
                    id:             controller
                }


                // Live channel monitor control component
                Component {
                    id: channelMonitorDisplayComponent

                    Item {
                        height: ScreenTools.defaultFontPixelHeight

                        property int    rcValue:    1500

                        property int            __lastRcValue:      1500
                        readonly property int   __rcValueMaxJitter: 2
                        property color          __barColor:         qgcPal.windowShade

                        // Bar
                        Rectangle {
                            id:                     bar
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  parent.width
                            height:                 parent.height / 2
                            color:                  __barColor
                        }

                        // Center point
                        Rectangle {
                            anchors.horizontalCenter:   parent.horizontalCenter
                            width:                      ScreenTools.defaultFontPixelWidth / 2
                            height:                     parent.height
                            color:                      qgcPal.window
                        }

                        // Indicator
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  parent.height * 0.75
                            height:                 width
                            x:                      (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * parent.width) - (width / 2)
                            radius:                 width / 2
                            color:                  qgcPal.text
                            visible:                mapped
                        }

                        QGCLabel {
                            anchors.fill:           parent
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            text:                   "Not Mapped"
                            visible:                !mapped
                        }

                        ColorAnimation {
                            id:         barAnimation
                            target:     bar
                            property:   "color"
                            from:       "yellow"
                            to:         __barColor
                            duration:   1500
                        }
                    }
                } // Component - channelMonitorDisplayComponent

                Connections {
                    target: controller

                    onChannelRCValueChanged: {
                        if (channelMonitorRepeater.itemAt(channel)) {
                            channelMonitorRepeater.itemAt(channel).loader.item.rcValue = rcValue
                        }
                    }
                }

                Repeater {
                    id:     channelMonitorRepeater
                    model:  controller.channelCount

                    RowLayout {
                        // Need this to get to loader from Connections above
                        property Item loader: theLoader

                        Loader {
                            id:                 theLoader
                            Layout.fillWidth:   true
                            //height:                 ScreenTools.defaultFontPixelHeight
                            //width:                  parent.width - anchors.leftMargin - ScreenTools.defaultFontPixelWidth
                            sourceComponent:        channelMonitorDisplayComponent

                            property bool mapped:               true
                            readonly property bool reversed:    false
                        }
                    }
                }

                QGCLabel {
                    text:                   "CH3"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? (channelMonitorRepeater.itemAt(3).loader.item.rcValue + "%") : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                    //verticalAlignment:      Text.AlignVCenter
                }
            }

            ColumnLayout { // gear

                QGCLabel {
                    text:                   "GEAR"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? getGear(_activeVehicle.engine.gear.value) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         30
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter

                    function getGear(gear){
                        var vehicleName;
                        switch (gear) {
                        case 81:
                            vehicleName = "N"
                            break
                        case 53:
                            vehicleName = "F"
                            break
                        case 205:
                            vehicleName = "R"
                            break
                        default:
                            vehicleName = "-"
                            break
                        }
                        return vehicleName
                    }
                }
            }

            ColumnLayout { // throttle
                QGCLabel {
                    text:                   "THROTTLE"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                ColumnLayout {

                    Layout.minimumHeight:    indicatorValueWidth

                    QGCLabel {
                        text:                   _activeVehicle ? _activeVehicle.engine.throttle_pos.value.toFixed(0) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    indicatorValueWidth
                        horizontalAlignment:    Text.AlignHCenter
                    }
                    QGCLabel {
                        text:                   _activeVehicle ? getThrottleControler(_activeVehicle.engine.steer_thr_state.value) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.smallFontPointSize
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    indicatorValueWidth
                        horizontalAlignment:    Text.AlignHCenter

                        function getThrottleControler(steer_thr_state){
                            var controllerName;
                            switch (steer_thr_state) {
                            case 1:
                            case 2:
                                controllerName = "MANUAL"
                                break
                            case 3:
                            case 4:
                                controllerName = "AUTO"
                                break
                            default:
                                controllerName = "-"
                                break
                            }
                            return controllerName
                        }
                    }
                }
            }

            ColumnLayout { // rudder
                QGCLabel {
                    text:                   "RUDDER"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                ColumnLayout {
                    Layout.minimumHeight:    indicatorValueWidth

                    QGCLabel {
                        text:                   _activeVehicle ? _activeVehicle.engine.rudder_angle.value.toFixed(1) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    indicatorValueWidth
                        horizontalAlignment:    Text.AlignHCenter
                    }
                    QGCLabel {
                        text:                   _activeVehicle ? getSteeringControler(_activeVehicle.engine.steer_thr_state.value) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.smallFontPointSize
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    indicatorValueWidth
                        horizontalAlignment:    Text.AlignHCenter


                        function getSteeringControler(steer_thr_state){
                            var controllerName;
                            switch (steer_thr_state) {
                            case 1:
                            case 3:
                                controllerName = "MANUAL"
                                break
                            case 2:
                            case 4:
                                controllerName = "AUTO"
                                break
                            default:
                                controllerName = "-"
                                break
                            }
                            return controllerName
                        }
                    }
                }
            }



            ColumnLayout { // RPM
                QGCLabel {
                    text:                   "RPM"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.efi.rpm.value : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                    //verticalAlignment:      Text.AlignVCenter
                }
            }

            ColumnLayout {
                QGCLabel {
                    text:                   "SPEED"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                // QGCColoredImage {
                //     height:                 _indicatorsHeight
                //     width:                  height
                //     source:                 "/custom/img/horizontal_speed.svg"
                //     fillMode:               Image.PreserveAspectFit
                //     sourceSize.height:      height
                //     Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                //     color:                  qgcPal.text
                // }
                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.groundSpeed.value.toFixed(1) + ' ' + _activeVehicle.groundSpeed.units : "0.0"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
            }


            ColumnLayout {
                QGCLabel {
                    text:                   "FUEL"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }

                // Gear
                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.efi.fuelFlow.value.toFixed(1) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
            }


            ColumnLayout { // battery
                QGCLabel {
                    text:                   "BATTERY"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text: (battery1 && battery1.voltage.value !== -1) ? (battery1.voltage.valueString + " " + battery1.voltage.units) : "N/A"
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                }
            }
            // Item { // spacer
            //      Layout.fillWidth:       true
            // }

            // Item{
            //     //id: attitudeCircle
            //     //Layout.rowSpan:         3
            //     //Layout.column:          8
            //     Layout.minimumWidth:    indicatorValueWidth*1.2
            //     Layout.fillHeight:      true
            //     Layout.fillWidth:       true
            //     //anchors.top:            compassCircle.bottom
            //     //anchors.topMargin:      ScreenTools.defaultFontPixelHeight * (_airspaceIndicatorVisible  ? 3 : 1.3)//
            //     //anchors.left:           compassCircle.left
            //     //anchors.leftMargin:      ScreenTools.defaultFontPixelWidth* 50

            //     Rectangle {
            //         color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,0)
            //         width:                  parent.width //attitudeIndicator.width * 1 //0.5
            //         height:                 parent.height
            //         visible:                true //CustomQuickInterface.showAttitudeWidget
            //         anchors.fill:   parent

            //     }
            //     Rectangle {
            //         id:                     attitudeIndicatorStrip
            //         anchors.fill:   parent
            //         height:                 indicatorValueWidth
            //         width:                  indicatorValueWidth
            //         radius:                 height * 0.5
            //         //color:                   parent.color
            //         visible:                true //CustomQuickInterface.showAttitudeWidget
            //         CustomAttitudeWidget {
            //             size:               parent.height * 0.95
            //             vehicle:            _activeVehicle
            //             showHeading:        false
            //             anchors.centerIn:   parent
            //         }
            //     }
            // }
        }

        // MouseArea {
        //     anchors.fill:       parent
        //     onDoubleClicked:    CustomQuickInterface.showAttitudeWidget = !CustomQuickInterface.showAttitudeWidget
        // }
    }

    Rectangle {
        id:                     payloadControl
        color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,_defaultWidgetOpacity)//0.3
        width:                  testStatusGrid.width  + (ScreenTools.defaultFontPixelWidth  * 18)//5
        height:                 testStatusGrid.height + (ScreenTools.defaultFontPixelHeight * 1.5)//1.5
        radius:                 _defaultWidgetRadius
        x:                      Math.round((mainWindow.width  - width)  * 0.5)//0.5
        y:                      Math.round((mainWindow.height - height) * 0.8)//0.5
        //anchors.top:            battTimeLoader.top
        //anchors.topMargin:      ScreenTools.defaultFontPixelHeight * (_airspaceIndicatorVisible  ? 3 : 1.3)//
        //anchors.left:           vehicleIndicator.left
        //anchors.leftMargin:     ScreenTools.defaultFontPixelWidth  * 80
        //  Layout
        RowLayout {
            id:                     payloadLayout2
            // columnSpacing:          ScreenTools.defaultFontPixelWidth  * 2
            // rowSpacing:             ScreenTools.defaultFontPixelHeight * 0.5
            // columns:                10
            anchors.centerIn:       parent
            Layout.fillWidth:       false


            ColumnLayout { // boat underway
                Layout.fillWidth:       true
                Layout.minimumWidth:    indicatorValueWidth
                Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

                // QGCColoredImage {
                //     height:                 _indicatorsHeight
                //     width:                  height
                //     source:                 "/res/cancel.svg" //"/qmlimages/Armed.svg"
                //     fillMode:               Image.PreserveAspectFit
                //     sourceSize.height:      height
                //     Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                //     //color:                  qgcPal.text
                // }
                QGCLabel {
                    text:                   _activeVehicle ? getPayloadStatus(_activeVehicle.engine.underway_threshold.value) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter

                    function getPayloadStatus(payload_info){
                        var payloadStatus;
                        switch (payload_info) {
                        case 1:
                            payloadStatus = "READY"
                            break
                        default:
                            payloadStatus = "NOT READY"
                            break
                        }
                        return payloadStatus
                    }
                }
                QGCLabel {
                    text:                   "STATUS"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.fillWidth:       true
                    Layout.minimumWidth:    indicatorValueWidth
                    horizontalAlignment:    Text.AlignHCenter
                    //wrapMode:               wrap
                }
                // QGCLabel {
                //     //id:                     latLabel
                //     text:                   "YES" // activeVehicle ? "Lat: " + activeVehicle.gps.lat.value.toFixed(activeVehicle.gps.lat.decimalPlaces) : "Lat: -"
                //     color:                  _indicatorsColor
                //     font.pointSize:         ScreenTools.mediumFontPointSize
                //     Layout.fillWidth:       true
                //     Layout.minimumWidth:    indicatorValueWidth
                //     horizontalAlignment:    Text.AlignHCenter
                //     //visible:                false
                // }
            }
            QGCHoverButton { // init payload
                id:             buttonInitPayload

                //anchors.left:   toolStripColumn.left
                //anchors.right:  toolStripColumn.right
                // height:         _indicatorsHeight
                // width:          height
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.minimumHeight: _indicatorsHeight * 2
                Layout.minimumWidth: height
                radius:         ScreenTools.defaultFontPixelWidth / 2
                fontPointSize:  ScreenTools.smallFontPointSize
                autoExclusive:  true

                enabled:        true //modelData.buttonEnabled
                visible:        true //modelData.buttonVisible
                imageSource:    "/custom/img/payload_init.svg"
                text:           "INIT"
                checked:        false //modelData.checked !== undefined ? modelData.checked : checked

                //ButtonGroup.group: buttonGroup
                // Only drop panel and toggleable are checkable
                //checkable: modelData.dropPanelComponent !== undefined || (modelData.toggle !== undefined && modelData.toggle)

                onClicked: {
                    console.warn("btn pressed, action: ", actionPayloadInit)
                    confirmAction(actionPayloadInit)
                    //executeAction(actionPayloadInit)
                }
            }
            QGCHoverButton {
                id:             buttonActivatePayload

                //anchors.left:   toolStripColumn.left
                //anchors.right:  toolStripColumn.right
                // height:         _indicatorsHeight
                // width:          height
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.minimumHeight: _indicatorsHeight *2
                Layout.minimumWidth: height
                radius:         ScreenTools.defaultFontPixelWidth / 2
                fontPointSize:  ScreenTools.smallFontPointSize
                autoExclusive:  true

                enabled:        true //modelData.buttonEnabled
                visible:        true //modelData.buttonVisible
                imageSource:    "/custom/img/payload_activate.svg"
                text:           "ACTIVATE"
                checked:        false //modelData.checked !== undefined ? modelData.checked : checked

                //ButtonGroup.group: buttonGroup
                // Only drop panel and toggleable are checkable
                //checkable: modelData.dropPanelComponent !== undefined || (modelData.toggle !== undefined && modelData.toggle)

                onClicked: {
                    console.warn("btn pressed, action: ", actionPayloadActivate)
                    confirmAction(actionPayloadActivate)
                    //executeAction(actionPayloadActivate)
                }
            }
            QGCHoverButton {
                id:             buttonResetPayload

                //anchors.left:   toolStripColumn.left
                //anchors.right:  toolStripColumn.right
                //height:         _indicatorsHeight
                //width:          height
                // Layout.fillHeight: true
                // Layout.fillWidth: true
                Layout.minimumHeight: _indicatorsHeight
                Layout.minimumWidth: _indicatorsHeight
                radius:         ScreenTools.defaultFontPixelWidth / 2
                fontPointSize:  ScreenTools.smallFontPointSize
                autoExclusive:  true

                enabled:        true //modelData.buttonEnabled
                visible:        true //modelData.buttonVisible
                imageSource:    "/res/XDelete.svg"
                text:           "RESET"
                checked:        false //modelData.checked !== undefined ? modelData.checked : checked

                //ButtonGroup.group: buttonGroup
                // Only drop panel and toggleable are checkable
                //checkable: modelData.dropPanelComponent !== undefined || (modelData.toggle !== undefined && modelData.toggle)

                onClicked: {
                    console.warn("btn pressed, action: ", actionPayloadReset)
                    //confirmAction(actionPayloadReset)
                    executeAction(actionPayloadReset)
                }
            }
        }
    }

    
}
