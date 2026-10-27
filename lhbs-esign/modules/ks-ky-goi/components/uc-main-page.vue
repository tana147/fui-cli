<template>
	<uc-wf-shell title="Ký số LHBS" subtitle="Ký văn bản">
    <div class="ks-page">

      <div class="ks-page-header">
        <div>
          <h1 class="ks-page-title">{{ detail.TieuDe || 'Ký văn bản' }}</h1>
          <p class="ks-page-subtitle">
            <span>{{ detail.HinhThucKyText || '—' }}</span>
            <span v-if="detail.TrangThaiText"> · {{ detail.TrangThaiText }}</span>
          </p>
        </div>
        <v-btn variant="text" color="primary" size="small" @click="goBack">
          <v-icon start size="16">mdi-arrow-left</v-icon>Quay lại
        </v-btn>
      </div>

      <div v-if="isLoading" class="ks-empty"><div>Đang tải...</div></div>

      <div v-else-if="!detail.GoiKyID" class="ks-empty">
        <div class="ks-empty__title">Không tìm thấy văn bản</div>
        <div>Gói ký không tồn tại hoặc đã bị xoá.</div>
      </div>

      <div v-else class="ks-viewer">
        <!-- Cột trái: tài liệu -->
        <div class="ks-viewer__doc">
          <div class="ks-viewer__doc-head">
            <span style="font-size:13px; font-weight:500;">{{ detail.TenFileGoc || 'Tài liệu' }}</span>
            <v-btn v-if="detail.FileUrl" variant="text" color="primary" size="x-small" @click="moTaiLieu">
              <v-icon start size="15">mdi-open-in-new</v-icon>Mở tài liệu
            </v-btn>
          </div>
          <div class="ks-viewer__doc-body ks-vd-doc-body">
            <uc-request-sign-canvas :file-url="detail.FileUrl || ''" :sign-boxes="boxes"
              :active-page="1" :selected-box-id="0"></uc-request-sign-canvas>
          </div>
        </div>

        <!-- Cột phải: bảng ký -->
        <div class="ks-viewer__panel">

          <!-- Lượt ký của tôi -->
          <div v-if="detail.LaLuotCuaToi" class="ks-panel-card ks-my-turn">
            <div class="ks-panel-card__title">
              <v-icon size="16" color="primary">mdi-file-sign</v-icon>Lượt ký của tôi
            </div>
            <div class="ks-panel-card__body">
              <div class="ks-my-turn__label">Bạn được yêu cầu ký văn bản này bằng <b>{{ detail.HinhThucKyText }}</b>.</div>
              <div class="ks-my-turn__actions">
                <button class="ks-btn ks-btn--danger" :disabled="busy" @click="tuChoi">
                  <v-icon size="16">mdi-close</v-icon>Từ chối
                </button>
                <button class="ks-btn ks-btn--primary" :disabled="busy" @click="xacNhanKy">
                  <v-icon size="16">mdi-check</v-icon>Xác nhận ký
                </button>
              </div>
            </div>
          </div>

          <!-- Danh sách người ký -->
          <div class="ks-panel-card">
            <div class="ks-panel-card__title">
              <v-icon size="16" color="#64748b">mdi-account-multiple-outline</v-icon>
              Người ký ({{ signers.length }})
            </div>
            <div class="ks-panel-card__body" style="padding-top: 2px; padding-bottom: 4px;">
              <div v-for="s in signers" :key="s.NguoiKyID" class="ks-signer-row">
                <div class="ks-signer-row__idx"
                  :class="s.TrangThai === 'DA_KY' ? 'ks-signer-row__idx--done' : (s.LaToi ? 'ks-signer-row__idx--me' : '')">
                  <v-icon v-if="s.TrangThai === 'DA_KY'" size="14">mdi-check</v-icon>
                  <span v-else>{{ s.ThuTuKy }}</span>
                </div>
                <div class="ks-signer-row__body">
                  <div class="ks-signer-row__name">{{ s.TenNguoiKy }}<span v-if="s.LaToi" style="color:var(--ks-primary); font-weight:400;"> · Bạn</span></div>
                  <div class="ks-signer-row__meta">{{ s.PhongBan }}</div>
                </div>
                <span class="ks-status" :class="signerStatusClass(s.TrangThai)" style="font-size:12px;">{{ s.TrangThaiText }}</span>
              </div>
            </div>
          </div>

          <!-- Lịch sử -->
          <div class="ks-panel-card">
            <div class="ks-panel-card__title">
              <v-icon size="16" color="#64748b">mdi-history</v-icon>Lịch sử
            </div>
            <div class="ks-panel-card__body">
              <div class="ks-timeline">
                <div class="ks-tl-item">
                  <div class="ks-tl-dot"><v-icon size="14">mdi-file-plus-outline</v-icon></div>
                  <div class="ks-tl-body">
                    <div class="ks-tl-title">Khởi tạo văn bản</div>
                    <div class="ks-tl-time">{{ formatDate(detail.CreateTime) }} · {{ detail.CreateUser }}</div>
                  </div>
                </div>
                <div v-for="s in daKySigners" :key="'h'+s.NguoiKyID" class="ks-tl-item">
                  <div class="ks-tl-dot" style="background:#dcfce7; color:var(--ks-success);"><v-icon size="14">mdi-check</v-icon></div>
                  <div class="ks-tl-body">
                    <div class="ks-tl-title">{{ s.TenNguoiKy }} đã ký</div>
                    <div class="ks-tl-time">{{ formatDate(s.NgayKy) }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>

    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
      return { isLoading: false, busy: false, goiKyId: 0, detail: {}, signers: [], boxes: [] };
    },
    computed: {
      daKySigners: function () {
        return this.signers.filter(function (s) { return s.TrangThai === 'DA_KY'; });
      }
    },
    mounted: function () {
      this.goiKyId = this.parseId();
      this.loadDetail();
    },
    methods: {
      parseId: function () {
        var p = new URLSearchParams(window.location.search || "");
        var v = parseInt(p.get("id") || "0", 10);
        return isNaN(v) ? 0 : v;
      },
      loadDetail: async function () {
        if (!this.goiKyId) return;
        this.isLoading = true;
        try {
          var res = await apiCallAsync("WF_GoiKy_GetDetail/" + this.goiKyId, {});
          if (Array.isArray(res) && Array.isArray(res[0])) {
            this.detail = res[0][0] || {};
            this.signers = Array.isArray(res[1]) ? res[1] : [];
            this.boxes = Array.isArray(res[2]) ? res[2] : [];
          } else {
            this.detail = {}; this.signers = []; this.boxes = [];
          }
        } catch (err) {
          this.detail = {}; this.signers = [];
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không tải được chi tiết văn bản.");
        } finally { this.isLoading = false; }
      },
      xacNhanKy: async function () {
        this.busy = true;
        try {
          await apiCallAsync("WF_GoiKy_XacNhanKy", { GoiKyID: this.goiKyId });
          if (typeof showToast !== "undefined" && showToast.success) showToast.success("Xác nhận ký thành công.");
          await this.loadDetail();
        } catch (err) {
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Ký không thành công.");
        } finally { this.busy = false; }
      },
      tuChoi: async function () {
        this.busy = true;
        try {
          await apiCallAsync("WF_GoiKy_TuChoi", { GoiKyID: this.goiKyId, LyDo: "" });
          if (typeof showToast !== "undefined" && showToast.info) showToast.info("Đã từ chối ký.");
          await this.loadDetail();
        } catch (err) {
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Thao tác không thành công.");
        } finally { this.busy = false; }
      },
      signerStatusClass: function (tt) {
        if (tt === 'DA_KY') return 'ks-status--done';
        if (tt === 'TU_CHOI') return 'ks-status--reject';
        return 'ks-status--pending';
      },
      formatDate: function (v) {
        if (!v) return "—";
        var d = new Date(v);
        if (isNaN(d.getTime())) return String(v);
        var p = function (n) { return String(n).padStart(2, "0"); };
        return p(d.getHours()) + ":" + p(d.getMinutes()) + " " + p(d.getDate()) + "/" + p(d.getMonth() + 1) + "/" + d.getFullYear();
      },
      moTaiLieu: function () {
        if (this.detail.FileUrl) window.open(this.detail.FileUrl, "_blank");
      },
      goBack: function () { window.location.href = "/ks-vanban-cho-ky"; }
    }
	}
</script>