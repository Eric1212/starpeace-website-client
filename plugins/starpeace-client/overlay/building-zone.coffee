
export default class BuildingZone
  @TYPES:
    NONE:
      value: 0
      type: 'NONE'
      color: 0x000000
    RESERVED:
      value: 1
      type: 'RESERVED'
      color: 0x800000
    RESIDENTIAL:
      value: 2
      type: 'RESIDENTIAL'
      color: 0x008080
    HC_RESIDENTIAL:
      value: 3
      type: 'HC_RESIDENTIAL'
      color: 0xC0FFBB
    MC_RESIDENTIAL:
      value: 4
      type: 'MC_RESIDENTIAL'
      color: 0x4FA343
    LC_RESIDENTIAL:
      value: 5
      type: 'LC_RESIDENTIAL'
      color: 0x23481E
    INDUSTRIAL:
      value: 6
      type: 'INDUSTRIAL'
      color: 0xD7D988
    COMMERCIAL:
      value: 7
      type: 'COMMERCIAL'
      color: 0x4974D8
    CIVICS:
      value: 8
      type: 'CIVICS'
      color: 0xFFFFFF
    OFFICES:
      value: 9
      type: 'OFFICES'
      color: 0x394488
    SERVICE:
      value: 10
      type: 'SERVICE'
      color: 0x4974D8
    WAREHOUSE:
      value: 11
      type: 'WAREHOUSE'
      color: 0xD7D988
    MAUSOLEUM:
      value: 12
      type: 'MAUSOLEUM'
      color: 0xFFFFFF

  @from_string: (type) -> if BuildingZone.TYPES[type]? then BuildingZone.TYPES[type] else BuildingZone.TYPES.NONE

  @zones_match: (city_zone, building_zone) ->
    return true if city_zone == building_zone || city_zone == BuildingZone.TYPES.NONE
    return true if building_zone == BuildingZone.TYPES.SERVICE && city_zone == BuildingZone.TYPES.COMMERCIAL
    return true if building_zone == BuildingZone.TYPES.WAREHOUSE && city_zone == BuildingZone.TYPES.INDUSTRIAL
    return true if building_zone == BuildingZone.TYPES.LC_RESIDENTIAL && city_zone == BuildingZone.TYPES.RESIDENTIAL
    return true if building_zone == BuildingZone.TYPES.MC_RESIDENTIAL && city_zone == BuildingZone.TYPES.RESIDENTIAL
    return true if building_zone == BuildingZone.TYPES.HC_RESIDENTIAL && city_zone == BuildingZone.TYPES.RESIDENTIAL
    false

  @deserialize_chunk: (width, height, data) ->
    zones = new Array(width * height)
    type_names = Object.keys(BuildingZone.TYPES)

    for y in [0...height]
      for x in [0...width]
        type_value = parseInt(data[y * width + x], 16)
        type = if type_value > 0 && type_value < type_names.length then BuildingZone.TYPES[type_names[type_value]] else null
        zones[y * width + x] = type || BuildingZone.TYPES.NONE

    zones
