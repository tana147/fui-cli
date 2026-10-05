<template>
	<div>
		<v-card class="mt-5">
			<v-card-title class="primary--text">Danh sách hội đồng</v-card-title>
			<v-data-table :headers="GiangVienSelectedHeaders" :items="DSGVSelected" item-key="GiangVienID" />
		</v-card>
	</div>
</template>

<script>
	export default {
		props: {
			dshdgiangvien: {
				type: Array
			},
		},
	
		data() {
			return {
				GiangVienSelectedHeaders: [
					{
						text: "STT",
						value: "STT",
						align: 'center',
						sortable: false,
					},
					{
						text: "Họ tên giảng viên",
						value: "HoTenHocHamHocVi",
					},
					{
						text: "Ngành giảng dạy",
						value: "NganhGiangDay",
					},
					{
						text: "Cơ quan công tác",
						value: "CoQuanCongTac",
					},
					{
						text: "Chức trách",
						value: "ChucTrach",
					},
				]
			}
		},
		computed: {
			DSHoiDongGiangVien: function () {
				return this.dshdgiangvien
			},
			DSGVSelected: function () {
				let filterDSSelected = this.DSHoiDongGiangVien.filter(item => item.Is_Chon && item.GiangVienID)
				this.$emit("input", filterDSSelected)
				return filterDSSelected
			}
		}
	}
</script>