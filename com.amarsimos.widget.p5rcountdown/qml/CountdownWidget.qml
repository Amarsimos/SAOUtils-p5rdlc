import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T
import QtQuick 2.12
import QtQuick.Controls 2.12

T.Widget {
    id: widget

    readonly property Image
    digitSprites: Image {
        mipmap: false
        source: "../Images/digits.png"
    }

    readonly property Image
    backgroundSprite: Image {
        mipmap: false
        source: "../Images/background.png"
    }

    readonly property bool inverseMode: widget.settings.inverse ?? false
    readonly property color spriteColor1: inverseMode ? "black" : "white"
    readonly property color spriteColor2: inverseMode ? "white" : "black"
    property string eventText: widget.settings.eventText ?? qsTr("GP更新")
    property string bottomText: widget.settings.bottomText ?? qsTr("盗取GP的心")
    property var targetDate: widget.settings.targetDate ? new Date(widget.settings.targetDate) : new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)
    property int daysRemaining: calculateDaysRemaining()

    function calculateDaysRemaining() {
        const today = new Date();
        today.setHours(0, 0, 0, 0); // Normalize today's date
        const target = targetDate; // Use the property which is bound to settings
        target.setHours(0, 0, 0, 0); // Normalize target date
        const diffTime = target.getTime() - today.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return Math.max(0, diffDays); // Don't show negative numbers
    }

    function getSplitText(text) {
        var res = [];
        for (var i = 0; i < text.length; i += 2) {
            res.push(text.substring(i, Math.min(i + 2, text.length)));
        }
        return res;
    }

    title: qsTr("P5R Countdown")
    solid: false
    resizable: false
    editing: dialog.active
    implicitWidth: mainLayout.width
    implicitHeight: mainLayout.height
    layer.enabled: true

    FontLoader {
        id: customFont

        source: "../Others/FZLanTingHei-B.ttf"
    }

    FontLoader {
        id: gothicFont

        source: "../Others/TsukuARdGothicStd-Bold.ttf"
    }

    Loader {
        id: dialog

        active: false
        source: "CountdownEditor.qml"
        onLoaded: {
            item.visible = true;
            item.visibleChanged.connect(function() {
                if (!item.visible)
                    dialog.active = false;

            });
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 1000 * 60 * 60
        onTriggered: {
            daysRemaining = calculateDaysRemaining();
        }
    }

    // Main Content Container
    Item {
        // 1. Content Wrapper (Source for Shader - Contains only Text)

        id: mainLayout

        width: contentWrapper.width - 10
        height: Math.max(contentWrapper.height, bottomRect.y + bottomRect.height + 10)
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 25

        Item {
            id: contentWrapper

            z: -1
            width: mainRow.width + 100
            height: mainRow.height + 40
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                id: mainRow

                anchors.centerIn: parent
                spacing: -5

                // Event Name
                Item {
                    // "距离" Text

                    width: eventTextRow.width + 10
                    height: 85

                    Text {
                        text: qsTr("距离")
                        font.family: customFont.name
                        font.pixelSize: 16
                        font.bold: true
                        color: "#ff0000"
                        rotation: -17
                        anchors.bottom: eventTextRow.top
                        anchors.bottomMargin: -10
                        anchors.left: eventTextRow.left
                        anchors.leftMargin: -15
                    }

                    Row {
                        id: eventTextRow

                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

                        Repeater {
                            model: getSplitText(eventText)

                            delegate: Item {
                                width: tNode.implicitWidth
                                height: tNode.implicitHeight
                                rotation: -17

                                Rectangle {
                                    color: "black"
                                    width: parent.width - 15
                                    height: 40
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 20
                                    z: -5
                                }

                                Text {
                                    id: tNode

                                    z: 1
                                    text: modelData
                                    font.family: customFont.name
                                    font.pixelSize: 40
                                    font.bold: true
                                    color: "#ff0000"
                                    styleColor: "black"
                                    anchors.centerIn: parent
                                }

                            }

                        }

                    }

                    // "还剩" Text
                    Text {
                        text: qsTr("还剩")
                        font.family: customFont.name
                        font.pixelSize: 16
                        color: "#ff0000"
                        rotation: -17
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -20
                        anchors.bottomMargin: -4
                    }

                }

                // Spacer
                Item {
                    width: 32
                    height: 1
                }

                // Digit Block
                Row {
                    id: daysRow

                    readonly property string daysString: daysRemaining.toString()

                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -6
                    spacing: -2

                    Repeater {
                        model: daysRow.daysString.length

                        delegate: Rectangle {
                            readonly property real randomRot: (Math.random() * 4) - 2

                            width: 36
                            height: 49
                            color: "#ff0000"
                            rotation: -17 + randomRot

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -1
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: daysRow.daysString[index]
                                font.family: customFont.name
                                font.pixelSize: 46
                                font.bold: true
                                color: "black"
                            }

                        }

                    }

                }

                // Spacer
                Item {
                    width: 15
                    height: 1
                }

                // "日" Text
                Text {
                    text: qsTr("日")
                    font.family: customFont.name
                    font.pixelSize: 24
                    font.bold: true
                    color: "#ff0000"
                    rotation: -18
                    anchors.bottom: parent.bottom
                }

            }

        }

        // Background Outline Effect
        ShaderEffectSource {
            id: effectSource

            sourceItem: contentWrapper
            visible: false
        }

        ShaderEffect {
            property variant source: effectSource
            property point delta: Qt.point(1 / width, 1 / height)

            anchors.fill: contentWrapper
            z: -3
            fragmentShader: Qt.resolvedUrl("../Shaders/Dilate.frag")
        }

        // 2. Bottom Red Rectangle
        Rectangle {
            id: bottomRect

            width: mainRow.width
            height: 25
            color: "#ff0000"
            anchors.top: contentWrapper.bottom
            anchors.topMargin: -15
            anchors.horizontalCenter: contentWrapper.horizontalCenter
            anchors.horizontalCenterOffset: -25
            z: 0

            Text {
                anchors.centerIn: parent
                text: bottomText
                font.family: gothicFont.name
                font.pixelSize: 18
                font.bold: true
                color: "black"
            }

        }

        Rectangle {
            id: bottomRectBackground

            width: mainRow.width + 40
            height: 45
            color: "transparent"
            anchors.verticalCenter: bottomRect.verticalCenter
            anchors.horizontalCenter: contentWrapper.horizontalCenter
            anchors.horizontalCenterOffset: -25
            z: -5

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = "#000000";
                    ctx.beginPath();
                    var step = 4;
                    var amp = 8;
                    ctx.moveTo(0, 0);
                    ctx.lineTo(width, 0);
                    for (var y = 0; y <= height; y += step) ctx.lineTo(width - Math.random() * amp, y)
                    ctx.lineTo(width, height);
                    ctx.lineTo(0, height);
                    for (var y = height; y >= 0; y -= step) ctx.lineTo(Math.random() * amp, y)
                    ctx.closePath();
                    ctx.fill();
                }
            }

        }

    }

    menu: Menu {
        MenuItem {
            text: qsTr("Settings...")
            onTriggered: dialog.active = true
        }

    }

}
