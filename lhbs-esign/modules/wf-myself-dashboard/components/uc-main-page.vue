<template>
	<uc-wf-shell title="Nhiệm vụ của tôi" subtitle="Hộp thư nhiệm vụ &amp; Tiến trình xử lý cá nhân">
    <!-- Header Page -->
    <div class="wf-page-header">
      <div>
        <h1>Danh sách nhiệm vụ cá nhân</h1>
        <p>Theo dõi các hồ sơ bạn phụ trách chính, các yêu cầu chờ bạn ký số và tiến độ duyệt của cấp trên.</p>
      </div>
      <div class="d-flex align-center" style="gap: 12px;">
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isLoading" @click="refreshDashboard">
          <v-icon start="">mdi-refresh</v-icon>
          Làm mới
        </v-btn>
      </div>
    </div>

    <!-- Stat Strip (Bộ lọc nhanh theo trạng thái) -->
    <div class="wf-stat-strip wf-stat-strip--5">
      <div class="wf-stat-pill" :class="{ active: filter === 'ALL' }" @click="setFilter('ALL')">
        <div class="wf-stat-icon wf-stat-icon--all">
          <v-icon>mdi-briefcase-outline</v-icon>
        </div>
        <div>
          <div class="wf-stat-val">{{ stats.all }}</div>
          <div class="wf-stat-lbl">Tất cả nhiệm vụ</div>
        </div>
      </div>
      <div class="wf-stat-pill" :class="{ active: filter === 'WAITING_ME' }" @click="setFilter('WAITING_ME')">
        <div class="wf-stat-icon wf-stat-icon--waiting">
          <v-icon>mdi-alert-decagram-outline</v-icon>
        </div>
        <div>
          <div class="wf-stat-val">{{ stats.waitingMe }}</div>
          <div class="wf-stat-lbl">Cần tôi xử lý</div>
        </div>
      </div>
      <div class="wf-stat-pill" :class="{ active: filter === 'RUNNING' }" @click="setFilter('RUNNING')">
        <div class="wf-stat-icon wf-stat-icon--running">
          <v-icon>mdi-progress-clock</v-icon>
        </div>
        <div>
          <div class="wf-stat-val">{{ stats.running }}</div>
          <div class="wf-stat-lbl">Đang thực hiện</div>
        </div>
      </div>
      <div class="wf-stat-pill" :class="{ active: filter === 'COMPLETED' }" @click="setFilter('COMPLETED')">
        <div class="wf-stat-icon wf-stat-icon--completed">
          <v-icon>mdi-check-all</v-icon>
        </div>
        <div>
          <div class="wf-stat-val">{{ stats.completed }}</div>
          <div class="wf-stat-lbl">Đã hoàn tất</div>
        </div>
      </div>
      <div class="wf-stat-pill" :class="{ active: filter === 'CANCELLED' }" @click="setFilter('CANCELLED')">
        <div class="wf-stat-icon wf-stat-icon--cancelled">
          <v-icon>mdi-close-circle-outline</v-icon>
        </div>
        <div>
          <div class="wf-stat-val">{{ stats.cancelled }}</div>
          <div class="wf-stat-lbl">Đã hủy bỏ</div>
        </div>
      </div>
    </div>

    <!-- Phân tích & Lọc nâng cao -->
    <div class="wf-tcard mb-4">
      <div class="wf-tcard-toolbar">
        <h3>Tổng hợp tiến độ theo Quy trình</h3>
        <v-spacer>
        <v-select v-model="workflowFilter" :items="workflowFilterOptions" item-title="title" item-value="value" density="compact" variant="outlined" hide-details="" class="wf-search-field" style="max-width: 280px;" label="Lọc theo loại quy trình">
      </v-select></v-spacer></div>

      <div class="wf-trow wf-trow-header" style="display:grid;grid-template-columns:minmax(220px,2fr) repeat(4,minmax(90px,1fr));gap:12px;align-items:center;">
        <div>Loại quy trình nghiệp vụ</div>
        <div class="text-center">Tổng số</div>
        <div class="text-center">Cần tôi xử lý</div>
        <div class="text-center">Đang chạy</div>
        <div class="text-center">Đã hoàn thành</div>
      </div>

      <div v-for="item in workflowSummaryRows" :key="'wf-summary-' + item.DefinitionName" class="wf-trow wf-dashboard-row" style="display:grid;grid-template-columns:minmax(220px,2fr) repeat(4,minmax(90px,1fr));gap:12px;align-items:center;" @click="applyWorkflowFilter(item.DefinitionName)">
        <div class="wf-dashboard-text" style="cursor:pointer;font-weight:600;color:#2f6fb3;">
          <v-icon size="16" class="mr-1">mdi-folder-outline</v-icon>
          {{ item.DefinitionName }}
        </div>
        <div class="wf-dashboard-strong text-center">{{ item.Total }}</div>
        <div class="text-center">
          <v-chip size="x-small" :color="item.WaitingMe > 0 ? '#c0841a' : '#6b7280'" variant="tonal" style="font-weight: 700;">
            {{ item.WaitingMe }}
          </v-chip>
        </div>
        <div class="text-center">
          <v-chip size="x-small" :color="item.Running > 0 ? '#2f6fb3' : '#6b7280'" variant="tonal">
            {{ item.Running }}
          </v-chip>
        </div>
        <div class="text-center">
          <v-chip size="x-small" :color="item.Completed > 0 ? '#217D46' : '#6b7280'" variant="tonal">
            {{ item.Completed }}
          </v-chip>
        </div>
      </div>

      <div v-if="!isLoading &amp;&amp; workflowSummaryRows.length === 0" class="wf-empty-state">
        Chưa có dữ liệu nhiệm vụ nào thuộc quy trình.
      </div>
    </div>

    <!-- Kanban board mini theo từng bước cho Quy trình được chọn -->
    <div class="wf-tcard mb-4" v-if="workflowFilter !== 'ALL'">
      <div class="wf-tcard-toolbar">
        <h3>Tiến độ Kanban: {{ workflowFilter }}</h3>
        <v-spacer>
        <div class="wf-dashboard-muted" style="font-size:12px;">
          Phân bổ hồ sơ theo từng giai đoạn xử lý
        </div>
      </v-spacer></div>

      <div class="wf-dashboard-kanban" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:14px;padding:12px 14px;">
        <div v-for="col in kanbanColumns" :key="'kb-col-' + col.key" class="wf-dashboard-kanban-col" :style="getKanbanColumnStyle(col)">
          <div class="wf-dashboard-kanban-head" :style="getKanbanColumnHeadStyle(col)">
            <div class="wf-dashboard-kanban-title" :style="getKanbanColumnTitleStyle(col)">
              {{ col.title }}
            </div>
            <v-chip size="x-small" :color="getKanbanColumnChipColor(col)" variant="tonal" :style="getKanbanCountChipStyle(col)">
              {{ col.items.length }}
            </v-chip>
          </div>

          <div v-if="col.items.length === 0" class="wf-dashboard-kanban-empty" style="padding:16px 12px;font-size:12px;color:#8a97a8;text-align:center;">
            Chưa có hồ sơ ở bước này.
          </div>

          <div v-for="item in col.items" :key="'kb-item-' + item.InstanceID" class="wf-dashboard-kanban-card" :style="getKanbanCardStyle(item)" @click="viewInstance(item)">
            <div class="wf-dashboard-kanban-card__name" style="font-size:13px;font-weight:700;color:#2c3e50;">
              {{ item.InstanceName }}
            </div>
            <div style="margin-top:6px;" class="d-flex ga-1 align-center flex-wrap">
              <v-chip size="x-small" :color="getStatusChipColor(item.Status)" variant="tonal" :style="getStatusChipStyle(item.Status)">
                {{ formatStatusText(item.Status) }}
              </v-chip>
              <v-chip v-if="item.AssigneeCode === currentUserID" size="x-small" color="blue" variant="flat" style="font-size:10px;height:18px;font-weight:bold;">
                Bạn phụ trách
              </v-chip>
            </div>

            <!-- Tỷ lệ hoàn thành Checklist tài liệu nếu có -->
            <div v-if="getChecklistProgress(item) !== null" class="mt-2">
              <div class="d-flex justify-between align-center" style="font-size:10px;color:#64748b;margin-bottom:2px;">
                <span>Tệp đính kèm bước</span>
                <span>{{ getChecklistProgressText(item) }}</span>
              </div>
              <v-progress-linear :model-value="getChecklistProgress(item)" color="success" height="4" rounded="">
            </v-progress-linear></div>

            <div class="d-flex justify-between align-center mt-3 pt-2" style="border-top: 1px dashed #e2e8f0; font-size:11px; color:#64748b;">
              <div>
                <v-icon size="12" class="mr-0.5">mdi-account-arrow-right</v-icon>
                Đang chờ: <strong>{{ item.NextSigner || '-' }}</strong>
              </div>
              <div style="color:#94a3b8;">
                {{ formatDate(item.UpdateTime || item.CreateTime) }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Danh sách chi tiết nhiệm vụ (Gom nhóm theo Quy trình) -->
    <div class="wf-tcard">
      <div class="wf-tcard-toolbar">
        <h3>Danh sách chi tiết nhiệm vụ ({{ filteredInstances.length }})</h3>
        <v-spacer>
        <v-text-field v-model="searchQuery" density="compact" prepend-inner-icon="mdi-magnify" variant="outlined" hide-details="" class="wf-search-field" style="max-width: 320px;" placeholder="Tìm tên hồ sơ, người xử lý...">
      </v-text-field></v-spacer></div>

      <!-- Header Grid tĩnh đại diện cho tiêu đề các cột -->
      <div class="wf-trow wf-trow-header wf-dashboard-grid" style="display:grid;grid-template-columns:1.8fr 1.2fr 1fr 1fr 1fr 1fr 60px;gap:12px;align-items:center;border-bottom: 2px solid #cbd5e1;">
        <div>Tên hồ sơ / Chi tiết</div>
        <div>Bước hiện tại</div>
        <div>Tài liệu bước</div>
        <div>PIC phụ trách</div>
        <div>Đang chờ sếp duyệt</div>
        <div class="text-center">Trạng thái</div>
        <div></div>
      </div>

      <!-- Hiển thị các Section Gom nhóm theo Quy trình nghiệp vụ -->
      <div v-for="group in groupedInstances" :key="'group-sec-' + group.name" class="wf-group-container">

        <!-- Group Header Toggle -->
        <div class="wf-group-header-row" @click="toggleGroup(group.name)">
          <div class="d-flex align-center ga-2">
            <v-icon class="wf-group-toggle-icon" :class="{ 'is-collapsed': !openedGroups[group.name] }">
              mdi-chevron-down
            </v-icon>
            <v-icon color="#2f6fb3" size="20">mdi-folder-text-outline</v-icon>
            <span class="wf-group-name">{{ group.name }}</span>
            <v-chip size="x-small" color="primary" variant="flat" class="font-weight-bold ml-2" style="height:18px;">
              {{ group.items.length }}
            </v-chip>
          </div>
          <div class="wf-group-line"></div>
        </div>

        <!-- Collapsible Content -->
        <v-expand-transition>
          <div v-show="openedGroups[group.name]" class="wf-group-body">
            <div v-for="item in group.items" :key="item.InstanceID" class="wf-trow wf-dashboard-grid wf-dashboard-row" style="display:grid;grid-template-columns:1.8fr 1.2fr 1fr 1fr 1fr 1fr 60px;gap:12px;align-items:center;border-top:none;border-bottom:1px solid #e2e8f0;padding:12px 16px;" @click="viewInstance(item)">
              <!-- Tên hồ sơ -->
              <div>
                <div class="wf-dashboard-name d-flex align-center ga-1" style="font-weight: 700; color: #1e293b; font-size:13px;">
                  <span>{{ item.InstanceName }}</span>
                  <v-chip v-if="item.Status === 'WAITING_ME'" size="x-small" color="deep-orange" variant="flat" style="font-size:9px;height:16px;font-weight:bold;">
                    <v-icon start="" size="9">mdi-file-sign</v-icon>Cần bạn xử lý
                  </v-chip>
                </div>
                <div class="wf-dashboard-sub" style="font-size:10px;color:#94a3b8;margin-top:2px;">
                  Khởi tạo: {{ formatDateTime(item.CreateTime) }}
                </div>
              </div>

              <!-- Bước hiện tại -->
              <div>
                <div class="wf-dashboard-text" style="font-weight:600;color:#334155;font-size:12.5px;">
                  {{ item.CurrentStepName || '-' }}
                </div>
                <div class="wf-dashboard-sub" style="font-size:10px;color:#94a3b8;">
                  Thứ tự bước: {{ item.CurrentStepOrder }}
                </div>
              </div>

              <!-- Tiến độ tệp đính kèm -->
              <div>
                <div v-if="getChecklistProgress(item) !== null">
                  <div class="d-flex align-center ga-2 mb-1">
                    <v-progress-linear :model-value="getChecklistProgress(item)" color="success" height="5" rounded="" style="max-width: 70px;">
                    <span style="font-size:11px;font-weight:bold;color:#1e293b;">{{ getChecklistProgressText(item)
                      }}</span>
                  </v-progress-linear></div>
                </div>
                <div v-else="" class="wf-dashboard-muted" style="font-size:11px;">
                  Không có tệp
                </div>
              </div>

              <!-- PIC Phụ trách -->
              <div>
                <div class="wf-dashboard-text" style="font-weight: 600; font-size:12px; color: #475569;">
                  {{ item.AssigneeName || '-' }}
                </div>
                <div v-if="item.AssigneeCode === currentUserID" style="font-size:10px;color:#2f6fb3;font-weight:bold;">
                  (Bạn phụ trách)
                </div>
              </div>

              <!-- Người chờ ký tiếp theo -->
              <div>
                <div class="wf-dashboard-text" style="font-weight: 600; font-size:12px; color: #b45309;">
                  {{ item.NextSigner || '-' }}
                </div>
              </div>

              <!-- Trạng thái -->
              <div class="text-center">
                <v-chip size="small" :color="getStatusChipColor(item.Status)" variant="tonal" :style="getStatusChipStyle(item.Status)" style="font-weight: 700; font-size:11px;">
                  {{ formatStatusText(item.Status) }}
                </v-chip>
              </div>

              <!-- Action -->
              <div class="d-flex align-center justify-end">
                <v-btn icon="mdi-chevron-right" variant="text" size="small" color="primary" @click.stop="viewInstance(item)">
              </v-btn></div>
            </div>
          </div>
        </v-expand-transition>
      </div>

      <!-- Empty State -->
      <div v-if="!isLoading &amp;&amp; filteredInstances.length === 0" class="wf-empty-state" style="padding:40px 0;">
        Không tìm thấy nhiệm vụ nào phù hợp với bộ lọc hiện tại.
      </div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      instances: [],
      currentUserID: "", // Sẽ tự động lấy từ phiên đăng nhập
      openedGroups: {}, // Lưu trạng thái collapsible của từng Group
      stats: {
        all: 0,
        waitingMe: 0,
        running: 0,
        completed: 0,
        cancelled: 0
      },
      isLoading: false,
      filter: "ALL",
      searchQuery: "",
      workflowFilter: "ALL"
    };
  },
  mounted: function () {
    this.initPage();
  },
  computed: {
    workflowFilterOptions: function () {
      var map = {};
      var items = [{ title: "Tất cả quy trình", value: "ALL" }];
      var i = 0;
      var name = "";
      for (i = 0; i < this.instances.length; i += 1) {
        name = String(this.instances[i].DefinitionName || "").trim() || "Khác";
        if (map[name]) continue;
        map[name] = true;
        items.push({ title: name, value: name });
      }
      return items;
    },
    workflowSummaryRows: function () {
      var map = {};
      var i = 0;
      var row = null;
      var key = "";
      var filtered = [];
      for (i = 0; i < this.instances.length; i += 1) {
        row = this.instances[i];
        key = String(row.DefinitionName || "").trim() || "Khác";
        if (!map[key]) {
          map[key] = { DefinitionName: key, Total: 0, WaitingMe: 0, Running: 0, Completed: 0 };
        }
        map[key].Total += 1;
        var status = String(row.Status || "").toUpperCase();
        if (status === "WAITING_ME") map[key].WaitingMe += 1;
        if (status === "RUNNING") map[key].Running += 1;
        if (status === "COMPLETED") map[key].Completed += 1;
      }
      for (key in map) {
        if (!Object.prototype.hasOwnProperty.call(map, key)) continue;
        if (this.workflowFilter === "ALL" || map[key].DefinitionName === this.workflowFilter) {
          filtered.push(map[key]);
        }
      }
      return filtered.sort(function (a, b) { return b.Total - a.Total; });
    },
    kanbanColumns: function () {
      var rows = this.instances.filter(function (item) {
        return this.workflowFilter !== "ALL" && String(item.DefinitionName || "").trim() === this.workflowFilter;
      }.bind(this));
      
      var map = {};
      var order = [];
      var i = 0;
      var colKey = "";
      var row = null;
      var output = [];
      
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i];
        var status = String(row.Status || "").toUpperCase();
        if (status === "COMPLETED") colKey = "Hoàn tất";
        else if (status === "CANCELLED") colKey = "Đã hủy";
        else colKey = String(row.CurrentStepName || "").trim() || "Bước không xác định";
        
        if (!map[colKey]) {
          map[colKey] = { key: colKey, title: colKey, items: [] };
          order.push(colKey);
        }
        map[colKey].items.push(row);
      }
      
      for (i = 0; i < order.length; i += 1) {
        output.push(map[order[i]]);
      }
      return output;
    },
    filteredInstances: function () {
      var filter = this.filter;
      var keyword = (this.searchQuery || "").toLowerCase().trim();
      
      return this.instances.filter(function (item) {
        var instanceName = String(item.InstanceName || "").toLowerCase();
        var definitionName = String(item.DefinitionName || "").toLowerCase();
        var nextSigner = String(item.NextSigner || "").toLowerCase();
        var assigneeName = String(item.AssigneeName || "").toLowerCase();
        
        var matchedKeyword = !keyword || 
                             instanceName.includes(keyword) || 
                             definitionName.includes(keyword) || 
                             nextSigner.includes(keyword) ||
                             assigneeName.includes(keyword);
                             
        if (!matchedKeyword) return false;
        if (this.workflowFilter !== "ALL" && String(item.DefinitionName || "").trim() !== this.workflowFilter) return false;
        if (filter === "ALL") return true;
        
        return String(item.Status || "").toUpperCase() === filter;
      }.bind(this)).sort(function (a, b) {
        var at = new Date(a.UpdateTime || a.CreateTime || 0).getTime();
        var bt = new Date(b.UpdateTime || b.CreateTime || 0).getTime();
        return bt - at;
      });
    },
    groupedInstances: function () {
      var groups = {};
      var order = [];
      var list = this.filteredInstances;
      var i = 0;
      var row = null;
      var key = "";
      
      for (i = 0; i < list.length; i += 1) {
        row = list[i];
        key = String(row.DefinitionName || "").trim() || "Khác";
        if (!groups[key]) {
          groups[key] = [];
          order.push(key);
        }
        groups[key].push(row);
      }
      
      var result = [];
      for (i = 0; i < order.length; i += 1) {
        result.push({
          name: order[i],
          items: groups[order[i]]
        });
      }
      return result;
    }
  },
  methods: {
    initPage: function () {
      if (window.sys_user && window.sys_user.EmployeeCode) {
        this.currentUserID = window.sys_user.EmployeeCode;
      } else if (window.localStorage && window.localStorage.getItem("EmployeeCode")) {
        this.currentUserID = window.localStorage.getItem("EmployeeCode");
      }
      this.refreshDashboard();
    },
    refreshDashboard: async function () {
      this.isLoading = true;
      try {
        await this.loadMyAssignedTasks();
        this.rebuildStats();
      } catch (err) {
        this.showError(err);
      } finally {
        this.isLoading = false;
      }
    },
    loadMyAssignedTasks: async function () {
      var rows = await apiCallAsync("WF_Instance_GetMyAssignedList", { Filter: "ALL" });
      var self = this;
      this.instances = (rows || []).map(function (item) {
        var checklist = [];
        try {
          if (item.ChecklistJSON) {
            checklist = JSON.parse(item.ChecklistJSON);
          }
        } catch (e) {
          checklist = [];
        }

        var defName = item.DefinitionName || "";
        // Mặc định tự động mở rộng nhóm mới khi tải dữ liệu
        var groupKey = String(defName).trim() || "Khác";
        if (self.openedGroups[groupKey] === undefined) {
          self.openedGroups[groupKey] = true;
        }

        return {
          InstanceID: item.InstanceID,
          InstanceName: item.InstanceName || "",
          DefinitionID: item.DefinitionID,
          DefinitionName: defName,
          CurrentStepOrder: item.CurrentStepOrder || 0,
          CurrentStepDefID: item.CurrentStepDefID || 0,
          CurrentStepName: item.CurrentStepName || "",
          Status: item.Status || "",
          CreateUser: item.CreateUser || "",
          CreateTime: item.CreateTime || "",
          UpdateTime: item.UpdateTime || "",
          Tag: item.Tag || "",
          AssigneeCode: item.AssigneeCode || "",
          AssigneeName: item.AssigneeName || "",
          NextSigner: item.NextSigner || "-",
          checklist: checklist
        };
      });
    },
    toggleGroup: function (name) {
      var key = String(name || "").trim() || "Khác";
      this.openedGroups[key] = !this.openedGroups[key];
    },
    rebuildStats: function () {
      var all = this.instances.length;
      var waitingMe = 0;
      var running = 0;
      var completed = 0;
      var cancelled = 0;
      
      var i = 0;
      for (i = 0; i < this.instances.length; i += 1) {
        var status = String(this.instances[i].Status || "").toUpperCase();
        if (status === "WAITING_ME") waitingMe += 1;
        else if (status === "RUNNING") running += 1;
        else if (status === "COMPLETED") completed += 1;
        else if (status === "CANCELLED") cancelled += 1;
      }
      
      this.stats.all = all;
      this.stats.waitingMe = waitingMe;
      this.stats.running = running;
      this.stats.completed = completed;
      this.stats.cancelled = cancelled;
    },
    setFilter: function (value) {
      this.filter = value;
    },
    applyWorkflowFilter: function (definitionName) {
      this.workflowFilter = String(definitionName || "").trim() || "ALL";
    },
    getChecklistProgress: function (item) {
      if (!item.checklist || item.checklist.length === 0) return null;
      var completed = item.checklist.filter(function (c) { return c.IsCompleted; }).length;
      return (completed / item.checklist.length) * 100;
    },
    getChecklistProgressText: function (item) {
      if (!item.checklist || item.checklist.length === 0) return "";
      var completed = item.checklist.filter(function (c) { return c.IsCompleted; }).length;
      return completed + "/" + item.checklist.length;
    },
    formatDateTime: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return value;
      var hh = String(dt.getHours()).padStart(2, "0");
      var mm = String(dt.getMinutes()).padStart(2, "0");
      var dd = String(dt.getDate()).padStart(2, "0");
      var mo = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = dt.getFullYear();
      return hh + ":" + mm + " " + dd + "/" + mo + "/" + yyyy;
    },
    formatDate: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return value;
      var dd = String(dt.getDate()).padStart(2, "0");
      var mo = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = dt.getFullYear();
      return dd + "/" + mo + "/" + yyyy;
    },
    formatStatusText: function (status) {
      var map = {
        RUNNING: "Đang chạy",
        WAITING_ME: "Chờ tôi ký",
        COMPLETED: "Hoàn tất",
        CANCELLED: "Đã hủy",
        REJECTED: "Từ chối"
      };
      if (map[status]) return map[status];
      return status || "";
    },
    getStatusChipColor: function (status) {
      var key = String(status || "").toUpperCase();
      if (key === "COMPLETED") return "#217D46";
      if (key === "WAITING_ME") return "#c0841a";
      if (key === "RUNNING") return "#2f6fb3";
      if (key === "REJECTED" || key === "CANCELLED") return "#c23a3a";
      return "primary";
    },
    getStatusTheme: function (status) {
      var key = String(status || "").toUpperCase();
      if (key === "COMPLETED") return { accent: "#2a9d5b", soft: "#f2fbf5", muted: "#2a7a4a", bg: "#fbfefc" };
      if (key === "WAITING_ME") return { accent: "#d9a441", soft: "#fffaf0", muted: "#9a6b15", bg: "#fffdf8" };
      if (key === "RUNNING") return { accent: "#5b8fd6", soft: "#f3f8ff", muted: "#3d67a6", bg: "#fcfdff" };
      if (key === "REJECTED" || key === "CANCELLED") return { accent: "#e07a7a", soft: "#fff5f5", muted: "#ad4c4c", bg: "#fffdfd" };
      return { accent: "#9aa5b1", soft: "#f6f8fb", muted: "#5f6b7a", bg: "#fdfefe" };
    },
    getStatusChipStyle: function (status) {
      var theme = this.getStatusTheme(status);
      return {
        color: theme.muted,
        backgroundColor: theme.soft,
        border: "1px solid " + theme.accent + "40",
        fontWeight: "600"
      };
    },
    getKanbanColumnChipColor: function (col) {
      var status = this.resolveKanbanColumnStatus(col);
      return this.getStatusChipColor(status);
    },
    getKanbanCountChipStyle: function (col) {
      var theme = this.getStatusTheme(this.resolveKanbanColumnStatus(col));
      return {
        backgroundColor: theme.soft,
        color: theme.muted,
        border: "1px solid " + theme.accent + "40",
        fontWeight: "700"
      };
    },
    getKanbanColumnStyle: function (col) {
      var theme = this.getStatusTheme(this.resolveKanbanColumnStatus(col));
      return {
        border: "1px solid " + theme.accent + "36",
        borderTop: "3px solid " + theme.accent,
        borderRadius: "8px",
        background: theme.bg,
        minHeight: "120px"
      };
    },
    getKanbanColumnHeadStyle: function (col) {
      var theme = this.getStatusTheme(this.resolveKanbanColumnStatus(col));
      return {
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        gap: "8px",
        padding: "10px 10px 8px",
        borderBottom: "1px solid #e3e7ee",
        background: "linear-gradient(180deg, " + theme.soft + " 0%, #ffffff00 100%)"
      };
    },
    getKanbanColumnTitleStyle: function (col) {
      var theme = this.getStatusTheme(this.resolveKanbanColumnStatus(col));
      return {
        fontSize: "13px",
        fontWeight: "700",
        color: theme.muted
      };
    },
    resolveKanbanColumnStatus: function (col) {
      var title = String(col && col.title ? col.title : "").toLowerCase();
      var items = col && col.items ? col.items : [];
      var hasWaiting = false;
      var hasRunning = false;
      var hasCompleted = false;
      var i = 0;
      var status = "";
      if (title.indexOf("hoàn tất") >= 0) return "COMPLETED";
      if (title.indexOf("đã hủy") >= 0) return "CANCELLED";
      for (i = 0; i < items.length; i += 1) {
        status = String(items[i].Status || "").toUpperCase();
        if (status === "WAITING_ME") hasWaiting = true;
        else if (status === "RUNNING") hasRunning = true;
        else if (status === "COMPLETED") hasCompleted = true;
      }
      if (hasWaiting) return "WAITING_ME";
      if (hasRunning) return "RUNNING";
      if (hasCompleted) return "COMPLETED";
      return "RUNNING";
    },
    getKanbanCardStyle: function (item) {
      var theme = this.getStatusTheme(item && item.Status ? item.Status : "");
      return {
        margin: "8px",
        padding: "12px 10px",
        border: "1px solid " + theme.accent + "2f",
        borderLeft: "4px solid " + theme.accent,
        borderRadius: "6px",
        background: "#ffffff",
        cursor: "pointer",
        transition: "transform 0.15s ease-in-out, box-shadow 0.15s ease-in-out",
        boxShadow: "0 1px 3px rgba(15,23,42,0.06)"
      };
    },

    viewInstance: function (item) {
      if (!item || !item.InstanceID) return;
      if (item.Status === "WAITING_ME") {
        window.location.href = "/wf-user-request-detail?id=" + item.InstanceID;
      } else {
        window.location.href = "/wf-kanban-flow-detail?id=" + item.InstanceID;
      }
    },
    showError: function (err) {
      var message = "";
      if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message;
      else if (err && err.responseText) message = err.responseText;
      else if (err && err.message) message = err.message;
      else message = "Không tải được dữ liệu nhiệm vụ cá nhân.";
      if (showToast && showToast.error) {
        showToast.error(message);
      }
    }
  }
	}
</script>