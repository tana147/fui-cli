<template>
	<v-dialog v-model="dialog" max-width="500" persistent>
		<v-card class="rounded-xs">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Thêm loại giải thưởng mới
				</span>
				<v-spacer />
				<v-btn icon small @click="close">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<v-text-field
					v-model="form.MaLoaiGiaiThuong"
					label="Mã loại giải thưởng"
					outlined
					dense
					hide-details
					class="mb-3"
				/>
				<v-text-field
					v-model="form.TenLoaiGiaiThuong"
					label="Tên loại giải thưởng"
					outlined
					dense
					hide-details
				/>
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
					Lưu
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-reward-type",
	props: {
		value: {
			type: Boolean,
			default: false
		}
	},
	emits: ["input", "on-reload"],
	data() {
		return {
			form: {
				MaLoaiGiaiThuong: "",
				TenLoaiGiaiThuong: ""
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
	methods: {
		resetForm() {
			this.form = {
				MaLoaiGiaiThuong: "",
				TenLoaiGiaiThuong: ""
			}
		},
		async save() {
			if (!this.form.TenLoaiGiaiThuong || this.form.TenLoaiGiaiThuong.trim() === "") {
				Vue.$toast.error("Vui lòng nhập tên loại giải thưởng", { position: "top" })
				return
			}
			this.saving = true
			try {
				const params = {
					MaLoaiGiaiThuong: this.form.MaLoaiGiaiThuong ? this.form.MaLoaiGiaiThuong.trim() : "",
					TenLoaiGiaiThuong: this.form.TenLoaiGiaiThuong.trim()
				}
				await ajaxCALLPromise("/LoaiGiaiThuong_Ins", params)
				Vue.$toast.success("Thêm loại giải thưởng thành công", { position: "top" })
				this.$emit("on-reload")
				this.close()
			} finally {
				this.saving = false
			}
		},
		close() {
			this.resetForm()
			this.dialog = false
		}
	}
	}
</script>
