<template>
	<div class="uc-tm">
    <div class="uc-tm__mo">
      Khi xếp tuần này, hệ thống lấy lịch đã có của tuần trước làm điểm xuất phát và chỉ đổi phần không còn dùng được.
      Bảng cho thấy trước tuần này có bao nhiêu ô phải đổi và vì sao. Tuần nguồn của từng khối là tuần gần nhất khối đó học đủ ngày.
    </div>
    <div class="uc-tm__kt">
      <div class="uc-tm__kthead">
        <b>Kiểm tra dữ liệu tuần</b>
        <span v-if="!kiemTra.length" class="uc-tm__ok">Chưa có kết quả</span>
        <span v-else-if="!demLoi && !demCanh" class="uc-tm__ok">Không có lỗi hay cảnh báo</span>
        <span v-if="demLoi" class="uc-tm__pill uc-tm__pill--loi">{{ demLoi }} lỗi · chặn chạy</span>
        <span v-if="demCanh" class="uc-tm__pill uc-tm__pill--canh">{{ demCanh }} cảnh báo</span>
        <span v-if="demTin" class="uc-tm__pill">{{ demTin }} thông tin</span>
      </div>
      <div v-for="(k, i) in kiemTra" :key="'kt' + i" :class="['uc-tm__ktrow', 'uc-tm__ktrow--' + k.MucDo]">
        <span class="uc-tm__muc">{{ tenMuc[k.MucDo] || k.MucDo }}</span>
        <span class="uc-tm__nhom">{{ k.Nhom }}</span>
        <span class="uc-tm__dt">{{ k.DoiTuong }}</span>
        <span class="uc-tm__mota">{{ k.MoTa }} <i>{{ k.GoiY }}</i></span>
      </div>
    </div>
    <div v-if="tong" class="uc-tm__tom">
      <div class="uc-tm__kpi"><span class="uc-tm__v">{{ tong.PhanTramGiu }}%</span><span class="uc-tm__l">ô giữ được so với định mức tuần này</span></div>
      <div class="uc-tm__kpi"><span class="uc-tm__v">{{ vo }}</span><span class="uc-tm__l">ô của tuần nguồn không còn dùng được</span></div>
      <div class="uc-tm__kpi"><span class="uc-tm__v">{{ tong.CanThem }}</span><span class="uc-tm__l">tiết cần xếp mới</span></div>
    </div>
    <div class="uc-tm__wrap fpScrollbar">
      <table class="uc-tm__tbl">
        <thead>
          <tr>
            <th>Khối</th><th>Tuần nguồn</th><th>Ô nguồn</th>
            <th title="Lớp nghỉ cả ngày hoặc cả buổi">Nghỉ</th>
            <th title="Giáo viên báo bận">Báo bận</th>
            <th title="Giáo viên có họp mới ở ô đó">Họp</th>
            <th title="Định mức lớp–môn của tuần này ít hơn tuần nguồn">Định mức giảm</th>
            <th>Giữ được</th><th>Cần xếp mới</th><th class="uc-tm__bar">Tỉ lệ giữ</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in dong" :key="r.Khoi" :class="r.tong ? 'uc-tm__tong' : ''">
            <td>{{ r.Khoi }}</td>
            <td class="uc-tm__n">{{ r.tong ? '' : r.TuanNguon }}</td>
            <td class="uc-tm__n">{{ r.SoONguon }}</td>
            <td :class="cls(r.GoNghi)">{{ r.GoNghi }}</td>
            <td :class="cls(r.GoBan)">{{ r.GoBan }}</td>
            <td :class="cls(r.GoHop)">{{ r.GoHop }}</td>
            <td :class="cls(r.GoDinhMuc)">{{ r.GoDinhMuc }}</td>
            <td class="uc-tm__n">{{ r.SoOGiu }}</td>
            <td :class="cls(r.CanThem)">{{ r.CanThem }}</td>
            <td class="uc-tm__bar"><span class="uc-tm__track"><span class="uc-tm__fill" :class="mau(r.PhanTramGiu)" :style="{ width: (r.PhanTramGiu || 0) + '%' }"></span></span><span class="uc-tm__pc">{{ r.PhanTramGiu }}%</span></td>
          </tr>
          <tr v-if="!dong.length"><td class="uc-tm__rong" colspan="10">Chưa có tuần nguồn để so sánh. Chọn tuần cần xếp, hoặc chốt tuần trước rồi quay lại.</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    rows: { type: Array, default: function () { return []; } },
    kiemTra: { type: Array, default: function () { return []; } }
  },
  data: function () {
    return { tenMuc: { LOI: 'Lỗi', CANHBAO: 'Cảnh báo', THONGTIN: 'Thông tin' } };
  },
  computed: {
    demLoi: function () { return (this.kiemTra || []).filter(function (k) { return k.MucDo === 'LOI'; }).length; },
    demCanh: function () { return (this.kiemTra || []).filter(function (k) { return k.MucDo === 'CANHBAO'; }).length; },
    demTin: function () { return (this.kiemTra || []).filter(function (k) { return k.MucDo === 'THONGTIN'; }).length; },
    dong: function () {
      var n = (this.rows || []).length;
      return (this.rows || []).map(function (r, i) {
        return Object.assign({}, r, { tong: i === n - 1 && String(r.Khoi).indexOf('Toàn') === 0 });
      });
    },
    tong: function () {
      var d = this.dong;
      return d.length && d[d.length - 1].tong ? d[d.length - 1] : null;
    },
    vo: function () {
      var t = this.tong;
      return t ? (t.GoNghi + t.GoBan + t.GoHop + t.GoDinhMuc) : 0;
    }
  },
  methods: {
    cls: function (v) { return 'uc-tm__n' + (v > 0 ? ' uc-tm__co' : ' uc-tm__khong'); },
    mau: function (p) { return p >= 95 ? 'uc-tm__fill--tot' : (p >= 85 ? 'uc-tm__fill--vua' : 'uc-tm__fill--thap'); }
  }
	}
