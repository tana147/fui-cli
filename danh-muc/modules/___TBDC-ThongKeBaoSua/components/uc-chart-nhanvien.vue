<template>
  <div  style="z-index:1000" ref="elNhanVien"></div>
</template>

<script>

export default {
  name: "BarStackNhanVienTheoThang",
  props: {
    rows: { type: Array, required: true },      // [{ HoTen, '6-2025': n, ... , '5-2026': n, Tong }]
    height: { type: [Number, String], default: 400 },
    sortByTongDesc: { type: Boolean, default: true },
  },
  data() {
    return { chart: null, inited: false };
  },
  mounted() { this.renderOrUpdate(); },
  watch: {
    rows:   { handler() { this.renderOrUpdate(); }, deep: true },
    height: { handler() { if (this.chart) this.chart.updateOptions({ chart: { height: this.computeHeight() } }, false, true); } }
  },
  methods: {
    // ---- parse key tháng-năm ----
    parseMonthKey(k) {
      const s = String(k).trim();
      const rx = [
        /^(\d{4})[-_/](\d{1,2})$/,      // 2025-06
        /^(\d{1,2})[-_/](\d{4})$/,      // 06-2025
        /^T?h?áng?\s*(\d{1,2})\s*[-/]\s*(\d{4})$/i,
        /^(\d{4})_(\d{1,2})$/,
      ];
      for (const r of rx) {
        const m = s.match(r); if (!m) continue;
        const y  = (r===rx[0]||r===rx[3]) ? +m[1] : +m[2];
        const mo = (r===rx[0]||r===rx[3]) ? +m[2] : +m[1];
        if (mo>=1 && mo<=12) return { y, m: mo };
      }
      return null;
    },
    labelMonthKey(k) {
      const p = this.parseMonthKey(k);
      return p ? `${String(p.m).padStart(2,"0")}/${p.y}` : String(k);
    },
    detectAndSortMonths(row0) {
      if (!row0) return [];
      const meta = new Set(["HoTen","TenPhongBan","MaPhongBan","Tong"]);
      const parsed = [], others = [];
      for (const k of Object.keys(row0)) {
        if (meta.has(k)) continue;
        const p = this.parseMonthKey(k);
        if (p) parsed.push({ key: k, y: p.y, m: p.m }); else others.push(k);
      }
      parsed.sort((a,b)=> a.y===b.y ? a.m-b.m : a.y-b.y);
      return [...parsed.map(x=>x.key), ...others];
    },

    // ---- rows -> { series, employees } ----
    buildSeriesByMonth() {
      if (!this.rows?.length) return { series: [], employees: [] };

      let employeesRows = this.rows.map(r => ({
        name: String(r.HoTen ?? ""),   // CHỈ dùng HoTen
        row: r,
        tong: Object.entries(r).reduce((s,[k,v]) => this.parseMonthKey(k) ? s + Number(v||0) : s, 0)
      }));
      if (this.sortByTongDesc) employeesRows.sort((a,b)=> b.tong - a.tong);

      const employees = employeesRows.map(x => x.name);
      const months = this.detectAndSortMonths(this.rows[0]);

      const series = months.map(k => ({
        name: this.labelMonthKey(k),
        data: employeesRows.map(x => Number(x.row[k] ?? 0))  // MẢNG SỐ theo đúng thứ tự NV
      }));

      return { series, employees };
    },

    // ---- Render lần đầu (có categories) hoặc update ----
    async renderOrUpdate() {
      const { series, employees } = this.buildSeriesByMonth();
      if (!series.length) return;

      if (!this.inited) {
        const options = {
          chart: { type: "bar", stacked: true, height: this.computeHeight(employees.length), toolbar: { show: true } },
          plotOptions: {
            bar: {
              horizontal: true,
              barHeight: "65%",
              dataLabels: { total: { enabled: true, formatter: v => (v>0 ? Math.round(v) : ""), style: { fontWeight: 700 }, offsetX: 8 } }
            }
          },
          dataLabels: { enabled: false },
          // QUAN TRỌNG: Nhãn nhân viên đặt ở xaxis.categories (Apex sẽ vẽ ở trục Y khi horizontal=true)
          xaxis: { categories: employees, type: "category" },
          // KHÔNG thêm formatter ở xaxis/yaxis để tránh NaN hoặc ép trục thành số
          legend: { position: "top", horizontalAlign: "left" },
          grid: { strokeDashArray: 4 },
          tooltip: { shared: false, intersect: true },
          title: { text: "Thống kê theo nhân viên xử lý ", align: "center",
		  style: {
	
	            fontFamily: 'Roboto, Arial, sans-serif',
	
	          } },
          noData: { text: "Không có dữ liệu" },
          series,
        };
        this.chart = new ApexCharts(this.$refs.elNhanVien, options);
        this.chart.render();
        this.inited = true;
      } else {
        await this.chart.updateOptions({
          xaxis: { categories: employees, type: "category" },
          chart: { height: this.computeHeight(employees.length) }
        }, false, true);
        await this.chart.updateSeries(series, true);
      }
    },

    computeHeight(n) {
      const count = n ?? (this.rows?.length || 0);
      const base = 140, perRow = 32;
      const target = base + count * perRow;
      const minH = typeof this.height === "number" ? this.height : parseInt(this.height,10) || 645;
      return Math.max(minH, target);
    },
  },
  beforeUnmount(){ this.chart?.destroy(); },
}
</script>
