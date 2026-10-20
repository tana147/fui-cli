<template>
	<sqd-list :decisionarr="decisionarr" :decisionfilter="decisionfilter"/>
</template>

<script>
	export default {
		props: ["decisionarr", "decisionfilter"]
	}
</script>