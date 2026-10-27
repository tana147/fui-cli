<template>
	<v-dialog :model-value="modelValue" max-width="500" persistent
		@update:model-value="$emit('update:modelValue', $event)">
		<v-card class="rounded-xl" elevation="8">
			<v-card-title class="d-flex align-center ga-2 pa-5 pb-3">
				<v-icon size="20" color="primary">mdi-vector-polyline-plus</v-icon>
				<span class="text-subtitle-1 font-weight-bold">Thêm quy trình vào Project</span>
			</v-card-title>

			<v-card-text class="pa-5 pt-2">
				<!-- Chọn cách thêm -->
				<div class="d-flex ga-2 mb-4">
					<div class="wf-add-opt flex-grow-1" :class="{ 'wf-add-opt--active': mode === 'existing' }"
						@click="mode = 'existing'">
						<v-icon size="18" :color="mode === 'existing' ? 'primary' : 'grey'">mdi-link-variant</v-icon>
						<div class="wf-add-opt__title">Dùng có sẵn</div>
						<div class="wf-add-opt__sub">Gắn quy trình đã tạo</div>
					</div>
					<div class="wf-add-opt flex-grow-1" :class="{ 'wf-add-opt--active': mode === 'new' }"
						@click="mode = 'new'">
						<v-icon size="18" :color="mode === 'new' ? 'primary' : 'grey'">mdi-plus-box-outline</v-icon>
						<div class="wf-add-opt__title">Tạo mới</div>
						<div class="wf-add-opt__sub">Thiết kế quy trình mới</div>
					</div>
				</div>

				<!-- Mode: existing -->
				<div v-if="mode === 'existing'">
					<div class="text-caption text-grey-darken-3 mb-1">Chọn quy trình chưa thuộc project nào</div>
					<v-select v-model="attachDefId" :items="availableWorkflows" item-title="Name"
						item-value="DefinitionID" :loading="loading" placeholder="Chọn quy trình..." variant="outlined"
						density="compact" hide-details clearable class="wf-ant-input bg-white"
						no-data-text="Không còn quy trình rảnh — hãy tạo mới" />
					<div v-if="!loading && availableWorkflows.length === 0" class="text-caption text-grey mt-2"
						style="font-size: 11px;">
						<v-icon size="13" color="grey">mdi-information-outline</v-icon>
						Tất cả quy trình đã thuộc project khác. Hãy chọn "Tạo mới".
					</div>
				</div>

				<!-- Mode: new -->
				<div v-else class="text-caption text-grey-darken-2" style="font-size: 12px; line-height: 1.6;">
					<v-icon size="14" color="primary">mdi-information-outline</v-icon>
					Mở <b>trình thiết kế quy trình</b> để tạo mới. Quy trình tạo ra sẽ <b>tự thuộc project này</b>;
					bạn thêm bước/trường dữ liệu tại đó rồi lưu.
				</div>
			</v-card-text>

			<v-card-actions class="pa-4 pt-0 d-flex ga-2">
				<v-spacer />
				<v-btn variant="text" color="grey" :disabled="attaching" @click="close">Hủy</v-btn>
				<v-btn v-if="mode === 'existing'" color="primary" variant="flat" :loading="attaching"
					:disabled="!attachDefId" class="font-weight-bold text-caption text-white px-4"
					style="text-transform: none; border-radius: 4px;" @click="attach">
					<v-icon start size="14">mdi-link-variant</v-icon>Gắn vào project
				</v-btn>
				<v-btn v-else color="primary" variant="flat" :disabled="!projectId"
					class="font-weight-bold text-caption text-white px-4"
					style="text-transform: none; border-radius: 4px;" @click="openDesigner">
					<v-icon start size="14">mdi-vector-polyline-edit</v-icon>Mở trình thiết kế
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-workflow-create-dialog',
  props: {
    modelValue: { type: Boolean, default: false },
    projectId: { type: [Number, String], default: null }
  },
  emits: ['update:modelValue', 'success'],
  data: function () {
    return {
      mode: 'existing',
      availableWorkflows: [],
      attachDefId: null,
      loading: false,
      attaching: false
    }
  },
  watch: {
    modelValue: function (val) {
      if (val) {
        this.mode = 'existing'
        this.attachDefId = null
        this.loadAvailable()
      }
    }
  },
  methods: {
    close: function () { this.$emit('update:modelValue', false) },

    loadAvailable: async function () {
      this.loading = true
      try {
        // Lọc client-side: workflow chưa thuộc project nào
        var res = await apiCallAsync('WF_Definition_GetList', { Status: 'ALL' })
        var all = Array.isArray(res) ? res : []
        this.availableWorkflows = all.filter(function (d) { return !d.ProjectID })
      } catch (e) {
        this.availableWorkflows = []
      } finally {
        this.loading = false
      }
    },

    attach: async function () {
      if (!this.attachDefId || this.attaching) return
      this.attaching = true
      try {
        var res = await apiCallAsync('WF_Definition_SetProject', {
          DefinitionID: this.attachDefId, ProjectID: this.projectId
        })
        var row = Array.isArray(res) ? res[0] : res
        if (row && (row.Success === false || row.Success === 0)) {
          showToast.error(row.Message || 'Không thể gắn quy trình.')
          return
        }
        showToast.success('Đã gắn quy trình vào project.')
        this.$emit('success')
        this.close()
      } catch (e) { /* handled */ } finally { this.attaching = false }
    },

    openDesigner: function () {
      if (!this.projectId) return
      // Tạo mới qua trình thiết kế chuẩn, gắn sẵn project qua ?projectId
      window.location.href = '/wf-admin-workflow-detail?id=0&projectId=' + this.projectId
    }
  }
	}
</script>