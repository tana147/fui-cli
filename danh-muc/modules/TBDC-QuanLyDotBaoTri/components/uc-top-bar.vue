<template>
    <v-app-bar density="compact" :elevation="0" title="Quản lý đợt bảo trì">
        <template v-slot:append>
            <v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onAddNew">Thêm
                mới</v-btn>
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
            this.$emit('on-add-new-lich-bao-tri')
        }
    }

}
</script>