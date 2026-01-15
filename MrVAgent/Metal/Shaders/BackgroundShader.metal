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
    float2 cursorVelocity;     // Speed and direction
    float2 cursorHistory[10];  // Last 10 cursor positions
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

    // Advanced cursor influence
    float2 cursorCoord = uniforms.cursorPosition;
    cursorCoord.y = 1.0 - cursorCoord.y; // Flip Y coordinate
    float2 toCursor = coord - (cursorCoord * uniforms.resolution / uniforms.resolution.y);
    float distanceToCursor = length(toCursor);

    // Multi-ripple from cursor history
    float ripple = 0.0;
    for (int i = 0; i < 10; i++) {
        float2 historyPos = uniforms.cursorHistory[i];
        historyPos.y = 1.0 - historyPos.y;
        float2 toHistory = coord - (historyPos * uniforms.resolution / uniforms.resolution.y);
        float dist = length(toHistory);

        // Age-based intensity (older = weaker)
        float age = float(i) / 10.0;
        float intensity = (1.0 - age) * 0.15;

        // Ripple wave
        float wave = sin(dist * 12.0 - uniforms.time * 3.0 - float(i) * 0.5) * 0.5 + 0.5;
        wave *= exp(-dist * 1.5);
        ripple += wave * intensity;
    }

    // Velocity-based directional distortion
    float speed = length(uniforms.cursorVelocity);
    float velocityEffect = 0.0;
    if (speed > 0.01) {
        float2 normalizedVel = normalize(uniforms.cursorVelocity);
        float directionInfluence = dot(normalize(toCursor), normalizedVel);
        velocityEffect = directionInfluence * speed * 0.3;
        velocityEffect *= exp(-distanceToCursor * 1.0);
    }

    // Speed-based color shift
    float3 speedColor = float3(0.0);
    if (speed > 0.05) {
        float speedIntensity = clamp(speed * 2.0, 0.0, 1.0);
        speedColor = float3(
            speedIntensity * 0.1,
            speedIntensity * 0.05,
            speedIntensity * 0.15
        );
    }

    // Combine effects
    float finalNoise = noiseValue + ripple + velocityEffect;

    // Color gradient based on time
    float timePhase = uniforms.time * 0.1;
    float3 colorShift = float3(
        sin(timePhase) * 0.02,
        sin(timePhase * 1.3) * 0.02,
        cos(timePhase * 0.7) * 0.03
    );

    // Final color
    float3 color = uniforms.baseColor + colorShift + speedColor;
    color += finalNoise * 0.15; // Add noise influence
    color = clamp(color, 0.0, 1.0);

    // Vignette effect (darker at edges)
    float2 vignetteCoord = uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(vignetteCoord, vignetteCoord) * 0.3;
    color *= vignette;

    return float4(color, 1.0);
}
