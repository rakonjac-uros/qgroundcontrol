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
import QtWebSockets             1.15

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
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 50
    property alias  _gripperMenu:           gripperOptions
    property real   _defaultWidgetOpacity:  0.7


    function getName(systemID){
        var vehicleName
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

    function getIP(systemID) {
        var vehicleIP
        switch (systemID) {
        case 1:
            vehicleIP = "10.49.0.3"
            break
        case 2:
            vehicleIP = "10.49.0.4"
            break
        case 3:
            vehicleIP = "10.49.0.5"
            break
        default:
            vehicleIP = "10.49.0.2"
            break
        }
        return vehicleIP
    }

    function sendPanValue(address, panValue) {
        //http://{ip}:9002/ptu/pan/{value}
        var http = new XMLHttpRequest()
        var url = "http://" + address + ":9002/ptu/pan/" + panValue;
        var params = "";
        http.open("POST", url, true);

        // Send the proper header information along with the request
        http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        http.setRequestHeader("Content-length", params.length);
        http.setRequestHeader("Connection", "close");

        http.onreadystatechange = function() { // Call a function when the state changes.
            if (http.readyState == 4) {
                if (http.status == 200) {
                    console.log("ok")
                } else {
                    console.log("error: " + http.status)
                }
            }
        }
        http.send(params);
    }

    function sendTiltValue(address, tiltValue) {
        //http://{ip}:9002/ptu/tilt/{value}
        var http = new XMLHttpRequest()
        var url = "http://" + address + ":9002/ptu/tilt/" + tiltValue;
        var params = "";
        http.open("POST", url, true);

        // Send the proper header information along with the request
        http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        http.setRequestHeader("Content-length", params.length);
        http.setRequestHeader("Connection", "close");

        http.onreadystatechange = function() { // Call a function when the state changes.
            if (http.readyState == 4) {
                if (http.status == 200) {
                    console.log("ok")
                } else {
                    console.log("error: " + http.status)
                }
            }
        }
        http.send(params);
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
        interval:  1000
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

    // property var cameraPos: [
    //     { pan: 0, tilt: 0 }, // Camera 1
    //     { pan: 0, tilt: 0 }, // Camera 2
    //     { pan: 0, tilt: 0 }  // Camera 3
    // ]

    // WebSocket { // alpha
    //     id: socket1
    //     url: "ws://10.49.0.3:9002/v1/sentrydatasource"

    //     onTextMessageReceived: {
    //         var somestring = JSON.parse(message)
    //         // var msgType = somestring.type;
    //         // if (msgType === "result") {
    //         //     //Someaction()
    //         // }
    //         console.log("ALPHA: " + somestring)
    //     }
    // }
    // WebSocket { // bravo
    //     id: socket2
    //     url: "ws://10.49.0.4:9002/v1/sentrydatasource"

    //     onTextMessageReceived: {
    //         var somestring = JSON.parse(message)
    //         // var msgType = somestring.type;
    //         // if (msgType === "result") {
    //         //     //Someaction()
    //         // }
    //         console.log("BRAVO: " + somestring)
    //     }
    // }
    // WebSocket { // charlie
    //     id: socket3
    //     url: "ws://10.49.0.5:9002/v1/sentrydatasource"

    //     onTextMessageReceived: {
    //         var somestring = JSON.parse(message)
    //         // var msgType = somestring.type;
    //         // if (msgType === "result") {
    //         //     //Someaction()
    //         // }
    //         console.log("CHARLIE: " + somestring)
    //     }
    // }

    // Instantiator {
    //     id: socketManager
    //     property var names: ["alpha", "bravo", "charlie"]
    //     delegate: WebSocket{
    //         //id: socket
    //         url: "ws://localhost:9002"

    //         onTextMessageReceived: {
    //             var somestring = JSON.parse(message)
    //             var msgType = somestring.type;
    //             if (msgType === "result") {
    //                 console.log(somestring.type)
    //             }
    //         }
    //     }
    //     model: names
    //     active: (names.length > 0)
    // }

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
        id: multiVehicleList
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
        anchors.centerIn:           parent
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


    signal windowAboutToOpen    // Catch this signal to do something special prior to the item transition to windowed mode
    signal windowAboutToClose   // Catch this signal to do special processing prior to the item transition back to pip mode


    Window {
        id:         windowBravo
        title:      "BRAVO"
        visible:    true
        width: parent.width /4
        height: parent.height /4

        property int _vehicleID: 2

        //-- Video 2
        Rectangle {
            anchors.fill: parent
            // anchors.margins:        _toolsMargin
            // anchors.right:          parent.right
            // anchors.top: rgbItem.bottom
            // width:                  _rightPanelWidth
            // height: _rightPanelWidth*0.7
            //width:              height * QGroundControl.videoManager.thermalAspectRatio
            //height:             _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_FULL ? parent.height : (_camera.thermalMode === QGCCameraControl.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
            //anchors.centerIn:   parent
            visible:            true //QGroundControl.videoManager.hasThermal && _camera.thermalMode !== QGCCameraControl.THERMAL_OFF

            QGCVideoBackground {
                id:             videoReceiverRGB1
                objectName:     "videoReceiverRGB1"
                anchors.fill:   parent
                receiver:       QGroundControl.videoManager.videoReceiverRGB1
                visible: btnBravoRGB.checked
                //opacity:        _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
            }
        }
        QGCVideoBackground {
            id:             videoReceiverTh1
            objectName:     "videoReceiverTh1"
            anchors.fill:   parent
            receiver:       QGroundControl.videoManager.videoReceiverTh1
            visible: btnBravoTh.checked
            //opacity:        _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
        }

        Connections {
            target: multiVehicleList
            onMessage: {
                if(id == 2) {
                    windowBravo.show()
                }
                console.log(id)
            }
        }

        Rectangle { // camera control
            id:                 videoTypePanelSelector2
            //anchors.bottom:     parent.bottom
            //anchors.right:      parent.right
            anchors.margins:        _toolsMargin
            width:                  payloadLayout2.width  + (ScreenTools.defaultFontPixelWidth  * 12)//5
            height:             _indicatorsHeight * 8
            color:                  Qt.rgba(0,0,0,0.5)
            radius:                 8
            //x:                      recalcXPosition() //Math.round((mainWindow.width  - width)  * 0.5)//0.5

            anchors.right:          parent.right
            anchors.bottom: parent.bottom

            ColumnLayout {

                id:                     cameraControlColumnLayout2
                Layout.fillWidth:       true
                anchors.centerIn:       parent
                anchors.margins:            _toolsMargin

                RowLayout{

                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        enabled:        true
                        visible:        true
                    }
                    QGCButton {
                        id: btnBravoRGB
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight * 0.8
                        Layout.maximumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true //_activeVehicle
                        visible:        true
                        text:           "RGB"
                        checked:        true
                        checkable:      true
                        pointSize:      ScreenTools.smallFontPointSize

                        onClicked: {
                            console.log("Bravo RGB")
                            btnBravoRGB.checked = true
                            btnBravoTh.checked = false
                        }
                    }
                    QGCButton {
                        id: btnBravoTh
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight * 0.8
                        Layout.maximumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true //_activeVehicle
                        visible:        true
                        text:           "TH"
                        checkable:      true
                        checked:        false
                        pointSize:      ScreenTools.smallFontPointSize

                        onClicked: {
                            console.log("Bravo THERM")
                            btnBravoRGB.checked = false
                            btnBravoTh.checked = true
                        }
                    }
                }

                RowLayout {
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    height:                 _indicatorsHeight * 3

                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true
                        visible:        true
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "FRONT"
                        checked:        false

                        onClicked: {
                            console.log("FRONT")
                            sendPanValue(getIP(2),"0")
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true
                        visible:        true

                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true
                        visible:        true

                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "UP"
                        checked:        false

                        onClicked: {
                            console.info("UP")
                            sendTiltValue(getIP(2),"20")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "-0-"
                        checked:        false

                        onClicked: {
                            console.info("Zero tilt")
                            sendTiltValue(getIP(2),"0")
                        }
                    }
                }
                RowLayout {
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    height:                 _indicatorsHeight * 3

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "LEFT"
                        checked:        false

                        onClicked: {
                            console.info("LEFT")
                            sendPanValue(getIP(2),"-90")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "BACK"
                        checked:        false

                        onClicked: {
                            console.info("BACK")
                            sendPanValue(getIP(2),"180")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "RIGHT"
                        checked:        false

                        onClicked: {
                            console.info("RIGHT")
                            sendPanValue(getIP(2),"90")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "-30"
                        checked:        false

                        onClicked: {
                            console.info("-30")
                            sendPanValue(getIP(2),"-30")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "DOWN"
                        checked:        false

                        onClicked: {
                            console.info("DOWN")
                            sendTiltValue(getIP(2),"-20")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "+30"
                        checked:        false

                        onClicked: {
                            console.info("+30")
                            sendPanValue(getIP(2),"30")
                        }
                    }
                }
            }
        }
    }

    Window {
        id:         windowCharlie
        title:      "CHARLIE"
        visible:    true
        width: parent.width /4
        height: parent.height /4


        Rectangle {
            anchors.fill: parent
            // anchors.margins:        _toolsMargin
            // anchors.right:          parent.right
            // anchors.top: rgbItem.bottom
            // width:                  _rightPanelWidth
            // height: _rightPanelWidth*0.7
            //width:              height * QGroundControl.videoManager.thermalAspectRatio
            //height:             _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_FULL ? parent.height : (_camera.thermalMode === QGCCameraControl.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
            //anchors.centerIn:   parent
            visible:            true //QGroundControl.videoManager.hasThermal && _camera.thermalMode !== QGCCameraControl.THERMAL_OFF

            QGCVideoBackground {
                id:             videoReceiverRGB2
                objectName:     "videoReceiverRGB2"
                anchors.fill:   parent
                receiver:       QGroundControl.videoManager.videoReceiverRGB2
                visible:        btnCharlieRGB.checked
                //opacity:        _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
            }
        }

        QGCVideoBackground {
            id:             videoReceiverTh2
            objectName:     "videoReceiverTh2"
            anchors.fill:   parent
            receiver:       QGroundControl.videoManager.videoReceiverTh2
            visible:        btnCharlieTh.checked
            //opacity:        _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
        }

        Connections {
            target: multiVehicleList
            onMessage: {
                console.log(id)
                if(id == 3) {
                    windowCharlie.show()
                }
            }
        }

        Rectangle { // camera control
            //anchors.bottom:     parent.bottom
            //anchors.right:      parent.right
            anchors.margins:        _toolsMargin
            width:                  payloadLayout2.width  + (ScreenTools.defaultFontPixelWidth  * 12)//5
            height:             _indicatorsHeight * 8
            color:                  Qt.rgba(0,0,0,0.5)
            radius:                 8
            //x:                      recalcXPosition() //Math.round((mainWindow.width  - width)  * 0.5)//0.5

            anchors.right:          parent.right
            anchors.bottom: parent.bottom

            property int _vehicleID: 3

            ColumnLayout {
                Layout.fillWidth:       true
                anchors.centerIn:       parent
                anchors.margins:            _toolsMargin

                RowLayout{

                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        enabled:        true
                        visible:        true
                    }
                    QGCButton {
                        id: btnCharlieRGB
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight * 0.8
                        Layout.maximumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "RGB"
                        checked:        true
                        checkable:      true
                        pointSize:      ScreenTools.smallFontPointSize

                        onClicked: {
                            btnCharlieRGB.checked = true
                            btnCharlieTh.checked = false
                        }
                    }
                    QGCButton {
                        id: btnCharlieTh
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight * 0.8
                        Layout.maximumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "TH"
                        checkable:      true
                        checked:        false
                        pointSize:      ScreenTools.smallFontPointSize

                        onClicked: {
                            btnCharlieRGB.checked = false
                            btnCharlieTh.checked = true
                        }
                    }
                }

                RowLayout {
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    height:                 _indicatorsHeight * 3

                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true
                        visible:        true
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "FRONT"
                        checked:        false

                        onClicked: {
                            console.info("FRONT")
                            sendPanValue(getIP(3),"0")
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true
                        visible:        true

                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        true
                        visible:        true

                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "UP"
                        checked:        false

                        onClicked: {
                            console.info("UP")
                            sendTiltValue(getIP(3),"20")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "-0-"
                        checked:        false

                        onClicked: {
                            console.info("Zero tilt")
                            sendTiltValue(getIP(3),"0")
                        }
                    }
                }
                RowLayout {
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    height:                 _indicatorsHeight * 3

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "LEFT"
                        checked:        false

                        onClicked: {
                            console.info("LEFT")
                            sendPanValue(getIP(3),"-90")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "BACK"
                        checked:        false

                        onClicked: {
                            console.info("BACK")
                            sendPanValue(getIP(3),"180")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "RIGHT"
                        checked:        false

                        onClicked: {
                            console.info("RIGHT")
                            sendPanValue(getIP(3),"90")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "-30"
                        checked:        false

                        onClicked: {
                            console.info("-30")
                            sendPanValue(getIP(3),"-30")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "DOWN"
                        checked:        false

                        onClicked: {
                            console.info("DOWN")
                            sendTiltValue(getIP(3),"-20")
                        }
                    }
                    QGCButton {
                        Layout.fillWidth: true
                        Layout.minimumHeight: _indicatorsHeight
                        Layout.minimumWidth: _indicatorsHeight
                        Layout.maximumWidth: _rightPanelWidth / 6.5
                        enabled:        _activeVehicle
                        visible:        true
                        text:           "+30"
                        checked:        false

                        onClicked: {
                            console.info("+30")
                            sendPanValue(getIP(3),"30")
                        }
                    }
                }
            }
        }
    }

    PhotoVideoControl {
        id:                     photoVideoControl
        anchors.margins:        _toolsMargin
        anchors.right:          parent.right
        width:                  _rightPanelWidth
        visible: false

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

    // JoystickThumbPad {
    //     id:                 testJoystick
    //     anchors.top:     videoTypePanelSelector.bottom
    //     anchors.right:      parent.right
    //     width:              _rightPanelWidth
    //     height:             _rightPanelWidth
    //     yAxisReCenter: false
    //     onStickPositionXChanged: {
    //         console("Joystick x: ", xAxis)
    //         console("Joystick y: ", yAxis)
    //     }
    // }


    TelemetryValuesBar {
        id:                 telemetryPanel
        x:                  recalcXPosition()
        anchors.margins:    _toolsMargin
        visible:            _activeVehicle

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

    Rectangle { // vehicle info
        id:                     vehicleIndicator
        color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,_defaultWidgetOpacity)//0.3
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
                // QGCLabel {
                //     text:                   _activeVehicle ? "PWM" + _activeVehicle.engine.chan3.valueString + "" : "PWM -"
                //     color:                  _indicatorsColor
                //     font.pointSize:         ScreenTools.mediumFontPointSize
                //     Layout.fillWidth:       false
                //     Layout.minimumWidth:    indicatorValueWidth
                //     Layout.minimumHeight:    _indicatorsHeight
                //     Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                //     horizontalAlignment:    Text.AlignHCenter
                // }
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
                    text:                   "FUEL CONS."
                    color:                  _indicatorsColor
                    font.pointSize:         ScreenTools.mediumFontPointSize
                    Layout.fillWidth:       false
                    Layout.minimumWidth:    indicatorValueWidth
                    Layout.minimumHeight:    _indicatorsHeight
                    Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    horizontalAlignment:    Text.AlignHCenter
                }

                QGCLabel {
                    // values are in cm3/min, we are displaying the value as L/h
                    text:                   _activeVehicle ? (_activeVehicle.efi.fuelFlow.value * 0.06).toFixed(1) + " L/h": "-"
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

                    text: _activeVehicle ? (_activeVehicle.batteries.get(0).voltage.valueString + " " + _activeVehicle.batteries.get(0).voltage.units) : "N/A"
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

    Rectangle { // payload control
        id:                     payloadControl
        color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,_defaultWidgetOpacity)//0.3
        width:                  payloadLayout2.width  + (ScreenTools.defaultFontPixelWidth  * 12)//5
        height:                 buttonInitPayload.height + payloadControlLabel.height + (ScreenTools.defaultFontPixelHeight * 1.5)//1.5
        radius:                 8
        x:                      recalcXPosition() //Math.round((mainWindow.width  - width)  * 0.5)//0.5
        //y:                      Math.round((mainWindow.height - height) * 0.7)//0.5
        anchors.bottom: telemetryPanel.top

        anchors.margins:        _toolsMargin
        anchors.horizontalCenter:      parent.horizontalCenter
        //anchors.top:            vehicleIndicator.bottom
        //width:                  _rightPanelWidth


        function recalcXPosition() {
            // First try centered
            var halfRootWidth   = _root.width / 2
            var halfPanelWidth  = payloadControl.width / 2
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

        ColumnLayout {
            id:                     payloadControlColumnLayout
            Layout.fillWidth:       true
            anchors.centerIn:       parent
            anchors.margins:            _toolsMargin

            QGCLabel {
                id:                     payloadControlLabel
                text:                   "PAYLOAD CONTROL"
                color:                  _indicatorsColor
                font.pointSize:         ScreenTools.mediumFontPointSize
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
                        font.pointSize:         ScreenTools.smallFontPointSize
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
                    Layout.minimumWidth: _indicatorsHeight * 3 //indicatorValueWidth * 1.5
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.smallFontPointSize
                    autoExclusive:  true

                    enabled:        true
                    visible:        true
                    imageSource:    "/custom/img/payload_activate.svg"
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
                    Layout.minimumWidth: _indicatorsHeight * 3 //indicatorValueWidth * 1.5
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.smallFontPointSize
                    autoExclusive:  true

                    enabled:        true
                    visible:        true
                    imageSource:    "/custom/img/payload_init.svg"
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
                    Layout.minimumHeight: _indicatorsHeight * 2
                    Layout.minimumWidth: _indicatorsHeight * 2 //indicatorValueWidth * 1.5
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:  ScreenTools.smallFontPointSize
                    autoExclusive:  true

                    enabled:        true
                    visible:        true
                    imageSource:    "/res/XDelete.svg"
                    text:           "RESET"
                    checked:        false

                    onClicked: {
                        console.warn("btn pressed, action: ", actionPayloadReset)
                        confirmAction(actionPayloadReset)
                    }
                }
            }
        }
    }

    // Rectangle { // camera control
    //     id:                 videoTypePanelSelector
    //     //anchors.bottom:     parent.bottom
    //     //anchors.right:      parent.right
    //     anchors.margins:        _toolsMargin
    //     width:                  payloadLayout2.width  + (ScreenTools.defaultFontPixelWidth  * 12)//5
    //     height:             _indicatorsHeight * 8
    //     color:                  qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.95) : Qt.rgba(0,0,0,_defaultWidgetOpacity)//0.3
    //     radius:                 8
    //     x:                      recalcXPosition() //Math.round((mainWindow.width  - width)  * 0.5)//0.5

    //     anchors.right:          parent.right
    //     anchors.top:            payloadControl.bottom

    //     function recalcXPosition() {
    //         // First try centered
    //         var halfRootWidth   = _root.width / 2
    //         var halfPanelWidth  = payloadControl.width / 2
    //         var leftX           = (halfRootWidth - halfPanelWidth) - _toolsMargin
    //         var rightX          = (halfRootWidth + halfPanelWidth) + _toolsMargin
    //         if (leftX >= parentToolInsets.leftEdgeBottomInset || rightX <= parentToolInsets.rightEdgeBottomInset ) {
    //             // It will fit in the horizontalCenter
    //             return halfRootWidth - halfPanelWidth
    //         } else {
    //             // Anchor to left edge
    //             return parentToolInsets.leftEdgeBottomInset + _toolsMargin
    //         }
    //     }

    //     ColumnLayout {

    //         id:                     cameraControlColumnLayout
    //         Layout.fillWidth:       true
    //         anchors.centerIn:       parent
    //         anchors.margins:            _toolsMargin

    //         RowLayout{

    //             QGCLabel {
    //                 text:                   "CAMERA CONTROL"
    //                 color:                  _indicatorsColor
    //                 font.pointSize:         ScreenTools.mediumFontPointSize
    //                 Layout.fillWidth:       true
    //                 Layout.minimumWidth:    indicatorValueWidth * 1.5
    //                 Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
    //                 horizontalAlignment:    Text.AlignHCenter
    //                 padding:                ScreenTools.defaultFontPixelWidth
    //             }

    //             Item {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 enabled:        true
    //                 visible:        true
    //             }
    //             QGCButton {
    //                 id: btnRGB
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight * 0.8
    //                 Layout.maximumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "RGB"
    //                 checked:        true
    //                 checkable:      true
    //                 pointSize:      ScreenTools.smallFontPointSize

    //                 onClicked: {
    //                     console.info("RGB")
    //                     btnThermal.checked = false
    //                     QGroundControl.multiVehicleManager.changeActiveVideoStream(false)
    //                     windowRGB.show()
    //                 }
    //             }
    //             QGCButton {
    //                 id: btnThermal
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight * 0.8
    //                 Layout.maximumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "TH"
    //                 checkable:      true
    //                 checked:        false
    //                 pointSize:      ScreenTools.smallFontPointSize

    //                 onClicked: {
    //                     console.info("THERM")
    //                     btnRGB.checked = false
    //                     QGroundControl.multiVehicleManager.changeActiveVideoStream(true)
    //                 }
    //             }
    //         }

    //         RowLayout {
    //             Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
    //             height:                 _indicatorsHeight * 3

    //             Item {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        true
    //                 visible:        true
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "FRONT"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("FRONT")
    //                     sendPanValue(getIP(_activeVehicle.id),"0")
    //                 }
    //             }
    //             Item {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        true
    //                 visible:        true

    //             }
    //             Item {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        true
    //                 visible:        true

    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "UP"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("UP")
    //                     sendTiltValue(getIP(_activeVehicle.id),"20")
    //                 }
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "-0-"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("Zero tilt")
    //                     sendTiltValue(getIP(_activeVehicle.id),"0")
    //                 }
    //             }
    //         }
    //         RowLayout {
    //             Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
    //             height:                 _indicatorsHeight * 3

    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "LEFT"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("LEFT")
    //                     sendPanValue(getIP(_activeVehicle.id),"-90")
    //                 }
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "BACK"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("BACK")
    //                     sendPanValue(getIP(_activeVehicle.id),"180")
    //                 }
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "RIGHT"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("RIGHT")
    //                     sendPanValue(getIP(_activeVehicle.id),"90")
    //                 }
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "<<"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("<<")
    //                     sendPanValue(getIP(_activeVehicle.id),"-30")
    //                 }
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           "DOWN"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info("DOWN")
    //                     sendTiltValue(getIP(_activeVehicle.id),"-20")
    //                 }
    //             }
    //             QGCButton {
    //                 Layout.fillWidth: true
    //                 Layout.minimumHeight: _indicatorsHeight
    //                 Layout.minimumWidth: _indicatorsHeight
    //                 Layout.maximumWidth: _rightPanelWidth / 6.5
    //                 enabled:        _activeVehicle
    //                 visible:        true
    //                 text:           ">>"
    //                 checked:        false

    //                 onClicked: {
    //                     console.info(">>")
    //                     sendPanValue(getIP(_activeVehicle.id),"30")
    //                 }
    //             }
    //         }
    //     }
    // }
}
