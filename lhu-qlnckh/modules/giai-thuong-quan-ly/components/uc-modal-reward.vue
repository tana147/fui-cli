<template>
	<v-dialog v-model="dialog" max-width="700" persistent>
		<v-card class="rounded-xs">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					{{ isEdit ? "Cập nhật giải thưởng" : "Thêm mới giải thưởng" }}
				</span>
				<v-spacer />
				<v-btn icon small @click="close">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<v-row dense>
					<v-col cols="12" sm="9">
						<v-select
							v-model="form.LoaiGiaiThuongID"
							:items="listLoaiGiaiThuong"
							item-value="LoaiGiaiThuongID"
							item-text="TenLoaiGiaiThuong"
							label="Loại giải thưởng"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="3">
						<v-text-field
							v-model.number="form.SoThuTu"
							label="Số thứ tự"
							type="number"
							outlined
							dense
							hide-details
						/>
					</v-col>

					<v-col cols="12">
						<v-textarea
							v-model="form.TenDeTai"
							label="Tên đề tài / Cuộc thi"
							rows="2"
							outlined
							dense
							hide-details
						/>
					</v-col>

					<v-col cols="12">
						<v-textarea
							v-model="form.TacGia"
							label="Tác giả / Nhóm tác giả / Đội"
							rows="2"
							outlined
							dense
							hide-details
						/>
					</v-col>

					<v-col cols="12" sm="7">
						<v-text-field
							v-model="form.DonVi"
							label="Đơn vị"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="5">
						<v-text-field
							v-model="form.Giai"
							label="Đạt giải"
							placeholder="VD: Giải Nhất, Giải Ba..."
							outlined
							dense
							hide-details
						/>
					</v-col>

					<v-col cols="12" sm="4">
						<v-text-field
							v-model.number="form.ThangDatGiai"
							label="Tháng đạt giải"
							type="number"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="4">
						<v-text-field
							v-model.number="form.NamDatGiai"
							label="Năm đạt giải"
							type="number"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="4">
						<v-select
							v-model="form.QDID"
							:items="listQuyetDinh"
							item-value="QDID"
							item-text="MaSoQD"
							label="Số quyết định"
							clearable
							outlined
							dense
							hide-details
						/>
					</v-col>
				</v-row>
			</v-card-text>

			<v-divider />

			<v-card-actions class="py-2 px-4">
				<v-spacer />
				<v-btn small text @click="close">Hủy</v-btn>
				<v-btn
					small
					color="primary"
					depressed
					:loading="saving"
					@click="save"
				>
					{{ isEdit ? "Cập nhật" : "Thêm mới" }}
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-reward",
	props: {
		value: {
			type: Boolean,
			default: false
		},
		isEdit: {
			type: Boolean,
			default: false
		},
		rewardItem: {
			type: Object,
			default: () => ({})
		},
		listLoaiGiaiThuong: {
			type: Array,
			default: () => []
		},
		listQuyetDinh: {
			type: Array,
			default: () => []
		},
		defaultLoaiGiaiThuongId: {
			type: [Number, String],
			default: null
		}
	},
	emits: ["input", "on-reload"],
	data() {
		return {
			form: {
				GiaiThuongID: 0,
				LoaiGiaiThuongID: null,
				SoThuTu: 1,
				TenDeTai: "",
				TacGia: "",
				DonVi: "Trường Đại học Lạc Hồng",
				Giai: "",
				ThangDatGiai: null,
				NamDatGiai: new Date().getFullYear(),
				QDID: null
			},
			saving: false
		}
	},
	computed: {
		dialog: {
			get() {
				return this.value
			},
			set(val) {
				this.$emit("input", val)
			}
		}
	},
	watch: {
		value(val) {
			if (val) {
				this.initForm()
			}
		}
	},
	methods: {
		initForm() {
			if (this.isEdit && this.rewardItem && this.rewardItem.GiaiThuongID) {
				this.form = {
					GiaiThuongID: this.rewardItem.GiaiThuongID,
					LoaiGiaiThuongID: this.rewardItem.LoaiGiaiThuongID,
					SoThuTu: this.rewardItem.SoThuTu || 0,
					TenDeTai: this.rewardItem.TenDeTai || "",
					TacGia: this.rewardItem.TacGia || "",
					DonVi: this.rewardItem.DonVi || "Trường Đại học Lạc Hồng",
					Giai: this.rewardItem.Giai || "",
					ThangDatGiai: this.rewardItem.ThangDatGiai || null,
					NamDatGiai: this.rewardItem.NamDatGiai || new Date().getFullYear(),
					QDID: this.rewardItem.QDID || null
				}
			} else {
				this.form = {
					GiaiThuongID: 0,
					LoaiGiaiThuongID: this.defaultLoaiGiaiThuongId || (this.listLoaiGiaiThuong[0] && this.listLoaiGiaiThuong[0].LoaiGiaiThuongID) || null,
					SoThuTu: 0,
					TenDeTai: "",
					TacGia: "",
					DonVi: "Trường Đại học Lạc Hồng",
					Giai: "",
					ThangDatGiai: null,
					NamDatGiai: new Date().getFullYear(),
					QDID: null
				}
			}
		},
		async save() {
			if (!this.form.TenDeTai || this.form.TenDeTai.trim() === "") {
				Vue.$toast.error("Vui lòng nhập tên đề tài/cuộc thi", { position: "top" })
				return
			}
			this.saving = true
			try {
				const params = {
					LoaiGiaiThuongID: this.form.LoaiGiaiThuongID,
					SoThuTu: this.form.SoThuTu || 0,
					TenDeTai: this.form.TenDeTai.trim(),
					TacGia: this.form.TacGia ? this.form.TacGia.trim() : "",
					DonVi: this.form.DonVi ? this.form.DonVi.trim() : "",
					Giai: this.form.Giai ? this.form.Giai.trim() : "",
					ThangDatGiai: this.form.ThangDatGiai || 0,
					NamDatGiai: this.form.NamDatGiai || 0,
					QDID: this.form.QDID || 0
				}

				if (this.isEdit) {
					params.GiaiThuongID = this.form.GiaiThuongID
					await ajaxCALLPromise("/GiaiThuong_Upd", params)
					Vue.$toast.success("Cập nhật giải thưởng thành công", { position: "top" })
				} else {
					await ajaxCALLPromise("/GiaiThuong_Ins", params)
					Vue.$toast.success("Thêm mới giải thưởng thành công", { position: "top" })
				}

				this.$emit("on-reload")
				this.close()
			} finally {
				this.saving = false
			}
		},
		close() {
			this.dialog = false
		}
	}
	}
</script>