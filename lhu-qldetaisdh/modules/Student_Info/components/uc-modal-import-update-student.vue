<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card>
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="d-flex align-center">
						<v-icon color="primary" class="mr-2">mdi-file-excel-box</v-icon>
						<span class="text-subtitle-1 font-weight-bold primary--text">Cập nhật thông tin học viên bằng Excel</span>
					</div>
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
							label="Chọn file Excel cập nhật"
							outlined
							prepend-icon=""
							prepend-inner-icon="mdi-file-excel"
						/>
					</v-col>

					<v-col cols="12" sm="4" md="3">
						<v-btn color="deep-purple accent-4" outlined class="rounded-xs" :href="templateUrl" target="_blank">
							<v-icon left small>mdi-file-download-outline</v-icon>
							Tải file template mẫu
						</v-btn>
					</v-col>

					<v-col cols="12" sm="3" md="5" class="text-right" v-if="DsHocVien.length > 0">
						<v-btn color="error" text class="rounded-xs mr-2" @click="clearAll">
							<v-icon left small>mdi-trash-can-outline</v-icon>
							Xóa dữ liệu
						</v-btn>
						<span class="text-caption grey--text text--darken-2">
							Đã nạp <b>{{ DsHocVien.length }}</b> dòng
						</span>
					</v-col>
				</v-row>

				<v-data-table
					:headers="tableHeader"
					:items="DsHocVien"
					:items-per-page="50"
					:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
					dense
					fixed-header
					height="calc(100vh - 270px)"
					class="elevation-1 rounded-xs"
				>
					<template v-slot:no-data>
						<c-empty-state
							icon="mdi-file-excel-outline"
							text="Chưa có dữ liệu. Vui lòng chọn file Excel để tải danh sách học viên"
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
						<v-text-field v-model="item.Email" dense hide-details single-line placeholder="Email" />
					</template>

					<template v-slot:item.SoDienThoai="{ item }">
						<v-text-field v-model="item.SoDienThoai" dense hide-details single-line placeholder="Số điện thoại" />
					</template>

					<template v-slot:item.NoiSinh="{ item }">
						<v-text-field v-model="item.NoiSinh" dense hide-details single-line placeholder="Nơi sinh" />
					</template>

					<template v-slot:item.DanToc="{ item }">
						<v-text-field v-model="item.DanToc" dense hide-details single-line placeholder="Dân tộc" />
					</template>

					<template v-slot:item.QuocTich="{ item }">
						<v-text-field v-model="item.QuocTich" dense hide-details single-line placeholder="Quốc tịch" />
					</template>

					<template v-slot:item.CCCD="{ item }">
						<v-text-field v-model="item.CCCD" dense hide-details single-line placeholder="Số CCCD" />
					</template>

					<template v-slot:item.Truong_DaiHoc="{ item }">
						<v-text-field v-model="item.Truong_DaiHoc" dense hide-details single-line placeholder="Trường ĐH" />
					</template>

					<template v-slot:item.Nganh_DaiHoc="{ item }">
						<v-text-field v-model="item.Nganh_DaiHoc" dense hide-details single-line placeholder="Ngành ĐH" />
					</template>

					<template v-slot:item.ThoiGianTotNghiep_DaiHoc="{ item }">
						<v-text-field v-model="item.ThoiGianTotNghiep_DaiHoc" dense hide-details single-line placeholder="Năm TN ĐH" />
					</template>

					<template v-slot:item.XepLoai="{ item }">
						<v-text-field v-model="item.XepLoai" dense hide-details single-line placeholder="Xếp loại" />
					</template>

					<template v-slot:item.NgoaiNgu_DauVao="{ item }">
						<v-text-field v-model="item.NgoaiNgu_DauVao" dense hide-details single-line placeholder="NN đầu vào" />
					</template>
				</v-data-table>
			</v-card-text>

			<v-card-actions class="pa-3">
				<v-spacer />
				<v-btn text class="rounded-xs" @click="close">Hủy</v-btn>
				<v-btn color="success" class="rounded-xs" :loading="saving" :disabled="DsHocVien.length === 0" @click="onSave">
					<v-icon left small>mdi-content-save</v-icon>Lưu cập nhật
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-import-update-student",
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
				fileTemplateId: "9A539D8929504A2797FC79D8174A8A96",
				DsHocVien: [],
				saving: false,
				tableHeader: [
					{ text: "STT", value: "STT", align: "center", width: 50, sortable: false },
					{ text: "Học viên", value: "StudentID", width: 220, sortable: false },
					{ text: "Ngày sinh", value: "NgaySinh", width: 100, sortable: false },
					{ text: "Email", value: "Email", width: 170, sortable: false },
					{ text: "Số điện thoại", value: "SoDienThoai", width: 130, sortable: false },
					{ text: "Nơi sinh", value: "NoiSinh", width: 130, sortable: false },
					{ text: "Dân tộc", value: "DanToc", width: 100, sortable: false },
					{ text: "Quốc tịch", value: "QuocTich", width: 100, sortable: false },
					{ text: "Số CCCD", value: "CCCD", width: 130, sortable: false },
					{ text: "Trường ĐH", value: "Truong_DaiHoc", width: 170, sortable: false },
					{ text: "Ngành ĐH", value: "Nganh_DaiHoc", width: 170, sortable: false },
					{ text: "Năm TN ĐH", value: "ThoiGianTotNghiep_DaiHoc", width: 110, sortable: false },
					{ text: "Xếp loại", value: "XepLoai", width: 100, sortable: false },
					{ text: "NN đầu vào", value: "NgoaiNgu_DauVao", width: 130, sortable: false },
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
								NoiSinh: item["Nơi sinh"] ?? null,
								DanToc: item["Dân tộc"] ?? null,
								QuocTich: item["Quốc tịch"] ?? null,
								Email: item["Email"] ?? null,
								CCCD: item["Số CCCD"] ?? null,
								Truong_DaiHoc: item["Trường Đại học"] ?? null,
								ThoiGianTotNghiep_DaiHoc: item["Năm tốt nghiệp đại học"] ?? null,
								Nganh_DaiHoc: item["Ngành Đại học"] ?? null,
								XepLoai: item["Xếp loại"] ?? null,
								SoDienThoai: item["Số điện thoại"] ?? null,
								NgoaiNgu_DauVao: item["Ngoại ngữ đầu vào"] ?? null,
								Loai_NgoaiNgu_DauVao: item["Loại ngoại ngữ đầu vào"] ?? null,
								BoSungKienThuc: item["Bổ sung kiến thức"] ?? 0,
								CongBoKhoaHoc: item["Công bố khoa học"] ?? null,
							}))
							.filter((item) => item.StudentID)
					} catch (error) {
						Vue.$toast.error(`Lỗi đọc file: ${error}`, { position: "top" })
					}
				}
				reader.readAsArrayBuffer(file)
			},

			clearAll() {
				this.fileUpload = null
				this.DsHocVien = []
			},

			async onSave() {
				const arr = this.DsHocVien.map((item) => ({
					StudentID: item.StudentID ? item.StudentID.toString().trim() : null,
					DanToc: item.DanToc ? item.DanToc.trim() : null,
					Email: item.Email ? item.Email.trim() : null,
					NoiSinh: item.NoiSinh ? item.NoiSinh.trim() : null,
					QuocTich: item.QuocTich ? item.QuocTich.trim() : null,
					CCCD: item.CCCD ? item.CCCD.trim() : null,
					SoDienThoai: item.SoDienThoai ? item.SoDienThoai.trim() : null,
					Truong_DaiHoc: item.Truong_DaiHoc ? item.Truong_DaiHoc.trim() : null,
					Nganh_DaiHoc: item.Nganh_DaiHoc ? item.Nganh_DaiHoc.trim() : null,
					ThoiGianTotNghiep_DaiHoc: item.ThoiGianTotNghiep_DaiHoc,
					XepLoai: item.XepLoai ? item.XepLoai.trim() : null,
					NgoaiNgu_DauVao: item.NgoaiNgu_DauVao ? item.NgoaiNgu_DauVao.trim() : null,
					Loai_NgoaiNgu_DauVao: item.Loai_NgoaiNgu_DauVao,
					BoSungKienThuc: item.BoSungKienThuc,
					CongBoKhoaHoc: item.CongBoKhoaHoc,
				}))

				if (arr.length === 0) {
					Vue.$toast.warning("Chưa có dữ liệu học viên để cập nhật", { position: "top" })
					return
				}

				this.saving = true
				try {
					await ajaxCALLPromise("/StudentInfor_Update_Import", {
						JsonData: JSON.stringify(arr),
					})
					Vue.$toast.success("Cập nhật thông tin học viên thành công", { position: "top" })
					this.$emit("on-reload")
					this.close()
				} catch (error) {
					const msg = error?.responseJSON?.Message || error?.message || "Lỗi cập nhật học viên"
					Vue.$toast.error(msg, { position: "top" })
				} finally {
					this.saving = false
				}
			},

			close() {
				this.clearAll()
				this.$emit("input", false)
			},
		},
	}
</script>