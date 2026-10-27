<template>
	<div class="kanban-board d-flex" ref="kanbanBoard" @dragover="onBoardDragOver"
    :class="{ 'kanban-board--dragging': dragCardId !== null }"
    style="height: calc(100vh - 56px); overflow-x: auto; overflow-y: hidden; gap: 8px; padding: 8px; background-color: #f4f6f8; align-items: stretch; box-sizing: border-box;">
    <div v-for="(cot, iCot) in dsCot" :key="cot.id" @dragover.prevent="onDragOver($event, iCot)"
      @drop="onDrop($event, iCot)" :class="{ 'kanban-col--over': dragOverCol === iCot }" :style="{
        minWidth: '300px',
        maxWidth: '300px',
        flexShrink: 0,
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: getColBgColor(cot),
        borderRadius: '0px',
        border: '1px solid ' + getColBorderColor(cot),
        overflow: 'hidden',
        boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
      }">

      <!-- padding: 12px 12px 6px;  -->
      <!-- Column Header -->
      <div class="kanban-col-header d-flex flex-column pa-2" :style="{
          userSelect: 'none',
          flexShrink: 0,
          background: 'white',
          borderBottom: '1px solid #f1f5f9',
          borderTop: '2px solid ' + (cot.mau || getColBorderColor(cot))
        }">
        <!-- Row 1: Title & Assignees (On the same row) -->
        <div class="d-flex align-center justify-space-between ga-2" style="width: 100%; min-height: 24px;">
          <div class="d-flex align-center justify-space-between ga-1.5" style="min-width: 0; flex: 1;">
            <v-tooltip location="bottom" :text="cot.tenCot">
              <template v-slot:activator="{ props }">
                <span v-bind="props" class="font-weight-bold"
                  style="font-size: 13.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: #1a1d21;">
                  {{ cot.tenCot }}
                </span>
              </template>
            </v-tooltip>

            <!-- Assignees Avatars / Menu (Right of Title) -->
            <v-menu v-if="cot.assignees && cot.assignees.length > 0" transition="slide-y-transition" offset="4"
              close-on-content-click>
              <template v-slot:activator="{ props }">
                <div class="d-flex align-center cursor-pointer" v-bind="props" style="user-select: none;">
                  <div class="d-flex align-center" style="margin-right: 2px;">
                    <uc-avatar v-for="(user, uIdx) in cot.assignees.slice(0, 3)" :key="user.StepAssigneeID || uIdx"
                      :name="user.FullName" :image="user?.Avatar || user.Photo || user.Image" :size="18" font-size="8px"
                      :style="{
                        border: '1.2px solid rgba(255, 255, 255, 0.9)',
                        marginLeft: uIdx > 0 ? '-6px' : '0px',
                        zIndex: 10 - uIdx,
                        boxShadow: '0 1px 2px rgba(0,0,0,0.1)'
                      }" />
                    <div v-if="cot.assignees.length > 3"
                      class="d-flex align-center justify-center font-weight-bold text-white text-center rounded-circle"
                      :style="{
                        width: '18px',
                        height: '18px',
                        fontSize: '8px',
                        backgroundColor: '#1b5e20',
                        border: '1.2px solid rgba(255, 255, 255, 0.9)',
                        marginLeft: '-6px',
                        zIndex: 5,
                        boxShadow: '0 1px 2px rgba(0,0,0,0.1)'
                      }">
                      +{{ cot.assignees.length - 3 }}
                    </div>
                  </div>
                  <v-icon size="11"
                    :color="cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS' ? 'success' : cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE' ? 'error' : 'grey-darken-1'"
                    class="opacity-80">mdi-chevron-down</v-icon>
                </div>
              </template>
              <v-list class="py-1 px-1 bg-white"
                style="min-width: 180px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important; border: 1px solid #e2e8f0;">
                <div class="text-grey-darken-1 px-3 py-1.5 text-left"
                  style="font-size: 9px !important; letter-spacing: 0.5px; color: #64748b !important;">
                  Người quản lý bước
                </div>
                <v-divider class="mx-2 my-1" style="border-color: #cbd5e1;"></v-divider>
                <v-list-item v-for="(user, uIdx) in cot.assignees" :key="user.StepAssigneeID || uIdx"
                  class="py-1 px-2.5 cursor-default rounded-md" style="min-height: 32px !important; text-align: left;">
                  <div class="d-flex align-center w-100" style="gap: 8px;">
                    <uc-avatar :name="user.FullName" :image="user.Avatar || user.Photo || user.Image " :size="20"
                      font-size="8px" :style="{
                        boxShadow: '0 1px 2px rgba(0,0,0,0.1)'
                      }" />
                    <span class="font-weight-medium text-left"
                      style="font-size: 12px !important; color: #334155; line-height: 1.4;">
                      {{ user.FullName }}
                    </span>
                  </div>
                </v-list-item>
              </v-list>
            </v-menu>
          </div>
        </div>

        <!-- Row 2: Done Count (Left) & Add Button (Right) -->
        <div class="d-flex align-center justify-space-between mt-1" style="width: 100%; min-height: 20px;">
          <!-- Done Count Text (màu nhạt, dùng tabular-nums để số 0 và 1 đồng bộ) -->
          <div style="font-size: 11.5px; color: #8c8c8c; font-weight: 500; font-variant-numeric: tabular-nums;">
            Đã xong: <span style="font-weight: 700; color: #2e7d32;">{{ getStepDoneDs(iCot).length }}</span>
          </div>

          <!-- Add Button (Right) -->
          <v-btn icon size="x-small" variant="text" color="grey" title="Thêm nhiệm vụ" @click="$emit('add-card', cot)"
            style="opacity: 0.6; width: 20px; height: 20px; margin-right: -4px;">
            <v-icon size="15">mdi-plus</v-icon>
          </v-btn>
        </div>
      </div>

      <!-- Cards Area -->
      <div class="kanban-col-body flex-grow-1"
        style="overflow-y: auto; display: flex; flex-direction: column; padding: 8px; gap: 8px;">
        <!-- ACTIVE/TODO CARDS -->
        <template v-for="(the, index) in getChuaHoanThanhDs(iCot)" :key="'todo-' + (the.id || index)">
          <uc-kanban-card :card="the" :column="cot" :ds-cot="dsCot" :danh-sach-nhan="danhSachNhan"
            :signer-profiles="signerProfiles" :is-completed-card="false" @open-card="$emit('open-card', $event)"
            @refresh-board="$emit('refresh-board')" @move-step="moveStep($event.card, $event.column, $event.index)"
            @edit-sla="moSuaHanChotInline" @manage-tags="moQuanLyNhan" @dragstart="onDragStart($event, the)"
            @dragend="onDragEnd" @edit-pic="moSuaNguoiPhuTrachInline" @edit-tags="moSuaNhanInline"
            @bao-hoan-thanh="baoHoanThanh($event)" @thu-hoi-hoan-thanh="thuHoiHoanThanh($event)" />
        </template>

        <!-- COMPLETED SECTION SEPARATOR -->
        <div v-if="getDaHoanThanhDs(iCot).length > 0" class="d-flex align-center justify-center my-1.5"
          style="position: relative; flex-shrink: 0; user-select: none;">
          <div
            style="height: 1px; background-color: #8bc34a; width: 100%; position: absolute; top: 50%; left: 0; z-index: 1; opacity: 0.5;">
          </div>
          <span class="px-2"
            style="position: relative; z-index: 2; font-size: 9px; font-weight: 500; background-color: #f1f3f5 !important; color: #558b2f !important; letter-spacing: 0.5px; border-radius: 4px;">CÔNG
            VIỆC ĐÃ HOÀN THÀNH</span>
        </div>

        <!-- COMPLETED/DONE CARDS -->
        <template v-for="(the, index) in getDaHoanThanhDs(iCot)" :key="'done-' + (the.id || index)">
          <uc-kanban-card :card="the" :column="cot" :ds-cot="dsCot" :danh-sach-nhan="danhSachNhan"
            :signer-profiles="signerProfiles" :is-completed-card="true" @open-card="$emit('open-card', $event)"
            @refresh-board="$emit('refresh-board')" @move-step="moveStep($event.card, $event.column, $event.index)"
            @edit-sla="moSuaHanChotInline" @manage-tags="moQuanLyNhan" @toggle-card-completed="toggleCardCompleted"
            @dragstart="onDragStart($event, the)" @dragend="onDragEnd" @edit-pic="moSuaNguoiPhuTrachInline"
            @edit-tags="moSuaNhanInline" @bao-hoan-thanh="baoHoanThanh($event)"
            @thu-hoi-hoan-thanh="thuHoiHoanThanh($event)" />
        </template>

        <!-- Empty State -->
        <div v-if="getDsTheoCot(iCot).length === 0"
          class="kanban-empty d-flex flex-column align-center justify-center py-10 opacity-50 bg-white rounded-lg border-dashed"
          style="border: 1px dashed #cbd5e1; user-select: none;">
          <v-icon color="grey" size="24" class="mb-1">mdi-tray-blank</v-icon>
          <div class="text-caption text-grey-darken-1" style="font-size: 11px !important;">Chưa có nhiệm vụ nào</div>
        </div>
      </div>
    </div>

    <!-- DIALOG QUẢN LÝ DANH MỤC NHÃN (Tag Manager) -->
    <uc-modal :model-value="dialogQuanLyNhan" @update:model-value="dialogQuanLyNhan = $event" max-width="520px"
      title="Quản lý danh mục nhãn" confirm-text="Thêm nhãn mới" confirm-icon="mdi-plus" cancel-text="Đóng"
      @confirm="themNhanMoi">

      <!-- Hiển thị các nhãn hiện tại dạng chip nhỏ gọn có nút xóa nét đứt -->
      <div class="text-grey-darken-3 mb-2 text-left" style="font-size: 13px;">Danh sách nhãn hiện tại:
      </div>
      <div class="d-flex flex-wrap ga-2 mb-5 pa-3 border rounded-lg bg-grey-lighten-5"
        style="max-height: 150px; overflow-y: auto; text-align: left; border-color: #cbd5e1 !important;">
        <v-chip v-for="tag in danhSachNhan" :key="tag.Tag" :style="{
            backgroundColor: getTagColorLight(tag.Tag),
            color: getTagTextColorDark(tag.Tag),
            border: '1px dashed ' + getTagBorderColor(tag.Tag),
            fontWeight: '500',
            fontSize: '11px',
            height: '24px'
          }" class="px-2.5">
          {{ tag.TagName }}
          <v-icon size="12" class="ml-1.5" style="cursor: pointer; opacity: 0.6;" @click.stop="xoaNhan(tag.Tag)">
            mdi-close</v-icon>
        </v-chip>
        <div v-if="danhSachNhan.length === 0" class="w-100 text-center text-caption text-grey py-4"
          style="font-size: 12px;">Chưa có nhãn dán nào trong hệ thống</div>
      </div>

      <v-divider class="mb-4"></v-divider>

      <!-- Trình thêm nhãn dán mới giống với Tạo nhiệm vụ -->
      <v-text-field v-model="nhanMoiName" label="Tên nhãn mới *" variant="outlined" density="compact"
        class="wf-ant-input mb-4 text-left" placeholder="Nhập tên nhãn mới..." hide-details="auto"
        @keyup.enter="themNhanMoi"></v-text-field>

      <!-- Bảng màu lựa chọn (10 màu) -->
      <div class="text-left mb-4">
        <div class="text-grey-darken-3 mb-2"
          style="font-size: 13px; display: flex; align-items: center; gap: 8px;">
          <span>Chọn màu sắc đại diện nhãn:</span>
          <div :style="{
              backgroundColor: nhanMoiColor,
              width: '16px',
              height: '16px',
              borderRadius: '50%',
              border: '1px solid #cbd5e1',
              marginLeft: '8px'
            }"></div>
        </div>
        <div class="d-flex ga-2.5 flex-wrap">
          <div v-for="color in dsBangMau" :key="color" @click="nhanMoiColor = color" :style="{
              backgroundColor: color,
              width: '24px',
              height: '24px',
              borderRadius: '4px',
              cursor: 'pointer',
              border: nhanMoiColor === color ? '2px solid #000' : '1px solid #cbd5e1',
              boxShadow: nhanMoiColor === color ? '0 0 0 2px #fff' : 'none',
              transition: 'all 0.15s ease'
            }" class="color-selection-box"></div>
        </div>
      </div>
    </uc-modal>

    <!-- Dialog Cập nhật thời gian SLA -->
    <uc-modal :model-value="dialogSuaSLA" @update:model-value="dialogSuaSLA = $event" max-width="450px"
      title="Cập nhật thời hạn hết hạn (SLA)" confirm-text="Lưu" cancel-text="Hủy" @confirm="luuHanChot">

      <!-- Hiển thị tiêu đề hồ sơ -->
      <div v-if="editingCardTitle" class="mb-4 text-left">
        <span class="text-caption text-grey-darken-1">Hồ sơ:</span>
        <div class="text-body-2 font-weight-medium mt-0.5" style="color: #1e293b;">{{ editingCardTitle }}</div>
      </div>

      <div class="text-left mb-4">
        <div class="text-grey-darken-3 mb-1.5" style="font-size: 11.5px;">Thời gian bắt đầu (Không bắt buộc)</div>
        <div class="d-flex ga-2">
          <v-text-field v-model="slaStartDate" type="date" class="wf-ant-input bg-white flex-grow-1" variant="outlined"
            density="compact" hide-details></v-text-field>
          <v-select v-model="slaStartTime" :items="dsKhungGio" class="wf-ant-input bg-white" variant="outlined"
            density="compact" hide-details style="width: 110px; max-width: 110px;"></v-select>
        </div>
      </div>

      <div class="text-left mb-2">
        <div class="text-grey-darken-3 mb-1.5" style="font-size: 11.5px;">Thời hạn hết hạn (SLA) <span
            class="text-error">*</span></div>
        <div class="d-flex ga-2">
          <v-text-field v-model="slaEndDate" type="date" class="wf-ant-input bg-white flex-grow-1" variant="outlined"
            density="compact" hide-details></v-text-field>
          <v-select v-model="slaEndTime" :items="dsKhungGio" class="wf-ant-input bg-white" variant="outlined"
            density="compact" hide-details style="width: 110px; max-width: 110px;"></v-select>
        </div>
      </div>
    </uc-modal>

    <!-- Dialog Giao việc (PIC) -->
    <uc-modal :model-value="dialogGiaoViec" @update:model-value="dialogGiaoViec = $event" max-width="450px"
      title="Giao việc cho nhân sự" confirm-text="Lưu lại" cancel-text="Hủy" @confirm="luuNguoiPhuTrach">
      <div class="mb-2 color-dark text-left" style="font-size: 13px;">Chọn người phụ trách:</div>
      <uc-select-user v-model="nguoiPhuTrachMoi" placeholder="Chọn người phụ trách..."
        :init-data="{ EmployeeCode: '', FullName: '' }" />
    </uc-modal>

    <!-- Dialog Cấu hình nhãn cho hồ sơ/nhiệm vụ -->
    <uc-modal :model-value="dialogNhan" @update:model-value="dialogNhan = $event" max-width="450px"
      title="Cấu hình nhãn dán" confirm-text="Lưu lại" cancel-text="Hủy" @confirm="luuNhan">
      <div class="mb-2 color-dark text-left" style="font-size: 13px;">Chọn nhãn dán:</div>
      <v-autocomplete v-model="nhanDaChon" :items="danhSachNhan" item-title="TagName" item-value="Tag"
        placeholder="Chọn nhãn..." multiple chips closable-chips variant="outlined" density="compact"
        class="wf-ant-input mb-4 text-left" hide-details="auto" :custom-filter="customTagFilter">
        <!-- Custom chip template -->
        <template v-slot:chip="{ props, item }">
          <v-chip v-bind="props" size="x-small" :style="{
              backgroundColor: getTagColorLight(item.raw.Tag),
              color: getTagTextColorDark(item.raw.Tag),
              border: '1px dashed ' + getTagBorderColor(item.raw.Tag),
              fontSize: '9px',
              height: '18px',
              fontWeight: '500',
              borderRadius: '4px',
              margin: '1px'
            }" class="px-2">
            {{ item.raw.TagName }}
          </v-chip>
        </template>
        <!-- Custom item template -->
        <template v-slot:item="{ props, item }">
          <v-list-item v-bind="props" density="compact" class="py-0.5 min-height-24">
            <template v-slot:prepend="{ isSelected }">
              <v-checkbox-btn :model-value="isSelected" density="compact" color="primary" class="mr-1">
              </v-checkbox-btn>
              <div
                :style="{ backgroundColor: getTagBorderColor(item.raw.Tag), width: '8px', height: '8px', borderRadius: '50%', marginRight: '8px' }">
              </div>
            </template>
            <template v-slot:title>
              <span style="font-size: 10.5px !important; font-weight: 600; color: #374151;">{{ item.raw.TagName
                }}</span>
            </template>
          </v-list-item>
        </template>
      </v-autocomplete>
    </uc-modal>
  </div>
