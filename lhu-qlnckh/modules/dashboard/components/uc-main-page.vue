<template>
	<div class="pa-3 dashboard-main-page">
		<!-- I. TỔNG THỂ HOẠT ĐỘNG NCKH (KPI Cards) -->
		<uc-stats :anPhamSummary="anPhamSummary" :cgcnHopDongTotal="cgcnHopDongTotal" :cgcnDonViTotal="cgcnDonViTotal"
			:giaiThuongTotal="giaiThuongTotal" :giaiThuongSinhVien="giaiThuongSinhVien"
			:giaiThuongGiangVien="giaiThuongGiangVien" :sumNCKHSV="sumNCKHSV" :sumKHCN="sumKHCN"
			:activeSection="activeSection" @select-section="onSelectSection"></uc-stats>

		<!-- CHỈ SỐ ẤN PHẨM ĐƯỢC ĐĂNG TRONG NĂM -->
		<v-row dense class="mb-3">
			<v-col cols="12">
				<v-card outlined class="rounded-xs pa-2">
					<v-card-title class="py-2 px-3 d-flex align-center justify-space-between flex-wrap">
						<div class="d-flex align-center flex-wrap ga-2">
							<span class="primary--text text-subtitle-1 font-weight-bold">
								CHỈ SỐ ẤN PHẨM ĐƯỢC ĐĂNG TRONG NĂM {{ selectedYear }}:
							</span>
							<v-select v-model="selectedYear" :items="yearOptions" label="Chọn năm" dense outlined
								hide-details class="dashboard-select-year ml-2"></v-select>
						</div>
						<v-spacer></v-spacer>
						<v-btn v-if="[1, 2, 9].includes(vueData.user?.SystemRight)" rounded small outlined
							color="primary" class="text-none" @click="onOpenModalPhanLoai(selectedYear)">
							<v-icon left small>mdi-table-eye</v-icon>Phân loại / Chi tiết
						</v-btn>
					</v-card-title>
					<v-card-text class="px-3 pb-3 pt-1">
						<v-row dense class="mb-2">
							<v-col cols="12" md="4">
								<v-card outlined class="rounded-xs pa-2 d-flex align-center justify-space-between dashboard-stat-card"
									@click="onOpenModalPhanLoai(selectedYear, '1')">
									<span class="text-body-2 grey--text text--darken-2 font-weight-medium">Tổng số (WoS/Scopus + HĐGSNN):</span>
									<span class="text-h6 font-weight-bold primary--text">
										{{ ((SoBaiDangQT[selectedYear] || []).length) + (Number(HDGSNNFormula[selectedYear]) || 0) }}
									</span>
								</v-card>
							</v-col>
							<v-col cols="12" md="4">
								<v-card outlined class="rounded-xs pa-2 d-flex align-center justify-space-between dashboard-stat-card"
									@click="onOpenModalPhanLoai(selectedYear, '1')">
									<span class="text-body-2 grey--text text--darken-2 font-weight-medium">WoS/Scopus:</span>
									<span class="text-h6 font-weight-bold info--text">
										{{ (SoBaiDangQT[selectedYear] || []).length }}
									</span>
								</v-card>
							</v-col>
							<v-col cols="12" md="4">
								<v-card outlined class="rounded-xs pa-2 d-flex align-center justify-space-between dashboard-stat-card"
									@click="onOpenModalPhanLoai(selectedYear, '2')">
									<span class="text-body-2 grey--text text--darken-2 font-weight-medium">Hội Đồng Giáo Sư Nhà Nước:</span>
									<span class="text-h6 font-weight-bold warning--text text--darken-2">
										{{ HDGSNNFormula[selectedYear] ?? 0 }}
									</span>
								</v-card>
							</v-col>
						</v-row>

						<div class="d-flex flex-wrap ga-2 mb-3">
							<v-chip small color="primary" outlined @click="onOpenModalPhanLoai(selectedYear, '3')">
								Hội thảo: <b class="ml-1">{{ (SoBaiDangKYHT[selectedYear] || []).length }}</b>
							</v-chip>
							<v-chip small color="primary" outlined @click="onOpenModalPhanLoai(selectedYear, '5')">
								Sách: <b class="ml-1">{{ (SoBaiDangSach[selectedYear] || []).length }}</b>
							</v-chip>
							<v-chip small color="primary" outlined @click="onOpenModalPhanLoai(selectedYear, '2')">
								Tạp chí trong nước: <b class="ml-1">{{ (TongSoBaiDang[selectedYear] || []).filter(ap => ap.LoaiAnPhamID == 3 && ap.LoaiSubAnPhamID == 8).length }}</b>
							</v-chip>
							<v-chip small color="primary" outlined @click="onOpenModalPhanLoai(selectedYear, '6')">
								Tạp chí KH Lạc Hồng (HĐGSNN): <b class="ml-1">{{ (SoBaiDangTapChiKHLH_GSNN[selectedYear] || []).length }}</b>
							</v-chip>
							<v-chip small color="primary" outlined @click="onOpenModalPhanLoai(selectedYear, '4')">
								Tạp chí KH Lạc Hồng (Khác): <b class="ml-1">{{ (SoBaiDangTCLH[selectedYear] || []).length }}</b>
							</v-chip>
						</div>

						<div class="dashboard-chart-350">
							<uc-chart v-if="!isLoadingChartBaiBao" :key="keyChartBaiBao" :data="dataBaiBaoTrongNam"
								type="bar" :options="optionBaiBaoTrongNam" :plugins="pluginsChart"></uc-chart>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
		</v-row>

		<!-- CHỈ SỐ HOẠT ĐỘNG KHOA HỌC TRONG NĂM -->
		<v-row dense class="mb-3">
			<v-col cols="12">
				<uc-hoat-dong-khoa-hoc></uc-hoat-dong-khoa-hoc>
			</v-col>
		</v-row>

		<!-- I. ẤN PHẨM KHOA HỌC -->
		<div ref="section1" class="mb-3">
			<uc-anpham-khenthuong :anPhamSummary="anPhamSummary"
				:anPhamQuocTeDetailSummary="anPhamQuocTeDetailSummary"
				:anPhamTrongNuocDetailSummary="anPhamTrongNuocDetailSummary"
				:anPhamColumnDetailSummary="anPhamColumnDetailSummary"
				:anPhamDetailSummary="anPhamDetailSummary"></uc-anpham-khenthuong>
		</div>

		<!-- II. CHUYỂN GIAO CÔNG NGHỆ -->
		<div ref="section2" class="mb-3">
			<uc-cgcn :cgcnHopDong="cgcnHopDong" :cgcnDonViTiepNhan="cgcnDonViTiepNhan"
				:cgcnTotalCount="cgcnHopDongTotal"></uc-cgcn>
		</div>

		<!-- III. GIẢI THƯỞNG NCKH -->
		<div ref="section3" class="mb-3">
			<uc-giaithuong :giaiThuongSummary="giaiThuongSummary"
				:giaiThuongNamSummary="giaiThuongNamSummary"></uc-giaithuong>
		</div>

		<!-- IV. ĐỀ TÀI NCKH -->
		<div ref="section4" class="mb-3">
			<uc-de-tai-nckh @on-sum-nckhsv="val => sumNCKHSV = val"
				@on-sum-khcn="val => sumKHCN = val"></uc-de-tai-nckh>
		</div>

		<!-- DIALOG PHÂN LOẠI ẤN PHẨM -->
		<uc-phan-loai-an-pham v-if="isShowModalPhanLoai" v-model="isShowModalPhanLoai" :year="selectedYear"
			:initialTab="selectedPhanLoaiTab" @reload="fetchAnPhamNamDang"></uc-phan-loai-an-pham>

		<!-- NÚT SCROLL TO TOP -->
		<v-btn v-show="showScrollTop" fab small dark color="primary" class="dashboard-scroll-top-btn"
			@click="scrollToTop" title="Lên đầu trang">
			<v-icon>mdi-chevron-up</v-icon>
		</v-btn>
	</div>
