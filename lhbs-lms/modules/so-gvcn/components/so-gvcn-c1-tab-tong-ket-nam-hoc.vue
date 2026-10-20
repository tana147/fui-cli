<template>
	<!-- Không dùng so-gvcn-sheet-wrap ở root: rule chung ép height:auto, làm mất vùng scroll của nội dung. -->
	<v-card-text class="pt-2 pb-2 px-2 d-flex flex-column so-gvcn-tong-ket-tab"
		:style="{ height: sheetHeight, overflow: 'hidden', minHeight: '0' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact" class="ma-2">
			Chọn một lớp ở thanh trên để xem và biên soạn Tổng kết cuối năm học.
		</v-alert>

		<div v-else class="d-flex flex-grow-1 ga-3 so-gvcn-c1-desktop-only" style="min-height: 0; min-width: 0;">
			<div class="d-none d-md-block flex-shrink-0 overflow-y-auto"
				style="width: 260px; min-height: 0; border-right: 1px solid rgba(0, 0, 0, 0.12);">
				<v-list density="compact" nav color="primary" class="pa-0">
					<v-list-subheader class="text-caption font-weight-bold text-primary px-3">
						ĐÁNH GIÁ TỔNG QUAN
					</v-list-subheader>
					<v-list-item v-for="item in navItems.slice(0, 3)" :key="item.key"
						:value="item.key" :active="activeSection === item.key" class="mb-1 rounded"
						@click="scrollToSection(item)">
						<v-list-item-title class="text-caption font-weight-bold text-wrap">
							{{ item.title }}
						</v-list-item-title>
					</v-list-item>
					<v-list-subheader class="text-caption font-weight-bold text-primary px-3 mt-2">
						KẾT QUẢ CUỐI NĂM
					</v-list-subheader>
					<v-list-item v-for="item in navItems.slice(3)" :key="item.key"
						:value="item.key" :active="activeSection === item.key" class="mb-1 rounded"
						@click="scrollToSection(item)">
						<v-list-item-title class="text-caption font-weight-bold text-wrap">
							{{ item.title }}
						</v-list-item-title>
					</v-list-item>
				</v-list>
			</div>

			<div ref="scrollContainer" class="flex-grow-1 overflow-y-auto" style="min-height: 0; min-width: 0;">
				<div class="text-h6 text-center font-weight-bold py-3">TỔNG KẾT NĂM HỌC</div>
				<v-card ref="sectionDuyTri" class="mb-4" variant="outlined">
					<v-card-title class="text-subtitle-1 font-weight-bold">1. Công tác duy trì số lượng</v-card-title>
					<v-card-text><v-textarea v-model="localForm.DuyTriSoLuong" rows="4" variant="outlined" density="compact" hide-details /></v-card-text>
				</v-card>
				<v-card ref="sectionNlPc" class="mb-4" variant="outlined">
					<v-card-title class="text-subtitle-1 font-weight-bold">2. Về năng lực, phẩm chất</v-card-title>
					<v-card-text><v-textarea v-model="localForm.NangLucPhamChat" rows="4" variant="outlined" density="compact" hide-details /></v-card-text>
				</v-card>
				<v-card ref="sectionKienThuc" class="mb-4" variant="outlined">
					<v-card-title class="text-subtitle-1 font-weight-bold">3. Về kiến thức, kĩ năng</v-card-title>
					<v-card-text><v-textarea v-model="localForm.KienThucKyNang" rows="4" variant="outlined" density="compact" hide-details /></v-card-text>
				</v-card>
				<v-card class="mb-4" variant="outlined">
					<v-card-title class="py-2">
						<span class="text-subtitle-1 font-weight-bold text-primary">
							KẾT QUẢ CUỐI NĂM HỌC
						</span>
					</v-card-title>
					<v-divider />
					<v-card-text class="pa-0">
						<section ref="sectionKetQuaNlPc" class="pa-3">
							<div class="text-subtitle-2 font-weight-bold text-primary mb-3">
								1. Về năng lực, phẩm chất
								<span class="text-caption text-medium-emphasis">({{ getKyDanhGiaTitle() }})</span>
							</div>
							<div ref="sheetRef1"
								class="w-100 so-gvcn-sheet so-gvcn-summary-result-sheet"></div>
						</section>
						<section ref="sectionMonHoc" class="pa-3 border-t">
							<div class="text-subtitle-2 font-weight-bold text-primary mb-3">
								2. Về môn học và hoạt động giáo dục
								<span class="text-caption text-medium-emphasis">({{ getKyDanhGiaTitle() }})</span>
							</div>
							<div ref="sheetRef2"
								class="w-100 so-gvcn-sheet so-gvcn-summary-result-sheet"></div>
						</section>
						<section ref="sectionKetQuaGd" class="pa-3 border-t">
							<div class="text-subtitle-2 font-weight-bold text-primary mb-3">
								3. Về đánh giá kết quả giáo dục
							</div>
							<div ref="sheetRef3"
								class="w-100 so-gvcn-sheet so-gvcn-summary-result-sheet"></div>
						</section>
						<section ref="sectionKhenThuong" class="pa-3 border-t">
							<div class="text-subtitle-2 font-weight-bold text-primary mb-3">
								4. Khen thưởng
							</div>
							<div ref="sheetRef4"
								class="w-100 so-gvcn-sheet so-gvcn-summary-result-sheet"></div>
						</section>
					</v-card-text>
				</v-card>
				<v-card ref="sectionHoanThanh" class="mb-4" variant="outlined">
					<v-card-title class="text-subtitle-1 font-weight-bold">5. Hoàn thành chương trình lớp học</v-card-title>
					<v-card-text><v-textarea v-model="localForm.HoanThanhCT" rows="4" variant="outlined" density="compact" hide-details /></v-card-text>
				</v-card>
				<v-card ref="sectionPhongTrao" variant="outlined">
					<v-card-title class="text-subtitle-1 font-weight-bold">6. Các hoạt động, phong trào khác</v-card-title>
					<v-card-text><v-textarea v-model="localForm.PhongTraoKhac" rows="4" variant="outlined" density="compact" hide-details /></v-card-text>
				</v-card>
			</div>
		</div>
		<!-- Native phone editors keep period ratings and summary notes editable without a wide grid. -->
		<div v-if="selectedLopID !== '__ALL__'" class="so-gvcn-c1-mobile-editor flex-column flex-grow-1 overflow-y-auto">
			<div class="pa-2">
				<v-select :model-value="selectedKyDanhGia" :items="kyDanhGiaOptions" item-title="title" item-value="value"
					label="Kỳ đánh giá" variant="outlined" density="compact" hide-details
					@update:model-value="prepareEvaluationPeriod" />
			</div>
			<v-expansion-panels multiple>
				<v-expansion-panel value="general">
					<v-expansion-panel-title>Đánh giá chung</v-expansion-panel-title>
					<v-expansion-panel-text>
						<v-textarea v-model="localForm.DuyTriSoLuong" label="1. Công tác duy trì số lượng" rows="3" auto-grow variant="outlined" density="compact" class="mb-3" hide-details />
						<v-textarea v-model="localForm.NangLucPhamChat" label="2. Về năng lực, phẩm chất" rows="3" auto-grow variant="outlined" density="compact" class="mb-3" hide-details />
						<v-textarea v-model="localForm.KienThucKyNang" label="3. Về kiến thức, kĩ năng" rows="3" auto-grow variant="outlined" density="compact" hide-details />
					</v-expansion-panel-text>
				</v-expansion-panel>
				<v-expansion-panel v-for="section in mobileResultDefinitions" :key="section.key" :value="section.key">
					<v-expansion-panel-title>{{ section.title }}</v-expansion-panel-title>
					<v-expansion-panel-text>
						<uc-so-gvcn-mobile-sheet-editor :ref="'mobileSummary_' + section.key"
							:rows="getInitialMobileRows(section.key)" :columns="getMobileColumns(section.key)"
							:nested-headers="getMobileNestedHeaders(section.key)" :title-index="0"
							empty-title="Nội dung" @cell-changed="onMobileSummaryCellChanged(section.key, $event)" />
					</v-expansion-panel-text>
				</v-expansion-panel>
				<v-expansion-panel value="conclusion">
					<v-expansion-panel-title>Hoàn thành chương trình và phong trào</v-expansion-panel-title>
					<v-expansion-panel-text>
						<v-textarea v-model="localForm.HoanThanhCT" label="5. Hoàn thành chương trình lớp học" rows="3" auto-grow variant="outlined" density="compact" class="mb-3" hide-details />
						<v-textarea v-model="localForm.PhongTraoKhac" label="6. Các hoạt động, phong trào khác" rows="3" auto-grow variant="outlined" density="compact" hide-details />
					</v-expansion-panel-text>
				</v-expansion-panel>
			</v-expansion-panels>
		</div>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-tong-ket-nam-hoc',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			selectedClass: { type: Object, default: () => null },
			nienKhoa: { type: [String, Number], default: () => new Date().getFullYear() },
			savedData: { type: Object, default: () => ({}) },
			students: { type: Array, default: () => [] },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' }
		},
		data() {
			return {
				sheet1Instance: null,
				sheet2Instance: null,
				sheet3Instance: null,
				sheet4Instance: null,
				activeSection: 'duy-tri',
				isMobileViewport: false,
				mobileSheetRows: {},
				selectedKyDanhGia: 4,
				syncLoading: false,
				// Sheet 1 và Sheet 2 được giữ riêng theo từng kỳ; Sheet 3/4 là phần tổng kết chung.
				periodSheetData: {
					Sheet1: {},
					Sheet2: {}
				},
				// Ở bậc Tiểu học chia làm 4 kỳ đánh giá:
				// 1: Giữa HK1, 2: Cuối HK1, 3: Giữa HK2, 4: Cuối HK2
				kyDanhGiaOptions: [
					{ title: 'Giữa HK1', value: 1 },
					{ title: 'Cuối HK1', value: 2 },
					{ title: 'Giữa HK2', value: 3 },
					{ title: 'Cuối HK2', value: 4 }
				],
				navItems: [
					{ key: 'duy-tri', refName: 'sectionDuyTri', title: '1. Công tác duy trì số lượng' },
					{ key: 'nang-luc-pham-chat', refName: 'sectionNlPc', title: '2. Về năng lực, phẩm chất' },
					{ key: 'kien-thuc-ky-nang', refName: 'sectionKienThuc', title: '3. Về kiến thức, kĩ năng' },
					{ key: 'ket-qua-nl-pc', refName: 'sectionKetQuaNlPc', title: '1. Về năng lực, phẩm chất' },
					{ key: 'mon-hoc-hdgd', refName: 'sectionMonHoc', title: '2. Về môn học và HĐGD' },
					{ key: 'ket-qua-giao-duc', refName: 'sectionKetQuaGd', title: '3. Đánh giá kết quả giáo dục' },
					{ key: 'khen-thuong', refName: 'sectionKhenThuong', title: '4. Khen thưởng' },
					{ key: 'hoan-thanh-chuong-trinh', refName: 'sectionHoanThanh', title: '5. Hoàn thành chương trình lớp' },
					{ key: 'phong-trao-khac', refName: 'sectionPhongTrao', title: '6. Hoạt động, phong trào khác' }
				],
				localForm: {
					DuyTriSoLuong: '',
					NangLucPhamChat: '',
					KienThucKyNang: '',
					HoanThanhCT: '',
					PhongTraoKhac: ''
				}
			}
		},
		watch: {
			nienKhoa() {
				// Khi thay đổi niên khóa, reset lại form và khởi tạo lại toàn bộ sheet dữ liệu
				this.localForm.DuyTriSoLuong = ''
				this.localForm.NangLucPhamChat = ''
				this.localForm.KienThucKyNang = ''
				this.localForm.HoanThanhCT = ''
				this.localForm.PhongTraoKhac = ''
				this.periodSheetData = { Sheet1: {}, Sheet2: {} }
				this.mobileSheetRows = {}
				this.initAllSheets()
			},
			selectedLopID() {
				this.periodSheetData = { Sheet1: {}, Sheet2: {} }
				this.mobileSheetRows = {}
				this.initAllSheets()
			},
			savedData: {
				deep: true,
				handler(val) {
					if (val) {
						this.localForm.DuyTriSoLuong = val.DuyTriSoLuong || ''
						this.localForm.NangLucPhamChat = val.NangLucPhamChat || ''
						this.localForm.KienThucKyNang = val.KienThucKyNang || ''
						this.localForm.HoanThanhCT = val.HoanThanhCT || ''
						this.localForm.PhongTraoKhac = val.PhongTraoKhac || ''
					}
					this.syncPeriodSheetData()
					this.mobileSheetRows = {}
					this.initAllSheets()
				}
			}
		},
		mounted() {
			this.isMobileViewport = window.matchMedia('(max-width: 959.98px)').matches
			window.addEventListener('resize', this.onWindowResize)
			if (this.savedData) {
				this.localForm.DuyTriSoLuong = this.savedData.DuyTriSoLuong || ''
				this.localForm.NangLucPhamChat = this.savedData.NangLucPhamChat || ''
				this.localForm.KienThucKyNang = this.savedData.KienThucKyNang || ''
				this.localForm.HoanThanhCT = this.savedData.HoanThanhCT || ''
				this.localForm.PhongTraoKhac = this.savedData.PhongTraoKhac || ''
			}
			this.syncPeriodSheetData()
			this.initAllSheets()
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.onWindowResize)
			this.destroyAllSheets()
		},
		computed: {
			mobileResultDefinitions() {
				return [
					{ key: 'Sheet1', title: '1. Năng lực, phẩm chất (' + this.getKyDanhGiaTitle() + ')' },
					{ key: 'Sheet2', title: '2. Môn học và hoạt động giáo dục (' + this.getKyDanhGiaTitle() + ')' },
					{ key: 'Sheet3', title: '3. Đánh giá kết quả giáo dục' },
					{ key: 'Sheet4', title: '4. Khen thưởng' }
				]
			}
		},
		methods: {
			onWindowResize() {
				const nextIsMobile = window.matchMedia('(max-width: 959.98px)').matches
				if (nextIsMobile === this.isMobileViewport) return
				const sheet1Rows = this.getSheetRows(this.sheet1Instance, 'Sheet1')
				const sheet2Rows = this.getSheetRows(this.sheet2Instance, 'Sheet2')
				this.mobileSheetRows = {
					Sheet1: this.toMobileRatingRows('Sheet1', sheet1Rows),
					Sheet2: this.toMobileRatingRows('Sheet2', sheet2Rows),
					Sheet3: this.getSheetRows(this.sheet3Instance, 'Sheet3'),
					Sheet4: this.getSheetRows(this.sheet4Instance, 'Sheet4')
				}
				if (sheet1Rows.length) this.setPeriodSheetRows('Sheet1', sheet1Rows)
				if (sheet2Rows.length) this.setPeriodSheetRows('Sheet2', sheet2Rows)
				this.isMobileViewport = nextIsMobile
				this.$nextTick(() => this.initAllSheets())
			},
			// Các sheet kết quả nằm trong scrollContainer chung của tab. Không lấy chiều
			// cao theo vị trí hiện tại trong viewport: sheet ở phía dưới sẽ trả về fallback
			// "100%" hoặc một giá trị rất nhỏ trước khi người dùng cuộn tới, khiến
			// JSpreadsheet cắt mất toàn bộ phần thân dữ liệu dưới các hàng tiêu đề.
			getContentTableHeight(container, rowCount, nestedHeaderCount = 0) {
				const rowHeight = 28
				const naturalHeight = Math.max(96, (Math.max(1, Number(nestedHeaderCount) + 1) * rowHeight)
					+ (Math.max(1, Number(rowCount) || 0) * rowHeight) + 4)
				return `${naturalHeight}px`
			},
			/**
			 * Hàm làm sạch giá trị ô để tránh lỗi kiểu dữ liệu hoặc cú pháp
			 */
			cleanSheetValue(val) {
				if (val === null || val === undefined) return ''
				if (typeof val === 'object') return ''
				return String(val).trim()
			},

			/**
			 * Lấy Khối ID hiện tại dựa trên prop selectedClass hoặc selectedLopID
			 */
			getCurrentKhoiID() {
				if (this.selectedClass && this.selectedClass.KhoiID) {
					return Number(this.selectedClass.KhoiID)
				}
				if (Array.isArray(this.students) && this.students[0]?.KhoiID) {
					return Number(this.students[0].KhoiID)
				}
				// Fallback tìm theo tên lớp (ví dụ '1A', '2B',...)
				const tenLop = this.selectedClass?.TenLop || ''
				const match = tenLop.match(/^([1-5])/)
				if (match) return Number(match[1])
				return 1
			},

			getKyDanhGiaTitle(value = this.selectedKyDanhGia) {
				return this.kyDanhGiaOptions.find(item => Number(item.value) === Number(value))?.title || `Kỳ ${value}`
			},

			cloneSheetRows(rows) {
				if (!Array.isArray(rows)) return []
				return rows.map(row => Array.isArray(row)
					? row.map(value => (value === null || value === undefined || typeof value === 'object') ? '' : value)
					: [])
			},

			normalizePeriodSheetData(value) {
				let source = value
				if (typeof source === 'string') {
					try { source = JSON.parse(source) } catch (error) { source = [] }
				}

				const result = {}
				const periods = source && !Array.isArray(source) && typeof source === 'object'
					? source.periods
					: null
				if (periods && typeof periods === 'object' && !Array.isArray(periods)) {
					Object.keys(periods).forEach(period => {
						const rows = this.cloneSheetRows(periods[period])
						if (rows.length) result[String(period)] = rows
					})
				} else if (Array.isArray(source) && source.length) {
					// Dữ liệu cũ chỉ có một mảng được xem là số liệu cuối năm (kỳ 4).
					result['4'] = this.cloneSheetRows(source)
				}
				return result
			},

			syncPeriodSheetData() {
				this.periodSheetData = {
					Sheet1: this.normalizePeriodSheetData(this.savedData?.Sheet1),
					Sheet2: this.normalizePeriodSheetData(this.savedData?.Sheet2)
				}
			},

			getPeriodSheetRows(sheetKey, period = this.selectedKyDanhGia) {
				const rows = this.periodSheetData?.[sheetKey]?.[String(period)]
				return this.cloneSheetRows(rows)
			},

			setPeriodSheetRows(sheetKey, rows, period = this.selectedKyDanhGia) {
				if (!this.periodSheetData[sheetKey]) this.periodSheetData[sheetKey] = {}
				this.periodSheetData[sheetKey][String(period)] = this.cloneSheetRows(rows)
			},

			getSheetRows(instance, sheetKey = '') {
				if (this.isMobileViewport && sheetKey) return this.getMobileSheetRows(sheetKey)
				const sheet = Array.isArray(instance) ? instance[0] : instance
				if (sheet && typeof sheet.closeEditor === 'function') {
					try { sheet.closeEditor(true) } catch (error) {}
				}
				return sheet && typeof sheet.getData === 'function'
					? this.cloneSheetRows(sheet.getData())
					: []
			},

			applyRowsToSheet(instance, rows, sheetKey = '') {
				if (this.isMobileViewport && sheetKey) {
					const mobileRows = sheetKey === 'Sheet1' || sheetKey === 'Sheet2'
						? this.toMobileRatingRows(sheetKey, rows)
						: this.cloneSheetRows(rows)
					this.mobileSheetRows[sheetKey] = mobileRows
					if (sheetKey === 'Sheet1' || sheetKey === 'Sheet2') this.setPeriodSheetRows(sheetKey, rows)
					this.$refs['mobileSummary_' + sheetKey]?.setRows?.(mobileRows)
					return true
				}
				const sheet = Array.isArray(instance) ? instance[0] : instance
				if (!sheet) return false
				const safeRows = this.cloneSheetRows(rows)
				if (typeof sheet.setData === 'function') {
					try {
						sheet.setData(safeRows)
						return true
					} catch (error) {
						console.warn('sheet.setData gặp lỗi, chuyển sang setValueFromCoords:', error)
					}
				}
				if (typeof sheet.setValueFromCoords === 'function') {
					safeRows.forEach((row, y) => {
						row.forEach((value, x) => sheet.setValueFromCoords(x, y, value, true))
					})
					return true
				}
				return false
			},

			buildSheetRows(labels, dataColumnCount, savedRows = []) {
				return labels.map((label, rowIndex) => {
					const savedRow = Array.isArray(savedRows[rowIndex]) ? savedRows[rowIndex] : []
					return [label, ...Array.from({ length: dataColumnCount }, (_, columnIndex) => savedRow[columnIndex + 1] ?? '')]
				})
			},

			buildSheet1Rows(savedRows = []) {
				return this.buildSheetRows(['Tốt (T)', 'Đạt (Đ)', 'Cần cố gắng (C)'], 30, savedRows)
			},

			buildSheet2Rows(savedRows = []) {
				return this.buildSheetRows(['Hoàn thành tốt (T)', 'Hoàn thành (H)', 'Chưa hoàn thành (C)'], 22, savedRows)
			},
			getMobileFieldNames(sheetKey) {
				if (sheetKey === 'Sheet1') {
					return [
						'Phẩm chất — Yêu nước', 'Phẩm chất — Nhân ái', 'Phẩm chất — Chăm chỉ',
						'Phẩm chất — Trung thực', 'Phẩm chất — Trách nhiệm', 'Năng lực — Tự chủ và tự học',
						'Năng lực — Giao tiếp và hợp tác', 'Năng lực — Giải quyết vấn đề và sáng tạo',
						'Năng lực — Ngôn ngữ', 'Năng lực — Tính toán', 'Năng lực — Khoa học',
						'Năng lực — Thẩm mĩ', 'Năng lực — Thể chất', 'Năng lực — Công nghệ', 'Năng lực — Tin học'
					]
				}
				if (sheetKey === 'Sheet2') {
					return ['Tiếng Việt', 'Toán', 'Tiếng Anh', 'Lịch sử và Địa lí',
						this.getCurrentKhoiID() <= 3 ? 'Tự nhiên và Xã hội' : 'Khoa học',
						'Tin học - Công nghệ', 'Đạo đức', 'Giáo dục thể chất', 'Âm nhạc', 'Mĩ thuật', 'Hoạt động trải nghiệm']
				}
				return []
			},
			toMobileRatingRows(sheetKey, rows) {
				const ratingRows = this.cloneSheetRows(rows)
				const fields = this.getMobileFieldNames(sheetKey)
				return fields.map((title, fieldIndex) => [title, ...ratingRows.flatMap(row => [
					row[1 + fieldIndex * 2] ?? '', row[2 + fieldIndex * 2] ?? ''
				])])
			},
			toCanonicalRatingRows(sheetKey, mobileRows) {
				const fields = this.getMobileFieldNames(sheetKey)
				const defaults = sheetKey === 'Sheet1' ? this.buildSheet1Rows() : this.buildSheet2Rows()
				return defaults.map((row, ratingIndex) => [row[0], ...fields.flatMap((_, fieldIndex) => {
					const mobileRow = mobileRows[fieldIndex] || []
					return [mobileRow[1 + ratingIndex * 2] ?? '', mobileRow[2 + ratingIndex * 2] ?? '']
				})])
			},
			getMobileNestedHeaders(sheetKey) {
				if (sheetKey !== 'Sheet1' && sheetKey !== 'Sheet2') return []
				const ratingLabels = sheetKey === 'Sheet1'
					? ['Tốt (T)', 'Đạt (Đ)', 'Cần cố gắng (C)']
					: ['Hoàn thành tốt (T)', 'Hoàn thành (H)', 'Chưa hoàn thành (C)']
				const nestedRatings = [{ title: '', colspan: 1 }, ...ratingLabels.map(title => ({ title, colspan: 2 }))]
				const fieldHeaders = [{ title: '', colspan: 1 }]
				ratingLabels.forEach(() => fieldHeaders.push({ title: 'Số lượng', colspan: 1 }, { title: 'Tỉ lệ (%)', colspan: 1 }))
				return [nestedRatings, fieldHeaders]
			},
			getMobileColumns(sheetKey) {
				if (sheetKey === 'Sheet1' || sheetKey === 'Sheet2') {
					const columns = [{ title: 'Chỉ tiêu', width: 250, readOnly: true }]
					for (let index = 0; index < 3; index++) {
						columns.push({ title: 'Số lượng', type: 'numeric' }, { title: 'Tỉ lệ (%)', type: 'numeric' })
					}
					return columns
				}
				if (sheetKey === 'Sheet3') return [
					{ title: 'Xếp loại', width: 250, readOnly: true },
					{ title: 'Số lượng', type: 'numeric' }, { title: 'Tỉ lệ (%)', type: 'numeric' }
				]
				return [
					{ title: 'Danh hiệu', width: 250, readOnly: true },
					{ title: 'Số lượng', type: 'numeric' }, { title: 'Tỉ lệ (%)', type: 'numeric' }
				]
			},
			buildFinalResultRows(sheetKey) {
				if (sheetKey === 'Sheet3') {
					const saved = this.savedData?.Sheet3 || []
					return ['Hoàn thành xuất sắc', 'Hoàn thành tốt', 'Hoàn thành', 'Chưa hoàn thành'].map((label, index) => [label, saved[index]?.[1] ?? '', saved[index]?.[2] ?? ''])
				}
				const saved = this.savedData?.Sheet4 || []
				return ['Học sinh Xuất sắc', 'Học sinh tiêu biểu hoàn thành tốt trong học tập và rèn luyện'].map((label, index) => [label, saved[index]?.[1] ?? '', saved[index]?.[2] ?? ''])
			},
			getInitialMobileRows(sheetKey) {
				if (this.mobileSheetRows[sheetKey]) return this.mobileSheetRows[sheetKey]
				if (sheetKey === 'Sheet1' || sheetKey === 'Sheet2') {
					const saved = this.getPeriodSheetRows(sheetKey)
					const canonical = saved.length ? saved : (sheetKey === 'Sheet1' ? this.buildSheet1Rows() : this.buildSheet2Rows())
					return this.toMobileRatingRows(sheetKey, canonical)
				}
			return this.buildFinalResultRows(sheetKey)
			},
			getMobileSheetRows(sheetKey) {
				const rows = this.$refs['mobileSummary_' + sheetKey]?.getRows?.()
					|| this.mobileSheetRows[sheetKey]
					|| this.getInitialMobileRows(sheetKey)
				this.mobileSheetRows[sheetKey] = this.cloneSheetRows(rows)
				if (sheetKey === 'Sheet1' || sheetKey === 'Sheet2') {
					const canonical = this.toCanonicalRatingRows(sheetKey, rows)
					this.setPeriodSheetRows(sheetKey, canonical)
					return canonical
				}
				return this.cloneSheetRows(rows)
			},
			onMobileSummaryCellChanged(sheetKey, change) {
				this.mobileSheetRows[sheetKey] = this.cloneSheetRows(change.rows)
				if (sheetKey === 'Sheet1' || sheetKey === 'Sheet2') {
					this.setPeriodSheetRows(sheetKey, this.toCanonicalRatingRows(sheetKey, change.rows))
				}
			},

			captureCurrentPeriodSheetData() {
				const sheet1Rows = this.getSheetRows(this.sheet1Instance, 'Sheet1')
				const sheet2Rows = this.getSheetRows(this.sheet2Instance, 'Sheet2')
				if (sheet1Rows.length) this.setPeriodSheetRows('Sheet1', sheet1Rows)
				if (sheet2Rows.length) this.setPeriodSheetRows('Sheet2', sheet2Rows)
			},

			prepareEvaluationPeriod(period) {
				const nextPeriod = Number(period)
				if (!this.kyDanhGiaOptions.some(item => Number(item.value) === nextPeriod)) return

				// Lưu bản đang hiển thị vào đúng kỳ trước khi chuyển kỳ, để thao tác đổi kỳ không làm mất chỉnh sửa thủ công.
				this.captureCurrentPeriodSheetData()
				this.selectedKyDanhGia = nextPeriod
				const sheet1Rows = this.getPeriodSheetRows('Sheet1', nextPeriod)
				const sheet2Rows = this.getPeriodSheetRows('Sheet2', nextPeriod)
				this.applyRowsToSheet(this.sheet1Instance, sheet1Rows.length ? sheet1Rows : this.buildSheet1Rows(), 'Sheet1')
				this.applyRowsToSheet(this.sheet2Instance, sheet2Rows.length ? sheet2Rows : this.buildSheet2Rows(), 'Sheet2')
			},

			buildPeriodizedSheetData(sheetKey) {
				this.captureCurrentPeriodSheetData()
				const periods = {}
				Object.keys(this.periodSheetData?.[sheetKey] || {}).forEach(period => {
					const rows = this.getPeriodSheetRows(sheetKey, period)
					if (rows.length) periods[String(period)] = rows
				})
				return {
					version: 2,
					type: 'c1-year-summary-periods',
					periods
				}
			},

			/**
			 * Đồng bộ và nạp số liệu đánh giá từ 2 API của hệ thống đánh giá:
			 * 1. REPORT_GetThongKeDanhGia_TheoMon -> Đổ vào Sheet 2 (Môn học và HĐGD)
			 * 2. REPORT_GetThongKeDanhGia_TheoNangLucPhamChat -> Đổ vào Sheet 1 (Năng lực, phẩm chất)
			 */
			async fetchAndApplyEvaluationStats(customKyDanhGia, options = {}) {
				// Ngăn chặn gọi trùng lặp nếu đang trong tiến trình tải số liệu đánh giá
				if (this.syncLoading) return
				if (this.selectedLopID === '__ALL__') {
					if (!options.quiet && typeof showMessage === 'function') {
						showMessage({ title: 'Vui lòng chọn một lớp cụ thể để lấy số liệu đánh giá.' })
					}
					return
				}

				this.syncLoading = true
				try {
					const namHocStr = String(this.nienKhoa || new Date().getFullYear())
					const kyDanhGiaNum = Number(customKyDanhGia !== undefined ? customKyDanhGia : (this.selectedKyDanhGia || 1))
					this.prepareEvaluationPeriod(kyDanhGiaNum)
					const khoiID = this.getCurrentKhoiID()

					const payload = {
						NamHoc: namHocStr,
						KyDanhGia: kyDanhGiaNum
					}

					// Gọi song song 2 API thống kê đánh giá
					const [resMon, resNlpc] = await Promise.all([
						ajaxCALLPromise('psmark1/REPORT_GetThongKeDanhGia_TheoMon', payload).catch(err => {
							console.error('Lỗi gọi REPORT_GetThongKeDanhGia_TheoMon:', err)
							return null
						}),
						ajaxCALLPromise('psmark1/REPORT_GetThongKeDanhGia_TheoNangLucPhamChat', payload).catch(err => {
							console.error('Lỗi gọi REPORT_GetThongKeDanhGia_TheoNangLucPhamChat:', err)
							return null
						})
					])

					// Helper unwrap data từ response API (hỗ trợ cả mảng trực tiếp do ajaxCALLPromise bóc hoặc bọc qua .data/.Data)
					const unwrapApiData = (res) => {
						if (!res) return []
						if (typeof res === 'string') {
							try { res = JSON.parse(res) } catch (e) {}
						}
						if (Array.isArray(res)) return res
						if (Array.isArray(res?.data)) return res.data
						if (Array.isArray(res?.Data)) return res.Data
						return []
					}

					// 1. Ánh xạ và đổ dữ liệu vào Sheet 1 (Năng lực, phẩm chất)
					const nlpcRaw = unwrapApiData(resNlpc)
					if (nlpcRaw.length > 0) {
						// Nếu trả về multi-dataset [[...]] thì lấy mảng con đầu tiên
						const flatNlpc = Array.isArray(nlpcRaw[0]) ? nlpcRaw[0] : nlpcRaw
						// Tìm dòng tương ứng với Khối ID của lớp, hoặc fallback lấy dòng đầu tiên
						const rowNlpc = flatNlpc.find(r => Number(r?.KhoiID) === Number(khoiID)) || flatNlpc[0]
						if (rowNlpc && typeof rowNlpc === 'object') {
							// Định nghĩa thứ tự 15 trường khớp cấu trúc cột của Sheet 1:
							// 5 Phẩm chất: PC1 (Yêu nước), PC2 (Nhân ái), PC3 (Chăm chỉ), PC4 (Trung thực), PC5 (Trách nhiệm)
							// 10 Năng lực: NL1 đến NL10
							const pcKeys = ['PC1', 'PC2', 'PC3', 'PC4', 'PC5']
							const nlKeys = ['NL1', 'NL2', 'NL3', 'NL4', 'NL5', 'NL6', 'NL7', 'NL8', 'NL9', 'NL10']
							const allKeys = [...pcKeys, ...nlKeys]

							// Row 0: Tốt (T)
							const r0 = ['Tốt (T)']
							// Row 1: Đạt (Đ) / Hoàn thành
							const r1 = ['Đạt (Đ)']
							// Row 2: Cần cố gắng (C) / Chưa hoàn thành
							const r2 = ['Cần cố gắng (C)']

							allKeys.forEach(key => {
								// Tốt
								const totQty = rowNlpc[`${key}Tot`] ?? rowNlpc[`${key}TOT`] ?? rowNlpc[`${key}_Tot`] ?? ''
								const totRate = rowNlpc[`${key}TileTot`] ?? rowNlpc[`${key}TiLeTot`] ?? rowNlpc[`${key}_TileTot`] ?? ''
								r0.push(this.cleanSheetValue(totQty), this.cleanSheetValue(totRate))

								// Đạt / Hoàn thành
								const htQty = rowNlpc[`${key}HoanThanh`] ?? rowNlpc[`${key}Dat`] ?? rowNlpc[`${key}HT`] ?? ''
								const htRate = rowNlpc[`${key}TileHoanThanh`] ?? rowNlpc[`${key}TiLeHoanThanh`] ?? rowNlpc[`${key}TileDat`] ?? rowNlpc[`${key}TileHT`] ?? ''
								r1.push(this.cleanSheetValue(htQty), this.cleanSheetValue(htRate))

								// Cần cố gắng / Chưa hoàn thành
								const chtQty = rowNlpc[`${key}ChuaHoanThanh`] ?? rowNlpc[`${key}CanCoGang`] ?? rowNlpc[`${key}CHT`] ?? rowNlpc[`${key}CCG`] ?? ''
								const chtRate = rowNlpc[`${key}TileChuaHoanThanh`] ?? rowNlpc[`${key}TiLeChuaHoanThanh`] ?? rowNlpc[`${key}TileCanCoGang`] ?? rowNlpc[`${key}TileCHT`] ?? ''
								r2.push(this.cleanSheetValue(chtQty), this.cleanSheetValue(chtRate))
							})

							// Lưu vào bộ nhớ theo kỳ để lần chuyển kỳ hoặc lần render sau không làm mất số liệu.
							this.setPeriodSheetRows('Sheet1', [r0, r1, r2], kyDanhGiaNum)
							this.applyRowsToSheet(this.sheet1Instance, [r0, r1, r2], 'Sheet1')
						}
					}

					// 2. Ánh xạ và đổ dữ liệu vào Sheet 2 (Môn học và HĐGD)
					const monRaw = unwrapApiData(resMon)
					const mergedMon = {}
					if (monRaw.length > 0) {
						// resMon thường là mảng các bảng con (mỗi bảng 1 nhóm môn), gom lại dòng của khối tương ứng
						monRaw.forEach(item => {
							if (Array.isArray(item)) {
								const row = item.find(r => Number(r?.KhoiID) === Number(khoiID))
								if (row) Object.assign(mergedMon, row)
							} else if (item && typeof item === 'object') {
								if (Number(item.KhoiID) === Number(khoiID)) {
									Object.assign(mergedMon, item)
								}
							}
						})
						// Fallback nếu không khớp KhoiID thì lấy dòng đầu tiên
						if (Object.keys(mergedMon).length === 0) {
							const first = monRaw[0]
							if (Array.isArray(first) && first[0]) Object.assign(mergedMon, first[0])
							else if (first && typeof first === 'object') Object.assign(mergedMon, first)
						}
					}

					if (Object.keys(mergedMon).length > 0) {
						// Danh sách 11 môn theo thứ tự cột của Sheet 2:
						// Tiếng Việt (TV), Toán (Toan), Tiếng Anh (AV), Lịch sử & Địa lí (LD), Khoa học (KHTN),
						// Tin học - Công nghệ (kết hợp Tin & CNghe), Đạo đức (DD), Thể chất (TD), Âm nhạc (AN), Mĩ thuật (MT), HĐTN (TC)
						const r0 = ['Hoàn thành tốt (T)']
						const r1 = ['Hoàn thành (H)']
						const r2 = ['Chưa hoàn thành (C)']

						const appendMonCols = (prefix) => {
							// Hoàn thành tốt
							const totQty = mergedMon[`${prefix}Tot`] ?? mergedMon[`${prefix}TOT`] ?? mergedMon[`${prefix}_Tot`] ?? ''
							const totRate = mergedMon[`${prefix}TileTot`] ?? mergedMon[`${prefix}TiLeTot`] ?? mergedMon[`${prefix}_TileTot`] ?? ''
							r0.push(this.cleanSheetValue(totQty), this.cleanSheetValue(totRate))

							// Hoàn thành
							const htQty = mergedMon[`${prefix}HT`] ?? mergedMon[`${prefix}HoanThanh`] ?? mergedMon[`${prefix}_HT`] ?? ''
							const htRate = mergedMon[`${prefix}TileHT`] ?? mergedMon[`${prefix}TiLeHT`] ?? mergedMon[`${prefix}_TileHT`] ?? ''
							r1.push(this.cleanSheetValue(htQty), this.cleanSheetValue(htRate))

							// Chưa hoàn thành
							const chtQty = mergedMon[`${prefix}CHT`] ?? mergedMon[`${prefix}ChuaHoanThanh`] ?? mergedMon[`${prefix}_CHT`] ?? ''
							const chtRate = mergedMon[`${prefix}TileCHT`] ?? mergedMon[`${prefix}TiLeCHT`] ?? mergedMon[`${prefix}_TileCHT`] ?? ''
							r2.push(this.cleanSheetValue(chtQty), this.cleanSheetValue(chtRate))
						}

						// 1. Tiếng Việt
						appendMonCols('TV')
						// 2. Toán
						appendMonCols('Toan')
						// 3. Tiếng Anh
						appendMonCols('AV')
						// 4. Lịch sử & Địa lí
						appendMonCols('LD')
						// 5. Khoa học / Tự nhiên và Xã hội (API trả key KHTN: ứng với TNXH ở khối 1-3 và Khoa học ở khối 4-5)
						appendMonCols('KHTN')
						// 6. Tin học - Công nghệ (Ưu tiên lấy Tin học hoặc Công nghệ theo khối)
						const hasTin = mergedMon['TinTot'] !== undefined && mergedMon['TinTot'] !== 0
						const tinPrefix = hasTin ? 'Tin' : 'CNghe'
						appendMonCols(tinPrefix)
						// 7. Đạo đức
						appendMonCols('DD')
						// 8. Giáo dục thể chất (TD)
						appendMonCols('TD')
						// 9. Âm nhạc (AN)
						appendMonCols('AN')
						// 10. Mĩ thuật (MT)
						appendMonCols('MT')
						// 11. HĐTN / Tự chọn (TC)
						appendMonCols('TC')

						// Lưu vào bộ nhớ theo kỳ; khi bấm Lưu, getData() sẽ gom toàn bộ các kỳ vào JSON.
						this.setPeriodSheetRows('Sheet2', [r0, r1, r2], kyDanhGiaNum)
						this.applyRowsToSheet(this.sheet2Instance, [r0, r1, r2], 'Sheet2')
					}

					if (!options.quiet && typeof showMessage === 'function') {
						showMessage({ title: 'Đã tải và đổ số liệu đánh giá vào các bảng thành công. Vui lòng kiểm tra và bấm "Lưu" để lưu vào hệ thống!' })
					}
				} catch (error) {
					console.error('Lỗi nạp số liệu đánh giá:', error)
					if (!options.quiet && typeof showMessage === 'function') {
						showMessage({ title: 'Có lỗi xảy ra khi nạp dữ liệu đánh giá: ' + (error.message || error) })
					}
				} finally {
					this.syncLoading = false
				}
			},

			scrollToSection(item) {
				this.activeSection = item.key
				let container = this.$refs.scrollContainer
				if (Array.isArray(container)) container = container[0]
				container = container?.$el || container
				let target = this.$refs[item.refName]
				if (Array.isArray(target)) target = target[0]
				target = target?.$el || target
				if (!container || !target) return
				const nextTop = container.scrollTop
					+ target.getBoundingClientRect().top
					- container.getBoundingClientRect().top
					- 8
				container.scrollTo({ top: nextTop, behavior: 'smooth' })
			},
			getData() {
				// Sheet 1/2 được lưu theo kỳ; Sheet 3/4 và các textarea là dữ liệu tổng kết chung.
				this.captureCurrentPeriodSheetData()

				return {
					Form: { ...this.localForm },
					Sheet1: this.buildPeriodizedSheetData('Sheet1'),
					Sheet2: this.buildPeriodizedSheetData('Sheet2'),
					Sheet3: this.getSheetRows(this.sheet3Instance, 'Sheet3'),
					Sheet4: this.getSheetRows(this.sheet4Instance, 'Sheet4'),
					KyDanhGia: this.selectedKyDanhGia
				}
			},

			getStructuredRatings(allMonHoc = []) {
				const getSheetData = (inst, key) => this.getSheetRows(inst, key)

				const ratings = []

				// 1. Sheet 1: Năng lực phẩm chất
				const sheet1Rows = getSheetData(this.sheet1Instance, 'Sheet1')
				const fields1 = [
					{ name: 'Yêu nước', code: 'PC_YEU_NUOC', type: 'QUALITY' },
					{ name: 'Nhân ái', code: 'PC_NHAN_AI', type: 'QUALITY' },
					{ name: 'Chăm chỉ', code: 'PC_CHAM_CHI', type: 'QUALITY' },
					{ name: 'Trung thực', code: 'PC_TRUNG_THUC', type: 'QUALITY' },
					{ name: 'Trách nhiệm', code: 'PC_TRACH_NHIEM', type: 'QUALITY' },
					{ name: 'Tự chủ và tự học', code: 'NL_TU_CHU', type: 'QUALITY' },
					{ name: 'Giao tiếp và hợp tác', code: 'NL_GIAO_TIEP', type: 'QUALITY' },
					{ name: 'GQVĐ và sáng tạo', code: 'NL_GQVD', type: 'QUALITY' },
					{ name: 'Ngôn ngữ', code: 'NL_NGON_NGU', type: 'QUALITY' },
					{ name: 'Tính toán', code: 'NL_TINH_TOAN', type: 'QUALITY' },
					{ name: 'Khoa học', code: 'NL_KHOA_HOC', type: 'QUALITY' },
					{ name: 'Thẩm mĩ', code: 'NL_THAM_MI', type: 'QUALITY' },
					{ name: 'Thể chất', code: 'NL_THE_CHAT', type: 'QUALITY' },
					{ name: 'Công nghệ', code: 'NL_CONG_NGHE', type: 'QUALITY' },
					{ name: 'Tin học', code: 'NL_TIN_HOC', type: 'QUALITY' }
				]
				const sheet1RatingCodes = ['TOT', 'DAT', 'CAN_CO_GANG']
				sheet1Rows.forEach((row, ratingIdx) => {
					const ratingCode = sheet1RatingCodes[ratingIdx] || 'TOT'
					fields1.forEach((item, fIdx) => {
						const colIdx = 1 + (fIdx * 2)
						const qty = parseInt(row[colIdx]) || 0
						const rate = parseFloat(row[colIdx + 1]) || 0
						ratings.push({
							LoaiDanhGia: 'QUALITY',
							MonHocID: null,
							TieuChiCode: item.code,
							TenTieuChi: item.name,
							MucXepLoaiCode: ratingCode,
							SoLuong: qty,
							TiLe: rate
						})
					})
				})

				// 2. Sheet 2: Môn học và HĐGD
				const sheet2Rows = getSheetData(this.sheet2Instance, 'Sheet2')
				// Khối 1, 2, 3 học môn 'Tự nhiên và Xã hội' (MonHocID: 3)
				// Khối 4, 5 học môn 'Khoa học' (MonHocID: 4)
				const khoiID = this.getCurrentKhoiID()
				const isKhoi123 = khoiID <= 3
				const scienceSubjectName = isKhoi123 ? 'Tự nhiên và Xã hội' : 'Khoa học'
				const fields2 = [
					'Tiếng Việt', 'Toán', 'Tiếng Anh', 'Lịch sử & Địa lí', scienceSubjectName,
					'Tin học - Công nghệ', 'Đạo đức', 'Giáo dục thể chất', 'Âm nhạc', 'Mĩ thuật', 'HĐTN'
				]
				const sheet2RatingCodes = ['HT_TOT', 'HOAN_THANH', 'CHUA_HT']
				sheet2Rows.forEach((row, ratingIdx) => {
					const ratingCode = sheet2RatingCodes[ratingIdx] || 'HT_TOT'
					fields2.forEach((subName, subIdx) => {
						const colIdx = 1 + (subIdx * 2)
						const qty = parseInt(row[colIdx]) || 0
						const rate = parseFloat(row[colIdx + 1]) || 0

						// Tìm môn học trong danh mục môn học của LMS
						let foundMon = (allMonHoc || []).find(m => m.TenMonHoc_HienThi === subName || m.TenMonHoc === subName)
						// Fallback đặc biệt cho môn Khoa học (MonHocID: 4) / Tự nhiên và Xã hội (MonHocID: 3)
						let monHocId = foundMon ? foundMon.MonHocID : null
						if (!monHocId) {
							if (subName === 'Tự nhiên và Xã hội') {
								monHocId = 3
							} else if (subName === 'Khoa học') {
								monHocId = 4
							}
						}

						ratings.push({
							LoaiDanhGia: 'SUBJECT',
							MonHocID: monHocId,
							TieuChiCode: monHocId ? null : subName,
							TenTieuChi: subName,
							MucXepLoaiCode: ratingCode,
							SoLuong: qty,
							TiLe: rate
						})
					})
				})

				// 3. Sheet 3: Đánh giá kết quả giáo dục
				const sheet3Rows = getSheetData(this.sheet3Instance, 'Sheet3')
				const sheet3RatingCodes = ['HT_XUAT_SAC', 'HT_TOT', 'HOAN_THANH', 'CHUA_HT']
				sheet3Rows.forEach((row, rIdx) => {
					const ratingCode = sheet3RatingCodes[rIdx] || 'HOAN_THANH'
					ratings.push({
						LoaiDanhGia: 'KET_QUA_GD',
						MonHocID: null,
						TieuChiCode: 'KET_QUA_GD',
						TenTieuChi: row[0] || '',
						MucXepLoaiCode: ratingCode,
						SoLuong: parseInt(row[1]) || 0,
						TiLe: parseFloat(row[2]) || 0
					})
				})

				// 4. Sheet 4: Khen thưởng
				const sheet4Rows = getSheetData(this.sheet4Instance, 'Sheet4')
				sheet4Rows.forEach((row, rIdx) => {
					ratings.push({
						LoaiDanhGia: 'KHEN_THUONG',
						MonHocID: null,
						TieuChiCode: `KHEN_THUONG_${rIdx + 1}`,
						TenTieuChi: row[0] || '',
						MucXepLoaiCode: `KHEN_THUONG_${rIdx + 1}`,
						SoLuong: parseInt(row[1]) || 0,
						TiLe: parseFloat(row[2]) || 0
					})
				})

				return ratings
			},

			destroyAllSheets() {
				[this.sheet1Instance, this.sheet2Instance, this.sheet3Instance, this.sheet4Instance].forEach(inst => {
					if (!inst) return
					try {
						const sheet = Array.isArray(inst) ? inst[0] : inst
						if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
					} catch (e) {}
				})
				this.sheet1Instance = null
				this.sheet2Instance = null
				this.sheet3Instance = null
				this.sheet4Instance = null
				const sheetRefs = ['sheetRef1', 'sheetRef2', 'sheetRef3', 'sheetRef4']
				sheetRefs.forEach(refName => {
					let container = this.$refs[refName]
					if (Array.isArray(container)) container = container[0]
					if (!container) return
					try {
						if (typeof jspreadsheet !== 'undefined' && typeof jspreadsheet.destroy === 'function') {
							jspreadsheet.destroy(container)
						}
					} catch (error) {}
					container.innerHTML = ''
				})
			},

			initAllSheets() {
				if (this.selectedLopID === '__ALL__') {
					this.destroyAllSheets()
					return
				}
				if (this.isMobileViewport) {
					this.destroyAllSheets()
					['Sheet1', 'Sheet2', 'Sheet3', 'Sheet4'].forEach(key => {
						const rows = this.getInitialMobileRows(key)
						this.mobileSheetRows[key] = this.cloneSheetRows(rows)
						this.$refs['mobileSummary_' + key]?.setRows?.(rows)
					})
					return
				}
				// Desktop keeps JSpreadsheet; mobile uses native inputs with the same saved row shapes.
				this.$nextTick(() => {
					this.destroyAllSheets()

					// Sheet 1: Năng lực, phẩm chất
					if (this.$refs.sheetRef1 && typeof jspreadsheet === 'function') {
						const savedSheet1 = this.getPeriodSheetRows('Sheet1')
						const defaultSheet1Data = this.buildSheet1Rows(savedSheet1)

						const cols1 = [{ title: 'Xếp loại', width: 150, readOnly: true }]
						const fields1 = [
							'Yêu nước', 'Nhân ái', 'Chăm chỉ', 'Trung thực', 'Trách nhiệm',
							'Tự chủ và tự học', 'Giao tiếp và hợp tác', 'GQVĐ và sáng tạo',
							'Ngôn ngữ', 'Tính toán', 'Khoa học', 'Thẩm mĩ', 'Thể chất', 'Công nghệ', 'Tin học'
						]
						fields1.forEach(() => {
							cols1.push({ title: 'SỐ LƯỢNG', width: 95, align: 'center', type: 'numeric' })
							cols1.push({ title: 'TỈ LỆ', width: 85, align: 'center', type: 'numeric' })
						})

						const nested1 = [
							[
								{ title: '', colspan: 1 },
								{ title: 'Phẩm chất', colspan: 10 },
								{ title: 'Năng lực', colspan: 20 }
							],
							[
								{ title: '', colspan: 1 },
								...fields1.map(f => ({ title: f, colspan: 2 }))
							]
						]

						this.sheet1Instance = soGvcnJspreadsheet.create(this.$refs.sheetRef1, {
							worksheets: [{
								data: defaultSheet1Data,
								columns: cols1,
								nestedHeaders: nested1,
								tableOverflow: true,
								tableWidth: '100%',
								tableHeight: this.getContentTableHeight(this.$refs.sheetRef1, defaultSheet1Data.length, nested1.length),
								freezeColumns: 1,
								wordWrap: true,
								allowInsertRow: false,
								allowDeleteRow: false,
								allowInsertColumn: false,
								allowDeleteColumn: false
							}],
							contextMenu: () => false
						})
					}

					// Sheet 2: Môn học và hoạt động giáo dục
					if (this.$refs.sheetRef2 && typeof jspreadsheet === 'function') {
						const savedSheet2 = this.getPeriodSheetRows('Sheet2')
						const defaultSheet2Data = this.buildSheet2Rows(savedSheet2)

						const cols2 = [{ title: 'Xếp loại', width: 150, readOnly: true }]
						// Khối 1, 2, 3 học Tự nhiên và Xã hội; Khối 4, 5 học Khoa học
						const isKhoi123 = this.getCurrentKhoiID() <= 3
						const scienceSubjectName = isKhoi123 ? 'Tự nhiên và Xã hội' : 'Khoa học'
						const fields2 = [
							'Tiếng Việt', 'Toán', 'Tiếng Anh', 'Lịch sử & Địa lí', scienceSubjectName,
							'Tin học - Công nghệ', 'Đạo đức', 'Giáo dục thể chất', 'Âm nhạc', 'Mĩ thuật', 'HĐTN'
						]
						fields2.forEach(() => {
							cols2.push({ title: 'SỐ LƯỢNG', width: 95, align: 'center', type: 'numeric' })
							cols2.push({ title: 'TỈ LỆ', width: 85, align: 'center', type: 'numeric' })
						})

						const nested2 = [
							[
								{ title: '', colspan: 1 },
								{ title: 'Môn học và hoạt động giáo dục', colspan: 22 }
							],
							[
								{ title: '', colspan: 1 },
								...fields2.map(f => ({ title: f, colspan: 2 }))
							]
						]

						this.sheet2Instance = soGvcnJspreadsheet.create(this.$refs.sheetRef2, {
							worksheets: [{
								data: defaultSheet2Data,
								columns: cols2,
								nestedHeaders: nested2,
								tableOverflow: true,
								tableWidth: '100%',
								tableHeight: this.getContentTableHeight(this.$refs.sheetRef2, defaultSheet2Data.length, nested2.length),
								freezeColumns: 1,
								wordWrap: true,
								allowInsertRow: false,
								allowDeleteRow: false,
								allowInsertColumn: false,
								allowDeleteColumn: false
							}],
							contextMenu: () => false
						})
					}

					// Sheet 3: Đánh giá kết quả giáo dục
					if (this.$refs.sheetRef3 && typeof jspreadsheet === 'function') {
						const savedSheet3 = this.mobileSheetRows.Sheet3 || this.savedData?.Sheet3 || []
						const defaultSheet3Data = savedSheet3.length ? savedSheet3 : [
							['Hoàn thành xuất sắc', savedSheet3[0]?.[1]||'', savedSheet3[0]?.[2]||''],
							['Hoàn thành tốt', savedSheet3[1]?.[1]||'', savedSheet3[1]?.[2]||''],
							['Hoàn thành', savedSheet3[2]?.[1]||'', savedSheet3[2]?.[2]||''],
							['Chưa hoàn thành', savedSheet3[3]?.[1]||'', savedSheet3[3]?.[2]||'']
						]

						this.sheet3Instance = soGvcnJspreadsheet.create(this.$refs.sheetRef3, {
							worksheets: [{
								data: defaultSheet3Data,
								columns: [
									{ title: 'Xếp loại', width: 180, readOnly: true },
									{ title: 'SỐ LƯỢNG', width: 95, align: 'center', type: 'numeric' },
									{ title: 'TỈ LỆ', width: 85, align: 'center', type: 'numeric' }
								],
								tableOverflow: true,
								tableWidth: '100%',
								tableHeight: this.getContentTableHeight(this.$refs.sheetRef3, defaultSheet3Data.length),
								freezeColumns: 1,
								wordWrap: true,
								rowResize: true,
								allowInsertRow: false,
								allowDeleteRow: false,
								allowInsertColumn: false,
								allowDeleteColumn: false
							}],
							contextMenu: () => false
						})
					}

					// Sheet 4: Khen thưởng
					if (this.$refs.sheetRef4 && typeof jspreadsheet === 'function') {
						const savedSheet4 = this.mobileSheetRows.Sheet4 || this.savedData?.Sheet4 || []
						const defaultSheet4Data = savedSheet4.length ? savedSheet4 : [
							['Học sinh Xuất sắc', savedSheet4[0]?.[1]||'', savedSheet4[0]?.[2]||''],
							['Học sinh tiêu biểu hoàn thành tốt trong học tập và rèn luyện', savedSheet4[1]?.[1]||'', savedSheet4[1]?.[2]||'']
						]

						this.sheet4Instance = soGvcnJspreadsheet.create(this.$refs.sheetRef4, {
							worksheets: [{
								data: defaultSheet4Data,
								columns: [
									{ title: 'Danh hiệu', width: 320, readOnly: true },
									{ title: 'SỐ LƯỢNG', width: 95, align: 'center', type: 'numeric' },
									{ title: 'TỈ LỆ', width: 85, align: 'center', type: 'numeric' }
								],
								tableOverflow: true,
								tableWidth: '100%',
								tableHeight: this.getContentTableHeight(this.$refs.sheetRef4, defaultSheet4Data.length),
								freezeColumns: 1,
								wordWrap: true,
								rowResize: true,
								allowInsertRow: false,
								allowDeleteRow: false,
								allowInsertColumn: false,
								allowDeleteColumn: false
							}],
							contextMenu: () => false
						})
					}
				})
			}
		}
	}
</script>