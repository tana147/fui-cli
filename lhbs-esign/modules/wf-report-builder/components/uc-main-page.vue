<template>
	<uc-wf-shell>
    <div class="wf-page-header">
      <div>
        <h1>Thiết kế widget</h1>
        <p>Tạo từng widget trước: chọn nguồn dữ liệu, cách nhóm dữ liệu, metric và loại chart rồi xem trước ngay trên FUI.</p>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="runPreview">
          <v-icon start>mdi-refresh</v-icon>
          Xem trước
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="goToDashboard">
          <v-icon start>mdi-view-dashboard-outline</v-icon>
          Mở bảng điều khiển
        </v-btn>
      </div>
    </div>
    <div class="wf-report-builder-layout">
      <div class="wf-report-panel">
        <div class="wf-report-panel__head">
          <h3>Thiết kế từng vùng hiển thị</h3>
          <v-chip size="small" color="primary" variant="tonal">MVP</v-chip>
        </div>
        <div class="wf-report-section">
          <div class="wf-report-section__title">Loại widget</div>
          <div class="wf-report-section__desc">Chọn vùng hiển thị này sẽ là KPI, biểu đồ, bảng thường, ranking hoặc matrix có cột công thức.</div>
          <div class="wf-report-form-grid">
            <v-text-field
              v-model="reportName"
              label="Tên widget"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-textarea
              v-model="reportDescription"
              label="Mô tả ngắn"
              variant="outlined"
              density="compact"
              hide-details="auto"
              rows="2"
            />
            <v-select
              v-model="selectedChartType"
              :items="chartTypeOptions"
              label="Loại hiển thị"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </div>
        </div>
        <div class="wf-report-section">
          <div class="wf-report-section__title">Nguồn dữ liệu</div>
          <div class="wf-report-section__desc">Chọn dataset an toàn mà widget này được phép dùng.</div>
          <div class="wf-report-form-grid">
            <v-select
              v-model="selectedDatasetCode"
              :items="datasetOptions"
              item-title="label"
              item-value="value"
              label="Nguồn dữ liệu"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-select
              v-model="selectedRange"
              :items="rangeOptions"
              label="Khoảng thời gian"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-select
              v-model="selectedStatus"
              :items="statusOptions"
              label="Trạng thái dữ liệu"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </div>
          <div class="wf-audit-sub mt-2" v-if="activeDataset.datasetType === 'FILE'">
            CSV và Excel đều preview/chart được ngay trong builder. Với XLS/XLSX, hệ thống sẽ đọc sheet đã chọn lúc bootstrap dataset.
          </div>
          <div class="wf-audit-sub mt-2" v-else-if="activeDataset.sourceKind === 'API'">
            Dataset API/store sẽ chạy preview thật qua store nguồn đã khai báo trong registry dataset hoặc qua HTTP contract đã lưu ở dataset.
          </div>
        </div>
        <div class="wf-report-section">
          <div class="wf-report-section__title">Cách nhóm dữ liệu</div>
          <div class="wf-report-section__desc">Xác định widget sẽ chia dữ liệu theo tháng, trạng thái, đơn vị hay nhóm khác.</div>
          <div class="wf-report-form-grid">
            <v-select
              v-model="selectedDimension"
              :items="dimensionOptions"
              label="Nhóm dữ liệu theo"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </div>
        </div>
        <div class="wf-report-section">
          <div class="wf-report-section__title">Chỉ số hiển thị</div>
          <div class="wf-report-section__desc">Chọn chỉ số chính của vùng này và các field phụ trợ sẽ hiện trong preview.</div>
          <div class="wf-report-form-grid">
            <v-select
              v-model="selectedMetric"
              :items="metricOptions"
              label="Chỉ số chính"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </div>
          <div class="wf-report-chip-list">
            <div
              v-for="field in availableFields"
              :key="field.key"
              class="wf-report-chip"
              :class="{ active: isFieldSelected(field.key) }"
              @click="toggleField(field.key)"
            >
              <v-icon size="14">{{ isFieldSelected(field.key) ? 'mdi-checkbox-marked-circle-outline' : 'mdi-checkbox-blank-circle-outline' }}</v-icon>
              <span>{{ field.label }}</span>
            </div>
          </div>
        </div>
        <uc-report-table-config
          v-if="isDataTableChart"
          :available-columns="availableTableColumns"
          :configured-columns="configuredTableColumns"
          :column-labels="tableColumnLabels"
          :column-filters="tableColumnFilters"
          :column-widths="tableColumnWidths"
          :table-filters="tableFilters"
          :table-sort-by="tableSortBy"
          :table-sort-dir="tableSortDir"
          :table-top-n="tableTopN"
          :freeze-first-column="tableFreezeFirstColumn"
          :table-sort-options="tableSortOptions"
          :table-sort-direction-options="tableSortDirectionOptions"
          :table-delta-mode-options="tableDeltaModeOptions"
          :visible-column-keys="tableVisibleColumns"
          @toggle-column="toggleTableColumn"
          @move-column-up="moveTableColumnUp"
          @move-column-down="moveTableColumnDown"
          @update:freeze-first-column="tableFreezeFirstColumn = $event"
          @update:table-filters="tableFilters = $event"
          @update:table-sort-by="tableSortBy = $event"
          @update:table-sort-dir="tableSortDir = $event"
          @update:table-top-n="tableTopN = $event"
          @update:column-label="updateTableColumnLabel"
          @update:column-filter="updateTableColumnFilter"
          @update:column-width="setTableColumnWidth"
        />
        <div class="wf-report-section" v-if="isMatrixChart">
          <div class="wf-report-section__title">Cột công thức</div>
          <div class="wf-report-section__desc">Matrix mode giữ hướng pivot/report tổng hợp. Bạn có thể tham chiếu `[value]`, `[delta]`, `[share]`, `[requestCount]` trong biểu thức.</div>
          <div class="wf-report-chip-list">
            <div class="wf-report-chip" @click="applyFormulaPreset({ label: 'Giá trị x 100', expression: '[value] * 100' })">
              <v-icon size="14">mdi-lightning-bolt-outline</v-icon>
              <span>Giá trị x 100</span>
            </div>
            <div class="wf-report-chip" @click="applyFormulaPreset({ label: 'Tỷ trọng x 2', expression: '[share] * 2' })">
              <v-icon size="14">mdi-lightning-bolt-outline</v-icon>
              <span>Tỷ trọng x 2</span>
            </div>
            <div class="wf-report-chip" @click="applyFormulaPreset({ label: 'Giá trị / 1000', expression: '[value] / 1000' })">
              <v-icon size="14">mdi-lightning-bolt-outline</v-icon>
              <span>Giá trị / 1000</span>
            </div>
          </div>
          <div class="wf-report-formula-list" v-if="formulaColumns.length > 0">
            <div v-for="formula in formulaColumns" :key="formula.key" class="wf-report-formula-row">
              <v-text-field
                v-model="formula.label"
                label="Tên cột công thức"
                variant="outlined"
                density="compact"
                hide-details="auto"
              />
              <v-text-field
                v-model="formula.expression"
                label="Công thức"
                variant="outlined"
                density="compact"
                hide-details="auto"
              />
              <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="removeFormulaColumn(formula.key)">
                <v-icon start size="14">mdi-delete-outline</v-icon>
                Xóa
              </v-btn>
            </div>
          </div>
          <div class="wf-report-panel__actions">
            <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="addFormulaColumn">
              <v-icon start size="14">mdi-plus</v-icon>
              Thêm cột công thức
            </v-btn>
          </div>
        </div>
        <div class="wf-report-section">
          <div class="wf-report-section__title">Thêm vào bảng điều khiển</div>
          <div class="wf-report-section__desc">Xem nhanh widget này sẽ mang gì lên dashboard trước khi lưu hoặc ghim.</div>
          <div class="wf-report-insight-list">
            <div class="wf-report-insight-item">
              <strong>{{ previewSummary.kpiValue }}</strong>
              <span>{{ previewSummary.kpiLabel }}</span>
            </div>
            <div class="wf-report-insight-item">
              <strong>{{ previewSummary.bestLabel }}</strong>
              <span>Nhóm tốt nhất</span>
            </div>
            <div class="wf-report-insight-item">
              <strong>{{ selectedFieldKeys.length }}</strong>
              <span>Field đang chọn</span>
            </div>
          </div>
        </div>
        <div class="wf-report-panel__actions">
          <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSaving" @click="saveReport">
            <v-icon start>mdi-content-save-outline</v-icon>
            Lưu widget
          </v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" @click="goToDashboard">
            <v-icon start>mdi-pin-outline</v-icon>
            Thêm vào bảng điều khiển
          </v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" @click="openMyReports">
            <v-icon start>mdi-file-chart-outline</v-icon>
            Thư viện widget
          </v-btn>
        </div>
      </div>
      <div class="wf-report-preview">
        <div class="wf-report-preview__head">
          <div>
            <h3>{{ previewTitle }}</h3>
            <p>{{ activeDataset.description }}</p>
          </div>
          <v-chip size="small" color="primary" variant="tonal">{{ selectedChartTypeLabel }}</v-chip>
        </div>
        <div class="wf-stat-strip wf-stat-strip--4">
          <div class="wf-stat-pill">
            <div class="wf-stat-icon wf-stat-icon--all"><v-icon>mdi-database-outline</v-icon></div>
            <div><div class="wf-stat-val">{{ previewRecordCount }}</div><div class="wf-stat-lbl">Nhóm dữ liệu preview</div></div>
          </div>
          <div class="wf-stat-pill">
            <div class="wf-stat-icon wf-stat-icon--running"><v-icon>mdi-tune-variant</v-icon></div>
            <div><div class="wf-stat-val">{{ selectedDimensionLabel }}</div><div class="wf-stat-lbl">Đang group theo</div></div>
          </div>
          <div class="wf-stat-pill">
            <div class="wf-stat-icon wf-stat-icon--waiting"><v-icon>mdi-chart-bar</v-icon></div>
            <div><div class="wf-stat-val">{{ selectedMetricLabel }}</div><div class="wf-stat-lbl">Metric chính</div></div>
          </div>
          <div class="wf-stat-pill">
            <div class="wf-stat-icon wf-stat-icon--completed"><v-icon>mdi-clock-outline</v-icon></div>
            <div><div class="wf-stat-val">{{ selectedRange }}</div><div class="wf-stat-lbl">Khoảng lọc</div></div>
          </div>
        </div>
        <div class="wf-report-chart-card" v-if="isKpiChart">
          <div class="wf-report-kpi-stage">
            <div class="wf-report-kpi-stage__hero">
              <span class="wf-report-kpi-stage__label">{{ selectedMetricLabel }}</span>
              <strong>{{ previewSummary.kpiValue }}</strong>
              <small>{{ activeDataset.name }}</small>
            </div>
            <div class="wf-report-kpi-stage__meta">
              <div class="wf-report-kpi-stage__meta-item">
                <span>Nhóm tốt nhất</span>
                <strong>{{ previewSummary.bestLabel }}</strong>
              </div>
              <div class="wf-report-kpi-stage__meta-item">
                <span>Số nhóm preview</span>
                <strong>{{ previewRecordCount }}</strong>
              </div>
            </div>
          </div>
        </div>
        <div class="wf-report-chart-card" v-else-if="isProgressListChart">
          <div class="wf-report-progress-list">
            <div v-for="row in previewRows" :key="row.label" class="wf-report-progress-item" @click="openDrillDown(row.label)">
              <div class="wf-report-progress-item__head">
                <strong>{{ row.label }}</strong>
                <span>{{ formatNumber(getMetricValue(row)) }}</span>
              </div>
              <div class="wf-report-progress-item__track">
                <div class="wf-report-progress-item__bar" :style="{ width: progressWidth(row) }"></div>
              </div>
              <div class="wf-report-progress-item__meta">
                <span>{{ row.share }}% tỷ trọng</span>
                <span :class="row.delta >= 0 ? 'wf-text-pos' : 'wf-text-neg'">{{ row.delta >= 0 ? '+' : '' }}{{ row.delta }}%</span>
              </div>
            </div>
          </div>
        </div>
        <uc-report-table-preview
          v-else-if="isDataTableChart"
          :is-preview-supported="isPreviewSupported"
          :preview-columns="previewTableColumns"
          :preview-rows="previewTableRows"
          :footer-row="previewTableFooter"
          :freeze-first-column="tableFreezeFirstColumn"
          :preview-disabled-message="previewDisabledMessage"
          :format-value="formatMatrixValue"
          :cell-class="matrixCellClass"
          @row-click="onTableRowClick"
        />
        <div class="wf-report-table-card" v-else-if="isMatrixChart">
          <div v-if="isPreviewSupported">
            <div class="wf-tcard-toolbar">
              <h3>Matrix preview</h3>
              <div class="wf-audit-sub">Matrix giữ logic row dimension + metric columns + formula columns cho báo cáo tổng hợp.</div>
            </div>
            <div class="wf-report-matrix-wrap">
              <table class="wf-report-matrix-table">
                <thead>
                  <tr>
                    <th v-for="column in previewMatrixColumns" :key="column.key">{{ column.label }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="row in previewMatrixRows" :key="row.label">
                    <td
                      v-for="column in previewMatrixColumns"
                      :key="column.key"
                      :class="matrixCellClass(column, row)"
                    >
                      {{ formatMatrixValue(row[column.key], column.type) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <div v-else class="wf-report-empty-state">
            <v-icon size="24">mdi-table-large</v-icon>
            <strong>Chưa có dữ liệu để dựng matrix</strong>
            <span>{{ previewDisabledMessage }}</span>
          </div>
        </div>
        <div class="wf-report-chart-card" v-else>
          <div v-if="isPreviewSupported" ref="chartEl" class="wf-report-chart"></div>
          <div v-else class="wf-report-empty-state">
            <v-icon size="24">mdi-file-chart-outline</v-icon>
            <strong>Chưa có dữ liệu preview để dựng chart</strong>
            <span>{{ previewDisabledMessage }}</span>
          </div>
        </div>
        <div class="wf-report-table-card" v-if="!isTableLikeChart && !isKpiChart && !isProgressListChart">
          <div class="wf-trow wf-trow-header wf-report-table-grid">
            <div>Nhóm dữ liệu</div>
            <div>Giá trị</div>
            <div>Xu hướng</div>
            <div>Tỷ trọng</div>
          </div>
          <div v-for="row in previewRows" :key="row.label" class="wf-trow wf-report-table-grid" @click="openDrillDown(row.label)">
            <div>
              <div class="wf-audit-title">{{ row.label }}</div>
              <div class="wf-audit-sub">{{ activeDataset.name }}</div>
            </div>
            <div class="wf-report-strong">{{ formatNumber(getMetricValue(row)) }}</div>
            <div>
              <v-chip size="x-small" :color="row.delta >= 0 ? '#217D46' : '#c62828'" variant="tonal">
                {{ row.delta >= 0 ? '+' : '' }}{{ row.delta }}%
              </v-chip>
            </div>
            <div>{{ row.share }}%</div>
            </div>
          </div>
        </div>
      </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: "uc-report-builder-page",
  mixins: [
    typeof window !== "undefined" && window.__WF_REPORT_BUILDER_MATRIX_MIXIN__
      ? window.__WF_REPORT_BUILDER_MATRIX_MIXIN__
      : {},
    typeof window !== "undefined" && window.__WF_REPORT_BUILDER_FILE_DATASET_MIXIN__
      ? window.__WF_REPORT_BUILDER_FILE_DATASET_MIXIN__
      : {}
  ],
  data: function () {
    return {
      chart: null,
      isLoadingDataset: false,
      isSaving: false,
      isPreviewLoading: false,
      currentReportId: 0,
      reportName: "Widget sản lượng hồ sơ theo tháng",
      reportDescription: "Một widget dùng để theo dõi nhanh khối lượng hồ sơ ký và xu hướng xử lý theo nhóm dữ liệu.",
      selectedDatasetCode: "contract_volume",
      selectedChartType: "bar",
      selectedDimension: "month",
      selectedMetric: "requestCount",
      selectedRange: "30 ngày gần nhất",
      selectedStatus: "Tất cả",
      selectedFieldKeys: ["label", "value", "delta", "share"],
      tableVisibleColumns: ["label", "value", "delta", "share"],
      tableColumnLabels: {},
      tableColumnFilters: {},
      tableColumnWidths: {},
      tableFreezeFirstColumn: true,
      tableSortBy: "value",
      tableSortDir: "desc",
      tableTopN: 20,
      tableFilters: {
        keyword: "",
        minValue: "",
        deltaMode: "all"
      },
      formulaSeed: 0,
      formulaColumns: [],
      previewApiSummary: null,
      previewApiRows: [],
      httpApiRows: [],
      httpApiError: "",
      tableDetailSummary: null,
      tableDetailRows: [],
      tableDetailError: "",
      fileDatasetRows: [],
      fileDatasetRawText: "",
      fileDatasetError: "",
      datasetCatalog: [
        {
          code: "contract_volume",
          name: "Khối lượng hồ sơ ký",
          description: "Theo dõi số lượng yêu cầu ký, tỷ lệ hoàn tất và phân bố theo trạng thái hồ sơ.",
          datasetType: "DB",
          sourceKind: "DATABASE",
          schemaStatus: "READY",
          canPreview: true,
          recordCount: 1680,
          dimensions: [
            { key: "month", label: "Theo tháng" },
            { key: "status", label: "Theo trạng thái" },
            { key: "department", label: "Theo đơn vị" }
          ],
          metrics: [
            { key: "requestCount", label: "Số yêu cầu" },
            { key: "completedRate", label: "Tỷ lệ hoàn tất" },
            { key: "slaHours", label: "Giờ SLA trung bình" }
          ],
          rows: {
            month: [
              { label: "Tháng 11", requestCount: 245, completedRate: 92, slaHours: 4.6, delta: 4, share: 16 },
              { label: "Tháng 12", requestCount: 268, completedRate: 94, slaHours: 4.2, delta: 6, share: 18 },
              { label: "Tháng 01", requestCount: 301, completedRate: 95, slaHours: 3.8, delta: 8, share: 20 },
              { label: "Tháng 02", requestCount: 279, completedRate: 93, slaHours: 4.1, delta: -3, share: 19 },
              { label: "Tháng 03", requestCount: 334, completedRate: 96, slaHours: 3.5, delta: 10, share: 27 }
            ],
            status: [
              { label: "Hoàn tất", requestCount: 1196, completedRate: 96, slaHours: 2.4, delta: 9, share: 71 },
              { label: "Chờ ký", requestCount: 282, completedRate: 0, slaHours: 5.8, delta: 3, share: 17 },
              { label: "Từ chối", requestCount: 104, completedRate: 0, slaHours: 1.5, delta: -2, share: 6 },
              { label: "Quá hạn", requestCount: 98, completedRate: 0, slaHours: 9.2, delta: -5, share: 6 }
            ],
            department: [
              { label: "Khối Kinh doanh", requestCount: 514, completedRate: 95, slaHours: 3.6, delta: 8, share: 31 },
              { label: "Khối Vận hành", requestCount: 422, completedRate: 94, slaHours: 3.9, delta: 6, share: 25 },
              { label: "Pháp chế", requestCount: 336, completedRate: 97, slaHours: 2.7, delta: 11, share: 20 },
              { label: "Nhân sự", requestCount: 218, completedRate: 92, slaHours: 4.8, delta: 2, share: 13 },
              { label: "Mua sắm", requestCount: 190, completedRate: 93, slaHours: 4.1, delta: 4, share: 11 }
            ]
          }
        },
        {
          code: "smartca_health",
          name: "Hiệu suất SmartCA",
          description: "Theo dõi transaction SmartCA theo gateway, lỗi timeout và thời gian phản hồi trung bình.",
          datasetType: "DB",
          sourceKind: "DATABASE",
          schemaStatus: "READY",
          canPreview: true,
          recordCount: 742,
          dimensions: [
            { key: "gateway", label: "Theo gateway" },
            { key: "result", label: "Theo kết quả" },
            { key: "hourBand", label: "Theo khung giờ" }
          ],
          metrics: [
            { key: "requestCount", label: "Số giao dịch" },
            { key: "completedRate", label: "Tỷ lệ thành công" },
            { key: "slaHours", label: "Phản hồi TB (giây)" }
          ],
          rows: {
            gateway: [
              { label: "SmartCA Core", requestCount: 328, completedRate: 97, slaHours: 1.8, delta: 7, share: 44 },
              { label: "VNPT eContract", requestCount: 174, completedRate: 94, slaHours: 2.6, delta: 4, share: 24 },
              { label: "WeSign", requestCount: 140, completedRate: 91, slaHours: 3.4, delta: -1, share: 19 },
              { label: "Fallback OTP", requestCount: 100, completedRate: 88, slaHours: 4.2, delta: -3, share: 13 }
            ],
            result: [
              { label: "Thành công", requestCount: 684, completedRate: 100, slaHours: 1.9, delta: 6, share: 92 },
              { label: "Timeout", requestCount: 24, completedRate: 0, slaHours: 6.8, delta: -4, share: 3 },
              { label: "Từ chối", requestCount: 19, completedRate: 0, slaHours: 1.2, delta: -1, share: 3 },
              { label: "Sai mapping", requestCount: 15, completedRate: 0, slaHours: 0.8, delta: -2, share: 2 }
            ],
            hourBand: [
              { label: "08h - 10h", requestCount: 122, completedRate: 95, slaHours: 1.6, delta: 5, share: 16 },
              { label: "10h - 12h", requestCount: 168, completedRate: 96, slaHours: 1.8, delta: 6, share: 23 },
              { label: "13h - 15h", requestCount: 216, completedRate: 94, slaHours: 2.4, delta: 2, share: 29 },
              { label: "15h - 17h", requestCount: 148, completedRate: 93, slaHours: 2.6, delta: 1, share: 20 },
              { label: "Sau giờ hành chính", requestCount: 88, completedRate: 89, slaHours: 3.9, delta: -3, share: 12 }
            ]
          }
        }
      ]
    }
  },
  computed: {
    activeDataset: function () {
      var found = null;
      var idx = 0;
      for (idx = 0; idx < this.datasetCatalog.length; idx++) {
        if (this.datasetCatalog[idx].code === this.selectedDatasetCode) {
          found = this.datasetCatalog[idx];
          break;
        }
      }
      return found || this.datasetCatalog[0];
    },
    datasetOptions: function () {
      return this.datasetCatalog.map(function (item) {
        var suffix = " · DB";
        if (item.sourceKind === "API") {
          suffix = " · API/store";
        } else if (item.datasetType === "FILE") {
          suffix = " · File";
        }
        return { label: item.name + suffix, value: item.code };
      });
    },
    chartTypeOptions: function () {
      return [
        { title: "KPI card", value: "kpi" },
        { title: "Bar dọc", value: "bar" },
        { title: "Bar ngang", value: "bar_horizontal" },
        { title: "Line", value: "line" },
        { title: "Area", value: "area" },
        { title: "Donut", value: "donut" },
        { title: "Pie", value: "pie" },
        { title: "Ranking list", value: "progress_list" },
        { title: "Table", value: "table" },
        { title: "Matrix", value: "matrix" }
      ];
    },
    rangeOptions: function () {
      return ["7 ngày gần nhất", "30 ngày gần nhất", "Quý này", "Năm nay"];
    },
    statusOptions: function () {
      return ["Tất cả", "Đang hoạt động", "Chỉ hoàn tất", "Cần xử lý"];
    },
    dimensionOptions: function () {
      return (this.activeDataset.dimensions || []).map(function (item) {
        return { title: item.label, value: item.key };
      });
    },
    metricOptions: function () {
      var metrics = this.activeDataset.metrics || [];
      if (this.activeDataset.datasetType === "FILE" && this.activeDataset.fields && this.activeDataset.fields.length > 0) {
        metrics = this.resolveFileMetricOptions(this.activeDataset.fields);
      }
      return metrics.map(function (item) {
        return { title: item.label, value: item.key };
      });
    },
    availableFields: function () {
      return [
        { key: "label", label: "Tên nhóm" },
        { key: "value", label: "Giá trị metric" },
        { key: "delta", label: "Biến động %" },
        { key: "share", label: "Tỷ trọng %" }
      ];
    },
    tableDeltaModeOptions: function () {
      return [
        { title: "Tất cả", value: "all" },
        { title: "Chỉ tăng", value: "positive" },
        { title: "Chỉ giảm", value: "negative" }
      ];
    },
    tableSortDirectionOptions: function () {
      return [
        { title: "Giảm dần", value: "desc" },
        { title: "Tăng dần", value: "asc" }
      ];
    },
    previewRows: function () {
      if (!this.isPreviewSupported) {
        return [];
      }
      if (this.previewApiRows && this.previewApiRows.length > 0) {
        return this.previewApiRows;
      }
      return [];
    },
    isPreviewSupported: function () {
      if (!this.activeDataset) {
        return false;
      }
      if (this.activeDataset.datasetType === "FILE") {
        return ["CSV", "XLS", "XLSX"].indexOf(String(this.activeDataset.sourceKind || "").toUpperCase()) >= 0
          && !!String(this.activeDataset.sourceFileId || "").trim();
      }
      if (this.activeDataset.sourceKind === "API" && this.isHttpApiDataset(this.activeDataset)) {
        return !!String(this.getHttpApiConfigValue(this.resolveDatasetSourceConfig(this.activeDataset), "requestUrl") || "").trim();
      }
      return !!this.activeDataset.canPreview;
    },
    previewDisabledMessage: function () {
      if (this.activeDataset.sourceKind === "API") {
        if (this.isHttpApiDataset(this.activeDataset)) {
          return this.httpApiError || "Dataset HTTP API đã có metadata schema nhưng builder chưa gọi được endpoint thật. Kiểm tra URL, token hoặc CORS.";
        }
        return "Dataset API/store chưa có SourceProcedureName hoặc chưa READY trong registry, nên builder chưa thể gọi preview thật.";
      }
      if (this.activeDataset.datasetType === "FILE") {
        if (["CSV", "XLS", "XLSX"].indexOf(String(this.activeDataset.sourceKind || "").toUpperCase()) >= 0) {
          if (this.fileDatasetError) {
            return this.fileDatasetError;
          }
          if (String(this.activeDataset.sourceKind || "").toUpperCase() === "CSV") {
            return "CSV sẽ được đọc trực tiếp từ FileData để dựng chart/table ngay trong builder.";
          }
          return "Excel sẽ được đọc trực tiếp từ FileData theo sheet đã chọn để dựng chart/table ngay trong builder.";
        }
        return "Dataset file hiện chưa có định dạng preview được trong builder.";
      }
      return "Dataset hiện tại chưa sẵn sàng cho preview.";
    },
    selectedDimensionLabel: function () {
      var match = this.dimensionOptions.find(function (item) {
        return item.value === this.selectedDimension;
      }, this);
      return match ? match.title : "-";
    },
    selectedMetricLabel: function () {
      var match = this.metricOptions.find(function (item) {
        return item.value === this.selectedMetric;
      }, this);
      return match ? match.title : "-";
    },
    selectedChartTypeLabel: function () {
      var match = this.chartTypeOptions.find(function (item) {
        return item.value === this.selectedChartType;
      }, this);
      return match ? match.title : this.selectedChartType;
    },
    previewSummary: function () {
      if (this.previewApiSummary) {
        return {
          kpiValue: this.formatNumber(this.previewApiSummary.TotalValue || 0),
          kpiLabel: this.selectedMetricLabel,
          bestLabel: this.previewApiSummary.TopLabel || "-"
        };
      }
      var rows = this.previewRows;
      var total = 0;
      var topLabel = "-";
      var topValue = -1;
      var idx = 0;
      for (idx = 0; idx < rows.length; idx++) {
        total += Number(this.getMetricValue(rows[idx]) || 0);
        if (Number(this.getMetricValue(rows[idx]) || 0) > topValue) {
          topValue = Number(this.getMetricValue(rows[idx]) || 0);
          topLabel = rows[idx].label;
        }
      }
      return {
        kpiValue: this.formatNumber(total),
        kpiLabel: this.selectedMetricLabel,
        bestLabel: topLabel
      };
    },
    previewTitle: function () {
      return this.activeDataset.name + " / " + this.selectedDimensionLabel;
    },
    previewRecordCount: function () {
      if (this.previewApiSummary && this.previewApiSummary.PreviewRowCount !== undefined && this.previewApiSummary.PreviewRowCount !== null) {
        return this.formatNumber(this.previewApiSummary.PreviewRowCount);
      }
      return "0";
    },
    isKpiChart: function () {
      return this.selectedChartType === "kpi";
    },
    isProgressListChart: function () {
      return this.selectedChartType === "progress_list";
    }
  },
  watch: {
    selectedDatasetCode: function () {
      this.fileDatasetRows = [];
      this.fileDatasetRawText = "";
      this.fileDatasetError = "";
      this.httpApiRows = [];
      this.httpApiError = "";
      this.selectedDimension = this.activeDataset.dimensions[0] ? this.activeDataset.dimensions[0].key : "";
      this.selectedMetric = this.metricOptions[0] ? this.metricOptions[0].value : "";
      this.ensureTableConfigDefaults();
      this.runPreview();
    },
    selectedDimension: function () {
      this.runPreview();
    },
    selectedMetric: function () {
      this.runPreview();
    },
    selectedRange: function () {
      this.runPreview();
    },
    selectedStatus: function () {
      this.runPreview();
    },
    selectedChartType: function () {
      this.ensureTableConfigDefaults();
      this.runPreview();
    }
  },
  mounted: function () {
    this.currentReportId = this.getReportIdFromQuery();
    this.applyRouteContext();
    this.ensureTableConfigDefaults();
    this.loadDatasetCatalog();
    this.runPreview();
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
    isFieldSelected: function (key) {
      return this.selectedFieldKeys.indexOf(key) >= 0;
    },
    toggleField: function (key) {
      var idx = this.selectedFieldKeys.indexOf(key);
      if (idx >= 0) {
        this.selectedFieldKeys.splice(idx, 1);
      } else {
        this.selectedFieldKeys.push(key);
      }
    },
    runPreview: function () {
      var self = this;
      if (!self.isPreviewSupported) {
        self.previewApiSummary = null;
        self.previewApiRows = [];
        self.fileDatasetError = "";
        self.httpApiError = "";
        self.clearTableDetailPreview();
        self.$nextTick(function () {
          self.renderChart();
        });
        return;
      }
      if (self.activeDataset.datasetType === "FILE") {
        self.clearTableDetailPreview();
        self.runFileDatasetPreview();
        return;
      }
      if (self.activeDataset.sourceKind === "API" && self.isHttpApiDataset(self.activeDataset)) {
        self.runHttpApiDatasetPreview();
        return;
      }
      self.isPreviewLoading = true;
      apiCallAsync("WF_Report_RunPreview", {
        ReportDefinitionID: self.currentReportId || 0,
        DatasetCode: self.selectedDatasetCode,
        ChartType: self.selectedChartType,
        DimensionKey: self.selectedDimension,
        MetricKey: self.selectedMetric,
        TimeRangeKey: self.selectedRange,
        StatusFilter: self.selectedStatus
      }).then(function (resultSets) {
        self.previewApiSummary = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        self.previewApiRows = ((resultSets && resultSets[1]) || []).map(function (item) {
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
        if (self.isDataTableChart) {
          self.loadTableDetailPreview();
        } else {
          self.clearTableDetailPreview();
        }
      }).catch(function () {
        self.previewApiSummary = null;
        self.previewApiRows = [];
        self.clearTableDetailPreview();
      }).finally(function () {
        self.isPreviewLoading = false;
        self.$nextTick(function () {
          self.renderChart();
        });
      });
    },
    clearTableDetailPreview: function () {
      this.tableDetailSummary = null;
      this.tableDetailRows = [];
      this.tableDetailError = "";
    },
    clearHttpApiPreview: function () {
      this.httpApiRows = [];
      this.httpApiError = "";
    },
    runHttpApiDatasetPreview: function () {
      var self = this;
      self.isPreviewLoading = true;
      self.clearTableDetailPreview();
      self.clearHttpApiPreview();
      self.fetchHttpApiDatasetRows(self.activeDataset).then(function (rows) {
        var preview = self.buildHttpApiPreviewRows(rows || []);
        self.httpApiRows = rows || [];
        self.previewApiRows = preview.rows;
        self.previewApiSummary = preview.summary;
        if (self.isDataTableChart) {
          self.tableDetailRows = rows || [];
          self.tableDetailSummary = {
            PreviewRowCount: (rows || []).length,
            TotalValue: preview.summary ? preview.summary.TotalValue : 0,
            TopLabel: preview.summary ? preview.summary.TopLabel : "-"
          };
          self.ensureTableConfigDefaults();
        }
      }).catch(function (err) {
        self.previewApiSummary = null;
        self.previewApiRows = [];
        self.clearTableDetailPreview();
        self.httpApiError = err && err.message ? err.message : "Không gọi được dataset HTTP API từ builder.";
      }).finally(function () {
        self.isPreviewLoading = false;
        self.$nextTick(function () {
          self.renderChart();
        });
      });
    },
    fetchHttpApiDatasetRows: function (dataset) {
      var config = this.resolveDatasetSourceConfig(dataset);
      return this.fetchHttpApiResponse(this.getHttpApiConfigValue(config, "requestUrl"), {
        method: this.getHttpApiConfigValue(config, "httpMethod") || "GET",
        headers: this.buildHttpApiRequestHeaders(config),
        params: this.normalizeHttpApiParams(this.getHttpApiConfigValue(config, "requestParams")),
        body: this.getHttpApiConfigValue(config, "requestBody")
      }).then(function (payload) {
        return this.extractHttpApiRows(payload, this.getHttpApiConfigValue(config, "responseDataPath"));
      }.bind(this));
    },
    resolveDatasetSourceConfig: function (dataset) {
      var sourceConfig = this.tryParseJsonObject(dataset && dataset.sourceConfig ? dataset.sourceConfig : {}, {});
      var sourceMeta = this.tryParseJsonObject(dataset && dataset.sourceMeta ? dataset.sourceMeta : {}, {});
      var nestedMeta = this.tryParseJsonObject(sourceConfig && (sourceConfig.SourceMeta || sourceConfig.sourceMeta) ? (sourceConfig.SourceMeta || sourceConfig.sourceMeta) : {}, {});
      var merged = {};
      Object.keys(sourceMeta || {}).forEach(function (key) {
        merged[key] = sourceMeta[key];
      });
      Object.keys(nestedMeta || {}).forEach(function (key) {
        merged[key] = nestedMeta[key];
      });
      Object.keys(sourceConfig || {}).forEach(function (key) {
        merged[key] = sourceConfig[key];
      });
      if (!String(this.getHttpApiConfigValue(merged, "requestUrl") || "").trim()) {
        if (/^https?:\/\//i.test(String(sourceConfig && sourceConfig.SourceApiCode ? sourceConfig.SourceApiCode : "").trim())) {
          merged.requestUrl = String(sourceConfig.SourceApiCode || "").trim();
        } else if (/^https?:\/\//i.test(String(dataset && dataset.sourceApiCode ? dataset.sourceApiCode : "").trim())) {
          merged.requestUrl = String(dataset.sourceApiCode || "").trim();
        }
      }
      if (!String(this.getHttpApiConfigValue(merged, "requestMode") || "").trim() && String(this.getHttpApiConfigValue(merged, "requestUrl") || "").trim()) {
        merged.requestMode = "HTTP";
      }
      return merged;
    },
    isHttpApiDataset: function (dataset) {
      var config = this.resolveDatasetSourceConfig(dataset || {});
      return String(this.getHttpApiConfigValue(config, "requestMode") || "").toUpperCase() === "HTTP"
        || !!String(this.getHttpApiConfigValue(config, "requestUrl") || "").trim();
    },
    getHttpApiConfigValue: function (config, key) {
      var matchedKey = "";
      if (!config || typeof config !== "object") {
        return "";
      }
      if (config[key] !== undefined) {
        return config[key];
      }
      matchedKey = this.findHttpApiObjectKeyCaseInsensitive(config, key);
      if (matchedKey) {
        return config[matchedKey];
      }
      return "";
    },
    buildHttpApiPreviewRows: function (rows) {
      var self = this;
      var dimensionKey = self.selectedDimension || "";
      var metricKey = self.selectedMetric || "";
      var grouped = {};
      var order = [];
      var total = 0;
      var topLabel = "-";
      var topValue = -1;
      var previewRows = [];
      (rows || []).forEach(function (row) {
        var label = self.resolveHttpApiGroupLabel(row, dimensionKey);
        var metricValue = self.resolveHttpApiMetricValue(row, metricKey);
        if (!Object.prototype.hasOwnProperty.call(grouped, label)) {
          grouped[label] = {
            label: label,
            value: 0,
            requestCount: 0,
            completedRate: 0,
            slaHours: 0,
            delta: 0,
            share: 0,
            __count: 0
          };
          order.push(label);
        }
        grouped[label].value += metricValue;
        grouped[label].requestCount += metricKey === "rowCount" ? 1 : metricValue;
        grouped[label].__count += 1;
      });
      previewRows = order.map(function (label) {
        var item = grouped[label];
        total += Number(item.value || 0);
        if (Number(item.value || 0) > topValue) {
          topValue = Number(item.value || 0);
          topLabel = item.label;
        }
        return item;
      });
      previewRows = previewRows.map(function (item, index) {
        var previousValue = index > 0 ? Number(previewRows[index - 1].value || 0) : Number(item.value || 0);
        if (item.__count > 0 && metricKey !== "rowCount" && self.looksLikeRateMetric(metricKey)) {
          item.value = Number((Number(item.value || 0) / item.__count).toFixed(2));
        }
        item.share = total > 0 ? Number((((Number(item.value || 0) / total) * 100).toFixed(2))) : 0;
        item.delta = previousValue ? Number((((Number(item.value || 0) - previousValue) / previousValue) * 100).toFixed(2)) : 0;
        delete item.__count;
        return item;
      });
      return {
        rows: previewRows,
        summary: {
          PreviewRowCount: previewRows.length,
          TotalValue: total,
          TopLabel: topLabel
        }
      };
    },
    resolveHttpApiGroupLabel: function (row, dimensionKey) {
      var value = row && row[dimensionKey] !== undefined ? row[dimensionKey] : "";
      if (value === null || value === undefined || value === "") {
        return "(Trống)";
      }
      return String(value);
    },
    resolveHttpApiMetricValue: function (row, metricKey) {
      var raw = null;
      if (!metricKey || metricKey === "rowCount") {
        return 1;
      }
      raw = row && row[metricKey] !== undefined ? row[metricKey] : 0;
      if (typeof raw === "number") {
        return raw;
      }
      if (typeof raw === "boolean") {
        return raw ? 1 : 0;
      }
      return isNaN(Number(raw)) ? 0 : Number(raw);
    },
    looksLikeRateMetric: function (metricKey) {
      var normalized = String(metricKey || "").toLowerCase();
      return normalized.indexOf("rate") >= 0 || normalized.indexOf("ratio") >= 0 || normalized.indexOf("percent") >= 0;
    },
    normalizeHttpApiParams: function (rows) {
      return (rows || []).map(function (item) {
        return {
          Key: String(item && item.Key ? item.Key : "").trim(),
          Value: item && item.Value !== undefined ? item.Value : ""
        };
      }).filter(function (item) {
        return item.Key !== "";
      });
    },
    buildHttpApiRequestHeaders: function (config) {
      var output = {};
      var authToken = String(this.getHttpApiConfigValue(config, "authToken") || "").trim();
      var authHeaderName = String(this.getHttpApiConfigValue(config, "authHeaderName") || "Authorization").trim();
      var authScheme = String(this.getHttpApiConfigValue(config, "authScheme") || "").trim();
      (this.getHttpApiConfigValue(config, "headers") || []).forEach(function (item) {
        if (item && item.Key) {
          output[item.Key] = item.Value;
        }
      });
      if (authToken && authHeaderName) {
        output[authHeaderName] = authScheme ? (authScheme + " " + authToken) : authToken;
      }
      return output;
    },
    buildHttpApiRequestUrl: function (baseUrl, params, method) {
      var url = String(baseUrl || "").trim();
      var queryParts = [];
      if (String(method || "GET").toUpperCase() !== "GET") {
        return url;
      }
      (params || []).forEach(function (item) {
        queryParts.push(encodeURIComponent(item.Key) + "=" + encodeURIComponent(item.Value));
      });
      if (queryParts.length === 0) {
        return url;
      }
      return url + (url.indexOf("?") >= 0 ? "&" : "?") + queryParts.join("&");
    },
    fetchHttpApiResponse: function (url, options) {
      var method = options && options.method ? String(options.method).toUpperCase() : "GET";
      var params = options && options.params ? options.params : [];
      var requestUrl = this.buildHttpApiRequestUrl(url, params, method);
      var requestInit = {
        method: method,
        headers: options && options.headers ? options.headers : {}
      };
      if (requestInit.method !== "GET" && requestInit.method !== "HEAD") {
        if (options && options.body !== null && options.body !== undefined && options.body !== "") {
          if (typeof options.body === "string") {
            requestInit.body = options.body;
          } else {
            requestInit.body = JSON.stringify(options.body);
            if (!requestInit.headers["Content-Type"] && !requestInit.headers["content-type"]) {
              requestInit.headers["Content-Type"] = "application/json";
            }
          }
        } else if (params.length > 0) {
          requestInit.body = JSON.stringify(this.convertHttpApiParamsToObject(params));
          if (!requestInit.headers["Content-Type"] && !requestInit.headers["content-type"]) {
            requestInit.headers["Content-Type"] = "application/json";
          }
        }
      }
      return fetch(requestUrl, requestInit).then(function (response) {
        if (!response.ok) {
          throw new Error("HTTP API trả về mã " + String(response.status) + ".");
        }
        return response.text();
      }).then(function (text) {
        if (!text) {
          return [];
        }
        try {
          return JSON.parse(text);
        } catch (err) {
          throw new Error("HTTP API không trả về JSON hợp lệ để builder preview.");
        }
      }).catch(function (err) {
        if (err && err.message) {
          throw err;
        }
        throw new Error("Không gọi được HTTP API từ builder. Kiểm tra URL, token hoặc CORS.");
      });
    },
    convertHttpApiParamsToObject: function (params) {
      var output = {};
      (params || []).forEach(function (item) {
        output[item.Key] = item.Value;
      });
      return output;
    },
    extractHttpApiRows: function (payload, responsePath) {
      var target = payload;
      var rows = [];
      if (String(responsePath || "").trim()) {
        target = this.readHttpApiValueByPath(payload, responsePath);
      }
      if (target === null || target === undefined || target === "") {
        target = this.unwrapHttpApiCandidate(payload);
      } else {
        target = this.unwrapHttpApiCandidate(target);
      }
      if (Array.isArray(target)) {
        rows = target;
      } else if (target && typeof target === "object") {
        rows = [target];
      }
      rows = rows.filter(function (item) {
        return item && typeof item === "object" && !Array.isArray(item);
      });
      if (!rows.length) {
        throw new Error("Không tìm thấy rows hợp lệ trong HTTP API để builder preview.");
      }
      return rows;
    },
    unwrapHttpApiCandidate: function (target) {
      var current = target;
      var guard = 0;
      var wrapper = null;
      while (guard < 5) {
        guard += 1;
        if (typeof current === "string") {
          current = this.tryParseJsonObject(current, current);
        }
        if (Array.isArray(current)) {
          if (current.length === 1 && current[0] && typeof current[0] === "object" && !Array.isArray(current[0])) {
            wrapper = this.pickHttpApiWrappedNode(current[0]);
            if (wrapper !== null && wrapper !== undefined) {
              current = wrapper;
              continue;
            }
          }
          return current;
        }
        if (!current || typeof current !== "object") {
          return current;
        }
        wrapper = this.pickHttpApiWrappedNode(current);
        if (wrapper !== null && wrapper !== undefined) {
          current = wrapper;
          continue;
        }
        return current;
      }
      return current;
    },
    pickHttpApiWrappedNode: function (node) {
      var candidates = ["data", "items", "result", "results", "list", "rows"];
      var keys = Object.keys(node || {});
      var idx = 0;
      var matched = "";
      if (!node || typeof node !== "object" || Array.isArray(node)) {
        return null;
      }
      for (idx = 0; idx < candidates.length; idx += 1) {
        matched = this.findHttpApiObjectKeyCaseInsensitive(node, candidates[idx]);
        if (matched && (Array.isArray(node[matched]) || (node[matched] && typeof node[matched] === "object"))) {
          return node[matched];
        }
      }
      if (keys.length === 1 && (Array.isArray(node[keys[0]]) || (node[keys[0]] && typeof node[keys[0]] === "object"))) {
        return node[keys[0]];
      }
      return null;
    },
    readHttpApiValueByPath: function (root, path) {
      var normalized = String(path || "").replace(/^\$\./, "").replace(/^\$/, "").replace(/\[(\d+)\]/g, ".$1");
      var segments = normalized.split(".").filter(function (item) {
        return String(item || "").trim() !== "";
      });
      var current = root;
      var index = 0;
      var segment = "";
      var matched = "";
      for (index = 0; index < segments.length; index += 1) {
        if (current === null || current === undefined) {
          return null;
        }
        segment = String(segments[index] || "").trim();
        if (Array.isArray(current) && /^\d+$/.test(segment)) {
          current = current[Number(segment)];
          continue;
        }
        if (current[segment] !== undefined) {
          current = current[segment];
          continue;
        }
        matched = this.findHttpApiObjectKeyCaseInsensitive(current, segment);
        if (matched) {
          current = current[matched];
          continue;
        }
        return null;
      }
      return current;
    },
    findHttpApiObjectKeyCaseInsensitive: function (target, key) {
      var normalized = String(key || "").toLowerCase();
      var keys = [];
      var idx = 0;
      if (!target || typeof target !== "object" || Array.isArray(target)) {
        return "";
      }
      keys = Object.keys(target);
      for (idx = 0; idx < keys.length; idx += 1) {
        if (String(keys[idx] || "").toLowerCase() === normalized) {
          return keys[idx];
        }
      }
      return "";
    },
    updateTableColumnLabel: function (payload) {
      if (!payload || !payload.key) {
        return;
      }
      this.tableColumnLabels[payload.key] = payload.value;
      this.tableColumnLabels = Object.assign({}, this.tableColumnLabels);
    },
    updateTableColumnFilter: function (payload) {
      if (!payload || !payload.key) {
        return;
      }
      this.tableColumnFilters[payload.key] = payload.value;
      this.tableColumnFilters = Object.assign({}, this.tableColumnFilters);
    },
    onTableRowClick: function (row) {
      var groupLabel = "";
      if (row && row.GroupLabel) {
        groupLabel = row.GroupLabel;
      } else if (row && row.label) {
        groupLabel = row.label;
      }
      this.openDrillDown(groupLabel);
    },
    loadTableDetailPreview: function () {
      var self = this;
      self.tableDetailError = "";
      apiCallAsync("WF_Report_RunDetail", {
        ReportDefinitionID: self.currentReportId || 0,
        DatasetCode: self.selectedDatasetCode,
        ChartType: self.selectedChartType,
        DimensionKey: self.selectedDimension,
        MetricKey: self.selectedMetric,
        TimeRangeKey: self.selectedRange,
        StatusFilter: self.selectedStatus,
        GroupLabel: ""
      }).then(function (resultSets) {
        self.tableDetailSummary = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        self.tableDetailRows = (resultSets && resultSets[1]) || [];
        self.ensureTableConfigDefaults();
      }).catch(function (xhr) {
        self.tableDetailSummary = null;
        self.tableDetailRows = [];
        self.tableDetailError = xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "";
      });
    },
    loadDatasetCatalog: function () {
      var self = this;
      self.isLoadingDataset = true;
      apiCallAsync("WF_ReportDataset_GetList", {
        Keyword: "",
        OnlyActive: 1
      }).then(function (resultSets) {
        self.applyDatasetMeta((resultSets && resultSets[0]) || [], (resultSets && resultSets[1]) || []);
        if (self.currentReportId > 0) {
          self.loadReportDetail(self.currentReportId);
        } else {
          self.runPreview();
        }
      }).catch(function () {
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được metadata nguồn dữ liệu widget. Đang giữ cấu hình hiện tại.");
        }
      }).finally(function () {
        self.isLoadingDataset = false;
      });
    },
    applyDatasetMeta: function (datasetRows, fieldRows) {
      var localMap = {};
      var merged = [];
      var i = 0;
      var j = 0;
      var fields = [];
      for (i = 0; i < this.datasetCatalog.length; i++) {
        localMap[this.datasetCatalog[i].code] = this.datasetCatalog[i];
      }
      for (i = 0; i < datasetRows.length; i++) {
        fields = [];
        for (j = 0; j < fieldRows.length; j++) {
          if (fieldRows[j].DatasetCode === datasetRows[i].DatasetCode) {
            fields.push(fieldRows[j]);
          }
        }
        merged.push({
          code: datasetRows[i].DatasetCode,
          name: datasetRows[i].DatasetName,
          description: datasetRows[i].Description || "",
          datasetType: datasetRows[i].DatasetType || "DB",
          sourceKind: datasetRows[i].SourceKind || "DATABASE",
          schemaStatus: datasetRows[i].SchemaStatus || "READY",
          canPreview: datasetRows[i].CanPreview === true || datasetRows[i].CanPreview === 1,
          sourceFileId: datasetRows[i].SourceFileID || "",
          sourceFileName: datasetRows[i].SourceFileName || "",
          sourceMeta: this.tryParseJsonObject(datasetRows[i].SourceMetaJson, {}),
          sourceConfig: this.tryParseJsonObject(datasetRows[i].SourceConfigJson, {}),
          recordCount: 0,
          dimensions: fields.filter(function (item) { return item.FieldRole === "DIMENSION"; }).map(function (item) {
            return { key: item.FieldKey, label: item.FieldLabel };
          }),
          metrics: fields.filter(function (item) { return item.FieldRole === "METRIC"; }).map(function (item) {
            return { key: item.FieldKey, label: item.FieldLabel };
          }),
          fields: fields.map(function (item) {
            return {
              key: item.FieldKey,
              label: item.FieldLabel,
              role: item.FieldRole,
              dataType: item.DataType
            };
          }),
          rows: {}
        });
      }
      if (merged.length > 0) {
        for (i = 0; i < merged.length; i++) {
          if (!merged[i].dimensions || merged[i].dimensions.length === 0) {
            merged[i].dimensions = localMap[merged[i].code] ? localMap[merged[i].code].dimensions : [];
          }
          if (!merged[i].metrics || merged[i].metrics.length === 0) {
            merged[i].metrics = localMap[merged[i].code] ? localMap[merged[i].code].metrics : [];
          }
          if (localMap[merged[i].code] && localMap[merged[i].code].recordCount) {
            merged[i].recordCount = localMap[merged[i].code].recordCount;
          }
          if (localMap[merged[i].code] && localMap[merged[i].code].canPreview !== undefined && (datasetRows.length === 0 || merged[i].canPreview === undefined)) {
            merged[i].canPreview = localMap[merged[i].code].canPreview;
          }
        }
        this.datasetCatalog = merged;
      }
    },
    loadReportDetail: function (reportId) {
      var self = this;
      apiCallAsync("WF_ReportDefinition_GetDetail", {
        ReportDefinitionID: reportId
      }).then(function (resultSets) {
        var detail = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (!detail) {
          return;
        }
        var config = self.tryParseJsonObject(detail.ConfigJson, {});
        self.currentReportId = detail.ReportDefinitionID;
        self.reportName = detail.ReportName || "";
        self.reportDescription = detail.Description || "";
        self.selectedDatasetCode = detail.DatasetCode || self.selectedDatasetCode;
        self.selectedChartType = config.ChartType || detail.ChartType || self.selectedChartType;
        self.selectedDimension = detail.DimensionKey || self.selectedDimension;
        self.selectedMetric = detail.MetricKey || self.selectedMetric;
        self.selectedRange = detail.TimeRangeKey || self.selectedRange;
        self.selectedStatus = detail.StatusFilter || self.selectedStatus;
        self.selectedFieldKeys = self.tryParseJsonArray(detail.SelectedFieldsJson, self.selectedFieldKeys);
        self.formulaColumns = Array.isArray(config.FormulaColumns) ? config.FormulaColumns : [];
        if (config.TableConfig) {
          self.tableVisibleColumns = Array.isArray(config.TableConfig.VisibleColumns) ? config.TableConfig.VisibleColumns : self.tableVisibleColumns;
          self.tableColumnLabels = config.TableConfig.ColumnLabels || {};
          self.tableColumnFilters = config.TableConfig.ColumnFilters || {};
          self.tableColumnWidths = config.TableConfig.ColumnWidths || {};
          self.tableFreezeFirstColumn = config.TableConfig.FreezeFirstColumn !== undefined ? !!config.TableConfig.FreezeFirstColumn : self.tableFreezeFirstColumn;
          self.tableSortBy = config.TableConfig.SortBy || self.tableSortBy;
          self.tableSortDir = config.TableConfig.SortDir || self.tableSortDir;
          self.tableTopN = config.TableConfig.TopN || self.tableTopN;
          self.tableFilters = config.TableConfig.TableFilters || self.tableFilters;
        }
        self.formulaSeed = self.formulaColumns.length;
        self.ensureTableConfigDefaults();
        self.runPreview();
      }).catch(function () {
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được chi tiết widget đã lưu.");
        }
      });
    },
    renderChart: function () {
      if (this.isTableLikeChart || this.isKpiChart || this.isProgressListChart) {
        if (this.chart && this.chart.dispose) {
          this.chart.dispose();
          this.chart = null;
        }
        return;
      }
      if (!this.isPreviewSupported) {
        if (this.chart && this.chart.dispose) {
          this.chart.dispose();
          this.chart = null;
        }
        return;
      }
      if (!this.$refs.chartEl || !window.echarts) {
        return;
      }
      if (!this.chart) {
        this.chart = window.echarts.init(this.$refs.chartEl);
      }
      var labels = this.previewRows.map(function (item) {
        return item.label;
      });
      var values = this.previewRows.map(function (item) {
        return Number(item.value || 0);
      });
      var option = {
        color: ["#217D46", "#E5A812", "#185d34", "#7abf92", "#f3ca67"],
        tooltip: { trigger: (this.selectedChartType === "pie" || this.selectedChartType === "donut") ? "item" : "axis" },
        grid: { left: 24, right: 20, top: 40, bottom: 28, containLabel: true },
        xAxis: (this.selectedChartType === "pie" || this.selectedChartType === "donut") ? null : {
          type: "category",
          data: labels,
          axisLabel: { color: "#5f6368", fontSize: 11 }
        },
        yAxis: (this.selectedChartType === "pie" || this.selectedChartType === "donut") ? null : {
          type: "value",
          axisLabel: { color: "#5f6368", fontSize: 11 },
          splitLine: { lineStyle: { color: "#eef1f4" } }
        },
        series: this.buildSeries(labels, values)
      };
      if (this.selectedChartType === "bar_horizontal") {
        option.xAxis = {
          type: "value",
          axisLabel: { color: "#5f6368", fontSize: 11 },
          splitLine: { lineStyle: { color: "#eef1f4" } }
        };
        option.yAxis = {
          type: "category",
          data: labels,
          axisLabel: { color: "#5f6368", fontSize: 11 }
        };
      }
      this.chart.setOption(option, true);
      this.chart.off("click");
      this.chart.on("click", function (params) {
        if (params && params.name) {
          this.openDrillDown(params.name);
        }
      }.bind(this));
    },
    buildSeries: function (labels, values) {
      if (this.selectedChartType === "pie" || this.selectedChartType === "donut") {
        return [
          {
            type: "pie",
            radius: this.selectedChartType === "pie" ? "68%" : ["40%", "68%"],
            center: ["50%", "54%"],
            label: { formatter: "{b}\n{d}%", fontSize: 11 },
            data: labels.map(function (label, index) {
              return { name: label, value: values[index] };
            })
          }
        ];
      }
      if (this.selectedChartType === "line" || this.selectedChartType === "area") {
        return [
          {
            type: "line",
            smooth: true,
            symbolSize: 8,
            lineStyle: { width: 3 },
            areaStyle: this.selectedChartType === "area" ? { opacity: 0.18 } : null,
            data: values
          }
        ];
      }
      if (this.selectedChartType === "bar_horizontal") {
        return [
          {
            type: "bar",
            barMaxWidth: 24,
            borderRadius: [0, 6, 6, 0],
            data: values
          }
        ];
      }
      return [
        {
          type: "bar",
          barMaxWidth: 38,
          borderRadius: [6, 6, 0, 0],
          data: values
        }
      ];
    },
    formatNumber: function (value) {
      var number = Number(value || 0);
      return number.toLocaleString("vi-VN");
    },
    progressWidth: function (row) {
      var max = 0;
      var value = Number(this.getMetricValue(row) || 0);
      (this.previewRows || []).forEach(function (item) {
        max = Math.max(max, Number(this.getMetricValue(item) || 0));
      }.bind(this));
      if (!max) {
        return "0%";
      }
      return String(Math.max(8, Math.round((value / max) * 100))) + "%";
    },
    getMetricValue: function (row) {
      if (!row) {
        return 0;
      }
      if (row[this.selectedMetric] !== undefined && row[this.selectedMetric] !== null && row[this.selectedMetric] !== "") {
        return Number(row[this.selectedMetric] || 0);
      }
      return Number(row.value || 0);
    },
    getReportIdFromQuery: function () {
      var search = window.location.search || "";
      var params = new URLSearchParams(search);
      return Number(params.get("id") || 0);
    },
    getQueryValue: function (key) {
      var search = window.location.search || "";
      var params = new URLSearchParams(search);
      return String(params.get(key) || "").trim();
    },
    applyRouteContext: function () {
      var datasetCode = this.getQueryValue("dataset");
      if (datasetCode) {
        this.selectedDatasetCode = datasetCode;
      }
      if (!this.getQueryValue("id") && datasetCode) {
        this.reportName = "Widget - " + datasetCode;
        this.reportDescription = "Widget được mở từ màn Nguồn dữ liệu để tiếp tục thiết kế chart.";
      }
    },
    tryParseJsonArray: function (input, fallback) {
      if (!input) {
        return fallback || [];
      }
      try {
        var parsed = JSON.parse(input);
        return Array.isArray(parsed) ? parsed : (fallback || []);
      } catch (e) {
        return fallback || [];
      }
    },
    tryParseJsonObject: function (input, fallback) {
      if (!input) {
        return fallback || {};
      }
      try {
        return JSON.parse(input);
      } catch (e) {
        return fallback || {};
      }
    },
    openDrillDown: function (groupLabel) {
      if (this.activeDataset.datasetType === "FILE") {
        if (typeof showToast !== "undefined") {
          showToast.info("Dataset file hiện đã preview/chart được trong builder, còn drill-down chi tiết sẽ nối ở bước tiếp theo.");
        }
        return;
      }
      var params = new URLSearchParams();
      if (this.currentReportId > 0) {
        params.set("id", String(this.currentReportId));
      }
      params.set("dataset", this.selectedDatasetCode || "");
      params.set("chart", this.selectedChartType || "");
      params.set("dimension", this.selectedDimension || "");
      params.set("metric", this.selectedMetric || "");
      params.set("range", this.selectedRange || "");
      params.set("status", this.selectedStatus || "");
      if (groupLabel) {
        params.set("group", groupLabel);
      }
      window.location.href = "/wf-report-detail?" + params.toString();
    },
    saveReport: function () {
      var self = this;
      if (!this.reportName) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần nhập tên widget trước khi lưu.");
        }
        return;
      }
      if (!this.isPreviewSupported) {
        if (typeof showToast !== "undefined") {
          showToast.error("Dataset hiện tại chưa sẵn sàng preview thật, nên chưa thể lưu widget.");
        }
        return;
      }
      self.isSaving = true;
      apiCallAsync("WF_ReportDefinition_Save", {
        ReportDefinitionID: self.currentReportId || 0,
        ReportName: self.reportName,
        Description: self.reportDescription,
        DatasetCode: self.selectedDatasetCode,
        ChartType: self.selectedChartType,
        DimensionKey: self.selectedDimension,
        MetricKey: self.selectedMetric,
        TimeRangeKey: self.selectedRange,
        StatusFilter: self.selectedStatus,
        SelectedFields: self.selectedFieldKeys,
        Config: {
          DatasetCode: self.selectedDatasetCode,
          ChartType: self.selectedChartType,
          DimensionKey: self.selectedDimension,
          MetricKey: self.selectedMetric,
          TimeRangeKey: self.selectedRange,
          StatusFilter: self.selectedStatus,
          SelectedFields: self.selectedFieldKeys,
          FormulaColumns: self.formulaColumns,
          TableConfig: {
            VisibleColumns: self.tableVisibleColumns,
            ColumnLabels: self.tableColumnLabels,
            ColumnFilters: self.tableColumnFilters,
            ColumnWidths: self.tableColumnWidths,
            FreezeFirstColumn: !!self.tableFreezeFirstColumn,
            SortBy: self.tableSortBy,
            SortDir: self.tableSortDir,
            TopN: Number(self.tableTopN || 0),
            TableFilters: self.tableFilters
          }
        },
        IsShared: 0,
        IsPinnedDashboard: 0,
        IsActive: 1
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (row) {
          self.currentReportId = Number(row.ReportDefinitionID || 0);
        }
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã lưu widget.");
        }
        if (self.currentReportId > 0) {
          window.setTimeout(function () {
            window.location.href = "/wf-report-detail?id=" + self.currentReportId + "&saved=1";
          }, 700);
        }
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Lưu báo cáo thất bại.");
        }
      }).finally(function () {
        self.isSaving = false;
      });
    },
    openMyReports: function () {
      window.location.href = "/wf-report-my-reports";
    },
    goToDashboard: function () {
      window.location.href = "/wf-report-dashboard";
    }
  }
	}
</script>