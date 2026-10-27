<template>
	<div class="wf-subtasks">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between mb-3">
      <div class="d-flex align-center ga-2">
        <v-icon size="16" color="primary">mdi-checkbox-multiple-outline</v-icon>
        <span class="text-subtitle-2 font-weight-bold text-grey-darken-4">Nhiệm vụ con</span>
        <v-chip v-if="subtasks.length" size="x-small" color="primary" variant="tonal" class="font-weight-bold">
          {{ completedCount }}/{{ subtasks.length }}
        </v-chip>
      </div>
      <v-btn variant="outlined" color="primary" height="28" class="font-weight-medium text-caption px-3"
        style="text-transform: none; border-radius: 4px; font-size: 11px !important;"
        @click="showAddForm = !showAddForm">
        <v-icon start size="12">mdi-plus</v-icon>
        Thêm
      </v-btn>
    </div>

    <!-- Progress bar -->
    <div v-if="subtasks.length > 0" class="mb-3">
      <div class="d-flex align-center justify-space-between mb-1">
        <span class="text-caption text-grey" style="font-size: 10px !important;">Tiến độ hoàn thành</span>
        <span class="text-caption font-weight-bold text-primary" style="font-size: 10px !important;">{{ progressPct
          }}%</span>
      </div>
      <v-progress-linear :model-value="progressPct" color="primary" bg-color="grey-lighten-3" height="5" rounded
        style="border-radius: 3px;" />
    </div>

    <!-- Add form -->
    <div v-if="showAddForm" class="mb-3 d-flex ga-2">
      <v-text-field v-model="newTaskName" placeholder="Tên nhiệm vụ con..." variant="outlined" density="compact"
        hide-details class="wf-ant-input bg-white flex-grow-1" @keydown.enter="addSubtask" @keydown.esc="closeAddForm"
        autofocus />
      <v-btn color="primary" variant="flat" height="36" icon :loading="isAdding" @click="addSubtask">
        <v-icon size="16">mdi-check</v-icon>
      </v-btn>
      <v-btn variant="text" color="grey" height="36" icon @click="closeAddForm">
        <v-icon size="16">mdi-close</v-icon>
      </v-btn>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="d-flex justify-center py-4">
      <v-progress-circular indeterminate color="primary" size="20" />
    </div>

    <!-- Empty -->
    <div v-else-if="subtasks.length === 0 && !showAddForm" class="text-center py-4">
      <v-icon size="32" color="grey-lighten-1">mdi-checkbox-blank-circle-outline</v-icon>
      <div class="text-caption text-grey mt-1">Chưa có nhiệm vụ con.</div>
    </div>

    <!-- Subtask list -->
    <div class="d-flex flex-column ga-1">
      <div v-for="task in subtasks" :key="task.ChildInstanceID"
        class="d-flex align-center ga-2 px-2 py-2 rounded border bg-white"
        style="border-color: #e2e8f0 !important; transition: background 0.1s;"
        @mouseenter="hoveredTask = task.ChildInstanceID" @mouseleave="hoveredTask = null"
        :style="hoveredTask === task.ChildInstanceID ? 'background: #f8fafc;' : ''">

        <!-- Status checkbox -->
        <v-checkbox-btn :model-value="task.Status === 'COMPLETED'" color="primary" density="compact" hide-details
          style="flex-shrink: 0;" @click.stop="toggleTaskStatus(task)" />

        <!-- Name -->
        <span class="flex-grow-1 text-caption text-grey-darken-4 text-truncate cursor-pointer"
          style="font-size: 12px !important;"
          :style="task.Status === 'COMPLETED' ? 'text-decoration: line-through; opacity: 0.5;' : ''"
          @click="openSubtask(task)">
          {{ task.ChildInstanceName }}
        </span>

        <!-- Status chip -->
        <v-chip size="x-small" :color="getStatusColor(task.Status)" variant="tonal"
          class="font-weight-bold flex-shrink-0" style="font-size: 9px; height: 16px;">
          {{ getStatusText(task.Status) }}
        </v-chip>

        <!-- Open link -->
        <v-btn icon size="x-small" variant="text" color="grey" class="flex-shrink-0" style="opacity: 0;"
          :style="hoveredTask === task.ChildInstanceID ? 'opacity: 0.7;' : ''" @click.stop="openSubtask(task)">
          <v-icon size="11">mdi-open-in-new</v-icon>
        </v-btn>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-subtasks',
  props: {
    instanceId: { type: Number, required: true }
  },
  data() {
    return {
      subtasks: [],
      isLoading: false,
      isAdding: false,
      showAddForm: false,
      newTaskName: '',
      hoveredTask: null
    }
  },
  computed: {
    completedCount() {
      return this.subtasks.filter(function (t) { return t.Status === 'COMPLETED' }).length
    },
    progressPct() {
      if (!this.subtasks.length) return 0
      return Math.round((this.completedCount / this.subtasks.length) * 100)
    }
  },
  watch: {
    instanceId: {
      immediate: true,
      handler(val) { if (val) this.loadSubtasks() }
    }
  },
  methods: {
    loadSubtasks: async function () {
      if (!this.instanceId) return
      this.isLoading = true
      try {
        var res = await apiCallAsync('WF_Instance_GetChildren', { ParentInstanceID: this.instanceId })
        this.subtasks = res || []
      } catch (e) {
        // handled
      } finally {
        this.isLoading = false
      }
    },

    addSubtask: async function () {
      var name = (this.newTaskName || '').trim()
      if (!name) return
      this.isAdding = true
      try {
        await apiCallAsync('WF_Instance_CreateChild', {
          ParentInstanceID: this.instanceId,
          InstanceName: name
        })
        showToast.success('Đã thêm nhiệm vụ con!')
        this.closeAddForm()
        await this.loadSubtasks()
      } catch (e) {
        // handled
      } finally {
        this.isAdding = false
      }
    },

    toggleTaskStatus: function (task) {
      // Navigate to detail to manage status — no direct toggle endpoint assumed
      this.openSubtask(task)
    },

    closeAddForm: function () {
      this.showAddForm = false
      this.newTaskName = ''
    },

    openSubtask: function (task) {
      if (task && task.ChildInstanceID) {
        window.open('/wf-kanban-flow-detail?id=' + task.ChildInstanceID, '_blank')
      }
    },

    getStatusColor: function (s) {
      return { RUNNING: 'blue', WAITING_ME: 'warning', COMPLETED: 'success', CANCELLED: 'grey' }[s] || 'grey'
    },
    getStatusText: function (s) {
      return { RUNNING: 'Đang chạy', WAITING_ME: 'Chờ xử lý', COMPLETED: 'Hoàn tất', CANCELLED: 'Đã hủy' }[s] || s || ''
    }
  }
	}
</script>