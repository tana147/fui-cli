<template>
    <div class="d-flex flex-wrap">
        <v-chip class="me-2" size="small" label dark
             :color="getColor(item.FileName)" @click="viewFile(item.FileID)">
            <v-icon class="me-1" left small>{{ getIcon(item.FileName) }}</v-icon>
            {{ item.FileName }}
        </v-chip>
    </div>
</template>

<script>
export default {
    props: {
        // {
        //     FileName: 'AAA.pdf',
        //     FileID : 'ASDC7976790'
        // }
        item: { type: Object, required: true },
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
    }
}
</script>
