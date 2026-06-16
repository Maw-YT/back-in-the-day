# Back in the day — PSX Style Shader

A PlayStation 1–inspired Iris shader pack for Minecraft. It recreates the look of late-90s console rendering: wobbly geometry, affine texture warping, banded lighting, low internal resolution, ordered dithering, distance fog, and optional CRT post-processing.

**Mod loader:** Iris Shaders (recommended)  
**Default internal resolution:** 320×240  
**Default aspect ratio:** 4:3 (letterboxed on widescreen)

---

## Overview

The pack applies PSX-style effects in three stages:

1. **Geometry pass (gbuffers)** — vertex snapping, breathing, affine textures, fragment lighting, fog, and alpha quantization on world geometry, entities, hands, clouds, and water.
2. **Composite pass** — passthrough copy of the scene buffer.
3. **Final pass** — low-res pixel snapping, color quantization/dithering, aspect ratio framing, and CRT effects.

Most settings are exposed in the in-game shader options menu under five tabs: **PSX**, **Lighting**, **Dither**, **Fog**, and **CRT**.

---

## PSX Tab — Geometry & Display

### Vertex Snapping
Snaps world-space vertices to a distance-scaled grid, producing the characteristic PSX polygon jitter.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Vertex Snapping | On | On / Off | Master toggle for world geometry snapping |
| Snap Fineness | 320 | 120–480 | Grid resolution; lower = chunkier snap |
| Vertex Breathing | 0.35 | 0–1 | Subtle animated wobble on snapped vertices; fades underground |

Breathing is scaled by sky light so caves stay stable instead of flickering.

### Hand Items
Held items use a separate, finer snap grid and lighter breathing so first-person models stay readable.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Hand Snap Strength | 0.30 | 0–5 | How strongly held items snap |
| Hand Breath Mul | 0.50 | 0–2 | Breathing multiplier for hands |

### Texture Warping
Affine texture mapping — textures stretch and swim on large polygons instead of staying perspective-correct.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Texture Warping | On | On / Off | Enables affine UV interpolation |
| Texture Warp Cap | 0.25 | 0–2 | Minimum clip-space W; limits extreme warping |

### Internal Resolution
The final pass snaps sampling to a fixed pixel grid before upscale and post effects.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Render Width | 320 | 160–640 | Internal horizontal resolution |
| Render Height | 240 | 120–480 | Internal vertical resolution |

### Aspect Ratio
Simulates playing on a CRT with a fixed aspect ratio. Widescreen monitors get pillarboxing (4:3) or letterboxing (16:9) with center-cropped source content — the image is not squished.

| Setting | Default | Options | Description |
|---------|---------|---------|-------------|
| Aspect Ratio | 4:3 | Native / 4:3 / 16:9 | Target display aspect |
| Hand Aspect Offset | 1.0 | 0–1.5 | Shifts held items into the visible frame; main hand moves left, offhand moves right on widescreen |

---

## Lighting Tab

### PSX Lighting
Fragment-shader lighting with banded lightmaps and directional face shading (similar to PSX Gouraud + flat shading).

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| PSX Lighting | On | Vanilla / On | **Vanilla** uses raw lightmap samples; **On** enables banded PSX lighting |
| Light Bands | 16 | 4–16 | Quantization steps for block/sky light. **16** ≈ native granularity (clean, flat ground stays smooth); lower = chunkier retro banding (and some checkerboard shimmer on light gradients) |
| Shade Bands | 4 | 2–8 | Quantization steps for sun-facing face shading |
| Shadow Depth | 0.35 | 0.20–0.50 | Ambient floor for shaded faces |

**Underground behavior:** When sky light is very low, face shading is disabled and lighting uses a stable ambient lightmap sample — this prevents flicker in caves from vertex breathing and band snapping.

**Lightmap snapping:** Lightmap coordinates are snapped to a 16×16 texel grid for stable, chunky light transitions.

