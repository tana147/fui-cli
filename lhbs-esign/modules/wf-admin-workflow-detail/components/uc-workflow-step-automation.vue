<template>
	<div class="wf-automation-tab">
    <!-- Basic Settings: chỉ hiện khi bước là SIGN -->
    <v-card v-if="activeStep.StepType === 'SIGN'" variant="outlined"
      class="mb-3 rounded-lg shadow-sm wf-automation-card">
      <div class="bg-blue-lighten-5 px-3 py-2 border-b d-flex align-center">
        <v-icon size="16" color="primary" class="mr-2">mdi-cog-outline</v-icon>
        <span class="text-caption font-weight-bold color-primary">Cài đặt quy trình</span>
      </div>
      <div class="pa-4 bg-white">
        <div>
          <div class="font-weight-bold text-error mb-2 d-flex align-center" style="font-size: 11px;">
            <v-icon size="14" color="error" class="mr-1">mdi-undo-variant</v-icon> KHI BƯỚC NÀY BỊ TỪ CHỐI,
            QUAY VỀ BƯỚC:
          </div>
          <v-select v-model="activeStep.OnRejectGoToStep" :items="rejectOptions" item-title="label" item-value="value"
            variant="outlined" density="compact" hide-details placeholder="Chọn bước..." class="bg-white" />
        </div>
      </div>
    </v-card>

    <!-- Danh sách quy tắc tự động hóa (phẳng, không có v-card bao ngoài) -->
    <div v-if="editingRuleIdx === null">
      <div class="d-flex align-center justify-space-between mb-2">
        <div class="d-flex align-center">
          <v-icon size="14" color="primary" class="mr-1">mdi-robot-outline</v-icon>
          <span class="text-caption font-weight-bold text-grey-darken-3">
            Quy tắc tự động hóa ({{ (activeStep.AutomationRules || []).length }})
          </span>
        </div>
        <v-btn variant="text" color="primary" size="x-small" class="font-weight-bold text-none"
          @click="addAutomationRule">
          <v-icon start size="13">mdi-plus</v-icon> Thêm quy tắc
        </v-btn>
      </div>

      <div>
        <div v-for="(rule, rIdx) in (activeStep.AutomationRules || [])" :key="rIdx" class="wf-task-row cursor-pointer"
          @click="editingRuleIdx = rIdx">
          <div class="wf-task-row__index bg-blue-lighten-5">
            <v-icon size="14" color="primary">mdi-lightning-bolt</v-icon>
          </div>
          <div class="wf-task-row__body">
            <div class="text-caption font-weight-bold text-grey-darken-4 mb-0.5">{{ rule.RuleName }}</div>
            <div class="d-flex align-center text-grey-darken-1 flex-wrap" style="font-size: 11px; line-height: 1.2;">
              <span class="mr-2 font-weight-bold text-primary">{{ getRuleEventLabel(rule.Event) }}</span>
              <v-icon size="10" class="mr-2">mdi-chevron-right</v-icon>
              <span class="text-blue-darken-2">{{ getRuleActionLabel(rule.Action.Type) }}</span>
              <span v-if="getRuleDetailSummary(rule)" class="text-grey border-left ml-2 pl-2">
                {{ getRuleDetailSummary(rule) }}
              </span>
            </div>
          </div>
          <v-btn icon size="x-small" variant="text" color="error" class="wf-task-row__remove"
            @click.stop="removeAutomationRule(rIdx)">
            <v-icon size="14">mdi-close</v-icon>
          </v-btn>
        </div>

        <div v-if="!activeStep.AutomationRules || !activeStep.AutomationRules.length" class="wf-empty-box mt-2">
          Chưa có quy tắc tự động hóa nào. Bấm "Thêm quy tắc" để bắt đầu.
        </div>
      </div>
    </div>

    <!-- Rule Editor View (Inline) -->
    <div class="wf-template-preview mb-4 overflow-visible"
      v-else-if="editingRuleIdx !== null && activeStep.AutomationRules && activeStep.AutomationRules[editingRuleIdx]">
      <div class="wf-tprev-header justify-space-between" style="background-color: #e8f5e9;">
        <div class="d-flex align-center gap-2">
          <div class="wf-tprev-icon">
            <v-icon size="18" color="green-darken-3">mdi-cog-outline</v-icon>
          </div>
          <div class="wf-tprev-info">
            <div class="wf-tprev-name text-green-darken-3">Chỉnh sửa quy tắc</div>
          </div>
        </div>
        <v-btn icon="mdi-close" size="small" variant="text" color="grey-darken-1" @click="editingRuleIdx = null" />
      </div>

      <div class="wf-tprev-body pa-4">
        <!-- Tên quy tắc -->
        <div class="mb-4">
          <v-row dense>
            <v-col cols="12" md="6">
              <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Tên quy tắc</div>
              <v-text-field v-model="activeStep.AutomationRules[editingRuleIdx].RuleName" variant="outlined"
                density="compact" hide-details class="bg-white wf-ant-input" />
            </v-col>
          </v-row>
        </div>

        <!-- Sự kiện & Hành động -->
        <div class="mb-4">
          <v-row dense>
            <v-col cols="12" md="6">
              <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Sự kiện kích hoạt</div>
              <v-select v-model="activeStep.AutomationRules[editingRuleIdx].Event" :items="ruleEventOptions"
                item-title="label" item-value="value" variant="outlined" density="compact" hide-details
                class="bg-white wf-ant-input">
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :subtitle="item.raw.description" />
                </template>
              </v-select>
            </v-col>
            <v-col cols="12" md="6">
              <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Hành động</div>
              <v-select v-model="activeStep.AutomationRules[editingRuleIdx].Action.Type" :items="ruleActionOptions"
                item-title="label" item-value="value" variant="outlined" density="compact" hide-details
                class="bg-white wf-ant-input">
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template v-slot:title>
                      <div class="font-weight-medium mb-1" style="font-size: 13px;">{{ item.title }}</div>
                    </template>
                    <template v-slot:subtitle>
                      <div class="text-caption text-grey-darken-1" style="font-size: 11px; line-height: 1.2;">
                        {{ item.raw.description }}
                      </div>
                    </template>
                  </v-list-item>
                </template>
              </v-select>
            </v-col>
          </v-row>
        </div>

        <!-- Tham số: Tạo công việc ở luồng khác -->
        <div v-if="activeStep.AutomationRules[editingRuleIdx].Action.Type === 'CROSS_WF_CREATE'"
          class="wf-template-preview mb-4 overflow-visible">
          <div class="wf-tprev-header" style="background-color: #f6ffed;">
            <div class="wf-tprev-icon" style="width: 24px; height: 24px;">
              <v-icon size="14" color="green-darken-2">mdi-link-variant</v-icon>
            </div>
            <div class="wf-tprev-info">
              <div class="wf-tprev-name text-green-darken-2">Thiết lập luồng đích</div>
            </div>
          </div>
          <div class="wf-tprev-body pa-3">
            <v-row dense>
              <v-col cols="12" md="6">
                <v-select v-model="activeStep.AutomationRules[editingRuleIdx].Action.Params.TargetWF"
                  :items="allDefinitions" item-title="Name" item-value="DefinitionID" placeholder="Chọn luồng..."
                  variant="outlined" density="compact" hide-details class="bg-white wf-ant-input"
                  @update:model-value="onTargetWFChange" />
              </v-col>
              <v-col cols="12" md="6">
                <v-select v-model="activeStep.AutomationRules[editingRuleIdx].Action.Params.TargetStep"
                  :items="targetSteps" item-title="label" item-value="value" placeholder="Chọn bước bắt đầu..."
                  variant="outlined" density="compact" hide-details class="bg-white wf-ant-input"
                  :disabled="!activeStep.AutomationRules[editingRuleIdx].Action.Params.TargetWF" />
              </v-col>
            </v-row>
          </div>
        </div>

        <!-- Tham số: Nhảy đến bước -->
        <div v-if="activeStep.AutomationRules[editingRuleIdx].Action.Type === 'JUMP_TO'"
          class="wf-template-preview mb-4 overflow-visible">
          <div class="wf-tprev-header" style="background-color: #fff7e6;">
            <div class="wf-tprev-icon" style="width: 24px; height: 24px;">
              <v-icon size="14" color="orange-darken-3">mdi-debug-step-over</v-icon>
            </div>
            <div class="wf-tprev-info">
              <div class="wf-tprev-name text-orange-darken-3">Thiết lập bước đích</div>
            </div>
          </div>
          <div class="wf-tprev-body pa-3">
            <v-select v-model="activeStep.AutomationRules[editingRuleIdx].Action.Params.TargetStep"
              :items="rejectOptions" item-title="label" item-value="value" placeholder="Nhảy đến bước..."
              variant="outlined" density="compact" hide-details class="bg-white wf-ant-input" />
          </div>
        </div>

        <!-- Tham số: Cập nhật trường dữ liệu -->
        <div v-if="activeStep.AutomationRules[editingRuleIdx].Action.Type === 'UPDATE_FIELD'"
          class="wf-template-preview mb-4 overflow-visible">
          <div class="wf-tprev-header" style="background-color: #f0f5ff;">
            <div class="wf-tprev-icon" style="width: 24px; height: 24px;">
              <v-icon size="14" color="blue-darken-3">mdi-database-edit-outline</v-icon>
            </div>
            <div class="wf-tprev-info">
              <div class="wf-tprev-name text-blue-darken-3">Thiết lập trường cập nhật</div>
            </div>
          </div>
          <div class="wf-tprev-body pa-3">
            <v-row dense>
              <v-col cols="12" md="6">
                <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Chọn trường dữ liệu</div>
                <v-select v-model="activeStep.AutomationRules[editingRuleIdx].Action.Params.FieldName"
                  :items="sharedFieldOptions" item-title="title" item-value="value" placeholder="Chọn trường..."
                  variant="outlined" density="compact" hide-details class="bg-white wf-ant-input" />
              </v-col>
              <v-col cols="12" md="6">
                <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Giá trị mới</div>
                <v-text-field v-model="activeStep.AutomationRules[editingRuleIdx].Action.Params.FieldValue"
                  placeholder="Nhập giá trị gán..." variant="outlined" density="compact" hide-details
                  class="bg-white wf-ant-input" />
              </v-col>
            </v-row>
          </div>
        </div>

        <!-- Tham số: Gán người phụ trách -->
        <div v-if="activeStep.AutomationRules[editingRuleIdx].Action.Type === 'ASSIGN_PIC'"
          class="wf-template-preview mb-4 overflow-visible">
          <div class="wf-tprev-header" style="background-color: #f9f0ff;">
            <div class="wf-tprev-icon" style="width: 24px; height: 24px;">
              <v-icon size="14" color="purple-darken-3">mdi-account-arrow-left-outline</v-icon>
            </div>
            <div class="wf-tprev-info">
              <div class="wf-tprev-name text-purple-darken-3">Thiết lập người phụ trách</div>
            </div>
          </div>
          <div class="wf-tprev-body pa-3">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Chọn người phụ trách</div>
            <v-autocomplete v-model="activeStep.AutomationRules[editingRuleIdx].Action.Params.AssignTo"
              :items="localAssigneeOptions" item-title="title" item-value="value" placeholder="Chọn người phụ trách..."
              v-model:search="userSearchText" @update:search="onUserSearch" :loading="isSearchingUsers"
              density="compact" variant="outlined" hide-details prepend-inner-icon="mdi-account"
              class="bg-white wf-ant-input" />
          </div>
        </div>

        <!-- Thiết lập điều kiện -->
        <div class="mt-4 border rounded bg-grey-lighten-5 overflow-hidden">
          <div class="px-3 py-1.5 border-b bg-grey-lighten-4 d-flex align-center">
            <v-icon size="14" color="grey-darken-2" class="mr-2">mdi-filter-variant</v-icon>
            <div class="text-caption font-weight-bold text-grey-darken-3">Thiết lập điều kiện</div>
          </div>
          <div class="pa-4">
            <uc-workflow-condition-group :group="activeStep.AutomationRules[editingRuleIdx].ConditionGroup"
              :shared-field-options="sharedFieldOptions" :rule-operator-options="ruleOperatorOptions" />
          </div>
        </div>

        <div class="mt-6 text-right">
          <v-btn color="primary" variant="flat" class="font-weight-bold text-none" @click="saveAutomationRule"
            style="letter-spacing: 0.5px;">Lưu quy tắc</v-btn>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    activeStep: { type: Object, required: true },
    rejectOptions: { type: Array, required: true },
    allDefinitions: { type: Array, required: true },
    sharedFieldOptions: { type: Array, required: true },
    assigneeOptions: { type: Array, default: () => [] }
  },
  data: function () {
    return {
      editingRuleIdx: null,
      targetSteps: [],
      userOptions: [],
      userSearchText: "",
      searchedUsers: [],
      isSearchingUsers: false,
      ruleEventOptions: [
        { value: "TASK_CREATED", label: "Khi một công việc mới được tạo", description: "Kích hoạt ngay sau khi một công việc mới được tạo thành công trong quy trình." },
        { value: "STAGE_CHANGED", label: "Khi một công việc được chuyển giai đoạn", description: "Kích hoạt khi một công việc được kéo thả sang một cột/giai đoạn mới. Đây là trigger phổ biến nhất." },
        { value: "SUBTASK_DONE", label: "Khi một việc con được hoàn thành", description: "Kích hoạt khi người dùng tick hoàn thành một mục trong checklist." }
      ],
      ruleActionOptions: [
        { value: "CROSS_WF_CREATE", label: "Tạo công việc ở luồng khác", description: "Tự động tạo một công việc mới trong một App và quy trình khác, có thể sao chép dữ liệu." },
        { value: "UPDATE_FIELD", label: "Cập nhật trường dữ liệu", description: "Tự động thay đổi giá trị của một hoặc nhiều trường trong chính công việc đó." },
        { value: "ASSIGN_PIC", label: "Gán người phụ trách", description: "Tự động gán công việc cho một người cụ thể hoặc một người trong trường dữ liệu." },
        { value: "SEND_EMAIL", label: "Gửi Email", description: "Tự động gửi một email dựa trên một mẫu có sẵn." },
        { value: "AUTO_COMPLETE", label: "Tự động hoàn thành", description: "Tự động chuyển trạng thái hoàn thành cho bước hiện tại." },
        { value: "SKIP_STEP", label: "Bỏ qua bước này", description: "Bỏ qua bước hiện tại và chuyển sang bước tiếp theo." },
        { value: "JUMP_TO", label: "Chuyển đến bước...", description: "Phân nhánh đến một bước cụ thể trong luồng." }
      ],
      logicOptions: [
        { value: "AND", label: "Thoả mãn tất cả điều kiện dưới đây" },
        { value: "OR", label: "Thoả mãn ít nhất 1 trong các điều kiện" }
      ],
      ruleOperatorOptions: [
        { value: "==", label: "Bằng (==)" },
        { value: "!=", label: "Khác (!=)" },
        { value: ">", label: "Lớn hơn (>)" },
        { value: "<", label: "Nhỏ hơn (<)" },
        { value: ">=", label: "Lớn hơn hoặc bằng (>=)" },
        { value: "<=", label: "Nhỏ hơn hoặc bằng (<=)" },
        { value: "contains", label: "Chứa (contains)" }
      ]
    }
  },
  computed: {
    localAssigneeOptions: function () {
      const options = JSON.parse(JSON.stringify(this.assigneeOptions || []));
      (this.searchedUsers || []).forEach(function (u) {
        const val = u.EmployeeCode || u.Email || u.UserID;
        if (val && !options.find(function (o) { return o.value === val; })) {
          options.push({
            title: (u.FullName || u.UserName || val) + " (" + val + ")",
            value: val
          });
        }
      });
      return options;
    }
  },
  created: function () {
    this.loadUsers();
  },
  methods: {
    onUserSearch: _.debounce(async function (val) {
      const $this = this
      if (!val || val.length < 2) return
      $this.isSearchingUsers = true
      try {
        const rows = await apiCallAsync("WF_User_GetList", { Keyword: val })
        $this.searchedUsers = rows || []
      } catch (err) {
        console.error("Search user profile error:", err)
      } finally {
        $this.isSearchingUsers = false
      }
    }, 500),
    loadUsers: async function () {
      try {
        const data = await apiCallAsync("WF_User_GetList", {});
        const userRows = Array.isArray(data) ? (Array.isArray(data[0]) ? data[0] : data) : [];
        this.userOptions = userRows.map(function (u) {
          return { label: u.FullName + ' (' + u.UserID + ')', value: u.UserID };
        });
      } catch (err) {
        console.error("Load users error:", err);
        this.userOptions = [];
      }
    },
    saveAutomationRule: function () {
      if (this.editingRuleIdx === null) return;
      const rule = this.activeStep.AutomationRules[this.editingRuleIdx];
      if (!rule) return;
      this.editingRuleIdx = null;
      // Force trigger Vue reactivity
      if (this.activeStep && this.activeStep.AutomationRules) {
        this.activeStep.AutomationRules = JSON.parse(JSON.stringify(this.activeStep.AutomationRules));
      }
    },
    addAutomationRule: function () {
      if (!this.activeStep.AutomationRules) this.activeStep.AutomationRules = [];
      const newRule = {
        RuleName: "Quy tắc mới " + (this.activeStep.AutomationRules.length + 1),
        Event: "STAGE_CHANGED",
        Action: { Type: "AUTO_COMPLETE", Params: {} },
        ConditionGroup: { Logic: "AND", Items: [] }
      };
      this.activeStep.AutomationRules.push(newRule);
      this.editingRuleIdx = this.activeStep.AutomationRules.length - 1;
      // Force trigger Vue reactivity
      this.activeStep.AutomationRules = [...this.activeStep.AutomationRules];
    },
    removeAutomationRule: function (idx) {
      if (this.editingRuleIdx === idx) this.editingRuleIdx = null;
      this.activeStep.AutomationRules.splice(idx, 1);
      // Force trigger Vue reactivity
      this.activeStep.AutomationRules = [...this.activeStep.AutomationRules];
    },
    getRuleEventLabel: function (val) {
      const opt = this.ruleEventOptions.find(o => o.value === val);
      return opt ? opt.label : val;
    },
    getRuleActionLabel: function (val) {
      const opt = this.ruleActionOptions.find(o => o.value === val);
      return opt ? opt.label : val;
    },
    getRuleDetailSummary: function (rule) {
      if (!rule || !rule.Action) return "";
      const params = rule.Action.Params || {};
      switch (rule.Action.Type) {
        case 'CROSS_WF_CREATE':
          const wf = this.allDefinitions.find(d => d.DefinitionID === params.TargetWF);
          return wf ? "Luồng: " + wf.Name : "";
        case 'JUMP_TO':
          return "Nhảy bước";
        case 'UPDATE_FIELD':
          return params.FieldName ? "Trường: " + params.FieldName + " → " + (params.FieldValue || "") : "";
        case 'ASSIGN_PIC':
          return params.AssignTo ? "Gán: " + params.AssignTo : "";
        default:
          return "";
      }
    },
    onTargetWFChange: function (val) {
      if (this.editingRuleIdx !== null) {
        this.activeStep.AutomationRules[this.editingRuleIdx].Action.Params.TargetStep = null;
      }
      this.loadTargetSteps(val);
    },
    loadTargetSteps: async function (definitionId) {
      if (!definitionId) {
        this.targetSteps = [];
        return;
      }
      try {
        const data = await apiCallAsync("WF_StepDefinition_GetList", { DefinitionID: definitionId });
        const stepRows = Array.isArray(data) ? (Array.isArray(data[0]) ? data[0] : data) : [];
        this.targetSteps = stepRows.map(function (s) {
          return { label: s.StepName, value: s.StepDefID };
        });
      } catch (err) {
        console.error("Load target steps error:", err);
        this.targetSteps = [];
      }
    }
  },
  watch: {
    activeStep: {
      handler: function () {
        this.editingRuleIdx = null;
      },
      deep: false
    },
    editingRuleIdx: function (newVal) {
      this.$emit('editing-rule-changed', newVal);
      if (newVal !== null && this.activeStep && this.activeStep.AutomationRules[newVal]) {
        const rule = this.activeStep.AutomationRules[newVal];
        
        // Ensure Action and Params are initialized to avoid undefined errors
        rule.Action = rule.Action || { Type: "AUTO_COMPLETE", Params: {} };
        rule.Action.Params = rule.Action.Params || {};

        if (rule.Action.Type === 'CROSS_WF_CREATE' && rule.Action.Params.TargetWF) {
          this.loadTargetSteps(rule.Action.Params.TargetWF);
        } else {
          this.targetSteps = [];
        }
      } else {
        this.targetSteps = [];
      }
    }
  }
	}
</script>