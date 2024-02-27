/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import Custom.Widgets               1.0

// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl

    readonly property real   indicatorValueWidth:   ScreenTools.defaultFontPixelWidth * 7
    readonly property int actionStopEngine:         25
    readonly property int actionPayloadInit:        26
    readonly property int actionPayloadActivate:    27
    readonly property int actionStartEngine:        28
    readonly property int actionPayloadReset:       29

    property real   _indicatorsHeight:      ScreenTools.defaultFontPixelHeight
    property color  _indicatorsColor:       qgcPal.text
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 40
    property alias  _gripperMenu:           gripperOptions

    property var    battery1:           _activeVehicle ? _activeVehicle.battery  : null

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
        customConfirmDialog.action = actionCode
        customConfirmDialog.actionData = actionData
        customConfirmDialog.hideTrigger = true
        customConfirmDialog.optionText = ""
        _actionData = actionData
        switch (actionCode) {
        case actionStopEngine:
            customConfirmDialog.title = "STOP ENGINE"
            customConfirmDialog.message = "WARNING: THIS WILL STOP THE ENGINE!"
            break;
        case actionStartEngine:
            customConfirmDialog.title = "START ENGINE"
            customConfirmDialog.message = "INFO: Start the engine?"
            break;
        case actionPayloadInit:
            customConfirmDialog.title = "INIT PAYLOAD"
            customConfirmDialog.message = "WARNING: THIS WILL INIT THE PAYLOAD!"
            break;
        case actionPayloadActivate:
            customConfirmDialog.title = "ACTIVATE PAYLOAD"
            customConfirmDialog.message = "WARNING: THIS WILL ACTIVATE THE PAYLOAD!"
            break;
        case actionPayloadReset:
            customConfirmDialog.title = "RESET PAYLOAD"
            customConfirmDialog.message = "WARNING: THIS WILL RESET THE PAYLOAD!"
            break;
        default:
            console.warn("Unknown actionCode", actionCode)
            return
        }
        customConfirmDialog.show(showImmediate)
    }

    // Executes the specified action
    function executeAction(actionCode, actionData, optionChecked) {
        var i;
        var rgVehicle;
        switch (actionCode) {
        case actionStopEngine:
            _activeVehicle.sendCommand(1, 183, false, 13, 1900, 0, 0, 0, 0, 0)
            stopMotorTimer.running = true
            console.warn(qsTr("Sent stop engine command"), actionCode)
            break
        case actionStartEngine:
            _activeVehicle.sendCommand(1, 183, false, 14, 1900, 0, 0, 0, 0, 0)
            startMotorTimer.running = true
            console.warn(qsTr("Sent start engine command"), actionCode)
            break
        case actionPayloadInit:
            _activeVehicle.sendCommand(1, 183, false, 11, 1900, 0, 0, 0, 0, 0)
            console.warn(qsTr("Sent payload init command"), actionCode)
            break
        case actionPayloadActivate:
            _activeVehicle.sendCommand(1, 183, false, 12, 1900, 0, 0, 0, 0, 0)
            console.warn(qsTr("Sent payload activate command"), actionCode)
            break
        case actionPayloadReset:
            _activeVehicle.sendCommand(1, 183, false, 12, 1100, 0, 0, 0, 0, 0)
            resetPayloadTimer.running = true
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
            _activeVehicle.sendCommand(1, 183, false, 14, 1100, 0, 0, 0, 0, 0)
            startMotorTimer.running = false
        }
    }

    Timer {
        id:        stopMotorTimer
        interval:  3000
        running:   false;
        repeat:    false;
        onTriggered: {
            _activeVehicle.sendCommand(1, 183, false, 13, 1100, 0, 0, 0, 0, 0)
            startMotorTimer.running = false
        }
    }

    Timer {
        id:        resetPayloadTimer
        interval:  3000
        running:   false;
        repeat:    false;
        onTriggered: {
            _activeVehicle.sendCommand(1, 183, false, 11, 1100, 0, 0, 0, 0, 0)
            resetPayloadTimer.running = false
        }
    }

    CustomActionConfirm {
        id:                         customConfirmDialog
        anchors.margins:            _margins
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        customCommandController:    _root
    }

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      instrumentPanel.rightEdgeTopInset
        rightEdgeCenterInset:   (telemetryPanel.rightEdgeCenterInset > photoVideoControl.rightEdgeCenterInset) ? telemetryPanel.rightEdgeCenterInset : photoVideoControl.rightEdgeCenterInset
        rightEdgeBottomInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.rightEdgeBottomInset : parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      instrumentPanel.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  telemetryPanel.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : parentToolInsets.bottomEdgeRightInset
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    Row {
        id:                 multiVehiclePanelSelector
        anchors.margins:    _toolsMargin
        anchors.top:        parent.top
        anchors.right:      parent.right
        width:              _rightPanelWidth
        spacing:            ScreenTools.defaultFontPixelWidth
        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList

        property bool showSingleVehiclePanel:  !visible || singleVehicleRadio.checked

        QGCMapPalette { id: mapPal; lightColors: true }

        QGCRadioButton {
            id:             singleVehicleRadio
            text:           qsTr("Single")
            checked:        true
            textColor:      mapPal.text
        }

        QGCRadioButton {
            text:           qsTr("Multi-Vehicle")
            textColor:      mapPal.text
        }
    }

    MultiVehicleList {
        anchors.margins:    _toolsMargin
        anchors.top:        multiVehiclePanelSelector.bottom
        anchors.right:      parent.right
        width:              _rightPanelWidth
        height:             parent.height - y - _toolsMargin
        visible:            !multiVehiclePanelSelector.showSingleVehiclePanel
    }


    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
    }

    FlyViewInstrumentPanel {
        id:                         instrumentPanel
        anchors.margins:            _toolsMargin
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 1.3
        anchors.top:                multiVehiclePanelSelector.visible ? multiVehiclePanelSelector.bottom : parent.top
        anchors.right:              parent.right
        width:                      _rightPanelWidth
        spacing:                    _toolsMargin
        visible:                    QGroundControl.corePlugin.options.flyView.showInstrumentPanel && multiVehiclePanelSelector.showSingleVehiclePanel
        availableHeight:            parent.height - y - _toolsMargin

        property real rightEdgeTopInset: visible ? parent.width - x : 0
        property real topEdgeRightInset: visible ? y + height : 0
    }

    PhotoVideoControl {
        id:                     photoVideoControl
        anchors.margins:        _toolsMargin
        anchors.right:          parent.right
        width:                  _rightPanelWidth

        property real rightEdgeCenterInset: visible ? parent.width - x : 0

        state:                  _verticalCenter ? "verticalCenter" : "topAnchor"
        states: [
            State {
                name: "verticalCenter"
                AnchorChanges {
                    target:                 photoVideoControl
                    anchors.top:            undefined
                    anchors.verticalCenter: _root.verticalCenter
                }
            },
            State {
                name: "topAnchor"
                AnchorChanges {
                    target:                 photoVideoControl
                    anchors.verticalCenter: undefined
                    anchors.top:            instrumentPanel.bottom
                }
            }
        ]

        property bool _verticalCenter: !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue
    }

    Row {
        id:                 videoTypePanelSelector
        anchors.bottom:     photoVideoControl.bottom
        anchors.right:      parent.right
        width:              _rightPanelWidth
        spacing:            ScreenTools.defaultFontPixelWidth

        QGCRadioButton {
            id:             rgbVideo
            text:           qsTr("RGB")
            checked:        true
            textColor:      mapPal.text
            onClicked:      QGroundControl.multiVehicleManager.changeActiveVideoStream(false)
        }

        QGCRadioButton {
            text:           qsTr("Thermal")
            textColor:      mapPal.text
            onClicked:      QGroundControl.multiVehicleManager.changeActiveVideoStream(true)
        }
    }

    TelemetryValuesBar {
        id:                 telemetryPanel
        x:                  recalcXPosition()
        anchors.margins:    _toolsMargin

        property real bottomEdgeCenterInset: 0
        property real rightEdgeCenterInset: 0

        // States for custom layout support
        states: [
            State {
                name: "bottom"
                when: telemetryPanel.bottomMode

                AnchorChanges {
                    target: telemetryPanel
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                    anchors.right: undefined
                    anchors.verticalCenter: undefined
                }

                PropertyChanges {
                    target: telemetryPanel
                    x: recalcXPosition()
                    bottomEdgeCenterInset: visible ? parent.height-y : 0
                    rightEdgeCenterInset: 0
                }
            },

            State {
                name: "right-video"
                when: !telemetryPanel.bottomMode && photoVideoControl.visible

                AnchorChanges {
                    target: telemetryPanel
                    anchors.top: photoVideoControl.bottom
                    anchors.bottom: undefined
                    anchors.right: parent.right
                    anchors.verticalCenter: undefined
                }
                PropertyChanges {
                    target: telemetryPanel
                    bottomEdgeCenterInset: 0
                    rightEdgeCenterInset: visible ? parent.width - x : 0
                }
            },

            State {
                name: "right-novideo"
                when: !telemetryPanel.bottomMode && !photoVideoControl.visible

                AnchorChanges {
                    target: telemetryPanel
                    anchors.top: undefined
                    anchors.bottom: undefined
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
                PropertyChanges {
                    target: telemetryPanel
                    bottomEdgeCenterInset: 0
                    rightEdgeCenterInset: visible ? parent.width - x : 0
                }
            }
        ]

        function recalcXPosition() {
            // First try centered
            var halfRootWidth   = _root.width / 2
            var halfPanelWidth  = telemetryPanel.width / 2
            var leftX           = (halfRootWidth - halfPanelWidth) - _toolsMargin
            var rightX          = (halfRootWidth + halfPanelWidth) + _toolsMargin
            if (leftX >= parentToolInsets.leftEdgeBottomInset || rightX <= parentToolInsets.rightEdgeBottomInset ) {
                // It will fit in the horizontalCenter
                return halfRootWidth - halfPanelWidth
            } else {
                // Anchor to left edge
                return parentToolInsets.leftEdgeBottomInset + _toolsMargin
            }
        }
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        width:                      parent.width  - (_pipOverlay.width / 2)
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       parentToolInsets.leftEdgeBottomInset + ScreenTools.defaultFontPixelHeight * 2
        anchors.horizontalCenter:   parent.horizontalCenter
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property bool autoCenterThrottle: QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue

        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue

        property real bottomEdgeLeftInset: parent.height-y
        property real bottomEdgeRightInset: parent.height-y

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset: visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: preFlightChecklistPopup.createObject(mainWindow).open()


        property real topEdgeLeftInset: visible ? y + height : 0
        property real leftEdgeTopInset: visible ? x + width : 0
    }

    GripperMenu {
        id: gripperOptions
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       toolStrip.right
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      false
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }

    Rectangle {
        id:                     vehicleIndicator
        color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,0.5)//0.3
        width:                  vehicleStatusGrid.width  + (ScreenTools.defaultFontPixelWidth  * 10)//5
        height:                 vehicleStatusGrid.height + (ScreenTools.defaultFontPixelHeight * 1.5)//2.5
        radius:                 8

        anchors.top:    parent.top
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 1.3
        anchors.horizontalCenter: parent.horizontalCenter

        //  Layout
        RowLayout {
            id:                     vehicleStatusGrid
            anchors.centerIn:       parent

            ColumnLayout { // USV name

                QGCLabel {
                    text:                   _activeVehicle ? getName(_activeVehicle.id) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillHeight: true
                    Layout.minimumWidth:    10
                    Layout.minimumHeight:    10
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                    rotation: 270
                }
                
            }

            ColumnLayout {
                Layout.fillHeight: true
                CustomHoverButton {
                    id:             buttonStartMotor
                    Layout.fillHeight: false
                    Layout.fillWidth: false
                    Layout.minimumHeight: _indicatorsHeight * 3
                    Layout.minimumWidth: indicatorValueWidth * 2
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.mediumFontPointSize
                    autoExclusive:  true

                    enabled:        _activeVehicle ? true : false
                    visible:        true
                    imageSource:    "/res/PowerButton"
                    text:           "START"
                    checked:        false
                    borderColor:    "green"
                    borderWidth:    4
                    hoverColor:     "green"

                    onPressed: {
                        console.warn("btn pressed, action: ", actionStartEngine)
                        confirmAction(actionStartEngine)
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                CustomHoverButton {
                    id:             buttonStopMotor
                    Layout.fillHeight: false
                    Layout.fillWidth: false
                    Layout.minimumHeight: _indicatorsHeight * 3
                    Layout.minimumWidth: indicatorValueWidth * 2
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.mediumFontPointSize
                    autoExclusive:  true

                    enabled:        _activeVehicle ? true : false
                    visible:        true
                    imageSource:    "/res/XDelete.svg"
                    text:           "STOP ENGINE"
                    checked:        false
                    borderColor:    "red"
                    borderWidth:    4
                    hoverColor:     "red"

                    onPressed: {
                        console.warn("btn pressed, action: ", actionStopEngine)
                        confirmAction(actionStopEngine)
                    }
                }
            }

            ColumnLayout { // throttle
                id: vehicleIndicatorThrottle
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "THROTTLE"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth * 2
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.minimumHeight:    _indicatorsHeight * 2
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

                    QGCLabel {
                        text:                   _activeVehicle ? _activeVehicle.engine.throttle_pos.value.toFixed(0) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       false
                        Layout.minimumWidth:    indicatorValueWidth
                        Layout.minimumHeight:    _indicatorsHeight
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                        horizontalAlignment:    Text.AlignHCenter
                    }
                    QGCLabel {
                        text:                   _activeVehicle ? getThrottleControler(_activeVehicle.engine.steer_thr_state.value) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       false
                        Layout.minimumWidth:    indicatorValueWidth
                        Layout.minimumHeight:    _indicatorsHeight
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
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
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "RUDDER"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
                ColumnLayout {
                    Layout.minimumHeight:     _indicatorsHeight*2
                    Layout.alignment:         Qt.AlignVCenter | Qt.AlignHCenter
                    Layout.fillHeight: true

                    QGCLabel {
                        text:                   _activeVehicle ? _activeVehicle.engine.rudder_angle.value.toFixed(1) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       false
                        Layout.minimumWidth:    indicatorValueWidth
                        Layout.minimumHeight:    _indicatorsHeight
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                        horizontalAlignment:    Text.AlignHCenter
                    }
                    QGCLabel {
                        text:                   _activeVehicle ? getSteeringControler(_activeVehicle.engine.steer_thr_state.value) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       false
                        Layout.minimumWidth:    indicatorValueWidth
                        Layout.minimumHeight:    _indicatorsHeight
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
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

             ColumnLayout { // RC Channel 3
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "CH3"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.engine.chan3.valueString + "%" : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
            }

            ColumnLayout { // gear
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "GEAR"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? getGear(_activeVehicle.engine.gear.value) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
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

            ColumnLayout { // RPM
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "RPM"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.efi.rpm.value : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "SPEED"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.groundSpeed.value.toFixed(1) + ' ' + _activeVehicle.groundSpeed.units : "0.0"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
            }


            ColumnLayout { // Fuel
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "FUEL"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }

                QGCLabel {
                    text:                   _activeVehicle ? _activeVehicle.efi.fuelFlow.value.toFixed(1) : "-"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
            }

            ColumnLayout { // battery
                Layout.fillHeight: true
                Layout.minimumHeight:    _indicatorsHeight * 3
                QGCLabel {
                    text:                   "BATTERY"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }

                QGCLabel {
                    text: (battery1 && battery1.voltage.value !== -1) ? (battery1.voltage.valueString + " " + battery1.voltage.units) : "N/A"
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.largeFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }
            }
        }
    }

    Rectangle {
        id:                     payloadControl
        color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,0.5)//0.3
        width:                  payloadLayout2.width  + (ScreenTools.defaultFontPixelWidth  * 10)//5
        height:                 buttonInitPayload.height + payloadControlLabel.height + (ScreenTools.defaultFontPixelHeight * 1.5)//1.5
        radius:                 8
        x:                      Math.round((mainWindow.width  - width)  * 0.5)//0.5
        y:                      Math.round((mainWindow.height - height) * 0.8)//0.5

        ColumnLayout {
            id:                     payloadControlColumnLayout
            Layout.fillWidth:       true
            anchors.centerIn:       parent
            anchors.margins:            _toolsMargin

            QGCLabel {
                id:                     payloadControlLabel
                text:                   "PAYLOAD CONTROL"
                color:                  _indicatorsColor
                font.pointSize:         ScreenTools.largeFontPointSize
                Layout.fillWidth:       true
                Layout.minimumWidth:    indicatorValueWidth * 1.5
                Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                horizontalAlignment:    Text.AlignHCenter
                padding:                ScreenTools.defaultFontPixelWidth
            }
        
            RowLayout {
                id:                     payloadLayout2
                Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                height:                 buttonInitPayload.height + ScreenTools.defaultFontPixelHeight

                ColumnLayout { // boat underway
                    Layout.fillWidth: false
                    Layout.minimumHeight: buttonInitPayload.height
                    Layout.minimumWidth: indicatorValueWidth * 1.5
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

                    QGCLabel {
                        text:                   _activeVehicle ? getPayloadStatus(_activeVehicle.engine.underway_threshold.value) : "-"
                        color:                  _indicatorsColor
                        font.pointSize:         ScreenTools.largeFontPointSize
                        Layout.fillWidth:       false
                        Layout.minimumWidth:    indicatorValueWidth
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                        horizontalAlignment:    Text.AlignHCenter
                        verticalAlignment:      Text.AlignVCenter

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
                        font.pointSize:         ScreenTools.mediumFontPointSize
                        Layout.fillWidth:       false
                        Layout.minimumWidth:    indicatorValueWidth * 1.5
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                        horizontalAlignment:    Text.AlignHCenter
                    }
                }
                CustomHoverButton { // init payload
                    id:             buttonInitPayload
                    Layout.fillWidth: false
                    Layout.minimumHeight: _indicatorsHeight * 3
                    Layout.minimumWidth: indicatorValueWidth * 1.5
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.mediumFontPointSize
                    autoExclusive:  true

                    enabled:        true
                    visible:        true
                    imageSource:    "/custom/img/payload_init.svg"
                    text:           "INIT"
                    checked:        false

                    onClicked: {
                        console.warn("btn pressed, action: ", actionPayloadInit)
                        confirmAction(actionPayloadInit)
                    }
                }
                CustomHoverButton {
                    id:             buttonActivatePayload
                    Layout.fillWidth: false
                    Layout.minimumHeight: _indicatorsHeight * 3
                    Layout.minimumWidth: indicatorValueWidth * 1.5
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.mediumFontPointSize
                    autoExclusive:  true

                    enabled:        true
                    visible:        true
                    imageSource:    "/custom/img/payload_activate.svg"
                    text:           "ACTIVATE"
                    checked:        false

                    onClicked: {
                        console.warn("btn pressed, action: ", actionPayloadActivate)
                        confirmAction(actionPayloadActivate)
                    }
                }
                CustomHoverButton {
                    id:             buttonResetPayload
                    Layout.fillWidth: false
                    Layout.minimumHeight: buttonActivatePayload.height
                    Layout.minimumWidth: indicatorValueWidth * 1.5
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.mediumFontPointSize
                    autoExclusive:  true

                    enabled:        true
                    visible:        true
                    imageSource:    "/res/XDelete.svg"
                    text:           "RESET"
                    checked:        false

                    onClicked: {
                        console.warn("btn pressed, action: ", actionPayloadReset)
                        executeAction(actionPayloadReset)
                    }
                }
            }
        }
    }
}
