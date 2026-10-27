// sync-touch: 2026-03-23 dashboard-present-runtime
window.__WF_REPORT_DASHBOARD_VIEW_VERSION__ = "2026-03-21-present-runtime-v1";
window.__WF_REPORT_DASHBOARD_VIEW_MIXIN__ = {
  data: function () {
    return {
      chartInstances: {},
      dashboardQueryId: 0,
      dashboardId: 0,
      dashboardName: "Dashboard trình chiếu",
      dashboardSections: [],
      dashboardRegions: [],
      dashboardWidgets: [],
      widgetRuntimeCache: {},
      widgetLoadQueue: [],
      widgetLoadPromiseMap: {},
      pendingChartRenderHandles: {},
      pendingChartRenderQueue: [],
      widgetObserver: null,
      activeWidgetLoadCount: 0,
      activeChartRenderKey: "",
      maxConcurrentWidgetLoads: 2,
      widgetLoadingMinMs: 350,
      datasetMetaMap: {},
      datasetCatalogPromise: null,
      tablePageSizeOptions: [10, 20, 50, 100],
      globalRange: "30 ngày gần nhất",
      globalStatus: "Tất cả",
      isFullscreen: false
    };
  },
  computed: {
    rangeOptions: function () {
      return ["7 ngày gần nhất", "30 ngày gần nhất", "Quý này", "Năm nay"];
    },
    statusOptions: function () {
      return ["Tất cả", "Đang hoạt động", "Chỉ hoàn tất", "Cần xử lý"];
    },
    dashboardSummaryText: function () {
      var widgetCount = 0;
      ;(this.dashboardRegions || []).forEach(function (region) {
        if (region && Number(region.widgetId || 0) !== 0) {
          widgetCount += 1;
        }
      });
      if (!(this.dashboardSections || []).length) {
        return "Dashboard này chưa có section hoặc chưa gắn widget nào.";
      }
      return "Có " + String((this.dashboardSections || []).length) + " section, " + String((this.dashboardRegions || []).length) + " vùng và " + String(widgetCount) + " widget đang trình chiếu.";
    },
    renderedSections: function () {
      var self = this;
      return (this.dashboardSections || []).slice().sort(function (a, b) {
        return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
      }).map(function (section) {
        var regions = self.getSectionRegions(section.sectionId);
        return {
          sectionId: section.sectionId,
          title: section.title || "Section",
          layoutCode: section.layoutCode || "single",
          regions: regions,
          rows: self.buildRegionRows(regions)
        };
      });
    }
  },
  watch: {
    globalRange: function () {
      this.reloadRuntime();
    },
    globalStatus: function () {
      this.reloadRuntime();
    }
  },
  mounted: function () {
    this.readRuntimeConfig();
    this.loadDashboard();
    window.addEventListener("resize", this.handleResize);
  },
  beforeDestroy: function () {
    window.removeEventListener("resize", this.handleResize);
    this.disconnectWidgetObserver();
    this.cancelAllPendingChartRenders();
    this.disposeAllCharts();
  },
  methods: {
    extractRows: function (resultSets) {
      if (!resultSets) {
        return [];
      }
      if (Array.isArray(resultSets.data)) {
        resultSets = resultSets.data;
      }
      if (!Array.isArray(resultSets)) {
        return [];
      }
      if (resultSets.length && Array.isArray(resultSets[0]) && resultSets[0].length && Array.isArray(resultSets[0][0])) {
        return resultSets[0];
      }
      return resultSets;
    },
    getResultSet: function (resultSets, index) {
      var normalized = resultSets;
      var splitRows = null;
      if (normalized && Array.isArray(normalized.data)) {
        normalized = normalized.data;
      }
      if (!Array.isArray(normalized)) {
        return [];
      }
      if (normalized.length && !Array.isArray(normalized[0]) && typeof normalized[0] === "object") {
        splitRows = this.splitFlatDashboardRows(normalized);
        return splitRows[index] || [];
      }
      if (normalized.length && Array.isArray(normalized[0])) {
        return normalized[index] || [];
      }
      return index === 0 ? normalized : [];
    },
    splitFlatDashboardRows: function (rows) {
      var dashboardRows = [];
      var widgetRows = [];
      (rows || []).forEach(function (row) {
        if (row && (row.ReportDashboardWidgetID || row.ReportDefinitionID || row.WidgetTitle || row.ChartType)) {
          widgetRows.push(row);
        } else {
          dashboardRows.push(row);
        }
      });
      return [dashboardRows, widgetRows];
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
    reloadRuntime: function () {
      this.loadDashboard();
    },
    loadDashboard: function () {
      var self = this;
      if (!this.dashboardQueryId) {
        this.dashboardSections = [];
        this.dashboardRegions = [];
        this.dashboardWidgets = [];
        this.disposeAllCharts();
        return;
      }
      apiCallAsync("WF_ReportDashboard_GetDetail", {
        ReportDashboardID: this.dashboardQueryId
      }).then(function (resultSets) {
        var dashboardRows = self.getResultSet(resultSets, 0);
        var widgetRows = self.getResultSet(resultSets, 1);
        var dashboard = dashboardRows && dashboardRows[0] ? dashboardRows[0] : null;
        var layout = self.tryParseJsonObject(dashboard && dashboard.LayoutJson, {});
        self.dashboardId = Number(dashboard && dashboard.ReportDashboardID ? dashboard.ReportDashboardID : 0);
        self.dashboardName = dashboard && dashboard.DashboardName ? dashboard.DashboardName : self.dashboardName;
        self.dashboardWidgets = (widgetRows || []).map(function (item, index) {
          var itemConfig = self.tryParseJsonObject(item.ConfigJson, {});
          return {
            reportDefinitionId: Number(item.ReportDefinitionID || 0),
            name: item.WidgetTitle || item.ReportName || ("Widget " + String(index + 1)),
            dataset: item.DatasetName || item.DatasetCode || "-",
            datasetCode: item.DatasetCode || "",
            chart: itemConfig.ChartType || item.ChartType || "bar",
            updatedAt: self.formatDate(item.UpdateTime || item.CreateTime),
            sortOrder: Number(item.SortOrder || index + 1),
            gridW: Number(item.GridW || 4),
            gridH: Number(item.GridH || 3),
            sizePreset: self.resolveSizePreset(item.GridW, item.GridH),
            previewSummary: null,
            previewRows: [],
            tableDetailRows: [],
            formulaColumns: Array.isArray(itemConfig.FormulaColumns) ? itemConfig.FormulaColumns : [],
            tableConfig: itemConfig.TableConfig || {},
            dimensionKey: item.DimensionKey || "",
            metricKey: item.MetricKey || "",
            error: "",
            isLoading: true
          };
        }).sort(function (a, b) {
          return Number(a.sortOrder || 0) - Number(b.sortOrder || 0);
        });
        self.dashboardRegions = self.resolveRegions(layout, self.dashboardWidgets);
        self.dashboardWidgets = self.mergeSystemWidgetsFromLayout(self.dashboardWidgets, self.dashboardRegions);
        self.dashboardSections = self.resolveSections(layout, self.dashboardRegions);
        self.ensureRegionsHaveSection();
        self.loadWidgetRuntime();
      }).catch(function () {
        self.dashboardSections = [];
        self.dashboardRegions = [];
        self.dashboardWidgets = [];
        self.disposeAllCharts();
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được dashboard trình chiếu.");
        }
      });
    },
    loadWidgetRuntime: function () {
      var self = this;
      self.disconnectWidgetObserver();
      self.widgetLoadQueue = [];
      self.widgetLoadPromiseMap = {};
      self.activeWidgetLoadCount = 0;
      if (!(this.dashboardWidgets || []).length) {
        this.disposeAllCharts();
        return;
      }
      (this.dashboardWidgets || []).forEach(function (item) {
        self.markWidgetLoading(item);
        item.error = "";
      });
      this.disposeAllCharts();
      this.$nextTick(function () {
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
        var detailRows = self.getResultSet(responses[0], 0);
        var previewSummaryRows = self.getResultSet(responses[1], 0);
        var previewDataRows = self.getResultSet(responses[1], 1);
        var detail = detailRows && detailRows[0] ? detailRows[0] : null;
        var config = self.tryParseJsonObject(detail && detail.ConfigJson, {});
        item.chart = config.ChartType || item.chart;
        item.dataset = detail && (detail.DatasetName || detail.DatasetCode) ? (detail.DatasetName || detail.DatasetCode) : item.dataset;
        item.dimensionKey = detail && detail.DimensionKey ? detail.DimensionKey : item.dimensionKey;
        item.metricKey = detail && detail.MetricKey ? detail.MetricKey : item.metricKey;
        item.formulaColumns = Array.isArray(config.FormulaColumns) ? config.FormulaColumns : [];
        item.tableConfig = config.TableConfig || {};
        item.previewSummary = previewSummaryRows && previewSummaryRows[0] ? previewSummaryRows[0] : null;
        item.previewRows = self.mapPreviewRows(previewDataRows, detail);
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
          self.storeWidgetRuntimeCache(item);
        });
      }).catch(function () {
        item.error = "Không tải được dữ liệu widget.";
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
        rootMargin: "220px 0px 220px 0px",
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
    loadSystemWidgetRuntime: function (item) {
      item.previewSummary = {
        TotalValue: 691988,
        TopLabel: "Tiểu học"
      };
      item.previewRows = [
        { __rowKey: "row_1", label: "Mầm non", value: 121872, share: 17.6, delta: 0, requestCount: 374, completedRate: 0, slaHours: 0 },
        { __rowKey: "row_2", label: "Tiểu học", value: 295190, share: 42.7, delta: 0, requestCount: 291, completedRate: 0, slaHours: 0 },
        { __rowKey: "row_3", label: "THCS", value: 194915, share: 28.2, delta: 0, requestCount: 170, completedRate: 0, slaHours: 0 },
        { __rowKey: "row_4", label: "THPT", value: 80011, share: 11.6, delta: 0, requestCount: 50, completedRate: 0, slaHours: 0 }
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
        { label: "MOET: Thống kê giáo dục mầm non năm học 2023-2024", meta: "Bộ Giáo dục và Đào tạo, đăng ngày 15/05/2025", url: "https://moet.gov.vn/thong-ke/Pages/thong-ke-giao-duc-mam-non.aspx?ItemID=10548" },
        { label: "MOET: Thống kê giáo dục tiểu học năm học 2023-2024", meta: "Bộ Giáo dục và Đào tạo, công bố trên chuyên mục thống kê năm 2025", url: "https://moet.gov.vn/thong-ke/pages/thong-ke-giao-duc-tieu-hoc.aspx" },
        { label: "MOET: Thống kê giáo dục THCS và THPT năm học 2023-2024", meta: "Bộ Giáo dục và Đào tạo, đăng ngày 14/05/2025", url: "https://moet.gov.vn/thong-ke/Pages/Thong-ke-giao-duc-trung-hoc.aspx" },
        { label: "Đồng Nai: Phụ lục quy mô trường lớp giai đoạn 2011-2020", meta: "Báo cáo quy hoạch tỉnh, phụ lục có số trường/lớp/học sinh đến năm học 2020-2021", url: "https://skhdt.dongnai.gov.vn/Shared%20Documents/2085_20230308_Project%20%C4%90%E1%BB%93ng%20Nai_BC%20gi%E1%BB%AFa%20k%E1%BB%B3_Ph%E1%BA%A7n%203.pdf" },
        { label: "Đồng Nai: Dự báo dân số đến năm 2030 và 2050", meta: "Báo cáo quy hoạch tỉnh, kịch bản khả thi", url: "https://skhdt.dongnai.gov.vn/Shared%20Documents/2085_20230308_Project%20%C4%90%E1%BB%93ng%20Nai_BC%20gi%E1%BB%AFa%20k%E1%BB%B3_Ph%E1%BA%A7n%202.pdf" }
      ];
      item.officialTrendLinks = [
        { label: "Quan tâm đến trường tư thục, song ngữ, STEM tại Việt Nam", meta: "Google Trends live, 12 tháng gần nhất", url: "https://trends.google.com/trends/explore?date=today%2012-m&geo=VN&q=tr%C6%B0%E1%BB%9Dng%20t%C6%B0%20th%E1%BB%A5c,tr%C6%B0%E1%BB%9Dng%20song%20ng%E1%BB%AF,stem%20cho%20h%E1%BB%8Dc%20sinh" },
        { label: "Quan tâm đến học phí, lớp 10 và hướng nghiệp", meta: "Google Trends live, 12 tháng gần nhất", url: "https://trends.google.com/trends/explore?date=today%2012-m&geo=VN&q=h%E1%BB%8Dc%20ph%C3%AD%20tr%C6%B0%E1%BB%9Dng%20t%C6%B0,luy%E1%BB%87n%20thi%20l%E1%BB%9Bp%2010,h%C6%B0%E1%BB%9Bng%20nghi%E1%BB%87p%20l%E1%BB%9Bp%2012" },
        { label: "Trang Google Trends chính thức", meta: "Có thể export, embed và đối chiếu trực tiếp theo thời gian", url: "https://trends.google.com/trends/" }
      ];
      item.isLoading = false;
      item.error = "";
      item.tableDetailRows = [];
      return Promise.resolve(item);
    },
    mapPreviewRows: function (rows, detail) {
      var metricKey = detail && detail.MetricKey ? detail.MetricKey : "requestCount";
      return (rows || []).map(function (row, index) {
        return {
          __rowKey: "row_" + String(index + 1),
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
        silent: true
      });
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
          xAxis: { type: "value", axisLabel: { color: "#5f6368", fontSize: 11 } },
          yAxis: { type: "category", data: labels, axisLabel: { color: "#5f6368", fontSize: 11 } },
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
        xAxis: { type: "category", data: labels, axisLabel: { color: "#5f6368", fontSize: 11 } },
        yAxis: { type: "value", axisLabel: { color: "#5f6368", fontSize: 11 } },
        series: [{
          type: (item.chart === "line" || item.chart === "area") ? "line" : "bar",
          animation: false,
          animationDuration: 0,
          animationDurationUpdate: 0,
          smooth: item.chart === "line" || item.chart === "area",
          barMaxWidth: 36,
          symbolSize: 8,
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
    tryParseJsonObject: function (rawValue, fallback) {
      if (!rawValue) {
        return fallback || {};
      }
      if (typeof rawValue === "object") {
        return rawValue;
      }
      try {
        return JSON.parse(rawValue);
      } catch (error) {
        return fallback || {};
      }
    },
    resolveRegions: function (layout, widgets) {
      var storedRegions = layout && Array.isArray(layout.regions) ? layout.regions : [];
      if (storedRegions.length) {
        return storedRegions.map(function (region, index) {
          return {
            regionId: region.regionId || ("region_" + String(index + 1)),
            title: region.title || ("Vùng " + String(index + 1)),
            sizePreset: region.sizePreset || "compact",
            widthUnits: Number(region.widthUnits || this.resolveWidthUnits(region.sizePreset || "compact")),
            rowIndex: Number(region.rowIndex || 0),
            sortOrder: Number(region.sortOrder || index + 1),
            widgetId: Number(region.widgetId || 0),
            sectionId: region.sectionId || "section_default"
          };
        }.bind(this));
      }
      return (widgets || []).map(function (item, index) {
        return {
          regionId: "region_" + String(index + 1),
          title: item.name,
          sizePreset: item.sizePreset || "compact",
          widthUnits: Number(item.gridW || this.resolveWidthUnits(item.sizePreset || "compact")),
          rowIndex: 0,
          sortOrder: index + 1,
          widgetId: Number(item.reportDefinitionId || 0),
          sectionId: "section_default"
        };
      }.bind(this));
    },
    resolveSections: function (layout, regions) {
      var storedSections = layout && Array.isArray(layout.sections) ? layout.sections : [];
      if (storedSections.length) {
        return storedSections.map(function (section, index) {
          return {
            sectionId: section.sectionId || ("section_" + String(index + 1)),
            title: section.title || ("Section " + String(index + 1)),
            layoutCode: section.layoutCode || "single",
            sortOrder: Number(section.sortOrder || index + 1)
          };
        });
      }
      return [{
        sectionId: "section_default",
        title: "Section 1",
        layoutCode: "single",
        sortOrder: 1
      }];
    },
    ensureRegionsHaveSection: function () {
      ;(this.dashboardRegions || []).forEach(function (region) {
        if (!region.sectionId) {
          region.sectionId = "section_default";
        }
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
      var rowMap = {};
      (regions || []).forEach(function (region) {
        var key = String(Number(region.rowIndex || 0));
        if (!rowMap[key]) {
          rowMap[key] = [];
          rows.push(rowMap[key]);
        }
        rowMap[key].push(region);
      });
      return rows;
    },
    getRegionWidget: function (region) {
      var targetId = Number(region && region.widgetId ? region.widgetId : 0);
      return (this.dashboardWidgets || []).find(function (item) {
        return Number(item.reportDefinitionId || 0) === targetId;
      }) || null;
    },
    mergeSystemWidgetsFromLayout: function (widgets, regions) {
      var output = (widgets || []).slice();
      var self = this;
      (regions || []).forEach(function (region) {
        var widgetId = Number(region && region.widgetId ? region.widgetId : 0);
        if (widgetId >= 0) {
          return;
        }
        if (output.some(function (item) { return Number(item.reportDefinitionId || 0) === widgetId; })) {
          return;
        }
        output.push(self.createSystemWidgetById(widgetId));
      });
      return output;
    },
    createSystemWidgetById: function (widgetId) {
      if (Number(widgetId) === -9001) {
        return {
          reportDefinitionId: -9001,
          name: "Radar tuyển sinh Đồng Nai",
          dataset: "MOET + Google Trends + Đồng Nai quy hoạch",
          datasetCode: "",
          chart: "official_live",
          updatedAt: "22/03 23:59",
          sortOrder: this.dashboardWidgets.length + 1,
          gridW: 8,
          gridH: 4,
          sizePreset: "wide",
          previewSummary: null,
          previewRows: [],
          tableDetailRows: [],
          formulaColumns: [],
          tableConfig: {},
          dimensionKey: "",
          metricKey: "",
          error: "",
          isLoading: true,
          isSystem: true,
          systemKey: "admission_radar_dong_nai"
        };
      }
      return null;
    },
    resolveWidthUnits: function (sizePreset) {
      var map = { compact: 4, wide: 8, tall: 4, hero: 12 };
      return map[sizePreset] || 4;
    },
    resolveSizePreset: function (gridW, gridH) {
      var width = Number(gridW || 4);
      var height = Number(gridH || 3);
      if (width >= 12) {
        return "hero";
      }
      if (width >= 8) {
        return "wide";
      }
      if (height >= 4) {
        return "tall";
      }
      return "compact";
    },
    regionCardClasses: function (region) {
      var item = this.getRegionWidget(region);
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
        "wf-report-widget--auto-height": !!item && (this.isProgressListWidget(item) || this.isKpiWidget(item)),
        "wf-report-widget--progress-runtime": !!item && this.isProgressListWidget(item)
      };
    },
    regionGridStyle: function (region, rowLength) {
      var width = Number(region && region.widthUnits ? region.widthUnits : 4);
      var percent = (width / 12) * 100;
      var divisor = Number(rowLength || 1);
      var gapPx = 16;
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
    layoutLabel: function (layoutCode) {
      var map = {
        single: "1 vùng toàn màn",
        two_equal: "2 vùng đều",
        three_equal: "3 vùng đều",
        ratio_1_3: "Tỷ lệ 1:3",
        ratio_3_1: "Tỷ lệ 3:1",
        ratio_1_3_1: "Tỷ lệ 1:3:1",
        ratio_1_4: "Tỷ lệ 1:4",
        hero_two_bottom: "1 hero + 2 dưới",
        two_top_one_bottom: "2 trên + 1 wide dưới",
        sidebar_left_content_right: "Sidebar trái + nội dung phải"
      };
      return map[layoutCode] || "Chưa chọn layout";
    },
    regionDescription: function (region) {
      var item = this.getRegionWidget(region);
      if (!item) {
        return "Vùng này chưa có widget.";
      }
      return (item.dataset || "-") + " · " + (item.chart || "-");
    },
    regionSizeLabel: function (region) {
      return String(region.widthUnits || 0) + "/12";
    },
    isKpiWidget: function (item) {
      return !!(item && item.chart === "kpi");
    },
    isProgressListWidget: function (item) {
      return !!(item && item.chart === "progress_list");
    },
    isDataTableWidget: function (item) {
      return !!(item && item.chart === "table");
    },
    isMatrixWidget: function (item) {
      return !!(item && item.chart === "matrix");
    },
    isOfficialLiveWidget: function (item) {
      return !!(item && item.chart === "official_live");
    },
    isTableLikeChart: function (item) {
      return this.isDataTableWidget(item) || this.isMatrixWidget(item);
    },
    getChartDomId: function (item) {
      return "wf-report-view-chart-" + String(item && item.reportDefinitionId ? item.reportDefinitionId : "na");
    },
    widgetMetricLabel: function (item) {
      return item && item.metricKey ? item.metricKey : "Metric";
    },
    widgetKpiValue: function (item) {
      if (!item || !item.previewSummary) {
        return "-";
      }
      return this.formatNumber(item.previewSummary.TotalValue || item.previewSummary.TotalCount || 0);
    },
    widgetProgressWidth: function (item, row) {
      var rows = item && item.previewRows ? item.previewRows : [];
      var maxValue = 0;
      rows.forEach(function (current) {
        maxValue = Math.max(maxValue, Number(current && current.value ? current.value : 0));
      });
      if (maxValue <= 0) {
        return "0%";
      }
      return String(Math.max(6, Math.round((Number(row && row.value ? row.value : 0) / maxValue) * 100))) + "%";
    },
    buildTableColumns: function (item) {
      var tableConfig = item && item.tableConfig ? item.tableConfig : {};
      var labels = tableConfig.ColumnLabels || {};
      var columns = [];
      var visible = Array.isArray(tableConfig.VisibleColumns) && tableConfig.VisibleColumns.length
        ? tableConfig.VisibleColumns
        : this.defaultTableVisibleColumns(item);
      visible.forEach(function (key) {
        columns.push({
          key: key,
          label: labels[key] || this.defaultColumnLabel(key),
          width: this.resolveTableColumnWidth(item, key),
          type: this.resolvePresentTableColumnType(item, key)
        });
      }.bind(this));
      return columns;
    },
    resolvePresentTableColumnType: function (item, key) {
      var rows = this.resolveTableSourceRows(item);
      var index = 0;
      var value = "";
      for (index = 0; index < rows.length; index += 1) {
        value = rows[index] && rows[index][key] !== undefined && rows[index][key] !== null ? rows[index][key] : "";
        if (value === "") {
          continue;
        }
        if (!isNaN(Number(value))) {
          return "number";
        }
        return "text";
      }
      return "text";
    },
    resolveTableColumnWidth: function (item, key) {
      var tableConfig = item && item.tableConfig ? item.tableConfig : {};
      var widths = tableConfig.ColumnWidths || {};
      var width = Number(widths[key] || 0);
      if (!width || width < 90) {
        return 180;
      }
      return width;
    },
    tableColumnStyle: function (item, column) {
      var width = column && column.width ? Number(column.width) : this.resolveTableColumnWidth(item, column && column.key);
      if (!width) {
        return {};
      }
      return {
        minWidth: String(width) + "px",
        width: String(width) + "px"
      };
    },
    shouldUseTableLiteScroll: function (item) {
      var rows = this.buildTableAllRows(item);
      var columns = this.buildTableColumns(item);
      return rows.length > 8 || columns.length > 6;
    },
    tableCellClass: function (column, row) {
      if (!column || !column.key) {
        return "";
      }
      if (column.key === "delta") {
        return Number(row && row[column.key] || 0) >= 0 ? "wf-text-pos" : "wf-text-neg";
      }
      if (column.type === "number") {
        return "wf-report-cell-number";
      }
      return "";
    },
    tableFreezeFirstColumn: function (item) {
      var tableConfig = item && item.tableConfig ? item.tableConfig : {};
      return tableConfig.FreezeFirstColumn !== undefined ? !!tableConfig.FreezeFirstColumn : true;
    },
    defaultTableVisibleColumns: function (item) {
      var rows = this.resolveTableSourceRows(item);
      if (rows.length > 0) {
        return Object.keys(rows[0]).filter(function (key) {
          return key !== "sourceIndex" && key !== "__rowKey";
        });
      }
      return ["label", "value", "delta", "share"];
    },
    resolveTableSourceRows: function (item) {
      var self = this;
      if (item && Array.isArray(item.tableDetailRows) && item.tableDetailRows.length > 0) {
        return item.tableDetailRows.map(function (row, index) {
          return self.normalizeTableRow(row, index);
        });
      }
      return (item && item.previewRows ? item.previewRows : []).map(function (row, index) {
        return self.normalizeTableRow(row, index);
      });
    },
    normalizeTableRow: function (row, index) {
      var output = {};
      Object.keys(row || {}).forEach(function (key) {
        output[key] = row[key];
      });
      output.sourceIndex = index;
      output.__rowKey = output.__rowKey || ("row_" + String(index + 1));
      return output;
    },
    resolveTablePageSize: function (item) {
      var tableConfig = item && item.tableConfig ? item.tableConfig : {};
      var size = Number(tableConfig.PageSize || 10);
      if (this.tablePageSizeOptions.indexOf(size) < 0) {
        size = 10;
      }
      return size;
    },
    resolveTablePageIndex: function (item) {
      var tableConfig = item && item.tableConfig ? item.tableConfig : {};
      var pageIndex = Number(tableConfig.PageIndex || 1);
      return pageIndex > 0 ? pageIndex : 1;
    },
    buildTableAllRows: function (item) {
      var rows = this.resolveTableSourceRows(item).slice();
      var tableConfig = item && item.tableConfig ? item.tableConfig : {};
      var sortBy = tableConfig.SortBy || "";
      var sortDir = String(tableConfig.SortDir || "asc").toLowerCase();
      var topN = Number(tableConfig.TopN || 0);
      var tableFilters = tableConfig.TableFilters || {};
      var keyword = String(tableFilters.keyword || "").trim().toLowerCase();
      var minValue = tableFilters.minValue === "" || tableFilters.minValue === null || tableFilters.minValue === undefined
        ? null
        : Number(tableFilters.minValue);
      var deltaMode = String(tableFilters.deltaMode || "all");
      if (keyword) {
        rows = rows.filter(function (row) {
          return Object.keys(row || {}).some(function (key) {
            if (key === "sourceIndex" || key === "__rowKey") {
              return false;
            }
            return String(row[key] === undefined || row[key] === null ? "" : row[key]).toLowerCase().indexOf(keyword) >= 0;
          });
        });
      }
      if (minValue !== null && !isNaN(minValue)) {
        rows = rows.filter(function (row) {
          var target = row && row[sortBy || "value"] !== undefined ? row[sortBy || "value"] : row.value;
          if (isNaN(Number(target))) {
            return true;
          }
          return Number(target || 0) >= minValue;
        });
      }
      if (deltaMode === "positive") {
        rows = rows.filter(function (row) {
          return row.delta === undefined || Number(row.delta || 0) > 0;
        });
      }
      if (deltaMode === "negative") {
        rows = rows.filter(function (row) {
          return row.delta === undefined || Number(row.delta || 0) < 0;
        });
      }
      if (sortBy) {
        rows.sort(function (a, b) {
          var av = a[sortBy];
          var bv = b[sortBy];
          if (av === bv) {
            return 0;
          }
          if (sortDir === "desc") {
            return av > bv ? -1 : 1;
          }
          return av > bv ? 1 : -1;
        });
      }
      if (topN > 0) {
        rows = rows.slice(0, topN);
      }
      return rows;
    },
    buildTableRows: function (item) {
      var rows = this.buildTableAllRows(item);
      var pageSize = this.resolveTablePageSize(item);
      var pageIndex = this.resolveTablePageIndex(item);
      var pageCount = Math.max(1, Math.ceil(rows.length / pageSize));
      var safePage = Math.min(pageIndex, pageCount);
      var start = (safePage - 1) * pageSize;
      if (item && item.tableConfig && Number(item.tableConfig.PageIndex || 1) !== safePage) {
        item.tableConfig.PageIndex = safePage;
      }
      return rows.slice(start, start + pageSize);
    },
    buildTableFooter: function (item) {
      var footer = {};
      var rows = this.buildTableAllRows(item);
      var columns = this.buildTableColumns(item);
      var index = 0;
      var key = "";
      for (index = 0; index < columns.length; index += 1) {
        key = columns[index].key;
        if (index === 0) {
          footer[key] = "Tổng: " + String(rows.length) + " dòng";
          continue;
        }
        if (this.isNumericTableColumn(rows, key)) {
          footer[key] = rows.reduce(function (sum, row) {
            return sum + Number(row && row[key] !== undefined && row[key] !== null && row[key] !== "" ? row[key] : 0);
          }, 0);
        } else {
          footer[key] = "";
        }
      }
      return footer;
    },
    buildTablePageCount: function (item) {
      var rows = this.buildTableAllRows(item);
      var pageSize = this.resolveTablePageSize(item);
      return Math.max(1, Math.ceil(rows.length / pageSize));
    },
    buildTablePageText: function (item) {
      var totalRows = this.buildTableAllRows(item).length;
      var pageSize = this.resolveTablePageSize(item);
      var pageCount = Math.max(1, Math.ceil(totalRows / pageSize));
      var pageIndex = Math.min(this.resolveTablePageIndex(item), pageCount);
      var start = totalRows === 0 ? 0 : ((pageIndex - 1) * pageSize) + 1;
      var end = Math.min(totalRows, pageIndex * pageSize);
      return "Hiển thị " + String(start) + "-" + String(end) + " / " + String(totalRows) + " dòng";
    },
    setTablePage: function (item, pageIndex) {
      var pageCount = this.buildTablePageCount(item);
      var safePage = Math.max(1, Math.min(pageCount, Number(pageIndex || 1)));
      item.tableConfig = item.tableConfig || {};
      item.tableConfig.PageIndex = safePage;
    },
    setTablePageSize: function (item, pageSize) {
      var safeSize = Number(pageSize || 10);
      if (this.tablePageSizeOptions.indexOf(safeSize) < 0) {
        safeSize = 10;
      }
      item.tableConfig = item.tableConfig || {};
      item.tableConfig.PageSize = safeSize;
      item.tableConfig.PageIndex = 1;
    },
    isNumericTableColumn: function (rows, key) {
      var index = 0;
      var value = "";
      for (index = 0; index < rows.length; index += 1) {
        value = rows[index] && rows[index][key] !== undefined && rows[index][key] !== null ? rows[index][key] : "";
        if (value === "") {
          continue;
        }
        return !isNaN(Number(value));
      }
      return false;
    },
    defaultColumnLabel: function (key) {
      var map = {
        label: "Nhóm dữ liệu",
        value: "Giá trị",
        requestCount: "Số lượng",
        delta: "Xu hướng",
        share: "Tỷ trọng",
        completedRate: "Tỷ lệ hoàn tất",
        slaHours: "SLA (giờ)"
      };
      return map[key] || String(key || "");
    },
    formatTableValue: function (value) {
      if (value === null || value === undefined || value === "") {
        return "-";
      }
      if (typeof value === "number") {
        return this.formatNumber(value);
      }
      if (!isNaN(Number(value)) && String(value).trim() !== "") {
        return this.formatNumber(Number(value));
      }
      return String(value);
    },
    buildWidgetMatrixColumns: function (item) {
      var columns = [
        { key: "label", label: "Nhóm dữ liệu", type: "text" },
        { key: "value", label: "Giá trị", type: "number" },
        { key: "delta", label: "Xu hướng", type: "percent" },
        { key: "share", label: "Tỷ trọng", type: "percent" }
      ];
      (item && item.formulaColumns ? item.formulaColumns : []).forEach(function (column, index) {
        columns.push({
          key: "formula_" + String(index + 1),
          label: column.label || ("Công thức " + String(index + 1)),
          type: "number",
          expression: column.expression || ""
        });
      });
      return columns;
    },
    buildWidgetMatrixRows: function (item) {
      var columns = this.buildWidgetMatrixColumns(item);
      return (item && item.previewRows ? item.previewRows : []).map(function (row, index) {
        var output = {
          sourceIndex: index,
          label: row.label,
          value: Number(row.value || 0),
          delta: Number(row.delta || 0),
          share: Number(row.share || 0)
        };
        columns.forEach(function (column) {
          if (column.expression) {
            output[column.key] = this.evaluateFormula(column.expression, output);
          }
        }.bind(this));
        return output;
      }.bind(this));
    },
    evaluateFormula: function (expression, row) {
      var safeExpression = String(expression || "");
      var scope = row || {};
      Object.keys(scope).forEach(function (key) {
        safeExpression = safeExpression.replace(new RegExp("\\[" + key + "\\]", "g"), String(Number(scope[key] || 0)));
      });
      try {
        return Function("return (" + safeExpression + ");")();
      } catch (error) {
        return 0;
      }
    },
    matrixCellClass: function (column, row) {
      if (column.type !== "percent") {
        return "";
      }
      return Number(row[column.key] || 0) >= 0 ? "wf-text-pos" : "wf-text-neg";
    },
    formatMatrixValue: function (value, type) {
      if (type === "percent") {
        return (Number(value || 0) >= 0 ? "+" : "") + String(Number(value || 0).toFixed(2)) + "%";
      }
      return this.formatTableValue(value);
    },
    formatDate: function (value) {
      if (!value) {
        return "-";
      }
      return String(value);
    },
    formatNumber: function (value) {
      if (value === null || value === undefined || value === "") {
        return "-";
      }
      return Number(value || 0).toLocaleString("vi-VN", { maximumFractionDigits: 2 });
    },
    exportWidgetCsv: function (item) {
      this.downloadTextFile(this.buildWidgetCsvContent(item), "text/csv;charset=utf-8;", this.buildWidgetExportFileName(item, "csv"));
    },
    exportWidgetExcel: function (item) {
      this.downloadTextFile(this.buildWidgetExcelContent(item), "application/vnd.ms-excel;charset=utf-8;", this.buildWidgetExportFileName(item, "xls"));
    },
    saveWidgetAsPng: function (item) {
      var chart = this.chartInstances[String(item && item.reportDefinitionId ? item.reportDefinitionId : this.getChartDomId(item))];
      var link = null;
      if (!chart || !chart.getDataURL) {
        if (typeof showToast !== "undefined") {
          showToast.error("Widget này chưa sẵn sàng để lưu PNG.");
        }
        return;
      }
      link = document.createElement("a");
      link.href = chart.getDataURL({
        type: "png",
        pixelRatio: 2,
        backgroundColor: "#ffffff"
      });
      link.download = this.buildWidgetExportFileName(item, "png");
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    },
    buildWidgetExportFileName: function (item, extension) {
      var name = item && item.name ? item.name : "widget";
      return String(name)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "") + "." + extension;
    },
    buildWidgetCsvContent: function (item) {
      return this.buildDelimitedText(item, ",");
    },
    buildWidgetExcelContent: function (item) {
      return this.buildDelimitedText(item, "\t");
    },
    buildDelimitedText: function (item, separator) {
      var columns = this.isDataTableWidget(item) ? this.buildTableColumns(item) : this.buildWidgetMatrixColumns(item);
      var rows = this.isDataTableWidget(item) ? this.buildTableAllRows(item) : this.buildWidgetMatrixRows(item);
      var lines = [];
      lines.push(columns.map(function (column) {
        return this.escapeDelimitedValue(column.label, separator);
      }.bind(this)).join(separator));
      rows.forEach(function (row) {
        lines.push(columns.map(function (column) {
          var value = this.isDataTableWidget(item)
            ? this.formatTableValue(row[column.key])
            : this.formatMatrixValue(row[column.key], column.type);
          return this.escapeDelimitedValue(value, separator);
        }.bind(this)).join(separator));
      }.bind(this));
      return "\ufeff" + lines.join("\n");
    },
    escapeDelimitedValue: function (value, separator) {
      var text = value === null || value === undefined ? "" : String(value);
      if (text.indexOf("\"") >= 0) {
        text = text.replace(/"/g, "\"\"");
      }
      if (text.indexOf("\n") >= 0 || text.indexOf("\r") >= 0 || text.indexOf(separator) >= 0) {
        return "\"" + text + "\"";
      }
      return text;
    },
    downloadTextFile: function (content, mimeType, fileName) {
      var blob = new Blob([content], { type: mimeType });
      var url = URL.createObjectURL(blob);
      var link = document.createElement("a");
      link.href = url;
      link.download = fileName;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    },
    goList: function () {
      window.location.href = "/wf-report-dashboard-list";
    },
    goDesign: function () {
      window.location.href = "/wf-report-dashboard?id=" + String(this.dashboardId || this.dashboardQueryId || 0);
    },
    toggleFullscreen: function () {
      this.isFullscreen = !this.isFullscreen;
      if (this.isFullscreen && document.documentElement && document.documentElement.requestFullscreen) {
        document.documentElement.requestFullscreen();
        return;
      }
      if (!this.isFullscreen && document.fullscreenElement && document.exitFullscreen) {
        document.exitFullscreen();
      }
    },
    openReportDetail: function (item, label) {
      window.location.href = "/wf-report-detail?id=" + String(item && item.reportDefinitionId ? item.reportDefinitionId : 0) + "&group=" + encodeURIComponent(label || "");
    }
  }
};