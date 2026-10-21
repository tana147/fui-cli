<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="1500px" persistent>
		<v-card>
			<c-toolbar @onClose="onClose">
				<template v-slot:title>
					<div class="title primary--text text-left">In Quyết Định Đổi/Điều chỉnh đề tài</div>
				</template>
			</c-toolbar>

			<v-card-text>
				<v-row>
					<v-col cols="2">
						<v-select :items="heDaoTao" label="Hệ đào tạo" outlined dense
							v-model="QDDataObject.typeHeDaoTao" item-text="VALUE" item-value="KEY" hide-details />
					</v-col>
					<v-col cols="3">
						<v-select :items="DanhSachNganh" label="Ngành" outlined dense v-model="QDDataObject.NganhObj"
							item-text="Ten_Nganh_HienThi" return-object hide-details
							no-data-text="Vui lòng chọn hệ đào tạo" />
					</v-col>
					<v-col>
						<v-text-field v-model="QDDataObject.SQD" outlined dense hide-details label="Số QĐ" />
					</v-col>
					<v-col>
						<f-date v-model="QDDataObject.NgayQD" outlined dense hide-details label="Ngày QĐ" />
					</v-col>

					<v-col cols="2">
						<v-select outlined color="success" dense label="Niên khóa" :items="NienKhoaArr"
							v-model="QDDataObject.NienKhoa" hide-details item-text="Nien_Khoa" item-value="Nien_Khoa"
							no-data-text="Vui lòng chọn ngành"
							:disabled="QDDataObject.LoaiQD === 1 || QDDataObject.LoaiQD === 2 || !QDDataObject.NganhObj || !QDDataObject.NganhObj.Nganh_ID" />
					</v-col>
					<v-col>
						<v-select v-model="QDDataObject.LoaiQD" :items="LoaiQDList" label="Loại Quyết Định"
							item-text="text" item-value="value" outlined dense hide-details />
					</v-col>
				</v-row>
				<div v-if="QDDataObject.NganhObj.Nganh_ID == 106">
					<v-radio-group v-model="thsType" row mandatory>
						<v-radio value="2" label="Thạc sĩ nghiên cứu" />
						<v-radio value="1" label="Thạc sĩ ứng dụng" />
					</v-radio-group>
				</div>
				<v-card class="mt-3">
					<v-card-title class="primary--text">
						Danh sách học viên ({{ DanhSachDoiDeTai.length }})
						<v-spacer></v-spacer>
						<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm nhanh..."
							single-line hide-details dense class="c-underline-search" style="max-width: 300px;">
						</v-text-field>
					</v-card-title>

					<v-data-table v-model="QDDataObject.selectedHocVien" height="400px" item-key="STT"
						:headers="tableHeader" :items="DanhSachDoiDeTai" :search="search"
						:custom-filter="customSearchFilter" show-select items-per-page="-1"
						:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" dense>
						<template v-slot:item.Student_ID="{ item }">
							<span class="primary--text">
								<b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
							</span>
							<br />
							<b>{{ item.Student_ID }}</b>
							<span class="amber--text"> [{{ item.Lop_ID }}]</span>
						</template>
					</v-data-table>
				</v-card>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn :loading="isLoading" :disabled="QDDataObject.selectedHocVien.length === 0" @click="printQD"
					color="success">
					<v-icon left dark>mdi-file-word-box</v-icon>In Quyết Định
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-print-qd",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			heDaoTao: { type: Array, default: () => [] },
			heArray: { type: Array, default: () => [] },
		},
		emits: ["input"],
		data() {
			return {
				heDaoTao: [],
				DanhSachNganh: [],
				DanhSachHocVien: [],
				NienKhoaArr: [],
				DanhSachDoiDeTai: [],
				t: ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'],
	
				thsType: 2,
				search: '',
	
				isLoading: false,
	
				QDDataObject: {
					LoaiQD: 0,
					SQD: '          /QĐ-ĐHLH',
					NgayQD: null,
					NienKhoa: null,
					NganhObj: {},
					typeHeDaoTao: 'N',
					selectedHocVien: [],
				},
	
				tableHeader: [
					{
						text: 'STT',
						value: 'STT',
						align: 'center',
						sortable: false,
					},
					{
						text: 'Học viên',
						value: 'Student_ID',
					},
					{
						text: 'Niên khóa',
						value: 'Nien_Khoa',
						align: 'center',
						sortable: false,
						width: '100px',
					},
					{
						text: 'Ngành',
						value: 'Ten_Nganh',
					},
					{
						text: 'Tên đề tài cũ',
						value: 'Thesis_Name_Old',
					},
					{
						text: 'Tên đề tài mới',
						value: 'Thesis_Name_New',
					},
					{
						text: 'GVHD 1 (mới)',
						value: 'Thesises_Prof1_New',
					},
					{
						text: 'GVHD 2 (mới)',
						value: 'Thesises_Prof2_New',
					},
				],
	
				LoaiQDList: [
					{
						text: 'Đổi đề tài',
						value: 0,
					},
					{
						text: 'Điều chỉnh đề tài',
						value: 1,
					},
					{
						text: 'Đổi GVHD',
						value: 2,
					},
					{
						text: 'Đổi đề tài và GVHD',
						value: 3,
					},
				],
			}
		},
		mounted() { },
		computed: {
			dialog: {
				get() {
					return this.value
				},
				set(val) {
					this.$emit('input', val)
				},
			},
		},
		watch: {
			dialog: function (val) {
				if (val) {
					this.getHeByID('N')
					this.getHeDaoTao()
					this.onloadDoiDeTaiDaDuyet(0)
				}
			},
			'QDDataObject.typeHeDaoTao': function (val) {
				if (val) {
					this.getHeByID(val)
				}
			},
	
			'QDDataObject.NganhObj': function (val) {
				if (val) {
					this.onLoadNienKhoa(val.Nganh_ID)
					this.onloadDoiDeTaiDaDuyet(val.Nganh_ID)
				}
			},
			thsType: function (val) {
				const $this = this
				console.log('val', val)
				if (val) {
					$this.onLoadNienKhoa($this.QDDataObject.NganhObj.Nganh_ID)
				}
			},
			'QDDataObject.LoaiQD': function (val) {
				if (val === 1 || val === 2) {
					this.QDDataObject.NienKhoa = null
				}
			},
		},
		methods: {
			// 1. Hàm hỗ trợ
			getNienKhoaForParam() {
				if (this.QDDataObject.LoaiQD === 1 || this.QDDataObject.LoaiQD === 2) {
					if (this.QDDataObject.selectedHocVien.length === 1) {
						const student = this.QDDataObject.selectedHocVien[0];
						return student.Nien_Khoa || student.NienKhoa || "0";
					}
					return "0";
				}
				return this.QDDataObject.NienKhoa || "0";
			},
			customSearchFilter(value, search, item) {
				if (!search) return true;
				const s = String(search).toLowerCase();
				const hoTen = String((item.Ho_SV || '') + ' ' + (item.Ten_SV || '')).toLowerCase();
				const id = String(item.Student_ID || '').toLowerCase();
				const lop = String(item.Lop_ID || '').toLowerCase();
				const nganh = String(item.Ten_Nganh || '').toLowerCase();
				const deTaiCu = String(item.Thesis_Name_Old || '').toLowerCase();
				const deTaiMoi = String(item.Thesis_Name_New || '').toLowerCase();
				const gv1 = String(item.Thesises_Prof1_New || '').toLowerCase();
				const gv2 = String(item.Thesises_Prof2_New || '').toLowerCase();
				return hoTen.includes(s) || id.includes(s) || lop.includes(s) || nganh.includes(s) || deTaiCu.includes(s) || deTaiMoi.includes(s) || gv1.includes(s) || gv2.includes(s);
			},

			// 2. Hàm xử lý chức năng
			onClose() {
				this.QDDataObject = {
					LoaiQD: 0,
					SQD: '          /QĐ-ĐHLH',
					NgayQD: null,
					NienKhoa: null,
					NganhObj: {},
					typeHeDaoTao: 'C',
					selectedHocVien: [],
				}
				this.isLoading = false
				this.$emit('input', false)
			},
			// 3. Hàm gọi API
			uploadFile({
				files,
				url,
				headers = {},
				resize = {
					width: 1900,
					height: 1600,
					quality: 80,
				},
				filters = {
					max_file_size: '5mb',
					mime_types: [{ title: 'All files', extensions: '*' }],
				},
				onProgress = () => { },
				onError = () => { },
				onSuccess = () => { },
			}) {
				return new Promise((resolve, reject) => {
					let uploadedResult = null
	
					// Lấy header xác thực giống f-upload.txt
					const combinedHeaders = {
						authorization: 'Bearer ' + getCookie('awt'),
						uploaddata: Date.now(),
						...headers,
					}
	
					// Plupload yêu cầu phải có browse_button (DOM element) để khởi tạo runtime html5
					let dummyBtn = document.createElement('div')
					dummyBtn.id = 'dummy-upload-btn-' + Date.now()
					dummyBtn.style.display = 'none'
					document.body.appendChild(dummyBtn)
	
					const uploader = new plupload.Uploader({
						runtimes: 'html5,html4',
						browse_button: dummyBtn.id,
						url: url,
						headers: combinedHeaders,
						resize: resize,
						filters: filters,
						init: {
							PostInit: function (up) {
								// Đảm bảo plupload đã sẵn sàng thì mới add file
								up.addFile(files)
							},
	
							FilesAdded: function (up, filesAdded) {
								up.start() // Bắt đầu upload
							},
	
							UploadProgress: function (up, file) {
								onProgress(file) // callback progress
							},
	
							FileUploaded: function (up, file, result) {
								try {
									let res = JSON.parse(result.response)
									if (typeof json_data_parse === 'function') {
										json_data_parse(res, 0)
									}
									uploadedResult = res
									onSuccess(res, file) // callback khi từng file xong
								} catch (e) {
									reject(e)
								}
							},
	
							UploadComplete: function () {
								// Xóa dummy button
								if (dummyBtn && dummyBtn.parentNode) {
									dummyBtn.parentNode.removeChild(dummyBtn)
								}
								resolve(uploadedResult) // Trả kết quả cuối
							},
	
							Error: function (up, err) {
								if (dummyBtn && dummyBtn.parentNode) {
									dummyBtn.parentNode.removeChild(dummyBtn)
								}
								if (err.status == 500 && err.response) {
									try {
										err.message = JSON.parse(err.response).message
									} catch (e) { }
								}
								onError(err)
								reject(err)
							},
						},
					})
	
					uploader.init()
				})
			},
	
			async onInsertQD(param) {
				const $this = this
				try {
					await ajaxCALLPromise(
						'/Decision_Change_Thesis_Ins',
						{
							JsonStudentData: JSON.stringify(param.StudentData),
							Decision_SoQD: $this.QDDataObject.SQD,
							Decision_NgayQD: param.day,
							Decision_ThangQD: param.month,
							Decision_NamQD: param.year,
							Decision_TieuDe: param.TieuDe,
							Decision_NganhID: $this.QDDataObject.NganhObj.Nganh_ID.toString(),
							Decision_NienKhoa: this.getNienKhoaForParam(),
							Decision_FileID: param.FileID,
							Decision_Url: param.Url,
							DecisionFile_Name: param.FileName,
						}
					)
					return 'success'
				} catch (error) {
					Vue.$toast.error(`${error.responseJSON?.Message || error.message}`, { position: 'top' })
					throw error
				}
			},
	
			printQD() {
				const $this = this
				if (this.QDDataObject.LoaiQD === 0 || this.QDDataObject.LoaiQD === 1) {
					$this.printQDDoiDieuChinh()
				} else {
					$this.printQDDoiDeTaiVaGVHD()
				}
			},
	
			async printQDDoiDeTaiVaGVHD() {
				const $this = this

				const requiredFields = [
					{ key: 'NgayQD', message: 'Vui lòng chọn ngày quyết định' },
					{ key: 'NganhObj', message: 'Vui lòng chọn ngành' },
				]
				if (this.QDDataObject.LoaiQD !== 2) {
					requiredFields.push({ key: 'NienKhoa', message: 'Vui lòng chọn niên khóa' })
				}

				for (const field of requiredFields) {
					const val = this.QDDataObject[field.key]
					const isInvalid = !val || (field.key === 'NganhObj' && !val.Nganh_ID)
					if (isInvalid) {
						Vue.$toast.error(field.message, { position: 'top' })
						this.isLoading = false
						return
					}
				}

				this.isLoading = true
	
				const ngayQDSplit = this.QDDataObject.NgayQD?.split('-') ?? []
				let danhSachHocVien = []
	
				const year = ngayQDSplit[0] ?? ''
				const month = ngayQDSplit[1] ?? ''
				const day = ngayQDSplit[2] ?? ''
	
				const studentIds = this.QDDataObject.selectedHocVien.map((item) => {
					return {
						StudentID: item.Student_ID,
					}
				})
	
				const dataParam = {
					StudentData: studentIds,
					FileID: null,
					Url: null,
					FileName: null,
					day: day,
					month: month,
					year: year,
					TieuDe: this.QDDataObject.LoaiQD == 2 ? 'Về việc thay đổi người hướng dẫn khoa học'
						: this.QDDataObject.LoaiQD == 3 ? 'Về việc thay đổi tên đề luận văn thạc sĩ và người hướng dẫn khoa học'
							: '',
				}
	
				// Nếu parse không được thì mặc định là 0
				const nguoiTao = parseInt(vueData.user.UserID.slice(-4)) || 0
	
				if (this.QDDataObject.LoaiQD === 2) {
					danhSachHocVien = this.QDDataObject.selectedHocVien.map((item, index) => {
						return {
							STT: item.STT.toString(),
							MSHV: item.Student_ID,
							HoHV: item.Ho_SV,
							TenHV: item.Ten_SV,
							NgaySinh: item.Ngay_Sinh,
							NoiSinh: item.Noi_Sinh,
							NienKhoa: item.Nien_Khoa,
							GVHD1: item.Thesises_Prof1_New,
							GVHD2: item.Thesises_Prof2_New,
							NoiCongTac1: "",
							NoiCongTac2: "",
						}
					})
				} else if (this.QDDataObject.LoaiQD === 3) {
					danhSachHocVien = this.QDDataObject.selectedHocVien.map((item, index) => {
						return {
							STT: item.STT.toString(),
							MSHV: item.Student_ID,
							HoHV: item.Ho_SV,
							TenHV: item.Ten_SV,
							NgaySinh: item.Ngay_Sinh,
							NoiSinh: item.Noi_Sinh,
							TenDeTaiCu: item.Thesis_Name_Old,
							TenDeTaiMoi: item.Thesis_Name_New,
							GVHD1: item.Thesises_Prof1_New,
							GVHD2: item.Thesises_Prof2_New,
							NoiCongTac1: item.CoQuanCongTacGV1 ?? "",
							NoiCongTac2: item.CoQuanCongTacGV2 ?? "",
						}
					})
				}
	
				let apiData = {
					SQD: this.QDDataObject.SQD,
					Ngay: day,
					Thang: month,
					Nam: year,
					Nganh: this.QDDataObject.NganhObj.Ten_Nganh,
					MaNganh: this.QDDataObject.NganhObj.MaNganh,
					NienKhoa: this.getNienKhoaForParam(),
					NguoiTao: nguoiTao.toString(),
					// 1 - đổi GVHD, 2 - đổi đề tài và GVHD
					IsDoiGVHDOrDeTai: this.QDDataObject.LoaiQD === 2 ? 1 : 2,
					SoLuong: this.QDDataObject.selectedHocVien.length,
					SoLuongBangChu: this.numberToText(parseInt(this.QDDataObject.selectedHocVien.length) || 0),
					DanhSach: this.QDDataObject.LoaiQD === 2 ? danhSachHocVien : [],
					DanhSachDoiDeTaiVaGVHD: this.QDDataObject.LoaiQD === 3 ? danhSachHocVien : [],
				}

				try {
					const blob = await ajaxPOSTBlobPromise(
						'https://gendocx.iotsoftvn.com/api/generate-docx/doi-gvhd-va-de-tai',
						apiData
					)

					if (!blob) {
						this.isLoading = false
						return
					}

					var url = window.URL.createObjectURL(blob)
					var a = document.createElement('a')
					a.href = url
					a.download = `${$this.QDDataObject.SQD} Quyết định ${this.QDDataObject.LoaiQD === 2 ? 'Đổi GVHD' : 'Đổi đề tài và GVHD'}.docx`
					document.body.appendChild(a)
					a.click()
					a.remove()

					const fileName = `${$this.QDDataObject.SQD} Quyết định ${this.QDDataObject.LoaiQD === 2 ? 'Đổi GVHD' : 'Đổi đề tài và GVHD'}.docx`
					const fileToUpload = new File([blob], fileName, {
						type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
					})

					const apiFileUrl = window.vueData?.v_Set?.apiFile || ''
					const uploadRes = await $this.uploadFile({
						files: [fileToUpload],
						url: apiFileUrl,
					})

					dataParam.FileID = uploadRes.Files[0].FILE_ID
					dataParam.Url = uploadRes.Files[0].FILE_URL
					dataParam.FileName = uploadRes.Files[0].FILE_NAME

					await $this.onInsertQD(dataParam)

					Vue.$toast.success(`Tạo Quyết định thành công`, { position: 'top' })
					this.onClose()
				} catch (error) {
					console.error('Lỗi khi tạo/upload quyết định:', error)
					Vue.$toast.error(`Lỗi khi tạo Quyết định`, { position: 'top' })
				} finally {
					this.isLoading = false
				}
			},
	
			async printQDDoiDieuChinh() {
				const $this = this

				const requiredFields = [
					{ key: 'NgayQD', message: 'Vui lòng chọn ngày quyết định' },
					{ key: 'NganhObj', message: 'Vui lòng chọn ngành' },
				]
				// Không validate Niên khóa khi Loại QĐ là "Điều chỉnh đề tài" (LoaiQD = 1)
				if (this.QDDataObject.LoaiQD !== 1) {
					requiredFields.push({ key: 'NienKhoa', message: 'Vui lòng chọn niên khóa' })
				}

				for (const field of requiredFields) {
					const val = this.QDDataObject[field.key]
					const isInvalid = !val || (field.key === 'NganhObj' && !val.Nganh_ID)
					if (isInvalid) {
						Vue.$toast.error(field.message, { position: 'top' })
						this.isLoading = false
						return
					}
				}

				this.isLoading = true
	
				const ngayQDSplit = this.QDDataObject.NgayQD?.split('-') ?? []
				const danhSachHocVien = []
	
				const year = ngayQDSplit[0] ?? ''
				const month = ngayQDSplit[1] ?? ''
				const day = ngayQDSplit[2] ?? ''
	
				// Nếu parse không được thì mặc định là 0
				const nguoiTao = parseInt(vueData.user.UserID.slice(-4)) || 0
	
				this.QDDataObject.selectedHocVien.forEach((item) => {
					// Hàm tách họ và tên
	
					// const lastSpaceIndex = item.Student_Name.lastIndexOf(' ')
					// const lastName = item.Student_Name.slice(lastSpaceIndex + 1)
					// const firstName = item.Student_Name.slice(0, lastSpaceIndex)
	
					const obj = {
						STT: item.STT.toString(),
						MSHV: item.Student_ID,
						Ho: item.Ho_SV,
						Ten: item.Ten_SV,
						NgaySinh: item.Ngay_Sinh,
						LopID: item.Lop_ID,
						NoiSinh: item.Noi_Sinh,
                        NienKhoa: item.Nien_Khoa,
						TenDeTaiCu: item.Thesis_Name_Old,
						TenDeTaiMoi: item.Thesis_Name_New,
						GVHD1: item.Thesises_Prof1_New,
						GVHD2: item.Thesises_Prof2_New,
					}
					danhSachHocVien.push(obj)
				})
	
				const studentIds = this.QDDataObject.selectedHocVien.map((item) => {
					return {
						StudentID: item.Student_ID,
					}
				})
	
				const dataParam = {
					StudentData: studentIds,
					FileID: null,
					Url: null,
					FileName: null,
					day: day,
					month: month,
					year: year,
					TieuDe: this.QDDataObject.LoaiQD == 0 ? 'Về việc thay đổi tên đề tài luận văn thạc sĩ' : 'Về việc điều chỉnh tên đề tài luận văn thạc sĩ',
				}

				const apiData = {
					SQD: this.QDDataObject.SQD,
					Ngay: day,
					Thang: month,
					Nam: year,
					// 0 - đổi đề tài, 1 - điều chỉnh đề tài
					IsDoiOrDieuChinh: this.QDDataObject.LoaiQD,
					NienKhoa: this.getNienKhoaForParam(),
					Nganh: this.QDDataObject.NganhObj.Nganh_ID === 106 ? "Tổ chức quản lý dược" : this.QDDataObject.NganhObj.Ten_Nganh,
					// Nganh: this.QDDataObject.NganhObj.Ten_Nganh,
					NganhID: this.QDDataObject.NganhObj.Nganh_ID.toString(),
					MaNganh: this.QDDataObject.NganhObj.MaNganh,
					NguoiTao: nguoiTao.toString(),
					SoLuongHocVien: this.QDDataObject.selectedHocVien.length,
					SoLuongHocVienBangChu: this.numberToText(parseInt(this.QDDataObject.selectedHocVien.length) || 0),
					DanhSach: danhSachHocVien,
				}
	
	
				try {
					const blob = await ajaxPOSTBlobPromise(
						'https://gendocx.iotsoftvn.com/api/generate-docx/doi-dieu-chinh',
						apiData
					)

					if (!blob) {
						this.isLoading = false
						return
					}

					var url = window.URL.createObjectURL(blob)
					var a = document.createElement('a')
					a.href = url
					a.download = `${$this.QDDataObject.SQD} Quyết định Đổi/Điều chỉnh đề tài.docx`
					document.body.appendChild(a)
					a.click()
					a.remove()

					const fileName = `${$this.QDDataObject.SQD} Quyết định Đổi/Điều chỉnh đề tài.docx`
					const fileToUpload = new File([blob], fileName, {
						type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
					})

					const apiFileUrl = window.vueData?.v_Set?.apiFile || ''
					const uploadRes = await $this.uploadFile({
						files: [fileToUpload],
						url: apiFileUrl,
					})

					dataParam.FileID = uploadRes.Files[0].FILE_ID
					dataParam.Url = uploadRes.Files[0].FILE_URL
					dataParam.FileName = uploadRes.Files[0].FILE_NAME

					await $this.onInsertQD(dataParam)

					Vue.$toast.success(`Tạo Quyết định thành công`, { position: 'top' })
					this.onClose()
				} catch (error) {
					console.error('Lỗi khi tạo/upload quyết định:', error)
					Vue.$toast.error(`Lỗi khi tạo Quyết định`, { position: 'top' })
				} finally {
					this.isLoading = false
				}
			},
	
			async onloadDoiDeTaiDaDuyet(nganhID) {
				try {
					const res = await ajaxCALLPromise(
						'/SDH_ThongKe_DoiDeTai_DaDuyet',
						{
							Nganh_ID: nganhID,
						}
					)
					this.DanhSachDoiDeTai = (res || []).map((item, index) => {
						return {
							...item,
							STT: index + 1,
						}
					})
					console.log('this.DanhSachDoiDeTai', this.DanhSachDoiDeTai)
				} catch (error) {
					Vue.$toast.error(`${error.responseJSON?.Message || error.message}`, { position: 'top' })
					console.log('fail to load thong ke doi de tai', error)
				}
			},
			async onLoadNienKhoa(nganhID) {
				try {
					const res = await ajaxCALLPromise(
						'/Get_NienKhoa_StudentWaitForThesisConfirm',
						{
							// 1 - Thạc sĩ ứng dụng, 2 - Thạc sĩ nghiên cứu
							Process_ID: nganhID == 102 || (nganhID == 106 && this.thsType == 1) ? 4 : 1,
							Nganh_ID: nganhID,
						}
					)
					this.NienKhoaArr = res || []
					console.log('this.NienKhoaArr', this.NienKhoaArr)
				} catch (error) {
					Vue.$toast.error(`${error.responseJSON?.Message || error.message}`, { position: 'top' })
					console.log('fail to load nien khoa', error)
				}
			},
			async getHeDaoTao() {
				try {
					const res = await ajaxCALLPromise('/hedaotao_get', null)
					this.heDaoTao = res || []
				} catch (error) {
					Vue.$toast.error(`${error.responseJSON?.Message || error.message}`, { position: 'top' })
					console.log('Get he dao tao fail', error)
				}
			},
			async getHeByID(heID) {
				try {
					const res = await ajaxCALLPromise(
						'/Nganh_Get_ByHeID',
						{ HeID: heID }
					)
					let allListObj = null
					if (this.QDDataObject.typeHeDaoTao) {
						allListObj = {
							Nganh_ID: 0,
							Ten_Nganh: '- Tất cả -',
							Ten_Nganh_HienThi: '- Tất cả -',
						}
					}
					this.DanhSachNganh = res || []
					this.DanhSachNganh.unshift(allListObj)
				} catch (error) {
					Vue.$toast.error(`${error.responseJSON?.Message || error.message}`, { position: 'top' })
					console.log('Fail to get he dao tao', error)
				}
			},
	
			numberToText(value) {
				if (value === 0) return this.t[0]
				let result = '',
					suffix = ''
	
				do {
					let ty = value % 1e9
					value = Math.floor(value / 1e9)
					result = value > 0 ? this._convertMillions(ty, true) + suffix + result : this._convertMillions(ty, false) + suffix + result
					suffix = ' tỷ'
				} while (value > 0)
	
				return result.trim()
			},
	
			onClose() {
				this.QDDataObject = {
					LoaiQD: 0,
					SQD: '          /QĐ-ĐHLH',
					NgayQD: null,
					NienKhoa: null,
					NganhObj: {},
					typeHeDaoTao: 'C',
					selectedHocVien: [],
				}
				this.isLoading = false
				this.$emit('input', false)
			},
	
			// Hàm xử lý hàng triệu
			_convertMillions(number, withSuffix) {
				let millions = Math.floor(number / 1e6)
				number %= 1e6
				let thousands = Math.floor(number / 1e3)
				number %= 1e3
	
				let result = ''
				if (millions > 0) {
					result += this._convertHundreds(millions, withSuffix) + ' triệu'
					withSuffix = true
				}
				if (thousands > 0) {
					result += this._convertHundreds(thousands, withSuffix) + ' ngàn'
					withSuffix = true
				}
				if (number > 0) {
					result += this._convertHundreds(number, withSuffix)
				}
				return result
			},
	
			// Hàm xử lý hàng trăm
			_convertHundreds(number, withSuffix) {
				let hundreds = Math.floor(number / 100)
				number %= 100
				let result = ''
	
				if (withSuffix || hundreds > 0) {
					result = ' ' + this.t[hundreds] + ' trăm'
					result += this._convertTens(number, true)
				} else {
					result = this._convertTens(number, false)
				}
				return result
			},
	
			// Hàm xử lý hàng chục
			_convertTens(number, withZeroPrefix) {
				let tens = Math.floor(number / 10)
				let units = number % 10
				let result = ''
	
				if (tens > 1) {
					result = ' ' + this.t[tens] + ' mươi'
					if (units === 1) result += ' mốt'
				} else if (tens === 1) {
					result = ' mười'
					if (units === 1) result += ' một'
				} else if (withZeroPrefix && units > 0) {
					result = ' lẻ'
				}
	
				if (units === 5 && tens >= 1) {
					result += ' lăm'
				} else if (units === 4 && tens >= 1) {
					result += ' bốn'
				} else if (units > 1 || (units === 1 && tens === 0)) {
					result += ' ' + this.t[units]
				}
	
				return result
			},
	
			// Hàm viết hoa chữ cái đầu tiên
			capitalize(text) {
				return text.charAt(0).toUpperCase() + text.slice(1)
			},
		},
	}
</script>