
import moment from 'moment'

import EventListener from '~/plugins/starpeace-client/state/event-listener.coffee'

import CoreState from '~/plugins/starpeace-client/state/core/core-state.coffee'

import BookmarkState from '~/plugins/starpeace-client/state/player/bookmark-state.coffee'
import CorporationState from '~/plugins/starpeace-client/state/player/corporation-state.coffee'
import IdentityState from '~/plugins/starpeace-client/state/player/identity-state.coffee'
import PlanetState from '~/plugins/starpeace-client/state/player/planet-state.coffee'
import PlayerState from '~/plugins/starpeace-client/state/player/player-state.coffee'
import SessionState from '~/plugins/starpeace-client/state/player/session-state.coffee'

import CameraState from '~/plugins/starpeace-client/state/ui/camera-state.coffee'
import InterfaceState from '~/plugins/starpeace-client/state/ui/interface-state.coffee'
import MenuState from '~/plugins/starpeace-client/state/ui/menu-state.coffee'
import MusicState from '~/plugins/starpeace-client/state/ui/music-state.coffee'

import TimeUtils from '~/plugins/starpeace-client/utils/time-utils.coffee'
import Utils from '~/plugins/starpeace-client/utils/utils.coffee'
import Logger from '~/plugins/starpeace-client/logger.coffee'

MAX_FAILED_AUTH_ERRORS = 3

