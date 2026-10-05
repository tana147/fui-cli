<template>
	<div>
		<f-table class="mt-1" :excel="true" :items-per-page="-1" label="Thiết lập chiết khấu"
			item-key="NganHang_ChietKhauID" :items="vueData.DS_NganHangChietKhau" :headers="HeaderDSNganHangChietKhau"
			height="calc(100vh - 200px)" :show-search="true" :fixed-header="true" dense :update-form="UpdateForm"
			:update-api="UpdateApi">
		</f-table>
	</div>
</template>
<script>
	export default {
		props: [],
		data() {
			return {
				HeaderDSNganHangChietKhau: [
					{
						"text": "Tên ngân hàng",
						"value": "TenNganHang"
					},
					{
						"text": "Phần trăm chiết khấu",
						"value": "PhanTramChietKhau",
					},
					{
						"text": "Ghi chú",
						"value": "GhiChu"
					},
					{
						"text": "",
						"value": "ctrl-update",
						"align": "center",
						"width": 80
					}
				],
				UpdateForm: [
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "TenNganHang",
							"label": "Tên ngân hàng"
						},
						"w": 8
					},
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "PhanTramChietKhau",
							"label": "Phần trăm chiết khấu",
							"type": "number"
						},
						"w": 4
					},
					{
						"el": "v-textarea",
						"attr": {
							":rules": false,
							"v-model": "GhiChu",
							"label": "Ghi chú",
							"rows": 2
						},
						"w": 12
					}
				],
				UpdateApi: {
					"new": {
						"CONFIRM": "Bạn có muốn thêm mới tài khoản ngân hàng",
						"API": "/eorder/NganHangChietKhau_Insert",
						"IN": {
							"TenNganHang": "item.TenNganHang",
							"PhanTramChietKhau": "item.PhanTramChietKhau",
							"GhiChu": "item.GhiChu"
						},
						"MESS": "Thêm mới thành công",
						"CALLBACK": {
							"CALL": "getNganHangChietKhau"
						}
					},
					"edit": {
						"CONFIRM": "Bạn có muốn cập nhật tài khoản ngân hàng <br /><b>{{item.TenNganHang}}</b>",
						"API": "/eorder/NganHangChietKhau_Update",
						"IN": {
							"NganHang_ChietKhauID": "item.NganHang_ChietKhauID",
							"TenNganHang": "item.TenNganHang",
							"PhanTramChietKhau": "item.PhanTramChietKhau",
							"GhiChu": "item.GhiChu"
						},
						"MESS": "Cập nhật thành công",
						"CALLBACK": {
							"CALL": "getNganHangChietKhau"
						}
					},
					"delete": {
						"CONFIRM": "Bạn có muốn xóa tài khoản ngân hàng <br /><b>{{item.TenNganHang}}</b>",
						"API": "/eorder/NganHangChietKhau_Delete",
						"IN": {
							"NganHang_ChietKhauID": "item.NganHang_ChietKhauID"
						},
						"MESS": "Xóa thành công",
						"CALLBACK": [
							{
								"CALL": "getNganHangChietKhau"
							}
						]
					}
				},
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>