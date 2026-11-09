import 'package:flutter/material.dart';

const appBrandAssetPath = 'assets/brand/app_brand_mark.png';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MUKLadder tennis logo',
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          appBrandAssetPath,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBrandMark(size: compact ? 34 : 52),
        const SizedBox(width: 12),
        Text('MUKLadder', style: textStyle),
      ],
    );
  }
}
