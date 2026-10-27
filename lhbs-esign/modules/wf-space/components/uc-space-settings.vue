<template>
	<div class="wf-set px-5 py-4">
		<!-- Section: Thông tin Project -->
		<div class="wf-pf-section mb-4">
			<div class="wf-pf-section__head">
				<div class="wf-pf-section__title">Thông tin Project</div>
				<v-btn v-if="canManage" variant="outlined" height="28" color="primary" class="text-caption px-3"
					style="text-transform: none; border-radius: 4px; font-size: 11px !important;"
					@click="$emit('edit')">
					<v-icon start size="14">mdi-pencil-outline</v-icon>Chỉnh sửa
				</v-btn>
			</div>
			<div class="pa-4">
				<div v-if="project" class="d-flex ga-4">
					<div class="wf-space-icon" style="width: 44px; height: 44px; border-radius: 12px; flex-shrink: 0;"
						:style="{ background: project.Color || '#217D46' }">
						<v-icon size="22" color="white">{{ project.Icon || 'mdi-sitemap' }}</v-icon>
					</div>
					<div>
						<div class="text-subtitle-1 font-weight-bold text-grey-darken-4">{{ project.Name }}</div>
						<div class="text-caption text-grey-darken-1 mt-0.5" style="font-size: 11px;">
							Mã: <b>{{ project.Code }}</b>
							· Tạo: {{ formatDate(project.CreateTime) }}
							· Trạng thái: <v-chip size="x-small"
								:color="project.Status === 'ACTIVE' ? 'success' : 'grey'" variant="tonal"
								class="font-weight-bold" style="font-size: 9px;">
								{{ project.Status === 'ACTIVE' ? 'Đang hoạt động' : project.Status }}
							</v-chip>
						</div>
						<div v-if="project.Description" class="text-caption text-grey-darken-2 mt-1"
							style="font-size: 12px;">
							{{ project.Description }}
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Section: Thành viên -->
		<div class="wf-pf-section">
			<div class="wf-pf-section__head">
				<div>
					<div class="wf-pf-section__title">Thành viên</div>
					<div class="wf-pf-section__sub">Quản lý thành viên trong project</div>
				</div>
			</div>
			<div class="pa-4">
				<uc-project-members v-if="project" :project-id="project.ProjectID" :can-manage="canManage" />
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-space-settings',
    props: {
      project: { type: Object, default: null },
      canManage: { type: Boolean, default: false }
    },
    emits: ['saved', 'edit'],
    methods: {
      formatDate: function (val) {
        if (!val) return '—'
        var d = new Date(val)
        if (isNaN(d.getTime())) return val
        return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear()
      }
    }
	}
</script>