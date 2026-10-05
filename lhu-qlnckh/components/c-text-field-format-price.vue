<template>
	<div>
		<v-text-field v-model="FormatPrice" v-bind="$attrs" reverse outlined dense></v-text-field>
	</div>
</template>

<script>
	export default {
		props: ["value"],
		data() {
			return {}
		},
		mounted() { },
		computed: {
			Price: function () {
				return this.value ?? 0;
			},
			FormatPrice: {
				get: function () {
					return formatAsCurrency(parseFloat(this.Price), 0);
				},
				set: function (newValue) {
					console.log('set...', newValue)
					if (newValue) {
						// eslint-disable-next-line no-useless-escape
						let number = Number(newValue.replace(/[^0-9\.]/g, ""));
						this.$emit("input", number);
					}
				},
			},
		},
		watch: {},
		methods: {},
	}
</script>