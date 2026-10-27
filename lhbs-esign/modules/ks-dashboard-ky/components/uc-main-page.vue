<template>
	<uc-wf-shell title="Ký số LHBS" subtitle="Bảng ký của tôi">
    <div class="ks-page">

      <div class="ks-page-header">
        <div>
          <h1 class="ks-page-title">Bảng ký của tôi</h1>
          <p class="ks-page-subtitle">Văn bản đang chờ bạn ký và lịch sử ký gần đây</p>
        </div>
        <v-btn variant="text" color="primary" size="small" :loading="isLoading" @click="loadData">
          <v-icon start size="16">mdi-refresh</v-icon>Làm mới
        </v-btn>
      </div>

      <div class="ks-stat-grid">
        <div class="ks-stat ks-stat--accent">
          <span class="ks-stat__label">Chờ ký hôm nay</span>
          <span class="ks-stat__value">{{ stats.ChoKyHomNay || 0 }}</span>
        </div>
        <div class="ks-stat">
          <span class="ks-stat__label">Đã ký · 7 ngày</span>
          <span class="ks-stat__value">{{ stats.DaKyTuanNay || 0 }}</span>
        </div>
        <div class="ks-stat">
          <span class="ks-stat__label">Ký nội bộ</span>
          <span class="ks-stat__value">{{ stats.KyNoiBo || 0 }}</span>
        </div>
        <div class="ks-stat">
          <span class="ks-stat__label">Ký pháp lý</span>
          <span class="ks-stat__value">{{ stats.KyPhapLy || 0 }}</span>
        </div>
      </div>

      <div class="ks-card">
        <div class="ks-card__head">
          <h3 class="ks-card__title">Văn bản đang chờ ký</h3>
          <span class="ks-card__count">{{ docs.length }} văn bản</span>
        </div>

        <div v-if="!isLoading && docs.length === 0" class="ks-empty">
          <div class="ks-empty__title">Không có văn bản nào chờ ký</div>
          <div>Bạn đã xử lý hết. Tuyệt vời!</div>
        </div>

        <div v-for="doc in docs" :key="doc.RecordID" class="ks-doc-row" @click="openDoc(doc)">
          <div class="ks-doc-row__main">
            <div class="ks-doc-row__title">{{ doc.TieuDe }}</div>
            <div class="ks-doc-row__meta">
              <span>{{ doc.LoaiHoSo }}</span>
              <span class="ks-doc-row__dot">·</span>
              <span>Chờ {{ doc.SoNgayCho }} ngày</span>
              <span v-if="doc.SoNgayCho >= 3" class="ks-doc-row__late">· Quá hạn</span>
            </div>
          </div>
          <div class="ks-doc-row__right">
            <span class="ks-tag" :class="doc.NhomKy === 'NOIBO' ? 'ks-tag--noibo' : 'ks-tag--phaply'">
              {{ doc.HinhThucKyText }}
            </span>
            <span class="ks-sign-link" @click.stop="signDoc(doc)">Ký ngay</span>
          </div>
        </div>
      </div>

    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
      return { isLoading: false, stats: {}, docs: [] };
    },
    mounted: function () {
      this.loadData();
    },
    methods: {
      loadData: async function () {
        this.isLoading = true;
        try {
          var res = await apiCallAsync("WF_DashboardKy", {});
          var stat = null, list = [];
          if (Array.isArray(res) && Array.isArray(res[0])) {
            stat = res[0][0] || null;
            list = Array.isArray(res[1]) ? res[1] : [];
          } else if (Array.isArray(res) && res[0]) {
            stat = res[0];
          }
          this.stats = stat || {};
          this.docs = list;
        } catch (err) {
          this.stats = {};
          this.docs = [];
          if (typeof showToast !== "undefined" && showToast.error) {
            showToast.error("Không tải được dữ liệu bảng ký.");
          }
        } finally {
          this.isLoading = false;
        }
      },
      openDoc: function (doc) {
        if (doc && doc.LinkMo) window.location.href = doc.LinkMo;
      },
      signDoc: function (doc) {
        if (doc && doc.LinkMo) window.location.href = doc.LinkMo;
      }
    }
	}
</script>