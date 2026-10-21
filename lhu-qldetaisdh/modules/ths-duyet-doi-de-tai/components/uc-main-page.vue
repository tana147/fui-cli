<template>
	<v-row class="fill-height ma-0 uc-acr-container" style="height: calc(100vh - 110px); overflow: hidden;">
		<v-col cols="5" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-main-view :ds-flow-status="dsFlowStatus"
				@on-select-student="onSelectStudent" @on-filter-nganh="onFilterNganh"
				@on-reload="fetchFlowStatus" style="height: 100%;" />
		</v-col>
		<v-col cols="7" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-detail-flow v-if="selectedStudent" :key="selectedStudent.Student_ID" :student-id="selectedStudent.Student_ID"
				:student-info="selectedStudent" :api-file="apiFile" :url-read-file="urlReadFile"
				@on-reload="onDetailReload" style="height: 100%;" />
			<v-card v-else outlined class="d-flex align-center justify-center fill-height"
				style="height: 100%; border: 1px solid #dbe7ee !important;">
				<div class="text-center grey--text">
					<v-icon size="64" color="grey lighten-1">mdi-account-search-outline</v-icon>
					<div class="mt-2 text-body-2">Chọn một học viên từ danh sách để xem chi tiết đổi đề tài</div>
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
				nganhId: 0,
				nienKhoa: "0",
				selectedStudent: null,
				apiFile: "",
				urlReadFile: "",
			};
		},
		watch: {
			nganhId() {
				this.fetchFlowStatus();
			},
			nienKhoa() {
				this.fetchFlowStatus();
			},
		},
		mounted() {
			this.initPlatformConfig();
			this.fetchFlowStatus();
		},
		methods: {
			// 1. Hàm hỗ trợ
			initPlatformConfig() {
				const vSet = window.vueData?.v_Set || {};
				this.apiFile = vSet.apiFile || "https://file.lhu.edu.vn/qldetaisdh/upload/FileData";
				this.urlReadFile = vSet.urlReadFile || "https://file.lhu.edu.vn/qldetaisdh/";
			},
			// 2. Hàm xử lý chức năng
			onFilterNganh(nganhId) {
				this.nganhId = nganhId;
				this.fetchFlowStatus();
			},
			onSelectStudent(item) {
				this.selectedStudent = item;
			},
			onDetailReload() {
				this.fetchFlowStatus();
			},
			// 3. Hàm gọi API
			async fetchFlowStatus() {
				const params = {
					Process_Action: 2,
					Nganh_ID: this.nganhId,
					NienKhoa: this.nienKhoa,
				};
				const res = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus", params);
				this.dsFlowStatus = Array.isArray(res) ? res : (res?.data || []);
			},
		},
	}
</script>