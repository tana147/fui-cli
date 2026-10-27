<template>
	<div class="px-5 py-4">
		<!-- ===== Summary tiles (Bento) ===== -->
		<div class="wf-pf-grid mb-4">
			<!-- Tiến độ tổng thể -->
			<div class="wf-pf-tile">
				<div class="wf-pf-tile__head">
					<span class="wf-pf-tile__cap">Tiến độ tổng thể</span>
					<v-icon size="18" color="primary">mdi-trending-up</v-icon>
				</div>
				<div class="d-flex align-end ga-2 mt-3">
					<span class="wf-pf-tile__num">{{ overallProgress }}%</span>
					<span class="text-success text-caption font-weight-bold mb-1"
						style="font-size: 11px !important;">+2.4% tuần này</span>
				</div>
				<div class="wf-pf-progress mt-3">
					<span :style="{ width: overallProgress + '%' }"></span>
				</div>
			</div>

			<!-- Ngân sách -->
			<div class="wf-pf-tile">
				<div class="wf-pf-tile__head">
					<span class="wf-pf-tile__cap">Ngân sách</span>
					<v-icon size="18" color="primary">mdi-wallet-outline</v-icon>
				</div>
				<div class="mt-3">
					<span class="wf-pf-tile__num" style="font-size: 22px !important; line-height: 1.4;">Đang trong
						hạn</span>
					<span class="wf-pf-tile__sub d-block mt-1">Sử dụng: 42% tổng mức đầu tư</span>
				</div>
				<div class="text-success font-weight-bold mt-2 d-flex align-center ga-1" style="font-size: 11px;">
					<span>●</span> ỔN ĐỊNH
				</div>
			</div>

			<!-- Nhân sự -->
			<div class="wf-pf-tile">
				<div class="wf-pf-tile__head">
					<span class="wf-pf-tile__cap">Nhân sự</span>
					<v-icon size="18" color="primary">mdi-account-group-outline</v-icon>
				</div>
				<div class="mt-3">
					<span class="wf-pf-tile__num">85%</span>
					<span class="wf-pf-tile__sub d-block mt-1">Công suất huy động</span>
				</div>
				<div class="d-flex align-center mt-2">
					<div class="d-flex" style="margin-left: 0;">
						<v-avatar size="20" color="indigo-lighten-4" class="border border-white"
							style="margin-left: 0; min-width: unset;">
							<span class="text-caption font-weight-bold" style="font-size: 8px !important;">TD</span>
						</v-avatar>
						<v-avatar size="20" color="teal-lighten-4" class="border border-white"
							style="margin-left: -6px; min-width: unset;">
							<span class="text-caption font-weight-bold" style="font-size: 8px !important;">MH</span>
						</v-avatar>
						<v-avatar size="20" color="amber-lighten-4" class="border border-white"
							style="margin-left: -6px; min-width: unset;">
							<span class="text-caption font-weight-bold" style="font-size: 8px !important;">KB</span>
						</v-avatar>
						<v-avatar size="20" color="primary"
							class="border border-white text-white font-weight-bold d-flex align-center justify-center"
							style="margin-left: -6px; font-size: 8px !important; min-width: unset;">
							+12
						</v-avatar>
					</div>
				</div>
			</div>

			<!-- Rủi ro trọng yếu -->
			<div class="wf-pf-tile wf-pf-tile--risk">
				<div class="wf-pf-tile__head">
					<span class="wf-pf-tile__cap">Rủi ro trọng yếu</span>
					<v-icon size="18" color="error">mdi-alert</v-icon>
				</div>
				<div class="mt-3">
					<span class="wf-pf-tile__num text-error">{{ riskCount || 2 }}</span>
					<span class="wf-pf-tile__sub d-block mt-1 text-error font-weight-bold">Cảnh báo cao</span>
				</div>
				<p class="wf-pf-tile__note mt-2" style="font-size: 11px !important;">
					{{ riskCount > 0 ? 'Cần phê duyệt vật tư & thay đổi nhân sự GĐ 2' : 'Các chỉ số trong ngưỡng an
					toàn' }}
				</p>
			</div>
		</div>

		<!-- ===== Bản đồ Tiến độ Đa luồng ===== -->
		<div class="wf-pf-section mb-4">
			<div class="wf-pf-section__head">
				<div>
					<div class="wf-pf-section__title">Bản đồ Tiến độ Đa luồng</div>
					<div class="wf-pf-section__sub">Trạng thái song song của các quy trình cốt lõi</div>
				</div>
				<v-btn variant="text" color="primary" class="font-weight-bold text-caption text-none"
					@click="goToFlowDetail">
					Chi tiết luồng <v-icon end size="14">mdi-open-in-new</v-icon>
				</v-btn>
			</div>
			<div class="pa-5">
				<div v-if="loadingLanes" class="d-flex justify-center py-6">
					<v-progress-circular indeterminate color="primary" size="24" />
				</div>
				<div v-else-if="lanes.length === 0" class="text-center py-6 text-caption text-grey">
					<v-icon size="28" color="grey-lighten-1" class="mb-1">mdi-sitemap-outline</v-icon>
					<div>Chưa có quy trình cốt lõi nào trong dự án này.</div>
				</div>
				<div v-else class="d-flex flex-column">
					<div v-for="lane in lanes" :key="lane.definitionId" class="wf-pf-lane">
						<div>
							<div class="wf-pf-lane__name" :title="lane.name">{{ lane.name }}</div>
							<div class="wf-pf-lane__sub text-truncate" :title="lane.instanceName"
								style="max-width: 180px; cursor: pointer;"
								@click="lane.instanceId && openInstanceDetail(lane.instanceId)">
								{{ lane.instanceName }}
							</div>
						</div>
						<div class="wf-pf-track">
							<div v-for="step in lane.steps" :key="step.stepDefId" class="wf-pf-step">
								<div class="wf-pf-node" :class="'wf-pf-node--' + step.status">
									<v-icon v-if="step.status === 'done'" color="white" size="12">mdi-check</v-icon>
									<v-icon v-else-if="step.status === 'active'" color="white" size="12">
										mdi-dots-horizontal</v-icon>
								</div>
								<div class="wf-pf-step__label" :class="'wf-pf-step__label--' + step.status"
									:title="step.name">
									{{ step.name }}
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- ===== Bottom: Milestone + Cảnh báo ===== -->
		<div class="wf-pf-bottom">
			<!-- Milestone -->
			<div class="wf-pf-section">
				<div class="wf-pf-section__head">
					<div class="wf-pf-section__title">Lộ trình trọng điểm (3 Tháng)</div>
				</div>
				<div class="pa-4">
					<div v-if="milestones.length === 0" class="text-center py-6 text-caption text-grey">
						<v-icon size="24" color="grey-lighten-1" class="mb-1">mdi-flag-outline</v-icon>
						<div>Chưa có nhiệm vụ nào có hạn.</div>
					</div>
					<div v-for="ms in milestones" :key="ms.WorkItemID" class="wf-pf-ms" @click="$emit('open-card', ms)">
						<div class="wf-pf-ms__date">{{ formatDate(ms.DueDate) }}</div>
						<span class="wf-pf-ms__dot" :style="{ backgroundColor: getStatusHex(ms.Status) }"></span>
						<div class="wf-pf-ms__body" :class="{ 'wf-pf-ms__body--over': isOverdue(ms) }">
							<div class="wf-pf-ms__name" :title="ms.Title">{{ ms.Title }}</div>
							<div class="wf-pf-ms__meta">{{ getStatusText(ms.Status) }}</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Cảnh báo -->
			<div class="wf-pf-section wf-pf-section--alert">
				<div class="wf-pf-section__head wf-pf-section__head--alert">
					<div class="wf-pf-section__title text-error d-flex align-center ga-2">
						<v-icon size="18" color="error">mdi-bell-alert-outline</v-icon>Cảnh báo Tập trung
					</div>
				</div>
				<div class="pa-4 d-flex flex-column ga-3">
					<div v-if="alerts.length === 0" class="text-center py-6 text-caption text-grey">
						<v-icon size="24" color="success" class="mb-1">mdi-check-circle-outline</v-icon>
						<div>Không có cảnh báo nào</div>
					</div>
					<div v-for="(al, ai) in alerts" :key="ai" class="wf-pf-alert" :class="'wf-pf-alert--' + al.sev"
						@click="al.item && $emit('open-card', al.item)">
						<div class="d-flex justify-space-between align-start mb-1">
							<span class="wf-pf-alert__cat" :class="'wf-pf-alert__cat--' + al.sev">{{ al.cat }}</span>
							<span class="wf-pf-alert__sev">{{ al.sevLabel }}</span>
						</div>
						<div class="wf-pf-alert__title" :title="al.title">{{ al.title }}</div>
						<div class="wf-pf-alert__note">{{ al.note }}</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-space-portfolio',
    props: {
      projectId: { type: [Number, String], default: null },
      workItems: { type: Array, default: function () { return [] } }
    },
    emits: ['open-card'],
    data: function () {
      return {
        lanes: [],
        loadingLanes: false
      }
    },
    watch: {
      projectId: {
        handler: function (newId) {
          if (newId) {
            this.loadWorkflowLanes(newId)
          } else {
            this.lanes = []
          }
        },
        immediate: true
      }
    },
    computed: {
      activeItems: function () {
        return (this.workItems || []).filter(function (i) { return i.Status !== 'DONE' })
      },
      totalActive: function () { return (this.workItems || []).length },
      openCount: function () {
        return (this.workItems || []).filter(function (i) {
          return i.Status !== 'DONE' && i.Status !== 'BLOCKED'
        }).length
      },
      completedCount: function () {
        return (this.workItems || []).filter(function (i) { return i.Status === 'DONE' }).length
      },
      completedPct: function () {
        var total = this.totalActive || 1
        return Math.round((this.completedCount / total) * 100)
      },
      overallProgress: function () { return this.completedPct },
      blockedItems: function () {
        return (this.workItems || []).filter(function (i) { return i.Status === 'BLOCKED' })
      },
      overdueItems: function () {
        var now = new Date()
        return this.activeItems.filter(function (i) {
          return i.DueDate && new Date(i.DueDate) < now
        })
      },
      riskCount: function () {
        return this.overdueItems.length + this.blockedItems.length
      },
      milestones: function () {
        var withDue = this.activeItems.filter(function (i) { return !!i.DueDate })
        return withDue.sort(function (a, b) {
          return new Date(a.DueDate) - new Date(b.DueDate)
        }).slice(0, 5)
      },
      alerts: function () {
        var self = this
        var out = []
        this.overdueItems.slice(0, 4).forEach(function (i) {
          out.push({
            cat: 'Quá hạn', sev: 'high', sevLabel: 'High',
            title: i.Title, item: i,
            note: 'Quá hạn từ ' + self.formatDate(i.DueDate)
          })
        })
        this.blockedItems.slice(0, 4).forEach(function (i) {
          out.push({
            cat: 'Bị chặn', sev: 'med', sevLabel: 'Med',
            title: i.Title, item: i,
            note: 'Nhiệm vụ đang bị chặn, cần gỡ để tiếp tục'
          })
        })
        return out
      }
    },
    methods: {
      loadWorkflowLanes: async function (projectId) {
        this.loadingLanes = true
        try {
          var res = await apiCallAsync('WF_Definition_GetList', { Status: 'ALL' })
          var allWfs = Array.isArray(res) ? res : []
          var pid = Number(projectId)
          var projectWfs = allWfs.filter(function (d) { return Number(d.ProjectID) === pid })
          
          var lanesList = []
          for (var i = 0; i < projectWfs.length; i++) {
            var wf = projectWfs[i]
            try {
              var stepsRes = await apiCallAsync('WF_StepDefinition_GetList', { DefinitionID: wf.DefinitionID })
              var steps = Array.isArray(stepsRes) ? stepsRes : []
              steps.sort(function (a, b) { return Number(a.StepOrder) - Number(b.StepOrder) })
              
              var instsRes = await apiCallAsync('WF_Instance_GetList', { DefinitionID: wf.DefinitionID, Filter: 'ALL' })
              var instances = Array.isArray(instsRes) ? instsRes : []
              
              var activeInstance = instances.find(function (inst) {
                return inst.Status === 'RUNNING' || inst.Status === 'WAITING_ME'
              })
              if (!activeInstance && instances.length > 0) {
                activeInstance = instances[0]
              }
              
              var mappedSteps = steps.map(function (s) {
                var status = 'pending'
                if (activeInstance) {
                  if (activeInstance.Status === 'COMPLETED') {
                    status = 'done'
                  } else if (activeInstance.Status === 'CANCELLED') {
                    status = 'pending'
                  } else {
                    if (Number(s.StepOrder) < Number(activeInstance.CurrentStepOrder)) {
                      status = 'done'
                    } else if (Number(s.StepOrder) === Number(activeInstance.CurrentStepOrder)) {
                      status = 'active'
                    } else {
                      status = 'pending'
                    }
                  }
                }
                return {
                  stepDefId: s.StepDefID,
                  name: s.StepName,
                  status: status
                }
              })
              
              lanesList.push({
                definitionId: wf.DefinitionID,
                name: wf.Name,
                instanceName: activeInstance ? activeInstance.InstanceName : 'Chưa có hồ sơ',
                instanceId: activeInstance ? activeInstance.InstanceID : null,
                steps: mappedSteps
              })
            } catch (err) {
              console.error(err)
            }
          }
          this.lanes = lanesList
        } catch (e) {
          console.error(e)
          this.lanes = []
        } finally {
          this.loadingLanes = false
        }
      },
      goToFlowDetail: function () {
        if (this.projectId) {
          window.location.href = '/wf-kanban-flow?projectId=' + this.projectId
        }
      },
      openInstanceDetail: function (instanceId) {
        if (instanceId) {
          window.location.href = '/wf-kanban-flow-detail?id=' + instanceId
        }
      },
      isOverdue: function (item) {
        return item.DueDate && item.Status !== 'DONE' && new Date(item.DueDate) < new Date()
      },
      getStatusText: function (s) {
        return { BACKLOG: 'Backlog', TODO: 'Cần làm', IN_PROGRESS: 'Đang làm', DONE: 'Hoàn tất', BLOCKED: 'Bị chặn' }[s] || s || ''
      },
      getStatusHex: function (s) {
        return { BACKLOG: '#94a3b8', TODO: '#2563eb', IN_PROGRESS: '#d97706', DONE: '#16a34a', BLOCKED: '#dc2626' }[s] || '#94a3b8'
      },
      formatDate: function (val) {
        if (!val) return '—'
        var d = new Date(val)
        if (isNaN(d.getTime())) return val
        return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear()
      }
    }
	}
</script>