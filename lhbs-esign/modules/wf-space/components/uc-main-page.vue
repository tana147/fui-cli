<template>
	<uc-wf-shell title="LHBS Workflow" subtitle="Không gian làm việc">

		<!-- Space Header -->
		<div class="wf-space-header border-bottom bg-white d-flex align-center"
			style="height: 56px; padding: 0 20px; border-bottom: 1px solid #dfe1e5 !important; gap: 12px;">

			<!-- Project Picker -->
			<v-menu transition="slide-y-transition" offset="4">
				<template v-slot:activator="{ props }">
					<div v-bind="props" class="d-flex align-center cursor-pointer ga-2 pr-3 border-right h-100"
						style="border-right: 1px solid #dfe1e5 !important;">
						<div class="wf-space-icon"
							:style="{ background: selectedProject ? (selectedProject.Color || '#217D46') : '#217D46' }">
							<v-icon size="14" color="white">{{ selectedProject ? (selectedProject.Icon || 'mdi-sitemap')
								:
								'mdi-view-grid-outline' }}</v-icon>
						</div>
						<span class="font-weight-bold"
							style="font-size: 14px; color: #1e293b; white-space: nowrap; max-width: 200px; overflow: hidden; text-overflow: ellipsis;">
							{{ selectedProject ? selectedProject.Name : 'Chọn Project' }}
						</span>
						<v-icon size="16" color="grey-darken-1">mdi-chevron-down</v-icon>
					</div>
				</template>
				<v-list density="compact" class="py-1 bg-white"
					style="border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.1) !important; min-width: 280px; max-height: 420px; overflow-y: auto;">
					<v-list-subheader class="text-caption font-weight-bold text-uppercase px-3"
						style="font-size: 10px !important; letter-spacing: 0.05em; color: #64748b;">
						Chọn Project
					</v-list-subheader>
					<v-divider class="mx-2 mb-1"></v-divider>
					<v-list-item v-for="p in projects" :key="p.ProjectID" :active="selectedProjectId === p.ProjectID"
						color="primary" class="rounded-md mx-1 px-3" style="min-height: 42px;"
						@click="selectProject(p)">
						<template v-slot:prepend>
							<div class="wf-space-icon mr-2" style="width: 22px; height: 22px;"
								:style="{ background: p.Color || '#217D46' }">
								<v-icon size="12" color="white">{{ p.Icon || 'mdi-sitemap' }}</v-icon>
							</div>
						</template>
						<v-list-item-title class="font-weight-medium" style="font-size: 13px !important;">{{ p.Name }}
						</v-list-item-title>
						<v-list-item-subtitle class="text-caption text-grey" style="font-size: 10px !important;">
							{{ p.Code }}
						</v-list-item-subtitle>
					</v-list-item>
					<v-list-item v-if="projects.length === 0" class="px-3">
						<v-list-item-title class="text-caption text-grey text-center">Chưa có project nào
						</v-list-item-title>
					</v-list-item>
					<template v-if="canCreateProject">
						<v-divider class="mx-2 my-1"></v-divider>
						<v-list-item class="rounded-md mx-1 px-3" style="min-height: 38px;" @click="openCreateProject">
							<template v-slot:prepend>
								<v-icon size="16" color="primary" class="mr-2">mdi-plus-circle-outline</v-icon>
							</template>
							<v-list-item-title class="font-weight-bold text-primary"
								style="font-size: 12px !important;">Tạo Project
								mới</v-list-item-title>
						</v-list-item>
					</template>
				</v-list>
			</v-menu>

			<!-- View Tabs -->
			<div class="d-flex align-center h-100 ga-1">
				<div v-for="tab in viewTabs" :key="tab.key"
					class="wf-space-tab cursor-pointer d-flex align-center ga-1 px-3 h-100 font-weight-medium"
					:class="currentView === tab.key ? 'wf-space-tab--active' : 'text-grey-darken-1'"
					@click="currentView = tab.key"
					style="font-size: 12px; border-bottom: 2px solid transparent; transition: all 0.15s;">
					<v-icon size="14">{{ tab.icon }}</v-icon>
					{{ tab.label }}
				</div>
			</div>

			<v-spacer />

			<!-- Filter toggle -->
			<v-btn v-if="selectedProjectId && currentView !== 'settings'" variant="outlined" color="grey-darken-2"
				height="32" class="font-weight-medium text-caption px-3 mr-2"
				style="text-transform: none; border-radius: 4px; font-size: 12px !important; border-color: #cbd5e1 !important;"
				@click="showFilterPanel = !showFilterPanel">
				<v-icon start size="14">mdi-filter-outline</v-icon>
				Lọc
				<v-chip v-if="activeFilterCount > 0" size="x-small" color="primary" variant="flat"
					class="ml-1 font-weight-bold" style="font-size: 9px; height: 16px;">{{ activeFilterCount }}</v-chip>
			</v-btn>

			<!-- Actions -->
			<v-btn v-if="currentView !== 'settings'" color="primary" variant="flat" height="32"
				class="font-weight-medium text-caption px-4 text-white" prepend-icon="mdi-plus"
				:disabled="!selectedProjectId" @click="openCreateDialog"
				style="text-transform: none; border-radius: 4px; font-size: 12px !important;">
				Tạo nhiệm vụ
			</v-btn>
		</div>

		<!-- Filter panel -->
		<div v-if="showFilterPanel && selectedProjectId" class="px-5 py-3 border-bottom bg-grey-lighten-5"
			style="border-bottom: 1px solid #e2e8f0 !important;">
			<uc-filter-builder :project-id="selectedProjectId" @apply="onFilterApply" />
		</div>

		<!-- Loading state -->
		<div v-if="isLoading" class="d-flex justify-center align-center" style="min-height: 60vh;">
			<v-progress-circular indeterminate color="primary" size="48" />
		</div>

		<!-- Empty: no project -->
		<div v-else-if="!selectedProjectId" class="d-flex flex-column align-center justify-center text-center"
			style="min-height: 60vh;">
			<v-icon size="72" color="grey-lighten-1">mdi-view-grid-plus-outline</v-icon>
			<div class="text-h6 text-grey-darken-1 mt-4">Chọn một Project để bắt đầu</div>
			<div class="text-caption text-grey mt-2">Mỗi Project gom nhiều nhiệm vụ, thành viên và lộ trình.</div>
			<v-btn v-if="canCreateProject" color="primary" variant="flat"
				class="mt-4 text-white font-weight-bold text-caption px-4"
				style="text-transform: none; border-radius: 4px;" @click="openCreateProject">
				<v-icon start size="16">mdi-plus</v-icon>Tạo Project mới
			</v-btn>
		</div>

		<!-- Project selected -->
		<template v-else>
			<!-- Settings view -->
			<div v-show="currentView === 'settings'">
				<uc-space-settings v-if="selectedProject" :project="selectedProject" :can-manage="canManageProject"
					@saved="onProjectChanged" @edit="openEditProject" />
			</div>

			<!-- Views -->
			<template v-if="currentView !== 'settings'">
				<div v-show="currentView === 'portfolio'">
					<uc-space-portfolio :project-id="selectedProjectId" :work-items="filteredWorkItems"
						@open-card="openCardDetail" />
				</div>

				<div v-show="currentView === 'board'">
					<uc-board :work-items="filteredWorkItems" @open-card="openCardDetail" @refresh="loadWorkItems" />
				</div>

				<div v-show="currentView === 'backlog'">
					<uc-backlog :work-items="filteredWorkItems" @open-card="openCardDetail" @refresh="loadWorkItems" />
				</div>

				<div v-show="currentView === 'list'">
					<uc-list-view :work-items="filteredWorkItems" @open-card="openCardDetail"
						@refresh="loadWorkItems" />
				</div>

				<div v-show="currentView === 'timeline'">
					<uc-space-timeline :work-items="filteredWorkItems" @open-card="openCardDetail" />
				</div>
			</template>
		</template>

		<!-- Dialog: Tạo nhiệm vụ -->
		<uc-task-create-dialog v-model="dialog.createTask" :project-id="selectedProjectId" :work-item="editingWorkItem"
			@success="loadWorkItems" />

		<!-- Dialog: Tạo/Sửa Project -->
		<uc-project-create-dialog v-model="dialog.project" :project="editingProject" @success="onProjectSaved" />

		<!-- Dialog: Chi tiết WorkItem -->
		<uc-workitem-detail v-model="showWorkItemDetail" :work-item="selectedWorkItem" @saved="loadWorkItems"
			@deleted="onWorkItemDeleted" />

	</uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      projects: [],
      selectedProjectId: null,
      workItems: [],
      currentView: 'board',
      isLoading: false,

      showFilterPanel: false,
      activeFilter: null,

      permissions: [],

      dialog: { createTask: false, project: false },
      editingProject: null,
      editingWorkItem: null,

      showWorkItemDetail: false,
      selectedWorkItem: null,

      viewTabs: [
        { key: 'portfolio', label: 'Tổng quan', icon: 'mdi-view-dashboard-outline' },
        { key: 'board', label: 'Board', icon: 'mdi-view-column-outline' },
        { key: 'backlog', label: 'Backlog', icon: 'mdi-format-list-bulleted' },
        { key: 'list', label: 'Danh sách', icon: 'mdi-table' },
        { key: 'timeline', label: 'Timeline', icon: 'mdi-chart-gantt' },
        { key: 'settings', label: 'Cài đặt', icon: 'mdi-cog-outline' }
      ]
    }
  },

  computed: {
    selectedProject: function () {
      if (!this.selectedProjectId) return null
      return this.projects.find(function (p) { return p.ProjectID === this.selectedProjectId }.bind(this)) || null
    },
    isAdmin: function () {
      return this.permissions.indexOf('admin-all') !== -1 || this.permissions.indexOf('project-manage') !== -1
    },
    canCreateProject: function () {
      return this.isAdmin || this.permissions.indexOf('project-create') !== -1
    },
    canManageProject: function () {
      return this.isAdmin || (this.selectedProject && this.selectedProject.MyRole === 'LEAD')
    },
    activeFilterCount: function () {
      return this.activeFilter && this.activeFilter.criteria ? this.activeFilter.criteria.length : 0
    },
    filteredWorkItems: function () {
      var list = this.workItems
      if (!this.activeFilter || !this.activeFilter.criteria || this.activeFilter.criteria.length === 0) return list
      var logic = this.activeFilter.logic || 'AND'
      var criteria = this.activeFilter.criteria
      return list.filter(function (item) {
        var results = criteria.map(function (c) {
          var val = (item[c.field] || '')
          var cv = (c.value || '')
          if (c.op === 'eq') return String(val).toLowerCase() === String(cv).toLowerCase()
          if (c.op === 'neq') return String(val).toLowerCase() !== String(cv).toLowerCase()
          if (c.op === 'contains') return String(val).toLowerCase().includes(String(cv).toLowerCase())
          if (c.op === 'not_contains') return !String(val).toLowerCase().includes(String(cv).toLowerCase())
          if (c.op === 'gte') return new Date(val) >= new Date(cv)
          if (c.op === 'lte') return new Date(val) <= new Date(cv)
          return true
        })
        return logic === 'OR' ? results.some(Boolean) : results.every(Boolean)
      })
    }
  },

  mounted: function () {
    this.initPage()
  },

  methods: {
    initPage: async function () {
      this.isLoading = true
      try {
        await this.loadPermissions()
        await this.loadProjects()

        var params = new URLSearchParams(window.location.search)
        var pid = parseInt(params.get('projectId') || '0')
        if (!pid) pid = parseInt(localStorage.getItem('wf_space_projectId') || '0')
        if (pid && this.projects.some(function (p) { return p.ProjectID === pid })) {
          await this.selectProject({ ProjectID: pid })
        }
      } catch (e) {
        console.error(e)
      } finally {
        this.isLoading = false
      }
    },

    loadPermissions: async function () {
      try {
        var res = await apiCallAsync('WF_User_GetPermissions', {})
        this.permissions = (Array.isArray(res) ? res : []).map(function (r) { return r.PermissionKey })
      } catch (e) {
        this.permissions = []
      }
    },

    loadProjects: async function () {
      try {
        var res = await apiCallAsync('WF_Project_GetList', { Status: 'ACTIVE' })
        this.projects = Array.isArray(res) ? res : []
      } catch (e) {
        this.projects = []
      }
    },

    selectProject: async function (p) {
      this.selectedProjectId = p.ProjectID
      localStorage.setItem('wf_space_projectId', String(p.ProjectID))
      this.workItems = []
      await this.loadWorkItems()
    },

    loadWorkItems: async function () {
      if (!this.selectedProjectId) return
      this.isLoading = true
      try {
        var res = await apiCallAsync('WF_WorkItem_GetList', { ProjectID: this.selectedProjectId })
        this.workItems = Array.isArray(res) ? res : []
      } catch (e) {
        this.workItems = []
      } finally {
        this.isLoading = false
      }
    },

    openCardDetail: function (item) {
      if (item && item.WorkItemID) {
        this.selectedWorkItem = item
        this.showWorkItemDetail = true
      }
    },

    openCreateDialog: function () {
      this.editingWorkItem = null
      this.dialog.createTask = true
    },

    openCreateProject: function () {
      this.editingProject = null
      this.dialog.project = true
    },

    openEditProject: function () {
      this.editingProject = this.selectedProject
      this.dialog.project = true
    },

    onProjectSaved: async function (newProjectId) {
      await this.loadProjects()
      if (newProjectId && this.projects.some(function (p) { return p.ProjectID === newProjectId })) {
        await this.selectProject({ ProjectID: newProjectId })
      }
    },

    onProjectChanged: function () {
      this.loadProjects()
    },

    onWorkItemDeleted: function () {
      this.showWorkItemDetail = false
      this.selectedWorkItem = null
      this.loadWorkItems()
    },

    onFilterApply: function (filter) {
      this.activeFilter = filter
    }
  }
	}
</script>