<template>
	<div class="uc-thong-ke-scope">
		<v-row dense align="center" class="mb-2">
			<v-col cols="12" sm="6" md="2">
				<v-select v-model="typeSelect" :items="typeList" outlined dense hide-details label="Loại thống kê"
					item-text="text" item-value="value" />
			</v-col>

			<v-col cols="12" sm="6" md="3">
				<v-select v-model="major" :items="nganhGiangDay" outlined dense hide-details label="Lọc theo ngành"
					item-text="TenNganh" item-value="NganhID" />
			</v-col>

			<v-col cols="12" sm="6" md="2">
				<v-autocomplete v-model="nienKhoaValue" :items="dsNienKhoa" item-text="TenNienKhoa"
					item-value="NienKhoa" outlined dense hide-details placeholder="Chọn niên khóa" label="Niên khóa" />
			</v-col>

			<v-col v-if="typeSelect === '1'" cols="12" sm="6" md="3">
				<v-select v-model="trangThaiBaiBaoSelect" :items="trangThaiBaiBaoList" outlined dense hide-details
					label="Trạng thái bài báo" item-text="text" item-value="value" />
			</v-col>

			<v-col v-if="typeSelect === '2'" cols="12" sm="6" md="3">
				<v-select v-model="doiDieuChinhSelect" :items="doiOrDieuChinhList" outlined dense hide-details
					label="Đổi / Điều chỉnh đề tài" item-text="text" item-value="value" />
			</v-col>

			<v-col cols="12" sm="6" md="2" class="d-flex align-center">
				<v-btn color="primary" class="rounded-xs" depressed @click="onFilter">
					<v-icon left small>mdi-filter</v-icon> Lọc
				</v-btn>
			</v-col>
		</v-row>

		<div v-if="typeSelect === '1'">
			<uc-thong-ke-bai-bao :ds-bai-bao-khoa-hoc="dsBaiBaoKhoaHoc" :trang-thai-bai-bao="trangThaiBaiBaoSelect"
				:nganh-id="major" :nganh-giang-day="nganhGiangDay" />
		</div>

		<div v-if="typeSelect === '2'">
			<uc-thong-ke-doi-dieu-chinh :ds-doi-dieu-chinh-de-tai="dsDoiDieuChinhDeTai" :nganh-id="major"
				:nganh-giang-day="nganhGiangDay" />
		</div>

		<div v-if="typeSelect === '3'">
			<uc-thong-ke-hoan-thanh-sau-bao-ve :ds-hoan-thanh-sbv="dsHoanThanhSBV" />
		</div>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
		props: {},
		emits: [],
		data() {
			return {
				// API Data
				nganhGiangDay: [],
				dsNienKhoa: [],
				dsBaiBaoKhoaHoc: [],
				dsBaiBaoKhoaHocRoot: [],
				dsDoiDieuChinhDeTai: [],
				dsDoiDieuChinhDeTaiRoot: [],
				dsHoanThanhSBV: [],
				dsHoanThanhSBVRoot: [],

				// Local Filter States
				major: "0",
				nienKhoaValue: "0",
				typeSelect: "1",
				trangThaiBaiBaoSelect: "0",
				doiDieuChinhSelect: "0",

				trangThaiBaiBaoList: [
					{ text: "- Tất cả -", value: "0" },
					{ text: "Đã nộp bài báo / minh chứng", value: "1" },
					{ text: "Chưa nộp bài báo", value: "2" },
				],

				typeList: [
					{ text: "Bài báo & Công trình khoa học", value: "1" },
					{ text: "Đổi / Điều chỉnh đề tài", value: "2" },
					{ text: "Hoàn thành sau bảo vệ", value: "3" },
				],

				doiOrDieuChinhList: [
					{ text: "- Tất cả -", value: "0" },
					{ text: "Đổi đề tài", value: "1" },
					{ text: "Điều chỉnh đề tài", value: "2" },
				],
			};
		},
		watch: {
			major(val) {
				if (this.typeSelect === "1") {
					this.onLoadBaiBaoKhoaHoc(val, this.trangThaiBaiBaoSelect);
				} else if (this.typeSelect === "2") {
					this.onLoadDoiDieuChinhDeTai(val);
				} else if (this.typeSelect === "3") {
					this.onLoadHoanThanhSBV(val);
				}
				this.nienKhoaValue = this.dsNienKhoa[0]?.NienKhoa || "0";
			},
			typeSelect(val) {
				this.major = "0";
				this.nienKhoaValue = "0";
				if (val === "1") {
					this.onLoadBaiBaoKhoaHoc(this.major, "0");
				} else if (val === "2") {
					this.onLoadDoiDieuChinhDeTai(0);
				} else if (val === "3") {
					this.onLoadHoanThanhSBV(0);
				}
			},
			trangThaiBaiBaoSelect(val) {
				this.major = "0";
				this.nienKhoaValue = "0";
				this.onLoadBaiBaoKhoaHoc(this.major, val);
			},
		},
		mounted() {
			this.initData();
		},
		methods: {
			async initData() {
				await Promise.all([
					this.onLoadNganhGiangDay(),
					this.getNienKhoa(),
					this.onLoadBaiBaoKhoaHoc(0, this.trangThaiBaiBaoSelect),
				]);
			},

			onFilter() {
				const map = {
					1: { target: "dsBaiBaoKhoaHoc", source: "dsBaiBaoKhoaHocRoot" },
					2: { target: "dsDoiDieuChinhDeTai", source: "dsDoiDieuChinhDeTaiRoot" },
					3: { target: "dsHoanThanhSBV", source: "dsHoanThanhSBVRoot" },
				};

				const config = map[this.typeSelect];
				if (!config) return;

				const { target, source } = config;

				let data =
					this.nienKhoaValue !== "0"
						? this[source].filter((item) => item.Nien_Khoa === this.nienKhoaValue)
						: [...this[source]];

				if (this.typeSelect === "2" && this.doiDieuChinhSelect !== "0") {
					data = data.filter(
						(item) => String(item.IsDoiDeTaiOrDieuChinh) === String(this.doiDieuChinhSelect)
					);
				}

				this[target] = data;
			},

			async getNienKhoa() {
				try {
					const res = await ajaxGETCALLPromise("https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa");
					if (res && res.data) {
						const defaultObj = {
							TenNienKhoa: "- Tất cả niên khóa -",
							NienKhoa: "0",
						};
						const mapped = res.data.map((item) => ({
							...item,
							TenNienKhoa: item.NienKhoa,
							NienKhoa: item.NienKhoa,
						}));
						this.dsNienKhoa = [defaultObj, ...mapped];
						this.nienKhoaValue = this.dsNienKhoa[0]?.NienKhoa || "0";
					}
				} catch (error) {
					console.error("Lỗi tải niên khóa:", error);
				}
			},

			async onLoadNganhGiangDay() {
				try {
					const res = await ajaxCALLPromise("/Nganh_Get_ByHeID", { HeID: "N" });
					const defaultObj = {
						NganhID: "0",
						TenNganh: "- Tất cả ngành -",
					};
					const mapped = (res || []).map((item) => ({
						...item,
						NganhID: String(item.Nganh_ID),
						TenNganh: item.Ten_Nganh_HienThi || item.Ten_Nganh,
					}));
					this.nganhGiangDay = [defaultObj, ...mapped];
				} catch (error) {
					console.error("Lỗi tải danh mục ngành Tiến sĩ:", error);
				}
			},

			async onLoadBaiBaoKhoaHoc(nganhID, trangThai) {
				try {
					const data = await ajaxCALLPromise("/Student_BaiBaoKhoaHoc_Get_TS", {
						Nganh_ID: parseInt(nganhID) || 0,
						BaiBaoStatus: parseInt(trangThai) || 0,
					});
					if (data) {
						const mapped = data.map((item, index) => ({
							...item,
							STT: index + 1,
						}));
						this.dsBaiBaoKhoaHoc = [...mapped];
						this.dsBaiBaoKhoaHocRoot = [...mapped];
					}
				} catch (error) {
					console.error("Lỗi tải thống kê bài báo:", error);
				}
			},

			async onLoadDoiDieuChinhDeTai(nganhID) {
				try {
					const data = await ajaxCALLPromise("/SDH_Get_DoiDieuChinh_DeTai_TS", {
						Nganh_ID: parseInt(nganhID) || 0,
					});
					if (data) {
						const mapped = data.map((item, index) => ({
							...item,
							STT: index + 1,
							ThoiGianQD: item.Decision_ID
								? `${item.Decision_NgayQD}/${item.Decision_ThangQD}/${item.Decision_NamQD}`
								: "",
						}));
						this.dsDoiDieuChinhDeTai = [...mapped];
						this.dsDoiDieuChinhDeTaiRoot = [...mapped];
					}
				} catch (error) {
					console.error("Lỗi tải thống kê đổi đề tài:", error);
				}
			},

			async onLoadHoanThanhSBV(nganhID) {
				try {
					const data = await ajaxCALLPromise("/SDH_Get_HoanThanhSauBaoVe_TS", {
						NganhID: parseInt(nganhID) || 0,
					});
					if (data) {
						const mapped = data.map((item, index) => ({
							...item,
							STT: index + 1,
						}));
						this.dsHoanThanhSBV = [...mapped];
						this.dsHoanThanhSBVRoot = [...mapped];
					}
				} catch (error) {
					console.error("Lỗi tải thống kê hoàn thành SBV:", error);
				}
			},
		},
	}
</script>