<template>
	<v-card class="rounded-sm elevation-1">
		<v-tabs v-model="activeTab" background-color="grey lighten-4" color="primary" grow>
			<v-tab class="font-weight-bold">
				<v-icon left>mdi-chart-bar</v-icon>
				Thống kê theo đơn vị
			</v-tab>
			<v-tab class="font-weight-bold green--text">
				<v-icon left color="success">mdi-account-check</v-icon>
				Giảng viên đạt nghĩa vụ
			</v-tab>
			<v-tab class="font-weight-bold red--text">
				<v-icon left color="error">mdi-account-alert</v-icon>
				Giảng viên chưa đạt
			</v-tab>
		</v-tabs>

		<v-window v-model="activeTab" class="pa-4">
			<!-- Tab Thống kê theo khoa -->
			<v-window-item style="max-height: calc(100vh - 360px); min-height: 300px; overflow-y: auto;">
				<f-table label="Bảng số liệu thống kê theo khoa" :headers="headerTableTheoKhoa"
				height="calc(100vh - 360px)"
					:items="ThongKeTheoKhoa" />
			</v-window-item>

			<!-- Tab Danh sách đạt -->
			<v-window-item style="max-height: calc(100vh - 360px); min-height: 300px; overflow-y: auto;">
				<f-table label="Danh sách giảng viên đạt nghĩa vụ NCKH" :headers="headerTableNhanVien" :items="dsDat"
					:items-per-page="15" />
			</v-window-item>

			<!-- Tab Danh sách không đạt -->
			<v-window-item style="max-height: calc(100vh - 360px); min-height: 300px; overflow-y: auto;">
				<f-table label="Danh sách giảng viên chưa đạt nghĩa vụ NCKH" :headers="headerTableNhanVien"
					:items="dsKhongDat" :items-per-page="15" />
			</v-window-item>
		</v-window>
	</v-card>
</template>

<script>
	export default {
		name: "uc-main-view",
	props: {
		ThongKeTheoKhoa: {
			type: Array,
			default: () => []
		},
		dsDat: {
			type: Array,
			default: () => []
		},
		dsKhongDat: {
			type: Array,
			default: () => []
		},
		headerTableTheoKhoa: {
			type: Array,
			default: () => []
		},
		headerTableNhanVien: {
			type: Array,
			default: () => []
		}
	},
	data() {
		return {
			activeTab: 0
		};
	}
	}
</script>