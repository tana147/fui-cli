<template>
	<div>
		<v-dialog v-model="vueData.isUpdDialog" persistent eager transition="dialog-bottom-transition"
			max-width="900px">
			<v-card>
				<c-toolbar @onClose="closeDialog">
					<template v-slot:title>
						<p class="title mb-0 primary--text">
							Cập nhật giảng viên <span class="red--text">{{ TeacherObj.HocViHocHam }}. {{
								TeacherObj.HoTenGiangVien }}</span>
						</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-form ref="form">
						<v-row dense>
							<v-col cols="3">
								<v-select v-model="TeacherObj.HocViHocHam" outlined dense hide-details
									label="Học hàm học vị" :items="vueData.DsGetHocHam" item-text="Column1"
									item-value="Column1" />
							</v-col>
							<v-col cols="9">
								<v-text-field v-model="TeacherObj.HoTenGiangVien" label="Họ tên giảng viên" outlined
									dense hide-details :rules="[(v) => !!v || !isNaN(parseFloat(v))]" />
							</v-col>

							<v-col cols="4">
								<v-autocomplete v-model="TeacherObj.NganhID" :items="NganhGiangDay" item-text="TenNganh"
									item-value="NganhID" dense outlined hide-details label="Ngành giảng dạy" />
							</v-col>
							<v-col cols="4">
								<v-text-field v-model="TeacherObj.SoDienThoai" outlined dense hide-details
									label="Số điện thoại" />
							</v-col>
							<v-col cols="4">
								<v-text-field v-model="TeacherObj.Email_GV" type="email" outlined dense hide-details
									label="Email" />
							</v-col>

							<v-col cols="6">
								<v-text-field v-model="TeacherObj.CoQuanCongTac" label="Cơ quan công tác" outlined dense
									hide-details :rules="[(v) => !!v || !isNaN(parseFloat(v))]" />
							</v-col>
							<v-col cols="6">
								<v-text-field v-model="TeacherObj.CoQuanCongTacTiengViet"
									placeholder="Dành cho ngành Ngôn ngữ Anh" label="Cơ quan công tác (bằng tiếng Việt)"
									outlined dense hide-details />
							</v-col>

							<v-col cols="12">
								<v-textarea rows="2" v-model="TeacherObj.DiaChi" label="Địa chỉ" outlined dense
									hide-details />
							</v-col>

							<v-col cols="4">
								<v-text-field v-model="TeacherObj.TenNganHang" outlined dense hide-details
									label="Tên ngân hàng" />
							</v-col>
							<v-col cols="4">
								<v-text-field v-model="TeacherObj.SoTKNganHang" outlined dense hide-details
									label="Số TK ngân hàng" />
							</v-col>
							<v-col cols="4">
								<v-text-field v-model="TeacherObj.MaSoThue" outlined dense hide-details
									label="Mã số thuế" />
							</v-col>
						</v-row>

						<div class="mt-3">
							<h3>File văn bằng</h3>
							<div class="d-flex align-center ml-auto" style="gap: 15px">
								<div>
									<f-file-upload label="" v-model="VanBang_Upload" :url="vueData.v_Set.apiFile"
										:filters="fileRules" color="v-btn--outlined v-size--default info--text" />
								</div>
								<div class="mt-3">
									<div v-if="TeacherObj.FileVanBang_ID">
										<v-chip label outlined close class="mb-3" color="deep-purple accent-4"
											@click:close="deleteVanBangFile">
											<v-icon left>mdi-file-check-outline</v-icon>
											<a :href="vueData.v_Set.urlReadFile + TeacherObj.FileVanBang_Url"
												target="_blank" style="color: deep-purple accent-4">{{
												TeacherObj.FileVanBang_Name
												}}</a>
										</v-chip>
									</div>

									<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload
										file </v-chip>
								</div>
							</div>
						</div>
						<div class="mt-3">
							<h3>File lý lịch</h3>
							<div class="d-flex align-center ml-auto" style="gap: 15px">
								<div>
									<f-file-upload label="" v-model="LyLich_Upload" :url="vueData.v_Set.apiFile"
										:filters="fileRules" color="v-btn--outlined v-size--default info--text" />
								</div>
								<div class="mt-3">
									<div v-if="TeacherObj.FileLyLichKH_ID">
										<v-chip label outlined close class="mb-3" color="deep-purple accent-4"
											@click:close="deleteLyLichFile">
											<v-icon left>mdi-file-check-outline</v-icon>
											<a :href="vueData.v_Set.urlReadFile + TeacherObj.FileLyLichKH_Url"
												target="_blank" style="color: deep-purple accent-4">{{
												TeacherObj.FileLyLichKH_Name
												}}</a>
										</v-chip>
									</div>

									<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload
										file </v-chip>
								</div>
							</div>
						</div>
					</v-form>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="updateGiangVien()" color="success"><v-icon left>mdi-content-save-outline</v-icon>
						Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ['teacheredit', 'dsgiangvien'],
		data() {
			return {
				cloneTeacherEdit: null,
				HeArr: [],
				LyLich_Upload: null,
				VanBang_Upload: null,
				TeacherObj: {},
	
				fileRules: {
					max_file_size: '50mb',
					mime_types: [
						{
							title: 'Pdf files',
							extensions: 'pdf',
						},
					],
				},
			}
		},
		mounted() { },
		computed: {
			IsUpdDialog: function () {
				return vueData.isUpdDialog
			},
			DsGiangVien: function () {
				return this.dsgiangvien
			},
			// TeacherObj: function () {
			// 	return JSON.parse(JSON.stringify(this.teacheredit))
			// },
			NganhGiangDay: function () {
				return vueData.NganhGiangDay
			},
		},
		watch: {
			VanBang_Upload: function (val) {
				if (val) {
					console.log('val', val.Files[0].FILE_NAME)
					this.TeacherObj.FileVanBang_ID = val.Files[0].FILE_ID
					this.TeacherObj.FileVanBang_Name = val.Files[0].FILE_NAME
					this.TeacherObj.FileVanBang_Url = val.Files[0].FILE_URL
				}
			},
			LyLich_Upload: function (val) {
				if (val) {
					console.log('val', val.Files[0].FILE_NAME)
					this.TeacherObj.FileLyLichKH_ID = val.Files[0].FILE_ID
					this.TeacherObj.FileLyLichKH_Name = val.Files[0].FILE_NAME
					this.TeacherObj.FileLyLichKH_Url = val.Files[0].FILE_URL
				}
			},
			IsUpdDialog: function (val) {
				if (val) {
					this.cloneTeacherEdit = JSON.parse(JSON.stringify(this.teacheredit))
					this.TeacherObj = JSON.parse(JSON.stringify(this.teacheredit))
					console.log('this.cloneTeacherEdit', this.cloneTeacherEdit)
				}
			},
		},
		methods: {
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
	
			async updateGiangVien() {
				// Kiểm tra các trường bắt buộc
				console.log('TeacherObj', this.TeacherObj)
				const requiredFields = [this.TeacherObj.HocViHocHam, this.TeacherObj.HoTenGiangVien, this.TeacherObj.CoQuanCongTac, this.TeacherObj.NganhID]
				if (requiredFields.some((field) => !field)) {
					Vue.$toast.error(`Không được bỏ trống các trường thông tin giảng viên`, { position: 'top' })
					return
				}
	
				if (this.cloneTeacherEdit.FileVanBang_ID) {
					await this.deleteFile(this.cloneTeacherEdit.FileVanBang_ID)
				}
	
				if (this.cloneTeacherEdit.FileLyLichKH_ID) {
					await this.deleteFile(this.cloneTeacherEdit.FileLyLichKH_ID)
				}
	
				// Dữ liệu giảng viên cần cập nhật
				const updatedTeacherData = {
					GiangVienID: this.TeacherObj.GiangVienID,
					HocViHocHam: this.TeacherObj.HocViHocHam,
					HoTenGiangVien: this.TeacherObj.HoTenGiangVien,
					CoQuanCongTac: this.TeacherObj.CoQuanCongTac,
					CoQuanCongTacTiengViet: this.TeacherObj.CoQuanCongTacTiengViet ? this.TeacherObj.CoQuanCongTacTiengViet.trim() : "",
					NganhID: this.TeacherObj.NganhID,
					NganhGiangDay: getNganhName(this.TeacherObj.NganhID),
					DiaChi: this.TeacherObj.DiaChi,
					SoDienThoai: this.TeacherObj.SoDienThoai,
	
					TenNganHang: this.TeacherObj.TenNganHang,
					SoTKNganHang: this.TeacherObj.SoTKNganHang,
					MaSoThue: this.TeacherObj.MaSoThue,
					Email_GV: this.TeacherObj.Email_GV ? this.TeacherObj.Email_GV.trim() : "",
					FileVanBang_ID: this.TeacherObj.FileVanBang_ID,
					FileVanBang_Name: this.TeacherObj.FileVanBang_Name,
					FileVanBang_Url: this.TeacherObj.FileVanBang_Url,
					FileLyLichKH_ID: this.TeacherObj.FileLyLichKH_ID,
					FileLyLichKH_Name: this.TeacherObj.FileLyLichKH_Name,
					FileLyLichKH_Url: this.TeacherObj.FileLyLichKH_Url,
				}
	
				const handleSuccess = () => {
					// Xóa file cũ đã bị thay thế trên máy chủ
					if (this.cloneTeacherEdit?.FileVanBang_ID && this.cloneTeacherEdit.FileVanBang_ID !== this.TeacherObj.FileVanBang_ID) {
						ajaxCALL('/FILE_FileDelete', { FileID: this.cloneTeacherEdit.FileVanBang_ID }, () => {}, () => {})
					}
					if (this.cloneTeacherEdit?.FileLyLichKH_ID && this.cloneTeacherEdit.FileLyLichKH_ID !== this.TeacherObj.FileLyLichKH_ID) {
						ajaxCALL('/FILE_FileDelete', { FileID: this.cloneTeacherEdit.FileLyLichKH_ID }, () => {}, () => {})
					}
					this.cloneTeacherEdit = JSON.parse(JSON.stringify(this.TeacherObj))
					Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
					CALL('getDsGiangVien')
					this.closeDialog()
				}
	
				const handleError = (error) => {
					Vue.$toast.error(`${error.responseJSON ? error.responseJSON.Message : error.message}`, { position: 'top' })
					console.log('Fail to update giang vien', error)
				}
	
				// Gọi API cập nhật
				ajaxCALL('/giangvien_upd', updatedTeacherData, handleSuccess, handleError)
			},
			closeDialog() {
				// Xóa file upload mới nếu hủy không lưu
				if (this.TeacherObj.FileVanBang_ID && this.TeacherObj.FileVanBang_ID !== this.cloneTeacherEdit?.FileVanBang_ID) {
					ajaxCALL('/FILE_FileDelete', { FileID: this.TeacherObj.FileVanBang_ID }, () => {}, () => {})
				}
				if (this.TeacherObj.FileLyLichKH_ID && this.TeacherObj.FileLyLichKH_ID !== this.cloneTeacherEdit?.FileLyLichKH_ID) {
					ajaxCALL('/FILE_FileDelete', { FileID: this.TeacherObj.FileLyLichKH_ID }, () => {}, () => {})
				}
				vueData.isUpdDialog = false
				this.TeacherObj = {}
			},
			deleteVanBangFile() {
				if (this.TeacherObj.FileVanBang_ID && this.TeacherObj.FileVanBang_ID !== this.cloneTeacherEdit?.FileVanBang_ID) {
					ajaxCALL('/FILE_FileDelete', { FileID: this.TeacherObj.FileVanBang_ID }, () => {}, () => {})
				}
				this.VanBang_Upload = null
				this.TeacherObj.FileVanBang_ID = null
				this.TeacherObj.FileVanBang_Name = null
				this.TeacherObj.FileVanBang_Url = null
			},
			deleteLyLichFile() {
				if (this.TeacherObj.FileLyLichKH_ID && this.TeacherObj.FileLyLichKH_ID !== this.cloneTeacherEdit?.FileLyLichKH_ID) {
					ajaxCALL('/FILE_FileDelete', { FileID: this.TeacherObj.FileLyLichKH_ID }, () => {}, () => {})
				}
				this.LyLich_Upload = null
				this.TeacherObj.FileLyLichKH_ID = null
				this.TeacherObj.FileLyLichKH_Name = null
				this.TeacherObj.FileLyLichKH_Url = null
			},
		},
	}
</script>