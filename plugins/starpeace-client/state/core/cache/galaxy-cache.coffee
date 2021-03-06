
import _ from 'lodash'
import moment from 'moment'
import Vue from 'vue'

import EventListener from '~/plugins/starpeace-client/state/event-listener.coffee'

import TimeUtils from '~/plugins/starpeace-client/utils/time-utils.coffee'
import Logger from '~/plugins/starpeace-client/logger.coffee'

export default class GalaxyCache
  constructor: () ->
    @event_listener = new EventListener()
    @reset_state()

  reset_state: () ->
    @galaxy_configuration_by_id = {}
    @galaxy_metadata_by_id = {}

  subscribe_configuration_listener: (listener_callback) -> @event_listener.subscribe('galaxy_cache.configuration', listener_callback)
  notify_configuration_listeners: () -> @event_listener.notify_listeners('galaxy_cache.configuration')
  subscribe_metadata_listener: (listener_callback) -> @event_listener.subscribe('galaxy_cache.metadata', listener_callback)
  notify_metadata_listeners: () -> @event_listener.notify_listeners('galaxy_cache.metadata')

  galaxy_configuration: (galaxy_id) -> @galaxy_configuration_by_id[galaxy_id]
  load_galaxy_configuration: (galaxy_id, galaxy_configuration) ->
    Vue.set(@galaxy_configuration_by_id, galaxy_id, galaxy_configuration)
    @notify_configuration_listeners()

  has_galaxy_metadata: (galaxy_id) -> @galaxy_metadata_by_id[galaxy_id]?
  galaxy_metadata: (galaxy_id) -> @galaxy_metadata_by_id[galaxy_id]
  load_galaxy_metadata: (galaxy_id, galaxy_metadata) ->
    Vue.set(@galaxy_metadata_by_id, galaxy_id, galaxy_metadata)
    @notify_metadata_listeners()

  change_galaxy_id: (old_galaxy_id, new_galaxy_id) ->
    if @galaxy_configuration_by_id[old_galaxy_id]?
      @galaxy_configuration_by_id[old_galaxy_id].id = new_galaxy_id
      Vue.set(@galaxy_configuration_by_id, new_galaxy_id, @galaxy_configuration_by_id[old_galaxy_id])
      Vue.delete(@galaxy_configuration_by_id, old_galaxy_id)
      @notify_configuration_listeners()
    if @galaxy_metadata_by_id[old_galaxy_id]?
      Vue.set(@galaxy_metadata_by_id, new_galaxy_id, @galaxy_metadata_by_id[old_galaxy_id])
      Vue.delete(@galaxy_metadata_by_id, old_galaxy_id)
      @notify_metadata_listeners()

  remove_galaxy: (galaxy_id) ->
    Vue.delete(@galaxy_configuration_by_id, galaxy_id)
    Vue.delete(@galaxy_metadata_by_id, galaxy_id)
    @notify_configuration_listeners()
    @notify_metadata_listeners()
