<template>
	<uc-wf-shell>
		<div>File Upload:</div>
		<input type="file" accept=".docx,.pdf,.xlsx" @change="onFileSelected" />
		<template v-if="fileDataList.length > 0">
			<div class="mt-2" style="font-size: 10px" v-for="file in fileDataList">
				<p><b>{{file.FileName}}</b></p>
				<small>{{file.FileID}} ({{file.FileSize}} KB)</small>
				<p>
					<a :href="vueData.v_Set.urlFile + file.FileID"
						target="_blank">{{vueData.v_Set.urlFile}}{{file.FileID}}</a>
				</p>
			</div>
		</template>
		<br />
		<br />
		<hr />
		<div>/WF_Category_GetList</div>
		<code style="font-size: 10px">
			{{categoryList}}
		</code>
		<br />
		<br />
		<hr />
		<div>/auth/WF_Demo_Api</div>
		<code style="font-size: 10px;">
			{{auditLogList}}
		</code>
	</uc-wf-shell>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData,
				categoryList: [],
				auditLogList: [],
				fileDataList: []
			}
		},
		mounted() {
			this.getAuditLog()
			this.getCategory()
		},
		computed: {},
		watch: {},
		methods: {
			getAuditLog() {
				ajaxCALL('/auth/WF_Demo_Api', null, res => {
					this.auditLogList = res.data
				})
			},
			getCategory() {
				ajaxCALL('/WF_Category_GetList', null, res => {
					this.categoryList = res.data
				})
			},
			onFileSelected: function (event) {
				var input = event && event.target ? event.target : null;
				var file = input && input.files && input.files[0] ? input.files[0] : null;
				if (!file) return;
				//Create formData
				const formData = new FormData();
				formData.append('file', file);
				ajaxCALL_File(vueData.v_Set.apiFileUpload, formData, (res) => {
					if (res.Files && res.Files.length > 0) {
						this.fileDataList = res.Files
					}
				})
			},
		},
	}
</script>