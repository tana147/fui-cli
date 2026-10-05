<template>
	<v-list>
		<v-list-subheader style="padding: 0px 8px !important;">Các tính năng khác</v-list-subheader>

		<v-list-item class="px-2" prepend-icon="mdi-calendar-month" title="Thời khóa biểu"
			@click="onOpenThoiKhoaBieu" />
		<v-divider />
		<v-list-item class="px-2" prepend-icon="mdi-book-education-outline" @click="onOpenHocLieuSo">
			Học liệu số
		</v-list-item>
		<v-divider />
		<v-list-item class="px-2" prepend-icon="mdi-trophy-outline" @click="onOpenThanhTich">
			Thành tích
		</v-list-item>
		<v-divider />
		<v-list-item class="text-red px-2" prepend-icon="mdi-login" @click="onLogout">
			Đăng xuất
		</v-list-item>
	</v-list>
</template>

<script>
	export default {
		name: "uc-ca-nhan-mobile-menu",
		props: {
			HocSinh: Object,
			NienKhoa: Number
		},
		methods: {
			onLogout() {
				redirect("https://login.lhbs.vn/")
			},
			onOpenHocLieuSo() {
				openWindow({
					title: "Học liệu số",
					url: `/kham-pha?capid=${this.HocSinh?.CapID}&khoiid=${this.HocSinh?.KhoiID}`
				})
			},
			onOpenThoiKhoaBieu() {
				// Mở trực tiếp module Thời khóa biểu theo HocSinhID của học sinh
				openWindow({
					title: "Thời khóa biểu",
					url: `/thoi-khoa-bieu?HocSinhID=${this.HocSinh?.HocSinhID}`
				})
			},
			onOpenThanhTich() { }
		}
	}
</script>