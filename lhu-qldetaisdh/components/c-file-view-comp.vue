<template>
	<div class="d-flex align-center" style="gap:15px">
		<div class="mt-3">
			<v-chip label outlined close v-if="ItemDes.File_ID" class="mb-3" color="deep-purple accent-4"
				@click:close="deleteFile">
				<v-icon left>mdi-file-check-outline</v-icon>
				<a :href="vueData.v_Set.urlReadFile + ItemDes.File_URL" target="_blank"
					style="color: deep-purple accent-4">{{ItemDes.File_Name}}</a>
			</v-chip>
			<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label>
				Chưa upload file
			</v-chip>
		</div>
	</div>
</template>

<script>
	export default {
		name: "c-file-view-comp",
		props: {
			itemdes: { type: Object, default: () => ({}) },
			textRules: { type: Array, default: () => [] },
			item: { type: Object, default: () => ({}) }
		},
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