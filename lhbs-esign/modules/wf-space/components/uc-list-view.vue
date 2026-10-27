<template>
	<div class="wf-list-view pa-4">
    <!-- Toolbar -->
    <div class="d-flex align-center justify-space-between mb-3">
      <div class="d-flex align-center ga-3">
        <span class="text-subtitle-2 font-weight-bold text-grey-darken-3">Danh sách</span>
        <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
          {{ filteredItems.length }}
        </v-chip>
      </div>
      <div class="d-flex align-center ga-2">
        <v-select v-model="filterPriority" :items="priorityOptions" item-title="label" item-value="value"
          placeholder="Ưu tiên" variant="outlined" density="compact" hide-details clearable
          style="min-width: 130px; font-size: 12px;" class="wf-ant-input bg-white" />
        <v-select v-model="filterStatus" :items="statusOptions" item-title="label" item-value="value"
          placeholder="Trạng thái" variant="outlined" density="compact" hide-details clearable
          style="min-width: 130px; font-size: 12px;" class="wf-ant-input bg-white" />
        <v-text-field v-model="search" placeholder="Tìm kiếm..." variant="outlined" density="compact" hide-details
          prepend-inner-icon="mdi-magnify" clearable style="min-width: 180px; font-size: 12px;"
          class="wf-ant-input bg-white" />
        <!-- Export CSV -->
        <v-btn variant="outlined" color="grey-darken-2" height="32" class="font-weight-medium px-3"
          style="font-size: 11px; border-radius: 4px; text-transform: none;" @click="exportCSV">
          <v-icon start size="14">mdi-download</v-icon>
          CSV
        </v-btn>
      </div>
    </div>

    <!-- Bulk action toolbar -->
    <div v-if="selectedIds.length > 0" class="d-flex align-center ga-3 px-4 py-2 mb-3 rounded-lg border"
      style="background: #eff6ff; border-color: #bfdbfe !important;">
      <v-icon size="16" color="primary">mdi-check-circle</v-icon>
      <span class="text-caption font-weight-bold text-primary" style="font-size: 12px !important;">
        {{ selectedIds.length }} mục đã chọn
      </span>
      <v-divider vertical style="height: 20px;" />
      <v-btn variant="text" color="primary" height="28" class="text-caption font-weight-medium px-3"
        style="text-transform: none; font-size: 11px !important;" @click="bulkExportCSV">
        <v-icon start size="12">mdi-download</v-icon>
        Xuất CSV
      </v-btn>
      <v-spacer />
      <v-btn icon size="x-small" variant="text" color="grey" @click="selectedIds = []">
        <v-icon size="14">mdi-close</v-icon>
      </v-btn>
    </div>

    <!-- Table -->
    <div class="bg-white border rounded-lg overflow-hidden" style="border-color: #e2e8f0 !important;">
      <!-- Header -->
      <div class="wf-list-header d-flex align-center px-3 py-2 border-bottom"
        style="background: #f8fafc; border-bottom: 1px solid #e2e8f0 !important;">
        <!-- Select all checkbox -->
        <div style="width: 28px; flex-shrink: 0;" class="d-flex align-center">
          <v-checkbox-btn :model-value="isAllSelected" :indeterminate="isSomeSelected" color="primary" density="compact"
            hide-details @click="toggleSelectAll" />
        </div>
        <div v-for="col in visibleColumns" :key="col.key"
          class="text-caption font-weight-bold text-grey-darken-2 text-uppercase cursor-pointer d-flex align-center ga-1"
          :style="(col.style || 'flex: 1;') + '; font-size: 10px !important; letter-spacing: 0.04em; user-select: none;'"
          @click="sortBy(col.key)">
          {{ col.label }}
          <v-icon v-if="sortKey === col.key" size="12" :color="'grey-darken-2'">
            {{ sortDir === 'asc' ? 'mdi-arrow-up' : 'mdi-arrow-down' }}
          </v-icon>
        </div>
      </div>

      <!-- Rows -->
      <div v-if="sortedItems.length > 0">
        <div v-for="item in sortedItems" :key="item.WorkItemID"
          class="wf-list-row d-flex align-center px-3 py-2 border-bottom cursor-pointer"
          @click="$emit('open-card', item)"
          :style="'border-bottom: 1px solid #f1f5f9 !important; transition: background 0.1s; ' + (selectedIds.includes(item.WorkItemID) ? 'background: #eff6ff;' : hoveredId === item.WorkItemID ? 'background: #f8fafc;' : '')"
          @mouseenter="hoveredId = item.WorkItemID" @mouseleave="hoveredId = null">

          <!-- Checkbox -->
          <div style="width: 28px; flex-shrink: 0;" class="d-flex align-center" @click.stop>
            <v-checkbox-btn :model-value="selectedIds.includes(item.WorkItemID)" color="primary" density="compact"
              hide-details @click.stop="toggleSelect(item.WorkItemID)" />
          </div>

          <!-- Name (with priority icon + issue key) -->
          <div style="flex: 2; min-width: 0;" class="d-flex align-center ga-2">
            <v-icon size="13" :color="getPriorityColor(item.Priority)" style="flex-shrink: 0;">
              {{ getPriorityIcon(item.Priority) }}
            </v-icon>
            <span v-if="item.IssueKey" class="font-weight-bold"
              style="font-size: 10px; color: #217D46; flex-shrink: 0;">{{ item.IssueKey }}</span>
            <span class="text-caption font-weight-medium text-grey-darken-4 text-truncate"
              style="font-size: 13px !important;">{{ item.Title }}</span>
          </div>

          <!-- Status -->
          <div style="width: 110px; flex-shrink: 0;">
            <v-chip size="x-small" :color="getStatusColor(item.Status)" variant="tonal" class="font-weight-bold px-1.5"
              style="font-size: 9px; height: 18px; border-radius: 4px;">
              {{ getStatusText(item.Status) }}
            </v-chip>
          </div>

          <!-- Assignee -->
          <div style="width: 120px; flex-shrink: 0; font-size: 11px !important;"
            class="d-flex align-center ga-1 text-caption text-grey-darken-2">
            <div v-if="item.AssigneeName"
              style="width: 18px; height: 18px; border-radius: 50%; background: #64748b; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 8px; font-weight: 700; flex-shrink: 0;">
              {{ (item.AssigneeName || '?').charAt(0).toUpperCase() }}
            </div>
            <span class="text-truncate">{{ item.AssigneeName || '—' }}</span>
          </div>

          <!-- Due date -->
          <div style="width: 80px; flex-shrink: 0; font-size: 10px; white-space: nowrap;" class="text-caption"
            :class="isOverdue(item.DueDate) ? 'text-error font-weight-bold' : 'text-grey-darken-1'">
            {{ item.DueDate ? formatDate(item.DueDate) : '—' }}
          </div>

          <!-- Created -->
          <div style="width: 90px; flex-shrink: 0; font-size: 10px; white-space: nowrap;"
            class="text-caption text-grey">
            {{ item.CreateTime ? formatDate(item.CreateTime) : '—' }}
          </div>
        </div>
      </div>

      <!-- Empty -->
      <div v-else class="text-center py-10">
        <v-icon size="40" color="grey-lighten-1">mdi-table-off</v-icon>
        <div class="text-caption text-grey mt-2">Không có dữ liệu.</div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-list-view',
  props: {
    workItems: { type: Array, default: function () { return [] } }
  },
  emits: ['open-card', 'refresh'],
  data: function () {
    return {
      search: '',
      filterPriority: null,
      filterStatus: null,
      sortKey: 'CreateTime',
      sortDir: 'desc',
      hoveredId: null,
      selectedIds: [],
      visibleColumns: [
        { key: 'Title', label: 'Tên nhiệm vụ', style: 'flex: 2; min-width: 0;' },
        { key: 'Status', label: 'Trạng thái', style: 'width: 110px; flex-shrink: 0;' },
        { key: 'AssigneeName', label: 'Phụ trách', style: 'width: 120px; flex-shrink: 0;' },
        { key: 'DueDate', label: 'Hạn chót', style: 'width: 80px; flex-shrink: 0;' },
        { key: 'CreateTime', label: 'Tạo lúc', style: 'width: 90px; flex-shrink: 0;' }
      ],
      priorityOptions: [
        { label: 'Khẩn cấp', value: 'CRITICAL' },
        { label: 'Cao', value: 'HIGH' },
        { label: 'Trung bình', value: 'MEDIUM' },
        { label: 'Thấp', value: 'LOW' }
      ],
      statusOptions: [
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
      if (q) list = list.filter(i => (i.Title || '').toLowerCase().includes(q))
      if (this.filterPriority) list = list.filter(i => i.Priority === this.filterPriority)
      if (this.filterStatus) list = list.filter(i => i.Status === this.filterStatus)
      return list
    },
    sortedItems: function () {
      var key = this.sortKey
      var dir = this.sortDir === 'asc' ? 1 : -1
      return this.filteredItems.slice().sort((a, b) => {
        var av = a[key] || ''
        var bv = b[key] || ''
        if (av < bv) return -1 * dir
        if (av > bv) return 1 * dir
        return 0
      })
    },
    isAllSelected: function () {
      return this.sortedItems.length > 0 &&
        this.sortedItems.every(i => this.selectedIds.includes(i.WorkItemID))
    },
    isSomeSelected: function () {
      return !this.isAllSelected && this.sortedItems.some(i => this.selectedIds.includes(i.WorkItemID))
    }
  },
  methods: {
    sortBy: function (key) {
      if (this.sortKey === key) {
        this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc'
      } else {
        this.sortKey = key
        this.sortDir = 'asc'
      }
    },
    toggleSelect: function (id) {
      var idx = this.selectedIds.indexOf(id)
      if (idx === -1) this.selectedIds.push(id)
      else this.selectedIds.splice(idx, 1)
    },
    toggleSelectAll: function () {
      if (this.isAllSelected) {
        var pageIds = this.sortedItems.map(i => i.WorkItemID)
        this.selectedIds = this.selectedIds.filter(id => pageIds.indexOf(id) === -1)
      } else {
        this.sortedItems.forEach(i => {
          if (this.selectedIds.indexOf(i.WorkItemID) === -1) this.selectedIds.push(i.WorkItemID)
        })
      }
    },
    bulkExportCSV: function () {
      var rows = this.sortedItems.filter(i => this.selectedIds.includes(i.WorkItemID))
      if (!rows.length) return
      var headers = ['ID', 'Tên nhiệm vụ', 'Trạng thái', 'Phụ trách', 'Độ ưu tiên', 'Hạn chót']
      var csv = headers.join(',') + '\n'
      rows.forEach(i => {
        csv += [i.WorkItemID, '"' + (i.Title || '').replace(/"/g, '""') + '"',
          i.Status || '', '"' + (i.AssigneeName || '').replace(/"/g, '""') + '"',
          i.Priority || '', i.DueDate || ''].join(',') + '\n'
      })
      var blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' })
      var a = document.createElement('a'); a.href = URL.createObjectURL(blob)
      a.download = 'nhiem-vu-' + new Date().toISOString().slice(0, 10) + '.csv'; a.click()
    },
    getPriorityColor: function (p) {
      return { CRITICAL: '#dc2626', HIGH: '#ea580c', MEDIUM: '#d97706', LOW: '#2563eb' }[p] || '#94a3b8'
    },
    getPriorityIcon: function (p) {
      return { CRITICAL: 'mdi-alert-circle', HIGH: 'mdi-arrow-up-circle', MEDIUM: 'mdi-minus-circle', LOW: 'mdi-arrow-down-circle' }[p] || 'mdi-flag-off-outline'
    },
    getStatusColor: function (s) {
      return { BACKLOG: 'grey', TODO: 'blue', IN_PROGRESS: 'warning', DONE: 'success', BLOCKED: 'error' }[s] || 'grey'
    },
    getStatusText: function (s) {
      return { BACKLOG: 'Backlog', TODO: 'Cần làm', IN_PROGRESS: 'Đang làm', DONE: 'Hoàn tất', BLOCKED: 'Bị chặn' }[s] || s || ''
    },
    isOverdue: function (date) {
      return date && new Date(date) < new Date()
    },
    formatDate: function (val) {
      if (!val) return ''
      var d = new Date(val)
      if (isNaN(d.getTime())) return val
      return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear()
    },
    exportCSV: function () {
      var rows = this.sortedItems
      if (!rows.length) { showToast.info('Không có dữ liệu để xuất.'); return }
      var headers = ['ID', 'Tên nhiệm vụ', 'Trạng thái', 'Phụ trách', 'Độ ưu tiên', 'Hạn chót', 'Ngày tạo']
      var csv = headers.join(',') + '\n'
      rows.forEach(i => {
        csv += [
          i.WorkItemID,
          '"' + (i.Title || '').replace(/"/g, '""') + '"',
          i.Status || '',
          '"' + (i.AssigneeName || '').replace(/"/g, '""') + '"',
          i.Priority || '',
          i.DueDate || '',
          i.CreateTime || ''
        ].join(',') + '\n'
      })
      var blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' })
      var url = URL.createObjectURL(blob)
      var a = document.createElement('a')
      a.href = url
      a.download = 'danh-sach-nhiem-vu-' + new Date().toISOString().slice(0, 10) + '.csv'
      a.click()
      URL.revokeObjectURL(url)
    }
  }
	}
</script>