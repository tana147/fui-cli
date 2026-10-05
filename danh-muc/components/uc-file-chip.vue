<template>
    <div class="d-flex flex-wrap">
        <v-chip v-for="(item, index) in items" :key="item.FileID" class="me-2" size="small" label dark
            :closable="closable" :color="getColor(item.FileName)" @click="viewFile(item.FileID)"
            @click:close="deleteFile(item, index)">
            <v-icon class="me-1" left small>{{ getIcon(item.FileName) }}</v-icon>
            {{ item.FileName }}
        </v-chip>
    </div>
</template>

<script>
export default {
    props: {
        items: { type: Array, required: true },
        closable: { type: Boolean, default: () => false }
    },
    methods: {
        getIcon(fileName) {
            if (!fileName) return 'mdi-file'
            if (
                fileName?.includes('.png') ||
                fileName?.includes('.jpg') ||
                fileName?.includes('.jpeg') ||
                fileName?.includes('.gif') ||
                fileName?.includes('.webp') ||
                fileName?.includes('.svg')
            ) return 'mdi-image'
            if (fileName?.includes('pdf')) return 'mdi-file-pdf-box'
            return 'mdi-file'
        },

        getColor(fileName) {
            if (!fileName) return 'indigo'
            if (
                fileName?.includes('.png') ||
                fileName?.includes('.jpg') ||
                fileName?.includes('.jpeg') ||
                fileName?.includes('.gif') ||
                fileName?.includes('.webp') ||
                fileName?.includes('.svg')
            ) return 'green'
            if (fileName?.includes('pdf')) return 'red'
            return 'blue'
        },

        viewFile(FileID) {
            const urlReadFile = 'https://file.zentea.vn/work/HH_FileData/'
            window.open(`${urlReadFile}${FileID}`, "_blank");
        },
        deleteFile(item, index) {
            this.$emit('close', {
                file: item,
                index: index
            })
        }

    }
}
</script>
