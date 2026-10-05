<template>
	<!-- Host chiếm 100% chiều cao tab trong viewport; JSpreadsheet giữ trọn vẹn cả hai thanh cuộn ngang/dọc bên trong. -->
	<v-card-text class="pa-0 h-100 overflow-hidden d-flex flex-column" :style="{ height: sheetHeight, minHeight: '0' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
			Chọn một lớp ở thanh trên để theo dõi BHYT và BHTN của học sinh.
		</v-alert>
		<div v-else class="w-100 flex-grow-1 overflow-hidden so-gvcn-theo-doi-bhyt-bhtn-sheet" style="min-height: 0;">
			<div ref="sheetRef" class="w-100 h-100 overflow-hidden" style="min-height: 0;"></div>
		</div>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-theo-doi-bhyt-bhtn',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			students: { type: Array, default: () => [] },
			savedRows: { type: Array, default: () => [] },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' }
		},
		data() {
			return {
				instance: null,
				columns: [
					{ title: 'STT', width: 60, readOnly: true, align: 'center' },
					{ title: 'HỌ VÀ TÊN HỌC SINH', width: 250, readOnly: true },
					{ title: 'BHYT', width: 180 },
					{ title: 'BHTN', width: 180 },
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
			}
		},
		mounted() {
			this.initSheet()
		},
		beforeUnmount() {
			this.destroySheet()
		},
		computed: {
			nestedHeaders() {
				return [
					[
						{ title: '', colspan: 2 },
						{ title: 'KHOẢN MUA HOẶC ĐÓNG GÓP', colspan: 2 },
						{ title: '', colspan: 1 }
					]
				]
			}
		},
		methods: {
			// Chiều cao tự nhiên theo số học sinh, có giới hạn bởi phần viewport còn lại;
			// khi lớp dài hơn màn hình, JSpreadsheet giữ scrollbar bên trong bảng.
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
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				return sheet && typeof sheet.getData === 'function' ? sheet.getData() : []
			},
			buildRows() {
				const findSaved = (hslopID) => (this.savedRows || []).find(r => r.HSLopID === hslopID) || {}
				return (this.students || []).map((student, idx) => {
					const saved = findSaved(student.HSLopID)
					return [
						idx + 1,
						student.HoTen || student.HoTenHocSinh || '',
						saved.BHYT || '',
						saved.BHTN || '',
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
								freezeColumns: 2,
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