# mir-text

BDF font loading and text rendering library for Zig.

Parses BDF font files and renders UTF-8 text to monochrome bitmaps suitable for compositing onto pixel buffers or canvases. Ships with built-in Unifont and Terminus fonts.

## Features

- BDF font file parsing with gzip decompression
- UTF-8 text rendering to monochrome (`u1`) bitmaps
- Text measurement without rendering
- Monochrome-to-RGBA conversion
- Font fallback chains (pass multiple fonts, first match wins)
- Built-in fonts: Unifont (full Unicode), Unifont JP, Terminus (9 sizes, normal/bold)

## Usage

### Install

```sh
zig fetch --save git+https://github.com/make-it-render/mir-text
```

### build.zig

```zig
const text_dep = b.dependency("text", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("text", text_dep.module("text"));
```

### Example

```zig
const text = @import("text");

// Load a built-in font
const font = try text.unifont.unifont(allocator);
defer font.deinit();

// Measure text dimensions
const metrics = try text.measure(&.{font}, "Hello, world!");
// metrics.width, metrics.height

// Render to a monochrome bitmap
var bitmap = try text.render(allocator, &.{font}, "Hello, world!");
defer bitmap.deinit();
// bitmap.width, bitmap.height, bitmap.bitmap ([]const u1)

// Convert to RGBA for display (e.g. white text)
const rgba = try bitmap.toRgba(allocator, &.{ 0xFF, 0xFF, 0xFF, 0xFF });
defer allocator.free(rgba);
```

## API

### Font loading

Fonts are loaded at comptime from embedded gzip-compressed BDF files and parsed at runtime.

**Unifont** -- full Unicode coverage (57k+ glyphs):

```zig
const font = try text.unifont.unifont(allocator);
defer font.deinit();

// Japanese variant
const font_jp = try text.unifont.unifont_jp(allocator);
defer font_jp.deinit();
```

**Terminus** -- compact bitmap font in sizes 12-32, normal or bold:

```zig
const font = try text.terminus.terminus(allocator, .@"16", .n); // 16px normal
defer font.deinit();

const bold = try text.terminus.terminus(allocator, .@"24", .b); // 24px bold
defer bold.deinit();
```

Available sizes: `12`, `14`, `16`, `18`, `20`, `22`, `24`, `28`, `32`. Weights: `.n` (normal), `.b` (bold).

### Font

`Font` holds parsed glyph data from a BDF file.

| Field    | Type  | Description              |
|----------|-------|--------------------------|
| `width`  | `u16` | Font bounding box width  |
| `height` | `u16` | Font bounding box height |
| `ascent` | `u16` | Font ascent              |
| `count`  | `u32` | Number of glyphs         |

| Method                  | Description                                          |
|-------------------------|------------------------------------------------------|
| `get(codepoint) ?Glyph` | Look up a glyph by Unicode codepoint                |
| `getOrBlank(codepoint) Glyph` | Look up a glyph, falling back to codepoint 0   |
| `deinit()`              | Free all font memory                                |

### Text rendering

Both `render` and `measure` accept a font slice, enabling fallback chains where the first font containing a glyph wins:

```zig
// Single font
const metrics = try text.measure(&.{font}, "Hello");
var bitmap = try text.render(allocator, &.{font}, "Hello");

// Fallback chain: try Terminus first, fall back to Unifont
const metrics = try text.measure(&.{ terminus_font, unifont }, "Hello");
var bitmap = try text.render(allocator, &.{ terminus_font, unifont }, "Hello");
```

### Bitmap

`render` returns a `Bitmap` with monochrome pixel data:

| Field    | Type            | Description                        |
|----------|-----------------|------------------------------------|
| `width`  | `u16`           | Bitmap width in pixels             |
| `height` | `u16`           | Bitmap height in pixels            |
| `bitmap` | `[]const u1`    | Pixel data (1 = foreground, 0 = background) |

| Method                          | Description                              |
|---------------------------------|------------------------------------------|
| `toRgba(allocator, pixel) []u8` | Convert to RGBA using the given 4-byte color for foreground pixels |
| `deinit()`                      | Free bitmap memory                       |

### TextMetrics

`measure` returns a `TextMetrics`:

| Field    | Type  | Description            |
|----------|-------|------------------------|
| `width`  | `u16` | Total text width       |
| `height` | `u16` | Maximum glyph height   |

### BDF parsing

You can also parse your own BDF font files directly:

```zig
const font = try text.bdf.parse(allocator, reader);
defer font.deinit();
```

The parser accepts a `*std.Io.Reader`, so it works with any source (files, decompressors, memory buffers).

## Building

```sh
zig build          # build library
zig build test     # run tests
zig build docs     # generate documentation
```

## License

MIT License

Copyright (c) Diogo Souza da Silva
