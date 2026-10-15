#ifdef GL_ES
precision mediump float;
#endif

varying mediump vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform lowp sampler2D source;
uniform highp vec2 delta;
uniform highp float radius; // 腐蚀半径（纹理像素）
uniform highp float angle;  // 腐蚀核旋转角(弧度)，与 Dilate.frag 保持一致

#define ITERATION_LIMIT 16.0 // 采样循环上限，必须 >= radius

// 与 Dilate.frag 对称：在旋转方形邻域内取最小 alpha。
// 先按更大半径膨胀再按差值腐蚀（闭运算），外轮廓宽度不变，字内的空心被填满。
void main() {
    lowp float alpha = 1.0;
    highp float c = cos(angle);
    highp float s = sin(angle);

    for (float x = -ITERATION_LIMIT; x <= ITERATION_LIMIT; x += 1.0) {
        if (abs(x) > radius) continue;

        for (float y = -ITERATION_LIMIT; y <= ITERATION_LIMIT; y += 1.0) {
            if (abs(y) > radius) continue;

            vec2 offset = vec2(x * c - y * s, x * s + y * c);
            alpha = min(alpha, texture2D(source, qt_TexCoord0 + offset * delta).a);
        }
    }

    float finalAlpha = smoothstep(0.3, 0.7, alpha);
    gl_FragColor = vec4(0.0, 0.0, 0.0, finalAlpha) * qt_Opacity;
}
