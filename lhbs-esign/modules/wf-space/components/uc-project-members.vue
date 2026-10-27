<template>
	<div class="wf-project-members">
    <!-- Add member (chỉ khi có quyền) -->
    <div v-if="canManage" class="d-flex align-end ga-2 mb-4">
      <div class="flex-grow-1">
        <div class="text-caption text-grey-darken-3 mb-1">Thêm thành viên</div>
        <uc-select-user v-model="addCode" placeholder="Tìm theo tên / mã nhân viên..." clearable />
      </div>
      <v-select v-model="addRole" :items="roleOptions" item-title="label" item-value="value"
        variant="outlined" density="compact" hide-details style="width: 130px; flex-shrink: 0;"
        class="wf-ant-input bg-white mb-2" />
      <v-btn color="primary" variant="flat" height="40" class="font-weight-bold text-caption text-white px-4 mb-2"
        style="text-transform: none; border-radius: 4px;" :loading="adding" :disabled="!addCode" @click="addMember">
        <v-icon start size="14">mdi-account-plus-outline</v-icon>
        Thêm
      </v-btn>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="text-center py-4">
      <v-progress-circular indeterminate color="primary" size="24" />
    </div>

    <!-- Member list -->
    <div v-else class="bg-white border rounded-lg overflow-hidden" style="border-color: #e2e8f0 !important;">
      <div v-if="members.length === 0" class="text-center py-8 text-caption text-grey">
        <v-icon size="32" color="grey-lighten-1" class="mb-1">mdi-account-off-outline</v-icon>
        <div>Chưa có thành viên nào.</div>
      </div>
      <div v-for="m in members" :key="m.MemberID"
        class="d-flex align-center ga-3 px-4 py-2 border-bottom"
        style="border-bottom: 1px solid #f1f5f9 !important;">
        <uc-avatar :name="m.FullName" :size="30" font-size="11px" />
        <div class="flex-grow-1 min-w-0">
          <div class="text-caption font-weight-bold text-grey-darken-4 text-truncate" style="font-size: 13px !important;">
            {{ m.FullName || m.EmployeeCode }}
            <v-chip v-if="m.IsCurrentUser" size="x-small" color="primary" variant="tonal" class="px-1 ml-1"
              style="height: 16px; font-size: 9px;">Tôi</v-chip>
          </div>
          <div class="text-caption text-grey" style="font-size: 10px;">{{ m.EmployeeCode }}</div>
        </div>

        <!-- Role -->
        <v-select v-if="canManage" :model-value="m.Role" :items="roleOptions" item-title="label" item-value="value"
          variant="outlined" density="compact" hide-details style="width: 120px;" class="wf-ant-input bg-white"
          @update:model-value="changeRole(m, $event)" />
        <v-chip v-else size="small" :color="roleColor(m.Role)" variant="tonal" class="font-weight-bold"
          style="font-size: 10px;">{{ roleLabel(m.Role) }}</v-chip>

        <!-- Remove -->
        <v-btn v-if="canManage" icon size="x-small" variant="text" color="error" @click="removeMember(m)">
          <v-icon size="16">mdi-close</v-icon>
        </v-btn>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-project-members',
  props: {
    projectId: { type: Number, default: 0 },
    canManage: { type: Boolean, default: false }
  },
  data: function () {
    return {
      members: [],
      isLoading: false,
      adding: false,
      addCode: null,
      addRole: 'MEMBER',
      roleOptions: [
        { label: 'Lead', value: 'LEAD' },
        { label: 'Thành viên', value: 'MEMBER' },
        { label: 'Người xem', value: 'VIEWER' }
      ]
    }
  },
  watch: {
    projectId: function (val) { if (val) this.loadMembers() }
  },
  mounted: function () {
    if (this.projectId) this.loadMembers()
  },
  methods: {
    loadMembers: async function () {
      if (!this.projectId) return
      this.isLoading = true
      try {
        var res = await apiCallAsync('WF_ProjectMember_GetList', { ProjectID: this.projectId })
        this.members = Array.isArray(res) ? res : []
      } catch (e) {
        this.members = []
      } finally {
        this.isLoading = false
      }
    },

    addMember: async function () {
      if (!this.addCode || this.adding) return
      this.adding = true
      try {
        var res = await apiCallAsync('WF_ProjectMember_Save', {
          ProjectID: this.projectId, EmployeeCode: this.addCode, Role: this.addRole
        })
        var row = Array.isArray(res) ? res[0] : res
        if (row && (row.Success === false || row.Success === 0)) { showToast.error(row.Message || 'Không thể thêm.'); return }
        showToast.success('Đã thêm thành viên.')
        this.addCode = null
        this.addRole = 'MEMBER'
        await this.loadMembers()
        this.$emit('changed')
      } catch (e) { /* handled */ } finally { this.adding = false }
    },

    changeRole: async function (m, role) {
      if (role === m.Role) return
      try {
        var res = await apiCallAsync('WF_ProjectMember_Save', {
          ProjectID: this.projectId, EmployeeCode: m.EmployeeCode, Role: role
        })
        var row = Array.isArray(res) ? res[0] : res
        if (row && (row.Success === false || row.Success === 0)) { showToast.error(row.Message || 'Không thể đổi vai trò.'); await this.loadMembers(); return }
        showToast.success('Đã đổi vai trò.')
        await this.loadMembers()
        this.$emit('changed')
      } catch (e) { await this.loadMembers() }
    },

    removeMember: function (m) {
      var self = this
      showConfirm('Gỡ "' + (m.FullName || m.EmployeeCode) + '" khỏi project?', async function () {
        try {
          var res = await apiCallAsync('WF_ProjectMember_Delete', { ProjectID: self.projectId, EmployeeCode: m.EmployeeCode })
          var row = Array.isArray(res) ? res[0] : res
          if (row && (row.Success === false || row.Success === 0)) { showToast.error(row.Message || 'Không thể gỡ.'); return }
          showToast.success('Đã gỡ thành viên.')
          await self.loadMembers()
          self.$emit('changed')
        } catch (e) { /* handled */ }
      })
    },

    roleLabel: function (r) {
      return { LEAD: 'Lead', MEMBER: 'Thành viên', VIEWER: 'Người xem' }[r] || r || ''
    },
    roleColor: function (r) {
      return { LEAD: 'primary', MEMBER: 'blue', VIEWER: 'grey' }[r] || 'grey'
    }
  }
	}
</script>