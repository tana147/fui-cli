<template>
	<div>
		<h3 class="text-primary mb-2 mt-2 font-weight-bold">
			II. Quá trình đào tạo:
		</h3>
		<f-table :items="QuaTrinhDaoTao" :headers="headers" :update-form="updateForm" :update-api="updateApi"
			:excel="false" dense></f-table>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-dao-tao',
		props: {
			userProfile: { type: Array, default: () => [] },
			nhanVienId: [String, Number]
		},
		data() {
			return {
				QuaTrinhDaoTao: [],
				headers: [
					{ "title": "Học vị", "value": "HocVi", "align": "left" },
					{ "title": "Chuyên ngành", "value": "ChuyenNganh", "align": "left" },
					{ "title": "Nơi đào tạo", "value": "NoiDaoTao", "align": "left" },
					{ "title": "Năm tốt nghiệp", "value": "NamTotNghiep", "align": "center" },
					{ "title": "Chức năng", "value": "ctrl-update", "align": "center" }
				],
				updateForm: [
					{
						el: "v-select",
						attr: {
							"v-model": "HocVi",
							"label": "Học vị",
							":items": "['Cử nhân', 'Kỹ sư', 'Thạc sĩ', 'Tiến sĩ', 'Giáo sư']"
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "ChuyenNganh",
							"label": "Chuyên ngành",
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "NoiDaoTao",
							"label": "Nơi đào tạo",
						},
						w: 8,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "NamTotNghiep",
							"label": "Năm tốt nghiệp",
							"type": "number",
						},
						w: 4,
					},
	
				],
				updateApi: {
					"default-item": {
						"NhanVienID": this.nhanVienId
					},
					new: {
						API: "/HDKH_Profile_DaoTao_Save",
						IN: {
							NhanVienID: "item.NhanVienID",
							DaoTaoID: 0,
							HocVi: "item.HocVi",
							ChuyenNganh: "item.ChuyenNganh",
							NoiDaoTao: "item.NoiDaoTao",
							NamTotNghiep: "item.NamTotNghiep"
						},
						MESS: "Thêm mới học vị thành công"
					},
					edit: {
						API: "/HDKH_Profile_DaoTao_Save",
						IN: {
							DaoTaoID: "item.DaoTaoID",
							HocVi: "item.HocVi",
							ChuyenNganh: "item.ChuyenNganh",
							NoiDaoTao: "item.NoiDaoTao",
							NamTotNghiep: "item.NamTotNghiep"
						},
						MESS: "Cập nhật học vị thành công"
					},
					delete: {
						CONFIRM: "Bạn có muốn xóa học vị <br /><b>{{item.HocVi}}</b>",
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
					if (val && val[1]) {
						this.QuaTrinhDaoTao = val[1];
					}
				}
			}
		},
		methods: {},
	}
</script>