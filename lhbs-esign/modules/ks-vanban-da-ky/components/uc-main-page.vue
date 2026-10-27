<template>
	<uc-wf-shell title="Ký số LHBS" subtitle="Văn bản đã ký">
    <div class="ks-page">

      <div class="ks-page-header">
        <div>
          <h1 class="ks-page-title">Văn bản đã ký</h1>
          <p class="ks-page-subtitle">Các văn bản bạn đã hoàn tất ký</p>
        </div>
        <v-btn variant="text" color="primary" size="small" :loading="isLoading" @click="loadData">
          <v-icon start size="16">mdi-refresh</v-icon>Làm mới
        </v-btn>
      </div>

      <div class="ks-toolbar">
        <v-text-field v-model="keyword" placeholder="Tìm theo tên văn bản..." variant="outlined"
          density="compact" hide-details prepend-inner-icon="mdi-magnify" style="max-width: 320px;" />
        <div class="ks-toolbar__spacer"></div>
      </div>

      <div class="ks-table-wrap">
        <div v-if="!isLoading && filtered.length === 0" class="ks-empty">
          <div class="ks-empty__title">Chưa có văn bản nào đã ký</div>
          <div>Các văn bản bạn ký sẽ xuất hiện ở đây.</div>
        </div>

        <table v-else class="ks-table">
          <thead>
            <tr>
              <th class="ks-table__stt">STT</th>
              <th>Tên văn bản</th>
              <th class="ks-col-nowrap">Thời gian ký</th>
              <th class="ks-col-nowrap">Thời gian hoàn thành</th>
              <th class="ks-col-nowrap">Người tạo</th>
              <th class="ks-col-nowrap">Trạng thái</th>
              <th class="ks-col-center">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, idx) in filtered" :key="row.Nguon + '-' + row.RecordID">
              <td class="ks-table__stt">{{ idx + 1 }}</td>
              <td><span class="ks-table__name" @click="openDoc(row)">{{ row.TieuDe }}</span></td>
              <td class="ks-col-nowrap">{{ formatDate(row.ThoiGianKy) }}</td>
              <td class="ks-col-nowrap">{{ row.ThoiGianHoanThanh ? formatDate(row.ThoiGianHoanThanh) : '—' }}</td>
              <td class="ks-col-nowrap">{{ row.NguoiTao }}</td>
              <td class="ks-col-nowrap">
                <span class="ks-status" :class="statusClass(row.TrangThaiCode)">{{ row.TrangThaiText }}</span>
              </td>
              <td class="ks-col-center">
                <div class="ks-actions" style="justify-content:center;">
                  <v-icon class="ks-action-ico ks-action-ico--download" size="17" @click="tai(row)" title="Tải">mdi-download</v-icon>
                  <v-icon class="ks-action-ico ks-action-ico--share" size="17" @click="chiaSe(row)" title="Chia sẻ">mdi-share-variant-outline</v-icon>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <div v-if="filtered.length > 0" class="ks-table-foot">{{ filtered.length }} văn bản</div>
      </div>

    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
      return { isLoading: false, rows: [], keyword: "" };
    },
    computed: {
      filtered: function () {
        var kw = (this.keyword || "").toLowerCase().trim();
        return this.rows.filter(function (r) {
          return !kw || String(r.TieuDe || "").toLowerCase().indexOf(kw) >= 0;
        });
      }
    },
    mounted: function () { this.loadData(); },
    methods: {
      loadData: async function () {
        this.isLoading = true;
        try {
          var res = await apiCallAsync("WF_VanBanDaKy", {});
          this.rows = Array.isArray(res) ? res : [];
        } catch (err) {
          this.rows = [];
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không tải được danh sách văn bản đã ký.");
        } finally { this.isLoading = false; }
      },
      statusClass: function (code) {
        if (code === "COMPLETED" || code === "DA_KY") return "ks-status--done";
        if (code === "REJECTED" || code === "CANCELLED" || code === "TU_CHOI") return "ks-status--reject";
        return "ks-status--pending";
      },
      formatDate: function (v) {
        if (!v) return "—";
        var d = new Date(v);
        if (isNaN(d.getTime())) return String(v);
        var p = function (n) { return String(n).padStart(2, "0"); };
        return p(d.getHours()) + ":" + p(d.getMinutes()) + " " + p(d.getDate()) + "/" + p(d.getMonth() + 1) + "/" + d.getFullYear();
      },
      openDoc: function (row) {
        if (row && row.LinkMo) window.location.href = row.LinkMo;
      },
      tai: function (row) { if (typeof showToast !== "undefined" && showToast.info) showToast.info("Tải: " + row.TieuDe); },
      chiaSe: function (row) { if (typeof showToast !== "undefined" && showToast.info) showToast.info("Chia sẻ: " + row.TieuDe); }
    }
	}
</script>