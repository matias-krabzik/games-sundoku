class AudioCredit {
  const AudioCredit({
    required this.title,
    required this.author,
    this.description,
    required this.license,
    required this.licenseUrl,
    required this.sourceUrl,
    this.licenseAsset,
  });

  final String title;
  final String author;
  final String? description;
  final String license;
  final String licenseUrl;
  final String sourceUrl;
  final String? licenseAsset;
}

const audioCredits = [
  AudioCredit(
    title: 'Música',
    author: 'Kevin MacLeod (incompetech.com)',
    description:
        'Devonshire Waltz Moderato\n'
        'Devonshire Waltz Allegretto\n'
        'Morning · Evening',
    license: 'CC BY 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
    sourceUrl: 'https://incompetech.com/music/royalty-free/music.html',
    licenseAsset: 'assets/licenses/CC-BY-4.0.txt',
  ),
  AudioCredit(
    title: 'Efectos de interfaz',
    author: 'Kenney (kenney.nl)',
    license: 'CC0 1.0 Universal',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    sourceUrl: 'https://kenney.nl/assets/interface-sounds',
    licenseAsset: 'assets/licenses/CC0-1.0.txt',
  ),
  AudioCredit(
    title: 'Celebración del sol',
    author: 'Kenney (kenney.nl)',
    license: 'CC0 1.0 Universal',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    sourceUrl: 'https://kenney.nl/assets/music-jingles',
    licenseAsset: 'assets/licenses/CC0-1.0.txt',
  ),
  AudioCredit(
    title: 'Sonido de victoria',
    author: 'Mixkit',
    license: 'Mixkit Sound Effects Free License',
    licenseUrl: 'https://mixkit.co/license/modal/sfxFree/',
    sourceUrl: 'https://mixkit.co/free-sound-effects/video-game/',
  ),
];
