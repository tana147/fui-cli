<template>
	<div class="uc-thong-ke-scope">
		<v-row>
			<v-col cols="12" sm="6" md="2">
				<v-select v-model="typeSelect" :items="typeList" outlined dense hide-details label="Loại thống kê"
					item-text="text" item-value="value" />
			</v-col>

			<v-col cols="12" sm="6" md="2">
				<v-select v-model="major" :items="nganhGiangDay" outlined dense hide-details label="Lọc theo ngành"
					item-text="TenNganh" item-value="NganhID" />
			</v-col>

			<v-col cols="12" sm="6" md="2">
				<v-autocomplete v-model="nienKhoaValue" :items="dsNienKhoa" item-text="TenNienKhoa"
					item-value="NienKhoa" outlined dense hide-details placeholder="Chọn niên khóa" label="Niên khóa" />
			</v-col>

			<v-col v-if="typeSelect === '1'" cols="12" sm="6" md="2">
				<v-select v-model="trangThaiBaiBaoSelect" :items="trangThaiBaiBaoList" outlined dense hide-details
					label="Trạng thái bài báo" item-text="text" item-value="value" />
			</v-col>

			<v-col v-if="typeSelect === '2'" cols="12" sm="6" md="2">
				<v-select v-model="doiDieuChinhSelect" :items="doiOrDieuChinhList" outlined dense hide-details
					label="Đổi/Điều chỉnh đề tài" item-text="text" item-value="value" />
			</v-col>

			<v-col cols="12" sm="6" md="2">
				<v-btn color="primary" dark @click="onFilter">
					<v-icon left>mdi-filter</v-icon> Lọc
				</v-btn>
			</v-col>
		</v-row>

		<div class="mt-4" v-if="typeSelect === '1'">
			<uc-thong-ke-bai-bao :ds-bai-bao-khoa-hoc="dsBaiBaoKhoaHoc" :trang-thai-bai-bao="trangThaiBaiBaoSelect"
				:nganh-id="major" :nganh-giang-day="nganhGiangDay" />
		</div>

		<div class="mt-4" v-if="typeSelect === '2'">
			<uc-thong-ke-doi-dieu-chinh :ds-doi-dieu-chinh-de-tai="dsDoiDieuChinhDeTai" :nganh-id="major"
				:nganh-giang-day="nganhGiangDay" />
		</div>

		<div class="mt-4" v-if="typeSelect === '3'">
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
					{ text: "Đã đăng bài", value: "1" },
					{ text: "Chưa đăng bài", value: "2" },
				],

				typeList: [
					{ text: "Bài báo khoa học", value: "1" },
					{ text: "Đổi/điều chỉnh đề tài", value: "2" },
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
				const res = await ajaxGETCALLPromise("https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa");
				if (res && res.data) {
					const defaultObj = {
						TenNienKhoa: "- Tất cả -",
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
			},

			async onLoadNganhGiangDay() {
				this.nganhGiangDay = await getNganhCaoHocPromise({ hasAllOption: true });
			},

			async onLoadBaiBaoKhoaHoc(nganhID, trangThai) {
				const data = await ajaxCALLPromise("/Student_BaiBaoKhoaHoc_Get", {
					Nganh_ID: parseInt(nganhID),
					BaiBaoStatus: parseInt(trangThai),
				});
				if (data) {
					const mapped = data.map((item, index) => ({
						...item,
						STT: index + 1,
					}));
					this.dsBaiBaoKhoaHoc = [...mapped];
					this.dsBaiBaoKhoaHocRoot = [...mapped];
				}
			},

			async onLoadDoiDieuChinhDeTai(nganhID) {
				const data = await ajaxCALLPromise("/SDH_Get_DoiDieuChinh_DeTai", {
					Nganh_ID: nganhID,
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
			},

			async onLoadHoanThanhSBV(nganhID) {
				const data = await ajaxCALLPromise("/SDH_Get_HoanThanhSauBaoVe", {
					NganhID: parseInt(nganhID),
				});
				if (data) {
					const mapped = data.map((item, index) => ({
						...item,
						STT: index + 1,
					}));
					this.dsHoanThanhSBV = [...mapped];
					this.dsHoanThanhSBVRoot = [...mapped];
				}
			},
		},
	}
</script>