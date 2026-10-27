// === inlined: imports/wf-report-builder-file-dataset.js ===
var wfReportBuilderFileDatasetMixin = {
  methods: {
    resolveFileMetricOptions: function (fields) {
      var metrics = [];
      var exists = {};
      var index = 0;
      for (index = 0; index < fields.length; index += 1) {
        if (fields[index].key === "rowCount") {
          metrics.push({ key: "rowCount", label: fields[index].label || "Số dòng" });
          exists.rowCount = true;
        }
      }
      if (!exists.rowCount) {
        metrics.push({ key: "rowCount", label: "Số dòng" });
      }
      for (index = 0; index < fields.length; index += 1) {
        if (fields[index].dataType === "number" && fields[index].key !== "rowCount") {
          metrics.push({ key: fields[index].key, label: fields[index].label });
        }
      }
      return metrics;
    },
    runFileDatasetPreview: function () {
      var self = this;
      self.isPreviewLoading = true;
      self.fileDatasetError = "";
      self.ensureFileDatasetRowsLoaded().then(function (rows) {
        var preview = self.buildFilePreviewRows(rows || []);
        self.previewApiRows = preview.rows;
        self.previewApiSummary = preview.summary;
      }).catch(function (err) {
        self.previewApiRows = [];
        self.previewApiSummary = null;
        self.fileDatasetError = err && err.message ? err.message : "Không đọc được dữ liệu CSV từ FileData.";
      }).finally(function () {
        self.isPreviewLoading = false;
        self.$nextTick(function () {
          self.renderChart();
        });
      });
    },
    ensureFileDatasetRowsLoaded: function () {
      var self = this;
      if (self.fileDatasetRows && self.fileDatasetRows.length > 0) {
        return Promise.resolve(self.fileDatasetRows);
      }
      return self.fetchFileDatasetRows(self.activeDataset.sourceFileId).then(function (rows) {
        self.fileDatasetRows = rows;
        return rows;
      });
    },
    fetchFileDatasetRows: function (fileId) {
      var self = this;
      return apiCallAsync("FileData_GetByID", { FileID: fileId, ID: fileId }).then(function (rows) {
        var row = rows && rows[0] ? rows[0] : null;
        var binary = row && (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || row.FileBinary || "");
        var sourceKind = String(self.activeDataset && self.activeDataset.sourceKind ? self.activeDataset.sourceKind : "").toUpperCase();
        var text = "";
        if (sourceKind === "XLS" || sourceKind === "XLSX") {
          return self.parseExcelBinaryToObjects(binary, self.activeDataset.fields || [], self.activeDataset.sourceMeta || {});
        }
        text = self.decodeFileBinaryToText(binary);
        if (!text) {
          throw new Error("Không đọc được nội dung CSV từ FileData.");
        }
        self.fileDatasetRawText = text;
        return self.parseCsvTextToObjects(text, self.activeDataset.fields || []);
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
          throw new Error("Không đọc được nội dung Excel từ FileData.");
        }
        workbook = XLSX.read(bytes, { type: "array" });
        sheetNames = workbook && workbook.SheetNames ? workbook.SheetNames : [];
        selectedSheetName = String(sourceMeta && sourceMeta.selectedSheetName ? sourceMeta.selectedSheetName : "").trim();
        if (!selectedSheetName || sheetNames.indexOf(selectedSheetName) < 0) {
          selectedSheetName = sheetNames[0] || "";
        }
        if (!selectedSheetName) {
          throw new Error("File Excel chưa có sheet hợp lệ để preview.");
        }
        worksheet = workbook.Sheets[selectedSheetName];
        if (!worksheet) {
          throw new Error("Không tìm thấy sheet Excel đã chọn để preview.");
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
        self.fileDatasetRawText = "[xlsx] " + selectedSheetName;
        return self.buildCsvObjects(columns, self.filterEmptyRawRows(rows.slice(1)));
      });
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
      return headers.map(function (header, index) {
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
      return rawRows.map(function (rawRow) {
        var row = {};
        columns.forEach(function (column, index) {
          row[column.key] = rawRow[index] !== undefined ? rawRow[index] : "";
        });
        return row;
      });
    },
    buildFilePreviewRows: function (rows) {
      var grouped = {};
      var order = [];
      var dimensionKey = this.selectedDimension || (this.activeDataset.dimensions[0] ? this.activeDataset.dimensions[0].key : "");
      var metricKey = this.selectedMetric || "rowCount";
      var index = 0;
      var label = "";
      var metricValue = 0;
      var total = 0;
      var previewRows = [];
      var topLabel = "-";
      var topValue = -1;
      for (index = 0; index < rows.length; index += 1) {
        label = String(rows[index][dimensionKey] || "(Trống)").trim() || "(Trống)";
        if (!grouped[label]) {
          grouped[label] = { label: label, value: 0, sourceCount: 0 };
          order.push(label);
        }
        metricValue = metricKey === "rowCount"
          ? 1
          : this.parseMetricNumber(rows[index][metricKey]);
        grouped[label].value += metricValue;
        grouped[label].sourceCount += 1;
        total += metricValue;
      }
      for (index = 0; index < order.length; index += 1) {
        label = order[index];
        grouped[label].share = total > 0 ? Math.round((grouped[label].value / total) * 1000) / 10 : 0;
        previewRows.push(grouped[label]);
      }
      previewRows.sort(function (a, b) {
        return Number(b.value || 0) - Number(a.value || 0);
      });
      for (index = 0; index < previewRows.length; index += 1) {
        if (index === 0) {
          previewRows[index].delta = 0;
        } else if (previewRows[index - 1].value > 0) {
          previewRows[index].delta = Math.round(((previewRows[index].value - previewRows[index - 1].value) / previewRows[index - 1].value) * 100);
        } else {
          previewRows[index].delta = 0;
        }
        previewRows[index][metricKey] = previewRows[index].value;
        if (previewRows[index].value > topValue) {
          topValue = previewRows[index].value;
          topLabel = previewRows[index].label;
        }
      }
      return {
        rows: previewRows.slice(0, 20),
        summary: {
          PreviewRowCount: previewRows.length,
          TotalValue: total,
          TopLabel: topLabel
        }
      };
    },
    parseMetricNumber: function (value) {
      var raw = String(value === undefined || value === null ? "" : value).trim();
      if (!raw) {
        return 0;
      }
      raw = raw.replace(/\./g, "").replace(/,/g, ".");
      raw = raw.replace(/[^0-9.-]/g, "");
      return Number(raw || 0);
    }
  }
};
if (typeof window !== "undefined") {
  window.__WF_REPORT_BUILDER_FILE_DATASET_MIXIN__ = wfReportBuilderFileDatasetMixin;
}
// === inlined: imports/wf-report-builder-matrix.js ===
var wfReportBuilderMatrixMixin = {
  computed: {
    isDataTableChart: function () {
      return this.selectedChartType === "table";
    },
    isMatrixChart: function () {
      return this.selectedChartType === "matrix";
    },
    isTableLikeChart: function () {
      return this.isDataTableChart || this.isMatrixChart;
    },
    availableTableColumns: function () {
      return this.buildTableColumnCatalog();
    },
    configuredTableColumns: function () {
      var self = this;
      var selected = Array.isArray(this.tableVisibleColumns) && this.tableVisibleColumns.length
        ? this.tableVisibleColumns
        : this.defaultTableVisibleColumns();
      return selected.map(function (key) {
        var match = (self.availableTableColumns || []).find(function (column) {
          return column.key === key;
        });
        if (!match) {
          return {
            key: key,
            label: self.resolveTableColumnLabel(key),
            rawLabel: key,
            type: "text",
            filterKind: "text",
            width: self.resolveTableColumnWidth(key),
            options: []
          };
        }
        return {
          key: match.key,
          label: self.resolveTableColumnLabel(match.key),
          rawLabel: match.rawLabel || match.label || match.key,
          type: match.type,
          filterKind: match.filterKind || "text",
          width: self.resolveTableColumnWidth(match.key),
          options: match.options || []
        };
      });
    },
    tableSortOptions: function () {
      return (this.availableTableColumns || []).map(function (column) {
        return {
          title: column.label,
          value: column.key
        };
      });
    },
    previewTableColumns: function () {
      return this.configuredTableColumns;
    },
    previewTableRows: function () {
      var self = this;
      var rows = this.resolveTableSourceRows();
      rows = rows.filter(function (row) {
        return self.matchesTableFilters(row);
      });
      rows.sort(function (a, b) {
        return self.compareTableRows(a, b);
      });
      return rows.slice(0, self.resolveTableTopN());
    },
    previewTableFooter: function () {
      var footer = {};
      var rows = this.previewTableRows || [];
      var columns = this.previewTableColumns || [];
      var index = 0;
      var key = "";
      for (index = 0; index < columns.length; index += 1) {
        key = columns[index].key;
        if (index === 0) {
          footer[key] = "Tổng: " + rows.length + " dòng";
          continue;
        }
        if (columns[index].type === "number") {
          footer[key] = rows.reduce(function (sum, row) {
            return sum + Number(row && row[key] !== undefined ? row[key] : 0);
          }, 0);
        } else {
          footer[key] = "";
        }
      }
      return footer;
    },
    previewMatrixColumns: function () {
      var columns = [
        { key: "label", label: this.selectedDimensionLabel || "Nhóm dữ liệu", type: "text" },
        { key: "value", label: this.selectedMetricLabel || "Giá trị", type: "number" }
      ];
      if (this.selectedFieldKeys.indexOf("delta") >= 0) {
        columns.push({ key: "delta", label: "Biến động %", type: "number" });
      }
      if (this.selectedFieldKeys.indexOf("share") >= 0) {
        columns.push({ key: "share", label: "Tỷ trọng %", type: "number" });
      }
      return columns.concat((this.formulaColumns || []).filter(function (item) {
        return String(item.label || "").trim() && String(item.expression || "").trim();
      }).map(function (item) {
        return {
          key: item.key,
          label: item.label,
          type: "formula",
          expression: item.expression
        };
      }));
    },
    previewMatrixRows: function () {
      var self = this;
      return (this.previewRows || []).map(function (row, index) {
        var output = {
          label: row.label,
          value: Number(self.getMetricValue(row) || 0),
          delta: Number(row.delta || 0),
          share: Number(row.share || 0),
          sourceIndex: index
        };
        (self.formulaColumns || []).forEach(function (formula) {
          if (!formula || !formula.key) return;
          output[formula.key] = self.evaluateFormulaExpression(formula.expression, output, row);
        });
        return output;
      });
    }
  },
  methods: {
    buildTableColumnCatalog: function () {
      if (this.tableDetailRows && this.tableDetailRows.length > 0) {
        return this.buildTableColumnsFromDetailRows(this.tableDetailRows[0]);
      }
      var datasetFieldColumns = this.buildTableColumnsFromDatasetFields();
      if (datasetFieldColumns.length > 0) {
        return datasetFieldColumns;
      }
      var metricLabel = this.selectedMetricLabel || "Giá trị";
      var fallbackRequestLabel = metricLabel.indexOf("giao dịch") >= 0 ? "Số giao dịch" : "Số yêu cầu";
      var completedMetric = this.findDatasetMetricLabel("completedRate", "Tỷ lệ hoàn tất");
      var slaMetric = this.findDatasetMetricLabel("slaHours", "Giờ SLA trung bình");
      return [
        { key: "label", label: this.selectedDimensionLabel || "Nhóm dữ liệu", type: "text" },
        { key: "value", label: metricLabel, type: "number" },
        { key: "requestCount", label: this.findDatasetMetricLabel("requestCount", fallbackRequestLabel), type: "number" },
        { key: "completedRate", label: completedMetric, type: "number" },
        { key: "slaHours", label: slaMetric, type: "number" },
        { key: "delta", label: "Biến động %", type: "number" },
        { key: "share", label: "Tỷ trọng %", type: "number" }
      ];
    },
    buildTableColumnsFromDatasetFields: function () {
      var fields = (this.activeDataset && this.activeDataset.fields) || [];
      return fields.map(function (field) {
        var label = field.label || field.key;
        return {
          key: field.key,
          label: label,
          rawLabel: label,
          type: this.resolveTableColumnType(field.dataType),
          filterKind: this.resolveTableFilterKind(field.key, label, this.resolveTableColumnType(field.dataType)),
          options: this.buildTableStatusOptions(field.key)
        };
      }, this);
    },
    buildTableColumnsFromDetailRows: function (row) {
      return Object.keys(row || {}).map(function (key) {
        var label = this.resolveDetailColumnLabel(key);
        var type = this.inferTableColumnTypeFromValue(row ? row[key] : "");
        return {
          key: key,
          label: label,
          rawLabel: key,
          type: type,
          filterKind: this.resolveTableFilterKind(key, label, type),
          options: this.buildTableStatusOptions(key)
        };
      }, this);
    },
    findDatasetMetricLabel: function (key, fallback) {
      var found = ((this.activeDataset && this.activeDataset.metrics) || []).find(function (metric) {
        return metric.key === key;
      });
      return found && found.label ? found.label : fallback;
    },
    defaultTableVisibleColumns: function () {
      var available = (this.availableTableColumns || []).map(function (column) {
        return column.key;
      });
      if (available.length > 0) {
        return available.slice(0, Math.min(4, available.length));
      }
      var columns = ["label", "value"];
      if (this.selectedFieldKeys.indexOf("delta") >= 0) {
        columns.push("delta");
      }
      return columns;
    },
    ensureTableConfigDefaults: function () {
      var availableKeys = (this.availableTableColumns || []).map(function (column) {
        return column.key;
      });
      if (Array.isArray(this.tableVisibleColumns) && availableKeys.length > 0) {
        this.tableVisibleColumns = this.tableVisibleColumns.filter(function (key) {
          return availableKeys.indexOf(key) >= 0;
        });
      }
      if (!Array.isArray(this.tableVisibleColumns) || !this.tableVisibleColumns.length) {
        this.tableVisibleColumns = this.defaultTableVisibleColumns();
      }
      if (!this.tableSortBy || (availableKeys.length > 0 && availableKeys.indexOf(this.tableSortBy) < 0)) {
        this.tableSortBy = this.tableVisibleColumns[0] || "value";
      }
      if (!this.tableSortDir) {
        this.tableSortDir = "desc";
      }
      if (!this.tableFilters) {
        this.tableFilters = {
          keyword: "",
          minValue: "",
          deltaMode: "all"
        };
      }
      if (!this.tableTopN) {
        this.tableTopN = 20;
      }
      if (!this.tableColumnLabels) {
        this.tableColumnLabels = {};
      } else if (availableKeys.length > 0) {
        this.tableColumnLabels = Object.keys(this.tableColumnLabels).reduce(function (output, key) {
          if (availableKeys.indexOf(key) >= 0) {
            output[key] = this.tableColumnLabels[key];
          }
          return output;
        }.bind(this), {});
      }
      if (!this.tableColumnFilters) {
        this.tableColumnFilters = {};
      } else if (availableKeys.length > 0) {
        this.tableColumnFilters = Object.keys(this.tableColumnFilters).reduce(function (output, key) {
          if (availableKeys.indexOf(key) >= 0) {
            output[key] = this.tableColumnFilters[key];
          }
          return output;
        }.bind(this), {});
      }
      if (!this.tableColumnWidths) {
        this.tableColumnWidths = {};
      } else if (availableKeys.length > 0) {
        this.tableColumnWidths = Object.keys(this.tableColumnWidths).reduce(function (output, key) {
          if (availableKeys.indexOf(key) >= 0) {
            output[key] = this.tableColumnWidths[key];
          }
          return output;
        }.bind(this), {});
      }
    },
    resolveTableSourceRows: function () {
      var self = this;
      if (this.activeDataset && this.activeDataset.datasetType === "FILE" && Array.isArray(this.fileDatasetRows) && this.fileDatasetRows.length > 0) {
        return this.fileDatasetRows.map(function (row, index) {
          return self.normalizeTableRow(row, index);
        });
      }
      if (Array.isArray(this.tableDetailRows) && this.tableDetailRows.length > 0) {
        return this.tableDetailRows.map(function (row, index) {
          return self.normalizeTableRow(row, index);
        });
      }
      return (this.previewRows || []).map(function (row, index) {
        return {
          label: row.label,
          value: Number(self.getMetricValue(row) || 0),
          requestCount: Number(row.requestCount || 0),
          completedRate: Number(row.completedRate || 0),
          slaHours: Number(row.slaHours || 0),
          delta: Number(row.delta || 0),
          share: Number(row.share || 0),
          sourceIndex: index
        };
      });
    },
    normalizeTableRow: function (row, index) {
      var output = {};
      Object.keys(row || {}).forEach(function (key) {
        output[key] = row[key];
      });
      output.sourceIndex = index;
      return output;
    },
    resolveTableColumnType: function (dataType) {
      var normalized = String(dataType || "").toLowerCase();
      if (normalized === "number") {
        return "number";
      }
      if (normalized === "date" || normalized === "datetime") {
        return "date";
      }
      return "text";
    },
    inferTableColumnTypeFromValue: function (value) {
      if (typeof value === "number") {
        return "number";
      }
      if (value === null || value === undefined || value === "") {
        return "text";
      }
      if (this.looksLikeDateValue(value)) {
        return "date";
      }
      return isNaN(Number(value)) ? "text" : "number";
    },
    looksLikeDateValue: function (value) {
      var text = String(value || "").trim();
      var time = 0;
      if (!text || text.length < 8) {
        return false;
      }
      if (text.indexOf("-") < 0 && text.indexOf("/") < 0) {
        return false;
      }
      time = Date.parse(text);
      return !isNaN(time);
    },
    resolveTableFilterKind: function (key, label, type) {
      var normalizedKey = String(key || "").toLowerCase();
      var normalizedLabel = String(label || "").toLowerCase();
      if (type === "number") {
        return "number";
      }
      if (type === "date") {
        return "date";
      }
      if (
        normalizedKey.indexOf("status") >= 0 ||
        normalizedKey.indexOf("result") >= 0 ||
        normalizedLabel.indexOf("trạng thái") >= 0 ||
        normalizedLabel.indexOf("kết quả") >= 0
      ) {
        return "status";
      }
      return "text";
    },
    buildTableStatusOptions: function (key) {
      var seen = {};
      var options = [];
      this.resolveTableSourceRows().forEach(function (row) {
        var value = String(row && row[key] !== undefined && row[key] !== null ? row[key] : "").trim();
        if (!value || seen[value]) {
          return;
        }
        seen[value] = true;
        options.push(value);
      });
      return options.slice(0, 12);
    },
    resolveTableColumnWidth: function (key) {
      var value = this.tableColumnWidths && this.tableColumnWidths[key] !== undefined ? this.tableColumnWidths[key] : "";
      var width = Number(value || 0);
      if (!width || width < 90) {
        return 180;
      }
      return width;
    },
    resolveTableColumnLabel: function (key) {
      var custom = this.tableColumnLabels && this.tableColumnLabels[key];
      var match = (this.availableTableColumns || []).find(function (column) {
        return column.key === key;
      });
      return String(custom || (match && match.label) || this.resolveDetailColumnLabel(key) || key || "").trim();
    },
    isTableColumnVisible: function (key) {
      return (this.tableVisibleColumns || []).indexOf(key) >= 0;
    },
    toggleTableColumn: function (key) {
      var next = Array.isArray(this.tableVisibleColumns) ? this.tableVisibleColumns.slice() : [];
      var idx = next.indexOf(key);
      if (idx >= 0) {
        if (next.length <= 1) {
          return;
        }
        next.splice(idx, 1);
      } else {
        next.push(key);
      }
      this.tableVisibleColumns = next;
    },
    moveTableColumnUp: function (key) {
      this.moveTableColumn(key, -1);
    },
    moveTableColumnDown: function (key) {
      this.moveTableColumn(key, 1);
    },
    moveTableColumn: function (key, direction) {
      var next = Array.isArray(this.tableVisibleColumns) ? this.tableVisibleColumns.slice() : [];
      var idx = next.indexOf(key);
      var target = idx + direction;
      if (idx < 0 || target < 0 || target >= next.length) {
        return;
      }
      next.splice(idx, 1);
      next.splice(target, 0, key);
      this.tableVisibleColumns = next;
    },
    setTableColumnWidth: function (payload) {
      var width = 0;
      if (!payload || !payload.key) {
        return;
      }
      width = Number(payload.value || 0);
      this.tableColumnWidths[payload.key] = width > 0 ? Math.max(90, width) : "";
      this.tableColumnWidths = Object.assign({}, this.tableColumnWidths);
    },
    resolveTableTopN: function () {
      var topN = Number(this.tableTopN || 0);
      if (!topN || topN < 0) {
        return 9999;
      }
      return topN;
    },
    matchesTableFilters: function (row) {
      var filters = this.tableFilters || {};
      var keyword = String(filters.keyword || "").trim().toLowerCase();
      var minValue = filters.minValue === "" || filters.minValue === null || filters.minValue === undefined
        ? null
        : Number(filters.minValue);
      var deltaMode = String(filters.deltaMode || "all");
      var sortBy = this.tableSortBy || "value";
      var sortValue = row && row[sortBy] !== undefined ? row[sortBy] : (row ? row.value : "");
      if (keyword && !this.rowContainsKeyword(row, keyword)) {
        return false;
      }
      if (!this.matchesTableColumnFilters(row)) {
        return false;
      }
      if (minValue !== null && !isNaN(minValue) && !isNaN(Number(sortValue)) && Number(sortValue || 0) < minValue) {
        return false;
      }
      if (deltaMode === "positive" && row.delta !== undefined && Number(row.delta || 0) <= 0) {
        return false;
      }
      if (deltaMode === "negative" && row.delta !== undefined && Number(row.delta || 0) >= 0) {
        return false;
      }
      return true;
    },
    matchesTableColumnFilters: function (row) {
      var filters = this.tableColumnFilters || {};
      return Object.keys(filters).every(function (key) {
        return this.matchesSingleTableColumnFilter(key, filters[key], row);
      }, this);
    },
    matchesSingleTableColumnFilter: function (key, filterValue, row) {
      var raw = row && row[key] !== undefined && row[key] !== null ? row[key] : "";
      var column = this.getAvailableTableColumn(key);
      var filterKind = column && column.filterKind ? column.filterKind : "text";
      var selected = null;
      var min = null;
      var max = null;
      var valueDate = null;
      if (!filterValue || (typeof filterValue === "string" && !String(filterValue).trim())) {
        return true;
      }
      if (filterKind === "number") {
        min = filterValue.min === "" || filterValue.min === undefined || filterValue.min === null ? null : Number(filterValue.min);
        max = filterValue.max === "" || filterValue.max === undefined || filterValue.max === null ? null : Number(filterValue.max);
        if (min !== null && !isNaN(min) && Number(raw || 0) < min) {
          return false;
        }
        if (max !== null && !isNaN(max) && Number(raw || 0) > max) {
          return false;
        }
        return true;
      }
      if (filterKind === "date") {
        valueDate = this.normalizeDateOnly(raw);
        if (!valueDate) {
          return false;
        }
        if (filterValue.from && valueDate < filterValue.from) {
          return false;
        }
        if (filterValue.to && valueDate > filterValue.to) {
          return false;
        }
        return true;
      }
      if (filterKind === "status") {
        selected = Array.isArray(filterValue.selected) ? filterValue.selected : [];
        if (!selected.length) {
          return true;
        }
        return selected.indexOf(String(raw || "").trim()) >= 0;
      }
      return String(raw).toLowerCase().indexOf(String(filterValue || "").trim().toLowerCase()) >= 0;
    },
    normalizeDateOnly: function (value) {
      var date = new Date(value);
      if (isNaN(date.getTime())) {
        return "";
      }
      return date.toISOString().slice(0, 10);
    },
    getAvailableTableColumn: function (key) {
      return (this.availableTableColumns || []).find(function (column) {
        return column.key === key;
      });
    },
    rowContainsKeyword: function (row, keyword) {
      return Object.keys(row || {}).some(function (key) {
        if (key === "sourceIndex") {
          return false;
        }
        return String(row[key] === undefined || row[key] === null ? "" : row[key]).toLowerCase().indexOf(keyword) >= 0;
      });
    },
    compareTableRows: function (a, b) {
      var sortBy = this.tableSortBy || "value";
      var sortDir = this.tableSortDir === "asc" ? 1 : -1;
      var left = a && a[sortBy] !== undefined ? a[sortBy] : "";
      var right = b && b[sortBy] !== undefined ? b[sortBy] : "";
      if (typeof left === "string" || typeof right === "string") {
        return String(left || "").localeCompare(String(right || ""), "vi") * sortDir;
      }
      return (Number(left || 0) - Number(right || 0)) * sortDir;
    },
    addFormulaColumn: function () {
      this.formulaSeed = Number(this.formulaSeed || 0) + 1;
      this.formulaColumns.push({
        key: "formula_" + this.formulaSeed,
        label: "Cột công thức " + this.formulaSeed,
        expression: "[value]"
      });
    },
    removeFormulaColumn: function (key) {
      this.formulaColumns = (this.formulaColumns || []).filter(function (item) {
        return item.key !== key;
      });
    },
    applyFormulaPreset: function (preset) {
      if (!preset) {
        return;
      }
      this.formulaSeed = Number(this.formulaSeed || 0) + 1;
      this.formulaColumns.push({
        key: "formula_" + this.formulaSeed,
        label: preset.label,
        expression: preset.expression
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
      if (type === "date") {
        return this.formatTableDateValue(value);
      }
      if (type === "text") {
        return String(value);
      }
      return Number(value || 0).toLocaleString("vi-VN", {
        maximumFractionDigits: 2
      });
    },
    formatTableDateValue: function (value) {
      var date = new Date(value);
      if (isNaN(date.getTime())) {
        return String(value);
      }
      return date.toLocaleString("vi-VN");
    },
    resolveDetailColumnLabel: function (key) {
      var fieldMatch = ((this.activeDataset && this.activeDataset.fields) || []).find(function (field) {
        return field.key === key;
      });
      var map = {
        GroupLabel: "Nhóm dữ liệu",
        MetricValue: "Giá trị",
        RequestCount: "Số lượng",
        CompletedRate: "Tỷ lệ hoàn tất",
        SlaHours: "SLA / Phản hồi",
        InstanceID: "Instance ID",
        InstanceName: "Tên hồ sơ",
        StatusLabel: "Trạng thái",
        CategoryName: "Đơn vị",
        CreateUser: "Người tạo",
        CreateTime: "Thời gian tạo",
        UpdateTime: "Cập nhật cuối",
        DurationHours: "Thời lượng (giờ)",
        ExecutionID: "Execution ID",
        SignerExecID: "SignerExec ID",
        ResolvedPersonName: "Người ký",
        SignMethod: "Phương thức ký",
        SignerStatus: "Trạng thái signer",
        ResultLabel: "Kết quả",
        GatewayLabel: "Gateway",
        EventTime: "Thời điểm",
        SignedDate: "Ký lúc",
        ResponseSeconds: "Thời gian phản hồi (giây)",
        InstanceStatus: "Trạng thái hồ sơ"
      };
      return (fieldMatch && fieldMatch.label) || map[key] || key;
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
    }
  }
};
if (typeof window !== "undefined") {
  window.__WF_REPORT_BUILDER_MATRIX_MIXIN__ = wfReportBuilderMatrixMixin;
}
// === original script.js ===
function loadWfReportBuilderImportSync(fileName) {
  var scriptUrl = "";
  var xhr = null;
  if (typeof window === "undefined" || typeof document === "undefined" || typeof XMLHttpRequest === "undefined") return false;
  if (window.__WF_REPORT_BUILDER_IMPORT_CACHE__ && window.__WF_REPORT_BUILDER_IMPORT_CACHE__[fileName]) return true;
  try {
    if (document.currentScript && document.currentScript.src) scriptUrl = String(document.currentScript.src || "");
    if (!scriptUrl) return false;
    scriptUrl = scriptUrl.replace(/\/script\.js(\?.*)?$/i, "/imports/" + String(fileName || "").replace(/^\/+/, ""));
    if (!scriptUrl || /\/script\.js(\?.*)?$/i.test(scriptUrl)) return false;
    xhr = new XMLHttpRequest();
    xhr.open("GET", scriptUrl, false);
    xhr.send(null);
    if (!((xhr.status >= 200 && xhr.status < 300) || xhr.status === 0)) return false;
    window.__WF_REPORT_BUILDER_IMPORT_CACHE__ = window.__WF_REPORT_BUILDER_IMPORT_CACHE__ || {};
    (0, eval)(String(xhr.responseText || ""));
    window.__WF_REPORT_BUILDER_IMPORT_CACHE__[fileName] = true;
    return true;
  } catch (e) {
    return false;
  }
}
if (typeof window !== "undefined" && !window.__WF_REPORT_BUILDER_FILE_DATASET_MIXIN__) {
  loadWfReportBuilderImportSync("wf-report-builder-file-dataset.js");
}
if (typeof window !== "undefined" && !window.__WF_REPORT_BUILDER_MATRIX_MIXIN__) {
  loadWfReportBuilderImportSync("wf-report-builder-matrix.js");
}