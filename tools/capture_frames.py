#!/usr/bin/env python3
"""Capture every preset of a running display as PNGs.

    python3 tools/capture_frames.py your-device.yaml docs/img/

Reads the device address and API key from your ESPHome config the way `esphome logs`
does, switches through the presets over the native API, presses Dump Frame on each and
renders the frames with render_frames.py. The display is put back on the preset it
showed. Run it with the Python that has ESPHome installed, plus Pillow.
"""

import argparse
import asyncio
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from aioesphomeapi import APIClient, LogLevel  # noqa: E402
import render_frames  # noqa: E402

SETTLE = 1.0  # seconds; a frame is rendered every 200 ms
BOOT_SCREEN = 6.0  # the IP address is shown for 5 s after WiFi connects
DUMPS = 3  # per preset, 0.6 s apart, so one of them has the blinking colons on
DUMP_GAP = 0.6


def load_device(config_path):
    """Return (address, port, encryption key) from the device's ESPHome config."""
    from esphome.config import read_config
    from esphome.core import CORE

    CORE.config_path = Path(config_path).resolve()
    config = read_config({}, skip_external_update=True)
    if config is None:
        sys.exit("the ESPHome config is not valid")
    CORE.config = config
    api = config.get("api") or {}
    return CORE.address, api.get("port", 6053), (api.get("encryption") or {}).get("key")


async def capture(address, port, key):
    client = APIClient(address, port, None, noise_psk=key, client_info="capture_frames")
    await client.connect(login=True)
    try:
        info = await client.device_info()
        print(f"{info.name}: ESPHome {info.esphome_version}, built {info.compilation_time}")
        entities, _ = await client.list_entities_services()
        by_name = {e.name: e for e in entities}
        for name in ("Display Preset", "Dump Frame"):
            if name not in by_name:
                sys.exit(f"no '{name}' entity: flash a firmware with the current package first")
        preset = by_name["Display Preset"]
        dump = by_name["Dump Frame"]

        states = {}
        client.subscribe_states(lambda s: states.__setitem__(s.key, s))
        lines = []
        unsubscribe = client.subscribe_logs(
            lambda m: lines.append(m.message.decode(errors="replace")),
            log_level=LogLevel.LOG_LEVEL_INFO,
        )
        # Initial states; also lets a freshly started display get past its boot screen,
        # which would otherwise be dumped instead of the preset
        await asyncio.sleep(BOOT_SCREEN)

        def state(name):
            entity = by_name.get(name)
            return getattr(states.get(entity.key), "state", None) if entity else None

        original = state("Display Preset")
        if state("Countdown") == "DONE":
            sys.exit('"DONE!" is flashing over every preset: press Stop Countdown first')
        # Start a countdown for its preset unless one is already running
        own_countdown = state("Countdown") in (None, "--:--")
        try:
            for option in preset.options:
                client.select_command(preset.key, option)
                if option == "Countdown" and own_countdown:
                    client.button_command(by_name["Start Countdown"].key)
                await asyncio.sleep(SETTLE)
                for _ in range(DUMPS):
                    client.button_command(dump.key)
                    await asyncio.sleep(DUMP_GAP)
                await asyncio.sleep(SETTLE)
                if option == "Countdown" and own_countdown:
                    client.button_command(by_name["Stop Countdown"].key)
        finally:
            if original:
                client.select_command(preset.key, original)
            await asyncio.sleep(SETTLE)
            unsubscribe()
    finally:
        await client.disconnect()
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("config", help="the device's ESPHome YAML")
    parser.add_argument("outdir", type=Path, help="folder for the PNGs")
    parser.add_argument("--log", type=Path, help="also save the captured log lines here")
    parser.add_argument(
        "--style", choices=render_frames.STYLES, default="square", help="pixel shape"
    )
    args = parser.parse_args()

    address, port, key = load_device(args.config)
    lines = asyncio.run(capture(address, port, key))
    if args.log:
        args.log.write_text("\n".join(lines) + "\n")
    frames = render_frames.parse(lines)
    if not frames:
        sys.exit("no complete frame dumps in the log")
    args.outdir.mkdir(parents=True, exist_ok=True)
    for preset, rows in render_frames.pick(frames).items():
        path = args.outdir / f"{render_frames.slug(preset)}.png"
        render_frames.render(rows, path, args.style)
        print(f"{preset} -> {path}")


if __name__ == "__main__":
    main()
