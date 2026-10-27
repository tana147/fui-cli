<template>
	<div class="uc-stem-grid">
    <table class="uc-stem-grid__table">
      <thead>
        <tr>
          <th class="uc-stem-grid__corner">Tuần</th>
          <th v-for="k in khoiList" :key="k.value">{{ k.text }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="week in weekRows" :key="week.ThuTuTuan">
          <td class="uc-stem-grid__rowhead">{{ week.TuanDisplay }}</td>
          <td v-for="k in khoiList" :key="week.ThuTuTuan + '-' + k.value"
            :class="cellClass(week, k)"
            @click="onCellClick(week, k)">
            <div v-if="week.cells[k.value]">
              <div class="uc-stem-grid__topic">{{ week.cells[k.value].topic }}</div>
              <div class="uc-stem-grid__lop-list">
                <span class="uc-stem-grid__lop-item" v-for="lg in week.cells[k.value].lopGv" :key="lg.MaLop">
                  <span class="uc-stem-grid__lop">{{ lg.MaLop }}</span>
                  <span class="uc-stem-grid__gv">{{ lg.TenGV }}</span>
                </span>
              </div>
            </div>
            <div v-else class="uc-stem-grid__add-hint">+</div>
          </td>
        </tr>
        <tr v-if="weekRows.length === 0">
          <td class="uc-stem-grid__empty" :colspan="khoiList.length + 1">Không có dữ liệu</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
	export default {
		name: 'uc-stem-grid',
    props: {
      items: { type: Array, default: function () { return []; } },
      khoiList: { type: Array, default: function () { return []; } }
    },
    emits: ['cell-click', 'add-cell'],
    computed: {
      weekRows: function () {
        var byWeek = {};
        this.items.forEach(function (r) {
          if (!byWeek[r.ThuTuTuan]) byWeek[r.ThuTuTuan] = { ThuTuTuan: r.ThuTuTuan, TuanDisplay: r.TuanDisplay, rows: [], cells: {} };
          byWeek[r.ThuTuTuan].rows.push(r);
        });
        var weeks = Object.keys(byWeek).map(function (k) { return byWeek[k]; })
          .sort(function (a, b) { return a.ThuTuTuan - b.ThuTuTuan; });
        weeks.forEach(function (w) {
          var byKhoi = {};
          w.rows.forEach(function (r) {
            if (!byKhoi[r.Khoi]) byKhoi[r.Khoi] = [];
            byKhoi[r.Khoi].push(r);
          });
          Object.keys(byKhoi).forEach(function (khoi) {
            var rowsKhoi = byKhoi[khoi].slice().sort(function (a, b) { return a.MaLop < b.MaLop ? -1 : 1; });
            var byGv = {};
            var gvOrder = [];
            rowsKhoi.forEach(function (r) {
              if (!byGv[r.TenGV]) { byGv[r.TenGV] = []; gvOrder.push(r.TenGV); }
              byGv[r.TenGV].push(r.MaLop);
            });
            var lopGv = gvOrder.map(function (gv) { return { MaLop: byGv[gv].join(', '), TenGV: gv }; });
            w.cells[khoi] = {
              topic: rowsKhoi[0].MonPhuTrach + ': ' + rowsKhoi[0].ChuDe,
              lopGv: lopGv,
              rows: rowsKhoi
            };
          });
        });
        return weeks;
      }
    },
    methods: {
      cellClass: function (week, k) {
        return ['uc-stem-grid__cell', week.cells[k.value] ? 'uc-stem-grid__cell--filled' : 'uc-stem-grid__cell--empty'];
      },
      onCellClick: function (week, k) {
        var cell = week.cells[k.value];
        if (!cell) {
          this.$emit('add-cell', { ThuTuTuan: week.ThuTuTuan, TuanDisplay: week.TuanDisplay, Khoi: k.value, KhoiText: k.text });
          return;
        }
        this.$emit('cell-click', { ThuTuTuan: week.ThuTuTuan, TuanDisplay: week.TuanDisplay, Khoi: k.value, KhoiText: k.text, rows: cell.rows });
      }
    }
	}
</script>

<style scoped>
.uc-stem-grid__table {
  border-collapse: collapse;
  width: 100%;
  table-layout: fixed;
}
.uc-stem-grid__table th,
.uc-stem-grid__table td {
  border: 1px solid #d0d0d0;
  text-align: left;
  vertical-align: top;
  padding: 4px 6px;
}
.uc-stem-grid__table thead th {
  background: #f5f5f5;
  font-weight: 600;
  font-size: 12px;
  text-align: center;
  padding: 6px 4px;
}
.uc-stem-grid__corner {
  width: 110px;
}
.uc-stem-grid__rowhead {
  background: #fafafa;
  font-weight: 600;
  font-size: 12px;
  white-space: nowrap;
  text-align: center;
  vertical-align: middle;
}
.uc-stem-grid__cell {
  min-height: 44px;
  min-width: 140px;
  transition: background-color 0.15s;
}
.uc-stem-grid__cell--filled {
  cursor: pointer;
  background: #fff;
}
.uc-stem-grid__cell--filled:hover {
  background: #f0f7ff;
}
.uc-stem-grid__cell--empty {
  background: #fafafa;
  cursor: pointer;
  text-align: center;
}
.uc-stem-grid__cell--empty:hover {
  background: #e8f5e9;
}
.uc-stem-grid__add-hint {
  color: #c8e6c9;
  font-size: 16px;
  font-weight: 700;
  line-height: 1;
  transition: color 0.15s;
}
.uc-stem-grid__cell--empty:hover .uc-stem-grid__add-hint {
  color: #4caf50;
}
.uc-stem-grid__topic {
  font-weight: 600;
  font-size: 12px;
  line-height: 1.35;
  color: #1565c0;
}
.uc-stem-grid__lop-list {
  margin-top: 3px;
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.uc-stem-grid__lop-item {
  font-size: 11px;
  line-height: 1.4;
}
.uc-stem-grid__lop {
  display: inline-block;
  font-weight: 700;
  color: #2e7d32;
  background: #e8f5e9;
  border-radius: 3px;
  padding: 0 4px;
  margin-right: 4px;
}
.uc-stem-grid__gv {
  color: #666;
}
.uc-stem-grid__empty {
  padding: 24px;
  color: #888;
  text-align: center;
}
</style>