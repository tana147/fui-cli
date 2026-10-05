<template>
	<v-dialog v-model="vueData.isOpenTotalTotNghiep" persistent eager transition="dialog-bottom-transition"
		max-width="1400px">
		<v-card class="qdt-dialog">
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<p class="mb-0 primary--text">Các học viên đã tốt nghiệp</p>
				</template>
			</c-toolbar>

			<v-card-text class="qdt-dialog__body">
				<v-sheet color="transparent">
					<v-row dense class="mt-3">
						<v-col cols="12" md="3">
							<v-select v-model="major" :items="nganhgiangday" outlined dense multiple small-chips
								hide-details label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID"
								class="qdt-input" prepend-inner-icon="mdi-shape-outline" />
						</v-col>

						<v-col cols="12" md="3">
							<v-autocomplete v-model="MultipleKhoaTotNghiep" :items="DsUniqueNienKhoaTotNghiep"
								item-text="TenNienKhoa" item-value="NienKhoa" multiple outlined dense hide-details
								clearable chips small-chips label="Lọc theo năm tốt nghiệp" class="qdt-input"
								prepend-inner-icon="mdi-calendar-multiple" />
						</v-col>

						<v-col cols="12" md="3">
							<v-autocomplete v-model="MultipleDecisionSoQD" :items="DecisionSoQDOptions" item-text="text"
								item-value="value" multiple outlined dense hide-details clearable chips small-chips
								label="Lọc theo số QĐ xét tốt nghiệp" class="qdt-input"
								prepend-inner-icon="mdi-filter-variant" />
						</v-col>

						<v-col cols="12" md="3">
							<v-autocomplete v-model="MultipleDecisionDot" :items="DecisionDotOptions" multiple outlined
								dense hide-details clearable chips small-chips label="Lọc theo đợt tốt nghiệp"
								class="qdt-input" prepend-inner-icon="mdi-filter-variant" />
						</v-col>

						<v-col cols="12" md="3">
							<v-autocomplete v-model="MultipleFilterNienKhoa" :items="DsNienKhoa" item-text="TenNienKhoa"
								item-value="NienKhoa" multiple outlined dense hide-details clearable chips small-chips
								label="Lọc theo niên khóa" class="qdt-input"
								prepend-inner-icon="mdi-calendar-multiple" />
						</v-col>

						<v-col cols="12" md="3" class="d-flex align-center qdt-filter-actions">
							<v-btn color="primary" @click="onApplyFilters">
								<v-icon left>mdi-filter</v-icon>
								Lọc
							</v-btn>
						</v-col>
					</v-row>
				</v-sheet>

				<v-sheet rounded="xl" class="qdt-table-wrap pa-2 pa-md-3">
					<v-card-title class="primary--text">
						Danh sách học viên ({{ DsHocVien.length }})
						<v-spacer></v-spacer>
						<v-text-field v-model="search" dense hide-details clearable prepend-inner-icon="mdi-magnify"
							label="Tên học viên, mã học viên" class="qdt-search" />
					</v-card-title>
					<v-data-table class="table-frozen-cols" v-model="SelectedStudents" :headers="tableHeader"
						:items="FilteredDsHocVien" :loading="isLoading" loading-text="Đang tải danh sách học viên..."
						no-data-text="Chưa có dữ liệu học viên" fixed-header height="380" dense show-select
						item-key="Student_ID" :items-per-page="50"
						:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
						<template v-slot:item.Student_ID="{ item }">
							<span class="primary--text">
								<b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
							</span>
							<br />
							<b>{{ item.Student_ID }}</b>
							<span class="amber--text"> [{{ item.Lop_ID }}]</span>
						</template>

						<template v-slot:item.DiemHoiDong="{ item }">
							<v-chip small label color="amber lighten-5" text-color="amber darken-4">
								{{ item.DiemHoiDong }}
							</v-chip>
						</template>

						<template v-slot:item.ThoiGianBaoVe="{ item }">
							<span class="font-weight-medium">{{ item.ThoiGianBaoVe || '-' }}</span>
						</template>
					</v-data-table>
				</v-sheet>
			</v-card-text>

			<v-card-actions
				class="qdt-dialog__actions px-4 py-3 d-flex flex-column flex-md-row align-start align-md-center">
				<div class="mb-3 mb-md-0">
					<div class="text-subtitle-2 font-weight-medium">Xuất quyết định tốt nghiệp</div>
					<div class="text-caption grey--text text--darken-1">{{ SelectedStudents.length }} học viên đang được
						chọn</div>
				</div>

				<v-spacer></v-spacer>

				<v-btn @click="onPrintTotalListExcel" color="success" :loading="isLoadingExport" dense hide-details>
					<v-icon left>mdi-microsoft-excel</v-icon> Xuất danh sách tổng
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			nganhgiangday: {
				type: Array,
				default: () => [],
			},
			dsnienkhoa: {
				type: Array,
				default: () => [],
			},
		},
		data() {
			return {
				isLoadingExport: false,
				major: [0],
				AppliedMajor: [],
				MultipleKhoaTotNghiep: [],
				AppliedKhoaTotNghiep: [],
				MultipleDecisionDot: [],
				MultipleDecisionSoQD: [],
				MultipleFilterNienKhoa: [],
				AppliedFilterNienKhoa: [], // Khởi tạo mảng lưu bộ lọc niên khóa đã áp dụng
				AppliedDecisionDot: [],
				AppliedDecisionSoQD: [],
				allNienKhoaValue: '__ALL__',
				allDecisionSoQDValue: '__ALL_DECISION_SOQD__',
				DecisionDotOptions: [],
				DsUniqueNienKhoaTotNghiep: [],
				DecisionSoQDOptions: [],
				SelectedStudents: [],
				DsHocVien: [],
				DsHocVienRoot: [],
				isLoading: false,
				search: '',
	
				tableHeader: [
					{ text: 'STT', value: 'STT', sortable: false, align: 'center', width: 50 },
					{ text: 'Học viên', value: 'Student_ID', width: 200 },
					{ text: 'Niên khóa', value: 'Nien_Khoa', sortable: false, align: 'center', width: 110 },
					{ text: 'Tên ngành', value: 'Ten_Nganh', width: 200 },
					{ text: 'Tên đề tài', value: 'Thesis_Name', sortable: false, width: 500 },
					{ text: 'GVHD 1', value: 'Thesises_Prof1', sortable: false, width: 180 },
					{ text: 'GVHD 2', value: 'Thesises_Prof2', sortable: false, width: 180 },
					{ text: 'Số QĐ xét tốt nghiệp', value: 'Decision_SoQD', align: 'center', sortable: false, width: 180 },
					{ text: 'Ngày lập QĐ tốt nghiệp', value: 'NgayLapQuyetDinh', sortable: false, align: 'center', width: 180 },
					{ text: 'Niên khóa tốt nghiệp', value: 'Decision_NienKhoa', sortable: false, align: 'center', width: 120 },
					{ text: 'Đợt tốt nghiệp', value: 'Decision_Dot', sortable: false, align: 'center', width: 120 },
					{ text: 'Số QĐ lập hội đồng', value: 'SoQDLapHoiDong', sortable: false, align: 'center', width: 180 },
					{ text: 'Thời gian bảo vệ', value: 'ThoiGianBaoVe', sortable: false, align: 'center', width: 140 },
					{ text: 'Điểm hội đồng', value: 'DiemHoiDong', sortable: false, align: 'center', width: 160 },
					{ text: 'Tên ngoại ngữ đầu vào', value: 'TenNgoaiNguDauVao', sortable: false, width: 190 },
					{ text: 'Tên ngoại ngữ đầu ra', value: 'TenNgoaiNguDauRa', sortable: false, width: 180 },
					{ text: 'Văn bằng/chứng chỉ ngoại ngữ đầu ra', value: 'VanBangChungChiDauRa', sortable: false, width: 180 },
					{ text: 'Thời gian cấp đầu ra', value: 'ThoiGianCapDauRa', sortable: false, align: 'center', width: 220 },
				],
			}
		},
		computed: {
			isOpenTotalTotNghiep() {
				return vueData.isOpenTotalTotNghiep
			},
			FilteredDsHocVien() {
				const keyword = (this.search || '').trim().toLowerCase()
	
				if (!keyword) {
					return this.DsHocVien
				}
	
				return this.DsHocVien.filter((item) => {
					const fullName = `${item.Ho_SV || ''} ${item.Ten_SV || ''}`.trim().toLowerCase()
					const studentId = `${item.Student_ID || ''}`.toLowerCase()
	
					return fullName.includes(keyword) || studentId.includes(keyword)
				})
			},
			DsNienKhoa() {
				return this.dsnienkhoa
			},
		},
		watch: {
			isOpenTotalTotNghiep(val) {
				if (val) {
					this.major = [0]
					this.AppliedMajor = []
					this.MultipleKhoaTotNghiep = []
					this.AppliedKhoaTotNghiep = []
					this.MultipleDecisionDot = []
					this.MultipleDecisionSoQD = []
					this.MultipleFilterNienKhoa = [] // Reset bộ lọc niên khóa trên UI
					this.AppliedFilterNienKhoa = [] // Reset bộ lọc niên khóa đã áp dụng
					this.AppliedDecisionDot = []
					this.AppliedDecisionSoQD = []
					this.DecisionDotOptions = []
					this.DecisionSoQDOptions = []
					this.SelectedStudents = []
					this.search = ''
					this.onLoadXetDaTotNghiep(this.major)
				}
			},
			major(val, oldVal) {
				if (!this.isOpenTotalTotNghiep || !val) return
	
				const hadZero = oldVal?.includes(0)
				const hasZero = val.includes(0)
	
				// Case 1: user vừa chọn Tất cả (0)
				if (!hadZero && hasZero) {
					this.major = [0]
					return
				}
	
				// Case 2: đang có Tất cả (0), user chọn thêm cái khác → bỏ 0
				if (hadZero && hasZero && val.length > 1) {
					const newVal = val.filter((v) => v !== 0)
					this.major = newVal
				}
	
				// Nếu chỉ có 0
				if (this.major.length === 1 && this.major[0] === 0) {
					return
				}
			},
			MultipleKhoaTotNghiep(val, oldVal) {
				if (!this.isOpenTotalTotNghiep || !val) return
	
				const allVal = this.allNienKhoaValue
				const hadAll = oldVal?.includes(allVal)
				const hasAll = val.includes(allVal)
	
				if (!hadAll && hasAll) {
					this.MultipleKhoaTotNghiep = [allVal]
					return
				}
	
				if (hadAll && hasAll && val.length > 1) {
					this.MultipleKhoaTotNghiep = val.filter((v) => v !== allVal)
				}
			},
			MultipleDecisionSoQD(val, oldVal) {
				if (!this.isOpenTotalTotNghiep || !val) return
	
				const allVal = this.allDecisionSoQDValue
				const hadAll = oldVal?.includes(allVal)
				const hasAll = val.includes(allVal)
	
				if (!hadAll && hasAll) {
					this.MultipleDecisionSoQD = [allVal]
					return
				}
	
				if (hadAll && hasAll && val.length > 1) {
					this.MultipleDecisionSoQD = val.filter((v) => v !== allVal)
				}
			},
			MultipleFilterNienKhoa(val, oldVal) {
				if (!this.isOpenTotalTotNghiep || !val) return
	
				const allVal = this.allNienKhoaValue
				const hadAll = oldVal?.includes(allVal)
				const hasAll = val.includes(allVal)
	
				// Xử lý chọn độc quyền cho Tất cả: nếu chọn Tất cả thì bỏ các chọn khác
				if (!hadAll && hasAll) {
					this.MultipleFilterNienKhoa = [allVal]
					return
				}
	
				// Bỏ Tất cả nếu đang có Tất cả mà người dùng chọn phần tử khác
				if (hadAll && hasAll && val.length > 1) {
					this.MultipleFilterNienKhoa = val.filter((v) => v !== allVal)
				}
			},
		},
		methods: {
			async onPrintTotalListExcel() {
				this.isLoadingExport = true
				if (!this.SelectedStudents || this.SelectedStudents.length === 0) {
					this.isLoadingExport = false
					return Vue.$toast.error('Vui lòng chọn ít nhất một học viên để xuất danh sách', { position: 'top' })
				}
	
				const dataArr = []
				this.SelectedStudents.forEach((item, index) => {
					const data = {
						STT: index + 1,
						MSHV: item.Student_ID,
						HoHV: item.Ho_SV,
						TenHV: item.Ten_SV,
						NienKhoa: item.Nien_Khoa ?? '',
						NgaySinh: item.NgaySinh ?? '',
						NoiSinh: item.Noi_Sinh ?? '',
						GioiTinh: item.GioiTinh ?? '',
						TenNgoaiNguDauVao: item.TenNgoaiNguDauVao ?? '',
						VanBangChungChiNNDauVao: item.VanBangChungChiNNDauVao ?? '',
						DiemBaoVe: item.DiemHoiDong ?? '',
						SQDLapHoiDong: item.SoQDLapHoiDong ?? '',
						NgayLapHoiDong: item.NgayLapHoiDong ?? '',
						NgayBaoVe: item.ThoiGianBaoVe ? this.formatCustomDate(item.ThoiGianBaoVe) : '',
						TenNgoaiNguDauRa: item.TenNgoaiNguDauRa ?? '',
						VanBangChungChiNNDauRa: item.VanBangChungChiDauRa ?? '',
						ThoiGianCapDauRa: item.ThoiGianCapDauRa ? this.formatCustomDate(item.ThoiGianCapDauRa) : '',
						LopID: item.Lop_ID ?? '',
						Nganh: item.Ten_Nganh ?? '',
						DanToc: item.DanToc ?? '',
						QuocTich: item.QuocTich ?? '',
						CCCD: item.CCCD ?? '',
						NgayCapCCCD: item.NgayCap_CCCD ? this.formatCustomDate(item.NgayCap_CCCD) : '',
						SoDT: item.SoDienThoai ?? '',
						Email: item.Email ?? '',
						DiaChiLienHe: item.DiaChiLienHe ?? '',
						ChucVu: item.ChucVu ?? '',
						DonViCongTac: item.DonViCongTac ?? '',
						MaNganh: item.MaNganh ?? '',
						BoSungKienThuc: item.BoSungKienThuc ?? '',
						CongBoKhoaHoc: item.CongBoKhoaHoc ?? '',
						DiemTBHocTap: null,
						DiemTBTotNghiep: null,
						TenDeTai: item.Thesis_Name ?? '',
						GVHD_1: item.Thesises_Prof1 ?? '',
						GVHD_2: item.Thesises_Prof2 ?? '',
						ChuTich: item.ChuTich ?? '',
						Pb_1: item.Pb_1 ?? '',
						Pb_2: item.Pb_2 ?? '',
						UyVien: item.UyVien ?? '',
						ThuKy: item.ThuKy ?? '',
						So_HoiDongDaoDuc: item.So_HoiDongDaoDuc ?? '',
						TruongDaiHoc: item.Truong_DaiHoc ?? '',
						NganhDaiHoc: item.Nganh_DaiHoc ?? '',
						XepLoai: item.XepLoai ?? '',
						SoQDTotNghiep: item.Decision_SoQD ?? '',
						ThoiGianTotNghiepThacSi: item.NgayLapQuyetDinh ?? '',
						DotTotNghiep: item.Decision_NienKhoa + '.' + item.Decision_Dot,
						SoMonHoc: null,
						ThoiGianTotnghiepDaiHoc: item.ThoiGianTotNghiep_DaiHoc ?? '',
					}
					dataArr.push(data)
				})
	
				const HeSoLuanvan = 15
				const HeSoDoAn = 9
				for (let item of dataArr) {
					const diemArray = await this.onLoadDiemThanhPhan(item.MSHV).then((data) => {
						return data.filter((diemItem) => {
							const monHocID = diemItem?.MonHocID
							if (monHocID === null || monHocID === undefined) {
								return true
							}
	
							// const monHocIDStr = String(monHocID).replace(/\D/g, '')
							// return monHocIDStr.slice(-3) !== '815'
							return true
						})
					})
	
					const monTotNghiep = diemArray.find(item =>
						[HeSoLuanvan, HeSoDoAn].includes(item.HeSo)
					)
	
					const heSoTotNghiep = monTotNghiep?.HeSo ?? HeSoLuanvan
	
					const countMonHoc = diemArray.length
					let totalDtb = diemArray.reduce((sum, itemDiem) => {
						if (![HeSoLuanvan, HeSoDoAn].includes(itemDiem.HeSo)) {
							return sum + itemDiem.DiemTBMon * itemDiem.HeSo
						}
						return sum
					}, 0)
					totalDtb = parseFloat(totalDtb.toFixed(2))
	
					const totalHeSo = diemArray.reduce((sum, itemDiem) => sum + itemDiem.HeSo, 0)
					const parseDiemBaoVe = item.DiemBaoVe ? parseFloat(item.DiemBaoVe) : 0
					const totalDTBTN = totalDtb + parseDiemBaoVe * heSoTotNghiep
	
					console.log("totalHeSo", totalHeSo)
					console.log("parseDiemBaoVe", parseDiemBaoVe)
	
					item.DiemTBHocTap = new Decimal(totalDtb.toString())
						.div(
							new Decimal(totalHeSo.toString())
								.minus(new Decimal(heSoTotNghiep.toString()))
						)
						.toDecimalPlaces(2, Decimal.ROUND_HALF_UP)
						.toString()
					console.log("item.DiemTBHocTap", item.DiemTBHocTap)
					item.SoMonHoc = countMonHoc
					item.DiemTBTotNghiep = new Decimal(totalDTBTN.toString())
						.div(new Decimal(totalHeSo.toString()))
						.toDecimalPlaces(2, Decimal.ROUND_HALF_UP)
						.toString()
				}
	
				const dotXetTotNghiep =
					this.AppliedDecisionDot.length > 0
						? [...this.AppliedDecisionDot]
							.sort((a, b) => {
								const numA = Number(a)
								const numB = Number(b)
	
								if (!Number.isNaN(numA) && !Number.isNaN(numB)) {
									return numA - numB
								}
	
								return String(a).localeCompare(String(b), undefined, { numeric: true, sensitivity: 'base' })
							})
							.join(', ')
						: '...'
				console.log('Dot xét tốt nghiệp:', dotXetTotNghiep)
	
				console.log('dataArr', dataArr)
	
				const findMaNganh = this.NganhGiangDay?.find((item) => item.NganhID == this.major)
				const apiData = {
					Nganh: findMaNganh ? findMaNganh.TenNganh : '',
					MaNganh: findMaNganh ? findMaNganh.MaNganh : '',
					Dot: dotXetTotNghiep,
					DanhSach: dataArr
						.sort((a, b) =>
							a.Nganh.localeCompare(b.Nganh, 'vi') ||
							a.TenHV.localeCompare(b.TenHV, 'vi')
						)
						.map((item, index) => {
							return {
								...item,
								STT: index + 1
							}
						}),
				}
	
				const myHeaders = new Headers()
				myHeaders.append('Content-Type', 'application/json')
				const requestOptions = {
					method: 'POST',
					headers: myHeaders,
					body: JSON.stringify(apiData),
					redirect: 'follow',
				}
	
				// https://gendocx.iotsoftvn.com
				// http://localhost:5244
				fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/xet-tot-nghiep', requestOptions)
					.then((response) => response.blob())
					.then((blob) => {
						const url = window.URL.createObjectURL(blob)
						const a = document.createElement('a')
						a.href = url
						a.download = `Danh sách tổng xét tốt nghiệp.xlsx`
						document.body.appendChild(a)
						a.click()
						a.remove()
						this.isLoadingExport = false
					})
					.catch((error) => {
						console.error(error)
						this.isLoadingExport = false
					})
			},
	
			onLoadDiemThanhPhan(studentID) {
				return new Promise(function (resolve, reject) {
					$.ajax({
						type: 'GET',
						headers: {
							authorization: $awt,
						},
						url: `https://tapi.lhu.edu.vn/mark/MarkViewer_GetBangDiem?studentId=${studentID}`,
						contentType: 'application/json; charset=utf-8',
						dataType: 'json',
						crossDomain: true,
						success: function (res) {
							const data = res.data.map((item, index) => ({
								...item,
								STT: index + 1,
								DiemThanhPhanList: JSON.parse(item.DiemThanhPhan),
							}))
							resolve(data)
						},
						error: function (xhr) {
							reject(xhr.responseJSON.Message)
							$.dialog({
								icon: 'fas fa-exclamation',
								title: 'Error',
								content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
								type: 'red',
								columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
								closeIcon: true,
								buttons: {
									ok: {
										text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
										btnClass: 'btn-blue',
									},
								},
							})
						},
						complete: function () { },
					})
				})
			},
			onLoadXetDaTotNghiep(nganhID) {
				this.isLoading = true
	
				ajaxCALL(
					'/Student_XetTotNghiep_Get',
					{
						Nganh_ID: parseInt(nganhID, 10),
						Flow_Status: 'C',
						TrangThaiTotNghiep: 1,
					},
					(res) => {
						this.DsHocVienRoot = res.data.map((item, index) => ({
							...item,
							STT: index + 1,
							ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
							ThoiGianCapDauRa: item.ThoiGianCapDauRa ? moment(item.ThoiGianCapDauRa).format('DD/MM/YYYY') : item.ThoiGianCapDauRa,
							DiemHoiDong: item.DiemHoiDong ? parseFloat(item.DiemHoiDong).toFixed(1) : '0.0',
						}))
	
						const dsUnique = [...new Set(res.data.map((item) => item.Decision_NienKhoa).filter((v) => v !== null && v !== undefined && v !== ''))]
						this.DsUniqueNienKhoaTotNghiep = [{ TenNienKhoa: '- Tất cả -', NienKhoa: this.allNienKhoaValue }, ...dsUnique.map((item) => ({ TenNienKhoa: item, NienKhoa: item }))]
	
						this.applyClientFilters()
						this.isLoading = false
					},
					(error) => {
						this.isLoading = false
						Vue.$toast.error(`${error.responseJSON?.Message || error}`, { position: 'top' })
						console.log('Fail to load thong ke xet tot nghiep', error)
					},
				)
			},
	
			onApplyFilters() {
				// Đồng bộ UI Check sang trạng thái Applied Filter khi người dùng bấm Lọc
				this.AppliedMajor = [...this.major]
				this.AppliedKhoaTotNghiep = [...this.MultipleKhoaTotNghiep]
				// Đồng bộ filter niên khóa sang trạng thái áp dụng
				this.AppliedFilterNienKhoa = [...this.MultipleFilterNienKhoa]
				this.AppliedDecisionDot = [...this.MultipleDecisionDot]
				this.AppliedDecisionSoQD = [...this.MultipleDecisionSoQD]
	
				this.applyClientFilters()
			},
	
			applyClientFilters() {
				// 1. Phục hồi state check box
				const selectedIds = new Set(this.SelectedStudents.map((item) => item.Student_ID))
				let data = [...this.DsHocVienRoot]
	
				// 1.5. Lọc Ngành
				data = data.filter((item) => {
					let checkNganh = false
					if (!this.AppliedMajor || this.AppliedMajor.length === 0 || this.AppliedMajor.includes(0) || this.AppliedMajor.includes('0')) {
						checkNganh = true
					} else {
						let itemNganhID = item.Nganh_ID !== undefined ? item.Nganh_ID : item.NganhID !== undefined ? item.NganhID : item.Student_Major
						checkNganh = this.AppliedMajor.some((m) => String(m) === String(itemNganhID))
					}
					return checkNganh
				})
	
				// Lọc dữ liệu học viên dựa vào trường Nien_Khoa thực tế
				data = this.filterByCriteria(data, 'Nien_Khoa', this.AppliedFilterNienKhoa, this.allNienKhoaValue)
	
				// 2. Flow lọc Step 1: Lọc Niên Khoá
				data = this.filterByCriteria(data, 'Decision_NienKhoa', this.AppliedKhoaTotNghiep, this.allNienKhoaValue)
	
				// 3. Trích xuất options Đợt & QĐ từ data đã lọc (Cascading effect)
				this.updateDropdownOptions(data)
	
				// 4. Chặn đứng các field Đợt / Số QĐ không hợp lệ trong filter và trên SelectUI
				this.validateSelectedFilters()
	
				// 5. Flow lọc Step 2 & 3: Lọc Đợt và Số QĐ
				data = this.filterByCriteria(data, 'Decision_Dot', this.AppliedDecisionDot, null)
				data = this.filterByCriteria(data, 'Decision_SoQD', this.AppliedDecisionSoQD, this.allDecisionSoQDValue)
	
				// Đánh số STT và cập nhật view
				this.DsHocVien = data.map((item, index) => ({
					...item,
					STT: index + 1,
				}))
				this.SelectedStudents = this.DsHocVien.filter((item) => selectedIds.has(item.Student_ID))
			},
	
			filterByCriteria(data, key, criteriaValues, allValue) {
				if (!criteriaValues || criteriaValues.length === 0) return data
				if (allValue && criteriaValues.includes(allValue)) return data
	
				return data.filter((item) => criteriaValues.includes(this.normalizeFilterValue(item[key])))
			},
	
			updateDropdownOptions(data) {
				this.DecisionDotOptions = this.getUniqueValues(data, 'Decision_Dot')
				const soQDList = this.getUniqueValues(data, 'Decision_SoQD')
	
				this.DecisionSoQDOptions = [{ text: '- Tất cả -', value: this.allDecisionSoQDValue }, ...soQDList.map((v) => ({ text: v, value: v }))]
			},
	
			validateSelectedFilters() {
				// Loại bỏ các Đợt không còn nằm trong danh sách Options hợp lệ
				this.MultipleDecisionDot = this.MultipleDecisionDot.filter((v) => this.DecisionDotOptions.includes(v))
				this.AppliedDecisionDot = this.AppliedDecisionDot.filter((v) => this.DecisionDotOptions.includes(v))
	
				// Loại bỏ các Số QĐ (Khác Tất cả) không còn nằm trong danh sách Options hợp lệ
				const validSoQDs = this.DecisionSoQDOptions.map((o) => o.value)
				this.MultipleDecisionSoQD = this.MultipleDecisionSoQD.filter((v) => validSoQDs.includes(v))
				this.AppliedDecisionSoQD = this.AppliedDecisionSoQD.filter((v) => validSoQDs.includes(v))
			},
	
			getUniqueValues(data, key) {
				const valueSet = new Set()
				data.forEach((item) => {
					const val = this.normalizeFilterValue(item[key])
					if (val) valueSet.add(val)
				})
				return Array.from(valueSet)
			},
	
			normalizeFilterValue(value) {
				if (value === null || value === undefined) {
					return ''
				}
				return String(value).trim()
			},
	
			formatCustomDate(dateStr) {
				const date = moment(dateStr, ['YYYY-MM-DD', 'DD/MM/YYYY', moment.ISO_8601], true)
	
				if (!date.isValid()) {
					return dateStr
				}
	
				return date.format('DD/MM/YYYY')
			},
	
			closeDialog() {
				this.major = [0]
				this.AppliedMajor = []
				this.MultipleKhoaTotNghiep = []
				this.AppliedKhoaTotNghiep = []
				this.MultipleDecisionDot = []
				this.MultipleDecisionSoQD = []
				this.MultipleFilterNienKhoa = [] // Reset UI filter
				this.AppliedFilterNienKhoa = [] // Reset applied filter
				this.AppliedDecisionDot = []
				this.AppliedDecisionSoQD = []
				this.DecisionDotOptions = []
				this.DecisionSoQDOptions = []
				this.search = ''
				vueData.isOpenTotalTotNghiep = false
			},
		},
	}
</script>