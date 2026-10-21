<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="pa-3">
			<v-row dense align="center">
				<v-col cols="12" sm="3" md="2">
					<v-autocomplete v-model="nienKhoaModel" :items="dsNienKhoa" item-text="TenNienKhoa"
						item-value="NienKhoa" outlined dense hide-details placeholder="Chọn niên khóa"
						label="Niên khóa" />
				</v-col>

				<v-col cols="12" sm="3" md="3">
					<v-autocomplete v-model="majorModel" :items="heArr" item-text="TenNganh" item-value="NganhID"
						outlined dense hide-details label="Lọc theo ngành" placeholder="Chọn ngành" clearable />
				</v-col>

				<v-col cols="12" sm="6" md="4" class="d-flex align-center">
					<v-btn color="primary" class="rounded-xs mr-2" depressed @click="$emit('on-open-import-new')">
						<v-icon left small>mdi-account-plus-outline</v-icon>
						Import mới
					</v-btn>

					<v-menu offset-y left>
						<template v-slot:activator="{ on, attrs }">
							<v-btn color="success" class="rounded-xs" depressed v-bind="attrs" v-on="on">
								<v-icon left small>mdi-cog-outline</v-icon>
								Tùy chọn
								<v-icon right small>mdi-chevron-down</v-icon>
							</v-btn>
						</template>
						<v-list dense class="py-1">
							<v-list-item @click="$emit('on-open-import')">
								<v-list-item-icon class="mr-3">
									<v-icon small color="success">mdi-file-excel-box</v-icon>
								</v-list-item-icon>
								<v-list-item-content>
									<v-list-item-title>Cập nhật thông tin NCS bằng Excel</v-list-item-title>
								</v-list-item-content>
							</v-list-item>
							<v-list-item @click="$emit('on-open-sync-gvhd')">
								<v-list-item-icon class="mr-3">
									<v-icon small color="primary">mdi-sync</v-icon>
								</v-list-item-icon>
								<v-list-item-content>
									<v-list-item-title>Đồng bộ phân công GVHD & Đề tài</v-list-item-title>
								</v-list-item-content>
							</v-list-item>
							<v-list-item @click="$emit('on-open-update-student-id')">
								<v-list-item-icon class="mr-3">
									<v-icon small color="indigo">mdi-card-account-details-outline</v-icon>
								</v-list-item-icon>
								<v-list-item-content>
									<v-list-item-title>Cập nhật MSHV theo Mã hồ sơ</v-list-item-title>
								</v-list-item-content>
							</v-list-item>
							<v-divider v-if="false" class="my-1" />
							<v-list-item v-if="false" @click="onExportThongTinUngVien" :disabled="isLoadingExportUngVien">
								<v-list-item-icon class="mr-3">
									<v-icon small color="teal">mdi-file-export-outline</v-icon>
								</v-list-item-icon>
								<v-list-item-content>
									<v-list-item-title>Xuất mẫu 1. Thông tin ứng viên (33 cột)</v-list-item-title>
								</v-list-item-content>
							</v-list-item>
						</v-list>
					</v-menu>
				</v-col>

				<v-col cols="12" sm="12" md="3" class="d-flex align-center">
					<v-btn icon color="primary" class="mr-2" :loading="isLoadingExport" @click="onPrintExcel"
						title="Xuất file Excel">
						<v-icon>mdi-microsoft-excel</v-icon>
					</v-btn>
					<v-text-field v-model="searchText" class="c-underline-search flex-grow-1"
						label="Tìm kiếm nhanh học viên..." dense hide-details single-line clearable
						prepend-inner-icon="mdi-magnify" />
				</v-col>
			</v-row>
		</v-card-title>

		<v-divider />

		<v-data-table :headers="tableHeaders" :items="items" :search="searchText" :custom-filter="customFilter" :loading="!isTableReady"
			:items-per-page="50" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
			height="calc(100vh - 193px)" fixed-header dense>
			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu học viên" />
			</template>

			<template v-slot:no-results>
				<c-empty-state text="Không tìm thấy kết quả phù hợp" />
			</template>

			<template v-slot:item.stt="{ item, index }">
				<span>{{ item.stt || (index + 1) }}</span>
			</template>

			<template v-slot:item.StudentID="{ item }">
				<div class="py-1">
					<span class="primary--text font-weight-bold">{{ item.HoTen || ((item.HoSV || '') + ' ' + (item.TenSV
						|| '')) }}</span>
					<br />
					<span class="font-weight-medium">{{ item.StudentID }}</span>
					<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
					<span v-if="item.MaHoSo && item.MaHoSo !== item.StudentID" class="blue-grey--text text--lighten-1 ml-1 text-caption font-italic">
						(HS: {{ item.MaHoSo }})
					</span>
				</div>
			</template>

			<template v-slot:item.NgaySinh="{ item }">
				<span>{{ formatDisplayDate(item.NgaySinh) }}</span>
			</template>

			<template v-slot:item.updTask="{ item }">
				<v-btn text small color="indigo" class="rounded-xs" :disabled="!item.isExist && !item.isSelect"
					@click="$emit('on-select-student', item)">
					<v-icon left small>mdi-account-edit-outline</v-icon>
					Cập nhật
				</v-btn>
			</template>

			<template v-slot:item.status="{ item }">
				<v-btn v-if="!item.isExist && !item.isSelect" text small color="primary" class="rounded-xs"
					@click="$emit('on-save-student', item)">
					<v-icon left small>mdi-account-plus-outline</v-icon>
					Thêm học viên
				</v-btn>
				<v-btn v-else text small color="error" class="rounded-xs" :disabled="!item.isCanDelete"
					@click="$emit('on-delete-student', item)">
					<v-icon left small>mdi-delete-outline</v-icon>
					Xóa học viên
				</v-btn>
			</template>

			<template v-slot:item.resetProcess="{ item }">
				<div class="d-flex flex-column align-center py-1">
					<v-btn text small color="warning" class="rounded-xs" :disabled="!item.isExist && !item.isSelect"
						@click="$emit('on-reset-process', item)">
						<v-icon left small>mdi-refresh</v-icon>
						Đăng ký mới
					</v-btn>
					<v-btn v-if="item.HasResetProcess === 1" text x-small color="teal" class="rounded-xs mt-1"
						:disabled="!item.isExist && !item.isSelect" @click="$emit('on-view-old-process', item)">
						<v-icon left small>mdi-history</v-icon>
						Dữ liệu cũ
					</v-btn>
				</div>
			</template>

			<template v-slot:item.IsXuLyHocVu="{ item }">
				<v-btn text small :color="item.IsXuLyHocVu ? 'orange darken-3' : 'purple darken-4'"
					class="rounded-xs font-weight-medium"
					:disabled="item.IsXuLyHocVu || (!item.isExist && !item.isSelect)"
					@click="$emit('on-xuly-hocvu', item)">
					<v-icon left small>{{ item.IsXuLyHocVu ? 'mdi-check-circle-outline' : 'mdi-alert-circle-outline' }}
					</v-icon>
					{{ item.IsXuLyHocVu ? 'Đã xử lý học vụ' : 'Xử lý học vụ' }}
				</v-btn>
			</template>
		</v-data-table>
	</v-card>
