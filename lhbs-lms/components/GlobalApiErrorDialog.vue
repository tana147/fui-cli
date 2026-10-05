<template>
	<v-dialog v-model="visible" max-width="420">
		<v-card>
			<v-card-title class="text-error">
				HTTP {{status}}
			</v-card-title>

			<v-card-text>
				{{ message }}
			</v-card-text>

			<v-card-actions>
				<v-spacer />
				<v-btn color="primary" @click="close">
					Đóng
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'GlobalApiErrorDialog',
		computed: {
			visible: {
				get() {
					return window.errorState?.api?.visible ?? false;
				},
				set(val) {
					if (window.errorState?.api) {
						window.errorState.api.visible = val;
					}
				}
			},
			message() {
				return window.errorState?.api?.message ?? '';
			},
			status() {
				return window.errorState?.api?.status ?? '';
			}
		},
	
		methods: {
			close() {
				window.errorState?.api?.hide?.();
			}
		}
	}
</script>