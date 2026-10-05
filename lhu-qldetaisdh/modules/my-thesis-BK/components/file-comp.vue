<template>
	<div>
		<div class="file-upload-row pt-2 pb-2">
			<div class="file-upload-action"
				v-if="lock !== 0 && item.Flow_Status !== 'C' && (item.Flow_Status === 'W' || item.Flow_Status === 'P') && ItemDes.Task_Detail_Type !== 'FILEVIEW'">
				<f-file-upload label="" v-model="ItemDes.FILE_UPLOAD" :url="vueData.v_Set.apiFile"
					:filters="updateFileRules(itemdes)" color="v-btn--outlined v-size--default info--text" />
			</div>
			<div class="file-upload-status">
				<div v-if="ItemDes.Task_Detail_Type === 'FILE' && ItemDes.Flow_Detail_Status !== 'C'">
					<v-chip label outlined close v-if="ItemDes.File_ID" class="mb-3 p-2" color="deep-purple accent-4"
						@click:close="deleteFile">
						<v-icon left>mdi-file-check-outline</v-icon>
						<a class="file-chip-link" :href="vueData.v_Set.urlReadFile + ItemDes.File_URL" target="_blank"
							style="color: deep-purple accent-4">{{ ItemDes.File_Name }}</a>
					</v-chip>
				</div>
				<div v-if="ItemDes.Task_Detail_Type !== 'FILE' || ItemDes.Flow_Detail_Status === 'C'">
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
		},
		watch: {
			'ItemDes.FILE_UPLOAD': function (val) {
				const $this = this
				if (val && val.Files) {
					const file = val.Files[0]
	
					console.log(' Đang giả lập delay 1 giây trong watcher...')
	
	
					let fileid = file.FILE_ID ?? null
					let filename = file.FILE_NAME ?? null
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
	
					console.log(' Watcher đã chạy xong sau delay')
	
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
				File_URL: url,
			}
		},
		methods: {
			deleteFile() {
				this.ItemDes.File_ID = null
				this.ItemDes.File_URL = null
				this.ItemDes.File_Name = null
				this.ItemDes.File_Type = null
				this.ItemDes.FILE_UPLOAD = null
				console.log('delete file', this.ItemDes)
			},
			updateFileRules() {
				// const item = arr.find(type => type.Task_Detail_Type === "FILE" || type.Task_Detail_Type === "FILEVIEW")
				// Kiểm tra nếu AllowFileType là null hoặc undefined
				// console.log("item xxx", item)
				let rule
				if (this.ItemDes) {
					if (this.ItemDes.AllowFileType === null || this.ItemDes.AllowFileType === undefined) {
						// Đặt giá trị mặc định cho extensions trong fileRules
						this.rules.mime_types[0].extensions = 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg'
						return this.rules
						console.log('fileRules 1', this.rules, item)
					} else {
						// Kiểm tra nếu AllowFileType là một chuỗi
						if (typeof this.ItemDes.AllowFileType === 'string') {
							// Chuyển đổi AllowFileType thành chữ thường và thay dấu | thành dấu ,
							const lowerCaseExtensions = this.ItemDes.AllowFileType.toLowerCase().replace(/\|/g, ',')
							console.log('lowerCaseExtensions', lowerCaseExtensions)
	
							// Cập nhật extensions trong fileRules
							this.rules.mime_types[0].extensions = lowerCaseExtensions
							return this.rules
							console.log('fileRules 2', this.rules)
						} else {
							// Nếu AllowFileType không phải là chuỗi, đặt giá trị mặc định cho extensions trong fileRules
							this.rules.mime_types[0].extensions = 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg'
							return this.rules
							console.log('fileRules 3', this.rules)
						}
					}
				}
			},
		},
	}
</script>