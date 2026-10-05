<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card>
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="title primary--text text-left">Import danh sách học viên mới (Tiến sĩ)</div>
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
							label="Chọn file Excel học viên"
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

					<v-col cols="12" sm="4" md="3">
						<v-autocomplete
							v-model="defaultNienKhoa"
							:items="dsNienKhoaValid"
							item-text="TenNienKhoa"
							item-value="NienKhoa"
							dense
							outlined
							hide-details
							label="Niên khóa mặc định (nếu dòng trống)"
							placeholder="Chọn niên khóa"
							@change="onDefaultNienKhoaChange"
						/>
					</v-col>

					<v-col cols="12" sm="12" md="3" class="d-flex justify-end align-center">
						<v-btn color="primary" outlined class="rounded-xs mr-2" @click="addNewRow">
							<v-icon left small>mdi-plus</v-icon>
							Thêm dòng
						</v-btn>
						<v-btn color="error" outlined class="rounded-xs" :disabled="DsHocVien.length === 0" @click="clearAll">
							<v-icon left small>mdi-trash-can-outline</v-icon>
							Xóa bảng
						</v-btn>
					</v-col>
				</v-row>

				<!-- Cảnh báo nếu có dòng chưa xác định được Ngành -->
				<v-alert v-if="unmappedNganhCount > 0" dense colored-border type="error" elevation="1" class="mb-3 rounded-xs">
					<div class="d-flex align-center justify-space-between flex-wrap">
						<div>
							<strong>Chưa thể import:</strong> Có <strong>{{ unmappedNganhCount }}</strong> học viên chưa khớp được <strong>Ngành học</strong> trong hệ thống.
							<div class="text-caption mt-1">Vui lòng chọn trực tiếp Ngành học tương ứng tại cột <strong>"Ngành (*)"</strong> bên dưới để tiếp tục.</div>
						</div>
					</div>
				</v-alert>

				<!-- Cảnh báo nếu có mã học viên không đúng chuẩn 9 chữ số -->
				<v-alert v-if="invalidStudentIdCount > 0" dense colored-border type="error" elevation="1" class="mb-3 rounded-xs">
					<div class="d-flex align-center justify-space-between flex-wrap">
						<div>
							<strong>Mã học viên chưa hợp lệ:</strong> Có <strong>{{ invalidStudentIdCount }}</strong> dòng mã số học viên không đúng chuẩn (bắt buộc đúng 9 chữ số, không dùng mã tạm HS1, HS2...).
							<div class="text-caption mt-1">Vui lòng chỉnh sửa trực tiếp tại cột <strong>"Mã số HV (*)"</strong> trước khi lưu.</div>
						</div>
					</div>
				</v-alert>

				<!-- Thông báo tổng số học viên -->
				<v-alert v-else-if="DsHocVien.length > 0 && unmappedNganhCount === 0" dense text type="info" class="mb-2 rounded-xs">
					Tổng số học viên: <strong>{{ DsHocVien.length }}</strong> dòng. Toàn bộ mã học viên và ngành học đã hợp lệ. Vui lòng kiểm tra lại thông tin trước khi bấm lưu.
				</v-alert>

				<v-data-table
					:headers="tableHeaders"
					:items="DsHocVien"
					:items-per-page="-1"
					hide-default-footer
					dense
					fixed-header
					height="calc(100vh - 270px)"
					class="elevation-1"
				>
					<template v-slot:no-data>
						<c-empty-state
							icon="mdi-file-excel-outline"
							text="Chưa có dữ liệu. Vui lòng chọn file Excel hoặc bấm Thêm dòng"
						/>
					</template>

					<template v-slot:item.stt="{ index }">
						<span>{{ index + 1 }}</span>
					</template>

					<template v-slot:item.StudentID="{ item }">
						<div class="py-1">
							<v-text-field
								v-model="item.StudentID"
								placeholder="9 chữ số (*)"
								dense
								hide-details
								:error="!isValidStudentID(item.StudentID)"
							/>
							<div v-if="!isValidStudentID(item.StudentID)" class="error--text text-caption font-weight-medium" style="font-size: 11px !important; line-height: 1.2;">
								{{ !item.StudentID ? 'Bắt buộc' : 'Phải đúng 9 số' }}
							</div>
						</div>
					</template>

					<template v-slot:item.MaHoSo="{ item }">
						<v-text-field
							v-model="item.MaHoSo"
							placeholder="Mã hồ sơ"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.HoSV="{ item }">
						<v-text-field
							v-model="item.HoSV"
							placeholder="Họ và chữ lót"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.TenSV="{ item }">
						<v-text-field
							v-model="item.TenSV"
							placeholder="Tên (*)"
							dense
							hide-details
							:error="!item.TenSV"
						/>
					</template>

					<template v-slot:item.LopID="{ item }">
						<v-text-field
							v-model="item.LopID"
							placeholder="Mã lớp"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.NganhID="{ item }">
						<div>
							<v-autocomplete
								v-model="item.NganhID"
								:items="heArrValid"
								item-text="TenNganh"
								item-value="NganhID"
								placeholder="Chọn ngành (*)"
								dense
								hide-details
								:error="!item.NganhID"
							/>
							<div v-if="!item.NganhID && item.rawNganh" class="red--text text-caption font-italic mt-1">
								(File ghi: "{{ item.rawNganh }}")
							</div>
						</div>
					</template>

					<template v-slot:item.NienKhoa="{ item }">
						<v-text-field
							v-model="item.NienKhoa"
							placeholder="Niên khóa (*)"
							dense
							hide-details
							:error="!item.NienKhoa"
						/>
					</template>

					<template v-slot:item.NgaySinh="{ item }">
						<v-text-field
							v-model="item.NgaySinh"
							placeholder="DD/MM/YYYY"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.NoiSinh="{ item }">
						<v-text-field
							v-model="item.NoiSinh"
							placeholder="Nơi sinh"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.GioiTinh="{ item }">
						<v-select
							v-model="item.GioiTinh"
							:items="['Nam', 'Nữ']"
							placeholder="Giới tính"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.SoDienThoai="{ item }">
						<v-text-field
							v-model="item.SoDienThoai"
							placeholder="Số ĐT"
							dense
							hide-details
						/>
					</template>

					<template v-slot:item.Email="{ item }">
						<v-text-field
							v-model="item.Email"
							placeholder="Email"
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
		name: "uc-modal-import-new-student",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			dsNienKhoa: {
				type: Array,
				default: () => [],
			},
			heArr: {
				type: Array,
				default: () => [],
			},
			currentNienKhoa: {
				type: [String, Number],
				default: null,
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				fileUpload: null,
				DsHocVien: [],
				defaultNienKhoa: null,
				saving: false,
				isDownloadingTemplate: false,
				tableHeaders: [
					{ text: "STT", value: "stt", align: "center", width: 50, sortable: false },
					{ text: "Mã số HV (*)", value: "StudentID", width: 140, sortable: false },
					{ text: "Mã hồ sơ", value: "MaHoSo", width: 120, sortable: false },
					{ text: "Họ đệm", value: "HoSV", width: 150, sortable: false },
					{ text: "Tên (*)", value: "TenSV", width: 110, sortable: false },
					{ text: "Lớp", value: "LopID", width: 110, sortable: false },
					{ text: "Ngành (*)", value: "NganhID", width: 240, sortable: false },
					{ text: "Niên khóa (*)", value: "NienKhoa", width: 120, sortable: false },
					{ text: "Ngày sinh", value: "NgaySinh", width: 120, sortable: false },
					{ text: "Nơi sinh", value: "NoiSinh", width: 130, sortable: false },
					{ text: "Giới tính", value: "GioiTinh", width: 100, sortable: false },
					{ text: "Số ĐT", value: "SoDienThoai", width: 120, sortable: false },
					{ text: "Email", value: "Email", width: 170, sortable: false },
					{ text: "", value: "action", align: "center", width: 50, sortable: false },
				],
			}
		},
		computed: {
			dsNienKhoaValid() {
				return (this.dsNienKhoa || []).filter((item) => item.NienKhoa && item.NienKhoa !== "0")
			},
			heArrValid() {
				return (this.heArr || []).filter((item) => item.NganhID && item.NganhID !== "0")
			},
			unmappedNganhCount() {
				return (this.DsHocVien || []).filter((x) => !x.NganhID).length
			},
			invalidStudentIdCount() {
				return (this.DsHocVien || []).filter((x) => !this.isValidStudentID(x.StudentID)).length
			},
			hasMissingRequired() {
				return (this.DsHocVien || []).some((x) => !this.isValidStudentID(x.StudentID) || !x.TenSV || !x.NienKhoa)
			},
			isSaveDisabled() {
				return this.DsHocVien.length === 0 || this.unmappedNganhCount > 0 || this.invalidStudentIdCount > 0 || this.hasMissingRequired || this.saving
			},
			saveButtonText() {
				if (this.unmappedNganhCount > 0) {
					return `Chưa chọn ngành (${this.unmappedNganhCount} dòng)`
				}
				if (this.invalidStudentIdCount > 0) {
					return `Mã HV chưa chuẩn 9 số (${this.invalidStudentIdCount} dòng)`
				}
				return `Lưu danh sách học viên (${this.DsHocVien.length})`
			},
		},
		watch: {
			value(val) {
				if (val) {
					if (this.currentNienKhoa && this.currentNienKhoa !== "0") {
						this.defaultNienKhoa = this.currentNienKhoa
					} else if (this.dsNienKhoaValid.length > 0) {
						this.defaultNienKhoa = this.dsNienKhoaValid[0].NienKhoa
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
							"Mã học viên": "923000215",
							"Mã hồ sơ": "HS01",
							"Họ và tên": "Nguyễn Đình Nghĩa",
							"Lớp": "23NQ912",
							"Tên ngành": "Quản trị kinh doanh",
							"Niên khóa": this.defaultNienKhoa || "2023-02",
							"Ngày sinh": "15/08/1988",
							"Nơi sinh": "Đồng Nai",
							"Giới tính": "Nam",
							"Số điện thoại": "0918889999",
							"Email": "nghiand_ts@lhu.edu.vn",
						},
						{
							"STT": 2,
							"Mã học viên": "923000216",
							"Mã hồ sơ": "HS02",
							"Họ và tên": "Đào Quốc Phương",
							"Lớp": "23NC912",
							"Tên ngành": "Khoa học máy tính",
							"Niên khóa": this.defaultNienKhoa || "2023-02",
							"Ngày sinh": "22/11/1990",
							"Nơi sinh": "Bình Dương",
							"Giới tính": "Nam",
							"Số điện thoại": "0909123456",
							"Email": "phuongdq_ts@lhu.edu.vn",
						},
					]

					jsonToExcel({
						data: sampleData,
						filename: "Mau_Import_Hoc_Vien_Tien_Si.xlsx",
						worksheet: "DanhSachHocVien",
					})
				} catch (error) {
					console.error("Lỗi xuất file mẫu:", error)
					Vue.$toast.error("Lỗi tạo file mẫu Excel", { position: "top" })
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

			splitFullName(fullName) {
				if (!fullName || typeof fullName !== "string") return { ho: "", ten: "" }
				const trimmed = fullName.trim()
				const lastSpaceIndex = trimmed.lastIndexOf(" ")
				if (lastSpaceIndex === -1) {
					return { ho: "", ten: trimmed }
				}
				return {
					ho: trimmed.substring(0, lastSpaceIndex).trim(),
					ten: trimmed.substring(lastSpaceIndex + 1).trim(),
				}
			},

			normalizeString(str) {
				if (!str) return ""
				return str
					.toString()
					.normalize("NFD")
					.replace(/[\u0300-\u036f]/g, "")
					.replace(/đ/g, "d")
					.replace(/Đ/g, "d")
					.toLowerCase()
					.trim()
			},

			cleanNganhName(raw) {
				if (!raw) return ""
				let norm = this.normalizeString(raw)
				// Loại bỏ các từ thừa phổ biến
				const prefixes = ["tien si", "tien sy", "thac si", "thac sy", "chuyen nganh", "nganh", "khoa"]
				prefixes.forEach((p) => {
					norm = norm.replace(new RegExp(`^${p}\\s*`, "g"), "").replace(new RegExp(`\\s*${p}$`, "g"), "")
				})
				return norm.trim()
			},

			resolveNganhID(rawNganh) {
				if (!rawNganh) {
					return this.defaultMajor || null
				}

				const rawStr = rawNganh.toString().trim()
				const rawNorm = this.cleanNganhName(rawStr)

				// 1. So khớp trực tiếp theo NganhID hoặc MaNganh
				const findDirect = this.heArrValid.find(
					(x) =>
						(x.NganhID && x.NganhID.toString().toLowerCase() === rawStr.toLowerCase()) ||
						(x.MaNganh && x.MaNganh.toString().toLowerCase() === rawStr.toLowerCase())
				)
				if (findDirect) return findDirect.NganhID

				// 2. So khớp theo Tên ngành (đã chuẩn hóa không dấu)
				const findExact = this.heArrValid.find((x) => {
					const normTen = this.cleanNganhName(x.TenNganh || "")
					const normOri = this.cleanNganhName(x.OriginalName || "")
					return normTen === rawNorm || normOri === rawNorm
				})
				if (findExact) return findExact.NganhID

				// 3. So khớp tương đối (includes)
				const findInclude = this.heArrValid.find((x) => {
					const normTen = this.cleanNganhName(x.TenNganh || "")
					const normOri = this.cleanNganhName(x.OriginalName || "")
					return (
						(normTen && (normTen.includes(rawNorm) || rawNorm.includes(normTen))) ||
						(normOri && (normOri.includes(rawNorm) || rawNorm.includes(normOri)))
					)
				})
				if (findInclude) return findInclude.NganhID

				// Nếu không tìm thấy ngành hợp lệ trong hệ thống -> Trả về null để yêu cầu user chọn
				return null
			},

			formatDateString(val) {
				if (!val) return ""
				if (typeof val === "string") {
					const trimmed = val.trim()
					if (typeof moment !== "undefined") {
						const m = moment(trimmed, ["DD/MM/YYYY", "D/M/YYYY", "DD-MM-YYYY", "YYYY-MM-DD", "YYYY/MM/DD"], true)
						if (m.isValid()) return m.format("DD/MM/YYYY")
					}
					return trimmed
				}
				if (val instanceof Date) {
					const d = String(val.getDate()).padStart(2, "0")
					const m = String(val.getMonth() + 1).padStart(2, "0")
					const y = val.getFullYear()
					return `${d}/${m}/${y}`
				}
				return String(val)
			},

			readExcel(file) {
				const reader = new FileReader()
				reader.onload = (e) => {
					try {
						const data = e.target.result
						const workbook = XLSX.read(data, { type: "array" })
						const firstSheet = workbook.SheetNames[0]
						const worksheet = workbook.Sheets[firstSheet]
						const json = XLSX.utils.sheet_to_json(worksheet)

						if (!json || json.length === 0) {
							Vue.$toast.warning("File Excel không có dữ liệu", { position: "top" })
							return
						}

						const mappedList = json.map((row) => {
							const mshv = this.normalizeStudentID(row["Mã học viên"] || row["Mã số học viên"] || row["MSHV"] || row["Mã SV"] || row["MSSV"] || row["StudentID"] || "")
							const maHoSo = (row["Mã hồ sơ"] || row["MaHoSo"] || row["Mã HS"] || "").toString().trim()
							const rawFullName = row["Họ và tên"] || row["Họ tên"] || row["HoTen"] || row["Họ và Tên"] || ""
							let ho = row["Họ"] || row["Họ đệm"] || row["HoSV"] || ""
							let ten = row["Tên"] || row["TenSV"] || ""

							if (rawFullName && (!ho || !ten)) {
								const splitRes = this.splitFullName(rawFullName)
								if (!ho) ho = splitRes.ho
								if (!ten) ten = splitRes.ten
							}

							const lop = row["Lớp"] || row["Mã lớp"] || row["LopID"] || ""
							const rawNganh = row["Tên ngành"] || row["Ngành"] || row["Ngành học"] || row["Mã ngành"] || row["Nganh"] || row["TenNganh"] || row["NganhID"] || ""
							const nganhID = this.resolveNganhID(rawNganh)

							const nienKhoa = row["Niên khóa"] || row["Khoá"] || row["Khóa"] || row["NienKhoa"] || this.defaultNienKhoa || ""
							const rawNgaySinh = row["Ngày sinh"] || row["NgaySinh"] || ""
							const ngaySinh = this.formatDateString(rawNgaySinh)

							const noiSinh = row["Nơi sinh"] || row["NoiSinh"] || ""
							const gioiTinh = row["Giới tính"] || row["GioiTinh"] || "Nam"
							const sdt = row["Số điện thoại"] || row["SĐT"] || row["SoDienThoai"] || row["Phone"] || ""
							const email = row["Email"] || ""

							return {
								StudentID: mshv,
								MaHoSo: maHoSo || mshv,
								HoSV: ho ? ho.toString().trim() : "",
								TenSV: ten ? ten.toString().trim() : "",
								LopID: lop ? lop.toString().trim() : "",
								rawNganh: rawNganh ? rawNganh.toString().trim() : "",
								NganhID: nganhID,
								NienKhoa: nienKhoa ? nienKhoa.toString().trim() : "",
								NgaySinh: ngaySinh,
								NoiSinh: noiSinh ? noiSinh.toString().trim() : "",
								GioiTinh: gioiTinh ? gioiTinh.toString().trim() : "Nam",
								SoDienThoai: sdt ? sdt.toString().trim() : "",
								Email: email ? email.toString().trim() : "",
							}
						}).filter((x) => x.StudentID || x.TenSV)

						this.DsHocVien = mappedList

						const invalidCount = mappedList.filter((x) => !this.isValidStudentID(x.StudentID)).length
						const unmapped = mappedList.filter((x) => !x.NganhID).length

						if (invalidCount > 0) {
							Vue.$toast.error(`Có ${invalidCount} học viên có mã không đúng chuẩn 9 số (ví dụ HS1, HS2...). Vui lòng sửa lại trên bảng!`, { position: "top" })
						} else if (unmapped > 0) {
							Vue.$toast.warning(`Đã đọc ${mappedList.length} dòng. Có ${unmapped} dòng chưa khớp được ngành, vui lòng chọn lại trên bảng!`, { position: "top" })
						} else {
							Vue.$toast.success(`Đã đọc và map ngành thành công cho toàn bộ ${mappedList.length} học viên`, { position: "top" })
						}
					} catch (error) {
						console.error("Lỗi đọc Excel:", error)
						Vue.$toast.error(`Lỗi đọc file Excel: ${error.message || error}`, { position: "top" })
					}
				}
				reader.readAsArrayBuffer(file)
			},

			addNewRow() {
				this.DsHocVien.push({
					StudentID: "",
					MaHoSo: "",
					HoSV: "",
					TenSV: "",
					LopID: "",
					rawNganh: "",
					NganhID: null,
					NienKhoa: this.defaultNienKhoa || "",
					NgaySinh: "",
					NoiSinh: "",
					GioiTinh: "Nam",
					SoDienThoai: "",
					Email: "",
				})
			},

			removeRow(index) {
				this.DsHocVien.splice(index, 1)
			},

			clearAll() {
				this.DsHocVien = []
				this.fileUpload = null
			},

			onDefaultNienKhoaChange(val) {
				if (val && this.DsHocVien.length > 0) {
					this.DsHocVien.forEach((item) => {
						if (!item.NienKhoa) {
							item.NienKhoa = val
						}
					})
				}
			},

			onDefaultMajorChange(val) {
				if (val && this.DsHocVien.length > 0) {
					this.DsHocVien.forEach((item) => {
						if (!item.NganhID) {
							item.NganhID = val
						}
					})
				}
			},

			async onSave() {
				if (!this.DsHocVien || this.DsHocVien.length === 0) {
					Vue.$toast.warning("Chưa có dữ liệu học viên để lưu", { position: "top" })
					return
				}

				if (this.unmappedNganhCount > 0) {
					Vue.$toast.error(`Có ${this.unmappedNganhCount} dòng chưa chọn/khớp được Ngành học. Vui lòng chọn ngành trước khi lưu!`, { position: "top" })
					return
				}

				if (this.invalidStudentIdCount > 0) {
					Vue.$toast.error(`Có ${this.invalidStudentIdCount} dòng mã học viên không hợp lệ (bắt buộc đúng chuẩn 9 số). Vui lòng kiểm tra lại!`, { position: "top" })
					return
				}

				// Validation chi tiết
				const invalidRows = []
				const validList = []

				this.DsHocVien.forEach((item, index) => {
					const rowNum = index + 1
					if (!item.StudentID || !this.isValidStudentID(item.StudentID)) {
						invalidRows.push(`Dòng ${rowNum}: Mã số học viên "${item.StudentID || ''}" không hợp lệ (phải gồm đúng 9 chữ số)`)
						return
					}
					if (!item.TenSV || !item.TenSV.trim()) {
						invalidRows.push(`Dòng ${rowNum}: Thiếu Tên học viên`)
						return
					}
					if (!item.NganhID) {
						invalidRows.push(`Dòng ${rowNum}: Thiếu Ngành học`)
						return
					}
					if (!item.NienKhoa || !item.NienKhoa.trim()) {
						invalidRows.push(`Dòng ${rowNum}: Thiếu Niên khóa`)
						return
					}

					const selectedNganh = this.heArrValid.find((x) => x.NganhID == item.NganhID)
					const tenNganh = selectedNganh ? selectedNganh.OriginalName || selectedNganh.TenNganh : ""
					const heDaoTao = selectedNganh ? selectedNganh.HeDaoTao || "Phd" : "Phd"
					const heDaoTaoID = selectedNganh ? selectedNganh.HeDaoTaoID || 9 : 9
					const khoaID = selectedNganh ? selectedNganh.KhoaID || "PSD" : "PSD"

					validList.push({
						StudentID: item.StudentID.trim(),
						MaHoSo: item.MaHoSo ? item.MaHoSo.trim() : item.StudentID.trim(),
						HoSV: item.HoSV ? item.HoSV.trim() : "",
						TenSV: item.TenSV.trim(),
						LopID: item.LopID ? item.LopID.trim() : "",
						KhoaID: khoaID,
						NganhID: String(item.NganhID),
						TenNganh: tenNganh,
						HeDaoTaoID: heDaoTaoID,
						HeDaoTao: heDaoTao,
						NienKhoa: item.NienKhoa.trim(),
						NgaySinh: item.NgaySinh ? item.NgaySinh.trim() : "",
						NoiSinh: item.NoiSinh ? item.NoiSinh.trim() : "",
						GioiTinh: item.GioiTinh ? item.GioiTinh.trim() : "Nam",
						SoDienThoai: item.SoDienThoai ? item.SoDienThoai.trim() : "",
						Email: item.Email ? item.Email.trim() : "",
					})
				})

				if (invalidRows.length > 0) {
					const firstFew = invalidRows.slice(0, 3).join("; ")
					Vue.$toast.error(`Có ${invalidRows.length} dòng không hợp lệ: ${firstFew}`, { position: "top" })
					return
				}

				this.saving = true
				try {
					await ajaxCALLPromise("/Student_INS_obj", {
						StudentObjArr: JSON.stringify(validList),
						Process_Action: 4,
					})

					Vue.$toast.success(`Đã lưu thành công ${validList.length} học viên`, { position: "top" })
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