# Changelog

## 0.1.0

First public release.

### Added
- `max7219-hottub.yaml`: ESPHome package for a 64 × 16 MAX7219 display with seven presets
  (Hot Tub, Hot Tub Big, Wall Clock, Night Clock, Weather, Countdown, Binary Clock), source
  sensors set from Home Assistant, automatic or manual brightness, °C / °F, a wind arrow
  relative to the viewer and a countdown.
- `max7219digit`: ESPHome 2026.10.2's driver with batched SPI frames (8 transfers per frame
  instead of 4,096) and a control register refresh every 10 s.
- `ha_dynamic`: Home Assistant sensor whose entity ID comes from a text entity.
- Dump Frame button, `tools/capture_frames.py` and `tools/render_frames.py` for screenshots
  taken from a running display.
- Case: OpenSCAD source, STL files, print settings and assembly steps.
- Examples for ESP32 and ESP32-C3; builds against ESPHome stable and beta.
