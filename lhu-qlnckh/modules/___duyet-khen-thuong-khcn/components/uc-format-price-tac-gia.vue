<template>
	<div>
		<v-text-field v-model="TienThuongFormat" class="text-input-right" :disabled="CongThucKhenThuongID === null"
			:filled="CongThucKhenThuongID === null" reverse outlined dense hide-details :readonly="readonly">
		</v-text-field>
	</div>
</template>

<script>
	export default {
		props: ["value", "ct_khenthuongid","readonly"],
		data() {
			return {}
		},
		computed: {
			CongThucKhenThuongID: function () {
				return this.ct_khenthuongid
			},
			TienThuongFormat: {
				get: function () {
					return formatAsCurrency(this.value, 0)
				},
				set: function (newValue) {
					let str = String(newValue !== null && newValue !== undefined ? newValue : '')
					let number = Number(str.replace(/[^0-9\.]/g, '')) || 0
					this.$emit('input', number)
				}
			}
		},
		methods: {},
	}
</script>