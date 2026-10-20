<template>
	<div v-if="!ItemDes.IsOldProc">
		<f-table search :headers="headerData" :items="similiarList" hide-default-footer="true" loading="true"
			loading-text="Đang tải dữ liệu..." class="elevation-1" no-data-text="Không có đề tài liên quan"
			v-if="similiarList.length > 0" color="teal lighten-3" label="Những đề tài liên quan">

		</f-table>
		<div class="d-flex justify-center align-center">
			<h4 v-if="similiarList.length === 0" class="success--text">
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
			ItemDes: function () {
				return this.itemdes
			},
			similiarList: function () {
				return (typeof vueData !== "undefined" && Array.isArray(vueData.similiarList)) ? vueData.similiarList : []
			}
		},
		watch: {},
		methods: {},
	}
</script>