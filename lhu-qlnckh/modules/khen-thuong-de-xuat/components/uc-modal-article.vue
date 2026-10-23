<template>
	<v-dialog :value="value" max-width="1650px" width="96vw" persistent scrollable :retain-focus="false">
		<v-card class="rounded-xs d-flex flex-column article-modal-card">
			<!-- Tiêu đề Dialog -->
			<v-card-title class="pa-3 d-flex align-center justify-space-between primary white--text flex-grow-0">
				<span class="text-subtitle-1 font-weight-bold">
					{{ !canEdit ? 'Chi tiết hồ sơ đề xuất khen thưởng' : (editedIndex === -1 ? 'Thêm mới hồ sơ đề xuất khen thưởng' : 'Chỉnh sửa hồ sơ đề xuất') }}
				</span>
				<v-btn icon dark small @click="close">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<!-- Tabs 3 bước rõ ràng: 1. Thông tin đề xuất - 2. File minh chứng - 3. Danh sách thành viên -->
			<v-tabs v-model="activeTab" dense color="primary" class="px-3 border-bottom flex-grow-0" height="42">
				<v-tab class="font-weight-medium text-capitalize">
					<v-icon left small>mdi-file-document-edit-outline</v-icon>
					1. Thông tin đề xuất
				</v-tab>
				<v-tab class="font-weight-medium text-capitalize">
					<v-icon left small>mdi-paperclip</v-icon>
					2. File minh chứng
					<v-chip x-small class="ml-2" :color="filesCount > 0 ? 'primary' : 'grey'" text-color="white">
						{{ filesCount }} file
					</v-chip>
				</v-tab>
				<v-tab class="font-weight-medium text-capitalize">
					<v-icon left small>mdi-account-group-outline</v-icon>
					3. Thành viên nhận thưởng
					<v-chip x-small class="ml-2" :color="membersCount > 0 ? 'primary' : 'grey'" text-color="white">
						{{ membersCount }} thành viên
					</v-chip>
				</v-tab>
			</v-tabs>

			<!-- Nội dung cuộn chính theo Tab -->
			<v-card-text class="pa-4 flex-grow-1 article-modal-body">
				<!-- Thông báo lý do từ chối hồ sơ (nếu có) -->
				<v-alert v-if="editedItem.KhenThuongObj && editedItem.KhenThuongObj.TrangThai === 4 && editedItem.KhenThuongObj.LyDoReject"
					type="error" text dense class="mb-3 rounded-xs font-weight-medium">
					<v-icon left small color="error">mdi-alert-circle</v-icon>
					<strong>Hồ sơ bị từ chối với lý do:</strong> {{ editedItem.KhenThuongObj.LyDoReject }}
				</v-alert>

				<!-- Thông báo khi đang chờ duyệt -->
				<v-alert v-if="editedItem.KhenThuongObj && editedItem.KhenThuongObj.TrangThai === 2"
					type="info" text dense class="mb-3 rounded-xs font-weight-medium">
					<v-icon left small color="info">mdi-information</v-icon>
					Hồ sơ đang trong quá trình thẩm định / xét duyệt (Chế độ chỉ xem).
				</v-alert>

				<!-- Thông báo khi đã duyệt -->
				<v-alert v-if="editedItem.KhenThuongObj && editedItem.KhenThuongObj.TrangThai === 3"
					type="success" text dense class="mb-3 rounded-xs font-weight-medium">
					<v-icon left small color="success">mdi-check-circle</v-icon>
					Hồ sơ đã được Quản trị phê duyệt chính thức (Chế độ chỉ xem).
				</v-alert>

				<v-tabs-items v-model="activeTab" class="bg-transparent">
					<!-- Tab 1: Form thông tin đề xuất -->
					<v-tab-item>
						<uc-form-an-pham ref="formAnPham" v-model="editedItem" :api-file="apiFile"
							:url-return-file="urlReturnFile" :readonly="!canEdit"></uc-form-an-pham>
						<div class="d-flex justify-end mt-4 pt-3 border-top">
							<v-btn small color="primary" elevation="0" class="text-capitalize px-3 font-weight-medium"
								@click="goToNextFromTab1">
								Tiếp theo: File minh chứng
								<v-icon right small>mdi-arrow-right</v-icon>
							</v-btn>
						</div>
					</v-tab-item>

					<!-- Tab 2: File minh chứng (.docx / .pdf) -->
					<v-tab-item>
						<v-card outlined class="pa-3 rounded-xs mb-3">
							<div class="d-flex flex-wrap align-center justify-space-between mb-3 px-1 gap-10">
								<div>
									<div class="font-weight-bold text-subtitle-2 primary--text d-flex align-center">
										<v-icon small color="primary" class="mr-1">mdi-file-upload-outline</v-icon>
										Đính kèm file minh chứng
										<v-chip x-small color="blue lighten-5" text-color="primary" class="ml-2 font-weight-medium">
											Chỉ nhận .docx, .pdf
										</v-chip>
									</div>
									<div class="caption grey--text text--darken-2 mt-1">
										Quy định bắt buộc: Chỉ chấp nhận định dạng <strong>.docx</strong> hoặc <strong>.pdf</strong> (có chữ ký xác nhận, dung lượng tối đa 25MB).
									</div>
								</div>
								<div class="compact-upload-wrapper">
									<f-file-upload v-if="canEdit" v-model="tempFileID" :filters="filtersFile" label="Chọn tệp minh chứng"
										:url="apiFileUploadUrl" color="primary" @input="onFileUploadSuccess" />
								</div>
							</div>

							<!-- Bảng danh sách file đã tải -->
							<v-data-table dense :headers="fileHeaders" :items="formattedFileList" hide-default-footer
								class="elevation-0 border rounded-xs nowrap-table" no-data-text="Chưa có file minh chứng nào. Vui lòng tải lên tệp .docx hoặc .pdf!">
								<template v-slot:item.STT="{ item }">
									<span class="grey--text text--darken-1">{{ item.STT }}</span>
								</template>
								<template v-slot:item.FileName="{ item }">
									<a :href="getFileUrl(item.FileID)" target="_blank" class="font-weight-medium text-decoration-none">
										<v-icon small color="primary" class="mr-1">
											{{ item.DinhDangFile === '.pdf' ? 'mdi-file-pdf-box' : 'mdi-file-word-box' }}
										</v-icon>
										{{ item.FileName }}
									</a>
								</template>
								<template v-slot:item.LoaiMinhChung="{ item }">
									<v-select v-model="item.LoaiMinhChung" :items="loaiMinhChungList" item-text="text"
										item-value="value" dense outlined hide-details :disabled="!canEdit" class="my-1"></v-select>
								</template>
								<template v-slot:item.MoTa="{ item }">
									<v-text-field v-model="item.MoTa" placeholder="Ghi chú minh chứng..." dense outlined
										hide-details :readonly="!canEdit" class="my-1"></v-text-field>
								</template>
								<template v-slot:item.actions="{ item, index }">
									<v-btn v-if="canEdit" icon small color="red darken-2" title="Xóa file minh chứng này"
										@click="deleteFile(item, index)">
										<v-icon small>mdi-trash-can-outline</v-icon>
									</v-btn>
									<v-btn v-else icon small color="primary" :href="getFileUrl(item.FileID)" target="_blank"
										title="Tải về / Xem tập tin">
										<v-icon small>mdi-download</v-icon>
									</v-btn>
								</template>
							</v-data-table>
						</v-card>

						<div class="d-flex align-center justify-space-between mt-4 pt-3 border-top">
							<v-btn small text color="grey darken-2" class="text-capitalize px-3" @click="activeTab = 0">
								<v-icon left small>mdi-arrow-left</v-icon>
								Quay lại thông tin đề xuất
							</v-btn>
							<v-btn small color="primary" elevation="0" class="text-capitalize px-3 font-weight-medium"
								@click="goToNextFromTab2">
								Tiếp theo: Thành viên nhận thưởng
								<v-icon right small>mdi-arrow-right</v-icon>
							</v-btn>
						</div>
					</v-tab-item>

					<!-- Tab 3: Danh sách thành viên nhận thưởng -->
					<v-tab-item>
						<uc-table-tac-gia ref="tableTacGia" v-model="editedItem.MembersObjArr"
							:khen-thuong-obj="editedItem.KhenThuongObj"
							:ds-ngan-hang="dsNganHang"
							:readonly="!canEdit"
							@update:hinh-thuc-thanh-toan="editedItem.KhenThuongObj.HinhThucThanhToan = $event"></uc-table-tac-gia>
						<div class="d-flex justify-start mt-4 pt-3 border-top">
							<v-btn small text color="grey darken-2" class="text-capitalize px-3" @click="activeTab = 1">
								<v-icon left small>mdi-arrow-left</v-icon>
								Quay lại file minh chứng
							</v-btn>
						</div>
					</v-tab-item>
				</v-tabs-items>
			</v-card-text>

			<v-divider></v-divider>

			<!-- Thanh tác vụ hành động -->
			<v-card-actions class="pa-3 flex-grow-0">
				<v-spacer></v-spacer>
				<v-btn small text color="grey darken-2" class="text-capitalize px-3" @click="close">
					Đóng
				</v-btn>
				<v-btn v-if="canEdit" small color="amber darken-3" outlined class="text-capitalize px-3 ml-2 font-weight-medium"
					:loading="isLoadingSave" @click="saveDraft">
					<v-icon left small>mdi-file-document-edit-outline</v-icon>
					Lưu dự thảo
				</v-btn>
				<v-btn v-if="canEdit" small color="primary" elevation="0" class="text-capitalize px-4 ml-2 font-weight-medium"
					:loading="isLoadingSave" @click="saveSubmit">
					<v-icon left small>mdi-send-outline</v-icon>
					{{ editedIndex === -1 ? 'Lưu & Nộp đề xuất' : 'Cập nhật & Nộp đề xuất' }}
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-modal-article',
		props: {
			value: { type: Boolean, default: false },
			editedItem: {
				type: Object,
				default: () => ({
					KhenThuongObj: {},
					MembersObjArr: [],
					FilesObjArr: [],
				}),
			},
			editedIndex: { type: Number, default: -1 },
			isLoadingSave: { type: Boolean, default: false },
			dsNganHang: { type: Array, default: () => [] },
			apiFile: { type: String, default: '' },
			urlReturnFile: { type: String, default: '' },
		},
		emits: ['input', 'on-close', 'on-save', 'on-save-draft'],
		data() {
			return {
				activeTab: 0,
				tempFileID: '',
				loaiMinhChungList: [
					{ text: 'Minh chứng giải / Văn bằng', value: 1 },
					{ text: 'QĐ / Tờ trình phân công GVHD', value: 2 },
					{ text: 'Minh chứng khác', value: 3 },
				],
				filtersFile: {
					max_file_size: '25mb',
					mime_types: [
						{ title: 'Tài liệu (.docx, .pdf)', extensions: 'docx,pdf' },
					],
				},
				uploadedFileIDs: [],
				pendingDeleteFileIDs: [],
			}
		},
		watch: {
			value(val) {
				if (val) {
					this.activeTab = 0
					this.uploadedFileIDs = []
					this.pendingDeleteFileIDs = []
				} else {
					if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
						this.uploadedFileIDs = []
					}
					this.pendingDeleteFileIDs = []
				}
			},
		},
		computed: {
			canEdit() {
				const status = this.editedItem.KhenThuongObj?.TrangThai
				// TrangThai = 2 (Chờ duyệt) hoặc 3 (Đã duyệt) thì chỉ xem, không được sửa
				return !status || status === 1 || status === 4
			},
			fileHeaders() {
				return [
					{ text: '#', value: 'STT', width: 50, align: 'center', sortable: false },
					{ text: 'Tên tệp tin', value: 'FileName', width: 320 },
					{ text: 'Loại minh chứng', value: 'LoaiMinhChung', width: 220 },
					{ text: 'Ghi chú / Mô tả', value: 'MoTa' },
					{ text: this.canEdit ? 'Xóa' : 'Tải về', value: 'actions', width: 70, align: 'center', sortable: false },
				]
			},
			filesList() {
				return this.editedItem.FilesObjArr || []
			},
			formattedFileList() {
				return (this.filesList || []).map((f, i) => ({
					...f,
					STT: i + 1,
				}))
			},
			filesCount() {
				return (this.editedItem.FilesObjArr || []).length
			},
			membersCount() {
				return (this.editedItem.MembersObjArr || []).length
			},
			apiFileUploadUrl() {
				return this.apiFile || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.apiFile) || 'https://file.lhu.edu.vn/qlnckh/upload/FileData'
			},
			fileReturnUrl() {
				return this.urlReturnFile || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || 'https://file.lhu.edu.vn/qlnckh'
			},
		},
		methods: {
			close() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
				}
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.$emit('input', false)
				this.$emit('on-close')
			},
			getFileUrl(fileId) {
				return this.fileReturnUrl ? this.fileReturnUrl + '/FileData/' + fileId : '#'
			},
			onFileUploadSuccess(res) {
				if (!res) return
				let payload = res
				if (typeof res === 'string') {
					try {
						payload = JSON.parse(res)
					} catch (e) {
						payload = { FILE_ID: res, FILE_NAME: res }
					}
				}
				const fileList = Array.isArray(payload.Files)
					? payload.Files
					: (Array.isArray(payload) ? payload : [payload])

				fileList.forEach(file => {
					if (!file) return
					const fileId = file.FILE_ID || file.FileID || (typeof file === 'string' ? file : '')
					const fileName = (file.FILE_NAME || file.FileName || file.FileTitle || file.name || '').trim()
					const lowerName = fileName.toLowerCase()

					// Ràng buộc chỉ nhận file .docx và .pdf
					if (fileName && !lowerName.endsWith('.docx') && !lowerName.endsWith('.pdf')) {
						Vue.$toast.error('Chỉ chấp nhận file định dạng .docx hoặc .pdf! File không hợp lệ: ' + fileName, { position: 'top' })
						if (fileId) {
							ajaxCALL('/FILE_FileDelete', { FileID: fileId }, () => {})
						}
						return
					}

					if (fileId) {
						this.uploadedFileIDs.push(fileId)
					}

					const ext = lowerName.endsWith('.docx') ? '.docx' : '.pdf'
					if (!this.editedItem.FilesObjArr) {
						this.$set(this.editedItem, 'FilesObjArr', [])
					}
					this.editedItem.FilesObjArr.push({
						FileID: fileId,
						FileName: fileName || (fileId ? fileId + ext : 'minh-chung' + ext),
						DinhDangFile: ext,
						LoaiMinhChung: 1,
						MoTa: '',
					})
					Vue.$toast.success('Đã tải lên tệp minh chứng: ' + (fileName || 'thành công'), { position: 'top' })
				})
				this.$nextTick(() => {
					this.tempFileID = ''
				})
			},
			deleteFile(item, index) {
				const $this = this
				confirm({
					title: 'Xóa tệp tin minh chứng?',
					message: 'Bạn có chắc chắn muốn xóa file "' + item.FileName + '" không?',
					action: function () {
						if (item.FileID) {
							if ($this.uploadedFileIDs.includes(item.FileID)) {
								ajaxCALL('/FILE_FileDelete', { FileID: item.FileID }, () => {})
								$this.uploadedFileIDs = $this.uploadedFileIDs.filter(id => id !== item.FileID)
							} else {
								$this.pendingDeleteFileIDs.push(item.FileID)
							}
						}
						$this.editedItem.FilesObjArr.splice(index, 1)
						Vue.$toast.success('Đã gỡ tệp tin minh chứng', { position: 'top' })
					},
				})
			},
			goToNextFromTab1() {
				const isFormValid = this.$refs.formAnPham ? this.$refs.formAnPham.validate() : false
				if (!isFormValid) {
					Vue.$toast.warning('Vui lòng hoàn thiện đầy đủ các thông tin đề xuất bắt buộc!', { position: 'top' })
					return
				}
				this.activeTab = 1
			},
			goToNextFromTab2() {
				if (!this.editedItem.FilesObjArr || this.editedItem.FilesObjArr.length === 0) {
					Vue.$toast.warning('Khuyến nghị: Vui lòng đính kèm ít nhất 1 file minh chứng (.docx hoặc .pdf) có chữ ký xác nhận!', { position: 'top' })
				}
				this.activeTab = 2
			},
			saveDraft() {
				const ten = this.editedItem.KhenThuongObj?.TenCuocThi_CongTrinh
				if (!ten || !ten.trim()) {
					this.activeTab = 0
					Vue.$toast.warning('Vui lòng nhập Tên cuộc thi hoặc công trình để lưu dự thảo!', { position: 'top' })
					return
				}
				const pendingDelete = [...this.pendingDeleteFileIDs]
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.$emit('on-save-draft', { pendingDeleteFileIDs: pendingDelete })
			},
			saveSubmit() {
				// 1. Validate Tab 1: Form đề xuất
				const isFormValid = this.$refs.formAnPham ? this.$refs.formAnPham.validate() : false
				if (!isFormValid) {
					this.activeTab = 0
					Vue.$toast.warning('Vui lòng hoàn thiện đầy đủ các thông tin đề xuất bắt buộc!', { position: 'top' })
					return
				}

				// 2. Validate Tab 2: File minh chứng
				if (!this.editedItem.FilesObjArr || this.editedItem.FilesObjArr.length === 0) {
					this.activeTab = 1
					Vue.$toast.warning('Hồ sơ bắt buộc phải có ít nhất 1 file minh chứng (.docx hoặc .pdf có chữ ký)!', { position: 'top' })
					return
				}

				// 3. Validate Tab 3: Danh sách thành viên
				if (!this.editedItem.MembersObjArr || this.editedItem.MembersObjArr.length === 0) {
					this.activeTab = 2
					Vue.$toast.warning('Hồ sơ bắt buộc phải có ít nhất 1 thành viên nhận khen thưởng!', { position: 'top' })
					return
				}

				const isMembersValid = this.$refs.tableTacGia ? this.$refs.tableTacGia.validate() : true
				if (!isMembersValid) {
					this.activeTab = 2
					Vue.$toast.warning('Vui lòng kiểm tra lại thông tin danh sách thành viên nhận thưởng!', { position: 'top' })
					return
				}

				const pendingDelete = [...this.pendingDeleteFileIDs]
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.$emit('on-save', { pendingDeleteFileIDs: pendingDelete })
			},
		},
	}
</script>