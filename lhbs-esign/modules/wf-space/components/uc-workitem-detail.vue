<template>
	<v-dialog :model-value="modelValue" max-width="600" persistent
    @update:model-value="$emit('update:modelValue', $event)">
    <v-card v-if="item" class="rounded-xl" elevation="8">
      <!-- Header -->
      <div class="d-flex align-center justify-space-between pa-5 pb-3">
        <div class="d-flex align-center ga-2">
          <v-chip v-if="item.IssueKey" size="x-small" color="primary" variant="tonal"
            class="font-weight-bold" style="font-size: 10px;">{{ item.IssueKey }}</v-chip>
          <span class="text-subtitle-1 font-weight-bold text-grey-darken-4">Chi tiết nhiệm vụ</span>
        </div>
        <v-btn icon size="small" variant="text" color="grey" @click="close">
          <v-icon size="18">mdi-close</v-icon>
        </v-btn>
      </div>

      <v-divider />

      <v-card-text class="pa-5">
        <!-- Title -->
        <div class="mb-4">
          <div class="wf-wi-label">Tiêu đề</div>
          <v-text-field v-if="editing" v-model="form.Title" variant="outlined" density="compact"
            hide-details class="wf-ant-input bg-white" />
          <div v-else class="text-body-1 font-weight-bold text-grey-darken-4 cursor-pointer"
            @click="startEdit" style="line-height: 1.4;">{{ item.Title }}</div>
        </div>

        <!-- Status + Priority -->
        <div class="d-flex ga-3 mb-4">
          <div style="flex: 1;">
            <div class="wf-wi-label">Trạng thái</div>
            <v-select v-if="editing" v-model="form.Status" :items="statusOptions" item-title="label"
              item-value="value" variant="outlined" density="compact" hide-details class="wf-ant-input bg-white" />
            <v-chip v-else size="small" :color="getStatusColor(item.Status)" variant="tonal"
              class="font-weight-bold" style="font-size: 11px;">{{ getStatusText(item.Status) }}</v-chip>
          </div>
          <div style="flex: 1;">
            <div class="wf-wi-label">Ưu tiên</div>
            <v-select v-if="editing" v-model="form.Priority" :items="priorityOptions" item-title="label"
              item-value="value" variant="outlined" density="compact" hide-details clearable
              class="wf-ant-input bg-white" />
            <div v-else class="d-flex align-center ga-1">
              <v-icon v-if="item.Priority" size="14" :color="getPriorityColor(item.Priority)">
                {{ getPriorityIcon(item.Priority) }}</v-icon>
              <span class="text-caption font-weight-medium">{{ getPriorityLabel(item.Priority) }}</span>
            </div>
          </div>
        </div>

        <!-- Assignee + DueDate -->
        <div class="d-flex ga-3 mb-4">
          <div style="flex: 1;">
            <div class="wf-wi-label">Phụ trách</div>
            <uc-select-user v-if="editing" v-model="form.AssigneeCode" placeholder="Chọn..." clearable />
            <div v-else class="d-flex align-center ga-1">
              <div v-if="item.AssigneeName"
                style="width: 22px; height: 22px; border-radius: 50%; background: #64748b; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 9px; font-weight: 700;">
                {{ (item.AssigneeName || '?').charAt(0).toUpperCase() }}
              </div>
              <span class="text-caption font-weight-medium">{{ item.AssigneeName || 'Chưa gán' }}</span>
            </div>
          </div>
          <div style="flex: 1;">
            <div class="wf-wi-label">Hạn chót</div>
            <v-text-field v-if="editing" v-model="form.DueDate" type="date" variant="outlined"
              density="compact" hide-details clearable class="wf-ant-input bg-white" />
            <span v-else class="text-caption"
              :class="isOverdue ? 'text-error font-weight-bold' : 'text-grey-darken-1'">
              {{ item.DueDate ? formatDateFull(item.DueDate) : 'Chưa đặt' }}
            </span>
          </div>
        </div>

        <!-- Description -->
        <div class="mb-4">
          <div class="wf-wi-label">Mô tả</div>
          <v-textarea v-if="editing" v-model="form.Description" variant="outlined" density="compact"
            rows="3" hide-details auto-grow class="wf-ant-input bg-white" />
          <div v-else class="text-caption text-grey-darken-2"
            style="font-size: 13px; white-space: pre-wrap; line-height: 1.5;">
            {{ item.Description || 'Chưa có mô tả.' }}
          </div>
        </div>

        <!-- Meta -->
        <div class="border-top pt-3" style="border-top: 1px solid #e2e8f0 !important;">
          <div class="d-flex ga-4 text-caption text-grey flex-wrap" style="font-size: 10px;">
            <span>Tạo bởi: {{ item.CreateUserName || item.CreateUser }}</span>
            <span>{{ formatDateFull(item.CreateTime) }}</span>
            <span v-if="item.UpdateTime">Cập nhật: {{ formatDateFull(item.UpdateTime) }}</span>
          </div>
        </div>
      </v-card-text>

      <v-card-actions class="pa-4 pt-0 d-flex ga-2">
        <v-btn v-if="!editing" variant="outlined" color="error" height="32" class="text-caption px-3"
          style="text-transform: none; border-radius: 4px;" @click="deleteItem">
          <v-icon start size="14">mdi-delete-outline</v-icon>Xóa
        </v-btn>
        <v-spacer />
        <template v-if="editing">
          <v-btn variant="text" color="grey" @click="cancelEdit">Hủy</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving"
            class="font-weight-bold text-caption text-white px-4"
            style="text-transform: none; border-radius: 4px;" @click="saveEdit">Lưu</v-btn>
        </template>
        <v-btn v-else color="primary" variant="outlined" height="32"
          class="text-caption font-weight-medium px-3"
          style="text-transform: none; border-radius: 4px;" @click="startEdit">
          <v-icon start size="14">mdi-pencil-outline</v-icon>Sửa
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: 'uc-workitem-detail',
  props: {
    modelValue: { type: Boolean, default: false },
    workItem: { type: Object, default: null }
  },
  emits: ['update:modelValue', 'saved', 'deleted'],
  data: function () {
    return {
      editing: false,
      saving: false,
      form: {},
      statusOptions: [
        { label: 'Backlog', value: 'BACKLOG' },
        { label: 'Cần làm', value: 'TODO' },
        { label: 'Đang làm', value: 'IN_PROGRESS' },
        { label: 'Hoàn tất', value: 'DONE' },
        { label: 'Bị chặn', value: 'BLOCKED' }
      ],
      priorityOptions: [
        { label: 'Khẩn cấp', value: 'CRITICAL' },
        { label: 'Cao', value: 'HIGH' },
        { label: 'Trung bình', value: 'MEDIUM' },
        { label: 'Thấp', value: 'LOW' }
      ]
    }
  },
  computed: {
    item: function () { return this.workItem },
    isOverdue: function () {
      return this.item && this.item.DueDate && this.item.Status !== 'DONE' && new Date(this.item.DueDate) < new Date()
    }
  },
  watch: {
    modelValue: function (val) { if (val) this.editing = false }
  },
  methods: {
    close: function () { this.$emit('update:modelValue', false) },

    startEdit: function () {
      this.form = {
        Title: this.item.Title || '',
        Description: this.item.Description || '',
        Status: this.item.Status || 'TODO',
        Priority: this.item.Priority || null,
        AssigneeCode: this.item.AssigneeCode || null,
        DueDate: this.item.DueDate ? this.item.DueDate.substring(0, 10) : null
      }
      this.editing = true
    },

    cancelEdit: function () { this.editing = false },

    saveEdit: async function () {
      if (this.saving) return
      this.saving = true
      try {
        var res = await apiCallAsync('WF_WorkItem_Save', {
          WorkItemID: this.item.WorkItemID,
          ProjectID: this.item.ProjectID,
          ItemType: this.item.ItemType || 'TASK',
          Title: (this.form.Title || '').trim(),
          Description: (this.form.Description || '').trim(),
          Status: this.form.Status,
          Priority: this.form.Priority,
          AssigneeCode: this.form.AssigneeCode,
          DueDate: this.form.DueDate
        })
        var row = Array.isArray(res) ? res[0] : res
        if (row && (row.Success === false || row.Success === 0)) {
          showToast.error(row.Message || 'Không thể lưu.')
          return
        }
        showToast.success('Đã cập nhật.')
        this.editing = false
        this.$emit('saved')
      } catch (e) {
        // handled
      } finally {
        this.saving = false
      }
    },

    deleteItem: function () {
      var self = this
      showConfirm('Xóa nhiệm vụ "' + this.item.Title + '"?', async function () {
        try {
          var res = await apiCallAsync('WF_WorkItem_Delete', { WorkItemID: self.item.WorkItemID })
          var row = Array.isArray(res) ? res[0] : res
          if (row && (row.Success === false || row.Success === 0)) {
            showToast.error(row.Message || 'Không thể xóa.')
            return
          }
          showToast.success('Đã xóa.')
          self.$emit('deleted')
          self.close()
        } catch (e) { /* handled */ }
      })
    },

    getStatusColor: function (s) {
      return { BACKLOG: 'grey', TODO: 'blue', IN_PROGRESS: 'warning', DONE: 'success', BLOCKED: 'error' }[s] || 'grey'
    },
    getStatusText: function (s) {
      return { BACKLOG: 'Backlog', TODO: 'Cần làm', IN_PROGRESS: 'Đang làm', DONE: 'Hoàn tất', BLOCKED: 'Bị chặn' }[s] || s || ''
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
    formatDateFull: function (val) {
      if (!val) return ''
      var d = new Date(val)
      if (isNaN(d.getTime())) return val
      return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear()
    }
  }
	}
</script>