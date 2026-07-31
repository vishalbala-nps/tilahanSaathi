/// Sentinel used by [FarmProfile.copyWith] to distinguish "leave unchanged"
/// from "explicitly set to null" for nullable fields.
const _unset = Object();

class FarmProfile {
  const FarmProfile({
    this.landName,
    this.state,
    this.district,
    this.landAreaAcres = 2.0,
    this.soilType,
    this.waterAvailability,
    this.currentCrop,
    this.planningSeason,
  });

  final String? landName;
  final String? state;
  final String? district;
  final double landAreaAcres;
  final String? soilType;
  final String? waterAvailability;
  final String? currentCrop;
  final String? planningSeason;

  bool get isComplete =>
      landName != null &&
      state != null &&
      district != null &&
      soilType != null &&
      waterAvailability != null &&
      planningSeason != null;

  FarmProfile copyWith({
    Object? landName = _unset,
    Object? state = _unset,
    Object? district = _unset,
    double? landAreaAcres,
    Object? soilType = _unset,
    Object? waterAvailability = _unset,
    Object? currentCrop = _unset,
    Object? planningSeason = _unset,
  }) {
    return FarmProfile(
      landName: identical(landName, _unset) ? this.landName : landName as String?,
      state: identical(state, _unset) ? this.state : state as String?,
      district: identical(district, _unset) ? this.district : district as String?,
      landAreaAcres: landAreaAcres ?? this.landAreaAcres,
      soilType: identical(soilType, _unset) ? this.soilType : soilType as String?,
      waterAvailability: identical(waterAvailability, _unset)
          ? this.waterAvailability
          : waterAvailability as String?,
      currentCrop: identical(currentCrop, _unset) ? this.currentCrop : currentCrop as String?,
      planningSeason:
          identical(planningSeason, _unset) ? this.planningSeason : planningSeason as String?,
    );
  }
}
