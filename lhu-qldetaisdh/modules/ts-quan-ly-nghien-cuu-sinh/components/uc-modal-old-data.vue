<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" max-width="1100px" scrollable persistent>
		<v-card class="rounded-xs">
			<!-- Toolbar Header -->
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="d-flex align-center flex-wrap">
						<v-icon color="primary" class="mr-2" size="20">mdi-history</v-icon>
						<span class="text-subtitle-1 font-weight-bold primary--text">Dữ liệu lịch sử bước:</span>
						<span class="text-subtitle-1 font-weight-bold grey--text text--darken-3 ml-1">
							{{ stepTitle }}
						</span>
						<v-chip v-if="studentId || studentName" color="error" outlined small class="ml-2 font-weight-bold rounded-xs">
							{{ studentId }} - {{ studentName }}
						</v-chip>
						<v-chip v-if="detailList.length > 0" color="primary" x-small class="ml-2 font-weight-bold rounded-xs">
							{{ detailList.length }} mục
						</v-chip>
					</div>
				</template>
			</c-toolbar>

			<!-- Content Body -->
			<v-card-text class="pa-4">
				<!-- Loading State -->
				<div v-if="loading" class="text-center py-8">
					<v-progress-circular indeterminate color="primary" size="32" />
					<div class="text-caption grey--text text--darken-1 mt-2">Đang tải dữ liệu lịch sử...</div>
				</div>

				<!-- Empty State -->
				<c-empty-state
					v-else-if="detailList.length === 0"
					icon="mdi-history"
					text="Chưa có dữ liệu lịch sử cho bước này"
				/>

				<!-- Hiển thị dữ liệu có SubGroup Tabs (Chuyên đề, Tiểu luận, Bài báo...) -->
				<div v-else-if="subGroupList.length > 0">
					<v-tabs v-model="activeTab" background-color="grey lighten-4" color="primary" class="mb-3 text-none rounded-xs" grow dense>
						<v-tab v-for="(sub, idx) in subGroupList" :key="'old-tab-' + idx" class="text-none font-weight-bold">
							<v-icon left small>mdi-book-open-outline</v-icon>
							{{ sub.title }}
							<v-chip x-small class="ml-2 font-weight-bold" :color="activeTab === idx ? 'primary' : 'grey lighten-2'">
								{{ sub.items.length }}
							</v-chip>
						</v-tab>
					</v-tabs>

					<v-window v-model="activeTab">
						<v-window-item v-for="(sub, idx) in subGroupList" :key="'old-window-' + idx">
							<div class="pa-1">
								<c-detail-item-view
									v-for="(itemDes, idxItem) in sub.items"
									:key="'old-item-' + sub.id + '-' + idxItem"
									:item="itemDes"
									:index="sub.prefix ? sub.prefix + '.' + (idxItem + 1) : (idxItem + 1)"
								/>
							</div>
						</v-window-item>
					</v-window>
				</div>

				<!-- Hiển thị dữ liệu tuần tự khi không có SubGroup -->
				<div v-else class="pa-1">
					<c-detail-item-view
						v-for="(itemDes, indexDes) in detailList"
						:key="'old-flat-' + indexDes"
						:item="itemDes"
						:index="indexDes + 1"
					/>
				</div>
			</v-card-text>

			<v-divider />

			<!-- Actions Footer -->
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
		name: "uc-modal-old-data",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			flowId: {
				type: [Number, String],
				default: null,
			},
			activeStep: {
				type: Object,
				default: () => ({}),
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
				detailList: [],
				activeTab: 0,
			}
		},
		computed: {
			stepTitle() {
				return this.activeStep?.TASK_NAME || this.activeStep?.Task_Name || "Chi tiết nhiệm vụ"
			},
			studentId() {
				return this.studentItem?.StudentID || this.studentItem?.Student_ID || ""
			},
			studentName() {
				return this.studentItem?.HoTen || `${this.studentItem?.HoSV || ""} ${this.studentItem?.TenSV || ""}`.trim()
			},
			subGroupList() {
				if (!this.detailList || this.detailList.length === 0) return []

				const hasSubGroup = this.detailList.some(
					(item) => item.SubGroup !== null && item.SubGroup !== undefined && item.SubGroup !== ""
				)
				if (!hasSubGroup) return []

				const groups = {}
				const groupOrder = []

				this.detailList.forEach((item) => {
					const sg = item.SubGroup !== null && item.SubGroup !== undefined ? String(item.SubGroup) : "0"
					if (!groups[sg]) {
						groups[sg] = []
						groupOrder.push(sg)
					}
					groups[sg].push(item)
				})

				return groupOrder.map((sgKey) => {
					const numKey = parseInt(sgKey, 10)
					let title = `Nhóm ${sgKey}`
					let prefix = sgKey

					if (!isNaN(numKey) && numKey >= 1 && numKey <= 3) {
						title = `Chuyên đề ${numKey}`
						prefix = `CĐ ${numKey}`
					} else if (!isNaN(numKey) && numKey >= 4 && numKey <= 5) {
						title = `Tiểu luận tổng quan`
						prefix = `TL`
					} else if (!isNaN(numKey) && numKey >= 6) {
						title = `Bài báo ${numKey - 5}`
						prefix = `BB ${numKey - 5}`
					}

					return {
						id: sgKey,
						title: title,
						prefix: prefix,
						items: groups[sgKey],
					}
				})
			},
		},
		watch: {
			async value(val) {
				if (val && this.flowId) {
					await this.loadOldData()
				} else {
					this.detailList = []
					this.activeTab = 0
				}
			},
			async flowId(newVal) {
				if (this.value && newVal) {
					await this.loadOldData()
				}
			},
		},
		methods: {
			async loadOldData() {
				if (!this.flowId) return
				this.loading = true
				try {
					const res = await ajaxCALLPromise("/SDH_Get_FlowDetail_His", {
						Flow_ID: this.flowId,
					})
					this.detailList = (res || []).filter((item) => item.Task_Detail_Display === 1 || item.Task_Detail_Display === "1")
				} catch (error) {
					console.error("Lỗi tải dữ liệu lịch sử:", error)
					this.detailList = []
				} finally {
					this.loading = false
				}
			},

			close() {
				this.$emit("input", false)
			},
		},
	}
</script>