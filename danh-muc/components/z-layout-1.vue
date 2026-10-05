<template>
	<v-defaults-provider :defaults="DEFAULT_PROVIDER">
		<template v-if="!isMobile">
			<v-layout>
				<v-navigation-drawer :rail="isShow" permanent @click="isShow = false" :width="220">
					<template v-slot:prepend>
						<v-list density="compact">
							<v-list-item prepend-avatar="/_cdn/danh-muc/logo-2025.png" subtitle="Danh mục">
								<template v-slot:title><b>TÔ MINH</b></template>
								<template v-slot:append>
									<v-btn icon="mdi-chevron-left" variant="text" @click.stop="isShow = !isShow">
									</v-btn>
								</template>
							</v-list-item>
						</v-list>
					</template>
					<v-divider></v-divider>
					<v-list density="compact" nav v-model:opened="openGroups">
						<v-list-group v-for="group in menuItem" :key="group.key" :value="group.key" color="primary">
							<template v-slot:activator="{ props }">
								<v-list-item v-bind="props" :prepend-icon="group.icon" :title="group.title" />
							</template>
							<v-list-item v-for="menu in group.children" :href="menu.url" :key="menu.key"
								:active="isActive(menu.url)" :title="menu.title" color="primary" />
						</v-list-group>
					</v-list>
					<template v-slot:append>
						<v-list density="compact" class="border-t py-1">
							<v-list-item href="https://login.zentea.vn/" :title="vueData.user.UserName"
								:subtitle="vueData.user.UserID">
								<template v-slot:prepend>
									<v-icon icon="mdi-account"></v-icon>
								</template>
								<template v-slot:append>
									<v-icon icon="mdi-open-in-new"></v-icon>
								</template>
							</v-list-item>
						</v-list>
					</template>
				</v-navigation-drawer>
				<v-main class="main-content">
					<v-overlay :model-value="vueData.v_Set.isLoading" class="align-center justify-center" persistent>
						<div class="d-flex flex-column align-center justify-center">
							<v-progress-circular color="primary" indeterminate size="45"></v-progress-circular>
							<p class="mt-2">Đang xử lý dữ liệu</p>
						</div>
					</v-overlay>
					<slot></slot>
				</v-main>
			</v-layout>
		</template>
		<template v-else>
			<v-layout>
				<v-app-bar density="compact" elevation="1" color="primary">
					<v-app-bar-nav-icon @click="isShow = !isShow" />
					<span class="font-weight-bold">TÔ MINH - QUẢN LÝ DANH MỤC</span>
				</v-app-bar>
				<v-navigation-drawer v-model="isShow" temporary width="200">
					<v-list density="compact" nav v-model:opened="openGroups">
						<v-list-group v-for="group in menuItem" :key="group.key" :value="group.key" color="primary">
							<template v-slot:activator="{ props }">
								<v-list-item v-bind="props" :prepend-icon="group.icon" :title="group.title" />
							</template>
							<v-list-item v-for="menu in group.children" :href="menu.url" :key="menu.key"
								:active="isActive(menu.url)" :title="menu.title" color="primary" />
						</v-list-group>
					</v-list>
					<template v-slot:append>
						<v-list density="compact" class="border-t py-1">
							<v-list-item href="https://login.zentea.vn/" :title="vueData.user.UserName"
								:subtitle="vueData.user.UserID">
								<template v-slot:prepend>
									<v-icon icon="mdi-account"></v-icon>
								</template>
								<template v-slot:append>
									<v-icon icon="mdi-open-in-new"></v-icon>
								</template>
							</v-list-item>
						</v-list>
					</template>
				</v-navigation-drawer>
				<v-main class="pt-12">
					<v-overlay :model-value="vueData.v_Set.isLoading" class="align-center justify-center" persistent>
						<div class="d-flex flex-column align-center">
							<v-progress-circular indeterminate size="45" />
							<p class="mt-2">Đang xử lý dữ liệu</p>
						</div>
					</v-overlay>
					<slot></slot>
				</v-main>
			</v-layout>
		</template>
	</v-defaults-provider>
