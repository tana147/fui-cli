<template>
	<div class="fluid pa-4">
		<uc-thong-tin-tong-hop :data="thongTinTongHop" />
		<div class="mt-6">
			<div class="d-flex justify-space-between align-center mb-4">
				<h2 class="text-primary font-weight-bold">
					CÁC HOẠT ĐỘNG ĐÃ KÊ KHAI NĂM HỌC {{ namHocHienTai }}
				</h2>
				<v-btn color="primary" prepend-icon="mdi-plus">
					<span>Kê khai hoạt động mới</span>
					<v-menu class="w-100" activator="parent">
						<v-list :items="dsForms" item-title="FormTitle" item-value="FormID"
							@update:selected="(event) => {showNewKekhaiDialog(event[0])}"></v-list>
					</v-menu>
				</v-btn>
			</div>
			<uc-danh-sach-ke-khai :items="dsKeKhai" @view="showViewKekhaiDialog" @edit="showEditKekhaiDialog"
				@delete="confirmDeleteKekhai" />
			<uc-form-ke-khai-dong v-model="isDialogKekhaiVisible" :form-definition="formDefinition"
				:form-edit-data="selectedSubmissionData" :title="dialogTitle" :ds-g-v="dsGV" :dsGV="dsGV" :itemStatus="itemStatus"
				:selectedSubmissionID="selectedSubmissionID" @on-reload="initData"
				@update:formDefinition="formDefinition = $event" @update:formEditData="selectedSubmissionData = $event"
				@update:selectedSubmissionID="selectedSubmissionID = $event" />
		</div>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				namHocHienTai: new Date().getFullYear(),
				thongTinTongHop: null,
				dsKeKhai: [],
				dsForms: [],
				dsGV: [],
				formDefinition: {},
				isDialogKekhaiVisible: false,
				selectedSubmissionData: null,
				dialogTitle: "",
				itemStatus: null,
				selectedFormCode: null,
				selectedSubmissionID: 0,
			};
		},
		mounted() {
			this.initData();
		},
		methods: {
			async initData() {
				await Promise.all([
					this.fetchDsGV(),
					this.fetchTongHop(),
					this.fetchDsKeKhai(),
					this.fetchDsForms(),
				]);
			},
			async fetchDsGV() {
				const data = await ajaxCALLPromise("/TaiKhoan_Seach", { Keyword: "" });
				this.dsGV = data || [];
			},
			async fetchTongHop() {
				const data = await ajaxCALLPromise("/HDKH_KeKhai_GetTongHopCaNhan", {
					NamHoc: this.namHocHienTai,
				});
				this.thongTinTongHop = data[0]
			},
			async fetchDsKeKhai() {
				const data = await ajaxCALLPromise("/HDKH_KeKhai_GetSubmissionList", {
					NamHoc: this.namHocHienTai,
				});
				this.dsKeKhai = data;
			},
			async fetchDsForms() {
				const data = await ajaxCALLPromise("/HDKH_Form_GetList", null);
				this.dsForms = data;
			},
			async fetchFormDefinition(formCode) {
				const data = await ajaxCALLPromise("/HDKH_Form_GetDefinition", {
					FormID: formCode,
				});
				this.formDefinition = data[0];
			},
			async fetchSubmissionDetail(submissionID) {
				const data = await ajaxCALLPromise("/HDKH_KeKhai_GetDetailByID", {
					SubmissionID: submissionID,
				});
				this.selectedSubmissionData = data;
			},
			async showNewKekhaiDialog(formCode) {
				if (!formCode) return;
				this.selectedFormCode = formCode;
				await this.fetchFormDefinition(formCode);
				this.selectedSubmissionData = {};
				this.itemStatus = "new";
				this.dialogTitle = `Kê khai mới: ${this.formDefinition.FormTitle}`;
				this.isDialogKekhaiVisible = true;
			},
			async showEditKekhaiDialog(submission) {
				if (!submission) return;
				const form = this.dsForms.find(
					(f) => f.FormTitle === submission.FormTitle
				);
				if (!form) return;
				this.selectedFormCode = form.FormID;
				await this.fetchFormDefinition(form.FormID);
				this.selectedSubmissionID = submission.SubmissionID;
				await this.fetchSubmissionDetail(submission.SubmissionID);
				this.dialogTitle = `Chỉnh sửa: ${submission.TenHoatDong_CuThe}`;
				this.itemStatus = "edit";
				this.isDialogKekhaiVisible = true;
			},
			async showViewKekhaiDialog(submission) {
				if (!submission) return;
				const form = this.dsForms.find(
					(f) => f.FormTitle === submission.FormTitle
				);
				if (!form) return;
				this.selectedFormCode = form.FormID;
				await this.fetchFormDefinition(form.FormID);
				this.selectedSubmissionID = submission.SubmissionID;
				await this.fetchSubmissionDetail(submission.SubmissionID);
				this.dialogTitle = `Xem: ${submission.TenHoatDong_CuThe}`;
				this.itemStatus = "view";
				this.isDialogKekhaiVisible = true;
			},
			confirmDeleteKekhai(submission) {
				confirm({
					title: `Bạn có chắc muốn xóa hoạt động "${submission.TenHoatDong_CuThe}"?`,
					action: async () => {
						await ajaxCALLPromise("/HDKH_KeKhai_Delete", {
							SubmissionID: submission.SubmissionID,
						});
						Vue.$toast.success("Xóa thành công!", { position: "top" });
						this.fetchTongHop();
						this.fetchDsKeKhai();
					},
				});
			},
		},
	}
</script>