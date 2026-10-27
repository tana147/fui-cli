<template>
	<uc-wf-shell>
    <!-- Header Toolbar -->
    <div class="wf-page-header border-bottom pa-0 bg-white"
      style="height: 56px; border-bottom: 1px solid #dfe1e5 !important; width: 100%;">
      <div style="display: flex; align-items: center; height: 100%; padding: 0 16px; width: 100%;">
        <!-- Left Side: Title + Tabs -->
        <div class="d-flex align-center h-100 ga-4" style="flex: 1; min-width: 0;">
          <div class="d-flex align-center ga-1 pr-2 border-right h-100"
            style="border-right: 1px solid #dfe1e5 !important;">
            <v-menu transition="slide-y-transition" offset="4">
              <template v-slot:activator="{ props }">
                <div v-bind="props" class="d-flex align-center cursor-pointer">
                  <h1 class="text-h6 font-weight-bold mb-0"
                    style="font-size: 15px !important; color: var(--wf-primary, #217D46); white-space: nowrap;">
                    {{ selectedDefinitionName }}
                  </h1>
                  <v-icon size="16" color="primary" class="ml-1 flex-shrink-0">mdi-chevron-down</v-icon>
                </div>
              </template>
              <v-list density="compact" class="py-1 bg-white"
                style="border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.1) !important; min-width: 240px; max-width: 380px; max-height: 400px; overflow-y: auto;">
                <v-list-subheader class="text-caption font-weight-bold text-uppercase px-3"
                  style="font-size: 10px !important; letter-spacing: 0.05em; color: #64748b;">
                  Chọn quy trình
                </v-list-subheader>
                <v-divider class="mx-2 mb-1"></v-divider>
                <template v-for="cat in categoriesWithDefs" :key="cat.CategoryID">
                  <v-list-subheader v-if="cat.Name" class="text-caption font-weight-medium px-3 mt-1"
                    style="font-size: 10px !important; color: #94a3b8; min-height: 24px;">
                    {{ cat.Name }}
                  </v-list-subheader>
                  <v-list-item v-for="def in cat.defs" :key="def.DefinitionID"
                    :active="definitionFilter === def.DefinitionID" color="primary" class="rounded-md mx-1 px-3"
                    style="min-height: 36px;" @click="selectDefinition(def.DefinitionID)">
                    <v-list-item-title class="font-weight-medium" style="font-size: 13px !important;">
                      {{ def.Name }}
                    </v-list-item-title>
                  </v-list-item>
                </template>
                <v-list-item v-if="definitionOptions.length === 0" class="px-3">
                  <v-list-item-title class="text-caption text-grey text-center">Không có quy trình nào
                  </v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </div>

          <!-- Tabs switcher -->
          <div class="wf-custom-header-tabs h-100">
            <!-- Tab Công việc with dropdown -->
            <v-menu transition="slide-y-transition" offset="4" attach="body">
              <template v-slot:activator="{ props }">
                <div v-bind="props" class="wf-header-tab-item active" style="user-select: none;">
                  <div class="d-flex align-center">
                    <span>CÔNG VIỆC</span>
                    <v-icon size="14" color="primary" class="ml-1">mdi-menu-down</v-icon>
                  </div>
                  <span class="wf-header-tab-sublabel">
                    {{ viewMode === 'kanban' ? 'Kanban view' : 'Gantt view' }}
                  </span>
                </div>
              </template>
              <v-list density="compact" class="py-1 bg-white"
                style="border: 1px solid #e2e8f0; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.08) !important;">
                <v-list-item @click="viewMode = 'kanban'" class="cursor-pointer">
                  <template v-slot:prepend>
                    <v-icon size="16" class="mr-2">mdi-view-column-outline</v-icon>
                  </template>
                  <v-list-item-title style="font-size: 12px; font-weight: 500;">Bảng Kanban</v-list-item-title>
                </v-list-item>
                <v-list-item @click="viewMode = 'timeline'" class="cursor-pointer">
                  <template v-slot:prepend>
                    <v-icon size="16" class="mr-2">mdi-chart-gantt</v-icon>
                  </template>
                  <v-list-item-title style="font-size: 12px; font-weight: 500;">Gantt view (Timeline)
                  </v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>

            <div class="wf-header-tab-item">
              <span>BÁO CÁO</span>
            </div>
            <div class="wf-header-tab-item">
              <span>TÙY CHỈNH</span>
            </div>
          </div>
        </div>

        <!-- Action Button — right side -->
        <v-btn color="primary" variant="outlined" class="wf-btn" prepend-icon="mdi-plus" :disabled="!definitionFilter"
          @click="openCreateDialog"
          style="text-transform: none; border-radius: 4px; font-size: 12px !important; margin-left: 12px;">
          Tạo nhiệm vụ
        </v-btn>
      </div>
    </div>

    <!-- Kanban Board -->
    <div v-show="viewMode === 'kanban'" style="margin-top: 0; padding: 0;">
      <div v-if="!definitionFilter" class="w-100 ga-2 d-flex flex-column align-center justify-center text-center"
        style="min-height: 63vh;">
        <v-icon size="64" color="grey-lighten-1">mdi-filter-variant</v-icon>
        <div class="text-h6 text-grey-darken-1 mt-4">Vui lòng chọn quy trình để xem bảng Kanban</div>
      </div>
      <uc-kanban v-else-if="!isLoading" :ds-cot="dsCot" :ds-the="dsThe" :signer-profiles="signerProfiles"
        @open-card="moDialogChiTiet" @drop="onDrop" @refresh-board="loadData" @add-card="openCreateDialogForStep" />
      <div v-else class="d-flex justify-center pa-10">
        <v-progress-circular indeterminate color="primary" size="48"></v-progress-circular>
      </div>
    </div>

    <!-- Timeline View -->
    <div v-show="viewMode === 'timeline'">
      <div v-if="!definitionFilter" class="wf-empty-state pa-10 text-center">
        <v-icon size="64" color="grey-lighten-1">mdi-timeline-text-outline</v-icon>
        <div class="text-h6 text-grey-darken-1 mt-4">Chọn quy trình để xem dòng thời gian</div>
      </div>
      <uc-timeline v-else-if="!isLoading" :ds-the="dsThe" :ds-cot="dsCot" @open-card="handleOpenCardFromTimeline" />
    </div>

    <!-- Dialog: Tạo nhiệm vụ mới -->
    <uc-instance-create-dialog v-model="dialog.createInstance" :definition-id="definitionFilter"
      :preselected-step-id="createPreselectedStepId" @success="loadData" />

  </uc-wf-shell>

  <!-- Panel chi tiết nhiệm vụ — slide-over từ bên phải -->
  <v-navigation-drawer v-model="dialog.showDetail" location="right" temporary :width="820" persistent
    style="position: fixed; top: 0; right: 0; height: 100vh; z-index: 1200; box-shadow: -4px 0 24px rgba(0,0,0,0.15);">
    <uc-kanban-flow-detail-view v-if="dialog.showDetail" :prop-instance-id="selectedInstanceId" :is-modal="true"
      @close="handleCloseDetail" @update="loadData(true)" />
  </v-navigation-drawer>
