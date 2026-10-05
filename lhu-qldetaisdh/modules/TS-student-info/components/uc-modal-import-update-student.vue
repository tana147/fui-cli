<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card>
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="title primary--text text-left">Cập nhật thông tin học viên bằng Excel (Tiến sĩ)</div>
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
						<strong>Mã học viên chưa hợp lệ:</strong> Có <strong>{{ invalidStudentIdCount }}</strong> dòng mã số học viên không đúng chuẩn 9 số (ví dụ HS1, HS2...). Vui lòng kiểm tra lại file Excel trước khi lưu cập nhật.
					</div>
				</v-alert>

				<!-- Thông báo tổng số học viên -->
				<v-alert v-else-if="DsHocVien.length > 0" dense text type="info" class="mb-2 rounded-xs">
					Tổng số học viên: <strong>{{ DsHocVien.length }}</strong> dòng. Vui lòng kiểm tra lại thông tin trước khi bấm lưu cập nhật.
				</v-alert>

				<v-data-table
					:headers="tableHeader"
					:items="DsHocVien"
					:items-per-page="-1"
					hide-default-footer
					dense
					fixed-header
					height="calc(100vh - 270px)"
					class="elevation-1 table-frozen-import-cols"
				>
					<template v-slot:no-data>
						<c-empty-state
							icon="mdi-file-excel-outline"
							text="Chưa có dữ liệu. Vui lòng chọn file Excel để tải danh sách học viên"
						/>
					</template>

					<template v-slot:item.STT="{ index }">
						<span>{{ index + 1 }}</span>
					</template>

					<template v-slot:item.StudentID="{ item }">
						<div class="py-1">
							<strong :class="{ 'error--text': !isValidStudentID(item.StudentID) }">{{ item.StudentID }}</strong>
							<v-chip v-if="!isValidStudentID(item.StudentID)" x-small color="error" class="ml-1" label>
								Sai chuẩn 9 số
							</v-chip>
							<div class="text-caption grey--text text--darken-1" v-if="item.HoHV || item.TenHV">
								{{ item.HoHV }} {{ item.TenHV }}
							</div>
						</div>
					</template>

					<template v-slot:item.Email="{ item }">
						<v-text-field v-model="item.Email" placeholder="Email" dense hide-details />
					</template>

					<template v-slot:item.SoDienThoai="{ item }">
						<v-text-field v-model="item.SoDienThoai" placeholder="Số điện thoại" dense hide-details />
					</template>

					<template v-slot:item.GioiTinh="{ item }">
						<v-select v-model="item.GioiTinh" :items="['Nam', 'Nữ']" placeholder="Giới tính" dense hide-details />
					</template>

					<template v-slot:item.NoiSinh="{ item }">
						<v-text-field v-model="item.NoiSinh" placeholder="Nơi sinh" dense hide-details />
					</template>

					<template v-slot:item.DanToc="{ item }">
						<v-text-field v-model="item.DanToc" placeholder="Dân tộc" dense hide-details />
					</template>

					<template v-slot:item.QuocTich="{ item }">
						<v-text-field v-model="item.QuocTich" placeholder="Quốc tịch" dense hide-details />
					</template>

					<template v-slot:item.CCCD="{ item }">
						<v-text-field v-model="item.CCCD" placeholder="Số CCCD" dense hide-details />
					</template>

					<template v-slot:item.NgayCap_CCCD="{ item }">
						<v-text-field v-model="item.NgayCap_CCCD" placeholder="DD-MM-YYYY" dense hide-details />
					</template>

					<template v-slot:item.NgheNghiep="{ item }">
						<v-text-field v-model="item.NgheNghiep" placeholder="Nghề nghiệp" dense hide-details />
					</template>

					<template v-slot:item.NoiLamViec="{ item }">
						<v-text-field v-model="item.NoiLamViec" placeholder="Nơi làm việc" dense hide-details />
					</template>

					<template v-slot:item.DiaChi="{ item }">
						<v-text-field v-model="item.DiaChi" placeholder="Địa chỉ liên hệ" dense hide-details />
					</template>

					<template v-slot:item.Truong_DaiHoc="{ item }">
						<v-text-field v-model="item.Truong_DaiHoc" placeholder="Trường ĐH" dense hide-details />
					</template>

					<template v-slot:item.Nganh_DaiHoc="{ item }">
						<v-text-field v-model="item.Nganh_DaiHoc" placeholder="Ngành ĐH" dense hide-details />
					</template>

					<template v-slot:item.HeDaoTao_DaiHoc="{ item }">
						<v-text-field v-model="item.HeDaoTao_DaiHoc" placeholder="Hệ ĐH" dense hide-details />
					</template>

					<template v-slot:item.ThoiGianTotNghiep_DaiHoc="{ item }">
						<v-text-field
							v-model="item.ThoiGianTotNghiep_DaiHoc"
							placeholder="Năm tốt nghiệp ĐH"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.Truong_ThacSi="{ item }">
						<v-text-field v-model="item.Truong_ThacSi" placeholder="Trường ThS" dense hide-details />
					</template>

					<template v-slot:item.Nganh_ThacSi="{ item }">
						<v-text-field v-model="item.Nganh_ThacSi" placeholder="Ngành ThS" dense hide-details />
					</template>

					<template v-slot:item.HeDaoTao_ThacSi="{ item }">
						<v-text-field v-model="item.HeDaoTao_ThacSi" placeholder="Hệ ThS" dense hide-details />
					</template>

					<template v-slot:item.ThoiGianTotNghiep_ThacSi="{ item }">
						<v-text-field
							v-model="item.ThoiGianTotNghiep_ThacSi"
							placeholder="Năm tốt nghiệp ThS"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.XepLoai="{ item }">
						<v-text-field v-model="item.XepLoai" placeholder="Xếp loại" dense hide-details />
					</template>

					<template v-slot:item.Loai_NgoaiNgu_DauVao="{ item }">
						<v-autocomplete
							v-model="item.Loai_NgoaiNgu_DauVao"
							placeholder="Loại ngoại ngữ"
							:items="DsTenNgoaiNgu"
							item-text="text"
							item-value="value"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.NgoaiNgu_DauVao="{ item }">
						<v-text-field v-model="item.NgoaiNgu_DauVao" placeholder="Ngoại ngữ đầu vào" dense hide-details />
					</template>

					<template v-slot:item.BoSungKienThuc="{ item }">
						<v-autocomplete
							v-model="item.BoSungKienThuc"
							placeholder="Bổ sung KT"
							:items="DsYesNo"
							item-text="text"
							item-value="value"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.CongBoKhoaHoc="{ item }">
						<v-autocomplete
							v-model="item.CongBoKhoaHoc"
							placeholder="Công bố KH"
							:items="DsYesNo"
							item-text="text"
							item-value="value"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.action="{ index }">
						<v-btn icon x-small color="error" @click="removeRow(index)" title="Xóa dòng này">
							<v-icon small>mdi-close-circle-outline</v-icon>
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
		name: "uc-modal-import-update-student",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			dsNienKhoa: {
				type: Array,
				default: () => [],
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				fileUpload: null,
				fileTemplateId: "9A539D8929504A2797FC79D8174A8A96",
				DsTenNgoaiNgu: [],
				DsHocVien: [],
				DsYesNo: [],
				saving: false,
				isDownloadingTemplate: false,
				tableHeader: [
					{ text: "STT", value: "STT", align: "center", width: 50, sortable: false },
					{ text: "Mã số HV", value: "StudentID", width: 160, sortable: false },
					{ text: "Email", value: "Email", width: 200, sortable: false },
					{ text: "Số điện thoại", value: "SoDienThoai", width: 120, sortable: false },
					{ text: "Giới tính", value: "GioiTinh", width: 100, sortable: false },
					{ text: "Nơi sinh", value: "NoiSinh", width: 120, sortable: false },
					{ text: "Dân tộc", value: "DanToc", width: 100, sortable: false },
					{ text: "Quốc tịch", value: "QuocTich", width: 100, sortable: false },
					{ text: "Số CCCD", value: "CCCD", width: 120, sortable: false },
					{ text: "Ngày cấp CCCD", value: "NgayCap_CCCD", width: 130, sortable: false },
					{ text: "Nghề nghiệp", value: "NgheNghiep", width: 160, sortable: false },
					{ text: "Nơi làm việc", value: "NoiLamViec", width: 200, sortable: false },
					{ text: "Địa chỉ liên hệ", value: "DiaChi", width: 220, sortable: false },
					{ text: "Trường Đại học", value: "Truong_DaiHoc", width: 200, sortable: false },
					{ text: "Ngành Đại học", value: "Nganh_DaiHoc", width: 200, sortable: false },
					{ text: "Hệ đào tạo ĐH", value: "HeDaoTao_DaiHoc", width: 130, sortable: false },
					{ text: "Năm tốt nghiệp ĐH", value: "ThoiGianTotNghiep_DaiHoc", width: 160, sortable: false },
					{ text: "Trường Thạc sĩ", value: "Truong_ThacSi", width: 200, sortable: false },
					{ text: "Ngành Thạc sĩ", value: "Nganh_ThacSi", width: 200, sortable: false },
					{ text: "Hệ đào tạo ThS", value: "HeDaoTao_ThacSi", width: 130, sortable: false },
					{ text: "Năm tốt nghiệp ThS", value: "ThoiGianTotNghiep_ThacSi", width: 160, sortable: false },
					{ text: "Xếp loại", value: "XepLoai", width: 100, sortable: false },
					{ text: "Loại ngoại ngữ đầu vào", value: "Loai_NgoaiNgu_DauVao", width: 180, sortable: false },
					{ text: "Ngoại ngữ đầu vào", value: "NgoaiNgu_DauVao", width: 160, sortable: false },
					{ text: "Bổ sung kiến thức", value: "BoSungKienThuc", width: 140, sortable: false },
					{ text: "Công bố khoa học", value: "CongBoKhoaHoc", width: 140, sortable: false },
					{ text: "", value: "action", width: 50, sortable: false, align: "center" },
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
				return `Lưu cập nhật (${this.DsHocVien.length})`
			},
		},
		watch: {
			value(val) {
				if (val) {
					if (typeof NgoaiNgu_NameList === "function") {
						this.DsTenNgoaiNgu = NgoaiNgu_NameList()
					}
					if (typeof YesNoArray === "function") {
						this.DsYesNo = YesNoArray()
					}
				}
			},
			fileUpload(val) {
				if (val) {
					this.readExcel(val)
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
							"MSHV": "923000215",
							"Họ HV": "Nguyễn Đình",
							"Tên HV": "Nghĩa",
							"Email": "nghiand_ts@lhu.edu.vn",
							"Số điện thoại": "0918889999",
							"Giới tính": "Nam",
							"Nơi sinh": "Đồng Nai",
							"Dân tộc": "Kinh",
							"Quốc tịch": "Việt Nam",
							"Số CCCD": "075088001234",
							"Ngày cấp CCCD": "15-05-2021",
							"Nghề nghiệp": "Giảng viên",
							"Nơi làm việc": "Trường Đại học Lạc Hồng",
							"Địa chỉ liên hệ": "Số 10 Huỳnh Văn Nghệ, P. Bửu Long, TP. Biên Hòa, Đồng Nai",
							"Trường Đại học": "Đại học Lạc Hồng",
							"Ngành Đại học": "Quản trị kinh doanh",
							"Hệ đào tạo ĐH": "Chính quy",
							"Năm tốt nghiệp đại học": "2010",
							"Trường Thạc sĩ": "Đại học Lạc Hồng",
							"Ngành Thạc sĩ": "Quản trị kinh doanh",
							"Hệ đào tạo ThS": "Chính quy",
							"Năm tốt nghiệp thạc sĩ": "2014",
							"Xếp loại": "Khá",
							"Loại ngoại ngữ đầu vào": "Tiếng Anh",
							"Ngoại ngữ đầu vào": "B1",
							"Bổ sung kiến thức": "Không",
							"Công bố khoa học": "Có",
						},
						{
							"STT": 2,
							"MSHV": "923000216",
							"Họ HV": "Đào Quốc",
							"Tên HV": "Phương",
							"Email": "phuongdq_ts@lhu.edu.vn",
							"Số điện thoại": "0909123456",
							"Giới tính": "Nam",
							"Nơi sinh": "Bình Dương",
							"Dân tộc": "Kinh",
							"Quốc tịch": "Việt Nam",
							"Số CCCD": "074090005678",
							"Ngày cấp CCCD": "20-10-2021",
							"Nghề nghiệp": "Kỹ sư phần mềm",
							"Nơi làm việc": "Công ty TNHH Giải pháp Công nghệ ABC",
							"Địa chỉ liên hệ": "Phường Phú Hòa, TP. Thủ Dầu Một, Bình Dương",
							"Trường Đại học": "Đại học Bách Khoa",
							"Ngành Đại học": "Công nghệ thông tin",
							"Hệ đào tạo ĐH": "Chính quy",
							"Năm tốt nghiệp đại học": "2012",
							"Trường Thạc sĩ": "Đại học Lạc Hồng",
							"Ngành Thạc sĩ": "Khoa học máy tính",
							"Hệ đào tạo ThS": "Chính quy",
							"Năm tốt nghiệp thạc sĩ": "2016",
							"Xếp loại": "Giỏi",
							"Loại ngoại ngữ đầu vào": "Tiếng Anh",
							"Ngoại ngữ đầu vào": "IELTS 6.5",
							"Bổ sung kiến thức": "Không",
							"Công bố khoa học": "Có",
						},
					]

					jsonToExcel({
						data: sampleData,
						filename: "Mau_Cap_Nhat_Thong_Tin_Hoc_Vien_Tien_Si.xlsx",
						worksheet: "CapNhatThongTin",
					})
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
						const json = XLSX.utils.sheet_to_json(worksheet)

						if (!json || json.length === 0) {
							Vue.$toast.warning("File Excel không có dữ liệu", { position: "top" })
							return
						}

						this.DsHocVien = json.map((item) => {
							const mshv = this.normalizeStudentID(item["MSHV"] || item["Mã học viên"] || item["Mã số học viên"] || item["StudentID"] || item["Mã hồ sơ"] || "")
							return {
								STT: item["STT"] !== undefined && item["STT"] !== null ? item["STT"] : null,
								StudentID: mshv,
								HoHV: item["Họ HV"] || item["Họ"] || item["Họ và chữ lót"] || item["Họ và tên lót"] || "",
								TenHV: item["Tên HV"] || item["Tên"] || "",
								Email: item["Email"] || null,
								SoDienThoai: item["Số điện thoại"] || item["SĐT"] || item["Điện thoại"] || item["Số ĐT"] || null,
								GioiTinh: item["Giới tính"] || item["Phái"] || null,
								NoiSinh: item["Nơi sinh"] || null,
								DanToc: item["Dân tộc"] || null,
								QuocTich: item["Quốc tịch"] || null,
								CCCD: item["Số CCCD"] || item["CCCD"] || item["Số CMND / CCCD"] || item["CMND"] || null,
								NgayCap_CCCD: item["Ngày cấp CCCD"] || item["Ngày cấp"] || item["NgayCap_CCCD"] || null,
								NgheNghiep: item["Nghề nghiệp"] || item["Nghề nghiệp / Chức vụ"] || item["Chức vụ"] || item["NgheNghiep"] || null,
								NoiLamViec: item["Nơi làm việc"] || item["Nơi làm việc / Cơ quan"] || item["Cơ quan"] || item["NoiLamViec"] || null,
								DiaChi: item["Địa chỉ liên hệ"] || item["Địa chỉ thường trú"] || item["Địa chỉ"] || item["DiaChi"] || null,
								Truong_DaiHoc: item["Trường Đại học"] || item["Trường ĐH"] || item["Trường tốt nghiệp ĐH"] || null,
								Nganh_DaiHoc: item["Ngành Đại học"] || item["Ngành ĐH"] || item["Ngành tốt nghiệp ĐH"] || null,
								HeDaoTao_DaiHoc: item["Hệ đào tạo ĐH"] || item["Hệ ĐH"] || item["Hệ đào tạo đại học"] || item["HeDaoTao_DaiHoc"] || null,
								ThoiGianTotNghiep_DaiHoc: item["Năm tốt nghiệp đại học"] || item["Năm tốt nghiệp ĐH"] || item["Thời gian tốt nghiệp đại học"] || null,
								Truong_ThacSi: item["Trường Thạc sĩ"] || item["Trường ThS"] || item["Trường học thạc sĩ"] || null,
								Nganh_ThacSi: item["Ngành Thạc sĩ"] || item["Ngành ThS"] || item["Ngành học thạc sĩ"] || null,
								HeDaoTao_ThacSi: item["Hệ đào tạo ThS"] || item["Hệ ThS"] || item["Hệ đào tạo thạc sĩ"] || item["HeDaoTao_ThacSi"] || null,
								ThoiGianTotNghiep_ThacSi: item["Năm tốt nghiệp thạc sĩ"] || item["Năm tốt nghiệp ThS"] || item["Thời gian tốt nghiệp thạc sĩ"] || null,
								XepLoai: item["Xếp loại"] || item["Xếp loại tốt nghiệp"] || null,
								Loai_NgoaiNgu_DauVao: item["Loại ngoại ngữ đầu vào"] || item["Loại ngoại ngữ"] || item["Loại NN"] || null,
								NgoaiNgu_DauVao: item["Ngoại ngữ đầu vào"] || item["Ngoại ngữ"] || item["Chứng chỉ ngoại ngữ"] || null,
								BoSungKienThuc: item["Bổ sung kiến thức"] || "Không",
								CongBoKhoaHoc: item["Công bố khoa học"] || "Không",
							}
						})

						const invalidCount = this.DsHocVien.filter((x) => !this.isValidStudentID(x.StudentID)).length
						if (invalidCount > 0) {
							Vue.$toast.error(`Có ${invalidCount} học viên có mã không đúng chuẩn 9 số (ví dụ HS1, HS2...). Không thể cập nhật các dòng này!`, { position: "top" })
						} else {
							Vue.$toast.success(`Đã nạp thành công ${this.DsHocVien.length} học viên từ file Excel`, { position: "top" })
						}
					} catch (error) {
						Vue.$toast.error(`Lỗi đọc file excel: ${error}`, { position: "top" })
					}
				}
				reader.readAsArrayBuffer(file)
			},
			async onSave() {
				if (this.invalidStudentIdCount > 0) {
					Vue.$toast.error(`Có ${this.invalidStudentIdCount} dòng mã học viên không đúng chuẩn 9 số (ví dụ HS1, HS2...). Vui lòng kiểm tra lại!`, { position: "top" })
					return
				}

				const arr = this.DsHocVien.map((item) => ({
					StudentID: item.StudentID ? item.StudentID.toString().trim() : null,
					GioiTinh: item.GioiTinh ? item.GioiTinh.trim() : null,
					DanToc: item.DanToc ? item.DanToc.trim() : null,
					Email: item.Email ? item.Email.trim() : null,
					NoiSinh: item.NoiSinh ? item.NoiSinh.trim() : null,
					QuocTich: item.QuocTich ? item.QuocTich.trim() : null,
					CCCD: item.CCCD ? item.CCCD.trim() : null,
					NgayCap_CCCD: item.NgayCap_CCCD ? item.NgayCap_CCCD.trim() : null,
					SoDienThoai: item.SoDienThoai ? item.SoDienThoai.trim() : null,
					DiaChi: item.DiaChi ? item.DiaChi.trim() : null,
					NoiLamViec: item.NoiLamViec ? item.NoiLamViec.trim() : null,
					NgheNghiep: item.NgheNghiep ? item.NgheNghiep.trim() : null,
					Truong_DaiHoc: item.Truong_DaiHoc ? item.Truong_DaiHoc.trim() : null,
					Nganh_DaiHoc: item.Nganh_DaiHoc ? item.Nganh_DaiHoc.trim() : null,
					HeDaoTao_DaiHoc: item.HeDaoTao_DaiHoc ? item.HeDaoTao_DaiHoc.trim() : null,
					ThoiGianTotNghiep_DaiHoc: item.ThoiGianTotNghiep_DaiHoc,
					Truong_ThacSi: item.Truong_ThacSi ? item.Truong_ThacSi.trim() : null,
					Nganh_ThacSi: item.Nganh_ThacSi ? item.Nganh_ThacSi.trim() : null,
					HeDaoTao_ThacSi: item.HeDaoTao_ThacSi ? item.HeDaoTao_ThacSi.trim() : null,
					ThoiGianTotNghiep_ThacSi: item.ThoiGianTotNghiep_ThacSi,
					XepLoai: item.XepLoai ? item.XepLoai.trim() : null,
					NgoaiNgu_DauVao: item.NgoaiNgu_DauVao ? item.NgoaiNgu_DauVao.trim() : null,
					Loai_NgoaiNgu_DauVao: item.Loai_NgoaiNgu_DauVao,
					BoSungKienThuc: item.BoSungKienThuc,
					CongBoKhoaHoc: item.CongBoKhoaHoc,
				}))

				if (arr.length === 0) {
					Vue.$toast.warning("Chưa có dữ liệu để lưu", { position: "top" })
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
				} finally {
					this.saving = false
				}
			},
			close() {
				this.DsHocVien = []
				this.fileUpload = null
				this.$emit("input", false)
			},
		},
	}
</script>