$input vTexCoord0, v_viewRay

// HARFANG(R) Copyright (C) 2022 Emmanuel Julien, NWNC HARFANG. Released under GPL/LGPL/Commercial Licence, see licence.txt for details.
#include <forward_pipeline.sh>

SAMPLER2D(u_color, 0);
SAMPLER2D(u_attr0, 1);
SAMPLER2D(u_attr1, 2);
SAMPLER2D(u_noise, 3);
SAMPLERCUBE(u_probe, 4);
SAMPLER2D(u_depthTex, 5); // input: minimum depth pyramid

#define sample_count uAAAParams[1].z

#define uv_ratio vec2_splat(uAAAParams[0].x)

#include <aaa_utils.sh>
#include <hiz_trace.sh>

void main() {
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 jitter = texture2D(u_noise, mod(gl_FragCoord.xy, vec2(64, 64)) / vec2(64, 64));

	// sample normal/depth
	vec2 uv = GetAttributeTexCoord(vTexCoord0, vec2(textureSize(u_attr0, 0).xy));
	vec4 attr0 = texture2D(u_attr0, uv);

	vec3 n = normalize(attr0.xyz);
	if (isNan(n.x) || isNan(n.y) || isNan(n.z))
		n = vec3(0, 1, 0);

	// compute ray origin & direction
	vec3 ray_o = GetRayOrigin(uMainProjection, v_viewRay, attr0.w);

	// spread
	vec3 right = normalize(cross(n, vec3(1, 0, 0)));
	vec3 up = cross(n, right);

	//
	const float z_min = 0.1;

	for (int i = 0; i < int(sample_count); ++i) {
		float r = (float(i) + jitter.y) / sample_count;
		float spread = r * 3.141592 * 0.5 * 0.9;
		float cos_spread = cos(spread), sin_spread = sin(spread);

		for (int j = 0; j < int(sample_count); ++j) {
			float angle = (float(j) + jitter.w) / sample_count * 2.0 * 3.141592;
			float cos_angle = cos(angle), sin_angle = sin(angle);
			vec3 ray_d_spread = (right * cos_angle + up * sin_angle) * sin_spread + n * cos_spread;

			vec2 hit_pixel;
			vec3 hit_point;
			float k = TraceScreenRay(ray_o - v_viewRay * 0.05, ray_d_spread, uMainProjection, z_min, 192, hit_pixel, hit_point);

			if (k > 0.0) {
				// use hit pixel velocity to compensate the fact that we are sampling the previous frame
				uv = hit_pixel * uv_ratio / uResolution.xy;
				vec2 vel = GetVelocityVector(uv);

				attr0 = texelFetch(u_attr0, ivec2(hit_pixel), 0);

				float log_depth = ComputeRayLogDepth(uMainProjection, hit_point);

				if ((dot(attr0.xyz, ray_d_spread) < 0.0)) { // ray facing the collision
					vec3 irradiance = texture2D(u_color, uv - vel * uv_ratio).xyz;
					color += vec4(irradiance, 1.0);
				} else {
					color += vec4(0.0, 0.0, 0.0, 0.0); // backface hit
				}
			} else {
				vec3 world_ray_d_spread = mul(uMainInvView, vec4(ray_d_spread, 0.0)).xyz;
				vec3 world_ray_o = mul(uMainInvView, vec4(ray_o, 1.0)).xyz;
				color += vec4(textureCubeLod(u_probe, ReprojectProbe(world_ray_o, world_ray_d_spread), 0).xyz, 0.);
			}
		}
	}

	color /= sample_count * sample_count;
	color = (saturate(color) / 32.0) * 32.0;

	gl_FragColor = color;
}
