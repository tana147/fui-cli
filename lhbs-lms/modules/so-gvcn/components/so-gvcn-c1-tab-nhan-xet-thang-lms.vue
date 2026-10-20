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
		<div v-if="selectedLopID !== '__ALL__' && !loading" class="w-100 h-100 overflow-hidden so-gvcn-sheet so-gvcn-sheet-wrap so-gvcn-c1-desktop-only" style="min-height: 0;">
			<div ref="sheetRef" class="w-100 h-100 overflow-hidden" style="min-height: 0;"></div>
		</div>
		<!-- Phone inputs keep every period field while avoiding the wide spreadsheet grid. -->
		<uc-so-gvcn-mobile-sheet-editor v-if="selectedLopID !== '__ALL__' && !loading" ref="mobileEditorRef"
			class="so-gvcn-c1-mobile-editor flex-column flex-grow-1" :rows="rows" :columns="columns"
			:nested-headers="nestedHeaders" :plain-text-indices="[2, 4, 6, 7, 8]"
			:title-index="1" :subtitle-indices="[0]" :read-only="readOnly" :searchable="true"
			empty-title="Học sinh" empty-text="Chưa có nhận xét cho học sinh này."
			@cell-changed="$emit('changed')" />
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
		return { instance: null, timer: null, isMobileViewport: false, pendingRows: null }
		},
		watch: {
			selectedLopID() { this.scheduleInit() },
			rows: { deep: false, handler() { this.scheduleInit() } },
			columns: { deep: false, handler() { this.scheduleInit() } },
			loading() { this.scheduleInit() },
			sheetKey() { this.scheduleInit() }
		},
		mounted() {
			this.isMobileViewport = window.matchMedia('(max-width: 959.98px)').matches
			window.addEventListener('resize', this.onWindowResize)
			this.scheduleInit()
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.onWindowResize)
			if (this.timer) clearTimeout(this.timer)
			this.destroySheet()
		},
		methods: {
			// The hidden legacy mobile summary renders stored HTML as plain text so markup cannot leak into a card.
			plainText(value) {
				if (value == null) return ''
				const source = typeof value === 'object'
					? (Array.isArray(value) ? value.join(', ') : JSON.stringify(value))
					: String(value)
				return source.replace(/<br\s*\/?\s*>/gi, '\n').replace(/<\/p\s*>/gi, '\n')
					.replace(/<[^>]*>/g, '').replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&')
					.replace(/&lt;/gi, '<').replace(/&gt;/gi, '>').replace(/&quot;/gi, '"')
					.replace(/&#39;/gi, "'").trim()
			},
			onWindowResize() {
				const nextIsMobile = window.matchMedia('(max-width: 959.98px)').matches
				if (nextIsMobile === this.isMobileViewport) return
				this.pendingRows = this.getRows()
				this.isMobileViewport = nextIsMobile
				this.scheduleInit()
			},
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
			getSheetInstance() { return Array.isArray(this.instance) ? this.instance[0] : this.instance },
			getInstance() {
				if (this.isMobileViewport) {
					return { getData: () => this.$refs.mobileEditorRef?.getRows?.() || (this.rows || []), closeEditor: () => {} }
				}
				return this.getSheetInstance()
			},
			getRows() {
				if (this.isMobileViewport) return this.$refs.mobileEditorRef?.getRows?.() || (this.rows || [])
				const sheet = this.getSheetInstance()
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
					const sheet = this.getSheetInstance()
					if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
				} catch (error) {}
				this.instance = null
			},
			initSheet() {
				if (this.selectedLopID === '__ALL__' || this.loading) {
					this.destroySheet()
					return
				}
				if (this.isMobileViewport) {
					this.destroySheet()
					const rows = this.pendingRows || this.rows || []
					this.pendingRows = null
					this.$nextTick(() => this.$refs.mobileEditorRef?.setRows?.(rows))
					return
				}
				// Desktop remains a spreadsheet; mobile uses the same row data and honors the workflow lock.
				const container = this.$refs.sheetRef
				if (!container) return
				this.destroySheet()
				container.innerHTML = ''
				if (typeof jspreadsheet !== 'function') return
				const data = this.rows || []
				this.instance = soGvcnJspreadsheet.create(container, {
					worksheets: [{
						data: this.pendingRows || data,
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
						this.pendingRows = null
						this.$nextTick(() => {
							setTimeout(() => {
							const sheet = this.getSheetInstance()
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