<template>
	<div class="mb-4">
		<!-- Trạng thái đã upload file -->
		<div v-if="hasUploadedFile" class="d-flex align-center pa-2 border rounded bg-white mb-2"
			style="border: 1px solid #dbe7ee !important; gap: 12px; max-width: 450px; width: 100%;">
			<v-icon large :color="getFileIcon(uploadedFileName).color">
				{{ getFileIcon(uploadedFileName).icon }}
			</v-icon>
			<div class="flex-grow-1 overflow-hidden">
				<a :href="fileDownloadUrl" target="_blank"
					class="text-decoration-none d-block text-body-2 font-weight-bold text-truncate text--primary mb-0">
					{{ uploadedFileName }}
				</a>
				<span class="text-caption grey--text">{{ getFileTypeLabel(uploadedFileType) }}</span>
			</div>
			<div class="d-flex align-center" style="gap: 4px;">
				<v-btn icon small :href="fileDownloadUrl" target="_blank" color="primary">
					<v-icon small>mdi-download</v-icon>
				</v-btn>
				<v-btn icon small
					v-if="allowUpload || (lock !== 0 && item.Flow_Status !== 'C' && (item.Flow_Status === 'W' || item.Flow_Status === 'P') && itemDes.Task_Detail_Type !== 'FILEVIEW')"
					color="error" @click="deleteFile">
					<v-icon small>mdi-delete-outline</v-icon>
				</v-btn>
			</div>
		</div>

		<!-- Trạng thái chưa upload file -->
		<div v-else class="d-flex align-center pa-3 rounded-sm mb-2"
			style="border: 1.5px dashed #cfd8dc !important; background: #fafafa; gap: 12px; max-width: 450px; width: 100%;">
			<v-icon color="grey lighten-1">mdi-cloud-upload-outline</v-icon>
			<span class="text-caption grey--text text--darken-1 font-weight-medium">Chưa có file nào được tải lên</span>
		</div>

		<!-- Nút Upload File -->
		<div v-if="allowUpload || (lock !== 0 && item.Flow_Status !== 'C' && (item.Flow_Status === 'W' || item.Flow_Status === 'P') && itemDes.Task_Detail_Type !== 'FILEVIEW')"
			class="mt-2">
			<f-file-upload label="Chọn file tải lên" @input="onFileUpload" :url="uploadUrl"
				:filters="fileRules" color="v-btn--outlined v-size--default success--text" />
		</div>

		<p class="red--text mt-1 mb-0" v-if="itemDes.Task_Help !== null">
			<i>{{ itemDes.Task_Help }}</i>
		</p>
	</div>
</template>

