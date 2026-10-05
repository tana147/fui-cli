<template>
	<div class="w-100" style="min-height: 300px;">
		<div ref="chartRef"></div>
		<div v-if="!chart && (!items || items.length === 0)"
			class="text-center text-grey d-flex flex-column align-center justify-center"
			style="position: absolute; inset: 0;">
			<v-icon size="40" class="mb-2 opacity-50">mdi-chart-bar-off</v-icon>
			<div class="text-caption">Không có dữ liệu nhân viên.</div>
		</div>
	</div>
</template>

<script>
	// Không cần import nếu dùng CDN (window.ApexCharts)
	
	export default {
		name: "UcChartNhanVien",
		props: {
			// Nhận mảng object: [{ MaNhanVien: 'NA001', HoTen: 'Nguyễn A', TongSoLuong: 10 }, ...]
			items: { type: Array, default: () => [] }
		},
		data() { return { chart: null }; },
		watch: {
			items: { handler() { this.renderChart(); }, deep: true }
		},
		mounted() { this.renderChart(); },
		beforeUnmount() {
			if (this.chart) this.chart.destroy();
		},
		methods: {
			renderChart() {
				if (!this.$refs.chartRef) return;
	
				const Apex = window.ApexCharts; // Lấy biến toàn cục
	
				// Nếu không có dữ liệu HOẶC thư viện chưa tải xong thì dừng
				if (!this.items || this.items.length === 0 || !Apex) {
					if (this.chart) this.chart.destroy();
					this.chart = null;
					return;
				}
	
				if (this.chart) this.chart.destroy(); // Phá hủy chart cũ trước khi vẽ lại
	
				const options = this.getOptions();
	
				this.chart = new Apex(this.$refs.chartRef, options);
				this.chart.render();
			},
			updateChart() {
				if (this.chart) {
					this.chart.updateOptions(this.getOptions(), true, true);
				} else {
					this.renderChart();
				}
			},
			getOptions() {
				// SỬA LỖI MAPPING: Dùng HoTen và TongSoLuong
				const categories = this.items.map(x => x.HoTen || x.MaNhanVien);
				const dataCounts = this.items.map(x => x.TongSoLuong || 0);
	
				return {
					chart: { type: 'bar', height: 300, toolbar: { show: false }, fontFamily: 'Roboto, sans-serif' },
					series: [{ name: 'Số lượng TS', data: dataCounts }],
					xaxis: {
						categories: categories,
						labels: { style: { fontSize: '11px' } }
					},
					colors: ['#1976D2'],
					plotOptions: { bar: { borderRadius: 4, columnWidth: '50%' } },
					dataLabels: { enabled: false }
				};
			}
		}
	}
</script>