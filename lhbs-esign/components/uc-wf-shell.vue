<template>
	<div class="wf-shell" :class="{ 'wf-shell--sidebar-collapsed': isSidebarCollapsed }">
		<div class="wf-sidebar" :class="{ 'wf-sidebar--collapsed': isSidebarCollapsed }">
			<div class="wf-sidebar-header" :class="{ 'wf-sidebar-header--collapsed': isSidebarCollapsed }">
				<template v-if="!isSidebarCollapsed">
					<div class="wf-shell-logo">
						<img v-if="logoSrc" :src="logoSrc" alt="LHBS" class="wf-shell-logo__img">
						<div v-else class="wf-avatar wf-avatar--lg"
							style="background: var(--wf-primary-light); color: var(--wf-primary);">LH</div>
					</div>
					<div style="flex:1;min-width:0;">
						<h2>{{ title }}</h2>
						<small>{{ subtitle }}</small>
					</div>
					<v-btn class="wf-shell-toggle" icon size="small" variant="text" color="default"
						@click="toggleSidebar">
						<v-icon size="18">mdi-chevron-left</v-icon>
					</v-btn>
				</template>
				<template v-else>
					<v-btn icon size="small" variant="text" color="default" style="margin:0 auto;"
						@click="toggleSidebar">
						<v-icon size="18">mdi-chevron-right</v-icon>
					</v-btn>
				</template>
			</div>

			<div class="wf-nav-section">
				<!-- Tổng quan -->
				<div v-for="item in overviewItems" :key="item.key" class="wf-nav-item"
					:class="{ active: activeKey === item.key, 'wf-nav-item--collapsed': isSidebarCollapsed }"
					@click="handleNavigate(item)">
					<v-icon size="16">{{ item.icon }}</v-icon>
					<span v-if="!isSidebarCollapsed">{{ item.label }}</span>
				</div>

				<!-- Quản trị -->
				<div v-if="!isSidebarCollapsed" class="wf-nav-label">Quản trị</div>
				<div v-if="isSidebarCollapsed" class="wf-nav-divider"></div>
				<div v-for="item in adminItems" :key="item.key" class="wf-nav-item"
					:class="{ active: activeKey === item.key, 'wf-nav-item--collapsed': isSidebarCollapsed }"
					@click="handleNavigate(item)">
					<v-icon size="16">{{ item.icon }}</v-icon>
					<span v-if="!isSidebarCollapsed">{{ item.label }}</span>
					<span v-if="item.badge && !isSidebarCollapsed" class="wf-nav-badge" :class="item.badgeClass">{{
						item.badge }}</span>
				</div>

				<!-- Cá nhân -->
				<div v-if="!isSidebarCollapsed" class="wf-nav-label">Cá nhân</div>
				<div v-if="isSidebarCollapsed" class="wf-nav-divider"></div>
				<div v-for="item in userItems" :key="item.key" class="wf-nav-item"
					:class="{ active: activeKey === item.key, 'wf-nav-item--collapsed': isSidebarCollapsed }"
					@click="handleNavigate(item)">
					<v-icon size="16">{{ item.icon }}</v-icon>
					<span v-if="!isSidebarCollapsed">{{ item.label }}</span>
				</div>
			</div>

			<div class="wf-sidebar-footer">
				<div class="wf-avatar wf-avatar--md" style="background:#0b6e4f;color:#fff;">IT</div>
				<div v-if="!isSidebarCollapsed" style="flex:1;min-width:0;">
					<div style="font-size:12px;font-weight:600;color:var(--wf-text-1);">{{vueData.user?.UserID}}</div>
					<div style="font-size:11px;color:var(--wf-text-3);">{{vueData.user?.FirstName}}
						{{vueData.user?.LastName}}</div>
				</div>
				<!-- <uc-notification-dropdown v-if="!isSidebarCollapsed" /> -->
				<v-btn v-if="!isSidebarCollapsed" icon size="x-small" variant="text" color="default" style="opacity:.6;"
					title="Đăng xuất" @click="handleLogout">
					<v-icon size="16">mdi-logout</v-icon>
				</v-btn>
			</div>
		</div>

		<div class="wf-main">
			<slot />
		</div>
	</div>
</template>

