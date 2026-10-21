<template>
	<v-row class="fill-height ma-0 uc-aet-container" style="height: calc(100vh - 110px); overflow: hidden;">
		<v-col cols="5" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-main-view
				:dsFlowStatus="dsFlowStatus"
				:selectedStudent="selectedStudent"
				@on-select-student="onSelectStudent"
				@on-reload="fetchFlowStatus"
				style="height: 100%;"
			/>
		</v-col>
		<v-col cols="7" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-detail-flow
				v-if="selectedStudent"
				:studentId="selectedStudent.Student_ID"
				:studentInfo="selectedStudent"
				:dsRootProcess="dsRootProcess"
				:apiFile="apiFile"
				:urlReadFile="urlReadFile"
				@on-reload="onDetailReload"
				style="height: 100%;"
			/>
			<v-card v-else outlined class="d-flex align-center justify-center fill-height"
				style="height: 100%; border: 1px solid #dbe7ee !important;">
				<div class="text-center grey--text">
					<v-icon size="64" color="grey lighten-1">mdi-account-search-outline</v-icon>
					<div class="mt-2 text-body-2">Chọn một học viên từ danh sách để xem chi tiết gia hạn</div>
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
			currentMajor: 0
		};
	},
	watch: {
		selectedStudent: {
			async handler(newVal) {
				if (newVal && newVal.Student_ID) {
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
		await this.fetchFlowStatus();
	},
	methods: {
		initPlatformConfig() {
			const vSet = window.vueData?.v_Set || {};
			this.apiFile = vSet.apiFile || "";
			this.urlReadFile = vSet.urlReadFile || "";
		},
		async fetchFlowStatus(nganhId = 0) {
			this.currentMajor = nganhId;
			const params = {
				Process_Action: 3,
				Nganh_ID: nganhId
			};
			try {
				const res = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus", params);
				this.dsFlowStatus = Array.isArray(res) ? res : (res?.data || []);
			} catch (error) {
				console.log("Error fetchFlowStatus in approve-extend-time", error);
				this.dsFlowStatus = [];
			}
		},
		async fetchRootProcess(studentId) {
			if (studentId) {
				try {
					const res = await ajaxCALLPromise(
						'/SDH_Get_RootProcessing',
						{
							StudentID: studentId,
							Process_Action: 3,
						}
					);
					this.dsRootProcess = Array.isArray(res) ? res : (res?.data || []);
				} catch (error) {
					Vue.$toast.error(error.responseJSON ? error.responseJSON.Message : 'Lỗi tải tiến trình gia hạn', { position: 'top' });
					console.log('Error fetchRootProcess: ', error);
					this.dsRootProcess = [];
				}
			} else {
				this.dsRootProcess = [];
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
			const currentSelectedId = this.selectedStudent ? this.selectedStudent.Student_ID : null;
			await this.fetchFlowStatus(this.currentMajor);
			if (currentSelectedId) {
				const found = this.dsFlowStatus.find(x => x.Student_ID === currentSelectedId);
				if (found) {
					this.selectedStudent = found;
					await this.fetchRootProcess(found.Student_ID);
				}
			}
		}
	}
	}
</script>