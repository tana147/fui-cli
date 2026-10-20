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
					this.cloneData = JSON.parse(JSON.stringify(this.thongtinhocvien))
					console.log('this.cloneData', this.cloneData)
				}
			},
		},
		methods: {
			removeFile() {
				this.dsHocVien.DecisionFile_ID = null
				this.dsHocVien.DecisionFile_Url = null
				this.dsHocVien.DecisionFile_Name = null
				this.fileName = null
			},
	
			uploadFile(value) {
				// console.log("Upload file api", value)
				let file = value.Files[0]
				this.dsHocVien.DecisionFile_ID = file.FILE_ID
				this.dsHocVien.DecisionFile_Url = file.FILE_URL
				this.dsHocVien.DecisionFile_Name = file.FILE_NAME
				this.fileName = file.FILE_NAME
			},
	
			deleteFile(fileID) {
				const $this = this
				return new Promise((resolve, reject) => {
					ajaxCALL(
						'/FileData_Delete',
						{
							FileID: fileID,
						},
						(res) => {
							resolve('success')
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							console.log('fali to delete file', error.responseJSON.Message)
							reject('error')
						},
					)
				})
			},
	
			async onSaveSQD() {
				const $this = this
				console.log('$this.dsHocVien', $this.dsHocVien)
				if ($this.dsHocVien.Decision_SoQD !== '') {
					if($this.cloneData.DecisionFile_ID){
						await $this.deleteFile($this.cloneData.DecisionFile_ID)
					}

					ajaxCALL(
						'/HoiDong_Upd_SoQD',
						{
							Decision_ID: $this.dsHocVien.Decision_ID,
							Decision_SoQD: $this.dsHocVien.Decision_SoQD,
							Decision_NgayQD: $this.dsHocVien.Decision_NgayQD,
							Decision_ThangQD: $this.dsHocVien.Decision_ThangQD,
							Decision_NamQD: $this.dsHocVien.Decision_NamQD,
							DecisionFile_ID: $this.dsHocVien.DecisionFile_ID,
							DecisionFile_Url: $this.dsHocVien.DecisionFile_Url,
							DecisionFile_Name: $this.dsHocVien.DecisionFile_Name,
							HoiDong_ID: $this.dsHocVien.HoiDongID,
							Student_ID: $this.dsHocVien.StudentID,
						},
						(res) => {
							Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
							// console.log("Update SQD complete", vueData.dsGetHoiDong)
							CALL('getHoiDongDeTai')
						},
						(error) => {
							Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
							// console.log("Error to update SQD", error)
						},
					)
					vueData.isSQDDialog = false
				} else {
					Vue.$toast.error(`Chưa nhập Số quyết dịnh`, { position: 'top' })
				}
			},
			onClose() {
				vueData.isSQDDialog = false
			},
		},
	}
</script>