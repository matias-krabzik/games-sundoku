import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key, this.prefix = 'Versión ', this.style});

  final String prefix;
  final TextStyle? style;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _info,
    builder: (context, snapshot) {
      final version = snapshot.data?.version;
      if (version == null || version.isEmpty) {
        return const SizedBox.shrink();
      }
      return Text(
        '${widget.prefix}$version',
        textAlign: TextAlign.center,
        style: widget.style,
      );
    },
  );
}
