<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="pa-2 px-3 d-flex align-center">
			<span class="subtitle-1 font-weight-bold primary--text">{{ labelTable }}</span>
			<v-spacer />
			<v-tooltip bottom>
				<template v-slot:activator="{ on, attrs }">
					<div v-bind="attrs" v-on="on" class="d-inline-block">
						<v-btn small depressed color="grey lighten-2" class="mr-2 rounded-xs" disabled>
							<v-icon left small>mdi-file-word-box</v-icon> Xuất mẫu tổng hợp
						</v-btn>
					</div>
				</template>
				<span>Mẫu biểu tổng hợp Tiến sĩ đang được cập nhật</span>
			</v-tooltip>

			<v-btn icon color="success" class="mr-2" :loading="isLoadingExport" @click="onPrintExcel"
				title="Xuất file Excel nội bộ">
				<v-icon>mdi-microsoft-excel</v-icon>
			</v-btn>
			<v-text-field v-model="search" class="c-underline-search" prepend-inner-icon="mdi-magnify"
				label="Tìm kiếm nhanh NCS..." single-line hide-details dense clearable />
		</v-card-title>

		<v-data-table v-model="selectedItems" :items="dsHoanThanhSBVComputed" :headers="tableHeader"
			:search="search" item-key="StudentID" show-select dense items-per-page="50" fixed-header height="calc(-258px + 100vh)"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu NCS hoàn thành sau bảo vệ" />
			</template>

			<template v-slot:no-results>
				<c-empty-state text="Không tìm thấy kết quả phù hợp" />
			</template>

			<template v-slot:item.STT="{ index }">
				<span>{{ index + 1 }}</span>
			</template>

			<template v-slot:item.HoTenMaSV="{ item }">
				<div class="py-1">
					<span class="primary--text font-weight-bold">
						{{ item.HoSV }} {{ item.TenSV }}
					</span>
					<br />
					<b>{{ item.StudentID }}</b>
					<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
				</div>
			</template>
		</v-data-table>
	</v-card>
</template>

<script>
	export default {
		name: "uc-thong-ke-hoan-thanh-sau-bao-ve",
		props: {
			dsHoanThanhSbv: {
				type: Array,
				default: () => [],
			},
		},
		emits: [],
		data() {
			return {
				isLoadingExport: false,
				search: "",
				selectedItems: [],
				tableHeader: [
					{ text: "STT", value: "STT", sortable: false, align: "center", width: 60 },
					{ text: "Nghiên cứu sinh", value: "HoTenMaSV", width: 200 },
					{ text: "Niên khóa", value: "Nien_Khoa", sortable: false, align: "center", width: 110 },
					{ text: "Tên ngành", value: "TenNganh", width: 180 },
					{ text: "Tên luận án", value: "ThesisName", width: 350 },
					{ text: "Điểm bảo vệ", value: "DiemHoiDong", sortable: false, align: "center", width: 110 },
					{ text: "GVHD 1", value: "ThesisesProf1", width: 180 },
					{ text: "GVHD 2", value: "ThesisesProf2", width: 180 },
					{ text: "Chủ tịch HĐ", value: "ChuTich", width: 180 },
					{ text: "Phản biện 1", value: "Pb_1", width: 180 },
					{ text: "Phản biện 2", value: "Pb_2", width: 180 },
					{ text: "Ủy viên", value: "UyVien", width: 180 },
					{ text: "Thư ký", value: "ThuKy", width: 180 },
				],
			};
		},
		computed: {
			dsHoanThanhSBVComputed() {
				return this.dsHoanThanhSbv.map((item, index) => ({
					...item,
					id: item.StudentID,
					STT: index + 1,
					HoTenMaSV: `${item.HoSV || ""} ${item.TenSV || ""} ${item.StudentID || ""} ${item.LopID || ""}`,
				}));
			},
			labelTable() {
				return `Danh sách NCS hoàn thành sau bảo vệ (${this.dsHoanThanhSBVComputed.length})`;
			},
		},
		methods: {
			onPrintExcel() {
				const sourceList = this.selectedItems && this.selectedItems.length > 0
					? this.selectedItems
					: this.dsHoanThanhSBVComputed;

				if (!sourceList || sourceList.length === 0) {
					Vue.$toast.warning("Không có dữ liệu để xuất Excel", { position: "top" });
					return;
				}

				this.isLoadingExport = true;
				try {
					const dataArr = sourceList.map((item, index) => ({
						STT: index + 1,
						MSHV: item.StudentID,
						HoTen: `${item.HoSV || ""} ${item.TenSV || ""}`.trim(),
						GioiTinh: item.GioiTinh || "",
						NgaySinh: item.NgaySinh || "",
						Nganh: item.TenNganh || "",
						NienKhoa: item.Nien_Khoa || "",
						LopID: item.LopID || "",
						DiemBaoVe: item.DiemHoiDong || "",
						DeTaiLuanAn: item.ThesisName || "",
						GVHD1: item.ThesisesProf1 || "",
						GVHD2: item.ThesisesProf2 || "",
						ChuTichHD: item.ChuTich || "",
						PhanBien1: item.Pb_1 || "",
						PhanBien2: item.Pb_2 || "",
						UyVienHD: item.UyVien || "",
						ThuKyHD: item.ThuKy || "",
						DienThoai: item.SoDienThoai || "",
						Email: item.Email || "",
					}));

					jsonToExcel({
						data: dataArr,
						filename: "ThongKe_NCS_HoanThanhSauBaoVe.xlsx",
						worksheet: "HoanThanhSBV",
					});
					Vue.$toast.success("Xuất file Excel thành công", { position: "top" });
				} catch (error) {
					console.error(error);
					Vue.$toast.error("Lỗi xuất Excel: " + error, { position: "top" });
				} finally {
					this.isLoadingExport = false;
				}
			},
		},
	}
</script>