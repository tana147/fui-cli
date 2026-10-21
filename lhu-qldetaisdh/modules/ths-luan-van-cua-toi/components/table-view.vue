<template>
	<div class="mb-3 mt-3">
		<!-- {{itemDes.Text_Content}} -->
		<c-table v-if="DsGiangVien.length > 0" label="Danh sách thành viên hội đồng" :headers="tableHeader"
			:items="DsGiangVien" isNew="false" isEdit="false" hide-default-footer>
			<template v-slot:item.HoTenHocHamHocVi="{item}">
				<span>
					<span>{{item.HocViHocHam}}. {{item.HoTenGiangVien}}</span>
				</span>
			</template>
		</c-table>

		<div class="d-flex justify-center align-center">
			<h4 v-if="DsGiangVien.length === 0" class="primary--text">
				<v-icon class="mb-1" color="primary">mdi-inbox</v-icon> Chưa có hội đồng
			</h4>
		</div>

	</div>
</template>

<script>
	export default {
		props: ["itemdes"],
		data() {
			return {
				DsGiangVien: [],
	
				tableHeader: [
					{
						text: "STT",
						value: "STT",
						class: "renderCol",
						sortable: false,
						align: "center",
					},
					{
						text: "Họ và tên",
						value: "HoTenHocHamHocVi"
					},
					{
						text: "Ngành giảng dạy",
						value: "NganhGiangDay"
					},
					{
						text: "Cơ quan công tác",
						value: "CoQuanCongTac"
					},
					{
						text: "Chức trách",
						value: "ChucTrach"
					},
				]
			}
		},
		mounted() {
			this.getHoiDongID()
		},
		computed: {
			itemDes: function () {
				return this.itemdes
			}
		},
		watch: {},
		methods: {
			getHoiDongID() {
				if (this.itemDes.Text_Content !== null) {
					ajaxCALL("/HoiDong_Get_ByHoiDongID", {
						HoiDong_ID: this.itemDes.Text_Content
					}, (res) => {
						this.DsGiangVien = res.data[1]
						console.log("Load DsGiangVien success", this.DsGiangVien)
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("error to load DsGiangVien", error)
					})
				} 
			}
		},
	}
</script>