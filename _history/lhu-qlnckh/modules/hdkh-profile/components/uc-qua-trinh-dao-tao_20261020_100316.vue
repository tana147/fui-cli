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
		props: [],
		data() {
			return {
				vueData,
				QuaTrinhDaoTao: vueData.userProfile[1] ?? {},
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
							":rules": "[vueData.rules.required]",
							":items": "['Cử nhân', 'Kỹ sư', 'Thạc sĩ', 'Tiến sĩ', 'Giáo sư']"
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "ChuyenNganh",
							"label": "Chuyên ngành",
							":rules": "[vueData.rules.required]"
						},
						w: 6,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "NoiDaoTao",
							"label": "Nơi đào tạo",
							":rules": "[vueData.rules.required]"
						},
						w: 8,
					},
					{
						el: "v-text-field",
						attr: {
							"v-model": "NamTotNghiep",
							"label": "Năm tốt nghiệp",
							"type": "number",
							":rules": "[vueData.rules.required, vueData.rules.year]"
						},
						w: 4,
					},
	
				],
				updateApi: {
					new: {
						API: "/HDKH_Profile_DaoTao_Save",
						IN: {
							DaoTaoID: 0,
							HocVi: "item.HocVi",
							ChuyenNganh: "item.ChuyenNganh",
							NoiDaoTao: "item.NoiDaoTao",
							NamTotNghiep: "item.NamTotNghiep"
						},
						MESS: "Thêm mới học vị thành công",
						CALLBACK: [
							{
								CALL: "getUserProfile",
							},
						],
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
						MESS: "Cập nhật học vị thành công",
						CALLBACK: [
							{
								CALL: "getUserProfile",
							},
						],
					},
					delete: {
						CONFIRM: "Bạn có muốn xóa học vị <br /><b>{{item.HocVi}}</b>",
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