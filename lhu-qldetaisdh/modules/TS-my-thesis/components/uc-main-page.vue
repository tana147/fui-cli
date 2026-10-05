<template>
	<v-container fluid class="pa-2 ts-module-wrapper d-flex flex-column h-100">
		<!-- Tiêu đề trang & Actions -->
		<v-card class="mb-2 pa-2 rounded-xs d-flex align-center justify-space-between uc-main-header flex-shrink-0" flat>
			<div class="d-flex align-center">
				<v-avatar size="32" color="primary" class="mr-2 rounded-xs">
					<v-icon color="white" size="18">mdi-school-outline</v-icon>
				</v-avatar>
				<div>
					<h3 class="text-subtitle-1 font-weight-bold primary--text mb-0 line-height-1-2">
						Đăng ký & Quản lý Học Tiến Sĩ
					</h3>
					<span class="text-caption grey--text text--darken-1 line-height-1-2 d-block">
						Theo dõi lộ trình đào tạo, nộp hồ sơ chuyên đề và quản lý tiến trình luận án Tiến sĩ của Nghiên cứu sinh
					</span>
				</div>
			</div>
			
			<v-menu offset-y>
				<template v-slot:activator="{ on, attrs }">
					<v-btn color="teal" dark small class="text-none font-weight-bold" v-bind="attrs" v-on="on">
						<v-icon left small>mdi-plus-circle-outline</v-icon> Tạo yêu cầu mới
					</v-btn>
				</template>
				<v-list dense>
					<v-list-item @click="createNewProcess(5, 'Đổi đề tài / Hướng nghiên cứu')">
						<v-list-item-title>Xin đổi đề tài / Hướng nghiên cứu</v-list-item-title>
					</v-list-item>
					<v-list-item @click="createNewProcess(6, 'Gia hạn thời gian')">
						<v-list-item-title>Xin gia hạn thời gian học tập</v-list-item-title>
					</v-list-item>
				</v-list>
			</v-menu>
		</v-card>

		<!-- Component thông tin học viên -->
		<uc-student-info v-if="detailInfo" :detailInfo="detailInfo" class="flex-shrink-0" />

		<!-- THANH 3 TABS QUY TRÌNH CHÍNH & XEM LỊCH SỬ -->
		<v-card class="mb-2 pa-1 rounded-xs flex-shrink-0 border" flat style="background: #ffffff;">
			<div class="d-flex align-center justify-space-between px-2" style="gap: 16px;">
				<!-- 3 Tabs quy trình chính cố định - Co giãn chiếm trọn chiều ngang -->
				<v-tabs
					v-model="activeProcessTabIndex"
					background-color="transparent"
					color="primary"
					class="text-none flex-grow-1"
					@change="onSelectProcessTab"
				>
					<v-tab v-for="(tab, index) in mainProcessTabs" :key="'proc-tab-' + index" class="text-none font-weight-bold">
						<v-icon left small color="primary">{{ tab.icon }}</v-icon>
						{{ tab.name }}
						<v-chip v-if="getProcessCountForAction(tab.action) > 0" x-small class="ml-2 font-weight-bold" color="primary lighten-5 primary--text">
							{{ getProcessCountForAction(tab.action) }}
						</v-chip>
					</v-tab>
				</v-tabs>

				<!-- Khu vực Xem Lịch Sử / Chọn đợt cũ tương ứng với từng Tab -->
				<div class="d-flex align-center ml-auto flex-shrink-0" style="gap: 8px;">
					<!-- Tab 1 (Quy trình chính): Nút mở Modal xem lịch sử quy trình cũ (Reset) -->
					<v-btn
						v-if="activeTabAction === 4"
						text
						small
						color="primary"
						class="rounded-xs text-none font-weight-bold"
						@click="isOpenViewOldProcessModal = true"
					>
						<v-icon left small>mdi-history</v-icon>
						Lịch sử quy trình cũ (Reset)
					</v-btn>

					<!-- Tab 2 (Đổi đề tài) hoặc Tab 3 (Gia hạn) và có nhiều lần: Dropdown chọn lần xem -->
					<div v-else-if="currentActionProcessList.length > 1" class="d-flex align-center">
						<span class="text-caption grey--text text--darken-2 mr-2 font-weight-medium text-no-wrap">
							<v-icon left small color="primary">mdi-history</v-icon> Lần đăng ký:
						</span>
						<v-select
							v-model="selectedProcessStudentId"
							:items="processVersionOptions"
							item-text="text"
							item-value="value"
							dense
							outlined
							hide-details
							class="caption font-weight-medium"
							style="min-width: 260px; max-width: 320px; background: #ffffff;"
							@change="onChangeProcessVersion"
						/>
					</div>
				</div>
			</div>
		</v-card>

		<!-- Component Timeline & Chi tiết giai đoạn -->
		<uc-main-view
			v-if="rootFlow && rootFlow.length > 0"
			:rootflow="rootFlow"
			:studentProcess="studentProcess"
			:studentId="studentId"
			:apiFile="apiFile"
			:urlReadFile="urlReadFile"
			@on-reload="initData"
			class="flex-grow-1 min-h-0"
		/>
		
		<v-card v-else outlined class="d-flex align-center justify-center fill-height pa-8 mt-2 flex-grow-1"
			style="border: 1px solid #dbe7ee !important; min-height: 300px;">
			<div class="text-center grey--text">
				<v-icon size="48" color="grey lighten-1">mdi-file-document-outline</v-icon>
				<div class="mt-2 text-body-1 font-weight-bold grey--text text--darken-2">NCS hiện chưa có hồ sơ đăng ký cho quy trình này</div>
				<div class="caption grey--text mt-1">Bạn có thể bấm nút <b>"Tạo yêu cầu mới"</b> ở góc phải trên cùng để bắt đầu đăng ký thủ tục.</div>
			</div>
		</v-card>

		<!-- Modal xem lịch sử quy trình cũ (Reset) -->
		<uc-modal-view-old-process
			v-model="isOpenViewOldProcessModal"
			:student-item="detailInfo"
		/>
	</v-container>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				studentProcess: [],
				rootFlow: [],
				detailInfo: null,
				studentId: null,
				apiFile: '',
				urlReadFile: '',
				mainProcessTabs: [
					{ key: 'main', action: 4, processId: 6, processTree: "4", name: "Quy trình đào tạo chính", icon: "mdi-school-outline" },
					{ key: 'change', action: 5, processId: 7, processTree: "2", name: "Đổi đề tài / GVHD", icon: "mdi-file-replace-outline" },
					{ key: 'extend', action: 6, processId: 8, processTree: "3", name: "Gia hạn thời gian", icon: "mdi-clock-time-four-outline" },
				],
				activeProcessTabIndex: 0,
				selectedProcessStudentId: null,
				isOpenViewOldProcessModal: false,
			}
		},
		computed: {
			activeTabAction() {
				return this.mainProcessTabs[this.activeProcessTabIndex]?.action || 4;
			},
			currentActionProcessList() {
				if (!this.studentProcess || this.studentProcess.length === 0) return [];
				const action = this.activeTabAction;
				return this.studentProcess.filter(p => (p.Process_Action || 4) === action);
			},
			processVersionOptions() {
				const list = this.currentActionProcessList;
				const total = list.length;
				return list.map((item, idx) => {
					const lanNum = total - idx;
					const statusText = item.Process_Student_Status === 'C' ? 'Đã hoàn thành' : 'Đang xử lý';
					return {
						text: `Lần ${lanNum} (${statusText})`,
						value: item.Process_Student_ID,
						item: item
					};
				});
			}
		},
		mounted() {
			this.apiFile = window.vueData?.v_Set?.apiFile || '';
			this.urlReadFile = window.vueData?.v_Set?.urlReadFile || '';
			this.initData();
		},
		methods: {
			getProcessCountForAction(action) {
				if (!this.studentProcess) return 0;
				return this.studentProcess.filter(p => (p.Process_Action || 4) === action).length;
			},
			async initData() {
				try {
					const userID = window.vueData?.user?.UserID;
					if (!userID) return;
					this.studentId = userID;

					// Lấy danh sách quy trình của NCS (Hỗ trợ nhiều luồng như chính, đổi đề tài, gia hạn)
					const res = await ajaxCALLPromise("/Student_Process_Get_TS", { Student_ID: userID, IsFull: 1 });
					const actionOrder = { 4: 1, 5: 2, 6: 3 };
					this.studentProcess = (res || []).sort((a, b) => {
						const orderA = actionOrder[a.Process_Action] || 99;
						const orderB = actionOrder[b.Process_Action] || 99;
						if (orderA !== orderB) return orderA - orderB;
						return (b.Process_Student_ID || 0) - (a.Process_Student_ID || 0);
					});
					
					await this.switchProcessTab(this.activeProcessTabIndex);

					// Lấy thông tin cá nhân
					const infoRes = await ajaxCALLPromise("/StudentInfo_GetById", { Student_ID: userID });
					if (infoRes && infoRes.length > 0) {
						const info = infoRes[0];
						// Nếu không phải Nghiên cứu sinh (Tiến sĩ), tự động chuyển về trang Luận văn Thạc sĩ
						if (info?.HeDaoTao && info.HeDaoTao.toLowerCase() !== 'phd') {
							window.location.href = '/my-thesis';
							return;
						}
						if (window.vueData?.user) {
							info.HoSV = window.vueData.user.LastName || '';
							info.TenSV = window.vueData.user.FirstName || '';
						}
						if (!info.HoTen) {
							info.HoTen = ((info.HoSV || '') + ' ' + (info.TenSV || '')).trim();
						}
						this.detailInfo = info;
					}
				} catch (error) {
					console.error("Lỗi khi initData (TS):", error);
				}
			},
			async onSelectProcessTab(index) {
				this.activeProcessTabIndex = index;
				await this.switchProcessTab(index);
			},
			async switchProcessTab(tabIndex) {
				const tab = this.mainProcessTabs[tabIndex] || this.mainProcessTabs[0];
				const procs = (this.studentProcess || []).filter(p => (p.Process_Action || 4) === tab.action);
				if (procs.length > 0) {
					this.selectedProcessStudentId = procs[0].Process_Student_ID;
					await this.loadRootFlow(procs[0].Process_Student_ID, tab.processTree);
				} else {
					this.selectedProcessStudentId = null;
					this.rootFlow = [];
				}
			},
			async onChangeProcessVersion(psId) {
				const tab = this.mainProcessTabs[this.activeProcessTabIndex] || this.mainProcessTabs[0];
				await this.loadRootFlow(psId, tab.processTree);
			},
			async loadRootFlow(processStudentId, processTree = "4") {
				if (!this.studentId || !processStudentId) {
					this.rootFlow = [];
					return;
				}
				try {
					this.rootFlow = await ajaxCALLPromise("/Get_RootFlow", {
						StudentID: this.studentId,
						Process_Student_ID: processStudentId,
						Process_Tree: String(processTree || "4")
					});
				} catch (e) {
					console.error("Lỗi lấy root flow:", e);
					this.rootFlow = [];
				}
			},
			createNewProcess(actionId, actionName) {
				confirm({
					title: `Tạo thủ tục ${actionName}`,
					content: `Hệ thống sẽ tạo quy trình <b>${actionName}</b> mới. Bạn có chắc chắn muốn tiếp tục?`,
					action: async () => {
						await ajaxCALLPromise("/Process_Student_Ins", {
							Process_Action: actionId,
							Student_ID: this.studentId,
							Expire_Date: new Date().getFullYear().toString() + '-12-31',
							insert_new: 1
						});
						if (typeof Vue !== 'undefined' && Vue.$toast) {
							Vue.$toast.success(`Tạo thủ tục ${actionName} thành công`, { position: 'top' });
						}
						// Chuyển tab sang loại quy trình vừa tạo
						const targetTabIndex = this.mainProcessTabs.findIndex(t => t.action === actionId);
						if (targetTabIndex !== -1) {
							this.activeProcessTabIndex = targetTabIndex;
						}
						await this.initData();
					},
					cancel: () => {}
				});
			}
		}
	}
</script>