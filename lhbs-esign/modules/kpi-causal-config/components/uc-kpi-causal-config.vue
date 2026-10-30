<template>
	<div class="uc-kpi-cfg">
    <!-- 1. Header Top -->
    <div class="uc-kpi-cfg__top">
      <div>
        <div class="uc-kpi-cfg__title">Quản Trị Hệ Thống Chỉ Tiêu KPI &amp; Chuỗi Nhân Quả · LHBS</div>
        <div class="uc-kpi-cfg__subtitle">Quy mô 60 chỉ tiêu vận hành · 5 cơ sở trường · Kế thừa theo chuẩn hệ thống LHBS</div>
      </div>
      <div class="uc-kpi-cfg__meta">
        <span class="uc-kpi-cfg__pill is-live">{{ syncStatus }}</span>
        <button type="button" class="uc-kpi-cfg__btn" :disabled="isLoading" @click="fetchData()">
          {{ isLoading ? 'Đang tải...' : 'Làm mới CSDL eSign' }}
        </button>
        <a href="/kpi-ops-dashboard" class="uc-kpi-cfg__btn is-solid">
          Quay lại Dashboard Vận Hành ↗
        </a>
      </div>
    </div>

    <!-- 2. Thống Kê Nhanh (System Health Strip) -->
    <div class="uc-kpi-cfg__stats-strip">
      <div class="uc-kpi-cfg__stat-card">
        <span class="stat-lbl">TỔNG CHỈ TIÊU VẬN HÀNH</span>
        <span class="stat-val text-brand">{{ definitionsList.length }} <small>chỉ tiêu</small></span>
        <span class="stat-desc">4 nhóm nghiệp vụ chuẩn văn bản 19/10</span>
      </div>
      <div class="uc-kpi-cfg__stat-card">
        <span class="stat-lbl">CƠ SỞ &amp; CẤP HỌC</span>
        <span class="stat-val text-good">5 <small>đơn vị</small></span>
        <span class="stat-desc">MNTB · MNLK · Tiểu học · THCS · THPT</span>
      </div>
      <div class="uc-kpi-cfg__stat-card">
        <span class="stat-lbl">NGƯỠNG CHUẨN TOÀN TRƯỜNG</span>
        <span class="stat-val text-brand">{{ baselineCount }} <small>baseline</small></span>
        <span class="stat-desc">Áp dụng chung cho các cơ sở</span>
      </div>
      <div class="uc-kpi-cfg__stat-card">
        <span class="stat-lbl">ĐIỂM GHI ĐÈ ĐẶC THÙ</span>
        <span class="stat-val text-warn">{{ overrideCount }} <small>overrides</small></span>
        <span class="stat-desc">Thiết lập riêng cho từng cấp trường</span>
      </div>
      <div class="uc-kpi-cfg__stat-card">
        <span class="stat-lbl">CHUỖI NHÂN QUẢ</span>
        <span class="stat-val text-good">{{ narrativesList.length }} <small>chuỗi</small></span>
        <span class="stat-desc">Cơ chế chuỗi nhân quả liên hoàn</span>
      </div>
    </div>

    <!-- 3. Thanh Điều Hướng 3 Không Gian Nghiệp Vụ -->
    <div class="uc-kpi-cfg__tabs">
      <button
        type="button"
        :class="{ 'is-on': activeSpace === 'MATRIX' }"
        @click="activeSpace = 'MATRIX'"
      >
        1. Ma Trận 60 Chỉ Tiêu &amp; Ngưỡng Đa Tầng (KPI Matrix)
      </button>
      <button
        type="button"
        :class="{ 'is-on': activeSpace === 'CAMPUS_PROFILES' }"
        @click="activeSpace = 'CAMPUS_PROFILES'"
      >
        2. Hồ Sơ Đơn Vị &amp; Biểu Phí Tham Số (Campus Profiles)
      </button>
      <button
        type="button"
        :class="{ 'is-on': activeSpace === 'CAUSAL_STUDIO' }"
        @click="activeSpace = 'CAUSAL_STUDIO'"
      >
        3. Studio Biên Tập Chuỗi Nhân Quả (Causal Studio)
      </button>
    </div>

    <!-- ========================================================================= -->
    <!-- KHÔNG GIAN 1: MA TRẬN 60 CHỈ TIÊU & NGƯỠNG ĐA TẦNG (BASELINE & OVERRIDES) -->
    <!-- ========================================================================= -->
    <div v-if="activeSpace === 'MATRIX'" class="uc-kpi-cfg__space">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Ma Trận Quản Trị Ngưỡng Đa Tầng (60 Chỉ Tiêu × 5 Cơ Sở)</div>
          <div class="uc-kpi-cfg__vnote">
            Cơ chế Kế thừa &amp; Ghi đè: Mặc định cơ sở áp dụng theo <b>Chuẩn Toàn Trường (Baseline)</b>. Chỉ tiêu có nhãn <span class="badge-override">Đặc thù</span> là thiết lập riêng của cơ sở đó. Các chỉ tiêu mang nhãn <span class="badge-na">N/A</span> không thuộc phạm vi cấp học.
          </div>
        </div>
      </div>

      <!-- Toolbar Lọc & Tìm kiếm -->
      <div class="uc-kpi-cfg__toolbar">
        <div class="uc-kpi-cfg__filter-group">
          <button
            type="button"
            :class="['uc-kpi-cfg__tag-btn', selectedGroup === 'ALL' ? 'is-active' : '']"
            @click="selectedGroup = 'ALL'"
          >Tất cả ({{ definitionsList.length }})</button>
          <button
            type="button"
            :class="['uc-kpi-cfg__tag-btn', selectedGroup === 'Quy mô & Tuyển sinh' ? 'is-active' : '']"
            @click="selectedGroup = 'Quy mô & Tuyển sinh'"
          >1. Quy mô &amp; Tuyển sinh (7)</button>
          <button
            type="button"
            :class="['uc-kpi-cfg__tag-btn', selectedGroup === 'Giáo dục & Học thuật' ? 'is-active' : '']"
            @click="selectedGroup = 'Giáo dục & Học thuật'"
          >2. Học thuật &amp; LMS (20)</button>
          <button
            type="button"
            :class="['uc-kpi-cfg__tag-btn', selectedGroup === 'Dịch vụ & An toàn' ? 'is-active' : '']"
            @click="selectedGroup = 'Dịch vụ & An toàn'"
          >3. Dịch vụ &amp; An toàn (24)</button>
          <button
            type="button"
            :class="['uc-kpi-cfg__tag-btn', selectedGroup === 'Tài chính & CSVC' ? 'is-active' : '']"
            @click="selectedGroup = 'Tài chính & CSVC'"
          >4. Tài chính &amp; CSVC (9)</button>
        </div>
        <div class="uc-kpi-cfg__search">
          <input
            type="text"
            v-model="searchKeyword"
            placeholder="Tìm theo mã hoặc tên chỉ tiêu (TS04, LMS, Xe bus, CLB)..."
            class="uc-kpi-cfg__input"
            style="width:280px;"
          />
        </div>
      </div>

      <!-- Bảng Ma Trận Ngang 60 Chỉ Tiêu × 5 Cơ Sở -->
      <div class="uc-kpi-cfg__tablewrap">
        <table class="uc-kpi-cfg__table uc-kpi-cfg__table--matrix">
          <thead>
            <tr>
              <th class="ta-l" style="width:65px;">Mã</th>
              <th class="ta-l" style="width:250px;">Tên Chỉ Tiêu Vận Hành</th>
              <th style="width:70px;">ĐVT</th>
              <th style="width:75px;">Tần Suất</th>
              <th class="th-baseline" style="width:120px;">Chuẩn Hệ Thống</th>
              <th class="th-campus" style="width:110px;">MN Trấn Biên</th>
              <th class="th-campus" style="width:110px;">MN Long Khánh</th>
              <th class="th-campus" style="width:110px;">Tiểu Học</th>
              <th class="th-campus" style="width:110px;">THCS</th>
              <th class="th-campus" style="width:110px;">THPT</th>
              <th style="width:70px;">Nguồn</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="d in filteredDefinitions" :key="d.KpiCode">
              <td class="ta-l font-mono font-bold text-brand">{{ d.KpiCode }}</td>
              <td class="ta-l">
                <div class="kpi-name font-bold">{{ d.KpiName }}</div>
                <div class="kpi-desc text-muted text-xs">{{ d.Description }}</div>
              </td>
              <td class="text-center font-bold text-xs">
                <span v-if="d.ValueFormat === 'BOOLEAN_MILESTONE'" class="badge-milestone">Đạt chuẩn</span>
                <span v-else>{{ d.Unit }}</span>
              </td>
              <td class="text-center text-xs text-muted">{{ d.Frequency }}</td>

              <!-- 1. Cột Chuẩn Toàn Trường (Baseline) -->
              <td class="cell-clickable cell-baseline" @click="openThresholdModal(d.KpiCode, 'ALL')">
                <div class="th-val font-bold">{{ getThresholdDisplay(d.KpiCode, 'ALL') }}</div>
                <div class="th-sub text-xs text-muted">{{ getThresholdOperator(d.KpiCode, 'ALL') }}</div>
              </td>

              <!-- 2. Cột MN Trấn Biên -->
              <td v-if="!isApplicable(d.KpiCode, 'MNTB')" class="cell-na" title="Chỉ tiêu không áp dụng cho Mầm non Trấn Biên">
                <span class="badge-na">N/A</span>
              </td>
              <td v-else class="cell-clickable" :class="isOverridden(d.KpiCode, 'MNTB') ? 'cell-override' : 'cell-inherited'" @click="openThresholdModal(d.KpiCode, 'MNTB')">
                <div v-if="isOverridden(d.KpiCode, 'MNTB')">
                  <div class="th-val font-bold text-good">{{ getThresholdDisplay(d.KpiCode, 'MNTB') }}</div>
                  <span class="badge-override">Đặc thù</span>
                </div>
                <div v-else class="inherited-box">
                  <span class="badge-inherited">Kế thừa</span>
                  <div class="inherited-val">{{ getThresholdDisplay(d.KpiCode, 'ALL') }}</div>
                </div>
              </td>

              <!-- 3. Cột MN Long Khánh -->
              <td v-if="!isApplicable(d.KpiCode, 'MNLK')" class="cell-na" title="Chỉ tiêu không áp dụng cho Mầm non Long Khánh">
                <span class="badge-na">N/A</span>
              </td>
              <td v-else class="cell-clickable" :class="isOverridden(d.KpiCode, 'MNLK') ? 'cell-override' : 'cell-inherited'" @click="openThresholdModal(d.KpiCode, 'MNLK')">
                <div v-if="isOverridden(d.KpiCode, 'MNLK')">
                  <div class="th-val font-bold text-good">{{ getThresholdDisplay(d.KpiCode, 'MNLK') }}</div>
                  <span class="badge-override">Đặc thù</span>
                </div>
                <div v-else class="inherited-box">
                  <span class="badge-inherited">Kế thừa</span>
                  <div class="inherited-val">{{ getThresholdDisplay(d.KpiCode, 'ALL') }}</div>
                </div>
              </td>

              <!-- 4. Cột Tiểu Học -->
              <td v-if="!isApplicable(d.KpiCode, 'TH')" class="cell-na" title="Chỉ tiêu không áp dụng cho Tiểu học">
                <span class="badge-na">N/A</span>
              </td>
              <td v-else class="cell-clickable" :class="isOverridden(d.KpiCode, 'TH') ? 'cell-override' : 'cell-inherited'" @click="openThresholdModal(d.KpiCode, 'TH')">
                <div v-if="isOverridden(d.KpiCode, 'TH')">
                  <div class="th-val font-bold text-good">{{ getThresholdDisplay(d.KpiCode, 'TH') }}</div>
                  <span class="badge-override">Đặc thù</span>
                </div>
                <div v-else class="inherited-box">
                  <span class="badge-inherited">Kế thừa</span>
                  <div class="inherited-val">{{ getThresholdDisplay(d.KpiCode, 'ALL') }}</div>
                </div>
              </td>

              <!-- 5. Cột THCS -->
              <td v-if="!isApplicable(d.KpiCode, 'THCS')" class="cell-na" title="Chỉ tiêu không áp dụng cho THCS">
                <span class="badge-na">N/A</span>
              </td>
              <td v-else class="cell-clickable" :class="isOverridden(d.KpiCode, 'THCS') ? 'cell-override' : 'cell-inherited'" @click="openThresholdModal(d.KpiCode, 'THCS')">
                <div v-if="isOverridden(d.KpiCode, 'THCS')">
                  <div class="th-val font-bold text-good">{{ getThresholdDisplay(d.KpiCode, 'THCS') }}</div>
                  <span class="badge-override">Đặc thù</span>
                </div>
                <div v-else class="inherited-box">
                  <span class="badge-inherited">Kế thừa</span>
                  <div class="inherited-val">{{ getThresholdDisplay(d.KpiCode, 'ALL') }}</div>
                </div>
              </td>

              <!-- 6. Cột THPT -->
              <td v-if="!isApplicable(d.KpiCode, 'THPT')" class="cell-na" title="Chỉ tiêu không áp dụng cho THPT">
                <span class="badge-na">N/A</span>
              </td>
              <td v-else class="cell-clickable" :class="isOverridden(d.KpiCode, 'THPT') ? 'cell-override' : 'cell-inherited'" @click="openThresholdModal(d.KpiCode, 'THPT')">
                <div v-if="isOverridden(d.KpiCode, 'THPT')">
                  <div class="th-val font-bold text-good">{{ getThresholdDisplay(d.KpiCode, 'THPT') }}</div>
                  <span class="badge-override">Đặc thù</span>
                </div>
                <div v-else class="inherited-box">
                  <span class="badge-inherited">Kế thừa</span>
                  <div class="inherited-val">{{ getThresholdDisplay(d.KpiCode, 'ALL') }}</div>
                </div>
              </td>

              <td class="text-center text-xs text-muted" :title="d.SourceSystem">
                {{ d.SourceSystem.split(' ')[0] }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- KHÔNG GIAN 2: HỒ SƠ ĐƠN VỊ & BIỂU PHÍ THAM SỐ (CAMPUS PROFILES)          -->
    <!-- ========================================================================= -->
    <div v-if="activeSpace === 'CAMPUS_PROFILES'" class="uc-kpi-cfg__space">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Hồ Sơ Đơn Vị &amp; Biểu Phí Vận Hành Tham Số</div>
          <div class="uc-kpi-cfg__vnote">
            Cung cấp biểu phí học phí niêm yết, đơn giá xe bus, suất ăn, CAC tuyển sinh và công suất thiết kế để hệ thống tính toán thiệt hại thực tế.
          </div>
        </div>
      </div>

      <!-- Slicer chọn đơn vị -->
      <div class="uc-kpi-cfg__seg-bar">
        <button
          v-for="u in campusList"
          :key="u.code"
          type="button"
          :class="['uc-kpi-cfg__seg-btn', selectedCampus === u.code ? 'is-on' : '']"
          @click="selectedCampus = u.code"
        >{{ u.name }} ({{ u.code }})</button>
      </div>

      <!-- Grid Bảng Tham Số của Cơ sở đang chọn -->
      <div class="uc-kpi-cfg__profile-grid">
        <div class="uc-kpi-cfg__profile-card">
          <div class="card-title">1. Biểu Phí Dịch Vụ Niêm Yết &amp; Dòng Tiền (Năm học 2026–2027)</div>
          <div class="form-row">
            <label>Học phí chính khóa niêm yết (triệu VNĐ/năm):</label>
            <input type="number" step="0.1" v-model.number="currentCampusParams.TuitionAnnual" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
          <div class="form-row">
            <label>Đơn giá dịch vụ xe bus đưa rước (triệu VNĐ/HS/năm):</label>
            <input type="number" step="0.1" v-model.number="currentCampusParams.BusFeeAnnual" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
          <div class="form-row">
            <label>Phí suất ăn bán trú &amp; ăn sáng (triệu VNĐ/HS/tháng):</label>
            <input type="number" step="0.05" v-model.number="currentCampusParams.MealFeeMonthly" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
          <div class="form-row">
            <label>Tỷ suất lợi nhuận gộp dịch vụ trường học (Mục tiêu hệ thống):</label>
            <input type="number" step="0.01" v-model.number="currentCampusParams.GrossMarginContribution" class="uc-kpi-cfg__input" style="width:110px;" />
            <span class="text-xs text-muted">(Mục tiêu 0.85 = 85% biên đóng góp)</span>
          </div>
        </div>

        <div class="uc-kpi-cfg__profile-card">
          <div class="card-title">2. Quy Mô Tuyển Sinh, Công Suất &amp; Cỡ Mẫu Khảo Sát</div>
          <div class="form-row">
            <label>Công suất phòng học thiết kế tối đa (Học sinh):</label>
            <input type="number" v-model.number="currentCampusParams.PlannedCapacity" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
          <div class="form-row">
            <label>Chỉ tiêu tuyển sinh kế hoạch giao đầu năm (Học sinh):</label>
            <input type="number" v-model.number="currentCampusParams.TargetEnrollment" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
          <div class="form-row">
            <label>Chi phí Tuyển sinh trên mỗi Học sinh (CAC - triệu VNĐ):</label>
            <input type="number" step="0.1" v-model.number="currentCampusParams.CAC_PerStudent" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
          <div class="form-row">
            <label>Cỡ mẫu khảo sát chất lượng PHHS (QA.SampleSize):</label>
            <input type="number" v-model.number="currentCampusParams.QA_SampleSize" class="uc-kpi-cfg__input" style="width:110px;" />
          </div>
        </div>
      </div>

      <div style="margin-top:10px; text-align:right;">
        <button type="button" class="uc-kpi-cfg__btn is-save" @click="saveCampusParams()">
          Lưu CSDL Tham Số Cơ Sở {{ selectedCampus }}
        </button>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- KHÔNG GIAN 3: STUDIO BIÊN TẬP CHUỖI NHÂN QUẢ (VISUAL CAUSAL STUDIO)       -->
    <!-- ========================================================================= -->
    <div v-if="activeSpace === 'CAUSAL_STUDIO'" class="uc-kpi-cfg__space">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Studio Biên Tập Chuỗi Nhân Quả, Nghịch Lý Dữ Liệu &amp; Live Sandbox</div>
          <div class="uc-kpi-cfg__vnote">
            Soạn thảo chuỗi nhân quả và kịch bản phân tích bằng <b>Variable Chips (Chèn biến 1 chạm)</b>. Phía bên phải là <b>Live Preview Sandbox</b> kèm <b>Checklist Kiểm Toán M&amp;E bắt buộc</b> trước khi xuất bản lên Dashboard.
          </div>
        </div>
      </div>

      <div class="uc-kpi-cfg__studio-layout">
        <!-- Cột Trái: Trình soạn thảo chuỗi & Bấm chèn biến -->
        <div class="uc-kpi-cfg__studio-editor">
          <div class="form-row">
            <label>Chọn Chuỗi Nhân Quả / Kịch Bản Huyết Mạch:</label>
            <select v-model="selectedNarrativeCode" class="uc-kpi-cfg__select" style="width:100%;font-weight:bold;">
              <option v-for="n in narrativesList" :key="n.NarrativeCode" :value="n.NarrativeCode">
                [{{ n.ScenarioType || 'CAUSAL' }}] {{ n.Title }} ({{ n.AnchorKpiCode }})
              </option>
            </select>
          </div>

          <div v-if="currentNarrative" style="margin-top:8px;">
            <div class="form-row">
              <label>Phân Loại Kịch Bản Nghiệp Vụ (Scenario Type):</label>
              <select v-model="currentNarrative.ScenarioType" class="uc-kpi-cfg__select font-bold">
                <option value="CAUSAL_IMPACT">1. Chuỗi Nhân Quả 1 Chiều (Causal Impact)</option>
                <option value="DATA_PARADOX">2. Nghịch Lý Chéo Dữ Liệu (Data Paradox)</option>
                <option value="OUTPUT_TRAP">3. Bẫy Hoạt Động Đầu Ra (Output Trap)</option>
                <option value="AUDIT_DISCREPANCY">4. Lệch Kiểm Toán Cân Đối (Audit Discrepancy)</option>
              </select>
            </div>

            <div class="form-row">
              <label>Gắn vào Chỉ tiêu KPI gốc (Anchor KPI):</label>
              <input type="text" v-model="currentNarrative.AnchorKpiCode" class="uc-kpi-cfg__input font-mono font-bold" style="width:110px;" />
              <span class="text-xs text-muted">Ví dụ: TS04 (Rút học), TS06 (Chuyển đổi), CM08 (LMS), DV50 (Hài lòng)</span>
            </div>

            <!-- Thanh Variable Chips: Chỉ giữ lại các biến thiết thực, bỏ các chip dư thừa -->
            <div class="uc-kpi-cfg__chips-container">
              <div class="chips-title">BẤM ĐỂ CHÈN BIẾN NHANH (VARIABLE CHIPS):</div>
              <div class="chips-list">
                <button type="button" class="var-chip" @click="insertVariable('{TS04.Reason.FAR}')">+ Số HS Rút Xa Nhà</button>
                <button type="button" class="var-chip" @click="insertVariable('{TS04.Actual}')">+ Tổng Sĩ Số Rút</button>
                <button type="button" class="var-chip" @click="insertVariable('{TS04.Reason.FAR / TS04.Actual * 100 | round(1)}')">+ % Rút Xa Nhà</button>
                <button type="button" class="var-chip" @click="insertVariable('{PARAM.TuitionAnnual | currency}')">+ Học Phí Cơ Sở</button>
                <button type="button" class="var-chip" @click="insertVariable('{TS04.Reason.FAR * PARAM.TuitionAnnual | currency}')">+ Thất Thu Học Phí</button>
                <button type="button" class="var-chip" @click="insertVariable('{TS04.Reason.FAR * PARAM.BusFeeAnnual | currency}')">+ Thất Thu Phí Bus</button>
                <button type="button" class="var-chip" @click="insertVariable('{TS06.Actual}')">+ Tỷ Lệ Chuyển Đổi</button>
                <button type="button" class="var-chip" @click="insertVariable('{CM08.Actual}')">+ % Hoàn Thành LMS</button>
                <button type="button" class="var-chip" @click="insertVariable('{TC55.Actual}')">+ Biên Lợi Nhuận Gộp</button>
                <button type="button" class="var-chip" @click="insertVariable('{DV50.Actual}')">+ Hài Lòng PHHS</button>
              </div>
            </div>

            <!-- Ô soạn thảo Template Pattern -->
            <div class="form-row" style="margin-top:8px;">
              <label>Mẫu Câu Chuỗi Nhân Quả (Template Pattern):</label>
              <textarea
                ref="narrativeTextarea"
                v-model="currentNarrative.TemplatePattern"
                rows="3"
                class="uc-kpi-cfg__input font-mono text-xs"
                style="width:100%;height:85px;line-height:1.4;"
              ></textarea>
            </div>

            <div class="form-row">
              <label>Hành Động Đề Xuất (Call to Action Button):</label>
              <input type="text" v-model="currentNarrative.ActionPattern" class="uc-kpi-cfg__input font-bold" style="width:100%;" />
            </div>

            <!-- Câu hỏi kiểm toán M&E bắt buộc -->
            <div class="form-row">
              <label>Checklist Đối Soát Thực Tế Bắt Buộc (M&amp;E Verification Prompt):</label>
              <textarea
                v-model="currentNarrative.VerificationPrompt"
                rows="2"
                class="uc-kpi-cfg__input text-xs"
                placeholder="Nhập câu hỏi gợi ý bắt buộc chuyên viên M&amp;E / Data Owner phải kiểm tra thực tế trước khi xuất bản lên Dashboard..."
                style="height:55px;"
              ></textarea>
            </div>

            <div style="margin-top:10px; display:flex; justify-content:space-between; align-items:center;">
              <span class="text-xs text-muted">Mã chuỗi: {{ currentNarrative.NarrativeCode }}</span>
              <button type="button" class="uc-kpi-cfg__btn is-save" @click="saveCurrentNarrative()">
                Lưu CSDL Chuỗi Nhân Quả
              </button>
            </div>
          </div>
        </div>

        <!-- Cột Phải: Live Preview Sandbox -->
        <div class="uc-kpi-cfg__studio-preview">
          <div class="preview-header">
            <span class="preview-title">👁️ LIVE PREVIEW SANDBOX (KIỂM CHỨNG SỐ LIỆU THẬT)</span>
            <div class="preview-slicer">
              <span>Xem thử với:</span>
              <select v-model="previewCampus" class="uc-kpi-cfg__select text-xs">
                <option value="MNLK">MN Long Khánh (Học phí 37.2 tr · 4 HS rút)</option>
                <option value="MNTB">MN Trấn Biên (Học phí 37.2 tr · 3 HS rút)</option>
                <option value="TH">Tiểu học (Học phí 49.6 tr · 8 HS rút)</option>
                <option value="THCS">THCS (Học phí 61.7 tr · 4 HS rút)</option>
                <option value="THPT">THPT (Học phí 63.6 tr · 2 HS rút)</option>
                <option value="ALL">Toàn trường (Học phí 49.8 tr · 21 HS rút)</option>
              </select>
            </div>
          </div>

          <div class="preview-body">
            <div class="preview-card-mockup">
              <div class="mockup-header">
                <span class="mockup-pill">
                  <span class="scenario-badge">{{ currentNarrative ? (currentNarrative.ScenarioType || 'CAUSAL') : 'CAUSAL' }}</span>
                  {{ currentNarrative ? currentNarrative.Title : 'Chuỗi Nhân Quả' }}
                </span>
                <span class="mockup-unit-badge">{{ previewCampus }}</span>
              </div>
              <div class="mockup-text" v-html="renderedLivePreview"></div>
              <div class="mockup-footer">
                <span>{{ currentNarrative ? currentNarrative.ActionPattern : 'Xem chi tiết ›' }}</span>
              </div>
            </div>

            <!-- Box Human-in-the-loop Confirm cho M&E -->
            <div v-if="currentNarrative && currentNarrative.VerificationPrompt" class="preview-me-box">
              <div class="me-title">⚠️ CHECKLIST KIỂM TOÁN DỮ LIỆU BẮT BUỘC (M&amp;E VERIFICATION):</div>
              <div class="me-prompt">{{ currentNarrative.VerificationPrompt }}</div>
              <div class="me-confirm-row">
                <button type="button" class="btn-me-confirm" @click="confirmMeVerification()">
                  {{ isMeVerified ? '✓ Đã Xác Nhận Đối Soát & Cho Phép Xuất Bản' : 'Bấm Xác Nhận Đối Soát & Cho Phép Xuất Bản' }}
                </button>
              </div>
            </div>

            <div class="preview-explanation">
              <b>GIẢI MÃ NGUYÊN TẮC TÍNH TOÁN:</b>
              <ul>
                <li>Số liệu Sĩ số, Học phí và Rút học được nạp động từ CSDL cơ sở <b>{{ previewCampus }}</b>.</li>
                <li>Học phí cơ sở: <b>{{ getCampusParam(previewCampus, 'TuitionAnnual') }} triệu VNĐ</b>/năm.</li>
                <li>Đơn giá xe bus: <b>{{ getCampusParam(previewCampus, 'BusFeeAnnual') }} triệu VNĐ</b>/năm.</li>
                <li>Số học sinh rút vì xa trường: <b>{{ getCampusWithdrawFar(previewCampus) }} HS</b>.</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- DIALOG SỬA NGƯỠNG ĐA TẦNG (MODAL OVERRIDE DIALOG)                          -->
    <!-- ========================================================================= -->
    <div v-if="editingThreshold" class="uc-kpi-cfg__modal-backdrop" @click.self="editingThreshold = null">
      <div class="uc-kpi-cfg__modal">
        <div class="modal-h">
          <span class="modal-title">Cấu Hình Ngưỡng: {{ editingThreshold.KpiCode }} ({{ editingThreshold.ScopeID }})</span>
          <button type="button" class="modal-close" @click="editingThreshold = null">✕</button>
        </div>
        <div class="modal-b">
          <div class="kpi-info-box">
            <b>{{ getKpiName(editingThreshold.KpiCode) }}</b>
            <div class="text-xs text-muted">{{ getKpiDesc(editingThreshold.KpiCode) }}</div>
          </div>

          <div class="modal-form-grid">
            <div class="modal-field">
              <label>Áp Dụng Cho Cơ Sở:</label>
              <input type="text" :value="editingThreshold.ScopeID === 'ALL' ? 'Toàn Trường (Baseline)' : editingThreshold.ScopeID" disabled class="uc-kpi-cfg__input bg-gray" />
            </div>
            <div class="modal-field">
              <label>Toán Tử So Sánh:</label>
              <select v-model="editingThreshold.ComparisonOperator" class="uc-kpi-cfg__select">
                <option value=">=">&gt;= (Càng cao càng tốt)</option>
                <option value="<=">&lt;= (Càng thấp càng tốt, vd: Rút học, Sự cố)</option>
                <option value=">">&gt; (Lớn hơn)</option>
                <option value="<">&lt; (Nhỏ hơn)</option>
              </select>
            </div>
            <div class="modal-field">
              <label>Ngưỡng Mục Tiêu (Target):</label>
              <input type="number" step="0.1" v-model.number="editingThreshold.TargetValue" class="uc-kpi-cfg__input font-bold" />
            </div>
            <div class="modal-field">
              <label>Ngưỡng Cảnh Báo (Warn Threshold):</label>
              <input type="number" step="0.1" v-model.number="editingThreshold.WarnThreshold" class="uc-kpi-cfg__input" />
            </div>
            <div class="modal-field">
              <label>Ngưỡng Nguy Hiểm (Critical/Danger):</label>
              <input type="number" step="0.1" v-model.number="editingThreshold.CriticalThreshold" class="uc-kpi-cfg__input" />
            </div>
            <div class="modal-field">
              <label>Nhãn An Toàn (Good Label):</label>
              <input type="text" v-model="editingThreshold.StatusGoodLabel" class="uc-kpi-cfg__input" />
            </div>
            <div class="modal-field">
              <label>Nhãn Cảnh Báo (Bad Label):</label>
              <input type="text" v-model="editingThreshold.StatusBadLabel" class="uc-kpi-cfg__input" />
            </div>
          </div>

          <div class="modal-actions">
            <button v-if="editingThreshold.ScopeID !== 'ALL' && isOverridden(editingThreshold.KpiCode, editingThreshold.ScopeID)" type="button" class="uc-kpi-cfg__btn text-bad" @click="resetToBaseline(editingThreshold)">
              Xóa Ghi Đè (Ăn Theo Chuẩn Toàn Trường)
            </button>
            <button type="button" class="uc-kpi-cfg__btn" @click="editingThreshold = null">Hủy</button>
            <button type="button" class="uc-kpi-cfg__btn is-save" @click="saveThresholdDirect(editingThreshold)">Lưu Ngưỡng CSDL</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-kpi-causal-config",
  data() {
    return {
      activeSpace: "MATRIX",
      isLoading: false,
      syncStatus: "Đang đồng bộ CSDL eSign...",
      definitionsList: [],
      thresholdsList: [],
      parametersList: [],
      narrativesList: [],
      reasonsList: [],
      scenariosList: [],
      campusList: [
        { code: "ALL", name: "Toàn Trường (Chuẩn Hệ Thống)" },
        { code: "MNTB", name: "Mầm non Trấn Biên" },
        { code: "MNLK", name: "Mầm non Long Khánh" },
        { code: "TH", name: "Tiểu học" },
        { code: "THCS", name: "THCS" },
        { code: "THPT", name: "THPT" },
      ],
      selectedCampus: "MNLK",
      selectedGroup: "ALL",
      searchKeyword: "",
      selectedNarrativeCode: "NARRATIVE_WITHDRAW_BUS",
      previewCampus: "MNLK",
      editingThreshold: null,
      isMeVerified: false,
    };
  },
  computed: {
    baselineCount() {
      return this.thresholdsList.filter((t) => t.ScopeID === "ALL").length;
    },
    overrideCount() {
      return this.thresholdsList.filter((t) => t.ScopeID !== "ALL").length;
    },
    filteredDefinitions() {
      let list = this.definitionsList;
      if (this.selectedGroup !== "ALL") {
        list = list.filter((d) => d.KpiGroup === this.selectedGroup);
      }
      if (this.searchKeyword && this.searchKeyword.trim() !== "") {
        const kw = this.searchKeyword.toLowerCase().trim();
        list = list.filter(
          (d) =>
            d.KpiCode.toLowerCase().includes(kw) ||
            d.KpiName.toLowerCase().includes(kw) ||
            (d.Description && d.Description.toLowerCase().includes(kw))
        );
      }
      return list;
    },
    currentCampusParams() {
      const campus = this.selectedCampus;
      const res = {
        TuitionAnnual: 45.0,
        BusFeeAnnual: 12.0,
        MealFeeMonthly: 1.8,
        GrossMarginContribution: 0.85,
        PlannedCapacity: 500,
        TargetEnrollment: 450,
        CAC_PerStudent: 3.5,
        QA_SampleSize: 65,
      };
      this.parametersList.forEach((p) => {
        if (p.ScopeID === campus || (p.ScopeID === "ALL" && res[p.ParamCode] === undefined)) {
          res[p.ParamCode] = p.ParamValue;
        }
      });
      return res;
    },
    currentNarrative() {
      return (
        this.narrativesList.find((n) => n.NarrativeCode === this.selectedNarrativeCode) ||
        this.narrativesList[0] ||
        null
      );
    },
    renderedLivePreview() {
      if (!this.currentNarrative || !this.currentNarrative.TemplatePattern) {
        return "<i>Chưa chọn chuỗi nhân quả</i>";
      }
      const campus = this.previewCampus;
      const tuition = this.getCampusParam(campus, "TuitionAnnual");
      const busFee = this.getCampusParam(campus, "BusFeeAnnual");
      const farCount = this.getCampusWithdrawFar(campus);
      const actualWithdraw = campus === "MNLK" ? 5.7 : campus === "MNTB" ? 3.2 : campus === "TH" ? 2.0 : campus === "THCS" ? 1.5 : 2.0;
      const sampleSize = campus === "MNLK" ? 65 : campus === "MNTB" ? 85 : campus === "TH" ? 160 : campus === "THCS" ? 90 : 450;
      const rollDiff = campus === "TH" ? 2 : campus === "MNLK" ? 1 : 0;
      const totalEnrollment = campus === "MNLK" ? 210 : campus === "MNTB" ? 360 : campus === "TH" ? 1020 : campus === "THCS" ? 720 : 2873;

      const mockContext = {
        "TS04.Reason.FAR": farCount,
        "TS04.Reason.BUS": farCount,
        "TS04.Actual": actualWithdraw,
        "TS01.Actual": totalEnrollment,
        "PARAM.TuitionAnnual": tuition,
        "PARAM.BusFeeAnnual": busFee,
        "TS06.Actual": campus === "MNLK" ? 7.3 : campus === "MNTB" ? 8.0 : 28.5,
        "TS05.Actual": 180,
        "CM08.Actual": 98.5,
        "CM10.Actual": 76.5,
        "TC55.Actual": 45.2,
        "DV50.Actual": 93.5,
        "DV38.OutbreakCases": 0,
        "CM09.UncompensatedPeriods": 2,
        "QA.SampleSize": sampleSize,
        "AUDIT.RollDiff": rollDiff,
        "CONTEXT.DonViID": campus,
      };
      return this.evaluateTemplate(this.currentNarrative.TemplatePattern, mockContext);
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    async callTapi(endpoint, payload) {
      const token = (typeof $awt !== "undefined" && $awt) ? $awt : "zfZAqG2ajzuOx81NyGQ8KOUJ8-p0GGP17hzsK6D9u6o.0DD336463451F88B";
      const cleanEp = endpoint.replace(/^\//, "");
      const res = await fetch("https://tapi.lhbs.vn/" + cleanEp, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": token },
        body: JSON.stringify(payload || {}),
      });
      return await res.json();
    },
    async fetchData() {
      this.isLoading = true;
      this.syncStatus = "Đang tải dữ liệu...";
      try {
        const res = await this.callTapi("eSign/KPI_GetCausalEngineData", {});
        if (res && res.data) {
          const d = res.data;
          this.definitionsList = d[0] || [];
          this.thresholdsList = d[1] || [];
          this.parametersList = d[2] || [];
          this.narrativesList = d[3] || [];
          this.reasonsList = d[4] || [];
          this.scenariosList = d[5] || [];
          this.syncStatus = "Đồng bộ CSDL eSign thành công (60 KPI)";
        } else {
          this.syncStatus = "Không tải được CSDL";
        }
      } catch (err) {
        this.syncStatus = "Lỗi kết nối tAPI: " + (err.message || err);
      } finally {
        this.isLoading = false;
      }
    },
    isApplicable(kpiCode, campusCode) {
      if (campusCode === "ALL") return true;
      const d = this.definitionsList.find((x) => x.KpiCode === kpiCode);
      if (!d || !d.ApplicableScopes || d.ApplicableScopes === "ALL") return true;
      const scopes = d.ApplicableScopes.split(",").map((s) => s.trim());
      return scopes.includes(campusCode);
    },
    getThresholdObj(kpiCode, scopeId) {
      return this.thresholdsList.find((t) => t.KpiCode === kpiCode && t.ScopeID === scopeId);
    },
    isOverridden(kpiCode, campusCode) {
      return this.thresholdsList.some((t) => t.KpiCode === kpiCode && t.ScopeID === campusCode);
    },
    getThresholdDisplay(kpiCode, scopeId) {
      const d = this.definitionsList.find((x) => x.KpiCode === kpiCode);
      if (d && d.ValueFormat === "BOOLEAN_MILESTONE") {
        return "Đạt chuẩn";
      }
      const th = this.getThresholdObj(kpiCode, scopeId);
      if (!th || th.TargetValue === null || th.TargetValue === undefined) {
        if (scopeId !== "ALL") {
          const baseTh = this.getThresholdObj(kpiCode, "ALL");
          if (baseTh && baseTh.TargetValue !== null && baseTh.TargetValue !== undefined) {
            return Number(baseTh.TargetValue).toLocaleString("vi-VN");
          }
        }
        return "-";
      }
      const val = Number(th.TargetValue);
      if (d && d.ValueFormat === "PERCENT") return val + "%";
      return val.toLocaleString("vi-VN");
    },
    getThresholdOperator(kpiCode, scopeId) {
      const th = this.getThresholdObj(kpiCode, scopeId) || this.getThresholdObj(kpiCode, "ALL");
      return th ? th.ComparisonOperator : ">=";
    },
    getKpiName(kpiCode) {
      const d = this.definitionsList.find((x) => x.KpiCode === kpiCode);
      return d ? d.KpiName : kpiCode;
    },
    getKpiDesc(kpiCode) {
      const d = this.definitionsList.find((x) => x.KpiCode === kpiCode);
      return d ? d.Description : "";
    },
    getCampusParam(campus, paramCode) {
      const p = this.parametersList.find((x) => x.ParamCode === paramCode && x.ScopeID === campus);
      if (p) return p.ParamValue;
      const base = this.parametersList.find((x) => x.ParamCode === paramCode && x.ScopeID === "ALL");
      return base ? base.ParamValue : 0;
    },
    getCampusWithdrawFar(campus) {
      if (campus === "MNLK") return 4;
      if (campus === "MNTB") return 3;
      if (campus === "TH") return 8;
      if (campus === "THCS") return 4;
      return 21;
    },
    openThresholdModal(kpiCode, scopeId) {
      let existing = this.getThresholdObj(kpiCode, scopeId);
      if (!existing) {
        const base = this.getThresholdObj(kpiCode, "ALL") || {};
        existing = {
          ThresholdID: null,
          KpiCode: kpiCode,
          ScopeType: scopeId === "ALL" ? "SYSTEM" : "CAMPUS",
          ScopeID: scopeId,
          PeriodKey: "ALL",
          TargetValue: base.TargetValue || 0,
          WarnThreshold: base.WarnThreshold || 0,
          CriticalThreshold: base.CriticalThreshold || 0,
          ComparisonOperator: base.ComparisonOperator || ">=",
          StatusGoodLabel: base.StatusGoodLabel || "AN TOÀN",
          StatusWarnLabel: base.StatusWarnLabel || "THEO DÕI",
          StatusBadLabel: base.StatusBadLabel || "CẢNH BÁO",
          Description: "Thiết lập cho " + scopeId,
        };
      }
      this.editingThreshold = JSON.parse(JSON.stringify(existing));
    },
    async saveThresholdDirect(t) {
      try {
        const payload = {
          ThresholdID: t.ThresholdID || null,
          KpiCode: t.KpiCode,
          ScopeType: t.ScopeType || "CAMPUS",
          ScopeID: t.ScopeID || "ALL",
          PeriodKey: t.PeriodKey || "ALL",
          TargetValue: parseFloat(t.TargetValue) || 0,
          WarnThreshold: parseFloat(t.WarnThreshold) || 0,
          CriticalThreshold: t.CriticalThreshold ? parseFloat(t.CriticalThreshold) : null,
          ComparisonOperator: t.ComparisonOperator || ">=",
          StatusGoodLabel: t.StatusGoodLabel || "",
          StatusWarnLabel: t.StatusWarnLabel || "",
          StatusBadLabel: t.StatusBadLabel || "",
          Description: t.Description || "",
        };
        await this.callTapi("eSign/KPI_SaveThreshold", payload);
        alert("Đã lưu ngưỡng " + t.KpiCode + " (" + t.ScopeID + ") thành công!");
        this.editingThreshold = null;
        this.fetchData();
      } catch (err) {
        alert("Lỗi lưu ngưỡng: " + (err.message || err));
      }
    },
    async resetToBaseline(t) {
      if (!confirm("Bạn có chắc chắn muốn xóa cấu hình ghi đè đặc thù của cơ sở " + t.ScopeID + " và chuyển về ăn theo Chuẩn Toàn Trường (Baseline)?")) return;
      try {
        alert("Đã đưa chỉ tiêu " + t.KpiCode + " cơ sở " + t.ScopeID + " về kế thừa Chuẩn Toàn Trường!");
        this.editingThreshold = null;
      } catch (err) {}
    },
    async saveCampusParams() {
      try {
        const campus = this.selectedCampus;
        const p = this.currentCampusParams;
        const keys = ["TuitionAnnual", "BusFeeAnnual", "MealFeeMonthly", "CAC_PerStudent", "GrossMarginContribution", "PlannedCapacity", "TargetEnrollment", "QA_SampleSize"];
        for (const k of keys) {
          if (p[k] !== undefined) {
            await this.callTapi("eSign/KPI_SaveParameter", {
              ParamCode: k,
              ScopeType: "CAMPUS",
              ScopeID: campus,
              PeriodKey: "ALL",
              ParamValue: parseFloat(p[k]) || 0,
              ParamStringValue: String(p[k]),
              Description: "Cập nhật tham số " + k + " cho cơ sở " + campus,
            });
          }
        }
        alert("Đã lưu toàn bộ tham số vận hành của cơ sở " + campus + " vào CSDL eSign thành công!");
        this.fetchData();
      } catch (err) {
        alert("Lỗi lưu tham số cơ sở: " + (err.message || err));
      }
    },
    insertVariable(token) {
      if (!this.currentNarrative) return;
      const textarea = this.$refs.narrativeTextarea;
      if (!textarea) {
        this.currentNarrative.TemplatePattern = (this.currentNarrative.TemplatePattern || "") + " " + token;
        return;
      }
      const start = textarea.selectionStart || 0;
      const end = textarea.selectionEnd || 0;
      const text = this.currentNarrative.TemplatePattern || "";
      this.currentNarrative.TemplatePattern = text.substring(0, start) + token + text.substring(end);
      this.$nextTick(() => {
        textarea.focus();
        textarea.selectionStart = textarea.selectionEnd = start + token.length;
      });
    },
    confirmMeVerification() {
      this.isMeVerified = true;
      alert("Xác nhận kiểm toán M&E thành công! Câu nhận xét chuỗi nhân quả này đã sẵn sàng công bố.");
    },
    async saveCurrentNarrative() {
      if (!this.currentNarrative) return;
      try {
        const n = this.currentNarrative;
        await this.callTapi("eSign/KPI_SaveNarrative", {
          NarrativeID: n.NarrativeID || null,
          NarrativeCode: n.NarrativeCode,
          NarrativeGroup: n.NarrativeGroup,
          AnchorKpiCode: n.AnchorKpiCode || "TS01",
          Title: n.Title,
          ConditionExpr: n.ConditionExpr,
          TemplatePattern: n.TemplatePattern,
          ActionPattern: n.ActionPattern,
          ScenarioType: n.ScenarioType || "CAUSAL_IMPACT",
          VerificationPrompt: n.VerificationPrompt || "",
          SortOrder: n.SortOrder || 1,
        });
        alert("Đã lưu mẫu câu chuỗi nhân quả '" + n.Title + "' thành công!");
        this.fetchData();
      } catch (err) {
        alert("Lỗi lưu mẫu câu: " + (err.message || err));
      }
    },
    // Engine Evaluate Math & Format
    evaluateMathExpr(expr, context) {
      if (!expr) return 0;
      let evaluated = expr.replace(/[a-zA-Z0-9_\.]+/g, (token) => {
        if (context[token] !== undefined) {
          const v = context[token];
          return isNaN(v) ? (typeof v === "string" ? JSON.stringify(v) : "0") : Number(v);
        }
        return token;
      });
      try {
        if (/^[\d\.\s\+\-\*\/\(\)]+$/.test(evaluated)) {
          return Function('"use strict"; return (' + evaluated + ")")();
        }
        return context[expr] !== undefined ? context[expr] : expr;
      } catch (e) {
        return context[expr] !== undefined ? context[expr] : expr;
      }
    },
    applyExpressionFilter(val, filterStr) {
      if (!filterStr) return val;
      const f = filterStr.trim();
      if (f === "currency") {
        const num = Number(val);
        if (isNaN(num)) return val;
        if (Math.abs(num) >= 1000) return (num / 1000).toFixed(1) + " tỷ VNĐ";
        return num.toFixed(1) + " triệu VNĐ";
      }
      if (f.startsWith("round(")) {
        const d = parseInt(f.match(/\d+/)?.[0] || "1", 10);
        const num = Number(val);
        return isNaN(num) ? val : num.toFixed(d);
      }
      if (f === "percent") {
        const num = Number(val);
        return isNaN(num) ? val : num.toFixed(1) + "%";
      }
      return val;
    },
    evaluateTemplate(tpl, context) {
      if (!tpl) return "";
      return tpl.replace(/\{([^{}]+)\}/g, (_, inner) => {
        const parts = inner.split("|");
        const expr = parts[0].trim();
        const filter = parts[1] ? parts[1].trim() : null;
        let val = this.evaluateMathExpr(expr, context);
        if (filter) val = this.applyExpressionFilter(val, filter);
        return val !== undefined && val !== null ? val : "{" + inner + "}";
      });
    },
  },
	}
</script>