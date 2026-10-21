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
				label="Tìm kiếm nhanh NCS..." single-line hide-details dense clearable />
		</v-card-title>

		<v-data-table :items="dsDoiDieuChinhComputed" :headers="tableHeader"
			:search="search" dense items-per-page="50" fixed-header height="calc(-258px + 100vh)"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu đổi / điều chỉnh đề tài" />
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
					<b>{{ item.Student_ID }}</b>
					<span v-if="item.LopID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.LopID }}]</span>
				</div>
			</template>

			<template v-slot:item.Decision_SoQD="{ item }">
				<c-chip-file v-if="item.DecisionFile_ID" :file-id="item.DecisionFile_ID"
					:label="item.Decision_SoQD ? 'Số: ' + item.Decision_SoQD : 'QĐ thay đổi'" />
				<span v-else-if="item.Decision_SoQD">Số: {{ item.Decision_SoQD }}</span>
				<span v-else class="grey--text">Chưa có số QĐ</span>
			</template>

			<template v-slot:item.action="{ item }">
				<v-btn small depressed color="primary" class="rounded-xs" @click="detailInfo(item)">
					<v-icon left small>mdi-eye-outline</v-icon> Chi tiết
				</v-btn>
			</template>
		</v-data-table>

		<uc-modal-detail-doi-dieu-chinh v-model="isDetailModalOpen" :detail-data="detailData" />
	</v-card>
</template>

<script>
	export default {
		name: "uc-thong-ke-doi-dieu-chinh",
		props: {
			dsDoiDieuChinhDeTai: {
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
		},
		emits: [],
		data() {
			return {
				isLoadingExport: false,
				search: "",
				isDetailModalOpen: false,
				detailData: {},
				tableHeader: [
					{ text: "STT", value: "STT", sortable: false, align: "center", width: 60 },
					{ text: "Nghiên cứu sinh", value: "HoTenMaSV", width: 200 },
					{ text: "Niên khóa", value: "Nien_Khoa", sortable: false, align: "center", width: 110 },
					{ text: "Tên ngành", value: "TenNganh", width: 180 },
					{ text: "Tên đề tài mới", value: "NewThesisName", width: 350 },
					{ text: "GVHD 1", value: "ThesisesProf1", width: 180 },
					{ text: "GVHD 2", value: "ThesisesProf2", width: 180 },
					{ text: "Quyết định", value: "Decision_SoQD", width: 180 },
					{ text: "Thao tác", value: "action", sortable: false, align: "center", width: 110 },
				],
			};
		},
		computed: {
			dsDoiDieuChinhComputed() {
				return this.dsDoiDieuChinhDeTai.map((item, index) => ({
					...item,
					STT: index + 1,
					HoTenMaSV: `${item.HoSV || ""} ${item.TenSV || ""} ${item.Student_ID || ""} ${item.LopID || ""}`,
				}));
			},
			labelTable() {
				return `Danh sách NCS đổi / điều chỉnh đề tài (${this.dsDoiDieuChinhComputed.length})`;
			},
		},
		methods: {
			detailInfo(item) {
				this.detailData = item;
				this.isDetailModalOpen = true;
			},
			nganhName(nganhId) {
				const nganh = this.nganhGiangDay.find((item) => String(item.NganhID) === String(nganhId));
				return nganh ? nganh.TenNganh?.toUpperCase() : "";
			},
			onPrintExcel() {
				if (!this.dsDoiDieuChinhComputed || this.dsDoiDieuChinhComputed.length === 0) {
					Vue.$toast.warning("Không có dữ liệu để xuất Excel", { position: "top" });
					return;
				}

				this.isLoadingExport = true;
				try {
					const dataArr = this.dsDoiDieuChinhComputed.map((item, index) => ({
						STT: index + 1,
						MSHV: item.Student_ID,
						HoTen: `${item.HoSV || ""} ${item.TenSV || ""}`.trim(),
						NienKhoa: item.Nien_Khoa,
						LopID: item.LopID,
						Nganh: item.TenNganh,
						TenDeTaiMoi: item.NewThesisName,
						GVHD1: item.ThesisesProf1,
						GVHD2: item.ThesisesProf2,
						SoQD: item.Decision_SoQD,
						NgayQD: item.ThoiGianQD,
					}));

					jsonToExcel({
						data: dataArr,
						filename: "ThongKe_DoiDieuChinhDeTai_NCS.xlsx",
						worksheet: "DoiDieuChinh",
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