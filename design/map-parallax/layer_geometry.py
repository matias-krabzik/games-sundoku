"""Shared registration and overscan for every map layer."""
import numpy as np

SOURCE_SIZE = (2172, 724)
PADDING = 128
BACKGROUND_PADDING = 512


def horizontal_padding(name):
    return PADDING if name in ('terrain', 'foreground') else BACKGROUND_PADDING


def vertical_padding(name):
    return {'foreground': 80, 'distance': 48}.get(name, PADDING)


def pad_layer(rgba, name):
    assert rgba.shape == (SOURCE_SIZE[1], SOURCE_SIZE[0], 4)
    if name in ('foreground', 'distance'):
        raise ValueError(f'Use the dedicated {name} exporter for painted margins; never reflect this layer')
    # Reuse edge artwork outside the original canvas. Reflect horizontally to
    # avoid stretched vertical stripes; sky uses its smooth boundary color.
    margin = horizontal_padding(name)
    horizontal = np.pad(rgba, ((0, 0), (margin, margin), (0, 0)),
                        mode='edge' if name == 'sky' else 'reflect')
    padded = np.pad(horizontal, ((PADDING, PADDING), (0, 0), (0, 0)), mode='edge')
    padded[padded[:, :, 3] == 0, :3] = 0
    assert np.array_equal(padded[PADDING:-PADDING, margin:-margin], rgba)
    return padded
