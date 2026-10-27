<template>
	<uc-wf-shell :show-user-section="false">
    <div class="wf-page-header">
      <div>
        <h1>Luồng công việc ({{ filteredDefinitions.length }})</h1>
        <p>Định nghĩa các quy trình ký số &amp; phê duyệt</p>
      </div>
      <v-btn class="wf-btn" variant="outlined" color="primary" @click="openCreate">
        <v-icon start="">mdi-plus</v-icon>
        Tạo luồng mới
      </v-btn>
    </div>

    <uc-table :rounded="false" title="Tất cả luồng" :headers="workflowHeaders" :items="filteredDefinitions"
      :loading="isLoading" item-value="DefinitionID" empty-text="Không có workflow nào khớp bộ lọc hiện tại."
      max-height="calc(100vh - 165px)" @row-click="openDetail">
      <template #toolbar>
        <div class="d-flex ga-2 mr-3">
          <v-btn size="small" variant="outlined" color="primary" :class="{ 'wf-btn--active': statusFilter === 'ALL' }"
            @click="setStatusFilter('ALL')">Tất cả
          </v-btn>
          <v-btn size="small" variant="outlined" color="primary"
            :class="{ 'wf-btn--active': statusFilter === 'ACTIVE' }" @click="setStatusFilter('ACTIVE')">Hoạt
            động</v-btn>
          <v-btn size="small" variant="outlined" color="primary"
            :class="{ 'wf-btn--active': statusFilter === 'INACTIVE' }" @click="setStatusFilter('INACTIVE')">
            Tắt</v-btn>
        </div>
        <v-text-field v-model="searchQuery" density="compact" hide-details prepend-inner-icon="mdi-magnify" single-line
          placeholder="Tìm kiếm..." variant="outlined" class="wf-search-field" @update:modelvalue="onKeywordChanged">
        </v-text-field>
      </template>
      <template #item.name="{ item }">
        <div class="wf-audit-title">{{ item.Name }}</div>
        <div class="wf-audit-sub">{{ item.Code }}</div>
      </template>
      <template #item.category="{ item }">
        <v-chip size="x-small" variant="outlined" color="primary" class="wf-chip-rounded">{{ item.CategoryName
          }}</v-chip>
      </template>
      <template #item.steps="{ item }">
        <span class="wf-audit-meta">{{ item.StepCount }} bước</span>
      </template>
      <template #item.instances="{ item }">
        <span class="wf-audit-meta"><strong>{{ item.ActiveInstances }}</strong> đang chạy</span>
      </template>
      <template #item.status="{ item }">
        <v-chip size="x-small" color="primary" :variant="item.IsActive ? 'tonal' : 'outlined'" class="wf-chip-rounded"
          @click.stop="toggleStatus(item)">
          {{ item.IsActive ? 'Hoạt động' : 'Tắt' }}
        </v-chip>
      </template>
      <template #item.actions="{ item }">
        <div class="d-flex ga-1">
          <v-btn icon size="x-small" variant="text" color="primary" :disabled="isCloning"
            @click.stop="cloneDefinition(item)">
            <v-icon size="14">mdi-content-copy</v-icon>
          </v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" @click.stop="confirmDelete(item)">
            <v-icon size="14" class="wf-icon-danger">mdi-delete-outline</v-icon>
          </v-btn>
        </div>
      </template>
    </uc-table>
  </uc-wf-shell>
</template>

