<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="450px" persistent>
		<v-card>
			<v-card-title class="d-block text-center pt-4">
				<div class="d-flex align-center justify-center mb-2">
					<v-icon color="primary" size="48">mdi-help-circle-outline</v-icon>
				</div>
				<div class="subtitle-1 font-weight-bold">Đồng bộ dữ liệu quy trình đổi đề tài</div>
			</v-card-title>

			<v-card-text>
				<div class="text-center mb-4">
					<span class="text-body-2">
						Bạn có muốn đồng bộ dữ liệu sang quy trình mới cho nghiên cứu sinh <b class="primary--text">{{ studentid }}</b> không?
					</span>
				</div>
				<v-select class="mt-2" v-model="loaiDieuChinh" :items="loaiDieuChinhList"
					label="Loại điều chỉnh" item-text="text" item-value="value" dense outlined hide-details />
			</v-card-text>

			<v-card-actions class="justify-center pb-4">
				<v-btn color="primary" :loading="loading" @click="confirmFunc">Xác nhận</v-btn>
				<v-btn text color="grey darken-1" :disabled="loading" @click="closeModal">Hủy</v-btn>
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
			processIdRequest: {
				type: Number,
				default: 0,
			}
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				loading: false,
				loaiDieuChinh: 1,
				loaiDieuChinhList: [
					{ text: "Đổi/Điều chỉnh tên đề tài luận án", value: 1 },
					{ text: "Đổi/Điều chỉnh Người hướng dẫn", value: 2 },
					{ text: "Đổi tên đề tài và Người hướng dẫn", value: 3 },
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
				if (!this.studentid || !this.processIdRequest) {
					Vue.$toast.error("Thiếu thông tin phê duyệt", { position: "top" });
					return;
				}
				this.loading = true;
				try {
					await ajaxCALLPromise("/SDH_StudentChangeThesis", {
						Process_ID_Request: this.processIdRequest,
						Student_ID: this.studentid,
						LoaiDieuChinh: this.loaiDieuChinh,
					});

					Vue.$toast.success("Đổi đề tài và cập nhật dữ liệu thành công", { position: "top" });
					this.$emit("on-reload");
					this.closeModal();
				} catch (error) {
					Vue.$toast.error(error?.responseJSON?.Message || "Có lỗi xảy ra", { position: "top" });
					console.error("Error confirming:", error);
				} finally {
					this.loading = false;
				}
			},
			closeModal() {
				this.dialog = false;
			},
		},
	}
</script>