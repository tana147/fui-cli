<template>
	<v-dialog :value="value" @input="$emit('input', $event)" max-width="850px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="title primary--text text-left">
						<v-icon left color="primary">mdi-card-account-details-outline</v-icon>
						Cập nhật Mã học viên Tiến sĩ theo Mã hồ sơ
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pa-4">
				<v-row dense align="center" class="mb-3">
					<v-col cols="12" sm="6">
						<v-file-input
							v-model="excelFile"
							dense
							outlined
							hide-details
							accept=".xlsx, .xls"
							label="Chọn file Excel cập nhật MSHV"
							prepend-icon=""
							prepend-inner-icon="mdi-file-excel"
						/>
					</v-col>
					<v-col cols="12" sm="6" class="d-flex align-center">
						<v-btn color="success" outlined class="rounded-xs mr-2" depressed @click="downloadTemplate">
							<v-icon left small>mdi-file-download-outline</v-icon>
							Tải file mẫu Excel
						</v-btn>
						<v-btn
							v-if="batchItems.length > 0"
							color="error"
							text
							class="rounded-xs"
							@click="clearBatch"
						>
							Xóa danh sách
						</v-btn>
					</v-col>
				</v-row>

				<v-alert v-if="batchInvalidCount > 0" dense type="error" outlined class="rounded-xs mb-2">
					Có <strong>{{ batchInvalidCount }}</strong> dòng dữ liệu chưa hợp lệ (Mã hồ sơ trống hoặc MSHV mới không đúng 9 chữ số). Vui lòng kiểm tra lại trước khi lưu.
				</v-alert>

				<v-alert v-else-if="batchItems.length > 0" dense type="info" outlined class="rounded-xs mb-2">
					Đã nạp <strong>{{ batchItems.length }}</strong> dòng dữ liệu. Toàn bộ mã học viên mới đều hợp lệ (9 chữ số).
				</v-alert>

				<v-data-table
					:headers="batchHeaders"
					:items="batchItems"
					:items-per-page="10"
					dense
					fixed-header
					height="320px"
					class="elevation-1 rounded-xs"
				>
					<template v-slot:no-data>
						<c-empty-state icon="mdi-file-excel" text="Chưa có dữ liệu. Vui lòng chọn file Excel để bắt đầu" />
					</template>

					<template v-slot:item.stt="{ index }">
						<span>{{ index + 1 }}</span>
					</template>

					<template v-slot:item.MaHoSo="{ item }">
						<span class="font-weight-medium">{{ item.MaHoSo }}</span>
					</template>

					<template v-slot:item.StudentName="{ item }">
						<span>{{ item.StudentName || '---' }}</span>
					</template>

					<template v-slot:item.NewStudentID="{ item }">
						<span :class="isValidStudentID(item.NewStudentID) ? 'primary--text font-weight-bold' : 'error--text font-weight-bold'">
							{{ item.NewStudentID }}
						</span>
					</template>

					<template v-slot:item.status="{ item }">
						<v-chip v-if="item.resultSuccess === true" small color="success" text-color="white" class="rounded-xs">
							<v-icon left small>mdi-check-circle</v-icon> Thành công
						</v-chip>
						<v-chip v-else-if="item.resultSuccess === false" small color="error" text-color="white" class="rounded-xs" :title="item.resultMessage">
							<v-icon left small>mdi-alert-circle</v-icon> Lỗi: {{ item.resultMessage }}
						</v-chip>
						<v-chip v-else-if="isValidStudentID(item.NewStudentID)" small color="blue-lighten-4" class="rounded-xs">
							Sẵn sàng
						</v-chip>
						<v-chip v-else small color="error" outlined class="rounded-xs">
							Không hợp lệ
						</v-chip>
					</template>
				</v-data-table>

				<div class="d-flex justify-end mt-3">
					<v-btn
						color="primary"
						class="rounded-xs"
						depressed
						:loading="isSavingBatch"
						:disabled="batchItems.length === 0 || batchInvalidCount > 0"
						@click="onSaveBatch"
					>
						<v-icon left small>mdi-content-save-all</v-icon>
						Cập nhật hàng loạt ({{ batchItems.length }} học viên)
					</v-btn>
				</div>
			</v-card-text>

			<v-divider />

			<v-card-actions class="pa-3">
				<v-spacer />
				<v-btn text class="rounded-xs" @click="close">Đóng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-update-student-id",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			dsExistStudent: {
				type: Array,
				default: () => [],
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				excelFile: null,
				batchItems: [],
				isSavingBatch: false,
				batchHeaders: [
					{ text: "STT", value: "stt", align: "center", width: 60, sortable: false },
					{ text: "Mã hồ sơ", value: "MaHoSo", width: 140 },
					{ text: "Học viên (Hệ thống)", value: "StudentName", width: 220 },
					{ text: "Mã HV mới (9 số)", value: "NewStudentID", width: 160 },
					{ text: "Trạng thái", value: "status", align: "center", width: 160, sortable: false },
				],
			}
		},
		computed: {
			batchInvalidCount() {
				return this.batchItems.filter(
					(x) => !x.MaHoSo || !this.isValidStudentID(x.NewStudentID)
				).length
			},
		},
		watch: {
			value(val) {
				if (val) {
					this.resetForm()
				}
			},
			excelFile(val) {
				if (val) {
					this.readExcelFile(val)
				}
			},
		},
		methods: {
			isValidStudentID(id) {
				if (!id) return false
				const s = id.toString().trim()
				return /^\d{9}$/.test(s)
			},

			resetForm() {
				this.excelFile = null
				this.batchItems = []
			},

			close() {
				this.resetForm()
				this.$emit("input", false)
			},

			downloadTemplate() {
				const sampleData = [
					{
						"Mã hồ sơ": "HS01",
						"Mã học viên mới": "923000215",
						"Ghi chú": "Mã học viên mới bắt buộc gồm đúng 9 chữ số",
					},
					{
						"Mã hồ sơ": "HSXD1",
						"Mã học viên mới": "923000216",
						"Ghi chú": "Mã hồ sơ có thể là mã tạm ban đầu hoặc MSHV cũ",
					},
				]

				jsonToExcel({
					data: sampleData,
					filename: "Mau_Cap_Nhat_Ma_Hoc_Vien_Tien_Si.xlsx",
					worksheet: "CapNhatMSHV",
				})
			},

			readExcelFile(file) {
				const reader = new FileReader()
				reader.onload = (e) => {
					try {
						const data = e.target.result
						const workbook = XLSX.read(data, { type: "array" })
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]
						const json = XLSX.utils.sheet_to_json(worksheet)

						if (!json || json.length === 0) {
							Vue.$toast.warning("File Excel không có dữ liệu", { position: "top" })
							return
						}

						const mapped = json.map((row) => {
							const maHoSo = (
								row["Mã hồ sơ"] ||
								row["MaHoSo"] ||
								row["Mã HS"] ||
								row["Mã hồ sơ cũ"] ||
								row["MSHV cũ"] ||
								row["StudentID"] ||
								""
							).toString().trim()

							const newId = (
								row["Mã học viên mới"] ||
								row["Mã số học viên mới"] ||
								row["NewStudentID"] ||
								row["MSHV mới"] ||
								row["Mã mới"] ||
								""
							).toString().trim()

							// Tìm tên trong ds học viên hiện tại
							let studentName = ""
							const found = (this.dsExistStudent || []).find((s) => {
								const sMaHoSo = (s.MaHoSo || "").toLowerCase().trim()
								const sId = (s.StudentID || "").toLowerCase().trim()
								const q = maHoSo.toLowerCase()
								return sMaHoSo === q || sId === q
							})
							if (found) {
								studentName = found.HoTen || `${found.HoSV || ''} ${found.TenSV || ''}`.trim()
							}

							return {
								MaHoSo: maHoSo,
								NewStudentID: newId,
								StudentName: studentName,
								resultSuccess: null,
								resultMessage: "",
							}
						}).filter((x) => x.MaHoSo || x.NewStudentID)

						this.batchItems = mapped

						const invalidCount = mapped.filter((x) => !x.MaHoSo || !this.isValidStudentID(x.NewStudentID)).length
						if (invalidCount > 0) {
							Vue.$toast.error(`Đã đọc ${mapped.length} dòng. Có ${invalidCount} dòng mã học viên mới không đúng 9 số!`, { position: "top" })
						} else {
							Vue.$toast.success(`Đã đọc thành công ${mapped.length} dòng dữ liệu cập nhật`, { position: "top" })
						}
					} catch (error) {
						console.error("Lỗi đọc file Excel:", error)
						Vue.$toast.error(`Lỗi đọc file: ${error.message || error}`, { position: "top" })
					}
				}
				reader.readAsArrayBuffer(file)
			},

			clearBatch() {
				this.batchItems = []
				this.excelFile = null
			},

			async onSaveBatch() {
				if (this.batchItems.length === 0 || this.batchInvalidCount > 0) return

				const payload = this.batchItems.map((x) => ({
					MaHoSo: x.MaHoSo,
					NewStudentID: x.NewStudentID,
				}))

				this.isSavingBatch = true
				try {
					const res = await ajaxCALLPromise("/Student_Update_StudentID_Batch_TS", {
						JsonData: JSON.stringify(payload),
					})

					// Map kết quả trả về vào bảng
					let successCount = 0
					let errorCount = 0

					const resultMap = {}
					if (Array.isArray(res)) {
						res.forEach((r) => {
							resultMap[r.MaHoSo] = r
						})
					}

					this.batchItems.forEach((item) => {
						const r = resultMap[item.MaHoSo]
						if (r) {
							item.resultSuccess = r.Success === 1 || r.Success === true
							item.resultMessage = r.Message || ""
							if (item.resultSuccess) successCount++
							else errorCount++
						} else {
							item.resultSuccess = false
							item.resultMessage = "Không nhận được phản hồi"
							errorCount++
						}
					})

					if (errorCount === 0) {
						Vue.$toast.success(`Cập nhật thành công toàn bộ ${successCount} học viên!`, { position: "top" })
						this.$emit("on-reload")
						this.close()
					} else {
						Vue.$toast.warning(`Hoàn tất: ${successCount} thành công, ${errorCount} lỗi. Vui lòng xem chi tiết trên bảng.`, { position: "top" })
						this.$emit("on-reload")
					}
				} catch (error) {
					console.error("Lỗi cập nhật batch:", error)
					Vue.$toast.error(`Lỗi cập nhật: ${error.message || error}`, { position: "top" })
				} finally {
					this.isSavingBatch = false
				}
			},
		},
	}
</script>