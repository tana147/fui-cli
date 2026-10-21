<template>
	<v-dialog v-model="isOpen" transition="dialog-bottom-transition" max-width="1550px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<div class="d-flex align-center">
						<v-icon color="primary" class="mr-2">mdi-account-plus</v-icon>
						<span class="title primary--text font-weight-bold mb-0">Lập hội đồng đánh giá</span>
						<v-chip color="primary" outlined class="ml-3 font-weight-bold" small label>
							{{ HoiDong.Student_ID || HoiDong.StudentID }}
						</v-chip>
						<span class="ml-2 font-weight-medium text--secondary">
							{{ HoiDong.Ho_SV }} {{ HoiDong.Ten_SV }}
						</span>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pt-3 pb-1">
				<!-- Banner thông tin đề tài & GVHD -->
				<v-sheet color="blue-grey lighten-5" class="pa-3 rounded-xs mb-3" outlined>
					<v-row dense align="center">
						<v-col cols="12" md="6">
							<div class="text-caption grey--text text--darken-1 font-weight-bold text-uppercase">
								Tên đề tài / Luận án:
							</div>
							<div class="body-2 font-weight-bold primary--text">
								{{ HoiDong.Thesis_Name || 'Chưa cập nhật tên đề tài' }}
							</div>
						</v-col>
						<v-col cols="12" md="3">
							<div class="text-caption grey--text text--darken-1 font-weight-bold text-uppercase">
								Hướng dẫn khoa học:
							</div>
							<div class="body-2 font-weight-medium">
								<div>{{ HoiDong.Thesises_Prof1 || 'Chưa có' }}</div>
								<div v-if="HoiDong.Thesises_Prof2" class="text-caption text--secondary">
									{{ HoiDong.Thesises_Prof2 }}
								</div>
							</div>
						</v-col>
						<v-col cols="12" md="3">
							<div class="text-caption grey--text text--darken-1 font-weight-bold text-uppercase">
								Lớp & Chuyên ngành:
							</div>
							<div class="body-2 font-weight-medium">
								<span class="amber--text text--darken-3 font-weight-bold">[{{ HoiDong.Lop_ID }}]</span>
								{{ HoiDong.Ten_Nganh }}
							</div>
						</v-col>
					</v-row>
				</v-sheet>

				<!-- Hàng cấu hình Loại hội đồng & Ngày bảo vệ -->
				<v-row class="mb-1" dense>
					<v-col cols="12" md="6">
						<v-select
							v-model="selectedLoaiHoiDong"
							:items="dsLoaiHoiDong"
							item-text="name"
							item-value="id"
							outlined
							dense
							hide-details
							label="Loại hội đồng"
							prepend-inner-icon="mdi-format-list-checks"
							class="rounded-xs"
						/>
					</v-col>
					<v-col cols="12" md="6">
						<f-date
							v-model="time"
							color="primary"
							label="Ngày bảo vệ"
							placeholder="Chọn ngày bảo vệ"
							outlined
							dense
							hide-details
							prepend-inner-icon="mdi-calendar"
							class="rounded-xs"
						/>
					</v-col>
				</v-row>

				<!-- Bảng chọn giảng viên & gán chức trách -->
				<uc-table-council
					:active-council-type="selectedLoaiHoiDong"
					:council-config="councilConfig"
					:dshdgiangvien="[]"
					:hoidong="HoiDong"
					:hearr="hearr"
					:is-dialog-closed="isOpen"
					@onSelected="(ds) => (DSGiangVienSeleted = ds)"
					@update-nganh-giang-day="(val) => $emit('update-nganh-giang-day', val)"
				/>
			</v-card-text>

			<v-divider />

			<v-card-actions class="px-4 py-3 bg-grey-lighten-4">
				<v-spacer></v-spacer>
				<v-btn text color="grey darken-1" class="rounded-xs mr-2" @click="closeDialog">
					<v-icon left small>mdi-close</v-icon>
					Đóng
				</v-btn>
				<v-btn color="primary" class="rounded-xs font-weight-bold px-4" depressed :loading="saving" @click="addHoiDong">
					<v-icon left small>mdi-content-save</v-icon>
					Lưu hội đồng
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-add-council",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			editedItem: {
				type: Object,
				default: () => ({})
			},
			dshoidonggiangvien: {
				type: Array,
				default: () => []
			},
			hearr: {
				type: Array,
				default: () => []
			},
			councilConfig: {
				type: Object,
				default: () => ({})
			}
		},
		emits: ["input", "on-reload", "update-nganh-giang-day"],
		data() {
			return {
				selectedLoaiHoiDong: 2,
				dsLoaiHoiDong: [
					{ id: 2, name: "Chuyên đề 1 NCS (Tối thiểu 3 thành viên)", minMembers: 3 },
					{ id: 3, name: "Chuyên đề 2 NCS (Tối thiểu 3 thành viên)", minMembers: 3 },
					{ id: 4, name: "Chuyên đề 3 NCS (Tối thiểu 3 thành viên)", minMembers: 3 },
					{ id: 5, name: "Luận án TS (Tối thiểu 5 thành viên)", minMembers: 5 }
				],
				DSGiangVienSeleted: [],
				time: "",
				saving: false
			};
		},
		computed: {
			isOpen: {
				get() {
					return this.value;
				},
				set(val) {
					this.$emit("input", val);
				}
			},
			HoiDong() {
				return this.editedItem || {};
			}
		},
		watch: {
			isOpen(val) {
				if (val) {
					const loai = (this.editedItem && this.editedItem.LoaiHoiDong) || 2;
					this.selectedLoaiHoiDong = parseInt(loai) || 2;
					this.time = "";
					this.DSGiangVienSeleted = [];
				}
			}
		},
		methods: {
			closeDialog() {
				this.isOpen = false;
				this.DSGiangVienSeleted = [];
				this.time = "";
			},
			async addHoiDong() {
				const minMembers = this.selectedLoaiHoiDong === 5 ? 5 : 3;
				if ((this.DSGiangVienSeleted || []).length < minMembers) {
					Vue.$toast.error(`Chưa đủ thành viên hội đồng (Yêu cầu tối thiểu ${minMembers} người)`, { position: "top" });
					return;
				}

				if (!this.time) {
					Vue.$toast.error("Vui lòng chọn ngày bảo vệ", { position: "top" });
					return;
				}

				const roles = new Set();
				for (const gv of this.DSGiangVienSeleted) {
					if (!gv.ChucTrach) {
						Vue.$toast.error(`Thành viên ${gv.HoTenHocHamHocVi} chưa được gán chức trách`, { position: "top" });
						return;
					}
					if (roles.has(gv.ChucTrach)) {
						Vue.$toast.error(`Trùng lặp chức trách "${gv.ChucTrach}"`, { position: "top" });
						return;
					}
					roles.add(gv.ChucTrach);
				}

				const studentId = this.HoiDong.Student_ID || this.HoiDong.StudentID;

				this.saving = true;
				try {
					await ajaxCALLPromise("/HoiDong_Ins", {
						Student_ID: studentId,
						HoiDongThanhVienObj_Arr: this.DSGiangVienSeleted,
						ThoiGianBaoVe: this.time,
						LoaiHoiDong: this.selectedLoaiHoiDong
					});

					Vue.$toast.success("Lập hội đồng thành công", { position: "top" });
					this.$emit("on-reload");
					this.closeDialog();
				} catch (error) {
					console.error("Add council error:", error);
					Vue.$toast.error(`${error?.responseJSON?.Message || error}`, { position: "top" });
				} finally {
					this.saving = false;
				}
			}
		}
	}
</script>