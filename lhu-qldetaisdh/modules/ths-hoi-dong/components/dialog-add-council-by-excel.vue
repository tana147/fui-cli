<template>
	<v-dialog v-model="vueData.isExcelDialog" transition="dialog-bottom-transition" max-width="1680px" persistent>
		<v-card>
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<p class="title mb-0 primary--text">Lập danh sách hội đồng bằng file excel</p>
					<v-chip class="ml-3" color="deep-purple accent-4" outlined label hide-details>
						<v-icon left>mdi-file-check-outline</v-icon>
						<a style="color: deep-purple accent-4" :href="vueData.v_Set.urlReadFile + templateNC">Template
							Thạc sĩ nghiên cứu</a>
					</v-chip>
					<v-chip class="ml-3" color="deep-purple accent-4" outlined label hide-details>
						<v-icon left>mdi-file-check-outline</v-icon>
						<a style="color: deep-purple accent-4" :href="vueData.v_Set.urlReadFile + templateUD">Template
							Thạc sĩ ứng dụng</a>
					</v-chip>
				</template>
			</c-toolbar>

			<v-card-text>
				<div class="d-flex align-center justify-end" style="gap: 15px">
					<div class="d-flex align-center" style="min-width: 300px">
						<v-file-input v-model="fileUpload" dense hide-details
							accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
							label="Chọn file Excel" outlined />
					</div>
					<div class="selectLoaiHD">
						<v-select v-model="loaiLapHoiDong" outlined dense hide-details :items="loaiLapHoiDongList"
							item-text="text" item-value="value" />
					</div>
					<div class="selectWidth">
						<v-select v-model="switchData" outlined dense hide-details :items="switchList" item-text="text"
							item-value="value" />
					</div>
				</div>

				<f-table class="mt-3" :label="labelTable" :headers="tableHeader" :items="DanhSachInfo"
					show-search="true" :dense="true" :excel="false"
					:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" itemsPerPage="-1">
					<template v-slot:item.KiemTraStatus="{ item }">
						<v-chip
							small
							:color="getStudentStatus(item.MSHV).color"
							label
							outlined
							class="font-weight-medium"
						>
							{{ getStudentStatus(item.MSHV).text }}
						</v-chip>
					</template>
				</f-table>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<div class="councilTime">
					<f-date v-model="councilTime" label="Ngày bảo vệ luận văn" placeholder="Ngày bảo vệ luận văn"
						outlined dense hide-details />
				</div>
				<v-btn v-if="loaiLapHoiDong === 2" @click="addCouncil" class="ml-3"
					:disabled="!fileUpload || !councilTime" color="success">Lập hội đồng</v-btn>
				<v-btn v-else-if="loaiLapHoiDong === 1" @click="onAddHDSQD" class="ml-3"
					:disabled="!fileUpload || !councilTime" color="success">Lập hội đồng & cấp SQĐ</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ['dshdgiangvien', 'dshddetai'],
		data() {
			return {
				fileUpload: null,
				fileData: null,
				switchData: 1,
				DanhSachInfo: [],
				DSDetai: [],
				labelTable: 'Danh sách học viên đăng ký bảo vệ luận văn',
				councilTime: '',
				templateNC: 'FileData/08196EA5814840AAA82DA9AA9C3CE2AF',
				templateUD: 'FileData/60E2A2B50914420D929C990D4F95AAAF',
				loaiLapHoiDong: 1,
	
				switchList: [
					{
						text: 'Thạc sĩ nghiên cứu',
						value: 1,
					},
					{
						text: 'Thạc sĩ ứng dụng',
						value: 2,
					},
				],
	
				loaiLapHoiDongList: [
					{
						text: 'Lập hội đồng và cấp SQĐ',
						value: 1,
					},
					{
						text: 'Chỉ lập hội đồng',
						value: 2,
					},
				],
	
				tableHeader: [
					{
						text: 'STT',
						value: 'STT',
						sortable: false,
						align: 'center',
						width: 50,
					},
					{
						text: 'MSHV',
						value: 'MSHV',
					},
					{
						text: 'Lớp',
						value: 'Lop',
					},
					{
						text: 'Họ',
						value: 'Ho',
					},
					{
						text: 'Tên',
						value: 'Ten',
					},
					{
						text: 'Trạng thái',
						value: 'KiemTraStatus',
						align: 'center',
						sortable: false,
						width: 170,
					},
					{
						text: 'Tên đề tài',
						value: 'DeTai',
					},
					{
						text: 'GVHD 1',
						value: 'GVHD1',
					},
					{
						text: 'GVHD 2',
						value: 'GVHD2',
					},
					{
						text: 'Chủ tịch',
						value: 'ChuTich',
					},
					{
						text: 'Phản biện 1',
						value: 'PB1',
					},
					{
						text: 'Phản biện 2',
						value: 'PB2',
					},
					{
						text: 'Thư ký',
						value: 'ThuKy',
					},
					{
						text: 'Ủy viên',
						value: 'UyVien',
					},
				],
			}
		},
		mounted() { },
		computed: {
			DsHoiDongGiangVien: function () {
				return this.dshdgiangvien
			},
			DsHoiDongDeTai: function () {
				return this.dshddetai
			},
		},
		watch: {
			fileUpload(val) {
				if (val) {
					this.loadExcelGVInfo(val)
				} else {
					this.deleteFile()
				}
			},
			switchData: function (val) {
				this.deleteFile()
			},
		},
		methods: {
			// Hàm clear khoảng trắng
			cleanString(input) {
				return (
					input
						// Loại bỏ khoảng trắng thừa xung quanh dấu chấm
						.replace(/\s*\.\s*/g, '. ')
						// Loại bỏ khoảng trắng thừa giữa các từ
						.replace(/\s+/g, ' ')
						// Chuẩn hóa viết hoa chữ cái đầu trong tên riêng
						.replace(/\b\w/g, (char) => char.toUpperCase())
						// Loại bỏ khoảng trắng thừa ở đầu và cuối chuỗi
						.trim()
				)
			},
	
			// Nhiệm vụ của hàm này là để đảm bảo không bị bất đồng bộ khi lập hội đồng và cấp SQĐ
			async onGetDeTai() {
				return new Promise((resolve, reject) => {
					ajaxCALL(
						'/HoiDong_DeTai_Get',
						{
							NganhID: 0,
						},
						(res) => {
							resolve(res.data)
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							reject(error)
						},
					)
				})
			},
	
			async onUpdateSQD(item) {
				return new Promise((resolve, reject) => {
					ajaxCALL(
						'/HoiDong_Upd_SoQD',
						{
							Decision_ID: item.Decision_ID,
							Decision_SoQD: item.Decision_SoQD,
							Decision_NgayQD: item.Decision_NgayQD,
							Decision_ThangQD: item.Decision_ThangQD,
							Decision_NamQD: item.Decision_NamQD,
							DecisionFile_ID: item.DecisionFile_ID,
							DecisionFile_Url: item.DecisionFile_Url,
							DecisionFile_Name: item.DecisionFile_Name,
							HoiDong_ID: item.HoiDong_ID,
							Student_ID: item.Student_ID,
						},
						(res) => {
							Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
							// console.log("Update SQD complete", vueData.dsGetHoiDong)
							resolve(res)
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							reject(error)
							// console.log("Error to update SQD", error)
						},
					)
				})
			},
	
			async onGetHoiDongByID(item) {
				return new Promise((resolve, reject) => {
					ajaxCALL(
						'/HoiDong_Get_ByHoiDongID',
						{
							HoiDong_ID: item.HoiDongID,
						},
						(res) => {
							resolve(res.data)
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							reject(error)
						},
					)
				})
			},
	
			getStudentStatus(mshv) {
				if (!mshv) {
					return { status: 'empty', text: 'Thiếu MSHV', color: 'grey', canProcess: false }
				}
				if (!this.DsHoiDongDeTai || this.DsHoiDongDeTai.length === 0) {
					return { status: 'unknown', text: 'Chờ dữ liệu...', color: 'grey', canProcess: false }
				}
				const cleanMshv = String(mshv).trim()
				const studentRecords = this.DsHoiDongDeTai.filter(
					(m) => String(m.Student_ID).trim() === cleanMshv,
				)
				if (!studentRecords || studentRecords.length === 0) {
					return { status: 'not_found', text: 'Không có đề tài', color: 'error', canProcess: false }
				}
				// 1. Trường hợp bảo vệ lại: có bản ghi KetQuaHoiDong === 2 và chưa có HoiDongID (đã mở lại hội đồng)
				const retakeRecord = studentRecords.find((m) => m.KetQuaHoiDong === 2 && !m.HoiDongID)
				if (retakeRecord) {
					return { status: 'retake', text: 'Hợp lệ (Bảo vệ lại)', color: 'teal', canProcess: true, record: retakeRecord }
				}
				// 2. Trường hợp chưa có hội đồng: có bản ghi chưa có HoiDongID
				const newRecord = studentRecords.find((m) => !m.HoiDongID && m.KetQuaHoiDong !== 1)
				if (newRecord) {
					return { status: 'new', text: 'Hợp lệ (Chưa có HĐ)', color: 'success', canProcess: true, record: newRecord }
				}
				// 3. Trường hợp đã có hội đồng đang hoạt động:
				const activeRecord = studentRecords.find((m) => m.HoiDongID && m.KetQuaHoiDong !== 2)
				if (activeRecord) {
					const soQD = activeRecord.Decision_SoQD ? ` (${activeRecord.Decision_SoQD})` : ''
					return {
						status: 'has_council',
						text: `Đã có HĐ${soQD} - Bỏ qua`,
						color: 'deep-orange',
						canProcess: false,
						record: activeRecord,
					}
				}
				// 4. Trường hợp học viên bảo vệ lại nhưng chưa thực hiện thao tác "Lập lại HĐ" trên web
				return {
					status: 'needs_reopen',
					text: 'Cần bấm "Lập lại HĐ" trước',
					color: 'amber darken-3',
					canProcess: false,
				}
			},

			async onAddHDSQD() {
				let hasError = false
				let hasAddSQDError = false
				const $this = this

				// Chuẩn bị dữ liệu cho từng học viên
				this.DanhSachInfo = this.DanhSachInfo.map((item) => {
					const dsChucTrach = this.prepareHoiDongArr(item)
					return {
						...item,
						hoiDongArr: dsChucTrach,
					}
				})

				// Lọc danh sách học viên hợp lệ và danh sách bỏ qua
				const validItems = this.DanhSachInfo.filter((item) => this.getStudentStatus(item.MSHV).canProcess)
				const skippedItems = this.DanhSachInfo.filter((item) => !this.getStudentStatus(item.MSHV).canProcess)

				if (validItems.length === 0) {
					Vue.$toast.warning(`Không có học viên nào đủ điều kiện lập hội đồng mới (tất cả đã có HĐ hoặc không hợp lệ)`, { position: 'top', duration: 5000 })
					return
				}

				if (skippedItems.length > 0) {
					Vue.$toast.info(`Bỏ qua ${skippedItems.length} học viên đã có HĐ để tránh ghi đè dữ liệu cũ`, { position: 'top', duration: 4000 })
				}

				// Phase 1: Lập hội đồng bằng file excel (chỉ chạy cho validItems)
				for (const item of validItems) {
					try {
						if (item.hoiDongArr.length === 0) {
							Vue.$toast.error(`Không có hội đồng cho học viên ${item.Ho} ${item.Ten}`, { position: 'top' })
							hasError = true
							break
						}
						await $this.insHoiDongApi(item) // Gọi API và chờ hoàn tất
						console.log(`Hội đồng đã được thêm cho học viên ${item.MSHV}`)
					} catch (error) {
						hasError = true
						console.error('Lỗi khi thêm hội đồng:', error)
						Vue.$toast.error(`Error ins hội đồng: ${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
						break
					}
				}

				if (!hasError) {
					$this.DSDetai = await $this.onGetDeTai()
				} else {
					Vue.$toast.error(`Lập hội đồng thất bại`, { position: 'top' })
					return
				}

				// Phase 2: Cấp SQĐ cho hội đồng mới lập (TUYỆT ĐỐI chỉ chạy cho validItems)
				let sqdSuccessCount = 0
				for (const item of validItems) {
					try {
						if (!item.SoQD || !item.NgayQD) {
							console.log(`Học viên ${item.MSHV} không có SoQD hoặc NgayQD trong file excel`)
							continue
						}

						// Tìm hội đồng MỚI được lập: ưu tiên bản ghi có HoiDongID và Decision_SoQD chưa có
						const findMSHVID = $this.DSDetai.find(
							(mshv) => String(mshv.Student_ID).trim() === String(item.MSHV).trim() && mshv.HoiDongID && (!mshv.Decision_SoQD || String(mshv.Decision_SoQD).trim() === '')
						) || $this.DSDetai.find(
							(mshv) => String(mshv.Student_ID).trim() === String(item.MSHV).trim() && mshv.KetQuaHoiDong === 0
						)

						if (findMSHVID) {
							const hoiDongDetail = await $this.onGetHoiDongByID(findMSHVID)

							if (hoiDongDetail && hoiDongDetail[0] && hoiDongDetail[0].length >= 1) {
								const currentDetail = hoiDongDetail[0][0]

								// GUARD TUYỆT ĐỐI: Không bao giờ ghi đè nếu hội đồng này đã có số QĐ từ trước!
								if (currentDetail.Decision_SoQD && String(currentDetail.Decision_SoQD).trim() !== '') {
									console.warn(`Hội đồng ID ${currentDetail.HoiDongID} của học viên ${item.MSHV} đã có số QĐ (${currentDetail.Decision_SoQD}), bỏ qua không ghi đè`)
									continue
								}

								const splitNgayQD = item.NgayQD.split('/')
								const ngayQD = splitNgayQD[0]
								const thangQD = splitNgayQD[1]
								const namQD = splitNgayQD[2]

								const data = {
									Decision_ID: currentDetail.Decision_ID,
									Decision_SoQD: item.SoQD,
									Decision_NgayQD: ngayQD,
									Decision_ThangQD: thangQD,
									Decision_NamQD: namQD,
									DecisionFile_ID: null,
									DecisionFile_Url: null,
									DecisionFile_Name: null,
									HoiDong_ID: currentDetail.HoiDongID,
									Student_ID: item.MSHV,
								}

								await $this.onUpdateSQD(data)
								sqdSuccessCount++
							}
						} else {
							console.warn(`Không tìm thấy đề tài mới của học viên ${item.Ho} ${item.Ten} để cấp SQĐ`)
						}
					} catch (error) {
						hasAddSQDError = true
						console.error('Lỗi khi cấp SQĐ:', error)
						Vue.$toast.error(`Error add SQD: ${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
						break
					}
				}

				if (!hasAddSQDError) {
					CALL('getHoiDongDeTai')
					Vue.$toast.success(`Lập hội đồng thành công (${validItems.length} HV, đã cấp SQĐ: ${sqdSuccessCount})`, { position: 'top' })
					this.closeDialog()
				}
			},

			async addCouncil() {
				let hasError = false

				// Chuẩn bị dữ liệu cho từng học viên
				this.DanhSachInfo = this.DanhSachInfo.map((item) => {
					const dsChucTrach = this.prepareHoiDongArr(item)
					return {
						...item,
						hoiDongArr: dsChucTrach,
					}
				})

				// Lọc danh sách học viên hợp lệ và bỏ qua
				const validItems = this.DanhSachInfo.filter((item) => this.getStudentStatus(item.MSHV).canProcess)
				const skippedItems = this.DanhSachInfo.filter((item) => !this.getStudentStatus(item.MSHV).canProcess)

				if (validItems.length === 0) {
					Vue.$toast.warning(`Không có học viên nào đủ điều kiện lập hội đồng (tất cả đã có HĐ hoặc không hợp lệ)`, { position: 'top', duration: 5000 })
					return
				}

				if (skippedItems.length > 0) {
					Vue.$toast.info(`Bỏ qua ${skippedItems.length} học viên đã có HĐ để tránh trùng lặp`, { position: 'top', duration: 4000 })
				}

				for (const item of validItems) {
					try {
						if (item.hoiDongArr.length === 0) {
							Vue.$toast.error(`Không có hội đồng cho học viên ${item.Ho} ${item.Ten}`, { position: 'top' })
							hasError = true
							break
						}
						await this.insHoiDongApi(item) // Gọi API và chờ hoàn tất
						console.log(`Hội đồng đã được thêm cho học viên ${item.MSHV}`)
					} catch (error) {
						hasError = true
						console.error('Lỗi khi thêm hội đồng:', error)
						Vue.$toast.error(`Error ins hội đồng: ${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
						break
					}
				}

				if (!hasError) {
					CALL('getHoiDongDeTai')
					Vue.$toast.success(`Lập hội đồng thành công (${validItems.length} học viên)`, { position: 'top' })
					this.closeDialog()
				}
			},
	
			prepareHoiDongArr(item) {
				const { DsHoiDongGiangVien, switchData } = this
				const findMember = (name, role) => {
					// HoTenGiangVien
					const member = DsHoiDongGiangVien.find((viTri) => this.cleanString(viTri.HoTenHocHamHocVi.toUpperCase()) === this.cleanString(name.toUpperCase()))
					// console.log('name', member)
					if (member === undefined || member === null) {
						Vue.$toast.error(
							`Hội đồng ${item.Ho} ${item.Ten} không tìm thấy giảng viên ${name}. Vui lòng kiểm tra lại họ tên, học hàm học vị của thành
						                    viên hội đồng và cập nhật lại hội đồng này`,
							{ position: 'top', duration: 10000 },
						)
						console.log('not found member')
					}
					return member ? { ...member, ChucTrach: role } : null
				}
	
				return switchData === 2
					? [findMember(item.ChuTich, 'Chủ tịch'), findMember(item.PB1, 'Phản biện'), findMember(item.ThuKy, 'Thư ký')].filter(Boolean)
					: [
						findMember(item.ChuTich, 'Chủ tịch'),
						findMember(item.PB1, 'Phản biện 1'),
						findMember(item.PB2, 'Phản biện 2'),
						findMember(item.UyVien, 'Ủy viên'),
						findMember(item.ThuKy, 'Thư ký'),
					].filter(Boolean)
			},
	
			insHoiDongApi(item) {
				console.log('item:', item)
				return new Promise((resolve, reject) => {
					ajaxCALL(
						'/HoiDong_Ins',
						{
							Student_ID: item.MSHV,
							HoiDongThanhVienObj_Arr: item.hoiDongArr,
							ThoiGianBaoVe: this.councilTime,
						},
						(res) => {
							console.log('Thêm hội đồng thành công')
							resolve(res)
						},
						(error) => {
							console.error('Thêm hội đồng thất bại:', error)
							reject(error)
						},
					)
				})
			},
	
			loadExcelGVInfo(file) {
				const $this = this
				const reader = new FileReader()
	
				reader.onload = (e) => {
					try {
						const arrayBuffer = e.target.result
	
						const workbook = XLSX.read(arrayBuffer, { type: 'array' })
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]
						const json = XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: '' })
	
						const jsonData = []
						const jsonHeader = []
						let headerArr = []
						let isExcelHasGVHD2 = false
	
						json.forEach((row) => {
							const rowData = row
							jsonData.push([...rowData])
							jsonHeader.push([...rowData])
						})
	
						if (jsonData.length > 0) {
							// Remove first 4 elements
							jsonData.splice(0, 7)
							jsonHeader.splice(0, 6)
							// Remove last 7 elements
							// jsonData.splice(-7, 7);
							this.fileData = jsonData
							console.log('jsonHeader', jsonHeader)
						}
	
						// Ensure each row has length 14 by adding empty elements
						const maxLength = 15
						this.fileData = this.fileData.map((row) => {
							while (row.length < maxLength) {
								row.push('') // Add empty string or null as needed
							}
							return row
						})
	
						headerArr = jsonHeader.map((row) => {
							while (row.length < maxLength) {
								row.push('') // Add empty string or null as needed
							}
							return row
						})
						console.log('xxxxxxxxxx headerArr', headerArr, headerArr[0][headerArr[0].length - 1])
						const hasHeader = headerArr.length > 0 && headerArr[0][0].length > 0
						console.log("this.switchData === 2", this.switchData === 2)
						console.log("hasHeader", hasHeader)
						const thirdCondition = !!headerArr[0][headerArr[0].length - 3]
						console.log('Điều kiện thứ 3:', thirdCondition)
						console.log('Giá trị thực tế:', headerArr[0][headerArr[0].length - 3])
	
						if ((this.switchData === 2 && hasHeader && headerArr[0][headerArr[0].length - 3]) || (hasHeader && headerArr[0][headerArr[0].length - 1])) {
							isExcelHasGVHD2 = true
						}
						console.log('isExcelHasGVHD2', isExcelHasGVHD2)
						// this.fileData.splice(0, 1)
						// console.log("this.fileData", this.fileData)
	
						// Map fileData to objects and push to DataArr
						if (this.switchData === 2) {
							if (isExcelHasGVHD2) {
								this.DanhSachInfo = this.fileData
									.map((row) => {
										return {
											STT: row[0] || 0,
											MSHV: row[1] ? row[1].toString().trim() : '',
											Lop: row[2] || '',
											Ho: row[3] || '',
											Ten: row[4] || '',
											DeTai: row[5] || '',
											GVHD1: row[6] || '',
											GVHD2: row[7] || '',
											ChuTich: row[8] || '',
											PB1: row[9] || '',
											ThuKy: row[10] || '',
											...(this.loaiLapHoiDong === 1 && {
												SoQD: row[11].toString() || '',
												NgayQD: row[12] ? moment(row[12], ['D/M/YYYY', 'DD/M/YYYY', 'D/MM/YYYY'], true).format('DD/MM/YYYY') : '',
											}),
										}
									})
									.filter((item) => item.MSHV && item.MSHV !== '0')
							} else {
								this.DanhSachInfo = this.fileData
									.map((row) => {
										return {
											STT: row[0] || 0,
											MSHV: row[1] ? row[1].toString().trim() : '',
											Lop: row[2] || '',
											Ho: row[3] || '',
											Ten: row[4] || '',
											DeTai: row[5] || '',
											GVHD1: row[6] || '',
											GVHD2: '',
											ChuTich: row[7] || '',
											PB1: row[8] || '',
											ThuKy: row[9] || '',
											...(this.loaiLapHoiDong === 1 && {
												SoQD: row[10].toString() || '',
												NgayQD: row[11] ? moment(row[11], ['D/M/YYYY', 'DD/M/YYYY', 'D/MM/YYYY'], true).format('DD/MM/YYYY') : null,
											}),
										}
									})
									.filter((item) => item.MSHV && item.MSHV !== '0')
							}
						} else {
							if (isExcelHasGVHD2) {
								console.log('co 2 gvhd')
								this.DanhSachInfo = this.fileData
									.map((row) => {
										return {
											STT: row[0] || 0,
											MSHV: row[1] ? row[1].toString().trim() : '',
											Lop: row[2] || '',
											Ho: row[3] || '',
											Ten: row[4] || '',
											DeTai: row[5] || '',
											GVHD1: row[6] || '',
											GVHD2: row[7] || '',
											ChuTich: row[8] || '',
											PB1: row[9] || '',
											PB2: row[10] || '',
											ThuKy: row[11] || '',
											UyVien: row[12] || '',
											...(this.loaiLapHoiDong === 1 && {
												SoQD: row[13].toString() || '',
												NgayQD: row[14] ? moment(row[14], ['D/M/YYYY', 'DD/M/YYYY', 'D/MM/YYYY'], true).format('DD/MM/YYYY') : null,
											}),
										}
									})
									.filter((item) => item.MSHV && item.MSHV !== '0')
								console.log('this.DanhSachInfo xxxxx', this.DanhSachInfo)
							} else {
								console.log('co 1 gvhd')
								this.DanhSachInfo = this.fileData
									.map((row) => {
										return {
											STT: row[0] || 0,
											MSHV: row[1] ? row[1].toString().trim() : '',
											Lop: row[2] || '',
											Ho: row[3] || '',
											Ten: row[4] || '',
											DeTai: row[5] || '',
											GVHD1: row[6] || '',
											GVHD2: '',
											ChuTich: row[7] || '',
											PB1: row[8] || '',
											PB2: row[9] || '',
											ThuKy: row[10] || '',
											UyVien: row[11] || '',
											...(this.loaiLapHoiDong === 1 && {
												SoQD: row[12].toString() || '',
												NgayQD: row[13] ? moment(row[13], ['D/M/YYYY', 'DD/M/YYYY', 'D/MM/YYYY'], true).format('DD/MM/YYYY') : null,
											}),
										}
									})
									.filter((item) => item.MSHV && item.MSHV !== '0')
							}
						}
	
						this.labelTable = `Danh sách học viên đăng ký bảo vệ luận văn (${this.DanhSachInfo.length})`
	
						//thay đổi tableHeader khi có GVHD 2 hoặc không có
						if (this.DanhSachInfo.length > 0) {
							const check_GVHD2 = this.DanhSachInfo.some((item) => item.GVHD2)
							this.tableHeader = [
								{
									text: 'STT',
									value: 'STT',
									sortable: false,
									align: 'center',
									width: 50,
								},
								{
									text: 'MSHV',
									value: 'MSHV',
								},
								{
									text: 'Lớp',
									value: 'Lop',
								},
								{
									text: 'Họ',
									value: 'Ho',
								},
								{
									text: 'Tên',
									value: 'Ten',
								},
								{
									text: 'Trạng thái',
									value: 'KiemTraStatus',
									align: 'center',
									sortable: false,
									width: 170,
								},
								{
									text: 'Tên đề tài',
									value: 'DeTai',
								},
							]
							if (check_GVHD2) {
								this.tableHeader.push(
									{
										text: 'GVHD 1',
										value: 'GVHD1',
									},
									{
										text: 'GVHD 2',
										value: 'GVHD2',
									},
								)
							} else {
								this.tableHeader.push({
									text: 'GVHD',
									value: 'GVHD1',
								})
							}
							if (this.switchData === 2) {
								this.tableHeader.push(
									{
										text: 'Chủ tịch',
										value: 'ChuTich',
									},
									{
										text: 'Phản biện',
										value: 'PB1',
									},
									{
										text: 'Thư ký',
										value: 'ThuKy',
									},
								)
							} else {
								this.tableHeader.push(
									{
										text: 'Chủ tịch',
										value: 'ChuTich',
									},
									{
										text: 'Phản biện 1',
										value: 'PB1',
									},
									{
										text: 'Phản biện 2',
										value: 'PB2',
									},
									{
										text: 'Thư ký',
										value: 'ThuKy',
									},
									{
										text: 'Ủy viên',
										value: 'UyVien',
									},
								)
							}
	
							if (this.loaiLapHoiDong === 1) {
								this.tableHeader.push(
									{
										text: 'Số quyết định',
										value: 'SoQD',
									},
									{
										text: 'Ngày quyết định',
										value: 'NgayQD',
									},
								)
							}
						}
	
						console.log('this.DanhSachInfo', this.DanhSachInfo)
						console.log('this.fileData', this.fileData)
					} catch (error) {
						console.error('Error loading Excel file:', error)
						Vue.$toast.error(`${error}`, { position: 'top' })
					}
				}
	
				reader.readAsArrayBuffer(file)
			},
			deleteFile() {
				this.fileUpload = null
				this.DanhSachInfo = []
				this.labelTable = 'Danh sách học viên đăng ký bảo vệ luận văn'
			},
			closeDialog() {
				vueData.isExcelDialog = false
				this.deleteFile()
				this.labelTable = 'Danh sách học viên đăng ký bảo vệ luận văn'
			},
		},
	}
</script>