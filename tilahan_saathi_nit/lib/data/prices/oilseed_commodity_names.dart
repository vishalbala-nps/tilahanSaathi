/// Exact Agmarknet `commodity_name` strings that correspond to one of our
/// tracked `OilseedCrop` values — mirrors the backend's
/// `OILSEED_CROP_TO_COMMODITY_NAME` (`api/app/services/price_sync.py`).
///
/// The `/crops` endpoint's `commodity_group` field is raw external metadata
/// from Agmarknet (`cmdt_grp_name`) and isn't a reliable "is this an oilseed"
/// signal — it's whatever grouping Agmarknet happens to use, not something
/// our backend controls. This fixed name list is the actual source of truth
/// the backend itself uses, so it's duplicated here rather than trusting
/// `commodity_group`. Castor and linseed are absent on purpose — Agmarknet
/// doesn't track them, so they never appear in `/crops` either.
const oilseedCommodityNames = <String>{
  'Groundnut',
  'Soyabean',
  'Sesamum(Sesame,Gingelly,Til)',
  'Mustard',
  'Sunflower/Sunflower Seed',
  'Safflower',
  'Niger Seed(Ramtil)',
};
