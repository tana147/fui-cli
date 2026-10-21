<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="pa-2 px-3 d-flex align-center">
			<span class="subtitle-1 font-weight-bold primary--text">{{ labelTable }}</span>
			<v-spacer />
			<v-btn icon color="success" class="mr-2" :loading="isLoadingExport" @click="onPrintExcel"
				title="Xuất file Excel nội bộ">
				<v-icon>mdi-microsoft-excel</v-icon>
			</v-btn>
			<v-text-field v-model="search" class="c-underline-search" prepend-inner-icon="mdi-magnify"
				label="Tìm kiếm nhanh bài báo / NCS..." single-line hide-details dense clearable />
		</v-card-title>

		<v-data-table :items="dsBaiBaoKhoaHocComputed" :headers="tableHeader"
			:search="search" dense items-per-page="50" fixed-header height="calc(-258px + 100vh)"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu bài báo khoa học" />
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
						{{ item.Ho_SV }} {{ item.Ten_SV }}
					</span>
					<br />
					<b>{{ item.Student_ID }}</b>
					<span v-if="item.Lop_ID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.Lop_ID }}]</span>
				</div>
			</template>

			<template v-slot:item.FileBaiBaoKhoaHocID="{ item }">
				<c-chip-file :file-id="item.FileBaiBaoKhoaHocID" label="Xem bài báo"
					empty-label="Chưa upload file" />
			</template>
		</v-data-table>
	</v-card>
</template>

<script>
	export default {
		name: "uc-thong-ke-bai-bao",
		props: {
			dsBaiBaoKhoaHoc: {
				type: Array,
				default: () => [],
			},
			nganhId: {
				type: [String, Number],
				default: "0",
			},
			nganhGiangDay: {
				type: Array,
				default: () => [],
			},
			trangThaiBaiBao: {
				type: [String, Number],
				default: "0",
			},
		},
		emits: [],
		data() {
			return {
				isLoadingExport: false,
				search: "",
				tableHeader: [
					{ text: "STT", value: "STT", sortable: false, align: "center", width: 60 },
					{ text: "Nghiên cứu sinh", value: "HoTenMaSV", width: 200 },
					{ text: "Niên khóa", value: "Nien_Khoa", sortable: false, align: "center", width: 110 },
					{ text: "Tên ngành", value: "Ten_Nganh", width: 180 },
					{ text: "Tên đề tài luận án", value: "Thesis_Name", width: 350 },
					{ text: "GVHD 1", value: "Thesises_Prof1", width: 180 },
					{ text: "GVHD 2", value: "Thesises_Prof2", width: 180 },
					{ text: "Minh chứng bài báo", value: "FileBaiBaoKhoaHocID", sortable: false, align: "center", width: 170 },
					{ text: "Tên bài báo / Công trình", value: "TenBaiBao", sortable: false, width: 280 },
				],
			};
		},
		computed: {
			dsBaiBaoKhoaHocComputed() {
				return this.dsBaiBaoKhoaHoc.map((item, index) => ({
					...item,
					STT: index + 1,
					HoTenMaSV: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""} ${item.Lop_ID || ""}`,
				}));
			},
			labelTable() {
				return `Danh sách bài báo & công trình NCS (${this.dsBaiBaoKhoaHocComputed.length})`;
			},
		},
		methods: {
			nganhName(nganhId) {
				const nganh = this.nganhGiangDay.find((item) => String(item.NganhID) === String(nganhId));
				return nganh ? nganh.TenNganh?.toUpperCase() : "";
			},
			onPrintExcel() {
				if (!this.dsBaiBaoKhoaHocComputed || this.dsBaiBaoKhoaHocComputed.length === 0) {
					Vue.$toast.warning("Không có dữ liệu để xuất Excel", { position: "top" });
					return;
				}

				this.isLoadingExport = true;
				try {
					const dataArr = this.dsBaiBaoKhoaHocComputed.map((item, index) => ({
						STT: index + 1,
						MSHV: item.Student_ID,
						HoTen: `${item.Ho_SV || ""} ${item.Ten_SV || ""}`.trim(),
						LopID: item.Lop_ID,
						NienKhoa: item.Nien_Khoa,
						TenNganh: item.Ten_Nganh,
						TenDeTaiLuanAn: item.Thesis_Name,
						GVHD1: item.Thesises_Prof1,
						GVHD2: item.Thesises_Prof2,
						TenBaiBao: item.TenBaiBao,
						TrangThaiNop: item.FileBaiBaoKhoaHocID ? "Đã nộp" : "Chưa nộp",
					}));

					jsonToExcel({
						data: dataArr,
						filename: "ThongKe_BaiBao_NCS.xlsx",
						worksheet: "BaiBaoKhoaHoc",
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