<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" max-width="1000px" scrollable persistent>
		<v-card class="rounded-xs">
			<!-- Header Toolbar -->
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

			<!-- Content Body -->
			<v-card-text class="pa-4">
				<!-- Loading State -->
				<div v-if="loading" class="text-center py-8">
					<v-progress-circular indeterminate color="primary" size="32" />
					<div class="text-caption grey--text text--darken-1 mt-2">Đang tải dữ liệu tiến trình cũ...</div>
				</div>

				<!-- Empty State -->
				<c-empty-state
					v-else-if="DsOldView.length === 0"
					icon="mdi-history"
					text="Chưa có dữ liệu đăng ký cũ nào"
				/>

				<!-- Danh sách theo từng Đợt Reset -->
				<div v-else>
					<div v-for="(batch, bIdx) in groupedBatches" :key="'batch-' + bIdx" class="mb-4">
						<!-- Header Đợt Reset -->
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

						<!-- Danh sách các bước trong đợt -->
						<v-expansion-panels v-model="batchPanels[bIdx]" accordion class="rounded-xs">
							<v-expansion-panel
								v-for="(item, stepIdx) in batch.items"
								:key="'step-' + item.Flow_ID"
								class="rounded-xs border mb-2"
							>
								<!-- Header bước (Phong cách sáng sủa, thanh thoát) -->
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

								<!-- Chi tiết từng tiêu chí con bên trong -->
								<v-expansion-panel-content class="pa-2 pt-3">
									<!-- Loading chi tiết bước -->
									<div v-if="loadingDetailId === item.Flow_ID" class="text-center py-4">
										<v-progress-circular indeterminate color="primary" size="24" />
										<div class="text-caption grey--text mt-1">Đang tải chi tiết nhiệm vụ...</div>
									</div>

									<!-- Danh sách tiêu chí con dùng c-detail-item-view -->
									<div v-else-if="detailsByFlow[item.Flow_ID] && detailsByFlow[item.Flow_ID].length > 0">
										<c-detail-item-view
											v-for="(itemDes, indexDes) in detailsByFlow[item.Flow_ID]"
											:key="'detail-' + indexDes"
											:item="itemDes"
											:index="indexDes + 1"
										/>
									</div>

									<c-empty-state
										v-else
										icon="mdi-text-box-remove-outline"
										text="Không có tiêu chí chi tiết trong bước này"
									/>
								</v-expansion-panel-content>
							</v-expansion-panel>
						</v-expansion-panels>
					</div>
				</div>
			</v-card-text>

			<v-divider />

			<!-- Card Actions Footer -->
			<v-card-actions class="pa-3 grey lighten-4">
				<v-spacer />
				<v-btn color="primary" outlined class="rounded-xs text-none font-weight-medium" @click="close">
					<v-icon left small>mdi-close</v-icon>
					Đóng
				</v-btn>
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
				DsOldView: [],
				detailsByFlow: {},
				loading: false,
				loadingDetailId: null,
				batchPanels: {},
			}
		},
		computed: {
			studentId() {
				return this.studentItem?.StudentID || this.studentItem?.Student_ID || ""
			},
			studentName() {
				return this.studentItem?.HoTen || `${this.studentItem?.HoSV || ""} ${this.studentItem?.TenSV || ""}`.trim()
			},
			groupedBatches() {
				if (!this.DsOldView || this.DsOldView.length === 0) return []

				const groups = {}
				const batchKeys = []

				this.DsOldView.forEach((item) => {
					const key = item.Process_Student_ID ? `PS_${item.Process_Student_ID}` : (item.Created_At || "DEFAULT")
					if (!groups[key]) {
						groups[key] = {
							key: key,
							processStudentId: item.Process_Student_ID,
							lyDo: item.LyDo || "",
							createdAt: item.Created_At,
							items: [],
						}
						batchKeys.push(key)
					}
					groups[key].items.push(item)
				})

				return batchKeys.map((key, idx) => ({
					batchIndex: idx + 1,
					batchTotal: batchKeys.length,
					...groups[key],
				}))
			},
		},
		watch: {
			async value(val) {
				if (val && this.studentId) {
					this.loading = true
					this.detailsByFlow = {}
					this.batchPanels = {}
					try {
						const res = await ajaxCALLPromise("/Get_RootFlow_His", {
							StudentID: this.studentId,
						})
						this.DsOldView = res || []
					} catch (err) {
						console.error("Lỗi tải tiến trình lịch sử:", err)
						this.DsOldView = []
					} finally {
						this.loading = false
					}
				} else {
					this.DsOldView = []
					this.detailsByFlow = {}
					this.batchPanels = {}
				}
			},
		},
		methods: {
			async onLoadDetailFlow(flowID) {
				if (!flowID) return
				if (this.detailsByFlow[flowID]) return // Đã nạp rồi thì không nạp lại

				this.loadingDetailId = flowID
				try {
					const res = await ajaxCALLPromise("/SDH_Get_FlowDetail_His", {
						Flow_ID: flowID,
					})
					this.$set(this.detailsByFlow, flowID, res || [])
				} catch (err) {
					console.error("Lỗi tải chi tiết bước:", err)
					this.$set(this.detailsByFlow, flowID, [])
				} finally {
					this.loadingDetailId = null
				}
			},

			formatDate(val) {
				if (!val) return ""
				if (typeof moment !== "undefined") {
					const m = moment(val)
					if (m.isValid()) return m.format("DD/MM/YYYY HH:mm")
				}
				return val
			},

			close() {
				this.$emit("input", false)
			},
		},
	}
</script>