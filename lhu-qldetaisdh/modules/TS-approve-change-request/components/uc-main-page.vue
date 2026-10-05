<template>
	<v-row class="fill-height ma-0 uc-ar-container" style="height: calc(100vh - 110px); overflow: hidden;">
		<v-col cols="5" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-main-view :ds-flow-status="dsFlowStatus" @on-select-student="onSelectStudent"
				@on-filter-nganh="onFilterNganh" style="height: 100%;" />
		</v-col>
		<v-col cols="7" class="fill-height pa-1" style="height: 100%; overflow: hidden;">
			<uc-detail-flow v-if="selectedStudentId" :student-id="selectedStudentId" :student-info="ctFlowStatus"
				@on-reload="fetchFlowStatus" style="height: 100%;" />
			<v-card v-else outlined class="d-flex align-center justify-center fill-height"
				style="height: 100%; border: 1px solid #dbe7ee !important;">
				<div class="text-center grey--text">
					<v-icon size="64" color="grey lighten-1">mdi-account-search-outline</v-icon>
					<div class="mt-2 text-body-2">Chọn một học viên từ danh sách để xem chi tiết yêu cầu đổi đề tài</div>
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
				ctFlowStatus: null,
			};
		},
		computed: {
			selectedStudentId() {
				return this.ctFlowStatus ? this.ctFlowStatus.Student_ID : "";
			},
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
			this.fetchFlowStatus();
		},
		methods: {
			onFilterNganh(nganhId) {
				this.nganhId = nganhId;
				this.fetchFlowStatus();
			},
			onSelectStudent(item) {
				this.ctFlowStatus = item;
			},
			async fetchFlowStatus() {
				const params = {
					Process_Action: 5, // 5 = Đổi / Điều chỉnh đề tài Tiến sĩ
					Nganh_ID: this.nganhId,
					NienKhoa: this.nienKhoa,
				};
				const res = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus", params);
				this.dsFlowStatus = res || [];
			},
		},
	}
</script>