**Cross-version lighting:** Block/sky light is normalized to a clean `[0, 1]` range on read and a fresh texel-center coordinate is rebuilt before sampling the lightmap. This keeps lighting correct on every 1.21.x build despite the differing raw lightmap ranges Iris delivers across versions (see Iris issues #2487 / #2810).

### Hand Held Light
Dynamic light from items held in main hand or offhand (torches, lanterns, etc.). Uses Iris uniforms `heldBlockLightValue`, `heldBlockLightValue2`, and `relativeEyePosition`.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Hand Held Light | On | On / Off | Master toggle |
| Hand Light Strength | 1.0 | 0.5–2.0 | Brightness multiplier |
| Hand Light Range | 1.0 | 0.5–2.0 | Falloff distance multiplier |

Light is cast from separate main-hand and offhand positions and merged with existing block light using logarithmic blending.

---

## Dither Tab — Color Depth

Simulates a 15-bit RGB555 framebuffer (32 levels per channel) with optional ordered dithering.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Dithering | On | On / Off | Enables 4×4 Bayer ordered dither before quantization |
| 16-bit Color Limit | On | On / Off | **On** = 32 steps/channel (PSX-accurate); **Off** = custom step count |
| Dither Strength | 1.0 | 0.5–3.0 | How strongly the dither pattern affects output |
| Color Steps | 31 | 8–32 | Color levels per channel when 16-bit limit is off |
| Dither Scale | 1.0 | 1–4 | Size of the dither pattern in pixels |

Bright pixels (luminance > 0.4) skip dither and use flat quantization only.

---

## Fog Tab

Distance fog with optional underground cave fog. Fog colors are color-quantized to match the rest of the palette.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Fog | On | On / Off | Master fog toggle |
| Fog Distance | 20 | 12–96 | Linear fog start/ramp distance |
| Fog Density | 0.14 | 0.04–0.20 | Exponential fog density |
| Sky Fog Strength | 0.50 | 0.20–1.00 | How strongly fog affects sky passes |

### Cave Fog
Height-based fog that darkens and thickens fog below a world Y threshold — simulates oppressive underground atmosphere.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Cave Fog | On | On / Off | Master toggle |
| Cave Fog Strength | 0.65 | 0–1 | Blend intensity |
| Cave Fog Start Height | 56 | 32–320 | World Y above which cave fog begins |
| Cave Fog Depth | 40 | 16–96 | Vertical range over which cave fog ramps in |

Underwater fog uses a separate, denser exponential curve.

---

## CRT Tab — Post Processing

All CRT effects run in the **final pass** after low-res upscale and dithering. Each effect has an independent strength slider.

| Setting | Default | Range | Effect |
|---------|---------|-------|--------|
| CRT Effects | On | On / Off | Master toggle for all CRT post-processing |
| Scanlines | 0.35 | 0–1 | Horizontal scanline darkening |
| Vignette | 0.40 | 0–1 | Edge darkening |
| Chromatic Aberration | 0.25 | 0–1 | RGB channel separation toward screen edges |
| Screen Curvature | 0.30 | 0–1 | Barrel distortion of the image |
| Phosphor Glow | 0.35 | 0–1 | Bloom on bright areas (green-tinted) |
| Shadow Mask | 0.25 | 0–1 | RGB aperture grille / shadow mask pattern |
| Color Bleed | 0.20 | 0–1 | Horizontal smear on bright pixels |
| Static Noise | 0.12 | 0–1 | Animated film grain |

Processing order: chromatic sampling → dither/quantize → phosphor glow → color bleed → scanlines → shadow mask → vignette → noise.

---

## Additional Effects (Always On)

These are built into the pipeline and do not have separate toggles.

### Alpha Quantization
Transparent pixels are snapped to three alpha levels: **0**, **0.5**, and **1.0** — producing hard-cut PSX-style transparency on foliage, particles, glass, and water.

### Entity Color Tinting
Entities with color overlays (team colors, hurt flash, etc.) use quantized alpha blending via `entityColor`.

### Separate AO
Enabled in `shaders.properties` (`separateAo = true`) for cleaner ambient occlusion with the PSX lighting model.

---

## Affected Render Passes

| Pass | Vertex Snap | Texture Warp | PSX Lighting | Fog | Alpha Quantize | Notes |
|------|:-----------:|:------------:|:------------:|:---:|:--------------:|-------|
| Terrain | ✓ | ✓ | ✓ | ✓ | ✓ | Full PSX treatment |
| Block entities | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Entities | ✓ | ✓ | ✓ | ✓ | ✓ | + entity color tint |
| Glowing entities | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Hand / held items | ✓* | ✓ | ✓* | ✓ | ✓ | *Separate hand snap/breath/light paths |
| Hand (translucent) | ✓* | ✓ | ✓* | ✓ | ✓ | `gbuffers_hand_water` — maps, glass, etc. |
| Particles | ✓ | ✓ | ✓ | ✓ | ✓ | `gbuffers_particles` / `_translucent` |
| Translucent entities | ✓ | ✓ | ✓ | ✓ | ✓ | `gbuffers_entities_translucent` |
| Translucent block entities | ✓ | ✓ | ✓ | ✓ | ✓ | `gbuffers_block_translucent` |
| Lightning | ✓ | — | ✓ | ✓ | ✓ | `gbuffers_lightning` |
| Lines / outlines | ✓ | — | ✓ | ✓ | ✓ | `gbuffers_line` / `gbuffers_lines` |
| Water | ✓ | ✓ | ✓ | ✓ | ✓ | Vanilla-style water shading |
| Clouds | ✓** | ✓ | — | ✓ | ✓ | **View-space snap |
| Weather | ✓ | ✓ | — | ✓ | ✓ | Rain/snow |
| Basic / textured | ✓ | ✓ | ✓ | ✓ | ✓ | Particles, items on ground, etc. |
| Sky (textured) | — | — | — | — | — | Vanilla passthrough (sun/moon) |
| Sky (basic) | — | — | — | — | — | Vanilla passthrough |
| Beacon beam | ✓ | ✓ | — | ✓ | ✓ | |
| Armor glint | ✓ | ✓ | — | ✓ | ✓ | |
| Spider eyes | ✓ | ✓ | — | ✓ | ✓ | |
| Damaged block overlay | ✓ | ✓ | ✓ | ✓ | ✓ | |

---

## File Structure

```
shaders/
├── lib/
│   ├── settings.glsl          # All #define settings and defaults
│   └── psx/
│       ├── affineTex.glsl     # Perspective-incorrect texture mapping
│       ├── alphaQuantize.glsl # 3-level alpha snapping
│       ├── aspect.glsl        # Aspect ratio letterbox / crop / hand offset
│       ├── colorQuantize.glsl # RGB555 / custom step quantization
│       ├── crt.glsl           # CRT post-processing stack
│       ├── dither.glsl        # 4×4 Bayer ordered dither
│       ├── entityTint.glsl    # Entity color overlay blending
│       ├── fog.glsl           # Distance + cave fog
│       ├── handLight.glsl     # Dynamic held-item lighting
│       ├── lighting.glsl      # PSX banded lighting (fragment shader)
│       ├── litTextured.glsl   # Shared lit texture sampling helper
│       ├── lowRes.glsl        # Internal resolution UV snapping
│       └── vertexSnap.glsl    # Vertex snap, breathing, world position
├── program/                   # GLSL source for each render pass
├── lang/en_US.lang            # Setting display names
└── shaders.properties         # Shader options menu layout
```

---

## Recommended Presets

### Authentic PSX (defaults)
Leave all defaults — 320×240, 4:3, vertex snap on, CRT on, cave fog on.

### Cleaner retro
- Snap Fineness → 480 (subtle)
- Vertex Breathing → 0
- CRT Effects → Off
- Dither Strength → 0.5

### Performance
- Render Width / Height → 240×180 or lower
- CRT Effects → Off
- Phosphor Glow / Color Bleed → 0

### Modern widescreen
- Aspect Ratio → Native or 16:9
- Hand Aspect Offset → tune until hands sit in frame

---

## Credits & Compatibility

**Supported Minecraft versions:** 1.21 through 1.21.11 (all 1.21.x releases)

PSX lighting is version-independent: it does not assume a fixed raw lightmap range, so block/sky banding and directional shading render identically across the whole 1.21.x line regardless of the Iris build's lightmap offset.

**Required:** [Iris Shaders](https://irisshaders.dev/) + Sodium (included with Iris installer)

| Iris version | Minecraft |
|--------------|-----------|
| 1.7.x+ | 1.21 – 1.21.4 |
| 1.8.x+ | 1.21.5 – 1.21.8 |
| 1.9.x+ | 1.21.9 – 1.21.10 |
| 1.10.x+ | 1.21.11 |

Hand held light requires Iris (or a mod that provides `heldBlockLightValue` uniforms).

The pack includes dedicated shader programs for render passes added across the 1.21.x line (`gbuffers_hand_water`, `gbuffers_textured_lit`, `gbuffers_line`, `gbuffers_lightning`, translucent entity/block/particle passes, and more). Older 1.21.x builds fall back gracefully when a pass is not used by that version.

Sky rendering intentionally uses a vanilla passthrough to avoid regressions with sun/moon alpha and fog interaction.
