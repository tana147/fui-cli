<template>
	<Global>
		<v-card class="elevation-1">
			<!-- ===== TIÊU ĐỀ & TOOLBAR ===== -->
			<v-card-title class="d-flex align-center flex-wrap ga-2 py-3 px-4 bg-light-blue-lighten-5">
				<v-icon color="primary" class="mr-2">mdi-chart-box-outline</v-icon>
				<span class="text-h6 font-weight-bold text-primary">BÁO CÁO TIẾN ĐỘ NHẬP NHẬN XÉT CẤP 1</span>
				<v-spacer />
				<v-btn color="primary" :loading="isLoading" prepend-icon="mdi-magnify" @click="onSearch">
					Xem báo cáo
				</v-btn>
				<v-btn color="success" variant="tonal" :disabled="!hasData || isLoading" prepend-icon="mdi-file-excel" @click="onExportExcel">
					Xuất Excel
				</v-btn>
			</v-card-title>

		<v-divider />

		<!-- ===== BỘ LỌC DỮ LIỆU ===== -->
		<v-card-text class="py-3">
			<v-row dense align="center">
				<!-- Chọn niên khóa -->
				<v-col cols="12" sm="3" md="2">
					<v-select
						v-model="NienKhoa"
						label="Niên khóa"
						:items="DSNienKhoa"
						item-title="title"
						item-value="value"
						density="compact"
						variant="outlined"
						hide-details
						@update:model-value="onNienKhoaChange"
					/>
				</v-col>

				<!-- Chọn khối cấp 1 -->
				<v-col cols="12" sm="3" md="2">
					<v-select
						v-model="KhoiID"
						label="Khối"
						:items="DSKhoi"
						item-title="TenKhoiHoc"
						item-value="KhoiID"
						:loading="isLoadingKhoi"
						clearable
						density="compact"
						variant="outlined"
						hide-details
						@update:model-value="onSearch"
					/>
				</v-col>

				<!-- Chọn tab nghiệp vụ -->
				<v-col cols="12" sm="4" md="3">
					<v-select
						v-model="loaiBaoCao"
						label="Loại nhận xét"
						:items="DSLoaiBaoCao"
						item-title="title"
						item-value="value"
						density="compact"
						variant="outlined"
						hide-details
						@update:model-value="onSearch"
					/>
				</v-col>

				<!-- Bộ lọc động theo loại nhận xét: Tháng -->
				<v-col v-if="loaiBaoCao === 'thang'" cols="12" sm="3" md="2">
					<v-select
						v-model="Thang"
						label="Tháng"
						:items="DSThang"
						item-title="label"
						item-value="value"
						density="compact"
						variant="outlined"
						hide-details
						@update:model-value="onSearch"
					/>
				</v-col>

				<!-- Bộ lọc động theo loại nhận xét: Học kì / Đợt đánh giá -->
				<v-col v-else cols="12" sm="3" md="2">
					<v-select
						v-model="HocKy"
						label="Đợt đánh giá"
						:items="DSHocKy"
						item-title="label"
						item-value="value"
						density="compact"
						variant="outlined"
						hide-details
						@update:model-value="onSearch"
					/>
				</v-col>

				<!-- Chọn phân nhóm môn / PCNL cho tab học kì -->
				<v-col v-if="loaiBaoCao === 'hoc-ky'" cols="12" sm="4" md="3">
					<v-select
						v-model="nhomMonHocKy"
						label="Nhóm môn / Đánh giá"
						:items="DSNhomMonHocKy"
						item-title="title"
						item-value="value"
						density="compact"
						variant="outlined"
						hide-details
						@update:model-value="onSearch"
					/>
				</v-col>
			</v-row>
		</v-card-text>

		<!-- ===== ALERT BÁO LỖI ===== -->
		<v-card-text v-if="errorMessage" class="pt-0">
			<v-alert type="error" variant="tonal" density="compact" closable @click:close="errorMessage = ''">
				{{ errorMessage }}
			</v-alert>
		</v-card-text>

		<v-divider />

		<!-- ===== NỘI DUNG HIỂN THỊ ===== -->
		<v-card-text>
			<!-- Trạng thái đang tải -->
			<div v-if="isLoading" class="text-center pa-10">
				<v-progress-circular indeterminate color="primary" size="48" />
				<div class="text-body-2 mt-3 text-grey-darken-1">Đang tổng hợp dữ liệu nhận xét...</div>
			</div>

			<!-- Chưa có dữ liệu -->
			<v-alert v-else-if="!hasData" type="info" variant="tonal" class="my-3">
				Vui lòng chọn <strong>Khối</strong> để xem báo cáo tiến độ nhận xét.
			</v-alert>

			<!-- ĐÃ CÓ DỮ LIỆU -->
			<div v-else>
				<!-- ========================================== -->
				<!-- 1. BIỂU ĐỒ & DASHBOARD TỔNG HỢP TIẾN ĐỘ   -->
				<!-- ========================================== -->
				<v-row dense class="mb-4" align="stretch">
					<!-- Card Tổng số lớp -->
					<v-col cols="12" sm="6" md="3">
						<v-card variant="tonal" color="primary" class="pa-3 h-100 d-flex flex-column justify-space-between">
							<div class="d-flex justify-space-between align-center">
								<div>
									<div class="text-caption text-uppercase font-weight-bold">Tổng số lớp</div>
									<div class="text-h4 font-weight-bold my-1">{{ currentTableData.length }}</div>
								</div>
								<v-icon size="36" color="primary">mdi-google-classroom</v-icon>
							</div>
							<div class="text-caption font-weight-medium text-primary">
								{{ KhoiID ? `Đang lọc Khối ${KhoiID}` : 'Toàn trường Tiểu học' }}
							</div>
						</v-card>
					</v-col>

					<!-- Card Tổng số học sinh -->
					<v-col cols="12" sm="6" md="3">
						<v-card variant="tonal" color="info" class="pa-3 h-100 d-flex flex-column justify-space-between">
							<div class="d-flex justify-space-between align-center">
								<div>
									<div class="text-caption text-uppercase font-weight-bold">Tổng số HS</div>
									<div class="text-h4 font-weight-bold my-1">{{ tongSoHocSinh }}</div>
								</div>
								<v-icon size="36" color="info">mdi-account-group</v-icon>
							</div>
							<div class="text-caption font-weight-medium text-info">
								{{ currentTableData.length > 0 ? `TB ~${Math.round(tongSoHocSinh / currentTableData.length)} HS/lớp` : '0 HS' }}
							</div>
						</v-card>
					</v-col>

					<!-- Card Số HS đã nhận xét -->
					<v-col cols="12" sm="6" md="3">
						<v-card variant="tonal" color="success" class="pa-3 h-100 d-flex flex-column justify-space-between">
							<div class="d-flex justify-space-between align-center">
								<div>
									<div class="text-caption text-uppercase font-weight-bold">Đã nhận xét</div>
									<div class="text-h4 font-weight-bold my-1">{{ tongDaNhanXet }}</div>
								</div>
								<v-icon size="36" color="success">mdi-check-circle-outline</v-icon>
							</div>
							<div class="text-caption text-success font-weight-medium">
								Đạt {{ tongTiLe }}% tổng số HS
							</div>
						</v-card>
					</v-col>

					<!-- Card Số HS chưa nhận xét -->
					<v-col cols="12" sm="6" md="3">
						<v-card variant="tonal" color="error" class="pa-3 h-100 d-flex flex-column justify-space-between">
							<div class="d-flex justify-space-between align-center">
								<div>
									<div class="text-caption text-uppercase font-weight-bold">Chưa nhận xét</div>
									<div class="text-h4 font-weight-bold my-1">{{ tongChuaNhanXet }}</div>
								</div>
								<v-icon size="36" color="error">mdi-alert-circle-outline</v-icon>
							</div>
							<div class="text-caption text-error font-weight-medium">
								{{ soLopChuaXong > 0 ? `${soLopChuaXong} lớp chưa hoàn tất` : 'Tất cả lớp đã hoàn tất' }}
							</div>
						</v-card>
					</v-col>
				</v-row>

				<!-- Thanh tiến độ tổng quan (Visual Progress Chart) -->
				<v-card variant="outlined" class="pa-4 mb-4">
					<div class="d-flex justify-space-between align-center mb-2">
						<span class="font-weight-bold text-body-1">Tiến độ hoàn thành toàn khối:</span>
						<span class="font-weight-bold text-h6" :class="tongTiLe >= 100 ? 'text-success' : 'text-primary'">
							{{ tongTiLe }}%
						</span>
					</div>
					<v-progress-linear
						:model-value="tongTiLe"
						:color="tongTiLe >= 100 ? 'success' : tongTiLe >= 60 ? 'primary' : 'warning'"
						height="16"
						rounded
						striped
					/>
					<!-- Biểu đồ phân bổ tiến độ từng lớp (Mini Bar Chart) -->
					<div class="mt-4">
						<div class="text-caption font-weight-bold text-grey-darken-2 mb-2">BIỂU ĐỒ TIẾN ĐỘ THEO TỪNG LỚP:</div>
						<v-row dense>
							<v-col
								v-for="lop in currentTableData"
								:key="lop.LopID"
								cols="12" sm="6" md="4" lg="3"
								class="mb-2"
							>
								<div class="pa-2 border rounded bg-grey-lighten-5">
									<div class="d-flex justify-space-between text-caption font-weight-medium mb-1">
										<span>{{ lop.TenLop }}</span>
										<span :class="lop.TiLe >= 100 ? 'text-success font-weight-bold' : 'text-primary'">
											{{ lop.DaNhanXet }}/{{ lop.TongHocSinh }} ({{ lop.TiLe }}%)
										</span>
									</div>
									<v-progress-linear
										:model-value="lop.TiLe"
										:color="lop.TiLe >= 100 ? 'success' : lop.TiLe >= 70 ? 'info' : lop.TiLe > 0 ? 'warning' : 'error'"
										height="8"
										rounded
									/>
								</div>
							</v-col>
						</v-row>
					</div>
				</v-card>

				<!-- ========================================== -->
				<!-- 2. BẢNG DỮ LIỆU CHI TIẾT (TABLE REPORT)    -->
				<!-- ========================================== -->
				<div class="d-flex align-center justify-space-between mb-2">
					<span class="font-weight-bold text-subtitle-1">
						<v-icon start size="20" color="primary">mdi-table</v-icon>
						{{ getTableTitle() }}
					</span>
					<div class="text-caption text-grey">
						* Dữ liệu nhận xét được tổng hợp tự động từ module Nhập điểm & Sổ GVCN
					</div>
				</div>

				<!-- TABLE LOẠI 1: NHẬN XÉT THÁNG -->
				<div v-if="loaiBaoCao === 'thang'" class="report-table-wrapper">
					<table class="report-table">
						<thead>
							<tr>
								<th class="stt-col">STT</th>
								<th class="lop-col">Lớp</th>
								<th class="center-col">Tổng học sinh</th>
								<th class="center-col">Đã nhập nhận xét</th>
								<th class="center-col">Chưa nhập</th>
								<th class="center-col" style="min-width: 140px;">Tiến độ</th>
								<th class="center-col">Trạng thái</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="(lop, idx) in DSLopNhanXetThang" :key="lop.LopID">
								<td class="stt-col">{{ idx + 1 }}</td>
								<td class="lop-col font-weight-bold text-primary">{{ lop.TenLop }}</td>
								<td class="center-col font-weight-medium">{{ lop.TongHocSinh }}</td>
								<td class="center-col font-weight-bold text-success">{{ lop.DaNhanXet }}</td>
								<td class="center-col font-weight-bold" :class="lop.ChuaNhanXet > 0 ? 'text-error' : 'text-grey'">
									{{ lop.ChuaNhanXet }}
								</td>
								<td class="center-col">
									<div class="d-flex align-center ga-2">
										<v-progress-linear
											:model-value="lop.TiLe"
											:color="lop.TiLe >= 100 ? 'success' : lop.TiLe >= 60 ? 'primary' : 'warning'"
											height="6"
											rounded
										/>
										<span class="text-caption font-weight-bold" style="min-width: 35px;">{{ lop.TiLe }}%</span>
									</div>
								</td>
								<td class="center-col">
									<v-chip
										:color="lop.TiLe >= 100 ? 'success' : lop.TiLe > 0 ? 'warning' : 'error'"
										size="x-small"
										variant="flat"
										class="font-weight-medium"
									>
										{{ lop.TiLe >= 100 ? 'Đã xong' : lop.TiLe > 0 ? 'Đang nhập' : 'Chưa nhập' }}
									</v-chip>
								</td>
							</tr>
						</tbody>
						<tfoot>
							<tr class="footer-row">
								<th colspan="2" class="text-right font-weight-bold">TỔNG CỘNG:</th>
								<th class="center-col">{{ tongSoHocSinh }}</th>
								<th class="center-col text-success">{{ tongDaNhanXet }}</th>
								<th class="center-col text-error">{{ tongChuaNhanXet }}</th>
								<th class="center-col text-primary font-weight-bold">{{ tongTiLe }}%</th>
								<th class="center-col">
									<v-chip :color="tongTiLe >= 100 ? 'success' : 'warning'" size="x-small">
										{{ tongTiLe >= 100 ? 'Hoàn thành' : 'Chưa hoàn tất' }}
									</v-chip>
								</th>
							</tr>
						</tfoot>
					</table>
				</div>

				<!-- TABLE LOẠI 2: NHẬN XÉT HỌC KÌ & MÔN / PCNL -->
				<div v-else class="report-table-wrapper">
					<table class="report-table">
						<thead>
							<tr>
								<th class="stt-col" rowspan="2">STT</th>
								<th class="lop-col" rowspan="2">Lớp</th>
								<th class="center-col" rowspan="2">Tổng HS</th>
								<!-- Group headers cho từng cột điểm nhận xét -->
								<th
									v-for="col in activeColumns"
									:key="col.code"
									class="center-col"
									colspan="2"
								>
									{{ col.title }}
									<div class="text-caption font-weight-regular text-grey-darken-1">({{ col.code }})</div>
								</th>
								<th class="center-col" rowspan="2" style="min-width: 120px;">Tỷ lệ chung</th>
							</tr>
							<tr class="sub-header-row">
								<template v-for="col in activeColumns" :key="`sub-${col.code}`">
									<th class="center-col text-success">Đã nhập</th>
									<th class="center-col text-error">Chưa nhập</th>
								</template>
							</tr>
						</thead>
						<tbody>
							<tr v-for="(lop, idx) in DSLopNhanXetHocKy" :key="lop.LopID">
								<td class="stt-col">{{ idx + 1 }}</td>
								<td class="lop-col font-weight-bold text-primary">{{ lop.TenLop }}</td>
								<td class="center-col font-weight-medium">{{ lop.TongHocSinh }}</td>
								<!-- Các cột điểm nhận xét -->
								<template v-for="col in activeColumns" :key="`cell-${lop.LopID}-${col.code}`">
									<td class="center-col font-weight-bold text-success">
										{{ getColValue(lop, col.code, 'daNhap') }}
									</td>
									<td class="center-col font-weight-bold" :class="getColValue(lop, col.code, 'chuaNhap') > 0 ? 'text-error' : 'text-grey'">
										{{ getColValue(lop, col.code, 'chuaNhap') }}
									</td>
								</template>
								<!-- Tỷ lệ chung của lớp -->
								<td class="center-col">
									<div class="d-flex align-center ga-1">
										<v-progress-linear
											:model-value="lop.TiLe"
											:color="lop.TiLe >= 100 ? 'success' : lop.TiLe >= 60 ? 'primary' : 'warning'"
											height="6"
											rounded
										/>
										<span class="text-caption font-weight-bold" style="min-width: 32px;">{{ lop.TiLe }}%</span>
									</div>
								</td>
							</tr>
						</tbody>
						<tfoot>
							<tr class="footer-row">
								<th colspan="2" class="text-right font-weight-bold">TỔNG CỘNG:</th>
								<th class="center-col">{{ tongSoHocSinh }}</th>
								<template v-for="col in activeColumns" :key="`foot-${col.code}`">
									<th class="center-col text-success">{{ getSummaryCol(col.code).daNhap }}</th>
									<th class="center-col text-error">{{ getSummaryCol(col.code).chuaNhap }}</th>
								</template>
								<th class="center-col text-primary font-weight-bold">{{ tongTiLe }}%</th>
							</tr>
						</tfoot>
					</table>
				</div>
			</div>
		</v-card-text>
	</v-card>

	<!-- ===== DIALOG LOADING TIẾN ĐỘ CHI TIẾT ===== -->
	<v-dialog v-model="isLoading" persistent max-width="380">
		<v-card class="pa-4 text-center rounded-lg elevation-4">
			<v-card-text class="d-flex flex-column align-center py-4">
				<v-progress-circular indeterminate color="primary" size="48" width="4" class="mb-3" />
				<div class="text-subtitle-1 font-weight-bold text-primary mb-1">
					{{ loadingMessage || 'Đang tải dữ liệu nhận xét...' }}
				</div>
				<v-progress-linear
					v-if="loaiBaoCao === 'hoc-ky'"
					:model-value="loadingPercent"
					color="primary"
					height="8"
					rounded
					striped
					class="mt-2 mb-1 w-100"
				/>
				<div v-if="loaiBaoCao === 'hoc-ky'" class="text-caption font-weight-bold text-primary">
					{{ loadingPercent }}% hoàn thành
				</div>
				<div class="text-caption text-grey mt-1">Vui lòng chờ trong giây lát</div>
			</v-card-text>
		</v-card>
	</v-dialog>
	</Global>
