<template>
  <div class="uc-kpi-cfg">
    <!-- 1. Header Top -->
    <div class="uc-kpi-cfg__top">
      <div>
        <div class="uc-kpi-cfg__title">Cấu Hình Mô Hình Nhân Quả &amp; Luật IF-ELSE · KPI LHBS</div>
        <div class="uc-kpi-cfg__subtitle">Quản trị danh mục kịch bản, tham số giả định đơn vị, tuyến xử lý lý do và quy tắc cảnh báo động</div>
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

    <!-- 2. Navigation Tabs -->
    <div class="uc-kpi-cfg__tabs">
      <button
        type="button"
        :class="{ 'is-on': activeTab === 'ASSUMPTIONS' }"
        @click="activeTab = 'ASSUMPTIONS'"
      >
        1. Tham số Giả định Đơn vị ({{ assumptionsList.length }} Cơ sở)
      </button>
      <button
        type="button"
        :class="{ 'is-on': activeTab === 'REASONS' }"
        @click="activeTab = 'REASONS'"
      >
        2. Tuyến Xử lý Lý do Rút học ({{ reasonsList.length }} Nhóm)
      </button>
      <button
        type="button"
        :class="{ 'is-on': activeTab === 'SCENARIOS' }"
        @click="activeTab = 'SCENARIOS'"
      >
        3. Kịch bản Phân tích ({{ scenariosList.length }} Kịch bản)
      </button>
      <button
        type="button"
        :class="{ 'is-on': activeTab === 'ASSIGNMENTS' }"
        @click="activeTab = 'ASSIGNMENTS'"
      >
        4. Phân công Trách nhiệm ({{ assignmentsList.length }} Phân công)
      </button>
      <button
        type="button"
        :class="{ 'is-on': activeTab === 'RULES' }"
        @click="activeTab = 'RULES'"
      >
        5. Quy tắc IF / ELSE Động ({{ rulesList.length }} Quy tắc)
      </button>
    </div>

    <!-- 3. TAB 1: THAM SỐ GIẢ ĐỊNH THEO ĐƠN VỊ -->
    <div v-if="activeTab === 'ASSUMPTIONS'" class="uc-kpi-cfg__section">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Bảng Tham Số Giả Định &amp; Học Phí Niêm Yết (tblKPI_CausalAssumptions)</div>
          <div class="uc-kpi-cfg__vnote">
            Được dùng để tự động tính toán Doanh thu năm nay mất, Doanh thu trọn vòng đời (LTV), Tỷ lệ lấp đầy và Lượng lead cần bù đắp trong Cây tác động SVG.
          </div>
        </div>
      </div>

      <div class="uc-kpi-cfg__tablewrap">
        <table class="uc-kpi-cfg__table">
          <thead>
            <tr>
              <th class="ta-l">Mã Đơn Vị</th>
              <th class="ta-l">Tên Đơn Vị</th>
              <th class="ta-l">Người Giải Trình</th>
              <th>Chỉ tiêu (KH)</th>
              <th>Sĩ số T9</th>
              <th>Học phí (tr/năm)</th>
              <th>Biên LN (%)</th>
              <th>Số năm còn lại</th>
              <th>Học phí cấp sau</th>
              <th>Xác suất lên cấp</th>
              <th>Lead/tháng</th>
              <th>Chuyển đổi (%)</th>
              <th>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in assumptionsList" :key="u.UnitCode">
              <td class="ta-l tx-strong">{{ u.UnitCode }}</td>
              <td class="ta-l">{{ u.UnitName }}</td>
              <td class="ta-l text-xs">{{ u.OwnerTitle }}</td>
              <td><input type="number" v-model.number="u.PlannedCapacity" class="uc-kpi-cfg__input" style="width:75px;" /></td>
              <td><input type="number" v-model.number="u.CurrentEnrollment" class="uc-kpi-cfg__input" style="width:75px;" /></td>
              <td><input type="number" step="0.1" v-model.number="u.AnnualTuitionMillion" class="uc-kpi-cfg__input" style="width:75px;" /></td>
              <td><input type="number" step="0.01" v-model.number="u.GrossMarginPct" class="uc-kpi-cfg__input" style="width:65px;" /></td>
              <td><input type="number" step="0.1" v-model.number="u.RemainingYearsInLevel" class="uc-kpi-cfg__input" style="width:65px;" /></td>
              <td>{{ u.NextLevelTuitionMillion ? u.NextLevelTuitionMillion + ' tr' : '—' }}</td>
              <td>{{ u.TransitionProbability ? (u.TransitionProbability * 100).toFixed(0) + '%' : '—' }}</td>
              <td><input type="number" v-model.number="u.MonthlyLeads" class="uc-kpi-cfg__input" style="width:70px;" /></td>
              <td><input type="number" step="0.001" v-model.number="u.ConversionRate" class="uc-kpi-cfg__input" style="width:70px;" /></td>
              <td>
                <button
                  type="button"
                  class="uc-kpi-cfg__btn is-save"
                  @click="saveAssumption(u)"
                  title="Lưu xuống CSDL eSign"
                >Lưu CSDL</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 4. TAB 2: TUYẾN XỬ LÝ LÝ DO RÚT HỌC -->
    <div v-if="activeTab === 'REASONS'" class="uc-kpi-cfg__section">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Danh Mục Lý Do Rút Học &amp; Tuyến Xử Lý Quy Trách Nhiệm (tblKPI_CausalReasons)</div>
          <div class="uc-kpi-cfg__vnote">
            Phân định rõ Đơn vị giải trình (Hiệu trưởng) và Đơn vị xử lý nguyên nhân (Phòng chức năng, Vận hành xe, Kế toán, Y tế) kèm chỉ số cần soi tiếp.
          </div>
        </div>
      </div>

      <div class="uc-kpi-cfg__tablewrap">
        <table class="uc-kpi-cfg__table">
          <thead>
            <tr>
              <th class="ta-l">Mã Lý Do</th>
              <th class="ta-l">Tên Lý Do</th>
              <th class="ta-l">Người Xử Lý Nguyên Nhân</th>
              <th class="ta-l">Chỉ Số Cần Soi Tiếp</th>
              <th class="ta-l">Hành Động Đề Xuất</th>
              <th>Mức Kiểm Soát</th>
              <th>Thực tế lũy kế</th>
              <th>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in reasonsList" :key="r.ReasonCode">
              <td class="ta-l tx-strong">{{ r.ReasonCode }}</td>
              <td class="ta-l font-bold">{{ r.ReasonName }}</td>
              <td class="ta-l"><input type="text" v-model="r.ActionOwner" class="uc-kpi-cfg__input" style="width:160px;" /></td>
              <td class="ta-l"><input type="text" v-model="r.WatchIndicator" class="uc-kpi-cfg__input" style="width:220px;" /></td>
              <td class="ta-l"><input type="text" v-model="r.RecommendedAction" class="uc-kpi-cfg__input" style="width:260px;" /></td>
              <td>
                <select v-model="r.ControlLevel" class="uc-kpi-cfg__select">
                  <option value="Cao">Cao</option>
                  <option value="Trung bình">Trung bình</option>
                  <option value="Thấp">Thấp</option>
                  <option value="Chưa rõ">Chưa rõ</option>
                </select>
              </td>
              <td class="text-center font-bold">{{ r.HistoricalCount }} ca</td>
              <td>
                <button
                  type="button"
                  class="uc-kpi-cfg__btn is-save"
                  @click="saveReason(r)"
                >Lưu CSDL</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 5. TAB 3: KỊCH BẢN PHÂN TÍCH -->
    <div v-if="activeTab === 'SCENARIOS'" class="uc-kpi-cfg__section">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Danh Mục Kịch Bản Phân Tích (tblKPI_CausalScenarios)</div>
          <div class="uc-kpi-cfg__vnote">
            Các kịch bản vận hành phục vụ phân tích What-If cho Ban Điều Hành và Hội đồng trường.
          </div>
        </div>
      </div>

      <div class="uc-kpi-cfg__tablewrap">
        <table class="uc-kpi-cfg__table">
          <thead>
            <tr>
              <th class="ta-l">Mã Kịch Bản</th>
              <th class="ta-l">Tên Kịch Bản</th>
              <th class="ta-l">Mô Tả Nghiệp Vụ</th>
              <th>Đơn Vị Mặc Định</th>
              <th>Trạng Thái</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="s in scenariosList" :key="s.ScenarioCode">
              <td class="ta-l tx-strong">{{ s.ScenarioCode }}</td>
              <td class="ta-l font-bold">{{ s.ScenarioName }}</td>
              <td class="ta-l">{{ s.ScenarioDescription }}</td>
              <td class="text-center">{{ s.DefaultUnit }}</td>
              <td class="text-center"><span class="uc-kpi-cfg__tag is-good">Đang kích hoạt</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 6. TAB 4: PHÂN CÔNG TRÁCH NHIỆM -->
    <div v-if="activeTab === 'ASSIGNMENTS'" class="uc-kpi-cfg__section">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Quy Định Trách Nhiệm Phối Hợp ("Ai Phải Làm Gì" - tblKPI_CausalActionAssignments)</div>
          <div class="uc-kpi-cfg__vnote">
            Phân định nhiệm vụ tức thì của từng vai trò (Hiệu trưởng, Tuyển sinh, Kế toán) khi kịch bản xảy ra.
          </div>
        </div>
      </div>

      <div class="uc-kpi-cfg__tablewrap">
        <table class="uc-kpi-cfg__table">
          <thead>
            <tr>
              <th>ID</th>
              <th class="ta-l">Kịch Bản</th>
              <th class="ta-l">Mã Vai Trò</th>
              <th class="ta-l">Chức Danh Phụ Trách</th>
              <th class="ta-l">Hành Động Cụ Thể</th>
              <th>Thứ Tự</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="a in assignmentsList" :key="a.AssignmentID">
              <td>{{ a.AssignmentID }}</td>
              <td class="ta-l tx-strong">{{ a.ScenarioCode }}</td>
              <td class="ta-l font-mono">{{ a.RoleCode }}</td>
              <td class="ta-l font-bold">{{ a.RoleTitle }}</td>
              <td class="ta-l">{{ a.ActionDescription }}</td>
              <td class="text-center">{{ a.SortOrder }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 7. TAB 5: QUY TẮC IF/ELSE ĐỘNG -->
    <div v-if="activeTab === 'RULES'" class="uc-kpi-cfg__section">
      <div class="uc-kpi-cfg__vhead">
        <div>
          <div class="uc-kpi-cfg__vtitle">Danh Mục Quy Tắc IF / ELSE Động (tblKPI_CausalRules)</div>
          <div class="uc-kpi-cfg__vnote">
            Hệ thống tự động kích hoạt nhánh cảnh báo (BAD/WARN) khi dữ liệu snapshot chạm ngưỡng.
          </div>
        </div>
      </div>

      <div class="uc-kpi-cfg__tablewrap">
        <table class="uc-kpi-cfg__table">
          <thead>
            <tr>
              <th>ID</th>
              <th class="ta-l">Mã Quy Tắc</th>
              <th class="ta-l">Tên Quy Tắc</th>
              <th class="ta-l">Biểu Thức Điều Kiện (IF)</th>
              <th>Mức Độ Cảnh Báo</th>
              <th class="ta-l">Hệ Quả &amp; Nhận Định (THEN)</th>
              <th>Trạng Thái</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in rulesList" :key="r.RuleID">
              <td>{{ r.RuleID }}</td>
              <td class="ta-l tx-strong">{{ r.RuleCode }}</td>
              <td class="ta-l font-bold">{{ r.RuleName }}</td>
              <td class="ta-l font-mono text-xs bg-slate-100 p-1">{{ r.ConditionExpr }}</td>
              <td class="text-center">
                <span :class="['uc-kpi-cfg__tag', r.Severity === 'BAD' ? 'is-bad' : 'is-warn']">{{ r.Severity }}</span>
              </td>
              <td class="ta-l">{{ r.OutcomeSummary }}</td>
              <td class="text-center"><span class="uc-kpi-cfg__tag is-good">Đang áp dụng</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "uc-kpi-causal-config",
  data() {
    return {
      activeTab: "ASSUMPTIONS",
      isLoading: false,
      syncStatus: "Đang đồng bộ CSDL eSign...",
      scenariosList: [],
      assumptionsList: [],
      reasonsList: [],
      assignmentsList: [],
      rulesList: [],
    };
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
        if (res && res.data && Array.isArray(res.data)) {
          if (res.data[0]) this.scenariosList = res.data[0];
          if (res.data[1]) this.assumptionsList = res.data[1];
          if (res.data[2]) this.reasonsList = res.data[2];
          if (res.data[3]) this.assignmentsList = res.data[3];
          if (res.data[4]) this.rulesList = res.data[4];
        }
        this.syncStatus = "Đã kết nối CSDL eSign (5/5 bảng)";
      } catch (err) {
        console.warn("fetchData error:", err);
        this.syncStatus = "Lỗi kết nối CSDL";
      } finally {
        this.isLoading = false;
      }
    },
    async saveAssumption(u) {
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
        alert("Đã lưu tham số của " + u.UnitName + " vào CSDL eSign thành công!");
        this.fetchData();
      } catch (err) {
        alert("Lỗi khi lưu tham số: " + (err.message || err));
      }
    },
    async saveReason(r) {
      try {
        const payload = {
          ReasonCode: r.ReasonCode,
          ActionOwner: r.ActionOwner,
          WatchIndicator: r.WatchIndicator,
          RecommendedAction: r.RecommendedAction,
          ControlLevel: r.ControlLevel,
        };
        await this.callTapi("eSign/KPI_SaveCausalReason", payload);
        alert("Đã lưu tuyến xử lý lý do '" + r.ReasonName + "' vào CSDL eSign thành công!");
        this.fetchData();
      } catch (err) {
        alert("Lỗi khi lưu lý do: " + (err.message || err));
      }
    },
  },
};
</script>
