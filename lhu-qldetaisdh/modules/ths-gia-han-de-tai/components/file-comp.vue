<template>
	<div class="d-flex align-center" style="gap:15px">
		<div
			v-if="item.Flow_Status !== 'C' && (item.Flow_Status === 'W' || item.Flow_Status === 'P') && ItemDes.Task_Detail_Type !== 'FILEVIEW'">
			<f-file-upload label="Upload" v-model="ItemDes.FILE_UPLOAD" :url="vueData.v_Set.apiFile"
				:filters="fileRules" color="v-btn--outlined v-size--default info--text" />
		</div>
		<div class="mt-3">
			<div v-if="ItemDes.Task_Detail_Type === 'FILE' && ItemDes.Flow_Detail_Status !== 'C'">
				<v-chip label outlined close v-if="ItemDes.File_ID" class="mb-3" color="deep-purple accent-4"
					@click:close="deleteFile">
					<v-icon left>mdi-file-check-outline</v-icon>
					<a :href="vueData.v_Set.urlReadFile + ItemDes.File_URL" target="_blank"
						style="color: deep-purple accent-4">{{ItemDes.File_Name}}</a>
				</v-chip>
			</div>
			<div v-if="ItemDes.Task_Detail_Type !== 'FILE' || ItemDes.Flow_Detail_Status === 'C'">
				<v-chip label outlined v-if="ItemDes.File_ID" class="mb-3" color="deep-purple accent-4">
					<v-icon left>mdi-file-check-outline</v-icon>
					<a :href="vueData.v_Set.urlReadFile + ItemDes.File_URL" target="_blank"
						style="color: deep-purple accent-4">{{ItemDes.File_Name}}</a>
				</v-chip>
			</div>
			<v-chip v-if="ItemDes.File_ID === null || ItemDes.File_ID === ''" class="mb-3" color="deep-purple accent-4" outlined label>
				Chưa upload file
			</v-chip>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["itemdes", "textRules", "item"],
		data() {
			return {
				fileRules: {
					"max_file_size": "100mb",
					"mime_types": [
						{
							"title": "All files",
							"extensions": "jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg"
						}
					]
				}
			}
		},
		computed: {
			ItemDes: function () {
				return this.itemdes
			}
		},
		watch: {
			"ItemDes.FILE_UPLOAD": function (val) {
				const $this = this
				if (val && val.Files) {
					const file = val.Files[0]
					const $this = this
					let fileid = file.FILE_ID ?? null
					let filename = file.FILE_NAME ?? null
					let contenttype = file.FILE_CONTENTTYPE ?? null
					let url = file.FILE_URL ?? null
					let size = file.FILE_SIZE ?? null
					$this.ItemDes.File_ID = fileid //
					$this.ItemDes.File_Name = filename //
					$this.ItemDes.File_Type = contenttype //
					$this.ItemDes.File_URL = url
	
					$this.ItemDes.FILE_UPLOAD = {
						File_ID: fileid,
						File_Name: filename,
						File_Type: contenttype,
						File_URL: url,
						File_Size: size
					}
					console.log("Files: ", file)
				}
			}
		},
		mounted() {
			const $this = this
			let fileid = $this.ItemDes.File_ID ?? null
			let filename = $this.ItemDes.File_Name ?? null
			let contenttype = $this.ItemDes.File_Type ?? null
			let url = $this.ItemDes.File_URL ?? null
			$this.ItemDes.File_ID = fileid
			$this.ItemDes.File_Name = filename
			$this.ItemDes.File_Type = contenttype
			$this.ItemDes.File_URL = url
			$this.ItemDes.FILE_UPLOAD = {
				File_ID: fileid,
				File_Name: filename,
				File_Type: contenttype,
				File_URL: url
			}
		},
		methods: {
			deleteFile() {
				this.ItemDes.File_ID = null
				this.ItemDes.File_URL = null
				this.ItemDes.File_Name = null
				this.ItemDes.File_Type = null
				this.ItemDes.FILE_UPLOAD = null
			},
		},
	}
</script>