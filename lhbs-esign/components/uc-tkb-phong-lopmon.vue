<template>
	<div class="uc-plm">
    <div class="uc-plm__bar">
      <button v-for="c in capList" :key="c.k" type="button" :class="['uc-plm__chip', cap === c.k ? 'uc-plm__chip--on' : '']" @click="cap = c.k">{{ c.ten }}</button>
      <input v-model="tim" class="uc-plm__tim" placeholder="Tìm lớp / phòng..." />
      <span class="uc-plm__sp"></span>
      <span>{{ soGan }} ô đã gán phòng</span>
      <span v-if="soCan" class="uc-plm__do">· {{ soCan }} ô chưa có phòng</span>
      <span v-else class="uc-plm__xanh">· không thiếu phòng</span>
    </div>
    <div class="uc-plm__mo">Mỗi lớp học 1 môn luôn ở 1 phòng cố định (rút từ TKB thật). Đổi phòng ở đây áp dụng cho các lần xếp sau và lúc gán phòng khi chạy xong. Chọn "—" = học tại lớp / dùng chung nhóm phòng.</div>
    <div class="uc-plm__hang">
      <div class="uc-plm__wrap fpScrollbar">
        <table class="uc-plm__tbl">
          <thead>
            <tr><th class="uc-plm__lop">Lớp</th><th v-for="m in monHien" :key="'h' + m">{{ tenMon[m] || m }}</th></tr>
          </thead>
          <tbody>
            <tr v-for="r in dong" :key="r.lop">
              <td class="uc-plm__lop">{{ r.lop }}</td>
              <td v-for="c in r.cells" :key="c.k" :class="c.cls" :title="c.title">
                <select v-if="c.co" :value="c.phong" class="uc-plm__sel" @change="doiPhong(r.lop, c.mon, $event.target.value)">
                  <option value="">—</option>
                  <option v-for="p in c.lua" :key="p" :value="p">{{ p }}</option>
                </select>
              </td>
            </tr>
            <tr v-if="!dong.length"><td class="uc-plm__rong" :colspan="1 + monHien.length">Không có lớp nào khớp bộ lọc</td></tr>
          </tbody>
        </table>
      </div>
      <div class="uc-plm__tai">
        <div class="uc-plm__taihead">Số lớp gán vào mỗi phòng</div>
        <div v-for="p in taiPhong" :key="p.ph" class="uc-plm__tairow" :title="p.lops.join(', ')">
          <span class="uc-plm__taiph">{{ p.ph }}</span>
          <span class="uc-plm__taiten">{{ p.ten }}</span>
          <span class="uc-plm__tain">{{ p.lops.length }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    rows: { type: Array, default: function () { return []; } }
  },
  data: function () {
    return {
      cap: 'all',
      tim: '',
      capList: [{ k: 'all', ten: 'Tất cả' }, { k: 'th', ten: 'Tiểu học' }, { k: 'thcs', ten: 'THCS' }, { k: 'thpt', ten: 'THPT' }],
      monThuTu: ['TIN', 'MT', 'NHAC', 'AI', 'STEM', 'SHTV', 'BOI', 'TANN', 'TAVN'],
      tenMon: { TIN: 'Tin học', MT: 'Mĩ thuật', NHAC: 'Âm nhạc', AI: 'AI', STEM: 'STEM', SHTV: 'Thư viện', BOI: 'Bơi', TANN: 'TA GVNN', TAVN: 'TA GVVN' },
      loaiPhong: { TIN: /^TIN\d/, MT: /^MT\d/, NHAC: /^AN\d/, AI: /^AI\d/, STEM: /^(STEAM|LI$|HOA$|SINH$)/, SHTV: /^TV\d/, BOI: /^BOI\d/, TANN: /^TA\d/, TAVN: /^TA\d/ }
    };
  },
  computed: {
    gan: function () {
      var m = {};
      (this.rows || []).forEach(function (r) { if (r.Loai === 'GAN') m[r.MaLop + '|' + r.MaMon] = r; });
      return m;
    },
    can: function () {
      var m = {};
      (this.rows || []).forEach(function (r) { if (r.Loai === 'CAN') m[r.MaLop + '|' + r.MaMon] = true; });
      return m;
    },
    phongDs: function () {
      return (this.rows || []).filter(function (r) { return r.Loai === 'PHONG'; });
    },
    monHien: function () {
      var co = {};
      (this.rows || []).forEach(function (r) { if (r.Loai !== 'PHONG' && r.MaMon) co[r.MaMon] = true; });
      return this.monThuTu.filter(function (m) { return co[m]; });
    },
    lopDs: function () {
      var s = {};
      (this.rows || []).forEach(function (r) { if (r.Loai !== 'PHONG' && r.MaLop) s[r.MaLop] = true; });
      return Object.keys(s).sort();
    },
    dong: function () {
      var self = this, t = (this.tim || '').trim().toUpperCase();
      return this.lopDs.filter(function (L) {
        var k = parseInt(L.slice(0, 2), 10);
        if (self.cap === 'th' && !(k >= 1 && k <= 5)) return false;
        if (self.cap === 'thcs' && !(k >= 6 && k <= 9)) return false;
        if (self.cap === 'thpt' && !(k >= 10 && k <= 12)) return false;
        if (!t) return true;
        if (L.toUpperCase().indexOf(t) >= 0) return true;
        return self.monHien.some(function (m) { var g = self.gan[L + '|' + m]; return g && g.Enable && String(g.MaPhong).toUpperCase().indexOf(t) >= 0; });
      }).map(function (L) {
        return { lop: L, cells: self.monHien.map(function (m) { return self.oCua(L, m); }) };
      });
    },
    soGan: function () {
      var self = this;
      return Object.keys(this.gan).filter(function (k) { return self.gan[k].Enable; }).length;
    },
    soCan: function () { return Object.keys(this.can).length; },
    taiPhong: function () {
      var self = this, m = {};
      Object.keys(this.gan).forEach(function (k) {
        var g = self.gan[k];
        if (!g.Enable) return;
        (m[g.MaPhong] || (m[g.MaPhong] = [])).push(g.MaLop + ' ' + g.MaMon);
      });
      return this.phongDs.map(function (p) { return { ph: p.MaPhong, ten: p.TenPhong || '', lops: m[p.MaPhong] || [] }; })
        .filter(function (p) { return p.lops.length || /^(TIN|MT|AN|AI|STEAM|LI|HOA|SINH|TV|TA|BOI)/.test(p.ph); })
        .sort(function (a, b) { return a.ph.localeCompare(b.ph); });
    }
  },
  methods: {
    oCua: function (L, m) {
      var g = this.gan[L + '|' + m], can = !!this.can[L + '|' + m], re = this.loaiPhong[m];
      var lua = this.phongDs.map(function (p) { return p.MaPhong; }).filter(function (p) { return !re || re.test(p); });
      var phong = g && g.Enable ? g.MaPhong : '';
      if (phong && lua.indexOf(phong) < 0) lua.push(phong);
      var co = !!g || can;
      return {
        k: L + m, mon: m, co: co, phong: phong, lua: lua,
        cls: 'uc-plm__o' + (can ? ' uc-plm__o--can' : (g && !g.Enable ? ' uc-plm__o--tat' : (phong ? ' uc-plm__o--co' : ''))),
        title: can ? 'Lớp có phân công môn này nhưng chưa có phòng' : (g ? (g.Enable ? '' : 'Đang tắt (học tại lớp / dùng chung nhóm phòng)\n') + (g.GhiChu || '') : '')
      };
    },
    doiPhong: function (L, m, p) {
      this.$emit('luu', { MaLop: L, MaMon: m, MaPhong: p || '' });
    }
  }
	}
