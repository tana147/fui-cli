<template>
	<div>
		<!-- {{getdiem[0]}} -->
		<div class="d-flex align-center" style="gap:15px">
			<!-- v-if="publishstatus === 0" -->
			<div v-if="publishstatus === 0">
				<f-file-upload label="" v-model="ItemDes.FILE_UPLOAD_1" :url="vueData.v_Set.apiFile"
					:filters="fileRules" color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="mt-2">
				<!-- v-if="publishstatus === 0" -->
				<div v-if="publishstatus === 0">
					<v-chip label outlined close v-if="ItemDes.FILE_UPLOAD_1.File_ID" class="mb-3"
						color="deep-purple accent-4" @click:close="deleteFile">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FILE_UPLOAD_1.File_ID"
							target="_blank" style="color: deep-purple accent-4">{{ItemDes.FILE_UPLOAD_1.File_Name}}</a>
					</v-chip>
				</div>
				<div v-if="publishstatus === 1">
					<v-chip label outlined v-if="ItemDes.FILE_UPLOAD_1.File_ID" class="mb-3"
						color="deep-purple accent-4">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a :href="vueData.v_Set.urlReadFile + '/FileData/' + ItemDes.FILE_UPLOAD_1.File_ID"
							target="_blank" style="color: deep-purple accent-4">{{ItemDes.FILE_UPLOAD_1.File_Name}}</a>
					</v-chip>
				</div>

				<v-chip v-if="ItemDes.FileKiemPhieuID === null" class="mb-3" color="deep-purple accent-4" outlined
					label>
					Chưa upload file
				</v-chip>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["item", "getdiem", "publishstatus"],
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
				return this.item
			}
		},
		watch: {
			"ItemDes.FILE_UPLOAD_1": function (val) {
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
					$this.ItemDes.FileKiemPhieuID = fileNXID
					$this.ItemDes.FileKiemPhieuName = fileNXName
	
					$this.ItemDes.FILE_UPLOAD_1 = {
						File_ID: fileid,
						File_Name: filename,
						File_Type: contenttype,
						File_URL: url,
						File_Size: size
					}
					// console.log("$this.item.FILE_UPLOAD_1", $this.ItemDes.FILE_UPLOAD_1)
					// console.log("Files: ", file)
				}
			},
			getdiem: function (val) {
				console.log("val kiem phieu", val)
				this.autoBindingFile()
			}
		},
		mounted() {
			this.autoBindingFile()
		},
		methods: {
			autoBindingFile() {
				const $this = this
				// this.$forceUpdate()
				let fileid = $this.getdiem[0][0].FileKiemPhieuID ?? null
				let filename = $this.getdiem[0][0].FileKiemPhieuName ?? null
				let contenttype = $this.ItemDes.File_Type ?? null
				let url = $this.ItemDes.File_URL ?? null
				let fileNXID = $this.getdiem[0][0].FileKiemPhieuID ?? null
				let fileNXName = $this.getdiem[0][0].FileKiemPhieuName ?? null
				$this.ItemDes.File_ID = fileid
				$this.ItemDes.File_Name = filename
				$this.ItemDes.File_Type = contenttype
				$this.ItemDes.File_URL = url
				$this.ItemDes.FileKiemPhieuID = fileNXID
				$this.ItemDes.FileKiemPhieuName = fileNXName
	
				$this.ItemDes.FILE_UPLOAD_1 = {
					File_ID: fileid,
					File_Name: filename,
					File_Type: contenttype,
					File_URL: url
				}
			},
			deleteFile() {
				this.ItemDes.FILE_UPLOAD_1.File_ID = null
				this.ItemDes.FILE_UPLOAD_1.File_URL = null
				this.ItemDes.FILE_UPLOAD_1.File_Name = null
				this.ItemDes.FILE_UPLOAD_1.File_Type = null
				this.ItemDes.FILE_UPLOAD_1.FILE_UPLOAD_1 = null
				this.ItemDes.FileKiemPhieuID = null
				this.ItemDes.FileKiemPhieuName = null
	
			},
		},
	}
</script>