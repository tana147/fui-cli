<template>
	<div class="uc-pt">
    <div class="uc-pt__tom">
      <b>Tổng quan phòng</b>
      <span>{{ phongs.length }} phòng · {{ soTiet }} tiết có phòng</span>
      <span v-if="soTrung" class="uc-pt__do">· {{ soTrung }} tiết trùng phòng</span>
      <span v-else class="uc-pt__xanh">· không trùng phòng</span>
      <span class="uc-pt__sp"></span>
      <span class="uc-pt__mo">Ô đỏ: 2 lớp cùng phòng cùng tiết · rê chuột để xem lớp, môn, giáo viên</span>
    </div>
    <div class="uc-pt__wrap fpScrollbar">
      <table class="uc-pt__tbl">
        <thead>
          <tr>
            <th class="uc-pt__nhom" rowspan="2">Nhóm</th>
            <th class="uc-pt__ten" rowspan="2">Phòng</th>
            <th v-for="t in thuCols" :key="'t' + t" :colspan="slots.length" class="uc-pt__thu">Thứ {{ t }}</th>
          </tr>
          <tr>
            <th v-for="h in dauCot" :key="h.k" :class="h.cls">{{ h.txt }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in dong" :key="r.ph" :class="r.dau ? 'uc-pt__dau' : ''">
            <td class="uc-pt__nhom">{{ r.dau ? r.nhom : '' }}</td>
            <td class="uc-pt__ten" :title="r.ph">{{ r.ph }}</td>
            <td v-for="c in r.cells" :key="c.k" :class="c.cls" :title="c.title">{{ c.txt }}</td>
          </tr>
          <tr v-if="!dong.length">
            <td class="uc-pt__rong" :colspan="2 + thuCols.length * slots.length">Lần chạy này chưa có tiết nào được gán phòng</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    items: { type: Array, default: function () { return []; } },
    thuCols: { type: Array, default: function () { return [2, 3, 4, 5, 6]; } }
  },
  data: function () {
    return {
      slots: [
        { Buoi: 'Sang', Tiet: 1 }, { Buoi: 'Sang', Tiet: 2 }, { Buoi: 'Sang', Tiet: 3 }, { Buoi: 'Sang', Tiet: 4 }, { Buoi: 'Sang', Tiet: 5 },
        { Buoi: 'Chieu', Tiet: 1 }, { Buoi: 'Chieu', Tiet: 2 }, { Buoi: 'Chieu', Tiet: 3 }, { Buoi: 'Chieu', Tiet: 4 }
      ],
      nhomDinhNghia: [
        ['STEM', /^(STEAM|LI$|HOA$|SINH$)/], ['AI', /^AI\d/], ['Tin học', /^TIN\d/], ['Mĩ thuật', /^MT\d/],
        ['Âm nhạc', /^AN\d/], ['Thư viện', /^TV\d/], ['Tiếng Anh', /^TA\d/], ['Hồ bơi', /^BOI\d/]
      ]
    };
  },
  computed: {
    idx: function () {
      var m = {};
      (this.items || []).forEach(function (it) {
        if (!it.MaPhong || it.MaLop === 'HOP' || it.MaMon === 'HOP') return;
        var k = it.MaPhong + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet;
        (m[k] || (m[k] = [])).push(it);
      });
      return m;
    },
    phongs: function () {
      var s = {};
      Object.keys(this.idx).forEach(function (k) { s[k.split('|')[0]] = true; });
      return Object.keys(s);
    },
    dauCot: function () {
      var self = this, out = [];
      this.thuCols.forEach(function (t) {
        self.slots.forEach(function (s, si) {
          out.push({ k: 'h' + t + s.Buoi + s.Tiet, txt: (s.Buoi === 'Sang' ? 'S' : 'C') + s.Tiet,
            cls: 'uc-pt__slot' + (si === 0 ? ' uc-pt__ngay' : '') + (s.Buoi === 'Chieu' ? ' uc-pt__chieu' : '') });
        });
      });
      return out;
    },
    dong: function () {
      var self = this, out = [];
      this.nhomDinhNghia.concat([['Khác', /./]]).forEach(function (d) {
        var ds = self.phongs.filter(function (p) {
          return d[1].test(p) && !out.some(function (r) { return r.ph === p; });
        }).sort();
        ds.forEach(function (p, i) { out.push({ ph: p, nhom: d[0], dau: i === 0, cells: self.oCua(p) }); });
      });
      return out;
    },
    soTiet: function () {
      var self = this, n = 0;
      Object.keys(this.idx).forEach(function (k) { n += self.idx[k].length; });
      return n;
    },
    soTrung: function () {
      var self = this, n = 0;
      Object.keys(this.idx).forEach(function (k) { if (self.lops(self.idx[k]).length > 1) n++; });
      return n;
    }
  },
  methods: {
    lops: function (rows) {
      var l = [];
      rows.forEach(function (r) { if (l.indexOf(r.MaLop) < 0) l.push(r.MaLop); });
      return l;
    },
    oCua: function (p) {
      var self = this, out = [];
      this.thuCols.forEach(function (t) {
        self.slots.forEach(function (s, si) {
          var rows = self.idx[p + '|' + t + '|' + s.Buoi + '|' + s.Tiet] || [];
          var l = self.lops(rows);
          out.push({
            k: p + t + s.Buoi + s.Tiet,
            txt: l.map(function (x) { return String(x).replace(/^0(\d)/, '$1'); }).join('+'),
            title: rows.length ? p + ' · Thứ ' + t + (s.Buoi === 'Sang' ? ' sáng' : ' chiều') + ' tiết ' + s.Tiet + '\n'
              + rows.map(function (r) { return r.MaLop + ' · ' + (r.TenMon || r.MaMon) + ' · ' + (r.TenGV || r.MaGV || ''); }).join('\n') : '',
            cls: 'uc-pt__o' + (si === 0 ? ' uc-pt__ngay' : '') + (s.Buoi === 'Chieu' ? ' uc-pt__chieu' : '')
              + (l.length > 1 ? ' uc-pt__o--trung' : (l.length ? ' uc-pt__o--co' : ''))
          });
        });
      });
      return out;
    }
  }
	}
