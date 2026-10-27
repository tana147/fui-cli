<template>
	<div class="kanban-card border position-relative cursor-pointer pa-2" :style="{
      borderRadius: '0px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.03)',
      backgroundColor: card.StepExecutionStatus === 'DONE' ? '#f1fbe9' : (checkQuaHan(card.StepDueDate, card) ? '#fff5f5' : (checkSapHetHan(card.StepDueDate, card) ? '#fffaf0' : '#ffffff')),
      borderColor: card.StepExecutionStatus === 'DONE' ? '#c5e1a5' : (checkQuaHan(card.StepDueDate, card) ? '#ffcdd2' : (checkSapHetHan(card.StepDueDate, card) ? '#ffe082' : '#e2e8f0')),
      transition: 'all 0.2s',
      display: 'flex',
      flexDirection: 'column',
      gap: '2px',
      overflow: 'hidden',
    }" draggable="true" @dragstart="$emit('dragstart', $event, card)" @dragend="$emit('dragend', $event)"
    @click="$emit('open-card', card)">

    <!-- Row 1: stepType dưới dạng chip, Tag (Trái) & toolbar (Phải) -->
    <div class="d-flex align-center justify-space-between" style="min-height: 22px;" @click.stop>
      <div class="d-flex align-center ga-1 flex-grow-1" style="min-width: 0; overflow: hidden;">
        <v-chip size="x-small" color="primary" variant="flat" class="flex-shrink-0"
          style="font-size: 9px; height: 16px; border-radius: 4px; font-weight: 500; text-transform: uppercase;">
          {{ getFieldCountText(column) }}
        </v-chip>
        <!-- Tags list (left) moved to Row 1 -->
        <div v-if="card.Tag" class="d-flex flex-wrap ga-1 align-center"
          style="max-height: 18px; overflow: hidden; min-width: 0;">
          <v-chip v-for="tag in tagStringToList(card.Tag).slice(0, 1)" :key="tag" size="x-small" :style="{
              backgroundColor: getTagColorLight(tag),
              color: getTagTextColorDark(tag),
              border: '1px dashed ' + getTagBorderColor(tag),
              fontSize: '9px',
              height: '16px',
              fontWeight: '500',
              borderRadius: '4px',
            }" class="px-1.5 flex-shrink-0">
            {{ getTagDisplayName(tag) }}
          </v-chip>
          <span v-if="tagStringToList(card.Tag).length > 1" class="text-caption text-grey flex-shrink-0"
            style="font-size: 9px; line-height: 16px; margin-left: 2px;">+{{ tagStringToList(card.Tag).length - 1
            }}</span>
        </div>
      </div>

      <!-- Right Toolbar -->
      <div class="d-flex align-center ga-1 flex-shrink-0">
        <v-menu transition="slide-y-transition" location="bottom start" attach="body">
          <template v-slot:activator="{ props: menuProps }">
            <v-btn icon variant="text" size="x-small" density="compact" v-bind="menuProps" class="text-grey-darken-1"
              style="width: 20px; height: 20px; min-width: 20px; opacity: 0.6;">
              <v-icon size="16">mdi-dots-vertical</v-icon>
            </v-btn>
          </template>
          <v-list class="py-0.5 px-1 custom-card-menu"
            style="min-width: 180px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important; background-color: #fff;">
            <v-menu open-on-hover location="end top" offset="12" transition="slide-x-transition" attach="body">
              <template v-slot:activator="{ props: subMenuProps }">
                <v-list-item v-bind="subMenuProps" class="py-1 px-2.5 cursor-pointer">
                  <template v-slot:prepend>
                    <v-icon size="14" class="mr-2 text-grey-darken-3">mdi-file-swap-outline</v-icon>
                  </template>
                  <v-list-item-title class="text-caption" style="color: rgba(0, 0, 0, 0.87);">Chuyển giai đoạn
                  </v-list-item-title>
                  <template v-slot:append>
                    <v-icon size="12" class="ml-auto text-grey">mdi-chevron-right</v-icon>
                  </template>
                </v-list-item>
              </template>
              <v-list class="py-0.5 px-1 custom-card-submenu"
                style="min-width: 200px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important; background-color: #fff;">
                <v-list-item v-for="(cotItem, index) in dsCot" :key="cotItem.id || index"
                  :disabled="isCurrentStep(card, cotItem)" @click="$emit('move-step', { card, column: cotItem, index })"
                  class="py-1 px-2.5 cursor-pointer">
                  <v-list-item-title class="text-caption"
                    :style="{ color: getStepColor(cotItem, isCurrentStep(card, cotItem)) }">
                    {{ cotItem.tenCot }}
                  </v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
            <v-list-item class="py-1 px-2.5 cursor-pointer" @click="$emit('edit-pic', card)">
              <template v-slot:prepend>
                <v-icon size="14" class="mr-2 text-grey-darken-3">mdi-account-plus-outline</v-icon>
              </template>
              <v-list-item-title class="text-caption" style="color: rgba(0, 0, 0, 0.87);">Giao việc
              </v-list-item-title>
            </v-list-item>
            <v-list-item class="py-1 px-2.5 cursor-pointer" @click="$emit('edit-tags', card)">
              <template v-slot:prepend>
                <v-icon size="14" class="mr-2 text-grey-darken-3">mdi-playlist-plus</v-icon>
              </template>
              <v-list-item-title class="text-caption" style="color: rgba(0, 0, 0, 0.87);">Thêm nhãn
              </v-list-item-title>
            </v-list-item>
            <v-list-item class="py-1 px-2.5 cursor-pointer" @click="$emit('edit-sla', card)">
              <template v-slot:prepend>
                <v-icon size="14" class="mr-2 text-grey-darken-3">mdi-clock-outline</v-icon>
              </template>
              <v-list-item-title class="text-caption" style="color: rgba(0, 0, 0, 0.87);">Cập nhật SLA
              </v-list-item-title>
            </v-list-item>
          </v-list>
        </v-menu>
      </div>
    </div>

    <!-- Row 2: Tên instance -->
    <div class="text-left font-weight-medium line-clamp-1"
      style="font-size: 14px;  color: #1a1d20; word-break: break-word; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; margin-top: 1px;">
      <v-icon v-if="checkQuaHan(card.StepDueDate, card)" color="error" size="14" class="mr-1"
        style="vertical-align: -2px;">mdi-alert-circle</v-icon>
      <v-icon v-else-if="checkSapHetHan(card.StepDueDate, card)" color="warning" size="14" class="mr-1"
        style="vertical-align: -2px;">mdi-alert</v-icon>
      {{ card.tieuDe }}
    </div>

    <!-- Row 3: Process bar công việc -->
    <div class="d-flex align-center ga-1.5 w-100 mt-1" style="font-size: 10px; min-height: 14px;">
      <span class="text-grey-darken-2 mr-1" style="white-space: nowrap;">Công việc:</span>
      <div
        style="flex-grow: 1; height: 5px; background-color: #e2e8f0; border-radius: 10px; overflow: hidden; position: relative;">
        <div :style="{
          width: getTasksList().length > 0 ? ((getTasksCompletedCount() / getTasksList().length) * 100) + '%' : '0%',
          backgroundColor: (getTasksList().length > 0 && getTasksCompletedCount() === getTasksList().length) ? '#2e7d32' : '#2196F3'
        }" style="height: 100%; transition: width 0.3s ease; border-radius: 10px;"></div>
      </div>
      <span class="font-weight-bold" style="color: #1e293b; min-width: 24px; text-align: right;">
        {{ getTasksCompletedCount() }}/{{ getTasksList().length }}
      </span>
    </div>

    <!-- Row 4: Duedate (Phải), bên trái là hồ sơ: 0/3 và ko dùng icon -->
    <div class="d-flex align-center justify-space-between mt-1" style="font-size: 10.5px; min-height: 18px;">
      <!-- Trái: Hồ sơ: 0/3 (Không dùng icon) -->
      <div class="text-grey-darken-2" style="font-size: 10.5px;">
        <span v-if="getChecklistItems().length > 0">
          Hồ sơ: <span class="font-weight-bold" style="color: #1e293b;">{{ getChecklistCompletedCount() }}/{{
            getChecklistItems().length }}</span>
        </span>
      </div>

      <!-- Phải: Duedate SLA -->
      <div>
        <span v-if="card.StepDueDate" class="d-inline-flex align-center ga-1 text-grey-darken-1 flex-shrink-0"
          style="font-size: 10.5px;">
          <v-icon size="12"
            :color="checkQuaHan(card.StepDueDate, card) ? 'error' : (checkSapHetHan(card.StepDueDate, card) ? 'warning' : 'grey-darken-1')">
            mdi-clock-outline</v-icon>
          <span
            :class="{ 'text-error font-weight-bold': checkQuaHan(card.StepDueDate, card), 'text-warning font-weight-bold': checkSapHetHan(card.StepDueDate, card) }">
            {{ formatSLA(card.StepStartDate, card.StepDueDate) }}
          </span>
        </span>
        <span v-if="card.StepExecutionStatus === 'DONE' && !card.StepDueDate"
          class="text-success text-truncate font-weight-semibold" style="font-size: 10.5px;"
          :title="'Done bởi ' + (card.AssigneeName || card.AssignToName || 'Admin')">
          Done bởi {{ card.AssigneeName || card.AssignToName || 'Admin' }}
        </span>
      </div>
    </div>

    <!-- Row 5 (Dòng cuối): Tên người phụ trách hiển thị full + avatar (Phải) -->
    <div class="d-flex align-center justify-end border-top pt-2"
      style="border-top: 1px solid #f1f5f9 !important; min-height: 28px; margin-top: 2px;" @click.stop>
      <!-- PIC Avatar & FullName hiển thị full (right) -->
      <div class="d-flex align-center ga-1 flex-shrink-0">
        <template v-if="(card.AssigneeName || card.AssigneeCode || card.AssignTo) != '-' && card.AssigneeCode">
          <uc-avatar :name="card.AssigneeName" :image="card.AssigneeAvatar" :size="20" font-size="8px"
            class="flex-shrink-0 mr-1" />
          <span class="text-caption text-grey-darken-2 font-weight-medium"
            style="font-size: 11px !important; line-height: 20px; white-space: nowrap;" :title="card.AssigneeName">
            {{ card.AssigneeName }}
          </span>
        </template>
      </div>
    </div>

    <!-- Watermark behind card -->
    <div v-if="checkQuaHan(card.StepDueDate, card)"
      style="position: absolute; top: 55%; left: 50%; transform: translate(-50%, -50%) rotate(-15deg); font-size: 26px; font-weight: 900; color: rgba(239, 83, 80, 0.05); pointer-events: none; z-index: 0; text-transform: uppercase; user-select: none; letter-spacing: 1.5px; white-space: nowrap;">
      QUÁ HẠN</div>
    <div v-else-if="checkSapHetHan(card.StepDueDate, card)"
      style="position: absolute; top: 55%; left: 50%; transform: translate(-50%, -50%) rotate(-15deg); font-size: 22px; font-weight: 900; color: rgba(245, 124, 0, 0.05); pointer-events: none; z-index: 0; text-transform: uppercase; user-select: none; letter-spacing: 1.5px; white-space: nowrap;">
      SẮP HẾT HẠN</div>
  </div>
