<template>
	<div>
    <div class="d-flex align-center justify-space-between wf-editor-section__label-row">
      <div class="wf-editor-section__label">
        <v-icon size="12" class="mr-1" color="primary">mdi-clipboard-list-outline</v-icon>
        Checklist công việc ({{ (activeStep.Tasks || []).length }})
      </div>
      <v-btn variant="text" color="primary" size="x-small" class="font-weight-bold text-none" @click="addTask">
        <v-icon start size="13">mdi-plus</v-icon> Thêm công việc
      </v-btn>
    </div>

    <div class="mt-2">
      <div v-for="(task, taskIdx) in (activeStep.Tasks || [])" :key="task._id || ('task-' + taskIdx)"
        class="wf-task-row" :class="{ 'wf-dragging': dragIdx === taskIdx }" :draggable="dragStartAllowed"
        @dragstart="onDragStart($event, taskIdx)" @dragover.prevent="onDragOver($event, taskIdx)"
        @dragleave="onDragLeave($event, taskIdx)" @drop="onDrop($event, taskIdx)" @dragend="onDragEnd($event)">

        <!-- Drag handle -->
        <div class="wf-task-row__drag-handle" @mousedown="dragStartAllowed = true" @mouseup="dragStartAllowed = false"
          @mouseleave="dragStartAllowed = false">
          <v-icon size="16">mdi-drag-vertical</v-icon>
        </div>

        <!-- Index badge -->
        <div class="wf-task-row__index">{{ taskIdx + 1 }}</div>

        <!-- Name + Description stacked -->
        <div class="wf-task-row__body">
          <v-text-field v-model="task.TaskName" placeholder="Tên nhiệm vụ..." density="compact" variant="plain"
            hide-details class="wf-task-row__name" :clearable="false" />
          <v-text-field v-model="task.Description" placeholder="Mô tả ngắn..." density="compact" variant="plain"
            hide-details class="wf-task-row__desc" :clearable="false" />
        </div>

        <!-- Required Toggle -->
        <div class="mr-2" style="flex-shrink: 0;">
          <v-checkbox-btn v-model="task.IsRequired" label="Bắt buộc" density="compact" hide-details
            class="text-caption font-weight-bold" style="font-size: 11px;"></v-checkbox-btn>
        </div>

        <!-- Remove btn -->
        <v-btn icon size="x-small" variant="text" color="error" class="wf-task-row__remove"
          @click="removeTask(taskIdx)">
          <v-icon size="14">mdi-close</v-icon>
        </v-btn>
      </div>

      <div v-if="!activeStep.Tasks || !activeStep.Tasks.length" class="wf-empty-box">
        Chưa có nhiệm vụ con nào. Bấm "+ Thêm nhiệm vụ" để bắt đầu.
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
		activeStep: { type: Object, required: true }
	},
	data: function () {
		return {
			dragIdx: null,
			dragStartAllowed: false
		}
	},
	methods: {
		addTask: function () {
			if (!this.activeStep.Tasks) this.activeStep.Tasks = []
			this.activeStep.Tasks.push({
				_id: Math.random().toString(36).substr(2, 9),
				TaskID: null,
				TaskName: "",
				Description: "",
				IsCompleted: false,
				IsRequired: false,
				SortOrder: this.activeStep.Tasks.length + 1
			})
		},
		removeTask: function (idx) {
			if (!this.activeStep.Tasks) return
			this.activeStep.Tasks.splice(idx, 1)
			this.activeStep.Tasks.forEach(function (t, i) {
				t.SortOrder = i + 1
			})
		},
		onDragStart: function (event, index) {
			this.dragIdx = index
			event.dataTransfer.effectAllowed = "move"
			event.dataTransfer.setData("text/plain", index)
		},
		onDragOver: function (event, index) {
			// Required to allow drop
		},
		onDragLeave: function (event, index) {
			// Handled if we need custom styles
		},
		onDrop: function (event, index) {
			if (this.dragIdx === null || this.dragIdx === index) return
			const tasks = this.activeStep.Tasks || []
			const draggedItem = tasks[this.dragIdx]
			tasks.splice(this.dragIdx, 1)
			tasks.splice(index, 0, draggedItem)
			tasks.forEach(function (t, i) {
				t.SortOrder = i + 1
			})
			this.dragIdx = null
			this.dragStartAllowed = false
		},
		onDragEnd: function (event) {
			this.dragIdx = null
			this.dragStartAllowed = false
		}
	}
	}
</script>