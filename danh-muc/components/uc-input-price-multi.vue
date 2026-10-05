<template>
	<v-combobox :model-value="displayValue" @update:model-value="onChange" :items="items" item-title="title"
		item-value="value" :label="label" :variant="variant" density="compact" :rules="rules" clearable
		hide-details="auto" return-object @keydown="onlyNumber">
		<template #item="{ props, item }">
			<v-list-item v-bind="props" :title="item.raw.title" />
		</template>

		<template #selection="{ item }">
			<span>{{ formatPrice(item.raw.value) }}</span>
		</template>
	</v-combobox>
</template>

<script>
	export default {
		props: {
			label: String,
			modelValue: Number,
			rules: Array,
			items: {
				type: Array,
				default: () => []
			},
			variant: {
				type: String,
				default: 'outlined'
			}
		},
	
		computed: {
			displayValue() {
				if (this.modelValue == null) return null
	
				// nếu có trong list -> dùng luôn (để highlight đúng)
				const found = this.items.find(x => x.value === this.modelValue)
				if (found) return found
	
				// nếu nhập tay
				return {
					title: this.formatPrice(this.modelValue),
					value: this.modelValue
				}
			}
		},
	
		methods: {
			formatPrice(value) {
				if (value == null || value === '') return ''
				return Number(value).toLocaleString('vi-VN')
			},

			onChange(val) {
				if (!val) {
					this.$emit('update:modelValue', null)
					return
				}
	
				let number
	
				if (typeof val === 'object') {
					number = val.value
				} else {
					const digits = val.toString().replace(/\D/g, '')
					number = digits ? Number(digits) : null
				}
	
				if (number == null || isNaN(number) || number < 0) {
					this.$emit('update:modelValue', null)
					return
				}
	
				this.$emit('update:modelValue', number)
			},
	
			onlyNumber(e) {
				const allow = [
					'Backspace', 'Delete', 'Tab', 'Enter',
					'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'
				]
	
				if (allow.includes(e.key) || e.ctrlKey || e.metaKey) return
				if (!/^\d$/.test(e.key)) e.preventDefault()
			}
		}
	}
</script>