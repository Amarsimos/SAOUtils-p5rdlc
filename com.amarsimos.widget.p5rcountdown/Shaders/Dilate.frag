#ifdef GL_ES
precision mediump float;
#endif

varying mediump vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform lowp sampler2D source;
uniform highp vec2 delta;

void main() {
    lowp float alpha = 0.0;

    // 解决毛边问题：恢复步长为 1.0，保证边缘平滑连续。
    // 半径设为 4.0，提供适中的描边厚度。
    // 使用圆形采样 (x*x + y*y <= r*r)，确保描边在所有方向厚度一致，更贴合字形。

    float radius = 8.0;
    float radiusSq = radius * radius;

    for (float x = -radius; x <= radius; x += 1.0) {
        for (float y = -radius; y <= radius; y += 1.0) {
            // 仅当采样点在圆内时才进行计算
            if ((x * x + y * y) <= (radiusSq + 0.5)) {
                vec2 coord = qt_TexCoord0 + vec2(x, y) * delta;
                alpha = max(alpha, texture2D(source, coord).a);
            }
        }
    }

    // 移除硬阈值判断，直接输出 Alpha 以保留平滑边缘
    gl_FragColor = vec4(0.0, 0.0, 0.0, alpha) * qt_Opacity;
}
