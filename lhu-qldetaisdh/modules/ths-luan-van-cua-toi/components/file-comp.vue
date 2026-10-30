<template>
	<div>
		<div class="file-upload-row pt-2 pb-2">
			<div class="file-upload-action"
				v-if="lock !== 0 && item.Flow_Status !== 'C' && (item.Flow_Status === 'W' || item.Flow_Status === 'P' || item.Flow_Status === 'R') && ItemDes.Task_Detail_Type !== 'FILEVIEW' && ItemDes.User_Input !== 'SDH'">
				<f-file-upload label="" v-model="ItemDes.FILE_UPLOAD" :url="vueData.v_Set.apiFile"
					:filters="uploadFilters" color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="file-upload-status">
				<div v-if="ItemDes.Task_Detail_Type === 'FILE' && ItemDes.Flow_Detail_Status !== 'C' && ItemDes.User_Input !== 'SDH'">
					<v-chip label outlined close v-if="ItemDes.File_ID" class="mb-3 p-2" color="deep-purple accent-4"
						@click:close="deleteFile">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a class="file-chip-link" :href="vueData.v_Set.urlReadFile + ItemDes.File_URL" target="_blank"
							style="color: deep-purple accent-4">{{ ItemDes.File_Name }}</a>
					</v-chip>
				</div>
				<div v-if="ItemDes.Task_Detail_Type !== 'FILE' || ItemDes.Flow_Detail_Status === 'C' || ItemDes.User_Input === 'SDH'">
					<v-chip label outlined v-if="ItemDes.File_ID" class="mb-3" color="deep-purple accent-4">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a class="file-chip-link" :href="vueData.v_Set.urlReadFile + ItemDes.File_URL" target="_blank"
							style="color: deep-purple accent-4">{{ ItemDes.File_Name }}</a>
					</v-chip>
				</div>
				<v-chip v-if="ItemDes.File_ID === null || ItemDes.File_ID === ''" class="mb-3"
					color="deep-purple accent-4" outlined label> Chưa upload file </v-chip>
			</div>
		</div>
		<p class="red--text" v-if="ItemDes.Task_Help !== null">
			<i>{{ ItemDes.Task_Help }}</i>
		</p>
	</div>
</template>

<script>
	export default {
		props: ['itemdes', 'textRules', 'item', 'lock', 'filerule'],
		data() {
			return {
				rules: {
					max_file_size: '80Mb',
					mime_types: [
						{
							title: 'All files',
							extensions: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg',
						},
					],
				},
			}
		},
		computed: {
			ItemDes: function () {
				return this.itemdes
			},
			fileRules: function () {
				return this.filerule
			},
			uploadFilters: function () {
				const allowed = this.getAllowedExtensions()
				return {
					max_file_size: '80Mb',
					mime_types: [
						{
							title: 'Allowed files',
							extensions: allowed.join(','),
						},
					],
				}
			},
		},
		watch: {
			'ItemDes.FILE_UPLOAD': function (val) {
				const $this = this
				if (val && val.Files && val.Files.length > 0) {
					const file = val.Files[0]
					const filename = file.FILE_NAME ?? null
					const ext = filename && filename.includes('.') ? filename.split('.').pop().toLowerCase() : ''
					const allowed = $this.getAllowedExtensions()

					if (ext && !allowed.includes(ext)) {
						Vue.$toast.error(
							`Chỉ được phép upload file định dạng: ${allowed.join(', ').toUpperCase()}`,
							{ position: 'top' }
						)
						$this.deleteFile()
						return
					}

					let fileid = file.FILE_ID ?? null
					let contenttype = file.FILE_CONTENTTYPE ?? null
					let url = file.FILE_URL ?? null
					let size = file.FILE_SIZE ?? null

					$this.ItemDes.File_ID = fileid
					$this.ItemDes.File_Name = filename
					$this.ItemDes.File_Type = contenttype
					$this.ItemDes.File_URL = url

					$this.ItemDes.FILE_UPLOAD = {
						File_ID: fileid,
						File_Name: filename,
						File_Type: contenttype,
						File_URL: url,
						File_Size: size,
					}

					window.unsavedUploadedFiles = window.unsavedUploadedFiles || []
					if (fileid && !window.unsavedUploadedFiles.includes(fileid)) {
						window.unsavedUploadedFiles.push(fileid)
					}
				}
			},
		},
		mounted() {
			const $this = this
			if (!$this.ItemDes) return
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
				File_URL: url,
			}
		},
		methods: {
			getAllowedExtensions() {
				const raw = this.ItemDes?.AllowFileType
				if (!raw || typeof raw !== 'string') {
					return ['jpg', 'doc', 'png', 'pdf', 'docx', 'xlsx', 'xls', 'ppt', 'jpeg']
				}
				const list = raw
					.toLowerCase()
					.replace(/\./g, '')
					.split(/[|,]/)
					.map((ext) => ext.trim())
					.filter(Boolean)
				return list.length > 0 ? list : ['jpg', 'doc', 'png', 'pdf', 'docx', 'xlsx', 'xls', 'ppt', 'jpeg']
			},
			deleteFile() {
				if (!this.ItemDes) return
				if (this.ItemDes.File_ID && window.unsavedUploadedFiles && window.unsavedUploadedFiles.includes(this.ItemDes.File_ID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: this.ItemDes.File_ID }, () => {}, () => {})
					window.unsavedUploadedFiles = window.unsavedUploadedFiles.filter((id) => id !== this.ItemDes.File_ID)
				}
				this.ItemDes.File_ID = null
				this.ItemDes.File_URL = null
				this.ItemDes.File_Name = null
				this.ItemDes.File_Type = null
				this.ItemDes.FILE_UPLOAD = null
			},
			updateFileRules() {
				return this.uploadFilters
			},
		},
	}
</script>