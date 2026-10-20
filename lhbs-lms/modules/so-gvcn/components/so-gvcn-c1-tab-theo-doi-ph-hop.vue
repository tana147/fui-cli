<template>
	<div class="h-100 overflow-hidden d-flex flex-column" :style="{ height: sheetHeight, minHeight: '0' }">
		<!-- Host chiếm 100% chiều cao tab trong viewport; JSpreadsheet giữ trọn vẹn cả hai thanh cuộn ngang/dọc bên trong. -->
		<v-card-text class="pa-0 h-100 overflow-hidden d-flex flex-column flex-grow-1" style="min-height: 0;">
			<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
				Chọn một lớp ở thanh trên để theo dõi tình hình Phụ huynh tham dự họp.
			</v-alert>
			<div v-else class="w-100 flex-grow-1 overflow-hidden so-gvcn-theo-doi-ph-hop-sheet so-gvcn-c1-desktop-only" style="min-height: 0;">
				<div ref="sheetRef" class="w-100 h-100 overflow-hidden" style="min-height: 0;"></div>
			</div>
			<!-- Mobile edits use the same row/column shape as JSpreadsheet so existing save and export paths remain shared. -->
			<uc-so-gvcn-mobile-sheet-editor v-if="selectedLopID !== '__ALL__'" ref="mobileEditorRef"
				class="so-gvcn-c1-mobile-editor flex-column flex-grow-1" :rows="mobileEditorRows" :columns="columns"
				:title-index="3" :subtitle-indices="[1, 2]" :searchable="true" empty-title="Học sinh"
				empty-text="Chưa có học sinh trong lớp này." />
		</v-card-text>
	</div>
</template>

