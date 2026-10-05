<template>
	<div class="uc-chart-apex">
		<!-- Custom Legend -->
		<div class="custom-legend" v-if="showCustomLegend"
			:class="{ 'compact-legend': compactLegend }">
			<div v-for="item in legendItems" :key="item.category" class="legend-item"
				:class="{ inactive: !item.active }" @click="toggleCategory(item.category)">
				<div class="legend-marker" :style="{ backgroundColor: item.color }"></div>
				<span class="legend-text">{{ item.label }}</span>
			</div>
		</div>

		<!-- Chart Container -->
		<div :id="uniqueId"></div>
	</div>
</template>

<script>
	export default {
		props: {
		modelValue: {},
		options: {
			type: Object
		},
		showCustomLegend: {
			type: Boolean,
			default: false
		},
		legendConfig: {
			type: Array,
			default: () => []
		},
		// Cho phép từng màn hình chọn mật độ legend; mặc định giữ nguyên giao diện cũ.
		compactLegend: {
			type: Boolean,
			default: false
		},
		hideSeries: {
			type: Array,
			default: () => []
		}
	},
	data() {
		return {
			myChart: null,
			config: this.options,
			legendItems: [],
			_
		}
	},
	mounted() {
		this.initLegend();
		this.buildChart(this)
	},
	computed: {
		uniqueId() {
			return `chart-${_.uniqueId()}`; // Sử dụng _uid của Vue để tạo ID duy nhất
		}
	},
	watch: {
		options: function (newValue, oldValue) {
			const config = {
				...this.options,
				chart: this.options.chart,
				series: this.options.series,
				xaxis: this.options.xaxis,
				yaxis: this.options.yaxis,
			}

			if (this.myChart) {
				this.myChart.destroy()
				this.buildChart(this)
			}
		},
		legendConfig: {
			handler() {
				this.initLegend();
			},
			deep: true
		}
	},
	methods: {
		initLegend() {
			if (this.showCustomLegend && this.legendConfig.length > 0) {
				this.legendItems = this.legendConfig.map(item => ({
					...item,
					active: true
				}));
			}
		},
		buildChart(self) {
			self.myChart = new ApexCharts(
				document.querySelector(`#${this.uniqueId}`), // Sử dụng ID động
				this.options
			);
			self.myChart.render();
			this.$emit('update:modelValue', self.myChart);
		},
		toggleCategory(category) {
			const legendItem = this.legendItems.find(item => item.category === category);
			if (legendItem) {
				legendItem.active = !legendItem.active;
				// Find and toggle all series with this category
				if (this.options.series) {
					this.options.series.forEach(series => {
						if (series.category === category) {
							if (legendItem.active) {
								this.myChart.showSeries(series.name);
							} else {
								this.myChart.hideSeries(series.name);
							}
						}
					});
				}
			}
		}
	},
	}
</script>

<style scoped>
/* Legend nhiều môn cần mật độ cao hơn để không chiếm gần hết chiều cao card. */
.uc-chart-apex .custom-legend.compact-legend {
	justify-content: flex-start;
	column-gap: 14px;
	row-gap: 3px;
	margin-bottom: 10px;
}

.uc-chart-apex .custom-legend.compact-legend .legend-item {
	gap: 5px;
	padding: 2px 4px;
}

.uc-chart-apex .custom-legend.compact-legend .legend-marker {
	width: 11px;
	height: 11px;
}

.uc-chart-apex .custom-legend.compact-legend .legend-text {
	font-size: 12px;
}
</style>