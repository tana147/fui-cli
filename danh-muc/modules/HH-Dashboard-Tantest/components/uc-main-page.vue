<template>
	<z-layout class="hh-dashboard-page">
		<v-app-bar density="compact" :elevation="0" class="border-b px-2">
			<template v-slot:prepend>
				<v-icon class="mr-2">mdi-view-dashboard-outline</v-icon>
			</template>
			<v-app-bar-title>Dashboard điều hành kho</v-app-bar-title>
			<template v-slot:append>
				<v-btn color="primary" variant="flat" prepend-icon="mdi-refresh" :loading="loading"
					@click="reloadDashboard()">
					Làm mới mock data
				</v-btn>
			</template>
		</v-app-bar>

		<div class="dashboard-shell">
			<uc-dashboard-filter :filter="filter" :location-options="locationOptions" :loading="loading"
				@change-filter="handleChangeFilter" @reload="reloadDashboard" />

			<uc-dashboard-stats :stats-data="statsData" :focus-key="focusKey" :loading="loading"
				@select-section="handleSelectSection" />

			<v-card class="dashboard-tab-shell" elevation="0">
				<v-tabs v-model="activeTab" color="primary" density="comfortable" class="dashboard-tabs" grow>
					<v-tab value="ACTION">Ưu tiên xử lý</v-tab>
					<v-tab value="ALERT">Cảnh báo</v-tab>
					<v-tab value="TREND">Xu hướng</v-tab>
					<v-tab value="RECENT">Giao dịch gần đây</v-tab>
				</v-tabs>

				<v-window v-model="activeTab" class="dashboard-window">
					<v-window-item value="ACTION" class="dashboard-window-item">
						<div class="dashboard-tab-panel">
							<uc-dashboard-action-center :action-items="actionItems" :focus-key="focusKey"
								:loading="loading" @select-action="handleSelectSection" />
						</div>
					</v-window-item>

					<v-window-item value="ALERT" class="dashboard-window-item">
						<div class="dashboard-tab-panel">
							<uc-dashboard-alerts :alert-rows="filteredAlertRows" :loading="loading"
								@select-alert="handleSelectAlert" />
						</div>
					</v-window-item>

					<v-window-item value="TREND" class="dashboard-window-item">
						<div class="dashboard-tab-panel">
							<uc-dashboard-overview :focus-key="focusKey" :trend-data="trendData" :recent-rows="[]"
								:insight-data="insightData" :loading="loading" @open-section="handleSelectSection" />
						</div>
					</v-window-item>

					<v-window-item value="RECENT" class="dashboard-window-item">
						<div class="dashboard-tab-panel">
							<uc-dashboard-overview :focus-key="focusKey" :trend-data="[]"
								:recent-rows="filteredRecentRows" :insight-data="insightData" :loading="loading"
								@open-section="handleSelectSection" />
						</div>
					</v-window-item>
				</v-window>
			</v-card>
		</div>
	</z-layout>
</template>