<script>
	export default {
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			students: { type: Array, default: () => [] },
			savedRows: { type: Array, default: () => [] },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' }
		},
		data() {
			return {
				instance: null,
				isMobileViewport: false,
				resizeTimer: null,
				resizeObserver: null,
				layoutRetry: 0,
				columns: [
					{ title: 'STT', width: 60, readOnly: true, align: 'center' },
					{ title: 'Mã học sinh', width: 110, readOnly: true, align: 'center' },
					{ title: 'Số danh bộ', width: 110, readOnly: true, align: 'center' },
					{ title: 'Họ và tên học sinh', width: 250, readOnly: true },
					{ title: 'I', width: 100, type: 'checkbox' },
					{ title: 'II', width: 100, type: 'checkbox' },
					{ title: 'III', width: 100, type: 'checkbox' },
					{ title: 'Ghi chú', width: 350 }
				]
			}
		},
		watch: {
			selectedLopID() {
				this.initSheet()
			},
			students: {
				deep: false,
				handler() {
					this.initSheet()
				}
			},
			savedRows: {
				deep: false,
				handler() {
					this.initSheet()
				}
			},
			sheetHeight() {
				this.initSheet()
			}
		},
		mounted() {
			this.isMobileViewport = window.matchMedia('(max-width: 959.98px)').matches
			window.addEventListener('resize', this.onWindowResize)
			this.startResizeObserver()
			this.initSheet()
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.onWindowResize)
			clearTimeout(this.resizeTimer)
			if (this.resizeObserver) this.resizeObserver.disconnect()
			this.destroySheet()
		},
		computed: {
			mobileEditorRows() {
				return this.buildRows()
			},
			nestedHeaders() {
				return [
					[
						{ title: '', colspan: 4 },
						{ title: 'Kiểm diện PH đi họp', colspan: 3 },
						{ title: '', colspan: 1 }
					]
				]
			}
		},
		methods: {
			// Bảng điểm danh theo số học sinh; giới hạn chiều cao theo viewport còn lại
			// để scrollbar chỉ xuất hiện trong JSpreadsheet khi thực sự cần.
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
			getRows() {
				if (this.isMobileViewport) {
					return this.$refs.mobileEditorRef?.getRows?.() || this.buildRows()
				}
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				// Đóng editor trước khi lấy data để đảm bảo các ô nhập gần nhất được ghi nhận
				if (sheet && typeof sheet.closeEditor === 'function') {
					try { sheet.closeEditor(true) } catch (error) {}
				}
				return sheet && typeof sheet.getData === 'function' ? sheet.getData() : []
			},
			getTableHeight(container) {
				// Chỉ cấp chiều cao còn lại cho JSpreadsheet; wrapper bên ngoài vẫn giữ 100%.
				if (typeof soGvcnJspreadsheet === 'object' && typeof soGvcnJspreadsheet.getTableHeight === 'function') {
					return soGvcnJspreadsheet.getTableHeight(container, '100%')
				}
				return '100%'
			},
			onWindowResize() {
				clearTimeout(this.resizeTimer)
				this.resizeTimer = setTimeout(() => {
					const nextIsMobile = window.matchMedia('(max-width: 959.98px)').matches
					if (nextIsMobile === this.isMobileViewport) return
					const rows = this.getRowsForCurrentViewport()
					this.isMobileViewport = nextIsMobile
					this.$nextTick(() => {
						if (nextIsMobile) this.$refs.mobileEditorRef?.setRows?.(rows)
						this.initSheet(nextIsMobile ? undefined : rows)
					})
				}, 120)
			},
			getRowsForCurrentViewport() {
				if (this.isMobileViewport) return this.$refs.mobileEditorRef?.getRows?.() || this.buildRows()
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				if (sheet && typeof sheet.closeEditor === 'function') {
					try { sheet.closeEditor(true) } catch (error) {}
				}
				return sheet && typeof sheet.getData === 'function' ? sheet.getData() : this.buildRows()
			},
			startResizeObserver() {
				const container = this.$refs.sheetRef
				const host = container?.closest?.('.v-window-item')
				if (!host || typeof ResizeObserver === 'undefined') return
				this.resizeObserver = new ResizeObserver(() => this.onWindowResize())
				this.resizeObserver.observe(host)
			},
			waitForHostLayout() {
				if (this.layoutRetry >= 8) return
				this.layoutRetry++
				window.requestAnimationFrame(() => this.initSheet())
			},
			buildRows() {
				const findSaved = (hslopID) => (this.savedRows || [])
					.find(r => String(r.HSLopID) === String(hslopID)) || {}
				return (this.students || []).map((student, idx) => {
					const saved = findSaved(student.HSLopID)
					return [
						idx + 1,
						student.MaHocSinh || student.HocSinhID || '',
						student.SoDanhBo || '',
						student.HoTen || student.HoTenHocSinh || '',
						!!(saved.Lan1 || saved.DauNamCoMat),
						!!(saved.Lan2 || saved.HK1CoMat),
						!!(saved.Lan3 || saved.CuoiNamCoMat),
						saved.GhiChu || ''
					]
				})
			},
			destroySheet() {
				if (!this.instance) return
				try {
					const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
					if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
					else if (this.$refs.sheetRef && typeof jspreadsheet !== 'undefined'
						&& typeof jspreadsheet.destroy === 'function') {
						jspreadsheet.destroy(this.$refs.sheetRef)
					}
				} catch (error) {}
				this.instance = null
			},
			initSheet(initialRows) {
				if (this.selectedLopID === '__ALL__' || this.isMobileViewport) {
					this.destroySheet()
					return
				}
				this.$nextTick(() => {
					const container = this.$refs.sheetRef
					if (!container) return
					this.destroySheet()
					container.innerHTML = ''
					if (typeof jspreadsheet !== 'function') return
					const data = Array.isArray(initialRows) ? initialRows : this.buildRows()
					this.instance = soGvcnJspreadsheet.create(container, {
						worksheets: [{
							data,
							columns: this.columns,
							nestedHeaders: this.nestedHeaders,
							rowResize: true,
							columnDrag: false,
							tableWidth: '100%',
							tableOverflow: true,
							tableHeight: this.getContentTableHeight(container, data.length, this.nestedHeaders.length),
							lazyLoading: false,
							freezeColumns: 4,
							wordWrap: true,
							allowInsertColumn: false,
							allowInsertRow: false,
							showHeader: true
						}],
						contextMenu: () => false
					})
				})
			}

		}
	}
</script>