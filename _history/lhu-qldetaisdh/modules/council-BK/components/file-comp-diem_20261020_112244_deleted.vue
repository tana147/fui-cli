<template>
	<div>
		<div class="d-flex align-center" style="gap:15px">
            <!-- v-if="ItemDes.Is_PublishDiem === 0" -->
			<div v-if="ItemDes.Is_PublishDiem === 0">
				<f-file-upload label="" v-model="ItemDes.FILE_UPLOAD_DIEM" :url="vueData.v_Set.apiFile"
					:filters="fileRules" color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="mt-3">
				<div v-if="ItemDes.Is_PublishDiem === 0">
					<v-chip label outlined close v-if="ItemDes.FileDiemID" class="mb-3" color="deep-purple accent-4"
						@click:close="deleteFile">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FileDiemID" target="_blank"
							style="color: deep-purple accent-4">{{ItemDes.FileDiemName}}</a>
					</v-chip>
				</div>
				<div v-if="ItemDes.Is_PublishDiem === 1">
					<v-chip label outlined v-if="ItemDes.FileDiemID" class="mb-3" color="deep-purple accent-4">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FileDiemID" target="_blank"
							style="color: deep-purple accent-4">{{ItemDes.FileDiemName}}</a>
					</v-chip>
				</div>

				<v-chip v-if="ItemDes.FileDiemID === null" class="mb-3" color="deep-purple accent-4" outlined label>
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
				console.log("ItemDes", this.item)
				return this.item
			}
		},
		watch: {
			"ItemDes.FILE_UPLOAD_DIEM": function (val) {
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
					$this.ItemDes.FileDiemID = fileNXID
					$this.ItemDes.FileDiemName = fileNXName
					$this.ItemDes.FileDiemURL = url
	
					$this.ItemDes.FILE_UPLOAD_DIEM = {
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
			let fileid = $this.getdiem.FileDiemID ?? null
			let filename = $this.getdiem.FileDiemName ?? null
			let contenttype = $this.ItemDes.File_Type ?? null
			//$this.getdiem.FileNhanXetURL ?? null
			let url = null
			let fileNXID = $this.getdiem.FileDiemID ?? null
			let fileNXName = $this.getdiem.FileDiemName ?? null
			$this.ItemDes.File_ID = fileid
			$this.ItemDes.File_Name = filename
			$this.ItemDes.File_Type = contenttype
			$this.ItemDes.File_URL = url
			$this.ItemDes.FileDiemID = fileNXID
			$this.ItemDes.FileDiemName = fileNXName
			$this.ItemDes.FILE_UPLOAD_DIEM = {
				File_ID: fileid,
				File_Name: filename,
				File_Type: contenttype,
				File_URL: url
			}
		},
		methods: {
			deleteFile() {
				this.ItemDes.FILE_UPLOAD_DIEM.File_ID = null
				this.ItemDes.FILE_UPLOAD_DIEM.File_URL = null
				this.ItemDes.FILE_UPLOAD_DIEM.File_Name = null
				this.ItemDes.FILE_UPLOAD_DIEM.File_Type = null
				this.ItemDes.FILE_UPLOAD_DIEM.FILE_UPLOAD = null
				this.ItemDes.FileDiemID = null
				this.ItemDes.FileDiemName = null
			},
		},
	}
</script>