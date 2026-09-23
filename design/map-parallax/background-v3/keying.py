"""Remove the flat magenta used by AI intermediates, including edge spill."""
import cv2
import numpy as np


def chroma_key(rgb):
    pixels = rgb.astype(np.float32)
    excess = np.minimum(pixels[:, :, 0], pixels[:, :, 2]) - pixels[:, :, 1]
    solid = excess < 10
    background = excess > 180
    key = np.median(pixels[background], axis=0)
    _, labels = cv2.distanceTransformWithLabels((~solid).astype('uint8'),
        cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
    lut = np.zeros((labels.max() + 1, 3), np.float32)
    lut[labels[solid]] = pixels[solid]
    delta = lut[labels] - key
    alpha = np.clip(np.sum((pixels - key) * delta, axis=2) /
        np.maximum(np.sum(delta * delta, axis=2), 1), 0, 1)
    alpha[solid] = 1
    alpha[background] = 0
    alpha[alpha < .04] = 0
    recovered = np.clip((pixels - (1 - alpha[:, :, None]) * key) /
        np.maximum(alpha[:, :, None], .001), 0, 255).astype('uint8')
    rgba = np.dstack([recovered, np.round(alpha * 255).astype('uint8')])
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return rgba
