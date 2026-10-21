<template>
	<v-card>
		<v-card-title class="primary--text d-flex align-center">
			<span>{{ labelTable }}</span>
			<v-spacer />
			<v-btn icon color="primary" class="mr-2" :loading="isLoadingExport" @click="onPrint"
				title="Xuất file Excel">
				<v-icon>mdi-microsoft-excel</v-icon>
			</v-btn>
			<v-text-field v-model="search" class="c-underline-search max-w-400" prepend-inner-icon="mdi-magnify"
				label="Tìm kiếm mã học viên..." single-line hide-details dense />
		</v-card-title>

		<v-data-table class="table-frozen-cols" item-key="STT" v-model="selectedItems" show-select
			:items="dsHoanThanhFormatted" :headers="tableHeader" :search="search" dense items-per-page="-1" fixed-header
			height="calc(100vh - 250px)" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
			<template v-slot:item.HoTenMaSV="{ item }">
				<span class="primary--text">
					<b>{{ item.HoSV }} {{ item.TenSV }}</b>
				</span>
				<br />
				<b>{{ item.StudentID }}</b>
				<span class="amber--text"> [{{ item.LopID }}]</span>
			</template>

			<template v-slot:item.SoDienThoai="{ item }">
				<b>{{ item.SoDienThoai }}</b>
				<p class="mb-0">{{ item.Email }}</p>
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
					{ text: "Họ tên", value: "HoTenMaSV", sortable: false, width: 200 },
					{ text: "Giới tính", value: "GioiTinh", sortable: false, align: "center", width: 90 },
					{ text: "Ngày sinh", value: "NgaySinh", sortable: false, align: "center" },
					{ text: "Ngành", value: "TenNganh", sortable: false, width: 200 },
					{ text: "Niên khóa", value: "Nien_Khoa", sortable: false, align: "center", width: 100 },
					{ text: "SĐT/Email", value: "SoDienThoai", sortable: false, width: 150 },
					{ text: "Đề tài", value: "ThesisName", sortable: false, width: 300 },
					{ text: "Chủ tịch", value: "ChuTich", sortable: false, width: 180 },
					{ text: "Phản biện 1", value: "Pb_1", sortable: false, width: 180 },
					{ text: "Phản biện 2", value: "Pb_2", sortable: false, width: 180 },
					{ text: "Ủy viên", value: "UyVien", sortable: false, align: "center", width: 180 },
					{ text: "Thư ký", value: "ThuKy", sortable: false, width: 180 },
				],
			};
		},
		computed: {
			labelTable() {
				const total = this.dsHoanThanhSbv.length;
				const selected = this.selectedItems.length;
				return `Danh sách học viên (${total})${selected > 0 ? ` - Đã chọn (${selected})` : ""}`;
			},
			dsHoanThanhFormatted() {
				return this.dsHoanThanhSbv.map((item) => ({
					...item,
					HoTenMaSV: `${item.HoSV || ""} ${item.TenSV || ""} ${item.StudentID || item.Student_ID || ""} ${item.LopID || ""}`,
				}));
			},
		},
		methods: {
			async onLoadDiemThanhPhan(studentID) {
				const res = await ajaxGETCALLPromise(
					`https://tapi.lhu.edu.vn/mark/MarkViewer_GetBangDiem?studentId=${studentID}`
				);
				if (res && res.data) {
					return res.data.map((item, index) => ({
						...item,
						STT: index + 1,
						DiemThanhPhanList: item.DiemThanhPhan ? JSON.parse(item.DiemThanhPhan) : [],
					}));
				}
				return [];
			},

			async onPrint() {
				if (!this.selectedItems || this.selectedItems.length === 0) {
					if (typeof Vue !== "undefined" && Vue.$toast) {
						Vue.$toast.warning("Vui lòng chọn ít nhất một học viên để xuất Excel", { position: "top" });
					}
					return;
				}
				this.isLoadingExport = true;
				try {
					const dataArr = this.selectedItems.map((item, index) => ({
						STT: index + 1,
						MSHV: item.StudentID || item.Student_ID || "",
						HoHV: item.HoSV || "",
						TenHV: item.TenSV || "",
						GioiTinh: item.GioiTinh || "",
						NgaySinh: item.NgaySinh || "",
						Nganh: item.TenNganh || "",
						NienKhoa: item.Nien_Khoa || "",
						LopID: item.LopID || "",
						SoMonHoc: "0",
						DiemTBHocTap: "0",
						DiemTBTotNghiep: "0",
						DiemBaoVe: item.DiemHoiDong ? item.DiemHoiDong.toString() : "",
						DeTai: item.ThesisName || "",
						GVHD1: item.ThesisesProf1 || "",
						GVHD2: item.ThesisesProf2 || "",
						ChuTich: item.ChuTich || "",
						PB1: item.Pb_1 || "",
						PB2: item.Pb_2 || "",
						UyVien: item.UyVien || "",
						ThuKy: item.ThuKy || "",
						SoDT: item.SoDienThoai || "",
						Email: item.Email || "",
					}));

					const HeSoLuanvan = 15;
					for (let item of dataArr) {
						const rawDiem = await this.onLoadDiemThanhPhan(item.MSHV);
						const diemArray = rawDiem.filter((diemItem) => {
							const monHocID = diemItem?.MonHocID;
							if (monHocID === null || monHocID === undefined) {
								return true;
							}
							const monHocIDStr = String(monHocID).replace(/\D/g, "");
							return monHocIDStr.slice(-3) !== "815";
						});

						const countMonHoc = diemArray.length;
						const totalDtb = diemArray.reduce((sum, diemItem) => {
							if (diemItem.HeSo !== HeSoLuanvan) {
								return sum + diemItem.DiemTBMon * diemItem.HeSo;
							}
							return sum;
						}, 0);

						const totalHeSo = diemArray.reduce((sum, diemItem) => sum + diemItem.HeSo, 0);
						const parseDiemBaoVe = item.DiemBaoVe ? parseFloat(item.DiemBaoVe) : 0;

						item.SoMonHoc = countMonHoc.toString();

						try {
							const dtbHocTap = totalDtb / (totalHeSo - HeSoLuanvan);
							item.DiemTBHocTap =
								isFinite(dtbHocTap) && !isNaN(dtbHocTap) ? dtbHocTap.toFixed(1) : "";
						} catch (e) {
							item.DiemTBHocTap = "";
						}

						try {
							const dtbTotNghiep = (totalDtb + parseDiemBaoVe * HeSoLuanvan) / totalHeSo;
							item.DiemTBTotNghiep =
								isFinite(dtbTotNghiep) && !isNaN(dtbTotNghiep)
									? dtbTotNghiep.toFixed(2)
									: "";
						} catch (e) {
							item.DiemTBTotNghiep = "";
						}
					}

					const apiData = {
						DanhSach: dataArr,
					};

					const blob = await ajaxPOSTBlobPromise(
						"https://gendocx.iotsoftvn.com/api/generate-xlsx/hoan-thanh-sau-bao-ve",
						apiData
					);
					if (blob) {
						const url = window.URL.createObjectURL(blob);
						const a = document.createElement("a");
						a.href = url;
						a.download = "Danh sách hoàn thành sau bảo vệ.xlsx";
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