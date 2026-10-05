<template>
	<div>
		<h3 class="text-primary mb-2 mt-2 font-weight-bold">
			V. Các công trình khoa học đã công bố:
		</h3>
		<f-table :items="CongTrinhCongBo" :headers="headers" :update-form="updateForm" :update-api="updateApi"
			:excel="false" dense></f-table>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-cong-trinh',
		props: {
			userProfile: { type: Array, default: () => [] },
			nhanVienId: [String, Number]
		},
		data() {
			return {
				CongTrinhCongBo: [],
				headers: [
					{ "title": "Tên tác giả", "value": "TenTacGia", "align": "left" },
					{ "title": "Tên công trình", "value": "TenCongTrinh", "align": "left" },
					{ "title": "Tạp chí - Hội thảo", "value": "TapChi_HoiThao", "align": "left" },
					{ "title": "Ghi chú", "value": "GhiChu", "align": "left" },
					{ "title": "Chức năng", "value": "ctrl-update", "align": "center" }
				],
				updateForm: [
					{
						el: "v-text-field",
						attr: {
							"v-model": "TenTacGia",
							"label": "Tên tác giả",
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "TenCongTrinh",
							"label": "Tên công trình",
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "TapChi_HoiThao",
							"label": "Tạp chí - Hội thảo",
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "GhiChu",
							"label": "Ghi chú"
						},
						w: 6,
					},
				],
				updateApi: {
					"default-item": {
						"NhanVienID": this.nhanVienId
					},
					new: {
						API: "/HDKH_Profile_CongTrinhDaCongBo_Save",
						IN: {
							NhanVienID: "item.NhanVienID",
							CongTrinhID: 0,
							TenTacGia: "item.TenTacGia",
							TenCongTrinh: "item.TenCongTrinh",
							TapChi_HoiThao: "item.TapChi_HoiThao",
							GhiChu: "item.GhiChu"
						},
						MESS: "Thêm mới công trình thành công"
					},
					edit: {
						API: "/HDKH_Profile_CongTrinhDaCongBo_Save",
						IN: {
							CongTrinhID: "item.CongTrinhID",
							TenTacGia: "item.TenTacGia",
							TenCongTrinh: "item.TenCongTrinh",
							TapChi_HoiThao: "item.TapChi_HoiThao",
							GhiChu: "item.GhiChu"
						},
						MESS: "Cập nhật công trình thành công"
					},
					delete: {
						CONFIRM: "Bạn có muốn xóa công trình <br /><b>{{item.TenCongTrinh}}</b>",
						API: "",
						IN: {},
						MESS: "CHUA CO API"
					},
				},
			}
		},
		mounted() { },
		computed: {},
		watch: {
			userProfile: {
				immediate: true,
				handler(val) {
					if (val && val[4]) {
						this.CongTrinhCongBo = val[4];
					}
				}
			}
		},
		methods: {},
	}
</script>