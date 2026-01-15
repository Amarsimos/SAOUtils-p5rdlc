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
    
    // --- 渲染属性 ---
    property int padding: 20 
    property real renderScale: 2.0 // 内部渲染缩放倍数，默认为 2.0 以获得高清边缘

    // 默认属性
    default property alias content: sourceContainer.data

    // 逻辑大小 (对外部布局可见的大小，保持原始尺寸)
    implicitWidth: (Math.max(contentGroup.childrenRect.width, root.backgroundWidth) + root.padding * 2) 
    implicitHeight: (Math.max(contentGroup.childrenRect.height, root.backgroundHeight) + root.padding * 2)

    // 1. 高清源容器 (不可见)
    // 实际尺寸 = 逻辑尺寸 * renderScale
    // 内部元素 (字体、矩形) 都要乘以 renderScale
    Item {
        id: sourceContainer
        width: root.implicitWidth * root.renderScale
        height: root.implicitHeight * root.renderScale
        visible: false

        // 背景矩形 (放大)
        Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.backgroundXOffset * root.renderScale
            anchors.verticalCenterOffset: root.backgroundYOffset * root.renderScale
            width: (root.backgroundWidth > 0 ? root.backgroundWidth : innerText.implicitWidth) * root.renderScale
            height: (root.backgroundHeight > 0 ? root.backgroundHeight : innerText.implicitHeight) * root.renderScale
            color: root.backgroundColor
            visible: root.backgroundColor != "transparent"
            z: -1
        }

        // 内部文本 (放大)
        Text {
            id: innerText
            anchors.centerIn: parent
            text: root.text
            font.family: root.font.family
            font.bold: root.font.bold
            font.pixelSize: root.font.pixelSize * root.renderScale // 关键：字体放大
            color: root.color
            visible: text !== ""
        }

        // 用户内容 (通过 scale 放大)
        Item {
            id: contentGroup
            anchors.centerIn: parent
            width: childrenRect.width * root.renderScale
            height: childrenRect.height * root.renderScale
            
            // 对子元素应用缩放
            transform: Scale {
                origin.x: contentGroup.width / 2
                origin.y: contentGroup.height / 2
                xScale: root.renderScale
                yScale: root.renderScale
            }
        }
    }

    // 2. 描边层 (最底层)
    ShaderEffect {
        id: outlineEffect
        anchors.centerIn: parent // 居中显示
        width: root.implicitWidth // 显示为逻辑大小
        height: root.implicitHeight
        z: -10 

        property variant source: ShaderEffectSource {
            sourceItem: sourceContainer
            hideSource: false // 关键：我们这里不隐藏，因为下面的 foregroundContainer 会用 Scale 缩放显示它
            // 等等，如果 sourceContainer 很大，我们不能直接显示它作为前景。
            // 我们需要单独处理前景。
            // 简单方案：ShaderEffectSource hideSource: true。
            // 前景单独用一个 ShaderEffect (PassThrough) 或者 Image 显示？
            // 或者再次实例化组件？不，太重。
            // 让 ShaderEffectSource 保持 hideSource: true。
            // 前景层我们用 Image (ShaderEffectSource 也可以作为 Image 源) 显示。
            
            hideSource: true 
            mipmap: true
        }
        
        // 传递给 Shader 的参数
        // 纹理现在是高清的，所以 delta 更小
        property point delta: Qt.point(1.0/sourceContainer.width, 1.0/sourceContainer.height)
        
        // 描边半径：为了保持视觉厚度一致，像素半径需要乘以 scale
        property real radius: 4.0 * root.renderScale 
        
        property real qt_Opacity: root.opacity

        fragmentShader: Qt.resolvedUrl("../Shaders/Dilate.frag")
    }
    
    // 3. 前景显示层
    // 直接显示 sourceContainer 的纹理，但缩放到逻辑大小
    ShaderEffect {
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
        z: 0
        
        property variant source: outlineEffect.source // 复用上面的纹理
        
        // 简单的透传 Shader (默认 ShaderEffect 行为就是透传纹理)
        // 但我们需要它保持透明度混合
    }
}
