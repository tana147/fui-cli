<template>
	<v-card-text class="pa-0 h-100 overflow-hidden d-flex flex-column" :style="{ height: sheetHeight, minHeight: '0' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
			Chọn một lớp ở thanh trên để theo dõi sĩ số học sinh theo từng tháng.
		</v-alert>
		<div v-else class="w-100 flex-grow-1 overflow-hidden so-gvcn-theo-doi-si-so-sheet so-gvcn-c1-desktop-only" style="min-height: 0;">
			<div ref="sheetRef" class="w-100 overflow-hidden" style="min-height: 0;"></div>
		</div>
		<!-- Compact month cards keep every field editable and preserve the sheet row order for saving. -->
		<uc-so-gvcn-mobile-sheet-editor v-if="selectedLopID !== '__ALL__'" ref="mobileEditorRef"
			class="so-gvcn-c1-mobile-editor flex-column flex-grow-1" :rows="mobileEditorRows"
			:columns="mobileEditorColumns" :numeric-indices="mobileNumericIndices" :title-index="0" empty-title="Tháng"
			empty-text="Chưa có số liệu theo dõi sĩ số." />
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-theo-doi-si-so',
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
				defaultMonths: [
					'Tháng 8',
					'Tháng 9',
					'Tháng 10',
					'Tháng 11',
					'Tháng 12',
					'Tháng 1',
					'Tháng 2',
					'Tháng 3',
					'Tháng 4',
					'Tháng 5'
				]
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
			this.isMobileViewport = window.matchMedia('(max-width: 959.98px)').matches
			window.addEventListener('resize', this.onWindowResize)
			this.initSheet()
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.onWindowResize)
			clearTimeout(this.resizeTimer)
			this.destroySheet()
		},
		computed: {
			mobileEditorColumns() {
				return this.buildColumnsAndHeaders().columns
			},
			mobileNumericIndices() {
				return this.mobileEditorColumns.map((column, index) => index)
					.filter(index => index > 0 && index < this.mobileEditorColumns.length - 1)
			},
			mobileEditorRows() {
				const { ethnicList } = this.buildColumnsAndHeaders()
				return this.buildRows(ethnicList)
			}
		},
		methods: {
			onWindowResize() {
				clearTimeout(this.resizeTimer)
				this.resizeTimer = setTimeout(() => {
					const isMobile = window.matchMedia('(max-width: 959.98px)').matches
					if (isMobile === this.isMobileViewport) return
					this.isMobileViewport = isMobile
					this.initSheet()
				}, 120)
			},
			// Keep values readable in cards when server rows contain arrays or objects instead of plain strings.
			displayMobileValue(value) {
				if (value === null || value === undefined || (typeof value === 'string' && value.trim() === '')) return '—'
				if (Array.isArray(value)) {
					const items = value.map(item => this.displayMobileValue(item)).filter(item => item !== '—')
					return items.length ? items.join(', ') : '—'
				}
				if (typeof value === 'object') {
					try { return JSON.stringify(value) || '—' } catch (error) { return '—' }
				}
				return String(value)
			},
			// Chỉ cấp chiều cao cần cho 10 dòng tháng; nếu số dòng tăng vượt viewport,
			// phần dư vẫn được giữ trong scrollbar của JSpreadsheet.
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
				if (typeof window !== 'undefined' && window.matchMedia('(max-width: 959.98px)').matches) {
					return this.$refs.mobileEditorRef?.getRows?.() || this.buildRows(this.getEthnicList())
				}
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
				if (list.includes('Kinh')) {
					return ['Kinh', ...list.filter(e => e !== 'Kinh')]
				}
				return list.length ? list : ['Kinh']
			},

			// Dự phòng cho giai đoạn sau: tự động tính tổng số, nữ và dân tộc.
			// Hiện tại chưa gọi hàm này theo yêu cầu nghiệp vụ.
			getClassSummary(ethnicList) {
				let total = 0, nu = 0
				const ethnicMap = {}
				ethnicList.forEach(e => ethnicMap[e] = 0)

				;(this.students || []).forEach(st => {
					total++
					const isNu = (st.GioiTinh === 'Nữ' || st.Phai === 'x' || st.IsNu)
					if (isNu) nu++

					const dt = (st.TenDanToc || st.DanToc || '').trim()
					if (dt && ethnicMap[dt] !== undefined) {
						ethnicMap[dt]++
					}
				})

				return { total, nu, ethnicMap }
			},

			buildColumnsAndHeaders() {
				const ethnicList = this.getEthnicList()
				const columns = [
					{ title: 'Thời điểm', width: 140, readOnly: true },
					{ title: 'Tổng số', width: 90, align: 'center', type: 'text', readOnly: false },
					{ title: 'Nữ', width: 90, align: 'center', type: 'text', readOnly: false }
				]

				// Nhóm Dân tộc
				ethnicList.forEach(eth => {
					columns.push({ title: eth, width: 100, align: 'center', type: 'text', readOnly: false })
				})

				// Cột Đội viên, Nhi đồng, Con liệt sĩ, Con thương binh
				columns.push({ title: 'Đội viên', width: 100, align: 'center', type: 'text', readOnly: false })
				columns.push({ title: 'Nhi đồng', width: 100, align: 'center', type: 'text', readOnly: false })
				columns.push({ title: 'Con liệt sĩ', width: 100, align: 'center', type: 'text', readOnly: false })
				columns.push({ title: 'Con thương binh', width: 120, align: 'center', type: 'text', readOnly: false })

				// Khuyết tật (Có đánh giá, Không đánh giá)
				columns.push({ title: 'Có đánh giá', width: 110, align: 'center', type: 'text', readOnly: false })
				columns.push({ title: 'Không đánh giá', width: 120, align: 'center', type: 'text', readOnly: false })

				// Hộ nghèo, Lí do tăng giảm
				columns.push({ title: 'Hộ nghèo', width: 100, align: 'center', type: 'text', readOnly: false })
				columns.push({ title: 'Học sinh tăng giảm, lí do', width: 280, readOnly: false })

				const nestedHeaders = [
					[
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: 'Dân tộc', colspan: ethnicList.length },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 },
						{ title: 'Khuyết tật', colspan: 2 },
						{ title: '', colspan: 1 },
						{ title: '', colspan: 1 }
					]
				]

				return { columns, nestedHeaders, ethnicList }
			},

			buildRows(ethnicList) {
				const findSaved = (thoiDiem) => (this.savedRows || []).find(r => r.ThoiDiem === thoiDiem) || {}

				return this.defaultMonths.map(thoiDiem => {
					const saved = findSaved(thoiDiem)
					let savedEthnicCounts = saved.DanTocJson || saved.DanToc || {}
					if (typeof savedEthnicCounts === 'string') {
						try {
							savedEthnicCounts = JSON.parse(savedEthnicCounts)
						} catch (error) {
							savedEthnicCounts = {}
						}
					}
					const ethnicValues = ethnicList.map(eth => savedEthnicCounts?.[eth] ?? '')
					return [
						thoiDiem,
						saved.TongSo ?? '',
						saved.Nu ?? '',
						...ethnicValues,
						saved.DoiVien ?? '',
						saved.NhiDong ?? '',
						saved.ConLietSi ?? '',
						saved.ConThuongBinh ?? '',
						saved.KhuyetTatCoDanhGia ?? saved.KhuyetTat ?? '',
						saved.KhuyetTatKhongDanhGia ?? '',
						saved.HoNgheo ?? '',
						saved.TangGiamLiDo ?? ''
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
				if (this.selectedLopID === '__ALL__') {
					this.destroySheet()
					return
				}
				if (this.isMobileViewport) {
					this.destroySheet()
					return
				}
				this.$nextTick(() => {
					const container = this.$refs.sheetRef
					if (!container) return
					this.destroySheet()
					container.innerHTML = ''

					const { columns, nestedHeaders, ethnicList } = this.buildColumnsAndHeaders()
					const data = Array.isArray(initialRows) ? initialRows : this.buildRows(ethnicList)

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
								tableHeight: 'auto',
								lazyLoading: false,
								freezeColumns: 1,
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