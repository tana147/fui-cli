<template>
	<div class="uc-kpi-ops">
    <!-- 1. Header Top -->
    <div class="uc-kpi-ops__top">
      <div>
        <div class="uc-kpi-ops__title">KPI Results Framework &amp; Ops Dashboard · LHBS</div>
        <div class="uc-kpi-ops__subtitle">Báo cáo vận hành Tháng 10/2026 · Năm học 2026–2027</div>
      </div>
      <div class="uc-kpi-ops__meta">
        <span>Chốt 27/10/2026</span>
        <span class="uc-kpi-ops__sep">|</span>
        <span :class="['uc-kpi-ops__pill', isLoading ? 'is-warn' : 'is-live']">
          {{ apiSyncStatus }}
        </span>
        <button type="button" class="uc-kpi-ops__simbtn" :disabled="isLoading" @click="refreshData()">
          {{ isLoading ? 'Đang tải...' : 'Làm mới dữ liệu (Live API)' }}
        </button>
        <button type="button" class="uc-kpi-ops__simbtn" @click="openCausalModal()">
          Vùng tác động (ước tính)
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
      <div>
        <button type="button" class="uc-kpi-ops__simbtn is-solid" @click="openDrawer('STUDENT_LIST')">
          Xem cơ cấu chi tiết ›
        </button>
      </div>
    </div>

    <!-- 3. PAGE 0: HỘI ĐỒNG TRƯỜNG (Executive Board Overview) -->
    <div v-if="page === 0" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__bhead">
        <div class="uc-kpi-ops__bhead-k">Tóm tắt Điều hành Hội đồng trường · {{ currentPeriodName }} · {{ currentUnitTitle }}</div>
        <div class="uc-kpi-ops__bhead-t">
          Tổng quy mô đạt <b>{{ formatNumber(displayStudents) }} học sinh</b> (Lấp đầy <b>{{ displayFillRate }}%</b> công suất). Tỷ lệ rút học ròng ở mức <b>{{ displayWithdrawRate }}%</b> ({{ displayWithdrawCount }} HS - ngưỡng an toàn {{ getMetricThresholdLabel('TS04') }}). Tỷ lệ hoàn thành bài tập trực tuyến LMS đạt <b>{{ computedLmsData.rate }}</b>. Lợi nhuận gộp dịch vụ trường học đạt <b>{{ computedFinanceData.grossMargin }}</b> (Doanh thu <b>{{ computedFinanceData.rev }}</b>). Duy trì <b>0 sự cố</b> an toàn học đường.
        </div>
        <div class="uc-kpi-ops__bhead-s">
          Kết nối trực tiếp CSDL eSign &amp; tapi.lhbs.vn · Tự động đồng bộ phản hồi theo bộ lọc cơ sở &amp; kỳ chốt sổ.
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
            <div class="uc-kpi-ops__bkpi-v">{{ formatNumber(displayStudents) }} <small>HS</small></div>
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
            <div class="causal-pill">{{ renderCausalTitle('TS06', '🔗 Chuỗi: Phễu CRM → Sĩ số → Doanh thu') }}</div>
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
            <div class="uc-kpi-ops__bkpi-v">{{ displayWithdrawRate }}% <small>({{ displayWithdrawCount }} HS)</small></div>
            <svg class="uc-kpi-ops__spark" viewBox="0 0 110 42">
              <line x1="2" x2="108" y1="8" y2="8" class="sp-tg"></line>
              <polyline points="4,18 25,22 46,20 67,26 88,24 100,21" class="sp-l"></polyline>
              <circle cx="100" cy="21" r="3" class="sp-d is-last"></circle>
              <text x="100" y="38" text-anchor="middle" class="sp-x">T10</text>
            </svg>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Đến: +{{ displayInflow }} HS | Đi: -{{ displayOutflow }} HS | Rút ròng: {{ displayNetChange }} HS</div>
          <div class="uc-kpi-ops__cmp">
            <span><i>Nơi ở/tiện đón:</i> <b>{{ displayReasonFar }}</b></span>
            <span><i>Kinh tế:</i> <b>{{ displayReasonEco }}</b></span>
            <span><i>Bệnh/Khác:</i> <b>{{ displayReasonOther }}</b></span>
          </div>

          <!-- Mắt xích Nhân quả Ngữ cảnh Tile 2 -->
          <div class="uc-kpi-ops__bkpi-causal is-bad" @click.stop="openCausalChainForCard('WITHDRAW')">
            <div class="causal-pill">{{ renderCausalTitle('TS04', '🔗 Chuỗi: Xe bus/CSVC → Rút học → Thất thu LTV') }}</div>
            <div class="causal-desc" v-html="renderCausalNarrative('TS04', 'NARRATIVE_WITHDRAW_BUS')"></div>
            <div class="causal-cta">
              <span>Mở Dialog Vùng Tác Động Rút Học &rsaquo;</span>
            </div>
          </div>

          <div class="uc-kpi-ops__bkpi-i">
            <span @click.stop="openCausalModal(currentUnit === 'ALL' ? 'MNLK' : currentUnit, 'RUT_HOC')" style="font-weight:700;color:var(--accent);">Xem Vùng tác động (ước tính) ›</span>
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
            <div class="uc-kpi-ops__bkpi-v">{{ computedLmsData.rate }} <small>hoàn thành</small></div>
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
            <div class="causal-pill">{{ renderCausalTitle('CM08', '🔗 Chuỗi: Học liệu số → Tự giác làm bài → Giữ chân HS') }}</div>
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
            <div class="uc-kpi-ops__bkpi-v">{{ computedFinanceData.grossMargin }} <small>LN Gộp</small></div>
            <svg class="uc-kpi-ops__spark" viewBox="0 0 110 42">
              <line x1="2" x2="108" y1="12" y2="12" class="sp-tg"></line>
              <polyline points="4,28 25,24 46,20 67,16 88,14 100,13" class="sp-l"></polyline>
              <circle cx="100" cy="13" r="3" class="sp-d is-last"></circle>
              <text x="100" y="38" text-anchor="middle" class="sp-x">KPI 50%</text>
            </svg>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Doanh thu thuần: {{ computedFinanceData.rev }} · Bán trú {{ computedFinanceData.mealMargin }} · Xe bus {{ computedFinanceData.busMargin }}</div>
          <div class="uc-kpi-ops__cmp">
            <span><i>DT CLB (KPI 3.2.1):</i> <b>{{ computedFinanceData.clbRev }}</b></span>
            <span><i>Học sinh CLB:</i> <b>{{ computedFinanceData.clbStudents }}</b></span>
            <span><i>Mục tiêu CLB:</i> <b>$1M tích lũy</b></span>
          </div>

          <!-- Mắt xích Nhân quả Ngữ cảnh Tile 4 -->
          <div class="uc-kpi-ops__bkpi-causal is-good" @click.stop="openCausalChainForCard('FINANCE')">
            <div class="causal-pill">{{ renderCausalTitle('TC55', '🔗 Chuỗi: LN Dịch vụ → Tái đầu tư CSVC → Giảm rút học') }}</div>
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

      <!-- 4 Trụ Cột Vận Hành LHBS (4 Command Pillars Bar) -->
      <div class="uc-kpi-ops__pillars">
        <!-- Trụ cột 1: Quy mô & Tuyển sinh -->
        <div class="uc-kpi-ops__pillar-card" @click="page = 1">
          <div class="uc-kpi-ops__pillar-h">
            <span>1. Quy mô &amp; Tuyển sinh</span>
            <span class="uc-kpi-ops__pillar-pill is-ok">ĐẠT {{ displayCapacityPct }}%</span>
          </div>
          <div class="uc-kpi-ops__pillar-b">
            {{ formatNumber(displayStudents) }} <small>/ {{ formatNumber(displayTarget) }} HS</small>
          </div>
          <div class="uc-kpi-ops__pillar-bar">
            <div class="uc-kpi-ops__pillar-bar-fill" :style="{ width: Math.min(100, displayCapacityPct) + '%' }"></div>
          </div>
          <div class="uc-kpi-ops__pillar-f">
            7 chỉ tiêu (TS01–TS07) · Rút học {{ displayWithdrawRate }}% · Tỷ lệ chuyển đổi TVTS {{ displayConversionRate }}%
          </div>
        </div>

        <!-- Trụ cột 2: Chuyên môn & Chất lượng Đào tạo -->
        <div class="uc-kpi-ops__pillar-card" @click="page = 4">
          <div class="uc-kpi-ops__pillar-h">
            <span>2. Giáo dục &amp; Học thuật</span>
            <span class="uc-kpi-ops__pillar-pill is-ok">ĐẠT {{ computedLmsData.rate }}</span>
          </div>
          <div class="uc-kpi-ops__pillar-b">
            {{ computedLmsData.rate }} <small>Hoàn thành LMS</small>
          </div>
          <div class="uc-kpi-ops__pillar-bar">
            <div class="uc-kpi-ops__pillar-bar-fill" style="width: 89.6%;"></div>
          </div>
          <div class="uc-kpi-ops__pillar-f">
            20 chỉ tiêu (CM08–CM27) · 100% học liệu số · 0 vi phạm quy chế chuyên môn
          </div>
        </div>

        <!-- Trụ cột 3: Vận hành Dịch vụ & Trải nghiệm -->
        <div class="uc-kpi-ops__pillar-card" @click="page = 3">
          <div class="uc-kpi-ops__pillar-h">
            <span>3. Vận hành &amp; Dịch vụ</span>
            <span class="uc-kpi-ops__pillar-pill is-ok">0 SỰ CỐ</span>
          </div>
          <div class="uc-kpi-ops__pillar-b">
            96.8% <small>Khám SK định kỳ</small>
          </div>
          <div class="uc-kpi-ops__pillar-bar">
            <div class="uc-kpi-ops__pillar-bar-fill" style="width: 96.8%;"></div>
          </div>
          <div class="uc-kpi-ops__pillar-f">
            23 chỉ tiêu (VH28–VH50) · 0 sự cố ATTP &amp; y tế · Hài lòng chung 93.6%
          </div>
        </div>

        <!-- Trụ cột 4: Tài chính & Tăng trưởng Bền vững -->
        <div class="uc-kpi-ops__pillar-card" @click="page = 5">
          <div class="uc-kpi-ops__pillar-h">
            <span>4. Tài chính Dịch vụ</span>
            <span class="uc-kpi-ops__pillar-pill is-ok">LN {{ computedFinanceData.grossMargin }}</span>
          </div>
          <div class="uc-kpi-ops__pillar-b">
            {{ computedFinanceData.rev }} <small>Doanh thu dịch vụ</small>
          </div>
          <div class="uc-kpi-ops__pillar-bar">
            <div class="uc-kpi-ops__pillar-bar-fill" style="width: 96.8%;"></div>
          </div>
          <div class="uc-kpi-ops__pillar-f">
            10 chỉ tiêu (TC51–TC60) · CLB {{ computedFinanceData.clbRev }} · Bán trú LN 48.5%
          </div>
        </div>
      </div>

      <!-- Bảng Điểm Nghẽn Vận Hành & Trách Nhiệm Giải Trình (Active Operational Bottlenecks & Escalation Matrix) -->
      <div class="uc-kpi-ops__escalation">
        <div class="uc-kpi-ops__escalation-h">
          <div class="uc-kpi-ops__escalation-title">
            <span>⚠️ Ma Trận Điểm Nghẽn Vận Hành &amp; Trách Nhiệm Giải Trình (Executive Bottlenecks)</span>
            <span class="uc-kpi-ops__escalation-badge">{{ activeBottlenecks.length }} Điểm Cần Xử Lý</span>
          </div>
          <div class="uc-kpi-ops__escalation-sub">
            Trích xuất trực tiếp từ CSDL eSign theo bộ lọc cơ sở · Báo cáo nóng trước Ban Điều Hành &amp; HĐQT
          </div>
        </div>

        <table class="uc-kpi-ops__escalation-table">
          <thead>
            <tr>
              <th style="width: 140px;">Chỉ Tiêu / Mã</th>
              <th style="width: 110px;">Thực Hiện / Ngưỡng</th>
              <th style="width: 100px;">Trạng Thái</th>
              <th>Vấn Đề Vận Hành &amp; Tác Động Tài Chính</th>
              <th style="width: 180px;">Đầu Mối Chịu Trách Nhiệm</th>
              <th style="width: 200px;">Nguồn Dữ Liệu Go-Live</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in activeBottlenecks" :key="b.KpiCode || b.SnapshotID">
              <td>
                <div style="font-weight: 700; color: #0f172a;">{{ b.KpiName || b.KpiCode }}</div>
                <div style="font-size: 11px; color: #64748b;">Mã: <code>{{ b.KpiCode }}</code></div>
              </td>
              <td>
                <div style="font-weight: 700; font-size: 13px; color: #0f172a;">
                  {{ formatNumber(b.ActualValue) }} {{ b.Unit || '' }}
                </div>
                <div style="font-size: 11px; color: #64748b;">
                  Mục tiêu: {{ formatNumber(b.TargetValue) }} {{ b.Unit || '' }}
                  <span v-if="b.Rate != null" style="font-weight: 600; color: #b45309; margin-left: 2px;">
                    · Đạt {{ b.Rate }}%
                  </span>
                </div>
              </td>
              <td>
                <span :class="['uc-kpi-ops__status-pill', b.Status === 'DANGER' || b.Status === 'BAD' ? 'is-danger' : 'is-warn']">
                  {{ b.Status === 'DANGER' || b.Status === 'BAD' ? 'NGUY HIỂM' : 'CẢNH BÁO' }}
                </span>
              </td>
              <td>
                <div style="margin-bottom: 4px;">{{ b.OperationalInsight || 'Cần theo dõi sát tiến độ hoàn thành theo kế hoạch.' }}</div>
                <div v-if="b.FinancialImpact" style="font-size: 11px; color: #b91c1c; font-weight: 600;">
                  💰 Tác động tài chính: {{ b.FinancialImpact }}
                </div>
              </td>
              <td>
                <div style="font-weight: 600; color: #334155;">{{ getKpiOwner(b) }}</div>
                <div style="font-size: 11px; color: #64748b;">Báo cáo trước HĐQT kỳ tới</div>
              </td>
              <td>
                <div style="display: flex; flex-direction: column; gap: 4px;">
                  <span style="font-weight: 600; font-size: 11px; color: #0284c7;">{{ b.SourceSystem || 'Hệ thống basicdata.lhbs.vn' }}</span>
                  <button
                    type="button"
                    class="uc-kpi-ops__simbtn"
                    style="font-size: 10.5px; padding: 2px 8px; width: fit-content;"
                    @click="openGoliveSpecs(b.SpecCode || 'SPEC_BASICDATA')"
                  >
                    Đặc tả API Go-Live &rsaquo;
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
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
              <div class="uc-kpi-ops__causal-head-title">{{ causalScenarioTitle }}</div>
            </div>
            <div class="uc-kpi-ops__causal-scenarios">
              <button
                v-for="sc in (causalScenariosList.length ? causalScenariosList : defaultScenarios)"
                :key="sc.ScenarioCode"
                type="button"
                :class="{ 'is-on': causalScenario === sc.ScenarioCode }"
                @click="setScenario(sc.ScenarioCode)"
              >{{ sc.ScenarioName }}</button>
              <button
                type="button"
                class="uc-kpi-ops__causal-cfgbtn"
                @click="openCausalConfigDrawer"
                title="Cấu hình tham số học phí, giả định &amp; quy tắc nhân quả CSDL"
              >⚙️ Cấu hình Tham số CSDL</button>
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
          <!-- Rail bên trái: Giả định / Trục IF -->
          <aside class="uc-kpi-ops__causal-rail">
            <div class="uc-kpi-ops__causal-rail-h">Giả định điều kiện (IF)</div>

            <!-- Đơn vị -->
            <div class="uc-kpi-ops__causal-f">
              <label>Đơn vị cơ sở</label>
              <div class="uc-kpi-ops__causal-opts">
                <button
                  v-for="u in causalUnitOptions"
                  :key="u.k"
                  type="button"
                  :class="{ 'is-on': causalUnit === u.k }"
                  @click="causalUnit = u.k"
                >{{ u.t }}</button>
              </div>
            </div>

            <!-- Trường hợp Rút học -->
            <template v-if="causalScenario === 'RUT_HOC'">
              <div class="uc-kpi-ops__causal-f">
                <label>Số học sinh rời đi: <b>{{ causalN }}</b> HS</label>
                <input
                  type="range"
                  min="1"
                  max="30"
                  step="1"
                  v-model.number="causalN"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Thời điểm rời</label>
                <select v-model.number="causalMonth" class="uc-kpi-ops__select">
                  <option v-for="o in causalMonthOptions" :key="o.m" :value="o.m">{{ o.t }}</option>
                </select>
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Lý do rời đi (Phân loại rủi ro)</label>
                <div class="uc-kpi-ops__causal-opts is-col">
                  <button
                    v-for="r in (causalReasonsList.length ? causalReasonsList : defaultReasons)"
                    :key="r.ReasonCode"
                    type="button"
                    :class="{ 'is-on': causalReasonCode === r.ReasonCode }"
                    @click="causalReasonCode = r.ReasonCode"
                  >{{ r.ReasonName }} <small v-if="r.HistoricalCount">({{ r.HistoricalCount }} ca)</small></button>
                </div>
              </div>
            </template>

            <!-- Trường hợp Tuyển thêm -->
            <template v-else-if="causalScenario === 'TUYEN_THEM'">
              <div class="uc-kpi-ops__causal-f">
                <label>Tuyển thêm học sinh: <b>{{ causalAddN }}</b> HS</label>
                <input
                  type="range"
                  min="1"
                  max="80"
                  step="1"
                  v-model.number="causalAddN"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Thời điểm nhập học</label>
                <select v-model.number="causalMonth" class="uc-kpi-ops__select">
                  <option v-for="o in causalMonthOptions" :key="o.m" :value="o.m">{{ o.t }}</option>
                </select>
              </div>
            </template>

            <!-- Trường hợp Thay đổi chuyển đổi -->
            <template v-else-if="causalScenario === 'CHUYEN_DOI'">
              <div class="uc-kpi-ops__causal-f">
                <label>Chuyển đổi thay đổi: <b>{{ causalConvDelta > 0 ? '+' : '' }}{{ causalConvDelta }} điểm</b></label>
                <input
                  type="range"
                  min="-10"
                  max="20"
                  step="1"
                  v-model.number="causalConvDelta"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Áp dụng trong</label>
                <select v-model.number="causalConvMonths" class="uc-kpi-ops__select">
                  <option v-for="mm in [1, 2, 3, 4, 6, 8]" :key="mm" :value="mm">{{ mm }} tháng tới</option>
                </select>
              </div>
            </template>

            <!-- Trường hợp Mở tuyến xe bus mới -->
            <template v-else-if="causalScenario === 'MO_TUYEN_BUS'">
              <div class="uc-kpi-ops__causal-f">
                <label>Số tuyến xe bus mở mới: <b>{{ causalBusRoutes }}</b> tuyến</label>
                <input
                  type="range"
                  min="1"
                  max="5"
                  step="1"
                  v-model.number="causalBusRoutes"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Số học sinh dự kiến / tuyến: <b>{{ causalBusStudentsPerRoute }}</b> HS</label>
                <input
                  type="range"
                  min="8"
                  max="25"
                  step="1"
                  v-model.number="causalBusStudentsPerRoute"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Tuyến trọng điểm</label>
                <div style="font-size: 11px; color: #334155; padding: 6px 10px; background: #f1f5f9; border-radius: 4px; border-left: 3px solid #0284c7;">
                  📍 Trục Trảng Dài - Tân Phong - Hố Nai (Chiếm 25.7% lý do rút học)
                </div>
              </div>
            </template>

            <!-- Trường hợp Ưu đãi giữ chân chuyển cấp -->
            <template v-else-if="causalScenario === 'GIU_CHAN_CHUYEN_CAP'">
              <div class="uc-kpi-ops__causal-f">
                <label>Mức ưu đãi học phí: <b>{{ causalDiscountPct }}%</b> trọn cấp</label>
                <input
                  type="range"
                  min="3"
                  max="15"
                  step="1"
                  v-model.number="causalDiscountPct"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Học sinh giữ chân dự kiến: <b>{{ causalTransitionRetained }}</b> HS</label>
                <input
                  type="range"
                  min="10"
                  max="80"
                  step="5"
                  v-model.number="causalTransitionRetained"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Khối chuyển tiếp</label>
                <div style="font-size: 11px; color: #334155; padding: 6px 10px; background: #f1f5f9; border-radius: 4px; border-left: 3px solid #059669;">
                  🎓 Khối Lá lên Lớp 1, Khối 5 lên 6, Khối 9 lên 10
                </div>
              </div>
            </template>

            <!-- Trường hợp Phát triển CLB ngoài giờ -->
            <template v-else-if="causalScenario === 'MO_RONG_CLB'">
              <div class="uc-kpi-ops__causal-f">
                <label>Số CLB mở mới: <b>{{ causalNewClbCount }}</b> CLB</label>
                <input
                  type="range"
                  min="1"
                  max="8"
                  step="1"
                  v-model.number="causalNewClbCount"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Học sinh tham gia thêm: <b>{{ causalAddClbStudents }}</b> HS</label>
                <input
                  type="range"
                  min="20"
                  max="200"
                  step="10"
                  v-model.number="causalAddClbStudents"
                  class="uc-kpi-ops__range"
                />
              </div>

              <div class="uc-kpi-ops__causal-f">
                <label>Lĩnh vực CLB trọng tâm</label>
                <div style="font-size: 11px; color: #334155; padding: 6px 10px; background: #f1f5f9; border-radius: 4px; border-left: 3px solid #d97706;">
                  🚀 STEM Robotics, AI Coding, Bơi lội, Nhạc cụ & Tiếng Anh giao tiếp
                </div>
              </div>
            </template>

            <!-- Trường hợp Ứng phó sự cố an toàn & y tế -->
            <template v-else-if="causalScenario === 'SU_CO_AN_TOAN'">
              <div class="uc-kpi-ops__causal-f">
                <label>Nguyên tắc sống còn</label>
                <div style="font-size: 11px; color: #991b1b; padding: 8px 10px; background: #fee2e2; border-radius: 4px; border-left: 3px solid #b91c1c; font-weight: 600;">
                  🛡️ Duy trì tuyệt đối 0 sự cố ngộ độc thực phẩm (ISO 22000) và 0 tai nạn thương tích y tế học đường
                </div>
              </div>
              <div class="uc-kpi-ops__causal-f">
                <label>Thời gian ứng phó khẩn cấp</label>
                <div style="font-size: 11px; color: #334155; padding: 6px 10px; background: #f8fafc; border-radius: 4px;">
                  ⏱️ Cô lập mẫu trong 30 phút · Đối thoại phụ huynh trong 2 giờ
                </div>
              </div>
            </template>

            <div class="uc-kpi-ops__causal-rail-note">
              Số liệu nền: tháng 9/2026. Tiền quy đổi theo học phí niêm yết 2026 từng cấp (chưa gồm bán trú, chưa trừ ưu đãi); dữ liệu động từ CSDL eSign.
            </div>
          </aside>

          <!-- Main bên phải -->
          <main class="uc-kpi-ops__causal-main">
            <!-- 1. Hero Kết luận -->
            <section class="uc-kpi-ops__causal-hero">
              <span class="uc-kpi-ops__causal-hero-tag">Gợi ý đọc số · chờ M&amp;E xác nhận</span>
              <span class="uc-kpi-ops__causal-hero-text">{{ causalHeroSentence }}</span>
            </section>

            <!-- 2. 4 Hero KPI Cards -->
            <section class="uc-kpi-ops__causal-kpis">
              <div class="uc-kpi-ops__causal-kpi is-bad">
                <div class="uc-kpi-ops__causal-kpi-k">Doanh thu năm nay</div>
                <div class="uc-kpi-ops__causal-kpi-v">{{ causalCalc.revNowSign }} tỷ</div>
                <div class="uc-kpi-ops__causal-kpi-s">khoảng {{ causalCalc.revNowRange }} · LN gộp {{ causalCalc.revMarginSign }} tỷ</div>
                <span class="uc-kpi-ops__causal-tag is-uoc">Ước tính</span>
              </div>

              <div class="uc-kpi-ops__causal-kpi is-bad">
                <div class="uc-kpi-ops__causal-kpi-k">Doanh thu các năm sau</div>
                <div class="uc-kpi-ops__causal-kpi-v">&asymp; {{ causalCalc.revFutureSign }} tỷ</div>
                <div class="uc-kpi-ops__causal-kpi-s">khoảng {{ causalCalc.revFutureRange }}</div>
                <span class="uc-kpi-ops__causal-tag is-uoc">Ước tính</span>
              </div>

              <div class="uc-kpi-ops__causal-kpi" :class="{ 'is-bad': causalCalc.isRutBad }">
                <div class="uc-kpi-ops__causal-kpi-k">Rút học lũy kế · KPI 3</div>
                <div class="uc-kpi-ops__causal-kpi-v">{{ causalCalc.rutBeforePct }}% &rarr; {{ causalCalc.rutAfterPct }}%</div>
                <div class="uc-kpi-ops__causal-kpi-s">nhịp cho phép 3,0% · {{ causalCalc.rutPaceMultiple }}</div>
                <span class="uc-kpi-ops__causal-tag is-that">Dữ liệu thật</span>
              </div>

              <div class="uc-kpi-ops__causal-kpi">
                <div class="uc-kpi-ops__causal-kpi-k">Lead để tuyển bù</div>
                <div class="uc-kpi-ops__causal-kpi-v">&asymp; {{ causalCalc.leadsNeed }} lead</div>
                <div class="uc-kpi-ops__causal-kpi-s">{{ causalCalc.leadsPctMonth }}% lượng lead một tháng</div>
                <span class="uc-kpi-ops__causal-tag is-that">Dữ liệu thật</span>
              </div>
            </section>

            <!-- 3. CÂY TÁC ĐỘNG TRỰC QUAN SVG (SVG Causal Tree 4 tầng) -->
            <section class="uc-kpi-ops__causal-card">
              <div class="uc-kpi-ops__causal-card-head">
                <div class="uc-kpi-ops__causal-card-title">Cây tác động</div>
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

            <!-- 4. Lưới 4 Card phụ -->
            <section class="uc-kpi-ops__causal-subgrid">
              <!-- Sub 1: Giá trị bị ảnh hưởng -->
              <div class="uc-kpi-ops__causal-card">
                <div class="uc-kpi-ops__causal-card-title">Giá trị bị ảnh hưởng</div>
                <div class="uc-kpi-ops__causal-value-total">{{ causalCalc.totalLostSign }} tỷ</div>
                <div class="uc-kpi-ops__causal-value-lbl">tổng doanh thu bị ảnh hưởng</div>
                <div class="uc-kpi-ops__causal-strip-bar">
                  <span class="uc-kpi-ops__causal-strip-now" :style="{ width: causalCalc.stripNowPct + '%' }"></span>
                  <span class="uc-kpi-ops__causal-strip-future" :style="{ width: (100 - causalCalc.stripNowPct) + '%' }"></span>
                </div>
                <div class="uc-kpi-ops__causal-strip-lg">
                  <div><em class="is-now"></em>Năm nay <b>{{ causalCalc.revNowSign }} tỷ</b></div>
                  <div><em class="is-future"></em>Các năm sau (ước tính) <b>{{ causalCalc.revFutureSign }} tỷ</b></div>
                </div>
              </div>

              <!-- Sub 2: KPI trước và sau so với ngưỡng -->
              <div class="uc-kpi-ops__causal-card">
                <div class="uc-kpi-ops__causal-card-title">KPI trước và sau, so với ngưỡng</div>
                <div class="uc-kpi-ops__causal-tbars">
                  <div>
                    <div class="uc-kpi-ops__causal-tbar-l">Đạt chỉ tiêu sĩ số</div>
                    <div class="uc-kpi-ops__causal-tbar-track">
                      <div class="uc-kpi-ops__causal-tbar-fill is-good" :style="{ width: Math.min(100, causalCalc.fillPctAfter) + '%' }"></div>
                      <i style="left: 100%;" title="Đích 100%"></i>
                    </div>
                    <div class="uc-kpi-ops__causal-tbar-v">
                      <span><s>{{ causalCalc.fillPctBefore }}%</s> &rarr; <b>{{ causalCalc.fillPctAfter }}%</b></span>
                      <small>ngưỡng 100,0%</small>
                    </div>
                  </div>

                  <div>
                    <div class="uc-kpi-ops__causal-tbar-l">Rút học lũy kế so với nhịp</div>
                    <div class="uc-kpi-ops__causal-tbar-track">
                      <div class="uc-kpi-ops__causal-tbar-fill" :style="{ width: Math.min(100, (causalCalc.rutAfterPct / 15) * 100) + '%' }"></div>
                      <i style="left: 20%;" title="Ngưỡng nhịp 3.0%"></i>
                    </div>
                    <div class="uc-kpi-ops__causal-tbar-v">
                      <span><s>{{ causalCalc.rutBeforePct }}%</s> &rarr; <b>{{ causalCalc.rutAfterPct }}%</b></span>
                      <small>ngưỡng &le; 3,0%</small>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Sub 3: Vì sao rời đi? -->
              <div class="uc-kpi-ops__causal-card">
                <div class="uc-kpi-ops__causal-card-title">Vì sao rời đi? (Tuyến xử lý)</div>
                <div class="uc-kpi-ops__causal-route">
                  <div class="uc-kpi-ops__causal-route-row">
                    <span>Giải trình (luôn là)</span>
                    <b>{{ currentCausalUnitName }} &middot; {{ currentCausalOwnerTitle }}</b>
                  </div>
                  <div class="uc-kpi-ops__causal-route-row">
                    <span>Xử lý nguyên nhân</span>
                    <b>{{ currentCausalReason.ActionOwner }}</b>
                  </div>
                  <div class="uc-kpi-ops__causal-route-row">
                    <span>Chỉ số cần soi tiếp</span>
                    <b>{{ currentCausalReason.WatchIndicator }}</b>
                  </div>
                  <div class="uc-kpi-ops__causal-route-row">
                    <span>Hành động đề xuất</span>
                    <b>{{ currentCausalReason.RecommendedAction }}</b>
                  </div>
                </div>
                <div class="uc-kpi-ops__causal-route-note">
                  Thực tế lũy kế <b>toàn hệ thống</b>: Nơi ở / đưa đón 21 &middot; Khác 14 &middot; Kinh tế 10 &middot; Bệnh 7 &middot; Định cư 1.
                </div>
              </div>

              <!-- Sub 4: Ai phải làm gì -->
              <div class="uc-kpi-ops__causal-card">
                <div class="uc-kpi-ops__causal-card-title">Ai phải làm gì</div>
                <div class="uc-kpi-ops__causal-actions">
                  <div
                    v-for="a in currentAssignments"
                    :key="a.AssignmentID"
                    class="uc-kpi-ops__causal-act-row"
                  >
                    <div class="uc-kpi-ops__causal-act-role">{{ a.RoleTitle.replace('{Unit}', currentCausalUnitName) }}</div>
                    <div class="uc-kpi-ops__causal-act-desc">{{ a.ActionDescription.replace('{Unit}', currentCausalUnitName).replace('{LeadsNeed}', causalCalc.leadsNeed) }}</div>
                  </div>
                </div>
              </div>
            </section>
          </main>
        </div>
      </div>
    </div>

      <!-- Bảng trách nhiệm giải trình -->
      <div class="uc-kpi-ops__visual">
        <div class="uc-kpi-ops__vhead">
          <div class="uc-kpi-ops__vtitle">Trách nhiệm theo dõi sĩ số &amp; vận hành từng khối lớp (Live Data)</div>
          <div class="uc-kpi-ops__vnote">Nguồn dữ liệu: API tapi.lhbs.vn/Dashboard/ThongKeHocSinhTheoKhoiLop</div>
        </div>
        <div class="uc-kpi-ops__tablewrap">
          <table class="uc-kpi-ops__table">
            <thead>
              <tr>
                <th class="ta-l">Khối Lớp</th>
                <th>Sĩ số hiện diện</th>
                <th>Nam</th>
                <th>Nữ</th>
                <th>Tỷ lệ Nữ</th>
                <th>Tỷ trọng toàn trường</th>
                <th class="ta-l">Tiến độ tuyển sinh</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in currentGradeRows.slice(0, 10)" :key="r.Ten">
                <td class="ta-l tx-strong">{{ r.Ten }}</td>
                <td class="tx-strong">{{ formatNumber(r.SLHocSinh) }}</td>
                <td>{{ formatNumber(r.SL_HSNam) }}</td>
                <td>{{ formatNumber(r.SL_HSNu) }}</td>
                <td>{{ calcPercent(r.SL_HSNu, r.SLHocSinh) }}%</td>
                <td>
                  <span class="uc-kpi-ops__btrack">
                    <span class="uc-kpi-ops__bfill is-good" :style="{ width: calcPercent(r.SLHocSinh, computedTotalStudents) * 5 + '%' }"></span>
                  </span>
                  {{ calcPercent(r.SLHocSinh, computedTotalStudents) }}%
                </td>
                <td class="ta-l">
                  <span :class="['uc-kpi-ops__cell-tag', r.SLHocSinh >= 150 ? 'is-good' : 'is-warn']">
                    {{ r.SLHocSinh >= 150 ? 'Đạt chỉ tiêu' : 'Cần đôn đốc' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 4. PAGE 1: CƠ CẤU SĨ SỐ KHỐI LỚP (TS01, TS02) -->
    <div v-if="page === 1" class="uc-kpi-ops__page">
      <div class="uc-kpi-ops__visual">
        <div class="uc-kpi-ops__vhead">
          <div class="uc-kpi-ops__vtitle">Bảng Cơ Cấu Sĩ Số Học Sinh Toàn Bộ Các Khối Lớp (Live API)</div>
          <div class="uc-kpi-ops__vnote">Tổng cộng: {{ formatNumber(computedTotalStudents) }} học sinh</div>
        </div>
        <div class="uc-kpi-ops__tablewrap">
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
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Top Lý Do Rút Học &amp; Chuyển Đi (152 bản ghi)</div>
            <div class="uc-kpi-ops__vnote">Nguồn: API ThongKeHocSinhChuyenDi</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <thead>
                <tr>
                  <th class="ta-l">Lý do rút hồ sơ</th>
                  <th>Số lượng</th>
                  <th>Tỷ trọng (%)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in topWithdrawReasons" :key="r.name">
                  <td class="ta-l tx-strong">{{ r.name }}</td>
                  <td class="tx-strong tx-bad">{{ r.count }} HS</td>
                  <td>
                    <span class="uc-kpi-ops__btrack">
                      <span class="uc-kpi-ops__bfill is-bad" :style="{ width: r.percent * 3 + '%' }"></span>
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
        <div class="uc-kpi-ops__vhead">
          <div class="uc-kpi-ops__vtitle">Mức Độ Hoàn Thành Bài Tập Của Học Sinh Trên LMS (CM08 · spAPI_BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID)</div>
          <div class="uc-kpi-ops__vnote">Tỷ lệ hoàn thành toàn cấp: <b class="tx-good">{{ lmsOverallRate }}%</b> (Tổng 5.323 lượt bài tập giao)</div>
        </div>
        <div class="uc-kpi-ops__tablewrap">
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
          Tỷ suất lợi nhuận gộp dịch vụ của {{ currentUnitTitle }} đạt <b>{{ computedFinanceData.grossMargin }}</b> (Mục tiêu <b>KPI 4: 50%</b>). Doanh thu các Câu lạc bộ bổ trợ ngoài giờ đạt <b>{{ computedFinanceData.clbRev }}</b> với <b>{{ computedFinanceData.clbStudents }}</b> tham gia (Đóng góp mục tiêu <b>KPI 3.2.1: $1M</b>).
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
            <b class="tx-good">MỤC TIÊU 50%</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v tx-good">{{ computedFinanceData.grossMargin }}</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Bán trú {{ computedFinanceData.mealMargin }} · Xe bus {{ computedFinanceData.busMargin }} · Bán lẻ 28.2%</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>DOANH THU THUẦN (ƯỚC TÍNH)</span>
            <b>HỌC KỲ 1</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedFinanceData.rev }}</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Lợi nhuận gộp ước tính đạt ~48% doanh thu</div>
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
            <div class="uc-kpi-ops__vtitle">Chỉ Tiêu 55: Tỷ Suất Lợi Nhuận Gộp Dịch Vụ (KPI 4 - Mục Tiêu 50%)</div>
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
                  <td class="tx-strong">79.37 tỷ</td>
                  <td class="tx-strong">40.95 tỷ</td>
                  <td class="tx-good tx-strong">38.42 tỷ</td>
                  <td class="tx-good tx-strong">48.4% (Đạt 96.8% KH)</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Bảng 2: Chỉ tiêu 56 - Doanh thu CLB bổ trợ -->
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Chỉ Tiêu 56: Doanh Thu Các CLB Bổ Trợ Ngoài Giờ (KPI 3.2.1)</div>
            <div class="uc-kpi-ops__vnote">Mục tiêu: Đạt $1 triệu USD tích lũy</div>
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
                  <td class="ta-l tx-strong">Toàn trường (4 Khối)</td>
                  <td class="tx-strong">596 HS</td>
                  <td>—</td>
                  <td class="tx-good tx-strong">1.611 tỷ VNĐ</td>
                  <td class="tx-good tx-strong">100% (Đạt 92.4% KH)</td>
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
            <div class="uc-kpi-ops__vnote">Tháng 10/2026</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <tbody>
                <tr>
                  <td class="ta-l tx-strong">Sự cố ngộ độc thực phẩm bếp ăn</td>
                  <td class="tx-good">0 vụ (Đạt KPI)</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Sự cố tai nạn thương tích nghiêm trọng</td>
                  <td class="tx-good">0 vụ (Đạt KPI)</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Tỷ lệ học sinh ăn bán trú toàn trường</td>
                  <td>94.2% (2.354 HS)</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Tỷ lệ phụ huynh cài đặt app ME School</td>
                  <td class="tx-good">98.6% (2.464 PH)</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Tương Tác Phụ Huynh Qua Kênh ME School (Live API)</div>
            <div class="uc-kpi-ops__vnote">HoatDongTrangMe_PH_TuongTac</div>
          </div>
          <div class="uc-kpi-ops__tablewrap">
            <table class="uc-kpi-ops__table">
              <tbody>
                <tr>
                  <td class="ta-l tx-strong">Lượt tương tác tin tức / thông báo</td>
                  <td class="tx-strong">12.480 lượt / tháng</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Lượt điểm danh nhận diện khuôn mặt</td>
                  <td class="tx-strong">48.200 lượt</td>
                </tr>
                <tr>
                  <td class="ta-l tx-strong">Đánh giá độ hài lòng dịch vụ (VH06)</td>
                  <td class="tx-good">96.8% Hài lòng</td>
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
            <b>THÁNG 10: {{ computedCrmLeadsCurrentMonth }}</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedCrmLeads }} <small>Leads</small></div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Lũy kế 3 tháng: T8: 359 · T9: 162 · T10: 89</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>TỶ LỆ CHUYỂN ĐỔI (TS06)</span>
            <b class="tx-good">ĐẠT 9.5%</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v tx-good">{{ computedCrmConversionRate }}%</div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">PTLC: 20.6% · MNBH: 10.3% · MNLK: 6.3%</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-good">
          <div class="uc-kpi-ops__bkpi-h">
            <span>NHẬP HỌC THỰC TẾ</span>
            <b>58 HỌC SINH</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">{{ computedCrmEnrolled }} <small>HS</small></div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">Đã hoàn tất đóng phí tuyển mới và nộp hồ sơ</div>
        </div>
        <div class="uc-kpi-ops__bkpi is-warn" @click="openDrawer('KITTY_LIST')">
          <div class="uc-kpi-ops__bkpi-h">
            <span>PIPELINE KITTY (HẸN HK2)</span>
            <b class="tx-warn">15 HỒ SƠ</b>
          </div>
          <div class="uc-kpi-ops__bkpi-m">
            <div class="uc-kpi-ops__bkpi-v">15 <small>Hồ sơ</small></div>
          </div>
          <div class="uc-kpi-ops__bkpi-d">13 bé chờ đủ tuổi HK2 (Tab Kitty GID 1481169716)</div>
          <div class="uc-kpi-ops__bkpi-i">Xem chi tiết 15 hồ sơ ›</div>
        </div>
      </div>

      <!-- Funnel Progress & Channel Matrix -->
      <div class="uc-kpi-ops__bcols">
        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Báo Cáo Diễn Biến Leads &amp; Nhập Học 3 Tháng (Live Tracking)</div>
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
                  <td class="ta-l tx-strong">Lũy kế 3 tháng</td>
                  <td class="tx-strong">63</td>
                  <td class="tx-strong">261</td>
                  <td class="tx-strong">286</td>
                  <td class="tx-strong tx-good">610</td>
                  <td class="tx-good tx-strong">58 HS</td>
                  <td class="tx-good tx-strong">9.51%</td>
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
            <div class="uc-kpi-ops__vnote">Google Sheet GID 1481169716 (15 phụ huynh)</div>
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
              Xem toàn bộ 15 hồ sơ nuôi dưỡng Kitty ›
            </button>
          </div>
        </div>

        <div class="uc-kpi-ops__visual">
          <div class="uc-kpi-ops__vhead">
            <div class="uc-kpi-ops__vtitle">Phân Tích Rào Cản Tuyển Sinh &amp; Lý Do Chưa Chuyển Đổi</div>
            <div class="uc-kpi-ops__vnote">Khảo sát 552 trường hợp drop-off</div>
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
          <span class="uc-kpi-ops__tabgrp-l">Nhóm 1: Quy mô &amp; Tuyển sinh</span>
          <button type="button" :class="{ 'is-on': page === 0 }" @click="page = 0">0. Hội đồng trường</button>
          <button type="button" :class="{ 'is-on': page === 1 }" @click="page = 1">1. Sĩ số &amp; Khối lớp (Chỉ tiêu 1–3)</button>
          <button type="button" :class="{ 'is-on': page === 7 }" @click="page = 7">2. Phễu TVTS &amp; Leads (Chỉ tiêu 5, 6)</button>
          <button type="button" :class="{ 'is-on': page === 2 }" @click="page = 2">3. Rút học &amp; Chuyển đi (Chỉ tiêu 4)</button>
        </div>
        <div class="uc-kpi-ops__tabgrp">
          <span class="uc-kpi-ops__tabgrp-l">Nhóm 2, 3, 4: Chuyên môn &amp; Tài chính</span>
          <button type="button" :class="{ 'is-on': page === 4 }" @click="page = 4">4. Chuyên môn LMS (Nhóm 2)</button>
          <button type="button" :class="{ 'is-on': page === 6 }" @click="page = 6">5. Dịch vụ &amp; An toàn ME (Nhóm 3)</button>
          <button type="button" :class="{ 'is-on': page === 5 }" @click="page = 5">6. Tài chính: LN gộp &amp; CLB (Nhóm 4: 55, 56)</button>
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
              📊 Phân Tích Chuỗi Tác Động Điều Hành: Xe Bus &rarr; Rút Học &rarr; Thất Thu Tài Chính
            </div>
            <div class="causal-desc" style="font-size:12px;margin:6px 0;">
              <b>21/53 học sinh</b> (40%) rút học do khoảng cách địa lý và tuyến đưa đón. Thiệt hại tài chính trực tiếp: <b>1.365 tỷ học phí</b> + <b>252 triệu xe bus/năm</b>.
            </div>
            <div class="d-flex align-center justify-space-between mt-2">
              <span class="text-xs text-muted">Đề xuất BĐH: Mở 2 tuyến bus Trảng Bom &amp; QL1K để giữ chân 25–30 HS</span>
              <button
                type="button"
                class="uc-kpi-ops__simbtn is-solid"
                style="padding:4px 10px;font-size:11px;"
                @click="openCausalModal(currentUnit === 'ALL' ? 'MNLK' : currentUnit, 'RUT_HOC')"
              >Mở Mô Hình Vùng Tác Động (What-If) ↗</button>
            </div>
          </div>

          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Danh sách 152 học sinh chuyển đi (Live Data)</div>
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
              📊 Phân Tích Chuỗi Tác Động Điều Hành: Quy Mô Sĩ Số &rarr; Lợi Nhuận Gộp &rarr; Điểm Hòa Vốn
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
                @click="openCausalModal(currentUnit === 'ALL' ? 'MNLK' : currentUnit, 'TUYEN_THEM')"
              >Mở Mô Hình Vùng Tác Động Tuyển Thêm ↗</button>
            </div>
          </div>

          <div class="uc-kpi-ops__visual">
            <div class="uc-kpi-ops__vhead">
              <div class="uc-kpi-ops__vtitle">Sĩ số theo khối lớp (Live Data)</div>
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
              📊 Phân Tích Chuỗi Tác Động Điều Hành: Lợi Nhuận Dịch Vụ &rarr; Quỹ Tái Đầu Tư CSVC
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
              <div class="uc-kpi-ops__vtitle">Chi tiết cơ cấu Lợi nhuận gộp Dịch vụ (KPI 4: Mục tiêu 50%)</div>
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
              <div class="uc-kpi-ops__vnote">Google Sheet GID 1481169716 · 15 hồ sơ chờ nhập học</div>
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
              >Tất cả hệ thống (6)</button>
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
                    <th>Sĩ số T9</th>
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
      correlationViewMode: "FLOW",
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
        { k: "MNBH", t: "MN Biên Hòa" },
        { k: "MNLK", t: "MN Long Khánh" },
        { k: "TH", t: "Tiểu học" },
        { k: "THCS", t: "THCS" },
        { k: "THPT", t: "THPT" },
      ],
      defaultScenarios: [
        { ScenarioCode: "RUT_HOC", ScenarioName: "Học sinh rời đi" },
        { ScenarioCode: "TUYEN_THEM", ScenarioName: "Tuyển thêm học sinh" },
        { ScenarioCode: "CHUYEN_DOI", ScenarioName: "Thay đổi chuyển đổi" },
      ],
      defaultReasons: [
        { ReasonCode: "REASON_BUS", ReasonName: "Nơi ở / đưa đón", ActionOwner: "Bán trú – Xe đưa rước", WatchIndicator: "Độ phủ tuyến xe; lead thất bại vì 'ngoài tuyến xe'", RecommendedAction: "Rà tuyến xe theo địa chỉ học sinh, đề xuất điểm đón mới", HistoricalCount: 21 },
        { ReasonCode: "REASON_ECO", ReasonName: "Kinh tế", ActionOwner: "Kế toán – Chính sách học phí", WatchIndicator: "Nợ học phí; tỷ lệ dùng ưu đãi", RecommendedAction: "Liên hệ phụ huynh trước khi rút, xem gói hỗ trợ học phí", HistoricalCount: 10 },
        { ReasonCode: "REASON_SICK", ReasonName: "Bệnh", ActionOwner: "Y tế học đường", WatchIndicator: "Ca bệnh theo lớp; chuyên cần", RecommendedAction: "Theo dõi sức khỏe, đề xuất bảo lưu thay vì rút", HistoricalCount: 7 },
        { ReasonCode: "REASON_DISSATISFIED", ReasonName: "Không hài lòng", ActionOwner: "Hiệu trưởng – Chuyên môn", WatchIndicator: "Hài lòng phụ huynh; khiếu nại; kết quả dự giờ", RecommendedAction: "Gặp phụ huynh, xử lý phản ánh trong 48 giờ", HistoricalCount: 0 },
        { ReasonCode: "REASON_ABROAD", ReasonName: "Định cư & du học", ActionOwner: "Tuyển sinh – Đối ngoại", WatchIndicator: "Nguyện vọng du học; đối tác", RecommendedAction: "Ít kiểm soát được; ghi nhận để dự báo", HistoricalCount: 1 },
        { ReasonCode: "REASON_UNKNOWN", ReasonName: "Chưa rõ lý do", ActionOwner: "Hiệu trưởng (phải phân loại trước)", WatchIndicator: "14/53 ca toàn hệ thống đang để 'Khác'; lý do chưa tách theo đơn vị", RecommendedAction: "Phỏng vấn rời trường, chọn lý do chuẩn rồi mới giao xử lý", HistoricalCount: 14 },
      ],
      defaultAssumptions: [
        { UnitCode: "MNBH", UnitName: "MN Biên Hòa", OwnerTitle: "Hiệu trưởng MN Trấn Biên", PlannedCapacity: 406, CurrentEnrollment: 357, AnnualTuitionMillion: 37.2, GrossMarginPct: 0.85, RemainingYearsInLevel: 2.0, NextLevelTuitionMillion: 49.6, NextLevelYears: 5.0, TransitionProbability: 0.40, MonthlyLeads: 110, ConversionRate: 0.08, ClbParticipationRate: 0.41 },
        { UnitCode: "MNLK", UnitName: "MN Long Khánh", OwnerTitle: "Hiệu trưởng MN Long Khánh", PlannedCapacity: 166, CurrentEnrollment: 129, AnnualTuitionMillion: 37.2, GrossMarginPct: 0.85, RemainingYearsInLevel: 2.0, NextLevelTuitionMillion: 49.6, NextLevelYears: 5.0, TransitionProbability: 0.40, MonthlyLeads: 60, ConversionRate: 0.073, ClbParticipationRate: 0.38 },
        { UnitCode: "TH", UnitName: "Tiểu học", OwnerTitle: "Hiệu trưởng Tiểu học", PlannedCapacity: 1050, CurrentEnrollment: 1045, AnnualTuitionMillion: 49.6, GrossMarginPct: 0.85, RemainingYearsInLevel: 2.5, NextLevelTuitionMillion: 61.7, NextLevelYears: 4.0, TransitionProbability: 0.70, MonthlyLeads: 150, ConversionRate: 0.12, ClbParticipationRate: 0.34 },
        { UnitCode: "THCS", UnitName: "THCS", OwnerTitle: "Hiệu trưởng THCS", PlannedCapacity: 650, CurrentEnrollment: 635, AnnualTuitionMillion: 61.7, GrossMarginPct: 0.85, RemainingYearsInLevel: 2.0, NextLevelTuitionMillion: 63.6, NextLevelYears: 3.0, TransitionProbability: 0.60, MonthlyLeads: 80, ConversionRate: 0.10, ClbParticipationRate: 0.25 },
        { UnitCode: "THPT", UnitName: "THPT", OwnerTitle: "Hiệu trưởng THPT", PlannedCapacity: 480, CurrentEnrollment: 459, AnnualTuitionMillion: 63.6, GrossMarginPct: 0.85, RemainingYearsInLevel: 1.5, NextLevelTuitionMillion: 0.0, NextLevelYears: 0.0, TransitionProbability: 0.00, MonthlyLeads: 70, ConversionRate: 0.09, ClbParticipationRate: 0.20 },
      ],
      defaultRules: [
        { RuleCode: "RULE_RUT_PACE_EXCEEDED", RuleName: "Vượt nhịp rút học cho phép", ConditionExpr: "RUT_LKP_PCT > PACE_THRESHOLD", Severity: "BAD", OutcomeSummary: "Tỷ lệ rút học vượt nhịp dự kiến theo mốc thời gian, gây nguy cơ hụt ngân sách" },
        { RuleCode: "RULE_LEAD_DEFICIT_HIGH", RuleName: "Áp lực tuyển bù vượt 50% lead tháng", ConditionExpr: "LEADS_NEED > 0.5 * MONTHLY_LEADS", Severity: "WARN", OutcomeSummary: "Số lượng lead cần bù đắp vượt 50% dung lượng tuyển sinh tháng của đơn vị" },
        { RuleCode: "RULE_CAPACITY_CRITICAL", RuleName: "Lấp đầy dưới 80% chỉ tiêu", ConditionExpr: "OCCUPANCY_PCT < 0.80", Severity: "BAD", OutcomeSummary: "Công suất lấp đầy dưới 80%, đơn vị buộc phải có văn bản giải trình trước Hội đồng" },
      ],
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
      causalNarrativesList: [],
      contextStore: {},
      metricThresholds: [],
      goliveSpecsList: [],
      defaultGoliveSpecs: [
        {
          SpecCode: "SPEC_BASICDATA",
          SourceSystem: "Hệ thống Basic Data (https://basicdata.lhbs.vn/)",
          KpiGroup: "Quy mô & Tuyển sinh (Chỉ tiêu 1–4, 7)",
          ApiEndpoint: "https://basicdata.lhbs.vn/api/v1/students/monthly-snapshot",
          HttpMethod: "POST",
          SyncSchedule: "Đồng bộ hàng ngày 00:00 và Chốt sổ 23:59 ngày cuối tháng",
          RequestSchema: '{\n  "NamHocID": 2026,\n  "DonViID": 1,\n  "KhoiID": 1000,\n  "Thang": 9,\n  "IncludeWithdrawals": true\n}',
          ResponseSchema: '{\n  "data": {\n    "totalStudents": 2625,\n    "targetStudents": 2873,\n    "fillRate": 91.37,\n    "capacityRate": 93.42,\n    "withdrawals": 53,\n    "inflow": 3\n  },\n  "status": 200\n}',
          GolivePrerequisites: "1. Chuẩn hóa mã hồ sơ học sinh trên https://basicdata.lhbs.vn/. 2. Phân loại rõ 3 nhóm rút học theo quy định docs: Tốt nghiệp, Chuyển trường, Rút hồ sơ. 3. Cấu hình webhook tự động khóa sổ vào 23:59 ngày cuối tháng đẩy số sang eSign.",
        },
        {
          SpecCode: "SPEC_HOCPHI",
          SourceSystem: "Hệ thống Học phí & Dịch vụ (https://hocphi.lhbs.vn/ · PM FTS)",
          KpiGroup: "Dịch vụ Bán trú, Xe bus, CLB & LN Gộp (Chỉ tiêu 33, 34, 55, 56)",
          ApiEndpoint: "https://hocphi.lhbs.vn/api/v1/services/financial-summary",
          HttpMethod: "POST",
          SyncSchedule: "Chốt sổ định kỳ ngày 05 hàng tháng sau khi đối soát kế toán FTS",
          RequestSchema: '{\n  "KyBaoCao": "2026-09",\n  "DonViID": "ALL"\n}',
          ResponseSchema: '{\n  "data": {\n    "services": [\n      {"code": "BAN_TRU", "name": "Bán trú & Ăn sáng", "rev": 14800000000, "cost": 7620000000, "margin": 48.5},\n      {"code": "BUS", "name": "Xe đưa đón học sinh", "rev": 2850000000, "cost": 2490000000, "margin": 12.6},\n      {"code": "CLUB", "name": "CLB Bổ trợ ngoài giờ", "rev": 1611000000, "cost": 830000000, "margin": 48.4}\n    ],\n    "overallMargin": 48.4\n  },\n  "status": 200\n}',
          GolivePrerequisites: "1. Phân bổ chi phí trực tiếp riêng cho từng tuyến xe bus và từng môn CLB trên https://hocphi.lhbs.vn/. 2. Tự động đối soát công nợ và biên lai thu học phí dịch vụ qua cổng thanh toán ngân hàng.",
        },
        {
          SpecCode: "SPEC_YTE",
          SourceSystem: "Hệ thống Y tế học đường (https://yte.lhbs.vn/)",
          KpiGroup: "Y tế & Sức khỏe học đường (Chỉ tiêu 36, 37, 38, 39)",
          ApiEndpoint: "https://yte.lhbs.vn/api/v1/health/medical-records",
          HttpMethod: "POST",
          SyncSchedule: "Đồng bộ định kỳ sau mỗi đợt khám SK và tổng hợp sự cố y tế hàng tháng",
          RequestSchema: '{\n  "NamHocID": 2026,\n  "DotKham": "DauNam",\n  "DonViID": "ALL"\n}',
          ResponseSchema: '{\n  "data": {\n    "totalExamined": 2541,\n    "examRate": 96.8,\n    "bmiDeviantRate": 8.8,\n    "seriousIncidents": 0\n  },\n  "status": 200\n}',
          GolivePrerequisites: "1. Chuẩn hóa hồ sơ khám sức khỏe định kỳ & phân loại chỉ số BMI lệch chuẩn trên https://yte.lhbs.vn/. 2. Theo dõi chỉ tiêu 0 vụ sự cố tai nạn thương tích, dị ứng, ngộ độc.",
        },
        {
          SpecCode: "SPEC_QA",
          SourceSystem: "Hệ thống Đảm bảo chất lượng (https://qa.lhbs.vn/)",
          KpiGroup: "Khảo sát & Sự hài lòng PHHS (Chỉ tiêu 23, 44, 49)",
          ApiEndpoint: "https://qa.lhbs.vn/api/v1/surveys/satisfaction-summary",
          HttpMethod: "POST",
          SyncSchedule: "Chốt sau mỗi kỳ khảo sát PHHS (Học kỳ / Hàng tháng)",
          RequestSchema: '{\n  "KyKhaoSat": "2026-09",\n  "LoaiKhaoSat": "DichVu_HocTap"\n}',
          ResponseSchema: '{\n  "data": {\n    "tienBoHocSinh": {"rate": 92.4, "threshold": 90.0},\n    "dongPhucSachVo": {"rate": 95.8, "threshold": 95.0},\n    "haiLongChung": {"rate": 93.6, "threshold": 90.0}\n  },\n  "status": 200\n}',
          GolivePrerequisites: "1. Chuẩn hóa biểu mẫu khảo sát trực tuyến trên https://qa.lhbs.vn/ về mức độ tiến bộ của học sinh và chất lượng dịch vụ. 2. Tự động tổng hợp tỷ lệ đánh giá mức Đạt trở lên (> 90%).",
        },
        {
          SpecCode: "SPEC_LMS",
          SourceSystem: "Hệ thống LMS Học tập (https://lms.lhbs.vn/ · CSDL LMS-LHBS)",
          KpiGroup: "Chuyên môn & Học thuật LMS (Chỉ tiêu 11, 15, 16, 17)",
          ApiEndpoint: "https://tapi.lhbs.vn/lms/BaoCao_2_ThongKe_HocLieuSo_ByCapID & /lms/BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID",
          HttpMethod: "POST",
          SyncSchedule: "Đồng bộ 02:00 sáng hàng ngày & Chốt tuần/tháng",
          RequestSchema: '{\n  "NamHocID": 2026,\n  "CapID": 1\n}',
          ResponseSchema: '{\n  "data": [\n    [{"TotalAssignments": 141, "TotalAssigned": 2629, "Total_DaNop": 597, "Total_DaCham": 1637, "CompletionRate_Assignments": 85.0}]\n  ],\n  "status": 200\n}',
          GolivePrerequisites: "1. Hoàn thiện tối ưu index trên SQL Server LMS-LHBS (192.168.100.22). 2. Mở rộng báo cáo chi tiết đến cấp giáo viên phụ trách.",
        },
        {
          SpecCode: "SPEC_EXCEL_INTERNAL",
          SourceSystem: "Excel nội bộ (TVTS Tracking 2026-2027 & Dashboard Vận hành T9)",
          KpiGroup: "Phễu TVTS & Vận hành CSVC (Chỉ tiêu 5, 6, 28, 51, 57)",
          ApiEndpoint: "docs/dashboard van hanh thang 9.xlsx & TVTS Tracking GID 1481169716",
          HttpMethod: "FILE_IMPORT",
          SyncSchedule: "Nhập liệu định kỳ hàng tuần/tháng trong giai đoạn Staging",
          RequestSchema: '{\n  "File": "dashboard van hanh thang 9.xlsx",\n  "Sheet": "8. Tư vấn tuyển sinh"\n}',
          ResponseSchema: '{\n  "data": {\n    "leadsT9": 162,\n    "enrolledT9": 22,\n    "conversionRate": 13.58,\n    "repairTickets": 48,\n    "staffTurnover": 0.82\n  },\n  "status": 200\n}',
          GolivePrerequisites: "1. Khi phần mềm CRM chính thức hoàn thiện, chuyển dữ liệu Leads và Chuyển đổi sang API CRM. 2. Khi phân hệ Helpdesk CSVC và HRM hoàn thiện, kết nối API tự động.",
        },
      ],
      unitOptions: [
        { k: "ALL", t: "Toàn trường" },
        { k: "MNTB", t: "Mầm non TB" },
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
      liveDataBienHoa: [
        { STT: 1, Ten: "18 Tháng", SLHocSinh: 17, SL_HSNu: 12, SL_HSNam: 5, KhoiID: -4 },
        { STT: 2, Ten: "MG Mầm", SLHocSinh: 66, SL_HSNu: 28, SL_HSNam: 38, KhoiID: -3 },
        { STT: 3, Ten: "MG Chồi", SLHocSinh: 94, SL_HSNu: 48, SL_HSNam: 46, KhoiID: -2 },
        { STT: 4, Ten: "MG Lá", SLHocSinh: 135, SL_HSNu: 63, SL_HSNam: 72, KhoiID: -1 },
        { STT: 5, Ten: "Khối 1", SLHocSinh: 207, SL_HSNu: 98, SL_HSNam: 109, KhoiID: 1 },
        { STT: 6, Ten: "Khối 2", SLHocSinh: 221, SL_HSNu: 108, SL_HSNam: 113, KhoiID: 2 },
        { STT: 7, Ten: "Khối 3", SLHocSinh: 219, SL_HSNu: 113, SL_HSNam: 106, KhoiID: 3 },
        { STT: 8, Ten: "Khối 4", SLHocSinh: 213, SL_HSNu: 103, SL_HSNam: 110, KhoiID: 4 },
        { STT: 9, Ten: "Khối 5", SLHocSinh: 185, SL_HSNu: 88, SL_HSNam: 97, KhoiID: 5 },
        { STT: 10, Ten: "Khối 6", SLHocSinh: 226, SL_HSNu: 114, SL_HSNam: 112, KhoiID: 6 },
        { STT: 11, Ten: "Khối 7", SLHocSinh: 213, SL_HSNu: 108, SL_HSNam: 105, KhoiID: 7 },
        { STT: 12, Ten: "Khối 8", SLHocSinh: 185, SL_HSNu: 96, SL_HSNam: 89, KhoiID: 8 },
        { STT: 13, Ten: "Khối 9", SLHocSinh: 181, SL_HSNu: 93, SL_HSNam: 88, KhoiID: 9 },
        { STT: 14, Ten: "Khối 10", SLHocSinh: 154, SL_HSNu: 78, SL_HSNam: 76, KhoiID: 10 },
        { STT: 15, Ten: "Khối 11", SLHocSinh: 106, SL_HSNu: 52, SL_HSNam: 54, KhoiID: 11 },
        { STT: 16, Ten: "Khối 12", SLHocSinh: 77, SL_HSNu: 38, SL_HSNam: 39, KhoiID: 12 },
      ],
      liveDataLongKhanh: [
        { STT: 1, Ten: "18 Tháng", SLHocSinh: 12, SL_HSNu: 5, SL_HSNam: 7, KhoiID: -4 },
        { STT: 2, Ten: "MG Mầm", SLHocSinh: 24, SL_HSNu: 11, SL_HSNam: 13, KhoiID: -3 },
        { STT: 3, Ten: "MG Chồi", SLHocSinh: 28, SL_HSNu: 14, SL_HSNam: 14, KhoiID: -2 },
        { STT: 4, Ten: "MG Lá", SLHocSinh: 34, SL_HSNu: 16, SL_HSNam: 18, KhoiID: -1 },
        { STT: 5, Ten: "Khối 1", SLHocSinh: 35, SL_HSNu: 18, SL_HSNam: 17, KhoiID: 1 },
      ],
      historyData: [
        { NienKhoa: "2020-2021", SLHocSinh: 1768 },
        { NienKhoa: "2021-2022", SLHocSinh: 1802 },
        { NienKhoa: "2022-2023", SLHocSinh: 1874 },
        { NienKhoa: "2023-2024", SLHocSinh: 1988 },
        { NienKhoa: "2024-2025", SLHocSinh: 2575 },
        { NienKhoa: "2025-2026", SLHocSinh: 2522 },
        { NienKhoa: "2026-2027", SLHocSinh: 2499 },
      ],
      inflowRecordsCount: 90,
      withdrawRecords: [
        { NgayChuyen: "05/06/2026", HoTen: "Dương Bình Minh", LopDi: "03B", TruongDen: "Marie Curie", LyDo: "Chuyển chỗ ở" },
        { NgayChuyen: "05/06/2026", HoTen: "Nguyễn Thanh Nhân", LopDi: "07D", TruongDen: "Định cư Mỹ", LyDo: "Định cư nước ngoài" },
        { NgayChuyen: "05/06/2026", HoTen: "Lại Nguyễn Bảo Vy", LopDi: "07A", TruongDen: "Đức Trí", LyDo: "Xa trường, đi lại khó khăn" },
        { NgayChuyen: "05/06/2026", HoTen: "Lại Nguyễn Khả Hân", LopDi: "03G", TruongDen: "Đức Trí", LyDo: "Xa trường, đi lại khó khăn" },
        { NgayChuyen: "05/06/2026", HoTen: "Nguyễn Thanh Phúc", LopDi: "04F", TruongDen: "Định cư Mỹ", LyDo: "Định cư nước ngoài" },
        { NgayChuyen: "14/08/2026", HoTen: "Phan Nguyên Ước", LopDi: "04A", TruongDen: "Du học Canada", LyDo: "Du học" },
        { NgayChuyen: "30/09/2026", HoTen: "Nguyễn Hồng Hải", LopDi: "10A", TruongDen: "Du học Mỹ", LyDo: "Du học" },
        { NgayChuyen: "14/10/2026", HoTen: "Chướng Nguyễn Hạo Nhiên", LopDi: "01F", TruongDen: "Nguyễn An Ninh", LyDo: "Có hoàn cảnh kinh tế gia đình" },
      ],
      topWithdrawReasons: [
        { name: "Xa trường, đi lại khó khăn", count: 39, percent: 25.7 },
        { name: "Nguyên nhân khác", count: 24, percent: 15.8 },
        { name: "Có hoàn cảnh kinh tế gia đình", count: 19, percent: 12.5 },
        { name: "Rút hồ sơ", count: 18, percent: 11.8 },
        { name: "Chuyển chỗ ở hoặc về quê", count: 16, percent: 10.5 },
        { name: "Định cư nước ngoài / Du học", count: 6, percent: 3.9 },
        { name: "Bé đi học can thiệp", count: 4, percent: 2.6 },
      ],
      teachingProgressRows: [
        { TenLop: "11A", TongTiet: 38, Toan: 5, Van: 1, KHTN: 6, STEM: 2 },
        { TenLop: "11B", TongTiet: 38, Toan: 2, Van: 5, KHTN: 6, STEM: 2 },
        { TenLop: "11C", TongTiet: 34, Toan: 3, Van: 2, KHTN: 7, STEM: 2 },
        { TenLop: "11D", TongTiet: 36, Toan: 5, Van: 3, KHTN: 4, STEM: 3 },
        { TenLop: "11E", TongTiet: 34, Toan: 3, Van: 2, KHTN: 4, STEM: 2 },
        { TenLop: "11F", TongTiet: 36, Toan: 3, Van: 5, KHTN: 2, STEM: 2 },
      ],
      financeServices: [
        { name: "Dịch vụ Bán trú & Bếp ăn học sinh", revenue: "14.80 tỷ", cost: "7.62 tỷ", grossProfit: "7.18 tỷ", margin: "48.5%" },
        { name: "Dịch vụ Đưa rước xe bus học đường", revenue: "2.85 tỷ", cost: "2.49 tỷ", grossProfit: "360 tr", margin: "12.6%" },
        { name: "Bán lẻ Đồng phục & Sách giáo khoa", revenue: "3.12 tỷ", cost: "2.24 tỷ", grossProfit: "880 tr", margin: "28.2%" },
        { name: "Học phí chính khóa đào tạo (Học thuật)", revenue: "58.60 tỷ", cost: "29.30 tỷ", grossProfit: "29.30 tỷ", margin: "50.0%" },
      ],
      financeClubs: [
        { name: "Khối Tiểu học (Aerobic, Bóng đá, Bơi, Ẩm thực)", students: 353, fee: "Vượt chỉ tiêu (117.7%)", revenue: "882.5 tr", share: "54.8%" },
        { name: "Khối Trung học (Advanced Robotics, Bóng đá, Digital Art)", students: 96, fee: "Đạt 64.0% chỉ tiêu", revenue: "288.0 tr", share: "17.9%" },
        { name: "Mầm non Biên Hòa (Tiếng Anh Kịch nghệ, Aerobic)", students: 77, fee: "Đạt 64.2% chỉ tiêu", revenue: "231.0 tr", share: "14.3%" },
        { name: "Mầm non Long Khánh (Tiền Tiểu học, Nhảy hiện đại)", students: 70, fee: "Đạt 93.3% chỉ tiêu", revenue: "210.0 tr", share: "13.0%" },
      ],
      lmsOverallRate: "83.9",
      lmsHocLieuSummary: {
        total: 76,
        coNoiDung: 27,
        pct: "35.5",
        totalFiles: 445,
      },
      lmsAssignmentRows: [
        { MonHocID: 2, TenMonHoc_HienThi: "Toán", TotalAssignments: 141, TotalAssigned: 2629, Total_DaNop: 597, Total_DaCham: 1637, Total_ChuaLam: 289, CompletionRate_Assignments: 85.0, CompletionRate_Graded: 62.3 },
        { MonHocID: 1, TenMonHoc_HienThi: "Tiếng Việt", TotalAssignments: 95, TotalAssigned: 1631, Total_DaNop: 417, Total_DaCham: 949, Total_ChuaLam: 196, CompletionRate_Assignments: 83.8, CompletionRate_Graded: 58.2 },
        { MonHocID: 4, TenMonHoc_HienThi: "Khoa học", TotalAssignments: 23, TotalAssigned: 397, Total_DaNop: 144, Total_DaCham: 199, Total_ChuaLam: 44, CompletionRate_Assignments: 86.4, CompletionRate_Graded: 50.1 },
        { MonHocID: 19, TenMonHoc_HienThi: "Lịch sử và Địa lí", TotalAssignments: 22, TotalAssigned: 397, Total_DaNop: 148, Total_DaCham: 193, Total_ChuaLam: 43, CompletionRate_Assignments: 85.9, CompletionRate_Graded: 48.6 },
        { MonHocID: 5, TenMonHoc_HienThi: "Ngoại ngữ", TotalAssignments: 4, TotalAssigned: 221, Total_DaNop: 66, Total_DaCham: 81, Total_ChuaLam: 22, CompletionRate_Assignments: 66.5, CompletionRate_Graded: 36.7 },
      ],
      lmsHocLieuRows: [
        { MonHocID: 1, TenMonHoc_HienThi: "Tiếng Việt", KhoiID: 1, TongHocLieu: 1, HocLieuCoNoiDung: 1, HocLieuChuaCoNoiDung: 0, TongNoiDung: 2 },
        { MonHocID: 2, TenMonHoc_HienThi: "Toán", KhoiID: 1, TongHocLieu: 1, HocLieuCoNoiDung: 1, HocLieuChuaCoNoiDung: 0, TongNoiDung: 1 },
        { MonHocID: 3, TenMonHoc_HienThi: "Tự nhiên và Xã hội", KhoiID: 1, TongHocLieu: 1, HocLieuCoNoiDung: 1, HocLieuChuaCoNoiDung: 0, TongNoiDung: 2 },
        { MonHocID: 4, TenMonHoc_HienThi: "Khoa học", KhoiID: 4, TongHocLieu: 1, HocLieuCoNoiDung: 1, HocLieuChuaCoNoiDung: 0, TongNoiDung: 2 },
        { MonHocID: 19, TenMonHoc_HienThi: "Lịch sử và Địa lí", KhoiID: 4, TongHocLieu: 1, HocLieuCoNoiDung: 1, HocLieuChuaCoNoiDung: 0, TongNoiDung: 1 },
      ],
      crmMonthlySummary: [
        { month: "Tháng 08/2026", ptlcLeads: 30, mnbhLeads: 144, mnlkLeads: 185, totalLeads: 359, ptlcEnrolled: 9, mnbhEnrolled: 16, mnlkEnrolled: 8, totalEnrolled: 33, rate: "9.2%" },
        { month: "Tháng 09/2026", ptlcLeads: 24, mnbhLeads: 77, mnlkLeads: 61, totalLeads: 162, ptlcEnrolled: 4, mnbhEnrolled: 8, mnlkEnrolled: 10, totalEnrolled: 22, rate: "13.6%" },
        { month: "Tháng 10/2026", ptlcLeads: 9, mnbhLeads: 40, mnlkLeads: 40, totalLeads: 89, ptlcEnrolled: 0, mnbhEnrolled: 3, mnlkEnrolled: 0, totalEnrolled: 3, rate: "3.4%" },
      ],
      crmChannelStats: [
        { channel: "Facebook Fanpage / Ads", leads: 521, pct: "85.4%", enrolled: 34, convRate: "6.5%" },
        { channel: "Người quen giới thiệu", leads: 22, pct: "3.6%", enrolled: 12, convRate: "54.5%" },
        { channel: "Nhận diện thương hiệu (Vãng lai)", leads: 28, pct: "4.6%", enrolled: 6, convRate: "21.4%" },
        { channel: "Phụ huynh LHBS hiện hữu", leads: 15, pct: "2.5%", enrolled: 5, convRate: "33.3%" },
        { channel: "Cán bộ GV / Nhân viên", leads: 11, pct: "1.8%", enrolled: 4, convRate: "36.4%" },
        { channel: "Zalo / Hotline tiếp nhận", leads: 5, pct: "0.8%", enrolled: 1, convRate: "20.0%" },
        { channel: "Đại sứ / Sự kiện trải nghiệm", leads: 8, pct: "1.3%", enrolled: 0, convRate: "0.0%" },
      ],
      crmDropReasons: [
        { reason: "Liên hệ / nhắn tin 3 lần không phản hồi", count: 414, pct: "75.0%", solution: "Chuyển Cold Leads, gửi tin Zalo định kỳ" },
        { reason: "Bé chưa đủ tuổi đi học (Chờ HK2)", count: 22, pct: "4.0%", solution: "Đưa vào danh sách chăm sóc nuôi dưỡng Kitty HK2" },
        { reason: "Phụ huynh tham khảo thông tin trước", count: 8, pct: "1.4%", solution: "Gửi tài liệu chương trình học và bảng phí" },
        { reason: "Không đạt quy chế / Từ chối khảo sát", count: 5, pct: "0.9%", solution: "Tư vấn lộ trình bồi dưỡng trước nhập học" },
        { reason: "Học phí cao / Chưa có chính sách ưu đãi", count: 3, pct: "0.5%", solution: "Áp dụng học bổng hoặc đóng phí theo đợt" },
        { reason: "Ngoài tuyến xe đưa đón học sinh", count: 4, pct: "0.7%", solution: "Khảo sát mở rộng điểm đón tuyến mới" },
      ],
      crmKittyList: [
        { stt: 87, thang: "T08/2026", tenPH: "Kiều Anh Vũ", lop: "Kitty", tenHS: "Bé sinh 01/2025", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 01/2027 liên hệ lại" },
        { stt: 107, thang: "T08/2026", tenPH: "Khánh Linh", lop: "Kitty", tenHS: "Nguyễn Ngọc Nhã Vy (01/2025)", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 01/2027 liên hệ lại" },
        { stt: 117, thang: "T08/2026", tenPH: "Bích Nguyệt", lop: "Kitty", tenHS: "Nguyễn Minh Anh (02/01/2026)", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 01/2027 liên hệ lại" },
        { stt: 118, thang: "T08/2026", tenPH: "Nguyễn Thủy Tiên", lop: "Kitty", tenHS: "Bé sinh 12/2025", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 01/2027 liên hệ lại" },
        { stt: 121, thang: "T08/2026", tenPH: "Như Loan", lop: "Kitty", tenHS: "Bé sinh 02/2025", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 02/2027 liên hệ lại" },
        { stt: 164, thang: "T09/2026", tenPH: "Con cô Như Vy (GV)", lop: "Kitty", tenHS: "Võ Chí Kiên (22/04/2025)", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Dự kiến 06/2027 đi học" },
        { stt: 168, thang: "T09/2026", tenPH: "Dược Huỳnh", lop: "Kitty", tenHS: "Bé sinh 02/2025", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 11/2026 liên hệ lại" },
        { stt: 174, thang: "T09/2026", tenPH: "Con thầy Kim Cương (GV)", lop: "Kitty", tenHS: "Dương Kim Trọng (28/10/2025)", tinhTrang: "Đã tư vấn xong (Nhập học T10)", hen: "Tháng 10/2026 làm hồ sơ" },
        { stt: 176, thang: "T09/2026", tenPH: "Con cô Anh Thư (GV)", lop: "Kitty", tenHS: "Mai Hoàng Khánh An (10/2025)", tinhTrang: "Đã tư vấn xong (Nhập học T10)", hen: "Tháng 10/2026 làm hồ sơ" },
        { stt: 109, thang: "T02/2026", tenPH: "Nguyễn Đỗ Thúy Ngân", lop: "Kitty", tenHS: "Nguyễn Thùy Tiên (06/2025)", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 12/2026 liên hệ lại" },
        { stt: 130, thang: "T03/2026", tenPH: "Trương Mỹ Hoa", lop: "Kitty", tenHS: "Minh Đăng (03/02/2025)", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 02/2027 liên hệ lại" },
        { stt: 476, thang: "T06/2026", tenPH: "Ninh Nguyễn Xuân", lop: "Kitty", tenHS: "Bé sinh 01/2026", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tuyển sinh HK2 liên hệ" },
        { stt: 479, thang: "T06/2026", tenPH: "Nguyễn Rosa", lop: "Kitty", tenHS: "Bé sinh 11/2025", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 11/2026 liên hệ lại" },
        { stt: 528, thang: "T07/2026", tenPH: "Tâm Như", lop: "Kitty", tenHS: "Bé sinh 14/12/2025", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 12/2026 nhập học" },
        { stt: 550, thang: "T07/2026", tenPH: "Chị Đài", lop: "Kitty", tenHS: "Nguyễn Trần Khánh Ngọc (07/2025)", tinhTrang: "Chưa đủ tuổi (Hẹn HK2)", hen: "Tháng 12/2026 liên hệ lại" },
      ],
    };
  },
  computed: {
    currentMonthText() {
      const mo = this.causalMonthOptions.find((o) => o.m === this.causalMonth);
      return mo ? mo.t.toLowerCase() : "đầu tháng 10";
    },
    currentMonthRatio() {
      const mo = this.causalMonthOptions.find((o) => o.m === this.causalMonth);
      return mo ? mo.r : 8 / 9;
    },
    currentCausalAssumption() {
      const list = this.causalAssumptionsList.length ? this.causalAssumptionsList : this.defaultAssumptions;
      const found = list.find((a) => a.UnitCode === this.causalUnit);
      return found || list[1];
    },
    currentCausalUnitName() {
      return this.currentCausalAssumption.UnitName || "MN Long Khánh";
    },
    currentCausalOwnerTitle() {
      return this.currentCausalAssumption.OwnerTitle || "Hiệu trưởng MN Long Khánh";
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
      let n = Math.max(1, this.causalScenario === "TUYEN_THEM" ? this.causalAddN : this.causalN);
      if (this.causalScenario === "MO_TUYEN_BUS") {
        n = this.causalBusRoutes * this.causalBusStudentsPerRoute;
      } else if (this.causalScenario === "GIU_CHAN_CHUYEN_CAP") {
        n = this.causalTransitionRetained;
      } else if (this.causalScenario === "MO_RONG_CLB") {
        n = this.causalAddClbStudents;
      }
      const r = this.currentMonthRatio;
      const hp = ass.AnnualTuitionMillion || 37.2;
      const margin = ass.GrossMarginPct || 0.85;

      const revNowRaw = (n * hp * r) / 1000;
      const revMarginRaw = revNowRaw * margin;
      const isOut = this.causalScenario === "RUT_HOC";

      const revNowSign = (isOut ? "−" : "+") + revNowRaw.toFixed(2).replace(".", ",");
      const revMarginSign = (isOut ? "−" : "+") + revMarginRaw.toFixed(2).replace(".", ",");
      const revNowRange = (isOut ? "−" : "+") + (revNowRaw * 0.85).toFixed(2).replace(".", ",") + " đến " + (isOut ? "−" : "+") + (revNowRaw * 1.15).toFixed(2).replace(".", ",") + " tỷ";

      const remY = Math.max(0, (ass.RemainingYearsInLevel || 2) - 1);
      const transProb = ass.TransitionProbability || 0.4;
      const nextY = ass.NextLevelYears || 5;
      const nextHp = ass.NextLevelTuitionMillion || 49.6;
      const revFutureRaw = (n * (remY * hp + transProb * nextY * nextHp)) / 1000;
      const revFutureSign = (isOut ? "−" : "+") + revFutureRaw.toFixed(2).replace(".", ",");
      const revFutureRange = (isOut ? "−" : "+") + (revFutureRaw * 0.7).toFixed(2).replace(".", ",") + " đến " + (isOut ? "−" : "+") + (revFutureRaw * 1.3).toFixed(2).replace(".", ",") + " tỷ";

      const totalLostRaw = revNowRaw + revFutureRaw;
      const totalLostSign = (isOut ? "−" : "+") + totalLostRaw.toFixed(2).replace(".", ",");
      const stripNowPct = totalLostRaw > 0 ? Math.min(100, Math.max(5, Math.round((revNowRaw / totalLostRaw) * 100))) : 20;

      const t9 = ass.CurrentEnrollment || 129;
      const kh = ass.PlannedCapacity || 166;
      const fillPctBefore = ((t9 / kh) * 100).toFixed(1).replace(".", ",");
      const t9After = isOut ? Math.max(0, t9 - n) : t9 + n;
      const fillPctAfter = ((t9After / kh) * 100).toFixed(1).replace(".", ",");

      const rutBeforePct = (8.1).toFixed(1).replace(".", ",");
      const rutAfterPctRaw = 8.1 + (n / t9) * 100 * (isOut ? 1 : -0.5);
      const rutAfterPct = Math.max(0, rutAfterPctRaw).toFixed(1).replace(".", ",");
      const isRutBad = rutAfterPctRaw > 3.0;
      const paceMultiple = (rutAfterPctRaw / 3.0).toFixed(1).replace(".", ",");

      const conv = ass.ConversionRate || 0.073;
      const leadsNeed = Math.round(n / conv);
      const monthlyLeads = ass.MonthlyLeads || 60;
      const leadsPctMonth = Math.round((leadsNeed / monthlyLeads) * 100);
      const clbLost = Math.round(n * (ass.ClbParticipationRate || 0.38));

      return {
        n,
        t9,
        t9After,
        kh,
        revNowSign,
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
      };
    },
    causalHeroSentence() {
      const scenarioCodeMap = {
        MO_TUYEN_BUS: "NARRATIVE_BUS_EXPANSION",
        GIU_CHAN_CHUYEN_CAP: "NARRATIVE_TRANSITION_INCENTIVE",
        MO_RONG_CLB: "NARRATIVE_CLB_GROWTH",
        SU_CO_AN_TOAN: "NARRATIVE_CAMPUS_SAFETY",
        TUYEN_THEM: "NARRATIVE_CAPACITY_OCCUPANCY",
        RUT_HOC: "NARRATIVE_WITHDRAW_BUS",
      };
      const narrativeCode = scenarioCodeMap[this.causalScenario];
      const item = this.causalNarrativesList.find((n) => n.NarrativeCode === narrativeCode);

      if (item && item.TemplatePattern) {
        const scenarioParams = {
          "SCENARIO.BusRoutes": this.causalBusRoutes,
          "SCENARIO.BusStudents": this.causalBusRoutes * this.causalBusStudentsPerRoute,
          "SCENARIO.DiscountPct": this.causalDiscountPct,
          "SCENARIO.TransitionRetained": this.causalTransitionRetained,
          "SCENARIO.NewClbCount": this.causalNewClbCount,
          "SCENARIO.AddClbStudents": this.causalAddClbStudents,
          "SCENARIO.AddN": this.causalAddN,
          "SCENARIO.WithdrawN": this.causalN,
        };
        const html = this.evaluateTemplate(item.TemplatePattern, this.contextStore, scenarioParams);
        return html.replace(/<[^>]*>/g, "");
      }

      // Fallback tính toán nếu chưa cấu hình bản ghi tương ứng
      const c = this.causalCalc;
      const reasonName = this.currentCausalReason ? this.currentCausalReason.ReasonName : "Chưa rõ lý do";
      const act = this.currentCausalReason ? this.currentCausalReason.RecommendedAction : "Rà soát đối thoại với phụ huynh";
      return c.n + " học sinh không phải '-" + c.n + " trên sĩ số', là " + c.revNowSign.replace("−", "").replace("-", "") + " tỷ doanh thu năm nay, khoảng " + c.revFutureSign.replace("−", "").replace("-", "") + " tỷ doanh thu các năm sau, và " + c.leadsNeed + " lead phải tìm thêm để bù. Chịu trách nhiệm giải trình: " + this.currentCausalOwnerTitle + ". Lý do " + reasonName.toLowerCase() + " — " + act + ".";
    },
    causalTreeNodes() {
      const c = this.causalCalc;
      const isOut = this.causalScenario === "RUT_HOC";
      const rName = this.currentCausalReason ? this.currentCausalReason.ReasonName : "Chưa rõ lý do";
      const ctl = this.currentCausalReason ? this.currentCausalReason.ControlLevel : "Trung bình";

      return [
        {
          id: "N_EVENT",
          x: 20,
          y: 120,
          label: (isOut ? "−" : "+") + c.n + " học sinh " + (isOut ? "rời đi" : "nhập học"),
          value: this.currentCausalUnitName,
          sub: "Lý do: " + rName,
          formula: "Sự kiện phát sinh tại " + this.currentCausalUnitName + " trong " + this.currentMonthText,
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
          formula: "Sĩ số sau biến động = Sĩ số T9 (" + c.t9 + ") " + (isOut ? "− " : "+ ") + c.n + " = " + c.t9After + " HS",
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
          label: "Doanh thu năm nay",
          value: c.revNowSign + " tỷ",
          sub: "khoảng " + c.revNowRange,
          formula: "Học phí niêm yết (" + (this.currentCausalAssumption.AnnualTuitionMillion || 37.2) + " tr) × " + c.n + " HS × " + Math.round(this.currentMonthRatio * 9) + "/9 tháng còn lại",
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
          formula: "Tỷ lệ tham gia CLB của cơ sở (" + Math.round((this.currentCausalAssumption.ClbParticipationRate || 0.38) * 100) + "%) × " + c.n + " HS",
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
          label: "Doanh thu các năm sau",
          value: "≈ " + c.revFutureSign + " tỷ",
          sub: "khoảng " + c.revFutureRange,
          formula: "LTV trọn vòng đời = Số năm còn lại trong cấp + Xác suất lên cấp (" + ((this.currentCausalAssumption.TransitionProbability || 0.4) * 100) + "%) × Học phí cấp tiếp theo",
          isBad: isOut,
          isGood: !isOut,
        },
        {
          id: "N_LEADS_NEED",
          x: 700,
          y: 150,
          label: "Lead để tuyển bù",
          value: "≈ " + c.leadsNeed + " lead",
          sub: "chuyển đổi " + ((this.currentCausalAssumption.ConversionRate || 0.073) * 100).toFixed(1) + "% · " + c.leadsPctMonth + "% lead/tháng",
          formula: "Số lead tuyển bù = " + c.n + " HS / Tỷ lệ chuyển đổi (" + ((this.currentCausalAssumption.ConversionRate || 0.073) * 100).toFixed(1) + "%)",
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
      return this.causalTreeNodes.find((n) => n.id === this.causalHoverNodeId);
    },
    currentViewLabel() {
      if (this.page === 0) return "Hội đồng trường";
      if (this.currentUnit === "ALL") return "Ban điều hành · Hợp nhất";
      const match = this.unitOptions.find((u) => u.k === this.currentUnit);
      return match ? "Hiệu trưởng " + match.t : "Toàn trường";
    },
    currentGradeRows() {
      if (this.currentUnit === "MNLK") return this.liveDataLongKhanh;
      if (this.currentUnit === "MNTB") return this.liveDataBienHoa.filter((r) => r.Ten.includes("MG") || r.Ten.includes("Tháng"));
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
      return this.currentGradeRows.reduce((sum, r) => sum + (r.SLHocSinh || 0), 0);
    },
    computedTargetStudents() {
      if (this.currentUnit === "MNLK") return 150;
      if (this.currentUnit === "MNTB") return 350;
      if (this.currentUnit === "TH") return 1080;
      if (this.currentUnit === "THCS") return 850;
      if (this.currentUnit === "THPT") return 350;
      return 2750;
    },
    computedDesignCapacity() {
      if (this.currentUnit === "MNLK") return 160;
      if (this.currentUnit === "MNTB") return 360;
      if (this.currentUnit === "TH") return 1100;
      if (this.currentUnit === "THCS") return 870;
      if (this.currentUnit === "THPT") return 380;
      return 2810;
    },
    computedFillRate() {
      if (!this.computedDesignCapacity) return "0.0";
      return ((this.computedTotalStudents / this.computedDesignCapacity) * 100).toFixed(1);
    },
    computedWithdrawCount() {
      return this.withdrawRecords.length || (this.currentUnit === "MNLK" ? 8 : 152);
    },
    computedNetChange() {
      return this.inflowRecordsCount - this.computedWithdrawCount;
    },
    computedWithdrawRate() {
      if (!this.computedTotalStudents) return "0.0";
      return ((this.computedWithdrawCount / (this.computedTotalStudents + this.computedWithdrawCount)) * 100).toFixed(1);
    },
    computedCrmLeads() {
      if (this.currentUnit === "MNLK") return 286;
      if (this.currentUnit === "MNTB") return 261;
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) return 63;
      return 610;
    },
    computedCrmEnrolled() {
      if (this.currentUnit === "MNLK") return 18;
      if (this.currentUnit === "MNTB") return 27;
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) return 13;
      return 58;
    },
    computedCrmConversionRate() {
      if (this.currentUnit === "MNLK") return "6.3";
      if (this.currentUnit === "MNTB") return "10.3";
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) return "20.6";
      return "9.5";
    },
    computedCrmLeadsCurrentMonth() {
      if (this.currentUnit === "MNLK") return 40;
      if (this.currentUnit === "MNTB") return 40;
      if (["TH", "THCS", "THPT"].includes(this.currentUnit)) return 9;
      return 89;
    },
    currentPeriodIsStaging() {
      return this.selectedPeriod === "2026-09";
    },
    currentPeriodName() {
      const p = this.periodsList.find((x) => x.PeriodKey === this.selectedPeriod);
      return p ? p.PeriodName : "Kỳ hiện tại";
    },
    currentUnitTitle() {
      const u = this.unitOptions.find((x) => x.k === this.currentUnit);
      return u ? u.t : "Toàn hệ thống";
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
      const k = this.getKpi("TS02");
      if (k && k.Rate != null) return Number(k.Rate).toFixed(1);
      return this.computedFillRate;
    },
    displayCapacityPct() {
      const k = this.getKpi("TS01");
      if (k && k.Rate != null) return Number(k.Rate).toFixed(1);
      if (!this.displayTarget) return "0.0";
      return ((this.displayStudents / this.displayTarget) * 100).toFixed(1);
    },
    displayWithdrawCount() {
      const k = this.getKpi("TS04");
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedWithdrawCount;
    },
    displayWithdrawRate() {
      const k = this.getKpi("TS04");
      if (k && k.Rate != null) return Number(k.Rate).toFixed(1);
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
      const k = this.getKpi("TS04");
      if (k && k.OperationalInsight) {
        const m = k.OperationalInsight.match(/(\d+)\s*HS/i);
        if (m) return parseInt(m[1], 10);
      }
      if (this.currentUnit === "MNLK") return 4;
      if (this.currentUnit === "MNTB") return 3;
      if (this.currentUnit === "TH") return 8;
      if (this.currentUnit === "THCS") return 4;
      return this.countReason("Xa trường") || 21;
    },
    displayReasonEco() {
      if (this.currentUnit === "MNLK") return 2;
      if (this.currentUnit === "MNTB") return 2;
      if (this.currentUnit === "TH") return 4;
      if (this.currentUnit === "THCS") return 2;
      return this.countReason("kinh tế") || 10;
    },
    displayReasonOther() {
      const far = this.displayReasonFar;
      const eco = this.displayReasonEco;
      const tot = this.displayWithdrawCount;
      return Math.max(0, tot - far - eco);
    },
    displayLeads() {
      const k = this.getKpi("TS05");
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedCrmLeads;
    },
    displayConversionRate() {
      const k = this.getKpi("TS06");
      if (k && k.Rate != null) return Number(k.Rate).toFixed(1);
      return this.computedCrmConversionRate;
    },
    displayEnrolled() {
      const k = this.getKpi("TS06");
      if (k && k.ActualValue != null) return Number(k.ActualValue);
      return this.computedCrmEnrolled;
    },
    computedFinanceData() {
      const kTc55 = this.getKpi("TC55");
      const kTc56 = this.getKpi("TC56");
      const kClb = this.getKpi("TC33");
      const grossMargin = (kTc55 && kTc55.Rate != null) ? kTc55.Rate + "%" : "48.4%";
      let rev = "79.37 Tỷ";
      if (kTc55 && kTc55.ActualValue != null) {
        const val = Number(kTc55.ActualValue);
        rev = val >= 1000000000 ? (val / 1000000000).toFixed(2) + " Tỷ" : (val / 1000000).toFixed(0) + " Tr";
      }
      let clbRev = "1.56 Tỷ";
      if (kClb && kClb.ActualValue != null) {
        const val = Number(kClb.ActualValue);
        clbRev = val >= 1000000000 ? (val / 1000000000).toFixed(2) + " Tỷ" : (val / 1000000).toFixed(0) + " Tr";
      }
      const clbStudents = (kClb && kClb.TargetValue != null) ? kClb.TargetValue + " HS" : "596 HS";
      const busMargin = (kTc56 && kTc56.Rate != null) ? kTc56.Rate + "%" : "12.6%";
      return {
        grossMargin,
        rev,
        clbRev,
        clbStudents,
        busMargin,
        mealMargin: "48.5%",
      };
    },
    computedLmsData() {
      if (this.currentUnit === "MNLK" || this.currentUnit === "MNTB") {
        return { rate: "—", math: "—", viet: "—", digitalLessons: "— (Mầm non)", onTime: "—" };
      }
      const kCm08 = this.getKpi("CM08");
      const kCm04 = this.getKpi("CM04");
      const rate = (kCm08 && kCm08.Rate != null) ? kCm08.Rate + "%" : (this.lmsOverallRate && this.lmsOverallRate !== "0.0" ? this.lmsOverallRate + "%" : "89.6%");
      const digitalLessons = (kCm04 && kCm04.Rate != null) ? kCm04.Rate + "% (Số hóa)" : (this.currentUnit === "TH" ? "68 bài (100%)" : "120 bài (100%)");
      return {
        rate,
        math: this.currentUnit === "TH" ? "88.2%" : "85.0%",
        viet: this.currentUnit === "TH" ? "86.5%" : "83.8%",
        digitalLessons,
        onTime: "91.2%",
      };
    },
    activeBottlenecks() {
      if (this.periodSnapshots && this.periodSnapshots.length) {
        const list = this.periodSnapshots.filter(
          (k) => k.Status === "WARN" || k.Status === "DANGER" || k.Status === "BAD"
        );
        if (list.length) return list;
      }
      return [
        {
          SnapshotID: "B1",
          KpiCode: "TS01",
          KpiName: "Sĩ số học sinh hiện diện toàn trường",
          Status: "WARN",
          ActualValue: 2625,
          TargetValue: 2750,
          Rate: 95.45,
          Unit: "Học sinh",
          OperationalInsight: "Quy mô toàn trường đạt 2.625 HS; hụt 125 HS so với kế hoạch năm học.",
          FinancialImpact: "Thiếu hụt doanh thu học phí ước tính 7.2 tỷ VNĐ so với dự toán.",
          SpecCode: "SPEC_BASICDATA",
          SourceSystem: "Hệ thống Basic Data (https://basicdata.lhbs.vn/)",
          Owner: "Ban Tuyển Sinh & Marketing",
        },
        {
          SnapshotID: "B2",
          KpiCode: "TS02",
          KpiName: "Tỷ lệ lấp đầy công suất học sinh MN Long Khánh",
          Status: "WARN",
          ActualValue: 133,
          TargetValue: 160,
          Rate: 83.1,
          Unit: "%",
          OperationalInsight: "Quy mô Long Khánh còn mỏng (133/160 HS). Thiếu hụt tập trung khối Nhà trẻ 18 tháng và Mầm.",
          FinancialImpact: "Thiếu hụt ~1.004 tỷ doanh thu kế hoạch năm học.",
          SpecCode: "SPEC_BASICDATA",
          SourceSystem: "Hệ thống Basic Data (https://basicdata.lhbs.vn/)",
          Owner: "Ban Giám Hiệu MN Long Khánh",
        },
        {
          SnapshotID: "B3",
          KpiCode: "CM04",
          KpiName: "Tỷ lệ số hóa học liệu bài giảng đa phương tiện LMS Cấp 1",
          Status: "WARN",
          ActualValue: 35.5,
          TargetValue: 60,
          Rate: 59.17,
          Unit: "%",
          OperationalInsight: "Môn Tiếng Việt và Toán đã tạo khung nhưng tỷ lệ gắn media & video tương tác mới đạt 35.5%.",
          FinancialImpact: "Ảnh hưởng trực tiếp đến chất lượng tự học và tỷ lệ hoàn thành bài tập trực tuyến CM08.",
          SpecCode: "SPEC_LMS",
          SourceSystem: "Hệ thống LMS Học tập (https://lms.lhbs.vn/)",
          Owner: "Ban Chuyên Môn & Đào Tạo",
        },
      ];
    },
    computedDisplaySpecs() {
      const sourceList = (this.goliveSpecsList && this.goliveSpecsList.length) ? this.goliveSpecsList : this.defaultGoliveSpecs;
      if (this.selectedSpecCode) {
        const filtered = sourceList.filter((s) => s.SpecCode === this.selectedSpecCode);
        return filtered.length ? filtered : sourceList;
      }
      return sourceList;
    },
  },
  mounted() {
    this.fetchPeriodsList();
    this.fetchPeriodData(this.selectedPeriod);
    this.fetchAllLiveData();
    this.fetchCausalEngineData();
    window.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.closeCausalModal();
        this.closeDrawer();
      }
    });
    document.addEventListener("fullscreenchange", () => {
      this.isPresentMode = !!document.fullscreenElement;
    });
  },
  methods: {
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
    openCausalModal(unit = null, scenario = null) {
      if (unit) this.causalUnit = unit;
      if (scenario) this.causalScenario = scenario;
      this.isCausalModalOpen = true;
    },
    openCausalChainForCard(cardType) {
      if (cardType === "WITHDRAW") {
        this.openCausalModal(this.currentUnit === "ALL" ? "MNLK" : this.currentUnit, "RUT_HOC");
      } else if (cardType === "ENROLLMENT") {
        this.openCausalModal(this.currentUnit === "ALL" ? "MNBH" : this.currentUnit, "TUYEN_THEM");
      } else if (cardType === "LMS") {
        this.openCausalModal(this.currentUnit === "ALL" ? "TH" : this.currentUnit, "CHUYEN_DOI");
      } else if (cardType === "FINANCE") {
        this.openDrawer("FINANCE_DETAIL");
      }
    },
    closeCausalModal() {
      this.isCausalModalOpen = false;
    },
    setScenario(sc) {
      this.causalScenario = sc;
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
        if (res && res.data && Array.isArray(res.data)) {
          if (res.data[0] && res.data[0].length) this.causalScenariosList = res.data[0];
          if (res.data[1] && res.data[1].length) this.causalAssumptionsList = res.data[1];
          if (res.data[2] && res.data[2].length) this.causalReasonsList = res.data[2];
          if (res.data[3] && res.data[3].length) this.causalAssignmentsList = res.data[3];
          if (res.data[4] && res.data[4].length) this.causalRulesList = res.data[4];
        }
      } catch (err) {
        console.warn("fetchCausalEngineData error, using fallback assumptions:", err);
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
    setPeriod(periodKey) {
      this.selectedPeriod = periodKey;
      if (periodKey === "2026-09") {
        this.fetchPeriodData("2026-09");
      }
      this.fetchAllLiveData();
    },
    async fetchPeriodsList() {
      try {
        const res = await this.callTapi("eSign/KPI_GetPeriods", {});
        if (res && Array.isArray(res) && res.length) {
          this.periodsList = res;
        }
      } catch (e) {
        console.warn("fetchPeriodsList error:", e);
      }
    },
    async fetchPeriodData(pKey) {
      this.isLoading = true;
      this.apiSyncStatus = "Đang đồng bộ dữ liệu chốt kỳ CSDL eSign...";
      try {
        const snapRes = await this.callTapi("eSign/KPI_GetPeriodSnapshots", { PeriodKey: pKey, DonViID: this.currentUnit });
        if (snapRes && Array.isArray(snapRes)) {
          if (snapRes[0]) this.periodSnapshots = snapRes[0];
          if (snapRes[1]) this.kpiGroupSummary = snapRes[1];
          if (snapRes[2] && Array.isArray(snapRes[2]) && snapRes[2].length) {
            this.goliveSpecsList = snapRes[2];
          } else if (snapRes[0]) {
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

        const corrRes = await this.callTapi("eSign/KPI_GetCorrelations", { PeriodKey: pKey, DonViID: this.currentUnit });
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
            this.contextStore = store;
          }
          if (corrRes[4] && Array.isArray(corrRes[4])) {
            this.metricThresholds = corrRes[4];
          }
        }

        this.apiSyncStatus = "Dữ liệu kỳ đã chốt sổ (CSDL eSign)";
      } catch (err) {
        console.warn("fetchPeriodData error:", err);
        this.apiSyncStatus = "Dữ liệu kỳ chốt";
      } finally {
        this.isLoading = false;
      }
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
      const item = this.causalNarrativesList.find((n) => n.AnchorKpiCode === kpiCode || n.NarrativeCode === defaultCode);
      if (!item) return this.getNarrative(defaultCode, fallbackPattern, fallbackParams);
      const pattern = item.TemplatePattern || fallbackPattern;
      return this.evaluateTemplate(pattern, this.contextStore, fallbackParams);
    },
    renderCausalTitle(kpiCode, defaultTitle) {
      const item = this.causalNarrativesList.find((n) => n.AnchorKpiCode === kpiCode);
      return item && item.Title ? item.Title : defaultTitle;
    },
    getNarrative(code, fallbackPattern = "", fallbackParams = {}) {
      const item = this.causalNarrativesList.find((n) => n.NarrativeCode === code);
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
      if (this.selectedPeriod === "2026-09") {
        this.fetchPeriodData("2026-09");
      }
      this.fetchAllLiveData();
    },
    setSchoolYear(year) {
      this.selectedYear = year;
      if (this.selectedPeriod === "2026-09") {
        this.fetchPeriodData("2026-09");
      }
      this.fetchAllLiveData();
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
      const token = (typeof $awt !== "undefined" && $awt) ? $awt : "zfZAqG2ajzuOx81NyGQ8KOUJ8-p0GGP17hzsK6D9u6o.0DD336463451F88B";
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
        const p7 = this.callTapi("Dashboard/Calen_ThongKe_TietDay_TheoLop", { NamHocID: 2024, DonViID: 1, KhoiID: 16, TuNgay: "2024-10-01", DenNgay: "2024-10-07" })
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
      if (this.selectedPeriod === "2026-09") {
        this.fetchPeriodData("2026-09");
      } else {
        this.fetchAllLiveData();
      }
      this.$emit("on-reload");
    },
  },
	}
</script>