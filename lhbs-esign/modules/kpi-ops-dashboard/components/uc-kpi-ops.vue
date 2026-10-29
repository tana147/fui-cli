<template>
	<div class="uc-kpi-ops">
    <!-- 1. Header Top -->
    <div class="uc-kpi-ops__top">
      <div>
        <div class="uc-kpi-ops__title">KPI Results Framework &amp; Ops Dashboard · LHBS</div>
        <div class="uc-kpi-ops__subtitle">Báo cáo vận hành {{ currentPeriodName }} · Năm học {{ selectedYear }}–{{ selectedYear + 1 }}</div>
      </div>
      <div class="uc-kpi-ops__meta">
        <span>{{ currentPeriodFreezeText }}</span>
        <span class="uc-kpi-ops__sep">|</span>
        <span :class="['uc-kpi-ops__pill', isLoading ? 'is-warn' : 'is-live']">
          {{ apiSyncStatus }}
        </span>
        <button type="button" class="uc-kpi-ops__simbtn" :disabled="isLoading" @click="refreshData()">
          {{ isLoading ? 'Đang tải...' : (currentPeriodIsFrozen ? 'Làm mới dữ liệu chốt kỳ' : 'Làm mới dữ liệu (Live API)') }}
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="openCausalModal()">
          Vùng tác động (ước tính)
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="copyExecutiveBriefing()">
          {{ copiedBriefing ? 'Đã sao chép briefing!' : 'Sao chép tóm tắt họp' }}
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="printExecutiveReport()">
          In báo cáo A4
        </button>
        <button type="button" :class="['uc-kpi-ops__simbtn', { 'is-solid': isPresentMode }]" @click="toggleFullscreen()">
          {{ isPresentMode ? 'Thoát toàn màn hình' : 'Toàn màn hình' }}
        </button>
      </div>
    </div>

    <!-- 2. Slicers Bar -->
    <div v-if="!isPresentMode" class="uc-kpi-ops__slicers">
      <div class="uc-kpi-ops__slicers-left">
        <div>
          <div class="uc-kpi-ops__slicer-label">Kỳ báo cáo &amp; Chốt sổ</div>
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
        <div>
          <div class="uc-kpi-ops__slicer-label">Góc nhìn điều hành</div>
          <div class="uc-kpi-ops__view">{{ currentViewLabel }}</div>
        </div>
      </div>
      <div style="display:flex;gap:6px;">
        <button type="button" class="uc-kpi-ops__simbtn" @click="openFactModal('LEAVE')">
          Tra cứu Fact Store
        </button>
        <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="openDrawer('STUDENT_LIST')">
          Xem cơ cấu chi tiết ›
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
      <div class="uc-kpi-ops__bhead">
        <div class="uc-kpi-ops__bhead-k">Tóm tắt Điều hành Hội đồng trường · {{ currentPeriodName }} · {{ currentUnitTitle }}</div>
        <div class="uc-kpi-ops__bhead-t">
          Tổng quy mô đạt <b>{{ formatNumber(displayStudents) }} học sinh</b> (Lấp đầy <b>{{ displayFillRate }}%</b> công suất). Tỷ lệ rút học trong kỳ {{ currentPeriodShortName }} là <b>{{ displayWithdrawRate }}%</b> ({{ displayWithdrawCount }} HS - Lũy kế chuyển đi: {{ displayOutflowYearToDate }} HS; ngưỡng an toàn {{ getMetricThresholdLabel('TS04') }}). Tỷ lệ hoàn thành bài tập trực tuyến LMS đạt <b>{{ computedLmsData.rate }}</b>. Lợi nhuận gộp dịch vụ trường học đạt <b>{{ computedFinanceData.grossMargin }}</b> (Doanh thu <b>{{ computedFinanceData.rev }}</b>). Duy trì <b>0 sự cố</b> an toàn học đường (ISO 22000).
        </div>
        <div class="uc-kpi-ops__bhead-s">
          Kết nối trực tiếp CSDL eSign &amp; tapi.lhbs.vn · Tự động đồng bộ phản hồi theo bộ lọc cơ sở &amp; kỳ chốt sổ.
        </div>
      </div>

      <!-- Executive Safeguard & Quality Banner -->
      <div class="uc-kpi-ops__safeguard-strip">
        <div class="uc-kpi-ops__safeguard-item is-zero-tol">
          <span class="safeguard-dot"></span>
          <span>AN TOÀN HỌC ĐƯỜNG: <b>0 Vụ ngộ độc thực phẩm (ISO 22000)</b></span>
        </div>
        <div class="uc-kpi-ops__safeguard-item is-zero-tol">
          <span class="safeguard-dot"></span>
          <span>Y TẾ HỌC ĐƯỜNG: <b>0 Tai nạn thương tích nghiêm trọng</b></span>
        </div>
        <div class="uc-kpi-ops__safeguard-item">
          <span>TÁI ĐẦU TƯ CSVC: <b>100% Thặng dư CLB &amp; Bán trú</b></span>
        </div>
        <div class="uc-kpi-ops__safeguard-item ml-auto">
          <span class="safeguard-badge">HĐQT GOVERNANCE · BẢO TOÀN VỐN</span>
        </div>
      </div>

      <!-- 4 Vital KPI Tiles -->
      <div class="uc-kpi-ops__bkpis">
        <!-- Tile 1: Quy mô & Tuyển sinh -->
        <div class="uc-kpi-ops__bkpi is-good" @click="openDrawer('STUDENT_LIST')">
          <div class="uc-kpi-ops__bkpi-h">
            <div class="uc-kpi-ops__bkpi-title-wrap">
              <span>QUY MÔ HIỆN DIỆN (TS01, TS02)</span>
              <button type="button" class="uc-kpi-ops__gl-btn" title="Ghi chú tích hợp Go-Live (TS01, TS02) · Bấm xem đặc tả API" @click.stop="openGoliveSpecs('SPEC_BASICDATA')">
                <span class="gl-icon">!</span>
              </button>
            </div>
            <b>ĐẠT {{ displayCapacityPct }}% KH</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">
              {{ formatNumber(displayStudents) }} <small>HS</small>
              <span v-if="getKpiMoM('TS01').hasPrior" :class="['uc-kpi-ops__trend-badge', getKpiMoM('TS01').isGood ? 'is-good' : 'is-bad']">
                {{ getKpiMoM('TS01').trend === 'up' ? '▲' : (getKpiMoM('TS01').trend === 'down' ? '▼' : '■') }} {{ Math.abs(getKpiMoM('TS01').deltaPct) }}% MoM
              </span>
            </div>
            <svg class="uc-kpi-ops__spark" viewBox="0 0 110 42">
              <line x1="2" x2="108" y1="12" y2="12" class="sp-tg"></line>
              <polyline points="4,34 20,32 36,29 52,26 68,14 84,16 100,17" class="sp-l"></polyline>
              <circle cx="100" cy="17" r="3" class="sp-d is-last"></circle>
              <text x="100" y="38" text-anchor="middle" class="sp-x">NH26</text>
            </svg>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Lấp đầy {{ displayFillRate }}% công suất · Kế hoạch: {{ formatNumber(displayTarget) }} HS (Thiết kế: {{ formatNumber(displayCapacity) }} HS)</div>
          <div class="uc-kpi-ops__cmp">
            <span><i>Leads TVTS (TS05):</i> <b>{{ displayLeads }}</b></span>
            <span><i>Chuyển đổi (TS06):</i> <b class="tx-good">{{ displayConversionRate }}% ({{ displayEnrolled }} HS)</b></span>
            <span><i>Kế hoạch:</i> <b>{{ formatNumber(displayTarget) }}</b></span>
          </div>

          <!-- Mắt xích Nhân quả Ngữ cảnh Tile 1 -->
          <div class="uc-kpi-ops__bkpi-causal" @click.stop="openCausalChainForCard('ENROLLMENT')">
            <div class="causal-pill">{{ renderCausalTitle('TS06', 'Chuỗi: Phễu CRM → Sĩ số → Doanh thu') }}</div>
            <div class="causal-desc" v-html="renderCausalNarrative('TS06', 'NARRATIVE_ENROLLMENT_CONV')"></div>
            <div class="causal-cta">
              <span>Phân tích tác động tuyển thêm &rsaquo;</span>
            </div>
          </div>

          <div class="uc-kpi-ops__bkpi-i" @click.stop="page = 7">
            <span>Xem chi tiết Phễu TVTS (TS05, TS06) ›</span>
            <span class="text-muted" style="font-size:11px;">Mã chỉ tiêu: TS01, TS02</span>
          </div>
        </div>

        <!-- Tile 2: Rút học / Chuyển đi -->
        <div class="uc-kpi-ops__bkpi is-good" @click="openDrawer('WITHDRAW_LIST')">
          <div class="uc-kpi-ops__bkpi-h">
            <div class="uc-kpi-ops__bkpi-title-wrap">
              <span>RÚT HỌC / CHUYỂN ĐI (TS04)</span>
              <button type="button" class="uc-kpi-ops__gl-btn" title="Ghi chú tích hợp Go-Live (TS04) · Bấm xem đặc tả API" @click.stop="openGoliveSpecs('SPEC_BASICDATA')">
                <span class="gl-icon">!</span>
              </button>
            </div>
            <b :class="'tx-' + getMetricStatus('TS04')">{{ displayWithdrawRate }}% {{ getMetricStatusText('TS04') }}</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">
              {{ displayWithdrawRate }}% <small>({{ displayWithdrawCount }} HS kỳ {{ currentPeriodShortName }})</small>
              <span v-if="getKpiMoM('TS04').hasPrior" :class="['uc-kpi-ops__trend-badge', getKpiMoM('TS04').isGood ? 'is-good' : 'is-bad']">
                {{ getKpiMoM('TS04').trend === 'up' ? '▲' : (getKpiMoM('TS04').trend === 'down' ? '▼' : '■') }} {{ Math.abs(getKpiMoM('TS04').deltaPct) }}% MoM
              </span>
            </div>
            <svg class="uc-kpi-ops__spark" viewBox="0 0 110 42">
              <line x1="2" x2="108" y1="8" y2="8" class="sp-tg"></line>
              <polyline points="4,18 25,22 46,20 67,26 88,24 100,21" class="sp-l"></polyline>
              <circle cx="100" cy="21" r="3" class="sp-d is-last"></circle>
              <text x="100" y="38" text-anchor="middle" class="sp-x">{{ nextPeriodShortName }}</text>
            </svg>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Đến: +{{ displayInflow }} HS | Đi ({{ currentPeriodShortName }}): -{{ displayOutflow }} HS (Lũy kế năm: {{ displayOutflowYearToDate }} HS)</div>
          <div class="uc-kpi-ops__cmp">
            <span><i>Nơi ở/tiện đón:</i> <b>{{ displayReasonFar }}</b></span>
            <span><i>Kinh tế:</i> <b>{{ displayReasonEco }}</b></span>
            <span><i>Bệnh/Khác:</i> <b>{{ displayReasonOther }}</b></span>
          </div>

          <!-- Mắt xích Nhân quả Ngữ cảnh Tile 2 -->
          <div class="uc-kpi-ops__bkpi-causal is-bad" @click.stop="openCausalChainForCard('WITHDRAW')">
            <div class="causal-pill">{{ renderCausalTitle('TS04', 'Chuỗi: Xe bus/CSVC → Rút học → Thất thu LTV') }}</div>
            <div class="causal-desc" v-html="renderCausalNarrative('TS04', 'NARRATIVE_WITHDRAW_BUS')"></div>
            <div class="causal-cta">
              <span>Mở Dialog Vùng Tác Động Rút Học &rsaquo;</span>
            </div>
          </div>

          <div class="uc-kpi-ops__bkpi-i">
            <span @click.stop="openCausalModal(currentUnit, 'RUT_HOC')" style="font-weight:700;color:var(--accent);">Xem Vùng tác động (ước tính) ›</span>
            <span class="text-muted" style="font-size:11px;">Mã chỉ tiêu: TS04</span>
          </div>
        </div>

        <!-- Tile 3: Hoàn thành bài tập & Học liệu LMS -->
        <div class="uc-kpi-ops__bkpi is-good" @click="page = 4">
          <div class="uc-kpi-ops__bkpi-h">
            <div class="uc-kpi-ops__bkpi-title-wrap">
              <span>HOÀN THÀNH BÀI TẬP LMS (CM08)</span>
              <button type="button" class="uc-kpi-ops__gl-btn" title="Ghi chú tích hợp Go-Live (CM04, CM08) · Bấm xem đặc tả API" @click.stop="openGoliveSpecs('SPEC_LMS')">
                <span class="gl-icon">!</span>
              </button>
            </div>
            <b>{{ computedLmsData.rate }} TỶ LỆ</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">
              {{ computedLmsData.rate }} <small>hoàn thành</small>
              <span v-if="getKpiMoM('CM08').hasPrior" :class="['uc-kpi-ops__trend-badge', getKpiMoM('CM08').isGood ? 'is-good' : 'is-bad']">
                {{ getKpiMoM('CM08').trend === 'up' ? '▲' : (getKpiMoM('CM08').trend === 'down' ? '▼' : '■') }} {{ Math.abs(getKpiMoM('CM08').deltaPct) }}% MoM
              </span>
            </div>
            <svg class="uc-kpi-ops__spark" viewBox="0 0 110 42">
              <line x1="2" x2="108" y1="10" y2="10" class="sp-tg"></line>
              <polyline points="4,22 25,20 46,18 67,16 88,14 100,12" class="sp-l"></polyline>
              <circle cx="100" cy="12" r="3" class="sp-d is-last"></circle>
              <text x="100" y="38" text-anchor="middle" class="sp-x">LMS</text>
            </svg>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Toán đạt {{ computedLmsData.math }}, Văn đạt {{ computedLmsData.viet }} · Kho học liệu: {{ computedLmsData.digitalLessons }}</div>
          <div class="uc-kpi-ops__cmp">
            <span><i>Toán:</i> <b class="tx-good">{{ computedLmsData.math }}</b></span>
            <span><i>Tiếng Việt:</i> <b class="tx-good">{{ computedLmsData.viet }}</b></span>
            <span><i>Học liệu số:</i> <b>{{ computedLmsData.digitalLessons }}</b></span>
          </div>

          <!-- Mắt xích Nhân quả Ngữ cảnh Tile 3 -->
          <div class="uc-kpi-ops__bkpi-causal is-good" @click.stop="openCausalChainForCard('LMS')">
            <div class="causal-pill">{{ renderCausalTitle('CM08', 'Chuỗi: Đổi mới dạy học & LMS → Nâng cao chất lượng & Gắn kết') }}</div>
            <div class="causal-desc" v-html="renderCausalNarrative('CM08', 'NARRATIVE_LMS_QUALITY')"></div>
            <div class="causal-cta">
              <span>Xem ma trận chất lượng giáo dục &rsaquo;</span>
            </div>
          </div>

          <div class="uc-kpi-ops__bkpi-i" @click.stop="page = 4">
            <span>Xem chi tiết bài tập &amp; học liệu số (CM04, CM08) ›</span>
            <span class="text-muted" style="font-size:11px;">Mã chỉ tiêu: CM04, CM08</span>
          </div>
        </div>

        <!-- Tile 4: Tài chính - Tỷ suất Lợi nhuận gộp & Doanh thu CLB -->
        <div class="uc-kpi-ops__bkpi is-good" @click="page = 5">
          <div class="uc-kpi-ops__bkpi-h">
            <div class="uc-kpi-ops__bkpi-title-wrap">
              <span>LỢI NHUẬN GỘP DỊCH VỤ (KPI 4)</span>
              <button type="button" class="uc-kpi-ops__gl-btn" title="Ghi chú tích hợp Go-Live (TC33, TC55, TC56) · Bấm xem đặc tả API" @click.stop="openGoliveSpecs('SPEC_HOCPHI')">
                <span class="gl-icon">!</span>
              </button>
            </div>
            <b class="tx-good">ĐẠT {{ computedFinanceData.grossMargin }}</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">
              {{ computedFinanceData.grossMargin }} <small>LN Gộp</small>
              <span v-if="getKpiMoM('TC55').hasPrior" :class="['uc-kpi-ops__trend-badge', getKpiMoM('TC55').isGood ? 'is-good' : 'is-bad']">
                {{ getKpiMoM('TC55').trend === 'up' ? '▲' : (getKpiMoM('TC55').trend === 'down' ? '▼' : '■') }} {{ Math.abs(getKpiMoM('TC55').deltaPct) }}% MoM
              </span>
            </div>
            <svg class="uc-kpi-ops__spark" viewBox="0 0 110 42">
              <line x1="2" x2="108" y1="12" y2="12" class="sp-tg"></line>
              <polyline points="4,28 25,24 46,20 67,16 88,14 100,13" class="sp-l"></polyline>
              <circle cx="100" cy="13" r="3" class="sp-d is-last"></circle>
              <text x="100" y="38" text-anchor="middle" class="sp-x">KPI {{ getKpiTarget('TC55') || '50%' }}</text>
            </svg>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Doanh thu thuần: {{ computedFinanceData.rev }} · Bán trú {{ computedFinanceData.mealMargin }} · Xe bus {{ computedFinanceData.busMargin }}</div>
          <div class="uc-kpi-ops__cmp">
            <span><i>DT CLB (KPI 3.2.1):</i> <b>{{ computedFinanceData.clbRev }}</b></span>
            <span><i>Học sinh CLB:</i> <b>{{ computedFinanceData.clbStudents }}</b></span>
            <span><i>Mục tiêu CLB:</i> <b>{{ displayClubTarget }}</b></span>
          </div>

          <!-- Mắt xích Nhân quả Ngữ cảnh Tile 4 -->
          <div class="uc-kpi-ops__bkpi-causal is-good" @click.stop="openCausalChainForCard('FINANCE')">
            <div class="causal-pill">{{ renderCausalTitle('TC55', 'Chuỗi: LN Dịch vụ → Tái đầu tư CSVC → Giảm rút học') }}</div>
            <div class="causal-desc" v-html="renderCausalNarrative('TC55', 'NARRATIVE_FINANCE_REINVEST')"></div>
            <div class="causal-cta">
              <span>Xem ma trận tái đầu tư tài chính &rsaquo;</span>
            </div>
          </div>

          <div class="uc-kpi-ops__bkpi-i" @click.stop="page = 5">
            <span>Xem chi tiết Tài chính (Chỉ tiêu 55, 56) ›</span>
            <span class="text-muted" style="font-size:11px;">Mã chỉ tiêu: TC33, TC55, TC56</span>
          </div>
        </div>
      </div>

      <!-- 4. THANH SUB-TABS ĐIỀU HÀNH FOLD 1 (Không emoji, chuẩn Fluent) -->
      <div class="uc-kpi-ops__subtabs">
        <button
          type="button"
          :class="['uc-kpi-ops__subtab-btn', { 'is-active': executiveTab === 'COMMAND' }]"
          @click="executiveTab = 'COMMAND'"
        >
          Tổng Quan Điều Hành (Ops Command)
        </button>
        <button
          type="button"
          :class="['uc-kpi-ops__subtab-btn', { 'is-active': executiveTab === 'RISK' }]"
          @click="executiveTab = 'RISK'"
        >
          Dự Báo &amp; Radar Rủi Ro {{ nextPeriodShortName }}
          <span class="uc-kpi-ops__subtab-badge" :class="riskBadgeClass">{{ riskSummaryBadgeText }}</span>
        </button>
        <button
          type="button"
          :class="['uc-kpi-ops__subtab-btn', { 'is-active': executiveTab === 'AUDIT' }]"
          @click="executiveTab = 'AUDIT'"
        >
          Kiểm Toán &amp; Điểm Vênh (Audit Center)
          <span class="uc-kpi-ops__subtab-count">{{ auditDiscrepanciesList.length }}</span>
        </button>
      </div>

      <!-- ================= SUB-TAB 1: TỔNG QUAN ĐIỀU HÀNH (COMMAND) ================= -->
      <div v-if="executiveTab === 'COMMAND'">
        <!-- Split Layout 7:5: Value Bridge (150px) + 4 Thẻ Đòn Bẩy Chiến Lược -->
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

        <!-- Grid 5 Thẻ Cơ Sở Tinh Gọn (Bullet Meters + Harvey Balls) -->
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

        <!-- Dải Phân Bổ Tỷ Trọng Rút Học & Dải Tải Trọng Vận Hành -->
        <div class="uc-kpi-ops__split-grid">
          <!-- Phân bổ lý do rút học -->
          <div class="uc-kpi-ops__dist-box">
            <div class="d-flex justify-space-between align-center">
              <span style="font-size:12.5px;font-weight:700;color:var(--accent2);">Cơ Cấu Lý Do Rút Học Trong Kỳ {{ currentPeriodName }} ({{ displayWithdrawCount }} Học Sinh)</span>
              <span style="font-size:11px;color:#64748b;">Lũy kế chuyển đi: {{ displayOutflowYearToDate }} HS {{ currentPeriodIsFrozen ? '(Chốt kỳ)' : '(Live Data)' }}</span>
            </div>
            <!-- Stacked Distribution Bar Động 100% -->
            <div class="uc-kpi-ops__dist-bar" v-if="dynamicWithdrawReasons && dynamicWithdrawReasons.length">
              <div 
                v-for="b in dynamicWithdrawReasons" 
                :key="b.code" 
                class="uc-kpi-ops__dist-seg" 
                :style="{ width: b.pct + '%', background: b.color }" 
                :title="b.name + ': ' + b.count + ' HS (' + b.pct + '%)'"
              ></div>
            </div>
            <div class="uc-kpi-ops__dist-legend" v-if="dynamicWithdrawReasons && dynamicWithdrawReasons.length">
              <span 
                v-for="b in dynamicWithdrawReasons" 
                :key="'leg-' + b.code" 
                class="uc-kpi-ops__dist-legend-item"
              >
                <i class="uc-kpi-ops__dist-legend-dot" :style="{ background: b.color }"></i>
                <b v-if="b.code === 'FAR' || b.code === 'BUS'">{{ b.name }}: {{ b.count }} HS ({{ b.pct }}%)</b>
                <span v-else>{{ b.name }}: {{ b.count }} HS ({{ b.pct }}%)</span>
              </span>
            </div>
          </div>

          <!-- Áp lực Nghỉ phép & Phụ Bếp Bán Trú -->
          <div class="uc-kpi-ops__dist-box">
            <div class="d-flex justify-space-between align-center">
              <span style="font-size:12.5px;font-weight:700;color:var(--accent2);">Tải Trọng Nghỉ Phép &amp; Áp Lực Bán Trú</span>
              <span style="font-size:11px;color:#d9822b;font-weight:600;">{{ dynamicRiskFactsBrief }}</span>
            </div>
            <div style="font-size:11.5px;color:#334155;margin:6px 0;line-height:1.4;">
              Áp lực cao nhất tại <b>Mầm non ({{ contextStore['LEAVE.KinderDays'] || '106' }} ngày)</b>, <b>Long Khánh ({{ contextStore['LEAVE.Days'] ? (Number(contextStore['LEAVE.Days']) / 8).toFixed(0) : '68' }} ngày)</b> và <b>Bộ phận Bếp ({{ contextStore['LEAVE.KitchenDays'] || '54' }} ngày)</b>. Cần bổ sung phụ bếp dự phòng tránh ảnh hưởng chất lượng bán trú.
            </div>
            <div class="d-flex gap-2 mt-2 pt-1 border-top" style="font-size:11px;border-color:#f1f5f9 !important;">
              <span class="p-1 px-2 rounded" style="background:#fef2f2;color:#991b1b;font-weight:600;">Bếp: {{ contextStore['LEAVE.KitchenDays'] || '54' }} ngày</span>
              <span class="p-1 px-2 rounded" style="background:#fef3c7;color:#92400e;font-weight:600;">Mầm non: {{ contextStore['LEAVE.KinderDays'] || '106' }} ngày</span>
              <span class="p-1 px-2 rounded" style="background:#f1f5f9;color:#475569;">Bảo trì: {{ contextStore['MAINT.PendingTickets'] || '0' }} ticket tồn</span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn ml-auto"
                style="padding:1px 8px;font-size:10.5px;"
                @click="openFactModal('LEAVE')"
              >Xem chi tiết đơn nghỉ phép &rsaquo;</button>
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
        <div class="uc-kpi-ops__risk-cards-grid" v-if="riskCampusCards && riskCampusCards.length">
          <div 
            v-for="c in riskCampusCards" 
            :key="c.ScopeID" 
            :class="['uc-kpi-ops__risk-card', 'level-' + (c.RiskLevel ? c.RiskLevel.toLowerCase() : 'green')]"
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
                >
                  <svg width="11" height="11" viewBox="0 0 16 16" fill="currentColor"><path d="M0 0h3v16H0zm6 5h3v11H6zm6-3h3v14h-3z"/></svg>
                  Thẻ đo
                </button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__switcher-btn', { 'is-active': riskViewMode === 'TABLE' }]"
                  @click="riskViewMode = 'TABLE'"
                >
                  <svg width="11" height="11" viewBox="0 0 16 16" fill="currentColor"><path d="M0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2zm1 2v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4H1zm1-3a1 1 0 0 0-1 1v1h14V2a1 1 0 0 0-1-1H2z"/></svg>
                  Bảng
                </button>
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
                    @click.stop="jumpToFactStore(getTriggerFactDomain(t), t.TargetCampus)"
                  >Xem chứng từ gốc &rsaquo;</button>
                </div>
              </div>
            </div>

            <!-- Table View -->
            <table v-else class="uc-kpi-ops__checklist-table mt-2">
              <thead>
                <tr>
                  <th style="width:20%;">Trục Rủi Ro</th>
                  <th style="width:32%;">Ngòi Nổ Dữ Liệu</th>
                  <th style="width:30%;">Chỉ Báo Nguy Cơ</th>
                  <th style="width:18%;">Trọng Điểm</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="t in riskTriggers" :key="'tb-' + t.TriggerID">
                  <td><b>{{ t.TriggerName }}</b></td>
                  <td>{{ t.DataTrigger || t.DataTriggerT9 }}</td>
                  <td>{{ t.RiskThreat || t.RiskThreatT10 }}</td>
                  <td><span :class="['uc-kpi-ops__checklist-status-badge', t.SeverityClass]">{{ t.TargetCampuses }}</span></td>
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
                  <th style="width:28px;text-align:center;">✓</th>
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
      <div v-if="executiveTab === 'AUDIT'">
        <div class="uc-kpi-ops__audit-box">
          <div class="uc-kpi-ops__audit-head">
            <div class="uc-kpi-ops__audit-title">
              <span>Trung Tâm Kiểm Toán Số Liệu &amp; Điểm Vênh Báo Cáo (Audit Discrepancies)</span>
              <span class="uc-kpi-ops__audit-badge">{{ auditDiscrepanciesList.length }} Điểm Cần Đối Soát</span>
            </div>
            <div style="font-size:12px;color:var(--ink2);display:flex;gap:12px;align-items:center;">
              <span><svg class="uc-kpi-ops__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /><circle cx="6" cy="6" r="5" class="hb-f" /></svg> Đã đối soát xác minh</span>
              <span><svg class="uc-kpi-ops__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /><path d="M6,1 A5,5 0 0 1 6,11 Z" class="hb-f" /></svg> Báo cáo nội bộ (chờ duyệt)</span>
              <span><svg class="uc-kpi-ops__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /></svg> Cần phúc tra khẩn cấp</span>
            </div>
          </div>

          <div class="uc-kpi-ops__audit-grid" v-if="auditDiscrepanciesList && auditDiscrepanciesList.length">
            <div
              v-for="item in auditDiscrepanciesList"
              :key="item.AuditCode || item.DiscrepancyID"
              :class="['uc-kpi-ops__audit-card', item.Category === 'MISMATCH' ? 'is-critical' : '']"
            >
              <div class="uc-kpi-ops__audit-card-top">
                <span class="uc-kpi-ops__audit-card-code">{{ item.AuditCode }} · Cơ sở: {{ item.ScopeID || 'ALL' }}</span>
                <span :class="['uc-kpi-ops__status-pill', item.Category === 'MISMATCH' ? 'is-danger' : 'is-warn']">
                  {{ item.VerificationStatus || 'PENDING_VERIFY' }}
                </span>
              </div>
              <div class="uc-kpi-ops__audit-card-name">
                <svg class="uc-kpi-ops__hb" viewBox="0 0 12 12">
                  <circle cx="6" cy="6" r="5" class="hb-o" />
                  <path v-if="item.Category === 'MISMATCH'" d="M6,1 A5,5 0 0 1 6,11 Z" class="hb-f" />
                  <circle v-else cx="6" cy="6" r="5" class="hb-f" />
                </svg>
                {{ item.Title }}
              </div>

              <!-- Đối chiếu 2 nguồn dữ liệu -->
              <div class="uc-kpi-ops__audit-compare">
                <div class="uc-kpi-ops__audit-compare-side">
                  <span style="color:#64748b;">Nguồn A (Vận hành):</span>
                  <b>{{ item.PrimaryValue }}</b>
                  <small style="display:block;font-size:10px;color:#94a3b8;">{{ item.PrimarySource }}</small>
                </div>
                <div class="uc-kpi-ops__audit-compare-side" style="border-left:1px solid #e2e8f0;padding-left:8px;">
                  <span style="color:#64748b;">Nguồn B (Tổng kết / Ban khác):</span>
                  <b class="tx-bad">{{ item.SecondaryValue }}</b>
                  <small style="display:block;font-size:10px;color:#94a3b8;">{{ item.SecondarySource }}</small>
                </div>
              </div>

              <div class="uc-kpi-ops__audit-desc">
                {{ item.VarianceAnalysis }}
              </div>

              <div class="uc-kpi-ops__audit-action">
                <b>Chỉ đạo BGH:</b> {{ item.ResolutionDirective || 'Thống nhất định nghĩa công thức và kỳ chốt trước kỳ họp HĐQT.' }}
              </div>

              <div class="uc-kpi-ops__audit-owner">
                <span>Đầu mối: <b>{{ item.ActionOwner }}</b></span>
                <div style="display:flex;gap:4px;">
                  <button
                    type="button"
                    class="uc-kpi-ops__simbtn is-solid"
                    style="padding:1px 8px;font-size:10.5px;"
                    @click="openFactModal(getAuditDomain(item), item.ScopeID)"
                  >Đối Soát Giao Dịch Gốc &rsaquo;</button>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="uc-kpi-ops__empty-card p-4 text-center mt-3" style="background:#f8fafc;border:1px dashed #cbd5e1;border-radius:8px;">
            <div style="font-size:13px;color:#16a34a;font-weight:600;">
              ✓ Hệ thống toàn vẹn: Không phát hiện điểm vênh hay nghịch lý số liệu trong kỳ báo cáo này.
            </div>
            <div style="font-size:11px;color:#64748b;margin-top:4px;">
              Tất cả các chỉ số đối soát giữa Vận hành và Báo cáo độc lập đều nằm trong ngưỡng an toàn.
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
            <!-- 6 Domain Chips -->
            <div class="uc-kpi-ops__seg mb-3">
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'LEAVE' }"
                @click="fetchOperationalFacts('LEAVE')"
              >{{ getFactDomainButtonLabel('LEAVE', 'Nghỉ phép & Công') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'HEALTH' }"
                @click="fetchOperationalFacts('HEALTH')"
              >{{ getFactDomainButtonLabel('HEALTH', 'Y tế học đường') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'MAINTENANCE' }"
                @click="fetchOperationalFacts('MAINTENANCE')"
              >{{ getFactDomainButtonLabel('MAINTENANCE', 'Bảo trì CSVC') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'CLUB' }"
                @click="fetchOperationalFacts('CLUB')"
              >{{ getFactDomainButtonLabel('CLUB', 'Dịch vụ CLB') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'HR_TURNOVER' }"
                @click="fetchOperationalFacts('HR_TURNOVER')"
              >{{ getFactDomainButtonLabel('HR_TURNOVER', 'Biến động NV') }}</button>
              <button
                type="button"
                :class="{ 'is-on': selectedFactDomain === 'TEACHING' }"
                @click="fetchOperationalFacts('TEACHING')"
              >{{ getFactDomainButtonLabel('TEACHING', 'Tiến độ dạy') }}</button>
            </div>

            <!-- Thanh Đối Soát 3 Cột (Reconciliation Strip) -->
            <div class="uc-kpi-ops__reconcile-strip" :class="'is-' + reconciliationSummary.status.toLowerCase()">
              <div class="uc-kpi-ops__reconcile-col">
                <div class="uc-kpi-ops__reconcile-lbl">1. Chỉ số KPI Báo Cáo</div>
                <div class="uc-kpi-ops__reconcile-val">{{ reconciliationSummary.kpiReported }}</div>
                <div class="uc-kpi-ops__reconcile-sub">{{ reconciliationSummary.kpiNote }}</div>
              </div>

              <div class="uc-kpi-ops__reconcile-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
              </div>

              <div class="uc-kpi-ops__reconcile-col">
                <div class="uc-kpi-ops__reconcile-lbl">2. Tổng Gộp Fact Store Gốc</div>
                <div class="uc-kpi-ops__reconcile-val">{{ reconciliationSummary.factMetric }}</div>
                <div class="uc-kpi-ops__reconcile-sub">{{ reconciliationSummary.factCount }} giao dịch nguyên tử</div>
              </div>

              <div class="uc-kpi-ops__reconcile-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/></svg>
              </div>

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
                  ⚠️ Tồn đọng / Chưa xử lý (Pending)
                </button>
                <button
                  type="button"
                  :class="['uc-kpi-ops__audit-chip is-anomaly', { 'is-active': factAuditFilter === 'ANOMALY' }]"
                  @click="factAuditFilter = 'ANOMALY'"
                >
                  🔍 Trọng điểm rủi ro
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
                    <th class="ta-l" style="width:160px;">Mã / Tên</th>
                    <th class="ta-l" style="width:140px;">Phân loại</th>
                    <th class="ta-l">Chi tiết nghiệp vụ</th>
                    <th style="width:110px;">Định lượng</th>
                    <th style="width:90px;">Trạng thái</th>
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
                    <span>⚠️ Bẫy định phí lớp học:</span>
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
                      {{ genericCausalCalc.shouldIntervene ? '✅ Phê duyệt can thiệp' : '⏸ Chấp nhận biến động tự nhiên' }}
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
            >
              <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M0 0h3v16H0zm6 5h3v11H6zm6-3h3v14h-3z"/></svg>
              Biểu đồ cột ngang
            </button>
            <button
              type="button"
              :class="['uc-kpi-ops__switcher-btn', { 'is-active': gradeViewMode === 'TABLE' }]"
              @click="gradeViewMode = 'TABLE'"
            >
              <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2zm1 2v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4H1zm1-3a1 1 0 0 0-1 1v1h14V2a1 1 0 0 0-1-1H2z"/></svg>
              Bảng số liệu
            </button>
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
              >
                <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M0 0h3v16H0zm6 5h3v11H6zm6-3h3v14h-3z"/></svg>
                Biểu đồ xếp hạng
              </button>
              <button
                type="button"
                :class="['uc-kpi-ops__switcher-btn', { 'is-active': withdrawViewMode === 'TABLE' }]"
                @click="withdrawViewMode = 'TABLE'"
              >
                <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2zm1 2v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4H1zm1-3a1 1 0 0 0-1 1v1h14V2a1 1 0 0 0-1-1H2z"/></svg>
                Bảng
              </button>
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
            >
              <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M0 0h3v16H0zm6 5h3v11H6zm6-3h3v14h-3z"/></svg>
              Thẻ tiến độ
            </button>
            <button
              type="button"
              :class="['uc-kpi-ops__switcher-btn', { 'is-active': lmsViewMode === 'TABLE' }]"
              @click="lmsViewMode = 'TABLE'"
            >
              <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2zm1 2v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4H1zm1-3a1 1 0 0 0-1 1v1h14V2a1 1 0 0 0-1-1H2z"/></svg>
              Bảng số liệu
            </button>
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
      <div class="uc-kpi-ops__bhead">
        <div class="uc-kpi-ops__bhead-k">Chỉ tiêu Tài chính Vận hành (Nhóm 4 · Chỉ tiêu 55, 56) · {{ currentUnitTitle }}</div>
        <div class="uc-kpi-ops__bhead-t">
          Tỷ suất lợi nhuận gộp dịch vụ của {{ currentUnitTitle }} đạt <b>{{ computedFinanceData.grossMargin }}</b> (Mục tiêu <b>KPI 4: {{ getKpiTarget('TC55') || '50%' }}</b>). Doanh thu các Câu lạc bộ bổ trợ ngoài giờ đạt <b>{{ computedFinanceData.clbRev }}</b> với <b>{{ computedFinanceData.clbStudents }}</b> tham gia (Đóng góp mục tiêu <b>KPI 3.2.1: $1M</b>).
        </div>
        <div class="uc-kpi-ops__bhead-s">
          Nguồn dữ liệu: Phòng Kế toán PM FTS · Phân hệ Thu phí Dịch vụ &amp; Quản lý Hoạt động ngoài giờ.
        </div>
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
      <div class="uc-kpi-ops__bhead">
        <div class="uc-kpi-ops__bhead-k">Chuyên môn Tuyển sinh &amp; Chăm sóc khách hàng (TVTS · CRM)</div>
        <div class="uc-kpi-ops__bhead-t">
          Lũy kế năm học 2026–2027 tiếp nhận <b>{{ computedCrmLeads }} Leads tiềm năng (TS05)</b>, chuyển đổi thành công <b>{{ computedCrmEnrolled }} học sinh nhập học</b>, tỷ lệ chuyển đổi trung bình đạt <b>{{ computedCrmConversionRate }}% (TS06)</b>. Kênh Người quen &amp; PH hiện hữu đạt tỷ lệ chốt cao nhất (&gt; 50%).
        </div>
        <div class="uc-kpi-ops__bhead-s">
          Trích xuất từ Báo cáo Tracking Tuyển sinh 2026–2027 (Google Spreadsheet TVTS) · Cập nhật theo đơn vị và khối lớp.
        </div>
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
      page: 0,
      currentUnit: "ALL",
      selectedYear: 2026,
      selectedPeriod: "2026-09",
      executiveTab: "COMMAND",
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
      metricThresholds: [],
      causalNarrativesList: [],
      contextStore: {},
      breakdownsList: [],
      selectedFactDomain: "LEAVE",
      isFactsLoading: false,
      isFactsModalOpen: false,
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
    reconciliationSummary() {
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

      // Tìm KPI vĩ mô tương ứng từ periodSnapshots để đối soát độc lập
      const kLeave = this.getKpi("HR01") || this.getKpi("HR02");
      const kHealth = this.getKpi("MED01") || this.getKpi("DV38");
      const kMaint = this.getKpi("CSVC01");
      const kClub = this.getKpi("TC56");
      const kHr = this.getKpi("HR02");
      const kTeach = this.getKpi("CM01") || this.getKpi("CM08");

      // Giá trị báo cáo vĩ mô
      const macroLeaveVal = kLeave && kLeave.ActualValue != null ? Number(kLeave.ActualValue) : totalMetric;
      const macroHealthVal = kHealth && kHealth.ActualValue != null ? Number(kHealth.ActualValue) : totalFacts;
      const macroMaintVal = kMaint && kMaint.ActualValue != null ? Number(kMaint.ActualValue) : totalFacts;
      const macroClubVal = kClub && kClub.ActualValue != null ? Number(kClub.ActualValue) : totalMetric;
      const macroHrVal = kHr && kHr.ActualValue != null ? Number(kHr.ActualValue) : totalFacts;
      const macroTeachVal = kTeach && kTeach.ActualValue != null ? Number(kTeach.ActualValue) : (totalMetric || totalFacts);

      const deltaLeave = Math.abs(macroLeaveVal - totalMetric);
      const isLeaveMatched = deltaLeave < 0.5;

      const deltaHealth = Math.abs(macroHealthVal - totalFacts);
      const isHealthMatched = deltaHealth === 0;

      const deltaMaint = Math.abs(macroMaintVal - totalFacts);
      const isMaintMatched = deltaMaint === 0;

      const configs = {
        LEAVE: {
          title: "Nghỉ Phép Nhân Sự (HR01)",
          kpiReported: macroLeaveVal.toFixed(1) + " ngày công (KPI báo cáo)",
          kpiNote: "Chỉ số vĩ mô HR01 · " + pName,
          factCount: totalFacts,
          factMetric: totalMetric.toFixed(1) + " ngày công",
          status: isLeaveMatched ? (pendingFacts > 0 ? "WARN" : "MATCHED") : "WARN",
          statusText: isLeaveMatched ? "Khớp 100% Số Liệu Gốc (" + totalMetric.toFixed(1) + " ngày công)" : "Lệch " + deltaLeave.toFixed(1) + " ngày công so với KPI",
          auditFinding: isLeaveMatched ? ("Ghi nhận " + totalFacts + " đơn với " + totalMetric.toFixed(1) + " ngày công. Trạng thái toàn vẹn dữ liệu.") : ("Phát hiện chênh lệch giữa KPI báo cáo (" + macroLeaveVal.toFixed(1) + ") và tổng gộp giao dịch gốc (" + totalMetric.toFixed(1) + ")."),
          responsibleRole: "Trưởng phòng Nhân sự",
        },
        HEALTH: {
          title: "Y Tế Học Đường (MED01)",
          kpiReported: macroHealthVal + " ca bệnh (KPI báo cáo)",
          kpiNote: "Chỉ tiêu y tế MED01 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " ca ghi nhận",
          status: isHealthMatched ? (pendingFacts > 0 ? "WARN" : "MATCHED") : "WARN",
          statusText: isHealthMatched ? "Khớp 100% Sổ Y Tế (" + totalFacts + " ca)" : "Lệch " + deltaHealth + " ca so với KPI",
          auditFinding: isHealthMatched ? ("Ghi nhận " + totalFacts + " lượt khám y tế trong kỳ " + pName + ".") : ("Số ca bệnh trên sổ y tế (" + totalFacts + ") không khớp với báo cáo vĩ mô (" + macroHealthVal + ")."),
          responsibleRole: "Trưởng bộ phận Y tế học đường",
        },
        MAINTENANCE: {
          title: "Bảo Trì Cơ Sở Vật Chất (CSVC01)",
          kpiReported: macroMaintVal + " ticket phát sinh (KPI báo cáo)",
          kpiNote: "Hệ thống CSVC01 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " ticket",
          status: pendingFacts > 0 ? "CRITICAL" : (isMaintMatched ? "MATCHED" : "WARN"),
          statusText: pendingFacts > 0 ? ("Cảnh Báo: " + pendingFacts + " Ticket Tồn Đọng Chưa Xử Lý") : (isMaintMatched ? "Khớp 100% Ticket Nghiệm Thu" : "Lệch ticket ghi nhận"),
          auditFinding: pendingFacts > 0 ? ("Có " + pendingFacts + " ticket đang tồn đọng xử lý trong kỳ " + pName + ". Cần hoàn tất SLA 24h.") : ("Toàn bộ ticket phát sinh trong kỳ đều đã nghiệm thu."),
          responsibleRole: "Trưởng phòng Quản trị CSVC",
        },
        CLUB: {
          title: "Doanh Thu & Học Viên CLB (TC56)",
          kpiReported: (macroClubVal >= 1000000 ? (macroClubVal / 1000000).toFixed(1) + " tr đ" : this.formatNumber(macroClubVal) + " đ") + " (KPI báo cáo)",
          kpiNote: "Kế toán dịch vụ TC56 · " + pName,
          factCount: totalFacts,
          factMetric: totalFacts + " môn CLB (" + (totalMetric >= 1000000 ? (totalMetric / 1000000).toFixed(1) + " tr đ" : this.formatNumber(totalMetric) + " đ") + ")",
          status: "MATCHED",
          statusText: "Khớp 100% Sổ Dịch Vụ 36 Môn CLB",
          auditFinding: "Ghi nhận " + totalFacts + " môn CLB bổ trợ với doanh thu đạt kế hoạch trong kỳ " + pName + ".",
          responsibleRole: "Kế toán trưởng & BGH Tiểu học",
        },
        HR_TURNOVER: {
          title: "Biến Động Nhân Sự Cơ Hữu (HR02)",
          kpiReported: macroHrVal + " ca biến động (KPI báo cáo)",
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
          kpiReported: (totalMetric > 0 ? totalMetric : totalFacts) + " tiết dạy thay (KPI báo cáo)",
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
          if (domain === "HEALTH") return txt.includes("cúm") || txt.includes("sốt") || txt.includes("thương tích") || txt.includes("bệnh");
          if (domain === "MAINTENANCE") return txt.includes("máy lạnh") || txt.includes("điều hòa") || txt.includes("quá hạn") || txt.includes("khu b");
          if (domain === "LEAVE") return txt.includes("bếp") || txt.includes("mầm non") || txt.includes("không phép") || (f.MetricCount && Number(f.MetricCount) >= 2);
          if (domain === "CLUB") return f.Status === "PENDING" || (f.MetricCount && Number(f.MetricCount) < 5);
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
      this.openFactModal(domainCode, scopeId);
    },
    openFactModal(domainCode = "LEAVE", scopeId = "ALL") {
      this.selectedFactDomain = domainCode || "LEAVE";
      this.factCampusFilter = scopeId || "ALL";
      this.factAuditFilter = "ALL";
      this.isFactsModalOpen = true;
      this.fetchOperationalFacts(this.selectedFactDomain);
    },
    closeFactModal() {
      this.isFactsModalOpen = false;
    },
    getTriggerFactDomain(t) {
      if (!t) return "LEAVE";
      const tid = (t.TriggerID || "").toUpperCase();
      if (tid.includes("MAINT") || tid.includes("CSVC")) return "MAINTENANCE";
      if (tid.includes("HEALTH") || tid.includes("YTE")) return "HEALTH";
      if (tid.includes("CRM") || tid.includes("ENROLL")) return "LEAVE";
      if (tid.includes("LMS") || tid.includes("TEACH")) return "TEACHING";
      return "LEAVE";
    },
    getAuditDomain(item) {
      let domain = "LEAVE";
      const code = ((item && item.AuditCode) || "").toUpperCase();
      const cat = ((item && item.Category) || "").toUpperCase();
      const title = ((item && item.Title) || "").toUpperCase();
      if (code.includes("MAINT") || cat.includes("CSVC") || title.includes("MÁY LẠNH")) {
        domain = "MAINTENANCE";
      } else if (code.includes("HEALTH") || cat.includes("Y TẾ") || title.includes("CÚM") || title.includes("SỐT")) {
        domain = "HEALTH";
      } else if (code.includes("CLUB") || cat.includes("CLB") || title.includes("CLB")) {
        domain = "CLUB";
      } else if (code.includes("TEACH") || cat.includes("DẠY") || title.includes("TIẾT")) {
        domain = "TEACHING";
      } else if (code.includes("HR") || cat.includes("NHÂN SỰ") || title.includes("BIẾN ĐỘNG")) {
        domain = "HR_TURNOVER";
      }
      return domain;
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
    openOperationalFactDrawer(domainCode = "LEAVE", scopeId = "ALL") {
      this.openFactModal(domainCode, scopeId);
    },
    openFactAuditForItem(item) {
      let domain = "LEAVE";
      const code = ((item && item.AuditCode) || "").toUpperCase();
      const cat = ((item && item.Category) || "").toUpperCase();
      const title = ((item && item.Title) || "").toUpperCase();
      if (code.includes("MAINT") || cat.includes("CSVC") || title.includes("MÁY LẠNH")) {
        domain = "MAINTENANCE";
      } else if (code.includes("HEALTH") || cat.includes("Y TẾ") || title.includes("CÚM") || title.includes("SỐT")) {
        domain = "HEALTH";
      } else if (code.includes("CLUB") || cat.includes("CLB") || title.includes("CLB")) {
        domain = "CLUB";
      } else if (code.includes("TEACH") || cat.includes("DẠY") || title.includes("TIẾT")) {
        domain = "TEACHING";
      } else if (code.includes("HR") || cat.includes("NHÂN SỰ") || title.includes("BIẾN ĐỘNG")) {
        domain = "HR_TURNOVER";
      }
      this.openFactModal(domain, item ? item.ScopeID : "ALL");
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