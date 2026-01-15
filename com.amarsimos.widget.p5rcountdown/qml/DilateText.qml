import QtQuick 2.12

Item {
    id: root

    // --- 兼容旧版 Text 属性 ---
    property string text: ""
    property font font
    property color color: "white"
    
    // --- 背景矩形属性 ---
    property color backgroundColor: "transparent"
    property real backgroundWidth: 0
    property real backgroundHeight: 0
    property real backgroundXOffset: 0
    property real backgroundYOffset: 0
    
    // --- 布局属性 ---
    property int padding: 20 

    // 默认属性：允许作为容器包裹其他组件（如 Row）
    default property alias content: sourceContainer.data

    // 自动计算大小：包含内容边界和 Padding
    implicitWidth: sourceContainer.width
    implicitHeight: sourceContainer.height

    // 1. 源容器 (内容层)
    // 保持水平且带 Padding，确保纹理不被裁切。
    // 我们不隐藏它 (hideSource: false)，让它直接作为前景显示。
    Item {
        id: sourceContainer
        width: Math.max(contentGroup.childrenRect.width, root.backgroundWidth) + root.padding * 2
        height: Math.max(contentGroup.childrenRect.height, root.backgroundHeight) + root.padding * 2
        
        // 背景矩形
        Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.backgroundXOffset
            anchors.verticalCenterOffset: root.backgroundYOffset
            width: root.backgroundWidth > 0 ? root.backgroundWidth : innerText.implicitWidth
            height: root.backgroundHeight > 0 ? root.backgroundHeight : innerText.implicitHeight
            color: root.backgroundColor
            visible: root.backgroundColor != "transparent"
            z: -1
        }

        // 内部文本 (仅在设置了 text 属性时显示)
        Text {
            id: innerText
            anchors.centerIn: parent
            text: root.text
            font: root.font
            color: root.color
            visible: text !== ""
        }

        // 用户通过 default property 放入的内容 (例如 Row)
        Item {
            id: contentGroup
            anchors.centerIn: parent
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    // 2. 描边层 (最底层)
    ShaderEffect {
        id: outlineEffect
        anchors.centerIn: sourceContainer
        width: sourceContainer.width
        height: sourceContainer.height
        z: -10 // 确保在原始内容之下

        property variant source: ShaderEffectSource {
            sourceItem: sourceContainer
            hideSource: false // 原始内容保持可见，作为前景
            mipmap: true
        }
        
        property point delta: Qt.point(1.0/width, 1.0/height)
        property real qt_Opacity: root.opacity

        fragmentShader: Qt.resolvedUrl("../Shaders/Dilate.frag")
    }
}