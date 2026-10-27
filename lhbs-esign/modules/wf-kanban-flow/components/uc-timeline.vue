<template>
	<div class="gantt-root">
    <!-- ══ TOOLBAR ══════════════════════════════════════════════════════ -->
    <div class="gantt-toolbar">
      <div class="gantt-toolbar-left">
        <v-btn icon size="x-small" variant="text" color="default" @click="prevMonth">
          <v-icon size="16">mdi-chevron-left</v-icon>
        </v-btn>
        <v-btn icon size="x-small" variant="text" color="default" @click="nextMonth">
          <v-icon size="16">mdi-chevron-right</v-icon>
        </v-btn>
        <v-btn size="small" variant="text" class="gantt-today-btn" @click="goToday">Hôm nay</v-btn>
        <div class="gantt-current-month ml-2 font-weight-bold" style="font-size: 14px; color: #1a1d21;">
          {{ monthNames[viewMonth] }} {{ viewYear }}
        </div>
      </div>
      <div class="gantt-toolbar-right">
        <span class="text-caption text-grey mr-2">Độ rộng ngày: {{ cellWidth }}px</span>
      </div>
    </div>

    <!-- ══ BODY ══════════════════════════════════════════════════════════ -->
    <div class="gantt-body">
      <!-- Left panel: Step groups & task list -->
      <div class="gantt-left-panel" ref="leftPanel" @scroll="syncScrollLeft">
        <div class="gantt-left-header">
          <span class="font-weight-bold" style="font-size: 12px; color: #5f6368;">Quy trình & Công việc</span>
          <div class="d-flex align-center" style="font-size: 10px; font-weight: 600; color: #80868b; gap: 12px; width: 140px; justify-content: flex-end; margin-right: 82px;">
            <span style="width: 40px; text-align: center;">BẮT ĐẦU</span>
            <span style="width: 40px; text-align: center;">HẠN CHÓT</span>
            <span style="width: 40px; text-align: center;">XONG</span>
          </div>
        </div>

        <template v-for="cot in dsCot" :key="'col-' + cot.id">
          <!-- Step group header row -->
          <div class="gantt-stage-group-header" style="height: 40px; display: flex; align-items: center;" @click="toggleGroup(cot.id)">
            <v-icon size="16" class="mr-1" color="grey-darken-1">
              {{ collapsedGroups[cot.id] ? 'mdi-chevron-right' : 'mdi-chevron-down' }}
            </v-icon>
            <div class="gantt-stage-color-dot" :style="{ backgroundColor: cot.mau || '#cbd5e1' }"></div>
            <span class="text-truncate" style="font-size: 12px; font-weight: 700;">{{ cot.tenCot }}</span>
            <span class="text-caption text-grey ml-1 font-weight-normal">({{ getTasksForStep(cot).length }})</span>
          </div>

          <!-- Task rows under step group -->
          <template v-if="!collapsedGroups[cot.id]">
            <div v-for="the in getTasksForStep(cot)" :key="'task-left-' + the.id" class="gantt-task-row-left">
              <!-- Checkbox Done -->
              <div class="mr-2.5 d-flex align-center">
                <v-icon v-if="the.StepExecutionStatus === 'DONE'" color="success" size="18">mdi-checkbox-marked</v-icon>
                <v-icon v-else color="grey-lighten-1" size="18">mdi-checkbox-blank-outline</v-icon>
              </div>

              <!-- Task title -->
              <div class="gantt-task-title-cell text-left" @click="$emit('open-card', the)" :title="the.tieuDe" style="font-size: 12px; font-weight: 500;">
                {{ the.tieuDe }}
              </div>

              <!-- Dates cell -->
              <div class="gantt-task-dates-cell">
                <span style="width: 40px; text-align: center;">{{ formatShortDate(the.StepStartDate || the.StartDate) || '--/--' }}</span>
                <span style="width: 40px; text-align: center;">{{ formatShortDate(the.StepDueDate || the.DueDate) || '--/--' }}</span>
                <span style="width: 40px; text-align: center;">{{ formatShortDate(the.CompletedDate || (the.StepExecutionStatus === 'DONE' ? the.UpdateTime : null)) || '--' }}</span>
              </div>

              <!-- Status Badge -->
              <div class="gantt-task-status-cell">
                <v-chip v-if="the.StepExecutionStatus === 'DONE'" size="x-small" color="success" variant="flat" style="font-size: 9px; height: 16px; border-radius: 4px; font-weight: 700;">DONE</v-chip>
                <v-chip v-else-if="checkQuaHan(the.StepDueDate || the.DueDate, the)" size="x-small" color="error" variant="flat" style="font-size: 9px; height: 16px; border-radius: 4px; font-weight: 700;">LATE</v-chip>
                <v-chip v-else size="x-small" color="primary" variant="flat" style="font-size: 9px; height: 16px; border-radius: 4px; font-weight: 700;">TODO</v-chip>
              </div>
            </div>

            <!-- Empty Row if no tasks -->
            <div v-if="getTasksForStep(cot).length === 0" class="d-flex align-center px-8 text-caption text-grey bg-grey-lighten-5 italic" style="height: 40px; border-bottom: 1px solid #f1f5f9; font-size: 11px;">
              Chưa có công việc nào
            </div>
          </template>
        </template>
      </div>

      <!-- Right panel: Calendar Timeline -->
      <div class="gantt-timeline-wrapper" ref="timelineWrapper" @scroll="syncScrollRight">
        <div class="gantt-timeline-inner" :style="{ width: totalWidth + 'px' }">
          <!-- Week Header Row -->
          <div class="gantt-header-weeks">
            <div v-for="wk in weekGroups" :key="wk.label" class="gantt-week-cell" :style="{ width: (wk.days.length * cellWidth) + 'px' }">
              {{ wk.label }}
            </div>
          </div>

          <!-- Day Header Row -->
          <div class="gantt-header-days">
            <div v-for="d in daysInMonth" :key="d.day" class="gantt-day-cell" :class="{ 'gantt-day-today': d.isToday, 'gantt-day-weekend': d.isWeekend }" :style="{ width: cellWidth + 'px' }">
              {{ d.day }}
            </div>
          </div>

          <!-- Rows (matched with left panel) -->
          <template v-for="cot in dsCot" :key="'grid-col-' + cot.id">
            <!-- Shaded placeholder for step header -->
            <div class="gantt-task-row" style="background: #f8fafc; border-bottom: 1px solid #e2e8f0; height: 40px;"></div>

            <!-- Task row content -->
            <template v-if="!collapsedGroups[cot.id]">
              <div v-for="the in getTasksForStep(cot)" :key="'grid-task-' + the.id" class="gantt-task-row">
                <!-- Grid day columns background -->
                <div v-for="d in daysInMonth" :key="'col-' + d.day" class="gantt-col-bg" :class="{ 'gantt-col-weekend': d.isWeekend, 'gantt-col-today': d.isToday }" :style="{ left: ((d.day - 1) * cellWidth) + 'px', width: cellWidth + 'px' }"></div>

                <!-- Task Bar -->
                <div v-if="hasValidDates(the)" class="gantt-task-bar" :style="getTaskBarStyle(the, cot)" @click="$emit('open-card', the)">
                  <span class="gantt-task-label">{{ the.tieuDe }}</span>
                  <v-icon v-if="the.StepExecutionStatus === 'DONE'" size="11" class="gantt-task-warn">mdi-check-circle</v-icon>
                </div>

                <!-- Floating Assignee detail to the right of task bar -->
                <div v-if="hasValidDates(the) && (the.AssigneeName || the.nguoiPhuTrach || the.NextSigner)" :style="getAssigneeStyle(the, cot)">
                  <uc-avatar :name="the.AssigneeName || the.nguoiPhuTrach || the.NextSigner" :image="the.AssigneeAvatar || the.Avatar" :size="18" font-size="8px" />
                  <span class="ml-1 text-grey-darken-2" style="font-size: 10px; font-weight: 500;">{{ the.AssigneeName || the.nguoiPhuTrach || the.NextSigner }}</span>
                </div>
              </div>

              <!-- Empty grid row if no tasks -->
              <div v-if="getTasksForStep(cot).length === 0" class="gantt-task-row" style="background: #fdfdfd; height: 40px; border-bottom: 1px solid #f1f5f9;">
                <div v-for="d in daysInMonth" :key="'empty-col-' + d.day" class="gantt-col-bg" :class="{ 'gantt-col-weekend': d.isWeekend, 'gantt-col-today': d.isToday }" :style="{ left: ((d.day - 1) * cellWidth) + 'px', width: cellWidth + 'px' }"></div>
              </div>
            </template>
          </template>

          <!-- Today red vertical line -->
          <div v-if="todayOffset >= 0" class="gantt-today-line" :style="{ left: todayOffset + 'px' }"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-timeline',
  props: {
    dsThe: {
      type: Array,
      default: () => []
    },
    dsCot: {
      type: Array,
      default: () => []
    }
  },
  data() {
    const today = new Date()
    return {
      cellWidth: 34,
      viewYear: today.getFullYear(),
      viewMonth: today.getMonth(), // 0-indexed
      collapsedGroups: {},

      monthNames: ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
        'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'],
      shortMonthNames: ['Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
        'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12'],

      isSyncingLeftScroll: false,
      isSyncingRightScroll: false
    }
  },
  computed: {
    daysInMonth() {
      const total = new Date(this.viewYear, this.viewMonth + 1, 0).getDate()
      const days = []
      const today = new Date()
      for (let d = 1; d <= total; d++) {
        const date = new Date(this.viewYear, this.viewMonth, d)
        const dow = date.getDay()
        days.push({
          day: d,
          isToday: today.getFullYear() === this.viewYear &&
            today.getMonth() === this.viewMonth &&
            today.getDate() === d,
          isWeekend: dow === 0 || dow === 6,
        })
      }
      return days
    },

    weekGroups() {
      const groups = []
      const mn = this.shortMonthNames[this.viewMonth]
      let week = null
      this.daysInMonth.forEach(function (d) {
        const wk = Math.ceil(d.day / 7)
        if (!week || week.wk !== wk) {
          week = { wk: wk, days: [], label: '' }
          groups.push(week)
        }
        week.days.push(d)
      })
      groups.forEach(function (g) {
        const first = g.days[0].day
        const last = g.days[g.days.length - 1].day
        g.label = mn + ' ' + first + ' - ' + mn + ' ' + last
      })
      return groups
    },

    totalWidth() {
      return this.daysInMonth.length * this.cellWidth
    },

    todayOffset() {
      const today = new Date()
      if (today.getFullYear() === this.viewYear && today.getMonth() === this.viewMonth) {
        return (today.getDate() - 1) * this.cellWidth + Math.floor(this.cellWidth / 2)
      }
      return -1
    }
  },
  methods: {
    toggleGroup(id) {
      this.collapsedGroups = {
        ...this.collapsedGroups,
        [id]: !this.collapsedGroups[id]
      }
    },

    getTasksForStep(cot) {
      if (!cot || !cot.id) return []
      return this.dsThe.filter(t => {
        if (cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS') {
          return t.Status === 'COMPLETED' || t.Status === 'SUCCESS' || t.CurrentStepDefID === cot.id
        }
        if (cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE') {
          return t.Status === 'REJECTED' || t.Status === 'CANCELLED' || t.Status === 'FAILURE' || t.CurrentStepDefID === cot.id
        }

        const isFinished = t.Status === 'COMPLETED' || t.Status === 'SUCCESS' || t.Status === 'REJECTED' || t.Status === 'CANCELLED' || t.Status === 'FAILURE'
        if (isFinished) return false

        if (t.CurrentStepDefID) return t.CurrentStepDefID === cot.id
        if (t.CurrentStepOrder !== undefined && cot.order !== undefined) return t.CurrentStepOrder === cot.order
        return false
      })
    },

    parseDate(dStr) {
      if (!dStr) return null
      const d = new Date(dStr)
      return isNaN(d.getTime()) ? null : d
    },

    getTaskStartEnd(the) {
      let start = this.parseDate(the.StepStartDate || the.StartDate || the.CreateTime || the.ngayTao)
      let end = this.parseDate(the.StepDueDate || the.DueDate || the.StepStartDate || the.UpdateTime || the.ngayCapNhatCuoi)

      if (!start && !end) {
        start = new Date()
        end = new Date()
      } else if (!start) {
        start = new Date(end.getTime())
      } else if (!end) {
        end = new Date(start.getTime())
      }
      return { start, end }
    },

    hasValidDates(the) {
      const { start, end } = this.getTaskStartEnd(the)
      return start !== null && end !== null
    },

    getTaskBarStyle(the, cot) {
      const { start, end } = this.getTaskStartEnd(the)
      if (!start || !end) return { display: 'none' }

      const viewStart = new Date(this.viewYear, this.viewMonth, 1)
      const viewEnd = new Date(this.viewYear, this.viewMonth + 1, 0)

      if (end < viewStart || start > viewEnd) return { display: 'none' }

      const dayStart = start < viewStart ? 1 : start.getDate()
      const dayEnd = end > viewEnd ? viewEnd.getDate() : end.getDate()

      const left = (dayStart - 1) * this.cellWidth + 4
      const width = Math.max(12, (dayEnd - dayStart + 1) * this.cellWidth - 8)

      return {
        position: 'absolute',
        left: left + 'px',
        width: width + 'px',
        backgroundColor: this.getTaskBarColor(the, cot),
        zIndex: 2
      }
    },

    getAssigneeStyle(the, cot) {
      const { start, end } = this.getTaskStartEnd(the)
      if (!start || !end) return { display: 'none' }

      const viewStart = new Date(this.viewYear, this.viewMonth, 1)
      const viewEnd = new Date(this.viewYear, this.viewMonth + 1, 0)

      if (end < viewStart || start > viewEnd) return { display: 'none' }

      const dayStart = start < viewStart ? 1 : start.getDate()
      const dayEnd = end > viewEnd ? viewEnd.getDate() : end.getDate()

      const left = (dayEnd - 1) * this.cellWidth + this.cellWidth + 8
      return {
        position: 'absolute',
        left: left + 'px',
        display: 'flex',
        alignItems: 'center',
        height: '24px',
        top: '8px',
        zIndex: 2,
        pointerEvents: 'none',
        whiteSpace: 'nowrap'
      }
    },

    getTaskBarColor(the, cot) {
      if (the.StepExecutionStatus === 'DONE') return '#2a9d5b' // Green
      if (this.checkQuaHan(the.StepDueDate || the.DueDate, the)) return '#dc3545' // Red
      return cot.mau || '#5b8fd6'
    },

    formatShortDate(ngay) {
      if (!ngay) return ''
      const d = new Date(ngay)
      if (isNaN(d.getTime())) return ''
      const pad = (n) => String(n).padStart(2, '0')
      return pad(d.getDate()) + '/' + pad(d.getMonth() + 1)
    },

    checkQuaHan(ngay, the) {
      if (!ngay) return false
      if (the && (the.StepExecutionStatus === 'DONE' || the.Status === 'COMPLETED' || the.Status === 'SUCCESS')) return false
      const d = new Date(ngay)
      if (isNaN(d.getTime())) return false
      return d < new Date()
    },

    prevMonth() {
      if (this.viewMonth === 0) {
        this.viewMonth = 11
        this.viewYear--
      } else {
        this.viewMonth--
      }
    },

    nextMonth() {
      if (this.viewMonth === 11) {
        this.viewMonth = 0
        this.viewYear++
      } else {
        this.viewMonth++
      }
    },

    goToday() {
      const today = new Date()
      this.viewYear = today.getFullYear()
      this.viewMonth = today.getMonth()
    },

    syncScrollLeft(e) {
      if (this.isSyncingRightScroll) {
        this.isSyncingRightScroll = false
        return
      }
      this.isSyncingLeftScroll = true
      const left = this.$refs.leftPanel
      const right = this.$refs.timelineWrapper
      if (left && right) {
        right.scrollTop = left.scrollTop
      }
    },

    syncScrollRight(e) {
      if (this.isSyncingLeftScroll) {
        this.isSyncingLeftScroll = false
        return
      }
      this.isSyncingRightScroll = true
      const left = this.$refs.leftPanel
      const right = this.$refs.timelineWrapper
      if (left && right) {
        left.scrollTop = right.scrollTop
      }
    }
  }
	}
</script>