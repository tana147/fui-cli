<template>
    <v-avatar size="24" :color="avatarColor">
        <v-img v-if="hasAvatar" :src="avatarUrl" />
        <span v-else class="text-caption font-weight-medium text-white">
            {{ initials }}
        </span>
    </v-avatar>
</template>

<script>
export default {
    props: {
        AnhDaiDien_Url: String,
        Ten: String,
    },

    computed: {
        hasAvatar() {
            return !!this.AnhDaiDien_Url
        },

        avatarUrl() {
            return `https://file.zentea.vn/work/FileData/${this.AnhDaiDien_Url}`
        },

        initials() {
            if (!this.Ten) return ''

            const parts = this.Ten.trim().split(/\s+/)
            if (parts.length === 1) return parts[0][0].toUpperCase()

            return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
        },

        avatarColor() {
            if (this.hasAvatar) return undefined

            const str = this.Ten || ''
            let hash = 0

            for (let i = 0; i < str.length; i++) {
                hash = str.charCodeAt(i) + ((hash << 5) - hash)
            }

            const colors = [
                'red', 'pink', 'purple', 'deep-purple',
                'indigo', 'blue', 'cyan', 'teal',
                'green', 'light-green', 'lime',
                'amber', 'orange', 'deep-orange'
            ]

            return colors[Math.abs(hash) % colors.length] || 'grey'
        }
    }
}
</script>