</template>

<script>
	export default {
		name: 'uc-kanban-card',
  props: {
    card: { type: Object, required: true },
    column: { type: Object, required: true },
    dsCot: { type: Array, default: () => [] },
    danhSachNhan: { type: Array, default: () => [] },
    signerProfiles: { type: Array, default: () => [] },
    isCompletedCard: { type: Boolean, default: false }
  },
  data() {
    return {
      sys_EmployeeCode: ''
    }
  },
  mounted() {
    this.sys_EmployeeCode = this.getCurrentEmployeeCode()
  },
  methods: {
    getCurrentEmployeeCode() {
      let code = '';
      try {
        if (typeof vueData !== 'undefined' && vueData.user) {
          code = vueData.user.UserID || vueData.user.EmployeeCode || '';
        }
      } catch (e) {}
      if (!code && typeof window !== 'undefined') {
        code = (window.sys_user && window.sys_user.EmployeeCode)
          || localStorage.getItem('EmployeeCode')
          || '';
      }
      return String(code).trim();
    },
    checkQuaHan(ngay, the) {
      if (!ngay) return false
      if (the && (the.StepExecutionStatus === 'DONE' || the.Status === 'COMPLETED' || the.Status === 'SUCCESS')) return false
      const d = new Date(ngay)
      if (isNaN(d)) return false
      return d < new Date()
    },
    checkSapHetHan(ngay, the) {
      if (!ngay) return false
      if (the && (the.StepExecutionStatus === 'DONE' || the.Status === 'COMPLETED' || the.Status === 'SUCCESS')) return false
      const d = new Date(ngay)
      if (isNaN(d)) return false
      const now = new Date()
      const diffMs = d - now
      return diffMs > 0 && diffMs <= 24 * 60 * 60 * 1000
    },
    formatNgay(ngay) {
      if (!ngay) return ''
      const d = new Date(ngay)
      if (isNaN(d)) return ngay
      const pad = (n) => String(n).padStart(2, '0')
      return pad(d.getDate()) + '/' + pad(d.getMonth() + 1) + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes())
    },
    formatSLA(startDate, endDate) {
      if (!endDate) return ''
      const startText = startDate ? this.formatNgay(startDate) : ''
      const endText = this.formatNgay(endDate)
      if (startText) {
        return startText + ' - ' + endText
      }
      return endText
    },
    isCurrentStep(the, cot) {
      if (the.CurrentStepDefID && typeof the.CurrentStepDefID === 'number') {
        return Number(cot.id) === Number(the.CurrentStepDefID)
      }
      if (the.CurrentStepOrder !== undefined && cot.order !== undefined) {
        return Number(cot.order) === Number(the.CurrentStepOrder)
      }
      return false
    },
    getStepColor(cot, isDisabled) {
      if (isDisabled) return 'rgba(0, 0, 0, 0.38)'
      if (cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS') {
        return '#2a9d5b'
      }
      if (cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE') {
        return '#b91c1c'
      }
      return 'rgba(0, 0, 0, 0.87)'
    },
    tagStringToList(tagString) {
      if (!tagString) return []
      return tagString.split(',').map(t => t.trim()).filter(Boolean)
    },
    getTagDisplayName(tagKey) {
      if (!tagKey) return ''
      const tag = this.danhSachNhan.find(t => t.Tag === tagKey || t.TagName === tagKey)
      return tag ? tag.TagName : tagKey
    },
    getTagColorLight(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      if (!tag || !tag.Color) return '#f1f5f9'
      const hex = tag.Color
      const map = {
        '#2196F3': '#e3f2fd', '#9c27b0': '#f3e5f5', '#4caf50': '#e8f5e9',
        '#8bc34a': '#f1f8e9', '#3f51b5': '#e8eaf6', '#d9a441': '#fdf6e2',
        '#ff9800': '#fff3e0', '#f44336': '#ffebee', '#e91e63': '#fce4ec',
        '#cbd5e1': '#f1f5f9', '#009688': '#e0f2f1', '#00bcd4': '#e0f7fa',
        '#ffc107': '#fff8e1', '#795548': '#efebe9', '#607d8b': '#eceff1'
      }
      return map[hex] || hex
    },
    getTagBorderColor(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      return tag ? (tag.Color || '#cbd5e1') : '#cbd5e1'
    },
    getTagTextColorDark(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      if (!tag || !tag.Color) return '#475569'
      const hex = tag.Color
      const map = {
        '#2196F3': '#1e88e5', '#9c27b0': '#8e24aa', '#4caf50': '#2e7d32',
        '#8bc34a': '#558b2f', '#3f51b5': '#3f51b5', '#d9a441': '#b58010',
        '#ff9800': '#e65100', '#f44336': '#c62828', '#e91e63': '#c2185b',
        '#cbd5e1': '#475569', '#009688': '#00796b', '#00bcd4': '#0097a7',
        '#ffc107': '#f57f17', '#795548': '#5d4037', '#607d8b': '#37474f'
      }
      return map[hex] || hex
    },
    customTagFilter(value, query, item) {
      if (!query) return true
      const q = String(query).toLowerCase().trim()
      const val = String(value).toLowerCase().trim()
      return val.indexOf(q) !== -1
    },
    getTasksList() {
      if (!this.card.TasksJSON) return []
      try {
        if (typeof this.card.TasksJSON === 'string') {
          return JSON.parse(this.card.TasksJSON) || []
        }
        return this.card.TasksJSON || []
      } catch (e) {
        return []
      }
    },
    getChecklistItems() {
      if (!this.card.ChecklistJSON) return []
      try {
        if (typeof this.card.ChecklistJSON === 'string') {
          return JSON.parse(this.card.ChecklistJSON) || []
        }
        return this.card.ChecklistJSON || []
      } catch (e) {
        return []
      }
    },
    getChecklistCompletedCount() {
      const list = this.getChecklistItems()
      return list.filter(c => c.IsCompleted || c.Status === 'DONE' || c.Status === 1 || c.IsCompleted === 1).length
    },
    getTasksCompletedCount() {
      const list = this.getTasksList()
      return list.filter(t => t.Status === 'DONE').length
    },
    getSignersList() {
      if (!this.card.SignersJSON) return []
      try {
        if (typeof this.card.SignersJSON === 'string') {
          return JSON.parse(this.card.SignersJSON) || []
        }
        return this.card.SignersJSON || []
      } catch (e) {
        return []
      }
    },
    getSignersCompletedCount() {
      const list = this.getSignersList()
      return list.filter(s => s.Status === 'SIGNED').length
    },
    getFieldCountText(cot) {
      if (!cot) return 'Nhập liệu'
      const type = String(cot.stepType || cot.stepCode || '').toUpperCase()
      if (type === 'REVIEW') return 'Xem duyệt'
      if (type === 'SIGN') return 'Ký số'
      if (type === 'ECONTRACT') return 'Ký HĐ'
      return 'Nhập liệu'
    },
    async toggleSubTaskStatus(task) {
      if (!task || !task.TaskID) return
      var newStatus = task.Status === 'DONE' ? 'TODO' : 'DONE'
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_InstanceTask_UpdateStatus', {
            TaskID: task.TaskID,
            Status: newStatus
          })
          if (res && res.Success !== false) {
            task.Status = newStatus
            let tasks = this.getTasksList()
            const found = tasks.find(t => t.TaskID === task.TaskID)
            if (found) found.Status = newStatus
            this.card.TasksJSON = typeof this.card.TasksJSON === 'string' ? JSON.stringify(tasks) : tasks
            if (typeof showToast !== 'undefined' && showToast.success) showToast.success('Cập nhật trạng thái nhiệm vụ thành công')
            this.$emit('refresh-board')
          } else {
            if (typeof showToast !== 'undefined' && showToast.error) showToast.error(res.Message || 'Lỗi cập nhật trạng thái nhiệm vụ')
          }
        }
      } catch (e) {
        console.error('Lỗi toggle subtask:', e)
      }
    },
    kiemTraQuyenBaoHoanThanh(the, cot) {
      return true; // Cho phép bất cứ ai cũng có thể check hoàn thành
    },
    async baoHoanThanh() {
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_StepExecution_UpdateStatus', {
            InstanceID: this.card.InstanceID,
            Status: 'DONE'
          })
          if (res && res.Success !== false) {
            this.card.StepExecutionStatus = 'DONE'
            if (typeof showToast !== 'undefined' && showToast.success) showToast.success('Đã báo hoàn thành bước thành công!')
            this.$emit('refresh-board')
          } else {
            if (typeof showToast !== 'undefined' && showToast.error) showToast.error(res.Message || 'Lỗi cập nhật trạng thái.')
          }
        }
      } catch (err) {
        console.error('Lỗi báo hoàn thành:', err)
      }
    },
    async thuHoiHoanThanh() {
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_StepExecution_UpdateStatus', {
            InstanceID: this.card.InstanceID,
            Status: 'ACTIVE'
          })
          if (res && res.Success !== false) {
            this.card.StepExecutionStatus = 'ACTIVE'
            if (typeof showToast !== 'undefined' && showToast.success) showToast.success('Đã thu hồi trạng thái hoàn thành!')
            this.$emit('refresh-board')
          } else {
            if (typeof showToast !== 'undefined' && showToast.error) showToast.error(res.Message || 'Lỗi cập nhật trạng thái.')
          }
        }
      } catch (err) {
        console.error('Lỗi thu hồi hoàn thành:', err)
      }
    },
    toggleCardCompleted() {
      this.$emit('toggle-card-completed', this.card)
    }
  }
	}
</script>