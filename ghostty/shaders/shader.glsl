// Fighting game: every cursor move is a hit, with sparks, shake, speed lines
// and impact frames. A HUD at the top shows two health bars and a round timer.
//
//   Left bar  (P1): rows left below the cursor. Low = output is near the bottom.
//   Right bar (P2): columns left on the line. Low = the line is about to wrap.
//   Timer:          seconds since the cursor last moved (max 99).
//
// Hits: typing = light, new line = medium, big jump (command output, clear, Vim jump) = heavy.
// Made for dark themes. Needs: custom-shader-animation = true
// WARNING: IMPACT_FLASH makes a very short black/white flash on heavy hits. Set it to 0.0 if flashes bother you.

// Hits
const float HEAVY_CELLS  = 10.0; // jump this many columns on one row = heavy
const float HEAVY_ROWS   = 3.0;  // jump more than this many rows = heavy
const float JAB_EFFECTS  = 1.0;  // 0 = no effects for normal typing
const float SHAKE        = 1.0;
const float SPARK_SIZE   = 1.0;
const float SPARK_RAYS   = 8.0;
const float SPEED_LINES  = 1.0;
const float IMPACT_FLASH = 1.0;  // 0 = off

// Stage
const float STAGE_LIGHT = 1.0;
const float EMBERS      = 1.0;
const float VIGNETTE    = 0.35;

// HUD
const float HUD        = 1.0;  // 0 = no bars and timer
const float LOW_HEALTH = 0.15; // bar blinks red below this

const vec3 SPARK_RIGHT = vec3(0.35, 0.70, 1.00); // blue
const vec3 SPARK_LEFT  = vec3(1.00, 0.30, 0.25); // red
const vec3 SPARK_VERT  = vec3(1.00, 0.80, 0.30); // gold
const vec3 BAR_FULL    = vec3(1.00, 0.85, 0.20);
const vec3 BAR_LOW     = vec3(1.00, 0.25, 0.10);
const vec3 BAR_DAMAGE  = vec3(0.90, 0.08, 0.05);

const float TAU = 6.2831853;

