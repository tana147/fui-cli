<template>
	<v-row dense class="dashboard-overview-grid">
		<v-col v-if="trendData.length > 0" cols="12" :lg="recentRows.length > 0 ? 5 : 12">
			<v-card class="dashboard-panel dashboard-panel-fill dashboard-chart-panel" elevation="0">
				<v-card-text class="pa-4">
					<div class="d-flex justify-space-between align-center mb-4">
						<div class="dashboard-section-title">Xu hướng 6 mốc gần nhất</div>
						<div class="dashboard-section-caption">Nhập / Xuất / Cảnh báo</div>
					</div>

					<div class="dashboard-trend-tabs mb-4">
						<v-btn size="small" :variant="activeMetric === 'NHAP' ? 'flat' : 'outlined'" color="primary"
							@click="setActiveMetric('NHAP')">
							Nhập
						</v-btn>
						<v-btn size="small" :variant="activeMetric === 'XUAT' ? 'flat' : 'outlined'"
							color="teal-darken-1" @click="setActiveMetric('XUAT')">
							Xuất
						</v-btn>
						<v-btn size="small" :variant="activeMetric === 'CANH_BAO' ? 'flat' : 'outlined'"
							color="orange-darken-2" @click="setActiveMetric('CANH_BAO')">
							Cảnh báo
						</v-btn>
					</div>

					<v-card class="dashboard-insight-card mb-4" elevation="0">
						<v-card-text class="pa-3">
							<div class="dashboard-insight-title">{{ currentInsight.Title }}</div>
							<div class="dashboard-insight-summary">{{ currentInsight.Summary }}</div>
							<div class="dashboard-insight-subtext">{{ currentInsight.SubText }}</div>
						</v-card-text>
					</v-card>

					<div v-for="item in trendData" :key="item.Label" class="dashboard-trend-row">
						<div class="dashboard-trend-label">{{ item.Label }}</div>
						<div class="dashboard-trend-bars">
							<div class="dashboard-trend-bar-wrap">
								<div class="dashboard-trend-bar dashboard-trend-bar-blue"
									:class="{ 'dashboard-trend-bar-focus': activeMetric === 'NHAP' && item.Nhap === maxNhap }"
									:style="getBarStyle(item.Nhap, maxNhap)">
									<span>{{ item.Nhap }}</span>
								</div>
							</div>
							<div class="dashboard-trend-bar-wrap">
								<div class="dashboard-trend-bar dashboard-trend-bar-green"
									:class="{ 'dashboard-trend-bar-focus': activeMetric === 'XUAT' && item.Xuat === maxXuat }"
									:style="getBarStyle(item.Xuat, maxXuat)">
									<span>{{ item.Xuat }}</span>
								</div>
							</div>
							<div class="dashboard-trend-bar-wrap">
								<div class="dashboard-trend-bar dashboard-trend-bar-orange"
									:class="{ 'dashboard-trend-bar-focus': activeMetric === 'CANH_BAO' && item.CanhBao === maxCanhBao }"
									:style="getBarStyle(item.CanhBao, maxCanhBao)">
									<span>{{ item.CanhBao }}</span>
								</div>
							</div>
						</div>
					</div>
				</v-card-text>
			</v-card>
		</v-col>

		<v-col v-if="recentRows.length > 0" cols="12" :lg="trendData.length > 0 ? 7 : 12">
			<v-card class="dashboard-panel dashboard-panel-fill dashboard-overview-recent" elevation="0">
				<v-card-text class="pa-4">
					<div class="d-flex justify-space-between align-center mb-4">
						<div class="dashboard-section-title">Giao dịch gần đây</div>
						<v-btn size="small" variant="text" color="primary" prepend-icon="mdi-filter-variant"
							@click="emitOpenSection()">
							{{ focusKey === 'ALL' ? 'Đang xem tất cả' : 'Bỏ lọc chi tiết' }}
						</v-btn>
					</div>

					<div v-if="recentRows.length === 0" class="dashboard-empty-state">
						Không có giao dịch phù hợp
					</div>

					<div v-else class="dashboard-table-wrap">
						<table class="dashboard-table">
							<thead>
								<tr>
									<th>Thời gian</th>
									<th>Loại</th>
									<th>Mã</th>
									<th>Địa điểm</th>
									<th>Trạng thái</th>
									<th>Giá trị</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="item in recentRows" :key="item.Id">
									<td>{{ item.TimeText }}</td>
									<td>{{ item.TypeText }}</td>
									<td class="dashboard-cell-code">{{ item.Code }}</td>
									<td>{{ item.LocationText }}</td>
									<td>{{ item.StatusText }}</td>
									<td>{{ item.ValueText }}</td>
								</tr>
							</tbody>
						</table>
					</div>
				</v-card-text>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
	name: 'uc-dashboard-overview',
	props: {
		focusKey: { type: String, default: 'ALL' },
		trendData: { type: Array, default: () => [] },
		recentRows: { type: Array, default: () => [] },
		insightData: { type: Object, default: () => ({}) },
		loading: { type: Boolean, default: false },
	},
	emits: ['open-section'],
	data() {
		return {
			activeMetric: 'NHAP',
		}
	},
	computed: {
		maxNhap() {
			return Math.max(...this.trendData.map((item) => item.Nhap), 1)
		},
		maxXuat() {
			return Math.max(...this.trendData.map((item) => item.Xuat), 1)
		},
		maxCanhBao() {
			return Math.max(...this.trendData.map((item) => item.CanhBao), 1)
		},
		currentInsight() {
			return this.insightData[this.activeMetric] || {
				Title: '',
				Summary: '',
				SubText: '',
			}
		},
	},
	methods: {
		setActiveMetric(metric) {
			this.activeMetric = metric
		},
		getBarStyle(value, maxValue) {
			return {
				width: Math.max(16, Math.round((value / maxValue) * 100)) + '%',
			}
		},
		emitOpenSection() {
			if (this.loading) return
			this.$emit('open-section', 'ALL')
		},
	},
}
</script>