
###
global addResizeListener
global FPSMeter
global PIXI
###

import ChunkMap from '~/plugins/starpeace-client/map/chunk/chunk-map.coffee'
import GameMap from '~/plugins/starpeace-client/map/game-map.coffee'
import Viewport from '~/plugins/starpeace-client/renderer/camera/viewport.coffee'
import Layers from '~/plugins/starpeace-client/renderer/layer/layers.coffee'

export default class Renderer
  constructor: (@event_listener, @managers, @game_state, @ui_state) ->
    @initialized = false

    @event_listener.subscribe_map_data_listener (chunk_event) =>
      if @layers?.tile_item_cache?
        source_x = (chunk_event.info.chunk_x - 0) * ChunkMap.CHUNK_WIDTH - 10
        target_x = (chunk_event.info.chunk_x + 1) * ChunkMap.CHUNK_WIDTH + 10
        source_y = (chunk_event.info.chunk_y - 0) * ChunkMap.CHUNK_HEIGHT - 10
        target_y = (chunk_event.info.chunk_y + 1) * ChunkMap.CHUNK_HEIGHT + 10
        @layers.tile_item_cache.clear_cache(source_x, target_x, source_y, target_y)

  viewport: () ->
    @_viewport = new Viewport(@game_state, @renderer_width, @renderer_height) unless @_viewport?
    @_viewport

  update_offset: (render_container) ->
    if render_container? && render_container.offsetParent != null
      rect = render_container.getBoundingClientRect()
      @offset = {
        top: rect.top + document.body.scrollTop
        left: rect.left + document.body.scrollLeft
      }
    else
      @offset = null

  handle_resize: () ->
    render_container = document?.getElementById('render-container')
    @update_offset(render_container)
    @renderer_width = Math.ceil(render_container.offsetWidth)
    @renderer_height = Math.ceil(render_container.offsetHeight)
    @_viewport = new Viewport(@game_state, @renderer_width, @renderer_height)
    @application.renderer.resize(@renderer_width, @renderer_height)
    @initialize_map()

  initialize_application: () ->
    return unless document?

    user_agent = navigator?.userAgent || 'unknown'
    is_iphone = ~user_agent.indexOf('iPhone') || ~user_agent.indexOf('iPod')

    setTimeout(scrollTo, 0, 0, 1)

    render_container = document.getElementById('render-container')
    @update_offset(render_container)
    @renderer_width = Math.ceil(render_container.offsetWidth)
    @renderer_height = Math.ceil(render_container.offsetHeight)
    @_viewport = new Viewport(@game_state, @renderer_width, @renderer_height)
    @application = new PIXI.Application(@renderer_width, @renderer_height, {
      backgroundColor : 0x000000
    })
    @application.stage = new PIXI.display.Stage()
    @application.stage.group.enableSort = true

    render_container.appendChild(@application.view)

    fps_el = document?.getElementById('fps-container')
    @fps_meter = new FPSMeter(fps_el, { theme: 'colorful' }) if fps_el?

    addResizeListener(render_container, => @handle_resize())

  initialize_map: () ->
    @layers?.remove_layers(@application.stage)
    @layers?.destroy()
    @layers = new Layers(@, @managers.building_manager, @managers.effect_manager, @managers.plane_manager, @game_state, @ui_state)
    @layers.add_layers(@application.stage)

  initialize: () ->
    @initialize_application() unless @application?

    planet = @game_state.current_planet
    land_manifest = @managers.planet_type_manifest_manager.planet_type_manifest[planet.planet_type]
    map_texture = @managers.planetary_manager.map_id_texture[planet.map_id]

    @game_state.game_map = new GameMap(@event_listener, @managers.building_manager, @managers.road_manager, @managers.overlay_manager, land_manifest, map_texture, @ui_state)
    @initialize_map()

    @game_state.loading = true
    setTimeout (=> @game_state.loading = false), 500

    @game_state.initialized = true
    @initialized = true

  tick: () ->
    @fps_meter.tickStart() if @fps_meter?
    current_time = new Date().getTime()

    @update_offset(document?.getElementById('render-container')) unless @offset?

    @layers.refresh() if @layers?.should_refresh()
    @layers?.refresh_planes()

    @fps_meter.tick() if @fps_meter?
