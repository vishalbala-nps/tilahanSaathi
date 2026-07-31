import 'package:flutter/material.dart';

class CropDetail {
  const CropDetail({
    required this.name,
    required this.icon,
    required this.color,
    required this.suitabilityScore,
    required this.reason,
    required this.growingDuration,
    required this.waterRequirement,
    required this.season,
    required this.whyRecommended,
    required this.thingsToConsider,
    required this.expectedYield,
    required this.expectedRevenue,
  });

  final String name;
  final String icon;
  final Color color;
  final int suitabilityScore;
  final String reason;
  final String growingDuration;
  final String waterRequirement;
  final String season;
  final String whyRecommended;
  final List<String> thingsToConsider;
  final double expectedYield;
  final double expectedRevenue;
}