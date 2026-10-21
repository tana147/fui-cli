<template>
	<div>
		<v-dialog v-model="vueData.isExcelDialog" persistent eager transition="dialog-bottom-transition"
			max-width="1680px">
			<v-card>
				<c-toolbar @onClose="closeDialog">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Thêm giảng viên</p>
					</template>
				</c-toolbar>

				<v-card-text>
					<div class="d-flex mb-3 ml-auto wrapSelect">
						<v-file-input v-model="fileUpload" dense hide-details
							accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
							label="Chọn file Excel" outlined />

						<v-chip class="ml-3" color="deep-purple accent-4" outlined label hide-details>
							<v-icon left>mdi-file-check-outline</v-icon>
							<a style="color: deep-purple accent-4"
								:href="vueData.v_Set.urlReadFile + 'fileData/' + fileTemplate_Id">File
								template
								mẫu</a>
						</v-chip>
					</div>
					<div class="justify-start wrapSelect mt-3 mb-3">
						<v-select v-model="NganhIDSelected" outlined dense hide-details label="Ngành giảng dạy"
							:items="NganhDay" item-text="TenNganh" item-value="NganhID" />
					</div>

					<v-card>
						<v-card-title class="primary--text">
							{{ labelTable }}
							<v-spacer></v-spacer>
							<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" single-line
								hide-details></v-text-field>
						</v-card-title>
						<v-data-table :headers="tableHeader" :items="GiangVienInfo">
							<template v-slot:item.Nganh="{ item }">
								<v-autocomplete v-model="item.NganhID" :items="NganhDay" item-text="TenNganh"
									item-value="NganhID" outlined dense hide-details @change="updateCheckNganhEmpty" />
							</template>
							<template v-slot:item.SoDienThoai="{ item }">
								<div>
									<b>{{ item.DienThoai }}</b>
									<p>{{ item.Email_GV }}</p>
								</div>
							</template>
						</v-data-table>
					</v-card>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="success" @click="onAddTeacher" :disabled="checkNganhEmpty">Thêm giảng viên</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ['nganhgiangday', 'dsgiangvien'],
		data() {
			return {
				fileUpload: null,
				fileData: null,
				labelTable: 'Danh sách giảng viên',
				GiangVienInfo: [],
				HeArr: [],
				NganhIDSelected: 0,
				search: '',
				fileTemplate_Id: "63A90EBC05904BBE9FA74D03F6E284C9",
				checkNganhEmpty: true,
	
				tableHeader: [
					{
						text: 'STT',
						value: 'STT',
						sortable: false,
						align: 'center',
						width: 50,
					},
					{
						text: 'Học hàm học vị',
						value: 'HocHamHocVi',
						sortable: false,
						align: 'center',
						width: 140,
					},
					{
						text: 'Họ và tên',
						value: 'HoTen',
						width: 140,
					},
					{
						text: 'Ngành',
						value: 'Nganh',
						sortable: false,
						align: 'center',
						width: 240,
					},
					{
						text: 'Đơn vị công tác',
						sortable: false,
						value: 'DonVi',
						width: 200,
					},
					{
						text: 'SĐT/Email',
						value: 'SoDienThoai',
						sortable: false,
						width: 180,
					},
					{
						text: 'Ngân hàng',
						value: 'TenNganHang',
						sortable: false,
						width: 150,
					},
					{
						text: 'Mã số thuế',
						value: 'MaSoThue',
						sortable: false,
						width: 150,
					},
					{
						text: 'Địa chỉ',
						value: 'DiaChi',
						sortable: false,
					},
				],
			}
		},
		mounted() { },
		computed: {
			NganhDay: function () {
				return this.nganhgiangday
			},
			IsExcelDialog: function () {
				return vueData.isExcelDialog
			},
			DsGiangVien: function () {
				return this.dsgiangvien
			},
		},
		watch: {
			fileUpload: function (val) {
				if (val) {
					this.loadExcelGVInfo(val)
					this.NganhIDSelected = 0
				} else {
					this.deleteFile()
				}
			},
			NganhIDSelected(val) {
				console.log('val', val)
				if (this.GiangVienInfo.length > 0 && val) {
					this.GiangVienInfo.forEach((item) => {
						item.NganhGiangDay = this.GetTenNganh(parseInt(val))
						item.NganhID = val
					})
					this.updateCheckNganhEmpty()
				}
			},
		},
		methods: {
			GetTenNganh(nganhID) {
				if (this.NganhDay) {
					const data = this.NganhDay.find((item) => item.NganhID == nganhID)
					console.log('data', data)
					return data.TenNganh
				}
			},
			async onAddTeacher() {
				console.log('this.GiangVienInfo', this.GiangVienInfo)
				let hasError = false
	
				for (let item of this.GiangVienInfo) {
					try {
						await this.addteacherAPI(item)
					} catch (error) {
						console.log('Error in adding teacher', error)
						hasError = true
						Vue.$toast.error(`Error adding teacher: ${error.responseJSON ? error.responseJSON.Message : error.message}`, {
							position: 'top',
						})
						break
					}
				}
	
				if (!hasError) {
					Vue.$toast.success(`Thêm giảng viên thành công`, { position: 'top' })
					CALL('getDsGiangVien')
					this.closeDialog()
				}
			},
			addteacherAPI(item) {
				console.log('item.NganhID', item.NganhID)
				return new Promise((resolve, reject) => {
					ajaxCALL(
						'/giangvien_ins',
						{
							HocViHocHam: item.HocHamHocVi,
							HoTenGiangVien: item.HoTen,
							CoQuanCongTac: item.DonVi,
							NganhID: item.NganhID,
							NganhGiangDay: this.GetTenNganh(parseInt(item.NganhID)),
							DiaChi: item.DiaChi,
							SoDienThoai: item.DienThoai,
	
							TenNganHang: item.TenNganHang,
							SoTKNganHang: item.SoTKNganHang,
							MaSoThue: item.MaSoThue,
							Email_GV: item.Email_GV,
						},
						(res) => {
							console.log('Add teacher success')
							resolve(res)
						},
						(error) => {
							console.log('Fail to add teacher')
							reject(error)
						},
					)
				})
			},
			updateCheckNganhEmpty() {
				if (this.GiangVienInfo.length > 0) {
					this.checkNganhEmpty = this.GiangVienInfo.some((item) => item.NganhID === 0)
				} else {
					this.checkNganhEmpty = true
				}
				console.log('checkNganhEmpty', this.checkNganhEmpty)
			},
			loadExcelGVInfo(file) {
				const reader = new FileReader()
	
				reader.onload = (e) => {
					try {
						const arrayBuffer = e.target.result
	
						const workbook = XLSX.read(arrayBuffer, { type: 'array' })
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]
						const json = XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: '' })
	
						const jsonData = []
	
						json.forEach((row) => {
							jsonData.push([...row])
						})
	
						if (jsonData.length > 0) {
							// Remove first 1 elements
							jsonData.splice(0, 1)
							this.fileData = jsonData
							this.labelTable = `Danh sách giảng viên (${this.fileData.length})`
						}
	
						// Ensure each row has length 14 by adding empty elements
						const maxLength = 15
						this.fileData = this.fileData.map((row) => {
							while (row.length < maxLength) {
								row.push('') // Add empty string or null as needed
							}
							return row
						})
	
						console.log('this.fileDataxxxx', this.fileData)
	
						// Map fileData to objects and push to DataArr
						this.GiangVienInfo = this.fileData.map((row) => {
							return {
								STT: row[0] || null,
								Nganh: row[1] || null,
								HocHamHocVi: row[2] ? row[2].trim().replace(/\.$/, '') : null,
								HoTen: row[3] || null,
								DonVi: row[4] || null,
								// DienThoai: typeof row[5] === 'object' ? (row[5].text.trim() || null) : (row[5].trim() || null),
								DienThoai: typeof row[5] === 'object' ? row[5].text.toString().trim() || null : row[5].toString().trim() || null,
								Email_GV: typeof row[6] === 'object' ? row[6].text.toString().trim() || null : row[6].toString().trim() || null,
								DiaChi: row[7] || null,
								MaSoThue: row[8] || null,
								SoTKNganHang: row[9] || null,
								TenNganHang: row[10] || null,
								NganhID: 0,
								NganhGiangDay: '',
							}
						})
	
						this.label = `Danh sách giảng viên (${this.GiangVienInfo.length})`
	
						console.log('this.GiangVienInfo', this.GiangVienInfo)
						console.log('this.fileData', this.fileData)
					} catch (error) {
						console.error('Error loading Excel file:', error)
					}
				}
	
				reader.readAsArrayBuffer(file)
			},
			deleteFile() {
				this.fileUpload = null
				this.fileData = null
				this.GiangVienInfo = []
				this.NganhIDSelected = 0
				this.labelTable = 'Danh sách giảng viên'
			},
			closeDialog() {
				vueData.isExcelDialog = false
				this.deleteFile()
				this.NganhIDSelected = 0
				this.labelTable = 'Danh sách giảng viên'
			},
		},
	}
</script>