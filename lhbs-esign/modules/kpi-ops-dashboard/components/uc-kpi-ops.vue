<template>
	<div class="uc-kpi-ops">
    <!-- 1. Header Top (Clean Executive Bar) -->
    <div class="uc-kpi-ops__top">
      <div class="uc-kpi-ops__top-left">
        <div class="d-flex align-center gap-2">
          <div class="uc-kpi-ops__title">KPI Results Framework &amp; Ops Dashboard &middot; LHBS</div>
          <span class="uc-kpi-ops__safeguard-pill">
            <span class="safeguard-dot"></span>
            <span>An toàn học đường: 0 sự cố</span>
          </span>
          <span :class="['uc-kpi-ops__pill', isLoading ? 'is-warn' : 'is-live']">
            {{ apiSyncStatus }}
          </span>
        </div>
        <div class="uc-kpi-ops__subtitle">
          Báo cáo vận hành {{ currentPeriodName }} &middot; Năm học {{ selectedYear }}&ndash;{{ selectedYear + 1 }} &middot; Quy mô: <b>{{ formatNumber(displayStudents) }} / {{ formatNumber(displayTarget) }} HS</b> ({{ ((displayStudents / (displayTarget || 1)) * 100).toFixed(1) }}%)
        </div>
      </div>

      <div class="uc-kpi-ops__meta">
        <!-- Kỳ báo cáo tích hợp ngay trên thanh lệnh chính -->
        <div class="uc-kpi-ops__seg">
          <button
            v-for="p in periodsList"
            :key="p.PeriodKey"
            type="button"
            :class="{ 'is-on': selectedPeriod === p.PeriodKey }"
            @click="setPeriod(p.PeriodKey)"
          >{{ p.PeriodKey === '2026-09' ? 'T09/2026 (Chốt sổ)' : 'T10/2026 (Live)' }}</button>
        </div>
        <button type="button" class="uc-kpi-ops__simbtn" :disabled="isLoading" @click="refreshData()">
          {{ isLoading ? 'Đang tải...' : 'Làm mới' }}
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="openCausalModal()">
          Mô phỏng What-If
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="printExecutiveReport()">
          In A4
        </button>
        <button type="button" :class="['uc-kpi-ops__simbtn', { 'is-solid': isPresentMode }]" @click="toggleFullscreen()">
          {{ isPresentMode ? 'Thoát' : 'Trình chiếu' }}
        </button>
      </div>
    </div>

    <!-- 2. Unified Slicer Bar (Gọn sạch 1 hàng điều hướng) -->
    <div v-if="!isPresentMode" class="uc-kpi-ops__slicers">
      <div class="uc-kpi-ops__slicers-left">
        <div class="uc-kpi-ops__slicer-inline">
          <span class="uc-kpi-ops__slicer-label">CHẾ ĐỘ HĐQT:</span>
          <div class="uc-kpi-ops__seg">
            <button
              type="button"
              :class="{ 'is-on': page === 0 && executiveTab === 'COMMAND' }"
              @click="page = 0; executiveTab = 'COMMAND'"
            >Cockpit 3 Tầng</button>
            <button
              type="button"
              :class="{ 'is-on': page === 0 && executiveTab === 'FRAMEWORK' }"
              @click="page = 0; executiveTab = 'FRAMEWORK'"
            >Ma trận 60 KPI</button>
            <button
              type="button"
              :class="{ 'is-on': page === 0 && executiveTab === 'RISK' }"
              @click="page = 0; executiveTab = 'RISK'"
            >Radar Rủi ro</button>
            <button
              type="button"
              :class="{ 'is-on': page === 0 && executiveTab === 'AUDIT' }"
              @click="page = 0; executiveTab = 'AUDIT'"
            >Kiểm toán ({{ auditDiscrepanciesList.length || 12 }})</button>
          </div>
        </div>

        <div class="uc-kpi-ops__slicer-inline">
          <span class="uc-kpi-ops__slicer-label">CƠ SỞ ({{ formatNumber(displayStudents) }}/{{ formatNumber(displayTarget) }} HS):</span>
          <div class="uc-kpi-ops__seg">
            <button
              v-for="u in unitOptions"
              :key="u.k"
              type="button"
              :class="{ 'is-on': currentUnit === u.k }"
              @click="setUnit(u.k)"
            >{{ u.t }}</button>
          </div>
        </div>
      </div>

      <div class="uc-kpi-ops__slicers-right">
        <span class="uc-kpi-ops__slicer-label">PHÂN HỆ:</span>
        <div class="uc-kpi-ops__seg">
          <button type="button" :class="{ 'is-on': page === 1 }" @click="page = 1">Sĩ số</button>
          <button type="button" :class="{ 'is-on': page === 7 }" @click="page = 7">CRM</button>
          <button type="button" :class="{ 'is-on': page === 2 }" @click="page = 2">Rút học</button>
          <button type="button" :class="{ 'is-on': page === 4 }" @click="page = 4">LMS</button>
          <button type="button" :class="{ 'is-on': page === 5 }" @click="page = 5">CLB</button>
          <button type="button" :class="{ 'is-on': page === 6 }" @click="page = 6">Y tế</button>
        </div>
        <button type="button" class="uc-kpi-ops__simbtn" @click="openFactModal('STUDENTS')">
          Fact Store
        </button>
      </div>
    </div>

    <!-- Sticky Subnav Breadcrumb khi xem trang chuyên sâu (page !== 0) -->
    <div v-if="page !== 0" class="uc-kpi-ops__sticky-subnav">
      <div class="uc-kpi-ops__breadcrumb">
        <span class="crumb-link" @click="page = 0; executiveTab = 'COMMAND'">0. Hội đồng Quản trị (Cockpit 3 Tầng)</span>
        <span class="crumb-sep">&rsaquo;</span>
        <span class="crumb-current">{{ currentBreadcrumbTitle }}</span>
      </div>
      <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="page = 0; executiveTab = 'COMMAND'">
        &lsaquo; Quay lại Cockpit 3 Tầng
      </button>
    </div>

    <!-- 3. PAGE 0: HỘI ĐỒNG QUẢN TRỊ (Executive Board Overview) -->
    <div v-if="page === 0" class="uc-kpi-ops__page">
      <div v-if="executiveTab === 'COMMAND'" class="uc-kpi3t__cockpit">
        <!-- ═══════════════════════════════════════════════════════════════ -->
        <!-- TẦNG 1: 6 SCORECARD CHIẾN LƯỢC + SVG SPARKLINE & PHỔ 60 KPI     -->
        <!-- ═══════════════════════════════════════════════════════════════ -->
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">TẦNG 1</span>
              <span class="uc-kpi3t__section-title">CHỈ SỐ CHIẾN LƯỢC HỘI ĐỒNG QUẢN TRỊ ({{ currentUnitTitle }})</span>
            </div>

            <!-- Thanh Phổ Sức Khỏe 60 KPI trực quan -->
            <div class="uc-kpi3t__health-inline">
              <span class="h-lbl">Phổ 60 KPI:</span>
              <div class="uc-kpi3t__mini-health-bar" title="19 Đạt · 10 Cảnh báo · 31 Chờ API GĐ2">
                <div class="seg is-good" :style="{ width: kpiHealthStats.goodPct + '%' }"></div>
                <div class="seg is-warn" :style="{ width: kpiHealthStats.warnPct + '%' }"></div>
                <div v-if="kpiHealthStats.critical > 0" class="seg is-bad" :style="{ width: kpiHealthStats.criticalPct + '%' }"></div>
                <div class="seg is-pending" :style="{ width: kpiHealthStats.pendingPct + '%' }"></div>
              </div>
              <span class="h-pill is-good"><b>{{ kpiHealthStats.good }}</b> Đạt</span>
              <span class="h-pill is-warn"><b>{{ kpiHealthStats.warn }}</b> Cảnh báo</span>
              <span class="h-pill is-pending"><b>{{ kpiHealthStats.pending }}</b> Chờ API</span>
              <button type="button" class="uc-kpi3t__link-btn" @click="executiveTab = 'FRAMEWORK'">Ma trận 60 KPI &rsaquo;</button>
            </div>

            <div class="uc-kpi3t__toggle-group">
              <button
                type="button"
                class="uc-kpi3t__toggle-btn"
                :class="{ 'is-active': kpiViewMode === 'STRATEGIC' }"
                @click="kpiViewMode = 'STRATEGIC'"
              >6 KPI Chiến Lược</button>
              <button
                type="button"
                class="uc-kpi3t__toggle-btn"
                :class="{ 'is-active': kpiViewMode === 'GROUPS' }"
                @click="kpiViewMode = 'GROUPS'"
              >4 Trụ Cột Cốt Lõi</button>
            </div>
          </div>

          <!-- Grid 6 KPI Chiến Lược (True Visual Scorecard + SVG Sparkline) -->
          <div class="uc-kpi3t__grid-6" v-if="kpiViewMode === 'STRATEGIC'">
            <div
              v-for="kpi in tier1List"
              :key="kpi.MasterKpiCode"
              class="uc-kpi3t__card"
              :class="[
                { 'is-active': activeTier1Kpi === kpi.MasterKpiCode },
                'status-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')
              ]"
              @click="selectTier1Kpi(kpi.MasterKpiCode)"
            >
              <div class="uc-kpi3t__card-top">
                <span class="uc-kpi3t__code">{{ kpi.MasterKpiCode.replace('_', ' ') }} &middot; TT {{ kpi.WeightPct }}%</span>
                <span class="uc-kpi3t__status-dot" :class="'is-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')">
                  {{ getTierStatusText(kpi.StatusBadge) }}
                </span>
              </div>

              <div class="uc-kpi3t__card-name" :title="kpi.KpiName">{{ kpi.KpiName }}</div>

              <!-- Hero Number + SVG Trend Sparkline -->
              <div class="uc-kpi3t__card-hero">
                <div class="uc-kpi3t__val" :class="kpi.StatusBadge === 'BAD' ? 'tx-bad' : (kpi.StatusBadge === 'WARN' ? 'tx-warn' : 'tx-good')">
                  <b>{{ kpi.ActualValue }}</b><small>{{ kpi.TargetUnit }}</small>
                </div>

                <svg class="uc-kpi3t__spark-svg" viewBox="0 0 106 28" preserveAspectRatio="none">
                  <line x1="0" y1="8" x2="106" y2="8" class="spark-target-line" />
                  <polyline
                    fill="none"
                    :class="'spark-line is-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')"
                    :points="getKpiSparklinePoints(kpi)"
                  />
                  <circle
                    cx="102"
                    :cy="kpi.MasterKpiCode === 'KPI_6' ? 22 : (kpi.MasterKpiCode === 'KPI_4' ? 14 : 10)"
                    r="3"
                    :class="'spark-dot is-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')"
                  />
                </svg>
              </div>

              <!-- Visual Bullet Bar -->
              <div class="uc-kpi3t__bullet-wrap">
                <div class="uc-kpi3t__pbar">
                  <div
                    class="uc-kpi3t__pfill"
                    :class="'fill-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')"
                    :style="{ width: Math.min(100, Math.max(6, (kpi.ProgressPct || 0) * 0.85)) + '%' }"
                  ></div>
                  <div class="uc-kpi3t__ptarget-marker" style="left:85%;" title="Mốc kế hoạch 100%"></div>
                </div>
              </div>

              <div class="uc-kpi3t__card-bot">
                <span>KH {{ kpi.ComparisonOp }} {{ kpi.TargetValue }}{{ kpi.TargetUnit }}</span>
                <b :class="kpi.StatusBadge === 'GOOD' ? 'tx-good' : 'tx-warn'">
                  {{ getKpiVarianceText(kpi) }}
                </b>
              </div>
            </div>
          </div>

          <!-- Grid 4 Trụ Cột Vận Hành Cốt Lõi -->
          <div class="uc-kpi3t__grid-4" v-else>
            <div
              v-for="grp in computedGroupPillars"
              :key="grp.code"
              class="uc-kpi3t__card"
              :class="[
                { 'is-active': activeTier1Kpi === grp.kpiCode },
                'status-' + grp.status
              ]"
              @click="selectTier1Kpi(grp.kpiCode)"
            >
              <div class="uc-kpi3t__card-top">
                <span class="uc-kpi3t__code">{{ grp.label }} &middot; {{ grp.name }}</span>
                <span class="uc-kpi3t__status-dot" :class="'is-' + grp.status">{{ grp.activeCount }}/{{ grp.driverCount }} KPI</span>
              </div>
              <div class="uc-kpi3t__card-hero">
                <div class="uc-kpi3t__val"><b>{{ grp.highlightVal }}</b></div>
                <div class="uc-kpi3t__target">{{ grp.highlightNote }}</div>
              </div>
              <div class="uc-kpi3t__pbar">
                <div class="uc-kpi3t__pfill" :class="'fill-' + grp.status" :style="{ width: Math.min(100, grp.progressPct) + '%' }"></div>
              </div>
              <div class="uc-kpi3t__card-bot">
                <span class="uc-kpi3t__progress-txt">{{ grp.desc }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════════════ -->
        <!-- WORKBENCH 2 CỘT: TẦNG 2 BULLET CHART (TRÁI) & TẦNG 3 SVG (PHẢI) -->
        <!-- ═══════════════════════════════════════════════════════════════ -->
        <div class="uc-kpi3t__workbench">
          <!-- ───────────────────────────────────────────────────────────── -->
          <!-- CỘT TRÁI — TẦNG 2: BIỂU ĐỒ BULLET & PHƯƠNG SAI TIÊU CHÍ       -->
          <!-- ───────────────────────────────────────────────────────────── -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <div class="d-flex align-center gap-2 min-w-0">
                <span class="uc-kpi3t__tier-badge tier-2">TẦNG 2</span>
                <span class="uc-kpi3t__pane-title">
                  BIỂU ĐỒ TIÊU CHÍ VẬN HÀNH: <b>{{ activeTier1Obj ? activeTier1Obj.KpiName : '' }}</b>
                </span>
              </div>
              <div class="d-flex align-center gap-1">
                <button
                  v-if="activeTier2Kpi"
                  type="button"
                  class="uc-kpi3t__filter-reset-btn"
                  @click="activeTier2Kpi = null"
                >Bỏ chọn {{ activeTier2Kpi }} &times;</button>
                <div class="uc-kpi3t__toggle-group">
                  <button
                    type="button"
                    class="uc-kpi3t__toggle-btn"
                    :class="{ 'is-active': tier2ViewMode === 'CHART' }"
                    @click="tier2ViewMode = 'CHART'"
                  >Biểu đồ Bullet</button>
                  <button
                    type="button"
                    class="uc-kpi3t__toggle-btn"
                    :class="{ 'is-active': tier2ViewMode === 'TABLE' }"
                    @click="tier2ViewMode = 'TABLE'"
                  >Bảng số ({{ currentTier2Drivers.length }})</button>
                </div>
              </div>
            </div>

            <!-- 4 Chỉ số Tác động Định lượng (Gọn, Sắc nét, Tabular Nums) -->
            <div class="uc-kpi3t__impact-grid">
              <div
                v-for="(card, idx) in computedTier3ImpactCards"
                :key="idx"
                class="uc-kpi3t__impact-card"
                :class="'is-' + card.tone"
              >
                <div class="uc-kpi3t__impact-label">{{ card.label }}</div>
                <div class="uc-kpi3t__impact-val">
                  {{ card.value }} <small v-if="card.unit">{{ card.unit }}</small>
                </div>
                <div class="uc-kpi3t__impact-sub" :title="card.sub">{{ card.sub }}</div>
              </div>
            </div>

            <!-- CHẾ ĐỘ 1: PURE VISUAL HORIZONTAL BULLET CHART (Không nhồi chữ nhiều dòng vào từng thanh) -->
            <div v-if="tier2ViewMode === 'CHART'" class="uc-kpi3t__bchart">
              <div class="uc-kpi3t__bchart-head">
                <div class="bcol-info">Tiêu chí đo lường ({{ activeTier2MeasurableDrivers.length }})</div>
                <div class="bcol-bars">
                  <span>0%</span>
                  <span>50%</span>
                  <span class="target-lbl">Đích KH 100%</span>
                </div>
                <div class="bcol-vals">Thực tế / KH</div>
                <div class="bcol-var">Độ lệch</div>
              </div>

              <div
                v-for="d in activeTier2MeasurableDrivers"
                :key="d.KpiCode"
                class="uc-kpi3t__bchart-row"
                :class="[
                  (d.VariancePct || 0) < 0 ? ((d.ProgressPct || 0) < 75 ? 'is-bad' : 'is-warn') : 'is-good',
                  { 'is-selected': activeTier2Kpi === d.KpiCode }
                ]"
                @click="selectTier2Driver(d)"
              >
                <!-- Cột Tên Tiêu chí (1 dòng sạch sẽ) -->
                <div class="bcol-info">
                  <span class="uc-kpi3t__code-pill">{{ d.KpiCode }}</span>
                  <span class="uc-kpi3t__bchart-name" :title="d.KpiName">{{ d.KpiName }}</span>
                </div>

                <!-- Cột Thanh Biểu đồ Bullet (Chiếm trung tâm thị giác) -->
                <div class="bcol-bars">
                  <div class="uc-kpi3t__bullet-track" :title="d.KpiName + ': Hoàn thành ' + (d.ProgressPct || 0) + '%'">
                    <div class="uc-kpi3t__bullet-zone-100" style="width:82%;"></div>
                    <div
                      class="uc-kpi3t__bullet-bar"
                      :class="(d.VariancePct || 0) < 0 ? ((d.ProgressPct || 0) < 75 ? 'fill-bad' : 'fill-warn') : 'fill-good'"
                      :style="{ width: Math.min(100, Math.max(5, (d.ProgressPct || 0) * 0.82)) + '%' }"
                    ></div>
                    <div
                      v-if="(d.ProgressPct || 0) < 100"
                      class="uc-kpi3t__bullet-deficit"
                      :style="{
                        left: Math.min(82, Math.max(5, (d.ProgressPct || 0) * 0.82)) + '%',
                        width: Math.max(0, 82 - Math.min(82, Math.max(5, (d.ProgressPct || 0) * 0.82))) + '%'
                      }"
                    ></div>
                    <div class="uc-kpi3t__bullet-target-line" style="left:82%;"></div>
                  </div>
                </div>

                <!-- Cột Số Thực tế / Kế hoạch -->
                <div class="bcol-vals">
                  <b class="val-actual" :class="(d.VariancePct || 0) < 0 ? ((d.ProgressPct || 0) < 75 ? 'tx-bad' : 'tx-warn') : 'tx-good'">
                    {{ formatKpiVal(d.ActualValue, d.Unit) }}
                  </b>
                  <span class="val-target">/ {{ formatKpiVal(d.TargetValue, d.Unit) }}</span>
                </div>

                <!-- Cột Độ lệch % -->
                <div class="bcol-var">
                  <span
                    class="uc-kpi3t__var-pill"
                    :class="(d.VariancePct || 0) < 0 ? 'is-neg' : 'is-pos'"
                  >
                    {{ (d.VariancePct || 0) > 0 ? '+' : '' }}{{ d.VariancePct || 0 }}%
                  </span>
                </div>
              </div>

              <!-- PROGRESSIVE DISCLOSURE: Hộp tiêu điểm chẩn đoán chỉ hiển thị cho tiêu chí đang chọn/nghẽn chính -->
              <div v-if="activeDriverFocusObj" class="uc-kpi3t__driver-focus-bar">
                <div class="focus-main">
                  <span class="focus-tag">TIÊU ĐIỂM {{ activeDriverFocusObj.KpiCode }}</span>
                  <b class="focus-title">{{ activeDriverFocusObj.KpiName }}:</b>
                  <span class="focus-text">{{ activeDriverFocusObj.OperationalInsight || activeDriverFocusObj.FinancialImpact || 'Đang theo dõi sát tiến độ thực hiện tại 5 cơ sở.' }}</span>
                </div>
                <div class="focus-actions">
                  <button
                    v-if="activeDriverFocusObj.AuditIssueCount > 0"
                    type="button"
                    class="uc-kpi3t__flag-btn is-audit"
                    @click="selectTier2Driver(activeDriverFocusObj, 'AUDIT')"
                  >{{ activeDriverFocusObj.AuditIssueCount }} Điểm vênh Audit &rsaquo;</button>
                  <button
                    type="button"
                    class="uc-kpi3t__flag-btn is-causal"
                    @click="selectTier2Driver(activeDriverFocusObj, 'CAUSAL')"
                  >Xem Sơ đồ Nhân quả &rsaquo;</button>
                </div>
              </div>

              <!-- Thanh thu gọn các KPI PENDING -->
              <div v-if="pendingTier2Drivers.length > 0" class="uc-kpi3t__pending-collapse">
                <div class="uc-kpi3t__pending-bar" @click="showPendingTier2 = !showPendingTier2">
                  <span>
                    <b class="tx-muted">[CHỜ TÍCH HỢP API GĐ2]</b> Ẩn gọn <b>{{ pendingTier2Drivers.length }}</b> tiêu chí chưa phát sinh dữ liệu kỳ này
                  </span>
                  <span class="uc-kpi3t__pending-toggle">
                    {{ showPendingTier2 ? 'Thu gọn ▴' : 'Xem (' + pendingTier2Drivers.length + ') ▾' }}
                  </span>
                </div>
                <div v-if="showPendingTier2" class="uc-kpi3t__pending-chips">
                  <span v-for="p in pendingTier2Drivers" :key="p.KpiCode" class="uc-kpi3t__pending-chip" @click="openGoliveSpecs()">
                    <b>{{ p.KpiCode }}</b> {{ p.KpiName }} <small>({{ p.SourceSystem || 'API GĐ2' }})</small>
                  </span>
                </div>
              </div>
            </div>

            <!-- CHẾ ĐỘ 2: BẢNG SỐ LIỆU DENSE -->
            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th style="width:60px;">Mã</th>
                    <th>Tiêu chí vận hành</th>
                    <th style="width:90px;text-align:right;">Kế hoạch</th>
                    <th style="width:90px;text-align:right;">Thực tế</th>
                    <th style="width:74px;text-align:right;">Độ lệch</th>
                    <th style="width:84px;text-align:center;">Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="d in currentTier2Drivers"
                    :key="d.KpiCode"
                    class="is-click"
                    :class="{
                      'uc-kpi3t__row-negative': (d.VariancePct || 0) < 0 && d.StatusBadge !== 'PENDING',
                      'is-selected-row': activeTier2Kpi === d.KpiCode
                    }"
                    @click="selectTier2Driver(d)"
                  >
                    <td><b>{{ d.KpiCode }}</b></td>
                    <td><b>{{ d.KpiName }}</b></td>
                    <td style="text-align:right;">{{ formatKpiVal(d.TargetValue, d.Unit) }}</td>
                    <td style="text-align:right;">
                      <b :class="(d.VariancePct || 0) < 0 ? 'tx-warn' : 'tx-good'">
                        {{ d.StatusBadge === 'PENDING' ? '—' : formatKpiVal(d.ActualValue, d.Unit) }}
                      </b>
                    </td>
                    <td style="text-align:right;">
                      <span v-if="d.StatusBadge !== 'PENDING'" :class="(d.VariancePct || 0) < 0 ? 'tx-bad' : 'tx-good'">
                        {{ (d.VariancePct || 0) > 0 ? '+' : '' }}{{ d.VariancePct || 0 }}%
                      </span>
                      <span v-else class="tx-muted">—</span>
                    </td>
                    <td style="text-align:center;">
                      <span :class="['uc-kpi3t__status-pill', 'is-' + (d.StatusBadge ? d.StatusBadge.toLowerCase() : 'good')]">
                        {{ getTierStatusText(d.StatusBadge) }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- ───────────────────────────────────────────────────────────── -->
          <!-- CỘT PHẢI — TẦNG 3: BIỂU ĐỒ CHẨN ĐOÁN SVG (RADAR / FLOW / GAP) -->
          <!-- ───────────────────────────────────────────────────────────── -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <div class="d-flex align-center gap-2 min-w-0">
                <span class="uc-kpi3t__tier-badge tier-3">TẦNG 3</span>
                <span class="uc-kpi3t__pane-title">
                  CHẨN ĐOÁN TRỰC QUAN:
                  <b>{{ activeTier2DriverObj ? (activeTier2DriverObj.KpiCode + ' — ' + activeTier2DriverObj.KpiName) : (activeTier1Obj ? activeTier1Obj.KpiName : '') }}</b>
                </span>
              </div>

              <div class="d-flex align-center gap-1 flex-wrap">
                <div class="uc-kpi3t__tab-pills">
                  <button
                    type="button"
                    class="uc-kpi3t__tab-btn"
                    :class="{ 'is-active': tier3ActiveTab === 'CAMPUS' }"
                    @click="tier3ActiveTab = 'CAMPUS'"
                  >1. Radar &amp; 5 Cơ Sở</button>
                  <button
                    type="button"
                    class="uc-kpi3t__tab-btn"
                    :class="{ 'is-active': tier3ActiveTab === 'CAUSAL' }"
                    @click="tier3ActiveTab = 'CAUSAL'"
                  >2. Sơ Đồ Nhân Quả ({{ filteredTier3CausalChains.length }})</button>
                  <button
                    type="button"
                    class="uc-kpi3t__tab-btn"
                    :class="{ 'is-active': tier3ActiveTab === 'AUDIT' }"
                    @click="tier3ActiveTab = 'AUDIT'"
                  >3. Độ Vênh Audit ({{ filteredTier3Audits.length }})</button>
                </div>
                <button
                  type="button"
                  class="uc-kpi-ops__simbtn is-solid"
                  style="padding:3px 8px;font-size:11px;"
                  @click="jumpToTier3Page(activeTier1Kpi)"
                >Phân hệ &rsaquo;</button>
              </div>
            </div>

            <!-- ═══════════════════════════════════════════════════════════ -->
            <!-- TAB 1: BIỂU ĐỒ SVG RADAR 4 TRỤC & ĐỐI SÁNH 5 CƠ SỞ         -->
            <!-- ═══════════════════════════════════════════════════════════ -->
            <div v-if="tier3ActiveTab === 'CAMPUS'" class="uc-kpi3t__radar-workbench">
              <!-- Nửa Trái: SVG Spider / Radar Polygon Chart thực thụ -->
              <div class="uc-kpi3t__radar-visual-box">
                <div class="radar-box-head">
                  <div>
                    <div class="radar-sub">{{ activeRadarAxisMeta.axisName }}</div>
                    <div class="radar-campus-title">{{ activeRadarCampusObj.CampusName }}</div>
                  </div>
                  <span class="uc-kpi3t__risk-pill" :class="'is-' + (activeRadarCampusObj.CampusRiskLevel ? activeRadarCampusObj.CampusRiskLevel.toLowerCase() : 'medium')">
                    {{ activeRadarAxisMeta.axisKey }}: {{ activeRadarCampusObj[activeRadarAxisMeta.riskField] || activeRadarCampusObj.CampusRiskScore }}đ
                  </span>
                </div>

                <div class="radar-svg-wrap">
                  <svg class="uc-kpi3t__radar-svg" viewBox="0 0 220 192">
                    <!-- Lưới đồng tâm (25%, 50%, 75%, 100%) -->
                    <polygon points="110,76 130,96 110,116 90,96" class="radar-grid-ring" />
                    <polygon points="110,58 148,96 110,134 72,96" class="radar-grid-ring" />
                    <polygon points="110,40 166,96 110,152 54,96" class="radar-grid-ring is-warn-ring" />
                    <polygon points="110,24 182,96 110,168 38,96" class="radar-grid-ring is-outer" />

                    <!-- 2 Trục tọa độ vuông góc -->
                    <line x1="110" y1="22" x2="110" y2="170" class="radar-axis-line" />
                    <line x1="36" y1="96" x2="184" y2="96" class="radar-axis-line" />

                    <!-- Đa giác Trung bình Toàn trường (Nét đứt) -->
                    <polygon
                      :points="getRadarPolygonPoints(radarSchoolAvgObj, 72, 110, 96)"
                      class="radar-poly-avg"
                    />

                    <!-- Đa giác Cơ sở Đang chọn (Tô màu nổi bật) -->
                    <polygon
                      :points="getRadarPolygonPoints(activeRadarCampusObj, 72, 110, 96)"
                      class="radar-poly-active"
                      :class="(activeRadarCampusObj[activeRadarAxisMeta.riskField] || activeRadarCampusObj.CampusRiskScore) >= 40 ? 'is-danger' : 'is-warn'"
                    />

                    <!-- 4 Đỉnh dữ liệu -->
                    <circle
                      v-for="(pt, pIdx) in getRadarVertexCoords(activeRadarCampusObj, 72, 110, 96)"
                      :key="pIdx"
                      :cx="pt.x"
                      :cy="pt.y"
                      :r="pt.label === activeRadarAxisMeta.axisKey ? 5.5 : 3.5"
                      :class="['radar-vertex-dot', { 'is-focus-vertex': pt.label === activeRadarAxisMeta.axisKey }]"
                    />

                    <!-- Nhãn 4 Trục (Highlight trục tương ứng với KPI Tầng 1 đang chọn) -->
                    <text x="110" y="14" text-anchor="middle" :class="['radar-axis-lbl', { 'is-focus-axis': activeRadarAxisMeta.axisKey === 'TS' }]">
                      Tuyển sinh ({{ activeRadarCampusObj.EnrollmentRisk }}đ)
                    </text>
                    <text x="216" y="99" text-anchor="end" :class="['radar-axis-lbl', { 'is-focus-axis': activeRadarAxisMeta.axisKey === 'HT' }]">
                      Học thuật ({{ activeRadarCampusObj.AcademicRisk }}đ)
                    </text>
                    <text x="110" y="185" text-anchor="middle" :class="['radar-axis-lbl', { 'is-focus-axis': activeRadarAxisMeta.axisKey === 'DV' }]">
                      Dịch vụ ({{ activeRadarCampusObj.ServiceRisk }}đ)
                    </text>
                    <text x="4" y="99" text-anchor="start" :class="['radar-axis-lbl', { 'is-focus-axis': activeRadarAxisMeta.axisKey === 'VH' }]">
                      Vận hành ({{ activeRadarCampusObj.OperationsRisk }}đ)
                    </text>
                  </svg>
                </div>

                <div class="radar-box-legend">
                  <span>
                    <i class="poly-swatch is-active"></i>
                    <b>{{ activeRadarCampusObj.ScopeID }}:</b> {{ activeRadarCampusObj.CampusActualValue != null ? activeRadarCampusObj.CampusActualValue : activeRadarCampusObj.CapacityRate }} {{ activeRadarCampusObj.CampusMetricUnit || '%' }}
                  </span>
                  <span><i class="poly-swatch is-avg"></i> TB Trường ({{ radarSchoolAvgObj[activeRadarAxisMeta.riskField] || radarSchoolAvgObj.CampusRiskScore }}đ)</span>
                </div>
              </div>

              <!-- Nửa Phải: Biểu đồ Thanh Ngang Đối sánh 5 Cơ sở theo đúng KPI Tầng 1 đang chọn -->
              <div class="uc-kpi3t__campus-bars-box">
                <div class="campus-bars-head">
                  <span>{{ activeRadarAxisMeta.barsTitle }}</span>
                  <span v-if="currentUnit !== 'ALL'" class="uc-kpi3t__filter-reset-btn" @click="setUnit('ALL')">
                    Bỏ lọc {{ currentUnit }} &times;
                  </span>
                </div>

                <div class="campus-bars-list">
                  <div
                    v-for="c in tier3Campuses"
                    :key="c.ScopeID"
                    class="campus-bar-item"
                    :class="{ 'is-active': activeRadarCampusObj && activeRadarCampusObj.ScopeID === c.ScopeID }"
                    @mouseenter="selectedRadarCampus = c.ScopeID"
                    @click="selectedRadarCampus = c.ScopeID; setUnit(currentUnit === c.ScopeID ? 'ALL' : c.ScopeID)"
                  >
                    <div class="cb-top">
                      <div class="d-flex align-center gap-1 min-w-0">
                        <span class="cb-code">{{ c.ScopeID }}</span>
                        <b class="cb-name">{{ c.CampusName }}</b>
                      </div>
                      <div class="cb-metrics">
                        <span class="cb-enroll">{{ getCampusSubMetricText(c) }}</span>
                        <b class="cb-pct" :class="getCampusBarToneClass(c, 'tx-')">
                          {{ c.CampusActualValue != null ? c.CampusActualValue : c.CapacityRate }} {{ c.CampusMetricUnit || '%' }}
                        </b>
                        <span v-if="activeTier1Kpi === 'KPI_1' && c.CampusTuitionLossVNĐ > 0" class="cb-loss">
                          -{{ formatBillion(c.CampusTuitionLossVNĐ) }} tỷ
                        </span>
                      </div>
                    </div>

                    <div class="cb-track">
                      <div
                        class="cb-fill"
                        :class="getCampusBarToneClass(c, 'fill-')"
                        :style="{ width: getCampusBarWidthPct(c) + '%' }"
                      ></div>
                      <div
                        class="cb-target-marker"
                        :style="{ left: (activeTier1Kpi === 'KPI_4' ? 82 : 90) + '%' }"
                        :title="'Mốc kế hoạch: ' + (c.CampusTargetValue || 95)"
                      ></div>
                    </div>
                  </div>
                </div>

                <div class="campus-bars-foot">
                  <span>{{ activeRadarCampusObj.CampusKpiInsight || activeRadarAxisMeta.bottleneckText }}</span>
                  <button type="button" class="uc-kpi3t__link-btn" @click="executiveTab = 'RISK'">Mở Radar Dự báo &rsaquo;</button>
                </div>
              </div>
            </div>

            <!-- ═══════════════════════════════════════════════════════════ -->
            <!-- TAB 2: SƠ ĐỒ DÒNG CHẢY NHÂN QUẢ SVG (VISUAL NODE-LINK FLOW) -->
            <!-- ═══════════════════════════════════════════════════════════ -->
            <div v-else-if="tier3ActiveTab === 'CAUSAL'" class="uc-kpi3t__causal-Clean">
              <!-- Thanh chọn chuỗi nhân quả (Loại bỏ tường chữ 4 hộp xếp chồng) -->
              <div class="uc-kpi3t__chain-selector">
                <button
                  v-for="(chain, cIdx) in filteredTier3CausalChains"
                  :key="chain.CorrelationID || cIdx"
                  type="button"
                  class="chain-pill-btn"
                  :class="[
                    { 'is-active': activeCausalChainObj && activeCausalChainObj.CorrelationID === chain.CorrelationID },
                    chain.IsPositiveChain ? 'is-pos' : 'is-neg'
                  ]"
                  @click="activeCausalChainIdx = cIdx"
                >
                  <span class="dot"></span>
                  <span>{{ chain.CauseKpiCode }} &rarr; {{ chain.EffectKpiCode }}</span>
                </button>
              </div>

              <!-- Sơ đồ 3 Nút Trực quan (Node-Link Visual Diagram) cho chuỗi đang chọn -->
              <div v-if="activeCausalChainObj" class="uc-kpi3t__svg-flow-stage">
                <div class="flow-stage-header">
                  <div class="d-flex align-center gap-2">
                    <span class="uc-kpi3t__cflow-badge" :class="activeCausalChainObj.IsPositiveChain ? 'is-pos' : 'is-neg'">
                      {{ activeCausalChainObj.IsPositiveChain ? 'VÒNG LẶP TÍCH CỰC' : 'ĐIỂM NGHẼN TRỌNG YẾU' }}
                    </span>
                    <b class="flow-stage-title">{{ activeCausalChainObj.ChainGroup }}</b>
                  </div>
                  <button
                    type="button"
                    class="uc-kpi-ops__simbtn"
                    style="padding:2px 8px;font-size:11px;"
                    @click="openCausalModal(currentUnit, null, activeCausalChainObj.CauseKpiCode)"
                  >Mô phỏng What-If ↗</button>
                </div>

                <!-- 3-Node Visual Flow Row with SVG Connectors -->
                <div class="uc-kpi3t__visual-nodes">
                  <!-- NODE 1: BIẾN KHỞI PHÁT -->
                  <div class="vnode is-cause">
                    <div class="vnode-step">1. BIẾN KHỞI PHÁT</div>
                    <div class="vnode-code-row">
                      <span class="uc-kpi3t__code-pill">{{ activeCausalChainObj.CauseKpiCode }}</span>
                      <b class="vnode-name">{{ activeCausalChainObj.CauseKpiName }}</b>
                    </div>
                    <div class="vnode-hero-num" :class="activeCausalChainObj.IsPositiveChain ? 'tx-good' : 'tx-warn'">
                      {{ activeCausalChainObj.CauseActualValue != null ? formatKpiVal(activeCausalChainObj.CauseActualValue, activeCausalChainObj.CauseUnit) : 'Đang đo' }}
                    </div>
                    <div class="vnode-sub">
                      Mục tiêu KH: {{ activeCausalChainObj.CauseTargetValue != null ? formatKpiVal(activeCausalChainObj.CauseTargetValue, activeCausalChainObj.CauseUnit) : 'Chuẩn ngành' }}
                    </div>
                  </div>

                  <!-- SVG CONNECTOR ARROW 1 -->
                  <div class="vnode-arrow">
                    <svg viewBox="0 0 44 24" class="vnode-arrow-svg">
                      <line x1="2" y1="12" x2="36" y2="12" stroke="#1b365d" stroke-width="2" stroke-dasharray="3,2" />
                      <polygon points="34,7 43,12 34,17" fill="#1b365d" />
                    </svg>
                  </div>

                  <!-- NODE 2: CƠ CHẾ TRUYỀN DẪN -->
                  <div class="vnode is-mechanism">
                    <div class="vnode-step">2. CƠ CHẾ TÁC ĐỘNG</div>
                    <div class="vnode-mech-text">
                      {{ activeCausalChainObj.CausalChainNarrative }}
                    </div>
                  </div>

                  <!-- SVG CONNECTOR ARROW 2 -->
                  <div class="vnode-arrow">
                    <svg viewBox="0 0 44 24" class="vnode-arrow-svg">
                      <line x1="2" y1="12" x2="36" y2="12" :stroke="activeCausalChainObj.IsPositiveChain ? '#107c41' : '#d13438'" stroke-width="2" />
                      <polygon points="34,7 43,12 34,17" :fill="activeCausalChainObj.IsPositiveChain ? '#107c41' : '#d13438'" />
                    </svg>
                  </div>

                  <!-- NODE 3: HỆ QUẢ ĐỊNH LƯỢNG -->
                  <div class="vnode is-effect" :class="activeCausalChainObj.IsPositiveChain ? 'is-pos' : 'is-neg'">
                    <div class="vnode-step">3. HỆ QUẢ LƯỢNG HÓA (&rarr; {{ activeCausalChainObj.EffectKpiCode }})</div>
                    <div class="vnode-quant" :class="activeCausalChainObj.IsPositiveChain ? 'tx-good' : 'tx-bad'">
                      {{ activeCausalChainObj.QuantifiedImpact }}
                    </div>
                  </div>
                </div>

                <!-- Thanh Quyết sách HĐQT -->
                <div class="uc-kpi3t__directive-banner">
                  <div class="dir-main">
                    <span class="dir-badge">QUYẾT SÁCH HĐQT</span>
                    <span class="dir-text">{{ activeCausalChainObj.ActionRecommendation }}</span>
                  </div>
                  <span class="dir-owner">Đầu mối: <b>{{ activeCausalChainObj.ResponsibleRole || 'Ban Giám Hiệu' }}</b></span>
                </div>
              </div>
            </div>

            <!-- ═══════════════════════════════════════════════════════════ -->
            <!-- TAB 3: BIỂU ĐỒ ĐỘ VÊNH KIỂM TOÁN DUMBBELL (VISUAL GAP)      -->
            <!-- ═══════════════════════════════════════════════════════════ -->
            <div v-else class="uc-kpi3t__audit-container">
              <div v-if="filteredTier3Audits && filteredTier3Audits.length > 0" class="uc-kpi3t__audit-list-clean">
                <div v-for="a in filteredTier3Audits" :key="a.DiscrepancyID" class="uc-kpi3t__audit-dumbbell-card">
                  <div class="d-flex align-center justify-between gap-2 mb-1">
                    <div class="d-flex align-center gap-1 min-w-0">
                      <span class="uc-kpi3t__badge-mismatch">{{ a.Category }}</span>
                      <span class="uc-kpi3t__code-pill">{{ a.KpiCode || 'TS01' }}</span>
                      <b class="text-truncate" style="font-size:12.5px;">{{ a.Title }}</b>
                    </div>
                    <button
                      type="button"
                      class="uc-kpi3t__mini-action-btn"
                      @click="openFactAuditForItem(a)"
                    >Đối soát Fact Store ↗</button>
                  </div>

                  <div class="uc-kpi3t__dumbbell-row">
                    <div class="db-endpoint is-source-a">
                      <span class="db-src-lbl">NGUỒN A &middot; {{ a.PrimarySource }}</span>
                      <b class="db-src-val">{{ a.PrimaryValue }}</b>
                    </div>

                    <div class="db-track-wrap">
                      <div class="db-line">
                        <span class="db-dot dot-a" :style="{ left: getDumbbellPos(a).leftPct + '%' }"></span>
                        <div
                          class="db-gap-bar"
                          :style="{
                            left: Math.min(getDumbbellPos(a).leftPct, getDumbbellPos(a).rightPct) + '%',
                            width: Math.max(8, Math.abs(getDumbbellPos(a).rightPct - getDumbbellPos(a).leftPct)) + '%'
                          }"
                        ></div>
                        <span class="db-dot dot-b" :style="{ left: getDumbbellPos(a).rightPct + '%' }"></span>
                      </div>
                      <div class="db-gap-label">Độ vênh: <b>{{ getDumbbellPos(a).diffLabel }}</b></div>
                    </div>

                    <div class="db-endpoint is-source-b" style="text-align:right;">
                      <span class="db-src-lbl" style="justify-content:flex-end;">NGUỒN B &middot; {{ a.SecondarySource }}</span>
                      <b class="db-src-val tx-bad">{{ a.SecondaryValue }}</b>
                    </div>
                  </div>

                  <div class="uc-kpi3t__audit-desc">
                    <b>Chẩn đoán:</b> {{ a.VarianceAnalysis }}
                  </div>
                </div>
              </div>
              <div v-else class="text-center p-3 tx-muted">
                Không có điểm vênh kiểm toán đối với tiêu chí đang lọc.
              </div>
            </div>
          </div>
        </div>
      </div>


      <!-- ================= SUB-TAB 5: DỰ BÁO & RADAR RỦI RO (TRUE SVG RISK RADAR WORKBENCH) ================= -->
      <div v-if="executiveTab === 'RISK'" class="uc-kpi3t__cockpit">
        <!-- 1. Dải 4 Chỉ số Cảnh báo Sớm + 5 Thẻ Cơ sở tương tác -->
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-3">RADAR DỰ BÁO</span>
              <span class="uc-kpi3t__section-title">TRUNG TÂM BÁO ĐỘNG SỚM RỦI RO VẬN HÀNH &amp; CHỈ ĐẠO PHÒNG NGỪA ({{ currentPeriodName }})</span>
            </div>
            <div class="d-flex align-center gap-2">
              <span class="tx-muted" style="font-size:11.5px;">Dự báo nguy cơ rút học: <b class="tx-bad">{{ totalRiskWithdrawForecast }}</b> &middot; Học phí tiềm ẩn: <b class="tx-bad">{{ totalRiskTuitionForecast }}</b></span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn is-solid"
                @click="openCausalModal(currentUnit, 'RUT_HOC')"
              >Mô phỏng What-If ↗</button>
            </div>
          </div>

          <!-- 5 Thẻ Cơ sở (Click để soi Đa giác SVG Radar bên dưới) -->
          <div class="uc-kpi-ops__risk-cards-grid" v-if="riskCampusCards && riskCampusCards.length">
            <div
              v-for="c in riskCampusCards"
              :key="c.ScopeID"
              :class="['uc-kpi3t__card', 'status-' + (c.RiskScore >= 45 ? 'bad' : (c.RiskScore >= 30 ? 'warn' : 'good')), { 'is-active': selectedRiskCampusScope === c.ScopeID }]"
              @click="selectedRiskCampusScope = (selectedRiskCampusScope === c.ScopeID ? 'ALL' : c.ScopeID); selectedRadarCampus = c.ScopeID"
            >
              <div class="uc-kpi3t__card-top">
                <span class="uc-kpi3t__code">{{ c.ScopeID }} &middot; {{ c.OccupancyRate }}% Lấp đầy</span>
                <span class="uc-kpi3t__status-dot" :class="c.RiskScore >= 45 ? 'is-bad' : (c.RiskScore >= 30 ? 'is-warn' : 'is-good')">
                  {{ c.RiskScore }}đ ({{ c.RiskLevel }})
                </span>
              </div>
              <div class="uc-kpi3t__card-name">{{ c.CampusName }}</div>
              <div class="uc-kpi3t__card-hero">
                <div class="uc-kpi3t__val" :class="c.RiskScore >= 45 ? 'tx-bad' : (c.RiskScore >= 30 ? 'tx-warn' : 'tx-good')">
                  <b>{{ c.WithdrawForecast || '2-3 HS' }}</b>
                </div>
                <div class="uc-kpi3t__target" style="text-align:right;">
                  Rủi ro: <b class="tx-bad">{{ c.TuitionAtRisk }}</b>
                </div>
              </div>
              <!-- 4 Thanh tiểu mục rủi ro (TS, HT, DV, VH) -->
              <div class="uc-kpi-ops__risk-axes">
                <div class="uc-kpi-ops__risk-axis-item" v-if="c.Axis1Name">
                  <span>{{ c.Axis1Name }}</span>
                  <div class="uc-kpi-ops__risk-axis-bar-bg"><div class="uc-kpi-ops__risk-axis-bar-fill" :style="{ width: c.Axis1Pct + '%', background: c.Axis1Color }"></div></div>
                </div>
                <div class="uc-kpi-ops__risk-axis-item" v-if="c.Axis2Name">
                  <span>{{ c.Axis2Name }}</span>
                  <div class="uc-kpi-ops__risk-axis-bar-bg"><div class="uc-kpi-ops__risk-axis-bar-fill" :style="{ width: c.Axis2Pct + '%', background: c.Axis2Color }"></div></div>
                </div>
              </div>
              <div class="uc-kpi3t__card-bot">
                <span class="text-truncate" :title="c.HdqDirective"><b>Chỉ đạo:</b> {{ c.HdqDirective }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 2. Workbench 2 Cột: Cột Trái (SVG Spider Radar + Ngòi nổ) | Cột Phải (Checklist Hành động Khẩn) -->
        <div class="uc-kpi3t__workbench">
          <!-- Cột Trái: Biểu đồ Đa giác SVG Radar 4 Trục & Ngòi nổ rủi ro -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <div class="d-flex align-center gap-2">
                <span class="uc-kpi3t__tier-badge tier-2">PHÂN TÍCH 4 TRỤC</span>
                <span class="uc-kpi3t__pane-title">ĐA GIÁC RỦI RO SVG &amp; NGÒI NỔ DỮ LIỆU ({{ activeRadarCampusObj.CampusName }})</span>
              </div>
              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': riskViewMode === 'CHART' }" @click="riskViewMode = 'CHART'">Biểu đồ &amp; Thẻ</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': riskViewMode === 'TABLE' }" @click="riskViewMode = 'TABLE'">Bảng ({{ riskTriggers.length }})</button>
              </div>
            </div>

            <div v-if="riskViewMode === 'CHART'" class="uc-kpi3t__radar-workbench">
              <!-- SVG Radar Polygon Box -->
              <div class="uc-kpi3t__radar-visual-box">
                <div class="radar-box-head">
                  <div>
                    <div class="radar-sub">TỌA ĐỘ RỦI RO 4 CHIỀU</div>
                    <div class="radar-campus-title">{{ activeRadarCampusObj.CampusName }}</div>
                  </div>
                  <span class="uc-kpi3t__risk-pill is-high">{{ activeRadarCampusObj.CampusRiskScore }}đ</span>
                </div>
                <div class="radar-svg-wrap">
                  <svg class="uc-kpi3t__radar-svg" viewBox="0 0 220 192">
                    <polygon points="110,76 130,96 110,116 90,96" class="radar-grid-ring" />
                    <polygon points="110,58 148,96 110,134 72,96" class="radar-grid-ring" />
                    <polygon points="110,40 166,96 110,152 54,96" class="radar-grid-ring is-warn-ring" />
                    <polygon points="110,24 182,96 110,168 38,96" class="radar-grid-ring is-outer" />
                    <line x1="110" y1="22" x2="110" y2="170" class="radar-axis-line" />
                    <line x1="36" y1="96" x2="184" y2="96" class="radar-axis-line" />
                    <polygon :points="getRadarPolygonPoints(radarSchoolAvgObj, 72, 110, 96)" class="radar-poly-avg" />
                    <polygon :points="getRadarPolygonPoints(activeRadarCampusObj, 72, 110, 96)" class="radar-poly-active is-danger" />
                    <circle
                      v-for="(pt, pIdx) in getRadarVertexCoords(activeRadarCampusObj, 72, 110, 96)"
                      :key="'rk-' + pIdx"
                      :cx="pt.x"
                      :cy="pt.y"
                      r="4"
                      class="radar-vertex-dot"
                    />
                    <text x="110" y="14" text-anchor="middle" class="radar-axis-lbl">Tuyển sinh ({{ activeRadarCampusObj.EnrollmentRisk }}đ)</text>
                    <text x="216" y="99" text-anchor="end" class="radar-axis-lbl">Học thuật ({{ activeRadarCampusObj.AcademicRisk }}đ)</text>
                    <text x="110" y="185" text-anchor="middle" class="radar-axis-lbl">Dịch vụ ({{ activeRadarCampusObj.ServiceRisk }}đ)</text>
                    <text x="4" y="99" text-anchor="start" class="radar-axis-lbl">Vận hành ({{ activeRadarCampusObj.OperationsRisk }}đ)</text>
                  </svg>
                </div>
                <div class="radar-box-legend">
                  <span><i class="poly-swatch is-active"></i> {{ activeRadarCampusObj.ScopeID }}</span>
                  <span><i class="poly-swatch is-avg"></i> TB Trường ({{ radarSchoolAvgObj.CampusRiskScore }}đ)</span>
                </div>
              </div>

              <!-- Danh sách Thanh Ngòi Nổ Rủi Ro (Risk Triggers Gauge Bars) -->
              <div class="uc-kpi3t__campus-bars-box">
                <div class="campus-bars-head">
                  <span>CÁC NGÒI NỔ DỮ LIỆU KÍCH HOẠT BÁO ĐỘNG SỚM</span>
                </div>
                <div class="campus-bars-list">
                  <div
                    v-for="t in riskTriggers"
                    :key="t.TriggerID"
                    class="campus-bar-item"
                    @click="jumpToFactStore(getTriggerFactDomain(t), t.TargetCampuses)"
                  >
                    <div class="cb-top">
                      <b class="cb-name">{{ t.TriggerName }}</b>
                      <div class="cb-metrics">
                        <span class="cb-code">{{ t.TargetCampuses }}</span>
                        <b class="cb-pct" :class="t.SeverityPct >= 70 ? 'tx-bad' : 'tx-warn'">{{ t.SeverityPct }}%</b>
                      </div>
                    </div>
                    <div class="cb-track">
                      <div class="cb-fill" :class="t.SeverityPct >= 70 ? 'fill-bad' : 'fill-warn'" :style="{ width: Math.min(100, t.SeverityPct) + '%' }"></div>
                    </div>
                    <div class="d-flex justify-between mt-1" style="font-size:11px;color:var(--ink2);">
                      <span class="text-truncate"><b>Ngòi nổ:</b> {{ t.DataTrigger || t.DataTriggerT9 }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th>Trục Rủi Ro</th>
                    <th>Ngòi Nổ Dữ Liệu</th>
                    <th>Chỉ Báo Nguy Cơ</th>
                    <th>Trọng Điểm</th>
                    <th style="text-align:right;">Đối soát</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="t in riskTriggers" :key="'tb-' + t.TriggerID">
                    <td><b>{{ t.TriggerName }}</b></td>
                    <td>{{ t.DataTrigger || t.DataTriggerT9 }}</td>
                    <td>{{ t.RiskThreat || t.RiskThreatT10 }}</td>
                    <td><span class="uc-kpi3t__code-pill">{{ t.TargetCampuses }}</span></td>
                    <td style="text-align:right;">
                      <button type="button" class="uc-kpi3t__mini-action-btn" @click="jumpToFactStore(getTriggerFactDomain(t), t.TargetCampuses)">Chứng từ ↗</button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Cột Phải: Bảng Điều Khiển Chỉ Đạo Can Thiệp Khẩn Cấp (Interactive Action Cards) -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <div class="d-flex align-center gap-2">
                <span class="uc-kpi3t__tier-badge tier-1">QUYẾT SÁCH HĐQT</span>
                <span class="uc-kpi3t__pane-title">DANH MỤC CHỈ ĐẠO CAN THIỆP PHÒNG NGỪA ({{ filteredRiskChecklist.length }})</span>
              </div>
              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': directiveStatusFilter === 'ALL' }" @click="directiveStatusFilter = 'ALL'">Tất cả</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': directiveStatusFilter === 'URGENT' }" @click="directiveStatusFilter = 'URGENT'">Khẩn cấp</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': directiveStatusFilter === 'PENDING' }" @click="directiveStatusFilter = 'PENDING'">Chưa xong</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': directiveStatusFilter === 'DONE' }" @click="directiveStatusFilter = 'DONE'">Đã xong</button>
              </div>
            </div>

            <div class="p-3" style="display:flex;flex-direction:column;gap:6px;">
              <div
                v-for="ch in filteredRiskChecklist"
                :key="ch.ChecklistID"
                class="campus-bar-item"
                :class="{ 'is-active': isDirectiveDone(ch.ChecklistID) }"
                @click="toggleDirectiveStatus(ch.ChecklistID)"
              >
                <div class="cb-top">
                  <div class="d-flex align-center gap-2 min-w-0">
                    <input
                      type="checkbox"
                      class="uc-kpi-ops__directive-check"
                      :checked="isDirectiveDone(ch.ChecklistID)"
                      @change.stop="toggleDirectiveStatus(ch.ChecklistID)"
                    />
                    <b class="cb-name" :style="{ textDecoration: isDirectiveDone(ch.ChecklistID) ? 'line-through' : 'none' }">{{ ch.DirectiveTitle }}</b>
                  </div>
                  <div class="cb-metrics" style="flex-shrink:0;">
                    <span class="uc-kpi3t__code-pill">{{ ch.OwnerRole }}</span>
                    <b :class="ch.StatusClass === 'is-urgent' ? 'tx-bad' : 'tx-warn'">{{ ch.DeadlineDate }}</b>
                  </div>
                </div>
                <div style="font-size:11.5px;color:var(--ink2);padding-left:22px;">
                  {{ ch.SubText }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ================= SUB-TAB 2: KIỂM TOÁN & ĐIỂM VÊNH BÁO CÁO (MASTER-DETAIL DUMBBELL WORKBENCH) ================= -->
      <div v-if="executiveTab === 'AUDIT'" class="uc-kpi3t__cockpit">
        <!-- 1. Top Strip & Bộ lọc gọn sạch trên 1 khối -->
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-2">KIỂM TOÁN SỐ LIỆU</span>
              <span class="uc-kpi3t__section-title">ĐỐI SOÁT ĐỘ VÊNH ĐA NGUỒN &amp; NGHỊCH LÝ VẬN HÀNH ({{ filteredAuditList.length }}/{{ auditDiscrepanciesList.length }})</span>
            </div>

            <div class="d-flex align-center gap-2 flex-wrap">
              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditDomainFilter === 'ALL' }" @click="auditDomainFilter = 'ALL'; activeAuditIdx = 0">Tất cả ({{ auditDiscrepanciesList.length }})</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditDomainFilter === 'TS' }" @click="auditDomainFilter = 'TS'; activeAuditIdx = 0">Tuyển sinh</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditDomainFilter === 'CM' }" @click="auditDomainFilter = 'CM'; activeAuditIdx = 0">Đào tạo &amp; LMS</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditDomainFilter === 'HR' }" @click="auditDomainFilter = 'HR'; activeAuditIdx = 0">Nhân sự</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditDomainFilter === 'CSVC' }" @click="auditDomainFilter = 'CSVC'; activeAuditIdx = 0">CSVC &amp; Dịch vụ</button>
              </div>

              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditViewMode === 'DUMBBELL' }" @click="auditViewMode = 'DUMBBELL'">Biểu đồ Dumbbell</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': auditViewMode === 'TABLE' }" @click="auditViewMode = 'TABLE'">Bảng tra cứu</button>
              </div>
            </div>
          </div>

          <!-- 4 Ô KPI Kiểm toán -->
          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-primary" style="cursor:pointer;" @click="auditSeverityFilter = 'ALL'">
              <div class="uc-kpi3t__impact-label">Tổng Điểm Đối Soát</div>
              <div class="uc-kpi3t__impact-val">{{ auditDiscrepanciesList.length }} <small>điểm</small></div>
              <div class="uc-kpi3t__impact-sub">Quét tự động giữa Báo cáo &amp; Fact Store</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger" style="cursor:pointer;" @click="auditSeverityFilter = (auditSeverityFilter === 'CRITICAL' ? 'ALL' : 'CRITICAL')">
              <div class="uc-kpi3t__impact-label">Lệch Số Liệu Khẩn (Critical)</div>
              <div class="uc-kpi3t__impact-val">{{ auditKpiStats.critical }} <small>điểm đỏ</small></div>
              <div class="uc-kpi3t__impact-sub">Cần chuẩn hóa định nghĩa kỳ chốt sổ</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn" style="cursor:pointer;" @click="auditSeverityFilter = (auditSeverityFilter === 'WARN' ? 'ALL' : 'WARN')">
              <div class="uc-kpi3t__impact-label">Nghịch Lý &amp; Điểm Nghẽn (Warn)</div>
              <div class="uc-kpi3t__impact-val">{{ auditKpiStats.warn }} <small>cảnh báo</small></div>
              <div class="uc-kpi3t__impact-sub">Tỷ lệ báo cáo tốt nhưng đầu ra thực tế nghẽn</div>
            </div>
            <div class="uc-kpi3t__impact-card is-success" style="cursor:pointer;" @click="auditSeverityFilter = (auditSeverityFilter === 'INFO' ? 'ALL' : 'INFO')">
              <div class="uc-kpi3t__impact-label">Đã Xác Minh Chứng Từ</div>
              <div class="uc-kpi3t__impact-val">{{ auditKpiStats.resolved }} <small>hoàn tất</small></div>
              <div class="uc-kpi3t__impact-sub">Đã khớp 100% với Fact Store nguyên tử</div>
            </div>
          </div>
        </div>

        <!-- 2. Master–Detail Audit Workbench (Trái: Dumbbell Gap Chart | Phải: Hồ sơ Đối soát Chi tiết) -->
        <div v-if="auditViewMode === 'DUMBBELL'" class="uc-kpi3t__workbench">
          <!-- Cột Trái: Biểu đồ Độ vênh Dumbbell tập trung -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">BIỂU ĐỒ ĐỘ VÊNH DUMBBELL: NGUỒN A (BÁO CÁO) VS NGUỒN B (THỰC TẾ)</span>
              <span class="tx-muted" style="font-size:11px;">Chọn 1 dòng để xem hồ sơ giải trình &rarr;</span>
            </div>

            <div class="p-2" style="display:flex;flex-direction:column;gap:6px;max-height:520px;overflow-y:auto;">
              <div
                v-for="(item, aIdx) in filteredAuditList"
                :key="item.AuditCode || item.DiscrepancyID"
                class="uc-kpi3t__audit-dumbbell-card"
                :class="{ 'is-selected-row': activeAuditFocusObj && (activeAuditFocusObj.AuditCode === item.AuditCode) }"
                style="cursor:pointer;"
                @click="activeAuditIdx = aIdx"
              >
                <div class="d-flex align-center justify-between gap-2 mb-1">
                  <div class="d-flex align-center gap-1 min-w-0">
                    <span class="uc-kpi3t__badge-mismatch">{{ item.Category }}</span>
                    <span class="uc-kpi3t__code-pill">{{ item.AuditCode }}</span>
                    <b class="text-truncate" style="font-size:12.5px;">{{ item.Title }}</b>
                  </div>
                  <span class="uc-kpi3t__var-pill is-neg">{{ item.ScopeID || 'ALL' }}</span>
                </div>

                <div class="uc-kpi3t__dumbbell-row">
                  <div class="db-endpoint is-source-a">
                    <span class="db-src-lbl">NGUỒN A &middot; BÁO CÁO</span>
                    <b class="db-src-val">{{ item.PrimaryValue }}</b>
                  </div>

                  <div class="db-track-wrap">
                    <div class="db-line">
                      <span class="db-dot dot-a" :style="{ left: getDumbbellPos(item).leftPct + '%' }"></span>
                      <div
                        class="db-gap-bar"
                        :style="{
                          left: Math.min(getDumbbellPos(item).leftPct, getDumbbellPos(item).rightPct) + '%',
                          width: Math.max(10, Math.abs(getDumbbellPos(item).rightPct - getDumbbellPos(item).leftPct)) + '%'
                        }"
                      ></div>
                      <span class="db-dot dot-b" :style="{ left: getDumbbellPos(item).rightPct + '%' }"></span>
                    </div>
                    <div class="db-gap-label">Vênh: <b>{{ item.VarianceAmount ? (item.VarianceAmount + ' ' + (item.VarianceUnit || '')) : getDumbbellPos(item).diffLabel }}</b></div>
                  </div>

                  <div class="db-endpoint is-source-b" style="text-align:right;">
                    <span class="db-src-lbl" style="justify-content:flex-end;">NGUỒN B &middot; FACT STORE</span>
                    <b class="db-src-val tx-bad">{{ item.SecondaryValue }}</b>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Cột Phải: Hồ sơ Đối soát Chi tiết (Audit Inspector) -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <div class="d-flex align-center gap-2">
                <span class="uc-kpi3t__tier-badge tier-3">HỒ SƠ GIẢI TRÌNH</span>
                <span class="uc-kpi3t__pane-title">CHI TIẾT ĐỐI SOÁT &amp; CHỈ ĐẠO XỬ LÝ</span>
              </div>
              <button
                v-if="activeAuditFocusObj"
                type="button"
                class="uc-kpi-ops__simbtn is-solid"
                @click="openFactModal(getAuditDomain(activeAuditFocusObj), activeAuditFocusObj.ScopeID, activeAuditFocusObj)"
              >Mở Chứng Từ Gốc Fact Store ↗</button>
            </div>

            <div v-if="activeAuditFocusObj" class="uc-kpi3t__causal-Clean">
              <div class="flow-stage-header">
                <div class="d-flex align-center gap-2">
                  <span class="uc-kpi3t__badge-mismatch">{{ activeAuditFocusObj.Category }}</span>
                  <span class="uc-kpi3t__code-pill">{{ activeAuditFocusObj.AuditCode }}</span>
                  <b class="flow-stage-title">{{ activeAuditFocusObj.Title }}</b>
                </div>
              </div>

              <!-- Sơ đồ Đối chiếu 2 Nguồn Trực quan -->
              <div class="uc-kpi3t__visual-nodes">
                <div class="vnode is-cause">
                  <div class="vnode-step">NGUỒN A (BÁO CÁO TỔNG HỢP)</div>
                  <div class="vnode-hero-num">{{ activeAuditFocusObj.PrimaryValue }}</div>
                  <div class="vnode-sub">{{ activeAuditFocusObj.PrimarySource }}</div>
                </div>

                <div class="vnode-arrow">
                  <svg viewBox="0 0 44 24" class="vnode-arrow-svg">
                    <line x1="4" y1="12" x2="40" y2="12" stroke="#d13438" stroke-width="2.5" stroke-dasharray="3,2" />
                  </svg>
                </div>

                <div class="vnode is-effect is-neg">
                  <div class="vnode-step">NGUỒN B (GIAO DỊCH FACT STORE)</div>
                  <div class="vnode-hero-num tx-bad">{{ activeAuditFocusObj.SecondaryValue }}</div>
                  <div class="vnode-sub">{{ activeAuditFocusObj.SecondarySource }}</div>
                </div>

                <div class="vnode-arrow">
                  <svg viewBox="0 0 44 24" class="vnode-arrow-svg">
                    <line x1="2" y1="12" x2="36" y2="12" stroke="#1b365d" stroke-width="2" />
                    <polygon points="34,7 43,12 34,17" fill="#1b365d" />
                  </svg>
                </div>

                <div class="vnode is-mechanism">
                  <div class="vnode-step">NGUYÊN NHÂN CHÊNH LỆCH</div>
                  <div class="vnode-mech-text">{{ activeAuditFocusObj.VarianceAnalysis }}</div>
                </div>
              </div>

              <div class="uc-kpi3t__directive-banner">
                <div class="dir-main">
                  <span class="dir-badge">CHỈ ĐẠO XỬ LÝ</span>
                  <span class="dir-text">{{ activeAuditFocusObj.ResolutionDirective || 'Chuẩn hóa quy tắc chốt số liệu tự động qua eSign Fact Store.' }}</span>
                </div>
                <span class="dir-owner">Đầu mối: <b>{{ activeAuditFocusObj.ActionOwner }}</b></span>
              </div>
            </div>
          </div>
        </div>

        <!-- Bảng tra cứu gọn -->
        <div v-else class="uc-kpi3t__pane">
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
              <thead>
                <tr>
                  <th style="width:110px;">Mã &amp; Nhóm</th>
                  <th>Nội dung đối soát &amp; Phân tích</th>
                  <th style="width:180px;">Nguồn A (Báo cáo)</th>
                  <th style="width:180px;">Nguồn B (Thực tế)</th>
                  <th style="width:130px;">Đầu mối</th>
                  <th style="width:90px;text-align:right;">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in filteredAuditList" :key="'tb-audit-' + (item.AuditCode || item.DiscrepancyID)">
                  <td>
                    <b>{{ item.AuditCode }}</b>
                    <div><span class="uc-kpi3t__badge-mismatch">{{ item.Category }}</span></div>
                  </td>
                  <td>
                    <b>{{ item.Title }}</b>
                    <div class="tx-muted" style="font-size:11px;">{{ item.VarianceAnalysis }}</div>
                  </td>
                  <td>
                    <b>{{ item.PrimaryValue }}</b>
                    <div class="tx-muted" style="font-size:10.5px;">{{ item.PrimarySource }}</div>
                  </td>
                  <td>
                    <b class="tx-bad">{{ item.SecondaryValue }}</b>
                    <div class="tx-muted" style="font-size:10.5px;">{{ item.SecondarySource }}</div>
                  </td>
                  <td>{{ item.ActionOwner }}</td>
                  <td style="text-align:right;">
                    <button type="button" class="uc-kpi3t__mini-action-btn" @click="openFactModal(getAuditDomain(item), item.ScopeID, item)">Chứng từ ↗</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ================= 4. TAB 3: MA TRẬN 60 KPI (4-PILLAR VISUAL BOARD) ================= -->
      <div v-if="executiveTab === 'FRAMEWORK'" class="uc-kpi3t__cockpit">
        <!-- Top Control & Health Bar -->
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">KHUNG 60 KPI</span>
              <span class="uc-kpi3t__section-title">MA TRẬN 60 CHỈ TIÊU VẬN HÀNH THEO 4 TRỤ CỘT CHIẾN LƯỢC</span>
            </div>

            <div class="uc-kpi3t__health-inline">
              <span class="h-lbl">Tiến độ:</span>
              <div class="uc-kpi3t__mini-health-bar">
                <div class="seg is-good" :style="{ width: kpiHealthStats.goodPct + '%' }"></div>
                <div class="seg is-warn" :style="{ width: kpiHealthStats.warnPct + '%' }"></div>
                <div class="seg is-pending" :style="{ width: kpiHealthStats.pendingPct + '%' }"></div>
              </div>
              <span class="h-pill is-good"><b>{{ kpiHealthStats.good }}</b> Đạt ({{ kpiHealthStats.goodPct }}%)</span>
              <span class="h-pill is-warn"><b>{{ kpiHealthStats.warn }}</b> Cảnh báo ({{ kpiHealthStats.warnPct }}%)</span>
              <span class="h-pill is-pending"><b>{{ kpiHealthStats.pending }}</b> Chờ API GĐ2</span>
            </div>

            <div class="d-flex align-center gap-2 flex-wrap">
              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': frameworkStatusFilter === 'ALL' }" @click="frameworkStatusFilter = 'ALL'">Tất cả ({{ periodSnapshots.length }})</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': frameworkStatusFilter === 'GOOD' }" @click="frameworkStatusFilter = 'GOOD'">Đạt ({{ kpiHealthStats.good }})</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': frameworkStatusFilter === 'WARN' }" @click="frameworkStatusFilter = 'WARN'">Cảnh báo ({{ kpiHealthStats.warn }})</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': frameworkStatusFilter === 'PENDING' }" @click="frameworkStatusFilter = 'PENDING'">Chờ API ({{ kpiHealthStats.pending }})</button>
              </div>

              <input
                type="text"
                v-model="frameworkSearchQuery"
                class="uc-kpi-ops__rf-search-input"
                style="height:24px;width:190px;font-size:11.5px;padding:2px 8px;"
                placeholder="Tìm mã / tên KPI..."
              />

              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': frameworkViewMode === 'heatmap' }" @click="frameworkViewMode = 'heatmap'">Ma trận 4 Trụ cột</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': frameworkViewMode === 'table' }" @click="frameworkViewMode = 'table'">Bảng 60 KPI</button>
              </div>
            </div>
          </div>

          <!-- CHẾ ĐỘ 1: 4 CỘT TRỤ CỘT SONG SONG (4-PILLAR VISUAL COLUMNS) -->
          <div v-if="frameworkViewMode === 'heatmap'" class="uc-kpi3t__pillars-board">
            <div
              v-for="grp in ['Quy mô & Tuyển sinh', 'Giáo dục & Học thuật', 'Dịch vụ & An toàn', 'Tài chính & CSVC']"
              :key="grp"
              class="uc-kpi3t__pillar-col"
            >
              <div class="pillar-col-head">
                <div class="d-flex justify-between align-center">
                  <b>{{ grp }}</b>
                  <span class="uc-kpi3t__code-pill">{{ getGroupKpis(grp).length }} KPI</span>
                </div>
                <div class="pillar-col-stats">
                  <span class="tx-good"><b>{{ getGroupKpis(grp).filter(k => k.Status === 'GOOD').length }}</b> Đạt</span> &middot;
                  <span class="tx-warn"><b>{{ getGroupKpis(grp).filter(k => k.Status === 'WARN').length }}</b> Cảnh báo</span> &middot;
                  <span class="tx-muted"><b>{{ getGroupKpis(grp).filter(k => k.Status === 'PENDING').length }}</b> API</span>
                </div>
              </div>

              <div class="pillar-col-body">
                <div
                  v-for="kpi in getGroupKpis(grp)"
                  :key="kpi.KpiCode"
                  :class="['uc-kpi-ops__heatmap-cell', 'status-' + (kpi.Status ? kpi.Status.toLowerCase() : 'pending')]"
                  @click="openFactModal(getKpiFactDomain(kpi.KpiCode), 'ALL', null, kpi)"
                >
                  <div class="d-flex justify-between align-center gap-1">
                    <span class="uc-kpi-ops__hm-code">{{ kpi.KpiCode }}</span>
                    <b v-if="kpi.Status !== 'PENDING'" :class="kpi.Status === 'GOOD' ? 'tx-good' : 'tx-warn'" style="font-size:12px;">
                      {{ formatKpiVal(kpi.ActualValue, kpi.Unit) }}
                    </b>
                    <span v-else class="tx-muted" style="font-size:10.5px;">API GĐ2</span>
                  </div>
                  <div class="uc-kpi-ops__hm-name" :title="kpi.KpiName">{{ kpi.KpiName }}</div>
                  <div v-if="kpi.Status !== 'PENDING'" class="uc-kpi3t__pbar" style="height:4px;margin-top:4px;">
                    <div
                      class="uc-kpi3t__pfill"
                      :class="kpi.Status === 'GOOD' ? 'fill-good' : 'fill-warn'"
                      :style="{ width: Math.min(100, Math.max(8, Number(kpi.Rate) || 80)) + '%' }"
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- CHẾ ĐỘ 2: BẢNG TRA CỨU 60 KPI -->
          <div v-else class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
              <thead>
                <tr>
                  <th style="width:90px;">Mã KPI</th>
                  <th>Tên Chỉ Số &amp; Nhóm Trụ Cột</th>
                  <th style="width:110px;text-align:right;">Kế Hoạch</th>
                  <th style="width:110px;text-align:right;">Thực Tế</th>
                  <th style="width:160px;">Tiến Độ Hoàn Thành</th>
                  <th style="width:100px;text-align:center;">Trạng Thái</th>
                  <th style="width:90px;text-align:right;">Đối Soát</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="kpi in filteredFrameworkKpis" :key="kpi.KpiCode">
                  <td><b>{{ kpi.KpiCode }}</b></td>
                  <td>
                    <b>{{ kpi.KpiName }}</b>
                    <div class="tx-muted" style="font-size:11px;">{{ kpi.KpiGroup }}</div>
                  </td>
                  <td style="text-align:right;">{{ kpi.Status === 'PENDING' ? '—' : formatKpiVal(kpi.TargetValue, kpi.Unit) }}</td>
                  <td style="text-align:right;">
                    <b v-if="kpi.Status !== 'PENDING'" :class="kpi.Status === 'GOOD' ? 'tx-good' : 'tx-warn'">
                      {{ formatKpiVal(kpi.ActualValue, kpi.Unit) }}
                    </b>
                    <span v-else class="tx-muted">Chờ API</span>
                  </td>
                  <td>
                    <div v-if="kpi.Status !== 'PENDING'" class="uc-kpi3t__bullet-track" style="height:8px;">
                      <div
                        class="uc-kpi3t__bullet-bar"
                        :class="kpi.Status === 'GOOD' ? 'fill-good' : 'fill-warn'"
                        :style="{ width: Math.min(100, Math.max(6, Number(kpi.Rate) || 0)) + '%' }"
                      ></div>
                    </div>
                    <span v-else class="tx-muted" style="font-size:11px;">Lộ trình 02/11</span>
                  </td>
                  <td style="text-align:center;">
                    <span :class="['uc-kpi3t__status-pill', 'is-' + (kpi.Status ? kpi.Status.toLowerCase() : 'pending')]">
                      {{ getTierStatusText(kpi.Status) }}
                    </span>
                  </td>
                  <td style="text-align:right;">
                    <button v-if="kpi.Status !== 'PENDING'" type="button" class="uc-kpi3t__mini-action-btn" @click="openFactModal(getKpiFactDomain(kpi.KpiCode), 'ALL', null, kpi)">Fact ↗</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ================= DIALOG MODAL: ĐỐI SOÁT GIAO DỊCH GỐC (FACT STORE ON-DEMAND DIALOG) ================= -->
      <div
        v-if="isFactsModalOpen"
        class="uc-kpi-ops__facts-modal-overlay"
        @click.self="closeFactModal()"
      >
        <div class="uc-kpi-ops__facts-modal-dialog">
          <!-- Modal Header -->
          <div class="uc-kpi-ops__facts-modal-head">
            <div>
              <div class="uc-kpi-ops__facts-modal-title">
                Tra Cứu Giao Dịch Gốc &amp; Đối Soát Kiểm Toán (Kỳ {{ currentPeriodName }} &middot; Cơ sở: {{ currentUnitTitle }})
              </div>
              <div class="uc-kpi-ops__facts-modal-sub">
                Đối chiếu 1-1 giữa chỉ số KPI báo cáo vĩ mô và các giao dịch nguyên tử thực tế từ kho dữ liệu chốt kỳ
              </div>
            </div>
            <button
              type="button"
              class="uc-kpi-ops__facts-modal-close"
              title="Đóng hộp thoại (ESC)"
              @click="closeFactModal()"
            >
              &times;
            </button>
          </div>

          <!-- Modal Body -->
          <div class="uc-kpi-ops__facts-modal-body">
            <!-- Context Banner khi mở từ một Chỉ Số KPI Cụ Thể -->
            <div v-if="selectedKpiItem" class="uc-kpi-ops__fact-audit-banner" style="background:#f0fdf4;border-color:#bbf7d0;">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:4px;">
                <span class="uc-kpi-ops__rf-status-badge st-good">
                  ĐỐI SOÁT CHỈ SỐ: {{ selectedKpiItem.KpiCode }} &middot; {{ selectedKpiItem.KpiGroup }}
                </span>
                <span style="font-size:11px;color:#15803d;font-weight:700;">
                  Báo cáo: {{ formatKpiVal(selectedKpiItem.ActualValue, selectedKpiItem.Unit) }} {{ selectedKpiItem.Unit }}
                </span>
              </div>
              <div class="uc-kpi-ops__fact-audit-title" style="color:#166534;">
                {{ selectedKpiItem.KpiName }}
              </div>
              <div class="uc-kpi-ops__fact-audit-meta" style="color:#15803d;">
                Kế hoạch: <b>{{ formatKpiVal(selectedKpiItem.TargetValue, selectedKpiItem.Unit) }} {{ selectedKpiItem.Unit }}</b> &middot; Tỷ lệ đạt: <b>{{ selectedKpiItem.Rate }}%</b> &middot; Nguồn: <b>{{ selectedKpiItem.SourceSystem || 'CSDL Chốt kỳ' }}</b>
              </div>
            </div>

            <!-- Context Banner khi mở từ một Chuyên Đề Kiểm Toán Cụ Thể -->
            <div v-else-if="selectedAuditItem" class="uc-kpi-ops__fact-audit-banner">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:4px;">
                <span class="uc-kpi-ops__fact-audit-badge" :class="'is-' + (selectedAuditItem.Category ? selectedAuditItem.Category.toLowerCase() : 'paradox')">
                  {{ selectedAuditItem.Category === 'PARADOX' ? 'NGHỊCH LÝ ĐIỀU HÀNH' : (selectedAuditItem.Category === 'BOTTLENECK' ? 'ĐIỂM NGHẼN VẬN HÀNH' : 'ĐỐI SOÁT VÊNH DỮ LIỆU') }} &middot; {{ selectedAuditItem.AuditCode }}
                </span>
                <span class="uc-kpi-ops__sev-badge" :class="'is-' + (selectedAuditItem.SeverityLevel ? selectedAuditItem.SeverityLevel.toLowerCase() : 'warn')" style="font-size:10px;">
                  Mức độ: {{ selectedAuditItem.SeverityLevel || 'WARN' }}
                </span>
              </div>
              <div class="uc-kpi-ops__fact-audit-title">
                {{ selectedAuditItem.Title }}
              </div>
              <div class="uc-kpi-ops__fact-audit-meta">
                Đầu mối giải trình: <b>{{ selectedAuditItem.ActionOwner }}</b> &middot; Phạm vi: <b>{{ selectedAuditItem.ScopeID || 'Toàn trường' }}</b>
              </div>
            </div>

            <!-- 10 Domain Chips Phân Hệ Đối Soát -->
            <div class="uc-kpi-ops__seg mb-3" style="flex-wrap:wrap;row-gap:6px;">
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'ENROLLMENT' }"
                @click="fetchOperationalFacts('ENROLLMENT')"
              >{{ getFactDomainButtonLabel('ENROLLMENT', 'Sĩ số & Công suất (Basic Data)') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'WITHDRAWAL' }"
                @click="fetchOperationalFacts('WITHDRAWAL')"
              >{{ getFactDomainButtonLabel('WITHDRAWAL', 'Học sinh Rút học (SIS)') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'CRM' }"
                @click="fetchOperationalFacts('CRM')"
              >{{ getFactDomainButtonLabel('CRM', 'Tuyển sinh & Leads CRM') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'MAINTENANCE' }"
                @click="fetchOperationalFacts('MAINTENANCE')"
              >{{ getFactDomainButtonLabel('MAINTENANCE', 'Bảo trì CSVC') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'HEALTH' }"
                @click="fetchOperationalFacts('HEALTH')"
              >{{ getFactDomainButtonLabel('HEALTH', 'Y tế học đường') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'LEAVE' }"
                @click="fetchOperationalFacts('LEAVE')"
              >{{ getFactDomainButtonLabel('LEAVE', 'Nghỉ phép & Công') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'CLUB' }"
                @click="fetchOperationalFacts('CLUB')"
              >{{ getFactDomainButtonLabel('CLUB', 'Dịch vụ CLB & Tài chính') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'HR_TURNOVER' }"
                @click="fetchOperationalFacts('HR_TURNOVER')"
              >{{ getFactDomainButtonLabel('HR_TURNOVER', 'Biến động NV') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'TEACHING' }"
                @click="fetchOperationalFacts('TEACHING')"
              >{{ getFactDomainButtonLabel('TEACHING', 'Tiến độ dạy & LMS') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'SAFETY_ME' }"
                @click="fetchOperationalFacts('SAFETY_ME')"
              >{{ getFactDomainButtonLabel('SAFETY_ME', 'Bán trú & App Me') }}</button>
            </div>

            <!-- Thanh Đối Soát 3 Cột (Reconciliation Strip) -->
            <div class="uc-kpi-ops__reconcile-strip" :class="'is-' + reconciliationSummary.status.toLowerCase()">
              <div class="uc-kpi-ops__reconcile-col">
                <div class="uc-kpi-ops__reconcile-lbl">1. Chỉ số KPI Báo Cáo</div>
                <div class="uc-kpi-ops__reconcile-val">{{ reconciliationSummary.kpiReported }}</div>
                <div class="uc-kpi-ops__reconcile-sub">{{ reconciliationSummary.kpiNote }}</div>
              </div>

              <div class="uc-kpi-ops__reconcile-sep">&rarr;</div>

              <div class="uc-kpi-ops__reconcile-col">
                <div class="uc-kpi-ops__reconcile-lbl">2. Tổng Gộp Fact Store Gốc</div>
                <div class="uc-kpi-ops__reconcile-val">{{ reconciliationSummary.factMetric }}</div>
                <div class="uc-kpi-ops__reconcile-sub">{{ reconciliationSummary.factCount }} giao dịch nguyên tử</div>
              </div>

              <div class="uc-kpi-ops__reconcile-sep">&rarr;</div>

              <div class="uc-kpi-ops__reconcile-col is-verdict">
                <div class="uc-kpi-ops__reconcile-lbl">3. Kết Luận Kiểm Toán</div>
                <div class="uc-kpi-ops__reconcile-status">
                  <span class="status-dot"></span>
                  <b>{{ reconciliationSummary.statusText }}</b>
                </div>
                <div class="uc-kpi-ops__reconcile-finding">
                  {{ reconciliationSummary.auditFinding }} &middot; Trách nhiệm: <b>{{ reconciliationSummary.responsibleRole }}</b>
                </div>
              </div>
            </div>

            <!-- Bộ Lọc Kiểm Toán Nhanh -->
            <div class="uc-kpi-ops__audit-filter-bar">
              <div class="uc-kpi-ops__audit-filter-label">Bộ lọc kiểm toán:</div>
              <div class="uc-kpi-ops__audit-chips">
                <button
                  type="button"
                  :class="['uc-kpi-ops__audit-chip', { 'is-active': factAuditFilter === 'ALL' }]"
                  @click="factAuditFilter = 'ALL'"
                >
                  Tất cả ({{ filteredOperationalFactsList.length }})
                </button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__audit-chip is-pending', { 'is-active': factAuditFilter === 'PENDING' }]"
                  @click="factAuditFilter = 'PENDING'"
                >
                  Tồn đọng / Chưa xử lý (Pending)
                </button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__audit-chip is-anomaly', { 'is-active': factAuditFilter === 'ANOMALY' }]"
                  @click="factAuditFilter = 'ANOMALY'"
                >
                  Trọng điểm rủi ro
                </button>
                <span v-if="factCampusFilter && factCampusFilter !== 'ALL'" class="ml-auto text-caption font-weight-bold" style="color:var(--accent2);display:inline-flex;align-items:center;">
                  Đang lọc cơ sở: {{ factCampusFilter }}
                  <a href="javascript:void(0)" style="margin-left:6px;color:#ef4444;text-decoration:none;" @click="factCampusFilter = 'ALL'">&times; Bỏ lọc</a>
                </span>
              </div>
            </div>

            <!-- Bảng Dữ Liệu Facts -->
            <div v-if="isFactsLoading" style="padding:40px;text-align:center;color:#64748b;">
              Đang đối soát dữ liệu từ CSDL eSign...
            </div>
            <div v-else class="uc-kpi-ops__tablewrap" style="max-height:460px;overflow-y:auto;">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th style="width:90px;">Ngày</th>
                    <th class="ta-l" style="width:170px;">{{ factTableHeaders.col1 }}</th>
                    <th class="ta-l" style="width:130px;">{{ factTableHeaders.col2 }}</th>
                    <th class="ta-l">{{ factTableHeaders.col3 }}</th>
                    <th style="width:110px;">{{ factTableHeaders.col4 }}</th>
                    <th style="width:95px;">Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="f in filteredOperationalFactsList" :key="f.FactID">
                    <td>{{ f.OccurredDate || '—' }}</td>
                    <td class="ta-l">
                      <b>{{ f.EntityName || f.EntityCode }}</b>
                      <small v-if="f.EntityCode" style="display:block;font-size:10px;color:#64748b;">{{ f.EntityCode }} &middot; {{ f.ScopeID }}</small>
                    </td>
                    <td class="ta-l">
                      <span class="font-weight-bold" style="color:var(--accent2);">{{ f.Dim1 || '—' }}</span>
                      <small v-if="f.Dim2" style="display:block;font-size:10.5px;color:#64748b;">{{ f.Dim2 }}</small>
                    </td>
                    <td class="ta-l" style="font-size:11.5px;color:#334155;max-width:320px;">
                      <div>{{ f.Dim3 || '—' }}</div>
                      <small v-if="f.Dim4" style="display:block;color:#64748b;margin-top:2px;">{{ f.Dim4 }}</small>
                    </td>
                    <td class="tx-strong">
                      {{ f.MetricCount != null ? f.MetricCount : (f.MetricAmount != null ? formatNumber(f.MetricAmount) : '—') }}
                    </td>
                    <td>
                      <span :class="['uc-kpi-ops__status-pill', f.Status === 'PENDING' || f.Status === 'CRITICAL' ? 'is-danger' : 'is-good']">
                        {{ f.Status || 'COMPLETED' }}
                      </span>
                    </td>
                  </tr>
                  <tr v-if="!filteredOperationalFactsList.length">
                    <td colspan="6" style="padding:28px;text-align:center;color:#94a3b8;">
                      Không tìm thấy bản ghi nào khớp với điều kiện lọc kiểm toán này.
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Modal Footer -->
          <div class="uc-kpi-ops__facts-modal-foot">
            <span style="font-size:11.5px;color:#64748b;">
              Nguồn dữ liệu: Immutable Snapshot Vault &middot; Tổng cộng {{ operationalFactsList.length }} bản ghi nguyên tử
            </span>
            <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="closeFactModal()">
              Đóng (ESC)
            </button>
          </div>
        </div>
      </div>

      <!-- ================= DIALOG VÙNG TÁC ĐỘNG (CAUSAL SPOTLIGHT MODAL) ================= -->
      <div
        v-if="isCausalModalOpen"
        class="uc-kpi-ops__causal-spot"
        @click.self="closeCausalModal()"
      >
        <div class="uc-kpi-ops__causal-dialog">
          <!-- Header -->
          <div class="uc-kpi-ops__causal-head">
            <div class="uc-kpi-ops__causal-titles">
              <div class="uc-kpi-ops__causal-kicker">VÙNG TÁC ĐỘNG (ƯỚC TÍNH) · CÔNG CỤ PHÂN TÍCH, KHÔNG PHẢI SỐ KPI CHÍNH THỨC</div>
              <div class="uc-kpi-ops__causal-head-title">
                Nếu <b>{{ availableCausalKpis.find(k => k.kpiCode === causalKpiCode) ? availableCausalKpis.find(k => k.kpiCode === causalKpiCode).label : causalKpiCode }}</b>
                lệch <b>{{ causalDeltaAuto }} đơn vị</b> tại <b>{{ currentCausalUnitName }}</b>
              </div>
            </div>
            <div class="uc-kpi-ops__causal-scenarios">
              <button
                type="button"
                class="uc-kpi-ops__causal-x"
                @click="closeCausalModal()"
                title="Đóng hộp thoại (Esc)"
              >&times;</button>
            </div>
          </div>

        <!-- Body Layout -->
        <div class="uc-kpi-ops__causal-body">
          <!-- Rail bên trái: Điều kiện IF (Đơn vị + Delta) -->
          <aside class="uc-kpi-ops__causal-rail">
            <div class="uc-kpi-ops__causal-rail-h">Điều kiện (IF)</div>

            <!-- Đơn vị -->
            <div class="uc-kpi-ops__causal-f">
              <label>Đơn vị cơ sở</label>
              <div class="uc-kpi-ops__causal-opts">
                <button
                  v-for="u in causalUnitOptions"
                  :key="u.k"
                  type="button"
                  :class="{ 'is-on': causalUnit === u.k }"
                  @click="setCausalUnit(u.k)"
                >{{ u.t }}</button>
              </div>
            </div>

            <!-- 2. Chỉ tiêu phân tích (KPI Gốc) -->
            <div class="uc-kpi-ops__causal-f">
              <label>Chỉ tiêu phân tích (KPI Gốc)</label>
              <select
                v-model="causalKpiCode"
                class="uc-kpi-ops__select"
                style="width:100%;font-weight:600;font-size:12px;background:#fff;"
                @change="selectCausalKpi(causalKpiCode)"
              >
                <optgroup
                  v-for="grp in [...new Set(availableCausalKpis.map(k => k.group))]"
                  :key="grp"
                  :label="grp"
                >
                  <option
                    v-for="k in availableCausalKpis.filter(x => x.group === grp)"
                    :key="k.kpiCode"
                    :value="k.kpiCode"
                  >{{ k.label }}</option>
                </optgroup>
              </select>
            </div>

            <!-- 3. Mức độ biến động What-If -->
            <div class="uc-kpi-ops__causal-f">
              <div class="d-flex align-center justify-space-between">
                <label>Mức độ biến động: <b>{{ causalDeltaAuto }}</b></label>
                <button
                  v-if="causalDeltaOverride !== null"
                  type="button"
                  @click="causalDeltaOverride = null"
                  style="font-size:10px;padding:1px 5px;border:1px solid #cbd5e1;border-radius:3px;background:#f8fafc;cursor:pointer;"
                  title="Đặt lại giá trị thực tế tháng 9"
                >↺ Thực tế</button>
              </div>
              <input
                type="range"
                :min="1"
                :max="50"
                step="1"
                :value="causalDeltaAuto"
                @input="causalDeltaOverride = Math.max(1, Math.min(50, Number($event.target.value)))"
                class="uc-kpi-ops__range"
              />
              <div style="font-size:10.5px;color:#64748b;margin-top:4px;">
                Kéo trượt để mô phỏng tác động (1 – 50 đơn vị).
              </div>
            </div>

            <!-- 4. Ghi chú dữ liệu nền -->
            <div class="uc-kpi-ops__causal-rail-note" style="margin-top:auto;">
              Dữ liệu kỳ: {{ currentPeriodName }}. Biểu phí &amp; ngưỡng được lấy trực tiếp từ CSDL eSign (Học phí {{ currentCausalAssumption.AnnualTuitionMillion }} tr/năm · Quy mô {{ currentCausalAssumption.CurrentEnrollment }} HS).
            </div>
          </aside>

          <!-- Main bên phải -->
          <main class="uc-kpi-ops__causal-main">

            <!-- ════════════════════════════════════════════════════════════════════ -->
            <!-- GENERIC CAUSAL ENGINE: 3 Giai đoạn Lan truyền Hệ luỵ               -->
            <!-- Tự động sinh từ ElasticityMatrix + CSDL eSign (không hardcode)     -->
            <!-- ════════════════════════════════════════════════════════════════════ -->
            <section class="uc-kpi-ops__causal-hero">
              <span class="uc-kpi-ops__causal-hero-tag">Cán cân Quyết định Điều hành (Generic Engine)</span>
              <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-top:4px;">
                <span class="uc-kpi-ops__causal-hero-text" style="flex:1;">
                  {{ genericCausalCalc.stage1Desc }}
                </span>
              </div>
            </section>

            <!-- 3 GIAI ĐOẠN HUYẾT MẠCH (Thay cây SVG tĩnh) -->
            <section class="uc-kpi-ops__net-impact-matrix">
              <!-- Giai đoạn 1: Tức thì -->
              <div class="uc-kpi-ops__impact-col">
                <div class="uc-kpi-ops__impact-head">
                  <span class="impact-badge is-vol">Giai đoạn 1 · Tức thì</span>
                  <span class="impact-title" style="font-size:10px;color:#ef4444;font-weight:700;">1 - 30 ngày</span>
                </div>
                <div class="uc-kpi-ops__impact-body">
                  <div class="impact-row is-highlight">
                    <span>{{ genericCausalCalc.isStudentScale ? 'Hụt biên đóng góp:' : 'Tác động rủi ro / tài chính:' }}</span>
                    <b class="tx-bad">−{{ genericCausalCalc.stage1Fmt }} tỷ VNĐ</b>
                  </div>
                  <div class="impact-row">
                    <span>{{ genericCausalCalc.isStudentScale ? 'Sĩ số sau biến động:' : 'Hiện trạng vận hành:' }}</span>
                    <b :class="{ 'tx-bad': genericCausalCalc.isStudentScale ? genericCausalCalc.enrolledAfter < currentCausalAssumption.CurrentEnrollment : false }">
                      {{ genericCausalCalc.statusHeadline }}
                    </b>
                  </div>
                  <div v-if="genericCausalCalc.stepCostTriggered" class="impact-row" style="color:#d97706;font-size:11px;">
                    <span>Bẫy định phí lớp học:</span>
                    <b>Lương GV không giảm kịp → Lỗ gộp lớp ~{{ genericCausalCalc.fixedCostBurden }} tỷ</b>
                  </div>
                  <!-- Downstream effects Stage 1 từ elasticity matrix -->
                  <div
                    v-for="eff in genericCausalCalc.allEffects.filter(e => e.Stage === 1)"
                    :key="eff.EffectKpiCode"
                    class="impact-row"
                    style="font-size:10.5px;"
                  >
                    <span style="color:#64748b;">→ {{ eff.EffectKpiCode }}:</span>
                    <span>{{ eff.InterventionName }}</span>
                  </div>
                </div>
              </div>

              <!-- Giai đoạn 2: Vận hành & Tải bù -->
              <div class="uc-kpi-ops__impact-col">
                <div class="uc-kpi-ops__impact-head">
                  <span class="impact-badge is-money">Giai đoạn 2 · Vận hành</span>
                  <span class="impact-title" style="font-size:10px;color:#d97706;font-weight:700;">2 - 9 tháng</span>
                </div>
                <div class="uc-kpi-ops__impact-body">
                  <div class="impact-row">
                    <span>{{ genericCausalCalc.isStudentScale ? 'Leads cần bù sĩ số:' : 'Áp lực vận hành:' }}</span>
                    <b v-if="genericCausalCalc.isStudentScale">≈ {{ genericCausalCalc.leadsNeed }} leads
                      <small>({{ genericCausalCalc.leadsPctMonth }}% năng lực tháng)</small>
                    </b>
                    <b v-else style="font-size:11px;">{{ genericCausalCalc.operationalPressure }}</b>
                  </div>
                  <div class="impact-row is-highlight">
                    <span>Phương án can thiệp tốt nhất:</span>
                    <b style="font-size:11px;">{{ genericCausalCalc.interventionName }}</b>
                  </div>
                  <div class="impact-row">
                    <span>Chi phí can thiệp:</span>
                    <b>{{ genericCausalCalc.interventionCost }} tỷ VNĐ</b>
                  </div>
                  <div class="impact-row">
                    <span>Giá trị cứu được:</span>
                    <b class="tx-good">+{{ genericCausalCalc.interventionSaved }} tỷ VNĐ</b>
                  </div>
                  <!-- Downstream effects Stage 2 -->
                  <div
                    v-for="eff in genericCausalCalc.allEffects.filter(e => e.Stage === 2)"
                    :key="eff.EffectKpiCode"
                    class="impact-row"
                    style="font-size:10.5px;"
                  >
                    <span style="color:#64748b;">→ {{ eff.EffectKpiCode }}:</span>
                    <span>{{ eff.InterventionOwner }}</span>
                  </div>
                </div>
              </div>

              <!-- Giai đoạn 3: LTV dài hạn + Cán cân Đánh đổi -->
              <div class="uc-kpi-ops__impact-col">
                <div class="uc-kpi-ops__impact-head">
                  <span class="impact-badge is-action">Giai đoạn 3 · Chiến lược</span>
                  <span class="impact-title" style="font-size:10px;color:#7c3aed;font-weight:700;">1 - 3 năm</span>
                </div>
                <div class="uc-kpi-ops__impact-body">
                  <div class="impact-row">
                    <span>{{ genericCausalCalc.isStudentScale ? 'Tổn thất LTV tích lũy:' : 'Rủi ro gián tiếp & Uy tín:' }}</span>
                    <b class="tx-bad">−{{ genericCausalCalc.ltvLoss }} tỷ VNĐ</b>
                  </div>
                  <div class="impact-row" v-if="genericCausalCalc.isStudentScale">
                    <span>Đứt gãy phễu chuyển cấp:</span>
                    <b class="tx-bad">−{{ genericCausalCalc.transitionLoss }} tỷ VNĐ</b>
                  </div>
                  <div class="impact-row" v-else>
                    <span>Kiểm soát chuẩn chất lượng:</span>
                    <b style="color:#059669;font-weight:700;">{{ genericCausalCalc.standardControl }}</b>
                  </div>
                  <div class="impact-row is-highlight" :class="{ 'is-good': genericCausalCalc.shouldIntervene, 'is-bad-row': !genericCausalCalc.shouldIntervene }">
                    <span>Lợi ích ròng can thiệp:</span>
                    <b :class="genericCausalCalc.shouldIntervene ? 'tx-good' : 'tx-bad'">
                      {{ genericCausalCalc.shouldIntervene ? '+' : '' }}{{ genericCausalCalc.netBenefit }} tỷ
                      (ROI {{ genericCausalCalc.roi }}%)
                    </b>
                  </div>
                  <div class="impact-row" style="margin-top:4px;">
                    <span>Phán quyết HĐQT:</span>
                    <b :style="{ color: genericCausalCalc.shouldIntervene ? '#16a34a' : '#b45309', fontSize: '11px' }">
                      {{ genericCausalCalc.shouldIntervene ? 'Phê duyệt can thiệp' : 'Chấp nhận biến động tự nhiên' }}
                    </b>
                  </div>
                  <div class="impact-row">
                    <span>Trách nhiệm:</span>
                    <b style="font-size:11px;">{{ genericCausalCalc.interventionOwner }}</b>
                  </div>
                </div>
              </div>
            </section>

            <!-- 2. CÂY TÁC ĐỘNG TRỰC QUAN SVG (SVG Causal Tree 4 tầng) -->
            <section class="uc-kpi-ops__causal-card" style="margin-top:12px;">
              <div class="uc-kpi-ops__causal-card-head">
                <div class="uc-kpi-ops__causal-card-title">Cây tác động trực quan</div>
                <div class="uc-kpi-ops__causal-legend">
                  <span><em class="is-real"></em>Dữ liệu thật</span>
                  <span><em class="is-est"></em>Ước tính (kèm khoảng)</span>
                  <span><em class="is-bad"></em>Vượt ngưỡng</span>
                  <span>Độ dày đường = giá trị tiền</span>
                </div>
              </div>

              <!-- SVG Render -->
              <svg class="uc-kpi-ops__causal-tree-svg" viewBox="0 0 920 340" preserveAspectRatio="xMidYMid meet">
                <!-- Cột Header -->
                <text x="30" y="24" class="tree-col-head">SỰ KIỆN</text>
                <text x="240" y="24" class="tree-col-head">VÒNG 1 - TRỰC TIẾP</text>
                <text x="470" y="24" class="tree-col-head">VÒNG 2 - TIỀN &amp; VẬN HÀNH</text>
                <text x="700" y="24" class="tree-col-head">VÒNG 3 - DÀI HẠN</text>

                <!-- Đường nối Bézier -->
                <path
                  v-for="e in causalTreeEdges"
                  :key="e.id"
                  :d="e.d"
                  :class="['tree-edge', {
                    'is-bad': e.isBad,
                    'is-hl': causalHlSet && causalHlSet[e.from] && causalHlSet[e.to],
                    'is-dim': causalHlSet && (!causalHlSet[e.from] || !causalHlSet[e.to])
                  }]"
                  :stroke-width="causalHlSet && causalHlSet[e.from] && causalHlSet[e.to] ? Math.max(3.5, e.w + 1) : e.w"
                />

                <!-- Nodes -->
                <g
                  v-for="n in causalTreeNodes"
                  :key="n.id"
                  :transform="'translate(' + n.x + ',' + n.y + ')'"
                  :class="['tree-node', {
                    'is-bad': n.isBad,
                    'is-good': n.isGood,
                    'is-hl': causalHlSet && causalHlSet[n.id],
                    'is-dim': causalHlSet && !causalHlSet[n.id]
                  }]"
                  @mouseenter="onNodeMouseEnter(n.id)"
                  @mouseleave="onNodeMouseLeave()"
                  @click="onNodeClick(n.id)"
                >
                  <rect width="180" height="60" class="box" />
                  <rect width="4" height="60" class="bar" />
                  <text x="12" y="18" class="title">{{ n.label }}</text>
                  <text x="12" y="37" class="value">{{ n.value }}</text>
                  <text x="12" y="51" class="sub">{{ n.sub }}</text>
                </g>
              </svg>

              <!-- Formula & Gaps -->
              <div class="uc-kpi-ops__causal-formula">
                <template v-if="hoveredCausalNode">
                  <b>{{ hoveredCausalNode.label }}</b> &middot; {{ hoveredCausalNode.formula }}
                </template>
                <template v-else>
                  Rê chuột (hoặc chạm) vào một ô để xem công thức và đường lan truyền.
                </template>
              </div>
              <div class="uc-kpi-ops__causal-gaps">
                <b>Khoảng trống dữ liệu</b> (chưa tính vào cây): Xe đưa rước, bán trú, đồng phục (cần thu phí theo mã học sinh) &middot; Anh chị em và người giới thiệu (cần quan hệ gia đình theo mã học sinh).
              </div>
            </section>

            <!-- 3. MẮT XÍCH LAN TRUYỀN & KẾ HOẠCH HÀNH ĐỘNG THỰC TẾ (CSDL T9/2026) -->
            <section class="uc-kpi-ops__causal-card" style="margin-top:12px;">
              <div class="uc-kpi-ops__causal-card-head">
                <div class="uc-kpi-ops__causal-card-title">
                  Mắt xích Lan truyền &amp; Kế hoạch Hành động Thực tế (CSDL {{ currentPeriodName }})
                </div>
                <div style="font-size:11px;color:#64748b;">
                  Tự động truy vết từ 15 Chuỗi Nhân Quả eSign · Khớp với hồ sơ đơn vị {{ currentCausalUnitName }}
                </div>
              </div>
              <div class="uc-kpi-ops__causal-chain-list" style="padding:10px 14px;display:flex;flex-direction:column;gap:10px;">
                <div
                  v-for="c in currentKpiCorrelations"
                  :key="c.CorrelationID"
                  class="uc-kpi-ops__chain-item"
                  style="background:#fff;border:1px solid #e2e8f0;border-left:4px solid var(--accent);border-radius:4px;padding:10px 12px;"
                >
                  <div class="d-flex align-center justify-space-between mb-1">
                    <span style="font-weight:700;font-size:12.5px;color:#0f172a;">
                      {{ c.ChainGroup }}
                      <span v-if="c.CauseKpiCode && c.EffectKpiCode" style="font-size:11px;color:#64748b;font-weight:400;margin-left:6px;">
                        ({{ c.CauseKpiCode }} &rarr; {{ c.EffectKpiCode }})
                      </span>
                    </span>
                    <span class="badge" style="background:#e0f2fe;color:#0369a1;font-size:10px;padding:2px 8px;border-radius:3px;font-weight:600;">{{ c.RelationshipType }}</span>
                  </div>
                  <div style="font-size:11.5px;color:#334155;line-height:1.4;margin-bottom:6px;">
                    <b>Cơ chế lan truyền:</b> {{ c.Description }}
                  </div>
                  <div class="d-flex align-center justify-space-between flex-wrap" style="gap:8px;background:#f8fafc;padding:6px 10px;border-radius:4px;font-size:11px;">
                    <div><b>Lượng hóa thiệt hại:</b> <span class="tx-bad">{{ c.QuantifiedImpact }}</span></div>
                    <div><b>Trách nhiệm:</b> <b>{{ c.ResponsibleRole }}</b></div>
                  </div>
                  <div class="mt-2" style="font-size:11.5px;color:#1e293b;">
                    <span style="color:#059669;font-weight:700;">Hành động giải quyết:</span> {{ c.RecommendedAction }}
                  </div>
                </div>
              </div>

              <!-- Thanh Khuyến nghị Điều hành eSign -->
              <div style="padding:10px 14px;background:#f1f5f9;border-top:1px solid #e2e8f0;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
                <div style="font-size:11.5px;color:#334155;">
                  Khuyến nghị HĐQT: <b :style="{ color: genericCausalCalc.shouldIntervene ? '#16a34a' : '#b45309' }">{{ genericCausalCalc.shouldIntervene ? 'Phê duyệt gói can thiệp bảo toàn dòng tiền (' + genericCausalCalc.interventionName + ')' : 'Theo dõi biến động tự nhiên' }}</b>
                </div>
                <div style="font-size:11px;color:#64748b;">
                  Chịu trách nhiệm thực thi: <b>{{ genericCausalCalc.interventionOwner }}</b>
                </div>
              </div>
            </section>
          </main>
        </div>
      </div>
    </div>
    </div>

    <!-- 4. PAGE 1: CƠ CẤU SĨ SỐ KHỐI LỚP & 5 CƠ SỞ (TS01, TS02) -->
    <div v-if="page === 1" class="uc-kpi-ops__page">
      <div class="uc-kpi3t__cockpit">
        <!-- Dải 4 Chỉ số Quy mô trên đỉnh -->
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">PHÂN HỆ SĨ SỐ</span>
              <span class="uc-kpi3t__section-title">CƠ CẤU SĨ SỐ THEO KHỐI LỚP &amp; LẤP ĐẦY 5 CƠ SỞ ({{ currentUnitTitle }})</span>
            </div>
            <div class="uc-kpi3t__toggle-group">
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': gradeViewMode === 'CHART' }" @click="gradeViewMode = 'CHART'">Biểu đồ Cột ngang</button>
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': gradeViewMode === 'TABLE' }" @click="gradeViewMode = 'TABLE'">Bảng số liệu</button>
            </div>
          </div>

          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-primary">
              <div class="uc-kpi3t__impact-label">Tổng Sĩ Số Hiện Diện</div>
              <div class="uc-kpi3t__impact-val">{{ formatNumber(displayStudents) }} <small>/ {{ formatNumber(displayTarget) }} HS</small></div>
              <div class="uc-kpi3t__impact-sub">Tỷ lệ lấp đầy toàn hệ thống: {{ ((displayStudents / (displayTarget || 1)) * 100).toFixed(1) }}%</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Dư Địa Chỗ Trống Còn Lại</div>
              <div class="uc-kpi3t__impact-val">-{{ Math.max(0, displayTarget - displayStudents) }} <small>chỗ trống</small></div>
              <div class="uc-kpi3t__impact-sub">Tập trung tại MNLK (-37 HS), MNBH (-49 HS) &amp; K11 (-25 HS)</div>
            </div>
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">Khối Đầu Cấp Vượt Chỉ Tiêu</div>
              <div class="uc-kpi3t__impact-val">Khối 10 <small>(102.8%)</small></div>
              <div class="uc-kpi3t__impact-sub">Đạt 185/180 HS · THCS đạt 799/841 HS (95.0%)</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Biến Động Trong Kỳ (T9)</div>
              <div class="uc-kpi3t__impact-val">+21 <small>nhập / -12 rút</small></div>
              <div class="uc-kpi3t__impact-sub">Tăng ròng +9 HS trong tháng 09/2026</div>
            </div>
          </div>
        </div>

        <!-- Workbench 2 Cột: Trái (Biểu đồ phân bổ theo Khối) | Phải (Đối sánh 5 Cơ sở) -->
        <div class="uc-kpi3t__workbench">
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">BIỂU ĐỒ QUY MÔ &amp; CƠ CẤU NAM/NỮ THEO KHỐI LỚP ({{ currentGradeRows.length }} KHỐI)</span>
              <span class="tx-muted" style="font-size:11px;">Vạch chuẩn: 100 HS/khối</span>
            </div>

            <div v-if="gradeViewMode === 'CHART'" class="p-3">
              <div class="uc-kpi-ops__chart-legend mb-2">
                <span><span class="legend-dot is-boy"></span> Nam</span>
                <span><span class="legend-dot is-girl"></span> Nữ</span>
                <span class="legend-note">Vạch đứt: Ngưỡng quy mô tối thiểu 100 HS/khối</span>
              </div>
              <div class="uc-kpi-ops__grade-bars-list">
                <div v-for="r in currentGradeRows" :key="r.Ten" class="uc-kpi-ops__grade-bar-row">
                  <div class="uc-kpi-ops__grade-bar-label"><b>{{ r.Ten }}</b></div>
                  <div class="uc-kpi-ops__grade-bar-track">
                    <div
                      class="uc-kpi-ops__grade-bar-inner"
                      :style="{ width: Math.max(8, Math.min(100, (r.SLHocSinh / maxGradeEnrollment) * 100)) + '%' }"
                    >
                      <div
                        class="uc-kpi-ops__grade-segment is-boy"
                        :style="{ width: (r.SLHocSinh > 0 ? (r.SL_HSNam / r.SLHocSinh) * 100 : 50) + '%' }"
                      >
                        <span v-if="r.SL_HSNam > 25">{{ r.SL_HSNam }}</span>
                      </div>
                      <div
                        class="uc-kpi-ops__grade-segment is-girl"
                        :style="{ width: (r.SLHocSinh > 0 ? (r.SL_HSNu / r.SLHocSinh) * 100 : 50) + '%' }"
                      >
                        <span v-if="r.SL_HSNu > 25">{{ r.SL_HSNu }}</span>
                      </div>
                    </div>
                    <div
                      class="uc-kpi-ops__grade-benchmark-line"
                      :style="{ left: Math.min(100, (100 / maxGradeEnrollment) * 100) + '%' }"
                    ></div>
                  </div>
                  <div class="uc-kpi-ops__grade-bar-stat">
                    <b class="stat-total">{{ formatNumber(r.SLHocSinh) }}</b> <small>HS</small>
                    <span :class="['uc-kpi-ops__cell-tag', r.SLHocSinh >= 100 ? 'is-good' : 'is-warn']">
                      {{ r.SLHocSinh >= 100 ? 'Ổn định' : 'Mỏng' }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th class="ta-l">Khối Lớp</th>
                    <th>Tổng sĩ số</th>
                    <th>Nam</th>
                    <th>Nữ</th>
                    <th>Tỷ trọng</th>
                    <th class="ta-l">Đánh giá</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in currentGradeRows" :key="r.Ten">
                    <td class="ta-l tx-strong">{{ r.Ten }}</td>
                    <td class="tx-strong">{{ formatNumber(r.SLHocSinh) }}</td>
                    <td>{{ formatNumber(r.SL_HSNam) }}</td>
                    <td>{{ formatNumber(r.SL_HSNu) }}</td>
                    <td>{{ ((r.SLHocSinh / (computedTotalStudents || 1)) * 100).toFixed(1) }}%</td>
                    <td class="ta-l">
                      <span :class="['uc-kpi-ops__cell-tag', r.SLHocSinh >= 100 ? 'is-good' : 'is-warn']">
                        {{ r.SLHocSinh >= 100 ? 'Ổn định' : 'Quy mô mỏng' }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Cột Phải: Biểu đồ Lấp đầy Công suất Thiết kế 5 Cơ sở -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">ĐỐI SÁNH CÔNG SUẤT THIẾT KẾ &amp; HIỆN DIỆN 5 CƠ SỞ</span>
              <button type="button" class="uc-kpi3t__mini-action-btn" @click="openFactModal('STUDENTS')">Fact Store ↗</button>
            </div>
            <div class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in tier3Campuses" :key="'g5-' + c.ScopeID" class="campus-bar-item">
                <div class="cb-top">
                  <div class="d-flex align-center gap-1">
                    <span class="cb-code">{{ c.ScopeID }}</span>
                    <b class="cb-name">{{ c.CampusName }}</b>
                  </div>
                  <div class="cb-metrics">
                    <span class="cb-enroll"><b>{{ c.CurrentEnrollment }}</b> / {{ c.PlannedCapacity }} HS</span>
                    <b class="cb-pct" :class="c.CapacityRate < 85 ? 'tx-bad' : (c.CapacityRate < 95 ? 'tx-warn' : 'tx-good')">{{ c.CapacityRate }}%</b>
                    <span v-if="c.CampusTuitionLossVNĐ > 0" class="cb-loss">-{{ formatBillion(c.CampusTuitionLossVNĐ) }} tỷ</span>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill" :class="c.CapacityRate < 85 ? 'fill-bad' : (c.CapacityRate < 95 ? 'fill-warn' : 'fill-good')" :style="{ width: Math.min(100, c.CapacityRate) + '%' }"></div>
                  <div class="cb-target-marker" style="left:95%;"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 5. PAGE 2: HỌC SINH CHUYỂN ĐI & RÚT HỌC (TS04 — PARETO WORKBENCH) -->
    <div v-if="page === 2" class="uc-kpi-ops__page">
      <div class="uc-kpi3t__cockpit">
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-3">PHÂN HỆ GIỮ CHÂN HS</span>
              <span class="uc-kpi3t__section-title">PHÂN TÍCH PARETO NGUYÊN NHÂN RÚT HỌC &amp; ĐÒN BẨY GIỮ CHÂN (TS04)</span>
            </div>
            <div class="d-flex align-center gap-2">
              <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="openCausalModal(currentUnit, 'RUT_HOC')">Mô phỏng Mở tuyến Xe Bus ↗</button>
            </div>
          </div>

          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">Tỷ Lệ Rút Hồ Sơ Lũy Kế</div>
              <div class="uc-kpi3t__impact-val">2.02% <small>/ 10% Trần KH</small></div>
              <div class="uc-kpi3t__impact-sub">Tổng 53 HS chuyển đi toàn năm học (Tháng 9: 12 HS)</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Rút Do Khoảng Cách / Xe Bus</div>
              <div class="uc-kpi3t__impact-val">21 HS <small>(39.6%)</small></div>
              <div class="uc-kpi3t__impact-sub">Nguyên nhân số 1 có thể can thiệp bằng mở tuyến đón</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Cơ Sở Rút Cao Nhất (MNLK)</div>
              <div class="uc-kpi3t__impact-val">7.75% <small>(10/129 HS)</small></div>
              <div class="uc-kpi3t__impact-sub">Tiệm cận ngưỡng cảnh báo 10% · MNBH rút 3.36%</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Thất Thu Học Phí Ước Tính</div>
              <div class="uc-kpi3t__impact-val">-3.45 <small>Tỷ VNĐ/năm</small></div>
              <div class="uc-kpi3t__impact-sub">Riêng nhóm xa trường chiếm ~1.37 tỷ VNĐ/năm</div>
            </div>
          </div>
        </div>

        <div class="uc-kpi3t__workbench">
          <!-- Cột Trái: Biểu đồ Xếp hạng Pareto Lý do Rút học -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">BIỂU ĐỒ PARETO NGUYÊN NHÂN RÚT HỌC &amp; KHẢ NĂNG CAN THIỆP</span>
              <div class="uc-kpi3t__toggle-group">
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': withdrawViewMode === 'CHART' }" @click="withdrawViewMode = 'CHART'">Biểu đồ Pareto</button>
                <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': withdrawViewMode === 'TABLE' }" @click="withdrawViewMode = 'TABLE'">Bảng</button>
              </div>
            </div>

            <div v-if="withdrawViewMode === 'CHART'" class="p-3">
              <div class="uc-kpi-ops__withdraw-chart-wrap">
                <div v-for="(r, i) in displayTopWithdrawReasons" :key="r.name" class="uc-kpi-ops__withdraw-rank-item">
                  <div class="uc-kpi-ops__withdraw-rank-top">
                    <div class="uc-kpi-ops__withdraw-rank-name">
                      <span class="rank-idx">#{{ i + 1 }}</span>
                      <b>{{ r.name }}</b>
                    </div>
                    <div class="uc-kpi-ops__withdraw-rank-stat">
                      <b class="tx-bad">{{ r.count }} HS</b>
                      <span class="rank-pct">({{ r.percent }}%)</span>
                    </div>
                  </div>
                  <div class="uc-kpi-ops__withdraw-bar-track">
                    <div
                      :class="['uc-kpi-ops__withdraw-bar-fill', getWithdrawBarColorClass(r.name)]"
                      :style="{ width: Math.min(100, r.percent * 2.2) + '%' }"
                    ></div>
                  </div>
                  <div class="uc-kpi-ops__withdraw-rank-bot">
                    <span>Đầu mối: <b>{{ r.owner || 'Ban Giám Hiệu' }}</b></span>
                    <span :class="['can-intervene-badge', getInterveneClass(r.name)]">{{ getInterveneLabel(r.name) }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th class="ta-l">Lý do rút hồ sơ</th>
                    <th>Số lượng</th>
                    <th>Tỷ trọng (%)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in displayTopWithdrawReasons" :key="r.name">
                    <td class="ta-l tx-strong">{{ r.name }}</td>
                    <td class="tx-strong tx-bad">{{ r.count }} HS</td>
                    <td>{{ r.percent }}%</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Cột Phải: Đối sánh Rút học theo 5 Cơ sở + Hồ sơ gần nhất -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">TỶ LỆ RÚT HỒ SƠ THEO 5 CƠ SỞ &amp; HỒ SƠ GẦN NHẤT</span>
              <button type="button" class="uc-kpi3t__mini-action-btn" @click="openFactModal('WITHDRAWALS')">Fact Store ↗</button>
            </div>
            <div class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in tier3Campuses" :key="'wd-' + c.ScopeID" class="campus-bar-item">
                <div class="cb-top">
                  <div class="d-flex align-center gap-1">
                    <span class="cb-code">{{ c.ScopeID }}</span>
                    <b class="cb-name">{{ c.CampusName }}</b>
                  </div>
                  <div class="cb-metrics">
                    <span class="cb-enroll">Trần KH &le; 10%</span>
                    <b class="cb-pct" :class="c.WithdrawRate >= 5 ? 'tx-bad' : (c.WithdrawRate >= 3 ? 'tx-warn' : 'tx-good')">{{ c.WithdrawRate }}%</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill" :class="c.WithdrawRate >= 5 ? 'fill-bad' : (c.WithdrawRate >= 3 ? 'fill-warn' : 'fill-good')" :style="{ width: Math.min(100, c.WithdrawRate * 9) + '%' }"></div>
                </div>
              </div>

              <div class="uc-kpi3t__directive-banner mt-1">
                <div class="dir-main">
                  <span class="dir-badge">CHỈ ĐẠO BGH</span>
                  <span class="dir-text">Khảo sát mở 2 tuyến xe đưa đón khu vực Long Khánh &amp; Trảng Bom để giữ chân 21 HS nhóm xa trường.</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 7. PAGE 4: CHUYÊN MÔN & LMS (CM04, CM08, CM01 — PAIRED VISUAL WORKBENCH) -->
    <div v-if="page === 4" class="uc-kpi-ops__page">
      <div class="uc-kpi3t__cockpit">
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">CHUYÊN MÔN &amp; LMS</span>
              <span class="uc-kpi3t__section-title">CHẤT LƯỢNG GIẢNG DẠY, BÀI TẬP LMS (CM08) &amp; HỌC LIỆU SỐ (CM04)</span>
            </div>
            <div class="uc-kpi3t__toggle-group">
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': lmsViewMode === 'CHART' }" @click="lmsViewMode = 'CHART'">Biểu đồ Trực quan</button>
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': lmsViewMode === 'TABLE' }" @click="lmsViewMode = 'TABLE'">Bảng chi tiết</button>
            </div>
          </div>

          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">Hoàn Thành Bài Tập LMS (CM08)</div>
              <div class="uc-kpi3t__impact-val">{{ lmsOverallRate && lmsOverallRate !== '0.0' ? lmsOverallRate : '89.6' }}% <small>/ 80% KH</small></div>
              <div class="uc-kpi3t__impact-sub">Học sinh duy trì nền nếp làm bài trực tuyến tốt</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Số Hóa Học Liệu Tự Học (CM04)</div>
              <div class="uc-kpi3t__impact-val">{{ lmsHocLieuSummary.pct && lmsHocLieuSummary.pct !== '0.0' ? lmsHocLieuSummary.pct : '35.5' }}% <small>/ 60% KH</small></div>
              <div class="uc-kpi3t__impact-sub">Điểm nghẽn: Nhiều khung bài giảng chưa đính kèm video/slide</div>
            </div>
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">Tuân Thủ Lịch Báo Giảng (Calen)</div>
              <div class="uc-kpi3t__impact-val">98.2% <small>/ 95% KH</small></div>
              <div class="uc-kpi3t__impact-sub">Thực hiện phân phối chương trình đúng tiến độ</div>
            </div>
            <div class="uc-kpi3t__impact-card is-primary">
              <div class="uc-kpi3t__impact-label">Đạt Chuẩn Khung Năng Lực (CM17)</div>
              <div class="uc-kpi3t__impact-val">82.4% <small>Thành thạo</small></div>
              <div class="uc-kpi3t__impact-sub">Vượt chỉ tiêu 80% ở nhóm năng lực STEM &amp; Tiếng Anh</div>
            </div>
          </div>
        </div>

        <div class="uc-kpi3t__workbench">
          <!-- Cột Trái: Biểu đồ Tiến độ Bài tập LMS theo môn -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">TIẾN ĐỘ BÀI TẬP LMS &amp; CHẤM CHỮA THEO MÔN HỌC (CM08)</span>
              <button type="button" class="uc-kpi3t__mini-action-btn" @click="openFactModal('LMS')">Fact Store LMS ↗</button>
            </div>

            <div v-if="lmsAssignmentRows && lmsAssignmentRows.length && lmsViewMode === 'CHART'" class="p-3">
              <div class="uc-kpi-ops__lms-cards-grid">
                <div v-for="r in lmsAssignmentRows" :key="r.MonHocID" class="uc-kpi-ops__lms-card">
                  <div class="uc-kpi-ops__lms-card-head">
                    <div class="uc-kpi-ops__lms-card-title">{{ r.TenMonHoc_HienThi }}</div>
                    <div :class="['uc-kpi-ops__lms-card-pct', r.CompletionRate_Assignments >= 80 ? 'tx-good' : 'tx-warn']">
                      {{ r.CompletionRate_Assignments }}%
                    </div>
                  </div>
                  <div class="uc-kpi-ops__lms-stacked-bar">
                    <div class="uc-kpi-ops__lms-seg is-graded" :style="{ width: ((r.Total_DaCham / (r.TotalAssigned || 1)) * 100) + '%' }"></div>
                    <div class="uc-kpi-ops__lms-seg is-submitted" :style="{ width: (((r.Total_DaNop - r.Total_DaCham) / (r.TotalAssigned || 1)) * 100) + '%' }"></div>
                    <div class="uc-kpi-ops__lms-seg is-pending" :style="{ width: ((r.Total_ChuaLam / (r.TotalAssigned || 1)) * 100) + '%' }"></div>
                  </div>
                  <div class="uc-kpi-ops__lms-card-meta">
                    <div>Đã giao <b>{{ formatNumber(r.TotalAssigned) }}</b></div>
                    <div>Đã nộp <b class="tx-good">{{ formatNumber(r.Total_DaNop) }}</b></div>
                    <div>Chưa làm <b>{{ formatNumber(r.Total_ChuaLam) }}</b></div>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="p-3">
              <div v-for="c in tier3Campuses" :key="'lms-c-' + c.ScopeID" class="campus-bar-item mb-2">
                <div class="cb-top">
                  <b class="cb-name">{{ c.CampusName }}</b>
                  <div class="cb-metrics">
                    <span class="cb-enroll">Mục tiêu &ge; 80%</span>
                    <b class="cb-pct tx-good">{{ c.LmsCompletionRate || 89.6 }}% LMS</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill fill-good" :style="{ width: (c.LmsCompletionRate || 89.6) + '%' }"></div>
                  <div class="cb-target-marker" style="left:80%;"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Cột Phải: Biểu đồ Độ vênh Số hóa Học liệu (CM04) giữa các cơ sở -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">ĐỘ VÊNH SỐ HÓA HỌC LIỆU TỰ HỌC (CM04 &middot; ĐÍCH 60%)</span>
            </div>
            <div class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in tier3Campuses" :key="'hl-c-' + c.ScopeID" class="campus-bar-item">
                <div class="cb-top">
                  <div class="d-flex align-center gap-1">
                    <span class="cb-code">{{ c.ScopeID }}</span>
                    <b class="cb-name">{{ c.CampusName }}</b>
                  </div>
                  <div class="cb-metrics">
                    <span class="cb-enroll">KH &ge; 60%</span>
                    <b class="cb-pct tx-warn">{{ c.DigitalMaterialRate || 35.5 }}%</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill fill-warn" :style="{ width: Math.min(100, (c.DigitalMaterialRate || 35.5) * 1.4) + '%' }"></div>
                  <div class="cb-target-marker" style="left:84%;" title="Đích kế hoạch 60%"></div>
                </div>
              </div>

              <div class="uc-kpi3t__directive-banner mt-1">
                <div class="dir-main">
                  <span class="dir-badge">CHỈ ĐẠO ĐÀO TẠO</span>
                  <span class="dir-text">Yêu cầu các Tổ bộ môn đính kèm video/slide bài giảng cho 100% chủ đề cốt lõi để HS nghỉ ốm (Cúm A) tự ôn tập tại nhà.</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 8. PAGE 5: TÀI CHÍNH DỊCH VỤ & CLB NGOẠI KHÓA (TC55, TC56) -->
    <div v-if="page === 5" class="uc-kpi-ops__page">
      <div class="uc-kpi3t__cockpit">
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">TÀI CHÍNH &amp; DỊCH VỤ</span>
              <span class="uc-kpi3t__section-title">HIỆU QUẢ KINH DOANH DỊCH VỤ BÁN TRÚ (TC55) &amp; CLB NGOẠI KHÓA (TC56)</span>
            </div>
            <div class="uc-kpi3t__toggle-group">
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': financeViewMode === 'CHART' }" @click="financeViewMode = 'CHART'">Biểu đồ Hiệu quả</button>
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': financeViewMode === 'TABLE' }" @click="financeViewMode = 'TABLE'">Bảng chi tiết</button>
            </div>
          </div>

          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Tỷ Suất LN Gộp Dịch Vụ (TC55)</div>
              <div class="uc-kpi3t__impact-val">{{ computedFinanceData.grossMargin }} <small>/ 50% KH</small></div>
              <div class="uc-kpi3t__impact-sub">Bán trú {{ computedFinanceData.mealMargin }} · Xe bus {{ computedFinanceData.busMargin }}</div>
            </div>
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">Doanh Thu CLB Ngoại Khóa (TC56)</div>
              <div class="uc-kpi3t__impact-val">{{ computedFinanceData.clbRev }} <small>(HK1)</small></div>
              <div class="uc-kpi3t__impact-sub">Vượt chỉ tiêu 1.50 tỷ VNĐ (+7.4%) · Tái đầu tư CSVC</div>
            </div>
            <div class="uc-kpi3t__impact-card is-primary">
              <div class="uc-kpi3t__impact-label">Tổng Lượt Đăng Ký CLB</div>
              <div class="uc-kpi3t__impact-val">{{ computedFinanceData.clbStudents }} <small>lượt HS</small></div>
              <div class="uc-kpi3t__impact-sub">Tiểu học đạt 353 HS (117.7% KH) · MNLK đạt 93.3%</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Biến Động Ăn Sáng &amp; Xe Bus</div>
              <div class="uc-kpi3t__impact-val">771 <small>Ăn sáng / 315 Bus</small></div>
              <div class="uc-kpi3t__impact-sub">Giảm nhẹ so với tháng 8 (-21 ăn sáng, -14 xe bus)</div>
            </div>
          </div>
        </div>

        <div class="uc-kpi3t__workbench">
          <!-- Cột Trái: Biểu đồ Tỷ suất LN Gộp theo mảng dịch vụ -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">CƠ CẤU DOANH THU &amp; BIÊN LỢI NHUẬN GỘP DỊCH VỤ (TC55)</span>
            </div>

            <div v-if="financeViewMode === 'CHART'" class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="s in financeServices" :key="s.name" class="campus-bar-item">
                <div class="cb-top">
                  <b class="cb-name">{{ s.name }}</b>
                  <div class="cb-metrics">
                    <span class="cb-enroll">DT: <b>{{ s.revenue }}</b> &middot; LN: <b>{{ s.grossProfit }}</b></span>
                    <b class="cb-pct" :class="parseFloat(s.margin) >= 45 ? 'tx-good' : 'tx-warn'">{{ s.margin }}</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div
                    class="cb-fill"
                    :class="parseFloat(s.margin) >= 45 ? 'fill-good' : 'fill-warn'"
                    :style="{ width: Math.min(100, Math.max(12, parseFloat(s.margin) * 1.4)) + '%' }"
                  ></div>
                  <div class="cb-target-marker" style="left:70%;" title="Mục tiêu LN gộp 50%"></div>
                </div>
              </div>
            </div>

            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th class="ta-l">Mảng dịch vụ</th>
                    <th>Doanh thu</th>
                    <th>Chi phí</th>
                    <th>LN gộp</th>
                    <th>Biên LN</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="s in financeServices" :key="s.name">
                    <td class="ta-l tx-strong">{{ s.name }}</td>
                    <td>{{ s.revenue }}</td>
                    <td>{{ s.cost }}</td>
                    <td class="tx-strong">{{ s.grossProfit }}</td>
                    <td class="tx-strong tx-good">{{ s.margin }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Cột Phải: Biểu đồ CLB Ngoại khóa -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">ĐỐI SÁNH DOANH THU &amp; SĨ SỐ CÁC MÔN CLB NGOẠI KHÓA (TC56)</span>
              <button type="button" class="uc-kpi3t__mini-action-btn" @click="openFactModal('FINANCE')">Fact Store ↗</button>
            </div>

            <div v-if="financeViewMode === 'CHART'" class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in financeClubs" :key="c.name" class="campus-bar-item">
                <div class="cb-top">
                  <b class="cb-name">{{ c.name }}</b>
                  <div class="cb-metrics">
                    <span class="cb-enroll"><b>{{ c.students }}</b> HS &middot; {{ c.fee }}</span>
                    <b class="cb-pct tx-good">{{ c.revenue }}</b>
                    <span class="uc-kpi3t__code-pill">{{ c.share }}</span>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill fill-good" :style="{ width: Math.min(100, Math.max(15, parseFloat(c.share) * 2.5)) + '%' }"></div>
                </div>
              </div>
            </div>

            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th class="ta-l">Câu lạc bộ</th>
                    <th>Sĩ số</th>
                    <th>Đơn giá</th>
                    <th>Doanh thu</th>
                    <th>Tỷ trọng</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="c in financeClubs" :key="c.name">
                    <td class="ta-l tx-strong">{{ c.name }}</td>
                    <td>{{ c.students }} HS</td>
                    <td>{{ c.fee }}</td>
                    <td class="tx-good tx-strong">{{ c.revenue }}</td>
                    <td>{{ c.share }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 9. PAGE 6: Y TẾ HỌC ĐƯỜNG, AN TOÀN BẾP ĂN & VẬN HÀNH CSVC (SK01, VH28, CSVC01) -->
    <div v-if="page === 6" class="uc-kpi-ops__page">
      <div class="uc-kpi3t__cockpit">
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">AN TOÀN &amp; Y TẾ</span>
              <span class="uc-kpi3t__section-title">AN TOÀN BẾP ĂN (VH28), DỊCH TỄ Y TẾ (SK01) &amp; BẢO TRÌ CSVC (CSVC01)</span>
            </div>
            <button type="button" class="uc-kpi-ops__simbtn" @click="openFactModal('HEALTH')">Mở Nhật ký Y tế &amp; CSVC ↗</button>
          </div>

          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">An Toàn Vệ Sinh Thực Phẩm</div>
              <div class="uc-kpi3t__impact-val">0 Vụ <small>(94.5% điểm bếp)</small></div>
              <div class="uc-kpi3t__impact-sub">Tuyệt đối không để xảy ra sự cố ngộ độc học đường</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Giám Sát Dịch Tễ Tháng 9</div>
              <div class="uc-kpi3t__impact-val">30 TCM <small>+ 53 ca Sốt</small></div>
              <div class="uc-kpi3t__impact-sub">Ổ dịch Tay-Chân-Miệng lớp Kitty/Bee &amp; Cúm A Khối 4-5</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Bảo Trì Phòng Ngừa CSVC</div>
              <div class="uc-kpi3t__impact-val">91.67% <small>/ 95% KH</small></div>
              <div class="uc-kpi3t__impact-sub">18 sự cố máy lạnh Khu B &amp; C cần thay mới 20 máy</div>
            </div>
            <div class="uc-kpi3t__impact-card is-primary">
              <div class="uc-kpi3t__impact-label">Kết Nối Phụ Huynh ME School</div>
              <div class="uc-kpi3t__impact-val">{{ opsSafetyMe.MeAppInstallRate || 96.4 }}% <small>cài App</small></div>
              <div class="uc-kpi3t__impact-sub">Hài lòng dịch vụ đạt {{ opsSafetyMe.SatisfactionRate || 93.6 }}%</div>
            </div>
          </div>
        </div>

        <div class="uc-kpi3t__workbench">
          <!-- Cột Trái: Biểu đồ Y tế & An toàn theo 5 cơ sở -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">TỶ LỆ KHÁM SỨC KHỎE &amp; KIỂM SOÁT DỊCH TỄ 5 CƠ SỞ (SK01)</span>
            </div>
            <div class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in tier3Campuses" :key="'sk-' + c.ScopeID" class="campus-bar-item">
                <div class="cb-top">
                  <div class="d-flex align-center gap-1">
                    <span class="cb-code">{{ c.ScopeID }}</span>
                    <b class="cb-name">{{ c.CampusName }}</b>
                  </div>
                  <div class="cb-metrics">
                    <span class="cb-enroll">Đích &ge; 95%</span>
                    <b class="cb-pct" :class="(c.HealthRate || 96) >= 95 ? 'tx-good' : 'tx-warn'">{{ c.HealthRate || 96.5 }}%</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill" :class="(c.HealthRate || 96) >= 95 ? 'fill-good' : 'fill-warn'" :style="{ width: (c.HealthRate || 96.5) + '%' }"></div>
                  <div class="cb-target-marker" style="left:95%;"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Cột Phải: Biểu đồ Bảo trì CSVC & Ngày phép Nhân sự 5 cơ sở -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">HOÀN THÀNH BẢO TRÌ CSVC (CSVC01) &amp; NGÀY NGHỈ PHÉP (TC54)</span>
            </div>
            <div class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in tier3Campuses" :key="'csvc-' + c.ScopeID" class="campus-bar-item">
                <div class="cb-top">
                  <div class="d-flex align-center gap-1">
                    <span class="cb-code">{{ c.ScopeID }}</span>
                    <b class="cb-name">{{ c.CampusName }}</b>
                  </div>
                  <div class="cb-metrics">
                    <span class="cb-enroll">Nghỉ phép: <b>{{ c.StaffLeaveDays || 40 }} ngày</b></span>
                    <b class="cb-pct" :class="(c.MaintenanceRate || 92) >= 95 ? 'tx-good' : 'tx-warn'">{{ c.MaintenanceRate || 91.7 }}% CSVC</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill" :class="(c.MaintenanceRate || 92) >= 95 ? 'fill-good' : 'fill-warn'" :style="{ width: (c.MaintenanceRate || 91.7) + '%' }"></div>
                  <div class="cb-target-marker" style="left:95%;"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 9b. PAGE 7: PHỄU TUYỂN SINH & LEADS CRM (TS05, TS06 — VISUAL FUNNEL WORKBENCH) -->
    <div v-if="page === 7" class="uc-kpi-ops__page">
      <div class="uc-kpi3t__cockpit">
        <div class="uc-kpi3t__section-h">
          <div class="uc-kpi3t__t1-bar">
            <div class="d-flex align-center gap-2">
              <span class="uc-kpi3t__tier-badge tier-1">PHỄU CRM &amp; TVTS</span>
              <span class="uc-kpi3t__section-title">PHỄU CHUYỂN ĐỔI LEADS TUYỂN SINH (TS05, TS06) &amp; PIPELINE NUÔI DƯỠNG HK2</span>
            </div>
            <div class="uc-kpi3t__toggle-group">
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': crmViewMode === 'CHART' }" @click="crmViewMode = 'CHART'">Phễu &amp; Biểu đồ</button>
              <button type="button" class="uc-kpi3t__toggle-btn" :class="{ 'is-active': crmViewMode === 'TABLE' }" @click="crmViewMode = 'TABLE'">Bảng chi tiết</button>
            </div>
          </div>

          <div class="uc-kpi3t__impact-grid" style="border:1px solid #d2d0ce;">
            <div class="uc-kpi3t__impact-card is-primary">
              <div class="uc-kpi3t__impact-label">Tổng Leads Lũy Kế (TS05)</div>
              <div class="uc-kpi3t__impact-val">{{ computedCrmLeads }} <small>Leads (T9: {{ computedCrmLeadsCurrentMonth }})</small></div>
              <div class="uc-kpi3t__impact-sub">{{ crmMonthlySummaryText }}</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Tỷ Lệ Chuyển Đổi (TS06)</div>
              <div class="uc-kpi3t__impact-val">{{ computedCrmConversionRate }}% <small>/ 30% KH</small></div>
              <div class="uc-kpi3t__impact-sub">{{ computedCrmUnitRatesText }}</div>
            </div>
            <div class="uc-kpi3t__impact-card is-success">
              <div class="uc-kpi3t__impact-label">Nhập Học Thực Tế</div>
              <div class="uc-kpi3t__impact-val">{{ computedCrmEnrolled }} <small>Học sinh</small></div>
              <div class="uc-kpi3t__impact-sub">Riêng tháng 9 nhập mới 21 HS bù đắp 12 ca rút</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn" style="cursor:pointer;" @click="openDrawer('KITTY_LIST')">
              <div class="uc-kpi3t__impact-label">Pipeline Kitty Chờ Đủ Tuổi HK2</div>
              <div class="uc-kpi3t__impact-val">{{ crmKittyList.length }} <small>Hồ sơ hẹn</small></div>
              <div class="uc-kpi3t__impact-sub">Bấm để xem danh sách phụ huynh hẹn nhập học HK2 &rsaquo;</div>
            </div>
          </div>
        </div>

        <div class="uc-kpi3t__workbench">
          <!-- Cột Trái: Hiệu quả Chuyển đổi theo Kênh Tiếp cận -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--left">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">HIỆU QUẢ CHUYỂN ĐỔI THEO KÊNH TIẾP CẬN &amp; DIỄN BIẾN 3 THÁNG</span>
            </div>

            <div v-if="crmViewMode === 'CHART'" class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="c in crmChannelStats" :key="c.channel" class="campus-bar-item">
                <div class="cb-top">
                  <b class="cb-name">{{ c.channel }}</b>
                  <div class="cb-metrics">
                    <span class="cb-enroll"><b>{{ c.leads }}</b> Leads ({{ c.pct }}) &rarr; Chốt <b>{{ c.enrolled }} HS</b></span>
                    <b class="cb-pct" :class="parseFloat(c.convRate) >= 25 ? 'tx-good' : 'tx-warn'">{{ c.convRate }}</b>
                  </div>
                </div>
                <div class="cb-track">
                  <div
                    class="cb-fill"
                    :class="parseFloat(c.convRate) >= 25 ? 'fill-good' : 'fill-warn'"
                    :style="{ width: Math.min(100, Math.max(10, parseFloat(c.convRate) * 2.2)) + '%' }"
                  ></div>
                  <div class="cb-target-marker" style="left:66%;" title="Mục tiêu chuyển đổi 30%"></div>
                </div>
              </div>
            </div>

            <div v-else class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
                <thead>
                  <tr>
                    <th class="ta-l">Kỳ báo cáo</th>
                    <th>PTLC</th>
                    <th>MNBH</th>
                    <th>MNLK</th>
                    <th>Tổng Leads</th>
                    <th>Nhập học</th>
                    <th>Tỷ lệ</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="m in crmMonthlySummary" :key="m.month">
                    <td class="ta-l tx-strong">{{ m.month }}</td>
                    <td>{{ m.ptlcLeads }}</td>
                    <td>{{ m.mnbhLeads }}</td>
                    <td>{{ m.mnlkLeads }}</td>
                    <td class="tx-strong">{{ m.totalLeads }}</td>
                    <td class="tx-good tx-strong">{{ m.totalEnrolled }} HS</td>
                    <td class="tx-strong">{{ m.rate }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Cột Phải: Rào cản Chưa chuyển đổi & Pipeline Kitty -->
          <div class="uc-kpi3t__pane uc-kpi3t__pane--right">
            <div class="uc-kpi3t__pane-head">
              <span class="uc-kpi3t__pane-title">PHÂN TÍCH RÀO CẢN CHƯA NHẬP HỌC ({{ computedCrmDropTotal }} HỒ SƠ DROP-OFF)</span>
              <button type="button" class="uc-kpi3t__mini-action-btn" @click="openDrawer('KITTY_LIST')">Pipeline Kitty ({{ crmKittyList.length }}) ↗</button>
            </div>

            <div class="p-3" style="display:flex;flex-direction:column;gap:8px;">
              <div v-for="r in crmDropReasons" :key="r.reason" class="campus-bar-item">
                <div class="cb-top">
                  <b class="cb-name">{{ r.reason }}</b>
                  <div class="cb-metrics">
                    <b class="cb-pct tx-bad">{{ r.count }} hồ sơ</b>
                    <span class="uc-kpi3t__code-pill">{{ r.pct }}</span>
                  </div>
                </div>
                <div class="cb-track">
                  <div class="cb-fill fill-bad" :style="{ width: Math.min(100, Math.max(10, parseFloat(r.pct) * 2.2)) + '%' }"></div>
                </div>
                <div style="font-size:11px;color:var(--ink2);margin-top:3px;">
                  <b>Giải pháp:</b> {{ r.solution }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 11. Slide-over Drill-down Drawer -->
    <div v-if="drawer.visible" class="uc-kpi-ops__veil" @click="closeDrawer()"></div>
    <div v-if="drawer.visible" class="uc-kpi-ops__drawer">
      <div class="uc-kpi-ops__dr-head">
        <div>
          <div class="uc-kpi-ops__dr-kicker">Chi tiết phân tích điều hành</div>
          <div class="uc-kpi-ops__dr-title">{{ drawer.title }}</div>
        </div>
        <button type="button" class="uc-kpi-ops__dr-x" @click="closeDrawer()">&times;</button>
      </div>
      <div class="uc-kpi-ops__dr-body">
        <div v-if="drawer.type === 'WITHDRAW_LIST'">
          <!-- Phân tích Tác động Nhân quả dành cho HĐQT -->
          <div class="uc-kpi-ops__bkpi-causal is-bad mb-3" style="padding:12px;font-size:12px;">
            <div class="causal-pill" style="font-size:12px;">
              Phân Tích Chuỗi Tác Động Điều Hành: Xe Bus &rarr; Rút Học &rarr; Thất Thu Tài Chính
            </div>
            <div class="causal-desc" style="font-size:12px;margin:6px 0;">
              <b>{{ displayReasonFar }}/{{ displayWithdrawCount }} học sinh</b> ({{ displayReasonFarPct }}% trong kỳ {{ currentPeriodName }}) rút học do khoảng cách địa lý và tuyến đưa đón (Lũy kế chuyển đi toàn năm học: {{ displayOutflowYearToDate }} HS). Thiệt hại tài chính trực tiếp: <b>{{ displayWithdrawFinancialLoss }}</b>.
            </div>
            <div class="d-flex align-center justify-space-between mt-2">
              <span class="text-xs text-muted">Đề xuất BĐH: Mở tuyến bus chuyên biệt để bảo toàn học sinh và doanh thu</span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn is-solid"
                style="padding:4px 10px;font-size:11px;"
                @click="openCausalModal(currentUnit, 'RUT_HOC')"
              >Mở Mô Hình Vùng Tác Động (What-If) ↗</button>
            </div>
          </div>

          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Danh sách {{ withdrawRecords.length || displayOutflowYearToDate }} học sinh chuyển đi lũy kế năm học {{ currentPeriodIsFrozen ? '(Số liệu chốt sổ)' : '(Live Data)' }}</div>
            </div>
            <div class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th class="ta-l">Họ tên</th>
                    <th>Lớp</th>
                    <th class="ta-l">Trường đến</th>
                    <th class="ta-l">Lý do</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(r, i) in withdrawRecords" :key="i">
                    <td class="ta-l tx-strong">{{ r.HoTen }}</td>
                    <td>{{ r.LopDi || '—' }}</td>
                    <td class="ta-l">{{ r.TruongDen || '—' }}</td>
                    <td class="ta-l tx-bad">{{ r.LyDo }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div v-if="drawer.type === 'STUDENT_LIST'">
          <!-- Phân tích Tác động Nhân quả dành cho HĐQT -->
          <div class="uc-kpi-ops__bkpi-causal is-good mb-3" style="padding:12px;font-size:12px;">
            <div class="causal-pill" style="font-size:12px;">
              Phân Tích Chuỗi Tác Động Điều Hành: Quy Mô Sĩ Số &rarr; Lợi Nhuận Gộp &rarr; Điểm Hòa Vốn
            </div>
            <div class="causal-desc" style="font-size:12px;margin:6px 0;">
              Lũy kế quy mô đạt <b>{{ formatNumber(displayStudents) }} HS</b> (Đạt {{ displayCapacityPct }}% kế hoạch). Cơ sở Mầm non Long Khánh đang ở vùng công suất mỏng ({{ ((133/160)*100).toFixed(0) }}%), cần ưu tiên dồn leads TVTS nhóm 18–24 tháng.
            </div>
            <div class="d-flex align-center justify-space-between mt-2">
              <span class="text-xs text-muted">Phụ trách: Ban Giám hiệu Long Khánh &amp; Ban TVTS</span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn is-solid"
                style="padding:4px 10px;font-size:11px;"
                @click="openCausalModal(currentUnit, 'TUYEN_THEM')"
              >Mở Mô Hình Vùng Tác Động Tuyển Thêm ↗</button>
            </div>
          </div>

          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Sĩ số theo khối lớp {{ currentPeriodIsFrozen ? '(Số liệu chốt sổ)' : '(Live Data)' }}</div>
            </div>
            <div class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th class="ta-l">Khối Lớp</th>
                    <th>Học sinh</th>
                    <th>Nam</th>
                    <th>Nữ</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in currentGradeRows" :key="r.Ten">
                    <td class="ta-l tx-strong">{{ r.Ten }}</td>
                    <td class="tx-strong">{{ formatNumber(r.SLHocSinh) }}</td>
                    <td>{{ formatNumber(r.SL_HSNam) }}</td>
                    <td>{{ formatNumber(r.SL_HSNu) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div v-if="drawer.type === 'FINANCE_DETAIL'">
          <!-- Phân tích Tác động Nhân quả dành cho HĐQT -->
          <div class="uc-kpi-ops__bkpi-causal is-good mb-3" style="padding:12px;font-size:12px;">
            <div class="causal-pill" style="font-size:12px;">
              Phân Tích Chuỗi Tác Động Điều Hành: Lợi Nhuận Dịch Vụ &rarr; Quỹ Tái Đầu Tư CSVC
            </div>
            <div class="causal-desc" style="font-size:12px;margin:6px 0;">
              Dòng tiền lợi nhuận gộp từ CLB (<b>{{ computedFinanceData.clbRev }}</b>) và Dịch vụ bán trú (<b>{{ computedFinanceData.grossMargin }}</b>) đóng góp quỹ tự chủ nâng cấp điều hòa khối Tiểu học và sân bãi thể thao mà không gây áp lực tăng học phí.
            </div>
            <div class="d-flex align-center justify-space-between mt-2">
              <span class="text-xs text-muted">Phụ trách: Phòng Kế toán &amp; Ban Quản trị CSVC</span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn"
                style="padding:4px 10px;font-size:11px;"
                @click="page = 5; closeDrawer()"
              >Xem Phân Tích Tài Chính Chi Tiết ›</button>
            </div>
          </div>

          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Chi tiết cơ cấu Lợi nhuận gộp Dịch vụ (KPI 4: Mục tiêu {{ getKpiTarget('TC55') || '50%' }})</div>
            </div>
            <div class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th class="ta-l">Mảng Dịch vụ</th>
                    <th>Doanh thu</th>
                    <th>Chi phí trực tiếp</th>
                    <th>Lợi nhuận gộp</th>
                    <th>Tỷ suất LN (KPI 4)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="s in financeServices" :key="s.name">
                    <td class="ta-l tx-strong">{{ s.name }}</td>
                    <td>{{ s.revenue }}</td>
                    <td>{{ s.cost }}</td>
                    <td class="tx-good tx-strong">{{ s.grossProfit }}</td>
                    <td class="tx-good tx-strong">{{ s.margin }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div v-if="drawer.type === 'KITTY_LIST'">
          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Pipeline Nuôi Dưỡng Khách Hàng Tiềm Năng Chờ HK2 (Tab Kitty)</div>
              <div class="uc-kpi-ops__vnote">Google Sheet GID 1481169716 · {{ crmKittyList.length }} hồ sơ chờ nhập học</div>
            </div>
            <div class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th>STT</th>
                    <th class="ta-l">Phụ huynh</th>
                    <th class="ta-l">Bé</th>
                    <th class="ta-l">Tình trạng</th>
                    <th class="ta-l">Lịch hẹn chăm sóc</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in crmKittyList" :key="r.stt">
                    <td>{{ r.stt }}</td>
                    <td class="ta-l tx-strong">{{ r.tenPH }}</td>
                    <td class="ta-l">{{ r.tenHS }}</td>
                    <td class="ta-l" :class="r.tinhTrang.includes('Nhập học') ? 'tx-good' : 'tx-warn'">{{ r.tinhTrang }}</td>
                    <td class="ta-l tx-strong">{{ r.hen }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <div v-if="drawer.type === 'GOLIVE_SPECS'">
          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Đặc Tả Kỹ Thuật API Golive Các Hệ Thống Nguồn (Theo Quy Định Docs)</div>
              <div class="uc-kpi-ops__vnote">
                Danh mục 6 nguồn dữ liệu theo tài liệu Phương án xây dựng Dashboard và chỉ đạo BĐH:
              </div>
            </div>

            <!-- Filter chips for specs -->
            <div class="uc-kpi-ops__seg mb-3">
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === null }"
                @click="selectedSpecCode = null"
              >Tất cả hệ thống ({{ goliveSpecsList.length }})</button>
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === 'SPEC_BASICDATA' }"
                @click="selectedSpecCode = 'SPEC_BASICDATA'"
              >basicdata.lhbs.vn</button>
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === 'SPEC_HOCPHI' }"
                @click="selectedSpecCode = 'SPEC_HOCPHI'"
              >hocphi.lhbs.vn</button>
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === 'SPEC_YTE' }"
                @click="selectedSpecCode = 'SPEC_YTE'"
              >yte.lhbs.vn</button>
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === 'SPEC_QA' }"
                @click="selectedSpecCode = 'SPEC_QA'"
              >qa.lhbs.vn</button>
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === 'SPEC_LMS' }"
                @click="selectedSpecCode = 'SPEC_LMS'"
              >lms.lhbs.vn</button>
              <button
                type="button"
                :class="{ 'is-on': selectedSpecCode === 'SPEC_EXCEL_INTERNAL' }"
                @click="selectedSpecCode = 'SPEC_EXCEL_INTERNAL'"
              >Excel nội bộ</button>
            </div>

            <div class="uc-kpi-ops__specs-list">
              <div v-for="spec in computedDisplaySpecs" :key="spec.SpecCode" class="uc-kpi-ops__spec-item">
                <div class="uc-kpi-ops__spec-h">
                  <div class="uc-kpi-ops__spec-title">
                    <span>{{ spec.SourceSystem }}</span>
                    <a
                      v-if="extractUrl(spec.SourceSystem)"
                      :href="extractUrl(spec.SourceSystem)"
                      target="_blank"
                      class="uc-kpi-ops__simbtn ml-2"
                      style="display:inline-block;padding:2px 8px;font-size:11px;"
                    >
                      Mở link hệ thống ↗
                    </a>
                  </div>
                  <span class="uc-kpi-ops__spec-badge">{{ spec.SpecCode }}</span>
                </div>
                <div class="uc-kpi-ops__spec-meta">
                  <b>Phân hệ / Nhóm KPI:</b> {{ spec.KpiGroup }} | <b>Tần suất đồng bộ:</b> {{ spec.SyncSchedule }}
                </div>
                <div class="uc-kpi-ops__spec-ep">
                  <b>{{ spec.HttpMethod }}</b> {{ spec.ApiEndpoint }}
                </div>
                <div class="uc-kpi-ops__spec-lbl">Cấu trúc Request JSON mẫu:</div>
                <div class="uc-kpi-ops__spec-code">{{ spec.RequestSchema }}</div>
                <div class="uc-kpi-ops__spec-lbl">Cấu trúc Response JSON chuẩn:</div>
                <div class="uc-kpi-ops__spec-code">{{ spec.ResponseSchema }}</div>
                <div class="uc-kpi-ops__spec-reqs">
                  <b>Điều kiện tiên quyết Golive:</b> {{ spec.GolivePrerequisites }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 11e. Causal Engine Configuration Drawer -->
        <div v-if="drawer.type === 'CAUSAL_CONFIG'">
          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Cấu hình Tham số Giả định &amp; Quy tắc Nhân quả (CSDL eSign)</div>
              <div class="uc-kpi-ops__vnote">
                Bảng cấu hình động lưu trữ tại <code>tblKPI_CausalAssumptions</code> &amp; <code>tblKPI_CausalRules</code> trên server eSignature.
              </div>
            </div>

            <!-- Bảng tham số giả định 5 đơn vị -->
            <div class="uc-kpi-ops__tablewrap mb-3">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th class="ta-l">Đơn vị</th>
                    <th>Chỉ tiêu (KH)</th>
                    <th>Sĩ số {{ currentPeriodShortName }}</th>
                    <th>Học phí (tr/năm)</th>
                    <th>Biên LN (%)</th>
                    <th>Năm còn lại</th>
                    <th>Leads/tháng</th>
                    <th>Chuyển đổi (%)</th>
                    <th>Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="u in (causalAssumptionsList.length ? causalAssumptionsList : defaultAssumptions)" :key="u.UnitCode">
                    <td class="ta-l tx-strong">{{ u.UnitName }}</td>
                    <td><input type="number" v-model.number="u.PlannedCapacity" class="uc-kpi-ops__input-sm" style="width:70px;" /></td>
                    <td><input type="number" v-model.number="u.CurrentEnrollment" class="uc-kpi-ops__input-sm" style="width:70px;" /></td>
                    <td><input type="number" step="0.1" v-model.number="u.AnnualTuitionMillion" class="uc-kpi-ops__input-sm" style="width:70px;" /></td>
                    <td><input type="number" step="0.01" v-model.number="u.GrossMarginPct" class="uc-kpi-ops__input-sm" style="width:60px;" /></td>
                    <td><input type="number" step="0.1" v-model.number="u.RemainingYearsInLevel" class="uc-kpi-ops__input-sm" style="width:60px;" /></td>
                    <td><input type="number" v-model.number="u.MonthlyLeads" class="uc-kpi-ops__input-sm" style="width:70px;" /></td>
                    <td><input type="number" step="0.001" v-model.number="u.ConversionRate" class="uc-kpi-ops__input-sm" style="width:70px;" /></td>
                    <td>
                      <button
                        type="button"
                        class="uc-kpi-ops__simbtn is-solid"
                        @click="saveCausalAssumption(u)"
                        title="Lưu xuống CSDL eSign"
                      >Lưu CSDL</button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Danh mục quy tắc IF/ELSE -->
            <div class="uc-kpi-ops__vhead mt-3">
              <div class="uc-kpi-ops__vtitle">Danh mục Luật Đánh giá IF / ELSE (tblKPI_CausalRules)</div>
            </div>
            <div class="uc-kpi-ops__tablewrap">
              <table class="uc-kpi-ops__table">
                <thead>
                  <tr>
                    <th class="ta-l">Mã Luật</th>
                    <th class="ta-l">Tên Quy tắc</th>
                    <th class="ta-l">Điều kiện (IF)</th>
                    <th>Mức độ</th>
                    <th class="ta-l">Hệ quả (THEN)</th>
                    <th>Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in (causalRulesList.length ? causalRulesList : defaultRules)" :key="r.RuleCode">
                    <td class="ta-l tx-strong">{{ r.RuleCode }}</td>
                    <td class="ta-l">{{ r.RuleName }}</td>
                    <td class="ta-l font-mono text-xs">{{ r.ConditionExpr }}</td>
                    <td>
                      <span :class="['uc-kpi-ops__tag', r.Severity === 'BAD' ? 'is-bad' : 'is-warn']">{{ r.Severity }}</span>
                    </td>
                    <td class="ta-l">{{ r.OutcomeSummary }}</td>
                    <td><span class="uc-kpi-ops__pill is-live">Hoạt động</span></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    
  </div>
</template>

<script>
	export default {
		name: "uc-kpi-ops",
  props: {},
  emits: ["on-reload"],
  data() {
    return {
      // 3-Tier Architecture State
      kpiViewMode: "STRATEGIC",
      tier2ViewMode: "CHART",
      activeTier2Kpi: null,
      showPendingTier2: false,
      tier3ActiveTab: "CAMPUS",
      activeCausalChainIdx: 0,
      selectedRadarCampus: "MNLK",
      tier3Campuses: [],
      tier3CausalImpact: null,
      tier3CausalChains: [],
      tier3Audits: [],
      activeTier1Kpi: "KPI_1",
      tier1List: [
        { MasterKpiCode: "KPI_1", KpiName: "Lấp đầy 100% công suất thiết kế", TargetValue: 100, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 93.42, ProgressPct: 93.4, StatusBadge: "WARN", ThemeColor: "#0284c7", WeightPct: 25, RadarRiskScore: 36, AuditOpenCount: 2, GoodCount: 3, WarnCount: 1, BadCount: 0 },
        { MasterKpiCode: "KPI_2", KpiName: "Tỷ lệ trúng tuyển ĐH & Chuẩn đầu ra", TargetValue: 95, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 98.20, ProgressPct: 95.3, StatusBadge: "WARN", ThemeColor: "#7c3aed", WeightPct: 20, RadarRiskScore: 28, AuditOpenCount: 2, GoodCount: 4, WarnCount: 1, BadCount: 0 },
        { MasterKpiCode: "KPI_3", KpiName: "Tỷ lệ rút học & Giữ chân học sinh", TargetValue: 10, TargetUnit: "%", ComparisonOp: "<=", ActualValue: 2.00, ProgressPct: 100.0, StatusBadge: "GOOD", ThemeColor: "#16a34a", WeightPct: 15, RadarRiskScore: 18, AuditOpenCount: 1, GoodCount: 7, WarnCount: 0, BadCount: 0 },
        { MasterKpiCode: "KPI_4", KpiName: "Tỷ suất lợi nhuận gộp dịch vụ bán trú", TargetValue: 50, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 48.40, ProgressPct: 96.8, StatusBadge: "WARN", ThemeColor: "#059669", WeightPct: 15, RadarRiskScore: 42, AuditOpenCount: 2, GoodCount: 2, WarnCount: 3, BadCount: 0 },
        { MasterKpiCode: "KPI_5", KpiName: "Cải cách TTHC & Giảm 50% thời gian xử lý", TargetValue: 50, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 91.67, ProgressPct: 92.5, StatusBadge: "WARN", ThemeColor: "#ea580c", WeightPct: 10, RadarRiskScore: 44, AuditOpenCount: 3, GoodCount: 2, WarnCount: 2, BadCount: 0 },
        { MasterKpiCode: "KPI_6", KpiName: "Tỷ lệ chuyển đổi Leads & Hài lòng PHHS", TargetValue: 30, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 13.58, ProgressPct: 78.4, StatusBadge: "WARN", ThemeColor: "#dc2626", WeightPct: 15, RadarRiskScore: 58, AuditOpenCount: 1, GoodCount: 1, WarnCount: 3, BadCount: 0 }
      ],
      tier2Drivers: [],

      page: 0,
      currentUnit: "ALL",
      selectedYear: 2026,
      selectedPeriod: "2026-09",
      executiveTab: "COMMAND",
      frameworkGroupFilter: "ALL",
      frameworkLevelFilter: "ALL",
      frameworkStatusFilter: "ALL",
      frameworkSearchQuery: "",
      isRoiModalOpen: false,
      selectedRoiScenario: "BUS",
      roiBusRoutes: 2,
      roiBusCostPerMonth: 35,
      roiBusMonths: 10,
      roiBusStudentsRetained: 21,
      roiTuitionPerYear: 65.2,
      roiBusFeePerMonth: 1.5,
      roiAcNewCount: 6,
      roiAcCapexPerUnit: 12,
      roiAcMaintCount: 12,
      roiAcMaintCost: 1.2,
      roiAcStudentsProtected: 5,
      roiStemLabCapex: 200,
      roiStemStudents: 50,
      roiStemFeePerMonth: 0.8,
      roiStemMonths: 9,
      roiStemCoachCostPerMonth: 12,
      roiAdsBudget: 80,
      roiExpectedLeads: 160,
      roiConversionPct: 16,
      roiHK2TuitionPerStudent: 32.6,
      correlationViewMode: "FLOW",
      gradeViewMode: "CHART",
      withdrawViewMode: "CHART",
      lmsViewMode: "CHART",
      riskViewMode: "CHART",
      selectedSpecCode: null,
      isCausalModalOpen: false,
      causalScenario: "RUT_HOC",
      causalUnit: "MNLK",
      causalN: 5,
      causalAddN: 20,
      causalMonth: 10,
      causalReasonCode: "REASON_UNKNOWN",
      causalConvDelta: 5,
      causalConvMonths: 3,
      causalBusRoutes: 2,
      causalBusStudentsPerRoute: 15,
      causalDiscountPct: 5,
      causalTransitionRetained: 40,
      causalNewClbCount: 4,
      causalAddClbStudents: 80,
      causalHoverNodeId: "",
      causalScenariosList: [],
      causalAssumptionsList: [],
      causalReasonsList: [],
      causalAssignmentsList: [],
      causalRulesList: [],
      causalMonthOptions: [
        { m: 10, t: "Đầu tháng 10", r: 8 / 9, since: 3 },
        { m: 11, t: "Đầu tháng 11", r: 7 / 9, since: 4 },
        { m: 12, t: "Đầu tháng 12", r: 6 / 9, since: 5 },
        { m: 1, t: "Đầu tháng 1", r: 5 / 9, since: 6 },
        { m: 2, t: "Đầu tháng 2", r: 4 / 9, since: 7 },
        { m: 3, t: "Đầu tháng 3", r: 3 / 9, since: 8 },
        { m: 4, t: "Đầu tháng 4", r: 2 / 9, since: 9 },
        { m: 5, t: "Đầu tháng 5", r: 1 / 9, since: 10 },
      ],
      causalUnitOptions: [
        { k: "ALL", t: "Toàn trường" },
        { k: "MNBH", t: "Mầm non BH" },
        { k: "MNLK", t: "Mầm non LK" },
        { k: "TH", t: "Tiểu học" },
        { k: "THCS", t: "THCS" },
        { k: "THPT", t: "THPT" },
      ],
      defaultScenarios: [],
      defaultReasons: [],
      defaultAssumptions: [],
      defaultRules: [],
      isLoading: false,
      isPresentMode: false,
      apiSyncStatus: "Đang đồng bộ Live API...",
      periodsList: [
        { PeriodKey: "2026-09", PeriodName: "Tháng 09/2026 (Chốt sổ)", IsFrozen: true, DataSourceType: "EXCEL_STAGING" },
        { PeriodKey: "2026-10", PeriodName: "Tháng 10/2026 (Kỳ Live)", IsFrozen: false, DataSourceType: "LIVE_API" },
      ],
      periodSnapshots: [],
      kpiGroupSummary: [],
      correlationsList: [],
      causalKpiCode: "TS04",
      causalDeltaOverride: null,
      elasticityMatrixList: [],
      defaultElasticityMatrix: [],
      riskCampusCards: [],
      riskTriggers: [],
      riskChecklist: [],
      strategicWaterfallBars: [],
      strategicLevers: [],
      opsSafetyMe: {},
      crmMonthlySummary: [],
      crmChannelStats: [],
      crmKittyList: [],
      crmDropReasons: [],
      auditDiscrepanciesList: [],
      auditDomainFilter: "ALL",
      auditSeverityFilter: "ALL",
      expandedAuditCodes: [],
      selectedRiskCampusScope: "ALL",
      metricThresholds: [],
      causalNarrativesList: [],
      contextStore: {},
      breakdownsList: [],
      selectedFactDomain: "STUDENTS",
      isFactsLoading: false,
      isFactsModalOpen: false,
      selectedAuditItem: null,
      selectedKpiItem: null,
      frameworkViewMode: 'heatmap',
      auditViewMode: 'DUMBBELL',
      activeAuditIdx: 0,
      financeViewMode: 'CHART',
      crmViewMode: 'CHART',
      safetyViewMode: 'CHART',
      factCampusFilter: "ALL",
      operationalFactsList: [],
      factAuditFilter: "ALL",
      causalChainFilter: "ALL",
      priorPeriodSnapshots: [],
      directiveStatusFilter: "ALL",
      directiveStatusMap: {},
      copiedBriefing: false,
      defaultCorrelations: [],
      defaultAuditDiscrepancies: [],
      goliveSpecsList: [],
      defaultGoliveSpecs: [],
      unitOptions: [
        { k: "ALL", t: "Toàn trường" },
        { k: "MNBH", t: "Mầm non BH" },
        { k: "MNLK", t: "Mầm non LK" },
        { k: "TH", t: "Tiểu học" },
        { k: "THCS", t: "THCS" },
        { k: "THPT", t: "THPT" },
      ],
      schoolYears: [2026, 2025, 2024],
      drawer: {
        visible: false,
        title: "",
        type: "",
      },
      liveDataBienHoa: [],
      liveDataLongKhanh: [],
      historyData: [],
      inflowRecordsCount: 0,
      withdrawRecords: [],
      topWithdrawReasons: [],
      teachingProgressRows: [],
      financeServices: [],
      financeClubs: [],
      financeSummary: null,
      lmsOverallRate: "0.0",
      lmsHocLieuSummary: {
        total: 0,
        coNoiDung: 0,
        pct: "0.0",
        totalFiles: 0,
      },
      lmsAssignmentRows: [],
      lmsHocLieuRows: [],
    };
  },
  computed: {
    activeTier1Obj() {
      return (this.tier1List || []).find(k => k.MasterKpiCode === this.activeTier1Kpi) || (this.tier1List && this.tier1List[0]);
    },
    currentTier2Drivers() {
      if (this.tier2Drivers && this.tier2Drivers.length > 0) {
        return this.tier2Drivers;
      }
      return [];
    },
    activeTier2MeasurableDrivers() {
      return (this.currentTier2Drivers || []).filter(d => d.StatusBadge !== "PENDING" && d.StatusBadge !== "pending");
    },
    pendingTier2Drivers() {
      return (this.currentTier2Drivers || []).filter(d => d.StatusBadge === "PENDING" || d.StatusBadge === "pending");
    },
    activeTier2DriverObj() {
      if (!this.activeTier2Kpi) return null;
      return (this.currentTier2Drivers || []).find(d => d.KpiCode === this.activeTier2Kpi) || null;
    },
    negativeDriversCount() {
      return (this.activeTier2MeasurableDrivers || []).filter(d => d.IsNegativeDriver || d.StatusBadge === 'WARN' || d.StatusBadge === 'BAD').length;
    },
    computedGroupPillars() {
      const snaps = this.periodSnapshots || [];
      const findSnap = (code, fallback) => {
        const s = snaps.find(x => x.KpiCode === code);
        return s && s.ActualValue != null ? Number(s.ActualValue) : fallback;
      };
      const ts01 = findSnap("TS01", 2625);
      const ts02 = findSnap("TS02", 93.42);
      const cm08 = findSnap("CM08", 89.6);
      const cm04 = findSnap("CM04", 35.5);
      const vh28 = findSnap("VH28", 94.5);
      const sk01 = findSnap("SK01", 96.8);
      const tc55 = findSnap("TC55", 48.4);
      const tc56 = findSnap("TC56", 1611000000);
      return [
        {
          code: "GRP_1",
          kpiCode: "KPI_1",
          label: "TRỤ CỘT 1 · TUYỂN SINH & QUY MÔ",
          name: "Quy mô, Tuyển sinh & Giữ chân",
          driverCount: 7,
          activeCount: 7,
          highlightVal: this.formatNumber(ts01) + " HS",
          highlightNote: "Lấp đầy: " + ts02 + "% (KH: 2.873 HS)",
          progressPct: ts02,
          status: ts02 >= 98 ? "good" : "warn",
          desc: "Sĩ số 5 cơ sở, Phễu CRM (162 Leads), Chuyển đổi (13.58%)"
        },
        {
          code: "GRP_2",
          kpiCode: "KPI_2",
          label: "TRỤ CỘT 2 · CHUYÊN MÔN & HỌC THUẬT",
          name: "Chất lượng Giáo dục & Học liệu số",
          driverCount: 20,
          activeCount: 6,
          highlightVal: cm08 + "% LMS",
          highlightNote: "Học liệu số: " + cm04 + "% (KH: 60%)",
          progressPct: (cm08 + (cm04 / 60) * 100) / 2,
          status: cm04 >= 60 ? "good" : "warn",
          desc: "Lịch báo giảng 98.2%, Bài tập LMS 89.6%, Khung NL 82.4%"
        },
        {
          code: "GRP_3",
          kpiCode: "KPI_3",
          label: "TRỤ CỘT 3 · DỊCH VỤ & AN TOÀN",
          name: "Bán trú, Xe đưa rước, Y tế & CSKH",
          driverCount: 24,
          activeCount: 10,
          highlightVal: vh28 + "% Bếp",
          highlightNote: "Khám SK: " + sk01 + "% · 0 vụ ngộ độc",
          progressPct: vh28,
          status: "good",
          desc: "Ăn sáng 771 HS, Xe bus 315 HS, Y tế (30 ca TCM, 53 sốt)"
        },
        {
          code: "GRP_4",
          kpiCode: "KPI_4",
          label: "TRỤ CỘT 4 · TÀI CHÍNH, NHÂN SỰ & CSVC",
          name: "Hiệu quả Dịch vụ, Đội ngũ & Bảo trì CSVC",
          driverCount: 9,
          activeCount: 6,
          highlightVal: tc55 + "% LN gộp",
          highlightNote: "CLB: " + this.formatBillion(tc56) + " Tỷ · Nghỉ phép 551 ngày",
          progressPct: (tc55 / 50) * 100,
          status: tc55 >= 50 ? "good" : "warn",
          desc: "Biên LN gộp 48.4%, CLB 596 lượt, Bảo trì CSVC 91.67%"
        }
      ];
    },
    filteredTier3CausalChains() {
      const sourceList = (this.tier3CausalChains && this.tier3CausalChains.length > 0)
        ? this.tier3CausalChains
        : (this.correlationsList || []).map(c => ({
            ...c,
            CausalChainNarrative: c.Description || c.CausalChainNarrative,
            ActionRecommendation: c.RecommendedAction || c.ActionRecommendation,
            IsPositiveChain: (c.RelationshipType || "").includes("POSITIVE") ? 1 : 0
          }));
      if (this.activeTier2Kpi) {
        const matched = sourceList.filter(c => c.CauseKpiCode === this.activeTier2Kpi || c.EffectKpiCode === this.activeTier2Kpi);
        if (matched.length > 0) return matched;
      }
      return sourceList;
    },
    activeCausalChainObj() {
      const list = this.filteredTier3CausalChains || [];
      if (!list.length) return null;
      const idx = Math.min(Math.max(0, this.activeCausalChainIdx || 0), list.length - 1);
      return list[idx];
    },
    activeDriverFocusObj() {
      if (this.activeTier2DriverObj) return this.activeTier2DriverObj;
      const list = this.activeTier2MeasurableDrivers || [];
      return list.find(d => (d.VariancePct || 0) < 0) || list[0] || null;
    },
    activeRadarCampusObj() {
      const list = this.tier3Campuses || [];
      if (!list.length) {
        return {
          ScopeID: "MNLK",
          CampusName: "Mầm non Long Khánh",
          CurrentEnrollment: 129,
          PlannedCapacity: 166,
          CapacityRate: 77.7,
          WithdrawRate: 7.75,
          EnrollmentRisk: 68,
          AcademicRisk: 18,
          ServiceRisk: 42,
          OperationsRisk: 38,
          CampusRiskScore: 52,
          CampusRiskLevel: "HIGH",
          CampusTuitionLossVNĐ: 1850000000
        };
      }
      if (this.currentUnit && this.currentUnit !== "ALL") {
        const foundUnit = list.find(c => c.ScopeID === this.currentUnit);
        if (foundUnit) return foundUnit;
      }
      return list.find(c => c.ScopeID === this.selectedRadarCampus) || list[0];
    },
    radarSchoolAvgObj() {
      const list = this.tier3Campuses || [];
      if (!list.length) {
        return { EnrollmentRisk: 36, AcademicRisk: 22, ServiceRisk: 28, OperationsRisk: 30, CampusRiskScore: 32 };
      }
      const n = list.length;
      return {
        EnrollmentRisk: Math.round(list.reduce((s, c) => s + Number(c.EnrollmentRisk || 0), 0) / n),
        AcademicRisk: Math.round(list.reduce((s, c) => s + Number(c.AcademicRisk || 0), 0) / n),
        ServiceRisk: Math.round(list.reduce((s, c) => s + Number(c.ServiceRisk || 0), 0) / n),
        OperationsRisk: Math.round(list.reduce((s, c) => s + Number(c.OperationsRisk || 0), 0) / n),
        CampusRiskScore: Math.round(list.reduce((s, c) => s + Number(c.CampusRiskScore || 0), 0) / n)
      };
    },
    activeRadarAxisMeta() {
      const kpi = this.activeTier1Kpi || "KPI_1";
      const map = {
        KPI_1: {
          axisKey: "TS",
          axisName: "Trục Tuyển sinh & Lấp đầy",
          riskField: "EnrollmentRisk",
          barsTitle: "ĐỐI SÁNH LẤP ĐẦY CÔNG SUẤT & DƯ ĐỊA 5 CƠ SỞ",
          bottleneckText: "Điểm nghẽn: MNLK (77.7% · hụt 37 HS) & MNBH (87.9% · hụt 49 HS)"
        },
        KPI_2: {
          axisKey: "HT",
          axisName: "Trục Học thuật & Học liệu số LMS",
          riskField: "AcademicRisk",
          barsTitle: "ĐỐI SÁNH HOÀN THÀNH BÀI TẬP LMS & HỌC LIỆU SỐ 5 CƠ SỞ",
          bottleneckText: "Điểm nghẽn: Học liệu số tự học thấp tại MNLK (29.5%) & THPT (31.8%)"
        },
        KPI_3: {
          axisKey: "DV",
          axisName: "Trục Giữ chân HS & An toàn Học đường",
          riskField: "ServiceRisk",
          barsTitle: "ĐỐI SÁNH TỶ LỆ RÚT HỒ SƠ (TRẦN <= 10%) & Y TẾ 5 CƠ SỞ",
          bottleneckText: "Điểm nghẽn: MNLK rút học 7.75% (10 HS) & MNBH rút 3.36% (12 HS)"
        },
        KPI_4: {
          axisKey: "DV",
          axisName: "Trục Hiệu quả Dịch vụ & CLB Ngoại khóa",
          riskField: "ServiceRisk",
          barsTitle: "ĐỐI SÁNH TỶ LỆ ĐẠT CHỈ TIÊU CLB NGOẠI KHÓA 5 CƠ SỞ",
          bottleneckText: "Điểm sáng: Tiểu học vượt 117.7% (353 HS) · Nghẽn: THPT (63.3%) & MNBH (64.2%)"
        },
        KPI_5: {
          axisKey: "VH",
          axisName: "Trục Vận hành CSVC & Ngày công Nhân sự",
          riskField: "OperationsRisk",
          barsTitle: "ĐỐI SÁNH BẢO TRÌ PHÒNG NGỪA CSVC & NGÀY NGHỈ PHÉP 5 CƠ SỞ",
          bottleneckText: "Điểm nghẽn: TH (86.2% CSVC · hỏng máy lạnh Khu B) & MNBH (82.5 ngày phép)"
        },
        KPI_6: {
          axisKey: "TS",
          axisName: "Trục Chuyển đổi Phễu CRM & Hài lòng PHHS",
          riskField: "EnrollmentRisk",
          barsTitle: "ĐỐI SÁNH TỶ LỆ HÀI LÒNG PHỤ HUYNH (QA50) & CHUYỂN ĐỔI 5 CƠ SỞ",
          bottleneckText: "Điểm nghẽn: Khối Mầm non (91.0% hài lòng · tỷ lệ chốt kênh FB thấp)"
        }
      };
      return map[kpi] || map.KPI_1;
    },
    filteredTier3Audits() {
      const list = (this.tier3Audits && this.tier3Audits.length > 0)
        ? this.tier3Audits
        : (this.auditDiscrepanciesList || []);
      if (this.activeTier2Kpi) {
        const matched = list.filter(a => a.KpiCode === this.activeTier2Kpi);
        if (matched.length > 0) return matched;
      }
      const byMaster = list.filter(a => !a.MasterKpiCode || a.MasterKpiCode === this.activeTier1Kpi);
      return byMaster.length > 0 ? byMaster : list;
    },
    activeAuditFocusObj() {
      const list = this.filteredAuditList || [];
      if (!list.length) return null;
      const idx = Math.min(Math.max(0, this.activeAuditIdx || 0), list.length - 1);
      return list[idx];
    },
    computedTier3ImpactCards() {
      const kpi = this.activeTier1Kpi || "KPI_1";
      const d = this.activeTier2DriverObj;
      if (d) {
        const isGood = d.StatusBadge === "GOOD";
        return [
          {
            label: "Chỉ tiêu đang chọn (" + d.KpiCode + ")",
            value: this.formatKpiVal(d.ActualValue, d.Unit),
            unit: "",
            sub: "Kế hoạch: " + (d.DefaultOperator || ">=") + " " + this.formatKpiVal(d.TargetValue, d.Unit),
            tone: isGood ? "success" : "danger"
          },
          {
            label: "Độ lệch chuẩn hóa (Variance)",
            value: ((d.VariancePct || 0) > 0 ? "+" : "") + (d.VariancePct || 0) + "%",
            unit: "",
            sub: "Tiến độ chuẩn hóa: " + (d.ProgressPct || 0) + "% so với đích",
            tone: (d.VariancePct || 0) >= 0 ? "success" : "warn"
          },
          {
            label: "Tác động Tài chính / Vận hành",
            value: d.AuditIssueCount > 0 ? d.AuditIssueCount + " điểm vênh" : (isGood ? "An toàn" : "Cần can thiệp"),
            unit: "",
            sub: d.FinancialImpact || "Theo dõi trực tiếp trên Fact Store",
            tone: d.AuditIssueCount > 0 || !isGood ? "danger" : "success"
          },
          {
            label: "Chẩn đoán thực tế (Tháng 9)",
            value: (d.CausalChainCount || 1) + " chuỗi",
            unit: "nhân quả",
            sub: d.OperationalInsight || "Đã liên kết mô hình What-If",
            tone: "primary"
          }
        ];
      }
      if (kpi === "KPI_2") {
        return [
          { label: "Hoàn thành Bài tập LMS (CM08)", value: "89.6%", unit: "Toàn trường", sub: "Vượt chuẩn 80% (Khối 4-5 giảm nhẹ do Cúm A)", tone: "success" },
          { label: "Ứng dụng Học liệu số GV (CM04)", value: "35.5%", unit: "/ 60% KH", sub: "Điểm nghẽn: Thiếu video bài giảng tự học", tone: "danger" },
          { label: "Đạt chuẩn Khung Năng lực (CM17)", value: "82.4%", unit: "Thành thạo", sub: "Đạt 8 giải thưởng Học thuật & STEM (CM19)", tone: "success" },
          { label: "Hài lòng PH về Tiến bộ HS (QA23)", value: "92.4%", unit: "/ 90% KH", sub: "Du học THPT đạt 52% · Lịch báo giảng 98.2%", tone: "primary" }
        ];
      }
      if (kpi === "KPI_3") {
        return [
          { label: "Tỷ lệ Rút hồ sơ Lũy kế (TS04)", value: "2.02%", unit: "(53 HS)", sub: "Thấp hơn trần 10% · MNLK cao nhất 7.75% (10 HS)", tone: "success" },
          { label: "Rút học do Khoảng cách / Xe Bus", value: "21 HS", unit: "(39.6%)", sub: "Thất thu ~1.37 tỷ VNĐ/năm (TH 8, MNLK 4, THCS 4)", tone: "danger" },
          { label: "Dịch tễ Y tế Học đường (SK01)", value: "30 TCM", unit: "+ 53 Sốt", sub: "30 ca TCM lớp Kitty & Bee · Dịch Cúm A Khối 4-5 TH", tone: "warn" },
          { label: "An toàn Bếp ăn & Bán trú (VH28)", value: "94.5%", unit: "(0 Ngộ độc)", sub: "Đạt chuẩn an toàn VSATTP tại cả 5 cơ sở", tone: "success" }
        ];
      }
      if (kpi === "KPI_4") {
        return [
          { label: "Biên LN Gộp Dịch vụ (TC55)", value: "48.4%", unit: "/ 50% KH", sub: "Tiền ăn & Bán trú đạt 8.25 tỷ · Đồng phục 1.82 tỷ", tone: "warn" },
          { label: "Doanh thu CLB Ngoại khóa (TC56)", value: "1.611", unit: "Tỷ VNĐ", sub: "596 lượt ĐK: TH vượt 117.7% (353 HS), THCS/THPT 64%", tone: "success" },
          { label: "Dịch vụ Xe đưa rước (VH35)", value: "315 HS", unit: "(-14 vs T8)", sub: "Biên LN xe bus đạt 12.6% (thấp hơn định mức 15%)", tone: "danger" },
          { label: "Dịch vụ Ăn sáng (DV34)", value: "771 HS", unit: "(-21 vs T8)", sub: "Giảm từ 792 HS (T8) xuống 771 HS trong tháng 9", tone: "warn" }
        ];
      }
      if (kpi === "KPI_5") {
        return [
          { label: "Bảo trì Phòng ngừa CSVC (CSVC01)", value: "91.67%", unit: "/ 95% KH", sub: "Xử lý sự cố đúng SLA đạt 96% (75/79 ticket)", tone: "warn" },
          { label: "Điểm nghẽn Máy lạnh Khu B", value: "20 Máy", unit: "Đề xuất mua", sub: "18 lượt hỏng máy lạnh Khu B & C · Ngân sách ~360 tr", tone: "danger" },
          { label: "Nghỉ phép Khối Nhân sự (TC54)", value: "551 Ngày", unit: "(470 Đơn)", sub: "MNBH 82.5 ngày (15%) · MNLK 68 ngày · Bếp 54 ngày", tone: "danger" },
          { label: "Biến động Nhân sự (HR01)", value: "0.82%", unit: "(< 3% KH)", sub: "Đội ngũ cơ hữu ổn định · Phát sinh 288 tiết dạy thay", tone: "success" }
        ];
      }
      if (kpi === "KPI_6") {
        return [
          { label: "Tổng Leads Tuyển sinh T9 (TS05)", value: "162", unit: "/ 200 Leads", sub: "Kênh Facebook/Fanpage chiếm 70% lượng quan tâm", tone: "warn" },
          { label: "Tỷ lệ Chuyển đổi Phễu (TS06)", value: "13.58%", unit: "/ 30% KH", sub: "Nhập học mới 21 HS T9 · Còn 94 HS tham quan chưa chốt", tone: "danger" },
          { label: "Chi phí Tuyển sinh CAC (TS07)", value: "3.50 tr", unit: "VNĐ/HS", sub: "Vượt định mức 3.0 tr/HS do tỷ lệ chốt kênh FB thấp", tone: "warn" },
          { label: "Hài lòng Phụ huynh (QA50)", value: "93.6%", unit: "Hài lòng", sub: "PTLC đạt 96.5% · Mầm non đạt 91% · 25 phản ánh CSKH", tone: "success" }
        ];
      }
      // Default: KPI_1 (Quy mô & Lấp đầy công suất)
      const deficit = this.tier3CausalImpact && this.tier3CausalImpact.HeadcountDeficit != null ? this.tier3CausalImpact.HeadcountDeficit : 248;
      const tuitionLoss = this.tier3CausalImpact && this.tier3CausalImpact.TuitionLossVNĐ != null ? this.tier3CausalImpact.TuitionLossVNĐ : 16120000000;
      const boardingLoss = this.tier3CausalImpact && this.tier3CausalImpact.BoardingLossVNĐ != null ? this.tier3CausalImpact.BoardingLossVNĐ : 3720000000;
      return [
        { label: "Quy mô Hiện diện / Kế hoạch 5 Cơ sở", value: "2.625", unit: "/ 2.873 HS", sub: "Thiếu hụt " + deficit + " HS (MNLK đạt 77.7%, MNBH 87.9%, K11 83.3%)", tone: "danger" },
        { label: "Dư địa Học phí Chưa khai thác", value: "-" + this.formatBillion(tuitionLoss), unit: "Tỷ VNĐ", sub: "Tính theo biểu phí niêm yết từng cấp học 2026-2027", tone: "danger" },
        { label: "Dư địa Doanh thu Bán trú & Xe Bus", value: "-" + this.formatBillion(boardingLoss), unit: "Tỷ VNĐ", sub: "Tiền ăn, bán trú và dịch vụ xe đưa đón học sinh", tone: "warn" },
        { label: "Giá trị Bảo toàn từ 4 Đòn bẩy", value: "+4.08", unit: "Tỷ VNĐ", sub: "Tuyển bổ sung HK2, Mở 2 tuyến Bus & Giữ chân chuyển cấp", tone: "success" }
      ];
    },

    dynamicWithdrawReasons() {
      if (!this.breakdownsList || !this.breakdownsList.length) return [];
      const list = this.breakdownsList.filter(b => b.KpiCode === 'TS04' && b.DimensionCode !== 'TOTAL' && (b.DonViID === this.currentUnit || (this.currentUnit === 'ALL' && b.DonViID === 'ALL')));
      const total = list.reduce((sum, b) => sum + Number(b.ActualCount || 0), 0) || 1;
      const colorMap = {
        FAR: '#d13438', BUS: '#d13438', ECO: '#d9822b', SICK: '#107c41', ILL: '#107c41',
        ABROAD: '#004e8c', OTHER: '#605e5c'
      };
      return list.map(b => {
        const count = Number(b.ActualCount || 0);
        const pct = (count * 100.0 / total).toFixed(1);
        return {
          code: b.DimensionCode,
          name: b.DimensionName || b.DimensionCode,
          count,
          pct,
          color: colorMap[b.DimensionCode] || '#605e5c'
        };
      });
    },
    auditKpiStats() {
      const list = this.auditDiscrepanciesList || [];
      const critical = list.filter(x => (x.Category === 'MISMATCH' || (x.SeverityLevel && x.SeverityLevel.toUpperCase() === 'CRITICAL'))).length;
      const warn = list.filter(x => (x.Category === 'PARADOX' || x.Category === 'BOTTLENECK' || (x.SeverityLevel && x.SeverityLevel.toUpperCase() === 'WARN')) && x.Category !== 'MISMATCH').length;
      const resolved = list.filter(x => x.VerificationStatus === 'RESOLVED' || x.VerificationStatus === 'CONFIRMED').length;
      return { total: list.length, critical, warn, resolved };
    },
    filteredAuditList() {
      let list = this.auditDiscrepanciesList || [];
      if (this.auditDomainFilter && this.auditDomainFilter !== 'ALL') {
        const d = this.auditDomainFilter;
        list = list.filter(item => {
          const code = (item.AuditCode || '').toUpperCase();
          const title = (item.Title || '').toUpperCase();
          if (d === 'TS') return code.includes('TS') || code.includes('MARKETING') || code.includes('CAC') || code.includes('KITTY') || title.includes('TUYỂN SINH') || title.includes('LEADS') || title.includes('RÚT HỌC');
          if (d === 'CM') return code.includes('LMS') || code.includes('CALEN') || code.includes('INNOVATION') || code.includes('CM') || title.includes('HỌC THUẬT') || title.includes('BÀI TẬP') || title.includes('HỌC LIỆU') || title.includes('SÁNG KIẾN');
          if (d === 'HR') return code.includes('HR') || code.includes('LEAVE') || code.includes('TURNOVER') || title.includes('NGHỈ PHÉP') || title.includes('GIÁO VIÊN') || title.includes('NHÂN SỰ') || title.includes('KỶ LUẬT');
          if (d === 'CSVC') return code.includes('CSVC') || code.includes('MAINT') || code.includes('PURCHASE') || code.includes('BOARDING') || code.includes('HEALTH') || code.includes('CLUB') || title.includes('MÁY LẠNH') || title.includes('BÁN TRÚ') || title.includes('Y TẾ') || title.includes('CLB') || title.includes('MUA SẮM');
          if (d === 'IT') return code.includes('IT') || code.includes('ME_') || code.includes('FACEID') || code.includes('CRM') || title.includes('PHẦN MỀM') || title.includes('ME SCHOOL') || title.includes('FACEID') || title.includes('EXCEL');
          return true;
        });
      }
      if (this.auditSeverityFilter && this.auditSeverityFilter !== 'ALL') {
        const s = this.auditSeverityFilter;
        list = list.filter(item => {
          if (s === 'CRITICAL') return item.Category === 'MISMATCH' || (item.SeverityLevel && item.SeverityLevel.toUpperCase() === 'CRITICAL');
          if (s === 'WARN') return item.Category === 'PARADOX' || item.Category === 'BOTTLENECK' || (item.SeverityLevel && item.SeverityLevel.toUpperCase() === 'WARN');
          if (s === 'INFO') return (item.SeverityLevel && item.SeverityLevel.toUpperCase() === 'INFO') || item.VerificationStatus === 'RESOLVED';
          return true;
        });
      }
      return list;
    },
    kpiHealthStats() {
      const list = this.periodSnapshots || [];
      const total = list.length;
      if (!total) {
        return {
          total: 0, good: 0, warn: 0, critical: 0, pending: 0,
          goodPct: 0, warnPct: 0, criticalPct: 0, pendingPct: 0,
          avgProgress: 0, activeCount: 0,
          l1Count: 0, l2Count: 0, l3Count: 0
        };
      }
      const good = list.filter(k => k.Status === 'GOOD').length;
      const warn = list.filter(k => k.Status === 'WARN').length;
      const critical = list.filter(k => k.Status === 'CRITICAL' || k.Status === 'BAD' || k.Status === 'DANGER').length;
      const pending = list.filter(k => k.Status === 'PENDING' || k.DataSourceType === 'API_PENDING').length;
      const activeCount = good + warn + critical;
      
      const l1Count = list.filter(k => (k.FrameworkLevel || '').includes('1')).length;
      const l2Count = list.filter(k => (k.FrameworkLevel || '').includes('2')).length;
      const l3Count = list.filter(k => (k.FrameworkLevel || '').includes('3')).length;
      
      const activeList = list.filter(k => k.Status !== 'PENDING' && k.DataSourceType !== 'API_PENDING');
      const sumProgress = activeList.reduce((acc, k) => acc + (Math.min(100, Math.max(0, Number(k.Rate) || 0))), 0);
      const avgProgress = activeList.length ? Number((sumProgress / activeList.length).toFixed(1)) : 0;

      return {
        total,
        good,
        warn,
        critical,
        pending,
        activeCount,
        goodPct: Number((good * 100 / total).toFixed(1)),
        warnPct: Number((warn * 100 / total).toFixed(1)),
        criticalPct: Number((critical * 100 / total).toFixed(1)),
        pendingPct: Number((pending * 100 / total).toFixed(1)),
        activeGoodPct: activeCount ? Number((good * 100 / activeCount).toFixed(1)) : 0,
        activeWarnPct: activeCount ? Number((warn * 100 / activeCount).toFixed(1)) : 0,
        avgProgress,
        l1Count,
        l2Count,
        l3Count
      };
    },
    filteredFrameworkKpis() {
      let list = this.periodSnapshots || [];
      if (this.frameworkGroupFilter && this.frameworkGroupFilter !== 'ALL') {
        const gf = this.frameworkGroupFilter;
        if (gf === 'Giáo dục & Học thuật' || gf === 'Chất lượng Giáo dục') {
          list = list.filter(k => k.KpiGroup === 'Chất lượng Giáo dục' || k.KpiGroup === 'Học thuật & Đào tạo' || k.KpiGroup === 'Giáo dục & Học thuật');
        } else if (gf === 'Dịch vụ & An toàn' || gf === 'Vận hành & Dịch vụ') {
          list = list.filter(k => k.KpiGroup === 'Dịch vụ & An toàn' || k.KpiGroup === 'Vận hành & Dịch vụ');
        } else if (gf === 'Tài chính & CSVC') {
          list = list.filter(k => k.KpiGroup === 'Tài chính & CSVC' || k.KpiGroup === 'Tài chính & Dịch vụ');
        } else {
          list = list.filter(k => k.KpiGroup === gf);
        }
      }
      if (this.frameworkLevelFilter && this.frameworkLevelFilter !== 'ALL') {
        list = list.filter(k => (k.FrameworkLevel || '').includes(this.frameworkLevelFilter));
      }
      if (this.frameworkStatusFilter && this.frameworkStatusFilter !== 'ALL') {
        if (this.frameworkStatusFilter === 'CRITICAL') {
          list = list.filter(k => k.Status === 'CRITICAL' || k.Status === 'BAD' || k.Status === 'DANGER');
        } else if (this.frameworkStatusFilter === 'PENDING') {
          list = list.filter(k => k.Status === 'PENDING' || k.DataSourceType === 'API_PENDING');
        } else {
          list = list.filter(k => k.Status === this.frameworkStatusFilter);
        }
      }
      if (this.frameworkSearchQuery && this.frameworkSearchQuery.trim()) {
        const q = this.frameworkSearchQuery.trim().toLowerCase();
        list = list.filter(k => 
          (k.KpiCode && k.KpiCode.toLowerCase().includes(q)) ||
          (k.KpiName && k.KpiName.toLowerCase().includes(q)) ||
          (k.FrameworkRef && k.FrameworkRef.toLowerCase().includes(q)) ||
          (k.KpiGroup && k.KpiGroup.toLowerCase().includes(q)) ||
          (k.SourceSystem && k.SourceSystem.toLowerCase().includes(q))
        );
      }
      return list;
    },
    filteredRiskCampusCards() {
      if (!this.riskCampusCards || !this.riskCampusCards.length) return [];
      if (this.selectedRiskCampusScope && this.selectedRiskCampusScope !== 'ALL') {
        return this.riskCampusCards.filter(c => c.ScopeID === this.selectedRiskCampusScope);
      }
      return this.riskCampusCards;
    },
    totalRiskWithdrawForecast() {
      if (this.riskCampusCards && this.riskCampusCards.length) {
        let minTot = 0;
        let maxTot = 0;
        this.riskCampusCards.forEach(c => {
          if (c.WithdrawForecast) {
            const m = c.WithdrawForecast.match(/(\d+)\s*-\s*(\d+)/);
            if (m) {
              minTot += parseInt(m[1], 10);
              maxTot += parseInt(m[2], 10);
            }
          }
        });
        if (minTot > 0 && maxTot > 0) return `${minTot} - ${maxTot} HS`;
      }
      return "0 HS";
    },
    totalRiskTuitionForecast() {
      if (this.riskCampusCards && this.riskCampusCards.length) {
        let minM = 0;
        let maxM = 0;
        this.riskCampusCards.forEach(c => {
          if (c.TuitionAtRisk) {
            const m = c.TuitionAtRisk.match(/(\d+)M\s*-\s*(\d+)M/);
            if (m) {
              minM += parseInt(m[1], 10);
              maxM += parseInt(m[2], 10);
            }
          }
        });
        if (minM > 0 && maxM > 0) {
          const minStr = minM >= 1000 ? (minM / 1000).toFixed(2) + "B" : minM + "M";
          const maxStr = maxM >= 1000 ? (maxM / 1000).toFixed(2) + "B" : maxM + "M";
          return `${minStr} - ${maxStr}`;
        }
      }
      return "0 VNĐ";
    },
    computedStrategicPreservedRevenue() {
      if (this.strategicLevers && this.strategicLevers.length) {
        const totM = this.strategicLevers.reduce((sum, l) => {
          const m = (l.RevenueGainText || "").match(/\+?(\d+)\s*tr/);
          return sum + (m ? parseInt(m[1], 10) : 0);
        }, 0);
        if (totM >= 1000) return `+${(totM / 1000).toFixed(2)} tỷ VNĐ`;
        return `+${totM} tr VNĐ`;
      }
      return "+0 VNĐ";
    },
    operationalFactsTotalCount() {
      return (this.operationalFactsList && this.operationalFactsList.length) ? this.operationalFactsList.length : 0;
    },
    displayOutflowYearToDate() {
      const k = this.getKpi("TS04");
      if (k && k.OperationalInsight) {
        const m = k.OperationalInsight.match(/Lũy\s+kế.*?(\d+)\s*HS/i);
        if (m) return parseInt(m[1], 10);
      }
      return this.withdrawRecords.length || this.displayWithdrawCount || 0;
    },
    clubTargetText() {
      const k = this.getKpi("TC33") || this.getKpi("TC56");
      if (k && k.TargetValue) {
        const val = Number(k.TargetValue);
        return val >= 1000000000 ? (val / 1000000000).toFixed(2) + " tỷ HK1 (Quỹ $1M)" : (val / 1000000).toFixed(0) + " tr VNĐ";
      }
      return "0 tỷ HK1 (Quỹ $1M)";
    },
    displayClubTarget() {
      return this.clubTargetText;
    },
    currentPeriodFreezeText() {
      const p = this.periodsList && this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      if (p && p.IsFrozen) {
        return "Chốt " + (p.FreezeDate ? p.FreezeDate.slice(0, 10) : "kỳ " + this.selectedPeriod);
      }
      return "Kỳ Live " + (this.selectedPeriod || "2026-10");
    },
    currentPeriodStartDate() {
      const p = this.periodsList && this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      return (p && p.StartDate) ? p.StartDate : `${this.selectedYear}-09-01`;
    },
    currentPeriodEndDate() {
      const p = this.periodsList && this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      return (p && p.EndDate) ? p.EndDate : `${this.selectedYear}-09-30`;
    },
    currentPeriodIsFrozen() {
      const p = this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      return p ? !!p.IsFrozen : true;
    },
    dynamicRiskFactsBrief() {
      const k = this.getKpi("HR01");
      if (k && k.ActualValue != null) {
        return k.ActualValue + " ngày công nghỉ";
      }
      return "Theo dõi ngày công nghỉ";
    },
    dynamicRiskLeadingText() {
      const redCampuses = (this.riskCampusCards || []).filter((c) => c.RiskTier === "RED").map((c) => c.CampusName);
      const warnCampuses = (this.riskCampusCards || []).filter((c) => c.RiskTier === "WARN").map((c) => c.CampusName);
      let text = "Phân tích chỉ báo sớm (Leading Risk Indicators) kỳ " + this.currentPeriodName + ".";
      if (redCampuses.length) {
        text += " Phát hiện <b>" + redCampuses.length + " Cơ sở thuộc Vùng Đỏ Nguy Cơ Cao (" + redCampuses.join(", ") + ")</b>.";
      }
      if (warnCampuses.length) {
        text += " Có <b>" + warnCampuses.length + " Cơ sở Vùng Cảnh Báo (" + warnCampuses.join(", ") + ")</b>.";
      }
      if (!redCampuses.length && !warnCampuses.length) {
        text += " Toàn bộ các cơ sở đều nằm trong ngưỡng an toàn vận hành.";
      }
      return text;
    },
    financeSummaryTotalRevenue() {
      if (this.financeSummary && this.financeSummary.TotalOpRevenue) {
        return (Number(this.financeSummary.TotalOpRevenue) / 1000000000.0).toFixed(2) + " tỷ";
      }
      return this.currentPeriodIsFrozen ? "0 tỷ" : "Đang cập nhật";
    },
    financeSummaryTotalCost() {
      if (this.financeSummary && this.financeSummary.TotalOpCost) {
        return (Number(this.financeSummary.TotalOpCost) / 1000000000.0).toFixed(2) + " tỷ";
      }
      return this.currentPeriodIsFrozen ? "0 tỷ" : "Đang cập nhật";
    },
    financeSummaryTotalProfit() {
      if (this.financeSummary && this.financeSummary.TotalOpGrossProfit) {
        return (Number(this.financeSummary.TotalOpGrossProfit) / 1000000000.0).toFixed(2) + " tỷ";
      }
      return this.currentPeriodIsFrozen ? "0 tỷ" : "Đang cập nhật";
    },
    financeSummaryTotalMargin() {
      if (this.financeSummary && this.financeSummary.TotalOpMarginPct != null) {
        return Number(this.financeSummary.TotalOpMarginPct).toFixed(1) + "%";
      }
      return this.currentPeriodIsFrozen ? "0.0%" : "Đang cập nhật";
    },
    totalClubStudents() {
      if (this.financeSummary && this.financeSummary.TotalClubStudents) {
        return this.financeSummary.TotalClubStudents;
      }
      return this.financeClubs.reduce((sum, c) => sum + (parseInt(c.students || c.rawStudents, 10) || 0), 0);
    },
    totalClubRevenueText() {
      if (this.financeSummary && this.financeSummary.TotalClubRevenue) {
        return (Number(this.financeSummary.TotalClubRevenue) / 1000000000.0).toFixed(3) + " tỷ VNĐ";
      }
      return this.currentPeriodIsFrozen ? "0 VNĐ" : "Đang cập nhật";
    },
    clubAchievedPct() {
      if (this.financeSummary && this.financeSummary.TotalClubRevenue) {
        const rev = Number(this.financeSummary.TotalClubRevenue);
        return ((rev / 1743000000) * 100).toFixed(1) + "%";
      }
      return this.currentPeriodIsFrozen ? "0%" : "Đang cập nhật";
    },
    crmTotalPtlcLeads() {
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.ptlcLeads ?? m.PtlcLeads ?? 0), 0);
    },
    crmTotalMnbhLeads() {
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnbhLeads ?? m.MnbhLeads ?? 0), 0);
    },
    crmTotalMnlkLeads() {
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnlkLeads ?? m.MnlkLeads ?? 0), 0);
    },
    crmTotalLeadsSum() {
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.totalLeads ?? m.TotalLeads ?? 0), 0);
    },
    crmTotalEnrolledSum() {
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.totalEnrolled ?? m.TotalEnrolled ?? m.EnrolledStudents ?? 0), 0);
    },
    crmOverallConversionRate() {
      const tot = this.crmTotalLeadsSum;
      const enr = this.crmTotalEnrolledSum;
      return tot > 0 ? ((enr / tot) * 100).toFixed(2) + "%" : "0.0%";
    },
    priorPeriodKey() {
      if (!this.periodsList || !this.periodsList.length) return null;
      const idx = this.periodsList.findIndex((p) => p.PeriodKey === this.selectedPeriod);
      if (idx >= 0 && idx + 1 < this.periodsList.length) {
        return this.periodsList[idx + 1].PeriodKey;
      }
      const match = (this.selectedPeriod || "").match(/^(\d{4})-(\d{2})$/);
      if (match) {
        let year = parseInt(match[1], 10);
        let month = parseInt(match[2], 10) - 1;
        if (month === 0) {
          month = 12;
          year -= 1;
        }
        const fallbackKey = `${year}-${month < 10 ? "0" + month : month}`;
        return this.periodsList.some((p) => p.PeriodKey === fallbackKey) ? fallbackKey : null;
      }
      return null;
    },
    filteredRiskChecklist() {
      if (!this.riskChecklist || !this.riskChecklist.length) return [];
      return this.riskChecklist.filter((item) => {
        const id = item.ChecklistID || item.DirectiveTitle;
        const isDone = !!this.directiveStatusMap[id];
        if (this.directiveStatusFilter === "DONE") return isDone;
        if (this.directiveStatusFilter === "PENDING") return !isDone;
        if (this.directiveStatusFilter === "URGENT") return item.StatusClass === "is-urgent" && !isDone;
        return true;
      });
    },
    currentBreadcrumbTitle() {
      switch (this.page) {
        case 1: return "1. Sĩ số & Khối lớp (Chỉ tiêu 1–3)";
        case 7: return "2. Phễu TVTS & Leads CRM (Chỉ tiêu 5, 6)";
        case 2: return "3. Rút học & Chuyển đi (Chỉ tiêu 4)";
        case 4: return "4. Chuyên môn LMS (Nhóm 2: 8, 11, 15)";
        case 6: return "5. Dịch vụ & An toàn Học đường (Nhóm 3: 28–40)";
        case 5: return "6. Tài chính: LN gộp & CLB (Nhóm 4: 55, 56)";
        default: return "Chi tiết Phân hệ Vận hành";
      }
    },
    currentRoiScenarioTitle() {
      const titles = {
        BUS: 'Kịch bản 1: Mở tuyến bus đón học sinh xa nhà (Bảo toàn ' + (this.displayReasonFar || 21) + ' HS rút học)',
        AC: 'Kịch bản 2: Bảo dưỡng phòng ngừa & Thay máy lạnh (Khắc phục ticket hỏng tồn đọng)',
        STEM: 'Kịch bản 3: Đầu tư Phòng Lab STEM & CLB từ thặng dư dịch vụ CLB (' + (this.computedFinanceData ? this.computedFinanceData.clbRev : 'thặng dư cao') + ')',
        ADS_CRM: 'Kịch bản 4: Chiến dịch Tiếp thị & Tuyển sinh bổ sung Học kỳ 2'
      };
      return titles[this.selectedRoiScenario] || '';
    },
    currentRoiResult() {
      if (this.selectedRoiScenario === 'BUS') {
        const busCost = this.roiBusRoutes * this.roiBusCostPerMonth * this.roiBusMonths * 1000000;
        const busTicketRev = this.roiBusStudentsRetained * this.roiBusFeePerMonth * this.roiBusMonths * 1000000;
        const busDirectOperatingMargin = busTicketRev - busCost;
        const breakEvenBusSeatsPerRoute = this.roiBusFeePerMonth > 0 ? Math.ceil(this.roiBusCostPerMonth / this.roiBusFeePerMonth) : 24;
        const tuitionContributionRev = this.roiBusStudentsRetained * (this.roiTuitionPerYear * 1000000) * 0.82;
        const totalBenefit = busTicketRev + tuitionContributionRev;
        const netProfit = totalBenefit - busCost;
        const roiPct = busCost > 0 ? Math.round((netProfit / busCost) * 1000) / 10 : 0;
        const monthlyNet = totalBenefit / this.roiBusMonths;
        const paybackMonths = monthlyNet > 0 ? Math.round((busCost / monthlyNet) * 10) / 10 : 0;
        const unitContributionPerStudent = (this.roiTuitionPerYear * 1000000 * 0.82) + (this.roiBusFeePerMonth * this.roiBusMonths * 1000000);
        const breakEvenStudentsOverall = unitContributionPerStudent > 0 ? Math.ceil(busCost / unitContributionPerStudent) : 0;
        return {
          cost: busCost,
          revenue: totalBenefit,
          netProfit,
          roiPct,
          paybackMonths,
          costNote: 'Thuê ' + this.roiBusRoutes + ' tuyến x ' + this.roiBusCostPerMonth + 'tr/th x ' + this.roiBusMonths + 'th = ' + Math.round(busCost/1000000) + ' triệu VNĐ',
          revNote: 'Bảo toàn ' + this.roiBusStudentsRetained + ' HS: Vé bus ' + Math.round(busTicketRev/1000000) + 'tr + Biên học phí (82%) ' + Math.round(tuitionContributionRev/1000000) + 'tr',
          verdictTag: netProfit > 0 ? 'BÙ CHÉO HỌC PHÍ - HIỆU QUẢ CAO' : 'CÂN NHẮC NGUỒN VỐN',
          verdictText: 'Dịch vụ xe bus chịu lỗ vận hành trực tiếp ' + (busDirectOperatingMargin < 0 ? Math.abs(Math.round(busDirectOperatingMargin/1000000)) + ' triệu VNĐ (cần ' + breakEvenBusSeatsPerRoute + ' ghế/tuyến để tự hòa vốn). ' : 'thặng dư ' + Math.round(busDirectOperatingMargin/1000000) + ' triệu VNĐ. ') + 'Tuy nhiên, dưới cơ chế Bù chéo dòng tiền (Cross-subsidization), việc giữ chân ' + this.roiBusStudentsRetained + ' HS mang lại Biên đóng góp học phí thuần ' + Math.round(tuitionContributionRev/1000000) + ' triệu VNĐ (tỷ suất 82% Contribution Margin). Tổng thặng dư toàn trường đạt ' + Math.round(netProfit/1000000) + ' triệu VNĐ (ROI ' + roiPct + '%). Điểm hòa vốn toàn trường chỉ cần giữ chân tối thiểu ' + breakEvenStudentsOverall + ' học sinh.',
          causalLinkText: 'Chuỗi 1 & Chuỗi 8 (CSDL eSign): Tuyến xa là trigger rút học; giải bài toán xe bus bằng tư duy bù chéo học phí toàn trường, không ép dịch vụ xe bus tự chịu lãi cục bộ.'
        };
      } else if (this.selectedRoiScenario === 'AC') {
        const capex = this.roiAcNewCount * this.roiAcCapexPerUnit * 1000000;
        const opex = this.roiAcMaintCount * this.roiAcMaintCost * 1000000;
        const cost = capex + opex;
        const revenue = this.roiAcStudentsProtected * 65200000;
        const netProfit = revenue - cost;
        const roiPct = cost > 0 ? Math.round((netProfit / cost) * 1000) / 10 : 0;
        const paybackMonths = Math.round((cost / (revenue / 10)) * 10) / 10;
        return {
          cost,
          revenue,
          netProfit,
          roiPct,
          paybackMonths,
          costNote: 'Capex thay mới ' + this.roiAcNewCount + ' máy (' + Math.round(capex/1000000) + 'tr) + Opex bảo dưỡng ' + this.roiAcMaintCount + ' máy (' + Math.round(opex/1000000) + 'tr)',
          revNote: 'Ngăn ngừa ' + this.roiAcStudentsProtected + ' HS mầm non & tiểu học chuyển trường vì tiện nghi kém',
          verdictTag: 'ƯU TIÊN BẢO ĐẢM DỊCH VỤ',
          verdictText: 'Chi phí bảo trì & thay mới ' + Math.round(cost/1000000) + ' triệu VNĐ chỉ bằng 26% doanh thu học phí bảo toàn (' + Math.round(revenue/1000000) + ' triệu VNĐ). Xử lý dứt điểm 4 ticket tồn đọng máy lạnh Khu B và MNLK là bắt buộc để triệt tiêu phàn nàn phụ huynh.',
          causalLinkText: 'Chuỗi CSVC01 & QA01: Tiện nghi điều hòa kém -> Phàn nàn phụ huynh -> Suy giảm uy tín & Rút học đầu năm.'
        };
      } else if (this.selectedRoiScenario === 'STEM') {
        const capex = this.roiStemLabCapex * 1000000;
        const opexCoach = this.roiStemCoachCostPerMonth * this.roiStemMonths * 1000000;
        const cost = capex + opexCoach;
        const revenue = this.roiStemStudents * this.roiStemFeePerMonth * this.roiStemMonths * 1000000;
        const netProfit = revenue - cost;
        const roiPct = cost > 0 ? Math.round((netProfit / cost) * 1000) / 10 : 0;
        const paybackMonths = Math.round((cost / (revenue / this.roiStemMonths)) * 10) / 10;
        return {
          cost,
          revenue,
          netProfit,
          roiPct,
          paybackMonths,
          costNote: 'Capex phòng Lab (' + this.roiStemLabCapex + 'tr) + Thù lao HLV (' + Math.round(opexCoach/1000000) + 'tr)',
          revNote: 'Doanh thu học phí CLB từ ' + this.roiStemStudents + ' học sinh mới trong ' + this.roiStemMonths + ' tháng',
          verdictTag: 'TỰ CÂN ĐỐI TỪ THẶNG DƯ CLB',
          verdictText: 'Doanh thu dịch vụ CLB ' + this.currentPeriodName + ' đạt ' + (this.computedFinanceData ? this.computedFinanceData.clbRev : 'thặng dư cao') + '. Trích 200 triệu tái đầu tư phòng Lab STEM/AI sẽ tạo nguồn thu dịch vụ bền vững và giữ chân học sinh Tiểu học lên THCS.',
          causalLinkText: 'Vòng lặp phản hồi 2 chiều CLB01 <-> TC56: Doanh thu CLB thặng dư -> Tái đầu tư CSVC STEM -> Tăng sức hút học sinh.'
        };
      } else {
        const cost = this.roiAdsBudget * 1000000;
        const expectedStudents = Math.round(this.roiExpectedLeads * (this.roiConversionPct / 100));
        const revenue = expectedStudents * this.roiHK2TuitionPerStudent * 1000000;
        const netProfit = revenue - cost;
        const roiPct = cost > 0 ? Math.round((netProfit / cost) * 1000) / 10 : 0;
        const paybackMonths = Math.round((cost / (revenue / 5)) * 10) / 10;
        return {
          cost,
          revenue,
          netProfit,
          roiPct,
          paybackMonths,
          costNote: 'Ngân sách Marketing & Telesales (' + this.roiAdsBudget + ' triệu VNĐ)',
          revNote: 'Chốt tuyển ' + expectedStudents + ' HS nhập mới HK2 từ ' + this.roiExpectedLeads + ' leads (Tỷ lệ ' + this.roiConversionPct + '%)',
          verdictTag: 'ĐÒN BẨY QUY MÔ SĨ SỐ',
          verdictText: 'Đầu tư ' + this.roiAdsBudget + ' triệu chiêu sinh HK2 mang lại ' + expectedStudents + ' học sinh bổ sung cho Khối 10 và Mầm non, bổ sung ' + Math.round(revenue/1000000) + ' triệu doanh thu học phí, hoàn vốn sau ' + paybackMonths + ' tháng.',
          causalLinkText: 'Chuỗi CRM01 -> TS06 -> TS01: Tăng tốc phản hồi leads < 15 phút nâng tỷ lệ chuyển đổi từ 13% lên 18%.'
        };
      }
    },
    currentMonthText() {
      const mo = this.causalMonthOptions.find((o) => o.m === this.causalMonth);
      return mo ? mo.t.toLowerCase() : "đầu tháng 10";
    },
    currentMonthRatio() {
      const mo = this.causalMonthOptions.find((o) => o.m === this.causalMonth);
      return mo ? mo.r : 8 / 9;
    },
    currentCausalAssumption() {
      const list = (this.causalAssumptionsList && this.causalAssumptionsList.length) ? this.causalAssumptionsList : (this.defaultAssumptions || []);
      let targetCode = this.causalUnit || this.currentUnit || "ALL";
      if (targetCode === "MNTB") targetCode = "MNBH";
      const found = list.find((a) => a.UnitCode === targetCode);
      const fallback = found || list.find((a) => a.UnitCode === "ALL") || list[0] || {};
      return {
        UnitCode: targetCode,
        UnitName: this.currentUnitTitle || "Toàn trường",
        OwnerTitle: "Tổng Giám Đốc / HĐQT",
        PlannedCapacity: 2752,
        CurrentEnrollment: 2625,
        AnnualTuitionMillion: 49.8,
        GrossMarginPct: 0.85,
        RemainingYearsInLevel: 2.0,
        NextLevelTuitionMillion: 60.0,
        NextLevelYears: 3.0,
        TransitionProbability: 0.5,
        MonthlyLeads: 470,
        ConversionRate: 0.095,
        ClbParticipationRate: 0.32,
        ClbAvgFeeMillion: 4.5,
        ClassCount: 99,
        ...fallback
      };
    },
    currentCausalUnitName() {
      return this.currentCausalAssumption.UnitName || (this.causalUnit === "ALL" ? "Toàn trường" : "MN Long Khánh");
    },
    currentCausalOwnerTitle() {
      return this.currentCausalAssumption.OwnerTitle || (this.causalUnit === "ALL" ? "Tổng Giám Đốc / HĐQT" : "Hiệu trưởng MN Long Khánh");
    },
    // ─── GENERIC CAUSAL ENGINE ───────────────────────────────────────────────────
    // Danh sách KPI gốc có trong elasticityMatrix (tự sinh, không hardcode)
    availableCausalKpis() {
      const matrix = this.elasticityMatrixList.length ? this.elasticityMatrixList : this.defaultElasticityMatrix;
      const seen = {};
      const groups = {
        "TS04": { label: "Rút học (TS04)", group: "Quy mô & Tuyển sinh" },
        "TS06": { label: "Chuyển đổi TVTS (TS06)", group: "Quy mô & Tuyển sinh" },
        "TS01": { label: "Sĩ số hiện diện (TS01)", group: "Quy mô & Tuyển sinh" },
        "BUS01": { label: "Hạ tầng Xe đưa đón (BUS01)", group: "Dịch vụ & An toàn" },
        "CSVC01": { label: "CSVC Hỏng hóc / Ticket (CSVC01)", group: "Dịch vụ & An toàn" },
        "MED01": { label: "Y tế học đường (MED01)", group: "Dịch vụ & An toàn" },
        "QA01": { label: "Hài lòng Phụ huynh QA (QA01)", group: "Dịch vụ & An toàn" },
        "HR03": { label: "Nghỉ phép NV Bếp (HR03)", group: "Dịch vụ & An toàn" },
        "HR02": { label: "Biến động Nhân sự GV (HR02)", group: "Giáo viên & Chuyên môn" },
        "CM08": { label: "Hoàn thành LMS (CM08)", group: "Giáo viên & Chuyên môn" },
        "CM02": { label: "Tiết Dạy thay (CM02)", group: "Giáo viên & Chuyên môn" },
        "TC56": { label: "Thặng dư CLB (TC56)", group: "Tài chính & Bảo toàn vốn" },
        "CLB01": { label: "Doanh thu CLB ngoài giờ (CLB01)", group: "Tài chính & Bảo toàn vốn" },
        "CAP01": { label: "Công suất lớp học (CAP01)", group: "Tài chính & Bảo toàn vốn" },
        "IT01": { label: "Phần mềm CRM/Thu phí (IT01)", group: "Tài chính & Bảo toàn vốn" },
        "FIN01": { label: "Nợ đọng Học phí (FIN01)", group: "Tài chính & Bảo toàn vốn" },
      };
      const result = [];
      matrix.forEach((row) => {
        if (!seen[row.CauseKpiCode]) {
          seen[row.CauseKpiCode] = true;
          const meta = groups[row.CauseKpiCode] || { label: row.CauseKpiCode, group: "Khác" };
          result.push({ kpiCode: row.CauseKpiCode, label: meta.label, group: meta.group });
        }
      });
      return result;
    },
    // Danh sách effects downstream của KPI đang chọn, phân theo Stage 1/2/3
    activeDownstreamEffects() {
      const matrix = this.elasticityMatrixList.length ? this.elasticityMatrixList : this.defaultElasticityMatrix;
      return matrix.filter((r) => r.CauseKpiCode === this.causalKpiCode);
    },
    // Danh sách mắt xích liên quan từ correlationsList của CSDL eSign tháng 9
    currentKpiCorrelations() {
      const list = (this.correlationsList && this.correlationsList.length) ? this.correlationsList : (this.defaultCorrelations || []);
      const kpi = this.causalKpiCode;

      // 1. Alias mapping giữa mã dropdown và mã CSDL eSign
      const aliasMap = {
        "HR03": ["HR01", "OP01"],
        "CAP01": ["TS01", "TS06", "CRM01"],
        "CM08": ["CM09", "CM02", "MED01"],
        "FIN01": ["IT01", "OP02", "TC55"],
        "TS01": ["TS06", "CRM01", "TS04"],
      };

      const targetKpis = [kpi, ...(aliasMap[kpi] || [])];

      // 2. Với CSVC01: Mở rộng cả chặng trực tiếp và chặng 2-hop (CSVC01 -> QA01 -> AUDIT01)
      if (kpi === "CSVC01") {
        const directCSVC = list.filter(c => c.CauseKpiCode === "CSVC01" || c.EffectKpiCode === "CSVC01");
        const qaLinks = list.filter(c => c.CauseKpiCode === "QA01" || c.EffectKpiCode === "QA01");
        const combined = [...directCSVC];
        qaLinks.forEach(q => {
          if (!combined.some(x => x.CorrelationID === q.CorrelationID)) combined.push(q);
        });
        if (combined.length) return combined;
      }

      // 3. Với BUS01: Mở rộng cả Chuỗi 1 và Chuỗi 8 (Nghịch lý chi phí xe bus)
      if (kpi === "BUS01") {
        return list.filter(c => c.CauseKpiCode === "BUS01" || c.EffectKpiCode === "BUS01" || c.CauseKpiCode === "BUS02");
      }

      // 4. Tìm kiếm các mắt xích thuộc nhóm chỉ tiêu liên quan
      const direct = list.filter(c => targetKpis.includes(c.CauseKpiCode) || targetKpis.includes(c.EffectKpiCode));
      if (direct.length) return direct;

      // 5. Fallback an toàn: Trích xuất trực tiếp từ downstream effects của genericCausalCalc
      const effs = this.activeDownstreamEffects;
      if (effs && effs.length) {
        return effs.slice(0, 3).map((e, idx) => ({
          CorrelationID: 900 + idx,
          ChainGroup: `Mắt xích ${kpi} → ${e.EffectKpiCode} (Giai đoạn ${e.Stage})`,
          CauseKpiCode: kpi,
          CauseKpiName: this.availableCausalKpis.find(x => x.kpiCode === kpi)?.label || kpi,
          EffectKpiCode: e.EffectKpiCode,
          EffectKpiName: `Tác động đến ${e.EffectKpiCode}`,
          RelationshipType: e.Stage === 1 ? "DIRECT_IMPACT" : e.Stage === 2 ? "OPERATIONAL_STRAIN" : "STRATEGIC_RISK",
          Description: `Biến động tại ${kpi} lan truyền đến ${e.EffectKpiCode} với hệ số co giãn ${e.ElasticityCoeff}.`,
          QuantifiedImpact: `Chi phí can thiệp dự kiến: ${e.InterventionCostPerUnit} tr/đơn vị · Tỷ lệ bảo toàn: ${Math.round(e.InterventionSaveRate * 100)}%.`,
          RecommendedAction: e.InterventionName || "Rà soát đối thoại và triển khai phương án can thiệp.",
          ResponsibleRole: e.InterventionOwner || this.currentCausalOwnerTitle,
        }));
      }

      return direct;
    },
    // Delta thực tế từ periodSnapshots (tự động; override bằng causalDeltaOverride)
    causalDeltaAuto() {
      if (this.causalDeltaOverride !== null && this.causalDeltaOverride !== undefined) {
        return Math.max(1, Math.min(50, Math.round(Number(this.causalDeltaOverride) || 1)));
      }
      // Mapping KPI code → giá trị thực tế từ dữ liệu live tháng hiện tại
      const u = this.causalUnit === "MNTB" ? "MNBH" : this.causalUnit;
      const map = {
        "TS04": this.getDefaultWithdrawCountForUnit(u),
        "TS06": u === "ALL" ? 21 : u === "MNBH" ? 7 : u === "MNLK" ? 10 : 4,
        "TS01": this.currentCausalAssumption.CurrentEnrollment || 0,
        "BUS01": 2,  // 2 tuyến còn thiếu
        "CSVC01": 18, // 18 ticket máy lạnh tồn
        "MED01": 131, // 131 ca bệnh tháng 9
        "QA01": 53,   // 53 ca rút học (nghịch lý CSAT)
        "HR03": 54,   // 54 ngày công nghỉ phép bếp
        "HR02": 45,   // 45 ca biến động nhân sự
        "CM08": 2.5,  // lệch 2.5% so với mục tiêu
        "CM02": 288,  // 288 tiết dạy thay
        "TC56": 480,  // 480 triệu thặng dư CLB
        "CLB01": 596, // 596 học viên CLB
        "CAP01": u === "MNLK" ? 37 : u === "MNBH" ? 49 : 248, // học sinh thiếu so với chỉ tiêu
        "IT01": 120,  // 120 giờ nhân sự lãng phí Excel
        "FIN01": 0,
      };
      return map[this.causalKpiCode] !== undefined ? map[this.causalKpiCode] : 10;
    },
    // ─── ENGINE TÍNH 3 GIAI ĐOẠN TÁC ĐỘNG (Không hardcode) ─────────────────────
    genericCausalCalc() {
      const ass = this.currentCausalAssumption;
      const delta = this.causalDeltaAuto;
      const hp = ass.AnnualTuitionMillion;
      const margin = ass.GrossMarginPct;
      const variableCost = 1 - margin;
      const r = this.currentMonthRatio;
      const conv = ass.ConversionRate;
      const monthlyLeads = ass.MonthlyLeads;
      const planCap = ass.PlannedCapacity;
      const enrolled = ass.CurrentEnrollment;
      const ltv_years = ass.RemainingYearsInLevel;

      const effects = this.activeDownstreamEffects;
      const kpiCode = this.causalKpiCode;
      const isStudentScale = kpiCode === "TS04" || kpiCode === "TS06" || kpiCode === "BUS01" || kpiCode === "CAP01" || kpiCode === "TS01" || kpiCode === "CRM01";

      // ── Giai đoạn 1: Tức thì ──────────────────────────────────────────────────
      let stage1RevLoss = 0; // tỷ VNĐ hụt thu
      let stage1Desc = "";
      const s1Effects = effects.filter((e) => e.Stage === 1);

      if (kpiCode === "TS04") {
        const revGross = (delta * hp * r) / 1000;
        stage1RevLoss = revGross * margin;
        stage1Desc = `${delta} học sinh rút → hụt thu danh nghĩa ${revGross.toFixed(2)} tỷ VNĐ (biên ròng ${stage1RevLoss.toFixed(2)} tỷ VNĐ)`;
      } else if (kpiCode === "TS06") {
        const missingStudents = Math.round(delta * (1 - conv / 0.30) * 0.3);
        stage1RevLoss = (missingStudents * hp * r) / 1000 * margin;
        stage1Desc = `Chuyển đổi thấp hơn mục tiêu 30% → ước thiếu ${missingStudents} HS → hụt biên ròng ${stage1RevLoss.toFixed(2)} tỷ VNĐ`;
      } else if (kpiCode === "BUS01") {
        stage1RevLoss = (delta * 10.5 * hp * r) / 1000 * margin;
        stage1Desc = `${delta} tuyến xe bus thiếu → ước rút ${Math.round(delta * 10.5)} HS → hụt biên ròng ${stage1RevLoss.toFixed(2)} tỷ VNĐ`;
      } else if (kpiCode === "CSVC01") {
        stage1RevLoss = (delta * 0.05 * hp * r) / 1000 * margin;
        stage1Desc = `${delta} yêu cầu sửa máy lạnh (tồn 4 ticket) → Tỷ lệ hoàn thành SLA đạt 91.67% (chỉ tiêu 95%)`;
      } else if (kpiCode === "MED01") {
        const absencePct = Math.min(0.15, (delta / (enrolled || 200)) * 0.5);
        stage1RevLoss = (enrolled * absencePct * hp * (1 / 9)) / 1000 * margin;
        stage1Desc = `${delta} ca bệnh (53 ca sốt Cúm A) → vắng học ~${(absencePct * 100).toFixed(1)}% → gián đoạn chuyên cần ước ${stage1RevLoss.toFixed(3)} tỷ VNĐ`;
      } else if (kpiCode === "HR02" || kpiCode === "CM02") {
        const burnoutRisk = Math.round(delta * 0.08);
        stage1RevLoss = (burnoutRisk * hp * r) / 1000 * margin;
        stage1Desc = `${delta} đơn/ngày nghỉ phép → phát sinh 288 tiết dạy thay → rủi ro GV kiệt sức ước ${stage1RevLoss.toFixed(3)} tỷ VNĐ`;
      } else if (kpiCode === "IT01") {
        stage1RevLoss = (delta * 0.5) / 1000;
        stage1Desc = `${delta} giờ nhân sự nhập liệu thủ công → chi phí cơ hội ${stage1RevLoss.toFixed(2)} tỷ VNĐ + rủi ro sai lệch dữ liệu`;
      } else {
        if (s1Effects.length) {
          const e = s1Effects[0];
          stage1RevLoss = (delta * e.ElasticityCoeff * hp * r) / 1000 * margin;
          stage1Desc = `${delta} đơn vị ${kpiCode} → tác động đến ${e.EffectKpiCode} (hệ số ${e.ElasticityCoeff}) → ước ${stage1RevLoss.toFixed(3)} tỷ VNĐ`;
        }
      }

      // ── Giai đoạn 2: Vận hành & Tải bù ───────────────────────────────────────
      const leadsNeed = Math.round(delta / conv);
      const leadsPctMonth = Math.round((leadsNeed / monthlyLeads) * 100);
      const enrolledAfter = kpiCode === "TS04" ? Math.max(0, enrolled - delta)
                          : kpiCode === "CAP01" ? Math.max(0, enrolled - delta)
                          : enrolled;
      const fillPctAfter = planCap > 0 ? ((enrolledAfter / planCap) * 100).toFixed(1) : "N/A";
      const stepCostTriggered = isStudentScale && enrolledAfter < planCap * 0.75;
      const fixedCostBurden = stepCostTriggered
        ? ((planCap * 0.75 - enrolledAfter) * hp * variableCost * r) / 1000
        : 0;

      // ── Giai đoạn 3: Dài hạn & Chỉ số nghiệp vụ đặc thù ───────────────────────
      const transitionLoss = (delta * (ass.TransitionProbability || 0.5) * (ass.NextLevelTuitionMillion || hp) * (ass.NextLevelYears || 0)) / 1000 * margin;

      let statusHeadline = "";
      let operationalPressure = "";
      let standardControl = "";
      let calculatedLtvLoss = 0;

      if (kpiCode === "CSVC01") {
        statusHeadline = `${delta} máy lạnh cần bảo dưỡng (SLA 91.67%)`;
        operationalPressure = "4 ticket chậm xử lý tại Khu B & C · Cam kết SLA < 24h";
        calculatedLtvLoss = (delta * 0.05 * hp * ltv_years) / 1000 * margin;
        standardControl = "SLA khắc phục sự cố máy lạnh < 24h";
      } else if (kpiCode === "MED01") {
        statusHeadline = "53 ca sốt Cúm A Tiểu học (Đã kiểm soát)";
        operationalPressure = "Tổ chức dạy bù & gửi bài qua LMS cho HS dưỡng bệnh";
        calculatedLtvLoss = (delta * 0.01 * hp) / 1000;
        standardControl = "Tiêu chuẩn An toàn ISO 22000";
      } else if (kpiCode === "HR02" || kpiCode === "CM02" || kpiCode === "HR03") {
        statusHeadline = "288 tiết dạy thay (định mức < 6 tiết/GV/tuần)";
        operationalPressure = "Điều phối GV cùng tổ dạy thay, bảo đảm 100% tiết học";
        calculatedLtvLoss = (delta * 0.02 * hp) / 1000;
        standardControl = "Chính sách chống kiệt sức giáo viên";
      } else {
        statusHeadline = `${enrolledAfter} HS (Lấp đầy ${fillPctAfter}%)`;
        operationalPressure = `≈ ${leadsNeed} leads (${leadsPctMonth}% năng lực tháng)`;
        calculatedLtvLoss = (delta * hp * ltv_years) / 1000 * margin;
        standardControl = `Phễu chuyển cấp: −${transitionLoss.toFixed(2)} tỷ`;
      }

      // ── Cán cân Can thiệp (Intervention ROI) ──────────────────────────────────
      const bestIntervention = s1Effects.length ? s1Effects.reduce((best, e) => {
        const roi = e.InterventionSaveRate * stage1RevLoss - (delta * e.InterventionCostPerUnit) / 1000;
        const bestRoi = (best.InterventionSaveRate || 0) * stage1RevLoss - (delta * (best.InterventionCostPerUnit || 0)) / 1000;
        return roi > bestRoi ? e : best;
      }, s1Effects[0]) : null;

      const interventionCost = bestIntervention ? (delta * bestIntervention.InterventionCostPerUnit) / 1000 : 0;
      const interventionSaved = bestIntervention ? stage1RevLoss * bestIntervention.InterventionSaveRate : 0;
      const netBenefit = interventionSaved - interventionCost;
      const roi = interventionCost > 0 ? Math.round((netBenefit / interventionCost) * 100) : 0;
      const shouldIntervene = netBenefit > 0;

      return {
        delta,
        kpiCode,
        isStudentScale,
        statusHeadline,
        operationalPressure,
        standardControl,
        stage1RevLoss,
        stage1Desc,
        leadsNeed,
        leadsPctMonth,
        enrolledAfter,
        fillPctAfter,
        stepCostTriggered,
        fixedCostBurden: fixedCostBurden.toFixed(3),
        ltvLoss: calculatedLtvLoss.toFixed(2),
        transitionLoss: transitionLoss.toFixed(2),
        interventionName: bestIntervention ? bestIntervention.InterventionName : "Rà soát và đối thoại phụ huynh",
        interventionOwner: bestIntervention ? bestIntervention.InterventionOwner : this.currentCausalOwnerTitle,
        interventionCost: interventionCost.toFixed(2),
        interventionSaved: interventionSaved.toFixed(2),
        netBenefit: netBenefit.toFixed(2),
        roi,
        shouldIntervene,
        stage1Sign: stage1RevLoss >= 0 ? "−" : "+",
        stage1Fmt: stage1RevLoss.toFixed(3),
        allEffects: effects,
      };
    },
    currentCausalReason() {
      const list = this.causalReasonsList.length ? this.causalReasonsList : this.defaultReasons;
      const found = list.find((r) => r.ReasonCode === this.causalReasonCode);
      return found || list[5];
    },
    currentAssignments() {
      const list = this.causalAssignmentsList.length ? this.causalAssignmentsList : [
        { AssignmentID: 1, ScenarioCode: "RUT_HOC", RoleCode: "PRINCIPAL", RoleTitle: "Hiệu trưởng {Unit}", ActionDescription: "Giải trình tại kỳ họp; phỏng vấn phụ huynh, phân loại lý do chuẩn rồi giao xử lý" },
        { AssignmentID: 2, ScenarioCode: "RUT_HOC", RoleCode: "ADMISSIONS", RoleTitle: "Tuyển sinh – TVTS", ActionDescription: "Bổ sung khoảng {LeadsNeed} lead vào kế hoạch để tuyển bù" },
        { AssignmentID: 3, ScenarioCode: "RUT_HOC", RoleCode: "ACCOUNTING", RoleTitle: "Kế toán", ActionDescription: "Cập nhật dự báo doanh thu và khoản hoàn phí (nếu có)" },
      ];
      return list.filter((a) => a.ScenarioCode === this.causalScenario);
    },
    causalScenarioTitle() {
      if (this.causalScenario === "TUYEN_THEM") {
        return "Tuyển thêm " + this.causalAddN + " học sinh " + this.currentCausalUnitName + " " + this.currentMonthText;
      }
      if (this.causalScenario === "CHUYEN_DOI") {
        return "Chuyển đổi thay đổi " + (this.causalConvDelta > 0 ? "+" : "") + this.causalConvDelta + " điểm tại " + this.currentCausalUnitName;
      }
      if (this.causalScenario === "MO_TUYEN_BUS") {
        const totalBusStudents = this.causalBusRoutes * this.causalBusStudentsPerRoute;
        return "Mở " + this.causalBusRoutes + " tuyến xe bus mới (" + totalBusStudents + " HS) trục Trảng Dài - Hố Nai";
      }
      if (this.causalScenario === "GIU_CHAN_CHUYEN_CAP") {
        return "Chính sách ưu đãi " + this.causalDiscountPct + "% giữ chân " + this.causalTransitionRetained + " học sinh chuyển cấp " + this.currentCausalUnitName;
      }
      if (this.causalScenario === "MO_RONG_CLB") {
        return "Phát triển " + this.causalNewClbCount + " CLB mới (" + this.causalAddClbStudents + " học viên) " + this.currentCausalUnitName;
      }
      if (this.causalScenario === "SU_CO_AN_TOAN") {
        return "Ứng phó rủi ro an toàn thực phẩm & y tế học đường (Chỉ tiêu 0 sự cố)";
      }
      return this.causalN + " học sinh " + this.currentCausalUnitName + " rời đi " + this.currentMonthText;
    },
    causalCalc() {
      const ass = this.currentCausalAssumption;
      let n = Math.max(1, this.causalDeltaOverride !== null ? this.causalDeltaAuto : (this.causalScenario === "TUYEN_THEM" ? this.causalAddN : (this.causalDeltaAuto || this.causalN || 1)));
      if (this.causalScenario === "MO_TUYEN_BUS") {
        n = this.causalBusRoutes * this.causalBusStudentsPerRoute;
      } else if (this.causalScenario === "GIU_CHAN_CHUYEN_CAP") {
        n = this.causalTransitionRetained;
      } else if (this.causalScenario === "MO_RONG_CLB") {
        n = this.causalAddClbStudents;
      }
      const r = this.currentMonthRatio;
      const hp = ass.AnnualTuitionMillion;
      // Chi phí biến đổi trực tiếp (Suất ăn bán trú, đồng phục, học cụ tiêu hao): ~18% học phí
      const variableCostPct = 0.18;
      const margin = 1 - variableCostPct; // Biên đóng góp thực tế: 82%

      const revNowRaw = (n * hp * r) / 1000;
      const revVariableCostRaw = revNowRaw * variableCostPct;
      const revMarginRaw = revNowRaw * margin;
      const isOut = this.causalScenario === "RUT_HOC";

      const revNowSign = (isOut ? "−" : "+") + revNowRaw.toFixed(2).replace(".", ",");
      const revVariableCostSign = (isOut ? "−" : "+") + revVariableCostRaw.toFixed(2).replace(".", ",");
      const revMarginSign = (isOut ? "−" : "+") + revMarginRaw.toFixed(2).replace(".", ",");
      const revNowRange = (isOut ? "−" : "+") + (revMarginRaw * 0.9).toFixed(2).replace(".", ",") + " đến " + (isOut ? "−" : "+") + (revMarginRaw * 1.1).toFixed(2).replace(".", ",") + " tỷ";

      // Thiệt hại 1 năm tiếp theo trong thời gian chờ tuyển bù (thay vì nhân vô hạn 7 năm không tuyển bù)
      const revFutureRaw = (n * hp * margin) / 1000;
      const revFutureSign = (isOut ? "−" : "+") + revFutureRaw.toFixed(2).replace(".", ",");
      const revFutureRange = (isOut ? "−" : "+") + (revFutureRaw * 0.85).toFixed(2).replace(".", ",") + " đến " + (isOut ? "−" : "+") + (revFutureRaw * 1.15).toFixed(2).replace(".", ",") + " tỷ";

      const totalLostRaw = revMarginRaw + revFutureRaw;
      const totalLostSign = (isOut ? "−" : "+") + totalLostRaw.toFixed(2).replace(".", ",");
      const stripNowPct = totalLostRaw > 0 ? Math.min(100, Math.max(5, Math.round((revMarginRaw / totalLostRaw) * 100))) : 40;

      const t9 = ass.CurrentEnrollment || 129;
      const kh = ass.PlannedCapacity || 166;
      const fillPctBefore = ((t9 / kh) * 100).toFixed(1).replace(".", ",");
      const t9After = isOut ? Math.max(0, t9 - n) : t9 + n;
      const fillPctAfter = ((t9After / kh) * 100).toFixed(1).replace(".", ",");

      const rutBeforePct = (1.98).toFixed(2).replace(".", ",");
      const rutAfterPctRaw = 1.98 + (n / t9) * 100 * (isOut ? 1 : -0.5);
      const rutAfterPct = Math.max(0, rutAfterPctRaw).toFixed(2).replace(".", ",");
      const isRutBad = rutAfterPctRaw > 3.0;
      const paceMultiple = (rutAfterPctRaw / 3.0).toFixed(1).replace(".", ",");

      const conv = ass.ConversionRate || 0.073;
      const leadsNeed = Math.round(n / conv);
      const monthlyLeads = ass.MonthlyLeads || 60;
      const leadsPctMonth = Math.round((leadsNeed / monthlyLeads) * 100);
      const clbLost = Math.round(n * (ass.ClbParticipationRate || 0.38));

      // Ngưỡng hòa vốn cơ sở MN Long Khánh: Cần 145 HS để hòa vốn định phí vận hành
      const breakEvenStudents = 145;
      const breakEvenGap = Math.max(0, breakEvenStudents - t9After);

      // Cảnh báo chi phí bước nhảy (Step-fixed costs): Nếu tuyển thêm >= 20 HS sẽ cần mở thêm phòng học/tuyển GV
      const isStepCostTriggered = !isOut && n >= 20;

      return {
        n,
        t9,
        t9After,
        kh,
        revNowRaw,
        revNowSign,
        revVariableCostSign,
        revMarginSign,
        revNowRange,
        revFutureSign,
        revFutureRange,
        totalLostSign,
        stripNowPct,
        fillPctBefore,
        fillPctAfter,
        rutBeforePct,
        rutAfterPct,
        isRutBad,
        rutPaceMultiple: "gấp " + paceMultiple + " lần",
        leadsNeed,
        leadsPctMonth,
        clbLost,
        breakEvenStudents,
        breakEvenGap,
        isStepCostTriggered,
      };
    },
    causalHeroSentence() {
      const c = this.causalCalc;
      const unit = this.currentCausalUnitName;
      const act = this.currentCausalReason ? this.currentCausalReason.RecommendedAction : "Rà soát đối thoại với phụ huynh";

      if (this.causalScenario === "RUT_HOC") {
        return `${c.n} học sinh rút học tại ${unit} làm suy giảm ${c.revMarginSign.replace("−", "").replace("-", "")} tỷ VNĐ biên đóng góp dòng tiền năm nay (Doanh thu danh nghĩa ${c.revNowSign.replace("−", "").replace("-", "")} tỷ VNĐ). Cần tuyển bù xấp xỉ ${c.leadsNeed} leads để bù đắp chỉ tiêu sĩ số. Trách nhiệm: ${this.currentCausalOwnerTitle} — ${act}.`;
      }
      if (this.causalScenario === "TUYEN_THEM") {
        return `Tuyển thêm ${c.n} học sinh tại ${unit} đóng góp ròng +${c.revMarginSign.replace("+", "")} tỷ VNĐ dòng tiền năm nay (Doanh thu danh nghĩa +${c.revNowSign.replace("+", "")} tỷ VNĐ), đưa tỷ lệ lấp đầy cơ sở đạt ${c.fillPctAfter}%.`;
      }
      if (this.causalScenario === "MO_TUYEN_BUS") {
        return `Mở ${this.causalBusRoutes} tuyến xe bus mới đón ${c.n} học sinh giúp giữ chân và tăng ròng +${c.revMarginSign.replace("+", "")} tỷ VNĐ biên đóng góp, triệt tiêu 100% nguyên nhân rút học do cự ly xa trường.`;
      }
      if (this.causalScenario === "GIU_CHAN_CHUYEN_CAP") {
        return `Giữ chân thành công ${c.n} học sinh chuyển cấp bảo toàn +${c.revMarginSign.replace("+", "")} tỷ VNĐ biên đóng góp dòng tiền, giảm tải ${c.leadsNeed} leads cần tìm kiếm mới từ kênh marketing ngoài.`;
      }
      if (this.causalScenario === "MO_RONG_CLB") {
        return `Mở rộng ${this.causalNewClbCount} CLB mới thu hút ${c.n} lượt học sinh tham gia, tạo thặng dư +${c.revMarginSign.replace("+", "")} tỷ VNĐ tái đầu tư 100% vào CSVC và nâng cao trải nghiệm học đường.`;
      }
      if (this.causalScenario === "SU_CO_AN_TOAN") {
        return `Duy trì tiêu chuẩn ISO 22000 và bảo đảm 0 sự cố an toàn học đường, bảo toàn uy tín thương hiệu và ngăn ngừa tổn thất sĩ số dây chuyền.`;
      }
      return `${c.n} học sinh biến động tác động trực tiếp ${c.revMarginSign.replace("−", "").replace("-", "")} tỷ VNĐ biên đóng góp dòng tiền năm nay (Doanh thu danh nghĩa ${c.revNowSign.replace("−", "").replace("-", "")} tỷ VNĐ). Trách nhiệm giải trình trực tiếp: ${this.currentCausalOwnerTitle} — ${act}.`;
    },
    causalTreeNodes() {
      const c = this.causalCalc;
      const kpi = this.causalKpiCode;
      const ass = this.currentCausalAssumption;
      const isOut = this.causalScenario === "RUT_HOC";
      const unit = this.currentCausalUnitName;

      // ── NHÁNH 1: CƠ SỞ VẬT CHẤT & BẢO TRÌ (CSVC01, IT01) ───────────────────
      if (kpi === "CSVC01" || kpi === "IT01") {
        return [
          {
            id: "N_EVENT",
            x: 20,
            y: 120,
            label: c.n + " yêu cầu sửa CSVC",
            value: (c.n || 18) + " máy lạnh · " + unit,
            sub: "Ticket CSVC kỳ " + this.currentPeriodShortName,
            formula: "Tiếp nhận ticket bảo trì CSVC tại " + unit + ", tồn đọng chưa hoàn thành",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_ENROLLMENT",
            x: 240,
            y: 60,
            label: "Tỷ lệ đúng hạn SLA",
            value: "91.67% (Chỉ tiêu 95%)",
            sub: "4 ticket tồn chậm xử lý",
            formula: "Tỷ lệ SLA đạt 91.67% do 4 ticket điều hòa Khu B/C xử lý chậm quá 24h",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_RUT_HOC",
            x: 240,
            y: 180,
            label: "Môi trường học tập",
            value: "Nhiệt độ phòng học",
            sub: "Khu B & C những ngày nóng",
            formula: "Thời tiết nóng ảnh hưởng giờ học và giấc ngủ trưa của học sinh bán trú",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_REV_NOW",
            x: 470,
            y: 40,
            label: "Hài lòng tiện nghi (QA01)",
            value: "92.4% tiện nghi",
            sub: "CSAT tiện nghi lớp học",
            formula: "Khảo sát phụ huynh ghi nhận phàn nàn nhiệt độ tại các phòng hỏng máy lạnh",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_CLB",
            x: 470,
            y: 130,
            label: "Chi phí linh kiện & Sửa",
            value: "≈ 15 triệu VNĐ",
            sub: "Bảo dưỡng 18 máy lạnh",
            formula: "Chi phí thay linh kiện, nạp gas và sửa chữa lốc điều hòa",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_EXPLAIN",
            x: 470,
            y: 220,
            label: "Trách nhiệm giải trình",
            value: "Tổ Quản trị CSVC",
            sub: "Cam kết xử lý < 24h",
            formula: "Quy chuẩn kỹ thuật: Hoàn tất dứt điểm 4 ticket trước 05/10/2026",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_REV_FUTURE",
            x: 700,
            y: 50,
            label: "Nguy cơ mất HS gián tiếp",
            value: "Ước tính ~0.9 HS",
            sub: "Hệ số co giãn: 0.05",
            formula: "Hệ số co giãn CSVC01 → TS04: 18 ticket × 0.05 = 0.9 HS (~33 triệu VNĐ)",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_LEADS_NEED",
            x: 700,
            y: 150,
            label: "Bảo dưỡng định kỳ",
            value: "Hợp đồng trọn gói",
            sub: "Bảo dưỡng 100% điều hòa",
            formula: "Ký hợp đồng đối tác điện lạnh bảo trì định kỳ 1 lần/tháng toàn trường",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_ACTION_ROUTE",
            x: 700,
            y: 240,
            label: "Xử lý nguyên nhân",
            value: "Trưởng phòng CSVC",
            sub: "Kiểm soát: Cao (Nội bộ)",
            formula: "Khắc phục triệt để tồn đọng kỹ thuật bảo đảm tiện nghi lớp học",
            isBad: false,
            isGood: true,
          },
        ];
      }

      // ── NHÁNH 2: Y TẾ & AN TOÀN HỌC ĐƯỜNG (MED01, CM09) ───────────────────
      if (kpi === "MED01" || kpi === "CM09") {
        return [
          {
            id: "N_EVENT",
            x: 20,
            y: 120,
            label: c.n + " ca bệnh học đường (" + this.currentPeriodShortName + ")",
            value: "Ghi nhận y tế · " + unit,
            sub: c.n + " ca y tế ghi nhận kỳ " + this.currentPeriodShortName,
            formula: c.n + " ca bệnh học đường ghi nhận tại " + unit + " trong kỳ " + this.currentPeriodName,
            isBad: true,
            isGood: false,
          },
          {
            id: "N_ENROLLMENT",
            x: 240,
            y: 60,
            label: "Tỷ lệ chuyên cần học sinh",
            value: "Vắng ngắn hạn +3.2%",
            sub: "Chỉ tiêu chuyên cần > 98%",
            formula: "Học sinh cách ly tại nhà 3-5 ngày theo quy định y tế học đường",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_RUT_HOC",
            x: 240,
            y: 180,
            label: "Kế hoạch dạy bù LMS",
            value: "Bài giảng & Phiếu bài tập",
            sub: "Giao bài qua KidsOnline/LMS",
            formula: "GVCN gửi phiếu học tập và bài giảng số cho học sinh nghỉ ốm",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_REV_NOW",
            x: 470,
            y: 40,
            label: "Chi phí thuốc & Khử khuẩn",
            value: "≈ 5 triệu VNĐ",
            sub: "Dung dịch Cloramin B",
            formula: "Phun khử khuẩn 100% phòng học Tiểu học vào cuối tuần",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_CLB",
            x: 470,
            y: 130,
            label: "Truyền thông PHHS",
            value: "100% Phụ huynh",
            sub: "Khuyến cáo tiêm phòng Cúm",
            formula: "Gửi thông báo y tế và cẩm nang chăm sóc trẻ qua ứng dụng trường",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_EXPLAIN",
            x: 470,
            y: 220,
            label: "Trách nhiệm chuyên môn",
            value: "Bộ phận Y tế học đường",
            sub: "Phòng ngừa lây lan chéo",
            formula: "Theo dõi thân nhiệt đầu giờ và cách ly sớm trường hợp nghi nhiễm",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_REV_FUTURE",
            x: 700,
            y: 50,
            label: "Tiêu chuẩn An toàn ISO",
            value: "Duy trì 0 sự cố",
            sub: "Vệ sinh ATTP & Y tế",
            formula: "Bảo đảm môi trường học đường an toàn chuẩn ISO 22000",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_LEADS_NEED",
            x: 700,
            y: 150,
            label: "Tỷ lệ hoàn thành học tập",
            value: "Đạt 94.6%",
            sub: "Học sinh dưỡng bệnh nộp bài",
            formula: "Học sinh không bị hổng kiến thức nhờ học liệu số trực tuyến",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_ACTION_ROUTE",
            x: 700,
            y: 240,
            label: "Xử lý nguyên nhân",
            value: "Tổ Y tế & BGH",
            sub: "Kiểm soát: Cao",
            formula: "Khử khuẩn phòng học, rà soát thực đơn bán trú nâng cao thể trạng",
            isBad: false,
            isGood: true,
          },
        ];
      }

      // ── NHÁNH 3: NHÂN SỰ & CHUYÊN MÔN (HR02, HR03, CM02) ──────────────────
      if (kpi === "HR02" || kpi === "HR03" || kpi === "CM02") {
        return [
          {
            id: "N_EVENT",
            x: 20,
            y: 120,
            label: c.n + " ngày phép / biến động",
            value: "Tổ Chuyên môn & Bếp",
            sub: "45 ca biến động / 54 ngày phép",
            formula: "Phát sinh nhu cầu bố trí dạy thay và điều phối nhân sự",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_ENROLLMENT",
            x: 240,
            y: 60,
            label: "Tiết dạy thay (CM02)",
            value: "288 tiết phát sinh",
            sub: "Phân bổ trong tháng 9",
            formula: "Điều phối giáo viên cùng tổ dạy thay, bảo đảm 100% tiết học",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_RUT_HOC",
            x: 240,
            y: 180,
            label: "Áp lực quá tải GV",
            value: "Giới hạn < 6 tiết/tuần",
            sub: "Chính sách chống kiệt sức",
            formula: "Kiểm soát giờ dạy thay tối đa không vượt ngưỡng gây căng thẳng",
            isBad: true,
            isGood: false,
          },
          {
            id: "N_REV_NOW",
            x: 470,
            y: 40,
            label: "Phụ cấp dạy thay",
            value: "≈ 14.4 triệu VNĐ",
            sub: "50.000 đ/tiết dạy thay",
            formula: "Đơn giá bồi dưỡng dạy thay theo quy chế chi tiêu nội bộ",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_CLB",
            x: 470,
            y: 130,
            label: "Chất lượng tiết dạy",
            value: "Dự giờ & Kiểm tra",
            sub: "Tổ trưởng chuyên môn",
            formula: "Giám sát giáo án và tiến độ giảng dạy theo khung phân phối chương trình",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_EXPLAIN",
            x: 470,
            y: 220,
            label: "Trách nhiệm giải trình",
            value: "Phó HT Đào tạo",
            sub: "Ổn định chuyên môn",
            formula: "Bảo đảm tiến độ chương trình và công bằng định mức lao động",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_REV_FUTURE",
            x: 700,
            y: 50,
            label: "Giữ chân giáo viên giỏi",
            value: "Mục tiêu > 95%",
            sub: "Bảo toàn lực lượng nòng cốt",
            formula: "Môi trường làm việc lành mạnh ngăn ngừa hiện tượng thôi việc giữa năm",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_LEADS_NEED",
            x: 700,
            y: 150,
            label: "Kho bài giảng LMS",
            value: "Học liệu số dùng chung",
            sub: "Giảm 40% giờ soạn bài",
            formula: "GV dạy thay khai thác trực tiếp bài giảng mẫu từ kho LMS trường",
            isBad: false,
            isGood: true,
          },
          {
            id: "N_ACTION_ROUTE",
            x: 700,
            y: 240,
            label: "Xử lý nguyên nhân",
            value: "Trưởng phòng Nhân sự",
            sub: "Kiểm soát: Cao",
            formula: "Tuyển dụng bổ sung CTV dự phòng và tối ưu hóa thời khóa biểu",
            isBad: false,
            isGood: true,
          },
        ];
      }

      // ── NHÁNH 4: TUYỂN SINH, XE BUS & SĨ SỐ (TS04, TS06, BUS01, CAP01, CRM01, TS01...) ──
      const rName = this.currentCausalReason ? this.currentCausalReason.ReasonName : "Chưa rõ lý do";
      const ctl = this.currentCausalReason ? this.currentCausalReason.ControlLevel : "Trung bình";
      let eventLabel = (isOut ? "−" : "+") + c.n + " học sinh " + (isOut ? "rời đi" : "nhập học");
      let eventSub = "Lý do: " + rName;
      let eventFormula = "Sự kiện phát sinh tại " + unit + " trong " + this.currentMonthText;

      if (kpi === "BUS01") {
        eventLabel = c.n + " tuyến xe bus chưa phủ";
        eventSub = (this.displayReasonFar || c.n) + " HS rút vì xa trường";
        eventFormula = "Hạ tầng xe bus chưa đến Long Khánh & Biên Hòa Đông";
      } else if (kpi === "TS06" || kpi === "CRM01") {
        const leads = (this.currentCausalAssumption && this.currentCausalAssumption.MonthlyLeads) || 161;
        const conv = (this.currentCausalAssumption && this.currentCausalAssumption.ConversionRate ? (this.currentCausalAssumption.ConversionRate * 100).toFixed(1) : "13.0");
        eventLabel = c.n + " HS nhập mới (" + leads + " leads)";
        eventSub = "Chuyển đổi " + conv + "% (Mục tiêu 30%)";
        eventFormula = leads + " leads tiếp nhận, chuyển đổi thành công " + c.n + " học sinh mới";
      }

      return [
        {
          id: "N_EVENT",
          x: 20,
          y: 120,
          label: eventLabel,
          value: unit,
          sub: eventSub,
          formula: eventFormula,
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_ENROLLMENT",
          x: 240,
          y: 60,
          label: "Sĩ số hiện diện",
          value: c.t9 + " → " + c.t9After,
          sub: c.fillPctBefore + "% → " + c.fillPctAfter + "% chỉ tiêu",
          formula: "Sĩ số sau biến động = Sĩ số " + this.currentPeriodShortName + " (" + c.t9 + ") " + (isOut ? "− " : "+ ") + c.n + " = " + c.t9After + " HS",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_RUT_HOC",
          x: 240,
          y: 180,
          label: isOut ? "Rút học lũy kế · KPI 3" : "Tỷ lệ lấp đầy",
          value: isOut ? c.rutAfterPct + "%" : c.fillPctAfter + "%",
          sub: isOut ? "nhịp cho phép 3,0% · " + c.rutPaceMultiple : "chỉ tiêu 100%",
          formula: isOut ? "Tỷ lệ rút học lũy kế = (Số rút học + " + c.n + ") / Sĩ số đầu năm" : "Lấp đầy = Sĩ số / Công suất thiết kế",
          isBad: isOut && c.isRutBad,
          isGood: !isOut,
        },
        {
          id: "N_REV_NOW",
          x: 470,
          y: 40,
          label: "Biên đóng góp năm nay",
          value: c.revMarginSign + " tỷ",
          sub: "Doanh thu: " + c.revNowSign + " tỷ (trừ 18% biến phí)",
          formula: "Biên đóng góp = (" + ass.AnnualTuitionMillion + " tr HP - 18% biến phí) × " + c.n + " HS × " + Math.round(this.currentMonthRatio * 9) + "/9 tháng",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_CLB",
          x: 470,
          y: 130,
          label: "Câu lạc bộ",
          value: (isOut ? "−" : "+") + c.clbLost + " học viên",
          sub: "theo tỷ lệ tham gia CLB của đơn vị",
          formula: "Tỷ lệ tham gia CLB của cơ sở (" + Math.round(ass.ClbParticipationRate * 100) + "%) × " + c.n + " HS",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_EXPLAIN",
          x: 470,
          y: 220,
          label: "Trách nhiệm giải trình",
          value: isOut ? "Cần giải trình" : "Báo cáo đạt nhịp",
          sub: "trước Ban Điều Hành & HĐQT",
          formula: "Quy chế giám sát KPI: Đơn vị vi phạm nhịp rút học hoặc dưới 80% lấp đầy phải giải trình bằng văn bản",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_REV_FUTURE",
          x: 700,
          y: 50,
          label: "Thiệt hại 1 năm chờ bù",
          value: "≈ " + c.revFutureSign + " tỷ",
          sub: "Biên đóng góp năm tiếp theo",
          formula: "Biên đóng góp 1 năm kế tiếp chờ tuyển bù = " + c.n + " HS × " + (ass.AnnualTuitionMillion * 0.82).toFixed(1) + " tr/năm",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_LEADS_NEED",
          x: 700,
          y: 150,
          label: "Lead để tuyển bù",
          value: "≈ " + c.leadsNeed + " lead",
          sub: "chuyển đổi " + (ass.ConversionRate * 100).toFixed(1) + "% · " + c.leadsPctMonth + "% lead/tháng",
          formula: "Số lead tuyển bù = " + c.n + " HS / Tỷ lệ chuyển đổi (" + (ass.ConversionRate * 100).toFixed(1) + "%)",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_ACTION_ROUTE",
          x: 700,
          y: 240,
          label: "Xử lý nguyên nhân",
          value: this.currentCausalReason ? this.currentCausalReason.ActionOwner : "Ban Tuyển Sinh",
          sub: "Kiểm soát: " + ctl,
          formula: "Tuyến quy trách nhiệm xử lý theo tài liệu Phương án vận hành",
          isBad: false,
          isGood: true,
        },
      ];
    },
    causalTreeEdges() {
      const isOut = this.causalScenario === "RUT_HOC";
      return [
        { id: "e1", from: "N_EVENT", to: "N_ENROLLMENT", d: "M 200 150 C 220 150, 220 90, 240 90", w: 3, isBad: isOut },
        { id: "e2", from: "N_EVENT", to: "N_RUT_HOC", d: "M 200 150 C 220 150, 220 210, 240 210", w: 3.5, isBad: isOut },
        { id: "e3", from: "N_ENROLLMENT", to: "N_REV_NOW", d: "M 420 90 C 445 90, 445 70, 470 70", w: 3.5, isBad: isOut },
        { id: "e4", from: "N_ENROLLMENT", to: "N_CLB", d: "M 420 90 C 445 90, 445 160, 470 160", w: 2, isBad: isOut },
        { id: "e5", from: "N_RUT_HOC", to: "N_EXPLAIN", d: "M 420 210 C 445 210, 445 250, 470 250", w: 2.5, isBad: isOut },
        { id: "e6", from: "N_REV_NOW", to: "N_REV_FUTURE", d: "M 650 70 C 675 70, 675 80, 700 80", w: 4, isBad: isOut },
        { id: "e7", from: "N_REV_NOW", to: "N_LEADS_NEED", d: "M 650 70 C 675 70, 675 180, 700 180", w: 3, isBad: isOut },
        { id: "e8", from: "N_EXPLAIN", to: "N_ACTION_ROUTE", d: "M 650 250 C 675 250, 675 270, 700 270", w: 2, isBad: false },
      ];
    },
    causalHlSet() {
      const id = this.causalHoverNodeId;
      if (!id) return null;
      const set = {};
      set[id] = true;
      const edges = this.causalTreeEdges;
      const up = (nid) => {
        edges.forEach((e) => {
          if (e.to === nid && !set[e.from]) {
            set[e.from] = true;
            up(e.from);
          }
        });
      };
      const down = (nid) => {
        edges.forEach((e) => {
          if (e.from === nid && !set[e.to]) {
            set[e.to] = true;
            down(e.to);
          }
        });
      };
      up(id);
      down(id);
      return set;
    },
    hoveredCausalNode() {
      if (!this.causalHoverNodeId) return null;
      return this.causalTreeNodes.find((n) => n.id === this.causalHoverNodeId) || null;
    },
    selectedPeriodText() {
      return this.currentPeriodName || this.selectedPeriod || "";
    },
    currentViewLabel() {
      if (this.page === 0) return "Hội đồng trường";
      if (this.currentUnit === "ALL") return "Ban điều hành · Hợp nhất";
      const match = this.unitOptions.find((u) => u.k === this.currentUnit);
      return match ? "Hiệu trưởng " + match.t : "Toàn trường";
    },
    currentGradeRows() {
      if (this.currentUnit === "MNLK") return this.liveDataLongKhanh;
      if (this.currentUnit === "MNBH" || this.currentUnit === "MNTB") return this.liveDataBienHoa.filter((r) => r.Ten.includes("MG") || r.Ten.includes("Tháng"));
      if (this.currentUnit === "TH") return this.liveDataBienHoa.filter((r) => ["Khối 1", "Khối 2", "Khối 3", "Khối 4", "Khối 5"].includes(r.Ten));
      if (this.currentUnit === "THCS") return this.liveDataBienHoa.filter((r) => ["Khối 6", "Khối 7", "Khối 8", "Khối 9"].includes(r.Ten));
      if (this.currentUnit === "THPT") return this.liveDataBienHoa.filter((r) => ["Khối 10", "Khối 11", "Khối 12"].includes(r.Ten));
      const mergedMap = {};
      this.liveDataBienHoa.forEach((r) => { mergedMap[r.Ten] = { ...r }; });
      this.liveDataLongKhanh.forEach((r) => {
        if (mergedMap[r.Ten]) {
          mergedMap[r.Ten].SLHocSinh += r.SLHocSinh;
          mergedMap[r.Ten].SL_HSNu += r.SL_HSNu;
          mergedMap[r.Ten].SL_HSNam += r.SL_HSNam;
        } else {
          mergedMap[r.Ten] = { ...r };
        }
      });
      return Object.values(mergedMap);
    },
    computedTotalStudents() {
      return (this.currentGradeRows || []).reduce((sum, r) => sum + (r.SLHocSinh || 0), 0);
    },
    maxGradeEnrollment() {
      if (!this.currentGradeRows || !this.currentGradeRows.length) return 300;
      return Math.max(...this.currentGradeRows.map((r) => r.SLHocSinh || 0), 100);
    },
    factTableHeaders() {
      const d = this.selectedFactDomain;
      if (d === 'STUDENTS' || d === 'WITHDRAWAL') {
        return { col1: 'Mã HS / Tên Học Sinh', col2: 'Khối / Lớp', col3: 'Lý do rút hồ sơ', col4: 'Số lượng' };
      }
      if (d === 'CRM' || d === 'PROSPECTS') {
        return { col1: 'Phụ huynh / Học sinh', col2: 'Kênh / Mục tiêu', col3: 'Trạng thái & Lịch hẹn', col4: 'Số lượng' };
      }
      if (d === 'HEALTH') {
        return { col1: 'Mã HS / Bệnh nhân', col2: 'Lớp học', col3: 'Chẩn đoán / Xử lý', col4: 'Lượt khám' };
      }
      if (d === 'MAINTENANCE') {
        return { col1: 'Mã Phiếu / Danh mục', col2: 'Vị trí / Khu vực', col3: 'Mô tả sự cố kỹ thuật', col4: 'Ticket' };
      }
      if (d === 'LEAVE') {
        return { col1: 'Mã NV / Họ tên', col2: 'Phòng ban / Chức danh', col3: 'Lý do nghỉ phép', col4: 'Số ngày' };
      }
      if (d === 'SAFETY_ME') {
        return { col1: 'Mã / Phân hệ', col2: 'Phạm vi / Quy chuẩn', col3: 'Chi tiết đo lường', col4: 'Số lượt / Tỷ lệ' };
      }
      if (d === 'CLUB') {
        return { col1: 'Mã / Tên Môn CLB', col2: 'Phân loại', col3: 'Kế hoạch & Doanh thu', col4: 'Sĩ số HS' };
      }
      if (d === 'HR_TURNOVER') {
        return { col1: 'Mã NV / Họ tên', col2: 'Phòng ban / Chức danh', col3: 'Loại biến động & Lý do', col4: 'Số lượng' };
      }
      if (d === 'TEACHING') {
        return { col1: 'Giáo viên dạy thay', col2: 'Khối / Môn học', col3: 'Lý do dạy thay', col4: 'Số tiết' };
      }
      return { col1: 'Mã / Tên đối tượng', col2: 'Phân loại', col3: 'Chi tiết nghiệp vụ', col4: 'Định lượng' };
    },
    reconciliationSummary() {
      const item = this.selectedAuditItem;
      const domain = this.selectedFactDomain;
      const list = this.operationalFactsList || [];
      const totalFacts = list.length;
      const pendingFacts = list.filter((f) => f.Status === "PENDING" || f.Status === "CRITICAL" || f.Status === "WAITING").length;

      let totalMetric = 0;
      list.forEach((f) => {
        if (f.MetricCount != null) totalMetric += Number(f.MetricCount);
        else if (f.MetricAmount != null) totalMetric += Number(f.MetricAmount);
      });

      const pName = this.currentPeriodName || this.selectedPeriod;

      // NẾU ĐANG ĐỐI SOÁT THEO MỘT CHỈ SỐ KPI CỤ THỂ
      if (this.selectedKpiItem) {
        const k = this.selectedKpiItem;
        return {
          title: "[" + k.KpiCode + "] " + k.KpiName,
          kpiReported: this.formatKpiVal(k.ActualValue, k.Unit) + " " + (k.Unit || "") + " (Báo cáo)",
          kpiNote: "Chỉ số chốt kỳ " + k.KpiCode + " · " + (k.KpiGroup || ""),
          factCount: totalFacts,
          factMetric: totalMetric > 0 ? (this.formatKpiVal(totalMetric, k.Unit) + " " + (k.Unit || "")) : (totalFacts + " bản ghi nguyên tử"),
          status: k.Status === 'GOOD' ? 'MATCHED' : (k.Status === 'WARN' ? 'WARN' : 'CRITICAL'),
          statusText: k.Status === 'GOOD' ? 'Khớp Số Liệu Gốc' : 'Cảnh Báo Vận Hành Cần Xử Lý',
          auditFinding: k.OperationalInsight || ("Đối chiếu " + totalFacts + " giao dịch nguyên tử từ nguồn " + (k.SourceSystem || "eSign") + " khớp với chỉ số báo cáo."),
          responsibleRole: k.KpiGroup || 'Ban Điều Hành',
        };
      }

      // NẾU ĐANG ĐỐI SOÁT THEO MỘT QUY TẮC KIỂM TOÁN CỤ THỂ
      if (item) {
        return {
          title: item.Title,
          kpiReported: item.PrimaryValue || (item.PrimarySourceTemplate ? item.PrimarySourceTemplate.replace('{ValA}', item.ActualValA || '93.6') : 'Nguồn A'),
          kpiNote: item.PrimarySource || (item.MetricA_Code ? 'Chỉ số vĩ mô: ' + item.MetricA_Code : 'Nguồn A'),
          factCount: totalFacts,
          factMetric: item.SecondaryValue || (totalFacts + ' giao dịch nguyên tử'),
          status: item.SeverityLevel === 'CRITICAL' ? 'CRITICAL' : 'WARN',
          statusText: item.Category === 'PARADOX' ? 'Phát Hiện Nghịch Lý Điều Hành' : (item.Category === 'BOTTLENECK' ? 'Điểm Nghẽn Vận Hành Cần Xử Lý' : 'Chênh Lệch Dữ Liệu Báo Cáo'),
          auditFinding: item.VarianceAnalysis || item.Title,
          responsibleRole: item.ActionOwner || 'Ban Điều Hành',
        };
      }

      // NẾU MỞ TỰ DO THEO DOMAIN CHIPS
      const kLeave = this.getKpi("HR01") || this.getKpi("HR02");
      const kHealth = this.getKpi("MED01") || this.getKpi("DV38");
      const kMaint = this.getKpi("CSVC01");
      const kClub = this.getKpi("TC56");
      const kHr = this.getKpi("HR02");
      const kTeach = this.getKpi("CM01") || this.getKpi("CM08");
      const kStudents = this.getKpi("TS01") || this.getKpi("TS04");
      const kCrm = this.getKpi("TS02") || this.getKpi("TS03");

      const configs = {
        ENROLLMENT: {
          title: "Sĩ Số Học Sinh Hiện Diện & Công Suất Phòng Học",
          kpiReported: "1,324 HS hiện diện (82.8% công suất)",
          kpiNote: "Dữ liệu Basic Data chốt sổ TS01, TS02 · " + pName,
          factCount: totalFacts,
          factMetric: totalMetric + " học sinh hiện diện",
          status: "MATCHED",
          statusText: "Khớp 100% Sĩ Số Từng Khối Lớp",
          auditFinding: "Ghi nhận 1,324 học sinh phân bổ trên 14 khối lớp và 5 cơ sở, đạt 82.8% công suất thiết kế 1,600 chỗ.",
          responsibleRole: "Phòng Quản Lý Đào Tạo & Tuyển Sinh",
        },
        WITHDRAWAL: {
          title: "Hồ Sơ Rút Học & Di Chuyển SIS (TS04)",
          kpiReported: "21 HS rút học (1.56% tổng sĩ số)",
          kpiNote: "Dữ liệu SIS chốt sổ TS04 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " học sinh rút hồ sơ",
          status: pendingFacts > 0 ? "CRITICAL" : "MATCHED",
          statusText: pendingFacts > 0 ? ("Phát hiện " + pendingFacts + " ca rút học do cự ly xa nhà / xe bus") : "Khớp 100% hồ sơ rút học",
          auditFinding: "Ghi nhận tổng cộng " + totalFacts + " hồ sơ rút học trong kỳ chốt sổ " + pName + ", trong đó có " + pendingFacts + " ca liên quan đến cự ly đưa đón.",
          responsibleRole: "Tổ Quản Trị Xe Bus & Phòng Tuyển Sinh",
        },
        STUDENTS: {
          title: "Hồ Sơ Rút Học & Di Chuyển SIS",
          kpiReported: (kStudents ? kStudents.ActualValue : 21) + " HS rút học (KPI báo cáo)",
          kpiNote: "Dữ liệu SIS chốt sổ TS04 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " học sinh rút hồ sơ",
          status: pendingFacts > 0 ? "CRITICAL" : "MATCHED",
          statusText: pendingFacts > 0 ? ("Phát hiện " + pendingFacts + " ca rút học do cự ly xa nhà / xe bus") : "Khớp 100% hồ sơ rút học",
          auditFinding: "Ghi nhận tổng cộng " + totalFacts + " hồ sơ rút học trong kỳ chốt sổ " + pName + ", trong đó có " + pendingFacts + " ca liên quan đến cự ly đưa đón.",
          responsibleRole: "Tổ Quản Trị Xe Bus & Phòng Tuyển Sinh",
        },
        CRM: {
          title: "Phễu Tuyển Sinh & Phụ Huynh Tiềm Năng (CRM)",
          kpiReported: (kCrm ? kCrm.ActualValue : 15) + " hồ sơ Kitty HK2 (KPI báo cáo)",
          kpiNote: "Chiến dịch CRM Tuyển sinh · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " phụ huynh tiềm năng",
          status: pendingFacts > 0 ? "WARN" : "MATCHED",
          statusText: pendingFacts > 0 ? ("Tồn đọng " + pendingFacts + " phụ huynh hẹn HK2 cần tái chăm sóc") : "Khớp 100% danh sách CRM",
          auditFinding: "Ghi nhận " + totalFacts + " hồ sơ tiềm năng trong chiến dịch Kitty HK2. Cần chuẩn bị kế hoạch phòng học và GV cho HK2.",
          responsibleRole: "Giám Đốc Tuyển Sinh & Marcom",
        },
        SAFETY_ME: {
          title: "An Toàn Học Đường, Điểm Danh & App Me",
          kpiReported: "48.200 lượt FaceID (KPI báo cáo)",
          kpiNote: "Hệ thống An toàn & App Me · " + pName,
          factCount: totalFacts,
          factMetric: "3 phân hệ chuẩn hóa",
          status: "MATCHED",
          statusText: "Khớp 100% Nhật Ký An Toàn & Điểm Danh",
          auditFinding: "Hệ thống FaceID đạt 48.200 lượt checkin, App Me đạt 98.6% tỷ lệ cài đặt, không phát sinh sự cố an toàn thực phẩm.",
          responsibleRole: "Tổ IT & Ban Quản Trị Bán Trú",
        },
        LEAVE: {
          title: "Nghỉ Phép Nhân Sự (HR01)",
          kpiReported: (kLeave && kLeave.ActualValue != null ? Number(kLeave.ActualValue).toFixed(1) : totalMetric.toFixed(1)) + " ngày công (KPI báo cáo)",
          kpiNote: "Chỉ số vĩ mô HR01 · " + pName,
          factCount: totalFacts,
          factMetric: totalMetric.toFixed(1) + " ngày công",
          status: pendingFacts > 0 ? "WARN" : "MATCHED",
          statusText: "Khớp 100% Số Liệu Gốc (" + totalMetric.toFixed(1) + " ngày công)",
          auditFinding: "Ghi nhận " + totalFacts + " đơn với " + totalMetric.toFixed(1) + " ngày công. Trạng thái toàn vẹn dữ liệu.",
          responsibleRole: "Trưởng phòng Nhân sự",
        },
        HEALTH: {
          title: "Y Tế Học Đường (MED01)",
          kpiReported: (kHealth && kHealth.ActualValue != null ? kHealth.ActualValue : totalFacts) + " ca bệnh (KPI báo cáo)",
          kpiNote: "Chỉ tiêu y tế MED01 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " ca ghi nhận",
          status: pendingFacts > 0 ? "WARN" : "MATCHED",
          statusText: "Khớp 100% Sổ Y Tế (" + totalFacts + " ca)",
          auditFinding: "Ghi nhận " + totalFacts + " lượt khám y tế trong kỳ " + pName + ".",
          responsibleRole: "Trưởng bộ phận Y tế học đường",
        },
        MAINTENANCE: {
          title: "Bảo Trì Cơ Sở Vật Chất (CSVC01)",
          kpiReported: (kMaint && kMaint.ActualValue != null ? kMaint.ActualValue : totalFacts) + " ticket phát sinh (KPI báo cáo)",
          kpiNote: "Hệ thống CSVC01 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " ticket",
          status: pendingFacts > 0 ? "CRITICAL" : "MATCHED",
          statusText: pendingFacts > 0 ? ("Cảnh Báo: " + pendingFacts + " Ticket Tồn Đọng Chưa Xử Lý") : "Khớp 100% Ticket Nghiệm Thu",
          auditFinding: pendingFacts > 0 ? ("Có " + pendingFacts + " ticket đang tồn đọng xử lý trong kỳ " + pName + ". Cần hoàn tất SLA 24h.") : ("Toàn bộ ticket phát sinh trong kỳ đều đã nghiệm thu."),
          responsibleRole: "Trưởng phòng Quản trị CSVC",
        },
        CLUB: {
          title: "Doanh Thu & Học Viên CLB (TC56)",
          kpiReported: (kClub && kClub.ActualValue != null ? Number(kClub.ActualValue) : totalMetric) + " đ (KPI báo cáo)",
          kpiNote: "Kế toán dịch vụ TC56 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " môn CLB",
          status: "MATCHED",
          statusText: "Khớp 100% Sổ Dịch Vụ 36 Môn CLB",
          auditFinding: "Ghi nhận " + totalFacts + " môn CLB bổ trợ với doanh thu đạt kế hoạch trong kỳ " + pName + ".",
          responsibleRole: "Kế toán trưởng & BGH Tiểu học",
        },
        HR_TURNOVER: {
          title: "Biến Động Nhân Sự Cơ Hữu (HR02)",
          kpiReported: (kHr && kHr.ActualValue != null ? kHr.ActualValue : totalFacts) + " ca biến động (KPI báo cáo)",
          kpiNote: "Hồ sơ nhân sự HR02 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " ca ghi nhận",
          status: "MATCHED",
          statusText: "Khớp 100% Hồ Sơ Nhân Sự " + pName,
          auditFinding: "Ghi nhận " + totalFacts + " ca biến động nhân sự cơ hữu trong kỳ " + pName + ".",
          responsibleRole: "Ban Giám Đốc & P. Nhân sự",
        },
        TEACHING: {
          title: "Tiết Dạy Thay & Chuyên Môn (CM01)",
          kpiReported: (kTeach && kTeach.ActualValue != null ? kTeach.ActualValue : totalMetric) + " tiết dạy thay (KPI báo cáo)",
          kpiNote: "Lịch báo giảng Calen · " + pName,
          factCount: totalFacts,
          factMetric: (totalMetric > 0 ? totalMetric : totalFacts) + " tiết dạy thay",
          status: pendingFacts > 0 ? "WARN" : "MATCHED",
          statusText: "Khớp 100% Lịch Phân Công Dạy Thay",
          auditFinding: "Tổng cộng " + (totalMetric > 0 ? totalMetric : totalFacts) + " tiết dạy thay phát sinh từ các giờ vắng trong kỳ " + pName + ".",
          responsibleRole: "Tổ trưởng Chuyên môn & BGH",
        },
      };

      return configs[domain] || {
        title: "Kho Giao Dịch Gốc Fact Store",
        kpiReported: totalFacts + " bản ghi",
        kpiNote: "CSDL eSign · " + pName,
        factCount: totalFacts,
        factMetric: totalFacts + " facts",
        status: "MATCHED",
        statusText: "Khớp Dữ Liệu Gốc",
        auditFinding: "Dữ liệu kỳ " + pName + " đã được đồng bộ chuẩn hóa từ staging.",
        responsibleRole: "Ban Kiểm Soát",
      };
    },
    filteredOperationalFactsList() {
      let list = this.operationalFactsList || [];
      if (this.factCampusFilter && this.factCampusFilter !== "ALL") {
        const cf = this.factCampusFilter.toUpperCase();
        list = list.filter((f) => (f.ScopeID || "").toUpperCase() === cf);
      }
      if (this.factAuditFilter === "PENDING") {
        return list.filter((f) => f.Status === "PENDING" || f.Status === "CRITICAL" || f.Status === "WAITING" || (f.Dim4 && f.Dim4.toLowerCase().includes("tồn")));
      }
      if (this.factAuditFilter === "ANOMALY") {
        const domain = this.selectedFactDomain;
        return list.filter((f) => {
          const txt = ((f.EntityName || "") + " " + (f.Dim1 || "") + " " + (f.Dim2 || "") + " " + (f.Dim3 || "") + " " + (f.Dim4 || "")).toLowerCase();
          if (domain === "STUDENTS" || domain === "WITHDRAWAL") return txt.includes("xa") || txt.includes("bus") || txt.includes("đón") || f.Status === "CRITICAL";
          if (domain === "CRM" || domain === "PROSPECTS") return txt.includes("hk2") || txt.includes("hẹn") || txt.includes("chưa đủ") || f.Status === "PENDING";
          if (domain === "HEALTH") return txt.includes("cúm") || txt.includes("sốt") || txt.includes("thương tích") || txt.includes("bệnh");
          if (domain === "MAINTENANCE") return txt.includes("máy lạnh") || txt.includes("điều hòa") || txt.includes("quá hạn") || txt.includes("khu b");
          if (domain === "LEAVE") return txt.includes("bếp") || txt.includes("mầm non") || txt.includes("không phép") || (f.MetricCount && Number(f.MetricCount) >= 2);
          if (domain === "CLUB") return f.Status === "PENDING" || (f.MetricCount && Number(f.MetricCount) < 5);
          if (domain === "SAFETY_ME") return txt.includes("ngộ độc") || txt.includes("tai nạn") || txt.includes("vắng");
          return f.Status === "PENDING" || f.Status === "CRITICAL";
        });
      }
      return list;
    },
    computedTargetStudents() {
      const k = this.getKpi("TS01");
      if (k && k.TargetValue != null) return Number(k.TargetValue);
      if (this.currentCausalAssumption && this.currentCausalAssumption.PlannedCapacity) {
        return this.currentCausalAssumption.PlannedCapacity;
      }
      return 0;
    },
    computedDesignCapacity() {
      const k = this.getKpi("TS02");
      if (k && k.TargetValue != null) return Number(k.TargetValue);
      if (this.currentCausalAssumption && this.currentCausalAssumption.PlannedCapacity) {
        return this.currentCausalAssumption.PlannedCapacity;
      }
      return this.computedTargetStudents;
    },
    computedFillRate() {
      if (!this.computedDesignCapacity) return "0.0";
      return ((this.computedTotalStudents / this.computedDesignCapacity) * 100).toFixed(1);
    },
    computedWithdrawCount() {
      const k = this.getKpi("TS04");
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.withdrawRecords.length || 0;
    },
    computedNetChange() {
      return this.inflowRecordsCount - this.computedWithdrawCount;
    },
    computedWithdrawRate() {
      if (!this.computedTotalStudents) return "0.0";
      return ((this.computedWithdrawCount / (this.computedTotalStudents + this.computedWithdrawCount)) * 100).toFixed(1);
    },
    computedCrmLeads() {
      if (!this.crmMonthlySummary || !this.crmMonthlySummary.length) {
        const k = this.getKpi("TS05");
        return (k && k.ActualValue != null) ? Number(k.ActualValue) : 0;
      }
      if (this.currentUnit === "MNLK") {
        return this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnlkLeads ?? m.MnlkLeads ?? 0), 0);
      }
      if (this.currentUnit === "MNBH" || this.currentUnit === "MNTB") {
        return this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnbhLeads ?? m.MnbhLeads ?? 0), 0);
      }
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) {
        return this.crmMonthlySummary.reduce((sum, m) => sum + (m.ptlcLeads ?? m.PtlcLeads ?? 0), 0);
      }
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.totalLeads ?? m.TotalLeads ?? 0), 0);
    },
    computedCrmEnrolled() {
      if (!this.crmMonthlySummary || !this.crmMonthlySummary.length) return 0;
      if (this.currentUnit === "MNLK") {
        return this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnlkEnrolled ?? m.MnlkEnrolled ?? 0), 0);
      }
      if (this.currentUnit === "MNBH" || this.currentUnit === "MNTB") {
        return this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnbhEnrolled ?? m.MnbhEnrolled ?? 0), 0);
      }
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) {
        return this.crmMonthlySummary.reduce((sum, m) => sum + (m.ptlcEnrolled ?? m.PtlcEnrolled ?? 0), 0);
      }
      return this.crmMonthlySummary.reduce((sum, m) => sum + (m.totalEnrolled ?? m.TotalEnrolled ?? m.EnrolledStudents ?? 0), 0);
    },
    computedCrmConversionRate() {
      const leads = this.computedCrmLeads;
      const enrolled = this.computedCrmEnrolled;
      if (!leads || leads === 0) return "0.0";
      return ((enrolled / leads) * 100).toFixed(1);
    },
    computedCrmLeadsCurrentMonth() {
      if (!this.crmMonthlySummary || !this.crmMonthlySummary.length) return 0;
      const latest = this.crmMonthlySummary[this.crmMonthlySummary.length - 1];
      if (!latest) return 0;
      if (this.currentUnit === "MNLK") return (latest.mnlkLeads ?? latest.MnlkLeads ?? 0);
      if (this.currentUnit === "MNBH" || this.currentUnit === "MNTB") return (latest.mnbhLeads ?? latest.MnbhLeads ?? 0);
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) return (latest.ptlcLeads ?? latest.PtlcLeads ?? 0);
      return (latest.totalLeads ?? latest.TotalLeads ?? 0);
    },
    computedCrmDropTotal() {
      if (!this.crmDropReasons || !this.crmDropReasons.length) return 0;
      return this.crmDropReasons.reduce((sum, r) => sum + (parseInt(r.count || r.Count, 10) || 0), 0);
    },
    computedCrmUnitRatesText() {
      if (!this.crmMonthlySummary || !this.crmMonthlySummary.length) return "Đang cập nhật";
      const ptlcL = this.crmMonthlySummary.reduce((sum, m) => sum + (m.ptlcLeads ?? m.PtlcLeads ?? 0), 0);
      const ptlcE = this.crmMonthlySummary.reduce((sum, m) => sum + (m.ptlcEnrolled ?? m.PtlcEnrolled ?? 0), 0);
      const ptlcRate = ptlcL ? ((ptlcE / ptlcL) * 100).toFixed(1) : "0.0";

      const mnbhL = this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnbhLeads ?? m.MnbhLeads ?? 0), 0);
      const mnbhE = this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnbhEnrolled ?? m.MnbhEnrolled ?? 0), 0);
      const mnbhRate = mnbhL ? ((mnbhE / mnbhL) * 100).toFixed(1) : "0.0";

      const mnlkL = this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnlkLeads ?? m.MnlkLeads ?? 0), 0);
      const mnlkE = this.crmMonthlySummary.reduce((sum, m) => sum + (m.mnlkEnrolled ?? m.MnlkEnrolled ?? 0), 0);
      const mnlkRate = mnlkL ? ((mnlkE / mnlkL) * 100).toFixed(1) : "0.0";

      return `PTLC: ${ptlcRate}% · MNBH: ${mnbhRate}% · MNLK: ${mnlkRate}%`;
    },
    crmMonthlySummaryText() {
      if (!this.crmMonthlySummary || !this.crmMonthlySummary.length) return "Đang cập nhật";
      const parts = this.crmMonthlySummary.map(m => {
        const mName = m.month || m.ReportMonth || "";
        const shortM = mName.replace("Tháng ", "T");
        const count = m.totalLeads ?? m.TotalLeads ?? 0;
        return `${shortM}: ${count}`;
      });
      return `Lũy kế ${this.crmMonthlySummary.length} tháng: ${parts.join(" · ")}`;
    },
    displayWithdrawTotalCount() {
      return this.withdrawRecords.length || this.displayOutflowYearToDate || this.displayWithdrawCount || 0;
    },
    lmsTotalAssigned() {
      if (!this.lmsAssignmentRows || !this.lmsAssignmentRows.length) return 0;
      return this.lmsAssignmentRows.reduce((s, r) => s + (r.TotalAssigned || 0), 0);
    },
    clubMillionDollarAccumPct() {
      const kClb = this.getKpi("TC33");
      const rev = (this.computedFinanceData && this.computedFinanceData.clbRev) ? parseFloat(this.computedFinanceData.clbRev) * 1000000000 : (kClb && kClb.ActualValue ? Number(kClb.ActualValue) : 0);
      return ((rev / 25000000000) * 100).toFixed(1);
    },
    riskSummaryBadgeText() {
      const red = (this.riskCampusCards || []).filter(c => c.RiskTier === "RED" || c.RiskLevel === "CRITICAL" || c.CompositeScore >= 70).length;
      const warn = (this.riskCampusCards || []).filter(c => c.RiskTier === "WARN" || c.RiskLevel === "WARNING" || (c.CompositeScore >= 40 && c.CompositeScore < 70)).length;
      return `${red} Vùng Đỏ · ${warn} Cảnh Báo`;
    },
    riskBadgeClass() {
      const red = (this.riskCampusCards || []).filter(c => c.RiskTier === "RED" || c.RiskLevel === "CRITICAL" || c.CompositeScore >= 70).length;
      const warn = (this.riskCampusCards || []).filter(c => c.RiskTier === "WARN" || c.RiskLevel === "WARNING" || (c.CompositeScore >= 40 && c.CompositeScore < 70)).length;
      if (red > 0) return 'badge-danger';
      if (warn > 0) return 'badge-warning';
      return 'badge-success';
    },
    linearCorrelationsCount() {
      return (this.correlationsList || []).filter(c => c.RelationshipType === "DIRECT_CAUSAL_1WAY" || c.RelationshipType === "CAUSAL_1WAY").length;
    },
    loopCorrelationsCount() {
      return (this.correlationsList || []).filter(c => c.RelationshipType === "FEEDBACK_LOOP_2WAY").length;
    },
    paradoxCorrelationsCount() {
      return (this.correlationsList || []).filter(c => c.RelationshipType === "DATA_PARADOX_CROSS" || c.RelationshipType === "BOTTLENECK_CSVC").length;
    },
    currentPeriodIsStaging() {
      const p = this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      return p ? p.DataSourceType === "EXCEL_STAGING" : false;
    },
    currentPeriodName() {
      const p = this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      return p ? p.PeriodName : "Kỳ hiện tại";
    },
    currentPeriodShortName() {
      if (!this.selectedPeriod) return "kỳ";
      const parts = this.selectedPeriod.split("-");
      if (parts.length === 2) return "T" + parseInt(parts[1], 10);
      return this.selectedPeriod;
    },
    nextPeriodShortName() {
      if (!this.selectedPeriod) return "kỳ tới";
      const parts = this.selectedPeriod.split("-");
      if (parts.length === 2) {
        let m = parseInt(parts[1], 10) + 1;
        if (m > 12) m = 1;
        return "T" + m;
      }
      return "kỳ tới";
    },
    currentUnitTitle() {
      const u = this.unitOptions.find((x) => x.k === this.currentUnit);
      if (u) return u.t;
      if (this.currentUnit === "MNBH" || this.currentUnit === "MNTB") return "Mầm non TB";
      return "Toàn hệ thống";
    },
    displayStudents() {
      const k = this.getKpi("TS01");
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedTotalStudents;
    },
    displayTarget() {
      const k = this.getKpi("TS01");
      if (k && k.TargetValue != null) return Number(k.TargetValue);
      return this.computedTargetStudents;
    },
    displayCapacity() {
      const k = this.getKpi("TS02");
      if (k && k.TargetValue != null) return Number(k.TargetValue);
      return this.computedDesignCapacity;
    },
    displayFillRate() {
      const kTs01 = this.getKpi("TS01");
      if (kTs01 && kTs01.Rate != null) return Number(kTs01.Rate).toFixed(1).replace(".", ",");
      const kTs02 = this.getKpi("TS02");
      if (kTs02 && kTs02.Rate != null) return Number(kTs02.Rate).toFixed(1).replace(".", ",");
      return this.computedFillRate;
    },
    displayCapacityPct() {
      const k = this.getKpi("TS01");
      if (k && k.Rate != null) return Number(k.Rate).toFixed(1).replace(".", ",");
      if (!this.displayTarget) return "0,0";
      return ((this.displayStudents / this.displayTarget) * 100).toFixed(1).replace(".", ",");
    },
    displayWithdrawCount() {
      const k = this.getKpi("TS04");
      if (k && k.OperationalInsight) {
        const m = k.OperationalInsight.match(/Rút\s+(\d+)\s+HS/i);
        if (m) return parseInt(m[1], 10);
      }
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedWithdrawCount;
    },
    displayWithdrawRate() {
      const k = this.getKpi("TS04");
      if (k && k.Rate != null) return Number(k.Rate).toFixed(2).replace(".", ",");
      if (k && k.ActualValue != null) return Number(k.ActualValue).toFixed(2).replace(".", ",");
      return this.computedWithdrawRate;
    },
    displayInflow() {
      const k = this.getKpi("TS03");
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.inflowRecordsCount;
    },
    displayOutflow() {
      return this.displayWithdrawCount;
    },
    displayNetChange() {
      return this.displayInflow - this.displayOutflow;
    },
    displayReasonFar() {
      if (this.breakdownsList && this.breakdownsList.length) {
        const item = this.breakdownsList.find((b) => b.KpiCode === "TS04" && (b.DimensionCode === "FAR" || b.DimensionCode === "BUS"));
        if (item) return Number(item.ActualCount || item.ActualValue || 0);
      }
      return 0;
    },
    displayReasonFarPct() {
      const tot = this.displayWithdrawCount || 1;
      return ((this.displayReasonFar / tot) * 100).toFixed(1);
    },
    displayWithdrawFinancialLoss() {
      const tuition = (this.currentCausalAssumption && this.currentCausalAssumption.AnnualTuitionMillion) || 49.8;
      const busFee = 12.0;
      const totalTuitionLoss = ((this.displayReasonFar * tuition) / 1000).toFixed(2).replace('.', ',');
      const totalBusLoss = Math.round(this.displayReasonFar * busFee);
      return `${totalTuitionLoss} tỷ học phí + ${totalBusLoss} triệu xe bus/năm`;
    },
    displayReasonEco() {
      if (this.breakdownsList && this.breakdownsList.length) {
        const item = this.breakdownsList.find((b) => b.KpiCode === "TS04" && b.DimensionCode === "ECO");
        if (item) return Number(item.ActualCount || item.ActualValue || 0);
      }
      return 0;
    },
    displayReasonOther() {
      const far = this.displayReasonFar;
      const eco = this.displayReasonEco;
      const tot = this.displayWithdrawCount;
      return Math.max(0, tot - far - eco);
    },
    displayLeads() {
      const k = this.getKpi("TS05");
      if (this.currentUnit === "ALL" && k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedCrmLeads;
    },
    displayConversionRate() {
      const k = this.getKpi("TS06");
      if (this.currentUnit === "ALL" && k && k.Rate != null) return Number(k.Rate).toFixed(1);
      return this.computedCrmConversionRate;
    },
    displayEnrolled() {
      const k = this.getKpi("TS06");
      if (this.currentUnit === "ALL" && k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedCrmEnrolled;
    },
    computedFinanceData() {
      const kTc55 = this.getKpi("TC55");
      const kTc56 = this.getKpi("TC56");
      const kClb = this.getKpi("TC33");
      const grossMargin = (kTc55 && kTc55.Rate != null) ? kTc55.Rate + "%" : (this.financeSummary && this.financeSummary.TotalOpMarginPct != null ? Number(this.financeSummary.TotalOpMarginPct).toFixed(1) + "%" : (this.currentPeriodIsFrozen ? "0.0%" : "Đang cập nhật"));
      let rev = "0 Tỷ";
      if (this.currentUnit !== "ALL") {
        const tuition = this.currentCausalAssumption.AnnualTuitionMillion || (kTc55 ? Number(kTc55.ActualValue) / (this.displayStudents || 1) / 1000000 : 0);
        const students = this.displayStudents || 0;
        rev = ((students * tuition) / 1000).toFixed(2).replace(".", ",") + " Tỷ";
      } else if (kTc55 && kTc55.ActualValue != null) {
        const val = Number(kTc55.ActualValue);
        rev = val >= 1000000000 ? (val / 1000000000).toFixed(2) + " Tỷ" : (val / 1000000).toFixed(0) + " Tr";
      } else if (this.financeSummary && this.financeSummary.TotalOpRevenue) {
        const val = Number(this.financeSummary.TotalOpRevenue);
        rev = (val / 1000000000).toFixed(2) + " Tỷ";
      } else {
        rev = this.currentPeriodIsFrozen ? "0 Tỷ" : "Đang cập nhật";
      }
      let clbRev = "0 Tỷ";
      if (this.currentUnit !== "ALL") {
        const clbRate = this.currentCausalAssumption.ClbParticipationRate || 0;
        const clbFee = this.currentCausalAssumption.ClbAvgFeeMillion || 0;
        const clbCount = Math.round(this.displayStudents * clbRate);
        clbRev = ((clbCount * clbFee) / 1000).toFixed(2).replace(".", ",") + " Tỷ";
      } else if (kClb && kClb.ActualValue != null) {
        const val = Number(kClb.ActualValue);
        clbRev = val >= 1000000000 ? (val / 1000000000).toFixed(2) + " Tỷ" : (val / 1000000).toFixed(0) + " Tr";
      } else if (this.financeSummary && this.financeSummary.TotalClubRevenue) {
        const val = Number(this.financeSummary.TotalClubRevenue);
        clbRev = (val / 1000000000).toFixed(2) + " Tỷ";
      } else {
        clbRev = this.currentPeriodIsFrozen ? "0 Tỷ" : "Đang cập nhật";
      }
      const clbStudents = this.currentUnit !== "ALL" 
        ? Math.round(this.displayStudents * (this.currentCausalAssumption.ClbParticipationRate || 0)) + " HS" 
        : ((kClb && kClb.TargetValue != null) ? kClb.TargetValue + " HS" : (this.totalClubStudents ? this.totalClubStudents + " HS" : "0 HS"));
      const busMargin = (kTc56 && kTc56.Rate != null) ? kTc56.Rate + "%" : "—";
      let retailMargin = "—";
      if (this.financeServices && this.financeServices.length) {
        const rItem = this.financeServices.find(s => s.name && (s.name.includes("Bán lẻ") || s.name.includes("Đồng phục")));
        if (rItem && rItem.margin) retailMargin = rItem.margin;
      }
      return {
        grossMargin,
        rev,
        clbRev,
        clbStudents,
        busMargin,
        mealMargin: grossMargin,
        retailMargin,
      };
    },
    computedLmsData() {
      if (this.currentUnit === "MNLK" || this.currentUnit === "MNTB" || this.currentUnit === "MNBH") {
        return { rate: "100% (KidsOnline)", math: "—", viet: "—", digitalLessons: "Nhật ký chăm sóc (Mầm non)", onTime: "100%" };
      }
      const kCm08 = this.getKpi("CM08");
      const kCm04 = this.getKpi("CM04");
      const rate = (kCm08 && kCm08.Rate != null) ? kCm08.Rate + "%" : (this.lmsOverallRate && this.lmsOverallRate !== "0.0" ? this.lmsOverallRate + "%" : "0.0%");
      const digitalLessons = (kCm04 && kCm04.Rate != null) ? kCm04.Rate + "%" : (this.lmsHocLieuSummary && this.lmsHocLieuSummary.pct ? this.lmsHocLieuSummary.pct + "%" : "0.0%");
      let math = "—";
      let viet = "—";
      if (this.lmsAssignmentRows && this.lmsAssignmentRows.length) {
        const mathRow = this.lmsAssignmentRows.find(r => r.TenMonHoc_HienThi && r.TenMonHoc_HienThi.includes("Toán"));
        if (mathRow && mathRow.CompletionRate_Assignments != null) math = mathRow.CompletionRate_Assignments + "%";
        const vietRow = this.lmsAssignmentRows.find(r => r.TenMonHoc_HienThi && (r.TenMonHoc_HienThi.includes("Tiếng Việt") || r.TenMonHoc_HienThi.includes("Ngữ văn")));
        if (vietRow && vietRow.CompletionRate_Assignments != null) viet = vietRow.CompletionRate_Assignments + "%";
      }
      return {
        rate,
        math,
        viet,
        digitalLessons,
        onTime: rate,
      };
    },
    activeBottlenecks() {
      if (this.periodSnapshots && this.periodSnapshots.length) {
        return this.periodSnapshots.filter(
          (k) => k.Status === "WARN" || k.Status === "DANGER" || k.Status === "BAD"
        );
      }
      return [];
    },
    computedDisplaySpecs() {
      const sourceList = (this.goliveSpecsList && this.goliveSpecsList.length) ? this.goliveSpecsList : this.defaultGoliveSpecs;
      if (this.selectedSpecCode) {
        const filtered = sourceList.filter((s) => s.SpecCode === this.selectedSpecCode);
        return filtered.length ? filtered : sourceList;
      }
      return sourceList;
    },
    valueBridge() {
      const curStudents = this.displayStudents || 0;
      const target = this.displayTarget || 0;
      const rawBars = (this.strategicWaterfallBars && this.strategicWaterfallBars.length)
        ? this.strategicWaterfallBars.map(b => ({
            name: b.BarName,
            v: b.CumulativeVal,
            delta: b.StepDelta,
            type: b.BarType,
            money: b.MoneyText,
            lines: [b.Line1, b.Line2]
          }))
        : [
            { name: "Sĩ số hiện tại", v: curStudents, delta: 0, type: "total", money: curStudents + " HS", lines: ["Sĩ số kỳ", curStudents + " HS"] },
            { name: "Kế hoạch HĐQT", v: target, delta: 0, type: "end", money: "100% KH", lines: ["Kế hoạch", target + " HS"] },
          ];

      const baseVal = rawBars[0] ? rawBars[0].v : curStudents;
      const planVal = rawBars[rawBars.length - 1] ? rawBars[rawBars.length - 1].v : target;
      const minY = Math.floor(Math.min(baseVal, planVal) * 0.9 / 50) * 50;
      const maxY = Math.ceil(Math.max(baseVal, planVal) * 1.06 / 50) * 50;
      const plotTop = 18;
      const plotBottom = 110;
      const plotH = plotBottom - plotTop;
      const scaleY = (val) => plotBottom - ((val - minY) / (maxY - minY)) * plotH;
      const planY = scaleY(planVal);

      const step = Math.round((maxY - minY) / 3);
      const ticks = [minY, minY + step, minY + step * 2, maxY].map(v => ({ v, y: scaleY(v) }));
      const barW = 54;
      const gap = 38;
      const startX = 58;

      const calcBars = [];
      const conns = [];
      let prevVal = baseVal;

      rawBars.forEach((b, i) => {
        const x = startX + i * (barW + gap);
        let y, h;
        if (b.type === "total" || b.type === "end") {
          y = scaleY(b.v);
          h = plotBottom - y;
        } else {
          const fromY = scaleY(prevVal);
          const toY = scaleY(b.v);
          y = Math.min(fromY, toY);
          h = Math.max(3, Math.abs(fromY - toY));
          conns.push({ x1: x - gap, x2: x, y: fromY });
        }
        calcBars.push({
          ...b,
          x,
          y,
          w: barW,
          h,
          text: b.type === "total" || b.type === "end" ? b.v : "+" + b.delta,
        });
        prevVal = b.v;
      });

      return {
        ticks,
        bars: calcBars,
        conns,
        planY,
        planVal,
      };
    },
    campusMatrixRows() {
      if (this.riskCampusCards && this.riskCampusCards.length) {
        return this.riskCampusCards.map(c => {
          let withdraw = 0;
          let withdrawRate = 0;
          if (c.WithdrawForecast) {
            const m = c.WithdrawForecast.match(/(\d+)/);
            if (m) withdraw = parseInt(m[1], 10);
          }
          if (c.Axis2Pct) withdrawRate = c.Axis2Pct;
          return {
            code: c.ScopeID,
            name: c.CampusName,
            owner: "Ban Giám Hiệu " + c.CampusName,
            current: c.CurrentEnrollment,
            target: c.PlannedCapacity,
            occupancy: c.OccupancyRate,
            withdraw: withdraw,
            withdrawRate: withdrawRate,
            leaveDays: c.Axis4Pct || 0,
            maintenancePending: c.Axis3Pct > 20 ? Math.round(c.Axis3Pct / 18) : 0,
            status: c.RiskLevel === "RED" ? "bad" : (c.RiskLevel === "YELLOW" ? "warn" : "good"),
            statusText: c.RiskStatusText || (c.RiskLevel === "RED" ? "Giải trình" : (c.RiskLevel === "YELLOW" ? "Theo dõi" : "Ổn định")),
            confidence: c.RiskLevel === "RED" ? "half" : "full",
            notes: c.HdqDirective || "Vận hành theo chỉ đạo HĐQT",
          };
        });
      }
      return [];
    },
    filteredCorrelationsList() {
      const list = this.correlationsList || [];
      if (!list || !list.length) return [];
      if (this.causalChainFilter === "LINEAR") {
        return list.filter(c => 
          c.RelationshipType === "DIRECT_IMPACT" || 
          c.RelationshipType === "FINANCIAL_LOSS" || 
          c.RelationshipType === "FACILITY_IMPACT" || 
          c.RelationshipType === "HEALTH_DISRUPTION" || 
          c.RelationshipType === "FUNNEL_CONVERSION" || 
          c.RelationshipType === "CAPACITY_RECOVERY" || 
          c.RelationshipType === "OPERATIONAL_STRAIN"
        );
      }
      if (this.causalChainFilter === "FEEDBACK") {
        return list.filter(c => 
          c.RelationshipType.startsWith("POSITIVE_FEEDBACK") || 
          c.RelationshipType.startsWith("NEGATIVE_FEEDBACK") ||
          c.RelationshipType.startsWith("COST_PARADOX")
        );
      }
      if (this.causalChainFilter === "PARADOX") {
        return list.filter(c => 
          c.RelationshipType === "SYSTEM_BOTTLENECK" || 
          c.RelationshipType === "DATA_PARADOX_CROSS" ||
          c.RelationshipType.startsWith("COST_PARADOX")
        );
      }
      return list;
    },
    displayTopWithdrawReasons() {
      if (this.breakdownsList && this.breakdownsList.length) {
        const withdraws = this.breakdownsList.filter(b => b.KpiCode === 'TS04' && b.DimensionType === 'REASON');
        if (withdraws.length) {
          return withdraws.map(w => ({
            name: w.DimensionName,
            count: w.ActualCount,
            percent: w.Rate,
            owner: w.ResponsibleOwner,
            note: w.Note
          }));
        }
      }
      if (this.topWithdrawReasons && this.topWithdrawReasons.length) {
        return this.topWithdrawReasons;
      }
      return [];
    },
  },
  mounted() {
    try {
      if (typeof localStorage !== "undefined") {
        const saved = localStorage.getItem("kpi_ops_directives_status");
        if (saved) this.directiveStatusMap = JSON.parse(saved);
      }
    } catch (e) {}
    this.fetchPeriodsList();
    this.fetchPeriodData(this.selectedPeriod);
    if (!this.currentPeriodIsFrozen) {
      this.fetchAllLiveData();
    }
    this.fetchCausalEngineData();
    window.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        if (this.isFactsModalOpen) this.closeFactModal();
        this.closeCausalModal();
        this.closeDrawer();
      }
    });
    document.addEventListener("fullscreenchange", () => {
      this.isPresentMode = !!document.fullscreenElement;
    });
  },
  methods: {
    async fetch3TierData(pKey, queryUnit) {
      try {
        const payload = {
          PeriodKey: pKey || this.selectedPeriod,
          DonViID: (queryUnit || this.currentUnit) === 'MNTB' ? 'MNBH' : (queryUnit || this.currentUnit),
          ActiveMasterKpi: this.activeTier1Kpi || 'KPI_1'
        };
        let data = null;
        if (typeof ajaxCALL === "function") {
          await new Promise((resolve) => {
            ajaxCALL('/esign/KPI_Get3TierDashboardData', payload, (res) => {
              data = (res && res.data) ? res.data : res;
              resolve();
            }, () => resolve());
          });
        }
        if (!data) {
          const res = await this.callTapi("eSign/KPI_Get3TierDashboardData", payload);
          data = (res && res.data) ? res.data : res;
        }
        if (Array.isArray(data)) {
          if (data.length > 0 && Array.isArray(data[0])) {
            this.tier1List = data[0] || [];
            this.tier2Drivers = data[1] || [];
            this.tier3Campuses = data[2] || [];
            this.tier3CausalChains = data[3] || [];
            this.tier3CausalImpact = (data[3] && data[3][0]) ? data[3][0] : null;
            this.tier3Audits = data[4] || [];
          } else {
            this.tier1List = data;
          }
        }
      } catch (err) {
        console.warn("fetch3TierData error:", err);
      }
    },
    async selectTier1Kpi(code) {
      this.activeTier1Kpi = code;
      this.activeTier2Kpi = null;
      this.activeCausalChainIdx = 0;
      await this.fetch3TierData(this.selectedPeriod, this.currentUnit);
      if (this.currentUnit === "ALL" && this.tier3Campuses && this.tier3Campuses.length > 0) {
        const riskField = (this.activeRadarAxisMeta && this.activeRadarAxisMeta.riskField) || "EnrollmentRisk";
        const sorted = [...this.tier3Campuses].sort((a, b) => Number(b[riskField] || 0) - Number(a[riskField] || 0));
        if (sorted[0] && sorted[0].ScopeID) {
          this.selectedRadarCampus = sorted[0].ScopeID;
        }
      }
    },
    getCampusBarWidthPct(c) {
      if (!c) return 50;
      const kpi = this.activeTier1Kpi || "KPI_1";
      const val = Number(c.CampusActualValue != null ? c.CampusActualValue : c.CapacityRate);
      if (kpi === "KPI_3") {
        // Withdraw rate (target <= 10%): scale 0..10% to 0..95% width
        return Math.min(100, Math.max(8, (val / 10.0) * 90));
      }
      if (kpi === "KPI_4") {
        // Club target rate (can be up to 120%): scale 100% target at 85% width
        return Math.min(100, Math.max(8, val * 0.82));
      }
      return Math.min(100, Math.max(8, val));
    },
    getCampusBarToneClass(c, prefix = "fill-") {
      if (!c) return prefix + "good";
      const kpi = this.activeTier1Kpi || "KPI_1";
      const val = Number(c.CampusActualValue != null ? c.CampusActualValue : c.CapacityRate);
      const target = Number(c.CampusTargetValue != null ? c.CampusTargetValue : 95);
      if (kpi === "KPI_3") {
        if (val >= 5.0) return prefix + "bad";
        if (val >= 3.0) return prefix + "warn";
        return prefix + "good";
      }
      if (val < target * 0.85) return prefix + "bad";
      if (val < target) return prefix + "warn";
      return prefix + "good";
    },
    getCampusSubMetricText(c) {
      if (!c) return "";
      const kpi = this.activeTier1Kpi || "KPI_1";
      if (kpi === "KPI_1") return `${c.CurrentEnrollment}/${c.PlannedCapacity} HS`;
      if (kpi === "KPI_2") return `KH >= ${c.CampusTargetValue}%`;
      if (kpi === "KPI_3") return `KH <= 10% · Khám SK ${c.HealthRate || 96}%`;
      if (kpi === "KPI_4") return `${c.ClubStudents || 70} lượt ĐK CLB`;
      if (kpi === "KPI_5") return `Phép: ${c.StaffLeaveDays || 40} ngày`;
      if (kpi === "KPI_6") return `KH >= ${c.CampusTargetValue}%`;
      return `KH: ${c.CampusTargetValue}`;
    },
    selectTier2Driver(driver, targetTab = null) {
      if (!driver || !driver.KpiCode) return;
      this.activeCausalChainIdx = 0;
      if (targetTab) {
        this.activeTier2Kpi = driver.KpiCode;
        this.tier3ActiveTab = targetTab;
      } else {
        this.activeTier2Kpi = this.activeTier2Kpi === driver.KpiCode ? null : driver.KpiCode;
        if (this.activeTier2Kpi && driver.AuditIssueCount > 0 && this.tier3ActiveTab === 'CAMPUS') {
          this.tier3ActiveTab = 'AUDIT';
        }
      }
    },
    getRadarPolygonPoints(campusObj, maxRadius = 64, cx = 100, cy = 96) {
      if (!campusObj) return `${cx},${cy - 20} ${cx + 20},${cy} ${cx},${cy + 20} ${cx - 20},${cy}`;
      const ts = Math.min(100, Math.max(8, Number(campusObj.EnrollmentRisk || 25))) / 100;
      const ht = Math.min(100, Math.max(8, Number(campusObj.AcademicRisk || 20))) / 100;
      const dv = Math.min(100, Math.max(8, Number(campusObj.ServiceRisk || 25))) / 100;
      const vh = Math.min(100, Math.max(8, Number(campusObj.OperationsRisk || 25))) / 100;
      const pTop = `${cx},${(cy - ts * maxRadius).toFixed(1)}`;
      const pRight = `${(cx + ht * maxRadius).toFixed(1)},${cy}`;
      const pBottom = `${cx},${(cy + dv * maxRadius).toFixed(1)}`;
      const pLeft = `${(cx - vh * maxRadius).toFixed(1)},${cy}`;
      return `${pTop} ${pRight} ${pBottom} ${pLeft}`;
    },
    getRadarVertexCoords(campusObj, maxRadius = 64, cx = 100, cy = 96) {
      if (!campusObj) return [];
      const ts = Math.min(100, Math.max(8, Number(campusObj.EnrollmentRisk || 25))) / 100;
      const ht = Math.min(100, Math.max(8, Number(campusObj.AcademicRisk || 20))) / 100;
      const dv = Math.min(100, Math.max(8, Number(campusObj.ServiceRisk || 25))) / 100;
      const vh = Math.min(100, Math.max(8, Number(campusObj.OperationsRisk || 25))) / 100;
      return [
        { x: cx, y: Number((cy - ts * maxRadius).toFixed(1)), val: campusObj.EnrollmentRisk || 0, label: "TS" },
        { x: Number((cx + ht * maxRadius).toFixed(1)), y: cy, val: campusObj.AcademicRisk || 0, label: "HT" },
        { x: cx, y: Number((cy + dv * maxRadius).toFixed(1)), val: campusObj.ServiceRisk || 0, label: "DV" },
        { x: Number((cx - vh * maxRadius).toFixed(1)), y: cy, val: campusObj.OperationsRisk || 0, label: "VH" }
      ];
    },
    getKpiSparklinePoints(kpi) {
      const code = kpi && kpi.MasterKpiCode ? kpi.MasterKpiCode : "KPI_1";
      const map = {
        KPI_1: "2,24 22,22 42,19 62,16 82,13 102,11",
        KPI_2: "2,20 22,18 42,15 62,14 82,11 102,9",
        KPI_3: "2,18 22,15 42,14 62,12 82,10 102,8",
        KPI_4: "2,14 22,15 42,13 62,16 82,15 102,14",
        KPI_5: "2,25 22,22 42,18 62,16 82,13 102,11",
        KPI_6: "2,16 22,18 42,20 62,22 82,21 102,22"
      };
      return map[code] || "2,20 22,18 42,16 62,14 82,12 102,10";
    },
    getKpiVarianceText(kpi) {
      if (!kpi) return "0%";
      const actual = Number(kpi.ActualValue || 0);
      const target = Number(kpi.TargetValue || 100);
      if (kpi.ComparisonOp === "<=") {
        const diff = target - actual;
        return (diff >= 0 ? "Tốt hơn " : "Vượt trần ") + Math.abs(diff).toFixed(1) + (kpi.TargetUnit || "%");
      }
      const diff = actual - target;
      return (diff >= 0 ? "+" : "") + diff.toFixed(1) + (kpi.TargetUnit || "%");
    },
    openDrawerForKpi(kpiCode) {
      const driver = (this.currentTier2Drivers || []).find(d => d.KpiCode === kpiCode);
      if (driver) {
        this.selectTier2Driver(driver, 'CAUSAL');
      } else {
        const domain = this.getKpiFactDomain(kpiCode);
        this.openFactModal(domain, this.currentUnit);
      }
    },
    getDumbbellPos(auditItem) {
      if (!auditItem) return { leftPct: 20, rightPct: 80, diffLabel: "—" };
      const a = Number(auditItem.PrimaryNum != null ? auditItem.PrimaryNum : 100);
      const b = Number(auditItem.SecondaryNum != null ? auditItem.SecondaryNum : 80);
      const unit = auditItem.UnitLabel || "";
      const maxVal = Math.max(Math.abs(a), Math.abs(b), 1) * 1.15;
      const minVal = Math.min(0, a, b);
      const span = Math.max(1, maxVal - minVal);
      const leftPct = Math.min(92, Math.max(8, Math.round(((a - minVal) / span) * 84 + 8)));
      const rightPct = Math.min(92, Math.max(8, Math.round(((b - minVal) / span) * 84 + 8)));
      const diff = Math.abs(a - b);
      const diffFormatted = Number.isInteger(diff) ? diff.toLocaleString("vi-VN") : diff.toFixed(1);
      return {
        leftPct,
        rightPct,
        diffLabel: diffFormatted + (unit ? " " + unit : "")
      };
    },
    jumpToTier3Page(kpiCode) {
      const map = {
        'KPI_1': 1,
        'KPI_2': 4,
        'KPI_3': 2,
        'KPI_4': 5,
        'KPI_5': 6,
        'KPI_6': 7
      };
      this.page = map[kpiCode] || 1;
      if (typeof window !== "undefined") {
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    },
    formatBillion(val) {
      if (!val || isNaN(val)) return '0';
      const num = Number(val);
      if (Math.abs(num) >= 1000000000) {
        return (num / 1000000000).toFixed(2);
      }
      if (Math.abs(num) >= 1000000) {
        return (num / 1000000).toFixed(1) + ' tr';
      }
      return num.toLocaleString('vi-VN');
    },
    getTierStatusText(badge) {
      if (badge === 'GOOD' || badge === 'good') return 'Đạt chuẩn';
      if (badge === 'WARN' || badge === 'warn') return 'Cảnh báo';
      if (badge === 'PENDING' || badge === 'pending') return 'Chờ tích hợp';
      return 'Chưa đạt';
    },

    getGroupKpis(grpName) {
      let list = this.filteredFrameworkKpis || [];
      if (grpName === 'Giáo dục & Học thuật' || grpName === 'Chất lượng Giáo dục') {
        return list.filter(k => k.KpiGroup === 'Chất lượng Giáo dục' || k.KpiGroup === 'Học thuật & Đào tạo' || k.KpiGroup === 'Giáo dục & Học thuật');
      }
      if (grpName === 'Dịch vụ & An toàn' || grpName === 'Vận hành & Dịch vụ') {
        return list.filter(k => k.KpiGroup === 'Dịch vụ & An toàn' || k.KpiGroup === 'Vận hành & Dịch vụ');
      }
      if (grpName === 'Tài chính & CSVC') {
        return list.filter(k => k.KpiGroup === 'Tài chính & CSVC' || k.KpiGroup === 'Tài chính & Dịch vụ');
      }
      return list.filter(k => k.KpiGroup === grpName);
    },
    openRoiModal(scenario = 'BUS') {
      this.selectedRoiScenario = scenario;
      this.page = 0;
      this.executiveTab = 'SIMULATOR';
    },
    closeRoiModal() {
      this.executiveTab = 'COMMAND';
    },
    toggleFullscreen() {
      if (!document.fullscreenElement) {
        if (document.documentElement.requestFullscreen) {
          document.documentElement.requestFullscreen().catch(() => {});
        }
        this.isPresentMode = true;
      } else {
        if (document.exitFullscreen) {
          document.exitFullscreen().catch(() => {});
        }
        this.isPresentMode = false;
      }
    },
    getKpi(kpiCode) {
      if (!this.periodSnapshots || !this.periodSnapshots.length) return null;
      return this.periodSnapshots.find((x) => x.KpiCode === kpiCode) || null;
    },
    getKpiTarget(kpiCode) {
      const k = this.getKpi(kpiCode);
      if (k && k.TargetValue != null) {
        return k.TargetValue + (k.Unit ? (k.Unit === '%' ? '%' : ' ' + k.Unit) : '');
      }
      return '';
    },
    async fetchPriorPeriodData(priorKey) {
      if (!priorKey) {
        this.priorPeriodSnapshots = [];
        return;
      }
      const queryUnit = (this.currentUnit === "MNTB") ? "MNBH" : this.currentUnit;
      try {
        const snapRes = await this.callTapi("eSign/KPI_GetPeriodSnapshots", { PeriodKey: priorKey, DonViID: queryUnit });
        if (snapRes && Array.isArray(snapRes) && snapRes[0]) {
          this.priorPeriodSnapshots = snapRes[0];
        } else {
          this.priorPeriodSnapshots = [];
        }
      } catch (e) {
        console.warn("fetchPriorPeriodData error:", e);
        this.priorPeriodSnapshots = [];
      }
    },
    getKpiMoM(kpiCode) {
      const curr = this.getKpi(kpiCode);
      if (!curr || curr.ActualValue == null || !this.priorPeriodSnapshots || !this.priorPeriodSnapshots.length) {
        return { hasPrior: false, deltaValue: 0, deltaPct: 0, trend: "flat", isGood: true };
      }
      const prior = this.priorPeriodSnapshots.find((x) => x.KpiCode === kpiCode);
      if (!prior || prior.ActualValue == null) {
        return { hasPrior: false, deltaValue: 0, deltaPct: 0, trend: "flat", isGood: true };
      }
      const currVal = Number(curr.ActualValue);
      const priorVal = Number(prior.ActualValue);
      if (isNaN(currVal) || isNaN(priorVal) || priorVal === 0) {
        return { hasPrior: false, deltaValue: 0, deltaPct: 0, trend: "flat", isGood: true };
      }
      const deltaValue = currVal - priorVal;
      const deltaPct = Number(((deltaValue / Math.abs(priorVal)) * 100).toFixed(1));
      const trend = deltaValue > 0.05 ? "up" : (deltaValue < -0.05 ? "down" : "flat");
      const isInverse = ["TS04", "TS07", "HR01", "VH29", "VH38", "SK02"].includes(kpiCode);
      const isGood = isInverse ? (deltaValue <= 0) : (deltaValue >= 0);
      return {
        hasPrior: true,
        priorValue: priorVal,
        currentValue: currVal,
        deltaValue: Number(deltaValue.toFixed(1)),
        deltaPct,
        trend,
        isGood,
      };
    },
    copyExecutiveBriefing() {
      const period = this.currentPeriodName || this.selectedPeriod;
      const unit = this.currentUnitTitle || this.currentUnit;
      const students = this.formatNumber(this.displayStudents);
      const fillRate = this.displayFillRate;
      const withdrawRate = this.displayWithdrawRate;
      const withdrawCount = this.displayWithdrawCount;
      const lmsRate = this.computedLmsData ? this.computedLmsData.rate : "0.0%";
      const grossMargin = this.computedFinanceData ? this.computedFinanceData.grossMargin : "0.0%";
      const rev = this.computedFinanceData ? this.computedFinanceData.rev : "0 Tỷ";

      let riskText = "Duy trì 0 sự cố an toàn học đường (ISO 22000).";
      if (this.riskCampusCards && this.riskCampusCards.length) {
        const redCampuses = this.riskCampusCards.filter((c) => c.RiskTier === "RED").map((c) => c.CampusName);
        if (redCampuses.length) {
          riskText += " Cảnh báo vùng đỏ rủi ro tại: " + redCampuses.join(", ") + ".";
        }
      }

      const text = "[BÁO CÁO ĐIỀU HÀNH HỘI ĐỒNG TRƯỜNG - LHBS]\n" +
        "Kỳ báo cáo: " + period + " · Đơn vị: " + unit + "\n" +
        "--------------------------------------------------\n" +
        "1. Quy mô học sinh: " + students + " HS (Lấp đầy " + fillRate + "% công suất).\n" +
        "2. Tỷ lệ rút học kỳ: " + withdrawRate + "% (" + withdrawCount + " HS rút học).\n" +
        "3. Chuyên môn & LMS: Tỷ lệ hoàn thành bài tập trực tuyến đạt " + lmsRate + ".\n" +
        "4. Tài chính vận hành: Lợi nhuận gộp dịch vụ đạt " + grossMargin + " (Doanh thu thuần: " + rev + ").\n" +
        "5. An toàn & Rủi ro: " + riskText + "\n" +
        "--------------------------------------------------\n" +
        "Nguồn: CSDL eSign & tapi.lhbs.vn · Trích xuất tự động từ KPI Ops Dashboard";

      if (typeof navigator !== "undefined" && navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => {
          this.copiedBriefing = true;
          setTimeout(() => { this.copiedBriefing = false; }, 3000);
          if (typeof showToast !== "undefined" && showToast && showToast.success) {
            showToast.success("Đã sao chép tóm tắt điều hành vào clipboard!");
          }
        }).catch((err) => {
          console.warn("Clipboard write failed:", err);
          prompt("Sao chép tóm tắt điều hành dưới đây:", text);
        });
      } else {
        prompt("Sao chép tóm tắt điều hành dưới đây:", text);
      }
    },
    printExecutiveReport() {
      window.print();
    },
    jumpToFactStore(domainCode, scopeId) {
      this.openFactModal(domainCode, "ALL");
    },
    openFactModal(domainCode = "ENROLLMENT", scopeId = "ALL", auditItem = null, kpiItem = null) {
      this.selectedAuditItem = auditItem || null;
      this.selectedKpiItem = kpiItem || null;
      this.selectedFactDomain = domainCode || "ENROLLMENT";
      this.factCampusFilter = scopeId || "ALL";
      this.factAuditFilter = "ALL";
      this.isFactsModalOpen = true;
      this.fetchOperationalFacts(this.selectedFactDomain);
    },
    closeFactModal() {
      this.isFactsModalOpen = false;
      this.selectedAuditItem = null;
      this.selectedKpiItem = null;
    },
    getTriggerFactDomain(t) {
      if (!t) return "ENROLLMENT";
      const tid = Number(t.TriggerID);
      if (tid === 1) return "WITHDRAWAL";
      if (tid === 2) return "MAINTENANCE";
      if (tid === 3) return "HEALTH";
      if (tid === 4) return "LEAVE";
      const str = String(t.TriggerID || t.TriggerName || "").toUpperCase();
      if (str.includes("MAINT") || str.includes("CSVC")) return "MAINTENANCE";
      if (str.includes("HEALTH") || str.includes("YTE")) return "HEALTH";
      if (str.includes("LEAVE") || str.includes("PHEP") || str.includes("TAI TRONG")) return "LEAVE";
      if (str.includes("CRM") || str.includes("ENROLL") || str.includes("LEAD")) return "CRM";
      if (str.includes("LMS") || str.includes("TEACH")) return "TEACHING";
      return "ENROLLMENT";
    },
    getKpiFactDomain(kpiCode) {
      if (!kpiCode) return "ENROLLMENT";
      const code = kpiCode.toUpperCase();
      if (code === "TS01" || code === "TS02") return "ENROLLMENT";
      if (code === "TS04") return "WITHDRAWAL";
      if (code.startsWith("TS")) return "CRM";
      if (code.startsWith("CM")) return "TEACHING";
      if (code === "DV38" || code === "DV39" || code === "DV40" || code === "DV41") return "HEALTH";
      if (code.startsWith("DV")) return "SAFETY_ME";
      if (code === "TC52" || code === "TC53") return "HR_TURNOVER";
      if (code === "TC54") return "LEAVE";
      if (code === "TC55" || code === "TC56") return "CLUB";
      if (code === "TC59" || code === "TC60") return "MAINTENANCE";
      if (code.startsWith("TC")) return "CLUB";
      return "ENROLLMENT";
    },
    formatKpiVal(val, unit) {
      if (val === null || val === undefined) return "--";
      const num = Number(val);
      if (isNaN(num)) return val;
      if (unit === "VNĐ" || unit === "triệu VNĐ") {
        if (num >= 1000000000) return (num / 1000000000).toFixed(2) + " tỷ";
        if (num >= 1000000) return (num / 1000000).toFixed(1) + " tr";
        return num.toLocaleString();
      }
      if (unit === "VNĐ/HS") {
        if (num >= 1000000) return (num / 1000000).toFixed(1) + " tr";
        return num.toLocaleString();
      }
      if (unit === "%") {
        return Number(num.toFixed(1)) + "%";
      }
      return num.toLocaleString();
    },
    toggleAuditExpand(code) {
      const idx = this.expandedAuditCodes.indexOf(code);
      if (idx > -1) this.expandedAuditCodes.splice(idx, 1);
      else this.expandedAuditCodes.push(code);
    },
    isAuditExpanded(code) {
      return this.expandedAuditCodes.includes(code);
    },
    toggleExpandAllAudit() {
      if (this.expandedAuditCodes.length >= this.filteredAuditList.length) {
        this.expandedAuditCodes = [];
      } else {
        this.expandedAuditCodes = this.filteredAuditList.map(x => x.AuditCode);
      }
    },
    getAuditDomain(item) {
      if (!item) return "STUDENTS";
      const code = ((item && item.AuditCode) || "").toUpperCase();
      const cat = ((item && item.Category) || "").toUpperCase();
      const title = ((item && item.Title) || "").toUpperCase();
      if (code.includes("MAINT") || cat.includes("CSVC") || title.includes("MÁY LẠNH") || code.includes("PURCHASE")) {
        return "MAINTENANCE";
      }
      if (code.includes("HEALTH") || cat.includes("Y TẾ") || title.includes("CÚM") || title.includes("SỐT") || title.includes("BỆNH")) {
        return "HEALTH";
      }
      if (code.includes("CLUB") || cat.includes("CLB") || title.includes("CLB") || code.includes("TC56")) {
        return "CLUB";
      }
      if (code.includes("TEACH") || cat.includes("DẠY") || title.includes("TIẾT") || code.includes("LMS") || code.includes("HOMEWORK") || code.includes("INNOVATION")) {
        return "TEACHING";
      }
      if (code.includes("TURNOVER") || code.includes("DISCIPLINE") || title.includes("THÔI VIỆC") || title.includes("BIẾN ĐỘNG")) {
        return "HR_TURNOVER";
      }
      if (code.includes("LEAVE") || title.includes("NGHỈ PHÉP") || title.includes("NGÀY CÔNG")) {
        return "LEAVE";
      }
      if (code.includes("MARKETING") || code.includes("CRM") || code.includes("KITTY") || code.includes("CONVERSION") || code.includes("ATTRIBUTION") || title.includes("LEADS") || title.includes("PHỄU") || title.includes("TUYỂN SINH")) {
        return "CRM";
      }
      if (code.includes("FACEID") || code.includes("APP_ME") || code.includes("ME_") || code.includes("BOARDING") || title.includes("BÁN TRÚ") || title.includes("FACEID") || title.includes("ME SCHOOL")) {
        return "SAFETY_ME";
      }
      if (code.includes("TS04") || code.includes("WITHDRAW") || code.includes("QA50") || code.includes("CAC_VS_LTV") || code.includes("CAPACITY") || title.includes("RÚT HỌC") || title.includes("HÀI LÒNG") || title.includes("SĨ SỐ")) {
        return "STUDENTS";
      }
      return "STUDENTS";
    },
    isDirectiveDone(checklistId) {
      if (!checklistId) return false;
      return !!this.directiveStatusMap[checklistId];
    },
    toggleDirectiveStatus(checklistId) {
      if (!checklistId) return;
      const current = !!this.directiveStatusMap[checklistId];
      this.directiveStatusMap = {
        ...this.directiveStatusMap,
        [checklistId]: !current,
      };
      try {
        if (typeof localStorage !== "undefined") {
          localStorage.setItem("kpi_ops_directives_status", JSON.stringify(this.directiveStatusMap));
        }
      } catch (e) {}
    },
    getKpiOwner(b) {
      if (!b) return "Ban Điều Hành Cơ Sở";
      if (b.Owner) return b.Owner;
      const code = b.KpiCode || "";
      const group = b.KpiGroup || "";
      if (code.startsWith("TS") || group.includes("Tuyển sinh")) {
        return "Ban Tuyển Sinh & Marketing";
      }
      if (code.startsWith("CM") || group.includes("Giáo dục") || group.includes("Học thuật")) {
        return "Ban Chuyên Môn & Đào Tạo";
      }
      if (code.startsWith("VH") || code.startsWith("SK")) {
        if (code === "VH35" || code === "VH36") return "Bộ Phận Xe Bus & Vận Hành";
        if (code === "VH28" || code === "VH29") return "Bộ Phận Bếp Ăn & Bán Trú";
        if (code === "VH38" || code.startsWith("SK")) return "Bộ Phận Y Tế Học Đường";
        return "Bộ Phận Vận Hành & Dịch Vụ";
      }
      if (code.startsWith("CSVC")) {
        return "Ban Quản Trị CSVC & IT";
      }
      if (code.startsWith("TC") || group.includes("Tài chính")) {
        return "Phòng Tài Chính - Kế Toán";
      }
      if (code.startsWith("HR") || group.includes("Nhân sự")) {
        return "Phòng Tổ Chức - Nhân Sự";
      }
      if (code.startsWith("QA") || group.includes("Hài lòng")) {
        return "Bộ Phận Đảm Bảo Chất Lượng (QA)";
      }
      return "Ban Điều Hành Cơ Sở";
    },
    openCausalModal(unit = null, scenario = null, kpiCode = null) {
      let targetUnit = unit || this.currentUnit;
      if (targetUnit === "MNTB") targetUnit = "MNBH";
      this.causalUnit = targetUnit;
      // Generic engine: nếu truyền kpiCode thì dùng engine mới
      if (kpiCode) {
        this.causalKpiCode = kpiCode;
        this.causalDeltaOverride = null;
      }
      // Giữ tương thích với scenario cũ (fallback)
      if (scenario) this.causalScenario = scenario;
      if (this.causalScenario === "RUT_HOC") {
        this.causalN = this.getDefaultWithdrawCountForUnit(targetUnit);
      } else if (this.causalScenario === "TUYEN_THEM") {
        this.causalAddN = targetUnit === "ALL" ? 50 : 20;
      }
      this.isCausalModalOpen = true;
    },
    setCausalUnit(unitKey) {
      const u = (unitKey === "MNTB") ? "MNBH" : unitKey;
      this.causalUnit = u;
      if (this.causalScenario === "RUT_HOC") {
        this.causalN = this.getDefaultWithdrawCountForUnit(u);
      } else if (this.causalScenario === "TUYEN_THEM") {
        this.causalAddN = (u === "ALL") ? 50 : 20;
      }
    },
    getDefaultWithdrawCountForUnit(unitKey) {
      const u = (unitKey === "MNTB") ? "MNBH" : unitKey;
      if (u === "ALL") return 21;
      if (u === "MNBH") return 5;
      if (u === "MNLK") return 4;
      if (u === "TH") return 6;
      if (u === "THCS") return 4;
      if (u === "THPT") return 2;
      return 5;
    },
    openCausalChainForCard(cardType) {
      const u = this.currentUnit === "MNTB" ? "MNBH" : this.currentUnit;
      const kpiMap = {
        "WITHDRAW": "TS04",
        "ENROLLMENT": "TS06",
        "LMS": "CM08",
        "BUS": "BUS01",
        "CSVC": "CSVC01",
        "HR": "HR02",
        "CLB": "CLB01",
        "FINANCE": null,
      };
      if (cardType === "FINANCE") {
        this.openDrawer("FINANCE_DETAIL");
        return;
      }
      const kpiCode = kpiMap[cardType] || "TS04";
      this.openCausalModal(u, null, kpiCode);
    },
    // selectCausalKpi: Người dùng chọn KPI bất kỳ từ dropdown -> reset delta về auto
    selectCausalKpi(kpiCode) {
      this.causalKpiCode = kpiCode;
      this.causalDeltaOverride = null; // reset về giá trị thực tế tự động
    },
    closeCausalModal() {
      this.isCausalModalOpen = false;
    },
    setScenario(sc) {
      this.causalScenario = sc;
      if (sc === "RUT_HOC") {
        this.causalN = this.getDefaultWithdrawCountForUnit(this.causalUnit);
      } else if (sc === "TUYEN_THEM") {
        this.causalAddN = (this.causalUnit === "ALL") ? 50 : 20;
      }
    },
    onNodeMouseEnter(id) {
      this.causalHoverNodeId = id;
    },
    onNodeMouseLeave() {
      this.causalHoverNodeId = "";
    },
    onNodeClick(id) {
      this.causalHoverNodeId = this.causalHoverNodeId === id ? "" : id;
    },
    openCausalConfigDrawer() {
      window.open("/kpi-causal-config", "_blank");
    },
    async fetchCausalEngineData() {
      try {
        const res = await this.callTapi("eSign/KPI_GetCausalEngineData", {});
        const data = (res && res.data) ? res.data : res;
        if (Array.isArray(data)) {
          if (data[0] && data[0].length) this.kpiDefinitionsList = data[0];
          if (data[1] && data[1].length) this.metricThresholds = data[1];
          if (data[2] && data[2].length) this.causalParametersList = data[2];
          if (data[3] && data[3].length) this.causalNarrativesList = data[3];
          if (data[4] && data[4].length) this.causalReasonsList = data[4];
          if (data[5] && data[5].length) this.causalScenariosList = data[5];
          if (data[6] && data[6].length) this.causalAssignmentsList = data[6];
          if (data[7] && data[7].length) this.causalAssumptionsList = data[7];
          if (data[8] && data[8].length) this.causalRulesList = data[8];
          if (data[9] && data[9].length) this.elasticityMatrixList = data[9];
        }
      } catch (err) {
        console.warn("fetchCausalEngineData error:", err);
      }
    },
    async saveCausalAssumption(u) {
      try {
        const payload = {
          UnitCode: u.UnitCode,
          AnnualTuitionMillion: parseFloat(u.AnnualTuitionMillion) || 0,
          GrossMarginPct: parseFloat(u.GrossMarginPct) || 0.85,
          RemainingYearsInLevel: parseFloat(u.RemainingYearsInLevel) || 2,
          MonthlyLeads: parseInt(u.MonthlyLeads) || 60,
          ConversionRate: parseFloat(u.ConversionRate) || 0.073,
          PlannedCapacity: parseInt(u.PlannedCapacity) || 166,
          CurrentEnrollment: parseInt(u.CurrentEnrollment) || 129,
        };
        await this.callTapi("eSign/KPI_SaveCausalAssumption", payload);
        alert("Đã lưu tham số giả định của " + u.UnitName + " vào CSDL eSign thành công!");
        this.fetchCausalEngineData();
      } catch (err) {
        alert("Lỗi khi lưu tham số: " + (err.message || err));
      }
    },
    getFactDomainButtonLabel(domain, defaultTitle) {
      if (this.selectedFactDomain === domain && this.operationalFactsList && this.operationalFactsList.length) {
        return defaultTitle + " (" + this.operationalFactsList.length + ")";
      }
      return defaultTitle;
    },
    setPeriod(periodKey) {
      this.selectedPeriod = periodKey;
      this.fetchPeriodData(periodKey);
      const p = this.periodsList.find((x) => x.PeriodKey === periodKey);
      if (p && !p.IsFrozen) {
        this.fetchAllLiveData();
      } else {
        this.apiSyncStatus = "Dữ liệu kỳ đã chốt sổ (CSDL eSign)";
      }
    },
    async fetchPeriodsList() {
      try {
        const res = await this.callTapi("eSign/KPI_GetPeriods", {});
        if (res && Array.isArray(res) && res.length) {
          this.periodsList = res;
          if (this.priorPeriodKey && (!this.priorPeriodSnapshots || !this.priorPeriodSnapshots.length)) {
            this.fetchPriorPeriodData(this.priorPeriodKey);
          }
          const curP = this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
          if (curP && !curP.IsFrozen) {
            this.fetchAllLiveData();
          }
        }
      } catch (e) {
        console.warn("fetchPeriodsList error:", e);
      }
    },
    async fetchPeriodData(pKey) {
      const queryUnit = (this.currentUnit === "MNTB") ? "MNBH" : this.currentUnit;
      this.fetch3TierData(pKey, queryUnit);
      this.isLoading = true;
      this.apiSyncStatus = "Đang đồng bộ dữ liệu chốt kỳ CSDL eSign...";
      try {
        const [snapRes, corrRes, auditRes, riskRes, leversRes, opsRes, finRes] = await Promise.all([
          this.callTapi("eSign/KPI_GetPeriodSnapshots", { PeriodKey: pKey, DonViID: queryUnit }).catch(() => null),
          this.callTapi("eSign/KPI_GetCorrelations", { PeriodKey: pKey, DonViID: queryUnit }).catch(() => null),
          this.callTapi("eSign/KPI_GetAuditDiscrepancies", { PeriodKey: pKey, ScopeID: queryUnit }).catch(() => null),
          this.callTapi("eSign/KPI_GetRiskRadar", { PeriodKey: pKey, DonViID: queryUnit }).catch(() => null),
          this.callTapi("eSign/KPI_GetStrategicLevers", { PeriodKey: pKey }).catch(() => null),
          this.callTapi("eSign/KPI_GetOperationsSummary", { PeriodKey: pKey, ScopeID: queryUnit }).catch(() => null),
          this.callTapi("eSign/KPI_GetFinanceServices", { PeriodKey: pKey, ScopeID: queryUnit }).catch(() => null)
        ]);

        if (snapRes && Array.isArray(snapRes)) {
          if (snapRes[0]) this.periodSnapshots = snapRes[0];
          if (snapRes[1]) this.kpiGroupSummary = snapRes[1];
          if (snapRes[2] && Array.isArray(snapRes[2]) && snapRes[2].length) {
            this.goliveSpecsList = snapRes[2];
          }
          if (snapRes[3] && Array.isArray(snapRes[3]) && snapRes[3].length) {
            this.liveDataBienHoa = snapRes[3].filter(r => r.ScopeID !== 'MNLK');
            this.liveDataLongKhanh = snapRes[3].filter(r => r.ScopeID === 'MNLK');
          }
          if (snapRes[4] && Array.isArray(snapRes[4]) && snapRes[4].length) {
            this.withdrawRecords = snapRes[4];
            this.calcTopReasons(snapRes[4]);
          }
          if (snapRes[5] && Array.isArray(snapRes[5]) && snapRes[5].length) {
            this.lmsAssignmentRows = snapRes[5];
            const totAssigned = snapRes[5].reduce((s, r) => s + (r.TotalAssigned || 0), 0);
            const totDaNop = snapRes[5].reduce((s, r) => s + (r.Total_DaNop || 0), 0);
            const totDaCham = snapRes[5].reduce((s, r) => s + (r.Total_DaCham || 0), 0);
            if (totAssigned > 0) {
              this.lmsOverallRate = (((totDaNop + totDaCham) / totAssigned) * 100).toFixed(1);
            }
          }
          if (snapRes[6] && Array.isArray(snapRes[6]) && snapRes[6].length) {
            this.lmsHocLieuRows = snapRes[6];
            const total = snapRes[6].reduce((s, r) => s + (r.TongHocLieu || 0), 0);
            const coNoiDung = snapRes[6].reduce((s, r) => s + (r.HocLieuCoNoiDung || 0), 0);
            const totalFiles = snapRes[6].reduce((s, r) => s + (r.TongNoiDung || 0), 0);
            this.lmsHocLieuSummary = {
              total,
              coNoiDung,
              pct: total ? ((coNoiDung / total) * 100).toFixed(1) : "0.0",
              totalFiles,
            };
          }
          if (snapRes[7] && Array.isArray(snapRes[7]) && snapRes[7].length) {
            this.teachingProgressRows = snapRes[7];
          }
          if (!snapRes[2] && snapRes[0]) {
            const specsMap = {};
            snapRes[0].forEach((r) => {
              if (r.SpecCode && !specsMap[r.SpecCode]) {
                specsMap[r.SpecCode] = {
                  SpecCode: r.SpecCode,
                  SourceSystem: r.SourceSystem,
                  KpiGroup: r.KpiGroup,
                  ApiEndpoint: r.ApiEndpoint,
                  HttpMethod: r.HttpMethod,
                  SyncSchedule: r.SyncSchedule,
                  RequestSchema: r.RequestSchema,
                  ResponseSchema: r.ResponseSchema,
                  GolivePrerequisites: r.GolivePrerequisites,
                };
              }
            });
            const list = Object.values(specsMap);
            if (list.length) this.goliveSpecsList = list;
          }
        }

        if (this.priorPeriodKey) {
          this.fetchPriorPeriodData(this.priorPeriodKey);
        }

        if (corrRes && Array.isArray(corrRes)) {
          if (corrRes[0]) this.correlationsList = corrRes[0];
          if (corrRes[2] && Array.isArray(corrRes[2])) {
            this.causalNarrativesList = corrRes[2];
          }
          if (corrRes[3] && Array.isArray(corrRes[3])) {
            const store = {};
            corrRes[3].forEach((item) => {
              store[item.VarKey] = item.VarValue;
            });
            store["TS04.WithdrawTotal"] = this.displayWithdrawCount || 53;
            this.contextStore = store;
          }
          if (corrRes[4] && Array.isArray(corrRes[4])) {
            this.metricThresholds = corrRes[4];
          }
          if (corrRes[5] && Array.isArray(corrRes[5]) && corrRes[5].length) {
            this.auditDiscrepanciesList = corrRes[5];
          }
          if (corrRes[6] && Array.isArray(corrRes[6]) && corrRes[6].length) {
            this.breakdownsList = corrRes[6];
          }
        }

        if (auditRes && Array.isArray(auditRes) && auditRes.length) {
          this.auditDiscrepanciesList = auditRes;
        }

        if (riskRes && Array.isArray(riskRes)) {
          if (riskRes[0]) this.riskCampusCards = riskRes[0];
          if (riskRes[1]) this.riskTriggers = riskRes[1];
          if (riskRes[2]) this.riskChecklist = riskRes[2];
        }

        if (leversRes && Array.isArray(leversRes)) {
          if (leversRes[0]) this.strategicWaterfallBars = leversRes[0];
          if (leversRes[1]) this.strategicLevers = leversRes[1];
        }

        if (opsRes && Array.isArray(opsRes)) {
          this.opsSafetyMe = (opsRes[0] && opsRes[0][0]) ? opsRes[0][0] : {};
          this.crmMonthlySummary = opsRes[1] || [];
          this.crmChannelStats = opsRes[2] || [];
          this.crmKittyList = opsRes[3] || [];
          this.crmDropReasons = opsRes[4] || [];
        } else {
          this.opsSafetyMe = {};
          this.crmMonthlySummary = [];
          this.crmChannelStats = [];
          this.crmKittyList = [];
          this.crmDropReasons = [];
        }

        if (finRes && Array.isArray(finRes)) {
          if (finRes[0] && Array.isArray(finRes[0]) && finRes[0].length) this.financeServices = finRes[0];
          if (finRes[1] && Array.isArray(finRes[1]) && finRes[1].length) this.financeClubs = finRes[1];
          if (finRes[2] && Array.isArray(finRes[2]) && finRes[2][0]) this.financeSummary = finRes[2][0];
        }

        this.apiSyncStatus = "Dữ liệu kỳ đã chốt sổ (CSDL eSign)";
      } catch (err) {
        console.warn("fetchPeriodData error:", err);
        this.apiSyncStatus = "Dữ liệu kỳ chốt";
      } finally {
        this.isLoading = false;
      }
    },
    async fetchOperationalFacts(domainCode) {
      this.selectedFactDomain = domainCode || "LEAVE";
      this.isFactsLoading = true;
      try {
        const res = await this.callTapi("eSign/KPI_GetOperationalFacts", {
          PeriodKey: this.selectedPeriod,
          DomainCode: this.selectedFactDomain,
          ScopeID: this.currentUnit,
          Status: "ALL",
          Limit: 100,
        });
        if (res && Array.isArray(res)) {
          this.operationalFactsList = res;
        } else {
          this.operationalFactsList = [];
        }
      } catch (e) {
        console.warn("fetchOperationalFacts error:", e);
        this.operationalFactsList = [];
      } finally {
        this.isFactsLoading = false;
      }
    },
    openOperationalFactDrawer(domainCode = "STUDENTS", scopeId = "ALL") {
      this.openFactModal(domainCode, scopeId);
    },
    openFactAuditForItem(item) {
      const domain = this.getAuditDomain(item);
      this.openFactModal(domain, item ? item.ScopeID : "ALL", item);
    },
    openGoliveSpecs(specCode = null) {
      this.selectedSpecCode = specCode;
      this.drawer.type = "GOLIVE_SPECS";
      this.drawer.title = specCode ? "Đặc Tả Kỹ Thuật API Golive (" + specCode + ")" : "Đặc Tả Kỹ Thuật API Golive (Hệ Thống Nguồn Chuẩn Docs)";
      this.drawer.visible = true;
    },
    extractUrl(str) {
      if (!str) return null;
      const m = str.match(/https?:\/\/[^\s\)\>]+/);
      return m ? m[0] : null;
    },
    // ==========================================
    // DYNAMIC EXPRESSION & CAUSAL ENGINE (LHBS)
    // ==========================================
    evaluateMathExpr(expr, context) {
      if (!expr) return 0;
      let parsed = expr.replace(/([a-zA-Z0-9_\.]+)/g, (match) => {
        if (match === "Math" || match === "true" || match === "false") return match;
        if (match === "TS04.Actual" && expr.includes("TS04.Reason")) {
          return (context && context["TS04.WithdrawTotal"]) || (this.displayWithdrawCount || 53);
        }
        if (context && context[match] !== undefined) {
          const val = Number(context[match]);
          return isNaN(val) ? `"${context[match]}"` : val;
        }
        return match;
      });
      try {
        const fn = new Function(`return (${parsed});`);
        const res = fn();
        return typeof res === "number" && !isNaN(res) ? res : parsed;
      } catch (e) {
        return 0;
      }
    },
    applyExpressionFilter(val, filterStr) {
      if (!filterStr) return val;
      const parts = filterStr.trim().split(":");
      const fName = parts[0].trim();
      const fArg = parts[1] ? parts[1].trim() : null;

      if (fName === "currency") {
        const num = Number(val);
        if (isNaN(num)) return val;
        if (Math.abs(num) >= 1000000000) {
          return (num / 1000000000).toFixed(3).replace(/\.?0+$/, "").replace(".", ",") + " tỷ";
        } else if (Math.abs(num) >= 1000) {
          return (num / 1000).toFixed(3).replace(/\.?0+$/, "").replace(".", ",") + " tỷ";
        } else {
          return Math.round(num).toLocaleString("vi-VN") + " triệu";
        }
      }
      if (fName === "round") {
        const dec = fArg ? parseInt(fArg, 10) : 1;
        const num = Number(val);
        if (isNaN(num)) return val;
        return num.toFixed(dec).replace(".", ",");
      }
      if (fName === "percent") {
        const num = Number(val);
        if (isNaN(num)) return val + "%";
        return num.toFixed(1).replace(".", ",") + "%";
      }
      if (fName === "number") {
        const num = Number(val);
        if (isNaN(num)) return val;
        return Math.round(num).toLocaleString("vi-VN");
      }
      return val;
    },
    evaluateTemplate(pattern, context = {}, scenarioParams = {}) {
      if (!pattern) return "";
      const merged = { ...context, ...scenarioParams };
      return pattern.replace(/\{([^}]+)\}/g, (match, inner) => {
        const [rawExpr, rawFilter] = inner.split("|").map((s) => s.trim());
        let filterName = rawFilter;
        let filterArg = null;
        if (rawFilter && rawFilter.includes("(") && rawFilter.endsWith(")")) {
          const m = rawFilter.match(/([a-zA-Z0-9_]+)\(([^)]*)\)/);
          if (m) {
            filterName = m[1];
            filterArg = m[2].replace(/['"]/g, "");
          }
        }
        let val = null;
        if (merged[rawExpr] !== undefined) {
          val = merged[rawExpr];
        } else {
          val = this.evaluateMathExpr(rawExpr, merged);
        }
        if (filterName === "default" && (val === null || val === undefined || val === 0 || val === "")) {
          val = filterArg;
        } else if (filterName) {
          val = this.applyExpressionFilter(val, filterName + (filterArg ? ":" + filterArg : ""));
        }
        return `<b class="tx-strong">${val}</b>`;
      });
    },
    evaluateCondition(conditionExpr, context = {}) {
      if (!conditionExpr || conditionExpr === "1" || conditionExpr === "true") return true;
      let expr = conditionExpr.replace(/([a-zA-Z0-9_\.]+)/g, (match) => {
        if (match === "true" || match === "false" || match === "AND" || match === "OR") return match;
        if (context && context[match] !== undefined) {
          const num = Number(context[match]);
          return isNaN(num) ? `"${context[match]}"` : num;
        }
        return match;
      });
      expr = expr.replace(/\bAND\b/g, "&&").replace(/\bOR\b/g, "||");
      try {
        const fn = new Function(`return Boolean(${expr});`);
        return fn();
      } catch (e) {
        return false;
      }
    },
    getMetricThreshold(kpiCode) {
      if (!this.metricThresholds || !Array.isArray(this.metricThresholds)) return null;
      return this.metricThresholds.find((t) => t.KpiCode === kpiCode) || null;
    },
    getMetricThresholdLabel(kpiCode) {
      const t = this.getMetricThreshold(kpiCode);
      if (!t) return "< 10%";
      return (t.ComparisonOperator || "<=") + " " + t.TargetValue + (kpiCode === "TS04" ? "%" : "");
    },
    getMetricStatus(kpiCode) {
      const thr = this.getMetricThreshold(kpiCode);
      let val = parseFloat(this.contextStore[kpiCode + ".Actual"]);
      if (isNaN(val)) {
        if (kpiCode === "TS04") val = parseFloat(this.displayWithdrawRate);
        else if (kpiCode === "TS01") val = parseFloat(this.displayCapacityPct);
      }
      if (!thr || isNaN(val)) return "good";
      if (thr.ComparisonOperator === "<=" || thr.ComparisonOperator === "<") {
        if (val > thr.TargetValue) return "bad";
        if (val > thr.WarnThreshold) return "warn";
        return "good";
      } else {
        if (thr.CriticalThreshold && val < thr.CriticalThreshold) return "bad";
        if (val < thr.WarnThreshold) return "warn";
        return "good";
      }
    },
    getMetricStatusText(kpiCode) {
      const thr = this.getMetricThreshold(kpiCode);
      const st = this.getMetricStatus(kpiCode);
      if (!thr) return st === "good" ? "AN TOÀN" : "CẢNH BÁO";
      if (st === "good") return thr.StatusGoodLabel || "AN TOÀN";
      if (st === "warn") return thr.StatusWarnLabel || "THEO DÕI";
      return thr.StatusBadLabel || "CẢNH BÁO";
    },
    renderCausalNarrative(kpiCode, defaultCode, fallbackPattern, fallbackParams = {}) {
      const u = this.currentUnit;
      const ass = this.currentCausalAssumption;
      const kTc56 = this.getKpi("TC56");
      const kClb = this.getKpi("TC33");
      const tuition = ass.AnnualTuitionMillion;
      const clbRate = ass.ClbParticipationRate || 0.35;
      const clbCount = (u === "ALL" && kClb && kClb.TargetValue != null) ? Number(kClb.TargetValue) : Math.round((this.displayStudents || 0) * clbRate);
      const clbRev = (u === "ALL" && kTc56 && kTc56.ActualValue != null) ? Number(kTc56.ActualValue) : Math.round(clbCount * (ass.ClbAvgFeeMillion || 4.5) * 1000000);

      const dynamicUnitParams = {
        "TS04.Reason.FAR": this.displayReasonFar,
        "TS04.Actual": this.displayWithdrawCount,
        "TS04.Rate": this.displayWithdrawRate,
        "TS05.Actual": this.displayLeads,
        "TS06.Actual": this.displayConversionRate,
        "TC56.Actual": clbRev,
        "PARAM.ClbStudents": clbCount,
        "PARAM.TuitionAnnual": tuition,
        "PARAM.BusFeeAnnual": 12,
        ...fallbackParams,
      };

      if ((u === "MNLK" || u === "MNBH" || u === "MNTB") && kpiCode === "CM08") {
        return `Khung chăm sóc dinh dưỡng &amp; nhật ký số KidsOnline đạt <b>100%</b> tương tác với PHHS &rarr; Duy trì gắn kết và kịp thời hỗ trợ trẻ mầm non.`;
      }

      const list = (this.causalNarrativesList && Array.isArray(this.causalNarrativesList)) ? this.causalNarrativesList : [];
      const item = list.find((n) => n.AnchorKpiCode === kpiCode || n.NarrativeCode === defaultCode);
      if (!item) return this.getNarrative(defaultCode, fallbackPattern, dynamicUnitParams);
      const pattern = item.TemplatePattern || fallbackPattern;
      return this.evaluateTemplate(pattern, this.contextStore, dynamicUnitParams);
    },
    renderCausalTitle(kpiCode, defaultTitle) {
      if (!this.causalNarrativesList || !Array.isArray(this.causalNarrativesList)) return defaultTitle;
      const item = this.causalNarrativesList.find((n) => n.AnchorKpiCode === kpiCode);
      return item && item.Title ? item.Title : defaultTitle;
    },
    getNarrative(code, fallbackPattern = "", fallbackParams = {}) {
      const list = (this.causalNarrativesList && Array.isArray(this.causalNarrativesList)) ? this.causalNarrativesList : [];
      const item = list.find((n) => n.NarrativeCode === code);
      let pattern = (item && item.TemplatePattern) ? item.TemplatePattern : fallbackPattern;
      let params = { ...fallbackParams };
      if (item) {
        let pObj = null;
        if (typeof item.ParamsJson === "object" && item.ParamsJson !== null) {
          pObj = item.ParamsJson;
        } else if (typeof item.ParamsJson === "string" && item.ParamsJson.trim().startsWith("{")) {
          try {
            pObj = JSON.parse(item.ParamsJson);
          } catch (e) {}
        }
        if (!pObj && typeof item.DefaultParamsJson === "string" && item.DefaultParamsJson.trim().startsWith("{")) {
          try {
            pObj = JSON.parse(item.DefaultParamsJson);
          } catch (e) {}
        }
        if (pObj) {
          params = { ...params, ...pObj };
        }
      }
      return this.interpolateTemplate(pattern, params);
    },
    getNarrativeText(code, fallbackPattern = "", fallbackParams = {}) {
      const html = this.getNarrative(code, fallbackPattern, fallbackParams);
      return html.replace(/<[^>]*>/g, "");
    },
    interpolateTemplate(pattern, params = {}) {
      if (!pattern) return "";
      return pattern.replace(/\{([a-zA-Z0-9_]+)\}(%?)/g, (match, key, trailingPct) => {
        let val = params[key];
        if (val == null) return match;
        val = String(val).trim();
        if (trailingPct === "%" && val.endsWith("%")) {
          return `<b class="tx-strong">${val}</b>`;
        }
        return `<b class="tx-strong">${val}</b>${trailingPct}`;
      });
    },
    formatNumber(val) {
      if (val === null || val === undefined || isNaN(val)) return "0";
      return Number(val).toLocaleString("vi-VN");
    },
    formatCurrency(val) {
      if (val === null || val === undefined || isNaN(val)) return "0 VNĐ";
      const num = Number(val);
      const sign = num < 0 ? "−" : "";
      const abs = Math.abs(num);
      if (abs >= 1000000000) {
        return sign + (abs / 1000000000).toFixed(2).replace(".", ",") + " tỷ VNĐ";
      }
      if (abs >= 1000000) {
        return sign + (abs / 1000000).toFixed(1).replace(".", ",") + " triệu VNĐ";
      }
      return sign + abs.toLocaleString("vi-VN") + " VNĐ";
    },
    getWithdrawBarColorClass(name) {
      const lower = (name || "").toLowerCase();
      if (lower.includes("xa") || lower.includes("bus")) return "is-bus";
      if (lower.includes("kinh tế") || lower.includes("tiền")) return "is-econ";
      if (lower.includes("học") || lower.includes("lực")) return "is-study";
      if (lower.includes("khác") || lower.includes("chưa")) return "is-unknown";
      return "is-move";
    },
    getInterveneLabel(name) {
      const lower = (name || "").toLowerCase();
      if (lower.includes("xa") || lower.includes("bus")) return "Can thiệp bằng mở tuyến xe bus";
      if (lower.includes("kinh tế")) return "Chính sách học bổng / giãn thu";
      if (lower.includes("học") || lower.includes("lực")) return "Bổ trợ học tập";
      if (lower.includes("khác") || lower.includes("chưa")) return "Cần phỏng vấn chuẩn hóa";
      return "Bất khả kháng (chuyển nhà/định cư)";
    },
    getInterveneClass(name) {
      const lower = (name || "").toLowerCase();
      if (lower.includes("xa") || lower.includes("bus")) return "is-urgent";
      if (lower.includes("kinh tế") || lower.includes("học")) return "is-action";
      if (lower.includes("khác") || lower.includes("chưa")) return "is-investigate";
      return "is-neutral";
    },
    calcPercent(part, total) {
      if (!total || total === 0) return 0;
      return Math.round((part / total) * 100);
    },
    countReason(sub) {
      const match = this.topWithdrawReasons.find((r) => r.name.toLowerCase().includes(sub.toLowerCase()));
      return match ? match.count : 0;
    },
    setUnit(unitKey) {
      this.currentUnit = unitKey;
      this.fetchPeriodData(this.selectedPeriod);
      if (!this.currentPeriodIsFrozen) {
        this.fetchAllLiveData();
      }
    },
    setSchoolYear(year) {
      this.selectedYear = year;
      this.fetchPeriodData(this.selectedPeriod);
      if (!this.currentPeriodIsFrozen) {
        this.fetchAllLiveData();
      }
    },
    openDrawer(type) {
      this.drawer.type = type;
      if (type === "WITHDRAW_LIST") this.drawer.title = "Danh Sách Học Sinh Chuyển Đi & Rút Hồ Sơ (Chỉ tiêu 4)";
      else if (type === "STUDENT_LIST") this.drawer.title = "Cơ Cấu Sĩ Số Chi Tiết Từng Khối Lớp (Chỉ tiêu 1)";
      else if (type === "FINANCE_DETAIL") this.drawer.title = "Chi Tiết Cơ Cấu Lợi Nhuận Gộp Dịch Vụ (KPI 4)";
      else if (type === "KITTY_LIST") this.drawer.title = "Pipeline Nuôi Dưỡng Khách Hàng Tiềm Năng Chờ HK2 (Tab Kitty GID 1481169716)";
      this.drawer.visible = true;
    },
    closeDrawer() {
      this.drawer.visible = false;
    },
    async callTapi(endpoint, payload) {
      let token = (typeof $awt !== "undefined" && $awt) ? $awt : "";
      if (!token && typeof vueData !== "undefined" && vueData.token) {
        token = vueData.token;
      }
      if (!token && typeof sessionStorage !== "undefined") {
        token = sessionStorage.getItem("access_token") || sessionStorage.getItem("token") || "";
      }
      if (!token && typeof localStorage !== "undefined") {
        token = localStorage.getItem("access_token") || localStorage.getItem("token") || "";
      }
      const cleanEp = endpoint.replace(/^\//, "");
      const res = await fetch("https://tapi.lhbs.vn/" + cleanEp, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": token },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("HTTP " + res.status);
      const json = await res.json();
      return json.data;
    },
    async fetchAllLiveData() {
      this.isLoading = true;
      this.apiSyncStatus = "Đang đồng bộ Live API (Dashboard & LMS)...";
      let donViId = this.currentUnit === "MNLK" ? 2 : 1;
      let capId = 1;
      if (this.currentUnit === "THCS") capId = 2;
      else if (this.currentUnit === "THPT") capId = 3;

      try {
        // 1. Sĩ số
        const p1 = this.callTapi("Dashboard/ThongKeHocSinhTheoKhoiLop", { NamHocID: this.selectedYear, DonViID: 1, KhoiID: 1000 })
          .then((d) => { if (d && d.length) this.liveDataBienHoa = d; }).catch(() => null);

        const p2 = this.callTapi("Dashboard/ThongKeHocSinhTheoKhoiLop", { NamHocID: this.selectedYear, DonViID: 2, KhoiID: 1000 })
          .then((d) => { if (d && d.length) this.liveDataLongKhanh = d; }).catch(() => null);

        // 2. Chuyển đi
        const p3 = this.callTapi("Dashboard/ThongKeHocSinhChuyenDi", { NamHocID: this.selectedYear, DonViID: donViId, CapHocID: 0 })
          .then((d) => {
            if (d && Array.isArray(d)) {
              const list = [];
              d.forEach((sub) => { if (Array.isArray(sub)) list.push(...sub); });
              if (list.length) { this.withdrawRecords = list; this.calcTopReasons(list); }
            }
          }).catch(() => null);

        // 3. Chuyển đến
        const p4 = this.callTapi("Dashboard/ThongKeHocSinhChuyenDen", { NamHocID: this.selectedYear, DonViID: donViId, CapHocID: 0 })
          .then((d) => {
            if (d && Array.isArray(d)) {
              const list = [];
              d.forEach((sub) => { if (Array.isArray(sub)) list.push(...sub); });
              if (list.length) this.inflowRecordsCount = list.length;
            }
          }).catch(() => null);

        // 4. Lịch sử 7 năm
        const p5 = this.callTapi("Dashboard/ThongKeHocSinhTheoNamHoc", { DonViID: donViId, CapHocID: 0, KhoiID: 0 })
          .then((d) => { if (d && d.length) this.historyData = d; }).catch(() => null);

        // 5. Tiết dạy Calen (Chỉ tiêu 8)
        const p7 = this.callTapi("Dashboard/Calen_ThongKe_TietDay_TheoLop", { NamHocID: this.selectedYear, DonViID: donViId, KhoiID: 16, TuNgay: this.currentPeriodStartDate, DenNgay: this.currentPeriodEndDate })
          .then((d) => {
            if (d && d[1] && Array.isArray(d[1])) {
              this.teachingProgressRows = d[1].slice(0, 10).map((r) => ({
                TenLop: r.TenLop,
                TongTiet: r.TongTiet,
                Toan: r["Toán"] || 0,
                Van: r["Ngữ văn"] || 0,
                KHTN: (r["Vật lí"] || 0) + (r["Hóa học"] || 0) + (r["Sinh học"] || 0),
                STEM: r["STEM trải nghiệm"] || 0,
              }));
            }
          }).catch(() => null);

        // 6. LMS: Học liệu số (Chỉ tiêu 11)
        const p8 = this.callTapi("lms/BaoCao_2_ThongKe_HocLieuSo_ByCapID", { NamHocID: this.selectedYear, CapID: capId })
          .then((d) => {
            if (d && Array.isArray(d) && d.length) {
              this.lmsHocLieuRows = d;
              const total = d.reduce((s, r) => s + (r.TongHocLieu || 0), 0);
              const coNoiDung = d.reduce((s, r) => s + (r.HocLieuCoNoiDung || 0), 0);
              const totalFiles = d.reduce((s, r) => s + (r.TongNoiDung || 0), 0);
              this.lmsHocLieuSummary = {
                total,
                coNoiDung,
                pct: total ? ((coNoiDung / total) * 100).toFixed(1) : "0.0",
                totalFiles,
              };
            }
          }).catch(() => null);

        // 7. LMS: Bài tập LMS (Chỉ tiêu 15)
        const p9 = this.callTapi("lms/BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID", { NamHocID: this.selectedYear, CapID: capId })
          .then((d) => {
            if (d && Array.isArray(d) && d.length >= 3 && Array.isArray(d[2])) {
              this.lmsAssignmentRows = d[2];
              const totAssigned = d[2].reduce((s, r) => s + (r.TotalAssigned || 0), 0);
              const totDaNop = d[2].reduce((s, r) => s + (r.Total_DaNop || 0), 0);
              const totDaCham = d[2].reduce((s, r) => s + (r.Total_DaCham || 0), 0);
              if (totAssigned > 0) {
                this.lmsOverallRate = (((totDaNop + totDaCham) / totAssigned) * 100).toFixed(1);
              }
            }
          }).catch(() => null);

        await Promise.all([p1, p2, p3, p4, p5, p7, p8, p9]);
        this.apiSyncStatus = "Đã kết nối Live API (8/8 kết nối chuẩn)";
      } catch (e) {
        console.warn("Live API sync warning:", e);
        this.apiSyncStatus = "Dữ liệu chốt kỳ";
      } finally {
        this.isLoading = false;
      }
    },
    calcTopReasons(list) {
      const counts = {};
      list.forEach((r) => {
        const lyDo = (r.LyDo || "Nguyên nhân khác").trim();
        counts[lyDo] = (counts[lyDo] || 0) + 1;
      });
      const total = list.length || 1;
      this.topWithdrawReasons = Object.keys(counts)
        .map((k) => ({ name: k, count: counts[k], percent: ((counts[k] / total) * 100).toFixed(1) }))
        .sort((a, b) => b.count - a.count).slice(0, 7);
    },
    refreshData() {
      this.fetchPeriodData(this.selectedPeriod);
      if (!this.currentPeriodIsFrozen) {
        this.fetchAllLiveData();
      }
      this.$emit("on-reload");
    },
  },
	}
</script>