</template>

<script>
	export default {
		name: "uc-main-view",
		props: {
			isTableReady: {
				type: Boolean,
				default: false,
			},
			items: {
				type: Array,
				default: () => [],
			},
			dsNienKhoa: {
				type: Array,
				default: () => [],
			},
			heArr: {
				type: Array,
				default: () => [],
			},
			selectedNienKhoa: {
				type: [String, Number],
				default: null,
			},
			selectedMajor: {
				type: [String, Number],
				default: "0",
			},
		},
		emits: [
			"update:selected-nien-khoa",
			"update:selected-major",
			"on-save-all",
			"on-save-student",
			"on-delete-student",
			"on-xuly-hocvu",
			"on-select-student",
			"on-reset-process",
			"on-view-old-process",
			"on-open-import",
			"on-open-import-new",
			"on-open-sync-gvhd",
			"on-open-update-student-id",
		],
		data() {
			return {
				searchText: "",
				isLoadingExport: false,
				isLoadingExportUngVien: false,
				tableHeaders: [
					{ text: "STT", value: "stt", align: "center", width: 60, sortable: false },
					{ text: "Học viên", value: "StudentID", width: 220 },
					{ text: "Ngày sinh", value: "NgaySinh", width: 110, align: "center" },
					{ text: "Niên khóa", value: "NienKhoa", width: 100, align: "center" },
					{ text: "Tên ngành", value: "TenNganh", width: 200 },
					{ text: "Cập nhật", value: "updTask", align: "center", sortable: false, width: 150 },
					{ text: "Trạng thái", value: "status", align: "center", sortable: false, width: 160 },
					{ text: "Đăng ký", value: "resetProcess", align: "center", sortable: false, width: 170 },
					{ text: "Học vụ", value: "IsXuLyHocVu", align: "center", sortable: false, width: 170 },
				],
			}
		},
		computed: {
			nienKhoaModel: {
				get() {
					return this.selectedNienKhoa
				},
				set(val) {
					this.$emit("update:selected-nien-khoa", val)
				},
			},
			majorModel: {
				get() {
					return this.selectedMajor
				},
				set(val) {
					this.$emit("update:selected-major", val)
				},
			},
		},
		methods: {
			normalizeSearch(str) {
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

			customFilter(value, search, item) {
				if (!search) return true
				const s = this.normalizeSearch(search)
				if (!s) return true

				const hoTen = item.HoTen || `${item.HoSV || ""} ${item.TenSV || ""}`.trim()
				const searchableStr = [
					item.StudentID,
					item.MaHoSo,
					hoTen,
					item.HoSV,
					item.TenSV,
					item.LopID,
					item.TenNganh,
					item.NienKhoa,
					item.Email,
					item.SoDienThoai,
					item.NoiSinh,
					item.CCCD,
					item.Truong_ThacSi,
					item.Nganh_ThacSi,
				]
					.filter(Boolean)
					.join(" ")

				return this.normalizeSearch(searchableStr).includes(s)
			},

			formatDisplayDate(val) {
				if (!val) return ""
				if (typeof moment !== "undefined" && moment(val).isValid()) {
					return moment(val).format("DD/MM/YYYY")
				}
				if (val instanceof Date) {
					return val.toLocaleDateString("vi-VN")
				}
				return val
			},

			async onPrintExcel() {
				if (!this.items || this.items.length === 0) {
					Vue.$toast.warning("Không có dữ liệu học viên để xuất Excel", { position: "top" })
					return
				}

				this.isLoadingExport = true
				try {
					const dataExport = this.items.map((item, index) => ({
						"STT": item.stt || (index + 1),
						"Mã học viên": item.StudentID || "",
						"Mã hồ sơ": item.MaHoSo || item.StudentID || "",
						"Họ tên": item.HoTen || `${item.HoSV || ""} ${item.TenSV || ""}`.trim(),
						"Lớp": item.LopID || "",
						"Ngày sinh": this.formatDisplayDate(item.NgaySinh),
						"Niên khóa": item.NienKhoa || "",
						"Ngành": item.TenNganh || "",
						"Email": item.Email || "",
						"Số điện thoại": item.SoDienThoai || "",
						"Nơi sinh": item.NoiSinh || "",
						"Dân tộc": item.DanToc || "",
						"Quốc tịch": item.QuocTich || "",
						"Số CCCD": item.CCCD || "",
						"Trường ĐH": item.Truong_DaiHoc || "",
						"Ngành ĐH": item.Nganh_DaiHoc || "",
						"Năm tốt nghiệp ĐH": item.ThoiGianTotNghiep_DaiHoc || "",
						"Hệ đào tạo ĐH": item.HeDaoTao_DaiHoc || "",
						"Trường ThS": item.Truong_ThacSi || "",
						"Ngành ThS": item.Nganh_ThacSi || "",
						"Hệ đào tạo ThS": item.HeDaoTao_ThacSi || "",
						"Năm tốt nghiệp ThS": item.ThoiGianTotNghiep_ThacSi || "",
						"Nơi làm việc": item.NoiLamViec || "",
						"Nghề nghiệp": item.NgheNghiep || "",
						"Địa chỉ": item.DiaChi || "",
						"Xếp loại": item.XepLoai || "",
						"Loại NN đầu vào": item.Loai_NgoaiNgu_DauVao || "",
						"Ngoại ngữ đầu vào": item.NgoaiNgu_DauVao || "",
						"Bổ sung kiến thức": item.BoSungKienThuc == 1 || item.BoSungKienThuc === "1" ? "Có" : "Không",
						"Công bố khoa học": item.CongBoKhoaHoc == 1 || item.CongBoKhoaHoc === "1" ? "Có" : "Không",
						"Trạng thái": item.isExist || item.isSelect ? "Đã thêm" : "Chưa thêm",
						"Xử lý học vụ": item.IsXuLyHocVu ? "Đã xử lý học vụ" : "Bình thường",
					}))

					const nienKhoaStr = this.selectedNienKhoa && this.selectedNienKhoa !== "0" ? `_NK_${this.selectedNienKhoa}` : ""
					jsonToExcel({
						data: dataExport,
						filename: `Danh_sach_thong_tin_hoc_vien${nienKhoaStr}.xlsx`,
						worksheet: "Sheet1",
					})
				} catch (error) {
					console.error("Lỗi xuất Excel:", error)
					Vue.$toast.error("Lỗi xuất file Excel", { position: "top" })
				} finally {
					this.isLoadingExport = false
				}
			},

			async onExportThongTinUngVien() {
				this.isLoadingExportUngVien = true
				try {
					const res = await ajaxCALLPromise("/Student_Export_ThongTinUngVien_TS", {
						NienKhoa: this.selectedNienKhoa || "0",
					})

					if (!res || res.length === 0) {
						Vue.$toast.warning("Không có dữ liệu ứng viên để xuất Excel", { position: "top" })
						return
					}

					const dataExport = res.map((item, index) => ({
						"Stt": item.Stt || (index + 1),
						"Mã HS": item.MaHoSo || item.StudentID || "",
						"Họ": item.Ho || "",
						"Tên": item.Ten || "",
						"Phái": item.Phai || "",
						"Ngày sinh": item.NgaySinh || "",
						"Nơi sinh": item.NoiSinh || "",
						"Dân tộc": item.DanToc || "",
						"Quốc tịch": item.QuocTich || "",
						"Chuyên ngành dự tuyển": item.ChuyenNganh || "",
						"Tên trường đại học ": item.Truong_DaiHoc || "",
						"Ngành học đại học ": item.Nganh_DaiHoc || "",
						"Năm tốt nghiệp ": item.NamTotNghiep_DH || "",
						"Loại tốt nghiệp ": item.LoaiTotNghiep_DH || "",
						"Hệ đào tạo": item.HeDaoTao_DH || "",
						"Tên trường thạc sĩ": item.Truong_ThacSi || "",
						"Ngành học thạc sĩ ": item.Nganh_ThacSi || "",
						"Hệ đào tạo ": item.HeDaoTao_ThS || "",
						"Năm tốt nghiệp  ": item.NamTotNghiep_ThS || "",
						"Nghề nghiệp": item.NgheNghiep || "",
						"Nơi làm việc": item.NoiLamViec || "",
						"Địa chỉ": item.DiaChi || "",
						"Email": item.Email || "",
						"Điện thoại": item.SoDienThoai || "",
						"Căn cước công dân": item.CCCD || "",
						"Giấy khám sức khoẻ": item.GiayKhamSucKhoe || "",
						"Người giới thiệu ": item.NguoiGioiThieu || "",
						"Đề xuất người hướng dẫn ": item.DeXuatGVHD || "",
						"Tên bài luận": item.TenBaiLuan || "",
						"Bài báo khoa học 1": item.BaiBaoKhoaHoc_1 || "",
						"Bài báo khoa học 2": item.BaiBaoKhoaHoc_2 || "",
						"Trình độ ngoại ngữ": item.NgoaiNgu_DauVao || "",
						"Bổ sung kiến thức": item.BoSungKienThuc || "",
					}))

					const nienKhoaStr = this.selectedNienKhoa && this.selectedNienKhoa !== "0" ? `_NK_${this.selectedNienKhoa}` : ""
					jsonToExcel({
						data: dataExport,
						filename: `1. Thong tin ung vien${nienKhoaStr}.xlsx`,
						worksheet: "Sheet1",
					})
					Vue.$toast.success(`Đã xuất thành công ${dataExport.length} ứng viên theo mẫu chuẩn 33 cột`, { position: "top" })
				} catch (error) {
					console.error("Lỗi xuất Excel thông tin ứng viên:", error)
					Vue.$toast.error("Lỗi xuất file Excel Thông tin ứng viên", { position: "top" })
				} finally {
					this.isLoadingExportUngVien = false
				}
			},
		},
	}
</script>