<template>
	<uc-wf-shell active-key="wf-admin-category" title="Workflow Admin" subtitle="Quản trị hệ thống">
    <div class="wf-page-header">
      <div>
        <h1>Nhóm quy trình ({{ filteredCategories.length }})</h1>
        <p>Phân loại workflow theo nhóm nghiệp vụ. Mỗi category gắn với màu sắc, icon riêng.</p>
      </div>
      <v-btn class="wf-btn" variant="outlined" color="primary" @click="openDialog(null)">
        <v-icon start="">mdi-plus</v-icon>
        Thêm nhóm
      </v-btn>
    </div>

    <uc-table :rounded="false" title="Danh sách nhóm" :show-count="false" :headers="categoryHeaders"
      :items="filteredCategories" :loading="isLoading" item-value="CategoryID" searchable
      search-placeholder="Tìm nhóm..." max-height="calc(100vh - 165px)" :pagination="true" :items-per-page="10">

      <template #item.category="{ item }">
        <div class="d-flex align-center wf-template-title" style="cursor: pointer;" @click.stop="openDialog(item)">
          <div class="wf-request-cat-card__icon mr-3"
            :style="{ background: buildColorLight(item.Color), color: item.Color || 'var(--wf-primary)', width: '34px', height: '34px', borderRadius: '4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }">
            <v-icon size="18">{{ item.Icon || 'mdi-shape-outline' }}</v-icon>
          </div>
          <div>
            <div class="wf-audit-title" style="font-size: 13px; font-weight: 700;">{{ item.Name }}</div>
            <div class="wf-audit-sub">{{ item.Code }}</div>
          </div>
        </div>
      </template>

      <template #item.description="{ item }">
        <span class="wf-audit-meta">{{ item.Description || ('Nhóm quy trình ' + item.Name.toLowerCase()) }}</span>
      </template>

      <template #item.color="{ item }">
        <div class="d-flex align-center ga-2">
          <div class="wf-cat-color-dot"
            :style="{ background: item.Color || '#ccc', width: '10px', height: '10px', borderRadius: '50%', display: 'inline-block' }">
          </div>
          <span style="font-size: 11.5px; color: var(--wf-text-2);">{{ item.Color || '—' }}</span>
        </div>
      </template>

      <template #item.customFields="{ item }">
        <div class="d-flex align-center ga-1 flex-wrap">
          <span class="wf-audit-meta mr-1 font-weight-bold" style="color: var(--wf-primary);">{{
            getCategoryFields(item.CategoryID).length }} trường:</span>
          <v-chip v-for="f in getCategoryFields(item.CategoryID).slice(0, 2)" :key="f.MappingID" size="x-small"
            variant="tonal" color="primary" class="px-1.5" style="height: 18px; font-size: 9.5px;">
            {{ f.FieldLabel || f.FieldName }}
          </v-chip>
          <span v-if="getCategoryFields(item.CategoryID).length > 2" class="text-caption text-grey"
            style="font-size: 9.5px;">
            +{{ getCategoryFields(item.CategoryID).length - 2 }}
          </span>
        </div>
      </template>

      <template #item.status="{ item }">
        <v-chip size="x-small" :color="isCategoryActive(item) ? 'primary' : 'grey'"
          :variant="isCategoryActive(item) ? 'tonal' : 'outlined'" class="wf-chip-rounded">
          {{ isCategoryActive(item) ? 'Hoạt động' : 'Tạm dừng' }}
        </v-chip>
      </template>

      <template #item.actions="{ item }">
        <div class="d-flex ga-1">
          <v-btn icon size="x-small" variant="text" color="gray" title="Cấu hình custom fields"
            @click.stop="openCustomFieldDialog(item)">
            <v-icon size="14">mdi-cog</v-icon>
          </v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" title="Chỉnh sửa" @click.stop="openDialog(item)">
            <v-icon size="14">mdi-pencil-outline</v-icon>
          </v-btn>
          <v-btn icon size="x-small" variant="text" title="Xóa" @click.stop="deleteCategory(item)">
            <v-icon size="14" class="wf-icon-danger">mdi-delete-outline</v-icon>
          </v-btn>
        </div>
      </template>
    </uc-table>

    <uc-modal v-model="showDialog" max-width="500px" :title="isEditing ? 'Cập nhật nhóm' : 'Thêm mới nhóm'"
      :confirm-text="isEditing ? 'Lưu' : 'Thêm'" :cancel-text="'Hủy'" @confirm="saveCategory">
      <div class="wf-request-section-title" style="margin-top: 0;">
        <span>Thông tin cơ bản</span>
      </div>
      <div class="wf-request-form-grid wf-request-form-grid--2">
        <v-text-field v-model="form.Name" label="Tên nhóm *" variant="outlined" density="compact" hide-details="">
        </v-text-field>
        <v-text-field v-model="form.Code" label="Mã nhóm (Code) *" variant="outlined" density="compact" hide-details=""
          :hint="'VD: HR, PR, AC'"></v-text-field>
        <v-text-field v-model.number="form.SortOrder" type="number" label="Thứ tự hiển thị *" variant="outlined"
          density="compact" hide-details="" min="1"></v-text-field>
        <v-textarea v-model="form.Description" label="Mô tả" variant="outlined" density="compact" hide-details=""
          rows="2" class="wf-request-span-2"></v-textarea>
      </div>

      <div class="wf-request-section-title">
        <span>Màu sắc</span>
      </div>
      <div class="wf-cat-color-picker">
        <div v-for="c in colorPresets" :key="c" class="wf-cat-color-swatch" :class="{ active: form.Color === c }"
          :style="{ background: c }" @click="form.Color = c">
          <v-icon v-if="form.Color === c" size="13" color="white">mdi-check</v-icon>
        </div>
        <!-- <v-text-field v-model="form.Color" label="Hex tùy chỉnh" variant="outlined" density="compact" hide-details
              style="max-width: 140px;" class="ml-2" /> -->
      </div>

      <div class="wf-cat-preview"
        :style="{ background: buildColorLight(form.Color), color: form.Color || 'var(--wf-primary)' }">
        <v-icon size="20">{{ form.Icon || 'mdi-shape-outline' }}</v-icon>
        <span class="wf-cat-preview__name">{{ form.Name || 'Tên nhóm' }}</span>
        <span class="wf-cat-preview__code">{{ form.Code || 'CODE' }}</span>
      </div>

      <div class="wf-request-section-title">
        <span>Icon</span>
      </div>
      <div class="wf-cat-icon-picker">
        <div v-for="ic in iconPresets" :key="ic" class="wf-cat-icon-swatch" :class="{ active: form.Icon === ic }"
          :title="ic" @click="form.Icon = ic">
          <v-icon size="18" :color="form.Icon === ic ? 'white' : '#5f6368'">{{ ic }}</v-icon>
        </div>
      </div>
      <!-- <v-text-field v-model="form.Icon" label="Icon tùy chỉnh (vd: mdi-account-group-outline)"
            variant="outlined" density="compact" hide-details class="mt-3" /> -->

      <div class="wf-request-section-title">
        <span>Trạng thái</span>
      </div>
      <v-switch v-model="form.IsActive" label="Hoạt động" color="primary" density="compact" hide-details="">
      </v-switch>
    </uc-modal>

    <uc-modal v-model="showCustomFieldDialog" :max-width="showFieldForm ? 1040 : 560" persistent=""
      :title="(selectedCategoryForField ? selectedCategoryForField.Name : '') + ' - Cấu hình trường dữ liệu động'"
      @confirm="submitCustomField" :cancel-text="'Đóng'" :confirm-text="'Lưu'" :show-close="true" :show-cancel="true"
      :show-confirm="true" subtitle="Cấu hình trường dữ liệu động cho quy trình này" body-padding="0px">
      <!-- ── Two-column body ───────────────────────────────── -->
      <div class="wf-cfd-body">
        <!-- LEFT: Danh sách trường -->
        <div class="wf-cfd-left" :class="{ 'wf-cfd-left--no-border': !showFieldForm }">
          <div class="wf-cfd-left-toolbar">
            <v-text-field v-model="customFieldSearch" density="compact" variant="outlined" hide-details=""
              prepend-inner-icon="mdi-magnify" placeholder="Tìm tên, label..." class="wf-search-field"></v-text-field>
            <v-spacer />
            <v-btn class="wf-btn flex-shrink-0" variant="outlined" color="primary" @click="openCustomFieldEditor(null)">
              <v-icon start="" size="14">mdi-plus</v-icon> Thêm trường
            </v-btn>
          </div>

          <div v-if="isCustomFieldLoading" class="wf-empty-state" style="padding: 28px 0;">
            <v-progress-circular indeterminate="" color="primary" size="22" />
          </div>

          <div v-if="filteredCustomFields.length === 0 && !isCustomFieldLoading" class="wf-cfd-list-empty">
            <v-icon size="28" color="grey-lighten-1">mdi-form-select</v-icon>
            <div class="mt-2">Chưa có custom field nào</div>
            <div class="text-caption">Bấm "Thêm trường" để tạo trường đầu tiên</div>
          </div>

          <div v-else class="wf-cfd-list">
            <div v-for="(item, idx) in filteredCustomFields" :key="item.MappingID" class="wf-cfd-list-row"
              :class="{ 'wf-cfd-list-row--active': Number(customFieldForm.MappingID || 0) === Number(item.MappingID || 0) }"
              @click="openCustomFieldEditor(item)">
              <div class="wf-cfd-list-row__num">{{ idx + 1 }}</div>
              <div class="wf-cfd-list-row__content">
                <div class="wf-cfd-list-row__label">{{ item.FieldLabel || item.FieldName }}</div>
                <div class="wf-cfd-list-row__meta">
                  <span class="wf-cfd-list-row__fname">{{ item.FieldName }}</span>
                </div>
              </div>
              <v-chip size="x-small" color="primary" variant="tonal" class="flex-shrink-0">{{ item.FieldType || 'text'}}
              </v-chip>
              <v-chip size="x-small" :color="isCustomFieldRequired(item) ? 'success' : 'default'" variant="tonal"
                class="flex-shrink-0">{{ isCustomFieldRequired(item) ? 'Bắt buộc' : 'Tùy chọn' }}</v-chip>
              <v-btn icon="" size="x-small" variant="text" color="error" class="wf-cfd-list-row__del"
                @click.stop="deleteCustomField(item)">
                <v-icon size="13">mdi-delete-outline</v-icon>
              </v-btn>
            </div>
          </div>
        </div>
        <!-- RIGHT: Form chỉnh sửa -->
        <div v-if="showFieldForm" class="wf-cfd-right">
          <!-- MODE BANNER -->
          <div v-if="!customFieldForm.MappingID" class="wf-cfd-mode-banner wf-cfd-mode-banner--new">
            <div class="wf-cfd-mode-banner__icon">
              <v-icon size="20" color="white">mdi-plus</v-icon>
            </div>
            <div class="wf-cfd-mode-banner__text">
              <div class="wf-cfd-mode-banner__title">Thêm trường mới</div>
              <div class="wf-cfd-mode-banner__sub">Điền thông tin bên dưới rồi bấm Lưu</div>
            </div>
            <v-btn icon="" size="small" variant="text" color="white" class="ml-auto" title="Đóng"
              @click="showFieldForm = false">
              <v-icon size="16">mdi-close</v-icon>
            </v-btn>
          </div>
          <div v-else class="wf-cfd-mode-banner wf-cfd-mode-banner--edit">
            <div class="wf-cfd-mode-banner__icon">
              <v-icon size="20" color="white">mdi-pencil</v-icon>
            </div>
            <div class="wf-cfd-mode-banner__text">
              <div class="wf-cfd-mode-banner__title">Đang chỉnh sửa</div>
              <div class="wf-cfd-mode-banner__sub">{{ customFieldForm.FieldLabel || customFieldForm.FieldName ||'trường
                #' + customFieldForm.SortOrder }}</div>
            </div>
            <v-btn icon="" size="small" variant="text" color="white" class="ml-auto" title="Đóng"
              @click="showFieldForm = false">
              <v-icon size="16">mdi-close</v-icon>
            </v-btn>
          </div>

          <div class="wf-cfd-form-body">
            <v-row dense="">
              <v-col cols="12">
                <v-text-field v-model="customFieldForm.FieldLabel" label="Tên hiển thị*" variant="outlined"
                  density="compact" hide-details="" placeholder="VD: Họ tên ứng viên">
                </v-text-field>
              </v-col>
              <v-col cols="12">
                <v-text-field v-model="customFieldForm.FieldName" label="Mã trường*" variant="outlined"
                  density="compact" hide-details="" placeholder="VD: HoTenUngVien">
                </v-text-field>
              </v-col>
              <v-col cols="7">
                <v-select v-model="customFieldForm.FieldType" :items="fieldTypeOptions" label="Kiểu dữ liệu"
                  variant="outlined" density="compact" hide-details="">
                </v-select>
              </v-col>
              <v-col cols="5">
                <v-text-field v-model="customFieldForm.SortOrder" type="number" min="1" label="Thứ tự"
                  variant="outlined" density="compact" hide-details="">
                </v-text-field>
              </v-col>
              <v-col cols="12">
                <v-text-field v-model="customFieldForm.DefaultValue" label="Giá trị mặc định" variant="outlined"
                  density="compact" hide-details="">
                </v-text-field>
              </v-col>
              <v-col cols="12">
                <v-textarea v-model="customFieldForm.FieldOptions" rows="3" :label="fieldOptionsLabel"
                  variant="outlined" density="compact" hide-details="" :placeholder="fieldOptionsPlaceholder">
                </v-textarea>
              </v-col>
              <v-col cols="12">
                <v-switch v-model="customFieldForm.IsRequired" label="Bắt buộc điền" color="primary" density="compact"
                  hide-details="">
                </v-switch>
              </v-col>
            </v-row>
          </div>

          <div class="wf-cfd-form-footer">
            <v-btn class="wf-btn" :variant="customFieldForm.MappingID ? 'flat' : 'outlined'"
              :color="customFieldForm.MappingID ? 'warning' : 'primary'" :loading="isCustomFieldSaving"
              @click="saveCustomField">
              <v-icon start="" size="14">{{ customFieldForm.MappingID ? 'mdi-content-save-edit-outline' :
                'mdi-plus-circle-outline' }}</v-icon>
              {{ customFieldForm.MappingID ? 'Cập nhật' : 'Thêm trường' }}
            </v-btn>
          </div>
        </div>
      </div>
    </uc-modal>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: 'uc-main-page',

  data: function () {
    return {
      isLoading: false,
      isSaving: false,
      showDialog: false,
      showCustomFieldDialog: false,
      searchQuery: '',
      customFieldSearch: '',
      isCustomFieldLoading: false,
      isCustomFieldSaving: false,
      categories: [],
      customFieldMappings: [],
      selectedCategoryForField: null,
      form: {
        CategoryID: null,
        Name: '',
        Code: '',
        SortOrder: 1,
        Description: '',
        Color: '#217D46',
        Icon: 'mdi-shape-outline',
        IsActive: true,
      },
      customFieldForm: {
        MappingID: 0,
        CategoryID: null,
        FieldName: '',
        FieldLabel: '',
        FieldType: 'text',
        FieldOptions: '',
        IsRequired: false,
        DefaultValue: '',
        SortOrder: 1,
        Enable: 0,
      },
      fieldTypeOptions: ['text', 'textarea', 'number', 'date', 'select', 'checkbox', 'file', 'image', 'user', 'checklist', 'rating', 'computed','signature'],
      colorPresets: [
        '#217D46', '#0b6e4f', '#2563eb', '#7c3aed',
        '#db2777', '#d97706', '#0891b2', '#c62828',
        '#374151', '#059669',
      ],
      iconPresets: [
        'mdi-account-group-outline',
        'mdi-file-document-edit-outline',
        'mdi-domain',
        'mdi-briefcase-outline',
        'mdi-currency-usd',
        'mdi-cog-outline',
        'mdi-clipboard-list-outline',
        'mdi-school-outline',
        'mdi-truck-delivery-outline',
        'mdi-handshake-outline',
        'mdi-chart-bar',
        'mdi-shield-check-outline',
        'mdi-tools',
        'mdi-email-outline',
        'mdi-calendar-check-outline',
        'mdi-tag-outline',
      ],
      categoryHeaders: [
        { title: 'Nhóm quy trình', key: 'category', width: '1.5fr' },
        { title: 'Mô tả', key: 'description' },
        { title: 'Màu sắc', key: 'color', width: '120px' },
        { title: 'Custom Fields', key: 'customFields', width: '220px' },
        { title: 'Trạng thái', key: 'status', width: '120px' },
        { title: '', key: 'actions', width: '110px' }
      ],
      allCustomFields: [],
      showFieldForm: false,
    }
  },

  computed: {
    fieldOptionsLabel: function () {
      if (this.customFieldForm.FieldType === 'checklist') return 'Checklist Options (Mảng JSON) *'
      if (this.customFieldForm.FieldType === 'computed') return 'Công thức tính toán (Formula) *'
      if (this.customFieldForm.FieldType === 'select') return 'Select Options (Mảng JSON hoặc phân tách dấu phẩy)'
      return 'Options (JSON/text)'
    },

    fieldOptionsPlaceholder: function () {
      if (this.customFieldForm.FieldType === 'checklist') return 'Ví dụ: ["Phiếu đăng ký", "Sơ yếu lý lịch", "Bằng cấp"]'
      if (this.customFieldForm.FieldType === 'computed') return 'Ví dụ: d1 + d2 hoặc [Kiến thức] * 0.4 + [Kỹ năng] * 0.6'
      if (this.customFieldForm.FieldType === 'select') return 'Ví dụ: ["Lựa chọn A", "Lựa chọn B"] hoặc A,B,C'
      return 'VD: ["Option A","Option B"]'
    },

    filteredCategories: function () {
      var q = (this.searchQuery || '').toLowerCase().trim()
      var rows = this.categories || []
      if (q) {
        rows = rows.filter(function (item) {
          return (
            (item.Name || '').toLowerCase().indexOf(q) >= 0 ||
            (item.Code || '').toLowerCase().indexOf(q) >= 0 ||
            (item.Description || '').toLowerCase().indexOf(q) >= 0
          )
        })
      }
      return rows.slice().sort(function (a, b) {
        var sa = Number(a && a.SortOrder ? a.SortOrder : 0)
        var sb = Number(b && b.SortOrder ? b.SortOrder : 0)
        if (sa !== sb) return sa - sb
        return Number(a && a.CategoryID ? a.CategoryID : 0) - Number(b && b.CategoryID ? b.CategoryID : 0)
      })
    },

    filteredCustomFields: function () {
      var q = (this.customFieldSearch || '').toLowerCase().trim()
      var rows = this.customFieldMappings || []
      if (q) {
        rows = rows.filter(function (item) {
          return (
            String(item.FieldName || '').toLowerCase().indexOf(q) >= 0 ||
            String(item.FieldLabel || '').toLowerCase().indexOf(q) >= 0 ||
            String(item.FieldType || '').toLowerCase().indexOf(q) >= 0
          )
        })
      }
      return rows.slice().sort(function (a, b) {
        var sa = Number(a.SortOrder || 0)
        var sb = Number(b.SortOrder || 0)
        if (sa !== sb) return sa - sb
        return Number(a.MappingID || 0) - Number(b.MappingID || 0)
      })
    },

    isEditing: function () {
      return !!(this.form && this.form.CategoryID)
    },
  },

  mounted: function () {
    this.loadCategories()
    this.loadAllCustomFields()
  },

  methods: {
    loadCategories: async function () {
      this.isLoading = true
      try {
        var rows = await apiCallAsync('WF_Category_GetList', {})
        this.categories = rows || []
      } catch (err) {
        this.categories = []
        showToast.error(err.responseJSON ? err.responseJSON.Message : 'Lỗi tải danh sách nhóm.')
      } finally {
        this.isLoading = false
      }
    },

    getNextSortOrder: function () {
      var rows = this.categories || []
      var maxSort = 0
      var i = 0
      for (i = 0; i < rows.length; i += 1) {
        maxSort = Math.max(maxSort, Number(rows[i].SortOrder || 0))
      }
      return maxSort + 1
    },

    isCategoryActive: function (item) {
      if (!item) return false
      if (item.IsActive === undefined || item.IsActive === null) return true
      return Number(item.IsActive) === 1 || item.IsActive === true
    },

    openDialog: function (item) {
      if (item) {
        this.form = {
          CategoryID: item.CategoryID,
          Name: item.Name || '',
          Code: item.Code || '',
          SortOrder: Number(item.SortOrder || 0) || 1,
          Description: item.Description || '',
          Color: item.Color || '#217D46',
          Icon: item.Icon || 'mdi-shape-outline',
          IsActive: this.isCategoryActive(item),
        }
      } else {
        this.form = {
          CategoryID: null,
          Name: '',
          Code: '',
          SortOrder: this.getNextSortOrder(),
          Description: '',
          Color: '#217D46',
          Icon: 'mdi-shape-outline',
          IsActive: true,
        }
      }
      this.showDialog = true
    },

    openCustomFieldDialog: async function (category) {
      if (!category || !category.CategoryID) {
        showToast.error('Không xác định được nhóm văn bản.')
        return
      }
      this.selectedCategoryForField = category
      this.showCustomFieldDialog = true
      this.customFieldSearch = ''
      this.resetCustomFieldForm(null)
      await this.loadCustomFieldsByCategory(category.CategoryID)
    },

    loadCustomFieldsByCategory: async function (categoryId) {
      this.isCustomFieldLoading = true
      try {
        var rows = await apiCallAsync('WF_CustomFieldMapping_GetList', { CategoryID: Number(categoryId || 0) })
        this.customFieldMappings = rows || []
      } catch (err) {
        this.customFieldMappings = []
        showToast.error(err.responseJSON ? err.responseJSON.Message : 'Lỗi tải custom field theo nhóm.')
      } finally {
        this.isCustomFieldLoading = false
      }
    },

    loadAllCustomFields: async function () {
      try {
        var rows = await apiCallAsync('WF_CustomFieldMapping_GetList', { CategoryID: 0 })
        this.allCustomFields = rows || []
      } catch (err) {
        this.allCustomFields = []
      }
    },

    getCategoryFields: function (categoryId) {
      if (!categoryId) return []
      return this.allCustomFields.filter(function (f) {
        return Number(f.CategoryID) === Number(categoryId)
      })
    },

    resetCustomFieldForm: function (item) {
      var categoryId = this.selectedCategoryForField ? this.selectedCategoryForField.CategoryID : null
      if (item) {
        this.customFieldForm = {
          MappingID: Number(item.MappingID || 0),
          CategoryID: Number(item.CategoryID || categoryId || 0),
          FieldName: item.FieldName || '',
          FieldLabel: item.FieldLabel || '',
          FieldType: item.FieldType || 'text',
          FieldOptions: item.FieldOptions || '',
          IsRequired: this.isCustomFieldRequired(item),
          DefaultValue: item.DefaultValue || '',
          SortOrder: Number(item.SortOrder || 1),
          Enable: Number(item.Enable || 0),
        }
      } else {
        this.customFieldForm = {
          MappingID: 0,
          CategoryID: Number(categoryId || 0),
          FieldName: '',
          FieldLabel: '',
          FieldType: 'text',
          FieldOptions: '',
          IsRequired: false,
          DefaultValue: '',
          SortOrder: this.getNextCustomFieldSortOrder(),
          Enable: 0,
        }
      }
    },

    openCustomFieldEditor: function (item) {
      this.resetCustomFieldForm(item)
      this.showFieldForm = true
    },

    getNextCustomFieldSortOrder: function () {
      var rows = this.customFieldMappings || []
      var maxSort = 0
      for (var i = 0; i < rows.length; i++) {
        maxSort = Math.max(maxSort, Number(rows[i].SortOrder || 0))
      }
      return maxSort + 1
    },

    validateCustomFieldForm: function () {
      if (!this.selectedCategoryForField || !this.selectedCategoryForField.CategoryID) return 'Bạn cần chọn nhóm văn bản.'
      if (!(this.customFieldForm.FieldName || '').trim()) return 'FieldName không được để trống.'
      if (!(this.customFieldForm.FieldLabel || '').trim()) return 'FieldLabel không được để trống.'
      if (!Number(this.customFieldForm.SortOrder) || Number(this.customFieldForm.SortOrder) <= 0) return 'SortOrder phải lớn hơn 0.'
      return ''
    },

    buildCustomFieldPayload: function () {
      return {
        MappingID: Number(this.customFieldForm.MappingID || 0),
        CategoryID: Number(this.selectedCategoryForField ? this.selectedCategoryForField.CategoryID : 0),
        FieldName: String(this.customFieldForm.FieldName || '').trim(),
        FieldLabel: String(this.customFieldForm.FieldLabel || '').trim(),
        FieldType: String(this.customFieldForm.FieldType || 'text').trim(),
        FieldOptions: String(this.customFieldForm.FieldOptions || '').trim(),
        IsRequired: this.customFieldForm.IsRequired ? 1 : 0,
        DefaultValue: String(this.customFieldForm.DefaultValue || '').trim(),
        SortOrder: Number(this.customFieldForm.SortOrder || 1),
        Enable: Number(this.customFieldForm.Enable || 0),
      }
    },

    saveCustomField: function () {
      var $this = this
      var err = this.validateCustomFieldForm()
      if (err) {
        showToast.error(err)
        return
      }

      this.isCustomFieldSaving = true
      var payload = this.buildCustomFieldPayload()
      var apiName = payload.MappingID > 0 ? 'WF_CustomFieldMapping_Update' : 'WF_CustomFieldMapping_Insert'
      apiCall(apiName, payload, function () {
        showToast.success(payload.MappingID > 0 ? 'Cập nhật thành công.' : 'Thêm thành công.')
        $this.loadCustomFieldsByCategory(payload.CategoryID).finally(function () {
          $this.isCustomFieldSaving = false
          $this.showFieldForm = false
          $this.resetCustomFieldForm(null)
          $this.loadAllCustomFields() // Update card preview
        })
      }, function (xhr) {
        showToast.error(xhr.responseJSON ? xhr.responseJSON.Message : 'Lỗi khi lưu.')
        $this.isCustomFieldSaving = false
      })
    },

    deleteCustomField: function (item) {
      var $this = this
      showConfirm(
        'Xóa trường "' + (item.FieldLabel || item.FieldName) + '"? Hành động này sẽ soft delete.',
        function () {
          apiCall('WF_CustomFieldMapping_Delete', { MappingID: Number(item.MappingID || 0) }, function () {
            showToast.success('Đã xóa custom field thành công.')
            $this.loadCustomFieldsByCategory($this.selectedCategoryForField ? $this.selectedCategoryForField.CategoryID : 0)
            if (Number($this.customFieldForm.MappingID || 0) === Number(item.MappingID || 0)) {
              $this.resetCustomFieldForm(null)
            }
          }, function (xhr) {
            showToast.error(xhr.responseJSON ? xhr.responseJSON.Message : 'Lỗi khi xóa custom field.')
          })
        }
      )
    },

    isCustomFieldRequired: function (item) {
      return Number(item && item.IsRequired ? item.IsRequired : 0) === 1 || (item && item.IsRequired === true)
    },

    validateForm: function () {
      if (!(this.form.Name || '').trim()) return 'Tên nhóm không được để trống.'
      if (!(this.form.Code || '').trim()) return 'Mã nhóm không được để trống.'
      if (!Number(this.form.SortOrder) || Number(this.form.SortOrder) <= 0) return 'Thứ tự hiển thị phải lớn hơn 0.'
      return ''
    },

    saveCategory: function () {
      var $this = this
      var err = this.validateForm()
      if (err) { showToast.error(err); return }

      this.isSaving = true
      var params = {
        CategoryID: this.form.CategoryID || 0,
        Name: (this.form.Name || '').trim(),
        Code: (this.form.Code || '').trim().toUpperCase(),
        SortOrder: Number(this.form.SortOrder || 0),
        Description: (this.form.Description || '').trim(),
        Color: (this.form.Color || '').trim(),
        Icon: (this.form.Icon || '').trim(),
        IsActive: this.form.IsActive ? 1 : 0,
      }
      apiCall('WF_Category_Save', params, function () {
        showToast.success('Lưu nhóm thành công.')
        $this.showDialog = false
        $this.loadCategories().finally(function () { $this.isSaving = false })
      }, function (xhr) {
        showToast.error(xhr.responseJSON ? xhr.responseJSON.Message : 'Lỗi khi lưu nhóm.')
        $this.isSaving = false
      })
    },

    deleteCategory: function (item) {
      var $this = this
      showConfirm(
        'Xóa nhóm "' + item.Name + '"? Hành động này không thể hoàn tác.',
        function () {
          apiCall('WF_Category_Delete', { CategoryID: item.CategoryID }, function () {
            showToast.success('Đã xóa nhóm "' + item.Name + '".')
            $this.loadCategories()
          }, function (xhr) {
            showToast.error(xhr.responseJSON ? xhr.responseJSON.Message : 'Lỗi khi xóa nhóm.')
          })
        }
      )
    },

    buildColorLight: function (color) {
      if (!color) return 'rgba(var(--wf-primary-rgb), .12)'
      if (color.indexOf('#') === 0) return color + '18'
      return 'rgba(var(--wf-primary-rgb), .12)'
    },

    submitCustomField: function () {
      this.showCustomFieldDialog = false
    },
  },
	}
</script>