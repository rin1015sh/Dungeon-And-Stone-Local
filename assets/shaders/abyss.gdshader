shader_type canvas_item;
// 낭떠러지·구덩이(void 타일 — Abyss·VoidChunk): 세계 좌표로 칠한다(화면에 고정된 그림 없음).
//  땅/허공 경계 = 칸 지도(mask: r = 허공, g = 나무 발판)를 부드럽게 이은 값 + 잡음 → 칸 모양이 아닌 들쭉날쭉한 가장자리.
//  허공 칸은 늘 허공, 땅 칸은 가장자리만 jag만큼 깎인다(바닥 그림이 없는 곳에 땅이 생기지 않게). 나무 발판은 깎지 않는다.
//  허공 픽셀 = 위(북쪽)로 땅까지의 거리 d → d < cliff_h면 절벽 면 그림(cliff — 아래로 갈수록 어둠), 나무 발판 아래면 들보 면,
//  아니면 깊은 어둠(abyss + 느리게 흐르는 안개). 땅 픽셀은 가장자리 2px만 칠하고(테두리 빛) 나머지는 버린다.
//  솟은 외곽(mask b = rise — 균열 지도 바깥 둘레): 내려가는 대신 위로 솟는다 — 남쪽(아래)으로 땅까지의 거리 d < rise_h면
//  벽·절벽 면(rise_face — 위 = 꼭대기, 성가퀴 틈은 투명), 그 너머는 꼭대기 풍경(rise_top — 세계 좌표로 이어 붙임, 멀수록 어둡게).
//  꼭짓점 색 = 빛·안개(FloorView.vertex_mul) — 곱한다.
uniform sampler2D mask : filter_nearest;
// 칸 거리(Abyss.dist_texture × 15): r = 반대쪽까지 체비쇼프 · g = 위로 땅까지 · b = 아래로 땅까지 — 땅 찾기 걸음을 경계 칸 안에서만(균열 렉, CT73)
uniform sampler2D dist : filter_nearest;
uniform vec2 map_size = vec2(64.0, 64.0);
uniform float tile = 32.0;
uniform sampler2D cliff : filter_linear, repeat_enable;
uniform float cliff_w = 256.0;   // 절벽 그림 한 장이 덮는 가로 px(세계)
uniform float cliff_h = 64.0;    // 절벽 면 높이 px(세계)
uniform float jag = 0.32;        // 땅 가장자리를 깎는 깊이(칸 비율)
uniform float side_px = 9.0;     // 옆(동·서) 벽 면 폭 px
uniform vec4 abyss_color : source_color = vec4(0.02, 0.02, 0.025, 1.0);
uniform vec4 mist_color : source_color = vec4(0.07, 0.07, 0.08, 1.0);
uniform vec4 rim_color : source_color = vec4(0.6, 0.55, 0.5, 1.0);
uniform vec4 beam_color : source_color = vec4(0.3, 0.22, 0.14, 1.0);
uniform float beam_px = 9.0;     // 나무 발판 들보 면 높이 px
uniform float mist_speed = 0.02;
uniform float edge_fade = 2.5;   // 지도 끝에서 이 칸 수 안의 땅은 어둠으로 녹는다
uniform sampler2D rise_face : filter_linear, repeat_enable;
uniform sampler2D rise_top : filter_linear, repeat_enable;
uniform float rise_w = 256.0;    // 솟은 면 그림 한 장의 가로 px(세계)
uniform float rise_h = 96.0;     // 솟은 면 높이 px(세계)
uniform float rise_top_w = 256.0;  // 꼭대기 풍경 그림 한 장의 크기 px(세계)
uniform float rise_fog = 6.0;    // 꼭대기 풍경이 어둠에 묻히는 거리(칸)
uniform float rise_jag = 0.0;    // 솟은 외곽 쪽 땅 가장자리를 깎는 깊이(성벽은 0 = 곧게)
uniform vec4 rise_dark : source_color = vec4(0.05, 0.04, 0.04, 1.0);
uniform float rise_band = 22.0;  // 땅 남쪽 솟은 외곽의 꼭대기 가장자리 띠 px(세계)
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 cell_at(vec2 c) {
	ivec2 q = ivec2(clamp(c, vec2(0.0), map_size - 1.0));
	return texelFetch(mask, q, 0).rgb;
}

