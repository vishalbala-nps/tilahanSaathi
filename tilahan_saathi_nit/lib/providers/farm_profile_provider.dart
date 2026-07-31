import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/models/farm_profile.dart';

class FarmProfileNotifier extends StateNotifier<FarmProfile> {
  FarmProfileNotifier() : super(const FarmProfile());

  void setLandName(String? value) {
    state = state.copyWith(landName: value);
  }

  void setState(String? value) {
    state = state.copyWith(
      state: value,
      district: null,
    );
  }

  void setDistrict(String? value) {
    state = state.copyWith(district: value);
  }

  void setLandAreaAcres(double value) {
    state = state.copyWith(landAreaAcres: value);
  }

  void setSoilType(String? value) {
    state = state.copyWith(soilType: value);
  }

  void setWaterAvailability(String? value) {
    state = state.copyWith(waterAvailability: value);
  }

  void setCurrentCrop(String? value) {
    state = state.copyWith(currentCrop: value);
  }

  void setPlanningSeason(String? value) {
    state = state.copyWith(planningSeason: value);
  }

  void reset() {
    state = const FarmProfile();
  }
}

final farmProfileProvider =
    StateNotifierProvider<FarmProfileNotifier, FarmProfile>(
  (ref) => FarmProfileNotifier(),
);