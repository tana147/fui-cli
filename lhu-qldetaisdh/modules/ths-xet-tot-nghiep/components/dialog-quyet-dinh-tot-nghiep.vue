<template>
	<v-dialog v-model="vueData.isOpenQDTotNghiep" persistent eager transition="dialog-bottom-transition"
		max-width="1400px">
		<v-card class="qdt-dialog">
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<div class="mb-0 primary--text">Quyết định công nhận tốt nghiệp</div>
				</template>
			</c-toolbar>

			<v-card-text class="qdt-dialog__body">
				<v-sheet color="transparent">
					<h3 class="mb-3 primary--text">
						Bộ lọc dữ liệu
					</h3>
					<v-row dense class="mt-3">
						<v-col cols="12" md="4">
							<v-autocomplete v-model="major" :items="nganhgiangday" outlined dense hide-details
								label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID" class="qdt-input"
								multiple chips small-chips prepend-inner-icon="mdi-shape-outline" />
						</v-col>

						<v-col cols="12" md="3">
							<v-autocomplete v-model="MultipleNienKhoa" :items="dsnienkhoa" item-text="TenNienKhoa"
								item-value="NienKhoa" multiple outlined dense hide-details clearable chips small-chips
								label="Lọc theo niên khóa" class="qdt-input"
								prepend-inner-icon="mdi-calendar-multiple" />
						</v-col>

						<v-col cols="12" md="3">
							<v-btn @click="applyFilters" color="primary"><v-icon left>mdi-filter</v-icon>Lọc</v-btn>
						</v-col>
					</v-row>

					<h3 class="mt-3 primary--text">
						Thông tin quyết định tốt nghiệp
					</h3>
					<v-row dense class="mt-3">
						<v-col cols="12" md="2">
							<f-date v-model="formData.NgayLapQDTotNghiep" label="* Ngày lập QĐ tốt nghiệp" dense
								outlined hide-details class="qdt-input" />
						</v-col>

						<v-col cols="12" md="2">
							<v-text-field v-model="formData.SQDTotNghiep" dense outlined hide-details
								label="* Số QĐ tốt nghiệp" class="qdt-input"
								prepend-inner-icon="mdi-file-document-outline" />
						</v-col>

						<v-col cols="12" md="4">
							<v-text-field v-model="formData.TieuDe" dense outlined hide-details label="* Tiêu đề"
								class="qdt-input" prepend-inner-icon="mdi-counter" />
						</v-col>
					</v-row>
				</v-sheet>

				<v-sheet rounded="xl" class="qdt-table-wrap pa-2 pa-md-3">
					<v-card-title class="primary--text">
						Danh sách học viên ({{ DsXetTotNghiep.length }})
						<v-spacer></v-spacer>
						<v-text-field v-model="search" dense hide-details clearable prepend-inner-icon="mdi-magnify"
							label="Tên học viên, mã học viên" class="qdt-search" />
					</v-card-title>
					<v-data-table class="table-frozen-cols" v-model="SelectedStudents" :headers="tableHeader"
						:items="FilteredDsXetTotNghiep" :loading="isLoading"
						loading-text="Đang tải danh sách xét tốt nghiệp..." no-data-text="Chưa có dữ liệu học viên"
						fixed-header height="320" dense show-select item-key="Student_ID" :items-per-page="50"
						:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
						<template v-slot:item.STT="{ item, index }">
							<span>{{ index + 1 }}</span>
						</template>

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

				<div>
					<v-text-field v-model="formData.NamTotNghiep" dense outlined hide-details label="* Năm tốt nghiệp"
						class="qdt-input" prepend-inner-icon="mdi-calendar-check-outline" />
				</div>

				<div>
					<v-text-field v-model="formData.Dot" dense outlined hide-details label="* Đợt xét" class="qdt-input"
						prepend-inner-icon="mdi-format-list-numbered" />
				</div>

				<v-menu offset-y left>
					<template v-slot:activator="{ on, attrs }">
						<v-btn color="success" dark v-bind="attrs" v-on="on" :loading="isLoading"
							:disabled="isExportDisabled" class="px-4">
							<v-icon left>mdi-file-document-outline</v-icon>
							Tùy chọn
							<v-icon right>mdi-chevron-down</v-icon>
						</v-btn>
					</template>

					<v-list class="py-1">
						<v-list-item @click="onPrintAndRecognize">
							<v-list-item-icon>
								<v-icon color="primary">mdi-file-word-box</v-icon>
							</v-list-item-icon>
							<v-list-item-content>
								<v-list-item-title>Xuất quyết định & công nhận tốt nghiệp</v-list-item-title>
							</v-list-item-content>
						</v-list-item>

						<!-- Thêm thuộc tính disabled để chống click nhiều lần và chuyển thành icon progress khi đang export -->
						<v-list-item @click="onPrintDocx" :disabled="isLoadingExport">
							<v-list-item-icon>
								<v-progress-circular v-if="isLoadingExport" indeterminate size="24"
									color="teal"></v-progress-circular>
								<v-icon v-else color="teal">mdi-printer-outline</v-icon>
							</v-list-item-icon>
							<v-list-item-content>
								<v-list-item-title>Chỉ xuất quyết định</v-list-item-title>
							</v-list-item-content>
						</v-list-item>

						<v-list-item @click="onAddSQDAndUpdate">
							<v-list-item-icon>
								<v-icon color="success">mdi-check-decagram-outline</v-icon>
							</v-list-item-icon>
							<v-list-item-content>
								<v-list-item-title>Công nhận tốt nghiệp</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
					</v-list>
				</v-menu>
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
				MultipleNienKhoa: [],
				AppliedNienKhoa: [],
				allNienKhoaValue: '__ALL__',
				SelectedStudents: [],
				DsXetTotNghiep: [],
				DsXetTotNghiepRoot: [],
				DsTotNghiepOriginal: [],
				isLoading: false,
				search: '',
	
				formData: {
					TieuDe: 'Về việc công nhận tốt nghiệp và cấp bằng thạc sĩ',
					NgayLapQDTotNghiep: null,
					SQDTotNghiep: '.../QĐ-ĐHLH',
					Dot: null,
					NamTotNghiep: '',
				},
	
				tableHeader: [
					{ text: 'STT', value: 'STT', sortable: false, align: 'center', width: 60 },
					{ text: 'Học viên', value: 'Student_ID', width: 200 },
					{ text: 'Niên khóa', value: 'Nien_Khoa', sortable: false, align: 'center', width: 110 },
					{ text: 'Tên ngành', value: 'Ten_Nganh', width: 200 },
					{ text: 'Tên đề tài', value: 'Thesis_Name', width: 500 },
					{ text: 'GVHD 1', value: 'Thesises_Prof1', width: 180 },
					{ text: 'GVHD 2', value: 'Thesises_Prof2', width: 180 },
					{ text: 'Số QĐ lập hội đồng', value: 'SoQDLapHoiDong', sortable: false, align: 'center', width: 180 },
					{ text: 'Thời gian bảo vệ', value: 'ThoiGianBaoVe', sortable: false, align: 'center', width: 130 },
					{ text: 'Điểm hội đồng', value: 'DiemHoiDong', sortable: false, align: 'center', width: 160 },
					{ text: 'Tên ngoại ngữ đầu vào', value: 'TenNgoaiNguDauVao', width: 190 },
					{ text: 'Tên ngoại ngữ đầu ra', value: 'TenNgoaiNguDauRa', width: 180 },
					{ text: 'Văn bằng/chứng chỉ ngoại ngữ đầu ra', value: 'VanBangChungChiDauRa', width: 180 },
					{ text: 'Thời gian cấp đầu ra', value: 'ThoiGianCapDauRa', width: 220 },
				],
			}
		},
		computed: {
			isOpenQDTotNghiep() {
				return vueData.isOpenQDTotNghiep
			},
			selectedNienKhoaText() {
				if (!this.AppliedNienKhoa.length) {
					return 'Tất cả niên khóa'
				}
	
				return this.AppliedNienKhoa.join(', ')
			},
			isExportDisabled() {
				return this.isLoading || this.DsXetTotNghiep.length === 0
			},
			FilteredDsXetTotNghiep() {
				const keyword = (this.search || '').trim().toLowerCase()
	
				if (!keyword) {
					return this.DsXetTotNghiep
				}
	
				return this.DsXetTotNghiep.filter((item) => {
					const fullName = `${item.Ho_SV || ''} ${item.Ten_SV || ''}`.trim().toLowerCase()
					const studentId = `${item.Student_ID || ''}`.toLowerCase()
	
					return fullName.includes(keyword) || studentId.includes(keyword)
				})
			},
		},
		watch: {
			isOpenQDTotNghiep(val) {
				if (val) {
					this.MultipleNienKhoa = []
					this.AppliedNienKhoa = []
					this.SelectedStudents = []
					this.search = ''
					this.onLoadXetTotNghiep(this.major)
				}
			},
			major(val, oldVal) {
				if (!this.isOpenQDTotNghiep || !val) return
	
				const hadZero = oldVal?.includes(0)
				const hasZero = val.includes(0)
	
				// Case 1: user vừa chọn 0
				if (!hadZero && hasZero) {
					this.major = [0]
					return
				}
	
				// Case 2: đang có 0, user chọn thêm cái khác → bỏ 0
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
				if (!this.isOpenQDTotNghiep || !val) return
	
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
			applyFilters() {
				const selectedStudentIds = new Set(this.SelectedStudents.map((item) => item.Student_ID))
				let data = [...this.DsTotNghiepOriginal]
	
				const filterConfigs = [
					{
						key: 'major',
						values: this.major || [],
						isAll: (values) => values.includes(0),
						match: (item, values) => {
							let itemNganhID = item.Nganh_ID !== undefined ? item.Nganh_ID : item.NganhID !== undefined ? item.NganhID : item.Student_Major
							return values.some((v) => String(v) === String(itemNganhID))
						},
					},
					{
						key: 'nienKhoa',
						values: this.MultipleNienKhoa || [],
						isAll: (values) => values.includes('__ALL__'),
						match: (item, values) => values.includes(item.Nien_Khoa),
					},
				]
	
				data = data.filter((item) => {
					return filterConfigs.every((config) => {
						const values = config.values
	
						if (!values.length) return true
						if (config.isAll(values)) return true
	
						return config.match(item, values)
					})
				})
	
				// Đánh lại STT và phục hồi selection
				this.DsXetTotNghiep = data.map((item, index) => ({
					...item,
					STT: index + 1,
				}))
	
				this.SelectedStudents = this.DsXetTotNghiep.filter((item) => selectedStudentIds.has(item.Student_ID))
			},
	
			onLoadXetTotNghiep(nganhID) {
				this.isLoading = true
	
				ajaxCALL(
					'/Student_XetTotNghiep_Get',
					{
						Nganh_ID: nganhID.length > 0 ? nganhID.join(',') : '0',
						Flow_Status: 'C',
						TrangThaiTotNghiep: 0,
					},
					(res) => {
						this.DsXetTotNghiepRoot = res.data.map((item, index) => ({
							...item,
							STT: index + 1,
							ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
							ThoiGianCapDauRa: item.ThoiGianCapDauRa ? moment(item.ThoiGianCapDauRa).format('DD/MM/YYYY') : item.ThoiGianCapDauRa,
							DiemHoiDong: item.DiemHoiDong ? parseFloat(item.DiemHoiDong).toFixed(1) : '0.0',
						}))
	
						this.DsTotNghiepOriginal = res.data.map((item, index) => ({
							...item,
							STT: index + 1,
							ThoiGianBaoVe: item.ThoiGianBaoVe ? moment(item.ThoiGianBaoVe).format('DD/MM/YYYY') : item.ThoiGianBaoVe,
							ThoiGianCapDauRa: item.ThoiGianCapDauRa ? moment(item.ThoiGianCapDauRa).format('DD/MM/YYYY') : item.ThoiGianCapDauRa,
							DiemHoiDong: item.DiemHoiDong ? parseFloat(item.DiemHoiDong).toFixed(1) : '0.0',
						}))
						this.applyFilters()
						this.isLoading = false
					},
					(error) => {
						this.isLoading = false
						Vue.$toast.error(`${error.responseJSON?.Message || error}`, { position: 'top' })
						console.log('Fail to load thong ke xet tot nghiep', error)
					},
				)
			},
			formatCustomDate(dateStr) {
				const date = moment(dateStr, ['YYYY-MM-DD', 'DD/MM/YYYY', moment.ISO_8601], true)
	
				if (!date.isValid()) {
					return dateStr
				}
	
				return date.format('DD/MM/YYYY')
			},
	
			onAddSQD() {
				return new Promise((resolve, reject) => {
					const studentIds = this.SelectedStudents.map((item) => ({ StudentID: item.Student_ID }))
					const splitDate = this.formData.NgayLapQDTotNghiep.split('-')
					const ngay = splitDate[2]
					const thang = splitDate[1]
					const nam = splitDate[0]
	
					this.isLoading = true
	
					ajaxCALL(
						'/Decision_Graduate_Ins',
						{
							JsonStudentData: JSON.stringify(studentIds),
							Decision_SoQD: this.formData.SQDTotNghiep,
							Decision_NgayQD: ngay,
							Decision_ThangQD: thang,
							Decision_NamQD: nam,
							Decision_TieuDe: this.formData.TieuDe,
							Decision_Dot: this.formData.Dot,
							Decision_NganhID: this.major,
							Decision_NienKhoa: this.formData.NamTotNghiep,
						},
						() => {
							Vue.$toast.success('Tạo quyết định tốt nghiệp thành công', { position: 'top' })
							this.isLoading = false
							resolve()
						},
						(error) => {
							this.isLoading = false
							Vue.$toast.error(`${error.responseJSON?.Message || error}`, { position: 'top' })
							console.log('Fail to tao quyet dinh tot nghiep', error)
							reject(error)
						},
					)
				})
			},
	
			onUpdateTotNghiep() {
				if (!this.onValidate()) {
					return
				}
	
				return new Promise((resolve, reject) => {
					const studentIds = this.SelectedStudents.map((item) => ({ StudentID: item.Student_ID }))
	
					this.isLoading = true
	
					ajaxCALL(
						'/StudentInfo_CongNhanTotNghiep_Update',
						{
							JsonStudentID: JSON.stringify(studentIds),
						},
						() => {
							Vue.$toast.success('Công nhận tốt nghiệp thành công', { position: 'top' })
							this.onLoadXetTotNghiep(0)
							this.isLoading = false
							resolve()
						},
						(error) => {
							this.isLoading = false
							Vue.$toast.error(`${error.responseJSON?.Message || error}`, { position: 'top' })
							console.log('Fail to update cong nhan tot nghiep', error)
							reject(error)
						},
					)
				})
			},
	
			onValidate() {
				const sqd = this.formData.SQDTotNghiep?.trim()
	
				if (!this.formData.NgayLapQDTotNghiep) {
					Vue.$toast.error('Vui lòng chọn ngày lập quyết định tốt nghiệp', { position: 'top' })
					return false
				}
				if (!sqd) {
					Vue.$toast.error('Vui lòng nhập số quyết định tốt nghiệp', { position: 'top' })
					return false
				}
				// Check phải nhập SQĐ và buộc phải bỏ dấu ...
				if (sqd.includes('...') || !/^\d+/.test(sqd)) {
					Vue.$toast.error('Vui lòng nhập số quyết định hợp lệ', { position: 'top' })
					return false
				}
				if (!this.formData.NamTotNghiep) {
					Vue.$toast.error('Vui lòng nhập năm tốt nghiệp', { position: 'top' })
					return false
				}
				if (!this.formData.Dot) {
					Vue.$toast.error('Vui lòng nhập đợt xét tốt nghiệp', { position: 'top' })
					return false
				}
				if (this.DsXetTotNghiep.length === 0) {
					Vue.$toast.error('Không có dữ liệu để xuất quyết định', { position: 'top' })
					return false
				}
				if (this.SelectedStudents.length === 0) {
					Vue.$toast.error('Vui lòng chọn ít nhất 1 học viên', { position: 'top' })
					return false
				}
				return true
			},
	
			async onPrintAndRecognize() {
				if (!this.onValidate()) {
					return
				}
	
				await this.onAddSQD()
				await this.onPrintDocx()
				await this.onUpdateTotNghiep()
				this.closeDialog()
			},
	
			async onAddSQDAndUpdate() {
				if (!this.onValidate()) {
					return
				}

				await this.onAddSQD()
				await this.onUpdateTotNghiep()
				this.closeDialog()
			},
	
			onPrintDocx() {
				this.isLoadingExport = true
	
				if (!this.onValidate()) {
					this.isLoadingExport = false
					return
				}
	
				const exportDate = moment(this.formData.NgayLapQDTotNghiep, ['YYYY-MM-DD', 'DD/MM/YYYY', moment.ISO_8601], true)
	
				if (!exportDate.isValid()) {
					this.isLoadingExport = false
					return Vue.$toast.error('Ngày lập quyết định tốt nghiệp không hợp lệ', { position: 'top' })
				}
	
				const day = exportDate.format('DD')
				const month = exportDate.format('MM')
				const year = exportDate.format('YYYY')
				const nguoiXuat = parseInt(vueData.user.UserID.slice(2), 10)
	
				const dataArr = this.SelectedStudents.map((item, index) => ({
					STT: (index + 1).toString(),
					MSHV: item.Student_ID,
					HoHV: item.Ho_SV,
					TenHV: item.Ten_SV,
					GioiTinh: item.GioiTinh ?? '',
					NgaySinh: item.NgaySinh ? this.formatCustomDate(item.NgaySinh) : '',
					NoiSinh: item.Noi_Sinh ?? '',
					Nganh: item.Ten_Nganh,
				}))
	
				const apiData = {
					SQDTotNghiep: this.formData.SQDTotNghiep,
					Ngay: day,
					Thang: month,
					Nam: year,
					Dot: this.formData.Dot,
					SoLuongHocVien: dataArr.length.toString(),
					SoLuongBangChu: numberToText(dataArr.length),
					NguoiXuat: nguoiXuat.toString(),
					DanhSach: dataArr
						.sort((a, b) =>
							a.Nganh.localeCompare(b.Nganh, 'vi') ||
							a.TenHV.localeCompare(b.TenHV, 'vi')
						)
						.map((item, index) => ({
							...item,
							STT: (index + 1).toString()
						}))
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
				return fetch('https://gendocx.iotsoftvn.com/api/generate-docx/cong-nhan-tot-nghiep', requestOptions)
					.then((response) => response.blob())
					.then((blob) => {
						const url = window.URL.createObjectURL(blob)
						const anchor = document.createElement('a')
						anchor.href = url
						anchor.download = 'Quyết định công nhận xét tốt nghiệp.docx'
						document.body.appendChild(anchor)
						anchor.click()
						anchor.remove()
						this.isLoadingExport = false
					})
					.catch((error) => {
						this.isLoadingExport = false
						Vue.$toast.error(`${error}`, { position: 'top' })
						console.error(error)
						throw error
					})
			},
	
			closeDialog() {
				this.major = []
				this.MultipleNienKhoa = []
				this.AppliedNienKhoa = []
				this.search = ''
				this.formData = {
					TieuDe: 'Về việc công nhận tốt nghiệp và cấp bằng thạc sĩ',
					NgayLapQDTotNghiep: '',
					SQDTotNghiep: '.../QĐ-ĐHLH',
					Dot: null,
					NamTotNghiep: '',
				}
				vueData.isOpenQDTotNghiep = false
			},
		},
	}
</script>