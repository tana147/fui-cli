<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<!-- Fixed Header Block: Thông tin học viên -->
		<div class="uc-student-info-bar mb-3 flex-shrink-0" v-if="studentDisplayId">
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

		<div v-if="effectiveDsRootProcess && effectiveDsRootProcess.length > 0" class="d-flex flex-column flex-grow-1 min-h-0" style="overflow: hidden;">
			<!-- Header hiển thị tên bước đang duyệt dưới dạng thanh ngang phẳng chuyên nghiệp - Cố định -->
			<v-card flat color="indigo" dark class="px-4 py-2 d-flex align-center justify-space-between mb-3 flex-shrink-0"
				style="min-height: 48px; border-radius: 4px;">
				<div class="subtitle-1 font-weight-bold d-flex align-center">
					<v-icon left>mdi-file-tree</v-icon>
					Bước duyệt: {{ activeRootStep.Step_Index || (selectedRootIndex + 1) }}./ {{ activeRootStep.Task_Name }}
				</div>
				<div class="d-flex align-center" style="gap: 8px;">
					<v-btn-toggle v-if="effectiveDsRootProcess.length > 1" v-model="selectedRootIndex" mandatory dense class="mr-2">
						<v-btn v-for="(r, rIdx) in effectiveDsRootProcess" :key="rIdx" small class="text-none font-weight-bold" @click="onLoadDetail(r.Flow_ID)">
							Bước {{ r.Step_Index || (rIdx + 1) }}
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
								<span class="d-flex align-center">
									<h4 class="text-body-1 font-weight-medium grey--text text--darken-4">
										{{ activeRootStep.Step_Index || (selectedRootIndex + 1) }}.{{ index + 1 }}./ {{ item.TASK_DETAIL_DESCRIPTION }}
									</h4>
								</span>

								<c-textarea-comp class="mt-2 mb-1" :item-des="item" :text-rules="textRules" :allow-edit="true"
									v-if="item.Task_Detail_Type === 'TEXT' || item.Task_Detail_Type === 'TEXTVIEW' || item.Task_Detail_Type === 'TEXTAREA'" />

								<c-file-comp :item-des="item" :item="item" :allow-upload="true" :api-file="effectiveApiFile" :url-read-file="effectiveUrlReadFile"
									@on-file-change="onFileChange($event, item)"
									v-if="item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW'" class="mt-2" />

								<div v-if="item.Task_Detail_Type === 'TEXTAREA | FUN'" class="mt-2">
									<div class="d-flex align-center justify-center" style="gap: 15px">
										<div style="flex-grow: 1;">
											<c-textarea-comp :item-des="item" :text-rules="textRules" :allow-edit="true" />
										</div>
										<v-btn color="warning" @click="checkTopicBtn(item.Text_Content)" class="mb-3">
											Kiểm tra trùng
										</v-btn>
									</div>
								</div>
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
				<v-btn color="success" dark @click="onSave(activeRootStep)" :loading="isSaving">
					<v-icon left>mdi-content-save</v-icon>
					Lưu thông tin
				</v-btn>
				<v-btn color="primary" dark @click="onCheckAll(detailProcess, activeRootStep)" :loading="isSavingAll">
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
				type: [String, Number],
				default: "",
			},
			studentInfo: {
				type: Object,
				default: () => ({}),
			},
			dsRootProcess: {
				type: Array,
				default: () => [],
			},
			apiFile: {
				type: String,
				default: "",
			},
			urlReadFile: {
				type: String,
				default: "",
			},
		},
		emits: ["on-reload"],
		data() {
			return {
				selectedRootIndex: 0,
				localDsRootProcess: [],
				detailProcess: [],
				textRules: [(v) => !!v || "Không được để trống"],
				isSaving: false,
				isSavingAll: false,
				isConfirmModalOpen: false,
				confirmStudentId: null,
				confirmProcessIdRequest: null,
				isChangeThesis: false,
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
			effectiveDsRootProcess() {
				return (this.dsRootProcess && this.dsRootProcess.length > 0) ? this.dsRootProcess : this.localDsRootProcess;
			},
			activeRootStep() {
				if (!this.effectiveDsRootProcess || this.effectiveDsRootProcess.length === 0) return {};
				return this.effectiveDsRootProcess[this.selectedRootIndex] || this.effectiveDsRootProcess[0] || {};
			},
			effectiveApiFile() {
				return this.apiFile || window.vueData?.v_Set?.apiFile || "https://file.lhu.edu.vn/qldetaisdh/upload/FileData";
			},
			effectiveUrlReadFile() {
				return this.urlReadFile || window.vueData?.v_Set?.urlReadFile || "https://file.lhu.edu.vn/qldetaisdh/";
			},
		},
		watch: {
			studentDisplayId: {
				immediate: true,
				async handler(newVal) {
					if (newVal) {
						this.selectedRootIndex = 0;
						if (!this.dsRootProcess || this.dsRootProcess.length === 0) {
							await this.fetchRootProcess();
						}
					} else {
						this.localDsRootProcess = [];
						this.detailProcess = [];
					}
				},
			},
			effectiveDsRootProcess: {
				immediate: true,
				async handler(val) {
					if (val && val.length > 0) {
						this.selectedRootIndex = 0;
						await this.onLoadDetail(val[0]?.Flow_ID);
					} else {
						this.detailProcess = [];
					}
				},
			},
		},
		methods: {
			getChipColor(status) {
				switch (status) {
					case "C":
						return "green darken-2";
					case "W":
						return "amber darken-2";
					case "P":
						return "blue darken-2";
					case "D":
						return "red darken-2";
					case "N":
						return "grey darken-1";
					default:
						return "primary";
				}
			},
			getChipColorText(status) {
				switch (status) {
					case "C":
						return "Đã duyệt";
					case "W":
						return "Chờ duyệt";
					case "P":
						return "Đang duyệt";
					case "D":
						return "Bị từ chối";
					case "N":
						return "Chưa duyệt";
					default:
						return "Đang duyệt";
				}
			},
			onFileChange(fileData, item) {
				if (item && fileData) {
					item.File_ID = fileData.File_ID;
					item.File_Name = fileData.File_Name;
					item.File_Type = fileData.File_Type;
					item.File_URL = fileData.File_URL;
					item.FILE_UPLOAD = fileData.FILE_UPLOAD || fileData;
				}
			},
			async fetchRootProcess() {
				if (!this.studentDisplayId) return;
				try {
					const data = await ajaxCALLPromise("/SDH_Get_RootProcessing", {
						StudentID: this.studentDisplayId,
						Process_Action: 2,
					});
					this.localDsRootProcess = Array.isArray(data) ? data : (data?.data || []);
				} catch (error) {
					console.error("Error fetchRootProcess:", error);
					this.localDsRootProcess = [];
				}
			},
			async onLoadDetail(Flow_ID) {
				if (!Flow_ID || Flow_ID <= 0) {
					this.detailProcess = [];
					return;
				}
				this.isChangeThesis = false;
				try {
					const res = await ajaxCALLPromise("/SDH_Get_DetailProcessing", {
						Flow_ID: Flow_ID,
					});
					const rawList = Array.isArray(res) ? res : (res?.data || []);
					this.detailProcess = rawList.map((item) => ({
						...item,
						FILE_UPLOAD: {
							File_ID: item.File_ID,
							File_Name: item.File_Name,
							File_Type: item.File_Type,
							File_URL: item.File_URL,
						},
						Flow_Detail_Status: item.Flow_Detail_Status === "C" || item.Flow_Detail_Status === true,
					}));
				} catch (error) {
					Vue.$toast.error(error?.responseJSON?.Message || "Lỗi tải chi tiết tiến trình", { position: "top" });
					console.error("Error onLoadDetail:", error);
					this.detailProcess = [];
				}
			},
			async onSave(root) {
				const payloadDetails = this.detailProcess.map((item) => ({
					Task_Detail_ID: item.TASK_DETAIL_ID,
					Text_Content: item.Text_Content !== null && typeof item.Text_Content === "string" ? item.Text_Content.trim() : (item.Text_Content ?? ""),
					File_Name: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_Name ?? item.File_Name ?? null : null,
					File_Type: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_Type ?? item.File_Type ?? null : null,
					File_URL: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_URL ?? item.File_URL ?? null : null,
					File_ID: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_ID ?? item.File_ID ?? null : null,
					Flow_Detail_Status: item.Flow_Detail_Status ? "C" : "W",
				}));

				this.isSaving = true;
				try {
					await ajaxCALLPromise("/FlowDetail_UpdateMulti", {
						Student_ID: this.studentDisplayId,
						Process_ID: root.Process_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || this.detailProcess[0]?.TASK_ID,
						JsonDetails: JSON.stringify(payloadDetails),
						IsApproveAll: 0,
					});
					Vue.$toast.success(`Cập nhật ${root.Task_Name} thành công`, { position: "top" });
				} catch (error) {
					Vue.$toast.error(error?.responseJSON?.Message || "Lỗi cập nhật", { position: "top" });
				} finally {
					this.isSaving = false;
				}
			},
			async onCheckAll(detail, root) {
				let validationPassed = true;
				for (const item of detail) {
					if (
						item.AllowNull === "0" &&
						item.Task_Detail_Type !== "FILE" &&
						item.Task_Detail_Type !== "FILEVIEW" &&
						(item.Text_Content === null || item.Text_Content === "") &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(`Mục "${item.TASK_DETAIL_DESCRIPTION}" chưa nhập nội dung`, { position: "top" });
						validationPassed = false;
						break;
					}
					if (
						item.AllowNull === "0" &&
						(item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") &&
						!item.FILE_UPLOAD?.File_ID &&
						!item.File_ID &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(`Mục "${item.TASK_DETAIL_DESCRIPTION}" chưa upload file`, { position: "top" });
						validationPassed = false;
						break;
					}
				}
				if (!validationPassed) return;

				detail.forEach((item) => (item.Flow_Detail_Status = true));

				const payloadDetails = detail.map((item) => ({
					Task_Detail_ID: item.TASK_DETAIL_ID,
					Text_Content: item.Text_Content !== null && typeof item.Text_Content === "string" ? item.Text_Content.trim() : (item.Text_Content ?? ""),
					File_Name: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_Name ?? item.File_Name ?? null : null,
					File_Type: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_Type ?? item.File_Type ?? null : null,
					File_URL: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_URL ?? item.File_URL ?? null : null,
					File_ID: (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") ? item.FILE_UPLOAD?.File_ID ?? item.File_ID ?? null : null,
					Flow_Detail_Status: "C",
				}));

				this.isSavingAll = true;
				try {
					await ajaxCALLPromise("/FlowDetail_UpdateMulti", {
						Student_ID: this.studentDisplayId,
						Process_ID: root.Process_ID,
						Flow_ID: root.Flow_ID,
						Task_ID: root.Children_Task_ID || detail[0]?.TASK_ID,
						JsonDetails: JSON.stringify(payloadDetails),
						IsApproveAll: 1,
					});
					Vue.$toast.success(`Duyệt thành công`, { position: "top" });

					const lastIndex = detail.length - 1 >= 0 ? detail.length - 1 : 0;
					if (detail[lastIndex]?.FN_Check === "fnChangeStudentProcess") {
						this.isChangeThesis = true;
						this.confirmStudentId = detail[lastIndex].Student_id || this.studentDisplayId;
						this.confirmProcessIdRequest = detail[lastIndex].Process_ID || root.Process_ID;
						this.isConfirmModalOpen = true;
					} else {
						this.$emit("on-reload");
					}
				} catch (error) {
					Vue.$toast.error(error?.responseJSON?.Message || "Lỗi duyệt", { position: "top" });
				} finally {
					this.isSavingAll = false;
				}
			},
			checkingStatus(item, root) {
				const nextStatus = !item.Flow_Detail_Status;
				const actionText = nextStatus ? "duyệt" : "hủy duyệt";

				if (nextStatus) {
					if (
						item.AllowNull === "0" &&
						item.Task_Detail_Type !== "FILE" &&
						item.Task_Detail_Type !== "FILEVIEW" &&
						(item.Text_Content === null || item.Text_Content === "") &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(`Mục "${item.TASK_DETAIL_DESCRIPTION}" chưa nhập nội dung`, { position: "top" });
						return;
					}
					if (
						item.AllowNull === "0" &&
						(item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") &&
						!item.FILE_UPLOAD?.File_ID &&
						!item.File_ID &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(`Mục "${item.TASK_DETAIL_DESCRIPTION}" chưa upload file`, { position: "top" });
						return;
					}
				}

				confirm({
					title: "Xác nhận duyệt",
					content: `Bạn có muốn ${actionText} mục "${item.TASK_DETAIL_DESCRIPTION}" này không?`,
					action: async () => {
						const statusName = nextStatus ? "C" : "P";
						try {
							await ajaxCALLPromise("/FlowDetail_UpdateStatus", {
								Student_ID: this.studentDisplayId,
								Process_ID: item.Process_ID || root.Process_ID,
								Flow_ID: item.FLOW_ID || root.Flow_ID,
								Task_ID: item.TASK_ID,
								Task_Detail_ID: item.TASK_DETAIL_ID,
								Flow_Detail_Status: statusName,
							});
							item.Flow_Detail_Status = nextStatus;
							Vue.$toast.success(`Cập nhật thành công`, { position: "top" });
						} catch (error) {
							Vue.$toast.error(error?.responseJSON?.Message || "Lỗi cập nhật", { position: "top" });
						}
					},
				});
			},
			async checkTopicBtn(TenDeTai) {
				try {
					const res = await ajaxCALLPromise("/Get_SimiliarPaper", { TenDeTai: TenDeTai });
					console.log("Similar topics", res);
				} catch (error) {
					console.error("Error checkTopicBtn", error);
				}
			},
		},
	}
</script>