<template lang='pug'>
#research-menu-container.card.is-starpeace.has-header
  .card-header
    .card-header-title {{translate('ui.menu.research.header')}}
  .card-content.sp-menu-background.overall-container
    .field.filter-input-container
      .control.has-icons-left.is-expanded
        input.input(type="text", :placeholder="translate('misc.filter')")
        span.icon.is-left
          font-awesome-icon(:icon="['fas', 'search-location']")

    aside.sp-menu.sp-scrollbar
      p.sp-section(v-for='item in sections')
        a(v-on:click.stop.prevent="item.expanded = !item.expanded")
          span(v-show="item.children.length && !item.expanded")
            font-awesome-icon(:icon="['fas', 'plus-square']")
          span(v-show="item.children.length && item.expanded")
            font-awesome-icon(:icon="['fas', 'minus-square']")
          span.sp-folder-icon(v-show="!item.children.length")
            font-awesome-icon(:icon="['fas', 'square']")
          span.sp-section-label {{item.name}}

        ul.sp-section-items(v-show="item.children.length && item.expanded")
          li(v-for="child in item.children")
            a.is-menu-item(v-on:click.stop.prevent="select_inventions(item.category, child.industry_type)", :class="section_item_class(item, child)")
              industry-type-icon(:industry_type="child.industry_type", :class="['sp-section-item-image', 'sp-indusry-icon']", :default_research='true')
              span.sp-section-item-label {{child.name}}

</template>

<script lang='coffee'>
import IndustryTypeIcon from '~/components/misc/industry-type-icon.vue'

import IndustryCategory from '~/plugins/starpeace-client/industry/industry-category.coffee'
import IndustryType from '~/plugins/starpeace-client/industry/industry-type.coffee'

export default
  components:
    'industry-type-icon': IndustryTypeIcon

  props:
    managers: Object
    client_state: Object

  data: ->
    menu_visible: @client_state?.menu?.is_visible('research')

    filter_input_value: ''

    sections: []

  mounted: ->
    @client_state?.menu?.subscribe_menu_listener =>
      @menu_visible = @client_state?.menu?.is_visible('research')

    @client_state?.options?.subscribe_options_listener => @refresh_sections()

  watch:
    is_visible: (new_value, old_value) ->
      @refresh_sections() if new_value
    selected_category: (new_value, old_value) ->
      @refresh_sections()
    company_id: (new_value, old_value) ->
      @refresh_sections()

  computed:
    is_visible: -> @client_state.workflow_status == 'ready' && @menu_visible

    selected_category: -> @client_state.interface.inventions_selected_category
    selected_industry_type: -> @client_state.interface.inventions_selected_industry_type

    company_id: -> @client_state.player.company_id

  methods:
    translate: (text_key) -> @managers?.translation_manager?.text(text_key)

    filter_class: (type) -> ""
    section_item_class: (item, child) -> { 'is-active': @selected_category == item.category && @selected_industry_type == child.industry_type }

    refresh_sections: () ->
      sections_by_category = {}
      for invention in @inventions_for_company()
        unless sections_by_category[invention.category]?
          category = IndustryCategory.CATEGORIES[invention.category]
          sections_by_category[invention.category] = {
            name: if category? then @translate(category.text_key) else invention.category
            category: invention.category
            expanded: invention.category == @selected_category
            children_by_type: {}
          }
        type = invention.industry_type || 'GENERAL'
        unless sections_by_category[invention.category].children_by_type[type]?
          industry_type = IndustryType.TYPES[type]
          sections_by_category[invention.category].children_by_type[type] = {
            name: if industry_type? then @translate(industry_type.text_key) else type
            industry_type: type
          }

      sections = []
      for category in ['SERVICE', 'INDUSTRY', 'LOGISTICS', 'COMMERCE', 'CIVIC', 'REAL_ESTATE']
        if sections_by_category[category]?
          section = sections_by_category[category]
          section.children = _.sortBy(_.values(section.children_by_type), (child) -> child.name)
          sections.push section

      @sections = sections

    inventions_for_company: -> @client_state.inventions_for_company()

    select_inventions: (category, industry_type) ->
      @client_state.interface.inventions_selected_category = category
      @client_state.interface.inventions_selected_industry_type = industry_type

</script>

<style lang='sass' scoped>
$sp-primary: #6ea192
$sp-primary-bg: #395950

#research-menu-container
  grid-column-start: 1
  grid-column-end: 2
  grid-row-start: 2
  grid-row-end: 5
  margin: 0
  overflow: hidden
  z-index: 1150


.card
  overflow: hidden

  .card-header
    min-height: 3.4rem

  .card-header-title
    font-size: 1.15rem
    letter-spacing: .2rem
    padding-top: .65rem

  .card-content
    height: calc(100% - 3.6rem)
    padding: 0

    &.overall-container
      padding-top: .5rem
      position: relative

.filter-input-container
  height: 3.5rem
  margin-bottom: .5rem
  padding: .5rem 1rem

  input
    &:focus
      border-color: $sp-primary !important

.sp-menu
  height: calc(100% - .5rem - 4rem)
  overflow-x: hidden
  overflow-y: scroll
  position: absolute
  width: 100%

  .sp-section
    border-bottom: 1px solid darken($sp-primary-bg, 7.5%)
    border-left: 0
    border-right: 0

    > a
      background-color: darken($sp-primary-bg, 3%)
      display: inline-block
      font-size: .8em
      letter-spacing: .1em
      padding: .75rem 1rem
      text-transform: uppercase
      width: 100%

      &:not(.disabled)
        &:hover,
        &.is-hover
          background-color: $sp-primary-bg

        &:active,
        &.is-active
          color: lighten($sp-primary, 20%)

    &:first-child
      border-top: 1px solid darken($sp-primary-bg, 7.5%)

    .sp-section-label
      margin-left: 1rem

    .sp-section-items
      a
        &.is-menu-item
          background-color: darken($sp-primary-bg, 15%)
          border-bottom: 1px solid darken($sp-primary-bg, 17.5%)
          display: inline-block
          padding-bottom: .75rem
          padding-top: .75rem
          position: relative
          width: 100%

          &:hover,
          &.is-hover
            background-color: darken($sp-primary-bg, 12.5%)
            border-bottom: 1px solid darken($sp-primary-bg, 15%)

          &:active,
          &.is-active
            background-color: darken($sp-primary-bg, 10%)
            border-bottom: 1px solid darken($sp-primary-bg, 12.5%)

      .sp-section-item-image
        border: 0
        padding: 0
        position: absolute
        left: .5rem
        top: calc(50% - .6rem)

      .sp-section-item-label
        font-size: 1.15rem
        margin-left: 2.3rem
        text-transform: capitalize

</style>
