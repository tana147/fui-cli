<template>
	<v-dialog v-model="dialog" max-width="650" persistent>
		<v-card class="rounded-xs">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Thông tin quyết định khen thưởng
				</span>
				<v-spacer />
				<v-btn icon small @click="close">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<div class="mb-3 pa-3 grey lighten-4 rounded-xs">
					<div class="mb-1">
						<span class="font-weight-medium">Số quyết định:</span>
						<span class="red--text font-weight-bold ml-1">
							{{ decisionInfo.MaSoQD || "Chưa có số QĐ" }}
						</span>
					</div>
					<div class="text-caption grey--text text--darken-2 mb-1">
						<span class="font-weight-medium">Ngày ban hành:</span>
						<span>{{ formatDate(decisionInfo) }}</span>
					</div>
					<div class="text-caption grey--text text--darken-2" v-if="decisionInfo.MoTaQD">
						<span class="font-weight-medium">Mô tả:</span> {{ decisionInfo.MoTaQD }}
					</div>
				</div>

				<div class="font-weight-bold text-subtitle-2 mb-2">
					Danh sách tập tin đính kèm quyết định ({{ attachedFiles.length }})
				</div>

				<v-data-table
					dense
					:headers="fileHeaders"
					:items="attachedFiles"
					item-key="FILE_ID"
					hide-default-footer
					:items-per-page="-1"
					no-data-text="Không có tập tin đính kèm"
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
		name: "uc-modal-decision-detail",
	props: {
		value: {
			type: Boolean,
			default: false
		},
		qdid: {
			type: [Number, String],
			default: 0
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
			loading: false,
			decisionInfo: {},
			attachedFiles: [],
			fileHeaders: [
				{ text: "Tập tin đính kèm", value: "FILE_NAME" }
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
	watch: {
		value(val) {
			if (val && this.qdid) {
				this.fetchDecisionDetail()
			}
		}
	},
	methods: {
		async fetchDecisionDetail() {
			this.loading = true
			try {
				const params = { QDID: this.qdid }
				const res = await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Get_ByID", params)
				if (Array.isArray(res) && res.length >= 2) {
					this.decisionInfo = (res[0] && res[0][0]) ? res[0][0] : {}
					this.attachedFiles = Array.isArray(res[1]) ? res[1] : []
				} else {
					this.decisionInfo = {}
					this.attachedFiles = []
				}
			} finally {
				this.loading = false
			}
		},
		formatDate(item) {
			if (!item || !item.NamQD) return "--"
			const day = item.NgayQD || "--"
			const month = item.ThangQD || "--"
			return `${day}/${month}/${item.NamQD}`
		},
		getFileUrl(item) {
			const baseUrl = (this.vSet && this.vSet.urlReturnFile) || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
			return `${baseUrl}/FileData/${item.FILE_ID}`
		},
		close() {
			this.dialog = false
		}
	}
	}
</script>