</template>

<script>
	export default {
		data() {
    return {
      viewMode: 'kanban',
      isLoading: false,

      categoryFilter: null,
      definitionFilter: null,

      categories: [],
      definitions: [],
      dsCot: [],
      dsThe: [],
      signerProfiles: [],

      dialog: {
        createInstance: false,
        showDetail: false
      },
      selectedInstanceId: null,
      theChiTiet: null,
      createPreselectedStepId: null
    }
  },

  computed: {
    categoryOptions: function () {
      return this.categories.map(c => ({ title: c.Name, value: c.CategoryID }))
    },
    definitionOptions: function () {
      return this.definitions
        .filter(d => !this.categoryFilter || d.CategoryID === this.categoryFilter)
        .map(d => ({ title: d.Name, value: d.DefinitionID }))
    },
    selectedDefinitionName: function () {
      if (!this.definitionFilter) return 'Kanban quy trình'
      var defId = this.definitionFilter
      var def = this.definitions.find(function (d) { return d.DefinitionID === defId })
      return def ? def.Name : 'Kanban quy trình'
    },
    categoriesWithDefs: function () {
      var defs = this.definitions || []
      var cats = this.categories || []
      var result = []
      // Group definitions by category
      cats.forEach(function (cat) {
        var catDefs = defs.filter(function (d) { return d.CategoryID === cat.CategoryID })
        if (catDefs.length > 0) {
          result.push({ CategoryID: cat.CategoryID, Name: cat.Name, defs: catDefs })
        }
      })
      // Uncategorized definitions
      var catIds = cats.map(function (c) { return c.CategoryID })
      var uncategorized = defs.filter(function (d) { return !d.CategoryID || catIds.indexOf(d.CategoryID) === -1 })
      if (uncategorized.length > 0) {
        result.push({ CategoryID: 0, Name: '', defs: uncategorized })
      }
      return result
    },
    selectedDefinitionOwner: function () {
      if (!this.definitionFilter) return null
      const def = this.definitions.find(d => d.DefinitionID === this.definitionFilter)
      return def && def.AssignerName ? def.AssignerName : (def && def.AssignerID ? def.AssignerID : null)
    }
  },

  mounted() {
    this.initPage()
    this.loadSignerProfiles()
  },

  methods: {
    initPage: async function () {
      this.isLoading = true
      try {
        const [cats, defs] = await Promise.all([
          apiCallAsync('WF_Category_GetList', {}),
          apiCallAsync('WF_Definition_GetList', { Status: 'ACTIVE' })
        ])
        this.categories = cats || []
        this.definitions = defs || []

        // Check URL params first, then localStorage
        const params = new URLSearchParams(window.location.search)
        var defId = parseInt(params.get('definitionID'))
        if (!defId) {
          var saved = parseInt(localStorage.getItem('wf_kanban_defId') || '0')
          if (saved) defId = saved
        }
        if (defId) {
          this.definitionFilter = defId
          await this.loadData()
        }
      } catch (err) {
        console.error(err)
      } finally {
        this.isLoading = false
      }
    },

    onCategoryChange: function () {
      this.definitionFilter = null
      this.dsCot = []
      this.dsThe = []
    },

    selectDefinition: function (defId) {
      this.definitionFilter = defId
      this.loadData()
    },

    loadData: async function (isSilent) {
      if (!this.definitionFilter) return
      localStorage.setItem('wf_kanban_defId', String(this.definitionFilter))
      if (!isSilent) {
        this.isLoading = true
      }
      try {
        var defIdParam = this.definitionFilter
        const [steps, instances, defDetail] = await Promise.all([
          apiCallAsync('WF_StepDefinition_GetList', { DefinitionID: defIdParam }),
          apiCallAsync('WF_Instance_GetList', { DefinitionID: defIdParam, Filter: 'ALL' }),
          apiCallAsync('WF_Definition_GetDetail', { DefinitionID: defIdParam })
        ])

        // Build step detail map from defDetail resultset[1]
        var stepDetailRows = defDetail && defDetail[1] ? defDetail[1] : []
        var stepDetailMap = {}
        stepDetailRows.forEach(function (s) {
          var tasks = []
          var assignees = []
          if (s.TasksJSON) { try { tasks = JSON.parse(s.TasksJSON) || [] } catch (e) { } }
          if (s.AssigneesJSON) { try { assignees = JSON.parse(s.AssigneesJSON) || [] } catch (e) { } }
          stepDetailMap[s.StepDefID] = {
            stepType: s.StepType || 'REVIEW',
            stepCode: s.StepCode || '',
            taskCount: tasks.length,
            assignees: assignees
          }
        })

        this.dsCot = (steps || []).map(function (s) {
          var detail = stepDetailMap[s.StepDefID] || {}
          var mau = s.Color
          if (!mau) {
            if (detail.stepType === 'SUCCESS' || detail.stepCode === 'STEP_SUCCESS') mau = '#28a745'
            else if (detail.stepType === 'FAILURE' || detail.stepCode === 'STEP_FAILURE') mau = '#dc3545'
            else mau = '#2a9d5b'
          }
          return {
            id: s.StepDefID,
            tenCot: s.StepName, //s.StepOrder + '. ' +
            mau: mau,
            order: s.StepOrder,
            stepType: detail.stepType || 'REVIEW',
            stepCode: detail.stepCode || '',
            taskCount: detail.taskCount || 0,
            assignees: detail.assignees || []
          }
        })

        this.dsThe = (instances || []).map(i => ({
          ...i,
          id: i.InstanceID,
          tieuDe: i.InstanceName,
          nguoiPhuTrach: i.NextSigner,
          hanChot: i.UpdateTime,
        }))
      } catch (err) {
        console.error(err)
      } finally {
        if (!isSilent) {
          this.isLoading = false
        }
      }
    },

    moDialogChiTiet: function (the) {
      if (the && the.InstanceID) {
        this.selectedInstanceId = the.InstanceID
        this.dialog.showDetail = true
      }
    },

    loadSignerProfiles: async function () {
      try {
        var rows = await apiCallAsync('WF_SignerProfile_GetList', {})
        var list = Array.isArray(rows) ? rows : (rows && Array.isArray(rows.data) ? rows.data : [])
        this.signerProfiles = list.filter(function (item) {
          var active = item.IsActive === true || Number(item.IsActive) === 1
          var certActive = item.CertIsActive === true || Number(item.CertIsActive) === 1
          return active && certActive
        })
      } catch (err) {
        this.signerProfiles = []
      }
    },

    onDrop: async function (e) {
      var $this = this
      var cardId = e.cardId
      var iCot = e.iCot
      var cot = this.dsCot[iCot]
      if (!cot) return

      var stepDefId = Number(cot.id)
      if (!stepDefId || isNaN(stepDefId)) return

      var theCard = this.dsThe.find(function (t) { return t.id === cardId })
      var tenHoSo = theCard ? (theCard.tieuDe || theCard.InstanceName) : 'hồ sơ này'

      var isFailureStep = cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE';

      var isCurrent = false;
      if (theCard) {
        if (theCard.CurrentStepDefID && typeof theCard.CurrentStepDefID === 'number') {
          isCurrent = Number(cot.id) === Number(theCard.CurrentStepDefID);
        } else if (theCard.CurrentStepOrder !== undefined && cot.order !== undefined) {
          isCurrent = Number(cot.order) === Number(theCard.CurrentStepOrder);
        }
      }
      if (isCurrent) {
        if (typeof showToast !== 'undefined' && showToast.warning) {
          showToast.warning('Hồ sơ đang ở bước này rồi.')
        }
        return
      }

      showConfirm(
        'Chuyển "' + tenHoSo + '" sang bước "' + cot.tenCot + '"?\n\nHành động này sẽ cập nhật bước hiện tại của hồ sơ.',
        function () { $this.doMoveStep(cardId, cot, stepDefId) },
        null
      )
    },

    doMoveStep: async function (cardId, cot, stepDefId) {
      try {
        var result = await apiCallAsync('WF_Instance_MoveStep', {
          InstanceID: cardId,
          ToStepDefID: stepDefId
        })
        var row = result && result[0] ? result[0] : result
        if (row && Number(row.Success) === 0) {
          if (typeof showToast !== 'undefined' && showToast.error) {
            showToast.error(row.Message || 'Không thể chuyển bước.')
          }
          return
        }
        if (typeof showToast !== 'undefined' && showToast.success) {
          showToast.success('Chuyển bước thành công!')
        }
        this.loadData()
      } catch (err) {
        var msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.message ? err.message : 'Lỗi không xác định')
        if (typeof showToast !== 'undefined' && showToast.error) {
          showToast.error('Không thể chuyển bước: ' + msg)
        }
      }
    },

    handleOpenCardFromTimeline: function (the) {
      this.viewMode = 'kanban'
      this.$nextTick(() => {
        this.moDialogChiTiet(the)
      })
    },

    openCreateDialog: function () {
      this.createPreselectedStepId = null
      this.dialog.createInstance = true
    },

    openCreateDialogForStep: function (cot) {
      this.createPreselectedStepId = cot ? cot.id : null
      this.dialog.createInstance = true
    },

    handleCloseDetail: function () {
      this.dialog.showDetail = false
      this.loadData(true)
    }
  }
	}
</script>