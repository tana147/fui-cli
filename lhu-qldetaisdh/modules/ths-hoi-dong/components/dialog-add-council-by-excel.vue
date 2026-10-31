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
							:color="item.statusColor || 'grey'"
							label
							outlined
							class="font-weight-medium"
						>
							{{ item.statusText || 'Chờ dữ liệu...' }}
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

			parseExcelDate(val) {
				if (!val) return ''
				if (typeof val === 'number') {
					// Excel serial date to JS Date
					const dateObj = new Date(Math.round((val - 25569) * 86400 * 1000))
					const d = String(dateObj.getUTCDate()).padStart(2, '0')
					const m = String(dateObj.getUTCMonth() + 1).padStart(2, '0')
					const y = dateObj.getUTCFullYear()
					return `${d}/${m}/${y}`
				}
				const str = String(val).trim()
				// Regex nhanh không backtracking
				const mMatch = str.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/)
				if (mMatch) {
					return `${mMatch[1].padStart(2, '0')}/${mMatch[2].padStart(2, '0')}/${mMatch[3]}`
				}
				const isoMatch = str.match(/^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/)
				if (isoMatch) {
					return `${isoMatch[3].padStart(2, '0')}/${isoMatch[2].padStart(2, '0')}/${isoMatch[1]}`
				}
				return str
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
				const validItems = this.DanhSachInfo.filter((item) => item.canProcess)
				const skippedItems = this.DanhSachInfo.filter((item) => !item.canProcess)

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

								// GUARD TUYỆT ĐỐI: Không bao giờ ghi đè nếu hội đồng này đã có số QĐ thực tế từ trước!
								const rawSoQD = String(currentDetail.Decision_SoQD || '').trim()
								const hasRealSoQD = rawSoQD !== '' && rawSoQD !== '/QĐ-ĐHLH' && rawSoQD.replace('/QĐ-ĐHLH', '').trim() !== ''
								if (hasRealSoQD) {
									console.warn(`Hội đồng ID ${currentDetail.HoiDongID} của học viên ${item.MSHV} đã có số QĐ (${currentDetail.Decision_SoQD}), bỏ qua không ghi đè`)
									continue
								}

								const splitNgayQD = String(item.NgayQD || '').split('/')
								if (splitNgayQD.length !== 3) {
									console.warn(`Ngày QĐ không hợp lệ cho học viên ${item.MSHV}: ${item.NgayQD}`)
									continue
								}
								const ngayQD = splitNgayQD[0].padStart(2, '0')
								const thangQD = splitNgayQD[1].padStart(2, '0')
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
				const validItems = this.DanhSachInfo.filter((item) => item.canProcess)
				const skippedItems = this.DanhSachInfo.filter((item) => !item.canProcess)

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
	
						if (!json || json.length === 0) {
							Vue.$toast.warning('File Excel không có dữ liệu', { position: 'top' })
							return
						}

						// 1. Tự động định vị dòng Header (dòng có chứa MSHV hoặc STT)
						let headerRowIndex = -1
						for (let i = 0; i < Math.min(json.length, 25); i++) {
							const row = json[i]
							if (Array.isArray(row)) {
								const hasMshv = row.some((c) => {
									const s = String(c || '').trim().toUpperCase()
									return s === 'MSHV' || s === 'MÃ HỌC VIÊN' || s === 'MA HOC VIEN'
								})
								if (hasMshv) {
									headerRowIndex = i
									break
								}
							}
						}

						if (headerRowIndex === -1) {
							for (let i = 0; i < Math.min(json.length, 25); i++) {
								const row = json[i]
								if (Array.isArray(row)) {
									const hasStt = row.some((c) => String(c || '').trim().toUpperCase() === 'STT')
									if (hasStt) {
										headerRowIndex = i
										break
									}
								}
							}
						}

						// Fallback: nếu không tìm thấy, dùng index 6 (template chuẩn có 6 dòng đầu) hoặc index 0
						if (headerRowIndex === -1) {
							headerRowIndex = json.length > 7 ? 6 : 0
						}

						const rawHeader = json[headerRowIndex] || []
						const rawData = json.slice(headerRowIndex + 1)

						// 2. Helper tìm index của cột theo từ khóa tiêu đề (không phụ thuộc thứ tự cố định)
						const findCol = (keywords, defaultIdx) => {
							const idx = rawHeader.findIndex((c) => {
								const s = String(c || '').trim().toUpperCase()
								return keywords.some((kw) => s === kw || s.includes(kw))
							})
							return idx !== -1 ? idx : defaultIdx
						}

						const isExcelHasGVHD2 = rawHeader.some((c) => {
							const s = String(c || '').trim().toUpperCase()
							return s.includes('GVHD 2') || s.includes('GVHD2') || s.includes('HƯỚNG DẪN 2') || s.includes('HUONG DAN 2')
						})

						const colSTT = findCol(['STT'], 0)
						const colMSHV = findCol(['MSHV', 'MÃ HỌC VIÊN', 'MA HOC VIEN'], 1)
						const colLop = findCol(['LỚP', 'LOP'], 2)
						const colHo = findCol(['HỌ', 'HO'], 3)
						const colTen = findCol(['TÊN', 'TEN'], 4)
						const colDeTai = findCol(['TÊN ĐỀ TÀI', 'TEN DE TAI', 'ĐỀ TÀI', 'DE TAI'], 5)
						const colGVHD1 = findCol(['GVHD 1', 'GVHD1', 'GVHD'], 6)
						const colGVHD2 = isExcelHasGVHD2 ? findCol(['GVHD 2', 'GVHD2'], 7) : -1
						const colChuTich = findCol(['CHỦ TỊCH', 'CHU TICH'], isExcelHasGVHD2 ? 8 : 7)
						const colPB1 = findCol(['PHẢN BIỆN 1', 'PHAN BIEN 1', 'PB1', 'PHẢN BIỆN', 'PHAN BIEN'], isExcelHasGVHD2 ? 9 : 8)
						const colPB2 = this.switchData === 2 ? -1 : findCol(['PHẢN BIỆN 2', 'PHAN BIEN 2', 'PB2'], isExcelHasGVHD2 ? 10 : 9)
						const colThuKy = findCol(['THƯ KÝ', 'THU KY'], this.switchData === 2 ? (isExcelHasGVHD2 ? 10 : 9) : (isExcelHasGVHD2 ? 11 : 10))
						const colUyVien = this.switchData === 2 ? -1 : findCol(['ỦY VIÊN', 'UY VIEN'], isExcelHasGVHD2 ? 12 : 11)
						const colSoQD = findCol(['SỐ QUYẾT ĐỊNH', 'SO QUYET DINH', 'SỐ QĐ', 'SO QD'], isExcelHasGVHD2 ? (this.switchData === 2 ? 11 : 13) : (this.switchData === 2 ? 10 : 12))
						const colNgayQD = findCol(['NGÀY QUYẾT ĐỊNH', 'NGAY QUYET DINH', 'NGÀY QĐ', 'NGAY QD'], isExcelHasGVHD2 ? (this.switchData === 2 ? 12 : 14) : (this.switchData === 2 ? 11 : 13))

						// 3. Map dữ liệu học viên
						this.DanhSachInfo = rawData
							.filter((row) => Array.isArray(row) && row.length > 0)
							.map((row) => {
								const mshvVal = row[colMSHV] ? String(row[colMSHV]).trim() : ''
								const item = {
									STT: row[colSTT] || 0,
									MSHV: mshvVal,
									Lop: row[colLop] || '',
									Ho: row[colHo] || '',
									Ten: row[colTen] || '',
									DeTai: row[colDeTai] || '',
									GVHD1: row[colGVHD1] || '',
									GVHD2: colGVHD2 !== -1 ? (row[colGVHD2] || '') : '',
									ChuTich: row[colChuTich] || '',
									PB1: row[colPB1] || '',
									PB2: colPB2 !== -1 ? (row[colPB2] || '') : '',
									ThuKy: row[colThuKy] || '',
									UyVien: colUyVien !== -1 ? (row[colUyVien] || '') : '',
									...(this.loaiLapHoiDong === 1 && {
										SoQD: colSoQD !== -1 && row[colSoQD] ? String(row[colSoQD]).trim() : '',
										NgayQD: colNgayQD !== -1 && row[colNgayQD] ? this.parseExcelDate(row[colNgayQD]) : '',
									}),
								}
								const st = this.getStudentStatus(mshvVal)
								return {
									...item,
									statusColor: st.color,
									statusText: st.text,
									canProcess: st.canProcess,
								}
							})
							.filter((item) => item.MSHV && item.MSHV !== '0' && item.MSHV.toUpperCase() !== 'MSHV')

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