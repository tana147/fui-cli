<template>
	<v-dialog v-model="dialog" max-width="850" persistent>
		<v-card>
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					{{ isEdit ? "Chi tiết / Cập nhật hồ sơ chuyển giao công nghệ" : "Kê khai hồ sơ chuyển giao công nghệ mới" }}
				</span>
				<v-spacer />
				<v-btn icon small @click="closeModal">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pt-4 pb-2 px-4">
				<!-- Banner hiển thị lý do cần bổ sung / từ chối -->
				<v-alert
					v-if="form.TrangThai === 4 && form.LyDoReject"
					type="error"
					dense
					outlined
					prominent
					class="mb-3"
				>
					<div class="font-weight-bold">Yêu cầu bổ sung / Lý do trả về từ Quản trị KH&CN:</div>
					<div class="mt-1 text-body-2">{{ form.LyDoReject }}</div>
					<div class="mt-1 caption font-italic text-secondary">
						* Vui lòng hoàn thiện các thông tin/minh chứng theo yêu cầu và bấm <b>"Gửi thẩm định lại"</b>.
					</div>
				</v-alert>

				<!-- Banner thông báo khi đang chờ duyệt -->
				<v-alert
					v-if="form.TrangThai === 2"
					type="info"
					dense
					outlined
					class="mb-3"
				>
					Hồ sơ đang trong quá trình thẩm định / xét duyệt. Không thể chỉnh sửa lúc này.
				</v-alert>

				<!-- Banner thông báo khi đã duyệt -->
				<v-alert
					v-if="form.TrangThai === 3"
					type="success"
					dense
					outlined
					class="mb-3"
				>
					Hồ sơ đã được Quản trị phê duyệt chính thức.
				</v-alert>

				<v-row dense>
					<v-col cols="12">
						<v-textarea
							v-model="form.TenDuAn"
							label="Tên Dự án / Hợp đồng chuyển giao công nghệ *"
							rows="2"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-textarea
							v-model="form.ChuNhiemDeTai"
							label="Chủ nhiệm đề tài / Hợp đồng *"
							rows="2"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-textarea
							v-model="form.ThanhVienDeTai"
							label="Thành viên cùng thực hiện"
							placeholder="Nhập tên các thành viên (cách nhau bởi dấu phẩy)"
							rows="2"
							outlined
							dense
							:readonly="isReadOnly"
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
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							v-model="form.DonViTiepNhan"
							label="Đơn vị tiếp nhận / Đối tác *"
							placeholder="Tên doanh nghiệp, tổ chức tiếp nhận CGCN"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.GiaTriHopDong"
							label="Giá trị hợp đồng (VNĐ) *"
							type="number"
							outlined
							dense
							:readonly="isReadOnly"
							:hint="formatMoney(form.GiaTriHopDong) + ' VNĐ'"
							persistent-hint
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.SoHopDong"
							label="Số hợp đồng *"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-text-field
							v-model="form.NamHoc"
							label="Năm học"
							placeholder="VD: 2024-2025"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-text-field
							v-model="form.NamThucHien"
							label="Năm TH"
							type="number"
							placeholder="VD: 2024"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>
				</v-row>

				<v-divider class="my-3" />

				<div class="d-flex align-center justify-space-between mb-2">
					<span class="font-weight-bold text-body-2">
						Tập tin minh chứng (Hợp đồng, Biên bản nghiệm thu, Thanh lý...)
					</span>
					<f-file-upload
						v-if="!isReadOnly"
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
					class="elevation-1"
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
							v-if="!isReadOnly"
							icon
							x-small
							color="red darken-2"
							title="Xóa tập tin"
							@click="removeAttachedFile(item)"
						>
							<v-icon small>mdi-trash-can-outline</v-icon>
						</v-btn>
						<v-btn
							v-else
							icon
							x-small
							color="primary"
							:href="getFileUrl(item)"
							target="_blank"
							title="Xem tập tin"
						>
							<v-icon small>mdi-download</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>

			<v-divider />

			<v-card-actions class="py-2 px-4">
				<v-spacer />
				<v-btn text small @click="closeModal">Đóng</v-btn>

				<!-- Nút Lưu dự thảo: chỉ hiển thị khi tạo mới hoặc đang là Dự thảo (1) -->
				<v-btn
					v-if="!isReadOnly && (form.TrangThai === 1 || !form.CGCNID)"
					color="grey darken-2"
					dark
					small
					depressed
					:loading="saving"
					class="mr-2"
					@click="saveItem(1)"
				>
					<v-icon left small>mdi-content-save-outline</v-icon>
					Lưu dự thảo
				</v-btn>

				<!-- Nút Gửi thẩm định: Tạo mới, hoặc Dự thảo (1), hoặc Cần bổ sung (4) -->
				<v-btn
					v-if="!isReadOnly"
					color="primary"
					small
					depressed
					:loading="saving"
					@click="saveItem(2)"
				>
					<v-icon left small>mdi-send</v-icon>
					{{ form.TrangThai === 4 ? "Gửi thẩm định lại" : "Lưu & Gửi thẩm định" }}
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-contract",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			itemData: {
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
				saving: false,
				uploadResult: null,
				attachedFiles: [],
				fileHeaders: [
					{ text: "Tập tin minh chứng", value: "FILE_NAME" },
					{ text: "Thao tác", value: "actions", align: "right", sortable: false, width: 80 }
				],
				fileFilters: {
					max_file_size: "20mb",
					mime_types: [{ title: "Tài liệu", extensions: "pdf,doc,docx,xls,xlsx,png,jpg,jpeg,zip,rar" }]
				},
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
			isEdit() {
				return !!(this.form && this.form.CGCNID)
			},
			isReadOnly() {
				// TrangThai = 2 (Chờ duyệt) hoặc 3 (Đã duyệt) thì chỉ xem, không được sửa
				return this.form.TrangThai === 2 || this.form.TrangThai === 3
			}
		},
		watch: {
			value(isOpen) {
				if (isOpen) {
					if (this.itemData && this.itemData.CGCNID) {
						this.syncFormFromItem(this.itemData)
					} else {
						this.resetForm()
					}
				}
			}
		},
		methods: {
			resetForm() {
				const currentYear = new Date().getFullYear()
				const currentSchoolYear = `${currentYear - 1}-${currentYear}`
				const userInfo = (window.vueData && window.vueData.user) || {}
				const defaultLeader = userInfo.FullName || userInfo.TenNhanVien || ""

				this.form = {
					CGCNID: null,
					SoThuTu: 0,
					TenDuAn: "",
					ChuNhiemDeTai: defaultLeader,
					ThanhVienDeTai: "",
					DonViChuNhiem: "Trường Đại học Lạc Hồng",
					DonViTiepNhan: "",
					GiaTriHopDong: 0,
					SoHopDong: "",
					NamHoc: currentSchoolYear,
					NamThucHien: currentYear,
					TrangThai: 1,
					LyDoReject: ""
				}
				this.attachedFiles = []
				this.uploadResult = null
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
					LyDoReject: item.LyDoReject || ""
				}
				this.attachedFiles = this.parseFileData(item.FileData)
				this.uploadResult = null
			},
			getFileUrl(file) {
				const baseUrl = (this.vSet && this.vSet.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
				return `${baseUrl}/FileData/${file.FILE_ID}`
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
				this.dialog = false
			},
			formatMoney(val) {
				if (val === null || val === undefined || val === "") return "0"
				if (typeof formatAsCurrency === "function") {
					return formatAsCurrency(Number(val) || 0, 0)
				}
				return Number(val || 0).toLocaleString("vi-VN")
			},
			validateForm() {
				if (!this.form.TenDuAn || !String(this.form.TenDuAn).trim()) {
					Vue.$toast.warning("Vui lòng nhập Tên dự án / Hợp đồng", { position: "top" })
					return false
				}
				if (!this.form.ChuNhiemDeTai || !String(this.form.ChuNhiemDeTai).trim()) {
					Vue.$toast.warning("Vui lòng nhập Chủ nhiệm đề tài", { position: "top" })
					return false
				}
				if (!this.form.DonViTiepNhan || !String(this.form.DonViTiepNhan).trim()) {
					Vue.$toast.warning("Vui lòng nhập Đơn vị tiếp nhận", { position: "top" })
					return false
				}
				return true
			},
			async saveItem(targetStatus) {
				if (!this.validateForm()) return

				const actionName = targetStatus === 2 ? "gửi thẩm định" : "lưu dự thảo"
				const confirmMsg = targetStatus === 2
					? `Bạn có chắc muốn gửi hồ sơ <b><i>${this.form.TenDuAn}</i></b> để thẩm định?`
					: `Bạn có muốn lưu hồ sơ <b><i>${this.form.TenDuAn}</i></b> dưới dạng dự thảo?`

				confirm({
					title: confirmMsg,
					action: async () => {
						this.saving = true
						try {
							const fileIdList = this.attachedFiles.map(item => item.FILE_ID).join(",")
							const params = {
								TenDuAn: this.form.TenDuAn,
								ChuNhiemDeTai: this.form.ChuNhiemDeTai,
								ThanhVienDeTai: this.form.ThanhVienDeTai,
								DonViChuNhiem: this.form.DonViChuNhiem,
								DonViTiepNhan: this.form.DonViTiepNhan,
								GiaTriHopDong: Number(this.form.GiaTriHopDong) || 0,
								NamThucHien: Number(this.form.NamThucHien) || null,
								SoHopDong: this.form.SoHopDong || "",
								DS_FileID: fileIdList,
								NamHoc: this.form.NamHoc,
								TrangThai: targetStatus
							}

							if (this.isEdit) {
								params.CGCNID = this.form.CGCNID
								await ajaxCALLPromise("/DEV_CGCN_Upd", params)
								Vue.$toast.success(
									targetStatus === 2
										? "Đã gửi hồ sơ thẩm định thành công!"
										: "Đã cập nhật dự thảo thành công!",
									{ position: "top" }
								)
							} else {
								await ajaxCALLPromise("/DEV_CGCN_Ins", params)
								Vue.$toast.success(
									targetStatus === 2
										? "Kê khai & gửi thẩm định hồ sơ thành công!"
										: "Đã tạo dự thảo hồ sơ thành công!",
									{ position: "top" }
								)
							}

							this.$emit("on-reload")
							this.closeModal()
						} finally {
							this.saving = false
						}
					}
				})
			}
		}
	}
</script>