<template>
	<uc-wf-shell :show-user-section="false">
  <div class="wf-page-header">
    <div>
      <h1>Người dùng nội bộ</h1>
      <p>Quản lý hồ sơ người dùng ký số SmartCA: thông tin cá nhân, chứng thư số và trạng thái hiệu lực.</p>
    </div>
    <div class="d-flex ga-2">
      <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isLoading" @click="loadRows">
        <v-icon start>mdi-refresh</v-icon>Làm mới
      </v-btn>
      <v-btn class="wf-btn" variant="outlined" color="primary" @click="goDetail(0)">
        <v-icon start>mdi-plus</v-icon>Thêm người dùng
      </v-btn>
    </div>
  </div>
  <uc-table
    title="Danh sách"
    :show-count="true"
    :headers="signerHeaders"
    :items="filteredRows"
    :loading="isLoading"
    item-value="UserID"
    searchable
    search-placeholder="Tìm theo tên, email, serial..."
    max-height="calc(100vh - 210px)"
    :pagination="true"
    :items-per-page="10">
    <template #item.user="{ item }">
      <div class="wf-audit-title">{{ item.FullName || '-' }}</div>
      <div class="wf-audit-sub">{{ item.Email || '-' }}</div>
    </template>
    <template #item.code="{ item }">
      <span class="wf-audit-meta">{{ item.EmployeeCode || '-' }}</span>
    </template>
    <template #item.dept="{ item }">
      <div class="wf-audit-title">{{ item.DepartmentName || '-' }}</div>
      <div class="wf-audit-sub">{{ item.JobTitle || '-' }}</div>
    </template>
    <template #item.cert="{ item }">
      <div class="wf-audit-title">{{ item.CertSerial || '-' }}</div>
      <div class="wf-audit-sub">{{ item.CertIssuer || '-' }}</div>
    </template>
    <template #item.validity="{ item }">
      <span class="wf-audit-meta">{{ formatValidity(item) }}</span>
    </template>
    <template #item.status="{ item }">
      <v-chip size="x-small" :color="item.IsActive ? '#217D46' : '#6f7f8c'" variant="tonal">{{ item.IsActive ? 'Đang dùng' : 'Tạm dừng' }}</v-chip>
      <v-chip size="x-small" class="ml-1" :color="item.CertIsActive ? '#217D46' : '#c23a3a'" variant="outlined">{{ item.CertIsActive ? 'CTS active' : 'CTS off' }}</v-chip>
    </template>
    <template #item.actions="{ item }">
      <div class="d-flex ga-1">
        <v-btn icon size="x-small" variant="text" color="primary" @click.stop="goDetail(item.UserID)"><v-icon size="14">mdi-pencil-outline</v-icon></v-btn>
        <v-btn icon size="x-small" variant="text" color="primary" :disabled="isDeleting" @click.stop="removeRow(item)"><v-icon size="14" class="wf-icon-danger">mdi-delete-outline</v-icon></v-btn>
      </div>
    </template>
  </uc-table>
</uc-wf-shell>
</template>

<script>
	export default {
		props: [],
		data: function () {
			return {
			isLoading: false,
			isDeleting: false,
			keyword: "",
			rows: [],
			signerHeaders: [
				{ title: 'Người dùng', key: 'user', width: '1.2fr' },
				{ title: 'Mã NV', key: 'code', width: '120px' },
				{ title: 'Đơn vị / chức vụ', key: 'dept' },
				{ title: 'Chứng thư số', key: 'cert' },
				{ title: 'Hiệu lực', key: 'validity', width: '170px' },
				{ title: 'Trạng thái', key: 'status', width: '170px' },
				{ title: '', key: 'actions', width: '70px' }
			]
			};
		},
		mounted: function () {
			this.loadRows();
		},
		computed: {
			filteredRows: function () {
			var q = (this.keyword || "").toLowerCase().trim();
			if (!q) return this.rows;
			return (this.rows || []).filter(function (item) {
				return (item.FullName || "").toLowerCase().indexOf(q) >= 0
				|| (item.Email || "").toLowerCase().indexOf(q) >= 0
				|| (item.EmployeeCode || "").toLowerCase().indexOf(q) >= 0
				|| (item.CertSerial || "").toLowerCase().indexOf(q) >= 0
				|| (item.CertIssuer || "").toLowerCase().indexOf(q) >= 0;
			});
			}
		},
		methods: {
			loadRows: async function () {
			this.isLoading = true;
			try {
				var rows = await apiCallAsync("WF_User_GetList", { Keyword: (this.keyword || "").trim(), OnlyActive: false });
				this.rows = Array.isArray(rows) ? rows : [];
			} catch (err) {
				this.showError(err, "Không tải được danh sách người dùng.");
			} finally {
				this.isLoading = false;
			}
			},
			formatDate: function (value) {
			if (!value) return "-";
			var dt = new Date(value);
			if (Number.isNaN(dt.getTime())) return String(value);
			var dd = String(dt.getDate()).padStart(2, "0");
			var mm = String(dt.getMonth() + 1).padStart(2, "0");
			var yyyy = dt.getFullYear();
			return dd + "/" + mm + "/" + yyyy;
			},
			formatValidity: function (item) {
			var fromText = this.formatDate(item ? item.CertValidFrom : null);
			var toText = this.formatDate(item ? item.CertValidTo : null);
			if (fromText === "-" && toText === "-") return "-";
			return fromText + " - " + toText;
			},
			goDetail: function (id) {
			window.location.href = "/wf-admin-signer-detail?id=" + Number(id || 0);
			},
			removeRow: function (item) {
			var self = this;
			if (!item || !item.UserID) return;
			showConfirm('Xóa hồ sơ "' + (item.FullName || "") + '"?', function () {
				self.isDeleting = true;
				apiCall("WF_User_Delete", { UserID: item.UserID }, function (res) {
				var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
				if (showToast && showToast.success) showToast.success(row && row.Message ? row.Message : "Đã xóa hồ sơ.");
				self.loadRows().finally(function () { self.isDeleting = false; });
				}, function (err) {
				self.showError(err, "Không xóa được hồ sơ.");
				self.isDeleting = false;
				});
			});
			},
			showError: function (err, fallback) {
			var message = "";
			if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message;
			else if (err && err.responseText) message = err.responseText;
			else if (err && err.message) message = err.message;
			else message = fallback || "Có lỗi xảy ra.";
			if (showToast && showToast.error) showToast.error(message);
			}
		}
	}
</script>