<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<!-- Fixed Header Block: Thông tin học viên -->
		<div class="uc-student-info-bar mb-3 flex-shrink-0" v-if="studentInfo">
			<div class="uc-student-info-item">
				<v-icon small class="mr-1 uc-student-icon">mdi-account-circle</v-icon>
				<span class="uc-student-label">Học viên:</span>
				<span class="uc-student-name">{{ studentDisplayName }}</span>
			</div>
			<div class="uc-student-info-item">
				<v-icon small class="mr-1 uc-student-icon">mdi-card-account-details-outline</v-icon>
				<span class="uc-student-id">{{ studentDisplayId }}</span>
			</div>
			<div class="uc-student-info-item">
				<v-icon small class="mr-1 uc-student-icon">mdi-school-outline</v-icon>
				<span class="uc-student-class">{{ studentClassId }}</span>
			</div>
		</div>

		<div v-if="dsRootProcess && dsRootProcess.length > 0" class="d-flex flex-column flex-grow-1 min-h-0" style="overflow: hidden;">
			<!-- Header hiển thị tên bước đang duyệt dưới dạng thanh ngang phẳng chuyên nghiệp - Cố định -->
			<v-card flat color="indigo" dark class="px-4 py-2 d-flex align-center justify-space-between mb-3 flex-shrink-0"
				style="min-height: 48px; border-radius: 4px;">
				<div class="subtitle-1 font-weight-bold d-flex align-center">
					<v-icon left>mdi-file-tree</v-icon>
					Bước duyệt: {{ activeRootStep.Task_Name }}
				</div>
				<div class="d-flex align-center" style="gap: 8px;">
					<v-btn-toggle v-if="dsRootProcess.length > 1" v-model="selectedRootIndex" mandatory dense class="mr-2">
						<v-btn v-for="(r, rIdx) in dsRootProcess" :key="rIdx" small class="text-none font-weight-bold" @click="fetchDetailProcess(r.Flow_ID)">
							Bước {{ rIdx + 1 }}
						</v-btn>
					</v-btn-toggle>
					<v-chip small :color="getChipColor(activeRootStep.Flow_Status)" dark class="font-weight-bold">
						{{ getChipColorText(activeRootStep.Flow_Status) }}
					</v-chip>
				</div>
			</v-card>

			<!-- Vùng nội dung chỉ cuộn danh sách tiêu chí -->
			<div class="flex-grow-1 min-h-0 pb-2" style="overflow-y: auto; overflow-x: hidden; padding-right: 2px;">
				<v-card outlined style="border: 1px solid #dbe7ee !important;">
					<div v-for="(item, index) in detailProcess" :key="index" class="py-4 px-4"
						style="border-bottom: 1px solid #eef2f5;">
						<v-row align="center" no-gutters>
							<!-- Cột bên trái: Nội dung mô tả và các component nhập liệu -->
							<v-col cols="10">
								<span class="uc-ar-name-padding d-flex align-center">
									<h4 class="text-body-1 font-weight-medium grey--text text--darken-4">
										{{ (selectedRootIndex + 1) }}.{{ index + 1 }}./ {{ item.TASK_DETAIL_DESCRIPTION }}
									</h4>
									<div v-if="item.Task_Detail_Type === 'CHECKBOX'" class="ml-3">
										<v-checkbox large color="success" :hint="item.Data_Exp" v-model="item.Text_Content"
											persistent-hint class="ma-0 pa-0" hide-details />
									</div>
								</span>

								<c-textarea-comp class="mt-2 mb-1" :item-des="item" :text-rules="textRules"
									:allow-edit="true"
									v-if="item.Task_Detail_Type === 'TEXT' || item.Task_Detail_Type === 'TEXTVIEW' || item.Task_Detail_Type === 'TEXTAREA'" />

								<c-file-comp :item-des="item" :item="item" :allow-upload="true" :api-file="apiFile"
									:url-read-file="urlReadFile"
									v-if="item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW'"
									class="mt-2" />
							</v-col>

							<!-- Cột bên phải: Nút duyệt Checkbox lớn dễ bấm -->
							<v-col cols="2" class="d-flex justify-center align-center">
								<div class="text-center">
									<div class="text-caption grey--text mb-1">Duyệt</div>
									<v-checkbox v-model="item.Flow_Detail_Status"
										@click.native.prevent.stop.capture="checkingStatus(item, activeRootStep)"
										hide-details color="success" class="ma-0 pa-0"></v-checkbox>
								</div>
							</v-col>
						</v-row>
					</div>
				</v-card>
			</div>

			<!-- Fixed Footer Action Bar: 2 nút luôn cố định ở dưới cùng -->
			<div class="d-flex align-center justify-end w-100 py-2 px-1 flex-shrink-0 mt-2" style="gap: 12px; border-top: 1px solid #eef2f5;">
				<v-btn color="success" dark @click="onSave(activeRootStep)">
					<v-icon left>mdi-content-save</v-icon>
					Lưu thông tin
				</v-btn>
				<v-btn color="primary" dark @click="onCheckAll(detailProcess, activeRootStep)">
					<v-icon left>mdi-check-all</v-icon>
					Duyệt & Lưu tất cả
				</v-btn>
			</div>
		</div>

		<v-card v-else flat class="d-flex align-center justify-center flex-grow-1" style="min-height: 200px;">
			<div class="text-center grey--text">Đang tải tiến trình...</div>
		</v-card>

		<uc-modal-confirm v-model="isConfirmModalOpen" :studentid="confirmStudentId" :processIdRequest="confirmProcessIdRequest" @on-reload="$emit('on-reload')" />
	</div>
