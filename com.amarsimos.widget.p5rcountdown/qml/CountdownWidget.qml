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
    // 整体放大倍数。布局按逻辑像素写，mainLayout 再整体放大 uiScale 倍；描边、笔刷等纹理也按这个倍数高清绘制
    readonly property real uiScale: 2
    // 所有文字（含数字红底）的横向压缩比例，1 为原始宽度
    readonly property real textScaleX: 0.85
    // 主标题（可编辑的 Event 文本）的旋转角度；其余固定文字为 -17° 左右
    readonly property real eventTextRotation: -19
    // 红条高度；黑色笔刷背景比红条宽 40、高 15
    readonly property real bottomBarHeight: 28
    // 黑色笔刷背景的实际外框（背景局部坐标），用于画布余量和挂件边距
    readonly property var brushBounds: pointsBounds(brushStrokes(contentWrapper.bottomBarWidth + 40, bottomBarHeight + 15))

    function calculateDaysRemaining() {
        const today = new Date();
        today.setHours(0, 0, 0, 0); // 只比较日期，去掉时分秒
        const target = targetDate;
        target.setHours(0, 0, 0, 0);
        const diffTime = target.getTime() - today.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return Math.max(0, diffDays); // 已过期时显示 0
    }

    // 红条后黑色笔刷背景的形状。形状固定，只有长度随宽度 w 变化（数值来自之前随机生成后定下的一组结果）。
    // - 上下两笔，下面一笔高度为接缝到底边的 0.55 倍，外侧上下边水平
    // - 两笔之间的接缝在左端留 2 的缝，往右逐渐收窄，到右端两笔贴合
    // - 左右末端直线斜切：上面一笔呈倒梯形（上边长），下面一笔呈正梯形（下边长）且接近矩形
    // 返回每笔的四边形顶点（背景局部坐标，单位为逻辑像素）。画布绘制和挂件边距计算都调用它，保证两者一致。
    function brushStrokes(w, h) {
        var deg = Math.PI / 180;
        var leftGap = 2;
        var seam = h / 2 + 0.68;
        var overlap = 0.3; // 右端两笔略微重叠，避免抗锯齿留出细缝
        var lowerHeight = (h - seam) * 0.55;
        // 每笔：上边/下边在左右两端的 y；左右末端相对背景边缘往内缩的距离；末端斜切角度（相对竖直）。
        // sign 为 1 时上边比下边长（倒梯形），-1 时下边比上边长（正梯形）
        var edges = [{
            "topL": 0.93,
            "topR": 0.93,
            "botL": seam - leftGap / 2,
            "botR": seam + overlap,
            "insetL": 11.24,
            "insetR": 6.35,
            "cutL": 10.83 * deg,
            "cutR": 11.14 * deg,
            "sign": 1
        }, {
            "topL": seam + leftGap / 2,
            "topR": seam - overlap,
            "botL": seam + lowerHeight - 0.06,
            "botR": seam + lowerHeight - 0.06,
            "insetL": 1.75,
            "insetR": 1.66,
            "cutL": 4.89 * deg,
            "cutR": 3.69 * deg,
            "sign": -1
        }];
        var result = [];
        for (var i = 0; i < edges.length; i++) {
            var e = edges[i];
            var left = e.insetL;
            var right = w - e.insetR;
            // x = 端点 + (y - 中点) * t：左端 t 为正时上边往外伸，右端 t 为负时上边往外伸
            var tl = e.sign * Math.tan(e.cutL);
            var tr = -e.sign * Math.tan(e.cutR);
            // 末端斜切线过本笔在该端的竖直中点
            var midL = (e.topL + e.botL) / 2;
            var midR = (e.topR + e.botR) / 2;
            result.push([Qt.point(left + (e.topL - midL) * tl, e.topL), Qt.point(right + (e.topR - midR) * tr, e.topR), Qt.point(right + (e.botR - midR) * tr, e.botR), Qt.point(left + (e.botL - midL) * tl, e.botL)]);
        }
        return result;
    }

    // 一组多边形顶点的外接矩形 { minX, minY, maxX, maxY }
    function pointsBounds(strokes) {
        var b = {
            "minX": Infinity,
            "minY": Infinity,
            "maxX": -Infinity,
            "maxY": -Infinity
        };
        for (var i = 0; i < strokes.length; i++) {
            for (var j = 0; j < strokes[i].length; j++) {
                var p = strokes[i][j];
                b.minX = Math.min(b.minX, p.x);
                b.minY = Math.min(b.minY, p.y);
                b.maxX = Math.max(b.maxX, p.x);
                b.maxY = Math.max(b.maxY, p.y);
            }
        }
        return b;
    }

    // 主标题每两个字为一组，每组单独旋转、带一条黑色色块
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
    // 挂件尺寸 = 内容区放大后的尺寸，随文字长度自动变化
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

    // 每小时重新计算一次剩余天数，跨过零点后能及时更新
    Timer {
        running: true
        repeat: true
        interval: 1000 * 60 * 60
        onTriggered: {
            daysRemaining = calculateDaysRemaining();
        }
    }

    // ===== 内容区 =====
    // 图层从下到上：黑色笔刷背景(z -5) → 文字黑色描边(z -3) → 文字 contentWrapper(z -1) → 底部红条(z 0)
    // 坐标单位都是逻辑像素，整个内容区再放大 uiScale 倍显示。
    Item {
        id: mainLayout

        // 以左上角为缩放原点，放大后的画面正好铺满挂件的 implicitWidth/Height
        scale: uiScale
        transformOrigin: Item.TopLeft
        width: contentWrapper.width
        height: contentWrapper.height

        // 文字区。它同时也是描边的取样范围，四周的 margin 必须能装下描边和红条后的黑色笔刷背景
        Item {
            id: contentWrapper

            // 底部红条：右端固定在 mainRow 右端往左 23 处，宽度至少 bottomBarMinWidth，
            // 文字短于红条时只在红条范围内往左长，超过后红条随文字一起往左变长。
            // 247 = 默认内容"GP更新 / 3日"时的 mainRow 宽度 213 × 1.45 × 0.8
            readonly property real bottomBarMinWidth: 247
            readonly property real bottomBarWidth: Math.max(bottomBarMinWidth, mainRow.width)
            // 黑色笔刷背景左上角相对 mainRow 左上角的位置（背景比红条宽 40、高 15，再整体下移 5）
            readonly property real brushOriginX: mainRow.width - 23 - bottomBarWidth - 20
            readonly property real brushOriginY: mainRow.height / 2 + 45 + bottomBarHeight / 2 + 5 - (bottomBarHeight + 15) / 2
            // 四边边距 = 内容超出 mainRow 布局框的量再加 4px 余量，让挂件框刚好贴合内容。
            // 左、右、下由黑色笔刷背景的实际外框决定，右边和下边另有文字描边的实测下限（8 / 30）。
            // 上边内容实际从 mainRow 顶部往下约 18px 才开始，所以上边距为负。
            readonly property real marginLeft: Math.max(0, -(brushOriginX + brushBounds.minX)) + 4
            readonly property real marginRight: Math.max(8, brushOriginX + brushBounds.maxX - mainRow.width + 4)
            readonly property real marginTop: -24
            readonly property real marginBottom: Math.max(30, brushOriginY + brushBounds.maxY - mainRow.height + 4)

            z: -1
            width: mainRow.width + marginLeft + marginRight
            height: mainRow.height + marginTop + marginBottom

            // 红条上的黑色垫块，被红条盖住看不见。让描边的闭运算把红条也算进去，
            // 填上"还剩"描边底边和红条上沿之间的小缝。只从"还剩"左端铺到红条右端：
            // 铺满整条红条会把"GP"左下的圆弧描边也拉成一面直墙连到红条。
            // 四边各内缩描边宽度（6 纹理像素 = 逻辑 3px），膨胀后刚好到红条边缘，不会在红条外多出黑边。
            Rectangle {
                readonly property real inset: outline.outlineRadius / uiScale
                // "还剩"外壳右端在 eventGroup 右端往右 18 处
                readonly property real remainLeft: mainRow.x + eventGroup.width + 18 - remainLabel.implicitWidth * textScaleX

                x: Math.max(bottomRect.x, remainLeft) + inset
                y: bottomRect.y + inset
                width: bottomRect.x + bottomRect.width - inset - x
                height: bottomRect.height - inset * 2
                color: "black"
                z: -10
            }

            // 一行内容：[距离 + 主标题 + 还剩] [间隔] [天数] [间隔] [日]
            Row {
                id: mainRow

                x: contentWrapper.marginLeft
                y: contentWrapper.marginTop
                spacing: -5

                // 主标题组：左上角"距离"、每两字一组的主标题、右下角"还剩"
                Item {
                    id: eventGroup

                    width: eventTextRow.width + 10
                    height: 85

                    // "距离"
                    // 旋转放在外壳上、横向压缩放在里面的 Text 上：两者写在同一个 Item 上时
                    // Qt 会先旋转再水平压缩，字形被错切成斜体。其他压缩过的文字也都按这个结构写。
                    Item {
                        width: distanceLabel.implicitWidth * textScaleX
                        height: distanceLabel.implicitHeight
                        rotation: -17
                        anchors.bottom: eventTextRow.top
                        anchors.bottomMargin: -12
                        anchors.left: eventTextRow.left
                        anchors.leftMargin: -13

                        Text {
                            id: distanceLabel

                            text: qsTr("距离")
                            font.family: customFont.name
                            font.pixelSize: 14
                            font.bold: true
                            color: "#ff0000"

                            transform: Scale {
                                xScale: textScaleX
                            }

                        }

                    }

                    Row {
                        id: eventTextRow

                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

                        Repeater {
                            model: getSplitText(eventText)

                            // 每组宽度按压缩后的字宽算，组与组之间不留空也不重叠
                            delegate: Item {
                                width: tNode.implicitWidth * textScaleX
                                height: tNode.implicitHeight
                                rotation: eventTextRotation

                                // 垫在字下半部分的黑色色块，比字窄 15、整体下移 20
                                Rectangle {
                                    color: "black"
                                    antialiasing: true
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

                                    transform: Scale {
                                        origin.x: tNode.width / 2
                                        xScale: textScaleX
                                    }

                                }

                            }

                        }

                    }

                    // "还剩"
                    Item {
                        width: remainLabel.implicitWidth * textScaleX
                        height: remainLabel.implicitHeight
                        rotation: -17
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -18
                        anchors.bottomMargin: -2

                        Text {
                            id: remainLabel

                            text: qsTr("还剩")
                            font.family: customFont.name
                            font.pixelSize: 14
                            font.bold: true
                            color: "#ff0000"

                            transform: Scale {
                                xScale: textScaleX
                            }

                        }

                    }

                }

                // 间隔
                Item {
                    width: 30
                    height: 1
                }

                // 天数：每位数字一个红底块，在 -17° 基础上再随机旋转 ±2°
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

                            width: 36 * textScaleX
                            height: 49
                            color: "#ff0000"
                            antialiasing: true
                            rotation: -17 + randomRot

                            Text {
                                id: digitText

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -1
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: daysRow.daysString[index]
                                font.family: customFont.name
                                font.pixelSize: 44
                                font.bold: true
                                color: "black"
                                // 字体只有一个粗体字重，用同色 1px 描边再加粗一档（小字上这样会糊，只用于数字）
                                style: Text.Outline
                                styleColor: "black"

                                transform: Scale {
                                    origin.x: digitText.width / 2
                                    xScale: textScaleX
                                }

                            }

                        }

                    }

                }

                // 间隔
                Item {
                    width: 15
                    height: 1
                }

                // "日"
                Item {
                    width: dayLabel.implicitWidth * textScaleX
                    height: dayLabel.implicitHeight
                    rotation: -18
                    anchors.bottom: parent.bottom

                    Text {
                        id: dayLabel

                        text: qsTr("日")
                        font.family: customFont.name
                        font.pixelSize: 18
                        font.bold: true
                        color: "#ff0000"

                        transform: Scale {
                            xScale: textScaleX
                        }

                    }

                }

            }

        }

        // ===== 文字黑色描边 =====
        // 把 contentWrapper 截成纹理，用 shader 把所有不透明像素往外扩，生成一整块黑色描边垫在文字下面。
        // 采用闭运算：先膨胀 outlineRadius + holeFill，再腐蚀 holeFill。
        // 外轮廓的描边宽度仍是 outlineRadius，字内宽度小于约 2 × holeFill 的空心会被填黑。
        // 单位都是 2x 纹理像素：6 = 逻辑 3px = 屏幕 6px。两个 shader 的 ITERATION_LIMIT 必须不小于各自半径。
        Item {
            id: outline

            readonly property real outlineRadius: 6
            readonly property real holeFill: 10
            // 膨胀核是方形并随文字一起旋转，描边拐角才会和斜着的字块平行
            readonly property real angle: -17 * Math.PI / 180
            // 中间膨胀结果会比最终描边多伸出 holeFill，纹理四周按逻辑像素留出这部分余量，避免被 contentWrapper 边界截断
            readonly property real pad: Math.ceil((outlineRadius + holeFill) / uiScale) + 2
            readonly property size textureSize: Qt.size(width * uiScale, height * uiScale)
            readonly property point delta: Qt.point(1 / textureSize.width, 1 / textureSize.height)

            x: -pad
            y: -pad
            width: contentWrapper.width + pad * 2
            height: contentWrapper.height + pad * 2
            z: -3

            // 第 0 步：截取文字区（含四周 pad 的透明余量），按 2 倍分辨率生成纹理，和屏幕像素一一对应
            ShaderEffectSource {
                id: effectSource

                sourceItem: contentWrapper
                sourceRect: Qt.rect(-outline.pad, -outline.pad, outline.width, outline.height)
                visible: false
                textureSize: outline.textureSize
            }

            // 第 1 步：膨胀。结果只作为中间纹理，不直接显示（由 dilateSource 的 hideSource 隐藏）
            ShaderEffect {
                id: dilatePass

                property variant source: effectSource
                property point delta: outline.delta
                property real radius: outline.outlineRadius + outline.holeFill
                property real angle: outline.angle

                anchors.fill: parent
                fragmentShader: Qt.resolvedUrl("../Shaders/Dilate.frag")
            }

            ShaderEffectSource {
                id: dilateSource

                sourceItem: dilatePass
                hideSource: true
                visible: false
                textureSize: outline.textureSize
            }

            // 第 2 步：腐蚀回去，得到最终显示的描边
            ShaderEffect {
                property variant source: dilateSource
                property point delta: outline.delta
                property real radius: outline.holeFill
                property real angle: outline.angle

                anchors.fill: parent
                fragmentShader: Qt.resolvedUrl("../Shaders/Erode.frag")
            }

        }

        // ===== 底部红条（todo 信息）=====
        Rectangle {
            id: bottomRect

            width: contentWrapper.bottomBarWidth
            height: bottomBarHeight
            color: "#ff0000"
            // 顶边在 mainRow 垂直中心下方 45；右端在 mainRow 右端往左 23，向左延伸
            x: mainRow.x + mainRow.width - 23 - width
            y: mainRow.y + mainRow.height / 2 + 45
            z: 0

            // 左端的 > 形切口：用和背景同色的黑色三角盖住红条左边缘
            Canvas {
                id: leftMask

                width: 15
                height: parent.height
                anchors.left: parent.left
                anchors.top: parent.top
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = "black";
                    ctx.beginPath();
                    var indent = 14; // 切口深度
                    ctx.moveTo(0, 0);
                    ctx.lineTo(indent, height * 2 / 3); // 切口尖点，位于上 2/3 处
                    ctx.lineTo(0, height);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            // 字体只有一个粗体字重，把同一行字在上下左右各偏移 0.3px 叠画来加粗
            Repeater {
                model: [Qt.point(0, 0), Qt.point(-0.3, 0), Qt.point(0.3, 0), Qt.point(0, -0.3), Qt.point(0, 0.3)]

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 4 + modelData.x
                    anchors.verticalCenterOffset: modelData.y
                    text: bottomText
                    font.family: gothicFont.name
                    font.pixelSize: 16
                    font.bold: true
                    color: "black"
                }

            }

        }

        // ===== 红条后的黑色笔刷背景 =====
        // 比红条宽 40、高 15，相对红条居中再下移 5；形状见 brushStrokes()
        Rectangle {
            id: bottomRectBackground

            width: bottomRect.width + 40
            height: bottomRect.height + 15
            color: "transparent"
            anchors.verticalCenter: bottomRect.verticalCenter
            anchors.verticalCenterOffset: 5
            anchors.horizontalCenter: bottomRect.horizontalCenter
            z: -5

            Canvas {
                readonly property var bounds: brushBounds
                // 末端斜切后笔触会略微超出背景矩形，画布四周留出刚好够用的余量
                readonly property real pad: Math.ceil(Math.max(0, -bounds.minX, -bounds.minY, bounds.maxX - parent.width, bounds.maxY - parent.height)) + 2

                x: -pad
                y: -pad
                // Canvas 按自身像素生成纹理，被 mainLayout 放大后会发虚，所以按 uiScale 倍尺寸绘制再缩回去
                width: (parent.width + pad * 2) * uiScale
                height: (parent.height + pad * 2) * uiScale
                scale: 1 / uiScale
                transformOrigin: Item.TopLeft
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onBoundsChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.scale(uiScale, uiScale);
                    ctx.translate(pad, pad);
                    ctx.fillStyle = "#000000";
                    var strokes = brushStrokes(bottomRectBackground.width, bottomRectBackground.height);
                    for (var i = 0; i < strokes.length; i++) {
                        var pts = strokes[i];
                        ctx.beginPath();
                        ctx.moveTo(pts[0].x, pts[0].y);
                        for (var j = 1; j < pts.length; j++) ctx.lineTo(pts[j].x, pts[j].y)
                        ctx.closePath();
                        ctx.fill();
                    }
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
