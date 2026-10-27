<template>
	<div class="px-5 py-4">
		<div class="wf-gantt-container">
			<div class="d-flex align-center justify-space-between px-4 py-3 border-bottom bg-white flex-wrap ga-3">
				<div>
					<div class="text-subtitle-1 font-weight-bold text-grey-darken-4">Lộ trình dự án</div>
					<div class="text-caption text-grey-darken-1">{{ formatDateRangeLabel }}</div>
				</div>

				<div class="d-flex align-center ga-2 flex-wrap">
					<v-btn-toggle v-model="viewMode" density="compact" mandatory color="primary" class="bg-white">
						<v-btn value="day" size="small" class="text-capitalize" height="32" style="font-size: 11px;">
							Ngày</v-btn>
						<v-btn value="week" size="small" class="text-capitalize" height="32" style="font-size: 11px;">
							Tuần</v-btn>
						<v-btn value="month" size="small" class="text-capitalize" height="32" style="font-size: 11px;">
							Tháng</v-btn>
					</v-btn-toggle>

					<v-divider vertical class="mx-1 align-self-stretch" />

					<v-btn variant="outlined" color="grey-darken-2" height="32"
						class="font-weight-medium px-3 text-capitalize" style="font-size: 11px;"
						@click="monthOffset = 0">
						Hôm nay
					</v-btn>
					<v-btn icon size="32" variant="outlined" color="grey-darken-2" @click="monthOffset--">
						<v-icon size="18">mdi-chevron-left</v-icon>
					</v-btn>
					<v-btn icon size="32" variant="outlined" color="grey-darken-2" @click="monthOffset++">
						<v-icon size="18">mdi-chevron-right</v-icon>
					</v-btn>

					<v-btn variant="outlined" color="grey-darken-2" height="32"
						class="font-weight-medium px-3 text-capitalize" style="font-size: 11px;" @click="exportCSV">
						<v-icon start size="14">mdi-download</v-icon>
						Xuất CSV
					</v-btn>
				</div>
			</div>

			<div class="wf-gantt-scroll-area" style="max-height: calc(100vh - 240px);">
				<div class="wf-gantt-grid" :style="gridStyle">

					<div class="wf-gantt-header-row">
						<div class="wf-gantt-title-col-header"
							style="width: 320px; height: 72px; display: flex; align-items: center; padding-left: 16px; font-size: 11px; font-weight: bold; color: #64748b; text-transform: uppercase;">
							Tên nhiệm vụ
						</div>

						<div class="wf-gantt-timeline-headers" :style="headersStyle">
							<div class="wf-gantt-months-row">
								<div v-for="(m, idx) in timelineMonths" :key="idx"
									class="text-caption font-weight-bold text-grey-darken-2 d-flex align-center justify-center border-right text-uppercase"
									:style="m.style">
									{{ m.label }}
								</div>
							</div>
							<div class="wf-gantt-weeks-row">
								<div v-for="(w, idx) in timelineColumns" :key="idx"
									class="text-caption font-weight-semibold text-grey-darken-1 d-flex align-center justify-center border-right"
									:class="{ 'bg-blue-lighten-5 text-primary font-weight-bold': isColCurrent(w) }"
									:style="w.style">
									{{ w.label }}
								</div>
							</div>
						</div>
					</div>

					<div v-if="todayPercent !== null" class="wf-gantt-today-line" :style="todayLineStyle">
						<div class="wf-gantt-today-tag">TODAY</div>
					</div>

					<div v-for="group in groups" :key="group.status" class="wf-gantt-group-wrapper">
						<div class="wf-gantt-row wf-gantt-row-group" style="height: 36px; align-items: center;">
							<div class="wf-gantt-group-title-cell"
								style="width: 320px; height: 100%; display: flex; align-items: center; padding: 0 16px; cursor: pointer;"
								@click="toggleGroup(group.status)">
								<v-icon size="16" class="mr-1">
									{{ collapsedGroups[group.status] ? 'mdi-chevron-right' : 'mdi-chevron-down' }}
								</v-icon>
								<span class="wf-gantt-group-dot mr-2" :style="{ background: group.color }"></span>
								<span class="text-caption font-weight-bold text-grey-darken-3"
									style="font-size: 12px !important;">{{ group.label }}</span>
								<v-chip size="x-small" variant="tonal" class="font-weight-bold ml-2 px-1"
									:style="group.chipStyle">
									{{ group.items.length }}
								</v-chip>
							</div>
							<div :style="fillRowStyle">
								<div v-for="w in timelineColumns" :key="w.key" class="wf-gantt-col-line"
									:style="w.style"></div>
							</div>
						</div>

						<div v-if="!collapsedGroups[group.status]">
							<div v-for="item in group.items" :key="item.WorkItemID" class="wf-gantt-row"
								style="height: 44px; align-items: center;" @click="$emit('open-card', item)">
								<div class="wf-gantt-item-title-cell"
									style="width: 320px; height: 100%; display: flex; align-items: center; padding-left: 36px; padding-right: 16px; overflow: hidden;">
									<span class="text-caption font-weight-medium text-grey-darken-4 text-truncate"
										style="font-size: 13px !important;" :title="item.Title">
										{{ item.Title }}
									</span>
								</div>

								<div class="wf-gantt-timeline-area" :style="timelineAreaStyle">
									<div :style="fillRowStyle">
										<div v-for="w in timelineColumns" :key="w.key" class="wf-gantt-col-line"
											:style="w.style"></div>
									</div>

									<div v-if="item.ganttHasCoords" class="wf-gantt-bar-wrapper"
										:style="item.ganttStyle">
										<div class="wf-gantt-bar text-truncate" :style="{ background: group.color }">
											{{ item.ganttBarText }}
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>

					<div v-if="workItems.length === 0" class="text-center py-10" :style="emptyStyle">
						<v-icon size="40" color="grey-lighten-1">mdi-calendar-blank-outline</v-icon>
						<div class="text-caption text-grey mt-2">Chưa có nhiệm vụ nào.</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-space-timeline',
		props: {
			workItems: { type: Array, default: () => [] }
		},
		emits: ['open-card'],
		data() {
			return {
				monthOffset: 0,
				viewMode: 'week',
				collapsedGroups: {}
			}
		},
		computed: {
			colWidth() {
				if (this.viewMode === 'day') return 45
				if (this.viewMode === 'week') return 100
				return 300
			},
			totalGridWidth() {
				return this.timelineColumns.length * this.colWidth
			},
			gridStyle() {
				return { minWidth: (320 + this.totalGridWidth) + 'px' }
			},
			headersStyle() {
				return { width: this.totalGridWidth + 'px', height: '72px' }
			},
			fillRowStyle() {
				return { width: this.totalGridWidth + 'px', height: '100%', display: 'flex' }
			},
			timelineAreaStyle() {
				return { width: this.totalGridWidth + 'px', height: '100%' }
			},
			emptyStyle() {
				return { width: (320 + this.totalGridWidth) + 'px' }
			},
			timelineStartDate() {
				const d = new Date()
				d.setDate(1)
				d.setHours(0, 0, 0, 0)
				d.setMonth(d.getMonth() + this.monthOffset)
				return d
			},
			timelineEndDate() {
				const d = new Date(this.timelineStartDate)
				if (this.viewMode === 'day') {
					d.setMonth(d.getMonth() + 1)
				} else {
					d.setMonth(d.getMonth() + 3)
				}
				d.setDate(0)
				d.setHours(23, 59, 59, 999)
				return d
			},
			timelineColumns() {
				const cols = []
				const start = new Date(this.timelineStartDate)
				const end = new Date(this.timelineEndDate)
				
				if (this.viewMode === 'day') {
					const current = new Date(start)
					while (current <= end) {
						const dayStart = new Date(current)
						dayStart.setHours(0, 0, 0, 0)
						const dayEnd = new Date(current)
						dayEnd.setHours(23, 59, 59, 999)
						
						cols.push({
							key: current.toISOString().slice(0, 10),
							label: String(current.getDate()).padStart(2, '0'),
							startDate: dayStart,
							endDate: dayEnd,
							monthLabel: 'Tháng ' + (current.getMonth() + 1) + ' ' + current.getFullYear(),
							style: { width: this.colWidth + 'px', fontSize: '10px' }
						})
						current.setDate(current.getDate() + 1)
					}
				} else if (this.viewMode === 'week') {
					const day = start.getDay()
					const diff = start.getDate() - day + (day === 0 ? -6 : 1)
					const current = new Date(start.setDate(diff))
					current.setHours(0, 0, 0, 0)
					
					while (current <= end) {
						const wStart = new Date(current)
						const wEnd = new Date(current)
						wEnd.setDate(wEnd.getDate() + 6)
						wEnd.setHours(23, 59, 59, 999)
						
						cols.push({
							key: wStart.toISOString().slice(0, 10),
							label: 'T' + this.getWeekNumber(wStart),
							startDate: wStart,
							endDate: wEnd,
							monthLabel: 'Tháng ' + (wStart.getMonth() + 1) + ' ' + wStart.getFullYear(),
							style: { width: this.colWidth + 'px', fontSize: '10px' }
						})
						current.setDate(current.getDate() + 7)
					}
				} else {
					const current = new Date(start)
					while (current <= end) {
						const mStart = new Date(current.getFullYear(), current.getMonth(), 1, 0, 0, 0, 0)
						const mEnd = new Date(current.getFullYear(), current.getMonth() + 1, 0, 23, 59, 59, 999)
						
						cols.push({
							key: current.getFullYear() + '-' + current.getMonth(),
							label: 'Tháng ' + (current.getMonth() + 1),
							startDate: mStart,
							endDate: mEnd,
							monthLabel: String(current.getFullYear()),
							style: { width: this.colWidth + 'px', fontSize: '10px' }
						})
						current.setMonth(current.getMonth() + 1)
					}
				}
				return cols
			},
			timelineMonths() {
				const cols = this.timelineColumns
				const groups = []
				if (!cols.length) return []
				
				let currentGroup = { label: cols[0].monthLabel, colspan: 1 }
				groups.push(currentGroup)
				
				for (let i = 1; i < cols.length; i++) {
					if (cols[i].monthLabel === currentGroup.label) {
						currentGroup.colspan++
					} else {
						currentGroup = { label: cols[i].monthLabel, colspan: 1 }
						groups.push(currentGroup)
					}
				}
				
				for (let i = 0; i < groups.length; i++) {
					groups[i].style = {
						width: (groups[i].colspan * this.colWidth) + 'px',
						fontSize: '10px',
						background: '#f8fafc'
					}
				}
				return groups
			},
			formatDateRangeLabel() {
				const cols = this.timelineColumns
				if (!cols.length) return ''
				const start = cols[0].startDate
				const end = cols[cols.length - 1].endDate
				return this.formatDateSimple(start) + ' – ' + this.formatDateSimple(end)
			},
			todayPercent() {
				const cols = this.timelineColumns
				if (!cols.length) return null
				const today = new Date().getTime()
				const timelineStart = cols[0].startDate.getTime()
				const timelineEnd = cols[cols.length - 1].endDate.getTime()
				
				if (today < timelineStart || today > timelineEnd) return null
				return ((today - timelineStart) / (timelineEnd - timelineStart)) * 100
			},
			todayLineStyle() {
				if (this.todayPercent === null) return null
				return { left: (320 + this.todayPercent * this.totalGridWidth / 100) + 'px' }
			},
			processedItems() {
				const cols = this.timelineColumns
				if (!cols.length) return []
				const timelineStart = cols[0].startDate.getTime()
				const timelineEnd = cols[cols.length - 1].endDate.getTime()
				const totalMs = timelineEnd - timelineStart
				const gridWidth = this.totalGridWidth
				
				return (this.workItems || []).map(item => {
					let start = item.CreateTime ? new Date(item.CreateTime) : null
					if (start && !isNaN(start.getTime())) {
						start.setHours(0, 0, 0, 0)
					}
					let end = item.DueDate ? new Date(item.DueDate) : null
					if (end && !isNaN(end.getTime())) {
						end.setHours(23, 59, 59, 999)
					}
					let hasCoords = true
					let sTime = 0
					let eTime = 0
					
					if (!start && !end) {
						hasCoords = false
					} else {
						if (!start) start = new Date(timelineStart)
						if (!end) end = new Date(start.getTime() + 3 * 24 * 3600 * 1000)
						
						sTime = start.getTime()
						eTime = end.getTime()
						
						if (eTime < timelineStart || sTime > timelineEnd) {
							hasCoords = false
						} else {
							if (sTime < timelineStart) sTime = timelineStart
							if (eTime > timelineEnd) eTime = timelineEnd
						}
					}
					
					let leftPercent = 0
					let widthPercent = 0
					let styleObj = null
					
					if (hasCoords) {
						leftPercent = ((sTime - timelineStart) / totalMs) * 100
						widthPercent = ((eTime - sTime) / totalMs) * 100
						if (widthPercent < 1) widthPercent = 1
						
						styleObj = {
							left: (leftPercent * gridWidth / 100) + 'px',
							width: (widthPercent * gridWidth / 100) + 'px'
						}
					}
					
					const sStr = start ? (start.getDate() + '/' + (start.getMonth() + 1)) : '?'
					const eStr = end ? (end.getDate() + '/' + (end.getMonth() + 1)) : '?'
					const barText = (start || end) ? (sStr + ' - ' + eStr) : ''
					
					return {
						...item,
						ganttHasCoords: hasCoords,
						ganttStyle: styleObj,
						ganttBarText: barText
					}
				})
			},
			groups() {
				const items = this.processedItems || []
				const statusConfig = [
					{ status: 'BACKLOG', label: 'Backlog', color: '#94a3b8' },
					{ status: 'TODO', label: 'Cần làm', color: '#2563eb' },
					{ status: 'IN_PROGRESS', label: 'Đang làm', color: '#d97706' },
					{ status: 'DONE', label: 'Hoàn tất', color: '#16a34a' },
					{ status: 'BLOCKED', label: 'Bị chặn', color: '#dc2626' }
				]
				
				const res = []
				for (let i = 0; i < statusConfig.length; i++) {
					const cfg = statusConfig[i]
					const groupItems = items.filter(w => w.Status === cfg.status)
					if (groupItems.length > 0) {
						res.push({
							status: cfg.status,
							label: cfg.label,
							color: cfg.color,
							items: groupItems,
							chipStyle: { color: cfg.color, background: cfg.color + '1a' }
						})
					}
				}
				return res
			}
		},
		methods: {
			getWeekNumber(d) {
				const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
				const dayNum = date.getUTCDay() || 7
				date.setUTCDate(date.getUTCDate() + 4 - dayNum)
				const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
				return Math.ceil((((date - yearStart) / 86400000) + 1) / 7)
			},
			isColCurrent(col) {
				const now = new Date()
				return now >= col.startDate && now <= col.endDate
			},
			toggleGroup(status) {
				this.collapsedGroups[status] = !this.collapsedGroups[status]
				this.$forceUpdate()
			},
			formatDateSimple(date) {
				if (!date) return ''
				const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
				return months[date.getMonth()] + ' ' + date.getDate() + ', ' + date.getFullYear()
			},
			exportCSV() {
				const rows = (this.workItems || []).filter(i => i.DueDate || i.CreateTime)
				if (!rows.length) { showToast.info('Không có dữ liệu để xuất.'); return }
				const headers = ['ID', 'Tên nhiệm vụ', 'Trạng thái', 'Độ ưu tiên', 'Bắt đầu', 'Hạn chót']
				let csv = headers.join(',') + '\n'
				rows.forEach(i => {
					csv += [
						i.WorkItemID,
						'"' + (i.Title || '').split('"').join('""') + '"',
						i.Status || '',
						i.Priority || '',
						i.CreateTime || '',
						i.DueDate || ''
					].join(',') + '\n'
				})
				const blob = new Blob([String.fromCharCode(0xFEFF) + csv], { type: 'text/csv;charset=utf-8;' })
				const url = URL.createObjectURL(blob)
				const a = document.createElement('a')
				a.href = url
				a.download = 'danh-sach-timeline-' + new Date().toISOString().slice(0, 10) + '.csv'
				a.click()
				URL.revokeObjectURL(url)
			}
		}
	}
</script>