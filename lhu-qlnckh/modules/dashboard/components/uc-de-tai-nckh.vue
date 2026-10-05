<template>
	<div>
		<uc-dcard title="IV. ĐỀ TÀI NCKH">
			<template v-slot:renderBody>
				<v-row dense>
					<v-col cols="12" md="6">
						<uc-dchart-card title="Tổng đề tài NCKH của sinh viên theo đợt" :detailTitle="String(sumNCKHSV)"
							elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogNCKHSV = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyNCKHSV" :data="dataChartNCKHSV" type="bar"
										:options="optionsBar" :plugins="pluginsChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12" md="6">
						<uc-dchart-card title="Đề tài NCKH sinh viên theo khoa" :detailTitle="String(sumNCKHSV)"
							elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogNCKHSV = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyNCKHKhoa" :data="dataChartNCKHKhoa" type="bar"
										:options="optionsHorizontalBar" :plugins="pluginsChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12">
						<uc-dchart-card title="Tổng đề tài KH&CN các cấp theo năm" :detailTitle="String(sumKHCN)"
							elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogKHCN = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyKHCN" :data="dataChartKHCN" type="bar" :options="optionsBar"
										:plugins="pluginsChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
				</v-row>
			</template>
		</uc-dcard>

		<uc-dialog v-model="dialogNCKHSV" title="Danh sách đề tài NCKH của sinh viên">
			<template v-slot:renderBody>
				<uc-dtable title="Đề tài NCKH của sinh viên" :headers="headersNCKHSV" :items="Data_NCKHSV"
					:isSearch="true" itemKey="SoThuTu"></uc-dtable>
			</template>
		</uc-dialog>

		<uc-dialog v-model="dialogKHCN" title="Danh sách đề tài KH&CN các cấp">
			<template v-slot:renderBody>
				<uc-dtable title="Đề tài KH&CN các cấp" :headers="headersKHCN" :items="Data_KHCN" :isSearch="true"
					itemKey="SoThuTu"></uc-dtable>
			</template>
		</uc-dialog>
	</div>
</template>

<script>
	export default {
		data() {
		return {
			Data_NCKH_Dot: [],
			Data_NCKH_Khoa: [],
			Data_NCKHSV: [],
			Data_KHCN_Nam: [],
			Data_KHCN: [],
			sumNCKHSV: 0,
			sumKHCN: 0,
			dialogNCKHSV: false,
			dialogKHCN: false,
			keyNCKHSV: 1,
			keyNCKHKhoa: 1,
			keyKHCN: 1,
			headersNCKHSV: [
				{ text: "STT", value: "SoThuTu", width: "70px", align: "center" },
				{ text: "Tên đề tài", value: "TenDeTaiNCKH" },
				{ text: "Khoa", value: "KhoaID" },
				{ text: "Tên sinh viên", value: "SinhVien" },
				{ text: "Tên GVHD", value: "GiaoVien" },
				{ text: "Sản phẩm", value: "MoTa_SanPham" }
			],
			headersKHCN: [
				{ text: "STT", value: "SoThuTu", width: "70px", align: "center" },
				{ text: "Nhóm đề tài", value: "TenNhomKHCN" },
				{ text: "Mã số", value: "MaSoDeTai" },
				{ text: "Tên đề tài", value: "TenDeTaiKHCN_Vi" },
				{ text: "Đơn vị", value: "DonVi" },
				{ text: "Năm đăng ký", value: "NamDangKy", align: "center" },
				{ text: "Năm thực hiện", value: "NamThucHien", align: "center" },
				{ text: "Tháng bắt đầu", value: "ThangBatDau", align: "center" },
				{ text: "Tháng kết thúc", value: "ThangKetThuc", align: "center" }
			]
		}
	},
	computed: {
		dataChartNCKHSV() {
			return {
				labels: this.Data_NCKH_Dot.map(x => x.TenDot),
				datasets: [
					{
						label: "Số lượng đề tài theo đợt",
						data: this.Data_NCKH_Dot.map(x => Number(x.SL_DT) || 0),
						backgroundColor: "#4db8ff"
					}
				]
			}
		},
		dataChartNCKHKhoa() {
			return {
				labels: this.Data_NCKH_Khoa.map(x => x.TenKhoa),
				datasets: [
					{
						label: "Số lượng đề tài theo khoa",
						data: this.Data_NCKH_Khoa.map(x => Number(x.SL_DT) || 0),
						backgroundColor: "#36a2eb"
					}
				]
			}
		},
		dataChartKHCN() {
			return {
				labels: this.Data_KHCN_Nam.map(x => String(x.NamThucHien)),
				datasets: [
					{
						label: "Số lượng đề tài KH&CN",
						data: this.Data_KHCN_Nam.map(x => Number(x.SL_DT) || 0),
						backgroundColor: "#ffa64d"
					}
				]
			}
		},
		optionsBar() {
			return {
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					legend: { position: "bottom" },
					datalabels: {
						color: "#333",
						font: { size: 11, weight: "bold" },
						formatter: (val) => (val > 0 ? val : "")
					}
				}
			}
		},
		optionsHorizontalBar() {
			return {
				responsive: true,
				maintainAspectRatio: false,
				indexAxis: "y",
				plugins: {
					legend: { position: "bottom" },
					datalabels: {
						color: "#333",
						font: { size: 11, weight: "bold" },
						formatter: (val) => (val > 0 ? val : "")
					}
				}
			}
		},
		pluginsChart() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		}
	},
	async mounted() {
		await Promise.all([
			this.fetchNCKHSummary(),
			this.fetchKHCNSummary()
		])
	},
	methods: {
		async fetchNCKHSummary() {
			const res = await ajaxCALLPromise("/RPT_NCKH_Summary", {})
			const dotList = (res && res[0]) ? res[0] : []
			const detailList = (res && res[1]) ? res[1] : []
			const khoaList = (res && res[2]) ? res[2] : []
			this.Data_NCKH_Dot = dotList
			this.Data_NCKH_Khoa = khoaList
			this.Data_NCKHSV = detailList.map((item, idx) => ({
				...item,
				SoThuTu: item.SoThuTu || (idx + 1)
			}))
			this.sumNCKHSV = dotList.reduce((acc, cur) => acc + (Number(cur.SL_DT) || 0), 0)
			this.$emit("on-sum-nckhsv", this.sumNCKHSV)
			this.keyNCKHSV++
			this.keyNCKHKhoa++
		},
		async fetchKHCNSummary() {
			const res = await ajaxCALLPromise("/RPT_KHCN_Summary", {})
			const namList = (res && res[0]) ? res[0] : []
			const detailList = (res && res[1]) ? res[1] : []
			this.Data_KHCN_Nam = namList
			this.Data_KHCN = detailList.map((item, idx) => ({
				...item,
				SoThuTu: item.SoThuTu || (idx + 1)
			}))
			this.sumKHCN = namList.reduce((acc, cur) => acc + (Number(cur.SL_DT) || 0), 0)
			this.$emit("on-sum-khcn", this.sumKHCN)
			this.keyKHCN++
		}
	}
	}
</script>