</template>
<script>
	export default {
		props: [],
		data() {
			return {
				DEFAULT_PROVIDER,
				vueData,
				isShow: false,
				openGroups: [],
				menuItem: [],
				legacyGroupConfig: {
					DANH_MUC: { title: 'Danh mục', icon: 'mdi-database-cog' },
					PHIEU: { title: 'Nhập xuất', icon: 'mdi-home-switch' },
					KHO: { title: 'Quản lý kho', icon: 'mdi-warehouse' },
					TAI_SAN: { title: 'Tài sản', icon: 'mdi-cupboard' },
					NGUYEN_LIEU: { title: 'Nguyên liệu', icon: 'mdi-food' },
					CONG_THUC: { title: 'Bảng công thức', icon: 'mdi-silverware-clean' },
					BANG_CONG_THUC: { title: 'Bảng công thức', icon: 'mdi-silverware-clean' },
					DE_XUAT: { title: 'Đề xuất', icon: 'mdi-lightbulb-outline' },
				},
				groupLabels: {
					HE_THONG: 'Hệ thống',
					DANH_MUC: 'Danh mục',
					KHO: 'Kho',
					PHIEU: 'Nhập xuất',
					BAO_CAO: 'Báo cáo',
					MUA_HANG: 'Mua hàng',
					CONG_THUC: 'Công thức',
					BANG_CONG_THUC: 'Bảng công thức',
					NGUYEN_LIEU: 'Nguyên liệu',
					TAI_SAN: 'Tài sản',
					DE_XUAT: 'Đề xuất',
				},
				groupOrderMap: {
					DANH_MUC: 1,
					PHIEU: 2,
					KHO: 3,
					TAI_SAN: 4,
					NGUYEN_LIEU: 5,
					CONG_THUC: 6,
					BANG_CONG_THUC: 6,
					DE_XUAT: 7,
					HE_THONG: 8,
				},
			}
		},
		async mounted() {
			await this.loadMenuByUser()
		},
		computed: {
			isMobile() {
				return this.$vuetify.display.smAndDown
			}
		},
		watch: {},
		methods: {
			getApiRows(result) {
				if (Array.isArray(result) && Array.isArray(result[0])) {
					return result[0]
				}
				return Array.isArray(result) ? result : []
			},
			normalizeText(value) {
				return (value || '').toString().trim().toLowerCase()
			},
			formatToken(value) {
				return (value || '')
					.toString()
					.replace(/([a-z])([A-Z])/g, '$1 $2')
					.replace(/[_-]+/g, ' ')
					.replace(/\s+/g, ' ')
					.trim()
					.replace(/\b\w/g, function (char) { return char.toUpperCase() })
			},
			getDescriptionInfo(quyen) {
				const moTa = (quyen && quyen.MoTa ? quyen.MoTa : '').toString().trim()
				if (!moTa) { return { groupLabel: '', pageLabel: '' } }
				const parts = moTa.split(' - ').map(function (item) { return item.trim() }).filter(function (item) { return !!item })
				if (parts.length >= 2) {
					return {
						groupLabel: parts[0],
						pageLabel: parts.slice(1).join(' - '),
					}
				}
				return {
					groupLabel: '',
					pageLabel: moTa,
				}
			},
			getGroupTitle(quyen, descriptionInfo) {
				const nhomQuyen = (quyen && quyen.NhomQuyen ? quyen.NhomQuyen : '').toString().trim()
				if (!nhomQuyen) { return 'Khác' }
				const rawGroupCode = this.normalizeText(nhomQuyen).replace(/-/g, '_').toUpperCase()
				if (this.legacyGroupConfig[rawGroupCode]) { return this.legacyGroupConfig[rawGroupCode].title }
				return this.groupLabels[rawGroupCode] || this.formatToken(nhomQuyen)
			},
			getPageTitle(quyen, descriptionInfo) {
				if (descriptionInfo.pageLabel) { return descriptionInfo.pageLabel }
	
				const pageUrl = (quyen && quyen.Page_Url ? quyen.Page_Url : '').toString().trim()
				const pageUrlToken = pageUrl.split('/').filter(function (item) { return !!item }).pop()
				if (pageUrlToken) { return this.formatToken(pageUrlToken) }
	
				const tenQuyen = (quyen && quyen.TenQuyen ? quyen.TenQuyen : '').toString().trim()
				if (!tenQuyen) { return 'Trang chưa đặt tên' }
				return tenQuyen
			},
			getGroupIcon(groupKey) {
				if (this.legacyGroupConfig[groupKey]) { return this.legacyGroupConfig[groupKey].icon }
				const iconMap = {
					HE_THONG: 'mdi-cog-outline',
					DANH_MUC: 'mdi-database-cog',
					KHO: 'mdi-warehouse',
					PHIEU: 'mdi-home-switch',
					BAO_CAO: 'mdi-chart-box-outline',
					MUA_HANG: 'mdi-cart-outline',
					CONG_THUC: 'mdi-silverware-clean',
					NGUYEN_LIEU: 'mdi-food',
					TAI_SAN: 'mdi-cupboard',
					DE_XUAT: 'mdi-lightbulb-outline',
					KHAC: 'mdi-shape-outline',
				}
				return iconMap[groupKey] || 'mdi-view-dashboard-outline'
			},
			mapPermissionFromApi(quyen) {
				return {
					Quyen_Id: quyen && quyen.Quyen_Id ? quyen.Quyen_Id : '',
					NhomQuyen: quyen && quyen.NhomQuyen ? quyen.NhomQuyen : '',
					TenQuyen: quyen && quyen.TenQuyen ? quyen.TenQuyen : '',
					MoTa: quyen && quyen.MoTa ? quyen.MoTa : '',
					Page_Url: quyen && quyen.Page_Url ? quyen.Page_Url : '',
					ThuTu: Number(quyen && quyen.ThuTu !== undefined ? quyen.ThuTu : 9999),
				}
			},
			buildMenuItems(rows) {
				const groupMap = {}
				const groupOrderMap = this.groupOrderMap
	
				rows.forEach(function (permission) {
					const quyen = this.mapPermissionFromApi(permission)
					const pageUrl = (quyen.Page_Url || '').toString().trim()
					if (!pageUrl) { return }
	
					const descriptionInfo = this.getDescriptionInfo(quyen)
					const groupKey = this.normalizeText(quyen.NhomQuyen).replace(/-/g, '_').toUpperCase() || 'KHAC'
					const groupTitle = this.getGroupTitle(quyen, descriptionInfo)
					const pageKey = this.normalizeText(pageUrl)
					const pageTitle = this.getPageTitle(quyen, descriptionInfo)
	
					if (!groupMap[groupKey]) {
						groupMap[groupKey] = {
							key: groupKey,
							title: groupTitle,
							icon: this.getGroupIcon(groupKey),
							order: quyen.ThuTu,
							childrenMap: {},
						}
					}
	
					if (quyen.ThuTu < groupMap[groupKey].order) {
						groupMap[groupKey].order = quyen.ThuTu
					}
	
					if (!groupMap[groupKey].childrenMap[pageKey]) {
						groupMap[groupKey].childrenMap[pageKey] = {
							key: pageKey,
							title: pageTitle,
							url: pageUrl,
							order: quyen.ThuTu,
						}
						return
					}
	
					const currentPage = groupMap[groupKey].childrenMap[pageKey]
					if (quyen.ThuTu < currentPage.order) {
						currentPage.order = quyen.ThuTu
						currentPage.title = pageTitle
					}
				}, this)
	
				return Object.values(groupMap)
					.map(function (group) {
						return {
							key: group.key,
							title: group.title,
							icon: group.icon,
							children: Object.values(group.childrenMap)
								.sort(function (left, right) {
									if (left.order !== right.order) { return left.order - right.order }
									return left.title.localeCompare(right.title)
								}),
							order: group.order,
						}
					})
					.filter(function (group) { return group.children.length > 0 })
					.sort(function (left, right) {
						const leftGroupOrder = groupOrderMap[left.key] || 9999
						const rightGroupOrder = groupOrderMap[right.key] || 9999
						if (leftGroupOrder !== rightGroupOrder) { return leftGroupOrder - rightGroupOrder }
						if (left.order !== right.order) { return left.order - right.order }
						return left.title.localeCompare(right.title)
					})
			},
			syncOpenGroups() {
				const path = window.location.pathname
				this.openGroups = this.menuItem
					.filter(function (group) {
						return group.children && group.children.some(function (menu) {
							return path.startsWith(menu.url)
						})
					})
					.map(function (group) { return group.key })
			},
			async loadMenuByUser() {
				try {
					const result = await apiCallPromise('work/HH_Quyen_Select_By_User_Id', {
						User_Id: this.vueData && this.vueData.user ? this.vueData.user.UserID : '',
					})
					this.menuItem = this.buildMenuItems(this.getApiRows(result))
					this.syncOpenGroups()
				} catch (error) {
					console.log(error)
					this.menuItem = []
					this.openGroups = []
				}
			},
			isActive(url) {
				//Active menu
				return window.location.pathname.startsWith(url)
			}
		},
	}
</script>