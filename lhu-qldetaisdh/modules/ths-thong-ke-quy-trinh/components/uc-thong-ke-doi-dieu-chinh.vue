<template>
	<div>
		<v-card>
			<v-card-title class="primary--text d-flex align-center">
				<span>{{ labelTable }}</span>
				<v-spacer />
				<v-btn icon color="primary" class="mr-2" :loading="isLoadingExport" @click="onPrintExcel"
					title="Xuất file Excel">
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-text-field v-model="search" class="c-underline-search max-w-360" prepend-inner-icon="mdi-magnify"
					label="Tìm kiếm..." single-line hide-details dense />
			</v-card-title>

			<v-data-table class="table-frozen-2-col" :items="dsDoiDieuChinhComputed" :headers="tableHeader"
				:search="search" dense items-per-page="-1" fixed-header height="calc(100vh - 250px)"
				:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
				<template v-slot:item.STT="{ index }">
					{{ index + 1 }}
				</template>

				<template v-slot:item.HoTenMaSV="{ item }">
					<span class="primary--text">
						<b>{{ item.HoSV }} {{ item.TenSV }}</b>
					</span>
					<br />
					<b>{{ item.Student_ID }}</b>
					<span class="amber--text"> [{{ item.LopID }}]</span>
				</template>

				<template v-slot:item.detailBtn="{ item }">
					<v-btn color="primary" text @click="detailInfo(item)">
						Xem chi tiết
					</v-btn>
				</template>

				<template v-slot:item.Decision_ID="{ item }">
					<c-chip-file :url="item.Decision_ID && item.DecisionFile_Url ? item.DecisionFile_Url : ''"
						:label="item.Decision_SoQD || 'File QĐ'"
						:empty-label="item.Decision_SoQD || 'Chưa có file QĐ'" />
				</template>
			</v-data-table>
		</v-card>

		<uc-modal-detail-doi-dieu-chinh v-model="isDetailModalOpen" :detail-data="detailData" />
	</div>
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
				isDetailModalOpen: false,
				isLoadingExport: false,
				search: "",
				detailData: {},

				tableHeader: [
					{ text: "STT", value: "STT", sortable: false, align: "center", width: 50 },
					{ text: "Học viên", value: "HoTenMaSV", width: 200 },
					{ text: "Niên khóa", value: "Nien_Khoa", sortable: false, align: "center", width: 110 },
					{ text: "Tên ngành", value: "TenNganh", sortable: false, width: 200 },
					{ text: "Ngày QĐ", value: "ThoiGianQD", width: 120, sortable: false, align: "center" },
					{ text: "Tên đề tài mới", value: "NewThesisName", sortable: false, width: 500 },
					{ text: "GVHD 1", value: "ThesisesProf1", sortable: false, width: 180 },
					{ text: "GVHD 2", value: "ThesisesProf2", sortable: false, width: 180 },
					{ text: "Số lần đổi/điều chỉnh đề tài", value: "SoLanDoiDieuChinh", sortable: false, align: "center", width: 120 },
					{ text: "Quyết định đổi/điều chỉnh", value: "Decision_ID", sortable: false, align: "center", width: 120 },
					{ text: "", value: "detailBtn", sortable: false, align: "center", width: 80 },
				],
			};
		},
		computed: {
			fileReadUrl() {
				return window.vueData?.v_Set?.urlReadFile || "";
			},
			dsDoiDieuChinhComputed() {
				return this.dsDoiDieuChinhDeTai.map((item) => ({
					...item,
					HoTenMaSV: `${item.HoSV || ""} ${item.TenSV || ""} ${item.Student_ID || ""} ${item.LopID || ""}`,
				}));
			},
			labelTable() {
				return `Danh sách học viên đã đổi/điều chỉnh đề tài (${this.dsDoiDieuChinhComputed.length})`;
			},
		},
		methods: {
			detailInfo(item) {
				this.detailData = item;
				this.isDetailModalOpen = true;
			},
			nganhName(nganhId) {
				const nganh = this.nganhGiangDay.find((item) => item.NganhID === nganhId);
				return nganh ? nganh.TenNganh?.toUpperCase() : "";
			},
			async onPrintExcel() {
				this.isLoadingExport = true;
				try {
					const dataArr = this.dsDoiDieuChinhComputed.map((item, index) => ({
						STT: index + 1,
						MSHV: item.Student_ID,
						HoHV: item.HoSV,
						TenHV: item.TenSV,
						NienKhoa: item.Nien_Khoa,
						LopID: item.LopID,
						TenDeTaiMoi: item.NewThesisName,
						Nganh: item.TenNganh,
						GVHD1: item.ThesisesProf1,
						GVHD2: item.ThesisesProf2,
					}));

					const apiData = {
						Nganh: this.nganhId === "0" ? "" : this.nganhName(this.nganhId),
						DanhSach: dataArr,
					};

					const blob = await ajaxPOSTBlobPromise(
						"https://gendocx.iotsoftvn.com/api/generate-xlsx/thong-ke-doi-dieu-chinh",
						apiData
					);
					if (blob) {
						const url = window.URL.createObjectURL(blob);
						const a = document.createElement("a");
						a.href = url;
						a.download = "Danh sách đổi/điều chỉnh đề tài.xlsx";
						document.body.appendChild(a);
						a.click();
						a.remove();
					}
				} catch (error) {
					console.error(error);
				} finally {
					this.isLoadingExport = false;
				}
			},
		},
	}
</script>