<template>
	<v-dialog v-model="dialog" max-width="500" persistent>
		<v-card>
			<v-card-title>Lý do từ chối hoạt động</v-card-title>
			<v-card-text class="pa-3">
				<v-textarea v-model="reason" label="Nhập lý do từ chối..." rows="3" autofocus variant="outlined"
					density="compact">
				</v-textarea>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn @click="dialog = false">Hủy</v-btn>
				<v-btn color="error" @click="submit" :disabled="!reason">Xác nhận</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-modal-reject',
		props: {
			modelValue: { type: Boolean, default: false },
			item: { type: Object, default: null },
			nhanVienId: [String, Number]
		},
		emits: ['update:modelValue', 'on-submit'],
		data() {
			return {
				reason: ''
			}
		},
		computed: {
			dialog: {
				get() {
					return this.modelValue;
				},
				set(val) {
					this.$emit('update:modelValue', val);
				}
			}
		},
		watch: {
			modelValue(val) {
				if (val) {
					this.reason = '';
				}
			}
		},
		methods: {
			submit() {
				if (!this.reason) return;
				const payload = {
					SubmissionID: this.item.SubmissionID,
					TrangThaiMoi: 'KHOA_TU_CHOI',
					GhiChuTuChoi: this.reason
				};
				this.$emit('on-submit', payload, this.nhanVienId);
				this.dialog = false;
			}
		}
	}
</script>