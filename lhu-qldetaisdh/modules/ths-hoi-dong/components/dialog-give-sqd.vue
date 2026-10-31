<template>
	<div>
		<v-dialog v-model="vueData.isSQDDialog" transition="dialog-bottom-transition" max-width="1024px" persistent>
			<v-card>
				<c-toolbar @onClose="onClose">
					<template v-slot:title>
						<p class="title mb-0 primary--text">
							Cập nhật SQĐ HV:
							<span class="red--text">[{{ HoiDong.Student_ID }}] {{ HoiDong.Ho_SV }} {{ HoiDong.Ten_SV }}
								[{{ HoiDong.Lop_ID }}] </span>
						</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-row style="margin: 0px">
						<v-col cols="3" class="pl-0">
							<!--:disabled="dsHocVien.HoiDong_Status !== 0"-->
							<v-text-field v-model="dsHocVien.Decision_SoQD" outlined color="success" dense hide-details
								label="Số quyết định" />
						</v-col>
						<v-col cols="2" class="pl-0">
							<!--:disabled="dsHocVien.HoiDong_Status !== 0"-->
							<c-text-field-sqd outlined dense :ngay.sync="dsHocVien.Decision_NgayQD"
								:thang.sync="dsHocVien.Decision_ThangQD" :nam.sync="dsHocVien.Decision_NamQD"
								label="Ngày quyết định" color="success"
								hint="Ví dụ: Nhập 28/02/2024 theo cú pháp: 28022024" hide-details />
						</v-col>
						<v-col class="pl-0">
							<div class="d-flex">
								<!--v-if="dsHocVien.HoiDong_Status === 0"-->
								<div cols="3">
									<f-file-upload label="" :url="vueData.v_Set.apiFile" :filters="fileRules"
										color="v-btn--outlined v-size--default info--text" @input="uploadFile"
										hide-details />
								</div>
								<div style="margin-top: 2px">
									<!--v-if="dsHocVien.HoiDong_Status === 0"-->
									<div class="ml-3">
										<v-chip v-if="dsHocVien.DecisionFile_ID" color="deep-purple accent-4" outlined
											label hide-details close @click:close="removeFile">
											<v-icon left>mdi-file-check-outline</v-icon>
											<a style="color: deep-purple accent-4"
												:href="vueData.v_Set.urlReadFile + dsHocVien.DecisionFile_Url"
												target="_blank">{{
												dsHocVien.DecisionFile_Name ?? fileName
												}}</a>
										</v-chip>
										<v-chip v-else color="deep-purple accent-4" outlined label hide-details> File
											quyết định </v-chip>
									</div>
								</div>
							</div>
						</v-col>
					</v-row>

					<v-row style="margin: 0" dense>
						<v-col class="pl-0">
							<f-table :headers="councilHeader" :items="dsHoiDong" itemKey="STT" hideDefaultFooter="true"
								label="Danh sách hội đồng" :dense="true" />
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<!--v-if="dsHocVien.HoiDong_Status === 0"-->
					<v-btn color="primary" @click="onSaveSQD" dark>Cập nhật SQĐ</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ['thongtinhocvien', 'dsgiangvien', 'editedItem'],
		data() {
			return {
				cloneData: null,
				fileName: '',
				fileRules: {
					max_file_size: '100mb',
					mime_types: [
						{
							title: 'All files',
							extensions: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg',
						},
					],
				},
				studentHeader: [
					{
						text: 'MSSV',
						value: 'StudentID',
					},
					{
						text: 'Họ và tên',
						value: 'HoTen',
					},
					{
						text: 'Tên đề tài',
						value: 'DeTai',
					},
					{
						text: 'Ngành',
						value: 'TenNganh',
					},
				],
				councilHeader: [
					{
						text: 'STT',
						value: 'STT',
						width: 50,
						sortable: false,
						align: 'center',
					},
					{
						text: 'Họ và tên',
						value: 'HoTenHocHamHocVi',
					},
					{
						text: 'Ngành giảng dạy',
						value: 'NganhGiangDay',
					},
					{
						text: 'Cơ quan công tác',
						value: 'CoQuanCongTac',
					},
					{
						text: 'Chức trách',
						value: 'ChucTrach',
					},
				],
			}
		},
		mounted() { },
		computed: {
			dsHocVien: function () {
				return this.thongtinhocvien ?? {}
			},
			dsHoiDong: function () {
				if (this.dsgiangvien) {
					console.log('this.dsgiangvien', this.dsgiangvien)
					return this.dsgiangvien
						.filter((item) => item.GiangVienID)
						.map((item, index) => {
							return {
								...item,
								STT: index + 1,
							}
						})
				}
			},
			HoiDong: function () {
				return this.editedItem
			},
			IsSQDDialog: function () {
				return vueData.isSQDDialog
			},
		},
		watch: {
			IsSQDDialog(val) {
				if (val) {
					if (this.dsHocVien.Decision_NgayQD && String(this.dsHocVien.Decision_NgayQD).includes('.')) {
						this.dsHocVien.Decision_NgayQD = ''
					}
					if (this.dsHocVien.Decision_ThangQD && String(this.dsHocVien.Decision_ThangQD).includes('.')) {
						this.dsHocVien.Decision_ThangQD = ''
					}
					if (this.dsHocVien.Decision_NamQD && String(this.dsHocVien.Decision_NamQD).includes('.')) {
						this.dsHocVien.Decision_NamQD = ''
					}
					if (this.dsHocVien.Decision_SoQD && String(this.dsHocVien.Decision_SoQD).trim() === '/QĐ-ĐHLH') {
						this.dsHocVien.Decision_SoQD = ''
					}
					this.cloneData = JSON.parse(JSON.stringify(this.thongtinhocvien))
					console.log('this.cloneData', this.cloneData)
				}
			},
		},
		methods: {
			removeFile() {
				if (this.dsHocVien.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== this.cloneData?.DecisionFile_ID) {
					this.deleteFile(this.dsHocVien.DecisionFile_ID)
				}
				this.dsHocVien.DecisionFile_ID = null
				this.dsHocVien.DecisionFile_Url = null
				this.dsHocVien.DecisionFile_Name = null
				this.fileName = null
			},
	
			uploadFile(value) {
				let file = value.Files[0]
				const fileId = file.FILE_ID ?? file.File_ID ?? file.id
				const fileUrl = file.FILE_URL ?? file.File_URL ?? (fileId ? '/FileData/' + fileId : null)
				const fileName = file.FILE_NAME ?? file.File_Name ?? file.name

				// Nếu trước đó đã upload file mới khác trong phiên này thì xóa file tạm đó đi
				if (this.dsHocVien.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== this.cloneData?.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== fileId) {
					this.deleteFile(this.dsHocVien.DecisionFile_ID)
				}

				this.dsHocVien.DecisionFile_ID = fileId
				this.dsHocVien.DecisionFile_Url = fileUrl
				this.dsHocVien.DecisionFile_Name = fileName
				this.fileName = fileName
			},
	
			deleteFile(fileID) {
				if (!fileID) return Promise.resolve('skip')
				return new Promise((resolve) => {
					ajaxCALL(
						'/FILE_FileDelete',
						{
							FileID: fileID,
						},
						(res) => {
							resolve('success')
						},
						(error) => {
							console.log('fail to delete file', error?.responseJSON?.Message)
							resolve('error')
						},
					)
				})
			},
	
			async onSaveSQD() {
				const $this = this
				if ($this.dsHocVien.Decision_SoQD !== '') {
					// Chỉ xóa file cũ trong DB nếu người dùng đã thay thế bằng file mới
					if ($this.cloneData?.DecisionFile_ID && $this.cloneData.DecisionFile_ID !== $this.dsHocVien.DecisionFile_ID) {
						await $this.deleteFile($this.cloneData.DecisionFile_ID)
					}

					const cleanNgay = String($this.dsHocVien.Decision_NgayQD || '').trim()
					const cleanThang = String($this.dsHocVien.Decision_ThangQD || '').trim()
					const cleanNam = String($this.dsHocVien.Decision_NamQD || '').trim()

					ajaxCALL(
						'/HoiDong_Upd_SoQD',
						{
							Decision_ID: $this.dsHocVien.Decision_ID,
							Decision_SoQD: $this.dsHocVien.Decision_SoQD,
							Decision_NgayQD: cleanNgay.includes('.') ? null : (cleanNgay ? cleanNgay.padStart(2, '0') : null),
							Decision_ThangQD: cleanThang.includes('.') ? null : (cleanThang ? cleanThang.padStart(2, '0') : null),
							Decision_NamQD: cleanNam.includes('.') ? null : (cleanNam || null),
							DecisionFile_ID: $this.dsHocVien.DecisionFile_ID,
							DecisionFile_Url: $this.dsHocVien.DecisionFile_Url,
							DecisionFile_Name: $this.dsHocVien.DecisionFile_Name,
							HoiDong_ID: $this.dsHocVien.HoiDongID,
							Student_ID: $this.dsHocVien.StudentID,
						},
						(res) => {
							Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
							CALL('getHoiDongDeTai')
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON?.Message || 'Lỗi cập nhật'}`, { position: 'top' })
						},
					)
					vueData.isSQDDialog = false
				} else {
					Vue.$toast.error(`Chưa nhập Số quyết định`, { position: 'top' })
				}
			},
			async onClose() {
				// Nếu upload file mới mà không lưu thì xóa file rác
				if (this.dsHocVien.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== this.cloneData?.DecisionFile_ID) {
					await this.deleteFile(this.dsHocVien.DecisionFile_ID)
				}
				vueData.isSQDDialog = false
			},
		},
	}
</script>