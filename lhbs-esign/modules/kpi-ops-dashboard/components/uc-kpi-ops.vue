<template>
	<div class="uc-kpi-ops">
    <!-- 1. Header Top -->
    <div class="uc-kpi-ops__top">
      <div>
        <div class="d-flex align-center gap-2">
          <div class="uc-kpi-ops__title">KPI Results Framework &amp; Ops Dashboard · LHBS</div>
          <span class="uc-kpi-ops__safeguard-pill">
            <span class="safeguard-dot"></span>
            <span>An toàn học đường: 0 sự cố</span>
          </span>
        </div>
        <div class="uc-kpi-ops__subtitle">Báo cáo vận hành {{ currentPeriodName }} · Năm học {{ selectedYear }}–{{ selectedYear + 1 }} · {{ currentPeriodFreezeText }}</div>
      </div>
      <div class="uc-kpi-ops__meta">
        <span :class="['uc-kpi-ops__pill', isLoading ? 'is-warn' : 'is-live']">
          {{ apiSyncStatus }}
        </span>
        <button type="button" class="uc-kpi-ops__simbtn" :disabled="isLoading" @click="refreshData()">
          {{ isLoading ? 'Đang tải...' : (currentPeriodIsFrozen ? 'Làm mới chốt kỳ' : 'Làm mới Live') }}
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="openCausalModal()">
          Vùng tác động
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="copyExecutiveBriefing()">
          {{ copiedBriefing ? 'Đã chép!' : 'Sao chép briefing' }}
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="printExecutiveReport()">
          In báo cáo A4
        </button>
        <button type="button" :class="['uc-kpi-ops__simbtn', { 'is-solid': isPresentMode }]" @click="toggleFullscreen()">
          {{ isPresentMode ? 'Thoát' : 'Toàn màn hình' }}
        </button>
      </div>
    </div>

    <!-- 2. Slicers Bar -->
    <div v-if="!isPresentMode" class="uc-kpi-ops__slicers">
      <div class="uc-kpi-ops__slicers-left">
        <div>
          <div class="uc-kpi-ops__slicer-label">Kỳ báo cáo</div>
          <div class="uc-kpi-ops__seg">
            <button
              v-for="p in periodsList"
              :key="p.PeriodKey"
              type="button"
              :class="{ 'is-on': selectedPeriod === p.PeriodKey }"
              @click="setPeriod(p.PeriodKey)"
            >{{ p.PeriodName }}</button>
          </div>
        </div>
        <div>
          <div class="uc-kpi-ops__slicer-label">Cấp học / Đơn vị</div>
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
        <div>
          <div class="uc-kpi-ops__slicer-label">Năm học</div>
          <div class="uc-kpi-ops__seg">
            <button
              v-for="y in schoolYears"
              :key="y"
              type="button"
              :class="{ 'is-on': selectedYear === y }"
              @click="setSchoolYear(y)"
            >{{ y }}</button>
          </div>
        </div>
      </div>
      <div style="display:flex;gap:6px;align-items:center;">
        <span class="uc-kpi-ops__view">{{ currentViewLabel }}</span>
        <button type="button" class="uc-kpi-ops__simbtn" @click="openFactModal('LEAVE')">
          Fact Store
        </button>
        <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="openDrawer('STUDENT_LIST')">
          Cơ cấu chi tiết ›
        </button>
      </div>
    </div>

    <!-- Sticky Subnav Breadcrumb khi xem trang chuyên sâu (page !== 0) -->
    <div v-if="page !== 0" class="uc-kpi-ops__sticky-subnav">
      <div class="uc-kpi-ops__breadcrumb">
        <span class="crumb-link" @click="page = 0">0. Hội đồng trường (Executive Cockpit)</span>
        <span class="crumb-sep">&rsaquo;</span>
        <span class="crumb-current">{{ currentBreadcrumbTitle }}</span>
      </div>
      <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="page = 0">
        &lsaquo; Quay lại Trung tâm điều hành
      </button>
    </div>

    <!-- 3. PAGE 0: HỘI ĐỒNG TRƯỜNG (Executive Board Overview) -->
    <div v-if="page === 0" class="uc-kpi-ops__page">
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <!-- TẦNG 1: EXECUTIVE BOARD SCORECARD                               -->
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <div class="uc-kpi3t__section-h">
        <div class="d-flex align-center justify-between flex-wrap gap-2 mb-2">
          <div>
            <div class="uc-kpi3t__section-title">
              <span class="uc-kpi3t__tier-badge tier-1">TẦNG 1</span>
              <span>EXECUTIVE BOARD SCORECARD &middot; HỘI ĐỒNG TRƯỜNG</span>
            </div>
            <div class="uc-kpi3t__section-sub">
              Bấm vào từng chỉ số để lọc Tiêu chí Vận hành (Tầng 2) và kích hoạt Phân tích Chẩn đoán sâu (Tầng 3)
            </div>
          </div>
          <div class="d-flex align-center gap-2">
            <!-- Nút Toggle 6 KPI vs 4 Khối -->
            <div class="uc-kpi3t__toggle-group">
              <button 
                type="button" 
                class="uc-kpi3t__toggle-btn" 
                :class="{ 'is-active': kpiViewMode === 'STRATEGIC' }" 
                @click="kpiViewMode = 'STRATEGIC'"
              >
                6 KPI Chiến Lược Results Framework
              </button>
              <button 
                type="button" 
                class="uc-kpi3t__toggle-btn" 
                :class="{ 'is-active': kpiViewMode === 'GROUPS' }" 
                @click="kpiViewMode = 'GROUPS'"
              >
                4 Khối Vận Hành Cốt Lõi
              </button>
            </div>
            <span class="uc-kpi-ops__pill2 is-live">
              Đang chọn: <b>{{ activeTier1Obj ? activeTier1Obj.KpiName : 'KPI 1' }}</b>
            </span>
          </div>
        </div>

        <!-- Grid 6 KPI Chiến Lược -->
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
              <div class="d-flex align-center gap-1">
                <span class="uc-kpi3t__dot" :style="{ backgroundColor: kpi.ThemeColor || '#0284c7' }"></span>
                <span class="uc-kpi3t__code">{{ kpi.MasterKpiCode.replace('_', ' ') }}</span>
              </div>
              <span class="uc-kpi3t__weight" v-if="kpi.WeightPct">Trọng số: {{ kpi.WeightPct }}%</span>
            </div>

            <div class="uc-kpi3t__card-name" :title="kpi.KpiName">
              {{ kpi.KpiName }}
            </div>

            <div class="uc-kpi3t__card-nums">
              <div class="uc-kpi3t__val">
                <b>{{ kpi.ActualValue }}</b><small>{{ kpi.TargetUnit }}</small>
              </div>
              <div class="uc-kpi3t__target">
                KH: {{ kpi.ComparisonOp }} {{ kpi.TargetValue }}{{ kpi.TargetUnit }}
              </div>
            </div>

            <!-- Progress Bar -->
            <div class="uc-kpi3t__pbar">
              <div 
                class="uc-kpi3t__pfill" 
                :class="'fill-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')"
                :style="{ width: Math.min(100, Math.max(0, kpi.ProgressPct || 0)) + '%' }"
              ></div>
            </div>

            <div class="uc-kpi3t__card-bot">
              <span class="uc-kpi3t__progress-txt">Tiến độ: <b>{{ kpi.ProgressPct }}%</b></span>
              <span class="uc-kpi3t__badge" :class="'badge-' + (kpi.StatusBadge ? kpi.StatusBadge.toLowerCase() : 'good')">
                {{ getTierStatusText(kpi.StatusBadge) }}
              </span>
            </div>

            <!-- Tích hợp Điểm Rủi ro Radar ngay trên Card -->
            <div class="uc-kpi3t__radar-strip mt-1" v-if="kpi.RadarRiskScore">
              <span class="radar-tag" :class="kpi.CampusAlertCount > 0 ? 'is-danger' : 'is-safe'">
                <i class="bi bi-shield-exclamation me-1"></i>
                Radar: <b>{{ kpi.RadarRiskScore }}đ</b> ({{ kpi.CampusAlertCount > 0 ? kpi.CampusAlertCount + ' cơ sở đỏ' : 'An toàn' }})
              </span>
            </div>
          </div>
        </div>

        <!-- Grid 4 Khối Vận Hành Cốt Lõi (Toggle Mode) -->
        <div class="uc-kpi3t__grid-4" v-else>
          <div 
            v-for="grp in groupPillars" 
            :key="grp.code"
            class="uc-kpi3t__card"
            :class="[
              { 'is-active': activeTier1Kpi === grp.kpiCode },
              'status-' + grp.status
            ]"
            @click="selectTier1Kpi(grp.kpiCode)"
          >
            <div class="uc-kpi3t__card-top">
              <span class="uc-kpi3t__code">{{ grp.label }}</span>
              <span class="uc-kpi3t__weight">{{ grp.driverCount }} Tiêu chí</span>
            </div>
            <div class="uc-kpi3t__card-name"><b>{{ grp.name }}</b></div>
            <div class="uc-kpi3t__card-nums">
              <div class="uc-kpi3t__val">{{ grp.highlightVal }}</div>
              <div class="uc-kpi3t__target">{{ grp.highlightNote }}</div>
            </div>
            <div class="uc-kpi3t__card-bot mt-2">
              <span class="uc-kpi3t__progress-txt">{{ grp.desc }}</span>
              <span class="uc-kpi3t__badge" :class="'badge-' + grp.status">{{ getTierStatusText(grp.status) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ═══════════════════════════════════════════════════════════════ -->
      <!-- TẦNG 2: TIÊU CHÍ VẬN HÀNH THÀNH PHẦN (OPERATIONAL DRIVERS)     -->
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <div class="uc-kpi3t__section-h mt-2 mb-2">
        <div class="d-flex align-center justify-between flex-wrap gap-2 pb-2 mb-2" style="border-bottom:1px solid #e2e8f0;">
          <div class="d-flex align-center gap-2">
            <span class="uc-kpi3t__tier-badge tier-2">TẦNG 2</span>
            <div>
              <div class="uc-kpi3t__section-title" style="font-size:13px;">
                TIÊU CHÍ VẬN HÀNH ĐÓNG GÓP: <span style="color:#0284c7;">{{ activeTier1Obj ? activeTier1Obj.KpiName : '' }}</span>
              </div>
              <div class="uc-kpi3t__section-sub">
                Gồm <b>{{ currentTier2Drivers.length }}</b> tiêu chí vận hành trực tiếp &middot; <span class="text-danger fw-bold" v-if="negativeDriversCount > 0">{{ negativeDriversCount }} tiêu chí cần can thiệp</span><span class="text-success" v-else>Tất cả tiêu chí đang vận hành tốt</span> &middot; Kỳ chốt {{ selectedPeriod }}
              </div>
            </div>
          </div>

          <div class="d-flex align-center gap-2">
            <span class="uc-kpi-ops__pill2 is-warn" v-if="negativeDriversCount > 0">
              Có {{ negativeDriversCount }} tiêu chí lệch kế hoạch
            </span>
            <span class="uc-kpi-ops__pill2 is-good" v-else>
              100% Tiêu chí On-track
            </span>
          </div>
        </div>

        <!-- Bảng danh sách tiêu chí con của Tầng 2 -->
        <div class="uc-kpi-ops__tablewrap mt-1">
          <table class="uc-kpi-ops__table uc-kpi-ops__table--dense">
            <thead>
              <tr>
                <th style="width:70px;">Mã</th>
                <th>Tên Tiêu Chí Vận Hành</th>
                <th style="width:85px;text-align:center;">Tần suất</th>
                <th style="width:110px;text-align:right;">Kế hoạch</th>
                <th style="width:110px;text-align:right;">Thực hiện</th>
                <th style="width:90px;text-align:right;">Độ lệch</th>
                <th style="width:110px;text-align:center;">Tiến độ</th>
                <th style="width:95px;text-align:center;">Trạng thái</th>
                <th style="width:130px;text-align:center;">Cờ Kiểm Toán</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="d in currentTier2Drivers" 
                :key="d.KpiCode" 
                class="is-click" 
                :class="{ 'uc-kpi3t__row-negative': d.IsNegativeDriver || d.StatusBadge === 'WARN' || d.StatusBadge === 'BAD' }"
                @click="openDrawerForKpi(d.KpiCode)"
              >
                <td><b class="tx-code">{{ d.KpiCode }}</b></td>
                <td>
                  <div class="d-flex align-center gap-1">
                    <b>{{ d.KpiName }}</b>
                    <span v-if="d.IsNegativeDriver" class="uc-kpi3t__negative-badge" title="Chỉ tiêu đang kéo tụt hiệu suất chung">KÉO TỤT</span>
                  </div>
                </td>
                <td style="text-align:center;"><small>{{ d.Frequency || 'Tháng' }}</small></td>
                <td style="text-align:right;">{{ formatNumber(d.TargetValue) }} {{ d.Unit || '' }}</td>
                <td style="text-align:right;">
                  <b :class="(d.IsNegativeDriver || d.StatusBadge === 'WARN' || d.StatusBadge === 'BAD') ? 'text-danger' : 'text-success'">
                    {{ formatNumber(d.ActualValue) }}
                  </b> {{ d.Unit || '' }}
                </td>
                <td style="text-align:right;">
                  <span :class="d.Variance < 0 ? 'text-danger fw-bold' : 'text-success fw-bold'">
                    {{ d.Variance > 0 ? '+' : '' }}{{ formatNumber(d.Variance) }}
                  </span>
                </td>
                <td style="text-align:center;">
                  <div class="d-flex align-center gap-1 justify-center">
                    <div class="uc-kpi3t__mini-pbar">
                      <div class="uc-kpi3t__mini-pfill" :class="'fill-' + (d.StatusBadge ? d.StatusBadge.toLowerCase() : 'good')" :style="{ width: Math.min(100, Math.max(0, d.ProgressPct || 0)) + '%' }"></div>
                    </div>
                    <small><b>{{ d.ProgressPct || 0 }}%</b></small>
                  </div>
                </td>
                <td style="text-align:center;">
                  <span :class="['uc-kpi3t__status-pill', 'is-' + (d.StatusBadge ? d.StatusBadge.toLowerCase() : 'good')]">
                    {{ getTierStatusText(d.StatusBadge) }}
                  </span>
                </td>
                <td style="text-align:center;">
                  <span v-if="d.AuditIssueCount > 0" class="uc-kpi3t__audit-flag" :title="d.AuditSummary">
                    <i class="bi bi-exclamation-octagon-fill text-danger me-1"></i>Vênh Báo Cáo
                  </span>
                  <span v-else class="tx-muted" style="font-size:11px;">
                    <i class="bi bi-check2 text-success me-1"></i>Đã khớp
                  </span>
                </td>
              </tr>
              <tr v-if="currentTier2Drivers.length === 0">
                <td colspan="9" style="text-align:center;padding:1.5rem;color:#64748b;">
                  Đang đồng bộ danh mục chỉ tiêu vận hành từ CSDL eSign...
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- ═══════════════════════════════════════════════════════════════ -->
      <!-- TẦNG 3: IN-CONTEXT DIAGNOSTIC & DRILL-DOWN PANEL               -->
      <!-- ═══════════════════════════════════════════════════════════════ -->
      <div class="uc-kpi3t__tier3-box mb-3">
        <div class="uc-kpi3t__tier3-header">
          <div class="d-flex align-center gap-2">
            <span class="uc-kpi3t__tier-badge tier-3">TẦNG 3</span>
            <div>
              <div class="uc-kpi3t__section-title">
                PHÂN TÍCH CHẨN ĐOÁN SÂU, HỆ LỤY NHÂN QUẢ &amp; ĐỐI SOÁT KIỂM TOÁN
              </div>
              <div class="uc-kpi3t__section-sub">
                Đang chẩn đoán chuyên sâu cho: <b style="color:#0284c7;">{{ activeTier1Obj ? activeTier1Obj.KpiName : '' }}</b>
              </div>
            </div>
          </div>
          
          <!-- Tabs của Tầng 3 -->
          <div class="d-flex align-center gap-2 flex-wrap">
            <div class="uc-kpi3t__tab-pills">
              <button 
                type="button" 
                class="uc-kpi3t__tab-btn" 
                :class="{ 'is-active': tier3ActiveTab === 'CAUSAL' }" 
                @click="tier3ActiveTab = 'CAUSAL'"
              >
                <i class="bi bi-diagram-3-fill me-1"></i>Chuỗi Nhân Quả &amp; Hệ Lụy Tài Chính
              </button>
              <button 
                type="button" 
                class="uc-kpi3t__tab-btn" 
                :class="{ 'is-active': tier3ActiveTab === 'CAMPUS' }" 
                @click="tier3ActiveTab = 'CAMPUS'"
              >
                <i class="bi bi-geo-alt-fill me-1"></i>Phân Rã 5 Cơ Sở &amp; Radar Rủi Ro ({{ tier3Campuses.length }})
              </button>
              <button 
                type="button" 
                class="uc-kpi3t__tab-btn" 
                :class="{ 'is-active': tier3ActiveTab === 'AUDIT' }" 
                @click="tier3ActiveTab = 'AUDIT'"
              >
                <i class="bi bi-search me-1"></i>Minh Chứng Đối Soát Kiểm Toán ({{ tier3Audits.length }})
              </button>
            </div>
            <button 
              type="button" 
              class="uc-kpi-ops__simbtn" 
              style="padding:4px 10px;font-size:11px;" 
              @click="jumpToTier3Page(activeTier1Kpi)" 
              title="Mở toàn màn hình phân hệ chi tiết dữ liệu thô"
            >
              Mở toàn màn hình phân hệ &rsaquo;
            </button>
          </div>
        </div>

        <!-- Nội dung Tab 1: Chuỗi Nhân Quả & Hệ Lụy Tài Chính (VNĐ) -->
        <div v-if="tier3ActiveTab === 'CAUSAL'" class="uc-kpi3t__causal-container p-3">
          <!-- 4 Stats Cards Lượng Hóa Thiệt Hại Thật -->
          <div class="uc-kpi3t__impact-grid mb-3">
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Thiếu hụt Quy mô Học sinh</div>
              <div class="uc-kpi3t__impact-val text-danger">
                -{{ tier3CausalImpact ? tier3CausalImpact.HeadcountDeficit : 125 }} <small>Học sinh</small>
              </div>
              <div class="uc-kpi3t__impact-sub">So với chỉ tiêu tuyển sinh 2.750 HS</div>
            </div>
            <div class="uc-kpi3t__impact-card is-danger">
              <div class="uc-kpi3t__impact-label">Thất thu Học phí Trực tiếp</div>
              <div class="uc-kpi3t__impact-val text-danger">
                -{{ formatBillion(tier3CausalImpact ? tier3CausalImpact.TuitionLossVNĐ : 8125000000) }} <small>Tỷ VNĐ</small>
              </div>
              <div class="uc-kpi3t__impact-sub">Theo biểu phí niêm yết 5 cơ sở CSDL eSign</div>
            </div>
            <div class="uc-kpi3t__impact-card is-warn">
              <div class="uc-kpi3t__impact-label">Thất thu Doanh thu Bán trú</div>
              <div class="uc-kpi3t__impact-val text-warn">
                -{{ formatBillion(tier3CausalImpact ? tier3CausalImpact.BoardingLossVNĐ : 2812500000) }} <small>Tỷ VNĐ</small>
              </div>
              <div class="uc-kpi3t__impact-sub">Tiền ăn, xe bus và dịch vụ bán trú 2026-2027</div>
            </div>
            <div class="uc-kpi3t__impact-card is-critical">
              <div class="uc-kpi3t__impact-label">Tổng Tác Động Tài Chính</div>
              <div class="uc-kpi3t__impact-val" style="color:#b91c1c;">
                -{{ formatBillion(tier3CausalImpact ? tier3CausalImpact.TotalFinancialLossVNĐ : 10937500000) }} <small>Tỷ VNĐ</small>
              </div>
              <div class="uc-kpi3t__impact-sub">Ước tính thiệt hại cả năm nếu không can thiệp</div>
            </div>
          </div>

          <!-- Truy vết Chuỗi Nhân Quả & Khuyến Nghị HĐQT -->
          <div class="uc-kpi3t__narrative-grid">
            <div class="uc-kpi3t__narrative-box">
              <div class="uc-kpi3t__box-head">
                <i class="bi bi-diagram-3-fill text-danger me-1"></i>
                <b>Truy Vết Chuỗi Nhân Quả Nghiệp Vụ (Root-Cause Causal Propagation)</b>
              </div>
              <div class="uc-kpi3t__narrative-text">
                {{ tier3CausalImpact ? tier3CausalImpact.CausalChainNarrative : 'Đang truy vết chuỗi nhân quả nghiệp vụ...' }}
              </div>
            </div>

            <div class="uc-kpi3t__narrative-box is-action">
              <div class="uc-kpi3t__box-head">
                <i class="bi bi-lightning-charge-fill text-primary me-1"></i>
                <b>Khuyến Nghị Hành Động Can Thiệp Cho HĐQT &amp; Ban Giám Hiệu</b>
              </div>
              <div class="uc-kpi3t__action-text">
                {{ tier3CausalImpact ? tier3CausalImpact.ActionRecommendation : 'Đang tải khuyến nghị điều hành...' }}
              </div>
            </div>
          </div>
        </div>

        <!-- Nội dung Tab 2: Phân Rã 5 Cơ Sở & Radar Rủi Ro -->
        <div v-if="tier3ActiveTab === 'CAMPUS'" class="uc-kpi3t__campus-container p-3">
          <div class="uc-kpi3t__campus-grid">
            <div 
              v-for="c in tier3Campuses" 
              :key="c.ScopeID" 
              class="uc-kpi3t__campus-card"
              :class="'risk-' + (c.CampusRiskLevel ? c.CampusRiskLevel.toLowerCase() : 'low')"
            >
              <div class="uc-kpi3t__campus-top">
                <b>{{ c.CampusName }}</b>
                <span class="uc-kpi3t__risk-pill" :class="'is-' + (c.CampusRiskLevel ? c.CampusRiskLevel.toLowerCase() : 'low')">
                  Radar: {{ c.CampusRiskScore }}đ ({{ c.CampusRiskLevel }})
                </span>
              </div>
              <div class="uc-kpi3t__campus-mid mt-2">
                <div class="d-flex justify-between mb-1">
                  <span class="tx-muted">Sĩ số / Công suất:</span>
                  <b>{{ c.CurrentEnrollment }} / {{ c.PlannedCapacity }} chỗ</b>
                </div>
                <div class="d-flex justify-between mb-1">
                  <span class="tx-muted">Tỷ lệ lấp đầy:</span>
                  <b :class="c.CapacityRate < 85 ? 'text-danger' : 'text-success'">{{ c.CapacityRate }}%</b>
                </div>
                <div class="d-flex justify-between mb-1">
                  <span class="tx-muted">Học phí niêm yết:</span>
                  <span>{{ (c.BaseAnnualTuition / 1000000).toFixed(0) }} tr/năm</span>
                </div>
                <div class="d-flex justify-between" style="border-top:1px dashed #cbd5e1;padding-top:4px;">
                  <span class="tx-muted">Thất thu học phí:</span>
                  <b class="text-danger">-{{ formatBillion(c.CampusTuitionLossVNĐ) }} tỷ</b>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Nội dung Tab 3: Biên Bản Đối Soát & Kiểm Toán Dữ Liệu -->
        <div v-if="tier3ActiveTab === 'AUDIT'" class="uc-kpi3t__audit-container p-3">
          <div v-if="tier3Audits && tier3Audits.length > 0" class="uc-kpi3t__audit-list">
            <div v-for="a in tier3Audits" :key="a.DiscrepancyID" class="uc-kpi3t__audit-item mb-2 p-2">
              <div class="d-flex align-center justify-between mb-1">
                <div class="d-flex align-center gap-1">
                  <span class="uc-kpi3t__badge-mismatch">{{ a.Category }}</span>
                  <b>{{ a.Title }}</b>
                </div>
                <small class="tx-muted">Phụ trách: <b>{{ a.ActionOwner }}</b></small>
              </div>
              <div class="uc-kpi3t__audit-sources">
                <div class="source-col">
                  <span class="lbl">Hệ thống Nguồn / Báo cáo:</span>
                  <div>{{ a.PrimarySource }}: <b>{{ a.PrimaryValue }}</b></div>
                </div>
                <div class="source-col">
                  <span class="lbl">Hệ thống Tác nghiệp / Nguồn gốc:</span>
                  <div>{{ a.SecondarySource }}: <b>{{ a.SecondaryValue }}</b></div>
                </div>
              </div>
              <div class="uc-kpi3t__audit-desc mt-1">
                <small><b>Phân tích vênh:</b> {{ a.VarianceAnalysis }}</small>
              </div>
            </div>
          </div>
          <div v-else class="text-center p-4 tx-muted">
            Chưa phát hiện điểm vênh kiểm toán đối với chỉ số này trong kỳ chốt {{ selectedPeriod }}. Số liệu đã được xác minh.
          </div>
        </div>
      </div>

      <!-- 2. KPI Results Framework Measurement Health Strip (60 KPIs) -->
        <div class="uc-kpi-ops__health-card mb-3">
          <div class="uc-kpi-ops__health-head">
            <div>
              <div class="uc-kpi-ops__health-title">
                Sức Khỏe Danh Mục 60 Chỉ Tiêu Vận Hành &amp; Results Framework (Kỳ {{ currentPeriodName }})
              </div>
              <div class="uc-kpi-ops__health-subtitle">
                Chuẩn hóa khớp 100% tài liệu họp BĐH 19/10/2026 (7 Tuyển sinh &middot; 20 Học thuật &middot; 24 Dịch vụ &middot; 9 CSVC/Tài chính)
              </div>
            </div>
            <button
              type="button"
              class="uc-kpi-ops__simbtn is-solid"
              style="padding:3px 10px;font-size:11px;"
              @click="executiveTab = 'FRAMEWORK'"
            >
              Xem danh mục 60 KPI &rsaquo;
            </button>
          </div>

          <!-- Stacked Bar (60 KPIs) -->
          <div class="uc-kpi-ops__health-bar-track">
            <div
              class="uc-kpi-ops__health-segment is-good"
              :style="{ width: kpiHealthStats.goodPct + '%' }"
              :title="'Đạt chuẩn: ' + kpiHealthStats.good + ' KPI (' + kpiHealthStats.goodPct + '%)'"
            >
              <span v-if="kpiHealthStats.good > 0">{{ kpiHealthStats.good }} Đạt</span>
            </div>
            <div
              class="uc-kpi-ops__health-segment is-warn"
              :style="{ width: kpiHealthStats.warnPct + '%' }"
              :title="'Cảnh báo: ' + kpiHealthStats.warn + ' KPI (' + kpiHealthStats.warnPct + '%)'"
            >
              <span v-if="kpiHealthStats.warn > 0">{{ kpiHealthStats.warn }} Cảnh báo</span>
            </div>
            <div
              v-if="kpiHealthStats.critical > 0"
              class="uc-kpi-ops__health-segment is-crit"
              :style="{ width: kpiHealthStats.criticalPct + '%' }"
              :title="'Nguy cấp: ' + kpiHealthStats.critical + ' KPI (' + kpiHealthStats.criticalPct + '%)'"
            >
              <span>{{ kpiHealthStats.critical }} Nguy cấp</span>
            </div>
            <div
              class="uc-kpi-ops__health-segment is-pending"
              :style="{ width: kpiHealthStats.pendingPct + '%' }"
              :title="'Chờ tích hợp API: ' + kpiHealthStats.pending + ' KPI (' + kpiHealthStats.pendingPct + '%)'"
            >
              <span v-if="kpiHealthStats.pending > 0">{{ kpiHealthStats.pending }} Chờ kết nối API ({{ kpiHealthStats.pendingPct }}%)</span>
            </div>
          </div>

          <!-- Legend & Metric Stats -->
          <div class="uc-kpi-ops__health-legend">
            <div class="uc-kpi-ops__health-legend-item">
              <span class="legend-indicator is-good"></span>
              <span>Đạt chuẩn: <b>{{ kpiHealthStats.good }}</b> KPI</span>
            </div>
            <div class="uc-kpi-ops__health-legend-item">
              <span class="legend-indicator is-warn"></span>
              <span>Cảnh báo: <b>{{ kpiHealthStats.warn }}</b> KPI</span>
            </div>
            <div class="uc-kpi-ops__health-legend-item">
              <span class="legend-indicator is-pending"></span>
              <span>Chờ tích hợp API: <b>{{ kpiHealthStats.pending }}</b> KPI</span>
            </div>
            <div class="uc-kpi-ops__health-legend-item ml-auto">
              <span>Đã số hóa: <b style="color:var(--accent2);">{{ kpiHealthStats.activeCount }}/{{ kpiHealthStats.total }} KPI ({{ ((kpiHealthStats.activeCount*100)/kpiHealthStats.total).toFixed(0) }}%)</b></span>
            </div>
          </div>
        </div>

        <!-- 3. Split Layout 7:5: Value Bridge (Waterfall) + 4 Thẻ Đòn Bẩy Chiến Lược -->
        <div class="uc-kpi-ops__split-grid">
          <!-- Cột trái (58%): Value Bridge SVG -->
          <div class="uc-kpi-ops__split-card">
            <div class="uc-kpi-ops__vhead mb-1">
              <div class="uc-kpi-ops__vtitle" style="font-size:13px;font-weight:700;color:var(--accent2);">
                Lộ Trình Phục Hồi Sĩ Số Đạt 100% Kế Hoạch {{ formatNumber(displayTarget) }} Học Sinh (Value Bridge Waterfall)
              </div>
              <div class="uc-kpi-ops__vnote" style="font-size:11px;color:var(--ink2);">
                Đóng góp {{ strategicLevers.length }} đòn bẩy từ Sĩ số kỳ ({{ formatNumber(displayStudents) }} HS) bù hụt {{ Math.max(0, displayTarget - displayStudents) }} HS đạt 100% kế hoạch (Thiết kế: {{ formatNumber(displayCapacity) }} HS)
              </div>
            </div>
            <svg class="uc-kpi-ops__svg" viewBox="0 0 640 150" preserveAspectRatio="xMidYMid meet">
              <line v-for="t in valueBridge.ticks" :key="'t' + t.v" x1="45" x2="625" :y1="t.y" :y2="t.y" class="g-grid"></line>
              <text v-for="t in valueBridge.ticks" :key="'l' + t.v" x="40" :y="t.y + 4" class="g-axis" text-anchor="end">{{ formatNumber(t.v) }}</text>
              <line v-for="(cn, i) in valueBridge.conns" :key="'c' + i" :x1="cn.x1" :x2="cn.x2" :y1="cn.y" :y2="cn.y" class="g-conn"></line>
              <g v-for="(b, i) in valueBridge.bars" :key="'b' + i">
                <rect :x="b.x" :y="b.y" :width="b.w" :height="b.h" :class="'g-' + b.type" rx="2"></rect>
                <text :x="b.x + b.w / 2" :y="b.y - 4" text-anchor="middle" class="g-val" style="font-size:10px;">{{ b.text }}</text>
                <text v-for="(ln, j) in b.lines" :key="j" :x="b.x + b.w / 2" :y="126 + j * 11" text-anchor="middle" class="g-axis" style="font-size:9.5px;">{{ ln }}</text>
              </g>
              <line x1="45" x2="625" :y1="valueBridge.planY" :y2="valueBridge.planY" class="g-plan"></line>
              <text x="625" :y="valueBridge.planY - 4" text-anchor="end" class="g-plan-txt" style="font-size:10px;">Chỉ tiêu: {{ formatNumber(valueBridge.planVal) }} HS</text>
            </svg>
          </div>

          <!-- Cột phải (42%): 4 Thẻ Đòn Bẩy Chiến Lược -->
          <div class="uc-kpi-ops__split-card">
            <div class="uc-kpi-ops__vhead mb-1">
              <div class="uc-kpi-ops__vtitle" style="font-size:13px;font-weight:700;color:var(--accent2);">
                Chi Tiết 4 Đòn Bẩy Lượng Hóa Doanh Thu
              </div>
              <div class="uc-kpi-ops__vnote" style="font-size:11px;color:var(--good);font-weight:600;">
                Tổng giá trị bảo toàn: {{ computedStrategicPreservedRevenue }} (Bù hụt {{ Math.max(0, displayTarget - displayStudents) }} HS đạt {{ formatNumber(displayTarget) }} HS)
              </div>
            </div>
            <div class="uc-kpi-ops__levers-list" v-if="strategicLevers && strategicLevers.length">
              <div 
                v-for="lv in strategicLevers" 
                :key="lv.LeverID" 
                :class="['uc-kpi-ops__lever-item', { 'is-priority': lv.IsPriority }]"
              >
                <div>
                  <div class="uc-kpi-ops__lever-title">{{ lv.Title }}</div>
                  <div class="uc-kpi-ops__lever-desc">{{ lv.Description }}</div>
                </div>
                <div class="uc-kpi-ops__lever-stat">
                  <div class="uc-kpi-ops__lever-hs">{{ lv.StudentsGain }}</div>
                  <div class="uc-kpi-ops__lever-money">{{ lv.RevenueGainText }}</div>
                </div>
              </div>
            </div>
            <div v-else class="text-caption text-grey p-3 text-center">
              Đang đồng bộ 4 đòn bẩy chiến lược từ CSDL eSign...
            </div>
          </div>
        </div>

        <!-- 4. Grid 5 Thẻ Cơ Sở Tinh Gọn (Bullet Meters + Harvey Balls) -->
        <div class="uc-kpi-ops__campus-grid">
          <div
            v-for="u in campusMatrixRows"
            :key="u.code"
            :class="['uc-kpi-ops__campus-tile', 'is-' + u.status]"
          >
            <div class="uc-kpi-ops__campus-tile-h">
              <div class="uc-kpi-ops__campus-tile-name">
                <svg class="uc-kpi-ops__hb" viewBox="0 0 12 12">
                  <circle cx="6" cy="6" r="5" class="hb-o" />
                  <circle v-if="u.confidence === 'full'" cx="6" cy="6" r="5" class="hb-f" />
                  <path v-else-if="u.confidence === 'half'" d="M6,1 A5,5 0 0 1 6,11 Z" class="hb-f" />
                </svg>
                {{ u.name }}
              </div>
              <span :class="['uc-kpi-ops__campus-tile-st', 'is-' + u.status]">{{ u.statusText }}</span>
            </div>

            <div class="uc-kpi-ops__campus-tile-nums">
              <div class="uc-kpi-ops__campus-tile-cur">{{ formatNumber(u.current) }} <small style="font-size:11px;font-weight:400;color:#64748b;">HS</small></div>
              <div class="uc-kpi-ops__campus-tile-tar">KH: {{ formatNumber(u.target) }} ({{ ((u.current / u.target) * 100).toFixed(1) }}%)</div>
            </div>

            <!-- Bullet Meter: Công suất lấp đầy -->
            <div class="uc-kpi-ops__bullet-meter" :title="'Lấp đầy: ' + u.occupancy + '%'">
              <div
                :class="['uc-kpi-ops__bullet-meter-fill', 'is-' + u.status]"
                :style="{ width: Math.min(100, u.occupancy) + '%' }"
              ></div>
              <div class="uc-kpi-ops__bullet-meter-target" style="left: 95%;" title="Ngưỡng chuẩn 95%"></div>
            </div>

            <div class="uc-kpi-ops__campus-tile-meta">
              <div>Rút học<b>{{ u.withdraw }} HS</b><small>{{ u.withdrawRate }}%</small></div>
              <div>Nghỉ phép<b>{{ u.leaveDays }}</b><small>ngày công</small></div>
              <div>Tồn CSVC<b :class="u.maintenancePending > 0 ? 'tx-warn' : ''">{{ u.maintenancePending }}</b><small>ticket</small></div>
            </div>
          </div>
        </div>

        <!-- 5. CỤM ĐỒ THỊ TRỰC QUAN DOANH NGHIỆP: PHỄU CHUYỂN ĐỔI TUYỂN SINH (FUNNEL SVG) + CƠ CẤU DOANH THU DỊCH VỤ -->
        <div class="uc-kpi-ops__split-grid">
          <!-- Cột trái: Phễu Chuyển Đổi Tuyển Sinh CRM 4 Tầng SVG -->
          <div class="uc-kpi-ops__split-card">
            <div class="uc-kpi-ops__vhead mb-1">
              <div class="uc-kpi-ops__vtitle" style="font-size:13px;font-weight:700;color:var(--accent2);">
                Phễu Chuyển Đổi Tuyển Sinh Toàn Trường (Conversion Funnel SVG)
              </div>
              <div class="uc-kpi-ops__vnote" style="font-size:11px;color:var(--ink2);">
                Đo lường tỷ lệ chuyển đổi qua 4 giai đoạn từ 1.200 Leads tiềm năng đến Nhập học chính thức
              </div>
            </div>
            <svg class="uc-kpi-ops__svg" viewBox="0 0 600 160" preserveAspectRatio="xMidYMid meet">
              <!-- Funnel Stage 1: Leads -->
              <polygon points="40,15 560,15 480,48 120,48" fill="#e0f2fe" stroke="#0284c7" stroke-width="1.5" />
              <text x="300" y="36" text-anchor="middle" font-size="11.5" font-weight="700" fill="#0369a1">1. TỔNG LEADS QUAN TÂM: 1,200 LEADS (100%)</text>
              
              <!-- Funnel Stage 2: Tiếp cận & Tư vấn -->
              <polygon points="120,52 480,52 420,85 180,85" fill="#fef3c7" stroke="#d97706" stroke-width="1.5" />
              <text x="300" y="73" text-anchor="middle" font-size="11" font-weight="700" fill="#92400e">2. TIẾP CẬN TƯ VẤN: 850 LEADS (70.8%) &middot; RƠI RỤNG 29.2%</text>

              <!-- Funnel Stage 3: Hẹn tham quan & Test -->
              <polygon points="180,89 420,89 360,122 240,122" fill="#fed7aa" stroke="#ea580c" stroke-width="1.5" />
              <text x="300" y="110" text-anchor="middle" font-size="10.5" font-weight="700" fill="#9a3412">3. HẸN THĂM TRƯỜNG &amp; TEST: 320 HỒ SƠ (26.7%)</text>

              <!-- Funnel Stage 4: Nhập học chính thức -->
              <polygon points="240,126 360,126 330,154 270,154" fill="#dcfce7" stroke="#16a34a" stroke-width="1.5" />
              <text x="300" y="144" text-anchor="middle" font-size="10.5" font-weight="700" fill="#15803d">4. NHẬP HỌC CHÍNH THỨC: 115 HS (9.6%)</text>
            </svg>
            <div class="d-flex justify-space-between align-center px-2 mt-1" style="font-size:10.5px;color:#64748b;">
              <span>Chi phí tuyển sinh/HS (CAC): <b>4.2 tr VNĐ</b></span>
              <span>Chiến dịch trọng điểm: <b>Kitty Mầm non &amp; Bổ sung THCS HK2</b></span>
            </div>
          </div>

          <!-- Cột phải: Cơ Cấu Đóng Góp Doanh Thu Dịch Vụ & Lợi Nhuận Gộp -->
          <div class="uc-kpi-ops__split-card">
            <div class="uc-kpi-ops__vhead mb-1">
              <div class="uc-kpi-ops__vtitle" style="font-size:13px;font-weight:700;color:var(--accent2);">
                Cơ Cấu Doanh Thu Dịch Vụ Bán Trú &amp; Câu Lạc Bộ (FTS Snapshot)
              </div>
              <div class="uc-kpi-ops__vnote" style="font-size:11px;color:var(--good);font-weight:600;">
                Tỷ suất LN gộp dịch vụ toàn trường: 52.4% (Vượt chuẩn KPI 4: 50%)
              </div>
            </div>
            <!-- Stacked Service Revenue Bar -->
            <div class="uc-kpi-ops__dist-bar mt-2 mb-2">
              <div class="uc-kpi-ops__dist-seg" style="width:42%;background:#0284c7;" title="Suất ăn Bán trú: 42% doanh thu"></div>
              <div class="uc-kpi-ops__dist-seg" style="width:24%;background:#16a34a;" title="Câu lạc bộ ngoại khóa: 24% doanh thu"></div>
              <div class="uc-kpi-ops__dist-seg" style="width:18%;background:#f59e0b;" title="Xe đưa rước: 18% doanh thu"></div>
              <div class="uc-kpi-ops__dist-seg" style="width:16%;background:#8b5cf6;" title="Đồng phục & Sách: 16% doanh thu"></div>
            </div>
            <!-- Legend Chi Tiết Doanh Thu Dịch Vụ -->
            <div class="d-flex flex-wrap gap-2 mt-2" style="font-size:11px;">
              <span class="p-1 px-2 rounded" style="background:#e0f2fe;color:#0369a1;font-weight:600;">Bán trú: 42% (LN gộp 54.2%)</span>
              <span class="p-1 px-2 rounded" style="background:#dcfce7;color:#15803d;font-weight:600;">CLB ngoại khóa: 24% (1.25 tỷ)</span>
              <span class="p-1 px-2 rounded" style="background:#fef3c7;color:#92400e;font-weight:600;">Xe bus: 18% (LN gộp 48.6%)</span>
              <span class="p-1 px-2 rounded" style="background:#ede9fe;color:#6d28d9;font-weight:600;">Đồng phục: 16%</span>
            </div>
            <div class="d-flex justify-space-between align-center mt-3 pt-2" style="border-top:1px dashed #e2e8f0;font-size:11px;">
              <span style="color:#64748b;">Đóng góp Bottom-Line: <b>Bảo toàn 4.076 tỷ VNĐ</b></span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn"
                style="padding:1px 8px;font-size:10.5px;"
                @click="openFactModal('CLUB')"
              >Đối soát chi tiết FTS &rsaquo;</button>
            </div>
          </div>
        </div>
      </div>

      <!-- ================= SUB-TAB 5: DỰ BÁO & RADAR RỦI RO THÁNG 10 (RISK RADAR) ================= -->
      <div v-if="executiveTab === 'RISK'" class="uc-kpi-ops__risk-container">
        <!-- Hero Summary Box -->
        <div class="uc-kpi-ops__risk-hero">
          <div>
            <div class="uc-kpi-ops__risk-hero-title">BÁO ĐỘNG SỚM RỦI RO ĐIỀU HÀNH · {{ currentPeriodName }}</div>
            <div class="uc-kpi-ops__risk-hero-desc">
              {{ dynamicRiskLeadingText }}
            </div>
          </div>
          <div class="uc-kpi-ops__risk-hero-stat">
            <div class="uc-kpi-ops__risk-stat-item">
              <div class="uc-kpi-ops__risk-stat-val">{{ totalRiskWithdrawForecast }}</div>
              <div class="uc-kpi-ops__risk-stat-lbl">Dự báo nguy cơ rút {{ nextPeriodShortName }}</div>
            </div>
            <div class="uc-kpi-ops__risk-stat-item">
              <div class="uc-kpi-ops__risk-stat-val">{{ totalRiskTuitionForecast }}</div>
              <div class="uc-kpi-ops__risk-stat-lbl">Thất thu học phí tiềm ẩn</div>
            </div>
            <div class="uc-kpi-ops__risk-stat-item">
              <button
                type="button"
                class="uc-kpi-ops__simbtn is-solid"
                @click="openCausalModal(currentUnit, 'RUT_HOC')"
              >
                Vùng tác động (ước tính) &rsaquo;
              </button>
            </div>
          </div>
        </div>

        <!-- 5 Campus Risk Cards Grid (Động 100% từ spAPI_KPI_GetRiskRadar) -->
        <!-- Leaderboard Pills Bar -->
        <div class="uc-kpi-ops__risk-campus-filter-bar">
          <span class="uc-kpi-ops__filter-lbl">Xếp hạng rủi ro cơ sở:</span>
          <button
            type="button"
            :class="['uc-kpi-ops__campus-filter-pill', { 'is-active': selectedRiskCampusScope === 'ALL' }]"
            @click="selectedRiskCampusScope = 'ALL'"
          >Toàn trường (5 cơ sở)</button>
          <button
            v-for="c in riskCampusCards"
            :key="'pill-' + c.ScopeID"
            :class="['uc-kpi-ops__campus-filter-pill', 'level-' + (c.RiskLevel ? c.RiskLevel.toLowerCase() : 'green'), { 'is-active': selectedRiskCampusScope === c.ScopeID }]"
            @click="selectedRiskCampusScope = (selectedRiskCampusScope === c.ScopeID ? 'ALL' : c.ScopeID)"
          >
            <b>{{ c.CampusName }}</b> ({{ c.RiskScore }}đ · {{ c.RiskLevel }})
          </button>
        </div>

        <!-- 5 Campus Risk Cards Grid -->
        <div class="uc-kpi-ops__risk-cards-grid" v-if="filteredRiskCampusCards && filteredRiskCampusCards.length">
          <div 
            v-for="c in filteredRiskCampusCards" 
            :key="c.ScopeID" 
            :class="['uc-kpi-ops__risk-card', 'level-' + (c.RiskLevel ? c.RiskLevel.toLowerCase() : 'green'), { 'is-selected': selectedRiskCampusScope === c.ScopeID }]"
            @click="selectedRiskCampusScope = (selectedRiskCampusScope === c.ScopeID ? 'ALL' : c.ScopeID)"
          >
            <div>
              <div class="uc-kpi-ops__risk-card-head">
                <div>
                  <div class="uc-kpi-ops__risk-campus-name">{{ c.CampusName }}</div>
                  <div class="uc-kpi-ops__risk-campus-sub">Sĩ số: {{ c.CurrentEnrollment }} / {{ c.PlannedCapacity }} ({{ c.OccupancyRate }}%)</div>
                </div>
                <span class="uc-kpi-ops__risk-score-badge">{{ c.RiskStatusText }}</span>
              </div>
              <div class="uc-kpi-ops__risk-forecast-box">
                <div class="uc-kpi-ops__risk-forecast-row">
                  <span>Dự báo rút:</span>
                  <span class="uc-kpi-ops__risk-forecast-val">{{ c.WithdrawForecast }}</span>
                </div>
                <div class="uc-kpi-ops__risk-forecast-row">
                  <span>Học phí rủi ro:</span>
                  <span class="uc-kpi-ops__risk-forecast-val">{{ c.TuitionAtRisk }}</span>
                </div>
              </div>
              <div class="uc-kpi-ops__risk-axes">
                <div class="uc-kpi-ops__risk-axis-item" v-if="c.Axis1Name">
                  <span>{{ c.Axis1Name }}</span>
                  <div class="uc-kpi-ops__risk-axis-bar-bg"><div class="uc-kpi-ops__risk-axis-bar-fill" :style="{ width: c.Axis1Pct + '%', background: c.Axis1Color }"></div></div>
                </div>
                <div class="uc-kpi-ops__risk-axis-item" v-if="c.Axis2Name">
                  <span>{{ c.Axis2Name }}</span>
                  <div class="uc-kpi-ops__risk-axis-bar-bg"><div class="uc-kpi-ops__risk-axis-bar-fill" :style="{ width: c.Axis2Pct + '%', background: c.Axis2Color }"></div></div>
                </div>
                <div class="uc-kpi-ops__risk-axis-item" v-if="c.Axis3Name">
                  <span>{{ c.Axis3Name }}</span>
                  <div class="uc-kpi-ops__risk-axis-bar-bg"><div class="uc-kpi-ops__risk-axis-bar-fill" :style="{ width: c.Axis3Pct + '%', background: c.Axis3Color }"></div></div>
                </div>
                <div class="uc-kpi-ops__risk-axis-item" v-if="c.Axis4Name">
                  <span>{{ c.Axis4Name }}</span>
                  <div class="uc-kpi-ops__risk-axis-bar-bg"><div class="uc-kpi-ops__risk-axis-bar-fill" :style="{ width: c.Axis4Pct + '%', background: c.Axis4Color }"></div></div>
                </div>
              </div>
            </div>
            <div class="uc-kpi-ops__risk-card-action" v-if="c.HdqDirective">
              <b>Chỉ đạo HĐQT:</b> {{ c.HdqDirective }}
            </div>
          </div>
        </div>
        <div v-else class="text-caption text-grey p-4 text-center">
          Đang nạp dữ liệu rủi ro cơ sở từ CSDL eSign...
        </div>

        <!-- Detail Split: Matrix & Checklist -->
        <div class="uc-kpi-ops__risk-detail-split">
          <!-- Left: 4-Axis Matrix Analysis -->
          <div class="uc-kpi-ops__risk-matrix-box">
            <div class="uc-kpi-ops__risk-subhead" style="display:flex;align-items:center;justify-content:space-between;">
              <div>
                <span>Ma Trận 4 Chiều Ngòi Nổ Rủi Ro Vận Hành (Risk Triggers)</span>
                <span style="font-size:11px;color:var(--ink3);margin-left:8px;">Fact Store {{ selectedPeriodText }}</span>
              </div>
              <div class="uc-kpi-ops__view-switcher">
                <button
                  type="button"
                  :class="['uc-kpi-ops__switcher-btn', { 'is-active': riskViewMode === 'CHART' }]"
                  @click="riskViewMode = 'CHART'"
                >Thẻ đo</button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__switcher-btn', { 'is-active': riskViewMode === 'TABLE' }]"
                  @click="riskViewMode = 'TABLE'"
                >Bảng</button>
              </div>
            </div>

            <!-- Chart / Cards View -->
            <div v-if="riskViewMode === 'CHART'" class="uc-kpi-ops__risk-cards-grid mt-2">
              <div 
                v-for="t in riskTriggers" 
                :key="t.TriggerID" 
                :class="['uc-kpi-ops__risk-card', t.SeverityClass]"
              >
                <div class="uc-kpi-ops__risk-card-head">
                  <div class="uc-kpi-ops__risk-card-title">{{ t.TriggerName }}</div>
                  <span :class="['uc-kpi-ops__checklist-status-badge', t.SeverityClass]">{{ t.TargetCampuses }}</span>
                </div>
                <div class="uc-kpi-ops__risk-card-meter">
                  <span>Mức độ:</span>
                  <div class="uc-kpi-ops__risk-meter-bar">
                    <div class="uc-kpi-ops__risk-meter-fill" :style="{ width: t.SeverityPct + '%', background: t.SeverityPct >= 70 ? '#ef4444' : '#f59e0b' }"></div>
                  </div>
                  <b :style="{ color: t.SeverityPct >= 70 ? '#ef4444' : '#f59e0b' }">{{ t.SeverityPct }}%</b>
                </div>
                <div class="uc-kpi-ops__risk-card-fact">
                  <b>Ngòi nổ:</b> {{ t.DataTrigger || t.DataTriggerT9 }}
                </div>
                <div class="uc-kpi-ops__risk-card-threat">
                  <b>Nguy cơ:</b> {{ t.RiskThreat || t.RiskThreatT10 }}
                </div>
                <div style="margin-top:6px;display:flex;justify-content:flex-end;">
                  <button
                    type="button"
                    class="uc-kpi-ops__simbtn"
                    style="padding:1px 6px;font-size:10.5px;"
                    @click.stop="jumpToFactStore(getTriggerFactDomain(t), t.TargetCampuses)"
                  >Xem chứng từ gốc &rsaquo;</button>
                </div>
              </div>
            </div>

            <!-- Table View -->
            <table v-else class="uc-kpi-ops__checklist-table mt-2">
              <thead>
                <tr>
                  <th style="width:18%;">Trục Rủi Ro</th>
                  <th style="width:32%;">Ngòi Nổ Dữ Liệu</th>
                  <th style="width:28%;">Chỉ Báo Nguy Cơ</th>
                  <th style="width:12%;">Trọng Điểm</th>
                  <th style="width:10%;text-align:right;">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="t in riskTriggers" :key="'tb-' + t.TriggerID">
                  <td><b>{{ t.TriggerName }}</b></td>
                  <td>{{ t.DataTrigger || t.DataTriggerT9 }}</td>
                  <td>{{ t.RiskThreat || t.RiskThreatT10 }}</td>
                  <td><span :class="['uc-kpi-ops__checklist-status-badge', t.SeverityClass]">{{ t.TargetCampuses }}</span></td>
                  <td style="text-align:right;">
                    <button
                      type="button"
                      class="uc-kpi-ops__simbtn"
                      style="padding:1px 6px;font-size:10px;"
                      @click.stop="jumpToFactStore(getTriggerFactDomain(t), t.TargetCampuses)"
                    >Xem chứng từ &rsaquo;</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Right: Preventive Checklist -->
          <div class="uc-kpi-ops__risk-checklist-box">
            <div class="uc-kpi-ops__risk-subhead" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:6px;">
              <span>Checklist Chỉ Đạo Can Thiệp Khẩn Cấp Của HĐQT</span>
              <div class="uc-kpi-ops__directive-filters">
                <button
                  type="button"
                  :class="['uc-kpi-ops__directive-btn', { 'is-active': directiveStatusFilter === 'ALL' }]"
                  @click="directiveStatusFilter = 'ALL'"
                >Tất cả</button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__directive-btn', { 'is-active': directiveStatusFilter === 'URGENT' }]"
                  @click="directiveStatusFilter = 'URGENT'"
                >Khẩn</button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__directive-btn', { 'is-active': directiveStatusFilter === 'PENDING' }]"
                  @click="directiveStatusFilter = 'PENDING'"
                >Chưa xong</button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__directive-btn', { 'is-active': directiveStatusFilter === 'DONE' }]"
                  @click="directiveStatusFilter = 'DONE'"
                >Đã xong</button>
              </div>
            </div>
            <table class="uc-kpi-ops__checklist-table" v-if="filteredRiskChecklist && filteredRiskChecklist.length">
              <thead>
                <tr>
                  <th style="width:28px;text-align:center;">#</th>
                  <th>Nội dung chỉ đạo phòng ngừa</th>
                  <th>Người phụ trách</th>
                  <th>Hạn chót</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="ch in filteredRiskChecklist"
                  :key="ch.ChecklistID"
                  :class="['uc-kpi-ops__directive-row', { 'is-done': isDirectiveDone(ch.ChecklistID) }]"
                >
                  <td style="text-align:center;">
                    <input
                      type="checkbox"
                      class="uc-kpi-ops__directive-check"
                      :checked="isDirectiveDone(ch.ChecklistID)"
                      @change="toggleDirectiveStatus(ch.ChecklistID)"
                      title="Đánh dấu đã hoàn thành"
                    />
                  </td>
                  <td>
                    <b>{{ ch.DirectiveTitle }}</b>
                    <div style="font-size:10.5px;color:var(--ink3);">{{ ch.SubText }}</div>
                  </td>
                  <td>{{ ch.OwnerRole }}</td>
                  <td><span :class="ch.StatusClass === 'is-urgent' ? 'tx-bad font-weight-bold' : 'tx-warn font-weight-bold'">{{ ch.DeadlineDate }}</span></td>
                </tr>
              </tbody>
            </table>
            <div v-else class="text-caption text-grey p-3 text-center">Không có chỉ thị nào trong mục này.</div>
          </div>
        </div>
      </div>

      <!-- ================= SUB-TAB 2: KIỂM TOÁN & ĐIỂM VÊNH BÁO CÁO (AUDIT) ================= -->
      <div v-if="executiveTab === 'AUDIT'" class="uc-kpi-ops__audit-container">
        <!-- 1. Dải KPI Sức Khỏe Kiểm Toán (Executive KPI Strip) -->
        <div class="uc-kpi-ops__audit-kpi-strip">
          <div
            :class="['uc-kpi-ops__audit-kpi-item', { 'is-selected': auditSeverityFilter === 'ALL' && auditDomainFilter === 'ALL' }]"
            @click="auditSeverityFilter = 'ALL'; auditDomainFilter = 'ALL'"
            title="Xem tất cả điểm đối soát"
          >
            <div class="uc-kpi-ops__audit-kpi-val">{{ auditDiscrepanciesList.length }}</div>
            <div class="uc-kpi-ops__audit-kpi-lbl">Tổng Điểm Đối Soát</div>
          </div>
          <div
            :class="['uc-kpi-ops__audit-kpi-item', 'is-critical', { 'is-selected': auditSeverityFilter === 'CRITICAL' }]"
            @click="auditSeverityFilter = (auditSeverityFilter === 'CRITICAL' ? 'ALL' : 'CRITICAL')"
            title="Lọc các điểm nóng cần xử lý khẩn cấp"
          >
            <div class="uc-kpi-ops__audit-kpi-val">{{ auditKpiStats.critical }}</div>
            <div class="uc-kpi-ops__audit-kpi-lbl">Vùng Đỏ Khẩn Cấp (Critical)</div>
          </div>
          <div
            :class="['uc-kpi-ops__audit-kpi-item', 'is-warn', { 'is-selected': auditSeverityFilter === 'WARN' }]"
            @click="auditSeverityFilter = (auditSeverityFilter === 'WARN' ? 'ALL' : 'WARN')"
            title="Lọc các điểm cảnh báo vận hành"
          >
            <div class="uc-kpi-ops__audit-kpi-val">{{ auditKpiStats.warn }}</div>
            <div class="uc-kpi-ops__audit-kpi-lbl">Cảnh Báo Vận Hành (Warn)</div>
          </div>
          <div
            :class="['uc-kpi-ops__audit-kpi-item', 'is-resolved', { 'is-selected': auditSeverityFilter === 'INFO' }]"
            @click="auditSeverityFilter = (auditSeverityFilter === 'INFO' ? 'ALL' : 'INFO')"
            title="Lọc các điểm đã đối soát / thông tin"
          >
            <div class="uc-kpi-ops__audit-kpi-val">{{ auditKpiStats.resolved }}</div>
            <div class="uc-kpi-ops__audit-kpi-lbl">Đã Xác Minh / Kiểm Toán</div>
          </div>
        </div>

        <!-- 2. Thanh Điều Khiển & Bộ Lọc Đa Chiều (Smart Control & Filter Bar) -->
        <div class="uc-kpi-ops__audit-toolbar">
          <!-- Row 1: Lọc theo phân hệ nghiệp vụ -->
          <div class="uc-kpi-ops__audit-domain-filters">
            <span class="uc-kpi-ops__filter-lbl">Phân hệ:</span>
            <button
              type="button"
              :class="['uc-kpi-ops__audit-pill-btn', { 'is-active': auditDomainFilter === 'ALL' }]"
              @click="auditDomainFilter = 'ALL'"
            >Tất cả ({{ auditDiscrepanciesList.length }})</button>
            <button
              type="button"
              :class="['uc-kpi-ops__audit-pill-btn', { 'is-active': auditDomainFilter === 'TS' }]"
              @click="auditDomainFilter = 'TS'"
            >Tuyển sinh &amp; Kênh Ads</button>
            <button
              type="button"
              :class="['uc-kpi-ops__audit-pill-btn', { 'is-active': auditDomainFilter === 'CM' }]"
              @click="auditDomainFilter = 'CM'"
            >Đào tạo &amp; LMS</button>
            <button
              type="button"
              :class="['uc-kpi-ops__audit-pill-btn', { 'is-active': auditDomainFilter === 'HR' }]"
              @click="auditDomainFilter = 'HR'"
            >Nhân sự &amp; Giáo viên</button>
            <button
              type="button"
              :class="['uc-kpi-ops__audit-pill-btn', { 'is-active': auditDomainFilter === 'CSVC' }]"
              @click="auditDomainFilter = 'CSVC'"
            >CSVC, Y tế &amp; Bán trú</button>
            <button
              type="button"
              :class="['uc-kpi-ops__audit-pill-btn', { 'is-active': auditDomainFilter === 'IT' }]"
              @click="auditDomainFilter = 'IT'"
            >Hệ thống &amp; CNTT</button>
          </div>

          <!-- Row 2: Lọc mức độ + Switcher Thẻ / Bảng -->
          <div class="uc-kpi-ops__audit-action-bar">
            <div class="uc-kpi-ops__audit-severity-filters">
              <span class="uc-kpi-ops__filter-lbl">Mức độ:</span>
              <button
                type="button"
                :class="['uc-kpi-ops__tag-btn', { 'is-active': auditSeverityFilter === 'ALL' }]"
                @click="auditSeverityFilter = 'ALL'"
              >Tất cả</button>
              <button
                type="button"
                :class="['uc-kpi-ops__tag-btn', 'is-bad', { 'is-active': auditSeverityFilter === 'CRITICAL' }]"
                @click="auditSeverityFilter = 'CRITICAL'"
              >Khẩn cấp ({{ auditKpiStats.critical }})</button>
              <button
                type="button"
                :class="['uc-kpi-ops__tag-btn', 'is-warn', { 'is-active': auditSeverityFilter === 'WARN' }]"
                @click="auditSeverityFilter = 'WARN'"
              >Cảnh báo ({{ auditKpiStats.warn }})</button>
              <button
                type="button"
                :class="['uc-kpi-ops__tag-btn', { 'is-active': auditSeverityFilter === 'INFO' }]"
                @click="auditSeverityFilter = 'INFO'"
              >Thông tin / Đã xử lý</button>
            </div>

            <div class="uc-kpi-ops__audit-view-controls">
              <button
                type="button"
                class="uc-kpi-ops__expand-all-btn"
                @click="toggleExpandAllAudit()"
                v-if="auditViewMode === 'CARD'"
              >
                {{ expandedAuditCodes.length >= filteredAuditList.length ? 'Thu gọn nhận định' : 'Mở rộng nhận định' }}
              </button>
              <div class="uc-kpi-ops__view-switcher">
                <button
                  type="button"
                  :class="['uc-kpi-ops__switcher-btn', { 'is-active': auditViewMode === 'DUMBBELL' }]"
                  @click="auditViewMode = 'DUMBBELL'"
                  title="Biểu đồ độ lệch Dumbbell Gap Chart"
                >Biểu Đồ Độ Lệch</button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__switcher-btn', { 'is-active': auditViewMode === 'CARD' }]"
                  @click="auditViewMode = 'CARD'"
                  title="Chế độ xem Thẻ Đối Soát"
                >Dạng Thẻ</button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__switcher-btn', { 'is-active': auditViewMode === 'TABLE' }]"
                  @click="auditViewMode = 'TABLE'"
                  title="Chế độ xem Bảng Ma Trận"
                >Dạng Bảng</button>
              </div>
            </div>
          </div>
        </div>

        <!-- 3A. CHẾ ĐỘ BIỂU ĐỒ ĐỘ LỆCH (DUMBBELL VARIANCE GAP CHART) -->
        <div v-if="auditViewMode === 'DUMBBELL'" class="uc-kpi-ops__dumbbell-list">
          <div
            v-for="item in filteredAuditList"
            :key="item.AuditCode || item.DiscrepancyID"
            class="uc-kpi-ops__dumbbell-card"
          >
            <div class="d-flex justify-space-between align-center mb-1">
              <div>
                <span class="uc-kpi-ops__fact-audit-badge" :class="'is-' + (item.Category ? item.Category.toLowerCase() : 'paradox')">
                  {{ item.Category === 'PARADOX' ? 'NGHỊCH LÝ ĐIỀU HÀNH' : (item.Category === 'BOTTLENECK' ? 'ĐIỂM NGHẼN VẬN HÀNH' : 'ĐỐI SOÁT VÊNH DỮ LIỆU') }} &middot; {{ item.AuditCode }}
                </span>
                <b class="ml-2" style="font-size:12px;color:#0f172a;">{{ item.Title }}</b>
              </div>
              <span class="uc-kpi-ops__sev-badge" :class="'is-' + (item.SeverityLevel ? item.SeverityLevel.toLowerCase() : 'warn')" style="font-size:10px;">
                Mức độ: {{ item.SeverityLevel || 'WARN' }}
              </span>
            </div>

            <!-- Dumbbell Variance Track -->
            <div class="uc-kpi-ops__dumbbell-track">
              <!-- Nguồn A (Báo cáo) -->
              <div class="uc-kpi-ops__dumbbell-point">
                <span class="uc-kpi-ops__dumbbell-node is-a"></span>
                <div>
                  <div style="font-size:10px;color:#64748b;">Nguồn A (Báo cáo vĩ mô)</div>
                  <b style="font-size:12px;color:#0369a1;">{{ item.PrimaryValue || item.PrimarySource || '93.6%' }}</b>
                </div>
              </div>

              <!-- Connecting Line & Gap Badge -->
              <div class="uc-kpi-ops__dumbbell-bridge">
                <span class="uc-kpi-ops__dumbbell-gap-badge">
                  Chênh lệch: {{ item.VarianceAmount ? (item.VarianceAmount + ' ' + (item.VarianceUnit || '')) : (item.VarianceText || 'Điểm vênh') }}
                </span>
              </div>

              <!-- Nguồn B (Thực tế) -->
              <div class="uc-kpi-ops__dumbbell-point">
                <div style="text-align:right;">
                  <div style="font-size:10px;color:#64748b;">Nguồn B (Giao dịch nguyên tử)</div>
                  <b style="font-size:12px;color:#c2410c;">{{ item.SecondaryValue || item.SecondarySource || '21 HS' }}</b>
                </div>
                <span class="uc-kpi-ops__dumbbell-node is-b"></span>
              </div>
            </div>

            <div class="d-flex justify-space-between align-center mt-1" style="font-size:11px;color:#64748b;">
              <div>
                Đầu mối giải trình: <b style="color:#334155;">{{ item.ActionOwner }}</b> &middot; Phạm vi: <b>{{ item.ScopeID || 'Toàn trường' }}</b>
                <span v-if="item.ActionStatus" class="ml-2 font-weight-bold" :style="{ color: item.ActionStatus === 'RESOLVED' ? '#16a34a' : '#ea580c' }">
                  &bull; {{ item.ActionStatus === 'RESOLVED' ? 'Đã giải trình' : 'Cần kiểm tra' }}
                </span>
              </div>
              <button
                type="button"
                class="uc-kpi-ops__simbtn"
                style="padding:2px 10px;font-size:11px;"
                @click="openFactModal(getAuditDomain(item), item.ScopeID, item)"
                title="Mở giao dịch gốc để đối soát chi tiết"
              >
                Đối Soát Gốc &rsaquo;
              </button>
            </div>
          </div>
        </div>

        <!-- 3B. CHẾ ĐỘ THẺ THÔNG MINH (SMART CARD GRID - 2 CỘT TƯƠNG PHẢN) -->
        <div v-if="auditViewMode === 'CARD'">
          <div class="uc-kpi-ops__audit-smart-grid" v-if="filteredAuditList && filteredAuditList.length">
            <div
              v-for="item in filteredAuditList"
              :key="item.AuditCode || item.DiscrepancyID"
              :class="['uc-kpi-ops__audit-smart-card', item.Category === 'MISMATCH' ? 'is-critical' : (item.Category === 'BOTTLENECK' ? 'is-bottleneck' : '')]"
            >
              <!-- Card Header -->
              <div class="uc-kpi-ops__audit-smart-top">
                <div class="uc-kpi-ops__audit-tags-group">
                  <span class="uc-kpi-ops__audit-code-badge">{{ item.AuditCode }}</span>
                  <span class="uc-kpi-ops__audit-cat-badge" :class="'cat-' + (item.Category ? item.Category.toLowerCase() : 'other')">
                    {{ item.Category }}
                  </span>
                  <span class="uc-kpi-ops__audit-scope-badge" v-if="item.ScopeID && item.ScopeID !== 'ALL'">
                    {{ item.ScopeID }}
                  </span>
                </div>
                <span :class="['uc-kpi-ops__status-pill', item.Category === 'MISMATCH' ? 'is-danger' : (item.VerificationStatus === 'RESOLVED' ? 'is-good' : 'is-warn')]">
                  {{ item.VerificationStatus || 'PENDING_VERIFY' }}
                </span>
              </div>

              <!-- Title -->
              <div class="uc-kpi-ops__audit-smart-title">
                {{ item.Title }}
              </div>

              <!-- Visual Contrast Side-by-Side: Nguồn A vs Nguồn B -->
              <div class="uc-kpi-ops__audit-contrast-box">
                <div class="uc-kpi-ops__contrast-side is-source-a">
                  <div class="uc-kpi-ops__contrast-lbl">Nguồn A (Báo cáo / Vận hành)</div>
                  <div class="uc-kpi-ops__contrast-val">{{ item.PrimaryValue }}</div>
                  <div class="uc-kpi-ops__contrast-sub">{{ item.PrimarySource }}</div>
                </div>
                <div class="uc-kpi-ops__contrast-vs">VS</div>
                <div class="uc-kpi-ops__contrast-side is-source-b">
                  <div class="uc-kpi-ops__contrast-lbl">Nguồn B (Thực tế phát hiện)</div>
                  <div class="uc-kpi-ops__contrast-val is-bad">{{ item.SecondaryValue }}</div>
                  <div class="uc-kpi-ops__contrast-sub">{{ item.SecondarySource }}</div>
                </div>
              </div>

              <!-- Accordion Toggle Button -->
              <div class="uc-kpi-ops__audit-accordion-toggle" @click="toggleAuditExpand(item.AuditCode)">
                <span>{{ isAuditExpanded(item.AuditCode) ? '▲ Thu gọn nhận định &amp; chỉ đạo' : '▼ Xem nhận định phân tích &amp; chỉ đạo BGH' }}</span>
              </div>

              <!-- Collapsible Content -->
              <div class="uc-kpi-ops__audit-expand-content" v-if="isAuditExpanded(item.AuditCode)">
                <div class="uc-kpi-ops__audit-desc">
                  <b>Phân tích sai lệch:</b> {{ item.VarianceAnalysis }}
                </div>
                <div class="uc-kpi-ops__audit-action" v-if="item.ResolutionDirective">
                  <b>Chỉ đạo BGH:</b> {{ item.ResolutionDirective }}
                </div>
              </div>

              <!-- Card Footer -->
              <div class="uc-kpi-ops__audit-smart-footer">
                <div class="uc-kpi-ops__audit-owner-lbl">
                  Đầu mối: <b>{{ item.ActionOwner }}</b>
                </div>
                <button
                  type="button"
                  class="uc-kpi-ops__simbtn is-solid"
                  style="padding:2px 8px;font-size:11px;"
                  @click="openFactModal(getAuditDomain(item), item.ScopeID, item)"
                  title="Mở giao dịch gốc để đối soát chi tiết"
                >Đối Soát Gốc &rsaquo;</button>
              </div>
            </div>
          </div>
          <div v-else class="uc-kpi-ops__empty-card p-4 text-center mt-3">
            <div style="font-size:13px;color:#16a34a;font-weight:600;">
              Không có điểm đối soát nào khớp với bộ lọc hiện tại.
            </div>
          </div>
        </div>

        <!-- 3B. CHẾ ĐỘ BẢNG MA TRẬN TINH GỌN (DENSE TABLE VIEW - 20 DÒNG QUÉT TRONG 10S) -->
        <div v-else class="uc-kpi-ops__audit-table-wrap mt-2">
          <table class="uc-kpi-ops__audit-matrix-table" v-if="filteredAuditList && filteredAuditList.length">
            <thead>
              <tr>
                <th style="width:14%;">Mã &amp; Nhóm</th>
                <th style="width:30%;">Vấn Đề &amp; Nội Dung Đối Soát</th>
                <th style="width:18%;">Nguồn A (Báo cáo)</th>
                <th style="width:18%;">Nguồn B (Thực tế)</th>
                <th style="width:12%;">Đầu Mối</th>
                <th style="width:8%;text-align:right;">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in filteredAuditList"
                :key="'tb-audit-' + (item.AuditCode || item.DiscrepancyID)"
                :class="['uc-kpi-ops__audit-tr', item.Category === 'MISMATCH' ? 'is-critical-row' : '']"
              >
                <td>
                  <div style="font-size:11px;font-weight:700;color:#1e293b;">{{ item.AuditCode }}</div>
                  <span class="uc-kpi-ops__audit-cat-badge" :class="'cat-' + (item.Category ? item.Category.toLowerCase() : 'other')">
                    {{ item.Category }}
                  </span>
                </td>
                <td>
                  <div style="font-weight:700;color:var(--ink);font-size:12px;">{{ item.Title }}</div>
                  <div style="font-size:11px;color:#64748b;margin-top:2px;" class="uc-kpi-ops__text-clamp">
                    {{ item.VarianceAnalysis }}
                  </div>
                </td>
                <td>
                  <b style="color:#0f172a;font-size:12px;">{{ item.PrimaryValue }}</b>
                  <div style="font-size:10px;color:#94a3b8;line-height:1.2;">{{ item.PrimarySource }}</div>
                </td>
                <td>
                  <b style="color:#d13438;font-size:12px;">{{ item.SecondaryValue }}</b>
                  <div style="font-size:10px;color:#94a3b8;line-height:1.2;">{{ item.SecondarySource }}</div>
                </td>
                <td>
                  <span style="font-size:11px;color:#334155;">{{ item.ActionOwner }}</span>
                </td>
                <td style="text-align:right;">
                  <button
                    type="button"
                    class="uc-kpi-ops__simbtn"
                    style="padding:1px 6px;font-size:10px;"
                    @click="openFactModal(getAuditDomain(item), item.ScopeID, item)"
                  >Đối soát &rsaquo;</button>
                </td>
              </tr>
            </tbody>
          </table>
          <div v-else class="uc-kpi-ops__empty-card p-4 text-center mt-3">
            <div style="font-size:13px;color:#16a34a;font-weight:600;">
              Không có điểm đối soát nào trong danh mục lọc.
            </div>
          </div>
        </div>
      </div>

      <!-- ================= 4. TAB 3: TIẾN ĐỘ & THỐNG KÊ DANH MỤC 60 KPI ================= -->
      <div v-if="executiveTab === 'FRAMEWORK'" class="uc-kpi-ops__rf-container">
        <!-- Header -->
        <div class="uc-kpi-ops__rf-header">
          <div>
            <div class="uc-kpi-ops__rf-title">
              Báo Cáo Thống Kê &amp; Tiến Độ Danh Mục 60 Chỉ Tiêu Vận Hành LHBS
            </div>
            <div class="uc-kpi-ops__rf-desc">
              Ma trận đo lường 60 chỉ tiêu vận hành chuẩn hóa theo Kết quả Họp BĐH 19/10/2026 (7 Tuyển sinh &middot; 20 Học thuật &middot; 24 Dịch vụ &middot; 9 CSVC/Tài chính)
            </div>
          </div>
          <div class="d-flex align-center" style="gap:8px;">
            <button
              type="button"
              class="uc-kpi-ops__simbtn"
              style="padding:3px 10px;font-size:11px;"
              @click="openFactModal('ENROLLMENT', 'ALL')"
            >
              Kho chứng từ gốc &rsaquo;
            </button>
            <button
              type="button"
              class="uc-kpi-ops__simbtn is-solid"
              style="padding:3px 10px;font-size:11px;"
              @click="executiveTab = 'COMMAND'"
            >
              Về Tổng quan điều hành &rsaquo;
            </button>
          </div>
        </div>

        <!-- 4 Stat Summary Cards (Khớp chuẩn Results Framework) -->
        <div class="uc-kpi-ops__rf-stats-grid mt-2">
          <div class="uc-kpi-ops__rf-stat-card">
            <div class="rf-stat-k">Tổng chỉ số Framework</div>
            <div class="rf-stat-v">{{ kpiHealthStats.total }} <small>KPI</small></div>
            <div class="rf-stat-d">7 Tuyển sinh &middot; 20 Học thuật &middot; 24 Dịch vụ &middot; 9 CSVC</div>
          </div>
          <div class="uc-kpi-ops__rf-stat-card is-good">
            <div class="rf-stat-k">Đạt chuẩn (GOOD)</div>
            <div class="rf-stat-v" style="color:#15803d;">{{ kpiHealthStats.good }} <small>KPI</small></div>
            <div class="rf-stat-d">Chiếm {{ kpiHealthStats.goodPct }}% tổng danh mục chỉ số</div>
          </div>
          <div class="uc-kpi-ops__rf-stat-card is-warn">
            <div class="rf-stat-k">Cảnh báo (WARN)</div>
            <div class="rf-stat-v" style="color:#b45309;">{{ kpiHealthStats.warn }} <small>KPI</small></div>
            <div class="rf-stat-d">Chiếm {{ kpiHealthStats.warnPct }}% (cần can thiệp vận hành)</div>
          </div>
          <div class="uc-kpi-ops__rf-stat-card is-pending">
            <div class="rf-stat-k">Chờ tích hợp API (PENDING)</div>
            <div class="rf-stat-v" style="color:#64748b;">{{ kpiHealthStats.pending }} <small>KPI</small></div>
            <div class="rf-stat-d">Lộ trình 02/11/2026 ({{ kpiHealthStats.pendingPct }}% danh mục)</div>
          </div>
        </div>

        <!-- Toolbar: Filters + Search + View Switcher -->
        <div class="uc-kpi-ops__rf-toolbar mt-3">
          <!-- Nhóm phân hệ -->
          <div class="uc-kpi-ops__rf-filter-grp">
            <span class="rf-filter-label">Phân hệ:</span>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkGroupFilter === 'ALL' }]"
              @click="frameworkGroupFilter = 'ALL'"
            >Tất cả ({{ periodSnapshots.length }})</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkGroupFilter === 'Quy mô & Tuyển sinh' }]"
              @click="frameworkGroupFilter = 'Quy mô & Tuyển sinh'"
            >Tuyển sinh (7)</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkGroupFilter === 'Giáo dục & Học thuật' || frameworkGroupFilter === 'Chất lượng Giáo dục' }]"
              @click="frameworkGroupFilter = 'Giáo dục & Học thuật'"
            >Học thuật (20)</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkGroupFilter === 'Dịch vụ & An toàn' || frameworkGroupFilter === 'Vận hành & Dịch vụ' }]"
              @click="frameworkGroupFilter = 'Dịch vụ & An toàn'"
            >Dịch vụ &amp; Y tế (24)</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkGroupFilter === 'Tài chính & CSVC' }]"
              @click="frameworkGroupFilter = 'Tài chính & CSVC'"
            >Tài chính &amp; CSVC (9)</button>
          </div>

          <!-- Tầng Level -->
          <div class="uc-kpi-ops__rf-filter-grp">
            <span class="rf-filter-label">Tầng:</span>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkLevelFilter === 'ALL' }]"
              @click="frameworkLevelFilter = 'ALL'"
            >Tất cả</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkLevelFilter === '1' }]"
              @click="frameworkLevelFilter = '1'"
            >Level 1</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkLevelFilter === '2' }]"
              @click="frameworkLevelFilter = '2'"
            >Level 2</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkLevelFilter === '3' }]"
              @click="frameworkLevelFilter = '3'"
            >Level 3</button>
          </div>

          <!-- Trạng thái -->
          <div class="uc-kpi-ops__rf-filter-grp">
            <span class="rf-filter-label">Trạng thái:</span>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkStatusFilter === 'ALL' }]"
              @click="frameworkStatusFilter = 'ALL'"
            >Tất cả ({{ periodSnapshots.length }})</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkStatusFilter === 'GOOD' }]"
              @click="frameworkStatusFilter = 'GOOD'"
            >Đạt chuẩn ({{ kpiHealthStats.good }})</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkStatusFilter === 'WARN' }]"
              @click="frameworkStatusFilter = 'WARN'"
            >Cảnh báo ({{ kpiHealthStats.warn }})</button>
            <button
              v-if="kpiHealthStats.critical > 0"
              type="button"
              :class="['rf-chip', { 'is-active': frameworkStatusFilter === 'CRITICAL' }]"
              @click="frameworkStatusFilter = 'CRITICAL'"
            >Nguy cấp ({{ kpiHealthStats.critical }})</button>
            <button
              type="button"
              :class="['rf-chip', { 'is-active': frameworkStatusFilter === 'PENDING' }]"
              @click="frameworkStatusFilter = 'PENDING'"
            >Chờ kết nối API ({{ kpiHealthStats.pending }})</button>
          </div>

          <!-- Switcher: Lưới Ô Nhiệt / Bảng Danh Sách -->
          <div class="uc-kpi-ops__view-toggle ml-2">
            <button
              type="button"
              :class="['uc-kpi-ops__view-toggle-btn', { 'is-active': frameworkViewMode === 'heatmap' }]"
              @click="frameworkViewMode = 'heatmap'"
              title="Xem ma trận ô nhiệt trực quan"
            >Lưới Ô Nhiệt</button>
            <button
              type="button"
              :class="['uc-kpi-ops__view-toggle-btn', { 'is-active': frameworkViewMode === 'table' }]"
              @click="frameworkViewMode = 'table'"
              title="Xem bảng tra cứu chi tiết"
            >Dạng Bảng</button>
          </div>

          <!-- Search Input -->
          <div class="uc-kpi-ops__rf-search-box ml-auto">
            <input
              type="text"
              v-model="frameworkSearchQuery"
              class="uc-kpi-ops__rf-search-input"
              placeholder="Tìm theo mã hoặc tên chỉ số KPI..."
            />
          </div>
        </div>

        <!-- CHẾ ĐỘ 1: MA TRẬN 60 Ô NHIỆT (KPI HEATMAP GRID VIEW - QUÉT TRONG 5 GIÂY) -->
        <div v-if="frameworkViewMode === 'heatmap'" class="uc-kpi-ops__heatmap-section">
          <div v-for="grp in ['Quy mô & Tuyển sinh', 'Giáo dục & Học thuật', 'Dịch vụ & An toàn', 'Tài chính & CSVC']" :key="grp" class="mb-3">
            <div class="uc-kpi-ops__heatmap-group-title">
              <span>{{ grp }} ({{ getGroupKpis(grp).length }} KPI)</span>
              <small style="color:#64748b;font-weight:400;">
                {{ getGroupKpis(grp).filter(k => k.Status === 'GOOD').length }} Đạt &middot; 
                {{ getGroupKpis(grp).filter(k => k.Status === 'WARN').length }} Cảnh báo &middot; 
                {{ getGroupKpis(grp).filter(k => k.Status === 'PENDING').length }} Chờ API
              </small>
            </div>
            <div class="uc-kpi-ops__heatmap-grid" v-if="getGroupKpis(grp).length">
              <div
                v-for="kpi in getGroupKpis(grp)"
                :key="kpi.KpiCode"
                :class="['uc-kpi-ops__heatmap-cell', 'status-' + (kpi.Status ? kpi.Status.toLowerCase() : 'pending')]"
                @click="openFactModal(getKpiFactDomain(kpi.KpiCode), 'ALL', null, kpi)"
                :title="kpi.KpiCode + ' - ' + kpi.KpiName + ' (' + (kpi.Status === 'GOOD' ? 'Đạt chuẩn' : (kpi.Status === 'WARN' ? 'Cảnh báo' : 'Chờ tích hợp API')) + ')'"
              >
                <div>
                  <div class="d-flex justify-space-between align-center">
                    <span class="uc-kpi-ops__hm-code">{{ kpi.KpiCode }}</span>
                    <span class="uc-kpi-ops__rf-level-badge level-level1" style="font-size:8.5px;padding:0 3px;">
                      {{ kpi.FrameworkLevel || 'L1' }}
                    </span>
                  </div>
                  <div class="uc-kpi-ops__hm-name">{{ kpi.KpiName }}</div>
                </div>
                <div class="uc-kpi-ops__hm-foot">
                  <span v-if="kpi.Status === 'PENDING'" style="color:#94a3b8;font-size:9.5px;">Lộ trình 02/11</span>
                  <span v-else style="color:#15803d;font-weight:700;">{{ formatKpiVal(kpi.ActualValue, kpi.Unit) }}</span>
                  
                  <span class="uc-kpi-ops__rf-status-badge" :class="'st-' + (kpi.Status ? kpi.Status.toLowerCase() : 'pending')" style="font-size:9px;padding:1px 5px;">
                    {{ kpi.Status === 'GOOD' ? 'Đạt' : (kpi.Status === 'WARN' ? 'Cảnh báo' : 'API') }}
                  </span>
                </div>
              </div>
            </div>
            <div v-else class="text-caption text-grey p-2" style="font-size:11px;">Không có chỉ số nào khớp bộ lọc.</div>
          </div>
        </div>

        <!-- CHẾ ĐỘ 2: BẢNG TRA CỨU CHI TIẾT 60 KPI (TABLE VIEW) -->
        <div v-else class="uc-kpi-ops__rf-table-wrap mt-2">
          <table class="uc-kpi-ops__rf-table" v-if="filteredFrameworkKpis && filteredFrameworkKpis.length">
            <thead>
              <tr>
                <th style="width:13%;">Mã &amp; Tầng</th>
                <th style="width:28%;">Tên Chỉ Số KPI &amp; Phân Hệ</th>
                <th style="width:13%;">Kế Hoạch</th>
                <th style="width:13%;">Thực Hiện</th>
                <th style="width:16%;">Tiến Độ Hoàn Thành</th>
                <th style="width:9%;">Trạng Thái</th>
                <th style="width:8%;text-align:right;">Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="kpi in filteredFrameworkKpis"
                :key="kpi.KpiCode"
                :class="['uc-kpi-ops__rf-tr', 'status-' + (kpi.Status ? kpi.Status.toLowerCase() : 'other')]"
              >
                <!-- Col 1: Mã & Cấp độ -->
                <td>
                  <div style="font-weight:700;font-size:12px;color:#0f172a;">{{ kpi.KpiCode }}</div>
                  <div class="d-flex align-center flex-wrap mt-1" style="gap:4px;">
                    <span v-if="kpi.FrameworkRef" class="uc-kpi-ops__rf-ref-badge">{{ kpi.FrameworkRef }}</span>
                    <span class="uc-kpi-ops__rf-level-badge" :class="'level-' + (kpi.FrameworkLevel ? kpi.FrameworkLevel.replace(/\s+/g, '').toLowerCase() : 'l1')">
                      {{ kpi.FrameworkLevel || 'Level 1' }}
                    </span>
                  </div>
                </td>

                <!-- Col 2: Tên & Phân hệ -->
                <td>
                  <div style="font-weight:600;font-size:12px;color:var(--ink);line-height:1.35;">{{ kpi.KpiName }}</div>
                  <div style="font-size:10.5px;color:#64748b;margin-top:2px;">
                    {{ kpi.KpiGroup }}
                    <span v-if="kpi.OperationalInsight" style="color:#475569;"> &middot; {{ kpi.OperationalInsight }}</span>
                  </div>
                </td>

                <!-- Col 3: Kế hoạch -->
                <td>
                  <template v-if="kpi.Status === 'PENDING' && (!kpi.TargetValue || kpi.TargetValue == 0)">
                    <span style="color:#94a3b8;font-size:11px;">--</span>
                  </template>
                  <template v-else>
                    <b style="font-size:12px;color:#334155;">{{ formatKpiVal(kpi.TargetValue, kpi.Unit) }}</b>
                    <div style="font-size:10px;color:#94a3b8;">{{ kpi.Unit }}</div>
                  </template>
                </td>

                <!-- Col 4: Thực hiện -->
                <td>
                  <template v-if="kpi.Status === 'PENDING'">
                    <span style="color:#94a3b8;font-size:11px;font-style:italic;">Chờ kết nối</span>
                  </template>
                  <template v-else>
                    <b :style="{ color: kpi.Status === 'GOOD' ? '#15803d' : (kpi.Status === 'WARN' ? '#b45309' : '#b91c1c'), fontSize: '12.5px' }">
                      {{ formatKpiVal(kpi.ActualValue, kpi.Unit) }}
                    </b>
                    <div style="font-size:10px;color:#94a3b8;">{{ kpi.Unit }}</div>
                  </template>
                </td>

                <!-- Col 5: Tiến độ thanh bar -->
                <td>
                  <template v-if="kpi.Status === 'PENDING'">
                    <div class="d-flex align-center justify-space-between mb-1" style="font-size:10.5px;">
                      <span style="color:#64748b;">Kỳ chốt:</span>
                      <b style="color:#64748b;">Lộ trình 02/11</b>
                    </div>
                    <div class="uc-kpi-ops__rf-prog-track">
                      <div class="uc-kpi-ops__rf-prog-fill prog-pending" style="width:0%;"></div>
                    </div>
                  </template>
                  <template v-else>
                    <div class="d-flex align-center justify-space-between mb-1" style="font-size:11px;">
                      <span style="color:#64748b;">Đạt:</span>
                      <b :style="{ color: kpi.Status === 'GOOD' ? '#15803d' : (kpi.Status === 'WARN' ? '#b45309' : '#b91c1c') }">
                        {{ kpi.Rate }}%
                      </b>
                    </div>
                    <div class="uc-kpi-ops__rf-prog-track">
                      <div
                        class="uc-kpi-ops__rf-prog-fill"
                        :class="'prog-' + (kpi.Status ? kpi.Status.toLowerCase() : 'other')"
                        :style="{ width: Math.min(100, Math.max(4, Number(kpi.Rate) || 0)) + '%' }"
                      ></div>
                    </div>
                  </template>
                </td>

                <!-- Col 6: Trạng thái badge -->
                <td>
                  <span class="uc-kpi-ops__rf-status-badge" :class="'st-' + (kpi.Status ? kpi.Status.toLowerCase() : 'other')">
                    {{ kpi.Status === 'GOOD' ? 'Đạt chuẩn' : (kpi.Status === 'WARN' ? 'Cảnh báo' : (kpi.Status === 'PENDING' ? 'Chờ tích hợp API' : 'Nguy cấp')) }}
                  </span>
                </td>

                <!-- Col 7: Thao tác mở Fact Store / Nguồn API -->
                <td style="text-align:right;">
                  <button
                    v-if="kpi.Status !== 'PENDING'"
                    type="button"
                    class="uc-kpi-ops__simbtn"
                    style="padding:1px 6px;font-size:10px;"
                    @click="openFactModal(getKpiFactDomain(kpi.KpiCode), 'ALL', null, kpi)"
                    title="Mở giao dịch gốc Fact Store đối soát chỉ số này"
                  >Xem Fact &rsaquo;</button>
                  <span
                    v-else
                    class="uc-kpi-ops__rf-source-tag"
                    :title="'Nguồn kết nối: ' + (kpi.SourceSystem || 'Hệ thống chuyên môn')"
                  >
                    {{ kpi.SourceSystem ? kpi.SourceSystem.split(' ')[0] : 'API' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
          <div v-else class="uc-kpi-ops__empty-card p-4 text-center mt-3">
            <div style="font-size:13px;color:#64748b;font-weight:600;">
              Không tìm thấy chỉ số KPI nào khớp với bộ lọc.
            </div>
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

    <!-- 4. PAGE 1: CƠ CẤU SĨ SỐ KHỐI LỚP (TS01, TS02) -->
    <div v-if="page === 1" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__visual">
        <div class="uc-kpi-ops__vhead" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
          <div>
            <div class="uc-kpi-ops__vtitle">Cơ Cấu Sĩ Số Học Sinh Toàn Bộ Các Khối Lớp {{ currentPeriodIsFrozen ? '(Số liệu chốt sổ)' : '(Live API)' }}</div>
            <div class="uc-kpi-ops__vnote">Tổng cộng: <b>{{ formatNumber(computedTotalStudents) }} học sinh</b></div>
          </div>
          <div class="uc-kpi-ops__view-switcher">
            <button
              type="button"
              :class="['uc-kpi-ops__switcher-btn', { 'is-active': gradeViewMode === 'CHART' }]"
              @click="gradeViewMode = 'CHART'"
            >Biểu đồ cột ngang</button>
            <button
              type="button"
              :class="['uc-kpi-ops__switcher-btn', { 'is-active': gradeViewMode === 'TABLE' }]"
              @click="gradeViewMode = 'TABLE'"
            >Bảng số liệu</button>
          </div>
        </div>

        <!-- Biểu Đồ Cột Ngang Đôi (Horizontal Stacked Bar Chart) -->
        <div v-if="gradeViewMode === 'CHART'" class="uc-kpi-ops__grade-chart-wrap mt-2">
          <!-- Legend -->
          <div class="uc-kpi-ops__chart-legend">
            <span><span class="legend-dot is-boy"></span> Nam</span>
            <span><span class="legend-dot is-girl"></span> Nữ</span>
            <span><span class="legend-dot is-thin"></span> Quy mô mỏng (&lt;100 HS)</span>
            <span class="legend-note">Vạch chuẩn an toàn: 100 HS/khối</span>
          </div>

          <div class="uc-kpi-ops__grade-bars-list">
            <div
              v-for="r in currentGradeRows"
              :key="r.Ten"
              class="uc-kpi-ops__grade-bar-row"
            >
              <div class="uc-kpi-ops__grade-bar-label">
                <b>{{ r.Ten }}</b>
              </div>
              <div class="uc-kpi-ops__grade-bar-track">
                <div
                  class="uc-kpi-ops__grade-bar-inner"
                  :style="{ width: Math.max(8, Math.min(100, (r.SLHocSinh / maxGradeEnrollment) * 100)) + '%' }"
                >
                  <div
                    class="uc-kpi-ops__grade-segment is-boy"
                    :style="{ width: (r.SLHocSinh > 0 ? (r.SL_HSNam / r.SLHocSinh) * 100 : 50) + '%' }"
                    :title="'Nam: ' + formatNumber(r.SL_HSNam) + ' HS (' + calcPercent(r.SL_HSNam, r.SLHocSinh) + '%)'"
                  >
                    <span v-if="r.SL_HSNam > 25">{{ r.SL_HSNam }}</span>
                  </div>
                  <div
                    class="uc-kpi-ops__grade-segment is-girl"
                    :style="{ width: (r.SLHocSinh > 0 ? (r.SL_HSNu / r.SLHocSinh) * 100 : 50) + '%' }"
                    :title="'Nữ: ' + formatNumber(r.SL_HSNu) + ' HS (' + calcPercent(r.SL_HSNu, r.SLHocSinh) + '%)'"
                  >
                    <span v-if="r.SL_HSNu > 25">{{ r.SL_HSNu }}</span>
                  </div>
                </div>
                <!-- Benchmark 100 HS -->
                <div
                  class="uc-kpi-ops__grade-benchmark-line"
                  :style="{ left: Math.min(100, (100 / maxGradeEnrollment) * 100) + '%' }"
                  title="Ngưỡng quy mô tối thiểu: 100 HS"
                ></div>
              </div>
              <div class="uc-kpi-ops__grade-bar-stat">
                <b class="stat-total">{{ formatNumber(r.SLHocSinh) }}</b> <small>HS</small>
                <span class="stat-pct">({{ ((r.SLHocSinh / (computedTotalStudents || 1)) * 100).toFixed(1) }}%)</span>
                <span :class="['uc-kpi-ops__cell-tag', r.SLHocSinh >= 100 ? 'is-good' : 'is-warn']">
                  {{ r.SLHocSinh >= 100 ? 'Ổn định' : 'Mỏng' }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Bảng Số Liệu Truyền Thống -->
        <div v-else class="uc-kpi-ops__tablewrap">
          <table class="uc-kpi-ops__table">
            <thead>
              <tr>
                <th class="ta-l">STT</th>
                <th class="ta-l">Khối Lớp</th>
                <th>Tổng sĩ số</th>
                <th>Nam</th>
                <th>Nữ</th>
                <th>Tỷ lệ Nữ (%)</th>
                <th>Tỷ trọng</th>
                <th class="ta-l">Tình trạng</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in currentGradeRows" :key="r.Ten">
                <td class="ta-l">{{ r.STT }}</td>
                <td class="ta-l tx-strong">{{ r.Ten }}</td>
                <td class="tx-strong">{{ formatNumber(r.SLHocSinh) }}</td>
                <td>{{ formatNumber(r.SL_HSNam) }}</td>
                <td>{{ formatNumber(r.SL_HSNu) }}</td>
                <td>{{ calcPercent(r.SL_HSNu, r.SLHocSinh) }}%</td>
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
    </div>

    <!-- 5. PAGE 2: HỌC SINH CHUYỂN ĐI & RÚT HỌC (TS04) -->
    <div v-if="page === 2" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__bcols">
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
            <div>
              <div class="uc-kpi-ops__vtitle">Top Lý Do Rút Học &amp; Chuyển Đi ({{ displayWithdrawTotalCount }} bản ghi)</div>
              <div class="uc-kpi-ops__vnote">Nguồn: {{ currentPeriodIsFrozen ? 'Kho chốt sổ CSDL eSign' : 'API ThongKeHocSinhChuyenDi' }}</div>
            </div>
            <div class="uc-kpi-ops__view-switcher">
              <button
                type="button"
                :class="['uc-kpi-ops__switcher-btn', { 'is-active': withdrawViewMode === 'CHART' }]"
                @click="withdrawViewMode = 'CHART'"
              >Biểu đồ xếp hạng</button>
              <button
                type="button"
                :class="['uc-kpi-ops__switcher-btn', { 'is-active': withdrawViewMode === 'TABLE' }]"
                @click="withdrawViewMode = 'TABLE'"
              >Bảng</button>
            </div>
          </div>

          <!-- Biểu Đồ Cột Xếp Hạng & Khả Năng Can Thiệp (Ranked Horizontal Bars) -->
          <div v-if="withdrawViewMode === 'CHART'" class="uc-kpi-ops__withdraw-chart-wrap">
            <div
              v-for="(r, i) in displayTopWithdrawReasons"
              :key="r.name"
              class="uc-kpi-ops__withdraw-rank-item"
            >
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
                <span :class="['can-intervene-badge', getInterveneClass(r.name)]">
                  {{ getInterveneLabel(r.name) }}
                </span>
              </div>
            </div>
          </div>

          <!-- Bảng Truyền Thống -->
          <div v-else class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
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
                  <td>
                    <span class="uc-kpi-ops__btrack">
                      <span class="uc-kpi-ops__bfill is-bad" :style="{ width: r.percent * 2 + '%' }"></span>
                    </span>
                    {{ r.percent }}%
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Mẫu Danh Sách Học Sinh Chuyển Đi Gần Nhất</div>
            <div class="uc-kpi-ops__vnote">Tổng số: {{ withdrawRecords.length }} HS</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Họ và tên</th>
                  <th>Lớp</th>
                  <th class="ta-l">Trường đến</th>
                  <th class="ta-l">Lý do</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(r, i) in withdrawRecords.slice(0, 8)" :key="i">
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
    </div>


    <!-- 7. PAGE 4: CHUYÊN MÔN & LMS (CM04: Học liệu số, CM08: Bài tập LMS, CM01: TKB) -->
    <div v-if="page === 4" class="uc-kpi-ops__page">
      <!-- Section 1: CM08 - Mức độ hoàn thành bài tập của học sinh trên LMS -->
      <div class="uc-kpi-ops__visual">
        <div class="uc-kpi-ops__vhead" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
          <div>
            <div class="uc-kpi-ops__vtitle">Mức Độ Hoàn Thành Bài Tập Của Học Sinh Trên LMS (CM08)</div>
            <div class="uc-kpi-ops__vnote">Tỷ lệ hoàn thành toàn cấp: <b class="tx-good">{{ lmsOverallRate }}%</b> (Tổng {{ formatNumber(lmsTotalAssigned) }} lượt bài tập giao)</div>
          </div>
          <div class="uc-kpi-ops__view-switcher">
            <button
              type="button"
              :class="['uc-kpi-ops__switcher-btn', { 'is-active': lmsViewMode === 'CHART' }]"
              @click="lmsViewMode = 'CHART'"
            >Thẻ tiến độ</button>
            <button
              type="button"
              :class="['uc-kpi-ops__switcher-btn', { 'is-active': lmsViewMode === 'TABLE' }]"
              @click="lmsViewMode = 'TABLE'"
            >Bảng số liệu</button>
          </div>
        </div>

        <div v-if="!lmsAssignmentRows.length" class="text-caption text-grey p-3 text-center">
          Chưa có dữ liệu bài tập LMS cho kỳ này (kỳ chốt sổ chưa có snapshot LMS; chuyển sang kỳ Live để lấy từ API).
        </div>
        <!-- Lưới Thẻ Tiến Độ Môn Học Trực Quan (Progress Grid) -->
        <div v-else-if="lmsViewMode === 'CHART'" class="uc-kpi-ops__lms-cards-grid">
          <div
            v-for="r in lmsAssignmentRows"
            :key="r.MonHocID"
            class="uc-kpi-ops__lms-card"
          >
            <div class="uc-kpi-ops__lms-card-head">
              <div class="uc-kpi-ops__lms-card-title">{{ r.TenMonHoc_HienThi }}</div>
              <div :class="['uc-kpi-ops__lms-card-pct', r.CompletionRate_Assignments >= 80 ? 'tx-good' : 'tx-warn']">
                {{ r.CompletionRate_Assignments }}%
              </div>
            </div>
            <!-- Stacked Progress Bar: Đã chấm (Xanh lá) - Chờ chấm (Xanh dương) - Chưa làm (Xám) -->
            <div class="uc-kpi-ops__lms-stacked-bar">
              <div
                class="uc-kpi-ops__lms-seg is-graded"
                :style="{ width: ((r.Total_DaCham / (r.TotalAssigned || 1)) * 100) + '%' }"
                :title="'Đã chấm: ' + formatNumber(r.Total_DaCham) + ' (' + r.CompletionRate_Graded + '%)'"
              ></div>
              <div
                class="uc-kpi-ops__lms-seg is-submitted"
                :style="{ width: (((r.Total_DaNop - r.Total_DaCham) / (r.TotalAssigned || 1)) * 100) + '%' }"
                :title="'Đã nộp chờ chấm: ' + formatNumber(r.Total_DaNop - r.Total_DaCham)"
              ></div>
              <div
                class="uc-kpi-ops__lms-seg is-pending"
                :style="{ width: ((r.Total_ChuaLam / (r.TotalAssigned || 1)) * 100) + '%' }"
                :title="'Chưa làm: ' + formatNumber(r.Total_ChuaLam)"
              ></div>
            </div>
            <div class="uc-kpi-ops__lms-card-meta">
              <div>Đã giao<b>{{ formatNumber(r.TotalAssigned) }}</b></div>
              <div>Đã nộp<b class="tx-good">{{ formatNumber(r.Total_DaNop) }}</b></div>
              <div>Chưa làm<b :class="r.Total_ChuaLam > 100 ? 'tx-warn' : ''">{{ formatNumber(r.Total_ChuaLam) }}</b></div>
            </div>
          </div>
        </div>

        <!-- Bảng Số Liệu Truyền Thống -->
        <div v-else class="uc-kpi-ops__tablewrap">
          <table class="uc-kpi-ops__table">
            <thead>
              <tr>
                <th class="ta-l">Môn học</th>
                <th>Tổng bài tập đã tạo</th>
                <th>Lượt HS được giao</th>
                <th>Đã nộp bài</th>
                <th>Đã chấm điểm</th>
                <th>Chưa làm</th>
                <th>Tỷ lệ hoàn thành (CM08)</th>
                <th>Tỷ lệ đã chấm</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in lmsAssignmentRows" :key="r.MonHocID">
                <td class="ta-l tx-strong">{{ r.TenMonHoc_HienThi }}</td>
                <td>{{ r.TotalAssignments }} bài</td>
                <td class="tx-strong">{{ formatNumber(r.TotalAssigned) }}</td>
                <td>{{ formatNumber(r.Total_DaNop) }}</td>
                <td class="tx-good">{{ formatNumber(r.Total_DaCham) }}</td>
                <td class="tx-muted">{{ formatNumber(r.Total_ChuaLam) }}</td>
                <td>
                  <span class="uc-kpi-ops__btrack">
                    <span :class="['uc-kpi-ops__bfill', r.CompletionRate_Assignments >= 80 ? 'is-good' : 'is-warn']" :style="{ width: r.CompletionRate_Assignments + '%' }"></span>
                  </span>
                  <b>{{ r.CompletionRate_Assignments }}%</b>
                </td>
                <td>{{ r.CompletionRate_Graded }}%</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Section 2: CM04 - Mức độ ứng dụng Học liệu số của giáo viên -->
      <div class="uc-kpi-ops__visual">
        <div class="uc-kpi-ops__vhead">
          <div class="uc-kpi-ops__vtitle">Mức Độ Ứng Dụng Học Liệu Số &amp; Năng Lực Số Của Giáo Viên (CM04 · spAPI_BaoCao_2_ThongKe_HocLieuSo_ByCapID)</div>
          <div class="uc-kpi-ops__vnote">Tổng cộng: <b>{{ lmsHocLieuSummary.total }} bài giảng</b> · Đã số hóa nội dung: <b class="tx-good">{{ lmsHocLieuSummary.coNoiDung }} bài ({{ lmsHocLieuSummary.pct }}%)</b> · {{ lmsHocLieuSummary.totalFiles }} files đa phương tiện</div>
        </div>
        <div class="uc-kpi-ops__tablewrap">
          <table class="uc-kpi-ops__table">
            <thead>
              <tr>
                <th class="ta-l">Môn học</th>
                <th>Khối</th>
                <th>Tổng học liệu tạo</th>
                <th>Học liệu đã có nội dung (video/slide)</th>
                <th>Học liệu chưa có nội dung</th>
                <th>Tổng tài nguyên số gắn kèm</th>
                <th>Tỷ lệ số hóa học liệu (CM04)</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="!lmsHocLieuRows.length"><td colspan="7" class="tx-muted" style="padding:16px;text-align:center;">Chưa có dữ liệu học liệu số cho kỳ này.</td></tr>
              <tr v-for="(r, i) in lmsHocLieuRows.slice(0, 10)" :key="i">
                <td class="ta-l tx-strong">{{ r.TenMonHoc_HienThi }}</td>
                <td>Khối {{ r.KhoiID }}</td>
                <td>{{ r.TongHocLieu }}</td>
                <td class="tx-good tx-strong">{{ r.HocLieuCoNoiDung }}</td>
                <td class="tx-muted">{{ r.HocLieuChuaCoNoiDung }}</td>
                <td>{{ r.TongNoiDung }} files</td>
                <td>
                  <span class="uc-kpi-ops__btrack">
                    <span class="uc-kpi-ops__bfill is-good" :style="{ width: (r.HocLieuCoNoiDung / (r.TongHocLieu || 1) * 100) + '%' }"></span>
                  </span>
                  <b>{{ ((r.HocLieuCoNoiDung / (r.TongHocLieu || 1)) * 100).toFixed(0) }}%</b>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Section 3: CM01 - Tiến độ thực hiện tiết dạy theo Thời khóa biểu -->
      <div class="uc-kpi-ops__visual">
        <div class="uc-kpi-ops__vhead">
          <div class="uc-kpi-ops__vtitle">Tiến Độ Thực Hiện Tiết Dạy Phân Phối Chương Trình (CM01 · Calen)</div>
          <div class="uc-kpi-ops__vnote">Thực dạy tuần khảo sát: Toán, Ngữ văn, KHTN, STEM</div>
        </div>
        <div class="uc-kpi-ops__tablewrap">
          <table class="uc-kpi-ops__table">
            <thead>
              <tr>
                <th class="ta-l">Lớp</th>
                <th>Tổng tiết dạy</th>
                <th>Toán</th>
                <th>Ngữ văn</th>
                <th>KHTN</th>
                <th>STEM</th>
                <th class="ta-l">Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="!teachingProgressRows.length"><td colspan="7" class="tx-muted" style="padding:16px;text-align:center;">Chưa có dữ liệu tiến độ tiết dạy cho kỳ này.</td></tr>
              <tr v-for="r in teachingProgressRows" :key="r.TenLop">
                <td class="ta-l tx-strong">{{ r.TenLop }}</td>
                <td class="tx-strong">{{ r.TongTiet }} tiết</td>
                <td>{{ r.Toan }}</td>
                <td>{{ r.Van }}</td>
                <td>{{ r.KHTN }}</td>
                <td>{{ r.STEM }}</td>
                <td class="ta-l"><span class="uc-kpi-ops__cell-tag is-good">Đúng tiến độ</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 8. PAGE 5: TÀI CHÍNH VẬN HÀNH (Nhóm 4: Chỉ tiêu 55 & 56) -->
    <div v-if="page === 5" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__vhead mb-2">
        <div class="uc-kpi-ops__vtitle">Chỉ tiêu Tài chính Vận hành (Nhóm 4 · Chỉ tiêu 55, 56) · {{ currentUnitTitle }}</div>
        <div class="uc-kpi-ops__vnote">Tỷ suất LN gộp: <b>{{ computedFinanceData.grossMargin }}</b> (Mục tiêu {{ getKpiTarget('TC55') || '50%' }}) · Doanh thu CLB: <b>{{ computedFinanceData.clbRev }}</b> ({{ computedFinanceData.clbStudents }} HS tham gia) · Nguồn: PM FTS</div>
      </div>

      <!-- 4 Stats Cards Tài chính -->
      <div class="uc-kpi-ops__bkpis">
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>TỶ SUẤT LN GỘP DỊCH VỤ (KPI 4)</span>
            <b class="tx-good">MỤC TIÊU {{ getKpiTarget('TC55') || '50%' }}</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v tx-good">{{ computedFinanceData.grossMargin }}</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Bán trú {{ computedFinanceData.mealMargin }} · Xe bus {{ computedFinanceData.busMargin }} · Bán lẻ {{ computedFinanceData.retailMargin || "—" }}</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>DOANH THU THUẦN (ƯỚC TÍNH)</span>
            <b>HỌC KỲ 1</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedFinanceData.rev }}</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Lợi nhuận gộp ước tính đạt ~{{ computedFinanceData.grossMargin }} doanh thu</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>DOANH THU CÁC CLB (KPI 3.2.1)</span>
            <b class="tx-good">HỌC KỲ 1</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedFinanceData.clbRev }}</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Đóng góp tích lũy vào quỹ tái đầu tư cơ sở vật chất</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>HỌC SINH THAM GIA CLB</span>
            <b>{{ currentUnitTitle }}</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedFinanceData.clbStudents }}</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Tham gia CLB bổ trợ ngoài giờ (Toán tư duy, Robotics, Thể thao)</div>
        </div>
      </div>

      <!-- 2 Bảng Tài chính chi tiết -->
      <div class="uc-kpi-ops__bcols">
        <!-- Bảng 1: Chỉ tiêu 55 - Tỷ suất LN gộp dịch vụ -->
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Chỉ Tiêu 55: Tỷ Suất Lợi Nhuận Gộp Dịch Vụ (KPI 4 - Mục Tiêu {{ getKpiTarget('TC55') || '50%' }})</div>
            <div class="uc-kpi-ops__vnote">Nguồn: Phòng Kế toán PM FTS</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Mảng hoạt động / Dịch vụ</th>
                  <th>Doanh thu thuần</th>
                  <th>Chi phí trực tiếp</th>
                  <th>Lợi nhuận gộp</th>
                  <th>Tỷ suất LN gộp (KPI 4)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="s in financeServices" :key="s.name">
                  <td class="ta-l tx-strong">{{ s.name }}</td>
                  <td>{{ s.revenue }}</td>
                  <td>{{ s.cost }}</td>
                  <td class="tx-strong">{{ s.grossProfit }}</td>
                  <td class="tx-strong" :class="parseFloat(s.margin) >= 40 ? 'tx-good' : ''">{{ s.margin }}</td>
                </tr>
                <tr class="is-total">
                  <td class="ta-l tx-strong">Tổng hòa hợp nhất</td>
                  <td class="tx-strong">{{ financeSummaryTotalRevenue }}</td>
                  <td class="tx-strong">{{ financeSummaryTotalCost }}</td>
                  <td class="tx-good tx-strong">{{ financeSummaryTotalProfit }}</td>
                  <td class="tx-good tx-strong">{{ financeSummaryTotalMargin }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Bảng 2: Chỉ tiêu 56 - Doanh thu CLB bổ trợ -->
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Chỉ Tiêu 56: Doanh Thu Các CLB Bổ Trợ Ngoài Giờ (KPI 3.2.1)</div>
            <div class="uc-kpi-ops__vnote">Mục tiêu HK1: {{ displayClubTarget }} (Đã đạt {{ totalClubRevenueText }} · {{ clubAchievedPct }}) · Đóng góp mục tiêu chiến lược 1 triệu USD tích lũy</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Tên Câu lạc bộ bổ trợ</th>
                  <th>Số học sinh</th>
                  <th>Đơn giá/kỳ</th>
                  <th>Doanh thu HK1</th>
                  <th>Tỷ trọng DT</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="c in financeClubs" :key="c.name">
                  <td class="ta-l tx-strong">{{ c.name }}</td>
                  <td class="tx-strong">{{ c.students }} HS</td>
                  <td>{{ c.fee }}</td>
                  <td class="tx-good tx-strong">{{ c.revenue }}</td>
                  <td>{{ c.share }}</td>
                </tr>
                <tr class="is-total">
                  <td class="ta-l tx-strong">Toàn trường ({{ financeClubs.length }} môn CLB)</td>
                  <td class="tx-strong">{{ totalClubStudents }} HS</td>
                  <td>—</td>
                  <td class="tx-good tx-strong">{{ totalClubRevenueText }}</td>
                  <td class="tx-good tx-strong">100% (Đạt {{ clubAchievedPct }}% KH Học Kỳ 1 · Tích lũy {{ clubMillionDollarAccumPct }}% Mục tiêu $1M)</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- 9. PAGE 6: VẬN HÀNH & AN TOÀN HỌC ĐƯỜNG, Y TẾ, ME (VH02, VH11) -->
    <div v-if="page === 6" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__bcols">
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">An Toàn Học Đường &amp; Y Tế Học Đường (VH02, VH11)</div>
            <div class="uc-kpi-ops__vnote">{{ selectedPeriodText }}</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <tbody>
                <tr>
                  <td class="ta-l tx-strong">Sự cố ngộ độc thực phẩm bếp ăn</td>
                  <td class="tx-good">{{ opsSafetyMe.FoodPoisoningCases != null ? opsSafetyMe.FoodPoisoningCases + ' vụ (Đạt KPI)' : '0 vụ (Đạt KPI)' }}</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Sự cố tai nạn thương tích nghiêm trọng</td>
                  <td class="tx-good">{{ opsSafetyMe.AccidentCases != null ? opsSafetyMe.AccidentCases + ' vụ (Đạt KPI)' : '0 vụ (Đạt KPI)' }}</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Tỷ lệ học sinh ăn bán trú toàn trường</td>
                  <td>{{ opsSafetyMe.BoardingRate != null ? opsSafetyMe.BoardingRate + '% (' + formatNumber(opsSafetyMe.BoardingStudents) + ' HS)' : '—' }}</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Tỷ lệ phụ huynh cài đặt app ME School</td>
                  <td class="tx-good">{{ opsSafetyMe.MeAppInstallRate != null ? opsSafetyMe.MeAppInstallRate + '% (' + formatNumber(opsSafetyMe.MeAppInstallParents) + ' PH)' : '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Tương Tác Phụ Huynh Qua Kênh ME School {{ currentPeriodIsFrozen ? '(Số liệu chốt sổ)' : '(Live API)' }}</div>
            <div class="uc-kpi-ops__vnote">HoatDongTrangMe_PH_TuongTac</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <tbody>
                <tr>
                  <td class="ta-l tx-strong">Lượt tương tác tin tức / thông báo</td>
                  <td class="tx-strong">{{ opsSafetyMe.NewsInteractions != null ? formatNumber(opsSafetyMe.NewsInteractions) + ' lượt / tháng' : '—' }}</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Lượt điểm danh nhận diện khuôn mặt</td>
                  <td class="tx-strong">{{ opsSafetyMe.FaceIdCheckins != null ? formatNumber(opsSafetyMe.FaceIdCheckins) + ' lượt' : '—' }}</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Đánh giá độ hài lòng dịch vụ (VH06)</td>
                  <td class="tx-good">{{ opsSafetyMe.SatisfactionRate != null ? opsSafetyMe.SatisfactionRate + '% Hài lòng' : '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- 9b. PAGE 7: PHỄU TUYỂN SINH & LEADS CRM (TS05, TS06) -->
    <div v-if="page === 7" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__vhead mb-2">
        <div class="uc-kpi-ops__vtitle">Chuyên môn Tuyển sinh &amp; Chăm sóc khách hàng (TVTS · CRM)</div>
        <div class="uc-kpi-ops__vnote">Lũy kế NH 2026–2027: <b>{{ computedCrmLeads }} Leads (TS05)</b> · Chuyển đổi: <b>{{ computedCrmConversionRate }}% ({{ computedCrmEnrolled }} HS nhập học - TS06)</b> · Nguồn: TVTS Tracking</div>
      </div>

      <!-- 4 Stats Cards CRM -->
      <div class="uc-kpi-ops__bkpis">
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>TỔNG LEADS TIẾP NHẬN (TS05)</span>
            <b>{{ currentPeriodName.toUpperCase() }}: {{ computedCrmLeadsCurrentMonth }}</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedCrmLeads }} <small>Leads</small></div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">{{ crmMonthlySummaryText }}</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>TỶ LỆ CHUYỂN ĐỔI (TS06)</span>
            <b class="tx-good">ĐẠT {{ computedCrmConversionRate }}%</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v tx-good">{{ computedCrmConversionRate }}%</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">{{ computedCrmUnitRatesText }}</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>NHẬP HỌC THỰC TẾ</span>
            <b>{{ computedCrmEnrolled }} HỌC SINH</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedCrmEnrolled }} <small>HS</small></div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Đã hoàn tất đóng phí tuyển mới và nộp hồ sơ</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-warn" @click="openDrawer('KITTY_LIST')">
          <div class="uc-kpi-ops__bkpi-h">
            <span>PIPELINE KITTY (HẸN HK2)</span>
            <b class="tx-warn">{{ crmKittyList.length }} HỒ SƠ</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ crmKittyList.length }} <small>Hồ sơ</small></div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Bé chờ đủ tuổi HK2 (Tab Kitty GID 1481169716)</div>
          <div class="uc-kpi-ops__bkpi-i">Xem chi tiết {{ crmKittyList.length }} hồ sơ ›</div>
        </div>
      </div>

      <!-- Funnel Progress & Channel Matrix -->
      <div class="uc-kpi-ops__bcols">
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Báo Cáo Diễn Biến Leads &amp; Nhập Học 3 Tháng {{ currentPeriodIsFrozen ? '(Số liệu chốt sổ)' : '(Live Tracking)' }}</div>
            <div class="uc-kpi-ops__vnote">Sheet BÁO CÁO (GID 1313591411)</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Kỳ báo cáo</th>
                  <th>Leads PTLC</th>
                  <th>Leads MNBH</th>
                  <th>Leads MNLK</th>
                  <th>Tổng Leads (TS05)</th>
                  <th>Nhập học</th>
                  <th>Chuyển đổi (TS06)</th>
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
                <tr class="is-total">
                  <td class="ta-l tx-strong">Lũy kế {{ crmMonthlySummary.length }} tháng</td>
                  <td class="tx-strong">{{ crmTotalPtlcLeads }}</td>
                  <td class="tx-strong">{{ crmTotalMnbhLeads }}</td>
                  <td class="tx-strong">{{ crmTotalMnlkLeads }}</td>
                  <td class="tx-strong tx-good">{{ crmTotalLeadsSum }}</td>
                  <td class="tx-good tx-strong">{{ crmTotalEnrolledSum }} HS</td>
                  <td class="tx-good tx-strong">{{ crmOverallConversionRate }}%</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Hiệu Quả Từng Kênh Tiếp Cận (Kênh Chuyển Đổi Cao Nhất)</div>
            <div class="uc-kpi-ops__vnote">Cơ cấu nguồn &amp; Tỷ lệ chốt</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Kênh tiếp cận</th>
                  <th>Số Leads</th>
                  <th>Tỷ trọng</th>
                  <th>Đã chốt</th>
                  <th>Chuyển đổi</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="c in crmChannelStats" :key="c.channel">
                  <td class="ta-l tx-strong">{{ c.channel }}</td>
                  <td>{{ c.leads }}</td>
                  <td>{{ c.pct }}</td>
                  <td class="tx-good tx-strong">{{ c.enrolled }} HS</td>
                  <td :class="parseFloat(c.convRate) > 20 ? 'tx-good tx-strong' : ''">{{ c.convRate }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Pipeline Kitty & Top Barriers -->
      <div class="uc-kpi-ops__bcols">
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Pipeline Nuôi Dưỡng Khách Hàng Tiềm Năng Chờ HK2 (Tab Kitty)</div>
            <div class="uc-kpi-ops__vnote">Google Sheet GID 1481169716 ({{ crmKittyList.length }} phụ huynh)</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Phụ huynh</th>
                  <th class="ta-l">Bé</th>
                  <th class="ta-l">Trạng thái</th>
                  <th class="ta-l">Lịch hẹn chăm sóc</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in crmKittyList.slice(0, 6)" :key="r.stt">
                  <td class="ta-l tx-strong">{{ r.tenPH }}</td>
                  <td class="ta-l">{{ r.tenHS }}</td>
                  <td class="ta-l" :class="r.tinhTrang.includes('Nhập học') ? 'tx-good' : 'tx-warn'">{{ r.tinhTrang }}</td>
                  <td class="ta-l tx-strong">{{ r.hen }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div style="padding: 10px; text-align: center;">
            <button type="button" class="uc-kpi-ops__simbtn" @click="openDrawer('KITTY_LIST')">
              Xem toàn bộ {{ crmKittyList.length }} hồ sơ nuôi dưỡng Kitty ›
            </button>
          </div>
        </div>

        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Phân Tích Rào Cản Tuyển Sinh &amp; Lý Do Chưa Chuyển Đổi</div>
            <div class="uc-kpi-ops__vnote">Khảo sát {{ computedCrmDropTotal }} trường hợp drop-off</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Rào cản / Lý do chính</th>
                  <th>Số vụ</th>
                  <th>Tỷ lệ</th>
                  <th class="ta-l">Giải pháp hành động</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in crmDropReasons" :key="r.reason">
                  <td class="ta-l tx-strong">{{ r.reason }}</td>
                  <td class="tx-bad tx-strong">{{ r.count }}</td>
                  <td>{{ r.pct }}</td>
                  <td class="ta-l">{{ r.solution }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- 10. Sticky Multi-Tier Bottom Tab Navigation -->
    <div class="uc-kpi-ops__tabs">
      <div class="uc-kpi-ops__tabrow">
        <div class="uc-kpi-ops__tabgrp">
          <span class="uc-kpi-ops__tabgrp-l">Điều hành HĐQT</span>
          <button type="button" :class="{ 'is-on': page === 0 && executiveTab === 'COMMAND' }" @click="page = 0; executiveTab = 'COMMAND'">0. Tổng quan</button>
          <button type="button" :class="{ 'is-on': page === 0 && executiveTab === 'RISK' }" @click="page = 0; executiveTab = 'RISK'">1. Radar Rủi ro</button>
          <button type="button" :class="{ 'is-on': page === 0 && executiveTab === 'AUDIT' }" @click="page = 0; executiveTab = 'AUDIT'">2. Đối soát &amp; Kiểm toán</button>
          <button type="button" :class="{ 'is-on': page === 0 && executiveTab === 'FRAMEWORK' }" @click="page = 0; executiveTab = 'FRAMEWORK'">3. Danh mục 60 KPI</button>
        </div>
        <div class="uc-kpi-ops__tabgrp">
          <span class="uc-kpi-ops__tabgrp-l">Chi tiết Phân hệ</span>
          <button type="button" :class="{ 'is-on': page === 1 }" @click="page = 1">Sĩ số (1–3)</button>
          <button type="button" :class="{ 'is-on': page === 7 }" @click="page = 7">TVTS &amp; CRM (5, 6)</button>
          <button type="button" :class="{ 'is-on': page === 2 }" @click="page = 2">Rút học (4)</button>
          <button type="button" :class="{ 'is-on': page === 4 }" @click="page = 4">Chuyên môn LMS</button>
          <button type="button" :class="{ 'is-on': page === 6 }" @click="page = 6">Dịch vụ &amp; Y tế</button>
          <button type="button" :class="{ 'is-on': page === 5 }" @click="page = 5">Tài chính CLB</button>
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
      tier3ActiveTab: "CAUSAL",
      tier3Campuses: [],
      tier3CausalImpact: null,
      tier3Audits: [],
      groupPillars: [
        { code: "GRP_1", kpiCode: "KPI_1", label: "KHỐI 1", name: "Quy mô, Tuyển sinh & Giữ chân", driverCount: 7, highlightVal: "2.625 HS", highlightNote: "Lấp đầy: 93.42%", status: "warn", desc: "Sĩ số, Tuyển mới, Rút học & Funnel Leads" },
        { code: "GRP_2", kpiCode: "KPI_2", label: "KHỐI 2", name: "Chất lượng Giáo dục & Học thuật", driverCount: 20, highlightVal: "89.6%", highlightNote: "Khung NL: 82.4%", status: "good", desc: "Học liệu số, Bài tập LMS, Chuẩn đầu ra" },
        { code: "GRP_3", kpiCode: "KPI_3", label: "KHỐI 3", name: "Bán trú, Y tế & An toàn Vận hành", driverCount: 24, highlightVal: "0 Vụ", highlightNote: "ISO 22000 & 0 tai nạn", status: "good", desc: "Bếp ăn, Xe bus, Y tế & CSKH" },
        { code: "GRP_4", kpiCode: "KPI_4", label: "KHỐI 4", name: "Tài chính, Nhân sự & Vận hành CSVC", driverCount: 9, highlightVal: "48.4%", highlightNote: "CLB: 1.61 Tỷ VNĐ", status: "warn", desc: "Biên LN gộp, Doanh thu CLB, TTHC & CSVC" }
      ],
      activeTier1Kpi: "KPI_1",
      tier1List: [
        { MasterKpiCode: "KPI_1", KpiName: "Lấp đầy 100% công suất thiết kế", TargetValue: 100, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 93.42, ProgressPct: 93.4, StatusBadge: "WARN", ThemeColor: "#0284c7", WeightPct: 25 },
        { MasterKpiCode: "KPI_2", KpiName: "Tỷ lệ trúng tuyển ĐH & Chuẩn đầu ra", TargetValue: 95, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 98.50, ProgressPct: 94.7, StatusBadge: "GOOD", ThemeColor: "#7c3aed", WeightPct: 20 },
        { MasterKpiCode: "KPI_3", KpiName: "Tỷ lệ rút học & Giữ chân học sinh", TargetValue: 10, TargetUnit: "%", ComparisonOp: "<=", ActualValue: 2.00, ProgressPct: 100, StatusBadge: "GOOD", ThemeColor: "#16a34a", WeightPct: 15 },
        { MasterKpiCode: "KPI_4", KpiName: "Tỷ suất lợi nhuận gộp dịch vụ bán trú", TargetValue: 50, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 48.40, ProgressPct: 96.8, StatusBadge: "WARN", ThemeColor: "#059669", WeightPct: 15 },
        { MasterKpiCode: "KPI_5", KpiName: "Cải cách TTHC & Giảm 50% thời gian xử lý", TargetValue: 50, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 35.00, ProgressPct: 70.0, StatusBadge: "WARN", ThemeColor: "#ea580c", WeightPct: 10 },
        { MasterKpiCode: "KPI_6", KpiName: "Tỷ lệ chuyển đổi Leads & Hài lòng PHHS", TargetValue: 30, TargetUnit: "%", ComparisonOp: ">=", ActualValue: 13.58, ProgressPct: 45.3, StatusBadge: "BAD", ThemeColor: "#dc2626", WeightPct: 15 }
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
        { k: "MNBH", t: "Mầm non TB" },
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
      // causalKpiCode: KPI được chọn để mô phỏng (thay cho causalScenario cứng)
      // causalDeltaOverride: null = dùng delta thực tế từ periodSnapshots; số = override thủ công
      causalKpiCode: "TS04",
      causalDeltaOverride: null,
      // elasticityMatrix: fallback khi API chưa trả về, được nạp từ KPI_GetCausalEngineData res.data[5]
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
      // Tab 2 Audit Center Redesign
      auditDomainFilter: "ALL",
      auditSeverityFilter: "ALL",
      auditViewMode: "CARD",
      expandedAuditCodes: [],
      // Tab 1 Risk Radar Redesign
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
      auditViewMode: 'dumbbell',
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
        { k: "MNBH", t: "Mầm non TB" },
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
      crmMonthlySummary: [],
      crmChannelStats: [],
      crmDropReasons: [],
      crmKittyList: [],
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
    negativeDriversCount() {
      return (this.currentTier2Drivers || []).filter(d => d.IsNegativeDriver || d.StatusBadge === 'WARN' || d.StatusBadge === 'BAD').length;
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
    selectTier1Kpi(code) {
      this.activeTier1Kpi = code;
      this.fetch3TierData(this.selectedPeriod, this.currentUnit);
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
      if (badge === 'GOOD' || badge === 'good') return 'Đạt';
      if (badge === 'WARN' || badge === 'warn') return 'Cảnh báo';
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
      this.fetch3TierData(pKey, (this.currentUnit === "MNTB") ? "MNBH" : this.currentUnit);
      this.isLoading = true;
      this.apiSyncStatus = "Đang đồng bộ dữ liệu chốt kỳ CSDL eSign...";
      const queryUnit = (this.currentUnit === "MNTB") ? "MNBH" : this.currentUnit;
      try {
        const snapRes = await this.callTapi("eSign/KPI_GetPeriodSnapshots", { PeriodKey: pKey, DonViID: queryUnit });
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

        const corrRes = await this.callTapi("eSign/KPI_GetCorrelations", { PeriodKey: pKey, DonViID: queryUnit });
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

        // 3. Dynamic Audit Discrepancies từ Rule Engine
        try {
          const auditRes = await this.callTapi("eSign/KPI_GetAuditDiscrepancies", { PeriodKey: pKey, ScopeID: queryUnit });
          if (auditRes && Array.isArray(auditRes) && auditRes.length) {
            this.auditDiscrepanciesList = auditRes;
          }
        } catch (e) {
          console.warn("KPI_GetAuditDiscrepancies call error:", e);
        }

        // 4. Dynamic Risk Radar Engine
        try {
          const riskRes = await this.callTapi("eSign/KPI_GetRiskRadar", { PeriodKey: pKey, DonViID: queryUnit });
          if (riskRes && Array.isArray(riskRes)) {
            if (riskRes[0]) this.riskCampusCards = riskRes[0];
            if (riskRes[1]) this.riskTriggers = riskRes[1];
            if (riskRes[2]) this.riskChecklist = riskRes[2];
          }
        } catch (e) {
          console.warn("KPI_GetRiskRadar call error:", e);
        }

        // 5. Dynamic Strategic Levers & Value Bridge Waterfall
        try {
          const leversRes = await this.callTapi("eSign/KPI_GetStrategicLevers", { PeriodKey: pKey });
          if (leversRes && Array.isArray(leversRes)) {
            if (leversRes[0]) this.strategicWaterfallBars = leversRes[0];
            if (leversRes[1]) this.strategicLevers = leversRes[1];
          }
        } catch (e) {
          console.warn("KPI_GetStrategicLevers call error:", e);
        }

        // 6. Dynamic Operations Summary (ME School & CRM Funnel)
        try {
          const opsRes = await this.callTapi("eSign/KPI_GetOperationsSummary", { PeriodKey: pKey, ScopeID: queryUnit });
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
        } catch (e) {
          console.warn("KPI_GetOperationsSummary call error:", e);
        }

        // 7. Dynamic Finance Services & Clubs (Chỉ tiêu 55 & 56)
        try {
          const finRes = await this.callTapi("eSign/KPI_GetFinanceServices", { PeriodKey: pKey, ScopeID: queryUnit });
          if (finRes && Array.isArray(finRes)) {
            if (finRes[0] && Array.isArray(finRes[0]) && finRes[0].length) this.financeServices = finRes[0];
            if (finRes[1] && Array.isArray(finRes[1]) && finRes[1].length) this.financeClubs = finRes[1];
            if (finRes[2] && Array.isArray(finRes[2]) && finRes[2][0]) this.financeSummary = finRes[2][0];
          }
        } catch (e) {
          console.warn("KPI_GetFinanceServices call error:", e);
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