<template>
	<canvas style="height: 500px;" ref="myChart"></canvas>
</template>

<script>
	export default {
		props: ['data', 'type', 'options', 'plugins', 'reverseData'],
    data: function () {
        return {
            COLORS: ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF'],
            CHART_COLORS: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF'],
            myChart: null,
            config: {
                type: this.type,
                data: this.data,
                options: {
                    ...this.options,
                    responsive: true, // Tự động resize khi màn hình thay đổi
                    maintainAspectRatio: false, // Không giữ tỷ lệ mặc định
                },
                plugins: this.plugins,
            },
        }
    },
    mounted() {
        this.buildChart(this)
    },
    watch: {
        data: {
            deep: true,
            handler(newValue) {
                this.myChart.destroy()
                this.config.data = newValue
                this.buildChart(this)
            },
        },
    },
    methods: {
        buildChart(self) {
            const $this = this
            if (self.reverseData && self.config.data.labels) self.config.data.labels = _.reverse(self.config.data.labels)
            _.forEach(self.config.data.datasets, function (v, k) {
                if (self.reverseData && v.data) v.data = _.reverse(v.data)

                if (self.config.type == 'line') {
                    if (!v.borderColor) v.borderColor = $this.COLORS[k % $this.COLORS.length]
                    if (!v.backgroundColor) v.backgroundColor = $this.CHART_COLORS[k % $this.CHART_COLORS.length]
                } else if (!v.backgroundColor) v.backgroundColor = $this.CHART_COLORS
            })
            console.log('self.config', self.config)
            self.myChart = new Chart(self.$refs.myChart, self.config)
        },
    },
	}
</script>