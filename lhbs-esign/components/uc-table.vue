<template>
	<div class="uc-table-wrapper" :style="wrapperStyle">
    <!-- Toolbar -->
    <div v-if="title || searchable || $slots.toolbar" class="wf-tcard-toolbar" style="flex-shrink: 0;">
      <h3>{{ title }}<span v-if="showCount" class="uc-table-count"> ({{ filteredItems.length }})</span></h3>
      <v-spacer></v-spacer>
      <slot name="toolbar"></slot>
      <v-text-field v-if="searchable" v-model="search" :placeholder="searchPlaceholder" variant="outlined"
        density="compact" hide-details prepend-inner-icon="mdi-magnify" class="wf-search-field" clearable>
      </v-text-field>
    </div>

    <!-- Header Row (sticky) -->
    <div class="wf-trow wf-trow-header" :style="gridStyle" style="flex-shrink: 0;">
      <div v-for="col in headers" :key="col.key" :style="colStyle(col)">
        {{ col.title }}
      </div>
    </div>

    <!-- Loading bar -->
    <v-progress-linear v-if="loading" indeterminate color="primary" height="3" style="flex-shrink: 0;">
    </v-progress-linear>

    <!-- Scrollable Body -->
    <div class="uc-table-body" :style="bodyScrollStyle">
      <!-- Data Rows -->
      <template v-if="!loading">
        <div v-for="(item, idx) in paginatedItems" :key="item[itemValue] || idx" class="wf-trow" :style="gridStyle"
          @click="$emit('row-click', item)">
          <div v-for="col in headers" :key="col.key" :style="colStyle(col)">
            <slot :name="'item.' + col.key" :item="item" :index="idx" :value="item[col.key]">
              {{ item[col.key] != null ? item[col.key] : '-' }}
            </slot>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="filteredItems.length === 0" class="uc-table-empty">
          <slot name="empty">
            <v-icon size="32" color="grey-lighten-1" class="mb-2">{{ emptyIcon }}</v-icon>
            <div class="uc-table-empty-text">{{ emptyText }}</div>
          </slot>
        </div>
      </template>
    </div>

    <!-- Pagination -->
    <div v-if="pagination && totalPages > 1" class="uc-table-pagination" style="flex-shrink: 0;">
      <span class="uc-table-pagination-info">
        {{ paginationStart }}-{{ paginationEnd }} / {{ filteredItems.length }}
      </span>
      <v-btn icon size="x-small" variant="text" :disabled="currentPage <= 1" @click="currentPage--">
        <v-icon size="16">mdi-chevron-left</v-icon>
      </v-btn>
      <v-btn icon size="x-small" variant="text" :disabled="currentPage >= totalPages" @click="currentPage++">
        <v-icon size="16">mdi-chevron-right</v-icon>
      </v-btn>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-table',
  props: {
    headers:   { type: Array, default: function () { return [] } },
    items:     { type: Array, default: function () { return [] } },
    loading:   { type: Boolean, default: false },
    hover:     { type: Boolean, default: true },
    rounded:   { type: [Boolean, String], default: true }, // true = 8px, false = 0, string = custom
    maxHeight: { type: String, default: '' }, // e.g. 'calc(100vh - 200px)' to contain scroll
    itemValue: { type: String, default: 'id' },
    title:     { type: String, default: '' },
    showCount: { type: Boolean, default: false },
    searchable: { type: Boolean, default: false },
    searchPlaceholder: { type: String, default: 'Tìm kiếm...' },
    pagination: { type: Boolean, default: false },
    itemsPerPage: { type: Number, default: 10 },
    emptyText: { type: String, default: 'Không có dữ liệu' },
    emptyIcon: { type: String, default: 'mdi-tray-remove' }
  },
  emits: ['row-click'],
  data: function () {
    return {
      search: '',
      currentPage: 1
    }
  },
  computed: {
    wrapperStyle: function () {
      var s = {}
      if (this.rounded === false || this.rounded === '0') s.borderRadius = '0'
      else if (typeof this.rounded === 'string') s.borderRadius = this.rounded
      return s
    },
    bodyScrollStyle: function () {
      if (this.maxHeight) {
        return { 
          'max-height': this.maxHeight, 
          'min-height': this.maxHeight, 
          'overflow-y': 'auto' 
        }
      }
      return {}
    },
    gridStyle: function () {
      var cols = this.headers.map(function (col) {
        if (col.width) {
          return typeof col.width === 'number' ? col.width + 'px' : col.width
        }
        return '1fr'
      })
      return { display: 'grid', gridTemplateColumns: cols.join(' '), alignItems: 'center' }
    },
    filteredItems: function () {
      if (!this.search) return this.items
      var q = this.search.toLowerCase().trim()
      var headers = this.headers
      return this.items.filter(function (item) {
        return headers.some(function (col) {
          var val = item[col.key]
          return val != null && String(val).toLowerCase().indexOf(q) >= 0
        })
      })
    },
    totalPages: function () {
      if (!this.pagination || this.itemsPerPage <= 0) return 1
      return Math.ceil(this.filteredItems.length / this.itemsPerPage)
    },
    paginatedItems: function () {
      if (!this.pagination) return this.filteredItems
      var start = (this.currentPage - 1) * this.itemsPerPage
      return this.filteredItems.slice(start, start + this.itemsPerPage)
    },
    paginationStart: function () {
      return (this.currentPage - 1) * this.itemsPerPage + 1
    },
    paginationEnd: function () {
      var end = this.currentPage * this.itemsPerPage
      return end > this.filteredItems.length ? this.filteredItems.length : end
    }
  },
  watch: {
    search: function () { this.currentPage = 1 }
  },
  methods: {
    colStyle: function (col) {
      var s = {}
      if (col.align === 'center') s.textAlign = 'center'
      if (col.align === 'right') s.textAlign = 'right'
      return s
    }
  }
	}
</script>