<template>
	<!-- Bảng cần sát hai mép phải/dưới; chỉ giữ đệm phía trên cho panel hướng dẫn. -->
	<v-card-text class="pt-2 px-0 pb-0 so-gvcn-plan-tab so-gvcn-month-plan-tab d-flex flex-column" :style="{ height: sheetHeight, overflow: 'hidden', minHeight: '0' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="mb-0">
			Chọn một lớp ở thanh trên để xem và nhập kế hoạch giáo dục của lớp đó.
		</v-alert>
		<template v-else>
			<!-- Thanh chọn Tháng hỗ trợ Trung học hiển thị riêng từng tháng tập trung, dễ quan sát -->
			<v-tabs v-model="activeMonthIndex" color="primary" density="compact" show-arrows class="flex-shrink-0 mb-2 px-2">
				<v-tab v-for="(month, idx) in months" :key="month.value" :value="idx" class="text-none">
					<v-icon start size="small">mdi-calendar-month-outline</v-icon>
					Tháng {{ month.label }}
				</v-tab>
			</v-tabs>

			<v-expansion-panels class="mb-2 px-2 flex-shrink-0">
				<v-expansion-panel>
					<v-expansion-panel-title class="text-subtitle-1 font-weight-bold py-2 px-3 text-primary"
						style="min-height: 48px;">
						<v-icon start color="primary" class="mr-2">mdi-information-outline</v-icon>
						KHUNG KẾ HOẠCH GIÁO DỤC HỌC SINH THÁNG {{ currentMonthLabel }} LỚP {{ selectedClass?.TenLop || '.....' }} - NĂM HỌC
						{{ schoolYearText }}
					</v-expansion-panel-title>
					<v-expansion-panel-text class="text-caption text-medium-emphasis">
						<div class="font-weight-bold mb-1">Gợi ý thực hiện:</div>
						<ul class="pl-4">
							<li>Căn cứ Khung chủ đề giáo dục của nhà trường để cập nhật tên Chủ đề hàng tháng và Mục
								tiêu giáo dục chính thông qua chủ đề của tháng đó.</li>
							<li>Căn cứ chủ đề - mục tiêu giáo dục đã xác định để lên kế hoạch cho các nội dung giáo dục
								sẽ triển khai cho từng tuần trong tháng.</li>
							<li class="font-weight-bold mt-1 text-primary">Các gợi ý nhiệm vụ thực hiện theo tuần:</li>
							<ul class="pl-4 text-grey-darken-2">
								<li>15 phút đầu giờ</li>
								<li>Sinh hoạt lớp cuối tuần</li>
								<li>Phim ngắn / Video tư liệu liên quan đến chủ đề giáo dục tháng, ngày lễ kỉ niệm, hoặc
									hành vi (nếu cần)</li>
								<li>Dặn dò khác</li>
							</ul>
							<li class="mt-1">Cuối tháng, GVCN cập nhật đánh giá ngắn gọn tình hình cả lớp trong tháng
								đó.</li>
						</ul>
					</v-expansion-panel-text>
				</v-expansion-panel>
			</v-expansion-panels>

			<div class="so-gvcn-sheet-wrap flex-grow-1 overflow-hidden" style="min-height: 0; height: 100%;">
				<div class="wrapper-jexcel h-100" style="min-height: 0; height: 100%;">
					<div ref="sheetRef" class="w-100 h-100" style="height: 100%; min-height: 0;"></div>
				</div>
			</div>
		</template>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-tab-ke-hoach',
		props: {
			selectedLopID: { type: String, default: '__ALL__' },
			selectedClass: { type: Object, default: null },
			schoolYearText: { type: String, default: '' },
			sheetHeight: { type: String, default: 'calc(100vh - 114px)' },
			keHoachSheetHeight: { type: String, default: 'calc(100vh - 114px)' },
			columns: { type: Array, default: () => [] },
			dataAoA: { type: Array, default: () => [] },
			sheetStyle: { type: Object, default: () => ({}) },
			nestedHeaders: { type: Array, default: () => [] },
			getKeHoachExportMonths: { type: Function, required: true },
			getKeHoachMonthRowCount: { type: Function, required: true }
		},
		data() {
			return {
				activeMonthIndex: 0,
				localDataAoA: []
			}
		},
		computed: {
			months() {
				return typeof this.getKeHoachExportMonths === 'function'
					? this.getKeHoachExportMonths()
					: []
			},
			currentMonthLabel() {
				const m = this.months[this.activeMonthIndex]
				return m ? m.label : ''
			}
		},
		created() {
			this.instance = null
			this.layoutObserver = null
			if (Array.isArray(this.dataAoA) && this.dataAoA.length > 0) {
				this.localDataAoA = JSON.parse(JSON.stringify(this.dataAoA))
			}
		},
		watch: {
			selectedLopID() {
				this.localDataAoA = []
				this.$nextTick(() => {
					this.initSheet()
					this.observeLayout()
				})
			},
			dataAoA: {
				deep: true,
				immediate: true,
				handler(newVal) {
					if (Array.isArray(newVal) && newVal.length > 0) {
						this.localDataAoA = JSON.parse(JSON.stringify(newVal))
					}
					this.initSheet()
				}
			},
			activeMonthIndex(newIdx, oldIdx) {
				this.commitCurrentSheet(oldIdx)
				this.$nextTick(() => {
					this.initSheet()
				})
			}
		},
		mounted() {
			this.initSheet()
			this.observeLayout()
		},
		beforeUnmount() {
			this.commitCurrentSheet()
			if (this.layoutObserver) {
				this.layoutObserver.disconnect()
				this.layoutObserver = null
			}
		},
		methods: {
			commitCurrentSheet(monthIdx = this.activeMonthIndex) {
				if (!this.instance) return
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				if (sheet && typeof sheet.getData === 'function') {
					try {
						const editorCell = sheet.edition ? sheet.edition[0] : null
						if (editorCell && typeof sheet.closeEditor === 'function') {
							sheet.closeEditor(editorCell, true)
						}
						const currentRows = sheet.getData()
						const rowCount = typeof this.getKeHoachMonthRowCount === 'function' ? this.getKeHoachMonthRowCount() : 7
						const start = monthIdx * rowCount
						if (Array.isArray(currentRows) && currentRows.length > 0) {
							for (let i = 0; i < currentRows.length; i++) {
								if (start + i < this.localDataAoA.length) {
									this.localDataAoA[start + i] = currentRows[i]
								}
							}
						}
					} catch (e) {}
				}
			},
			getActiveMonthRows() {
				const rowCount = typeof this.getKeHoachMonthRowCount === 'function' ? this.getKeHoachMonthRowCount() : 7
				const start = this.activeMonthIndex * rowCount
				if (!this.localDataAoA || !this.localDataAoA.length) return []
				const monthRows = this.localDataAoA.slice(start, start + rowCount)
				return JSON.parse(JSON.stringify(monthRows))
			},
			getRows() {
				this.commitCurrentSheet()
				return this.localDataAoA
			},
			getFullData() {
				this.commitCurrentSheet()
				return this.localDataAoA
			},
			getInstance() {
				const self = this
				return {
					getData() {
						self.commitCurrentSheet()
						return self.localDataAoA
					},
					closeEditor(cell, save) {
						const sheet = Array.isArray(self.instance) ? self.instance[0] : self.instance
						if (sheet && typeof sheet.closeEditor === 'function') {
							try { sheet.closeEditor(cell, save) } catch (e) {}
						}
						self.commitCurrentSheet()
					}
				}
			},
			observeLayout() {
				if (typeof ResizeObserver !== 'function') return

				this.$nextTick(() => {
					if (this.layoutObserver) {
						this.layoutObserver.disconnect()
						this.layoutObserver = null
					}

					const target = this.$refs.sheetRef
					if (!target || target.nodeType !== 1) return

					this.layoutObserver = new ResizeObserver(() => {
						if (target.offsetParent !== null) this.syncTableHeight()
					})
					this.layoutObserver.observe(target)
				})
			},
			getTableHeight() {
				return '100%'
			},
			syncTableHeight() {
				const container = this.$refs.sheetRef
				if (!container) return

				const tableHeight = '100%'
				container.querySelectorAll(
					'.jss_container, .jspreadsheet_container, .jexcel_container, .jss_content, .jspreadsheet_content, .jexcel_content'
				).forEach(content => {
					content.style.setProperty('height', tableHeight, 'important')
					content.style.setProperty('max-height', tableHeight, 'important')
				})
			},
			initSheet() {
				if (this.selectedLopID === '__ALL__') return
				this.$nextTick(() => {
					const container = this.$refs.sheetRef
					if (!container) return
					const tableHeight = '100%'

					if (this.instance) {
						try {
							const s = Array.isArray(this.instance) ? this.instance[0] : this.instance
							if (s && typeof s.destroy === 'function') s.destroy()
						} catch (e) {}
						this.instance = null
					}
					container.innerHTML = ''

					const data = this.getActiveMonthRows()

					if (typeof soGvcnJspreadsheet === 'object' && typeof soGvcnJspreadsheet.create === 'function') {
						this.instance = soGvcnJspreadsheet.create(container, {
							worksheets: [{
								data,
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
								tableHeight,
								lazyLoading: false,
								wordWrap: true,
								allowInsertColumn: false,
								allowInsertRow: false,
								style: this.sheetStyle,
								showHeader: true
							}],
							contextMenu: () => false,
							onchange: (worksheet, cell, x, y, value, oldValue) => {
								if (x === undefined || y === undefined) return
								if (String(value ?? '').trim() === String(oldValue ?? '').trim()) return
								this.commitCurrentSheet()
								this.$emit('changed')
							},
							onload: () => {
								this.$nextTick(() => {
									this.syncTableHeight()
									setTimeout(() => {
										this.applyLayout()
									}, 100)
								})
							}
						})
					}
				})
			},
			applyLayout() {
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				if (!sheet) return
				const rowCount = typeof this.getKeHoachMonthRowCount === 'function' ? this.getKeHoachMonthRowCount() : 7
				this.applyMerge(sheet, 'A1', 1, rowCount)
				this.applyMerge(sheet, 'I1', 1, rowCount)
			},
			applyMerge(sheet, cell, colspan, rowspan) {
				const originalAlert = window.alert
				try {
					window.alert = function (msg) {
						if (msg && String(msg).toLowerCase().indexOf('merged') !== -1) return
						if (typeof originalAlert === 'function') originalAlert(msg)
					}
					if (sheet.setMerge) sheet.setMerge(cell, colspan, rowspan)
					else if (sheet.setMergeCells) sheet.setMergeCells(cell, colspan, rowspan)
				} catch (e) {
				} finally {
					window.alert = originalAlert
				}
			}
		}
	}
</script>