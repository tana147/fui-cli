<template>
	<v-dialog :value="value" max-width="1650px" width="96vw" persistent scrollable :retain-focus="false">
		<v-card class="rounded-xs d-flex flex-column" style="min-height: 680px;">
			<!-- Tiêu đề Dialog -->
			<v-card-title class="pa-3 d-flex align-center justify-space-between primary white--text flex-grow-0">
				<span class="text-subtitle-1 font-weight-bold">
					{{ editedIndex === -1 ? 'Thêm mới hồ sơ đề xuất khen thưởng' : 'Chỉnh sửa hồ sơ đề xuất' }}
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
			<v-card-text class="pa-4 flex-grow-1" style="max-height: calc(85vh - 150px); overflow-y: auto;">
				<!-- Thông báo lý do từ chối hồ sơ (nếu có) -->
				<v-alert v-if="editedItem.KhenThuongObj && editedItem.KhenThuongObj.TrangThai === 4 && editedItem.KhenThuongObj.LyDoReject"
					type="error" text dense class="mb-3 rounded-xs font-weight-medium">
					<v-icon left small color="error">mdi-alert-circle</v-icon>
					<strong>Hồ sơ bị từ chối với lý do:</strong> {{ editedItem.KhenThuongObj.LyDoReject }}
				</v-alert>

				<v-tabs-items v-model="activeTab" class="bg-transparent">
					<!-- Tab 1: Form thông tin đề xuất -->
					<v-tab-item>
						<uc-form-an-pham ref="formAnPham" v-model="editedItem" :api-file="apiFile"
							:url-return-file="urlReturnFile"></uc-form-an-pham>
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
							<div class="d-flex flex-wrap align-center justify-space-between mb-3 px-1" style="gap: 10px;">
								<div>
									<div class="font-weight-bold text-subtitle-2 primary--text d-flex align-center">
										<v-icon small color="primary" class="mr-1">mdi-file-upload-outline</v-icon>
										Đính kèm file minh chứng
									</div>
									<div class="caption grey--text text--darken-2 mt-1">
										Quy định: Chỉ chấp nhận định dạng <strong>.docx</strong> hoặc <strong>.pdf</strong> (có chữ ký xác nhận, tối đa 25MB).
									</div>
								</div>
								<div class="compact-upload-wrapper">
									<f-file-upload v-model="tempFileID" :filters="filtersFile" label="Chọn tệp minh chứng"
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
										item-value="value" dense outlined hide-details class="my-1"></v-select>
								</template>
								<template v-slot:item.MoTa="{ item }">
									<v-text-field v-model="item.MoTa" placeholder="Ghi chú minh chứng..." dense outlined
										hide-details class="my-1"></v-text-field>
								</template>
								<template v-slot:item.actions="{ item, index }">
									<v-btn icon small color="red darken-2" title="Xóa file minh chứng này"
										@click="deleteFile(item, index)">
										<v-icon small>mdi-trash-can-outline</v-icon>
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
				fileHeaders: [
					{ text: '#', value: 'STT', width: 50, align: 'center', sortable: false },
					{ text: 'Tên tệp tin', value: 'FileName', width: 320 },
					{ text: 'Loại minh chứng', value: 'LoaiMinhChung', width: 220 },
					{ text: 'Ghi chú / Mô tả', value: 'MoTa' },
					{ text: 'Xóa', value: 'actions', width: 70, align: 'center', sortable: false },
				],
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
				}
			},
		},
		computed: {
			canEdit() {
				const status = this.editedItem.KhenThuongObj?.TrangThai
				return !status || status === 1 || status === 2 || status === 4
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
				return this.apiFile || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.apiFile) || ''
			},
			fileReturnUrl() {
				return this.urlReturnFile || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || ''
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
				if (!res || !res.Files || !res.Files[0]) return
				const file = res.Files[0]
				const fileName = (file.FILE_NAME || '').trim()
				const lowerName = fileName.toLowerCase()

				// Ràng buộc chỉ nhận file .docx và .pdf
				if (!lowerName.endsWith('.docx') && !lowerName.endsWith('.pdf')) {
					Vue.$toast.error('Định dạng tệp không hợp lệ! Chỉ chấp nhận file .docx hoặc .pdf (có chữ ký xác nhận).', { position: 'top' })
					if (file.FILE_ID) {
						ajaxCALL('/FILE_FileDelete', { FileID: file.FILE_ID }, () => {})
					}
					return
				}

				if (file.FILE_ID) {
					this.uploadedFileIDs.push(file.FILE_ID)
				}

				const ext = lowerName.endsWith('.docx') ? '.docx' : '.pdf'
				if (!this.editedItem.FilesObjArr) {
					this.$set(this.editedItem, 'FilesObjArr', [])
				}
				this.editedItem.FilesObjArr.push({
					FileID: file.FILE_ID,
					FileName: fileName,
					DinhDangFile: ext,
					LoaiMinhChung: 1,
					MoTa: '',
				})
				Vue.$toast.success('Đã tải lên tệp minh chứng: ' + fileName, { position: 'top' })
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