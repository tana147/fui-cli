<template>
	<div class="pa-2">
		<v-row class="fluid grid-list-md">
			<v-col cols="12" md="5">
				<uc-main-view :ds-flow-status="dsFlowStatus" @on-select-student="onSelectStudent"
					@on-filter-nganh="onFilterNganh" />
			</v-col>
			<v-col cols="12" md="7" v-if="selectedStudentId">
				<uc-detail-flow :student-id="selectedStudentId" :student-info="ctFlowStatus"
					@on-reload="fetchFlowStatus" />
			</v-col>
		</v-row>
	</div>
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
			// 2. Hàm xử lý chức năng
			onFilterNganh(nganhId) {
				this.nganhId = nganhId;
				this.fetchFlowStatus();
			},
			onSelectStudent(item) {
				this.ctFlowStatus = item;
			},
			// 3. Hàm gọi API
			async fetchFlowStatus() {
				const params = {
					Process_Action: 2,
					Nganh_ID: this.nganhId,
					NienKhoa: this.nienKhoa,
				};
				const res = await ajaxCALLPromise("/SDH_Get_Student_FlowStatus", params);
				this.dsFlowStatus = res || [];
			},
		},
	}
</script>