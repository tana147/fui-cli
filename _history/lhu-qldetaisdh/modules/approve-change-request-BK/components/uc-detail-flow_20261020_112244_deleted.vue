<template>
	<div>
		<div class="title primary--text text-left">
			Học viên:
			<span class="red--text">
				[{{ studentDisplayId }}] {{ studentDisplayName }} [{{ studentClassId }}]
			</span>
		</div>

		<v-expansion-panels v-model="panel" accordion class="mt-2">
			<v-expansion-panel v-for="(itemRoot, indexRoot) in dsRootProcess" :key="indexRoot">
				<v-expansion-panel-header :step="indexRoot + 1" @click="fetchDetailProcess(itemRoot.Flow_ID)"
					:class="getChipColor(itemRoot.Flow_Status)" style="height: 48px" disable-icon-rotate>
					<div class="stepperStep">
						<h4 class="headerColorTxt">
							{{ indexRoot + 1 }}./ {{ itemRoot.Task_Name }}
						</h4>
					</div>
					<template v-slot:actions>
						<v-icon color="white">{{
							getStepIcon(itemRoot.Flow_Status)
							}}</v-icon>
					</template>
				</v-expansion-panel-header>
				<v-expansion-panel-content :step="indexRoot + 1">
					<div class="mt-3">
						<v-data-table :headers="[
                { text: 'Nội dung', value: 'NoiDung' },
                {
                  text: 'Duyệt',
                  value: 'Check',
                  align: 'center',
                  sortable: false,
                  width: '100',
                },
              ]" :items="detailProcess" hide-default-footer disable-pagination>
							<template v-slot:item.NoiDung="{ item, index }">
								<span class="namePadding">
									<h4 class="mt-3">
										{{ indexRoot + 1 }}.{{ index + 1 }}
										{{ item.TASK_DETAIL_DESCRIPTION }}
									</h4>
								</span>
								<c-textarea-comp class="mt-2" :itemDes="item" :textRules="textRules" :allowEdit="true"
									v-if="
                    item.Task_Detail_Type === 'TEXT' ||
                    item.Task_Detail_Type === 'TEXTVIEW'
                  " />
								<c-file-comp :itemDes="item" :item="item" :apiFile="apiFile" :urlReadFile="urlReadFile"
									:allowUpload="true" v-if="
                    item.Task_Detail_Type === 'FILE' ||
                    item.Task_Detail_Type === 'FILEVIEW'
                  " />
							</template>
							<template v-slot:item.Check="{ item }">
								<div class="d-flex justify-center align-center" style="width: 100%">
									<v-checkbox v-model="item.Flow_Detail_Status" @click.native.prevent.stop.capture="
                      checkingStatus(item, itemRoot)
                    " hide-details></v-checkbox>
								</div>
							</template>
						</v-data-table>

						<div>
							<div v-if="isSystemAdmin" class="d-flex align-center justify-end w-100 mt-4"
								style="gap: 10px">
								<v-btn color="indigo" dark @click="onCheckButNotSave(detailProcess, itemRoot)">
									<v-icon>mdi-check-bold</v-icon>
									Duyệt tất cả
								</v-btn>
							</div>

							<div v-else class="d-flex align-center justify-end w-100 mt-4" style="gap: 10px">
								<v-btn text color="info" @click="onSave(itemRoot)">
									<v-icon>mdi-content-save-edit</v-icon>
									Cập nhật chỉnh sửa
								</v-btn>
								<div>
									<v-btn color="success" @click="onCheckAll(detailProcess, itemRoot)">
										<v-icon>mdi-check-bold</v-icon>
										Lưu & Duyệt tất cả
									</v-btn>
								</div>
							</div>
						</div>
					</div>
				</v-expansion-panel-content>
			</v-expansion-panel>
		</v-expansion-panels>

		<uc-modal-confirm v-model="isConfirmModalOpen" :studentid="confirmStudentId" @on-reload="$emit('on-reload')" />
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
				dsRootProcess: [],
				detailProcess: [],
				similarTopic: [],
				confirmStudentId: null,
				isChangeThesis: false,
				panel: 0,
				textRules: [(v) => !!v || "Không được để trống"],
			};
		},
		computed: {
			studentDisplayId() {
				return this.studentId || this.studentInfo?.Student_ID || "";
			},
			studentDisplayName() {
				return this.studentInfo?.Student_Name || "";
			},
			studentClassId() {
				return this.studentInfo?.Class_ID || "";
			},
			isSystemAdmin() {
				return window.vueData?.user?.SystemRight === 1;
			},
			apiFile() {
				return window.vueData?.v_Set?.apiFile || "";
			},
			urlReadFile() {
				return window.vueData?.v_Set?.urlReadFile || "";
			},
		},
		watch: {
			studentId: {
				immediate: true,
				handler(newVal) {
					if (newVal && newVal !== "") {
						this.panel = 0;
						this.fetchRootProcess();
					}
				},
			},
			dsRootProcess(val) {
				if (val && val.length > 0) {
					this.fetchDetailProcess(val[0]?.Flow_ID);
				}
			},
		},
		methods: {
			// 1. Hàm hỗ trợ
			getChipColor(name) {
				switch (name) {
					case "W":
						return "info";
					case "C":
						return "success";
					case "P":
						return "blue light-2";
					case "R":
						return "error";
					default:
						return "secondary";
				}
			},
			getStepIcon(name) {
				switch (name) {
					case "w":
					case "W":
						return "mdi-information";
					case "C":
						return "mdi-check-bold";
					case "P":
						return "mdi-timer-sand";
					case "R":
						return "mdi-close-thick";
					default:
						return "water-boiler-alert";
				}
			},
	
			// 2. Hàm xử lý chức năng
			checkingStatus(item, root) {
				let validationPassed = true;
				if (item.Flow_Detail_Status === false) {
					if (
						item.Task_Detail_Type !== "FILE" &&
						item.Task_Detail_Type !== "FILEVIEW" &&
						(item.Text_Content === null || item.Text_Content === "") &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(
							`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa nhập nội dung`,
							{ position: "top" }
						);
						validationPassed = false;
					}
					if (
						(item.Task_Detail_Type === "FILE" ||
							item.Task_Detail_Type === "FILEVIEW") &&
						item.File_ID === null &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(
							`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa upload file`,
							{ position: "top" }
						);
						validationPassed = false;
					}
				}
	
				if (validationPassed) {
					confirm({
						title: "Xác nhận duyệt",
						content:
							item.Flow_Detail_Status === false
								? `Bạn có muốn duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này không?`
								: `Bạn có muốn hủy duyệt mục "${item.TASK_DETAIL_DESCRIPTION}" này?`,
						action: async () => {
							const newStatus =
								item.Flow_Detail_Status === false ? "C" : "P";
							await ajaxCALLPromise("/FlowDetail_UpdateStatus", {
								Student_ID: this.studentDisplayId,
								Process_ID: item.Process_ID,
								Flow_ID: item.FLOW_ID,
								Task_ID: item.TASK_ID,
								Task_Detail_ID: item.TASK_DETAIL_ID,
								Flow_Detail_Status: newStatus,
							});
							Vue.$toast.success(`Cập nhật thành công`, { position: "top" });
							item.Flow_Detail_Status = !item.Flow_Detail_Status;
						},
					});
				}
			},
			async onCheckButNotSave(detail, root) {
				let validationPassed = true;
				detail.forEach((item) => {
					if (
						item.AllowNull === "0" &&
						item.Task_Detail_Type !== "FILE" &&
						item.Task_Detail_Type !== "FILEVIEW" &&
						(item.Text_Content === null || item.Text_Content === "") &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(
							`Task "${item.TASK_DETAIL_DESCRIPTION}" chưa nhập nội dung`,
							{ position: "top" }
						);
						validationPassed = false;
					}
					if (
						item.AllowNull === "0" &&
						(item.Task_Detail_Type === "FILE" ||
							item.Task_Detail_Type === "FILEVIEW") &&
						item.File_ID === null &&
						item.Task_Detail_Type !== "FUN"
					) {
						Vue.$toast.error(
							`Task ${item.TASK_DETAIL_DESCRIPTION} chưa upload file`,
							{ position: "top" }
						);
						validationPassed = false;
					}
				});
				if (!validationPassed) return;
	
				detail.forEach((item) => (item.Flow_Detail_Status = true));
	
				for (const item of detail) {
					await ajaxCALLPromise("/FlowDetail_UpdateStatus", {
						Student_ID: this.studentDisplayId,
						Process_ID: item.Process_ID,
						Flow_ID: item.FLOW_ID,
						Task_ID: item.TASK_ID,
						Task_Detail_ID: item.TASK_DETAIL_ID,
						Flow_Detail_Status: "C",
					});
					item.Flow_Detail_Status = true;
				}
	
				Vue.$toast.success(`Duyệt thành công`, { position: "top" });
	
				const lastIndex =
					this.detailProcess.length - 1 >= 0
						? this.detailProcess.length - 1
						: 0;
	
				if (this.isChangeThesis) {
					Vue.$toast.error(`Học viên đã đổi/điều chỉnh đề tài`, {
						position: "top",
					});
					return;
				}
	
				if (detail[lastIndex]?.FN_Check === "fnChangeStudentProcess") {
					this.isChangeThesis = true;
					await ajaxCALLPromise("/SDH_StudentChangeThesis", {
						Process_ID: detail[lastIndex].Process_ID,
						Student_ID: detail[lastIndex].Student_id,
					});
	
					this.confirmStudentId = detail[lastIndex].Student_id;
					this.isConfirmModalOpen = true;
				}
	
				this.$emit("on-reload");
			},
			async onCheckAll(detail, root) {
				await this.onSave(root);
				await this.onCheckButNotSave(detail, root);
			},
	
			// 3. Hàm gọi API
			async fetchRootProcess() {
				if (!this.studentDisplayId) return;
				const data = await ajaxCALLPromise("/SDH_Get_RootProcessing", {
					StudentID: this.studentDisplayId,
					Process_Action: 2,
				});
				this.dsRootProcess = data || [];
			},
			async fetchDetailProcess(Flow_ID) {
				if (!Flow_ID || Flow_ID <= 0) return;
				this.isChangeThesis = false;
	
				const data = await ajaxCALLPromise("/SDH_Get_DetailProcessing", {
					Flow_ID: Flow_ID,
				});
	
				const promiseData = (data || []).map(async (item) => {
					if (
						item.Task_Detail_Type === "TEXTAREA | FUN" &&
						item.FN_Check === "fnCheckTenDeTai"
					) {
						this.checkSimilarTopic(item.Text_Content);
					}
	
					return {
						...item,
						FILE_UPLOAD: {
							File_ID: item.File_ID,
							File_Name: item.File_Name,
							File_Type: item.File_Type,
							File_URL: item.File_URL,
						},
						Flow_Detail_Status: false,
						TinhTrangNoHocPhi: 0,
					};
				});
	
				this.detailProcess = await Promise.all(promiseData);
			},
			async checkSimilarTopic(TenDeTai) {
				const data = await ajaxCALLPromise("/Get_SimiliarPaper", {
					TenDeTai: TenDeTai,
				});
				this.similarTopic = data || [];
			},
			async onSave(root) {
				let failCount = 0;
				for (const item of this.detailProcess) {
					try {
						await ajaxCALLPromise("/FlowDetail_UpdateData", {
							Student_ID: this.studentDisplayId,
							Process_ID: root.Process_ID,
							Flow_ID: item.FLOW_ID,
							Task_ID: item.TASK_ID,
							Task_Detail_ID: item.TASK_DETAIL_ID,
							Text_Content:
								item.Text_Content !== null
									? item.Text_Content.trim()
									: item.Text_Content,
							File_Name:
								item.Task_Detail_Type === "FILE" ||
									item.Task_Detail_Type === "FILEVIEW"
									? item.FILE_UPLOAD?.File_Name ?? null
									: null,
							File_Type:
								item.Task_Detail_Type === "FILE" ||
									item.Task_Detail_Type === "FILEVIEW"
									? item.FILE_UPLOAD?.File_Type ?? null
									: null,
							File_URL:
								item.Task_Detail_Type === "FILE" ||
									item.Task_Detail_Type === "FILEVIEW"
									? item.FILE_UPLOAD?.File_URL ?? null
									: null,
							File_ID:
								item.Task_Detail_Type === "FILE" ||
									item.Task_Detail_Type === "FILEVIEW"
									? item.FILE_UPLOAD?.File_ID ?? null
									: null,
						});
					} catch (e) {
						failCount++;
					}
				}
	
				if (failCount > 0) {
					Vue.$toast.error(`Cập nhật ${root.Task_Name} thất bại`, {
						position: "top",
					});
				} else {
					Vue.$toast.success(`Cập nhật ${root.Task_Name} thành công`, {
						position: "top",
					});
				}
			},
		},
	}
</script>