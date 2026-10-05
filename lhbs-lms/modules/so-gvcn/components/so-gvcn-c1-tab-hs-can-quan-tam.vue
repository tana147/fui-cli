<template>
	<!-- Host chiếm 100% chiều cao tab trong viewport; JSpreadsheet giữ trọn vẹn cả hai thanh cuộn ngang/dọc bên trong. -->
	<v-card-text class="pa-0 h-100 overflow-hidden d-flex flex-column" style="min-height: 0;">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
			Chọn một lớp ở thanh trên để theo dõi học sinh cần quan tâm.
		</v-alert>
		<div v-else class="w-100 h-100 overflow-hidden so-gvcn-sheet so-gvcn-sheet-wrap so-gvcn-hs-can-quan-tam-sheet" style="min-height: 0;">
			<div ref="sheetRef" class="w-100 h-100 overflow-hidden" style="min-height: 0;"></div>
		</div>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-hs-can-quan-tam',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			students: { type: Array, default: () => [] },
			savedRows: { type: Array, default: () => [] },
			sheetHeight: { type: String,  },
			sheetKey: { type: [Number, String], default: 0 }
		},
		created() {
			this.instance = null
		},
		data() {
			return {
				timer: null,
				columns: [
					{ title: 'MÃ HỌC SINH', width: 120, readOnly: true },
					{ title: 'SỐ DANH BỘ', width: 120, readOnly: true },
					{ title: 'HỌ TÊN HỌC SINH', width: 220, readOnly: true },
					{ title: 'HS cần hỗ trợ đặc biệt (ghi rõ vấn đề-nếu có)', width: 350, align: 'justify' },
					{ title: 'THÁNG 8', width: 380, align: 'justify' },
					{ title: 'THÁNG 9', width: 380, align: 'justify' },
					{ title: 'THÁNG 10', width: 380, align: 'justify' },
					{ title: 'THÁNG 11', width: 380, align: 'justify' },
					{ title: 'THÁNG 12', width: 380, align: 'justify' },
					{ title: 'NHẬN XÉT HKI', width: 420, align: 'justify' },
					{ title: 'KẾT QUẢ HỌC TẬP VÀ RÈN LUYỆN HKI', width: 420, align: 'justify' },
					{ title: 'THÁNG 01 VÀ 02', width: 380, align: 'justify' },
					{ title: 'THÁNG 3', width: 380, align: 'justify' },
					{ title: 'THÁNG 4', width: 380, align: 'justify' },
					{ title: 'THÁNG 5', width: 380, align: 'justify' },
					{ title: 'NHẬN XÉT CUỐI NĂM HỌC', width: 420, align: 'justify' },
					{
						title: 'KẾT QUẢ HỌC TẬP VÀ RÈN LUYỆN CUỐI NĂM HỌC',
						width: 420,
						align: 'justify'
					}
				]
			}
		},
		watch: {
			selectedLopID() {
				this.scheduleInit()
			},
			students: {
				deep: false,
				handler() {
					this.scheduleInit()
				}
			},
			savedRows: {
				deep: false,
				handler() {
					this.scheduleInit()
				}
			},
			sheetKey() {
				this.scheduleInit()
			}
		},
		mounted() {
			this.scheduleInit()
		},
		beforeUnmount() {
			if (this.timer) clearTimeout(this.timer)
			this.destroySheet()
		},
		computed: {
			nestedHeaders() {
				return [
					[
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: 'GHI NHẬN/ THEO DÕI QUÁ TRÌNH RÈN LUYỆN CỦA HỌC SINH CẦN QUAN TÂM', colspan: 14 }
					]
				]
			}
		},
		methods: {
			// Bảng theo dõi có thể rất rộng; chỉ giới hạn chiều cao theo số dòng và viewport,
			// để phần rộng/dài còn lại cuộn trong JSpreadsheet.
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
			scheduleInit() {
				if (this.timer) clearTimeout(this.timer)
				this.$nextTick(() => {
					this.timer = window.setTimeout(() => {
						this.timer = null
						this.initSheet()
					}, 50)
				})
			},
			buildRows() {
				const findSaved = (hslopID) => (this.savedRows || [])
					.find(row => String(row.HSLopID) === String(hslopID)) || {}
				return (this.students || []).map((student) => {
					const saved = findSaved(student.HSLopID)
					return [
						student.MaHocSinh || student.HocSinhID || '',
						student.SoDanhBo || '',
						student.HoTen || student.HoTenHocSinh || '',
						saved.CanHoTroDacBiet || '',
						saved.Thang8 || '',
						saved.Thang9 || '',
						saved.Thang10 || '',
						saved.Thang11 || '',
						saved.Thang12 || '',
						saved.NhanXetHKI || '',
						saved.KetQuaHKI || '',
						saved.Thang1_2 || '',
						saved.Thang3 || '',
						saved.Thang4 || '',
						saved.Thang5 || '',
						saved.NhanXetCuoiNam || '',
						saved.KetQuaCuoiNam || ''
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
				const container = this.$refs.sheetRef
				if (!container) return

				this.destroySheet()
				container.innerHTML = ''
				if (typeof jspreadsheet !== 'function') return
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
						freezeColumns: 3,
						wordWrap: true,
						allowInsertColumn: false,
						allowInsertRow: false,
						showHeader: true
					}],
					contextMenu: () => false
				})
			}
		}
	}
</script>