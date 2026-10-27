<template>
	<div class="uc-tkb-grid">
    <table class="uc-tkb-grid__table">
      <thead>
        <tr>
          <th class="uc-tkb-grid__corner">Buổi / Tiết</th>
          <th v-for="thu in thuCols" :key="'th' + thu">Thứ {{ thu }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row in gridRows" :key="row.Buoi + '-' + row.Tiet">
          <td class="uc-tkb-grid__rowhead">{{ row.BuoiLabel }}<br>Tiết {{ row.Tiet }}</td>
          <td v-for="cell in row.cells" :key="row.Buoi + '-' + row.Tiet + '-' + cell.Thu"
            :class="[cellClass(row, cell), monClass(cell), groupSlotFor(row, cell) ? 'uc-tkb-grid__cell--group' : '', isSlotSelected(row, cell) ? 'uc-tkb-grid__cell--baoban' : '', markClass(row, cell), hlClass(cell)]"
            :draggable="draggable && !!cell.item"
            :title="selectMode ? 'Bấm để ' + (isSlotSelected(row, cell) ? 'bỏ chọn' : 'chọn') + ' báo bận' : (groupSlotFor(row, cell) ? 'Lớp đang tách nhóm — ' + groupSlotFor(row, cell).TenCum : ((showKhoa && cell.item) ? 'Chuột phải để ' + (cell.item.DaKhoa ? 'mở khóa' : 'khóa tay') : null))"
            @click="onCellClick(row, cell)"
            @contextmenu="onCellRightClick($event, cell)"
            @dragstart="onDragStart($event, cell.item)"
            @dragover.prevent
            @drop="onDrop($event, row, cell)">
            <div v-if="cell.item">
              <div class="uc-tkb-grid__mon" :title="cell.item.MaMon">{{ cell.item.TenMon || cell.item.MaMon }}</div>
              <div class="uc-tkb-grid__gv">{{ cell.item[subLabelField] }}</div>
              <div class="uc-tkb-grid__phong" v-if="cell.item.MaPhong">P.{{ cell.item.MaPhong }}</div>
              <v-icon v-if="editable" class="uc-tkb-grid__edit-icon" size="14"
                @click.stop="$emit('edit-cell', cell.item)">mdi-pencil</v-icon>
              <v-icon v-if="showKhoa && cell.item.DaKhoa" class="uc-tkb-grid__khoa-badge" size="13">mdi-lock</v-icon>
            </div>
            <div v-else-if="groupSlotFor(row, cell)" class="uc-tkb-grid__group-label">
              <v-icon size="12" class="uc-tkb-grid__group-icon">mdi-account-group-outline</v-icon>
              <div>Học nhóm</div>
              <div class="uc-tkb-grid__group-name">{{ groupSlotFor(row, cell).TenCum }}</div>
            </div>
            <div v-else-if="addable" class="uc-tkb-grid__add-hint">+</div>
          </td>
        </tr>
        <tr v-if="gridRows.length === 0">
          <td class="uc-tkb-grid__empty" :colspan="thuCols.length + 1">Không có dữ liệu</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
	export default {
		name: 'uc-tkb-grid',
  props: {
    items: { type: Array, default: function () { return []; } },
    editable: { type: Boolean, default: true },
    subLabelField: { type: String, default: 'TenGV' },
    // Khi truyen fixedThuCols/fixedSlots: luoi hien du Thu/Tiet co dinh (ke ca o rong), thay vi
    // chi suy tu du lieu san co (hanh vi cu, giu nguyen khi khong truyen — khong pha 4 trang dang
    // dung: tkb-sua-tay, tkb-theo-giaovien, tkb-theo-phong, tkb-xuat-in).
    fixedThuCols: { type: Array, default: null },
    fixedSlots: { type: Array, default: null },
    // addable: cho phep click o rong de bao emit 'add-cell' — trang cha tu quyet dinh hien popover
    // hay gi do, component KHONG tu mo modal.
    addable: { type: Boolean, default: false },
    // draggable: cho phep keo 1 o da co du lieu tha vao 1 o rong — emit 'move-cell'.
    draggable: { type: Boolean, default: false },
    // showKhoa: hien icon khoa/mo-khoa tren moi o da co du lieu, emit 'toggle-khoa' khi bam (2026-09-02,
    // xem tblTKB_KetQuaXep_Khoa) — chi bat o trang can phan biet tiet da-khoa-tay vs con-tu-do-cho-Auto.
    showKhoa: { type: Boolean, default: false },
    // groupSlots: cac slot (Thu,Buoi,Tiet) ma LOP GOC dang tach hoc sinh cho nhom con (2026-09-02,
    // xem spAPI_TkbCumTachSlotByLop) — chi la OVERLAY HIEN THI, khong phai du lieu that trong
    // tblTKB_KetQuaXep, nen o nay khong duoc click/keo-tha/them/khoa nhu 1 tiet that.
    groupSlots: { type: Array, default: function () { return []; } },
    // selectMode: bat che do "chon slot" (2026-09-03, dung cho dialog GV bao ban) — click bat ky o
    // nao (co du lieu hay trong deu duoc, vi bao ban co the cam luon ca o dang trong) chi emit
    // 'toggle-slot' voi {Thu,Buoi,Tiet}, KHONG lam cac hanh vi edit/swap/add binh thuong nua.
    selectMode: { type: Boolean, default: false },
    // selectedSlots: danh sach {Thu,Buoi,Tiet} dang duoc chon — chi dung de highlight khi selectMode.
    selectedSlots: { type: Array, default: function () { return []; } },
    // clickEdit (2026-10-06): false = bam o chi chon (emit 'select-cell'), KHONG mo hop sua — sua bang icon but.
    // Dung cho cua so lop o trang Bang dieu khien (bam tiet -> hien lich GV ngay ben duoi de quan sat).
    clickEdit: { type: Boolean, default: true },
    // markSlots: [{Thu,Buoi,Tiet}] — to nen xanh nhat (vd "GV dang ghim ranh" / "lop dang xem trong").
    markSlots: { type: Array, default: function () { return []; } },
    // hlLop / hlGv: vien dam cac tiet cua lop / GV nay.
    hlLop: { type: String, default: '' },
    hlGv: { type: String, default: '' }
  },
  emits: ['edit-cell', 'swap', 'add-cell', 'move-cell', 'select-cell', 'drop-external', 'toggle-khoa', 'toggle-slot'],
  data: function () {
    return {
      selectedId: null,
      dragItem: null,
      buoiLabel: { Sang: 'Sáng', Chieu: 'Chiều' },
      buoiOrder: { Sang: 0, Chieu: 1 }
    };
  },
  computed: {
    markMap: function () {
      var m = {};
      (this.markSlots || []).forEach(function (s) { m[s.Thu + '|' + s.Buoi + '|' + s.Tiet] = true; });
      return m;
    },
    thuCols: function () {
      if (this.fixedThuCols && this.fixedThuCols.length) return this.fixedThuCols;
      var thuSet = {};
      this.items.forEach(function (it) { thuSet[it.Thu] = true; });
      var cols = Object.keys(thuSet).map(Number).sort(function (a, b) { return a - b; });
      return cols.length > 0 ? cols : [2, 3, 4, 5, 6];
    },
    gridRows: function () {
      var items = this.items;
      var thuCols = this.thuCols;
      var buoiLabel = this.buoiLabel;
      var buoiOrder = this.buoiOrder;
      var slots;
      if (this.fixedSlots && this.fixedSlots.length) {
        slots = this.fixedSlots.map(function (s) { return { Buoi: s.Buoi, Tiet: s.Tiet }; });
      } else {
        var slotSet = {};
        items.forEach(function (it) {
          slotSet[it.Buoi + '|' + it.Tiet] = { Buoi: it.Buoi, Tiet: it.Tiet };
        });
        slots = Object.keys(slotSet).map(function (k) { return slotSet[k]; });
      }
      slots.sort(function (a, b) {
        var bo = buoiOrder[a.Buoi] - buoiOrder[b.Buoi];
        return bo !== 0 ? bo : a.Tiet - b.Tiet;
      });
      var rows = slots.map(function (s) {
        var cells = thuCols.map(function (thu) {
          var found = items.find(function (it) {
            return it.Thu === thu && it.Buoi === s.Buoi && it.Tiet === s.Tiet;
          });
          return { Thu: thu, item: found || null };
        });
        return { Buoi: s.Buoi, BuoiLabel: buoiLabel[s.Buoi] || s.Buoi, Tiet: s.Tiet, cells: cells };
      });
      // Danh dau tiet doi: 2 hang lien tiep cung buoi, cung Tiet ke nhau, cung Lop/Mon/GV o 1 cot
      // (2026-08-28) — de ve khung noi 2 o thanh 1 khoi, nhin ra ngay day la 1 doi tiet.
      for (var ri = 0; ri < rows.length - 1; ri++) {
        var rowA = rows[ri], rowB = rows[ri + 1];
        if (rowA.Buoi !== rowB.Buoi || rowB.Tiet !== rowA.Tiet + 1) continue;
        for (var ci = 0; ci < rowA.cells.length; ci++) {
          var a = rowA.cells[ci].item, b = rowB.cells[ci].item;
          if (a && b && a.MaMon === b.MaMon && a.MaGV === b.MaGV && a.MaLop === b.MaLop) {
            rowA.cells[ci].isDoiTop = true;
            rowB.cells[ci].isDoiBottom = true;
          }
        }
      }
      return rows;
    }
  },
  methods: {
    cellClass: function (row, cell) {
      return [
        'uc-tkb-grid__cell',
        cell.item ? 'uc-tkb-grid__cell--filled' : 'uc-tkb-grid__cell--empty',
        (!cell.item && this.addable && !this.groupSlotFor(row, cell)) ? 'uc-tkb-grid__cell--addable' : '',
        cell.item && cell.item.ID === this.selectedId ? 'uc-tkb-grid__cell--selected' : '',
        cell.isDoiTop ? 'uc-tkb-grid__cell--doi-top' : '',
        cell.isDoiBottom ? 'uc-tkb-grid__cell--doi-bottom' : '',
        (this.showKhoa && cell.item && cell.item.DaKhoa) ? 'uc-tkb-grid__cell--khoa' : ''
      ];
    },
    // To mau rieng cac mon dang co luat cung (HOP, HDTN1, TV, TOAN, TANN, TAVN) de quan sat de
    // doi chieu (2026-08-27, bo sung TANN/TAVN 2026-08-28 theo yeu cau nhin tiet Tieng Anh de hon).
    monClass: function (cell) {
      if (!cell.item) return '';
      var mon = cell.item.MaMon;
      if (mon === 'HOP') return 'uc-tkb-grid__cell--hop';
      if (mon === 'HDTN1') return 'uc-tkb-grid__cell--hdtn1';
      if (mon === 'TV') return 'uc-tkb-grid__cell--tv';
      if (mon === 'TOAN') return 'uc-tkb-grid__cell--toan';
      if (mon === 'TANN') return 'uc-tkb-grid__cell--tann';
      if (mon === 'TAVN') return 'uc-tkb-grid__cell--tavn';
      return '';
    },
    // groupSlotFor: slot nay co dang bi "chiem" boi 1 cum tach ma lop goc nhuong hoc sinh khong —
    // chi tra ket qua khi o dang TRONG (cell.item=null), vi day chi la overlay hien thi cho o trong.
    groupSlotFor: function (row, cell) {
      if (cell.item || !this.groupSlots || !this.groupSlots.length) return null;
      for (var i = 0; i < this.groupSlots.length; i++) {
        var g = this.groupSlots[i];
        if (g.Thu === cell.Thu && g.Buoi === row.Buoi && g.Tiet === row.Tiet) return g;
      }
      return null;
    },
    markClass: function (row, cell) {
      return this.markMap[cell.Thu + '|' + row.Buoi + '|' + row.Tiet] ? 'uc-tkb-grid__cell--mark' : '';
    },
    hlClass: function (cell) {
      if (!cell.item) return '';
      if (this.hlLop && cell.item.MaLop === this.hlLop) return 'uc-tkb-grid__cell--hl';
      if (this.hlGv && cell.item.MaGV === this.hlGv) return 'uc-tkb-grid__cell--hl';
      return '';
    },
    isSlotSelected: function (row, cell) {
      if (!this.selectMode || !this.selectedSlots) return false;
      for (var i = 0; i < this.selectedSlots.length; i++) {
        var s = this.selectedSlots[i];
        if (s.Thu === cell.Thu && s.Buoi === row.Buoi && s.Tiet === row.Tiet) return true;
      }
      return false;
    },
    // onCellClick (2026-10-02, theo de xuat nguoi dung "click o dau mo modal lien quan de thao tac
    // lien luon"): TRUOC DAY bam 1 o da co du lieu chi "cam" de cho (vo tri giac), phai bam trung
    // cay but rat nho o goc moi mo duoc hop thoai sua — gay nham lan tren ca 5+ trang dung chung
    // component nay. NAY: bam thang vao o la mo modal sua ngay (gui 'edit-cell'); hoan doi 2 tiet
    // chuyen sang keo-tha (xem onDrop) thay vi bam-bam, khong con tranh chap cu chi voi edit nua.
    onCellClick: function (row, cell) {
      if (this.selectMode) {
        this.$emit('toggle-slot', { Thu: cell.Thu, Buoi: row.Buoi, Tiet: row.Tiet, item: cell.item });
        return;
      }
      if (cell.item) {
        this.$emit('select-cell', cell.item);
        if (!this.editable || !this.clickEdit) return;
        this.$emit('edit-cell', cell.item);
      } else {
        if (!this.addable || this.groupSlotFor(row, cell)) return;
        this.$emit('add-cell', { Thu: cell.Thu, Buoi: row.Buoi, Tiet: row.Tiet });
      }
    },
    onCellRightClick: function (e, cell) {
      if (!this.showKhoa || !cell.item) return;
      e.preventDefault();
      this.$emit('toggle-khoa', cell.item);
    },
    onDragStart: function (e, item) {
      if (!this.draggable || !item) return;
      this.dragItem = item;
      if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move';
    },
    onDrop: function (e, row, cell) {
      if (this.groupSlotFor(row, cell)) return; // o dang "hoc nhom" khong nhan tha
      // Tha vao o DA CO du lieu (2026-10-02): hoan doi 2 tiet, thay the co che bam-bam cu (xem onCellClick).
      if (cell.item) {
        if (this.draggable && this.dragItem && this.dragItem.ID !== cell.item.ID) {
          var id1 = this.dragItem.ID;
          this.dragItem = null;
          this.$emit('swap', { id1: id1, id2: cell.item.ID });
        }
        return;
      }
      if (this.draggable && this.dragItem) {
        // Keo NOI BO: tu 1 o da co du lieu trong CHINH grid nay sang o trong.
        var item = this.dragItem;
        this.dragItem = null;
        this.$emit('move-cell', { item: item, Thu: cell.Thu, Buoi: row.Buoi, Tiet: row.Tiet });
        return;
      }
      // Keo tu BEN NGOAI grid (vd danh sach "Chua xep duoc") — doc qua dataTransfer vi nguon keo
      // la 1 component/DOM khac, khong chia se state noi bo (dragItem) voi grid nay duoc.
      if (e.dataTransfer) {
        var raw = e.dataTransfer.getData('application/json');
        if (raw) {
          try {
            this.$emit('drop-external', { item: JSON.parse(raw), Thu: cell.Thu, Buoi: row.Buoi, Tiet: row.Tiet });
          } catch (err) { /* du lieu keo khong hop le, bo qua */ }
        }
      }
    }
  }
	}
</script>

<style scoped>
.uc-tkb-grid__table {
  border-collapse: collapse;
  width: 100%;
  table-layout: fixed;
}
.uc-tkb-grid__table th,
.uc-tkb-grid__table td {
  border: 1px solid #d0d0d0;
  text-align: center;
  vertical-align: middle;
  padding: 2px;
}
.uc-tkb-grid__table thead th {
  background: #f5f5f5;
  font-weight: 600;
  font-size: 11px;
  padding: 4px 2px;
}
.uc-tkb-grid__corner {
  width: 56px;
}
.uc-tkb-grid__rowhead {
  background: #fafafa;
  font-weight: 600;
  font-size: 10px;
  line-height: 1.3;
  white-space: nowrap;
}
.uc-tkb-grid__cell {
  height: 38px;
  width: 78px;
  cursor: pointer;
  position: relative;
  transition: background-color 0.15s;
}
.uc-tkb-grid__cell--empty:hover {
  background: #f0f7ff;
}
.uc-tkb-grid__cell--filled {
  background: #fff;
}
.uc-tkb-grid__cell--filled:hover {
  background: #f5f5f5;
}
.uc-tkb-grid__cell--filled[draggable="true"] {
  cursor: grab;
}
.uc-tkb-grid__cell--filled[draggable="true"]:active {
  cursor: grabbing;
}
.uc-tkb-grid__cell--selected {
  background: #fff3cd !important;
  outline: 2px solid #f0ad4e;
  outline-offset: -2px;
}
.uc-tkb-grid__cell--addable {
  cursor: pointer;
}
/* To mau 4 mon dang co luat cung (2026-08-27) — de anh doi chieu bang mat cho de. */
.uc-tkb-grid__cell--hop {
  background: #ede7f6 !important;
}
.uc-tkb-grid__cell--hop:hover {
  background: #d1c4e9 !important;
}
.uc-tkb-grid__cell--hdtn1 {
  background: #fff3e0 !important;
}
.uc-tkb-grid__cell--hdtn1:hover {
  background: #ffe0b2 !important;
}
.uc-tkb-grid__cell--tv {
  background: #e8f5e9 !important;
}
.uc-tkb-grid__cell--tv:hover {
  background: #c8e6c9 !important;
}
.uc-tkb-grid__cell--toan {
  background: #e3f2fd !important;
}
.uc-tkb-grid__cell--toan:hover {
  background: #bbdefb !important;
}
.uc-tkb-grid__cell--tann {
  background: #e0f2f1 !important;
}
.uc-tkb-grid__cell--tann:hover {
  background: #b2dfdb !important;
}
.uc-tkb-grid__cell--tavn {
  background: #fff8e1 !important;
}
.uc-tkb-grid__cell--tavn:hover {
  background: #ffecb3 !important;
}
/* Khung noi 2 o thanh 1 khoi cho tiet doi (2026-08-28) — de nhan ra ngay day la 1 doi tiet lien
   nhau, khong lan sang cac tiet le xung quanh. */
.uc-tkb-grid__cell--doi-top {
  border-left: 2px solid #ff7043 !important;
  border-right: 2px solid #ff7043 !important;
  border-top: 2px solid #ff7043 !important;
  border-bottom: 1px dashed #ff7043 !important;
}
.uc-tkb-grid__cell--doi-bottom {
  border-left: 2px solid #ff7043 !important;
  border-right: 2px solid #ff7043 !important;
  border-bottom: 2px solid #ff7043 !important;
  border-top: none !important;
}
.uc-tkb-grid__cell--addable:hover {
  background: #e8f5e9;
}
.uc-tkb-grid__cell--group {
  background: repeating-linear-gradient(135deg, #e8eaf6, #e8eaf6 6px, #c5cae9 6px, #c5cae9 12px);
  cursor: not-allowed;
}
.uc-tkb-grid__group-label {
  color: #5c6bc0;
  font-size: 8.5px;
  line-height: 1.25;
  padding: 2px;
  font-weight: 600;
}
.uc-tkb-grid__group-icon {
  color: #5c6bc0 !important;
  margin-bottom: 1px;
}
.uc-tkb-grid__group-name {
  font-size: 8px;
  font-style: italic;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.uc-tkb-grid__add-hint {
  color: #c8e6c9;
  font-size: 16px;
  font-weight: 700;
  line-height: 1;
  transition: color 0.15s;
}
.uc-tkb-grid__cell--addable:hover .uc-tkb-grid__add-hint {
  color: #4caf50;
}
.uc-tkb-grid__mon {
  font-weight: 700;
  font-size: 9.5px;
  line-height: 1.15;
  color: #1565c0;
  overflow-wrap: break-word;
  hyphens: auto;
}
.uc-tkb-grid__gv {
  font-size: 9px;
  line-height: 1.2;
  color: #444;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  padding: 0 2px;
}
.uc-tkb-grid__phong {
  font-size: 8px;
  line-height: 1.1;
  color: #888;
}
.uc-tkb-grid__edit-icon {
  position: absolute;
  top: 0px;
  right: 0px;
  opacity: 0.35;
  cursor: pointer;
  transform: scale(0.8);
}
.uc-tkb-grid__edit-icon:hover {
  opacity: 1;
}
.uc-tkb-grid__khoa-badge {
  position: absolute;
  top: 0px;
  left: 0px;
  color: #e65100;
  opacity: 0.9;
  pointer-events: none;
}
.uc-tkb-grid__cell--khoa {
  box-shadow: inset 0 0 0 1.5px #e65100;
}
.uc-tkb-grid__cell--baoban {
  background: #ffcdd2 !important;
  outline: 2px solid #e53935;
  outline-offset: -2px;
}
/* O trong duoc danh dau: nen xanh; o co tiet duoc danh dau: vach xanh duoi (giu mau mon). */
.uc-tkb-grid__cell--empty.uc-tkb-grid__cell--mark {
  background-color: #c8e6c9 !important;
}
.uc-tkb-grid__cell--filled.uc-tkb-grid__cell--mark {
  box-shadow: inset 0 -4px 0 #43a047;
}
.uc-tkb-grid__cell--hl {
  box-shadow: inset 0 0 0 2px #6a1b9a;
}
.uc-tkb-grid__empty {
  padding: 24px;
  color: #888;
}
</style>