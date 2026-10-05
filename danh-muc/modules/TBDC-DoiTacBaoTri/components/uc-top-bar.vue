<template>
	<v-app-bar density="compact" :elevation="0" title="Quản lý đối tác bảo trì">
		<template v-slot:append>
			<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onAddNew">Thêm
				mới</v-btn>
			<v-menu>
				<template v-slot:activator="{ props }">
					<v-btn color="primary" prepend-icon="mdi-tune" append-icon="mdi-chevron-down" variant="flat"
						v-bind="props">Thao
						tác</v-btn>
				</template>
				<v-list density="compact">
					<v-list-item @click="onExport" prepend-icon="mdi-file-excel-outline" title="Xuất excel">
					</v-list-item>
				</v-list>
			</v-menu>
		</template>
	</v-app-bar>
</template>

<script>
	export default {
	
	    props: {
	    },
	
	    data() {
	        return {
	        }
	    },
	
	    mounted() {
	    },
	    computed: {
	    },
	
	    watch: {
	    },
	
	    methods: {
	        onAddNew() {
	            this.$emit('add-new-emit')
	        },
	        onExport() {
	            this.$emit('export-execl-emit')
	        },
	    }
	
	}
</script>