</template>

<script>
	export default {
		props: {
    dsCot: { type: Array, default: () => [] },
    dsThe: { type: Array, default: () => [] },
    signerProfiles: { type: Array, default: () => [] }
  },
  data() {
    return {
      dragCardId: null,
      dragOverCol: null,
      sys_UserName: '',
      sys_EmployeeCode: '',

      // Inline edit state
      editingCardId: null,
      editingType: null, // 'TAG', 'SLA', hoặc 'ASSIGNEE'

      dialogQuanLyNhan: false,
      dialogSuaSLA: false,
      dialogGiaoViec: false,
      dialogNhan: false,
      editingCardTitle: '',
      nhanDaChon: [],
      danhSachNhan: [],
      nhanMoiName: '',
      nhanMoiColor: '#cbd5e1', // Default xám
      slaStartDate: '',
      slaStartTime: '08:00',
      slaEndDate: '',
      slaEndTime: '17:30',
      dsKhungGio: (function() {
        var list = []
        for (var h = 0; h < 24; h++) {
          var hh = String(h).padStart(2, '0')
          list.push(hh + ':00')
          list.push(hh + ':30')
        }
        return list
      })(),
      nguoiPhuTrachMoi: null,
      loadingNguoiPhuTrach: false,
      filteredSignerProfiles: [],

      // Bảng màu chuyên nghiệp mở rộng
      dsBangMau: [
        '#cbd5e1', // Xám
        '#2196F3', // Xanh dương
        '#9c27b0', // Tím
        '#4caf50', // Xanh lá
        '#8bc34a', // Xanh lá mạ
        '#3f51b5', // Tím đậm
        '#d9a441', // Vàng cát
        '#ff9800', // Cam
        '#f44336', // Đỏ
        '#e91e63', // Hồng
        '#009688', // Ngọc bích/Teal
        '#00bcd4', // Cyan
        '#ffc107', // Vàng sáng
        '#795548', // Nâu đất
        '#607d8b'  // Xám xanh/Slate
      ]
    }
  },
  watch: {
    signerProfiles: {
      immediate: true,
      handler: function (newVal) {
        this.filteredSignerProfiles = Array.isArray(newVal) ? newVal : []
      }
    }
  },
  mounted() {
    this.taiDanhSachNhan()
    this.sys_UserName = this.getCurrentUserName()
    this.sys_EmployeeCode = this.getCurrentEmployeeCode()
  },
  methods: {
    getInitials: function (name) {
      if (!name) return ''
      var parts = String(name).trim().split(/\s+/)
      if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
      var word1 = parts[parts.length - 2] || ''
      var word2 = parts[parts.length - 1] || ''
      return (word1.charAt(0) + word2.charAt(0)).toUpperCase()
    },
    onSearchNguoiPhuTrach: async function (searchVal) {
      const query = String(searchVal || '').trim()
      if (!query) {
        this.filteredSignerProfiles = Array.isArray(this.signerProfiles) ? this.signerProfiles : []
        return
      }
      this.loadingNguoiPhuTrach = true
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_SignerProfile_GetList', { Keyword: query })
          this.filteredSignerProfiles = Array.isArray(res) ? res : []
        }
      } catch (err) {
        console.error('Lỗi khi tìm kiếm người phụ trách:', err)
      } finally {
        this.loadingNguoiPhuTrach = false
      }
    },
    ganNguoiPhuTrach: async function (card, employeeCode) {
      if (!card || !card.InstanceID) return
      try {
        if (typeof apiCallAsync === 'function') {
          await apiCallAsync('WF_Instance_AssignPIC', {
            InstanceID: card.InstanceID,
            AssignTo: employeeCode
          })
          if (typeof showToast !== 'undefined' && showToast.success) {
            showToast.success('Thay đổi người phụ trách thành công!')
          }
          this.$emit('refresh-board')
        }
      } catch (err) {
        var msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.responseText ? err.responseText : 'Lỗi khi gán người phụ trách.')
        if (typeof showToast !== 'undefined' && showToast.error) {
          showToast.error(msg)
        }
      }
    },
    async taiDanhSachNhan() {
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_Tag_GetList', {})
          this.danhSachNhan = Array.isArray(res) ? res : []
        }
      } catch (e) {
        console.error('Lỗi tải danh mục nhãn:', e)
      }
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
    // Trả về màu nền nhạt hơn của Tag để font chữ đen hiển thị đẹp, rõ ràng nhất
    getTagColorLight(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      if (!tag || !tag.Color) return '#f1f5f9'
      const hex = tag.Color

      // Convert các mã màu đậm sang dạng nhạt (tonal) 12% opacity để thiết kế mềm mại
      const map = {
        '#2196F3': '#e3f2fd', // Xanh dương
        '#9c27b0': '#f3e5f5', // Tím
        '#4caf50': '#e8f5e9', // Xanh lá
        '#8bc34a': '#f1f8e9', // Xanh lá mạ
        '#3f51b5': '#e8eaf6', // Tím đậm
        '#d9a441': '#fdf6e2', // Vàng cát
        '#ff9800': '#fff3e0', // Cam
        '#f44336': '#ffebee', // Đỏ
        '#e91e63': '#fce4ec', // Hồng
        '#cbd5e1': '#f1f5f9', // Xám
        '#009688': '#e0f2f1', // Ngọc bích/Teal
        '#00bcd4': '#e0f7fa', // Cyan
        '#ffc107': '#fff8e1', // Vàng sáng
        '#795548': '#efebe9', // Nâu đất
        '#607d8b': '#eceff1'  // Xám xanh/Slate
      }
      return map[hex] || hex
    },
    // Trả về màu đậm hơn của Tag để làm màu viền nét đứt (border dashed) cực kỳ cao cấp
    getTagBorderColor(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      return tag ? (tag.Color || '#cbd5e1') : '#cbd5e1'
    },
    // Trả về màu text đậm để đọc cực rõ trên nền nhạt
    getTagTextColorDark(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      if (!tag || !tag.Color) return '#475569'
      const hex = tag.Color
      const map = {
        '#2196F3': '#1e88e5', // Xanh dương
        '#9c27b0': '#8e24aa', // Tím
        '#4caf50': '#2e7d32', // Xanh lá
        '#8bc34a': '#558b2f', // Xanh lá mạ
        '#3f51b5': '#3f51b5', // Tím đậm
        '#d9a441': '#b58010', // Vàng cát
        '#ff9800': '#e65100', // Cam
        '#f44336': '#c62828', // Đỏ
        '#e91e63': '#c2185b', // Hồng
        '#cbd5e1': '#475569', // Xám
        '#009688': '#00796b', // Ngọc bích/Teal
        '#00bcd4': '#0097a7', // Cyan
        '#ffc107': '#f57f17', // Vàng sáng
        '#795548': '#5d4037', // Nâu đất
        '#607d8b': '#37474f'  // Xám xanh/Slate
      }
      return map[hex] || hex
    },
    getTagTextColorByHex(hex) {
      if (!hex || hex === '#cbd5e1' || hex === '#e2e8f0') return '#374151'
      return '#ffffff'
    },
    customTagFilter(value, query, item) {
      if (!query) return true
      const q = String(query).toLowerCase().trim()
      const val = String(value).toLowerCase().trim()
      return val.indexOf(q) !== -1
    },
    customSignerFilter(value, query, item) {
      if (!query) return true
      const q = String(query).toLowerCase().trim()
      const fullName = String(item && item.raw && item.raw.FullName || '').toLowerCase().trim()
      const empCode = String(item && item.raw && item.raw.EmployeeCode || '').toLowerCase().trim()
      return fullName.indexOf(q) !== -1 || empCode.indexOf(q) !== -1
    },
    moSuaNhanInline(the) {
      this.editingCardId = the.InstanceID
      this.editingType = 'TAG'
      this.nhanDaChon = this.tagStringToList(the.Tag)
      this.dialogNhan = true
    },
    moSuaNguoiPhuTrachInline(the) {
      this.editingCardId = the.InstanceID
      this.editingType = 'ASSIGNEE'
      this.nguoiPhuTrachMoi = the.AssigneeCode || null
      this.dialogGiaoViec = true
      console.log('signerProfiles count:', this.signerProfiles ? this.signerProfiles.length : 0)
    },
    async luuNhan() {
      if (!this.editingCardId) return
      try {
        const tagsString = this.nhanDaChon.join(',')
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_Instance_SaveTags', {
            InstanceID: this.editingCardId,
            Tags: tagsString
          })
          if (res && res.Success !== false) {
            const the = this.dsThe.find(t => t.InstanceID === this.editingCardId)
            if (the) the.Tag = tagsString
            this.editingCardId = null
            this.dialogNhan = false
            if (showToast && showToast.success) showToast.success('Cập nhật nhãn thành công')
            this.$emit('refresh-board')
          } else {
            if (showToast && showToast.error) showToast.error(res.Message || 'Lỗi cập nhật nhãn')
          }
        }
      } catch (e) {
        console.error('Lỗi cập nhật nhãn dán:', e)
      }
    },
    async luuNguoiPhuTrach() {
      if (!this.editingCardId) return
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_Instance_AssignPIC', {
            InstanceID: this.editingCardId,
            AssignTo: this.nguoiPhuTrachMoi
          })
          if (res && res.Success !== false) {
            const the = this.dsThe.find(t => t.InstanceID === this.editingCardId)
            if (the) {
              the.AssigneeCode = this.nguoiPhuTrachMoi
              const signer = this.signerProfiles.find(s => s.EmployeeCode === this.nguoiPhuTrachMoi)
              the.AssigneeName = signer ? signer.FullName : (this.nguoiPhuTrachMoi || '')
            }
            this.editingCardId = null
            this.dialogGiaoViec = false
            if (showToast && showToast.success) showToast.success('Thay đổi người phụ trách thành công')
            this.$emit('refresh-board')
          } else {
            if (showToast && showToast.error) showToast.error(res.Message || 'Lỗi thay đổi người phụ trách')
          }
        }
      } catch (e) {
        console.error('Lỗi thay đổi người phụ trách:', e)
      }
    },
    moQuanLyNhan() {
      this.dialogQuanLyNhan = true
    },
    async themNhanMoi() {
      if (!this.nhanMoiName.trim()) return
      try {
        const key = this.nhanMoiName.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/\s+/g, '')
        if (typeof apiCallAsync === 'function') {
          await apiCallAsync('WF_Tag_Save', {
            Tag: key,
            TagName: this.nhanMoiName.trim(),
            Color: this.nhanMoiColor,
            IsActive: 1
          })
          this.nhanMoiName = ''
          await this.taiDanhSachNhan()
          if (showToast && showToast.success) showToast.success('Thêm nhãn dán mới thành công')
        }
      } catch (e) {
        console.error('Lỗi thêm nhãn mới:', e)
      }
    },
    async xoaNhan(tagKey) {
      const self = this
      if (typeof $ !== 'undefined' && $.confirm) {
        $.confirm({
          title: 'Xác nhận xóa nhãn dán',
          content: 'Bạn có chắc chắn muốn xóa nhãn dán này không? Hành động này không thể hoàn tác.',
          type: 'red',
          animateFromElement: false,
          buttons: {
            cancel: {
              text: '<i class="v-icon v-icon--size-default mdi mdi-close mr-1"></i> Hủy',
              btnClass: 'wf-confirm-btn wf-confirm-btn--cancel',
              action: function () {}
            },
            ok: {
              text: '<i class="v-icon v-icon--size-default mdi mdi-check-circle mr-1"></i> Đồng ý',
              btnClass: 'wf-confirm-btn wf-confirm-btn--danger btn-red',
              keys: ['enter'],
              action: async function () {
                try {
                  if (typeof apiCallAsync === 'function') {
                    await apiCallAsync('WF_Tag_Delete', { Tag: tagKey })
                    await self.taiDanhSachNhan()
                    if (typeof showToast !== 'undefined' && showToast.success) {
                      showToast.success('Xóa nhãn dán thành công')
                    }
                  }
                } catch (e) {
                  console.error('Lỗi xóa nhãn dán:', e)
                }
              }
            }
          }
        })
      } else {
        if (confirm('Bạn có chắc chắn muốn xóa nhãn dán này không?')) {
          try {
            if (typeof apiCallAsync === 'function') {
              await apiCallAsync('WF_Tag_Delete', { Tag: tagKey })
              await this.taiDanhSachNhan()
              if (typeof showToast !== 'undefined' && showToast.success) {
                showToast.success('Xóa nhãn dán thành công')
              }
            }
          } catch (e) {
            console.error('Lỗi xóa nhãn dán:', e)
          }
        }
      }
    },
    moSuaHanChotInline(the) {
      this.editingCardId = the.InstanceID
      this.editingCardTitle = the.tieuDe || the.InstanceName || ''
      this.dialogSuaSLA = true
      const pad = (n) => String(n).padStart(2, '0')

      if (the.StepStartDate) {
        const dStart = new Date(the.StepStartDate)
        if (!isNaN(dStart)) {
          this.slaStartDate = dStart.getFullYear() + '-' + pad(dStart.getMonth() + 1) + '-' + pad(dStart.getDate())
          this.slaStartTime = pad(dStart.getHours()) + ':' + pad(dStart.getMinutes())
        } else {
          this.slaStartDate = ''
          this.slaStartTime = '08:00'
        }
      } else {
        this.slaStartDate = ''
        this.slaStartTime = '08:00'
      }

      if (the.StepDueDate) {
        const d = new Date(the.StepDueDate)
        if (!isNaN(d)) {
          this.slaEndDate = d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
          this.slaEndTime = pad(d.getHours()) + ':' + pad(d.getMinutes())
        } else {
          this.slaEndDate = ''
          this.slaEndTime = '17:30'
        }
      } else {
        this.slaEndDate = ''
        this.slaEndTime = '17:30'
      }
    },
    async luuHanChot() {
      if (!this.editingCardId) return
      try {
        if (!this.slaEndDate) {
          alert('Vui lòng chọn ngày hết hạn (SLA) hợp lệ')
          return
        }

        let stepStartDateStr = null
        if (this.slaStartDate) {
          stepStartDateStr = this.slaStartDate + ' ' + (this.slaStartTime || '08:00') + ':00'
        }
        const stepDueDateStr = this.slaEndDate + ' ' + (this.slaEndTime || '17:30') + ':00'

        // Kiểm tra logic ngày bắt đầu <= ngày kết thúc ở frontend
        if (stepStartDateStr && new Date(stepStartDateStr) > new Date(stepDueDateStr)) {
          alert('Thời gian bắt đầu không được lớn hơn thời hạn hết hạn (SLA)')
          return
        }

        if (typeof apiCallAsync === 'function') {
          const params = {
            InstanceID: this.editingCardId,
            StepDueDate: stepDueDateStr,
            StepStartDate: stepStartDateStr
          }
          const res = await apiCallAsync('WF_Instance_UpdateDueDate', params)
          if (res && res.Success !== false) {
            const the = this.dsThe.find(t => t.InstanceID === this.editingCardId)
            if (the) {
              the.StepStartDate = stepStartDateStr
              the.StepDueDate = stepDueDateStr
            }
            this.dialogSuaSLA = false
            if (showToast && showToast.success) showToast.success('Gia hạn thời gian nhắc nhở thành công')
            this.$emit('refresh-board')
          } else {
            if (showToast && showToast.error) showToast.error(res.Message || 'Lỗi cập nhật hạn chót')
          }
        }
      } catch (e) {
        console.error('Lỗi cập nhật hạn chót:', e)
        var msg = e && e.responseJSON ? e.responseJSON.Message : (e && e.responseText ? e.responseText : 'Lỗi cập nhật hạn chót.')
        if (typeof showToast !== 'undefined' && showToast.error) {
          showToast.error(msg)
        }
      }
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
      // Sắp hết hạn nếu còn dưới 24 giờ và chưa quá hạn
      return diffMs > 0 && diffMs <= 24 * 60 * 60 * 1000
    },
    getChecklistItems(the) {
      if (!the.ChecklistJSON) return []
      try {
        if (typeof the.ChecklistJSON === 'string') {
          return JSON.parse(the.ChecklistJSON) || []
        }
        return the.ChecklistJSON || []
      } catch (e) {
        return []
      }
    },
    getCompletedCount(the) {
      const items = this.getChecklistItems(the)
      return items.filter(function (i) { return i.IsCompleted }).length
    },
    getDsTheoCot(iCot) {
      const cot = this.dsCot[iCot]
      if (!cot || !cot.id) return []

      return this.dsThe.filter(t => {
        if (cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS') {
          return t.Status === 'COMPLETED' || t.Status === 'SUCCESS' || t.CurrentStepDefID === cot.id
        }
        if (cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE') {
          return t.Status === 'REJECTED' || t.Status === 'CANCELLED' || t.Status === 'FAILURE' || t.CurrentStepDefID === cot.id
        }

        const isFinished = t.Status === 'COMPLETED' || t.Status === 'SUCCESS' || t.Status === 'REJECTED' || t.Status === 'CANCELLED' || t.Status === 'FAILURE';
        // Với các cột thường, ẩn các thẻ đã kết thúc (thành công/thất bại)
        if (isFinished) return false;

        if (t.CurrentStepDefID) return t.CurrentStepDefID === cot.id
        if (t.CurrentStepOrder !== undefined && cot.order !== undefined) return t.CurrentStepOrder === cot.order
        return false
      })
    },
    getStatusColor(status) {
      const key = String(status || '').toUpperCase()
      if (key === 'COMPLETED') return '#2a9d5b'
      if (key === 'REJECTED' || key === 'CANCELLED') return '#e07a7a'
      if (key === 'RUNNING' || key === 'ACTIVE' || key === 'SIGNING') return '#5b8fd6'
      if (key === 'WAITING_ME' || key === 'PENDING') return '#d9a441'
      return '#9aa5b1'
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
    getStepInfo(the) {
      var cot = null
      if (the.CurrentStepDefID && typeof the.CurrentStepDefID === 'number') {
        cot = this.dsCot.find(function (c) { return c.id === the.CurrentStepDefID })
      }
      if (!cot && the.CurrentStepOrder) {
        cot = this.dsCot.find(function (c) { return c.order === the.CurrentStepOrder })
      }
      return cot || {}
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
    moveStep(the, cot, index) {
      this.$emit('drop', { cardId: the.id, iCot: index })
    },
    onDragStart(e, the) {
      this.dragCardId = the.id
      e.dataTransfer.effectAllowed = 'move'
      e.dataTransfer.setData('cardId', String(the.id))
    },
    onDragEnd() {
      this.dragCardId = null
      this.dragOverCol = null
    },
    onDragOver(e, iCot) {
      e.preventDefault()
      if (this.dragOverCol !== iCot) {
        this.dragOverCol = iCot
      }
    },
    onDragLeave() {
      this.dragOverCol = null
    },
    onBoardDragOver(e) {
      const board = this.$refs.kanbanBoard
      if (!board) return
      const rect = board.getBoundingClientRect()
      const edge = 100
      const speed = 15
      if (e.clientX - rect.left < edge) board.scrollLeft -= speed
      else if (rect.right - e.clientX < edge) board.scrollLeft += speed
    },
    onDrop(e, iCot) {
      e.preventDefault()
      const cardId = parseInt(e.dataTransfer.getData('cardId'))
      if (cardId) this.$emit('drop', { cardId, iCot })
      this.dragCardId = null
      this.dragOverCol = null
    },
    getCurrentUserName() {
      if (typeof window !== 'undefined') {
        return window.sys_UserName || window.sys_FullName || localStorage.getItem('EmployeeName') || localStorage.getItem('FullName') || 'Me';
      }
      return 'Me';
    },
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
    getChuaHoanThanhCount(iCot) {
      return this.getChuaHoanThanhDs(iCot).length
    },
    getChuaHoanThanhDs(iCot) {
      return this.getDsTheoCot(iCot).filter(t => {
        return t.Status !== 'COMPLETED' && t.Status !== 'SUCCESS'
      })
    },
    getDaHoanThanhDs(iCot) {
      return this.getDsTheoCot(iCot).filter(t => {
        return t.Status === 'COMPLETED' || t.Status === 'SUCCESS'
      })
    },
    getStepDoneDs(iCot) {
      return this.getDsTheoCot(iCot).filter(t => {
        return t.StepExecutionStatus === 'DONE'
      })
    },
    getStepActiveDs(iCot) {
      return this.getDsTheoCot(iCot).filter(t => {
        return t.StepExecutionStatus !== 'DONE'
      })
    },
    getTasksList(the) {
      if (!the.TasksJSON) return []
      try {
        if (typeof the.TasksJSON === 'string') {
          return JSON.parse(the.TasksJSON) || []
        }
        return the.TasksJSON || []
      } catch (e) {
        return []
      }
    },
    getFieldCountText(cot) {
      if (!cot) return 'Nhập liệu'
      const type = String(cot.stepType || cot.stepCode || '').toUpperCase()
      if (type === 'REVIEW') return 'Xem duyệt'
      if (type === 'SIGN') return 'Ký số'
      if (type === 'ECONTRACT') return 'Ký hợp đồng'
      return 'Nhập liệu'
    },
    getSignersList(the) {
      if (!the.SignersJSON) return []
      try {
        if (typeof the.SignersJSON === 'string') {
          return JSON.parse(the.SignersJSON) || []
        }
        return the.SignersJSON || []
      } catch (e) {
        return []
      }
    },
    getSignersCompletedCount(the) {
      const list = this.getSignersList(the)
      return list.filter(s => s.Status === 'SIGNED').length
    },
    getTasksCompletedCount(the) {
      const list = this.getTasksList(the)
      return list.filter(t => t.Status === 'DONE').length
    },
    async toggleSubTaskStatus(task, the) {
      if (!task || !task.TaskID) return
      var newStatus = task.Status === 'DONE' ? 'TODO' : 'DONE'
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_InstanceTask_UpdateStatus', {
            TaskID: task.TaskID,
            Status: newStatus
          })
          if (res && (res.Success === true || Number(res.Success) === 1 || res.Success !== false)) {
            task.Status = newStatus

            // Cập nhật TasksJSON local trên thẻ để Vue cập nhật reactive mà không cần reload
            if (the) {
              let tasks = []
              if (typeof the.TasksJSON === 'string') {
                try {
                  tasks = JSON.parse(the.TasksJSON) || []
                } catch (e) {
                  tasks = []
                }
              } else {
                tasks = the.TasksJSON || []
              }
              const found = tasks.find(t => t.TaskID === task.TaskID)
              if (found) {
                found.Status = newStatus
              }
              if (typeof the.TasksJSON === 'string') {
                the.TasksJSON = JSON.stringify(tasks)
              } else {
                the.TasksJSON = tasks
              }
            }

            if (typeof showToast !== 'undefined' && showToast.success) {
              showToast.success('Cập nhật trạng thái nhiệm vụ thành công')
            }
          } else {
            if (typeof showToast !== 'undefined' && showToast.error) {
              showToast.error(res.Message || 'Lỗi cập nhật trạng thái nhiệm vụ')
            }
          }
        }
      } catch (e) {
        console.error('Lỗi cập nhật trạng thái nhiệm vụ con:', e)
      }
    },

    getColBgColor(cot) {
      if (!cot) return '#ffffff'
      if (cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS') {
        return '#f1fbe9' // Xanh lá nhạt chuẩn
      }
      if (cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE') {
        return '#fff5f5' // Đỏ nhạt chuẩn
      }
      return '#ffffff' // Cột thường màu trắng
    },
    getColBorderColor(cot) {
      if (!cot) return '#e2e8f0'
      if (cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS') {
        return '#c5e1a5'
      }
      if (cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE') {
        return '#ef9a9a'
      }
      return '#e2e8f0'
    },
    getColHeaderTextColor(cot) {
      if (!cot) return '#1e293b'
      if (cot.stepType === 'SUCCESS' || cot.stepCode === 'STEP_SUCCESS') {
        return '#2e7d32'
      }
      if (cot.stepType === 'FAILURE' || cot.stepCode === 'STEP_FAILURE') {
        return '#c62828'
      }
      return '#1e293b'
    },

    kiemTraQuyenBaoHoanThanh(the, cot) {
      return true; // Bỏ phân quyền check done
    },
    async baoHoanThanh(the) {
      if (!the || !the.InstanceID) return
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_StepExecution_UpdateStatus', {
            InstanceID: the.InstanceID,
            Status: 'DONE'
          })
          if (res && res.Success !== false) {
            the.StepExecutionStatus = 'DONE'
            if (typeof showToast !== 'undefined' && showToast.success) {
              showToast.success('Đã báo hoàn thành bước thành công!')
            }
          } else {
            if (typeof showToast !== 'undefined' && showToast.error) {
              showToast.error(res.Message || 'Lỗi khi cập nhật trạng thái.')
            }
          }
        }
      } catch (err) {
        console.error('Lỗi khi báo hoàn thành:', err)
        const msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.responseText ? err.responseText : 'Lỗi hệ thống.')
        if (typeof showToast !== 'undefined' && showToast.error) {
          showToast.error(msg)
        }
      }
    },
    async thuHoiHoanThanh(the) {
      if (!the || !the.InstanceID) return
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_StepExecution_UpdateStatus', {
            InstanceID: the.InstanceID,
            Status: 'ACTIVE'
          })
          if (res && res.Success !== false) {
            the.StepExecutionStatus = 'ACTIVE'
            if (typeof showToast !== 'undefined' && showToast.success) {
              showToast.success('Đã thu hồi trạng thái hoàn thành!')
            }
          } else {
            if (typeof showToast !== 'undefined' && showToast.error) {
              showToast.error(res.Message || 'Lỗi khi cập nhật trạng thái.')
            }
          }
        }
      } catch (err) {
        console.error('Lỗi khi thu hồi hoàn thành:', err)
        const msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.responseText ? err.responseText : 'Lỗi hệ thống.')
        if (typeof showToast !== 'undefined' && showToast.error) {
          showToast.error(msg)
        }
      }
    },
    toggleCardCompleted(the) {
      if (the.Status === 'COMPLETED' || the.Status === 'SUCCESS') {
        if (typeof showToast !== 'undefined' && showToast.warning) {
          showToast.warning('Quy trình yêu cầu chuyển bước tuần tự, không thể đổi ngược trạng thái trực tiếp.')
        }
      } else {
        const successStep = this.dsCot.find(c => c.stepType === 'SUCCESS' || c.stepCode === 'STEP_SUCCESS')
        if (successStep) {
          const index = this.dsCot.indexOf(successStep)
          if (index !== -1) {
            this.moveStep(the, successStep, index)
          }
        } else {
          if (typeof showToast !== 'undefined' && showToast.error) {
            showToast.error('Không tìm thấy cột hoàn thành quy trình.')
          }
        }
      }
    }
  },
  emits: ['drop', 'add-card', 'edit-col', 'open-card', 'edit-card', 'delete-card', 'refresh-board']
	}
</script>