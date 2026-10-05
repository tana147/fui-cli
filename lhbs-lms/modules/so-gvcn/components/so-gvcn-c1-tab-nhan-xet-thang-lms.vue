<template>
	<!-- Host chiếm 100% chiều cao tab trong viewport; JSpreadsheet giữ trọn vẹn cả hai thanh cuộn ngang/dọc bên trong. -->
	<div class="w-100 h-100 overflow-hidden d-flex flex-column" style="min-height: 0;">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2"
			style="flex: 0 0 auto; min-height: auto;">
			Chọn một lớp ở thanh trên để nhập nhận xét tháng LMS.
		</v-alert>
		<div v-else-if="loading" class="d-flex align-center justify-center ga-3 pa-4 text-primary"
			style="flex: 0 0 auto; min-height: auto;">
			<v-progress-circular indeterminate size="24" width="2" />
			<span class="text-body-2">Đang tải nhận xét tháng...</span>
		</div>
		<v-alert v-else-if="reasonReject" type="error" variant="tonal" density="compact" class="ma-2"
			style="flex: 0 0 auto; min-height: auto;">
			Lý do từ chối: {{ reasonReject }}
		</v-alert>
		<div v-if="selectedLopID !== '__ALL__' && !loading" class="w-100 h-100 overflow-hidden so-gvcn-sheet so-gvcn-sheet-wrap" style="min-height: 0;">
			<div ref="sheetRef" class="w-100 h-100 overflow-hidden" style="min-height: 0;"></div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-nhan-xet-thang-lms',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			rows: { type: Array, default: () => [] },
			columns: { type: Array, default: () => [] },
			nestedHeaders: { type: Array, default: () => [] },
			sheetHeight: { type: String  },
			sheetKey: { type: [Number, String], default: 0 },
			readOnly: { type: Boolean, default: false },
			reasonReject: { type: String, default: '' },
			loading: { type: Boolean, default: false }
		},
		data() {
			return { instance: null, timer: null }
		},
		watch: {
			selectedLopID() { this.scheduleInit() },
			rows: { deep: false, handler() { this.scheduleInit() } },
			columns: { deep: false, handler() { this.scheduleInit() } },
			loading() { this.scheduleInit() },
			sheetKey() { this.scheduleInit() }
		},
		mounted() { this.scheduleInit() },
		beforeUnmount() {
			if (this.timer) clearTimeout(this.timer)
			this.destroySheet()
		},
		methods: {
			// Nhận xét tháng thường có ít dòng hơn chiều cao viewport; chỉ phần vượt quá
			// số dòng thực tế mới tạo scrollbar dọc trong JSpreadsheet.
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
			getInstance() { return Array.isArray(this.instance) ? this.instance[0] : this.instance },
			getRows() {
				const sheet = this.getInstance()
				return sheet && typeof sheet.getData === 'function' ? sheet.getData() : []
			},
			scheduleInit() {
				if (this.timer) clearTimeout(this.timer)
				this.$nextTick(() => {
					this.timer = window.setTimeout(() => {
						this.timer = null
						this.initSheet()
					}, 50)
				})
			},
			destroySheet() {
				if (!this.instance) return
				try {
					const sheet = this.getInstance()
					if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
				} catch (error) {}
				this.instance = null
			},
			initSheet() {
				if (this.selectedLopID === '__ALL__' || this.loading) {
					this.destroySheet()
					return
				}
				const container = this.$refs.sheetRef
				if (!container) return
				this.destroySheet()
				container.innerHTML = ''
				if (typeof jspreadsheet !== 'function') return
				const data = this.rows || []
				this.instance = soGvcnJspreadsheet.create(container, {
					worksheets: [{
						data: data,
						columns: (this.columns || []).map(column => {
							const normalizedColumn = this.readOnly ? { ...column, readOnly: true } : column
							return !normalizedColumn.readOnly && normalizedColumn.type !== 'numeric' && normalizedColumn.align !== 'center'
								? { ...normalizedColumn, align: 'justify' }
								: normalizedColumn
						}),
						nestedHeaders: this.nestedHeaders || [],
						rowResize: true,
						columnDrag: false,
						rowDrag: false,
						columnSorting: false,
						tableWidth: '100%',
						tableOverflow: true,
						tableHeight: this.getContentTableHeight(container, data.length, (this.nestedHeaders || []).length),
						lazyLoading: false,
						freezeColumns: 2,
						wordWrap: true,
						allowInsertColumn: false,
						allowInsertRow: false,
						showHeader: true
					}],
					contextMenu: () => false,
					onload: () => {
						this.$nextTick(() => {
							setTimeout(() => {
								const sheet = this.getInstance()
								if (!sheet || typeof sheet.setHeight !== 'function') return
								;(this.rows || []).forEach((_, rowIndex) => sheet.setHeight(rowIndex, 96))
							}, 100)
						})
					}
				})
			}
		}
	}
</script>