<template>
	<v-dialog v-model="dialog" max-width="750" persistent>
		<v-card class="rounded-xs">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Tập tin đính kèm quyết định
				</span>
				<v-spacer />
				<v-btn icon small @click="close">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<!-- Tóm tắt quyết định -->
				<div class="mb-3 pa-3 grey lighten-4 rounded-xs">
					<div class="mb-1">
						<span class="font-weight-medium">Số quyết định:</span>
						<span class="red--text font-weight-bold ml-1">
							{{ decisionDetail.MaSoQD || decisionItem.MaSoQD || "Chưa có" }}
						</span>
					</div>
					<div class="text-caption grey--text text--darken-2 mb-1">
						<span class="font-weight-medium">Ngày ban hành:</span>
						<span>{{ formatDate(decisionDetail) }}</span>
					</div>
					<div class="text-caption grey--text text--darken-2" v-if="decisionDetail.MoTaQD || decisionItem.MoTaQD">
						<span class="font-weight-medium">Mô tả:</span> {{ decisionDetail.MoTaQD || decisionItem.MoTaQD }}
					</div>
				</div>

				<!-- Tiêu đề và nút upload file -->
				<div class="d-flex align-center justify-space-between mb-2">
					<span class="font-weight-bold text-subtitle-2">
						Danh sách tập tin đính kèm ({{ attachedFiles.length }})
					</span>
					<div>
						<f-file-upload
							v-model="uploadPayload"
							label="Tải lên tập tin"
							color="primary"
							:filters="fileFilters"
							:url="apiFileUploadUrl"
							@input="onFileUpload"
						/>
					</div>
				</div>

				<!-- Bảng danh sách tập tin -->
				<v-data-table
					dense
					:headers="fileHeaders"
					:items="attachedFiles"
					item-key="FILE_ID"
					hide-default-footer
					:items-per-page="-1"
					no-data-text="Chưa có tập tin nào đính kèm"
					class="elevation-1 rounded-xs"
					:loading="loading"
				>
					<template v-slot:item.FILE_NAME="{ item }">
						<a
							:href="getFileUrl(item)"
							target="_blank"
							class="text-decoration-none font-weight-medium"
						>
							<v-icon small color="primary" class="mr-1">mdi-file-download-outline</v-icon>
							{{ item.FILE_NAME }}
						</a>
						<span v-if="item.FILE_SIZE" class="grey--text text-caption ml-1">
							({{ item.FILE_SIZE }} KB)
						</span>
					</template>

					<template v-slot:item.actions="{ item }">
						<div class="text-right">
							<v-btn
								icon
								x-small
								color="red darken-3"
								title="Xóa tập tin"
								@click="handleDeleteFile(item)"
							>
								<v-icon small>mdi-trash-can-outline</v-icon>
							</v-btn>
						</div>
					</template>
				</v-data-table>
			</v-card-text>

			<v-divider />

			<v-card-actions class="py-2 px-4">
				<v-spacer />
				<v-btn small text @click="close">Đóng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-files",
	props: {
		value: {
			type: Boolean,
			default: false
		},
		decisionItem: {
			type: Object,
			default: () => ({})
		},
		vSet: {
			type: Object,
			default: () => ({
				apiFile: "",
				urlReturnFile: ""
			})
		}
	},
	emits: ["input", "on-reload"],
	data() {
		return {
			loading: false,
			decisionDetail: {},
			attachedFiles: [],
			uploadPayload: null,
			fileHeaders: [
				{ text: "Tập tin", value: "FILE_NAME" },
				{ text: "Thao tác", value: "actions", align: "right", sortable: false, width: 80 }
			],
			fileFilters: {
				max_file_size: "15mb",
				mime_types: [{ title: "All files", extensions: "*" }]
			}
		}
	},
	computed: {
		dialog: {
			get() {
				return this.value
			},
			set(val) {
				this.$emit("input", val)
			}
		},
		apiFileUploadUrl() {
			return (this.vSet && this.vSet.apiFile) || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.apiFile) || "https://file.lhu.edu.vn/qlnckh/upload/FileData"
		}
	},
	watch: {
		value(val) {
			if (val && this.decisionItem && this.decisionItem.QDID) {
				this.fetchDecisionDetail()
			}
		}
	},
	methods: {
		formatDate(item) {
			if (!item || !item.NamQD) return "--"
			const day = item.NgayQD || "--"
			const month = item.ThangQD || "--"
			return `${day}/${month}/${item.NamQD}`
		},
		async fetchDecisionDetail() {
			this.loading = true
			try {
				const params = { QDID: this.decisionItem.QDID }
				const res = await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Get_ByID", params)
				if (Array.isArray(res) && res.length >= 2) {
					this.decisionDetail = (res[0] && res[0][0]) ? res[0][0] : {}
					this.attachedFiles = Array.isArray(res[1]) ? res[1] : []
				} else {
					this.attachedFiles = []
				}
			} finally {
				this.loading = false
			}
		},
		getFileUrl(item) {
			const baseUrl = (this.vSet && this.vSet.urlReturnFile) || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
			return `${baseUrl}/FileData/${item.FILE_ID}`
		},
		async onFileUpload(val) {
			if (!val || !val.Files || !val.Files.length) return
			const uploadedFile = val.Files[0]
			this.attachedFiles.push(uploadedFile)

			const dsFileId = this.attachedFiles.map(item => item.FILE_ID).join(",")
			const params = {
				QDID: this.decisionItem.QDID,
				DS_FileID: dsFileId
			}
			await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Upd_File", params)
			Vue.$toast.success("Tải tập tin thành công", { position: "top" })
			this.uploadPayload = null
			this.$emit("on-reload")
			this.fetchDecisionDetail()
		},
		handleDeleteFile(file) {
			confirm({
				title: `Bạn có chắc muốn xóa tập tin <b><i>${file.FILE_NAME}</i></b>?`,
				action: async () => {
					this.attachedFiles = this.attachedFiles.filter(item => item.FILE_ID !== file.FILE_ID)
					const dsFileId = this.attachedFiles.map(item => item.FILE_ID).join(",")
					const params = {
						QDID: this.decisionItem.QDID,
						DS_FileID: dsFileId
					}
					await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Upd_File", params)
					Vue.$toast.success("Xóa tập tin thành công", { position: "top" })
					this.$emit("on-reload")
					this.fetchDecisionDetail()
				}
			})
		},
		close() {
			this.dialog = false
		}
	}
	}
</script>