</template>

<script>
	export default {
		data() {
		// Helper chuẩn hóa năm học an toàn, ngăn ngừa triệt để NaN
		const safeYear = (val) => {
			if (!val || typeof val === 'object') return null
			const n = Number(val)
			return (!isNaN(n) && n >= 2000 && n <= 2100) ? n : null
		}

		// Nhận niên khóa từ vueData (chuẩn FUI module) hoặc từ URL query
		const params = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : null
		const queryNienKhoa = params ? (params.get('nienKhoa') || params.get('nienkhoa') || params.get('NienKhoa') || params.get('NamHocID')) : null
		const nienKhoa = safeYear(vueData?.nienKhoa)
			|| safeYear(vueData?.NienKhoa)
			|| safeYear(vueData?.NamHocID)
			|| safeYear(queryNienKhoa)
			|| 2025

		const capID = Number(vueData?.CapID) || 1 // Cấp 1 (tiểu học)

		// Danh sách các niên khóa hỗ trợ
		const years = Array.from(new Set([nienKhoa, 2026, 2025, 2024, 2023])).sort((a, b) => b - a)
		const dsNienKhoa = years.map(y => ({ title: `${y} - ${y + 1}`, value: y }))

		return {
			NienKhoa: nienKhoa,
			DSNienKhoa: dsNienKhoa,
			CapID: capID,
			KhoiID: null,

			// Phân loại báo cáo
			loaiBaoCao: 'thang', // 'thang' hoặc 'hoc-ky'
			DSLoaiBaoCao: [
				{ title: 'Nhận xét tháng (Sổ GVCN / Tháng)', value: 'thang' },
				{ title: 'Nhận xét học kì (Theo môn & Phẩm chất năng lực)', value: 'hoc-ky' }
			],

			// Bộ lọc tháng
			Thang: new Date().getMonth() + 1,
			DSThang: [
				{ label: 'Tháng 8', value: 8 },
				{ label: 'Tháng 9', value: 9 },
				{ label: 'Tháng 10', value: 10 },
				{ label: 'Tháng 11', value: 11 },
				{ label: 'Tháng 12', value: 12 },
				{ label: 'Tháng 1', value: 1 },
				{ label: 'Tháng 2', value: 2 },
				{ label: 'Tháng 3', value: 3 },
				{ label: 'Tháng 4', value: 4 },
				{ label: 'Tháng 5', value: 5 }
			],

			// Bộ lọc học kì / đợt đánh giá
			HocKy: 'GK_HK1',
			DSHocKy: [
				{ label: 'Giữa học kì 1 (GK_HK1)', value: 'GK_HK1' },
				{ label: 'Cuối học kì 1 (CK_HK1)', value: 'CK_HK1' },
				{ label: 'Giữa học kì 2 (GK_HK2)', value: 'GK_HK2' },
				{ label: 'Cuối học kì 2 (CK_HK2)', value: 'CK_HK2' }
			],

			// Bộ lọc phân nhóm môn học / PCNL cho tab học kì
			nhomMonHocKy: 'all',
			DSNhomMonHocKy: [
				{ title: 'Tất cả cột nhận xét', value: 'all' },
				{ title: 'Môn học đánh giá (Toán, TV, TA...)', value: 'mon-hoc' },
				{ title: 'Năng lực cốt lõi & đặc thù', value: 'nang-luc' },
				{ title: 'Phẩm chất chủ yếu', value: 'pham-chat' }
			],

			// Danh sách lọc danh mục
			DSKhoi: [],
			DSLop: [],

			// Kết quả tổng hợp
			DSLopNhanXetThang: [],
			DSLopNhanXetHocKy: [],

			// Bộ đệm client-side cache giúp chuyển tab / đổi bộ lọc tức thì không cần request lại backend
			dataCacheHocKy: {},
			dataCacheThang: {},

			isLoading: false,
			isLoadingKhoi: false,
			loadingMessage: '',
			loadingPercent: 0,
			errorMessage: ''
		}
	},

	computed: {
		/**
		 * Danh sách cột nhận xét hiển thị động theo đợt đánh giá và nhóm môn
		 * Chuẩn hóa theo mã cột trong tblTemplateBangDiemChiTiet:
		 * - Giữa HK1: NhanXetGK_HKI
		 * - Cuối HK1: NhanXetCK_HKI
		 * - Giữa HK2: NhanXetGK_HKII
		 * - Cuối HK2: NhanXetCK_HKII
		 */
		activeColumns() {
			const hk = this.HocKy // 'GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2'
			const isHK1 = hk.includes('1') || (hk.includes('I') && !hk.includes('II'))
			const isGK = hk.includes('GK')
			const romanHK = isHK1 ? 'HKI' : 'HKII'
			const arabicHK = isHK1 ? 'HK1' : 'HK2'
			const phase = isGK ? 'GK' : 'CK'
			const phaseTitle = isGK ? 'Giữa kì' : 'Cuối kì'
			const hkTitle = isHK1 ? 'HK1' : 'HK2'

			// Mã cột chuẩn theo TemplateBangDiemChiTiet
			const monCode = `NhanXet${phase}_${romanHK}`
			const nlCode = `NhanXet_NL_${phase}_${romanHK}`
			const pcCode = `NhanXet_PC_${phase}_${romanHK}`

			const allCols = [
				// Cột nhận xét môn học (Toán, Tiếng Việt, Tiếng Anh...)
				{
					code: monCode,
					title: `Nhận xét môn học (${phaseTitle} ${hkTitle})`,
					group: 'mon-hoc',
					aliases: [
						monCode,
						`NhanXet${phase}_${arabicHK}`,
						`NhanXet_${phase}_${romanHK}`,
						`NhanXet_${phase}_${arabicHK}`,
						`NhanXet_${romanHK}`,
						`NhanXet_${arabicHK}`,
						`NhanXet_${hk}`,
						'NhanXet'
					]
				},
				// Cột nhận xét Năng lực cốt lõi & đặc thù
				{
					code: nlCode,
					title: `Năng lực (${phaseTitle} ${hkTitle})`,
					group: 'nang-luc',
					aliases: [
						nlCode,
						`NhanXet_NL_${phase}_${arabicHK}`,
						`NhanXet_NL_${romanHK}`,
						`NhanXet_NL_${arabicHK}`,
						`NhanXet_NL_${hk}`,
						'NhanXet_NL',
						'NangLuc'
					]
				},
				// Cột nhận xét Phẩm chất chủ yếu
				{
					code: pcCode,
					title: `Phẩm chất (${phaseTitle} ${hkTitle})`,
					group: 'pham-chat',
					aliases: [
						pcCode,
						`NhanXet_PC_${phase}_${arabicHK}`,
						`NhanXet_PC_${romanHK}`,
						`NhanXet_PC_${arabicHK}`,
						`NhanXet_PC_${hk}`,
						'NhanXet_PC',
						'PhamChat'
					]
				}
			]

			// Lọc theo nhóm môn / đánh giá đã chọn
			if (this.nhomMonHocKy === 'all') {
				return allCols
			}
			return allCols.filter(c => c.group === this.nhomMonHocKy)
		},

		/** Mảng dữ liệu đang active theo loại báo cáo */
		currentTableData() {
			return this.loaiBaoCao === 'thang' ? this.DSLopNhanXetThang : this.DSLopNhanXetHocKy
		},

		hasData() {
			return this.currentTableData.length > 0
		},

		tongSoHocSinh() {
			return this.currentTableData.reduce((sum, lop) => sum + (lop.TongHocSinh || 0), 0)
		},

		tongDaNhanXet() {
			return this.currentTableData.reduce((sum, lop) => sum + (lop.DaNhanXet || 0), 0)
		},

		tongChuaNhanXet() {
			return this.currentTableData.reduce((sum, lop) => sum + (lop.ChuaNhanXet || 0), 0)
		},

		tongTiLe() {
			if (!this.tongSoHocSinh) return 0
			return Math.round((this.tongDaNhanXet / this.tongSoHocSinh) * 100)
		},

		soLopChuaXong() {
			return this.currentTableData.filter(lop => lop.TiLe < 100).length
		}
	},

	mounted() {
		// Helper chuẩn hóa năm học an toàn
		const safeYear = (val) => {
			if (!val || typeof val === 'object') return null
			const n = Number(val)
			return (!isNaN(n) && n >= 2000 && n <= 2100) ? n : null
		}

		// Đọc query param từ URL nếu được mở từ bc-tong-hop-bao-cao
		const params = new URLSearchParams(window.location.search)
		const queryHk = params.get('hk')
		const queryTab = params.get('tab')
		const queryKhoi = params.get('khoiid') || params.get('khoiId') || params.get('KhoiID')
		const queryNienKhoa = params.get('nienKhoa') || params.get('nienkhoa') || params.get('NienKhoa') || params.get('NamHocID')

		const validYear = safeYear(queryNienKhoa) || safeYear(vueData?.nienKhoa) || safeYear(vueData?.NienKhoa)
		if (validYear) {
			this.NienKhoa = validYear
		}

		if (queryTab === 'thang') {
			this.loaiBaoCao = 'thang'
		} else if (queryHk) {
			this.loaiBaoCao = 'hoc-ky'
			if (['GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2'].includes(queryHk)) {
				this.HocKy = queryHk
			}
		}

		if (queryKhoi !== null && queryKhoi !== undefined && queryKhoi !== '') {
			this.KhoiID = Number(queryKhoi)
		} else {
			this.KhoiID = null
		}

		this.loadKhoi().then(() => {
			// Chỉ tự động tải nếu trên URL có truyền tham số khối cụ thể
			if (this.KhoiID !== null && this.KhoiID !== undefined) {
				this.onSearch()
			}
		})
	},

	watch: {
		NienKhoa() {
			this.loadKhoi().then(() => {
				if (this.KhoiID !== null && this.KhoiID !== undefined) {
					this.onSearch()
				}
			})
		},
		KhoiID(newVal) {
			if (newVal === null || newVal === undefined) {
				this.DSLopNhanXetThang = []
				this.DSLopNhanXetHocKy = []
				return
			}
			this.onSearch()
		},
		loaiBaoCao() {
			this.errorMessage = ''
			if (this.KhoiID !== null && this.KhoiID !== undefined) {
				this.onSearch()
			}
		},
		Thang() {
			if (this.loaiBaoCao === 'thang' && this.KhoiID !== null && this.KhoiID !== undefined) {
				this.onSearch()
			}
		},
		HocKy() {
			if (this.loaiBaoCao === 'hoc-ky' && this.KhoiID !== null && this.KhoiID !== undefined) {
				this.onSearch()
			}
		},
		nhomMonHocKy() {
			if (this.loaiBaoCao === 'hoc-ky' && this.KhoiID !== null && this.KhoiID !== undefined) {
				this.onSearch()
			}
		}
	},

	methods: {
		/** Xử lý khi thay đổi niên khóa */
		async onNienKhoaChange() {
			await this.loadKhoi()
			if (this.KhoiID !== null && this.KhoiID !== undefined) {
				this.onSearch()
			}
		},

		/** Làm sạch giá trị tránh [object Object] hoặc ký tự rác */
		cleanVal(val) {
			if (val === null || val === undefined) return ''
			if (typeof val === 'object') return ''
			return String(val).trim()
		},

		/** Chuẩn hóa phản hồi API thành mảng */
		normalizeResponse(res) {
			if (Array.isArray(res)) return res
			if (Array.isArray(res?.data)) return res.data
			if (Array.isArray(res?.[0]?.data)) return res[0].data
			return []
		},

		/** Tiêu đề bảng hiển thị */
		getTableTitle() {
			if (this.loaiBaoCao === 'thang') {
				const th = this.DSThang.find(t => t.value === this.Thang)?.label || `Tháng ${this.Thang}`
				return `Bảng thống kê nhận xét ${th} - Năm học ${this.NienKhoa}`
			}
			const hk = this.DSHocKy.find(h => h.value === this.HocKy)?.label || this.HocKy
			return `Bảng thống kê nhận xét ${hk} (Môn học & Phẩm chất Năng lực)`
		},

		/** Tải danh sách khối Cấp 1 */
		async loadKhoi() {
			this.isLoadingKhoi = true
			try {
				const res = await ajaxCALLPromise('lms/KhoiHocByCapHoc_Get', {
					CapID: this.CapID,
					HocKi: 1,
					NienKhoa: this.NienKhoa
				})
				const raw = this.normalizeResponse(res)
				let list = []
				if (raw && raw.length) {
					list = raw.map(k => ({
						KhoiID: Number(k.KhoiID || k.KhoiHocID || k.value),
						TenKhoiHoc: k.TenKhoiHoc || k.TenKhoi || `Khối ${k.KhoiHocCode || k.KhoiID || ''}`
					}))
				} else {
					// Fallback mặc định 5 khối của Cấp 1 (Tiểu học) nếu API trả rỗng
					list = [
						{ KhoiID: 1, TenKhoiHoc: 'Khối 1' },
						{ KhoiID: 2, TenKhoiHoc: 'Khối 2' },
						{ KhoiID: 3, TenKhoiHoc: 'Khối 3' },
						{ KhoiID: 4, TenKhoiHoc: 'Khối 4' },
						{ KhoiID: 5, TenKhoiHoc: 'Khối 5' }
					]
				}

				// Thêm option Tất cả lên đầu danh sách
				this.DSKhoi = [
					{ KhoiID: 0, TenKhoiHoc: 'Tất cả các khối' },
					...list
				]
			} catch (e) {
				console.error('Lỗi load khối:', e)
				this.DSKhoi = [
					{ KhoiID: 0, TenKhoiHoc: 'Tất cả các khối' },
					{ KhoiID: 1, TenKhoiHoc: 'Khối 1' },
					{ KhoiID: 2, TenKhoiHoc: 'Khối 2' },
					{ KhoiID: 3, TenKhoiHoc: 'Khối 3' },
					{ KhoiID: 4, TenKhoiHoc: 'Khối 4' },
					{ KhoiID: 5, TenKhoiHoc: 'Khối 5' }
				]
			} finally {
				this.isLoadingKhoi = false
			}
		},

		/** Tải danh sách lớp theo khối / Cấp 1 */
		async loadLop() {
			const res = await ajaxCALLPromise('lms/Lop_Get_By_CapID', {
				NienKhoa: this.NienKhoa,
				CapID: this.CapID
			})
			let ds = this.normalizeResponse(res)
			if (this.KhoiID && Number(this.KhoiID) !== 0) {
				ds = ds.filter(l => Number(l.KhoiID) === Number(this.KhoiID))
			}
			this.DSLop = ds
		},

		/** Tìm kiếm và tổng hợp báo cáo */
		async onSearch() {
			if (this.KhoiID === null || this.KhoiID === undefined) {
				this.errorMessage = 'Vui lòng chọn Khối để xem báo cáo.'
				return
			}
			this.errorMessage = ''
			this.isLoading = true
			this.loadingPercent = 0
			this.loadingMessage = 'Đang tải danh sách lớp học...'
			try {
				await this.loadLop()
				if (!this.DSLop.length) {
					this.errorMessage = 'Không tìm thấy lớp học nào thuộc khối đã chọn.'
					return
				}

				if (this.loaiBaoCao === 'thang') {
					this.loadingMessage = `Đang tổng hợp nhận xét Tháng ${this.Thang}...`
					await this.loadBaoCaoThang()
				} else {
					await this.loadBaoCaoHocKy()
				}
			} catch (e) {
				console.error('Lỗi tra cứu báo cáo:', e)
				this.errorMessage = 'Đã có lỗi xảy ra khi tải báo cáo nhận xét.'
			} finally {
				this.isLoading = false
				this.loadingPercent = 100
			}
		},

		/**
		 * Xử lý báo cáo Nhận xét Tháng
		 * Dựa vào spAPI_NhanXetThang_Lop_Get_TinhTrang và dữ liệu chi tiết từng lớp
		 */
		async loadBaoCaoThang() {
			let rawTinhTrang = []
			try {
				const res = await ajaxCALLPromise('lms/NhanXetThang_Lop_Get_TinhTrang', {
					NienKhoa: this.NienKhoa,
					Thang: this.Thang,
					CapID: this.CapID
				})
				rawTinhTrang = this.normalizeResponse(res)
			} catch (err) {
				console.warn('Lỗi gọi NhanXetThang_Lop_Get_TinhTrang:', err)
			}

			// Map dữ liệu tổng hợp từng lớp
			this.DSLopNhanXetThang = this.DSLop.map(lop => {
				const lopId = lop.LopID || lop.LopHocID
				const record = rawTinhTrang.find(r => Number(r.LopID) === Number(lopId))
				
				const tongHS = Number(record?.TongHocSinh || lop.SiSo || 0)
				const daNhap = Number(record?.DaNhapNhanXet || record?.SoHSDaNhap || (record?.TinhTrang >= 2 ? tongHS : 0))
				const chuaNhap = Math.max(0, tongHS - daNhap)
				const tiLe = tongHS > 0 ? Math.round((daNhap / tongHS) * 100) : 0

				return {
					LopID: lopId,
					TenLop: this.cleanVal(lop.TenLop),
					KhoiID: lop.KhoiID,
					TongHocSinh: tongHS,
					DaNhanXet: daNhap,
					ChuaNhanXet: chuaNhap,
					TiLe: tiLe,
					TinhTrang: record?.TinhTrang || null
				}
			})
		},

		/**
		 * Xử lý báo cáo Nhận xét Học kì (Môn học & PCNL) - ĐÃ TỐI ƯU HÓA
		 * - Tối ưu 1: Chia lô (Chunking 5 lớp song song) tránh nghẽn socket HTTP và quá tải server SQL.
		 * - Tối ưu 2: Bộ nhớ đệm (Client-side cache) theo từng lớp, niên khóa và học kì.
		 * - Tối ưu 3: Gọi có điều kiện theo nhóm môn (Ví dụ: xem riêng Môn học thì không gọi API PCNL).
		 */
		async loadBaoCaoHocKy() {
			const semesterCode = this.HocKy.includes('HK1') ? '1' : '2'
			const cols = this.activeColumns
			const totalLop = this.DSLop.length
			let completedCount = 0

			this.loadingMessage = `Đang tải dữ liệu ${totalLop} lớp...`
			this.loadingPercent = 0

			const needsBangDiem = this.nhomMonHocKy === 'all' || this.nhomMonHocKy === 'mon-hoc'
			const needsPCNL = this.nhomMonHocKy === 'all' || this.nhomMonHocKy === 'nang-luc' || this.nhomMonHocKy === 'pham-chat'

			// Hàm xử lý tải dữ liệu cho từng lớp có cache
			const fetchLopData = async (lop) => {
				const lopId = lop.LopID || lop.LopHocID
				const cacheKey = `${this.NienKhoa}_${this.HocKy}_${lopId}`

				if (this.dataCacheHocKy[cacheKey]) {
					completedCount++
					this.loadingPercent = Math.round((completedCount / totalLop) * 100)
					this.loadingMessage = `Đang tải: ${lop.TenLop} (${completedCount}/${totalLop})`
					return {
						lop,
						...this.dataCacheHocKy[cacheKey]
					}
				}

				try {
					const promises = []

					// 1. Tải bảng điểm môn nếu cần
					if (needsBangDiem) {
						promises.push(
							ajaxCALLPromise('lms/HocSinhBangDiem_Get_ByLopID_Semester', {
								LopID: String(lopId),
								NienKhoa: this.NienKhoa,
								Semester: semesterCode
							}).catch(() => [])
						)
					} else {
						promises.push(Promise.resolve([]))
					}

					// 2. Tải nhận xét Phẩm chất Năng lực nếu cần
					if (needsPCNL) {
						promises.push(
							ajaxCALLPromise('lms/BaoCao_ThongKe_NhanXet_Cap1', {
								LopID: String(lopId),
								NienKhoa: this.NienKhoa,
								HocKi: this.HocKy
							}).catch(() => [])
						)
					} else {
						promises.push(Promise.resolve([]))
					}

					const [resBangDiem, resPCNL] = await Promise.all(promises)
					const rawBangDiem = this.normalizeResponse(resBangDiem)
					const rawPCNL = this.normalizeResponse(resPCNL)

					const resultData = {
						bangDiem: rawBangDiem,
						pcnl: rawPCNL
					}

					// Lưu vào cache
					this.dataCacheHocKy[cacheKey] = resultData

					completedCount++
					this.loadingPercent = Math.round((completedCount / totalLop) * 100)
					this.loadingMessage = `Đang tải: ${lop.TenLop} (${completedCount}/${totalLop})`

					return { lop, ...resultData }
				} catch (e) {
					completedCount++
					this.loadingPercent = Math.round((completedCount / totalLop) * 100)
					return { lop, bangDiem: [], pcnl: [] }
				}
			}

			// Chia danh sách lớp thành các chunk (mỗi chunk 5 lớp) chạy tuần tự để tối ưu tài nguyên
			const chunkSize = 5
			const allResults = []
			for (let i = 0; i < this.DSLop.length; i += chunkSize) {
				const chunk = this.DSLop.slice(i, i + chunkSize)
				const chunkResults = await Promise.all(chunk.map(lop => fetchLopData(lop)))
				allResults.push(...chunkResults)
			}

			this.loadingMessage = 'Đang xử lý kết quả thống kê...'

			this.DSLopNhanXetHocKy = allResults.map(res => {
				const { lop, bangDiem, pcnl } = res || { lop: {}, bangDiem: [], pcnl: [] }
				const tongHS = bangDiem.length || Number(lop.SiSo || 0)
				const colDetails = {}

				let totalDaNhapAllCols = 0
				let countCols = 0

				cols.forEach(c => {
					let daNhapCount = 0

					// 1. Quét đối với nhóm Môn học: tìm trong bảng điểm qua mọi alias khả dĩ
					if (c.group === 'mon-hoc') {
						daNhapCount = bangDiem.filter(hs => {
							const aliases = c.aliases || [c.code]
							for (const key of aliases) {
								const val = hs[key]
								if (val !== null && val !== undefined && this.cleanVal(val) !== '') {
									return true
								}
							}
							return false
						}).length
					} else if (c.group === 'nang-luc') {
						// 2. Quét đối với nhóm Năng lực: quét trong danh sách PCNL và đối soát bảng điểm
						const hsNangLuc = new Set(
							pcnl
								.filter(x => {
									const nhom = String(x.NhomNhanXet || x.MaNhom || '').toLowerCase()
									return (nhom.includes('năng lực') || nhom.includes('nang luc') || nhom.includes('nl')) && this.cleanVal(x.NhanXet) !== ''
								})
								.map(x => x.HocSinhID)
						)

						// Đối soát thêm các cột mã năng lực trong bảng điểm nếu có
						bangDiem.forEach(hs => {
							const aliases = c.aliases || [c.code]
							for (const key of aliases) {
								const val = hs[key]
								if (val !== null && val !== undefined && this.cleanVal(val) !== '') {
									hsNangLuc.add(hs.HocSinhID)
									break
								}
							}
						})
						daNhapCount = hsNangLuc.size
					} else if (c.group === 'pham-chat') {
						// 3. Quét đối với nhóm Phẩm chất: quét trong danh sách PCNL và đối soát bảng điểm
						const hsPhamChat = new Set(
							pcnl
								.filter(x => {
									const nhom = String(x.NhomNhanXet || x.MaNhom || '').toLowerCase()
									return (nhom.includes('phẩm chất') || nhom.includes('pham chat') || nhom.includes('pc')) && this.cleanVal(x.NhanXet) !== ''
								})
								.map(x => x.HocSinhID)
						)

						// Đối soát thêm các cột mã phẩm chất trong bảng điểm nếu có
						bangDiem.forEach(hs => {
							const aliases = c.aliases || [c.code]
							for (const key of aliases) {
								const val = hs[key]
								if (val !== null && val !== undefined && this.cleanVal(val) !== '') {
									hsPhamChat.add(hs.HocSinhID)
									break
								}
							}
						})
						daNhapCount = hsPhamChat.size
					}

					// Giới hạn số lượng không vượt quá tổng học sinh lớp
					daNhapCount = Math.min(daNhapCount, tongHS)
					const chuaNhapCount = Math.max(0, tongHS - daNhapCount)

					colDetails[c.code] = {
						daNhap: daNhapCount,
						chuaNhap: chuaNhapCount
					}

					totalDaNhapAllCols += daNhapCount
					countCols++
				})

				const avgDaNhap = countCols > 0 ? Math.round(totalDaNhapAllCols / countCols) : 0
				const avgTiLe = tongHS > 0 ? Math.round((avgDaNhap / tongHS) * 100) : 0

				return {
					LopID: lop.LopID || lop.LopHocID,
					TenLop: this.cleanVal(lop.TenLop),
					KhoiID: lop.KhoiID,
					TongHocSinh: tongHS,
					DaNhanXet: avgDaNhap,
					ChuaNhanXet: Math.max(0, tongHS - avgDaNhap),
					TiLe: avgTiLe,
					CotDiemDetail: colDetails
				}
			})
		},

		/** Lấy giá trị của từng cột theo lớp */
		getColValue(lop, colCode, key) {
			return lop.CotDiemDetail?.[colCode]?.[key] ?? 0
		},

		/** Tính tổng cột toàn trường/khối */
		getSummaryCol(colCode) {
			return {
				daNhap: this.DSLopNhanXetHocKy.reduce((sum, l) => sum + this.getColValue(l, colCode, 'daNhap'), 0),
				chuaNhap: this.DSLopNhanXetHocKy.reduce((sum, l) => sum + this.getColValue(l, colCode, 'chuaNhap'), 0)
			}
		},

		/** Đảm bảo thư viện XLSX sẵn sàng */
		ensureXLSX() {
			if (window.XLSX) return Promise.resolve(window.XLSX)
			return new Promise((resolve, reject) => {
				const script = document.createElement('script')
				script.src = 'https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js'
				script.onload = () => resolve(window.XLSX)
				script.onerror = reject
				document.head.appendChild(script)
			})
		},

		/** Xuất Excel báo cáo đồng bộ với UI */
		async onExportExcel() {
			if (!this.hasData) return
			try {
				const XLSX = await this.ensureXLSX()
				const wb = XLSX.utils.book_new()

				// Lấy nhãn thông tin lọc
				const nienKhoaLabel = `${this.NienKhoa} - ${this.NienKhoa + 1}`
				const khoiLabel = this.KhoiID ? (this.DSKhoi.find(k => k.KhoiID === this.KhoiID)?.TenKhoiHoc || `Khối ${this.KhoiID}`) : 'Tất cả các khối'
				const dotLabel = this.loaiBaoCao === 'thang' 
					? (this.DSThang.find(t => t.value === this.Thang)?.label || `Tháng ${this.Thang}`)
					: (this.DSHocKy.find(h => h.value === this.HocKy)?.label || this.HocKy)

				const titleRow = ['BÁO CÁO TIẾN ĐỘ NHẬP NHẬN XÉT CẤP 1']
				const infoRow = [`Niên khóa: ${nienKhoaLabel} | ${dotLabel} | Khối: ${khoiLabel}`]
				const emptyRow = []

				if (this.loaiBaoCao === 'thang') {
					const headers = ['STT', 'Lớp', 'Tổng học sinh', 'Đã nhập nhận xét', 'Chưa nhập nhận xét', 'Tỷ lệ hoàn thành (%)', 'Trạng thái']
					const rows = this.DSLopNhanXetThang.map((l, i) => [
						i + 1,
						l.TenLop,
						l.TongHocSinh,
						l.DaNhanXet,
						l.ChuaNhanXet,
						`${l.TiLe}%`,
						l.TiLe >= 100 ? 'Đã xong' : l.TiLe > 0 ? 'Đang nhập' : 'Chưa nhập'
					])
					const totalRow = ['TỔNG CỘNG', '', this.tongSoHocSinh, this.tongDaNhanXet, this.tongChuaNhanXet, `${this.tongTiLe}%`, this.tongTiLe >= 100 ? 'Hoàn thành' : 'Chưa hoàn tất']
					
					const aoa = [titleRow, infoRow, emptyRow, headers, ...rows, totalRow]
					const ws = XLSX.utils.aoa_to_sheet(aoa)
					const totalRowIdx = aoa.length - 1

					ws['!merges'] = [
						{ s: { r: 0, c: 0 }, e: { r: 0, c: 6 } },
						{ s: { r: 1, c: 0 }, e: { r: 1, c: 6 } },
						{ s: { r: totalRowIdx, c: 0 }, e: { r: totalRowIdx, c: 1 } }
					]
					ws['!cols'] = [
						{ wch: 8 },
						{ wch: 15 },
						{ wch: 16 },
						{ wch: 20 },
						{ wch: 22 },
						{ wch: 24 },
						{ wch: 18 }
					]

					XLSX.utils.book_append_sheet(wb, ws, `NX_Thang_${this.Thang}`)
				} else {
					const cols = this.activeColumns
					const totalCols = 3 + cols.length * 2 + 1

					// Dòng header 1 (Tên nhóm cột nhận xét)
					const mainHeader = ['STT', 'Lớp', 'Tổng HS']
					cols.forEach(c => {
						mainHeader.push(`${c.title} (${c.code})`, '')
					})
					mainHeader.push('Tỷ lệ chung (%)')

					// Dòng header 2 (Đã nhập / Chưa nhập)
					const subHeader = ['', '', '']
					cols.forEach(() => {
						subHeader.push('Đã nhập', 'Chưa nhập')
					})
					subHeader.push('')

					const rows = this.DSLopNhanXetHocKy.map((l, i) => [
						i + 1,
						l.TenLop,
						l.TongHocSinh,
						...cols.flatMap(c => [this.getColValue(l, c.code, 'daNhap'), this.getColValue(l, c.code, 'chuaNhap')]),
						`${l.TiLe}%`
					])

					const totalRow = [
						'TỔNG CỘNG',
						'',
						this.tongSoHocSinh,
						...cols.flatMap(c => [this.getSummaryCol(c.code).daNhap, this.getSummaryCol(c.code).chuaNhap]),
						`${this.tongTiLe}%`
					]

					const aoa = [titleRow, infoRow, emptyRow, mainHeader, subHeader, ...rows, totalRow]
					const ws = XLSX.utils.aoa_to_sheet(aoa)
					const totalRowIdx = aoa.length - 1

					// Thiết lập ô merge cho tiêu đề và header 2 tầng
					const merges = [
						{ s: { r: 0, c: 0 }, e: { r: 0, c: totalCols - 1 } },
						{ s: { r: 1, c: 0 }, e: { r: 1, c: totalCols - 1 } },
						{ s: { r: 3, c: 0 }, e: { r: 4, c: 0 } }, // STT
						{ s: { r: 3, c: 1 }, e: { r: 4, c: 1 } }, // Lớp
						{ s: { r: 3, c: 2 }, e: { r: 4, c: 2 } }  // Tổng HS
					]

					let colPointer = 3
					cols.forEach(() => {
						merges.push({ s: { r: 3, c: colPointer }, e: { r: 3, c: colPointer + 1 } })
						colPointer += 2
					})

					// Merge Tỷ lệ chung & dòng Tổng cộng
					merges.push({ s: { r: 3, c: totalCols - 1 }, e: { r: 4, c: totalCols - 1 } })
					merges.push({ s: { r: totalRowIdx, c: 0 }, e: { r: totalRowIdx, c: 1 } })

					ws['!merges'] = merges
					ws['!cols'] = [
						{ wch: 8 },
						{ wch: 14 },
						{ wch: 12 },
						...cols.flatMap(() => [{ wch: 14 }, { wch: 14 }]),
						{ wch: 16 }
					]

					XLSX.utils.book_append_sheet(wb, ws, `NX_${this.HocKy}`)
				}

				const fileName = `BC_TienDo_NhanXet_C1_${this.loaiBaoCao === 'thang' ? `Thang_${this.Thang}` : this.HocKy}.xlsx`
				XLSX.writeFile(wb, fileName)
			} catch (e) {
				console.error('Lỗi xuất Excel:', e)
				this.errorMessage = 'Không thể xuất file Excel.'
			}
		}
	}
	}
</script>