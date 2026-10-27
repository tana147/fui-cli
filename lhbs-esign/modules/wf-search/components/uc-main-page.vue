<template>
	<uc-wf-shell title="Tìm kiếm" subtitle="Tìm nhiệm vụ toàn hệ thống">
    <div class="pa-6" style="max-width: 900px; margin: 0 auto;">
      <!-- Search Header -->
      <div class="mb-6">
        <div class="text-h6 font-weight-bold text-grey-darken-4 mb-2">Tìm kiếm toàn hệ thống</div>
        <div class="text-caption text-grey">Tìm kiếm nhiệm vụ, hồ sơ trên tất cả các quy trình.</div>
      </div>

      <!-- Search Bar -->
      <div class="d-flex ga-3 mb-6 align-start">
        <v-text-field v-model="keyword" placeholder="Nhập tên nhiệm vụ, từ khóa..." variant="outlined"
          density="comfortable" hide-details prepend-inner-icon="mdi-magnify" clearable
          class="wf-ant-input bg-white flex-grow-1"
          style="font-size: 14px;" autofocus
          @keydown.enter="search" @click:clear="clearSearch" />
        <v-btn color="primary" variant="flat" height="44" class="font-weight-bold px-6"
          style="text-transform: none; border-radius: 4px; font-size: 13px !important;"
          :loading="isLoading" @click="search">
          <v-icon start size="16">mdi-magnify</v-icon>
          Tìm kiếm
        </v-btn>
      </div>

      <!-- Advanced filters toggle -->
      <div class="mb-4">
        <v-btn variant="text" color="primary" height="28" class="text-caption font-weight-medium px-2"
          style="text-transform: none;" @click="showFilters = !showFilters">
          <v-icon start size="14">mdi-filter-outline</v-icon>
          {{ showFilters ? 'Ẩn bộ lọc' : 'Lọc nâng cao' }}
        </v-btn>
      </div>

      <!-- Advanced Filters -->
      <div v-if="showFilters" class="mb-5 pa-4 rounded-lg border bg-grey-lighten-5"
        style="border-color: #e2e8f0 !important;">
        <v-row class="ma-0 ga-3">
          <v-col cols="12" md="3" class="pa-0">
            <v-select v-model="filters.status" :items="statusOptions" item-title="label" item-value="value"
              label="Trạng thái" variant="outlined" density="compact" hide-details clearable
              class="wf-ant-input bg-white" />
          </v-col>
          <v-col cols="12" md="3" class="pa-0">
            <v-select v-model="filters.priority" :items="priorityOptions" item-title="label" item-value="value"
              label="Độ ưu tiên" variant="outlined" density="compact" hide-details clearable
              class="wf-ant-input bg-white" />
          </v-col>
          <v-col cols="12" md="3" class="pa-0">
            <v-text-field v-model="filters.dateFrom" label="Từ ngày" type="date" variant="outlined"
              density="compact" hide-details class="wf-ant-input bg-white" />
          </v-col>
          <v-col cols="12" md="3" class="pa-0">
            <v-text-field v-model="filters.dateTo" label="Đến ngày" type="date" variant="outlined"
              density="compact" hide-details class="wf-ant-input bg-white" />
          </v-col>
        </v-row>
      </div>

      <!-- Loading -->
      <div v-if="isLoading" class="d-flex justify-center py-12">
        <v-progress-circular indeterminate color="primary" size="36" />
      </div>

      <!-- Results -->
      <template v-else-if="hasSearched">
        <div class="d-flex align-center justify-space-between mb-3">
          <div class="text-caption text-grey-darken-2">
            <span class="font-weight-bold text-grey-darken-4">{{ results.length }}</span> kết quả
            <span v-if="keyword"> cho "<span class="font-weight-medium text-primary">{{ keyword }}</span>"</span>
          </div>
        </div>

        <div v-if="results.length === 0" class="text-center py-12">
          <v-icon size="56" color="grey-lighten-1">mdi-text-search</v-icon>
          <div class="text-body-1 text-grey-darken-1 mt-4">Không tìm thấy kết quả phù hợp.</div>
          <div class="text-caption text-grey mt-1">Thử từ khóa khác hoặc điều chỉnh bộ lọc.</div>
        </div>

        <div v-else class="d-flex flex-column ga-2">
          <div v-for="inst in results" :key="inst.InstanceID"
            class="d-flex align-center ga-3 px-4 py-3 bg-white border rounded-lg cursor-pointer"
            style="border-color: #e2e8f0 !important; transition: box-shadow 0.15s;"
            @click="openInstance(inst)"
            @mouseenter="hoveredId = inst.InstanceID"
            @mouseleave="hoveredId = null"
            :style="hoveredId === inst.InstanceID ? 'box-shadow: 0 2px 10px rgba(0,0,0,0.08);' : ''">

            <!-- Priority icon -->
            <v-icon size="16" :color="getPriorityColor(inst.Priority)" style="flex-shrink: 0;">
              {{ getPriorityIcon(inst.Priority) }}
            </v-icon>

            <!-- Main info -->
            <div class="flex-grow-1 min-w-0">
              <div class="text-caption font-weight-bold text-grey-darken-4 mb-0.5"
                style="font-size: 13px !important;" v-html="highlight(inst.InstanceName)"></div>
              <div class="d-flex align-center ga-2 text-caption text-grey" style="font-size: 10px !important;">
                <span>{{ inst.DefinitionName || '' }}</span>
                <span v-if="inst.CurrentStepName">· {{ inst.CurrentStepName }}</span>
                <span v-if="inst.AssigneeName">· {{ inst.AssigneeName }}</span>
              </div>
            </div>

            <!-- Status -->
            <v-chip size="x-small" :color="getStatusColor(inst.Status)" variant="tonal"
              class="font-weight-bold flex-shrink-0" style="font-size: 9px; height: 18px; border-radius: 4px;">
              {{ getStatusText(inst.Status) }}
            </v-chip>

            <!-- Updated time -->
            <span class="text-caption text-grey flex-shrink-0" style="font-size: 10px; white-space: nowrap;">
              {{ formatDate(inst.UpdateTime || inst.CreateTime) }}
            </span>

            <v-icon size="14" color="grey-lighten-1" style="flex-shrink: 0;">mdi-open-in-new</v-icon>
          </div>
        </div>
      </template>

      <!-- Initial state -->
      <div v-else class="text-center py-16">
        <v-icon size="64" color="grey-lighten-1">mdi-magnify</v-icon>
        <div class="text-body-1 text-grey-darken-1 mt-4">Nhập từ khóa để bắt đầu tìm kiếm</div>
        <div class="text-caption text-grey mt-1">Tìm theo tên nhiệm vụ, mã hồ sơ, nhãn, người phụ trách...</div>
      </div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data() {
    return {
      keyword: '',
      results: [],
      isLoading: false,
      hasSearched: false,
      showFilters: false,
      hoveredId: null,
      filters: {
        status: null,
        priority: null,
        dateFrom: '',
        dateTo: ''
      },
      statusOptions: [
        { label: 'Đang chạy', value: 'RUNNING' },
        { label: 'Chờ xử lý', value: 'WAITING_ME' },
        { label: 'Hoàn tất', value: 'COMPLETED' },
        { label: 'Đã hủy', value: 'CANCELLED' }
      ],
      priorityOptions: [
        { label: 'Khẩn cấp', value: 'CRITICAL' },
        { label: 'Cao', value: 'HIGH' },
        { label: 'Trung bình', value: 'MEDIUM' },
        { label: 'Thấp', value: 'LOW' }
      ]
    }
  },
  mounted() {
    var params = new URLSearchParams(window.location.search)
    var q = params.get('q') || ''
    if (q) { this.keyword = q; this.search() }
  },
  methods: {
    search: async function () {
      var q = (this.keyword || '').trim()
      if (!q) { showToast.info('Vui lòng nhập từ khóa tìm kiếm.'); return }
      this.isLoading = true
      this.hasSearched = true
      try {
        var params = { Keyword: q, PageSize: 50 }
        if (this.filters.status) params.Status = this.filters.status
        if (this.filters.priority) params.Priority = this.filters.priority
        if (this.filters.dateFrom) params.DateFrom = this.filters.dateFrom
        if (this.filters.dateTo) params.DateTo = this.filters.dateTo
        var res = await apiCallAsync('WF_Instance_Search', params)
        this.results = res || []
      } catch (e) {
        // handled
      } finally {
        this.isLoading = false
      }
    },

    clearSearch: function () {
      this.results = []
      this.hasSearched = false
    },

    openInstance: function (inst) {
      if (inst && inst.InstanceID) {
        window.location.href = '/wf-kanban-flow-detail?id=' + inst.InstanceID
      }
    },

    highlight: function (text) {
      var q = (this.keyword || '').trim()
      if (!q || !text) return text || ''
      var escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      return text.replace(new RegExp('(' + escaped + ')', 'gi'),
        '<mark style="background:#fef3c7; padding: 0 1px; border-radius: 2px;">$1</mark>')
    },

    getPriorityColor: function (p) {
      return { CRITICAL: '#dc2626', HIGH: '#ea580c', MEDIUM: '#d97706', LOW: '#2563eb' }[p] || '#94a3b8'
    },
    getPriorityIcon: function (p) {
      return { CRITICAL: 'mdi-alert-circle', HIGH: 'mdi-arrow-up-circle', MEDIUM: 'mdi-minus-circle', LOW: 'mdi-arrow-down-circle' }[p] || 'mdi-flag-off-outline'
    },
    getStatusColor: function (s) {
      return { RUNNING: 'blue', WAITING_ME: 'warning', COMPLETED: 'success', CANCELLED: 'grey' }[s] || 'grey'
    },
    getStatusText: function (s) {
      return { RUNNING: 'Đang chạy', WAITING_ME: 'Chờ xử lý', COMPLETED: 'Hoàn tất', CANCELLED: 'Đã hủy' }[s] || s || ''
    },
    formatDate: function (val) {
      if (!val) return ''
      var d = new Date(val)
      if (isNaN(d.getTime())) return val
      return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear()
    }
  }
	}
</script>