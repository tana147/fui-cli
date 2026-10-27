<template>
	<div class="uc-tkb-dinhmuc-grid">
    <table class="uc-tkb-dinhmuc-grid__table">
      <thead>
        <tr>
          <th class="uc-tkb-dinhmuc-grid__corner">Môn / Tuần</th>
          <th v-for="tuan in tuanCols" :key="'tw' + tuan.TuanTrongNam" :title="tuan.TenTuan"
            :class="headClass(tuan)">
            <div class="uc-tkb-dinhmuc-grid__tuanso">{{ tuan.TuanTrongNam }}</div>
            <div class="uc-tkb-dinhmuc-grid__tuanngay">{{ ngayLabel(tuan.NgayBatDau, tuan.NgayKetThuc) }}</div>
            <div v-if="tongTuanCua(tuan.TuanTrongNam)" class="uc-tkb-dinhmuc-grid__tuantong"
              :class="tongTuanCua(tuan.TuanTrongNam).BatThuong ? 'uc-tkb-dinhmuc-grid__tuantong--canh' : 'uc-tkb-dinhmuc-grid__tuantong--ok'">
              {{ tongTuanLabel(tongTuanCua(tuan.TuanTrongNam)) }}
            </div>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row in gridRows" :key="row.MaMon">
          <td class="uc-tkb-dinhmuc-grid__rowhead">
            <div class="uc-tkb-dinhmuc-grid__monten">{{ row.TenMon || row.MaMon }}</div>
            <div v-if="row.GVInfo" class="uc-tkb-dinhmuc-grid__gvrow" :title="row.GVInfo">{{ row.GVInfo }}</div>
            <div v-if="row.QuyTacLabel" class="uc-tkb-dinhmuc-grid__quytac" @click.stop="onQuyTacClick(row)">
              {{ row.QuyTacLabel }} <span class="uc-tkb-dinhmuc-grid__quytac-icon">ⓘ</span>
            </div>
          </td>
          <td v-for="cell in row.cells" :key="row.MaMon + '-' + cell.TuanTrongNam"
            :class="cellClass(cell)"
            @click="onCellClick(row, cell)">
            <div v-if="cell.item">
              <div class="uc-tkb-dinhmuc-grid__tiet">{{ soTietLabel(cell.item) }}</div>
              <div class="uc-tkb-dinhmuc-grid__gv">{{ cell.item.SoGV }} GV · {{ cell.item.SoLop }} lớp</div>
            </div>
          </td>
        </tr>
        <tr v-if="gridRows.length === 0">
          <td class="uc-tkb-dinhmuc-grid__empty" :colspan="tuanCols.length + 1">Không có dữ liệu</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
	export default {
		name: 'uc-tkb-dinhmuc-grid',
    props: {
      items: { type: Array, default: function () { return []; } },
      // tongTuan: tong dinh muc/tuan (tu spAPI_TkbDinhMucTuanTongTheoTuan) — hien thang so ngay trong
      // header cot tuan (2026-08-28), khong bat nguoi dung phai nhin rieng dai chip ben ngoai nua.
      tongTuan: { type: Array, default: function () { return []; } }
    },
    emits: ['select-cell', 'select-quytac'],
    computed: {
      tuanCols: function () {
        var seen = {};
        var cols = [];
        this.items.forEach(function (it) {
          if (!seen[it.TuanTrongNam]) {
            seen[it.TuanTrongNam] = true;
            cols.push({ TuanTrongNam: it.TuanTrongNam, TenTuan: it.TenTuan, NgayBatDau: it.NgayBatDau, NgayKetThuc: it.NgayKetThuc });
          }
        });
        cols.sort(function (a, b) { return a.TuanTrongNam - b.TuanTrongNam; });
        return cols;
      },
      // Tuan chua ngay hom nay (2026-08-28) — dung de ve duong ke/to mau cot "dang o day" tren luoi,
      // tra ve null neu hom nay nam ngoai pham vi cac tuan dang hien (vd xem Hoc ky 2 luc dang HK1).
      currentTuanTrongNam: function () {
        var today = new Date(); today.setHours(0, 0, 0, 0);
        var found = this.tuanCols.find(function (t) {
          if (!t.NgayBatDau) return false;
          var bd = new Date(t.NgayBatDau); bd.setHours(0, 0, 0, 0);
          var kt = t.NgayKetThuc ? new Date(t.NgayKetThuc) : bd;
          kt.setHours(0, 0, 0, 0);
          return today >= bd && today <= kt;
        });
        return found ? found.TuanTrongNam : null;
      },
      gridRows: function () {
        var items = this.items;
        var tuanCols = this.tuanCols;
        var monMap = {};
        var monOrder = [];
        var self = this;
        items.forEach(function (it) {
          if (!monMap[it.MaMon]) {
            monMap[it.MaMon] = { MaMon: it.MaMon, TenMon: it.TenMon, GVInfo: it.GVInfo, QuyTacInfo: it.QuyTacInfo };
            monOrder.push(it.MaMon);
          } else if (!monMap[it.MaMon].GVInfo && it.GVInfo) {
            monMap[it.MaMon].GVInfo = it.GVInfo;
          }
        });
        return monOrder.map(function (maMon) {
          var mon = monMap[maMon];
          var cells = tuanCols.map(function (tuan) {
            var found = items.find(function (it) {
              return it.MaMon === maMon && it.TuanTrongNam === tuan.TuanTrongNam;
            });
            return { TuanTrongNam: tuan.TuanTrongNam, item: found || null };
          });
          return {
            MaMon: mon.MaMon,
            TenMon: mon.TenMon,
            GVInfo: mon.GVInfo,
            QuyTacLabel: self.quyTacLabel(mon.QuyTacInfo),
            cells: cells
          };
        });
      }
    },
    methods: {
      formatDdMm: function (isoDate) {
        var d = new Date(isoDate);
        var dd = ('0' + d.getDate()).slice(-2);
        var mm = ('0' + (d.getMonth() + 1)).slice(-2);
        return dd + '/' + mm;
      },
      ngayLabel: function (batDau, ketThuc) {
        if (!batDau) return '';
        var tuBd = this.formatDdMm(batDau);
        var tuKt = ketThuc ? this.formatDdMm(ketThuc) : '';
        if (!tuKt || tuKt === tuBd) return tuBd;
        return tuBd + '-' + tuKt;
      },
      quyTacLabel: function (quyTacInfo) {
        if (!quyTacInfo) return '';
        var map = {
          MaxTietMoiNgay: 'Max tiết/ngày',
          MaxDoiMoiNgay: 'Max đôi/ngày',
          CamKhungGio: 'Cấm khung giờ',
          HopBatBuocKhoaCung: 'Khóa cứng lịch họp',
          TV_Khoi1_Pattern: 'Mẫu TV khối 1',
          TV_Khoi2_Pattern: 'Mẫu TV khối 2',
          TV_Khoi3_Pattern: 'Mẫu TV khối 3',
          TV_Khoi45_Pattern: 'Mẫu TV khối 4-5',
          HDTN1_Pattern: 'Mẫu HĐTN1'
        };
        return quyTacInfo.split(', ').map(function (code) { return map[code] || code; }).join(', ');
      },
      soTietLabel: function (item) {
        if (item.SoTietMin === item.SoTietMax) return item.SoTietMin + ' tiết';
        return item.SoTietMin + '-' + item.SoTietMax + ' tiết';
      },
      cellClass: function (cell) {
        return [
          'uc-tkb-dinhmuc-grid__cell',
          cell.item ? 'uc-tkb-dinhmuc-grid__cell--filled' : 'uc-tkb-dinhmuc-grid__cell--empty',
          cell.TuanTrongNam === this.currentTuanTrongNam ? 'uc-tkb-dinhmuc-grid__cell--current' : ''
        ];
      },
      headClass: function (tuan) {
        return tuan.TuanTrongNam === this.currentTuanTrongNam ? 'uc-tkb-dinhmuc-grid__col--current' : '';
      },
      tongTuanCua: function (tuanTrongNam) {
        return this.tongTuan.find(function (t) { return t.TuanTrongNam === tuanTrongNam; }) || null;
      },
      tongTuanLabel: function (t) {
        return t.TongMin === t.TongMax ? (t.TongMin + ' tiết') : (t.TongMin + '-' + t.TongMax + ' tiết');
      },
      onQuyTacClick: function (row) {
        this.$emit('select-quytac', { MaMon: row.MaMon, TenMon: row.TenMon });
      },
      onCellClick: function (row, cell) {
        if (!cell.item) return;
        this.$emit('select-cell', {
          MaMon: row.MaMon,
          TenMon: row.TenMon,
          TuanTrongNam: cell.TuanTrongNam,
          TenTuan: cell.item.TenTuan
        });
      }
    }
	}
