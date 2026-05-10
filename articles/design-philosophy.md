# Design Philosophy

This document records the design invariants that govern ggpatchy’s
internals. It is written for contributors, not users. If you are adding
a pattern or modifying the rendering pipeline, read this first.

## The user contract

The pattern reference vignette (`vignettes/pattern-reference.Rmd`) is
the authoritative definition of what “correct” looks like. At the
default `pattern_spacing`, every standard pattern should be visually
consistent and readable on a typical chart element. Any deviation from
that baseline is explicitly the user’s choice, made by setting
`pattern_spacing` explicitly.

The strongest form of this contract is **physical uniformity across all
shapes in the same plot**: a small polygon and a large polygon with the
same `pattern_spacing` have the same physical distance between hatch
lines, the same physical dot size, and the same physical dot pitch.
Users never see a map where small counties have 2 dots and large
counties have 50.

## Coordinate system contract (mm)

Pattern spacing is in **millimetres**. `pattern_spacing = 5` means “5mm
between line centres” or “5mm between dot centres” everywhere — bar,
tile, polygon, sf geometry, violin, density curve, and legend key. Grid
resolves millimetres to device pixels at draw time, independently of
viewport size. This produces physically consistent patterns across all
shapes.

**Why mm, not npc?** npc resolves relative to the current viewport’s
pixel dimensions. A tall bar at 200px and a short bar at 40px would get
very different physical spacings with the same npc fraction. mm is
resolved by grid against device physical dimensions, independently of
viewport size. `spacing = 5mm` is 5mm whether the viewport is 200px or
40px.

**Implementation constraint:** `mm → npc` conversion must happen inside
a `makeContent` method — a grid callback that fires at draw time when
the correct viewport is active. It cannot happen in the pattern function
body, which executes before the shape’s viewport is pushed. Pattern
functions construct a custom `gTree` (`DotPatternTree`,
`LinePatternTree`) that defers conversion to `makeContent`. See
`specs/SPEC_makecontent_infrastructure.md`.

### Previous model (v0.5.x and earlier)

In prior versions, pattern spacing was **viewport-relative**
(bounding-box fraction). `pattern_spacing = 0.08` meant 8% of the
shape’s bounding box. This produced different visual densities across
shapes of different physical sizes — most visibly on choropleth maps
where small and large regions received different dot counts.

## Legend key spacing

The legend key communicates pattern *identity* — what type of pattern is
this? Because `pattern_spacing` is now in mm, the key correctly shows
the same physical density as the data. No override is needed or applied.

`pattern_size` and `pattern_angle` are passed through from user data, as
they always have been.

## Pattern functions are pure

Pattern functions `fn(x, y, width, height, gp, params)` have no side
effects and make no assumptions about rendering context beyond what is
passed to them. They must not inspect global state, device dimensions,
or parent viewport dimensions.

**Dot radius uses `"mm"`.** `unit(r, "mm")` is physically circular on
all devices at all scales. Do not use `"npc"` for dot radius — it
resolves using the x-axis of the viewport only and produces ovals on
non-square viewports.

## Diagnostic checklist for pattern rendering issues

If patterns look wrong (wrong density, oval dots, legend mismatch),
check in this order:

1.  **Are dots oval instead of circular?** Dot radius must use `"mm"`,
    never `"npc"`. `unit(r, "npc")` resolves anisotropically on
    non-square viewports.

2.  **Is density inconsistent across shapes of different sizes?** Check
    that `makeContent.DotPatternTree` and `makeContent.LinePatternTree`
    are calling `convertWidth` / `convertHeight` inside `makeContent`,
    not in the pattern function body.

3.  **Is `draw_key_pattern` passing `width = 0.9, height = 0.9`?** It
    should be — verify
    `pattern_fn(x = 0.05, y = 0.05, width = 0.9, height = 0.9, ...)`.

4.  **Does the legend key look wrong for sparse/dense variants?** In the
    mm model, the legend shows the same physical spacing as the data — a
    dense pattern swatch has denser lines. This is correct and expected.

5.  **Is there a `bbox_scale`, `sqrt(width * height)`, or
    panel-dimension division in a pattern function?** Remove it. Pattern
    functions receive bbox-normalised coordinates; they must not apply
    additional scaling.