<script>
	export default {
		data() {
    return {
      definitions: [],
      filteredDefinitions: [],
      searchQuery: "",
      statusFilter: "ALL",
      isLoading: false,
      isCloning: false,
      isUpdatingStatus: false,
      searchTimer: null,
      workflowHeaders: [
        { title: 'Tên luồng', key: 'name' },
        { title: 'Nhóm quy trình', key: 'category', width: '120px' },
        { title: 'Số bước', key: 'steps', width: '80px' },
        { title: 'Nhiệm vụ', key: 'instances', width: '100px' },
        { title: 'Trạng thái', key: 'status', width: '100px' },
        { title: 'Thao tác', key: 'actions', width: '60px' }
      ]
    }
  },
  mounted() {
    this.loadDefinitions()
  },
  methods: {
    async loadDefinitions() {
      const $this = this
      $this.isLoading = true
      try {
        const params = { Status: $this.statusFilter }
        if (($this.searchQuery || "").trim()) {
          params.Keyword = ($this.searchQuery || "").trim()
        }
        const rows = await apiCallAsync("WF_Definition_GetList", params)
        $this.definitions = rows || []
        $this.filteredDefinitions = $this.definitions
        $this.applyFilters()
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
        }
      } finally {
        $this.isLoading = false
      }
    },
    applyFilters() {
      var keyword = (this.searchQuery || "").toLowerCase().trim()
      var status = this.statusFilter
      this.filteredDefinitions = this.definitions.filter(function (item) {
        var isMatchedStatus = status === "ALL" || (status === "ACTIVE" && item.IsActive) || (status === "INACTIVE" && !item.IsActive)
        var name = ((item && item.Name) || "").toLowerCase()
        var code = ((item && item.Code) || "").toLowerCase()
        var categoryName = ((item && item.CategoryName) || "").toLowerCase()
        var isMatchedKeyword = !keyword || name.includes(keyword) || code.includes(keyword) || categoryName.includes(keyword)
        return isMatchedStatus && isMatchedKeyword
      })
    },
    onKeywordChanged() {
      var $this = this
      if ($this.searchTimer) clearTimeout($this.searchTimer)
      $this.searchTimer = setTimeout(function () {
        $this.loadDefinitions()
      }, 250)
    },
    setStatusFilter(status) {
      this.statusFilter = status
      this.loadDefinitions()
    },
    openCreate() {
      window.location.href = "/wf-admin-workflow-detail?id=0"
    },
    openDetail(definition) {
      window.location.href = "/wf-admin-workflow-detail?id=" + definition.DefinitionID
    },
    confirmDelete(definition) {
      const $this = this
      if (!definition || !definition.DefinitionID) return
      const title = definition.Name ? "Xóa luồng \"" + definition.Name + "\"?" : "Xóa luồng?"
      showConfirm(title, function () {
        $this.deleteDefinition(definition.DefinitionID)
      })
    },
    deleteDefinition(definitionId) {
      const $this = this
      const params = { DefinitionID: definitionId }
      apiCall(
        "WF_Definition_Delete",
        params,
        (res) => {
          const row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null
          if (showToast && showToast.success) showToast.success(row && row.Message ? row.Message : "Đã xóa workflow.")
          $this.loadDefinitions()
        },
        (err) => {
          if (showToast && showToast.error) {
            showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
          }
          $this.loadDefinitions()
        }
      )
    },
    toggleStatus(definition) {
      var $this = this
      if (!definition || !definition.DefinitionID) return
      var nextStatus = definition.IsActive ? 0 : 1
      var actionText = definition.IsActive ? "tắt" : "kích hoạt"
      showConfirm(
        'Bạn có muốn ' + actionText + ' workflow "' + definition.Name + '"?',
        function () {
          $this.isUpdatingStatus = true
          apiCall(
            "WF_Definition_UpdateStatus",
            {
              DefinitionID: definition.DefinitionID,
              IsActive: nextStatus
            },
            function (res) {
              var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null
              if (showToast && showToast.success) {
                showToast.success(row && row.Message ? row.Message : "Đã cập nhật trạng thái workflow.")
              }
              $this.loadDefinitions().then(function () {
                $this.isUpdatingStatus = false
              }).catch(function () {
                $this.isUpdatingStatus = false
              })
            },
            function (err) {
              if (showToast && showToast.error) {
                showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
              }
              $this.isUpdatingStatus = false
            }
          )
        }
      )
    },
    cloneDefinition(definition) {
      var $this = this
      if (!definition || !definition.DefinitionID) return
      showConfirm(
        'Bạn có muốn tạo bản sao quy trình "' + definition.Name + '"?',
        function () {
          $this.isCloning = true
          apiCall(
            "WF_Definition_Clone",
            { DefinitionID: definition.DefinitionID },
            function (res) {
              var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null
              if (showToast && showToast.success) {
                showToast.success(row && row.Message ? row.Message : "Tạo bản sao quy trình thành công.")
              }
              $this.loadDefinitions().then(function () {
                $this.isCloning = false
              }).catch(function () {
                $this.isCloning = false
              })
            },
            function (err) {
              if (showToast && showToast.error) {
                showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
              }
              $this.isCloning = false
            }
          )
        }
      )
    }
  }
	}
</script>