
EN_STRINGS = {
  'industry.category.none.label': 'None'
  'industry.category.civics.label': 'Civics'
  'industry.category.commerce.label': 'Commerce'
  'industry.category.industries.label': 'Industries'
  'industry.category.logistics.label': 'Logistics'
  'industry.category.offices.label': 'Offices'
  'industry.category.residentials.label': 'Residentials'
  'industry.category.services.label': 'Services'

  'industry.type.automobile.label': 'Automobile'
  'industry.type.banking.label': 'Banking'
  'industry.type.bar.label': 'Bars'
  'industry.type.book.label': 'Book'
  'industry.type.chemical.label': 'Chemical'
  'industry.type.clothes.label': 'Clothing'
  'industry.type.coal.label': 'Coal'
  'industry.type.college.label': 'College'
  'industry.type.compact_disc.label': 'Compact Disc'
  'industry.type.computer.label': 'Computer'
  'industry.type.computer_services.label': 'Computer Services'
  'industry.type.construction.label': 'Construction'
  'industry.type.crude_oil.label': 'Crude Oil'
  'industry.type.electronic_component.label': 'Electronic Component'
  'industry.type.fabric.label': 'Fabric'
  'industry.type.fast_food.label': 'Fast Food'
  'industry.type.farming.label': 'Farming'
  'industry.type.fire.label': 'Fire Safety'
  'industry.type.funeral_services.label': 'Funeral Services'
  'industry.type.furniture.label': 'Furniture'
  'industry.type.garbage.label': 'Garbage'
  'industry.type.gasoline.label': 'Gasoline'
  'industry.type.hospital.label': 'Hospital'
  'industry.type.household_appliance.label': 'Household Appliances'
  'industry.type.headquarters.label': 'Headquarters'
  'industry.type.hc_residential.label': 'High-class Residential'
  'industry.type.lc_residential.label': 'Low-class Residential'
  'industry.type.legal_services.label': 'Legal Services'
  'industry.type.liquor.label': 'Liquor'
  'industry.type.machinery.label': 'Machinery'
  'industry.type.market.label': 'Market'
  'industry.type.mc_residential.label': 'Middle-class Residential'
  'industry.type.metal.label': 'Metallurgy'
  'industry.type.movie.label': 'Movie'
  'industry.type.museum.label': 'Museum'
  'industry.type.office.label': 'Office'
  'industry.type.ore.label': 'Ore'
  'industry.type.paper.label': 'Paper'
  'industry.type.park.label': 'Park'
  'industry.type.pharmaceutical.label': 'Pharmaceutical'
  'industry.type.plastic.label': 'Plastic'
  'industry.type.police.label': 'Police'
  'industry.type.prison.label': 'Prison'
  'industry.type.processed_food.label': 'Processed Food'
  'industry.type.raw_chemical.label': 'Raw Chemical'
  'industry.type.restaurant.label': 'Restaurant'
  'industry.type.school.label': 'School'
  'industry.type.silicon.label': 'Silicon'
  'industry.type.stone.label': 'Stone'
  'industry.type.television.label': 'Television'
  'industry.type.timber.label': 'Timber'
  'industry.type.toy.label': 'Toy'
  'industry.type.warehouse.label': 'Warehouse'
}

export default class TranslationManager
  constructor: (@asset_manager, @ajax_state, @client_state, @options) ->
    @client_state.core.translations_library.load_translations_partial('EN', _.map(EN_STRINGS, (value, key) -> { id:key, value:value }))

  queue_asset_load: () ->
    current_language = @options.language()
    return if @client_state.core.translations_library.has_metadata(current_language) || @ajax_state.is_locked('assets.translations', current_language)

    @ajax_state.lock('assets.translations', current_language)
    @asset_manager.queue("translations.#{current_language.toLowerCase()}", "./translations.#{current_language.toLowerCase()}.json", (resource) =>
      @client_state.core.translations_library.load_translations(current_language, resource.data.translations)
      @ajax_state.unlock('assets.translations', current_language)
    )

  text: (key) ->
    @client_state.core.translations_library.translations_by_language_code[@options.language()]?[key]