</script>

<style scoped>
.uc-plm { font-size: 12px; }
.uc-plm__bar { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; margin: 4px 0; }
.uc-plm__chip { border: 1px solid #c5cae9; border-radius: 12px; padding: 1px 10px; background: #fff; cursor: pointer; }
.uc-plm__chip--on { background: #2e7d32; color: #fff; border-color: #2e7d32; }
.uc-plm__tim { border: 1px solid #ccc; border-radius: 4px; padding: 2px 6px; width: 180px; }
.uc-plm__sp { flex: 1 1 auto; }
.uc-plm__do { color: #c62828; font-weight: 600; }
.uc-plm__xanh { color: #2e7d32; }
.uc-plm__mo { color: #777; font-size: 11px; margin-bottom: 6px; }
.uc-plm__hang { display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-start; }
.uc-plm__wrap { overflow: auto; max-height: 65vh; border: 1px solid #e3e3e3; flex: 1 1 520px; min-width: 300px; }
.uc-plm__tbl { border-collapse: separate; border-spacing: 0; }
.uc-plm__tbl th, .uc-plm__tbl td { border-right: 1px solid #ececec; border-bottom: 1px solid #ececec; padding: 1px 4px; text-align: center; white-space: nowrap; }
.uc-plm__tbl thead th { position: sticky; top: 0; background: #f5f5f5; font-weight: 600; z-index: 2; }
.uc-plm__lop { position: sticky; left: 0; background: #fafafa; font-weight: 600; z-index: 1; min-width: 56px; }
.uc-plm__tbl thead .uc-plm__lop { z-index: 3; }
.uc-plm__o { min-width: 72px; }
.uc-plm__o--co { background: #f3effa; }
.uc-plm__o--can { background: #fff3e0; }
.uc-plm__o--tat { background: #f5f5f5; color: #999; }
.uc-plm__sel { border: none; background: transparent; font-size: 12px; cursor: pointer; }
.uc-plm__tai { flex: 0 0 240px; border: 1px solid #e3e3e3; max-height: 65vh; overflow: auto; }
.uc-plm__taihead { font-weight: 600; padding: 4px 6px; background: #f5f5f5; position: sticky; top: 0; }
.uc-plm__tairow { display: flex; gap: 6px; padding: 2px 6px; border-bottom: 1px solid #f0f0f0; }
.uc-plm__taiph { font-weight: 600; min-width: 52px; color: #4527a0; }
.uc-plm__taiten { flex: 1 1 auto; color: #777; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.uc-plm__tain { min-width: 22px; text-align: right; }
.uc-plm__rong { padding: 16px; color: #888; }
</style>