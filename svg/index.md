---
---

Rendering a subset of the SVG format in Roc.

## In scope
- paths and shapes
- strokes and fills
- generic framebuffer platform
- simplified SVG representation using Roc's type system
- demonstrate composing functions

## Out of scope
- parsing SVG files
- conforming to SVG spec in any way
- id-style references
- text
- animation
- gradient and patterns
- clipping and masking
- filters
- trying to be performant
- trying to get everything in scope done

## Milestones
- Framebuffer platform: app provides (width, height, RGB bytes)
- straight paths and fills
- render Roc's logo
- lines and rects
- curved paths, circle, ellipse
- polyline, polygon
- stroke
- render ghostscript tiger

## Roc SVG (from the home page)
```svg
<svg width="240" height="240" viewBox="0 0 51 53" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M23.6751 22.7086L17.655 53L27.4527 45.2132L26.4673 39.3424L23.6751 22.7086Z" fill="#6c3bdc" />
    <path d="M37.2438 19.0101L44.0315 26.3689L45 22L45.9665 16.6324L37.2438 19.0101Z" fill="#8a66de" />
    <path d="M23.8834 3.21052L0 0L23.6751 22.7086L23.8834 3.21052Z" fill="#8a66de" />
    <path d="M44.0315 26.3689L23.6751 22.7086L26.4673 39.3424L44.0315 26.3689Z" fill="#8a66de" />
    <path d="M50.5 22L45.9665 16.6324L45 22H50.5Z" fill="#6c3bdc" />
    <path d="M23.6751 22.7086L44.0315 26.3689L37.2438 19.0101L23.8834 3.21052L23.6751 22.7086Z" fill="#6c3bdc" />
</svg>
```

## Links
- [SVG MDN](https://developer.mozilla.org/en-US/docs/Web/SVG)
- [usvg](https://docs.rs/usvg/latest/usvg/index.html)
- [roc-svg](https://github.com/Hasnep/roc-svg/tree/main)
- [ghostscript tiger svg](https://commons.wikimedia.org/wiki/File:Ghostscript_Tiger.svg)