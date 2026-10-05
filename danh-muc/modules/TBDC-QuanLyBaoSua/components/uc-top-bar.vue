<template>
    <v-app-bar density="compact" :elevation="0" title="Quản lí sửa chữa">
        <v-spacer></v-spacer>
        <v-btn icon="mdi-reload" variant="text" size="small" @click="onReload" />
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
        onReload() {
            this.$emit('load-bao-sua-moi')
        }
    }

}
</script>