<template>
	<div class="px-5 py-4">
    <!-- KPI row -->
    <div class="d-flex ga-3 mb-4" style="flex-wrap: wrap;">
      <div class="wf-ck-kpi">
        <div class="wf-ck-kpi__num">{{ openInstances.length }}</div>
        <div class="wf-ck-kpi__lbl">Đang mở</div>
      </div>
      <div class="wf-ck-kpi">
        <div class="wf-ck-kpi__num text-warning">{{ approvalInstances.length }}</div>
        <div class="wf-ck-kpi__lbl">Chờ duyệt / ký</div>
      </div>
      <div class="wf-ck-kpi">
        <div class="wf-ck-kpi__num text-success">{{ countByStatus.COMPLETED || 0 }}</div>
        <div class="wf-ck-kpi__lbl">Hoàn tất</div>
      </div>
      <div class="wf-ck-kpi">
        <div class="wf-ck-kpi__num text-error">{{ overdueInstances.length }}</div>
        <div class="wf-ck-kpi__lbl">Quá hạn</div>
      </div>
    </div>

    <!-- Grid widgets -->
    <div class="wf-ck-grid">
      <!-- Cần xử lý -->
      <div class="wf-ck-card">
        <div class="wf-ck-card__head">
          <span><v-icon size="16" color="primary" class="mr-1">mdi-checkbox-marked-circle-outline</v-icon>Cần xử
            lý</span>
          <span class="text-caption text-grey">{{ openInstances.length }}</span>
        </div>
        <div v-if="topOpen.length">
          <div v-for="inst in topOpen" :key="inst.InstanceID" class="wf-ck-item" @click="$emit('open-card', inst)">
            <span class="wf-ck-dot" :style="{ backgroundColor: getStatusColor(inst.Status, true) }"></span>
            <span class="flex-grow-1 text-caption text-grey-darken-3 text-truncate"
              :title="inst.InstanceName">{{ inst.InstanceName }}</span>
            <v-icon v-if="isOverdue(inst.StepDueDate)" size="13" color="error">mdi-clock-alert-outline</v-icon>
          </div>
        </div>
        <div v-else class="wf-ck-empty">Không còn việc đang mở 🎉</div>
      </div>

      <!-- Chờ duyệt / ký -->
      <div class="wf-ck-card">
        <div class="wf-ck-card__head">
          <span><v-icon size="16" color="warning" class="mr-1">mdi-shield-check-outline</v-icon>Chờ duyệt / ký</span>
          <v-chip size="x-small" color="warning" variant="tonal" class="font-weight-bold"
            style="height: 18px; font-size: 10px;">{{ approvalInstances.length }}</v-chip>
        </div>
        <div v-if="approvalInstances.length">
          <div v-for="inst in approvalInstances.slice(0, 6)" :key="inst.InstanceID" class="wf-ck-item"
            @click="$emit('open-card', inst)">
            <span class="flex-grow-1 text-caption text-grey-darken-3 text-truncate"
              :title="inst.InstanceName">{{ inst.InstanceName }}</span>
            <span class="text-caption text-grey-lighten-1 text-truncate" style="max-width: 90px;">{{
              stepNameOf(inst) }}</span>
          </div>
        </div>
        <div v-else class="wf-ck-empty">Không có nhiệm vụ chờ duyệt.</div>
      </div>

      <!-- Tổng quan trạng thái -->
      <div class="wf-ck-card">
        <div class="wf-ck-card__head"><span><v-icon size="16" color="primary"
              class="mr-1">mdi-chart-donut</v-icon>Tổng quan trạng thái</span></div>
        <div class="wf-ck-bar mb-3">
          <span v-for="seg in statusSegments" :key="seg.key" :style="{ width: seg.pct + '%', background: seg.color }"
            :title="seg.label + ': ' + seg.count"></span>
        </div>
        <div v-for="seg in statusSegments" :key="'leg-' + seg.key" class="d-flex align-center ga-2 mb-1">
          <span class="wf-ck-dot" :style="{ backgroundColor: seg.color }"></span>
          <span class="text-caption text-grey-darken-2">{{ seg.label }}</span>
          <span class="ml-auto text-caption text-grey font-weight-bold">{{ seg.count }}</span>
        </div>
      </div>

      <!-- Khối lượng theo người (span 2) -->
      <div class="wf-ck-card wf-ck-span2">
        <div class="wf-ck-card__head">
          <span><v-icon size="16" color="primary" class="mr-1">mdi-account-group-outline</v-icon>Khối lượng theo
            người</span>
          <span class="text-caption text-grey">việc đang mở</span>
        </div>
        <div v-if="workload.length">
          <div v-for="w in workload" :key="w.name" class="d-flex align-center ga-3 mb-2">
            <span class="text-caption text-grey-darken-3 text-truncate" style="width: 120px;"
              :title="w.name">{{ w.name }}</span>
            <span class="wf-ck-load">
              <span class="wf-ck-load__fill" :style="{ width: w.pct + '%', background: w.pct >= 100 ? '#c25a5a' : '#2b6fd6' }"></span>
            </span>
            <span class="text-caption font-weight-bold" :class="w.pct >= 100 ? 'text-error' : 'text-grey'"
              style="width: 32px; text-align: right;">{{ w.count }}</span>
          </div>
        </div>
        <div v-else class="wf-ck-empty">Chưa có dữ liệu phân công.</div>
      </div>

      <!-- Hoạt động gần đây -->
      <div class="wf-ck-card">
        <div class="wf-ck-card__head"><span><v-icon size="16" color="primary"
              class="mr-1">mdi-history</v-icon>Cập nhật gần đây</span></div>
        <div v-if="recent.length">
          <div v-for="inst in recent" :key="inst.InstanceID" class="wf-ck-item" @click="$emit('open-card', inst)">
            <span class="flex-grow-1 text-caption text-grey-darken-3 text-truncate"
              :title="inst.InstanceName">{{ inst.InstanceName }}</span>
            <span class="text-caption text-grey-lighten-1">{{ formatDate(inst.UpdateTime || inst.CreateTime) }}</span>
          </div>
        </div>
        <div v-else class="wf-ck-empty">Chưa có hoạt động.</div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-space-cockpit',
    props: {
      instances: { type: Array, default: function () { return [] } },
      steps: { type: Array, default: function () { return [] } }
    },
    emits: ['open-card'],
    computed: {
      stepMap: function () {
        var map = {}
        ;(this.steps || []).forEach(function (s) { map[s.id] = s })
        return map
      },
      openInstances: function () {
        return (this.instances || []).filter(function (i) {
          return i.Status !== 'COMPLETED' && i.Status !== 'CANCELLED'
        })
      },
      topOpen: function () {
        return this.openInstances.slice().sort(function (a, b) {
          return new Date(b.UpdateTime || b.CreateTime || 0) - new Date(a.UpdateTime || a.CreateTime || 0)
        }).slice(0, 6)
      },
      approvalInstances: function () {
        var map = this.stepMap
        return this.openInstances.filter(function (i) {
          var s = map[i.CurrentStepDefID]
          if (!s) return false
          var t = String(s.stepType || '').toUpperCase()
          return t === 'APPROVE' || t === 'SIGN' || t === 'REVIEW'
        })
      },
      overdueInstances: function () {
        var now = new Date()
        return this.openInstances.filter(function (i) {
          return i.StepDueDate && new Date(i.StepDueDate) < now
        })
      },
      countByStatus: function () {
        var map = {}
        ;(this.instances || []).forEach(function (i) {
          var k = i.Status || 'OTHER'
          map[k] = (map[k] || 0) + 1
        })
        return map
      },
      statusSegments: function () {
        var c = this.countByStatus
        var total = (this.instances || []).length || 1
        var defs = [
          { key: 'RUNNING', label: 'Đang chạy', color: '#2b6fd6' },
          { key: 'WAITING_ME', label: 'Chờ xử lý', color: '#c2a35a' },
          { key: 'COMPLETED', label: 'Hoàn tất', color: '#7aa37a' },
          { key: 'CANCELLED', label: 'Đã hủy', color: '#cfcdc5' }
        ]
        return defs.map(function (d) {
          var count = c[d.key] || 0
          return { key: d.key, label: d.label, color: d.color, count: count, pct: Math.round((count / total) * 100) }
        }).filter(function (d) { return d.count > 0 })
      },
      workload: function () {
        var map = {}
        this.openInstances.forEach(function (i) {
          var name = i.AssigneeName || i.NextSigner || 'Chưa phân công'
          map[name] = (map[name] || 0) + 1
        })
        var rows = Object.keys(map).map(function (k) { return { name: k, count: map[k] } })
        var max = rows.reduce(function (m, r) { return Math.max(m, r.count) }, 0) || 1
        rows.forEach(function (r) { r.pct = Math.round((r.count / max) * 100) })
        rows.sort(function (a, b) { return b.count - a.count })
        return rows.slice(0, 6)
      },
      recent: function () {
        return (this.instances || []).slice().sort(function (a, b) {
          return new Date(b.UpdateTime || b.CreateTime || 0) - new Date(a.UpdateTime || a.CreateTime || 0)
        }).slice(0, 6)
      }
    },
    methods: {
      stepNameOf: function (inst) {
        var s = this.stepMap[inst.CurrentStepDefID]
        return s ? String(s.tenCot || '').replace(/^\d+\.\s*/, '') : (inst.CurrentStepName || '')
      },
      getStatusColor: function (s, hex) {
        var hexMap = { RUNNING: '#2b6fd6', WAITING_ME: '#c2a35a', COMPLETED: '#7aa37a', CANCELLED: '#cfcdc5' }
        if (hex) return hexMap[s] || '#cbd5e1'
        return { RUNNING: 'blue', WAITING_ME: 'warning', COMPLETED: 'success', CANCELLED: 'grey' }[s] || 'grey'
      },
      isOverdue: function (date) {
        return date && new Date(date) < new Date()
      },
      formatDate: function (val) {
        if (!val) return '—'
        var d = new Date(val)
        if (isNaN(d.getTime())) return val
        return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0')
      }
    }
	}
</script>