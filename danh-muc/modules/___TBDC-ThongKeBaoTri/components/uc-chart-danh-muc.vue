<template>
	<div class="position-relative w-100" style="min-height: 350px;">
		<div v-if="loading" class="d-flex align-center justify-center h-100"
			style="position: absolute; inset: 0; z-index: 5; background: rgba(255,255,255,0.8);">
			<v-progress-circular indeterminate color="orange"></v-progress-circular>
		</div>

		<div ref="chartRef" class="w-100"></div>

		<div v-if="!loading && (!items || items.length === 0)"
			class="text-center text-grey d-flex flex-column align-center justify-center"
			style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);">
			<v-icon size="40" class="mb-2 opacity-50">mdi-chart-bar-off</v-icon>
			<div class="text-caption">Chưa có dữ liệu Danh mục</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: "UcChartDanhMuc",
		props: {
			items: { type: Array, default: () => [] },
			loading: { type: Boolean, default: false }
		},
		data() { return { chart: null }; },
		watch: {
			items: {
				handler(val) {
					if (val && val.length > 0) this.updateChart();
					else if (this.chart) { this.chart.destroy(); this.chart = null; }
				},
				deep: true
			}
		},
		mounted() {
			if (this.items && this.items.length > 0) this.renderChart();
		},
		beforeUnmount() {
			if (this.chart) this.chart.destroy();
		},
		methods: {
			renderChart() {
				if (!this.$refs.chartRef) return;
				if (!this.chart) {
					const options = this.getOptions();
					this.chart = new ApexCharts(this.$refs.chartRef, options);
					this.chart.render();
				} else { this.updateChart(); }
			},
			updateChart() {
				if (!this.chart) { this.renderChart(); return; }
				this.chart.updateOptions(this.getOptions(), true, true);
			},
			getOptions() {
				const categories = this.items.map(x => x.LabelName || 'Khác');
				const dataCounts = this.items.map(x => x.TotalValue || 0);
	
				return {
					chart: { type: 'bar', height: 350, fontFamily: 'Roboto, sans-serif', toolbar: { show: false }, animations: { enabled: true } },
					plotOptions: {
						bar: { borderRadius: 4, horizontal: true, distributed: true, barHeight: '60%', dataLabels: { position: 'bottom' } }
					},
					// Tông màu Cam/Đỏ cho Danh mục
					colors: ['#FF5722', '#FF9800', '#FFC107', '#FFEB3B', '#FF7043'],
					dataLabels: {
						enabled: true, textAnchor: 'start', style: { colors: ['#fff'], fontSize: '11px' },
						formatter: function (val) { return val }, offsetX: 0
					},
					series: [{ name: 'Số lượng', data: dataCounts }],
					xaxis: { categories: categories, labels: { style: { fontSize: '12px' } } },
					legend: { show: false },
					tooltip: { y: { formatter: (val) => val + " lỗi" } }
				};
			}
		}
	}
</script>