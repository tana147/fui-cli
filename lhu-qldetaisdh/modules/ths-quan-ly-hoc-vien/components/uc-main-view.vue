<template>
	<div>
		<!-- Hàng bộ lọc và thao tác -->
		<v-row dense align="center" class="mb-2">
			<v-col cols="12" sm="3" md="2">
				<v-autocomplete
					v-model="nienKhoaModel"
					:items="dsNienKhoa"
					item-text="TenNienKhoa"
					item-value="NienKhoa"
					outlined
					dense
					hide-details
					placeholder="Chọn niên khóa"
					label="Niên khóa"
				/>
			</v-col>

			<v-col cols="12" sm="3" md="3">
				<v-autocomplete
					v-model="majorModel"
					:items="heArr"
					item-text="TenNganh"
					item-value="NganhID"
					outlined
					dense
					hide-details
					label="Lọc theo ngành"
					placeholder="Chọn ngành"
					clearable
				/>
			</v-col>

			<v-col cols="12" sm="6" md="7" class="d-flex align-center">
				<v-btn
					color="primary"
					class="rounded-xs mr-2"
					depressed
					:disabled="nienKhoaModel === '0' || nienKhoaModel === 0 || !nienKhoaModel"
					@click="$emit('on-save-all')"
				>
					<v-icon left small>mdi-plus</v-icon>
					Thêm tất cả
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
								<v-list-item-title>Cập nhật thông tin học viên bằng Excel</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
						<v-list-item @click="$emit('on-open-sync-gvhd')">
							<v-list-item-icon class="mr-3">
								<v-icon small color="primary">mdi-sync</v-icon>
							</v-list-item-icon>
							<v-list-item-content>
								<v-list-item-title>Đồng bộ dữ liệu phân công GVHD</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
					</v-list>
				</v-menu>
			</v-col>
		</v-row>

		<!-- Card bảng danh sách học viên -->
		<v-card outlined class="rounded-xs">
			<v-card-title class="pa-2 px-3 d-flex align-center">
				<span class="subtitle-1 font-weight-bold primary--text">
					{{ labelTable }}
				</span>
				<v-spacer></v-spacer>
				<v-btn
					icon
					color="success"
					class="mr-2"
					:loading="isLoadingExport"
					@click="onPrintExcel"
					title="Xuất file Excel"
				>
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-text-field
					v-model="searchText"
					class="c-underline-search"
					label="Tìm kiếm nhanh học viên..."
					dense
					hide-details
					single-line
					clearable
					prepend-inner-icon="mdi-magnify"
					style="max-width: 280px;"
				/>
			</v-card-title>

			<v-divider />

			<v-data-table
				:headers="tableHeaders"
				:items="items"
				:search="searchText"
				:custom-filter="customFilter"
				:loading="!isTableReady"
				:items-per-page="50"
				:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
				height="calc(100vh - 233px)"
				fixed-header
				dense
			>
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
					<span class="primary--text font-weight-bold">{{ item.HoTen || ((item.HoSV || '') + ' ' + (item.TenSV || '')) }}</span>
					<br />
					<span class="font-weight-medium">{{ item.StudentID }}</span>
					<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
				</div>
			</template>

			<template v-slot:item.NgaySinh="{ item }">
				<span>{{ formatDisplayDate(item.NgaySinh) }}</span>
			</template>

			<template v-slot:item.updTask="{ item }">
				<v-btn
					text
					small
					color="indigo"
					class="rounded-xs"
					:disabled="!item.isExist && !item.isSelect"
					@click="$emit('on-select-student', item)"
				>
					<v-icon left small>mdi-account-edit-outline</v-icon>
					Cập nhật
				</v-btn>
			</template>

			<template v-slot:item.status="{ item }">
				<v-btn
					v-if="!item.isExist && !item.isSelect"
					text
					small
					color="primary"
					class="rounded-xs"
					@click="$emit('on-save-student', item)"
				>
					<v-icon left small>mdi-account-plus-outline</v-icon>
					Thêm học viên
				</v-btn>
				<v-btn
					v-else
					text
					small
					color="error"
					class="rounded-xs"
					:disabled="!item.isCanDelete"
					@click="$emit('on-delete-student', item)"
				>
					<v-icon left small>mdi-delete-outline</v-icon>
					Xóa học viên
				</v-btn>
			</template>

			<template v-slot:item.resetProcess="{ item }">
				<div class="d-flex flex-column align-center py-1">
					<v-btn
						text
						small
						color="warning"
						class="rounded-xs"
						:disabled="!item.isExist && !item.isSelect"
						@click="$emit('on-reset-process', item)"
					>
						<v-icon left small>mdi-refresh</v-icon>
						Đăng ký mới
					</v-btn>
					<v-btn
						v-if="item.HasResetProcess === 1"
						text
						x-small
						color="teal"
						class="rounded-xs mt-1"
						:disabled="!item.isExist && !item.isSelect"
						@click="$emit('on-view-old-process', item)"
					>
						<v-icon left small>mdi-history</v-icon>
						Dữ liệu cũ
					</v-btn>
				</div>
			</template>

			<template v-slot:item.IsXuLyHocVu="{ item }">
				<v-btn
					text
					small
					:color="item.IsXuLyHocVu ? 'orange darken-3' : 'purple darken-4'"
					class="rounded-xs font-weight-medium"
					:disabled="item.IsXuLyHocVu || (!item.isExist && !item.isSelect)"
					@click="$emit('on-xuly-hocvu', item)"
				>
					<v-icon left small>{{ item.IsXuLyHocVu ? 'mdi-check-circle-outline' : 'mdi-alert-circle-outline' }}</v-icon>
					{{ item.IsXuLyHocVu ? 'Đã xử lý học vụ' : 'Xử lý học vụ' }}
				</v-btn>
			</template>
		</v-data-table>
	</v-card>
</div>
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
			"on-open-sync-gvhd",
		],
		data() {
			return {
				searchText: "",
				isLoadingExport: false,
				tableHeaders: [
					{ text: "STT", value: "stt", align: "center", width: 60, sortable: false },
					{ text: "Học viên", value: "StudentID", width: 220 },
					{ text: "Ngày sinh", value: "NgaySinh", width: 110, align: "center" },
					{ text: "Niên khóa", value: "NienKhoa", width: 100, align: "center" },
					{ text: "Tên ngành", value: "TenNganh", width: 200 },
					{ text: "Cập nhật", value: "updTask", align: "center", sortable: false, width: 140 },
					{ text: "Trạng thái", value: "status", align: "center", sortable: false, width: 150 },
					{ text: "Đăng ký", value: "resetProcess", align: "center", sortable: false, width: 160 },
					{ text: "Học vụ", value: "IsXuLyHocVu", align: "center", sortable: false, width: 170 },
				],
			}
		},
		computed: {
			labelTable() {
				const count = this.items ? this.items.length : 0
				return count > 0 ? `Danh sách thông tin học viên (${count})` : "Danh sách thông tin học viên"
			},
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
			hasUnaddedStudents() {
				return this.items.some((x) => !x.isExist && !x.isSelect)
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
					item.Truong_DaiHoc,
					item.Nganh_DaiHoc,
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
						filename: `Danh_sach_thong_tin_hoc_vien_CaoHoc${nienKhoaStr}.xlsx`,
						worksheet: "Sheet1",
					})
				} catch (error) {
					console.error("Lỗi xuất Excel:", error)
					Vue.$toast.error("Lỗi xuất file Excel", { position: "top" })
				} finally {
					this.isLoadingExport = false
				}
			},
		},
	}
</script>