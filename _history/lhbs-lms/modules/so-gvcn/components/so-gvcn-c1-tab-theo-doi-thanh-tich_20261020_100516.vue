<template>
	<div class="h-100 overflow-hidden d-flex flex-column" :style="{ height: sheetHeight, minHeight: '0' }">
		<!-- Host chiếm 100% chiều cao tab trong viewport; JSpreadsheet giữ trọn vẹn cả hai thanh cuộn ngang/dọc bên trong. -->
		<v-card-text class="pa-0 h-100 overflow-hidden d-flex flex-column flex-grow-1" style="min-height: 0;">
			<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
				Chọn một lớp ở thanh trên để theo dõi thành tích & khen thưởng học sinh.
			</v-alert>
			<div v-else class="w-100 flex-grow-1 overflow-hidden so-gvcn-theo-doi-thanh-tich-sheet" style="min-height: 0;">
				<div ref="sheetRef" class="w-100 h-100 overflow-hidden" style="min-height: 0;"></div>
			</div>
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
				resizeTimer: null,
				resizeObserver: null,
				layoutRetry: 0,
				columns: [
					{ title: 'STT', width: 50, readOnly: true, align: 'center' },
					{ title: 'Mã học sinh', width: 110, readOnly: true },
					{ title: 'Số danh bộ', width: 110, readOnly: true },
					{ title: 'Họ và tên học sinh', width: 220, readOnly: true },
					{ title: 'HKI', width: 350 },
					{ title: 'Cuối năm học', width: 350 }
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
			nestedHeaders() {
				return [
					[
						{ title: '', colspan: 4 },
						{ title: 'Nội dung khen thưởng/ Thành tích đạt được', colspan: 2 }
					]
				]
			}
		},
		methods: {
			// Chiều cao bảng bám theo số học sinh, nhưng không vượt phần viewport còn lại;
			// dữ liệu dài hơn sẽ cuộn trong JSpreadsheet thay vì đẩy page ra ngoài.
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
			getTableHeight(container) {
				// Chỉ cấp chiều cao còn lại cho JSpreadsheet; wrapper bên ngoài vẫn giữ 100%.
				if (typeof soGvcnJspreadsheet === 'object' && typeof soGvcnJspreadsheet.getTableHeight === 'function') {
					return soGvcnJspreadsheet.getTableHeight(container, '100%')
				}
				return '100%'
			},
			onWindowResize() {
				clearTimeout(this.resizeTimer)
				this.resizeTimer = setTimeout(() => this.initSheet(), 120)
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
			getInstance() {
				return this.instance
			},
			getRows() {
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				if (sheet && typeof sheet.closeEditor === 'function') {
					try { sheet.closeEditor(true) } catch (error) {}
				}
				return sheet && typeof sheet.getData === 'function' ? sheet.getData() : []
			},
			buildRows() {
				const findSaved = (hslopID) => (this.savedRows || []).find(r => Number(r.HSLopID) === Number(hslopID)) || {}
				return (this.students || []).map((student, idx) => {
					const saved = findSaved(student.HSLopID)
					return [
						idx + 1,
						student.MaHocSinh || student.HocSinhID || '',
						student.SoDanhBo || '',
						student.HoTen || student.HoTenHocSinh || '',
						saved.HKI || saved.ThanhTich || '',
						saved.CuoiNam || ''
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
		// Khởi tạo JSpreadsheet với chiều cao 100% tự co giãn theo flexbox viewport
		initSheet() {
			if (this.selectedLopID === '__ALL__') {
				this.destroySheet()
				return
			}
			this.$nextTick(() => {
				const container = this.$refs.sheetRef
				if (!container) return
				this.destroySheet()
				container.innerHTML = ''
				if (typeof jspreadsheet === 'function') {
					const data = this.buildRows()
					this.instance = soGvcnJspreadsheet.create(container, {
						worksheets: [{
							data: data,
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
				}
			})
		}
		}
	}
</script>