</template>

<script>
	export default {
		name: "uc-detail-flow",
		props: {
			studentId: {
				type: String,
				default: "",
			},
			studentInfo: {
				type: Object,
				default: () => ({}),
			},
		},
		emits: ["on-reload"],
		data() {
			return {
				isConfirmModalOpen: false,
				confirmStudentId: "",
				confirmProcessIdRequest: null,
				isChangeThesis: false,
				selectedRootIndex: 0,
				textRules: [(v) => !!v || "Vui lòng nhập nội dung"],
				apiFile: "",
				urlReadFile: "",
				dsRootProcess: [],
				detailProcess: [],
				initialDetailProcess: [],
			};
		},
		computed: {
			studentDisplayId() {
				return this.studentInfo?.Student_ID || this.studentInfo?.StudentID || this.studentId || "";
			},
			studentDisplayName() {
				return this.studentInfo?.Student_Name || `${this.studentInfo?.HoSV || ''} ${this.studentInfo?.TenSV || ''}`.trim() || "";
			},
			studentClassId() {
				return this.studentInfo?.Class_ID || this.studentInfo?.LopID || "";
			},
			activeRootStep() {
				if (!this.dsRootProcess || this.dsRootProcess.length === 0) return {};
				return this.dsRootProcess[this.selectedRootIndex] || this.dsRootProcess[0];
			}
		},
		watch: {
			studentId: function (newVal) {
				if (newVal) {
					this.fetchRootProcess();
				} else {
					this.dsRootProcess = [];
					this.detailProcess = [];
				}
			},
			dsRootProcess: function (newVal) {
				if (newVal && newVal.length > 0) {
					this.selectedRootIndex = 0;
					this.fetchDetailProcess(newVal[0].Flow_ID);
				}
			},
		},
		mounted() {
			this.apiFile = window.vueData?.v_Set?.apiFile || "";
			this.urlReadFile = window.vueData?.v_Set?.urlReadFile || "";
			if (this.studentId) {
				this.fetchRootProcess();
			}
		},
		methods: {
			getChipColor(status) {
				switch (status) {
					case 'C': return 'green darken-2';
					case 'W': return 'amber darken-2';
					case 'P': return 'blue darken-2';
					case 'D': return 'red darken-2';
					case 'N': return 'grey darken-1';
					default: return 'primary';
				}
			},
			getChipColorText(status) {
				switch (status) {
					case 'C': return 'Đã duyệt';
					case 'W': return 'Chờ duyệt';
					case 'P': return 'Đang duyệt';
					case 'D': return 'Bị từ chối';
					case 'N': return 'Chưa duyệt';
					default: return 'Đang duyệt';
				}
			},
			isChanged(item) {
				const init = this.initialDetailProcess.find(x => x.TASK_DETAIL_ID === item.TASK_DETAIL_ID);
				if (!init) return true;
				return init.Text_Content !== item.Text_Content || init.File_ID !== item.File_ID;
			},
			async onSave(root) {
				if (!root || !root.Flow_ID) return;
				const changedItems = this.detailProcess.filter(item => this.isChanged(item));
				if (changedItems.length === 0) {
					Vue.$toast.info("Không có thông tin nào thay đổi", { position: "top" });
					return;
				}

				const payloadDetails = changedItems.map(item => ({
					Task_Detail_ID: item.TASK_DETAIL_ID,
					Text_Content: item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : (item.Text_Content ?? ''),
					File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
					File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
					File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
					File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
					Flow_Detail_Status: item.Flow_Detail_Status ? 'C' : 'W'
				}));

				try {
					await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
						Student_ID: this.studentDisplayId,
						Process_ID: root.Process_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || this.detailProcess[0]?.TASK_ID,
						JsonDetails: JSON.stringify(payloadDetails),
						IsApproveAll: 0
					});

					Vue.$toast.success("Lưu thông tin thành công", { position: "top" });
					this.initialDetailProcess = JSON.parse(JSON.stringify(this.detailProcess));
				} catch (error) {
					Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : "Lỗi lưu thông tin", { position: "top" });
				}
			},
			async onCheckAll(detail, root) {
				if (!root || !root.Flow_ID) return;
				confirm({
					title: "Duyệt tất cả",
					content: "Bạn có chắc chắn muốn duyệt và lưu tất cả các mục này không?",
					action: async () => {
						const payloadDetails = detail.map(item => ({
							Task_Detail_ID: item.TASK_DETAIL_ID,
							Text_Content: item.Text_Content && typeof item.Text_Content === 'string' ? item.Text_Content.trim() : (item.Text_Content ?? ''),
							File_Name: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Name ?? null) : null,
							File_Type: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_Type ?? null) : null,
							File_URL: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_URL ?? null) : null,
							File_ID: ['FILE', 'FILEVIEW'].includes(item.Task_Detail_Type) ? (item.File_ID ?? null) : null,
							Flow_Detail_Status: 'C'
						}));

						try {
							await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
								Student_ID: this.studentDisplayId,
								Process_ID: root.Process_ID,
								Flow_ID: root.Flow_ID,
								Task_ID: root.Children_Task_ID || detail[0]?.TASK_ID,
								JsonDetails: JSON.stringify(payloadDetails),
								IsApproveAll: 1
							});

							Vue.$toast.success("Duyệt tất cả thành công", { position: "top" });
							
							const lastIndex = detail.length - 1 >= 0 ? detail.length - 1 : 0;
							if (detail[lastIndex]?.FN_Check === "fnChangeStudentProcess") {
								this.confirmStudentId = detail[lastIndex].Student_id || this.studentDisplayId;
								this.confirmProcessIdRequest = detail[lastIndex].Process_ID || root.Process_ID;
								this.isConfirmModalOpen = true;
							} else {
								this.$emit("on-reload");
							}
						} catch (error) {
							Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : "Lỗi duyệt tất cả", { position: "top" });
						}
					}
				});
			},
			async checkingStatus(item, itemRoot) {
				if (!itemRoot || !itemRoot.Process_ID) return;
				confirm({
					title: "Xác nhận duyệt",
					content: item.Flow_Detail_Status === false
						? `Bạn có muốn duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này không?`
						: `Bạn có muốn hủy duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này?`,
					action: async () => {
						const newStatus = item.Flow_Detail_Status === false ? "C" : "P";
						try {
							await ajaxCALLPromise("/FlowDetail_UpdateStatus", {
								Student_ID: this.studentDisplayId,
								Process_ID: itemRoot.Process_ID,
								Flow_ID: item.FLOW_ID,
								Task_ID: item.TASK_ID,
								Task_Detail_ID: item.TASK_DETAIL_ID,
								Flow_Detail_Status: newStatus,
							});
							Vue.$toast.success("Cập nhật thành công", { position: "top" });
							item.Flow_Detail_Status = !item.Flow_Detail_Status;
							this.$emit("on-reload");
						} catch (error) {
							Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : "Lỗi cập nhật", { position: "top" });
						}
					}
				});
			},
			async fetchRootProcess() {
				if (!this.studentDisplayId) return;
				const data = await ajaxCALLPromise("/SDH_Get_RootProcessing", {
					StudentID: this.studentDisplayId,
					Process_Action: 5, // 5 = Đổi đề tài Tiến sĩ
				});
				this.dsRootProcess = data || [];
			},
			async fetchDetailProcess(Flow_ID) {
				if (!Flow_ID || Flow_ID <= 0) return;
				const data = await ajaxCALLPromise("/SDH_Get_DetailProcessing", {
					Flow_ID: Flow_ID,
				});

				this.detailProcess = (data || []).map((item) => ({
					...item,
					Flow_Detail_Status: item.Flow_Detail_Status === "C" || item.Flow_Detail_Status === true,
				}));
				this.initialDetailProcess = JSON.parse(JSON.stringify(this.detailProcess));
			},
		},
	}
</script>