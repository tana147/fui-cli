<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" max-width="1000px" scrollable persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="d-flex align-center flex-wrap">
						<v-icon color="primary" class="mr-2" size="20">mdi-history</v-icon>
						<span class="text-subtitle-1 font-weight-bold primary--text">Dữ liệu đăng ký cũ:</span>
						<span v-if="studentId || studentName" class="text-subtitle-1 font-weight-bold grey--text text--darken-3 ml-1">
							[{{ studentId }} - {{ studentName }}]
						</span>
						<v-chip v-if="DsOldView.length > 0" color="primary" x-small class="ml-2 font-weight-bold rounded-xs">
							{{ groupedBatches.length }} đợt ({{ DsOldView.length }} bước)
						</v-chip>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pa-4">
				<div v-if="loading" class="text-center py-8">
					<v-progress-circular indeterminate color="primary" size="32" />
					<div class="text-caption grey--text text--darken-1 mt-2">Đang tải dữ liệu tiến trình cũ...</div>
				</div>

				<c-empty-state
					v-else-if="DsOldView.length === 0"
					icon="mdi-history"
					text="Chưa có dữ liệu đăng ký cũ nào"
				/>

				<div v-else>
					<div v-for="(batch, bIdx) in groupedBatches" :key="'batch-' + bIdx" class="mb-4">
						<div class="d-flex align-center justify-space-between mb-2 pa-2 rounded-xs grey lighten-4 border">
							<div class="d-flex align-center flex-wrap">
								<v-icon color="primary" small class="mr-1">mdi-source-branch</v-icon>
								<span class="text-subtitle-2 font-weight-bold primary--text">
									Đợt {{ batch.batchTotal > 1 ? (batch.batchTotal - bIdx) : 1 }}
								</span>
								<span v-if="batch.lyDo" class="text-caption grey--text text--darken-2 ml-2">
									• Lý do: <b class="grey--text text--darken-4">{{ batch.lyDo }}</b>
								</span>
								<span v-if="batch.createdAt" class="text-caption grey--text text--darken-1 ml-2">
									• Thời gian: {{ formatDate(batch.createdAt) }}
								</span>
							</div>
							<v-chip x-small outlined color="primary" class="font-weight-bold">
								{{ batch.items.length }} bước
							</v-chip>
						</div>

						<v-expansion-panels v-model="batchPanels[bIdx]" accordion class="rounded-xs">
							<v-expansion-panel
								v-for="(item, stepIdx) in batch.items"
								:key="'step-' + item.Flow_ID"
								class="rounded-xs border mb-2"
							>
								<v-expansion-panel-header
									class="pa-3 py-2 grey lighten-5"
									@click="onLoadDetailFlow(item.Flow_ID)"
									disable-icon-rotate
								>
									<div class="d-flex align-center">
										<v-avatar size="22" color="primary" class="white--text text-caption font-weight-bold mr-2">
											{{ stepIdx + 1 }}
										</v-avatar>
										<span class="text-subtitle-2 font-weight-bold grey--text text--darken-3">
											{{ item.Task_Name }}
										</span>
									</div>

									<template v-slot:actions>
										<div class="d-flex align-center">
											<c-status-chip :status="item.Flow_Status" x-small class="mr-2" />
											<v-icon color="grey darken-1" size="18">mdi-chevron-down</v-icon>
										</div>
									</template>
								</v-expansion-panel-header>

								<v-expansion-panel-content class="pa-2 pt-3">
									<div v-if="loadingDetailId === item.Flow_ID" class="text-center py-4">
										<v-progress-circular indeterminate color="primary" size="24" />
										<div class="text-caption grey--text mt-1">Đang tải chi tiết nhiệm vụ...</div>
									</div>

									<div v-else-if="detailsByFlow[item.Flow_ID] && detailsByFlow[item.Flow_ID].length > 0">
										<c-detail-item-view
											v-for="(itemDes, indexDes) in detailsByFlow[item.Flow_ID]"
											:key="'detail-' + indexDes"
											:item="itemDes"
											:index="indexDes"
										/>
									</div>

									<div v-else class="text-center py-4 grey--text text-caption">
										Không có tiêu chí chi tiết nào cho bước này
									</div>
								</v-expansion-panel-content>
							</v-expansion-panel>
						</v-expansion-panels>
					</div>
				</div>
			</v-card-text>

			<v-card-actions class="pa-3">
				<v-spacer />
				<v-btn text class="rounded-xs" @click="close">Đóng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-view-old-process",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			studentItem: {
				type: Object,
				default: () => ({}),
			},
		},
		emits: ["input"],
		data() {
			return {
				loading: false,
				loadingDetailId: null,
				DsOldView: [],
				detailsByFlow: {},
				batchPanels: {},
			}
		},
		computed: {
			studentId() {
				return this.studentItem?.StudentID || ""
			},
			studentName() {
				return this.studentItem?.HoTen || `${this.studentItem?.HoSV || ""} ${this.studentItem?.TenSV || ""}`.trim()
			},
			groupedBatches() {
				if (!this.DsOldView || this.DsOldView.length === 0) return []

				const map = new Map()
				for (const item of this.DsOldView) {
					const batchId = item.Reset_ID || item.Batch_ID || "default"
					if (!map.has(batchId)) {
						map.set(batchId, {
							id: batchId,
							lyDo: item.LyDo || item.Reset_Reason || "",
							createdAt: item.Created_At || item.Reset_Date || null,
							items: [],
						})
					}
					map.get(batchId).items.push(item)
				}

				const batches = Array.from(map.values())
				const total = batches.length
				return batches.map((b) => ({
					...b,
					batchTotal: total,
				}))
			},
		},
		watch: {
			value(val) {
				if (val && this.studentId) {
					this.loadHistory()
				} else if (!val) {
					this.resetState()
				}
			},
		},
		methods: {
			formatDate(val) {
				if (!val) return ""
				if (typeof moment !== "undefined" && moment(val).isValid()) {
					return moment(val).format("DD/MM/YYYY HH:mm")
				}
				return val
			},

			resetState() {
				this.DsOldView = []
				this.detailsByFlow = {}
				this.batchPanels = {}
				this.loading = false
				this.loadingDetailId = null
			},

			async loadHistory() {
				this.loading = true
				try {
					const data = await ajaxCALLPromise("/Get_RootFlow_His", {
						StudentID: this.studentId,
					})
					this.DsOldView = Array.isArray(data) ? data : []
				} catch (error) {
					const msg = error?.responseJSON?.Message || error?.message || "Lỗi tải lịch sử"
					Vue.$toast.error(msg, { position: "top" })
					this.DsOldView = []
				} finally {
					this.loading = false
				}
			},

			async onLoadDetailFlow(flowId) {
				if (!flowId || this.detailsByFlow[flowId]) return

				this.loadingDetailId = flowId
				try {
					const data = await ajaxCALLPromise("/SDH_Get_FlowDetail_His", {
						Flow_ID: flowId,
					})
					this.$set(this.detailsByFlow, flowId, Array.isArray(data) ? data : [])
				} catch (error) {
					console.error("Lỗi tải chi tiết flow:", error)
					this.$set(this.detailsByFlow, flowId, [])
				} finally {
					this.loadingDetailId = null
				}
			},

			close() {
				this.$emit("input", false)
			},
		},
	}
</script>