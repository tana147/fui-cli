<template>
	<!-- sync-touch: 2026-03-23 dashboard-present-component -->
  <div class="wf-report-present-page">
    <div class="wf-report-present-toolbar">
      <div>
        <div class="wf-report-detail-hero__tag">Present mode</div>
        <h1>{{ dashboardName }}</h1>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="goList">
          <v-icon start>mdi-arrow-left</v-icon>
          Dashboard
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="goDesign">
          <v-icon start>mdi-pencil-outline</v-icon>
          Thiết kế
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="toggleFullscreen">
          <v-icon start>{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
          {{ isFullscreen ? 'Thoát full' : 'Fullscreen' }}
        </v-btn>
      </div>
    </div>

    <div class="wf-report-present-filters">
      <v-select v-model="globalRange" :items="rangeOptions" label="Thời gian" variant="outlined" density="compact" hide-details="auto" />
      <v-select v-model="globalStatus" :items="statusOptions" label="Trạng thái" variant="outlined" density="compact" hide-details="auto" />
      <v-btn class="wf-btn" variant="outlined" color="primary" @click="reloadRuntime">
        <v-icon start>mdi-refresh</v-icon>
        Tải lại
      </v-btn>
    </div>

    <div v-if="renderedSections.length === 0" class="wf-empty-state wf-report-dashboard-empty">
      Dashboard này chưa có section hoặc chưa gắn widget nào.
    </div>

    <div v-else class="wf-report-canvas-grid wf-report-canvas-grid--present">
      <div v-for="section in renderedSections" :key="section.sectionId" class="wf-report-section-card wf-report-section-card--present">
        <div class="wf-report-section-card__head">
          <div class="wf-report-section-card__title-block">
            <h3>{{ section.title }}</h3>
          </div>
        </div>
        <div v-for="(row, rowIndex) in section.rows" :key="section.sectionId + '_' + rowIndex" class="wf-report-canvas-row" :style="canvasRowStyle(row)">
          <div
            v-for="region in row"
            :key="region.regionId"
            class="wf-report-widget wf-report-widget--canvas"
            :class="regionCardClasses(region)"
            :style="regionGridStyle(region, row.length)"
            :data-widget-runtime-key="region.widgetId ? getWidgetRuntimeKey(getRegionWidget(region)) : ''"
          >
            <div class="wf-report-widget__head">
              <div>
                <h3>{{ region.title || 'Vùng hiển thị' }}</h3>
              </div>
              <div class="wf-report-widget__head-meta">
                <v-btn
                  v-if="getRegionWidget(region) && !isTableLikeChart(getRegionWidget(region)) && !isKpiWidget(getRegionWidget(region)) && !isProgressListWidget(getRegionWidget(region)) && !isOfficialLiveWidget(getRegionWidget(region))"
                  class="wf-btn"
                  size="small"
                  variant="text"
                  color="primary"
                  @click="saveWidgetAsPng(getRegionWidget(region))"
                >
                  <v-icon start>mdi-image-outline</v-icon>
                  PNG
                </v-btn>
                <v-btn
                  v-if="getRegionWidget(region) && isTableLikeChart(getRegionWidget(region))"
                  class="wf-btn"
                  size="small"
                  variant="text"
                  color="primary"
                  @click="exportWidgetCsv(getRegionWidget(region))"
                >
                  <v-icon start>mdi-file-delimited-outline</v-icon>
                  CSV
                </v-btn>
                <v-btn
                  v-if="getRegionWidget(region) && isTableLikeChart(getRegionWidget(region))"
                  class="wf-btn"
                  size="small"
                  variant="text"
                  color="primary"
                  @click="exportWidgetExcel(getRegionWidget(region))"
                >
                  <v-icon start>mdi-microsoft-excel</v-icon>
                  Excel
                </v-btn>
              </div>
            </div>

            <div v-if="!getRegionWidget(region)" class="wf-empty-state">Vùng này chưa có widget.</div>

            <div v-else-if="getRegionWidget(region).isLoading" class="wf-report-widget__loading">
              <div class="wf-report-widget__loading-spinner">
                <v-progress-circular indeterminate size="22" width="2" color="primary"></v-progress-circular>
              </div>
              <div class="wf-report-widget__loading-title">Đang tải widget</div>
              <div class="wf-report-widget__loading-sub">
                {{ (region.title || (getRegionWidget(region) && getRegionWidget(region).name) || 'Widget này') + ' đang nạp dữ liệu để trình chiếu.' }}
              </div>
            </div>

            <div v-else-if="isOfficialLiveWidget(getRegionWidget(region))" class="wf-admission-widget wf-admission-widget--canvas">
              <div class="wf-admission-widget__note wf-admission-widget__note--inline">
                <strong>Widget report dashboard:</strong> đây là widget hệ thống dùng nguồn chính quy, dành cho insight tuyển sinh trong present mode.
              </div>
              <div class="wf-admission-widget__grid">
                <div class="wf-admission-widget__panel">
                  <div class="wf-admission-widget__panel-title">Quy mô nền học sinh Đồng Nai</div>
                  <div class="wf-admission-real-stat-grid">
                    <div v-for="entry in getRegionWidget(region).officialHighlights" :key="entry.label" class="wf-admission-real-stat">
                      <div class="wf-admission-real-stat__label">{{ entry.label }}</div>
                      <div class="wf-admission-real-stat__value">{{ entry.value }}</div>
                      <div class="wf-admission-real-stat__meta">{{ entry.meta }}</div>
                    </div>
                  </div>
                  <div class="wf-admission-widget__panel-title">Học sinh theo cấp học</div>
                  <div class="wf-admission-level-list">
                    <div v-for="entry in getRegionWidget(region).officialLevelRows" :key="entry.level" class="wf-admission-level-item">
                      <div class="wf-admission-level-item__top">
                        <div>
                          <div class="wf-admission-level-item__title">{{ entry.level }}</div>
                          <div class="wf-admission-level-item__meta">{{ entry.schools }} trường</div>
                        </div>
                        <div class="wf-admission-level-item__value">{{ entry.students }}</div>
                      </div>
                      <div class="wf-admission-level-item__bar">
                        <div class="wf-admission-level-item__bar-fill" :style="{ width: entry.share + '%' }"></div>
                      </div>
                      <div class="wf-admission-level-item__share">{{ entry.shareLabel }}</div>
                    </div>
                  </div>
                </div>
                <div class="wf-admission-widget__panel">
                  <div class="wf-admission-widget__panel-title">Nguồn chính thức</div>
                  <div class="wf-admission-source-list">
                    <div v-for="entry in getRegionWidget(region).officialSourceLinks" :key="entry.label" class="wf-admission-source-item">
                      <div>
                        <div class="wf-admission-source-item__title">{{ entry.label }}</div>
                        <div class="wf-admission-source-item__meta">{{ entry.meta }}</div>
                      </div>
                      <v-btn class="wf-btn" variant="outlined" color="primary" size="small" :href="entry.url" target="_blank">
                        <v-icon start size="14">mdi-open-in-new</v-icon>
                        Mở nguồn
                      </v-btn>
                    </div>
                  </div>
                  <div class="wf-admission-widget__panel-title">Google Trends live</div>
                  <div class="wf-admission-source-list">
                    <div v-for="entry in getRegionWidget(region).officialTrendLinks" :key="entry.label" class="wf-admission-source-item">
                      <div>
                        <div class="wf-admission-source-item__title">{{ entry.label }}</div>
                        <div class="wf-admission-source-item__meta">{{ entry.meta }}</div>
                      </div>
                      <v-btn class="wf-btn" variant="outlined" color="primary" size="small" :href="entry.url" target="_blank">
                        <v-icon start size="14">mdi-chart-line</v-icon>
                        Xem live
                      </v-btn>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-else-if="isKpiWidget(getRegionWidget(region))" class="wf-report-kpi-stage wf-report-kpi-stage--dashboard">
              <div class="wf-report-kpi-stage__hero">
                <span class="wf-report-kpi-stage__label">{{ widgetMetricLabel(getRegionWidget(region)) }}</span>
                <strong>{{ widgetKpiValue(getRegionWidget(region)) }}</strong>
              </div>
            </div>

            <div v-else-if="isProgressListWidget(getRegionWidget(region))" class="wf-report-progress-list wf-report-progress-list--dashboard">
              <div v-for="item in (getRegionWidget(region).previewRows || [])" :key="item.label" class="wf-report-progress-item">
                <div class="wf-report-progress-item__head">
                  <strong>{{ item.label }}</strong>
                  <span>{{ formatNumber(item.value) }}</span>
                </div>
                <div class="wf-report-progress-item__track">
                  <div class="wf-report-progress-item__bar" :style="{ width: widgetProgressWidth(getRegionWidget(region), item) }"></div>
                </div>
                <div class="wf-report-progress-item__meta">
                  <span>{{ item.share }}% tỷ trọng</span>
                  <span :class="item.delta >= 0 ? 'wf-text-pos' : 'wf-text-neg'">{{ item.delta >= 0 ? '+' : '' }}{{ item.delta }}%</span>
                </div>
              </div>
            </div>

            <div v-else-if="isDataTableWidget(getRegionWidget(region))" class="wf-report-matrix-wrap wf-report-matrix-wrap--dashboard">
              <table
                class="wf-report-matrix-table wf-report-matrix-table--dashboard"
                :class="{ 'wf-report-matrix-table--freeze-first': tableFreezeFirstColumn(getRegionWidget(region)) }"
              >
                <thead>
                  <tr>
                    <th
                      v-for="(column, columnIndex) in buildTableColumns(getRegionWidget(region))"
                      :key="column.key"
                      :style="tableColumnStyle(getRegionWidget(region), column)"
                      :class="{ 'wf-report-matrix-table__sticky': tableFreezeFirstColumn(getRegionWidget(region)) && columnIndex === 0 }"
                    >{{ column.label }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="rowItem in buildTableRows(getRegionWidget(region))" :key="rowItem.__rowKey">
                    <td
                      v-for="(column, columnIndex) in buildTableColumns(getRegionWidget(region))"
                      :key="column.key"
                      :class="tableCellClass(column, rowItem)"
                      :style="tableColumnStyle(getRegionWidget(region), column)"
                      :data-sticky="tableFreezeFirstColumn(getRegionWidget(region)) && columnIndex === 0 ? '1' : '0'"
                    >{{ formatTableValue(rowItem[column.key]) }}</td>
                  </tr>
                </tbody>
                <tfoot>
                  <tr class="wf-report-table-footer">
                    <td
                      v-for="(column, columnIndex) in buildTableColumns(getRegionWidget(region))"
                      :key="'footer-' + column.key"
                      :style="tableColumnStyle(getRegionWidget(region), column)"
                      :data-sticky="tableFreezeFirstColumn(getRegionWidget(region)) && columnIndex === 0 ? '1' : '0'"
                    >
                      {{ formatTableValue(buildTableFooter(getRegionWidget(region))[column.key]) }}
                    </td>
                  </tr>
                </tfoot>
              </table>
              <div v-if="buildTableAllRows(getRegionWidget(region)).length" class="wf-report-table-pager">
                <div class="wf-report-table-pager__summary">{{ buildTablePageText(getRegionWidget(region)) }}</div>
                <div class="wf-report-table-pager__actions">
                  <v-select
                    class="wf-report-table-pager__size"
                    :items="tablePageSizeOptions"
                    :model-value="resolveTablePageSize(getRegionWidget(region))"
                    density="compact"
                    hide-details
                    variant="outlined"
                    @update:model-value="setTablePageSize(getRegionWidget(region), $event)"
                  ></v-select>
                  <v-btn
                    class="wf-btn"
                    variant="outlined"
                    color="primary"
                    size="small"
                    :disabled="resolveTablePageIndex(getRegionWidget(region)) <= 1"
                    @click="setTablePage(getRegionWidget(region), resolveTablePageIndex(getRegionWidget(region)) - 1)"
                  >
                    <v-icon start size="14">mdi-chevron-left</v-icon>
                    Trước
                  </v-btn>
                  <div class="wf-report-table-pager__page">
                    Trang {{ resolveTablePageIndex(getRegionWidget(region)) }} / {{ buildTablePageCount(getRegionWidget(region)) }}
                  </div>
                  <v-btn
                    class="wf-btn"
                    variant="outlined"
                    color="primary"
                    size="small"
                    :disabled="resolveTablePageIndex(getRegionWidget(region)) >= buildTablePageCount(getRegionWidget(region))"
                    @click="setTablePage(getRegionWidget(region), resolveTablePageIndex(getRegionWidget(region)) + 1)"
                  >
                    Sau
                    <v-icon end size="14">mdi-chevron-right</v-icon>
                  </v-btn>
                </div>
              </div>
            </div>

            <div v-else-if="isMatrixWidget(getRegionWidget(region))" class="wf-report-matrix-wrap wf-report-matrix-wrap--dashboard">
              <table class="wf-report-matrix-table wf-report-matrix-table--dashboard">
                <thead>
                  <tr>
                    <th v-for="column in buildWidgetMatrixColumns(getRegionWidget(region))" :key="column.key">{{ column.label }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="rowItem in buildWidgetMatrixRows(getRegionWidget(region))" :key="rowItem.sourceIndex">
                    <td v-for="column in buildWidgetMatrixColumns(getRegionWidget(region))" :key="column.key" :class="matrixCellClass(column, rowItem)">
                      {{ formatMatrixValue(rowItem[column.key], column.type) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div v-else :id="getChartDomId(getRegionWidget(region))" class="wf-report-chart wf-report-chart--dashboard-canvas"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-report-dashboard-view-page",
  mixins: [window.__WF_REPORT_DASHBOARD_VIEW_MIXIN__ || {}]
	}
</script>

<style scoped>
.wf-report-present-page {
  min-height: 100vh;
  padding: 20px 32px 28px 24px;
  background: #f6f8fb;
  font-family: "Be Vietnam Pro", sans-serif;
  box-sizing: border-box;
  overflow-x: hidden;
}

.wf-report-present-toolbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.wf-report-present-toolbar h1 {
  margin: 0;
  font-size: 24px;
  line-height: 1.15;
}

.wf-report-present-filters {
  display: grid;
  grid-template-columns: minmax(180px, 220px) minmax(180px, 220px) auto;
  gap: 12px;
  align-items: start;
  margin-bottom: 16px;
}

.wf-report-present-page .wf-report-canvas-grid {
  display: grid;
  gap: 18px;
  min-width: 0;
}

.wf-report-present-page .wf-report-section-card {
  padding: 14px;
  border: 1px solid #e4e8eb;
  border-radius: 8px;
  background: #fff;
  box-shadow: 0 10px 24px rgba(21, 39, 58, 0.06);
  min-width: 0;
  max-width: 100%;
  overflow: hidden;
}

.wf-report-present-page .wf-report-section-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}

.wf-report-present-page .wf-report-section-card__title-block {
  display: grid;
  gap: 2px;
}

.wf-report-present-page .wf-report-section-card__head h3 {
  margin: 0;
  font-size: 14px;
  line-height: 1.3;
  font-weight: 700;
}

.wf-report-present-page .wf-report-canvas-row {
  display: flex;
  align-items: stretch;
  gap: 16px;
  min-width: 0;
  max-width: 100%;
}

.wf-report-present-page .wf-report-widget {
  padding: 16px;
  background: #fff;
  border: 1px solid #dfe5ea;
  border-radius: 8px;
  min-width: 0;
  max-width: 100%;
  overflow: hidden;
}

.wf-report-present-page .wf-report-widget--canvas {
  min-height: 360px;
  display: flex;
  flex-direction: column;
}

.wf-report-present-page .wf-report-widget--auto-height {
  min-height: 0;
}

.wf-report-present-page .wf-report-widget--progress-runtime {
  align-self: flex-start;
}

.wf-report-present-page .wf-report-widget__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  min-width: 0;
  max-width: 100%;
}

.wf-report-present-page .wf-report-widget__head h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  overflow-wrap: anywhere;
}

.wf-report-present-page .wf-report-widget__head-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  flex-shrink: 0;
  justify-content: flex-end;
  max-width: 100%;
}

.wf-report-present-page .wf-report-matrix-wrap {
  overflow: auto;
  min-width: 0;
  max-width: 100%;
}

.wf-report-present-page .wf-report-chart--dashboard-canvas {
  height: 260px;
}

.wf-report-present-page .wf-report-progress-list--dashboard {
  gap: 10px;
}

.wf-report-present-page .wf-report-progress-item {
  padding: 10px 12px;
}

@media (max-width: 960px) {
  .wf-report-present-toolbar {
    flex-direction: column;
  }

  .wf-report-present-filters {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 900px) {
  .wf-report-present-page .wf-report-canvas-row,
  .wf-report-present-page .wf-report-section-card__head,
  .wf-report-present-page .wf-report-widget__head {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>