import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_surface_art.dart';

const bookPaperAsset = AssetImage('assets/images/tutorial/paper-grain.jpg');
const bookLandscapeAsset = AssetImage('assets/images/world-1-horizontal.png');

/// Keeps the book's decoded artwork alive until the owning app is disposed.
class BookResources {
  final List<_PinnedBookImage> _images = [];
  Future<void>? _ready;
  bool _disposed = false;

  Future<void> prepare(BuildContext context) {
    if (_disposed) return Future.error(StateError('Book resources disposed'));
    return _ready ??= _load(createLocalImageConfiguration(context));
  }

  Future<void> _load(ImageConfiguration configuration) async {
    final providers = <ImageProvider<Object>>[
      bookPaperAsset,
      bookLandscapeAsset,
      const AssetImage('assets/images/home/icons.png'),
      // NineSliceArt uses an explicit scale; atlas icons and horizontal
      // surfaces use resolution-aware AssetImage providers.
      for (final surface in [
        UiSurface.solaraBook,
        UiSurface.goldButton,
        UiSurface.goldRound,
      ]) ...[
        ExactAssetImage(surface.spec.asset),
        AssetImage(surface.spec.asset),
      ],
    ];
    final images = [
      for (final provider in providers)
        _PinnedBookImage(provider.resolve(configuration)),
    ];
    _images.addAll(images);
    try {
      await Future.wait<void>([
        for (final image in images) image.ready,
        // Pagination measures text before the first leaf is built.
        for (final font in const {
          'IMFellEnglish': 'assets/fonts/IMFellEnglish-Regular.ttf',
          'EBGaramond': 'assets/fonts/EBGaramond-Variable.ttf',
          'Baloo2': 'assets/fonts/Baloo2-Variable.ttf',
        }.entries)
          (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load(),
      ]);
    } catch (error, stack) {
      for (final image in images) {
        image.dispose();
        _images.remove(image);
      }
      _ready = null;
      Error.throwWithStackTrace(error, stack);
    }
  }

  void dispose() {
    _disposed = true;
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
  }
}

class _PinnedBookImage {
  _PinnedBookImage(this.stream) {
    listener = ImageStreamListener(
      (frame, _) {
        // The active stream retains the decoded frame, including after the
        // dialog closes. Release only this callback's extra reference.
        frame.dispose();
        if (!_firstFrame.isCompleted) _firstFrame.complete();
      },
      onError: (Object error, StackTrace? stack) {
        if (!_firstFrame.isCompleted) _firstFrame.completeError(error, stack);
      },
    );
    stream.addListener(listener);
  }

  final ImageStream stream;
  final Completer<void> _firstFrame = Completer<void>();
  late final ImageStreamListener listener;
  bool _disposed = false;

  Future<void> get ready => _firstFrame.future;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stream.removeListener(listener);
    if (!_firstFrame.isCompleted) {
      _firstFrame.completeError(
        StateError('Book image disposed before loading'),
      );
    }
  }
}
