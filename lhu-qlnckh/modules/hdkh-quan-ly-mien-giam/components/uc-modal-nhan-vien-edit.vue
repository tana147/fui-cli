<template>
	<v-dialog v-model="dialog" max-width="600px" persistent>
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>Cập nhật thông tin nhân viên</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon variant="text" @click="close">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-toolbar>
			<v-card-text class="pt-4">
				<v-row dense>
					<v-col cols="12" md="6" class="pb-2">
						<v-text-field v-model="form.MaNV" label="Mã nhân viên" dense hide-details readonly disabled>
						</v-text-field>
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
		name: "uc-modal-nhan-vien-edit",
		props: {
			value: { type: Boolean, default: false },
			modelValue: { type: Boolean, default: null },
			khoaList: { type: Array, default: () => [] },
			khoaId: { type: [Number, String], default: null },
			editItem: { type: Object, default: () => ({}) },
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
					this.mapEditItem();
				}
			}
		},
		methods: {
			mapEditItem() {
				if (this.editItem) {
					// Map dữ liệu từ editItem sang form
					this.form = {
						MaNV: this.editItem.NhanVienID || "",
						HoTen: this.editItem.HoTen || "",
						ChucVu: this.editItem.ChucVu || "",
						MaDonVi: this.editItem.KhoaID !== undefined ? this.editItem.KhoaID : this.khoaId,
						HocViID: this.editItem.HocViID !== undefined ? this.editItem.HocViID : null,
						Is_ThamGiaNCKH: this.editItem.Is_ThamGiaNCKH !== undefined ? (this.editItem.Is_ThamGiaNCKH === 1 || this.editItem.Is_ThamGiaNCKH === true) : true
					};
				}
			},
			// logic handleHoTenInput và extractTen đã được loại bỏ
			async save() {
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
					await ajaxCALLPromise("/HDKH_Admin_NhanVien_Update", params);
					Vue.$toast.success("Cập nhật thông tin thành công", { position: "top" });
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