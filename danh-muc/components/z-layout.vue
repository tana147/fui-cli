<template>
	<v-defaults-provider :defaults="DEFAULT_PROVIDER">
		<template v-if="!isMobile">
			<v-layout>
				<v-navigation-drawer :rail="isShow" permanent @click="isShow = false" :width="220">
					<template v-slot:prepend>
						<v-list density="compact">
							<v-list-item prepend-avatar="/_cdn/danh-muc/logo-2025.png" subtitle="Danh mục">
								<template v-slot:title><b>TÔ MINH</b></template>
								<template v-slot:append><v-btn icon="mdi-chevron-left" variant="text"
										@click.stop="isShow = !isShow"></v-btn></template>
							</v-list-item>
						</v-list>
					</template>
					<v-divider></v-divider>
					<v-list density="compact" nav v-model:opened="openGroups">
						<v-list-group v-for="group in menuItem" :value="group.key" color="primary">
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
						<v-list-group v-for="group in menuItem" :value="group.key" color="primary">
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
			const menuItem = [
				{
					key: "DANH_MUC",
					title: "Danh mục",
					icon: "mdi-database-cog",
					children: [
						{ key: "quan-ly-dia-diem", title: "Địa điểm", url: "/HH-dia-diem" },
						{ key: "quan-ly-khu-vuc", title: "Khu vực", url: "/HH-khu-vuc" },
						{ key: "quan-ly-phan-loai-nha-cung-cap", title: "Nhóm nhà cung cấp", url: "/HH-PhanLoaiNCC" },
						{ key: "quan-ly-nha-cung-cap", title: "Nhà cung cấp", url: "/HH-NhaCungCap" },
						{ key: "quan-ly-don-vi-tinh", title: "Đơn vị tính", url: "/HH-don-vi-tinh" },
						{ key: "quan-ly-phan-loai-tinh-chat", title: "Nhóm tính chất", url: "/HH-PhanLoaiTinhChat" },
						{ key: "quan-ly-phan-loai-vat-tu", title: "Nhóm vật tư", url: "/HH-PhanLoaiNhomVatTu" },
						{ key: "quan-ly-phan-loai-nhom-san-pham", title: "Nhóm hàng hóa", url: "/HH-PhanLoaiNhomSanPham" },
					],
				},
				{
					key: "PHIEU",
					title: "Nhập xuất",
					icon: "mdi-home-switch",
					children: [
						{ key: "quan-ly-phieu-nhap", title: "Phiếu nhập", url: "/HH-QuanLyPhieuNhap" },
						{ key: "quan-ly-phieu-xuat", title: "Phiếu xuất", url: "/HH-QuanLyPhieuXuat" },
					],
				},
				{
					key: "KHO",
					title: "Quản lý kho",
					icon: "mdi-warehouse",
					children: [
						{ key: "quan-ly-kho", title: "Quản lý kho", url: "/HH-QuanLyKho" },
						{ key: "quan-ly-kho-dia-diem", title: "Kho - Địa điểm", url: "/HH-Kho-DiaDiem" },
						{ key: "quan-ly-phieu-dinh-ki", title: "Phiếu định kì", url: "/HH-PhieuDinhKi" },
						{ key: "kiem-ke", title: "Kiểm kê", url: "/HH-KiemKe" },
						{ key: "bang-ton-kho", title: "Bảng tồn kho", url: "/HH-BangTonKho" },
					],
				},
				{
					key: "TAI_SAN",
					title: "Tài sản",
					icon: "mdi-cupboard",
					children: [
						{ key: "quan-ly-tbdc", title: "Quản lý tài sản", url: "/TBDC-CCDC" },
						{ key: "quan-ly-lich-dinh-ki", title: "Quản lý lịch định kì", url: "/TBDC-LichDinhKi" },
						{ key: "quan-ly-bao-tri", title: "Quản lý đợt bảo trì", url: "/TBDC-QuanLyDotBaoTri" },
						{ key: "bao-tri", title: "Bảo trì", url: "/TBDC-BaoTri" },
						{ key: "quan-ly-bao-sua", title: "Quản lý báo sửa", url: "/TBDC-QuanLyBaoSua" },
						{ key: "bao-sua", title: "Báo sửa", url: "/TBDC-BaoSua" },
						{ key: "in-ma-vach", title: "In mã vạch", url: "/TBDC-InMaVach" },
					]
				},
				{
					key: "NGUYEN_LIEU",
					title: "Nguyên liệu",
					icon: "mdi-food",
					children: [
						{ key: "quan-ly-nguyen-lieu", title: "Quản lý nguyên liệu", url: "/NL-quan-ly-nguyen-lieu" },
					],
				},
				{
					key: "CONG_THUC",
					title: "Bảng công thức",
					icon: "mdi-silverware-clean",
					children: [
						{ key: "quan-ly-bang-cong-thuc", title: "Bảng công thức", url: "/BCT-quan-ly-bang-cong-thuc" }],
				},
				{
					key: "DE_XUAT",
					title: "Đề xuất",
					icon: "mdi-lightbulb-outline",
					children: [
						{ key: "de-xuat", title: "Đề xuất", url: "/DX-mua-hang" },
						{ key: "cau-hinh-de-xuat", title: "Cấu hình", url: "/DX-cau-hinh" },
						{ key: "tong-hop-de-xuat", title: "Tổng hợp đề xuất", url: "/HH-TongHopDeXuat" },
					]
				}
			]
			//Xử lý active menu group
			const path = window.location.pathname
			const openGroups = menuItem
				.filter(group => group.children?.some(m => path.startsWith(m.url)))
				.map(group => group.key)
	
			return {
				DEFAULT_PROVIDER,
				vueData,
				isShow: false,
				openGroups,
				menuItem,
			}
		},
		mounted() { },
		computed: {
			isMobile() {
				return this.$vuetify.display.smAndDown
			}
		},
		watch: {},
		methods: {
			isActive(url) {
				//Active menu
				return window.location.pathname.startsWith(url)
			}
		},
	}
</script>