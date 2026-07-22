---
version: alpha
name: Buzz for Cloudron
description: Preserve the unmodified upstream Buzz interface in this package.
colors:
  primary: "#8839EF"
  secondary: "#CCD0DA"
  tertiary: "#CCD0DA"
  neutral: "#EFF1F5"
  background: "#EFF1F5"
  surface: "#EFF1F5"
  on-surface: "#4C4F69"
  error: "#D20F39"
  outline: "#BCC0CC"
typography:
  body-md:
    fontFamily: Inter Variable
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  label-md:
    fontFamily: Inter Variable
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4
rounded:
  sm: 4px
  md: 10px
  lg: 16px
spacing:
  unit: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 32px
components: {}
---

# Design System: Buzz for Cloudron

## 1. Overview

This repository packages upstream Buzz and does not create a separate product
interface. The image copies the upstream web and administration bundles without
modification. Upstream Buzz remains the sole visual and interaction authority.

## 2. Colors

The recorded light-theme tokens come from the upstream Buzz web bundle at
`web/src/shared/styles/globals.css`. The palette is Catppuccin Latte with a
mauve primary accent. Dark-mode tokens also remain entirely upstream-owned.

## 3. Typography

Upstream Buzz uses Inter Variable with Inter, Avenir Next, Segoe UI, and generic
sans-serif fallbacks. This package must not inject fonts or alter the hierarchy.

## 4. Layout

All page structure, spacing, navigation, and responsive behavior come from the
pinned upstream web assets under `/srv/buzz/web`. Cloudron provides only the
reverse proxy and container frame.

## 5. Elevation and Depth

Use the elevation, borders, and tonal layers compiled into upstream Buzz. The
Cloudron package adds no overlays, banners, modals, or navigation surfaces.

## 6. Shapes

The upstream radius token is `0.625rem`. Do not restyle the bundled interface in
packaging code.

## 7. Components

The package owns no visual components. Operator administration is deliberately
command-line based through `/app/code/buzz-ctl`. The public HTTP surface is the
unmodified upstream invite and Git-forge bundle.

## 8. Guidance

Do:

- Copy pinned upstream web assets without modification.
- Keep operational messages in Cloudron metadata and the README.
- Update this document if the package later adds any visual surface.

Do not:

- Rebrand Buzz or imply that this package is an official Block distribution.
- Inject Cloudron-specific CSS or JavaScript into upstream assets.
- Expose secrets, internal health data, or MinIO controls in a browser view.

## 9. Responsive Behaviour

Responsive behavior belongs to upstream Buzz desktop, mobile, and web clients.
The package must preserve WebSocket, media, and static-asset delivery without
changing client layout behavior.

## 10. Agent Prompt Guide

When changing packaging, treat the upstream interface as immutable. UI changes
belong upstream unless this repository explicitly adopts a separate management
surface. If that occurs, define its tokens, accessibility, responsive behavior,
and screenshots here in the same change.
