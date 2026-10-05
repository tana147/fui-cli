<template>
	<v-dialog v-model="dialogVisible" :width="width" :close-on-back="false" v-bind="$attrs">
		<v-card class="uc-dialog__card">
			<v-card-title class="d-flex px-6 py-2">
				<slot name="title" v-if="!title"></slot>
				<div v-else class="flex-grow-1 min-width-0">
					<div :class="classTitle">
						{{ title }}
					</div>
					<div class="text-caption text-medium-emphasis">
						<slot name="subTitle"></slot>
					</div>
				</div>
				<v-spacer></v-spacer>
				<v-btn icon="mdi-close" variant="text" size="small" aria-label="Đóng" @click="onClose"></v-btn>
			</v-card-title>
			<v-card-text class="uc-dialog__content" style="padding: 12px 16px">
				<slot></slot>
			</v-card-text>
			<v-card-actions class="uc-dialog__actions">
				<template v-if="$slots.actions">
					<slot name="actions"></slot>
				</template>
				<template v-else>
					<v-btn text color="grey-darken-1" variant="text" prepend-icon="mdi-close"
						@click="onClose">
						{{ closeText }}
					</v-btn>
					<v-btn v-if="isShowDoneBtn" text color="primary" variant="outlined" prepend-icon="mdi-content-save"
						:loading="doneLoading" :disabled="doneDisabled" @click="handleSubmit">
						{{ doneText }}
					</v-btn>
				</template>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
	        modelValue: {
	            type: Boolean,
	            required: true,
	        },
	        title: {
	            type: String,
	            default: '',
	        },
	        doneText: {
	            type: String,
	            default: 'OK',
	        },
	        closeText: {
	            type: String,
	            default: 'Đóng',
	        },
	        onSubmit: {
	            type: Function,
	        },
	        classTitle: {
	            type: String,
	            default: 'primary-text',
	        },
	        width: {
	            default: 500,
	        },
		        isShowDoneBtn: {
		            type: Boolean,
		            default: true,
		        },
		        doneLoading: {
		            type: Boolean,
		            default: false,
	        },
		        doneDisabled: {
		            type: Boolean,
		            default: false,
		        },
	    },
	    computed: {
			dialogVisible: {
				get() {
					return this.modelValue
				},
				set(value) {
					this.$emit('update:modelValue', value)
				},
			},
		},
	    methods: {
	        onClose() {
	            this.$emit('update:modelValue', false)
	        },
	        handleSubmit(e) {
	            this.$emit('onSubmit', e)
	        },
	    },
	}
</script>

<style scoped>
.uc-dialog__card {
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 32px);
}

.uc-dialog__content {
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
}

.uc-dialog__actions {
  flex: 0 0 auto;
}

@media (max-width: 600px) {
  .uc-dialog__content {
    padding: 8px 10px !important;
  }
}
</style>