<template>
	<div>
		<h3 class="text-primary mb-2 mt-2 font-weight-bold">
			IV. Các đề tài đã tham gia:
		</h3>
		<f-table :items="QuaTrinhDaoTao" :headers="headers" :update-form="updateForm" :update-api="updateApi"
			:excel="false" dense></f-table>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData,
				QuaTrinhDaoTao: vueData.userProfile[3] ?? {},
				headers: [
					{ "title": "Tên đề tài", "value": "TenDeTai", "align": "left" },
					{ "title": "Cơ quan tài trợ", "value": "CoQuanTaiTro", "align": "left" },
					{ "title": "Vai trò", "value": "VaiTro", "align": "center" },
					{ "title": "Thời gian thực hiện", "value": "ThoiGianThucHien", "align": "center" },
					{ "title": "Chức năng", "value": "ctrl-update", "align": "center" }
				],
				updateForm: [
					{
						el: "v-text-field",
						attr: {
							"v-model": "TenDeTai",
							"label": "Tên đề tài",
							":rules": "[vueData.rules.required]"
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "CoQuanTaiTro",
							"label": "Cơ quan tài trợ",
							":rules": "[vueData.rules.required]"
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "VaiTro",
							"label": "Vai trò",
							":rules": "[vueData.rules.required]"
						},
						w: 4,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "ThoiGianThucHien",
							"label": "Thời gian thực hiện",
							":rules": "[vueData.rules.required]"
						},
						w: 8,
					},
				],
				updateApi: {
					new: {
						API: "/HDKH_Profile_DeTaiDaThamGia_Save",
						IN: {
							DeTaiID: 0,
							TenDeTai: "item.TenDeTai",
							CoQuanTaiTro: "item.CoQuanTaiTro",
							ThoiGianThucHien: "item.ThoiGianThucHien",
							VaiTro: "item.VaiTro"
						},
						MESS: "Thêm mới đề tài thành công",
						CALLBACK: [
							{
								CALL: "getUserProfile",
							},
						],
					},
					edit: {
						API: "/HDKH_Profile_DeTaiDaThamGia_Save",
						IN: {
							DeTaiID: "item.DeTaiID",
							TenDeTai: "item.TenDeTai",
							CoQuanTaiTro: "item.CoQuanTaiTro",
							ThoiGianThucHien: "item.ThoiGianThucHien",
							VaiTro: "item.VaiTro"
						},
						MESS: "Cập nhật đề tài thành công",
						CALLBACK: [
							{
								CALL: "getUserProfile",
							},
						],
					},
					delete: {
						CONFIRM: "Bạn có muốn xóa đề tài <br/><b>{{item.TenDeTai}}</b>",
						API: "",
						IN: {},
						MESS: "CHUA CO API",
						CALLBACK: [
							{
								CALL: "getUserProfile",
							},
						],
					},
				},
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>