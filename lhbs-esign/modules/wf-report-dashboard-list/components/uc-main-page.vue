<template>
	<uc-wf-shell>
    <div class="wf-page-header">
      <div>
        <h1>Quản lý dashboard</h1>
        <p>Tạo, đổi tên, đặt mặc định và mở từng dashboard ở chế độ thiết kế hoặc trình chiếu.</p>
      </div>
      <div class="wf-report-header-actions">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="openCreateDialog()">
          <v-icon start>mdi-plus</v-icon>
          Tạo dashboard
        </v-btn>
      </div>
    </div>

    <div class="wf-stat-strip wf-stat-strip--4">
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--all"><v-icon>mdi-view-dashboard-outline</v-icon></div>
        <div><div class="wf-stat-val">{{ dashboards.length }}</div><div class="wf-stat-lbl">Tổng dashboard</div></div>
      </div>
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--completed"><v-icon>mdi-star-outline</v-icon></div>
        <div><div class="wf-stat-val">{{ defaultDashboardName }}</div><div class="wf-stat-lbl">Dashboard mặc định</div></div>
      </div>
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--running"><v-icon>mdi-view-grid-plus-outline</v-icon></div>
        <div><div class="wf-stat-val">{{ totalWidgetCount }}</div><div class="wf-stat-lbl">Widget đã ghim</div></div>
      </div>
      <div class="wf-stat-pill">
        <div class="wf-stat-icon wf-stat-icon--waiting"><v-icon>mdi-presentation-play</v-icon></div>
        <div><div class="wf-stat-val">{{ activeDashboardCount }}</div><div class="wf-stat-lbl">Dashboard hoạt động</div></div>
      </div>
    </div>

    <div class="wf-tcard wf-report-library-filter-card">
      <div class="wf-tcard-toolbar">
        <h3>Bộ lọc dashboard</h3>
      </div>
      <div class="wf-template-dialog-body">
        <v-row dense>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="searchQuery"
              density="compact"
              prepend-inner-icon="mdi-magnify"
              variant="outlined"
              hide-details="auto"
              label="Tìm theo tên dashboard"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="defaultFilter"
              :items="defaultFilterOptions"
              density="compact"
              variant="outlined"
              hide-details="auto"
              label="Mặc định"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="statusFilter"
              :items="statusOptions"
              density="compact"
              variant="outlined"
              hide-details="auto"
              label="Trạng thái"
            />
          </v-col>
        </v-row>
      </div>
    </div>

    <div class="wf-tcard wf-report-library-card">
      <div class="wf-trow wf-trow-header wf-report-dashboard-list-grid">
        <div>Tên dashboard</div>
        <div>Widget</div>
        <div>Mặc định</div>
        <div>Cập nhật</div>
        <div></div>
      </div>
      <div v-for="item in filteredDashboards" :key="item.id" class="wf-trow wf-report-dashboard-list-grid">
        <div>
          <div class="wf-audit-title">{{ item.name }}</div>
          <div class="wf-audit-sub">{{ dashboardSubtitle(item) }}</div>
        </div>
        <div class="wf-report-strong">{{ item.widgetCount }}</div>
        <div>
          <v-chip size="x-small" :color="item.isDefault ? 'primary' : '#6f7f8c'" :variant="item.isDefault ? 'tonal' : 'outlined'">
            {{ item.isDefault ? 'Mặc định' : 'Thường' }}
          </v-chip>
        </div>
        <div>{{ item.updatedAt }}</div>
        <div class="wf-audit-actions">
          <v-btn icon size="x-small" variant="text" color="primary" @click="openDesigner(item)"><v-icon size="14">mdi-pencil-outline</v-icon></v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" @click="openPresent(item)"><v-icon size="14">mdi-presentation-play</v-icon></v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" @click="openEditDialog(item)"><v-icon size="14">mdi-rename-box</v-icon></v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" :disabled="item.isDefault" @click="setDefault(item)"><v-icon size="14">mdi-star-outline</v-icon></v-btn>
          <v-btn icon size="x-small" variant="text" class="wf-icon-danger" :disabled="item.isDefault" @click="deleteDashboard(item)"><v-icon size="14">mdi-delete-outline</v-icon></v-btn>
        </div>
      </div>
      <div v-if="filteredDashboards.length === 0" class="wf-empty-state">
        Chưa có dashboard nào khớp bộ lọc hiện tại.
      </div>
    </div>

    <v-dialog v-model="isEditDialogOpen" max-width="520">
      <v-card class="wf-template-dialog">
        <div class="wf-template-dialog__header">
          <div>
            <h3>{{ editingDashboardId ? 'Cập nhật dashboard' : 'Tạo dashboard mới' }}</h3>
            <p>Đặt tên dashboard trước, sau đó mở sang màn thiết kế để chia section và gắn widget.</p>
          </div>
          <v-btn icon size="small" variant="text" color="primary" @click="isEditDialogOpen = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <div class="wf-template-dialog-body">
          <v-text-field
            v-model="editingDashboardName"
            label="Tên dashboard"
            variant="outlined"
            density="compact"
            hide-details="auto"
          />
          <v-switch
            v-model="editingDashboardDefault"
            color="primary"
            density="compact"
            hide-details
            label="Đặt làm dashboard mặc định"
          />
        </div>
        <div class="wf-template-dialog__footer">
          <v-btn class="wf-btn" variant="outlined" color="primary" @click="isEditDialogOpen = false">Hủy</v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSaving" @click="saveDashboard">Lưu dashboard</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </uc-wf-shell>
