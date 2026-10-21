<template>
	<div>
		<f-table search :headers="headerData" :items="vueData.similiarList" hide-default-footer="true" loading="true"
			loading-text="Đang tải dữ liệu..." class="elevation-1" no-data-text="Không có đề tài liên quan"
			v-if="vueData.similiarList.length > 0" color="teal lighten-3" label="Những đề tài liên quan">

		</f-table>
		<div class="d-flex justify-center align-center">
			<h4 v-if="vueData.similiarList.length === 0" class="success--text">
				<v-icon class="mb-1" color="success">mdi-check-bold</v-icon> Không có đề tài liên quan
			</h4>
		</div>
	</div>

</template>

<script>
	export default {
		props: ["itemdes"],
		data() {
			return {
				headerData: [
					{
						text: "Tên đề tài",
						value: "ThesisName",
						sortable: false
					},
					{
						text: "Khoa",
						value: "ThesisMajor",
						sortable: false
					},
					{
						text: "Tác giả",
						value: "ThesisStudent",
						sortable: false
					}
				]
			}
		},
		mounted() {
		},
		computed: {
			itemDes: function () {
				return this.itemdes
			}
		},
		watch: {},
		methods: {},
	}
</script>