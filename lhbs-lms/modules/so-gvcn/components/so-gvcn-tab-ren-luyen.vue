<template>
	<v-card class="d-flex flex-column h-100 overflow-hidden">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2 flex-shrink-0">
			Chọn một lớp ở thanh trên để xem và nhập hồ sơ theo dõi quá trình rèn luyện của học sinh lớp đó.
		</v-alert>
		<template v-else>
			<!-- Phần header (alert + panel hướng dẫn): flex-shrink để không chiếm hết chiều cao -->
			<div class="pa-2 pb-0 flex-shrink-0">
				<v-alert v-if="showAttendanceAlert && attendanceWarnings.length" type="warning" variant="tonal" density="compact" closable class="mb-2"
					@click:close="$emit('close-attendance-alert')">
					<div class="font-weight-bold">Cảnh báo chuyên cần</div>
					<div v-for="warning in attendanceWarnings" :key="warning.key" class="text-body-2 mt-1">
						{{ warning.text }}
					</div>
				</v-alert>
				<v-expansion-panels class="mb-2">
					<v-expansion-panel>
						<v-expansion-panel-title class="text-subtitle-1 font-weight-bold py-2 px-3 text-primary"
							style="min-height: 48px;">
							<v-icon start color="primary" class="mr-2">mdi-information-outline</v-icon>
							THEO DÕI QUÁ TRÌNH RÈN LUYỆN CỦA HỌC SINH LỚP {{ selectedClass?.TenLop || '.......' }} NĂM HỌC
							{{ schoolYearText }}
						</v-expansion-panel-title>
						<v-expansion-panel-text class="text-caption text-medium-emphasis">
							<div class="font-weight-bold mb-1">Cột từng tháng:</div>
							<ul class="pl-4 mb-0">
								<li>Ghi tóm tắt vi phạm, tái phạm, số ngày nghỉ, thời gian/xử lí/có mời PH/có cam kết lần...
								</li>
								<li>Ghi nhận tiến bộ về mặt nào đó, thành tích, đóng góp.</li>
							</ul>
						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>
			</div>

			<!-- flex-grow để sheet chiếm toàn bộ chiều cao còn lại sau panel hướng dẫn -->
			<div class="flex-grow-1 overflow-hidden so-gvcn-sheet so-gvcn-sheet-wrap" style="min-height: 0;">
				<template v-if="rows && rows.length">
					<div ref="sheetRef" class="w-100 h-100"></div>
				</template>
				<uc-card-empty v-else />
			</div>
		</template>
	</v-card>
</template>

