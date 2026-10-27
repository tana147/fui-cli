<template>
	<uc-wf-shell>
    <div class="wf-page-header">
      <div>
        <h1>Nguồn dữ liệu</h1>
        <p>Đây là bước 1 của flow Power BI mini: tạo nguồn dữ liệu trước, sau đó sang thiết kế widget và cuối cùng ghép lên bảng điều khiển.</p>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isLoading" @click="loadDatasets">
          <v-icon start>mdi-refresh</v-icon>
          Tải lại
        </v-btn>
      </div>
    </div>

    <div class="wf-report-dataset-layout">
      <div class="wf-report-step-strip">
        <div class="wf-report-step-card wf-report-step-card--active">
          <div class="wf-report-step-card__index">1</div>
          <div>
            <div class="wf-audit-title">Tạo nguồn dữ liệu</div>
            <div class="wf-audit-sub">Chọn DB nội bộ, upload file CSV/Excel hoặc đăng ký dataset từ API/store.</div>
          </div>
        </div>
        <div class="wf-report-step-card">
          <div class="wf-report-step-card__index">2</div>
          <div>
            <div class="wf-audit-title">Thiết kế widget</div>
            <div class="wf-audit-sub">Chọn chart, cách nhóm dữ liệu, metric và xem trước kết quả.</div>
          </div>
        </div>
        <div class="wf-report-step-card">
          <div class="wf-report-step-card__index">3</div>
          <div>
            <div class="wf-audit-title">Đưa lên dashboard</div>
            <div class="wf-audit-sub">Ghim widget vào bảng điều khiển cá nhân hoặc màn tổng hợp.</div>
          </div>
        </div>
      </div>

      <div class="wf-tcard wf-report-source-tabs-card">
        <div class="wf-report-source-tabs">
          <button
            type="button"
            class="wf-report-source-tab"
            :class="{ 'wf-report-source-tab--active': createSourceTab === 'FILE' }"
            @click="createSourceTab = 'FILE'"
          >
            <span>Thêm dataset từ file</span>
            <v-chip size="x-small" color="primary" variant="tonal">MVP</v-chip>
          </button>
          <button
            type="button"
            class="wf-report-source-tab"
            :class="{ 'wf-report-source-tab--active': createSourceTab === 'API' }"
            @click="createSourceTab = 'API'"
          >
            <span>Thêm dataset từ API/store</span>
            <v-chip size="x-small" color="primary" variant="tonal">Phase 1+</v-chip>
          </button>
        </div>

        <div class="wf-report-upload-body" v-if="createSourceTab === 'FILE'">
          <div class="wf-report-upload-note">
            <div class="wf-audit-title">Nguồn hỗ trợ</div>
            <div class="wf-audit-sub">CSV sẽ tự nhận diện cột ở dòng đầu và preview vài dòng mẫu ngay trên màn này. XLS/XLSX hiện mới lưu metadata trước, phần map sheet/schema sẽ đi ở phase tiếp theo.</div>
          </div>

          <div class="wf-report-form-grid">
            <v-text-field
              v-model="uploadForm.datasetName"
              label="Tên dataset"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-textarea
              v-model="uploadForm.description"
              label="Mô tả dataset"
              variant="outlined"
              density="compact"
              hide-details="auto"
              rows="2"
            />
          </div>

          <div class="wf-report-upload-actions">
            <input
              ref="datasetFileInput"
              type="file"
              class="wf-hidden-input"
              accept=".csv,.xls,.xlsx"
              @change="onFileSelected"
            />
            <v-btn class="wf-btn" variant="outlined" color="primary" @click="triggerFileDialog">
              <v-icon start>mdi-paperclip</v-icon>
              Chọn file CSV/XLS/XLSX
            </v-btn>
            <div class="wf-audit-sub" v-if="uploadForm.sourceFileName">
              {{ uploadForm.sourceFileName }} · {{ uploadForm.sourceKind }}
            </div>
          </div>

          <div class="wf-report-upload-status" v-if="uploadForm.sourceFileName">
            <div class="wf-report-upload-status__item">
              <strong>{{ uploadForm.sourceKind }}</strong>
              <span>Loại nguồn</span>
            </div>
            <div class="wf-report-upload-status__item">
              <strong>{{ detectedColumns.length }}</strong>
              <span>Cột nhận diện</span>
            </div>
            <div class="wf-report-upload-status__item">
              <strong>{{ uploadHintText }}</strong>
              <span>Trạng thái schema</span>
            </div>
          </div>

          <div class="wf-report-upload-note" v-if="isExcelUploadSelected">
            <div class="wf-audit-title">Excel sẽ đọc sheet và header sơ bộ ngay trên màn này</div>
            <div class="wf-audit-sub">Hệ thống sẽ lấy workbook, cho bạn chọn sheet và nhận diện header để dựng schema sơ bộ. Preview chart cho Excel vẫn sẽ nối ở bước tiếp theo.</div>
          </div>

          <div class="wf-report-form-grid" v-if="isExcelUploadSelected && excelSheetOptions.length > 0">
            <v-select
              v-model="selectedExcelSheet"
              :items="excelSheetOptions"
              label="Sheet dữ liệu"
              variant="outlined"
              density="compact"
              hide-details="auto"
              @update:model-value="onExcelSheetChanged"
            />
            <div class="wf-report-upload-note">
              <div class="wf-audit-title">Workbook đã nhận diện {{ excelSheetOptions.length }} sheet</div>
              <div class="wf-audit-sub">Đang dùng sheet `{{ selectedExcelSheet || excelSheetOptions[0] }}` để lấy header và vài dòng mẫu đầu tiên.</div>
            </div>
          </div>

          <div class="wf-tcard wf-report-column-card" v-if="detectedColumns.length > 0">
            <div class="wf-trow wf-trow-header wf-report-column-grid">
              <div>Cột dữ liệu</div>
              <div>Field key</div>
              <div>Kiểu dữ liệu</div>
            </div>
            <div v-for="column in detectedColumns" :key="column.FieldKey" class="wf-trow wf-report-column-grid">
              <div>{{ column.FieldLabel }}</div>
              <div class="wf-audit-sub">{{ column.FieldKey }}</div>
              <div>{{ column.DataType }}</div>
            </div>
          </div>

          <div class="wf-tcard wf-report-column-card" v-if="sampleRows.length > 0">
            <div class="wf-tcard-toolbar">
              <h3>Xem trước dữ liệu file</h3>
              <div class="wf-audit-sub">Đang hiển thị {{ sampleRows.length }} dòng đầu để bạn kiểm tra đúng file trước khi tạo dataset.</div>
            </div>
            <div class="wf-report-sample-table-wrap">
              <table class="wf-report-sample-table">
                <thead>
                  <tr>
                    <th v-for="column in detectedColumns" :key="'head-' + column.FieldKey">{{ column.FieldLabel }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, rowIndex) in sampleRows" :key="'row-' + rowIndex">
                    <td v-for="column in detectedColumns" :key="column.FieldKey + '-' + rowIndex">
                      {{ row[column.FieldKey] }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="wf-report-upload-actions">
            <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isUploading" @click="createFileDataset">
              <v-icon start>mdi-upload-outline</v-icon>
              {{ fileActionLabel }}
            </v-btn>
            <div class="wf-audit-sub">{{ fileActionHint }}</div>
          </div>

          <div class="wf-report-upload-actions" v-if="lastCreatedDatasetCode">
            <v-btn class="wf-btn" variant="outlined" color="primary" @click="openBuilderForDataset(lastCreatedDatasetCode)">
              <v-icon start>mdi-chart-box-outline</v-icon>
              Mở thiết kế widget cho dataset vừa tạo
            </v-btn>
            <div class="wf-audit-sub">{{ lastCreatedDatasetHint }}</div>
          </div>
        </div>

        <div class="wf-report-upload-body" v-else>
          <div class="wf-report-upload-note">
            <div class="wf-audit-title">Contract metadata</div>
            <div class="wf-audit-sub">Dùng khi nguồn dữ liệu đến từ API/store nội bộ hoặc HTTP API. Bạn có thể truyền URL, param, header, token để test call API, lấy response mẫu và map cột thành field metadata cho dataset.</div>
          </div>

          <div class="wf-report-form-grid">
            <v-text-field
              v-model="apiDatasetForm.datasetName"
              label="Tên dataset"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-select
              v-model="apiDatasetForm.requestMode"
              :items="apiRequestModeOptions"
              label="Kiểu nguồn API"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-model="apiDatasetForm.apiCode"
              label="API endpoint code"
              placeholder="Ví dụ: WF_Report_Source_ContractVolume"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-if="apiDatasetForm.requestMode === 'STORE'"
              v-model="apiDatasetForm.sourceProcedureName"
              label="Stored procedure / nguồn gọi"
              placeholder="Ví dụ: spAPI_WF_Report_Source_ContractVolume"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-if="apiDatasetForm.requestMode === 'STORE'"
              v-model="apiDatasetForm.detailSourceProcedureName"
              label="Stored procedure detail source"
              placeholder="Ví dụ: spAPI_WF_Report_Source_ContractVolume_Detail"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-textarea
              v-model="apiDatasetForm.description"
              label="Mô tả dataset"
              variant="outlined"
              density="compact"
              hide-details="auto"
              rows="2"
            />
          </div>

          <div class="wf-report-upload-note" v-if="apiDatasetForm.requestMode === 'HTTP'">
            <div class="wf-audit-title">Test call HTTP API</div>
            <div class="wf-audit-sub">Browser sẽ gọi trực tiếp API để lấy response mẫu. Nếu API chặn CORS hoặc yêu cầu auth đặc biệt, bước test có thể fail dù URL/param đúng.</div>
          </div>

          <div class="wf-report-form-grid" v-if="apiDatasetForm.requestMode === 'HTTP'">
            <v-select
              v-model="apiDatasetForm.httpMethod"
              :items="apiHttpMethodOptions"
              label="HTTP method"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-model="apiDatasetForm.requestUrl"
              label="Request URL"
              placeholder="https://domain/api/endpoint"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-model="apiDatasetForm.responseDataPath"
              label="Đường dẫn mảng dữ liệu trong response"
              placeholder="Ví dụ: data.items"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-model="apiDatasetForm.authHeaderName"
              label="Tên header auth"
              placeholder="Authorization"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-text-field
              v-model="apiDatasetForm.authScheme"
              label="Auth scheme"
              placeholder="Bearer"
              variant="outlined"
              density="compact"
              hide-details="auto"
            />
            <v-textarea
              v-model="apiDatasetForm.authToken"
              label="Token / API key (nếu có)"
              variant="outlined"
              density="compact"
              hide-details="auto"
              rows="2"
            />
          </div>

          <div class="wf-tcard wf-report-column-card" v-if="apiDatasetForm.requestMode === 'HTTP'">
            <div class="wf-tcard-toolbar">
              <h3>Query params / form params</h3>
              <div class="wf-report-header-actions">
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="addApiRequestParamRow()">
                  <v-icon start size="14">mdi-plus</v-icon>
                  Thêm param
                </v-btn>
              </div>
            </div>
            <div v-if="apiDatasetForm.requestParams.length > 0">
              <div v-for="(row, index) in apiDatasetForm.requestParams" :key="'api-param-' + index" class="wf-report-formula-row">
                <v-text-field
                  v-model="row.Key"
                  label="Param key"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-text-field
                  v-model="row.Value"
                  label="Param value"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="removeApiRequestParamRow(index)">
                  <v-icon start size="14">mdi-delete-outline</v-icon>
                  Xóa
                </v-btn>
              </div>
            </div>
            <div v-else class="wf-report-empty-state">
              <strong>Chưa có param</strong>
              <div>Thêm param nếu API cần query string hoặc body input đơn giản.</div>
            </div>
          </div>

          <div class="wf-tcard wf-report-column-card" v-if="apiDatasetForm.requestMode === 'HTTP'">
            <div class="wf-tcard-toolbar">
              <h3>Headers bổ sung</h3>
              <div class="wf-report-header-actions">
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="addApiHeaderRow()">
                  <v-icon start size="14">mdi-plus</v-icon>
                  Thêm header
                </v-btn>
              </div>
            </div>
            <div v-if="apiDatasetForm.headers.length > 0">
              <div v-for="(row, index) in apiDatasetForm.headers" :key="'api-header-' + index" class="wf-report-formula-row">
                <v-text-field
                  v-model="row.Key"
                  label="Header key"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-text-field
                  v-model="row.Value"
                  label="Header value"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="removeApiHeaderRow(index)">
                  <v-icon start size="14">mdi-delete-outline</v-icon>
                  Xóa
                </v-btn>
              </div>
            </div>
            <div v-else class="wf-report-empty-state">
              <strong>Chưa có header bổ sung</strong>
              <div>Bạn có thể để trống nếu API chỉ cần token hoặc query params.</div>
            </div>
          </div>

          <div class="wf-report-form-grid" v-if="apiDatasetForm.requestMode === 'HTTP' && apiDatasetForm.httpMethod !== 'GET'">
            <v-textarea
              v-model="apiDatasetForm.requestBody"
              label="Request body JSON"
              placeholder='Ví dụ: {"page":1,"size":50}'
              variant="outlined"
              density="compact"
              hide-details="auto"
              rows="4"
            />
          </div>

          <div class="wf-report-upload-actions" v-if="apiDatasetForm.requestMode === 'HTTP'">
            <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isTestingApiDataset" @click="testApiDatasetSource">
              <v-icon start>mdi-api</v-icon>
              Test API và nhận diện cột
            </v-btn>
            <div class="wf-audit-sub">Sau khi test thành công, hệ thống sẽ suy ra cột từ response mẫu và điền metadata để bạn chỉnh lại vai trò/dữ liệu.</div>
          </div>

          <div class="wf-tcard wf-report-column-card" v-if="apiDatasetForm.requestMode === 'HTTP' && apiTestColumns.length > 0">
            <div class="wf-tcard-toolbar">
              <h3>Cột nhận diện từ API response</h3>
              <div class="wf-audit-sub">{{ apiTestRows.length }} dòng mẫu · {{ apiTestColumns.length }} cột</div>
            </div>
            <div class="wf-trow wf-trow-header wf-report-column-grid">
              <div>Cột dữ liệu</div>
              <div>Field key</div>
              <div>Kiểu dữ liệu</div>
            </div>
            <div v-for="column in apiTestColumns" :key="'api-preview-' + column.FieldKey" class="wf-trow wf-report-column-grid">
              <div>{{ column.FieldLabel }}</div>
              <div class="wf-audit-sub">{{ column.FieldKey }}</div>
              <div>{{ column.DataType }}</div>
            </div>
          </div>

          <div class="wf-tcard wf-report-column-card" v-if="apiDatasetForm.requestMode === 'HTTP' && apiTestRows.length > 0">
            <div class="wf-tcard-toolbar">
              <h3>Xem trước response API</h3>
              <div class="wf-audit-sub">Hiển thị vài dòng đầu sau khi áp dụng response path.</div>
            </div>
            <div class="wf-report-sample-table-wrap">
              <table class="wf-report-sample-table">
                <thead>
                  <tr>
                    <th v-for="column in apiTestColumns" :key="'api-head-' + column.FieldKey">{{ column.FieldLabel }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, rowIndex) in apiTestRows" :key="'api-row-' + rowIndex">
                    <td v-for="column in apiTestColumns" :key="'api-cell-' + column.FieldKey + '-' + rowIndex">{{ row[column.FieldKey] }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="wf-report-upload-status">
            <div class="wf-report-upload-status__item">
              <strong>{{ apiReadyFieldCount }}</strong>
              <span>Field sẵn sàng</span>
            </div>
            <div class="wf-report-upload-status__item">
              <strong>{{ apiDimensionCount }}</strong>
              <span>Dimension</span>
            </div>
            <div class="wf-report-upload-status__item">
              <strong>{{ apiMetricCount }}</strong>
              <span>Metric</span>
            </div>
          </div>

          <div class="wf-tcard wf-report-column-card">
            <div class="wf-tcard-toolbar">
              <div>
                <h3>Khai báo field metadata</h3>
                <div class="wf-audit-sub">`Dimension` là cột dùng để nhóm/phân loại dữ liệu như phòng ban, trạng thái, ngày. `Metric` là cột số dùng để đếm, cộng, trung bình hoặc tính KPI.</div>
              </div>
              <div class="wf-report-header-actions">
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="addApiFieldRow('DIMENSION')">
                  <v-icon start size="14">mdi-plus</v-icon>
                  Thêm dimension
                </v-btn>
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="addApiFieldRow('METRIC')">
                  <v-icon start size="14">mdi-plus</v-icon>
                  Thêm metric
                </v-btn>
              </div>
            </div>

            <div v-if="apiDatasetForm.fields.length > 0">
              <div v-for="(field, index) in apiDatasetForm.fields" :key="'api-field-' + index" class="wf-report-formula-row">
                <v-text-field
                  v-model="field.FieldLabel"
                  label="Tên field"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                  @blur="syncApiFieldKey(index)"
                />
                <v-text-field
                  v-model="field.FieldKey"
                  label="Field key"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-select
                  v-model="field.FieldRole"
                  :items="fieldRoleOptions"
                  label="Vai trò"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-select
                  v-model="field.DataType"
                  :items="dataTypeOptions"
                  label="Kiểu dữ liệu"
                  variant="outlined"
                  density="compact"
                  hide-details="auto"
                />
                <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click="removeApiFieldRow(index)">
                  <v-icon start size="14">mdi-delete-outline</v-icon>
                  Xóa
                </v-btn>
              </div>
            </div>
            <div v-else class="wf-report-empty-state">
              <strong>Chưa có field nào</strong>
              <div>Khai báo tối thiểu 1 dimension hoặc 1 metric để builder có thể hiểu metadata dataset.</div>
            </div>
          </div>

          <div class="wf-report-upload-actions">
            <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSavingApiDataset" @click="createApiDataset">
              <v-icon start>mdi-database-plus-outline</v-icon>
              Lưu dataset API/store
            </v-btn>
            <div class="wf-audit-sub">Dataset API/store sẽ được lưu theo user hiện tại và hiện ngay trong catalog nguồn dữ liệu. Với HTTP API, metadata request sẽ nằm trong `SourceConfigJson` để phase sau tiếp tục nối preview runtime.</div>
          </div>
        </div>
      </div>

      <div class="wf-tcard">
        <div class="wf-trow wf-trow-header wf-report-dataset-grid">
          <div>Dataset</div>
          <div>Nguồn</div>
          <div>Schema</div>
          <div>Field</div>
          <div>Quyền dùng</div>
          <div>Hành động</div>
        </div>
        <div v-for="item in datasets" :key="item.code" class="wf-trow wf-report-dataset-grid">
          <div>
            <div class="wf-audit-title">{{ item.name }}</div>
            <div class="wf-audit-sub">{{ item.code }}</div>
            <div class="wf-audit-sub" v-if="item.fileName">{{ item.fileName }}</div>
            <div class="wf-audit-sub" v-if="item.apiCode">{{ item.apiCode }}</div>
            <div class="wf-audit-sub" v-if="item.apiRequestUrl">{{ item.apiRequestUrl }}</div>
            <div class="wf-audit-sub" v-if="item.sourceProcedureName">{{ item.sourceProcedureName }}</div>
            <div class="wf-audit-sub" v-if="item.detailSourceProcedureName">{{ item.detailSourceProcedureName }}</div>
          </div>
          <div>
            <v-chip size="x-small" :color="item.sourceKind === 'API' ? '#335c9b' : (item.datasetType === 'FILE' ? '#7b5e10' : '#217D46')" variant="tonal">
              {{ item.datasetTypeLabel }}
            </v-chip>
            <div class="wf-audit-sub mt-1">{{ item.sourceLabel }}</div>
          </div>
          <div>
            <div class="wf-audit-title">{{ item.schemaLabel }}</div>
            <div class="wf-audit-sub">{{ item.description }}</div>
          </div>
          <div>
            <div class="wf-audit-title">{{ item.dimensions }}</div>
            <div class="wf-audit-sub">Metric: {{ item.metrics }}</div>
          </div>
          <div>
            <div class="wf-audit-title">{{ item.ownerLabel }}</div>
            <div class="wf-audit-sub" v-if="item.canPreview">Có thể preview ngay trong widget builder</div>
            <div class="wf-audit-sub" v-else>Builder đã đọc metadata, preview engine sẽ nối theo contract nguồn này</div>
          </div>
          <div class="wf-report-dataset-actions">
            <v-btn class="wf-btn" size="small" variant="outlined" color="primary" @click.stop="openBuilderForDataset(item.code)">
              <v-icon start>mdi-chart-box-outline</v-icon>
              Thiết kế widget
            </v-btn>
            <v-btn
              v-if="item.canDelete"
              class="wf-btn"
              size="small"
              variant="outlined"
              color="primary"
              :loading="deletingDatasetCode === item.code"
              @click.stop="confirmDeleteDataset(item)"
            >
              <v-icon start>mdi-delete-outline</v-icon>
              Xóa dataset
            </v-btn>
          </div>
        </div>
      </div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: "uc-report-dataset-page",
  data: function () {
    return {
      isLoading: false,
      isUploading: false,
      isSavingApiDataset: false,
      isTestingApiDataset: false,
      deletingDatasetCode: "",
      selectedFile: null,
      detectedColumns: [],
      sampleRows: [],
      lastCreatedDatasetCode: "",
      excelWorkbook: null,
      excelSheetOptions: [],
      selectedExcelSheet: "",
      fieldRoleOptions: [
        { title: "Dimension", value: "DIMENSION" },
        { title: "Metric", value: "METRIC" }
      ],
      dataTypeOptions: [
        { title: "Chuỗi", value: "string" },
        { title: "Số", value: "number" },
        { title: "Ngày", value: "date" },
        { title: "DateTime", value: "datetime" },
        { title: "Boolean", value: "boolean" }
      ],
      apiRequestModeOptions: [
        { title: "Store nội bộ", value: "STORE" },
        { title: "HTTP API", value: "HTTP" }
      ],
      apiHttpMethodOptions: ["GET", "POST", "PUT", "PATCH"],
      createSourceTab: "FILE",
      uploadForm: {
        datasetName: "",
        description: "",
        sourceKind: "",
        sourceFileName: "",
        sourceContentType: "",
        sourceFileID: ""
      },
      apiDatasetForm: {
        datasetName: "",
        description: "",
        requestMode: "STORE",
        apiCode: "",
        sourceProcedureName: "",
        detailSourceProcedureName: "",
        requestUrl: "",
        httpMethod: "GET",
        responseDataPath: "",
        authHeaderName: "Authorization",
        authScheme: "Bearer",
        authToken: "",
        requestBody: "",
        requestParams: [],
        headers: [],
        fields: []
      },
      apiTestColumns: [],
      apiTestRows: [],
      datasets: []
    }
  },
  computed: {
    uploadHintText: function () {
      if (!this.uploadForm.sourceKind) {
        return "Chưa có file";
      }
      if (this.uploadForm.sourceKind === "CSV") {
        return this.detectedColumns.length > 0 ? "CSV đã nhận diện cột" : "CSV chưa đọc được header";
      }
      if (this.detectedColumns.length > 0) {
        return "Excel đã nhận diện sheet/header";
      }
      return "Excel chưa đọc được sheet/header";
    },
    isExcelUploadSelected: function () {
      return this.uploadForm.sourceKind === "XLS" || this.uploadForm.sourceKind === "XLSX";
    },
    fileActionLabel: function () {
      return this.isExcelUploadSelected ? "Lưu metadata và tạo dataset" : "Upload và tạo dataset";
    },
    fileActionHint: function () {
      return this.isExcelUploadSelected
        ? "Dataset Excel sau khi tạo sẽ lưu workbook metadata, sheet đã chọn và schema sơ bộ từ header."
        : "Dataset file sau khi tạo sẽ hiện trong kho nguồn dữ liệu của riêng bạn.";
    },
    lastCreatedDatasetHint: function () {
      return this.isExcelUploadSelected
        ? "Dataset Excel đã được đăng ký với sheet và schema sơ bộ. Builder sẽ dùng metadata này ở bước tiếp theo."
        : "Nếu là dataset file, builder sẽ giải thích rõ trạng thái hỗ trợ hiện tại.";
    },
    apiReadyFieldCount: function () {
      return this.buildApiFieldPayload().length;
    },
    apiDimensionCount: function () {
      var count = 0;
      this.buildApiFieldPayload().forEach(function (item) {
        if (item.FieldRole === "DIMENSION") {
          count += 1;
        }
      });
      return count;
    },
    apiMetricCount: function () {
      var count = 0;
      this.buildApiFieldPayload().forEach(function (item) {
        if (item.FieldRole === "METRIC") {
          count += 1;
        }
      });
      return count;
    }
  },
  mounted: function () {
    this.resetApiDatasetForm();
    this.loadDatasets();
  },
  methods: {
    loadDatasets: function () {
      var self = this;
      self.isLoading = true;
      apiCallAsync("WF_ReportDataset_GetList", {
        Keyword: "",
        OnlyActive: 1
      }).then(function (resultSets) {
        var rows = resultSets && resultSets[0] ? resultSets[0] : [];
        var fields = resultSets && resultSets[1] ? resultSets[1] : [];
        self.datasets = rows.map(function (item) {
          var ownFields = fields.filter(function (field) {
            return field.DatasetCode === item.DatasetCode;
          });
          return {
            code: item.DatasetCode,
            name: item.DatasetName,
            description: item.Description || "",
            datasetType: item.DatasetType || "DB",
            datasetTypeLabel: self.buildDatasetTypeLabel(item),
            sourceLabel: self.buildSourceLabel(item),
            schemaLabel: self.buildSchemaLabel(item),
            dimensions: ownFields.filter(function (field) { return field.FieldRole === "DIMENSION"; }).map(function (field) { return field.FieldLabel; }).join(", ") || "-",
            metrics: ownFields.filter(function (field) { return field.FieldRole === "METRIC"; }).map(function (field) { return field.FieldLabel; }).join(", ") || "-",
            ownerLabel: self.buildOwnerLabel(item),
            ownerUserID: item.OwnerUserID || "",
            canPreview: item.CanPreview === true || item.CanPreview === 1,
            canDelete: self.canDeleteDataset(item),
            fileName: item.SourceFileName || "",
            apiCode: item.SourceApiCode || "",
            sourceProcedureName: item.SourceProcedureName || "",
            detailSourceProcedureName: item.DetailSourceProcedureName || "",
            sourceConfig: self.tryParseJsonObject(item.SourceConfigJson, {}),
            apiRequestUrl: ""
          };
        }).map(function (item) {
          item.apiRequestUrl = item.sourceConfig && item.sourceConfig.RequestUrl ? item.sourceConfig.RequestUrl : "";
          return item;
        });
      }).catch(function () {
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được danh mục nguồn dữ liệu widget.");
        }
      }).finally(function () {
        self.isLoading = false;
      });
    },
    buildDatasetTypeLabel: function (item) {
      if ((item.SourceKind || "") === "API") {
        return "API/store";
      }
      if ((item.DatasetType || "DB") === "FILE") {
        return "File upload";
      }
      return "DB nội bộ";
    },
    buildSourceLabel: function (item) {
      if ((item.SourceKind || "") === "API") {
        return (item.SourceApiCode || item.SourceProcedureName) ? String(item.SourceApiCode || item.SourceProcedureName) : "API/store nội bộ";
      }
      if ((item.DatasetType || "DB") !== "FILE") {
        return "Stored procedure / workflow DB";
      }
      if (item.SourceKind === "CSV") {
        return "CSV upload cá nhân";
      }
      if (item.SourceKind === "XLS" || item.SourceKind === "XLSX") {
        return "Excel upload cá nhân";
      }
      return "File upload cá nhân";
    },
    buildOwnerLabel: function (item) {
      if ((item.SourceKind || "") === "API" || (item.DatasetType || "DB") === "FILE") {
        return item.OwnerUserName || item.OwnerUserID || "Dùng chung toàn hệ";
      }
      return "Dùng chung toàn hệ";
    },
    buildSchemaLabel: function (item) {
      if ((item.SourceKind || "") === "API") {
        return item.SchemaStatus === "READY" ? "READY" : (item.SchemaStatus || "REGISTERED");
      }
      if ((item.DatasetType || "DB") !== "FILE") {
        return "READY";
      }
      if (item.SchemaStatus === "READY") {
        return "READY";
      }
      if (item.SchemaStatus === "PENDING_SCHEMA") {
        return "Chờ map schema";
      }
      return item.SchemaStatus || "-";
    },
    canDeleteDataset: function (item) {
      var datasetType = String(item.DatasetType || item.DatasetTypeLabel || "").toUpperCase();
      var sourceKind = String(item.SourceKind || "").toUpperCase();
      var ownerUserID = String(item.OwnerUserID || "").trim();
      if (datasetType !== "FILE" && sourceKind !== "API") {
        return false;
      }
      return ownerUserID !== "";
    },
    confirmDeleteDataset: function (item) {
      var self = this;
      if (!item || !item.code) {
        return;
      }
      if (typeof showConfirm === "undefined") {
        self.deleteDataset(item);
        return;
      }
      showConfirm(
        "Bạn có chắc muốn xóa dataset `" + item.name + "`? Hệ thống sẽ xóa mềm dataset và metadata field của nguồn này.",
        function () {
          self.deleteDataset(item);
        }
      );
    },
    deleteDataset: function (item) {
      var self = this;
      if (!item || !item.code) {
        return;
      }
      self.deletingDatasetCode = item.code;
      apiCallAsync("WF_ReportDataset_Delete", {
        DatasetCode: item.code
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã xóa dataset.");
        }
        if (self.lastCreatedDatasetCode === item.code) {
          self.lastCreatedDatasetCode = "";
        }
        self.loadDatasets();
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không xóa được dataset.");
        }
      }).finally(function () {
        self.deletingDatasetCode = "";
      });
    },
    triggerFileDialog: function () {
      if (this.$refs.datasetFileInput && this.$refs.datasetFileInput.click) {
        this.$refs.datasetFileInput.click();
      }
    },
    onFileSelected: function (event) {
      var input = event && event.target ? event.target : null;
      var file = input && input.files && input.files[0] ? input.files[0] : null;
      if (!file) {
        return;
      }
      this.prepareSelectedFile(file);
      if (input) {
        input.value = "";
      }
    },
    prepareSelectedFile: function (file) {
      var self = this;
      self.selectedFile = file;
      self.uploadForm.sourceFileName = file.name || "";
      self.uploadForm.sourceContentType = file.type || "";
      self.uploadForm.sourceKind = self.detectSourceKind(file.name || "");
      self.uploadForm.sourceFileID = "";
      self.lastCreatedDatasetCode = "";
      self.excelWorkbook = null;
      self.excelSheetOptions = [];
      self.selectedExcelSheet = "";
      if (!self.uploadForm.datasetName) {
        self.uploadForm.datasetName = self.buildDefaultDatasetName(file.name || "dataset");
      }
      if (self.uploadForm.sourceKind === "CSV") {
        self.parseCsvPreview(file).then(function (preview) {
          var columns = preview && preview.columns ? preview.columns : [];
          self.detectedColumns = columns;
          self.sampleRows = preview && preview.rows ? preview.rows : [];
          if (columns.length === 0 && typeof showToast !== "undefined") {
            showToast.info("CSV đã upload nhưng chưa đọc được dòng header. Bạn vẫn có thể lưu metadata file.");
          }
        }).catch(function () {
          self.detectedColumns = [];
          self.sampleRows = [];
          if (typeof showToast !== "undefined") {
            showToast.error("Không đọc được header CSV. Bạn có thể chọn lại file hoặc tiếp tục lưu metadata.");
          }
        });
        return;
      }
      self.parseExcelPreview(file).then(function (preview) {
        self.excelWorkbook = preview && preview.workbook ? preview.workbook : null;
        self.excelSheetOptions = preview && preview.sheetNames ? preview.sheetNames : [];
        self.selectedExcelSheet = self.excelSheetOptions.length > 0 ? self.excelSheetOptions[0] : "";
        self.applyExcelSheetPreview(self.selectedExcelSheet);
      }).catch(function () {
        self.detectedColumns = [];
        self.sampleRows = [];
        self.excelWorkbook = null;
        self.excelSheetOptions = [];
        self.selectedExcelSheet = "";
        if (typeof showToast !== "undefined") {
          showToast.error("Không đọc được workbook Excel. Bạn có thể chọn lại file hoặc tiếp tục lưu metadata file.");
        }
      });
    },
    onExcelSheetChanged: function () {
      this.applyExcelSheetPreview(this.selectedExcelSheet);
    },
    createFileDataset: function () {
      var self = this;
      if (!self.selectedFile) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần chọn file CSV/XLS/XLSX trước.");
        }
        return;
      }
      if (!String(self.uploadForm.datasetName || "").trim()) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần nhập tên dataset trước khi lưu.");
        }
        return;
      }
      self.isUploading = true;
      self.uploadFileToFileData(self.selectedFile).then(function (fileRow) {
        self.uploadForm.sourceFileID = fileRow.FileID || "";
        return apiCallAsync("WF_ReportDataset_SaveFile", {
          DatasetName: self.uploadForm.datasetName,
          Description: self.uploadForm.description,
          SourceKind: self.uploadForm.sourceKind,
          SourceFileID: self.uploadForm.sourceFileID,
          SourceFileName: self.uploadForm.sourceFileName,
          SourceContentType: self.uploadForm.sourceContentType,
          Columns: self.detectedColumns,
          SourceMeta: {
            fileSize: self.selectedFile && self.selectedFile.size ? self.selectedFile.size : 0,
            fileExtension: self.getFileExtension(self.uploadForm.sourceFileName),
            schemaMode: self.uploadForm.sourceKind === "CSV" ? "AUTO_HEADER" : (self.detectedColumns.length > 0 ? "AUTO_SELECTED_SHEET_HEADER" : "PENDING_MANUAL_MAPPING"),
            selectedSheetName: self.selectedExcelSheet || "",
            sheetNames: self.excelSheetOptions
          }
        });
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        self.lastCreatedDatasetCode = row && row.DatasetCode ? row.DatasetCode : "";
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã tạo dataset file.");
        }
        self.loadDatasets();
        self.resetUploadForm();
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không tạo được dataset file.");
        }
      }).finally(function () {
        self.isUploading = false;
      });
    },
    createApiDataset: function () {
      var self = this;
      var fields = self.buildApiFieldPayload();
      if (!String(self.apiDatasetForm.datasetName || "").trim()) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần nhập tên dataset API/store.");
        }
        return;
      }
      if (!String(self.apiDatasetForm.apiCode || "").trim()) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần nhập API endpoint code.");
        }
        return;
      }
      if (self.apiDatasetForm.requestMode === "HTTP" && !String(self.apiDatasetForm.requestUrl || "").trim()) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần nhập Request URL để đăng ký dataset HTTP API.");
        }
        return;
      }
      if (fields.length === 0) {
        if (typeof showToast !== "undefined") {
          showToast.error("Bạn cần khai báo ít nhất một field metadata cho dataset API/store.");
        }
        return;
      }
      self.isSavingApiDataset = true;
      apiCallAsync("WF_ReportDataset_SaveApi", {
        DatasetName: self.apiDatasetForm.datasetName,
        Description: self.apiDatasetForm.description,
        SourceApiCode: self.apiDatasetForm.apiCode,
        SourceProcedureName: self.apiDatasetForm.requestMode === "STORE" ? self.apiDatasetForm.sourceProcedureName : "",
        DetailSourceProcedureName: self.apiDatasetForm.requestMode === "STORE" ? self.apiDatasetForm.detailSourceProcedureName : "",
        Fields: fields,
        SourceMeta: {
          contract: "REPORT_DATASET_API",
          previewMode: self.apiDatasetForm.requestMode === "STORE" ? "STORE_RUNTIME" : "HTTP_CONTRACT_ONLY",
          requestMode: self.apiDatasetForm.requestMode,
          requestUrl: self.apiDatasetForm.requestUrl,
          httpMethod: self.apiDatasetForm.httpMethod,
          responseDataPath: self.apiDatasetForm.responseDataPath,
          authHeaderName: self.apiDatasetForm.authHeaderName,
          authScheme: self.apiDatasetForm.authScheme,
          authToken: self.apiDatasetForm.authToken,
          requestBody: self.parseApiRequestBodySafe(self.apiDatasetForm.requestBody),
          requestParams: self.buildSimpleKeyValuePayload(self.apiDatasetForm.requestParams),
          headers: self.buildSimpleKeyValuePayload(self.apiDatasetForm.headers),
          sampleColumns: self.apiTestColumns,
          sampleRows: self.apiTestRows
        }
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        self.lastCreatedDatasetCode = row && row.DatasetCode ? row.DatasetCode : "";
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã tạo dataset API/store.");
        }
        self.loadDatasets();
        self.resetApiDatasetForm();
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không tạo được dataset API/store.");
        }
      }).finally(function () {
        self.isSavingApiDataset = false;
      });
    },
    addApiFieldRow: function (role) {
      this.apiDatasetForm.fields.push({
        FieldLabel: "",
        FieldKey: "",
        FieldRole: role || "DIMENSION",
        DataType: role === "METRIC" ? "number" : "string"
      });
    },
    addApiRequestParamRow: function () {
      this.apiDatasetForm.requestParams.push({
        Key: "",
        Value: ""
      });
    },
    removeApiRequestParamRow: function (index) {
      this.apiDatasetForm.requestParams.splice(index, 1);
    },
    addApiHeaderRow: function () {
      this.apiDatasetForm.headers.push({
        Key: "",
        Value: ""
      });
    },
    removeApiHeaderRow: function (index) {
      this.apiDatasetForm.headers.splice(index, 1);
    },
    removeApiFieldRow: function (index) {
      this.apiDatasetForm.fields.splice(index, 1);
      if (this.apiDatasetForm.fields.length === 0) {
        this.addApiFieldRow("DIMENSION");
      }
    },
    syncApiFieldKey: function (index) {
      var row = this.apiDatasetForm.fields[index];
      if (!row) {
        return;
      }
      if (!String(row.FieldKey || "").trim()) {
        row.FieldKey = this.sanitizeFieldKey(row.FieldLabel || "", index + 1);
      } else {
        row.FieldKey = this.sanitizeFieldKey(row.FieldKey || "", index + 1);
      }
    },
    buildApiFieldPayload: function () {
      var seen = {};
      return (this.apiDatasetForm.fields || []).map(function (item, index) {
        var fieldLabel = String(item.FieldLabel || "").trim();
        var fieldKey = this.sanitizeFieldKey(item.FieldKey || item.FieldLabel || "", index + 1);
        var fieldRole = item.FieldRole === "METRIC" ? "METRIC" : "DIMENSION";
        var dataType = String(item.DataType || "").toLowerCase();
        if (["number", "date", "datetime", "boolean"].indexOf(dataType) < 0) {
          dataType = "string";
        }
        if (!fieldLabel) {
          return null;
        }
        if (seen[fieldKey]) {
          seen[fieldKey] += 1;
          fieldKey = fieldKey + "_" + seen[fieldKey];
        } else {
          seen[fieldKey] = 1;
        }
        return {
          FieldLabel: fieldLabel,
          FieldKey: fieldKey,
          FieldRole: fieldRole,
          DataType: dataType
        };
      }, this).filter(function (item) {
        return item !== null;
      });
    },
    buildSimpleKeyValuePayload: function (rows) {
      return (rows || []).map(function (item) {
        return {
          Key: String(item && item.Key ? item.Key : "").trim(),
          Value: String(item && item.Value ? item.Value : "").trim()
        };
      }).filter(function (item) {
        return item.Key !== "";
      });
    },
    parseApiRequestBodySafe: function (raw) {
      var text = String(raw || "").trim();
      if (!text) {
        return null;
      }
      try {
        return JSON.parse(text);
      } catch (err) {
        return text;
      }
    },
    testApiDatasetSource: function () {
      var self = this;
      self.isTestingApiDataset = true;
      self.callApiDatasetSource().then(function (payload) {
        var resolved = self.extractApiResponseRows(payload, self.apiDatasetForm.responseDataPath);
        var columns = self.inferColumnsFromApiRows(resolved.rows);
        self.apiTestColumns = columns;
        self.apiTestRows = self.buildApiSampleRows(columns, resolved.rows);
        self.applyApiColumnsToFieldMetadata(columns);
        if (typeof showToast !== "undefined") {
          showToast.success("Đã gọi API và nhận diện " + String(columns.length) + " cột từ response.");
        }
      }).catch(function (err) {
        self.apiTestColumns = [];
        self.apiTestRows = [];
        if (typeof showToast !== "undefined") {
          showToast.error(err && err.message ? err.message : "Không gọi được API để nhận diện schema.");
        }
      }).finally(function () {
        self.isTestingApiDataset = false;
      });
    },
    callApiDatasetSource: function () {
      var self = this;
      var url = String(self.apiDatasetForm.requestUrl || "").trim();
      var method = String(self.apiDatasetForm.httpMethod || "GET").toUpperCase();
      var headers = self.buildApiRequestHeaders();
      var params = self.buildSimpleKeyValuePayload(self.apiDatasetForm.requestParams);
      var bodyPayload = self.parseApiRequestBodySafe(self.apiDatasetForm.requestBody);
      var controller = null;
      var timeoutId = 0;
      if (!url) {
        return Promise.reject(new Error("Bạn cần nhập Request URL."));
      }
      if (typeof AbortController !== "undefined") {
        controller = new AbortController();
        timeoutId = window.setTimeout(function () {
          controller.abort();
        }, 15000);
      }
      return self.fetchApiResponse(url, {
        method: method,
        headers: headers,
        params: params,
        body: bodyPayload,
        controller: controller
      }).finally(function () {
        if (timeoutId) {
          window.clearTimeout(timeoutId);
        }
      });
    },
    fetchApiResponse: function (url, options) {
      var method = options && options.method ? options.method : "GET";
      var params = options && options.params ? options.params : [];
      var requestUrl = this.buildApiRequestUrl(url, params, method);
      var requestInit = {
        method: method,
        headers: options && options.headers ? options.headers : {}
      };
      if (options && options.controller && options.controller.signal) {
        requestInit.signal = options.controller.signal;
      }
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
          requestInit.body = JSON.stringify(this.buildApiParamObject(params));
          if (!requestInit.headers["Content-Type"] && !requestInit.headers["content-type"]) {
            requestInit.headers["Content-Type"] = "application/json";
          }
        }
      }
      return fetch(requestUrl, requestInit).then(function (response) {
        if (!response.ok) {
          throw new Error("API trả về HTTP " + String(response.status) + ".");
        }
        return response.text().then(function (text) {
          if (!text) {
            return [];
          }
          try {
            return JSON.parse(text);
          } catch (err) {
            throw new Error("Response không phải JSON hợp lệ để map schema.");
          }
        });
      }).catch(function (err) {
        if (err && err.name === "AbortError") {
          throw new Error("API timeout sau 15 giây.");
        }
        if (err && err.message) {
          throw err;
        }
        throw new Error("Không gọi được API. Kiểm tra lại URL, token hoặc CORS.");
      });
    },
    buildApiRequestHeaders: function () {
      var self = this;
      var output = {};
      var authToken = String(self.apiDatasetForm.authToken || "").trim();
      var authHeaderName = String(self.apiDatasetForm.authHeaderName || "Authorization").trim();
      var authScheme = String(self.apiDatasetForm.authScheme || "").trim();
      self.buildSimpleKeyValuePayload(self.apiDatasetForm.headers).forEach(function (item) {
        output[item.Key] = item.Value;
      });
      if (authToken && authHeaderName) {
        output[authHeaderName] = authScheme ? (authScheme + " " + authToken) : authToken;
      }
      return output;
    },
    buildApiRequestUrl: function (baseUrl, params, method) {
      var url = String(baseUrl || "").trim();
      var queryParts = [];
      if (String(method || "GET").toUpperCase() !== "GET") {
        return url;
      }
      params.forEach(function (item) {
        queryParts.push(encodeURIComponent(item.Key) + "=" + encodeURIComponent(item.Value));
      });
      if (queryParts.length === 0) {
        return url;
      }
      return url + (url.indexOf("?") >= 0 ? "&" : "?") + queryParts.join("&");
    },
    buildApiParamObject: function (params) {
      var output = {};
      params.forEach(function (item) {
        output[item.Key] = item.Value;
      });
      return output;
    },
    extractApiResponseRows: function (payload, responsePath) {
      var target = payload;
      var segments = String(responsePath || "").trim();
      var rows = [];
      if (segments) {
        target = this.readValueByPath(payload, segments);
      }
      if ((target === null || target === undefined || target === "") && !segments) {
        target = this.detectDefaultApiDataNode(payload);
      }
      if ((target === null || target === undefined || target === "") && segments) {
        target = this.detectDefaultApiDataNode(payload);
      }
      target = this.unwrapApiRowsCandidate(target);
      if (typeof target === "string") {
        target = this.tryParseJsonObject(target, target);
        target = this.unwrapApiRowsCandidate(target);
      }
      if (Array.isArray(target)) {
        rows = target;
      } else if (target && typeof target === "object") {
        rows = [target];
      } else {
        rows = [];
      }
      rows = rows.filter(function (item) {
        return item && typeof item === "object" && !Array.isArray(item);
      });
      rows = this.unwrapWrappedApiRows(rows);
      if (rows.length === 0) {
        throw new Error("Không tìm thấy mảng/object dữ liệu phù hợp trong response để map cột.");
      }
      return {
        rows: rows
      };
    },
    unwrapApiRowsCandidate: function (target) {
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
            wrapper = this.pickWrappedApiNode(current[0]);
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
        wrapper = this.pickWrappedApiNode(current);
        if (wrapper !== null && wrapper !== undefined) {
          current = wrapper;
          continue;
        }
        return current;
      }
      return current;
    },
    unwrapWrappedApiRows: function (rows) {
      var wrapped = this.unwrapApiRowsCandidate(rows);
      if (Array.isArray(wrapped)) {
        return wrapped.filter(function (item) {
          return item && typeof item === "object" && !Array.isArray(item);
        });
      }
      if (wrapped && typeof wrapped === "object" && !Array.isArray(wrapped)) {
        return [wrapped];
      }
      return [];
    },
    pickWrappedApiNode: function (node) {
      var candidates = ["data", "items", "result", "results", "list", "rows"];
      var keys = [];
      var matchedKey = "";
      var idx = 0;
      if (!node || typeof node !== "object" || Array.isArray(node)) {
        return null;
      }
      keys = Object.keys(node);
      for (idx = 0; idx < candidates.length; idx += 1) {
        matchedKey = this.findObjectKeyCaseInsensitive(node, candidates[idx]);
        if (matchedKey && (Array.isArray(node[matchedKey]) || (node[matchedKey] && typeof node[matchedKey] === "object"))) {
          return node[matchedKey];
        }
      }
      if (keys.length === 1 && (Array.isArray(node[keys[0]]) || (node[keys[0]] && typeof node[keys[0]] === "object"))) {
        return node[keys[0]];
      }
      return null;
    },
    readValueByPath: function (root, path) {
      var normalized = String(path || "").replace(/^\$\./, "").replace(/^\$/, "").replace(/\[(\d+)\]/g, ".$1");
      var segments = normalized.split(".").filter(function (item) {
        return String(item || "").trim() !== "";
      });
      var current = root;
      var index = 0;
      var segment = "";
      var matchedKey = "";
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
        matchedKey = this.findObjectKeyCaseInsensitive(current, segment);
        if (matchedKey) {
          current = current[matchedKey];
          continue;
        }
        return null;
      }
      return current;
    },
    findObjectKeyCaseInsensitive: function (target, key) {
      var normalized = String(key || "").toLowerCase();
      var objectKeys = [];
      var idx = 0;
      if (!target || typeof target !== "object" || Array.isArray(target)) {
        return "";
      }
      objectKeys = Object.keys(target);
      for (idx = 0; idx < objectKeys.length; idx += 1) {
        if (String(objectKeys[idx] || "").toLowerCase() === normalized) {
          return objectKeys[idx];
        }
      }
      return "";
    },
    detectDefaultApiDataNode: function (payload) {
      var candidates = ["data", "items", "result", "results", "list", "rows"];
      var idx = 0;
      var matchedKey = "";
      if (!payload || typeof payload !== "object") {
        return payload;
      }
      if (Array.isArray(payload)) {
        return payload;
      }
      for (idx = 0; idx < candidates.length; idx += 1) {
        matchedKey = this.findObjectKeyCaseInsensitive(payload, candidates[idx]);
        if (matchedKey && payload[matchedKey] !== undefined) {
          return payload[matchedKey];
        }
      }
      return payload;
    },
    inferColumnsFromApiRows: function (rows) {
      var seen = {};
      var first = rows && rows[0] ? rows[0] : {};
      return Object.keys(first || {}).map(function (key, index) {
        var sanitized = this.sanitizeFieldKey(key, index + 1);
        var dataType = this.inferApiDataType(rows, key);
        if (seen[sanitized]) {
          seen[sanitized] += 1;
          sanitized = sanitized + "_" + seen[sanitized];
        } else {
          seen[sanitized] = 1;
        }
        return {
          FieldKey: sanitized,
          FieldLabel: key,
          DataType: dataType
        };
      }, this);
    },
    inferApiDataType: function (rows, key) {
      var detected = "string";
      var idx = 0;
      var value = null;
      for (idx = 0; idx < (rows || []).length; idx += 1) {
        value = rows[idx] ? rows[idx][key] : null;
        if (value === null || value === undefined || value === "") {
          continue;
        }
        if (typeof value === "number") {
          return "number";
        }
        if (typeof value === "boolean") {
          return "boolean";
        }
        if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}T/.test(value)) {
          return "datetime";
        }
        if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
          return "date";
        }
        detected = "string";
      }
      return detected;
    },
    buildApiSampleRows: function (columns, rows) {
      return (rows || []).slice(0, 5).map(function (rawRow) {
        var output = {};
        columns.forEach(function (column) {
          output[column.FieldKey] = rawRow && rawRow[column.FieldLabel] !== undefined ? rawRow[column.FieldLabel] : "";
        });
        return output;
      });
    },
    tryParseJsonObject: function (input, fallback) {
      if (!input) {
        return fallback || {};
      }
      if (typeof input === "object") {
        return input;
      }
      try {
        return JSON.parse(input);
      } catch (err) {
        return fallback || {};
      }
    },
    applyApiColumnsToFieldMetadata: function (columns) {
      this.apiDatasetForm.fields = (columns || []).map(function (column) {
        return {
          FieldLabel: column.FieldLabel,
          FieldKey: column.FieldKey,
          FieldRole: column.DataType === "number" ? "METRIC" : "DIMENSION",
          DataType: column.DataType
        };
      });
    },
    uploadFileToFileData: function (file) {
      var self = this;
      return new Promise(function (resolve, reject) {
        var reader = new FileReader();
        reader.onload = function (evt) {
          var dataUrl = evt && evt.target ? evt.target.result : "";
          var base64 = "";
          if (!dataUrl || String(dataUrl).indexOf(",") < 0) {
            reject(new Error("READ_FILE_FAILED"));
            return;
          }
          base64 = String(dataUrl).split(",")[1] || "";
          apiCall("UPLOAD_FileData_Base64", {
            FileBase64: base64,
            FileName: file.name || "dataset.csv",
            FileContentType: file.type || self.resolveContentType(self.detectSourceKind(file.name || ""))
          }, function (res) {
            var fileRow = self.pickUploadedFileRow(res);
            if (!fileRow || !fileRow.FileID) {
              reject(new Error("MISSING_FILE_ID"));
              return;
            }
            resolve(fileRow);
          }, function (err) {
            reject(err);
          });
        };
        reader.onerror = function () {
          reject(new Error("READ_FILE_FAILED"));
        };
        reader.readAsDataURL(file);
      });
    },
    parseCsvPreview: function (file) {
      var self = this;
      return new Promise(function (resolve, reject) {
        var reader = new FileReader();
        reader.onload = function (evt) {
          var text = evt && evt.target ? String(evt.target.result || "") : "";
          var rows = self.extractCsvRows(text, 6);
          var headers = rows.length > 0 ? rows[0] : [];
          var columns = self.buildColumnsFromHeaders(headers);
          resolve({
            columns: columns,
            rows: self.buildSampleRows(columns, rows.slice(1))
          });
        };
        reader.onerror = function () {
          reject(new Error("READ_CSV_FAILED"));
        };
        reader.readAsText(file, "utf-8");
      });
    },
    ensureXlsxLibLoaded: function () {
      return new Promise(function (resolve, reject) {
        var existing = null;
        if (window.XLSX) {
          resolve(window.XLSX);
          return;
        }
        existing = document.getElementById("wf-report-xlsx-lib");
        if (existing) {
          existing.addEventListener("load", function () {
            if (window.XLSX) {
              resolve(window.XLSX);
            } else {
              reject(new Error("XLSX_LIB_NOT_READY"));
            }
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
    parseExcelPreview: function (file) {
      var self = this;
      return self.ensureXlsxLibLoaded().then(function (XLSX) {
        return new Promise(function (resolve, reject) {
          var reader = new FileReader();
          reader.onload = function (evt) {
            try {
              var data = evt && evt.target ? evt.target.result : null;
              var workbook = XLSX.read(data, { type: "array" });
              resolve({
                workbook: workbook,
                sheetNames: workbook && workbook.SheetNames ? workbook.SheetNames : []
              });
            } catch (err) {
              reject(err);
            }
          };
          reader.onerror = function () {
            reject(new Error("READ_XLSX_FAILED"));
          };
          reader.readAsArrayBuffer(file);
        });
      });
    },
    applyExcelSheetPreview: function (sheetName) {
      var workbook = this.excelWorkbook;
      var rows = [];
      var headers = [];
      var worksheet = null;
      if (!workbook || !window.XLSX) {
        this.detectedColumns = [];
        this.sampleRows = [];
        return;
      }
      worksheet = workbook.Sheets[sheetName];
      if (!worksheet) {
        this.detectedColumns = [];
        this.sampleRows = [];
        return;
      }
      rows = window.XLSX.utils.sheet_to_json(worksheet, {
        header: 1,
        raw: false,
        defval: ""
      }) || [];
      headers = rows.length > 0 ? rows[0].map(function (value) {
        return String(value || "").trim();
      }) : [];
      this.detectedColumns = this.buildColumnsFromHeaders(headers);
      this.sampleRows = this.buildSampleRows(this.detectedColumns, rows.slice(1, 6));
    },
    extractCsvRows: function (text, maxRows) {
      var normalized = String(text || "").replace(/^\uFEFF/, "");
      var lines = normalized.split(/\r?\n/);
      var index = 0;
      var rows = [];
      for (index = 0; index < lines.length; index += 1) {
        if (String(lines[index] || "").trim()) {
          rows.push(this.parseCsvLine(lines[index]));
        }
        if (rows.length >= (maxRows || 6)) {
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
      }).filter(function (value) {
        return value !== "";
      });
    },
    buildColumnsFromHeaders: function (headers) {
      var seen = {};
      return headers.map(function (header, index) {
        var fieldKey = this.sanitizeFieldKey(header, index + 1);
        if (seen[fieldKey]) {
          seen[fieldKey] += 1;
          fieldKey = fieldKey + "_" + seen[fieldKey];
        } else {
          seen[fieldKey] = 1;
        }
        return {
          FieldKey: fieldKey,
          FieldLabel: header,
          DataType: "string"
        };
      }, this);
    },
    buildSampleRows: function (columns, rawRows) {
      return rawRows.map(function (rawRow) {
        var row = {};
        columns.forEach(function (column, index) {
          row[column.FieldKey] = rawRow[index] !== undefined ? rawRow[index] : "";
        });
        return row;
      });
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
    buildDefaultDatasetName: function (fileName) {
      var name = String(fileName || "dataset").replace(/\.[^/.]+$/, "");
      return "Dataset file - " + name;
    },
    detectSourceKind: function (fileName) {
      var ext = this.getFileExtension(fileName);
      if (ext === "xlsx") return "XLSX";
      if (ext === "xls") return "XLS";
      return "CSV";
    },
    getFileExtension: function (fileName) {
      var raw = String(fileName || "").toLowerCase();
      var parts = raw.split(".");
      return parts.length > 1 ? parts[parts.length - 1] : "";
    },
    resolveContentType: function (sourceKind) {
      if (sourceKind === "XLSX") {
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      }
      if (sourceKind === "XLS") {
        return "application/vnd.ms-excel";
      }
      return "text/csv";
    },
    pickUploadedFileRow: function (payload) {
      var queue = [];
      var visited = [];
      var node = null;
      var fileId = "";
      var key = "";
      if (!payload || typeof payload !== "object") {
        return null;
      }
      queue.push(payload);
      while (queue.length > 0) {
        node = queue.shift();
        if (!node || typeof node !== "object") {
          continue;
        }
        if (visited.indexOf(node) >= 0) {
          continue;
        }
        visited.push(node);
        fileId = String(node.FileID || node.fileId || node.FILE_ID || "").trim();
        if (fileId) {
          return {
            FileID: fileId,
            FileName: String(node.FileName || node.fileName || node.FILE_NAME || "").trim(),
            FileUrl: String(node.FileUrl || node.fileUrl || node.FILE_URL || "").trim()
          };
        }
        if (Array.isArray(node)) {
          node.forEach(function (child) {
            if (child && typeof child === "object") {
              queue.push(child);
            }
          });
          continue;
        }
        for (key in node) {
          if (Object.prototype.hasOwnProperty.call(node, key) && node[key] && typeof node[key] === "object") {
            queue.push(node[key]);
          }
        }
      }
      return null;
    },
    openBuilderForDataset: function (datasetCode) {
      if (!datasetCode) {
        return;
      }
      window.location.href = "/wf-report-builder?dataset=" + encodeURIComponent(datasetCode);
    },
    resetUploadForm: function () {
      this.selectedFile = null;
      this.detectedColumns = [];
      this.sampleRows = [];
      this.excelWorkbook = null;
      this.excelSheetOptions = [];
      this.selectedExcelSheet = "";
      this.uploadForm = {
        datasetName: "",
        description: "",
        sourceKind: "",
        sourceFileName: "",
        sourceContentType: "",
        sourceFileID: ""
      };
    },
    resetApiDatasetForm: function () {
      this.apiDatasetForm = {
        datasetName: "",
        description: "",
        requestMode: "STORE",
        apiCode: "",
        sourceProcedureName: "",
        detailSourceProcedureName: "",
        requestUrl: "",
        httpMethod: "GET",
        responseDataPath: "",
        authHeaderName: "Authorization",
        authScheme: "Bearer",
        authToken: "",
        requestBody: "",
        requestParams: [],
        headers: [],
        fields: []
      };
      this.apiTestColumns = [];
      this.apiTestRows = [];
      this.addApiFieldRow("DIMENSION");
      this.addApiFieldRow("METRIC");
    }
  }
	}
</script>