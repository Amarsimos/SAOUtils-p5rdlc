#ifdef GL_ES
precision mediump float;
#endif

varying mediump vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform lowp sampler2D source;
uniform highp vec2 delta;
uniform highp float radius; // 由 QML 传入，实际生效的描边半径
uniform highp float angle;  // 膨胀核旋转角(弧度)，应与文字旋转角一致

#define ITERATION_LIMIT 16.0 // 采样循环上限，必须 >= radius，否则 radius 超出部分不生效

void main() {
    lowp float alpha = 0.0;
    highp float c = cos(angle);
    highp float s = sin(angle);

    // 方形核随文字一起旋转：轴对齐的方形核会在旋转字块的拐角处补出水平/垂直的平台，
    // 看起来像描边被方框截断；旋转后拐角与字块平行，同时保留 P5 硬朗的方角风格。
    for (float x = -ITERATION_LIMIT; x <= ITERATION_LIMIT; x += 1.0) {
        if (abs(x) > radius) continue;

        for (float y = -ITERATION_LIMIT; y <= ITERATION_LIMIT; y += 1.0) {
            if (abs(y) > radius) continue;

            vec2 offset = vec2(x * c - y * s, x * s + y * c);
            alpha = max(alpha, texture2D(source, qt_TexCoord0 + offset * delta).a);
        }
    }

    // 源图边缘本身带约 1px 的抗锯齿过渡，取最大值后外缘仍保留这段过渡；
    // 用以 0.3 为中心的窄 smoothstep 代替硬阈值，边缘位置不变、依然锐利，但斜边不再是阶梯。
    float finalAlpha = smoothstep(0.1, 0.5, alpha);
    gl_FragColor = vec4(0.0, 0.0, 0.0, finalAlpha) * qt_Opacity;
}
