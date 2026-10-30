<template>
	<v-dialog v-model="dialog" max-width="650" persistent>
		<v-card class="rounded-xs">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					{{ isEdit ? "Cập nhật quyết định" : "Thêm mới quyết định" }}
				</span>
				<v-spacer />
				<v-btn icon small @click="close">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pa-4">
				<v-row dense>
					<v-col cols="12" sm="6">
						<v-text-field
							v-model="form.MaSoQD"
							label="Số quyết định"
							placeholder="VD: 123/QĐ-ĐHLH"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="2">
						<v-text-field
							v-model.number="form.NgayQD"
							label="Ngày QĐ"
							type="number"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="2">
						<v-text-field
							v-model.number="form.ThangQD"
							label="Tháng QĐ"
							type="number"
							outlined
							dense
							hide-details
						/>
					</v-col>
					<v-col cols="12" sm="2">
						<v-text-field
							v-model.number="form.NamQD"
							label="Năm QĐ"
							type="number"
							outlined
							dense
							hide-details
						/>
					</v-col>

					<v-col cols="12">
						<v-textarea
							v-model="form.MoTaQD"
							label="Mô tả / Trích yếu quyết định"
							rows="3"
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
		name: "uc-modal-decision",
	props: {
		value: {
			type: Boolean,
			default: false
		},
		isEdit: {
			type: Boolean,
			default: false
		},
		decisionItem: {
			type: Object,
			default: () => ({})
		}
	},
	emits: ["input", "on-reload"],
	data() {
		return {
			form: {
				QDID: 0,
				MaSoQD: "",
				NgayQD: null,
				ThangQD: null,
				NamQD: new Date().getFullYear(),
				MoTaQD: ""
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
			if (this.isEdit && this.decisionItem && this.decisionItem.QDID) {
				this.form = {
					QDID: this.decisionItem.QDID,
					MaSoQD: this.decisionItem.MaSoQD || "",
					NgayQD: this.decisionItem.NgayQD || null,
					ThangQD: this.decisionItem.ThangQD || null,
					NamQD: this.decisionItem.NamQD || new Date().getFullYear(),
					MoTaQD: this.decisionItem.MoTaQD || ""
				}
			} else {
				const now = new Date()
				this.form = {
					QDID: 0,
					MaSoQD: "",
					NgayQD: now.getDate(),
					ThangQD: now.getMonth() + 1,
					NamQD: now.getFullYear(),
					MoTaQD: ""
				}
			}
		},
		async save() {
			if (!this.form.MaSoQD || this.form.MaSoQD.trim() === "") {
				Vue.$toast.error("Vui lòng nhập số quyết định", { position: "top" })
				return
			}
			this.saving = true
			try {
				const params = {
					MaSoQD: this.form.MaSoQD.trim(),
					NgayQD: this.form.NgayQD || 0,
					ThangQD: this.form.ThangQD || 0,
					NamQD: this.form.NamQD || 0,
					MoTaQD: this.form.MoTaQD ? this.form.MoTaQD.trim() : "",
					TemplateQD: 1,
					LoaiQD: 1
				}

				if (this.isEdit) {
					params.QDID = this.form.QDID
					params.DS_FileID = null
					await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Upd", params)
					Vue.$toast.success("Cập nhật quyết định thành công", { position: "top" })
				} else {
					await ajaxCALLPromise("/GiaiThuong_QuyetDinh_Ins", params)
					Vue.$toast.success("Thêm mới quyết định thành công", { position: "top" })
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