<template>
	<div style="z-index:1000" ref="el"></div>
</template>

<script>
	export default {
	  props: {
	    rows: { type: Array, required: true },
	    height: { type: [Number, String], default: 645 },
	  },
	  data() {
	    return { chart: null };
	  },
	  mounted() {
	    this.initChart();
	    this.updateFromRows();          // nếu đã có dữ liệu ngay
	  },
	  watch: {
	    rows: { handler() { this.updateFromRows(); }, deep: true },
	  },
	  methods: {
	    initChart() {
	      const options = {
	        chart: { type: "bar", height: this.height, stacked: true, toolbar: { show: true } },
	        plotOptions: {
	          bar: {
	            horizontal: true,
	            barHeight: "65%",
	            dataLabels: {
	              total: {
	                enabled: true,
	                formatter: (v) => (v > 0 ? v : ""),
	                style: { fontWeight: 700 },
	                offsetX: 8,
	              },
	            },
	          },
	        },
	        dataLabels: { enabled: false },
	        xaxis: {
	          title: { text: "" },
	          labels: { formatter: (v) => Math.round(v) },
	        },
	        // KHÔNG cần yaxis.categories nữa
	        yaxis: { labels: { style: { fontSize: "13px" } } },
	        legend: { position: "top", horizontalAlign: "left" },
	        grid: { strokeDashArray: 4 },
	        tooltip: {
	          shared: false,     // <- chỉ hiện series đang hover
	          intersect: true
	        },
	        title: {
	          text: "Danh mục theo khu", align: "center",
	          style: {
	
	            fontFamily: 'Roboto, Arial, sans-serif',
	
	          }
	        },
	        series: [],
	      };
	      this.chart = new ApexCharts(this.$refs.el, options);
	      this.chart.render();
	    },
	
	    // Chuyển rows -> series dạng { x: 'Khu ...', y: số }
	    buildSeriesXY() {
	      if (!this.rows?.length) return [];
	
	      // Lấy danh sách cột khu và sắp xếp theo thứ tự mong muốn
	      const allKeys = Object.keys(this.rows[0]);
	      const order = ["Khu A", "Khu B", "Khu C", "Khu D", "Khu E", "Cơ sở 02", "Cơ sở Long Khánh"];
	      const areas = allKeys
	        .filter(k => k !== "TenDanhMuc" && k !== "Tong")
	        .sort((a, b) => (order.indexOf(a) === -1 ? 999 : order.indexOf(a)) -
	          (order.indexOf(b) === -1 ? 999 : order.indexOf(b)));
	
	      // Mỗi danh mục là 1 series; data = [{x: 'Khu A', y: ...}, ...]
	      const series = this.rows.map(r => ({
	        name: r.TenDanhMuc,
	        data: areas.map(a => ({ x: String(a), y: Number(r[a] || 0) })),
	      }));
	
	      return series;
	    },
	
	    async updateFromRows() {
	      if (!this.chart) return;
	      const series = this.buildSeriesXY();
	      if (!series.length) return;
	      await this.chart.updateSeries(series, true);
	    },
	  },
	  beforeUnmount() { this.chart?.destroy(); },
	}
</script>