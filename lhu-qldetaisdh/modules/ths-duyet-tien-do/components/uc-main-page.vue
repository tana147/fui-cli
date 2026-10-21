<template>
	<v-row class="fill-height ma-0 uc-ar-container" style="height: calc(100vh - 110px); overflow: hidden;">
		<v-col cols="5" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-main-view :dsFlowStatus="dsFlowStatus" :dsNotFinishFlowStatus="dsNotFinishFlowStatus"
				@on-select-student="onSelectStudent" @on-reload="initData"
				style="height: 100%;" />
		</v-col>
		<v-col cols="7" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-detail-flow v-if="selectedStudent" :studentId="selectedStudent.Student_ID"
				:studentInfo="selectedStudent" :dsRootProcess="dsRootProcess" :apiFile="apiFile"
				:urlReadFile="urlReadFile" :systemRight="systemRight" @on-reload="onDetailReload"
				style="height: 100%;" />
			<v-card v-else outlined class="d-flex align-center justify-center fill-height"
				style="height: 100%; border: 1px solid #dbe7ee !important;">
				<div class="text-center grey--text">
					<v-icon size="64" color="grey lighten-1">mdi-account-search-outline</v-icon>
					<div class="mt-2 text-body-2">Chọn một học viên từ danh sách để xem chi tiết tiến trình duyệt</div>
				</div>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				dsFlowStatus: [],
				dsNotFinishFlowStatus: [],
				dsRootProcess: [],
				selectedStudent: null,
				apiFile: "",
				urlReadFile: "",
				systemRight: 0,
				currentFilter: {
					nganhId: 0,
					nienKhoa: "0"
				}
			};
		},
		watch: {
			selectedStudent: {
				async handler(newVal) {
					if (newVal) {
						await this.fetchRootProcess(newVal.Student_ID);
					} else {
						this.dsRootProcess = [];
					}
				},
				immediate: true
			}
		},
		async mounted() {
			this.initPlatformConfig();
			await this.initData();
		},
		methods: {
			initPlatformConfig() {
				const vSet = window.vueData?.v_Set || {};
				this.apiFile = vSet.apiFile || "";
				this.urlReadFile = vSet.urlReadFile || "";
				this.systemRight = window.vueData?.user?.SystemRight ?? 0;
			},
			async fetchFlowStatus(nganhId = 0, nienKhoa = "0") {
				const params = {
					Process_Action: 1,
					Nganh_ID: nganhId,
					NienKhoa: nienKhoa
				};
				try {
					this.dsFlowStatus = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus", params);
				} catch (error) {
					console.log("Error fetchFlowStatus", error);
					this.dsFlowStatus = [];
				}
			},
			async fetchNotFinishFlowStatus(nganhId = 0) {
				const params = {
					Process_Action: 1,
					Nganh_ID: nganhId
				};
				try {
					this.dsNotFinishFlowStatus = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus_NotFinish", params);
				} catch (error) {
					console.log("Error fetchNotFinishFlowStatus", error);
					this.dsNotFinishFlowStatus = [];
				}
			},
			async fetchRootProcess(studentId) {
				if (studentId) {
					try {
						this.dsRootProcess = await ajaxCALLPromise(
							'/SDH_Get_RootProcessing',
							{
								StudentID: studentId,
								Process_Action: 1,
							}
						);
					} catch (error) {
						Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi tải tiến trình', { position: 'top' });
						console.log('Error onLoadRoot: ', error);
						this.dsRootProcess = [];
					}
				} else {
					this.dsRootProcess = [];
				}
			},
			async initData(nganhId, nienKhoa, keepSelection = false) {
				const filterNganh = nganhId !== undefined ? nganhId : this.currentFilter.nganhId;
				const filterNienKhoa = nienKhoa !== undefined ? nienKhoa : this.currentFilter.nienKhoa;

				this.currentFilter = {
					nganhId: filterNganh,
					nienKhoa: filterNienKhoa
				};

				const currentSelectedId = (keepSelection && this.selectedStudent) ? this.selectedStudent.Student_ID : null;

				await Promise.all([
					this.fetchFlowStatus(filterNganh, filterNienKhoa),
					this.fetchNotFinishFlowStatus(filterNganh)
				]);

				if (currentSelectedId) {
					const found = this.dsFlowStatus.find(x => x.Student_ID === currentSelectedId);
					this.selectedStudent = found || null;
				} else {
					this.selectedStudent = null;
				}
			},
			onSelectStudent(student) {
				this.selectedStudent = student;
				if (typeof vueData !== 'undefined') {
					vueData.CT_FlowStatus = student;
					vueData.Student_ID = student?.Student_ID || '';
				}
			},
			async onDetailReload() {
				await this.initData(undefined, undefined, true);
				if (this.selectedStudent) {
					await this.fetchRootProcess(this.selectedStudent.Student_ID);
				}
			}
		}
	}
</script>