<template>
	<div>
		<uc-dcard title="II. CHUYỂN GIAO CÔNG NGHỆ" :IsShowBtnDialog="true">
			<template v-slot:renderBody>
				<v-row dense>
					<v-col cols="12" md="6">
						<uc-dchart-card title="Biểu đồ thống kê giá trị hợp đồng chuyển giao KHCN"
							elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogHopDong = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyGiaTri" :data="dataChartGiaTriHopDong" type="bar"
										:options="optionsHopDong" :plugins="pluginsHopDong"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12" md="6">
						<uc-dchart-card title="Biểu đồ thống kê số lượng hợp đồng chuyển giao KHCN qua các năm"
							:detailTitle="String(sumCGCNHopDong)" elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogHopDong = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyHopDong" :data="dataChartHopDong" type="line"
										:options="optionsHopDong" :plugins="pluginsHopDong"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12">
						<uc-dchart-card title="Đơn vị hợp tác, đối tác chuyển giao công nghệ"
							:detailTitle="String(sumCGCNDonViTiepNhan)" elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogDonVi = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyDonVi" :data="dataChartDonVi" type="bar"
										:options="optionsDonVi" :plugins="pluginsDonVi"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
				</v-row>
			</template>
		</uc-dcard>

		<uc-dialog v-model="dialogHopDong" title="Thống kê hợp đồng chuyển giao công nghệ qua các năm">
			<template v-slot:renderBody>
				<uc-dtable title="Số lượng & giá trị hợp đồng CGCN" :headers="headersHopDong" :items="itemsHopDong"
					:isSearch="true" itemKey="STT">
					<template v-slot:item.GT_HD="{ item }">
						<span>{{ Number(item.GT_HD || 0).toLocaleString('vi-VN') }}</span>
					</template>
				</uc-dtable>
			</template>
		</uc-dialog>

		<uc-dialog v-model="dialogDonVi" title="Danh sách đơn vị tiếp nhận chuyển giao công nghệ">
			<template v-slot:renderBody>
				<uc-dtable title="Đơn vị tiếp nhận CGCN" :headers="headersDonVi" :items="itemsDonVi" :isSearch="true"
					itemKey="STT">
					<template v-slot:item.GT_HD="{ item }">
						<span>{{ Number(item.GT_HD || 0).toLocaleString('vi-VN') }}</span>
					</template>
				</uc-dtable>
			</template>
		</uc-dialog>
	</div>
</template>

<script>
	export default {
		props: {
		cgcnHopDong: {
			type: Array,
			default: () => []
		},
		cgcnDonViTiepNhan: {
			type: Array,
			default: () => []
		},
		cgcnTotalCount: {
			type: Number,
			default: 0
		}
	},
	data() {
		return {
			dialogHopDong: false,
			dialogDonVi: false,
			keyGiaTri: 1,
			keyHopDong: 1,
			keyDonVi: 1,
			headersHopDong: [
				{ text: "STT", value: "STT", width: "70px", align: "center" },
				{ text: "Năm thực hiện", value: "NamThucHien", align: "center" },
				{ text: "Số lượng hợp đồng", value: "SL_HD", align: "right" },
				{ text: "Giá trị hợp đồng (VNĐ)", value: "GT_HD", align: "right" }
			],
			headersDonVi: [
				{ text: "STT", value: "STT", width: "70px", align: "center" },
				{ text: "Đơn vị tiếp nhận", value: "DonViTiepNhan" },
				{ text: "Số lượng hợp đồng", value: "SL_HD", align: "right" },
				{ text: "Giá trị hợp đồng (VNĐ)", value: "GT_HD", align: "right" }
			]
		}
	},
	computed: {
		sumCGCNHopDong() {
			if (this.cgcnTotalCount > 0) {
				return this.cgcnTotalCount
			}
			return (this.cgcnHopDong || []).reduce((acc, cur) => acc + (Number(cur.SL_HD) || 0), 0)
		},
		sumCGCNDonViTiepNhan() {
			return (this.cgcnDonViTiepNhan || []).length
		},
		itemsHopDong() {
			return (this.cgcnHopDong || []).map((item, idx) => ({
				...item,
				STT: idx + 1
			}))
		},
		itemsDonVi() {
			return (this.cgcnDonViTiepNhan || []).map((item, idx) => ({
				...item,
				STT: idx + 1
			}))
		},
		dataChartGiaTriHopDong() {
			const rows = this.cgcnHopDong || []
			return {
				labels: rows.map(x => String(x.NamThucHien)),
				datasets: [
					{
						label: "Giá trị hợp đồng",
						data: rows.map(x => Number(x.GT_HD) || 0),
						backgroundColor: "#36a2eb"
					}
				]
			}
		},
		dataChartHopDong() {
			const rows = this.cgcnHopDong || []
			return {
				labels: rows.map(x => String(x.NamThucHien)),
				datasets: [
					{
						label: "Số lượng hợp đồng",
						data: rows.map(x => Number(x.SL_HD) || 0),
						backgroundColor: "#4db8ff",
						borderColor: "#4db8ff"
					}
				]
			}
		},
		dataChartDonVi() {
			const rows = this.cgcnDonViTiepNhan || []
			return {
				labels: rows.map(x => String(x.DonViTiepNhan)),
				datasets: [
					{
						label: "Số lượng hợp đồng",
						data: rows.map(x => Number(x.SL_HD) || 0),
						backgroundColor: "#ffa64d"
					}
				]
			}
		},
		optionsHopDong() {
			return {
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					legend: { position: "bottom" },
					datalabels: {
						color: "#333",
						font: { size: 11, weight: "bold" },
						formatter: (val) => (val > 0 ? val.toLocaleString("vi-VN") : "")
					}
				}
			}
		},
		optionsDonVi() {
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
		pluginsHopDong() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		},
		pluginsDonVi() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		}
	},
	watch: {
		cgcnHopDong: {
			deep: true,
			handler() {
				this.keyGiaTri++
				this.keyHopDong++
			}
		},
		cgcnDonViTiepNhan: {
			deep: true,
			handler() {
				this.keyDonVi++
			}
		}
	}
	}
</script>