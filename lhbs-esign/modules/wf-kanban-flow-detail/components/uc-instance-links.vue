<template>
	<div class="wf-instance-links">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between mb-4">
      <div class="d-flex align-center ga-2">
        <v-icon size="16" color="primary">mdi-link-variant</v-icon>
        <span class="text-subtitle-2 font-weight-bold text-grey-darken-4">Liên kết nhiệm vụ</span>
        <v-chip v-if="links.length" size="x-small" color="primary" variant="tonal" class="font-weight-bold">
          {{ links.length }}
        </v-chip>
      </div>
      <v-btn variant="outlined" color="primary" height="28" class="font-weight-medium text-caption px-3"
        style="text-transform: none; border-radius: 4px; font-size: 11px !important;"
        @click="showAddForm = !showAddForm">
        <v-icon start size="12">mdi-plus</v-icon>
        Thêm liên kết
      </v-btn>
    </div>

    <!-- Add Link Form -->
    <div v-if="showAddForm" class="mb-4 pa-4 rounded-lg border bg-grey-lighten-5"
      style="border-color: #e2e8f0 !important;">
      <div class="text-caption font-weight-bold text-grey-darken-2 mb-3 text-uppercase"
        style="font-size: 10px !important; letter-spacing: 0.05em;">Thêm liên kết mới</div>

      <div class="d-flex flex-column ga-3">
        <!-- Link type -->
        <v-select v-model="newLink.linkType" :items="linkTypeOptions" item-title="label" item-value="value"
          label="Loại liên kết" variant="outlined" density="compact" hide-details
          class="wf-ant-input bg-white" />

        <!-- Search instance -->
        <div>
          <v-text-field v-model="searchKeyword" label="Tìm nhiệm vụ (nhập tên hoặc ID)"
            variant="outlined" density="compact" hide-details clearable
            prepend-inner-icon="mdi-magnify" class="wf-ant-input bg-white"
            @input="onSearchInput" @click:clear="searchResults = []" />

          <!-- Search results -->
          <div v-if="searchResults.length > 0" class="mt-1 border rounded-lg bg-white"
            style="border-color: #e2e8f0 !important; max-height: 200px; overflow-y: auto;">
            <div v-for="inst in searchResults" :key="inst.InstanceID"
              class="d-flex align-center ga-2 px-3 py-2 cursor-pointer border-bottom"
              style="border-bottom: 1px solid #f1f5f9 !important;"
              :style="newLink.targetInstanceId === inst.InstanceID ? 'background: #eff6ff;' : ''"
              @click="selectTarget(inst)">
              <v-icon size="12" :color="newLink.targetInstanceId === inst.InstanceID ? 'primary' : 'grey-darken-1'">
                {{ newLink.targetInstanceId === inst.InstanceID ? 'mdi-check-circle' : 'mdi-circle-outline' }}
              </v-icon>
              <div class="flex-grow-1 min-w-0">
                <div class="text-caption font-weight-medium text-grey-darken-4 text-truncate"
                  style="font-size: 12px !important;">{{ inst.InstanceName }}</div>
                <div class="text-caption text-grey" style="font-size: 10px !important;">
                  ID: {{ inst.InstanceID }} · {{ inst.DefinitionName || '' }}
                </div>
              </div>
              <v-chip size="x-small" :color="getStatusColor(inst.Status)" variant="tonal"
                class="font-weight-bold flex-shrink-0" style="font-size: 9px; height: 16px;">
                {{ getStatusText(inst.Status) }}
              </v-chip>
            </div>
          </div>
          <div v-if="searchKeyword && searchResults.length === 0 && !isSearching"
            class="text-caption text-grey mt-1 px-1">Không tìm thấy kết quả.</div>
        </div>

        <!-- Selected target -->
        <div v-if="newLink.targetInstanceId" class="d-flex align-center ga-2 pa-2 rounded bg-primary-lighten-5 border"
          style="border-color: #bfdbfe !important; background-color: #eff6ff !important;">
          <v-icon size="14" color="primary">mdi-check-circle</v-icon>
          <div class="flex-grow-1 min-w-0 text-caption font-weight-medium text-primary text-truncate"
            style="font-size: 12px !important;">{{ newLink.targetInstanceName }}</div>
          <v-btn icon size="x-small" variant="text" color="grey" @click="clearTarget">
            <v-icon size="12">mdi-close</v-icon>
          </v-btn>
        </div>

        <!-- Actions -->
        <div class="d-flex justify-end ga-2">
          <v-btn variant="text" color="grey" height="28" class="text-caption px-3"
            style="text-transform: none;" @click="closeAddForm">
            Hủy
          </v-btn>
          <v-btn color="primary" variant="flat" height="28" class="font-weight-bold text-caption px-4"
            style="text-transform: none; border-radius: 4px;"
            :disabled="!newLink.targetInstanceId || !newLink.linkType"
            :loading="isSaving" @click="saveLink">
            <v-icon start size="12">mdi-link-plus</v-icon>
            Tạo liên kết
          </v-btn>
        </div>
      </div>
    </div>

    <!-- Links list -->
    <div v-if="isLoading" class="d-flex justify-center py-6">
      <v-progress-circular indeterminate color="primary" size="24" />
    </div>

    <div v-else-if="links.length === 0 && !showAddForm" class="text-center py-8">
      <v-icon size="40" color="grey-lighten-1">mdi-link-off</v-icon>
      <div class="text-caption text-grey-darken-1 mt-2">Chưa có liên kết nào.</div>
    </div>

    <!-- Group by link type -->
    <div v-for="group in groupedLinks" :key="group.type" class="mb-4">
      <div class="d-flex align-center ga-2 mb-2">
        <v-chip size="x-small" :color="getLinkTypeColor(group.type)" variant="tonal" class="font-weight-bold px-2"
          style="font-size: 10px !important;">
          <v-icon start size="10">{{ getLinkTypeIcon(group.type) }}</v-icon>
          {{ getLinkTypeLabel(group.type) }}
        </v-chip>
        <span class="text-caption text-grey" style="font-size: 10px !important;">{{ group.items.length }}</span>
      </div>

      <div class="d-flex flex-column ga-1">
        <div v-for="link in group.items" :key="link.LinkID"
          class="d-flex align-center ga-3 px-3 py-2 bg-white border rounded"
          style="border-color: #e2e8f0 !important; transition: background 0.1s;"
          @mouseenter="hoveredLink = link.LinkID" @mouseleave="hoveredLink = null"
          :style="hoveredLink === link.LinkID ? 'background: #f8fafc;' : ''">

          <v-icon size="13" :color="getLinkTypeColor(group.type)">
            {{ getLinkTypeIcon(group.type) }}
          </v-icon>

          <div class="flex-grow-1 min-w-0 cursor-pointer" @click="openInstance(link)">
            <div class="text-caption font-weight-medium text-grey-darken-4 text-truncate"
              style="font-size: 12px !important;">{{ link.TargetInstanceName || link.SourceInstanceName }}</div>
            <div class="text-caption text-grey" style="font-size: 10px !important;">
              ID: {{ link.TargetInstanceID || link.SourceInstanceID }}
            </div>
          </div>

          <v-chip size="x-small" :color="getStatusColor(link.TargetStatus || link.SourceStatus)" variant="tonal"
            class="font-weight-bold flex-shrink-0" style="font-size: 9px; height: 16px;">
            {{ getStatusText(link.TargetStatus || link.SourceStatus) }}
          </v-chip>

          <v-btn icon size="x-small" variant="text" color="error" class="flex-shrink-0"
            style="opacity: 0;" :style="hoveredLink === link.LinkID ? 'opacity: 1;' : ''"
            @click="deleteLink(link)">
            <v-icon size="12">mdi-close</v-icon>
          </v-btn>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-instance-links',
  props: {
    instanceId: { type: Number, required: true }
  },
  data() {
    return {
      links: [],
      isLoading: false,
      isSaving: false,
      isSearching: false,
      showAddForm: false,
      searchKeyword: '',
      searchResults: [],
      searchTimer: null,
      hoveredLink: null,
      newLink: { linkType: 'RELATES_TO', targetInstanceId: null, targetInstanceName: '' },
      linkTypeOptions: [
        { label: 'Liên quan đến', value: 'RELATES_TO' },
        { label: 'Chặn (blocks)', value: 'BLOCKS' },
        { label: 'Bị chặn bởi', value: 'IS_BLOCKED_BY' },
        { label: 'Trùng lặp', value: 'DUPLICATES' }
      ]
    }
  },
  computed: {
    groupedLinks() {
      var groups = {}
      this.links.forEach(function (link) {
        var t = link.LinkType || 'RELATES_TO'
        if (!groups[t]) groups[t] = { type: t, items: [] }
        groups[t].items.push(link)
      })
      return Object.values(groups)
    }
  },
  watch: {
    instanceId: {
      immediate: true,
      handler(val) { if (val) this.loadLinks() }
    }
  },
  methods: {
    loadLinks: async function () {
      if (!this.instanceId) return
      this.isLoading = true
      try {
        var res = await apiCallAsync('WF_InstanceLink_GetList', { InstanceID: this.instanceId })
        this.links = res || []
      } catch (e) {
        // handled
      } finally {
        this.isLoading = false
      }
    },

    onSearchInput: function () {
      clearTimeout(this.searchTimer)
      var q = (this.searchKeyword || '').trim()
      if (q.length < 2) { this.searchResults = []; return }
      var self = this
      this.searchTimer = setTimeout(async function () {
        self.isSearching = true
        try {
          var res = await apiCallAsync('WF_Instance_Search', { Keyword: q, PageSize: 10 })
          self.searchResults = (res || []).filter(function (i) {
            return Number(i.InstanceID) !== Number(self.instanceId)
          })
        } catch (e) {
          // handled
        } finally {
          self.isSearching = false
        }
      }, 300)
    },

    selectTarget: function (inst) {
      this.newLink.targetInstanceId = inst.InstanceID
      this.newLink.targetInstanceName = inst.InstanceName
      this.searchResults = []
      this.searchKeyword = ''
    },

    clearTarget: function () {
      this.newLink.targetInstanceId = null
      this.newLink.targetInstanceName = ''
    },

    saveLink: async function () {
      if (!this.newLink.targetInstanceId || !this.newLink.linkType) return
      this.isSaving = true
      try {
        await apiCallAsync('WF_InstanceLink_Save', {
          InstanceID: this.instanceId,
          TargetInstanceID: this.newLink.targetInstanceId,
          LinkType: this.newLink.linkType
        })
        showToast.success('Đã tạo liên kết!')
        this.closeAddForm()
        await this.loadLinks()
      } catch (e) {
        // handled
      } finally {
        this.isSaving = false
      }
    },

    deleteLink: function (link) {
      var self = this
      showConfirm('Xóa liên kết này?', async function () {
        try {
          await apiCallAsync('WF_InstanceLink_Delete', { LinkID: link.LinkID })
          showToast.success('Đã xóa liên kết.')
          await self.loadLinks()
        } catch (e) {
          // handled
        }
      })
    },

    closeAddForm: function () {
      this.showAddForm = false
      this.newLink = { linkType: 'RELATES_TO', targetInstanceId: null, targetInstanceName: '' }
      this.searchKeyword = ''
      this.searchResults = []
    },

    openInstance: function (link) {
      var id = link.TargetInstanceID || link.SourceInstanceID
      if (id) window.open('/wf-kanban-flow-detail?id=' + id, '_blank')
    },

    getLinkTypeLabel: function (t) {
      return { RELATES_TO: 'Liên quan đến', BLOCKS: 'Chặn', IS_BLOCKED_BY: 'Bị chặn bởi', DUPLICATES: 'Trùng lặp' }[t] || t
    },
    getLinkTypeColor: function (t) {
      return { RELATES_TO: 'blue', BLOCKS: 'error', IS_BLOCKED_BY: 'warning', DUPLICATES: 'grey' }[t] || 'grey'
    },
    getLinkTypeIcon: function (t) {
      return { RELATES_TO: 'mdi-link', BLOCKS: 'mdi-block-helper', IS_BLOCKED_BY: 'mdi-minus-circle', DUPLICATES: 'mdi-content-copy' }[t] || 'mdi-link'
    },
    getStatusColor: function (s) {
      return { RUNNING: 'blue', WAITING_ME: 'warning', COMPLETED: 'success', CANCELLED: 'grey' }[s] || 'grey'
    },
    getStatusText: function (s) {
      return { RUNNING: 'Đang chạy', WAITING_ME: 'Chờ xử lý', COMPLETED: 'Hoàn tất', CANCELLED: 'Đã hủy' }[s] || s || ''
    }
  }
	}
</script>