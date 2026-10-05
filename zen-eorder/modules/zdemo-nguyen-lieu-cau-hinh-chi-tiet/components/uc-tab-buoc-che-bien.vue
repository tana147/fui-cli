<template>
	<div>
		<div class="page-section">
			<v-card elevation="0">
				<!--Tên sản phẩm -->
				<v-toolbar dense flat>
					<v-toolbar-title>
						Nguyên liệu món: <span class="success--text ml-1">{{ CTSanPham?.TenSanPham }} - {{
							CTSanPham?.MaSanPham }}</span>
					</v-toolbar-title>
				</v-toolbar>
				<!-- bảng danh sách và cấu hình -->
				<v-card-text style="padding-top: 10px;">
					<v-row>
						<v-col cols="5">
							<f-table class="mx-3 mb-5" label="Danh sách các bước thiết lập" :headers="headers"
								:items="[]" :excel="true" dense :update-form="updateForm" :update-api="updateApi"
								:items-per-page='-1' hide-default-footer="true" />
						</v-col>
						<v-col cols="7">
							<v-card outlined>
								<v-toolbar flat dense>
									<v-toolbar-title class="success--text" style="font-size: 1.1rem">
										Chi tiết bước</v-toolbar-title>
								</v-toolbar>
								<v-card-text class="pt-0">
									<v-form>
										<v-text-field label="Thời gian nấu" outlined dense :rules="[v => !!v || '']" />
										<!-- bảng mô tả chi tiết -->
										<div class="mb-3">
											<h3>Mô tả chi tiết</h3>
										</div>
										<f-editor v-model="ct_sanpham.NoiDung" :height="400" :toolbar="toolbar"
											:imageapi="vueData.v_Set.apiImageAdapter" />
										<!-- nút lưu -->
										<div class="text-right mt-2">
											<v-btn color="primary">Lưu</v-btn>
										</div>
									</v-form>
								</v-card-text>
							</v-card>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</div>
	</div>
</template>
<script>
	export default {
		props: ["ct_sanpham"],
		data() {
			return {
				toolbar: ["bold", "italic", "underline", "|", "undo", "redo", "removeFormat", "alignment", "fontSize", "fontFamily", "fontColor", "|", "bulletedList", "numberedList", "|", "imageUpload"],
				headers: [
					{
						text: "Số bước",
						value: "Bước",
					},
					{
						text: "",
						el: "t-button",
						align: "right",
						attr: {
							color: "primary",
							label: "Xem chi tiết",
							action: [
								{
									ManHinhID: "item.ManHinhID"
								},
								{
									CALL: "getManHinhChiTiet"
								}
							]
						}
					},
					{
						text: "Tạm khóa",
						align: "center",
						value: "TinhTrang",
						el: "v-icon",
						attr: {
							color: "red"
						},
						innerHTML: "{{item.TinhTrang == 0 ? '': 'mdi-lock'}}"
					},
					{
						text: "",
						value: "ctrl-update",
						align: "center",
						width: 100,
						sortable: false,
					},
				],
				updateForm: [
					{
						el: "v-text-field",
						attr: {
							"v-model": "Buoc",
							label: "Bước",
						},
						w: 8,
					},
					{
						el: "v-select",
						attr: {
							"v-model": "TinhTrang",
							label: "Tình trạng",
							":items": "vueData.DSTinhTrang",
						},
						w: 4,
					},
				],
				updateApi: {
					new: {
						API: "/eordertest/CuaHangIP_Insert",
						IN: {
							CuaHangID: "vueData.CuaHangIPItem.CuaHangID",
							Buoc: "item.Bước",
						},
						MESS: "Thêm IP cửa hàng thành công",
						CALLBACK: [
							{
								EXE: "loadDSCuaHangIP()",
							},
						],
					},
					edit: {
						API: "/eordertest/CuaHangIP_Update",
						IN: {
							CuaHangID: "vueData.CuaHangIPItem.CuaHangID",
							Buoc: "item.Bước",
							CuaHangIPID: "item.CuaHangIPID",
						},
						MESS: "Cập nhật IP cửa hàng thành công",
						CALLBACK: [
							{
								EXE: "loadDSCuaHangIP()",
							},
						],
					},
					delete: {
						API: "/eordertest/CuaHangIP_Delete",
						IN: {
							CuaHangIPID: "item.CuaHangIPID",
							CuaHangID: "vueData.CuaHangIPItem.CuaHangID",
						},
						MESS: "Xóa thành công",
						CALLBACK: [
							{
								EXE: "loadDSCuaHangIP()",
							},
						],
					},
				},
			}
		},
		computed: {
			CTSanPham: function () {
				return this.ct_sanpham
			},
		},
		methods: {
		},
		mounted: {
		},
	}
</script>