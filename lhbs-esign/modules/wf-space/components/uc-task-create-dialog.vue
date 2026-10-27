<template>
	<v-dialog :model-value="modelValue" max-width="500" persistent
    @update:model-value="$emit('update:modelValue', $event)">
    <v-card class="rounded-xl" elevation="8">
      <v-card-title class="d-flex align-center ga-2 pa-5 pb-3">
        <v-icon size="20" color="primary">mdi-plus-circle-outline</v-icon>
        <span class="text-subtitle-1 font-weight-bold">{{ isEdit ? 'Sửa nhiệm vụ' : 'Tạo nhiệm vụ mới' }}</span>
      </v-card-title>

      <v-card-text class="pa-5 pt-2">
        <!-- Title -->
        <div class="mb-3">
          <div class="text-caption text-grey-darken-3 mb-1">Tiêu đề <span class="text-error">*</span></div>
          <v-text-field v-model="form.Title" placeholder="Nhập tiêu đề nhiệm vụ..." variant="outlined"
            density="compact" hide-details maxlength="500" class="wf-ant-input bg-white" autofocus
            @keydown.enter="save" />
        </div>

        <!-- Description -->
        <div class="mb-3">
          <div class="text-caption text-grey-darken-3 mb-1">Mô tả</div>
          <v-textarea v-model="form.Description" placeholder="Mô tả chi tiết..." variant="outlined"
            density="compact" rows="2" hide-details auto-grow max-rows="4" class="wf-ant-input bg-white" />
        </div>

        <!-- Assignee + Priority -->
        <div class="d-flex ga-3 mb-3">
          <div class="flex-grow-1">
            <div class="text-caption text-grey-darken-3 mb-1">Người phụ trách</div>
            <uc-select-user v-model="form.AssigneeCode" placeholder="Chọn người..." clearable />
          </div>
          <div style="width: 150px; flex-shrink: 0;">
            <div class="text-caption text-grey-darken-3 mb-1">Độ ưu tiên</div>
            <v-select v-model="form.Priority" :items="priorityOptions" item-title="label" item-value="value"
              variant="outlined" density="compact" hide-details clearable placeholder="Chọn..."
              class="wf-ant-input bg-white" />
          </div>
        </div>

        <!-- DueDate + Status -->
        <div class="d-flex ga-3">
          <div style="width: 180px; flex-shrink: 0;">
            <div class="text-caption text-grey-darken-3 mb-1">Hạn chót</div>
            <v-text-field v-model="form.DueDate" type="date" variant="outlined" density="compact"
              hide-details clearable class="wf-ant-input bg-white" />
          </div>
          <div class="flex-grow-1">
            <div class="text-caption text-grey-darken-3 mb-1">Trạng thái</div>
            <v-select v-model="form.Status" :items="statusOptions" item-title="label" item-value="value"
              variant="outlined" density="compact" hide-details class="wf-ant-input bg-white" />
          </div>
        </div>
      </v-card-text>

      <v-card-actions class="pa-4 pt-0 d-flex ga-2">
        <v-spacer />
        <v-btn variant="text" color="grey" :disabled="saving" @click="close">Hủy</v-btn>
        <v-btn color="primary" variant="flat" :loading="saving" :disabled="!isValid"
          class="font-weight-bold text-caption text-white px-4"
          style="text-transform: none; border-radius: 4px;" @click="save">
          {{ isEdit ? 'Lưu' : 'Tạo' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: 'uc-task-create-dialog',
  props: {
    modelValue: { type: Boolean, default: false },
    projectId: { type: [Number, String], default: null },
    workItem: { type: Object, default: null }
  },
  emits: ['update:modelValue', 'success'],
  data: function () {
    return {
      saving: false,
      form: { Title: '', Description: '', AssigneeCode: null, Priority: null, DueDate: null, Status: 'TODO' },
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
    isEdit: function () { return !!(this.workItem && this.workItem.WorkItemID) },
    isValid: function () { return (this.form.Title || '').trim() !== '' && !!this.projectId }
  },
  watch: {
    modelValue: function (val) { if (val) this.resetForm() }
  },
  methods: {
    resetForm: function () {
      if (this.workItem && this.workItem.WorkItemID) {
        this.form = {
          Title: this.workItem.Title || '',
          Description: this.workItem.Description || '',
          AssigneeCode: this.workItem.AssigneeCode || null,
          Priority: this.workItem.Priority || null,
          DueDate: this.workItem.DueDate ? this.workItem.DueDate.substring(0, 10) : null,
          Status: this.workItem.Status || 'TODO'
        }
      } else {
        this.form = { Title: '', Description: '', AssigneeCode: null, Priority: null, DueDate: null, Status: 'TODO' }
      }
    },
    close: function () { this.$emit('update:modelValue', false) },
    save: async function () {
      if (!this.isValid || this.saving) return
      this.saving = true
      try {
        var payload = {
          ProjectID: this.projectId,
          ItemType: 'TASK',
          Title: (this.form.Title || '').trim(),
          Description: (this.form.Description || '').trim(),
          Status: this.form.Status || 'TODO',
          Priority: this.form.Priority || null,
          AssigneeCode: this.form.AssigneeCode || null,
          DueDate: this.form.DueDate || null
        }
        if (this.isEdit) payload.WorkItemID = this.workItem.WorkItemID
        var res = await apiCallAsync('WF_WorkItem_Save', payload)
        var row = Array.isArray(res) ? res[0] : res
        if (row && (row.Success === false || row.Success === 0)) {
          showToast.error(row.Message || 'Không thể lưu.')
          return
        }
        showToast.success(this.isEdit ? 'Đã cập nhật.' : 'Đã tạo nhiệm vụ.')
        this.$emit('success', row ? row.WorkItemID : null)
        this.close()
      } catch (e) {
        // apiCallAsync handles error toast
      } finally {
        this.saving = false
      }
    }
  }
	}
</script>