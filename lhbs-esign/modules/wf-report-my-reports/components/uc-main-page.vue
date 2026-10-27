<template>
	<uc-wf-shell>
    <div class="wf-page-header">
      <div>
        <h1>Thư viện widget</h1>
        <p>Danh sách widget cá nhân để mở lại, nhân bản và ghim vào bảng điều khiển.</p>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openBuilder">
          <v-icon start>mdi-plus</v-icon>
          Tạo widget
        </v-btn>
      </div>
    </div>

    <div class="wf-tcard wf-report-library-filter-card">
      <div class="wf-tcard-toolbar">
        <h3>Bộ lọc nhanh</h3>
      </div>
      <div class="wf-template-dialog-body">
        <v-row dense>
          <v-col cols="12" md="4">
            <v-text-field
              v-model="searchQuery"
              density="compact"
              prepend-inner-icon="mdi-magnify"
              variant="outlined"
              hide-details="auto"
              label="Tìm theo tên widget"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="datasetFilter"
              :items="datasetOptions"
              label="Dataset"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="chartFilter"
              :items="chartOptions"
              label="Chart"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="2">
            <v-select
              v-model="statusFilter"
              :items="statusOptions"
              label="Trạng thái"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
        </v-row>
      </div>
    </div>

    <div class="wf-tcard wf-report-library-card">
      <div class="wf-trow wf-trow-header wf-report-list-grid">
        <div>Tên widget</div>
        <div>Dataset</div>
        <div>Chart</div>
        <div>Chia sẻ</div>
        <div>Cập nhật</div>
        <div></div>
      </div>
      <div v-for="item in filteredReports" :key="item.id" class="wf-trow wf-report-list-grid">
        <div>
          <div class="wf-audit-title">{{ item.name }}</div>
          <div class="wf-audit-sub">{{ item.description }}</div>
        </div>
        <div>{{ item.dataset }}</div>
        <div><v-chip size="x-small" :color="item.isSystem ? '#c0841a' : '#217D46'" variant="tonal">{{ item.chart }}</v-chip></div>
        <div><v-chip size="x-small" :color="item.isSystem ? '#c0841a' : (item.shared ? '#335c9b' : '#6f7f8c')" variant="outlined">{{ item.isSystem ? 'Hệ thống' : (item.shared ? 'Đã share' : 'Cá nhân') }}</v-chip></div>
        <div>{{ item.updatedAt }}</div>
        <div class="wf-audit-actions">
          <v-btn icon size="x-small" variant="text" color="primary" @click="openDetail(item)"><v-icon size="14">mdi-open-in-new</v-icon></v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" :disabled="item.isSystem" @click="cloneReport(item)"><v-icon size="14">mdi-content-copy</v-icon></v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" :disabled="item.isSystem" @click="pinDashboard(item)"><v-icon size="14">mdi-pin-outline</v-icon></v-btn>
        </div>
      </div>
      <div v-if="filteredReports.length === 0" class="wf-empty-state">
        Không có widget nào khớp bộ lọc hiện tại.
      </div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: "uc-report-my-reports-page",
  data: function () {
    return {
      isLoading: false,
      searchQuery: "",
      datasetFilter: "Tất cả",
      chartFilter: "Tất cả",
      statusFilter: "Tất cả",
      systemReports: [
        {
          id: "system-admission-radar-dongnai",
          name: "Radar tuyển sinh Đồng Nai",
          description: "Widget nguồn thật cho tuyển sinh: quy mô học sinh, dân số dự báo và link Google Trends live.",
          dataset: "MOET + Google Trends + Đồng Nai quy hoạch",
          chart: "official_live",
          shared: true,
          isSystem: true,
          status: "Đang hoạt động",
          updatedAt: "22/03 23:59",
          targetUrl: "/wf-report-dashboard"
        }
      ],
      reports: [
        { id: 1, name: "Widget sản lượng hồ sơ theo tháng", description: "Theo dõi tăng trưởng hồ sơ ký qua từng tháng.", dataset: "Khối lượng hồ sơ ký", chart: "bar", shared: true, status: "Đang hoạt động", updatedAt: "20/03 22:10" },
        { id: 2, name: "Widget tỷ trọng trạng thái hồ sơ", description: "Pie chart để drill-down theo trạng thái hiện tại.", dataset: "Khối lượng hồ sơ ký", chart: "pie", shared: false, status: "Đang hoạt động", updatedAt: "20/03 22:08" },
        { id: 3, name: "Widget hiệu suất SmartCA theo gateway", description: "So sánh tỷ lệ thành công và response time giữa các gateway.", dataset: "Hiệu suất SmartCA", chart: "line", shared: true, status: "Nháp", updatedAt: "20/03 22:02" }
      ]
    }
  },
  mounted: function () {
    this.loadReports();
  },
  computed: {
    libraryRows: function () {
      return (this.systemReports || []).concat(this.reports || []);
    },
    datasetOptions: function () {
      var values = { "Tất cả": true };
      (this.libraryRows || []).forEach(function (item) {
        if (item && item.dataset) {
          values[item.dataset] = true;
        }
      });
      return Object.keys(values);
    },
    chartOptions: function () {
      var values = { "Tất cả": true };
      (this.libraryRows || []).forEach(function (item) {
        if (item && item.chart) {
          values[item.chart] = true;
        }
      });
      return Object.keys(values);
    },
    statusOptions: function () {
      var values = { "Tất cả": true };
      (this.libraryRows || []).forEach(function (item) {
        if (item && item.status) {
          values[item.status] = true;
        }
      });
      return Object.keys(values);
    },
    filteredReports: function () {
      var self = this;
      var rows = this.libraryRows || [];
      return rows.filter(function (item) {
        var matchSearch = !self.searchQuery || item.name.toLowerCase().indexOf(self.searchQuery.toLowerCase()) >= 0;
        var matchDataset = self.datasetFilter === "Tất cả" || item.dataset === self.datasetFilter;
        var matchChart = self.chartFilter === "Tất cả" || item.chart === self.chartFilter;
        var matchStatus = self.statusFilter === "Tất cả" || item.status === self.statusFilter;
        return matchSearch && matchDataset && matchChart && matchStatus;
      });
    }
  },
  methods: {
    loadReports: function () {
      var self = this;
      self.isLoading = true;
      apiCallAsync("WF_ReportDefinition_GetList", {
        Keyword: "",
        OnlyMine: 1
      }).then(function (resultSets) {
        var rows = self.extractReportDefinitionRows(resultSets);
        self.reports = self.mapReportRows(rows || []);
      }).catch(function () {
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được thư viện widget đã lưu.");
        }
      }).finally(function () {
        self.isLoading = false;
      });
    },
    formatDate: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (isNaN(dt.getTime())) return String(value);
      return dt.toLocaleString("vi-VN", { hour: "2-digit", minute: "2-digit", day: "2-digit", month: "2-digit" });
    },
    extractReportDefinitionRows: function (resultSets) {
      if (!resultSets) {
        return [];
      }
      if (Array.isArray(resultSets) && resultSets.length > 0) {
        if (Array.isArray(resultSets[0])) {
          return resultSets[0];
        }
        if (resultSets[0] && typeof resultSets[0] === "object" && resultSets[0].ReportDefinitionID !== undefined) {
          return resultSets;
        }
      }
      return [];
    },
    mapReportRows: function (rows) {
      var self = this;
      return (rows || []).map(function (item) {
        var config = self.tryParseJsonObject(item.ConfigJson, {});
        var chartKey = config.ChartType || item.ChartType || "bar";
        return {
          id: Number(item.ReportDefinitionID || 0),
          name: item.ReportName || "Widget",
          description: item.Description || "",
          dataset: item.DatasetName || item.DatasetCode || "-",
          chart: chartKey,
          shared: item.IsShared === true || item.IsShared === 1,
          status: item.IsActive === true || item.IsActive === 1 ? "Đang hoạt động" : "Nháp",
          updatedAt: self.formatDate(item.UpdateTime || item.CreateTime)
        };
      });
    },
    tryParseJsonObject: function (value, fallback) {
      if (!value) {
        return fallback || {};
      }
      if (typeof value === "object") {
        return value;
      }
      try {
        return JSON.parse(value);
      } catch (err) {
        return fallback || {};
      }
    },
    openBuilder: function () {
      window.location.href = "/wf-report-builder";
    },
    openDetail: function (item) {
      if (item && item.isSystem && item.targetUrl) {
        window.location.href = item.targetUrl;
        return;
      }
      window.location.href = "/wf-report-detail?id=" + item.id;
    },
    cloneReport: function (item) {
      if (typeof showToast !== "undefined") {
        showToast.info("Nhân bản widget sẽ làm ở phase tiếp theo.");
      }
    },
    pinDashboard: function (item) {
      apiCallAsync("WF_ReportDashboard_PinReport", {
        ReportDefinitionID: item.id
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã ghim widget lên bảng điều khiển.");
        }
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Ghim widget thất bại.");
        }
      });
    }
  }
	}
</script>