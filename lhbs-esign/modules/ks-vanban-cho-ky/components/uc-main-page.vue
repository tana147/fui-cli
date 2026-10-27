<template>
	<uc-wf-shell title="Ký số LHBS" subtitle="Văn bản chờ ký">
    <div class="ks-page">

      <div class="ks-page-header">
        <div>
          <h1 class="ks-page-title">Văn bản chờ ký</h1>
          <p class="ks-page-subtitle">Danh sách văn bản đang chờ bạn ký</p>
        </div>
        <v-btn variant="text" color="primary" size="small" :loading="isLoading" @click="loadData">
          <v-icon start size="16">mdi-refresh</v-icon>Làm mới
        </v-btn>
      </div>

      <!-- Thanh lọc -->
      <div class="ks-toolbar">
        <v-text-field v-model="keyword" placeholder="Tìm theo tên văn bản..." variant="outlined"
          density="compact" hide-details prepend-inner-icon="mdi-magnify" style="max-width: 320px;" />
        <v-select v-model="filterLoai" :items="loaiItems" item-title="label" item-value="value"
          variant="outlined" density="compact" hide-details class="ks-filter" label="Hình thức ký" />
        <div class="ks-toolbar__spacer"></div>
      </div>

      <div class="ks-table-wrap">
        <div v-if="!isLoading && filtered.length === 0" class="ks-empty">
          <div class="ks-empty__title">Không có văn bản nào chờ ký</div>
          <div>Bạn đã xử lý hết. Tuyệt vời!</div>
        </div>

        <table v-else class="ks-table">
          <thead>
            <tr>
              <th class="ks-table__stt">STT</th>
              <th>Tên văn bản</th>
              <th class="ks-col-center">Bước ký</th>
              <th class="ks-col-nowrap">Hình thức</th>
              <th class="ks-col-nowrap">Thời gian tạo</th>
              <th class="ks-col-nowrap">Người tạo</th>
              <th class="ks-col-center">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, idx) in filtered" :key="row.Nguon + '-' + row.RecordID">
              <td class="ks-table__stt">{{ idx + 1 }}</td>
              <td>
                <span class="ks-table__name" @click="openDoc(row)">{{ row.TieuDe }}</span>
                <span v-if="row.SoNgayCho >= 3" class="ks-status--reject" style="font-size:11px; margin-left:6px;">· Quá hạn</span>
              </td>
              <td class="ks-col-center">{{ row.BuocKy }}</td>
              <td>
                <span class="ks-tag" :class="row.HinhThucKyText === 'Ký nội bộ' ? 'ks-tag--noibo' : 'ks-tag--phaply'">
                  {{ row.HinhThucKyText }}
                </span>
              </td>
              <td class="ks-col-nowrap">{{ formatDate(row.ThoiGianTao) }}</td>
              <td class="ks-col-nowrap">{{ row.NguoiTao }}</td>
              <td class="ks-col-center">
                <span class="ks-sign-link" @click="openDoc(row)">Ký ngay</span>
              </td>
            </tr>
          </tbody>
        </table>

        <div v-if="filtered.length > 0" class="ks-table-foot">
          {{ filtered.length }} văn bản
        </div>
      </div>

    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
      return {
        isLoading: false,
        rows: [],
        keyword: "",
        filterLoai: "ALL",
        loaiItems: [
          { label: "Tất cả hình thức", value: "ALL" },
          { label: "Ký nội bộ", value: "CA_NOIBO" },
          { label: "VNPT SmartCA", value: "SMARTCA" },
          { label: "HĐ điện tử VNPT", value: "VNPT_ECONTRACT" }
        ]
      };
    },
    computed: {
      filtered: function () {
        var kw = (this.keyword || "").toLowerCase().trim();
        var loai = this.filterLoai;
        return this.rows.filter(function (r) {
          var okKw = !kw || String(r.TieuDe || "").toLowerCase().indexOf(kw) >= 0;
          var okLoai = loai === "ALL" || r.HinhThucKy === loai;
          return okKw && okLoai;
        });
      }
    },
    mounted: function () {
      this.loadData();
    },
    methods: {
      loadData: async function () {
        this.isLoading = true;
        try {
          var res = await apiCallAsync("WF_VanBanChoKy", {});
          this.rows = Array.isArray(res) ? res : [];
        } catch (err) {
          this.rows = [];
          if (typeof showToast !== "undefined" && showToast.error) {
            showToast.error("Không tải được danh sách văn bản chờ ký.");
          }
        } finally {
          this.isLoading = false;
        }
      },
      formatDate: function (v) {
        if (!v) return "-";
        var d = new Date(v);
        if (isNaN(d.getTime())) return String(v);
        var p = function (n) { return String(n).padStart(2, "0"); };
        return p(d.getHours()) + ":" + p(d.getMinutes()) + " " + p(d.getDate()) + "/" + p(d.getMonth() + 1) + "/" + d.getFullYear();
      },
      openDoc: function (row) {
        if (row && row.LinkMo) {
          window.location.href = row.LinkMo;
        } else if (typeof showToast !== "undefined" && showToast.info) {
          showToast.info("Chưa có màn ký cho: " + row.TieuDe);
        }
      }
    }
	}
</script>