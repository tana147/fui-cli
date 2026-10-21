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
					<div class="text-caption grey--text text--darken-1 text-left mt-1">
						<v-icon small color="info">mdi-information-outline</v-icon>
						Tên task đồng bộ: <b>{{ getTenTaskQuyetDinh(loaiDieuChinh) }}</b>
					</div>
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
			processIdRequest: {
				type: Number,
				default: 0,
			}
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

			getTenTaskQuyetDinh(loai) {
				switch (loai) {
					case 1:
						return "File Quyết định đổi/điều chỉnh tên đề tài";
					case 2:
						return "File Quyết định thay đổi GVHD";
					case 3:
						return "File Quyết định đổi tên đề tài và thay đổi GVHD";
					default:
						return "File Quyết định đổi/điều chỉnh đề tài";
				}
			},
		},
	}
</script>