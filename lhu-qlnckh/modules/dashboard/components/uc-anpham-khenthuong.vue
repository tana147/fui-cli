<template>
	<div>
		<uc-dcard title="I. ẤN PHẨM KHOA HỌC" hrefDetailTitle="/an-pham-bai-bao" detailTitle="Xem chi tiết">
			<template v-slot:rightTitle>
				<uc-btn v-for="(btn, idx) in listButtons" :key="idx" @click="btn.click" :label="btn.label"></uc-btn>
			</template>
			<template v-slot:renderBody>
				<v-row dense>
					<v-col cols="12" md="4">
						<uc-card-item :title="cardItems[0].title" :description="cardItems[0].description"
							:trailingIcon="cardItems[0].trailingIcon"></uc-card-item>
					</v-col>
					<v-col cols="12" md="4">
						<uc-card-item :title="cardItems[1].title" :description="cardItems[1].description"
							:trailingIcon="cardItems[1].trailingIcon"></uc-card-item>
					</v-col>
					<v-col cols="12" md="4">
						<uc-card-item :title="cardItems[2].title" :description="cardItems[2].description"
							:trailingIcon="cardItems[2].trailingIcon"></uc-card-item>
					</v-col>
				</v-row>
				<v-row dense class="mt-2">
					<v-col cols="12" md="4">
						<uc-dchart-card title="Thống kê ấn phẩm trong nước và quốc tế" elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="openDialogData('Trong nước')" label="Trong nước" class="mr-2"></uc-btn>
								<uc-btn @click="openDialogData('Quốc tế')" label="Quốc tế"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-pie">
									<uc-chart :key="keyChartPie1" :data="dataChartPie" type="pie"
										:options="optionPieChart" :plugins="pluginsPieChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12" md="8">
						<uc-dchart-card title="Thống kê bài báo qua các năm" elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogTableDetail = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyChartBar" :data="dataChartBar" type="bar"
										:options="optionBarChart" :plugins="pluginsBarChart"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
				</v-row>
				<v-row dense class="mt-2">
					<v-col cols="12" md="4">
						<uc-dchart-card title="Số bài báo khoa học phân theo đơn vị" :detailTitle="String(sumSLBaiBao || 0)"
							elevation="elevation-0">
							<template v-slot:leftTitle>
								<v-select v-model="LoaiAnPhamID" :items="Data_LoaiAnPham" item-text="TenLoaiAnPham"
									item-value="LoaiAnPhamID" label="Danh mục bài báo/ấn phẩm" dense outlined
									hide-details class="mt-2 dashboard-select-loai"></v-select>
							</template>
							<template v-slot:rightTitle>
								<uc-btn @click="openDialogTableDataPieChart" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-pie">
									<uc-chart :key="keyChartPie2" :data="dataPieChartNhomDonVi" type="pie"
										:options="optionPieChartNhomDonVi"
										:plugins="pluginsPieChartNhomDonVi"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
					<v-col cols="12" md="8">
						<uc-dchart-card title="Biểu đồ thống kê các ấn phẩm Khoa học Công nghệ" elevation="elevation-0">
							<template v-slot:rightTitle>
								<uc-btn @click="dialogDetailSummary = true" label="Số liệu chi tiết"></uc-btn>
							</template>
							<template v-slot:checkboxShowNumber>
								<v-checkbox v-model="isShowAllLabelBarChart" label="Hiển thị số trên biểu đồ" dense
									hide-details class="mt-1"></v-checkbox>
							</template>
							<template v-slot:renderBody>
								<div class="dashboard-chart-container">
									<uc-chart :key="keyChartColumnDetail" :data="dataBarChartColumnDetailSummary"
										type="bar" :options="optionsBarChartColumnDetailSummary"
										:plugins="pluginsBarChartColumnDetailSummary"></uc-chart>
								</div>
							</template>
						</uc-dchart-card>
					</v-col>
				</v-row>
			</template>
		</uc-dcard>

		<uc-dialog v-model="dialogDetailSummary" title="Số liệu chi tiết theo loại ấn phẩm">
			<template v-slot:renderBody>
				<uc-dtable title="Danh sách chi tiết" :headers="headersDetailSummary" :items="anPhamDetailSummary"
					:isSearch="true" itemKey="STT"></uc-dtable>
			</template>
		</uc-dialog>

		<uc-dialog v-model="dialogTableDataPieChart" :title="titleTenLoaiAnPham">
			<template v-slot:renderBody>
				<uc-dtable title="Số bài báo khoa học phân theo đơn vị" :headers="headersPieChartNhomDonVi"
					:items="Data_Summary_ByLoaiAnPhamID" :isSearch="true" itemKey="STT"></uc-dtable>
			</template>
		</uc-dialog>

		<uc-dialog v-model="dialogData" :title="titleDialogData">
			<template v-slot:renderBody>
				<uc-dtable :title="titleDialogData" :headers="headerDialogData" :items="itemsDialogData"
					:isSearch="true" itemKey="TenLoaiAnPham"></uc-dtable>
			</template>
		</uc-dialog>

		<uc-dialog v-model="dialogTableDetail" title="Số liệu chi tiết bài báo khoa học">
			<template v-slot:renderBody>
				<uc-dtable title="Số liệu chi tiết bài báo khoa học" :headers="headersTableDetail"
					:items="Data_SoLieuCT" :isSearch="true" itemKey="SoThuTu"></uc-dtable>
			</template>
		</uc-dialog>
	</div>
