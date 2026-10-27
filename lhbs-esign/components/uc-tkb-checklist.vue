<template>
	<div class="uc-ck">
    <div v-if="!rows.length" class="uc-ck__rong">Chọn một lần chạy ở ô phía trên để xem checklist luật.</div>
    <template v-else>
      <div :class="['uc-ck__tom', demKD ? 'uc-ck__tom--loi' : (demCB ? 'uc-ck__tom--canh' : 'uc-ck__tom--ok')]">
        <b v-if="demKD">Chưa đạt: {{ demKD }} luật bắt buộc bị vi phạm</b>
        <b v-else-if="demCB">Đạt các luật bắt buộc · còn {{ demCB }} luật mềm cần xem</b>
        <b v-else>Đạt toàn bộ luật</b>
        <span>{{ demDat }} đạt · {{ demKD }} không đạt · {{ demCB }} cảnh báo</span>
      </div>
      <table class="uc-ck__tbl">
        <thead>
          <tr><th class="uc-ck__kq">Kết quả</th><th>Nhóm</th><th>Luật</th><th class="uc-ck__n">Số lần</th><th>Ví dụ</th></tr>
        </thead>
        <tbody>
          <tr v-for="r in rows" :key="r.STT" :class="'uc-ck__r--' + r.KetQua">
            <td class="uc-ck__kq"><span :class="['uc-ck__pill', 'uc-ck__pill--' + r.KetQua]">{{ nhan[r.KetQua] || r.KetQua }}</span></td>
            <td class="uc-ck__nhom">{{ r.Nhom }}</td>
            <td>{{ r.Luat }}</td>
            <td class="uc-ck__n">{{ r.KetQua === 'THONGTIN' ? '' : r.SoLan }}</td>
            <td class="uc-ck__vd">{{ r.ViDu }}</td>
          </tr>
        </tbody>
      </table>
      <div class="uc-ck__mo">Không đạt = vi phạm luật bắt buộc (trùng giờ, thiếu tiết, giờ nghỉ/bận, học sinh ở 2 nơi…), cần sửa trước khi chốt tuần. Cảnh báo = luật mềm, người sắp tay đôi khi cũng phá khi cần.</div>
    </template>
  </div>
</template>

<script>
	export default {
		props: {
    rows: { type: Array, default: function () { return []; } }
  },
  data: function () {
    return { nhan: { DAT: 'Đạt', KHONGDAT: 'Không đạt', CANHBAO: 'Cảnh báo', THONGTIN: 'Thông tin' } };
  },
  computed: {
    demDat: function () { return (this.rows || []).filter(function (r) { return r.KetQua === 'DAT'; }).length; },
    demKD: function () { return (this.rows || []).filter(function (r) { return r.KetQua === 'KHONGDAT'; }).length; },
    demCB: function () { return (this.rows || []).filter(function (r) { return r.KetQua === 'CANHBAO'; }).length; }
  }
	}
</script>

<style scoped>
.uc-ck { font-size: 13px; }
.uc-ck__rong { padding: 16px; color: #888; }
.uc-ck__tom { display: flex; flex-wrap: wrap; gap: 6px 16px; align-items: baseline; padding: 8px 12px; border-radius: 6px; margin-bottom: 10px; }
.uc-ck__tom--ok { background: #e8f5e9; color: #1b5e20; }
.uc-ck__tom--canh { background: #fff8e1; color: #6d4c00; }
.uc-ck__tom--loi { background: #ffebee; color: #b71c1c; }
.uc-ck__tbl { border-collapse: collapse; width: 100%; }
.uc-ck__tbl th, .uc-ck__tbl td { padding: 5px 10px; border-bottom: 1px solid #ececec; text-align: left; vertical-align: top; }
.uc-ck__tbl thead th { background: #f5f5f5; font-size: 12px; font-weight: 600; }
.uc-ck__kq { width: 96px; }
.uc-ck__n { text-align: right !important; width: 64px; font-variant-numeric: tabular-nums; }
.uc-ck__nhom { color: #666; white-space: nowrap; }
.uc-ck__vd { color: #555; font-size: 12px; }
.uc-ck__pill { font-size: 11.5px; font-weight: 600; padding: 1px 8px; border-radius: 10px; white-space: nowrap; }
.uc-ck__pill--DAT { background: #e8f5e9; color: #2e7d32; }
.uc-ck__pill--KHONGDAT { background: #ffebee; color: #c62828; }
.uc-ck__pill--CANHBAO { background: #fff8e1; color: #8d6e00; }
.uc-ck__pill--THONGTIN { background: #eceff1; color: #455a64; }
.uc-ck__r--KHONGDAT td { background: #fffafa; }
.uc-ck__mo { color: #777; font-size: 12px; margin-top: 8px; max-width: 90ch; }
</style>