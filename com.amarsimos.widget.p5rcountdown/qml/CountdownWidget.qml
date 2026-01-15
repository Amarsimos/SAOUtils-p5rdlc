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
    readonly property real uiScale: 2

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
    implicitWidth: mainLayout.width * uiScale
    implicitHeight: mainLayout.height * uiScale
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
        // 不再参考 contentWrapper.height，因为它包含为了 Shader 防裁切而设置的大量填充

        id: mainLayout

        scale: uiScale
        width: contentWrapper.width - 10
        height: contentWrapper.height
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 25

        Item {
            id: contentWrapper

            z: -1
            width: mainRow.width + 100
            // 增加高度缓冲以防止旋转后的文本被裁切
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
            // 关键：生成 2x 分辨率的高清纹理，配合 uiScale 实现抗锯齿
            textureSize: Qt.size(contentWrapper.width * uiScale, contentWrapper.height * uiScale)
        }

        ShaderEffect {
            property variant source: effectSource
            // 根据高清纹理尺寸计算采样步长
            property point delta: Qt.point(1 / (contentWrapper.width * uiScale), 1 / (contentWrapper.height * uiScale))
            // 传递描边半径 (2x 分辨率下设为 20.0 以获得更粗的视觉效果)
            property real radius: 18

            anchors.fill: contentWrapper
            z: -3
            fragmentShader: Qt.resolvedUrl("../Shaders/Dilate.frag")
        }

        // 2. Bottom Red Rectangle
        Rectangle {
            id: bottomRect

            width: mainRow.width
            height: 20
            color: "#ff0000" // 恢复为普通矩形
            // 修复分离问题：不再锚定于 contentWrapper.bottom (受宽度影响大)，
            // 而是锚定于 contentWrapper.verticalCenter，保持相对位置恒定。
            anchors.top: contentWrapper.verticalCenter
            anchors.topMargin: 47 // 基于 mainRow 高度估算的偏移量 (约半高 + 间距)
            anchors.horizontalCenter: contentWrapper.horizontalCenter
            anchors.horizontalCenterOffset: -25
            z: 0

            // 叠加遮罩：在左侧绘制黑色形状以形成“内凹”
            Canvas {
                id: leftMask

                width: 15 // 遮罩区域宽度
                height: parent.height
                anchors.left: parent.left
                anchors.top: parent.top
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = "black"; // 与背景同色
                    ctx.beginPath();
                    var indent = 4;
                    // 绘制要“切掉”的部分（黑色覆盖）
                    // 形状：左边沿的 > 形切口
                    ctx.moveTo(0, 0);
                    ctx.lineTo(indent, height / 2); // 内凹尖点
                    ctx.lineTo(0, height);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 4
                text: bottomText
                font.family: gothicFont.name
                font.pixelSize: 16
                font.bold: true
                color: "black"
            }

        }

        Rectangle {
            id: bottomRectBackground

            width: mainRow.width + 40
            height: 35
            color: "transparent"
            anchors.verticalCenter: bottomRect.verticalCenter
            anchors.horizontalCenter: contentWrapper.horizontalCenter
            anchors.horizontalCenterOffset: -25
            z: -5

            Canvas {
                anchors.fill: parent
                // 提高纹理质量
                renderTarget: Canvas.FramebufferObject
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.imageSmoothingEnabled = false; // 关闭平滑，防止羽化
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = "#000000";
                    // P5R 风格：保持边缘绝对锐利，不使用半透明或平滑
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
