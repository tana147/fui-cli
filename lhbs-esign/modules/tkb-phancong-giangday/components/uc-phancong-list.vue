<template>
	<div class="uc-pc-list">
    <div v-for="sec in sections" :key="sec.Khoi" class="uc-pc-section">
      <div class="uc-pc-section__header">Khối {{ sec.Khoi }}</div>
      <div class="uc-pc-tabs">
        <button
          v-for="lp in sec.lops"
          :key="lp.MaLop"
          type="button"
          class="uc-pc-tab"
          :class="{ 'uc-pc-tab--active': activeLop[sec.Khoi] === lp.MaLop }"
          @click="activeLop[sec.Khoi] = lp.MaLop">
          {{ lp.MaLop }}
        </button>
      </div>
      <div class="uc-pc-row uc-pc-row--head">
        <div class="uc-pc-col uc-pc-col--mon">Môn</div>
        <div class="uc-pc-col uc-pc-col--gv">Giáo viên</div>
        <div class="uc-pc-col uc-pc-col--to">Tổ</div>
        <div class="uc-pc-col uc-pc-col--tiet">Tiết/tuần</div>
        <div class="uc-pc-col uc-pc-col--hk">HK</div>
        <div class="uc-pc-col uc-pc-col--tuan">Tuần áp dụng</div>
        <div class="uc-pc-col uc-pc-col--act"></div>
      </div>
      <div v-for="item in currentRows(sec)" :key="item.PhanCongID" class="uc-pc-row">
        <div class="uc-pc-col uc-pc-col--mon">
          <span class="uc-pc-link" @click="$emit('view-mon', { MaMon: item.MaMon, TenMon: item.TenMon })">{{ item.TenMon }}</span>
        </div>
        <div class="uc-pc-col uc-pc-col--gv">
          <span class="uc-pc-link" @click="$emit('view-gv', { MaGV: item.MaGV, TenGV: item.TenGV })">{{ item.TenGV }}</span>
        </div>
        <div class="uc-pc-col uc-pc-col--to">{{ item.ToGV }}</div>
        <div class="uc-pc-col uc-pc-col--tiet">{{ item.SoTietChuanTuan }}</div>
        <div class="uc-pc-col uc-pc-col--hk">{{ item.HocKy }}</div>
        <div class="uc-pc-col uc-pc-col--tuan">
          <span v-if="item.TuanApDungDisplay" class="uc-pc-badge">{{ item.TuanApDungDisplay }}</span>
        </div>
        <div class="uc-pc-col uc-pc-col--act">
          <v-btn icon size="small" variant="text" @click="$emit('edit-item', item)">
            <v-icon size="18">mdi-pencil</v-icon>
          </v-btn>
          <v-btn icon size="small" variant="text" color="warning" @click="$emit('delete-item', item)">
            <v-icon size="18">mdi-delete</v-icon>
          </v-btn>
        </div>
      </div>
    </div>
    <div v-if="sections.length === 0" class="uc-pc-empty">Không có dữ liệu</div>
  </div>
</template>

<script>
	export default {
		name: 'uc-phancong-list',
    props: {
      items: { type: Array, default: function () { return []; } }
    },
    emits: ['edit-item', 'delete-item', 'view-mon', 'view-gv'],
    data: function () {
      return {
        activeLop: {}
      };
    },
    computed: {
      sections: function () {
        var byKhoi = {};
        this.items.forEach(function (r) {
          if (!byKhoi[r.Khoi]) byKhoi[r.Khoi] = { Khoi: r.Khoi, rows: [], lopSet: {} };
          byKhoi[r.Khoi].rows.push(r);
          byKhoi[r.Khoi].lopSet[r.MaLop] = true;
        });
        return Object.keys(byKhoi).sort().map(function (k) {
          var sec = byKhoi[k];
          var lops = Object.keys(sec.lopSet).sort().map(function (lp) { return { MaLop: lp }; });
          return { Khoi: sec.Khoi, rows: sec.rows, lops: lops };
        });
      }
    },
    watch: {
      items: {
        immediate: true,
        handler: function () {
          var self = this;
          this.sections.forEach(function (sec) {
            if (!self.activeLop[sec.Khoi] || sec.lops.every(function (lp) { return lp.MaLop !== self.activeLop[sec.Khoi]; })) {
              self.activeLop[sec.Khoi] = sec.lops.length ? sec.lops[0].MaLop : null;
            }
          });
        }
      }
    },
    methods: {
      currentRows: function (sec) {
        var lop = this.activeLop[sec.Khoi];
        return sec.rows.filter(function (r) { return r.MaLop === lop; });
      }
    }
	}
</script>

<style scoped>
.uc-pc-section {
  margin-bottom: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  overflow: hidden;
}
.uc-pc-section__header {
  background: #1565c0;
  color: #fff;
  font-weight: 700;
  font-size: 13px;
  padding: 8px 12px;
}
.uc-pc-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  padding: 8px 10px;
  background: #f5f5f5;
  border-bottom: 1px solid #e0e0e0;
}
.uc-pc-tab {
  border: 1px solid #ccc;
  background: #fff;
  border-radius: 4px;
  padding: 3px 10px;
  font-size: 12px;
  font-weight: 600;
  color: #555;
  cursor: pointer;
}
.uc-pc-tab:hover {
  background: #f0f7ff;
}
.uc-pc-tab--active {
  background: #1565c0;
  border-color: #1565c0;
  color: #fff;
}
.uc-pc-row {
  display: flex;
  align-items: center;
  padding: 6px 12px;
  border-top: 1px solid #f0f0f0;
  font-size: 13px;
}
.uc-pc-row--head {
  font-weight: 600;
  font-size: 11px;
  color: #888;
  border-top: none;
  background: #fafafa;
}
.uc-pc-col--mon { width: 22%; }
.uc-pc-col--gv { width: 20%; }
.uc-pc-link {
  cursor: pointer;
  color: #1565c0;
}
.uc-pc-link:hover {
  text-decoration: underline;
}
.uc-pc-col--to { width: 14%; color: #777; font-size: 12px; }
.uc-pc-col--tiet { width: 8%; text-align: center; }
.uc-pc-col--hk { width: 6%; text-align: center; }
.uc-pc-col--tuan { width: 18%; }
.uc-pc-col--act { width: 12%; text-align: right; margin-left: auto; }
.uc-pc-badge {
  display: inline-block;
  font-size: 11px;
  font-weight: 600;
  color: #e65100;
  background: #fff3e0;
  border-radius: 3px;
  padding: 1px 6px;
}
.uc-pc-empty {
  padding: 32px;
  text-align: center;
  color: #888;
}
</style>