<script>
	export default {
		name: "c-file-comp",
		props: {
			itemDes: { type: Object, default: () => ({}) },
			textRules: { type: Array, default: () => [] },
			item: { type: Object, default: () => ({}) },
			lock: { type: [Number, String], default: 1 },
			fileRule: { type: Object, default: () => ({}) },
			apiFile: { type: String, default: "" },
			urlReadFile: { type: String, default: "" },
			allowUpload: { type: Boolean, default: false }
		},
		emits: ["on-file-change"],
		data() {
			return {};
		},
		computed: {
			hasUploadedFile() {
				return !!(this.itemDes?.File_ID || this.itemDes?.FILE_UPLOAD?.File_ID);
			},
			uploadedFileName() {
				return this.itemDes?.File_Name || this.itemDes?.FILE_UPLOAD?.File_Name || '';
			},
			uploadedFileUrl() {
				return this.itemDes?.File_URL || this.itemDes?.FILE_UPLOAD?.File_URL || '';
			},
			uploadedFileType() {
				return this.itemDes?.File_Type || this.itemDes?.FILE_UPLOAD?.File_Type || this.uploadedFileName;
			},
			fileDownloadUrl() {
				const base = (this.readUrl || '').replace(/\/+$/, '');
				const path = (this.uploadedFileUrl || '').replace(/^\/+/, '');
				return base && path ? `${base}/${path}` : (base || path || '#');
			},
			fileRules() {
				const ext = (typeof this.itemDes?.AllowFileType === 'string' && this.itemDes.AllowFileType)
					? this.itemDes.AllowFileType.toLowerCase().replace(/\|/g, ',')
					: 'jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg';
				return {
					max_file_size: '80Mb',
					mime_types: [
						{
							title: 'All files',
							extensions: ext,
						},
					],
				};
			},
			uploadUrl() {
				return this.apiFile || window.vueData?.v_Set?.apiFile || "https://file.lhu.edu.vn/qldetaisdh/upload/FileData";
			},
			readUrl() {
				return this.urlReadFile || window.vueData?.v_Set?.urlReadFile || "https://file.lhu.edu.vn/qldetaisdh/";
			},
		},
		methods: {
			onFileUpload(val) {
				if (!val) return;
				const file = (val.Files && val.Files[0]) ? val.Files[0] : (Array.isArray(val) ? val[0] : val);
				if (!file) return;

				const fileid = file.FILE_ID ?? file.File_ID ?? file.id ?? null;
				const filename = file.FILE_NAME ?? file.File_Name ?? file.name ?? null;
				const contenttype = file.FILE_CONTENTTYPE ?? file.File_Type ?? file.type ?? null;
				const url = file.FILE_URL ?? file.File_URL ?? file.url ?? null;
				const size = file.FILE_SIZE ?? file.File_Size ?? file.size ?? null;

				if (!fileid && !url && !filename) return;

				if (this.itemDes) {
					this.itemDes.File_ID = fileid;
					this.itemDes.File_Name = filename;
					this.itemDes.File_Type = contenttype;
					this.itemDes.File_URL = url;
					this.itemDes.FILE_UPLOAD = {
						File_ID: fileid,
						File_Name: filename,
						File_Type: contenttype,
						File_URL: url,
						File_Size: size,
					};
				}

				window.unsavedUploadedFiles = window.unsavedUploadedFiles || [];
				if (fileid && !window.unsavedUploadedFiles.includes(fileid)) {
					window.unsavedUploadedFiles.push(fileid);
				}

				this.$emit('on-file-change', this.itemDes);
			},
			deleteFile() {
				if (this.itemDes) {
					this.itemDes.File_ID = null;
					this.itemDes.File_URL = null;
					this.itemDes.File_Name = null;
					this.itemDes.File_Type = null;
					this.itemDes.FILE_UPLOAD = null;
				}
				this.$emit('on-file-change', this.itemDes);
			},
			getFileIcon(fileName) {
				if (!fileName) return { icon: 'mdi-file-document-outline', color: 'grey' };
				const ext = fileName.split('.').pop().toLowerCase();
				switch (ext) {
					case 'pdf': return { icon: 'mdi-file-pdf-box', color: 'red darken-1' };
					case 'doc':
					case 'docx': return { icon: 'mdi-file-word-box', color: 'blue darken-2' };
					case 'xls':
					case 'xlsx': return { icon: 'mdi-file-excel-box', color: 'green darken-2' };
					case 'jpg':
					case 'jpeg':
					case 'png':
					case 'gif': return { icon: 'mdi-file-image-outline', color: 'purple darken-1' };
					default: return { icon: 'mdi-file-document-outline', color: 'grey darken-1' };
				}
			},
			getFileTypeLabel(fileType) {
				if (!fileType) return 'Tệp tin';
				const typeLower = fileType.toLowerCase();
				if (typeLower.includes('pdf')) return 'Tài liệu PDF';
				if (typeLower.includes('word') || typeLower.includes('doc') || typeLower.endsWith('.doc') || typeLower.endsWith('.docx')) return 'Tài liệu Word';
				if (typeLower.includes('sheet') || typeLower.includes('excel') || typeLower.endsWith('.xls') || typeLower.endsWith('.xlsx')) return 'Bảng tính Excel';
				if (typeLower.includes('image') || typeLower.includes('png') || typeLower.includes('jpg') || typeLower.includes('jpeg')) return 'Hình ảnh';
				return 'Tệp tin';
			}
		},
	}
</script>