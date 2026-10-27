<template>
	<div class="wf-activity-stream">
		<!-- Header -->
		<div class="d-flex align-center justify-space-between mb-4 pb-3" style="border-bottom: 1px solid #e2e8f0;">
			<div class="d-flex align-center ga-2">
				<v-icon size="18" color="primary">mdi-history</v-icon>
				<span class="text-subtitle-2 font-weight-bold text-grey-darken-4 text-uppercase"
					style="font-size: 13px !important;">Nhật ký hoạt động</span>
			</div>
			<v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold px-2">
				{{ logs.length }}
			</v-chip>
		</div>

		<!-- Timeline -->
		<div style="overflow-y: auto; max-height: 480px; padding-right: 4px;">
			<div v-if="logs.length > 0" class="premium-timeline" style="padding-left: 8px;">
				<div v-for="log in logs" :key="log.LogID" class="premium-timeline-item" style="padding-bottom: 20px;">
					<!-- Indicator -->
					<div class="timeline-indicator-wrapper" style="width: 24px;">
						<div class="timeline-line" style="top: 24px; bottom: -20px;"></div>
						<div class="timeline-node"
							:style="{ backgroundColor: 'white', borderColor: getLogStatusColor(log.ActionCode), borderWidth: '2px', borderStyle: 'solid', width: '22px', height: '22px', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '50%' }">
							<v-icon size="12" :color="getLogStatusColor(log.ActionCode)">
								{{ getLogIcon(log.ActionCode) }}
							</v-icon>
						</div>
					</div>

					<!-- Content -->
					<div class="timeline-content-card"
						style="padding: 12px; margin-left: 10px; border-radius: 8px; border: 1px solid #e2e8f0; background-color: white;">
						<div class="d-flex align-start flex-wrap ga-2 text-left" style="width: 100%;">
							<v-chip size="x-small" :color="getLogChipColor(log.ActionCode)" variant="tonal"
								class="font-weight-bold px-2"
								style="font-size: 10px; height: 18px; border-radius: 4px;">
								{{ getLogChipText(log.ActionCode) }}
							</v-chip>
							<div class="text-caption font-weight-bold text-grey-darken-4"
								style="font-size: 12px !important; line-height: 1.4; color: #1e293b !important;">
								{{ getLogDescription(log) }}
							</div>
						</div>
						<div class="d-flex align-center mt-1 text-left flex-wrap ga-2"
							style="font-size: 11px !important; color: #64748b;">
							<div v-if="getStepName(log.StepOrder)" class="d-flex align-center">
								<v-icon size="13" class="mr-1 text-grey-darken-1">mdi-timeline-outline</v-icon>
								<span>Bước: <span class="font-weight-medium text-grey-darken-3">{{
										getStepName(log.StepOrder) }}</span></span>
							</div>
							<span v-if="getStepName(log.StepOrder)" class="text-grey-lighten-1">•</span>
							<div class="d-flex align-center">
								<v-icon size="13" class="mr-1 text-grey-darken-1">mdi-clock-outline</v-icon>
								<span>{{ formatDateTime(log.CreateTime) }}</span>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Empty state -->
			<div v-else class="text-center py-6 text-caption text-grey">
				<v-icon size="32" color="grey-lighten-1" class="mb-1">mdi-history-off</v-icon>
				<div>Chưa có nhật ký hoạt động.</div>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-request-detail-history',
  props: {
    logs: { type: Array, default: function () { return [] } },
    steps: { type: Array, default: function () { return [] } }
  },
  methods: {
    getStepName: function (stepOrder) {
      if (!stepOrder) return ''
      var found = (this.steps || []).find(function (s) { return Number(s.StepOrder) === Number(stepOrder) })
      return found ? found.StepName : ('Bước ' + stepOrder)
    },

    getLogChipText: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'INSTANCE_CREATED' || code === 'CREATE_INSTANCE') return 'Tạo mới'
      if (code === 'STAGE_CHANGED' || code === 'MOVE_STEP' || code === 'STEP_DONE' || code === 'STEP_ACTIVE') return 'Giai đoạn'
      if (code === 'UPDATE_TAG' || code === 'TAG_CHANGED' || code === 'SAVE_TAGS') return 'Nhãn'
      if (code === 'SIGNED' || code === 'SIGNED_FILE_UPLOADED' || code === 'SEND_FOR_SIGNING' || code === 'CANCEL_SIGNING' || code === 'INSTANCE_COMPLETED') return 'Ký số'
      if (code === 'ASSIGN_PIC' || code === 'UPDATE_ASSIGNEE') return 'Phân công'
      if (code === 'COMMENT_ADDED') return 'Bình luận'
      if (code === 'CANCELLED' || code === 'REJECTED') return 'Kết thúc'
      return 'Hệ thống'
    },

    getLogChipColor: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'INSTANCE_CREATED' || code === 'CREATE_INSTANCE') return 'blue'
      if (code === 'STAGE_CHANGED' || code === 'MOVE_STEP' || code === 'STEP_DONE' || code === 'STEP_ACTIVE') return 'indigo'
      if (code === 'UPDATE_TAG' || code === 'TAG_CHANGED' || code === 'SAVE_TAGS') return 'teal'
      if (code === 'SIGNED' || code === 'SIGNED_FILE_UPLOADED' || code === 'SEND_FOR_SIGNING' || code === 'CANCEL_SIGNING' || code === 'INSTANCE_COMPLETED') return 'warning'
      if (code === 'ASSIGN_PIC' || code === 'UPDATE_ASSIGNEE') return 'purple'
      if (code === 'COMMENT_ADDED') return 'cyan'
      if (code === 'CANCELLED' || code === 'REJECTED') return 'error'
      return 'grey'
    },

    getLogIcon: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'INSTANCE_CREATED' || code === 'CREATE_INSTANCE') return 'mdi-plus-circle'
      if (code === 'STAGE_CHANGED' || code === 'MOVE_STEP') return 'mdi-arrow-right-bold-circle-outline'
      if (code === 'STEP_DONE') return 'mdi-check-circle-outline'
      if (code === 'STEP_ACTIVE') return 'mdi-undo-variant'
      if (code === 'UPDATE_TAG' || code === 'TAG_CHANGED' || code === 'SAVE_TAGS') return 'mdi-tag-outline'
      if (code === 'SIGNED') return 'mdi-check-decagram-outline'
      if (code === 'SIGNED_FILE_UPLOADED') return 'mdi-file-check-outline'
      if (code === 'SEND_FOR_SIGNING') return 'mdi-send-circle-outline'
      if (code === 'CANCEL_SIGNING') return 'mdi-close-circle-outline'
      if (code === 'INSTANCE_COMPLETED') return 'mdi-flag-checkered'
      if (code === 'CANCELLED') return 'mdi-cancel'
      if (code === 'REJECTED') return 'mdi-close-octagon-outline'
      if (code === 'ASSIGN_PIC' || code === 'UPDATE_ASSIGNEE') return 'mdi-account-arrow-right-outline'
      if (code === 'COMMENT_ADDED') return 'mdi-comment-outline'
      return 'mdi-circle-medium'
    },

    getLogStatusColor: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'SIGNED' || code === 'INSTANCE_COMPLETED' || code === 'STEP_DONE') return '#28a745'
      if (code === 'CANCELLED' || code === 'CANCEL_SIGNING' || code === 'REJECTED') return '#dc3545'
      if (code === 'SEND_FOR_SIGNING' || code === 'SIGNED_FILE_UPLOADED') return '#f59e0b'
      return '#2196f3'
    },

    getLogDescription: function (log) {
      var code = String(log.ActionCode || '').toUpperCase()
      var userText = log.UserID ? (log.UserID + (log.UserFullName ? ' — ' + log.UserFullName : '')) : 'Hệ thống'

      if (code === 'INSTANCE_CREATED') {
        try {
          var parsed = JSON.parse(log.ActionDetail)
          if (parsed && parsed.Description) return userText + ' đã tạo nhiệm vụ "' + parsed.Description + '".'
        } catch (e) {}
        return userText + ' đã tạo nhiệm vụ.'
      }
      if (code === 'CANCELLED') return userText + ' đã hủy luồng công việc.'
      if (code === 'REJECTED') return userText + ' đã từ chối.'
      if (code === 'STEP_DONE') return userText + ' đã báo hoàn thành xử lý bước.'
      if (code === 'STEP_ACTIVE') return userText + ' đã thu hồi trạng thái hoàn thành bước.'
      if (code === 'SEND_FOR_SIGNING') return userText + ' đã gửi hồ sơ đi ký số.'
      if (code === 'CANCEL_SIGNING') return userText + ' đã hủy gửi ký số.'
      if (code === 'SIGNED') return userText + ' đã hoàn tất lượt ký số.'
      if (code === 'SIGNED_FILE_UPLOADED') return 'Hệ thống đã lưu file PDF sau khi ký số.'
      if (code === 'INSTANCE_COMPLETED') return userText + ' đã hoàn tất toàn bộ yêu cầu.'
      if (code === 'ASSIGN_PIC' || code === 'UPDATE_ASSIGNEE') {
        try {
          var a = JSON.parse(log.ActionDetail)
          if (a && a.AssignTo) return userText + ' đã phân công cho ' + a.AssignTo + '.'
        } catch (e) {}
        return userText + ' đã cập nhật người phụ trách.'
      }
      if (code === 'COMMENT_ADDED') return userText + ' đã thêm bình luận.'
      if (code === 'SAVE_TAGS' || code === 'UPDATE_TAG' || code === 'TAG_CHANGED') return userText + ' đã cập nhật nhãn dán.'
      if (code === 'MOVE_STEP' || code === 'STAGE_CHANGED') {
        try {
          var m = JSON.parse(log.ActionDetail)
          if (m && m.ToStepName) return userText + ' đã chuyển sang bước "' + m.ToStepName + '".'
          if (m && m.ToStep) return userText + ' đã chuyển bước → ' + m.ToStep + '.'
        } catch (e) {}
        return userText + ' đã chuyển bước.'
      }

      if (log.ActionDetail && log.ActionDetail.indexOf('{') !== 0) {
        var detailTrim = String(log.ActionDetail).trim()
        if (detailTrim.indexOf(userText) === 0 || /^NV\d+/i.test(detailTrim)) return log.ActionDetail
        return userText + ' ' + detailTrim
      }

      return userText + ' đã thực hiện thao tác.'
    },

    formatDateTime: function (val) {
      if (!val) return '—'
      var dt = new Date(val)
      if (isNaN(dt.getTime())) return val
      var hh = String(dt.getHours()).padStart(2, '0')
      var mm = String(dt.getMinutes()).padStart(2, '0')
      var dd = String(dt.getDate()).padStart(2, '0')
      var mo = String(dt.getMonth() + 1).padStart(2, '0')
      var yyyy = dt.getFullYear()
      return hh + ':' + mm + ' ' + dd + '/' + mo + '/' + yyyy
    }
  }
	}
</script>