</script>

<style scoped>
.uc-tkb-dinhmuc-grid__table {
  border-collapse: collapse;
  width: 100%;
  table-layout: fixed;
}
.uc-tkb-dinhmuc-grid__table th,
.uc-tkb-dinhmuc-grid__table td {
  border: 1px solid #d0d0d0;
  text-align: center;
  vertical-align: middle;
  padding: 2px;
}
.uc-tkb-dinhmuc-grid__table thead th {
  background: #f5f5f5;
  font-weight: 600;
  font-size: 10px;
  padding: 4px 2px;
  white-space: normal;
  overflow: visible;
  height: auto;
}
.uc-tkb-dinhmuc-grid__corner {
  width: 220px;
}
.uc-tkb-dinhmuc-grid__tuanso {
  font-weight: 700;
}
.uc-tkb-dinhmuc-grid__tuanngay {
  font-weight: 400;
  color: #777;
  font-size: 9px;
}
.uc-tkb-dinhmuc-grid__tuantong {
  font-weight: 700;
  font-size: 10px;
  margin-top: 2px;
  border-radius: 3px;
  padding: 1px 3px;
}
.uc-tkb-dinhmuc-grid__tuantong--ok {
  color: #2e7d32;
  background: #e8f5e9;
}
.uc-tkb-dinhmuc-grid__tuantong--canh {
  color: #c62828;
  background: #ffebee;
}
/* Duong ke timeline cho cot tuan hien tai (2026-08-28) — vien 2 ben day mau xanh de nhan ra ngay
   "dang o day", ke ca khi cuon ngang qua nhieu tuan (border ap len ca thead lan tbody). */
