#include <metal_stdlib>
using namespace metal;

// MARK: - Particle Structure

struct Particle {
    float3 position;      // x, y, z
    float3 velocity;      // vx, vy, vz
    float4 color;         // r, g, b, a
    float size;           // particle size
    float life;           // 0.0 to 1.0 (1.0 = newborn, 0.0 = dead)
    float maxLife;        // maximum lifetime
    float rotation;       // rotation angle
};

// MARK: - Uniforms

struct ParticleUniforms {
    float time;
    float2 resolution;
    float deltaTime;
    float4x4 projectionMatrix;
};

// MARK: - Vertex Output

struct ParticleVertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
    float life;
};

// MARK: - Vertex Shader

vertex ParticleVertexOut particleVertexShader(
    uint vertexID [[vertex_id]],
    const device Particle* particles [[buffer(0)]],
    constant ParticleUniforms& uniforms [[buffer(1)]]
) {
    ParticleVertexOut out;

    Particle particle = particles[vertexID];

    // Convert particle position to NDC (Normalized Device Coordinates)
    float2 ndcPosition = float2(
        (particle.position.x / uniforms.resolution.x) * 2.0 - 1.0,
        1.0 - (particle.position.y / uniforms.resolution.y) * 2.0
    );

    out.position = float4(ndcPosition, particle.position.z, 1.0);

    // Fade alpha based on life
    float4 color = particle.color;
    color.a *= particle.life;  // Fade out as life decreases
    out.color = color;

    // Scale size based on life (subtle pulse)
    float lifePulse = 1.0 + sin(particle.life * 3.14159) * 0.2;
    out.pointSize = particle.size * lifePulse;

    out.life = particle.life;

    return out;
}

// MARK: - Fragment Shader

fragment float4 particleFragmentShader(
    ParticleVertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    // Create circular particles (not square)
    float2 center = pointCoord - float2(0.5);
    float distance = length(center);

    if (distance > 0.5) {
        discard_fragment();
    }

    // Soft edge falloff
    float alpha = 1.0 - smoothstep(0.3, 0.5, distance);

    // Apply life-based alpha
    float4 color = in.color;
    color.a *= alpha;

    // Add subtle glow for high-life particles
    if (in.life > 0.8) {
        float glow = (in.life - 0.8) * 5.0;  // 0 to 1
        color.rgb += color.rgb * glow * 0.3;
    }

    return color;
}

// MARK: - Compute Shader for Particle Updates

kernel void updateParticles(
    device Particle* particles [[buffer(0)]],
    constant ParticleUniforms& uniforms [[buffer(1)]],
    uint id [[thread_position_in_grid]]
) {
    Particle particle = particles[id];

    // Skip dead particles
    if (particle.life <= 0.0) {
        return;
    }

    // Update position based on velocity
    particle.position += particle.velocity * uniforms.deltaTime;

    // Update life (decay)
    particle.life -= uniforms.deltaTime / particle.maxLife;

    // Clamp life
    particle.life = max(particle.life, 0.0);

    // Apply gravity (subtle downward pull)
    particle.velocity.y += 20.0 * uniforms.deltaTime;

    // Apply friction/drag
    particle.velocity *= 0.98;

    // Update rotation
    particle.rotation += uniforms.deltaTime * 2.0;

    // Boundary check - wrap around screen
    if (particle.position.x < 0.0) {
        particle.position.x = uniforms.resolution.x;
    } else if (particle.position.x > uniforms.resolution.x) {
        particle.position.x = 0.0;
    }

    if (particle.position.y < 0.0) {
        particle.position.y = uniforms.resolution.y;
    } else if (particle.position.y > uniforms.resolution.y) {
        particle.position.y = 0.0;
    }

    // Write back
    particles[id] = particle;
}
