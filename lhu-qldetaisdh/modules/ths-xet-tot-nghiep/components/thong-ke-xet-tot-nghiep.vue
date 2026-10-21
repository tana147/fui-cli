<template>
	<div>
		<div>
			<h3 class="mb-3 primary--text">
				<b>Bộ lọc dữ liệu</b>
			</h3>
			<v-row dense class="mb-3">
				<v-col cols="2">
					<v-autocomplete v-model="major" multiple small-chips :items="NganhGiangDay" outlined dense
						hide-details label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID" />
				</v-col>

				<v-col cols="2">
					<v-autocomplete v-model="MultipleNienKhoa" :items="DsNienKhoa" item-text="TenNienKhoa"
						item-value="NienKhoa" outlined multiple dense chips small-chips hide-details clearable
						placeholder="Chọn niên khóa" label="Niên khóa" />
				</v-col>

				<v-col>
					<v-btn color="primary" @click="applyLocalFilters">
						<v-icon left>mdi-filter</v-icon> Lọc
					</v-btn>
				</v-col>
			</v-row>
		</div>

		<div>
			<h3 class="mb-3 primary--text">
				<b>Thống kê xét tốt nghiệp</b>
			</h3>
			<v-row dense class="mb-3" justify="start">
				<v-col cols="12" sm="4" md="2">
					<f-date v-model="formData.NgayDanhGiaTotNghiep" label="* Ngày đánh giá tốt nghiệp" dense outlined
						hide-details class="export-input" />
				</v-col>

				<v-col cols="12" sm="4" md="1">
					<v-text-field v-model="formData.Dot" label="* Đợt" dense outlined hide-details class="export-input"
						prepend-inner-icon="mdi-calendar-star" />
				</v-col>

				<v-col cols="12" sm="4" md="2" class="d-flex">
					<v-btn @click="onPrintExcel" color="success" block class="export-btn">
						<v-icon left>mdi-microsoft-excel</v-icon>
						Xuất file đánh giá tốt nghiệp
					</v-btn>
				</v-col>

				<v-col cols="12" sm="4" md="2" class="d-flex">
					<v-btn @click="openQDTotNghiep" color="primary" block class="export-btn export-btn--docx">
						<v-icon left>mdi-microsoft-word</v-icon>
						Quyết định công nhận tốt nghiệp
					</v-btn>
				</v-col>

				<v-col cols="12" sm="4" md="2" class="d-flex">
					<v-btn @click="openTotalTotNghiep" color="warning" block class="export-btn">
						<v-icon left>mdi-format-list-bulleted-square</v-icon>
						Xuất danh sách tổng
					</v-btn>
				</v-col>
			</v-row>
		</div>

		<v-card outlined class="mt-5">
			<v-card-title class="primary--text">
				{{ labelTable }}
				<v-spacer />
				<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm mã học viên..."
					single-line hide-details dense style="max-width: 400px" />
			</v-card-title>
			<v-data-table class="table-frozen-cols" item-key="STT" v-model="selectedItems" show-select
				:items="DsXetTotNghiep" :headers="tableHeader" :search="search" dense items-per-page="-1"
				:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
				<template v-slot:item.HoTenMaSV="{ item }">
					<span class="primary--text">
						<b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
					</span>
					<br />
					<b>{{ item.Student_ID }}</b>
					<span class="amber--text"> [{{ item.Lop_ID }}]</span>
				</template>

				<template v-slot:item.FileChungChiNgoaiNguID="{ item }">
					<div v-if="item.FileChungChiNgoaiNguID">
						<v-chip label outlined class="mb-3" color="deep-purple accent-4">
							<v-icon left>mdi-file-check-outline</v-icon>
							<a :href="vueData.v_Set.urlReadFile + 'FileData/' + item.FileChungChiNgoaiNguID"
								target="_blank">Văn bằng/Chứng chỉ</a>
						</v-chip>
					</div>

					<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload file </v-chip>
				</template>

				<template v-slot:item.DiemHoiDong="{ item }">
					<v-chip small label color="amber lighten-5" text-color="amber darken-4">
						{{ item.DiemHoiDong }}
					</v-chip>
				</template>
			</v-data-table>
		</v-card>

		<dialog-quyet-dinh-tot-nghiep :nganhgiangday="NganhGiangDay" :multiplenienkhoa="MultipleNienKhoa"
			:dsnienkhoa="DsNienKhoa" />
		<dialog-tong-tot-nghiep :nganhgiangday="NganhGiangDay" :multiplenienkhoa="MultipleNienKhoa"
			:dsnienkhoa="DsNienKhoa" />
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				isExportCongNhan: false,
				major: [0],
				multipleMajor: [],
				heArr: [],
				MultipleNienKhoa: [],
				allNienKhoaValue: '__ALL__',
				DsXetTotNghiep: [],
				DsXetTotNghiepRoot: [],
				DsNienKhoa: [],
				NganhGiangDay: [],
				selectedItems: [],
				search: '',
	
				formData: {
					SQDTotNghiep: '.../QĐ-ĐHLH',
					NgayXetTotNghiep: null,
					NgayDanhGiaTotNghiep: null,
					Dot: '1',
				},
				DanhSachMonTotNghiep: [],
	
				tableHeader: [
					{
						text: 'STT',
						value: 'STT',
						sortable: false,
						align: 'center',
						width: 60,
					},
					{
						text: 'Học viên',
						value: 'HoTenMaSV',
						width: 200,
					},
					{
						text: 'Niên khóa',
						value: 'Nien_Khoa',
						sortable: false,
						align: 'center',
						width: 110,
					},
					{
						text: 'Tên ngành',
						value: 'Ten_Nganh',
						sortable: false,
						width: 200,
					},
					{
						text: 'Tên đề tài',
						value: 'Thesis_Name',
						sortable: false,
						width: 500,
					},
					{
						text: 'GVHD 1',
						value: 'Thesises_Prof1',
						sortable: false,
						width: 180,
					},
					{
						text: 'GVHD 2',
						value: 'Thesises_Prof2',
						sortable: false,
						width: 180,
					},
					{
						text: 'Số QĐ lập hội đồng',
						value: 'SoQDLapHoiDong',
						sortable: false,
						align: 'center',
						width: 180,
					},
					{
						text: 'Thời gian bảo vệ',
						value: 'ThoiGianBaoVe',
						sortable: false,
						align: 'center',
						width: 130,
					},
					{
						text: 'Điểm hội đồng',
						value: 'DiemHoiDong',
						sortable: false,
						align: 'center',
						width: 160,
					},
					{
						text: 'Tên ngoại ngữ đầu vào',
						value: 'TenNgoaiNguDauVao',
						sortable: false,
						width: 190,
					},
					{
						text: 'Tên ngoại ngữ đầu ra',
						value: 'TenNgoaiNguDauRa',
						sortable: false,
						width: 180,
					},
					{
						text: 'Văn bằng/chứng chỉ ngoại ngữ đầu ra',
						value: 'VanBangChungChiDauRa',
						sortable: false,
						width: 180,
					},
					{
						text: 'Thời gian cấp đầu ra',
						value: 'ThoiGianCapDauRa',
						sortable: false,
						width: 220,
					},
				],
			}
		},
		mounted() {
			this.getNienKhoa()
			this.onLoadXetTotNghiep(this.major, 'C', 0)
			this.onLoadNganh()
			// Tạm ngưng gọi API cấu hình môn tốt nghiệp theo ngành (data đang thiếu ở nhiều ngành).
			// Môn tốt nghiệp được xác định trực tiếp từ bảng điểm SV: môn có Hệ số >= 9.
			// this.onLoadDanhSachMonTotNghiep()
		},
		computed: {
			labelTable() {
				const total = this.DsXetTotNghiep.length
				const selected = this.selectedItems.length
				return `Danh sách học viên (${total})${selected > 0 ? ` - Đã chọn (${selected})` : ''}`
			},
		},
		watch: {
			major(val, oldVal) {
				if (!val) return
	
				const hadZero = oldVal?.includes(0)
				const hasZero = val.includes(0)
	
				// Case 1: user vừa chọn Tất cả (0)
				if (!hadZero && hasZero) {
					this.major = [0]
					return
				}
	
				// Case 2: đang có Tất cả (0), user chọn thêm cái khác → bỏ Tất cả (0)
				if (hadZero && hasZero && val.length > 1) {
					const newVal = val.filter((v) => v !== 0)
					this.major = newVal
				}
	
				// Nếu chỉ có 0
				if (this.major.length === 1 && this.major[0] === 0) {
					return
				}
			},
			MultipleNienKhoa(val, oldVal) {
				if (!val) return
	
				const allVal = this.allNienKhoaValue
				const hadAll = oldVal?.includes(allVal)
				const hasAll = val.includes(allVal)
	
				if (!hadAll && hasAll) {
					this.MultipleNienKhoa = [allVal]
					return
				}
	
				if (hadAll && hasAll && val.length > 1) {
					this.MultipleNienKhoa = val.filter((v) => v !== allVal)
				}
			},
		},
		methods: {
			applyLocalFilters() {
				this.DsXetTotNghiep = this.DsXetTotNghiepRoot.filter((item) => {
					// Kiểm tra Ngành
					let checkNganh = false
					if (!this.major || this.major.length === 0 || this.major.includes(0) || this.major.includes('0')) {
						checkNganh = true
					} else {
						let itemNganhID = item.Nganh_ID !== undefined ? item.Nganh_ID : item.NganhID !== undefined ? item.NganhID : item.Student_Major
						checkNganh = this.major.some((m) => String(m) === String(itemNganhID))
					}
	
					// Kiểm tra Niên khóa
					let checkNienKhoa = false
					if (!this.MultipleNienKhoa || this.MultipleNienKhoa.length === 0 || this.MultipleNienKhoa.includes(this.allNienKhoaValue)) {
						checkNienKhoa = true
					} else {
						checkNienKhoa = this.MultipleNienKhoa.includes(item.Nien_Khoa)
					}
	
					return checkNganh && checkNienKhoa
				})
	
				this.resetSTT()
			},
	
			resetSTT() {
				this.DsXetTotNghiep = this.DsXetTotNghiep.map((item, index) => ({
					...item,
					STT: index + 1,
				}))
			},
	
			onLoadDanhSachMonTotNghiep() {
				const $this = this
				$.ajax({
					type: 'GET',
					headers: {
						authorization: $awt,
					},
					url: `https://tapi.lhu.edu.vn/hoso/SDH_GetDanhSachMonTotNghiep`,
					contentType: 'application/json; charset=utf-8',
					dataType: 'json',
					crossDomain: true,
					success: function (res) {
						$this.DanhSachMonTotNghiep = res.data
					},
					error: function (xhr, ajaxOptions, thrownError) {
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
				})
			},
	
			async onLoadNganh() {
				this.NganhGiangDay = await getNganhCaoHocPromise({ hasAllOption: true });
			},
	
			openQDTotNghiep() {
				vueData.isOpenQDTotNghiep = true
			},
	
			openTotalTotNghiep() {
				vueData.isOpenTotalTotNghiep = true
			},
	
			openExportCongNhan() {
				this.formData = {
					SQDTotNghiep: '.../QĐ-ĐHLH',
					NgayXetTotNghiep: null,
					Dot: '1',
				}
	
				this.isExportCongNhan = !this.isExportCongNhan
			},
	
			nganhName(nganhid) {
				const nganh = this.NganhGiangDay.find((item) => item.NganhID === nganhid)
				return nganh ? nganh.TenNganh?.toUpperCase() : ''
			},
			multiNganhName() {
				return this.heArr
					.filter((item) => this.multipleMajor.includes(item.NganhID))
					.map((item) => item.TenNganh)
					.join(', ')
			},
			multiMaNganh() {
				return this.heArr
					.filter((item) => this.multipleMajor.includes(item.NganhID))
					.map((item) => item.MaNganh)
					.join(', ')
			},
			formatCustomDate(dateStr) {
				const m = moment(dateStr, ['YYYY-MM-DD', 'DD/MM/YYYY'])
				const day = m.format('DD')
				const year = m.format('YYYY')
				let month = m.month() + 1
	
				if (month === 1 || month === 2) {
					month = `0${month}`
				}
				return `${day}/${month}/${year}`
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
							const data = res.data.map((item, index) => {
								return {
									...item,
									STT: index + 1,
									DiemThanhPhanList: JSON.parse(item.DiemThanhPhan),
								}
							})
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
	
			getNienKhoa() {
				const $this = this
				$.ajax({
					type: 'GET',
					headers: {
						authorization: $awt,
					},
					url: `https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa`,
					contentType: 'application/json; charset=utf-8',
					dataType: 'json',
					crossDomain: true,
					success: function (res) {
						// Thêm bình luận giải thích chức năng: Load DS niên khóa và chèn cứng "- Tất cả -" lên đầu ds
						const mappedData = res.data.map((item) => {
							return {
								...item,
								TenNienKhoa: item.NienKhoa,
								NienKhoa: item.NienKhoa,
							}
						})
						$this.DsNienKhoa = [{ TenNienKhoa: '- Tất cả -', NienKhoa: $this.allNienKhoaValue }, ...mappedData]
					},
					error: function (xhr) {
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
				})
			},
	
			onLoadXetTotNghiep(nganhID, trangThai, TrangThaiTotNghiep) {
				this.selectedItems = []
				ajaxCALL(
					'/Student_XetTotNghiep_Get',
					{
						Nganh_ID: parseInt(nganhID, 10),
						Flow_Status: trangThai,
						TrangThaiTotNghiep: TrangThaiTotNghiep,
					},
					(res) => {
						this.DsXetTotNghiep = res.data.map((item, index) => {
							return {
								...item,
								STT: index + 1,
								ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
								ThoiGianCapDauRa: item.ThoiGianCapDauRa ? moment(item.ThoiGianCapDauRa).format('DD/MM/YYYY') : item.ThoiGianCapDauRa,
								DiemHoiDong: item.DiemHoiDong ? parseFloat(item.DiemHoiDong).toFixed(1) : '0.0',
								TrangThaiChungChi: item.TenNgoaiNguDauVao && item.TenNgoaiNguDauRa ? '1' : '2',
								HoTenMaSV: item.Ho_SV + ' ' + item.Ten_SV + ' ' + item.Student_ID + ' ' + item.Lop_ID,
							}
						})
	
						this.DsXetTotNghiepRoot = this.DsXetTotNghiep.map((item) => ({ ...item }))
						this.applyLocalFilters()
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON?.Message || error}`, { position: 'top' })
						console.log('Fail to load thong ke xet tot nghiep', error)
					},
				)
			},
	
			// (applyNienKhoaFilter đã được gộp chung vào applyLocalFilters)
			// Tạm ngưng dùng API DanhSachMonTotNghiep (data thiếu ở nhiều ngành).
			// Môn tốt nghiệp/luận văn giờ được xác định thẳng từ bảng điểm SV trong onPrintExcel: môn nào Hệ số >= 9.

			async onPrintExcel() {
				console.log(this.selectedItems)
				if (!this.formData.NgayDanhGiaTotNghiep) {
					return Vue.$toast.error(`Vui lòng chọn ngày đánh giá tốt nghiệp`, { position: 'top' })
				}
	
				if (!this.formData.Dot) {
					return Vue.$toast.error(`Vui lòng chọn đợt đánh giá tốt nghiệp`, { position: 'top' })
				}
	
				if (this.selectedItems.length === 0) {
					return Vue.$toast.error(`Vui lòng chọn ít nhất 1 dữ liệu để xuất`, { position: 'top' })
				}
	
				const dateList = this.formData.NgayDanhGiaTotNghiep.split('-')
				const day = dateList[2]
				const month = dateList[1]
				const year = dateList[0]
	
				const dataArr = []
				this.selectedItems.forEach((item, index) => {
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
						VanBangChungChiNNDauVao: item.NgoaiNgu_DauVao ?? '',
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
						SoMonHoc: null,
					}
					dataArr.push(data)
				})
				for (const item of dataArr) {
					const diemArray = await this.onLoadDiemThanhPhan(item.MSHV)
					const parseDiemBaoVe = item.DiemBaoVe ? parseFloat(item.DiemBaoVe) : 0
	
					let diemHocTap = 0, heSoHocTap = 0
					let diemLuanVan = 0, heSoLuanVan = 0

					// Tạm thời: môn tốt nghiệp/luận văn là môn trong bảng điểm SV có Hệ số >= 9
					diemArray.forEach(d => {
						const isMonTotNghiep = Number(d.HeSo) >= 9

						if (isMonTotNghiep) {
							diemLuanVan += parseDiemBaoVe * d.HeSo
							heSoLuanVan += d.HeSo
						} else {
							diemHocTap += (d.DiemTBMon || 0) * d.HeSo
							heSoHocTap += d.HeSo
						}
					})

					item.SoMonHoc = diemArray.length
	
					// Tính Điểm TB Học Tập (Chỉ lấy môn thường)
					item.DiemTBHocTap = heSoHocTap > 0
						? new Decimal(diemHocTap).div(heSoHocTap).toDecimalPlaces(2, Decimal.ROUND_HALF_UP).toString()
						: "0"
	
					// Tính Điểm TB Tốt Nghiệp (Học tập + Luận văn)
					const tongHeSoTN = heSoHocTap + heSoLuanVan
					item.DiemTBTotNghiep = tongHeSoTN > 0
						? new Decimal(diemHocTap + diemLuanVan).div(tongHeSoTN).toDecimalPlaces(2, Decimal.ROUND_HALF_UP).toString()
						: "0"
				}
	
				const findMaNganh = this.NganhGiangDay.find((item) => item.NganhID == this.major)
	
				const apiData = {
					Nganh: findMaNganh ? findMaNganh.TenNganh : '',
					MaNganh: findMaNganh ? findMaNganh.MaNganh : '',
					Dot: this.formData.Dot,
					Ngay: day,
					Thang: month,
					Nam: year,
					DanhSach: dataArr.sort((a, b) => a.TenHV.localeCompare(b.TenHV, 'vi'))
						.map((item, index) => {
							return {
								...item,
								STT: index + 1
							}
						}),
				}
	
				const headers = new Headers()
				headers.append('Content-Type', 'application/json')
	
				const requestOptions = {
					method: 'POST',
					headers: headers,
					body: JSON.stringify(apiData),
				}
	
				try {
					// https://gendocx.iotsoftvn.com
					// http://localhost:5244
					const link = 'https://gendocx.iotsoftvn.com'
					const [file1, file2] = await Promise.all([fetch(`${link}/api/generate-xlsx/trich-ngang-tot-nghiep`, requestOptions), fetch(`${link}/api/generate-xlsx/phieu-danh-gia-tot-nghiep`, requestOptions)])
	
					const blob1 = await file1.blob()
					const blob2 = await file2.blob()
	
					const zip = new JSZip()
	
					zip.file('Danh sách trích ngang.xlsx', blob1)
					zip.file('Phiếu đánh giá tốt nghiệp.xlsx', blob2)
	
					const zipBlob = await zip.generateAsync({ type: 'blob' })
	
					const url = window.URL.createObjectURL(zipBlob)
					const a = document.createElement('a')
					a.href = url
					a.download = 'Xét tốt nghiệp.zip'
					document.body.appendChild(a)
					a.click()
					a.remove()
				} catch (err) {
					Vue.$toast.error(`${err}`, { position: 'top' })
					console.error(err)
				}
			},
		},
	}
</script>