<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title>
					{{ TitlePage }}
				</v-card-title>
				<v-card-text>
					<v-row align="center">
						<v-col>
							<v-select v-model="CapID" label="Chọn cấp học" :items="DSCap" item-title="title"
								item-value="value" />
						</v-col>
						<v-col>
							<uc-date-range-picker v-model="dateRange" :NienKhoa="vueData.NienKhoa" />
							<v-btn color="success" variant="tonal" prepend-icon="mdi-microsoft-excel" @click="onExport">
								Xuất Excel
							</v-btn>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<!-- Tabs -->
		<v-card rounded="0" elevation="0" border="0">
			<v-tabs v-model="tab" color="primary" density="comfortable">
				<v-tab :value="0">
					<v-icon start size="16">mdi-bookshelf</v-icon>
					Học liệu số
				</v-tab>
				<v-tab :value="1">
					<v-icon start size="16">mdi-school-outline</v-icon>
					LMS
				</v-tab>
			</v-tabs>

			<v-divider />

			<v-tabs-window v-model="tab">
				<v-tabs-window-item :value="0" :key="0" :eager="true">
					<uc-hoc-lieu-so ref="refHocLieuSo" :CapID :NienKhoa="vueData.NienKhoa" :NgayBatDau="dateRange.from"
						:NgayKetThuc="dateRange.to" />
				</v-tabs-window-item>
				<v-tabs-window-item :value="1" :key="1" :eager="true">
					<uc-lms ref="refLms" :CapID :NienKhoa="vueData.NienKhoa" :NgayBatDau="dateRange.from" :NgayKetThuc="dateRange.to" />
				</v-tabs-window-item>
			</v-tabs-window>
		</v-card>

	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef'],
	props: [],
	data() {
		const nienKhoa = Number(vueData.NienKhoa) || new Date().getFullYear()
		return {
			vueData,
			tab: 0,
			CapID: null,
			DSCap: [
				{ title: 'Cấp 1', value: 1 },
				{ title: 'Cấp 2', value: 2 },
				{ title: 'Cấp 3', value: 3 },
			],
			dateRange: {
				// Mặc định toàn bộ năm học; khoảng ngày chỉ là bộ lọc phụ.
				from: `${nienKhoa}-08-01`,
				to: `${nienKhoa + 1}-05-31`,
			},
		}
	},
	watch: {
		'vueData.NienKhoa'(value, oldValue) {
			if (value && value !== oldValue) this.dateRange = this.getAcademicYearRange(value)
		},
	},
	computed: {
		TitlePage() {
			return getTitlePageByURL(window.location.pathname + window.location.search)
		},
	},
	methods: {
		getAcademicYearRange(nienKhoa) {
			const year = Number(nienKhoa)
			return Number.isFinite(year) && year > 0
				? { from: `${year}-08-01`, to: `${year + 1}-05-31` }
				: { from: null, to: null }
		},
		// 'YYYY-MM-DD' → 'dd/MM/yyyy'
		formatDate(iso) {
			if (!iso) return ''
			const [y, m, d] = iso.split('-')
			return `${d}/${m}/${y}`
		},
		// 'YYYY-MM-DD' → 'ddMMyyyy'  (dùng trong tên file)
		formatDateFile(iso) {
			if (!iso) return ''
			const [y, m, d] = iso.split('-')
			return `${d}${m}${y}`
		},

		onExport() {
			const hocLieuRef = this.$refs.refHocLieuSo
			const lmsRef = this.$refs.refLms

			// Excel phải xuất đúng phạm vi khối đang chọn trên bảng, không lấy lại toàn bộ dữ liệu của cấp học.
			const items = hocLieuRef?.filteredItems ?? hocLieuRef?.items ?? []
			const teacherActivityOverview = hocLieuRef?.teacherActivityOverview ?? []
			const teacherActivityKhoi = hocLieuRef?.activeKhoi ?? 0
			const dataTong = lmsRef?.dataTong ?? []
			const dataBaiHoc = lmsRef?.dataBaiHoc ?? []
			const dataBaiTap = lmsRef?.dataBaiTap ?? []

			const capLabel = this.DSCap.find(c => c.value === this.CapID)?.title ?? ''
			const nienKhoa = vueData.NienKhoa ?? ''
			const hasRange = this.dateRange.from && this.dateRange.to

			// Tiêu đề dùng trong sheet
			const rangeLabel = hasRange
				? `${this.formatDate(this.dateRange.from)} - ${this.formatDate(this.dateRange.to)}`
				: `Năm học ${nienKhoa}`

			// Tên file
			const dateStr = hasRange
				? `${this.formatDateFile(this.dateRange.from)}_${this.formatDateFile(this.dateRange.to)}`
				: nienKhoa

			// 3 dòng thông tin chèn đầu mỗi sheet (sau tiêu đề):
			// Row 2: Cấp học / Khoảng thời gian
			// Row 3: Từ ngày / Đến ngày
			// Row 4: (trắng)
			// → Header cột luôn ở Row 5, data luôn bắt đầu từ Row 6
			const infoRows = [
				['Cấp học:', capLabel, '', 'Khoảng thời gian:', rangeLabel],
				['Từ ngày:', hasRange ? this.formatDate(this.dateRange.from) : '(tất cả)',
					'', 'Đến ngày:', hasRange ? this.formatDate(this.dateRange.to) : '(tất cả)'],
				[],
			]
			// Excel row của dòng data đầu tiên (1-based):
			// Row1=tiêu đề, Row2+3+4=infoRows(3), Row5=header → Row 6 = data bắt đầu
			const DATA_START = 6

			const wb = XLSX.utils.book_new()
			const makeSheet = (aoaData, colWidths) => {
				const ws = XLSX.utils.aoa_to_sheet(aoaData)
				ws['!cols'] = colWidths.map(w => ({ wch: w }))
				return ws
			}

			// ── SHEET 1: Học liệu số ─────────────────────────────────────
			// Cấu trúc riêng: sau header thông tin còn có 2 dòng KPI + 1 dòng trắng.
			// Row 5: tổng học liệu, tổng nội dung, nội dung trong kỳ, có/chưa nội dung
			// Row 6: các giá trị KPI tương ứng
			// Row 7: []
			// Row 8: tổng học liệu, số có/chưa nội dung, tổng node, node trong kỳ và trạng thái.
			// Row 9+ : data items
			// Row 9+n: Tổng cộng
			// API trả dữ liệu đã gộp theo môn/khối; Excel phải cộng các trường tổng hợp,
			// không đếm số dòng kết quả.
			const total = items.reduce((sum, i) => sum + Number(i.TongHocLieu ?? 0), 0)
			const hasNd = items.reduce((sum, i) => sum + Number(i.HocLieuCoNoiDung ?? 0), 0)
			const noNd = items.reduce((sum, i) => sum + Number(i.HocLieuChuaCoNoiDung ?? 0), 0)
			const totalContent = items.reduce((sum, i) => sum + Number(i.TongNoiDung ?? 0), 0)
			const totalContentInRange = items.reduce((sum, i) => sum + Number(i.TongNoiDungTrongKhoang ?? 0), 0)
			const hocLieuScopeLabel = teacherActivityKhoi === 0 ? capLabel : `${capLabel} – Khối ${teacherActivityKhoi}`
			const HL_DATA_START = 9   // data chi tiết bắt đầu từ Excel row 9
			const HL_DATA_END = HL_DATA_START + items.length - 1
			const aoa1 = [
				[`BÁO CÁO HỌC LIỆU SỐ – ${hocLieuScopeLabel} – ${rangeLabel}`],  // row 1
				...infoRows,                                                // row 2,3,4
				['Tổng học liệu', 'Tổng nội dung học liệu', 'Nội dung trong khoảng thời gian đang lọc', 'Có nội dung', 'Chưa có nội dung'], // row 5
				[total, totalContent, totalContentInRange, hasNd, noNd],      // row 6
				[],                                                         // row 7
				['Khối', 'Môn học', 'Tổng học liệu', 'Có nội dung', 'Chưa có', 'Tổng nội dung học liệu', 'Nội dung trong khoảng thời gian đang lọc', 'Trạng thái'], // row 8
				...items.map(i => [                                         // row 9+
					`Khối ${i.KhoiID}`,
					i.TenMonHoc_HienThi,
					Number(i.TongHocLieu ?? 0),
					Number(i.HocLieuCoNoiDung ?? 0),
					Number(i.HocLieuChuaCoNoiDung ?? 0),
					Number(i.TongNoiDung ?? 0),
					Number(i.TongNoiDungTrongKhoang ?? 0),
					Number(i.TongNoiDung ?? 0) > 0 ? 'Có nội dung' : 'Chưa có',
				]),
				[                                                           // row 9+n
					'Tổng cộng',
					`${total} học liệu`,
					{ f: `SUM(C${HL_DATA_START}:C${HL_DATA_END})` },
					{ f: `SUM(D${HL_DATA_START}:D${HL_DATA_END})` },
					{ f: `SUM(E${HL_DATA_START}:E${HL_DATA_END})` },
					{ f: `SUM(F${HL_DATA_START}:F${HL_DATA_END})` },
					{ f: `SUM(G${HL_DATA_START}:G${HL_DATA_END})` },
					`${hasNd} có / ${noNd} chưa`,
				],
			]
			XLSX.utils.book_append_sheet(wb, makeSheet(aoa1, [12, 30, 14, 14, 14, 22, 34, 20]), 'Học liệu số')

			// ── SHEET 2: Giáo viên thao tác học liệu ────────────────────────
			// Đặt ngay sau sheet Học liệu số để nhóm các báo cáo liên quan đến học liệu cạnh nhau.
			// Dùng đúng computed đang hiển thị trên bảng ngoài: chọn "Tất cả" sẽ gộp toàn khối,
			// chọn một khối sẽ xuất đúng danh sách giáo viên của khối đó.
			const teacherScopeLabel = teacherActivityKhoi === 0 ? 'Tất cả khối' : `Khối ${teacherActivityKhoi}`
			const GV_DATA_START = DATA_START
			const GV_DATA_END = GV_DATA_START + teacherActivityOverview.length - 1
			const teacherSum = (field) => teacherActivityOverview.length
				? { f: `SUM(${field}${GV_DATA_START}:${field}${GV_DATA_END})` }
				: 0
			const aoa5 = [
				[`GIÁO VIÊN THAO TÁC HỌC LIỆU – ${capLabel} – ${teacherScopeLabel} – ${rangeLabel}`],
				...infoRows,
				['Giáo viên', 'Đã thêm', 'Đã cập nhật', 'Tạo mục', 'Tạo tài liệu', 'Tạo câu hỏi'],
				...teacherActivityOverview.map(row => [
					row.TenGiaoVien,
					row.SoMucThem ?? 0,
					row.SoMucCapNhat ?? 0,
					row.SoCauTruc ?? 0,
					row.SoHocLieu ?? 0,
					row.SoCauHoi ?? 0,
				]),
				[
					'Tổng cộng',
					teacherSum('B'),
					teacherSum('C'),
					teacherSum('D'),
					teacherSum('E'),
					teacherSum('F'),
				],
			]
			XLSX.utils.book_append_sheet(wb, makeSheet(aoa5, [30, 14, 16, 12, 16, 14]), 'GV thao tác học liệu')

			// ── SHEET 3: LMS Tổng quan ───────────────────────────────────
			// Row 1: tiêu đề | Row 2,3,4: info | Row 5: header | Row 6+: data
			const T_DATA_END = DATA_START + dataTong.length - 1
			const T_SUM_ROW = DATA_START + dataTong.length
			const aoa2 = [
				[`LMS – TỔNG QUAN THEO MÔN – ${capLabel} – ${rangeLabel}`],  // row 1
				...infoRows,                                                   // row 2,3,4
					// Thứ tự cột phải thống nhất với bảng LMS trên màn hình: tổng, chưa giao, đã giao.
					['STT', 'Môn học', 'Tổng bài học', 'Chưa giao bài học', 'Đã giao bài học',
						'Tổng bài tập', 'Chưa giao bài tập', 'Đã giao bài tập'],   // row 5
					...dataTong.map((r, i) => [                                    // row 6+
						i + 1, r.TenMonHoc_HienThi,
						r.TotalLessons ?? 0, r.UnassignedLessons ?? 0, r.AssignedLessons ?? 0,
						r.TotalAssignments ?? 0, r.UnassignedAssignments ?? 0, r.AssignedAssignments ?? 0,
					]),
				[                                                              // row 6+n
					'', 'Tổng cộng',
						{ f: `SUM(C${DATA_START}:C${T_DATA_END})` },
						{ f: `SUM(D${DATA_START}:D${T_DATA_END})` },
						{ f: `SUM(E${DATA_START}:E${T_DATA_END})` },
						{ f: `SUM(F${DATA_START}:F${T_DATA_END})` },
						{ f: `SUM(G${DATA_START}:G${T_DATA_END})` },
						{ f: `SUM(H${DATA_START}:H${T_DATA_END})` },
					],
				]
				XLSX.utils.book_append_sheet(wb, makeSheet(aoa2, [6, 30, 16, 16, 18, 16, 16, 18]), 'LMS - Tổng quan')

			// ── SHEET 4: LMS Bài học ─────────────────────────────────────
			// Row 1: tiêu đề | Row 2,3,4: info | Row 5: header | Row 6+: data
			const BH_DATA_END = DATA_START + dataBaiHoc.length - 1
			const BH_SUM_ROW = DATA_START + dataBaiHoc.length
			const aoa3 = [
				[`LMS – CHI TIẾT BÀI HỌC – ${capLabel} – ${rangeLabel}`],    // row 1
				...infoRows,                                                   // row 2,3,4
					// Các cột kết quả bên phải chỉ phản ánh bài học đã giao; bài chưa giao
					// vẫn được thống kê ở nhóm cột đầu nhưng không làm tăng mẫu số tiến độ.
					['STT', 'Môn học', 'Tổng bài học', 'Chưa giao', 'Đã giao',
						'Lượt học (bài đã giao)', 'HS hoàn thành (bài đã giao)', 'Tỉ lệ (%)', 'Đánh giá'],
				...dataBaiHoc.map((r, i) => {                                  // row 6+
					const rate = r.CompletionRate_Lessons ?? 0
					return [
						i + 1, r.TenMonHoc_HienThi,
							r.TotalLessons ?? 0, r.UnassignedLessons ?? 0, r.AssignedLessons ?? 0,
							r.TotalProgress ?? 0, r.TotalCompleted ?? 0,
							rate / 100,
						rate >= 80 ? 'Tốt' : rate >= 50 ? 'Trung bình' : 'Thấp',
					]
				}),
				[                                                              // row 6+n
					'', 'Tổng cộng',
					{ f: `SUM(C${DATA_START}:C${BH_DATA_END})` },
						{ f: `SUM(D${DATA_START}:D${BH_DATA_END})` },
						{ f: `SUM(E${DATA_START}:E${BH_DATA_END})` },
						{ f: `SUM(F${DATA_START}:F${BH_DATA_END})` },
						{ f: `SUM(G${DATA_START}:G${BH_DATA_END})` },
						{ f: `IFERROR(G${BH_SUM_ROW}/F${BH_SUM_ROW},0)` },
						'Tỉ lệ TB',
					],
				]
				const ws3 = makeSheet(aoa3, [6, 30, 15, 15, 17, 14, 16, 14, 14])
				// Format % cột H (index 7) cho các dòng data
				dataBaiHoc.forEach((_, i) => {
					const addr = XLSX.utils.encode_cell({ r: DATA_START - 1 + i, c: 7 })
				if (ws3[addr]) ws3[addr].z = '0.0%'
			})
			XLSX.utils.book_append_sheet(wb, ws3, 'LMS - Bài học')

			// ── SHEET 5: LMS Bài tập ─────────────────────────────────────
			// Row 1: tiêu đề | Row 2,3,4: info | Row 5: header | Row 6+: data
			const BT_DATA_END = DATA_START + dataBaiTap.length - 1
			const BT_SUM_ROW = DATA_START + dataBaiTap.length
			const aoa4 = [
				[`LMS – CHI TIẾT BÀI TẬP – ${capLabel} – ${rangeLabel}`],    // row 1
				...infoRows,                                                   // row 2,3,4
					// Trạng thái và các tỉ lệ bên phải chỉ tính trên bài tập đã giao.
					['STT', 'Môn học', 'Tổng bài tập', 'Chưa giao', 'Đã giao',
						'HS được giao (bài đã giao)', 'Chưa làm', 'Đang làm', 'Đã nộp / chấm nháp', 'Đã chấm',
						'Tỉ lệ nộp (%)', 'Tỉ lệ chấm (%)', 'Đánh giá'],
				...dataBaiTap.map((r, i) => {                                  // row 6+
					const rateNop = r.CompletionRate_Assignments ?? 0
					const rateCham = r.CompletionRate_Graded ?? 0
					return [
						i + 1, r.TenMonHoc_HienThi,
							r.TotalAssignments ?? 0, r.UnassignedAssignments ?? 0, r.AssignedAssignments ?? 0,
							r.TotalAssigned ?? 0, r.Total_ChuaLam ?? 0, r.Total_DangLam ?? 0,
							r.Total_DaNop ?? 0, r.Total_DaCham ?? 0,
						rateNop / 100, rateCham / 100,
						rateNop >= 80 ? 'Tốt' : rateNop >= 50 ? 'Trung bình' : 'Thấp',
					]
				}),
				[                                                              // row 6+n
					'', 'Tổng cộng',
					{ f: `SUM(C${DATA_START}:C${BT_DATA_END})` },
						{ f: `SUM(D${DATA_START}:D${BT_DATA_END})` },
						{ f: `SUM(E${DATA_START}:E${BT_DATA_END})` },
						{ f: `SUM(F${DATA_START}:F${BT_DATA_END})` },
						{ f: `SUM(G${DATA_START}:G${BT_DATA_END})` },
						{ f: `SUM(H${DATA_START}:H${BT_DATA_END})` },
						{ f: `SUM(I${DATA_START}:I${BT_DATA_END})` },
						{ f: `SUM(J${DATA_START}:J${BT_DATA_END})` },
						{ f: `IFERROR((I${BT_SUM_ROW}+J${BT_SUM_ROW})/F${BT_SUM_ROW},0)` },
						{ f: `IFERROR(J${BT_SUM_ROW}/F${BT_SUM_ROW},0)` },
						'Tỉ lệ TB',
					],
				]
				const ws4 = makeSheet(aoa4, [6, 30, 15, 15, 17, 16, 12, 12, 12, 12, 14, 14, 14])
				// Format % cột K,L (index 10,11) cho các dòng data
				dataBaiTap.forEach((_, i) => {
					;[10, 11].forEach(col => {
					const addr = XLSX.utils.encode_cell({ r: DATA_START - 1 + i, c: col })
					if (ws4[addr]) ws4[addr].z = '0.0%'
				})
			})
			// Dòng tổng cũng phải dùng format phần trăm; nếu thiếu, Excel sẽ hiển thị số thập phân dài.
				;['K' + BT_SUM_ROW, 'L' + BT_SUM_ROW].forEach(addr => {
				if (ws4[addr]) ws4[addr].z = '0.0%'
			})
			XLSX.utils.book_append_sheet(wb, ws4, 'LMS - Bài tập')

			// ── Xuất file ────────────────────────────────────────────────
			const capStr = capLabel.replace(/\s/g, '_')
			XLSX.writeFile(wb, `BaoCao_HocLieuSo_LMS_${capStr}_${dateStr}.xlsx`)
		},
	},
	}
</script>