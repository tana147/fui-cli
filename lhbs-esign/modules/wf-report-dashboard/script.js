// sync-touch: 2026-03-23 dashboard-runtime
window.__WF_REPORT_DASHBOARD_VERSION__ = "2026-03-21-rowindex-layout-v1";
var wfReportDashboardCanvasMixin = {
  data: function () {
    return {
      chartInstances: {},
      isSavingLayout: false,
      isWidgetPickerOpen: false,
      dashboardQueryId: 0,
      dashboardId: 0,
      dashboardName: "Bảng điều khiển của tôi",
      dashboardSections: [],
      dashboardRegions: [],
      dashboardWidgets: [],
      widgetRuntimeCache: {},
      widgetLoadQueue: [],
      widgetLoadPromiseMap: {},
      pendingChartRenderHandles: {},
      pendingChartRenderQueue: [],
      widgetVisibleMap: {},
      widgetObserver: null,
      activeWidgetLoadCount: 0,
      activeChartRenderKey: "",
      maxConcurrentWidgetLoads: 2,
      widgetLoadingMinMs: 350,
      datasetMetaMap: {},
      datasetCatalogPromise: null,
      widgetLibrary: [],
      systemWidgetLibrary: [],
      widgetPickerSearch: "",
      selectedLayoutTemplate: "single",
      selectedSectionId: "",
      selectedRegionId: "",
      isSectionComposerOpen: false,
      sectionComposerMode: "create",
      sectionComposerSectionId: "",
      pendingSectionTitle: "Section mới",
      pendingSectionLayout: "single",
      draggingRegionId: "",
      dropTargetRegionId: "",
      tablePageSizeOptions: [10, 20, 50, 100],
      globalRange: "30 ngày gần nhất",
      globalStatus: "Tất cả",
      globalDatasetFilter: "Tất cả",
      globalChartFilter: "Tất cả",
      globalSearchQuery: ""
    }
  },
  computed: {
    layoutTemplateOptions: function () {
      return [
        { title: "1 vùng toàn màn", value: "single" },
        { title: "2 vùng đều", value: "two_equal" },
        { title: "3 vùng đều", value: "three_equal" },
        { title: "Tỷ lệ 1:3", value: "ratio_1_3" },
        { title: "Tỷ lệ 3:1", value: "ratio_3_1" },
        { title: "Tỷ lệ 1:3:1", value: "ratio_1_3_1" },
        { title: "Tỷ lệ 1:4", value: "ratio_1_4" },
        { title: "1 hero + 2 dưới", value: "hero_two_bottom" },
        { title: "2 trên + 1 wide dưới", value: "two_top_one_bottom" },
        { title: "Sidebar trái + nội dung phải", value: "sidebar_left_content_right" }
      ];
    },
    layoutTemplateCards: function () {
      var descriptions = {
        single: "Một vùng lớn cho matrix hoặc chart tổng quan.",
        two_equal: "Hai vùng cân bằng cho 2 biểu đồ hoặc 1 chart + 1 bảng.",
        three_equal: "Ba vùng đều cho KPI hoặc bộ chart so sánh nhanh.",
        ratio_1_3: "Một vùng hẹp bên trái, vùng nội dung chính bên phải.",
        ratio_3_1: "Vùng chính bên trái, vùng phụ nhỏ bên phải.",
        ratio_1_3_1: "Ba vùng theo tỷ lệ hẹp - rộng - hẹp.",
        ratio_1_4: "Một cột chỉ số nhỏ và một vùng phân tích rất rộng.",
        hero_two_bottom: "Một vùng hero ở trên, hai vùng nhỏ phía dưới.",
        two_top_one_bottom: "Hai vùng ngang ở trên, một vùng wide bên dưới.",
        sidebar_left_content_right: "Sidebar bên trái, khu vực chính bên phải."
      };
      return (this.layoutTemplateOptions || []).map(function (item) {
        return {
          title: item.title,
          value: item.value,
          description: descriptions[item.value] || "Mẫu layout section."
        };
      });
    },
    rangeOptions: function () {
      return ["7 ngày gần nhất", "30 ngày gần nhất", "Quý này", "Năm nay"];
    },
    statusOptions: function () {
      return ["Tất cả", "Đang hoạt động", "Chỉ hoàn tất", "Cần xử lý"];
    },
    canvasDatasetOptions: function () {
      var options = ["Tất cả"];
      var seen = {};
      ;(this.dashboardRegions || []).forEach(function (region) {
        var item = region && region.widgetId ? this.getRegionWidget(region) : null;
        if (item && item.dataset && !seen[item.dataset]) {
          seen[item.dataset] = true;
          options.push(item.dataset);
        }
      }.bind(this));
      return options;
    },
    canvasChartOptions: function () {
      var options = ["Tất cả"];
      var seen = {};
      ;(this.dashboardRegions || []).forEach(function (region) {
        var item = region && region.widgetId ? this.getRegionWidget(region) : null;
        if (item && item.chart && !seen[item.chart]) {
          seen[item.chart] = true;
          options.push(item.chart);
        }
      }.bind(this));
      return options;
    },
    visibleDashboardWidgets: function () {
      var self = this;
      return (this.dashboardRegions || []).map(function (region) {
        return region && region.widgetId ? self.getRegionWidget(region) : null;
      }).filter(function (item) {
        return !!item;
      }).filter(function (item) {
        var matchDataset = self.globalDatasetFilter === "Tất cả" || item.dataset === self.globalDatasetFilter;
        var matchChart = self.globalChartFilter === "Tất cả" || item.chart === self.globalChartFilter;
        var matchSearch = !self.globalSearchQuery || String(item.name || "").toLowerCase().indexOf(String(self.globalSearchQuery || "").toLowerCase()) >= 0;
        return matchDataset && matchChart && matchSearch;
      });
    },
    statCards: function () {
      var datasets = {};
      var tableLikeCount = 0;
      var chartCount = 0;
      ;(this.visibleDashboardWidgets || []).forEach(function (item) {
        if (item && item.dataset) {
          datasets[item.dataset] = true;
        }
        if (item && (item.chart === "table" || item.chart === "matrix")) {
          tableLikeCount += 1;
        } else {
          chartCount += 1;
        }
      });
      return [
        { label: "Widget trên bảng", value: String(this.visibleDashboardWidgets.length), icon: "mdi-view-dashboard-outline", iconClass: "wf-stat-icon--all" },
        { label: "Nguồn dữ liệu", value: String(Object.keys(datasets).length), icon: "mdi-database-outline", iconClass: "wf-stat-icon--running" },
        { label: "Widget biểu đồ", value: String(chartCount), icon: "mdi-chart-bar-stacked", iconClass: "wf-stat-icon--completed" },
        { label: "Widget bảng", value: String(tableLikeCount), icon: "mdi-table-large", iconClass: "wf-stat-icon--waiting" }
      ];
    },
    dashboardSummaryText: function () {
      if (!this.dashboardSections.length) {
        return "Canvas còn trống. Hãy tạo section trước, chọn layout, rồi gắn widget vào từng vùng.";
      }
      return "Có " + this.dashboardSections.length + " section, " + this.dashboardRegions.length + " vùng trên canvas, trong đó " + this.visibleDashboardWidgets.length + " vùng đã có widget khớp bộ lọc hiện tại.";
    },
    renderedSections: function () {
      var self = this;
      return (this.dashboardSections || []).slice().sort(function (a, b) {
        return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
      }).map(function (section) {
        var regions = self.getSectionRegions(section.sectionId);
        return {
          sectionId: section.sectionId,
          title: section.title,
          layoutCode: section.layoutCode || "single",
          sortOrder: section.sortOrder || 1,
          regions: regions,
          rows: self.buildRegionRows(regions)
        };
      });
    },
    canvasRegionRows: function () {
      return this.buildRegionRows(this.dashboardRegions || []);
    },
    filteredWidgetLibrary: function () {
      var self = this;
      var pinnedMap = {};
      ;(this.dashboardRegions || []).forEach(function (region) {
        if (region && region.widgetId) {
          pinnedMap[String(region.widgetId || 0)] = true;
        }
      });
      return (this.widgetLibrary || []).filter(function (item) {
        return !self.widgetPickerSearch || String(item.name || "").toLowerCase().indexOf(String(self.widgetPickerSearch || "").toLowerCase()) >= 0;
      }).map(function (item) {
        return {
          id: item.id,
          name: item.name,
          dataset: item.dataset,
          chart: item.chart,
          updatedAt: item.updatedAt,
          isPinned: !!pinnedMap[String(item.id || 0)],
          isSystem: !!item.isSystem,
          systemKey: item.systemKey || ""
        };
      });
    }
  },
  watch: {
    globalDatasetFilter: function () {
      this.$nextTick(function () {
        this.renderAllCharts();
      }.bind(this));
    },
    globalChartFilter: function () {
      this.$nextTick(function () {
        this.renderAllCharts();
      }.bind(this));
    },
    globalSearchQuery: function () {
      this.$nextTick(function () {
        this.renderAllCharts();
      }.bind(this));
    }
  },
  mounted: function () {
    this.readRuntimeConfig();
    this.loadDashboard();
    window.addEventListener("resize", this.handleResize);
  },
  beforeUnmount: function () {
    window.removeEventListener("resize", this.handleResize);
    this.disconnectWidgetObserver();
    this.cancelAllPendingChartRenders();
    this.disposeAllCharts();
  },
  methods: {
    getResultSet: function (resultSets, index) {
      var normalized = resultSets;
      if (normalized && Array.isArray(normalized.data)) {
        normalized = normalized.data;
      }
      if (!Array.isArray(normalized)) {
        return [];
      }
      if (normalized.length && Array.isArray(normalized[0])) {
        return normalized[index] || [];
      }
      return index === 0 ? normalized : [];
    },
    handleResize: function () {
      var self = this;
      Object.keys(this.chartInstances || {}).forEach(function (key) {
        if (self.chartInstances[key] && self.chartInstances[key].resize) {
          self.chartInstances[key].resize();
        }
      });
    },
    readRuntimeConfig: function () {
      var params = new URLSearchParams(window.location.search || "");
      this.dashboardQueryId = Number(params.get("id") || 0);
    },
    loadDashboard: function () {
      var self = this;
      var apiName = self.dashboardQueryId > 0 ? "WF_ReportDashboard_GetDetail" : "WF_ReportDashboard_GetMy";
      var apiPayload = self.dashboardQueryId > 0 ? { ReportDashboardID: self.dashboardQueryId } : {};
      apiCallAsync(apiName, apiPayload).then(function (resultSets) {
        var dashboardRows = self.getResultSet(resultSets, 0);
        var widgetRows = self.getResultSet(resultSets, 1);
        var dashboard = dashboardRows && dashboardRows[0] ? dashboardRows[0] : null;
        var widgets = widgetRows || [];
        var layout = self.tryParseJsonObject(dashboard && dashboard.LayoutJson, {});
        if (dashboard) {
          self.dashboardId = Number(dashboard.ReportDashboardID || 0);
          self.dashboardQueryId = self.dashboardId;
          self.dashboardName = dashboard.DashboardName || self.dashboardName;
        }
        self.dashboardWidgets = (widgets || []).map(function (item, index) {
          var itemConfig = self.tryParseJsonObject(item.ConfigJson, {});
          return {
            reportDefinitionId: Number(item.ReportDefinitionID || 0),
            name: item.WidgetTitle || item.ReportName || ("Widget " + (index + 1)),
            dataset: item.DatasetName || item.DatasetCode || "-",
            chart: itemConfig.ChartType || item.ChartType || "bar",
            updatedAt: self.formatDate(item.UpdateTime || item.CreateTime),
            sortOrder: Number(item.SortOrder || index + 1),
            gridX: Number(item.GridX || 0),
            gridY: Number(item.GridY || 0),
            gridW: Number(item.GridW || 4),
            gridH: Number(item.GridH || 3),
            sizePreset: self.resolveSizePreset(item.GridW, item.GridH),
            previewSummary: null,
            previewRows: [],
            tableDetailRows: [],
            formulaColumns: [],
            tableConfig: {},
            datasetCode: item.DatasetCode || "",
            dimensionKey: "",
            metricKey: "",
            isLoading: true,
            error: ""
          };
        }).sort(function (a, b) {
          return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
        });
        self.dashboardRegions = self.resolveRegions(layout, self.dashboardWidgets);
        self.dashboardWidgets = self.mergeSystemWidgetsFromLayout(self.dashboardWidgets, self.dashboardRegions);
        self.dashboardSections = self.resolveSections(layout, self.dashboardRegions);
        self.ensureRegionsHaveSection();
        self.selectedSectionId = self.selectedSectionId || (self.dashboardSections[0] ? self.dashboardSections[0].sectionId : "");
        self.systemWidgetLibrary = self.buildSystemWidgetLibrary();
        self.loadWidgetRuntime();
      }).catch(function () {
        self.dashboardSections = [];
        self.dashboardRegions = [];
        self.dashboardWidgets = [];
        self.systemWidgetLibrary = self.buildSystemWidgetLibrary();
        self.disposeAllCharts();
      });
    },
    loadWidgetRuntime: function () {
      var self = this;
      self.disconnectWidgetObserver();
      self.widgetLoadQueue = [];
      self.widgetLoadPromiseMap = {};
      self.activeWidgetLoadCount = 0;
      if (!self.dashboardWidgets.length) {
        self.disposeAllCharts();
        return;
      }
      (self.dashboardWidgets || []).forEach(function (item) {
        self.markWidgetLoading(item);
        item.error = "";
      });
      self.disposeAllCharts();
      self.$nextTick(function () {
        self.observeWidgetCards();
        self.queueInitialWidgetLoads();
      });
    },
    loadSingleWidgetRuntime: function (item, forceReload) {
      var self = this;
      var cacheKey = self.getWidgetCacheKey(item);
      var runtimeKey = self.getWidgetRuntimeKey(item);
      var cached = null;
      if (!item) {
        return Promise.resolve(null);
      }
      if (!forceReload) {
        cached = self.widgetRuntimeCache[cacheKey];
        if (cached && !self.isWidgetCacheExpired(cached)) {
          self.applyWidgetRuntimeCache(item, cached);
          return Promise.resolve(item);
        }
        if (self.widgetLoadPromiseMap[runtimeKey]) {
          return self.widgetLoadPromiseMap[runtimeKey];
        }
      }
      self.markWidgetLoading(item);
      item.error = "";
      if (item && item.isSystem) {
        self.widgetLoadPromiseMap[runtimeKey] = self.loadSystemWidgetRuntime(item).then(function () {
          self.storeWidgetRuntimeCache(item);
          return item;
        }).finally(function () {
          delete self.widgetLoadPromiseMap[runtimeKey];
        });
        return self.widgetLoadPromiseMap[runtimeKey];
      }
      self.widgetLoadPromiseMap[runtimeKey] = Promise.all([
        apiCallAsync("WF_ReportDefinition_GetDetail", {
          ReportDefinitionID: item.reportDefinitionId
        }).catch(function () {
          return [];
        }),
        apiCallAsync("WF_Report_RunPreview", {
          ReportDefinitionID: item.reportDefinitionId,
          TimeRangeKey: self.globalRange,
          StatusFilter: self.globalStatus
        }).catch(function () {
          return [];
        })
      ]).then(function (responses) {
        var detailSets = responses[0];
        var previewSets = responses[1];
        var detailRows = self.getResultSet(detailSets, 0);
        var previewSummaryRows = self.getResultSet(previewSets, 0);
        var previewDataRows = self.getResultSet(previewSets, 1);
        var detail = detailRows && detailRows[0] ? detailRows[0] : null;
        var config = self.tryParseJsonObject(detail && detail.ConfigJson, {});
        item.chart = config.ChartType || (detail && detail.ChartType ? detail.ChartType : item.chart);
        item.dataset = detail && (detail.DatasetName || detail.DatasetCode) ? (detail.DatasetName || detail.DatasetCode) : item.dataset;
        item.datasetCode = detail && detail.DatasetCode ? detail.DatasetCode : item.datasetCode;
        item.dimensionKey = detail && detail.DimensionKey ? detail.DimensionKey : "";
        item.metricKey = detail && detail.MetricKey ? detail.MetricKey : "";
        item.formulaColumns = Array.isArray(config.FormulaColumns) ? config.FormulaColumns : [];
        item.tableConfig = config.TableConfig || {};
        item.previewSummary = previewSummaryRows && previewSummaryRows[0] ? previewSummaryRows[0] : null;
        item.previewRows = previewDataRows ? self.mapPreviewRows(previewDataRows, detail) : [];
        if (self.isDataTableWidget(item)) {
          return apiCallAsync("WF_Report_RunDetail", {
            ReportDefinitionID: item.reportDefinitionId,
            DatasetCode: detail && detail.DatasetCode ? detail.DatasetCode : "",
            ChartType: config.ChartType || item.chart || "table",
            DimensionKey: detail && detail.DimensionKey ? detail.DimensionKey : "",
            MetricKey: detail && detail.MetricKey ? detail.MetricKey : "",
            TimeRangeKey: self.globalRange,
            StatusFilter: self.globalStatus,
            GroupLabel: ""
          }).then(function (detailResultSets) {
            item.tableDetailRows = self.getResultSet(detailResultSets, 1) || [];
            if (item.tableDetailRows && item.tableDetailRows.length > 0) {
              return self.finishWidgetLoading(item).then(function () {
                self.storeWidgetRuntimeCache(item);
              });
            }
            return self.tryLoadFileTableRows(detail && detail.DatasetCode ? detail.DatasetCode : item.datasetCode).then(function (fileRows) {
              item.tableDetailRows = fileRows || [];
              return self.finishWidgetLoading(item).then(function () {
                self.storeWidgetRuntimeCache(item);
              });
            }).catch(function () {
              item.tableDetailRows = [];
              return self.finishWidgetLoading(item).then(function () {
                self.storeWidgetRuntimeCache(item);
              });
            });
          }).catch(function () {
            return self.tryLoadFileTableRows(detail && detail.DatasetCode ? detail.DatasetCode : item.datasetCode).then(function (fileRows) {
              item.tableDetailRows = fileRows || [];
              return self.finishWidgetLoading(item).then(function () {
                self.storeWidgetRuntimeCache(item);
              });
            }).catch(function () {
              item.tableDetailRows = [];
              return self.finishWidgetLoading(item).then(function () {
                self.storeWidgetRuntimeCache(item);
              });
            });
          });
        }
        item.tableDetailRows = [];
        return self.finishWidgetLoading(item).then(function () {
          if (!item.previewRows.length) {
            item.error = "Widget chưa có dữ liệu preview để hiển thị.";
          }
          self.storeWidgetRuntimeCache(item);
        });
      }).catch(function () {
        item.error = "Không tải được dữ liệu của widget này.";
        item.tableDetailRows = [];
        return self.finishWidgetLoading(item);
      }).finally(function () {
        delete self.widgetLoadPromiseMap[runtimeKey];
      });
      return self.widgetLoadPromiseMap[runtimeKey];
    },
    getWidgetRuntimeKey: function (item) {
      if (!item) {
        return "";
      }
      if (item.isSystem) {
        return "system:" + String(item.systemKey || item.reportDefinitionId || "unknown");
      }
      return "report:" + String(item.reportDefinitionId || "0");
    },
    getWidgetCacheKey: function (item) {
      return [
        this.getWidgetRuntimeKey(item),
        String(this.globalRange || ""),
        String(this.globalStatus || ""),
        String(item && item.chart ? item.chart : ""),
        JSON.stringify(item && item.tableConfig ? item.tableConfig : {}),
        JSON.stringify(item && item.formulaColumns ? item.formulaColumns : [])
      ].join("|");
    },
    isWidgetCacheExpired: function (entry) {
      var loadedAt = entry && entry.loadedAt ? Number(entry.loadedAt) : 0;
      if (!loadedAt) {
        return true;
      }
      return (Date.now() - loadedAt) > 120000;
    },
    storeWidgetRuntimeCache: function (item) {
      var cacheKey = this.getWidgetCacheKey(item);
      this.widgetRuntimeCache[cacheKey] = {
        loadedAt: Date.now(),
        chart: item.chart,
        dataset: item.dataset,
        datasetCode: item.datasetCode,
        dimensionKey: item.dimensionKey,
        metricKey: item.metricKey,
        previewSummary: this.cloneWidgetRuntimeValue(item.previewSummary),
        previewRows: this.cloneWidgetRuntimeValue(item.previewRows || []),
        tableDetailRows: this.cloneWidgetRuntimeValue(item.tableDetailRows || []),
        formulaColumns: this.cloneWidgetRuntimeValue(item.formulaColumns || []),
        tableConfig: this.cloneWidgetRuntimeValue(item.tableConfig || {}),
        error: item.error || ""
      };
    },
    applyWidgetRuntimeCache: function (item, entry) {
      item.chart = entry.chart || item.chart;
      item.dataset = entry.dataset || item.dataset;
      item.datasetCode = entry.datasetCode || item.datasetCode;
      item.dimensionKey = entry.dimensionKey || item.dimensionKey;
      item.metricKey = entry.metricKey || item.metricKey;
      item.previewSummary = this.cloneWidgetRuntimeValue(entry.previewSummary || null);
      item.previewRows = this.cloneWidgetRuntimeValue(entry.previewRows || []);
      item.tableDetailRows = this.cloneWidgetRuntimeValue(entry.tableDetailRows || []);
      item.formulaColumns = this.cloneWidgetRuntimeValue(entry.formulaColumns || []);
      item.tableConfig = this.cloneWidgetRuntimeValue(entry.tableConfig || {});
      item.error = entry.error || "";
      item.isLoading = false;
    },
    cloneWidgetRuntimeValue: function (value) {
      if (value === null || value === undefined) {
        return value;
      }
      return JSON.parse(JSON.stringify(value));
    },
    markWidgetLoading: function (item) {
      if (!item) {
        return;
      }
      item.__loadingStartedAt = Date.now();
      item.isLoading = true;
    },
    finishWidgetLoading: function (item) {
      var self = this;
      var startedAt = item && item.__loadingStartedAt ? Number(item.__loadingStartedAt) : 0;
      var waitMs = startedAt ? Math.max(0, Number(self.widgetLoadingMinMs || 0) - (Date.now() - startedAt)) : 0;
      return new Promise(function (resolve) {
        window.setTimeout(function () {
          if (item) {
            item.isLoading = false;
            item.__loadingStartedAt = 0;
          }
          resolve();
        }, waitMs);
      });
    },
    observeWidgetCards: function () {
      var self = this;
      var cards = [];
      self.disconnectWidgetObserver();
      if (typeof IntersectionObserver === "undefined") {
        self.queueInitialWidgetLoads();
        return;
      }
      self.widgetObserver = new IntersectionObserver(function (entries) {
        self.handleWidgetIntersection(entries);
      }, {
        root: null,
        rootMargin: "200px 0px 200px 0px",
        threshold: 0.15
      });
      cards = Array.prototype.slice.call(document.querySelectorAll("[data-widget-runtime-key]"));
      cards.forEach(function (node) {
        if (node && node.getAttribute("data-widget-runtime-key")) {
          self.widgetObserver.observe(node);
        }
      });
    },
    disconnectWidgetObserver: function () {
      if (this.widgetObserver && this.widgetObserver.disconnect) {
        this.widgetObserver.disconnect();
      }
      this.widgetObserver = null;
    },
    handleWidgetIntersection: function (entries) {
      var self = this;
      (entries || []).forEach(function (entry) {
        var key = entry && entry.target ? entry.target.getAttribute("data-widget-runtime-key") : "";
        var item = self.findWidgetByRuntimeKey(key);
        if (!key || !item) {
          return;
        }
        if (entry.isIntersecting || entry.intersectionRatio > 0) {
          self.widgetVisibleMap[key] = true;
          self.enqueueWidgetRuntimeLoad(item);
          if (self.widgetObserver && self.widgetObserver.unobserve) {
            self.widgetObserver.unobserve(entry.target);
          }
        }
      });
    },
    queueInitialWidgetLoads: function () {
      var self = this;
      (self.dashboardWidgets || []).slice(0, self.maxConcurrentWidgetLoads).forEach(function (item) {
        self.enqueueWidgetRuntimeLoad(item);
      });
    },
    enqueueWidgetRuntimeLoad: function (item, forceReload) {
      var runtimeKey = this.getWidgetRuntimeKey(item);
      var priority = 0;
      if (!runtimeKey) {
        return;
      }
      if (this.widgetLoadPromiseMap[runtimeKey]) {
        return;
      }
      if (!forceReload && this.widgetLoadQueue.some(function (queued) {
        return queued && queued.key === runtimeKey;
      })) {
        return;
      }
      priority = this.getWidgetLoadPriority(item);
      this.widgetLoadQueue.push({
        key: runtimeKey,
        item: item,
        forceReload: !!forceReload,
        priority: priority
      });
      this.widgetLoadQueue.sort(function (a, b) {
        return Number(a && a.priority ? a.priority : 0) - Number(b && b.priority ? b.priority : 0);
      });
      this.processWidgetLoadQueue();
    },
    getWidgetLoadPriority: function (item) {
      if (!item) {
        return 99;
      }
      if (this.isKpiWidget(item)) {
        return 1;
      }
      if (this.isProgressListWidget(item)) {
        return 2;
      }
      if (this.isDataTableWidget(item) || this.isMatrixWidget(item)) {
        return 3;
      }
      return 4;
    },
    processWidgetLoadQueue: function () {
      var nextJob = null;
      while (this.activeWidgetLoadCount < this.maxConcurrentWidgetLoads && this.widgetLoadQueue.length > 0) {
        nextJob = this.widgetLoadQueue.shift();
        if (!nextJob || !nextJob.item) {
          continue;
        }
        this.activeWidgetLoadCount += 1;
        this.loadSingleWidgetRuntime(nextJob.item, nextJob.forceReload).then(function () {
          this.$nextTick(function () {
            this.renderSingleWidgetRuntime(nextJob.item);
          }.bind(this));
        }.bind(this)).finally(function () {
          this.activeWidgetLoadCount = Math.max(0, this.activeWidgetLoadCount - 1);
          this.processWidgetLoadQueue();
        }.bind(this));
      }
    },
    findWidgetByRuntimeKey: function (runtimeKey) {
      var matched = null;
      (this.dashboardWidgets || []).some(function (item) {
        if (String(this.getWidgetRuntimeKey(item)) === String(runtimeKey || "")) {
          matched = item;
          return true;
        }
        return false;
      }.bind(this));
      return matched;
    },
    ensureDatasetCatalogLoaded: function () {
      var self = this;
      if (self.datasetCatalogPromise) {
        return self.datasetCatalogPromise;
      }
      self.datasetCatalogPromise = apiCallAsync("WF_ReportDataset_GetList", {
        Keyword: "",
        OnlyActive: 1
      }).then(function (resultSets) {
        var datasetRows = self.getResultSet(resultSets, 0);
        var fieldRows = self.getResultSet(resultSets, 1);
        self.applyDatasetCatalogMeta(datasetRows || [], fieldRows || []);
        return self.datasetMetaMap;
      }).catch(function () {
        self.datasetMetaMap = {};
        return self.datasetMetaMap;
      });
      return self.datasetCatalogPromise;
    },
    applyDatasetCatalogMeta: function (datasetRows, fieldRows) {
      var map = {};
      var fields = [];
      (datasetRows || []).forEach(function (row) {
        fields = (fieldRows || []).filter(function (field) {
          return String(field.DatasetCode || "") === String(row.DatasetCode || "");
        }).map(function (field) {
          return {
            key: field.FieldKey,
            label: field.FieldLabel || field.FieldKey,
            dataType: field.DataType || "string"
          };
        });
        map[row.DatasetCode] = {
          code: row.DatasetCode,
          name: row.DatasetName || row.DatasetCode,
          datasetType: row.DatasetType || "DB",
          sourceKind: row.SourceKind || "DATABASE",
          sourceFileId: row.SourceFileID || "",
          sourceMeta: this.tryParseJsonObject(row.SourceMetaJson, {}),
          fields: fields
        };
      }, this);
      this.datasetMetaMap = map;
    },
    tryLoadFileTableRows: function (datasetCode) {
      var self = this;
      if (!datasetCode) {
        return Promise.reject(new Error("DATASET_CODE_EMPTY"));
      }
      return self.ensureDatasetCatalogLoaded().then(function () {
        var meta = self.datasetMetaMap[datasetCode];
        if (!meta || String(meta.datasetType || "").toUpperCase() !== "FILE" || !meta.sourceFileId) {
          throw new Error("DATASET_NOT_FILE");
        }
        return self.fetchFileDatasetRows(meta);
      });
    },
    fetchFileDatasetRows: function (meta) {
      var self = this;
      return apiCallAsync("FileData_GetByID", { FileID: meta.sourceFileId, ID: meta.sourceFileId }).then(function (resultSets) {
        var rows = self.getResultSet(resultSets, 0);
        var row = rows && rows[0] ? rows[0] : null;
        var binary = row && (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || row.FileBinary || "");
        var sourceKind = String(meta && meta.sourceKind ? meta.sourceKind : "").toUpperCase();
        var text = "";
        if (sourceKind === "XLS" || sourceKind === "XLSX") {
          return self.parseExcelBinaryToObjects(binary, meta.fields || [], meta.sourceMeta || {});
        }
        text = self.decodeFileBinaryToText(binary);
        if (!text) {
          throw new Error("FILEDATA_EMPTY");
        }
        return self.parseCsvTextToObjects(text, meta.fields || []);
      });
    },
    ensureXlsxLibLoaded: function () {
      if (typeof window === "undefined") {
        return Promise.reject(new Error("XLSX_LIB_NOT_READY"));
      }
      if (window.XLSX) {
        return Promise.resolve(window.XLSX);
      }
      return new Promise(function (resolve, reject) {
        var existing = document.getElementById("wf-report-xlsx-lib");
        if (existing) {
          existing.addEventListener("load", function () {
            if (window.XLSX) {
              resolve(window.XLSX);
              return;
            }
            reject(new Error("XLSX_LIB_NOT_READY"));
          }, { once: true });
          existing.addEventListener("error", function () {
            reject(new Error("XLSX_LIB_LOAD_FAILED"));
          }, { once: true });
          return;
        }
        existing = document.createElement("script");
        existing.id = "wf-report-xlsx-lib";
        existing.src = "https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js";
        existing.async = true;
        existing.onload = function () {
          if (window.XLSX) {
            resolve(window.XLSX);
            return;
          }
          reject(new Error("XLSX_LIB_NOT_READY"));
        };
        existing.onerror = function () {
          reject(new Error("XLSX_LIB_LOAD_FAILED"));
        };
        document.head.appendChild(existing);
      });
    },
    decodeFileBinaryToText: function (value) {
      var raw = String(value || "").trim();
      var bytes = null;
      if (!raw) {
        return "";
      }
      if (this.looksLikeBase64Text(raw)) {
        bytes = this.base64ToBytes(raw);
        return this.bytesToUtf8(bytes);
      }
      return raw.replace(/^\uFEFF/, "");
    },
    looksLikeBase64Text: function (value) {
      var raw = String(value || "").replace(/\s+/g, "");
      if (!raw || raw.length < 16 || raw.length % 4 !== 0) {
        return false;
      }
      return /^[A-Za-z0-9+/=]+$/.test(raw);
    },
    base64ToBytes: function (base64) {
      var binary = atob(String(base64 || "").replace(/\s+/g, ""));
      var length = binary.length;
      var bytes = new Uint8Array(length);
      var index = 0;
      for (index = 0; index < length; index += 1) {
        bytes[index] = binary.charCodeAt(index);
      }
      return bytes;
    },
    bytesToUtf8: function (bytes) {
      var decoder = null;
      var index = 0;
      var text = "";
      if (typeof TextDecoder !== "undefined") {
        decoder = new TextDecoder("utf-8");
        return decoder.decode(bytes);
      }
      for (index = 0; index < bytes.length; index += 1) {
        text += String.fromCharCode(bytes[index]);
      }
      return text;
    },
    decodeFileBinaryToBytes: function (value) {
      var raw = String(value || "").trim();
      var index = 0;
      var bytes = null;
      if (!raw) {
        return new Uint8Array(0);
      }
      if (this.looksLikeBase64Text(raw)) {
        return this.base64ToBytes(raw);
      }
      bytes = new Uint8Array(raw.length);
      for (index = 0; index < raw.length; index += 1) {
        bytes[index] = raw.charCodeAt(index) & 255;
      }
      return bytes;
    },
    parseExcelBinaryToObjects: function (binary, fields, sourceMeta) {
      var self = this;
      return self.ensureXlsxLibLoaded().then(function (XLSX) {
        var bytes = self.decodeFileBinaryToBytes(binary);
        var workbook = null;
        var sheetNames = [];
        var selectedSheetName = "";
        var worksheet = null;
        var rows = [];
        var headers = [];
        var columns = [];
        if (!bytes || !bytes.length) {
          throw new Error("EXCEL_EMPTY");
        }
        workbook = XLSX.read(bytes, { type: "array" });
        sheetNames = workbook && workbook.SheetNames ? workbook.SheetNames : [];
        selectedSheetName = String(sourceMeta && sourceMeta.selectedSheetName ? sourceMeta.selectedSheetName : "").trim();
        if (!selectedSheetName || sheetNames.indexOf(selectedSheetName) < 0) {
          selectedSheetName = sheetNames[0] || "";
        }
        if (!selectedSheetName) {
          throw new Error("EXCEL_SHEET_EMPTY");
        }
        worksheet = workbook.Sheets[selectedSheetName];
        if (!worksheet) {
          throw new Error("EXCEL_SHEET_NOT_FOUND");
        }
        rows = XLSX.utils.sheet_to_json(worksheet, {
          header: 1,
          raw: false,
          defval: ""
        }) || [];
        headers = rows.length > 0 ? rows[0].map(function (value) {
          return String(value || "").trim();
        }) : [];
        columns = fields && fields.length > 0 ? fields : self.buildColumnsFromHeaders(headers);
        return self.buildCsvObjects(columns, self.filterEmptyRawRows(rows.slice(1)));
      });
    },
    parseCsvTextToObjects: function (text, fields) {
      var rows = this.extractCsvRows(text, 5000);
      var headers = rows.length > 0 ? rows[0] : [];
      var columns = fields && fields.length > 0 ? fields : this.buildColumnsFromHeaders(headers);
      return this.buildCsvObjects(columns, rows.slice(1));
    },
    filterEmptyRawRows: function (rawRows) {
      return (rawRows || []).filter(function (rawRow) {
        if (!Array.isArray(rawRow)) {
          return false;
        }
        return rawRow.some(function (cell) {
          return String(cell === undefined || cell === null ? "" : cell).trim() !== "";
        });
      });
    },
    extractCsvRows: function (text, maxRows) {
      var normalized = String(text || "").replace(/^\uFEFF/, "");
      var lines = normalized.split(/\r?\n/);
      var rows = [];
      var index = 0;
      for (index = 0; index < lines.length; index += 1) {
        if (!String(lines[index] || "").trim()) {
          continue;
        }
        rows.push(this.parseCsvLine(lines[index]));
        if (rows.length >= (maxRows || 5000)) {
          break;
        }
      }
      return rows;
    },
    parseCsvLine: function (line) {
      var values = [];
      var current = "";
      var insideQuote = false;
      var index = 0;
      var char = "";
      var nextChar = "";
      for (index = 0; index < line.length; index += 1) {
        char = line.charAt(index);
        nextChar = index + 1 < line.length ? line.charAt(index + 1) : "";
        if (char === "\"") {
          if (insideQuote && nextChar === "\"") {
            current += "\"";
            index += 1;
          } else {
            insideQuote = !insideQuote;
          }
        } else if (char === "," && !insideQuote) {
          values.push(current);
          current = "";
        } else {
          current += char;
        }
      }
      values.push(current);
      return values.map(function (value) {
        return String(value || "").trim();
      });
    },
    buildColumnsFromHeaders: function (headers) {
      var seen = {};
      return (headers || []).map(function (header, index) {
        var key = this.sanitizeFieldKey(header, index + 1);
        if (seen[key]) {
          seen[key] += 1;
          key = key + "_" + seen[key];
        } else {
          seen[key] = 1;
        }
        return {
          key: key,
          label: header,
          dataType: "string"
        };
      }, this);
    },
    sanitizeFieldKey: function (header, fallbackIndex) {
      var raw = String(header || "").toLowerCase();
      if (raw.normalize) {
        raw = raw.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
      }
      raw = raw.replace(/[^a-z0-9]+/g, "_");
      raw = raw.replace(/^_+|_+$/g, "");
      if (!raw) {
        raw = "column_" + String(fallbackIndex || 1);
      }
      if (!/^[a-z]/.test(raw)) {
        raw = "f_" + raw;
      }
      return raw.slice(0, 50);
    },
    buildCsvObjects: function (columns, rawRows) {
      return (rawRows || []).map(function (rawRow) {
        var row = {};
        (columns || []).forEach(function (column, index) {
          row[column.key] = rawRow[index] !== undefined ? rawRow[index] : "";
        });
        return row;
      });
    },
    loadSystemWidgetRuntime: function (item) {
      item.previewSummary = {
        TotalValue: 691988,
        TopLabel: "Tiểu học"
      };
      item.previewRows = [
        { label: "Mầm non", value: 121872, share: 17.6, delta: 0, requestCount: 374, completedRate: 0, slaHours: 0 },
        { label: "Tiểu học", value: 295190, share: 42.7, delta: 0, requestCount: 291, completedRate: 0, slaHours: 0 },
        { label: "THCS", value: 194915, share: 28.2, delta: 0, requestCount: 170, completedRate: 0, slaHours: 0 },
        { label: "THPT", value: 80011, share: 11.6, delta: 0, requestCount: 50, completedRate: 0, slaHours: 0 }
      ];
      item.dimensionKey = "Cấp học";
      item.metricKey = "Số học sinh";
      item.officialHighlights = [
        { label: "Tổng học sinh 4 cấp", value: "691.988", meta: "Đồng Nai, năm học 2020-2021" },
        { label: "Dân số dự báo 2030", value: "3.802.537", meta: "Tài liệu quy hoạch tỉnh Đồng Nai" },
        { label: "Tỷ lệ đô thị hóa 2030", value: "55%", meta: "Kịch bản khả thi trong báo cáo quy hoạch" },
        { label: "Áp lực tăng nhu cầu", value: "Cao", meta: "Đặc biệt quanh đô thị hóa và khu công nghiệp" }
      ];
      item.officialLevelRows = [
        { level: "Mầm non", schools: "374", students: "121.872 học sinh", share: 18, shareLabel: "17,6% tổng 4 cấp" },
        { level: "Tiểu học", schools: "291", students: "295.190 học sinh", share: 43, shareLabel: "42,7% tổng 4 cấp" },
        { level: "THCS", schools: "170", students: "194.915 học sinh", share: 28, shareLabel: "28,2% tổng 4 cấp" },
        { level: "THPT", schools: "50", students: "80.011 học sinh", share: 12, shareLabel: "11,6% tổng 4 cấp" }
      ];
      item.officialSourceLinks = [
        {
          label: "MOET: Thống kê giáo dục mầm non năm học 2023-2024",
          meta: "Bộ Giáo dục và Đào tạo, đăng ngày 15/05/2025",
          url: "https://moet.gov.vn/thong-ke/Pages/thong-ke-giao-duc-mam-non.aspx?ItemID=10548"
        },
        {
          label: "MOET: Thống kê giáo dục tiểu học năm học 2023-2024",
          meta: "Bộ Giáo dục và Đào tạo, công bố trên chuyên mục thống kê năm 2025",
          url: "https://moet.gov.vn/thong-ke/pages/thong-ke-giao-duc-tieu-hoc.aspx"
        },
        {
          label: "MOET: Thống kê giáo dục THCS và THPT năm học 2023-2024",
          meta: "Bộ Giáo dục và Đào tạo, đăng ngày 14/05/2025",
          url: "https://moet.gov.vn/thong-ke/Pages/Thong-ke-giao-duc-trung-hoc.aspx"
        },
        {
          label: "Đồng Nai: Phụ lục quy mô trường lớp giai đoạn 2011-2020",
          meta: "Báo cáo quy hoạch tỉnh, phụ lục có số trường/lớp/học sinh đến năm học 2020-2021",
          url: "https://skhdt.dongnai.gov.vn/Shared%20Documents/2085_20230308_Project%20%C4%90%E1%BB%93ng%20Nai_BC%20gi%E1%BB%AFa%20k%E1%BB%B3_Ph%E1%BA%A7n%203.pdf"
        },
        {
          label: "Đồng Nai: Dự báo dân số đến năm 2030 và 2050",
          meta: "Báo cáo quy hoạch tỉnh, kịch bản khả thi",
          url: "https://skhdt.dongnai.gov.vn/Shared%20Documents/2085_20230308_Project%20%C4%90%E1%BB%93ng%20Nai_BC%20gi%E1%BB%AFa%20k%E1%BB%B3_Ph%E1%BA%A7n%202.pdf"
        }
      ];
      item.officialTrendLinks = [
        {
          label: "Quan tâm đến trường tư thục, song ngữ, STEM tại Việt Nam",
          meta: "Google Trends live, 12 tháng gần nhất",
          url: "https://trends.google.com/trends/explore?date=today%2012-m&geo=VN&q=tr%C6%B0%E1%BB%9Dng%20t%C6%B0%20th%E1%BB%A5c,tr%C6%B0%E1%BB%9Dng%20song%20ng%E1%BB%AF,stem%20cho%20h%E1%BB%8Dc%20sinh"
        },
        {
          label: "Quan tâm đến học phí, lớp 10 và hướng nghiệp",
          meta: "Google Trends live, 12 tháng gần nhất",
          url: "https://trends.google.com/trends/explore?date=today%2012-m&geo=VN&q=h%E1%BB%8Dc%20ph%C3%AD%20tr%C6%B0%E1%BB%9Dng%20t%C6%B0,luy%E1%BB%87n%20thi%20l%E1%BB%9Bp%2010,h%C6%B0%E1%BB%9Bng%20nghi%E1%BB%87p%20l%E1%BB%9Bp%2012"
        },
        {
          label: "Trang Google Trends chính thức",
          meta: "Có thể export, embed và đối chiếu trực tiếp theo thời gian",
          url: "https://trends.google.com/trends/"
        }
      ];
      item.isLoading = false;
      item.error = "";
      return Promise.resolve(item);
    },
    buildSystemWidgetLibrary: function () {
      return [
        {
          id: -9001,
          name: "Radar tuyển sinh Đồng Nai",
          dataset: "MOET + Google Trends + Đồng Nai quy hoạch",
          chart: "official_live",
          updatedAt: "22/03 23:59",
          isPinned: false,
          isSystem: true,
          systemKey: "admission_radar_dong_nai"
        }
      ];
    },
    mergeSystemWidgetsFromLayout: function (widgets, regions) {
      var output = (widgets || []).slice();
      var self = this;
      (regions || []).forEach(function (region) {
        var widgetId = Number(region && region.widgetId ? region.widgetId : 0);
        var systemWidget = null;
        if (widgetId >= 0) {
          return;
        }
        if (output.some(function (item) { return Number(item.reportDefinitionId || 0) === widgetId; })) {
          return;
        }
        systemWidget = self.createSystemWidgetById(widgetId);
        if (systemWidget) {
          output.push(systemWidget);
        }
      });
      return output;
    },
    createSystemWidgetById: function (widgetId) {
      if (Number(widgetId) === -9001) {
        return {
          reportDefinitionId: -9001,
          name: "Radar tuyển sinh Đồng Nai",
          dataset: "MOET + Google Trends + Đồng Nai quy hoạch",
          chart: "official_live",
          updatedAt: "22/03 23:59",
          sortOrder: this.dashboardWidgets.length + 1,
          gridX: 0,
          gridY: 0,
          gridW: 6,
          gridH: 4,
          sizePreset: "wide",
          previewSummary: null,
          previewRows: [],
          formulaColumns: [],
          tableConfig: {},
          dimensionKey: "",
          metricKey: "",
          isLoading: true,
          error: "",
          isSystem: true,
          systemKey: "admission_radar_dong_nai"
        };
      }
      return null;
    },
    mapPreviewRows: function (rows, detail) {
      var metricKey = detail && detail.MetricKey ? detail.MetricKey : "requestCount";
      return (rows || []).map(function (row) {
        return {
          label: row.Label || "-",
          value: Number(row.MetricValue || 0),
          requestCount: Number(row.RequestCount || 0),
          completedRate: Number(row.CompletedRate || 0),
          slaHours: Number(row.SlaHours || 0),
          delta: Number(row.DeltaValue || 0),
          share: Number(row.ShareValue || 0),
          metricKey: metricKey
        };
      });
    },
    renderAllCharts: function () {
      var self = this;
      this.cancelAllPendingChartRenders();
      this.disposeAllCharts();
      if (!window.echarts) {
        return;
      }
      ;(this.dashboardRegions || []).forEach(function (region) {
        var item = self.getRegionWidget(region);
        if (!item || self.isTableLikeChart(item) || self.isKpiWidget(item) || self.isProgressListWidget(item) || self.isOfficialLiveWidget(item) || !item.previewRows || !item.previewRows.length) {
          return;
        }
        if (!self.regionMatchesCanvasFilter(region)) {
          return;
        }
        self.scheduleChartRender(item);
      });
    },
    scheduleChartRender: function (item) {
      var chartKey = String(item && (item.reportDefinitionId || this.getChartDomId(item)) || "");
      if (!chartKey) {
        return;
      }
      this.cancelPendingChartRender(chartKey);
      this.pendingChartRenderQueue.push({
        key: chartKey,
        item: item
      });
      this.processChartRenderQueue();
    },
    processChartRenderQueue: function () {
      var nextJob = null;
      var callback = null;
      var handle = 0;
      var self = this;
      if (this.activeChartRenderKey || !this.pendingChartRenderQueue.length) {
        return;
      }
      nextJob = this.pendingChartRenderQueue.shift();
      if (!nextJob || !nextJob.item || !nextJob.key) {
        return;
      }
      this.activeChartRenderKey = nextJob.key;
      callback = function () {
        delete self.pendingChartRenderHandles[nextJob.key];
        self.renderWidgetChart(nextJob.item);
        self.activeChartRenderKey = "";
        if (typeof window !== "undefined" && typeof window.requestAnimationFrame === "function") {
          window.requestAnimationFrame(function () {
            self.processChartRenderQueue();
          });
          return;
        }
        setTimeout(function () {
          self.processChartRenderQueue();
        }, 16);
      };
      if (typeof window !== "undefined" && typeof window.requestIdleCallback === "function") {
        handle = window.requestIdleCallback(callback, { timeout: 180 });
        this.pendingChartRenderHandles[nextJob.key] = { type: "idle", id: handle };
        return;
      }
      if (typeof window !== "undefined" && typeof window.requestAnimationFrame === "function") {
        handle = window.requestAnimationFrame(function () {
          callback();
        });
        this.pendingChartRenderHandles[nextJob.key] = { type: "raf", id: handle };
        return;
      }
      handle = setTimeout(callback, 16);
      this.pendingChartRenderHandles[nextJob.key] = { type: "timeout", id: handle };
    },
    cancelPendingChartRender: function (chartKey) {
      var handle = this.pendingChartRenderHandles[chartKey];
      if (!handle) {
        this.pendingChartRenderQueue = (this.pendingChartRenderQueue || []).filter(function (entry) {
          return String(entry && entry.key ? entry.key : "") !== String(chartKey || "");
        });
        return;
      }
      if (typeof window !== "undefined" && handle.type === "idle" && typeof window.cancelIdleCallback === "function") {
        window.cancelIdleCallback(handle.id);
      } else if (typeof window !== "undefined" && handle.type === "raf" && typeof window.cancelAnimationFrame === "function") {
        window.cancelAnimationFrame(handle.id);
      } else {
        clearTimeout(handle.id);
      }
      delete this.pendingChartRenderHandles[chartKey];
      this.pendingChartRenderQueue = (this.pendingChartRenderQueue || []).filter(function (entry) {
        return String(entry && entry.key ? entry.key : "") !== String(chartKey || "");
      });
      if (String(this.activeChartRenderKey || "") === String(chartKey || "")) {
        this.activeChartRenderKey = "";
      }
    },
    cancelAllPendingChartRenders: function () {
      var self = this;
      Object.keys(this.pendingChartRenderHandles || {}).forEach(function (chartKey) {
        self.cancelPendingChartRender(chartKey);
      });
      this.pendingChartRenderQueue = [];
      this.activeChartRenderKey = "";
    },
    renderWidgetChart: function (item) {
      var target = document.getElementById(this.getChartDomId(item));
      var chart = null;
      var rows = item.previewRows || [];
      var chartKey = String(item.reportDefinitionId || this.getChartDomId(item));
      if (!target || !window.echarts) {
        return;
      }
      if (this.chartInstances[chartKey] && this.chartInstances[chartKey].dispose) {
        this.chartInstances[chartKey].dispose();
      }
      chart = window.echarts.init(target, null, {
        renderer: "canvas",
        useDirtyRect: true
      });
      chart.setOption(this.buildWidgetChartOption(item, rows), {
        notMerge: true,
        lazyUpdate: true,
        silent: false
      });
      chart.off("click");
      chart.on("click", function (params) {
        this.openReportDetail(item, params && params.name ? params.name : "");
      }.bind(this));
      this.chartInstances[chartKey] = chart;
    },
    renderSingleWidgetRuntime: function (item) {
      var chartKey = "";
      if (!item) {
        return;
      }
      if (this.isTableLikeChart(item) || this.isKpiWidget(item) || this.isProgressListWidget(item) || this.isOfficialLiveWidget(item)) {
        return;
      }
      chartKey = String(item.reportDefinitionId || this.getChartDomId(item));
      if (!item.previewRows || !item.previewRows.length) {
        if (this.chartInstances[chartKey] && this.chartInstances[chartKey].dispose) {
          this.chartInstances[chartKey].dispose();
          delete this.chartInstances[chartKey];
        }
        this.cancelPendingChartRender(chartKey);
        return;
      }
      if (!this.regionMatchesCanvasFilterByWidget(item)) {
        this.cancelPendingChartRender(chartKey);
        return;
      }
      this.scheduleChartRender(item);
    },
    buildWidgetChartOption: function (item, rows) {
      var labels = rows.map(function (row) { return row.label; });
      var values = rows.map(function (row) { return Number(row.value || 0); });
      if (item.chart === "pie" || item.chart === "donut") {
        return {
          animation: false,
          animationDuration: 0,
          animationDurationUpdate: 0,
          hoverLayerThreshold: Infinity,
          color: ["#217D46", "#E5A812", "#4c78a8", "#f58518", "#e45756", "#72b7b2"],
          tooltip: { trigger: "item", transitionDuration: 0 },
          series: [{
            type: "pie",
            radius: item.chart === "pie" ? "68%" : ["36%", "68%"],
            animation: false,
            animationDuration: 0,
            animationDurationUpdate: 0,
            hoverAnimation: false,
            label: { formatter: "{b}\n{d}%", fontSize: 11 },
            data: rows.map(function (row) {
              return { name: row.label, value: Number(row.value || 0) };
            })
          }]
        };
      }
      if (item.chart === "bar_horizontal") {
        return {
          animation: false,
          animationDuration: 0,
          animationDurationUpdate: 0,
          hoverLayerThreshold: Infinity,
          color: ["#217D46"],
          tooltip: { trigger: "axis", transitionDuration: 0 },
          grid: { left: 28, right: 16, top: 24, bottom: 20, containLabel: true },
          xAxis: {
            type: "value",
            axisLabel: { color: "#5f6368", fontSize: 11 },
            splitLine: { lineStyle: { color: "#eef1f4" } }
          },
          yAxis: {
            type: "category",
            data: labels,
            axisLabel: { color: "#5f6368", fontSize: 11 }
          },
          series: [{
            type: "bar",
            animation: false,
            animationDuration: 0,
            animationDurationUpdate: 0,
            barMaxWidth: 24,
            itemStyle: { borderRadius: [0, 6, 6, 0] },
            data: values
          }]
        };
      }
      return {
        animation: false,
        animationDuration: 0,
        animationDurationUpdate: 0,
        hoverLayerThreshold: Infinity,
        color: [(item.chart === "line" || item.chart === "area") ? "#335c9b" : "#217D46"],
        tooltip: { trigger: "axis", transitionDuration: 0 },
        grid: { left: 28, right: 16, top: 24, bottom: 30, containLabel: true },
        xAxis: {
          type: "category",
          data: labels,
          axisLabel: { color: "#5f6368", fontSize: 11 }
        },
        yAxis: {
          type: "value",
          axisLabel: { color: "#5f6368", fontSize: 11 },
          splitLine: { lineStyle: { color: "#eef1f4" } }
        },
        series: [{
          type: (item.chart === "line" || item.chart === "area") ? "line" : "bar",
          animation: false,
          animationDuration: 0,
          animationDurationUpdate: 0,
          smooth: item.chart === "line" || item.chart === "area",
          barMaxWidth: 36,
          symbolSize: 8,
          itemStyle: item.chart === "bar" ? { borderRadius: [6, 6, 0, 0] } : {},
          areaStyle: item.chart === "area" ? { opacity: 0.18 } : (item.chart === "line" ? { opacity: 0.12 } : null),
          data: values
        }]
      };
    },
    disposeAllCharts: function () {
      var self = this;
      Object.keys(this.chartInstances || {}).forEach(function (key) {
        if (self.chartInstances[key] && self.chartInstances[key].dispose) {
          self.chartInstances[key].dispose();
        }
      });
      this.chartInstances = {};
    },
    moveWidget: function (index, direction) {
      var targetIndex = index + direction;
      var clone = null;
      if (targetIndex < 0 || targetIndex >= this.dashboardWidgets.length) {
        return;
      }
      clone = this.dashboardWidgets.slice();
      clone.splice(targetIndex, 0, clone.splice(index, 1)[0]);
      this.dashboardWidgets = clone.map(function (item, idx) {
        item.sortOrder = idx + 1;
        return item;
      });
      this.$nextTick(function () {
        this.renderAllCharts();
      }.bind(this));
    },
    moveVisibleWidget: function (visibleIndex, direction) {
      var visibleRegions = this.dashboardRegions.filter(function (region) {
        return this.regionMatchesCanvasFilter(region);
      }.bind(this));
      var currentRegion = visibleRegions[visibleIndex];
      var targetRegion = visibleRegions[visibleIndex + direction];
      var currentIndex = -1;
      var targetIndex = -1;
      if (!currentRegion || !targetRegion) {
        return;
      }
      currentIndex = this.dashboardRegions.indexOf(currentRegion);
      targetIndex = this.dashboardRegions.indexOf(targetRegion);
      if (currentIndex < 0 || targetIndex < 0) {
        return;
      }
      this.moveRegion(currentIndex, targetIndex > currentIndex ? 1 : -1);
    },
    moveRegion: function (index, direction) {
      var targetIndex = index + direction;
      var clone = null;
      if (targetIndex < 0 || targetIndex >= this.dashboardRegions.length) {
        return;
      }
      clone = this.dashboardRegions.slice();
      clone.splice(targetIndex, 0, clone.splice(index, 1)[0]);
      this.dashboardRegions = clone.map(function (region, idx) {
        region.sortOrder = idx + 1;
        return region;
      });
      this.$nextTick(function () {
        this.renderAllCharts();
      }.bind(this));
    },
    handleRegionDragStart: function (region, event) {
      this.draggingRegionId = String(region && region.regionId ? region.regionId : "");
      this.dropTargetRegionId = "";
      if (event && event.dataTransfer) {
        event.dataTransfer.effectAllowed = "move";
        event.dataTransfer.setData("text/plain", String(this.draggingRegionId || ""));
      }
    },
    handleRegionDragOver: function (region) {
      if (!this.draggingRegionId || !region || String(region.regionId || "") === String(this.draggingRegionId || "")) {
        this.dropTargetRegionId = "";
        return;
      }
      this.dropTargetRegionId = String(region.regionId || "");
    },
    handleRegionDrop: function (region) {
      var sourceId = String(this.draggingRegionId || "");
      var targetId = String(region && region.regionId ? region.regionId : "");
      var sourceIndex = -1;
      var targetIndex = -1;
      var clone = null;
      if (!sourceId || !targetId || sourceId === targetId) {
        this.handleRegionDragEnd();
        return;
      }
      sourceIndex = this.dashboardRegions.findIndex(function (item) { return String(item.regionId || "") === sourceId; });
      targetIndex = this.dashboardRegions.findIndex(function (item) { return String(item.regionId || "") === targetId; });
      if (sourceIndex < 0 || targetIndex < 0) {
        this.handleRegionDragEnd();
        return;
      }
      clone = this.dashboardRegions.slice();
      clone.splice(targetIndex, 0, clone.splice(sourceIndex, 1)[0]);
      this.dashboardRegions = clone.map(function (item, idx) {
        item.sortOrder = idx + 1;
        return item;
      });
      this.handleRegionDragEnd();
      this.$nextTick(function () {
        this.renderAllCharts();
      }.bind(this));
    },
    handleRegionDragEnd: function () {
      this.draggingRegionId = "";
      this.dropTargetRegionId = "";
    },
    createSection: function (title, layoutCode) {
      var maxSort = 0;
      ;(this.dashboardSections || []).forEach(function (item) {
        maxSort = Math.max(maxSort, Number(item && item.sortOrder ? item.sortOrder : 0));
      });
      return {
        sectionId: "section_" + String(Date.now()) + "_" + String(Math.floor(Math.random() * 1000)),
        title: title || ("Section " + String(maxSort + 1)),
        layoutCode: layoutCode || "single",
        sortOrder: maxSort + 1
      };
    },
    addSection: function () {
      this.openSectionComposer();
    },
    openSectionComposer: function (sectionId) {
      var section = null;
      this.sectionComposerMode = sectionId ? "update" : "create";
      this.sectionComposerSectionId = sectionId || "";
      if (sectionId) {
        section = (this.dashboardSections || []).find(function (item) {
          return String(item.sectionId || "") === String(sectionId || "");
        }) || null;
      }
      this.pendingSectionTitle = section && section.title ? section.title : ("Section " + String((this.dashboardSections || []).length + 1));
      this.pendingSectionLayout = section && section.layoutCode ? section.layoutCode : (this.selectedLayoutTemplate || "single");
      this.isSectionComposerOpen = true;
    },
    closeSectionComposer: function () {
      this.isSectionComposerOpen = false;
      this.sectionComposerMode = "create";
      this.sectionComposerSectionId = "";
    },
    confirmSectionComposer: function () {
      var section = null;
      var title = String(this.pendingSectionTitle || "").trim();
      if (!title) {
        title = this.sectionComposerMode === "update" ? "Section hiện tại" : ("Section " + String((this.dashboardSections || []).length + 1));
      }
      if (this.sectionComposerMode === "update") {
        section = (this.dashboardSections || []).find(function (item) {
          return String(item.sectionId || "") === String(this.sectionComposerSectionId || "");
        }.bind(this)) || null;
        if (!section) {
          return;
        }
        section.title = title;
        section.layoutCode = this.pendingSectionLayout || section.layoutCode || "single";
        this.selectedSectionId = section.sectionId;
        this.selectedLayoutTemplate = section.layoutCode || "single";
        this.applyLayoutTemplate(section.layoutCode, section.sectionId);
      } else {
        section = this.createSection(title, this.pendingSectionLayout || "single");
        this.dashboardSections.push(section);
        this.selectedSectionId = section.sectionId;
        this.selectedLayoutTemplate = section.layoutCode || "single";
        this.applyLayoutTemplate(section.layoutCode, section.sectionId);
      }
      this.closeSectionComposer();
    },
    selectSection: function (sectionId) {
      var section = (this.dashboardSections || []).find(function (item) {
        return String(item.sectionId || "") === String(sectionId || "");
      });
      this.selectedSectionId = sectionId || "";
      if (section) {
        this.selectedLayoutTemplate = section.layoutCode || "single";
      }
    },
    updateSectionLayoutChoice: function (sectionId, layoutCode) {
      var section = (this.dashboardSections || []).find(function (item) {
        return String(item.sectionId || "") === String(sectionId || "");
      });
      if (!section) {
        return;
      }
      section.layoutCode = layoutCode || "single";
      if (String(this.selectedSectionId || "") === String(section.sectionId || "")) {
        this.selectedLayoutTemplate = section.layoutCode || "single";
      }
    },
    applySectionLayout: function (sectionId) {
      var section = (this.dashboardSections || []).find(function (item) {
        return String(item.sectionId || "") === String(sectionId || "");
      }.bind(this));
      if (!section) {
        return;
      }
      this.selectedSectionId = section.sectionId;
      this.selectedLayoutTemplate = section.layoutCode || "single";
      this.applyLayoutTemplate(section.layoutCode || "single", section.sectionId);
    },
    layoutLabel: function (layoutCode) {
      var item = (this.layoutTemplateOptions || []).find(function (option) {
        return String(option.value || "") === String(layoutCode || "");
      });
      return item && item.title ? item.title : "Chưa chọn layout";
    },
    addRegion: function (preset) {
      var targetSectionId = this.selectedSectionId || (this.dashboardSections[0] ? this.dashboardSections[0].sectionId : "");
      if (!targetSectionId) {
        this.addSection();
        targetSectionId = this.selectedSectionId || (this.dashboardSections[0] ? this.dashboardSections[0].sectionId : "");
      }
      var region = this.createRegion(preset || "compact", null, null, null, targetSectionId);
      this.dashboardRegions.push(region);
    },
    applySelectedLayoutTemplate: function () {
      var targetSectionId = this.selectedSectionId || (this.dashboardSections[0] ? this.dashboardSections[0].sectionId : "");
      if (!targetSectionId) {
        this.addSection();
        targetSectionId = this.selectedSectionId || (this.dashboardSections[0] ? this.dashboardSections[0].sectionId : "");
      }
      this.applyLayoutTemplate(this.selectedLayoutTemplate || "single", targetSectionId);
    },
    applyLayoutTemplate: function (templateCode, sectionId) {
      var definition = this.getLayoutTemplateDefinition(templateCode || "single");
      var targetSectionId = sectionId || this.selectedSectionId || (this.dashboardSections[0] ? this.dashboardSections[0].sectionId : "");
      var preserved = (this.dashboardRegions || []).filter(function (region) {
        return String(region.sectionId || "") !== String(targetSectionId || "");
      });
      var section = (this.dashboardSections || []).find(function (item) {
        return String(item.sectionId || "") === String(targetSectionId || "");
      });
      if (section) {
        section.layoutCode = templateCode || "single";
      }
      this.dashboardRegions = preserved.concat((definition.regions || []).map(function (config, index) {
        return this.createRegion(
          config.sizePreset || "compact",
          config.widthUnits || 4,
          config.title || ("Vùng " + (index + 1)),
          config.rowIndex,
          targetSectionId
        );
      }.bind(this))).map(function (item, idx) {
        item.sortOrder = idx + 1;
        return item;
      });
    },
    getLayoutTemplateDefinition: function (templateCode) {
      var map = {
        single: { regions: [{ title: "Vùng toàn màn", sizePreset: "hero", widthUnits: 12, rowIndex: 0 }] },
        two_equal: { regions: [{ title: "Vùng trái", sizePreset: "compact", widthUnits: 6, rowIndex: 0 }, { title: "Vùng phải", sizePreset: "compact", widthUnits: 6, rowIndex: 0 }] },
        three_equal: { regions: [{ title: "Vùng 1", sizePreset: "compact", widthUnits: 4, rowIndex: 0 }, { title: "Vùng 2", sizePreset: "compact", widthUnits: 4, rowIndex: 0 }, { title: "Vùng 3", sizePreset: "compact", widthUnits: 4, rowIndex: 0 }] },
        ratio_1_3: { regions: [{ title: "Vùng hẹp", sizePreset: "compact", widthUnits: 3, rowIndex: 0 }, { title: "Vùng rộng", sizePreset: "wide", widthUnits: 9, rowIndex: 0 }] },
        ratio_3_1: { regions: [{ title: "Vùng rộng", sizePreset: "wide", widthUnits: 9, rowIndex: 0 }, { title: "Vùng hẹp", sizePreset: "compact", widthUnits: 3, rowIndex: 0 }] },
        ratio_1_3_1: { regions: [{ title: "Vùng trái", sizePreset: "compact", widthUnits: 2, rowIndex: 0 }, { title: "Vùng giữa", sizePreset: "wide", widthUnits: 8, rowIndex: 0 }, { title: "Vùng phải", sizePreset: "compact", widthUnits: 2, rowIndex: 0 }] },
        ratio_1_4: { regions: [{ title: "Vùng phụ", sizePreset: "compact", widthUnits: 2, rowIndex: 0 }, { title: "Vùng chính", sizePreset: "hero", widthUnits: 10, rowIndex: 0 }] },
        hero_two_bottom: {
          regions: [
            { title: "Vùng hero", sizePreset: "hero", widthUnits: 12, rowIndex: 0 },
            { title: "Vùng dưới trái", sizePreset: "compact", widthUnits: 6, rowIndex: 1 },
            { title: "Vùng dưới phải", sizePreset: "compact", widthUnits: 6, rowIndex: 1 }
          ]
        },
        two_top_one_bottom: {
          regions: [
            { title: "Vùng trên trái", sizePreset: "compact", widthUnits: 6, rowIndex: 0 },
            { title: "Vùng trên phải", sizePreset: "compact", widthUnits: 6, rowIndex: 0 },
            { title: "Vùng dưới", sizePreset: "hero", widthUnits: 12, rowIndex: 1 }
          ]
        },
        sidebar_left_content_right: {
          regions: [
            { title: "Sidebar trái", sizePreset: "tall", widthUnits: 3, rowIndex: 0 },
            { title: "Nội dung phải", sizePreset: "hero", widthUnits: 9, rowIndex: 0 }
          ]
        }
      };
      return map[templateCode] || map.single;
    },
    removeRegion: function (region) {
      this.dashboardRegions = this.dashboardRegions.filter(function (item) {
        return String(item.regionId || "") !== String(region.regionId || "");
      });
    },
    cycleRegionSize: function (region) {
      var order = ["compact", "wide", "tall", "hero"];
      var currentIndex = order.indexOf(region.sizePreset);
      region.sizePreset = order[(currentIndex + 1) % order.length];
      this.$nextTick(function () {
        this.handleResize();
      }.bind(this));
    },
    regionCardClasses: function (region) {
      return {
        "wf-report-widget--micro": Number(region.widthUnits || 0) === 2,
        "wf-report-widget--third": Number(region.widthUnits || 0) === 3,
        "wf-report-widget--half": Number(region.widthUnits || 0) === 6,
        "wf-report-widget--compact": region.sizePreset === "compact",
        "wf-report-widget--wide": region.sizePreset === "wide",
        "wf-report-widget--two-third": Number(region.widthUnits || 0) === 8,
        "wf-report-widget--three-quarter": Number(region.widthUnits || 0) === 9,
        "wf-report-widget--tall": region.sizePreset === "tall",
        "wf-report-widget--five-sixth": Number(region.widthUnits || 0) === 10,
        "wf-report-widget--hero": region.sizePreset === "hero",
        "wf-report-widget--dragging": this.draggingRegionId && String(region.regionId || "") === String(this.draggingRegionId || ""),
        "wf-report-widget--drop-target": this.dropTargetRegionId && String(region.regionId || "") === String(this.dropTargetRegionId || "")
      };
    },
    regionGridStyle: function (region, rowLength) {
      var width = Number(region && region.widthUnits ? region.widthUnits : this.resolveWidthUnits(region && region.sizePreset ? region.sizePreset : "compact"));
      var percent = 0;
      var gapPx = 16;
      var divisor = Number(rowLength || 1);
      if (width < 1) {
        width = 4;
      }
      if (width > 12) {
        width = 12;
      }
      percent = (width / 12) * 100;
      return {
        gridColumn: "span " + String(width),
        flex: "0 0 calc(" + String(percent) + "% - " + String(((divisor - 1) * gapPx) / divisor) + "px)",
        maxWidth: "calc(" + String(percent) + "% - " + String(((divisor - 1) * gapPx) / divisor) + "px)",
        minWidth: "0"
      };
    },
    canvasRowStyle: function () {
      return {
        display: "flex",
        flexWrap: "nowrap",
        alignItems: "stretch",
        gap: "16px"
      };
    },
    regionSizeLabel: function (region) {
      if (Number(region.widthUnits || 0) === 2) return "1/6";
      if (Number(region.widthUnits || 0) === 3) return "1/4";
      if (Number(region.widthUnits || 0) === 6) return "1/2";
      if (Number(region.widthUnits || 0) === 8) return "2/3";
      if (Number(region.widthUnits || 0) === 9) return "3/4";
      if (Number(region.widthUnits || 0) === 10) return "5/6";
      if (region.sizePreset === "wide") return "Rộng";
      if (region.sizePreset === "tall") return "Cao";
      if (region.sizePreset === "hero") return "Hero";
      return "Gọn";
    },
    regionSizeChipColor: function (region) {
      if (region.sizePreset === "hero") return "#7d42a3";
      if (region.sizePreset === "wide") return "#335c9b";
      if (region.sizePreset === "tall") return "#c0841a";
      return "#217D46";
    },
    widgetSubText: function (item) {
      var dimension = item.dimensionKey || "group";
      var metric = item.metricKey || "metric";
      return "Dimension: " + dimension + " · Metric: " + metric;
    },
    regionDescription: function (region, index) {
      var widget = this.getRegionWidget(region);
      if (!widget) {
        return "Vùng " + (index + 1) + " · Chưa gắn widget";
      }
      return widget.dataset + " · " + this.widgetSubText(widget);
    },
    regionHintText: function (region) {
      if (!region.widgetId) {
        return "Kéo thả để đổi vị trí vùng hoặc bấm Add widget để gắn nội dung.";
      }
      return this.widgetHintText(this.getRegionWidget(region));
    },
    regionUpdatedText: function (region) {
      var widget = this.getRegionWidget(region);
      return widget && widget.updatedAt ? widget.updatedAt : "Region builder";
    },
    widgetHintText: function (item) {
      if (this.isOfficialLiveWidget(item)) {
        return "Widget hệ thống dùng nguồn chính quy và link live, không lấy từ report definition thường.";
      }
      if (this.isDataTableWidget(item)) {
        return "Data table đang dùng cột hiển thị, filter row, sort và top N riêng.";
      }
      if (this.isMatrixWidget(item)) {
        return "Matrix đang hiển thị báo cáo tổng hợp với cột công thức.";
      }
      return "Click vào chart để drill-down nhanh theo từng nhóm dữ liệu.";
    },
    isTableLikeChart: function (item) {
      return item && (item.chart === "table" || item.chart === "matrix");
    },
    isDataTableWidget: function (item) {
      return item && item.chart === "table";
    },
    isMatrixWidget: function (item) {
      return item && item.chart === "matrix";
    },
    isKpiWidget: function (item) {
      return item && item.chart === "kpi";
    },
    isProgressListWidget: function (item) {
      return item && item.chart === "progress_list";
    },
    isOfficialLiveWidget: function (item) {
      return item && item.chart === "official_live";
    },
    widgetProgressWidth: function (item, row) {
      var max = 0;
      var value = Number(row && row.value ? row.value : 0);
      (item && item.previewRows ? item.previewRows : []).forEach(function (entry) {
        max = Math.max(max, Number(entry && entry.value ? entry.value : 0));
      });
      if (!max) {
        return "0%";
      }
      return String(Math.max(8, Math.round((value / max) * 100))) + "%";
    },
    buildWidgetTableColumns: function (item) {
      var config = item && item.tableConfig ? item.tableConfig : {};
      var visible = Array.isArray(config.VisibleColumns) && config.VisibleColumns.length
        ? config.VisibleColumns
        : ["label", "value", "delta", "share"];
      var labels = config.ColumnLabels || {};
      var catalog = this.getWidgetTableColumnCatalog(item);
      return visible.map(function (key) {
        var match = catalog.find(function (column) {
          return column.key === key;
        });
        return {
          key: key,
          label: String(labels[key] || (match && match.label) || key),
          type: match && match.type ? match.type : "text",
          width: this.resolveWidgetTableColumnWidth(item, key)
        };
      }.bind(this));
    },
    getWidgetTableColumnCatalog: function (item) {
      var rows = this.resolveWidgetTableSourceRows(item);
      if (rows.length > 0) {
        return Object.keys(rows[0]).filter(function (key) {
          return key !== "sourceIndex" && key !== "__rowKey";
        }).map(function (key) {
          return {
            key: key,
            label: this.defaultWidgetColumnLabel(item, key),
            type: this.inferWidgetTableColumnType(rows, key)
          };
        }.bind(this));
      }
      return [
        { key: "label", label: item && item.dimensionKey ? item.dimensionKey : "Nhóm dữ liệu", type: "text" },
        { key: "value", label: item && item.metricKey ? item.metricKey : "Giá trị", type: "number" },
        { key: "requestCount", label: "Số lượng", type: "number" },
        { key: "completedRate", label: "Tỷ lệ hoàn tất", type: "number" },
        { key: "slaHours", label: "SLA / Phản hồi TB", type: "number" },
        { key: "delta", label: "Biến động %", type: "number" },
        { key: "share", label: "Tỷ trọng %", type: "number" }
      ];
    },
    resolveWidgetTableSourceRows: function (item) {
      var self = this;
      if (item && Array.isArray(item.tableDetailRows) && item.tableDetailRows.length > 0) {
        return item.tableDetailRows.map(function (row, index) {
          return self.normalizeWidgetTableRow(row, index);
        });
      }
      return (item && item.previewRows ? item.previewRows : []).map(function (row, index) {
        return {
          label: row.label,
          value: Number(row.value || 0),
          requestCount: Number(row.requestCount || 0),
          completedRate: Number(row.completedRate || 0),
          slaHours: Number(row.slaHours || 0),
          delta: Number(row.delta || 0),
          share: Number(row.share || 0),
          sourceIndex: index,
          __rowKey: "row_" + String(index + 1)
        };
      });
    },
    normalizeWidgetTableRow: function (row, index) {
      var output = {};
      Object.keys(row || {}).forEach(function (key) {
        output[key] = row[key];
      });
      output.sourceIndex = index;
      output.__rowKey = output.__rowKey || ("row_" + String(index + 1));
      return output;
    },
    inferWidgetTableColumnType: function (rows, key) {
      var index = 0;
      var value = "";
      for (index = 0; index < rows.length; index += 1) {
        value = rows[index] && rows[index][key] !== undefined && rows[index][key] !== null ? rows[index][key] : "";
        if (value === "") {
          continue;
        }
        return isNaN(Number(value)) ? "text" : "number";
      }
      return "text";
    },
    defaultWidgetColumnLabel: function (item, key) {
      var config = item && item.tableConfig ? item.tableConfig : {};
      var labels = config.ColumnLabels || {};
      var map = {
        label: item && item.dimensionKey ? item.dimensionKey : "Nhóm dữ liệu",
        value: item && item.metricKey ? item.metricKey : "Giá trị",
        requestCount: "Số lượng",
        completedRate: "Tỷ lệ hoàn tất",
        slaHours: "SLA / Phản hồi TB",
        delta: "Biến động %",
        share: "Tỷ trọng %"
      };
      return String(labels[key] || map[key] || key);
    },
    resolveWidgetTableColumnWidth: function (item, key) {
      var config = item && item.tableConfig ? item.tableConfig : {};
      var widths = config.ColumnWidths || {};
      var width = Number(widths[key] || 0);
      if (!width || width < 90) {
        return 180;
      }
      return width;
    },
    widgetTableColumnStyle: function (item, column) {
      var width = column && column.width ? Number(column.width) : this.resolveWidgetTableColumnWidth(item, column && column.key);
      if (!width) {
        return {};
      }
      return {
        minWidth: String(width) + "px",
        width: String(width) + "px"
      };
    },
    shouldUseWidgetTableLiteScroll: function (item) {
      var rows = this.buildWidgetTableAllRows(item);
      var columns = this.buildWidgetTableColumns(item);
      return rows.length > 8 || columns.length > 6;
    },
    resolveWidgetTablePageSize: function (item) {
      var config = item && item.tableConfig ? item.tableConfig : {};
      var size = Number(config.PageSize || 10);
      if (this.tablePageSizeOptions.indexOf(size) < 0) {
        size = 10;
      }
      return size;
    },
    resolveWidgetTablePageIndex: function (item) {
      var config = item && item.tableConfig ? item.tableConfig : {};
      var pageIndex = Number(config.PageIndex || 1);
      return pageIndex > 0 ? pageIndex : 1;
    },
    buildWidgetTableAllRows: function (item) {
      var self = this;
      var config = item && item.tableConfig ? item.tableConfig : {};
      var filters = config.TableFilters || {};
      var sortBy = config.SortBy || "value";
      var sortDir = config.SortDir === "asc" ? 1 : -1;
      var topN = Number(config.TopN || 0);
      var rows = this.resolveWidgetTableSourceRows(item).filter(function (row) {
        return self.widgetTableRowVisible(row, filters);
      }).sort(function (a, b) {
        var left = a[sortBy];
        var right = b[sortBy];
        if (typeof left === "string" || typeof right === "string") {
          return String(left || "").localeCompare(String(right || ""), "vi") * sortDir;
        }
        return (Number(left || 0) - Number(right || 0)) * sortDir;
      });
      if (topN > 0) {
        rows = rows.slice(0, topN);
      }
      return rows;
    },
    buildWidgetTableFooter: function (item) {
      var footer = {};
      var rows = this.buildWidgetTableAllRows(item);
      var columns = this.buildWidgetTableColumns(item);
      var index = 0;
      var key = "";
      for (index = 0; index < columns.length; index += 1) {
        key = columns[index].key;
        if (index === 0) {
          footer[key] = "Tổng: " + String(rows.length) + " dòng";
          continue;
        }
        if (columns[index].type === "number") {
          footer[key] = rows.reduce(function (sum, row) {
            return sum + Number(row && row[key] !== undefined && row[key] !== null && row[key] !== "" ? row[key] : 0);
          }, 0);
        } else {
          footer[key] = "";
        }
      }
      return footer;
    },
    buildWidgetTableRows: function (item) {
      var rows = this.buildWidgetTableAllRows(item);
      var pageSize = this.resolveWidgetTablePageSize(item);
      var pageIndex = this.resolveWidgetTablePageIndex(item);
      var pageCount = Math.max(1, Math.ceil(rows.length / pageSize));
      var safePage = Math.min(pageIndex, pageCount);
      var start = (safePage - 1) * pageSize;
      if (item && item.tableConfig && Number(item.tableConfig.PageIndex || 1) !== safePage) {
        item.tableConfig.PageIndex = safePage;
      }
      return rows.slice(start, start + pageSize);
    },
    buildWidgetTablePageCount: function (item) {
      var rows = this.buildWidgetTableAllRows(item);
      var pageSize = this.resolveWidgetTablePageSize(item);
      return Math.max(1, Math.ceil(rows.length / pageSize));
    },
    buildWidgetTablePageText: function (item) {
      var totalRows = this.buildWidgetTableAllRows(item).length;
      var pageSize = this.resolveWidgetTablePageSize(item);
      var pageCount = Math.max(1, Math.ceil(totalRows / pageSize));
      var pageIndex = Math.min(this.resolveWidgetTablePageIndex(item), pageCount);
      var start = totalRows === 0 ? 0 : ((pageIndex - 1) * pageSize) + 1;
      var end = Math.min(totalRows, pageIndex * pageSize);
      return "Hiển thị " + String(start) + "-" + String(end) + " / " + String(totalRows) + " dòng";
    },
    setWidgetTablePage: function (item, pageIndex) {
      var pageCount = this.buildWidgetTablePageCount(item);
      var safePage = Math.max(1, Math.min(pageCount, Number(pageIndex || 1)));
      item.tableConfig = item.tableConfig || {};
      item.tableConfig.PageIndex = safePage;
    },
    setWidgetTablePageSize: function (item, pageSize) {
      var safeSize = Number(pageSize || 10);
      if (this.tablePageSizeOptions.indexOf(safeSize) < 0) {
        safeSize = 10;
      }
      item.tableConfig = item.tableConfig || {};
      item.tableConfig.PageSize = safeSize;
      item.tableConfig.PageIndex = 1;
    },
    widgetTableRowVisible: function (row, filters) {
      var keyword = String(filters && filters.keyword ? filters.keyword : "").trim().toLowerCase();
      var minValue = filters && filters.minValue !== "" && filters.minValue !== null && filters.minValue !== undefined
        ? Number(filters.minValue)
        : null;
      var deltaMode = String(filters && filters.deltaMode ? filters.deltaMode : "all");
      if (keyword && String(row.label || "").toLowerCase().indexOf(keyword) < 0) {
        return false;
      }
      if (minValue !== null && !isNaN(minValue) && Number(row.value || 0) < minValue) {
        return false;
      }
      if (deltaMode === "positive" && Number(row.delta || 0) <= 0) {
        return false;
      }
      if (deltaMode === "negative" && Number(row.delta || 0) >= 0) {
        return false;
      }
      return true;
    },
    buildWidgetMatrixColumns: function (item) {
      var columns = [
        { key: "label", label: item.dimensionKey || "Nhóm dữ liệu", type: "text" },
        { key: "value", label: item.metricKey || "Giá trị", type: "number" }
      ];
      if ((item.previewRows || []).some(function (row) { return Number(row.delta || 0) !== 0; })) {
        columns.push({ key: "delta", label: "Biến động %", type: "number" });
      }
      if ((item.previewRows || []).some(function (row) { return Number(row.share || 0) !== 0; })) {
        columns.push({ key: "share", label: "Tỷ trọng %", type: "number" });
      }
      return columns.concat((item.formulaColumns || []).filter(function (formula) {
        return formula && String(formula.label || "").trim() && String(formula.expression || "").trim();
      }).map(function (formula) {
        return {
          key: formula.key,
          label: formula.label,
          type: "formula",
          expression: formula.expression
        };
      }));
    },
    buildWidgetMatrixRows: function (item) {
      var self = this;
      return (item.previewRows || []).map(function (row, index) {
        var output = {
          label: row.label,
          value: Number(row.value || 0),
          delta: Number(row.delta || 0),
          share: Number(row.share || 0),
          requestCount: Number(row.requestCount || 0),
          sourceIndex: index
        };
        ;(item.formulaColumns || []).forEach(function (formula) {
          if (!formula || !formula.key) {
            return;
          }
          output[formula.key] = self.evaluateFormulaExpression(formula.expression, output, row);
        });
        return output;
      });
    },
    evaluateFormulaExpression: function (expression, previewRow, rawRow) {
      var expr = String(expression || "").trim();
      var safeExpr = "";
      var context = {};
      var evaluator = null;
      if (!expr) {
        return "";
      }
      context = {
        label: String(previewRow.label || rawRow.label || ""),
        value: Number(previewRow.value || 0),
        delta: Number(previewRow.delta || 0),
        share: Number(previewRow.share || 0),
        requestCount: Number(rawRow.requestCount || previewRow.value || 0),
        completedRate: Number(rawRow.completedRate || 0),
        slaHours: Number(rawRow.slaHours || 0)
      };
      safeExpr = expr.replace(/\[([a-zA-Z0-9_]+)\]/g, function (_, key) {
        if (Object.prototype.hasOwnProperty.call(context, key)) {
          return String(Number(context[key] || 0));
        }
        return "0";
      });
      safeExpr = safeExpr.replace(/[^0-9+\-*/(). %]/g, "");
      if (!safeExpr) {
        return "";
      }
      try {
        evaluator = new Function("return (" + safeExpr + ");");
        return Number(evaluator() || 0);
      } catch (e) {
        return "";
      }
    },
    formatMatrixValue: function (value, type) {
      if (value === "" || value === null || value === undefined) {
        return "-";
      }
      if (type === "text") {
        return String(value);
      }
      return Number(value || 0).toLocaleString("vi-VN", {
        maximumFractionDigits: 2
      });
    },
    matrixCellClass: function (column, row) {
      var value = row && column ? row[column.key] : "";
      if (column && column.key === "delta") {
        if (Number(value || 0) > 0) return "wf-report-matrix-cell wf-report-matrix-cell--pos";
        if (Number(value || 0) < 0) return "wf-report-matrix-cell wf-report-matrix-cell--neg";
      }
      if (column && column.type === "formula") {
        return "wf-report-matrix-cell wf-report-matrix-cell--formula";
      }
      return "wf-report-matrix-cell";
    },
    resolveSizePreset: function (gridW, gridH) {
      var width = Number(gridW || 0);
      var height = Number(gridH || 0);
      if (width >= 12) return "hero";
      if (height >= 5) return "tall";
      if (width >= 8) return "wide";
      return "compact";
    },
    resolveWidthUnits: function (preset) {
      if (preset === "hero") return 12;
      if (preset === "wide") return 8;
      return 4;
    },
    getChartDomId: function (item) {
      return "wf-report-chart-" + String(item.reportDefinitionId || item.name || "temp").replace(/[^a-zA-Z0-9_-]/g, "");
    },
    createRegion: function (preset, widthUnits, title, rowIndex, sectionId) {
      var regionId = "region_" + String(Date.now()) + "_" + String(Math.floor(Math.random() * 1000));
      var maxRowIndex = -1;
      ;(this.dashboardRegions || []).forEach(function (item) {
        if (String(item && item.sectionId ? item.sectionId : "") === String(sectionId || "")) {
          maxRowIndex = Math.max(maxRowIndex, Number(item && item.rowIndex !== undefined ? item.rowIndex : -1));
        }
      });
      return {
        regionId: regionId,
        title: title || "Vùng mới",
        sizePreset: preset || "compact",
        widthUnits: Number(widthUnits || this.resolveWidthUnits(preset || "compact")),
        rowIndex: rowIndex !== undefined && rowIndex !== null ? Number(rowIndex) : (maxRowIndex + 1),
        sectionId: sectionId || this.selectedSectionId || "",
        widgetId: 0,
        sortOrder: (this.dashboardRegions || []).length + 1
      };
    },
    resolveSections: function (layout, regions) {
      var sections = [];
      if (layout && Array.isArray(layout.sections) && layout.sections.length > 0) {
        sections = layout.sections.map(function (section, index) {
          return {
            sectionId: section.sectionId || ("section_" + (index + 1)),
            title: section.title || ("Section " + (index + 1)),
            layoutCode: section.layoutCode || "single",
            sortOrder: Number(section.sortOrder || index + 1)
          };
        });
      }
      if (!sections.length) {
        sections.push({
          sectionId: "section_default",
          title: "Section 1",
          layoutCode: "single",
          sortOrder: 1
        });
      }
      ;(regions || []).forEach(function (region) {
        var key = String(region && region.sectionId ? region.sectionId : "");
        if (!key) {
          return;
        }
        if (!sections.some(function (section) { return String(section.sectionId || "") === key; })) {
          sections.push({
            sectionId: key,
            title: "Section " + String(sections.length + 1),
            layoutCode: "single",
            sortOrder: sections.length + 1
          });
        }
      });
      return sections.sort(function (a, b) {
        return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
      });
    },
    ensureRegionsHaveSection: function () {
      var fallbackSectionId = this.dashboardSections[0] ? this.dashboardSections[0].sectionId : "section_default";
      this.dashboardRegions = (this.dashboardRegions || []).map(function (region) {
        if (!region.sectionId) {
          region.sectionId = fallbackSectionId;
        }
        return region;
      });
    },
    getSectionRegions: function (sectionId) {
      return (this.dashboardRegions || []).filter(function (region) {
        return String(region.sectionId || "") === String(sectionId || "");
      }).sort(function (a, b) {
        return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
      });
    },
    buildRegionRows: function (regions) {
      var rows = [];
      var hasRowIndex = false;
      var rowMap = {};
      var currentRow = [];
      var currentWidth = 0;
      ;(regions || []).forEach(function (region) {
        if (region && region.rowIndex !== undefined && region.rowIndex !== null) {
          hasRowIndex = true;
        }
      });
      if (hasRowIndex) {
        ;(regions || []).forEach(function (region) {
          var key = String(Number(region && region.rowIndex !== undefined ? region.rowIndex : 0));
          if (!rowMap[key]) {
            rowMap[key] = [];
          }
          rowMap[key].push(region);
        });
        return Object.keys(rowMap).sort(function (a, b) {
          return Number(a) - Number(b);
        }).map(function (key) {
          return rowMap[key];
        });
      }
      ;(regions || []).forEach(function (region) {
        var width = Number(region && region.widthUnits ? region.widthUnits : 4);
        if (width < 1) width = 4;
        if (width > 12) width = 12;
        if (currentRow.length > 0 && currentWidth + width > 12) {
          rows.push(currentRow);
          currentRow = [];
          currentWidth = 0;
        }
        currentRow.push(region);
        currentWidth += width;
      });
      if (currentRow.length > 0) {
        rows.push(currentRow);
      }
      return rows;
    },
    resolveRegions: function (layout, widgets) {
      var regions = [];
      var widgetMap = {};
      (widgets || []).forEach(function (item) {
        widgetMap[String(item.reportDefinitionId || 0)] = item;
      });
      if (layout && Array.isArray(layout.regions) && layout.regions.length > 0) {
        regions = layout.regions.map(function (region, index) {
          return {
            regionId: region.regionId || ("region_" + (index + 1)),
            title: region.title || ("Vùng " + (index + 1)),
            sizePreset: region.sizePreset || this.resolveSizePreset(region.gridW, region.gridH),
            widthUnits: Number(region.widthUnits || region.gridW || this.resolveWidthUnits(region.sizePreset || "compact")),
            rowIndex: Number(region.rowIndex !== undefined ? region.rowIndex : index),
            sectionId: region.sectionId || "section_default",
            widgetId: Number(region.widgetId || 0),
            sortOrder: Number(region.sortOrder || index + 1)
          };
        }.bind(this));
      } else {
        regions = (widgets || []).map(function (item, index) {
          return {
            regionId: "region_" + String(item.reportDefinitionId || index + 1),
            title: item.name || ("Vùng " + (index + 1)),
            sizePreset: item.sizePreset || this.resolveSizePreset(item.gridW, item.gridH),
            widthUnits: Number(item.gridW || this.resolveWidthUnits(item.sizePreset || "compact")),
            rowIndex: index,
            sectionId: "section_default",
            widgetId: Number(item.reportDefinitionId || 0),
            sortOrder: index + 1
          };
        }.bind(this));
      }
      (widgets || []).forEach(function (item) {
        var hasRegion = regions.some(function (region) {
          return Number(region.widgetId || 0) === Number(item.reportDefinitionId || 0);
        });
        if (!hasRegion) {
          regions.push({
            regionId: "region_" + String(item.reportDefinitionId || 0),
            title: item.name || "Vùng thêm mới",
            sizePreset: item.sizePreset || this.resolveSizePreset(item.gridW, item.gridH),
            widthUnits: Number(item.gridW || this.resolveWidthUnits(item.sizePreset || "compact")),
            rowIndex: regions.length,
            sectionId: "section_default",
            widgetId: Number(item.reportDefinitionId || 0),
            sortOrder: regions.length + 1
          });
        }
      }.bind(this));
      return regions.sort(function (a, b) {
        return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
      });
    },
    getRegionWidget: function (region) {
      if (!region || !region.widgetId) {
        return null;
      }
      return (this.dashboardWidgets || []).find(function (item) {
        return Number(item.reportDefinitionId || 0) === Number(region.widgetId || 0);
      }) || null;
    },
    regionMatchesCanvasFilter: function (region) {
      var widget = this.getRegionWidget(region);
      if (!widget) {
        return true;
      }
      if (this.globalDatasetFilter !== "Tất cả" && widget.dataset !== this.globalDatasetFilter) {
        return false;
      }
      if (this.globalChartFilter !== "Tất cả" && widget.chart !== this.globalChartFilter) {
        return false;
      }
      if (this.globalSearchQuery && String(widget.name || "").toLowerCase().indexOf(String(this.globalSearchQuery || "").toLowerCase()) < 0) {
        return false;
      }
      return true;
    },
    regionMatchesCanvasFilterByWidget: function (widget) {
      if (!widget) {
        return false;
      }
      if (this.globalDatasetFilter !== "Tất cả" && widget.dataset !== this.globalDatasetFilter) {
        return false;
      }
      if (this.globalChartFilter !== "Tất cả" && widget.chart !== this.globalChartFilter) {
        return false;
      }
      if (this.globalSearchQuery && String(widget.name || "").toLowerCase().indexOf(String(this.globalSearchQuery || "").toLowerCase()) < 0) {
        return false;
      }
      return true;
    },
    buildLayoutWidgets: function () {
      var cursorY = 0;
      var output = [];
      (this.renderedSections || []).forEach(function (section) {
        var rowHeight = 0;
        var cursorX = 0;
        (section.rows || []).forEach(function (row) {
          rowHeight = 0;
          cursorX = 0;
          (row || []).forEach(function (region) {
            var index = this.dashboardRegions.indexOf(region);
            var size = region.sizePreset || "compact";
            var width = Number(region.widthUnits || this.resolveWidthUnits(size));
            var height = size === "tall" ? 5 : (size === "hero" ? 5 : 3);
            var payload = {
              ReportDefinitionID: region.widgetId || 0,
              WidgetTitle: region.title,
              ChartType: this.getRegionWidget(region) ? this.getRegionWidget(region).chart : null,
              GridX: cursorX,
              GridY: cursorY,
              GridW: width,
              GridH: height,
              SortOrder: index + 1
            };
            cursorX += width;
            rowHeight = Math.max(rowHeight, height);
            if (Number(payload.ReportDefinitionID || 0) > 0) {
              output.push(payload);
            }
          }.bind(this));
          cursorY += rowHeight;
        }.bind(this));
        cursorY += 1;
      }.bind(this));
      return output;
    },
    saveLayout: function () {
      var self = this;
      self.isSavingLayout = true;
      apiCallAsync("WF_ReportDashboard_SaveLayout", {
        ReportDashboardID: self.dashboardId || 0,
        DashboardName: self.dashboardName,
        Layout: {
          CanvasMode: "section-region-builder",
          WidgetCount: self.dashboardWidgets.length,
          sections: (self.dashboardSections || []).map(function (section, index) {
            return {
              sectionId: section.sectionId,
              title: section.title || ("Section " + (index + 1)),
              layoutCode: section.layoutCode || "single",
              sortOrder: index + 1
            };
          }),
          regions: (self.dashboardRegions || []).map(function (region, index) {
            var size = region.sizePreset || "compact";
            return {
              regionId: region.regionId,
              title: region.title || ("Vùng " + (index + 1)),
              sizePreset: size,
              widthUnits: Number(region.widthUnits || self.resolveWidthUnits(size)),
              rowIndex: Number(region.rowIndex !== undefined ? region.rowIndex : index),
              sectionId: region.sectionId || (self.dashboardSections[0] ? self.dashboardSections[0].sectionId : "section_default"),
              widgetId: region.widgetId || 0,
              sortOrder: index + 1,
              gridW: Number(region.widthUnits || self.resolveWidthUnits(size)),
              gridH: size === "tall" ? 5 : (size === "hero" ? 5 : 3)
            };
          })
        },
        Widgets: self.buildLayoutWidgets()
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (row && row.ReportDashboardID) {
          self.dashboardId = Number(row.ReportDashboardID || self.dashboardId || 0);
          self.dashboardQueryId = self.dashboardId;
        }
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã lưu bố cục bảng điều khiển.");
        }
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Lưu bố cục bảng điều khiển thất bại.");
        }
      }).finally(function () {
        self.isSavingLayout = false;
      });
    },
    applyGlobalFilters: function () {
      this.loadWidgetRuntime();
    },
    resetGlobalFilters: function () {
      this.globalRange = "30 ngày gần nhất";
      this.globalStatus = "Tất cả";
      this.globalDatasetFilter = "Tất cả";
      this.globalChartFilter = "Tất cả";
      this.globalSearchQuery = "";
      this.loadWidgetRuntime();
    },
    openWidgetPicker: function (region) {
      this.selectedRegionId = region && region.regionId ? region.regionId : "";
      this.isWidgetPickerOpen = true;
      this.loadWidgetLibrary();
    },
    loadWidgetLibrary: function () {
      var self = this;
      apiCallAsync("WF_ReportDefinition_GetList", {
        Keyword: "",
        OnlyMine: 1
      }).then(function (resultSets) {
        var rows = self.extractReportDefinitionRows(resultSets);
        if (rows && rows.length) {
          self.widgetLibrary = self.mapWidgetLibraryRows(rows).concat(self.buildSystemWidgetLibrary());
          return;
        }
        return apiCallAsync("WF_ReportDefinition_GetList", {
          Keyword: "",
          OnlyMine: 0
        }).then(function (fallbackSets) {
          var fallbackRows = self.extractReportDefinitionRows(fallbackSets);
          self.widgetLibrary = self.mapWidgetLibraryRows(fallbackRows || []).concat(self.buildSystemWidgetLibrary());
        });
      }).catch(function () {
        self.widgetLibrary = self.buildSystemWidgetLibrary();
      });
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
    mapWidgetLibraryRows: function (rows) {
      var self = this;
      return (rows || []).map(function (item) {
        var itemConfig = self.tryParseJsonObject(item.ConfigJson, {});
        return {
          id: Number(item.ReportDefinitionID || 0),
          name: item.ReportName || "Widget",
          dataset: item.DatasetName || item.DatasetCode || "-",
          chart: itemConfig.ChartType || item.ChartType || "bar",
          updatedAt: self.formatDate(item.UpdateTime || item.CreateTime),
          isPinned: false
        };
      });
    },
    openBuilderFromPicker: function () {
      this.isWidgetPickerOpen = false;
      this.openBuilder();
    },
    openMyReportsFromPicker: function () {
      this.isWidgetPickerOpen = false;
      this.openMyReports();
    },
    addWidgetToCanvas: function (item) {
      var self = this;
      var targetRegion = (self.dashboardRegions || []).find(function (region) {
        return String(region.regionId || "") === String(self.selectedRegionId || "");
      }) || null;
      if (!item || !item.id) {
        return;
      }
      if (item.isSystem) {
        var systemWidget = (self.dashboardWidgets || []).find(function (widget) {
          return Number(widget.reportDefinitionId || 0) === Number(item.id || 0);
        }) || self.createSystemWidgetById(item.id);
        if (!systemWidget) {
          return;
        }
        if (!(self.dashboardWidgets || []).some(function (widget) { return Number(widget.reportDefinitionId || 0) === Number(item.id || 0); })) {
          self.dashboardWidgets.push(systemWidget);
        }
        if (targetRegion) {
          targetRegion.widgetId = Number(item.id || 0);
          targetRegion.title = item.name;
        } else {
          self.dashboardRegions.push({
            regionId: "region_" + String(item.id || Date.now()),
            title: item.name,
            sizePreset: "wide",
            widthUnits: 8,
            rowIndex: self.getSectionRegions(self.selectedSectionId || (self.dashboardSections[0] ? self.dashboardSections[0].sectionId : "section_default")).length,
            sectionId: self.selectedSectionId || (self.dashboardSections[0] ? self.dashboardSections[0].sectionId : "section_default"),
            widgetId: Number(item.id || 0),
            sortOrder: self.dashboardRegions.length + 1
          });
        }
        if (typeof showToast !== "undefined") {
          showToast.success("Đã thêm widget tuyển sinh vào report dashboard.");
        }
        self.isWidgetPickerOpen = false;
        self.selectedRegionId = "";
        self.loadSingleWidgetRuntime(systemWidget);
        return;
      }
      if (targetRegion && Number(targetRegion.widgetId || 0) === Number(item.id || 0)) {
        self.isWidgetPickerOpen = false;
        return;
      }
      apiCallAsync("WF_ReportDashboard_PinReport", {
        ReportDefinitionID: item.id
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        var existingWidget = (self.dashboardWidgets || []).find(function (widget) {
          return Number(widget.reportDefinitionId || 0) === Number(item.id || 0);
        });
        if (!existingWidget) {
          existingWidget = {
            reportDefinitionId: Number(item.id || 0),
            name: item.name,
            dataset: item.dataset,
            chart: item.chart,
            updatedAt: item.updatedAt,
            sortOrder: self.dashboardWidgets.length + 1,
            gridX: 0,
            gridY: 0,
            gridW: 4,
            gridH: 3,
            sizePreset: "compact",
            previewSummary: null,
            previewRows: [],
            formulaColumns: [],
            dimensionKey: "",
            metricKey: "",
            isLoading: true,
            error: ""
          };
          self.dashboardWidgets.push(existingWidget);
        }
        if (targetRegion) {
          targetRegion.widgetId = Number(item.id || 0);
          targetRegion.title = item.name;
        } else {
          self.dashboardRegions.push({
            regionId: "region_" + String(item.id || Date.now()),
            title: item.name,
            sizePreset: "compact",
            widthUnits: 4,
            rowIndex: self.getSectionRegions(self.selectedSectionId || (self.dashboardSections[0] ? self.dashboardSections[0].sectionId : "section_default")).length,
            sectionId: self.selectedSectionId || (self.dashboardSections[0] ? self.dashboardSections[0].sectionId : "section_default"),
            widgetId: Number(item.id || 0),
            sortOrder: self.dashboardRegions.length + 1
          });
        }
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã thêm widget vào dashboard.");
        }
        self.isWidgetPickerOpen = false;
        self.selectedRegionId = "";
        self.loadSingleWidgetRuntime(existingWidget).then(function () {
          self.$nextTick(function () {
            self.renderAllCharts();
          });
        });
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không thêm được widget vào dashboard.");
        }
      });
    },
    tryParseJsonObject: function (value, fallback) {
      if (!value) return fallback || {};
      if (typeof value === "object") return value;
      try {
        return JSON.parse(value);
      } catch (e) {
        return fallback || {};
      }
    },
    formatDate: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (isNaN(dt.getTime())) return String(value);
      return dt.toLocaleString("vi-VN", { hour: "2-digit", minute: "2-digit", day: "2-digit", month: "2-digit" });
    },
    formatNumber: function (value) {
      if (value === null || value === undefined || value === "") {
        return "-";
      }
      return Number(value || 0).toLocaleString("vi-VN", {
        maximumFractionDigits: 2
      });
    },
    openBuilder: function () {
      window.location.href = "/wf-report-builder";
    },
    openDashboardList: function () {
      window.location.href = "/wf-report-dashboard-list";
    },
    openPresentView: function () {
      var targetId = Number(this.dashboardId || this.dashboardQueryId || 0);
      if (targetId > 0) {
        window.location.href = "/wf-report-dashboard-view?id=" + String(targetId);
        return;
      }
      if (typeof showToast !== "undefined") {
        showToast.info("Hãy lưu dashboard trước khi mở chế độ trình chiếu.");
      }
    },
    openMyReports: function () {
      window.location.href = "/wf-report-my-reports";
    },
    openReportDetail: function (item, groupLabel) {
      if (!item || !item.reportDefinitionId) {
        return;
      }
      var params = new URLSearchParams();
      params.set("id", String(item.reportDefinitionId));
      params.set("range", this.globalRange || "");
      params.set("status", this.globalStatus || "");
      if (groupLabel) {
        params.set("group", groupLabel);
      }
      window.location.href = "/wf-report-detail?" + params.toString();
    }
  }
};
if (typeof window !== "undefined") {
  window.__WF_REPORT_DASHBOARD_CANVAS_MIXIN__ = wfReportDashboardCanvasMixin;
}