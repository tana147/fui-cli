<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card>
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="title primary--text text-left">Đồng bộ dữ liệu phân công GVHD & Đề tài (Tiến sĩ)</div>
				</template>
			</c-toolbar>

			<v-card-text class="pa-4">
				<v-row dense align="center" class="mb-3">
					<v-col cols="12" sm="5" md="4">
						<v-file-input
							v-model="fileUpload"
							dense
							hide-details
							accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
							label="Chọn file Excel phân công"
							outlined
							prepend-icon=""
							prepend-inner-icon="mdi-file-excel"
						/>
					</v-col>

					<v-col cols="12" sm="3" md="2">
						<v-btn color="success" class="rounded-xs" depressed @click="downloadTemplate" :loading="isDownloadingTemplate">
							<v-icon left small>mdi-file-download-outline</v-icon>
							Tải file mẫu Excel
						</v-btn>
					</v-col>

					<v-col cols="12" sm="4" md="6" class="d-flex justify-end align-center">
						<v-btn color="error" outlined class="rounded-xs" :disabled="DsHocVien.length === 0" @click="clearAll">
							<v-icon left small>mdi-trash-can-outline</v-icon>
							Xóa bảng
						</v-btn>
					</v-col>
				</v-row>

				<!-- Cảnh báo nếu có mã học viên không đúng chuẩn 9 số -->
				<v-alert v-if="invalidStudentIdCount > 0" dense colored-border type="error" elevation="1" class="mb-3 rounded-xs">
					<div>
						<strong>Mã học viên chưa hợp lệ:</strong> Có <strong>{{ invalidStudentIdCount }}</strong> dòng mã số học viên không đúng chuẩn 9 số (ví dụ HS1, HS2...). Vui lòng kiểm tra lại file Excel.
					</div>
				</v-alert>

				<!-- Thông báo tổng số NCS -->
				<v-alert v-else-if="DsHocVien.length > 0" dense text type="info" class="mb-2 rounded-xs">
					Tổng số nghiên cứu sinh: <strong>{{ DsHocVien.length }}</strong> dòng. Vui lòng kiểm tra lại thông tin đề tài và cán bộ hướng dẫn trước khi bấm lưu đồng bộ.
				</v-alert>

				<v-data-table
					:headers="tableHeader"
					:items="DsHocVien"
					:items-per-page="-1"
					hide-default-footer
					dense
					fixed-header
					height="calc(100vh - 270px)"
					class="elevation-1 rounded-xs"
				>
					<template v-slot:no-data>
						<c-empty-state
							icon="mdi-file-excel-outline"
							text="Chưa có dữ liệu. Vui lòng chọn file Excel để tải danh sách phân công GVHD & đề tài"
						/>
					</template>

					<template v-slot:item.STT="{ index }">
						<span>{{ index + 1 }}</span>
					</template>

					<template v-slot:item.StudentID="{ item }">
						<div class="py-1">
							<span class="primary--text font-weight-bold">{{ item.HoHV }} {{ item.TenHV }}</span>
							<br />
							<b :class="{ 'error--text': !isValidStudentID(item.StudentID) }">{{ item.StudentID }}</b>
							<v-chip v-if="!isValidStudentID(item.StudentID)" x-small color="error" class="ml-1" label>
								Sai chuẩn 9 số
							</v-chip>
							<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
						</div>
					</template>

					<template v-slot:item.Email="{ item }">
						<div>
							<div v-if="item.Email">{{ item.Email }}</div>
							<div v-if="item.DienThoai" class="text-caption grey--text text--darken-2"><b>{{ item.DienThoai }}</b></div>
						</div>
					</template>

					<template v-slot:item.DeTai="{ item }">
						<v-textarea
							v-model="item.DeTai"
							placeholder="Tên đề tài luận án chính thức..."
							dense
							hide-details
							rows="1"
							auto-grow
						/>
					</template>

					<template v-slot:item.GVHD1="{ item }">
						<v-text-field
							v-model="item.GVHD1"
							placeholder="Cán bộ hướng dẫn 1"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.GVHD2="{ item }">
						<v-text-field
							v-model="item.GVHD2"
							placeholder="Cán bộ hướng dẫn 2 (nếu có)"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.actions="{ index }">
						<v-btn icon x-small color="error" @click="removeRow(index)" title="Xóa dòng này">
							<v-icon small>mdi-close</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>

			<v-divider />

			<v-card-actions class="pa-3">
				<v-spacer />
				<v-btn text class="rounded-xs" @click="close">Hủy</v-btn>
				<v-btn
					color="primary"
					class="rounded-xs"
					:loading="saving"
					:disabled="isSaveDisabled"
					@click="onSave"
				>
					<v-icon left small>mdi-content-save</v-icon>
					{{ saveButtonText }}
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-sync-gvhd",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				fileUpload: null,
				fileTemplateId: "D462392FE2C042D9909537208A729858",
				DsHocVien: [],
				saving: false,
				isDownloadingTemplate: false,
				tableHeader: [
					{ text: "STT", value: "STT", align: "center", width: 50, sortable: false },
					{ text: "Nghiên cứu sinh", value: "StudentID", width: 200, sortable: false },
					{ text: "Ngày sinh", value: "NgaySinh", width: 110, align: "center", sortable: false },
					{ text: "Email / SĐT", value: "Email", width: 170, sortable: false },
					{ text: "Tên đề tài luận án", value: "DeTai", width: 350, sortable: false },
					{ text: "Cán bộ hướng dẫn 1", value: "GVHD1", width: 180, sortable: false },
					{ text: "Cán bộ hướng dẫn 2", value: "GVHD2", width: 180, sortable: false },
					{ text: "Xóa", value: "actions", align: "center", width: 60, sortable: false },
				],
			}
		},
		computed: {
			templateUrl() {
				const baseUrl = window.vueData?.v_Set?.urlReadFile || ""
				return `${baseUrl}fileData/${this.fileTemplateId}`
			},
			invalidStudentIdCount() {
				return (this.DsHocVien || []).filter((x) => !this.isValidStudentID(x.StudentID)).length
			},
			isSaveDisabled() {
				return this.DsHocVien.length === 0 || this.invalidStudentIdCount > 0 || this.saving
			},
			saveButtonText() {
				if (this.invalidStudentIdCount > 0) {
					return `Mã HV chưa chuẩn 9 số (${this.invalidStudentIdCount} dòng)`
				}
				return `Lưu đồng bộ (${this.DsHocVien.length})`
			},
		},
		watch: {
			fileUpload(val) {
				if (val) {
					this.readExcel(val)
				} else {
					this.DsHocVien = []
				}
			},
		},
		methods: {
			downloadTemplate() {
				this.isDownloadingTemplate = true
				try {
					const sampleData = [
						{
							"STT": 1,
							"Lớp": "23TS111",
							"MSHV": "926000087",
							"Họ": "Nguyễn Văn",
							"Tên": "An",
							"Ngày sinh": "15/08/1988",
							"Điện thoại": "0912345678",
							"Email": "annv_ts@lhu.edu.vn",
							"Tên đề tài": "Nghiên cứu ứng dụng trí tuệ nhân tạo trong tự động hóa quy trình nghiệp vụ",
							"Giảng viên hướng dẫn 1": "PGS.TS. Trần Văn B",
							"Giảng viên hướng dẫn 2": "TS. Lê Thị C",
						},
						{
							"STT": 2,
							"Lớp": "23TS111",
							"MSHV": "926000203",
							"Họ": "Trần Thị",
							"Tên": "Bình",
							"Ngày sinh": "20/11/1990",
							"Điện thoại": "0987654321",
							"Email": "binhtt_ts@lhu.edu.vn",
							"Tên đề tài": "Phát triển mô hình bảo mật dữ liệu phân tán trong hệ thống quản lý đào tạo",
							"Giảng viên hướng dẫn 1": "GS.TS. Hoàng Minh D",
							"Giảng viên hướng dẫn 2": "",
						},
					]

					jsonToExcel({
						data: sampleData,
						filename: "Mau_DongBo_GVHD_DeTai_TienSi.xlsx",
						worksheet: "PhanCongGVHD",
					})
					Vue.$toast.success("Tải file mẫu thành công", { position: "top" })
				} catch (error) {
					console.error("Lỗi tạo file mẫu Excel:", error)
					if (this.templateUrl) {
						window.open(this.templateUrl, "_blank")
					} else {
						Vue.$toast.error("Lỗi tạo file mẫu Excel", { position: "top" })
					}
				} finally {
					this.isDownloadingTemplate = false
				}
			},

			normalizeStudentID(val) {
				if (val === null || val === undefined) return ""
				let s = String(val).trim()
				if (/\.0+$/.test(s)) {
					s = s.replace(/\.0+$/, "")
				}
				return s
			},

			isValidStudentID(id) {
				if (!id) return false
				const str = this.normalizeStudentID(id)
				return /^\d{9}$/.test(str)
			},

			clearAll() {
				this.DsHocVien = []
				this.fileUpload = null
			},

			removeRow(index) {
				this.DsHocVien.splice(index, 1)
			},

			readExcel(file) {
				const reader = new FileReader()
				reader.onload = (e) => {
					try {
						const data = e.target.result
						const workbook = XLSX.read(data, { type: "array" })
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]

						// Thử đọc từ dòng 0 trước
						let json = XLSX.utils.sheet_to_json(worksheet)
						// Nếu không thấy cột MSHV ở range 0, thử đọc range: 6 (format legacy có header trường)
						if (json && json.length > 0 && !json.some((item) => item["MSHV"] || item["Mã học viên"] || item["StudentID"])) {
							json = XLSX.utils.sheet_to_json(worksheet, { range: 6 })
						}

						if (!json || json.length === 0) {
							Vue.$toast.warning("File Excel không có dữ liệu", { position: "top" })
							return
						}

						this.DsHocVien = json
							.map((item) => {
								const mshv = this.normalizeStudentID(item["MSHV"] || item["Mã học viên"] || item["Mã số học viên"] || item["StudentID"] || "")
								return {
									STT: item["STT"] !== undefined && item["STT"] !== null ? item["STT"] : null,
									LopID: item["Lớp"] || item["LopID"] || item["Lớp học"] || null,
									StudentID: mshv,
									HoHV: item["Họ"] || item["Họ đệm"] || item["HoHV"] || "",
									TenHV: item["Tên"] || item["TenHV"] || "",
									NgaySinh: item["Ngày sinh"] || item["NgaySinh"] || null,
									DienThoai: item["Điện thoại"] || item["Số điện thoại"] || item["DienThoai"] || null,
									Email: item["Email"] || null,
									DeTai: item["Tên đề tài"] || item["Đề tài"] || item["DeTai"] || item["ThesisName"] || null,
									GVHD1: item["Giảng viên hướng dẫn 1"] || item["GVHD 1"] || item["GVHD1"] || item["ThesisesProf1"] || "",
									GVHD2: item["Giảng viên hướng dẫn 2"] || item["GVHD 2"] || item["GVHD2"] || item["ThesisesProf2"] || "",
								}
							})
							.filter((item) => item.StudentID)

						const invalidCount = this.DsHocVien.filter((x) => !this.isValidStudentID(x.StudentID)).length

						if (invalidCount > 0) {
							Vue.$toast.error(`Có ${invalidCount} dòng mã học viên không đúng chuẩn 9 số (ví dụ HS1, HS2...). Không thể đồng bộ các dòng này!`, { position: "top" })
						} else if (this.DsHocVien.length > 0) {
							Vue.$toast.success(`Đã nạp thành công ${this.DsHocVien.length} nghiên cứu sinh từ file Excel`, { position: "top" })
						} else {
							Vue.$toast.warning("Không tìm thấy dòng hợp lệ có MSHV trong file", { position: "top" })
						}
					} catch (error) {
						Vue.$toast.error(`Lỗi đọc file excel: ${error}`, { position: "top" })
					}
				}
				reader.readAsArrayBuffer(file)
			},

			async onSave() {
				if (this.invalidStudentIdCount > 0) {
					Vue.$toast.error(`Có ${this.invalidStudentIdCount} dòng mã học viên không hợp lệ (bắt buộc đúng chuẩn 9 số). Vui lòng kiểm tra lại!`, { position: "top" })
					return
				}

				const dataArr = this.DsHocVien.map((item) => ({
					StudentID: item.StudentID,
					DeTai: item.DeTai,
					GVHD1: item.GVHD1,
					GVHD2: item.GVHD2,
				}))

				if (dataArr.length === 0) {
					Vue.$toast.warning("Chưa có danh sách học viên để đồng bộ", { position: "top" })
					return
				}

				this.saving = true
				try {
					await ajaxCALLPromise("/Student_GVHD_Update_TS", {
						StudentObjArr: JSON.stringify(dataArr),
					})
					Vue.$toast.success("Đồng bộ GVHD & Đề tài thành công", { position: "top" })
					this.$emit("on-reload")
					this.close()
				} finally {
					this.saving = false
				}
			},

			close() {
				this.fileUpload = null
				this.DsHocVien = []
				this.$emit("input", false)
			},
		},
	}
</script>