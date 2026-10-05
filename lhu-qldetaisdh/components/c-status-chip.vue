<template>
	<v-chip
		:small="small"
		:x-small="xSmall"
		:outlined="outlined"
		:color="chipColor"
		:class="['font-weight-medium rounded-xs', chipTextClass, customClass]"
		label
	>
		<v-icon v-if="showIcon && chipIcon" left :x-small="xSmall" :small="small && !xSmall">
			{{ chipIcon }}
		</v-icon>
		{{ chipLabel }}
	</v-chip>
</template>

<script>
	export default {
		name: "c-status-chip",
		props: {
			status: {
				type: [String, Number],
				default: "W",
			},
			lock: {
				type: [Number, String],
				default: 1,
			},
			small: {
				type: Boolean,
				default: false,
			},
			xSmall: {
				type: Boolean,
				default: false,
			},
			outlined: {
				type: Boolean,
				default: false,
			},
			showIcon: {
				type: Boolean,
				default: true,
			},
			customClass: {
				type: String,
				default: "",
			},
		},
		computed: {
			isLocked() {
				return this.lock === 0 || this.lock === "0"
			},
			normalizedStatus() {
				if (!this.status) return "W"
				const s = String(this.status).toUpperCase().trim()
				if (s === "COMPLETED") return "C"
				if (s === "PROCESSING") return "P"
				if (s === "REJECTED" || s === "REJECT") return "R"
				if (s === "WAITING") return "W"
				return s
			},
			chipLabel() {
				if (this.isLocked) return "Đã khóa"
				switch (this.normalizedStatus) {
					case "C":
						return "Đã hoàn thành"
					case "P":
						return "Đang thực hiện"
					case "R":
						return "Từ chối"
					case "W":
					default:
						return "Đang chờ"
				}
			},
			chipColor() {
				if (this.isLocked) return "grey lighten-2"
				switch (this.normalizedStatus) {
					case "C":
						return "green lighten-5"
					case "P":
						return "blue lighten-5"
					case "R":
						return "red lighten-5"
					case "W":
					default:
						return "grey lighten-3"
				}
			},
			chipTextClass() {
				if (this.isLocked) return "grey--text text--darken-3"
				switch (this.normalizedStatus) {
					case "C":
						return "green--text text--darken-3"
					case "P":
						return "blue--text text--darken-3"
					case "R":
						return "red--text text--darken-3"
					case "W":
					default:
						return "grey--text text--darken-2"
				}
			},
			chipIcon() {
				if (this.isLocked) return "mdi-lock"
				switch (this.normalizedStatus) {
					case "C":
						return "mdi-check-circle"
					case "P":
						return "mdi-timer-sand"
					case "R":
						return "mdi-close-circle"
					case "W":
					default:
						return "mdi-clock-outline"
				}
			},
		},
	}
</script>