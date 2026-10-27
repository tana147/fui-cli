<template>
	<div class="wf-condition-group" :class="[
    isNested ? 'wf-condition-group--nested' : 'wf-condition-group--root',
    'wf-condition-group--' + (group.Logic || 'AND').toLowerCase()
  ]">
    <!-- Logic Selector Header -->
    <div class="wf-condition-group__header d-flex align-center mb-2">
      <v-select v-model="group.Logic" :items="logicOptions" item-title="label" item-value="value" variant="outlined"
        density="compact" hide-details class="bg-white wf-logic-select-full" />
      <v-spacer />
      <v-btn v-if="isNested" icon size="x-small" variant="text" color="error" class="wf-group-remove ml-2"
        @click="$emit('remove')">
        <v-icon size="14">mdi-close</v-icon>
      </v-btn>
    </div>

    <div class="wf-condition-items">
      <div v-for="(item, idx) in group.Items" :key="idx" class="wf-condition-item-row">
        <!-- Simple Condition -->
        <div v-if="!item.Logic" class="wf-condition-item-simple">
          <div class="d-flex align-start mb-2" style="gap: 8px;">
            <v-select v-model="item.FieldName" :items="sharedFieldOptions" placeholder="Chọn trường" variant="outlined"
              density="compact" hide-details style="flex: 1.5" class="wf-ant-input">
              <template v-slot:item="{ props, item }">
                <v-list-item v-bind="props">
                  <template v-slot:title>
                    <span class="font-weight-medium" style="font-size: 13px;">{{ item.title }}</span>
                  </template>
                  <template v-slot:subtitle>
                    <div class="d-flex align-center ga-1 mt-1">
                      <v-chip size="x-small" :color="getFieldTypeColor(item.raw)" variant="flat"
                        style="font-size: 8px; height: 16px;">
                        {{ getFieldTypeLabel(item.raw) }}
                      </v-chip>
                      <span class="text-grey" style="font-size: 10px;">Mã: {{ item.value }}</span>
                    </div>
                  </template>
                </v-list-item>
              </template>
            </v-select>
            <v-select v-model="item.Operator" :items="ruleOperatorOptions" item-title="label" item-value="value"
              variant="outlined" density="compact" hide-details style="max-width: 140px" class="wf-ant-input" />

            <!-- Tự động chuyển thành select khi chọn việc con cụ thể -->
            <v-select v-if="isTaskField(item.FieldName)" v-model="item.Value" :items="taskStatusOptions"
              item-title="label" item-value="value" placeholder="Chọn trạng thái..." variant="outlined"
              density="compact" hide-details style="flex: 2" class="wf-ant-input" />
            <v-text-field v-else v-model="item.Value" placeholder="Nhập giá trị..." variant="outlined" density="compact"
              hide-details style="flex: 2" class="wf-ant-input" />
            <v-btn icon size="small" variant="text" color="grey-darken-1" class="wf-ant-close" @click="removeItem(idx)">
              <v-icon size="16">mdi-close</v-icon>
            </v-btn>
          </div>
        </div>

        <!-- Nested Group -->
        <uc-workflow-condition-group v-else :group="item" :shared-field-options="sharedFieldOptions"
          :rule-operator-options="ruleOperatorOptions" :is-nested="true" @remove="removeItem(idx)" />
      </div>
    </div>

    <div class="wf-condition-group__footer d-flex align-center mt-2">
      <v-btn variant="text" color="primary" size="x-small" class="font-weight-bold wf-add-btn" @click="addCondition">
        <v-icon start size="13">mdi-plus</v-icon> Thêm điều kiện
      </v-btn>
      <v-btn variant="text" color="primary" size="x-small" class="font-weight-bold wf-add-btn ml-2" @click="addGroup">
        <v-icon start size="13">mdi-plus-box-outline</v-icon> Thêm nhóm
      </v-btn>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-workflow-condition-group',
  props: {
    group: { type: Object, required: true },
    sharedFieldOptions: { type: Array, required: true },
    ruleOperatorOptions: { type: Array, required: true },
    isNested: { type: Boolean, default: false }
  },
  data: function () {
    return {
      logicOptions: [
        { value: "AND", label: "Thoả mãn tất cả điều kiện dưới đây" },
        { value: "OR", label: "Thoả mãn ít nhất 1 trong các điều kiện" }
      ],
      taskStatusOptions: [
        { value: "DONE", label: "Đã hoàn thành (DONE)" },
        { value: "TODO", label: "Chưa hoàn thành (TODO)" }
      ]
    }
  },
  methods: {
    isTaskField: function (fieldName) {
      return String(fieldName || '').startsWith('task_')
    },
    getFieldTypeLabel: function (itemRaw) {
      return itemRaw && itemRaw.type === 'checklist' ? 'Checklist' : 'Trường tùy chỉnh'
    },
    getFieldTypeColor: function (itemRaw) {
      return itemRaw && itemRaw.type === 'checklist' ? 'primary' : 'blue-grey'
    },
    addCondition: function () {
      if (!this.group.Items) this.group.Items = [];
      this.group.Items.push({ FieldName: "", Operator: "==", Value: "" });
    },
    addGroup: function () {
      if (!this.group.Items) this.group.Items = [];
      this.group.Items.push({ Logic: "AND", Items: [] });
    },
    removeItem: function (idx) {
      this.group.Items.splice(idx, 1);
    }
  }
	}
</script>