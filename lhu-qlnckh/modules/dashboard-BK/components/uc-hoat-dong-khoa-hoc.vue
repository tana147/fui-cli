<template>
	<v-card class="elevation-0 rounded-sm pa-2" style="border: 0.8px solid #8080803d">
		<v-card-title class="d-flex ga-2 justify-space-between">
			<div class="d-flex flex-column ga-2" style="width:100%">
				<div class="d-flex ga-2 align-center" style="width:100%">
					<span class="primary--text" style="word-break: break-word;">
						CHỈ SỐ HOẠT ĐỘNG KHOA HỌC TRONG NĂM {{this.selectedYear}}:
					</span>
				</div>
				<div style="width:100%">
					<v-row dense>
						<v-col cols="12" md="4">
							<uc-card-item title="Tất cả:" :description="DataCard.TatCa" trailingIcon="mdi-earth"
								styleDescription="font-size: 20px " styleTitle="font-size: 18px !important"
								:isCustom='true' style="background-color:rgb(228 240 245)"></uc-card-item>
						</v-col>
						<v-col cols="12" md="4">
							<uc-card-item title="Đạt:" :description="DataCard.Dat" trailingIcon="mdi-earth"
								styleDescription="font-size: 20px ; color:white !important"
								styleTitle="font-size: 18px !important; color:white !important" :isCustom='true'
								style="background-color: green;"></uc-card-item>
						</v-col>
						<v-col cols="12" md="4">
							<uc-card-item title="Không đạt:" :description="DataCard.KhongDat" trailingIcon="mdi-earth"
								styleDescription="font-size: 20px ; color:white !important"
								styleTitle="font-size: 18px !important; color:white !important" :isCustom='true'
								style="background-color: rgb(241 2 2);"></uc-card-item>
						</v-col>
					</v-row>

				</div>
			</div>
		</v-card-title>
		<v-card-text style="height: 350px;">
			<uc-chart ref="chartHoatDongKhoaHoc" type="bar" v-if="!isLoadingChartHoatDongKhoaHoc"
				:data="DataHoatDongKhoaHoc" :options="optionHoatDongKhoaHoc" :key="vueData.keyComp"></uc-chart>
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
							stacked: true,
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
							text: ``,
							font: {
								size: 16,
							}
						},
						legend: {
							display: true,
						},
						datalabels: {
							color: "#ffffff",
							font: {
								size: 18,
							},
							formatter: (value, context) => {
								if (value > 5) {
									return value
								} else {
									return ''
								}
							}
						},
					},
				},
				isLoadingChartHoatDongKhoaHoc: false,
				DataHoatDongKhoaHoc: [],
				vueData,
				DataCard: {},
				selectedYear: new Date().getFullYear()
			}
		},
		async mounted() {
	
			await this.GET_HDKH_Admin_GetBaoCaoTongHop()
		},
		methods: {
			async GET_HDKH_Admin_GetBaoCaoTongHop() {
				vueData.isLoadingChartHoatDongKhoaHoc = true
				await ajaxCALL('/HDKH_Admin_GetBaoCaoTongHop', {
					NamHoc: this.selectedYear
				}, res => {
					const khoaGocList = res.data[0] || [];
					const datList = res.data[1] || [];
					const khongDatList = res.data[2] || [];
	
					this.DataCard = {
						TatCa: datList.length + khongDatList.length,
						Dat: datList.length,
						KhongDat: khongDatList.length
					};
	
					const bieuDoMap = {};
					khoaGocList.forEach(item => {
						bieuDoMap[item.DonVi] = { Dat: 0, KhongDat: 0 };
					});
	
					datList.forEach(nv => {
						if (bieuDoMap[nv.TenDonVi]) {
							bieuDoMap[nv.TenDonVi].Dat += 1;
						}
					});
	
					khongDatList.forEach(nv => {
						if (bieuDoMap[nv.TenDonVi]) {
							bieuDoMap[nv.TenDonVi].KhongDat += 1;
						}
					});
	
					const labels = khoaGocList.map(item => item.DonVi);
					this.DataHoatDongKhoaHoc = {
						labels: labels,
						datasets: [
							{
								label: 'Đạt',
								data: labels.map(lbl => bieuDoMap[lbl].Dat),
							},
							{
								label: 'Không Đạt',
								data: labels.map(lbl => bieuDoMap[lbl].KhongDat),
							}
						]
					};
				}
				)
				vueData.isLoadingChartHoatDongKhoaHoc = false
			}
		}
	}
</script>