</template>

<script>
	export default {
		name: "uc-report-dashboard-list-page",
  data: function () {
    return {
      isLoading: false,
      isSaving: false,
      isEditDialogOpen: false,
      editingDashboardId: 0,
      editingDashboardName: "",
      editingDashboardDefault: false,
      searchQuery: "",
      defaultFilter: "Tất cả",
      statusFilter: "Tất cả",
      dashboards: []
    };
  },
  computed: {
    defaultFilterOptions: function () {
      return ["Tất cả", "Mặc định", "Không mặc định"];
    },
    statusOptions: function () {
      return ["Tất cả", "Đang hoạt động", "Tạm ẩn"];
    },
    filteredDashboards: function () {
      var self = this;
      return (this.dashboards || []).filter(function (item) {
        var matchSearch = !self.searchQuery || String(item.name || "").toLowerCase().indexOf(String(self.searchQuery || "").toLowerCase()) >= 0;
        var matchDefault = self.defaultFilter === "Tất cả" || (self.defaultFilter === "Mặc định" ? item.isDefault : !item.isDefault);
        var matchStatus = self.statusFilter === "Tất cả" || item.status === self.statusFilter;
        return matchSearch && matchDefault && matchStatus;
      });
    },
    totalWidgetCount: function () {
      var total = 0;
      (this.dashboards || []).forEach(function (item) {
        total += Number(item.widgetCount || 0);
      });
      return total;
    },
    activeDashboardCount: function () {
      return (this.dashboards || []).filter(function (item) {
        return item.status === "Đang hoạt động";
      }).length;
    },
    defaultDashboardName: function () {
      var found = (this.dashboards || []).find(function (item) {
        return !!item.isDefault;
      });
      return found ? found.name : "-";
    }
  },
  mounted: function () {
    this.loadDashboards();
  },
  methods: {
    extractDashboardRows: function (resultSets) {
      if (!resultSets) {
        return [];
      }
      if (Array.isArray(resultSets)) {
        if (Array.isArray(resultSets[0])) {
          return resultSets[0];
        }
        if (resultSets[0] && typeof resultSets[0] === "object" && resultSets[0].ReportDashboardID !== undefined) {
          return resultSets;
        }
      }
      if (resultSets.data && Array.isArray(resultSets.data)) {
        if (Array.isArray(resultSets.data[0])) {
          return resultSets.data[0];
        }
        if (resultSets.data[0] && typeof resultSets.data[0] === "object" && resultSets.data[0].ReportDashboardID !== undefined) {
          return resultSets.data;
        }
      }
      return [];
    },
    loadDashboards: function () {
      var self = this;
      self.isLoading = true;
      apiCallAsync("WF_ReportDashboard_GetList", {}).then(function (resultSets) {
        var rows = self.extractDashboardRows(resultSets);
        self.dashboards = (rows || []).map(function (item) {
          return {
            id: Number(item.ReportDashboardID || 0),
            code: item.DashboardCode || "",
            name: item.DashboardName || "Dashboard",
            widgetCount: Number(item.WidgetCount || 0),
            isDefault: item.IsDefault === true || item.IsDefault === 1,
            status: item.IsActive === true || item.IsActive === 1 ? "Đang hoạt động" : "Tạm ẩn",
            updatedAt: self.formatDate(item.UpdateTime || item.CreateTime)
          };
        });
      }).catch(function () {
        self.dashboards = [];
        if (typeof showToast !== "undefined") {
          showToast.error("Không tải được danh sách dashboard.");
        }
      }).finally(function () {
        self.isLoading = false;
      });
    },
    formatDate: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (isNaN(dt.getTime())) return String(value);
      return dt.toLocaleString("vi-VN", { hour: "2-digit", minute: "2-digit", day: "2-digit", month: "2-digit" });
    },
    dashboardSubtitle: function (item) {
      return (item.code || "-") + " · " + String(item.widgetCount || 0) + " widget";
    },
    openCreateDialog: function () {
      this.editingDashboardId = 0;
      this.editingDashboardName = "Dashboard mới";
      this.editingDashboardDefault = !this.dashboards.length;
      this.isEditDialogOpen = true;
    },
    openEditDialog: function (item) {
      this.editingDashboardId = Number(item.id || 0);
      this.editingDashboardName = item.name || "";
      this.editingDashboardDefault = !!item.isDefault;
      this.isEditDialogOpen = true;
    },
    saveDashboard: function () {
      var self = this;
      self.isSaving = true;
      apiCallAsync("WF_ReportDashboard_Save", {
        ReportDashboardID: self.editingDashboardId || 0,
        DashboardName: self.editingDashboardName,
        IsDefault: self.editingDashboardDefault ? 1 : 0
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã lưu dashboard.");
        }
        self.isEditDialogOpen = false;
        self.loadDashboards();
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không lưu được dashboard.");
        }
      }).finally(function () {
        self.isSaving = false;
      });
    },
    setDefault: function (item) {
      var self = this;
      apiCallAsync("WF_ReportDashboard_SetDefault", {
        ReportDashboardID: item.id
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã đặt dashboard mặc định.");
        }
        self.loadDashboards();
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không đặt được dashboard mặc định.");
        }
      });
    },
    deleteDashboard: function (item) {
      var self = this;
      if (typeof showConfirm === "function") {
        showConfirm({
          title: "Xóa dashboard",
          message: "Dashboard này sẽ bị ẩn khỏi danh sách và không còn dùng được cho trình chiếu. Bạn có chắc muốn xóa?",
          onOk: function () {
            self.doDeleteDashboard(item);
          }
        });
        return;
      }
      self.doDeleteDashboard(item);
    },
    doDeleteDashboard: function (item) {
      var self = this;
      apiCallAsync("WF_ReportDashboard_Delete", {
        ReportDashboardID: item.id
      }).then(function (resultSets) {
        var row = resultSets && resultSets[0] && resultSets[0][0] ? resultSets[0][0] : null;
        if (typeof showToast !== "undefined") {
          showToast.success(row && row.Message ? row.Message : "Đã xóa dashboard.");
        }
        self.loadDashboards();
      }).catch(function (xhr) {
        if (typeof showToast !== "undefined") {
          showToast.error(xhr && xhr.responseJSON && xhr.responseJSON.Message ? xhr.responseJSON.Message : "Không xóa được dashboard.");
        }
      });
    },
    openDesigner: function (item) {
      window.location.href = "/wf-report-dashboard?id=" + String(item.id || 0);
    },
    openPresent: function (item) {
      window.location.href = "/wf-report-dashboard-view?id=" + String(item.id || 0);
    }
  }
	}
</script>