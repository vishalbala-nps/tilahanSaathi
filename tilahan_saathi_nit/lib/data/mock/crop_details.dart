import 'package:flutter/material.dart';
import 'package:tilahan_saathi/features/crop_details/crop_detail_model.dart';

class CropDetailsData {
  static const groundnut = CropDetail(
    name: 'Groundnut',
    icon: 'assets/icons/groundnut.svg',
    color: Color(0xFF9C6B3E),
    suitabilityScore: 92,
    reason: 'Ideal for your loamy soil and Kharif season. Groundnut '
        'thrives in well-drained soils with moderate rainfall, matching '
        'your farm conditions perfectly.',
    growingDuration: '90–110 days',
    waterRequirement: '400–600 mm',
    season: 'Kharif',
    whyRecommended: 'Groundnut matches your loamy soil type and Kharif '
        'planning season. Your rainfed setup provides just enough water for '
        'this drought-tolerant oilseed, and the market demand in your region '
        'ensures a good price at harvest time.',
    thingsToConsider: [
      'Requires well-drained soil; avoid waterlogged areas',
      'Apply gypsum at flowering stage for better pod development',
      'Monitor for aphids and leaf spot during monsoon',
      'Harvest within 2–3 days of pulling to avoid pod damage',
    ],
    expectedYield: 800,
    expectedRevenue: 24000,
  );

  static const sesame = CropDetail(
    name: 'Sesame',
    icon: 'assets/icons/sesame.svg',
    color: Color(0xFFF6C445),
    suitabilityScore: 87,
    reason: 'Low water need suits your rainfed setup. Sesame is an '
        'excellent oilseed for dryland farming with strong market demand.',
    growingDuration: '85–100 days',
    waterRequirement: '350–500 mm',
    season: 'Kharif',
    whyRecommended: 'Sesame requires less water than most oilseeds, '
        'making it ideal for your rainfed conditions. It matures quickly and '
        'has consistently good market prices at local mandis.',
    thingsToConsider: [
      'Sow when soil temperature is above 25°C for best germination',
      'Thin seedlings to 15–20 cm spacing after 3 weeks',
      'Harvest early in the morning to minimize shattering losses',
      'Store dried pods in airtight containers to prevent oil rancidity',
    ],
    expectedYield: 450,
    expectedRevenue: 18000,
  );

  static const sunflower = CropDetail(
    name: 'Sunflower',
    icon: 'assets/icons/sunflower.svg',
    color: Color(0xFF61C9F8),
    suitabilityScore: 84,
    reason: 'Strong market demand in your region. Sunflower is a '
        'high-yield oilseed with good return on investment.',
    growingDuration: '80–100 days',
    waterRequirement: '450–650 mm',
    season: 'Kharif',
    whyRecommended: 'Sunflower has the highest oil content among common '
        'oilseeds and commands premium prices at procurement centers. '
        'Your soil type supports good root development for this crop.',
    thingsToConsider: [
      'Plant in rows 60 cm apart with 30 cm spacing between plants',
      'Use bird scaring methods during grain filling stage',
      'Apply nitrogen fertilizer in split doses',
      'Rotate with legumes to maintain soil fertility',
    ],
    expectedYield: 1200,
    expectedRevenue: 30000,
  );

  static const List<CropDetail> all = [
    groundnut,
    sesame,
    sunflower,
  ];
}