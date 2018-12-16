
import AssetLibrary from '~/plugins/starpeace-client/state/core/library/asset-library.coffee'
import TextureAtlasCache from '~/plugins/starpeace-client/state/core/texture-atlas-cache.coffee'

import Logger from '~/plugins/starpeace-client/logger.coffee'

export default class OverlayLibrary extends AssetLibrary
  constructor: () ->
    super()

    @texture_cache = new TextureAtlasCache()

    @metadata_by_id = {}

  has_metadata: () -> Object.keys(@metadata_by_id).length
  has_assets: () -> @has_metadata() && @texture_cache.has_assets()

  load_overlay_metadata: (overlay_metadata) ->
    @metadata_by_id[overlay.id] = overlay for overlay in overlay_metadata
    @notify_listeners()

  load_required_atlases: (atlases) ->
    @texture_cache.set_required_atlases(atlases)

  load_atlas: (atlas_key, atlas) ->
    @texture_cache.load_atlas(atlas_key, atlas)
    @notify_listeners()
