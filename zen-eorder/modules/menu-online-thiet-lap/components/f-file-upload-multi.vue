<template>
	<div>
		<v-btn style="background-color: transparent !important; color: #2c3e50" :id="elID" v-bind="$attrs" class="d-flex align-center">
			<v-icon v-if="iconText" :left="label !== ''">{{ iconText }}</v-icon>
			{{ label }}
			<v-dialog v-model="dialog" persistent width="450">
				<v-card>
					<v-card-actions>
						<span>Upload file</span>
						<v-spacer></v-spacer>
						<v-btn :loading="loading" icon @click="closeDialog">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</v-card-actions>
					<v-sheet v-if="UploadingError.length > 0" color="error" dark class="py-2">
						<v-card-text class="py-1 px-4" v-for="(t, i) in UploadingError" :key="'error-' + i">
							<div><b>{{ t.file.name }}</b></div>
							<div>{{ t.message }}</div>
						</v-card-text>
					</v-sheet>
					<v-sheet v-if="UploadingFile.length > 0" class="pb-2">
						<v-card-text class="py-1 px-4" v-for="(t, i) in UploadingFile" :key="'file-' + i">
							<v-card-subtitle class="pa-0">
								{{ t.percent }}% - {{ t.name }}
							</v-card-subtitle>
							<v-progress-linear :value="t.percent" class="mb-2 mt-1"></v-progress-linear>
						</v-card-text>
					</v-sheet>
				</v-card>
			</v-dialog>
		</v-btn>
	</div>
</template>

<script>
	export default {
		props: {
			multiple: { type: Boolean, default: false },
			label: { type: String, default: '' },
			url: { type: String, default: '' },
			autoclose: { type: Boolean, default: true },
			iconText: { type: String, default: 'mdi-cloud-upload-outline' },
			filters: {
				type: Object,
				default: () => ({
					max_file_size: '10mb',
					mime_types: [{ title: 'All files', extensions: '*' }]
				})
			},
			resize: {
				type: Object,
				default: () => ({
					width: 1900,
					height: 1600,
					quality: 80
				})
			},
			onclose: {
				type: Function,
				default: undefined
			},
			type: {
				type: String,
				default: ''
			}
		},
		data() {
			return {
				dialog: false,
				loading: true,
				UploadingFile: [],
				UploadingError: [],
				elID: '',
				uploader: null,
				filesUploaded: []
			};
		},
		created() {
			this.elID = this.generateID();
		},
		mounted() {
			this.uploaderInit();
		},
		watch: {
			dialog(newVal) {
				if (!newVal && this.onclose) {
					this.onclose();
				}
			},
			filters: {
				deep: true,
				handler(newVal) {
					this.uploader.setOption('filters', newVal);
					const ext = '.' + newVal.mime_types[0].extensions.replace(/\s/g, '').replace(/,+/g, ',.');
					this.$nextTick(() => {
						const fileInput = document.querySelector(`#${this.elID} + .moxie-shim input[type="file"]`);
						if (fileInput) fileInput.setAttribute('accept', ext);
					});
				}
			}
		},
		methods: {
			generateID() {
				return 'upload-btn-' + Math.random().toString(36).substr(2, 9);
			},
			closeDialog() {
				this.dialog = false;
				this.UploadingError = [];
				this.UploadingFile = [];
			},
			uploaderInit() {
				const self = this;
				const uploader = new plupload.Uploader({
					runtimes: 'html5,html4',
					browse_button: self.elID,
					headers: {
						authorization: 'Bearer ' + getCookie('awt'),
						uploaddata: Date.now()
					},
					resize: self.resize,
					filters: self.filters,
					init: {
						FilesAdded(up, files) {
							self.dialog = true;
							self.UploadingFile = files;
							self.filesUploaded = [];
							up.start();
						},
						BeforeUpload(up, file) {
							up.settings.url = self.url;
						},
						FileUploaded(up, file, result) {
							let response = JSON.parse(result.response);
							json_data_parse(response, 0);
							if (self.multiple) {
								self.filesUploaded.push(response.Files[0]);
							} else {
								self.filesUploaded = response;
							}
						},
						UploadProgress(up, file) {
							const target = self.UploadingFile.find(f => f.id === file.id);
							if (target) target.percent = file.percent;
						},
						UploadComplete(up, files) {
							self.uploadFile(self.filesUploaded.length > 0 ? self.filesUploaded : files)
							if (self.UploadingError.length === 0 && self.autoclose) {
								self.dialog = false;
							}
							self.loading = false;
						},
						Error(up, err) {
							self.loading = false;
							try {
								if (err.status === 500) {
									err.message = JSON.parse(err.response).message;
								}
							} catch (e) { }
							self.UploadingError.push(err);
							self.dialog = true;
						}
					}
				});
				uploader.init();
				this.uploader = uploader;
			},
			uploadFile(file) {
				const $this = this
				if (file.length > 0) {
					const fileIdList = file.map(item => item.FileID)
					ajaxCALL('/eorder/HinhAnhQuangCao_Insert', {
						FileID_List: fileIdList.join(','),
						LoaiAnh: $this.type
					}, (res) => {
						$this.$emit('reload')
					})
				}
			}
		}
	}
</script>