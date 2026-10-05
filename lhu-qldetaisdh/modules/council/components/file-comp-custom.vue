<template>
	<div>
		<div class="d-flex align-center" style="gap:15px">
			<div>
				<f-file-upload label="" v-model="ItemDes.FILE_UPLOAD" :url="vueData.v_Set.apiFile" :filters="fileRules"
					color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="mt-2">
				<v-chip label outlined close v-if="ItemDes.FILE_UPLOAD && ItemDes.FILE_UPLOAD.File_ID" class="mb-3"
					color="deep-purple accent-4" @click:close="deleteFile">
					<v-icon left>mdi-file-check-outline</v-icon>
					<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FILE_UPLOAD.File_ID"
						target="_blank" style="color: deep-purple accent-4">{{ItemDes.FILE_UPLOAD.File_Name}}</a>
				</v-chip>

				<v-chip v-if="!ItemDes.FILE_UPLOAD || !ItemDes.FILE_UPLOAD.File_ID" class="mb-3" color="deep-purple accent-4" outlined label>
					Chưa upload file
				</v-chip>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["item", "getdiem", "publishstatus"],
		emits: ["on-file-uploaded"],
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
				return this.item || {}
			}
		},
		watch: {
			item: {
				handler(val) {
					if (val) {
						this.syncFromFileItem()
					}
				},
				deep: true,
				immediate: true
			},
			"ItemDes.FILE_UPLOAD": function (val) {
				if (val && val.Files && val.Files.length > 0) {
					const file = val.Files[0]
					let fileid = file.FILE_ID ?? null
					let filename = file.FILE_NAME ?? null
					let contenttype = file.FILE_CONTENTTYPE ?? null
					let url = file.FILE_URL ?? null
					let size = file.FILE_SIZE ?? null

					this.ItemDes.File_ID = fileid
					this.ItemDes.File_Name = filename
					this.ItemDes.File_Type = contenttype
					this.ItemDes.File_URL = url
					this.ItemDes.FileNhanXetID = fileid
					this.ItemDes.FileNhanXetName = filename

					this.ItemDes.FILE_UPLOAD = {
						File_ID: fileid,
						File_Name: filename,
						File_Type: contenttype,
						File_URL: url,
						File_Size: size
					}

					if (fileid) {
						this.$emit("on-file-uploaded", fileid)
						if (!window.unsavedUploadedFiles) {
							window.unsavedUploadedFiles = []
						}
						if (!window.unsavedUploadedFiles.includes(fileid)) {
							window.unsavedUploadedFiles.push(fileid)
						}
					}
				}
			}
		},
		methods: {
			syncFromFileItem() {
				if (this.ItemDes) {
					if (this.ItemDes.FileNhanXetID && (!this.ItemDes.FILE_UPLOAD || !this.ItemDes.FILE_UPLOAD.File_ID)) {
						this.ItemDes.FILE_UPLOAD = {
							File_ID: this.ItemDes.FileNhanXetID,
							File_Name: this.ItemDes.FileNhanXetName,
							File_Type: this.ItemDes.File_Type ?? null,
							File_URL: this.ItemDes.File_URL ?? (this.ItemDes.FileNhanXetID ? `/FileData/${this.ItemDes.FileNhanXetID}` : null)
						}
					}
				}
			},
			deleteFile() {
				this.ItemDes.FILE_UPLOAD = {
					File_ID: null,
					File_URL: null,
					File_Name: null,
					File_Type: null
				}
				this.ItemDes.File_ID = null
				this.ItemDes.File_Name = null
				this.ItemDes.File_URL = null
				this.ItemDes.FileNhanXetID = null
				this.ItemDes.FileNhanXetName = null
			},
		},
	}
</script>