<script>
	export default {
	name: 'uc-main-page',
	data() {
		return {
			loading: false,

			filter: {
				DateRange: 'THANG_NAY',
				DiaDiem_Id: 0,
			},

			statsData: [],
			actionItems: [],
			alertRows: [],
			recentRows: [],
			trendData: [],
			insightData: {},

			focusKey: 'ALL',
			activeTab: 'ACTION',

			locationOptions: [
				{ DiaDiem_Id: 0, TenDiaDiem: 'Tất cả kho' },
				{ DiaDiem_Id: 1, TenDiaDiem: 'Kho trung tâm' },
				{ DiaDiem_Id: 2, TenDiaDiem: 'Kho sản xuất' },
				{ DiaDiem_Id: 3, TenDiaDiem: 'Kho chi nhánh' },
			],
		}
	},
	mounted() {
		this.reloadDashboard()
	},
	computed: {
		filteredAlertRows() {
			if (this.focusKey === 'ALL') return this.alertRows
			return this.alertRows.filter((item) => item.GroupKey === this.focusKey)
		},
		filteredRecentRows() {
			if (this.focusKey === 'ALL') return this.recentRows
			return this.recentRows.filter((item) => item.GroupKey === this.focusKey)
		},
	},
	methods: {
		createBaseMockData() {
			return {
				stats: [
					{
						Key: 'TON_KHO',
						Title: 'Tồn kho hiện tại',
						Value: 1284,
						SubText: '92 mã hàng đang hoạt động',
						Icon: 'mdi-package-variant-closed',
						Color: 'primary',
					},
					{
						Key: 'SAP_HET',
						Title: 'Hàng sắp hết',
						Value: 18,
						SubText: '6 mã cần nhập gấp trong 3 ngày',
						Icon: 'mdi-alert-outline',
						Color: 'orange-darken-2',
					},
					{
						Key: 'CHO_DUYET',
						Title: 'Yêu cầu chờ duyệt',
						Value: 7,
						SubText: '4 phiếu nhập, 3 phiếu kiểm kê',
						Icon: 'mdi-timer-sand',
						Color: 'amber-darken-2',
					},
					{
						Key: 'XUAT_TRONG_NGAY',
						Title: 'Xuất trong ngày',
						Value: 26,
						SubText: 'Tăng 12% so với hôm qua',
						Icon: 'mdi-export',
						Color: 'teal-darken-1',
					},
				],
				actionItems: [
					{
						Id: 1,
						Key: 'SAP_HET',
						Title: 'Cần nhập gấp hôm nay',
						Value: 6,
						Unit: 'mã hàng',
						Description: 'Ưu tiên nhóm đóng gói và tiêu hao sản xuất',
						ActionText: 'Xem danh sách cần nhập',
						Icon: 'mdi-cart-arrow-down',
						Tone: 'danger',
					},
					{
						Id: 2,
						Key: 'CHO_DUYET',
						Title: 'Phiếu chờ duyệt',
						Value: 7,
						Unit: 'phiếu',
						Description: 'Có 2 phiếu vượt thời gian xử lý mục tiêu',
						ActionText: 'Mở hàng đợi duyệt',
						Icon: 'mdi-clipboard-clock-outline',
						Tone: 'warning',
					},
					{
						Id: 3,
						Key: 'TON_KHO',
						Title: 'Điểm cần rà soát tồn',
						Value: 9,
						Unit: 'điểm',
						Description: 'Mã đứng kho 14 ngày, nên kiểm tra luân chuyển',
						ActionText: 'Xem chi tiết tồn kho',
						Icon: 'mdi-magnify-scan',
						Tone: 'info',
					},
				],
				alertRows: [
					{
						Id: 1,
						GroupKey: 'SAP_HET',
						Level: 'Khẩn',
						Title: 'Dây rút nhựa trắng xuống dưới tồn tối thiểu',
						Description: 'Kho trung tâm còn 12, định mức tối thiểu 30',
						ActionText: 'Mở danh sách hàng sắp hết',
						DueText: 'Cần xử lý trước 15:00',
						ImpactText: 'Nguy cơ dừng đóng gói ca chiều',
						Severity: 'danger',
						LocationText: 'Kho trung tâm',
					},
					{
						Id: 2,
						GroupKey: 'CHO_DUYET',
						Level: 'Chờ duyệt',
						Title: 'Phiếu nhập PN-240327-04 đang chờ xác nhận',
						Description: 'Kho sản xuất, tạo lúc 09:15',
						ActionText: 'Mở danh sách yêu cầu',
						DueText: 'Quá SLA 45 phút',
						ImpactText: 'Chậm cấp hàng cho tổ sản xuất',
						Severity: 'warning',
						LocationText: 'Kho sản xuất',
					},
					{
						Id: 3,
						GroupKey: 'TON_KHO',
						Level: 'Theo dõi',
						Title: 'Có 9 mã hàng không phát sinh 14 ngày gần nhất',
						Description: 'Cần rà soát tồn ứ hoặc chuyển kho',
						ActionText: 'Mở danh sách tồn kho',
						DueText: 'Rà soát trong ngày',
						ImpactText: 'Chiếm dung lượng lưu kho không cần thiết',
						Severity: 'info',
						LocationText: 'Toàn hệ thống',
					},
					{
						Id: 4,
						GroupKey: 'XUAT_TRONG_NGAY',
						Level: 'Biến động',
						Title: 'Xuất kho tăng mạnh ở nhóm vật tư đóng gói',
						Description: 'Tăng 32% so với trung bình 7 ngày',
						ActionText: 'Xem giao dịch gần đây',
						DueText: 'Theo dõi đến hết ca',
						ImpactText: 'Có thể kéo theo thiếu hụt ngày mai',
						Severity: 'warning',
						LocationText: 'Kho trung tâm',
					},
				],
				recentRows: [
					{
						Id: 1,
						GroupKey: 'CHO_DUYET',
						TimeText: '10:15',
						TypeText: 'Phiếu nhập',
						Code: 'PN-240327-04',
						LocationText: 'Kho sản xuất',
						StatusText: 'Chờ duyệt',
						ValueText: '12 mặt hàng',
					},
					{
						Id: 2,
						GroupKey: 'XUAT_TRONG_NGAY',
						TimeText: '09:40',
						TypeText: 'Phiếu xuất',
						Code: 'PX-240327-11',
						LocationText: 'Kho trung tâm',
						StatusText: 'Đã xuất',
						ValueText: '36 đơn vị',
					},
					{
						Id: 3,
						GroupKey: 'SAP_HET',
						TimeText: '08:55',
						TypeText: 'Cảnh báo tồn',
						Code: 'VT-DAYRUT-002',
						LocationText: 'Kho trung tâm',
						StatusText: 'Dưới ngưỡng',
						ValueText: 'Còn 12',
					},
					{
						Id: 4,
						GroupKey: 'TON_KHO',
						TimeText: '08:20',
						TypeText: 'Kiểm kê',
						Code: 'KK-240327-02',
						LocationText: 'Kho chi nhánh',
						StatusText: 'Đang mở',
						ValueText: '48 mục',
					},
					{
						Id: 5,
						GroupKey: 'XUAT_TRONG_NGAY',
						TimeText: '07:50',
						TypeText: 'Phiếu xuất',
						Code: 'PX-240327-07',
						LocationText: 'Kho sản xuất',
						StatusText: 'Đã xuất',
						ValueText: '18 đơn vị',
					},
				],
				trendData: [
					{ Label: 'T2', Nhap: 42, Xuat: 28, CanhBao: 4 },
					{ Label: 'T3', Nhap: 35, Xuat: 26, CanhBao: 5 },
					{ Label: 'T4', Nhap: 44, Xuat: 31, CanhBao: 6 },
					{ Label: 'T5', Nhap: 40, Xuat: 29, CanhBao: 4 },
					{ Label: 'T6', Nhap: 52, Xuat: 36, CanhBao: 7 },
					{ Label: 'T7', Nhap: 38, Xuat: 20, CanhBao: 3 },
				],
				insights: {
					NHAP: {
						Title: 'Nhập kho',
						Summary: 'T6 là đỉnh nhập, chủ yếu từ nhóm vật tư sản xuất.',
						SubText: 'Nên dồn lịch nhận hàng trước 11:00 để tránh nghẽn cuối ngày.',
					},
					XUAT: {
						Title: 'Xuất kho',
						Summary: 'Biến động xuất tăng tập trung ở kho trung tâm.',
						SubText: 'Nếu giữ nhịp hiện tại, một số mã tiêu hao sẽ chạm ngưỡng vào ngày mai.',
					},
					CANH_BAO: {
						Title: 'Cảnh báo',
						Summary: 'Số cảnh báo tăng mạnh ở giữa tuần rồi hạ về cuối tuần.',
						SubText: 'Nên chốt lịch rà soát tồn tối thiểu vào sáng T5.',
					},
				},
			}
		},

		applyFilterToMockData(baseData) {
			const locationFactorMap = {
				0: 1,
				1: 1.15,
				2: 0.82,
				3: 0.67,
			}
			const dateFactorMap = {
				HOM_NAY: 0.35,
				'7_NGAY': 0.78,
				THANG_NAY: 1,
			}

			const locationFactor = locationFactorMap[this.filter.DiaDiem_Id] ?? 1
			const dateFactor = dateFactorMap[this.filter.DateRange] ?? 1
			const displayLocation = this.getLocationName(this.filter.DiaDiem_Id)

			const stats = baseData.stats.map((item) => {
				const nextValue = Math.max(1, Math.round(item.Value * locationFactor * dateFactor))
				return {
					...item,
					Value: nextValue,
					SubText: this.buildStatSubText(item.Key, displayLocation, nextValue),
				}
			})

			const actionItems = baseData.actionItems.map((item, index) => {
				const nextValue = Math.max(1, Math.round(item.Value * locationFactor * dateFactor))
				return {
					...item,
					Id: index + 1,
					Value: nextValue,
					Description: this.decorateWithLocation(item.Description, displayLocation),
				}
			})

			const alertRows = baseData.alertRows.map((item, index) => {
				return {
					...item,
					Id: index + 1,
					Description: this.decorateWithLocation(item.Description, displayLocation),
					LocationText: this.filter.DiaDiem_Id === 0 ? item.LocationText : displayLocation,
				}
			})

			const recentRows = baseData.recentRows.map((item, index) => {
				return {
					...item,
					Id: index + 1,
					LocationText: this.filter.DiaDiem_Id === 0 ? item.LocationText : displayLocation,
				}
			})

			const trendData = baseData.trendData.map((item) => {
				return {
					Label: item.Label,
					Nhap: Math.max(1, Math.round(item.Nhap * locationFactor * dateFactor)),
					Xuat: Math.max(1, Math.round(item.Xuat * locationFactor * dateFactor)),
					CanhBao: Math.max(1, Math.round(item.CanhBao * (2 - locationFactor / 2))),
				}
			})

			const insightData = {
				NHAP: {
					Title: baseData.insights.NHAP.Title,
					Summary: this.decorateWithLocation(baseData.insights.NHAP.Summary, displayLocation),
					SubText: baseData.insights.NHAP.SubText,
				},
				XUAT: {
					Title: baseData.insights.XUAT.Title,
					Summary: this.decorateWithLocation(baseData.insights.XUAT.Summary, displayLocation),
					SubText: baseData.insights.XUAT.SubText,
				},
				CANH_BAO: {
					Title: baseData.insights.CANH_BAO.Title,
					Summary: this.decorateWithLocation(baseData.insights.CANH_BAO.Summary, displayLocation),
					SubText: baseData.insights.CANH_BAO.SubText,
				},
			}

			return {
				stats,
				actionItems,
				alertRows,
				recentRows,
				trendData,
				insightData,
			}
		},

		buildStatSubText(key, locationName, value) {
			if (key === 'TON_KHO') return locationName + ' đang giữ ' + value + ' đơn vị'
			if (key === 'SAP_HET') return locationName + ' có ' + value + ' điểm cần bổ sung'
			if (key === 'CHO_DUYET') return locationName + ' còn ' + value + ' yêu cầu mở'
			if (key === 'XUAT_TRONG_NGAY') return locationName + ' phát sinh ' + value + ' lượt xuất'
			return locationName
		},

		decorateWithLocation(text, locationName) {
			if (this.filter.DiaDiem_Id === 0) return text
			return text + ' tại ' + locationName.toLowerCase()
		},

		getLocationName(diaDiemId) {
			const item = this.locationOptions.find((location) => location.DiaDiem_Id === diaDiemId)
			return item ? item.TenDiaDiem : 'Tất cả kho'
		},

		async reloadDashboard() {
			this.loading = true
			try {
				const baseData = this.createBaseMockData()
				const dashboardData = this.applyFilterToMockData(baseData)
				this.statsData = dashboardData.stats
				this.actionItems = dashboardData.actionItems
				this.alertRows = dashboardData.alertRows
				this.recentRows = dashboardData.recentRows
				this.trendData = dashboardData.trendData
				this.insightData = dashboardData.insightData
			} finally {
				this.loading = false
			}
		},

		handleChangeFilter(payload) {
			this.filter = {
				DateRange: payload.DateRange,
				DiaDiem_Id: payload.DiaDiem_Id,
			}
			this.focusKey = 'ALL'
			this.reloadDashboard()
		},

		handleSelectSection(key) {
			this.focusKey = key || 'ALL'
		},

		handleSelectAlert(item) {
			this.focusKey = item?.GroupKey || 'ALL'
		},
	},
}
</script>