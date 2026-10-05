<template>
	<v-dialog :value="value" @input="$emit('input', $event)" transition="dialog-bottom-transition" max-width="600px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="close">
				<template v-slot:title>
					<div class="title primary--text text-left">
						Xác nhận đăng ký mới "{{ studentName }}"
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pt-4">
				<v-text-field
					v-model="LyDo"
					label="Lý do"
					placeholder="Nhập lý do đăng ký mới"
					outlined
					color="primary"
					dense
					hide-details
				/>
			</v-card-text>

			<v-card-actions class="pa-3">
				<v-spacer />
				<v-btn text class="rounded-xs" @click="close">Hủy</v-btn>
				<v-btn color="success" class="rounded-xs" :loading="saving" @click="onReset">
					<v-icon left small>mdi-content-save</v-icon>Xác nhận
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-reset-process",
		props: {
			value: {
				type: Boolean,
				default: false,
			},
			studentItem: {
				type: Object,
				default: () => ({}),
			},
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				LyDo: "",
				saving: false,
			}
		},
		computed: {
			studentName() {
				return this.studentItem?.HoTen || `${this.studentItem?.HoSV || ""} ${this.studentItem?.TenSV || ""}`.trim()
			},
		},
		methods: {
			async onReset() {
				if (!this.LyDo || !this.LyDo.trim()) {
					Vue.$toast.error('Không được bỏ trống "Lý do"', { position: "top" })
					return
				}

				if (!this.studentItem?.StudentID) {
					Vue.$toast.error("Không tìm thấy thông tin học viên", { position: "top" })
					return
				}

				this.saving = true
				try {
					await ajaxCALLPromise("/Reset_Student_Process", {
						Student_ID: this.studentItem.StudentID,
						LyDo: this.LyDo.trim(),
					})

					await ajaxCALLPromise("/Student_Remove", {
						StudentID: this.studentItem.StudentID,
					})

					await ajaxCALLPromise("/Student_INS_obj", {
						StudentObjArr: this.studentItem,
						Process_Action: 1,
					})

					Vue.$toast.success("Đăng ký mới thành công", { position: "top" })
					this.$emit("on-reload")
					this.close()
				} catch (error) {
					const msg = error?.responseJSON?.Message || error?.message || "Lỗi xử lý đăng ký mới"
					Vue.$toast.error(msg, { position: "top" })
				} finally {
					this.saving = false
				}
			},

			close() {
				this.LyDo = ""
				this.$emit("input", false)
			},
		},
	}
</script>