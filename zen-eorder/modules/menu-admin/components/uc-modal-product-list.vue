<template>
	<v-dialog v-model="is_dialog" width="640" persistent>
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>
					Thiết lập vị trí sản phẩm
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="$emit('on_close')">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-toolbar>
			<v-card-text>
				<f-table label="Danh sách sản phẩm" :items="ds_sp_menu" :excel="true" :update-form="updateForm"
					:headers="headers" :update-api="updateAPI" />
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ["is_dialog", "ds_sp_menu"],
		data() {
			return {
				updateForm: [
					{
						"el": "v-combobox",
						"attr": {
							"v-model": "SanPhamID",
							"label": "Chọn sản phẩm",
							":items": "vueData.DSSanPham",
							"item-text": "text",
							"item-value": "value"
						},
						"w": 12
					},
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "ViTri_X",
							"label": "Vị trí X"
						},
						"w": 6
					},
					{
						"el": "v-text-field",
						"attr": {
							"v-model": "ViTri_Y",
							"label": "Vị trí Y"
						},
						"w": 6
					}
				],
				headers: [
					{
						"text": "Tên sản phẩm",
						"el": "span",
						"value": "TenSanPham",
						"attr": {
							"style": "display: flex; align-items: center;"
						},
						"innerHTML": "<div><b>{{item.MaSanPham}} - {{item.TenSanPham}}</b></div>"
					},
					{
						"text": "Vị trí",
						"el": "span",
						"attr": {
							"style": "display: flex; align-items: center;"
						},
						"innerHTML": "<div><b>X:{{item.ViTri_X}} <br> Y:{{item.ViTri_Y}}</b></div>"
					},
					{
						"text": "",
						"value": "ctrl-update",
						"align": "center"
					}
				],
				updateAPI: {
					"delete": {
						"CONFIRM": "Bạn có muốn xóa sản phẩm <span class='error--text'> {{item.TenSanPham}} </i></span>?",
						"API": "/eorder/CuaHangMenu_Delete",
						"IN": {
							"CuaHang_MenuID": "item.CuaHang_MenuID"
						},
						"OUT": "ERRMSG",
						"MESS": "Xóa thành công",
						"CALLBACK": [
							{
								"CALL": "getCuaHangMenu"
							}
						]
					}
				}
			}
		}, methods: {},
	} 
</script>