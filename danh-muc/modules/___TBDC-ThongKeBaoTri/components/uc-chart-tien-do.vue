<template>
	<div class="position-relative w-100" style="min-height: 300px;">
		<div ref="chartRef" class="w-100 d-flex justify-center"></div>
		<div v-if="total === 0" class="text-center text-grey absolute-center">Chưa có dữ liệu</div>
	</div>
</template>

<script>
	export default {
		name: "UcChartTienDo",
		props: {
			// Object: { DungHan: 10, TreHan: 2, ChuaThucHien: 5 }
			data: { type: Object, default: () => ({}) }
		},
		data() { return { chart: null, total: 0 }; },
		watch: {
			data: { handler() { this.renderChart(); }, deep: true }
		},
		mounted() { this.renderChart(); },
		methods: {
			renderChart() {
				if (!this.$refs.chartRef) return;
				if (this.chart) this.chart.destroy();
	
				const series = [
					this.data.DungHan || 0,
					this.data.TreHan || 0,
					this.data.ChuaThucHien || 0
				];
				this.total = series.reduce((a, b) => a + b, 0);
				if (this.total === 0) return;
	
				const options = {
					chart: { type: 'donut', height: 300, fontFamily: 'Roboto, sans-serif' },
					labels: ['Đúng hạn', 'Quá hạn', 'Chưa làm'],
					series: series,
					colors: ['#4CAF50', '#F44336', '#9E9E9E'], // Xanh, Đỏ, Xám
					legend: { position: 'bottom' },
					dataLabels: { enabled: true },
					plotOptions: {
						pie: { donut: { labels: { show: true, total: { show: true, label: 'Tổng', fontSize: '14px' } } } }
					}
				};
	
				const Apex = window.ApexCharts || ApexCharts;
				this.chart = new Apex(this.$refs.chartRef, options);
				this.chart.render();
			}
		}
	}
</script>