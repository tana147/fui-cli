<template>
	<div class="d-flex flex-column align-center justify-center py-8 grey--text text--lighten-1">
    <v-icon size="48" color="grey lighten-1">{{ icon }}</v-icon>
    <div class="text-body-2 mt-2 grey--text text--darken-1">{{ text }}</div>
  </div>
</template>

<script>
	export default {
		name: "c-empty-state",
  props: {
    text: {
      type: String,
      default: "Không có dữ liệu",
    },
    icon: {
      type: String,
      default: "mdi-database-minus-outline",
    },
  },
	}
</script>