</template>

<script>
	export default {
		props: {
		anPhamSummary: {
			type: Object,
			default: () => ({ SL_Tong: 0, SL_TrongNuoc: 0, SL_QuocTe: 0 })
		},
		anPhamQuocTeDetailSummary: {
			type: Array,
			default: () => []
		},
		anPhamTrongNuocDetailSummary: {
			type: Array,
			default: () => []
		},
		anPhamColumnDetailSummary: {
			type: Array,
			default: () => []
		},
		anPhamDetailSummary: {
			type: Array,
			default: () => []
		}
	},
	data() {
		return {
			colorPalette: {
				0: "#ff6384",
				1: "#ffb1c1",
				2: "#36a2eb",
				3: "#ffe6aa",
				4: "#a5dfdf",
				5: "#ccb2ff",
				6: "#e4e5e7",
				7: "#a0d911",
				8: "#13c2c2",
				9: "#eb2f96",
				10: "#ffcf9f"
			},
			ColorTrongNuoc: "#4db8ff",
			ColorQuocTe: "#ffa64d",
			Data_BBKH: [],
			Data_SoLieuCT: [],
			Data_LoaiAnPham: [],
			LoaiAnPhamID: 1,
			Data_Summary_ByLoaiAnPhamID: [],
			sumSLBaiBao: 0,
			titleTenLoaiAnPham: "",
			isShowAllLabelBarChart: false,
			dialogDetailSummary: false,
			dialogTableDataPieChart: false,
			dialogData: false,
			dialogTableDetail: false,
			titleDialogData: "",
			itemsDialogData: [],
			keyChartPie1: 1,
			keyChartPie2: 1,
			keyChartBar: 1,
			keyChartColumnDetail: 1,
			headerDialogData: [
				{ text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" },
				{ text: "Số lượng bài báo", value: "SL_BB", align: "right" }
			],
			headersDetailSummary: [
				{ text: "STT", value: "STT", width: "70px", align: "center" },
				{ text: "Năm", value: "Nam", align: "center" },
				{ text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" },
				{ text: "Số lượng bài báo", value: "SL_BB", align: "right" }
			],
			headersPieChartNhomDonVi: [
				{ text: "STT", value: "STT", width: "70px", align: "center" },
				{ text: "Đơn vị / Nhóm", value: "Col_Name" },
				{ text: "Số lượng bài báo", value: "SL_BB", align: "right" }
			],
			headersTableDetail: [
				{ text: "STT", value: "SoThuTu", width: "70px", align: "center" },
				{ text: "Tên tác giả", value: "TenTacGia" },
				{ text: "Đơn vị", value: "TenDonVi" },
				{ text: "Tên bài báo", value: "TenBaiBao" },
				{ text: "Tên tạp chí/ Hội thảo", value: "TenTapChiHoiThao" },
				{ text: "Năm học", value: "NamHoc", width: "120px", align: "center" },
				{ text: "Nơi đăng", value: "NoiDang" },
				{ text: "Thể loại", value: "TheLoai" },
				{ text: "Ghi chú", value: "GhiChu" }
			]
		}
	},
	computed: {
		listButtons() {
			return [
				{
					label: "Tra cứu tạp chí",
					click: () => window.open("https://www.scimagojr.com/", "_blank")
				}
			]
		},
		cardItems() {
			return [
				{
					title: "TỔNG ẤN PHẨM KHOA HỌC",
					description: this.anPhamSummary?.SL_Tong || 0,
					trailingIcon: "mdi-book-open-page-variant-outline"
				},
				{
					title: "ẤN PHẨM TRONG NƯỚC",
					description: this.anPhamSummary?.SL_TrongNuoc || 0,
					trailingIcon: "mdi-book-outline"
				},
				{
					title: "ẤN PHẨM QUỐC TẾ",
					description: this.anPhamSummary?.SL_QuocTe || 0,
					trailingIcon: "mdi-earth"
				}
			]
		},
		dataChartPie() {
			return {
				labels: ["Trong nước", "Quốc tế"],
				datasets: [
					{
						data: [
							this.anPhamSummary?.SL_TrongNuoc || 0,
							this.anPhamSummary?.SL_QuocTe || 0
						],
						backgroundColor: [this.ColorTrongNuoc, this.ColorQuocTe]
					}
				]
			}
		},
		optionPieChart() {
			return {
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					legend: { position: "bottom" },
					datalabels: {
						color: "#fff",
						font: { weight: "bold", size: 13 },
						formatter: (value) => (value > 0 ? value : "")
					}
				}
			}
		},
		pluginsPieChart() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		},
		dataChartBar() {
			const labels = this.Data_BBKH.map(x => x.NamHoc)
			const listTong = this.Data_BBKH.map(x => Number(x.SL_Tong) || 0)
			const listTrongNuoc = this.Data_BBKH.map(x => Number(x.SL_TrongNuoc) || 0)
			const listQuocTe = this.Data_BBKH.map(x => Number(x.SL_QuocTe) || 0)
			return {
				labels,
				datasets: [
					{
						label: "Tổng số bài báo",
						data: listTong,
						backgroundColor: "#36a2eb"
					},
					{
						label: "Bài đăng trong nước",
						data: listTrongNuoc,
						backgroundColor: this.ColorTrongNuoc
					},
					{
						label: "Bài đăng quốc tế",
						data: listQuocTe,
						backgroundColor: this.ColorQuocTe
					}
				]
			}
		},
		optionBarChart() {
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
		pluginsBarChart() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		},
		dataPieChartNhomDonVi() {
			const labels = this.Data_Summary_ByLoaiAnPhamID.map(x => x.Col_Name)
			const data = this.Data_Summary_ByLoaiAnPhamID.map(x => Number(x.SL_BB) || 0)
			const colors = labels.map((_, idx) => this.colorPalette[idx % 11])
			return {
				labels,
				datasets: [
					{
						data,
						backgroundColor: colors
					}
				]
			}
		},
		optionPieChartNhomDonVi() {
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
		pluginsPieChartNhomDonVi() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		},
		dataBarChartColumnDetailSummary() {
			const labels = [...new Set((this.anPhamDetailSummary || []).map(item => String(item.Nam)))]
			const datasetLines = (this.anPhamDetailSummary || []).reduce((acc, item) => {
				const { TenLoaiAnPham, SL_BB, LoaiAnPhamID } = item
				const existingItem = acc.find(entry => entry.label === TenLoaiAnPham)
				if (existingItem) {
					existingItem.data.push(SL_BB)
				} else {
					const color = this.colorPalette[(Number(LoaiAnPhamID) || 0) % 11]
					acc.push({
						label: TenLoaiAnPham,
						data: [SL_BB],
						type: "line",
						backgroundColor: color,
						borderColor: color
					})
				}
				return acc
			}, [])

			const trongNuocData = (this.anPhamColumnDetailSummary || []).map(item => item.SL_TrongNuoc)
			const quocTeData = (this.anPhamColumnDetailSummary || []).map(item => item.SL_QuocTe)
			const datasetColumn = [
				{
					label: "Trong nước",
					data: trongNuocData,
					stack: "combined",
					type: "bar",
					backgroundColor: this.ColorTrongNuoc,
					borderColor: this.ColorTrongNuoc
				},
				{
					label: "Quốc tế",
					data: quocTeData,
					stack: "combined",
					type: "bar",
					backgroundColor: this.ColorQuocTe,
					borderColor: this.ColorQuocTe
				}
			]

			return {
				labels,
				datasets: [...datasetLines, ...datasetColumn]
			}
		},
		optionsBarChartColumnDetailSummary() {
			const showAll = this.isShowAllLabelBarChart
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
						display: showAll,
						color: "#333",
						font: { size: 11, weight: "bold" },
						formatter: (val) => (val > 0 ? val : "")
					}
				}
			}
		},
		pluginsBarChartColumnDetailSummary() {
			return typeof ChartDataLabels !== "undefined" ? [ChartDataLabels] : []
		}
	},
	watch: {
		anPhamSummary: {
			deep: true,
			handler() {
				this.keyChartPie1++
			}
		},
		anPhamColumnDetailSummary: {
			deep: true,
			handler() {
				this.keyChartColumnDetail++
			}
		},
		anPhamDetailSummary: {
			deep: true,
			handler() {
				this.keyChartColumnDetail++
			}
		},
		isShowAllLabelBarChart() {
			this.keyChartColumnDetail++
		},
		LoaiAnPhamID() {
			this.fetchSummaryByLoaiAnPham()
		}
	},
	async mounted() {
		await Promise.all([
			this.fetchBBKHGroupByNamHoc(),
			this.fetchLoaiAnPham()
		])
	},
	methods: {
		async fetchBBKHGroupByNamHoc() {
			const res = await ajaxCALLPromise("/RPT_BBKH_GroupBy_NamHoc", {})
			this.Data_BBKH = (res && res[0]) ? res[0] : []
			const rawSoLieu = (res && res[1]) ? res[1] : []
			this.Data_SoLieuCT = rawSoLieu.map((item, idx) => ({
				...item,
				SoThuTu: item.SoThuTu || (idx + 1)
			}))
			this.keyChartBar++
		},
		async fetchLoaiAnPham() {
			const res = await ajaxCALLPromise("/AnPham_LoaiAnPham_Get", {})
			const list = Array.isArray(res) ? res : []
			this.Data_LoaiAnPham = list
			if (list.length > 0 && !this.LoaiAnPhamID) {
				this.LoaiAnPhamID = list[0].LoaiAnPhamID
			}
			await this.fetchSummaryByLoaiAnPham()
		},
		async fetchSummaryByLoaiAnPham() {
			if (this.LoaiAnPhamID === null || this.LoaiAnPhamID === undefined) return
			const res = await ajaxCALLPromise("/RPT_BBKH_Summary_ByLoaiAnPhamID", {
				LoaiAnPhamID: this.LoaiAnPhamID
			})
			const rows = Array.isArray(res) ? res : []
			this.Data_Summary_ByLoaiAnPhamID = rows.map((item, idx) => ({
				...item,
				STT: idx + 1
			}))
			this.sumSLBaiBao = rows.reduce((acc, cur) => acc + (Number(cur.SL_BB) || 0), 0)
			this.keyChartPie2++
		},
		openDialogData(type) {
			this.titleDialogData = "Thống kê ấn phẩm " + type
			this.itemsDialogData = type === "Trong nước"
				? this.anPhamTrongNuocDetailSummary
				: this.anPhamQuocTeDetailSummary
			this.dialogData = true
		},
		openDialogTableDataPieChart() {
			const found = this.Data_LoaiAnPham.find(x => x.LoaiAnPhamID === this.LoaiAnPhamID)
			this.titleTenLoaiAnPham = "Số bài báo khoa học phân theo đơn vị - " + (found ? found.TenLoaiAnPham : "")
			this.dialogTableDataPieChart = true
		}
	}
	}
</script>