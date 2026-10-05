<template>
	<div>
		<!-- Dialog Quản lý danh sách đợt đề xuất (Rộng rãi 1450px) -->
		<v-dialog :value="value" max-width="1450px" persistent scrollable :retain-focus="false">
			<v-card class="rounded-xs d-flex flex-column">
				<v-card-title class="d-flex align-center px-4 py-2 subtitle-1 font-weight-bold primary white--text flex-grow-0">
					<v-icon left small dark>mdi-bullhorn-outline</v-icon>
					Quản lý các đợt nộp đề xuất khen thưởng (Dành cho giảng viên)
					<v-spacer></v-spacer>
					<v-btn color="white" text small class="mr-2 text-capitalize" @click="openForm(null)">
						<v-icon left small>mdi-plus</v-icon>Tạo đợt mới
					</v-btn>
					<v-btn icon dark small @click="close">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<v-card-text class="pa-3 flex-grow-1">
					<v-data-table dense fixed-header height="380px" :headers="headers" :items="items"
						:loading="loading" :items-per-page="10" no-data-text="Chưa có đợt đề xuất nào">
						<template v-slot:item.TinhTrang="{ item }">
							<v-chip x-small :color="item.TinhTrang === 1 ? 'success' : 'grey'" outlined class="font-weight-medium">
								{{ item.TinhTrang === 1 ? 'Đang mở' : 'Đã đóng' }}
							</v-chip>
						</template>

						<template v-slot:item.ThoiGian="{ item }">
							<span class="text-caption font-weight-medium">
								{{ formatDateDisplay(item.ThoiGianBatDau) }} – {{ formatDateDisplay(item.ThoiGianKetThuc) }}
							</span>
						</template>

						<template v-slot:item.ThongBao="{ item }">
							<span class="text-caption grey--text text--darken-3" :title="item.ThongBao">
								{{ truncate(item.ThongBao, 60) }}
							</span>
						</template>

						<template v-slot:item.FileHuongDan="{ item }">
							<v-chip v-if="item.FileHuongDan" x-small color="primary" outlined :href="getFileUrl(item.FileHuongDan)"
								target="_blank" class="font-weight-medium" :title="item.FileNameHuongDan || item.FileHuongDan">
								<v-icon left x-small>mdi-download</v-icon>
								{{ truncate(item.FileNameHuongDan || 'Xem file', 20) }}
							</v-chip>
							<span v-else class="grey--text text-caption">-</span>
						</template>

						<template v-slot:item.actions="{ item }">
							<v-icon small color="green darken-2" class="mr-2" title="Chỉnh sửa đợt" @click="openForm(item)">
								mdi-square-edit-outline
							</v-icon>
							<v-icon small color="red darken-3" title="Xóa đợt" @click="deleteItem(item)">
								mdi-trash-can-outline
							</v-icon>
						</template>
					</v-data-table>
				</v-card-text>

				<v-divider></v-divider>
				<v-card-actions class="pa-2 px-3">
					<v-spacer></v-spacer>
					<v-btn small text color="grey darken-2" class="text-capitalize" @click="close">
						Đóng
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Thêm mới / Sửa đợt đề xuất (Rộng rãi 880px) -->
		<v-dialog :value="formDialog" max-width="880" persistent :retain-focus="false">
			<v-card class="rounded-xs">
				<v-card-title class="d-flex align-center px-4 py-2 subtitle-1 font-weight-bold primary white--text">
					<v-icon left small dark>{{ editItem.DotID ? 'mdi-pencil-outline' : 'mdi-plus-circle-outline' }}</v-icon>
					{{ editItem.DotID ? 'Chỉnh sửa đợt đề xuất khen thưởng' : 'Thêm mới đợt đề xuất khen thưởng' }}
					<v-spacer></v-spacer>
					<v-btn icon dark small @click="closeForm">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<v-card-text class="pa-4">
					<v-form ref="validForm" lazy-validation>
						<v-row dense>
							<v-col cols="12" sm="8" class="py-1">
								<v-text-field v-model="editItem.TenDot" label="Tên đợt đề xuất *"
									placeholder="VD: Đợt 1 năm học 2025 - 2026"
									outlined dense hide-details="auto"
									:rules="[v => !!v || 'Bắt buộc nhập tên đợt']"></v-text-field>
							</v-col>
							<v-col cols="12" sm="4" class="py-1">
								<v-text-field v-model="editItem.NamHoc" label="Niên khóa / Năm học *"
									placeholder="VD: 2025-2026"
									outlined dense hide-details="auto"
									:rules="[v => !!v || 'Bắt buộc nhập năm học']"></v-text-field>
							</v-col>

							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model="editItem.ThoiGianBatDau" label="Ngày bắt đầu tiếp nhận *"
									type="date" outlined dense hide-details="auto"
									:rules="[v => !!v || 'Bắt buộc chọn ngày bắt đầu']"></v-text-field>
							</v-col>
							<v-col cols="12" sm="6" class="py-1">
								<v-text-field v-model="editItem.ThoiGianKetThuc" label="Ngày kết thúc tiếp nhận *"
									type="date" outlined dense hide-details="auto"
									:rules="[v => !!v || 'Bắt buộc chọn ngày kết thúc']"></v-text-field>
							</v-col>

							<v-col cols="12" class="py-1">
								<v-textarea v-model="editItem.ThongBao" label="Nội dung thông báo hiển thị cho giảng viên *"
									placeholder="VD: Tiếp nhận đề xuất khen thưởng các giải thưởng phát sinh từ tháng 6 đến 20/12..."
									outlined dense hide-details="auto" rows="3"
									:rules="[v => !!v || 'Bắt buộc nhập nội dung thông báo']"></v-textarea>
							</v-col>

							<!-- Khu vực Upload File Hướng dẫn kèm theo -->
							<v-col cols="12" class="py-2">
								<v-card outlined class="pa-3 rounded-xs" style="background: #fafafa;">
									<div class="d-flex flex-wrap align-center justify-space-between mb-2">
										<div class="font-weight-medium text-subtitle-2 primary--text d-flex align-center">
											<v-icon small color="primary" class="mr-1">mdi-paperclip</v-icon>
											File hướng dẫn & quy chế đính kèm (Giảng viên tải xem trên Banner):
										</div>
										<f-file-upload v-model="tempFileID" :filters="filtersFile" label="Chọn tệp hướng dẫn"
											:url="apiFileUploadUrl" color="primary" @input="onFileUploadSuccess" />
									</div>

									<div v-if="editItem.FileHuongDan" class="d-flex align-center mt-2 px-2 py-1 rounded border" style="background: #fff;">
										<v-icon small color="primary" class="mr-2">mdi-file-pdf-box</v-icon>
										<span class="font-weight-medium text-body-2 mr-3 text-truncate" style="max-width: 380px;">
											{{ editItem.FileNameHuongDan || editItem.FileHuongDan }}
										</span>
										<v-btn icon x-small color="primary" :href="getFileUrl(editItem.FileHuongDan)" target="_blank" title="Tải xem thử file">
											<v-icon small>mdi-download</v-icon>
										</v-btn>
										<v-spacer></v-spacer>
										<v-btn icon x-small color="red darken-2" title="Gỡ file đính kèm" @click="removeFileHuongDan">
											<v-icon small>mdi-close-circle-outline</v-icon>
										</v-btn>
									</div>
									<div v-else class="caption grey--text text-center py-2">
										Chưa có file hướng dẫn nào. Nhấn <strong>"Chọn tệp hướng dẫn"</strong> để đính kèm file (.pdf, .docx).
									</div>
								</v-card>
							</v-col>

							<v-col cols="12" class="py-1">
								<v-switch v-model="editItem.TinhTrang" :true-value="1" :false-value="0"
									label="Đang mở tiếp nhận đề xuất (Hiển thị Banner trên trang người nộp)"
									color="success" hide-details class="mt-0 font-weight-medium"></v-switch>
							</v-col>
						</v-row>
					</v-form>
				</v-card-text>

				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn small text color="grey darken-2" class="text-capitalize" @click="closeForm">Hủy</v-btn>
					<v-btn small color="primary" elevation="0" class="text-capitalize px-4" :loading="saving" @click="saveItem">
						<v-icon left small>mdi-content-save-outline</v-icon>Lưu đợt
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-dot-dexuat-manage',
		props: {
			value: { type: Boolean, default: false },
		},
		emits: ['input', 'on-reload'],
		data() {
			return {
				items: [],
				loading: false,
				saving: false,
				formDialog: false,
				tempFileID: '',
				headers: [
					{ text: '#', value: 'DotID', width: 60, align: 'center' },
					{ text: 'Tên đợt đề xuất', value: 'TenDot', width: 240 },
					{ text: 'Năm học', value: 'NamHoc', width: 110, align: 'center' },
					{ text: 'Thời gian tiếp nhận', value: 'ThoiGian', width: 200, align: 'center' },
					{ text: 'Thông báo hiển thị cho giảng viên', value: 'ThongBao', width: 340 },
					{ text: 'File hướng dẫn & quy chế', value: 'FileHuongDan', width: 200, align: 'center' },
					{ text: 'Tình trạng', value: 'TinhTrang', width: 110, align: 'center' },
					{ text: 'Thao tác', value: 'actions', width: 90, align: 'center', sortable: false },
				],
				editItem: {
					DotID: null,
					TenDot: '',
					NamHoc: '2025-2026',
					ThoiGianBatDau: '',
					ThoiGianKetThuc: '',
					ThongBao: '',
					FileHuongDan: '',
					FileNameHuongDan: '',
					TinhTrang: 1,
				},
				filtersFile: {
					max_file_size: '25mb',
					mime_types: [
						{ title: 'Tài liệu hướng dẫn (.pdf, .docx)', extensions: 'pdf,docx' },
					],
				},
			}
		},
		computed: {
			apiFileUploadUrl() {
				return (window.vueData && window.vueData.v_Set && window.vueData.v_Set.apiFile) || ''
			},
			fileReturnUrl() {
				return (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || ''
			},
		},
		watch: {
			value(val) {
				if (val) {
					this.loadData()
				}
			},
		},
		methods: {
			close() {
				this.$emit('input', false)
			},
			closeForm() {
				this.formDialog = false
			},
			async loadData() {
				this.loading = true
				const data = await ajaxCALLPromise('/ThiKHCN_Dot_Get')
				this.items = data || []
				this.loading = false
			},
			getFileUrl(fileId) {
				return this.fileReturnUrl ? this.fileReturnUrl + '/FileData/' + fileId : '#'
			},
			truncate(text, max) {
				if (!text) return ''
				return text.length > max ? text.substring(0, max) + '...' : text
			},
			formatDateDisplay(val) {
				if (!val) return ''
				if (typeof val === 'string' && /^\d{2}\/\d{2}\/\d{4}$/.test(val)) return val
				if (typeof moment !== 'undefined') {
					let m = moment(val, 'YYYY-MM-DD')
					if (m.isValid()) return m.format('DD/MM/YYYY')
					m = moment(val)
					if (m.isValid()) return m.format('DD/MM/YYYY')
				}
				return val
			},
			openForm(item) {
				if (item) {
					this.editItem = {
						DotID: item.DotID,
						TenDot: item.TenDot || '',
						NamHoc: item.NamHoc || '2025-2026',
						ThoiGianBatDau: item.ThoiGianBatDau || '',
						ThoiGianKetThuc: item.ThoiGianKetThuc || '',
						ThongBao: item.ThongBao || '',
						FileHuongDan: item.FileHuongDan || '',
						FileNameHuongDan: item.FileNameHuongDan || '',
						TinhTrang: item.TinhTrang !== undefined ? item.TinhTrang : 1,
					}
				} else {
					this.editItem = {
						DotID: null,
						TenDot: '',
						NamHoc: '2025-2026',
						ThoiGianBatDau: '',
						ThoiGianKetThuc: '',
						ThongBao: '',
						FileHuongDan: '',
						FileNameHuongDan: '',
						TinhTrang: 1,
					}
				}
				this.formDialog = true
			},
			onFileUploadSuccess(res) {
				if (!res || !res.Files || !res.Files[0]) return
				const file = res.Files[0]
				const fileName = (file.FILE_NAME || '').trim()
				const lowerName = fileName.toLowerCase()

				if (!lowerName.endsWith('.docx') && !lowerName.endsWith('.pdf')) {
					Vue.$toast.error('Chỉ chấp nhận file định dạng .docx hoặc .pdf!', { position: 'top' })
					if (file.FILE_ID) {
						ajaxCALL('/FILE_FileDelete', { FileID: file.FILE_ID }, () => {})
					}
					return
				}

				this.editItem.FileHuongDan = file.FILE_ID
				this.editItem.FileNameHuongDan = fileName
				Vue.$toast.success('Đã tải lên tệp hướng dẫn: ' + fileName, { position: 'top' })
			},
			removeFileHuongDan() {
				if (this.editItem.FileHuongDan) {
					ajaxCALL('/FILE_FileDelete', { FileID: this.editItem.FileHuongDan }, () => {})
				}
				this.editItem.FileHuongDan = ''
				this.editItem.FileNameHuongDan = ''
				Vue.$toast.info('Đã gỡ tệp hướng dẫn đính kèm', { position: 'top' })
			},
			async saveItem() {
				const isFormValid = this.$refs.validForm ? this.$refs.validForm.validate() : true
				if (!isFormValid) {
					Vue.$toast.warning('Vui lòng điền đầy đủ các thông tin bắt buộc!', { position: 'top' })
					return
				}

				this.saving = true
				try {
					const isNew = !this.editItem.DotID
					const url = isNew ? '/ThiKHCN_Dot_Ins' : '/ThiKHCN_Dot_Udp'
					const payload = {
						TenDot: this.editItem.TenDot,
						NamHoc: this.editItem.NamHoc,
						ThoiGianBatDau: this.editItem.ThoiGianBatDau,
						ThoiGianKetThuc: this.editItem.ThoiGianKetThuc,
						ThongBao: this.editItem.ThongBao,
						FileHuongDan: this.editItem.FileHuongDan || '',
						FileNameHuongDan: this.editItem.FileNameHuongDan || '',
						TinhTrang: this.editItem.TinhTrang,
					}
					if (!isNew) {
						payload.DotID = this.editItem.DotID
					}

					await ajaxCALLPromise(url, payload)
					Vue.$toast.success(isNew ? 'Thêm mới đợt đề xuất thành công!' : 'Cập nhật đợt đề xuất thành công!', { position: 'top' })
					this.formDialog = false
					await this.loadData()
					this.$emit('on-reload')
				} catch (err) {
					Vue.$toast.error('Lưu đợt đề xuất thất bại!', { position: 'top' })
				} finally {
					this.saving = false
				}
			},
			deleteItem(item) {
				const $this = this
				confirm({
					title: 'Xóa đợt đề xuất khen thưởng?',
					message: 'Bạn có chắc chắn muốn xóa đợt "' + item.TenDot + '" không?',
					action: async function () {
						await ajaxCALLPromise('/ThiKHCN_Dot_Del', { DotID: item.DotID })
						Vue.$toast.success('Đã xóa đợt đề xuất thành công', { position: 'top' })
						$this.loadData()
						$this.$emit('on-reload')
					},
				})
			},
		},
	}
</script>