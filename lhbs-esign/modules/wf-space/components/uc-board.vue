<template>
	<div class="wf-board pa-4">
    <div class="wf-board-columns">
      <div v-for="col in columns" :key="col.status" class="wf-board-col"
        :class="{ 'wf-board-col--over': dragOverStatus === col.status }"
        @dragover.prevent="onDragOver(col.status)"
        @drop="onDrop(col.status)"
        @dragleave="onDragLeave">

        <!-- Column header -->
        <div class="wf-board-col__head">
          <div class="wf-board-col__dot" :style="{ background: col.color }"></div>
          <span class="wf-board-col__title">{{ col.label }}</span>
          <v-chip size="x-small" variant="tonal" class="font-weight-bold px-1"
            :style="{ color: col.color, background: col.color + '1a' }">
            {{ col.items.length }}
          </v-chip>
        </div>

        <!-- Cards -->
        <div class="wf-board-col__body">
          <div v-for="item in col.items" :key="item.WorkItemID"
            class="wf-board-card" draggable="true"
            :class="{ 'wf-board-card--dragging': draggingId === item.WorkItemID }"
            @dragstart="onDragStart($event, item)"
            @dragend="onDragEnd"
            @click="$emit('open-card', item)">

            <!-- IssueKey + Priority -->
            <div class="d-flex align-center justify-space-between mb-1">
              <span v-if="item.IssueKey" class="wf-board-card__key">{{ item.IssueKey }}</span>
              <span v-else></span>
              <v-icon v-if="item.Priority" size="13" :color="getPriorityColor(item.Priority)">
                {{ getPriorityIcon(item.Priority) }}
              </v-icon>
            </div>

            <!-- Title -->
            <div class="wf-board-card__title">{{ item.Title }}</div>

            <!-- Footer: Assignee + DueDate -->
            <div class="d-flex align-center justify-space-between mt-2">
              <v-tooltip v-if="item.AssigneeName" :text="item.AssigneeName" location="top">
                <template v-slot:activator="{ props }">
                  <div v-bind="props" class="wf-board-card__avatar">
                    {{ (item.AssigneeName || '?').charAt(0).toUpperCase() }}
                  </div>
                </template>
              </v-tooltip>
              <div v-else></div>
              <span v-if="item.DueDate" class="wf-board-card__due"
                :class="{ 'wf-board-card__due--over': isOverdue(item) }">
                <v-icon size="10" class="mr-0.5">mdi-clock-outline</v-icon>
                {{ formatDate(item.DueDate) }}
              </span>
            </div>
          </div>

          <!-- Empty column -->
          <div v-if="col.items.length === 0" class="wf-board-col__empty">
            Kéo nhiệm vụ vào đây
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-board',
  props: {
    workItems: { type: Array, default: function () { return [] } }
  },
  emits: ['open-card', 'status-change', 'refresh'],
  data: function () {
    return {
      draggingId: null,
      draggingItem: null,
      dragOverStatus: null,
      statusConfig: [
        { status: 'BACKLOG', label: 'Backlog', color: '#94a3b8' },
        { status: 'TODO', label: 'Cần làm', color: '#2563eb' },
        { status: 'IN_PROGRESS', label: 'Đang làm', color: '#d97706' },
        { status: 'DONE', label: 'Hoàn tất', color: '#16a34a' },
        { status: 'BLOCKED', label: 'Bị chặn', color: '#dc2626' }
      ]
    }
  },
  computed: {
    columns: function () {
      var items = this.workItems || []
      return this.statusConfig.map(function (cfg) {
        return {
          status: cfg.status,
          label: cfg.label,
          color: cfg.color,
          items: items.filter(function (w) { return w.Status === cfg.status })
            .sort(function (a, b) { return (a.SortOrder || 0) - (b.SortOrder || 0) })
        }
      })
    }
  },
  methods: {
    onDragStart: function (ev, item) {
      this.draggingId = item.WorkItemID
      this.draggingItem = item
      ev.dataTransfer.effectAllowed = 'move'
    },
    onDragOver: function (status) {
      this.dragOverStatus = status
    },
    onDragLeave: function () {
      this.dragOverStatus = null
    },
    onDragEnd: function () {
      this.draggingId = null
      this.draggingItem = null
      this.dragOverStatus = null
    },
    onDrop: async function (newStatus) {
      var item = this.draggingItem
      this.onDragEnd()
      if (!item || item.Status === newStatus) return
      var oldStatus = item.Status
      item.Status = newStatus
      try {
        var res = await apiCallAsync('WF_WorkItem_UpdateStatus', {
          WorkItemID: item.WorkItemID,
          Status: newStatus
        })
        var row = Array.isArray(res) ? res[0] : res
        if (row && (row.Success === false || row.Success === 0)) {
          showToast.error(row.Message || 'Không thể chuyển trạng thái.')
          item.Status = oldStatus
          return
        }
        this.$emit('status-change', item, newStatus)
      } catch (e) {
        item.Status = oldStatus
      }
    },
    getPriorityColor: function (p) {
      return { CRITICAL: '#dc2626', HIGH: '#ea580c', MEDIUM: '#d97706', LOW: '#2563eb' }[p] || '#94a3b8'
    },
    getPriorityIcon: function (p) {
      return { CRITICAL: 'mdi-alert-circle', HIGH: 'mdi-arrow-up-circle', MEDIUM: 'mdi-minus-circle', LOW: 'mdi-arrow-down-circle' }[p] || 'mdi-flag-off-outline'
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