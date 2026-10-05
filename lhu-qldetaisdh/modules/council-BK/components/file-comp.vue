<template>
	<div>
		<div class="d-flex align-center" style="gap:15px">
			<!-- v-if="ItemDes.Is_PublishDiem === 0" -->
			<div v-if="ItemDes.Is_PublishDiem === 0">
				<f-file-upload label="" v-model="ItemDes.FILE_UPLOAD" :url="vueData.v_Set.apiFile" :filters="fileRules"
					color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="mt-3">
				<!-- v-if="ItemDes.Is_PublishDiem === 0" -->
				<div v-if="ItemDes.Is_PublishDiem === 0">
					<v-chip label outlined close v-if="ItemDes.FileNhanXetID" class="mb-3" color="deep-purple accent-4"
						@click:close="deleteFile">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FileNhanXetID" target="_blank"
							style="color: deep-purple accent-4">{{ItemDes.FileNhanXetName}}</a>
					</v-chip>
				</div>
				<div v-if="ItemDes.Is_PublishDiem === 1">
					<v-chip label outlined v-if="ItemDes.FileNhanXetID" class="mb-3" color="deep-purple accent-4">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FileNhanXetID" target="_blank"
							style="color: deep-purple accent-4">{{ItemDes.FileNhanXetName}}</a>
					</v-chip>
				</div>

				<v-chip v-if="ItemDes.FileNhanXetID === null" class="mb-3" color="deep-purple accent-4" outlined label>
					Chưa upload file
				</v-chip>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["item", "getdiem"],
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
				console.log("item 2", this.item)
				return this.item
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
					let fileNXID = file.FILE_ID ?? null
					let fileNXName = file.FILE_NAME ?? null
					$this.ItemDes.File_ID = fileid //
					$this.ItemDes.File_Name = filename //
					$this.ItemDes.File_Type = contenttype //
					$this.ItemDes.File_URL = url
					$this.ItemDes.FileNhanXetID = fileNXID
					$this.ItemDes.FileNhanXetName = fileNXName
	
					$this.ItemDes.FILE_UPLOAD = {
						File_ID: fileid,
						File_Name: filename,
						File_Type: contenttype,
						File_URL: url,
						File_Size: size
					}
					// console.log("$this.item.FILE_UPLOAD", $this.ItemDes.FILE_UPLOAD)
					// console.log("Files: ", file)
				}
			}
		},
		mounted() {
			const $this = this
			console.log("$this.getdiem", $this.getdiem)
			let fileid = $this.getdiem.FileNhanXetID ?? null
			let filename = $this.getdiem.FileNhanXetName ?? null
			let contenttype = $this.ItemDes.File_Type ?? null
			let url = $this.getdiem.FileNhanXetURL ?? null
			let fileNXID = $this.getdiem.FileNhanXetID ?? null
			let fileNXName = $this.getdiem.FileNhanXetName ?? null
	
			$this.ItemDes.File_ID = fileid
			$this.ItemDes.File_Name = filename
			console.log("$this.ItemDes.File_Namexxx", $this.ItemDes.File_Name)
			$this.ItemDes.File_Type = contenttype
			$this.ItemDes.File_URL = url
			$this.ItemDes.FileNhanXetID = fileNXID
			$this.ItemDes.FileNhanXetName = fileNXName
			$this.ItemDes.FILE_UPLOAD = {
				File_ID: fileid,
				File_Name: filename,
				File_Type: contenttype,
				File_URL: url
			}
		},
		methods: {
			deleteFile() {
				this.ItemDes.FILE_UPLOAD.File_ID = null
				this.ItemDes.FILE_UPLOAD.File_URL = null
				this.ItemDes.FILE_UPLOAD.File_Name = null
				this.ItemDes.FILE_UPLOAD.File_Type = null
				this.ItemDes.FILE_UPLOAD.FILE_UPLOAD = null
				this.ItemDes.FileNhanXetID = null
				this.ItemDes.FileNhanXetName = null
			},
		},
	}
</script>