<script>
	export default {
		name: 'so-gvcn-tab-ren-luyen',
		props: {
			selectedLopID: { type: String, default: '__ALL__' },
			selectedClass: { type: Object, default: null },
			schoolYearText: { type: String, default: '' },
			rows: { type: Array, default: () => [] },
			columns: { type: Array, default: () => [] },
			nestedHeaders: { type: Array, default: () => [] },
			attendanceSummaries: { type: Object, default: () => ({}) },
			attendanceLoading: { type: Boolean, default: false },
			showAttendanceAlert: { type: Boolean, default: false },
			sheetHeight: { type: String, default: 'calc(100vh - 175px)' },
			sheetKey: { type: [Number, String], default: 0 }
		},
		emits: ['update:rows', 'close-attendance-alert'],
		data() {
			return {
				instance: null,
				timer: null,
				savedScrollTop: 0,
				savedScrollLeft: 0,
				savedElScrollTop: 0,
				savedElScrollLeft: 0,
				savedSelection: null,
				lastSelection: null,
				lastActiveCell: null,
				_savedParentScrolls: null
			}
		},
		computed: {
			attendanceWarnings() {
				return Object.values(this.attendanceSummaries || {})
					.filter(item => item.warningLevel)
					.map(item => ({
						key: item.key,
						text: `${item.hoTen}: ${item.warningText}`
					}))
			}
		},
		watch: {
			selectedLopID(newVal, oldVal) {
				// Khi đổi sang lớp khác mới reset vị trí cuộn; cùng lớp thì giữ nguyên
				if (newVal !== oldVal) {
					this.savedScrollTop = 0
					this.savedScrollLeft = 0
					this.savedElScrollTop = 0
					this.savedElScrollLeft = 0
					this.savedSelection = null
					this.lastSelection = null
					this.lastActiveCell = null
					this._savedParentScrolls = null
				}
				this.scheduleInit()
			},
			sheetKey() {
				this.scheduleInit()
			},
			rows(newVal, oldVal) {
				// Không dùng deep: true để tránh re-init sheet khi user đang nhập liệu từng ô cell
				if (newVal !== oldVal) {
					this.scheduleInit()
				}
			}
		},
		mounted() {
			this.scheduleInit()
		},
		beforeUnmount() {
			if (this.timer) clearTimeout(this.timer)
			this.destroySheet()
		},
		methods: {
			getContentTableHeight(container, rowCount, nestedHeaderCount = 0) {
				const rowHeight = 28
				const naturalHeight = Math.max(96, (Math.max(1, Number(nestedHeaderCount) + 1) * rowHeight)
					+ (Math.max(1, Number(rowCount) || 0) * rowHeight) + 4)
				const viewportHeight = typeof soGvcnJspreadsheet === 'object'
					&& typeof soGvcnJspreadsheet.getTableHeight === 'function'
					? parseInt(soGvcnJspreadsheet.getTableHeight(container, '100%'), 10)
					: naturalHeight
				return `${Number.isFinite(viewportHeight) && viewportHeight > 0
					? Math.min(naturalHeight, viewportHeight)
					: naturalHeight}px`
			},
			getInstance() {
				return this.instance
			},
			getScrollElement() {
				const container = this.$refs.sheetRef
				if (!container) return null
				return container.querySelector('.jss_content, .jspreadsheet_content, .jexcel_content')
					|| container.querySelector('.jss_container, .jspreadsheet_container, .jexcel_container')
					|| container
			},
			// Lưu lại vị trí scroll (dọc, ngang) của table và các container cha trước khi re-render
			saveCurrentState() {
				const container = this.$refs.sheetRef
				if (!container) return
				const contentEl = this.getScrollElement()
				if (contentEl) {
					if (contentEl.scrollTop > 0) this.savedScrollTop = contentEl.scrollTop
					if (contentEl.scrollLeft > 0) this.savedScrollLeft = contentEl.scrollLeft
				}
				if (this.$el && (this.$el.scrollTop > 0 || this.$el.scrollLeft > 0)) {
					this.savedElScrollTop = this.$el.scrollTop
					this.savedElScrollLeft = this.$el.scrollLeft
				}
				let p = container.parentElement
				this._savedParentScrolls = new Map()
				while (p && p !== document.body) {
					if (p.scrollTop > 0 || p.scrollLeft > 0) {
						this._savedParentScrolls.set(p, { top: p.scrollTop, left: p.scrollLeft })
					}
					p = p.parentElement
				}
				const sheet = this.getInstance()
				if (sheet) {
					if (typeof sheet.getSelection === 'function') {
						const sel = sheet.getSelection()
						if (sel && sel.length) this.lastSelection = sel
					} else if (sheet.selectedCell) {
						this.lastSelection = sheet.selectedCell
					}
				}
			},
			// Phục hồi lại vị trí scroll và selection sau khi table khởi tạo lại dữ liệu
			restoreState() {
				const container = this.$refs.sheetRef
				if (!container) return
				const contentEl = this.getScrollElement()
				if (contentEl) {
					if (this.savedScrollTop > 0 || this.savedScrollLeft > 0) {
						contentEl.scrollTop = this.savedScrollTop
						contentEl.scrollLeft = this.savedScrollLeft
					}
				}
				if (this.$el && (this.savedElScrollTop > 0 || this.savedElScrollLeft > 0)) {
					this.$el.scrollTop = this.savedElScrollTop
					this.$el.scrollLeft = this.savedElScrollLeft
				}
				if (this._savedParentScrolls) {
					this._savedParentScrolls.forEach((pos, el) => {
						try { el.scrollTop = pos.top; el.scrollLeft = pos.left } catch (e) {}
					})
				}
				const sheet = this.getInstance()
				const targetSelection = this.lastSelection || this.savedSelection
				if (sheet && targetSelection) {
					try {
						const x1 = targetSelection[0]
						const y1 = targetSelection[1]
						const x2 = targetSelection[2] !== undefined ? targetSelection[2] : x1
						const y2 = targetSelection[3] !== undefined ? targetSelection[3] : y1
						if (typeof sheet.updateSelectionFromCoords === 'function') {
							sheet.updateSelectionFromCoords(x1, y1, x2, y2)
						}
					} catch (e) {}
				}
			},
			// Lắng nghe sự kiện cuộn thực tế của bảng jspreadsheet để luôn bắt kịp vị trí cuộn mới nhất
			attachRealtimeListeners(container) {
				if (!container) return
				const contentEl = this.getScrollElement()
				if (contentEl && !contentEl._hasScrollListener) {
					contentEl._hasScrollListener = true
					contentEl.addEventListener('scroll', () => {
						if (contentEl.scrollTop > 0 || contentEl.scrollLeft > 0) {
							this.savedScrollTop = contentEl.scrollTop
							this.savedScrollLeft = contentEl.scrollLeft
						}
					}, { passive: true })
				}
			},
			destroySheet() {
				if (!this.instance) return
				try {
					const s = Array.isArray(this.instance) ? this.instance[0] : this.instance
					if (s && typeof s.destroy === 'function') s.destroy()
				} catch (e) {}
				this.instance = null
			},
			scheduleInit() {
				if (this.selectedLopID === '__ALL__') {
					this.destroySheet()
					return
				}
				if (this.timer) clearTimeout(this.timer)
				this.timer = setTimeout(() => this.initSheet(), 50)
			},
			initSheet() {
				const container = this.$refs.sheetRef
				if (!container || !this.rows || !this.rows.length || this.selectedLopID === '__ALL__') {
					this.destroySheet()
					return
				}

				// Ghi nhớ vị trí scroll hiện tại trước khi hủy DOM cũ
				this.saveCurrentState()
				this.destroySheet()
				container.innerHTML = ''

				if (typeof jspreadsheet === 'undefined') {
					setTimeout(() => this.initSheet(), 100)
					return
				}

				const factory = (typeof soGvcnJspreadsheet !== 'undefined' && soGvcnJspreadsheet.create)
					? soGvcnJspreadsheet.create.bind(soGvcnJspreadsheet)
					: jspreadsheet

				this.instance = factory(container, {
					worksheets: [{
						data: Array.isArray(this.rows) ? this.rows : [],
						columns: (this.columns || []).map(column => (
							!column.readOnly && column.type !== 'numeric' && column.align !== 'center'
								? { ...column, align: 'justify' }
								: column
						)),
						nestedHeaders: this.nestedHeaders,
						rowResize: true,
						columnDrag: false,
						tableWidth: '100%',
						tableOverflow: true,
						tableHeight: this.getContentTableHeight(container, (this.rows || []).length, (this.nestedHeaders || []).length),
						lazyLoading: false,
						freezeColumns: 4,
						wordWrap: true,
						allowInsertColumn: false,
						allowInsertRow: false,
						showHeader: true
					}],
					contextMenu: () => false,
					onselection: (worksheet, x1, y1, x2, y2) => {
						this.lastSelection = [Number(x1), Number(y1), Number(x2 !== undefined ? x2 : x1), Number(y2 !== undefined ? y2 : y1)]
						this.lastActiveCell = { x: Number(x1), y: Number(y1) }
						const contentEl = this.getScrollElement()
						if (contentEl && (contentEl.scrollTop > 0 || contentEl.scrollLeft > 0)) {
							this.savedScrollTop = contentEl.scrollTop
							this.savedScrollLeft = contentEl.scrollLeft
						}
					},
					onchange: (worksheet, cell, x, y, value) => {
						this.lastActiveCell = { x: Number(x), y: Number(y) }
						this.lastSelection = [Number(x), Number(y), Number(x), Number(y)]
						const contentEl = this.getScrollElement()
						if (contentEl && (contentEl.scrollTop > 0 || contentEl.scrollLeft > 0)) {
							this.savedScrollTop = contentEl.scrollTop
							this.savedScrollLeft = contentEl.scrollLeft
						}
						if (Array.isArray(this.rows) && this.rows[y]) {
							this.rows[y][x] = value
							this.$emit('update:rows', this.rows)
						}
					}
				})

				// Khôi phục lại scroll sau khi DOM render xong qua các mốc thời gian an toàn
				this.$nextTick(() => {
					this.attachRealtimeListeners(container)
					this.restoreState()
					setTimeout(() => {
						this.attachRealtimeListeners(container)
						this.restoreState()
					}, 50)
					setTimeout(() => this.restoreState(), 100)
					setTimeout(() => this.restoreState(), 200)
					setTimeout(() => this.restoreState(), 400)
				})
			}
		}
	}
</script>