</template>

<script>
	export default {
		data() {
		return {
			vueData,
			activeSection: 0,
			showScrollTop: false,
			selectedYear: "2026",
			yearOptions: ["2026", "2025"],
			isShowModalPhanLoai: false,
			selectedPhanLoaiTab: "1",
			isLoadingChartBaiBao: false,
			keyChartBaiBao: 1,

			// Section I: Ấn phẩm
			anPhamSummary: { SL_Tong: 0, SL_TrongNuoc: 0, SL_QuocTe: 0 },
			anPhamQuocTeDetailSummary: [],
			anPhamTrongNuocDetailSummary: [],
			anPhamColumnDetailSummary: [],
			anPhamDetailSummary: [],

			// Section II: CGCN
			cgcnHopDong: [],
			cgcnDonViTiepNhan: [],
			cgcnDetailList: [],

			// Section III: Giải thưởng
			giaiThuongSummary: [],
			giaiThuongNamSummary: [],

			// Section IV: Đề tài NCKH
			sumNCKHSV: 0,
			sumKHCN: 0,

			// Yearly Publication Breakdown (2025, 2026)
			SoBaiDangTrongNuoc: { "2025": [], "2026": [] },
			SoBaiDangQuocTe: { "2025": [], "2026": [] },
			TongSoBaiDang: { "2025": [], "2026": [] },
			SoBaiDangQT: { "2025": [], "2026": [] },
			SoBaiDangHDGSNN: { "2025": [], "2026": [] },
			SoBaiDangKYHT: { "2025": [], "2026": [] },
			SoBaiDangKYHTTN: { "2025": [], "2026": [] },
			SoBaiDangKYHTQT: { "2025": [], "2026": [] },
			SoBaiDangTCLH: { "2025": [], "2026": [] },
			SoBaiDangSach: { "2025": [], "2026": [] },
			SoBaiDangTapChiKHLH_GSNN: { "2025": [], "2026": [] },

			optionBaiBaoTrongNam: {
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					legend: { display: true, position: "bottom" },
					datalabels: {
						color: "#333",
						font: { size: 12, weight: "bold" },
						formatter: (value) => (value > 0 ? value : "")
					}
				}
			}
		}
	},
	computed: {
		cgcnHopDongTotal() {
			if (this.cgcnDetailList && this.cgcnDetailList.length > 0) {
				return this.cgcnDetailList.length
			}
			return (this.cgcnHopDong || []).reduce((acc, cur) => acc + (Number(cur.SL_HD) || 0), 0)
		},
		cgcnDonViTotal() {
			return (this.cgcnDonViTiepNhan || []).length
		},
		giaiThuongTotal() {
			return (this.giaiThuongSummary || []).reduce((acc, cur) => acc + (Number(cur.SL_GT) || 0), 0)
		},
		giaiThuongSinhVien() {
			return (this.giaiThuongSummary || [])
				.filter(x => x.LoaiGiaiThuongID !== 4)
				.reduce((acc, cur) => acc + (Number(cur.SL_GT) || 0), 0)
		},
		giaiThuongGiangVien() {
			const found = (this.giaiThuongSummary || []).find(x => x.LoaiGiaiThuongID === 4)
			return found ? (Number(found.SL_GT) || 0) : 0
		},
		HDGSNNFormula() {
			const calcForYear = (y) => {
				const qt = (this.SoBaiDangQT[y] || []).length
				const hdgsnn = (this.SoBaiDangHDGSNN[y] || []).length
				const kyhttn = (this.SoBaiDangKYHTTN[y] || []).length
				const kyhtqt = (this.SoBaiDangKYHTQT[y] || []).length
				const tclhGsnn = (this.SoBaiDangTapChiKHLH_GSNN[y] || []).length
				const sach = (this.SoBaiDangSach[y] || []).length * 3
				return qt + hdgsnn + kyhttn + kyhtqt + tclhGsnn + sach
			}
			return {
				"2025": calcForYear("2025"),
				"2026": calcForYear("2026")
			}
		},
		dataBaiBaoTrongNam() {
			const buildYearData = (y) => [
				(this.SoBaiDangQT[y] || []).length,
				this.HDGSNNFormula[y] || 0,
				(this.TongSoBaiDang[y] || []).filter(ap => ap.LoaiAnPhamID == 3 && ap.LoaiSubAnPhamID == 8).length,
				((this.SoBaiDangKYHTTN[y] || []).length) + ((this.SoBaiDangKYHTQT[y] || []).length),
				(this.SoBaiDangSach[y] || []).length,
				(this.SoBaiDangTapChiKHLH_GSNN[y] || []).length,
				(this.SoBaiDangTCLH[y] || []).length
			]

			return {
				labels: [
					"WoS/Scopus",
					"Hội Đồng Giáo Sư Nhà Nước",
					"Tạp chí trong nước",
					"Hội thảo",
					"Sách",
					"Tạp chí KH Lạc Hồng (HĐGSNN)",
					"Tạp chí KH Lạc Hồng (Khác)"
				],
				datasets: [
					{
						label: "2025",
						backgroundColor: "#4db8ff",
						data: buildYearData("2025")
					},
					{
						label: "2026",
						backgroundColor: "#ffa64d",
						data: buildYearData("2026")
					}
				]
			}
		},
		pluginsChart() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		}
	},
	watch: {
		selectedYear() {
			this.keyChartBaiBao++
		}
	},
	async mounted() {
		window.addEventListener("scroll", this.onWindowScroll, { passive: true })
		vueData.reloadAnPhamNamDang = () => this.fetchAnPhamNamDang()
		await Promise.all([
			this.fetchAnPhamSummary(),
			this.fetchCGCNSummary(),
			this.fetchGiaiThuongSummary(),
			this.fetchHeSoChatLuong(),
			this.fetchAnPhamNamDang()
		])
	},
	beforeDestroy() {
		window.removeEventListener("scroll", this.onWindowScroll)
	},
	methods: {
		onWindowScroll() {
			const scrollTop = window.pageYOffset || document.documentElement.scrollTop || 0
			this.showScrollTop = scrollTop > 250
		},
		scrollToTop() {
			this.activeSection = 0
			window.scrollTo({ top: 0, behavior: "smooth" })
		},
		onSelectSection(sectionIndex) {
			this.activeSection = sectionIndex
			const refEl = this.$refs["section" + sectionIndex]
			if (refEl && typeof refEl.scrollIntoView === "function") {
				refEl.scrollIntoView({ behavior: "smooth", block: "start" })
			}
		},
		onOpenModalPhanLoai(year, tabId = "1") {
			if (year) {
				this.selectedYear = String(year)
			}
			this.selectedPhanLoaiTab = String(tabId || "1")
			this.isShowModalPhanLoai = true
		},
		async fetchAnPhamSummary() {
			const res = await ajaxCALLPromise("/RPT_BBKH_Summary", {})
			if (!res) return
			this.anPhamSummary = (res[0] && res[0][0]) ? res[0][0] : { SL_Tong: 0, SL_TrongNuoc: 0, SL_QuocTe: 0 }
			this.anPhamQuocTeDetailSummary = (res[1] || []).map(item => ({
				...item,
				TenLoaiAnPham: item.LoaiAnPhamID === 6 ? item.TenLoaiAnPham + " quốc tế" : item.TenLoaiAnPham
			}))
			this.anPhamTrongNuocDetailSummary = (res[2] || []).map(item => ({
				...item,
				TenLoaiAnPham: item.LoaiAnPhamID === 6 ? item.TenLoaiAnPham + " trong nước" : item.TenLoaiAnPham
			}))
			this.anPhamColumnDetailSummary = res[3] || []
			this.anPhamDetailSummary = (res[4] || []).map((item, idx) => ({
				...item,
				STT: idx + 1
			}))
		},
		async fetchCGCNSummary() {
			const [res, detailRows] = await Promise.all([
				ajaxCALLPromise("/RPT_CGCN_Summary", {}),
				ajaxCALLPromise("/ChuyenGiaoCongNghe_AUN_Get", {})
			])
			if (res) {
				this.cgcnHopDong = res[0] || []
				this.cgcnDonViTiepNhan = res[1] || []
			}
			this.cgcnDetailList = Array.isArray(detailRows) ? detailRows : []
		},
		async fetchGiaiThuongSummary() {
			const res = await ajaxCALLPromise("/RPT_GiaiThuong_Summary", {})
			if (!res) return
			this.giaiThuongSummary = (res[0] || []).map((item, idx) => ({
				...item,
				STT: idx + 1
			}))
			this.giaiThuongNamSummary = (res[1] || []).map((item, idx) => ({
				...item,
				STT: idx + 1
			}))
		},
		async fetchHeSoChatLuong() {
			const [hscl, dacThu] = await Promise.all([
				ajaxCALLPromise("/HSCL_Get", {}),
				ajaxCALLPromise("/RPT_LoaiSubAnPham_DacThu_Get", {})
			])
			vueData.DSHeSoChatLuong = Array.isArray(hscl) ? hscl : []
			vueData.DSHeSoChatLuongDacThu = Array.isArray(dacThu) ? dacThu : []
		},
		async fetchAnPhamNamDang() {
			this.isLoadingChartBaiBao = true
			const res = await ajaxCALLPromise("/RPT_AnPham_NamDang", { NamDang: "2025,2026" })
			const rows = Array.isArray(res) ? res : []

			const years = ["2025", "2026"]
			const mapState = {
				SoBaiDangTrongNuoc: {},
				SoBaiDangQuocTe: {},
				TongSoBaiDang: {},
				SoBaiDangQT: {},
				SoBaiDangHDGSNN: {},
				SoBaiDangKYHT: {},
				SoBaiDangKYHTTN: {},
				SoBaiDangKYHTQT: {},
				SoBaiDangTCLH: {},
				SoBaiDangSach: {},
				SoBaiDangTapChiKHLH_GSNN: {}
			}

			years.forEach(y => {
				const byYear = rows.filter(x => String(x.NamDangBai ?? x.NamDang) === y)
				mapState.TongSoBaiDang[y] = byYear
				mapState.SoBaiDangTrongNuoc[y] = byYear.filter(x => x.NoiDangBai === "Trong nước")
				mapState.SoBaiDangQuocTe[y] = byYear.filter(x => x.NoiDangBai === "Quốc tế")
				mapState.SoBaiDangQT[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 1)
				mapState.SoBaiDangHDGSNN[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 2)
				mapState.SoBaiDangKYHT[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 3)
				mapState.SoBaiDangKYHTTN[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 3 && Number(x.LoaiAnPhamID) === 1)
				mapState.SoBaiDangKYHTQT[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 3 && Number(x.LoaiAnPhamID) === 2)
				mapState.SoBaiDangTCLH[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 4)
				mapState.SoBaiDangSach[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 5)
				mapState.SoBaiDangTapChiKHLH_GSNN[y] = byYear.filter(x => Number(x.GroupAnPham_Edit) === 6)
			})

			Object.keys(mapState).forEach(key => {
				this[key] = mapState[key]
				vueData[key] = mapState[key]
			})

			this.keyChartBaiBao++
			this.isLoadingChartBaiBao = false
		}
	}
	}
</script>