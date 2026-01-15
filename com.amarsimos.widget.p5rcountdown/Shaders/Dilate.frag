#ifdef GL_ES
precision mediump float;
#endif

varying mediump vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform lowp sampler2D source;
uniform highp vec2 delta;
uniform highp float radius; // 由 QML 传入，实际生效的描边半径

#define ITERATION_LIMIT 12.0 // 采样循环上限，修改此处可调整最大支持的描边宽度

void main() {
    lowp float alpha = 0.0;

    // 使用方形采样，保持 P5 硬朗风格特征。
    for (float x = -ITERATION_LIMIT; x <= ITERATION_LIMIT; x += 1.0) {
        if (abs(x) > radius) continue;

        for (float y = -ITERATION_LIMIT; y <= ITERATION_LIMIT; y += 1.0) {
            if (abs(y) > radius) continue;

            vec2 coord = qt_TexCoord0 + vec2(x, y) * delta;
            alpha = max(alpha, texture2D(source, coord).a);
        }
    }

    // 使用硬阈值处理 Alpha，彻底消除羽化感，保持边缘绝对锐利。
    // 只要 alpha 超过一定数值，就直接输出不透明的黑色。
    float finalAlpha = alpha > 0.3 ? 1.0 : 0.0;
    gl_FragColor = vec4(0.0, 0.0, 0.0, finalAlpha) * qt_Opacity;
}
