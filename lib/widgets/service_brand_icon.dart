import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

/// A locally bundled Simple Icons glyph with a service-specific fallback.
class ServiceBrandIcon extends StatelessWidget {
  const ServiceBrandIcon({
    super.key,
    required this.serviceName,
    this.size = 56,
  });

  final String serviceName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final service = serviceName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final icon = _iconFor(service);
    final color = _colorFor(service);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF17102B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF34264F)),
      ),
      child: icon == null
          ? _ServiceFallback(service: service, color: color, size: size)
          : Icon(icon, size: size * .68, color: color),
    );
  }

  IconData? _iconFor(String service) {
    if (service.contains('netflix')) return SimpleIcons.netflix;
    if (service.contains('spotify')) return SimpleIcons.spotify;
    if (service.contains('youtube')) return SimpleIcons.youtube;
    if (service.contains('applemusic')) return SimpleIcons.applemusic;
    if (service.contains('playstation')) return SimpleIcons.playstation;
    return null;
  }

  Color _colorFor(String service) {
    if (service.contains('netflix')) return SimpleIconColors.netflix;
    if (service.contains('spotify')) return SimpleIconColors.spotify;
    if (service.contains('youtube')) return SimpleIconColors.youtube;
    if (service.contains('applemusic')) return SimpleIconColors.applemusic;
    if (service.contains('playstation')) return SimpleIconColors.playstation;
    if (service.contains('disney')) return const Color(0xFF113CCF);
    if (service.contains('amazon') || service.contains('prime')) {
      return const Color(0xFF43B6E8);
    }
    if (service.contains('xbox')) return const Color(0xFF107C10);
    if (service.contains('exxen')) return const Color(0xFFE31B54);
    if (service.contains('blutv')) return const Color(0xFF40A9FF);
    if (service == 'gain') return const Color(0xFFF0445E);
    if (service.contains('music')) return const Color(0xFFC4B5FD);
    return const Color(0xFFB8B2CC);
  }
}

class _ServiceFallback extends StatelessWidget {
  const _ServiceFallback({
    required this.service,
    required this.color,
    required this.size,
  });

  final String service;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (service.contains('disney')) {
      return Text(
        'D+',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      );
    }
    if (service.contains('amazon') || service.contains('prime')) {
      return Text(
        'prime',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size * .25,
        ),
      );
    }
    if (service.contains('apple')) {
      return Icon(Icons.apple, size: 38, color: color);
    }
    if (service.contains('music')) {
      return Icon(Icons.music_note_rounded, size: 38, color: color);
    }
    if (service.contains('video') || service.contains('stream')) {
      return Icon(Icons.movie_rounded, size: size * .68, color: color);
    }
    if (service.contains('xbox')) {
      return Icon(Icons.sports_esports_rounded, size: size * .68, color: color);
    }
    if (service.contains('exxen')) {
      return Text(
        'X',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size * .58,
        ),
      );
    }
    if (service.contains('blutv')) {
      return Text(
        'Blu',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size * .36,
        ),
      );
    }
    if (service == 'gain') {
      return Text(
        'gain',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size * .3,
        ),
      );
    }
    if (service.contains('playstation')) {
      return Icon(Icons.sports_esports_rounded, size: size * .68, color: color);
    }
    return Icon(Icons.subscriptions_rounded, size: size * .64, color: color);
  }
}
