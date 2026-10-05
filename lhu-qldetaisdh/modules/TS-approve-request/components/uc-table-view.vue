<template>
	<div class="mb-3 mt-3">
		<c-table v-if="DsGiangVien.length > 0" :label="item.TASK_DETAIL_DESCRIPTION || 'Danh sách'"
			:headers="tableHeader" :items="DsGiangVien" isNew="false" isEdit="false" hide-default-footer>
			<template v-slot:item.HoTenHocHamHocVi="{item}">
				<span>
					<span>{{item.HocViHocHam}}. {{item.HoTenGiangVien}}</span>
				</span>
			</template>
		</c-table>

		<div class="d-flex justify-center align-center">
			<h4 v-if="DsGiangVien.length === 0" class="primary--text text-subtitle-2">
				<v-icon class="mb-1" color="primary">mdi-inbox</v-icon>
				{{ isHoiDong ? 'Chưa có hội đồng' : 'Chưa có dữ liệu' }}
			</h4>
		</div>
	</div>
</template>

<script>
	export default {
		name: "uc-table-view",
		props: {
			item: { type: Object, default: () => ({}) }
		},
		data() {
			return {
				DsGiangVien: [],
	
				tableHeader: [
					{
						text: "STT",
						value: "STT",
						class: "uc-ar-render-col",
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
			isHoiDong() {
				const desc = this.item?.TASK_DETAIL_DESCRIPTION || '';
				return desc.toLowerCase().includes('hội đồng') || desc.toLowerCase().includes('hoidong');
			}
		},
		watch: {
			item: {
				handler() {
					this.getHoiDongID()
				},
				deep: true
			}
		},
		methods: {
			async getHoiDongID() {
				if (this.item.Text_Content) {
					try {
						const res = await ajaxCALLPromise("/HoiDong_Get_ByHoiDongID", {
							HoiDong_ID: this.item.Text_Content
						})
						this.DsGiangVien = res[1] || []
						console.log("Load DsGiangVien success", this.DsGiangVien)
					} catch (error) {
						Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi lấy danh sách hội đồng', { position: 'top' });
						console.log("error to load DsGiangVien", error)
					}
				}
			}
		},
	}
</script>