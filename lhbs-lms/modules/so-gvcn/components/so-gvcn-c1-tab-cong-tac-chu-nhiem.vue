<template>
	<!-- Giữ đệm ba cạnh, riêng mép phải không đệm để scrollbar nội dung sát viền tab. -->
	<v-card-text class="pt-2 pb-2 px-2 d-flex flex-column" :style="{ height: sheetHeight, overflow: 'hidden', minHeight: '0' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact">
			Chọn một lớp ở thanh trên để cập nhật công tác chủ nhiệm tháng.
		</v-alert>
		<div v-else class="d-flex flex-column flex-grow-1" style="min-height: 0; min-width: 0;">
			<!-- Các tháng dùng tab ngang để không chiếm 220px chiều rộng của bảng kế hoạch. -->
			<v-tabs :model-value="activeMonth" color="primary" density="compact" show-arrows
				class="so-gvcn-c1-month-tabs flex-shrink-0 mb-2" @update:model-value="selectMonth">
				<v-tab v-for="month in months" :key="month.value" :value="month.value" class="text-none">
					<v-icon start size="small">mdi-calendar-month-outline</v-icon>
					Tháng {{ month.label }}
				</v-tab>
			</v-tabs>

			<!-- Chỉ content dọc; scrollbar ngang được JSpreadsheet tự giữ trong bảng. -->
			<div ref="scrollContainer" class="flex-grow-1 overflow-y-auto" style="min-height: 0; min-width: 0; overflow-x: hidden;" @wheel.capture="onSheetWheel">
				<div class="text-h6 text-center font-weight-bold py-3">
					<template v-if="Number(activeMonth) === 8">
						KẾ HOẠCH THÁNG {{ activeMonthLabel }}/{{ activeYearLabel }}
					</template>
					<template v-else-if="Number(activeMonth) === 5">
						KẾT QUẢ THỰC HIỆN THÁNG {{ prevMonthLabel }}/{{ activeYearLabel }}
					</template>
					<template v-else>
						KẾT QUẢ THỰC HIỆN THÁNG {{ prevMonthLabel }}/{{ activeYearLabel }}
						VÀ KẾ HOẠCH THÁNG {{ activeMonthLabel }}/{{ activeYearLabel }}
					</template>
				</div>

				<v-row dense class="mb-3">
					<v-col v-if="Number(activeMonth) !== 8" cols="12" class="mb-3">
						<v-card variant="outlined">
							<v-card-title class="text-subtitle-2 font-weight-bold text-primary">
								I. ĐÁNH GIÁ CÔNG TÁC THÁNG {{ prevMonthLabel }}
							</v-card-title>
							<v-card-text>
								<v-textarea v-if="currentPlan" v-model="currentPlan.DanhGia" rows="5" auto-grow
									variant="outlined" density="compact" hide-details
									placeholder="Nhập nội dung đánh giá kết quả thực hiện trong tháng..." />
							</v-card-text>
						</v-card>
					</v-col>

					<v-col v-if="Number(activeMonth) !== 5" cols="12" class="mb-3">
						<v-card variant="outlined">
							<v-card-title class="text-subtitle-2 font-weight-bold text-primary">
								{{ Number(activeMonth) === 8 ? 'I' : 'II' }}. KẾ HOẠCH THÁNG {{ activeMonthLabel }}
							</v-card-title>
							<v-card-text>
								<v-textarea v-if="currentPlan" v-model="currentPlan.MucTieu" rows="5" auto-grow
									variant="outlined" density="compact" hide-details
									placeholder="Nhập nội dung và nhiệm vụ trọng tâm của tháng..." />
							</v-card-text>
						</v-card>
					</v-col>

					<v-col cols="12">
						<v-card variant="outlined" class="mb-8">
							<v-card-title class="text-subtitle-2 font-weight-bold text-primary">
								{{ (Number(activeMonth) === 8 || Number(activeMonth) === 5) ? 'II' : 'III' }}. KẾ HOẠCH HÀNG TUẦN CỦA THÁNG {{ activeMonthLabel }}/{{ activeYearLabel }}
							</v-card-title>
							<v-divider />
							<v-card-text class="pa-2">
								<div class="wrapper-jexcel">
									<div ref="sheetRef" class="w-100 so-gvcn-sheet so-gvcn-cong-tac-thang-sheet"
										:style="{ height: weeklySheetHeight }"></div>
								</div>
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>
			</div>
		</div>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-cong-tac-chu-nhiem',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' },
			monthSheetHeight: { type: String, default: 'calc(100vh - 310px)' },
			monthList: { type: Array, default: () => [] },
			weekList: { type: Array, default: () => [] },
			weeklyPlanLoaded: { type: Boolean, default: false },
			nienKhoa: { type: [String, Number], default: null },
			getKeHoachExportMonths: { type: Function, default: () => () => [] }
		},
		data() {
			const months = this.getMonths()
			return {
				months,
				activeMonth: months[0]?.value || 8,
				localPlans: {},
				plansInitialized: false,
				deletedWeekMonths: new Set(),
				instance: null,
				weeklyColumns: [
					{ title: 'THÁNG', width: 80, align: 'center' },
					{ title: 'TUẦN', width: 90, align: 'center' },
					{ title: 'THỜI GIAN', width: 150, align: 'center' },
					{ title: 'KẾ HOẠCH THỰC HIỆN', width: 390, align: 'justify' },
					{ title: 'KẾT QUẢ', width: 330, align: 'justify' },
					{ title: 'NGUYÊN NHÂN ĐẠT ĐƯỢC KẾT QUẢ', width: 390, align: 'justify' }
				]
			}
		},
		computed: {
			activeMonthLabel() {
				return this.months.find(month => Number(month.value) === Number(this.activeMonth))?.label
					|| this.activeMonth
			},
			prevMonthLabel() {
				const index = this.months.findIndex(month => Number(month.value) === Number(this.activeMonth))
				if (index > 0) return this.months[index - 1].label
				return ''
			},
			currentPlan() {
				return this.localPlans[String(this.activeMonth)] || null
			},
			activeYearLabel() {
				const schoolYear = Number(this.nienKhoa) || new Date().getFullYear()
				return Number(this.activeMonth) >= 8 ? schoolYear - 1 : schoolYear
			},
			weeklySheetHeight() {
				return '100%'
			}
		},
		watch: {
			selectedLopID() {
				this.localPlans = {}
				this.plansInitialized = false
				this.deletedWeekMonths = new Set()
				this.buildPlans({ commitCurrent: false })
			},
			monthList: {
				deep: true,
				handler() {
					// monthList và weekList được tải từ 2 request khác nhau. Khi monthList
					// về trước, bảng mới chỉ là dữ liệu lịch mặc định; không được commit
					// bảng tạm vì sẽ khiến weekList thật về sau bị bỏ qua.
					this.buildPlans({ commitCurrent: false })
				}
			},
			weekList: {
				deep: true,
				handler() {
					// Chỉ hydrate lại localPlans từ dữ liệu tuần server, không đọc lại
					// dữ liệu bảng đang hiển thị để tránh đánh dấu nhầm là user đã sửa.
					this.buildPlans({ commitCurrent: false })
				}
			},
			weeklyPlanLoaded() {
				this.buildPlans({ commitCurrent: false })
			},
			nienKhoa() {
				this.localPlans = {}
				this.plansInitialized = false
				this.deletedWeekMonths = new Set()
				this.buildPlans({ commitCurrent: false })
			}
		},
		created() {
			this.buildPlans({ commitCurrent: false })
		},
		mounted() {
			this.initSheet()
		},
		beforeUnmount() {
			this.commitCurrentSheet()
			this.destroySheet()
		},
		methods: {
			onSheetWheel(event) {
				// JSpreadsheet giữ wheel trên các ô dù bảng không có scroll dọc riêng.
				// Bắt ở capture và chuyển nó về scrollbar của nội dung tab.
				if (!event.deltaY || !event.target?.closest?.('.jss_content, .jspreadsheet_content, .jexcel_content')) return
				const container = this.$refs.scrollContainer
				if (!container || container.scrollHeight <= container.clientHeight) return
				const nextTop = Math.max(0, Math.min(
					container.scrollTop + event.deltaY,
					container.scrollHeight - container.clientHeight
				))
				if (nextTop === container.scrollTop) return
				event.preventDefault()
				container.scrollTop = nextTop
			},
			getMonths() {
				const source = this.getKeHoachExportMonths()
				return source.length ? source : [
					{ label: '8', value: 8 },
					{ label: '9', value: 9 },
					{ label: '10', value: 10 },
					{ label: '11', value: 11 },
					{ label: '12', value: 12 },
					{ label: '1,2', value: 1 },
					{ label: '3', value: 3 },
					{ label: '4', value: 4 },
					{ label: '5', value: 5 }
				]
			},
			buildPlans({ commitCurrent = false } = {}) {
				// Không commit khi hydrate props: commit bảng lịch mặc định sẽ đánh dấu
				// tháng là đã sửa cục bộ và làm ẩn các dòng tuần thật từ server.
				if (commitCurrent) this.commitCurrentSheet()
				const savedMap = new Map((this.monthList || []).map(row => [String(row.Thang), row]))
				const plans = {}
				this.months.forEach(month => {
					const saved = savedMap.get(String(month.value)) || {}
					const savedWeeks = (this.weekList || [])
						.filter(row => Number(row.Thang) === Number(month.value))
						.sort((a, b) =>
							Number(a.ThangThucTe) - Number(b.ThangThucTe)
							|| Number(a.TuanTrongThang) - Number(b.TuanTrongThang))
					const existingPlan = this.localPlans[String(month.value)]
					const weeklyRows = this.deletedWeekMonths.has(String(month.value)) && existingPlan
						? existingPlan.weeklyRows
						: (savedWeeks.length
							? this.normalizeWeeklyRows(savedWeeks, month)
							: this.normalizeWeeklyRows([], month))
					plans[String(month.value)] = {
						Thang: month.value,
						DanhGia: saved.DanhGia || '',
						MucTieu: saved.MucTieu || saved.ChuDe || '',
						weeklyRows
					}
				})
				this.localPlans = plans
				this.plansInitialized = true
				const currentMonthVal = Number(this.activeMonth)
				const isMonthValid = this.months.some(m => Number(m.value) === currentMonthVal)
				if (!isMonthValid) {
					this.activeMonth = this.months[0]?.value || 8
				}
				this.initSheet()
			},
			normalizeWeeklyRows(rows, month = null) {
				const targetMonth = month || this.months.find(item =>
					Number(item.value) === Number(this.activeMonth))
				const calendarRows = this.buildCalendarWeekRows(targetMonth)
				const blankRowCount = Math.max(calendarRows.length, 1)
				const blankRows = Array.from({ length: blankRowCount }, () => ['', '', '', '', '', ''])
				if (!Array.isArray(rows) || rows.length === 0) {
					return blankRows
				}
				const normalizedRows = Array.from({
					length: Math.max(blankRowCount, rows.length)
				}, () => ['', '', '', '', '', ''])
				rows.forEach((source, index) => {
					let targetIndex = index
					if (!Array.isArray(source)) {
						const sourceMonth = Number(source?.ThangThucTe)
							|| this.extractActualMonth(source?.ThangText, targetMonth?.value)
						const sourceWeek = Number(source?.TuanTrongThang)
							|| this.extractWeekNumber(source?.TuanText)
						const periodIndex = this.getCalendarWeekPeriods(targetMonth).findIndex(period =>
							Number(period.actualMonth) === Number(sourceMonth)
							&& Number(period.week) === Number(sourceWeek))
						// Keep an empty slot for a missing week so it remains available
						// for user input, without filling that slot with defaults.
						targetIndex = periodIndex >= 0 ? periodIndex : index
					}
					if (!Array.isArray(source)) {
						normalizedRows[targetIndex] = [
							source.ThangText || (source.ThangThucTe ? 'Tháng ' + source.ThangThucTe : ''),
							source.TuanText || (source.TuanTrongThang ? 'Tuần ' + source.TuanTrongThang : ''),
							source.ThoiGianText || this.formatStoredWeekDateRange(source, ''),
							source.KeHoachThucHien || '',
							source.KetQua || '',
							source.NguyenNhan || ''
						]
						return
					}
					// Default weekly rows contain only the 3 calendar columns.
					// Do not shift those columns into the editable content columns
					// when jspreadsheet returns the row after Ctrl+X.
					const contentStart = source.length >= 6 ? 3 : (source.length >= 5 ? 2 : 3)
					normalizedRows[targetIndex] = [
						source[0] ?? '',
						source[1] ?? '',
						source[2] ?? '',
						source[contentStart] || '',
						source[contentStart + 1] || '',
						source[contentStart + 2] || ''
					]
				})
				return normalizedRows
			},
			isBlankWeeklyRow(source) {
				if (Array.isArray(source)) return source.every(value => String(value ?? '').trim() === '')
				if (!source || typeof source !== 'object') return true
				return [
					source.ThangText,
					source.TuanText,
					source.ThoiGianText,
					source.KeHoachThucHien,
					source.KetQua,
					source.NguyenNhan
				].every(value => String(value ?? '').trim() === '')
			},
			buildCalendarWeekRows(month) {
				return this.getCalendarWeekPeriods(month).map(period => [
					'Tháng ' + period.actualMonth,
					'Tuần ' + period.week,
					this.formatWeekDate(period.fromDate) + ' – ' + this.formatWeekDate(period.toDate)
				])
			},
			formatWeekDate(value) {
				const day = String(value.getDate()).padStart(2, '0')
				const month = String(value.getMonth() + 1).padStart(2, '0')
				return day + '/' + month
			},
			formatSqlDate(value) {
				const year = value.getFullYear()
				const month = String(value.getMonth() + 1).padStart(2, '0')
				const day = String(value.getDate()).padStart(2, '0')
				return year + '-' + month + '-' + day
			},
			getCalendarWeekPeriods(month) {
				if (!month) return []
				const schoolYear = Number(this.nienKhoa) || new Date().getFullYear()
				const monthNumber = Number(month.value)
				const actualMonths = monthNumber === 1 && String(month.label).includes('2')
					? [1, 2]
					: [monthNumber]
				const periods = []
				actualMonths.forEach(actualMonth => {
					const calendarYear = actualMonth >= 8 ? schoolYear - 1 : schoolYear
					const rangeStart = new Date(calendarYear, actualMonth - 1, 1)
					const rangeEnd = new Date(calendarYear, actualMonth, 0)
					const cursor = new Date(rangeStart)
					const day = cursor.getDay()
					cursor.setDate(cursor.getDate() - (day === 0 ? 6 : day - 1))
					const monthPeriods = []
					let week = 1
					while (cursor <= rangeEnd && week <= 5) {
						const fromDate = new Date(cursor)
						const toDate = new Date(cursor)
						toDate.setDate(toDate.getDate() + 6)
						monthPeriods.push({ actualMonth, week, fromDate, toDate })
						cursor.setDate(cursor.getDate() + 7)
						week += 1
					}
					while (monthPeriods.length < 5) {
						const last = monthPeriods[monthPeriods.length - 1]
						const fromDate = new Date(last.toDate)
						fromDate.setDate(fromDate.getDate() + 1)
						const toDate = new Date(fromDate)
						toDate.setDate(toDate.getDate() + 6)
						monthPeriods.push({ actualMonth, week: monthPeriods.length + 1, fromDate, toDate })
					}
					periods.push(...monthPeriods)
				})
				return periods
			},
			selectMonth(month) {
				if (Number(month) === Number(this.activeMonth)) return
				this.commitCurrentSheet()
				this.activeMonth = month
				this.initSheet()
			},
			commitCurrentSheet() {
				const plan = this.currentPlan
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				if (plan && sheet && typeof sheet.getData === 'function') {
					try {
						// closeEditor expects the active cell and the save flag. Passing
						// only `true` can close the editor without committing its value.
						const editorCell = sheet.edition ? sheet.edition[0] : null
						if (editorCell && typeof sheet.closeEditor === 'function') {
							sheet.closeEditor(editorCell, true)
						}
						const data = sheet.getData()
						if (Array.isArray(data)) {
							this.deletedWeekMonths.add(String(this.activeMonth))
						}
						plan.weeklyRows = this.normalizeWeeklyRows(data)
					} catch (error) {}
				}
			},
			destroySheet() {
				if (!this.instance) return
				try {
					const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
					if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
				} catch (error) {}
				this.instance = null
			},
			getResponsiveWeeklyColumns() {
				// Giữ nguyên độ rộng khai báo của các cột; khi tổng độ rộng vượt viewport,
				// phần dư phải tạo scrollbar ngang bên trong JSpreadsheet thay vì co chữ
				// lại hoặc làm tràn vùng scroll của tab.
				return this.weeklyColumns.map(column => ({ ...column }))
			},
			initSheet() {
				if (this.selectedLopID === '__ALL__') {
					this.destroySheet()
					return
				}
				this.$nextTick(() => {
					const container = this.$refs.sheetRef
					if (!container || !this.currentPlan || typeof jspreadsheet !== 'function') return
					this.destroySheet()
					container.innerHTML = ''
					const columns = this.getResponsiveWeeklyColumns()
					this.instance = soGvcnJspreadsheet.create(container, {
						worksheets: [{
							data: this.currentPlan.weeklyRows,
							columns,
							rowResize: true,
							columnDrag: false,
							tableWidth: '100%',
							// Bảng kế hoạch tháng cần hiển thị hết số dòng. Nếu dùng
							// tableOverflow/tableHeight, JSpreadsheet tạo một scrollbar
							// dọc riêng và lúc mở editor có thể tự đổi vị trí cuộn.
							tableOverflow: false,
							lazyLoading: false,
							wordWrap: true,
							allowInsertColumn: false,
							allowInsertRow: false,
							showHeader: true
						}],
						contextMenu: () => false,
								onchange: worksheet => {
								if (this.currentPlan) {
									const data = worksheet.getData()
					if (Array.isArray(data)) {
						this.deletedWeekMonths.add(String(this.activeMonth))
									}
									this.currentPlan.weeklyRows = this.normalizeWeeklyRows(data)
									this.$emit('changed')
								}
						}
					})
				})
			},
			getInstance() {
				return this.instance
			},
			resetAfterSave() {
				// Keep the cleared-month marker through the next getDetail(). When
				// the server returns no weekly rows, normalizeWeeklyRows must keep
				// that month blank instead of rebuilding calendar placeholder rows.
			},
			getSaveRows(soGVCNID) {
				this.commitCurrentSheet()
				return this.months.map(month => {
					const plan = this.localPlans[String(month.value)] || {}
					const saved = (this.monthList || []).find(row =>
						Number(row.Thang) === Number(month.value)) || {}
					return {
						SoGVCNID: soGVCNID,
						Thang: month.value,
						ChuDe: '',
						MucTieu: plan.MucTieu || '',
						NhiemVu: '',
						// Weekly content is stored in tblSoGVCNKeHoachTuan. Keep
						// any legacy value instead of overwriting it with ''.
						KeHoachTuan: saved.KeHoachTuan || '',
						DanhGia: plan.DanhGia || ''
					}
				})
			},
			getSaveWeekRows(soGVCNID) {
				this.commitCurrentSheet()
				const rows = []
				this.months.forEach(month => {
					const plan = this.localPlans[String(month.value)] || {}
					const weeklyRows = this.normalizeWeeklyRows(plan.weeklyRows || [], month)
					const periods = this.getCalendarWeekPeriods(month)
					weeklyRows.forEach((week, index) => {
						const values = week.map(value => String(value ?? '').trim())
						const actualMonth = this.extractActualMonth(week[0], null)
						const weekNumber = this.extractWeekNumber(week[1])
						const hasContent = values.slice(3).some(value => value !== '')
						const hasEditableKey = values[0] !== '' || values[1] !== ''
						// A week with no teaching can legitimately keep only the default
						// date range while THÁNG/TUẦN and all content stay empty.
						if (!hasContent && !hasEditableKey) return
						if (!Number.isInteger(actualMonth) || actualMonth < 1 || actualMonth > 12
							|| !Number.isInteger(weekNumber) || weekNumber < 1 || weekNumber > 6) {
							throw new Error('Dòng ' + (index + 1) + ' của tháng ' + month.value
								+ ' phải có THÁNG hợp lệ (1-12) và TUẦN hợp lệ (1-6).')
						}
						if (!values[0] || !values[1]) {
							throw new Error('Dòng ' + (index + 1) + ' của tháng ' + month.value
								+ ' đang có dữ liệu nhưng thiếu THÁNG hoặc TUẦN.')
						}
						const period = periods.find(item =>
							Number(item.actualMonth) === Number(actualMonth)
							&& Number(item.week) === Number(weekNumber)) || periods[index]
						if (!period) return
						const dateRange = this.parseEditedWeekDateRange(week[2], period)
						rows.push({
							SoGVCNID: soGVCNID,
							Thang: month.value,
							ThangThucTe: actualMonth,
							TuanTrongThang: weekNumber,
							TuNgay: dateRange.fromDate,
							DenNgay: dateRange.toDate,
							KeHoachThucHien: week[3] || '',
							KetQua: week[4] || '',
							NguyenNhan: week[5] || ''
						})
					})
				})
				const seenKeys = new Map()
				const duplicateGroups = new Map()
				rows.forEach((row, index) => {
					const key = [row.Thang, row.ThangThucTe, row.TuanTrongThang].join(':')
					if (seenKeys.has(key)) {
						const group = duplicateGroups.get(key) || {
							row,
							rowIndexes: [seenKeys.get(key) + 1]
						}
						group.rowIndexes.push(index + 1)
						duplicateGroups.set(key, group)
					} else {
						seenKeys.set(key, index)
					}
				})
				if (duplicateGroups.size) {
					const details = Array.from(duplicateGroups.values()).map(group =>
						'Dòng ' + group.rowIndexes.join(', ') + ' cùng là Tháng '
						+ group.row.ThangThucTe + ', Tuần ' + group.row.TuanTrongThang)
					throw new Error(details.join('; ')
						+ '. Vui lòng đổi TUẦN hoặc sửa dòng đã có trước khi lưu.')
				}
				return rows
			},
			formatStoredWeekDateRange(source, fallback) {
				if (!source?.TuNgay || !source?.DenNgay) return fallback
				return this.formatStoredDate(source.TuNgay) + ' – ' + this.formatStoredDate(source.DenNgay)
			},
			formatStoredDate(value) {
				const match = String(value || '').match(/(\d{4})-(\d{2})-(\d{2})/)
				if (match) return match[3] + '/' + match[2]
				const date = new Date(value)
				return Number.isNaN(date.getTime()) ? String(value || '') : this.formatWeekDate(date)
			},
			parseEditedWeekDateRange(value, fallbackPeriod) {
				const fallback = {
					fromDate: this.formatSqlDate(fallbackPeriod.fromDate),
					toDate: this.formatSqlDate(fallbackPeriod.toDate)
				}
				const matches = String(value || '')
					.replace(/\s*(?:đến|to)\s*/i, ' - ')
					.match(/(\d{1,2})\/(\d{1,2})\s*[–-]\s*(\d{1,2})\/(\d{1,2})/)
				if (!matches) return fallback
				const year = fallbackPeriod.fromDate.getFullYear()
				const from = new Date(year, Number(matches[2]) - 1, Number(matches[1]))
				const toYear = Number(matches[4]) < Number(matches[2]) ? year + 1 : year
				const to = new Date(toYear, Number(matches[4]) - 1, Number(matches[3]))
				return {
					fromDate: this.formatSqlDate(from),
					toDate: this.formatSqlDate(to)
				}
			},
				extractActualMonth(value, fallback) {
				const match = String(value || '').match(/(\d+)/)
				return match ? Number(match[1]) : Number(fallback)
			},
			extractWeekNumber(value) {
				const match = String(value || '').match(/(\d+)/)
				return match ? Number(match[1]) : null
			}
		}
	}
</script>