export default class ClientState
  constructor: (@options, @ajax_state) ->
    @event_listener = new EventListener()

    @core = new CoreState()

    @bookmarks = new BookmarkState()
    @corporation = new CorporationState()
    @identity = new IdentityState()
    @session = new SessionState()
    @player = new PlayerState()
    @planet = new PlanetState()

    @camera = new CameraState()
    @interface = new InterfaceState(@options)
    @menu = new MenuState()
    @music = new MusicState()

    @reset_full_state()

    @core.corporation_cache.subscribe_corporation_metadata_listener => @update_state()
    @core.planets_cache.subscribe_planets_metadata_listener => @update_state()
    @core.tycoon_cache.subscribe_tycoon_metadata_listener => @update_state()

    @core.building_library.subscribe_listener => @update_state()
    @core.concrete_library.subscribe_listener => @update_state()
    @core.effect_library.subscribe_listener => @update_state()
    @core.invention_library.subscribe_listener => @update_state()
    @core.land_library.subscribe_listener => @update_state()
    @core.map_library.subscribe_listener => @update_state()
    @core.news_library.subscribe_listener => @update_state()
    @core.overlay_library.subscribe_listener => @update_state()
    @core.plane_library.subscribe_listener => @update_state()
    @core.road_library.subscribe_listener => @update_state()
    @core.translations_library.subscribe_listener => @update_state()

    @bookmarks.subscribe_bookmarks_metadata_listener => @update_state()
    @corporation.subscribe_company_buildings_listener => @update_state()
    @corporation.subscribe_company_inventions_listener => @update_state()
    @identity.subscribe_visa_type_listener => @update_state()
    @identity.subscribe_identity_listener => @update_state()
    @session.subscribe_session_token_listener => @update_state()
    @player.subscribe_planet_id_listener => @update_state()
    @player.subscribe_corporation_id_listener => @update_state()
    @player.subscribe_mail_metadata_listener => @update_state()
    @planet.subscribe_planet_details_listener => @update_state()


  subscribe_workflow_status_listener: (listener_callback) -> @event_listener.subscribe('workflow_status', listener_callback)
  notify_workflow_status_listeners: () -> @event_listener.notify_listeners('workflow_status')

  reset_full_state: () ->
    @webgl_warning = false
    @session_expired_warning = false

    @loading = false
    @workflow_status = 'initializing'

    @renderer_initialized = false
    @mini_map_renderer_initialized = false
    @construction_preview_renderer_initialized = false

    @ajax_state.reset_state()
    @core.corporation_cache.reset_state()
    @core.planets_cache.reset_state()
    @core.tycoon_cache.reset_state()

    @identity.reset_state()
    @session.reset_state()

    @reset_planet_state()

  reset_planet_state: () ->
    @initialized = false

    @plane_sprites = []

    @core.building_cache.reset_state()
    @core.company_cache.reset_state()

    @bookmarks.reset_state()
    @corporation.reset_state()
    @player.reset_state()
    @planet.reset_state()

    @camera.reset_state()
    @interface.reset_state()
    @menu.reset_state()
    @music.reset_state()

    @update_state()


  finish_initialization: () ->
    @initialized = true
    @update_state()

  update_state: () ->
    new_state = @determine_state()
    unless @workflow_status == new_state
      @workflow_status = new_state
      @notify_workflow_status_listeners()

  determine_state: () ->
    unless @initialized && @renderer_initialized && @mini_map_renderer_initialized && @construction_preview_renderer_initialized
      return 'pending_universe' unless @identity.galaxy_id? || @identity.galaxy_visa_type?
      return 'pending_identity' unless @identity.identity?
      return 'pending_session' unless @session.session_token?

      return 'pending_tycoon_metadata' if @state_needs_tycoon_metadata()
      return 'pending_galaxy_metadata' if @state_needs_galaxy_metadata()
      return 'pending_planet' unless @player.planet_id?

      planet_metadata = @core.planets_cache.metadata_for_id(@player.planet_id)
      return 'pending_galaxy_metadata' unless planet_metadata?

      return 'pending_assets' unless @core.has_assets(@options.language(), planet_metadata.map_id, planet_metadata.planet_type)
      return 'pending_planet_details' unless @planet.has_data()
      return 'pending_player_data' if @state_needs_player_data()
      return 'pending_initialization'

    'ready'

  state_needs_tycoon_metadata: () -> @is_galaxy_tycoon() && !@core.tycoon_cache.has_tycoon_metadata_fresh(@session.tycoon_id)
  state_needs_galaxy_metadata: () -> @identity.galaxy_id? && !@core.galaxy_cache.has_galaxy_metadata(@identity.galaxy_id)
  state_needs_player_data: () -> @is_tycoon() && @player.corporation_id? && (!@player.has_data() || !@corporation.has_data() || !@bookmarks.has_data())


  has_session: () -> @session.session_token? && @ajax_state.invalid_session_counter < MAX_FAILED_AUTH_ERRORS
  handle_authorization_error: () ->
    if @ajax_state.invalid_session_as_of? && TimeUtils.within_minutes(@ajax_state.invalid_session_as_of, 5)
      @ajax_state.invalid_session_counter += 1
    else
      @ajax_state.invalid_session_counter = 1
    @ajax_state.invalid_session_as_of = moment()

    if @ajax_state.invalid_session_counter >= MAX_FAILED_AUTH_ERRORS && !@session_expired_warning
      @session_expired_warning = true
      setTimeout (=> @reset_full_state()), 3000


  reset_to_galaxy: () ->
    setTimeout(=>
      @initialized = false
      @reset_planet_state()
    , 250)

  change_planet_id: (new_planet_visa_type, planet_id) ->
    @initialized = false
    setTimeout(=>
      @reset_planet_state()
      @player.planet_visa_type = new_planet_visa_type if new_planet_visa_type?.length
      @player.set_planet_id(planet_id) if planet_id?.length && @core.planets_cache.metadata_for_id(planet_id)?
    , 250)


  is_galaxy_tycoon: () -> @identity.galaxy_visa_type == 'tycoon' && @session.tycoon_id?
  is_tycoon: () -> @is_galaxy_tycoon() && @player.planet_visa_type == 'tycoon'

  current_tycoon_metadata: () -> if @session.tycoon_id? then @core.tycoon_cache.metadata_for_id(@session.tycoon_id) else null
  current_planet_metadata: () -> if @player.planet_id? then @core.planets_cache.metadata_for_id(@player.planet_id) else null
  current_corporation_metadata: () -> if @player.corporation_id? then @core.corporation_cache.metadata_for_id(@player.corporation_id) else null
  current_company_metadata: () -> if @player.company_id? then @core.company_cache.metadata_for_id(@player.company_id) else null

  current_planet_details: () -> if @player.planet_id? && @planet.details? then @planet.details else null

  enabled_for_planet_id: (planet_id) ->
    planet_metadata = @core.planets_cache.metadata_for_id(planet_id)
    if planet_metadata?.enabled? then planet_metadata.enabled else false

  name_for_planet_id: (planet_id) -> @core.planets_cache.metadata_for_id(planet_id)?.name
  name_for_tycoon_id: (tycoon_id) -> @core.tycoon_cache.metadata_for_id(tycoon_id)?.name
  name_for_corporation_id: (corporation_id) -> @core.corporation_cache.metadata_for_id(corporation_id)?.name

  seal_for_company_id: (company_id) -> @core.company_cache.metadata_for_id(company_id)?.seal_id || 'NONE'
  name_for_company_id: (company_id) -> @core.company_cache.metadata_for_id(company_id)?.name || ''

  selected_building_metadata: () -> if @interface.selected_building_id?.length then @core.building_cache.building_metadata_for_id(@interface.selected_building_id) else null

  inventions_for_company: ->
    if @is_tycoon()
      company_metadata = @current_company_metadata()
      if company_metadata? then @core.invention_library.metadata_for_seal_id(company_metadata.seal_id) else []
    else
      @core.invention_library.all_metadata()

  building_count_for_company: (building_definition_id) ->
    count = 0
    if @is_tycoon() && @player.company_id?.length
      for id in @corporation.building_ids_for_company(@player.company_id)
        metadata = @core.building_cache.building_metadata_for_id(id)
        count += 1 if metadata?.key == building_definition_id
      count
    count



  has_construction_requirements: (building_id) ->
    return false unless @player.company_id? && building_id?

    metadata = @core.building_library.metadata_by_id[building_id]
    return false unless metadata?

    completed_invention_ids = @corporation.completed_invention_ids_for_company(@player.company_id)
    for id in (metadata.required_invention_ids || [])
      return false unless completed_invention_ids.indexOf(id) >= 0

    (@current_corporation_metadata()?.cash || 0) >= metadata.cost()

  can_construct_building: () ->
    return false unless @has_construction_requirements(@interface.construction_building_id)
    @planet.can_place_building(@interface.construction_building_map_x, @interface.construction_building_map_y, @interface.construction_building_zone, @interface.construction_building_width, @interface.construction_building_height)

  initiate_building_construction: (building_id) ->
    view_center = @camera.center()
    iso_start = @camera.map_to_iso(view_center.x, view_center.y)

    metadata = @core.building_library.metadata_by_id[building_id]
    image_metadata = if metadata? then @core.building_library.images_by_id[metadata.image_id] else null

    @interface.construction_building_id = building_id
    @interface.construction_building_map_x = iso_start.i
    @interface.construction_building_map_y = iso_start.j
    @interface.construction_building_zone = metadata.zone
    @interface.construction_building_width = if image_metadata? then image_metadata.w else 1
    @interface.construction_building_height = if image_metadata? then image_metadata.h else 1

    @interface.toggle_zones() unless @interface.show_zones