<script>
	export default {
		props: {
			title: { type: String, default: "LHBS Workflow" },
			subtitle: { type: String, default: "Luồng công việc" },
			logoSrc: { type: String, default: "/_cdn/security-manager/SongNgu_logo.png" },
			showUserSection: { type: Boolean, default: true }
		},
		data: function () {
			return {
				vueData,
				activeKey: "",
				isSidebarCollapsed: false
			};
		},
		mounted: function () {
			this.activeKey = this.resolveActiveKey();
		},
		computed: {
			overviewItems: function () {
				return [
					// { key: "wf-space",         label: "Project",            icon: "mdi-view-grid-outline",   path: "/wf-space" },
					// { key: "wf-search",        label: "Tìm kiếm toàn cục", icon: "mdi-magnify",             path: "/wf-search" },
					// { key: "wf-space-reports", label: "Báo cáo",            icon: "mdi-chart-bar",           path: "/wf-space-reports" },
					{ key: "wf-kanban-flow",   label: "Kanban quy trình",   icon: "mdi-view-column-outline", path: "/wf-kanban-flow" },
				];
			},
			adminItems: function () {
				return [
					{ key: "wf-admin-workflow-list", label: "Thiết kế quy trình", icon: "mdi-vector-polyline-edit", path: "/wf-admin-workflow-list" },
					{ key: "wf-admin-category", label: "Nhóm quy trình", icon: "mdi-shape-outline", path: "/wf-admin-category" },
					{ key: "wf-admin-templates", label: "Mẫu văn bản", icon: "mdi-file-document-outline", path: "/wf-admin-templates" },
					{ key: "wf-admin-roles", label: "Phân quyền", icon: "mdi-account-key-outline", path: "/wf-admin-roles" },
					{ key: "wf-admin-signer-directory", label: "Thư mục người dùng", icon: "mdi-card-account-details-outline", path: "/wf-admin-signer-directory" },
				];
			},
			systemItems: function () {
				return [
					{ key: "settings", label: "Cài đặt chung", icon: "mdi-cog-outline", path: "/settings" },
					{ key: "wf-admin-audit-log", label: "Audit Log", icon: "mdi-history", path: "/wf-admin-audit-log" }
				];
			},
			reportItems: function () {
				return [
					{ key: "wf-report-dashboard-list", label: "Quản lý dashboard", icon: "mdi-view-dashboard-edit-outline", badge: "P1", badgeClass: "wf-nav-badge--accent", path: "/wf-report-dashboard-list" },
					{ key: "wf-report-dashboard", label: "Thiết kế dashboard", icon: "mdi-chart-box-outline", path: "/wf-report-dashboard" },
					{ key: "wf-report-dashboard-view", label: "Trình chiếu dashboard", icon: "mdi-presentation-play", path: "/wf-report-dashboard-view" },
					{ key: "wf-report-builder", label: "Thiết kế widget", icon: "mdi-tune-variant", path: "/wf-report-builder" },
					{ key: "wf-report-my-reports", label: "Thư viện widget", icon: "mdi-file-chart-outline", path: "/wf-report-my-reports" },
					{ key: "wf-report-dataset", label: "Nguồn dữ liệu", icon: "mdi-database-outline", path: "/wf-report-dataset" }
				];
			},
			userItems: function () {
				return [
					{ key: "ks-dashboard-ky", label: "Bảng ký của tôi", icon: "mdi-file-sign", path: "/ks-dashboard-ky" },
					{ key: "ks-vanban-cua-toi", label: "Văn bản của tôi", icon: "mdi-folder-account-outline", path: "/ks-vanban-cua-toi" },
					{ key: "ks-vanban-cho-ky", label: "Văn bản chờ ký", icon: "mdi-file-clock-outline", path: "/ks-vanban-cho-ky" },
					{ key: "ks-vanban-da-ky", label: "Văn bản đã ký", icon: "mdi-file-check-outline", path: "/ks-vanban-da-ky" },
					{ key: "wf-myself-dashboard", label: "Nhiệm vụ của tôi", icon: "mdi-view-dashboard-outline", path: "/wf-myself-dashboard" },
					{ key: "wf-user-request-create", label: "Tạo yêu cầu ký", icon: "mdi-file-plus-outline", path: "/wf-user-request-create" },
					{ key: "wf-user-sign-config", label: "Cấu hình chữ ký", icon: "mdi-draw-pen", path: "/wf-user-sign-config" },
				];
			}
		},
		methods: {
			resolveActiveKey: function () {
				var path = window.location.pathname || "";
				if (!path || path === "/") return "";
				return path.replace(/^\//, "").split("/")[0];
			},
			handleNavigate: function (item) {
				if (!item) return;
				var target = item.path || (item.key ? "/" + item.key : "");
				if (!target) return;
				window.location.href = target;
			},
			toggleSidebar: function () {
				this.isSidebarCollapsed = !this.isSidebarCollapsed;
			},
			handleLogout: function () {
				redirect('https://login.lhbs.vn/');
			}
		}
	}
</script>