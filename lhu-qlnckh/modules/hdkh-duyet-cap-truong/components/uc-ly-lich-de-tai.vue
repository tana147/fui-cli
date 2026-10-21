<template>
	<div>
		<h3 class="text-primary mb-2 mt-2 font-weight-bold">
			IV. Các đề tài đã tham gia:
		</h3>
		<f-table :items="DeTaiDaThamGia" :headers="headers" :update-form="updateForm" :update-api="updateApi"
			:excel="false" dense></f-table>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-de-tai',
		props: {
			items: { type: Array, default: () => [] },
			nhanVienId: { type: String, default: '' }
		},
		data() {
			return {
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
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "CoQuanTaiTro",
							"label": "Cơ quan tài trợ",
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "VaiTro",
							"label": "Vai trò",
						},
						w: 4,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "ThoiGianThucHien",
							"label": "Thời gian thực hiện",
						},
						w: 8,
					},
				],
				updateApi: {
					"default-item": {
						"NhanVienID": this.nhanVienId
					},
					new: {
						API: "/HDKH_Profile_DeTaiDaThamGia_Save",
						IN: {
							NhanVienID: "item.NhanVienID",
							DeTaiID: 0,
							TenDeTai: "item.TenDeTai",
							CoQuanTaiTro: "item.CoQuanTaiTro",
							ThoiGianThucHien: "item.ThoiGianThucHien",
							VaiTro: "item.VaiTro"
						},
						MESS: "Thêm mới đề tài thành công"
					},
					edit: {
						API: "/HDKH_Profile_DeTaiDaThamGia_Save",
						IN: {
							NhanVienID: this.nhanVienId,
							DeTaiID: "item.DeTaiID",
							TenDeTai: "item.TenDeTai",
							CoQuanTaiTro: "item.CoQuanTaiTro",
							ThoiGianThucHien: "item.ThoiGianThucHien",
							VaiTro: "item.VaiTro"
						},
						MESS: "Cập nhật đề tài thành công"
					},
					delete: {
						CONFIRM: "Bạn có muốn xóa đề tài <br/><b>{{item.TenDeTai}}</b>",
						API: "",
						IN: {},
						MESS: "CHUA CO API"
					},
				},
			}
		},
		watch: {
			nhanVienId: {
				immediate: true,
				handler(val) {
					if (this.updateApi && this.updateApi["default-item"]) {
						this.updateApi["default-item"].NhanVienID = val;
					}
					if (this.updateApi && this.updateApi.edit && this.updateApi.edit.IN) {
						this.updateApi.edit.IN.NhanVienID = val;
					}
				}
			}
		},
		computed: {
			DeTaiDaThamGia() {
				return this.items || [];
			}
		}
	}
</script>