.uc-tkb-dinhmuc-grid__col--current {
  border-left: 3px solid #1976d2 !important;
  border-right: 3px solid #1976d2 !important;
  background: #e3f2fd !important;
}
.uc-tkb-dinhmuc-grid__cell--current {
  border-left: 3px solid #1976d2 !important;
  border-right: 3px solid #1976d2 !important;
}
.uc-tkb-dinhmuc-grid__rowhead {
  background: #fafafa;
  text-align: left;
  padding: 4px 6px;
  white-space: normal;
  vertical-align: top;
}
.uc-tkb-dinhmuc-grid__monten {
  font-weight: 600;
  font-size: 11px;
}
.uc-tkb-dinhmuc-grid__gvrow {
  font-size: 9px;
  color: #555;
  line-height: 1.3;
  margin-top: 2px;
}
.uc-tkb-dinhmuc-grid__quytac {
  font-size: 9px;
  color: #8a5300;
  background: #fff3e0;
  border-radius: 3px;
  padding: 1px 4px;
  margin-top: 2px;
  display: inline-block;
  cursor: pointer;
}
.uc-tkb-dinhmuc-grid__quytac:hover {
  background: #ffe0b2;
}
.uc-tkb-dinhmuc-grid__quytac-icon {
  opacity: 0.7;
}
.uc-tkb-dinhmuc-grid__cell {
  height: 34px;
  width: 60px;
  cursor: default;
}
.uc-tkb-dinhmuc-grid__cell--filled {
  background: #fff;
  cursor: pointer;
}
.uc-tkb-dinhmuc-grid__cell--filled:hover {
  background: #f0f7ff;
}
.uc-tkb-dinhmuc-grid__cell--empty {
  background: #fafafa;
}
.uc-tkb-dinhmuc-grid__tiet {
  font-weight: 700;
  font-size: 11px;
  color: #1565c0;
}
.uc-tkb-dinhmuc-grid__gv {
  font-size: 9px;
  color: #666;
}
.uc-tkb-dinhmuc-grid__empty {
  padding: 24px;
  color: #888;
}
</style>