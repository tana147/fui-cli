<template>
	<div>
		<uc-dcard title="III. GIẢI THƯỞNG NCKH" :IsShowBtnDialogGiaiThuong="true">
			<template v-slot:renderBody>
				<v-row dense>
					<v-col cols="12" md="4">
						<uc-dchart-card title="Tổng hợp giải thưởng NCKH" :detailTitle="String(sumGiaiThuong)"
							elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogPie = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-pie">
									<uc-chart :key="keyPie" :data="dataChartPie" type="pie" :options="optionsPie"
										:plugins="pluginsChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12" md="8">
						<uc-dchart-card title="Giải thưởng NCKH qua các năm" :detailTitle="String(sumGiaiThuong)"
							elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogBar = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyBar" :data="dataChartBar" type="bar" :options="optionsBar"
										:plugins="pluginsChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
				</v-row>
			</template>
		</uc-dcard>

		<uc-dialog v-model="dialogPie" title="Tổng hợp giải thưởng NCKH">
			<template v-slot:renderBody>
				<uc-dtable title="Tổng hợp giải thưởng NCKH" :headers="headersSummary" :items="giaiThuongSummary"
					:isSearch="true" itemKey="STT"></uc-dtable>
			</template>
		</uc-dialog>

		<uc-dialog v-model="dialogBar" title="Giải thưởng NCKH qua các năm">
			<template v-slot:renderBody>
				<uc-dtable title="Giải thưởng NCKH qua các năm" :headers="headersNamSummary"
					:items="giaiThuongNamSummary" :isSearch="true" itemKey="STT"></uc-dtable>
			</template>
		</uc-dialog>
	</div>
</template>

<script>
	export default {
		props: {
		giaiThuongSummary: {
			type: Array,
			default: () => []
		},
		giaiThuongNamSummary: {
			type: Array,
			default: () => []
		}
	},
	data() {
		return {
			colorPalette: [
				"#ff6384",
				"#36a2eb",
				"#ffa64d",
				"#4db8ff",
				"#a0d911",
				"#ccb2ff",
				"#13c2c2",
				"#eb2f96",
				"#ffe6aa",
				"#a5dfdf"
			],
			dialogPie: false,
			dialogBar: false,
			keyPie: 1,
			keyBar: 1,
			headersSummary: [
				{ text: "STT", value: "STT", width: "70px", align: "center" },
				{ text: "Tên loại giải thưởng", value: "TenLoaiGiaiThuong" },
				{ text: "Số lượng giải thưởng", value: "SL_GT", align: "right" }
			],
			headersNamSummary: [
				{ text: "STT", value: "STT", width: "70px", align: "center" },
				{ text: "Năm đạt giải", value: "NamDatGiai", align: "center" },
				{ text: "Tên loại giải thưởng", value: "TenLoaiGiaiThuong" },
				{ text: "Số lượng giải thưởng", value: "SL_GT", align: "right" }
			]
		}
	},
	computed: {
		sumGiaiThuong() {
			return (this.giaiThuongSummary || []).reduce((acc, cur) => acc + (Number(cur.SL_GT) || 0), 0)
		},
		dataChartPie() {
			const rows = this.giaiThuongSummary || []
			return {
				labels: rows.map(x => x.TenLoaiGiaiThuong),
				datasets: [
					{
						data: rows.map(x => Number(x.SL_GT) || 0),
						backgroundColor: rows.map((_, idx) => this.colorPalette[idx % this.colorPalette.length])
					}
				]
			}
		},
		dataChartBar() {
			const rows = this.giaiThuongNamSummary || []
			const listNam = [...new Set(rows.map(x => x.NamDatGiai))]
			const listLoai = [...new Set(rows.map(x => x.TenLoaiGiaiThuong))]
			return {
				labels: listNam,
				datasets: listLoai.map((loai, idx) => ({
					label: loai,
					backgroundColor: this.colorPalette[idx % this.colorPalette.length],
					data: listNam.map(nam => {
						const found = rows.find(x => x.NamDatGiai === nam && x.TenLoaiGiaiThuong === loai)
						return found ? (Number(found.SL_GT) || 0) : 0
					})
				}))
			}
		},
		optionsPie() {
			return {
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					legend: { position: "bottom" },
					datalabels: {
						color: "#fff",
						font: { size: 12, weight: "bold" },
						formatter: (val) => (val > 0 ? val : "")
					}
				}
			}
		},
		optionsBar() {
			return {
				responsive: true,
				maintainAspectRatio: false,
				scales: {
					x: { stacked: true },
					y: { stacked: true }
				},
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
	watch: {
		giaiThuongSummary: {
			deep: true,
			handler() {
				this.keyPie++
			}
		},
		giaiThuongNamSummary: {
			deep: true,
			handler() {
				this.keyBar++
			}
		}
	}
	}
</script>