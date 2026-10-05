<template>
	<v-dialog v-model="dialog" max-width="850" persistent>
		<v-card>
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Thêm mới dự án / hợp đồng chuyển giao công nghệ
				</span>
				<v-spacer />
				<v-btn icon small @click="closeModal">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pt-4 pb-2 px-4">
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
						<v-text-field
							v-model="form.NamHoc"
							label="Năm học"
							placeholder="2024-2025"
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
				</v-row>

				<v-divider class="my-3" />

				<div class="d-flex align-center justify-space-between mb-2">
					<span class="font-weight-bold text-body-2">Danh sách tập tin đính kèm</span>
					<f-file-upload
						v-model="uploadResult"
						label="Tải lên tập tin"
						:filters="fileFilters"
						:url="vSet.apiFile"
						@input="handleFileUploaded"
					/>
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

			<v-divider />

			<v-card-actions class="py-2 px-4">
				<v-spacer />
				<v-btn text small @click="closeModal">Hủy</v-btn>
				<v-btn
					color="primary"
					small
					depressed
					:loading="saving"
					@click="saveItem"
				>
					Lưu
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-add",
	props: {
		value: {
			type: Boolean,
			default: false
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
			// 1. Data arrays/objects
			attachedFiles: [],
			fileHeaders: [
				{ text: "Tập tin", value: "FILE_NAME" },
				{ text: "Xóa", value: "actions", align: "right", sortable: false, width: 80 }
			],
			fileFilters: {
				max_file_size: "15mb",
				mime_types: [{ title: "All files", extensions: "*" }]
			},

			// 2. Local form & state
			saving: false,
			uploadResult: null,
			form: {
				SoThuTu: 0,
				TenDuAn: "",
				ChuNhiemDeTai: "",
				ThanhVienDeTai: "",
				DonViChuNhiem: "Trường Đại học Lạc Hồng",
				DonViTiepNhan: "",
				GiaTriHopDong: 0,
				SoHopDong: "",
				NamHoc: "",
				NamThucHien: new Date().getFullYear()
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
		}
	},
	methods: {
		resetForm() {
			this.form = {
				SoThuTu: 0,
				TenDuAn: "",
				ChuNhiemDeTai: "",
				ThanhVienDeTai: "",
				DonViChuNhiem: "Trường Đại học Lạc Hồng",
				DonViTiepNhan: "",
				GiaTriHopDong: 0,
				SoHopDong: "",
				NamHoc: "",
				NamThucHien: new Date().getFullYear()
			}
			this.attachedFiles = []
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

			confirm({
				title: "Bạn có muốn thêm mới dự án/hợp đồng chuyển giao công nghệ?",
				action: async () => {
					this.saving = true
					try {
						const params = {
							SoThuTu: Number(this.form.SoThuTu) || 0,
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
							TrangThai: 3
						}
						await ajaxCALLPromise("/DEV_CGCN_Ins", params)
						Vue.$toast.success("Thêm mới dự án/hợp đồng chuyển giao công nghệ thành công", { position: "top" })
						this.$emit("on-reload")
						this.closeModal()
					} finally {
						this.saving = false
					}
				}
			})
		},
		handleFileUploaded(payload) {
			const result = payload || this.uploadResult
			if (result && Array.isArray(result.Files) && result.Files.length > 0) {
				result.Files.forEach(file => {
					const exists = this.attachedFiles.some(item => item.FILE_ID === file.FILE_ID)
					if (!exists) {
						this.attachedFiles.push(file)
					}
				})
				this.uploadResult = null
			}
		},
		removeAttachedFile(file) {
			this.attachedFiles = this.attachedFiles.filter(item => item.FILE_ID !== file.FILE_ID)
		},
		closeModal() {
			this.resetForm()
			this.dialog = false
		}
	}
	}
</script>