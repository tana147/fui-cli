<template>
	<v-card elevation="0" class="d-flex flex-column align-center justify-center">
		<div style="position: relative; height: 300px; width: 100%;">
			<canvas ref="pieChartRef"></canvas>
			<div v-if="total > 0"
				style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; pointer-events: none;">
				<div class="text-h4 font-weight-bold text-primary">{{ total }}</div>
				<div class="text-caption text-grey">Tổng TS</div>
			</div>
			<div v-else class="d-flex align-center justify-center h-100 text-grey">Không có dữ liệu</div>
		</div>
	</v-card>
</template>

<script>
	export default {
		props: ["lost", "broken", "good", "notChecked"],
		data() { return { pieChart: null }; },
		computed: {
			total() { return (Number(this.lost) || 0) + (Number(this.broken) || 0) + (Number(this.good) || 0) + (Number(this.notChecked) || 0); }
		},
		watch: {
			lost: 'renderChart', broken: 'renderChart', good: 'renderChart', notChecked: 'renderChart',
		},
		mounted() {
			this.$nextTick(() => { this.renderChart(); });
		},
		methods: {
			tinhPhanTram(x) {
				const val = Number(x) || 0;
				return this.total > 0 ? (val / this.total * 100).toFixed(1) + '%' : '0%';
			},
			renderChart() {
				if (this.pieChart) { this.pieChart.destroy(); this.pieChart = null; }
				if (!this.$refs.pieChartRef || typeof window.Chart === 'undefined') return;
	
				const ctx = this.$refs.pieChartRef.getContext('2d');
				this.pieChart = new window.Chart(ctx, {
					type: 'doughnut',
					data: {
						labels: ['Mất: ' + this.tinhPhanTram(this.lost), 'Hư: ' + this.tinhPhanTram(this.broken), 'Tốt: ' + this.tinhPhanTram(this.good), 'Chưa kiểm: ' + this.tinhPhanTram(this.notChecked)],
						datasets: [{
							data: [Number(this.lost) || 0, Number(this.broken) || 0, Number(this.good) || 0, Number(this.notChecked) || 0],
							backgroundColor: ['#F44336', '#FF9800', '#4CAF50', '#9E9E9E'],
							borderWidth: 1, borderColor: '#ffffff', hoverOffset: 4
						}]
					},
					options: {
						responsive: true, maintainAspectRatio: false, cutout: '65%',
						plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, padding: 15 } }, tooltip: { callbacks: { label: (c) => c.label } } }
					}
				});
			}
		}
	}
</script>