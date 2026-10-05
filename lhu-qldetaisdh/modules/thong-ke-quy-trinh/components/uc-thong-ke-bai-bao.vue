<template>
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

		<v-data-table class="table-frozen-2-col" :items="dsBaiBaoKhoaHocComputed" :headers="tableHeader"
			:search="search" dense items-per-page="-1" fixed-header height="calc(100vh - 250px)"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
			<template v-slot:item.HoTenMaSV="{ item }">
				<span class="primary--text">
					<b>{{ item.Ho_SV }} {{ item.Ten_SV }}</b>
				</span>
				<br />
				<b>{{ item.Student_ID }}</b>
				<span class="amber--text"> [{{ item.Lop_ID }}]</span>
			</template>

			<template v-slot:item.FileBaiBaoKhoaHocID="{ item }">
				<c-chip-file :file-id="item.FileBaiBaoKhoaHocID" label="Bài báo khoa học"
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
					{ text: "STT", value: "STT", sortable: false, align: "center", width: 50 },
					{ text: "Học viên", value: "HoTenMaSV", width: 170 },
					{ text: "Niên khóa", value: "Nien_Khoa", sortable: false, align: "center", width: 100 },
					{ text: "Tên ngành", value: "Ten_Nganh", width: 180 },
					{ text: "Tên đề tài", value: "Thesis_Name", width: 490 },
					{ text: "GVHD 1", value: "Thesises_Prof1", width: 180 },
					{ text: "GVHD 2", value: "Thesises_Prof2", width: 180 },
					{ text: "File bài báo", value: "FileBaiBaoKhoaHocID", sortable: false, align: "center" },
					{ text: "Tên bài báo", value: "TenBaiBao", sortable: false, width: 250 },
					{ text: "Tên tạp chí/Hội thảo", value: "TenTapChi_HoiThao", sortable: false, width: 200 },
					{ text: "Năm xuất bản", value: "NamXuatBan", sortable: false, width: 120 },
					{ text: "Vị trí tác giả", value: "ViTriTacGia", sortable: false, width: 150 },
					{ text: "Điểm Hội đồng GS", value: "DiemHoiDongGS", sortable: false, width: 100 },
				],
			};
		},
		computed: {
			fileReadUrl() {
				return window.vueData?.v_Set?.urlReadFile || "";
			},
			dsBaiBaoKhoaHocComputed() {
				return this.dsBaiBaoKhoaHoc.map((item) => ({
					...item,
					HoTenMaSV: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""} ${item.Lop_ID || ""}`,
				}));
			},
			labelTable() {
				return `Danh sách học viên (${this.dsBaiBaoKhoaHocComputed.length})`;
			},
		},
		methods: {
			nganhName(nganhId) {
				const nganh = this.nganhGiangDay.find((item) => item.NganhID === nganhId);
				return nganh ? nganh.TenNganh?.toUpperCase() : "";
			},
			async onPrintExcel() {
				this.isLoadingExport = true;
				try {
					const dataArr = this.dsBaiBaoKhoaHocComputed.map((item, index) => ({
						STT: index + 1,
						MSHV: item.Student_ID,
						HoHV: item.Ho_SV,
						TenHV: item.Ten_SV,
						LopID: item.Lop_ID,
						NienKhoa: item.Nien_Khoa,
						TenNganh: item.Ten_Nganh,
						TenDeTai: item.Thesis_Name,
						GVHD1: item.Thesises_Prof1,
						GVHD2: item.Thesises_Prof2,
						TenBaiBao: item.TenBaiBao,
						TenTapChiHoiThao: item.TenTapChi_HoiThao,
						ViTriTacGia: item.ViTriTacGia,
						DiemHoiDongGS: isNaN(parseFloat(item.DiemHoiDongGS)) ? null : parseFloat(item.DiemHoiDongGS),
					}));

					const apiData = {
						Nganh: this.nganhId === "0" ? "" : this.nganhName(this.nganhId),
						SoLuong: this.dsBaiBaoKhoaHocComputed.length,
						TrangThaiBaiBao: parseInt(this.trangThaiBaiBao),
						DanhSach: dataArr,
					};

					const blob = await ajaxPOSTBlobPromise(
						"https://gendocx.iotsoftvn.com/api/generate-xlsx/thong-ke-bai-bao",
						apiData
					);
					if (blob) {
						const url = window.URL.createObjectURL(blob);
						const a = document.createElement("a");
						a.href = url;
						a.download = "Danh sách nộp bài báo.xlsx";
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