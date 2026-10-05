<template>
  <v-dialog v-model="value" persistent centered width="520">
    <v-card small elevation="0" outlined centered>
      <v-card-title>
        <h5 class="primary--text">Tiến trình lấy dữ liệu báo cáo</h5>
      </v-card-title>

      <v-card-text class="mx-auto">
        <div class="pr-2 pl-2">
          <v-progress-linear v-if="isLoading" :value="processNum"></v-progress-linear>

          <!-- BIG DATA MODE: chỉ hiện cảnh báo + nút tải -->
          <v-alert v-if="isBigData" type="warning" outlined dense class="mt-3">
            Dữ liệu rất lớn ({{ rowCount.toLocaleString() }} dòng). Để tránh treo giao diện,
            chỉ cho phép tải file dữ liệu. Vui lòng bấm “Tải Excel” hoặc dùng CSV nếu Excel thất bại.
          </v-alert>

          <div v-if="isBigData" class="d-flex align-center ga-2 mt-2">
            <v-btn color="primary" :loading="exporting" @click="exportToXLSX" small>Tải Excel</v-btn>
            <v-btn color="grey" :loading="exportingCsv" @click="exportToCSV" small>CSV (nhẹ)</v-btn>
          </div>

          <!-- Bình thường: vẫn cho xem danh sách tiến trình -->
          <v-virtual-scroll
            v-else
            class="page-section"
            :items="items"
            height="500"
            item-height="60"
          >
            <template v-slot:default="{ item }">
              <v-list-item
                :key="item.CuaHangID"
                :class="{ 'error-row': item.status === 3 }"
              >
                <v-list-item-content>
                  {{ item.TenCuaHang || ('Cửa hàng #' + item.CuaHangID) }}
                  <span v-if="requestTimes[item.CuaHangID] !== undefined" class="ml-2" style="font-size:12px;color:#888;">
                    ({{ requestTimes[item.CuaHangID] }} ms)
                  </span>
                </v-list-item-content>
                <v-list-item-action>
                  <v-btn v-if="item.status === 1" elevation="0" icon :loading="true" small />
                  <v-icon v-else-if="item.status === 2" color="primary" small>mdi-check</v-icon>
                  <v-btn v-else-if="item.status === 3" icon small @click.stop="retry(item.CuaHangID)">
                    <v-icon small>mdi-reload</v-icon>
                  </v-btn>
                </v-list-item-action>
              </v-list-item>
              <v-divider />
            </template>
          </v-virtual-scroll>
        </div>
      </v-card-text>

      <v-card-actions>
        <v-spacer />
        <!-- KHÓA ĐÓNG khi big data hoặc đang tải -->
        <v-tooltip bottom v-if="isBigData || isLoading">
          <template v-slot:activator="{ on, attrs }">
            <div v-bind="attrs" v-on="on">
              <v-btn color="red" text @click="clearALl()">Đóng</v-btn>
            </div>
          </template>
          <span v-if="isLoading">Đang xử lý...</span>
          <span v-else>Dữ liệu lớn – chỉ cho phép tải file</span>
        </v-tooltip>
        <v-btn v-else color="red" text @click="close" :disabled="isLoading">Đóng</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  props: ["value"],
  data() {
    return {
      vueData, 
      isLoading: false,
      localStatuses: Object.create(null),
      completedCount: 0,
      aborter: null,
      exporting: false,
      exportingCsv: false,
      BIG_THRESHOLD: 10000, // tùy chỉnh theo cấu hình máy
      requestTimes: Object.create(null) // Thêm object lưu thời gian request
    };
  },
  computed: {
    items() {
      const ids = Array.isArray(this.vueData.CuaHangIDList) ? this.vueData.CuaHangIDList : [];
      const nameMap = Object.create(null);
      const ds = Array.isArray(this.vueData.DSCuaHang) ? this.vueData.DSCuaHang : [];
      for (let i = 0; i < ds.length; i++) nameMap[ds[i].CuaHangID] = ds[i].TenCuaHang;
      // Tạo mảng cửa hàng với status
      const arr = ids.map((id) => ({
        CuaHangID: id,
        TenCuaHang: nameMap[id],
        status: this.localStatuses[id] ?? 0
      }));
      // Sắp xếp: lỗi lên đầu, loading tiếp theo, done cuối cùng
      arr.sort((a, b) => {
        // status: 3 (error) < 1 (loading) < 2 (done)
        const order = (st) => st === 3 ? 0 : (st === 1 ? 1 : 2);
        return order(a.status) - order(b.status);
      });
      return arr;
    },
    processNum() {
      const total = this.vueData.CuaHangIDList?.length || 0;
      return total ? (this.completedCount / total) * 100 : 0;
    },
    rowCount() {
      return Array.isArray(this.vueData.DSChiTietHoaDon) ? this.vueData.DSChiTietHoaDon.length : 0;
    },
    isBigData() {
      return this.rowCount >= this.BIG_THRESHOLD;
    }
  },
  watch: {
    value: {
      handler(val) {
        if (val) {
          this.vueData.DSCuaHangGetSuccess = [];
          this.localStatuses = Object.create(null);
          this.completedCount = 0;
          this.$nextTick(this.handleGetData);
        } else {
          this.abortAll();
        }
      }
    },
    'vueData.PhanHieuID'(val) {
      if (val) this.vueData.CuaHangIDList = [];
    }
  },
  methods: {
   
    clearALl() {
      vueData.DSChiTietHoaDon = []
      this.isLoading = false;
      this.$emit("input", false);

    },
    close() {
      this.isLoading = false;
      this.$emit("input", false);
    },
    abortAll() {
      if (this.aborter) {
        try { this.aborter.abort(); } catch(_) {}
        this.aborter = null;
      }
    },
    setStatus(id, st) {
      this.$set(this.localStatuses, id, st);
    },

    async handleGetData() {
      const ids = Array.isArray(this.vueData.CuaHangIDList) ? this.vueData.CuaHangIDList.slice() : [];
      if (!ids.length) { this.isLoading = false; return; }

      this.isLoading = true;
      this.abortAll();
      this.aborter = new AbortController();
      const { signal } = this.aborter;

      // reset nguồn
      this.vueData.DSChiTietHoaDon = [];

      for (let i = 0; i < ids.length; i++) this.setStatus(ids[i], 1);

      const baseFilter = {
        PhanHieuID: this.vueData.PhanHieuID,
        KhuVucID: this.vueData.KhuVucID,
        HinhThucThanhToan: this.vueData.HinhThucThanhToan,
        HinhThucThoiGian: this.vueData.HinhThucThoiGian,
        Ngay: this.vueData.Ngay,
        TuNgay: this.vueData.TuNgay,
        DenNgay: this.vueData.DenNgay,
        Nam: this.vueData.Nam ?? -1,
        TuNam: this.vueData.TuNam ?? -1,
        DenNam: this.vueData.DenNam ?? -1,
        Thang: this.vueData.Thang ?? -1,
        TrangThaiMon: this.vueData.TrangThaiMon
      };

      const CONCURRENCY = 10;
      const tasks = ids.map(id => () => this.fetchStore(id, baseFilter, signal));
      const results = await this.runWithConcurrency(tasks, CONCURRENCY, signal);

      const allData = [];
      const succ = [];
      const fail = [];
      for (const r of results) {
        if (!r) continue;
        if (r.ok) { allData.push(...(r.data || [])); succ.push(r.id); }
        else { fail.push({ CuaHangID: r.id, message: r.errMsg || '' }); }
      }

      this.vueData.DSChiTietHoaDon = allData;

      try {
        if (typeof handleColumnHinhThucThoiGian === 'function') {
          handleColumnHinhThucThoiGian(this.vueData.HinhThucThoiGian);
        }
      } catch (_) {}

      // Khi không fail và không big data => tự đóng
      if (fail.length === 0 && !this.isBigData) this.close();
      // Ngược lại: giữ dialog để người dùng bấm tải file

      this.isLoading = false;
    },

    async fetchStore(CuaHangID, baseFilter, signal) {
      const URL = fixURL("/eorder/BaoCao_HoaDon_ChiTiet_v2");
      const body = JSON.stringify({ ...baseFilter, CuaHangID });

      const start = performance.now(); // Bắt đầu tính thời gian
      try {
        const res = await fetch(URL, {
          method: "POST",
          headers: {
            "content-type": "application/json; charset=utf-8",
            "authorization": $awt
          },
          body,
          signal
        });

        const end = performance.now(); // Kết thúc tính thời gian
        this.$set(this.requestTimes, CuaHangID, Math.round(end - start));

        if (!res.ok) {
          const text = await res.text().catch(() => "");
          this.markDone(CuaHangID, false);
          return { ok: false, id: CuaHangID, errMsg: text || res.statusText };
        }

        const json = await res.json().catch(() => ({}));
        const data = json?.data || [];

        this.markDone(CuaHangID, true);
        return { ok: true, id: CuaHangID, data };
      } catch (err) {
        const end = performance.now();
        this.$set(this.requestTimes, CuaHangID, Math.round(end - start));
        if (signal.aborted) return { ok: false, id: CuaHangID, errMsg: 'aborted' };
        this.markDone(CuaHangID, false);
        return { ok: false, id: CuaHangID, errMsg: err && err.message ? err.message : '' };
      }
    },

    markDone(id, isSuccess) {
      this.setStatus(id, isSuccess ? 2 : 3);
      this.completedCount += 1;
    },

    async runWithConcurrency(tasks, limit, signal) {
      const results = new Array(tasks.length);
      let idx = 0, running = 0;
      return new Promise((resolve) => {
        const launchNext = () => {
          if (signal?.aborted) return resolve(results);
          while (running < limit && idx < tasks.length) {
            const current = idx++;
            running++;
            tasks[current]()
              .then(r => { results[current] = r; })
              .catch(e => { results[current] = { ok: false, id: null, errMsg: e?.message || 'error' }; })
              .finally(() => {
                running--;
                if (idx >= tasks.length && running === 0) resolve(results);
                else if (typeof requestAnimationFrame === 'function') requestAnimationFrame(launchNext);
                else setTimeout(launchNext, 0);
              });
          }
        };
        launchNext();
      });
    },

    async exportToXLSX() {
      if (!Array.isArray(this.vueData.DSChiTietHoaDon) || this.rowCount === 0) return;
      this.exporting = true;
      try {
          jsonToExcel({ data: this.vueData.DSChiTietHoaDon, filename: 'Báo cáo chi tiết hóa đơn.xlsx' });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
      } catch (e) {
        // Fallback CSV nếu lỗi
        console.warn('xlsx failed, fallback to CSV:', e);
        await this.exportToCSV(true);
      } finally {
        this.exporting = false;
      }
    },

    async exportToCSV(isFallback = false) {
      if (!Array.isArray(this.vueData.DSChiTietHoaDon) || this.rowCount === 0) return;
      this.exportingCsv = true;
      try {
        const rows = this.vueData.DSChiTietHoaDon;
        const cols = Object.keys(rows.reduce((acc, r) => { Object.keys(r||{}).forEach(k => acc[k]=1); return acc; }, {}));

        const escapeCsv = (v) => {
          if (v == null) return '';
          const s = String(v);
          return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
        };

        const chunkSize = 5000; // tránh block UI
        let csv = cols.map(escapeCsv).join(',') + '\n';
        for (let i = 0; i < rows.length; i++) {
          const r = rows[i] || {};
          const line = cols.map(c => escapeCsv(r[c])).join(',');
          csv += line + '\n';
          if ((i % chunkSize) === 0) await new Promise(res => setTimeout(res)); // nhường thread
        }

        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = this.makeFileName('BaoCao_HoaDon', 'csv', isFallback ? 'xlsx-fallback' : '');
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      } finally {
        this.exportingCsv = false;
      }
    },

    makeFileName(prefix, ext, suffix='') {
      const d = new Date();
      const pad = (n) => String(n).padStart(2,'0');
      const ts = `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
      return `${prefix}${suffix?('_'+suffix):''}_${ts}.${ext}`;
    },

    // optional: retry một cửa hàng fail
    async retry(id) {
      if (this.isLoading) return;
      this.completedCount = Math.max(0, this.completedCount - (this.localStatuses[id] === 3 ? 1 : 0));
      this.setStatus(id, 1);
      const { signal } = (this.aborter = new AbortController());
      const baseFilter = {
        PhanHieuID: this.vueData.PhanHieuID,
        KhuVucID: this.vueData.KhuVucID,
        HinhThucThanhToan: this.vueData.HinhThucThanhToan,
        HinhThucThoiGian: this.vueData.HinhThucThoiGian,
        Ngay: this.vueData.Ngay,
        TuNgay: this.vueData.TuNgay,
        DenNgay: this.vueData.DenNgay,
        Nam: this.vueData.Nam ?? -1,
        TuNam: this.vueData.TuNam ?? -1,
        DenNam: this.vueData.DenNam ?? -1,
        Thang: this.vueData.Thang ?? -1,
        TrangThaiMon: this.vueData.TrangThaiMon
      };
      const start = performance.now();
      await this.fetchStore(id, baseFilter, signal);
      const end = performance.now();
      this.$set(this.requestTimes, id, Math.round(end - start));
    }
  }
}
</script>


