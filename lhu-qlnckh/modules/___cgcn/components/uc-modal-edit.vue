<template>
	<v-dialog v-model="dialog" max-width="1050" persistent>
		<v-card class="rounded-xs d-flex flex-column">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Cập nhật & Thẩm định dự án / hợp đồng CGCN
				</span>
				<v-spacer />
				<v-chip
					v-if="form.TrangThai"
					small
					:color="getStatusChipColor(form.TrangThai)"
					:text-color="getStatusChipTextColor(form.TrangThai)"
					class="mr-2 font-weight-bold"
				>
					{{ getStatusText(form.TrangThai) }}
				</v-chip>
				<v-btn icon small @click="closeModal">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pt-4 pb-2 px-4">
				<!-- Cảnh báo nếu trạng thái = Cần bổ sung -->
				<v-alert
					v-if="form.TrangThai === 4 && form.LyDoReject"
					type="error"
					dense
					outlined
					class="mb-3"
				>
					<strong>Lý do yêu cầu bổ sung hiện tại:</strong> {{ form.LyDoReject }}
				</v-alert>

				<v-row dense>
					<v-col cols="12">
						<v-textarea
							v-model="form.TenDuAn"
							label="Tên Dự án / Hợp đồng *"
							rows="2"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-textarea
							v-model="form.ChuNhiemDeTai"
							label="Chủ nhiệm"
							rows="2"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-textarea
							v-model="form.ThanhVienDeTai"
							label="Thành viên thực hiện"
							rows="2"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							v-model="form.DonViChuNhiem"
							label="Đơn vị chủ nhiệm"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							v-model="form.DonViTiepNhan"
							label="Đơn vị tiếp nhận"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.GiaTriHopDong"
							label="Giá trị hợp đồng (VNĐ)"
							type="number"
							outlined
							dense
							:hint="formatMoney(form.GiaTriHopDong) + ' VNĐ'"
							persistent-hint
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.SoHopDong"
							label="Số hợp đồng"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-select
							v-model="form.NamHoc"
							:items="namHocOptions"
							label="Năm học"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-text-field
							v-model="form.NamThucHien"
							label="Năm TH"
							type="number"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-select
							v-model="form.TrangThai"
							:items="statusOptions"
							item-text="text"
							item-value="value"
							label="Trạng thái hồ sơ"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							:value="form.TenNhanVienSubmit || form.NhanVienSubmit"
							label="Người nộp hồ sơ"
							outlined
							dense
							readonly
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col v-if="form.TrangThai === 4 || form.TrangThai === 2" cols="12">
						<v-textarea
							v-model="form.LyDoReject"
							:label="form.TrangThai === 2 ? 'Nội dung yêu cầu bổ sung (Nhập trước khi bấm Yêu cầu bổ sung)' : 'Lý do từ chối / Nội dung yêu cầu bổ sung *'"
							rows="2"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
							:placeholder="form.TrangThai === 2 ? 'Nhập chi tiết các nội dung giảng viên cần bổ sung...' : ''"
						/>
					</v-col>
				</v-row>

				<v-divider class="my-3" />

				<div class="d-flex align-center justify-space-between mb-2">
					<span class="font-weight-bold text-body-2">Danh sách tập tin đính kèm</span>
					<div class="compact-upload-wrapper">
						<f-file-upload
							v-model="uploadResult"
							label="Tải lên tập tin"
							color="primary"
							:filters="fileFilters"
							:url="vSet.apiFile"
							@input="handleFileUploaded"
						/>
					</div>
				</div>

				<v-data-table
					dense
					:headers="fileHeaders"
					:items="attachedFiles"
					item-key="FILE_ID"
					hide-default-footer
					:items-per-page="-1"
					no-data-text="Chưa có tập tin đính kèm"
					class="elevation-1 cgcn-file-table"
				>
					<template v-slot:item.FILE_NAME="{ item }">
						<a
							:href="getFileUrl(item)"
							target="_blank"
							class="text-decoration-none font-weight-medium"
						>
							<v-icon small color="primary" class="mr-1">mdi-file-document-outline</v-icon>
							{{ item.FILE_NAME }}
						</a>
						<span v-if="item.FILE_SIZE" class="grey--text text-caption ml-1">
							({{ item.FILE_SIZE }} KB)
						</span>
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn
							icon
							x-small
							color="red darken-2"
							title="Xóa tập tin"
							@click="removeAttachedFile(item)"
						>
							<v-icon small>mdi-trash-can-outline</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>

			<v-card-actions class="pa-3 flex-grow-0 border-top">
				<!-- Nút Thẩm định trực tiếp: Từ chối / Bổ sung -->
				<v-btn
					v-if="form.TrangThai === 2"
					color="red darken-1"
					small
					outlined
					class="text-capitalize px-3 mr-2 font-weight-medium rounded-xs"
					:loading="saving"
					@click="rejectDirectly"
				>
					<v-icon left small>mdi-close-circle-outline</v-icon>
					Yêu cầu bổ sung
				</v-btn>

				<!-- Nút Thẩm định trực tiếp: Phê duyệt -->
				<v-btn
					v-if="form.TrangThai === 2"
					color="success"
					small
					elevation="0"
					class="text-capitalize px-3 mr-2 font-weight-medium rounded-xs"
					:loading="saving"
					@click="approveDirectly"
				>
					<v-icon left small>mdi-check-circle-outline</v-icon>
					Phê duyệt ngay
				</v-btn>

				<v-spacer />
				<v-btn small text color="grey darken-2" class="text-capitalize px-3 rounded-xs" @click="closeModal">
					Đóng
				</v-btn>
				<v-btn
					color="primary"
					small
					elevation="0"
					class="text-capitalize px-4 ml-2 font-weight-medium rounded-xs"
					:loading="saving"
					@click="saveItem"
				>
					<v-icon left small>mdi-content-save-outline</v-icon>
					Lưu thay đổi
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-edit",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			editItem: {
				type: Object,
				default: () => ({})
			},
			vSet: {
				type: Object,
				default: () => ({
					apiFile: "",
					urlReturnFile: ""
				})
			}
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				attachedFiles: [],
				uploadedFileIDs: [],
				pendingDeleteFileIDs: [],
				fileHeaders: [
					{ text: "Tập tin", value: "FILE_NAME" },
					{ text: "Xóa", value: "actions", align: "right", sortable: false, width: 80 }
				],
				fileFilters: {
					max_file_size: "20mb",
					mime_types: [{ title: "All files", extensions: "*" }]
				},
				statusOptions: [
					{ text: "1. Dự thảo", value: 1 },
					{ text: "2. Chờ xét duyệt", value: 2 },
					{ text: "3. Đã phê duyệt", value: 3 },
					{ text: "4. Cần bổ sung", value: 4 }
				],
				saving: false,
				uploadResult: null,
				form: {
					CGCNID: null,
					SoThuTu: 0,
					TenDuAn: "",
					ChuNhiemDeTai: "",
					ThanhVienDeTai: "",
					DonViChuNhiem: "Trường Đại học Lạc Hồng",
					DonViTiepNhan: "",
					GiaTriHopDong: 0,
					SoHopDong: "",
					NamHoc: "",
					NamThucHien: null,
					TrangThai: 1,
					NhanVienSubmit: "",
					TenNhanVienSubmit: "",
					LyDoReject: ""
				}
			}
		},
		computed: {
			dialog: {
				get() {
					return this.value
				},
				set(val) {
					this.$emit("input", val)
				}
			},
			namHocOptions() {
				const currentYear = new Date().getFullYear()
				const list = []
				for (let y = currentYear + 1; y >= currentYear - 7; y--) {
					list.push(`${y - 1}-${y}`)
				}
				if (this.form && this.form.NamHoc && !list.includes(this.form.NamHoc)) {
					list.unshift(this.form.NamHoc)
				}
				return list
			}
		},
		watch: {
			value(isOpen) {
				if (isOpen && this.editItem) {
					this.syncFormFromItem(this.editItem)
				} else if (!isOpen) {
					if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
						this.uploadedFileIDs = []
					}
					this.pendingDeleteFileIDs = []
				}
			},
			editItem: {
				handler(newItem) {
					if (this.value && newItem) {
						this.syncFormFromItem(newItem)
					}
				},
				deep: true
			}
		},
		methods: {
			getStatusText(status) {
				switch (Number(status)) {
					case 1: return "Dự thảo"
					case 2: return "Chờ duyệt"
					case 3: return "Đã duyệt"
					case 4: return "Cần bổ sung"
					default: return "Chưa rõ"
				}
			},
			getStatusChipColor(status) {
				switch (Number(status)) {
					case 1: return "grey lighten-2"
					case 2: return "orange lighten-4"
					case 3: return "green lighten-4"
					case 4: return "red lighten-4"
					default: return "grey lighten-2"
				}
			},
			getStatusChipTextColor(status) {
				switch (Number(status)) {
					case 1: return "grey darken-3"
					case 2: return "orange darken-4"
					case 3: return "green darken-4"
					case 4: return "red darken-4"
					default: return "grey darken-3"
				}
			},
			parseFileData(rawFileData) {
				if (!rawFileData) return []
				if (Array.isArray(rawFileData)) return [...rawFileData]
				if (typeof rawFileData === "string") {
					try {
						const parsed = JSON.parse(rawFileData)
						return Array.isArray(parsed) ? parsed : []
					} catch (e) {
						return []
					}
				}
				return []
			},
			syncFormFromItem(item) {
				this.form = {
					CGCNID: item.CGCNID || null,
					SoThuTu: item.SoThuTu || 0,
					TenDuAn: item.TenDuAn || "",
					ChuNhiemDeTai: item.ChuNhiemDeTai || "",
					ThanhVienDeTai: item.ThanhVienDeTai || "",
					DonViChuNhiem: item.DonViChuNhiem || "Trường Đại học Lạc Hồng",
					DonViTiepNhan: item.DonViTiepNhan || "",
					GiaTriHopDong: item.GiaTriHopDong || 0,
					SoHopDong: item.SoHopDong || "",
					NamHoc: item.NamHoc || "",
					NamThucHien: item.NamThucHien || null,
					TrangThai: item.TrangThai || 1,
					NhanVienSubmit: item.NhanVienSubmit || "",
					TenNhanVienSubmit: item.TenNhanVienSubmit || item.NhanVienSubmit || "",
					LyDoReject: item.LyDoReject || ""
				}
				this.attachedFiles = this.parseFileData(item.FileData)
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.uploadResult = null
			},
			formatMoney(val) {
				if (val === null || val === undefined || val === "") return "0"
				if (typeof formatAsCurrency === "function") {
					return formatAsCurrency(Number(val) || 0, 0)
				}
				return Number(val || 0).toLocaleString("vi-VN")
			},
			getFileUrl(file) {
				const baseUrl = (this.vSet && this.vSet.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
				return `${baseUrl}/FileData/${file.FILE_ID}`
			},
			async saveItem() {
				if (!this.form.TenDuAn || !String(this.form.TenDuAn).trim()) {
					Vue.$toast.warning("Vui lòng nhập Tên dự án / Hợp đồng", { position: "top" })
					return
				}

				this.saving = true
				try {
					const params = {
						CGCNID: this.form.CGCNID,
						TenDuAn: this.form.TenDuAn,
						NamHoc: this.form.NamHoc,
						ChuNhiemDeTai: this.form.ChuNhiemDeTai,
						ThanhVienDeTai: this.form.ThanhVienDeTai,
						DonViChuNhiem: this.form.DonViChuNhiem,
						DonViTiepNhan: this.form.DonViTiepNhan,
						GiaTriHopDong: Number(this.form.GiaTriHopDong) || 0,
						NamThucHien: Number(this.form.NamThucHien) || null,
						SoHopDong: this.form.SoHopDong || "",
						DS_FileID: this.attachedFiles.map(item => item.FILE_ID).join(","),
						TrangThai: this.form.TrangThai,
						LyDoReject: this.form.LyDoReject || ""
					}
					await ajaxCALLPromise("/DEV_CGCN_Upd", params)
					if (this.pendingDeleteFileIDs && this.pendingDeleteFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.pendingDeleteFileIDs.join(',') }, () => {})
					}
					this.uploadedFileIDs = []
					this.pendingDeleteFileIDs = []
					Vue.$toast.success("Cập nhật thông tin thành công!", { position: "top" })
					this.$emit("on-reload")
					this.closeModal()
				} finally {
					this.saving = false
				}
			},
			async approveDirectly() {
				confirm({
					title: `Phê duyệt dự án/hợp đồng <b><i>${this.form.TenDuAn}</i></b>?`,
					action: async () => {
						this.saving = true
						try {
							await ajaxCALLPromise("/DEV_CGCN_Duyet", {
								CGCNID: this.form.CGCNID,
								TrangThai: 3,
								LyDoReject: ""
							})
							Vue.$toast.success("Đã phê duyệt hồ sơ!", { position: "top" })
							this.$emit("on-reload")
							this.closeModal()
						} finally {
							this.saving = false
						}
					}
				})
			},
			async rejectDirectly() {
				if (!this.form.LyDoReject || !String(this.form.LyDoReject).trim()) {
					Vue.$toast.warning("Vui lòng nhập lý do từ chối / nội dung cần bổ sung", { position: "top" })
					return
				}
				this.saving = true
				try {
					await ajaxCALLPromise("/DEV_CGCN_Duyet", {
						CGCNID: this.form.CGCNID,
						TrangThai: 4,
						LyDoReject: this.form.LyDoReject.trim()
					})
					Vue.$toast.success("Đã trả về yêu cầu bổ sung!", { position: "top" })
					this.$emit("on-reload")
					this.closeModal()
				} finally {
					this.saving = false
				}
			},
			handleFileUploaded(payload) {
				const result = payload || this.uploadResult
				if (result && Array.isArray(result.Files) && result.Files.length > 0) {
					result.Files.forEach(file => {
						if (file && file.FILE_ID) {
							const exists = this.attachedFiles.some(item => item.FILE_ID === file.FILE_ID)
							if (!exists) {
								this.attachedFiles.push(file)
								this.uploadedFileIDs.push(file.FILE_ID)
							}
						}
					})
					this.uploadResult = null
				}
			},
			removeAttachedFile(file) {
				if (file && file.FILE_ID) {
					if (this.uploadedFileIDs.includes(file.FILE_ID)) {
						ajaxCALL('/FILE_FileDelete', { FileID: file.FILE_ID }, () => {})
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== file.FILE_ID)
					} else {
						this.pendingDeleteFileIDs.push(file.FILE_ID)
					}
				}
				this.attachedFiles = this.attachedFiles.filter(item => item.FILE_ID !== file.FILE_ID)
			},
			closeModal() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
				}
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.dialog = false
			}
		}
	}
</script>