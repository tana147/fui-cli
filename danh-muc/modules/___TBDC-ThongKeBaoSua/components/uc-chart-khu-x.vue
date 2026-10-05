<template>
  <div id="asset-by-area-chart"></div>
</template>

<script>

export default {
  name: "AssetByAreaChart",
  props: {
    // Mảng JSON từ API (chính là dữ liệu bạn gửi)
    rows: {
      type: Array,
      required: true,
    },
    // Bật/tắt xếp chồng
    stacked: {
      type: Boolean,
      default: false,
    },
    // Chiều cao biểu đồ
    height: {
      type: [Number, String],
      default: 420,
    },
  },
  data() {
    return {
      chart: null,
    };
  },
  computed: {
    categories() {
      // Trục X: TenDanhMuc
      return this.rows.map((r) => r.TenDanhMuc);
    },
    series() {
      // Lấy danh sách cột khu vực từ khóa của object, loại TenDanhMuc và Tong
      const allKeys = this.rows.length ? Object.keys(this.rows[0]) : [];

      // Ưu tiên thứ tự hiển thị mong muốn:
      const desiredOrder = [
        "Khu A",
        "Khu B",
        "Khu C",
        "Khu D",
        "Khu E",
        "Cơ sở 02",
        "Cơ sở Long Khánh",
      ];

      const areaKeys = allKeys
        .filter((k) => k !== "TenDanhMuc" && k !== "Tong")
        // sắp theo desiredOrder, nếu có khóa mới thì để cuối
        .sort((a, b) => {
          const ia = desiredOrder.indexOf(a);
          const ib = desiredOrder.indexOf(b);
          return (ia === -1 ? 999 : ia) - (ib === -1 ? 999 : ib);
        });

      // Tạo series cho ApexCharts
      return areaKeys.map((area) => ({
        name: area,
        data: this.rows.map((r) => Number(r[area] || 0)),
      }));
    },
  },
  mounted() {
    this.renderChart();
  },
  watch: {
    rows: {
      handler() {
        this.updateChart();
      },
      deep: true,
    },
    stacked() {
      this.updateChart();
    },
  },
  methods: {
    renderChart() {
      const options = {
        chart: {
          type: "bar",
          height: this.height,
          stacked: this.stacked,
          toolbar: { show: false },
        },
        series: this.series,
        xaxis: {
          categories: this.categories,
          labels: { rotate: -30, trim: true },
        },
        plotOptions: {
          bar: {
            horizontal: false,
            columnWidth: "60%",
          },
        },
        dataLabels: { enabled: false },
        legend: {
          position: "top",
          horizontalAlign: "center",
          markers: { width: 10, height: 10, radius: 12 },
        },
        tooltip: {
          shared: true,
          intersect: false,
          y: { formatter: (v) => (v == null ? 0 : v) },
        },
        yaxis: {
          forceNiceScale: true,
          labels: { formatter: (v) => Math.round(v) },
          title: { text: "Số lượng" },
        },
        title: {
          text: this.stacked
            ? "Phân bố thiết bị theo khu vực (Stacked)"
            : "Phân bố thiết bị theo khu vực",
          align: "center",
        },
        grid: { strokeDashArray: 4 },
        responsive: [
          {
            breakpoint: 960,
            options: {
              plotOptions: { bar: { columnWidth: "70%" } },
              xaxis: { labels: { rotate: -45 } },
            },
          },
        ],
      };

      this.chart = new ApexCharts(
        document.querySelector("#asset-by-area-chart"),
        options
      );
      this.chart.render();
    },
    updateChart() {
      if (!this.chart) return this.renderChart();
      // Cập nhật stacked
      this.chart.updateOptions({
        chart: { stacked: this.stacked },
        xaxis: { categories: this.categories },
        title: {
          text: this.stacked
            ? "Phân bố thiết bị theo khu vực (Stacked)"
            : "Phân bố thiết bị theo khu vực",
        },
      });
      // Cập nhật series
      this.chart.updateSeries(this.series);
    },
  },
  beforeUnmount() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },
}
</script>
