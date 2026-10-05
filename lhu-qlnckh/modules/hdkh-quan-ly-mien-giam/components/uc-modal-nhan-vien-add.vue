<template>
	<v-dialog v-model="dialog" max-width="600px" persistent>
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>Thêm nhân viên mới</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon variant="text" @click="close">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-toolbar>
			<v-card-text class="pt-4">
				<v-row dense>
					<v-col cols="12" md="6" class="pb-2">
						<v-text-field v-model="form.MaNV" label="Mã nhân viên" dense hide-details></v-text-field>
					</v-col>
					<v-col cols="12" md="6" class="pb-2">
						<v-text-field v-model="form.HoTen" label="Họ và tên" dense hide-details></v-text-field>
					</v-col>
					<v-col cols="12" md="6" class="pb-2">
						<v-text-field v-model="form.ChucVu" label="Chức vụ" dense hide-details></v-text-field>
					</v-col>
					<v-col cols="12" md="6" class="pb-2">
						<v-select v-model="form.HocViID" :items="hocViList" item-value="HocViID" item-title="TenHocVi"
							label="Học vị" dense hide-details></v-select>
					</v-col>
					<v-col cols="12" class="pb-2">
						<v-checkbox v-model="form.Is_ThamGiaNCKH" label="Tham gia NCKH" dense hide-details></v-checkbox>
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn text @click="close">Hủy</v-btn>
				<v-btn color="primary" :loading="saving" @click="save">Lưu</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-nhan-vien-add",
		props: {
			value: { type: Boolean, default: false },
			modelValue: { type: Boolean, default: null },
			khoaList: { type: Array, default: () => [] },
			khoaId: { type: [Number, String], default: null },
			hocViList: { type: Array, default: () => [] }
		},
		emits: ["input", "update:modelValue", "on-reload"],
		data() {
			return {
				saving: false,
				form: {
					MaNV: "",
					HoTen: "",
					ChucVu: "",
					MaDonVi: null,
					HocViID: null,
					Is_ThamGiaNCKH: true
				}
			}
		},
		computed: {
			dialog: {
				get() { return this.modelValue !== null ? this.modelValue : this.value; },
				set(val) {
					this.$emit("input", val);
					this.$emit("update:modelValue", val);
				}
			}
		},
		watch: {
			dialog(newVal) {
				if (newVal) {
					this.resetForm();
				}
			}
		},
		methods: {
			resetForm() {
				this.form = {
					MaNV: "",
					HoTen: "",
					ChucVu: "",
					MaDonVi: this.khoaId,
					HocViID: null,
					Is_ThamGiaNCKH: true
				};
			},
			// logic handleHoTenInput và extractTen đã được loại bỏ
			async save() {
				if (!this.form.MaNV) {
					Vue.$toast.error("Vui lòng nhập mã nhân viên", { position: "top" });
					return;
				}
				
				const maNVRegex = /^(?=.*[a-zA-Z])(?=.*[0-9])[a-zA-Z0-9]{9}$/;
				if (!maNVRegex.test(this.form.MaNV)) {
					Vue.$toast.error("Mã nhân viên phải gồm đúng 9 ký tự bao gồm cả chữ và số", { position: "top" });
					return;
				}

				if (!this.form.HoTen) {
					Vue.$toast.error("Vui lòng nhập họ và tên", { position: "top" });
					return;
				}
				if (!this.form.MaDonVi) {
					Vue.$toast.error("Vui lòng chọn khoa/đơn vị", { position: "top" });
					return;
				}

				this.saving = true;
				try {
					const khoa = this.khoaList.find(k => k.KhoaID === this.form.MaDonVi);
					const maDonViGui = khoa ? (khoa.MaDonVi || khoa.MaKhoa || khoa.KhoaID) : this.form.MaDonVi;
					const params = {
						MaNV: this.form.MaNV,
						HoTen: this.form.HoTen,
						ChucVu: this.form.ChucVu,
						MaDonVi: maDonViGui,
						HocViID: this.form.HocViID,
						Is_ThamGiaNCKH: this.form.Is_ThamGiaNCKH ? 1 : 0
					};
					await ajaxCALLPromise("/HDKH_Admin_NhanVien_Insert", params);
					Vue.$toast.success("Thêm nhân viên thành công", { position: "top" });
					this.$emit("on-reload");
					this.close();
				} finally {
					this.saving = false;
				}
			},
			close() {
				this.dialog = false;
			}
		}
	}
</script>