// 지도 밖 칸(가장자리 칸 값을 이어 쓴다)은 지도에서 떨어진 만큼 반대쪽·옆 거리를 늘린다(위·아래는 가장자리 그대로).
vec4 dist_at(vec2 c) {
	vec2 cc = clamp(c, vec2(0.0), map_size - 1.0);
	vec4 v = texelFetch(dist, ivec2(cc), 0) * 15.0;
	vec2 ofs = abs(c - cc);
	v.r += max(ofs.x, ofs.y);
	v.a += ofs.x;
	return v;
}

// 옆 땅까지 거리(칸)를 칸 가운데끼리 이은 값 — 꼭대기 풍경 안개가 칸 모양 계단으로 보이지 않게.
float side_far(vec2 p) {
	vec2 q = p - 0.5;
	vec2 i = floor(q);
	vec2 f = fract(q);
	return mix(mix(dist_at(i).a, dist_at(i + vec2(1.0, 0.0)).a, f.x), mix(dist_at(i + vec2(0.0, 1.0)).a, dist_at(i + vec2(1.0, 1.0)).a, f.x), f.y);
}

// 허공 정도(0 땅 ~ 1 허공)를 칸 가운데끼리 곧게 이은 값(경계에서 완만해야 잡음이 깊게 깎는다).
float field(vec2 p) {
	vec2 q = p - 0.5;
	vec2 i = floor(q);
	vec2 f = fract(q);
	float a = cell_at(i).r;
	float b = cell_at(i + vec2(1.0, 0.0)).r;
	float c = cell_at(i + vec2(0.0, 1.0)).r;
	float d = cell_at(i + vec2(1.0, 1.0)).r;
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 둘레 네 칸 중 솟은 외곽이 있는가(그쪽 땅 가장자리는 rise_jag로 깎는다).
bool near_rise(vec2 p) {
	vec2 i = floor(p - 0.5);
	return max(max(cell_at(i).b, cell_at(i + vec2(1.0, 0.0)).b), max(cell_at(i + vec2(0.0, 1.0)).b, cell_at(i + vec2(1.0, 1.0)).b)) > 0.5;
}

bool is_void(vec2 p) {
	vec3 own = cell_at(floor(p));
	if (own.r > 0.5) {
		return true;
	}
	if (own.g > 0.5 || dist_at(floor(p)).r > 1.5) {  // 나무 발판 · 둘레 여덟 칸에 허공이 없는 땅은 깎이지 않는다
		return false;
	}
	float n = smoothstep(0.2, 0.85, vnoise(p * 1.7) * 0.72 + vnoise(p * 4.1 + 17.0) * 0.28);  // 깎인 곳·남은 곳이 또렷하게(잔 톱니는 줄인다)
	return field(p) + (near_rise(p) ? rise_jag : jag) * n > 0.5;
}

bool is_rise(vec2 p) {
	return cell_at(floor(p)).b > 0.5;
}

bool is_wood(vec2 p) {
	return cell_at(floor(p)).g > 0.5;
}

// 깊은 어둠: 가로로 늘인 가는 안개 결이 천천히 흐른다. below = 절벽 윗선에서 내려온 거리(칸) — 멀수록 어둡다.
vec3 deep(vec2 w, float below) {
	vec2 p = w / tile;
	vec2 q = vec2(p.x * 0.45, p.y * 1.3);
	float m = vnoise(q + vec2(TIME * mist_speed, 0.0)) * 0.55 + vnoise(q * 2.7 - vec2(TIME * mist_speed * 1.6, 0.0)) * 0.3
		+ vnoise(p * 5.0) * 0.15;
	float haze = smoothstep(0.45, 0.95, m) * (1.0 - smoothstep(1.0, 6.0, below) * 0.75);
	return mix(abyss_color.rgb, mist_color.rgb, haze);
}

// 솟은 외곽 한 픽셀: 아래(남쪽)로 땅까지 d → 면, 아니면 꼭대기 풍경(땅에서 멀수록 어둡게).
vec3 rise_color(vec2 p, float px, vec2 w) {
	vec4 dd = dist_at(floor(p));
	float fy = fract(p.y);
	float step_px = 4.0;
	float d = -1.0;
	float d0 = (dd.b - fy) * tile;  // 아래 가장 가까운 땅 칸 윗선까지(px) — 땅 경계는 그 칸 안에만 있다
	int n = d0 <= rise_h && dd.b < 14.5 ? int(tile * 1.5 / step_px) + 2 : 0;
	float lo0 = max(0.0, d0 - 1.0);
	for (int k = 0; k <= 64; k++) {
		if (k >= n) {
			break;
		}
		float at = lo0 + float(k) * step_px;
		if (at > rise_h) {
			break;
		}
		if (!is_void(p + vec2(0.0, at * px))) {
			float lo = max(0.0, at - step_px);
			float hi = at;
			for (int j = 0; j < 2; j++) {
				float mid = (lo + hi) * 0.5;
				if (is_void(p + vec2(0.0, mid * px))) {
					lo = mid;
				} else {
					hi = mid;
				}
			}
			d = hi;
			break;
		}
	}
	if (d >= 0.0) {
		vec4 face = texture(rise_face, vec2(w.x / rise_w, 1.0 - d / rise_h));
		if (face.a > 0.5) {
			return face.rgb;
		}
	}
	// 꼭대기 풍경: 땅(위·아래·옆)까지의 거리로 어둡게(칸 거리 그림으로 — 예전엔 네 방향을 걸어 쟀다)
	float far = clamp(min(min(dd.g - 1.0 + fy, dd.b - fy - rise_h / tile), side_far(p) - 0.5), 0.0, rise_fog);
	for (int s = 1; s <= 3; s++) {  // 옆(동·서) 면: 땅 옆에서 비스듬히 보이는 좁은 벽(옆 칸에 땅이 있을 때만)
		if (dd.r > 1.5) {
			break;
		}
		float o = side_px * float(s) / 3.0;
		if (!is_void(p - vec2(o * px, 0.0)) || !is_void(p + vec2(o * px, 0.0))) {
			vec4 sf = texture(rise_face, vec2(w.y / rise_w + 0.31, 0.55));
			return sf.rgb * (0.5 + 0.12 * float(s));
		}
	}
	// 땅 남쪽에 솟은 외곽: 면은 보이지 않고 꼭대기 가장자리(성가퀴·눈 처마)를 위에서 본다 — 면 그림 윗부분을 rise_band px에 눌러 담는다
	for (int k = 1; k <= 8; k++) {
		float u = float(k) * rise_band / 8.0;
		if (dd.g > 1.5 || u > fy * tile + rise_band) {  // 바로 위 칸이 땅일 때만
			break;
		}
		if (!is_void(p - vec2(0.0, u * px))) {
			vec4 lip = texture(rise_face, vec2(w.x / rise_w, u / rise_band * 0.22));
			if (lip.a > 0.5) {
				return lip.rgb * (k <= 1 ? 0.45 : 0.9);
			}
			break;
		}
	}
	vec3 top = texture(rise_top, w / rise_top_w).rgb * 0.8;
	return mix(top, rise_dark.rgb, smoothstep(0.3, rise_fog, far) * 0.92);
}

void fragment() {
	vec2 p = world / tile;
	float px = 1.0 / tile;
	vec2 edge = min(p, map_size - p);
	float border = min(edge.x, edge.y);
	if (!is_void(p) && border < edge_fade) {
		// 지도 끝으로 나가는 땅(입구·출구 길): 깊은 어둠으로 녹는다(지도 밖은 다 덮는다)
		float k = clamp(1.0 - border / edge_fade, 0.0, 1.0);
		COLOR = vec4(deep(world, 6.0) * COLOR.rgb, k * k * (3.0 - 2.0 * k));
	} else if (!is_void(p)) {
		// 땅: 허공에 닿는 가장자리만 — 아래(절벽 위 턱)는 밝게 부스러진 테두리, 옆·위는 그늘
		if (is_void(p + vec2(0.0, 2.0 * px)) && !is_rise(p + vec2(0.0, 2.0 * px))) {
			COLOR = vec4(rim_color.rgb * COLOR.rgb, 0.55);
		} else if (is_void(p + vec2(1.6 * px, 0.0)) || is_void(p - vec2(1.6 * px, 0.0)) || is_void(p - vec2(0.0, 1.6 * px))) {
			COLOR = vec4(vec3(0.0), 0.45);
		} else {
			discard;
		}
	} else if (is_rise(p)) {
		COLOR = vec4(rise_color(p, px, world) * COLOR.rgb, 1.0);
	} else {
		vec4 dd = dist_at(floor(p));
		float step_px = 3.0;
		float d = -1.0;
		bool wood = false;
		float d0 = (fract(p.y) + dd.g - 1.0) * tile;  // 위 가장 가까운 땅 칸 아랫선까지(px) — 땅 경계는 그 칸 안에만 있다
		int n = d0 <= cliff_h && dd.g < 14.5 ? int(tile * 1.5 / step_px) + 2 : 0;
		float lo0 = max(0.0, d0 - 1.0);
		for (int k = 0; k <= 64; k++) {
			if (k >= n) {
				break;
			}
			float at = lo0 + float(k) * step_px;
			if (at > cliff_h) {
				break;
			}
			vec2 q = p - vec2(0.0, at * px);
			if (!is_void(q)) {
				// 두 번 반으로 나눠 경계를 다듬는다
				float lo = max(0.0, at - step_px);
				float hi = at;
				for (int j = 0; j < 2; j++) {
					float mid = (lo + hi) * 0.5;
					if (is_void(p - vec2(0.0, mid * px))) {
						lo = mid;
					} else {
						hi = mid;
					}
				}
				d = hi;
				wood = is_wood(p - vec2(0.0, hi * px));
				break;
			}
		}
		float below = d >= 0.0 ? d / tile : cliff_h / tile;
		if (d < 0.0) {  // 절벽 면 아래: 위 땅까지 깊이(칸 거리 그림 — 예전엔 성큼성큼 걸어 쟀다)
			below = clamp(d0 / tile, cliff_h / tile, cliff_h / tile + 6.0);
		}
		vec3 col = deep(world, below);
		if (d >= 0.0 && wood) {
			if (d < beam_px) {
				float grain = vnoise(vec2(world.x * 0.08, world.y * 0.9)) * 0.25;
				col = beam_color.rgb * (1.0 - d / beam_px * 0.45 - grain);
				if (d < 1.2 || d > beam_px - 1.5) {
					col *= 0.35;
				}
			} else {
				col *= 0.55;  // 발판 밑 그늘
			}
		} else if (d >= 0.0) {
			vec2 uv = vec2(world.x / cliff_w, d / cliff_h);
			vec3 face = texture(cliff, uv).rgb;
			col = mix(face, col, smoothstep(0.82, 1.0, uv.y));
			if (d < 1.4) {
				col *= 0.4;  // 절벽 윗선(잉크)
			}
		} else {
			// 옆 벽: 동·서 가까이에 땅이 있으면 비스듬히 보이는 좁은 벽 면
			float sl = 0.0;
			for (int s = 1; s <= 3; s++) {
				if (dd.r > 1.5) {  // 옆 칸에 땅이 없으면 옆 벽도 없다
					break;
				}
				float o = side_px * float(s) / 3.0;
				if (!is_void(p - vec2(o * px, 0.0)) || !is_void(p + vec2(o * px, 0.0))) {
					sl = 1.0 - float(s - 1) / 3.0;
					break;
				}
			}
			if (sl > 0.0) {
				vec3 face = texture(cliff, vec2(world.y / cliff_w + 0.37, 0.35)).rgb * 0.55;
				col = mix(col, face, sl * 0.85);
			}
		}
		COLOR = vec4(col * COLOR.rgb, 1.0);
	}
}