</script>

<style scoped>
.uc-tm { font-size: 13px; }
.uc-tm__mo { color: #666; margin: 4px 0 10px; max-width: 80ch; }
.uc-tm__tom { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 10px; }
.uc-tm__kpi { border: 1px solid #e0e0e0; border-radius: 6px; padding: 8px 14px; display: flex; flex-direction: column; min-width: 160px; }
.uc-tm__v { font-size: 22px; font-weight: 600; font-variant-numeric: tabular-nums; }
.uc-tm__l { color: #777; font-size: 12px; }
.uc-tm__wrap { overflow: auto; border: 1px solid #e3e3e3; }
.uc-tm__tbl { border-collapse: collapse; width: 100%; }
.uc-tm__tbl th, .uc-tm__tbl td { padding: 5px 10px; border-bottom: 1px solid #ececec; text-align: left; white-space: nowrap; }
.uc-tm__tbl thead th { background: #f5f5f5; font-weight: 600; font-size: 12px; position: sticky; top: 0; }
.uc-tm__n { text-align: right !important; font-variant-numeric: tabular-nums; }
.uc-tm__co { color: #b71c1c; font-weight: 600; }
.uc-tm__khong { color: #bdbdbd; }
.uc-tm__tong td { font-weight: 700; background: #fafafa; border-top: 2px solid #bdbdbd; }
.uc-tm__bar { min-width: 190px; }
.uc-tm__track { display: inline-block; vertical-align: middle; width: 120px; height: 8px; background: #eceff1; border-radius: 4px; overflow: hidden; }
.uc-tm__fill { display: block; height: 100%; }
.uc-tm__fill--tot { background: #2e7d32; }
.uc-tm__fill--vua { background: #f9a825; }
.uc-tm__fill--thap { background: #c62828; }
.uc-tm__pc { margin-left: 8px; font-variant-numeric: tabular-nums; }
.uc-tm__rong { padding: 16px; color: #888; }
.uc-tm__kt { border: 1px solid #e3e3e3; border-radius: 6px; margin-bottom: 12px; max-height: 260px; overflow: auto; }
.uc-tm__kthead { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; padding: 6px 10px; background: #f5f5f5; position: sticky; top: 0; }
.uc-tm__ok { color: #2e7d32; }
.uc-tm__pill { font-size: 11.5px; font-weight: 600; padding: 1px 8px; border-radius: 10px; background: #eceff1; color: #455a64; }
.uc-tm__pill--loi { background: #ffebee; color: #b71c1c; }
.uc-tm__pill--canh { background: #fff8e1; color: #8d6e00; }
.uc-tm__ktrow { display: flex; flex-wrap: wrap; gap: 4px 10px; padding: 4px 10px; border-top: 1px solid #f0f0f0; border-left: 3px solid #cfd8dc; }
.uc-tm__ktrow--LOI { border-left-color: #c62828; }
.uc-tm__ktrow--CANHBAO { border-left-color: #f9a825; }
.uc-tm__muc { font-weight: 600; min-width: 70px; }
.uc-tm__nhom { color: #555; min-width: 130px; }
.uc-tm__dt { font-weight: 600; min-width: 160px; }
.uc-tm__mota { flex: 1 1 320px; min-width: 0; }
.uc-tm__mota i { color: #777; }
</style>