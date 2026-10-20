<template>
	<v-card-text class="pa-0 h-100 overflow-hidden d-flex flex-column" :style="{ height: sheetHeight, minHeight: '0' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
			Chọn một lớp ở thanh trên để xem thống kê độ tuổi học sinh.
		</v-alert>
		<div v-else class="w-100 flex-grow-1 overflow-hidden so-gvcn-thong-ke-do-tuoi-sheet" style="min-height: 0;">
			<div ref="sheetRef" class="w-100 overflow-hidden" style="min-height: 0;"></div>
		</div>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-thong-ke-do-tuoi',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			students: { type: Array, default: () => [] },
			savedRows: { type: Array, default: () => [] },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' }
		},
		data() {
			return {
				instance: null
			}
		},
		watch: {
			selectedLopID() {
				this.initSheet()
			},
			students: {
				deep: true,
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
			window.addEventListener('resize', this.onWindowResize)
			this.initSheet()
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.onWindowResize)
			clearTimeout(this.resizeTimer)
			this.destroySheet()
		},
		methods: {
			// Bảng có tối thiểu 20 dòng tuổi; chỉ khi dữ liệu dài hơn viewport mới tạo
			// scrollbar dọc bên trong JSpreadsheet.
			getContentTableHeight(container, rowCount, nestedHeaderCount = 0) {
				const rowHeight = 28
				const naturalHeight = Math.max(96, (Math.max(1, Number(nestedHeaderCount) + 1) * rowHeight)
					+ (Math.max(1, Number(rowCount) || 0) * rowHeight) + 4)
				// "100%" không đại diện cho phần màn hình còn lại khi tab nằm trong
				// v-window. Tính trực tiếp từ đáy viewport để bảng không làm trang dài ra.
				const top = Number(container?.getBoundingClientRect?.().top) || 0
				const viewportHeight = typeof window !== 'undefined'
					? Math.max(160, Math.floor(window.innerHeight - top - 64))
					: naturalHeight
				return `${Number.isFinite(viewportHeight) && viewportHeight > 0
					? Math.min(naturalHeight, viewportHeight)
					: naturalHeight}px`
			},
			onWindowResize() {
				clearTimeout(this.resizeTimer)
				this.resizeTimer = setTimeout(() => this.initSheet(), 120)
			},
			applyTableHeight(tableHeight) {
				const container = this.$refs.sheetRef
				if (!container) return
				container.querySelectorAll('.jss_content, .jspreadsheet_content')
					.forEach(element => {
						element.style.setProperty('height', tableHeight, 'important')
						element.style.setProperty('max-height', tableHeight, 'important')
					})
			},
			getInstance() {
				return this.instance
			},
			getRows() {
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance
				return sheet && typeof sheet.getData === 'function' ? sheet.getData() : []
			},
			// Tự động phân tích danh sách dân tộc xuất hiện trong lớp
			getEthnicList() {
				const ethnicSet = new Set()
				;(this.students || []).forEach(st => {
					const dt = (st.TenDanToc || st.DanToc || '').trim()
					if (dt) ethnicSet.add(dt)
				})
				const list = Array.from(ethnicSet)
				// Ưu tiên đưa 'Kinh' lên đầu nếu có
				if (list.includes('Kinh')) {
					return ['Kinh', ...list.filter(e => e !== 'Kinh')]
				}
				return list.length ? list : ['Kinh']
			},
			buildColumnsAndHeaders() {
				const ethnicList = this.getEthnicList()
				const columns = [
					{ title: 'Các độ tuổi', width: 220 },
					{ title: 'Nam', width: 100, align: 'center', type: 'numeric' },
					{ title: 'Nữ', width: 100, align: 'center', type: 'numeric' }
				]

				// Cột Dân tộc
				ethnicList.forEach(eth => {
					columns.push({ title: eth, width: 110, align: 'center', type: 'numeric' })
				})

				// Cột Khuyết tật (nhập số lượng)
				columns.push({ title: 'Khuyết tật', width: 140, align: 'center', type: 'numeric' })

				const nestedHeaders = [
					[
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: 'Dân tộc', colspan: ethnicList.length },
						{ title: '', colspan: 1 }
					]
				]

				return { columns, nestedHeaders, ethnicList }
			},

			buildRows(ethnicList) {
				const savedRows = this.savedRows || []
				const rowCount = Math.max(20, savedRows.length)
				return Array.from({ length: rowCount }, (_, index) => {
					const saved = savedRows[index] || {}
					let ethnicCounts = saved.EthnicCounts || saved.DanToc || {}
					if (saved.DanTocJson) {
						try {
							ethnicCounts = JSON.parse(saved.DanTocJson)
						} catch (error) {}
					}
					return [
						saved.AgeLabel || '',
						saved.Nam ?? '',
						saved.Nu ?? '',
						...ethnicList.map(eth => ethnicCounts[eth] ?? ''),
						saved.KhuyetTat ?? ''
					]
				})
			},

			getSerializableRows() {
				const ethnicList = this.getEthnicList()
				return this.getRows().map(row => {
					const ethnicCounts = {}
					ethnicList.forEach((eth, index) => {
						ethnicCounts[eth] = row[3 + index] ?? ''
					})
					return {
						AgeLabel: row[0] ?? '',
						Nam: row[1] ?? '',
						Nu: row[2] ?? '',
						DanTocJson: JSON.stringify(ethnicCounts),
						KhuyetTat: row[3 + ethnicList.length] ?? ''
					}
				}).filter(row => row.AgeLabel || row.Nam || row.Nu
					|| row.KhuyetTat || Object.values(JSON.parse(row.DanTocJson)).some(value => value !== ''))
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

					const { columns, nestedHeaders, ethnicList } = this.buildColumnsAndHeaders()
					const data = this.buildRows(ethnicList)
					const tableHeight = this.getContentTableHeight(container, data.length, nestedHeaders.length)

					if (typeof jspreadsheet === 'function') {
						this.instance = soGvcnJspreadsheet.create(container, {
							worksheets: [{
								data: data,
								columns: columns,
								nestedHeaders: nestedHeaders,
								rowResize: true,
								columnDrag: false,
								tableWidth: '100%',
								tableOverflow: true,
							tableHeight,
								lazyLoading: false,
								freezeColumns: 1,
								wordWrap: true,
								allowInsertColumn: false,
								allowInsertRow: false,
							showHeader: true
						}],
						contextMenu: () => false,
						onload: () => this.$nextTick(() => this.applyTableHeight(tableHeight))
						})
					}
				})
			}
		}
	}
</script>