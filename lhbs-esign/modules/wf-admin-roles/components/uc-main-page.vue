<template>
	<uc-wf-shell>
        <div class="wf-page-header">
            <div>
                <h1>Phân quyền</h1>
                <p>Quản lý các nhóm vai trò (bộ phận), danh sách nhân sự trực thuộc và thiết lập quyền truy cập hệ
                    thống.</p>
            </div>
        </div>

        <div class="wf-roles-container">
            <!-- Cột Trái: Danh sách vai trò / bộ phận -->
            <div class="wf-roles-sidebar">
                <div class="wf-pane-header">
                    <h5>Nhóm vai trò</h5>
                    <v-btn icon="" size="x-small" variant="text" color="primary" @click="openRoleDialog()">
                        <v-icon size="20">mdi-plus</v-icon>
                    </v-btn>
                </div>

                <div class="wf-role-list">
                    <div v-if="isLoadingRoles" class="d-flex justify-center py-4">
                        <v-progress-circular indeterminate="" color="primary" size="24">
                        </v-progress-circular>
                    </div>
                    <div v-for="role in roles" :key="role.RolesID"
                        :class="['wf-role-item', { active: selectedRole &amp;&amp; selectedRole.RolesID === role.RolesID }]"
                        @click="selectRole(role)">
                        <div class="wf-role-item-main">
                            <div class="wf-role-item-name">{{ role.Name }}</div>
                            <div class="wf-role-item-meta">
                                <!-- Badge số nhân sự -->
                                <v-chip size="x-small" variant="tonal" color="success">
                                    {{ getUserCountForRole(role.RolesID) }}
                                    <v-icon size="12" class="ml-1">mdi-account</v-icon>
                                </v-chip>
                                <!-- Link phân quyền -->
                                <span class="wf-permission-link" @click.stop="openPermissionDialog(role)">
                                    Quyền ({{ getPermissionCountForRole(role.RolesID) }})
                                </span>
                            </div>
                        </div>
                        <div class="wf-role-item-actions">
                            <v-menu location="bottom end">
                                <template #activator="{ props }">
                                    <v-btn icon="" size="x-small" variant="text" v-bind="props">
                                        <v-icon size="16">mdi-dots-vertical</v-icon>
                                    </v-btn>
                                </template>
                                <v-list density="compact">
                                    <v-list-item @click="openRoleDialog(role)">
                                        <template #prepend="">
                                            <v-icon size="14">mdi-pencil</v-icon>
                                        </template>
                                        <v-list-item-title class="text-caption">Chỉnh sửa</v-list-item-title>
                                    </v-list-item>
                                    <v-list-item @click="deleteRole(role)" class="text-red">
                                        <template #prepend="">
                                            <v-icon size="14" color="error">mdi-delete</v-icon>
                                        </template>
                                        <v-list-item-title class="text-caption text-red">Xóa vai trò</v-list-item-title>
                                    </v-list-item>
                                </v-list>
                            </v-menu>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Cột Phải: Danh sách nhân sự thuộc vai trò -->
            <div class="wf-roles-content">
                <template v-if="selectedRole">
                    <div class="wf-pane-header">
                        <h5>Danh sách nhân sự</h5>
                        <v-btn class="wf-btn" color="primary" variant="outlined" @click="openAddUserDialog">
                            <v-icon start="" size="16">mdi-plus</v-icon>
                            Thêm nhân sự
                        </v-btn>
                    </div>

                    <div class="wf-users-table-wrapper">
                        <uc-table :rounded="false" :headers="userTableHeaders" :items="assignedUsers"
                            :loading="isLoadingUsers" item-value="EmployeeCode"
                            empty-text="Không có nhân sự nào trong vai trò này.">
                            <!-- Cột tên nhân sự + avatar -->
                            <template #item.FullName="{ item }">
                                <div class="d-flex align-center ga-3">
                                    <div class="wf-avatar-circle">{{ getAvatarInitial(item.FullName) }}</div>
                                    <div>
                                        <div class="wf-audit-title">{{ item.FullName }}</div>
                                        <div class="wf-audit-sub">{{ item.EmployeeCode }}</div>
                                    </div>
                                </div>
                            </template>
                            <!-- Cột bộ phận -->
                            <template #item.roleName>
                                {{ selectedRole.Name }}
                            </template>
                            <!-- Cột văn phòng -->
                            <template #item.DepartmentName="{ item }">
                                {{ item.DepartmentName || '-' }}
                            </template>
                            <!-- Cột actions -->
                            <template #item.actions="{ item }">
                                <v-btn icon size="x-small" variant="text" color="error"
                                    @click.stop="removeUserFromRole(item)">
                                    <v-icon size="14">mdi-delete-outline</v-icon>
                                </v-btn>
                            </template>
                        </uc-table>
                    </div>
                </template>
                <template v-else="">
                    <div class="h-100 d-flex align-center justify-center text-grey">
                        Chọn một vai trò/bộ phận ở cột bên trái để quản lý danh sách nhân sự.
                    </div>
                </template>
            </div>
        </div>

        <!-- Dialog 1: Thêm/Sửa vai trò -->
        <uc-modal v-model="showRoleDialog" :title="editingRole.RolesID ? 'Chỉnh sửa vai trò' : 'Thêm vai trò mới'"
            :max-width="500" confirm-text="Lưu" cancel-text="Hủy" :loading="isSavingRole" @confirm="saveRole">
            <v-text-field v-model="editingRole.Name" label="Tên vai trò (Bộ phận)" variant="outlined" density="compact"
                class="mb-4"></v-text-field>
            <v-text-field v-model="editingRole.Description" label="Mô tả" variant="outlined" density="compact">
            </v-text-field>
        </uc-modal>

        <!-- Dialog 2: Thiết lập quyền truy cập -->
        <v-dialog v-model="showPermissionDialog" max-width="900">
            <v-card v-if="permissionRole" style="border-radius: 12px; overflow: hidden;">
                <!-- Header -->
                <div class="perm-dialog-header">
                    <div>
                        <div class="perm-dialog-title">Thiết lập quyền truy cập</div>
                        <div class="perm-dialog-subtitle">{{ permissionRole.Name }}</div>
                    </div>
                    <v-btn icon="mdi-close" variant="text" size="small" color="white"
                        @click="showPermissionDialog = false">
                    </v-btn>
                </div>

                <!-- Body -->
                <div class="perm-dialog-body">
                    <div v-if="isLoadingPermissions" class="d-flex justify-center py-12">
                        <v-progress-circular indeterminate color="primary" size="36"></v-progress-circular>
                    </div>
                    <div v-else>
                        <div v-for="(groups, moduleName) in groupedPermissions" :key="moduleName"
                            class="perm-module-section">
                            <!-- Module Section Header -->
                            <div class="perm-module-header">
                                <div class="d-flex align-center ga-2">
                                    <v-icon size="14" color="primary">mdi-folder-outline</v-icon>
                                    <span class="perm-module-name">{{ moduleName }}</span>
                                </div>
                                <span class="perm-module-count">
                                    <span class="perm-count-selected">{{ getSelectedCountForModule(groups) }}</span>
                                    <span class="perm-count-sep">/</span>
                                    <span>{{ getTotalCountForModule(groups) }}</span>
                                </span>
                            </div>

                            <!-- Permission Group Cards -->
                            <div class="perm-groups-grid">
                                <div v-for="(perms, groupName) in groups" :key="groupName" class="perm-group-card">
                                    <!-- Group Header -->
                                    <div class="perm-group-header">
                                        <span class="perm-group-name">{{ groupName }}</span>
                                        <button class="perm-toggle-btn" @click.stop="toggleGroupSelection(perms)">
                                            {{ isGroupAllSelected(perms) ? 'Bỏ chọn' : 'Chọn tất cả' }}
                                        </button>
                                    </div>
                                    <!-- Permission Items -->
                                    <div class="perm-group-body">
                                        <div v-for="p in perms" :key="p.PermissionsID" class="perm-item"
                                            :class="{ 'perm-item--active': selectedPermissionIds.includes(p.PermissionsID) }"
                                            @click="togglePermissionSelection(p.PermissionsID)">
                                            <v-checkbox-btn
                                                :model-value="selectedPermissionIds.includes(p.PermissionsID)"
                                                color="primary" hide-details density="compact"
                                                style="flex-shrink: 0; pointer-events: none;">
                                            </v-checkbox-btn>
                                            <div class="perm-item-info">
                                                <span class="perm-item-name">{{ p.PermissionName }}</span>
                                                <span class="perm-item-key">{{ p.PermissionKey }}</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Footer -->
                <div class="perm-dialog-footer">
                    <v-btn color="primary" variant="flat" height="36" class="px-6 font-weight-bold text-caption"
                        style="border-radius: 6px; text-transform: none;" :loading="isSavingPermissions"
                        @click="saveRolePermissions">
                        <v-icon start size="15">mdi-content-save-outline</v-icon>
                        Lưu thay đổi
                    </v-btn>
                </div>
            </v-card>
        </v-dialog>

        <!-- Dialog 3: Thêm nhân sự vào vai trò -->
        <uc-modal v-model="showAddUserDialog"
            :title="'Thêm nhân sự vào vai trò ' + (selectedRole ? selectedRole.Name : '')" :max-width="600"
            confirm-text="Lưu" cancel-text="Hủy" :loading="isSavingUserAssignments" @confirm="saveUserAssignments">
            <v-autocomplete v-model="selectedUsersToAssign" :items="userOptions" item-title="title" item-value="value"
                label="Chọn nhân sự cần thêm" variant="outlined" density="compact" multiple chips closable-chips
                clearable>
            </v-autocomplete>
        </uc-modal>
    </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      roles: [],
      userCountByRoleId: {}, // Map [RolesID] -> Số nhân sự thuộc role (từ tblWF_UserRoles)
      allUsersList: [], // Danh sách tất cả người dùng trong hệ thống
      allPermissionsList: [], // Danh sách tất cả các quyền
      rolePermissionCounts: {}, // Map [RolesID] -> Số lượng quyền đã gán

      selectedRole: null,
      assignedUsers: [], // Danh sách nhân sự của vai trò được chọn

      // Trạng thái load
      isLoadingRoles: false,
      isLoadingUsers: false,
      isLoadingPermissions: false,
      isSavingRole: false,
      isSavingPermissions: false,
      isSavingUserAssignments: false,

      // Dialog 1: Role
      showRoleDialog: false,
      editingRole: {
        RolesID: 0,
        Name: "",
        Description: "",
        Enable: 1
      },

      // Dialog 2: Permission
      showPermissionDialog: false,
      permissionRole: null,
      selectedPermissionIds: [],

      // Dialog 3: Add User
      showAddUserDialog: false,
      selectedUsersToAssign: [],

      // uc-table headers cho danh sách nhân sự
      userTableHeaders: [
        { title: 'Tên nhân sự', key: 'FullName', width: '1.5fr' },
        { title: 'Bộ phận', key: 'roleName' },
        { title: 'Văn phòng', key: 'DepartmentName' },
        { title: '', key: 'actions', width: '50px', align: 'center' }
      ]
    }
  },
  computed: {
    // Nhóm permissions theo ModuleName -> FeatureGroup
    groupedPermissions: function () {
      const groups = {}
      this.allPermissionsList.forEach(function (p) {
        const mod = p.ModuleName || "Hệ thống"
        const feat = p.FeatureGroup || "Chức năng khác"
        if (!groups[mod]) groups[mod] = {}
        if (!groups[mod][feat]) groups[mod][feat] = []
        groups[mod][feat].push(p)
      })
      return groups
    },
    // Options cho autocomplete thêm nhân sự
    userOptions: function () {
      return this.allUsersList.map(function (u) {
        return {
          title: u.FullName + " (" + u.EmployeeCode + ") - " + (u.DepartmentName || "N/A"),
          value: u.EmployeeCode,
          user: u
        }
      })
    }
  },
  mounted: function () {
    this.initPage()
  },
  methods: {
    initPage: async function () {
      this.isLoadingRoles = true
      try {
        await Promise.all([
          this.loadRoles(),
          this.loadAllUsers(),
          this.loadAllPermissions()
        ])
        if (this.roles.length > 0) {
          this.selectRole(this.roles[0])
        }
      } catch (err) {
        this.showError(err, "Không khởi tạo được trang phân quyền.")
      } finally {
        this.isLoadingRoles = false
      }
    },
    loadRoles: async function () {
      try {
        const rows = await apiCallAsync("WF_Role_GetList", { Enable: 1 })
        this.roles = Array.isArray(rows) ? rows : (rows?.data || [])
        await this.loadRolePermissionCounts()
      } catch (err) {
        this.showError(err, "Không tải được danh sách vai trò.")
      }
    },
    loadRolePermissionCounts: async function () {
      const self = this
      const counts = {}
      const promises = this.roles.map(async function (role) {
        try {
          const res = await apiCallAsync("WF_RolePermission_GetByRole", { RolesID: role.RolesID })
          const list = Array.isArray(res) ? res : (res?.data || [])
          counts[role.RolesID] = list.length
        } catch (e) {
          counts[role.RolesID] = 0
        }
      })
      await Promise.all(promises)
      this.rolePermissionCounts = counts
    },
    loadAllUsers: async function () {
      try {
        const rows = await apiCallAsync("WF_User_GetList", {})
        this.allUsersList = Array.isArray(rows) ? rows : (rows?.data || [])
      } catch (err) {
        console.error("Lỗi tải danh mục người dùng:", err)
      }
    },
    loadAllPermissions: async function () {
      try {
        const rows = await apiCallAsync("WF_Permission_GetList")
        this.allPermissionsList = Array.isArray(rows) ? rows : (rows?.data || [])
      } catch (err) {
        console.error("Lỗi tải danh mục quyền hạn:", err)
      }
    },
    selectRole: async function (role) {
      this.selectedRole = role
      this.isLoadingUsers = true
      try {
        const rows = await apiCallAsync("WF_UserRole_GetByRole", { RolesID: role.RolesID })
        this.assignedUsers = Array.isArray(rows) ? rows : (rows?.data || [])
      } catch (err) {
        this.showError(err, "Không tải được danh sách nhân sự.")
      } finally {
        this.isLoadingUsers = false
      }
    },
    getUserCountForRole: function (roleId) {
      const role = this.roles.find(r => r.RolesID === roleId)
      return role ? (role.UserCount || 0) : 0
    },
    getPermissionCountForRole: function (roleId) {
      return this.rolePermissionCounts[roleId] || 0
    },
    getAvatarInitial: function (name) {
      return name ? name.charAt(0).toUpperCase() : "?"
    },
    // Role Dialog
    openRoleDialog: function (role) {
      if (role) {
        this.editingRole = {
          RolesID: role.RolesID,
          Name: role.Name,
          Description: role.Description,
          Enable: role.Enable
        }
      } else {
        this.editingRole = {
          RolesID: 0,
          Name: "",
          Description: "",
          Enable: 1
        }
      }
      this.showRoleDialog = true
    },
    saveRole: async function () {
      if (!this.editingRole.Name.trim()) {
        if (showToast) showToast.error("Vui lòng nhập tên vai trò.")
        return
      }
      this.isSavingRole = true
      try {
        await apiCallAsync("WF_Role_Save", {
          RolesID: Number(this.editingRole.RolesID || 0),
          Name: this.editingRole.Name.trim(),
          Description: this.editingRole.Description.trim(),
          Enable: Number(this.editingRole.Enable || 1)
        })
        if (showToast) showToast.success("Lưu vai trò thành công.")
        this.showRoleDialog = false
        await this.loadRoles()
      } catch (err) {
        this.showError(err, "Không lưu được vai trò.")
      } finally {
        this.isSavingRole = false
      }
    },
    deleteRole: function (role) {
      const self = this
      showConfirm("Bạn có chắc chắn muốn xóa vai trò " + role.Name + "?", async function () {
        try {
          await apiCallAsync("WF_Role_Delete", { RolesID: role.RolesID })
          if (showToast) showToast.success("Đã xóa vai trò thành công.")
          await self.loadRoles()
          if (self.selectedRole && self.selectedRole.RolesID === role.RolesID) {
            self.selectedRole = self.roles.length > 0 ? self.roles[0] : null
            if (self.selectedRole) self.selectRole(self.selectedRole)
          }
        } catch (err) {
          self.showError(err, "Không xóa được vai trò.")
        }
      })
    },
    // Permission dialog
    openPermissionDialog: async function (role) {
      this.permissionRole = role
      this.showPermissionDialog = true
      this.isLoadingPermissions = true
      this.selectedPermissionIds = []
      try {
        const res = await apiCallAsync("WF_RolePermission_GetByRole", { RolesID: role.RolesID })
        const list = Array.isArray(res) ? res : (res?.data || [])
        this.selectedPermissionIds = list.map(function (item) {
          return item.PermissionsID
        })
      } catch (err) {
        this.showError(err, "Không tải được quyền hạn của vai trò.")
      } finally {
        this.isLoadingPermissions = false
      }
    },
    togglePermissionSelection: function (id) {
      const idx = this.selectedPermissionIds.indexOf(id)
      if (idx === -1) {
        this.selectedPermissionIds.push(id)
      } else {
        this.selectedPermissionIds.splice(idx, 1)
      }
    },
    isGroupAllSelected: function (perms) {
      const self = this
      return perms.every(function (p) {
        return self.selectedPermissionIds.includes(p.PermissionsID)
      })
    },
    toggleGroupSelection: function (perms) {
      const self = this
      const allSelected = this.isGroupAllSelected(perms)
      perms.forEach(function (p) {
        const idx = self.selectedPermissionIds.indexOf(p.PermissionsID)
        if (allSelected) {
          if (idx !== -1) self.selectedPermissionIds.splice(idx, 1)
        } else {
          if (idx === -1) self.selectedPermissionIds.push(p.PermissionsID)
        }
      })
    },
    getSelectedCountForModule: function (groups) {
      const self = this
      let count = 0
      Object.values(groups).forEach(function (perms) {
        perms.forEach(function (p) {
          if (self.selectedPermissionIds.includes(p.PermissionsID)) count++
        })
      })
      return count
    },
    getTotalCountForModule: function (groups) {
      let count = 0
      Object.values(groups).forEach(function (perms) {
        count += perms.length
      })
      return count
    },
    saveRolePermissions: async function () {
      if (!this.permissionRole) return
      this.isSavingPermissions = true
      try {
        await apiCallAsync("WF_RolePermission_Save", {
          RolesID: this.permissionRole.RolesID,
          PermissionsIDList: this.selectedPermissionIds.join(",")
        })
        if (showToast) showToast.success("Cập nhật phân quyền thành công.")
        this.showPermissionDialog = false
        // Cập nhật lại số lượng quyền hiển thị ngoài list
        this.rolePermissionCounts = {
          ...this.rolePermissionCounts,
          [this.permissionRole.RolesID]: this.selectedPermissionIds.length
        }
      } catch (err) {
        this.showError(err, "Không lưu được phân quyền.")
      } finally {
        this.isSavingPermissions = false
      }
    },
    // User Assignment
    openAddUserDialog: function () {
      this.selectedUsersToAssign = []
      this.showAddUserDialog = true
    },
    saveUserAssignments: async function () {
      if (this.selectedUsersToAssign.length === 0) {
        if (showToast) showToast.error("Vui lòng chọn ít nhất một nhân sự.")
        return
      }
      this.isSavingUserAssignments = true
      try {
        const self = this
        // Lần lượt gán vai trò mới cho từng user
        const promises = this.selectedUsersToAssign.map(async function (userId) {
          // Lấy các vai trò hiện tại của user đó
          let currentRoles = []
          try {
            const res = await apiCallAsync("WF_UserRole_GetByUser", { UserID: userId })
            currentRoles = Array.isArray(res) ? res : (res?.data || [])
          } catch (e) {
            console.error("Không tải được vai trò hiện tại của user " + userId, e)
          }

          const roleIds = currentRoles.map(function (r) { return r.RolesID })
          if (!roleIds.includes(self.selectedRole.RolesID)) {
            roleIds.push(self.selectedRole.RolesID)
          }

          // Lưu lại các vai trò cập nhật
          await apiCallAsync("WF_UserRole_Save", {
            UserID: userId,
            RoleIDs: JSON.stringify(roleIds)
          })
        })

        await Promise.all(promises)
        if (showToast) showToast.success("Gán nhân sự vào vai trò thành công.")
        this.showAddUserDialog = false
        await this.loadRoles()
        if (this.selectedRole) {
          await this.selectRole(this.selectedRole)
        }
      } catch (err) {
        this.showError(err, "Không thể gán nhân sự vào vai trò.")
      } finally {
        this.isSavingUserAssignments = false
      }
    },
    removeUserFromRole: function (user) {
      const self = this
      showConfirm("Bạn có chắc chắn muốn gỡ nhân sự " + user.FullName + " ra khỏi vai trò hiện tại?", async function () {
        try {
          // Lấy vai trò hiện tại của user đó
          let currentRoles = []
          try {
            const res = await apiCallAsync("WF_UserRole_GetByUser", { UserID: user.EmployeeCode })
            currentRoles = Array.isArray(res) ? res : (res?.data || [])
          } catch (e) {
            console.error("Không tải được vai trò hiện tại của user " + user.UserID, e)
          }

          // Lọc bỏ vai trò hiện tại ra khỏi danh sách
          const roleIds = currentRoles
            .map(function (r) { return r.RolesID })
            .filter(function (id) { return id !== self.selectedRole.RolesID })

          // Lưu lại
          await apiCallAsync("WF_UserRole_Save", {
            UserID: user.UserID,
            RoleIDs: JSON.stringify(roleIds)
          })

          if (showToast) showToast.success("Đã gỡ nhân sự ra khỏi vai trò.")
          await self.loadRoles()
          if (self.selectedRole) {
            await self.selectRole(self.selectedRole)
          }
        } catch (err) {
          self.showError(err, "Không gỡ được nhân sự.")
        }
      })
    },
    showError: function (err, fallback) {
      let message = ""
      if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message
      else if (err && err.responseText) message = err.responseText
      else if (err && err.message) message = err.message
      else message = fallback || "Có lỗi xảy ra."
      if (showToast && showToast.error) showToast.error(message)
    }
  }
	}
</script>