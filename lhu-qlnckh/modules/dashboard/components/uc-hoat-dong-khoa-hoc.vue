<template>
	<v-card outlined class="rounded-xs pa-2">
		<v-card-title class="py-2 px-3 d-flex ga-2 justify-space-between">
			<div class="d-flex flex-column ga-2 flex-grow-1">
				<div class="d-flex ga-2 align-center">
					<span class="primary--text text-subtitle-1 font-weight-bold dashboard-word-break">
						CHỈ SỐ HOẠT ĐỘNG KHOA HỌC TRONG NĂM {{ selectedYear }}:
					</span>
				</div>
				<div>
					<v-row dense>
						<v-col cols="12" md="4">
							<v-card outlined class="rounded-xs pa-2 d-flex align-center justify-space-between">
								<span class="text-body-2 grey--text text--darken-2 font-weight-medium">Tất cả:</span>
								<span class="text-h6 font-weight-bold primary--text">{{ DataCard.TatCa || 0 }}</span>
							</v-card>
						</v-col>
						<v-col cols="12" md="4">
							<v-card outlined class="rounded-xs pa-2 d-flex align-center justify-space-between">
								<span class="text-body-2 grey--text text--darken-2 font-weight-medium">Đạt:</span>
								<span class="text-h6 font-weight-bold success--text">{{ DataCard.Dat || 0 }}</span>
							</v-card>
						</v-col>
						<v-col cols="12" md="4">
							<v-card outlined class="rounded-xs pa-2 d-flex align-center justify-space-between">
								<span class="text-body-2 grey--text text--darken-2 font-weight-medium">Không đạt:</span>
								<span class="text-h6 font-weight-bold error--text">{{ DataCard.KhongDat || 0 }}</span>
							</v-card>
						</v-col>
					</v-row>
				</div>
			</div>
		</v-card-title>
		<v-card-text class="dashboard-chart-350">
			<uc-chart ref="chartHoatDongKhoaHoc" type="bar" v-if="!isLoadingChartHoatDongKhoaHoc"
				:data="DataHoatDongKhoaHoc" :options="optionHoatDongKhoaHoc" :key="chartKey"></uc-chart>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		data() {
		return {
			optionHoatDongKhoaHoc: {
				scales: {
					x: {
						stacked: true
					},
					y: {
						stacked: true
					}
				},
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					title: {
						display: false,
						text: '',
						font: {
							size: 16
						}
					},
					legend: {
						display: true
					},
					datalabels: {
						color: "#ffffff",
						font: {
							size: 18
						},
						formatter: (value) => {
							return value > 5 ? value : ''
						}
					}
				}
			},
			isLoadingChartHoatDongKhoaHoc: false,
			DataHoatDongKhoaHoc: { labels: [], datasets: [] },
			DataCard: { TatCa: 0, Dat: 0, KhongDat: 0 },
			selectedYear: new Date().getFullYear(),
			chartKey: 1
		}
	},
	async mounted() {
		await this.GET_HDKH_Admin_GetBaoCaoTongHop()
	},
	methods: {
		async GET_HDKH_Admin_GetBaoCaoTongHop() {
			this.isLoadingChartHoatDongKhoaHoc = true
			const res = await ajaxCALLPromise('/HDKH_Admin_GetBaoCaoTongHop', {
				NamHoc: this.selectedYear
			})
			const khoaGocList = (res && res[0]) ? res[0] : []
			const datList = (res && res[1]) ? res[1] : []
			const khongDatList = (res && res[2]) ? res[2] : []

			this.DataCard = {
				TatCa: datList.length + khongDatList.length,
				Dat: datList.length,
				KhongDat: khongDatList.length
			}

			const bieuDoMap = {}
			khoaGocList.forEach(item => {
				bieuDoMap[item.DonVi] = { Dat: 0, KhongDat: 0 }
			})

			datList.forEach(nv => {
				if (bieuDoMap[nv.TenDonVi]) {
					bieuDoMap[nv.TenDonVi].Dat += 1
				}
			})

			khongDatList.forEach(nv => {
				if (bieuDoMap[nv.TenDonVi]) {
					bieuDoMap[nv.TenDonVi].KhongDat += 1
				}
			})

			const labels = khoaGocList.map(item => item.DonVi)
			this.DataHoatDongKhoaHoc = {
				labels: labels,
				datasets: [
					{
						label: 'Đạt',
						data: labels.map(lbl => bieuDoMap[lbl].Dat),
						backgroundColor: '#4caf50'
					},
					{
						label: 'Không Đạt',
						data: labels.map(lbl => bieuDoMap[lbl].KhongDat),
						backgroundColor: '#f44336'
					}
				]
			}
			this.chartKey++
			this.isLoadingChartHoatDongKhoaHoc = false
		}
	}
	}
</script>