<template>
	<v-dialog v-model="dialog" max-width="650">
		<v-card>
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Tập tin minh chứng ({{ contractNo || "Chưa có số HĐ" }})
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
					:headers="headers"
					:items="attachedFiles"
					item-key="FILE_ID"
					hide-default-footer
					:items-per-page="-1"
					no-data-text="Không có tập tin đính kèm"
					class="elevation-1"
				>
					<template v-slot:item.FILE_NAME="{ item }">
						<a
							:href="getFileUrl(item)"
							target="_blank"
							class="text-decoration-none font-weight-medium"
						>
							<v-icon small color="primary" class="mr-1">mdi-file-document-outline</v-icon>
							{{ item.FILE_NAME }}
						</a>
					</template>

					<template v-slot:item.FILE_SIZE="{ item }">
						<span class="grey--text text-caption">
							{{ item.FILE_SIZE ? item.FILE_SIZE + " KB" : "-" }}
						</span>
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn
							icon
							x-small
							color="primary"
							:href="getFileUrl(item)"
							target="_blank"
							title="Tải về / Xem tập tin"
						>
							<v-icon small>mdi-download</v-icon>
						</v-btn>
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
				headers: [
					{ text: "Tên tập tin", value: "FILE_NAME" },
					{ text: "Dung lượng", value: "FILE_SIZE", width: 120, align: "center" },
					{ text: "Thao tác", value: "actions", sortable: false, width: 80, align: "center" }
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