<template>
	<div>
		<!-- Criteria -->
		<div class="d-flex flex-wrap ga-2 align-center">
			<div v-for="(cr, idx) in criteria" :key="idx" class="d-flex align-center ga-1 pa-1 rounded border"
				style="background: #f8fafc; border-color: #e2e8f0 !important;">
				<!-- Conjunction (AND/OR) -->
				<v-select v-if="idx > 0" v-model="logic" :items="logicOptions" variant="plain" density="compact"
					hide-details style="max-width: 68px; min-width: 60px; font-size: 10px;" class="text-caption" />

				<!-- Field -->
				<v-select v-model="cr.field" :items="fieldOptions" item-title="label" item-value="value"
					variant="outlined" density="compact" hide-details placeholder="Trường..."
					style="max-width: 130px; font-size: 11px;" class="wf-ant-input bg-white" />

				<!-- Operator -->
				<v-select v-model="cr.op" :items="operatorOptions" item-title="label" item-value="value"
					variant="outlined" density="compact" hide-details placeholder="..."
					style="max-width: 90px; font-size: 11px;" class="wf-ant-input bg-white" />

				<!-- Value -->
				<v-select v-if="cr.field === 'Status'" v-model="cr.value" :items="statusOptions" item-title="label"
					item-value="value" variant="outlined" density="compact" hide-details
					style="max-width: 120px; font-size: 11px;" class="wf-ant-input bg-white" />
				<v-select v-else-if="cr.field === 'Priority'" v-model="cr.value" :items="priorityOptions"
					item-title="label" item-value="value" variant="outlined" density="compact" hide-details clearable
					style="max-width: 120px; font-size: 11px;" class="wf-ant-input bg-white" />
				<v-text-field v-else-if="cr.field === 'DueDate' || cr.field === 'CreateTime'" v-model="cr.value"
					type="date" variant="outlined" density="compact" hide-details
					style="max-width: 140px; font-size: 11px;" class="wf-ant-input bg-white" />
				<v-text-field v-else v-model="cr.value" variant="outlined" density="compact" hide-details
					placeholder="Giá trị..." style="max-width: 140px; font-size: 11px;" class="wf-ant-input bg-white" />

				<!-- Remove -->
				<v-btn icon size="x-small" variant="text" color="grey" @click="removeCriteria(idx)">
					<v-icon size="14">mdi-close</v-icon>
				</v-btn>
			</div>

			<!-- Add criteria -->
			<v-btn variant="text" color="primary" height="28" class="text-caption font-weight-bold"
				style="text-transform: none; font-size: 11px !important;" @click="addCriteria">
				<v-icon start size="14">mdi-plus</v-icon>Thêm điều kiện
			</v-btn>

			<!-- Apply -->
			<v-btn v-if="criteria.length > 0" color="primary" variant="flat" height="28"
				class="text-caption font-weight-bold px-3 text-white"
				style="text-transform: none; font-size: 11px !important; border-radius: 4px;" @click="apply">
				Áp dụng
			</v-btn>

			<!-- Clear -->
			<v-btn v-if="criteria.length > 0" variant="text" color="grey" height="28"
				class="text-caption font-weight-medium" style="text-transform: none; font-size: 11px !important;"
				@click="clearAll">
				Xóa bộ lọc
			</v-btn>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-filter-builder',
    props: {
      projectId: { type: [Number, String], default: null }
    },
    emits: ['apply'],
    data: function () {
      return {
        logic: 'AND',
        criteria: [],
        logicOptions: ['AND', 'OR'],
        fieldOptions: [
          { label: 'Trạng thái', value: 'Status' },
          { label: 'Độ ưu tiên', value: 'Priority' },
          { label: 'Người phụ trách', value: 'AssigneeName' },
          { label: 'Tiêu đề', value: 'Title' },
          { label: 'Hạn chót', value: 'DueDate' },
          { label: 'Ngày tạo', value: 'CreateTime' }
        ],
        operatorOptions: [
          { label: 'Bằng', value: 'eq' },
          { label: 'Khác', value: 'neq' },
          { label: 'Chứa', value: 'contains' },
          { label: 'Không chứa', value: 'not_contains' },
          { label: 'Từ ngày', value: 'gte' },
          { label: 'Đến ngày', value: 'lte' }
        ],
        statusOptions: [
          { label: 'Backlog', value: 'BACKLOG' },
          { label: 'Cần làm', value: 'TODO' },
          { label: 'Đang làm', value: 'IN_PROGRESS' },
          { label: 'Hoàn tất', value: 'DONE' },
          { label: 'Bị chặn', value: 'BLOCKED' }
        ],
        priorityOptions: [
          { label: 'Khẩn cấp', value: 'CRITICAL' },
          { label: 'Cao', value: 'HIGH' },
          { label: 'Trung bình', value: 'MEDIUM' },
          { label: 'Thấp', value: 'LOW' }
        ]
      }
    },
    methods: {
      addCriteria: function () {
        this.criteria.push({ field: 'Status', op: 'eq', value: '' })
      },
      removeCriteria: function (idx) {
        this.criteria.splice(idx, 1)
        if (this.criteria.length === 0) this.apply()
      },
      clearAll: function () {
        this.criteria = []
        this.$emit('apply', { logic: 'AND', criteria: [] })
      },
      apply: function () {
        var valid = this.criteria.filter(function (c) { return c.field && c.op && c.value })
        this.$emit('apply', { logic: this.logic, criteria: valid })
      }
    }
	}
</script>