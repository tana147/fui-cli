<template>
	<v-row class="fill-height ma-0 uc-ar-container" style="height: calc(100vh - 110px); overflow: hidden;">
		<v-col cols="5" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-main-view :dsFlowStatus="dsFlowStatus" @on-select-student="onSelectStudent" @on-reload="initData"
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
		mounted() {
			this.initPlatformConfig();
			this.initData();
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
					Process_Action: 4,
					Nganh_ID: nganhId,
					NienKhoa: nienKhoa
				};
				this.dsFlowStatus = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus", params);
			},
			async fetchRootProcess(studentId) {
				if (studentId) {
					try {
						this.dsRootProcess = await ajaxCALLPromise(
							'/SDH_Get_RootProcessing',
							{
								StudentID: studentId,
								Process_Action: 4,
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

				const currentSelectedFlowId = (keepSelection && this.selectedStudent) ? this.selectedStudent.Flow_ID : null;
				const currentSelectedStudentId = (keepSelection && this.selectedStudent) ? this.selectedStudent.Student_ID : null;
				
				await this.fetchFlowStatus(filterNganh, filterNienKhoa);

				if (currentSelectedStudentId) {
					let found = null;
					if (currentSelectedFlowId) {
						found = (this.dsFlowStatus || []).find(s => s.Flow_ID === currentSelectedFlowId);
					}
					if (!found) {
						found = (this.dsFlowStatus || []).find(s => s.Student_ID === currentSelectedStudentId);
					}
					if (found) {
						this.selectedStudent = found;
						await this.fetchRootProcess(currentSelectedStudentId);
					} else {
						this.selectedStudent = null;
						this.dsRootProcess = [];
					}
				} else {
					this.selectedStudent = null;
					this.dsRootProcess = [];
				}
			},
			onSelectStudent(student) {
				this.selectedStudent = student;
			},
			async onDetailReload() {
				await this.initData(undefined, undefined, true);
			}
		}
	}
</script>