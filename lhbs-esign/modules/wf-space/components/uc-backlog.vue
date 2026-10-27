<template>
	<div class="wf-backlog pa-4">
    <!-- Toolbar -->
    <div class="d-flex align-center justify-space-between mb-4">
      <div class="d-flex align-center ga-3">
        <span class="text-subtitle-2 font-weight-bold text-grey-darken-3">Backlog</span>
        <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
          {{ filteredItems.length }}
        </v-chip>
      </div>
      <div class="d-flex align-center ga-2">
        <!-- Filter by Priority -->
        <v-select v-model="filterPriority" :items="priorityFilterOptions" item-title="label" item-value="value"
          placeholder="Độ ưu tiên" variant="outlined" density="compact" hide-details clearable
          style="min-width: 140px; max-width: 160px; font-size: 12px;" class="wf-ant-input bg-white" />
        <!-- Filter by Status -->
        <v-select v-model="filterStatus" :items="statusFilterOptions" item-title="label" item-value="value"
          placeholder="Trạng thái" variant="outlined" density="compact" hide-details clearable
          style="min-width: 140px; max-width: 160px; font-size: 12px;" class="wf-ant-input bg-white" />
        <!-- Search -->
        <v-text-field v-model="search" placeholder="Tìm kiếm..." variant="outlined" density="compact" hide-details
          prepend-inner-icon="mdi-magnify" clearable style="min-width: 200px; font-size: 12px;"
          class="wf-ant-input bg-white" />
      </div>
    </div>

    <!-- Group by Priority -->
    <div v-for="grp in priorityGroups" :key="grp.key" class="mb-4">
      <!-- Priority header -->
      <div class="d-flex align-center ga-2 mb-2 cursor-pointer" @click="toggleGroup(grp.key)">
        <v-icon size="16" :color="grp.color">
          {{ collapsedGroups[grp.key] ? 'mdi-chevron-right' : 'mdi-chevron-down' }}
        </v-icon>
        <div class="wf-step-dot" :style="{ background: grp.color }"></div>
        <span class="text-caption font-weight-bold text-grey-darken-3" style="font-size: 12px !important;">{{
          grp.label }}</span>
        <v-chip size="x-small" variant="tonal" class="font-weight-bold px-1"
          :style="{ color: grp.color, background: grp.color + '1a' }">
          {{ grp.items.length }}
        </v-chip>
      </div>

      <!-- WorkItem rows -->
      <template v-if="!collapsedGroups[grp.key]">
        <div v-for="item in grp.items" :key="item.WorkItemID"
          class="wf-backlog-row d-flex align-center ga-3 px-4 py-2 mb-1 bg-white border rounded cursor-pointer"
          style="border-color: #e2e8f0 !important; transition: box-shadow 0.15s;" @click="$emit('open-card', item)"
          @mouseenter="hoveredId = item.WorkItemID" @mouseleave="hoveredId = null"
          :style="hoveredId === item.WorkItemID ? 'box-shadow: 0 2px 8px rgba(0,0,0,0.08);' : ''">

          <!-- Priority icon -->
          <v-tooltip :text="getPriorityLabel(item.Priority)" location="top">
            <template v-slot:activator="{ props }">
              <v-icon v-bind="props" size="14" :color="getPriorityColor(item.Priority)" style="flex-shrink: 0;">
                {{ getPriorityIcon(item.Priority) }}
              </v-icon>
            </template>
          </v-tooltip>

          <!-- Issue key -->
          <span v-if="item.IssueKey" class="font-weight-bold flex-shrink-0" style="font-size: 10px; color: #217D46;">{{
            item.IssueKey }}</span>

          <!-- Title -->
          <span class="flex-grow-1 text-caption font-weight-medium text-grey-darken-4"
            style="font-size: 13px !important; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            {{ item.Title }}
          </span>

          <!-- Assignee -->
          <v-tooltip v-if="item.AssigneeName" :text="item.AssigneeName" location="top">
            <template v-slot:activator="{ props }">
              <div v-bind="props" class="flex-shrink-0"
                style="width: 22px; height: 22px; border-radius: 50%; background: #64748b; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 9px; font-weight: 700;">
                {{ (item.AssigneeName || '?').charAt(0).toUpperCase() }}
              </div>
            </template>
          </v-tooltip>

          <!-- Due date -->
          <span v-if="item.DueDate" class="flex-shrink-0 text-caption text-grey-darken-1"
            :class="isOverdue(item) ? 'text-error font-weight-bold' : ''"
            style="font-size: 10px; white-space: nowrap;">
            <v-icon size="11" class="mr-0.5">mdi-clock-outline</v-icon>
            {{ formatDate(item.DueDate) }}
          </span>

          <!-- Status chip -->
          <v-chip size="x-small" :color="getStatusColor(item.Status)" variant="tonal"
            class="font-weight-bold px-1.5 flex-shrink-0" style="font-size: 9px; height: 18px; border-radius: 4px;">
            {{ getStatusText(item.Status) }}
          </v-chip>
        </div>

        <div v-if="grp.items.length === 0" class="text-caption text-grey px-4 py-2" style="font-style: italic;">
          Không có nhiệm vụ nào.</div>
      </template>
    </div>

    <!-- Empty state -->
    <div v-if="filteredItems.length === 0" class="text-center py-10">
      <v-icon size="48" color="grey-lighten-1">mdi-format-list-bulleted</v-icon>
      <div class="text-body-2 text-grey-darken-1 mt-3">Không có nhiệm vụ nào.</div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-backlog',
  props: {
    workItems: { type: Array, default: function () { return [] } }
  },
  emits: ['open-card', 'refresh'],
  data: function () {
    return {
      search: '',
      filterPriority: null,
      filterStatus: null,
      collapsedGroups: {},
      hoveredId: null,
      priorityFilterOptions: [
        { label: 'Khẩn cấp', value: 'CRITICAL' },
        { label: 'Cao', value: 'HIGH' },
        { label: 'Trung bình', value: 'MEDIUM' },
        { label: 'Thấp', value: 'LOW' }
      ],
      statusFilterOptions: [
        { label: 'Backlog', value: 'BACKLOG' },
        { label: 'Cần làm', value: 'TODO' },
        { label: 'Đang làm', value: 'IN_PROGRESS' },
        { label: 'Hoàn tất', value: 'DONE' },
        { label: 'Bị chặn', value: 'BLOCKED' }
      ]
    }
  },
  computed: {
    filteredItems: function () {
      var list = this.workItems || []
      var q = (this.search || '').trim().toLowerCase()
      if (q) list = list.filter(function (i) { return (i.Title || '').toLowerCase().includes(q) })
      if (this.filterPriority) list = list.filter(function (i) { return i.Priority === this.filterPriority }.bind(this))
      if (this.filterStatus) list = list.filter(function (i) { return i.Status === this.filterStatus }.bind(this))
      return list
    },
    priorityGroups: function () {
      var self = this
      var order = [
        { key: 'CRITICAL', label: 'Khẩn cấp', color: '#dc2626' },
        { key: 'HIGH', label: 'Cao', color: '#ea580c' },
        { key: 'MEDIUM', label: 'Trung bình', color: '#d97706' },
        { key: 'LOW', label: 'Thấp', color: '#2563eb' },
        { key: 'NONE', label: 'Chưa đặt độ ưu tiên', color: '#94a3b8' }
      ]
      return order.map(function (g) {
        var items = self.filteredItems.filter(function (i) {
          return (i.Priority || 'NONE') === g.key
        }).sort(function (a, b) {
          var da = a.DueDate ? new Date(a.DueDate).getTime() : Infinity
          var db = b.DueDate ? new Date(b.DueDate).getTime() : Infinity
          if (da !== db) return da - db
          return (a.Title || '').localeCompare(b.Title || '')
        })
        return Object.assign({}, g, { items: items })
      }).filter(function (g) { return g.items.length > 0 })
    }
  },
  methods: {
    toggleGroup: function (key) {
      this.collapsedGroups = Object.assign({}, this.collapsedGroups, { [key]: !this.collapsedGroups[key] })
    },
    getPriorityColor: function (p) {
      return { CRITICAL: '#dc2626', HIGH: '#ea580c', MEDIUM: '#d97706', LOW: '#2563eb' }[p] || '#94a3b8'
    },
    getPriorityIcon: function (p) {
      return { CRITICAL: 'mdi-alert-circle', HIGH: 'mdi-arrow-up-circle', MEDIUM: 'mdi-minus-circle', LOW: 'mdi-arrow-down-circle' }[p] || 'mdi-flag-off-outline'
    },
    getPriorityLabel: function (p) {
      return { CRITICAL: 'Khẩn cấp', HIGH: 'Cao', MEDIUM: 'Trung bình', LOW: 'Thấp' }[p] || 'Không đặt'
    },
    getStatusColor: function (s) {
      return { BACKLOG: 'grey', TODO: 'blue', IN_PROGRESS: 'warning', DONE: 'success', BLOCKED: 'error' }[s] || 'grey'
    },
    getStatusText: function (s) {
      return { BACKLOG: 'Backlog', TODO: 'Cần làm', IN_PROGRESS: 'Đang làm', DONE: 'Hoàn tất', BLOCKED: 'Bị chặn' }[s] || s || ''
    },
    isOverdue: function (item) {
      return item.DueDate && item.Status !== 'DONE' && new Date(item.DueDate) < new Date()
    },
    formatDate: function (val) {
      if (!val) return ''
      var d = new Date(val)
      if (isNaN(d.getTime())) return val
      return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0')
    }
  }
	}
</script>