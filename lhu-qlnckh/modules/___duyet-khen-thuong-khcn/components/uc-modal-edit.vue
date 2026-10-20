<template>
	<div>
		<v-dialog v-model="dialog" max-width="1650px" width="96vw" persistent scrollable :retain-focus="false">
			<v-card class="rounded-xs d-flex flex-column duyet-modal-card">
				<!-- Tiêu đề Dialog -->
				<v-card-title class="pa-3 d-flex align-center justify-space-between primary white--text flex-grow-0">
					<span class="text-subtitle-1 font-weight-bold">
						Thẩm định hồ sơ & Phân bổ khen thưởng
					</span>
					<v-btn icon dark small @click="close">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<!-- Tabs 3 bước đồng bộ: 1. Thông tin đề xuất - 2. File minh chứng - 3. Thẩm định & Tính tiền -->
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
						<v-icon left small>mdi-calculator</v-icon>
						3. Thẩm định & Tính tiền
						<v-chip x-small class="ml-2" color="success" text-color="white" v-if="detailItem.KhenThuongObj.TongTienThuong > 0">
							{{ formatCurrency(detailItem.KhenThuongObj.TongTienThuong) }}
						</v-chip>
					</v-tab>
				</v-tabs>

				<!-- Nội dung cuộn theo Tab -->
				<v-card-text class="pa-4 flex-grow-1 duyet-modal-body">
					<!-- Cảnh báo nếu hồ sơ bị từ chối -->
					<v-alert v-if="detailItem.KhenThuongObj && detailItem.KhenThuongObj.TrangThai === 4"
						type="error" text dense class="mb-3 rounded-xs font-weight-medium">
						<v-icon left small color="error">mdi-alert-circle</v-icon>
						<strong>Hồ sơ đang ở trạng thái Bị từ chối.</strong>
						<span v-if="detailItem.KhenThuongObj.LyDoReject" class="ml-1">
							Lý do: <em>{{ detailItem.KhenThuongObj.LyDoReject }}</em>
						</span>
					</v-alert>

					<v-tabs-items v-model="activeTab" class="bg-transparent">
						<!-- Tab 1: Form thông tin đề xuất (Quản trị viên có thể cập nhật) -->
						<v-tab-item>
							<uc-form-an-pham v-model="detailItem.KhenThuongObj" :url-return-file="urlReturnFile"></uc-form-an-pham>
							<div class="d-flex justify-end mt-4 pt-3 border-top">
								<v-btn small color="primary" elevation="0" class="text-capitalize px-3 font-weight-medium"
									@click="activeTab = 1">
									Tiếp theo: Xem file minh chứng
									<v-icon right small>mdi-arrow-right</v-icon>
								</v-btn>
							</div>
						</v-tab-item>

						<!-- Tab 2: File minh chứng (.docx / .pdf có chữ ký) -->
						<v-tab-item>
							<v-card outlined class="pa-3 rounded-xs mb-3">
								<div class="d-flex flex-wrap align-center justify-space-between mb-3 border-bottom pb-2">
									<div>
										<div class="text-subtitle-1 font-weight-bold primary--text d-flex align-center">
											<v-icon small color="primary" class="mr-2">mdi-paperclip</v-icon>
											Danh sách file minh chứng đính kèm
											<v-chip x-small color="blue lighten-5" text-color="primary" class="ml-2 font-weight-medium">
												Chỉ nhận .docx, .pdf
											</v-chip>
										</div>
										<div class="caption grey--text text--darken-2 mt-1">
											Định dạng cho phép: <strong>.docx</strong>, <strong>.pdf</strong> (tối đa 25MB - có chữ ký xác nhận).
										</div>
									</div>
									<div class="d-flex align-center">
										<span class="caption grey--text text--darken-2 mr-3">
											Tổng số: <strong>{{ filesCount }}</strong> tệp tin
										</span>
										<f-file-upload v-model="tempFileID" :filters="filtersFile" label="Thêm tệp minh chứng"
											:url="apiFileUploadUrl" color="primary" @input="onFileUploadSuccess" />
									</div>
								</div>

								<v-data-table dense :headers="fileHeaders" :items="formattedFileList" hide-default-footer
									class="elevation-0 border rounded-xs" no-data-text="Không có tệp tin minh chứng nào trong hồ sơ!">
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
									<template v-slot:item.actions="{ item }">
										<div class="d-flex align-center justify-center">
											<v-btn icon small color="primary" :href="getFileUrl(item.FileID)" target="_blank" title="Tải tệp tin về máy">
												<v-icon small>mdi-download</v-icon>
											</v-btn>
											<v-btn icon small color="red darken-2" title="Xóa tệp tin này" @click="deleteFile(item)">
												<v-icon small>mdi-trash-can-outline</v-icon>
											</v-btn>
										</div>
									</template>
								</v-data-table>
							</v-card>

							<div class="d-flex align-center justify-space-between mt-4 pt-3 border-top">
								<v-btn small text color="grey darken-2" class="text-capitalize px-3" @click="activeTab = 0">
									<v-icon left small>mdi-arrow-left</v-icon>
									Quay lại thông tin đề xuất
								</v-btn>
								<v-btn small color="primary" elevation="0" class="text-capitalize px-3 font-weight-medium"
									@click="activeTab = 2">
									Tiếp theo: Tính tiền & Phân bổ
									<v-icon right small>mdi-arrow-right</v-icon>
								</v-btn>
							</div>
						</v-tab-item>

						<!-- Tab 3: Chọn công thức tính tiền & Bảng phân bổ thành viên -->
						<v-tab-item>
							<uc-table-tac-gia v-model="detailItem.MembersObjArr"
								:cong-thuc-id="detailItem.KhenThuongObj.CongThucID"
								:ds-cong-thuc="dscongthuckhenthuong"
								:tong-tien-thuong="detailItem.KhenThuongObj.TongTienThuong"
								:khen-thuong-obj="detailItem.KhenThuongObj"
								@update:cong-thuc-id="detailItem.KhenThuongObj.CongThucID = $event"
								@update:tong-tien-thuong="detailItem.KhenThuongObj.TongTienThuong = $event"
								@update:hinh-thuc-thanh-toan="detailItem.KhenThuongObj.HinhThucThanhToan = $event">
							</uc-table-tac-gia>

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

				<!-- Thanh tác vụ hành động đồng bộ -->
				<v-card-actions class="pa-3 flex-wrap">
					<v-spacer></v-spacer>
					<v-btn small text color="grey darken-2" class="text-capitalize px-3" @click="close">
						Đóng
					</v-btn>
					<v-btn small color="error" outlined class="text-capitalize px-3 ml-2 font-weight-medium"
						:loading="isLoadingAction" @click="openRejectDialog">
						<v-icon left small>mdi-close-circle-outline</v-icon>
						Từ chối hồ sơ
					</v-btn>
					<v-btn small color="amber darken-3" outlined class="text-capitalize px-3 ml-2 font-weight-medium"
						:loading="isLoadingAction" @click="saveAllChanges">
						<v-icon left small>mdi-content-save-outline</v-icon>
						Lưu cập nhật hồ sơ
					</v-btn>

					<!-- Khung Đợt duyệt & Duyệt chi tiền -->
					<div class="d-flex align-center ml-3 pl-3 border-left">
						<v-select v-model="selectedDotDuyetID" :items="dotDuyetOptions" item-text="TenDotDuyet"
							item-value="DotDuyetID" label="Đợt duyệt chi tiền" outlined dense hide-details
							class="select-dot-duyet" no-data-text="Chưa có đợt duyệt mở" />
						<v-btn icon small class="ml-1" title="Quản lý đợt duyệt" @click="$emit('on-manage-dotduyet')">
							<v-icon small color="primary">mdi-plus-circle-outline</v-icon>
						</v-btn>
						<v-btn small class="ml-2 font-weight-medium text-capitalize" color="success" elevation="0"
							:loading="isLoadingAction" :disabled="!selectedDotDuyetID" @click="approveReward">
							<v-icon left small>mdi-check-circle-outline</v-icon>
							Duyệt chi tiền
						</v-btn>
					</div>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog nhập lý do từ chối -->
		<v-dialog v-model="dialogReject" max-width="520px" persistent>
			<v-card class="rounded-xs">
				<v-card-title class="primary white--text pa-3 subtitle-1 font-weight-bold d-flex align-center">
					<v-icon left small dark>mdi-alert-circle-outline</v-icon>
					Từ chối hồ sơ khen thưởng
				</v-card-title>
				<v-card-text class="pa-4">
					<div class="caption grey--text text--darken-2 mb-2">
						Vui lòng nhập lý do từ chối chi tiết để người nộp đề xuất có căn cứ điều chỉnh lại hồ sơ:
					</div>
					<v-textarea v-model="rejectReason" label="Lý do từ chối hồ sơ *" outlined rows="3" dense hide-details
						placeholder="Ví dụ: Thiếu chữ ký xác nhận của lãnh đạo đơn vị trên file minh chứng..."></v-textarea>
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn small text color="grey darken-2" @click="dialogReject = false">Hủy</v-btn>
					<v-btn small color="error" elevation="0" class="text-capitalize px-3 font-weight-medium"
						:loading="isLoadingAction" @click="confirmReject">
						Xác nhận từ chối
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-modal-edit',
		props: {
			value: { type: Boolean, default: false },
			editRow: { type: Object, default: () => ({}) },
			dscongthuckhenthuong: { type: Array, default: () => [] },
			dsdotduyet: { type: Array, default: () => [] },
		},
		emits: ['input', 'on-reload', 'on-manage-dotduyet'],
		data() {
			return {
				activeTab: 0,
				isLoadingAction: false,
				dialogReject: false,
				rejectReason: '',
				selectedDotDuyetID: null,
				tempFileID: '',
				uploadedFileIDs: [],
				pendingDeleteFileIDs: [],
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
				detailItem: {
					KhenThuongObj: {},
					MembersObjArr: [],
					FilesObjArr: [],
				},
				fileHeaders: [
					{ text: '#', value: 'STT', width: 50, align: 'center', sortable: false },
					{ text: 'Tên tệp tin', value: 'FileName', width: 320 },
					{ text: 'Phân loại minh chứng', value: 'LoaiMinhChung', width: 220 },
					{ text: 'Ghi chú / Mô tả', value: 'MoTa' },
					{ text: 'Thao tác', value: 'actions', width: 90, align: 'center', sortable: false },
				],
			}
		},
		computed: {
			dialog: {
				get() { return this.value },
				set(val) { this.$emit('input', val) },
			},
			dotDuyetOptions() {
				return (this.dsdotduyet || []).filter(d => d.TinhTrang === 1)
			},
			apiFileUploadUrl() {
				return (window.vueData && window.vueData.v_Set && window.vueData.v_Set.apiFile) || 'https://file.lhu.edu.vn/qlnckh/upload/FileData'
			},
			urlReturnFile() {
				return (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || 'https://file.lhu.edu.vn/qlnckh'
			},
			filesCount() {
				return (this.detailItem.FilesObjArr || []).length
			},
			formattedFileList() {
				return (this.detailItem.FilesObjArr || []).map((f, i) => ({
					...f,
					STT: i + 1,
				}))
			},
		},
		watch: {
			value(val) {
				if (val) {
					this.activeTab = 0
					this.uploadedFileIDs = []
					this.pendingDeleteFileIDs = []
					if (this.editRow && this.editRow.KhenThuongID) {
						this.fetchDetail(this.editRow.KhenThuongID)
					}
				} else {
					this.cleanUploadedGarbageFiles()
				}
			},
		},
		beforeDestroy() {
			this.cleanUploadedGarbageFiles()
		},
		methods: {
			cleanUploadedGarbageFiles() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
					this.uploadedFileIDs = []
				}
				this.pendingDeleteFileIDs = []
			},
			formatCurrency(val) {
				return Number(val || 0).toLocaleString('vi-VN') + ' đ'
			},
			getLoaiMinhChungName(loai) {
				switch (loai) {
					case 1: return 'Minh chứng giải / Văn bằng'
					case 2: return 'QĐ / Tờ trình phân công GVHD'
					case 3: return 'Minh chứng khác'
					default: return 'Minh chứng'
				}
			},
			getFileUrl(fileId) {
				return this.urlReturnFile ? this.urlReturnFile + '/FileData/' + fileId : '#'
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
					if (!this.detailItem.FilesObjArr) {
						this.$set(this.detailItem, 'FilesObjArr', [])
					}
					this.detailItem.FilesObjArr.push({
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
			deleteFile(item) {
				const $this = this
				confirm({
					title: 'Xóa tệp tin minh chứng?',
					message: 'Bạn có chắc chắn muốn xóa file "' + (item.FileName || '') + '" không?',
					action: function () {
						if (item.FileID) {
							if ($this.uploadedFileIDs.includes(item.FileID)) {
								ajaxCALL('/FILE_FileDelete', { FileID: item.FileID }, () => {})
								$this.uploadedFileIDs = $this.uploadedFileIDs.filter(id => id !== item.FileID)
							} else {
								$this.pendingDeleteFileIDs.push(item.FileID)
							}
						}
						const idx = $this.detailItem.FilesObjArr.findIndex(f => f.FileID === item.FileID || (f.FileName && f.FileName === item.FileName))
						if (idx !== -1) {
							$this.detailItem.FilesObjArr.splice(idx, 1)
						}
						Vue.$toast.success('Đã gỡ tệp tin minh chứng', { position: 'top' })
					},
				})
			},
			async fetchDetail(khenThuongID) {
				const res = await ajaxCALLPromise('/ThiKHCN_Get_ByID', { KhenThuongID: khenThuongID })
				if (res && res.length >= 3) {
					const obj = res[0][0] || {}
					if (obj.NgayBanHanh) {
						if (typeof moment !== 'undefined') {
							let m = moment(obj.NgayBanHanh, 'YYYY-MM-DD')
							if (!m.isValid()) m = moment(obj.NgayBanHanh, 'DD/MM/YYYY')
							if (m.isValid()) obj.NgayBanHanh = m.format('YYYY-MM-DD')
						}
					}
					this.detailItem = {
						KhenThuongObj: obj,
						MembersObjArr: res[1] || [],
						FilesObjArr: res[2] || [],
					}
					this.selectedDotDuyetID = obj.DotDuyetID || (this.dotDuyetOptions[0] ? this.dotDuyetOptions[0].DotDuyetID : null)
				}
			},
			close() {
				this.cleanUploadedGarbageFiles()
				this.dialog = false
			},
			openRejectDialog() {
				this.rejectReason = ''
				this.dialogReject = true
			},
			async confirmReject() {
				if (!this.rejectReason || !this.rejectReason.trim()) {
					Vue.$toast.warning('Vui lòng nhập lý do từ chối!', { position: 'top' })
					return
				}
				this.isLoadingAction = true
				try {
					await ajaxCALLPromise('/ThiKHCN_Udp_TrangThai', {
						KhenThuongID: this.detailItem.KhenThuongObj.KhenThuongID,
						TrangThai: 4,
						LyDoReject: this.rejectReason.trim(),
					})
					Vue.$toast.success('Đã từ chối hồ sơ đề xuất', { position: 'top' })
					this.dialogReject = false
					this.close()
					this.$emit('on-reload')
				} finally {
					this.isLoadingAction = false
				}
			},
			async saveAllChanges() {
				this.isLoadingAction = true
				try {
					const khenThuongID = this.detailItem.KhenThuongObj.KhenThuongID
					// 1. Cập nhật phân bổ tiền thành viên
					await ajaxCALLPromise('/ThiKHCN_ThanhVien_Udp', {
						KhenThuongID: khenThuongID,
						CongThucID: this.detailItem.KhenThuongObj.CongThucID,
						TongTienThuong: this.detailItem.KhenThuongObj.TongTienThuong,
						HinhThucThanhToan: this.detailItem.KhenThuongObj.HinhThucThanhToan,
						MembersObjArr: JSON.stringify(this.detailItem.MembersObjArr),
					})
					// 2. Cập nhật thông tin đề xuất, công thức, tổng tiền và danh sách files
					await ajaxCALLPromise('/ThiKHCN_Udp_Obj', {
						KhenThuongID: khenThuongID,
						KhenThuongObj: JSON.stringify(this.detailItem.KhenThuongObj),
						MembersObjArr: JSON.stringify(this.detailItem.MembersObjArr),
						FilesObjArr: JSON.stringify(this.detailItem.FilesObjArr),
						TrangThai: this.detailItem.KhenThuongObj.TrangThai || 2,
					})
					// 3. Xóa các file cũ đã bị xóa khỏi hệ thống file vật lý
					if (this.pendingDeleteFileIDs && this.pendingDeleteFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.pendingDeleteFileIDs.join(',') }, () => {})
						this.pendingDeleteFileIDs = []
					}
					// File mới tải lên đã được lưu chính thức, không còn là file rác
					this.uploadedFileIDs = []

					Vue.$toast.success('Đã lưu toàn bộ thông tin cập nhật hồ sơ!', { position: 'top' })
					// Tự động gọi lại API để làm mới chi tiết hồ sơ vừa lưu và danh sách bên ngoài
					await this.fetchDetail(khenThuongID)
					this.$emit('on-reload')
				} finally {
					this.isLoadingAction = false
				}
			},
			async approveReward() {
				if (!this.selectedDotDuyetID) {
					Vue.$toast.warning('Vui lòng chọn đợt duyệt chi tiền!', { position: 'top' })
					return
				}

				// 1. Kiểm tra đã chọn công thức tính tiền chưa
				if (!this.detailItem.KhenThuongObj.CongThucID) {
					this.activeTab = 2
					Vue.$toast.warning('Vui lòng chọn công thức khen thưởng và tính tiền trước khi duyệt!', { position: 'top' })
					return
				}

				// 2. Kiểm tra tổng tỷ lệ Nhóm tác giả phải là 100%
				const authors = (this.detailItem.MembersObjArr || []).filter(m => m.VaiTro === 1 || m.VaiTro === 2)
				if (authors.length > 0) {
					const sumAuthorRate = authors.reduce((sum, m) => sum + (Number(m.TyLeDongGop) || 0), 0)
					if (Math.round(sumAuthorRate) !== 100) {
						this.activeTab = 2
						Vue.$toast.error(`Tổng tỷ lệ nhóm tác giả phải bằng 100% (Hiện tại là ${sumAuthorRate}%). Vui lòng bấm "Chia đều 100%" hoặc điều chỉnh lại!`, { position: 'top' })
						return
					}
				}

				// 3. Kiểm tra tổng tỷ lệ Nhóm GVHD (nếu có) phải là 100%
				const mentors = (this.detailItem.MembersObjArr || []).filter(m => m.VaiTro === 3)
				if (mentors.length > 0) {
					const sumMentorRate = mentors.reduce((sum, m) => sum + (Number(m.TyLeDongGop) || 0), 0)
					if (Math.round(sumMentorRate) !== 100) {
						this.activeTab = 2
						Vue.$toast.error(`Tổng tỷ lệ nhóm GVHD phải bằng 100% (Hiện tại là ${sumMentorRate}%). Vui lòng bấm "Chia đều 100%" hoặc điều chỉnh lại!`, { position: 'top' })
						return
					}
				}

				this.isLoadingAction = true
				try {
					const khenThuongID = this.detailItem.KhenThuongObj.KhenThuongID
					// 1. Lưu phân bổ tiền & cập nhật hồ sơ
					await this.saveAllChanges()
					// 2. Chuyển vào đợt duyệt
					await ajaxCALLPromise('/ThiKHCN_ChuyenDotDuyet', {
						KhenThuongIDs: String(khenThuongID),
						DotDuyetID: this.selectedDotDuyetID,
					})
					// 3. Đổi trạng thái sang 3 (Đã duyệt)
					await ajaxCALLPromise('/ThiKHCN_Udp_TrangThai', {
						KhenThuongID: khenThuongID,
						TrangThai: 3,
						LyDoReject: '',
					})
					Vue.$toast.success('Duyệt hồ sơ khen thưởng thành công!', { position: 'top' })
					this.close()
					this.$emit('on-reload')
				} finally {
					this.isLoadingAction = false
				}
			},
		},
	}
</script>