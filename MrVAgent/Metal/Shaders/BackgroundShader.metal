#include <metal_stdlib>
using namespace metal;

// MARK: - Structs

struct BackgroundUniforms {
    float time;
    float2 resolution;
    float2 cursorPosition;
    float3 baseColor;
    float breathingIntensity;
    float noiseScale;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// MARK: - Utility Functions

/// Simple hash function for pseudo-random numbers
float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

/// 2D Perlin-like noise
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);

    // Four corners
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    // Bilinear interpolation
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/// Fractal Brownian Motion (multiple octaves of noise)
float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// MARK: - Vertex Shader

vertex VertexOut backgroundVertexShader(uint vertexID [[vertex_id]]) {
    // Fullscreen quad using triangle strip
    // Vertices: (-1,1), (-1,-1), (1,1), (1,-1)
    float2 positions[4] = {
        float2(-1.0,  1.0),  // Top-left
        float2(-1.0, -1.0),  // Bottom-left
        float2( 1.0,  1.0),  // Top-right
        float2( 1.0, -1.0)   // Bottom-right
    };

    float2 texCoords[4] = {
        float2(0.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 0.0),
        float2(1.0, 1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];

    return out;
}

// MARK: - Fragment Shader

fragment float4 backgroundFragmentShader(
    VertexOut in [[stage_in]],
    constant BackgroundUniforms &uniforms [[buffer(0)]]
) {
    // Normalized coordinates (0-1)
    float2 uv = in.texCoord;

    // Aspect ratio correction
    float2 coord = uv * uniforms.resolution / uniforms.resolution.y;

    // Breathing effect (slow sine wave)
    float breathingPhase = sin(uniforms.time * 0.5) * 0.5 + 0.5;
    float breathing = mix(1.0, 1.0 + uniforms.breathingIntensity, breathingPhase);

    // Generate base noise pattern
    float2 noiseCoord = coord * uniforms.noiseScale * breathing;
    noiseCoord += uniforms.time * 0.02; // Slow movement

    float noiseValue = fbm(noiseCoord);

    // Cursor influence (subtle ripple)
    float2 cursorCoord = uniforms.cursorPosition;
    cursorCoord.y = 1.0 - cursorCoord.y; // Flip Y coordinate
    float2 toCenter = coord - (cursorCoord * uniforms.resolution / uniforms.resolution.y);
    float distanceToCenter = length(toCenter);

    // Ripple effect
    float ripple = sin(distanceToCenter * 10.0 - uniforms.time * 2.0) * 0.5 + 0.5;
    ripple *= exp(-distanceToCenter * 2.0); // Fade with distance
    ripple *= 0.2; // Subtle intensity

    // Combine effects
    float finalNoise = noiseValue + ripple;

    // Color gradient based on time
    float timePhase = uniforms.time * 0.1;
    float3 colorShift = float3(
        sin(timePhase) * 0.02,
        sin(timePhase * 1.3) * 0.02,
        cos(timePhase * 0.7) * 0.03
    );

    // Final color
    float3 color = uniforms.baseColor + colorShift;
    color += finalNoise * 0.15; // Add noise influence
    color = clamp(color, 0.0, 1.0);

    // Vignette effect (darker at edges)
    float2 vignetteCoord = uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(vignetteCoord, vignetteCoord) * 0.3;
    color *= vignette;

    return float4(color, 1.0);
}
