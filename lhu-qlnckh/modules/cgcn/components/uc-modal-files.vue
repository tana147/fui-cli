<template>
	<v-dialog v-model="dialog" max-width="680">
		<v-card>
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Các file minh chứng Dự án / Hợp đồng
					<span v-if="contractNo" class="grey--text text--darken-2 font-weight-regular">
						({{ contractNo }})
					</span>
				</span>
				<v-spacer />
				<v-btn icon small @click="closeModal">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<v-data-table
					dense
					:headers="fileHeaders"
					:items="attachedFiles"
					item-key="FILE_ID"
					hide-default-footer
					:items-per-page="-1"
					no-data-text="Không có tập tin đính kèm"
					class="elevation-1 cgcn-file-table"
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
				</v-data-table>
			</v-card-text>

			<v-divider />

			<v-card-actions class="py-2 px-4">
				<v-spacer />
				<v-btn small text @click="closeModal">Đóng</v-btn>
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
		attachedFiles: {
			type: Array,
			default: () => []
		},
		contractNo: {
			type: String,
			default: ""
		},
		vSet: {
			type: Object,
			default: () => ({
				apiFile: "",
				urlReturnFile: ""
			})
		}
	},
	emits: ["input"],
	data() {
		return {
			fileHeaders: [
				{ text: "Tập tin minh chứng", value: "FILE_NAME" }
			]
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
		}
	},
	methods: {
		getFileUrl(file) {
			const baseUrl = (this.vSet && this.vSet.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
			return `${baseUrl}/FileData/${file.FILE_ID}`
		},
		closeModal() {
			this.dialog = false
		}
	}
	}
</script>