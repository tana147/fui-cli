<template>
	<div>
		<f-table class="mt-1" :excel="true" :items-per-page="-1" label="Tài khoản ngân hàng" item-key="DSNganHang"
			:items="vueData.DS_NganHang" :headers="HeaderDSNganHang" height="calc(100vh - 200px)" :show-search="true"
			:fixed-header="true" dense :update-form="UpdateForm" :update-api="UpdateApi">
		</f-table>
	</div>
</template>
<script>
	export default {
		props: [],
		data() {
			return {
				HeaderDSNganHang: [
					{
						"text": "Số tài khoản",
						"value": "SoTaiKhoan"
					},
					{
						"text": "Tên tài khoản",
						"value": "TenTaiKhoan"
					},
					{
						"text": "Ngân hàng",
						"value": "TenNganHang"
					},
					{
						"text": "Mã số ngân hàng",
						"value": "MaNganHang"
					},
					{
						"text": "Chi nhánh",
						"value": "ChiNhanh"
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
						"w": 12
					},
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "MaNganHang",
							"label": "Mã số ngân hàng"
						},
						"w": 3
					},
					{
						"el": "v-text-field",
						"attr": {
							":rules": false,
							"v-model": "ChiNhanh",
							"label": "Chi nhánh"
						},
						"w": 9
					},
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "SoTaiKhoan",
							"label": "Số tài khoản"
						},
						"w": 6
					},
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "TenTaiKhoan",
							"label": "Tên tài khoản"
						},
						"w": 6
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
					"default-item": {
						"MaNganHang": "970407",
						"TenNganHang": "Ngân hàng TMCP Kỹ thương Việt Nam",
						"TenTaiKhoan": "CTY TNHH MTV SX TM DV TO MINH"
					},
					"new": {
						"CONFIRM": "Bạn có muốn thêm mới tài khoản ngân hàng",
						"API": "/eorder/NganHang_Insert",
						"IN": {
							"TenNganHang": "item.TenNganHang",
							"MaNganHang": "item.MaNganHang",
							"ChiNhanh": "item.ChiNhanh",
							"TenTaiKhoan": "item.TenTaiKhoan",
							"SoTaiKhoan": "item.SoTaiKhoan",
							"GhiChu": "item.GhiChu"
						},
						"MESS": "Thêm mới thành công",
						"CALLBACK": {
							"CALL": "getNganHang"
						}
					},
					"edit": {
						"CONFIRM": "Bạn có muốn cập nhật tài khoản ngân hàng <br /><b>{{item.SoTaiKhoan}}</b>",
						"API": "/eorder/NganHang_Update",
						"IN": {
							"NganHangID": "item.NganHangID",
							"TenNganHang": "item.TenNganHang",
							"MaNganHang": "item.MaNganHang",
							"ChiNhanh": "item.ChiNhanh",
							"TenTaiKhoan": "item.TenTaiKhoan",
							"SoTaiKhoan": "item.SoTaiKhoan",
							"GhiChu": "item.GhiChu"
						},
						"MESS": "Cập nhật thành công",
						"CALLBACK": {
							"CALL": "getNganHang"
						}
					},
					"delete": {
						"CONFIRM": "Bạn có muốn xóa tài khoản ngân hàng <br /><b>{{item.SoTaiKhoan}}</b>",
						"API": "/eorder/NganHang_Delete",
						"IN": {
							"NganHangID": "item.NganHangID"
						},
						"MESS": "Xóa thành công",
						"CALLBACK": [
							{
								"CALL": "getNganHang"
							}
						]
					}
				},
			}
		},
		mounted() {},
		computed: {},
		watch: {},
		methods: {},
	}
</script>