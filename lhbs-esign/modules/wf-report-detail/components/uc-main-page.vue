<template>
	<uc-wf-shell>
    <div class="wf-page-header">
      <div>
        <h1>Chi tiết widget</h1>
        <p>Xem drill-down thật theo từng nhóm dữ liệu và export nhanh từ cùng dataset engine.</p>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="backToReports">
          <v-icon start>mdi-arrow-left</v-icon>
          Quay lại
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" :disabled="detailRows.length === 0" @click="exportCsv">
          <v-icon start>mdi-file-delimited-outline</v-icon>
          Xuất CSV
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" :disabled="detailRows.length === 0" @click="exportExcel">
          <v-icon start>mdi-file-excel-outline</v-icon>
          Xuất Excel
        </v-btn>
      </div>
    </div>

    <div class="wf-report-detail-hero">
      <div>
        <div class="wf-report-detail-hero__tag">Widget detail</div>
        <h2>{{ reportTitle }}</h2>
        <p>Dataset: {{ datasetText }} · Chart: {{ chartText }} · Người tạo: {{ ownerText }}</p>
      </div>
      <v-chip size="small" color="primary" variant="tonal">{{ reportCodeText }}</v-chip>
    </div>

    <div class="wf-stat-strip wf-stat-strip--4">
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--all"><v-icon>mdi-shape-outline</v-icon></div>
        <div><div class="wf-stat-val">{{ activeGroupLabel }}</div><div class="wf-stat-lbl">Nhóm đang drill</div></div>
      </div>
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--waiting"><v-icon>mdi-format-list-bulleted</v-icon></div>
        <div><div class="wf-stat-val">{{ detailSummary.DetailRowCount || 0 }}</div><div class="wf-stat-lbl">Số dòng chi tiết</div></div>
      </div>
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--running"><v-icon>mdi-axis-arrow</v-icon></div>
        <div><div class="wf-stat-val">{{ dimensionText }}</div><div class="wf-stat-lbl">Dimension</div></div>
      </div>
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--completed"><v-icon>mdi-chart-bar</v-icon></div>
        <div><div class="wf-stat-val">{{ metricText }}</div><div class="wf-stat-lbl">Metric</div></div>
      </div>
    </div>

    <div class="wf-report-chart-card">
      <div class="wf-report-preview__head">
        <div>
          <h3>Kết quả preview</h3>
          <p>{{ previewSummaryText }}</p>
        </div>
        <v-chip size="small" color="primary" variant="tonal">{{ chartText }}</v-chip>
      </div>
      <div ref="chartEl" class="wf-report-chart"></div>
    </div>

    <div class="wf-report-table-card">
      <div class="wf-report-preview__head">
        <div>
          <h3>Nhóm dữ liệu</h3>
          <p>Click vào từng nhóm để thay đổi phạm vi drill-down.</p>
        </div>
      </div>
      <div class="wf-trow wf-trow-header wf-report-table-grid">
        <div>Nhóm dữ liệu</div>
        <div>Giá trị</div>
        <div>Xu hướng</div>
        <div>Tỷ trọng</div>
      </div>
      <div
        v-for="row in previewRows"
        :key="row.label"
        class="wf-trow wf-report-table-grid"
        :class="{ 'wf-report-row--active': activeGroupLabel === row.label }"
        @click="selectGroup(row.label)"
      >
        <div>
          <div class="wf-audit-title">{{ row.label }}</div>
          <div class="wf-audit-sub">{{ datasetText }}</div>
        </div>
        <div class="wf-report-strong">{{ formatNumber(getMetricValue(row)) }}</div>
        <div>
          <v-chip size="x-small" :color="row.delta >= 0 ? '#217D46' : '#c62828'" variant="tonal">
            {{ row.delta >= 0 ? '+' : '' }}{{ row.delta }}%
          </v-chip>
        </div>
        <div>{{ row.share }}%</div>
      </div>
      <div v-if="previewRows.length === 0" class="wf-empty-state">Chưa có dữ liệu preview.</div>
    </div>

    <div class="wf-report-table-card">
      <div class="wf-report-preview__head">
        <div>
          <h3>Dữ liệu chi tiết</h3>
          <p>{{ detailDescription }}</p>
        </div>
      </div>
      <div v-if="detailRows.length > 0" class="wf-audit-scroll">
        <table class="wf-report-detail-table">
          <thead>
            <tr>
              <th v-for="column in detailColumns" :key="column.key">{{ column.label }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, rowIndex) in detailRows" :key="rowIndex">
              <td v-for="column in detailColumns" :key="column.key">{{ formatDetailValue(row[column.key]) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="wf-empty-state">Không có dòng detail nào cho bộ lọc hiện tại.</div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: "uc-report-detail-page",
  data: function () {
    return {
      chart: null,
      report: {},
      previewSummary: null,
      previewRows: [],
      detailSummary: {},
      detailRows: [],
      runtimeConfig: {
        id: 0,
        dataset: "contract_volume",
        chart: "bar",
        dimension: "month",
        metric: "requestCount",
        range: "30 ngày gần nhất",
        status: "Tất cả",
        group: ""
      }
    }
  },
  computed: {
    reportTitle: function () {
      return this.report.ReportName || "Chi tiết widget";
    },
    datasetText: function () {
      return this.report.DatasetName || this.report.DatasetCode || this.runtimeConfig.dataset || "-";
    },
    chartText: function () {
      return this.runtimeConfig.chart || this.report.ChartType || "-";
    },
    ownerText: function () {
      return this.report.OwnerUserName || this.report.OwnerUserID || "Tạm thời";
    },
    reportCodeText: function () {
      return this.report.ReportCode || "Widget tạm thời";
    },
    activeGroupLabel: function () {
      return this.runtimeConfig.group || "Tất cả";
    },
    dimensionText: function () {
      return this.report.DimensionKey || this.runtimeConfig.dimension || "-";
    },
    metricText: function () {
      return this.report.MetricKey || this.runtimeConfig.metric || "-";
    },
    metricKey: function () {
      return this.report.MetricKey || this.runtimeConfig.metric || "requestCount";
    },
    previewSummaryText: function () {
      if (!this.previewSummary) {
        return "Chưa có dữ liệu preview.";
      }
      return "Top: " + (this.previewSummary.TopLabel || "-") + " · Tổng: " + this.previewSummary.TotalValue + " · Time range: " + (this.previewSummary.TimeRangeKey || this.runtimeConfig.range);
    },
    detailDescription: function () {
      return "Nhóm: " + this.activeGroupLabel + " · Tổng dòng: " + (this.detailSummary.DetailRowCount || 0) + " · Export theo đúng dữ liệu đang hiển thị.";
    },
    detailColumns: function () {
      if (!this.detailRows || this.detailRows.length === 0) {
        return [];
      }
      var preferred = this.runtimeConfig.dataset === "smartca_health"
        ? ["GroupLabel", "InstanceID", "ExecutionID", "SignerExecID", "ResolvedPersonName", "SignMethod", "SignerStatus", "ResultLabel", "GatewayLabel", "EventTime", "SignedDate", "ResponseSeconds", "ExecutionEngine", "ContractProvider", "InstanceStatus"]
        : ["GroupLabel", "InstanceID", "InstanceName", "StatusLabel", "CategoryName", "CreateUser", "CreateTime", "UpdateTime", "DurationHours", "ExecutionEngine", "ContractProvider", "CurrentStepOrder"];
      var row = this.detailRows[0];
      var keys = preferred.filter(function (key) {
        return Object.prototype.hasOwnProperty.call(row, key);
      });
      if (keys.length === 0) {
        keys = Object.keys(row);
      }
      return keys.map(function (key) {
        return {
          key: key,
          label: this.resolveDetailColumnLabel(key)
        };
      }, this);
    }
  },
  mounted: function () {
    this.readRuntimeConfig();
    this.loadReportDetail();
    window.addEventListener("resize", this.handleResize);
  },
  beforeUnmount: function () {
    window.removeEventListener("resize", this.handleResize);
    if (this.chart && this.chart.dispose) {
      this.chart.dispose();
      this.chart = null;
    }
  },
  methods: {
    handleResize: function () {
      if (this.chart && this.chart.resize) {
        this.chart.resize();
      }
    },
    readRuntimeConfig: function () {
      var params = new URLSearchParams(window.location.search || "");
      this.runtimeConfig.id = Number(params.get("id") || 0);
      this.runtimeConfig.dataset = params.get("dataset") || this.runtimeConfig.dataset;
      this.runtimeConfig.chart = params.get("chart") || this.runtimeConfig.chart;
      this.runtimeConfig.dimension = params.get("dimension") || this.runtimeConfig.dimension;
      this.runtimeConfig.metric = params.get("metric") || this.runtimeConfig.metric;
      this.runtimeConfig.range = params.get("range") || this.runtimeConfig.range;
      this.runtimeConfig.status = params.get("status") || this.runtimeConfig.status;
      this.runtimeConfig.group = params.get("group") || "";
    },
    buildApiPayload: function () {
      return {
        ReportDefinitionID: this.runtimeConfig.id || 0,
        DatasetCode: this.runtimeConfig.dataset,
        ChartType: this.runtimeConfig.chart,
        DimensionKey: this.runtimeConfig.dimension,
        MetricKey: this.runtimeConfig.metric,
        TimeRangeKey: this.runtimeConfig.range,
        StatusFilter: this.runtimeConfig.status,
        GroupLabel: this.runtimeConfig.group
      };
    },
    loadReportDetail: function () {
      var self = this;
      if (!self.runtimeConfig.id) {
        self.loadPreview();
        return;
      }
      apiCallAsync("WF_ReportDefinition_GetDetail", {
        ReportDefinitionID: self.runtimeConfig.id
      }).then(function (resultSets) {
        self.report = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : {};
        var config = self.tryParseJsonObject(self.report.ConfigJson, {});
        self.runtimeConfig.dataset = self.report.DatasetCode || self.runtimeConfig.dataset;
        self.runtimeConfig.chart = config.ChartType || self.report.ChartType || self.runtimeConfig.chart;
        self.runtimeConfig.dimension = self.report.DimensionKey || self.runtimeConfig.dimension;
        self.runtimeConfig.metric = self.report.MetricKey || self.runtimeConfig.metric;
        self.runtimeConfig.range = self.report.TimeRangeKey || self.runtimeConfig.range;
        self.runtimeConfig.status = self.report.StatusFilter || self.runtimeConfig.status;
        self.loadPreview();
      }).catch(function () {
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được chi tiết widget.");
        }
        self.loadPreview();
      });
    },
    loadPreview: function () {
      var self = this;
      apiCallAsync("WF_Report_RunPreview", self.buildApiPayload()).then(function (resultSets) {
        self.previewSummary = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        self.previewRows = ((resultSets && resultSets[1]) || []).map(function (item) {
          return {
            label: item.Label,
            value: Number(item.MetricValue || 0),
            requestCount: Number(item.RequestCount || 0),
            completedRate: Number(item.CompletedRate || 0),
            slaHours: Number(item.SlaHours || 0),
            delta: Number(item.DeltaValue || 0),
            share: Number(item.ShareValue || 0)
          };
        });
        if (!self.runtimeConfig.group && self.previewRows.length > 0) {
          self.runtimeConfig.group = self.previewRows[0].label;
        }
        self.loadDetail();
      }).catch(function () {
        self.previewSummary = null;
        self.previewRows = [];
        self.detailSummary = {};
        self.detailRows = [];
      }).finally(function () {
        self.$nextTick(function () {
          self.renderChart();
        });
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
    loadDetail: function () {
      var self = this;
      apiCallAsync("WF_Report_RunDetail", self.buildApiPayload()).then(function (resultSets) {
        self.detailSummary = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : {};
        self.detailRows = (resultSets && resultSets[1]) || [];
      }).catch(function () {
        self.detailSummary = {};
        self.detailRows = [];
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được dữ liệu drill-down.");
        }
      });
    },
    renderChart: function () {
      if (!this.$refs.chartEl || !window.echarts) {
        return;
      }
      if (!this.chart) {
        this.chart = window.echarts.init(this.$refs.chartEl);
      }
      var labels = this.previewRows.map(function (item) { return item.label; });
      var values = this.previewRows.map(function (item) { return Number(item.value || 0); });
      var series = [];
      if (this.chartText === "pie") {
        series = [{
          type: "pie",
          radius: ["34%", "68%"],
          center: ["50%", "54%"],
          label: { formatter: "{b}\n{d}%", fontSize: 11 },
          data: labels.map(function (label, index) {
            return { name: label, value: values[index] };
          })
        }];
      } else if (this.chartText === "line") {
        series = [{
          type: "line",
          smooth: true,
          symbolSize: 8,
          lineStyle: { width: 3 },
          areaStyle: { opacity: 0.12 },
          data: values
        }];
      } else {
        series = [{
          type: "bar",
          barMaxWidth: 38,
          borderRadius: [6, 6, 0, 0],
          data: values
        }];
      }
      this.chart.setOption({
        color: ["#217D46", "#E5A812", "#185d34", "#7abf92", "#f3ca67"],
        tooltip: { trigger: this.chartText === "pie" ? "item" : "axis" },
        grid: { left: 24, right: 20, top: 40, bottom: 28, containLabel: true },
        xAxis: this.chartText === "pie" ? null : {
          type: "category",
          data: labels,
          axisLabel: { color: "#5f6368", fontSize: 11 }
        },
        yAxis: this.chartText === "pie" ? null : {
          type: "value",
          axisLabel: { color: "#5f6368", fontSize: 11 },
          splitLine: { lineStyle: { color: "#eef1f4" } }
        },
        series: series
      }, true);
      this.chart.off("click");
      this.chart.on("click", function (params) {
        if (params && params.name) {
          this.selectGroup(params.name);
        }
      }.bind(this));
    },
    selectGroup: function (groupLabel) {
      this.runtimeConfig.group = groupLabel || "";
      this.syncQueryString();
      this.loadDetail();
    },
    syncQueryString: function () {
      var params = new URLSearchParams();
      if (this.runtimeConfig.id) params.set("id", String(this.runtimeConfig.id));
      if (this.runtimeConfig.dataset) params.set("dataset", this.runtimeConfig.dataset);
      if (this.runtimeConfig.chart) params.set("chart", this.runtimeConfig.chart);
      if (this.runtimeConfig.dimension) params.set("dimension", this.runtimeConfig.dimension);
      if (this.runtimeConfig.metric) params.set("metric", this.runtimeConfig.metric);
      if (this.runtimeConfig.range) params.set("range", this.runtimeConfig.range);
      if (this.runtimeConfig.status) params.set("status", this.runtimeConfig.status);
      if (this.runtimeConfig.group) params.set("group", this.runtimeConfig.group);
      window.history.replaceState({}, "", "/wf-report-detail?" + params.toString());
    },
    getMetricValue: function (row) {
      return Number(row[this.metricKey] || row.value || 0);
    },
    formatNumber: function (value) {
      return Number(value || 0).toLocaleString("vi-VN");
    },
    formatDetailValue: function (value) {
      if (value === null || value === undefined || value === "") {
        return "-";
      }
      if (typeof value === "number") {
        return Number(value).toLocaleString("vi-VN");
      }
      var text = String(value);
      var dt = new Date(text);
      if (!isNaN(dt.getTime()) && text.indexOf("-") >= 0) {
        return dt.toLocaleString("vi-VN");
      }
      return text;
    },
    resolveDetailColumnLabel: function (key) {
      var map = {
        GroupLabel: "Nhóm dữ liệu",
        InstanceID: "Instance ID",
        InstanceName: "Tên hồ sơ",
        StatusLabel: "Trạng thái",
        CategoryName: "Đơn vị",
        CreateUser: "Người tạo",
        CreateTime: "Thời gian tạo",
        UpdateTime: "Cập nhật cuối",
        DurationHours: "Thời lượng (giờ)",
        ExecutionEngine: "Engine",
        ContractProvider: "Provider",
        CurrentStepOrder: "Bước hiện tại",
        ExecutionID: "Execution ID",
        SignerExecID: "SignerExec ID",
        ResolvedPersonID: "Mã người ký",
        ResolvedPersonName: "Người ký",
        SignMethod: "Phương thức ký",
        SignerStatus: "Trạng thái signer",
        ResultLabel: "Kết quả",
        GatewayLabel: "Gateway",
        EventTime: "Thời điểm",
        SignedDate: "Ký lúc",
        ResponseSeconds: "Thời gian phản hồi (giây)",
        InstanceStatus: "Trạng thái hồ sơ",
        MetricValue: "Giá trị",
        RequestCount: "Số lượng",
        CompletedRate: "Tỷ lệ hoàn tất",
        SlaHours: "SLA / Phản hồi"
      };
      return map[key] || key;
    },
    exportCsv: function () {
      this.downloadTextFile(this.buildCsvContent(), "text/csv;charset=utf-8;", this.buildExportFileName("csv"));
    },
    exportExcel: function () {
      this.downloadTextFile(this.buildExcelContent(), "application/vnd.ms-excel;charset=utf-8;", this.buildExportFileName("xls"));
    },
    buildCsvContent: function () {
      var lines = [];
      var headers = this.detailColumns.map(function (column) { return '"' + column.label + '"'; });
      var self = this;
      lines.push(headers.join(","));
      this.detailRows.forEach(function (row) {
        var values = self.detailColumns.map(function (column) {
          var text = self.formatDetailValue(row[column.key]);
          return '"' + String(text).replace(/"/g, '""') + '"';
        });
        lines.push(values.join(","));
      });
      return "\ufeff" + lines.join("\n");
    },
    buildExcelContent: function () {
      var html = [];
      var self = this;
      html.push("<table><thead><tr>");
      this.detailColumns.forEach(function (column) {
        html.push("<th>" + column.label + "</th>");
      });
      html.push("</tr></thead><tbody>");
      this.detailRows.forEach(function (row) {
        html.push("<tr>");
        self.detailColumns.forEach(function (column) {
          html.push("<td>" + self.escapeHtml(self.formatDetailValue(row[column.key])) + "</td>");
        });
        html.push("</tr>");
      });
      html.push("</tbody></table>");
      return "\ufeff" + html.join("");
    },
    downloadTextFile: function (content, mimeType, fileName) {
      var blob = new Blob([content], { type: mimeType });
      var url = window.URL.createObjectURL(blob);
      var link = document.createElement("a");
      link.href = url;
      link.download = fileName;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    },
    buildExportFileName: function (ext) {
      var parts = [
        this.runtimeConfig.dataset || "report",
        this.runtimeConfig.dimension || "detail",
        this.activeGroupLabel || "all"
      ];
      return parts.join("-").replace(/\s+/g, "_") + "." + ext;
    },
    escapeHtml: function (input) {
      return String(input)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
    },
    backToReports: function () {
      window.location.href = this.runtimeConfig.id ? "/wf-report-my-reports" : "/wf-report-builder";
    }
  }
	}
</script>