// 7-segment masks for 0-9, bits a..g
const float SEGMENTS[10] = float[10](63.0, 6.0, 91.0, 79.0, 102.0, 109.0, 125.0, 7.0, 127.0, 111.0);

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Ghostty gives the cursor top-left corner (y up) and size
vec2 cursorCenter(vec4 c) {
    return c.xy + vec2(c.z, -c.w) * 0.5;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float bit(float mask, float i) {
    return mod(floor(mask / exp2(i)), 2.0);
}

// Distance to a 7-segment digit. p is 0..0.5 wide, 0..1 tall
float digit(vec2 p, int n) {
    float m = SEGMENTS[n];
    float d = 1e5;
    if (bit(m, 0.0) > 0.5) d = min(d, sdSegment(p, vec2(0.0, 1.0), vec2(0.5, 1.0)));
    if (bit(m, 1.0) > 0.5) d = min(d, sdSegment(p, vec2(0.5, 1.0), vec2(0.5, 0.5)));
    if (bit(m, 2.0) > 0.5) d = min(d, sdSegment(p, vec2(0.5, 0.5), vec2(0.5, 0.0)));
    if (bit(m, 3.0) > 0.5) d = min(d, sdSegment(p, vec2(0.0, 0.0), vec2(0.5, 0.0)));
    if (bit(m, 4.0) > 0.5) d = min(d, sdSegment(p, vec2(0.0, 0.5), vec2(0.0, 0.0)));
    if (bit(m, 5.0) > 0.5) d = min(d, sdSegment(p, vec2(0.0, 1.0), vec2(0.0, 0.5)));
    if (bit(m, 6.0) > 0.5) d = min(d, sdSegment(p, vec2(0.0, 0.5), vec2(0.5, 0.5)));
    return d;
}

// Shown health and the red "damage" part that drains after a hit
vec2 barValue(float now, float before, float age) {
    float shown = now < before ? now : mix(before, now, smoothstep(0.0, 0.4, age));
    float ghost = max(shown, mix(before, now, smoothstep(0.35, 0.9, age)));
    return vec2(shown, ghost);
}

// One health bar. t = 0 at the outer edge, 1 at the inner edge. Returns rgb + alpha
vec4 healthBar(vec2 p, vec2 center, vec2 halfSize, float t, vec2 value) {
    float d = sdBox(p, center, halfSize);
    float border = 1.0 - smoothstep(1.0, 2.5, abs(d - 1.0));
    float inside = 1.0 - smoothstep(-1.0, 0.0, d);

    float yIn = abs(p.y - center.y) / halfSize.y;
    float shown = value.x;

    vec3 fill = mix(BAR_LOW, BAR_FULL, smoothstep(LOW_HEALTH, LOW_HEALTH + 0.25, shown));
    fill *= 0.75 + 0.45 * (1.0 - yIn * yIn); // shine
    if (shown < LOW_HEALTH) fill *= 0.55 + 0.45 * step(0.5, fract(iTime * 3.0));

    vec3 col = vec3(0.08, 0.02, 0.03);
    if (t < value.y) col = BAR_DAMAGE;
    if (t < shown) col = fill;
    col = mix(col, vec3(0.95, 0.92, 0.85), border);

    return vec4(col, max(inside, border));
}

float softClip(float x) {
    return x < 0.8 ? x : 0.8 + 0.2 * (1.0 - exp(-(x - 0.8) / 0.2));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy;
    vec2 uv0 = fragCoord / res;
    vec2 cell = max(iCurrentCursor.zw, vec2(1.0));

    // --- Sort the hit ---------------------------------------------------
    vec2 cur  = cursorCenter(iCurrentCursor);
    vec2 prev = cursorCenter(iPreviousCursor);
    vec2 move = (cur - prev) / cell;
    float cols = abs(move.x);
    float rows = abs(move.y);

    // Ignore the (0,0) start position and changes with no real move (blink)
    bool valid = (iPreviousCursor.x + iPreviousCursor.y) > 0.0 && length(move) > 0.5;

    float strength = 0.0;
    if (valid) {
        if (rows > HEAVY_ROWS || (rows < 0.5 && cols > HEAVY_CELLS)) strength = 1.0;
        else if (rows >= 0.5 || cols > 2.5) strength = 0.6;
        else strength = 0.25 * JAB_EFFECTS;
    }
    float heavy = step(0.99, strength);
    float age = iTime - iTimeCursorChange;
    float seed = hash(vec2(iTimeCursorChange, 1.7));

    vec3 sparkColor = rows >= 0.5 ? SPARK_VERT : (move.x > 0.0 ? SPARK_RIGHT : SPARK_LEFT);

    // --- Hit stop (zoom punch) and shake ----------------------------------
    float hitStop = 0.04 * heavy;
    float st = age - hitStop;
    float shakeAmt = (st > 0.0 && st < 0.2) ? (1.0 - st / 0.2) : 0.0;
    shakeAmt *= shakeAmt * strength * SHAKE * cell.y * 0.15;
    float shakeFrame = floor(iTime * 60.0);
    vec2 shake = (vec2(hash(vec2(shakeFrame, seed)), hash(vec2(seed, shakeFrame))) - 0.5) * 2.0 * shakeAmt;

    vec2 p = fragCoord + shake;
    float punch = heavy * (1.0 - smoothstep(0.0, 0.12, age)) * 0.015;
    p = cur + (p - cur) * (1.0 - punch);
    vec2 uv = p / res;

    // --- Terminal with RGB split on medium and heavy hits -----------------
    float splitAmt = step(0.5, strength) * strength * (1.0 - smoothstep(0.0, 0.25, age));
    vec2 split = vec2(splitAmt * cell.x * 0.12, 0.0) / res;
    vec4 term = texture(iChannel0, uv);
    vec3 col = vec3(
        texture(iChannel0, uv + split).r,
        term.g,
        texture(iChannel0, uv - split).b
    );
    float bgMask = 1.0 - smoothstep(0.08, 0.35, luma(term.rgb));

    // --- Stage: top light, embers, vignette ------------------------------
    float light = exp(-pow((uv0.x - 0.5) * 1.6, 2.0)) * smoothstep(0.3, 1.0, uv0.y);
    col += vec3(1.0, 0.6, 0.3) * light * 0.06 * STAGE_LIGHT * bgMask;

    vec2 ep = fragCoord / (cell.y * 3.0);
    ep.y -= iTime * 0.25;
    ep.x += sin(ep.y * 0.7 + iTime * 0.3) * 0.3;
    vec2 id = floor(ep);
    float eh = hash(id);
    if (eh > 0.75) {
        vec2 pos = vec2(hash(id + 1.3), hash(id + 7.1)) * 0.8 + 0.1;
        float d = length(fract(ep) - pos);
        float flick = 0.6 + 0.4 * sin(iTime * 3.0 + eh * 40.0);
        float ember = exp(-d * d * 2500.0) * flick * (eh - 0.75) * 4.0 * (1.0 - uv0.y * 0.7);
        col += vec3(1.0, 0.45, 0.15) * ember * EMBERS * bgMask;
    }

    vec2 v = uv0 * (1.0 - uv0.yx);
    col *= mix(1.0, pow(v.x * v.y * 16.0, 0.3), VIGNETTE * 2.0);

    // --- Health values (used by rage aura and HUD) -----------------------
    float p1Now  = clamp((iCurrentCursor.y - iCurrentCursor.w) / res.y, 0.0, 1.0);
    float p1Prev = clamp((iPreviousCursor.y - iPreviousCursor.w) / res.y, 0.0, 1.0);
    float p2Now  = clamp(1.0 - (iCurrentCursor.x + iCurrentCursor.z) / res.x, 0.0, 1.0);
    float p2Prev = clamp(1.0 - (iPreviousCursor.x + iPreviousCursor.z) / res.x, 0.0, 1.0);
    vec2 p1 = barValue(p1Now, p1Prev, age);
    vec2 p2 = barValue(p2Now, p2Prev, age);

    // Rage aura: red pulse at the edges when P1 is low
    if (p1.x < LOW_HEALTH) {
        float edge = 1.0 - smoothstep(0.0, 0.2, min(min(uv0.x, 1.0 - uv0.x), min(uv0.y, 1.0 - uv0.y)));
        col += vec3(1.0, 0.1, 0.05) * edge * (0.5 + 0.5 * sin(iTime * 4.0)) * 0.15 * bgMask;
    }

    // --- Speed lines (heavy) ---------------------------------------------
    vec2 toC = fragCoord - cur;
    float r = length(toC);
    float ang = atan(toC.y, toC.x + 1e-4);

    float speed = heavy * SPEED_LINES * (1.0 - smoothstep(0.03, 0.28, age));
    if (speed > 0.0) {
        float a = ang / TAU * 90.0;
        float on = step(0.7, hash(vec2(floor(a), seed)));
        float thin = 1.0 - abs(fract(a) - 0.5) * 2.0;
        float lines = on * smoothstep(0.4, 0.9, thin);
        float reach = mix(cell.y * 4.0, length(res), smoothstep(0.03, 0.28, age));
        lines *= smoothstep(reach, reach + cell.y * 4.0, r);
        col = mix(col, vec3(1.0), lines * speed * 0.35);
    }

    // --- Hit spark -------------------------------------------------------
    float sparkLife = mix(0.16, 0.26, heavy);
    float sa = clamp(age / sparkLife, 0.0, 1.0);
    if (strength > 0.0 && sa < 1.0) {
        float size = cell.y * (0.8 + 2.5 * strength) * SPARK_SIZE;
        float rn = r / size;
        float grow = 1.0 - pow(1.0 - sa, 3.0);
        float fade = 1.0 - sa;

        float n = floor(SPARK_RAYS * (0.6 + 0.4 * strength));
        float a = ang + seed * TAU;
        float rayId = mod(floor(a * n / TAU + 0.5), n);
        float len = 0.55 + 0.45 * hash(vec2(rayId, seed * 13.0));
        float ray = pow(abs(cos(a * n * 0.5)), 20.0 + rn * 80.0);
        ray *= 1.0 - smoothstep(len * grow * 0.7, len * grow, rn);

        float ring = exp(-pow((rn - grow * 1.2) * 10.0, 2.0)) * step(0.5, strength);
        float core = exp(-pow(rn / (0.3 * fade + 0.02), 2.0));

        float spark = (ray * 1.4 + ring * 0.6 + core) * fade;
        col += mix(sparkColor, vec3(1.0), core) * spark * 1.2;
    }

    // --- Impact frame: black/white negative for a moment on heavy hits ---
    if (IMPACT_FLASH > 0.5 && heavy > 0.5 && age < 0.035) {
        col = vec3(1.0 - smoothstep(0.15, 0.35, luma(col)));
    }

    col = vec3(softClip(col.r), softClip(col.g), softClip(col.b));

    // --- HUD -------------------------------------------------------------
    if (HUD > 0.5) {
        float margin = cell.y * 0.4;
        float barH = cell.y * 0.45;
        float timerH = cell.y * 1.0;
        float barY = res.y - margin - timerH * 0.5;
        float gap = timerH * 2.0;
        float barW = (res.x - margin * 2.0 - gap) * 0.5;
        vec2 halfSize = vec2(barW, barH) * 0.5;

        // Fade the HUD when the cursor is under it so text stays readable
        float hudAlpha = iCurrentCursor.y > res.y - cell.y * 2.5 ? 0.25 : 0.85;

        // Slanted bars: left leans /, right leans \.
        float slant = (fragCoord.y - barY) * 0.5;
        vec2 lp = vec2(fragCoord.x - slant, fragCoord.y);
        vec2 rp = vec2(fragCoord.x + slant, fragCoord.y);
        vec2 lc = vec2(margin + barW * 0.5, barY);
        vec2 rc = vec2(res.x - margin - barW * 0.5, barY);

        vec4 left = healthBar(lp, lc, halfSize, (lp.x - margin) / barW, p1);
        vec4 right = healthBar(rp, rc, halfSize, (res.x - margin - rp.x) / barW, p2);
        col = mix(col, left.rgb, left.a * hudAlpha);
        col = mix(col, right.rgb, right.a * hudAlpha);

        // Timer
        float secs = clamp(floor(age), 0.0, 99.0);
        int tens = int(secs / 10.0);
        int ones = int(mod(secs, 10.0));
        vec2 tp = (fragCoord - vec2(res.x * 0.5 - timerH * 0.625, barY - timerH * 0.5)) / timerH;
        float dd = min(digit(tp, tens), digit(tp - vec2(0.75, 0.0), ones)) * timerH;
        float w = timerH * 0.07;
        float ink = 1.0 - smoothstep(w - 1.0, w + 1.0, dd);
        float outline = 1.0 - smoothstep(w + 1.0, w + 3.0, dd);
        vec3 timerCol = secs >= 99.0 ? BAR_LOW : vec3(1.0, 0.97, 0.9);
        col = mix(col, vec3(0.0), outline * hudAlpha * 0.8);
        col = mix(col, timerCol, ink * hudAlpha);
    }

    fragColor = vec4(col, term.a);
}