</script>

<style scoped>
.uc-pt { font-size: 12px; margin-bottom: 8px; }
.uc-pt__tom { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin: 4px 0 6px; }
.uc-pt__sp { flex: 1 1 auto; }
.uc-pt__mo { color: #888; font-size: 11px; }
.uc-pt__do { color: #c62828; font-weight: 600; }
.uc-pt__xanh { color: #2e7d32; }
.uc-pt__wrap { overflow: auto; max-height: 60vh; border: 1px solid #e3e3e3; }
.uc-pt__tbl { border-collapse: separate; border-spacing: 0; }
.uc-pt__tbl th, .uc-pt__tbl td { border-right: 1px solid #ececec; border-bottom: 1px solid #ececec; text-align: center; padding: 0 2px; white-space: nowrap; }
.uc-pt__tbl thead th { position: sticky; top: 0; background: #f5f5f5; font-weight: 600; z-index: 2; }
.uc-pt__tbl thead tr:first-child th { height: 20px; line-height: 20px; padding: 0 4px; }
.uc-pt__tbl thead tr:nth-child(2) th { top: 20px; height: 18px; line-height: 18px; font-size: 9px; color: #666; font-weight: 400; }
.uc-pt__nhom { position: sticky; left: 0; background: #fafafa; z-index: 1; min-width: 70px; text-align: left !important; color: #4527a0; }
.uc-pt__ten { position: sticky; left: 70px; background: #fafafa; z-index: 1; min-width: 52px; font-weight: 600; border-right: 2px solid #9e9e9e !important; }
.uc-pt__tbl thead .uc-pt__nhom, .uc-pt__tbl thead .uc-pt__ten { z-index: 3; }
.uc-pt__thu { border-left: 2px solid #9e9e9e; }
.uc-pt__ngay { border-left: 2px solid #9e9e9e !important; }
.uc-pt__chieu { background-image: linear-gradient(rgba(0, 0, 0, 0.03), rgba(0, 0, 0, 0.03)); }
.uc-pt__o, .uc-pt__slot { min-width: 34px; max-width: 46px; height: 20px; overflow: hidden; text-overflow: ellipsis; font-size: 10px; }
.uc-pt__o--co { background: #ede7f6; color: #311b92; }
.uc-pt__o--trung { background: #ffcdd2; color: #b71c1c; font-weight: 700; }
.uc-pt__dau td { border-top: 2px solid #d1c4e9; }
.uc-pt__rong { padding: 16px; color: #888; }
</style>