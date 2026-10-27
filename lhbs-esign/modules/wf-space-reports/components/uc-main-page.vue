<template>
	<uc-wf-shell title="Báo cáo" subtitle="Phân tích và thống kê quy trình">
    <div class="pa-6">
      <!-- Header -->
      <div class="d-flex align-center justify-space-between mb-6">
        <div>
          <div class="text-h6 font-weight-bold text-grey-darken-4 mb-1">Báo cáo phân tích</div>
          <div class="text-caption text-grey">Thống kê hiệu suất và tiến độ thực hiện quy trình.</div>
        </div>
        <div class="d-flex align-center ga-3">
          <v-select v-model="selectedDefId" :items="definitions" item-title="Name" item-value="DefinitionID"
            label="Quy trình" variant="outlined" density="compact" hide-details clearable
            style="min-width: 200px;" class="wf-ant-input bg-white"
            @update:model-value="loadReports" />
          <v-select v-model="dateRange" :items="dateRangeOptions" item-title="label" item-value="value"
            label="Khoảng thời gian" variant="outlined" density="compact" hide-details
            style="min-width: 150px;" class="wf-ant-input bg-white"
            @update:model-value="loadReports" />
        </div>
      </div>

      <!-- Loading -->
      <div v-if="isLoading" class="d-flex justify-center py-12">
        <v-progress-circular indeterminate color="primary" size="36" />
      </div>

      <template v-else>
        <!-- KPI Cards -->
        <v-row class="mb-6">
          <v-col v-for="kpi in kpis" :key="kpi.label" cols="12" sm="6" md="3">
            <div class="bg-white border rounded-xl pa-4 d-flex flex-column"
              style="border-color: #e2e8f0 !important; box-shadow: 0 1px 4px rgba(0,0,0,0.05);">
              <div class="d-flex align-center justify-space-between mb-3">
                <span class="text-caption font-weight-bold text-grey-darken-2 text-uppercase"
                  style="font-size: 10px !important; letter-spacing: 0.05em;">{{ kpi.label }}</span>
                <div class="rounded-lg d-flex align-center justify-center"
                  style="width: 32px; height: 32px;"
                  :style="{ background: kpi.bg }">
                  <v-icon size="16" :color="kpi.color">{{ kpi.icon }}</v-icon>
                </div>
              </div>
              <div class="text-h5 font-weight-black" :class="'text-' + kpi.color" style="font-size: 28px !important;">
                {{ kpi.value }}
              </div>
              <div class="text-caption text-grey mt-1" style="font-size: 10px !important;">{{ kpi.sub }}</div>
            </div>
          </v-col>
        </v-row>

        <!-- Charts Row 1 -->
        <v-row class="mb-4">
          <!-- Status distribution -->
          <v-col cols="12" md="5">
            <div class="bg-white border rounded-xl pa-5" style="border-color: #e2e8f0 !important;">
              <div class="text-subtitle-2 font-weight-bold text-grey-darken-3 mb-4">Phân bổ trạng thái</div>
              <div v-if="statusData.length === 0" class="text-center py-6 text-caption text-grey">Chưa có dữ liệu.</div>
              <div v-else>
                <div v-for="item in statusData" :key="item.status" class="mb-3">
                  <div class="d-flex align-center justify-space-between mb-1">
                    <div class="d-flex align-center ga-2">
                      <div style="width: 10px; height: 10px; border-radius: 50%;"
                        :style="{ background: item.color }"></div>
                      <span class="text-caption text-grey-darken-3" style="font-size: 11px !important;">{{ item.label }}</span>
                    </div>
                    <div class="d-flex align-center ga-2">
                      <span class="text-caption font-weight-bold text-grey-darken-4"
                        style="font-size: 11px !important;">{{ item.count }}</span>
                      <span class="text-caption text-grey" style="font-size: 10px !important;">({{ item.pct }}%)</span>
                    </div>
                  </div>
                  <v-progress-linear :model-value="item.pct" :color="item.barColor" bg-color="grey-lighten-3"
                    height="6" rounded />
                </div>
              </div>
            </div>
          </v-col>

          <!-- Step throughput -->
          <v-col cols="12" md="7">
            <div class="bg-white border rounded-xl pa-5" style="border-color: #e2e8f0 !important;">
              <div class="text-subtitle-2 font-weight-bold text-grey-darken-3 mb-4">
                Thời gian xử lý theo bước (giờ)
              </div>
              <div v-if="timeInStatus.length === 0" class="text-center py-6 text-caption text-grey">Chưa có dữ liệu.</div>
              <div v-else class="d-flex flex-column ga-2">
                <div v-for="step in timeInStatus" :key="step.StepName" class="d-flex align-center ga-3">
                  <div class="text-caption text-grey-darken-3 text-truncate"
                    style="width: 130px; flex-shrink: 0; font-size: 11px !important;">{{ step.StepName }}</div>
                  <div class="flex-grow-1 bg-grey-lighten-4 rounded" style="height: 18px; overflow: hidden;">
                    <div class="h-100 rounded d-flex align-center pl-2"
                      style="background: linear-gradient(90deg, #3b82f6, #06b6d4); transition: width 0.6s ease;"
                      :style="{ width: getBarWidth(step.AvgHours) + '%' }">
                      <span class="text-white font-weight-bold" style="font-size: 9px;">
                        {{ Number(step.AvgHours || 0).toFixed(1) }}h
                      </span>
                    </div>
                  </div>
                  <span class="text-caption text-grey-darken-2 flex-shrink-0"
                    style="width: 40px; text-align: right; font-size: 10px !important;">
                    {{ Number(step.AvgHours || 0).toFixed(1) }}h
                  </span>
                </div>
              </div>
            </div>
          </v-col>
        </v-row>

        <!-- Charts Row 2 -->
        <v-row>
          <!-- SLA Compliance -->
          <v-col cols="12" md="4">
            <div class="bg-white border rounded-xl pa-5" style="border-color: #e2e8f0 !important;">
              <div class="text-subtitle-2 font-weight-bold text-grey-darken-3 mb-4">Tỉ lệ đúng hạn</div>
              <div class="d-flex flex-column align-center justify-center" style="min-height: 120px;">
                <div class="text-h3 font-weight-black" style="font-size: 48px !important;"
                  :class="slaCompliance >= 80 ? 'text-success' : slaCompliance >= 60 ? 'text-warning' : 'text-error'">
                  {{ slaCompliance }}%
                </div>
                <div class="text-caption text-grey mt-2">{{ slaOnTime }} / {{ slaTotalDone }} hồ sơ đúng hạn</div>
                <v-progress-linear :model-value="slaCompliance"
                  :color="slaCompliance >= 80 ? 'success' : slaCompliance >= 60 ? 'warning' : 'error'"
                  bg-color="grey-lighten-3" height="8" rounded class="mt-3 w-100" />
              </div>
            </div>
          </v-col>

          <!-- Throughput table -->
          <v-col cols="12" md="8">
            <div class="bg-white border rounded-xl pa-5" style="border-color: #e2e8f0 !important;">
              <div class="text-subtitle-2 font-weight-bold text-grey-darken-3 mb-4">Lượng hồ sơ hoàn thành theo tuần</div>
              <div v-if="throughput.length === 0" class="text-center py-6 text-caption text-grey">Chưa có dữ liệu.</div>
              <div v-else class="d-flex ga-1 align-end" style="height: 100px;">
                <div v-for="week in throughput" :key="week.Week"
                  class="flex-grow-1 d-flex flex-column align-center justify-end ga-1">
                  <span class="text-caption text-grey-darken-3 font-weight-bold"
                    style="font-size: 9px !important;">{{ week.Count }}</span>
                  <div class="rounded-sm w-100"
                    :style="{ height: getBarHeightPx(week.Count) + 'px', background: '#3b82f6', borderRadius: '3px 3px 0 0' }">
                  </div>
                  <span class="text-grey" style="font-size: 8px; white-space: nowrap;">{{ week.Week }}</span>
                </div>
              </div>
            </div>
          </v-col>
        </v-row>
      </template>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data() {
    return {
      definitions: [],
      selectedDefId: null,
      dateRange: '30',
      isLoading: false,
      timeInStatus: [],
      throughput: [],
      statusData: [],
      slaCompliance: 0,
      slaOnTime: 0,
      slaTotalDone: 0,
      dateRangeOptions: [
        { label: '7 ngày', value: '7' },
        { label: '30 ngày', value: '30' },
        { label: '90 ngày', value: '90' },
        { label: '365 ngày', value: '365' }
      ]
    }
  },
  computed: {
    kpis() {
      var total = this.statusData.reduce(function (s, i) { return s + (i.count || 0) }, 0)
      var completed = (this.statusData.find(function (i) { return i.status === 'COMPLETED' }) || {}).count || 0
      var running = (this.statusData.find(function (i) { return i.status === 'RUNNING' }) || {}).count || 0
      var maxHours = this.timeInStatus.reduce(function (m, s) { return Math.max(m, s.AvgHours || 0) }, 0)
      return [
        { label: 'Tổng hồ sơ', value: total, icon: 'mdi-file-multiple-outline', color: 'primary', bg: '#eff6ff', sub: 'trong kỳ' },
        { label: 'Hoàn thành', value: completed, icon: 'mdi-check-circle-outline', color: 'success', bg: '#f0fdf4', sub: 'đã kết thúc' },
        { label: 'Đang xử lý', value: running, icon: 'mdi-progress-clock', color: 'blue', bg: '#eff6ff', sub: 'đang chạy' },
        { label: 'Thời gian TB', value: maxHours > 0 ? Number(maxHours).toFixed(1) + 'h' : '—', icon: 'mdi-clock-fast', color: 'warning', bg: '#fffbeb', sub: 'bước chậm nhất' }
      ]
    },
    maxThroughput() {
      return Math.max(1, Math.max.apply(null, this.throughput.map(function (w) { return w.Count || 0 })))
    }
  },
  mounted() {
    this.loadDefinitions()
  },
  methods: {
    loadDefinitions: async function () {
      try {
        var res = await apiCallAsync('WF_Definition_GetList', { Status: 'ACTIVE' })
        this.definitions = res || []
        if (this.definitions.length > 0) {
          this.selectedDefId = this.definitions[0].DefinitionID
          await this.loadReports()
        }
      } catch (e) {
        // handled
      }
    },

    loadReports: async function () {
      if (!this.selectedDefId) return
      this.isLoading = true
      try {
        var params = { DefinitionID: this.selectedDefId, DateRangeDays: Number(this.dateRange) }
        var [timeRes, throughputRes, slaRes, instanceRes] = await Promise.all([
          apiCallAsync('WF_Report_TimeInStatus', params).catch(function () { return [] }),
          apiCallAsync('WF_Report_Throughput', params).catch(function () { return [] }),
          apiCallAsync('WF_Report_SLACompliance', params).catch(function () { return {} }),
          apiCallAsync('WF_Instance_GetList', { DefinitionID: this.selectedDefId, Filter: 'ALL' }).catch(function () { return [] })
        ])

        this.timeInStatus = timeRes || []
        this.throughput = throughputRes || []

        var sla = slaRes || {}
        this.slaCompliance = Number(sla.CompliancePct || 0)
        this.slaOnTime = Number(sla.OnTime || 0)
        this.slaTotalDone = Number(sla.Total || 0)

        // Build status data from instances
        var instances = instanceRes || []
        var statusMap = {}
        instances.forEach(function (i) {
          statusMap[i.Status] = (statusMap[i.Status] || 0) + 1
        })
        var total = instances.length || 1
        var statusConfig = {
          RUNNING: { label: 'Đang chạy', color: '#3b82f6', barColor: 'blue' },
          WAITING_ME: { label: 'Chờ xử lý', color: '#f59e0b', barColor: 'warning' },
          COMPLETED: { label: 'Hoàn thành', color: '#22c55e', barColor: 'success' },
          CANCELLED: { label: 'Đã hủy', color: '#94a3b8', barColor: 'grey' }
        }
        this.statusData = Object.keys(statusMap).map(function (s) {
          var cfg = statusConfig[s] || { label: s, color: '#94a3b8', barColor: 'grey' }
          var count = statusMap[s]
          return Object.assign({}, cfg, { status: s, count: count, pct: Math.round((count / total) * 100) })
        }).sort(function (a, b) { return b.count - a.count })
      } catch (e) {
        // handled
      } finally {
        this.isLoading = false
      }
    },

    getBarWidth: function (hours) {
      var max = Math.max(1, Math.max.apply(null, this.timeInStatus.map(function (s) { return s.AvgHours || 0 })))
      return Math.min(100, Math.round(((hours || 0) / max) * 90))
    },

    getBarHeightPx: function (count) {
      return Math.max(4, Math.round((count / this.maxThroughput) * 80))
    }
  }
	}
</script>