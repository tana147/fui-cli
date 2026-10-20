<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="400px" persistent>
		<v-card>
			<v-card-title class="d-block">
				<div class="d-flex align-center justify-center">
					<v-icon color="primary" x-large>mdi-help-circle-outline</v-icon>
				</div>
				<div class="d-flex align-center justify-center">Đồng bộ dữ liệu quy trình mới</div>
			</v-card-title>

			<v-card-text>
				<v-container class="text-center">
					<h3 class="font-weight-medium black--text">
						Bạn có muốn đồng bộ dữ liệu từ quy trình cũ sang quy trình mới cho học viên <i
							class="mssvText">{{ studentid }}</i> không?
					</h3>
					<v-select class="mt-6 pt-2" v-model="loaiDieuChinh" :items="loaiDieuChinhList"
						label="Loại điều chỉnh" item-text="text" item-value="value" dense outlined />
				</v-container>
			</v-card-text>

			<v-card-actions class="justify-center">
				<v-btn color="primary" :loading="loading" @click="confirmFunc">Xác nhận</v-btn>
				<v-btn color="error" :disabled="loading" @click="closeModal">Hủy</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-confirm",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			studentid: {
				type: String,
				default: "",
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				loading: false,
				DanhSachDoiDeTai: [],
				StudentProcList: [],
				DS_OldRootProcess: [],
				DS_NewRootProcess: [],
				loaiDieuChinh: 1,
				loaiDieuChinhList: [
					{ text: "Đổi/Điều chỉnh tên đề tài", value: 1 },
					{ text: "Đổi/Điều chỉnh GVHD", value: 2 },
					{ text: "Đổi tên đề tài và GVHD", value: 3 },
				],
			};
		},
		computed: {
			dialog: {
				get() {
					return this.value;
				},
				set(val) {
					this.$emit("input", val);
				},
			},
		},
		methods: {
			async confirmFunc() {
				if (!this.studentid) {
					Vue.$toast.error("Thiếu mã học viên", { position: "top" });
					return;
				}
				this.loading = true;
				try {
					await this.onloadDoiDeTaiDaDuyet();
					const StudentInfo = this.DanhSachDoiDeTai[0];
	
					if (!StudentInfo) {
						Vue.$toast.error("Không tìm thấy tên đề tài mới cho học viên này", { position: "top" });
						return;
					}
	
					await this.onLoadStudentPocess(this.studentid);
					if (this.StudentProcList.length === 0 || this.StudentProcList.length !== 2) {
						Vue.$toast.error("Số lượng quy trình của học viên không hợp lệ", { position: "top" });
						return;
					}
	
					const ProcOldTree = this.StudentProcList.find((item) => item.Process_Student_Status === "X");
					const ProcNewTree = this.StudentProcList.find((item) => item.Process_Student_Status !== "X");
	
					if (!ProcOldTree || !ProcNewTree) {
						Vue.$toast.error("Không tìm thấy quy trình cũ hoặc mới cho học viên này", { position: "top" });
						return;
					}
	
					this.DS_OldRootProcess = await this.onLoadChangeTopicRoot(ProcOldTree.Process_Student_ID, this.studentid);
					this.DS_NewRootProcess = await this.onLoadChangeTopicRoot(ProcNewTree.Process_Student_ID, this.studentid);
	
					if (this.DS_OldRootProcess.length === 0 || this.DS_NewRootProcess.length === 0) {
						Vue.$toast.error("Không tìm thấy root flow cho học viên này", { position: "top" });
						return;
					}
	
					this.DS_OldRootProcess = this.DS_OldRootProcess.filter(
						(item) => item.Flow_Status === "C" || item.Flow_Status === "P" || item.Task_Description === "signForDefendThesis"
					);
	
					if (this.DS_OldRootProcess.length === 0 || this.DS_NewRootProcess.length === 0) {
						Vue.$toast.error("Không tìm thấy root flow cho học viên này", { position: "top" });
						return;
					}
	
					for (const oldRoot of this.DS_OldRootProcess) {
						let oldFlowDetail = await this.onLoadFlowDetailOldTree(oldRoot.Flow_ID);
						let newFlowDetail;
						const sequence = this.DS_NewRootProcess.find((item) => item.SEQ === oldRoot.SEQ);
	
						if (sequence) {
							newFlowDetail = await this.onLoadFlowDetailNewTree(sequence.Flow_ID);
	
							oldFlowDetail.forEach((item) => {
								newFlowDetail.find((newItem) => {
									if (item.Task_Detail_ID === newItem.Task_Detail_ID) {
										if (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW") {
											newItem.File_ID = item.File_ID;
											newItem.File_Name = item.File_Name;
											newItem.File_Type = item.File_Type;
											newItem.File_URL = item.File_URL;
										} else if ((this.loaiDieuChinh === 3 || this.loaiDieuChinh === 2) && newItem.Task_Detail_ID === 47) {
											newItem.Text_Content = StudentInfo.Thesises_Prof1_New;
										} else if ((this.loaiDieuChinh === 3 || this.loaiDieuChinh === 2) && newItem.Task_Detail_ID === 55) {
											newItem.Text_Content = StudentInfo.Thesises_Prof2_New;
										} else if ((this.loaiDieuChinh === 3 || this.loaiDieuChinh === 2) && newItem.Task_Detail_ID === 60) {
											newItem.Text_Content = StudentInfo.Thesises_Prof1_New;
										} else if ((this.loaiDieuChinh === 3 || this.loaiDieuChinh === 2) && newItem.Task_Detail_ID === 62) {
											newItem.Text_Content = StudentInfo.Thesises_Prof2_New;
										} else if ((this.loaiDieuChinh === 1 || this.loaiDieuChinh === 3) && newItem.Task_Detail_ID === 119) {
											newItem.Text_Content = StudentInfo.Thesis_Name_New;
										} else if ((this.loaiDieuChinh === 1 || this.loaiDieuChinh === 3) && newItem.Task_Detail_ID === 59) {
											newItem.Text_Content = StudentInfo.Thesis_Name_New;
										} else if ((this.loaiDieuChinh === 1 || this.loaiDieuChinh === 3) && newItem.Task_Detail_ID === 46) {
											newItem.Text_Content = StudentInfo.Thesis_Name_New;
										} else {
											newItem.Text_Content = item.Text_Content;
										}
									}
								});
							});
	
							const arrFilter = newFlowDetail.filter(
								(item) => (item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? item.File_ID : item.Text_Content)
							);
							newFlowDetail = arrFilter;
	
							let checkStatus = oldFlowDetail.filter(
								(item) => item.FN_Check === "fnCheckDeTaiDaDangKy" || item.Flow_Detail_Status !== "W"
							);
							if (checkStatus.length > 0) {
								await this.onUpdateFlowDetail(newFlowDetail, StudentInfo.Student_ID, oldRoot);
							}
	
							checkStatus = oldFlowDetail.filter((item) => item.Flow_Detail_Status === "C");
							if (checkStatus.length > 0) {
								await this.onUpdateStatusFlow(newFlowDetail, StudentInfo.Student_ID, oldRoot, "C");
							}
	
							checkStatus = oldFlowDetail.filter((item) => item.Flow_Detail_Status === "P");
							if (checkStatus.length > 0) {
								await this.onUpdateStatusFlow(newFlowDetail, StudentInfo.Student_ID, oldRoot, "P");
							}
	
							if (this.loaiDieuChinh === 1 || this.loaiDieuChinh === 3) {
								await this.onUpdateTenDeTaiHoiDong(StudentInfo.Student_ID, StudentInfo.Thesis_Name_New);
							}
						} else {
							Vue.$toast.error("Không tìm thấy flow mới cho học viên này", { position: "top" });
							return;
						}
					}
	
					Vue.$toast.success("Đổi đề tài và cập nhật dữ liệu thành công", { position: "top" });
					this.$emit("on-reload");
					this.closeModal();
				} catch (error) {
					console.error("Error loading data:", error);
				} finally {
					this.loading = false;
				}
			},
	
			async onUpdateTenDeTaiHoiDong(studentId, tenDeTai) {
				await ajaxCALLPromise("/HoiDong_Udp_TenDeTai", {
					Student_ID: studentId,
					TenDeTaiMoi: tenDeTai,
				});
			},
	
			async onloadDoiDeTaiDaDuyet() {
				const res = await ajaxCALLPromise("/SDH_DoiDeTai_FlowDetail", { StudentID: this.studentid });
				this.DanhSachDoiDeTai = (res || []).map((item, index) => ({
					...item,
					STT: index + 1,
				}));
			},
	
			async onLoadStudentPocess(studentId) {
				const res = await ajaxCALLPromise("/Student_Process_Get", {
					Student_ID: studentId,
					IsFull: 0,
				});
				this.StudentProcList = res || [];
			},
	
			async onLoadChangeTopicRoot(processStudentId, studentId) {
				const res = await ajaxCALLPromise("/Get_RootFlow", {
					Process_Student_ID: processStudentId,
					Process_Tree: 1,
					StudentID: studentId,
				});
				return res || [];
			},
	
			async onLoadFlowDetailOldTree(flowId) {
				const res = await ajaxCALLPromise("/Get_FlowDetail_OldTree", { Flow_ID: flowId });
				return res || [];
			},
	
			async onLoadFlowDetailNewTree(flowId) {
				const res = await ajaxCALLPromise("/SDH_Get_FlowDetail", { Flow_ID: flowId });
				return res || [];
			},
	
			async onUpdateFlowDetail(arr, studentId, root) {
				for (const item of arr) {
					await ajaxCALLPromise("/FlowDetail_UpdateData", {
						Student_ID: studentId,
						Process_ID: root.PROCESS_ID,
						Flow_ID: item.Flow_ID,
						Task_ID: item.Task_ID,
						Task_Detail_ID: item.Task_Detail_ID,
						Text_Content: item.Text_Content !== null ? item.Text_Content.trim() : item.Text_Content,
						File_Name: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? item.File_Name ?? null : null,
						File_Type: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? item.File_Type ?? null : null,
						File_URL: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? item.File_URL ?? null : null,
						File_ID: item.Task_Detail_Type === "FILE" || item.Task_Detail_Type === "FILEVIEW" ? item.File_ID ?? null : null,
					});
				}
			},
	
			async onUpdateStatusFlow(arr, studentId, root, status) {
				for (const item of arr) {
					await ajaxCALLPromise("/FlowDetail_UpdateStatus", {
						Student_ID: studentId,
						Process_ID: root.PROCESS_ID,
						Flow_ID: item.Flow_ID,
						Task_ID: item.Task_ID,
						Task_Detail_ID: item.Task_Detail_ID,
						Flow_Detail_Status: status,
					});
				}
			},
	
			closeModal() {
				this.dialog = false;
			},
		},
	}
</script>