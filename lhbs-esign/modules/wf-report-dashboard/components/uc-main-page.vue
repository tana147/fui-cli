<template>
	<uc-wf-shell>
    <div
      class="wf-report-runtime-marker"
      data-report-dashboard-component-version="2026-03-21-component-row-layout-v1"
      style="display:none;"
    ></div>
    <div class="wf-page-header">
      <div>
        <h1>Bảng điều khiển</h1>
        <p>Ghép nhiều widget KPI, biểu đồ, bảng và matrix vào cùng một canvas gần với cách dùng Power BI.</p>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openDashboardList">
          <v-icon start>mdi-view-dashboard-edit-outline</v-icon>
          Quản lý dashboard
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openPresentView">
          <v-icon start>mdi-presentation-play</v-icon>
          Trình chiếu
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSavingLayout" @click="saveLayout">
          <v-icon start>mdi-content-save-outline</v-icon>
          Lưu bố cục
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openMyReports">
          <v-icon start>mdi-view-grid-plus-outline</v-icon>
          Chọn từ thư viện
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openBuilder">
          <v-icon start>mdi-plus</v-icon>
          Tạo widget
        </v-btn>
      </div>
    </div>

    <div class="wf-stat-strip wf-stat-strip--4">
      <div v-for="card in statCards" :key="card.label" class="wf-stat-pill">
        <div class="wf-stat-icon" :class="card.iconClass"><v-icon>{{ card.icon }}</v-icon></div>
        <div>
          <div class="wf-stat-val">{{ card.value }}</div>
          <div class="wf-stat-lbl">{{ card.label }}</div>
        </div>
      </div>
    </div>

    <div class="wf-report-canvas-toolbar">
      <div>
        <h3>{{ dashboardName }}</h3>
        <p>{{ dashboardSummaryText }}</p>
      </div>
      <div class="wf-report-canvas-toolbar__chips">
        <v-chip size="x-small" color="primary" variant="tonal">Canvas</v-chip>
        <v-chip size="x-small" color="#335c9b" variant="tonal">Chart + Table + Matrix</v-chip>
        <v-select
          v-model="selectedSectionId"
          class="wf-report-layout-select wf-report-layout-select--section"
          :items="dashboardSections"
          item-title="title"
          item-value="sectionId"
          label="Section đang thiết kế"
          variant="outlined"
          density="compact"
          hide-details="auto"
        />
        <v-btn class="wf-btn wf-btn--compact" variant="outlined" color="primary" size="small" @click="openSectionComposer()">
          <v-icon start size="14">mdi-view-sequential-outline</v-icon>
          Section mới
        </v-btn>
        <v-btn class="wf-btn wf-btn--compact" variant="text" color="primary" size="small" :disabled="!selectedSectionId" @click="openSectionComposer(selectedSectionId)">
          <v-icon start size="14">mdi-view-grid-plus-outline</v-icon>
          Layout
        </v-btn>
        <v-btn class="wf-btn wf-btn--compact" variant="text" color="primary" size="small" :disabled="!selectedSectionId" @click="addRegion('compact')">
          <v-icon start size="14">mdi-shape-square-plus</v-icon>
          Thêm vùng
        </v-btn>
      </div>
    </div>

    <div class="wf-tcard wf-report-canvas-filter-card">
      <div class="wf-tcard-toolbar">
        <h3>Bộ lọc chung toàn màn</h3>
        <div class="wf-report-header-actions">
          <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="applyGlobalFilters">
            <v-icon start size="14">mdi-filter-check-outline</v-icon>
            Áp dụng
          </v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="resetGlobalFilters">
            <v-icon start size="14">mdi-filter-off-outline</v-icon>
            Bỏ lọc
          </v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="openWidgetPicker">
            <v-icon start size="14">mdi-plus-box-multiple-outline</v-icon>
            Thêm widget
          </v-btn>
        </div>
      </div>
      <div class="wf-template-dialog-body">
        <v-row dense>
          <v-col cols="12" md="3">
            <v-select
              v-model="globalRange"
              :items="rangeOptions"
              label="Thời gian chung"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="globalStatus"
              :items="statusOptions"
              label="Trạng thái chung"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="2">
            <v-select
              v-model="globalDatasetFilter"
              :items="canvasDatasetOptions"
              label="Lọc dataset"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="2">
            <v-select
              v-model="globalChartFilter"
              :items="canvasChartOptions"
              label="Lọc chart"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="2">
            <v-text-field
              v-model="globalSearchQuery"
              label="Tìm widget"
              variant="outlined"
              density="compact"
              prepend-inner-icon="mdi-magnify"
              hide-details="auto"
            />
          </v-col>
        </v-row>
      </div>
    </div>

    <div v-if="dashboardSections.length === 0" class="wf-empty-state wf-report-dashboard-empty">
      <div class="wf-report-dashboard-empty__icon">
        <v-icon size="34">mdi-view-dashboard-edit-outline</v-icon>
      </div>
      <div class="wf-audit-title">Bảng điều khiển của bạn chưa có section nào.</div>
      <div class="wf-audit-sub">Hãy tạo section trước, chọn layout cho section đó, rồi gắn widget vào từng vùng.</div>
      <div class="wf-report-dashboard-empty__actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="addSection">
          <v-icon start>mdi-view-sequential-outline</v-icon>
          Tạo section đầu tiên
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openBuilder">
          <v-icon start>mdi-plus</v-icon>
          Tạo widget
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openMyReports">
          <v-icon start>mdi-pin-outline</v-icon>
          Mở thư viện widget
        </v-btn>
      </div>
    </div>

    <div v-else class="wf-report-canvas-grid">
      <div v-for="section in renderedSections" :key="section.sectionId" class="wf-report-section-card">
        <div class="wf-report-section-card__head">
          <div class="wf-report-section-card__title-block">
            <h3>{{ section.title }}</h3>
            <p>{{ section.regions.length }} vùng</p>
          </div>
          <div class="wf-report-section-card__actions">
            <v-chip v-if="selectedSectionId === section.sectionId" size="x-small" color="primary" variant="tonal">Thiết kế</v-chip>
            <div class="wf-report-section-layout-badge">
              <span class="wf-report-section-layout-badge__label">Mẫu section</span>
              <strong>{{ layoutLabel(section.layoutCode) }}</strong>
            </div>
            <v-tooltip text="Đổi layout section" location="top">
              <template #activator="{ props }">
                <v-btn
                  v-bind="props"
                  class="wf-btn wf-btn--icon-tool"
                  variant="text"
                  color="primary"
                  size="x-small"
                  icon
                  @click="openSectionComposer(section.sectionId)"
                >
                  <v-icon size="15">mdi-view-grid-plus-outline</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
            <v-tooltip text="Chọn section để thêm vùng hoặc gắn widget" location="top">
              <template #activator="{ props }">
                <v-btn
                  v-bind="props"
                  class="wf-btn wf-btn--icon-tool"
                  variant="text"
                  color="primary"
                  size="x-small"
                  icon
                  @click="selectSection(section.sectionId)"
                >
                  <v-icon size="15">mdi-cursor-default-click-outline</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </div>
        </div>
        <div
          v-for="(row, rowIndex) in section.rows"
          :key="section.sectionId + '_row_' + rowIndex"
          class="wf-report-canvas-row"
          :style="canvasRowStyle(row)"
        >
        <div
          v-for="region in row"
          :key="region.regionId || rowIndex"
          class="wf-report-widget wf-report-widget--canvas"
          :class="regionCardClasses(region)"
          :style="regionGridStyle(region, row.length)"
          :data-widget-runtime-key="region.widgetId ? getWidgetRuntimeKey(getRegionWidget(region)) : ''"
          draggable="true"
          @dragstart="handleRegionDragStart(region, $event)"
          @dragend="handleRegionDragEnd"
          @dragover.prevent="handleRegionDragOver(region)"
          @dragenter.prevent="handleRegionDragOver(region)"
          @drop.prevent="handleRegionDrop(region)"
        >
        <div class="wf-report-widget__head">
          <div>
            <h3>{{ region.title || ('Vùng ' + (dashboardRegions.indexOf(region) + 1)) }}</h3>
            <p>{{ regionDescription(region, dashboardRegions.indexOf(region)) }}</p>
          </div>
          <div class="wf-report-widget__head-meta">
            <v-chip size="x-small" color="#335c9b" variant="tonal">{{ region.widgetId ? 'Đã gắn widget' : 'Region trống' }}</v-chip>
            <v-chip size="x-small" :color="regionSizeChipColor(region)" variant="outlined">{{ regionSizeLabel(region) }}</v-chip>
          </div>
        </div>

        <div class="wf-report-widget__toolbar">
          <div class="wf-report-widget__toolbar-text">
            <span>{{ regionHintText(region) }}</span>
            <span>{{ regionUpdatedText(region) }}</span>
          </div>
          <div class="wf-report-widget__toolbar-actions">
            <v-btn icon size="x-small" variant="text" color="primary" :disabled="dashboardRegions.indexOf(region) === dashboardRegions.length - 1" @click="moveRegion(dashboardRegions.indexOf(region), 1)">
              <v-icon size="15">mdi-arrow-right</v-icon>
            </v-btn>
            <v-btn icon size="x-small" variant="text" color="primary" :disabled="dashboardRegions.indexOf(region) === 0" @click="moveRegion(dashboardRegions.indexOf(region), -1)">
              <v-icon size="15">mdi-arrow-left</v-icon>
            </v-btn>
            <v-btn icon size="x-small" variant="text" color="primary" @click="cycleRegionSize(region)">
              <v-icon size="15">mdi-fit-to-page-outline</v-icon>
            </v-btn>
            <v-btn icon size="x-small" variant="text" color="primary" @click="openWidgetPicker(region)">
              <v-icon size="15">mdi-plus-box-outline</v-icon>
            </v-btn>
            <v-btn icon size="x-small" variant="text" color="primary" :disabled="!region.widgetId" @click="openReportDetail(getRegionWidget(region))">
              <v-icon size="15">mdi-open-in-new</v-icon>
            </v-btn>
            <v-btn icon size="x-small" variant="text" color="#c62828" @click="removeRegion(region)">
              <v-icon size="15">mdi-close</v-icon>
            </v-btn>
          </div>
        </div>

        <div v-if="!region.widgetId" class="wf-empty-state wf-report-region-empty">
          <div class="wf-report-dashboard-empty__icon">
            <v-icon size="26">mdi-view-dashboard-edit-outline</v-icon>
          </div>
          <div class="wf-audit-title">Vùng này đang trống</div>
          <div class="wf-audit-sub">Chọn kích thước vùng trước, sau đó bấm Add widget để gắn nội dung vào đây.</div>
          <div class="wf-report-dashboard-empty__actions">
            <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="openWidgetPicker(region)">
              <v-icon start size="14">mdi-plus-box-outline</v-icon>
              Add widget
            </v-btn>
          </div>
        </div>
        <div v-else-if="getRegionWidget(region).isLoading" class="wf-report-widget__loading">
          <div class="wf-report-widget__loading-spinner">
            <v-progress-circular indeterminate size="22" width="2" color="primary"></v-progress-circular>
          </div>
          <div class="wf-report-widget__loading-title">Đang tải widget</div>
          <div class="wf-report-widget__loading-sub">
            {{ (region.title || (getRegionWidget(region) && getRegionWidget(region).name) || 'Widget này') + ' đang nạp dữ liệu và cấu hình hiển thị.' }}
          </div>
        </div>
        <div v-else-if="getRegionWidget(region).error" class="wf-empty-state wf-report-widget__error">
          {{ getRegionWidget(region).error }}
        </div>
        <div v-else-if="!regionMatchesCanvasFilter(region)" class="wf-empty-state wf-report-widget__error">
          Widget trong vùng này đang bị ẩn bởi bộ lọc canvas hiện tại.
        </div>
        <div v-else-if="isOfficialLiveWidget(getRegionWidget(region))" class="wf-admission-widget wf-admission-widget--canvas">
          <div class="wf-admission-widget__note wf-admission-widget__note--inline">
            <strong>Widget report dashboard:</strong> đây là widget hệ thống dùng nguồn chính quy, dành cho insight tuyển sinh thay vì report definition thông thường.
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
            <span class="wf-report-kpi-stage__label">{{ getRegionWidget(region).metricKey || 'KPI' }}</span>
            <strong>{{ formatNumber(getRegionWidget(region).previewSummary && getRegionWidget(region).previewSummary.TotalValue) }}</strong>
            <small>{{ getRegionWidget(region).dataset }}</small>
          </div>
          <div class="wf-report-kpi-stage__meta">
            <div class="wf-report-kpi-stage__meta-item">
              <span>Nhóm tốt nhất</span>
              <strong>{{ getRegionWidget(region).previewSummary && getRegionWidget(region).previewSummary.TopLabel ? getRegionWidget(region).previewSummary.TopLabel : '-' }}</strong>
            </div>
            <div class="wf-report-kpi-stage__meta-item">
              <span>Số nhóm</span>
              <strong>{{ getRegionWidget(region).previewRows ? getRegionWidget(region).previewRows.length : 0 }}</strong>
            </div>
          </div>
        </div>
        <div v-else-if="isProgressListWidget(getRegionWidget(region))" class="wf-report-progress-list wf-report-progress-list--dashboard">
          <div v-for="row in getRegionWidget(region).previewRows" :key="row.label" class="wf-report-progress-item" @click="openReportDetail(getRegionWidget(region), row.label)">
            <div class="wf-report-progress-item__head">
              <strong>{{ row.label }}</strong>
              <span>{{ formatNumber(row.value) }}</span>
            </div>
            <div class="wf-report-progress-item__track">
              <div class="wf-report-progress-item__bar" :style="{ width: widgetProgressWidth(getRegionWidget(region), row) }"></div>
            </div>
            <div class="wf-report-progress-item__meta">
              <span>{{ row.share }}% tỷ trọng</span>
              <span :class="row.delta >= 0 ? 'wf-text-pos' : 'wf-text-neg'">{{ row.delta >= 0 ? '+' : '' }}{{ row.delta }}%</span>
            </div>
          </div>
        </div>
        <div v-else-if="isDataTableWidget(getRegionWidget(region))" class="wf-report-matrix-wrap wf-report-matrix-wrap--dashboard">
          <table
            class="wf-report-matrix-table wf-report-matrix-table--dashboard"
            :class="{ 'wf-report-matrix-table--freeze-first': getRegionWidget(region).tableConfig && getRegionWidget(region).tableConfig.FreezeFirstColumn !== false }"
          >
            <thead>
              <tr>
                <th
                  v-for="(column, columnIndex) in buildWidgetTableColumns(getRegionWidget(region))"
                  :key="column.key"
                  :style="widgetTableColumnStyle(getRegionWidget(region), column)"
                  :class="{ 'wf-report-matrix-table__sticky': (!getRegionWidget(region).tableConfig || getRegionWidget(region).tableConfig.FreezeFirstColumn !== false) && columnIndex === 0 }"
                >{{ column.label }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in buildWidgetTableRows(getRegionWidget(region))" :key="row.__rowKey || row.sourceIndex" @click="openReportDetail(getRegionWidget(region), row.label)">
                <td
                  v-for="(column, columnIndex) in buildWidgetTableColumns(getRegionWidget(region))"
                  :key="column.key"
                  :class="matrixCellClass(column, row)"
                  :style="widgetTableColumnStyle(getRegionWidget(region), column)"
                  :data-sticky="(!getRegionWidget(region).tableConfig || getRegionWidget(region).tableConfig.FreezeFirstColumn !== false) && columnIndex === 0 ? '1' : '0'"
                >
                  {{ formatMatrixValue(row[column.key], column.type) }}
                </td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="wf-report-table-footer">
                <td
                  v-for="(column, columnIndex) in buildWidgetTableColumns(getRegionWidget(region))"
                  :key="'footer-' + column.key"
                  :style="widgetTableColumnStyle(getRegionWidget(region), column)"
                  :data-sticky="(!getRegionWidget(region).tableConfig || getRegionWidget(region).tableConfig.FreezeFirstColumn !== false) && columnIndex === 0 ? '1' : '0'"
                >
                  {{ formatMatrixValue(buildWidgetTableFooter(getRegionWidget(region))[column.key], column.type) }}
                </td>
              </tr>
            </tfoot>
          </table>
          <div v-if="buildWidgetTableAllRows(getRegionWidget(region)).length" class="wf-report-table-pager">
            <div class="wf-report-table-pager__summary">{{ buildWidgetTablePageText(getRegionWidget(region)) }}</div>
            <div class="wf-report-table-pager__actions">
              <v-select
                class="wf-report-table-pager__size"
                :items="tablePageSizeOptions"
                :model-value="resolveWidgetTablePageSize(getRegionWidget(region))"
                density="compact"
                hide-details
                variant="outlined"
                @update:model-value="setWidgetTablePageSize(getRegionWidget(region), $event)"
              ></v-select>
              <v-btn
                class="wf-btn"
                variant="outlined"
                color="primary"
                size="small"
                :disabled="resolveWidgetTablePageIndex(getRegionWidget(region)) <= 1"
                @click="setWidgetTablePage(getRegionWidget(region), resolveWidgetTablePageIndex(getRegionWidget(region)) - 1)"
              >
                <v-icon start size="14">mdi-chevron-left</v-icon>
                Trước
              </v-btn>
              <div class="wf-report-table-pager__page">
                Trang {{ resolveWidgetTablePageIndex(getRegionWidget(region)) }} / {{ buildWidgetTablePageCount(getRegionWidget(region)) }}
              </div>
              <v-btn
                class="wf-btn"
                variant="outlined"
                color="primary"
                size="small"
                :disabled="resolveWidgetTablePageIndex(getRegionWidget(region)) >= buildWidgetTablePageCount(getRegionWidget(region))"
                @click="setWidgetTablePage(getRegionWidget(region), resolveWidgetTablePageIndex(getRegionWidget(region)) + 1)"
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
              <tr v-for="row in buildWidgetMatrixRows(getRegionWidget(region))" :key="row.sourceIndex">
                <td
                  v-for="column in buildWidgetMatrixColumns(getRegionWidget(region))"
                  :key="column.key"
                  :class="matrixCellClass(column, row)"
                >
                  {{ formatMatrixValue(row[column.key], column.type) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else>
          <div :id="getChartDomId(getRegionWidget(region))" class="wf-report-chart wf-report-chart--dashboard-canvas"></div>
        </div>

        <div class="wf-report-widget__footer">
          <template v-if="isOfficialLiveWidget(getRegionWidget(region))">
            <div>
              <strong>Chính quy</strong>
              <span>Nguồn công khai đã xác minh</span>
            </div>
            <div>
              <strong>{{ region.widgetId && getRegionWidget(region).officialSourceLinks ? getRegionWidget(region).officialSourceLinks.length : 0 }}</strong>
              <span>Nguồn/tài liệu</span>
            </div>
            <div>
              <strong>Google Trends</strong>
              <span>Link live cho đội tuyển sinh</span>
            </div>
          </template>
          <template v-else>
            <div>
              <strong>{{ formatNumber(region.widgetId && getRegionWidget(region).previewSummary && getRegionWidget(region).previewSummary.TotalValue) }}</strong>
              <span>Tổng giá trị preview</span>
            </div>
            <div>
              <strong>{{ region.widgetId && getRegionWidget(region).previewRows ? getRegionWidget(region).previewRows.length : 0 }}</strong>
              <span>Số nhóm dữ liệu</span>
            </div>
            <div>
              <strong>{{ region.widgetId && getRegionWidget(region).dimensionKey ? getRegionWidget(region).dimensionKey : '-' }}</strong>
              <span>{{ region.widgetId ? 'Dimension' : 'Vị trí vùng' }}</span>
            </div>
          </template>
        </div>
        </div>
        </div>
      </div>
    </div>

    <v-dialog v-model="isWidgetPickerOpen" max-width="920">
      <v-card class="wf-dialog-card">
        <div class="wf-tcard-toolbar">
          <h3>Thêm widget vào vùng</h3>
          <v-btn icon size="small" variant="text" color="primary" @click="isWidgetPickerOpen = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>
        <div class="wf-template-dialog-body">
          <v-row dense>
            <v-col cols="12" md="8">
              <v-text-field
                v-model="widgetPickerSearch"
                label="Tìm theo tên widget"
                variant="outlined"
                density="compact"
                prepend-inner-icon="mdi-magnify"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-btn class="wf-btn" variant="outlined" color="primary" block @click="loadWidgetLibrary">
                <v-icon start>mdi-refresh</v-icon>
                Tải lại thư viện
              </v-btn>
            </v-col>
          </v-row>

          <div class="wf-report-picker-list">
            <div v-for="item in filteredWidgetLibrary" :key="item.id" class="wf-report-picker-item">
              <div>
                <div class="wf-audit-title">{{ item.name }}</div>
                <div class="wf-audit-sub">{{ item.dataset }} · {{ item.chart }} · {{ item.updatedAt }}</div>
                <div v-if="item.isSystem" class="wf-audit-sub">Widget hệ thống dùng nguồn chính quy và render trực tiếp trên report dashboard.</div>
              </div>
              <div class="wf-report-picker-item__actions">
                <v-chip v-if="item.isSystem" size="x-small" color="#c0841a" variant="tonal">Hệ thống</v-chip>
                <v-chip v-if="item.isPinned" size="x-small" color="#217D46" variant="tonal">Đã có trên canvas</v-chip>
                <v-btn
                  v-else
                  class="wf-btn"
                  variant="outlined"
                  color="primary"
                  size="small"
                  @click="addWidgetToCanvas(item)"
                >
                  <v-icon start size="14">mdi-pin-outline</v-icon>
                  Thêm vào dashboard
                </v-btn>
              </div>
            </div>
            <div v-if="filteredWidgetLibrary.length === 0" class="wf-empty-state">
              <div class="wf-audit-title">Chưa có widget nào để chọn</div>
              <div class="wf-audit-sub">Hãy tạo widget mới hoặc mở thư viện widget để kiểm tra các widget đã lưu.</div>
              <div class="wf-report-dashboard-empty__actions">
                <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="openBuilderFromPicker">
                  <v-icon start size="14">mdi-plus</v-icon>
                  Tạo widget mới
                </v-btn>
                <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="openMyReportsFromPicker">
                  <v-icon start size="14">mdi-file-chart-outline</v-icon>
                  Mở thư viện widget
                </v-btn>
              </div>
            </div>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="isSectionComposerOpen" max-width="1080">
      <v-card class="wf-dialog-card">
        <div class="wf-tcard-toolbar">
          <h3>{{ sectionComposerMode === 'update' ? 'Chỉnh layout section' : 'Thêm section vào dashboard' }}</h3>
          <v-btn icon size="small" variant="text" color="primary" @click="closeSectionComposer">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>
        <div class="wf-template-dialog-body">
          <v-row dense class="mb-2">
            <v-col cols="12" md="5">
              <v-text-field
                v-model="pendingSectionTitle"
                label="Tên section"
                variant="outlined"
                density="compact"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="7">
              <div class="wf-report-section-composer__hint">
                <strong>Chọn một mẫu bố cục trực quan.</strong>
                <span>Mỗi section là một block lớn của dashboard; từng ô con trong block đó sẽ chứa một widget.</span>
              </div>
            </v-col>
          </v-row>

          <div class="wf-report-layout-gallery">
            <button
              v-for="layout in layoutTemplateCards"
              :key="layout.value"
              type="button"
              class="wf-report-layout-card"
              :class="{ 'wf-report-layout-card--active': pendingSectionLayout === layout.value }"
              @click="pendingSectionLayout = layout.value"
            >
              <div class="wf-report-layout-card__preview" :data-layout="layout.value">
                <span v-if="layout.value === 'single'" class="wf-report-layout-card__box wf-report-layout-card__box--full"></span>
                <template v-else-if="layout.value === 'two_equal'">
                  <span class="wf-report-layout-card__box"></span>
                  <span class="wf-report-layout-card__box"></span>
                </template>
                <template v-else-if="layout.value === 'three_equal'">
                  <span class="wf-report-layout-card__box"></span>
                  <span class="wf-report-layout-card__box"></span>
                  <span class="wf-report-layout-card__box"></span>
                </template>
                <template v-else-if="layout.value === 'ratio_1_3'">
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--thin"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--fat"></span>
                </template>
                <template v-else-if="layout.value === 'ratio_3_1'">
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--fat"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--thin"></span>
                </template>
                <template v-else-if="layout.value === 'ratio_1_3_1'">
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--thin"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--fat"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--thin"></span>
                </template>
                <template v-else-if="layout.value === 'ratio_1_4'">
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--thin"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--hero"></span>
                </template>
                <template v-else-if="layout.value === 'hero_two_bottom'">
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--full"></span>
                  <span class="wf-report-layout-card__box"></span>
                  <span class="wf-report-layout-card__box"></span>
                </template>
                <template v-else-if="layout.value === 'two_top_one_bottom'">
                  <span class="wf-report-layout-card__box"></span>
                  <span class="wf-report-layout-card__box"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--full"></span>
                </template>
                <template v-else>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--thin"></span>
                  <span class="wf-report-layout-card__box wf-report-layout-card__box--hero"></span>
                </template>
              </div>
              <div class="wf-report-layout-card__title">{{ layout.title }}</div>
              <div class="wf-report-layout-card__desc">{{ layout.description }}</div>
            </button>
          </div>

          <div class="wf-report-section-composer__actions">
            <v-btn class="wf-btn" variant="outlined" color="primary" @click="closeSectionComposer">
              <v-icon start>mdi-close</v-icon>
              Hủy
            </v-btn>
            <v-btn class="wf-btn" variant="outlined" color="primary" @click="confirmSectionComposer">
              <v-icon start>mdi-check</v-icon>
              {{ sectionComposerMode === 'update' ? 'Cập nhật section' : 'Tạo section và áp layout' }}
            </v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: "uc-report-dashboard-page",
  mixins: [window.__WF_REPORT_DASHBOARD_CANVAS_MIXIN__ || {}]
	}
</script>

<style scoped>
.wf-report-canvas-toolbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 18px;
  margin-bottom: 16px;
  border: 1px solid #e4e8eb;
  border-radius: var(--wf-r-md);
  background: linear-gradient(135deg, #ffffff 0%, #f5fbf7 100%);
}

.wf-report-canvas-toolbar h3 {
  margin: 0 0 4px;
  font-size: 16px;
  line-height: 1.25;
}

.wf-report-canvas-toolbar p {
  margin: 0;
  color: var(--wf-text-2);
  font-size: 12px;
  line-height: 1.5;
}

.wf-report-canvas-toolbar__chips {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.wf-report-layout-select {
  min-width: 200px;
  max-width: 240px;
}

.wf-report-layout-select--section {
  min-width: 210px;
}

.wf-btn--compact {
  min-height: 34px !important;
  padding-inline: 12px !important;
  font-size: 12px !important;
}

.wf-btn--micro {
  min-height: 28px !important;
  padding-inline: 8px !important;
  font-size: 11px !important;
}

.wf-btn--icon-tool {
  width: 28px !important;
  min-width: 28px !important;
  height: 28px !important;
  padding: 0 !important;
  border-radius: 8px !important;
}

.wf-report-canvas-filter-card {
  margin-bottom: 16px;
}

.wf-report-dashboard-empty {
  display: grid;
  justify-items: center;
  gap: 10px;
  padding: 42px 24px;
}

.wf-report-dashboard-empty__icon {
  width: 64px;
  height: 64px;
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #edf7f0;
  color: var(--wf-primary-dark);
}

.wf-report-dashboard-empty__actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: center;
}

.wf-report-section-card {
  padding: 14px;
  border: 1px solid #e4e8eb;
  border-radius: var(--wf-r-md);
  background: #fff;
}

.wf-report-section-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}

.wf-report-section-card__title-block {
  display: grid;
  gap: 2px;
}

.wf-report-section-card__head h3 {
  margin: 0;
  font-size: 14px;
  line-height: 1.3;
  font-weight: 700;
}

.wf-report-section-card__head p {
  margin: 0;
  color: var(--wf-text-2);
  font-size: 11px;
  line-height: 1.4;
}

.wf-report-section-card__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.wf-report-section-layout-badge {
  display: grid;
  gap: 2px;
  min-width: 170px;
  padding: 6px 10px;
  border: 1px solid #d8e3db;
  border-radius: 8px;
  background: #f8fcf9;
}

.wf-report-section-layout-badge__label {
  font-size: 10px;
  color: var(--wf-text-3);
  text-transform: uppercase;
  letter-spacing: .04em;
}

.wf-report-section-layout-badge strong {
  font-size: 12px;
  line-height: 1.35;
  font-weight: 600;
}

.wf-report-section-composer__hint {
  display: grid;
  gap: 4px;
  padding: 10px 12px;
  border: 1px dashed #cfe0d5;
  border-radius: 10px;
  background: #f8fcf9;
  font-size: 12px;
  color: var(--wf-text-2);
}

.wf-report-layout-gallery {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px;
}

.wf-report-layout-card {
  border: 1px solid #dbe3e8;
  border-radius: 14px;
  background: #fff;
  padding: 12px;
  text-align: left;
  transition: border-color .18s ease, box-shadow .18s ease, transform .18s ease;
}

.wf-report-layout-card:hover {
  border-color: #8ab89a;
  box-shadow: 0 8px 18px rgba(22, 59, 34, .08);
  transform: translateY(-1px);
}

.wf-report-layout-card--active {
  border-color: #217D46;
  box-shadow: 0 0 0 2px rgba(33, 125, 70, .12);
  background: linear-gradient(180deg, #ffffff 0%, #f5fbf7 100%);
}

.wf-report-layout-card__preview {
  display: grid;
  gap: 6px;
  min-height: 84px;
  margin-bottom: 12px;
  padding: 10px;
  border-radius: 12px;
  background: linear-gradient(180deg, #eef6f0 0%, #f8fbff 100%);
}

.wf-report-layout-card__preview[data-layout="single"] {
  grid-template-columns: 1fr;
}

.wf-report-layout-card__preview[data-layout="two_equal"],
.wf-report-layout-card__preview[data-layout="ratio_1_3"],
.wf-report-layout-card__preview[data-layout="ratio_3_1"],
.wf-report-layout-card__preview[data-layout="ratio_1_4"],
.wf-report-layout-card__preview[data-layout="sidebar_left_content_right"],
.wf-report-layout-card__preview[data-layout="hero_two_bottom"],
.wf-report-layout-card__preview[data-layout="two_top_one_bottom"] {
  grid-template-columns: 1fr 1fr;
}

.wf-report-layout-card__preview[data-layout="three_equal"],
.wf-report-layout-card__preview[data-layout="ratio_1_3_1"] {
  grid-template-columns: 1fr 1fr 1fr;
}

.wf-report-layout-card__box {
  min-height: 24px;
  border-radius: 8px;
  background: linear-gradient(135deg, #a8d5b6 0%, #4b9a68 100%);
}

.wf-report-layout-card__box--full {
  grid-column: 1 / -1;
}

.wf-report-layout-card__title {
  font-weight: 700;
  color: var(--wf-text-1);
  font-size: 13px;
  line-height: 1.35;
}

.wf-report-layout-card__desc {
  margin-top: 4px;
  font-size: 11px;
  line-height: 1.5;
  color: var(--wf-text-2);
}

.wf-report-section-composer__actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 18px;
}

.wf-report-canvas-grid {
  display: grid;
  gap: 16px;
}

.wf-report-canvas-row {
  display: flex;
  align-items: stretch;
  gap: 16px;
}

.wf-report-widget--canvas {
  grid-column: span 4;
  min-height: 360px;
  display: flex;
  flex-direction: column;
  cursor: grab;
  transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
}

.wf-report-widget--canvas:active {
  cursor: grabbing;
}

.wf-report-widget--dragging {
  opacity: .58;
  transform: scale(.985);
}

.wf-report-widget--drop-target {
  border-color: #217D46;
  box-shadow: 0 0 0 2px rgba(33, 125, 70, .14);
}

.wf-report-widget--compact {
  grid-column: span 4;
}

.wf-report-widget--micro {
  grid-column: span 2;
}

.wf-report-widget--third {
  grid-column: span 3;
}

.wf-report-widget--half {
  grid-column: span 6;
}

.wf-report-widget--wide {
  grid-column: span 8;
}

.wf-report-widget--two-third {
  grid-column: span 8;
}

.wf-report-widget--three-quarter {
  grid-column: span 9;
}

.wf-report-widget--tall {
  grid-column: span 4;
  min-height: 480px;
}

.wf-report-widget--hero {
  grid-column: span 12;
}

.wf-report-widget--five-sixth {
  grid-column: span 10;
}

.wf-report-widget__head-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.wf-report-widget__toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 0 12px;
}

.wf-report-widget__toolbar-text {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  font-size: 11px;
  color: var(--wf-text-3);
}

.wf-report-widget__toolbar-actions {
  display: flex;
  align-items: center;
  gap: 2px;
}

.wf-report-widget__loading,
.wf-report-widget__error {
  min-height: 220px;
}

.wf-report-chart--dashboard-canvas {
  height: 260px;
}

.wf-report-matrix-wrap--dashboard {
  flex: 1;
  min-height: 0;
}

.wf-report-matrix-table--dashboard th,
.wf-report-matrix-table--dashboard td {
  white-space: nowrap;
}

.wf-report-widget__footer {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
  margin-top: auto;
  padding-top: 14px;
  border-top: 1px solid #eef1f4;
}

.wf-report-widget__footer strong {
  display: block;
  font-size: 18px;
  line-height: 1.2;
  color: var(--wf-text-1);
}

.wf-report-widget__footer span {
  display: block;
  margin-top: 4px;
  font-size: 11px;
  color: var(--wf-text-3);
}

.wf-report-picker-list {
  display: grid;
  gap: 10px;
  margin-top: 16px;
}

.wf-report-picker-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 14px;
  border: 1px solid #e6eaee;
  border-radius: var(--wf-r-sm);
  background: #fafbfc;
}

.wf-report-picker-item__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

@media (max-width: 1280px) {
  .wf-report-widget--micro,
  .wf-report-widget--third,
  .wf-report-widget--half,
  .wf-report-widget--compact,
  .wf-report-widget--tall {
    grid-column: span 6;
  }

  .wf-report-widget--two-third,
  .wf-report-widget--three-quarter,
  .wf-report-widget--five-sixth,
  .wf-report-widget--wide,
  .wf-report-widget--hero {
    grid-column: span 12;
  }
}

@media (max-width: 900px) {
  .wf-report-canvas-toolbar,
  .wf-report-widget__toolbar,
  .wf-report-section-card__head,
  .wf-report-section-composer__actions {
    flex-direction: column;
    align-items: stretch;
  }

  .wf-report-canvas-row {
    flex-direction: column;
  }

  .wf-report-layout-select--section,
  .wf-report-section-layout-badge {
    max-width: none;
    min-width: 0;
  }

  .wf-report-widget--compact,
  .wf-report-widget--micro,
  .wf-report-widget--third,
  .wf-report-widget--half,
  .wf-report-widget--two-third,
  .wf-report-widget--three-quarter,
  .wf-report-widget--five-sixth,
  .wf-report-widget--wide,
  .wf-report-widget--tall,
  .wf-report-widget--hero {
    grid-column: auto;
    max-width: 100% !important;
    flex-basis: 100% !important;
  }
}

@media (max-width: 768px) {
  .wf-report-widget__head {
    flex-direction: column;
    align-items: stretch;
  }

  .wf-report-picker-item {
    flex-direction: column;
    align-items: stretch;
  }

  .wf-report-widget__footer {
    grid-template-columns: 1fr;
  }

  .wf-report-dashboard-empty__actions {
    width: 100%;
  }

  .wf-report-layout-gallery {
    grid-template-columns: 1fr;
  }
}
</style>