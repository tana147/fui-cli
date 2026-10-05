<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" max-width="1400px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="d-flex align-center">
						<v-icon color="primary" class="mr-2">mdi-sync</v-icon>
						<span class="text-subtitle-1 font-weight-bold primary--text">Đồng bộ dữ liệu phân công GVHD</span>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pa-4">
				<v-row dense align="center" class="mb-3">
					<v-col cols="12" sm="6" md="4">
						<v-file-input
							v-model="fileUpload"
							dense
							hide-details
							accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
							label="Chọn file Excel"
							outlined
							prepend-icon=""
							prepend-inner-icon="mdi-file-excel"
						/>
					</v-col>

					<v-col cols="12" sm="6" md="4">
						<v-chip color="deep-purple accent-4" outlined label hide-details>
							<v-icon left small>mdi-file-check-outline</v-icon>
							<a
								class="text-decoration-none deep-purple--text text--accent-4 font-weight-medium"
								:href="templateUrl"
								target="_blank"
							>
								Tải file template mẫu
							</a>
						</v-chip>
					</v-col>

					<v-col cols="12" sm="12" md="4" class="text-right" v-if="DsHocVien.length > 0">
						<span class="text-caption grey--text text--darken-2">
							Đã nạp <b>{{ DsHocVien.length }}</b> dòng từ file Excel
						</span>
					</v-col>
				</v-row>

				<v-data-table
					class="rounded-xs elevation-1"
					:headers="tableHeader"
					:items="DsHocVien"
					:items-per-page="50"
					:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
					dense
					fixed-header
					height="calc(100vh - 280px)"
				>
					<template v-slot:no-data>
						<c-empty-state
							icon="mdi-file-excel-outline"
							text="Chưa có dữ liệu. Vui lòng chọn file Excel để xem trước danh sách phân công GVHD"
						/>
					</template>

					<template v-slot:item.STT="{ item, index }">
						{{ index + 1 }}
					</template>

					<template v-slot:item.StudentID="{ item }">
						<div class="py-1">
							<span class="primary--text font-weight-bold">{{ item.HoHV }} {{ item.TenHV }}</span>
							<br />
							<b>{{ item.StudentID }}</b>
							<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
						</div>
					</template>

					<template v-slot:item.Email="{ item }">
						<div class="py-1">
							<p class="mb-0 text-caption">{{ item.Email }}</p>
							<span class="font-weight-medium text-caption">{{ item.DienThoai }}</span>
						</div>
					</template>

					<template v-slot:item.GVHD1="{ item }">
						<span class="font-weight-medium">{{ item.GVHD1 }}</span>
					</template>

					<template v-slot:item.GVHD2="{ item }">
						<span class="font-weight-medium">{{ item.GVHD2 }}</span>
					</template>
				</v-data-table>
			</v-card-text>

			<v-card-actions class="pa-3">
				<v-spacer />
				<v-btn text class="rounded-xs" @click="close">Hủy</v-btn>
				<v-btn color="success" class="rounded-xs" :loading="saving" @click="onSave">
					<v-icon left small>mdi-content-save</v-icon>Lưu
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
				tableHeader: [
					{ text: "STT", value: "STT", align: "center", width: 50, sortable: false },
					{ text: "Học viên", value: "StudentID", width: 200, sortable: false },
					{ text: "Ngày sinh", value: "NgaySinh", width: 100, sortable: false },
					{ text: "Email/Điện thoại", value: "Email", width: 160, sortable: false },
					{ text: "Đề tài", value: "DeTai", width: 300, sortable: false },
					{ text: "GVHD 1", value: "GVHD1", width: 180, sortable: false },
					{ text: "GVHD 2", value: "GVHD2", width: 180, sortable: false },
				],
			}
		},
		computed: {
			templateUrl() {
				const baseUrl = window.vueData?.v_Set?.urlReadFile || ""
				return `${baseUrl}fileData/${this.fileTemplateId}`
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
			readExcel(file) {
				const reader = new FileReader()
				reader.onload = (e) => {
					try {
						const data = e.target.result
						const workbook = XLSX.read(data, { type: "array" })
						const sheetName = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[sheetName]
						const json = XLSX.utils.sheet_to_json(worksheet, {
							range: 6,
						})

						this.DsHocVien = json
							.map((item) => ({
								STT: item["STT"] ?? null,
								LopID: item["Lớp"] ?? null,
								StudentID: item["MSHV"] ?? null,
								HoHV: item["Họ"] ?? null,
								TenHV: item["Tên"] ?? null,
								NgaySinh: item["Ngày sinh"] ?? null,
								DienThoai: item["Điện thoại"] ?? null,
								Email: item["Email"] ?? null,
								DeTai: item["Tên đề tài"] ?? null,
								GVHD1: item["Giảng viên hướng dẫn 1"] ?? "",
								GVHD2: item["Giảng viên hướng dẫn 2"] ?? "",
							}))
							.filter((item) => item.StudentID)
					} catch (error) {
						Vue.$toast.error(`Lỗi đọc file: ${error}`, { position: "top" })
					}
				}
				reader.readAsArrayBuffer(file)
			},

			async onSave() {
				const dataArr = this.DsHocVien.map((item) => ({
					StudentID: item.StudentID,
					GVHD1: item.GVHD1,
					GVHD2: item.GVHD2,
				}))

				if (dataArr.length === 0) {
					Vue.$toast.warning("Chưa có danh sách học viên để đồng bộ", { position: "top" })
					return
				}

				this.saving = true
				try {
					await ajaxCALLPromise("/Student_GVHD_Update", {
						StudentObjArr: JSON.stringify(dataArr),
					})
					Vue.$toast.success("Đồng bộ GVHD thành công", { position: "top" })
					this.$emit("on-reload")
					this.close()
				} catch (error) {
					const msg = error?.responseJSON?.Message || error?.message || "Lỗi đồng bộ GVHD"
					Vue.$toast.error(msg, { position: "top" })
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