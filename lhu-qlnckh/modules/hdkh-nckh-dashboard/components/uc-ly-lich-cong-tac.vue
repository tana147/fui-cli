<template>
	<div>
		<h3 class="text-primary mb-2 mt-2 font-weight-bold">
			III. Quá trình công tác chuyên môn kể từ khi tốt nghiệp đại học:
		</h3>
		<f-table :items="QuaTrinhCongTac" :headers="headers" :update-form="updateForm" :update-api="updateApi"
			:excel="false" dense></f-table>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-cong-tac',
		props: {
			items: { type: Array, default: () => [] },
			nhanVienId: { type: String, default: '' }
		},
		data() {
			return {
				headers: [
					{ "title": "Thời gian", "value": "ThoiGian", "align": "left" },
					{ "title": "Nơi công tác", "value": "NoiCongTac", "align": "left" },
					{ "title": "Công việc đảm nhận", "value": "CongViecDamNhiem", "align": "left" },
					{ "title": "Chức năng", "value": "ctrl-update", "align": "center" }
				],
				updateForm: [
					{
						el: "v-text-field",
						attr: {
							"v-model": "ThoiGian",
							"label": "Thời gian",
						},
						w: 4,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "NoiCongTac",
							"label": "Nơi công tác",
						},
						w: 4,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "CongViecDamNhiem",
							"label": "Công việc đảm nhận",
						},
						w: 4,
					}
				],
				updateApi: {
					"default-item": {
						"NhanVienID": this.nhanVienId
					},
					new: {
						API: "/HDKH_Profile_CongTac_Save",
						IN: {
							NhanVienID: "item.NhanVienID",
							CongTacID: 0,
							ThoiGian: "item.ThoiGian",
							NoiCongTac: "item.NoiCongTac",
							CongViecDamNhiem: "item.CongViecDamNhiem"
						},
						MESS: "Thêm mới quá trình thành công"
					},
					edit: {
						API: "/HDKH_Profile_CongTac_Save",
						IN: {
							CongTacID: "item.CongTacID",
							ThoiGian: "item.ThoiGian",
							NoiCongTac: "item.NoiCongTac",
							CongViecDamNhiem: "item.CongViecDamNhiem"
						},
						MESS: "Cập nhật quá trình thành công"
					},
					delete: {
						CONFIRM: "Bạn có muốn xóa nơi công tác <br /><b>{{item.NoiCongTac}}</b>",
						API: "",
						IN: {
						},
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
				}
			}
		},
		computed: {
			QuaTrinhCongTac() {
				return this.items || [];
			}
		}
	}
</script>