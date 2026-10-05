<template>
	<v-text-field v-model="displayValue" :label="label" :placeholder="placeholder" :error-messages="errorMessages"
		:readonly="readonly" :disabled="disabled" :clearable="clearable" @input="handleInput" @blur="formatValue"
		@focus="unformatValue" suffix="đ" />
</template>

<script>
	export default {
		name: 'CurrencyInput',
		props: {
			modelValue: {
				type: [String, Number],
				default: ''
			},
			label: String,
			placeholder: String,
			errorMessages: [String, Array],
			readonly: Boolean,
			disabled: Boolean,
			clearable: Boolean
		},
		data() {
			return {
				displayValue: ''
			}
		},
		watch: {
			modelValue: {
				immediate: true,
				handler(val) {
					this.displayValue = this.formatNumber(val)
				}
			}
		},
		methods: {
			handleInput(e) {
				const raw = e.target.value.replace(/\D/g, '') // bỏ tất cả ký tự không phải số
				const formatted = this.formatNumber(raw)
				this.displayValue = formatted
	
				const number = parseInt(raw)
				this.$emit('update:modelValue', isNaN(number) ? null : number)
			},
			formatValue() {
				this.displayValue = this.formatNumber(this.modelValue)
			},
			unformatValue() {
				this.displayValue = this.modelValue?.toString() || ''
			},
			formatNumber(value) {
				const number = parseInt(value)
				if (isNaN(number)) return ''
				return number.toLocaleString('vi-VN')
			}
		}
	}
</script>