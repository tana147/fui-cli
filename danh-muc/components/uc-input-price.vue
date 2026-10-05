<template>
	<v-text-field :model-value="displayPrice" @update:model-value="onInput" :label :variant density="compact" :rules
		:reverse type="text" inputmode="numeric" />
</template>

<script>
	export default {
	
	    props: {
	        label: String,
	        modelValue: Number,
	        rules: Array,
	        variant: {
	            type: String,
	            default: 'outlined'
	        },
	        reverse: {
	            type: Boolean,
	            default: false
	        }
	    },
	
	    data() {
	        return {
	        }
	    },
	
	    mounted() {
	    },
	    computed: {
	        displayPrice() {
	            if (this.modelValue == null) return ''
	            return this.modelValue.toLocaleString('vi-VN')
	        }
	    },
	
	    watch: {
	    },
	
	    methods: {
	        onInput(val) {
	            const digits = val?.replace(/\D/g, '')
	
	            if (!digits) {
	                this.$emit('update:modelValue', null)
	                return
	            }
	
	            this.$emit('update:modelValue', parseFloat(digits))
	        }
	    }
	
	}
</script>